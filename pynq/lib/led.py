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

__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


from pynq import MMIO
from pynq import PL

LEDS_OFFSET0 = 0x8
LEDS_OFFSET1 = 0xC

class LED(object):
    """This class controls the onboard LEDs.

    Attributes
    ----------
    index : int
        The index of the onboard LED, starting from 0.
    """
    _mmio = None
    _leds_value = 0

    def __init__(self, index):
        """Create a new LED object.
        
        Parameters
        ----------
        index : int
            Index of the LED, from 0 to 3.
        
        """
        if not index in range(4):
            raise Value("Index for onboard LEDs should be 0 - 3.")
            
        self.index = index
        if LED._mmio is None:
            LED._mmio = MMIO(PL.ip_dict["SEG_swsleds_gpio_Reg"][0],16)
        LED._mmio.write(LEDS_OFFSET1, 0x0)

    def toggle(self):
        """Flip the state of a single LED.
        
        If the LED is on, it will be turned off. If the LED is off, it will be
        turned on.
        
        Returns
        -------
        None
        
        """
        new_val = LED._leds_value ^ (0x1 << self.index)
        self._set_leds_value(new_val)

    def on(self):
        """Turn on a single LED.
        
        Returns
        -------
        None
        
        """
        new_val = LED._leds_value | (0x1 << self.index)
        self._set_leds_value(new_val)

    def off(self):
        """Turn off a single LED.
        
        Returns
        -------
        None
        
        """
        new_val = (LED._leds_value) & (0xff ^ (0x1 << self.index))
        self._set_leds_value(new_val)

    def write(self, value):
        """Set the LED state according to the input value.

        Parameters
        ----------
        value : int
            This parameter can be either 0 (off) or 1 (on).

        Raises
        ------
        ValueError
            If the value parameter is not 0 or 1.
        
        """
        if value not in (0, 1):
            raise ValueError("Value should be 0 or 1.")
        if value:
            self.on()
        else:
            self.off()

    def read(self):
        """Retrieve the LED state.

        Returns
        -------
        int
            Either 0 if the LED is off or 1 if the LED is on.
            
        """
        return (LED._leds_value >> self.index) & 0x1

    @staticmethod
    def _set_leds_value(value):
        """Set the state of all LEDs.
        
        Note
        ----
        This function should not be used directly. User should rely 
        on `toggle()`, `on()`, `off()`, `write()`, and `read()` instead
        
        Parameters
        ----------
        value : int 
            The value of all the LEDs encoded in a single variable
        
        """
        LED._leds_value = value
        LED._mmio.write(LEDS_OFFSET0, value)
