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

__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


from time import sleep
import pytest
from pynq import Overlay
from pynq.drivers import HDMI
from pynq.drivers import HDMI
from pynq.tests.util import user_answer_yes

flag_hdmi_in = user_answer_yes("\nHDMI in connected to a video source?")
flag_hdmi_out = user_answer_yes("HDMI out connected to a screen?")

@pytest.mark.run(order=32)
@pytest.mark.skipif(not flag_hdmi_in, reason="need HDMI connected")
def test_hdmi_in():
    """Test for the HDMI class with direction set as input.
    
    It may take some time to load the frames. After that, the direction, 
    frame size, and the frame index will all be tested.
    
    """
    pass
    
@pytest.mark.run(order=33)
@pytest.mark.skipif(not flag_hdmi_out, reason="need HDMI connected")
def test_hdmi_out():
    """Test for the HDMI class with direction set as output.
    
    Test the direction, the display mode, and the state.
    
    """
    pass

@pytest.mark.run(order=34)
@pytest.mark.skipif(not flag_hdmi_out, reason="need HDMI connected")
def test_pattern_colorbar():
    """Test for the HDMI class with color bar pattern.
    
    This test will show 8 vertical color bars on the screen. 
    
    """
    pass

@pytest.mark.run(order=35)
@pytest.mark.skipif(not flag_hdmi_out, reason="need HDMI connected")
def test_pattern_blended():
    """Test for the HDMI class with color bar pattern.
    
    This test will show a blended color pattern on the screen. 
    
    """
    pass
