"""This module exposes API to control an OLED PMOD."""


__author__      = "Graham Schelle, Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__version__     = "0.1"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from . import _iop
from pyxi import MMIO
import time

PROGRAM = "./oled.bin"

class OLED(object):
    """Control an OLED PMOD.

    Arguments
    ----------
    pmod_id (int)   : Id of the PMOD to which the ADC's I/O Processor 
                      will be attached to
    text (string)   : Default:None. If set, the specified text will be 
                      written on the OLED during initialization

    Attributes
    ----------
    iop (pyb.iop)   : I/O Processor instance used by ADC
    iop_id (int)    : From argument *pmod_id*
    mmio (pyb.mmio) : Memory-mapped I/O instance needed to read and write 
                      instructions and data.
    """

    def __init__(self, pmod_id, text=None):         
        """Return a new instance of an OLED object. It might raise an exception 
        as the *force* flag is not set when calling request_iop(). 
        Refer to _iop.request_iop() for additional details.
        """
        if (pmod_id not in _iop.IOP_CONSTANTS):
            raise ValueError("Valid PMOD IDs are: 1, 2, 3, 4")
        self.iop = _iop.request_iop(pmod_id, PROGRAM)
        self.iop_id = pmod_id
        self.mmio = MMIO(_iop.IOP_CONSTANTS[pmod_id]['address'], 
                         _iop.IOP_MMIO_REGSIZE)    

        self.iop.start()
   
        if text:
            self.write(text)
                   
    def write(self, text):
        """Write a new text string on the OLED. 
        Clear the screen first to correctly show the new text.

        Arguments
        ----------
        text (string): The text string that will be written on the OLED.
        """     
        self.clear_screen()
        time.sleep(0.1)
        self._write_string(text)
                
    def _write_string(self, text):
        """Write a new text string on the OLED.

        Note
        ----------
        This should not be used directly to write a new string on the OLED. 
        Use write() instead.

        Arguments
        ----------
        text (string): The text string that will be written on the OLED.
        """    
        # First write length, x-pos, y-pos
        self.mmio.write(_iop.MAILBOX_OFFSET, len(text))
        self.mmio.write(_iop.MAILBOX_OFFSET + 4, 0)
        self.mmio.write(_iop.MAILBOX_OFFSET + 8, 0)
        
        # Then write rest of string
        for i in range(len(text)):
            self.mmio.write(_iop.MAILBOX_OFFSET + 0xc + i*4, ord(text[i]))
                       
        # Finally write the print string command bit[3]: string, bit[0] valid
        self.mmio.write(_iop.MAILBOX_OFFSET + 
                        _iop.MAILBOX_PY2IOP_CMDCMD_OFFSET, 
                        (0x10000 | 0x1 | 0x8))
        
    def clear_screen(self):
        """Clear the OLED screen."""             
        self._write_string(" " * 16 * 4)
    