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
__email__       = "xpp_support@xilinx.com"


from time import sleep
import pytest
from pyxi import Overlay
from pyxi.video import HDMI
from pyxi.test.util import user_answer_yes

flag = user_answer_yes("\nHDMI port connected to a video source?")
if flag:
    global ol
    ol = Overlay("audiovideo.bit")
    
@pytest.mark.run(order=32)
@pytest.mark.skipif(not flag, reason="need HDMI connected")
def test_hdmi():
    """Test for the HDMI class with direction set as input.
    
    It may take some time to load the frames. After that, the direction, 
    frame size, and the frame index will all be tested.
    
    """
    global hdmi
    hdmi = HDMI('in')
    print("\nLoading (may take up to 10 seconds)...")
    sleep(10)
    assert hdmi.direction is 'in', 'Wrong direction for HDMI.'
    
    hdmi.start()
    frame_raw = hdmi.frame_raw()
    assert len(frame_raw)==1920*1080*3, 'Wrong frame size for HDMI.'
    
    index = hdmi.frame_index()
    hdmi.frame_index(index+1)
    assert not hdmi.frame_index()==index, 'HDMI frame index is not changed.'
    
    hdmi.stop()
    del hdmi
    ol.flush_ip_dictionary()