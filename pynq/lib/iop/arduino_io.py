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

__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


from pynq.iop import iop_const
from pynq.iop import DevMode
from pynq.iop import ARDUINO

class Arduino_IO(object):
    """This class controls the Arduino IO pins as inputs or outputs.
    
    Note
    ----
    The parameter 'direction' determines whether the instance is input/output:
    'in'  : receiving input from offchip to onchip. 
    'out' : sending output from onchip to offchip.
    
    Note
    ----
    The index of the Arduino pins:
    upper row, from right to left: {0, 1, ..., 13}. (D0 - D13)
    lower row, from left to right: {14, 15,..., 19}. (A0 - A5)
    
    Attributes
    ----------
    iop : _IOP
        The _IOP object returned from the DevMode.
    index : int
        The index of the Arduino pin, from 0 to 19.
    direction : str
        Input 'in' or output 'out'.
    
    """
    def __init__(self, if_id, index, direction): 
        """Return a new instance of a Arduino IO object.
        
        Parameters
        ----------
        if_id : int
            The interface ID (3) corresponding to (ARDUINO).
        index: int
            The index of the Arduino pin, from 0 to 19.
        direction : str
            Input 'in' or output 'out'.
            
        """
        if not if_id in [ARDUINO]:
            raise ValueError("No such IOP for Arduino device.")
        if index not in range(20):
            raise ValueError("Valid pin indexes are 0 - 19.")
        if direction not in ['in', 'out']:
            raise ValueError("Direction can only be 'in', or 'out'.")
            
        self.iop = DevMode(if_id, iop_const.ARDUINO_SWCFG_DIOALL)
        self.index = index
        self.direction = direction
        
        self.iop.start()
        if self.index in range(14):
            if self.direction == 'in':
                self.iop.write_cmd(iop_const.ARDUINO_DIO_BASEADDR + \
                                   iop_const.ARDUINO_DIO_TRI_OFFSET, 
                                   iop_const.ARDUINO_CFG_DIO_ALLINPUT)
            else:
                self.iop.write_cmd(iop_const.ARDUINO_DIO_BASEADDR + \
                                   iop_const.ARDUINO_DIO_TRI_OFFSET, 
                                   iop_const.ARDUINO_CFG_DIO_ALLOUTPUT)
        else:
            if self.direction == 'in':
                self.iop.write_cmd(iop_const.ARDUINO_AIO_BASEADDR + \
                                   iop_const.ARDUINO_AIO_TRI_OFFSET, 
                                   iop_const.ARDUINO_CFG_AIO_ALLINPUT)
            else:
                self.iop.write_cmd(iop_const.ARDUINO_AIO_BASEADDR + \
                                   iop_const.ARDUINO_AIO_TRI_OFFSET, 
                                   iop_const.ARDUINO_CFG_AIO_ALLOUTPUT)
                            
        self.iop.load_switch_config()
    
    def write(self, value): 
        """Send the value to the offboard Arduino IO device.

        Note
        ----
        Only use this function when direction is 'out'.
        
        Parameters
        ----------
        value : int
            The value to be written to the Arduino IO device.
            
        Returns
        -------
        None
            
        """
        if not value in (0,1):
            raise ValueError("Arduino IO can only write 0 or 1.")
        if not self.direction == 'out':
            raise ValueError('Arduino IO used as output, declared as input.')

        if self.index in range(0,14):
            if value:
                cur_val = self.iop.read_cmd(iop_const.ARDUINO_DIO_BASEADDR + \
                                           iop_const.ARDUINO_DIO_DATA_OFFSET)
                new_val = cur_val | (0x1<<self.index)
                self.iop.write_cmd(iop_const.ARDUINO_DIO_BASEADDR + \
                                   iop_const.ARDUINO_DIO_DATA_OFFSET, new_val)
            else:
                cur_val = self.iop.read_cmd(iop_const.ARDUINO_DIO_BASEADDR + \
                                           iop_const.ARDUINO_DIO_DATA_OFFSET)
                new_val = cur_val & (0xffffffff ^ (0x1<<self.index))
                self.iop.write_cmd(iop_const.ARDUINO_DIO_BASEADDR + \
                                   iop_const.ARDUINO_DIO_DATA_OFFSET, new_val)
        else:
            if value:
                cur_val = self.iop.read_cmd(iop_const.ARDUINO_AIO_BASEADDR + \
                                           iop_const.ARDUINO_AIO_DATA_OFFSET)
                new_val = cur_val | (0x1<<(self.index-14))
                self.iop.write_cmd(iop_const.ARDUINO_AIO_BASEADDR + \
                                   iop_const.ARDUINO_AIO_DATA_OFFSET, new_val)
            else:
                cur_val = self.iop.read_cmd(iop_const.ARDUINO_AIO_BASEADDR + \
                                           iop_const.ARDUINO_AIO_DATA_OFFSET)
                new_val = cur_val & (0xffffffff ^ (0x1<<(self.index-14)))
                self.iop.write_cmd(iop_const.ARDUINO_AIO_BASEADDR + \
                                   iop_const.ARDUINO_AIO_DATA_OFFSET, new_val)
            
    def read(self):
        """Receive the value from the offboard Arduino IO device.

        Note
        ----
        Only use this function when direction is 'in'.
        
        Returns
        -------
        int
            The data (0 or 1) on the specified Arduino IO pin.
        
        """  
        if not self.direction == 'in':
            raise ValueError('Arduino IO used as input, declared as output.')
        
        if self.index in range(0,14):
            raw_value = self.iop.read_cmd(iop_const.ARDUINO_DIO_BASEADDR + \
                                          iop_const.ARDUINO_DIO_DATA_OFFSET)
            return (raw_value >> self.index) & 0x1
        else:
            raw_value = self.iop.read_cmd(iop_const.ARDUINO_AIO_BASEADDR + \
                                          iop_const.ARDUINO_AIO_DATA_OFFSET)
            return (raw_value >> (self.index-14)) & 0x1
            
    def _state(self):
        """Retrieve the current state of the Arduino IO.
        
        This function is usually used for debug purpose. Users should still
        rely on read() or write() to get/put a value.
        
        Returns
        -------
        int
            The data (0 or 1) on the specified Arduino IO pin.
        
        """
        if self.index in range(0,14):
            raw_value = self.iop.read_cmd(iop_const.ARDUINO_DIO_BASEADDR + \
                                          iop_const.ARDUINO_DIO_DATA_OFFSET)
            return (raw_value >> self.index) & 0x1
        else:
            raw_value = self.iop.read_cmd(iop_const.ARDUINO_AIO_BASEADDR + \
                                          iop_const.ARDUINO_AIO_DATA_OFFSET)
            return (raw_value >> (self.index-14)) & 0x1
        