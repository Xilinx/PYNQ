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


from . import Arduino
from . import ARDUINO_GROVE_G1
from . import ARDUINO_GROVE_G2
from . import ARDUINO_GROVE_G3
from . import ARDUINO_GROVE_G4
from . import ARDUINO_GROVE_G5
from . import ARDUINO_GROVE_G6
from . import ARDUINO_GROVE_G7


__author__ = "Parimal Patel"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


ARDUINO_GROVE_BUZZER_PROGRAM = "arduino_grove_buzzer.bin"


class ArduinoGroveBuzzer(object):
    """This class controls the Grove Buzzer.
    
    The grove buzzer module has a piezo buzzer as the main component. 
    The piezo can be connected to digital outputs, and will emit a tone 
    when the output is HIGH. Alternatively, it can be connected to an analog 
    pulse-width modulation output to generate various tones and effects.
    Hardware version: v1.2.

    Attributes
    ----------
    microblaze : Arduino
        Microblaze processor instance used by this module.

    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an GROVE_Buzzer object. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on arduino-grove shield.

        """
        if gr_pin not in [ARDUINO_GROVE_G1,
                          ARDUINO_GROVE_G2,
                          ARDUINO_GROVE_G3,
                          ARDUINO_GROVE_G4,
                          ARDUINO_GROVE_G5,
                          ARDUINO_GROVE_G6,
                          ARDUINO_GROVE_G7]:
            raise ValueError("Buzzer group number can only be G1 - G7.")

        self.microblaze = Arduino(mb_info, ARDUINO_GROVE_BUZZER_PROGRAM)
        self.microblaze.write_mailbox([0, 4], gr_pin)
        self.microblaze.write_blocking_command(1)

    def play_tone(self, tone_period, num_cycles):
        """Play a single tone with tone_period for num_cycles

        Parameters
        ----------
        tone_period : int
            The period of the tone in microsecond.
        num_cycles : int
            The number of cycles for the tone to be played.

        Returns
        -------
        None

        """
        if tone_period not in range(1, 32768):
            raise ValueError("Valid tone period is between 1 and 32767.")
        if num_cycles not in range(1, 32768):
            raise ValueError("Valid number of cycles is between 1 and 32767.")

        self.microblaze.write_mailbox([0, 4], [tone_period, num_cycles])
        self.microblaze.write_blocking_command(0x3)

    def play_melody(self):
        """Play a melody.

        Returns
        -------
        None

        """
        self.microblaze.write_blocking_command(0x5)
