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


import os
import pytest
from pynq import PL
from pynq import Overlay
from pynq import Clocks
from pynq.pl import BS_BOOT
from pynq.ps import DEFAULT_CLK_MHZ


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


bitfile1 = BS_BOOT
bitfile2 = PL.bitfile_name
ol1 = Overlay(bitfile1)
ol2 = Overlay(bitfile2)

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
    global ol1, ol2
    global cpu_mhz
    global bitfile1_fclk0_mhz, bitfile1_fclk1_mhz
    global bitfile1_fclk2_mhz, bitfile1_fclk3_mhz
    global bitfile2_fclk0_mhz, bitfile2_fclk1_mhz
    global bitfile2_fclk2_mhz, bitfile2_fclk3_mhz

    for ol in [ol1, ol2]:
        ol.download()
        assert len(ol.ip_dict) > 0,\
            'Overlay gets empty IP dictionary.'
        assert len(ol.gpio_dict) > 0,\
            'Overlay gets empty GPIO dictionary.'
        for ip in ol.ip_dict:
            for key in ['addr_range', 'phys_addr', 'state', 'type']:
                assert key in ol.ip_dict[ip], \
                    'Key {} missing in IP {}.'.format(key, ip)
            assert ol.ip_dict[ip]['state'] is None,\
                'Overlay gets wrong IP state.'
            # Set "TEST" for IP states
            ol.ip_dict[ip]['state'] = "TEST"
        for gpio in ol.gpio_dict:
            for key in ['index', 'state']:
                assert key in ol.gpio_dict[gpio], \
                    'Key {} missing in GPIO {}.'.format(key, gpio)
            assert ol.gpio_dict[gpio]['state'] is None, \
                'Overlay gets wrong GPIO state.'
            # Set "TEST" for GPIO states
            ol.gpio_dict[gpio]['state'] = "TEST"
        ol.reset()
        for ip in ol.ip_dict:
            # "TEST" should have been cleared by reset()
            assert ol.ip_dict[ip]['state'] is None,\
                'Overlay cannot reset IP dictionary.'
        for gpio in ol.gpio_dict:
            # "TEST" should have been cleared by reset()
            assert ol.gpio_dict[gpio]['state'] is None,\
                'Overlay cannot reset GPIO dictionary.'
        cpu_mhz = Clocks.cpu_mhz
        bitfile1_fclk0_mhz = Clocks.fclk0_mhz
        bitfile1_fclk1_mhz = Clocks.fclk1_mhz
        bitfile1_fclk2_mhz = Clocks.fclk2_mhz
        bitfile1_fclk3_mhz = Clocks.fclk3_mhz
        assert not ol.timestamp == '', \
            'Overlay ({}) has an empty timestamp.'.format(ol.bitfile_name)
        assert ol.is_loaded(), \
            'Overlay ({}) should be loaded.'.format(ol.bitfile_name)
        assert Clocks.cpu_mhz == cpu_mhz, \
            'CPU frequency should not be changed.'
        assert Clocks.fclk0_mhz == bitfile1_fclk0_mhz, \
            'FCLK0 frequency not correct after downloading {}.'.format(
                ol.bitfile_name)
        assert Clocks.fclk1_mhz == bitfile1_fclk1_mhz, \
            'FCLK1 frequency not correct after downloading {}.'.format(
                ol.bitfile_name)
        assert Clocks.fclk2_mhz == bitfile1_fclk2_mhz, \
            'FCLK2 frequency not correct after downloading {}.'.format(
                ol.bitfile_name)
        assert Clocks.fclk3_mhz == bitfile1_fclk3_mhz, \
            'FCLK3 frequency not correct after downloading {}.'.format(
                ol.bitfile_name)


@pytest.mark.run(order=-1)
def test_end():
    """Wrapping up by changing the overlay back.
    
    This is the last test to be performed.
    
    """
    global ol1, ol2

    ol2.download()

    # Clear the javascript files copied during tests if any
    if os.system("rm -rf ./js"):
        raise RuntimeError('Cannot remove WaveDrom javascripts.')

    del ol1
    del ol2
