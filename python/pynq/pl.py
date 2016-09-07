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

__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


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
    return os.path.splitext(bitfile_name)[0]+'.tcl'
                        
def _get_dict_ip_addr(tcl_name):
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
    result = {}
    with open(tcl_name, 'r') as f:
        for line in f:
            m = re.search('create_bd_addr_seg -range (0[xX][0-9a-fA-F]+) '+\
                    '-offset (0[xX][0-9a-fA-F]+) '+\
                    '\[get_bd_addr_spaces (processing_system7_0|ps7)/Data\] '+\
                    '(\[.+?\]) '+\
                    '([A-Za-z0-9_]+)',line,re.IGNORECASE)
            if m:
                # Each entry is [base, range, state]
                result[m.group(5)] = [m.group(2), m.group(1), None]
                
    return result
    
def _get_dict_gpio(tcl_name):
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
                gpio_list = re.findall('\[get_bd_pins (.+?)/Din\]',\
                                        line,re.IGNORECASE)
    
    match1 = 0
    for i in range(len(gpio_list)):
        name = gpio_list[i].split('/')[0]
        pat3 = "set "+ name
        pat4 = "CONFIG.DIN_FROM {([0-9]+)}*"
        with open(tcl_name, 'r') as f:
            for line in f:
                if pat3 in line:
                    match1 = 1
                    continue
                if match1==1:
                    match2 = re.search(pat4,line,re.IGNORECASE)
                    if match2:
                        index = match2.group(1)
                        match1 = 0
                        break
        result[gpio_list[i]] = [int(index), None]
        
    return result
    
class PL_Meta(type):
    """This method is the meta class for the PL.
    
    This is not a class for users. Hence there is no attribute or method 
    exposed to users.
    
    """
    @property
    def bitfile_name(cls):
        """The getter for the attribute `bitfile_name`.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        str
            The absolute path of the bitstream currently on PL.
        
        """
        cls._client_request()
        cls._server_update()
        return cls._bitfile_name
        
    @property
    def timestamp(cls):
        """The getter for the attribute `timestamp`.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        str
            Bitstream download timestamp.
        
        """
        cls._client_request()
        cls._server_update()
        return cls._timestamp
        
    @property
    def ip_dict(cls):
        """The getter for the attribute `ip_dict`.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        dict
            The dictionary storing addressable IP instances; can be empty.
            
        """
        cls._client_request()
        cls._server_update()
        return cls._ip_dict
        
    @property
    def gpio_dict(cls):
        """The getter for the attribute `gpio_dict`.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        dict
            The dictionary storing the PS GPIO pins.
            
        """
        cls._client_request()
        cls._server_update()
        return cls._gpio_dict
        
