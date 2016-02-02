"""This module exposes API to control a 
Digital to Analog Converter (DAC) PMOD.
"""


__author__      = "Graham Schelle, Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__version__     = "0.1"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from . import _iop
from pyxi import mmio
import time


PROGRAM = "./dac.bin"


class DAC(object):
    """Control a DAC PMOD.

    Arguments
    ----------
    pmod_id (int)   : Id of the PMOD to which the ADC's I/O Processor 
                      will be attached to
    value (float)   : Default:None. If set, a value will be written on the 
                      DAC PMOD during initialization

    Attributes
    ----------
    iop (pyb.iop)   : I/O Processor instance used by ADC
    iop_id (int)    : From argument *pmod_id*
    mmio (pyb.mmio) : Memory-mapped I/O instance needed to read and write 
                      instructions and data.
    """

    def __init__(self, pmod_id, value=None):
        """Return a new instance of a DAC object. It might raise an exception 
        as the *force* flag is not set when calling request_iop(). 
        Refer to _iop.request_iop() for additional details.
        """
        if (pmod_id not in _iop.IOP_CONSTANTS):
            raise ValueError("Valid PMOD IDs are: 1, 2, 3, 4")
        self.iop = _iop.request_iop(pmod_id, PROGRAM)
        self.iop_id = pmod_id
        self.mmio = mmio.MMIO(_iop.IOP_CONSTANTS[pmod_id]['address'], 
                         _iop.IOP_MMIO_REGSIZE>>2)    

        self.iop.start()

        if value:
            self.write(value)

    def write(self, value):
        """Write a floating point number on the DAC PMOD.

        Note
        ----------
        User is not allowed to use a number greater than 1.2 as input value

        Arguments
        ----------
        value (float): The value which will be written to the DAC PMOD

        Raises
        ----------
        ValueError   : If the input value exceeds the maximum allowed 
                       voltage of 1.2V.
        """     
        # Calculate the Voltage Value and Write to DAC
        if (value > 1.2 or value < 0):
            raise ValueError("Requested value not in range 0 - 1.2 V")

        intVal = int(value / (0.000610351))
        self.mmio.write(_iop.MAILBOX_OFFSET + 
                        _iop.MAILBOX_PY2IOP_CMDCMD_OFFSET, 
                        (intVal << 20) | (0x3))
        
        # Wait for I/O Processor to complete
        while (self.mmio.read(_iop.MAILBOX_OFFSET + 
                              _iop.MAILBOX_PY2IOP_CMDCMD_OFFSET) & 0x1) == 0x1:
            time.sleep(0.001)
    