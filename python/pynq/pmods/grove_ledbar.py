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
        
        Parameters
        ----------
        pmod_id : int
            The PMOD ID (1, 2, 3, 4) corresponding to (JB, JC, JD, JE).
        gr_id: int
            The group ID on StickIt, from 1 to 4.
            
        """
        self.iop = _iop.request_iop(pmod_id, GROVE_LEDBAR_PROGRAM)
        self.mmio = self.iop.mmio
        
        self.iop.start()
        
    def self_check(self):
        """Runs a small demo of the LEDbar.
        
        Clear the LEDbar after the self check is complete.

        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x07)
        self.mmio.write(pmod_const.MAILBOX_OFFSET, 0x00)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x4, 0)		
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x8, 0)					
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x7):
            pass
			
    def reset(self):
        """Resets the LEDbar.
        
        Clear the LEDbar.

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
        
    def set_ledbar_onehot(self, brightness, data_in, red_to_green):
        """Set individual Leds in the LEDbar based on 16 bit one-hot control.
        
        brightness and Direction of the LEDbar can also be controlled
        
        Parameters
        ----------
        brightness : 
            Controls the brightness of the LEDbar  min - 0x01, max - 0xFF .
        data_in : 
            10 LSBs of the 16 bit data control the LEDbar.
			Control is one hot
		red_to_green : 
            Sets the direction of the sequence
			0 - red to green
            1 - green to red			
		
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET, brightness)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x4, data_in)		
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x8, red_to_green)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x3)		
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x3):				
            pass    				
                        
    def set_ledbar_level(self, brightness, level, red_to_green):
        """Set the level to which the leds are light in 1-10.
        
        1 can be red or green led based on red_to_green parameter.
        
        Parameters
        ----------
        brightness : 
            Controls the brightness of the LEDbar  min - 0x01, max - 0xFF .
        level : 
            10 levels exist on the LEDbar.
			1 is minimum and 10 is maximum
		red_to_green : 
            Sets the direction of the sequence
			0 - red to green
            1 - green to red.	
        
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET, brightness)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x4, level)		
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 0x8, red_to_green)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x5)		
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                                pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0x5):
            pass								
    
