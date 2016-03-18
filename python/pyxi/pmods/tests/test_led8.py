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
__email__       = "xpp_support@xilinx.com"


import sys
import select
import termios
from time import sleep
import pytest
from pyxi import Overlay
from pyxi.pmods.led8 import LED8
from pyxi.test.util import user_answer_yes

flag = user_answer_yes("\nLED8 attached to the board?")
if flag:
    global led_id
    led_id = int(input("Type in the PMOD ID of the LED8 (1 ~ 4): "))
    global ol
    ol = Overlay('pmod.bit')

@pytest.mark.run(order=21)
@pytest.mark.skipif(not flag, reason="need LED8 attached in order to run")
def test_led0():
    """Test for a single LED8.
    
    Instantiates an LED8 object on index 0 and performs some actions 
    on it, requesting user confirmation.
    
    """
    global leds
    leds = [LED8(led_id,index) for index in range(8)]
    
    led = leds[0]
    led.on()
    assert led.read() is 1
    assert user_answer_yes("\nPMOD LED 0 on?")
    led.off()
    assert led.read() is 0
    assert user_answer_yes("PMOD LED 0 off?")
    led.toggle()
    assert led.read() is 1
    led.write(0)
    assert led.read() is 0
    led.write(1)
    assert led.read() is 1
    led.off()

@pytest.mark.run(order=22) 
@pytest.mark.skipif(not flag, reason="need LED8 attached in order to run") 
def test_shift_leds():
    """Test for all the LEDs on LED8.
    
    Instantiates 8 LED8 objects and shifts from right to left.
    
    """
    global leds
    
    for led in leds:
        led.off()
    
    print("\nShifting PMOD LEDs. Press enter to stop shifting...", end="")
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

    assert user_answer_yes("PMOD LEDs were shifting from LD0 to LD7?")

@pytest.mark.run(order=23) 
@pytest.mark.skipif(not flag, reason="need LED8 attached in order to run")  
def test_toggle_leds():
    """Test for all the LEDs on LED8.
    
    Instantiates 8 LED objects and toggles them.
    
    """
    global leds
    
    for led in leds:
        led.off()
    leds[0].on()
    leds[2].on()
    leds[4].on()
    leds[6].on()
    
    print("\nToggling PMOD LEDs. Press enter to stop toggling...", end="")
    while True:
        for led in leds:
            led.toggle()
        sleep(0.2)
        if sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
            termios.tcflush(sys.stdin, termios.TCIOFLUSH)
            break
            
    for led in leds:
        led.off()
        
    assert user_answer_yes("PMOD LEDs were toggling?")
    
    del leds
    ol.flush_iop_dictionary()
