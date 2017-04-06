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
from pynq.iop import iop_const


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "yunq@xilinx.com"


class _IOPInterruptEvent:
    """The class provides and asyncio Event-like interface to
    the interrupt subsystem for an IOP. The event is set by the IOP
    raising an interrupt and cleared using the clear function.

    Typical use is to call clear prior to sending a request to
    the IOP and waiting in a loop until the response is received.
    This order of operations will avoid race conditions between the
    IOP and the host code.

    """
    def __init__(self, intr_pin, intr_ack_gpio):
        """Create a new _IOPInterruptEvent object

        Parameters
        ----------
        intr_pin : str
            Name of the interrupt pin for the IOP
        intr_ack_gpio : int
            Number of the GPIO pin used to clear the interrupt

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
    interrupt : Event
        An asyncio.Event-like class for waiting on and clearing interrupts

    """

    def __init__(self, iop_name, addr_base, addr_range, gpio_uix,
                 mb_program, intr_pin=None, intr_ack_gpio=None):
        """Create a new _IOP object.

        Parameters
        ----------
        iop_name : str
            The name of the IP corresponding to the I/O Processor.
        addr_base : int
            The base address for the MMIO.
        addr_range : int
            The address range for the MMIO.
        gpio_uix : int
            The user index of the GPIO, starting from 0.
        mb_program : str
            The Microblaze program loaded for the IOP.

        """
        self.iop_name = iop_name
        self.mb_program = mb_program
        self.state = 'IDLE'
        self.gpio = GPIO(GPIO.get_gpio_pin(gpio_uix), "out")
        self.mmio = MMIO(addr_base, addr_range)
        if intr_pin and intr_ack_gpio:
            self.interrupt = _IOPInterruptEvent(intr_pin, intr_ack_gpio)

        self.program()

    def start(self):
        """Start the Microblaze of the current IOP.

        This method will update the status of the IOP.

        Returns
        -------
        None

        """
        self.state = 'RUNNING'
        self.gpio.write(0)

    def stop(self):
        """Stop the Microblaze of the current IOP.

        This method will update the status of the IOP.

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

        Returns
        -------
        None

        """
        self.stop()

        PL.load_ip_data(self.iop_name, self.mb_program)

        self.interrupt.clear()
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
    ip_dict = PL.ip_dict
    gpio_dict = PL.gpio_dict
    intr_dict = PL.interrupt_pins

    iop = "SEG_mb_bram_ctrl_" + str(iop_id) + "_Mem0"
    rst_pin = "mb_" + str(iop_id) + "_reset"
    intr_pin = "iop{0}/dff_en_reset_0/q".format(iop_id)
    intr_ack_pin = "mb_{0}_intr_ack".format(iop_id)

    ip = [k for k, _ in ip_dict.items()]
    gpio = [k for k, _ in gpio_dict.items()]

    if iop not in ip:
        raise ValueError("No such IOP {}.".format(iop_id))
    if rst_pin not in gpio:
        raise ValueError("No such reset pin for IOP {}.".format(iop_id))
    if intr_ack_pin not in gpio:
        intr_ack_pin = None
    if intr_pin not in intr_dict:
        intr_pin = None

    addr_base, addr_range, ip_state = ip_dict[iop]
    gpio_uix, _ = gpio_dict[rst_pin]
    intr_ack_gpio, _ = gpio_dict[intr_ack_pin]

    mb_path = mb_program
    if not os.path.isabs(mb_path):
        mb_path = os.path.join(iop_const.BIN_LOCATION, mb_path)

    if (ip_state is None) or \
            (ip_state == mb_path):
        # case 1
        return _IOP(iop, addr_base, addr_range, gpio_uix,
                    mb_path, intr_pin, intr_ack_gpio)
    else:
        # case 2
        raise LookupError('Another program {} already running on IOP.'
                          .format(ip_state))
