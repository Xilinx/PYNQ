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


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "yunq@xilinx.com"


class MBInterruptEvent:
    """The class provides and asyncio Event-like interface to
    the interrupt subsystem for a Microblaze. The event is set by
    raising an interrupt and cleared using the clear function.

    Typical use is to call clear prior to sending a request to
    the Microblaze and waiting in a loop until the response is received.
    This order of operations will avoid race conditions between the
    Microblaze and the host code.

    """
    def __init__(self, intr_pin, intr_ack_gpio):
        """Create a new _MBInterruptEvent object

        Parameters
        ----------
        intr_pin : str
            Name of the interrupt pin for the Microblaze.
        intr_ack_gpio : int
            Number of the GPIO pin used to clear the interrupt.

        """
        self.interrupt = Interrupt(intr_pin)
        self.gpio = GPIO(GPIO.get_gpio_pin(intr_ack_gpio), "out")

    @asyncio.coroutine
    def wait(self):
        """Coroutine to wait until the event is set by an interrupt.

        """
        yield from self.interrupt.wait()

    def clear(self):
        """Clear the interrupt and reset the event. Resetting the event
        should be done before sending a request that will be acknowledged
        interrupts.

        """
        self.gpio.write(1)
        self.gpio.write(0)


class PynqMicroblaze:
    """This class controls the active Microblaze instances in the system.

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

    def __init__(self, ip_name, addr_base, addr_range, mb_program,
                 rst_name, gpio_uix,
                 intr_pin=None, intr_ack_gpio=None):
        """Create a new Microblaze object.

        Parameters
        ----------
        ip_name : str
            The name of the IP corresponding to the Microblaze.
        rst_name : str
            The name of the reset pin for the Microblaze.
        addr_base : int
            The base address for the MMIO.
        addr_range : int
            The address range for the MMIO.
        gpio_uix : int
            The user index of the GPIO, starting from 0.
        mb_program : str
            The Microblaze program loaded for the processor.
        intr_pin : str
            Name of the interrupt pin for the Microblaze.
        intr_ack_gpio : int
            Number of the GPIO pin used to clear the interrupt.

        """
        self.ip_name = ip_name
        self.rst_name = rst_name
        self.mb_program = mb_program
        self.state = 'IDLE'
        self.gpio = GPIO(GPIO.get_gpio_pin(gpio_uix), "out")
        self.mmio = MMIO(addr_base, addr_range)
        self.interrupt = None

        if intr_pin and intr_ack_gpio:
            self.interrupt = MBInterruptEvent(intr_pin, intr_ack_gpio)
        self.program()

    def run(self):
        """Start the Microblaze to run program loaded.

        This method will update the status of the Microblaze.

        Returns
        -------
        None

        """
        self.state = 'RUNNING'
        self.gpio.write(0)

    def reset(self):
        """Reset the Microblaze to stop it from running.

        This method will update the status of the Microblaze.

        Returns
        -------
        None

        """
        self.state = 'STOPPED'
        self.gpio.write(1)

    def program(self):
        """This method programs the Microblaze.

        This method is called in __init__(); it can also be called after that.
        It uses the attribute `self.mb_program` to program the Microblaze.

        Returns
        -------
        None

        """
        self.reset()
        PL.load_ip_data(self.ip_name, self.mb_program)
        if self.interrupt:
            self.interrupt.clear()
        self.run()

    def write(self, offsets, data):
        """This method write data into the shared memory of the Microblaze.

        Parameters
        ----------
        offsets : list
            A list of offsets where data are to be written.
        data : list
            A list of 32b words to be written.

        Returns
        -------
        None

        """
        if len(offsets) != len(data):
            raise ValueError("Offsets length not equal to data length.")

        for offset, word in zip(offsets, data):
            self.mmio.write(offset, word)

    def read(self, offsets):
        """This method reads data from the shared memory of Microblaze.

        Parameters
        ----------
        offsets : list
            A list of offsets where data are read from.

        Returns
        -------
        list
            list of data read from the shared memory.

        """
        return [self.mmio.read(offset) for offset in offsets]
