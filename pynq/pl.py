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
import abc
import struct
import numpy as np
from copy import deepcopy
from datetime import datetime
from multiprocessing.connection import Listener
from multiprocessing.connection import Client
from .mmio import MMIO
from .ps import Clocks, CPU_ARCH_IS_SUPPORTED, CPU_ARCH, ZU_ARCH, ZYNQ_ARCH

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"

# Overlay constants
PYNQ_PATH = os.path.dirname(os.path.realpath(__file__))
BS_BOOT = os.path.join(PYNQ_PATH, 'overlays', 'base', 'base.bit')
TCL_BOOT = os.path.join(PYNQ_PATH, 'overlays', 'base', 'base.tcl')

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


class _TCLABC(metaclass=abc.ABCMeta):
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
    # Key strings to search for in the TCL file
    family_pat = "create_project"
    family_regex = "(?P<family_str>xc.{2}).*"
    hier_use_pat = "create_hier_cell"
    hier_proc_def_pat = "proc {}".format(hier_use_pat)
    hier_def_regex = "create_hier_cell_(?P<name>[^ ]*)"
    hier_proc_end_pat = "}\n"
    hier_use_regex = ("create_hier_cell_(?P<hier_name>[^ ]*) ([^ ].*) " +
                      "(?P<instance_name>[^ ]*)\n")

    config_ip_pat = "CONFIG"
    config_ignore_pat = ".VALUE_SRC"
    config_regex = "CONFIG.(?P<key>.+?) \{(?P<value>.+?)\}"
    prop_start_pat = "set_property -dict ["
    prop_end_pat = "]"
    prop_name_regex = "\] \$(?P<instance_name>.+?)$"
    net_pat = "connect_bd_net -net"
    net_regex = "\[get_bd_pins (?P<name>[^]]+)\]"
    addr_pat = "create_bd_addr_seg"
    ip_pat = "create_bd_cell -type ip -vlnv "
    ip_regex = ("create_bd_cell -type ip -vlnv " +
                "(?P<author>.+?):" +
                "(?P<type>.+?):" +
                "(?P<ip_name>.+?):" +
                "(?P<version>.+?) " +
                "(?P<instance_name>[^ ]*)")
    ip_block_name_pat = "set block_name"
    ip_block_name_regex = "set block_name (?P<ip_block_name>.+)"
    ip_block_pat = "create_bd_cell -type module -reference "
    ip_block_regex = ("set (?P<instance_name>.*) " +
                      "\[create_bd_cell -type module -reference " +
                      "(?P<block_name>[\S]*) " +
                      "(?P<block_cell_name>[\S]*)\]")
    ignore_regex = "\s*(\#|catch).*"

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
        
        if not os.path.exists(tcl_name):
            raise IOError("Could not find specified .tcl file")

        # Regex Variable updated during processing
        addr_regex = ("create_bd_addr_seg " +
                      "-range (?P<range>0[xX][0-9a-fA-F]+) " +
                      "-offset (?P<addr>0[xX][0-9a-fA-F]+) " +
                      "\[get_bd_addr_spaces ")

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
        self.family = "xc7z"


        # Parsing state
        current_hier = ""
        last_concat = ""
        ip_block_name = ""
        in_prop = False
        gpio_idx = None
        gpio_dict = dict()
        hier_dict = dict()
        hier_dict[current_hier] = dict()

        with open(tcl_name, 'r') as f:
            for line in f:
                if re.match(self.ignore_regex, line):
                    continue

                # Matching IP configurations
                elif self.prop_start_pat in line:
                    in_prop = True

                # Matching IP block name
                elif self.ip_block_name_pat in line:
                    m = re.search(self.ip_block_name_regex, line, re.IGNORECASE)
                    ip_block_name = m.group("ip_block_name")

                # Matching Property declarations
                elif in_prop:
                    if (self.prop_end_pat in line and
                        re.search(self.prop_name_regex, line, re.IGNORECASE)):
                        m = re.search(self.prop_name_regex, line, re.IGNORECASE)
                        if m and gpio_idx is not None:
                            name = m.group("instance_name")
                            gpio_dict[name] = gpio_idx
                            gpio_idx = None
                        in_prop = False

                    elif self.config_ip_pat in line \
                            and self.config_ignore_pat not in line:
                        m1 = re.search(self.config_regex, line)
                        key = m1.group("key")
                        value = m1.group("value")
                        if key == "NUM_PORTS":
                            self.concat_cells[last_concat] = int(value)

                        elif key == 'DIN_FROM':
                            gpio_idx = int(value)

                        elif self._is_clk_divisor_line(line):
                            m2 = re.search(self.clk_odiv_regex, key)
                            pl_clk_idx = int(m2.group("pl_idx"))
                            odiv_idx = m2.group("odiv_idx")
                            divisor_name = 'divisor{}'.format(odiv_idx)
                            if pl_clk_idx not in self.pl_clks:
                                raise ValueError("Invalid PL CLK index")
                            self.clock_dict[pl_clk_idx][divisor_name] = int(value)
                                
                        elif self._is_clk_enable_line(line):
                            m3 = re.search(self.clk_enable_regex, key)
                            pl_clk_idx = int(m3.group("idx"))
                            if pl_clk_idx not in self.pl_clks:
                                raise ValueError("Invalid PL CLK index")
                            self.clock_dict[pl_clk_idx]['enable'] = int(value)
                    #    elif self._is_clk_divisor_line(line):
                    #        m2 = re.search(self.clk_odiv_regex, key)
                    #        idx = int(m2.group("idx"))
                    #        if idx not in self.clock_dict:
                    #            self.clock_dict[idx] = {'enable': 0,
                    #                                    'divisor0': 1,
                    #                                    'divisor1': 1}
                    #        divisor_name = 'divisor' + m2.group("div")
                    #        self.clock_dict[idx][divisor_name] = int(value)

                    #    elif self._is_clk_enable_line(line):
                    #        m3 = re.search(self.clk_enable_regex, key)
                    #        idx = int(m3.group("idx"))
                    #        if idx not in self.clock_dict:
                    #            self.clock_dict[idx] = {'enable': 0,
                    #                                    'divisor0': 1,
                    #                                    'divisor1': 1}
                    #        self.clock_dict[idx]['enable'] = int(value)

                # Match project/family declaration
                elif self.family_pat in line:
                    m = re.search(self.family_regex, line, re.IGNORECASE)
                    self.family = m.group("family_str")

                # Matching address segment
                elif self.addr_pat in line:
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
                elif self.hier_proc_def_pat in line:
                    m = re.search(self.hier_def_regex, line)
                    hier_name = m.group("name")
                    current_hier = hier_name
                    hier_dict[current_hier] = dict()

                elif self.hier_proc_end_pat == line:
                    current_hier = ""

                # Match hierarchical cell use/instantiation
                elif self.hier_use_pat in line:
                    m = re.search(self.hier_use_regex, line)
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
                elif self.ip_pat in line:
                    m = re.search(self.ip_regex, line)
                    ip_name = m.group("ip_name")
                    instance_name = m.group("instance_name")
                    if m.group("ip_name") == self.ps_ip_name:
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

                # Matching IP block cells in root design
                elif self.ip_block_pat in line:
                    m = re.search(self.ip_block_regex, line)
                    instance_name = m.group("instance_name")
                    if m.group('block_name') == '$block_name':
                        name = ip_block_name
                    else:
                        name = m.group('block_name')
                    ip_type = ':'.join(['user', 'ip', name, 'unknown'])
                    hier_dict[current_hier][instance_name] = ip_type

                # Matching nets
                elif self.net_pat in line:
                    mpins = re.findall(self.net_regex, line, re.IGNORECASE)
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

        if self.ps_name + "/" + self.irq_pin_name in self.pins:
            ps_irq_net = self.pins[
                self.ps_name + "/" + self.irq_pin_name]
            self._add_interrupt_pins(ps_irq_net, "", 0)

        if self.ps_name + "/" + self.gpio_pin_name in self.pins:
            ps_gpio_net = self.pins[
                self.ps_name + "/" + self.gpio_pin_name]
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


