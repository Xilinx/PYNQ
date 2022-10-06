#   Copyright (c) 2021, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import os
import pickle
import warnings
from copy import deepcopy

from pynq.devicetree import DeviceTreeSegment, get_dtbo_base_name

from .hwh_parser import HWH, get_hwh_name


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
        if "_probe_" in attrs:
            priority = attrs["_probe_priority_"]
            if (
                priority in DeviceMeta._subclasses
                and DeviceMeta._subclasses[priority].__name__ != name
            ):
                raise RuntimeError("Multiple Device subclasses with same priority")
            DeviceMeta._subclasses[priority] = cls
        super().__init__(name, bases, attrs)

    @property
    def devices(cls):
        """All devices found in the system

        An array of `Device` objects. Probing is done when this
        property is first accessed

        """
        if not hasattr(cls, "_devices"):
            cls._devices = []
            for key in sorted(DeviceMeta._subclasses.keys()):
                cls._devices.extend(DeviceMeta._subclasses[key]._probe_())
            if len(cls._devices) == 0 and "XILINX_XRT" not in os.environ:
                warnings.warn(
                    "No devices found, is the XRT environment sourced?", UserWarning
                )
        return cls._devices

    @property
    def active_device(cls):
        """The device used by PYNQ if `None` used for a device parameter

        This defaults to the device with the lowest priority and index but
        can be overridden to globally change the default.

        """
        if not hasattr(cls, "_active_device"):
            if len(cls.devices) == 0:
                raise RuntimeError("No Devices Found")
            cls._active_device = cls.devices[0]
        return cls._active_device

    @active_device.setter
    def active_device(cls, value):
        cls._active_device = value

def clear_state(dict_in):
    """Clear the state information for a given dictionary.
    Parameters
    ----------
    dict_in : obj
        Input dictionary to be cleared.
    """
    if not isinstance(dict_in,dict):
        return dict_in

    for k,v in dict_in.items():
        if isinstance(v,dict):
            dict_in[k] =  clear_state(v)
        if k == 'state':
            dict_in[k] = None
    return dict_in


