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

__author__      = "Graham Schelle, Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


from pynq.iop import iop_const
from pynq.iop import DevMode
from pynq.iop import PMODA
from pynq.iop import PMODB

class Pmod_LED8(object):
    """This class controls a single LED on the LED8 Pmod.
    
    The Pmod LED8 (PB 200-163) has eight high-brightness LEDs. Each LED can be
    individually illuminated from a logic high signal.
    
    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by LED8.
    index : int
        Index of the pin on LED8, from 0 to 7.
        
    """

    def __init__(self, if_id, index):
        """Return a new instance of a LED object.
        
        Parameters
        ----------
        if_id : int
            The interface ID (1, 2) corresponding to (PMODA, PMODB).
        index: int
            The index of the pin in a Pmod, from 0 to 7.
            
        """
        if not if_id in [PMODA, PMODB]:
            raise ValueError("No such IOP for Pmod device.")
        if not index in range(8):
            raise ValueError("Valid pin indexes are 0 - 7.")
            
        self.iop = DevMode(if_id, iop_const.PMOD_SWCFG_DIOALL) 
        self.index = index
        
        self.iop.start()
        self.iop.write_cmd(iop_const.PMOD_DIO_BASEADDR +
                            iop_const.PMOD_DIO_TRI_OFFSET,
                            iop_const.PMOD_CFG_DIO_ALLOUTPUT)

        self.iop.load_switch_config()
                  
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
        curr_val = self.iop.read_cmd(iop_const.PMOD_DIO_BASEADDR + \
                                        iop_const.PMOD_DIO_DATA_OFFSET)
        new_val  = curr_val ^ (0x1 << self.index)
        self._set_leds_values(new_val)
        
    def on(self):  
        """Turn on a single LED.
        
        Returns
        -------
        None
        
        """
        curr_val = self.iop.read_cmd(iop_const.PMOD_DIO_BASEADDR + \
                                        iop_const.PMOD_DIO_DATA_OFFSET)
        new_val  = curr_val | (0x1 << self.index)
        self._set_leds_values(new_val)
     
    def off(self):    
        """Turn off a single LED.
        
        Returns
        -------
        None
        
        """
        curr_val = self.iop.read_cmd(iop_const.PMOD_DIO_BASEADDR + \
                                        iop_const.PMOD_DIO_DATA_OFFSET)
        new_val  = curr_val & (0xff ^ (0x1 << self.index))
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
        if not value in (0,1):
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
        curr_val = self.iop.read_cmd(iop_const.PMOD_DIO_BASEADDR + \
                                        iop_const.PMOD_DIO_DATA_OFFSET)
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
        self.iop.write_cmd(iop_const.PMOD_DIO_BASEADDR + \
                            iop_const.PMOD_DIO_DATA_OFFSET, value)
                         