class _TCLUltrascale(_TCLABC):
    """Intermediate class to extract information from a TCL configuration
    file for Ultrascale devices. 

    """
    ps_ip_name = "zynq_ultra_ps_e"
    irq_pin_offset = 0
    irq_pin_name = "pl_ps_irq{}".format(irq_pin_offset)
    gpio_pin_name = "emio_gpio_o"
    family_name = "xczu"

    clk_odiv_regex = 'PSU__CRL_APB__PL(?P<pl_idx>.+?)' + \
                     '_REF_CTRL__DIVISOR(?P<odiv_idx>.+?)'
    clk_enable_regex = 'PSU__FPGA_PL(?P<idx>.+?)_ENABLE'

    pl_clks = [0, 1, 2, 3]
    def __init__(self, tcl_name):
        """Returns an Ultrascale-specific map built from the supplied tcl file

        Parameters
        ---------
        tcl_name : str
            The tcl filename to parse. This is opened directly so should be
            fully qualified

        """
        self.clock_dict = dict()
        for pl_clk in self.pl_clks:
            self.clock_dict[pl_clk] = dict()
            self.clock_dict[pl_clk]['enable'] = 0
            self.clock_dict[pl_clk]["divisor0"] = 10
            self.clock_dict[pl_clk]["divisor1"] = 1
        self.clock_dict[0]['enable'] = 1
        super().__init__(tcl_name)
        
    def _is_clk_enable_line(self, line):
        """Returns True if line contains a declaration to enable a PL 
        clock otherwise False

        Parameters
        ---------
        line : str
            The string from a line in a tcl file
        """        
        return "PSU__FPGA_PL" in line \
            and "ENABLE" in line

    def _is_clk_divisor_line(self, line):
        """Returns True if line contains a declaration to set a PL clock
        divisor otherwise False

        Parameters
        ---------
        line : str
            The string from a line in a tcl file
        """
        return "PSU__CRL_APB__PL" in line \
            and "REF_CTRL__DIVISOR" in line

