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
from pynq import DefaultHierarchy

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
    reset_pin : GPIO
        The reset pin associated with the Microblaze.
    mmio : MMIO
        The MMIO instance associated with the Microblaze.
    interrupt : Event
        An asyncio.Event-like class for waiting on and clearing interrupts.

    """

    def __init__(self, mb_info, mb_program, force=False):
        """Create a new Microblaze object.

        It looks for active instances on the same Microblaze, and prevents 
        users from silently reloading the Microblaze program. Users are 
        notified with an exception if a program is already running on the
        selected Microblaze, to prevent unwanted behavior.

        Two cases:

        1.  No previous Microblaze program loaded in the system, 
        or users want to request another instance using the same program.
        No exception will be raised in this case.

        2.  There is a previous Microblaze program loaded in the system.
        Users want to request another instance with a different 
        program. An exception will be raised.

        Note
        ----
        When a Microblaze program is already loaded in the system, and users
        want to instantiate another object using a different Microblaze 
        program, users are in danger of losing existing objects.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the 
            IP name and the reset name.
        mb_program : str
            The Microblaze program loaded for the processor.

        Raises
        ------
        RuntimeError
            When another Microblaze program is already loaded.

        Examples
        --------
        The `mb_info` is a dictionary storing Microblaze information:

        >>> mb_info = {'ip_name': 'mb_bram_ctrl_1',
        'rst_name': 'mb_reset_1', 
        'intr_pin_name': 'iop1/dff_en_reset_0/q', 
        'intr_ack_name': 'mb_1_intr_ack'}

        """
        ip_dict = PL.ip_dict
        gpio_dict = PL.gpio_dict
        intr_dict = PL.interrupt_pins

        # Check program path
        if not os.path.isfile(mb_program):
            raise ValueError('{} does not exist.'
                             .format(mb_program))

        # Get IP information
        ip_name = mb_info['ip_name']
        if ip_name not in ip_dict.keys():
            raise ValueError("No such IP {}.".format(ip_name))
        addr_base = ip_dict[ip_name]['phys_addr']
        addr_range = ip_dict[ip_name]['addr_range']
        ip_state = ip_dict[ip_name]['state']

        # Get reset information
        rst_name = mb_info['rst_name']
        if rst_name not in gpio_dict.keys():
            raise ValueError("No such reset pin {}."
                             .format(rst_name))
        gpio_uix = gpio_dict[rst_name]['index']

        # Get interrupt pin information
        if 'intr_pin_name' in mb_info:
            intr_pin_name = mb_info['intr_pin_name']
            if intr_pin_name not in intr_dict.keys():
                raise ValueError("No such interrupt pin {}."
                                 .format(intr_pin_name))
        else:
            intr_pin_name = None

        # Get interrupt ACK information
        if 'intr_ack_name' in mb_info:
            intr_ack_name = mb_info['intr_ack_name']
            if intr_ack_name not in gpio_dict.keys():
                raise ValueError("No such interrupt ACK {}."
                                 .format(intr_ack_name))
            intr_ack_gpio = gpio_dict[intr_ack_name]['index']
        else:
            intr_ack_gpio = None

        # Set basic attributes
        self.ip_name = ip_name
        self.rst_name = rst_name
        self.mb_program = mb_program
        self.state = 'IDLE'
        self.reset_pin = GPIO(GPIO.get_gpio_pin(gpio_uix), "out")
        self.mmio = MMIO(addr_base, addr_range)

        # Check to see if Microblaze in user
        if (ip_state is not None) and (ip_state != mb_program):
            if force:
                self.reset()
            else:
                raise RuntimeError('Another program {} already running.'
                                   .format(ip_state))

        # Set optional attributes
        if (intr_pin_name is not None) and (intr_ack_gpio is not None):
            self.interrupt = MBInterruptEvent(intr_pin_name, intr_ack_gpio)
        else:
            self.interrupt = None

        # Reset, program, and run
        self.program()

    def run(self):
        """Start the Microblaze to run program loaded.

        This method will update the status of the Microblaze.

        Returns
        -------
        None

        """
        self.state = 'RUNNING'
        self.reset_pin.write(0)

    def reset(self):
        """Reset the Microblaze to stop it from running.

        This method will update the status of the Microblaze.

        Returns
        -------
        None

        """
        self.state = 'STOPPED'
        self.reset_pin.write(1)

    def program(self):
        """This method programs the Microblaze.

        This method is called in __init__(); it can also be called after that.
        It uses the attribute `self.mb_program` to program the Microblaze.

        Returns
        -------
        None

        """
        self.reset()
        PL.load_ip_data(self.ip_name, self.mb_program, zero=True)
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


class MicroblazeHierarchy(DefaultHierarchy):
    """Hierarchy driver for the microblaze subsystem.

    Enables the user to `load` programs on to the microblaze. All function
    calls and member accesses are delegated to the loaded program.

    """
    def __init__(self, description, mbtype="Unknown"):
        super().__init__(description)
        hier = description['fullpath']
        if hier.count('/') > 0:
            parent, _, ip = hier.rpartition('/')
            container = "{}/".format(parent)
        else:
            container = ""
            ip = hier
        self.mb_info = {'ip_name': '{}/mb_bram_ctrl'.format(hier),
                        'rst_name': '{}mb_{}_reset'.format(container,ip),
                        'intr_pin_name': '{}/dff_en_reset_vector_0/q'.format(
                            hier),
                        'intr_ack_name': '{}mb_{}_intr_ack'.format(
                            container, ip),
                        'mbtype': mbtype,
                        'name' : hier}

    @property
    def mbtype(self):
        """The defined type of the microblaze subsystem. Used by driver 
        programs to limit what microblaze subsystems the program is run on.

        """
        return self.mb_info['mbtype']

    @mbtype.setter
    def mbtype(self, value):
        self.mb_info['mbtype'] = value

    @staticmethod
    def checkhierarchy(description):
        return 'mb_bram_ctrl' in description['ip']
