"""Test module for led8.py"""


__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi.tests import unittest
from pyxi.board.utils import delay

from pyxi.pmods.led8 import LED8

led_id = None

class TestLED(unittest.TestCase):
    """TestCase for the PMOD LED class."""
    def test_0_led0(self):
        """Instantiates a LED object on index 0 and performs some actions 
        on it, requesting user confirmation.""" 
        led = LED8(led_id,0)    
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
    
    def test_1_shift_leds(self):
        """Instantiates 8 LED objects and shifts from right to left.""" 
        DelaySec1 = 0.2
        leds = [LED8(led_id,index) for index in range(0, 8)] 
        
        for led in leds:
            led.off()
        
        for i in range(0,2):
            for led in leds:
                led.on()
                delay(DelaySec1)
            for led in leds:
                led.off()
                delay(DelaySec1)
        self.assertUserAnswersYes("\nLEDs on/off shifting from LD0 to LD7?")
    
    def test_2_toggle_leds(self):
        """Instantiates 8 LED objects and toggles them.""" 
        DelaySec2 = 0.25
        leds = [LED8(led_id,index) for index in range(0, 8)] 
        
        for led in leds:
            led.off()
        leds[0].on()
        leds[2].on()
        leds[4].on()
        leds[6].on()
        for i in range(0,10):
            for led in leds:
                led.toggle()
            delay(DelaySec2)
        for led in leds:
            led.off()
        self.assertUserAnswersYes("\nSeen PMOD LEDs toggling?")

def test_led8():
    if not unittest.request_user_confirmation(
            'Is LED8 attached to the board?'):
        raise unittest.SkipTest()

    global led_id
    led_id = int(input("Type in the PMOD ID of the LED8 (1 ~ 4): "))
    
    # starting tests
    unittest.main(__name__) 
    
    # cleanup active_iops
    from pyxi.pmods._iop import _flush_iops
    _flush_iops()


if __name__ == "__main__":
    test_led8()
