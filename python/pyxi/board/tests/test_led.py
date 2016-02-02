"""Test module for led.py"""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.tests import unittest
from pyxi.board import LED
from time import sleep


class TestLED(unittest.TestCase):
    """TestCase for the LED class and its wrapper functions."""

    def __init__(self):
        #bring all leds to a known state
        for i in range(4):
            LED(i).off()
    
    def test_0_led0(self):
        """Instantiates a LED object on index 0 and performs some actions 
        on it to test LED's API, requesting user confirmation."""     
        led = LED(0)
        led.on()
        self.assertEqual(led.read(),1) 
        self.assertUserAnswersYes("\nOnboard LED 0 on?")
        led.off()
        self.assertEqual(led.read(),0) 
        self.assertUserAnswersYes("Onboard LED 0 off?")
        led.toggle()
        self.assertEqual(led.read(),1) 
        self.assertUserAnswersYes("Onboard LED 0 on again?")
        led.write(0)
        self.assertEqual(led.read(),0) 
        self.assertUserAnswersYes("Onboard LED 0 off again?")
        led.write(1)
        self.assertEqual(led.read(),1) 
        led.off()
        
    def test_1_toggle_leds(self):
        """Instantiates 4 LED objects and toggles them.""" 
        leds = [LED(index) for index in range(0, 4)] 
        
        print("\nToggling onboard LEDs.")
        for i in range(4):
            leds[i].write(i % 2  )
        for i in range(10):
            for led in leds:
                led.toggle()
            sleep(0.1)
        for led in leds:
            led.off()
        self.assertUserAnswersYes("Seen LEDs toggling?")

def test_led():
    unittest.main(__name__) 

if __name__ == "__main__":
    test_led()