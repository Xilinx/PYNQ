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
from datetime import datetime
from multiprocessing.connection import Listener
from multiprocessing.connection import Client
from pynq import MMIO
from .ps import Clocks

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"

# Overlay constants
PYNQ_PATH = os.path.dirname(os.path.realpath(__file__))
BS_BOOT = os.path.join(PYNQ_PATH, 'base', 'base.bit')
TCL_BOOT = os.path.join(PYNQ_PATH, 'base', 'base.tcl')

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
        self.ps7_name = ""
        self.ip_dict = {}
        self.gpio_dict = {}
        self.clock_dict = {}

        # Key strings to search for in the TCL file
        hier_start_pat = "create_hier_cell"
        hier_end_pat = "}\n"
        hier_regex = "proc create_hier_cell_([^ ]*)"
        config_pat = "CONFIG."
        config_regex = "CONFIG.(.+?) \{(.+?)\}"
        clk_divisor_regex = 'PCW_FCLK(.+?)_PERIPHERAL_DIVISOR(.+?)'
        clk_enable_regex = 'PCW_FPGA_FCLK(.+?)_ENABLE'
        prop_start_pat = "set_property -dict ["
        prop_end_pat = "]"
        prop_name_regex = "\] \$(.+?)$"
        net_pat = "connect_bd_net -net"
        net_regex = "\[get_bd_pins ([^]]+)\]"
        addr_pat = "create_bd_addr_seg"
        addr_regex = "create_bd_addr_seg -range (0[xX][0-9a-fA-F]+) " + \
                     "-offset (0[xX][0-9a-fA-F]+) " + \
                     "\[get_bd_addr_spaces "
        ip_pat = "create_bd_cell -type ip -vlnv "
        ip_regex = "create_bd_cell -type ip -vlnv " + \
                   "(.+?):(.+?):(.+?):(.+?) (.+?) "

        # Parsing state
        current_hier = ""
        last_concat = ""
        in_prop = False
        gpio_idx = None
        ip_dict = {}
        gpio_dict = {}

        with open(tcl_name, 'r') as f:
            for line in f:
                if not line.lstrip().startswith('#'):
                    # Matching address segment
                    if not in_prop and addr_pat in line:
                        m = re.search(addr_regex, line, re.IGNORECASE)
                        if m:
                            for key, value in ip_dict.items():
                                if m.group(3).startswith(key):
                                    self.ip_dict[key] = dict()
                                    self.ip_dict[key]['phys_addr'] = \
                                        int(m.group(2), 16)
                                    self.ip_dict[key]['addr_range'] = \
                                        int(m.group(1), 16)
                                    self.ip_dict[key]['type'] = \
                                        value
                                    self.ip_dict[key]['state'] = None

                    # Matching hierarchical cell
                    elif not in_prop and hier_start_pat in line:
                        m = re.search(hier_regex, line)
                        if m:
                            current_hier = m.group(1) + "/"
                    elif not in_prop and hier_end_pat == line:
                        current_hier = ""

                    # Matching IP cells in root design
                    elif not in_prop and ip_pat in line:
                        m = re.search(ip_regex, line)
                        hier_name = current_hier + m.group(5)
                        if m.group(3) == "processing_system7":
                            self.ps7_name = hier_name
                            addr_regex += (self.ps7_name + "/Data\] " +
                                           "\[get_bd_addr_segs (.+?)\] " +
                                           "([A-Za-z0-9_]+)")
                        else:
                            ip_type = ':'.join([m.group(1), m.group(2),
                                                m.group(3), m.group(4)])
                            ip_dict[hier_name] = ip_type
                            if m.group(3) == "xlconcat":
                                last_concat = current_hier + m.group(5)
                                self.concat_cells[last_concat] = 2
                            elif m.group(3) == "axi_intc":
                                self.intc_names.append(current_hier +
                                                       m.group(5))

                    # Matching nets
                    elif not in_prop and net_pat in line:
                        new_pins = [current_hier + v for v in
                                    re.findall(net_regex, line, re.IGNORECASE)]
                        indexes = set()
                        for p in new_pins:
                            if p in self.pins:
                                indexes.add(self.pins[p])
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

                    # Matching IP configurations
                    elif not in_prop and prop_start_pat in line:
                        in_prop = True
                    elif in_prop and prop_end_pat in line:
                        m = re.search(prop_name_regex, line, re.IGNORECASE)
                        if m:
                            if gpio_idx is not None:
                                gpio_dict[m.group(1)] = gpio_idx
                                gpio_idx = None
                        in_prop = False
                    elif in_prop and config_pat in line:
                        m1 = re.search(config_regex, line)
                        if m1.group(1) == "NUM_PORTS":
                            self.concat_cells[last_concat] = int(m1.group(2))
                        elif m1.group(1) == 'DIN_FROM':
                            gpio_idx = int(m1.group(2))
                        elif 'FCLK' in m1.group(1):
                            m2 = re.search(clk_divisor_regex, m1.group(1))
                            m3 = re.search(clk_enable_regex, m1.group(1))
                            if m2:
                                fclk_index = int(m2.group(1))
                                if fclk_index not in self.clock_dict:
                                    self.clock_dict[fclk_index] = {}
                                divisor_name = 'divisor' + m2.group(2)
                                self.clock_dict[fclk_index][divisor_name] = \
                                    int(m1.group(2))
                            if m3:
                                fclk_index = int(m3.group(1))
                                if fclk_index not in self.clock_dict:
                                    self.clock_dict[fclk_index] = {}
                                self.clock_dict[fclk_index]['enable'] = \
                                    int(m1.group(2))

        if self.ps7_name + "/IRQ_F2P" in self.pins:
            ps7_irq_net = self.pins[self.ps7_name + "/IRQ_F2P"]
            self._add_interrupt_pins(ps7_irq_net, "", 0)

        if self.ps7_name + "/GPIO_O" in self.pins:
            ps7_gpio_net = self.pins[self.ps7_name + "/GPIO_O"]
            self._add_gpio_pins(ps7_gpio_net, gpio_dict)

    def _add_gpio_pins(self, net, gpio_dict):
        net_pins = self.nets[net]
        gpio_names = []
        for p in net_pins:
            m = re.match('(.*)/Din', p)
            if m is not None:
                gpio_names.append(m.group(1))
        for n, i in gpio_dict.items():
            if n in gpio_names:
                self.gpio_dict[n] = {'index': i, 'state': None}

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
                                      'index': offset}
        return offset + 1

    def _add_concat_pins(self, name, parent, offset):
        num_ports = self.concat_cells[name]
        for i in range(num_ports):
            net = self.pins[name + "/In" + str(i)]
            offset = self._add_interrupt_pins(net, parent, offset)
        return offset


