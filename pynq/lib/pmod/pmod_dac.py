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
__email__       = "pynq_support@xilinx.com"


import time
from pynq import MMIO
from pynq.iop import request_iop
from pynq.iop import iop_const
from pynq.iop import PMODA
from pynq.iop import PMODB

PMOD_DAC_PROGRAM = "pmod_dac.bin"

class Pmod_DAC(object):
    """This class controls a Digital to Analog Converter Pmod.
    
    The Pmod DA4 (PB 200-245) is an 8 channel 12-bit digital-to-analog 
    converter run via AD5628.

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by the DAC
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """

    def __init__(self, if_id, value=None):
        """Return a new instance of a DAC object.
    
        Note
        ----
        The floating point number to be written should be in the range 
        of [0.00, 2.00]. 
        
        Parameters
        ----------
        if_id : int
            The interface ID (1, 2) corresponding to (PMODA, PMODB).
        value: float
            The value to be written to the DAC Pmod.
            
        """
        if not if_id in [PMODA, PMODB]:
            raise ValueError("No such IOP for Pmod device.")
            
        self.iop = request_iop(if_id, PMOD_DAC_PROGRAM)
        self.mmio = self.iop.mmio

        self.iop.start()

        if value:
            self.write(value)

    def write(self, value):
        """Write a floating point number onto the DAC Pmod.

        Note
        ----
        User is not allowed to use a number outside of the range [0.00, 2.00] 
        as the input value.

        Parameters
        ----------
        value : float
            The value to be written to the DAC Pmod
            
        Returns
        -------
        None

        """
        if not 0.00 <= value <= 2.00:
            raise ValueError("Requested value not in range [0.00, 2.00].")
        
        # Calculate the voltage value and write to DAC
        int_val = int(value / 0.000610351)
        self.mmio.write(iop_const.MAILBOX_OFFSET + 
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 
                        (int_val << 20) | 0x3)
        
        # Wait for I/O Processor to complete
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                              iop_const.MAILBOX_PY2IOP_CMD_OFFSET)
                              & 0x1) == 0x1:
            time.sleep(0.001)
            