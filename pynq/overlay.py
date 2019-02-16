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

import collections
import importlib.util
import os
import re
import warnings
from copy import deepcopy
from .mmio import MMIO
from .ps import Clocks, CPU_ARCH_IS_SUPPORTED, CPU_ARCH
from .pl import PL
from .pl import Bitstream
from .pl import TCL
from .pl import HWH
from .pl import get_tcl_name
from .pl import get_hwh_name
from .interrupt import Interrupt
from .gpio import GPIO
from .registers import RegisterMap


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


def _assign_drivers(description, ignore_version):
    """Assigns a driver for each IP and hierarchy in the description.

    """
    for name, details in description['hierarchies'].items():
        _assign_drivers(details, ignore_version)
        details['driver'] = DocumentHierarchy
        for hip in _hierarchy_drivers:
            if hip.checkhierarchy(details):
                details['driver'] = hip
                break

    for name, details in description['ip'].items():
        ip_type = details['type']
        if ip_type in _ip_drivers:
            details['driver'] = _ip_drivers[ip_type]
        else:
            no_version_ip = ip_type.rpartition(':')[0]
            if no_version_ip in _ip_drivers:
                if ignore_version:
                    details['driver'] = _ip_drivers[no_version_ip]
                else:
                    other_versions = [v for v in _ip_drivers.keys()
                                      if v.startswith(no_version_ip + ":")]
                    message = (
                       "IP {0} is of type {1} and driver found for [{2}]. " +
                       "Use ignore_version=True to use this driver."
                       ).format(details['fullpath'],
                                details['type'],
                                ", ".join(other_versions))
                    warnings.warn(message, UserWarning)
                    details['driver'] = DefaultIP
            else:
                details['driver'] = DefaultIP


def _complete_description(ip_dict, hierarchy_dict, ignore_version):
    """Returns a complete hierarchical description of an overlay based
    on the three dictionaries parsed from the TCL.

    """
    starting_dict = dict()
    starting_dict['ip'] = {k: v for k, v in ip_dict.items()}
    starting_dict['hierarchies'] = {k: v for k, v in hierarchy_dict.items()}
    starting_dict['interrupts'] = dict()
    starting_dict['gpio'] = dict()
    _assign_drivers(starting_dict, ignore_version)
    return starting_dict


_class_aliases = {
    'pynq.overlay.DocumentOverlay': 'pynq.overlay.DefaultOverlay',
    'pynq.overlay.DocumentHierarchy': 'pynq.overlay.DefaultHierarchy'
}


def _classname(class_):
    """Returns the full name for a class. Has option for overriding
    some class names to hide internal details. The overrides are
    stored in the `_class_aliases` dictionaries.

    """
    rawname = "{}.{}".format(class_.__module__, class_.__name__)

    if rawname in _class_aliases:
        return _class_aliases[rawname]
    else:
        return rawname


def _build_docstring(description, name, type_):
    """Helper function to build a documentation string for
    a hierarchical description.

    Parameters
    ----------
    description : dict
        The description to document.
    name : str
        The name of the object - inserted into the doc string
    type_ : str
        The type of the object - generally 'overlay' or 'hierarchy'

    Returns
    -------
    str : The generated documentation string

    """
    lines = list()
    lines.append("Default documentation for {} {}. The following"
                 .format(type_, name))
    lines.append("attributes are available on this {}:".format(type_))
    lines.append("")

    lines.append("IP Blocks")
    lines.append("----------")
    if description['ip']:
        for ip, details in description['ip'].items():
            lines.append("{0: <20} : {1}"
                         .format(ip, _classname(details['driver'])))
    else:
        lines.append("None")
    lines.append("")

    lines.append("Hierarchies")
    lines.append("-----------")
    if description['hierarchies']:
        for hierarchy, details in description['hierarchies'].items():
            lines.append("{0: <20} : {1}"
                         .format(hierarchy, _classname(details['driver'])))
    else:
        lines.append("None")
    lines.append("")

    lines.append("Interrupts")
    lines.append("----------")
    if description['interrupts']:
        for interrupt in description['interrupts'].keys():
            lines.append("{0: <20} : pynq.interrupt.Interrupt"
                         .format(interrupt))
    else:
        lines.append("None")
    lines.append("")

    lines.append("GPIO Outputs")
    lines.append("------------")
    if description['gpio']:
        for gpio in description['gpio'].keys():
            lines.append("{0: <20} : pynq.gpio.GPIO".format(gpio))
    else:
        lines.append("None")
    lines.append("")
    return '\n    '.join(lines)


