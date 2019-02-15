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
import warnings
import abc
from xml.etree import ElementTree
from copy import deepcopy
from datetime import datetime
import struct
import numpy as np
from multiprocessing.connection import Listener
from multiprocessing.connection import Client
from .mmio import MMIO
from .ps import CPU_ARCH_IS_SUPPORTED, CPU_ARCH, ZYNQ_ARCH, ZU_ARCH

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"

# Overlay constants
PYNQ_PATH = os.path.dirname(os.path.realpath(__file__))
PL_SERVER_FILE = os.path.join(PYNQ_PATH, '.log')


def get_tcl_name(bitfile_name):
    """This method returns the name of the tcl file.

    For example, the input "/home/xilinx/pynq/overlays/base/base.bit" will
    lead to the result "/home/xilinx/pynq/overlays/base/base.tcl".

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


def get_hwh_name(bitfile_name):
    """This method returns the name of the hwh file.

    For example, the input "/home/xilinx/pynq/overlays/base/base.bit" will
    lead to the result "/home/xilinx/pynq/overlays/base/base.hwh".

    Parameters
    ----------
    bitfile_name : str
        The absolute path of the .bit file.

    Returns
    -------
    str
        The absolute path of the .hwh file.

    """
    return os.path.splitext(bitfile_name)[0] + '.hwh'


def string2int(a):
    """Convert a hex or decimal string into an int.

    Parameters
    ----------
    a : string
        The input string representation of the number.

    Returns
    -------
    int
        The decimal number.

    """
    return int(a, 16 if a.startswith('0x') else 10)


def clear_state(dict_in):
    """Clear the state information for a given dictionary.

    Parameters
    ----------
    dict_in : dict
        Input dictionary to be cleared.

    """
    if type(dict_in) is dict:
        for i in dict_in:
            if 'state' in dict_in[i]:
                dict_in[i]['state'] = None
    return dict_in


def locate_overlay():
    """Locate an overlay in the overlays folder.

    Return the base overlay by default; if not found, return the first overlay
    found.

    Returns
    -------
    str
        The name of the first overlay found.

    """
    if os.path.isdir(os.path.join(PYNQ_PATH, 'overlays', 'base')):
        return 'base'
    for i in os.listdir(os.path.join(PYNQ_PATH, 'overlays')):
        if os.path.isdir(os.path.join(PYNQ_PATH, 'overlays', i)) and \
                not i.startswith('_'):
            return i
    return ''


OVERLAY_BOOT = locate_overlay()
BS_BOOT = os.path.join(PYNQ_PATH, 'overlays',
                       OVERLAY_BOOT, OVERLAY_BOOT + '.bit')
TCL_BOOT = get_tcl_name(BS_BOOT)
HWH_BOOT = get_hwh_name(BS_BOOT)


class _TCLABC(metaclass=abc.ABCMeta):
    """Helper Class to extract information from a TCL configuration file.

    Note
    ----
    This class requires the absolute path of the '.tcl' file.

    Attributes
    ----------
    ip_dict : dict
        All the addressable IPs from PS7. Key is the name of the IP; value is
        a dictionary mapping the physical address, address range, IP type,
        memory segment ID, the state associated with that IP, any
        interrupts and GPIO pins attached to the IP and the full path to the
        IP in the block design:
        {str: {'phys_addr' : int, 'addr_range' : int,\
               'type' : str, 'mem_id' : str, 'state' : str,\
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
    # common key strings to search for in the TCL file
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
    prop_end_inst_regex = "\] \$(?P<instance_name>.+?)$"
    prop_end_nets_regex = "\] \[.*\]"
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

    # following members will be overridden in the child classes
    ps_ip_name = ""
    irq_pin_offset = 0
    irq_pin_name = ""
    gpio_pin_name = ""
    clk_odiv_regex = ""
    clk_enable_regex = ""
    pl_clks = []
    clock_dict = {}

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
        # Regex Variable updated during processing
        addr_regex = "create_bd_addr_seg " +\
                     "-range (?P<range>0[xX][0-9a-fA-F]+) " +\
                     "-offset (?P<addr>0[xX][0-9a-fA-F]+) " +\
                     "\[get_bd_addr_spaces ([^ ].*) " +\
                     "\[get_bd_addr_segs (?P<hier>.+?)\] " +\
                     "(?P<name>[A-Za-z0-9_]+)"

        # Initialize result variables
        self.partial = True
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
                    m = re.search(self.ip_block_name_regex, line,
                                  re.IGNORECASE)
                    ip_block_name = m.group("ip_block_name")

                # Matching Property declarations
                elif in_prop:
                    if (re.search(self.prop_end_inst_regex,
                                  line, re.IGNORECASE) or
                            re.search(self.prop_end_nets_regex,
                                      line, re.IGNORECASE)):
                        m = re.search(self.prop_end_inst_regex, line,
                                      re.IGNORECASE)
                        if m and gpio_idx is not None:
                            name = m.group("instance_name")
                            if current_hier == "":
                                hier_name = name
                            else:
                                hier_name = "{}/{}".format(current_hier, name)
                            gpio_dict[hier_name] = gpio_idx
                            gpio_idx = None
                        in_prop = False

                    elif self.config_ip_pat in line \
                            and self.config_ignore_pat not in line:
                        m1 = re.search(self.config_regex, line)
                        if m1:
                            key = m1.group("key")
                            value = m1.group("value")
                            if key == "NUM_PORTS":
                                self.concat_cells[last_concat] = int(value)

                            elif key == 'DIN_FROM':
                                gpio_idx = int(value)

                            elif self.is_clk_divisor_line(line):
                                m2 = re.search(self.clk_odiv_regex, key)
                                pl_clk_idx = int(m2.group("pl_idx"))
                                odiv_idx = m2.group("odiv_idx")
                                divisor_name = 'divisor{}'.format(odiv_idx)
                                if pl_clk_idx not in self.pl_clks:
                                    raise ValueError("Invalid PL CLK index")
                                self.clock_dict[pl_clk_idx][
                                    divisor_name] = int(value)

                            elif self.is_clk_enable_line(line):
                                m3 = re.search(self.clk_enable_regex, key)
                                pl_clk_idx = int(m3.group("idx"))
                                if pl_clk_idx not in self.pl_clks:
                                    raise ValueError("Invalid PL CLK index")
                                self.clock_dict[pl_clk_idx][
                                    'enable'] = int(value)

                # Matching address segment
                elif self.addr_pat in line:
                    m = re.search(addr_regex, line, re.IGNORECASE)
                    if m:
                        for ip_dict0 in hier_dict:
                            for ip_name, ip_type in \
                                    hier_dict[ip_dict0].items():
                                ip = (ip_dict0 + '/' + ip_name).lstrip('/')
                                if m.group("hier").startswith(ip + '/'):
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
                                    self.ip_dict[ip]['mem_id'] = m.group('name')

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
                        self.partial = False
                        self.ps_name = instance_name
                        addr_regex = "create_bd_addr_seg " +\
                                     "-range (?P<range>0[xX][0-9a-fA-F]+) " +\
                                     "-offset (?P<addr>0[xX][0-9a-fA-F]+) " +\
                                     "\[get_bd_addr_spaces " +\
                                     instance_name + "/Data\] " +\
                                     "\[get_bd_addr_segs (?P<hier>.+?)\] " +\
                                     "(?P<name>[A-Za-z0-9_]+)"
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
            if (name + "/In" + str(i)) in self.pins:
                net = self.pins[name + "/In" + str(i)]
                offset = self._add_interrupt_pins(net, parent, offset)
            else:
                offset = 1
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
        lasthierarchies = {}
        hierarchies = {k.rpartition('/')[0] for k in self.ip_dict.keys()
                       if k.count('/') > 0}
        while lasthierarchies != hierarchies:
            parents = {k.rpartition('/')[0] for k in hierarchies 
                       if k.count('/') > 0}
            lasthierarchies = hierarchies
            hierarchies.update(parents)
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
    """Intermediate class to extract information from a TCL configuration.

    This class works for the Zynq Ultrascale devices.
    The following additional attributes are added to the ABC class.

    Attributes
    ----------
    clock_dict : dict
        All the PL clocks that can be controlled by the PS. Key is the index
        of the clock (e.g., 0 for the first clock);
        value is a dictionary mapping the divisor values and the enable flag
        (1 for enabled, and 0 for disabled):
        {index: {'divisor0' : int, 'divisor1' : int, 'enable' : int}}

    """
    ps_ip_name = "zynq_ultra_ps_e"
    irq_pin_offset = 0
    irq_pin_name = "pl_ps_irq{}".format(irq_pin_offset)
    gpio_pin_name = "emio_gpio_o"
    clk_odiv_regex = 'PSU__CRL_APB__PL(?P<pl_idx>.+?)' \
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

    def is_clk_enable_line(self, line):
        """Returns True if line contains a declaration to enable a PL
        clock otherwise False
        Parameters
        ---------
        line : str
            The string from a line in a tcl file
        """
        return "PSU__FPGA_PL" in line and "ENABLE" in line

    def is_clk_divisor_line(self, line):
        """Returns True if line contains a declaration to set a PL clock
        divisor otherwise False
        Parameters
        ---------
        line : str
            The string from a line in a tcl file
        """
        return "PSU__CRL_APB__PL" in line and "REF_CTRL__DIVISOR" in line


class _TCLZynq(_TCLABC):
    """Intermediate class to extract information from a TCL configuration.

    This class works for the Zynq devices.
    The following additional attributes are added to the ABC class.

    Attributes
    ----------
    clock_dict : dict
        All the PL clocks that can be controlled by the PS. Key is the index
        of the clock (e.g., 0 for the first clock);
        value is a dictionary mapping the divisor values and the enable flag
        (1 for enabled, and 0 for disabled):
        {index: {'divisor0' : int, 'divisor1' : int, 'enable' : int}}

    """
    ps_ip_name = "processing_system7"
    irq_pin_offset = 0
    irq_pin_name = "IRQ_F2P"
    gpio_pin_name = "GPIO_O"
    clk_odiv_regex = 'PCW_FCLK(?P<pl_idx>.+?)_PERIPHERAL_DIVISOR' \
                     '(?P<odiv_idx>[01])$'
    clk_enable_regex = 'PCW_FPGA_FCLK(?P<idx>.+?)_ENABLE'
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

    def is_clk_enable_line(self, line):
        """Returns True if line contains a declaration to enable a PL
        clock otherwise False
        Parameters
        ---------
        line : str
            The string from a line in a tcl file
        """
        return "FCLK" in line and "ENABLE" in line

    def is_clk_divisor_line(self, line):
        """Returns True if line contains a declaration to set a PL clock
        divisor otherwise False
        Parameters
        ---------
        line : str
            The string from a line in a tcl file
        """
        return "FCLK" in line and "PERIPHERAL_DIVISOR" in line


if CPU_ARCH == ZU_ARCH:
    TCL = _TCLUltrascale
elif CPU_ARCH == ZYNQ_ARCH:
    TCL = _TCLZynq
else:
    TCL = _TCLABC
    warnings.warn("PYNQ does not support the CPU Architecture: {}"
                  .format(CPU_ARCH), UserWarning)


class _HWHABC(metaclass=abc.ABCMeta):
    """Helper Class to extract information from a HWH configuration file

    Note
    ----
    This class requires the absolute path of the '.hwh' file.

    Attributes
    ----------
    ip_dict : dict
        All the addressable IPs from PS7. Key is the name of the IP; value is
        a dictionary mapping the physical address, address range, IP type,
        memory segment ID, the state associated with that IP, any
        interrupts and GPIO pins attached to the IP and the full path to the
        IP in the block design:
        {str: {'phys_addr' : int, 'addr_range' : int,\
               'type' : str, 'mem_id' : str, 'state' : str,\
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
    family_ps = ""
    family_irq = ""
    family_gpio = ""

    def __init__(self, hwh_name):
        """Returns a map built from the supplied hwh file

        Parameters
        ---------
        hwh_name : str
            The hwh filename to parse.

        Note
        ----
        If this method is called on an unsupported architecture it will warn
        and return without initialization

        """
        tree = ElementTree.parse(hwh_name)
        self.root = tree.getroot()
        self.partial = True
        self.intc_names = []
        self.interrupt_controllers = {}
        self.concat_cells = {}
        self.nets = {}
        self.pins = {}
        self.hierarchy_dict = {}
        self.interrupt_pins = {}
        self.ps_name = ""
        self.ip_dict = {}
        self.gpio_dict = {}
        self.clock_dict = {}
        self.instance2attr = {i.get('INSTANCE'): (
            i.get('FULLNAME').lstrip('/'),
            i.get('VLNV'),
            i.findall("./PARAMETERS/*[@NAME][@VALUE]"),
            i.findall(".//REGISTERS/*[@NAME]"))
            for i in self.root.iter("MODULE")}

        self.init_partial_ip_dict()
        for mod in self.root.iter("MODULE"):
            mod_type = mod.get('MODTYPE')
            full_path = mod.get('FULLNAME').lstrip('/')
            if mod_type == self.family_ps:
                self.ps_name = mod.get('INSTANCE')
                self.init_clk_dict(mod)
                self.init_full_ip_dict(mod)
            elif mod_type == 'xlconcat':
                self.concat_cells[full_path] = mod.find(
                    ".//*[@NAME='NUM_PORTS']").get('VALUE')
            elif mod_type == 'axi_intc':
                self.intc_names.append(full_path)

            self.match_nets(mod, full_path)

        self.match_ports()
        self.match_pins()
        self.add_gpio()
        self.init_interrupts()
        self.init_hierachy_dict()
        self.assign_interrupts_gpio()

    def init_partial_ip_dict(self):
        """Get the IP address blocks exposed for a certain block design.

        This method will only work for partial block designs.

        """
        self._parse_ip_dict(self.root, 'MASTERBUSINTERFACE')

    def init_full_ip_dict(self, mod):
        """Get the IP address blocks exposed at the top level block design.

        This method will only work on those addressable IPs for full block
        designs. Since we know this is a full block design, we can stop
        any on-going parsing and discard any partial IP dict.

        Note that if the hwh file has been generated from a partial
        reconfiguration project, the main hwh file may not contain
        the complete information about the block design. In that case, we may
        have duplicated instance names for multiple physical addresses. We
        assume the corresponding partial region is a black box and use the
        memory interface IDs to differentiate them in the IP dict, because we
        don't know what instances are connected to those interfaces yet.
        For full bitstream designs, this is not likely to happen.

        Parameters
        ----------
        mod : Element
            The current PS instance under parsing.

        """
        self.partial = False
        self.ip_dict = {}
        self._parse_ip_dict(mod, 'SLAVEBUSINTERFACE')

    def _parse_ip_dict(self, mod, mem_intf_id):
        to_pop = set()
        for i in mod.iter("MEMRANGE"):
            if i.get('INSTANCE') in self.instance2attr:
                full_name, vlnv, pars, regs = self.instance2attr[
                    i.get('INSTANCE')]
                intf_id = i.get(mem_intf_id)
                if full_name in self.ip_dict and \
                        self.ip_dict[full_name]['mem_id'] and intf_id:
                    rename = full_name + '/' + self.ip_dict[full_name]['mem_id']
                    self.ip_dict[rename] = deepcopy(self.ip_dict[full_name])
                    self.ip_dict[rename]['fullpath'] = rename
                    to_pop.add(full_name)
                    full_name += '/' + intf_id
                elif vlnv.split(':')[:2] == ['xilinx.com', 'module_ref']:
                    full_name += '/' + intf_id

                self.ip_dict[full_name] = {}
                self.ip_dict[full_name]['fullpath'] = full_name
                self.ip_dict[full_name]['type'] = vlnv
                self.ip_dict[full_name]['state'] = None
                high_addr = int(i.get('HIGHVALUE'), 16)
                base_addr = int(i.get('BASEVALUE'), 16)
                addr_range = high_addr - base_addr + 1
                self.ip_dict[full_name]['addr_range'] = addr_range
                self.ip_dict[full_name]['phys_addr'] = base_addr
                self.ip_dict[full_name]['mem_id'] = intf_id
                self.ip_dict[full_name]['gpio'] = {}
                self.ip_dict[full_name]['interrupts'] = {}
                self.ip_dict[full_name]['parameters'] = {j.get('NAME'):
                                                         j.get('VALUE')
                                                         for j in pars}
                self.ip_dict[full_name]['registers'] = {j.get('NAME'): {
                        'address_offset': string2int(j.find(
                            './PROPERTY/[@NAME="ADDRESS_OFFSET"]').get(
                            'VALUE')),
                        'size': string2int(j.find(
                            './PROPERTY/[@NAME="SIZE"]').get(
                            'VALUE')),
                        'access': j.find('./PROPERTY/[@NAME="ACCESS"]').get(
                                'VALUE'),
                        'description': j.find(
                            './PROPERTY/[@NAME="DESCRIPTION"]').get('VALUE'),
                        'fields': {k.get('NAME'): {
                            'bit_offset': string2int(k.find(
                                './PROPERTY/[@NAME="BIT_OFFSET"]').get(
                                'VALUE')),
                            'bit_width': string2int(k.find(
                                './PROPERTY/[@NAME="BIT_WIDTH"]').get(
                                'VALUE')),
                            'description': j.find(
                                './PROPERTY/[@NAME="DESCRIPTION"]').get(
                                    'VALUE'),
                            'access': k.find(
                                './PROPERTY/[@NAME="ACCESS"]').get('VALUE')}
                            for k in j.findall('./FIELDS/FIELD/[@NAME]')}}
                    for j in regs}
        for i in to_pop:
            self.ip_dict.pop(i)

    def match_nets(self, mod, full_path):
        """Matching all the nets in the modules from the HWH file.

        This method will arrange all the nets. Note that since we
        have a signal name for each net, we will use that as the key to index
        the nets dictionary.

        Parameters
        ----------
        mod : Element
            The current XML element under parsing.
        full_path : str
            The full path of the given module.

        """
        for blk in mod.iter("PORT"):
            ports = [full_path + '/' + blk.get('NAME')]
            signame = blk.get('SIGNAME')
            if signame in self.nets:
                self.nets[signame] |= set(ports)
            else:
                self.nets[signame] = set(ports)

    def match_ports(self):
        """Connecting all the ports to the internal signals.

        This method will hook up internal and external pins by checking the
        net names.

        """
        external_ports = self.root.find('./EXTERNALPORTS')
        for port in external_ports.iter("PORT"):
            name_list = [port.get('NAME')]
            signame = port.get('SIGNAME')
            if signame in self.nets:
                self.nets[signame] |= set(name_list)
            else:
                self.nets[signame] = set(name_list)

    def match_pins(self):
        """Matching all the pins from the HWH file.

        This method will arrange all the pins. The pins dictionary stores
        the reverse mapping, which maps each pin to the name of the
        connected signal.

        """
        for signame, pin_set in self.nets.items():
            for p in pin_set:
                self.pins[p] = signame

    def init_interrupts(self):
        """Prepare the interrupt dictionaries.

        This method will prepare both the interrupt controller dictionary
        and the interrupt pins dictionary.

        """
        if self.ps_name + "/" + self.family_irq in self.pins:
            ps_irq_net = self.pins[
                self.ps_name + "/" + self.family_irq]
            self._add_interrupt_pins(ps_irq_net, "", 0)

    def _add_interrupt_pins(self, net, parent, offset):
        net_pins = self.nets[net] if net else set()
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
        num_ports = int(self.concat_cells[name])
        for i in range(num_ports):
            net = self.pins[name + "/In" + str(i)]
            offset = self._add_interrupt_pins(net, parent, offset)
        return offset

    def add_gpio(self):
        """Get the PS GPIO blocks exposed at the top level block design.

        """
        for it in self.root.iter('MODULE'):
            mod = it.find(
                ".//PORTS//*[@DIR='I']"
                "//*[@INSTANCE='{0}'][@PORT='{1}']../../../..".format(
                    self.ps_name, self.family_gpio))
            if mod is not None:
                din = int(mod.find(".//*[@NAME='DIN_FROM']").get('VALUE'))
                for p in mod.iter("PORT"):
                    if p.get('DIR') == 'O':
                        signame = p.get('SIGNAME')
                        net_set = self.nets[signame]
                        gpio_name = ''
                        for i in net_set:
                            m = re.match('(.*)/Dout', i)
                            if m is not None:
                                gpio_name = m.group(1)
                                break
                        if gpio_name == '':
                            raise ValueError("Cannot get GPIO name */Dout.")
                        self.gpio_dict[gpio_name] = {}
                        self.gpio_dict[gpio_name]['state'] = None
                        self.gpio_dict[gpio_name]['pins'] = net_set
                        self.gpio_dict[gpio_name]['index'] = din

    def init_hierachy_dict(self):
        """Initialize the hierachical dictionary.

        """
        lasthierarchies = {}
        hierarchies = {k.rpartition('/')[0] for k in self.ip_dict.keys()
                       if k.count('/') > 0}
        while lasthierarchies != hierarchies:
            parents = {k.rpartition('/')[0] for k in hierarchies
                       if k.count('/') > 0}
            lasthierarchies = hierarchies
            hierarchies.update(parents)
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

    def assign_interrupts_gpio(self):
        """Assign interrupts and gpio entries to the dictionaries.

        """
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

    def init_clk_dict(self, mod):
        """Initialize the clock dictionary.

        Parameters
        ----------
        mod : Element
            The current XML element under parsing.

        """
        for i in range(4):
            self.clock_dict[i] = dict()
            self.clock_dict[i]['enable'] = self.find_clock_enable(mod, i)
            for j in range(2):
                self.clock_dict[i]['divisor{}'.format(j)] = \
                    self.find_clock_divisor(mod, i, j)


class _HWHZynq(_HWHABC):
    """Helper Class to extract information from a HWH configuration file

    This class works for the Zynq devices.

    """
    family_ps = "processing_system7"
    family_irq = "IRQ_F2P"
    family_gpio = "GPIO_O"

    def find_clock_divisor(self, mod, clk_id, div_id):
        """Return the clock divisor for the given clock ID.

        Parameters
        ----------
        mod : Element
            The current XML element under parsing.
        clk_id : int
            The ID of the PL clock, can be 0 - 3.
        div_id : int
            The ID of the clock divisor, can be 0 - 1.

        Returns
        -------
        int
            The clock divisor value in decimal.

        """
        clk_odiv = 'PCW_FCLK{0}_PERIPHERAL_DIVISOR{1}'.format(clk_id, div_id)
        return int(mod.find(
            "./PARAMETERS/*[@NAME='{0}']".format(clk_odiv)).get('VALUE'))

    def find_clock_enable(self, mod, clk_id):
        """Return the clock enable for the given clock ID.

        Parameters
        ----------
        mod : Element
            The current XML element under parsing.
        clk_id : int
            The ID of the PL clock, can be 0 - 3.

        Returns
        -------
        int
            The clock enable value in decimal (1 means enabled).

        """
        clk_enable = 'PCW_FPGA_FCLK{0}_ENABLE'.format(clk_id)
        return int(mod.find(
            "./PARAMETERS/*[@NAME='{0}']".format(clk_enable)).get('VALUE'))


class _HWHUltrascale(_HWHABC):
    """Helper Class to extract information from a HWH configuration file

    This class works for the Zynq Ultrascale devices.

    """
    family_ps = "zynq_ultra_ps_e"
    family_irq = "pl_ps_irq0"
    family_gpio = "emio_gpio_o"

    def find_clock_divisor(self, mod, clk_id, div_id):
        """Return the clock divisor for the given clock ID.

        Parameters
        ----------
        mod : Element
            The current XML element under parsing.
        clk_id : int
            The ID of the PL clock, can be 0 - 3.
        div_id : int
            The ID of the clock divisor, can be 0 - 1.

        Returns
        -------
        int
            The clock divisor value in decimal.

        """
        clk_odiv = 'PSU__CRL_APB__PL{0}_REF_CTRL__DIVISOR{1}'.format(
            clk_id, div_id)
        return int(mod.find(
            "./PARAMETERS/*[@NAME='{0}']".format(clk_odiv)).get('VALUE'))

    def find_clock_enable(self, mod, clk_id):
        """Return the clock enable for the given clock ID.

        Parameters
        ----------
        mod : Element
            The current XML element under parsing.
        clk_id : int
            The ID of the PL clock, can be 0 - 3.

        Returns
        -------
        int
            The clock enable value in decimal (1 means enabled).

        """
        clk_enable = 'PSU__FPGA_PL{0}_ENABLE'.format(clk_id)
        return int(mod.find(
            "./PARAMETERS/*[@NAME='{0}']".format(clk_enable)).get('VALUE'))


if CPU_ARCH == ZU_ARCH:
    HWH = _HWHUltrascale
elif CPU_ARCH == ZYNQ_ARCH:
    HWH = _HWHZynq
else:
    HWH = _HWHABC
    warnings.warn("PYNQ does not support the CPU Architecture: {}"
                  .format(CPU_ARCH), UserWarning)


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
        if os.path.exists(HWH_BOOT):
            parser = HWH(HWH_BOOT)
            _ip_dict = parser.ip_dict
            _gpio_dict = parser.gpio_dict
            _interrupt_controllers = parser.interrupt_controllers
            _interrupt_pins = parser.interrupt_pins
            _hierarchy_dict = parser.hierarchy_dict
        elif os.path.exists(TCL_BOOT):
            parser = TCL(TCL_BOOT)
            _ip_dict = parser.ip_dict
            _gpio_dict = parser.gpio_dict
            _interrupt_controllers = parser.interrupt_controllers
            _interrupt_pins = parser.interrupt_pins
            _hierarchy_dict = parser.hierarchy_dict
        else:
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
            _ip_dict = {}
            _gpio_dict = {}
            _interrupt_controllers = {}
            _interrupt_pins = {}
            _hierarchy_dict = {}

    @property
    def bitfile_name(cls):
        """The getter for the attribute `bitfile_name`.

        Returns
        -------
        str
            The absolute path of the bitstream currently on PL.

        """
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
                "Could not connect to PL server") from None
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

    def shutdown(cls):
        """Shutdown the AXI connections to the PL in preparation for
        reconfiguration

        """
        ip = cls.ip_dict
        for name, details in ip.items():
            if details['type'] == 'xilinx.com:ip:pr_axi_shutdown_manager:1.0':
                mmio = MMIO(details['phys_addr'])
                # Request shutdown
                mmio.write(0x0, 0x1)
                i = 0
                while mmio.read(0x0) != 0x0F and i < 16000:
                    i += 1
                if i >= 16000:
                    warnings.warn("Timeout for shutdown manager. It's likely "
                                  "the configured bitstream and metadata "
                                  "don't match.")

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
        cls.client_request()
        if parser is not None:
            cls._ip_dict = parser.ip_dict
            cls._gpio_dict = parser.gpio_dict
            cls._interrupt_controllers = parser.interrupt_controllers
            cls._interrupt_pins = parser.interrupt_pins
            cls._hierarchy_dict = parser.hierarchy_dict
        else:
            hwh_name = get_hwh_name(cls._bitfile_name)
            tcl_name = get_tcl_name(cls._bitfile_name)
            if os.path.isfile(hwh_name) or os.path.isfile(tcl_name):
                cls._ip_dict = clear_state(cls._ip_dict)
                cls._gpio_dict = clear_state(cls._gpio_dict)
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
        cls.client_request()
        cls._update_pr_ip(parser)
        cls._update_pr_gpio(parser)
        cls._update_pr_intr_pins(parser)
        cls._update_pr_hier(hier)
        cls.server_update()

    def _update_pr_ip(cls, parser):
        merged_ip_dict = deepcopy(cls._ip_dict)
        if type(parser) is HWH:
            for k, v in parser.ip_dict.items():
                if k in cls._ip_dict:
                    merged_ip_dict.pop(k)
                    ip_name = v['fullpath']
                    merged_ip_dict[ip_name] = cls._ip_dict[k]
                    merged_ip_dict[ip_name]['fullpath'] = v['fullpath']
                    merged_ip_dict[ip_name]['parameters'] = v['parameters']
                    merged_ip_dict[ip_name]['phys_addr'] = \
                        cls._ip_dict[k]['phys_addr'] + v['phys_addr']
                    merged_ip_dict[ip_name]['registers'] = v['registers']
                    merged_ip_dict[ip_name]['state'] = None
                    merged_ip_dict[ip_name]['type'] = v['type']
        elif type(parser) is TCL:
            for k_partial, v_partial in parser.ip_dict.items():
                for k_full, v_full in cls._ip_dict.items():
                    if v_partial['mem_id'] == v_full['mem_id']:
                        merged_ip_dict.pop(k_full)
                        ip_name = v_partial['fullpath']
                        merged_ip_dict[ip_name] = v_full
                        merged_ip_dict[ip_name]['fullpath'] = \
                            v_partial['fullpath']
                        merged_ip_dict[ip_name]['phys_addr'] = \
                            v_full['phys_addr'] + v_partial['phys_addr']
                        merged_ip_dict[ip_name]['state'] = None
                        merged_ip_dict[ip_name]['type'] = v_partial['type']
                        break
        else:
            raise ValueError("Cannot find HWH or TCL PR region parser.")
        cls._ip_dict = merged_ip_dict

    def _update_pr_gpio(cls, parser):
        new_gpio_dict = dict()
        for k, v in cls._gpio_dict.items():
            for pin in v['pins']:
                if pin in parser.pins:
                    v |= parser.nets[parser.pins[pin]]
                new_gpio_dict[k] = v
        cls._gpio_dict = new_gpio_dict

    def _update_pr_intr_pins(cls, parser):
        new_interrupt_pins = dict()
        for k, v in cls._interrupt_pins.items():
            if k in parser.pins:
                net_set = parser.nets[parser.pins[k]]
                hier_map = {i.count('/'): i for i in net_set}
                hier_map = sorted(hier_map.items(), reverse=True)
                fullpath = hier_map[0][-1]
                new_interrupt_pins[fullpath] = deepcopy(v)
                new_interrupt_pins[fullpath]['fullpath'] = fullpath
            else:
                new_interrupt_pins[k] = v
        cls._interrupt_pins = new_interrupt_pins

    def _update_pr_hier(cls, hier):
        cls._hierarchy_dict[hier] = {
            'ip': dict(),
            'hierarchies': dict(),
            'interrupts': dict(),
            'gpio': dict(),
            'fullpath': hier,
        }
        for name, val in cls._ip_dict.items():
            hier, _, ip = name.rpartition('/')
            if hier:
                cls._hierarchy_dict[hier]['ip'][ip] = val
                cls._hierarchy_dict[hier]['ip'][ip] = val
        for name, val in cls._hierarchy_dict.items():
            hier, _, subhier = name.rpartition('/')
            if hier:
                cls._hierarchy_dict[hier]['hierarchies'][subhier] = val
        for interrupt, val in cls._interrupt_pins.items():
            block, _, pin = interrupt.rpartition('/')
            if block in cls._ip_dict:
                cls._ip_dict[block]['interrupts'][pin] = val
            if block in cls._hierarchy_dict:
                cls._hierarchy_dict[block]['interrupts'][pin] = val
        for gpio in cls._gpio_dict.values():
            for connection in gpio['pins']:
                ip, _, pin = connection.rpartition('/')
                if ip in cls._ip_dict:
                    cls._ip_dict[ip]['gpio'][pin] = gpio
                elif ip in cls._hierarchy_dict:
                    cls._hierarchy_dict[ip]['gpio'][pin] = gpio


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
    """This class instantiates the meta class for PL bitstream (full/partial).

    Attributes
    ----------
    bitfile_name : str
            The absolute path or name of the bit file as a string.
    partial : bool
        Flag to indicate whether or not the bitstream is partial.
    bit_data : dict
        Dictionary storing information about the bitstream.
    binfile_name : str
        The absolute path or name of the bin file as a string.
    firmware_path : str
        The absolute path of the bin file in the firmware folder.
    timestamp : str
        Timestamp when loading the bitstream. Format:
        year, month, day, hour, minute, second, microsecond

    """
    BS_FPGA_MAN = "/sys/class/fpga_manager/fpga0/firmware"
    BS_FPGA_MAN_FLAGS = "/sys/class/fpga_manager/fpga0/flags"

    def __init__(self, bitfile_name, partial=False):
        """Return a new Bitstream object.

        Users can either specify an absolute path to the bitstream file
        (e.g. '/home/xilinx/pynq/overlays/base/base.bit'),
        or a relative path within an overlay folder.
        (e.g. 'base.bit' for base/base.bit).

        Note
        ----
        self.bitstream always stores the absolute path of the bitstream.

        Parameters
        ----------
        bitfile_name : str
            The absolute path or name of the bit file as a string.
        partial : bool
            Flag to indicate whether or not the bitstream is partial.

        """
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

        self.bit_data = dict()
        self.binfile_name = ''
        self.firmware_path = ''
        self.timestamp = ''
        self.partial = partial

    def convert_bit_to_bin(self):
        """The method to convert a .bit file to .bin file.

        A .bit file is generated by Vivado, but .bin files are needed
        by the FPGA manager driver. Users must specify
        the absolute path to the source .bit file, and the destination
        .bin file and have read/write access to both paths.
        This function is only converting the bit file when the bit file is
        updated.

        Note
        ----
        Implemented based on: https://blog.aeste.my/?p=2892

        """
        if self.bit_data != self.parse_bit_header() or \
                not os.path.isfile(self.firmware_path):
            self.bit_data = self.parse_bit_header()
            bit_buffer = np.frombuffer(self.bit_data['data'],
                                       dtype=np.int32, offset=0)
            bin_buffer = bit_buffer.byteswap()
            bin_buffer.tofile(self.firmware_path, "")

    def parse_bit_header(self):
        """The method to parse the header of a bitstream.

        The returned dictionary has the following keys:
        "design": str, the Vivado project name that generated the bitstream;
        "version": str, the Vivado tool version that generated the bitstream;
        "part": str, the Xilinx part name that the bitstream targets;
        "date": str, the date the bitstream was compiled on;
        "time": str, the time the bitstream finished compilation;
        "length": int, total length of the bitstream (in bytes);
        "data": binary, binary data in .bit file format

        Returns
        -------
        Dict
            A dictionary containing the header information.

        Note
        ----
        Implemented based on: https://blog.aeste.my/?p=2892

        """
        with open(self.bitfile_name, 'rb') as bitf:
            finished = False
            offset = 0
            contents = bitf.read()
            bit_dict = {}

            # Strip the (2+n)-byte first field (2-bit length, n-bit data)
            length = struct.unpack('>h', contents[offset:offset + 2])[0]
            offset += 2 + length

            # Strip a two-byte unknown field (usually 1)
            offset += 2

            # Strip the remaining headers. 0x65 signals the bit data field
            while not finished:
                desc = contents[offset]
                offset += 1

                if desc != 0x65:
                    length = struct.unpack('>h',
                                           contents[offset:offset + 2])[0]
                    offset += 2
                    fmt = ">{}s".format(length)
                    data = struct.unpack(fmt,
                                         contents[offset:offset + length])[0]
                    data = data.decode('ascii')[:-1]
                    offset += length

                if desc == 0x61:
                    s = data.split(";")
                    bit_dict['design'] = s[0]
                    bit_dict['version'] = s[-1]
                elif desc == 0x62:
                    bit_dict['part'] = data
                elif desc == 0x63:
                    bit_dict['date'] = data
                elif desc == 0x64:
                    bit_dict['time'] = data
                elif desc == 0x65:
                    finished = True
                    length = struct.unpack('>i',
                                           contents[offset:offset + 4])[0]
                    offset += 4
                    # Expected length values can be verified in the chip TRM
                    bit_dict['length'] = str(length)
                    if length + offset != len(contents):
                        raise RuntimeError("Invalid length found")
                    bit_dict['data'] = contents[offset:offset + length]
                else:
                    raise RuntimeError("Unknown field: {}".format(hex(desc)))
            return bit_dict

    def download(self):
        """Download the bitstream onto PL and update PL information.

        Note
        ----
        For partial bitstream, this method does not guarantee isolation between
        static and dynamic regions.

        Returns
        -------
        None

        """
        # preload bin into firmware
        if not self.binfile_name:
            self.preload()

        # use fpga manager to download bin
        if not self.partial:
            PL.shutdown()
            flag = '0'
        else:
            flag = '1'
        with open(self.BS_FPGA_MAN_FLAGS, "w") as fd:
            fd.write(flag)
        with open(self.BS_FPGA_MAN, 'w') as fd:
            fd.write(self.binfile_name)

        # update PL information
        if not self.partial:
            self.update_pl()

    def preload(self):
        if not os.path.exists(self.BS_FPGA_MAN):
            raise RuntimeError("Could not find programmable device")

        self.binfile_name = os.path.basename(
            self.bitfile_name).replace('.bit', '.bin')
        self.firmware_path = '/lib/firmware/' + self.binfile_name
        self.convert_bit_to_bin()

    def update_pl(self):
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
