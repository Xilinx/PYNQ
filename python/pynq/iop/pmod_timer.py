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
__email__       = "pynq_support@xilinx.com"


import time
import struct
from . import _iop
from . import pmod_const
from pynq import MMIO

PMOD_TIMER_PROGRAM = "pmod_timer.bin"

class PMOD_Timer(object):
    """This class uses the timer's capture and generation capabilities.

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by PMOD_TIMER.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    clk : int
        The clock period of the IOP in ns.
            
    """
    def __init__(self, pmod_id): 
        """Return a new instance of an PMOD_TIMER object. 
        
        Note
        ----
        The pmod_id 0 is reserved for XADC (JA).
        
        Parameters
        ----------
        pmod_id : int
            The PMOD ID (1, 2, 3, 4) corresponding to (JB, JC, JD, JE).
            
        """
        self.iop = _iop.request_iop(pmod_id, PMOD_TIMER_PROGRAM)
        self.mmio = self.iop.mmio
        self.clk = int(pow(10,9)/pmod_const.IOP_FREQUENCY)
        
        self.iop.start()
        
    def stop(self):
        """This method stops the timer.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x1)
        while not (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                    pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
            
    def generate_pulse(self, period, times=0):
        """Generate pulses every (period+2) clocks for a number of times.
        
        The default is to generate pulses every (period+2) IOP clocks forever
        until stopped. The pulse width is equal to the IOP clock period.
        
        Parameters
        ----------
        period : int
            A parameter related to the period of the generated signals.
        times : int
            The number of times for which the pulses are generated.
            
        Returns
        -------
        None
        
        """
        if times == 0:
            # Generate pulses forever
            if (period not in range(1,4294967294)):
                raise ValueError("Valid period is between 1 and 4294967294.")
                
            self.mmio.write(pmod_const.MAILBOX_OFFSET, period)
            self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                            pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x2)
            while not (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
                pass
                
        elif 1 <= times < 255:
            # Generate pulses for a certain times
            if (period not in range(1,16777215)):
                raise ValueError("Valid period is between 1 and 16777215.")
                
            self.mmio.write(pmod_const.MAILBOX_OFFSET, (period << 8) | times)
            self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                            pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x4)
            while not (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
                pass
                
        else:
            raise ValueError("Valid number of times is between 1 and 255.")
            
    def event_detected(self, period):
        """Detect a rising edge or high-level in (period+2) clocks.
        
        Parameters
        ----------
        period : int
            A parameter related to the period of the generated signals.
            
        Returns
        -------
        int 
            1 if any event is detected, and 0 if no event is detected.
        
        """
        if (period not in range(50,4294967294)):
            raise ValueError("Valid period is between 50 and 4294967294.") 
        
        self.mmio.write(pmod_const.MAILBOX_OFFSET, period)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x8)
        while not (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                    pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
        return self.mmio.read(pmod_const.MAILBOX_OFFSET)
        
    def event_count(self, period):
        """Count the number of rising edges detected in (period+2) clocks.
        
        Parameters
        ----------
        period : int
            A parameter related to the period of the generated signals.
            
        Returns
        -------
        int
            The number of events detected.
            
        """
        if (period not in range(50,4294967295)):
            raise ValueError("Valid period is between 50 and 4294967295.")
            
        self.mmio.write(pmod_const.MAILBOX_OFFSET, period)
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x10)
        while not (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                    pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
        return self.mmio.read(pmod_const.MAILBOX_OFFSET)
        
    def get_period_ns(self):
        """Measure the period between two successive rising edges.
        
        Parameters
        ----------
        None
            
        Returns
        -------
        int
            Measured period in ns.
        
        """
        self.mmio.write(pmod_const.MAILBOX_OFFSET+\
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x20)
        while not (self.mmio.read(pmod_const.MAILBOX_OFFSET+\
                    pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
        return self.mmio.read(pmod_const.MAILBOX_OFFSET) * self.clk
        