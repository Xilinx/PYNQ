"""Test module for devmode.py"""


__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__maintainer__  = "Yun Rock Qu"
__email__       = "yunq@xilinx.com"


import pytest
from pyxi.pmods.devmode import DevMode
from pyxi.pmods import _iop
from pyxi.pmods._iop import _flush_iops

@pytest.mark.run(order=13)
def test_pmod1():
    """Tests whether DevMode works for PMOD 1."""
    assert DevMode(1, _iop.IOP_SWCFG_XGPIOALL) is not None
    assert DevMode(1, _iop.IOP_SWCFG_IIC0_TOPROW) is not None
    assert DevMode(1, _iop.IOP_SWCFG_IIC0_BOTTOMROW) is not None

@pytest.mark.run(order=14)
def test_pmod2():
    """Tests whether DevMode works for PMOD 2."""
    assert DevMode(2, _iop.IOP_SWCFG_XGPIOALL) is not None
    assert DevMode(2, _iop.IOP_SWCFG_IIC0_TOPROW) is not None
    assert DevMode(2, _iop.IOP_SWCFG_IIC0_BOTTOMROW) is not None

@pytest.mark.run(order=15)
def test_pmod3():
    """Tests whether DevMode works for PMOD 3."""
    assert DevMode(3, _iop.IOP_SWCFG_XGPIOALL) is not None
    assert DevMode(3, _iop.IOP_SWCFG_IIC0_TOPROW) is not None
    assert DevMode(3, _iop.IOP_SWCFG_IIC0_BOTTOMROW) is not None

@pytest.mark.run(order=16)
def test_pmod4():
    """Tests whether DevMode works for PMOD 4."""
    assert DevMode(4, _iop.IOP_SWCFG_XGPIOALL) is not None
    assert DevMode(4, _iop.IOP_SWCFG_IIC0_TOPROW) is not None
    assert DevMode(4, _iop.IOP_SWCFG_IIC0_BOTTOMROW) is not None
    _flush_iops()
