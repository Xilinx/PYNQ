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


from . import Pmod
from . import PMOD_GROVE_G1
from . import PMOD_GROVE_G2
from . import PMOD_GROVE_G3
from . import PMOD_GROVE_G4


__author__ = "Marco Rabozzi, Giuseppe Natale"
__copyright__ = "Copyright 2016, NECST Laboratory, Politecnico di Milano"


PMOD_GROVE_EAR_HR_PROGRAM = "pmod_grove_ear_hr.bin"
CONFIG_IOP_SWITCH = 0x1


class Grove_EarHR(object):
    """This class controls the Grove ear clip heart rate sensor. 

    Sensor model: MED03212P.
    
    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
        
    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Grove_EarHR object. 
                
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the 
            IP name and the reset name.
        gr_pin: list
            A group of pins on pmod-grove adapter.
            
        """
        if gr_pin not in [PMOD_GROVE_G1,
                          PMOD_GROVE_G2,
                          PMOD_GROVE_G3,
                          PMOD_GROVE_G4]:
            raise ValueError("Group number can only be G1 - G4.")

        self.microblaze = Pmod(mb_info, PMOD_GROVE_EAR_HR_PROGRAM)
        self.microblaze.write_mailbox(0, gr_pin[0])
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

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
        beats = self.microblaze.read_mailbox(0x4)
        interval_ms = self.microblaze.read_mailbox(0x8 + (beats % 4)*4)
        return beats, interval_ms
