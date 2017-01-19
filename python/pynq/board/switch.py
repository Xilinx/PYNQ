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
from pynq import MMIO
from pynq import PL
from pynq import Interrupt

__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


class Switch(object):
    """This class controls the onboard switches.

    Attributes
    ----------
    index : int
        Index of the onboard switches, starting from 0.

    """
    _mmio = None

    def __init__(self, index):
        """Create a new Switch object.

        Parameters
        ----------
        index : int
            The index of the onboard switches, from 0 to 3.

        """
        if Switch._mmio is None:
            Switch._mmio = MMIO(PL.ip_dict["SEG_swsleds_gpio_Reg"][0], 512)
        self.index = index
        self.interrupt = None
        try:
            self.interrupt = Interrupt('swsleds_gpio/ip2intc_irpt')
            # Enable interrupts
            Switch._mmio.write(0x11C, 0x80000000)
            Switch._mmio.write(0x128, 0x00000001)
        except ValueError as err:
            print(err)

    def read(self):
        """Read the current value of the switch.

        Returns
        -------
        int
            Either 0 if the switch is off or 1 if the switch is on

        """
        curr_val = Switch._mmio.read()
        return (curr_val & (1 << self.index)) >> self.index

    @asyncio.coroutine
    def wait_for_value_async(self, value):
        """Wait for the switch to be set to a particular position

        Parameters
        ----------
        value: int
            1 for the switch up and 0 for the switch down

        This function is an asyncio coroutine

        """
        if self.interrupt is None:
            raise RuntimeError('Interrupts not available in this Overlay')
        while self.read() != value:
            yield from self.interrupt.wait()
            if Switch._mmio.read(0x120) & 0x1:
                Switch._mmio.write(0x120, 0x00000001)

    def wait_for_value(self, value):
        """Wait for the switch to be set to a particular position

        Parameters
        ----------
        value: int
            1 for the switch up and 0 for the switch down

        This function wraps the coroutine form so the asyncio
        event loop will run until the function returns

        """
        if self.interrupt is None:
            raise RuntimeError('Interrupts not available in this Overlay')
        loop = asyncio.get_event_loop()
        loop.run_until_complete(asyncio.ensure_future(
            self.wait_for_value_async(value)
        ))
