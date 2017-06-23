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
from .pl import _TCL
from .pl import _get_tcl_name
from .pl import PYNQ_PATH
from .interrupt import Interrupt
from .gpio import GPIO


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


def _subhierarchy(description, hierarchy):
    """Returns a hierarchical subset of an IP dict

    """
    return {k.partition('/')[2]: v
            for k, v in description.items()
            if k.startswith('{}/'.format(hierarchy))}


def _hierarchical_description(description, path):
    """Creates a hierarchical description of an IP dict

    The description is a recursively structured collection of
    dictionaries. There are four dictionary types:

    hierarchies: { 'ip': ip, 'hierarchies': hierarchies,
                   'interrupts': interrupts, 'gpio': gpio,
                   'fullpath': str }

    ip: Subset of ip_dict containing IP directly in the hierarchy
        with each entry containing having additional members
        {'fullpath': str, 'interrupts': interrupts, 'gpio': gpio}

    interrupts: Dict of pin name to entry in PL.interrupt_pins
                with each entry also having a 'fullpath' entry.

    gpio: Dict of pin name to entry in PL.gpio_dict with each
          entry also having a 'fullpath' entry.

    This function creates the skeleton hierachies without interrupt
    or gpio information.

    """
    hierarchies = {k.partition('/')[0]
                   for k in description.keys() if k.count('/')}
    ipnames = {k for k, v in description.items() if k.count('/') ==
               0 and 'type' in v}
    if path:
        prefix = '{}/'.format(path)
    else:
        prefix = ''

    hierarchy_dict = dict()
    for h in hierarchies:
        hierarchy_dict[h] = _hierarchical_description(
            _subhierarchy(description, h), '{}{}'.format(prefix, h))

    ip_dict = dict()
    for ip in ipnames:
        ipdescription = deepcopy(description[ip])
        ipdescription['fullpath'] = '{}{}'.format(prefix, ip)
        ipdescription['interrupts'] = dict()
        ipdescription['gpio'] = dict()
        ip_dict[ip] = ipdescription

    newdescription = {'ip': ip_dict,
                      'hierarchies': hierarchy_dict,
                      'interrupts': {},
                      'gpio': {},
                      'fullpath': path}
    return newdescription


def _find_entry(hierarchy, path):
    """Helper function to find an entry in a hierarchical description
    based on a path. Return None if the path cannot be found.

    """
    base, _, rest = path.partition('/')
    if not rest:
        return hierarchy
    elif base in hierarchy['hierarchies']:
        return _find_entry(hierarchy['hierarchies'][base], rest)
    elif base in hierarchy['ip']:
        if rest.count('/'):
            return None
        else:
            return hierarchy['ip'][base]
    else:
        return None


def _assign_drivers(description):
    """Assigns a driver for each IP and hierarchy in the description.

    """
    for name, details in description['hierarchies'].items():
        _assign_drivers(details)
        details['driver'] = DocumentHierarchy
        for hip in _hierarchy_drivers:
            if hip.checkhierarchy(details):
                details['driver'] = hip
                break

    for name, details in description['ip'].items():
        if details['type'] in _ip_drivers:
            details['driver'] = _ip_drivers[details['type']]
        else:
            details['driver'] = DefaultIP


def _complete_description(ip_dict, gpio_dict, interrupts):
    """Returns a complete hierarchical description of an overlay based
    on the three dictionaries parsed from the TCL.

    """
    starting_dict = _hierarchical_description(ip_dict, '')

    for interrupt, details in interrupts.items():
        entry = _find_entry(starting_dict, interrupt)
        if entry:
            _, _, leafname = interrupt.rpartition('/')
            description = deepcopy(details)
            description['fullpath'] = interrupt
            entry['interrupts'][leafname] = description

    for gpio, details in gpio_dict.items():
        for pin in details['pins']:
            entry = _find_entry(starting_dict, pin)
            if entry:
                _, _, leafname = pin.rpartition('/')
                description = deepcopy(details)
                description['fullpath'] = pin
                entry['gpio'][leafname] = description

    _assign_drivers(starting_dict)
    return starting_dict


