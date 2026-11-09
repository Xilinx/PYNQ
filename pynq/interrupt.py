#   Copyright (c) 2017-2022, Xilinx, Inc.
#   Copyright (C) 2022-2026 Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import asyncio
import weakref
from .pl_server.device import Device
from .pl_server.global_state import (
    global_state_file_exists, load_global_state,
)
from .mmio import MMIO
from .uio import get_uio_device, UioController


def _metadata(device):
    """Use this device's metadata, including the classic saved-metadata path."""
    if getattr(device, "interrupt_pins", None) is not None:
        return device
    metadata = device.dict_views
    if metadata is None:
        raise RuntimeError("No interrupt metadata available for this device")
    return metadata


def _timestamp(device):
    if hasattr(device, "timestamp"):
        return device.timestamp
    tag = getattr(device, "_state_tag", "")
    if global_state_file_exists(tag):
        return load_global_state(tag).timestamp
    return None


def _controller_state(device):
    timestamp = _timestamp(device)
    state = getattr(device, "_interrupt_state", None)
    if state is None:
        state = {"timestamp": timestamp, "controllers": {}, "uio": {}}
        device._interrupt_state = state
    elif state["timestamp"] != timestamp:
        state["controllers"].clear()
        state["timestamp"] = timestamp
    return state



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

    def __new__(cls, pinname, device=None):
        device = device if device is not None else Device.active_device
        backend = getattr(device, "_interrupt_class", cls)
        if backend is not cls and backend is not Interrupt:
            return backend(pinname, device=device)
        return super().__new__(cls)

    def __init__(self, pinname, device=None):
        """Initialise an Interrupt object attached to the specified pin

        Parameters
        ----------
        pinname : string
            Fully qualified name of the pin in the block diagram of the
            for ${cell}/${pin}. Raises an exception if the pin cannot
            be found in the selected device's overlay.
        device : Device, optional
            Target device. Defaults to the active device at construction.

        """
        self.device = device if device is not None else Device.active_device
        pins = _metadata(self.device).interrupt_pins
        if pinname not in pins:
            raise ValueError("No Pin of name {} found".format(pinname))
        parent, self.number = _InterruptController.get_parent(
            pins[pinname], self.device)

        self._timestamp = _timestamp(self.device)
        self.parent = weakref.ref(parent)
        self.event = asyncio.Event()
        self.waiting = False

    async def wait(self):
        """Wait for the interrupt to be active

        May raise an exception if the Overlay has been changed since
        initialisation.
        """
        _controller_state(self.device)
        parent = self.parent()
        if self._timestamp != _timestamp(self.device):
            raise RuntimeError("Interrupt invalidated by Overlay change")
        if parent is None:
            raise RuntimeError("Interrupt invalidated by Overlay change")
        if not self.waiting:
            self.event.clear()
            parent.add_event(self.event, self.number)
            self.waiting = True
        await self.event.wait()
        self.waiting = False


class _InterruptController(object):
    """Class that interacts with an AXI interrupt controller

    This class is not designed to be interacted with by end users directly -
    most uses will be via the register_interrupt API which will handle the
    creation and registration of _InterruptController instances

    """
    @staticmethod
    def get_controller(name, device=None):
        """Returns the _InterruptController corresponding to the AXI interrupt
        controller with the specified name. Will invalidate this device's
        interrupt controllers if its overlay has changed. Should not be accessed
        by user code.

        Parameters
        ----------
        name : str
            Name of the interrupt controller to return

        """
        device = device if device is not None else Device.active_device
        controllers = _controller_state(device)["controllers"]
        if name in controllers:
            return controllers[name]
        ret = _InterruptController(name, device)
        controllers[name] = ret
        return ret

    @staticmethod
    def get_parent(entry, device=None):
        """Return the parent and index of an interrupt.

        This can either be an interrupt controller or a UIO interface

        Parameters
        ----------
        entry : dict
            The entry in the interrupt_pins dict for the pin

        """
        device = device if device is not None else Device.active_device
        state = _controller_state(device)
        parent = entry['parent'] if 'parent' in entry else entry['controller']
        number = entry['index']
        if parent == "":
            raw_irq = entry['raw_irq']
            if raw_irq in state["uio"]:
                return state["uio"][raw_irq], 0
            uiodev = get_uio_irq(raw_irq)
            if uiodev is None:
                raise ValueError('Could not find UIO device for interrupt pin '
                                 'for IRQ number {}'.format(raw_irq))
            dev = UioController(uiodev)
            state["uio"][raw_irq] = dev
            return dev, 0
        else:
            return _InterruptController.get_controller(parent, device), number

    def __init__(self, name, device=None):
        """Return a new _InterruptController

        Returns a new _InterruptController. As these are singleton objects,
        this should never be called directly, instead register_interrupt
        should be used, or get_controller if direct access is required

        Parameters
        ----------
        name : str
            Name of the interrupt controller to return

        """
        self.device = device if device is not None else Device.active_device
        metadata = _metadata(self.device)
        self.name = name
        self.mmio = MMIO(metadata.ip_dict[name]['phys_addr'], 32, device=self.device)
        self.wait_handles = [[] for _ in range(32)]
        self.event_number = 0
        self.waiting = False

        # Disable Interrupt lines
        self.mmio.write(0x08, 0)

        self.parent, self.number = _InterruptController.get_parent(
            metadata.interrupt_controllers[name], self.device)

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


