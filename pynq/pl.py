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
import re
import mmap
import math
import warnings
from copy import deepcopy
from datetime import datetime
from multiprocessing.connection import Listener
from multiprocessing.connection import Client
from .mmio import MMIO
from .ps import Clocks, CPU_ARCH_IS_SUPPORTED, CPU_ARCH

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"

# Overlay constants
PYNQ_PATH = os.path.dirname(os.path.realpath(__file__))
BS_BOOT = os.path.join(PYNQ_PATH, 'overlays', 'base', 'base.bit')
TCL_BOOT = os.path.join(PYNQ_PATH, 'overlays', 'base', 'base.tcl')

BS_IS_PARTIAL = "/sys/devices/soc0/amba/f8007000.devcfg/is_partial_bitstream"
BS_XDEVCFG = "/dev/xdevcfg"

PL_SERVER_FILE = os.path.join(PYNQ_PATH, '.log')


def _get_tcl_name(bitfile_name):
    """This method returns the name of the tcl file.

    For example, the input "/home/xilinx/src/pynq/bitstream/base.bit" will
    lead to the result "/home/xilinx/src/pynq/bitstream/base.tcl".

    Parameters
    ----------
    bitfile_name : str
        The absolute path of the .bit file.

    Returns
    -------
    str
        The absolute path of the .tcl file.

    """
    return os.path.splitext(bitfile_name)[0] + '.tcl'


