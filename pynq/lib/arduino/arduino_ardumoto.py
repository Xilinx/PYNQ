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


from . import Arduino


__author__ = "Vikhyat Goyal"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


ARDUINO_ARDUMOTO_PROGRAM = "arduino_ardumoto.bin"
CONFIG_IOP_SWITCH = 0x1
CONFIGURE_PIN = 0x3
CONFIGURE_POLAR = 0x5
SET_DIRECTION = 0x7
SET_SPEED = 0x9
RUN = 0xB
STOP = 0xD


class Arduino_Ardumoto(object):
    """This class controls the Arduino Ardumoto. 

    The Ardumoto shield can be purchased at:
    https://www.sparkfun.com/products/14180?_ga=2.131154063.1683239815.\
    1506444499-1487919484.1504886094
    Ardumoto supports two DC motor driving.

    Hook up instructions can be found at https://learn.sparkfun.com/tutorials/\
    ardumoto-kit-hookup-guide?_ga=2.147685681.768736901.1523039274-1762361132.\
    1512080817

    Attributes
    ----------
    microblaze : Arduino
        Microblaze processor instance used by this module.
    pin_config : int
        Pin configuration, can be PIN_DEFAULT(0) or PIN_ALTERNATIVE(1).
    motor_a : dict
        Dictionary storing the direction and speed information for motor A.
    motor_b : dict
        Dictionary storing the direction and speed information for motor B.

    """
    def __init__(self, mb_info):
        """Return a new instance of an arduino_ardumoto_shield object. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.

        """
        # constants
        self.MOTOR_A = 0
        self.MOTOR_B = 1
        self.PIN_DEFAULT = 0
        self.PIN_ALTERNATIVE = 1
        self.POLAR_DEFAULT = 0
        self.POLAR_REVERSE = 1
        self.FORWARD = 0
        self.BACKWARD = 1

        # instantiation
        self.microblaze = Arduino(mb_info, ARDUINO_ARDUMOTO_PROGRAM)
        self.pin_config = self.PIN_DEFAULT
        self.motor_a = {'status': 'stopped',
                        'polarity': self.POLAR_DEFAULT,
                        'direction': self.FORWARD,
                        'speed': 1}
        self.motor_b = {'status': 'stopped',
                        'polarity': self.POLAR_DEFAULT,
                        'direction': self.FORWARD,
                        'speed': 1}

        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)
        self.configure_pin(self.PIN_DEFAULT)
        self.configure_polarity(self.MOTOR_A, self.POLAR_DEFAULT)
        self.configure_polarity(self.MOTOR_B, self.POLAR_DEFAULT)

    def configure_pin(self, configuration):
        """Switch the pin configurations.

        This method switch the pin configurations connected to the L298 between
        two available alternatives:

        (1) Default:
        pin 2 - Direction control for motor A;
        pin 3 - PWM control (speed) for motor A;
        pin 4 - Direction control for motor B;
        pin 11 - PWM control (speed) for motor B;

        (2) Alternative:
        pin 8 - Direction control for motor A;
        pin 9 - PWM control (speed) for motor A;
        pin 7 - Direction control for motor B;
        pin 10 - PWM control (speed) for motor B;

        Parameters
        ----------
        configuration : int
            Can be PIN_DEFAULT(0) or PIN_ALTERNATIVE(1).

        """
        if configuration not in [self.PIN_DEFAULT, self.PIN_ALTERNATIVE]:
            raise ValueError("Configuration must be {} or {}.".format(
                self.PIN_DEFAULT, self.PIN_ALTERNATIVE))
        self.pin_config = configuration
        self.microblaze.write_mailbox(0, configuration)
        self.microblaze.write_blocking_command(CONFIGURE_PIN)

    def configure_polarity(self, motor, polarity):
        """Set direction of rotation of motor.

        This may depend on the way the motor is connected to the shield.
        User should set the clockwise and counter-clockwise definitions,
        depending on how the motor is wired to the shield.

        Parameters
        ----------
        motor : int
            Can be MOTOR_A(0) or MOTOR_B(1).
        polarity : int
            Can be POLAR_DEFAULT(0) or POLAR_REVERSE(1).

        """
        if motor not in [self.MOTOR_A, self.MOTOR_B]:
            raise ValueError('Motor index can only be {} or {}.'.format(
                self.MOTOR_A, self.MOTOR_B))
        if polarity not in [self.POLAR_DEFAULT, self.POLAR_REVERSE]:
            raise ValueError('Motor polarity can only be {} or {}.'.format(
                self.POLAR_DEFAULT, self.POLAR_REVERSE))
        self.microblaze.write_mailbox(0, motor)
        self.microblaze.write_mailbox(0x4, polarity)
        self.microblaze.write_blocking_command(CONFIGURE_POLAR)
        if motor == self.MOTOR_A:
            self.motor_a['polarity'] = polarity
        else:
            self.motor_b['polarity'] = polarity

    def set_direction(self, motor, direction):
        """Set the direction of rotation for specific motor.

        Motor A is the motor connected to pin pair (2,3) or (8,9).
        Motor B is the motor connected to pin pair (4,11) or (7,10).

        Parameters
        ----------
        motor : int
            Can be MOTOR_A(0) or MOTOR_B(1).
        direction : int
            Can be FORWARD(0) or BACKWARD(1).

        """
        if motor not in [self.MOTOR_A, self.MOTOR_B]:
            raise ValueError('Motor index can only be {} or {}.'.format(
                self.MOTOR_A, self.MOTOR_B))
        if direction not in [self.FORWARD, self.BACKWARD]:
            raise ValueError('Motor direction can only be {} or {}.'.format(
                self.FORWARD, self.BACKWARD))
        self.microblaze.write_mailbox(0, motor)
        self.microblaze.write_mailbox(0x4, direction)
        self.microblaze.write_blocking_command(SET_DIRECTION)
        if motor == self.MOTOR_A:
            self.motor_a['direction'] = direction
        else:
            self.motor_b['direction'] = direction

    def set_speed(self, motor, speed):
        """Set the speed of rotation for specific motor.

        Motor A is the motor connected to pin pair (2,3) or (8,9).
        Motor B is the motor connected to pin pair (4,11) or (7,10).

        Parameters
        ----------
        motor : int
            Can be MOTOR_A(0) or MOTOR_B(1).
        speed : int
            PWM duty cycle for the motor specified, ranging from 1 - 99.

        """
        if motor not in [self.MOTOR_A, self.MOTOR_B]:
            raise ValueError('Motor index can only be {} or {}.'.format(
                self.MOTOR_A, self.MOTOR_B))
        if speed not in range(1, 100):
            raise ValueError('Motor speed must be in range [1, 99].')
        self.microblaze.write_mailbox(0, motor)
        self.microblaze.write_mailbox(0x4, speed)
        self.microblaze.write_blocking_command(SET_SPEED)
        if motor == self.MOTOR_A:
            self.motor_a['speed'] = speed
        else:
            self.motor_b['speed'] = speed

    def run(self, motor):
        """Run the motor at the set speed and direction.

        Motor A is the motor connected to pin pair (2,3) or (8,9).
        Motor B is the motor connected to pin pair (4,11) or (7,10).

        Parameters
        ----------
        motor : int
            Can be MOTOR_A(0) or MOTOR_B(1).

        """
        self.microblaze.write_mailbox(0, motor)
        self.microblaze.write_blocking_command(RUN)
        if motor == self.MOTOR_A:
            self.motor_a['status'] = 'running'
        else:
            self.motor_b['status'] = 'running'

    def stop(self, motor):
        """Stop the specified motor.

        Motor A is the motor connected to pin pair (2,3) or (8,9).
        Motor B is the motor connected to pin pair (4,11) or (7,10).

        Parameters
        ----------
        motor : int
            Can be MOTOR_A(0) or MOTOR_B(1).

        """
        self.microblaze.write_mailbox(0, motor)
        self.microblaze.write_blocking_command(STOP)
        if motor == self.MOTOR_A:
            self.motor_a['status'] = 'stopped'
        else:
            self.motor_b['status'] = 'stopped'
