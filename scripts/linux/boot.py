
from time import sleep
from pynq import PL
from pynq.board import RGBLED, LED

rgbleds = [RGBLED(i) for i in range(4,6)]
leds = [LED(i) for i in range(4)]

# Wait for PL server to come up
timeout=2
for i in range(timeout):
    try:
        PL.ip_dict
    except:
        sleep(1)

# Toggle board LEDs
for i in range (5):
    [l.on() for l in leds]
    [rgbled.on(1) for rgbled in rgbleds]
    sleep(.2)
    [l.off() for l in leds]
    [rgbled.off() for rgbled in rgbleds]
    sleep(.2)
    
