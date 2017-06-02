#   Copyright (c) 2016, NECST Laboratory, Politecnico di Milano
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


from . import Arduino
from . import ARDUINO_GROVE_I2C


__author__ = "Marco Rabozzi, Luca Cerina, Giuseppe Natale"
__copyright__ = "Copyright 2016, NECST Laboratory, Politecnico di Milano"


ARDUINO_GROVE_COLOR_PROGRAM = "arduino_grove_color.bin"
CONFIG_IOP_SWITCH = 0x1
READ_DATA = 0x2
READ_AND_LOG_DATA = 0x3
STOP_LOG = 0xC


class Grove_Color(object):
    """This class controls the Grove IIC Color sensor. 
    
    Grove Color sensor based on the TCS3414CS. 
    Hardware version: v1.3.
    
    Attributes
    ----------
    microblaze : Arduino
        Microblaze processor instance used by this module.

    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Grove_Color object.  
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on arduino-grove shield.
            
        """
        if gr_pin not in [ARDUINO_GROVE_I2C]:
            raise ValueError("Color group number can only be I2C.")

        self.microblaze = Arduino(mb_info, ARDUINO_GROVE_COLOR_PROGRAM)
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

    def read(self):
        """Read the color values from the Grove Color peripheral.

        The output contains 4 integer values: Red, Green, Blu and Clear.
        Clear represents the value of the sensor if no color filters are
        applied.

        Returns
        -------
        list
            A list of (red, green, blue, clear) components.

        """
        self.microblaze.write_blocking_command(READ_DATA)
        colors = self.microblaze.read_mailbox(0, 4)
        return colors
