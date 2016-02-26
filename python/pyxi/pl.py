__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "yunq@xilinx.com"

import os
import sys
import re
from datetime import datetime
from xml.etree import ElementTree

class PL:
    """ This class exposes the programmable logic for users."""
    
    global bitstream, timestamp
    bitstream = '/home/xpp/src/pyxi/bitstream/pmod.bit'
    timestamp = ''
    
    def __init__(self):
        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('root permissions required.')
          
class BITSTREAM(PL):
    """This class extends the PL (singleton) class."""
    
    global bs_path, bs_default
    bs_path = '/home/xpp/src/pyxi/bitstream/'
    bs_default = 'pmod.bit'
    
    def __init__(self, bs_name = bs_default):
        """ Users can either specify only the bitstream name (e.g. 'pmod.bit'),
        or an absolute path to the bitstream file
        (e.g. '/home/xpp/src/pyxi/bitstream/pmod.bit').
        To avoid any confusion, always use consistent representation.
        """
        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('root permissions required.')
        
        if not isinstance(bs_name, str):
            raise TypeError("bitstream name has to be a string")
        
        if os.path.isfile(bs_path + bs_name):
            self.bitstream = bs_path + bs_name
        elif os.path.isfile(bs_name):
            self.bitstream = bs_name
        else:
            raise IOError('bitstream file {} does not exist'.format(bs_name))
            
        self.timestamp = ''

    def download(self):
        # compose bitfile name, open bitfile
        try:
            f = open(self.bitstream, 'rb')
        except IOError:
            print('cannot open', self.bitstream)
            raise
            
        # read bitfile into buffer
        try:
            buf = f.read()
        except IOError:
            print('cannot read', self.bitstream)
            raise
        finally:
            f.close()
        
        # Set is_partial_bitfile device attribute to 0        
        try:
            fd = open("/sys/devices/soc0/amba/f8007000.devcfg"
                      "/is_partial_bitstream", 'w')
        except IOError:
            print('cannot open is_partial_bitstream')
            raise
        else:
            fd.write('0')
        finally:
            fd.close()
        
        # Write partial bitfile to xdevcfg device
        try:
            f = open("/dev/xdevcfg", 'wb')
        except IOError:
            print('cannot open /dev/xdevcfg')
            raise
        else:
            f.write(buf)
        finally:
            f.close()
        
        t = datetime.now()
        self.timestamp = "{}/{}/{} {}:{}:{} +{}".format(t.year,t.month,t.day,\
                                t.hour,t.minute,t.second,t.microsecond)
        PL.bitstream = self.bitstream             
        PL.timestamp = self.timestamp
        
