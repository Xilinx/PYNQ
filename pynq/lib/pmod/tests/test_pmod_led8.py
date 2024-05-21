#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import sys
import select
import termios
from time import sleep
import pytest
from pynq import Overlay
from pynq.lib.pmod import Pmod_LED8
from pynq.lib.pmod import PMODA
from pynq.lib.pmod import PMODB
from pynq.tests.util import user_answer_yes
from pynq.tests.util import get_interface_id




try:
    _ = Overlay('base.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nPmod LED8 attached to the board?")
if flag1:
    led_id = eval(get_interface_id('Pmod LED8', options=['PMODA', 'PMODB']))
flag = flag0 and flag1


@pytest.mark.skipif(not flag, 
                    reason="need Pmod LED8 attached to the base overlay")
def test_led8():
    """Test for the Pmod LED8 module.

    There are 3 tests done here:

    1. Instantiate an LED8 object on index 0 and perform some actions 
    on it, requesting user confirmation.

    2. Instantiate 8 LED objects and shift from right to left.

    3. Toggles the states of the 8 LEDs.
    
    """
    Overlay('base.bit').download()
    leds = [Pmod_LED8(led_id, index) for index in range(8)]

    led = leds[0]
    led.on()
    assert led.read() == 1
    assert user_answer_yes("\nPmod LED 0 on?")
    led.off()
    assert led.read() == 0
    assert user_answer_yes("Pmod LED 0 off?")
    led.toggle()
    assert led.read() == 1
    led.write(0)
    assert led.read() == 0
    led.write(1)
    assert led.read() == 1
    led.off()
    for led in leds:
        led.off()
    
    print("Shifting LEDs on Pmod LED8.", end='')
    print("\nPress enter to stop shifting ...", end='')
    while True:
        for led in leds:
            led.on()
            sleep(0.1)
        for led in leds:
            led.off()
            sleep(0.1)
        if sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
            termios.tcflush(sys.stdin, termios.TCIOFLUSH)
            break
    assert user_answer_yes("Pmod LEDs were shifting from LD0 to LD7?")

    for led in leds:
        led.off()
    leds[0].on()
    leds[2].on()
    leds[4].on()
    leds[6].on()

    print("Toggling LEDs on Pmod LED8.", end='')
    print("\nPress enter to stop toggling ...", end='')
    while True:
        for led in leds:
            led.toggle()
        sleep(0.2)
        if sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
            termios.tcflush(sys.stdin, termios.TCIOFLUSH)
            break
    for led in leds:
        led.off()
    assert user_answer_yes("Pmod LEDs were toggling?")

    del leds


