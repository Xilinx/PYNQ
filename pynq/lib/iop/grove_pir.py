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
__email__       = "pynq_support@xilinx.com"


from pynq.iop import iop_const
from pynq.iop import Pmod_IO
from pynq.iop import Arduino_IO
from pynq.iop import PMODA
from pynq.iop import PMODB
from pynq.iop import ARDUINO
from pynq.iop import PMOD_GROVE_G1
from pynq.iop import PMOD_GROVE_G2
from pynq.iop import ARDUINO_GROVE_G1
from pynq.iop import ARDUINO_GROVE_G2
from pynq.iop import ARDUINO_GROVE_G3
from pynq.iop import ARDUINO_GROVE_G4
from pynq.iop import ARDUINO_GROVE_G5
from pynq.iop import ARDUINO_GROVE_G6
from pynq.iop import ARDUINO_GROVE_G7

class Grove_PIR(object):
    """This class controls the PIR motion sensor.
    
    The grove PIR motion sensor is attached to a Pmod or an Arduino interface. 
    Hardware version: v1.2.
    
    Attributes
    ----------
    pir_iop : object
        The Pmod IO or Arduino IO object.
    
    """
    def __init__(self, if_id, gr_pin):
        """Return a new instance of a PIR object. 
        
        Parameters
        ----------
        if_id : int
            IOP ID (1, 2, 3) corresponding to (PMODA, PMODB, ARDUINO).
        gr_pin: list
            A group of pins on stickit connector or arduino shield.
            
        """
        if if_id in [PMODA, PMODB]:
            if not gr_pin in [PMOD_GROVE_G1,
                              PMOD_GROVE_G2]:
                raise ValueError("PIR group number can only be G1 - G2.")
            self.pir_iop = Pmod_IO(if_id, gr_pin[0], 'in')
        elif if_id in [ARDUINO]:
            if not gr_pin in [ARDUINO_GROVE_G1,
                              ARDUINO_GROVE_G2,
                              ARDUINO_GROVE_G3,
                              ARDUINO_GROVE_G4,
                              ARDUINO_GROVE_G5,
                              ARDUINO_GROVE_G6,
                              ARDUINO_GROVE_G7]:
                raise ValueError("PIR group number can only be G1 - G7.")
            self.pir_iop = Arduino_IO(if_id, gr_pin[0], 'in')
        else:
            raise ValueError("No such IOP for grove device.")
            
    def read(self):
        """Receive the value from the PIR sensor.
        
        Returns 0 when there is no motion, and returns 1 otherwise.
        
        Returns
        -------
        int
            The data (0 or 1) read from the PIR sensor.
        
        """
        return self.pir_iop.read()