class OVERLAY(PL):
    """The OVERLAY class can keep track of multiple bitstreams."""
    
    global bs_path
    bs_path = '/home/xpp/src/pyxi/bitstream/'
    
    def __init__(self):
        """ An overlay does not instantiate a bitstream object initially
        Users can assign bitstreams using the bitstream class.
        bit_table is a hash table:
            key: name
            value: bitstream
        The "name" can be a relative path under bs_path folder, or an absolute 
        path. To avoid confusion when looking up the table, it is always a good
        practice to use consistent representation. i.e., for any entry, use 
        either relative or absolute path to store and retrieve, but not both.
        """
        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('root permissions required.')
        
        self.bit_table = {}
    
    def add_bitstream(self, bs_name):
        """ Add a bitstream into the dictionary
        Note:
            The bitstream will not be downloaded until set_bitstream()
            Since the bitstream is not downloaded yet, the timestamp is empty.
        """
        if not isinstance(bs_name, str):
            raise TypeError("bitstream name has to be a string")
        
        self.bit_table[bs_name] = BITSTREAM(bs_name)
                
    def download_bitstream(self, bs_name):
        """ Download a bitstream onto PL
        If the bitstream is not in the dictionary, add it before downloading
        After the bitstream has been downloaded, the timestamp will be updated.
        Note:
            It is not safe to always only use download_bitstream()
            This is because the bitstream in the dictionary can be changed 
            elsewhere by malicious programs
            So the recommendation is to always add bitstream before 
            downloading it onto PL
        """
        if not isinstance(bs_name, str):
            raise TypeError("bitstream name has to be a string")
        
        if not bs_name in self.bit_table.keys():
            self.add_bitstream(bs_name)
        self.bit_table[bs_name].download()
                
    def get_name(self):
        """ Return a list of bitstreams stored in the dictionary. 
        """
        return list(self.bit_table)
        
    def get_timestamp(self, bs_name):
        """ Return the timestamp of a bitstream.
        """
        if not isinstance(bs_name, str):
            raise TypeError("bitstream name has to be a string")
        
        if bs_name in self.bit_table.keys():
            return self.bit_table[bs_name].timestamp
        else:
            raise ValueError('bitstream {} does not exist in this overlay'\
                        .format(bs_name))
        
    def get_status(self, bs_name):
        """ Return the current status of a bitstream.
        i.e., whether it is "LOADED" or not.
        Note:
            The timestamp attribute of PL is only available when at least 1
            bitstream has already been downloaded onto PL.
        """
        if not isinstance(bs_name, str):
            raise TypeError("bitstream name has to be a string")
        
        if not bs_name in self.bit_table.keys():
            raise ValueError('bitstream {} does not exist in this overlay'\
                        .format(bs_name))
        
        if not hasattr(PL, 'timestamp'):
            raise AttributeError('PL timestamp not available yet')
        
        if (self.bit_table[bs_name].timestamp==PL.timestamp):
            return "LOADED" 
        else:
            return 'UNLOADED'
    
    def get_iplist(self, bs_name):
        """ Get the entire list of all the IPs in the bitstream.
        The list may not be human-readable.
        This function requires the '.bxml' file association.
        Users can do the following to get a readable printout:
            >>> from pprint import pprint
            >>> pprint(result, width = 1))
        Note: 
            The IP name in BXML file is slightly different from the ones used
            in the TCL file.
        """
        if not isinstance(bs_name, str):
            raise TypeError("bitstream name has to be a string")
            
        if bs_name not in self.bit_table.keys():
            raise ValueError('bitstream {} does not exist in this overlay'\
                        .format(bs_name))     
        
        bxml_name = os.path.splitext(bs_name)[0]+'.bxml'
        if os.path.isfile(bs_path + bxml_name):
            root = ElementTree.parse(bs_path + bxml_name).getroot()
        elif os.path.isfile(bxml_name):
            root = ElementTree.parse(bxml_name).getroot()
        else:
            raise FileNotFoundError('BXML file {} is missing'\
                            .format(bxml_name))
        
        result = []
        for filename in root.iter('File'):
            if (filename.attrib.get('Type')=='IP'):
                result.append(filename.attrib.get('Name'))
        return result
        
    def get_ip(self, bs_name, ip_name):
        """ Return a list of all the IPs containing ip_name.
        The list may not be human-readable.
        This function requires the '.bxml' file association.
        Users can do the following to get a readable printout:
            >>> from pprint import pprint
            >>> pprint(result, width = 1))
        Note: 
            The IP name in BXML file is slightly different from the ones used
            in the TCL file.
        """
        if not isinstance(bs_name, str):
            raise TypeError("bitstream name has to be a string")
        
        if not isinstance(ip_name, str):
            raise TypeError("IP name has to be a string")
            
        if bs_name not in self.bit_table.keys():
            raise ValueError('bitstream {} does not exist in this overlay'\
                        .format(bs_name))
        
        bxml_name = os.path.splitext(bs_name)[0]+'.bxml'
        if os.path.isfile(bs_path + bxml_name):
            root = ElementTree.parse(bs_path + bxml_name).getroot()
        elif os.path.isfile(bxml_name):
            root = ElementTree.parse(bxml_name).getroot()
        else:
            raise FileNotFoundError('BXML file {} is missing'\
                            .format(bxml_name))
        
        result = []
        for filename in root.iter('File'):
            if (filename.attrib.get('Type')=='IP'):
                if (ip_name in filename.attrib.get('Name')):
                    result.append(filename.attrib.get('Name'))
        return result
        
    def rm_bitstream(self, bs_name):
        """ Remove a bitstream from the overlay.
        This function only removes the bitstream from the dictionary, so it
        should be used carefully.
        """
        if not isinstance(bs_name, str):
            raise TypeError("bitstream name has to be a string")
        
        del(self.bit_table[bs_name])
        
    def get_gpio_base(self):
        """ Return the GPIO base in PS.
        The returned value is bitstream-independent.
        The actual GPIO index between PS and PL can be calculated using:
            GPIO index = GPIO base + EMIO index
        e.g. The GPIO base is 138, and EMIO 54 is specified in Vivado IPI.
        Then the real GPIO index should be (138 + 54) = 192.
        """
        for root, dirs, files in os.walk('/sys/class/gpio'):
            for name in dirs:
                if 'gpiochip' in name:
                    return int(''.join(x for x in name if x.isdigit()))
                    
    def get_mmio_base(self, bs_name, ip_name):
        """ Return the MMIO base in PL.
        The returned value (type: str) is bitstream-dependent.
        This function requires the '.tcl' file association.
        """
        if not isinstance(bs_name, str):
            raise TypeError("bitstream name has to be a string")
        
        if not isinstance(ip_name, str):
            raise TypeError("IP name has to be a string")
            
        if bs_name not in self.bit_table.keys():
            raise ValueError('bitstream {} does not exist in this overlay'\
                        .format(bs_name))
        
        tcl_name = os.path.splitext(bs_name)[0]+'.tcl'
        if os.path.isfile(bs_path + tcl_name):
            f = open(bs_path + tcl_name, 'r')
        elif os.path.isfile(bxml_name):
            f = open(tcl_name, 'r')
        else:
            raise FileNotFoundError('TCL file {} is missing'\
                            .format(tcl_name))
        
        result = ''
        for line in f:
            m = re.search('create_bd_addr_seg(.+?)-offset '+\
                    '(0[xX][0-9a-fA-F]+)(.+?)'+ip_name,line,re.IGNORECASE)
            if m:
                result = m.group(2)
        if result is '':
            raise ValueError('no such addressable IP in bitstream {}'\
                            .format(bs_name))
        return result
        
    def get_mmio_range(self, bs_name, ip_name):
        """ Return the MMIO range in PL.
        The returned value (type: str) is bitstream-dependent.
        This function requires the '.tcl' file association.
        """
        if not isinstance(bs_name, str):
            raise TypeError("bitstream name has to be a string")
        
        if not isinstance(ip_name, str):
            raise TypeError("IP name has to be a string")
            
        if bs_name not in self.bit_table.keys():
            raise ValueError('bitstream {} does not exist in this overlay'\
                        .format(bs_name))
        
        tcl_name = os.path.splitext(bs_name)[0]+'.tcl'
        if os.path.isfile(bs_path + tcl_name):
            f = open(bs_path + tcl_name, 'r')
        elif os.path.isfile(bxml_name):
            f = open(tcl_name, 'r')
        else:
            raise FileNotFoundError('TCL file {} is missing'\
                            .format(tcl_name))
        
        result = ''
        for line in f:
            m = re.search('create_bd_addr_seg -range '+\
                    '(0[xX][0-9a-fA-F]+)(.+?)'+ip_name,line,re.IGNORECASE)
            if m:
                result = m.group(1)
        if result is '':
            raise ValueError('no such addressable IP in bitstream {}'\
                            .format(bs_name))
        return result