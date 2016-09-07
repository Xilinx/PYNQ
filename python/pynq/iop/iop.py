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
__email__       = "yunq@xilinx.com"


import os
import sys
import math
from pynq import MMIO
from pynq import GPIO
from pynq import PL
from pynq.iop import iop_const

class _IOP:
    """This class controls the active IOP instances in the system.
    
    Attributes
    ----------
    mb_program : str
        The absolute path of the Microblaze program.
    state : str
        The status (IDLE, RUNNING, or STOPPED) of the IOP.
    gpio : GPIO
        The GPIO instance associated with the IOP.
    mmio : MMIO
        The MMIO instance associated with the IOP.
        
    """

    def __init__(self, iop_name, addr_base, addr_range, gpio_uix, mb_program):
        """Create a new _IOP object.
        
        Parameters
        ----------
        iop_name : str
            The name of the IP corresponding to the I/O Processor.
        addr_base : str
            The base address for the MMIO in hex format.
        addr_range : str
            The address range for the MMIO in hex format.
        gpio_uix : int
            The user index of the GPIO, starting from 0.
        mb_program : str
            The Microblaze program loaded for the IOP.
        
        """
        self.iop_name = iop_name
        self.mb_program = iop_const.BIN_LOCATION + mb_program
        self.state = 'IDLE'
        self.gpio = GPIO(GPIO.get_gpio_pin(gpio_uix), "out")
        self.mmio = MMIO(int(addr_base, 16), int(addr_range,16))
        
        self.program()
        
    def start(self):
        """Start the Microblaze of the current IOP.
        
        This method will update the status of the IOP.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        self.state = 'RUNNING';
        self.gpio.write(0)
        
    def stop(self):
        """Stop the Microblaze of the current IOP.
        
        This method will update the status of the IOP.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        self.state = 'STOPPED'
        self.gpio.write(1)
        
    def program(self):
        """This method programs the Microblaze of the IOP.
        
        This method is called in __init__(); it can also be called after that.
        It uses the attribute "self.mb_program" to program the Microblaze. 
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        self.stop()
        
        PL.load_ip_data(self.iop_name, self.mb_program)
        
        self.start()

def request_iop(iop_id, mb_program):
    """This is the interface to request an I/O Processor.
    
    It looks for active instances on the same IOP ID, and prevents users from 
    instantiating different types of IOPs on the same interface.
    Users are notified with an exception if the selected interface is already 
    hooked to another type of IOP, to prevent unwanted behavior.
    
    Two cases:
    1.  No previous IOP in the system with the same ID, or users want to 
    request another instance with the same program. 
    Do not raises an exception.
    2.  There is A previous IOP in the system with the same ID. Users want to 
    request another instance with a different program. 
    Raises an exception.

    Note
    ----
    When an IOP is already in the system with the same IOP ID, users are in 
    danger of losing the old instances associated with this IOP.
    
    For bitstream `base.bit`, the IOP IDs are 
    {1, 2, 3} <=> {PMODA, PMODB, arduino interface}. 
    For different bitstreams, this mapping can be different.
    
    Parameters
    ----------
    iop_id : int
        IOP ID (1, 2, 3) corresponding to (PMODA, PMODB, ARDUINO).
    mb_program : str
        Program to be loaded on the IOP.
    
    Returns
    -------
    _IOP
        An _IOP object with the updated Microblaze program.
        
    Raises
    ------
    ValueError
        When the IOP name or the GPIO name cannot be found in the PL.
    LookupError
        When another IOP is in the system with the same IOP ID.
        
    """
    ip_names = PL.get_ip_names("mb_bram_ctrl_")
    iop_name = "SEG_mb_bram_ctrl_" + str(iop_id) + "_Mem0"
    if (iop_name not in ip_names):
            raise ValueError("No such IOP {}."
                            .format(iop_id))
                            
    gpio_names = PL.get_gpio_names()
    rst_pin_name = "mb_" + str(iop_id) + "_reset"
    if (rst_pin_name not in gpio_names):
            raise ValueError("No such GPIO pin for IOP {}."
                            .format(iop_id))
                            
    addr_base = PL.get_ip_addr_base(iop_name)
    addr_range = PL.get_ip_addr_range(iop_name)
    gpio_uix = PL.get_gpio_user_ix(rst_pin_name)
    if (PL.get_ip_state(iop_name) is None) or \
        (PL.get_ip_state(iop_name)== \
                (iop_const.BIN_LOCATION + mb_program)):
        # case 1
        return _IOP(iop_name, addr_base, addr_range, \
                    gpio_uix, mb_program)
    else:
        # case 2
        raise LookupError('Another program {} already running on IOP.'\
                .format(PL.get_ip_state(iop_name)))
        return None
        
