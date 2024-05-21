#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from . import Pmod




PMOD_DAC_PROGRAM = "pmod_dac.bin"
FIXEDGEN = 0x3


class Pmod_DAC(object):
    """This class controls a Digital to Analog Converter Pmod.
    
    The Pmod DA4 (PB 200-245) is an 8 channel 12-bit digital-to-analog 
    converter run via AD5628.

    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
        
    """

    def __init__(self, mb_info, value=None):
        """Return a new instance of a DAC object.
    
        Note
        ----
        The floating point number to be written should be in the range 
        of [0.00, 2.50]. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
            
        """
        self.microblaze = Pmod(mb_info, PMOD_DAC_PROGRAM)
        if value:
            self.write(value)

    def write(self, value):
        """Write a floating point number onto the DAC Pmod.

        Note
        ----
        Input value must be in the range [0.00, 2.50] 

        Parameters
        ----------
        value : float
            The value to be written to the DAC.
            
        Returns
        -------
        None

        """
        if not 0.00 <= value <= 2.5:
            raise ValueError("Requested value not in range [0.00, 2.50].")

        # Calculate the voltage value and write to DAC
        int_val = int(value / 0.0006105)
        cmd = (int_val << 20) | FIXEDGEN
        self.microblaze.write_blocking_command(cmd)


