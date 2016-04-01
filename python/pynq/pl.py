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
    
class PL:
    """This class serves as a singleton for "Overlay" and "Bitstream" classes.
    
    The dictionary of programmable IPs stores the following information:
    1. key (int), index starting from 0.
    2. address (str), the base address of the IP.
    3. program (str), the program (e.g. ".bin") loaded on the IP.
    4. psgpio (int), the GPIO pin used for control.
    
    Attributes
    ----------
    bitstream : str
        The name of the bitstream currently loaded on PL.
    timestamp : str
        Timestamp when loading the bitstream. Follow a format of:
        (year, month, day, hour, minute, second, microsecond)
    prog_ips : dict
        The dictionary storing alive programmable IP instances; can be empty.
        
    """
    
    bitstream = general_const.BS_BOOT
    timestamp = ""
    prog_ips = general_const.PL_IP_DICT

    def __init__(self):
        """Return a new PL object.
        
        Parameters
        ----------
        None
        
        """
        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('Root permissions required.')
          
class Bitstream(PL):
    """This class provides the bitstreams that can be downloaded.
    
    Note
    ----
    To avoid confusion, self.bitstream always stores an absolute path.
    
    Attributes
    ----------
    bitstream : str
        The absolute path of the bitstream.
    timestamp : str
        Timestamp when loading the bitstream. Follow a format of:
        (year, month, day, hour, minute, second, microsecond)
        
    """
    
    def __init__(self, bitfile_name):
        """Return a new Bitstream object. 
        
        Users can either specify an absolute path to the bitstream file 
        (e.g. '/home/xpp/src/pynq/bitstream/pmod.bit'),
        or only the bitstream name 
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
            self.bitstream = bitfile_name
        elif os.path.isfile(general_const.BS_SEARCH_PATH + bitfile_name):
            self.bitstream = general_const.BS_SEARCH_PATH + bitfile_name
        else:
            raise IOError('Bitstream file {} does not exist.'\
                            .format(bitfile_name))
            
        self.timestamp = ''

    def download(self):
        """The method to download the bitstream onto PL. 
        
        Note
        ----
        The "bitstream" and "timestamp" held by the singleton PL will also 
        be updated accordingly.

        Parameters
        ----------
        None

        Returns
        -------
        None
            
        """
        #: Compose bitfile name, open bitfile
        with open(self.bitstream, 'rb') as f:
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
        PL.bitstream = self.bitstream
        PL.timestamp = self.timestamp
        
class Overlay(PL):
    """The Overlay class keeps track of a single bitstream.
    
    The overlay class holds the state of the bitstream and enables run-time 
    protection of bindlings. 
    Our definition of overlay is: "post-bitstream configurable design". 
    Hence, this class must expose configurability through content discovery 
    and runtime protection.
    
    The dictionary of programmable IPs stores the following information:
    1. key (int), index starting from 0.
    2. address (str), the base address of the IP.
    3. program (str), the program (e.g. ".bin") loaded on the IP.
    4. psgpio (int), the GPIO pin used for control.
    
    Attributes
    ----------
    bitfile_name : str
        The absolute path of the bitstream.
    bitstream : Bitstream
        The corresponding bitstream object.
    prog_ips : dict
        The programmable IP instances on the overlay.
        
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
        
        if not isinstance(bitfile_name, str):
            raise TypeError("Bitstream name has to be a string.")
        
        if os.path.isfile(bitfile_name):
            self.bitfile_name = bitfile_name
        elif os.path.isfile(general_const.BS_SEARCH_PATH + bitfile_name):
            self.bitfile_name = general_const.BS_SEARCH_PATH + bitfile_name
        else:
            raise IOError('Bitstream file {} does not exist.'\
                            .format(bitfile_name))
            
        self.bitstream = Bitstream(self.bitfile_name)
        self.prog_ips = {}
        self.set_prog_ips()
        
    def set_prog_ips(self, mmio_kwd='axi_bram_ctrl_', 
                     psgpio_kwd='get_bd_pins mb_'):
        """Set the dictionary for the programmable IPs.
        
        This method will be called during the initialization. Users can also
        call it again to refresh the dictionary. 
        The default values of the parameters can be used for Microblaze 
        processors.
        
        Note
        ----
        This method requires the '.tcl' file association.
        
        Parameters
        ----------
        mmio_kwd : str
            The keyword to search for the MMIO address.
        psgpio_kwd : str
            The keyword to search for the PS GPIO pin.
            
        Returns
        -------
        None
            
        """
        #: Sets the base address for the programmable IPs
        tcl_name = os.path.splitext(self.bitfile_name)[0]+'.tcl'
        with open(tcl_name, 'r') as f:
            addr = None
            ip_id = 0
            for line in f:
                m = re.search('create_bd_addr_seg(.+?)-offset '+ \
                        '(0[xX][0-9a-fA-F]+)(.+?)'+ mmio_kwd + \
                        '([0-9]+)(.+?)',line,re.IGNORECASE)
                if m:
                    addr = m.group(2)
                    self.prog_ips[ip_id] = [addr, None, None]
                    ip_id += 1
            
        #: Sets the psgpio pins for the programmable IPs
        with open(tcl_name, 'r') as f:
            all_pins = None
            pattern = 'connect_bd_net -net processing_system7_0_GPIO_O'
            for line in f:
                if pattern in line:
                    ip_id = 0
                    all_pins = re.findall('\[(.+?)\]',line,re.IGNORECASE)
                    for i in range(len(all_pins)):
                        if (psgpio_kwd in all_pins[i]):
                            self.prog_ips[ip_id][2] = GPIO.get_gpio_pin(ip_id)
                            ip_id += 1
    
    def get_bitfile_name(self):
        """The method to get the bitstream name.
        
        Note
        ----
        Can call this even before the bitstream is downloaded. The bitstream 
        name is expressed in its absolute path.
        
        Parameters
        ----------
        None

        Returns
        -------
        str
            The name of the bitstream in the overlay.
        
        """
        return self.bitfile_name
        
    def download(self):
        """The method to download a bitstream onto PL.
        
        Note
        ----
        After the bitstream has been downloaded, the "timestamp" in PL will be 
        updated. In addition, the program recorded in the dictionary 
        "prog_ips" in PL will be cleared.
        
        Parameters
        ----------
        None

        Returns
        -------
        None
        
        """
        self.bitstream.download()
        for i in self.prog_ips.keys():
            self.prog_ips[i][1] = None
        PL.prog_ips = self.prog_ips
        
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
        
        First check whether the timestamps are the same. Otherwise if the two
        bitstreams have the same name, this method will also consider this 
        case as loaded.
        
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
            return self.bitfile_name==PL.bitstream
        
    def get_ip(self, ip_name=None):
        """The method to return a list of IPs containing ip_name.
        
        If ip_name is not specified, this method will return all the IPs 
        available in the overlay. This method applies to all the programmable 
        and non-programmable IPs.
        
        Note
        ----
        This method requires the '.tcl' file association.
        The returned list may not be human-readable.
        Users can do the following to get a readable printout:
        >>> from pprint import pprint
        >>> pprint(result, width = 1))
        
        Parameters
        ----------
        ip_name : str
            The input keyword to search for in the bitstream.

        Returns
        -------
        list
            The list of the addressable IPs containing the input keyword.
            
        """
        if (not ip_name is None) and (not isinstance(ip_name, str)):
            raise TypeError("IP name has to be a string.")
                        
        #: tcl will be absolute path
        tcl_name = os.path.splitext(self.bitfile_name)[0]+'.tcl'
        result = []
        with open(tcl_name, 'r') as f:
            for line in f:
                m = re.search('create_bd_addr_seg(.+?) '+\
                        '(\[.+?\]) (\[.+?\]) '+
                        '([A-Za-z0-9_]+)',line,re.IGNORECASE)
                if m:
                    temp = m.group(4)
                    if (ip_name is None) or (ip_name in temp.lower()):
                        result.append(temp)
        
        if result is []:
            raise ValueError('No such addressable IPs in bitstream {}.'\
                            .format(self.bitfile_name))
        return result
                    
    def get_ip_addr_base(self, ip_name):
        """This method returns the MMIO base of an IP.
        
        This method applies to all the programmable and non-programmable IPs.
        
        Note
        ----
        This method requires the '.tcl' file association.
        
        Parameters
        ----------
        ip_name : str
            The input keyword to search for in the bitstream.

        Returns
        -------
        str
            A string containing the hexadecimal representation of the base.
        
        """
        if not isinstance(ip_name, str):
            raise TypeError("IP name has to be a string.")
        
        #: tcl_name will be absolute path
        tcl_name = os.path.splitext(self.bitfile_name)[0]+'.tcl'
        result = None
        with open(tcl_name, 'r') as f:
            for line in f:
                m = re.search('create_bd_addr_seg(.+?)-offset '+\
                        '(0[xX][0-9a-fA-F]+)(.+?)'+ip_name,line,re.IGNORECASE)
                if m:
                    result = m.group(2)
        
        if result is None:
            raise ValueError('No such addressable IP in bitstream {}.'\
                            .format(self.bitfile_name))
        return result
        
    def get_ip_addr_range(self, ip_name):
        """This method returns the MMIO range of an IP.
        
        This method applies to all the programmable and non-programmable IPs.
        
        Note
        ----
        This method requires the '.tcl' file association.
        
        Parameters
        ----------
        ip_name : str
            The input keyword to search for in the bitstream.

        Returns
        -------
        str
            A string containing the hexadecimal representation of the range.
            
        """
        if not isinstance(ip_name, str):
            raise TypeError("IP name has to be a string.")
        
        #: tcl_name will be absolute path
        tcl_name = os.path.splitext(self.bitfile_name)[0]+'.tcl'
        result = None
        with open(tcl_name, 'r') as f:
            for line in f:
                m = re.search('create_bd_addr_seg -range '+\
                        '(0[xX][0-9a-fA-F]+)(.+?)'+ip_name,line,re.IGNORECASE)
                if m:
                    result = m.group(1)
        
        if result is None:
            raise ValueError('No such addressable IP in bitstream {}.'\
                            .format(self.bitfile_name))
        return result
    
    def get_ip_addr_prog(self, ip_id):
        """This method returns the address for programming an IP.
        
        Only the programmable IPs in PL will be checked.
        
        Note
        ----
        Each entry in the dictionary stores [address, program, psgpio]:
        address (str), the base address of the IP.
        program (str), the program (e.g. ".bin") loaded on the IP.
        psgpio (int), the GPIO pin used for control.
        
        Parameters
        ----------
        ip_id : int
            The ID of the programmable IP.

        Returns
        -------
        str
            The address for programming, in hex format.
        
        """
        return PL.prog_ips[ip_id][0]
        
    def get_ip_program(self, ip_id):
        """This method returns the program loaded in a programmable IP.
        
        Only the programmable IPs in PL will be checked.
        
        Note
        ----
        Each entry in the dictionary stores [address, program, psgpio]:
        address (str), the base address of the IP.
        program (str), the program (e.g. ".bin") loaded on the IP.
        psgpio (int), the GPIO pin used for control.
        
        Parameters
        ----------
        ip_id : int
            The ID of the programmable IP.

        Returns
        -------
        str
            The program loaded in a programmable IP.
        
        """
        return PL.prog_ips[ip_id][1]
    
    def get_ip_psgpio(self, ip_id):
        """This method returns the PS GPIO for a programmable IP.
        
        Only the programmable IPs in PL will be checked.
        
        Note
        ----
        Each entry in the dictionary stores [address, program, psgpio]:
        address (str), the base address of the IP.
        program (str), the program (e.g. ".bin") loaded on the IP.
        psgpio (int), the GPIO pin used for control.
        
        Parameters
        ----------
        ip_id : int
            The ID of the programmable IP.

        Returns
        -------
        int
            The GPIO pin used for control from PS.
        
        """
        return PL.prog_ips[ip_id][2]
    
    def load_ip_program(self, ip_id, program):
        """This method loads the program for the programmable IP.
        
        Only the programmable IPs will be affected.
        
        Note
        ----
        Make sure the current overlay on PL is the right one.
        
        Parameters
        ----------
        ip_id : int
            The ID of the programmable IP, starting from 0.
        program : str
            The absolute path of the program to be loaded.
        
        Returns
        -------
        None
        
        """
        if not self.is_loaded():
            raise LookupError("The current overlay has not been loaded.")
        else:
            with open(program, 'rb') as bin:
                size = (math.ceil(os.fstat(bin.fileno()).st_size/ \
                        mmap.PAGESIZE))*mmap.PAGESIZE
                self.mmio = MMIO(int(self.prog_ips[ip_id][0], 16), size)
                buf = bin.read(size)
                self.mmio.write(0, buf)
                
            self.prog_ips[ip_id][1] = program
            PL.prog_ips[ip_id][1] = program
    
    def flush_ip_dictionary(self):
        """This function flushes all the alive programmable IPs.
        
        Only the programmable IPs will be flushed.
        
        Note
        ----
        This function should be used with caution since it only clears the 
        dictionary. It also clears the dictionary in PL.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        for ip_id in self.prog_ips.keys():
            self.prog_ips[ip_id][1] = None
            PL.prog_ips[ip_id][1] = None
            