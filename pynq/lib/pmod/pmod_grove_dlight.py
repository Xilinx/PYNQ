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
from . import PMOD_GROVE_G3
from . import PMOD_GROVE_G4


__author__ = "Marco Rabozzi, Luca Cerina, Giuseppe Natale"
__copyright__ = "Copyright 2016, NECST Laboratory, Politecnico di Milano"


PMOD_GROVE_DLIGHT_PROGRAM = "pmod_grove_dlight.bin"
CONFIG_IOP_SWITCH = 0x1
GET_LIGHT_VALUE = 0x3
GET_LUX_VALUE = 0x5


class Grove_Dlight(object):
    """This class controls the Grove IIC color sensor.
    
    Grove Color sensor based on the TCS3414CS. 
    Hardware version: v1.3.
    
    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
        
    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Grove_Dlight object. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on pmod-grove adapter.
            
        """
        if gr_pin not in [PMOD_GROVE_G3,
                          PMOD_GROVE_G4]:
            raise ValueError("Group number can only be G3 - G4.")

        self.microblaze = Pmod(mb_info, PMOD_GROVE_DLIGHT_PROGRAM)
        self.microblaze.write_mailbox(0, gr_pin)
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

    def read_raw_light(self):
        """Read the visible and IR channel values.

        Read the values from the grove digital light peripheral.
        
        Returns
        -------
        tuple
            A tuple containing 2 integer values ch0 (visible) and ch1 (IR).
        
        """
        self.microblaze.write_blocking_command(GET_LIGHT_VALUE)
        ch0, ch1 = self.microblaze.read_mailbox(0, 2)
        return ch0, ch1

    def read_lux(self):
        """Read the computed lux value of the sensor.
        
        Returns
        -------
        int
            The lux value from the sensor
        
        """
        self.microblaze.write_blocking_command(GET_LUX_VALUE)
        lux = self.microblaze.read_mailbox(0x8)
        return lux
