#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import sys
import select
import termios
from time import sleep
import pytest
from pynq import Overlay
from pynq.overlays.base import BaseOverlay
from pynq.tests.util import user_answer_yes




try:
    ol = Overlay('base.bit', download=False)
    flag0 = True
except IOError:
    flag0 = False
flag1 = user_answer_yes("\nTest onboard LEDs?")
flag = flag0 and flag1


@pytest.mark.skipif(not flag, reason="need base overlay and onboard LEDs")
def test_leds_on_off():
    """Test for the LED class and its wrapper functions.

    Control the LED objects, requesting user confirmation.

    """
    base = BaseOverlay("base.bit")
    leds = base.leds
    for led in leds:
        led.off()

    led = leds[0]
    led.on()
    assert user_answer_yes("\nOnboard LED 0 on?")
    led.off()
    assert user_answer_yes("Onboard LED 0 off?")


@pytest.mark.skipif(not flag, reason="need base overlay and onboard buttons")
def test_leds_toggle():
    """Test for the LED class and its wrapper functions.

    Control the LED objects, requesting user confirmation.

    """
    base = BaseOverlay("base.bit")
    leds = base.leds
    
    print("\nToggling onboard LEDs. Press enter to stop toggling...", end='')
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
    assert user_answer_yes("LEDs toggling during the test?")


