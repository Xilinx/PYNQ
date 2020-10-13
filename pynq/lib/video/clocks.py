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

__author__ = "Peter Ogden, Parimal Patel"
__copyright__ = "Copyright 2018, Xilinx"
__email__ = "pynq_support@xilinx.com"

import cffi
import math
import numpy as np
from .constants import *


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
            if IDT_8T49N24X_FVCO_MIN <= VCOTemp <= IDT_8T49N24X_FVCO_MAX:
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
    M1_best = 0
    P_best = 0
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
        """Configure the device based on the line rate

        The parameter `line_rate` is left to keep consistent API with
        other clock drivers.

        """
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


class SI_5324C:
    """Driver for the SI 5324C series of clock generators

    """

    def __init__(self, master, address):
        """Create a new instance of the SI_5324C driver

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
            raise RuntimeError("Could not find SI5324")

        self.vals = [0 for _ in range(6)]
        self.n1_min = 1
        self.n1_max = 1
        self.n1_hs = 1
        self.nc_ls_min = 1
        self.nc_ls_max = 1
        self.nc_ls = 1
        self.n2_hs = 1
        self.n2_ls_min = 1
        self.n2_ls_max = 1
        self.n2_ls = 1
        self.n3_min = 1
        self.n3_max = 1
        self.n3 = 1
        self.best_n1_hs = 1
        self.best_nc_ls = 1
        self.best_n2_hs = 1
        self.best_n2_ls = 1
        self.best_n3 = 1
        self.fin = 1
        self.fout = 1
        self.fosc = 1
        self.best_fout_delta = 1
        self.best_fout = 1

        self.enable(False)
        self._configure()
        self.enable(True)

    def _configure(self):
        self._write(3, 0x15)
        self._write(4, 0x92)
        self._write(6, 0x2f)
        self._write(10, 0x08)
        self._write(11, 0x42)
        self._write(19, 0x23)
        self._write(137, 0x01)

    def _read(self, reg_addr):
        attempts = 0
        while True:
            try:
                self._buffer[0] = reg_addr
                self._master.send(self._address, self._buffer, 1, 1)
                self._master.receive(self._address, self._buffer, 1, 0)
            except Exception:
                attempts += 1
                if attempts > 100:
                    raise RuntimeError(
                        "Timeout when reading from address {}".format(reg_addr))
                continue
            break

        return self._buffer[0]

    def _write(self, reg_addr, value):
        attempts = 0
        while True:
            try:
                self._buffer[0] = reg_addr
                self._buffer[1] = value
                self._master.send(self._address, self._buffer, 2, 0)
            except Exception:
                attempts += 1
                if attempts > 100:
                    raise RuntimeError(
                        "Timeout when writing to address {}".format(reg_addr))
                continue
            break

    def _update(self, reg_addr, value, mask):
        data = self._read(reg_addr)
        data &= ~mask
        data |= (value & mask)
        self._write(reg_addr, data)

    def check_device_id(self):
        device_id = self._read(0x86) << 8
        device_id |= self._read(0x87)
        return device_id == 0x0182

    def enable(self, active):
        if active:
            value = 0x00
        else:
            value = 0x01
        self._update(0x0B, value, 0x01)

    def set_clock(self, freq, line_rate):
        self.enable(False)
        self._set_clock(SI5324_CLKSRC_XTAL, SI5324_XTAL_FREQ, freq)
        self.enable(True)

    def _rate_approx(self, f):
        h = np.array([0, 1, 0])
        k = np.array([1, 0, 0])
        n = 1
        if self.n3_max <= 1:
            self.n3 = 1
            self.n2_ls = f >> 28
            return
        n = n << 28
        for i in range(0, 28):
            if (f % 2) == 0:
                n = n//2
                f = f//2
            else:
                break
        d = f
        for i in range(64):
            if n:
                a = d//n
            else:
                a = 0
            if i and not a:
                break
            x = d
            d = n
            n = x % n
            x = a
            if k[1]*a+k[0] >= self.n3_max:
                x = (self.n3_max-k[0])//k[1]
                if not (x*2 >= a or k[1] >= self.n3_max):
                    break
            h[2] = x*h[1]+h[0]
            h[0] = h[1]
            h[1] = h[2]
            k[2] = x*k[1]+k[0]
            k[0] = k[1]
            k[1] = k[2]
        self.n3 = k[1]
        self.n2_ls = h[1]

    def _find_n2ls(self):
        result = 0
        np.seterr(divide='ignore', invalid='ignore')
        n2_ls_div_n3 = self.fosc//(self.fin >> 28)//self.n2_hs//2
        self._rate_approx(n2_ls_div_n3)
        self.n2_ls = self.n2_ls*2
        if self.n2_ls < self.n2_ls_min:
            mult = self.n2_ls_min % self.n2_ls
            if mult == 1:
                mult = mult+1
            self.n2_ls = self.n2_ls*mult
            self.n3 = self.n3*mult

        if self.n3 < self.n3_min:
            mult = self.n3_min % self.n3
            if mult == 1:
                mult = mult+1
            self.n2_ls = self.n2_ls*mult
            self.n3 = self.n3*mult
        else:
            f3_actual = self.fin//self.n3
            fosc_actual = f3_actual * self.n2_hs * self.n2_ls
            fout_actual = fosc_actual//(self.n1_hs * self.nc_ls)
            delta_fout = fout_actual - self.fout

            if f3_actual < (SI5324_F3_MIN << 28) or \
                    f3_actual > (SI5324_F3_MAX << 28):
                pass
            elif fosc_actual < (SI5324_FOSC_MIN << 28) or \
                    fosc_actual > (SI5324_FOSC_MAX << 28):
                pass
            elif fout_actual < (SI5324_FOUT_MIN << 28) or \
                    fout_actual > (SI5324_FOUT_MAX << 28):
                pass
            else:
                if abs(delta_fout) < self.best_fout_delta:
                    self.best_n1_hs = self.n1_hs
                    self.best_nc_ls = self.nc_ls
                    self.best_n2_hs = self.n2_hs
                    self.best_n2_ls = self.n2_ls
                    self.best_n3 = self.n3
                    self.best_fout = fout_actual
                    self.best_fout_delta = abs(delta_fout)
                    if delta_fout == 0:
                        result = 1

        return result

    def _find_n2(self):
        result = 0
        for i in range(SI5324_N2_HS_MAX, SI5324_N2_HS_MIN-1, -1):
            self.n2_hs = i
            self.n2_ls_min = self.fosc//((SI5324_F3_MAX * i) << 28)
            if self.n2_ls_min < SI5324_N2_LS_MIN:
                self.n2_ls_min = SI5324_N2_LS_MIN
            self.n2_ls_max = self.fosc//((SI5324_F3_MIN * i) << 28)
            if self.n2_ls_max > SI5324_N2_LS_MAX:
                self.n2_ls_max = SI5324_N2_LS_MAX
            result = self._find_n2ls()
            if result:
                break

        return result

    def _calc_ncls_limits(self):
        self.nc_ls_min = self.n1_min//self.n1_hs
        if self.nc_ls_min < SI5324_NC_LS_MIN:
            self.nc_ls_min = SI5324_NC_LS_MIN

        if self.nc_ls_min > 1 and self.nc_ls_min & 0x1 == 1:
            self.nc_ls_min = self.nc_ls_min+1

        self.nc_ls_max = self.n1_max//self.n1_hs
        if self.nc_ls_max > SI5324_NC_LS_MAX:
            self.nc_ls_max = SI5324_NC_LS_MAX

        if self.nc_ls_max & 0x1 == 1:
            self.nc_ls_max = self.nc_ls_max-1

        if self.nc_ls_max * self.n1_hs < self.n1_min or \
                self.nc_ls_min * self.n1_hs > self.n1_max:
            return -1

        return 0

    def _find_ncls(self):
        fosc_1 = self.fout * self.n1_hs

        result = 0
        for i in range(self.nc_ls_max, self.nc_ls_max+1):
            self.fosc = fosc_1 * i
            self.nc_ls = i
            result = self._find_n2()
            if result:
                break
            if i == 1:
                self.nc_ls = i+1

            else:
                self.nc_ls = i+2

        return result

    def _calc_freq_settings(self, clk_in_freq, clk_out_freq):
        self.fin = clk_in_freq << 28
        self.fout = clk_out_freq << 28
        best_delta_fout = self.fout

        self.n1_min = SI5324_FOSC_MIN//clk_out_freq
        if self.n1_min < SI5324_N1_HS_MIN * SI5324_NC_LS_MIN:
            self.n1_min = SI5324_N1_HS_MIN * SI5324_NC_LS_MIN

        self.n1_max = SI5324_FOSC_MAX//clk_out_freq
        if self.n1_max > SI5324_N1_HS_MAX * SI5324_NC_LS_MAX:
            self.n1_max = SI5324_N1_HS_MAX * SI5324_NC_LS_MAX

        self.n3_min = clk_in_freq//SI5324_F3_MAX
        if self.n3_min < SI5324_N3_MIN:
            self.n3_min = SI5324_N3_MIN

        self.n3_max = clk_in_freq//SI5324_F3_MIN
        if self.n3_max > SI5324_N3_MAX:
            self.n3_max = SI5324_N3_MAX

        for i in range(SI5324_N1_HS_MAX, SI5324_N1_HS_MIN-1, -1):
            self.n1_hs = i
            result = self._calc_ncls_limits()
            if result:
                continue
            result = self._find_ncls()
            if result:
                break

        if best_delta_fout == best_delta_fout//self.fout:
            return SI5234_ERR_FREQ

        self.vals[0] = self.best_n1_hs-4
        self.vals[1] = self.best_nc_ls-1
        self.vals[2] = self.best_n2_hs-4
        self.vals[3] = self.best_n2_ls-1
        self.vals[4] = self.best_n3-1
        self.vals[5] = 6

        return SI5324_SUCCESS

    def _set_clock(self, clk_src, clk_in_freq, clk_out_freq):
        buf = np.zeros(30, dtype=np.uint8)

        if clk_src < SI5324_CLKSRC_CLK1 or clk_src > SI5324_CLKSRC_XTAL:
            raise RuntimeError("Si5324 Error : Incorrect input clock selected")

        if clk_src == SI5324_CLKSRC_CLK2:
            raise RuntimeError("Si5324 Error : clock input 2 not supported")

        if clk_in_freq < SI5324_FIN_MIN or clk_in_freq > SI5324_FIN_MAX:
            raise RuntimeError("Si5324 Error :Input Frequency out of range")

        if clk_out_freq < SI5324_FOUT_MIN or clk_out_freq > SI5324_FOUT_MAX:
            raise RuntimeError("Si5324 ERROR: Output frequency out of range")

        result = self._calc_freq_settings(clk_in_freq, clk_out_freq)
        if result != SI5324_SUCCESS:
            raise RuntimeError("Si5324 ERROR: Could not determine settings "
                               "for requested frequency")

        i = 0
        buf[i] = 0
        if clk_src == SI5324_CLKSRC_XTAL:
            buf[i+1] = 0x54
        else:
            buf[i+1] = 0x14

        i = i+2
        buf[i] = 2
        buf[i+1] = (self.vals[5] << 4) | 0x02

        i += 2
        buf[i] = 11
        if clk_src == SI5324_CLKSRC_CLK1:
            buf[i+1] = 0x42
        else:
            buf[i+1] = 0x41

        i += 2
        buf[i] = 13
        buf[i+1] = 0x2f

        i += 2
        buf[i] = 25
        buf[i+1] = self.vals[0] << 5

        i += 2
        buf[i] = 31
        buf[i+1] = (self.vals[1] & 0x000F0000) >> 16
        buf[i+2] = 32
        buf[i+3] = (self.vals[1] & 0x0000FF00) >> 8
        buf[i+4] = 33
        buf[i+5] = self.vals[1] & 0x000000FF

        i += 6
        buf[i] = 40
        buf[i+1] = self.vals[2] << 5
        temp = (self.vals[3] & 0x000F0000) >> 16
        buf[i+1] = buf[i+1] | temp
        buf[i+2] = 41
        buf[i+3] = (self.vals[3] & 0x0000FF00) >> 8
        buf[i+4] = 42
        buf[i+5] = self.vals[3] & 0x000000FF

        i += 6
        if clk_src == SI5324_CLKSRC_CLK1:
            buf[i] = 43
            buf[i+2] = 44
            buf[i+4] = 45
        else:
            buf[i] = 46
            buf[i+2] = 47
            buf[i+4] = 48
        buf[i+1] = (self.vals[4] & 0x00070000) >> 16
        buf[i+3] = (self.vals[4] & 0x0000FF00) >> 8
        buf[i+5] = self.vals[4] & 0x000000FF

        i += 6
        buf[i] = 136
        buf[i+1] = 0x40

        i += 2
        if i != buf.shape[0]:
            return

        for index in range(0, i, 2):
            reg_addr = buf[index]
            data = buf[index+1]
            self._write(reg_addr, data)

        return result
