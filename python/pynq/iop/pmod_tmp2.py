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
__email__       = "pynq_support@xilinx.com"


import time
from pynq import MMIO
from pynq.iop import request_iop
from pynq.iop import iop_const
from pynq.iop import PMODA
from pynq.iop import PMODB

PMOD_TMP2_PROGRAM = "pmod_tmp2.bin"
PMOD_TMP2_LOG_START = iop_const.MAILBOX_OFFSET+16
PMOD_TMP2_LOG_END = PMOD_TMP2_LOG_START+(1000*4)

class Pmod_TMP2(object):
    """This class controls a temperature sensor Pmod.
    
    The Pmod TMP2 (PB 200-221) is an ambient temperature sensor powered by 
    ADT7420.

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by TMP2.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    log_interval_ms : int
        Time in milliseconds between sampled reads of the TMP2 sensor.
        
    """
    def __init__(self, if_id):
        """Return a new instance of a TMP2 object. 
        
        Parameters
        ----------
        if_id : int
            The interface ID (1, 2) corresponding to (PMODA, PMODB).
            
        """
        if not if_id in [PMODA, PMODB]:
            raise ValueError("No such IOP for Pmod device.")
            
        self.iop = request_iop(if_id, PMOD_TMP2_PROGRAM)
        self.mmio = self.iop.mmio
        self.log_interval_ms = 1000
        
        self.iop.start()
        
    def read(self):
        """Read current temperature value measured by the Pmod TMP2.
        
        Returns
        -------
        float
            The current sensor value.
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 3)
                        
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 3):
            pass
            
        value = self.mmio.read(iop_const.MAILBOX_OFFSET)
        return self._reg2float(value)
        
    def set_log_interval_ms(self,log_interval_ms):
        """Set the sampling interval for the Pmod TMP2.
        
        Parameters
        ----------
        log_interval_ms : int
            Time in milliseconds between sampled reads of the TMP2 sensor
            
        Returns
        -------
        None
        
        """
        if log_interval_ms < 0:
            raise ValueError("Log length should not be less than 0.")
        
        self.log_interval_ms = log_interval_ms
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, self.log_interval_ms)
        
    def start_log(self):
        """Start recording multiple values in a log.
        
        This method will first call set_log_interval_ms() before writting to
        the MMIO.
            
        Returns
        -------
        None
        
        """
        self.set_log_interval_ms(self.log_interval_ms)
        self.mmio.write(iop_const.MAILBOX_OFFSET+\
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 7)
                        
    def stop_log(self):
        """Stop recording multiple values in a log.
        
        Simply write to the MMIO to stop the log.
            
        Returns
        -------
        None
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)
                        
    def get_log(self):
        """Return list of logged samples.
            
        Returns
        -------
        List of valid samples from the temperature sensor in Celsius.
        
        """
        # First stop logging
        self.stop_log()

        # Prep iterators and results list
        head_ptr = self.mmio.read(iop_const.MAILBOX_OFFSET+0x8)
        tail_ptr = self.mmio.read(iop_const.MAILBOX_OFFSET+0xC)
        temps = list()

        # Sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            for i in range(head_ptr,tail_ptr,4):
                temps.append(self._reg2float(self.mmio.read(i)))
        else:
            for i in range(head_ptr,PMOD_TMP2_LOG_END,4):
                temps.append(self._reg2float(self.mmio.read(i)))
            for i in range(PMOD_TMP2_LOG_START,tail_ptr,4):
                temps.append(self._reg2float(self.mmio.read(i)))
        return temps
        
    def _reg2float(self, reg):
        """Translate the register value to a floating-point number.
        
        Note
        ----
        The float precision is specified to be 1 digit after the decimal 
        point.
        
        Bit [31]    (1 bit)        ->    Sign (S)
        Bit [30:23] (8 bits)       ->    Exponent (E)
        Bit [22:0]  (23 bits)      ->    Mantissa (M)
        
        Parameters
        ----------
        reg : int
            A 4-byte integer.
            
        Returns
        -------
        float
            The floating-point number translated from the input.
            
        """
        if reg == 0:
            return 0.0
        sign = (reg & 0x80000000) >> 31 & 0x01
        exp = ((reg & 0x7f800000) >> 23)-127
        if exp == 0:
            man = (reg & 0x007fffff)/pow(2,23)
        else:
            man = 1+(reg & 0x007fffff)/pow(2,23)
        result = pow(2,exp)*man*((sign*-2) +1)
        return float("{0:.1f}".format(result))
