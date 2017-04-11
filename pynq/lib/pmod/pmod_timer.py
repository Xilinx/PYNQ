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
from pynq import MMIO
from pynq.iop import request_iop
from pynq.iop import iop_const
from pynq.iop import PMODA
from pynq.iop import PMODB

PMOD_TIMER_PROGRAM = "pmod_timer.bin"

class Pmod_Timer(object):
    """This class uses the timer's capture and generation capabilities.

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Pmod_Timer.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    clk : int
        The clock period of the IOP in ns.
            
    """
    def __init__(self, if_id, index): 
        """Return a new instance of an Pmod_Timer object. 
        
        Parameters
        ----------
        if_id : int
            The interface ID (1, 2) corresponding to (PMODA, PMODB).
        index : int
            The specific pin that runs timer.
            
        """
        if not if_id in [PMODA, PMODB]:
            raise ValueError("No such IOP for Pmod device.")
            
        self.iop = request_iop(if_id, PMOD_TIMER_PROGRAM)
        self.mmio = self.iop.mmio
        self.clk = int(pow(10,9)/iop_const.IOP_FREQUENCY)
        self.iop.start()
        
        # Write PWM pin config
        self.mmio.write(iop_const.MAILBOX_OFFSET, index)
        
        # Write configuration and wait for ACK
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x1)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
        
    def stop(self):
        """This method stops the timer.
        
        Returns
        -------
        None
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x3)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
            
    def generate_pulse(self, period, times=0):
        """Generate pulses every (period) clocks for a number of times.
        
        The default is to generate pulses every (period) IOP clocks forever
        until stopped. The pulse width is equal to the IOP clock period.
        
        Parameters
        ----------
        period : int
            The period of the generated signals.
        times : int
            The number of times for which the pulses are generated.
            
        Returns
        -------
        None
        
        """
        if times == 0:
            # Generate pulses forever
            if period not in range(3,4294967296):
                raise ValueError("Valid period is between 3 and 4294967296.")
                
            self.mmio.write(iop_const.MAILBOX_OFFSET, period)
            self.mmio.write(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x5)
            while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
                pass
                
        elif 1 <= times < 255:
            # Generate pulses for a certain times
            if period not in range(3,16777217):
                raise ValueError("Valid period is between 3 and 16777217.")
                
            self.mmio.write(iop_const.MAILBOX_OFFSET, ((period-2)<<8)|times)
            self.mmio.write(iop_const.MAILBOX_OFFSET +
                            iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x7)
            while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
                pass
                
        else:
            raise ValueError("Valid number of times is between 1 and 255.")
            
    def event_detected(self, period):
        """Detect a rising edge or high-level in (period) clocks.
        
        Parameters
        ----------
        period : int
            The period of the generated signals.
            
        Returns
        -------
        int 
            1 if any event is detected, and 0 if no event is detected.
        
        """
        if period not in range(52,4294967296):
            raise ValueError("Valid period is between 52 and 4294967296.") 
        
        self.mmio.write(iop_const.MAILBOX_OFFSET, period-2)
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0x9)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
        return self.mmio.read(iop_const.MAILBOX_OFFSET)
        
    def event_count(self, period):
        """Count the number of rising edges detected in (period) clocks.
        
        Parameters
        ----------
        period : int
            The period of the generated signals.
            
        Returns
        -------
        int
            The number of events detected.
            
        """
        if period not in range(52,4294967297):
            raise ValueError("Valid period is between 52 and 4294967297.")
            
        self.mmio.write(iop_const.MAILBOX_OFFSET, period-2)
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xB)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
        return self.mmio.read(iop_const.MAILBOX_OFFSET)
        
    def get_period_ns(self):
        """Measure the period between two successive rising edges.
            
        Returns
        -------
        int
            Measured period in ns.
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 0xD)
        while not (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                  iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 0):
            pass
        return self.mmio.read(iop_const.MAILBOX_OFFSET) * self.clk
        