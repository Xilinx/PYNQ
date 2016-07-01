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

__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "xpp_support@xilinx.com"


from pynq.iop import pmod_const
from pynq.iop.pmod_io import PMOD_IO

class Grove_PIR(PMOD_IO):
    """This class controls the PIR motion sensor.
    
    The grove PIR motion sensor is attached to a PMOD. This class inherits 
    from the PMODIO class. Hardware version: v1.2.
    
    Attributes
    ----------
    iop : _IOP
        The _IOP object returned from the DevMode.
    index : int
        The index of the PMOD pin {0, 1, 7, 6}.
    
    """
    def __init__(self, pmod_id, gr_id): 
        """Return a new instance of a PIR object. 
        
        Only checks the gr_id, since other parameters can be checked by the 
        PMODIO class. The gr_id starts from 1, at the StickIt socket farthest
        away from the board.
        
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
        if (gr_id not in range(1,5)):
            raise ValueError("Valid StickIt group IDs are 1 - 4.")
            
        super().__init__(pmod_id, pmod_const.STICKIT_PINS_GR[gr_id][0],'in')
        
    def read(self):
        """Receive the value from the PIR sensor.
        
        Returns 0 when there is no motion, and returns 1 otherwise.
        
        Parameters
        ---------
        None
        
        Returns
        -------
        int
            The data (0 or 1) read from the PIR sensor.
        
        """
        return super().read()