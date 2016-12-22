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
__email__       = "pynq_support@xilinx.com"


import time
import struct
from pynq import MMIO
from pynq.iop import request_iop
from pynq.iop import iop_const
from pynq.iop import PMODA
from pynq.iop import PMODB
from pynq.iop import ARDUINO
from pynq.iop import PMOD_GROVE_G1
from pynq.iop import PMOD_GROVE_G2
from pynq.iop import PMOD_GROVE_G3
from pynq.iop import PMOD_GROVE_G4
from pynq.iop import ARDUINO_GROVE_G1
from pynq.iop import ARDUINO_GROVE_G2
from pynq.iop import ARDUINO_GROVE_G3
from pynq.iop import ARDUINO_GROVE_G4
from pynq.iop import ARDUINO_GROVE_G5
from pynq.iop import ARDUINO_GROVE_G6
from pynq.iop import ARDUINO_GROVE_G7

PMOD_GROVE_LEDBAR_PROGRAM = "pmod_grove_ledbar.bin"
ARDUINO_GROVE_LEDBAR_PROGRAM = "arduino_grove_ledbar.bin"

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
    def __init__(self, if_id, gr_pin): 
        """Return a new instance of an Grove LEDbar object. 
        
        Note
        ----
        Valid StickIt group ID is currently only 1.
        
        Parameters
        ----------
        if_id : int
            IOP ID (1, 2, 3) corresponding to (PMODA, PMODB, ARDUINO).
        gr_pin: list
            A group of pins on stickit connector or arduino shield.
            
        """
        if if_id in [PMODA, PMODB]:
            if not gr_pin in [PMOD_GROVE_G1,
                              PMOD_GROVE_G2,
                              PMOD_GROVE_G3,
                              PMOD_GROVE_G4]:
                raise ValueError("LEDbar group number can only be G1 - G4.")
            GROVE_LEDBAR_PROGRAM = PMOD_GROVE_LEDBAR_PROGRAM
        elif if_id in [ARDUINO]:
            if not gr_pin in [ARDUINO_GROVE_G1,
                              ARDUINO_GROVE_G2,
                              ARDUINO_GROVE_G3,
                              ARDUINO_GROVE_G4,
                              ARDUINO_GROVE_G5,
                              ARDUINO_GROVE_G6,
                              ARDUINO_GROVE_G7]:
                raise ValueError("LEDbar group number can only be G1 - G7.")
            GROVE_LEDBAR_PROGRAM = ARDUINO_GROVE_LEDBAR_PROGRAM
        else:
            raise ValueError("No such IOP for grove device.")
            
        self.iop = request_iop(if_id, GROVE_LEDBAR_PROGRAM)
        self.mmio = self.iop.mmio
        self.iop.start()
        
        # Write GPIO pin config
        self.mmio.write(iop_const.MAILBOX_OFFSET, gr_pin[0])
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, gr_pin[1])
            
        # Write configuration and wait for ACK
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                              iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
            
    def reset(self):
        """Resets the LEDbar.
        
        Clears the LED bar, sets all LEDs to OFF state.
            
        Returns
        -------
        None
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET + 
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x3)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
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
        self.mmio.write(iop_const.MAILBOX_OFFSET, data_in)
        self.mmio.write(iop_const.MAILBOX_OFFSET + 
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x5)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
            
    def write_brightness(self, data_in, brightness=[0xAA]*10):
        """Set individual LEDs with 3 level brightness control.
        
        Each bit in the 10-bit `data_in` points to a LED position on the
        LEDbar. Red LED corresponds to the LSB, while green LED corresponds
        to the MSB.
        
        Brightness of each LED is controlled by the brightness parameter.
        There are 3 perceivable levels of brightness:
        0xFF : HIGH
        0xAA : MED
        0x01 : LOW
        
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
        self.mmio.write(iop_const.MAILBOX_OFFSET, data_in)
        for i in range(0,10):
            self.mmio.write(iop_const.MAILBOX_OFFSET + 4*(i+1),
                            brightness[i])
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x7)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
        
    def write_level(self, level, bright_level, green_to_red):
        """Set the level to which the leds are to be lit in levels 1 - 10.
        
        Level can be set in both directions. `set_level` operates by setting
        all LEDs to the same brightness level.
        
        There are 4 preset brightness levels:
        bright_level = 0: off
        bright_level = 1: low
        bright_level = 2: medium
        bright_level = 3: maximum
        
        `green_to_red` indicates the direction, either from red to green when
        it is 0, or green to red when it is 1.
        
        Parameters
        ----------
        level : int
            10 levels exist, where 1 is minimum and 10 is maximum.
        bright_level : int
            Controls brightness of all LEDs in the LEDbar, from 0 to 3.
        green_to_red : int
            Sets the direction of the sequence.
        
        Returns
        -------
        None
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET, level)
        self.mmio.write(iop_const.MAILBOX_OFFSET + 0x4, bright_level)
        self.mmio.write(iop_const.MAILBOX_OFFSET + 0x8, green_to_red)
        self.mmio.write(iop_const.MAILBOX_OFFSET + 
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x9)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass

    def read(self):
        """Reads the current status of LEDbar.
        
        Reads the current status of LED bar and returns 10-bit binary string.
        Each bit position corresponds to a LED position in the LEDbar,
        and bit value corresponds to the LED state.
        
        Red LED corresponds to the LSB, while green LED corresponds
        to the MSB.
            
        Returns
        -------
        str
            String of 10 binary bits.
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET + 
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xB)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
        value = self.mmio.read(iop_const.MAILBOX_OFFSET)
        return bin(value)[2:].zfill(10)
        