class _TCL:
    """Helper Class to extract information from a TCL configuration file

    Note
    ----
    This class requires the absolute path of the '.tcl' file.

    Attributes
    ----------
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
    clock_dict : dict
        All the PL clocks that can be controlled by the PS. Key is the index
        of the clock (e.g., 0 for `fclk0`); value is a dictionary mapping the 
        divisor values and the enable flag (1 for enabled, and 
        0 for disabled):
        {index: {'divisor0' : int, 'divisor1' : int, 'enable' : int}}

    """

    def __init__(self, tcl_name):
        """Returns a map built from the supplied tcl file

        Parameters
        ---------
        tcl_name : str
            The tcl filename to parse. This is opened directly so should be
            fully qualified

        Note
        ----
        If this method is called on an unsupported architecture it will warn 
        and return without initialization

        """
        
        if not isinstance(tcl_name, str):
            raise TypeError("tcl_name has to be a string")
        
        # Initialize result variables
        self.intc_names = []
        self.interrupt_controllers = {}
        self.concat_cells = {}
        self.nets = []
        self.pins = {}
        self.prop = []
        self.interrupt_pins = {}
        self.ps_name = ""
        self.ip_dict = {}
        self.gpio_dict = {}
        self.clock_dict = {}

        # Key strings to search for in the TCL file
        family_pat = "create_project"
        family_regex = "(?P<family_str>xc.{2}).*"
        family_ps_dict = {"xc7z": "processing_system7",
                          "xczu": "zynq_ultra_ps_e"}
        family_irq_dict = {"xc7z": "IRQ_F2P",
                           "xczu": "pl_ps_irq0"}
        family_gpio_dict = {"xc7z": "GPIO_O",
                            "xczu": "emio_gpio_o"}
        hier_use_pat = "create_hier_cell"
        hier_proc_def_pat = "proc {}".format(hier_use_pat)
        hier_def_regex = "create_hier_cell_(?P<name>[^ ]*)"
        hier_proc_end_pat = "}\n"
        hier_use_regex = ("create_hier_cell_(?P<hier_name>[^ ]*) ([^ ].*) " +
                          "(?P<instance_name>[^ ]*)\n")

        config_ip_pat = "CONFIG."
        config_regex = "CONFIG.(?P<key>.+?) \{(?P<value>.+?)\}"
        clk_odiv_regex = 'PCW_FCLK(?P<idx>.+?)_PERIPHERAL_DIVISOR' \
                         '(?P<div>[01])$'
        clk_enable_regex = 'PCW_FPGA_FCLK(?P<idx>.+?)_ENABLE$'
        prop_start_pat = "set_property -dict ["
        prop_end_pat = "]"
        prop_name_regex = "\] \$(?P<instance_name>.+?)$"
        net_pat = "connect_bd_net -net"
        net_regex = "\[get_bd_pins (?P<name>[^]]+)\]"
        addr_pat = "create_bd_addr_seg"
        addr_regex = ("create_bd_addr_seg " +
                      "-range (?P<range>0[xX][0-9a-fA-F]+) " +
                      "-offset (?P<addr>0[xX][0-9a-fA-F]+) " +
                      "\[get_bd_addr_spaces ")
        ip_pat = "create_bd_cell -type ip -vlnv "
        ip_regex = ("create_bd_cell -type ip -vlnv " +
                    "(?P<author>.+?):" +
                    "(?P<type>.+?):" +
                    "(?P<ip_name>.+?):" +
                    "(?P<version>.+?) " +
                    "(?P<instance_name>[^ ]*)")
        ignore_regex = "\s*(\#|catch).*"

        # Parsing state
        current_hier = ""
        last_concat = ""
        in_prop = False
        gpio_idx = None
        gpio_dict = dict()
        hier_dict = dict()
        hier_dict[current_hier] = dict()

        with open(tcl_name, 'r') as f:
            for line in f:
                if re.match(ignore_regex, line):
                    continue

                # Matching IP configurations
                elif prop_start_pat in line:
                    in_prop = True

                # Matching Property declarations
                elif in_prop:
                    if prop_end_pat in line:
                        m = re.search(prop_name_regex, line, re.IGNORECASE)
                        if m and gpio_idx is not None:
                            name = m.group("instance_name")
                            gpio_dict[name] = gpio_idx
                            gpio_idx = None
                        in_prop = False

                    elif config_ip_pat in line:
                        m1 = re.search(config_regex, line)
                        key = m1.group("key")
                        value = m1.group("value")

                        if key == "NUM_PORTS":
                            self.concat_cells[last_concat] = int(value)

                        elif key == 'DIN_FROM':
                            gpio_idx = int(value)

                        elif "FCLK" in line and "PERIPHERAL_DIVISOR" in line:
                            m2 = re.search(clk_odiv_regex, key)
                            idx = int(m2.group("idx"))
                            if idx not in self.clock_dict:
                                self.clock_dict[idx] = {}
                            divisor_name = 'divisor' + m2.group("div")
                            self.clock_dict[idx][divisor_name] = int(value)

                        elif "FCLK" in line and "ENABLE" in line:
                            m3 = re.search(clk_enable_regex, key)
                            idx = int(m3.group("idx"))
                            if idx not in self.clock_dict:
                                self.clock_dict[idx] = {}
                            self.clock_dict[idx]['enable'] = int(value)

                # Match project/family declaration
                elif family_pat in line:
                    m = re.search(family_regex, line, re.IGNORECASE)
                    self.family = m.group("family_str")

                # Matching address segment
                elif addr_pat in line:
                    m = re.search(addr_regex, line, re.IGNORECASE)
                    if m:
                        for ip_dict0 in hier_dict:
                            for ip_name, ip_type in \
                                    hier_dict[ip_dict0].items():
                                ip = (ip_dict0 + '/' + ip_name).lstrip('/')
                                if m.group("hier").startswith(ip):
                                    self.ip_dict[ip] = dict()
                                    self.ip_dict[ip]['phys_addr'] = \
                                        int(m.group("addr"), 16)
                                    self.ip_dict[ip]['addr_range'] = \
                                        int(m.group("range"), 16)
                                    self.ip_dict[ip]['type'] = ip_type
                                    self.ip_dict[ip]['state'] = None
                                    self.ip_dict[ip]['interrupts'] = dict()
                                    self.ip_dict[ip]['gpio'] = dict()
                                    self.ip_dict[ip]['fullpath'] = ip

                # Match hierarchical cell definition
                elif hier_proc_def_pat in line:
                    m = re.search(hier_def_regex, line)
                    hier_name = m.group("name")
                    current_hier = hier_name
                    hier_dict[current_hier] = dict()

                elif hier_proc_end_pat == line:
                    current_hier = ""

                # Match hierarchical cell use/instantiation
                elif hier_use_pat in line:
                    m = re.search(hier_use_regex, line)
                    hier_name = m.group("hier_name")
                    inst_name = m.group("instance_name")
                    inst_path = (current_hier + '/' + inst_name).lstrip('/')
                    inst_dict = dict()
                    for path in hier_dict:
                        psplit = path.split('/')
                        if psplit[0] == hier_name:
                            inst_path += path.lstrip(hier_name)
                            inst_dict[inst_path] = deepcopy(hier_dict[path])
                    hier_dict.update(inst_dict)

                # Matching IP cells in root design
                elif ip_pat in line:
                    m = re.search(ip_regex, line)
                    ip_name = m.group("ip_name")
                    instance_name = m.group("instance_name")
                    if m.group("ip_name") == family_ps_dict[self.family]:
                        self.ps_name = instance_name
                        addr_regex += (instance_name + "/Data\] " +
                                       "\[get_bd_addr_segs (?P<hier>.+?)\] " +
                                       "(?P<name>[A-Za-z0-9_]+)")
                    else:
                        ip_type = ':'.join([m.group(1), m.group(2),
                                            m.group(3), m.group(4)])
                        hier_dict[current_hier][instance_name] = ip_type

                        ip = (current_hier + '/' + instance_name).lstrip('/')
                        if ip_name == "xlconcat":
                            last_concat = ip
                            self.concat_cells[ip] = 2
                        elif ip_name == "axi_intc":
                            self.intc_names.append(ip)

                # Matching nets
                elif net_pat in line:
                    mpins = re.findall(net_regex, line, re.IGNORECASE)
                    new_pins = [(current_hier + "/" + v).lstrip('/') for v in
                                mpins]
                    indexes = {self.pins[p] for p in new_pins if
                               p in self.pins}
                    if len(indexes) == 0:
                        index = len(self.nets)
                        self.nets.append(set())
                    else:
                        to_merge = []
                        while len(indexes) > 1:
                            to_merge.append(indexes.pop())
                        index = indexes.pop()
                        for i in to_merge:
                            self.nets[index] |= self.nets[i]
                    self.nets[index] |= set(new_pins)
                    for p in self.nets[index]:
                        self.pins[p] = index

        if self.ps_name + "/" + family_irq_dict[self.family] in self.pins:
            ps_irq_net = self.pins[
                self.ps_name + "/" + family_irq_dict[self.family]]
            self._add_interrupt_pins(ps_irq_net, "", 0)

        if self.ps_name + "/" + family_gpio_dict[self.family] in self.pins:
            ps_gpio_net = self.pins[
                self.ps_name + "/" + family_gpio_dict[self.family]]
            self._add_gpio_pins(ps_gpio_net, gpio_dict)

        self._build_hierarchy_dict()
        self._assign_interrupts_gpio()

    def _add_gpio_pins(self, net, gpio_dict):
        net_pins = self.nets[net]
        gpio_names = []
        for p in net_pins:
            m = re.match('(.*)/Din', p)
            if m is not None:
                gpio_names.append(m.group(1))
        for n, i in gpio_dict.items():
            if n in gpio_names:
                output_net = self.pins['{}/Dout'.format(n)]
                output_pins = self.nets[output_net]
                self.gpio_dict[n] = {'index': i, 'state': None,
                                     'pins': output_pins}

    def _add_interrupt_pins(self, net, parent, offset):
        net_pins = self.nets[net]
        # Find the next item up the chain
        for p in net_pins:
            m = re.match('(.*)/dout', p)
            if m is not None:
                name = m.group(1)
                if name in self.concat_cells:
                    return self._add_concat_pins(name, parent, offset)
            m = re.match('(.*)/irq', p)
            if m is not None:
                name = m.group(1)
                if name in self.intc_names:
                    self._add_interrupt_pins(
                        self.pins[name + "/intr"], name, 0)
                    self.interrupt_controllers[name] = {'parent': parent,
                                                        'index': offset}
                    return offset + 1
        for p in net_pins:
            self.interrupt_pins[p] = {'controller': parent,
                                      'index': offset,
                                      'fullpath': p}
        return offset + 1

    def _add_concat_pins(self, name, parent, offset):
        num_ports = self.concat_cells[name]
        for i in range(num_ports):
            net = self.pins[name + "/In" + str(i)]
            offset = self._add_interrupt_pins(net, parent, offset)
        return offset

    def _assign_interrupts_gpio(self):
        for interrupt, val in self.interrupt_pins.items():
            block, _, pin = interrupt.rpartition('/')
            if block in self.ip_dict:
                self.ip_dict[block]['interrupts'][pin] = val
            if block in self.hierarchy_dict:
                self.hierarchy_dict[block]['interrupts'][pin] = val

        for gpio in self.gpio_dict.values():
            for connection in gpio['pins']:
                ip, _, pin = connection.rpartition('/')
                if ip in self.ip_dict:
                    self.ip_dict[ip]['gpio'][pin] = gpio
                elif ip in self.hierarchy_dict:
                    self.hierarchy_dict[ip]['gpio'][pin] = gpio

    def _build_hierarchy_dict(self):
        hierarchies = {k.rpartition('/')[0] for k in self.ip_dict.keys()
                       if k.count('/') > 0}
        self.hierarchy_dict = dict()
        for hier in hierarchies:
            self.hierarchy_dict[hier] = {
                'ip': dict(),
                'hierarchies': dict(),
                'interrupts': dict(),
                'gpio': dict(),
                'fullpath': hier,
            }
        for name, val in self.ip_dict.items():
            hier, _, ip = name.rpartition('/')
            if hier:
                self.hierarchy_dict[hier]['ip'][ip] = val

        for name, val in self.hierarchy_dict.items():
            hier, _, subhier = name.rpartition('/')
            if hier:
                self.hierarchy_dict[hier]['hierarchies'][subhier] = val


