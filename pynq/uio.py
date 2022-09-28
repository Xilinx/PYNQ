#   Copyright (c) 2017, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import asyncio
import functools
import os



def get_uio_device(dev_name):
    """Returns the UIO device path.

    This method will return None if no such device can be found.

    Parameters
    ----------
    dev_name : str
        The name of the UIO device.

    Returns
    -------
    str
        The path of the device in /dev list.

    """
    for dev in os.listdir("/sys/class/uio"):
        with open('/sys/class/uio/' + dev + '/name', 'r') as f:
            name = f.read().strip()
        if name == dev_name:
            return '/dev/' + dev
    return None


def get_uio_index(name):
    """Return the uio index for the given device.

    Parameters
    ----------
    name : str
        The name of the UIO device.

    Returns
    -------
    int
        The index number for the UIO device.

    """
    d = get_uio_device(name)
    if d is None:
        return None
    return int(d[len(d.rstrip('0123456789')):])


class UioController(object):
    """Class that interacts directly with a UIO device.

    Attributes
    ----------
    uio : _io.BufferedRandom
        File handle for the opened UIO.

    """
    def __init__(self, device):
        """Initialize the UIO controller.

        Parameters
        ----------
        device : str
            The path of the device extracted from /dev.

        """
        self.uio = open(device, 'r+b', buffering=0)
        asyncio.get_event_loop().add_reader(self.uio, functools.partial(
            UioController._uio_callback, self))
        self.wait_events = []

    def __del__(self):
        asyncio.get_event_loop().remove_reader(self.uio)
        self.uio.close()

    def _uio_callback(self):
        self.uio.read(4)
        current_events = self.wait_events
        self.wait_events = []
        for e in current_events:
            e.set()

    def add_event(self, event, number):
        if not self.wait_events:
            self.uio.write(bytes([0, 0, 0, 1]))
        self.wait_events.append(event)


