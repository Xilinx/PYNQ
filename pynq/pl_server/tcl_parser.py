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


import abc
import os
import re
from copy import deepcopy
from pynq.ps import CPU_ARCH_IS_SUPPORTED, CPU_ARCH, ZYNQ_ARCH, ZU_ARCH

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


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
        self.mem_dict = {}

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
        self.init_mem_dict()

    def init_mem_dict(self):
        """Prepare the memory dictionary

        For now we will add a single entry for the PS

        """
        from pynq.xlnk import Xlnk
        self.mem_dict[self.ps_name] = {
            'raw_type': None,
            'used': 1,
            'base_address':0,
            'size': Xlnk.cma_mem_size(None),
            'type': 'PSDDR',
            'streaming': False
        }

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
                'memories': dict(),
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