class PLMeta(type):
    """This method is the meta class for the PL.

    This is not a class for users. Hence there is no attribute or method
    exposed to users.

    Note
    ----
    If this metaclass is parsed on an unsupported architecture it will issue
    a warning and leave class variables undefined

    """
    _bitfile_name = BS_BOOT
    _timestamp = ""
    
    if CPU_ARCH_IS_SUPPORTED:
        _tcl = _TCL(TCL_BOOT)
        _ip_dict = _tcl.ip_dict
        _gpio_dict = _tcl.gpio_dict
        _interrupt_controllers = _tcl.interrupt_controllers
        _interrupt_pins = _tcl.interrupt_pins
        _hierarchy_dict = _tcl.hierarchy_dict
        _status = 1
        _server = None
        _host = None
        _remote = None
    else:
        warnings.warn("Pynq does not support the CPU Architecture: {}"
                      .format(CPU_ARCH), ResourceWarning)

    @property
    def bitfile_name(cls):
        """The getter for the attribute `bitfile_name`.

        Returns
        -------
        str
            The absolute path of the bitstream currently on PL.

        Note
        ----
        If this method is called on an unsupported architecture it will warn 
        and return an empty string

        """
        if not CPU_ARCH_IS_SUPPORTED:
            warnings.warn("Pynq does not support the CPU Architecture: {}"
                          .format(CPU_ARCH), ResourceWarning)
            return ""
        
        cls.client_request()
        cls.server_update()
        return cls._bitfile_name

    @property
    def timestamp(cls):
        """The getter for the attribute `timestamp`.

        Returns
        -------
        str
            Bitstream download timestamp.

        """
        cls.client_request()
        cls.server_update()
        return cls._timestamp

    @property
    def ip_dict(cls):
        """The getter for the attribute `ip_dict`.

        Returns
        -------
        dict
            The dictionary storing addressable IP instances; can be empty.

        """
        cls.client_request()
        cls.server_update()
        return cls._ip_dict

    @property
    def gpio_dict(cls):
        """The getter for the attribute `gpio_dict`.

        Returns
        -------
        dict
            The dictionary storing the PS GPIO pins.

        """
        cls.client_request()
        cls.server_update()
        return cls._gpio_dict

    @property
    def interrupt_controllers(cls):
        """The getter for the attribute `interrupt_controllers`.

        Returns
        -------
        dict
            The dictionary storing interrupt controller information.

        """
        cls.client_request()
        cls.server_update()
        return cls._interrupt_controllers

    @property
    def interrupt_pins(cls):
        """The getter for the attribute `interrupt_pins`.

        Returns
        -------
        dict
            The dictionary storing the interrupt endpoint information.

        """
        cls.client_request()
        cls.server_update()
        return cls._interrupt_pins

    @property
    def hierarchy_dict(cls):
        """The getter for the attribute `hierarchy_dict`

        Returns
        -------
        dict
            The dictionary containing the hierarchies in the design

        """
        cls.client_request()
        cls.server_update()
        return cls._hierarchy_dict

    def setup(cls, address=PL_SERVER_FILE, key=b'xilinx'):
        """Start the PL server and accept client connections.

        This method should not be used by the users directly. To check open
        pipes in the system, use `lsof | grep <address>` and
        `kill -9 <pid>` to manually delete them.

        Parameters
        ----------
        address : str
            The filename on the file system.
        key : bytes
            The authentication key of connection.

        Returns
        -------
        None

        """
        cls._server = Listener(address, family='AF_UNIX', authkey=key)

        while cls._status:
            cls._host = cls._server.accept()
            cls._host.send([cls._bitfile_name,
                            cls._timestamp,
                            cls._ip_dict,
                            cls._gpio_dict,
                            cls._interrupt_controllers,
                            cls._interrupt_pins,
                            cls._hierarchy_dict])
            cls._bitfile_name, cls._timestamp, \
                cls._ip_dict, cls._gpio_dict, \
                cls._interrupt_controllers, cls._interrupt_pins, \
                cls._hierarchy_dict, cls._status = cls._host.recv()
            cls._host.close()

        cls._server.close()

    def client_request(cls, address=PL_SERVER_FILE,
                       key=b'xilinx'):
        """Client connects to the PL server and receives the attributes.

        This method should not be used by the users directly. To check open
        pipes in the system, use `lsof | grep <address>` and
        `kill -9 <pid>` to manually delete them.

        Parameters
        ----------
        address : str
            The filename on the file system.
        key : bytes
            The authentication key of connection.

        Returns
        -------
        None

        """
        try:
            cls._remote = Client(address, family='AF_UNIX', authkey=key)
        except FileNotFoundError:
            raise ConnectionError(
                       "Could not connect to Pynq PL server") from None
        cls._bitfile_name, cls._timestamp, \
            cls._ip_dict, cls._gpio_dict, \
            cls._interrupt_controllers, \
            cls._interrupt_pins, \
            cls._hierarchy_dict = cls._remote.recv()

    def server_update(cls, continued=1):
        """Client sends the attributes to the server.

        This method should not be used by the users directly. To check open
        pipes in the system, use `lsof | grep <address>` and `kill -9 <pid>`
        to manually delete them.

        Parameters
        ----------
        continued : int
            Continue (1) or stop (0) the PL server.

        Returns
        -------
        None

        """
        cls._remote.send([cls._bitfile_name,
                          cls._timestamp,
                          cls._ip_dict,
                          cls._gpio_dict,
                          cls._interrupt_controllers,
                          cls._interrupt_pins,
                          cls._hierarchy_dict,
                          continued])
        cls._remote.close()

    def reset(cls):
        """Reset both all the dictionaries.

        This method must be called after a bitstream download.
        1. In case there is a `*.tcl` file, this method will reset the IP,
        GPIO , and interrupt dictionaries based on the tcl file.
        2. In case there is no `*.tcl` file, this method will simply clear
        the state information stored for all dictionaries.

        """
        cls.client_request()
        tcl_name = _get_tcl_name(cls._bitfile_name)
        if os.path.isfile(tcl_name):
            tcl = _TCL(tcl_name)
            cls._ip_dict = tcl.ip_dict
            cls._gpio_dict = tcl.gpio_dict
            cls._interrupt_controllers = tcl.interrupt_controllers
            cls._interrupt_pins = tcl.interrupt_pins
        else:
            cls.clear_dict()
        cls.server_update()

    def clear_dict(cls):
        """Clear all the dictionaries stored in PL.

        This method will clear all the related dictionaries, including IP
        dictionary, GPIO dictionary, etc.
        
        """
        cls._ip_dict.clear()
        cls._gpio_dict.clear()
        cls._interrupt_controllers.clear()
        cls._interrupt_pins.clear()
        cls._hierarchy_dict.clear()

    def load_ip_data(cls, ip_name, data):
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

        Returns
        -------
        None

        """
        cls.client_request()
        with open(data, 'rb') as bin_file:
            size = int((math.ceil(os.fstat(bin_file.fileno()).st_size /
                                  mmap.PAGESIZE)) * mmap.PAGESIZE)
            mmio = MMIO(cls._ip_dict[ip_name]['phys_addr'], size)
            buf = bin_file.read(size)
            mmio.write(0, buf)

        cls._ip_dict[ip_name]['state'] = data
        cls.server_update()


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


def _stop_server():
    """Entry point for the stop_pl_server.py script

    This function will attempt to stop the PL server in
    a controlled manner. It should not be called by user code

    """
    try:
        PL.client_request()
        PL.server_update(0)
    except:
        pass


def _start_server():
    """Entry point for the start_pl_server.py script

    Starts the PL server using the default server file.  Should
    not be called by user code - use PL.setup() instead to
    customise the server.

    """
    if os.path.exists(PL_SERVER_FILE):
        os.remove(PL_SERVER_FILE)
    PL.setup()


class Bitstream:
    """This class instantiates a programmable logic bitstream.

    Attributes
    ----------
    bitfile_name : str
        The absolute path of the bitstream.
    timestamp : str
        Timestamp when loading the bitstream. Format:
        year, month, day, hour, minute, second, microsecond

    """

    def __init__(self, bitfile_name):
        """Return a new Bitstream object.

        Users can either specify an absolute path to the bitstream file
        (e.g. '/home/xilinx/src/pynq/bitstream/base.bit'),
        or a relative path within an overlay folder.
        (e.g. 'base.bit' for base/base.bit).

        Note
        ----
        self.bitstream always stores the absolute path of the bitstream.

        Parameters
        ----------
        bitfile_name : str
            The bitstream absolute path or name as a string.
        """
        super().__init__()

        if not isinstance(bitfile_name, str):
            raise TypeError("Bitstream name has to be a string.")

        bitfile_abs = os.path.abspath(bitfile_name)
        bitfile_overlay_abs = os.path.join(PYNQ_PATH,
                                           'overlays',
                                           bitfile_name.replace('.bit', ''),
                                           bitfile_name)

        if os.path.isfile(bitfile_name):
            self.bitfile_name = bitfile_abs
        elif os.path.isfile(bitfile_overlay_abs):
            self.bitfile_name = bitfile_overlay_abs
        else:
            raise IOError('Bitstream file {} does not exist.'
                          .format(bitfile_name))

        self.timestamp = ''

    def download(self):
        """The method to download the bitstream onto PL.

        Note
        ----
        The class variables held by the singleton PL will also be updated. In
        addition, if this method is called on an unsupported architecture it
        will warn and return.

        Returns
        -------
        None

        """

        # Compose bitfile name, open bitfile
        with open(self.bitfile_name, 'rb') as f:
            buf = f.read()

        # Set is_partial_bitfile device attribute to 0
        with open(BS_IS_PARTIAL, 'w') as fd:
            fd.write('0')

        # Write bitfile to xdevcfg device
        with open(BS_XDEVCFG, 'wb') as f:
            f.write(buf)

        t = datetime.now()
        self.timestamp = "{}/{}/{} {}:{}:{} +{}".format(
                t.year, t.month, t.day,
                t.hour, t.minute, t.second, t.microsecond)

        # Update PL information
        PL.client_request()
        PL._bitfile_name = self.bitfile_name
        PL._timestamp = self.timestamp
        PL.clear_dict()
        PL.server_update()
