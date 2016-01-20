"""Test module for oled.py"""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.tests import unittest

from pyxi.pmods.oled import OLED

oled = None

class TestOLED(unittest.TestCase):
    """TestCase for the OLED class."""

    def test_writeString(self):
        """Just writes on the OLED the string 'TEST' and asks the user to 
        confirm if it is shown on the OLED. After that, it clears the screen 
        and asks again for user confirmation.
        """
        oled.write('Welcome to Zybo.')
        self.assertUserAnswersYes("\nWelcome message shown on the OLED?")
        oled.clear_screen()
        self.assertUserAnswersYes("OLED screen clear now?")      


def test_oled():
    if not unittest.request_user_confirmation(
            'Is OLED attached to the board?'):
        raise unittest.SkipTest()

    global oled
    oled = OLED(int(input("Insert the PMOD's ID of the OLED: ")))
    
    # starting tests
    unittest.main(__name__) 
    
    # cleanup active_iops
    from pyxi.pmods._iop import _flush_iops
    _flush_iops()


if __name__ == "__main__":
    test_oled()
