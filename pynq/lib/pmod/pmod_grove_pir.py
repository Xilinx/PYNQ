#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from . import Pmod_IO
from . import PMOD_GROVE_G1
from . import PMOD_GROVE_G2




class Grove_PIR(Pmod_IO):
    """This class controls the PIR motion sensor.

    Hardware version: v1.2.
    
    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
    index : int
        The index of the Pmod pin, from 0 to 7.
    direction : str
        Can only be 'in' for PIR sensor.
    
    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of a PIR object. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on pmod-grove adapter.
            
        """
        if gr_pin not in [PMOD_GROVE_G1,
                          PMOD_GROVE_G2]:
            raise ValueError("Group number can only be G1 - G2.")

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


