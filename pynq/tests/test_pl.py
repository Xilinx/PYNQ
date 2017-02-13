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

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"

import pytest
from pynq import general_const
from pynq import Overlay
from pynq import Clocks
from pynq.ps import DEFAULT_CLK_MHZ

bitfile1 = 'base.bit'
bitfile2 = 'interface.bit'

ol1 = Overlay(bitfile1)
ol2 = Overlay(bitfile1)
ol3 = Overlay(bitfile2)

cpu_mhz = 0
bitfile1_fclk0_mhz = DEFAULT_CLK_MHZ
bitfile1_fclk1_mhz = DEFAULT_CLK_MHZ
bitfile1_fclk2_mhz = DEFAULT_CLK_MHZ
bitfile1_fclk3_mhz = DEFAULT_CLK_MHZ
bitfile2_fclk0_mhz = DEFAULT_CLK_MHZ
bitfile2_fclk1_mhz = DEFAULT_CLK_MHZ
bitfile2_fclk2_mhz = DEFAULT_CLK_MHZ
bitfile2_fclk3_mhz = DEFAULT_CLK_MHZ


@pytest.mark.run(order=2)
def test_overlay():
    """Test whether the overlay is properly set.
    
    Each overlay has its own bitstream. Also need the corresponding ".tcl" 
    files to pass the tests.
    
    """
    global ol1, ol2, ol3
    global cpu_mhz
    global bitfile1_fclk0_mhz, bitfile1_fclk1_mhz
    global bitfile1_fclk2_mhz, bitfile1_fclk3_mhz
    global bitfile2_fclk0_mhz, bitfile2_fclk1_mhz
    global bitfile2_fclk2_mhz, bitfile2_fclk3_mhz

    ol1.download()
    assert bitfile1 in ol1.bitfile_name, \
        'Bitstream is not in the overlay.'
    assert len(ol1.ip_dict) > 0,\
        'Overlay gets empty IP dictionary.'
    assert len(ol1.gpio_dict) > 0,\
        'Overlay gets empty GPIO dictionary.'
    assert ol1.ip_dict['mb_bram_ctrl_1']['phys_addr'] == \
        int('0x40000000', 16), 'Overlay gets wrong IP base address.'
    assert ol1.ip_dict['mb_bram_ctrl_1']['addr_range'] == \
        int('0x10000', 16), 'Overlay gets wrong IP address range.'
    for i in ol1.ip_dict:
        assert ol1.ip_dict[i]['state'] is None,\
            'Overlay gets wrong IP state.'
        # Set "TEST" for IP states
        ol1.ip_dict[i]['state'] = "TEST"
    for i in ol1.gpio_dict:
        assert ol1.gpio_dict[i]['state'] is None, \
            'Overlay gets wrong GPIO state.'
        # Set "TEST" for GPIO states
        ol1.gpio_dict[i]['state'] = "TEST"
    ol1.reset()
    for i in ol1.ip_dict:
        # "TEST" should have been cleared by reset()
        assert ol1.ip_dict[i]['state'] is None,\
            'Overlay cannot reset IP dictionary.'
    for i in ol1.gpio_dict:
        # "TEST" should have been cleared by reset()
        assert ol1.gpio_dict[i]['state'] is None,\
            'Overlay cannot reset GPIO dictionary.'
    cpu_mhz = Clocks.cpu_mhz
    bitfile1_fclk0_mhz = Clocks.fclk0_mhz
    bitfile1_fclk1_mhz = Clocks.fclk1_mhz
    bitfile1_fclk2_mhz = Clocks.fclk2_mhz
    bitfile1_fclk3_mhz = Clocks.fclk3_mhz

    ol2.download()
    assert bitfile1 in ol2.bitfile_name, \
        'Bitstream is not in the overlay.'
    assert len(ol2.ip_dict) > 0, \
        'Overlay gets empty IP dictionary.'
    assert len(ol2.gpio_dict) > 0, \
        'Overlay gets empty GPIO dictionary.'
    assert ol2.ip_dict['mb_bram_ctrl_1']['phys_addr'] == \
        int('0x40000000', 16), 'Overlay gets wrong IP base address.'
    assert ol2.ip_dict['mb_bram_ctrl_1']['addr_range'] == \
        int('0x10000', 16), 'Overlay gets wrong IP address range.'
    for i in ol2.ip_dict:
        assert ol2.ip_dict[i]['state'] is None, \
            'Overlay gets wrong IP state.'
        # Set "TEST" for IP states
        ol2.ip_dict[i]['state'] = "TEST"
    for i in ol2.gpio_dict:
        assert ol2.gpio_dict[i]['state'] is None, \
            'Overlay gets wrong GPIO state.'
        # Set "TEST" for GPIO states
        ol2.gpio_dict[i]['state'] = "TEST"
    ol2.reset()
    for i in ol2.ip_dict:
        # "TEST" should have been cleared by reset()
        assert ol2.ip_dict[i]['state'] is None, \
            'Overlay cannot reset IP dictionary.'
    for i in ol2.gpio_dict:
        # "TEST" should have been cleared by reset()
        assert ol2.gpio_dict[i]['state'] is None, \
            'Overlay cannot reset GPIO dictionary.'

    ol3.download()
    assert bitfile2 in ol3.bitfile_name, \
        'Bitstream is not in the overlay.'
    assert len(ol3.ip_dict) > 0, \
        'Overlay gets empty IP dictionary.'
    assert len(ol3.gpio_dict) > 0, \
        'Overlay gets empty GPIO dictionary.'
    assert ol3.ip_dict['mb_bram_ctrl_1']['phys_addr'] == \
        int('0x40000000', 16), 'Overlay gets wrong IP base address.'
    assert ol3.ip_dict['mb_bram_ctrl_1']['addr_range'] == \
        int('0x10000', 16), 'Overlay gets wrong IP address range.'
    for i in ol3.ip_dict:
        assert ol3.ip_dict[i]['state'] is None, \
            'Overlay gets wrong IP state.'
        # Set "TEST" for IP states
        ol3.ip_dict[i][2] = "TEST"
    for i in ol3.gpio_dict:
        assert ol3.gpio_dict[i]['state'] is None, \
            'Overlay gets wrong GPIO state.'
        # Set "TEST" for GPIO states
        ol3.gpio_dict[i]['state'] = "TEST"
    ol3.reset()
    for i in ol3.ip_dict:
        # "TEST" should have been cleared by reset()
        assert ol3.ip_dict[i]['state'] is None, \
            'Overlay cannot reset IP dictionary.'
    for i in ol3.gpio_dict:
        # "TEST" should have been cleared by reset()
        assert ol3.gpio_dict[i]['state'] is None, \
            'Overlay cannot reset GPIO dictionary.'
    bitfile2_fclk0_mhz = Clocks.fclk0_mhz
    bitfile2_fclk1_mhz = Clocks.fclk1_mhz
    bitfile2_fclk2_mhz = Clocks.fclk2_mhz
    bitfile2_fclk3_mhz = Clocks.fclk3_mhz