class _TCLZynq(_TCLABC):
    """Intermediate class to extract information from a TCL configuration
    file for  devices. 

    """
    ps_ip_name = "processing_system7"
    irq_pin_offset = 0
    irq_pin_name = "IRQ_F2P"
    gpio_pin_name = "GPIO_O"
    family_name = "xc7z"
    
    clk_odiv_regex = 'PCW_FCLK(?P<pl_idx>.+?)_PERIPHERAL_DIVISOR' \
                     '(?P<odiv_idx>[01])$'
    clk_enable_regex = 'PCW_FPGA_FCLK(?P<idx>.+?)_ENABLE'

    pl_clks = [0, 1 ,2, 3]
    def __init__(self, tcl_name):
        """Returns an Ultrascale-specific map built from the supplied tcl file

        Parameters
        ---------
        tcl_name : str
            The tcl filename to parse. This is opened directly so should be
            fully qualified

        """
        self.clock_dict = dict()
        for pl_clk in self.pl_clks:
            self.clock_dict[pl_clk] = dict()
            self.clock_dict[pl_clk]['enable'] = 0
            self.clock_dict[pl_clk]["divisor0"] = 10
            self.clock_dict[pl_clk]["divisor1"] = 1
        super().__init__(tcl_name)

    def _is_clk_enable_line(self, line):
        """Returns True if line contains a declaration to enable a PL 
        clock otherwise False

        Parameters
        ---------
        line : str
            The string from a line in a tcl file
        """        
        return "FCLK" in line and \
            "ENABLE" in line

    def _is_clk_divisor_line(self, line):
        """Returns True if line contains a declaration to set a PL clock
        divisor otherwise False

        Parameters
        ---------
        line : str
            The string from a line in a tcl file
        """
        return "FCLK" in line and \
            "PERIPHERAL_DIVISOR" in line

class _TCL(_TCLUltrascale if CPU_ARCH == ZU_ARCH else _TCLZynq):
    """Helper class to extract information from a TCL configuration
    file

    Note
    ----
    This class requires the absolute path of the '.tcl' file.
    """
    pass


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
        if os.path.exists(TCL_BOOT):
            _tcl = _TCL(TCL_BOOT)
            _ip_dict = _tcl.ip_dict
            _gpio_dict = _tcl.gpio_dict
            _interrupt_controllers = _tcl.interrupt_controllers
            _interrupt_pins = _tcl.interrupt_pins
            _hierarchy_dict = _tcl.hierarchy_dict
        else:
            _tcl = None
            _ip_dict = {}
            _gpio_dict = {}
            _interrupt_controllers = {}
            _interrupt_pins = {}
            _hierarchy_dict = {}
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

    def client_request(cls, address=PL_SERVER_FILE, key=b'xilinx'):
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
        cls.client_request()
        with open(data, 'rb') as bin_file:
            size = os.fstat(bin_file.fileno()).st_size
            target_size = cls._ip_dict[ip_name]['addr_range']
            if size > target_size:
                raise RuntimeError("Binary file too big for IP")
            mmio = MMIO(cls._ip_dict[ip_name]['phys_addr'], target_size)
            buf = bin_file.read(size)
            mmio.write(0, buf)
            if zero and size < target_size:
                mmio.write(size, b'\x00' * (target_size - size))

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

class _Bitstream:
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
        self._download()
        self._update_pl()
        
    def _update_pl(self):
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
        
class _BitstreamZynq(_Bitstream):
    """This class instantiates a programmable logic bitstream for Zynq Devices

    Note
    ----
    This class inherits from the _Bitstream class

    """

    BS_IS_PARTIAL = "/sys/devices/soc0/amba/f8007000.devcfg/is_partial_bitstream"
    BS_XDEVCFG = "/dev/xdevcfg"

    def _download(self):
        """The Zynq-specific method to download the bitstream onto PL.

        Note
        ----
        The class variables held by the singleton PL will also be updated.

        Returns
        -------
        None

        """
        if not os.path.exists(self.BS_XDEVCFG):
            raise RuntimeError("Could not find programmable device")
        
        # Compose bitfile name, open bitfile
        with open(self.bitfile_name, 'rb') as f:
            buf = f.read()

        # Set is_partial_bitfile device attribute to 0
        with open(self.BS_IS_PARTIAL, 'w') as fd:
            fd.write('0')

        # Write bitfile to xdevcfg device
        with open(self.BS_XDEVCFG, 'wb') as f:
            f.write(buf)


