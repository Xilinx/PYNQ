"""Test module for audio.py"""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.tests import unittest
from pyb import overlay

from pyxi.audio import LineIn, Headphone

class Test_0_LineIn(unittest.TestCase):
    """TestCase for the LineIn class."""

    def __init__(self):
        self.linein = LineIn()

    def test_call(self):
        """Tests whether the __call__() method correctly returns a 
        list of two integers.
        """
        self.assertIs(type(self.linein()), list)
        self.assertEqual(len(self.linein()),2)
        self.assertIs(type(self.linein()[0]),int)
        self.assertIs(type(self.linein()[1]),int)


class Test_1_Headphone(unittest.TestCase):
    """TestCase for both the Headphone and LineIn classes."""

    def __init__(self):
        self.Headphone = Headphone()
        self.linein = LineIn()

    def test_0_loop(self):
        """Tests whether the two objects works properly using their __call__() 
        methods, asking for user confirmation.
        """
        input("\nMake sure LineIn is receiveing audio and hit enter...")
        for i in range(100000): # empirically determined loop length
            self.Headphone(self.linein())
        self.assertUserAnswersYes("Heard audio on the headphone (HPH) port?")

    def test_1_mute(self):
        """Tests is_muted() and toggle_mute() methods.""" 
        is_muted = self.Headphone.controller.is_muted() 
        self.Headphone.controller.toggle_mute()
        self.assertEqual(not is_muted, self.Headphone.controller.is_muted())    


def test_audio():
    if not unittest.request_user_confirmation(
                'Both LineIn and Headphone (HPH) jacks connected?'):
            raise unittest.SkipTest()
    #switch to audiovideo overlay - this should be
    #updated in the future with conditional checks
    overlay().update("./overlay/audiovideo.bit.bin")
    # starting tests
    unittest.main(__name__)
    #switch back to pmod overlay 
    overlay().update("./overlay/pmod.bit.bin")


if __name__ == "__main__":
    test_audio()
