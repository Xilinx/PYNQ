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

from multiprocessing.connection import Listener
from multiprocessing.connection import Client
from copy import deepcopy
import os
import threading
from pynq.devicetree import DeviceTreeSegment
from pynq.devicetree import get_dtbo_base_name
from .tcl_parser import TCL, get_tcl_name
from .hwh_parser import HWH, get_hwh_name

__author__ = "Yun Rock Qu, Peter Ogden"
__copyright__ = "Copyright 2019, Xilinx"
__email__ = "pynq_support@xilinx.com"


# Overlay constants
PYNQ_PATH = os.path.dirname(os.path.realpath(__file__))
PL_SERVER_TEMPLATE = '/tmp/pynq.{}.socket'


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


class DeviceClient:
    """Class to access the PL server

    The properties of the class access the most recent version
    from the PL server and are read-only. All updating of the
    PL server is performed by methods.

    """
    @staticmethod
    def accessible(tag):
        try:
            client = DeviceClient(tag)
            client.client_request()
            client.server_update()
            return True
        except (ConnectionError, PermissionError):
            return False

    def __init__(self, tag, key=b'xilinx'):
        """Create a new instance of the PL server

        Parameters
        ----------

        tag : string or path
            The unique identifier of the device
        key : bytes
            The authentication key for the server

        """
        self._ip_dict = {}
        self._gpio_dict = {}
        self._interrupt_controllers = {}
        self._interrupt_pins = {}
        self._hierarchy_dict = {}
        self._devicetree_dict = {}
        self._address = PL_SERVER_TEMPLATE.format(tag)
        self._key = key
        self._timestamp = None
        self._bitfile_name = None

    @property
    def ip_dict(self):
        """The getter for the attribute `ip_dict`.

        Returns
        -------
        dict
            The dictionary storing addressable IP instances; can be empty.

        """
        self.client_request()
        self.server_update()
        return self._ip_dict

    @property
    def gpio_dict(self):
        """The getter for the attribute `gpio_dict`.

        Returns
        -------
        dict
            The dictionary storing the PS GPIO pins.

        """
        self.client_request()
        self.server_update()
        return self._gpio_dict

    @property
    def interrupt_pins(self):
        """The getter for the attribute `interrupt_pins`.

        Returns
        -------
        dict
            The dictionary storing the interrupt endpoint information.

        """
        self.client_request()
        self.server_update()
        return self._interrupt_pins

    @property
    def interrupt_controllers(self):
        """The getter for the attribute `interrupt_controllers`.

        Returns
        -------
        dict
            The dictionary storing interrupt controller information.

        """
        self.client_request()
        self.server_update()
        return self._interrupt_controllers

    @property
    def hierarchy_dict(self):
        """The getter for the attribute `hierarchy_dict`

        Returns
        -------
        dict
            The dictionary containing the hierarchies in the design

        """
        self.client_request()
        self.server_update()
        return self._hierarchy_dict

    @property
    def devicetree_dict(self):
        """The getter for the attribute `devicetree_dict`

        Returns
        -------
        dict
            The dictionary containing the device tree blobs.

        """
        self.client_request()
        self.server_update()
        return self._devicetree_dict

    @property
    def bitfile_name(self):
        """The getter for the attribute `bitfile_name`.

        Returns
        -------
        str
            The absolute path of the bitstream currently on PL.

        """
        self.client_request()
        self.server_update()
        return self._bitfile_name

    @property
    def timestamp(self):
        """The getter for the attribute `timestamp`.

        Returns
        -------
        str
            Bitstream download timestamp.

        """
        self.client_request()
        self.server_update()
        return self._timestamp

    @property
    def mem_dict(self):
        """The getter for the attribute `mem_dict`

        Returns
        -------
        dict
            The dictionary containing the memory spaces in the design

        """
        self.client_request()
        self.server_update()
        return self._mem_dict

    def reset(self, parser=None, timestamp=None, bitfile_name=None):
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
        self.client_request()
        if parser is not None:
            self._ip_dict = parser.ip_dict
            self._gpio_dict = parser.gpio_dict
            self._interrupt_controllers = parser.interrupt_controllers
            self._interrupt_pins = parser.interrupt_pins
            self._hierarchy_dict = parser.hierarchy_dict
            self._mem_dict = parser.mem_dict
        else:
            hwh_name = get_hwh_name(self._bitfile_name)
            tcl_name = get_tcl_name(self._bitfile_name)
            if os.path.isfile(hwh_name) or os.path.isfile(tcl_name):
                self._ip_dict = clear_state(self._ip_dict)
                self._gpio_dict = clear_state(self._gpio_dict)
            else:
                self.clear_dict()
        if timestamp is not None:
            self._timestamp = timestamp
        if bitfile_name is not None:
            self._bitfile_name = bitfile_name
        self.server_update()

    def clear_dict(self):
        """Clear all the dictionaries stored in PL.

        This method will clear all the related dictionaries, including IP
        dictionary, GPIO dictionary, etc.

        """
        self._ip_dict.clear()
        self._gpio_dict.clear()
        self._interrupt_controllers.clear()
        self._interrupt_pins.clear()
        self._hierarchy_dict.clear()
        self._mem_dict.clear()

    def load_ip_data(self, ip_name, data):
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
        self.client_request()
        self._ip_dict[ip_name]['state'] = data
        self.server_update()

    def update_partial_region(self, hier, parser):
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
        self.client_request()
        self._update_pr_ip(parser)
        self._update_pr_gpio(parser)
        self._update_pr_intr_pins(parser)
        self._update_pr_hier(hier)
        self.server_update()

    def _update_pr_ip(self, parser):
        merged_ip_dict = deepcopy(self._ip_dict)
        if type(parser) is HWH:
            for k, v in parser.ip_dict.items():
                if k in self._ip_dict:
                    merged_ip_dict.pop(k)
                    ip_name = v['fullpath']
                    merged_ip_dict[ip_name] = self._ip_dict[k]
                    merged_ip_dict[ip_name]['fullpath'] = v['fullpath']
                    merged_ip_dict[ip_name]['parameters'] = v['parameters']
                    merged_ip_dict[ip_name]['phys_addr'] = \
                        self._ip_dict[k]['phys_addr'] + v['phys_addr']
                    merged_ip_dict[ip_name]['registers'] = v['registers']
                    merged_ip_dict[ip_name]['state'] = None
                    merged_ip_dict[ip_name]['type'] = v['type']
        elif type(parser) is TCL:
            for k_partial, v_partial in parser.ip_dict.items():
                for k_full, v_full in self._ip_dict.items():
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
        self._ip_dict = merged_ip_dict

    def _update_pr_gpio(self, parser):
        new_gpio_dict = dict()
        for k, v in self._gpio_dict.items():
            for pin in v['pins']:
                if pin in parser.pins:
                    v |= parser.nets[parser.pins[pin]]
                new_gpio_dict[k] = v
        self._gpio_dict = new_gpio_dict

    def _update_pr_intr_pins(self, parser):
        new_interrupt_pins = dict()
        for k, v in self._interrupt_pins.items():
            if k in parser.pins:
                net_set = parser.nets[parser.pins[k]]
                hier_map = {i.count('/'): i for i in net_set}
                hier_map = sorted(hier_map.items(), reverse=True)
                fullpath = hier_map[0][-1]
                new_interrupt_pins[fullpath] = deepcopy(v)
                new_interrupt_pins[fullpath]['fullpath'] = fullpath
            else:
                new_interrupt_pins[k] = v
        self._interrupt_pins = new_interrupt_pins

    def _update_pr_hier(self, hier):
        self._hierarchy_dict[hier] = {
            'ip': dict(),
            'hierarchies': dict(),
            'interrupts': dict(),
            'gpio': dict(),
            'fullpath': hier,
            'memories': dict()
        }
        for name, val in self._ip_dict.items():
            hier, _, ip = name.rpartition('/')
            if hier:
                self._hierarchy_dict[hier]['ip'][ip] = val
                self._hierarchy_dict[hier]['ip'][ip] = val
        for name, val in self._hierarchy_dict.items():
            hier, _, subhier = name.rpartition('/')
            if hier:
                self._hierarchy_dict[hier]['hierarchies'][subhier] = val
        for interrupt, val in self._interrupt_pins.items():
            block, _, pin = interrupt.rpartition('/')
            if block in self._ip_dict:
                self._ip_dict[block]['interrupts'][pin] = val
            if block in self._hierarchy_dict:
                self._hierarchy_dict[block]['interrupts'][pin] = val
        for gpio in self._gpio_dict.values():
            for connection in gpio['pins']:
                ip, _, pin = connection.rpartition('/')
                if ip in self._ip_dict:
                    self._ip_dict[ip]['gpio'][pin] = gpio
                elif ip in self._hierarchy_dict:
                    self._hierarchy_dict[ip]['gpio'][pin] = gpio

    def clear_devicetree(self):
        """Clear the device tree dictionary.

        This should be used when downloading the full bitstream, where all the
        dtbo are cleared from the system.

        """
        for i in self._devicetree_dict:
            self._devicetree_dict[i].remove()

    def insert_device_tree(cls, abs_dtbo):
        """Insert device tree segment.

        For device tree segments associated with full / partial bitstreams,
        users can provide the relative or absolute paths of the dtbo files.

        Parameters
        ----------
        abs_dtbo : str
            The absolute path to the device tree segment.

        """
        cls.client_request()
        dtbo_base_name = get_dtbo_base_name(abs_dtbo)
        cls._devicetree_dict[dtbo_base_name] = DeviceTreeSegment(abs_dtbo)
        cls._devicetree_dict[dtbo_base_name].remove()
        cls._devicetree_dict[dtbo_base_name].insert()
        cls.server_update()

    def remove_device_tree(cls, abs_dtbo):
        """Remove device tree segment for the overlay.

        Parameters
        ----------
        abs_dtbo : str
            The absolute path to the device tree segment.

        """
        cls.client_request()
        dtbo_base_name = get_dtbo_base_name(abs_dtbo)
        cls._devicetree_dict[dtbo_base_name].remove()
        del cls._devicetree_dict[dtbo_base_name]
        cls.server_update()

    def client_request(self):
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
            self._remote = Client(self._address, family='AF_UNIX',
                                  authkey=self._key)
        except FileNotFoundError:
            raise ConnectionError(
                "Could not connect to PL server") from None
        self._bitfile_name, self._timestamp, \
            self._ip_dict, self._gpio_dict, \
            self._interrupt_controllers, \
            self._interrupt_pins, \
            self._hierarchy_dict, \
            self._devicetree_dict, \
            self._mem_dict = self._remote.recv()

    def server_update(self, continued=1):
        self._remote.send([self._bitfile_name,
                          self._timestamp,
                          self._ip_dict,
                          self._gpio_dict,
                          self._interrupt_controllers,
                          self._interrupt_pins,
                          self._hierarchy_dict,
                          self._devicetree_dict,
                          self._mem_dict,
                          continued])
        self._remote.close()
        pass


