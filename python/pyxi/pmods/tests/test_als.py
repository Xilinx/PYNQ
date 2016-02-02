"""Test module for als.py"""


__author__      = "Naveen Purushotham"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Naveen Purushotham"
__email__       = "npurusho@xilinx.com"


from pyxi.tests import unittest
from pyxi.pmods.als import ALS

als = None

class TestALS(unittest.TestCase):
    """TestCase for the ALS class."""

    def test_readlight(self):
        """Just reads the ALS and asks the user to dim light manual and verify  
        lower reading is displayed. After that, it asks the user to brighten
        the light and asks again for user to confirm a higher reading is
        displayed.
        """
        n = als.read()
        print("\n%d" % n)	
        self.assertUserAnswersYes("Is the reading between 0-255 displayed?")
        input("Dim light by placing palm over the ALS sensor and hit enter")
        n = als.read()
        print("%d" % n)
        self.assertUserAnswersYes("Is the lower reading displayed?")


def test_als():
    if not unittest.request_user_confirmation(
            'Is ALS attached to the board?'):
        raise unittest.SkipTest()

    global als
    als = ALS(int(input("Insert the PMOD's ID of the ALS (1 ~ 4): ")))
    
    # starting tests
    unittest.main(__name__) 
    
    # cleanup active_iops
    from pyxi.pmods._iop import _flush_iops
    _flush_iops()


if __name__ == "__main__":
    test_als()