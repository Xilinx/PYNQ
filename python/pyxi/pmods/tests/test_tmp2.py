"""Test module for tmp2.py"""


__author__      = "Naveen Purushotham"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Naveen Purushotham"
__email__       = "npurusho@xilinx.com"

from pyxi.tests import unittest

from pyxi.pmods.tmp2 import TMP2
from pyb import mmio, udelay

tmp2 = None

class TestTMP2(unittest.TestCase):
    """TestCase for the TMP2 class."""

    def test_readtemp(self):
        """Reads the TMP2 and asks the user if the temperature is  displayed.
        After that, it asks the user to modify temperature and confirm change
        in reading is displayed.
        """
        n = tmp2.read()
        print("Current temperature: \n%d C" % n)	
        self.assertUserAnswersYes("Reading in celcius displayed?")
        

def test_tmp2():
    if not unittest.request_user_confirmation(
            'Is TMP2 attached to the board?'):
        raise unittest.SkipTest()

    global tmp2
    tmp2 = TMP2(int(input("Insert the PMOD's ID of the TMP2 (1 ~ 4): ")))
    
    # starting tests
    unittest.main(__name__) 
    
    # cleanup active_iops
    from pyxi.pmods._iop import _flush_iops
    _flush_iops()


if __name__ == "__main__":
    test_tmp2()