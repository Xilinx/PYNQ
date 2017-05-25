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

import asyncio
import os
import sys
import math
from . import MAILBOX_OFFSET
from . import MAILBOX_PY2IOP_CMD_OFFSET
from . import BIN_LOCATION


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "yunq@xilinx.com"


class Pmod(PynqMicroblaze):
    """This class controls the Pmod Microblaze instances in the system.

    This class inherits from the PynqMicroblaze class. It extends 
    PynqMicroblaze with capability to control Pmod devices.

    Attributes
    ----------
    ip_name : str
        The name of the IP corresponding to the Microblaze.
    rst_name : str
        The name of the reset pin for the Microblaze.
    mb_program : str
        The absolute path of the Microblaze program.
    state : str
        The status (IDLE, RUNNING, or STOPPED) of the Microblaze.
    reset : GPIO
        The reset pin associated with the Microblaze.
    mmio : MMIO
        The MMIO instance associated with the Microblaze.
    interrupt : Event
        An asyncio.Event-like class for waiting on and clearing interrupts.

    """

    def __init__(self, mb_info, mb_program,
                 intr_pin=None, intr_ack_pin=None):
        """Create a new Microblaze object.

        It looks for active instances on the same Pmod ID, and prevents users 
        from instantiating different types of Pmod instances on the same 
        interface. Users are notified with an exception if the selected 
        interface is already hooked to another type of Pmod instance, 
        to prevent unwanted behavior.
    
        Two cases:

        1.  No previous Pmod program loaded in the system with the same ID, 
        or users want to request another instance with the same program.
        No exception will be raised in this case.

        2.  There is A previous Pmod program loaded in the system with the 
        same ID. Users want to request another instance with a different 
        program. An exception will be raised.

        Note
        ----
        When a Pmod program is already loaded in the system with the same 
        interface ID, users are in danger of losing the old instance.
    
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the 
            IP name and the reset name.
        mb_program : str
            The Microblaze program loaded for the processor.
        intr_pin : str
            Name of the interrupt pin for the Microblaze.
        intr_ack_gpio : int
            Number of the GPIO pin used to clear the interrupt.

        Raises
        ------
        ValueError
            When the `ip_name` or the `rst_name` cannot be found in the PL.
        RuntimeError
            When another Microblaze program is already loaded.

        """
        if not os.path.isabs(mb_program):
            mb_program = os.path.join(BIN_LOCATION, mb_program)

        super().__init__(mb_info, mb_program, intr_pin, intr_ack_pin)

    def write_mailbox(self, data_offset, data):
        """This method write data into the mailbox of the Microblaze.

        Parameters
        ----------
        data_offset : int
            The offset for mailbox data, 0,4,... for MAILBOX 0,1,...
        data : int/list
            A list of 32b words to be written into the mailbox.

        Returns
        -------
        None

        """
        offset = MAILBOX_OFFSET + data_offset
        self.write(offset, data)

    def read_mailbox(self, data_offset, num_words=1):
        """This method reads mailbox data from the Microblaze.

        Parameters
        ----------
        data_offset : int
            The offset for mailbox data, 0,4,... for MAILBOX 0,1,...
        num_words : int
            Number of 32b words to read from Microblaze mailbox.

        Returns
        -------
        int/list
            An int of a list of data read from the mailbox.

        """
        offset = MAILBOX_OFFSET + data_offset
        return self.read(offset, num_words)

    def write_blocking_command(self, command):
        """This method writes a blocking command to the Microblaze.

        The program waits in the loop until the command is cleared by the
        Microblaze.

        Parameters
        ----------
        command : int
            The command to write to the Microblaze.

        Returns
        -------
        None

        """
        self.write(MAILBOX_OFFSET + MAILBOX_PY2DIF_CMD_OFFSET, command)
        while self.read(MAILBOX_OFFSET + MAILBOX_PY2DIF_CMD_OFFSET) != 0:
            pass

    def write_non_blocking_command(self, command):
        """This method writes a non-blocking command to the Microblaze.

        The program will just send the command and returns the control 
        immediately.

        Parameters
        ----------
        command : int
            The command to write to the Microblaze.

        Returns
        -------
        None

        """
        self.write(MAILBOX_OFFSET + MAILBOX_PY2DIF_CMD_OFFSET, command)
