"""Test module for tmp2.py"""


__author__      = "Naveen Purushotham, Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Naveen Purushotham"
__email__       = "npurusho@xilinx.com"

import pytest
from pyxi.pmods.tmp2 import TMP2
from pyxi.pmods._iop import _flush_iops
from pyxi.test.util import user_answer_yes

flag = user_answer_yes("\nTMP2 attached to the board?")
if flag:
    global tmp2_id
    tmp2_id = int(input("Type in the PMOD ID of the TMP2 (1 ~ 4): "))

@pytest.mark.run(order=21)
@pytest.mark.skipif(not flag, reason="need TMP2 attached in order to run")
def test_readtemp():
    """TestCase for the TMP2 class.
    Reads the TMP2 and asks the user if the temperature is  displayed.
    After that, it asks the user to modify temperature and confirm change
    in reading is displayed.
    """
    tmp2 = TMP2(tmp2_id)
    n = tmp2.read()
    print("\nCurrent temperature: {} C".format(n))
    assert user_answer_yes("Reading in celcius displayed?")
    _flush_iops()
