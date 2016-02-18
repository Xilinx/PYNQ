__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "yunq@xilinx.com"
        
 
import pytest
import os
from pyxi import OVERLAY
    
ol = OVERLAY()
ol.add_bitstream('pmod.bit')
ol.add_bitstream('audiovideo.bit')
    
@pytest.mark.run(order=4)
def test_overlay():
    """ Test whether the overlay is properly set.
    """
    global ol
    assert 'pmod.bit' in ol.get_name(), \
            'pmod.bit is not in the overlay'
    assert 'audiovideo.bit' in ol.get_name(), \
            'audiovideo.bit is not in the overlay'
    assert not ol.get_iplist('pmod.bit')==[], \
            'pmod.bit has an empty IP list'
    assert not ol.get_iplist('audiovideo.bit')==[], \
            'audiovideo.bit has an empty IP list'
            
    assert ol.get_mmio_base('pmod.bit','axi_bram_ctrl_1')=='0x40000000',\
            'pmod.bit gets wrong MMIO base'
    assert ol.get_mmio_range('pmod.bit','axi_bram_ctrl_1')=='0x8000',\
            'pmod.bit gets wrong MMIO range'
            
    assert ol.get_mmio_base('audiovideo.bit','axi_bram_ctrl_0')=='0x40000000',\
            'audiovideo.bit gets wrong MMIO base'
    assert ol.get_mmio_range('audiovideo.bit','axi_bram_ctrl_0')=='0x8000',\
            'audiovideo.bit gets wrong MMIO range'

@pytest.mark.run(order=9)
def test_pmod():
    """ Change the bitstream on PL to "pmod", and then test.
    """
    global ol
    ol.download_bitstream('pmod.bit')
    assert not ol.get_timestamp('pmod.bit')=='', \
            'pmod.bit does not have timestamp'
    assert ol.get_status('pmod.bit')=='LOADED', \
            'pmod.bit is not loaded yet'
    assert ol.get_status('audiovideo.bit')=='UNLOADED', \
            'audiovideo.bit should not be loaded'

@pytest.mark.run(order=33)
def test_audiovideo():
    """ Change the bitstream on PL to "audiovideo", and then test.
    """
    global ol
    ol.download_bitstream('audiovideo.bit')
    assert not ol.get_timestamp('audiovideo.bit')=='', \
            'audiovideo.bit does not have timestamp'
    assert ol.get_status('pmod.bit')=='UNLOADED', \
            'pmod.bit should not be loaded'
    assert ol.get_status('audiovideo.bit')=='LOADED', \
            'audiovideo.bit is not loaded yet'

@pytest.mark.run(order=43)
def test_end():
    """ Wrapping up by changing the bitstream back to "pmod".
    """
    global ol
    ol.download_bitstream('pmod.bit')
    assert not ol.get_timestamp('pmod.bit')=='', \
            'pmod.bit does not have timestamp'
    assert ol.get_status('pmod.bit')=='LOADED', \
            'pmod.bit is not loaded yet'
    assert ol.get_status('audiovideo.bit')=='UNLOADED', \
            'audiovideo.bit should not be loaded'