class _BitstreamUltrascale(_Bitstream):
    """This class instantiates a programmable logic bitstream for Zynq
    Ultrascale Devices

    Note
    ----
    This class inherits from the _Bitstream class

    """
    BS_FPGA_MAN = "/sys/class/fpga_manager/fpga0/firmware"
    
    def _download(self):
        """The Zynq-specific method to download the bitstream onto PL.

        Note
        ----
        The class variables held by the singleton PL will also be updated.

        Returns
        -------
        None

        """
        if not os.path.exists(self.BS_FPGA_MAN):
            raise RuntimeError("Could not find programmable device")         

        bin_base = os.path.basename(self.bitfile_name).replace('.bit', '.bin')
        binfile_name = '/lib/firmware/' + bin_base
        self._convert_bit_to_bin(self.bitfile_name, binfile_name)
        with open(self.BS_FPGA_MAN, 'w') as fd:
            fd.write(bin_base)

    def _convert_bit_to_bin(self, bit_file, bin_file):
        """The method to convert a .bit file to .bin file.

        A .bit file is generated by Vivado, but .bin files are needed
        by the Zynq Ultrascale FPGA manager driver. Users must specify
        the absolute path to the source .bit file, and the destination
        .bin file and have read/write access to both paths. 

        Note
        ----
        Imlemented based on: https://blog.aeste.my/?p=2892

        Parameters
        ----------
        bit_file: str
            The bitstream absolute source path

        bin_file: str
            The bitstream absolute desination path

        Returns
        -------
        None

        """
        with open(bit_file, 'rb') as f:
            d = self._parse_bitstream_header(f)
        bit = np.frombuffer(d['data'], dtype=np.int32, offset = 0) 
        bin = bit.byteswap()
        bin.tofile(bin_file, "")

    def _parse_bitstream_header(self, bitf):
        """The method to parse the header of a bitstream

        Parameters
        ----------
        bitf:
            The open file object continaing a valid .bit file

        Returns
        -------
            A dictionary containing the keys:
                "design": str
                    The Vivado project name that generated the bitstream
                    
                "version": str
                    The Vivado tool version that generated the bitstream
                         
                "part": str
                    The Xilinx part name that the bitstream targets
                
                "date": str
                    The date the bitstream was compiled on
                
                "time": str
                    The time the bitstream finished compilation

                "length": int
                    Total length of the bitstream (in bytes)
                    
                "data": binary
                    binary data in .bit file format
                    
        Note
        ----
        Imlemented based on: https://blog.aeste.my/?p=2892
        
        """
        finished = False
        offset = 0
        length = 0
        contents = bitf.read()
        bit_dict = {}

        # Strip the (2+n)-byte first field (2-bit length, n-bit data)
        length = struct.unpack('>h', contents[offset:offset+2])[0]
        offset += 2 + length
        
        # Strip a two-byte unknown field (ususally 1)
        # Theory: Describes the length of the field descriptor?
        length = struct.unpack('>h', contents[offset:offset+2])[0]
        offset += 2

        # Strip the remaining headers. 0x65 signals the bit data field
        while not finished:
            desc = contents[offset]
            offset += 1
            
            if(desc != 0x65):
                length = struct.unpack('>h', contents[offset:offset+2])[0]
                offset += 2
                fmt = ">{}s".format(length)
                data = struct.unpack(fmt, contents[offset:offset+length])[0]
                data = data.decode('ascii')[:-1]
                offset += length

            if(desc == 0x61):
                s = data.split(";")
                bit_dict['design'] = s[0]
                bit_dict['version'] = s[2]
            elif(desc == 0x62):
                bit_dict['part'] = data
            elif(desc == 0x63):
                bit_dict['date'] = data
            elif(desc == 0x64):
                bit_dict['time'] = data
            elif(desc == 0x65):
                finished = True
                length = struct.unpack('>i', contents[offset:offset+4])[0]
                offset += 4
                # Expected length values can be verified in the chip TRM
                bit_dict['length'] = str(length)
                if length + offset != len(contents):
                    raise RuntimeError("Invalid length found")
                bit_dict['data'] = contents[offset:offset+length]
            else:
                raise RuntimeError("Unknown field: {}".format(hex(desc)))
        return bit_dict

class Bitstream(_BitstreamUltrascale if CPU_ARCH == ZU_ARCH \
                else _BitstreamZynq):
    """This wrapper class instantiates a programmable logic bitstream for Pynq
    Devices

    Note
    ----
    This class inherits from the _BitstreamZynq or _BitstreamUltrascale
    classes depending on the value of CPU_ARCH from ps.py

    """
    pass
