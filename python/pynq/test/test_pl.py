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
import pytest
from pynq import Overlay

ol1 = Overlay('pmod.bit')
ol2 = Overlay('audiovideo.bit')
    
@pytest.mark.run(order=2)
def test_overlay():
    """Test whether the overlay is properly set.
    
    Each overlay has its own bitstream. Also need the corresponding ".bxml" 
    and ".tcl" files to pass the tests.
    
    The entries in Microblaze dictionary use the following format:
    mb_instance[key] = {base address, program, gpio pin}.
    
    """
    global ol1, ol2
    
    ol1.download()
    assert 'pmod.bit' in ol1.bitfile_name, \
            'Bitstream is not in the overlay.'
    assert len(ol1.ip_dict)>0,\
            'Overlay gets empty IP dictionary.'
    assert len(ol1.gpio_dict)>0,\
            'Overlay gets empty GPIO dictionary.'
    assert ol1.get_ip_addr_base('SEG_axi_bram_ctrl_1_Mem0')=='0x40000000',\
            'Overlay gets wrong IP base address.'
    assert ol1.get_ip_addr_range('SEG_axi_bram_ctrl_1_Mem0')=='0x8000',\
            'Overlay gets wrong IP address range.'
    for i in ol1.ip_dict.keys():
        assert ol1.get_ip_addr_base(i)==ol1.ip_dict[i][0],\
            'Overlay gets wrong IP base address.'
        assert ol1.get_ip_addr_range(i)==ol1.ip_dict[i][1],\
            'Overlay gets wrong IP address range.'
        assert ol1.get_ip_state(i)==ol1.ip_dict[i][2]==None,\
            'Overlay gets wrong IP state.'
        #: Set the test for the state
        ol1.ip_dict[i][2] = "TEST"
    for i in ol1.gpio_dict.keys():
        assert ol1.get_gpio_user_ix(i)==ol1.gpio_dict[i][0],\
            'Overlay gets wrong PS GPIO pin.'
    ol1.reset_ip_dict()
    for i in ol1.ip_dict.keys():
        #: "TEST" should have been cleared by reset_ip_dict()
        assert ol1.get_ip_state(i)==None,\
            'Overlay cannot reset IP dictionary.'
            
    ol2.download()
    assert 'audiovideo.bit' in ol2.bitfile_name, \
            'Bitstream is not in the overlay.'
    assert len(ol2.ip_dict)>0,\
            'Overlay gets empty IP dictionary.'
    assert len(ol2.gpio_dict)>0,\
            'Overlay gets empty GPIO dictionary.'
    assert ol2.get_ip_addr_base('SEG_axi_bram_ctrl_1_Mem0')=='0x40000000',\
            'Overlay gets wrong IP base address.'
    assert ol2.get_ip_addr_range('SEG_axi_bram_ctrl_1_Mem0')=='0x8000',\
            'Overlay gets wrong IP address range.'
    for i in ol2.ip_dict.keys():
        assert ol2.get_ip_addr_base(i)==ol2.ip_dict[i][0],\
            'Overlay gets wrong IP base address.'
        assert ol2.get_ip_addr_range(i)==ol2.ip_dict[i][1],\
            'Overlay gets wrong IP address range.'
        assert ol2.get_ip_state(i)==ol2.ip_dict[i][2]==None,\
            'Overlay gets wrong IP state.'
        #: Set the test for the state
        ol2.ip_dict[i][2] = "TEST"
    for i in ol2.gpio_dict.keys():
        assert ol2.get_gpio_user_ix(i)==ol2.gpio_dict[i][0],\
            'Overlay gets wrong PS GPIO pin.'
    ol2.reset_ip_dict()
    for i in ol2.ip_dict.keys():
        #: "TEST" should have been cleared by reset_ip_dict()
        assert ol2.get_ip_state(i)==None,\
            'Overlay cannot reset IP dictionary.'

@pytest.mark.run(order=9)
def test_pmod():
    """Download the bitstream "pmod.bit", and then test.
    
    Need the corresponding "pmod.bxml" and "pmod.tcl" files to pass the tests.
    
    """
    global ol1,ol2
    ol1.download()
    assert not ol1.get_timestamp()=='', \
            'Overlay (pmod.bit) has an empty timestamp.'
    assert ol1.is_loaded(), \
            'Overlay (pmod.bit) should be loaded.'
    assert not ol2.is_loaded(), \
            'Overlay (audiovideo.bit) should not be loaded.'

@pytest.mark.run(order=29)
def test_audiovideo():
    """Change the bitstream to "audiovideo.bit", and then test.
    
    Need the corresponding "audiovideo.bxml" and "audiovideo.tcl" files to 
    pass the tests.
    
    """
    global ol1,ol2
    ol2.download()
    assert not ol2.get_timestamp()=='', \
            'Overlay (audiovideo.bit) has an empty timestamp.'
    assert not ol1.is_loaded(), \
            'Overlay (pmod.bit) should not be loaded.'
    assert ol2.is_loaded(), \
            'Overlay (audiovideo.bit) should be loaded.'

@pytest.mark.run(order=38)
def test_end():
    """Wrapping up by changing the bitstream back to "pmod.bit".
    
    This is the last test to be performed.
    
    """
    global ol1,ol2
    ol1.download()
    assert not ol1.get_timestamp()=='', \
            'Overlay (pmod.bit) has an empty timestamp.'
    assert ol1.is_loaded(), \
            'Overlay (pmod.bit) should be loaded.'
    assert not ol2.is_loaded(), \
            'Overlay (audiovideo.bit) should not be loaded.'
    del ol1
    del ol2