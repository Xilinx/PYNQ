
__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "xpp_support@xilinx.com"


from pyxi import MMIO
from pyxi.board import _constants


class Switch(object):
    """Control a single onboard switch.

    Parameters
    ----------
    index : int
            Index of the switch

    Attributes
    ----------
    index : int
            From parameter `index`
    """

    # Memory-mapped I/O instance needed to read and write instructions
    # and data.
    _mmio = None

    def __init__(self, index):
        if Switch._mmio is None:
            Switch._mmio = MMIO(_constants.SWS_ADDR)
        self.index = index

    def read(self):
        """Read the current value of the switch.

        Returns
        -------
        int
            Either 0 if the switch is off or 1 if the switch is on
        """
        curr_val = Switch._mmio.read()
        return (curr_val & (1 << self.index)) >> self.index
