#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import pytest
from pynq import Overlay
from pynq.lib.pmod import Pmod_TMP2
from pynq.lib.pmod import PMODA
from pynq.lib.pmod import PMODB
from pynq.tests.util import user_answer_yes
from pynq.tests.util import get_interface_id




try:
    _ = Overlay('base.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nPmod TMP2 attached to the board?")
if flag1:
    tmp2_id = eval(get_interface_id('Pmod TMP2', options=['PMODA', 'PMODB']))
flag = flag0 and flag1


@pytest.mark.skipif(not flag, 
                    reason="need Pmod TMP2 attached to the base overlay")
def test_read_temp():
    """Test for the TMP2 class.
    
    Reads the TMP2 and asks the user if the temperature is displayed.
    
    """
    Overlay('base.bit').download()
    tmp2 = Pmod_TMP2(tmp2_id)

    n = tmp2.read()
    print("\nCurrent temperature: {} C.".format(n))
    assert user_answer_yes("Reading in celsius displayed?")

    del tmp2


