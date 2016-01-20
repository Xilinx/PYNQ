"""Test module for devmode.py"""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.tests import unittest

from pyxi.pmods.devmode import DevMode


class TestDevMode(unittest.TestCase):
    """TestCase for the DevMode class."""
    #TODO: Fill me
    pass


def test_devmode():
    unittest.main(__name__) 
    
    # cleanup active_iops
    from pyxi.pmods._iop import _flush_iops
    _flush_iops()

if __name__ == "__main__":
    test_devmode()
