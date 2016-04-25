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
from pynq import MMIO

PROGRAM = "pmod_adc.bin"

class PMOD_ADC(object):
    """This class controls an Analog to Digital Converter PMOD.

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by the ADC
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """

    def __init__(self, pmod_id):
        """Return a new instance of an ADC object.
    
        Note
        ----
        The pmod_id 0 is reserved for XADC (JA). 
        
        Parameters
        ----------
        pmod_id : int
            The PMOD ID (1, 2, 3, 4) corresponding to (JB, JC, JD, JE).
            
        """
        self.iop = _iop.request_iop(pmod_id, PROGRAM)
        self.mmio = self.iop.mmio

        self.iop.start()
    
    def _value(self, channel=0, samples=4):   
        """Get the raw value from the ADC PMOD.
        
        All the 3 available channels are enabled. The default channel is 0, 
        meaning only the first channel is read. Users can choose any channel
        from 0 to 2. In each channel, this method reads multiple samples and 
        returns the last sample. 
        
        Note
        ----
        For debug purpose, by setting "samples" to 0, the ADC can also read 
        an infinite number of samples.
        
        Note
        ----
        This method should not be used directly. Users should use read() 
        instead to read the value returned by the ADC PMOD.
        
        Parameters
        ----------
        channel : int
            The available channels, from 0 to 2.
        samples : int
            The number of samples read from each ADC channel.
        
        Returns
        -------
        int
            The value read from the ADC PMOD in its raw format.
        
        """
        #: Set up ADC (multiple samples, all the 3 channels)
        cmd_word = 0xa000F | (samples<<8)
        self.mmio.write(pmod_const.MAILBOX_OFFSET + 
                        pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, cmd_word)
        
        #: Wait for I/O processor to complete
        while (self.mmio.read(pmod_const.MAILBOX_OFFSET + 
                              pmod_const.MAILBOX_PY2IOP_CMD_OFFSET) 
                              & 0x1) == 0x1:
            time.sleep(0.001)

        #: Read the 4-th sample
        return self.mmio.read(pmod_const.MAILBOX_OFFSET + \
                                ((samples-1)*3 + channel)*4)
            
    def read(self, channel=0, samples=4):
        """Read the value from the ADC PMOD as a string.
        
        Parameters
        ----------
        channel : int
            The available channels, from 0 to 2.
        samples : int
            The number of samples read from each ADC channel.
        
        Returns
        -------
        str
            An floating number expressed as a string.
        
        """
        if not 0<=channel<=2:
            raise ValueError("Available channels are 0, 1, and 2.")
        if not 0<=samples<=255:
            raise ValueError("Available number of samples is from 0 to 255.")
        
        val = self._value(channel, samples)
        chars = ['0','.','0','0','0','0']
        chars[0] = chr((val >> 24 ) & 0xff)
        chars[2] = chr((val >> 16 ) & 0xff)
        chars[3] = chr((val >> 8 )  & 0xff)
        chars[4] = chr((val)        & 0xff)
        
        return  ''.join(chars)  
    