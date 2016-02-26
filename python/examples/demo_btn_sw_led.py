"""Demo for switch + LED + Button."""

__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__maintainer__  = "Yun Rock Qu"
__email__       = "yunq@xilinx.com"

from pyxi.board.utils import delay
from pyxi.board.led import LED
from pyxi.board.switch import Switch
from pyxi.board.button import Button

def demo_btn_sw_led():
    """Demo of the buttons, switches, and LEDs.
    button 0 pressed:
        LEDs toggle
    button 1 pressed:
        LEDs shift from right to left.
    button 2 pressed:
        switch 0 on   -> LED 0 on 
        switch 1 on   -> LED 1 on
        switch 2 on   -> LED 2 on
        switch 3 on   -> LED 3 on
    button 3 pressed:
        End this demo
    """
    global DelaySec1, DelaySec2
    DelaySec1 = 0.5
    DelaySec2 = 0.25
    leds = [LED(index) for index in range(0, 4)] 
    btns = [Button(index) for index in range(0, 4)] 
    sws = [Switch(index) for index in range(0, 4)]
    
    print("\nLong-press Button 0 -> toggle LEDs")        
    print("Long-press Button 1 -> left-shift LEDs")        
    print("Long-press Button 2 -> switch-controlled LEDs")        
    print("Long-press Button 3 -> end this demo")
        
    for led in leds:
        led.off()    
    while (btns[3].read()==0):
        if (btns[0].read()==1):
            for led in leds:
                led.toggle()
            delay(DelaySec1)
            
        elif (btns[1].read()==1):
            for led in leds:
                led.off()
            delay(DelaySec2)
            for led in leds:
                led.toggle()
                delay(DelaySec2)
                
        elif (btns[2].read()==1):
            for i in range(0, 4):
                if (sws[i].read()==1):
                    leds[i].on()
                else:
                    leds[i].off()                  
    
    print('End of this demo ...')
    for led in leds:
        led.off() 

if __name__ == "__main__":
    demo_btn_sw_led()
