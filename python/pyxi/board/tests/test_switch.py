"""Test module for switch.py"""


__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "yunq@xilinx.com"


import pytest
from pyxi.board.switch import SWITCH
    
@pytest.mark.run(order=7)
def test_switch_all():
    """TestCase for the Switch class and its wrapper functions.
    Instantiates 4 Switch objects on index 0 ~ 3 and performs some 
    actions on it, requesting user confirmation.
    """ 
    print("\nSet all the 4 switches (SW0 ~ SW3) off (lower position).") 
    input("Then hit enter...")
    switches = [SWITCH(index) for index in range(0, 4)] 
    for index in range(4):
        assert switches[index].read()==0, \
            "Switch %d read wrong values." % index
    input("Now switch them on (upper position) and hit enter...")
    for index in range(4):
        assert switches[index].read()==1, \
            "Switch %d read wrong values." % index