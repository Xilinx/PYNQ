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
import sys
import re
import mmap
import math
from datetime import datetime
from multiprocessing.connection import Listener
from multiprocessing.connection import Client
from pynq import general_const
from pynq import GPIO
from pynq import MMIO

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


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


def _get_ip(tcl_name):
    """This method returns the MMIO base and range of an IP.

    This method applies to all the addressable IPs.

    Note
    ----
    This method requires the absolute path of the '.tcl' file as input.
    Each entry in the returned dictionary stores a list of strings containing
    the base and range in hex format, and an empty state.

    Parameters
    ----------
    tcl_name : str
        The absolute path of the .tcl file.

    Returns
    -------
    dict
        A dictionary storing the address base and range information.

    """
    regex = 'create_bd_addr_seg -range (0[xX][0-9a-fA-F]+) ' + \
            '-offset (0[xX][0-9a-fA-F]+) ' + \
            '\[get_bd_addr_spaces (processing_system7_0|ps7)/Data\] ' + \
            '(\[.+?\]) ' + \
            '([A-Za-z0-9_]+)'
    result = {}

    with open(tcl_name, 'r') as f:
        for line in f:
            m = re.search(regex, line, re.IGNORECASE)
            if m:
                # Each entry is [base, range, state]
                result[m.group(5)] = [int(m.group(2), 16),
                                      int(m.group(1), 16), None]

    return result


def _get_gpio(tcl_name):
    """This method returns the PS GPIO index for an IP.

    Note
    ----
    This method requires the absolute path of the '.tcl' file as input.
    Each entry in the returned dictionary stores a user index, and an empty
    state. For more information about the user GPIO pin, please see the GPIO
    class.

    Parameters
    ----------
    tcl_name : str
        The absolute path of the .tcl file.

    Returns
    -------
    dict
        The dictionary storing the GPIO user indices, starting from 0.

    """
    pat1 = 'connect_bd_net -net processing_system7_0_GPIO_O'
    pat2 = 'connect_bd_net -net ps7_GPIO_O'
    result = {}
    gpio_list = []
    with open(tcl_name, 'r') as f:
        for line in f:
            if (pat1 in line) or (pat2 in line):
                gpio_list = re.findall('\[get_bd_pins (.+?)/Din\]',
                                       line, re.IGNORECASE)

    match1 = 0
    index = 0
    for i in range(len(gpio_list)):
        name = gpio_list[i].split('/')[0]
        pat3 = "set " + name
        pat4 = "CONFIG.DIN_FROM {([0-9]+)}*"
        with open(tcl_name, 'r') as f:
            for line in f:
                if pat3 in line:
                    match1 = 1
                    continue
                if match1 == 1:
                    match2 = re.search(pat4, line, re.IGNORECASE)
                    if match2:
                        index = match2.group(1)
                        match1 = 0
                        break
        result[gpio_list[i]] = [int(index), None]

    return result


