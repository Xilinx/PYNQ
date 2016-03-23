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

PROGRAM = "./dac.bin"
ol = Overlay("pmod.bit")

class DAC(object):
    """This class controls a Digital to Analog Converter PMOD.

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by the DAC
    pmod_id : int
        The ID of the PMOD to which the DAC is attached
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """

    def __init__(self, pmod_id, value=None):
        """Return a new instance of a DAC object. 
        
        When we call request_iop(), an exception might be raised if 
        the *force* flag is not set. Please refer to _iop.request_iop() for 
        additional details.
    
        Note
        ----
        The pmod_id 0 is reserved for XADC (JA). The floating point number
        to be written should be in the range of [0.00, 2.00]. 
        
        Parameters
        ----------
        pmod_id : int
            The PMOD ID (1, 2, 3, 4) corresponding to (JB, JC, JD, JE).
        value: float
            The value to be written to the DAC PMOD.
            
        """
        if (pmod_id not in range(1,5)):
            raise ValueError("Valid PMOD IDs are: 1, 2, 3, 4.")
            
        #: The IOP 0 controlls PMOD 1, and so on
        mmio_addr = int(ol.get_mb_addr()[pmod_id-1], 16)
                
        self.iop = _iop.request_iop(pmod_id, PROGRAM)
        self.pmod_id = pmod_id
        self.mmio = MMIO(mmio_addr, pmod_const.IOP_MMIO_REGSIZE)    

        self.iop.start()

        if value:
            self.write(value)

    def write(self, value):
        """Write a floating point number onto the DAC PMOD.

        Note
        ----
        User is not allowed to use a number outside of the range [0.00, 2.00] 
        as the input value.

        Parameters
        ----------
        value : float
            The value to be written to the DAC PMOD
            
        Returns
        -------
        None

        """
        if not 0.00 <= value <= 2.00:
            raise ValueError("Requested value not in range [0.00, 2.00].")
        
        #: Calculate the voltage value and write to DAC
        intVal = int(value / (0.000610351))
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 
                        (intVal << 20) | (0x3))
        
        #: Wait for I/O Processor to complete
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET + \
                              pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) \
                              & 0x1) == 0x1:
            time.sleep(0.001)
            