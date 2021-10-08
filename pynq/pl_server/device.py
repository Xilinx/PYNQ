#   Copyright (c) 2021, Xilinx, Inc.
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

__author__ = "Peter Ogden"
__copyright__ = "Copyright 2021, Xilinx"
__email__ = "pynq_support@xilinx.com"

import atexit
import os
import warnings
from .server import DeviceClient, DeviceServer


class DeviceMeta(type):
    """Metaclass for all types of Device

    It is responsible for enumerating the devices in the system and
    selecting a `default_device` that is used by applications that
    are oblivious to multiple-device scenarios

    The main implementation is the `Device` class which should be subclassed
    for each type of hardware that is supported. Each subclass should have
    a `_probe_` function which returns an array of `Device` objects and
    a `_probe_priority_` constant which is used to determine the
    default device.

    """
    _subclasses = {}

    def __init__(cls, name, bases, attrs):
        if '_probe_' in attrs:
            priority = attrs['_probe_priority_']
            if (priority in DeviceMeta._subclasses and
                    DeviceMeta._subclasses[priority].__name__ != name):
                raise RuntimeError(
                    "Multiple Device subclasses with same priority")
            DeviceMeta._subclasses[priority] = cls
        super().__init__(name, bases, attrs)

    @property
    def devices(cls):
        """All devices found in the system

        An array of `Device` objects. Probing is done when this
        property is first accessed

        """
        if not hasattr(cls, '_devices'):
            cls._devices = []
            for key in sorted(DeviceMeta._subclasses.keys()):
                cls._devices.extend(DeviceMeta._subclasses[key]._probe_())
            if len(cls._devices) == 0 and 'XILINX_XRT' not in os.environ:
                warnings.warn(
                    'No devices found, is the XRT environment sourced?',
                    UserWarning)
        return cls._devices

    @property
    def active_device(cls):
        """The device used by PYNQ if `None` used for a device parameter

        This defaults to the device with the lowest priority and index but
        can be overridden to globally change the default.

        """
        if not hasattr(cls, '_active_device'):
            if len(cls.devices) == 0:
                raise RuntimeError("No Devices Found")
            cls._active_device = cls.devices[0]
        return cls._active_device

    @active_device.setter
    def active_device(cls, value):
        cls._active_device = value


