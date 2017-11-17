#   Copyright (c) 2016, Xilinx, Inc.
#   All rights reserved.
# 
#   Redistribution and use in source and binary forms, with or without 
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its 
#       contributors may be used to endorse or promote products derived from 
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


import struct
from math import ceil
from . import Arduino
from . import MAILBOX_OFFSET
from . import ARDUINO_NUM_ANALOG_PINS


__author__ = "Vikhyat Goyal"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


arduino_joystick_shield_PROGRAM = "arduino_joystick_shield.bin"
CONFIG_IOP_SWITCH = 0x1
GET_RAW_DATA_X = 0x3
GET_RAW_DATA_Y = 0x5
GET_DIRECTION  = 0x7
GET_BUTTONS = 0x9

class Arduino_joystick(object):
    """This class controls the Arduino Analog. 
    
    XADC is an internal analog controller in the hardware. This class
    provides API to do analog reads from IOP.
    
    Attributes
    ----------
    microblaze : Arduino
        Microblaze processor instance used by this module.
    log_running : int
        The state of the log (0: stopped, 1: started).
    log_interval_ms : int
        Time in milliseconds between samples on the same channel.
    gr_pin : list
        A group of pins on arduino-grove shield.
    num_channels : int
        The number of channels sampled.

    """
    def __init__(self, mb_info):
        """Return a new instance of an arduino_joystick_shield object. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
            
        """

        self.microblaze = Arduino(mb_info, arduino_joystick_shield_PROGRAM)
        self.log_interval_ms = 1000
        self.log_running = 0
        
        # Write configuration and wait for ACK
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

    def read_raw_x(self):
        """Read the analog raw value from the analog peripheral.
        
        Returns
        -------
        float
            The raw values from the analog device.
        
        """
        self.microblaze.write_blocking_command(GET_RAW_DATA_X)

        return self.microblaze.read_mailbox(0)

    def read_raw_y(self):
        """Read the analog raw value from the analog peripheral.
        
        Returns
        -------
        float
            The raw values from the analog device.
        
        """
        self.microblaze.write_blocking_command(GET_RAW_DATA_Y)

        return self.microblaze.read_mailbox(0)

    def read_direction(self):
        """Read the dirction of joysitck 
        
        Returns
        -------
        str
            The direction of the joystick
        
        """
        self.microblaze.write_blocking_command(GET_DIRECTION)

        return self.microblaze.read_mailbox(0)
     
    def read_buttons(self):
        """Read the analog raw value from the analog peripheral.
        
        Returns
        -------
        list
            The current value of buttons
        
        """
        self.microblaze.write_blocking_command(GET_BUTTONS)
        buttons = self.microblaze.read_mailbox(0,5)
        return buttons
