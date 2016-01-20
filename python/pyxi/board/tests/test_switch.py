"""Test module for switch.py"""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.tests import unittest
from pyxi.board import Switch


class TestSwitch(unittest.TestCase):
    """TestCase for the Switch class and its wrapper functions."""

    def test_switch_all(self):
        """Instantiates 4 Switch objects on index 0 ~ 3 and performs some 
        actions on it, requesting user confirmation.
        """
        switches = [Switch(index) for index in range(4)] 
        print("\nSet all the 4 switches (SW0 ~ SW3) off (lower position).") 
        input("Then hit enter...")
        for s in switches:
            self.assertTrue(s() is 0)
        input("Now switch them on (upper position) and hit enter...")
        for s in switches:
            self.assertTrue(s() is 1)

def test_switch():
    unittest.main(__name__) 

if __name__ == "__main__":
    test_switch()