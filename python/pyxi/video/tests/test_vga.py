"""Test module for vga.py"""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.tests import unittest
from pyxi.board import delay
from pyb import overlay

from pyxi.video import VGA


class TestVGA_out(unittest.TestCase):
    """TestCase for the VGA class with direction set as output."""

    def __init__(self):
        self.vga = VGA('out')
        self.vga.mode(3) # 1280x720@60Hz
        self.vga.start()
        self.vga.frame_index_next()
        print("Loading ...")

    def test_0_pattern_frame(self):      
        frame = self.vga.frame()
        index = self.vga.frame_index()
        self.vga.frame_index_next()
        
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

        self.vga.frame(index, frame)
        self.vga.frame_index(index)

        self.assertUserAnswersYes("\nColor bar pattern showing on screen?")        


    def test_1_pattern_frame_raw(self):    
        frame_raw = self.vga.frame_raw()
        index = self.vga.frame_index()             
        self.vga.frame_index_next() 

        # constructing colorbar test pattern
        hint = self.vga.frame_width() / 4
        xleft = hint * 3
        xmid = hint * 2 * 3
        xright = hint *3 *3
        xinc = 256.0 / hint
        yint = self.vga.frame_height() / 4
        yinc = 256.0 / yint
        fblue = 0.0
        fred = 256.0
        for hcoi in range(0,self.vga.frame_width()*3, 3):
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
            for wcoi in range(self.vga.frame_height()):
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
        
        self.vga.frame_raw(index, frame_raw)
        self.vga.frame_index(index)

        self.assertUserAnswersYes("\nBlended pattern showing on screen?")               

    def test_2_mode(self):
        self.assertEqual(self.vga.mode(0), "640x480@60Hz")
        self.assertEqual(self.vga.mode(1), "800x600@60Hz")
        self.assertEqual(self.vga.mode(2), "1280x720@60Hz")
        self.assertEqual(self.vga.mode(3), "1280x1024@60Hz")
        self.assertEqual(self.vga.mode(4), "1920x1080@60Hz")

    def test_3_start_stop_state(self):
        self.vga.stop()
        self.assertEqual(self.vga.state(), 0)
        self.vga.start()
        self.assertEqual(self.vga.state(), 1)
        self.vga.stop()
        self.assertEqual(self.vga.state(), 0)


def test_vga():
    if not unittest.request_user_confirmation(
            'VGA port connected to a screen?'):
        raise unittest.SkipTest()
    #switch to audiovideo overlay - this should be
    #updated in the future with conditional checks
    overlay().update("./overlay/audiovideo.bit.bin")
    # starting tests
    unittest.main(__name__)
    #switch back to pmod overlay 
    overlay().update("./overlay/pmod.bit.bin")


if __name__ == "__main__":
    test_vga()
