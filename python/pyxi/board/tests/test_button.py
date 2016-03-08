"""Test module for button.py"""


__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "yunq@xilinx.com"


import pytest
from pyxi.board.button import Button

@pytest.mark.run(order=8)
def test_btn_all():
    """TestCase for the Button class and its wrapper functions.
    Instantiates 4 Button objects on index 0 ~ 3 and performs some 
    actions on it, requesting user confirmation."""
    buttons = [Button(index) for index in range(0, 4)] 
    input("\nHit enter to continue...")
    for index in range(4):
        assert buttons[index].read()==0, \
            "Button %d read wrong values." % index
    for index in range(4):
        input("Hit enter while pressing Button {0} (BTN{0})...".format(index))
        assert buttons[index].read()==1, \
            "Button %d read wrong values." % index

