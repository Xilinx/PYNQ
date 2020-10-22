#! /usr/bin/env python3.6

# example #1 - WiFi connection at boot
#from pynq.lib import Wifi
#
#port = Wifi()
#port.connect('your_ssid', 'your_password', auto=True)

# example #2 - Change hostname
#import subprocess
#subprocess.call('pynq_hostname.sh aNewHostName'.split())

# example #3 - blink LEDs (PYNQ-Z1, PYNQ-Z2, ZCU104)
#from pynq import Overlay
#from time import sleep
#
#ol = Overlay('base.bit')
#leds = ol.leds
#
#for _ in range(8):
#    leds[0:4].off()
#    sleep(0.2)
#    leds[0:4].on()
#    sleep(0.2)

