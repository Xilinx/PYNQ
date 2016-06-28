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

__author__      = "Parimal Patel"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "xpp_support@xilinx.com"


import time
import struct
from . import _iop
from . import pmod_const
from pynq import MMIO

PMOD_PWM_PROGRAM = "pmod_pwm.bin"

class PMOD_PWM(object):
    """This class uses the PWM of the IOP. 

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by PMOD_PWM
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
            
    """
    def __init__(self, pmod_id): 
        """Return a new instance of an GROVE_PWM object. 
        
        Note
        ----
        The pmod_id 0 is reserved for XADC (JA).
        
        Parameters
        ----------
        pmod_id : int
            The PMOD ID (1, 2, 3, 4) corresponding to (JB, JC, JD, JE).
            
        """
        
        self.iop = _iop.request_iop(pmod_id, PMOD_PWM_PROGRAM)
        self.mmio = self.iop.mmio
        
        self.iop.start()
               
    def generate(self,period,duty_cycle):
        """Generate pwm signal with desired period and percent duty cycle.
        
        Parameters
        ----------
        period : int
            The period of the tone (us), between 1 and 65536.
        duty_cycle : int
            The duty cycle in percentage.
        
        Returns
        -------
        None
                
        """
        if (period not in range(1,65536)):
            raise ValueError("Valid tone period is between 1 and 65536.")
        if (duty_cycle not in range(1,99)): 
            raise ValueError("Valid duty cycle is between 1 and 99.")
            
        cmd_word = (period << 16) | (duty_cycle << 1) 
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, cmd_word)
        while not (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
        
    def stop(self):
        """Stops PWM generation.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        None
        
        """
        cmd_word = 1
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, cmd_word)
        while not (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
            