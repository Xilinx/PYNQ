#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import pytest
from pynq import Overlay
from pynq.lib.pmod import Pmod_OLED
from pynq.lib.pmod import PMODA
from pynq.lib.pmod import PMODB
from pynq.tests.util import user_answer_yes
from pynq.tests.util import get_interface_id




try:
    _ = Overlay('base.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nPmod OLED attached to the board?")
if flag1:
    oled_id = eval(get_interface_id('Pmod OLED', options=['PMODA', 'PMODB']))
flag = flag0 and flag1


@pytest.mark.skipif(not flag, 
                    reason="need OLED attached to the base overlay")
def test_write_string():
    """Test for the OLED Pmod.
    
    Writes on the OLED the string 'Welcome to PYNQ.' and asks the user to 
    confirm if it is shown on the OLED. After that, it clears the screen. 
    This test can be skipped.
    
    """
    Overlay('base.bit').download()
    oled = Pmod_OLED(oled_id)

    oled.draw_line(0, 0, 255, 0)
    oled.draw_line(0, 2, 255, 2)
    oled.write('Welcome to PYNQ.', 0, 1)
    oled.draw_line(0, 20, 255, 20)
    oled.draw_line(0, 22, 255, 22)

    assert user_answer_yes("\nWelcome message shown on the OLED?")
    oled.clear()
    assert user_answer_yes("OLED screen clear now?")

    del oled


