#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from . import Arduino
from . import ARDUINO_GROVE_G1
from . import ARDUINO_GROVE_G2
from . import ARDUINO_GROVE_G3
from . import ARDUINO_GROVE_G4
from . import ARDUINO_GROVE_G5
from . import ARDUINO_GROVE_G6
from . import ARDUINO_GROVE_G7




ARDUINO_GROVE_BUZZER_PROGRAM = "arduino_grove_buzzer.bin"
CONFIG_IOP_SWITCH = 0x1
PLAY_TONE = 0x3
PLAY_DEMO = 0x5


class Grove_Buzzer(object):
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
        self.microblaze.write_mailbox(0, gr_pin)
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

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

        self.microblaze.write_mailbox(0, [tone_period, num_cycles])
        self.microblaze.write_blocking_command(PLAY_TONE)

    def play_melody(self):
        """Play a melody.

        Returns
        -------
        None

        """
        self.microblaze.write_blocking_command(PLAY_DEMO)


