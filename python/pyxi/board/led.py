
__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.mmio import MMIO
from pyxi.board import _constants


class LED(object):
    """Control a single onboard LED.

    Arguments
    ----------
    index (int) : Index of the LED

    Attributes
    ----------
    index (int) : From argument *index*
    """

    # Memory-mapped I/O instance needed to read and write instructions 
    # and data.
    _mmio = None


    # Encode all LEDs value as a single number to allow the update 
    # of a single LED while maintaining other LEDs.
    _leds_value = 0


    def __init__(self, index, addr = None):
        self.index = index
        if LED._mmio is None: 
            if addr is None:
                addr = _constants.LEDS_ADDR
            LED._mmio = MMIO(addr, int(_constants.LEDS_OFFSET/4) + 2)

        LED._mmio.write(0x4 + _constants.LEDS_OFFSET, 0x0) 
                  
    def toggle(self):  
        """Flip the bit of the single LED."""
        new_val  = (LED._leds_value) ^ (0x1 << self.index)        
        self._set_leds_value(new_val)
        
    def on(self):  
        new_val  = (LED._leds_value) | (0x1 << self.index)            
        self._set_leds_value(new_val)
     
    def off(self):    
        new_val  = (LED._leds_value) & (0xff ^ (0x1 << self.index))    
        self._set_leds_value(new_val)

    def write(self, value):       
        """Set the LED state according to the input value

        Arguments
        ----------
        value (Boolean) : If true, the LED will turned on. Will be turned off 
                          otherwise. Note that this method does not take into 
                          account the current LED state.
        """
        if (value not in (0 ,1)):
            raise ValueError("Requested value should be 0 or 1")
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
        return (LED._leds_value >> self.index) & 0x1    
        
    def _set_leds_value(self, value):
        """Set the state of all LEDs

        Note
        ----------
        Should not be used directly. User should rely on toggle(), on(), 
        off(), write(), and read() instead

        Arguments
        ----------
        value (int) : The value of all the LEDs encoded in one single value
        """
        LED._leds_value = value
        LED._mmio.write(_constants.LEDS_OFFSET, value)
