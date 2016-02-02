"""This module exposes API to control a LED8 PMOD."""


__author__      = "Graham Schelle, Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__version__     = "0.1"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from . import _iop
from .devmode import DevMode

class LED8(object):
    """Control a single LED on the LED8 PMOD.

    Arguments
    ----------
    pmod_id (int)          : Id of the PMOD to which the LED's I/O Processor 
                             will be attached to
    index (int)            : Index of the LED to Control

    Attributes
    ----------
    iop (dev_mode.DevMode) : I/O Processor instance used by LED
    iop_id (int)           : From argument *pmod_id*
    index (int)            : From argument *index*.
    """

    def __init__(self, pmod_id, index):
        """Return a new instance of a LED object. It might raise an exception 
        as the *force* flag is not set when calling request_iop() in 
        DevMode initialization. 
        Refer to _iop.request_iop() for additional details.
        """
        if not pmod_id in _iop.IOP_CONSTANTS:
            raise ValueError("Valid PMOD IDs are: 1, 2, 3, 4")
        if not index in _iop.IOP_SWCFG_XGPIOALL:
            raise ValueError("Valid pin indexes are 0 - 7")
        self.iop = DevMode(pmod_id, _iop.IOP_SWCFG_XGPIOALL) 
        self.iop_id = pmod_id
        self.index = index

        if self.iop.status()[0] != 'RUNNING':
            self.iop.start()
            self.iop.write_cmd(_iop.IOPMM_XGPIO_BASEADDR + 
                               _iop.IOPMM_XGPIO_TRI_OFFSET, 
                               _iop.IOCFG_XGPIO_ALLOUTPUT)    

        # Set switch to XGPIOALL (corner case : mailbox.bin was used previously 
        #                        with non-LED8 PMOD)
        self.iop.load_switch_config()     
                  
    def toggle(self):  
        """Flip the bit of the single LED."""
        curr_val = self.iop.read_cmd(_iop.IOPMM_XGPIO_BASEADDR + 
                                     _iop.IOPMM_XGPIO_DATA_OFFSET)
        new_val  = (curr_val) ^ (0x1 << self.index)        
        self._set_leds_values(new_val)
        
    def on(self):  
        """Turn on single LED."""
        curr_val = self.iop.read_cmd(_iop.IOPMM_XGPIO_BASEADDR + 
                                     _iop.IOPMM_XGPIO_DATA_OFFSET)
        new_val  = (curr_val) | (0x1 << self.index)            
        self._set_leds_values(new_val)
     
    def off(self):    
        """Turn on single LED."""
        curr_val = self.iop.read_cmd(_iop.IOPMM_XGPIO_BASEADDR + 
                                     _iop.IOPMM_XGPIO_DATA_OFFSET)
        new_val  = (curr_val) & (0xff ^ (0x1 << self.index))    
        self._set_leds_values(new_val)

    def write(self, value):
        """Set the LED state according to the input value

        Arguments
        ----------
        value (Boolean) : If true, the LED will turned on. Will be turned off 
        otherwise. Note that this method does not take into account the current 
        LED state.
        """
        if not value in (0,1):
            raise ValueError("LED8 can only write 0 or 1")
        if value:
            self.on()
        else:
            self.off()        

    def read(self):       
        """Retrieve the LED state

        Arguments
        ----------
        None
        """
        curr_val = self.iop.read_cmd(_iop.IOPMM_XGPIO_BASEADDR + 
                                     _iop.IOPMM_XGPIO_DATA_OFFSET)
        return (curr_val >> self.index) & 0x1 
    
    def _set_leds_values(self, value):
        """Set the state of all LEDs

        Note
        ----------
        Should not be used directly. User should rely on toggle(), on(), 
        off(), write(), and read() instead

        Arguments
        ----------
        value (int) : The value of all the LEDs encoded in one single value
        """
        self.iop.write_cmd(_iop.IOPMM_XGPIO_BASEADDR + 
                           _iop.IOPMM_XGPIO_DATA_OFFSET, value)
                         