@pytest.mark.run(order=10)
def test_overlay1():
    """Download the bitstream for the first overlay, and then test.
    
    Need the corresponding `*.tcl` file to pass the tests.
    
    """
    global ol1
    global cpu_mhz
    global bitfile1_fclk0_mhz, bitfile1_fclk1_mhz
    global bitfile1_fclk2_mhz, bitfile1_fclk3_mhz

    ol1.download()
    assert not ol1.bitstream.timestamp == '', \
        f'Overlay 1 ({bitfile1}) has an empty timestamp.'
    assert ol1.is_loaded(), \
        f'Overlay 1 ({bitfile1}) should be loaded.'
    assert Clocks.cpu_mhz == cpu_mhz, \
        'CPU frequency should not be changed.'
    assert Clocks.fclk0_mhz == bitfile1_fclk0_mhz, \
        f'FCLK0 frequency not correct after downloading {bitfile1}.'
    assert Clocks.fclk1_mhz == bitfile1_fclk1_mhz, \
        f'FCLK1 frequency not correct after downloading {bitfile1}.'
    assert Clocks.fclk2_mhz == bitfile1_fclk2_mhz, \
        f'FCLK2 frequency not correct after downloading {bitfile1}.'
    assert Clocks.fclk3_mhz == bitfile1_fclk3_mhz, \
        f'FCLK3 frequency not correct after downloading {bitfile1}.'


