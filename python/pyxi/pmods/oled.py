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
from pyxi import MMIO
from pyxi import Overlay

PROGRAM = "./oled.bin"

class OLED(object):
    """This class controls an OLED PMOD.

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by the OLED
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """

    def __init__(self, pmod_id, text=None):         
        """Return a new instance of an OLED object. 
        
        When we call request_iop(), an exception might be raised if 
        the *force* flag is not set. Please refer to _iop.request_iop() for 
        additional details.
    
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
        self.mmio = MMIO(self.iop.mmio.base_addr, pmod_const.IOP_MMIO_REGSIZE)

        self.iop.start()
   
        if text:
            self.write(text)
                   
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
        self.clear_screen()
        time.sleep(0.01)
        self._write_string(text)
                
    def _write_string(self, text):
        """Write a new text string on the OLED.

        Note
        ----
        This should not be used directly to write a new string on the OLED. 
        Use write() instead.

        Parameters
        ----------
        text : str
            The text string to be displayed on the OLED.
            
        Returns
        -------
        None
        
        """
        #: First write length, x-pos, y-pos
        self.mmio.write(pmod_const.MAILBOX_OFFSET, len(text))
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 4, 0)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 8, 0)
        
        #: Then write rest of string
        for i in range(len(text)):
            self.mmio.write(pmod_const.MAILBOX_OFFSET + 0xC + i*4, 
                            ord(text[i]))
                       
        #: Finally write the print string command bit[3]: str, bit[0]: valid
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 
                        (0x10000 | 0x1 | 0x8))
        
    def clear_screen(self):
        """Clear the OLED screen.
        
        This is done by writing empty strings into the OLED.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """             
        self._write_string(" " * 16 * 4)
    