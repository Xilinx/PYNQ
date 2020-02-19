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
import ctypes
import itertools
import os
import re
import struct
import warnings
from copy import deepcopy
from .mmio import MMIO
from .ps import Clocks
from .bitstream import Bitstream
from .interrupt import Interrupt
from .gpio import GPIO
from .registers import RegisterMap
from .utils import ReprDict

if "XILINX_XRT" in os.environ:
    try:
        import ert_binding as ert
    except ImportError:
        from pynq import ert

    # Monkey patch typo in some versions on XRT Python binding
    if not hasattr(ert, 'ert_cmd_type'):
        ert.ert_cmd_type = ert.ert_cmdype


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


def _assign_drivers(description, ignore_version, device):
    """Assigns a driver for each IP and hierarchy in the description.

    """
    for name, details in description['hierarchies'].items():
        _assign_drivers(details, ignore_version, device)
        details['device'] = device
        details['driver'] = DocumentHierarchy
        for hip in _hierarchy_drivers:
            if hip.checkhierarchy(details):
                details['driver'] = hip
                break

    for name, details in description['ip'].items():
        details['device'] = device
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


def _complete_description(ip_dict, hierarchy_dict, ignore_version,
                          mem_dict, device):
    """Returns a complete hierarchical description of an overlay based
    on the three dictionaries parsed from the TCL.

    """
    starting_dict = dict()
    starting_dict['ip'] = {k: v for k, v in ip_dict.items()}
    starting_dict['hierarchies'] = {k: v for k, v in hierarchy_dict.items()}
    starting_dict['interrupts'] = dict()
    starting_dict['gpio'] = dict()
    starting_dict['memories'] = {re.sub('[^A-Za-z0-9_]', '', k): v
                                 for k, v in mem_dict.items() if v['used']}
    starting_dict['device'] = device
    _assign_drivers(starting_dict, ignore_version, device)
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

    lines.append("Memories")
    lines.append("------------")
    if description['memories']:
        for mem, mem_desc in description['memories'].items():
            if 'streaming' in mem_desc and mem_desc['streaming']:
                lines.append("{0: <20} : Stream".format(mem))
            else:
                lines.append("{0: <20} : Memory".format(mem))
    else:
        lines.append("None")
    lines.append("")
    lines.append("")
    return '\n    '.join(lines)


