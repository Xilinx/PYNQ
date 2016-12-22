#   Copyright (c) 2016, NECST Laboratory, Politecnico di Milano
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

__author__      = "Marco Rabozzi, Luca Cerina, Giuseppe Natale"
__copyright__   = "Copyright 2016, NECST Laboratory, Politecnico di Milano"

import time
import struct
from pynq import MMIO
from pynq.iop import request_iop
from pynq.iop import iop_const
from pynq.iop import Pmod_IO
from pynq.iop import Arduino_IO
from pynq.iop import PMODA
from pynq.iop import PMODB
from pynq.iop import ARDUINO
from pynq.iop import PMOD_GROVE_G3
from pynq.iop import PMOD_GROVE_G4
from pynq.iop import ARDUINO_GROVE_I2C


PMOD_GROVE_COLOR_PROGRAM = "pmod_grove_color.bin"
ARDUINO_GROVE_COLOR_PROGRAM = "arduino_grove_color.bin"
GROVE_COLOR_LOG_START = iop_const.MAILBOX_OFFSET+16
GROVE_COLOR_LOG_END = GROVE_COLOR_LOG_START+(250*16)

class Grove_Color(object):
    """This class controls the Grove IIC Color sensor. 
    
    Grove Color sensor based on the TCS3414CS. 
    Hardware version: v1.3.
    
    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Grove_Color.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    log_running : int
        The state of the log (0: stopped, 1: started).
        
    """
    def __init__(self, if_id, gr_pin): 
        """Return a new instance of an Grove_Color object.  
        
        Parameters
        ----------
        if_id : int
            IOP ID (1, 2, 3) corresponding to (PMODA, PMODB, ARDUINO).
        gr_pin: list
            A group of pins on stickit connector or arduino shield.
            
        """
        if if_id in [PMODA, PMODB]:
            if not gr_pin in [PMOD_GROVE_G3,
                              PMOD_GROVE_G4]:
                raise ValueError("Color group number can only be G3 - G4.")
            GROVE_COLOR_PROGRAM = PMOD_GROVE_COLOR_PROGRAM

        elif if_id in [ARDUINO]:
            if not gr_pin in [ARDUINO_GROVE_I2C]:
                raise ValueError("Color group number can only be I2C.")
            GROVE_COLOR_PROGRAM = ARDUINO_GROVE_COLOR_PROGRAM

        else:
            raise ValueError("No such IOP for grove device.")

        self.iop = request_iop(if_id, GROVE_COLOR_PROGRAM)
        self.mmio = self.iop.mmio
        self.log_interval_ms = 1000
        self.log_running  = 0
        self.iop.start()
        
        if if_id in [PMODA, PMODB]:
            self.mmio.write(iop_const.MAILBOX_OFFSET, gr_pin[0])
            self.mmio.write(iop_const.MAILBOX_OFFSET+4, gr_pin[1])

        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                              iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 1):
            pass

    def read(self):
        """Read the color values from the Grove Color peripheral.

        The output contains 4 integer values: Red, Green, Blu and Clear.
        Clear represents the value of the sensor if no color filters are
        applied.
        
        Returns
        -------
        tuple
            Tuple of (red, green, blue, clear),
        
        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 2)      
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                              iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 2):
            pass
        red = self.mmio.read(iop_const.MAILBOX_OFFSET)
        green = self.mmio.read(iop_const.MAILBOX_OFFSET + 0x4)
        blue = self.mmio.read(iop_const.MAILBOX_OFFSET + 0x8)
        clear = self.mmio.read(iop_const.MAILBOX_OFFSET + 0xC)
        return red, green, blue, clear
