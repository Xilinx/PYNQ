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
from . import PMOD_CFG_DIO_ALLINPUT
from . import PMOD_CFG_DIO_ALLOUTPUT
from . import PMOD_NUM_DIGITAL_PINS


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


class Pmod_IO(Pmod_DevMode):
    """This class controls the Pmod IO pins as inputs or outputs.
    
    Note
    ----
    The parameter 'direction' determines whether the instance is input/output:
    'in'  : receiving input from offchip to onchip. 
    'out' : sending output from onchip to offchip.
    The index of the Pmod pins:
    upper row, from left to right: {vdd,gnd,3,2,1,0}.
    lower row, from left to right: {vdd,gnd,7,6,5,4}.
    
    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
    index : int
        The index of the Pmod pin, starting from 0.
    direction : str
        Input 'in' or output 'out'.
    
    """
    def __init__(self, mb_info, index, direction):
        """Return a new instance of a Pmod IO object.
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        index: int
            The index of the Pmod pin, starting from 0.
        direction : str
            Input 'in' or output 'out'.
            
        """
        if index not in range(PMOD_NUM_DIGITAL_PINS):
            raise ValueError("Valid pin indexes are 0 - {}."
                             .format(PMOD_NUM_DIGITAL_PINS-1))
        if direction not in ['in', 'out']:
            raise ValueError("Direction can only be 'in', or 'out'.")

        super().__init__(mb_info, PMOD_SWCFG_DIOALL)
        self.index = index
        self.direction = direction
        self.start()
        if self.direction == 'in':
            self.write_cmd(PMOD_DIO_BASEADDR +
                           PMOD_DIO_TRI_OFFSET,
                           PMOD_CFG_DIO_ALLINPUT)
        else:
            self.write_cmd(PMOD_DIO_BASEADDR +
                           PMOD_DIO_TRI_OFFSET,
                           PMOD_CFG_DIO_ALLOUTPUT)

    def write(self, value): 
        """Send the value to the offboard Pmod IO device.

        Note
        ----
        Only use this function when direction is 'out'.
        
        Parameters
        ----------
        value : int
            The value to be written to the Pmod IO device.
            
        Returns
        -------
        None
            
        """
        if value not in (0, 1):
            raise ValueError("Pmod IO can only write 0 or 1.")
        if not self.direction == 'out':
            raise ValueError('Pmod IO used as output, declared as input.')

        if value:
            cur_val = self.read_cmd(PMOD_DIO_BASEADDR +
                                    PMOD_DIO_DATA_OFFSET)
            new_val = cur_val | (0x1 << self.index)
            self.write_cmd(PMOD_DIO_BASEADDR +
                           PMOD_DIO_DATA_OFFSET, new_val)
        else:
            cur_val = self.read_cmd(PMOD_DIO_BASEADDR +
                                    PMOD_DIO_DATA_OFFSET)
            new_val = cur_val & (0xff ^ (0x1 << self.index))
            self.write_cmd(PMOD_DIO_BASEADDR +
                           PMOD_DIO_DATA_OFFSET, new_val)

    def read(self):
        """Receive the value from the offboard Pmod IO device.

        Note
        ----
        Only use this function when direction is 'in'.
        
        Returns
        -------
        int
            The data (0 or 1) on the specified Pmod IO pin.
        
        """  
        if not self.direction == 'in':
            raise ValueError('Pmod IO used as input, but declared as output.')

        raw_value = self.read_cmd(PMOD_DIO_BASEADDR +
                                  PMOD_DIO_DATA_OFFSET)
        return (raw_value >> self.index) & 0x1
        
    def _state(self):
        """Retrieve the current state of the Pmod IO.
        
        This function is usually used for debug purpose. Users should still
        rely on read() or write() to get/put a value.
        
        Returns
        -------
        int
            The data (0 or 1) on the specified Pmod IO pin.
        
        """
        raw_value = self.read_cmd(PMOD_DIO_BASEADDR +
                                  PMOD_DIO_DATA_OFFSET)
        return (raw_value >> self.index) & 0x1
