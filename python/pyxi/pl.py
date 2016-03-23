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
from datetime import datetime
from . import general_const
    
class PL:
    """This class serves as a singleton for "Overlay" and "Bitstream" classes.
    
    Attributes
    ----------
    bitstream : str
        The name of the bitstream currently loaded on PL.
    timestamp : str
        Timestamp when loading the bitstream. Follow a format of:
        (year, month, day, hour, minute, second, microsecond)
    mb_instances : dict
        The dictionary storing alive Microblaze instances; can be empty.
        
    """
    
    bitstream = general_const.BS_BOOT
    timestamp = ""
    mb_instances = {}
    
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
    
    def __init__(self, bs_name):
        """Return a new Bitstream object. 
        
        Users can either specify an absolute path to the bitstream file 
        (e.g. '/home/xpp/src/pyxi/bitstream/pmod.bit'),
        or only the bitstream name 
        (e.g. 'pmod.bit').
        
        Note
        ----
        To avoid any confusion, always use consistent representation.
        self.bitstream always stores the absolute path of the bitstream.
        
        Parameters
        ----------
        bs_name : str
            The bitstream absolute path or name as a string.
            
        """
        super().__init__()
        
        if not isinstance(bs_name, str):
            raise TypeError("Bitstream name has to be a string.")
        
        if os.path.isfile(bs_name):
            self.bitstream = bs_name
        elif os.path.isfile(general_const.BS_SEARCH_PATH + bs_name):
            self.bitstream = general_const.BS_SEARCH_PATH + bs_name
        else:
            raise IOError('Bitstream file {} does not exist.'.format(bs_name))
            
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
    
    Attributes
    ----------
    bs_name : str
        The absolute path of the bitstream.
    bitstream : Bitstream
        The corresponding bitstream object.
        
    """
    
    def __init__(self, bs_name):
        """Return a new Overlay object.
        
        Note
        ----
        An overlay does not instantiate a bitstream object initially.
        Users can assign bitstreams using the bitstream class.
        
        Parameters
        ----------
        bs_name : str
            The bitstream name or absolute path as a string.
            
        """
        super().__init__()
        
        if not isinstance(bs_name, str):
            raise TypeError("Bitstream name has to be a string.")
        
        if os.path.isfile(bs_name):
            self.bs_name = bs_name
        elif os.path.isfile(general_const.BS_SEARCH_PATH + bs_name):
            self.bs_name = general_const.BS_SEARCH_PATH + bs_name
        else:
            raise IOError('Bitstream file {} does not exist.'.format(bs_name))
            
        self.bitstream = Bitstream(self.bs_name)
        
        #: The number of Microblaze processors supported may vary
        PL.mb_instances = {}
        for i in range(len(self.get_mb_addr())):
            PL.mb_instances[i] = None
    
    def get_bs_name(self):
        """The method to get the bitstream name
        
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
        return self.bs_name
        
    def download(self):
        """The method to download a bitstream onto PL
        
        Note
        ----
        After the bitstream has been downloaded, the "timestamp" in PL will be 
        updated. In addition, the dictionary "mb_instances" in PL will be 
        cleared.
        
        Parameters
        ----------
        None

        Returns
        -------
        None
        
        """
        self.bitstream.download()
        PL.mb_instances = {}
        for i in range(len(self.get_mb_addr())):
            PL.mb_instances[i] = None
        
    def get_timestamp(self):
        """This method returns the timestamp of a bitstream.
        
        Parameters
        ----------
        None

        Returns
        -------
        str
            The timestamp of the bitstream.
            
        """ 
        return self.bitstream.timestamp
        
    def is_loaded(self):
        """This method checks whether a bitstream is loaded.
        
        Parameters
        ----------
        None

        Returns
        -------
        bool
            True if bitstream is loaded.
            
        """
        return self.bitstream.timestamp==PL.timestamp
        
    def get_iplist(self):
        """The method to get the addressable IPs in the bitstream.
        
        Note
        ----
        This method requires the '.tcl' file association.
        The returned list may not be human-readable.
        Users can do the following to get a readable printout:
        >>> from pprint import pprint
        >>> pprint(result, width = 1))
        
        Parameters
        ----------
        None

        Returns
        -------
        list
            The list of all the addressable IPs in the bitstream.
            
        """
        #: tcl_name will be absolute path
        tcl_name = os.path.splitext(self.bs_name)[0]+'.tcl'
        result = []
        with open(tcl_name, 'r') as f:
            for line in f:
                m = re.search('create_bd_addr_seg(.+?) '+\
                        '(\[.+?\]) (\[.+?\]) '+
                        '([A-Za-z0-9_]+)',line,re.IGNORECASE)
                if m:
                    result.append(m.group(4))
        
        if result is []:
            raise ValueError('No addressable IPs in bitstream {}.'\
                            .format(self.bs_name))
        return result
        
    def get_ip(self, ip_name):
        """The method to return a list of IPs containing ip_name.
        
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
        if not isinstance(ip_name, str):
            raise TypeError("IP name has to be a string.")
                        
        #: tcl will be absolute path
        tcl_name = os.path.splitext(self.bs_name)[0]+'.tcl'
        result = []
        with open(tcl_name, 'r') as f:
            for line in f:
                m = re.search('create_bd_addr_seg(.+?) '+\
                        '(\[.+?\]) (\[.+?\]) '+
                        '([A-Za-z0-9_]+)',line,re.IGNORECASE)
                if m:
                    temp = m.group(4)
                    if ip_name in temp.lower():
                        result.append(temp)
        
        if result is []:
            raise ValueError('No such addressable IPs in bitstream {}.'\
                            .format(self.bs_name))
        return result
        
    def reset(self):
        """This method resets the bitstream in the overlay.
        
        Parameters
        ----------
        None

        Returns
        -------
        None
        
        """
        bs_name = self.bs_name
        if os.path.isfile(bs_name):
            self.bs_name = bs_name
        else:
            raise IOError('Bitstream file {} does not exist.'.format(bs_name))
  
        self.bitstream = Bitstream(self.bs_name)
                    
    def get_mmio_base(self, ip_name):
        """This method returns the MMIO base of an IP.
        
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
        tcl_name = os.path.splitext(self.bs_name)[0]+'.tcl'
        result = None
        with open(tcl_name, 'r') as f:
            for line in f:
                m = re.search('create_bd_addr_seg(.+?)-offset '+\
                        '(0[xX][0-9a-fA-F]+)(.+?)'+ip_name,line,re.IGNORECASE)
                if m:
                    result = m.group(2)
        
        if result is None:
            raise ValueError('No such addressable IP in bitstream {}.'\
                            .format(self.bs_name))
        return result
        
    def get_mmio_range(self, ip_name):
        """This method returns the MMIO range of an IP.
        
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
        tcl_name = os.path.splitext(self.bs_name)[0]+'.tcl'
        result = None
        with open(tcl_name, 'r') as f:
            for line in f:
                m = re.search('create_bd_addr_seg -range '+\
                        '(0[xX][0-9a-fA-F]+)(.+?)'+ip_name,line,re.IGNORECASE)
                if m:
                    result = m.group(1)
        
        if result is None:
            raise ValueError('No such addressable IP in bitstream {}.'\
                            .format(self.bs_name))
        return result
        
    def get_mb_addr(self):
        """This method returns the base address of the Microblaze processors.
        
        Note
        ----
        This method requires the '.tcl' file association.
        The address is stored as a string in its hex format.
        The returned dictionary can also be empty if there is no processors
        available. 
        Each key "mb_id" is associated with a value in the 
        dictionary; each value is an "address".
        Hence, the dictionary records the addresses of all the Microblaze 
        processors. This dictionary is different than the Microblaze 
        dictionary stored in the PL class.
        
        The processor ID is of type int. 
        Address is of type str.
        
        Parameters
        ----------
        None

        Returns
        -------
        dict
            A dictionary storing the Microblaze IDs and the addresses.
        
        """
        #: tcl_name will be absolute path
        tcl_name = os.path.splitext(self.bs_name)[0]+'.tcl'
        result = {}
        mb_id = 0
        with open(tcl_name, 'r') as f:
            for line in f:
                m = re.search('create_bd_addr_seg(.+?)-offset '+\
                        '(0[xX][0-9a-fA-F]+)(.+?)'+'axi_bram_ctrl_'+
                        '([0-9]+)(.+?)',line,re.IGNORECASE)
                if m:
                    addr = m.group(2)
                    result[mb_id] = addr
                    mb_id += 1
                    
        return result
        
    def set_mb_program(self, mb_id, program):
        """This method adds the program for the Microblaze processor.
        
        Note
        ----
        The dictionary "mb_instances" is kept as a singleton in PL. This 
        dictionary stores the mapping from the processor IDs to the programs. 
        
        Parameters
        ----------
        mb_id : int
            The ID of the Microblaze processor, starting from 0.
        program : str
            The Microblaze program to be loaded.
        
        Returns
        -------
        None
        
        """
        PL.mb_instances[mb_id] = program
        
    def get_mb_program(self, mb_id):
        """This method gets the program for a Microblaze processor.
        
        Note
        ----
        The dictionary "mb_instances" is kept as a singleton in PL. This 
        dictionary stores the mapping from the processor IDs to the programs.
        
        Parameters
        ----------
        mb_id : int
            The ID of the Microblaze processor, starting from 0.
        
        Returns
        -------
        str
            The Microblaze program loaded on the processor.
        
        """
        return PL.mb_instances[mb_id]
        
    def get_mb_dictionary(self):
        """This method returns the alive Microblaze processors on the PL.
        
        The returned dictionary stores the mapping from the processor IDs to 
        the programs.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        dict
            The dictionary "mb_instances" kept as a singleton in PL.
        
        """
        return PL.mb_instances
    
    def flush_mb_dictionary(self):
        """This function flushes all the alive Microblaze processors.
    
        Note
        ----
        This function should be used with caution since it only clears the 
        dictionary.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        for k in self.get_mb_dictionary().keys():
            self.get_mb_dictionary()[k] = None