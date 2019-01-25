
from . import Arduino
from . import ARDUINO_GROVE_I2C

__author__ ="CCHui,SWJTU"

ARDUINO_GROVE_GESTURE_PROGRAM = "arduino_grove_gesture.bin"

CONFIG_IOP_SWITCH		=0x1
GET_GESTURE				=0x3
SET_SPEED				=0x5
RESET					=0xF

LOWSPEED                =0x10
HIGHSPEED               =0x30

Gesture ={  1:"forward",
            2:"backward",
            3:"right",
            4:"left",
            5:"up",
            6:"down",
            7:"clk_wise",
            8:"ant_clk_wise",
            9:"wave"
            }

class Grove_Gesture(object):
    """This class controls the Grove IIC Gesture. 
    
    Grove IIC Gesture has nine gestures.
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
        """Reset  the sensors on Gesture.
            
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(RESET)

    def read_gesture(self):
        """Get the gesture value.

        Returns
        -------
            The gesture value.

        """
        self.microblaze.write_blocking_command(GET_GESTURE)
        value = self.microblaze.read_mailbox(0)
        return value

    def set_speed(self,mode):
        """Select speed mode.

        Paramter:
            mode 0 :120ps far mode,
            mode 1 :240ps near mode.
        
        Returns
        -------
        None

        """
        if mode == 0:
            self.microblaze.write_mailbox(0,LOWSPEED)
        elif mode == 1:
            self.microblaze.write_mailbox(0,HIGHSPEED)
        else :
            return
        
        self.microblaze.write_blocking_command(SET_SPEED)
    
