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
import functools
import os

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


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
