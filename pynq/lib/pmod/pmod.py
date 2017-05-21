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
from pynq import MMIO
from pynq import GPIO
from pynq import PL
from pynq import Interrupt
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
    gpio : GPIO
        The GPIO instance associated with the Microblaze.
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
        ip_dict = PL.ip_dict
        gpio_dict = PL.gpio_dict
        intr_dict = PL.interrupt_pins

        ip_name = mb_info['ip_name']
        rst_name = mb_info['rst_name']

        if ip_name not in ip_dict.keys():
            raise ValueError(f"No such IP {ip_name}.")
        if rst_name not in gpio_dict.keys():
            raise ValueError(f"No such reset pin {rst_name}.")
        if intr_ack_pin not in gpio_dict.keys():
            intr_ack_pin = None
        if intr_pin not in intr_dict.keys():
            intr_pin = None

        addr_base = ip_dict[ip_name]['phys_addr']
        addr_range = ip_dict[ip_name]['addr_range']
        ip_state = ip_dict[ip_name]['state']
        gpio_uix = gpio_dict[rst_name]['index']
        intr_ack_gpio = gpio_dict[intr_ack_pin]['index']

        mb_path = mb_program
        if not os.path.isabs(mb_path):
            mb_path = os.path.join(BIN_LOCATION, mb_path)

        if (ip_state is None) or (ip_state == mb_path):
            # case 1
            super().__init__(ip_name, addr_base, addr_range, mb_program,
                             rst_name, gpio_uix,
                             intr_pin, intr_ack_gpio)
        else:
            # case 2
            raise RuntimeError('Another program {} already running.'
                               .format(ip_state))

    def write_mailbox(self, offsets, data):
        """This method write data into the mailbox of the Microblaze.

        Parameters
        ----------
        offsets : list
            A list of offsets where data are to be written.
        data : list
            A list of 32b words to be written into the mailbox.

        Returns
        -------
        None

        """
        mailbox_offsets = [(MAILBOX_OFFSET + offset) for offset in offsets]
        self.write(mailbox_offsets, data)

    def read_mailbox(self, offsets):
        """This method reads mailbox data from the Microblaze.

        Parameters
        ----------
        offsets : list
            A list of offsets where data are read from.

        Returns
        -------
        list
            list of data read from mailbox.

        """
        mailbox_offsets = [(MAILBOX_OFFSET + offset) for offset in offsets]
        return self.read(mailbox_offsets)

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
        self.mmio.write(MAILBOX_OFFSET + MAILBOX_PY2DIF_CMD_OFFSET, command)
        while not (self.mmio.read(MAILBOX_OFFSET +
                                  MAILBOX_PY2DIF_CMD_OFFSET) == 0):
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
        self.mmio.write(MAILBOX_OFFSET + MAILBOX_PY2DIF_CMD_OFFSET, command)