class Overlay(Bitstream):
    """This class keeps track of a single bitstream's state and contents.

    The overlay class holds the state of the bitstream and enables run-time
    protection of bindlings.

    Our definition of overlay is: "post-bitstream configurable design".
    Hence, this class must expose configurability through content discovery
    and runtime protection.

    The overlay class exposes the IP and hierarchies as attributes in the
    overlay. If no other drivers are available the `DefaultIP` is constructed
    for IP cores at top level and `DefaultHierarchy` for any hierarchies that
    contain addressable IP. Custom drivers can be bound to IP and hierarchies
    by subclassing `DefaultIP` and `DefaultHierarchy`. See the help entries
    for those class for more details.

    This class stores four dictionaries: IP, GPIO, interrupt controller
    and interrupt pin dictionaries.

    Each entry of the IP dictionary is a mapping:
    'name' -> {phys_addr, addr_range, type, config, state}, where
    name (str) is the key of the entry.
    phys_addr (int) is the physical address of the IP.
    addr_range (int) is the address range of the IP.
    type (str) is the type of the IP.
    config (dict) is a dictionary of the configuration parameters.
    state (str) is the state information about the IP.

    Each entry of the GPIO dictionary is a mapping:
    'name' -> {pin, state}, where
    name (str) is the key of the entry.
    pin (int) is the user index of the GPIO, starting from 0.
    state (str) is the state information about the GPIO.

    Each entry in the interrupt controller dictionary is a mapping:
    'name' -> {parent, index}, where
    name (str) is the name of the interrupt controller.
    parent (str) is the name of the parent controller or '' if attached
    directly to the PS.
    index (int) is the index of the interrupt attached to.

    Each entry in the interrupt pin dictionary is a mapping:
    'name' -> {controller, index}, where
    name (str) is the name of the pin.
    controller (str) is the name of the interrupt controller.
    index (int) is the line index.

    Attributes
    ----------
    bitfile_name : str
        The absolute path of the bitstream.
    bitstream : Bitstream
        The corresponding bitstream object.
    ip_dict : dict
        All the addressable IPs from PS. Key is the name of the IP; value is
        a dictionary mapping the physical address, address range, IP type,
        parameters, registers, and the state associated with that IP:
        {str: {'phys_addr' : int, 'addr_range' : int, \
               'type' : str, 'parameters' : dict, 'registers': dict, \
               'state' : str}}.
    gpio_dict : dict
        All the GPIO pins controlled by PS. Key is the name of the GPIO pin;
        value is a dictionary mapping user index (starting from 0),
        and the state associated with that GPIO pin:
        {str: {'index' : int, 'state' : str}}.
    interrupt_controllers : dict
        All AXI interrupt controllers in the system attached to
        a PS interrupt line. Key is the name of the controller;
        value is a dictionary mapping parent interrupt controller and the
        line index of this interrupt:
        {str: {'parent': str, 'index' : int}}.
        The PS is the root of the hierarchy and is unnamed.
    interrupt_pins : dict
        All pins in the design attached to an interrupt controller.
        Key is the name of the pin; value is a dictionary
        mapping the interrupt controller and the line index used:
        {str: {'controller' : str, 'index' : int}}.

    """
    def __init__(self, bitfile_name, download=True, ignore_version=False):
        """Return a new Overlay object.

        An overlay instantiates a bitstream object as a member initially.

        Parameters
        ----------
        bitfile_name : str
            The bitstream name or absolute path as a string.
        download : bool
            Whether the overlay should be downloaded.
        ignore_version : bool
            Indicate whether or not to ignore the driver versions.

        Note
        ----
        This class requires a Vivado TCL file to be next to bitstream file
        with same name (e.g. `base.bit` and `base.tcl`).

        """
        super().__init__(bitfile_name, partial=False)

        hwh_path = get_hwh_name(self.bitfile_name)
        tcl_path = get_tcl_name(self.bitfile_name)
        if os.path.exists(hwh_path):
            self.parser = HWH(hwh_path)
        elif os.path.exists(tcl_path):
            self.parser = TCL(tcl_path)
            message = "Users will not get PARAMETERS / REGISTERS information " \
                      "through TCL files. HWH file is recommended."
            warnings.warn(message, UserWarning)
        else:
            raise ValueError("Cannot find HWH or TCL file for {}.".format(
                self.bitfile_name))

        self.ip_dict = self.gpio_dict = self.interrupt_controllers = \
            self.interrupt_pins = self.hierarchy_dict = dict()
        self._deepcopy_dict_from(self.parser)
        self.clock_dict = self.parser.clock_dict
        self.pr_region = ''
        self.ignore_version = ignore_version
        description = _complete_description(
            self.ip_dict, self.hierarchy_dict, self.ignore_version)
        self._ip_map = _IPMap(description)

        if download:
            self.download()

        self.__doc__ = _build_docstring(self._ip_map._description,
                                        bitfile_name,
                                        "overlay")

    def __getattr__(self, key):
        """Overload of __getattr__ to return a driver for an IP or
        hierarchy. Throws an `RuntimeError` if the overlay is not loaded.

        """
        if self.is_loaded():
            return getattr(self._ip_map, key)
        else:
            raise RuntimeError("Overlay not currently loaded")

    def _deepcopy_dict_from(self, source):
        self.ip_dict = deepcopy(source.ip_dict)
        self.gpio_dict = deepcopy(source.gpio_dict)
        self.interrupt_controllers = deepcopy(source.interrupt_controllers)
        self.interrupt_pins = deepcopy(source.interrupt_pins)
        self.hierarchy_dict = deepcopy(source.hierarchy_dict)

    def set_partial_region(self, pr_region):
        """Set partial reconfiguration region for the overlay.

        Parameters
        ----------
        pr_region : str
            The name of the hierarchical block corresponding to the PR region.

        """
        self.pr_region = pr_region

    def download(self, partial_bit=None):
        """The method to download a bitstream onto PL.

        After the bitstream has been downloaded, the "timestamp" in PL will be
        updated. In addition, all the dictionaries on PL will
        be reset automatically.

        If no bit file name is given, it is assuming
        a full bitstream will be downloaded; otherwise a partial bitstream
        needs to be specified as the input argument.

        Also, for partial bitstream, the corresponding parser will only be
        added once the `download()` method of the hierarchical block is called.

        Parameters
        ----------
        partial_bit : str
            The name of the partial bitstream.

        """
        if not partial_bit:
            for i in self.clock_dict:
                enable = self.clock_dict[i]['enable']
                div0 = self.clock_dict[i]['divisor0']
                div1 = self.clock_dict[i]['divisor1']
                if enable:
                    Clocks.set_pl_clk(i, div0, div1)
                else:
                    Clocks.set_pl_clk(i)

            super().download()
            PL.reset(self.parser)
        else:
            if not self.pr_region:
                raise ValueError(
                    "Partial region must be set before reconfiguration.")
            PL.reset(self.parser)
            pr_block = self.__getattr__(self.pr_region)
            pr_block.download(partial_bit)
            pr_parser = pr_block.parsers[partial_bit]
            PL.update_partial_region(self.pr_region, pr_parser)
            self._deepcopy_dict_from(PL)
            description = _complete_description(
                self.ip_dict, self.hierarchy_dict, self.ignore_version)
            self._ip_map = _IPMap(description)

    def is_loaded(self):
        """This method checks whether a bitstream is loaded.

        This method returns true if the loaded PL bitstream is same
        as this Overlay's member bitstream.

        Returns
        -------
        bool
            True if bitstream is loaded.

        """
        PL.client_request()
        PL.server_update()
        if not self.timestamp == '':
            return self.timestamp == PL._timestamp
        else:
            return self.bitfile_name == PL._bitfile_name

    def reset(self):
        """This function resets all the dictionaries kept in the overlay.

        This function should be used with caution. In most cases, only those
        dictionaries keeping track of states need to be updated.

        Returns
        -------
        None

        """
        self.ip_dict = self.parser.ip_dict
        self.gpio_dict = self.parser.gpio_dict
        self.interrupt_controllers = self.parser.interrupt_controllers
        self.interrupt_pins = self.parser.interrupt_pins
        if self.is_loaded():
            PL.reset(self.parser)

    def load_ip_data(self, ip_name, data):
        """This method loads the data to the addressable IP.

        Calls the method in the super class to load the data. This method can
        be used to program the IP. For example, users can use this method to
        load the program to the Microblaze processors on PL.

        Note
        ----
        The data is assumed to be in binary format (.bin). The data name will
        be stored as a state information in the IP dictionary.

        Parameters
        ----------
        ip_name : str
            The name of the addressable IP.
        data : str
            The absolute path of the data to be loaded.

        Returns
        -------
        None

        """
        PL.load_ip_data(ip_name, data)
        self.ip_dict[ip_name]['state'] = data

    def __dir__(self):
        return sorted(set(super().__dir__() +
                          list(self.__dict__.keys()) +
                               self._ip_map._keys()))


