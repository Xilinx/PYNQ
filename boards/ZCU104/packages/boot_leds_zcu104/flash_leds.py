#! /usr/bin/env python3.6

from pynq import Overlay
from time import sleep

ol = Overlay('base.bit')
leds = ol.gpio_leds.channel1

for _ in range(8):
    leds[0:4].off()
    sleep(0.2)
    leds[0:4].on()
    sleep(0.2)
