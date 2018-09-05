#   Copyright (c) 2017, Xilinx, Inc.
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
import weakref
import warnings
from .pl import PL
from .ps import CPU_ARCH, ZU_ARCH, ZYNQ_ARCH
from .mmio import MMIO
from .uio import get_uio_device, UioController

__author__ = "Peter Ogden"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


def get_uio_irq(irq):
    """Returns the UIO device path for a specified interrupt.

    If the IRQ either cannot be found or does not correspond to a
    UIO device, None is returned.

    Parameters
    ----------
    irq : int
        The desired physical interrupt line

    Returns
    -------
    str
        The path of the device in /dev list.

    """
    dev_name = None
    with open('/proc/interrupts', 'r') as f:
        for line in f:
            cols = line.split()
            if len(cols) >= 7:
                if cols[-3] == str(irq):
                    dev_name = cols[-1]
    if dev_name is None:
        return None
    else:
        return get_uio_device(dev_name)


class Interrupt(object):
    """Class that provides the core wait-based API to end users

    Provides a single coroutine wait that waits until the interrupt
    signal goes high. If the Overlay is changed or re-downloaded this
    object is invalidated and waiting results in undefined behaviour."""

    def __init__(self, pinname):
        """Initialise an Interrupt object attached to the specified pin

        Parameters
        ----------
        pinname : string
            Fully qualified name of the pin in the block diagram of the
            for ${cell}/${pin}. Raises an exception if the pin cannot
            be found in the currently active Overlay

        """
        if pinname not in PL.interrupt_pins:
            raise ValueError("No Pin of name {} found".format(pinname))

        parentname = PL.interrupt_pins[pinname]['controller']
        self.number = PL.interrupt_pins[pinname]['index']
        self.parent = weakref.ref(
            _InterruptController.get_controller(parentname))
        self.event = asyncio.Event()
        self.waiting = False

    @asyncio.coroutine
    def wait(self):
        """Wait for the interrupt to be active

        May raise an exception if the Overlay has been changed since
        initialisation.
        """
        parent = self.parent()
        if parent is None:
            raise RuntimeError("Interrupt invalidated by Overlay change")
        if not self.waiting:
            self.event.clear()
            parent.add_event(self.event, self.number)
            self.waiting = True
        yield from self.event.wait()
        self.waiting = False


class _InterruptController(object):
    """Class that interacts with an AXI interrupt controller

    This class is not designed to be interacted with by end users directly -
    most uses will be via the register_interrupt API which will handle the
    creation and registration of _InterruptController instances

    """
    _controllers = []
    _last_timestamp = None
    if CPU_ARCH == ZYNQ_ARCH:
        irq_offset = 61
    elif CPU_ARCH == ZU_ARCH:
        irq_offset = 121
    else:
        warnings.warn("PYNQ does not support the CPU Architecture: {}"
                      .format(CPU_ARCH), ResourceWarning)

    @staticmethod
    def get_controller(name):
        """Returns the _InterruptController corresponding to the AXI interrupt
        controller with the specified name. Will invalidate all interrupt
        controllers if the Overlay has been changed. Should not be accessed
        by user code.

        Parameters
        ----------
        name : str
            Name of the interrupt controller to return

        """
        bitstream_timestamp = PL.timestamp
        if bitstream_timestamp != _InterruptController._last_timestamp:
            _InterruptController._controllers.clear()
            _InterruptController._last_timestamp = bitstream_timestamp

        for con in _InterruptController._controllers:
            if con.name == name:
                return con
        ret = _InterruptController(name)
        _InterruptController._controllers.append(ret)
        return ret

    def __init__(self, name):
        """Return a new _InterruptController

        Returns a new _InterruptController. As these are singleton objects,
        this should never be called directly, instead register_interrupt
        should be used, or get_controller if direct access is required

        Parameters
        ----------
        name : str
            Name of the interrupt controller to return

        """
        self.name = name
        self.mmio = MMIO(PL.ip_dict[name]['phys_addr'], 32)
        self.wait_handles = [[] for _ in range(32)]
        self.event_number = 0
        self.waiting = False

        # Disable Interrupt lines
        self.mmio.write(0x08, 0)

        parent = PL.interrupt_controllers[name]['parent']
        number = PL.interrupt_controllers[name]['index']
        if parent == "":
            uiodev = get_uio_irq(self.irq_offset + number)
            if uiodev is None:
                raise ValueError('Could not find UIO device for interrupt pin '
                                 'for IRQ number {}'.format(number))
            self.parent = UioController(uiodev)
            self.number = 0
        else:
            self.parent = _InterruptController.get_controller(parent)
            self.number = number

    def set(self):
        """Mimics the set function of an event. Should not be called by
        user code

        Allows for chaining of interrupt controllers by looking like an
        event to the parent controller. Will re-add the event if there
        are still interrupts left outstanding
        """
        # Pull pending interrupts
        irqs = self.mmio.read(0x04)
        # Call all active IRQs
        work = irqs
        irq = 0
        while work != 0:
            if work % 2 == 1:
                # Disable the interrupt
                self.mmio.write(0x14, 1 << irq)
                events = self.wait_handles[irq]
                self.wait_handles[irq] = []
                for e in events:
                    e.set()
                self.event_number -= len(events)
            work = work >> 1
            irq = irq + 1

        # Acknowledge the interrupts
        self.mmio.write(0x0C, irqs)
        if self.event_number:
            self.parent.add_event(self, self.number)

    def add_event(self, event, number):
        """Registers an event against an interrupt line

        When the interrupt is active, all events are signaled and the
        interrupt line is disabled. End user classes should clear the
        interrupt before re-adding the event.

        Parameters
        ----------
        event : object
            Any object that provides a set method to notify of
            an active interrupt
        number : int
            Interrupt number to register event against

        """

        if not self.wait_handles[number]:
            self.mmio.write(0x10, 1 << number)
        if not self.event_number:
            self.parent.add_event(self, self.number)
        self.wait_handles[number].append(event)
        self.event_number += 1
        # Enable global interrupt
        self.mmio.write(0x1C, 0x00000003)
