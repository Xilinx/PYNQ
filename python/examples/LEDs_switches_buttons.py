from pyxi.board import LED, Switch, Button

MAX_LEDS = 4
MAX_SWITCHES = 4
MAX_BUTTONS = 4

# Create lists for each of the IO component groups
leds = [LED(i) for i in range(MAX_LEDS)]
switches = [Switch(i) for i in range(MAX_SWITCHES)]
buttons = [Button(i) for i in range(MAX_BUTTONS)]

# LEDs start in the off state
for led in leds:
    led.off()

# if a slide-switch is on, light the corresponding LED
for i, switch in enumerate(switches):
    if switch.read():
        leds[i].on()
    else:
        leds[i].off()

# if a button is depressed, toggle the state of the corresponding LED
for i, button in enumerate(buttons):
    if button.read():
        leds[i].toggle()