_ip_drivers = dict()
_hierarchy_drivers = collections.deque()


class RegisterIP(type):
    """Meta class that binds all registers all subclasses as IP drivers

    The `bindto` attribute of subclasses should be an array of strings
    containing the VLNV of the IP the driver should bind to.

    """
    def __init__(cls, name, bases, attrs):
        if 'bindto' in attrs:
            for vlnv in cls.bindto:
                _ip_drivers[vlnv] = cls
                _ip_drivers[vlnv.rpartition(':')[0]] = cls
        super().__init__(name, bases, attrs)


class DefaultIP(metaclass=RegisterIP):
    """Driver for an IP without a more specific driver

    This driver wraps an MMIO device and provides a base class
    for more specific drivers written later. It also provides
    access to GPIO outputs and interrupts inputs via attributes. More specific
    drivers should inherit from `DefaultIP` and include a
    `bindto` entry containing all of the IP that the driver
    should bind to. Subclasses meeting these requirements will
    automatically be registered.

    Attributes
    ----------
    mmio : pynq.MMIO
        Underlying MMIO driver for the device
    _interrupts : dict
        Subset of the PL.interrupt_pins related to this IP
    _gpio : dict
        Subset of the PL.gpio_dict related to this IP

    """

    def __init__(self, description):
        self.mmio = MMIO(description['phys_addr'], description['addr_range'])
        if 'interrupts' in description:
            self._interrupts = description['interrupts']
        else:
            self._interrupts = {}
        if 'gpio' in description:
            self._gpio = description['gpio']
        else:
            self._gpio = {}
        for interrupt, details in self._interrupts.items():
            setattr(self, interrupt, Interrupt(details['fullpath']))
        for gpio, entry in self._gpio.items():
            gpio_number = GPIO.get_gpio_pin(entry['index'])
            setattr(self, gpio, GPIO(gpio_number, 'out'))
        if 'registers' in description:
            self._registers = description['registers']
            self._register_name = description['fullpath'].rpartition('/')[2]
        else:
            self._registers = None

    @property
    def register_map(self):
        if not hasattr(self, '_register_map'):
            if self._registers:
                self._register_map = RegisterMap.create_subclass(
                        self._register_name,
                        self._registers)(self.mmio.array)
            else:
                raise AttributeError(
                        "register_map only available if the .hwh is provided")
        return self._register_map


    def read(self, offset=0):
        """Read from the MMIO device

        Parameters
        ----------
        offset : int
            Address to read

        """
        return self.mmio.read(offset)

    def write(self, offset, value):
        """Write to the MMIO device

        Parameters
        ----------
        offset : int
            Address to write to
        value : int or bytes
            Data to write

        """
        self.mmio.write(offset, value)


