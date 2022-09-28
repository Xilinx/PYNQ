#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from random import randint
from random import choice
from math import pow
from time import sleep
import pytest
from pynq import MMIO
from pynq import PL




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
        if "xilinx.com:ip:axi_bram_ctrl:" in PL.ip_dict[ip]['type'] :
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


