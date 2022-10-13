#!/usr/local/share/pynq-venv/bin/python

from pynq.overlays.base import BaseOverlay
from time import sleep

ol = BaseOverlay('base.bit')
leds = ol.leds

for _ in range(8):
    leds[0:4].off()
    sleep(0.2)
    leds[0:4].on()
    sleep(0.2)
