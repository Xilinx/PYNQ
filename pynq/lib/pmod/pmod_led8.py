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


from . import Pmod_DevMode
from . import PMOD_SWCFG_DIOALL
from . import PMOD_DIO_BASEADDR
from . import PMOD_DIO_TRI_OFFSET
from . import PMOD_DIO_DATA_OFFSET
from . import PMOD_CFG_DIO_ALLOUTPUT
from . import PMOD_NUM_DIGITAL_PINS


__author__ = "Graham Schelle, Giuseppe Natale, Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


class Pmod_LED8(Pmod_DevMode):
    """This class controls a single LED on the LED8 Pmod.
    
    The Pmod LED8 (PB 200-163) has eight high-brightness LEDs. Each LED can be
    individually illuminated from a logic high signal.
    
    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
    iop_switch_config :list
        Microblaze processor IO switch configuration (8 integers).
    index : int
        Index of the pin on LED8, starting from 0.
        
    """

    def __init__(self, mb_info, index):
        """Return a new instance of a LED object.
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        index: int
            The index of the pin in a Pmod, starting from 0.
            
        """
        if index not in range(PMOD_NUM_DIGITAL_PINS):
            raise ValueError("Valid pin indexes are 0 - {}."
                             .format(PMOD_NUM_DIGITAL_PINS-1))

        super().__init__(mb_info, PMOD_SWCFG_DIOALL)
        self.index = index
        self.start()
        self.write_cmd(PMOD_DIO_BASEADDR +
                       PMOD_DIO_TRI_OFFSET,
                       PMOD_CFG_DIO_ALLOUTPUT)
                  
    def toggle(self):  
        """Flip the bit of a single LED.
        
        Note
        ----
        The LED will be turned off if it is on. Similarly, it will be turned 
        on if it is off.
        
        Returns
        -------
        None
        
        """
        curr_val = self.read_cmd(PMOD_DIO_BASEADDR +
                                 PMOD_DIO_DATA_OFFSET)
        new_val = curr_val ^ (0x1 << self.index)
        self._set_leds_values(new_val)
        
    def on(self):  
        """Turn on a single LED.
        
        Returns
        -------
        None
        
        """
        curr_val = self.read_cmd(PMOD_DIO_BASEADDR +
                                 PMOD_DIO_DATA_OFFSET)
        new_val = curr_val | (0x1 << self.index)
        self._set_leds_values(new_val)

    def off(self):    
        """Turn off a single LED.
        
        Returns
        -------
        None
        
        """
        curr_val = self.read_cmd(PMOD_DIO_BASEADDR +
                                 PMOD_DIO_DATA_OFFSET)
        new_val = curr_val & (0xff ^ (0x1 << self.index))
        self._set_leds_values(new_val)

    def write(self, value):
        """Set the LED state according to the input value
        
        Note
        ----
        This method does not take into account the current LED state.
        
        Parameters
        ----------
        value : int
            Turn on the LED if value is 1; turn it off if value is 0.
            
        Returns
        -------
        None
        
        """
        if value not in (0, 1):
            raise ValueError("LED8 can only write 0 or 1.")
        if value:
            self.on()
        else:
            self.off()

    def read(self):       
        """Retrieve the LED state.
        
        Returns
        -------
        int
            The data (0 or 1) read out from the selected pin.
        
        """
        curr_val = self.read_cmd(PMOD_DIO_BASEADDR +
                                 PMOD_DIO_DATA_OFFSET)
        return (curr_val >> self.index) & 0x1 
    
    def _set_leds_values(self, value):
        """Set the state for all the LEDs.

        Note
        ----
        Should not be used directly. User should rely on toggle(), on(), 
        off(), write(), and read() instead.

        Parameters
        ----------
        value : int
            The state of all the LEDs encoded in one single value
        
        Returns
        -------
        None
        
        """
        self.write_cmd(PMOD_DIO_BASEADDR +
                       PMOD_DIO_DATA_OFFSET, value)