class Overlay(Bitstream):
    """This class keeps track of a single bitstream's state and contents.

    The overlay class holds the state of the bitstream and enables run-time
    protection of bindings.

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
    dtbo : str
        The absolute path of the dtbo file for the full bitstream.
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
    pr_dict : dict
        Dictionary mapping from the name of the partial-reconfigurable
        hierarchical blocks to the loaded partial bitstreams:
        {str: {'loaded': str, 'dtbo': str}}.
    device : pynq.Device
        The device that the overlay is loaded on

    """
    def __init__(self, bitfile_name, dtbo=None,
                 download=True, ignore_version=False, device=None):
        """Return a new Overlay object.

        An overlay instantiates a bitstream object as a member initially.

        Parameters
        ----------
        bitfile_name : str
            The bitstream name or absolute path as a string.
        dtbo : str
            The dtbo file name or absolute path as a string.
        download : bool
            Whether the overlay should be downloaded.
        ignore_version : bool
            Indicate whether or not to ignore the driver versions.
        device : pynq.Device
            Device on which to load the Overlay. Defaults to
            pynq.Device.active_device

        Note
        ----
        This class requires a Vivado TCL file to be next to bitstream file
        with same name (e.g. `base.bit` and `base.tcl`).

        """
        super().__init__(bitfile_name, dtbo, partial=False, device=device)

        self.parser = self.device.get_bitfile_metadata(self.bitfile_name)

        self.ip_dict = self.gpio_dict = self.interrupt_controllers = \
            self.interrupt_pins = self.hierarchy_dict = dict()
        self._deepcopy_dict_from(self.parser)
        self.clock_dict = self.parser.clock_dict
        self.pr_dict = dict()
        self.ignore_version = ignore_version
        description = _complete_description(
            self.ip_dict, self.hierarchy_dict, self.ignore_version,
            self.mem_dict, self.device)
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
        self.ip_dict = ReprDict(deepcopy(source.ip_dict), rootname='ip_dict')
        self.gpio_dict = ReprDict(deepcopy(source.gpio_dict),
                                  rootname='gpio_dict')
        self.interrupt_controllers = ReprDict(
            deepcopy(source.interrupt_controllers),
            rootname='interrupt_controllers')
        self.interrupt_pins = ReprDict(
            deepcopy(source.interrupt_pins), rootname='interrupt_pins')
        self.hierarchy_dict = ReprDict(deepcopy(source.hierarchy_dict),
                                       rootname='hierarchy_dict')
        self.mem_dict = ReprDict(deepcopy(source.mem_dict),
                                 rootname='mem_dict')

    def free(self):
        if hasattr(self.device, 'free_bitstream'):
            self.device.free_bitstream()

    def download(self, dtbo=None):
        """The method to download a full bitstream onto PL.

        After the bitstream has been downloaded, the "timestamp" in PL will be
        updated. In addition, all the dictionaries on PL will
        be reset automatically.

        This method will use parameter `dtbo` or `self.dtbo` to configure the
        device tree.

        Parameters
        ----------
        dtbo : str
            The path of the dtbo file.

        """
        for i in self.clock_dict:
            enable = self.clock_dict[i]['enable']
            div0 = self.clock_dict[i]['divisor0']
            div1 = self.clock_dict[i]['divisor1']
            if enable:
                Clocks.set_pl_clk(i, div0, div1)
            else:
                Clocks.set_pl_clk(i)

        super().download(self.parser)
        if dtbo:
            super().insert_dtbo(dtbo)
        elif self.dtbo:
            super().insert_dtbo()

    def pr_download(self, partial_region, partial_bit, dtbo=None):
        """The method to download a partial bitstream onto PL.

        In this method, the corresponding parser will only be
        added once the `download()` method of the hierarchical block is called.

        This method always uses the parameter `dtbo` to configure the device
        tree.

        Note
        ----
        There is no check on whether the partial region specified by users
        is really partial-reconfigurable. So users have to make sure the
        `partial_region` provided is correct.

        Parameters
        ----------
        partial_region : str
            The name of the hierarchical block corresponding to the PR region.
        partial_bit : str
            The name of the partial bitstream.
        dtbo : str
            The path of the dtbo file.

        """
        self.device.reset(self.parser)
        pr_block = self.__getattr__(partial_region)
        pr_block.download(bitfile_name=partial_bit, dtbo=dtbo)
        pr_parser = pr_block.parsers[pr_block.pr_loaded]
        pr_dtbo = pr_block.bitstreams[partial_bit].dtbo
        self.device.update_partial_region(partial_region, pr_parser)
        self._deepcopy_dict_from(self.device)
        self.pr_dict[partial_region] = {'loaded': pr_block.pr_loaded,
                                        'dtbo': pr_dtbo}
        description = _complete_description(
            self.ip_dict, self.hierarchy_dict, self.ignore_version,
            self.mem_dict, self.device)
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
        if not self.timestamp == '':
            return self.timestamp == self.device.timestamp
        else:
            return self.bitfile_name == self.device.bitfile_name

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
            self.device.reset(self.parser, self.timestamp, self.bitfile_name)

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
        self.device.load_ip_data(ip_name, data)
        self.ip_dict[ip_name]['state'] = data

    def __dir__(self):
        return sorted(set(super().__dir__() +
                          list(self.__dict__.keys()) + self._ip_map._keys()))


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

_struct_dict = {
    # Base Vitis int types
    'char': 'c',
    'signed char': 'b',
    'unsigned char': 'B',
    'short': 'h',
    'unsigned short': 'H',
    'int': 'i',
    'unsigned int': 'I',
    'long int': 'l',
    'long unsigned int': 'L',
    'long long int': 'q',
    'long long unsigned int': 'Q',
    # Base Vitis floating point types
    'float': 'f',
    'double': 'd',
    # Other types seen in the wild
    'long': 'l',
    'uint': 'I',
    'ushort': 'H'
}


def _ctype_to_struct(ctype):
    ctype = ctype.replace('const', '').strip()
    return _struct_dict[ctype]

XrtArgument = collections.namedtuple('XrtArgument',
                                     ['name', 'index', 'type', 'mem'])


def _create_call(regmap):
    from inspect import Parameter, Signature

    sorted_regmap = list(regmap.items())
    sorted_regmap.sort(key=lambda x: x[1]['address_offset'])

    parameters = []
    ptr_list = []
    struct_string = "="
    arg_details = {}

    for k, v in sorted_regmap:
        curr_offset = struct.calcsize(struct_string)
        reg_offset = v['address_offset']
        if reg_offset < curr_offset:
            raise RuntimeError("Struct string generation failed")
        elif reg_offset > curr_offset:
            struct_string += "{}x".format(reg_offset - curr_offset)
        reg_type = v['type']
        if "*" in reg_type:
            struct_string += "Q"
            ptr_type = True
        else:
            struct_string += _struct_dict[v['type']]
            ptr_type = False
        if k != 'CTRL':
            ptr_list.append(ptr_type)
            parameters.append(Parameter(
                k, Parameter.POSITIONAL_OR_KEYWORD,
                annotation=v['type']))
            arg_details[k] = XrtArgument(
                k, len(parameters), v['type'],
                v['memory'] if 'memory' in v else None)
    signature = Signature(parameters)
    return signature, struct_string, ptr_list, arg_details


