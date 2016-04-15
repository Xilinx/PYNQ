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
__email__       = "xpp_support@xilinx.com"


import struct
import math
from time import sleep
from . import _iop
from . import pmod_const
from pynq import MMIO

GROVE_IMU_PROGRAM = "groveimu.bin"

class Grove_IMU(object):
    """This class controls the Grove IIC IMU. 

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Grove_IMU.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """
    def __init__(self, pmod_id, gr_id): 
        """Return a new instance of an Grove IMU object. 
        
        Note
        ----
        The pmod_id 0 is reserved for XADC (JA).
        
        Parameters
        ----------
        pmod_id : int
            The PMOD ID (1, 2, 3, 4) corresponding to (JB, JC, JD, JE).
        gr_id: int
            The group ID on StickIt, from 1 to 4.
            
        """
        if (gr_id not in range(4,5)):
            raise ValueError("Valid StickIt group ID is currently only 4.")

        self.iop = _iop.request_iop(pmod_id, GROVE_IMU_PROGRAM)
        self.mmio = self.iop.mmio
        
        self.iop.start()
        self.reset()
        
    def reset(self):
        """Reset all the sensors on the grove IMU.

        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + \
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xF)
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET + \
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0xF):
            pass
        
    def get_accl(self):
        """Get the data from the accelerometer.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        list
            A list of the acceleration data along X-axis, Y-axis, and Z-axis.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + \
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x3)
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET + \
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x3):
            pass
        ax = self._reg2float(self.mmio.read(pmod_const.MAILBOX_OFFSET))
        ay = self._reg2float(self.mmio.read(pmod_const.MAILBOX_OFFSET+1))
        az = self._reg2float(self.mmio.read(pmod_const.MAILBOX_OFFSET+2))
        return [ax, ay, az]
        
    def get_gyro(self):
        """Get the data from the gyroscope.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        list
            A list of the gyro data along X-axis, Y-axis, and Z-axis.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + \
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x5)
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET + \
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x5):
            pass
        gx = self._reg2float(self.mmio.read(pmod_const.MAILBOX_OFFSET))
        gy = self._reg2float(self.mmio.read(pmod_const.MAILBOX_OFFSET+1))
        gz = self._reg2float(self.mmio.read(pmod_const.MAILBOX_OFFSET+2))
        return [gx, gy, gz]
        
    def get_compass(self):
        """Get the data from the magnetometer.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        list
            A list of the compass data along X-axis, Y-axis, and Z-axis.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + \
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x7)
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET + \
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x7):
            pass
        mx = self._reg2float(self.mmio.read(pmod_const.MAILBOX_OFFSET))
        my = self._reg2float(self.mmio.read(pmod_const.MAILBOX_OFFSET+1))
        mz = self._reg2float(self.mmio.read(pmod_const.MAILBOX_OFFSET+2))
        return [mx, my, mz]
        
    def get_heading(self):
        """Get the value of the heading.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        float
            The angle deviated from the X-axis, toward the positive Y-axis.
        
        """
        [mx, my, mz] = self.get_compass()
        heading = 180 * math.atan2(my, mx) / math.pi
        if (heading < 0):
            heading += 360
        return heading
        
    def get_tiltheading(self):
        """Get the value of the tilt heading.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        float
            The tilt heading value.
        
        """
        [ax, ay, az] = self.get_accl()
        [mx, my, mz] = self.get_compass()
        
        pitch = math.asin(-ax)
        roll = math.asin(ay / math.cos(pitch))
        xh = mx * math.cos(pitch) + mz * math.sin(pitch)
        yh = mx * math.sin(roll) * math.sin(pitch) + \
                my * math.cos(roll) - mz * math.sin(roll) * math.cos(pitch)
        zh = -mx * math.cos(roll) * math.sin(pitch) + \
                my * math.sin(roll) + mz * math.cos(roll) * math.cos(pitch)
        tiltheading = 180 * math.atan2(yh, xh) / math.pi
        if (yh < 0):
            tiltheading += 360;
        return tiltheading
        
    def get_temperature(self):
        """Get the current temperature.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        float
            The temperature value.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + \
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xB)
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET + \
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0xB):
            pass
        value = self.mmio.read(pmod_const.MAILBOX_OFFSET)
        return self._reg2float(value)
        
    def get_pressure(self):
        """Get the current pressure.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        float
            The pressure value.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + \
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xD)
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET + \
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0xD):
            pass
        value = self.mmio.read(pmod_const.MAILBOX_OFFSET)
        return self._reg2float(value)
        
    def get_altitude(self):
        """Get the current altitude.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        float
            The altitude value.
        
        """
        pressure = self.get_pressure()
        A = pressure/101325;
        B = 1/5.25588;
        C = 1-pow(A,B);
        altitude = C /0.0000225577;
        return altitude
        
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
        if (exp == 0):
            man = (reg & 0x007fffff)/pow(2,23)
        else:
            man = 1+(reg & 0x007fffff)/pow(2,23)
        result = pow(2,exp)*(man)*((sign*-2) +1)
        return float("{0:.1f}".format(result))
        