class Device(metaclass=DeviceMeta):
    """Construct a new Device Instance

    This should be called by subclasses providing a globally unique
    identifier for the device.

    Parameters
    ----------
    tag: str
        The unique identifier associated with the device
    """

    def __init__(self, tag, warn=False):
        # Args validation
        if type(tag) is not str:
            raise ValueError("Argument 'tag' must be a string")
        self.tag = tag
        self.parser = None

    def set_bitfile_name(self, bitfile_name: str) -> None:
        self.bitfile_name = bitfile_name
        self.parser = self.get_bitfile_metadata(self.bitfile_name)
        self.mem_dict = self.parser.mem_dict
        self.ip_dict = self.parser.ip_dict
        self.gpio_dict = self.parser.gpio_dict
        self.interrupt_pins = self.parser.interrupt_pins
        self.interrupt_controllers = self.parser.interrupt_controllers
        self.hierarchy_dict = self.parser.hierarchy_dict
        self.systemgraph = self.parser.systemgraph

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
        if parser is not None:
            self.ip_dict = parser.ip_dict
            self.gpio_dict = parser.gpio_dict
            self.interrupt_controllers = parser.interrupt_controllers
            self.interrupt_pins = parser.interrupt_pins
            self.hierarchy_dict = parser.hierarchy_dict
            self.mem_dict = parser.mem_dict
        else:
            hwh_name = get_hwh_name(self._bitfile_name)
            if os.path.isfile(hwh_name):
                self.ip_dict = clear_state(self.ip_dict)
                self.gpio_dict = clear_state(self.gpio_dict)
                self.hierarchy_dict = clear_state(self.hierarchy_dict)
            else:
                self.clear_dict()
        if timestamp is not None:
            self.timestamp = timestamp
        if bitfile_name is not None:
            self.bitfile_name = bitfile_name

    def clear_dict(self):
        """Clear all the dictionaries stored in PL.

        This method will clear all the related dictionaries, including IP
        dictionary, GPIO dictionary, etc.

        """
        self.ip_dict = {}
        self.gpio_dict = {}
        self.interrupt_controllers = {}
        self.interrupt_pins = {}
        self.hierarchy_dict = {}
        self.mem_dict = {}

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

        if ip_name in self.ip_dict:
            self.ip_dict[ip_name]["state"] = data
        elif ip_name in self.mem_dict:
            self.mem_dict[ip_name]["state"] = data

        ip_dict = self.ip_dict
        mem_dict = self.mem_dict
        if ip_name in ip_dict:
            address = ip_dict[ip_name]["addr_range"]
            target_size = ip_dict[ip_name]["addr_range"]
        elif ip_name in mem_dict:
            address = mem_dict[ip_name]["base_address"]
            target_size = mem_dict[ip_name]["size"]
        with open(data, "rb") as bin_file:
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
                mmio.write(size, b"\x00" * (target_size - size))

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
        self._update_pr_ip(parser, hier)
        self._update_pr_gpio(parser)
        self._update_pr_intr_pins(parser)
        self._update_pr_hier(hier)

    def _update_pr_ip(self, parser, hier):
        merged_ip_dict = deepcopy(self.ip_dict)
        if type(parser) is HWH:
            for k in merged_ip_dict.copy():
                if k.startswith(hier):
                    merged_ip_dict.pop(k)
            for k, v in parser.ip_dict.items():
                merged_ip_dict[v['fullpath']] = v
        else:
            raise ValueError("Cannot find HWH PR region parser.")
        self.ip_dict = merged_ip_dict

    def _update_pr_gpio(self, parser):
        new_gpio_dict = dict()
        for k, v in self.gpio_dict.items():
            for pin in v["pins"]:
                if pin in parser.pins:
                    v |= parser.nets[parser.pins[pin]]
                new_gpio_dict[k] = v
        self.gpio_dict = new_gpio_dict

    def _update_pr_intr_pins(self, parser):
        new_interrupt_pins = dict()
        for k, v in self.interrupt_pins.items():
            if k in parser.pins:
                net_set = parser.nets[parser.pins[k]]
                hier_map = {i.count("/"): i for i in net_set}
                hier_map = sorted(hier_map.items(), reverse=True)
                fullpath = hier_map[0][-1]
                new_interrupt_pins[fullpath] = deepcopy(v)
                new_interrupt_pins[fullpath]["fullpath"] = fullpath
            else:
                new_interrupt_pins[k] = v
        self._interrupt_pins = new_interrupt_pins

    def _update_pr_hier(self, hier):
        self.hierarchy_dict[hier] = {
            "ip": dict(),
            "hierarchies": dict(),
            "interrupts": dict(),
            "gpio": dict(),
            "fullpath": hier,
            "memories": dict(),
        }
        for name, val in self.ip_dict.items():
            hier, _, ip = name.rpartition("/")
            if hier:
                self.hierarchy_dict[hier]["ip"][ip] = val
                self.hierarchy_dict[hier]["ip"][ip] = val
        for name, val in self.hierarchy_dict.items():
            hier, _, subhier = name.rpartition("/")
            if hier:
                self.hierarchy_dict[hier]["hierarchies"][subhier] = val
        for interrupt, val in self._interrupt_pins.items():
            block, _, pin = interrupt.rpartition("/")
            if block in self.ip_dict:
                self.ip_dict[block]["interrupts"][pin] = val
            if block in self.hierarchy_dict:
                self.hierarchy_dict[block]["interrupts"][pin] = val
        for gpio in self.gpio_dict.values():
            for connection in gpio["pins"]:
                ip, _, pin = connection.rpartition("/")
                if ip in self.ip_dict:
                    self.ip_dict[ip]["gpio"][pin] = gpio
                elif ip in self.hierarchy_dict:
                    self.hierarchy_dict[ip]["gpio"][pin] = gpio

    def clear_devicetree(self):
        """Clear the device tree dictionary.

        This should be used when downloading the full bitstream, where all the
        dtbo are cleared from the system.

        """
        for i in self.devicetree_dict:
            self.devicetree_dict[i].remove()

    def insert_device_tree(self, abs_dtbo):
        """Insert device tree segment.

        For device tree segments associated with full / partial bitstreams,
        users can provide the relative or absolute paths of the dtbo files.

        Parameters
        ----------
        abs_dtbo : str
            The absolute path to the device tree segment.

        """
        dtbo_base_name = get_dtbo_base_name(abs_dtbo)
        if not hasattr(self, "devicetree_dict"):
            self.devicetree_dict = {}
        self.devicetree_dict[dtbo_base_name] = DeviceTreeSegment(abs_dtbo)
        self.devicetree_dict[dtbo_base_name].remove()
        self.devicetree_dict[dtbo_base_name].insert()

    def remove_device_tree(self, abs_dtbo):
        """Remove device tree segment for the overlay.

        Parameters
        ----------
        abs_dtbo : str
            The absolute path to the device tree segment.

        """
        dtbo_base_name = get_dtbo_base_name(abs_dtbo)
        self.devicetree_dict[dtbo_base_name].remove()
        del self.devicetree_dict[dtbo_base_name]

    def shutdown(self):
        """Shutdown the AXI connections to the PL in preparation for
        reconfiguration

        """
        from ..mmio import MMIO
        from .global_state import (
            GlobalState,
            global_state_file_exists,
            load_global_state,
            initial_global_state_file_boot_check
        )

        initial_global_state_file_boot_check()

        if global_state_file_exists():
            gs = load_global_state()
            for sd_ip in gs.shutdown_ips.values():
                mmio = MMIO(sd_ip.base_addr, device=self)
                # Request shutdown
                mmio.write(0x0, 0x1)
                i = 0
                while mmio.read(0x0) != 0x0F and i < 16000:
                    i += 1
                if i >= 16000:
                    warnings.warn(
                        "Timeout for shutdown manager. It's likely "
                        "the configured bitstream and metadata "
                        "don't match."
                    )

    def post_download(self, bitstream, parser, name: str = "Unknown"):
        if not bitstream.partial:
            import datetime

            t = datetime.datetime.now()
            bitstream.timestamp = "{}/{}/{} {}:{}:{} +{}".format(
                t.year, t.month, t.day, t.hour, t.minute, t.second, t.microsecond
            )
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
        if not hasattr(self, "capabilities"):
            return False
        return cap in self.capabilities and self.capabilities[cap]

    def get_bitfile_metadata(self, bitfile_name):
        return None

    def close(self):
        """ Deprecated """
        warnings.warn("PL Server has been deprecated -- this call"
                "will be removed in a future release")
        pass
