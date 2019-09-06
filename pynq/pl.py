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
import warnings
from copy import deepcopy
from datetime import datetime
import struct
import numpy as np
from multiprocessing.connection import Listener
from multiprocessing.connection import Client
from .mmio import MMIO
from .ps import CPU_ARCH_IS_SUPPORTED, CPU_ARCH, ZYNQ_ARCH, ZU_ARCH
from .devicetree import DeviceTreeSegment
from .devicetree import get_dtbo_path
from .devicetree import get_dtbo_base_name

from .pl_server import HWH, TCL
from .pl_server import get_hwh_name, get_tcl_name
from .pl_server import Device

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


class PLMeta(type):
    """This method is the meta class for the PL.

    This is not a class for users. Hence there is no attribute or method
    exposed to users.

    We make no assumption of the overlay during boot, so most of the
    dictionaries are empty. Those dictionaries will get populated when
    users download an overlay onto the PL.

    Note
    ----
    If this metaclass is parsed on an unsupported architecture it will issue
    a warning and leave class variables undefined

    """

    @property
    def bitfile_name(cls):
        """The getter for the attribute `bitfile_name`.

        Returns
        -------
        str
            The absolute path of the bitstream currently on PL.

        """
        return Device.active_device.bitfile_name

    @property
    def timestamp(cls):
        """The getter for the attribute `timestamp`.

        Returns
        -------
        str
            Bitstream download timestamp.

        """
        return Device.active_device.timestamp

    @property
    def ip_dict(cls):
        """The getter for the attribute `ip_dict`.

        Returns
        -------
        dict
            The dictionary storing addressable IP instances; can be empty.

        """
        return Device.active_device.ip_dict

    @property
    def gpio_dict(cls):
        """The getter for the attribute `gpio_dict`.

        Returns
        -------
        dict
            The dictionary storing the PS GPIO pins.

        """
        return Device.active_device.gpio_dict

    @property
    def interrupt_controllers(cls):
        """The getter for the attribute `interrupt_controllers`.

        Returns
        -------
        dict
            The dictionary storing interrupt controller information.

        """
        return Device.active_device.interrupt_controllers

    @property
    def interrupt_pins(cls):
        """The getter for the attribute `interrupt_pins`.

        Returns
        -------
        dict
            The dictionary storing the interrupt endpoint information.

        """
        return Device.active_device.interrupt_pins

    @property
    def hierarchy_dict(cls):
        """The getter for the attribute `hierarchy_dict`

        Returns
        -------
        dict
            The dictionary containing the hierarchies in the design

        """
        return Device.active_device.hierarchy_dict

    @property
    def devicetree_dict(cls):
        """The getter for the attribute `devicetree_dict`

        Returns
        -------
        dict
            The dictionary containing the device tree blobs.

        """
        return Device.active_device.devicetree_dict

    @property
    def devicetree_dict(self):
        """The getter for the attribute `devicetree_dict`

        Returns
        -------
        dict
            The dictionary containing the device tree blobs.

        """
        return Device.active_device.devicetree_dict

    @property
    def mem_dict(self):
        """The getter for the attribute `mem_dict`

        Returns
        -------
        dict
            The dictionary containing the memories in the design.

        """
        return Device.active_device.mem_dict

    def shutdown(cls):
        """Shutdown the AXI connections to the PL in preparation for
        reconfiguration

        """
        Device.active_device.shutdown()

    def reset(cls, parser=None):
        """Reset all the dictionaries.

        This method must be called after a bitstream download.
        1. In case there is a `hwh` or `tcl` file, this method will reset
        the states of the IP, GPIO, and interrupt dictionaries .
        2. In case there is no `hwh` or `tcl` file, this method will simply
        clear the state information stored for all dictionaries.

        An existing parser given as the input can significantly reduce
        the reset time, since the PL can reset based on the
        information provided by the parser.

        Parameters
        ----------
        parser : TCL/HWH
            A parser object to speed up the reset process.

        """
        Device.active_device.reset(parser)

    def clear_dict(cls):
        """Clear all the dictionaries stored in PL.

        This method will clear all the related dictionaries, including IP
        dictionary, GPIO dictionary, etc.

        """
        Device.active_device.clear_dict()

    def clear_devicetree(cls):
        """Clear the device tree dictionary.

        This should be used when downloading the full bitstream, where all the
        dtbo are cleared from the system.

        """
        Device.active_device.clear_devicetree()

    def insert_device_tree(cls, abs_dtbo):
        """Insert device tree segment.

        For device tree segments associated with full / partial bitstreams,
        users can provide the relative or absolute paths of the dtbo files.

        Parameters
        ----------
        abs_dtbo : str
            The absolute path to the device tree segment.

        """
        Device.active_device.insert_device_tree(abs_dtbo)

    def remove_device_tree(cls, abs_dtbo):
        """Remove device tree segment for the overlay.

        Parameters
        ----------
        abs_dtbo : str
            The absolute path to the device tree segment.

        """
        Device.active_device.remove_device_tree(abs_dtbo)

    def load_ip_data(cls, ip_name, data, zero=False):
        """This method writes data to the addressable IP.

        Note
        ----
        The data is assumed to be in binary format (.bin). The data
        name will be stored as a state information in the IP dictionary.

        Parameters
        ----------
        ip_name : str
            The name of the addressable IP.
        data : str
            The absolute path of the data to be loaded.
        zero : bool
            Zero out the address of the IP not covered by data

        Returns
        -------
        None

        """
        Device.active_device.load_ip_data(ip_name, data, zero)

    def update_partial_region(cls, hier, parser):
        """Merge the parser information from partial region.

        Combine the currently PL information and the partial HWH/TCL file
        parsing results.

        Parameters
        ----------
        hier : str
            The name of the hierarchical block as the partial region.
        parser : TCL/HWH
            A parser object for the partial region.

        """
        Device.active_device.update_partial_region(hier, parser)