class _InterruptMap:
    """Helper Class to extract interrupt information from a TCL
    configuration file

    Attributes
    ----------
    intc_parent : dict [str, str, int]
        All AXI interrupt controllers in the system attached to
        a PS7 interrupt line. Key is the name of the controller and
        value is parent interrupt controller and the line interrupt used
        The PS7 is the root of the hierarchy and is unnamed

    intc_pins : dict [str, str, int]
        All pins in the design attached to an interrupt controller listed in
        in intc_names. Key is the name of the pin, value is the interrupt
        controller and line used.

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

        # This code does not support nested hierarchies at present

        # Initialize result variables
        self.intc_names = []
        self.intc_parent = {}
        self.concat_cells = {}
        self.nets = []
        self.pins = {}
        self.intc_pins = {}
        self.ps7_name = ""

        # Key strings to search for in the TCL file
        hier_pat = "create_hier_cell"
        concat_pat = "create_bd_cell -type ip -vlnv " \
                     "xilinx.com:ip:xlconcat:2.1"
        interrupt_pat = "create_bd_cell -type ip -vlnv " \
                        "xilinx.com:ip:axi_intc:4.1"
        ps7_pat = "create_bd_cell -type ip -vlnv " \
                  "xilinx.com:ip:processing_system7:5.5"
        prop_pat = "set_property -dict"
        config_pat = "CONFIG.NUM_PORTS"
        end_pat = "}\n"
        net_pat = "connect_bd_net -net"

        # Parsing state
        current_hier = ""
        last_concat = ""

        with open(tcl_name, 'r') as f:
            for line in f:
                if config_pat in line:
                    m = re.search('CONFIG.NUM_PORTS \{([0-9]+)\}', line)
                    self.concat_cells[last_concat] = int(m.groups(1)[0])
                elif hier_pat in line:
                    m = re.search('proc create_hier_cell_([^ ]*)', line)
                    if m:
                        current_hier = m.groups(1)[0] + "/"
                elif prop_pat in line:
                    in_prop = True
                elif concat_pat in line:
                    m = re.search(
                        'create_bd_cell -type ip -vlnv ' +
                        'xilinx.com:ip:xlconcat:2.1 ([^ ]+)', line)
                    last_concat = current_hier + m.groups(1)[0]
                    # Default for IP is two input ports
                    self.concat_cells[last_concat] = 2
                elif interrupt_pat in line:
                    m = re.search(
                        'create_bd_cell -type ip -vlnv ' +
                        'xilinx.com:ip:axi_intc:4.1 ([^ ]+)', line)
                    self.intc_names.append(current_hier + m.groups(1)[0])
                elif ps7_pat in line:
                    m = re.search(
                        'create_bd_cell -type ip -vlnv ' +
                        'xilinx.com:ip:processing_system7:5.5 ([^ ]+)', line)
                    self.ps7_name = current_hier + m.groups(1)[0]
                elif end_pat == line:
                    current_hier = ""
                elif net_pat in line:
                    new_pins = [current_hier + v for v in
                                re.findall('\[get_bd_pins ([^]]+)\]',
                                           line, re.IGNORECASE)]
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

        if self.ps7_name + "/IRQ_F2P" in self.pins:
            ps7_irq_net = self.pins[self.ps7_name + "/IRQ_F2P"]
            self._add_interrupt_pins(ps7_irq_net, "", 0)

    def _add_interrupt_pins(self, net, parent, offset):

        net_pins = self.nets[net]
        # Find the next item up the chain
        for p in net_pins:
            m = re.match('(.*)/dout', p)
            if m is not None:
                name = m.groups(1)[0]
                if name in self.concat_cells:
                    return self._add_concat_pins(name, parent, offset)
            m = re.match('(.*)/irq', p)
            if m is not None:
                name = m.groups(1)[0]
                if name in self.intc_names:
                    self._add_interrupt_pins(
                        self.pins[name + "/intr"], name, 0)
                    self.intc_parent[name] = [parent, offset]
                    return offset + 1
        for p in net_pins:
            self.intc_pins[p] = [parent, offset]
        return offset + 1

    def _add_concat_pins(self, name, parent, offset):
        num_ports = self.concat_cells[name]
        for i in range(num_ports):
            net = self.pins[name + "/In" + str(i)]
            offset = self._add_interrupt_pins(net, parent, offset)
        return offset


def _get_interrupts(tcl_name):
    """Function to extract interrupt information from a TCL configuration file

    Returns
    -------
    interrupt_controllers, interrupt_pins

    interrupt_controllers : dict str -> str, int
        All AXI interrupt controllers in the system attached to
        a PS7 interrupt line. Key is the name of the controller and
        value is parent interrupt controller and the line interrupt used
        The PS7 is the root of the hierarchy and is unnamed

    interrupt_pins : dict str -> str, int
        All pins in the design attached to an interrupt controller listed in
        in intc_names. Key is the name of the pin, value is the interrupt
        controller and line used.

    """
    result = _InterruptMap(tcl_name)
    return result.intc_parent, result.intc_pins


class PL_Meta(type):
    """This method is the meta class for the PL.

    This is not a class for users. Hence there is no attribute or method
    exposed to users.

    """
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
        """The getter for the attribute `interrupt_controllers`

        Returns
        -------
        dict
            The dictionary storing interrupt controller information

        """
        cls.client_request()
        cls.server_update()
        return cls._interrupt_controllers

    @property
    def interrupt_pins(cls):
        """The getter for the attribute `interrupt_pins`

        Returns
        -------
        dict
            The dictionary storing the interrupt endpoint information

        """
        cls.client_request()
        cls.server_update()
        return cls._interrupt_pins


class PL(metaclass=PL_Meta):
    """Serves as a singleton for `Overlay` and `Bitstream` classes.

    This class stores two dictionaries: IP dictionary and GPIO dictionary.

    Each entry of the IP dictionary is a mapping:
    'name' -> [address, range, state]

    where
    name (str) is the key of the entry.
    address (int) is the base address of the IP.
    range (int) is the address range of the IP.
    state (str) is the state information about the IP.

    Each entry of the GPIO dictionary is a mapping:
    'name' -> [pin, state]

    where
    name (str) is the key of the entry.
    pin (int) is the user index of the GPIO, starting from 0.
    state (str) is the state information about the GPIO.

    The timestamp uses the following format:
    year, month, day, hour, minute, second, microsecond

    Attributes
    ----------
    bitfile_name : str
        The absolute path of the bitstream currently on PL.
    timestamp : str
        Bitstream download timestamp.
    ip_dict : dict
        The dictionary storing addressable IP instances; can be empty.
    gpio_dict : dict
        The dictionary storing the PS GPIO pins.

    """

    _bitfile_name = general_const.BS_BOOT
    _timestamp = ""

    _ip_dict = _get_ip(general_const.TCL_BOOT)
    _gpio_dict = _get_gpio(general_const.TCL_BOOT)
    _interrupt_controllers, _interrupt_pins = _get_interrupts(
        general_const.TCL_BOOT)
    _server = None
    _host = None
    _remote = None

    def __init__(self):
        """Return a new PL object.

        This class requires a root permission.

        """
        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('Root permissions required.')

    @classmethod
    def setup(cls, address='/home/xilinx/pynq/bitstream/.log', key=b'xilinx'):
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
        cls._status = 1

        while cls._status:
            cls._host = cls._server.accept()
            cls._host.send([cls._bitfile_name, cls._timestamp,
                            cls._ip_dict, cls._gpio_dict,
                            cls._interrupt_controllers, cls._interrupt_pins])
            [cls._bitfile_name, cls._timestamp, cls._ip_dict,
             cls._gpio_dict, cls._interrupt_controllers,
             cls._interrupt_pins, cls._status] = cls._host.recv()
            cls._host.close()

        cls._server.close()

    @classmethod
    def client_request(cls, address='/home/xilinx/pynq/bitstream/.log',
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
        [cls._bitfile_name, cls._timestamp,
         cls._ip_dict, cls._gpio_dict,
         cls._interrupt_controllers, cls.intc_pins] = cls._remote.recv()

    @classmethod
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
        cls._remote.send([cls._bitfile_name, cls._timestamp,
                          cls._ip_dict, cls._gpio_dict,
                          cls._interrupt_controllers,
                          cls.intc_pins, continued])
        cls._remote.close()

    @classmethod
    def reset(cls):
        """Reset both the IP and GPIO dictionaries.

        This method must be called after a bitstream download.
        1. In case there is a `*.tcl` file, this method will reset the IP,
        Interrupt and GPIO dictionaries based on the tcl file.
        2. In case there is no `*.tcl` file, this method will simply clear
        the state information stored for all dictionaries.

        """
        cls.client_request()
        tcl_name = _get_tcl_name(cls._bitfile_name)
        if os.path.isfile(tcl_name):
            cls._ip_dict = _get_ip(tcl_name)
            cls._gpio_dict = _get_gpio(tcl_name)
            cls._interrupt_controllers, cls._interrupt_pins = \
                _get_interrupts(tcl_name)
        else:
            for i in cls._ip_dict.keys():
                cls._ip_dict[i][2] = None
            for i in cls._gpio_dict.keys():
                cls._gpio_dict[i][1] = None
            cls._interrupt_controllers.clear()
            cls._interrupt_pins.clear()
        cls.server_update()

    @classmethod
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
        with open(data, 'rb') as bin:
            size = (math.ceil(os.fstat(bin.fileno()).st_size /
                              mmap.PAGESIZE)) * mmap.PAGESIZE
            mmio = MMIO(cls._ip_dict[ip_name][0], size)
            buf = bin.read(size)
            mmio.write(0, buf)

        cls._ip_dict[ip_name][2] = data
        cls.server_update()


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
        or only a relative path.
        (e.g. 'base.bit').

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

        if os.path.isfile(bitfile_name):
            self.bitfile_name = bitfile_name
        elif os.path.isfile(general_const.BS_SEARCH_PATH + bitfile_name):
            self.bitfile_name = general_const.BS_SEARCH_PATH + bitfile_name
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
        with open(general_const.BS_IS_PARTIAL, 'w') as fd:
            fd.write('0')

        # Write bitfile to xdevcfg device
        with open(general_const.BS_XDEVCFG, 'wb') as f:
            f.write(buf)

        t = datetime.now()
        self.timestamp = "{}/{}/{} {}:{}:{} +{}".format(
                t.year, t.month, t.day,
                t.hour, t.minute, t.second, t.microsecond)

        # Update PL information
        PL.client_request()
        PL._bitfile_name = self.bitfile_name
        PL._timestamp = self.timestamp
        PL._ip_dict = {}
        PL._gpio_dict = {}
        PL._interrupt_controllers = {}
        PL._interrupt_pins = {}
        PL.server_update()


class Overlay(PL):
    """This class keeps track of a single bitstream's state and contents.

    The overlay class holds the state of the bitstream and enables run-time
    protection of bindlings.

    Our definition of overlay is: "post-bitstream configurable design".
    Hence, this class must expose configurability through content discovery
    and runtime protection.

    This class stores four dictionaries: IP, GPIO, Interrupt Controller
    and Interrupt Pin dictionaries.

    Each entry of the IP dictionary is a mapping:
    'name' -> [address, range, state]

    where
    name (str) is the key of the entry.
    address (int) is the base address of the IP.
    range (int) is the address range of the IP.
    state (str) is the state information about the IP.

    Each entry of the GPIO dictionary is a mapping:
    'name' -> [pin, state]

    where
    name (str) is the key of the entry.
    pin (int) is the user index of the GPIO, starting from 0.
    state (str) is the state information about the GPIO.

    Each entry in the Interrupt dictionaries are of the form
    'name' -> [parent, number]

    where
    name (str) is the name of the pin or the interrupt controller
    parent (str) is the name of the parent controller or '' if attached
        directly to the PS7
    number (int) is the interrupt number attached to

    Attributes
    ----------
    bitfile_name : str
        The absolute path of the bitstream.
    bitstream : Bitstream
        The corresponding bitstream object.
    ip_dict : dict
        The addressable IP instances on the overlay.
    gpio_dict : dict
        The dictionary storing the PS GPIO pins.
    interrupt_controllers : dict
        The dictionary containing all interrupt controllers
    interrupt_pins : dict
        The dictionary containing all interrupts in the design

    """

    def __init__(self, bitfile_name):
        """Return a new Overlay object.

        An overlay instantiates a bitstream object as a member initially.

        Note
        ----
        This class requires a Vivado '.tcl' file to be next to bitstream file
        with same base name (e.g. base.bit and base.tcl).

        Parameters
        ----------
        bitfile_name : str
            The bitstream name or absolute path as a string.

        """
        super().__init__()

        # Set the bitfile name
        if not isinstance(bitfile_name, str):
            raise TypeError("Bitstream name has to be a string.")
        if os.path.isfile(bitfile_name):
            self.bitfile_name = bitfile_name
        elif os.path.isfile(general_const.BS_SEARCH_PATH + bitfile_name):
            self.bitfile_name = general_const.BS_SEARCH_PATH + bitfile_name
        else:
            raise IOError('Bitstream file {} does not exist.'
                          .format(bitfile_name))

        # Set the bitstream
        self.bitstream = Bitstream(self.bitfile_name)
        tcl_name = _get_tcl_name(self.bitfile_name)

        # Set the IP dictionary
        self.ip_dict = _get_ip(tcl_name)

        # Set the GPIO dictionary
        self.gpio_dict = _get_gpio(tcl_name)

        # Set the Interrupt dictionaries
        self.interrupt_controllers, self.interrupt_pins = \
            _get_interrupts(tcl_name)

    def download(self):
        """The method to download a bitstream onto PL.

        Note
        ----
        After the bitstream has been downloaded, the "timestamp" in PL will be
        updated. In addition, both of the IP and GPIO dictionaries on PL will
        be reset automatically.

        Returns
        -------
        None

        """
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
        """This function resets the IP and GPIO dictionaries of the overlay.

        Note
        ----
        This function should be used with caution. If the overlay is loaded,
        it also resets the IP and GPIO dictionaries in the PL.

        Returns
        -------
        None

        """
        tcl_name = _get_tcl_name(self.bitfile_name)
        self.gpio_dict = _get_gpio(tcl_name)
        self.ip_dict = _get_ip(tcl_name)
        self.interrupt_controllers, self.interrupt_pins = \
            _get_interrupts(tcl_name)
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
        super().load_ip_data(ip_name, data)
        self.ip_dict[ip_name][2] = data
