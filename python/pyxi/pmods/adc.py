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
from . import _constants
from pyxi import MMIO
from pyxi import Overlay

PROGRAM = "./adc.bin"
ol = Overlay("pmod.bit")

class ADC(object):
    """This class controls an Analog to Digital Converter PMOD.

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by the ADC
    pmod_id : int
        The ID of the PMOD to which the ADC is attached
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """

    def __init__(self, pmod_id):
        """Return a new instance of an ADC object. 
        
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
            
        """
        if (pmod_id not in range(1,5)):
            raise ValueError("Valid PMOD IDs are: 1, 2, 3, 4.")
            
        for k in ol.get_iop_addr().keys():
            if ol.get_iop_addr()[k][0] == pmod_id:
                mmio_addr = int(ol.get_iop_addr()[k][1], 16)
                break
                
        self.iop = _iop.request_iop(pmod_id, PROGRAM)
        self.pmod_id = pmod_id
        self.mmio = MMIO(mmio_addr, _constants.IOP_MMIO_REGSIZE)

        self.iop.start()
    
    def _value(self):   
        """Get the raw value from the ADC PMOD.
        
        Note
        ----
        This method should not be used directly. Users should use read() 
        instead to read the value returned by the ADC PMOD.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        int
            The value read from the ADC PMOD in its raw format.
        
        """     
        #: Set up ADC (3 samples of channel 10)
        self.mmio.write(_constants.MAILBOX_OFFSET + 
                        _constants.MAILBOX_PY2IOP_CMD_OFFSET, 0xa0403)
        
        #: Wait for I/O processor to complete
        while (self.mmio.read(_constants.MAILBOX_OFFSET + 
                              _constants.MAILBOX_PY2IOP_CMD_OFFSET) 
                              & 0x1) == 0x1:
            time.sleep(0.001)

        return self.mmio.read(_constants.MAILBOX_OFFSET + 12)
            
    def read(self):
        """Read the value from the ADC PMOD as a string.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        str
            An floating number expressed as a string.
        
        """
        val = self._value()        
        chars = ['0','.','0','0','0','0']
        
        chars[0] = chr((val >> 24 ) & 0xff)
        chars[2] = chr((val >> 16 ) & 0xff)
        chars[3] = chr((val >> 8 )  & 0xff)
        chars[4] = chr((val)        & 0xff)
        
        return  ''.join(chars)  
    