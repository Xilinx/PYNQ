#!/bin/env python3.6

from time import sleep
from pynq import PL
from pynq.lib import RGBLED, LED

# Wait for PL server to come up
timeout = 3
for i in range(timeout):
    try:
        PL.ip_dict
    except:
        sleep(1)

rgbleds = [RGBLED(i) for i in range(4, 6)]
leds = [LED(i) for i in range(4)]

# Toggle board LEDs leaving small LEDs lit
for i in range(8):
    [l.off() for l in leds]
    [rgbled.off() for rgbled in rgbleds]
    sleep(.2)
    [l.on() for l in leds]
    [rgbled.on(1) for rgbled in rgbleds]
    sleep(.2)

[rgbled.off() for rgbled in rgbleds]
