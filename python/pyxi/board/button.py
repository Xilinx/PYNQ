
__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.mmio import MMIO
from pyxi.board import _constants


class Button(object):
    """Control a single onboard push-button.

    Arguments
    ----------
    index (int) : Index of the button

    Attributes
    ----------
    index (int) : From argument *index*
    """

    # Memory-mapped I/O instance needed to read and write instructions 
    # and data.
    _mmio = None

    def __init__(self, index, addr = None):
        if Button._mmio is None: 
            if addr is None:
                addr = _constants.BTNS_ADDR
            Button._mmio = MMIO(addr)
        self.index = index

    def read(self):
        """Read the current value of the Button."""
        curr_val = Button._mmio.read()
        return (curr_val & (1 << self.index)) >> self.index
