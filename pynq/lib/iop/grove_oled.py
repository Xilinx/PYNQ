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


import time
import struct
from pynq import MMIO
from pynq.iop import request_iop
from pynq.iop import iop_const
from pynq.iop import PMODA
from pynq.iop import PMODB
from pynq.iop import ARDUINO
from pynq.iop import PMOD_GROVE_G3
from pynq.iop import PMOD_GROVE_G4
from pynq.iop import ARDUINO_GROVE_I2C

PMOD_GROVE_OLED_PROGRAM = "pmod_grove_oled.bin"
ARDUINO_GROVE_OLED_PROGRAM = "arduino_grove_oled.bin"

class Grove_OLED(object):
    """This class controls the Grove IIC OLED.

    Grove LED 128×64 Display module is an OLED monochrome 128×64 matrix
    display module. Model: OLE35046P. Hardware version: v1.1.

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Grove_OLED.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """
    def __init__(self, if_id, gr_pin): 
        """Return a new instance of an Grove OLED object. 
        
        Note
        ----
        The parameter `gr_pin` is a list organized as [scl_pin, sda_pin].
        
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
                raise ValueError("OLED group number can only be G3 - G4.")
            GROVE_OLED_PROGRAM = PMOD_GROVE_OLED_PROGRAM
        elif if_id in [ARDUINO]:
            if not gr_pin in [ARDUINO_GROVE_I2C]:
                raise ValueError("OLED group number can only be I2C.")
            GROVE_OLED_PROGRAM = ARDUINO_GROVE_OLED_PROGRAM
        else:
            raise ValueError("No such IOP for grove device.")
            
        self.iop = request_iop(if_id, GROVE_OLED_PROGRAM)
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
            
        # Use the default of horizontal mode
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
        # First write length
        self.mmio.write(iop_const.MAILBOX_OFFSET, len(text))
        
        # Then write rest of string
        for i in range(len(text)):
            self.mmio.write(iop_const.MAILBOX_OFFSET + 0x4 + i*4, 
                            ord(text[i]))
                       
        # Finally write the print string command
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x13)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x13):
            pass
            
    def clear(self):
        """Clear the OLED screen.
        
        This is done by writing empty strings into the OLED in Microblaze.
        
        Returns
        -------
        None
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xF)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0xF):
            pass
            
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
        self.mmio.write(iop_const.MAILBOX_OFFSET, row)
        self.mmio.write(iop_const.MAILBOX_OFFSET + 0x4, column)
        
        # Then write the command
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xD)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0xD):
            pass
            
    def set_normal_mode(self):
        """Set the display mode to normal.
        
        Returns
        -------
        None
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x3)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x3):
            pass
                        
    def set_inverse_mode(self):
        """Set the display mode to inverse.
        
        Returns
        -------
        None
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x5)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x5):
            pass
            
    def set_page_mode(self):
        """Set the display mode to paged.
        
        Returns
        -------
        None
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x9)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x9):
            pass
                        
    def set_horizontal_mode(self):
        """Set the display mode to horizontal.
        
        Returns
        -------
        None
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xB)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0xB):
            pass
            
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
        if brightness not in range(0,256):
            raise ValueError("Valid brightness is between 0 and 255.")
        self.mmio.write(iop_const.MAILBOX_OFFSET, brightness)
        
        # Then write the command
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x11)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x11):
            pass
            