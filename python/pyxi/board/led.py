
__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "xpp_support@xilinx.com"


from pyxi import MMIO
from pyxi.board import _constants


class LED(object):
    """Control a single onboard LED.

    Parameters
    ----------
    index : int
            Index of the LED

    Attributes
    ----------
    index : int
            From parameter `index`
    """

    # Memory-mapped I/O instance needed to read and write instructions
    # and data.
    _mmio = None

    # Encode all LEDs value as a single number to allow the update
    # of a single LED while maintaining other LEDs.
    _leds_value = 0

    def __init__(self, index):
        self.index = index
        if LED._mmio is None:
            LED._mmio = MMIO(_constants.LEDS_ADDR, 2**4)
        LED._mmio.write(_constants.LEDS_OFFSET + 0x4, 0x0)

    def toggle(self):
        """Flip the bit of the single LED."""
        new_val = (LED._leds_value) ^ (0x1 << self.index)
        self._set_leds_value(new_val)

    def on(self):
        new_val = (LED._leds_value) | (0x1 << self.index)
        self._set_leds_value(new_val)

    def off(self):
        new_val = (LED._leds_value) & (0xff ^ (0x1 << self.index))
        self._set_leds_value(new_val)

    def write(self, value):
        """Set the LED state according to the input value.

        Parameters
        ----------
        value : {0, 1} 
                This parameter can be either 0 or 1. If 1, the LED will 
                be turned on, and will be turned off otherwise. Note that 
                - as you may guess - this method does not take into account 
                the current LED state.

        Raises
        ------
        ValueError
            If the value parameter is not 0 or 1
        """
        if (value not in (0, 1)):
            raise ValueError("Value should be 0 or 1")
        if value:
            self.on()
        else:
            self.off()

    def read(self):
        """Retrieve the LED state.

        Returns
        -------
        int
            Either 0 if the LED is off or 1 if the LED is on
        """
        return (LED._leds_value >> self.index) & 0x1

    def _set_leds_value(self, value):
        """Set the state of all LEDs

        Parameters
        ----------
        value : int 
                The value of all the LEDs encoded in a single variable

        Notes
        -----
        This function should not be used directly. User should rely 
        on `toggle()`, `on()`, `off()`, `write()`, and `read()` instead
        """
        LED._leds_value = value
        LED._mmio.write(_constants.LEDS_OFFSET, value)
