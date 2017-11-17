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


arduino_joystick_shield_PROGRAM = "arduino_ardumoto.bin"
CONFIG_IOP_SWITCH = 0x1
CONFIGURE = 0x3
RECONFIGURE_DIR = 0x5
SET_DIRECTION = 0x7
SET_SPEED = 0x9
RUN  = 0xB
STOP = 0xD

class Arduino_Ardumoto(object):
    """This class controls the Arduino Ardumoto. 
    
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
        """Return a new instance of an arduino_ardumoto_shield object. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
	"""

        self.microblaze = Arduino(mb_info, arduino_joystick_shield_PROGRAM)
        self.defaultpins = 0
        self.alternatepins = 1
        self.pol_default = 0
        self.pol_reverse = 1
        self.motorA = 0
        self.motorB = 1
        self.forward = 0
        self.backward = 1
        # Write configuration and wait for ACK

        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

    def configure_pins(self, pin_comb):
        """Switch the pins connected to the L298 between two available alternatives:
	1) pin 2 - Direction control for motor A
	   pin 3 - PWM control (speed) for motor A
	   pin 4 - Direction control for motor B
	   pin 11 - PWM control (speed) for motor B

	2) pin 8 - Direction control for motor A
	   pin 9 - PWM control (speed) for motor A
	   pin 7 - Direction control for motor B
	   pin 10 - PWM control (speed) for motor B

	Parameters
        ----------
        pin_comb : int
	0 - defaultpins = Default Configuration (2,3,4,11)
	1 - alternatepins = Alternate Configuration (8,9,7,10)
    
        Returns
        -------
        none    
        """
        self.microblaze.write_mailbox(0, pin_comb)
        self.microblaze.write_blocking_command(CONFIGURE)

    def configure_polarity(self, mot, polarity):
        """Direction of rotation of motor depends on the polarity connected to the battery.
	   user should set the Clockwise and counter-clockwise definitions, Depending on how the motor is wired.

	Parameters
        ----------
        sense : int
	0 - pol_default = FORWARD - Clockwise
	1 - pol_reverse = REVERSE - Clockwise
    
        Returns
        -------
        none    
        """
        self.microblaze.write_mailbox(0, mot)
        self.microblaze.write_mailbox(0x4, polarity)
        self.microblaze.write_blocking_command(RECONFIGURE_DIR)


    def set_dir(self, mot, direction):
        """Set the direction of rotation for specific motor

	Parameters
        ----------
        mot : int
	0 : motorA- Motor A (connected to (2,3) or (8,9))
	1 : motorB- Motor B (connected to (4,11) or (7,10))

	direction : int
	0 - forward : Run FORWARD
	1 - backward : Run REVERSE
    
        Returns
        -------
        none    
        """
        self.microblaze.write_mailbox(0, mot)
        self.microblaze.write_mailbox(0x4, direction)
        self.microblaze.write_blocking_command(SET_DIRECTION)

        return self.microblaze.read_mailbox(0)

    def set_speed(self, mot, speed):
        """Set the speed of rotation for specific motor

	Parameters
        ----------
        mot : int
	0 - Motor A (connected to (2,3) or (8,9))
	1 - Motor B (connected to (4,11) or (7,10))

	speed : int
	PWM duty to be configured for the motor specified 
	ramge from 1 - 99
    
        Returns
        -------
        none    
        """
        self.microblaze.write_mailbox(0, mot)
        self.microblaze.write_mailbox(0x4, speed)
        self.microblaze.write_blocking_command(SET_SPEED)

        return self.microblaze.read_mailbox(0)

    def run(self, mot):
        """Run the motor at the set speed and direction

	Parameters
        ----------
        mot : int
	0 - Motor A (connected to (2,3) or (8,9))
	1 - Motor B (connected to (4,11) or (7,10))
    
        Returns
        -------
        none    
        """
        self.microblaze.write_mailbox(0, mot)
        self.microblaze.write_blocking_command(RUN)

        return self.microblaze.read_mailbox(0)

    def stop(self, mot):
        """Stop the specified motor

	Parameters
        ----------
        mot : int
	0 - Motor A (connected to (2,3) or (8,9))
	1 - Motor B (connected to (4,11) or (7,10))
    
        Returns
        -------
        none    
        """
        self.microblaze.write_mailbox(0, mot)
        self.microblaze.write_blocking_command(STOP)

        return self.microblaze.read_mailbox(0)

    
