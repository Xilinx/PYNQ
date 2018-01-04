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
from . import ARDUINO_GROVE_G1
from . import ARDUINO_GROVE_G2
from . import ARDUINO_GROVE_G3
from . import ARDUINO_GROVE_G4
from . import ARDUINO_GROVE_G5
from . import ARDUINO_GROVE_G6
from . import ARDUINO_GROVE_G7
from . import MAILBOX_OFFSET
from pynq import Clocks
from math import ceil

__author__ = "Vikhyat Goyal"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


ARDUINO_GROVE_USRANGER_PROGRAM = "arduino_grove_USranger.bin"
GROVE_USRANGER_LOG_START = MAILBOX_OFFSET+16
GROVE_USRANGER_LOG_END = GROVE_USRANGER_LOG_START+(1000*4)
CONFIG_IOP_SWITCH = 0x1
READ = 0x2
READ_AND_LOG_DATA = 0x3
STOP_LOG = 0xC


class Grove_USranger(object):
    """This class controls the Grove ultrasonic ranger. 
    
    This Grove - Ultrasonic sensor is a non-contact distance 
    measurement module which works at 42KHz
    
    Attributes
    ----------
    microblaze : Arduino
        Microblaze processor instance used by this module.
        
    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Grove ultrasonic ranger. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on arduino-grove shield.

        """
        self.clk_period_ns = int(1000 / Clocks.fclk0_mhz);

        if gr_pin not in [ARDUINO_GROVE_G1,
                          ARDUINO_GROVE_G2,
                          ARDUINO_GROVE_G3,
                          ARDUINO_GROVE_G4,
                          ARDUINO_GROVE_G5,
                          ARDUINO_GROVE_G6,
                          ARDUINO_GROVE_G7]:
        	raise ValueError("Group number can only be G1 - G7.")

        self.microblaze = Arduino(mb_info, ARDUINO_GROVE_USRANGER_PROGRAM)
        self.USrangerpin = gr_pin;
        print (self.USrangerpin);
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

    def read_distance_cm(self):
        """enables the US ranger to get a single measurment of distance.

        A 10usec initiate signal is send to the sensor, 
	the sensor then outputs eight 40khz Ultrasonic signal and detects a echo back.
	
	The distance can be measured in terms of cm or inches.
	once the sensor distance measurment has been started, 
	the echo back pulse duration (in usec) can be convered into distance as below:

	distance(cm) = duration(usec)/58
	distance(inch) = duration(usec)/148

        Returns
        -------
        int
	   the distance in cm

        """
        self.microblaze.write_mailbox(0, self.USrangerpin)
        self.microblaze.write_blocking_command(READ)
        value = self.microblaze.read_mailbox(0)
        value = value * self.clk_period_ns*(0.001) #convert value to useconds
        if((value*0.001) > 30): #If more than 30msec take as no obstacle
          return (500)
        else:
          return (value/58)

    def read_distance_inch(self):
        """The distance can be measured in terms of cm or inches.
	once the sensor distance measurment has been started, 
	the echo back pulse duration (in usec) can be convered into distance as below:

	distance(cm) = duration(usec)/58
	distance(inch) = duration(usec)/148

        Returns
        -------
        int
	   the distance in inch

        """
        self.microblaze.write_mailbox(0, self.USrangerpin)
        self.microblaze.write_blocking_command(READ)
        value = self.microblaze.read_mailbox(0)
        value = value * self.clk_period_ns*(0.001) #convert value to useconds
        if ((value*0.001) > 30):#If more than 30msec take as no obstacle
         return (500)
        else :
         return (value/148)

    def start_log(self, log_interval_ms=100):
        """Start recording multiple distance readings in a log.

        This method will first call set the log interval before writing to
        the MMIO.

        Parameters
        ----------
        log_interval_ms : int
            The time between two samples in milliseconds.

        Returns
        -------
        None

        """
        if log_interval_ms < 0:
            raise ValueError("Time between samples cannot be less than zero.")

        self.log_running = 1
        self.log_interval_ms = log_interval_ms
        self.microblaze.write_mailbox(0x4, log_interval_ms)
        self.microblaze.write_non_blocking_command(READ_AND_LOG_DATA)

    def stop_log(self):
        """Stop recording the values in the log.

        Simply write 0xC to the MMIO to stop the log.

        Returns
        -------
        None

        """
        if self.log_running == 1:
            self.microblaze.write_non_blocking_command(STOP_LOG)
            self.log_running = 0
        else:
            raise RuntimeError("No US distance measurment log running.")

    def get_log_cm(self):
        """Return list of logged samples.

        Returns
        -------
        list
            List of integers containing the measured distance.

        """
        # Stop logging
        self.stop_log()

        # Prep iterators and results list
        [head_ptr, tail_ptr] = self.microblaze.read_mailbox(0x8, 2)
        readings = list()

        # Sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            num_words = int(ceil((tail_ptr - head_ptr) / 4))
            data = self.microblaze.read(head_ptr, num_words)
            for i in range(len(data)) :
              data[i] = (data[i]*0.01)/58
            readings += data
        else:
            num_words = int(ceil((GROVE_USRANGER_LOG_END - head_ptr) / 4))
            data = self.microblaze.read(head_ptr, num_words)
            print (data)
            for i in range(len(data)) :
              data[i] = (data[i]*0.01)/58
            readings += data

            num_words = int(ceil((tail_ptr - GROVE_USRANGER_LOG_START) / 4))
            data = self.microblaze.read(GROVE_USRANGER_LOG_START, num_words)
            print (data)
            for i in range(len(data)) :
              data[i] = (data[i]*0.01)/58
            readings += data
        return readings