class PL(metaclass=PLMeta):
    """Serves as a singleton for `Overlay` and `Bitstream` classes.

    This class stores multiple dictionaries: IP dictionary, GPIO dictionary,
    interrupt controller dictionary, and interrupt pins dictionary.

    Attributes
    ----------
    bitfile_name : str
        The absolute path of the bitstream currently on PL.
    timestamp : str
        Bitstream download timestamp, using the following format:
        year, month, day, hour, minute, second, microsecond.
    ip_dict : dict
        All the addressable IPs from PS7. Key is the name of the IP; value is
        a dictionary mapping the physical address, address range, IP type,
        configuration dictionary, the state associated with that IP, any
        interrupts and GPIO pins attached to the IP and the full path to the
        IP in the block design:
        {str: {'phys_addr' : int, 'addr_range' : int,\
               'type' : str, 'config' : dict, 'state' : str,\
               'interrupts' : dict, 'gpio' : dict, 'fullpath' : str}}.
    gpio_dict : dict
        All the GPIO pins controlled by PS7. Key is the name of the GPIO pin;
        value is a dictionary mapping user index (starting from 0),
        the state associated with that GPIO pin and the pins in block diagram
        attached to the GPIO:
        {str: {'index' : int, 'state' : str, 'pins' : [str]}}.
    interrupt_controllers : dict
        All AXI interrupt controllers in the system attached to
        a PS7 interrupt line. Key is the name of the controller;
        value is a dictionary mapping parent interrupt controller and the
        line index of this interrupt:
        {str: {'parent': str, 'index' : int}}.
        The PS7 is the root of the hierarchy and is unnamed.
    interrupt_pins : dict
        All pins in the design attached to an interrupt controller.
        Key is the name of the pin; value is a dictionary
        mapping the interrupt controller and the line index used:
        {str: {'controller' : str, 'index' : int}}.
    hierarchy_dict : dict
        All of the hierarchies in the block design containing addressable IP.
        The keys are the hiearachies and the values are dictionaries
        containing the IP and sub-hierarchies contained in the hierarchy and
        and GPIO and interrupts attached to the hierarchy. The keys in
        dictionaries are relative to the hierarchy and the ip dict only
        contains immediately contained IP - not those in sub-hierarchies.
        {str: {'ip': dict, 'hierarchies': dict, 'interrupts': dict,\
               'gpio': dict, 'fullpath': str}}

    """
    def __init__(self):
        """Return a new PL object.

        This class requires a root permission.

        """
        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('Root permissions required.')
