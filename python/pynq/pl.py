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
__email__       = "xpp_support@xilinx.com"


import os
import sys
import re
import mmap
import math
from datetime import datetime
from pynq import general_const
from pynq import GPIO
from pynq import MMIO

def _get_tcl_name(bitfile_name):
    """This method returns the name of the *.tcl file.
    
    For example, the input "/home/xpp/src/pynq/bitstream/pmod.bit" will lead 
    to the result "/home/xpp/src/pynq/bitstream/pmod.tcl".
    
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
    
def _get_ip_names(tcl_name, ip_kwd=None):
    """This method returns a list of IPs containing ip_kwd.
    
    If ip_kwd is not specified, this method will return all the IPs 
    available in the tcl file. This method applies to all the addressable IPs.
    
    Note
    ----
    This method requires the absolute path of the '.tcl' file as input.
    The returned list may not be human-readable.
    Users can do the following to get a readable printout:
    >>> from pprint import pprint
    >>> pprint(result, width = 1))
    
    Parameters
    ----------
    tcl_name : str
        The absolute path of the .tcl file.
    ip_kwd : str
        The input keyword to search for in the bitstream.
        
    Returns
    -------
    list
        A list of the addressable IPs containing the ip_kwd.
        
    """
    if (not ip_kwd==None) and (not isinstance(ip_kwd, str)):
        raise TypeError("IP name has to be a string.")
        
    result = []
    with open(tcl_name, 'r') as f:
        for line in f:
            m = re.search('create_bd_addr_seg(.+?) '+\
                    '(\[.+?\]) (\[.+?\]) '+
                    '([A-Za-z0-9_]+)',line,re.IGNORECASE)
            if m:
                temp = m.group(4)
                if (ip_kwd is None) or (ip_kwd in temp.lower()):
                        result.append(temp)
        
    if result==[]:
        raise ValueError('No such addressable IPs in file {}.'\
                        .format(tcl_name))
    return result
                        
def _get_ip_addr_base(tcl_name, ip_name):
    """This method returns the MMIO base of an IP.
    
    This method applies to all the addressable IPs.
    
    Note
    ----
    This method requires the absolute path of the '.tcl' file as input.
    
    Parameters
    ----------
    tcl_name : str
        The absolute path of the .tcl file.
    ip_name : str
        The IP name to lookup in the bitstream.

    Returns
    -------
    str
        A string containing the hexadecimal representation of the base.
    
    """
    if not isinstance(ip_name, str):
        raise TypeError("IP name has to be a string.")
        
    result = None
    with open(tcl_name, 'r') as f:
        for line in f:
            m = re.search('create_bd_addr_seg(.+?)-offset '+\
                    '(0[xX][0-9a-fA-F]+)(.+?)'+ip_name,line,re.IGNORECASE)
            if m:
                result = m.group(2)
    
    if result==None:
        raise ValueError('No such addressable IP in file {}.'\
                        .format(tcl_name))
    return result
        
def _get_ip_addr_range(tcl_name, ip_name):
    """This method returns the MMIO range of an IP.
    
    This method applies to all the addressable IPs.
    
    Note
    ----
    This method requires the absolute path of the '.tcl' file as input.
    
    Parameters
    ----------
    tcl_name : str
        The absolute path of the .tcl file.
    ip_name : str
        The IP name to lookup in the bitstream.

    Returns
    -------
    str
        A string containing the hexadecimal representation of the range.
    
    """
    if not isinstance(ip_name, str):
        raise TypeError("IP name has to be a string.")
        
    result = None
    with open(tcl_name, 'r') as f:
        for line in f:
            m = re.search('create_bd_addr_seg -range '+\
                    '(0[xX][0-9a-fA-F]+)(.+?)'+ip_name,line,re.IGNORECASE)
            if m:
                result = m.group(1)
                
    if result==None:
        raise ValueError('No such addressable IP in file {}.'\
                        .format(tcl_name))
    return result
    
def _get_gpio_names(tcl_name):
    """The method to return a list of PS GPIO instance names.
    
    Note
    ----
    This method requires the absolute path of the '.tcl' file as input.
    The returned list may not be human-readable.
    Users can do the following to get a readable printout:
    >>> from pprint import pprint
    >>> pprint(result, width = 1))
    
    Parameters
    ----------
    tcl_name : str
        The absolute path of the .tcl file.
        
    Returns
    -------
    list
        A list of GPIO instance names.
        
    """
    pattern = 'connect_bd_net -net processing_system7_0_GPIO_O'
    result=[]
    with open(tcl_name, 'r') as f:
        for line in f:
            if pattern in line:
                result = re.findall('\[get_bd_pins (.+?)\]',line,re.IGNORECASE)
                
    if result==[]:
        raise ValueError('No such GPIO instances in file {}.'\
                        .format(tcl_name))
    return result
    
def _get_gpio_user_ix(tcl_name, gpio_kwd):
    """This method returns the user index of the GPIO for an IP.
    
    Note
    ----
    This method requires the absolute path of the '.tcl' file as input.
    For more information about the user GPIO pin, please check the GPIO class.
    
    Parameters
    ----------
    tcl_name : str
        The absolute path of the .tcl file.
    gpio_kwd : str
        The input keyword to search for in the bitstream.

    Returns
    -------
    int
        The user index of the GPIO, starting from 0.
    
    """
    if not isinstance(gpio_kwd, str):
        raise TypeError("PS GPIO name has to be a string.")
        
    gpio_list = _get_gpio_names(tcl_name)
    result = None
    for i in range(len(gpio_list)):
        if gpio_kwd in gpio_list[i]:
            result = i
            
    if result==None:
        raise ValueError('No such GPIO instances in file {}.'\
                        .format(tcl_name))
    return result
    
    
class PL:
    """This class serves as a singleton for "Overlay" and "Bitstream" classes.
    
    The IP dictionary stores the following information:
    1. name (str), the key of an entry.
    2. address (str), the base address of the IP.
    3. range (str), the address range of the IP.
    4. state (str), the state information about the IP.
    
    The PS GPIO dictionary stores the following information:
    1. name (str), the key of an entry.
    2. pin (int), the user index of the GPIO, starting from 0.
    
    The timestamp uses the following format:
    Follow a format of: (year, month, day, hour, minute, second, microsecond)
    
    Attributes
    ----------
    bitfile_name : str
        The absolute path of the bitstream currently on PL.
    timestamp : str
        Timestamp when loading the bitstream.
    ip_dict : dict
        The dictionary storing addressable IP instances; can be empty.
    gpio_dict : dict
        The dictionary storing the PS GPIO pins.
        
    """
    
    bitfile_name = general_const.BS_BOOT
    timestamp = ""
    ip_dict = {i : [_get_ip_addr_base(general_const.TCL_BOOT,i),
                    _get_ip_addr_range(general_const.TCL_BOOT,i),
                    None] 
                    for i in _get_ip_names(general_const.TCL_BOOT)}
    gpio_dict = {i : _get_gpio_user_ix(general_const.TCL_BOOT,i)
                    for i in _get_gpio_names(general_const.TCL_BOOT)}
                    
        
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
    def reset_ip_dict(cls):
        """Reset the IP dictionary.
        
        This class method is usually called after a bitstream download.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        tcl_name = _get_tcl_name(cls.bitfile_name)
        cls.ip_dict = {i : [_get_ip_addr_base(tcl_name,i),
                            _get_ip_addr_range(tcl_name,i),
                            None]
                            for i in _get_ip_names(tcl_name)}
    
    @classmethod
    def reset_gpio_dict(cls):
        """Reset the GPIO dictionary.
        
        This class method is usually called after a bitstream download.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        tcl_name = _get_tcl_name(cls.bitfile_name)
        gpio_dict = {i : _get_gpio_user_ix(tcl_name,i)
                    for i in _get_gpio_names(tcl_name)}
                        
    @classmethod
    def get_ip_names(cls, ip_kwd=None):
        """This method returns the IP names on PL.
        
        This method returns the information about the current overlay loaded. 
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
        if ip_kwd==None:
            return list(cls.ip_dict.keys())
        else:
            return [ip for ip in cls.ip_dict.keys() if ip_kwd in ip]
            
    @classmethod
    def get_ip_addr_base(cls, ip_name):
        """This method returns the base address for an IP on PL.
        
        Returns the information about the current overlay loaded.
        
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
        return cls.ip_dict[ip_name][0]
        
    @classmethod
    def get_ip_addr_range(cls, ip_name):
        """This method returns the address range for an IP on PL.
        
        Returns the information about the current overlay loaded.
        
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
        return cls.ip_dict[ip_name][1]
        
    @classmethod
    def get_ip_state(cls, ip_name):
        """This method returns the state about an addressable IP.
        
        Returns the information about the current overlay loaded. The state 
        information can be used for general purposes, e.g., a program running
        on the IP.
        
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
        return cls.ip_dict[ip_name][2]
    
    @classmethod
    def get_gpio_names(cls, gpio_kwd=None):
        """This method returns the GPIO instance names on PL.
        
        This method returns the information about the current overlay loaded. 
        If the gpio_kwd is not specified, this method returns the entire list; 
        otherwise it returns the GPIO instance names containing the gpio_kwd.
        
        Note
        ----
        The PS GPIO dictionary stores the following information:
        1. name (str), the key of an entry.
        2. pin (int), the user index of the GPIO, starting from 0.
        
        Parameters
        ----------
        gpio_kwd : str
            The input keyword to search for in the overlay.

        Returns
        -------
        list
            A list of the GPIO instance names containing the gpio_kwd.
        
        """
        if gpio_kwd==None:
            return list(cls.gpio_dict.keys())
        else:
            return [gpio for gpio in cls.gpio_dict.keys() if gpio_kwd in gpio]
            
    @classmethod
    def get_gpio_user_ix(cls, gpio_name):
        """This method returns the user GPIO pin for an IP.
        
        Returns the information about the current overlay loaded.
        
        Note
        ----
        The PS GPIO dictionary stores the following information:
        1. name (str), the key of an entry.
        2. pin (int), the user index of the GPIO, starting from 0.
        
        Parameters
        ----------
        gpio_name : str
            The name of the PS GPIO pin.

        Returns
        -------
        int
            The user index of the GPIO, starting from 0.
        
        """
        return cls.gpio_dict[gpio_name]

class Bitstream(PL):
    """This class provides the bitstreams that can be downloaded.
    
    Note
    ----
    To avoid confusion, self.bitstream always stores an absolute path.
    
    Attributes
    ----------
    bitfile_name : str
        The absolute path of the bitstream.
    timestamp : str
        Timestamp when loading the bitstream. Follow a format of:
        (year, month, day, hour, minute, second, microsecond)
        
    """
    
    def __init__(self, bitfile_name):
        """Return a new Bitstream object. 
        
        Users can either specify an absolute path to the bitstream file 
        (e.g. '/home/xpp/src/pynq/bitstream/pmod.bit'),
        or only a relative path.
        (e.g. 'pmod.bit').
        
        Note
        ----
        To avoid any confusion, always use consistent representation.
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
        #: Compose bitfile name, open bitfile
        with open(self.bitfile_name, 'rb') as f:
            buf = f.read()
        
        #: Set is_partial_bitfile device attribute to 0        
        with open(general_const.BS_IS_PARTIAL, 'w') as fd:
            fd.write('0')
        
        #: Write bitfile to xdevcfg device
        with open(general_const.BS_XDEVCFG, 'wb') as f:
            f.write(buf)
        
        t = datetime.now()
        self.timestamp = "{}/{}/{} {}:{}:{} +{}".format(t.year,t.month,t.day,\
                                t.hour,t.minute,t.second,t.microsecond)
        PL.bitfile_name = self.bitfile_name
        PL.timestamp = self.timestamp
        PL.reset_ip_dict()
        PL.reset_gpio_dict()
        
