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
from pynq import Overlay
from pynq.pmods import pmod_const

ol = Overlay('pmod.bit')

class _IOP:
    """This class controls the active IOP instances in the system.
    
    Attributes
    ----------
    iop_id : int
        The ID of the IOP, index starting from 0.
    mb_program : str
        The absolute path of the Microblaze program.
    state : str
        The status of the IOP.
    gpio : GPIO
        The reset pin associated with the IOP.
    base_addr : int
        The MMIO base address of the IOP.
        
    """

    def __init__(self, iop_id, mb_program='mailbox.bin'):
        """Create a new _IOP object.
        
        Note
        ----
        For "pmod.bit", PMOD ID = IOP ID + 1. This mapping may be changed for 
        other bitstreams.
        
        Parameters
        ----------
        iop_id : int
            The ID of the IOP, index starting from 0.
        mb_program : str
            The Microblaze program loaded for the IOP.
        
        """
        if (iop_id not in [0,1,2,3]):
            raise ValueError("Valid IOP IDs are: 0, 1, 2, 3.")
        self.iop_id = iop_id
        self.mb_program = pmod_const.BIN_LOCATION + mb_program
        self.state = 'IDLE'
        self.gpio = GPIO(ol.get_ip_psgpio(iop_id), "out")
        self.base_addr = int(ol.get_ip_addr_prog(iop_id), 16)
        
        #: Use self.mb_program to update the program
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
        
        ol.load_ip_program(self.iop_id, self.mb_program)
        
        self.start()

def request_iop(pmod_id, mb_program='mailbox.bin'):
    """This is the interface to request an I/O Processor.
    
    It looks for active instances on the same PMOD ID, and prevents users from 
    instantiating different types of IOPs on the same PMOD.
    Users are notified with an exception if the selected PMOD is already 
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
    Raises LookupError when another IOP type in the system with the same ID. 
    Users are in danger of losing the old instances associated with this PMOD.
    
    For bitstream "pmod.bit", the PMOD IDs are {1, 2, 3, 4}, while the IOP 
    IDs are {0, 1, 2, 3} <=> {JB, JC, JD, JE}. 
    For different bitstreams, this mapping can be different.
    
    Parameters
    ----------
    pmod_id : int
        ID of the PMOD
    mb_program : str
        Program to be loaded on the IOP.
    
    Returns
    -------
    _IOP
        An _IOP object with the updated Microblaze program.
        
    """
    if (pmod_id not in range(1,5)):
            raise ValueError("Valid PMOD IDs are: 1, 2, 3, 4.")
    iop_id = pmod_id - 1
    if (ol.get_ip_program(iop_id) is None) or \
        (ol.get_ip_program(iop_id) == (pmod_const.BIN_LOCATION + mb_program)):
        #: case 1
        return _IOP(iop_id, mb_program)
    else:
        #: case 2
        raise LookupError('Another program {} already running on IOP.'\
                .format(ol.get_ip_program(iop_id)))
        return None
        