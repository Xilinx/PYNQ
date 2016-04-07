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

__author__      = "Cathal McCabe, Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "xpp_support@xilinx.com"


import time
from . import _iop
from . import pmod_const
from pynq import MMIO
from pynq import Overlay

PROGRAM = "dpot.bin"

class DPOT(object):
    """This class controls a digital potentiometer PMOD.

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by DPOT
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """
    def __init__(self, pmod_id, overlay_name='pmod.bit'):
        """Return a new instance of a DPOT object. 
    
        Note
        ----
        The pmod_id 0 is reserved for XADC (JA).
        
        Parameters
        ----------
        pmod_id : int
            The PMOD ID (1, 2, 3, 4) corresponding to (JB, JC, JD, JE).
        overlay_name : str
            The name of the overlay for IOP.
            
        """
        self.iop = _iop.request_iop(pmod_id, PROGRAM, overlay_name)
        self.mmio = self.iop.mmio
        
        self.iop.start()
    
    def write(self, val, step=0, log_ms=0):
        """Write the value into the DPOT.
        
        This method will write the parameters "value", "step", and "log_ms" 
        all together into the DPOT PMOD. The parameter "log_ms" is only used
        for debug; users can ignore this parameter.
        
        Parameters
        ----------
        val : int
            The initial value to start, in [0, 255].
        step : int
            The number of steps when ramping up to the final value.
        log_ms : int
            The length of the log in milliseconds, for debug only.
            
        Returns
        -------
        None
        
        """
        if not 0<=val<=255:
            raise ValueError("Initial value should be in range [0, 255].")    
        if not 0<=step<=(255-val):
            raise ValueError("Ramp steps should be in range [0, {}]."\
                            .format(255-val))
        if log_ms<0:
            raise ValueError("Requested log_ms value cannot be less than 0.")
        
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)
                        
        self.mmio.write(pmod_const.MAILBOX_OFFSET, val)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+4, step)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+8, log_ms)
      
        if step == 0:
            self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                            pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 3)
        else:
            self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                            pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 5)

    def _read_hex(self, addr_offset):
        """Read Hex value from Microblaze address space.
        
        Note
        ----
        This method should not be used directly. It should be only used for 
        debug.
        
        Parameters
        ----------
        addr_offset : int
            The MMIO address to be read from.
            
        Returns
        -------
        str
            The data read from the MMIO address expressed in hex.
            
        """
        return hex(self.mmio.read(addr_offset)) 
