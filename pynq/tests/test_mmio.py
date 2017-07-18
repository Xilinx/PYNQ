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


from random import randint
from random import choice
from math import pow
from time import sleep
import pytest
from pynq import MMIO
from pynq import PL


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


@pytest.mark.run(order=4)
def test_mmio():
    """Test whether MMIO class is working properly.
    
    Generate random tests to swipe through the entire range:
    
    >>> mmio.write(all offsets, random data)
    
    Steps:
    
    1. Initialize an instance with length in bytes
    
    2. Write an integer to a given offset.
    
    3. Write a number within the range [0, 2^32-1] into a 4-byte location.
    
    4. Change to the next offset and repeat.
    
    """
    mmio_base = mmio_range = None
    for ip in PL.ip_dict:
        if PL.ip_dict[ip]['type'] == "xilinx.com:ip:axi_bram_ctrl:4.0":
            mmio_base = PL.ip_dict[ip]['phys_addr']
            mmio_range = PL.ip_dict[ip]['addr_range']
            break

    if mmio_base is not None and mmio_range is not None:
        mmio = MMIO(mmio_base, mmio_range)
        for offset in range(0, min(100, mmio_range), 4):
            data1 = randint(0, pow(2, 32) - 1)
            mmio.write(offset, data1)
            sleep(0.1)
            data2 = mmio.read(offset)
            assert data1 == data2, \
                'MMIO read back a wrong random value at offset {}.'.format(
                    offset)
            mmio.write(offset, 0)
            sleep(0.1)
            assert mmio.read(offset) == 0, \
                'MMIO read back a wrong fixed value at offset {}.'.format(
                    offset)
    else:
        raise RuntimeError("No testable IP for MMIO class.")
