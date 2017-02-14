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
from pynq.dif import dif_const

class _DIF:
    """This class controls the Digital Interface instances in the system.

    This class servers as the agent to communicate with the interface
    processor in PL. The interface processor has a Microblaze which
    can be reprogrammed to interface with digital IO pins.

    The functions (or types) available for the DIF agent include
    Combination Function Generator, Pattern Generator,
    and Finite State Machine.

    Attributes
    ----------
    mb_program : str
        The absolute path of the Microblaze program.
    state : str
        The status (IDLE, RUNNING, or STOPPED) of the DIF.
    gpio : GPIO
        The GPIO instance associated with the DIF.
    mmio : MMIO
        The MMIO instance associated with the DIF.
        
    """

    def __init__(self, ip_name, addr_base, addr_range, gpio_uix, mb_program):
        """Create a new _DIF object.
        
        Parameters
        ----------
        ip_name : str
            The name of the IP corresponding to the DIF.
        addr_base : int
            The base address for the MMIO in hex format.
        addr_range : int
            The address range for the MMIO in hex format.
        gpio_uix : int
            The user index of the GPIO, starting from 0.
        mb_program : str
            The Microblaze program loaded for the DIF.
        
        """
        self.ip_name = ip_name
        self.mb_program = dif_const.BIN_LOCATION + mb_program
        self.state = 'IDLE'
        self.gpio = GPIO(GPIO.get_gpio_pin(gpio_uix), "out")
        self.mmio = MMIO(addr_base, addr_range)
        
        self.program()
        
    def start(self):
        """Start the Microblaze of the current DIF.
        
        This method will update the status of the DIF.
        
        Returns
        -------
        None
        
        """
        self.state = 'RUNNING'
        self.gpio.write(0)
        
    def stop(self):
        """Stop the Microblaze of the current DIF.
        
        This method will update the status of the DIF.
        
        Returns
        -------
        None
        
        """
        self.state = 'STOPPED'
        self.gpio.write(1)
        
    def program(self):
        """This method programs the Microblaze of the DIF.
        
        This method is called in __init__(); it can also be called after that.
        It uses the attribute "self.mb_program" to program the Microblaze.
        
        Returns
        -------
        None
        
        """
        self.stop()
        
        PL.load_ip_data(self.ip_name, self.mb_program)
        
        self.start()

def request_dif(if_id, mb_program):
    """This is the interface to request an I/O Processor.
    
    It looks for active instances on the same interface ID, and prevents
    users from instantiating different types of DIFs on the same interface.
    Users are notified with an exception if the selected interface is already 
    hooked to another type of DIF, to prevent unwanted behavior.
    
    Two cases:
    1.  No previous DIF in the system with the same ID, or users want to
    request another instance with the same program. 
    Do not raises an exception.
    2.  There is A previous DIF in the system with the same ID. Users want to
    request another instance with a different program. 
    Raises an exception.

    Note
    ----
    When a DIF is already in the system with the same interface ID, users are
    in danger of losing the old instances associated with this DIF.
    
    For bitstream `interface.bit`, the DIF IDs are
    {1, 2, 3} <=> {PMODA, PMODB, ARDUINO}.
    For different bitstreams, this mapping can be different.
    
    Parameters
    ----------
    if_id : int
        Interface ID (1, 2, 3) corresponding to (PMODA, PMODB, ARDUINO).
    mb_program : str
        Program to be loaded on the DIF.
    
    Returns
    -------
    _DIF
        A _DIF object with the updated Microblaze program.
        
    Raises
    ------
    ValueError
        When the DIF name or the GPIO name cannot be found in the PL.
    LookupError
        When another DIF is in the system with the same interface ID.
        
    """
    ip_dict = PL.ip_dict
    gpio_dict = PL.gpio_dict
    dif = "SEG_mb_bram_ctrl_" + str(if_id) + "_Mem0"
    rst_pin = "mb_" + str(if_id) + "_reset"

    ip = [k for k, _ in ip_dict.items()]
    gpio = [k for k, _ in gpio_dict.items()]

    if dif not in ip:
            raise ValueError("No such DIF {}.".format(if_id))
    if rst_pin not in gpio:
            raise ValueError("No such GPIO pin for DIF {}.".format(if_id))

    addr_base, addr_range, ip_state = ip_dict[dif]
    gpio_uix, _ = gpio_dict[rst_pin]
    if (ip_state is None) or \
            (ip_state == (dif_const.BIN_LOCATION + mb_program)):
        # case 1
        return _dif(dif, addr_base, addr_range, gpio_uix, mb_program)
    else:
        # case 2
        raise LookupError('Another DIF program {} already running.' \
                          .format(ip_state))