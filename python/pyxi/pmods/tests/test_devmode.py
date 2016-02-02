"""Test module for devmode.py"""


__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__maintainer__  = "Yun Rock Qu"
__email__       = "yunq@xilinx.com"


from pyxi.tests import unittest
from pyxi.pmods.devmode import DevMode
from pyxi.pmods import _iop

class TestDevMode(unittest.TestCase):
    """TestCase for the DevMode class."""
    def test_0_pmod(self):
        """Tests whether DevMode works for PMOD 1."""
        self.assertIsNotNone(DevMode(1, _iop.IOP_SWCFG_XGPIOALL))
        self.assertIsNotNone(DevMode(1, _iop.IOP_SWCFG_IIC0_TOPROW))
        self.assertIsNotNone(DevMode(1, _iop.IOP_SWCFG_IIC0_BOTTOMROW))

    def test_1_pmod(self):
        """Tests whether DevMode works for PMOD 2."""
        self.assertIsNotNone(DevMode(2, _iop.IOP_SWCFG_XGPIOALL))
        self.assertIsNotNone(DevMode(2, _iop.IOP_SWCFG_IIC0_TOPROW))
        self.assertIsNotNone(DevMode(2, _iop.IOP_SWCFG_IIC0_BOTTOMROW))

    def test_2_pmod(self):
        """Tests whether DevMode works for PMOD 3."""
        self.assertIsNotNone(DevMode(3, _iop.IOP_SWCFG_XGPIOALL))
        self.assertIsNotNone(DevMode(3, _iop.IOP_SWCFG_IIC0_TOPROW))
        self.assertIsNotNone(DevMode(3, _iop.IOP_SWCFG_IIC0_BOTTOMROW))

    def test_3_pmod(self):
        """Tests whether DevMode works for PMOD 4."""
        self.assertIsNotNone(DevMode(4, _iop.IOP_SWCFG_XGPIOALL))
        self.assertIsNotNone(DevMode(4, _iop.IOP_SWCFG_IIC0_TOPROW))
        self.assertIsNotNone(DevMode(4, _iop.IOP_SWCFG_IIC0_BOTTOMROW))


def test_devmode():
    unittest.main(__name__) 
    
    # cleanup active_iops
    from pyxi.pmods._iop import _flush_iops
    _flush_iops()

if __name__ == "__main__":
    test_devmode()
