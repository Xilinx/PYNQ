"""Test module for hdmi.py"""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.tests import unittest
from pyxi.board import delay
from pyb import overlay

from pyxi.video import HDMI


class TestHDMI_in(unittest.TestCase):
    """TestCase for the HDMI class with direction set as input."""

    def __init__(self):
        self.hdmi = HDMI('in')
        print("Loading ...")
        delay(10)

    def test_0_memoryview(self):
        frame_raw = self.hdmi.frame_raw()
        self.assertEqual(len(frame_raw), 1920*1080*3)

    def test_1_change_frame_index(self):
        index = self.hdmi.frame_index()
        self.hdmi.frame_index(index + 1)
        self.assertNotEqual(self.hdmi.frame_index(), index)        


def test_hdmi():
    if not unittest.request_user_confirmation(
            'HDMI port connected to a video source?'):
        raise unittest.SkipTest()
    #switch to audiovideo overlay - this should be
    #updated in the future with conditional checks
    overlay().update("./overlay/audiovideo.bit.bin")
    # starting tests
    unittest.main(__name__)
    #switch back to pmod overlay 
    overlay().update("./overlay/pmod.bit.bin")


if __name__ == "__main__":
    test_hdmi()