class Device(metaclass=DeviceMeta):
    """Construct a new Device Instance

    This should be called by subclasses providing a globally unique
    identifier for the device.

    Parameters
    ----------
    tag: str
        The unique identifier associated with the device
    server_type: str
        Indicates the type of PL server to use. Its value can only be one
        of the following ["global"|"local"|"fallback"], where "global" will
        use a global PL server, "local" will spawn a local PL server (i.e.
        only associated to the current Python process), and "fallback" will
        attempt to use a global PL server and fallback to local in case it
        fails, warning the user. Default is "fallback".
    warn: bool
        Warn the user when falling back to local PL server.
        Default is False
    """

    start_global = False
    """
        Class attribute that can override 'server_type' if set to True
        when 'global' or 'fallback' are used
    """
    def __init__(self, tag, server_type="fallback", warn=False):
        # Args validation
        if type(tag) is not str:
            raise ValueError("Argument 'tag' must be a string")
        if server_type not in ["global", "local", "fallback"]:
            raise ValueError("Argument 'server_type' can only be set to "
                             "'global', 'local' or 'fallback'")

        if server_type in ["global", "fallback"]:
            self._server = None
            if not DeviceClient.accessible(tag):
                if self.start_global:
                    # global PL server will be started later
                    server_type = None
                elif server_type == "global":
                    raise ConnectionError("Could not connect to global PL "
                                          "server")
                elif warn:
                    warnings.warn("Could not connect to global PL server, "
                                  "falling back to local PL server", Warning)
            else:
                server_type = None  # avoid fallback to local when successful
        if server_type in ["local", "fallback"]:
            tag = "{}.{}".format(tag, os.getpid())
            if not DeviceClient.accessible(tag):
                self._server = DeviceServer(tag)
                self._server.start()
        self.tag = tag
        self._client = DeviceClient(tag)
        atexit.register(self.close)

    def close(self):
        if self._server:
            self._server.stop()
            self._server = None

    @property
    def ip_dict(self):
        """The getter for the attribute `ip_dict`.

        Returns
        -------
        dict
            The dictionary storing addressable IP instances; can be empty.

        """
        return self._client.ip_dict

    @property
    def gpio_dict(self):
        """The getter for the attribute `gpio_dict`.

        Returns
        -------
        dict
            The dictionary storing the PS GPIO pins.

        """
        return self._client.gpio_dict

    @property
    def interrupt_pins(self):
        """The getter for the attribute `interrupt_pins`.

        Returns
        -------
        dict
            The dictionary storing the interrupt endpoint information.

        """
        return self._client.interrupt_pins

    @property
    def interrupt_controllers(self):
        """The getter for the attribute `interrupt_controllers`.

        Returns
        -------
        dict
            The dictionary storing interrupt controller information.

        """
        return self._client.interrupt_controllers

    @property
    def bitfile_name(self):
        """The getter for the attribute `bitfile_name`.

        Returns
        -------
        str
            The absolute path of the bitstream currently on PL.

        """
        return self._client.bitfile_name

    @property
    def hierarchy_dict(self):
        """The getter for the attribute `hierarchy_dict`

        Returns
        -------
        dict
            The dictionary containing the hierarchies in the design

        """
        return self._client.hierarchy_dict

    @property
    def timestamp(self):
        """The getter for the attribute `timestamp`.

        Returns
        -------
        str
            Bitstream download timestamp.

        """
        return self._client.timestamp

    @property
    def devicetree_dict(self):
        """The getter for the attribute `devicetree_dict`

        Returns
        -------
        dict
            The dictionary containing the device tree blobs.

        """
        return self._client.devicetree_dict

    @property
    def mem_dict(self):
        """The getter for the attribute `mem_dict`

        Returns
        -------
        dict
            The dictionary containing the memory spaces in the design

        """
        return self._client.mem_dict

    def allocate(self, shape, dtype, **kwargs):
        """Allocate an array on the device

        Returns a buffer on memory accessible to the device

        Parameters
        ----------
        shape : tuple(int)
            The shape of the array
        dtype : np.dtype
            The type of the elements of the array

        Returns
        ------
        PynqBuffer
            The buffer shared between the host and the device

        """
        return self.default_memory.allocate(shape, dtype, **kwargs)

    def reset(self, parser=None, timestamp=None, bitfile_name=None):
        """Reset all the dictionaries.

        This method must be called after a bitstream download.
        1. In case there is a `hwh` file, this method will reset
        the states of the IP, GPIO, and interrupt dictionaries .
        2. In case there is no `hwh` file, this method will simply
        clear the state information stored for all dictionaries.

        An existing parser given as the input can significantly reduce
        the reset time, since the PL can reset based on the
        information provided by the parser.

        Parameters
        ----------
        parser : HWH
            A parser object to speed up the reset process.
        timestamp : str
            The timestamp to embed in the reset
        bitfile_name : str
            The bitfile being loaded as part of the reset

        """
        self._client.reset(parser, timestamp, bitfile_name)

    def clear_dict(self):
        """Clear all the dictionaries stored in PL.

        This method will clear all the related dictionaries, including IP
        dictionary, GPIO dictionary, etc.

        """
        self._client.clear_dict()

    def load_ip_data(self, ip_name, data, zero=False):
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
        from pynq import MMIO
        self._client.load_ip_data(ip_name, data)
        ip_dict = self.ip_dict
        mem_dict = self.mem_dict
        if ip_name in ip_dict:
            address = ip_dict[ip_name]['addr_range']
            target_size = ip_dict[ip_name]['addr_range']
        elif ip_name in mem_dict:
            address = mem_dict[ip_name]['base_address']
            target_size = mem_dict[ip_name]['size']
        with open(data, 'rb') as bin_file:
            size = os.fstat(bin_file.fileno()).st_size
            if size > target_size:
                raise RuntimeError("Binary file too big for IP")
            mmio = MMIO(address, target_size, device=self)
            buf = bin_file.read(size)
            if len(buf) % 4 != 0:
                padding = 4 - len(buf) % 4
                buf += b"\x00" * padding
                size += padding
            mmio.write(0, buf)
            if zero and size < target_size:
                mmio.write(size, b'\x00' * (target_size - size))

    def update_partial_region(self, hier, parser):
        """Merge the parser information from partial region.

        Combine the currently PL information and the partial HWH file
        parsing results.

        Parameters
        ----------
        hier : str
            The name of the hierarchical block as the partial region.
        parser : HWH
            A parser object for the partial region.

        """
        self._client.update_partial_region(hier, parser)

    def clear_devicetree(self):
        """Clear the device tree dictionary.

        This should be used when downloading the full bitstream, where all the
        dtbo are cleared from the system.

        """
        self._client.clear_devicetree()

    def insert_device_tree(self, abs_dtbo):
        """Insert device tree segment.

        For device tree segments associated with full / partial bitstreams,
        users can provide the relative or absolute paths of the dtbo files.

        Parameters
        ----------
        abs_dtbo : str
            The absolute path to the device tree segment.

        """
        self._client.insert_device_tree(abs_dtbo)

    def remove_device_tree(self, abs_dtbo):
        """Remove device tree segment for the overlay.

        Parameters
        ----------
        abs_dtbo : str
            The absolute path to the device tree segment.

        """
        self._client.remove_device_tree(abs_dtbo)

    def shutdown(self):
        """Shutdown the AXI connections to the PL in preparation for
        reconfiguration

        """
        from pynq import MMIO
        ip = self.ip_dict
        for name, details in ip.items():
            if details['type'] in \
                    ['xilinx.com:ip:pr_axi_shutdown_manager:1.0',
                     'xilinx.com:ip:dfx_axi_shutdown_manager:1.0']:
                mmio = MMIO(details['phys_addr'], device=self)
                # Request shutdown
                mmio.write(0x0, 0x1)
                i = 0
                while mmio.read(0x0) != 0x0F and i < 16000:
                    i += 1
                if i >= 16000:
                    warnings.warn("Timeout for shutdown manager. It's likely "
                                  "the configured bitstream and metadata "
                                  "don't match.")

    def post_download(self, bitstream, parser):
        if not bitstream.partial:
            import datetime
            t = datetime.datetime.now()
            bitstream.timestamp = "{}/{}/{} {}:{}:{} +{}".format(
                t.year, t.month, t.day,
                t.hour, t.minute, t.second, t.microsecond)
            self.reset(parser, bitstream.timestamp, bitstream.bitfile_name)

    def has_capability(self, cap):
        """Test if the device as a desired capability

        Parameters
        ----------
        cap : str
            The desired capability

        Returns
        -------
        bool
            True if the devices support cap

        """
        if not hasattr(self, 'capabilities'):
            return False
        return cap in self.capabilities and self.capabilities[cap]

    def get_bitfile_metadata(self, bitfile_name):
        return None