@pytest.mark.run(order=30)
def test_overlay2():
    """Change to another overlay, and then test.
    
    Need the corresponding `*.tcl` file to pass the tests.
    
    """
    global ol2
    global cpu_mhz
    global bitfile1_fclk0_mhz, bitfile1_fclk1_mhz
    global bitfile1_fclk2_mhz, bitfile1_fclk3_mhz

    ol2.download()
    assert not ol2.bitstream.timestamp == '', \
        f'Overlay 2 ({bitfile1}) has an empty timestamp.'
    assert ol2.is_loaded(), \
        f'Overlay 2 ({bitfile1}) should be loaded.'
    assert Clocks.cpu_mhz == cpu_mhz, \
        'CPU frequency should not be changed.'
    assert Clocks.fclk0_mhz == bitfile1_fclk0_mhz, \
        f'FCLK0 frequency not correct after downloading {bitfile1}.'
    assert Clocks.fclk1_mhz == bitfile1_fclk1_mhz, \
        f'FCLK1 frequency not correct after downloading {bitfile1}.'
    assert Clocks.fclk2_mhz == bitfile1_fclk2_mhz, \
        f'FCLK2 frequency not correct after downloading {bitfile1}.'
    assert Clocks.fclk3_mhz == bitfile1_fclk3_mhz, \
        f'FCLK3 frequency not correct after downloading {bitfile1}.'


@pytest.mark.run(order=39)
def test_overlay3():
    """Change to another overlay, and then test.

    Need the corresponding `*.tcl` file to pass the tests.

    """
    global ol3
    global cpu_mhz
    global bitfile2_fclk0_mhz, bitfile2_fclk1_mhz
    global bitfile2_fclk2_mhz, bitfile2_fclk3_mhz

    ol3.download()
    assert not ol3.bitstream.timestamp == '', \
        f'Overlay 3 ({bitfile2}) has an empty timestamp.'
    assert ol3.is_loaded(), \
        f'Overlay 3 ({bitfile2}) should be loaded.'
    assert Clocks.cpu_mhz == cpu_mhz, \
        'CPU frequency should not be changed.'
    assert Clocks.fclk0_mhz == bitfile2_fclk0_mhz, \
        f'FCLK0 frequency not correct after downloading {bitfile2}.'
    assert Clocks.fclk1_mhz == bitfile2_fclk1_mhz, \
        f'FCLK1 frequency not correct after downloading {bitfile2}.'
    assert Clocks.fclk2_mhz == bitfile2_fclk2_mhz, \
        f'FCLK2 frequency not correct after downloading {bitfile2}.'
    assert Clocks.fclk3_mhz == bitfile2_fclk3_mhz, \
        f'FCLK3 frequency not correct after downloading {bitfile2}.'


@pytest.mark.run(order=49)
def test_end():
    """Wrapping up by changing the overlay back.
    
    This is the last test to be performed.
    
    """
    global ol1, ol2, ol3
    global cpu_mhz
    global bitfile1_fclk0_mhz, bitfile1_fclk1_mhz
    global bitfile1_fclk2_mhz, bitfile1_fclk3_mhz

    ol1.download()
    assert not ol1.bitstream.timestamp == '', \
        f'Overlay 1 ({bitfile1}) has an empty timestamp.'
    assert ol1.is_loaded(), \
        f'Overlay 1 ({bitfile1}) should be loaded.'
    assert Clocks.cpu_mhz == cpu_mhz, \
        'CPU frequency should not be changed.'
    assert Clocks.fclk0_mhz == bitfile1_fclk0_mhz, \
        f'FCLK0 frequency not correct after downloading {bitfile1}.'
    assert Clocks.fclk1_mhz == bitfile1_fclk1_mhz, \
        f'FCLK1 frequency not correct after downloading {bitfile1}.'
    assert Clocks.fclk2_mhz == bitfile1_fclk2_mhz, \
        f'FCLK2 frequency not correct after downloading {bitfile1}.'
    assert Clocks.fclk3_mhz == bitfile1_fclk3_mhz, \
        f'FCLK3 frequency not correct after downloading {bitfile1}.'

    del ol1
    del ol2
    del ol3