class WaitHandle:
    def __init__(self, target):
        self.target = target

    def wait(self):
        while self.target.mmio.read(0) & 0x4 != 0x4:
            pass


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
        if 'device' in description:
            self.device = description['device']
        else:
            from .pl_server.device import Device
            self.device = Device.active_device
        self.mmio = MMIO(description['phys_addr'], description['addr_range'],
                         device=self.device)
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
            if ('CTRL' in self._registers and
                    self.device.has_capability('CALLABLE')):
                self._signature, struct_string, self._ptr_list, self.args = \
                    _create_call(self._registers)
                self._call_struct = struct.Struct(struct_string)
        else:
            self._registers = None
        if 'index' in description:
            self.cu_mask = 1 << description['adjusted_index']
            self._setup_packet_prototype()
        if 'streams' in description:
            self.streams = {}
            for k, v in description['streams'].items():
                stream = self.device.get_memory_by_idx(v['stream_id'])
                self.streams[k] = stream
                if v['direction'] == 'output':
                    stream.source_ip = self
                elif v['direction'] == 'input':
                    stream.sink_ip = self

        if self.signature is None:
            self._start = self.start_none
        elif self.device.has_capability('ERT'):
            self._start = self.start_ert
        else:
            self._start = self.start_sw

    def _setup_packet_prototype(self):
        self._packet = ert.ert_start_kernel_cmd()
        self._packet.m_uert.m_start_cmd_struct.state = \
            ert.ert_cmd_state.ERT_CMD_STATE_NEW
        self._packet.m_uert.m_start_cmd_struct.unused = 0
        self._packet.m_uert.m_start_cmd_struct.extra_cu_masks = 0
        self._packet.m_uert.m_start_cmd_struct.count = \
            (self._call_struct.size // 4) + 1
        self._packet.m_uert.m_start_cmd_struct.opcode = \
            ert.ert_cmd_opcode.ERT_START_CU
        self._packet.m_uert.m_start_cmd_struct.type = \
            ert.ert_cmd_type.ERT_DEFAULT
        self._packet.cu_mask = self.cu_mask

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

    @property
    def signature(self):
        """The signature of the `call` method

        """
        if hasattr(self, "_signature"):
            return self._signature
        else:
            return None

    def call(self, *args, **kwargs):
        self.start(*args, **kwargs).wait()

    def start_sw(self, *args, ap_ctrl=1, waitfor=None, **kwargs):
        """Start the accelerator

        This function will configure the accelerator with the provided
        arguments and start the accelerator. Use the `wait` function to
        determine when execution has finished. Note that buffers should be
        flushed prior to starting the accelerator and any result buffers
        will need to be invalidated afterwards.

        For details on the function's signature use the `signature` property.
        The type annotations provide the C types that the accelerator
        operates on. Any pointer types should be passed as `ContiguousArray`
        objects created from the `pynq.Xlnk` class. Scalars should be passed
        as a compatible python type as used by the `struct` library.

        """
        if not self._signature:
            raise RuntimeError("Only HLS IP can be called with the wrapper")
        if waitfor is not None:
            raise RuntimeError(
                "waitfor only supported on newer versions of XRT")
        if kwargs:
            # Resolve any kwargs to make a single args tuple
            args = self._signature.bind(*args, **kwargs).args
        # Resolve and pointers that need .device_address taken
        args = [a.device_address if p else a
                for a, p in itertools.zip_longest(args, self._ptr_list)]
        self.mmio.write(0, self._call_struct.pack(0, *args))
        self.mmio.write(0, ap_ctrl)
        return WaitHandle(self)

    def start_none(self, *args, **kwargs):
        raise RuntimeError("Start only supported for XCLBIN-based designs")

    def start(self, *args, **kwargs):
        """Start the accelerator

        This function will configure the accelerator with the provided
        arguments and start the accelerator. Use the `wait` function to
        determine when execution has finished. Note that buffers should be
        flushed prior to starting the accelerator and any result buffers
        will need to be invalidated afterwards.

        For details on the function's signature use the `signature` property.
        The type annotations provide the C types that the accelerator
        operates on. Any pointer types should be passed as `ContiguousArray`
        objects created from the `pynq.Xlnk` class. Scalars should be passed
        as a compatible python type as used by the `struct` library.

        """
        # For now direct people to the sw version until the ERT initialization
        # is fixed
        return self._start(*args, **kwargs)

    def start_ert(self, *args, waitfor=(), **kwargs):
        """Start the accelerator using the ERT scheduler

        This function will use the embedded scheduler to call the accelerator
        with the provided arguments - see the documentation for ``start`` for
        more details. An optional ``waitfor`` parameter can be used to
        schedule dependent executions without using the CPU.

        Parameters
        ----------
        waitfor : [WaitHandle]
            A list of wait handles returned by other calls to ``start_ert``
            which must complete before this execution starts

        Returns
        -------
        WaitHandle :
            Object with a ``wait`` call that will return when the execution
            completes

        """
        if not self._signature:
            raise RuntimeError("Only HLS IP can be called with the wrapper")
        if kwargs:
            # Resolve any kwargs to make a single args tuple
            args = self._signature.bind(*args, **kwargs).args
        args = [a.device_address if p else a for a, p in zip(args, 
                                                             self._ptr_list)]
        arg_data = self._call_struct.pack(0, *args)
        bo = self.device.get_exec_bo()
        exec_packet = bo.as_packet(ert.ert_start_kernel_cmd)
        exec_packet.m_uert.header = self._packet.m_uert.header
        exec_packet.cu_mask = self.cu_mask
        ctypes.memmove(exec_packet.data, arg_data, len(arg_data))
        wait_bos = tuple(w._bo for w in waitfor if w is not None and w._has_bo)
        if wait_bos:
            return self.device.execute_bo_with_waitlist(bo, wait_bos)
        else:
            return self.device.execute_bo(bo)

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
        elif key in self._description['memories']:
            mem = self._description['device'].get_memory(
                self._description['memories'][key])
            setattr(self, key, mem)
            return mem
        else:
            raise AttributeError(
                "Could not find IP or hierarchy {} in overlay".format(key))

    def _keys(self):
        """The set of keys that can be accessed through the IP map

        """
        return (list(self._description['hierarchies'].keys()) +
                list(i for i in self._description['ip'].keys()) +
                list(i for i in self._description['interrupts'].keys()) +
                list(i for i in self._description['gpio'].keys()) +
                list(g for g in self._description['memories'].keys()))

    def __dir__(self):
        return sorted(set(super().__dir__() +
                          list(self.__dict__.keys()) +
                          self._keys()))


def DocumentOverlay(bitfile, download):
    """Function to build a custom overlay class with a custom docstring
    based on the supplied bitstream. Mimics a class constructor.

    """
    class DocumentedOverlay(Overlay):
        def __init__(self):
            super().__init__(bitfile, download=download)
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
        The absolute path of the partial bitstream loaded.

    """

    def __init__(self, description):
        self.description = description
        self.parsers = dict()
        self.bitstreams = dict()
        self.pr_loaded = ''
        self.device = description['device']
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

    def download(self, bitfile_name, dtbo):
        """Function to download a partial bitstream for the hierarchy block.

        Since it is hard to know which hierarchy is to be reconfigured by only
        looking at the metadata, we assume users will tell this information.
        Thus, this function should be called only when users are sure about
        the hierarchy name of the partial region.

        Parameters
        ----------
        bitfile_name : str
            The name of the partial bitstream.
        dtbo : str
            The relative or absolute path of the partial dtbo file.

        """
        if self.pr_loaded:
            self._find_bitstream_by_abs(self.pr_loaded).remove_dtbo()
        self._locate_metadata(bitfile_name, dtbo)
        self._parse(bitfile_name)
        self._load_bitstream(bitfile_name)
        if dtbo:
            self.bitstreams[bitfile_name].insert_dtbo()

    def _find_bitstream_by_abs(self, absolute_path):
        for i in self.bitstreams.keys():
            if self.bitstreams[i].bitfile_name == absolute_path:
                return self.bitstreams[i]
        return None

    def _locate_metadata(self, bitfile_name, dtbo):
        self.bitstreams[bitfile_name] = Bitstream(bitfile_name, dtbo,
                                                  partial=True)
        bitfile_name = self.bitstreams[bitfile_name].bitfile_name
        self.parsers[bitfile_name] = self.device.get_bitfile_metadata(
            bitfile_name)

    def _parse(self, bitfile_name):
        bitfile_name = self.bitstreams[bitfile_name].bitfile_name
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
            if s is not None and p is not None
        }

        self.parsers[bitfile_name].pins = {
            fullpath + '/' + p: fullpath + '_' + s
            for p, s in self.parsers[bitfile_name].pins.items()
            if s is not None and p is not None
        }

    def _load_bitstream(self, bitfile_name):
        self.bitstreams[bitfile_name].download()
        self.pr_loaded = self.bitstreams[bitfile_name].bitfile_name
