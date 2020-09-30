#!/bin/env python3.6

from time import sleep
from pynq.overlays.base import BaseOverlay

base = BaseOverlay("base.bit")

rgbleds = [base.rgbleds[i] for i in range(4, 6)]
leds = [base.leds[i] for i in range(4)]

# Toggle board LEDs leaving small LEDs lit
for i in range(8):
    [l.off() for l in leds]
    [rgbled.off() for rgbled in rgbleds]
    sleep(.2)
    [l.on() for l in leds]
    [rgbled.on(1) for rgbled in rgbleds]
    sleep(.2)

[rgbled.off() for rgbled in rgbleds]
