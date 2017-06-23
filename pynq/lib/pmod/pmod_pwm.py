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


import time
import struct
from . import Pmod
from . import PMOD_NUM_DIGITAL_PINS


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


PMOD_PWM_PROGRAM = "pmod_pwm.bin"
CONFIG_IOP_SWITCH = 0x1
GENERATE = 0x3
STOP = 0x5


class Pmod_PWM(object):
    """This class uses the PWM of the IOP. 

    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.

    """
    def __init__(self, mb_info, index):
        """Return a new instance of an GROVE_PWM object. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        index : int
            The specific pin that runs PWM.
            
        """
        if index not in range(PMOD_NUM_DIGITAL_PINS):
            raise ValueError("Valid pin indexes are 0 - {}."
                             .format(PMOD_NUM_DIGITAL_PINS-1))

        self.microblaze = Pmod(mb_info, PMOD_PWM_PROGRAM)
        
        # Write PWM pin config
        self.microblaze.write_mailbox(0, index)
        
        # Write configuration and wait for ACK
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)
            
    def generate(self, period, duty_cycle):
        """Generate pwm signal with desired period and percent duty cycle.
        
        Parameters
        ----------
        period : int
            The period of the tone (us), between 1 and 65536.
        duty_cycle : int
            The duty cycle in percentage.
        
        Returns
        -------
        None
                
        """
        if period not in range(1, 65536):
            raise ValueError("Valid tone period is between 1 and 65536.")
        if duty_cycle not in range(1, 99):
            raise ValueError("Valid duty cycle is between 1 and 99.")

        self.microblaze.write_mailbox(0, [period, duty_cycle])
        self.microblaze.write_blocking_command(GENERATE)

    def stop(self):
        """Stops PWM generation.

        Returns
        -------
        None

        """
        self.microblaze.write_blocking_command(STOP)