class PLMeta(type):
    """This method is the meta class for the PL.

    This is not a class for users. Hence there is no attribute or method
    exposed to users.

    """
    _bitfile_name = BS_BOOT
    _timestamp = ""

    _tcl = _TCL(TCL_BOOT)
    _ip_dict = _tcl.ip_dict
    _gpio_dict = _tcl.gpio_dict
    _interrupt_controllers = _tcl.interrupt_controllers
    _interrupt_pins = _tcl.interrupt_pins
    _status = 1

    _server = None
    _host = None
    _remote = None

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
                            cls._interrupt_pins])
            cls._bitfile_name, cls._timestamp, \
                cls._ip_dict, cls._gpio_dict, \
                cls._interrupt_controllers, cls._interrupt_pins, \
                cls._status = cls._host.recv()
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
        cls._remote = Client(address, family='AF_UNIX', authkey=key)
        cls._bitfile_name, cls._timestamp, \
            cls._ip_dict, cls._gpio_dict, \
            cls._interrupt_controllers, \
            cls._interrupt_pins = cls._remote.recv()

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
            cls._ip_dict.clear()
            cls._gpio_dict.clear()
            cls._interrupt_controllers.clear()
            cls._interrupt_pins.clear()
        cls.server_update()

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
            size = (math.ceil(os.fstat(bin_file.fileno()).st_size /
                              mmap.PAGESIZE)) * mmap.PAGESIZE
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
    def __init__(self):
        """Return a new PL object.

        This class requires a root permission.

        """
        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('Root permissions required.')


class Bitstream(PL):
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
        bitfile_overlay_abs = os.path.join(PYNQ_PATH, bitfile_name.replace('.bit', ''), bitfile_name)

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
        The class variables held by the singleton PL will also be updated.

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
        PL._ip_dict.clear()
        PL._gpio_dict.clear()
        PL._interrupt_controllers.clear()
        PL._interrupt_pins.clear()
        PL.server_update()


class Overlay(PL):
    """This class keeps track of a single bitstream's state and contents.

    The overlay class holds the state of the bitstream and enables run-time
    protection of bindlings.

    Our definition of overlay is: "post-bitstream configurable design".
    Hence, this class must expose configurability through content discovery
    and runtime protection.

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

    def __init__(self, bitfile_name):
        """Return a new Overlay object.

        An overlay instantiates a bitstream object as a member initially.

        Note
        ----
        This class requires a Vivado '.tcl' file to be next to bitstream file
        with same name (e.g. base.bit and base.tcl).

        Parameters
        ----------
        bitfile_name : str
            The bitstream name or absolute path as a string.

        """
        super().__init__()

        # # Set the bitfile name
        # if not isinstance(bitfile_name, str):
        #     raise TypeError("Bitstream name has to be a string.")
        # if os.path.isfile(bitfile_name):
        #     self.bitfile_name = bitfile_name
        # elif os.path.isfile(BS_SEARCH_PATH + bitfile_name):
        #     self.bitfile_name = BS_SEARCH_PATH + bitfile_name
        # else:
        #     raise IOError('Bitstream file {} does not exist.'
        #                   .format(bitfile_name))

        # Set the bitstream
        self.bitstream = Bitstream(bitfile_name)
        self.bitfile_name = self.bitstream.bitfile_name
        tcl = _TCL(_get_tcl_name(self.bitfile_name))
        self.ip_dict = tcl.ip_dict
        self.gpio_dict = tcl.gpio_dict
        self.interrupt_controllers = tcl.interrupt_controllers
        self.interrupt_pins = tcl.interrupt_pins
        self.clock_dict = tcl.clock_dict

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
