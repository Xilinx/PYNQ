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
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


from time import sleep
import pytest
from pynq import Overlay
from pynq.video import VGA
from pynq.test.util import user_answer_yes

flag = user_answer_yes("\nVGA port connected to a screen?")

@pytest.mark.run(order=33)
@pytest.mark.skipif(not flag, reason="need VGA connected")
def test_vga():
    """Test for the VGA class with direction set as output.
    
    Test the direction, the display mode, and the state.
    
    """
    global vga
    vga = VGA('out')
    
    assert vga.direction is 'out', 'Wrong direction for VGA.'
    vga.mode(3)
    assert vga.mode(3) == "1280x1024@60Hz", 'Wrong display mode for VGA.'
    vga.start()
    assert vga.state()==1, 'Wrong state for VGA.'
    
    print("\nLoading (may take up to 10 seconds)...")
    vga.frame_index_next()

@pytest.mark.run(order=34)
@pytest.mark.skipif(not flag, reason="need VGA connected")
def test_pattern_colorbar():
    """Test for the VGA class with color bar pattern.
    
    This test will show 8 vertical color bars on the screen. 
    
    """
    global vga
    
    frame = vga.frame()
    index = vga.frame_index()
    vga.frame_index_next()
        
    #: Constructing colorbar test pattern
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

    vga.frame(index, frame)
    vga.frame_index(index)

    assert user_answer_yes("\nColor bar pattern showing on screen?")        

@pytest.mark.run(order=35)
@pytest.mark.skipif(not flag, reason="need VGA connected")
def test_pattern_blended():
    """Test for the VGA class with color bar pattern.
    
    This test will show a blended color pattern on the screen. 
    
    """
    global vga
    
    frame_raw = vga.frame_raw()
    index = vga.frame_index()             
    vga.frame_index_next() 

    #: Constructing blended test pattern
    hint = vga.frame_width() / 4
    xleft = hint * 3
    xmid = hint * 2 * 3
    xright = hint *3 *3
    xinc = 256.0 / hint
    yint = vga.frame_height() / 4
    yinc = 256.0 / yint
    fblue = 0.0
    fred = 256.0
    for hcoi in range(0,vga.frame_width()*3, 3):
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
        for wcoi in range(vga.frame_height()):
            if fgreen >= 256.0:
                wgreen = 255
            else:
                wgreen = int(fgreen)
            frame_raw[ipixeladdr + 0] = wred
            frame_raw[ipixeladdr + 1] = wgreen
            frame_raw[ipixeladdr + 2] = wblue
            if wcoi < yint:
                fgreen += yinc
            elif wcoi < 2*yint:
                fgreen -= yinc
            elif wcoi < 3*yint:
                fgreen += yinc
            else:
                fgreen -= yinc
            ipixeladdr += 1920*3 # stride
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
        
    vga.frame_raw(index, frame_raw)
    vga.frame_index(index)

    assert user_answer_yes("\nBlended pattern showing on screen?")               

@pytest.mark.run(order=36)
@pytest.mark.skipif(not flag, reason="need VGA connected")
def test_vga_mode():
    global vga
    
    assert vga.mode(0) == "640x480@60Hz", 'Wrong display mode for VGA.'
    assert vga.mode(1) == "800x600@60Hz", 'Wrong display mode for VGA.'
    assert vga.mode(2) == "1280x720@60Hz", 'Wrong display mode for VGA.'
    assert vga.mode(3) == "1280x1024@60Hz", 'Wrong display mode for VGA.'
    assert vga.mode(4) == "1920x1080@60Hz", 'Wrong display mode for VGA.'

@pytest.mark.run(order=37)
@pytest.mark.skipif(not flag, reason="need VGA connected")
def test_vga_state():
    global vga
    
    vga.stop()
    assert vga.state()==0, 'Wrong state for VGA.'
    vga.start()
    assert vga.state()==1, 'Wrong state for VGA.'
    vga.stop()
    assert vga.state()==0, 'Wrong state for VGA.'
    
    del vga
