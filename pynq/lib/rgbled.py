#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from pynq import MMIO
from pynq import PL



RGBLEDS_XGPIO_OFFSET = 0
RGB_CLEAR = 0
RGB_BLUE = 1
RGB_GREEN = 2
RGB_CYAN = 3
RGB_RED = 4
RGB_MAGENTA = 5
RGB_YELLOW = 6
RGB_WHITE = 7


class RGBLED(object):
    """This class controls the onboard RGB LEDs.

    Attributes
    ----------
    index : int
        The index of the RGB LED. Can be an arbitrary value.
    _mmio : MMIO
        Shared memory map for the RGBLED GPIO controller.
    _rgbleds_val : int
        Global value of the RGBLED GPIO pins.
    _rgbleds_start_index : int
        Global value representing the lowest index for RGB LEDs
    """

    _mmio = None
    _rgbleds_val = 0
    _rgbleds_start_index = float("inf")

    def __init__(self, index, ip_name="rgbleds_gpio", start_index=float("inf")):
        """Create a new RGB LED object.

        Parameters
        ----------
        index : int
            Index of the RGBLED, Can be an arbitrary value.
            The smallest index given will set the global value
            `_rgbleds_start_index`. This behavior can be overridden by defining
            `start_index`.
        ip_name : str
            Name of the IP in  the `ip_dict`. Defaults to "rgbleds_gpio".
        start_index : int
            If defined, will be used to update the global value
            `_rgbleds_start_index`.

        """

        self.index = index
        if RGBLED._mmio is None:
            base_addr = PL.ip_dict[ip_name]["phys_addr"]
            RGBLED._mmio = MMIO(base_addr, 16)
        if index < start_index and start_index != float("inf"):
            raise ValueError("Inconsistent use of initialization indexes.")
        if start_index < RGBLED._rgbleds_start_index:
            RGBLED._rgbleds_start_index = start_index
        if index < RGBLED._rgbleds_start_index:
            RGBLED._rgbleds_start_index = index

    def on(self, color):
        """Turn on a single RGB LED with a color value (see color constants).

        Parameters
        ----------
        color : int
           Color of RGB specified by a 3-bit RGB integer value.

        Returns
        -------
        None

        """
        if color not in range(8):
            raise ValueError("color should be an integer value from 0 to 7.")

        rgb_mask = 0x7 << ((self.index - RGBLED._rgbleds_start_index) * 3)
        new_val = (RGBLED._rgbleds_val & ~rgb_mask) | (
            color << ((self.index - RGBLED._rgbleds_start_index) * 3)
        )
        self._set_rgbleds_value(new_val)

    def off(self):
        """Turn off a single RGBLED.

        Returns
        -------
        None

        """
        rgb_mask = 0x7 << ((self.index - RGBLED._rgbleds_start_index) * 3)
        new_val = RGBLED._rgbleds_val & ~rgb_mask
        self._set_rgbleds_value(new_val)

    def write(self, color):
        """Set the RGBLED state according to the input value.

        Parameters
        ----------
        color : int
            Color of RGB specified by a 3-bit RGB integer value.

        Returns
        -------
        None

        """
        self.on(color)

    def read(self):
        """Retrieve the RGBLED state.

        Returns
        -------
        int
            The color value stored in the RGBLED.

        """
        return (
            RGBLED._rgbleds_val >> ((self.index - RGBLED._rgbleds_start_index) * 3)
        ) & 0x7

    @staticmethod
    def _set_rgbleds_value(value):
        """Set the state of all RGBLEDs.

        Note
        ----
        This function should not be used directly. User should call
        `on()`, `off()`, instead.

        Parameters
        ----------
        value : int
            The value of all the RGBLEDs encoded in a single variable.

        """
        RGBLED._rgbleds_val = value
        RGBLED._mmio.write(RGBLEDS_XGPIO_OFFSET, value)


