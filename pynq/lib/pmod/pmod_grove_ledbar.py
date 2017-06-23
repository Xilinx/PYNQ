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


from . import Pmod
from . import PMOD_GROVE_G1
from . import PMOD_GROVE_G2
from . import PMOD_GROVE_G3
from . import PMOD_GROVE_G4


__author__ = "Naveen Purushotham"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


PMOD_GROVE_LEDBAR_PROGRAM = "pmod_grove_ledbar.bin"
HIGH = 0xFF
LOW = 0x01
MED = 0xAA
OFF = 0x00
CONFIG_IOP_SWITCH = 0x1
RESET = 0x3
WRITE_LEDS = 0x5
SET_BRIGHTNESS = 0x7
SET_LEVEL = 0x9
READ_LEDS = 0xB


class Grove_LEDbar(object):
    """This class controls the Grove LED BAR. 
    
    Grove LED Bar is comprised of a 10 segment LED gauge bar and an MY9221 LED
    controlling chip. Model: LED05031P. Hardware version: v2.0.
    
    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
        
    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Grove LEDbar object.
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on pmod-grove adapter.

        """
        if gr_pin not in [PMOD_GROVE_G1,
                          PMOD_GROVE_G2,
                          PMOD_GROVE_G3,
                          PMOD_GROVE_G4]:
            raise ValueError("Group number can only be G1 - G4.")

        self.microblaze = Pmod(mb_info, PMOD_GROVE_LEDBAR_PROGRAM)
        self.microblaze.write_mailbox(0, gr_pin)
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

    def reset(self):
        """Resets the LEDbar.
        
        Clears the LED bar, sets all LEDs to OFF state.
            
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(RESET)
        
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
        self.microblaze.write_mailbox(0, data_in)
        self.microblaze.write_blocking_command(WRITE_LEDS)

    def write_brightness(self, data_in, brightness=[MED]*10):
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
            Each element controls a single LED.
        
        Returns
        -------
        None
        
        """
        data = [data_in]
        data += brightness
        self.microblaze.write_mailbox(0, data)
        self.microblaze.write_blocking_command(SET_BRIGHTNESS)

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
        self.microblaze.write_mailbox(0, [level, bright_level, green_to_red])
        self.microblaze.write_blocking_command(SET_LEVEL)

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
        self.microblaze.write_blocking_command(READ_LEDS)
        value = self.microblaze.read_mailbox(0x0)
        return bin(value)[2:].zfill(10)
