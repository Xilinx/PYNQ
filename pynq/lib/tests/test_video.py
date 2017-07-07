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
from pynq.tests.util import user_answer_yes

flag_hdmi_in = user_answer_yes("\nHDMI IN connected to a video source?")
flag_hdmi_out = user_answer_yes("HDMI OUT connected to a monitor?")
flag_hdmi = flag_hdmi_in and flag_hdmi_out

@pytest.mark.run(order=33)
@pytest.mark.skipif(not flag_hdmi_in, reason="need HDMI IN connected")
def test_hdmi_in():
    """Test for the HDMI class with direction set as input.
    
    It may take some time to load the frames. After that, the direction, 
    frame size, and the frame index will all be tested.
    
    """
    hdmi_in = HDMI('in')
    print("\nLoading (may take a few seconds)...")
    sleep(5)
    assert hdmi_in.direction=='in', 'Wrong HDMI direction.'
    
    hdmi_in.start()
    frame_raw = hdmi_in.frame_raw()
    assert len(frame_raw)==1920*1080*3, 'Wrong HDMI frame size.'
    
    index = hdmi_in.frame_index()
    hdmi_in.frame_index(index+1)
    assert not hdmi_in.frame_index()==index, 'Wrong HDMI frame index.'
    
    hdmi_in.stop()
    del hdmi_in
    
@pytest.mark.run(order=34)
@pytest.mark.skipif(not flag_hdmi_out, reason="need HDMI OUT connected")
def test_hdmi_out():
    """Test for the HDMI class with direction set as output.
    
    Test the direction, the display mode, and the state. For the state 
    information, `0` means `stopped`, while `1` means `started`.
    
    """
    hdmi_out = HDMI('out')
    
    assert hdmi_out.direction=='out', 'Wrong direction for HDMI.'
    hdmi_out.mode(2)
    assert hdmi_out.mode(2)=="1280x720@60Hz", 'Wrong HDMI display mode.'
    hdmi_out.start()
    assert hdmi_out.state()==1, 'Wrong HDMI state.'
    
    index = hdmi_out.frame_index()
    hdmi_out.frame_index_next()
    assert not hdmi_out.frame_index()==index, 'Wrong HDMI frame index.'
    
    hdmi_out.stop()
    del hdmi_out

@pytest.mark.run(order=35)
@pytest.mark.skipif(not flag_hdmi_out, reason="need HDMI OUT connected")
def test_pattern_colorbar():
    """Test for the HDMI class with color bar pattern.
    
    This test will show 8 vertical color bars on the screen. 
    
    """
    hdmi_out = HDMI('out')
    hdmi_out.mode(2)
    hdmi_out.start()
    
    frame = hdmi_out.frame()
    index = hdmi_out.frame_index()
    hdmi_out.frame_index_next()
    
    xint = int(frame.width / 8)
    xinc = 256.0 / xint
    fcolor =  0.0
    xcurrentint = 1
    for xcoi in range(frame.width):
        if xcurrentint > 7:
            wred = 255
            wblue = 255
            wgreen = 255
        else:
            if xcurrentint & 0b001:
                wred = int(fcolor)
            else:
                wred = 0
            if xcurrentint & 0b010:
                wblue = int(fcolor)
            else:
                wblue = 0
            if xcurrentint & 0b100:
                wgreen = int(fcolor)
            else:
                wgreen = 0
            fcolor += xinc
            if fcolor >= 256.0:
                fcolor = 0.0
                xcurrentint += 1
            
        for ycoi in range(frame.height):
            frame[xcoi, ycoi] = (wred, wgreen, wblue)

    hdmi_out.frame(index, frame)
    hdmi_out.frame_index(index)

    assert user_answer_yes("\nColor bar pattern showing on screen?")
    
    hdmi_out.stop()
    del hdmi_out
    
