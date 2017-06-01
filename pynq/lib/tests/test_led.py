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
from pynq.board import LED
from pynq.tests.util import user_answer_yes

__author__ = "Giuseppe Natale, Yun Rock Qu"
__copyright__ = "Copyright 2015, Xilinx"
__email__ = "pynq_support@xilinx.com"


@pytest.mark.run(order=5)
def test_leds_on():
    """Test for the LED class and its wrapper functions.
    
    Instantiates a LED object on index 0 and performs some actions 
    on it to test LED's API, requesting user confirmation.
    
    """
    leds = [LED(index) for index in range(4)]
    for led in leds:
        led.off()
        
    led = leds[0]
    led.on()
    assert led.read() == 1
    assert user_answer_yes("\nOnboard LED 0 on?")
    led.off()
    assert led.read() == 0
    assert user_answer_yes("Onboard LED 0 off?")
    led.toggle()
    assert led.read() == 1
    led.write(0)
    assert led.read() == 0
    led.write(1)
    assert led.read() == 1
    led.off()


@pytest.mark.run(order=6)
def test_leds_toggle():
    """Test for the LED class and its wrapper functions.
    
    Instantiates 4 LED objects and toggles them.
    
    """
    leds = [LED(index) for index in range(4)]
    
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
