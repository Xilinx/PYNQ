#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from . import Pmod




PMOD_DPOT_PROGRAM = "pmod_dpot.bin"
CANCEL = 0x1
SET_POT_SIMPLE = 0x3
SET_POT_RAMP = 0x5


class Pmod_DPOT(object):
    """This class controls a digital potentiometer Pmod.
    
    The Pmod DPOT (PB 200-239) is a digital potentiometer powered by the 
    AD5160. Users may set a desired resistance between 60 ~ 10k ohms.

    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
        
    """
    def __init__(self, mb_info):
        """Return a new instance of a DPOT object. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
            
        """
        self.microblaze = Pmod(mb_info, PMOD_DPOT_PROGRAM)
    
    def write(self, val, step=0, log_ms=0):
        """Write the value into the DPOT.

        This method will write the parameters "value", "step", and "log_ms" 
        all together into the DPOT Pmod. The parameter "log_ms" is only used
        for debug; users can ignore this parameter.
        
        Parameters
        ----------
        val : int
            The initial value to start, in [0, 255].
        step : int
            The number of steps when ramping up to the final value.
        log_ms : int
            The length of the log in milliseconds, for debug only.
            
        Returns
        -------
        None
        
        """
        if not 0 <= val <= 255:
            raise ValueError("Initial value should be in range [0, 255].")    
        if not 0 <= step <= (255-val):
            raise ValueError("Ramp steps should be in range [0, {}]."
                             .format(255-val))
        if log_ms < 0:
            raise ValueError("Requested log_ms value cannot be less than 0.")

        self.microblaze.write_non_blocking_command(CANCEL)
        self.microblaze.write_mailbox(0, [val, step, log_ms])

        if step == 0:
            self.microblaze.write_non_blocking_command(SET_POT_SIMPLE)
        else:
            self.microblaze.write_non_blocking_command(SET_POT_RAMP)


