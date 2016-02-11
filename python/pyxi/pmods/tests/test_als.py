"""Test module for als.py"""


__author__      = "Naveen Purushotham, Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Naveen Purushotham"
__email__       = "npurusho@xilinx.com"


import pytest
from pyxi.pmods.als import ALS
from pyxi.pmods._iop import _flush_iops
from pyxi.test.util import user_answer_yes

flag = user_answer_yes("\nALS attached to the board?")
if flag:
    global als_id
    als_id = int(input("Type in the PMOD ID of the ALS (1 ~ 4): "))

@pytest.mark.run(order=24)  
@pytest.mark.skipif(not flag, reason="need ALS attached in order to run")
def test_readlight():
    """TestCase for the ALS class.
    Just reads the ALS and asks the user to dim light manual and verify  
    lower reading is displayed. After that, it asks the user to brighten
    the light and asks again for user to confirm a higher reading is
    displayed.
    """
    als = ALS(als_id)
    n = als.read()
    print("\n%d" % n)	
    assert user_answer_yes("Is a reading between 0-255 displayed?")
    input("Dim light by placing palm over the ALS sensor and hit enter")
    n = als.read()
    print("%d" % n)
    assert user_answer_yes("Is the lower reading displayed?")
    _flush_iops()