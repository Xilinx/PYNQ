# Last modified: CMC 25 Nov 2015

__author__      = "Cathal McCabe"
__copyright__   = "Copyright 2015, Xilinx"
__version__     = "0.1"
__maintainer__  = "Cathal McCabe"
__email__       = "cathal.mccabe@xilinx.com"


from . import _iop
from pyxi import MMIO
import time

PROGRAM = "./tmp2.bin"

class TMP2(object):
    """Control an TMP2 PMOD.

        Arguments
        ----------
        pmod_id (int)   : Id of the PMOD to which the I/O Processor 
                        will be attached to

        Attributes
        ----------
        iop (pyb.iop)   : I/O Processor instance used by ADC
        iop_id (int)    : From argument *pmod_id*
        mmio (MMIO)     : Memory-mapped I/O instance needed to read and write 
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

        self.threshold = 20
        self.delay = 0


    def read(self):
        """ Read current sensor value. """
        self.mmio.write(self.cmdAddr, 3)      
        while (self.mmio.read(self.cmdAddr) == 3):
            pass # Wait for acknowledge   
        self.value = self.mmio.read(self.mbAddr)
        return self.reg2float(self.value)

    def set_delay(self,delay):
        if (delay <0):
            raise ValueError("Delay value must be great than 0")
        self.delay = delay
        self.mmio.write(self.mbAddr+(1*4), self.delay)

    def set_threshold(self,val):
        if (val <0):
            raise ValueError("Threshold value must be great than 0")
        self.threshold = val

    def start_log(self, delay=0):
        if (delay <0):
            raise ValueError("Delay value must be great than 0")
        self.delay = delay
        self.mmio.write(self.mbAddr+(1*4), self.delay)
        self.mmio.write(self.cmdAddr, 7)     

    def stop_log(self):
        self.mmio.write(self.cmdAddr, 1)    

    def print_log(self):
        """  Read data from Mailbox. """
        self.stop_log() # first stop logging
        self.mmio.write(self.cmdAddr, 1)
        end_ptr = self.mmio.read(self.mbAddr+(2*4))

        if(end_ptr>=1000): # end_ptr has looped; => mailbox is full
            current_ptr = end_ptr-999 # +1 more than end_ptr
            end_ptr = end_ptr-1000
            count = 1000 # Mailbox is full, print 1000 values
        else: # mailbox is not full, print to the end_ptr
            current_ptr = 0 
            count = end_ptr

        print("T\tData")
        for x in range(0, count):
            print(str(x) + "\t" + \
                  str(self.reg2float(self.mmio.read(self.mbAddr+(3+x)*4))))
            if(current_ptr<999):
                current_ptr+=1
            else:
                current_ptr=0
      
    def reg2float(self, reg):
        """ 31	1 bit   	Sign (S)
            23-30	8 bits  	Exponent (E)
            0-22	23 bits 	Mantissa (M)
        """
        if reg == 0:
            return 0.0
        sign = (reg & 0x80000000) >> 31 & 0x01
        exp = ((reg & 0x7f800000) >> 23)-127
        if(exp ==0):
            man = (reg & 0x007fffff)/pow(2,23)
        else:
            man = 1+(reg & 0x007fffff)/pow(2,23)
      
        result = pow(2,exp)*(man)*((sign*-2) +1)

        return result
   