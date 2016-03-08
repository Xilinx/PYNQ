__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "yunq@xilinx.com"
        
 
import pytest
import os
from random import randint
from math import pow
from pyxi import MMIO, Overlay
    
    
@pytest.mark.run(order=4)
def test_mmio():
    """ Test whether MMIO class is working properly.
    Generate 100 random tests. 
    mmio.write(random offset, random data)
    Steps:
        1. Initialize an instance with word length <= range / 4
        2. Write an integer to a random offset.
        3. The largest unsigned int is 2^32-1. Any number within the 
        range [0, 2^32-1] can be written into a 4-byte location.
    """
    ol = Overlay()
    ol.add_bitstream('pmod.bit')
    ol.add_bitstream('audiovideo.bit')
    
    ol.download_bitstream('pmod.bit')
    mmio_base = int(ol.get_mmio_base('pmod.bit','axi_bram_ctrl_1'),16)
    mmio_range = int(ol.get_mmio_range('pmod.bit','axi_bram_ctrl_1'),16)
    
    mmio = MMIO(mmio_base, int(mmio_range/4))
    for i in range(100):
        offset = 4*randint(0, mmio_range/4-1)
        data = randint(0, pow(2,32)-1)
        mmio.write(offset, data)
        assert mmio.read(offset)==data, 'MMIO read back a wrong random value'
        mmio.write(offset, 0)
        assert mmio.read(offset)==0, 'MMIO read back a wrong fixed value'
        
    ol.download_bitstream('audiovideo.bit')
    mmio_base = int(ol.get_mmio_base('audiovideo.bit','axi_bram_ctrl_0'),16)
    mmio_range = int(ol.get_mmio_range('audiovideo.bit','axi_bram_ctrl_0'),16)
    
    mmio = MMIO(mmio_base, int(mmio_range/4))
    for i in range(100):
        offset = 4*randint(0, mmio_range/4-1)
        data = randint(0, pow(2,32)-1)
        mmio.write(offset, data)
        assert mmio.read(offset)==data, 'MMIO read back a wrong random value'
        mmio.write(offset, 0)
        assert mmio.read(offset)==0, 'MMIO read back a wrong fixed value'
    
    ol.download_bitstream('pmod.bit')