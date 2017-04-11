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


class Button(object):
    """This class controls the onboard push-buttons.

    Attributes
    ----------
    index : int
        Index of the push-buttons, starting from 0.

    """
    _mmio = None

    def __init__(self, index):
        """Create a new Button object.

        Parameters
        ----------
        index : int
            The index of the push-buttons, from 0 to 3.

        """
        if Button._mmio is None:
            base_addr = PL.ip_dict["btns_gpio"]["phys_addr"]
            Button._mmio = MMIO(base_addr, 512)
        self.index = index
        self.interrupt = None
        try:
            self.interrupt = Interrupt('btns_gpio/ip2intc_irpt')
            # Enable interrupts
            Button._mmio.write(0x11C, 0x80000000)
            Button._mmio.write(0x128, 0x00000001)
        except ValueError:
            pass

    def read(self):
        """Read the current value of the button.

        Returns
        -------
        int
            Either 1 if the button is pressed or 0 otherwise

        """
        curr_val = Button._mmio.read()
        return (curr_val & (1 << self.index)) >> self.index

    @asyncio.coroutine
    def wait_for_value_async(self, value):
        """Wait for the button to be pressed or released

        Parameters
        ----------
        value: int
            1 to wait for press or 0 to wait for release

        This function is an asyncio coroutine

        """
        if self.interrupt is None:
            raise RuntimeError('Interrupts not available in this Overlay')
        while self.read() != value:
            yield from self.interrupt.wait()
            if Button._mmio.read(0x120) & 0x1:
                Button._mmio.write(0x120, 0x00000001)

    def wait_for_value(self, value):
        """Wait for the button to be pressed or released

        Parameters
        ----------
        value: int
            1 to wait for press or 0 to wait for release

        This function wraps the coroutine form so the asyncio
        event loop will run until the function returns

        """
        if self.interrupt is None:
            raise RuntimeError('Interrupts not available in this Overlay')
        loop = asyncio.get_event_loop()
        loop.run_until_complete(asyncio.ensure_future(
            self.wait_for_value_async(value)
        ))
