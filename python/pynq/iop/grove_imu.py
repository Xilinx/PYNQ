#   Copyright (c) 2016, Xilinx, Inc.
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

__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


import struct
import math
from time import sleep
from pynq import MMIO
from pynq.iop import request_iop
from pynq.iop import iop_const
from pynq.iop import PMODA
from pynq.iop import PMODB
from pynq.iop import ARDUINO
from pynq.iop import PMOD_GROVE_G3
from pynq.iop import PMOD_GROVE_G4
from pynq.iop import ARDUINO_GROVE_I2C

PMOD_GROVE_IMU_PROGRAM = "pmod_grove_imu.bin"
ARDUINO_GROVE_IMU_PROGRAM = "arduino_grove_imu.bin"

class Grove_IMU(object):
    """This class controls the Grove IIC IMU. 
    
    Grove IMU 10DOF is a combination of grove IMU 9DOF (MPU9250) and grove 
    barometer sensor (BMP180). MPU-9250 is a 9-axis motion tracking device 
    that combines a 3-axis gyroscope, 3-axis accelerometer, 3-axis 
    magnetometer and a Digital Motion Processor (DMP). BMP180 is a high 
    precision, low power digital pressure sensor. Hardware version: v1.1.
    
    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Grove_IMU.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """
    def __init__(self, if_id, gr_pin): 
        """Return a new instance of an Grove IMU object. 
        
        Parameters
        ----------
        if_id : int
            IOP ID (1, 2, 3) corresponding to (PMODA, PMODB, ARDUINO).
        gr_pin: list
            A group of pins on stickit connector or arduino shield.
            
        """
        if if_id in [PMODA, PMODB]:
            if not gr_pin in [PMOD_GROVE_G3,
                              PMOD_GROVE_G4]:
                raise ValueError("IMU group number can only be G3 - G4.")
            GROVE_IMU_PROGRAM = PMOD_GROVE_IMU_PROGRAM
        elif if_id in [ARDUINO]:
            if not gr_pin in [ARDUINO_GROVE_I2C]:
                raise ValueError("IMU group number can only be I2C.")
            GROVE_IMU_PROGRAM = ARDUINO_GROVE_IMU_PROGRAM
        else:
            raise ValueError("No such IOP for grove device.")
            
        self.iop = request_iop(if_id, GROVE_IMU_PROGRAM)
        self.mmio = self.iop.mmio
        self.iop.start()
        
        if if_id in [PMODA, PMODB]:
            # Write SCL and SDA pin config
            self.mmio.write(iop_const.MAILBOX_OFFSET, gr_pin[0])
            self.mmio.write(iop_const.MAILBOX_OFFSET+4, gr_pin[1])
        
            # Write configuration and wait for ACK
            self.mmio.write(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)
            while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 1):
                pass
                
        self.reset()
                
    def reset(self):
        """Reset all the sensors on the grove IMU.
            
        Returns
        -------
        None
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xF)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0xF):
            pass
        
    def get_accl(self):
        """Get the data from the accelerometer.
        
        Returns
        -------
        list
            A list of the acceleration data along X-axis, Y-axis, and Z-axis.
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x3)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x3):
            pass
        ax = self._reg2int(self.mmio.read(iop_const.MAILBOX_OFFSET))
        ay = self._reg2int(self.mmio.read(iop_const.MAILBOX_OFFSET+4))
        az = self._reg2int(self.mmio.read(iop_const.MAILBOX_OFFSET+8))
        return [float("{0:.2f}".format(ax/16384)),
                float("{0:.2f}".format(ay/16384)),
                float("{0:.2f}".format(az/16384))]
        
    def get_gyro(self):
        """Get the data from the gyroscope.
        
        Returns
        -------
        list
            A list of the gyro data along X-axis, Y-axis, and Z-axis.
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x5)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x5):
            pass
        gx = self._reg2int(self.mmio.read(iop_const.MAILBOX_OFFSET))
        gy = self._reg2int(self.mmio.read(iop_const.MAILBOX_OFFSET+4))
        gz = self._reg2int(self.mmio.read(iop_const.MAILBOX_OFFSET+8))
        return [float("{0:.2f}".format(gx*250/32768)),
                float("{0:.2f}".format(gy*250/32768)),
                float("{0:.2f}".format(gz*250/32768))]
        
    def get_compass(self):
        """Get the data from the magnetometer.
        
        Returns
        -------
        list
            A list of the compass data along X-axis, Y-axis, and Z-axis.
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x7)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x7):
            pass
        mx = self._reg2int(self.mmio.read(iop_const.MAILBOX_OFFSET))
        my = self._reg2int(self.mmio.read(iop_const.MAILBOX_OFFSET+4))
        mz = self._reg2int(self.mmio.read(iop_const.MAILBOX_OFFSET+8))
        return [float("{0:.2f}".format(mx*1200/4096)),
                float("{0:.2f}".format(my*1200/4096)),
                float("{0:.2f}".format(mz*1200/4096))]
        
    def get_heading(self):
        """Get the value of the heading.
        
        Returns
        -------
        float
            The angle deviated from the X-axis, toward the positive Y-axis.
        
        """
        [mx, my, _] = self.get_compass()
        heading = 180 * math.atan2(my, mx) / math.pi
        if heading < 0:
            heading += 360
        return float("{0:.2f}".format(heading))
        
    def get_tilt_heading(self):
        """Get the value of the tilt heading.
        
        Returns
        -------
        float
            The tilt heading value.
        
        """
        [ax, ay, _] = self.get_accl()
        [mx, my, mz] = self.get_compass()

        try:
            pitch = math.asin(-ax)
            roll = math.asin(ay / math.cos(pitch))
        except ZeroDivisionError:
            raise RuntimeError("Value out of range or device not connected.")

        xh = mx * math.cos(pitch) + mz * math.sin(pitch)
        yh = mx * math.sin(roll) * math.sin(pitch) + \
                my * math.cos(roll) - mz * math.sin(roll) * math.cos(pitch)
        _ = -mx * math.cos(roll) * math.sin(pitch) + \
                my * math.sin(roll) + mz * math.cos(roll) * math.cos(pitch)
        tilt_heading = 180 * math.atan2(yh, xh) / math.pi
        if yh < 0:
            tilt_heading += 360
        return float("{0:.2f}".format(tilt_heading))
        
    def get_temperature(self):
        """Get the current temperature in degree C.
        
        Returns
        -------
        float
            The temperature value.
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xB)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0xB):
            pass
        value = self.mmio.read(iop_const.MAILBOX_OFFSET)
        return self._reg2float(value)
        
    def get_pressure(self):
        """Get the current pressure in Pa.
        
        Returns
        -------
        float
            The pressure value.
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xD)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0xD):
            pass
        value = self.mmio.read(iop_const.MAILBOX_OFFSET)
        return self._reg2float(value)
        
    def get_atm(self):
        """Get the current pressure in relative atmosphere.

        Returns
        -------
        float
            The related atmosphere.
        
        """
        return float("{0:.2f}".format(self.get_pressure()/101325))
        
    def get_altitude(self):
        """Get the current altitude.
        
        Returns
        -------
        float
            The altitude value.
        
        """
        pressure = self.get_pressure()
        a = pressure/101325
        b = 1/5.255
        c = 1-pow(a,b)
        altitude = 44300 * c
        return float("{0:.2f}".format(altitude))
        
    def _reg2float(self, reg):
        """Converts 32-bit register value to floats in Python.
        
        Parameters
        ----------
        reg: int
            A 32-bit register value read from the mailbox.
            
        Returns
        -------
        float
            A float number translated from the register value.
        
        """
        if reg == 0:
            return 0.0
        sign = (reg & 0x80000000) >> 31 & 0x01
        exp = ((reg & 0x7f800000) >> 23)-127
        if exp == 0:
            man = (reg & 0x007fffff)/pow(2,23)
        else:
            man = 1+(reg & 0x007fffff)/pow(2,23)
        result = pow(2,exp)*man*((sign*-2) +1)
        return float("{0:.2f}".format(result))
        
    def _reg2int(self, reg):
        """Converts 32-bit register value to signed integer in Python.
        
        Parameters
        ----------
        reg: int
            A 32-bit register value read from the mailbox.
            
        Returns
        -------
        int
            A signed integer translated from the register value.
        
        """
        result = -(reg>>31 & 0x1)*(1<<31)
        for i in range(31):
            result += (reg>>i & 0x1)*(1<<i)
        return result
        