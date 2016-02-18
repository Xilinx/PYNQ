"""Test module for oled.py"""


__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


import pytest
from pyxi.pmods._iop import _flush_iops
from pyxi.pmods.oled import OLED
from pyxi.test.util import user_answer_yes

flag = user_answer_yes("\nOLED attached to the board?")
if flag:
    global oled_id
    oled_id = int(input("Type in the PMOD ID of the OLED (1 ~ 4): "))

@pytest.mark.run(order=20)
@pytest.mark.skipif(not flag, reason="need OLED attached in order to run")
def test_write_string():
    """TestCase for the OLED class.
    Just writes on the OLED the string 'TEST' and asks the user to 
    confirm if it is shown on the OLED. After that, it clears the screen 
    and asks again for user confirmation.
    """
    oled = OLED(oled_id)
    oled.write('Welcome to Zybo.')
    assert user_answer_yes("\nWelcome message shown on the OLED?")
    oled.clear_screen()
    assert user_answer_yes("OLED screen clear now?")      
    _flush_iops()