class DefaultOverlay(PL):
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
    directly to the PS7.
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
        All the addressable IPs from PS7. Key is the name of the IP; value is
        a dictionary mapping the physical address, address range, IP type,
        configuration dictionary, and the state associated with that IP:
        {str: {'phys_addr' : int, 'addr_range' : int,
               'type' : str, 'config' : dict, 'state' : str}}.
    gpio_dict : dict
        All the GPIO pins controlled by PS7. Key is the name of the GPIO pin;
        value is a dictionary mapping user index (starting from 0),
        and the state associated with that GPIO pin:
        {str: {'index' : int, 'state' : str}}.
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

    """
        
    def __init__(self, bitfile_name, download):
        """Return a new Overlay object.

        An overlay instantiates a bitstream object as a member initially.

        Parameters
        ----------
        bitfile_name : str
            The bitstream name or absolute path as a string.
        download : boolean or None
            Whether the overlay should be downloaded. If None then the
            overlay will be downloaded if it isn't already loaded.

        Note
        ----
        This class requires a Vivado '.tcl' file to be next to bitstream file
        with same name (e.g. base.bit and base.tcl).

        """
        super().__init__()

        # Set the bitstream
        self.bitstream = Bitstream(bitfile_name)
        self.bitfile_name = self.bitstream.bitfile_name
        tcl = _TCL(_get_tcl_name(self.bitfile_name))
        self.ip_dict = tcl.ip_dict
        self.gpio_dict = tcl.gpio_dict
        self.interrupt_controllers = tcl.interrupt_controllers
        self.interrupt_pins = tcl.interrupt_pins
        self.clock_dict = tcl.clock_dict

        description = _complete_description(
            self.ip_dict, self.gpio_dict, self.interrupt_pins)
        self._ip_map = _IPMap(description)
        if download is None:
            download = bitfile_name != PL.bitfile_name
        if download: 
            self.download()

    def __getattr__(self, key):
        """Overload of __getattr__ to return a driver for an IP or
        hierarchy. Throws an `RuntimeError` if the overlay is not loaded.

        """
        if self.is_loaded():
            return getattr(self._ip_map, key)
        else:
            raise RuntimeError("Overlay not currently loaded")

    def download(self):
        """The method to download a bitstream onto PL.

        Note
        ----
        After the bitstream has been downloaded, the "timestamp" in PL will be
        updated. In addition, all the dictionaries on PL will
        be reset automatically.

        Returns
        -------
        None

        """
        for i in self.clock_dict:
            enable = self.clock_dict[i]['enable']
            div0 = self.clock_dict[i]['divisor0']
            div1 = self.clock_dict[i]['divisor1']
            if enable:
                Clocks.set_fclk(i, div0, div1)
            else:
                Clocks.set_fclk(i)

        self.bitstream.download()
        PL.reset()

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
        if not self.bitstream.timestamp == '':
            return self.bitstream.timestamp == PL._timestamp
        else:
            return self.bitfile_name == PL._bitfile_name

    def reset(self):
        """This function resets all the dictionaries kept in the overlay.

        This function should be used with caution.

        Returns
        -------
        None

        """
        tcl = _TCL(_get_tcl_name(self.bitfile_name))
        self.ip_dict = tcl.ip_dict
        self.gpio_dict = tcl.gpio_dict
        self.interrupt_controllers = tcl.interrupt_controllers
        self.interrupt_pins = tcl.interrupt_pins
        if self.is_loaded():
            PL.reset()

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
        return super().__init__(name, bases, attrs)


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


_class_aliases = {
    'pynq.overlay.DocumentOverlay': 'pynq.overlay.DefaultOverlay',
    'pynq.overlay.DocumentHierarchy': 'pynq.overlay.DefaultHierarchy'
}


def _classname(class_):
    """Returns the full name for a class. Has option for overriding
    some class names to hide internal details. The overrides are
    stored in the `_classaliases` dictionaries.

    """
    rawname = "{}.{}".format(class_.__module__, class_.__name__)
                                            
    if rawname in _classaliases:
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
    lines = []
    lines.append("Default documentation for {} {}. The following"
                 .format(type_, name))
    lines.append("attributes are available on this {}:".format(type_))
    lines.append("")

    lines.append("IP Blocks")
    lines.append("----------")
    if description['ip']:
        for ip, details in description['ip'].items():
            lines.append("{0 : <20} : {1}"
                         .format(ip, _classname(details['driver'])))
    else:
        lines.append("None")
    lines.append("")

    lines.append("Hierarchies")
    lines.append("-----------")
    if description['hierarchies']:
        for hierarchy, details in description['hierarchies'].items():
            lines.append("{0 : <20} : {1}"
                         .format(hierarchy, _classname(details['driver'])))
    else:
        lines.append("None")
    lines.append("")

    lines.append("Interrupts")
    lines.append("----------")
    if description['interrupts']:
        for interrupt in description['interrupts'].keys():
            lines.append("{0 : <20} : pynq.interrupt.Interrupt"
                         .format(interrupt))
    else:
        lines.append("None")
    lines.append("")

    lines.append("GPIO Outputs")
    lines.append("------------")
    if description['gpio']:
        for gpio in description['gpio'].keys():
            lines.append("{0 : <20} : pynq.gpio.GPIO".format(gpio))
    else:
        lines.append("None")
    lines.append("")
    return '\n    '.join(lines)


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
        return super().__init__(name, bases, attrs)


class DefaultHierarchy(_IPMap, metaclass=RegisterHierarchy):
    """Hierarchy exposing all IP and hierarchies as attributes

    This Hierarchy is instantiated if no more specific hierarchy class
    registered with register_hierarchy_driver is specified. More specific
    drivers should inherit from `DefaultHierarachy` and call it's constructor
    in __init__ prior to any other initialisation. `checkhierarchy` should
    also be redefined to return True if the driver matches a hierarchy.
    Any derived class that meets these requirements will automatically be
    registered in the driver database.

    """

    def __init__(self, description):
        self.description = description
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


def Overlay(bitfile, download=None, class_=None):
    """Instantiate and download an overlay.

    This class will return an instance of `class_` if one is provided.
    If no preference is specified and a python file is located with the
    bitfile then the `Overlay` function in that file will be called. If
    no python file is provided then a `DefaultOverlay` will be returned.

    Parameters
    ----------
    bitfile : str
        Bitstream file to load. The bitfile should either be an absolute
        path or one of the installed bitstreams in the pynq installation
        directory.
    class_ : class
        Class to return instead of the overlay-specified default.

    Returns
    -------
    Instantiated overlay

    Note
    ----

    If this method is called on an unsupported architecture it will warn and
    return None

    """
    if not CPU_ARCH_IS_SUPPORTED:
        warnings.warn("Pynq does not support the CPU Architecture: {}"
                      .format(CPU_ARCH), ResourceWarning)
        return None
    
    bitfile_path = os.path.join(
        PYNQ_PATH, bitfile.replace('.bit', ''), bitfile)
    python_path = os.path.splitext(bitfile_path)[0] + '.py'
    if class_:
        return class_(bitfile, download)
    elif os.path.exists(python_path):
        spec = importlib.util.spec_from_file_location(
            os.path.splitext(os.path.basename(bitfile_path))[0],
            python_path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module.Overlay(bitfile, download)
    else:
        return DocumentOverlay(bitfile, download)
