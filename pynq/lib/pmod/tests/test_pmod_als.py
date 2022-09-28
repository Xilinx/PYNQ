#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import pytest
from time import sleep
from pynq import Overlay
from pynq.lib.pmod import Pmod_ALS
from pynq.lib.pmod import PMODA
from pynq.lib.pmod import PMODB
from pynq.tests.util import user_answer_yes
from pynq.tests.util import get_interface_id




try:
    _ = Overlay('base.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nPmod ALS attached to the board?")
if flag1:
    als_id = eval(get_interface_id('Pmod ALS', options=['PMODA', 'PMODB']))
flag = flag0 and flag1


@pytest.mark.skipif(not flag,
                    reason="need Pmod ALS attached to the base overlay")
def test_readlight():
    """Test for the ALS class.
    
    This test reads the ALS and asks the user to dim light manually. Then
    verify that a lower reading is displayed.
    
    """
    Overlay('base.bit').download()
    als = Pmod_ALS(als_id)
    
    # Wait for the Pmod ALS to finish initialization
    sleep(0.01)
    n = als.read()
    print("\nCurrent ALS reading: {}.".format(n))
    assert user_answer_yes("Is a reading between 0-255 displayed?")
    input("Dim light by placing palm over the ALS and hit enter...")
    n = als.read()
    print("Current ALS reading: {}.".format(n))
    assert user_answer_yes("Is a lower reading displayed?")
    
    del als


