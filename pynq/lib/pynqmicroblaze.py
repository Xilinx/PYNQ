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


import os
import asyncio
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
    reset : GPIO
        The reset pin associated with the Microblaze.
    mmio : MMIO
        The MMIO instance associated with the Microblaze.
    interrupt : Event
        An asyncio.Event-like class for waiting on and clearing interrupts.

    """

    def __init__(self, mb_info, mb_program,
                 intr_pin=None, intr_ack_gpio=None):
        """Create a new Microblaze object.

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

        """
        ip_dict = PL.ip_dict
        gpio_dict = PL.gpio_dict
        intr_dict = PL.interrupt_pins

        ip_name = mb_info['ip_name']
        rst_name = mb_info['rst_name']

        if not os.path.isfile(mb_program):
            raise ValueError(f'{mb_program} does not exist.')
        if ip_name not in ip_dict.keys():
            raise ValueError(f"No such IP {ip_name}.")
        if rst_name not in gpio_dict.keys():
            raise ValueError(f"No such reset pin {rst_name}.")
        if intr_ack_gpio not in gpio_dict.keys():
            intr_ack_gpio = None
        if intr_pin not in intr_dict.keys():
            intr_pin = None

        addr_base = ip_dict[ip_name]['phys_addr']
        addr_range = ip_dict[ip_name]['addr_range']
        ip_state = ip_dict[ip_name]['state']
        gpio_uix = gpio_dict[rst_name]['index']
        intr_ack_gpio = gpio_dict[intr_ack_gpio]['index']

        if (ip_state is None) or (ip_state == mb_program):
            # case 1
            self.ip_name = ip_name
            self.rst_name = rst_name
            self.mb_program = mb_program
            self.state = 'IDLE'
            self.reset = GPIO(GPIO.get_gpio_pin(gpio_uix), "out")
            self.mmio = MMIO(addr_base, addr_range)
        else:
            # case 2
            raise RuntimeError('Another program {} already running.'
                               .format(ip_state))

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
        self.reset.write(0)

    def reset(self):
        """Reset the Microblaze to stop it from running.

        This method will update the status of the Microblaze.

        Returns
        -------
        None

        """
        self.state = 'STOPPED'
        self.reset.write(1)

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

    def write(self, offset, data):
        """This method write data into the shared memory of the Microblaze.

        Parameters
        ----------
        offset : int
            The beginning offset where data are written into.
        data : int/list
            A list of 32b words to be written.

        Returns
        -------
        None

        """
        if type(data) is int:
            self.mmio.write(offset, data)
        elif type(data) is list:
            for i, word in enumerate(data):
                self.mmio.write(offset + 4*i, word)
        else:
            raise ValueError('Type of write data has to be int or lists.')

    def read(self, offset, length=1):
        """This method reads data from the shared memory of Microblaze.

        Parameters
        ----------
        offset : int
            The beginning offset where data are read from.
        length : int
            The number of data (32-bit int) to be read.

        Returns
        -------
        int/list
            An int of a list of data read from the shared memory.

        """
        if length == 1:
            return self.mmio.read(offset)
        elif length > 1:
            return [self.mmio.read(offset + 4*i) for i in range(length)]
        else:
            raise ValueError('Length of read data has to be 1 or more.')
