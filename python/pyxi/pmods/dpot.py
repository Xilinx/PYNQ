# Last modified: CMC 25 Nov 2015

__author__      = "Cathal McCabe"
__copyright__   = "Copyright 2015, Xilinx"
__version__     = "0.1"
__maintainer__  = "Cathal McCabe"
__email__       = "cathal.mccabe@xilinx.com"

from . import _iop
from pyxi import MMIO
import time


PROGRAM = "./dpot.bin"

class DPOT(object):
    """Control a the DPOT PMOD.

        Arguments
        ----------
        pmod_id (int)   : Id of the PMOD to which the I/O Processor 
                      will be attached to

        Attributes
        ----------
        iop (pyb.iop)   : I/O Processor instance used by ADC
        iop_id (int)    : From argument *pmod_id*
        mmio (pyb.mmio) : Memory-mapped I/O instance needed to read and write 
                        instructions and data.
    """
    def __init__(self,pmod_id):
        if (pmod_id not in _iop.IOP_CONSTANTS):
            raise ValueError("Valid PMOD IDs are: 1, 2, 3, 4")
        self.iop = _iop.request_iop(pmod_id, PROGRAM)
        self.iop_id = pmod_id
        self.mmio = MMIO(_iop.IOP_CONSTANTS[pmod_id]['address'], 
                         _iop.IOP_MMIO_REGSIZE)    
        self.iop.start()

        self.cmdAddr = 0x7ffc
        self.mbAddr  = 0x7000

      
    def write(self,val, step=0, delay=0):
        if not 0<=val<=255:
            raise ValueError("Requested value should be in range 0 - 255")
        if not 0<=step<=255:
            raise ValueError("Requested step size should be in range 0 - 255")
        if delay<0:
            raise ValueError("Requested delay value cannot be less than 0")
        self.mmio.write(self.cmdAddr, 1)  # Cancel outstanding transactions

        self.mmio.write(self.mbAddr, val) # initial value
        self.mmio.write(self.mbAddr+4, step) # initial value
        self.mmio.write(self.mbAddr+8, delay) # initial value
      
        if(step == 0) :
            self.mmio.write(self.cmdAddr, 3)  # Write continuous  
        else :
            self.mmio.write(self.cmdAddr, 5)  # Write continuous  
   
    # Simple Write to Mailbox
    def write_addr(self,val, addr_offset):
        self.mmio.write(self.mbAddr+(addr_offset*4), val)

    def write_cmd(self,val):
        self.mmio.write(self.cmdAddr, val)        

    # Read data from Mailbox
    def read(self, addr_offset):
        return self.mmio.read(self.mbAddr+(addr_offset*4))    

    # For DEBUG: Read Hex value from anywhere in MicroBlaze address space
    def read_hex(self, addr_offset):
        return hex(self.mmio.read((addr_offset*4))) 

   

    

