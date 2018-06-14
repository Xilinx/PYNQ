#   Copyright (c) 2018, Xilinx, Inc.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

__author__ = "Peter Ogden"
__copyright__ = "Copyright 2018, Xilinx"
__email__ = "pynq_support@xilinx.com"

import cffi
import math


_ffi = cffi.FFI()


class DP159:
    """Class to configure the TI SNDP159 HDMI redriver/retimer

    """

    def __init__(self, master, address):
        """Construct a new driver

        Parameters
        ----------
        master : IIC master
            I2C master that the device is connected to
        address : int
            I2C address of device

        """
        self._master = master
        self._address = address
        self._buffer = _ffi.new("unsigned char [32]")

    def _read(self, reg_addr):
        self._buffer[0] = reg_addr
        self._master.send(self._address, self._buffer, 1, 1)
        self._master.receive(self._address, self._buffer, 1)
        self._master.wait()
        # Clear all of the interrupts
        self._master.write(0x20, self._master.read(0x20))
        return self._buffer[0]

    def _write(self, reg_addr, data):
        self._buffer[0] = reg_addr
        self._buffer[1] = data
        self._master.send(self._address, self._buffer, 2)
        self._master.wait()
        # Clear all of the interrupts
        self._master.write(0x20, self._master.read(0x20))

    def set_clock(self, refclk, line_rate):
        """Configure the device based on the line rate

        """
        is20 = (line_rate // 1000000) > 3400
        # These parameters are derived from the Xilinx ZCU104 reference
        self._write(0x09, 0x06)
        if is20:
            self._write(0x0B, 0x9A)
            self._write(0x0C, 0x49)
            self._write(0x0D, 0x00)
            self._write(0x0A, 0x36)
        else:
            self._write(0x0B, 0x80)
            self._write(0x0C, 0x48)
            self._write(0x0D, 0x00)
            self._write(0x0A, 0x35)


# The following algorithm is transcribed from the ZCU104 HDMI reference design

IDT_8T49N24X_XTAL_FREQ = 40000000  # The freq of the crystal in Hz
IDT_8T49N24X_FVCO_MAX = 4000000000  # Max VCO Operating Freq in Hz
IDT_8T49N24X_FVCO_MIN = 3000000000  # Min VCO Operating Freq in Hz

IDT_8T49N24X_FOUT_MAX = 400000000  # Max Output Freq in Hz
IDT_8T49N24X_FOUT_MIN = 8000       # Min Output Freq in Hz

IDT_8T49N24X_FIN_MAX = 875000000   # Max Input Freq in Hz
IDT_8T49N24X_FIN_MIN = 8000        # Min Input Freq in Hz

IDT_8T49N24X_FPD_MAX = 128000      # Max Phase Detector Freq in Hz
IDT_8T49N24X_FPD_MIN = 8000        # Min Phase Detector Freq in Hz

IDT_8T49N24X_P_MAX = 4194304       # pow(2,22) - Max P div value
IDT_8T49N24X_M_MAX = 16777216      # pow(2,24) - Max M mult value


def _get_int_div_table(fout, bypass):
    if bypass:
        NS1_Options = [1, 4, 5, 6]
    else:
        NS1_Options = [4, 5, 6]
    table = []
    OutDivMin = math.ceil(IDT_8T49N24X_FVCO_MIN / fout)
    OutDivMax = math.floor(IDT_8T49N24X_FVCO_MAX / fout)
    if OutDivMax in NS1_Options or OutDivMin in NS1_Options:
        # Bypass NS2
        NS2Min = 0
        NS2Max = 0
    else:
        NS2Min = math.ceil(OutDivMin / NS1_Options[-1] / 2)
        NS2Max = math.floor(OutDivMax / NS1_Options[0] / 2)
        if NS2Max == 0:
            NS2Max = 1
    NS2Temp = NS2Min
    while NS2Temp <= NS2Max:
        for ns1 in NS1_Options:
            if NS2Temp == 0:
                OutDivTemp = ns1
            else:
                OutDivTemp = ns1 * NS2Temp * 2
            VCOTemp = fout * OutDivTemp
            if VCOTemp <= IDT_8T49N24X_FVCO_MAX and VCOTemp >= IDT_8T49N24X_FVCO_MIN:
                table.append((OutDivTemp, ns1))
        NS2Temp += 1
    return table


NS1Lookup = {4: 2, 5: 0, 6: 1}


def _calculate_settings(fin, fout):
    settings = {}
    divide = max(_get_int_div_table(fout, False))
    fvco = fout * divide[0]
    settings['NS1Ratio'] = divide[1]
    settings['NS1_Reg'] = NS1Lookup[settings['NS1Ratio']]
    settings['NS2Ratio'] = divide[0] // divide[1]
    settings['NS2_Reg'] = settings['NS2Ratio'] // 2
    # Assume always integer division
    settings['NInt'] = divide[0] // 2
    settings['NFrac'] = 0
    # Calculate the divider from the reference crystal
    fbdiv = fvco / (2 * IDT_8T49N24X_XTAL_FREQ)
    settings['DSMInt'] = math.floor(fbdiv)
    settings['DSMFrac'] = round((fbdiv - settings['DSMInt']) * pow(2, 21))
    # Calculate settings for the phase detector
    fin_ratio = fvco / fin
    PMin = fin // IDT_8T49N24X_FPD_MAX
    min_error = 99999999
    for i in range(PMin, IDT_8T49N24X_P_MAX):
        M1 = round(i * fin_ratio)
        if M1 < IDT_8T49N24X_M_MAX:
            error = abs(fin_ratio - (M1 / i))
            if error < min_error:
                M1_best = M1
                P_best = i
                min_error = error
                if error < 1e-9:
                    break
        else:
            break
    settings['M1'] = M1_best
    settings['Pre'] = P_best
    LOS = (fvco // 8 // fin) + 3
    if LOS < 6:
        LOS = 6
    settings['LOS'] = LOS
    return settings

# Initial configuration that sets up a free-running clock


IDT_Synth = [
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xEF, 0x00, 0x03, 0x00, 0x31, 0x00,
    0x04, 0x89, 0x00, 0x00, 0x01, 0x00, 0x63, 0xC6, 0x07, 0x00, 0x00, 0x77,
    0x6D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0x01,
    0x3F, 0x00, 0x28, 0x00, 0x1A, 0xCC, 0xCD, 0x00, 0x01, 0x00, 0x00, 0xD0,
    0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x0C, 0x00, 0x00,
    0x00, 0x44, 0x44, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0B,
    0x00, 0x00, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x89, 0x0A, 0x2B, 0x20,
    0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

]


class IDT_8T49N24:
    """Driver for the IDT 8T49N24x series of clock generators

    """

    def __init__(self, master, address):
        """Create a new instance of the IDT driver

        Parameters
        ----------
        master : IIC master
            IIC master the device is connected to
        address : int
            IIC address of the device

        """
        self._master = master
        self._address = address
        self._buffer = _ffi.new("unsigned char [32]")
        if not self.check_device_id():
            raise RuntimeError("Could not find IDT8TN24x")
        self.enable(False)
        self._configure(IDT_Synth)
        self.enable(True)

    def _configure(self, values):
        for i, v in enumerate(values):
            if i != 0x70:  # Skip Calibration
                self._write(i, v)

    def _read(self, reg_addr):
        attempts = 0
        while True:
            try:
                self._buffer[0] = reg_addr >> 8
                self._buffer[1] = reg_addr & 0xFF
                self._master.send(self._address, self._buffer, 2, 1)
                self._master.receive(self._address, self._buffer, 1, 0)
            except:
                attempts += 1
                if attempts > 100:
                    raise
                continue
            break

        return self._buffer[0]

    def _write(self, reg_addr, value):
        attempts = 0
        while True:
            try:
                self._buffer[0] = reg_addr >> 8
                self._buffer[1] = reg_addr & 0xFF
                self._buffer[2] = value
                self._master.send(self._address, self._buffer, 3, 0)
            except:
                attempts += 1
                if attempts > 100:
                    raise
                continue
            break

    def _update(self, reg_addr, value, mask):
        data = self._read(reg_addr)
        data &= ~mask
        data |= (value & mask)
        self._write(reg_addr, data)

    def check_device_id(self):
        device_id = (self._read(0x0002) & 0xF) << 12
        device_id |= self._read(0x0003) << 4
        device_id |= self._read(0x0004) >> 4
        return device_id == 0x0606 or device_id == 65535

    def enable(self, active):
        if active:
            value = 0x00
        else:
            value = 0x05
        self._update(0x0070, value, 0x05)

    def set_clock(self, freq, line_rate):
        self._set_clock(IDT_8T49N24X_XTAL_FREQ, freq, True)

    def _set_clock(self, fin, fout, free_run):
        if fin < IDT_8T49N24X_FIN_MIN:
            raise RuntimeError("Input Frequency Below Minimum")
        if fin > IDT_8T49N24X_FIN_MAX:
            raise RuntimeError("Input Frequency Above Maximum")
        if fout < IDT_8T49N24X_FOUT_MIN:
            raise RuntimeError("Output Frequency Below Minimum")
        if fout > IDT_8T49N24X_FOUT_MAX:
            raise RuntimeError("Output Frequency Above Maximum")

        settings = _calculate_settings(fin, fout)
        self.enable(False)

        if free_run:
            self._reference_input(0, False)
            self._reference_input(1, False)
            self._mode(True)
        else:
            self._reference_input(0, True)
            self._reference_input(1, False)
            self._mode(False)
        # Set up input clock
        self._pre_divider(0, settings['Pre'])
        self._pre_divider(1, settings['Pre'])
        self._m1_feedback(0, settings['M1'])
        self._m1_feedback(1, settings['M1'])
        self._los(0, settings['LOS'])
        self._los(1, settings['LOS'])
        # FVCO configuration
        self._dsm_int(settings['DSMInt'])
        self._dsm_frac(settings['DSMFrac'])
        # Output clock
        self._output_divider(2, settings['NInt'])
        self._output_divider(3, settings['NInt'])
        self._output_divider_frac(2, settings['NFrac'])
        self._output_divider_frac(3, settings['NFrac'])

        self.enable(True)

    def _reference_input(self, channel, enable):
        if channel == 1:
            shift = 5
        else:
            shift = 4
        if enable:
            value = 0
        else:
            value = 1 << shift
        mask = 1 << shift
        self._update(0x000a, value, mask)

    def _mode(self, free_run):
        if free_run:
            self._update(0x000a, 0x31, 0x33)
            self._update(0x0069, 0x08, 0x08)
        else:
            self._update(0x000a, 0x20, 0x33)
            self._update(0x0069, 0x00, 0x08)

    def _pre_divider(self, channel, value):
        if channel == 1:
            address = 0x000e
        else:
            address = 0x000b
        self._write(address, (value >> 16) & 0x1F)
        self._write(address + 1, (value >> 8) & 0xFF)
        self._write(address + 2, value & 0xFF)

    def _m1_feedback(self, channel, value):
        if channel == 1:
            address = 0x0011
        else:
            address = 0x0014
        self._write(address, value >> 16)
        self._write(address + 1, (value >> 8) & 0xFF)
        self._write(address + 2, value & 0xFF)

    def _los(self, channel, value):
        if channel == 1:
            address = 0x0074
        else:
            address = 0x0071
        self._write(address, value >> 16)
        self._write(address + 1, (value >> 8) & 0xFF)
        self._write(address + 2, value & 0xFF)

    def _dsm_int(self, value):
        self._write(0x25, (value >> 8) & 0x01)
        self._write(0x26, value & 0xFF)

    def _dsm_frac(self, value):
        self._write(0x28, (value >> 16) & 0x1F)
        self._write(0x29, (value >> 8) & 0xFF)
        self._write(0x2a, value & 0xFF)

    def _output_divider(self, channel, value):
        addresses = [0x003f, 0x0042, 0x0045, 0x0048]
        address = addresses[channel]
        self._write(address, (value >> 16) & 0x3)
        self._write(address + 1, (value >> 8) & 0xFF)
        self._write(address + 2, value & 0xFF)

    def _output_divider_frac(self, channel, value):
        addresses = [0x0000, 0x0057, 0x005b, 0x005f]
        address = addresses[channel]
        self._write(address, (value >> 24) & 0x0F)
        self._write(address + 1, (value >> 16) & 0xFF)
        self._write(address + 2, (value >> 8) & 0xFF)
        self._write(address + 3, value & 0xFF)
