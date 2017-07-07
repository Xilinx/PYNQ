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


from . import Arduino
from . import ARDUINO_GROVE_I2C


__author__ = "Marco Rabozzi, Luca Cerina, Giuseppe Natale"
__copyright__ = "Copyright 2016, NECST Laboratory, Politecnico di Milano"


ARDUINO_GROVE_HAPTIC_MOTOR_PROGRAM = "arduino_grove_haptic_motor.bin"
CONFIG_IOP_SWITCH = 0x1
START_WAVEFORM = 0x2
STOP_WAVEFORM = 0x3
READ_IS_PLAYING = 0x4


class Grove_HapticMotor(object):
    """This class controls the Grove Haptic Motor based on the DRV2605L.
    Hardware version v0.9. 
    
    
    Attributes
    ----------
    microblaze : Arduino
        Microblaze processor instance used by this module.
        
    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Grove_Haptic_Motor object. 
                
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on arduino-grove shield.
            
        """
        if gr_pin not in [ARDUINO_GROVE_I2C]:
            raise ValueError("Group number can only be I2C.")

        self.microblaze = Arduino(mb_info, ARDUINO_GROVE_HAPTIC_MOTOR_PROGRAM)
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

    def play(self, effect):
        """Play a vibration effect on the Grove Haptic Motor peripheral.

        Valid effect identifiers are in the range [1, 127].

        Parameters
        ----------
        effect : int
            An integer that specifies the effect.

        Returns
        -------
        None 

        """
        if (effect < 1) or (effect > 127):
            raise ValueError("Valid effect identifiers are within 1 and 127.")
        self.microblaze.write_mailbox(0, [effect, 0])
        self.microblaze.write_blocking_command(START_WAVEFORM)

    def play_sequence(self, sequence):
        """Play a sequence of effects possibly separated by pauses.

        At most 8 effects or pauses can be specified at a time.
        Pauses are defined using negative integer values in the 
        range [-1, -127] that correspond to a pause length in the 
        range [10, 1270] ms

        Valid effect identifiers are in the range [1, 127]

        As an example, in the following sequence example: [4,-20,5] 
        effect 4 is played and after a pause of 200 ms effect 5 is played

        Parameters
        ----------
        sequence : list
            At most 8 values specifying effects and pauses.

        Returns
        -------
        None 

        """
        length = len(sequence)
        if length < 1:
            raise ValueError("The sequence must contain at least one value.")
        if length > 8:
            raise ValueError("The sequence cannot contain more than 8 values.")
        for i in range(length):
            if sequence[i] < 0:
                if sequence[i] < -127:
                    raise ValueError("Pause value must be smaller than -127")
                sequence[i] = -sequence[i] + 128
            else:
                if (sequence[i] < 1) or (sequence[i] > 127):
                    raise ValueError("Valid effect identifiers are within " +
                                     "1 and 127.")
        sequence += [0] * (8 - length)

        self.microblaze.write_mailbox(0, sequence)
        self.microblaze.write_blocking_command(START_WAVEFORM)

    def stop(self):
        """Stop an effect or a sequence on the motor peripheral.

        Returns
        -------
        None

        """
        self.microblaze.write_blocking_command(STOP_WAVEFORM)

    def is_playing(self):
        """Check if a vibration effect is running on the motor.

        Returns
        -------
        bool
            True if a vibration effect is playing, false otherwise

        """
        self.microblaze.write_blocking_command(READ_IS_PLAYING)
        flag = self.microblaze.read_mailbox(0)
        return flag == 1
