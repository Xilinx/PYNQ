# Show IP package

This package runs a script on boot, allowing the user to get the board's IP address via a Grove OLED display.
This is especially useful for hackathons, etc., where many PYNQ boards are connected to the same network.

## How to use

  * After boot, wait until the LEDs flash and then turn off
  * Insert the Grove OLED module in PMODB via connector G3
  * Press BTN0
  * Read IP from OLED display

Note that there is a timeout of 5 minutes while waiting for the button press. This is to minimise any danger of having this script running in the background on subsequent boots.
