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

__author__      = "Naveen Purushotham"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "xpp_support@xilinx.com"


import time
import struct
from . import _iop
from . import pmod_const
from pynq import MMIO

GROVE_LEDBAR_PROGRAM = "grove_ledbar.bin"

class Grove_LEDbar(object):
    """This class controls the Grove LED BAR. 
    
    Grove LED Bar is comprised of a 10 segment LED gauge bar and an MY9221 LED
    controlling chip. Model: LED05031P. Hardware version: v2.0.
    
    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Grove_LEDbar.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """
    def __init__(self, pmod_id, gr_id): 
        """Return a new instance of an Grove LEDbar object. 
        
        Note
        ----
        The pmod_id 0 is reserved for XADC (JA).
        Valid StickIt group ID is currently only 1.
        
        Parameters
        ----------
        pmod_id : int
            The PMOD ID (1, 2, 3, 4) corresponding to (JB, JC, JD, JE).
        gr_id: int
            The group ID on StickIt, from 1 to 4.
            
        """
        if (gr_id  != 1):
            raise ValueError("Valid StickIt group ID is currently only 1.")
        self.iop = _iop.request_iop(pmod_id, GROVE_LEDBAR_PROGRAM)
        self.mmio = self.iop.mmio
        
        self.iop.start()

    def reset(self):
        """Resets the LEDbar.
        
        Clears the LEDbar, sets all LEDs to OFF state.

        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x01)
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x1):
            pass        
        
    def write_binary(self, data_in):
        """Set individual LEDs in the LEDbar based on 10 bit binary input.
        
        Each bit in the 10-bit `data_in` points to a LED position on the
        LEDbar. Red LED corresponds to the LSB, while green LED corresponds
        to the MSB.
        
        Parameters
        ----------
        data_in : int
            10 LSBs of this parameter control the LEDbar.
        
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET, data_in)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x3)        
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x3):
            pass                    
            
    def write_brightness(self, data_in, brightness = []):
        """Set individual LEDs with 3 level brightness control.
        
        Each bit in the 10-bit `data_in` points to a LED position on the
        LEDbar. Red LED corresponds to the LSB, while green LED corresponds
        to the MSB.
        
        Brightness of each LED is controlled by the brightness parameter.
        There are 3 perceivable levels of brightness:
        HIGH = 0xFF
        MED  = 0xAA
        LOW  = 0x01
        
        Parameters
        ----------
        data_in : int
            10 LSBs of this parameter control the LEDbar.
        brightness : list
            Each List element controls a single LED.
        
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET, data_in)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 4, brightness[0])        
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 8, brightness[1])        
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 12, brightness[2])        
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 16, brightness[3])        
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 20, brightness[4])        
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 24, brightness[5])        
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 28, brightness[6])        
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 32, brightness[7])        
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 36, brightness[8])        
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 40, brightness[9])        
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x5)        
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x5):
            pass                            
                        
    def write_level(self, level, brightness, green_to_red):
        """Set the level to which the leds are to be lit in levels 1 - 10.
        
        Level can be set in both directions. `set_level` operates by setting
        all LEDs to the same brightness level.
        
        Brightness of each LED is controlled by the brightness parameter.
        There are 3 perceivable levels of brightness:
        HIGH = 0xFF
        MED  = 0xAA
        LOW  = 0x01
        
        `green_to_red` indicates the direction, either from red to green when
        it is 0, or green to red when it is 1.
        
        Parameters
        ----------
        level : int
            10 levels exist, where 1 is minimum and 10 is maximum.
        brightness : int
            Controls brightness of all LEDs in the LEDbar.
        green_to_red : int
            Sets the direction of the sequence.
        
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET, level)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x4, brightness)        
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x8, green_to_red)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x7)        
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x7):
            pass

    def read(self):
        """Reads the current status of LEDbar.
        
        Reads the current status of LEDbar and returns a 10-bit binary string.
        Each bit position corresponds to a LED position in the LEDbar,
        and bit value corresponds to the LED state.
        
        Red LED corresponds to the LSB, while green LED corresponds
        to the MSB.

        Parameters
        ----------
        None
            
        Returns
        -------
        str
            String of 10 binary bits.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x9)        
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x9):
            pass              
        value = self.mmio.read(pmod_const.MAILBOX_OFFSET)
        return (bin(value)[2:].zfill(10))
        