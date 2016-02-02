__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "yunq@xilinx.com"

import os
import sys
import struct
from time import gmtime, strftime

class OVERLAY:
    """This class exposes the programmable logic for users."""
    
    global bs_path, bs_default
    bs_path = '/home/xpp/src/pyxi/bitstream/'
    bs_default = 'pmod.bit'
    
    pl_bitstream = bs_default
    pl_state = 'PRELOADED'
    pl_stamp = ''
    num_instances = 0
    
    def __init__(self, bs_name = bs_default):
        self.state = 'UNLOADED'
        try:
            self.bitstream = (bs_path + bs_name)
        except AttributeError:
            print('cannot assign bitstream', bs_name)
        assert os.path.exists(self.bitstream), "bitstream doesn't exist"
        
        try:
            euid = os.geteuid()
        except EnvironmentError:
            print('root permissions required.')
            exit()
            
        self.state = 'LOADED'
        self.stamp = strftime("%a, %d %b %Y %H:%M:%S +0000", gmtime())
          
class bitstream(OVERLAY):
    """This class exposes the programmable logic for users."""
    global bs_path, bs_default
    bs_path = '/media/usb/bitstream/'
    bs_default = 'pmod.bit'
    
    def __init__(self, bs_name = bs_default):
        self.state = 'UNLOADED'
        try:
            self.bitstream = (bs_path + bs_name)
        except AttributeError:
            print('cannot assign bitstream', bs_name)
        assert os.path.exists(self.bitstream), "bitstream doesn't exist"
        
        try:
            euid = os.geteuid()
        except EnvironmentError:
            print('root permissions required.')
            exit()
        
        self.state = 'LOADED'
        self.stamp = strftime("%a, %d %b %Y %H:%M:%S +0000", gmtime())
        OVERLAY.num_instances += 1  

    def status(self):
        if (OVERLAY.num_instances == 1 and 
            self.bitstream == (bs_path + bs_default)):
            self.state = 'LOADED' 
        elif (self.stamp != OVERLAY.pl_stamp):
            self.state = 'UNLOADED'
        
        str = '%s %s at %s' % (self.bitstream,self.state,self.stamp)
        return str
    
    def download(self, bs_name = bs_default):
        self.state = 'FAILED'
        try:
            self.bitstream = (bs_path + bs_name)
        except AttributeError:
            print('cannot assign bitstream', bs_name)
        assert os.path.exists(self.bitstream), "bitstream doesn't exist"
        
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
        
        self.state = 'LOADED'
        self.stamp = strftime("%a, %d %b %Y %H:%M:%S +0000", gmtime())
        OVERLAY.pl_bitstream = self.bitstream      
        OVERLAY.pl_state = self.state       
        OVERLAY.pl_stamp = self.stamp
            
