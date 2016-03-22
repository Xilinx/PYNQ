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
import mmap
from pyxi import MMIO
from pyxi import GPIO
from pyxi import Overlay
from pyxi.pmods import pmod_const

class _IOP:
    """This class controls the active IOP instances in the system.
    
    Attributes
    ----------
    iop_id : int
        The ID of the IOP, index starting from 0.
    pmod_id : int
        The corresponding PMOD ID of the IOP, index starting from 1.
    mb_program : str
        The Microblaze program loaded for the IOP.
    state : str
        The status of the IOP.
    gpio : GPIO
        The GPIO pin associated with the IOP.
    mmio : MMIO
        The MMIO instance associated with the IOP.
        
    """

    def __init__(self, iop_id, mb_program='mailbox.bin'):
        """Create a new _IOP object.
        
        Note
        ----
        For "pmod.bit", pmod_id = iop_id + 1. This mapping may be changed for 
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
        self.pmod_id = iop_id + 1
        self.mb_program = mb_program
        self.state = 'IDLE'
        
        emio_pin = GPIO.get_gpio_pin(iop_id)
        self.gpio = GPIO(emio_pin, 'out')
        
        #: Use self.program to update the Microblaze
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
        
        ol = Overlay('pmod.bit')
        iop_dict = ol.get_iop_addr()
        iop_addr = int(iop_dict[self.iop_id][1], 16)
        with open(pmod_const.BIN_LOCATION + \
                    self.mb_program, 'rb') as ublaze_bin:
            size = (math.ceil(os.fstat(ublaze_bin.fileno()).st_size/ \
                    mmap.PAGESIZE))*mmap.PAGESIZE
            self.mmio = MMIO(iop_addr, size)
            
            buf = ublaze_bin.read(size)
            self.mmio.write(0, buf)
        
        self.start()
         
    def _status(self):
        str = 'Microblaze program {} at address 0x{} {}'\
            .format(self.mb_program, self.mmio.base_addr, self.state)
        return str

def request_iop(pmod_id, mb_program='mailbox.bin', force=False):
    """This is the interface to request an I/O Processor.
    
    It looks for active instances on the same PMOD ID, and prevents users from 
    instantiating different types of IOPs on the same PMOD.
    Users are notified with an exception if the selected PMOD is already 
    hooked to another type of IOP, to prevent unwanted behavior.
    This can be overridden by setting the *force* flag.
    
    Three cases:
    1. No previous IOP in the system with the same ID
    2. There is A previous IOP in the system with the same ID. 
       Users want to request another instance with the same program. 
       Update the program only: do not raises an exception.
    3. force == False. There is A previous IOP in the system with the same ID. 
       Users want to request another instance with a different program. 
       Raises an exception.

    Note
    ----
    Raises LookupError when another IOP type in the system with the same ID, 
    and the *force* flag is not set. A work-around is to set the *force* flag
    to overwrite the old instance, but that is not advised since hot swapping
    is not supported currently.
    
    For bitstream "pmod.bit", the PMOD IDs are {1, 2, 3, 4}, while the IOP 
    IDs are {0, 1, 2, 3} <=> {JB, JC, JD, JE}. 
    For different bitstreams, this mapping can be different.
    
    Parameters
    ----------
    pmod_id : int
        ID of the PMOD
    mb_program : str
        Program to be loaded on the IOP. 
    force : bool
        Flag whether the function will force IOP instantiation.
    
    Returns
    -------
    _IOP
        An _IOP object with the updated Microblaze program.
        
    """
    ol = Overlay('pmod.bit')
    iop_id = pmod_id - 1
    if ol.get_iop_instance(iop_id) is None:
        #: case 1
        ol.set_iop_instance(iop_id, mb_program)
        return _IOP(iop_id, mb_program)
    elif (force or mb_program is ol.get_iop_instance(iop_id)):
        #: case 2
        ol.set_iop_instance(iop_id, mb_program)
        return _IOP(iop_id, mb_program)
    else:
        #: case 3
        raise LookupError('Another IOP with the same ID is already on PL.')
        return None
        
