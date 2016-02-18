
__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


import pytest
from time import sleep
from pyxi.video import VGA
from pyxi.test.util import user_answer_yes

flag = user_answer_yes("\nVGA port connected to a screen?")
vga = None

@pytest.mark.run(order=38)  
@pytest.mark.skipif(not flag, reason="need VGA connected")  
def test_vga():
    """TestCase for the VGA class with direction set as output."""
    global vga
    vga = VGA('out')
    assert vga.direction is 'out', 'VGA direction is wrong'
    vga.mode(3)
    assert vga.mode(3) is "1280x1024@60Hz", 'wrong VGA mode'
    vga.start()
    assert vga.state()==1, 'wrong VGA state'
    
    print("Loading ...")
    vga.frame_index_next()

@pytest.mark.run(order=39)  
@pytest.mark.skipif(not flag, reason="need VGA connected") 
def test_pattern_frame(): 
    global vga
    frame = vga.frame()
    index = vga.frame_index()
    vga.frame_index_next()
        
    # constructing colorbar test pattern
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

@pytest.mark.run(order=40)  
@pytest.mark.skipif(not flag, reason="need VGA connected") 
def test_pattern_frame_raw(): 
    global vga
    frame_raw = vga.frame_raw()
    index = vga.frame_index()             
    vga.frame_index_next() 

    # constructing colorbar test pattern
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

@pytest.mark.run(order=41)  
@pytest.mark.skipif(not flag, reason="need VGA connected") 
def test_vga_mode():
    global vga
    assert vga.mode(0) is "640x480@60Hz", 'wrong VGA mode'
    assert vga.mode(1) is "800x600@60Hz", 'wrong VGA mode'
    assert vga.mode(2) is "1280x720@60Hz", 'wrong VGA mode'
    assert vga.mode(3) is "1280x1024@60Hz", 'wrong VGA mode'
    assert vga.mode(4) is "1920x1080@60Hz", 'wrong VGA mode'

@pytest.mark.run(order=42)  
@pytest.mark.skipif(not flag, reason="need VGA connected") 
def test_vga_state():
    global vga
    vga.stop()
    assert vga.state()==0, 'wrong VGA state'
    vga.start()
    assert vga.state()==1, 'wrong VGA state'
    vga.stop()
    assert vga.state()==0, 'wrong VGA state'
