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

__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


import sys
import select
import termios
from time import sleep
import pytest
from pynq import Overlay
from pynq.iop import PMODA
from pynq.iop import PMODB
from pynq.iop import Pmod_LED8
from pynq.tests.util import user_answer_yes
from pynq.tests.util import get_pmod_id

flag = user_answer_yes("\nPmod LED8 attached to the board?")
if flag:
    global led_id

    pmod_id = get_pmod_id('Pmod LED8')
    if pmod_id == 'A':
        led_id = PMODA
    elif pmod_id == 'B':
        led_id = PMODB
    else:
        raise ValueError("Please type in A or B.")

@pytest.mark.run(order=22)
@pytest.mark.skipif(not flag, reason="need LED8 attached in order to run")
def test_led0():
    """Test for a single LED8.
    
    Instantiates an LED8 object on index 0 and performs some actions 
    on it, requesting user confirmation.
    
    """
    global leds
    leds = [Pmod_LED8(led_id,index) for index in range(8)]
    
    led = leds[0]
    led.on()
    assert led.read() is 1
    assert user_answer_yes("\nPmod LED 0 on?")
    led.off()
    assert led.read() is 0
    assert user_answer_yes("Pmod LED 0 off?")
    led.toggle()
    assert led.read() is 1
    led.write(0)
    assert led.read() is 0
    led.write(1)
    assert led.read() is 1
    led.off()

@pytest.mark.run(order=23) 
@pytest.mark.skipif(not flag, reason="need LED8 attached in order to run") 
def test_shifts():
    """Test for all the LEDs on LED8.
    
    Instantiates 8 LED8 objects and shifts from right to left.
    
    """
    global leds
    
    for led in leds:
        led.off()
    
    print("\nShifting Pmod LEDs. Press enter to stop shifting...", end="")
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

@pytest.mark.run(order=24) 
@pytest.mark.skipif(not flag, reason="need LED8 attached in order to run")  
def test_toggle():
    """Test for all the LEDs on LED8.
    
    Instantiates 8 LED objects and toggles them. This test can be skipped.
    
    """
    global leds
    
    for led in leds:
        led.off()
    leds[0].on()
    leds[2].on()
    leds[4].on()
    leds[6].on()
    
    print("\nToggling Pmod LEDs. Press enter to stop toggling...", end="")
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
    