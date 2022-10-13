#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from . import Arduino_IO
from . import ARDUINO_GROVE_G1
from . import ARDUINO_GROVE_G2
from . import ARDUINO_GROVE_G3
from . import ARDUINO_GROVE_G4
from . import ARDUINO_GROVE_G5
from . import ARDUINO_GROVE_G6
from . import ARDUINO_GROVE_G7




class Grove_PIR(Arduino_IO):
    """This class controls the PIR motion sensor.

    Hardware version: v1.2.
    
    Attributes
    ----------
    microblaze : Arduino
        Microblaze processor instance used by this module.

    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of a PIR object. 
        
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
                raise ValueError("Group number can only be G1 - G7.")

        super().__init__(mb_info, gr_pin[0], 'in')

    def read(self):
        """Receive the value from the PIR sensor.

        Returns 0 when there is no motion, and returns 1 otherwise.

        Returns
        -------
        int
            The data (0 or 1) read from the PIR sensor.

        """
        return super().read()