class PL(metaclass=PL_Meta):
    """Serves as a singleton for "Overlay" and "Bitstream" classes.
    
    The IP dictionary stores the following information:
    1. name (str), the key of an IP entry.
    2. address (str), the base address of the IP.
    3. range (str), the address range of the IP.
    4. state (str), the state information about the IP.
    
    The PS GPIO dictionary stores the following information:
    1. name (str), the key of an IP entry.
    2. pin (int), the PS GPIO index, starting from 0.
    3. state (str), the state information about the GPIO.
    
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
    _ip_dict = _get_dict_ip_addr(general_const.TCL_BOOT)
    _gpio_dict = _get_dict_gpio(general_const.TCL_BOOT)
        
    def __init__(self):
        """Return a new PL object.
        
        Parameters
        ----------
        None
        
        """
        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('Root permissions required.')
            
    @classmethod
    def _setup(cls, address='/home/xilinx/pynq/bitstream/.log', key=b'xilinx'):
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
            # Accept connections
            cls._host = cls._server.accept()
            # Send the PL attrib utes
            cls._host.send([cls._bitfile_name, cls._timestamp, \
                            cls._ip_dict, cls._gpio_dict])
            # Receive the PL attributes
            [cls._bitfile_name, cls._timestamp, cls._ip_dict, \
                        cls._gpio_dict, cls._status] = cls._host.recv()
            # Close the connection
            cls._host.close()
            
        # Server stopped
        cls._server.close()
        
    @classmethod
    def _client_request(cls, address='/home/xilinx/pynq/bitstream/.log',
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
        [cls._bitfile_name, cls._timestamp, \
                cls._ip_dict, cls._gpio_dict] = cls._remote.recv()
    
    @classmethod
    def _server_update(cls,continued=1):
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
        cls._remote.send([cls._bitfile_name, cls._timestamp, \
                            cls._ip_dict, cls._gpio_dict, continued])
        cls._remote.close()
        
    @classmethod
    def reset_ip_dict(cls):
        """Reset the IP dictionary.
        
        This method must be called after a bitstream download.
        1. In case there is a `*.tcl` file, this method will set the IP 
        dictionary to what is provided by the tcl file.
        2. In case there is no `*.tcl` file, this method will simply clear
        the state information stored in the IP dictionary.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        cls._client_request()
        tcl_name = _get_tcl_name(cls._bitfile_name)
        if os.path.isfile(tcl_name):
            cls._ip_dict = _get_dict_ip_addr(tcl_name)
        else:
            for i in cls._ip_dict.keys():
                cls._ip_dict[i][2] = None
        cls._server_update()
        
    @classmethod
    def reset_gpio_dict(cls):
        """Reset the GPIO dictionary.
        
        This method must be called after a bitstream download.
        1. In case there is a `*.tcl` file, this method will set the GPIO 
        dictionary to what is provided by the tcl file.
        2. In case there is no `*.tcl` file, this method will simply clear
        the state information stored in the GPIO dictionary.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        cls._client_request()
        tcl_name = _get_tcl_name(cls._bitfile_name)
        if os.path.isfile(tcl_name):
            cls._gpio_dict = _get_dict_gpio(tcl_name)
        else:
            for i in cls._gpio_dict.keys():
                cls._gpio_dict[i][1] = None
        cls._server_update()
        
    @classmethod
    def reset(cls):
        """Reset both the IP and GPIO dictionaries.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        cls._client_request()
        tcl_name = _get_tcl_name(cls._bitfile_name)
        if os.path.isfile(tcl_name):
            cls._ip_dict = _get_dict_ip_addr(tcl_name)
            cls._gpio_dict = _get_dict_gpio(tcl_name)
        else:
            for i in cls._ip_dict.keys():
                cls._ip_dict[i][2] = None
            for i in cls._gpio_dict.keys():
                cls._gpio_dict[i][1] = None
        cls._server_update()
        
    @classmethod
    def get_ip_names(cls, ip_kwd=None):
        """This method returns the IP names in the PL.
        
        This method returns information about the current overlay loaded. 
        If the ip_kwd is not specified, this method returns the entire list; 
        otherwise it returns the IP names containing the ip_kwd.
        
        Note
        ----
        The IP dictionary stores the following information:
        1. name (str), the key of an entry.
        2. address (str), the base address of the IP.
        3. range (str), the address range of the IP.
        4. state (str), the state information about the IP.
        
        Parameters
        ----------
        ip_kwd : str
            The input keyword to search for in the overlay.

        Returns
        -------
        list
            A list of the addressable IPs containing the ip_kwd.
        
        """
        cls._client_request()
        cls._server_update()
        if ip_kwd==None:
            return list(cls._ip_dict.keys())
        else:
            return [ip for ip in cls._ip_dict.keys() if ip_kwd in ip]
            
    @classmethod
    def get_ip_addr_base(cls, ip_name):
        """This method returns the base address for an IP in the PL.
        
        Note
        ----
        The IP dictionary stores the following information:
        1. name (str), the key of an entry.
        2. address (str), the base address of the IP.
        3. range (str), the address range of the IP.
        4. state (str), the state information about the IP.
        
        Parameters
        ----------
        ip_name : str
            The name of the addressable IP.

        Returns
        -------
        str
            The base address in hex format.
        
        """
        cls._client_request()
        cls._server_update()
        return cls._ip_dict[ip_name][0]
        
    @classmethod
    def get_ip_addr_range(cls, ip_name):
        """This method returns the address range for an IP in the PL.
        
        Note
        ----
        The IP dictionary stores the following information:
        1. name (str), the key of an entry.
        2. address (str), the base address of the IP.
        3. range (str), the address range of the IP.
        4. state (str), the state information about the IP.
        
        Parameters
        ----------
        ip_name : str
            The name of the addressable IP.

        Returns
        -------
        str
            The address range in hex format.
        
        """
        cls._client_request()
        cls._server_update()
        return cls._ip_dict[ip_name][1]
        
    @classmethod
    def get_ip_state(cls, ip_name):
        """This method returns the state about an addressable IP.
        
        Returns information about a currently loaded IP. This general 
        purpose state's meaning is defined by the loaded Overlay.  
        E.g., can specify what program is running on a soft processor.
        
        Note
        ----
        The IP dictionary stores the following information:
        1. name (str), the key of an entry.
        2. address (str), the base address of the IP.
        3. range (str), the address range of the IP.
        4. state (str), the state information about the IP.
        
        Parameters
        ----------
        ip_name : str
            The name of the addressable IP.

        Returns
        -------
        str
            The state of the addressable IP.
        
        """
        cls._client_request()
        cls._server_update()
        return cls._ip_dict[ip_name][2]
        
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
        cls._client_request()
        with open(data, 'rb') as bin:
            size = (math.ceil(os.fstat(bin.fileno()).st_size/ \
                    mmap.PAGESIZE))*mmap.PAGESIZE
            mmio = MMIO(int(cls._ip_dict[ip_name][0], 16), size)
            buf = bin.read(size)
            mmio.write(0, buf)
            
        cls._ip_dict[ip_name][2] = data
        cls._server_update()
        
    @classmethod
    def get_gpio_names(cls, gpio_kwd=None):
        """This method returns PS GPIO accessible IP.
        
        This method returns the information about the current overlay loaded. 
        If the gpio_kwd is not specified, this method returns the entire list; 
        otherwise it returns the GPIO instance names containing the gpio_kwd.
        
        Note
        ----
        The PS GPIO dictionary stores the following information:
        1. name (str), the key of an entry.
        2. pin (int), the user index of the GPIO, starting from 0.
        3. state (str), the state information about the GPIO.
        
        Parameters
        ----------
        gpio_kwd : str
            The input keyword to search for in the overlay.

        Returns
        -------
        list
            A list of the GPIO instance names containing the gpio_kwd.
        
        """
        cls._client_request()
        cls._server_update()
        if gpio_kwd==None:
            return list(cls._gpio_dict.keys())
        else:
            return [gpio for gpio in cls._gpio_dict.keys() if gpio_kwd in gpio]
            
    @classmethod
    def get_gpio_user_ix(cls, gpio_name):
        """This method returns the PS GPIO index for an IP.
        
        Note
        ----
        The PS GPIO dictionary stores the following information:
        1. name (str), the key of an entry.
        2. pin (int), the user index of the GPIO, starting from 0.
        3. state (str), the state information about the GPIO.
        
        Parameters
        ----------
        gpio_name : str
            The name of the PS GPIO pin.

        Returns
        -------
        int
            The user index of the GPIO, starting from 0.
        
        """
        cls._client_request()
        cls._server_update()
        return cls._gpio_dict[gpio_name][0]
        
    @classmethod
    def get_gpio_state(cls, gpio_name):
        """This method returns the state for a GPIO.
        
        Note
        ----
        The PS GPIO dictionary stores the following information:
        1. name (str), the key of an entry.
        2. pin (int), the user index of the GPIO, starting from 0.
        3. state (str), the state information about the GPIO.
        
        Parameters
        ----------
        gpio_name : str
            The name of the PS GPIO pin.
            
        Returns
        -------
        str
            The state of the GPIO pin.
        
        """
        cls._client_request()
        cls._server_update()
        return cls._gpio_dict[gpio_name][1]
        
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
            raise IOError('Bitstream file {} does not exist.'\
                            .format(bitfile_name))
            
        self.timestamp = ''

    def download(self):
        """The method to download the bitstream onto PL. 
        
        Note
        ----
        The class variables held by the singleton PL will also be updated.

        Parameters
        ----------
        None

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
        self.timestamp = "{}/{}/{} {}:{}:{} +{}".format(t.year,t.month,t.day,\
                                t.hour,t.minute,t.second,t.microsecond)
        
        # Update PL information
        PL._client_request()
        PL._bitfile_name = self.bitfile_name
        PL._timestamp = self.timestamp
        PL._ip_dict = {}
        PL._gpio_dict = {}
        PL._server_update()
        
class Overlay(PL):
    """This class keeps track of a single bitstream's state and contents.
    
    The overlay class holds the state of the bitstream and enables run-time 
    protection of bindlings. 
    Our definition of overlay is: "post-bitstream configurable design". 
    Hence, this class must expose configurability through content discovery 
    and runtime protection.
    
    The IP dictionary stores the following information:
    1. name (str), the key of an entry.
    2. address (str), the base address of the IP.
    3. range (str), the address range of the IP.
    4. state (str), the state information about the IP.
    
    The PS GPIO dictionary stores the following information:
    1. name (str), the key of an entry.
    2. pin (int), the user index of the GPIO, starting from 0.
    3. state (str), the state information about the GPIO.
    
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
            raise IOError('Bitstream file {} does not exist.'\
                            .format(bitfile_name))
        
        # Set the bitstream
        self.bitstream = Bitstream(self.bitfile_name)
        tcl_name = _get_tcl_name(self.bitfile_name)
        
        # Set the IP dictionary
        self.ip_dict = _get_dict_ip_addr(tcl_name)
                        
        # Set the GPIO dictionary
        self.gpio_dict = _get_dict_gpio(tcl_name)
        
    def download(self):
        """The method to download a bitstream onto PL.
        
        Note
        ----
        After the bitstream has been downloaded, the "timestamp" in PL will be 
        updated. In addition, both of the IP and GPIO dictionaries on PL will 
        be reset automatically. 
        
        Parameters
        ----------
        None

        Returns
        -------
        None
        
        """
        self.bitstream.download()
        PL.reset_ip_dict()
        PL.reset_gpio_dict()
        
    def get_timestamp(self):
        """This method returns the timestamp of the bitstream.
        
        The timestamp will be empty string until the bitstream is downloaded.
        
        Parameters
        ----------
        None

        Returns
        -------
        str
            The timestamp when the bitstream is downloaded.
            
        """
        return self.bitstream.timestamp
            
    def is_loaded(self):
        """This method checks whether a bitstream is loaded.
        
        This method returns true if the loaded PL bitstream is same 
        as this Overlay's member bitstream.
        
        Parameters
        ----------
        None

        Returns
        -------
        bool
            True if bitstream is loaded.
            
        """
        PL._client_request()
        PL._server_update()
        if not self.bitstream.timestamp=='':
            return self.bitstream.timestamp==PL._timestamp
        else:
            return self.bitfile_name==PL._bitfile_name
            
    def reset_ip_dict(self):
        """This function resets the entire IP dictionary of the overlay.
        
        This function is usually called before instantiating new objects on
        the same overlay. In that case, the GPIO dictionary does not have to
        be reset.
        
        Note
        ----
        This function should be used with caution since it resets the IP
        dictionary; the state information will be lost. If the overlay is 
        loaded, it also resets the IP dictionary in the PL.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        tcl_name = _get_tcl_name(self.bitfile_name)
        self.ip_dict = _get_dict_ip_addr(tcl_name)
        if self.is_loaded():
            PL.reset_ip_dict()
    
    def reset_gpio_dict(self):
        """This function resets the entire GPIO dictionary of the overlay.
        
        Note
        ----
        This function should be used with caution since it resets the 
        GPIO dictionary. If the overlay is loaded, it also resets the GPIO
        dictionary in the PL.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        tcl_name = _get_tcl_name(self.bitfile_name)
        self.gpio_dict = _get_dict_gpio(tcl_name)
        if self.is_loaded():
            PL.reset_gpio_dict()
            
    def reset(self):
        """This function resets the IP and GPIO dictionaries of the overlay.
        
        Note
        ----
        This function should be used with caution. If the overlay is loaded, 
        it also resets the IP and GPIO dictionaries in the PL.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        self.reset_ip_dict()
        self.reset_gpio_dict()
        
    def get_ip_addr_base(self, ip_name):
        """This method returns the base address of an IP in this overlay.
        
        Note
        ----
        The IP dictionary stores the following information:
        1. name (str), the key of an entry.
        2. address (str), the base address of the IP.
        3. range (str), the address range of the IP.
        4. state (str), the state information about the IP.
        
        Parameters
        ----------
        ip_name : str
            The name of the addressable IP.

        Returns
        -------
        str
            The base address in hex format.
        
        """
        return self.ip_dict[ip_name][0]
        
    def get_ip_addr_range(self, ip_name):
        """This method returns an IP's address range in this overlay.
        
        Note
        ----
        The IP dictionary stores the following information:
        1. name (str), the key of an entry.
        2. address (str), the base address of the IP.
        3. range (str), the address range of the IP.
        4. state (str), the state information about the IP.
        
        Parameters
        ----------
        ip_name : str
            The name of the addressable IP.

        Returns
        -------
        str
            The address range in hex format.
        
        """
        return self.ip_dict[ip_name][1]
        
    def get_ip_state(self, ip_name):
        """This method returns the state of an addressable IP.
        
        Note
        ----
        The IP dictionary stores the following information:
        1. name (str), the key of an entry.
        2. address (str), the base address of the IP.
        3. range (str), the address range of the IP.
        4. state (str), the state information about the IP.
        
        Parameters
        ----------
        ip_name : str
            The name of the addressable IP.

        Returns
        -------
        str
            The state of the addressable IP.
        
        """
        return self.ip_dict[ip_name][2]
        
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
        
    def get_gpio_user_ix(self, gpio_name):
        """This method returns the user index of the GPIO.
        
        Note
        ----
        The PS GPIO dictionary stores the following information:
        1. name (str), the key of an entry.
        2. pin (int), the user index of the GPIO, starting from 0.
        3. state (str), the state information about the GPIO.
        
        Parameters
        ----------
        gpio_name : str
            The name of the PS GPIO pin.

        Returns
        -------
        int
            The user index of the GPIO, starting from 0.
        
        """
        return self.gpio_dict[gpio_name][0]
        
    def get_gpio_state(self, gpio_name):
        """This method returns the state of the GPIO.
        
        Note
        ----
        The PS GPIO dictionary stores the following information:
        1. name (str), the key of an entry.
        2. pin (int), the user index of the GPIO, starting from 0.
        3. state (str), the state information about the GPIO.
        
        Parameters
        ----------
        gpio_name : str
            The name of the PS GPIO pin.

        Returns
        -------
        str
            The state information about the GPIO.
        
        """
        return self.gpio_dict[gpio_name][1]
            
