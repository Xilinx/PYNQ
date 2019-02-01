
from . import Arduino
from . import ARDUINO_GROVE_I2C

__author__ = "CCHui,SWJTU"

ARDUINO_GROVE_GESTURE_PROGRAM = "arduino_grove_gesture.bin"

CONFIG_IOP_SWITCH = 0x1
GET_GESTURE = 0x3
SET_SPEED = 0x5
RESET = 0xF

LOWSPEED = 0x10
HIGHSPEED = 0x30

GESTURE_MAP = {0: "no-detection",
               1: "forward",
               2: "backward",
               3: "right",
               4: "left",
               5: "up",
               6: "down",
               7: "clockwise",
               8: "counter-clockwise",
               9: "wave"
               }


class Grove_Gesture(object):
    """This class controls the Grove IIC Gesture. 

    Grove IIC Gesture can detect nine gestures.

    Attributes
    ----------
    microblaze : Arduino
        Microblaze processor instance used by this module.

    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Grove Gesture object. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on arduino-grove shield.

        """
        if gr_pin not in [ARDUINO_GROVE_I2C]:
            raise ValueError("Group number can only be I2C.")

        self.microblaze = Arduino(mb_info, ARDUINO_GROVE_GESTURE_PROGRAM)
        self.reset()

    def reset(self):
        """Reset the sensors on Gesture.

        Returns
        -------
        None

        """
        self.microblaze.write_blocking_command(RESET)

    def read_raw_data(self):
        """Get the raw gesture value.

        Returns
        -------
        int
            The gesture value returned by the sensor directly.

        """
        self.microblaze.write_blocking_command(GET_GESTURE)
        value = self.microblaze.read_mailbox(0)
        return value

    def read_gesture(self):
        """Get the gesture.

        Returns
        -------
        int
            The gesture value.

        """
        return GESTURE_MAP[self.read_raw_data()]

    def set_speed(self, fps):
        """Select speed mode.

        Parameters
        ----------
        fps : int
            Can be 120 for far mode or 240 for near mode.
        
        Returns
        -------
        None

        """
        if fps == 120:
            self.microblaze.write_mailbox(0, LOWSPEED)
        elif fps == 240:
            self.microblaze.write_mailbox(0, HIGHSPEED)
        else:
            raise ValueError('Value of fps must be either 120 or 240.')

        self.microblaze.write_blocking_command(SET_SPEED)