class _IPMap:
    """Class that stores drivers to IP, hierarches, interrupts and
    gpio as attributes.

    """

    def __init__(self, desc):
        """Create a new _IPMap based on a hierarchical description.

        """
        self._description = desc

    def __getattr__(self, key):
        if key in self._description['hierarchies']:
            hierdescription = self._description['hierarchies'][key]
            hierarchy = hierdescription['driver'](hierdescription)
            setattr(self, key, hierarchy)
            return hierarchy
        elif key in self._description['ip']:
            ipdescription = self._description['ip'][key]
            driver = ipdescription['driver'](ipdescription)
            setattr(self, key, driver)
            return driver
        elif key in self._description['interrupts']:
            interrupt = Interrupt(
                self._description['interrupts'][key]['fullpath'])
            setattr(self, key, interrupt)
            return interrupt
        elif key in self._description['gpio']:
            gpio_index = self._description['gpio'][key]['index']
            gpio_number = GPIO.get_gpio_pin(gpio_index)
            gpio = GPIO(gpio_number, 'out')
            setattr(self, key, gpio)
            return gpio
        else:
            raise AttributeError(
                "Could not find IP or hierarchy {} in overlay".format(key))

    def _keys(self):
        """The set of keys that can be accessed through the IP map

        """
        return (list(self._description['hierarchies'].keys()) +
                list(i for i in self._description['ip'].keys()) +
                list(i for i in self._description['interrupts'].keys()) +
                list(g for g in self._description['gpio'].keys()))

    def __dir__(self):
        return sorted(set(super().__dir__() +
                          list(self.__dict__.keys()) +
                          self._keys()))


def DocumentOverlay(bitfile, download):
    """Function to build a custom overlay class with a custom docstring
    based on the supplied bitstream. Mimics a class constructor.

    """
    class DocumentedOverlay(DefaultOverlay):
        def __init__(self):
            super().__init__(bitfile, download)
    overlay = DocumentedOverlay()
    DocumentedOverlay.__doc__ = _build_docstring(overlay._ip_map._description,
                                                 bitfile,
                                                 "overlay")
    return overlay


