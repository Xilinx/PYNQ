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
from . import PMOD_GROVE_G3
from . import PMOD_GROVE_G4


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


PMOD_GROVE_OLED_PROGRAM = "pmod_grove_oled.bin"


class PmodGroveOLED(object):
    """This class controls the Grove IIC OLED.

    Grove LED 128×64 Display module is an OLED monochrome 128×64 matrix
    display module. Model: OLE35046P. Hardware version: v1.1.

    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
        
    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Grove OLED object. 
        
        Note
        ----
        The parameter `gr_pin` is a list organized as [scl_pin, sda_pin].
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on pmod-grove adapter.
            
        """
        if gr_pin not in [PMOD_GROVE_G3,
                          PMOD_GROVE_G4]:
            raise ValueError("Group number can only be G3 - G4.")

        self.microblaze = Pmod(mb_info, PMOD_GROVE_OLED_PROGRAM)
        self.microblaze.write_mailbox([0, 4], gr_pin)
        self.microblaze.write_blocking_command(1)

        self.set_horizontal_mode()
        self.clear()
        
    def write(self, text):
        """Write a new text string on the OLED.
        
        Clear the screen first to correctly show the new text.

        Parameters
        ----------
        text : str
            The text string to be displayed on the OLED screen.
            
        Returns
        -------
        None
        
        """
        # First write length, then write rest of string
        offsets = [i*4 for i in range(len(text)+1)]
        data = [len(text)]
        data += [ord(char) for char in text]
        self.microblaze.write_mailbox(offsets, data)

        # Finally write the print string command
        self.microblaze.write_blocking_command(0x13)

    def clear(self):
        """Clear the OLED screen.
        
        This is done by writing empty strings into the OLED in Microblaze.
        
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(0xF)

    def set_position(self, row, column):
        """Set the position of the display.
        
        The position is indicated by (row, column).
        
        Parameters
        ----------
        row : int
            The row number to start the display.
        column : int
            The column number to start the display.
        
        Returns
        -------
        None
        
        """
        # First write row and column positions
        self.microblaze.write_mailbox([0, 4], [row, column])
        
        # Then write the command
        self.microblaze.write_blocking_command(0xD)

    def set_normal_mode(self):
        """Set the display mode to normal.
        
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(0x3)

    def set_inverse_mode(self):
        """Set the display mode to inverse.
        
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(0x5)

    def set_page_mode(self):
        """Set the display mode to paged.
        
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(0x9)

    def set_horizontal_mode(self):
        """Set the display mode to horizontal.
        
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(0xB)

    def set_contrast(self, brightness):
        """Set the contrast level for the OLED display.
        
        The contrast level is in [0, 255].
        
        Parameters
        ----------
        brightness : int
            The brightness of the display.
        
        Returns
        -------
        None
        
        """
        # First write the brightness
        if brightness not in range(0, 256):
            raise ValueError("Valid brightness is between 0 and 255.")
        self.microblaze.write_mailbox([0], [brightness])
        
        # Then write the command
        self.microblaze.write_blocking_command(0x11)
