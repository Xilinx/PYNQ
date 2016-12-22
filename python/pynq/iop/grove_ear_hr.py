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

__author__      = "Marco Rabozzi, Giuseppe Natale"
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
from pynq.iop import PMOD_GROVE_G1
from pynq.iop import PMOD_GROVE_G2
from pynq.iop import PMOD_GROVE_G3
from pynq.iop import PMOD_GROVE_G4
from pynq.iop import ARDUINO_GROVE_G1
from pynq.iop import ARDUINO_GROVE_G2
from pynq.iop import ARDUINO_GROVE_G3
from pynq.iop import ARDUINO_GROVE_G4
from pynq.iop import ARDUINO_GROVE_G5
from pynq.iop import ARDUINO_GROVE_G6
from pynq.iop import ARDUINO_GROVE_G7

PMOD_GROVE_EAR_HR_PROGRAM = "pmod_grove_ear_hr.bin"
ARDUINO_GROVE_EAR_HR_PROGRAM = "arduino_grove_ear_hr.bin"

class Grove_EarHR(object):
    """This class controls the Grove ear clip heart rate sensor. 
    Sensor model: MED03212P.
    
    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by Grove_FingerHR.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
        
    """
    def __init__(self, if_id, gr_pin): 
        """Return a new instance of an Grove_EarHR object. 
                
        Parameters
        ----------
        if_id : int
            IOP ID (1, 2, 3) corresponding to (PMODA, PMODB, ARDUINO).
        gr_pin: list
            A group of pins on stickit connector or arduino shield.
            
        """
        if if_id in [PMODA, PMODB]:
            if not gr_pin in [PMOD_GROVE_G1,
                              PMOD_GROVE_G2,
                              PMOD_GROVE_G3,
                              PMOD_GROVE_G4]:
                raise ValueError("EarHR group number can only be G1 - G4.")
            GROVE_EAR_HR_PROGRAM = PMOD_GROVE_EAR_HR_PROGRAM

        elif if_id in [ARDUINO]:
            if not gr_pin in [ARDUINO_GROVE_G1,
                              ARDUINO_GROVE_G2,
                              ARDUINO_GROVE_G3,
                              ARDUINO_GROVE_G4,
                              ARDUINO_GROVE_G5,
                              ARDUINO_GROVE_G6,
                              ARDUINO_GROVE_G7]:
                raise ValueError("EarHR group number can only be G1 - G7.")
            GROVE_EAR_HR_PROGRAM = ARDUINO_GROVE_EAR_HR_PROGRAM

        else:
            raise ValueError("No such IOP for grove device.")

        self.iop = request_iop(if_id, GROVE_EAR_HR_PROGRAM)
        self.mmio = self.iop.mmio
        self.iop.start()

        signal_pin = gr_pin[0]
        self.mmio.write(iop_const.MAILBOX_OFFSET, signal_pin)
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                              iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 1):
            pass

    def read(self):
        """Read the heart rate from the sensor.
            
        Returns
        -------
        float
            The heart rate as beats per minute

        """
        beats, interval_ms = self.read_raw()
        if 0 < interval_ms < 2500:
            rate = 60000.0 / interval_ms
        else:
            raise RuntimeError("Value out of range or device not connected.")
        return rate

    def read_raw(self):
        """Read the number of heart beats.
        
        Read the number of beats since the sensor initialization; also read 
        the time elapsed in ms between the latest two heart beats.
        
        Returns
        -------
        tuple
            Number of heart beats and the time elapsed between 2 latest beats.
        
        """
        beats = self.mmio.read(iop_const.MAILBOX_OFFSET + 0x4)
        interval_ms = self.mmio.read(iop_const.MAILBOX_OFFSET +
                                     0x8 + (beats%4)*4)
        return beats, interval_ms