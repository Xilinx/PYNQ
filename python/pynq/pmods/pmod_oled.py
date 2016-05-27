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

__author__      = "Graham Schelle, Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "xpp_support@xilinx.com"


import time
from . import _iop
from . import pmod_const
from pynq import MMIO

PROGRAM = "pmod_oled.bin"

class PMOD_OLED(object):
    """This class controls an OLED PMOD.

    The PMOD OLED (PB 200-222) is 128x32 pixel monochrome organic LED (OLED) 
    panel powered by the Solomon Systech SSD1306.
    
    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by the OLED
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """

    def __init__(self, pmod_id, text=None):
        """Return a new instance of an OLED object. 
    
        Note
        ----
        The pmod_id 0 is reserved for XADC (JA).
        
        Parameters
        ----------
        pmod_id : int
            The PMOD ID (1, 2, 3, 4) corresponding to (JB, JC, JD, JE).
        text: str
            The text to be displayed after initialization.
            
        """
        self.iop = _iop.request_iop(pmod_id, PROGRAM)
        self.mmio = self.iop.mmio

        self.iop.start()
        self.clear()
        
        if text:
            self.write(text)
            
    def clear(self):
        """Clear the OLED screen.
        
        This is done by sending the clear command to the IOP.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """             
        # Write the clear command
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x1)
        
        # Wait for the command to be cleared
        while not (self.mmio.read(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x0):
            pass
            
    def write(self, text, x=0, y=0):
        """Write a new text string on the OLED.
        
        Parameters
        ----------
        text : str
            The text string to be displayed on the OLED screen.
        x : int
            The x-position of the display.
        y : int
            The y-position of the display.
            
        Returns
        -------
        None
        
        """
        if not 0 <= x <= 255:
            raise ValueError("X-position should be in [0, 255]")
        if not 0 <= y <= 255:
            raise ValueError("Y-position should be in [0, 255]")
            
        # First write length, x, y
        self.mmio.write(pmod_const.MAILBOX_OFFSET, len(text))
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x4, x)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x8, y)
        
        # Then write rest of string
        for i in range(len(text)):
            self.mmio.write(pmod_const.MAILBOX_OFFSET + 0xC + i*4, 
                            ord(text[i]))
                       
        # Finally write the print string command
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x3)
        
        # Wait for the command to be cleared
        while not (self.mmio.read(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x0):
            pass
        
    def draw_line(self, x1, y1, x2, y2):
        """Draw a straight line on the OLED.
        
        Parameters
        ----------
        x1 : int
            The x-position of the starting point.
        y1 : int
            The y-position of the starting point.
        x2 : int
            The x-position of the ending point.
        y2 : int
            The y-position of the ending point.
            
        Returns
        -------
        None
        
        """
        if not 0 <= x1 <= 255:
            raise ValueError("X-position should be in [0, 255]")
        if not 0 <= x2 <= 255:
            raise ValueError("X-position should be in [0, 255]")
        if not 0 <= y1 <= 255:
            raise ValueError("Y-position should be in [0, 255]")
        if not 0 <= y2 <= 255:
            raise ValueError("Y-position should be in [0, 255]")
            
        self.mmio.write(pmod_const.MAILBOX_OFFSET, x1)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x4, y1)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x8, x2)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0xC, y2)
                    
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x5)
                        
        while not (self.mmio.read(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x0):
            pass
            
    def draw_rect(self, x1, y1, x2, y2):
        """Draw a rectangle on the OLED.
        
        Parameters
        ----------
        x1 : int
            The x-position of the starting point.
        y1 : int
            The y-position of the starting point.
        x2 : int
            The x-position of the ending point.
        y2 : int
            The y-position of the ending point.
            
        Returns
        -------
        None
        
        """
        if not 0 <= x1 <= 255:
            raise ValueError("X-position should be in [0, 255]")
        if not 0 <= x2 <= 255:
            raise ValueError("X-position should be in [0, 255]")
        if not 0 <= y1 <= 255:
            raise ValueError("Y-position should be in [0, 255]")
        if not 0 <= y2 <= 255:
            raise ValueError("Y-position should be in [0, 255]")
            
        self.mmio.write(pmod_const.MAILBOX_OFFSET, x1)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x4, y1)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x8, x2)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0xC, y2)
                    
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x7)
                        
        while not (self.mmio.read(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x0):
            pass