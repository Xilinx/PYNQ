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


import time
import struct
from . import _iop
from . import pmod_const
from pynq import MMIO

GROVE_OLED_PROGRAM = "grove_oled.bin"

class Grove_OLED(object):
    """This class controls the Grove IIC OLED. 

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Grove_OLED.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """
    def __init__(self, pmod_id, gr_id): 
        """Return a new instance of an Grove OLED object. 
        
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

        self.iop = _iop.request_iop(pmod_id, GROVE_OLED_PROGRAM)
        self.mmio = self.iop.mmio
        
        self.iop.start()
        
        #: Use the default of horizontal mode
        self.set_horizontal_mode()
        
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
        #: First write length
        self.mmio.write(pmod_const.MAILBOX_OFFSET, len(text))
        
        #: Then write rest of string
        for i in range(len(text)):
            self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x4 + i*4, 
                            ord(text[i]))
                       
        #: Finally write the print string command bit[3]: str, bit[0]: valid
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x13)
        
    def clear_screen(self):
        """Clear the OLED screen.
        
        This is done by writing empty strings into the OLED in Microblaze.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xF)
                        
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
        #: First write row and column positions
        self.mmio.write(pmod_const.MAILBOX_OFFSET, row)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x4, column)
        
        #: Then write the command
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xD)
                        
    def set_normal_mode(self):
        """Set the display mode to normal.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x3)
                        
    def set_inverse_mode(self):
        """Set the display mode to inverse.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x5)
                        
    def set_page_mode(self):
        """Set the display mode to paged.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x9)
                        
    def set_horizontal_mode(self):
        """Set the display mode to horizontal.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xB)
                        
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
        #: First write the brightness
        if (brightness not in range(0,256)):
            raise ValueError("Valid brightness is between 0 and 255.")
        self.mmio.write(pmod_const.MAILBOX_OFFSET, brightness)
        
        #: Then write the command
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x11)
    