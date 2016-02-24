"""Test module for led.py"""


__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "yunq@xilinx.com"


import pytest
import sys, select, termios
from pyxi.board.led import LED
from pyxi.test.util import user_answer_yes
from time import sleep


@pytest.mark.run(order=5)
def test_led0():
    """Instantiates a LED object on index 0 and performs some actions 
    on it to test LED's API, requesting user confirmation."""     
    for i in range(4):
        LED(i).off()
    led = LED(0)
    led.on()
    assert led.read()==1 
    assert user_answer_yes("\nOnboard LED 0 on?")
    led.off()
    assert led.read()==0
    assert user_answer_yes("Onboard LED 0 off?")
    led.toggle()
    assert led.read()==1
    assert user_answer_yes("Onboard LED 0 on again?")
    led.write(0)
    assert led.read()==0
    assert user_answer_yes("Onboard LED 0 off again?")
    led.write(1)
    assert led.read()==1
    led.off()

@pytest.mark.run(order=6)
def test_toggle_leds():
    """Instantiates 4 LED objects and toggles them.""" 
    leds = [LED(index) for index in range(0, 4)] 
        
    print("\nToggling onboard LEDs. Press enter to stop toggling...", end="")
    for i in range(4):
        leds[i].write(i % 2)
    while True:
        for led in leds:
            led.toggle()
        sleep(0.1)
        if sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
            termios.tcflush(sys.stdin, termios.TCIOFLUSH)
            break

    for led in leds:
        led.off()
    assert user_answer_yes("LEDs were toggling?")