def DocumentHierarchy(description):
    """Helper function to build a custom hierarchy class with a docstring
    based on the description. Mimics a class constructor

    """
    class DocumentedHierarchy(DefaultHierarchy):
        def __init__(self):
            super().__init__(description)
    hierarchy = DocumentedHierarchy()
    DocumentedHierarchy.__doc__ = _build_docstring(description,
                                                   description['fullpath'],
                                                   "hierarchy")
    return hierarchy


class RegisterHierarchy(type):
    """Metaclass to register classes as hierarchy drivers

    Any class with this metaclass an the `checkhierarchy` function
    will be registered in the global driver database

    """
    def __init__(cls, name, bases, attrs):
        if 'checkhierarchy' in attrs:
            _hierarchy_drivers.appendleft(cls)
        super().__init__(name, bases, attrs)


class DefaultHierarchy(_IPMap, metaclass=RegisterHierarchy):
    """Hierarchy exposing all IP and hierarchies as attributes

    This Hierarchy is instantiated if no more specific hierarchy class
    registered with register_hierarchy_driver is specified. More specific
    drivers should inherit from `DefaultHierarachy` and call it's constructor
    in __init__ prior to any other initialisation. `checkhierarchy` should
    also be redefined to return True if the driver matches a hierarchy.
    Any derived class that meets these requirements will automatically be
    registered in the driver database.

    Attributes
    ----------
    description : dict
        Dictionary storing relevant information about the hierarchy.
    parsers : dict
        Parser objects for partial block design metadata.
    bitstreams : dict
        Bitstream objects for partial designs.
    pr_loaded : str
        The name of the partial bitstream loaded.

    """

    def __init__(self, description):
        self.description = description
        self.parsers = dict()
        self.bitstreams = dict()
        self.pr_loaded = ''
        super().__init__(description)

    @staticmethod
    def checkhierarchy(description):
        """Function to check if the driver matches a particular hierarchy

        This function should be redefined in derived classes to return True
        if the description matches what is expected by the driver. The default
        implementation always returns False so that drivers that forget don't
        get loaded for hierarchies they don't expect.

        """
        return False

    def download(self, bitfile_name):
        """Function to download a partial bitstream for the hierarchy block.

        Since it is hard to know which hierarchy is to be reconfigured by only
        looking at the metadata, we assume users will tell this information.
        Thus, this function should be called only when users are sure about
        the hierarchy name of the partial region.

        Parameters
        ----------
        bitfile_name : str
            The name of the partial bitstream.

        """
        self._locate_metadata(bitfile_name)
        self._parse(bitfile_name)
        self._load_bitstream(bitfile_name)
        self.pr_loaded = bitfile_name

    def _locate_metadata(self, bitfile_name):
        self.bitstreams[bitfile_name] = Bitstream(bitfile_name,
                                                  partial=True)
        bitfile_name = self.bitstreams[bitfile_name].bitfile_name
        hwh_path = get_hwh_name(bitfile_name)
        tcl_path = get_tcl_name(bitfile_name)
        if os.path.exists(hwh_path):
            self.parsers[bitfile_name] = HWH(hwh_path)
        elif os.path.exists(tcl_path):
            self.parsers[bitfile_name] = TCL(tcl_path)
            message = "Users will not get PARAMETERS / REGISTERS information " \
                      "through TCL files. HWH file is recommended."
            warnings.warn(message, UserWarning)
        else:
            raise ValueError("Cannot find HWH or TCL file for {}.".format(
                bitfile_name))

    def _parse(self, bitfile_name):
        fullpath = self.description['fullpath']
        ip_dict = dict()
        for k, v in self.parsers[bitfile_name].ip_dict.items():
            ip_dict_id = fullpath + '/' + v['mem_id']
            ip_dict[ip_dict_id] = v
            ip_dict[ip_dict_id]['fullpath'] = fullpath + '/' + v['fullpath']
        self.parsers[bitfile_name].ip_dict = ip_dict

        self.parsers[bitfile_name].nets = {
            fullpath + '_' + s: {
                fullpath + '/' + i for i in p}
            for s, p in self.parsers[bitfile_name].nets.items()
        }

        self.parsers[bitfile_name].pins = {
            fullpath + '/' + p: fullpath + '_' + s
            for p, s in self.parsers[bitfile_name].pins.items()
        }

    def _load_bitstream(self, bitfile_name):
        self.bitstreams[bitfile_name].download()
