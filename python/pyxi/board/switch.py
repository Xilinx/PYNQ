
__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.mmio import mmio
from pyxi.board import _constants


class Switch(object):
    """Control a single onboard switch.

    Arguments
    ----------
    index (int) : Index of the switch

    Attributes
    ----------
    index (int) : From argument *index*
    """

    # Memory-mapped I/O instance needed to read and write instructions 
    # and data.
    _mmio = None


    def __init__(self, index, addr = None):
        if Switch._mmio is None: 
            if addr is None:
                #raise AssertionError('Must specify switches address when ' + 
                #                     'instantiating the first switch.')
                addr = _constants.SWS_ADDR                
            Switch._mmio = mmio(addr)
        self.index = index

    def read(self):
        """Read the current value of the Switch."""
        curr_val = Switch._mmio.read()       
        return (curr_val & (1 << self.index)) >> self.index