class Overlay(PL):
    """The Overlay class keeps track of a single bitstream.
    
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
        This method requires the '.tcl' file association.
        
        Parameters
        ----------
        bitfile_name : str
            The bitstream name or absolute path as a string.
            
        """
        super().__init__()
        
        #: Set the bitfile name
        if not isinstance(bitfile_name, str):
            raise TypeError("Bitstream name has to be a string.")
        if os.path.isfile(bitfile_name):
            self.bitfile_name = bitfile_name
        elif os.path.isfile(general_const.BS_SEARCH_PATH + bitfile_name):
            self.bitfile_name = general_const.BS_SEARCH_PATH + bitfile_name
        else:
            raise IOError('Bitstream file {} does not exist.'\
                            .format(bitfile_name))
        
        #: Set the bitstream
        self.bitstream = Bitstream(self.bitfile_name)
        tcl_name = _get_tcl_name(self.bitfile_name)
        
        #: Set the IP dictionary
        self.ip_dict = {i : [_get_ip_addr_base(tcl_name,i),
                            _get_ip_addr_range(tcl_name,i),
                            None] 
                            for i in _get_ip_names(tcl_name)}
                        
        #: Set the GPIO dictionary
        self.gpio_dict = {i : _get_gpio_user_ix(tcl_name,i)
                            for i in _get_gpio_names(tcl_name)}
        
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
        
    def get_timestamp(self):
        """This method returns the timestamp of the bitstream.
        
        The timestamp will be empty unless the bitstream is downloaded.
        
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
        
        This method returns true if the timestamps are the same. 
        The method also returns true if the two bitstreams have the same name.
        
        Parameters
        ----------
        None

        Returns
        -------
        bool
            True if bitstream is loaded.
            
        """
        if not self.bitstream.timestamp=='':
            return self.bitstream.timestamp==PL.timestamp
        else:
            return self.bitfile_name==PL.bitfile_name
    
    def load_ip_data(self, ip_name, data):
        """This method loads the data to the addressable IP.
        
        This method can also be used for programming the IP. For example, 
        users can use this method to load the program to the Microblaze 
        processors on PL.
        
        Note
        ----
        The data is assumed to be in binary format (*.bin). The data name will
        be stored as a state information in the IP dictionary.
        
        Parameters
        ----------
        ip_name : str
            The name of the addressable IP.
        data : str
            The absolute path of the program to be loaded.
        
        Returns
        -------
        None
        
        Raises
        ------
        LookupError
            If the overlay is not loaded yet.
        
        """
        if not self.is_loaded():
            raise LookupError("The current overlay has not been loaded.")
        else:
            with open(data, 'rb') as bin:
                size = (math.ceil(os.fstat(bin.fileno()).st_size/ \
                        mmap.PAGESIZE))*mmap.PAGESIZE
                mmio = MMIO(int(self.ip_dict[ip_name][0], 16), size)
                buf = bin.read(size)
                mmio.write(0, buf)
                
            self.ip_dict[ip_name][2] = data
            PL.ip_dict[ip_name][2] = data
            
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
        self.ip_dict = {i : [_get_ip_addr_base(tcl_name,i),
                            _get_ip_addr_range(tcl_name,i),
                            None]
                            for i in _get_ip_names(tcl_name)}
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
        gpio_dict = {i : _get_gpio_user_ix(tcl_name,i)
                    for i in _get_gpio_names(tcl_name)}
        if self.is_loaded():
            PL.reset_gpio_dict()
                    
    def get_ip_addr_base(self, ip_name):
        """This method returns the base address for an IP on the overlay.
        
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
        """This method returns the address range for an IP on the overlay.
        
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
        """This method returns the state about an addressable IP.
        
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
    
    def get_gpio_user_ix(self, gpio_name):
        """This method returns the user index of the GPIO for an IP.
        
        Note
        ----
        The PS GPIO dictionary stores the following information:
        1. name (str), the key of an entry.
        2. pin (int), the user index of the GPIO, starting from 0.
        
        Parameters
        ----------
        gpio_name : str
            The name of the PS GPIO pin.

        Returns
        -------
        int
            The user index of the GPIO, starting from 0.
        
        """
        return self.gpio_dict[gpio_name]
            
