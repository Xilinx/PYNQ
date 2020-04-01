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
from pynq.lib.video.header import *


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


vals=np.zeros(6,dtype=np.uint64)

n1_min=np.uint32(1)
n1_max=np.uint32(1)
n1_hs=np.uint32(1)
nc_ls_min=np.uint32(1)
nc_ls_max=np.uint32(1)
nc_ls=np.uint32(1)
n2_hs=np.uint32(1)
n2_ls_min=np.uint32(1)
n2_ls_max=np.uint32(1)
n2_ls=np.uint32(1)
n3_min=np.uint32(1)
n3_max=np.uint32(1)
n3=np.uint32(1)
best_n1_hs=np.uint32(1)
best_nc_ls=np.uint32(1)
best_n2_hs=np.uint32(1)
best_n2_ls=np.uint32(1)
best_n3=np.uint32(1)
fin=np.uint64(1)
fout=np.uint64(1)
fosc=np.uint64(1)
best_fout_delta=np.uint64(1)
best_fout=np.uint64(1)

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
        self.enable(False)
        self._configure()
        self.enable(True)

    def _configure(self):
        self._write(3,0x15)
        self._write(4,0x92)
        self._write(6,0x2f)
        self._write(10,0x08)
        self._write(11,0x42)
        self._write(19,0x23)    # if VID_PHY_CONTROLLER_HDMI_FAST_SWITCH  else 0x2f
        self._write(137,0x01)
    
    def _read(self, reg_addr):
        attempts = 0
        while True:
            try:
                self._buffer[0] = reg_addr 
                self._master.send(self._address, self._buffer, 1, 1)
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
                self._buffer[0] = reg_addr
                self._buffer[1] = value
                self._master.send(self._address, self._buffer, 2, 0)
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
        device_id = self._read(0x86) << 8
        print(hex(device_id))
        device_id |= self._read(0x87)  
        print(hex(device_id))
        return device_id == 0x0182 

    def enable(self, active):
        if active:
            value = 0x00
        else:
            value = 0x01
        self._update(0x0B, value, 0x01)

    def set_clock(self, freq, line_rate):
        if SI5324_DEBUG:
            print("freq:",freq,"line_rate:",line_rate)
        self.enable(False)
        self._SetClock(SI5324_CLKSRC_XTAL,SI5324_XTAL_FREQ, freq)
        self.enable(True)
        
    def _print_settings(self):
        print("n1_min=%d, n1_max=%d, n1_hs=%d, nc_ls_min=%d, nc_ls_max=%d, nc_ls=%d" %(n1_min,n1_max,n1_hs, nc_ls_min, nc_ls_max, nc_ls))
        print("n2_hs=%d, n2_ls_min=%d, n2_ls_max=%d, n2_ls=%d, n3_min=%d, n3_max=%d, n3=%d" %(n2_hs,n2_ls_min,n2_ls_max,n2_ls,n3_min,n3_max,n3))
        print("fin=%d, fout=%d, fosc=%d" %(fin,fout,fosc))
        print("best_fout_delta=%d, best_fout=%d" %(best_fout_delta,best_fout))
        print("best_n1_hs=%d, best_nc_ls=%d, best_n2_hs=%d, best_n2_ls=%d, best_n3=%d" %(best_n1_hs,best_nc_ls, best_n2_hs, best_n2_ls, best_n3))

    def _Si5324_RatApprox(self,f):
        global n1_max,n1_min,n1_hs,nc_ls_min,nc_ls_max,nc_ls,n2_hs,n2_ls_min,n2_ls_max,n2_ls,n3,n3_min,n3_max,best_n1_hs,best_nc_ls,best_n2_ls,best_n2_hs,best_n3,fin,fout,fosc,best_fout_delta,best_fout

        if SI5324_LOW_LEVEL_DEBUG:
            print("\nEntering _Si5324_RatApprox with f=",f,"md=",n3_max)
            self._print_settings()
        h=np.array([0,1,0])
        k=np.array([1,0,0])
        i=0
        n=1
        if n3_max<=1:
            n3=1
            n2_ls=np.uint64(f)>>np.uint64(28)
            return
        n=np.uint64(n<<28)
        for i in range(0,28):
            if (f%2)==0:        #f&0x1==0:
                n=n//2          #n=n>>1
                f=f//2          #f=f>>1
            else:
                break
        d=f
        for i in range(64):
            if n:
                a=d//n          #a=d/n
            else:
                a=0
            if i and not(a):    #i and ~a:
                break
            x=d
            d=n
            n=x%n
            x=a
            if k[1]*a+k[0]>=n3_max:
                x=(n3_max-k[0])/k[1]
                if x*2>=a or k[1]>=n3_max:
                    i=65
                else:
                    break
            h[2]=x*h[1]+h[0]
            h[0]=h[1]
            h[1]=h[2]
            k[2]=x*k[1]+k[0]
            k[0]=k[1]
            k[1]=k[2]
        n3=np.uint32(k[1])
        n2_ls=np.uint32(h[1])
        if SI5324_LOW_LEVEL_DEBUG:
            print("\nExiting _Si5324_RatApprox with n3(denom) and n2_ls(num)",n3, n2_ls)
            self._print_settings()

    def _Si5324_FindN2ls(self):
        global n1_max,n1_min,n1_hs,nc_ls_min,nc_ls_max,nc_ls,n2_hs,n2_ls_min,n2_ls_max,n2_ls,n3,n3_min,n3_max,best_n1_hs,best_nc_ls,best_n2_ls,best_n2_hs,best_n3,fin,fout,fosc,best_fout_delta,best_fout

        if SI5324_LOW_LEVEL_DEBUG:
            print("\nEntering _Si5324_FindN2ls")
            self._print_settings()

        result=0
        delta_fout=np.uint64(1)     #PP
        np.seterr(divide='ignore', invalid='ignore')
        n2_ls_div_n3=np.uint64(fosc//(fin>>np.uint64(28))//n2_hs//2)
        self._Si5324_RatApprox(n2_ls_div_n3)
        n2_ls=np.uint32(n2_ls*2)
        if n2_ls<n2_ls_min:
            mult=n2_ls_min//n2_ls
            mult=n2_ls_min%n2_ls
            if mult==1:
                mult=mult+1
            else:
                mult=mult
            n2_ls=np.uint32(n2_ls*mult)
            n3=np.uint32(n3*mult)
            
        if n3<n3_min:
            mult=n3_min//n3
            mult=n3_min%n3
            if mult==1:
                mult=mult+1
            else:
                mult=mult
            n2_ls=np.uint32(n2_ls*mult)
            n3=np.uint32(n3*mult)
       
        if SI5324_DEBUG:
            print("Trying N2_LS",n2_ls,"N3 = ",n3,"\n")
        if n2_ls<n2_ls_min or n2_ls>n2_ls_max:
            print("N2_LS out of range\n")
        elif n3<n3_min or n3>n3_max:
            print("N3 out of range\n")

        else:
            f3_actual=np.uint64(fin//n3)
            fosc_actual=np.uint64(f3_actual*n2_hs*n2_ls)
            fout_actual=np.uint64(fosc_actual//(n1_hs*nc_ls))
            delta_fout=np.uint64(fout_actual-fout)

            if f3_actual<(SI5324_F3_MIN<<28) or f3_actual>(SI5324_F3_MAX<<28):
                if SI5324_DEBUG:
                    print("F3 frequency out of range\n")
            elif fosc_actual<(SI5324_FOSC_MIN<<28) or fosc_actual>(SI5324_FOSC_MAX<<28):
                if SI5324_DEBUG:
                    print("Fosc frequency out of range\n")
            elif fout_actual<(SI5324_FOUT_MIN<<28) or fout_actual>(SI5324_FOUT_MAX<<28):
                if SI5324_DEBUG:
                    print("Fout frequency out of range\n")
            else:
                if SI5324_DEBUG:
#                    print("Found solution : fout=",fout_actual>>28,"Hz delta = ",delta_fout>>28,"Hz\n")
#                    print(" fosc=",(fosc_actual>>28)/1000,"kHz f3 = ",f3_actual>>28,"Hz\n")
                    print("\tFound solution : fout=",np.uint64(fout_actual)>>np.uint64(28),"Hz delta = ",np.uint64(delta_fout)>>np.uint64(28),"Hz\n")
                    print("\tfosc=",(np.uint64(fosc_actual)>>np.uint64(28))/1000,"kHz f3 = ",np.uint64(f3_actual)>>np.uint64(28),"Hz\n")
#                if llabs(delta_fout)<best_fout_delta:
                if abs(delta_fout)<best_fout_delta:
                    if SI5324_DEBUG:
                        print("This solution is the best yet!\n")
                    best_n1_hs=np.uint32(n1_hs)
                    best_nc_ls=np.uint32(nc_ls)
                    best_n2_hs=np.uint32(n2_hs)
                    best_n2_ls=np.uint32(n2_ls)
                    best_n3=np.uint32(n3)
                    best_fout=np.uint64(fout_actual)
#                    best_fout_delta=llabs(delta_fout)
                    best_fout_delta=abs(delta_fout)
                    if delta_fout==0:
                        result=1
        if SI5324_LOW_LEVEL_DEBUG:
            print("\nExiting _Si5324_FindN2ls with result=",result)
            self._print_settings()

        return result


    def _Si5324_FindN2(self):
        global n1_max,n1_min,n1_hs,nc_ls_min,nc_ls_max,nc_ls,n2_hs,n2_ls_min,n2_ls_max,n2_ls,n3,n3_min,n3_max,best_n1_hs,best_nc_ls,best_n2_ls,best_n2_hs,best_n3,fin,fout,fosc,best_fout_delta,best_fout

        if SI5324_LOW_LEVEL_DEBUG:
            print("Entering _Si5324_FindN2")
            self._print_settings()

        for i in range(SI5324_N2_HS_MAX,SI5324_N2_HS_MIN-1,-1):
            n2_hs=i
            if SI5324_DEBUG:
                print("Trying N2_HS=",i,"\n")
            n2_ls_min=np.uint32(fosc/((np.uint64(SI5324_F3_MAX)*np.uint64(i))<<np.uint64(28)))
            if n2_ls_min<SI5324_N2_LS_MIN:
                n2_ls_min=np.uint32(SI5324_N2_LS_MIN)
            n2_ls_max=np.uint32(fosc/(np.uint64(SI5324_F3_MIN*i)<<np.uint64(28)))
            if n2_ls_max>SI5324_N2_LS_MAX:
                n2_ls_max=np.uint32(SI5324_N2_LS_MAX)
            result=self._Si5324_FindN2ls()
            if result:
                break

        if SI5324_LOW_LEVEL_DEBUG:
            print("Exiting _Si5324_FindN2")
            self._print_settings()

        return result

    def _Si5324_CalcNclsLimits(self):
        global n1_max,n1_min,n1_hs,nc_ls_min,nc_ls_max,nc_ls,n2_hs,n2_ls_min,n2_ls_max,n2_ls,n3,n3_min,n3_max,best_n1_hs,best_nc_ls,best_n2_ls,best_n2_hs,best_n3,fin,fout,fosc,best_fout_delta,best_fout
        nc_ls_min=np.uint32(n1_min/n1_hs)

        if SI5324_LOW_LEVEL_DEBUG:
            print("Entering _Si5324_CalcNclsLimits")
            self._print_settings()

        if nc_ls_min<SI5324_NC_LS_MIN:
            nc_ls_min=np.uint32(SI5324_NC_LS_MIN)

        if nc_ls_min>1 and nc_ls_min&0x1 == 1:
            nc_ls_min=np.uint32(nc_ls_min+1)

        nc_ls_max=np.uint32(n1_max/n1_hs)
        if nc_ls_max>SI5324_NC_LS_MAX:
            nc_ls_max=np.uint32(SI5324_NC_LS_MAX)

        if np.uint32(nc_ls_max)&np.uint32(0x1)==1:
            nc_ls_max=np.uint32(nc_ls_max-1)

        if nc_ls_max*n1_hs<[n1_min] or nc_ls_min*n1_hs>n1_max:
            if SI5324_LOW_LEVEL_DEBUG:
                print("\nExiting abnormal: _Si5324_CalcNclsLimits")
                self._print_settings()
            return -1

        if SI5324_LOW_LEVEL_DEBUG:
            print("\nExiting normal: _Si5324_CalcNclsLimits")
            self._print_settings()

        return 0

    def _Si5324_FindNcls(self):
        global n1_max,n1_min,n1_hs,nc_ls_min,nc_ls_max,nc_ls,n2_hs,n2_ls_min,n2_ls_max,n2_ls,n3,n3_min,n3_max,best_n1_hs,best_nc_ls,best_n2_ls,best_n2_hs,best_n3,fin,fout,fosc,best_fout_delta,best_fout

        if SI5324_LOW_LEVEL_DEBUG:
            print("\nEntering _Si5324_FindNcls")
            self._print_settings()
        fosc_1=fout*n1_hs

        for i in range(nc_ls_max,nc_ls_max+1):
            fosc=np.uint64(fosc_1*i)
            if SI5324_DEBUG:
                print("Trying NCn_LS",i,": fosc=",(fosc>>np.uint64(28))/1000,"kHz\n")
            nc_ls=i     #PP
            result=self._Si5324_FindN2()
            if result:
                break
            if i==1:
                nc_ls=np.uint32(i+1)

            else:
                nc_ls=np.uint32(i+2)
        if SI5324_LOW_LEVEL_DEBUG:
            print("\nIn _Si5324_FindNcls");
            self._print_settings()
        
        return result

    def _Si5324_CalcFreqSettings(self,ClkInFreq,ClkOutFreq):
        global n1_max,n1_min,n1_hs,nc_ls_min,nc_ls_max,nc_ls,n2_hs,n2_ls_min,n2_ls_max,n2_ls,n3,n3_min,n3_max,best_n1_hs,best_nc_ls,best_n2_ls,best_n2_hs,best_n3,fin,fout,fosc,best_fout_delta,best_fout

        if SI5324_LOW_LEVEL_DEBUG:
            print("\nIn _Si5324_CalcFreqSettings, ClkInFreq: ",ClkInFreq, "ClkOutFreq: ",ClkOutFreq)
            self._print_settings()
        
        fin=np.uint64(ClkInFreq<<28)
        fout=np.uint64(ClkOutFreq<<28)    
        best_delta_fout=np.uint64(fout)

        n1_min=np.uint32(SI5324_FOSC_MIN/ClkOutFreq)
        if n1_min<SI5324_N1_HS_MIN * SI5324_NC_LS_MIN:
           n1_min=np.uint32(SI5324_N1_HS_MIN * SI5324_NC_LS_MIN)

        n1_max=np.uint32(SI5324_FOSC_MAX/ClkOutFreq)
        if n1_max>SI5324_N1_HS_MAX * SI5324_NC_LS_MAX:
            n1_max=np.uint32(SI5324_N1_HS_MAX* SI5324_NC_LS_MAX)

        n3_min=np.uint32(ClkInFreq/SI5324_F3_MAX)
        if n3_min<SI5324_N3_MIN:
            n3_min=np.uint32(SI5324_N3_MIN)

        n3_max=np.uint32(ClkInFreq/SI5324_F3_MIN)
        if n3_max>SI5324_N3_MAX:
           n3_max=np.uint32(SI5324_N3_MAX)

        for i in range(SI5324_N1_HS_MAX,SI5324_N1_HS_MIN-1,-1):
            n1_hs=i    #PP
            if SI5324_DEBUG:
                print("Trying N1_HS =",i,"\n")
            result=self._Si5324_CalcNclsLimits()

            if result:
                if SI5324_DEBUG:
                    print("No valid settings for NCn_LS\n")
                continue
            result=self._Si5324_FindNcls()
            if result:
                break

        if best_delta_fout==best_delta_fout/fout:
            if SI5324_DEBUG:
                print('Si5324:Error:No valid settings found')
                print("Exiting abnormal: _Si5324_CalcFreqSettings\n")
            if SI5324_LOW_LEVEL_DEBUG:
                self._print_settings()

            return SI5234_ERR_FREQ

        if SI5324_DEBUG:
            print("Si5324:Found solution:fout",np.uint64(best_fout>>np.uint64(28)),"Hz\n")

        vals[0]=best_n1_hs-4
        vals[1]=best_nc_ls-1
        vals[2]=best_n2_hs-4
        vals[3]=best_n2_ls-1
        vals[4]=best_n3-1
        vals[5]=6

        if SI5324_LOW_LEVEL_DEBUG:
            print("Exiting normal:  _Si5324_CalcFreqSettings\n")
            self._print_settings()
        return SI5324_SUCCESS
        
    def _SetClock(self,ClkSrc,ClkInFreq,ClkOutFreq):

        if SI5324_LOW_LEVEL_DEBUG:
            print("In _SetClock, ClkInFreq: ",ClkInFreq, "ClkOutFreq: ",ClkOutFreq)
            self._print_settings()

        buf=np.zeros(30,dtype=np.uint8)
        
        if ClkSrc<SI5324_CLKSRC_CLK1 or ClkSrc>SI5324_CLKSRC_XTAL:
            if SI5324_DEBUG:
                print("Si5324:Error : Incorrect input clock selected\n")
            return SI5324_ERR_PARM

        if ClkSrc==SI5324_CLKSRC_CLK2:
            if SI5324_DEBUG:
                print("Si5324:Error : clock input 2 not supported")
            return SI5324_ERR_PARM
        
        if ClkInFreq<SI5324_FIN_MIN or ClkInFreq>SI5324_FIN_MAX:
            if SI5324_DEBUG:
                print("Si5324:Error :Input Frequency out of range\n")
            return SI5324_ERR_PARM

        if ClkOutFreq<SI5324_FOUT_MIN or ClkOutFreq>SI5324_FOUT_MAX:
            if SI5324_DEBUG:
                print("Si5324: ERROR: Output frequency out of range\n")
            return SI5324_ERR_PARM
        
        result=self._Si5324_CalcFreqSettings(ClkInFreq,ClkOutFreq)

        if result!=SI5324_SUCCESS:
            if SI5324_DEBUG:
                print("Si5324: ERROR: Could not determine settings for requested frequency!\n")
            return result

        if SI5324_DEBUG:
            print("Si5324:Programming frequency settings\n")

        i=0
        buf[i]=0

        if ClkSrc==SI5324_CLKSRC_XTAL:
            buf[i+1]=0x54
        else:
            buf[i+1]=0x14

        i=i+2

        buf[i]=2
        buf[i+1]=np.uint8((vals[5]<<np.uint64(4)))|np.uint64(0x02)
        i+=2

        buf[i]=11
        if ClkSrc==SI5324_CLKSRC_CLK1:
            buf[i+1]=0x42
        else:
            buf[i+1]=0x41
        i+=2

        buf[i]=13
        buf[i+1]=0x2f   #2d=>LVPECL and 2F=>LVDS
        i+=2

        buf[i]=25
        buf[i+1]=np.uint8(vals[0]<<np.uint64(5))
        i+=2

        buf[i]=31
        buf[i+1]=np.uint8((vals[1]&np.uint64(0x000F0000))>>np.uint64(16))
        buf[i+2]=32
        buf[i+3]=np.uint8((vals[1]&np.uint64(0x000FF0000))>>np.uint64(8))
        buf[i+4]=33
        buf[i+5]=np.uint8(vals[1]&np.uint64(0x000000FF))
        i+=6

        buf[i]=40
        buf[i+1]=np.uint8(vals[2]<<np.uint64(5))
        temp=(np.uint8(vals[3])&np.uint64(0x000F0000))>>np.uint64(16)
        buf[i+1]=np.uint8(np.uint64(buf[i+1])|np.uint64(temp))
        buf[i+2]=41
        buf[i+3]=np.uint8((vals[3]&np.uint64(0x0000FF00))>>np.uint64(8))
        buf[i+4]=42
        buf[i+5]=np.uint8(vals[3]&np.uint64(0x000000FF))
        i+=6

        if ClkSrc==SI5324_CLKSRC_CLK1:
            buf[i]=43
            buf[i+2]=44
            buf[i+4]=45
        else:
            buf[i]=46
            buf[i+2]=47
            buf[i+4]=48

        buf[i+1]=np.uint8((vals[4]&np.uint64(0x00070000))>>np.uint64(16))
        buf[i+3]=np.uint8((vals[4]&np.uint64(0x0000FF00))>>np.uint64(8))
        buf[i+5]=np.uint8(vals[4]&np.uint64(0x000000FF))
        i+=6

        buf[i]=136
        buf[i+1]=0x40
        i+=2

        if i!=buf.shape[0]:
            if SI5324_DEBUG:
                print("Si5324 : FATAL ERROR: Incorrect buffer size while programming frequnency settings!")
            return

        print("Programming Si5324 chip with the following address and data")
        for index in range (0,i,2):
            print("reg:",np.uint8(buf[index]),"value:",hex(np.uint8(buf[index+1])))

        for index in range (0,i,2):
            reg_addr= np.uint8(buf[index])
            data=np.uint8(buf[index+1])
            self._write(reg_addr, data)

        return result
