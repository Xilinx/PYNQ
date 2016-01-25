"""Test module for button.py"""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.tests import unittest
from pyxi.board.button import Button


class TestButton(unittest.TestCase):
    """TestCase for the Button class and its wrapper functions."""
    
    def test_btn_all(self):
        """Instantiates 4 Button objects on index 0 ~ 3 and performs some 
        actions on it, requesting user confirmation."""
        buttons = [Button(index) for index in range(4)] 
        input("\nHit enter to continue...")
        for b in buttons:
            self.assertTrue(b.read() == 0)      
        for i in range(len(buttons)):           
            input("Hit enter while pressing Button {0} (BTN{0})...".format(i))
            self.assertTrue(buttons[i].read() == 1)

def test_button():
    unittest.main(__name__) 

if __name__ == "__main__":
    test_button()
