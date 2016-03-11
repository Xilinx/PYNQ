
__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "xpp_support@xilinx.com"


from pyxi import MMIO
from pyxi.board import _constants


class Button(object):
    """Control a single onboard push-button.

    Parameters
    ----------
    index : int
            Index of the button

    Attributes
    ----------
    index : int
            From parameter `index`
    """

    # Memory-mapped I/O instance needed to read and write instructions
    # and data.
    _mmio = None

    def __init__(self, index):
        if Button._mmio is None:
            Button._mmio = MMIO(_constants.BTNS_ADDR)
        self.index = index

    def read(self):
        """Read the current value of the button.

        Returns
        -------
        int
            Either 1 if the button is pressed or 0 otherwise
        """
        curr_val = Button._mmio.read()
        return (curr_val & (1 << self.index)) >> self.index
