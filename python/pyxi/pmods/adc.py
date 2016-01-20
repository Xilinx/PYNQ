"""This module exposes API to control an 
Analog to Digital Converter (ADC) PMOD.
"""


__author__      = "Graham Schelle, Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__version__     = "0.1"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from . import _iop
from pyb import mmio, udelay


PROGRAM = "./pyxi/pmods/adc.bin"


class ADC(object):
    """Control an ADC PMOD.

    Arguments
    ----------
    pmod_id (int)   : Id of the PMOD to which the ADC's I/O Processor 
                      will be attached to

    Attributes
    ----------
    iop (pyb.iop)   : I/O Processor instance used by ADC
    iop_id (int)    : From argument *pmod_id*
    mmio (pyb.mmio) : Memory-mapped I/O instance needed to read and write 
                      instructions and data.
    """

    def __init__(self, pmod_id):
        """Return a new instance of an ADC object. It might raise an exception 
        as the *force* flag is not set when calling request_iop(). 
        Refer to _iop.request_iop() for additional details.
        """
        if (pmod_id not in _iop.iop_constants):
            raise ValueError("PMOD ID not valid. Valid values are: 1, 2, 3, 4")
        self.iop = _iop.request_iop(self, pmod_id, PROGRAM)
        self.iop_id = pmod_id
        self.mmio = mmio(_iop.iop_constants[pmod_id]['address'], 
                         _iop.IOP_MMIO_REGSIZE)    

        self.iop.start()
    
    def value(self):   
        """ Get the raw value from the ADC PMOD."""     
        # Set up  ADC (3 samples of channel 10 )
        self.mmio.write(_iop.MAILBOX_OFFSET + 
                        _iop.MAILBOX_PY2IOP_CMDCMD_OFFSET, 0xa0403)
        
        # Wait for I/O Processor to complete
        while (self.mmio.read(_iop.MAILBOX_OFFSET + 
                              _iop.MAILBOX_PY2IOP_CMDCMD_OFFSET) & 0x1) == 0x1:
            udelay(1000)

        return self.mmio.read(_iop.MAILBOX_OFFSET + 12)
            
    def read(self):
        """ Get the raw value from the ADC PMOD and convert it 
        to a float string.
        """
        val = self.value()        
        chars = ['0','.','0','0','0','0']
        
        chars[0] = chr((val >> 24 ) & 0xff)  
        chars[2] = chr((val >> 16 ) & 0xff)         
        chars[3] = chr((val >> 8 )  & 0xff)       
        chars[4] = chr((val)        & 0xff)
        
        return  ''.join(chars)  
    