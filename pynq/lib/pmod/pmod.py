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
from pynq.lib import PynqMicroblaze
from pynq.lib.pynqmicroblaze import add_bsp
from . import MAILBOX_OFFSET
from . import MAILBOX_PY2IOP_CMD_OFFSET
from . import BIN_LOCATION
from . import BSP_LOCATION

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
    reset_pin : GPIO
        The reset pin associated with the Microblaze.
    mmio : MMIO
        The MMIO instance associated with the Microblaze.
    interrupt : Event
        An asyncio.Event-like class for waiting on and clearing interrupts.

    """

    def __init__(self, mb_info, mb_program):
        """Create a new Microblaze object.

        This method leverages the initialization method of its parent. It 
        also deals with relative / absolute path of the program.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the 
            IP name and the reset name.
        mb_program : str
            The Microblaze program loaded for the processor.

        Examples
        --------
        The `mb_info` is a dictionary storing Microblaze information:

        >>> mb_info = {'ip_name': 'mb_bram_ctrl_1',
        'rst_name': 'mb_reset_1', 
        'intr_pin_name': 'iop1/dff_en_reset_0/q', 
        'intr_ack_name': 'mb_1_intr_ack'}

        """
        if not os.path.isabs(mb_program):
            mb_program = os.path.join(BIN_LOCATION, mb_program)

        super().__init__(mb_info, mb_program)

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
        self.write(MAILBOX_OFFSET + MAILBOX_PY2IOP_CMD_OFFSET, command)
        while self.read(MAILBOX_OFFSET + MAILBOX_PY2IOP_CMD_OFFSET) != 0:
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
        self.write(MAILBOX_OFFSET + MAILBOX_PY2IOP_CMD_OFFSET, command)


if os.path.exists(BSP_LOCATION):
    add_bsp(BSP_LOCATION)
