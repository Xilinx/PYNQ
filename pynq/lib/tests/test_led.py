#   Copyright (c) 2016, Xilinx, Inc.
#   All rights reserved.
# 
#   Redistribution and use in source and binary forms, with or without 
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its 
#       contributors may be used to endorse or promote products derived from 
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


import sys
import select
import termios
from time import sleep
import pytest
from pynq import Overlay
from pynq.overlays.base import BaseOverlay
from pynq.tests.util import user_answer_yes


__author__ = "Giuseppe Natale, Yun Rock Qu"
__copyright__ = "Copyright 2015, Xilinx"
__email__ = "pynq_support@xilinx.com"


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
