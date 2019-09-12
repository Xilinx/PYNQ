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
from pynq import DefaultIP


__author__ = "Peter Ogden"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


class AxiGPIO(DefaultIP):
    """Class for interacting with the AXI GPIO IP block.

    This class exposes the two banks of GPIO as the `channel1` and
    `channel2` attributes. Each channel can have the direction and
    the number of wires specified.

    The wires in the channel can be accessed from the channel using
    slice notation - all slices must have a stride of 1. Input wires
    can be `read` and output wires can be written to, toggled, or
    turned off or on. InOut channels combine the functionality of
    input and output channels. The tristate of the pin is determined
    by whether the pin was last read or written.

    """
    class Input:
        """Class representing wires in an input channel.

        This class should be passed to `setdirection` to indicate the
        channel should be used for input only. It should not be used
        directly.

        """
        def __init__(self, parent, start, stop):
            self._parent = parent
            self._start = start
            self._stop = stop
            self._mask = (1 << (stop - start)) - 1

        def read(self):
            """Reads the value of all the wires in the slice

            If there is more than one wire in the slice then the least
            significant bit of the return value corresponds to the
            wire with the lowest index.

            """
            return (self._parent.read() >> self._start) & self._mask

        @asyncio.coroutine
        def wait_for_value_async(self, value):
            """Coroutine that waits until the specified value is read

            This function relies on interrupts being available for the IP
            block and will throw a `RuntimeError` otherwise.

            """
            while self.read() != value:
                yield from self._parent.wait_for_interrupt_async()

        def wait_for_value(self, value):
            """Wait until the specified value is read

            This function is dependent on interrupts being enabled
            and will throw a `RuntimeError` otherwise. Internally it
            uses asyncio so should not be used inside an asyncio task.
            Use `wait_for_value_async` if using asyncio.

            """
            loop = asyncio.get_event_loop()
            loop.run_until_complete(asyncio.ensure_future(
                self.wait_for_value_async(value)
            ))

    class Output:
        """Class representing wires in an output channel.

        This class should be passed to `setdirection` to indicate the
        channel should be used for output only. It should not be used
        directly.

        """
        def __init__(self, parent, start, stop):
            self._parent = parent
            self._start = start
            self._stop = stop
            self._mask = (1 << (stop - start)) - 1

        def read(self):
            """Reads the value of all the wires in the slice

            If there is more than one wire in the slice then the least
            significant bit of the return value corresponds to the
            wire with the lowest index.

            """
            return (self._parent._val >> self._start) & self._mask

        def write(self, val):
            """Set the value of the slice

            If the slice consists of more than one wire then the least
            significant bit of `val` corresponds to the lowest index
            wire.

            """
            if val > self._mask:
                raise ValueError("{} too large for {} bits"
                                 .format(val, self._stop - self._start))
            self._parent.write(val << self._start, self._mask << self._start)

        def on(self):
            """Turns on all of the wires in the slice

            """
            self.write(self._mask)

        def off(self):
            """Turns off all of the wires in the slice

            """
            self.write(0)

        def toggle(self):
            """Toggles all of the wires in the slice

            """
            self.write((~self._parent.val >> self._start) & self._mask)

    class InOut(Output, Input):
        """Class representing wires in an inout channel.

        This class should be passed to `setdirection` to indicate the
        channel should be used for both input and output. It should not
        be used directly.

        """
        def __init__(self, parent, start, stop):
            self._parent = parent
            self._start = start
            self._stop = stop
            self._mask = (1 << (stop - start)) - 1
            self._trimask = self._mask << start

        def read(self):
            """Reads the value of all the wires in the slice

            Changes the tristate of the slice to input.
            If there is more than one wire in the slice then the least
            significant bit of the return value corresponds to the
            wire with the lowest index.

            """
            self._parent.trimask |= self._trimask
            return super().read()

        def write(self, val):
            """Set the value of the slice

            Changes the tristate of the slice to output.
            If the slice consists of more than one wire then the least
            significant bit of `val` corresponds to the lowest index
            wire.

            """
            self._parent.trimask &= ~self._trimask
            return super().write(val)

    class Channel:
        """Class representing a single channel of the GPIO controller.

        Wires are and bundles of wires can be accessed using array notation
        with the methods on the wires determined by the type of the channel::

            input_channel[0].read()
            output_channel[1:3].on()

        This class instantiated not used directly, instead accessed through
        the `AxiGPIO` classes attributes. This class exposes the wires
        connected to the channel as an array or elements. Slices of the
        array can be assigned simultaneously.

        """
        def __init__(self, parent, channel):
            self._parent = parent
            self._channel = channel
            self.slicetype = AxiGPIO.InOut
            self.length = 32
            self.val = 0
            self._waiter_count = 0

        def __getitem__(self, idx):
            if isinstance(idx, slice):
                if idx.step is not None and idx.step != 1:
                    raise IndexError("Steps other than 1 not supported")
                return self.slicetype(self, idx.start, idx.stop)
            elif isinstance(idx, int):
                if idx >= self.length:
                    raise IndexError()
                return self.slicetype(self, idx, idx + 1)

        def __len__(self):
            return self.length

        def write(self, val, mask):
            """Set the state of the output pins

            """
            self.val = (self.val & ~mask) | (val & mask)
            self._parent.write(self._channel * 8, self.val)

        def read(self):
            """Read the state of the input pins

            """
            return self._parent.read(self._channel * 8)

        @property
        def trimask(self):
            """Gets or sets the tri-state mask for an inout channel

            """
            return self._parent.read(self._channel * 8 + 4)

        @trimask.setter
        def trimask(self, value):
            self._parent.write(self._channel * 8 + 4, value)

        def setlength(self, length):
            """Set the number of wires connected to the channel

            """
            self.length = length

        def setdirection(self, direction):
            """Set the direction of the channel

            Must be one of AxiGPIO.{Input, Output, InOut} or the string
            'in', 'out', or 'inout'

            """
            if type(direction) is str:
                if direction in _direction_map:
                    direction = _direction_map[direction]
            if direction not in [AxiGPIO.Input, AxiGPIO.Output, AxiGPIO.InOut]:
                raise ValueError(
                    "direction should be one of AxiGPIO.{Input,Output,InOut} "
                    "or the string 'in', 'out' or 'inout'")
            self.slicetype = direction

        @asyncio.coroutine
        def wait_for_interrupt_async(self):
            """Wait for the interrupt on the channel to be signalled

            This is intended to be used by slices waiting for a particular
            value but can be used in any situation to wait for a per-channel
            interrupt.

            """
            if not self._parent.has_interrupts:
                raise RuntimeError('Interrupts not available for this IP')

            mask = (1 << self._channel)
            if self._waiter_count == 0:
                enable = self._parent.read(0x128)
                enable |= mask
                self._parent.write(0x128, enable)

            self._waiter_count += 1

            yield from self._parent.ip2intc_irpt.wait()
            if self._parent.read(0x120) & mask:
                self._parent.write(0x120, mask)

            self._waiter_count -= 1

            if self._waiter_count == 0:
                enable = self._parent.read(0x128)
                enable &= ~mask
                self._parent.write(0x128, enable)

    def __init__(self, description):
        super().__init__(description)
        self._channels = [AxiGPIO.Channel(self, i) for i in range(2)]
        self.channel1 = self._channels[0]
        self.channel2 = self._channels[1]
        if 'ip2intc_irpt' in description['interrupts']:
            self.write(0x11C, 0x80000000)
            self.has_interrupts = True
        else:
            self.has_interrupts = False

    def setlength(self, length, channel=1):
        """Sets the length of a channel in the controller

        """
        self._channels[channel - 1].length = length

    def setdirection(self, direction, channel=1):
        """Sets the direction of a channel in the controller

        Must be one of AxiGPIO.{Input, Output, InOut} or the string
        'in', 'out' or 'inout'

        """
        if direction not in [AxiGPIO.Input, AxiGPIO.Output, AxiGPIO.InOut]:
            raise ValueError(
                "direction should be one of AxiGPIO.{Input,Output,InOut}")
        self._channels[channel - 1].slicetype = direction

    def __getitem__(self, idx):
        return self.channel1[idx]

    bindto = ['xilinx.com:ip:axi_gpio:2.0']

_direction_map = { "in": AxiGPIO.Input,
                   "out": AxiGPIO.Output,
                   "inout": AxiGPIO.InOut }