@pytest.mark.run(order=36)
@pytest.mark.skipif(not flag_hdmi_out, reason="need HDMI OUT connected")
def test_pattern_blended():
    """Test for the HDMI class with blended color pattern.
    
    This test will show a blended color pattern on the screen. 
    
    """
    hdmi_out = HDMI('out')
    hdmi_out.mode(2)
    hdmi_out.start()
    
    frame_raw = hdmi_out.frame_raw()
    index = hdmi_out.frame_index()             
    hdmi_out.frame_index_next() 

    hint = hdmi_out.frame_width() / 4
    xleft = hint * 3
    xmid = hint * 2 * 3
    xright = hint *3 *3
    xinc = 256.0 / hint
    yint = hdmi_out.frame_height() / 4
    yinc = 256.0 / yint
    fblue = 0.0
    fred = 256.0
    for hcoi in range(0,hdmi_out.frame_width()*3, 3):
        if fred >= 256.0:
            wred = 255
        else:
            wred = int(fred)
        if fblue >= 256.0:
            wblue = 255
        else:
            wblue = int(fblue)
        ipixeladdr = hcoi
        fgreen = 0.0
        for wcoi in range(hdmi_out.frame_height()):
            if fgreen >= 256.0:
                wgreen = 255
            else:
                wgreen = int(fgreen)
            frame_raw[ipixeladdr] = wblue
            frame_raw[ipixeladdr + 1] = wgreen
            frame_raw[ipixeladdr + 2] = wred
            if wcoi < yint:
                fgreen += yinc
            elif wcoi < 2*yint:
                fgreen -= yinc
            elif wcoi < 3*yint:
                fgreen += yinc
            else:
                fgreen -= yinc
            ipixeladdr += 1920*3
        if hcoi < xleft:
            fblue = 0.0
            fred -= xinc
        elif hcoi < xmid:
            fblue += xinc
            fred += xinc
        elif hcoi < xright:    
            fblue -= xinc
            fred -= xinc
        else:
            fblue += xinc
            fred = 0.0
        
    hdmi_out.frame_raw(index, frame_raw)
    hdmi_out.frame_index(index)

    assert user_answer_yes("\nBlended pattern showing on screen?")
    
    hdmi_out.stop()
    del hdmi_out
    
@pytest.mark.run(order=37)
@pytest.mark.skipif(not flag_hdmi_out, reason="need HDMI OUT connected")
def test_hdmi_state():
    """Test the state information of an HDMI object.
    
    This test will test all the available resolution modes, and the state.
    For the state information, `0` means `stopped`, while `1` means `started`.
    
    """
    hdmi_out = HDMI('out')
    hdmi_out.mode(2)
    hdmi_out.start()
    
    assert hdmi_out.mode(0) == "640x480@60Hz", 'Wrong HDMI display mode.'
    assert hdmi_out.mode(1) == "800x600@60Hz", 'Wrong HDMI display mode.'
    assert hdmi_out.mode(2) == "1280x720@60Hz", 'Wrong HDMI display mode.'
    assert hdmi_out.mode(3) == "1280x1024@60Hz", 'Wrong HDMI display mode.'
    assert hdmi_out.mode(4) == "1920x1080@60Hz", 'Wrong HDMI display mode.'
    
    hdmi_out.stop()
    assert hdmi_out.state()==0, 'Wrong HDMI state.'
    hdmi_out.start()
    assert hdmi_out.state()==1, 'Wrong HDMI state.'
    hdmi_out.stop()
    assert hdmi_out.state()==0, 'Wrong HDMI state.'
    
    del hdmi_out
    
@pytest.mark.run(order=38)
@pytest.mark.skipif(not flag_hdmi, reason="need HDMI IN and OUT connected")
def test_hdmi_state():
    """Test the HDMI streaming video.
    
    This test requires the video to be streamed into the HDMI IN. Users should
    see live video from a monitor to which the HDMI OUT is connected.
    
    """
    hdmi_out = HDMI('out')
    hdmi_in = HDMI('in',frame_list=hdmi_out.frame_list)
    
    hdmi_out.mode(2)
    hdmi_in.start()
    hdmi_out.start()
    
    assert user_answer_yes("\nSee live video on screen?")
    
    hdmi_in.stop()
    hdmi_out.stop()
    del hdmi_in
    del hdmi_out
    