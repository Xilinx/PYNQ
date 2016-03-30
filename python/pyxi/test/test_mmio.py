#   Copyright (c) 2016, Xilinx, Inc.
#   All rights reserved.
# 
#   Redistribution and use in source and binary forms, with or without 
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its 
#       contributors may be used to endorse or promote products derived from 
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "xpp_support@xilinx.com"


import os
from random import randint
from math import pow
from time import sleep
import pytest
from pyxi import MMIO
from pyxi import Overlay
from pyxi import general_const
    
@pytest.mark.run(order=4)
def test_mmio():
    """Test whether MMIO class is working properly.
    
    Generate random tests to swipe through the entire range. 
    mmio.write(all offsets, random data)
    Steps:
    1. Initialize an instance with length in bytes
    2. Write an integer to a given offset.
    3. Write a number within the range [0, 2^32-1] into a 4-byte location.
    4. Change to the next offset and repeat.
    
    """
    ol1 = Overlay('pmod.bit')
    ol2 = Overlay('audiovideo.bit')
    
    ol1.download()
    sleep(0.1)
    mmio_base = int(ol1.get_ip_addr_base('axi_bram_ctrl_1'),16)
    mmio_range = int(ol1.get_ip_addr_range('axi_bram_ctrl_1'),16)
    mmio = MMIO(mmio_base, mmio_range)
    for offset in range(0, 400, general_const.MMIO_WORD_LENGTH):
        data = randint(0, pow(2,32)-1)
        mmio.write(offset, data)
        sleep(0.001)
        assert mmio.read(offset)==data, 'MMIO read back a wrong random value.'
        mmio.write(offset, 0)
        sleep(0.001)
        assert mmio.read(offset)==0, 'MMIO read back a wrong fixed value.'
        
    ol2.download()
    sleep(0.1)
    mmio_base = int(ol2.get_ip_addr_base('axi_bram_ctrl_0'),16)
    mmio_range = int(ol2.get_ip_addr_range('axi_bram_ctrl_0'),16)
    mmio = MMIO(mmio_base, mmio_range)
    for offset in range(0, 400, general_const.MMIO_WORD_LENGTH):
        data = randint(0, pow(2,32)-1)
        mmio.write(offset, data)
        sleep(0.001)
        assert mmio.read(offset)==data, 'MMIO read back a wrong random value.'
        mmio.write(offset, 0)
        sleep(0.001)
        assert mmio.read(offset)==0, 'MMIO read back a wrong fixed value.'
    
    ol1.download()
    del ol1
    del ol2