class DeviceServer:
    """Class to provide an instance of the PL server
    """
    def __init__(self, tag, key=b'xilinx'):
        self.tag = tag
        self.socket_name = PL_SERVER_TEMPLATE.format(tag)
        self.key = key
        self.thread = threading.Thread(target=self.server_proc)
        self._data = [
            "",      # Bitfile name
            None,    # Timestamp
            dict(),  # IP Dict
            dict(),  # GPIO Dict
            dict(),  # Interrupt Dict
            dict(),  # Interrupt Pin Dict
            dict(),  # Hierarchy Dict
            dict(),  # Devicetree dict
            dict()   # Memory Dict
        ]

    def start(self, daemonize=True):
        self.thread.daemon = daemonize
        self.thread.start()

    def server_proc(self):
        if os.path.exists(self.socket_name):
            os.remove(self.socket_name)
        server = Listener(self.socket_name, family='AF_UNIX', authkey=self.key)
        status = True
        while status:
            client = server.accept()
            client.send(self._data)
            new_data = client.recv()
            self._data = new_data[0:-1]
            status = new_data[-1]
            client.close()
        server.close()
        if os.path.exists(self.socket_name):
            os.remove(self.socket_name)

    def stop(self, wait_for_thread=True):
        client = DeviceClient(self.tag, self.key)
        client.client_request()
        client.server_update(0)
        if wait_for_thread:
            self.thread.join()


def _start_server():
    from .device import Device
    Device.start_global = True
    servers = [
        DeviceServer(d.tag) for d in Device.devices
    ]
    for s in servers:
        s.start(False)
    for s in servers:
        s.thread.join()


def _stop_server():
    from .device import Device
    Device.start_global = True
    servers = [
        DeviceServer(d.tag) for d in Device.devices
    ]
    for s in servers:
        # This is called from a separate process so the threads aren't started
        s.stop(False)
