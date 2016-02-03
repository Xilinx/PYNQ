__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "yunq@xilinx.com"

import os
import sys
from time import gmtime, strftime

class PL:
    """This class exposes the programmable logic for users."""
    
    global bitstream, timestamp
    bitstream = '/home/xpp/src/pyxi/bitstream/pmod.bit'
    timestamp = ''
    
    def __init__(self):
        try:
            euid = os.geteuid()
        except EnvironmentError:
            print('root permissions required')
            exit()
          
class bitstream(PL):
    """This class extends the PL (singleton) class."""
    
    global bs_path, bs_default
    bs_path = '/home/xpp/src/pyxi/bitstream/'
    bs_default = 'pmod.bit'
    
    def __init__(self, bs_name = bs_default):
        """ Users can either specify only the bitstream name (e.g. 'pmod.bit'),
        or an absolute path to the bitstream file 
        (e.g. '/home/xpp/src/pyxi/bitstream/pmod.bit').
        """
        try:
            euid = os.geteuid()
        except EnvironmentError:
            print('root permissions required')
            exit()
        
        if os.path.isfile(bs_path + bs_name):
            self.bitstream = bs_path + bs_name
        elif os.path.isfile(bs_name):
            self.bitstream = bs_name
        else:
            raise IOError("bitstream file doesn't exist")
            
        self.timestamp = ''

    def download(self):
        # compose bitfile name, open bitfile
        try:
            f = open(self.bitstream, 'rb')
        except IOError:
            print('cannot open', self.bitstream)
            
        # read bitfile into buffer
        try:
            buf = f.read()
        except IOError:
            print('cannot read', self.bitstream)
        finally:
            f.close()
        
        # Set is_partial_bitfile device attribute to 0        
        try:
            fd = open("/sys/devices/soc0/amba/f8007000.devcfg"
                      "/is_partial_bitstream", 'w')
        except IOError:
            print('cannot open is_partial_bitstream')
        else:
            fd.write('0')
        finally:
            fd.close()
        
        # Write partial bitfile to xdevcfg device
        try:
            f = open("/dev/xdevcfg", 'wb')
        except IOError:
            print('cannot open /dev/xdevcfg')
        else:
            f.write(buf)
        finally:
            f.close()
        
        self.timestamp = strftime("%a, %d %b %Y %H:%M:%S +0000", gmtime())
        PL.bitstream = self.bitstream             
        PL.timestamp = self.timestamp
            
