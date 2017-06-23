#   Copyright (c) 2016, NECST Laboratory, Politecnico di Milano
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
from . import ARDUINO_GROVE_I2C
from . import MAILBOX_OFFSET


__author__ = "Lorenzo Di Tucci, Marco Rabozzi, Giuseppe Natale"
__copyright__ = "Copyright 2016, NECST Laboratory, Politecnico di Milano"


ARDUINO_GROVE_TH02_PROGRAM = "arduino_grove_th02.bin"
GROVE_TH02_LOG_START = MAILBOX_OFFSET+16
GROVE_TH02_LOG_END = GROVE_TH02_LOG_START+(500*8)
CONFIG_IOP_SWITCH = 0x1
READ_DATA = 0x2
READ_AND_LOG_DATA = 0x3
STOP_LOG = 0xC


class Grove_TH02(object):
    """This class controls the Grove I2C Temperature and Humidity sensor. 
    
    Temperature & humidity sensor (high-accuracy & mini).
    Hardware version: v1.0.
    
    Attributes
    ----------
    microblaze : Arduino
        Microblaze processor instance used by this module.
    log_running : int
        The state of the log (0: stopped, 1: started).
    log_interval_ms : int
        Time in milliseconds between sampled reads.
        
    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Grove_TH02 object. 
                
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

        self.microblaze = Arduino(mb_info, ARDUINO_GROVE_TH02_PROGRAM)
        self.log_interval_ms = 1000
        self.log_running = 0

        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

    def read(self):
        """Read the temperature and humidity values from the TH02 peripheral.

        Returns
        -------
        tuple
            Tuple containing (temperature, humidity)

        """
        self.microblaze.write_blocking_command(READ_DATA)
        [tmp, humidity] = self.microblaze.read_mailbox(0, 2)
        tmp = tmp / 32 - 50
        humidity = humidity / 16 - 24
        return tmp, humidity

    def start_log(self, log_interval_ms=100):
        """Start recording multiple heart rate values in a log.

        This method will first call set the log interval before sending
        the command.

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

        Simply send the command 0xC to stop the log.

        Returns
        -------
        None

        """
        if self.log_running == 1:
            self.microblaze.write_non_blocking_command(STOP_LOG)
            self.log_running = 0
        else:
            raise RuntimeError("No grove TH02 log running.")

    def get_log(self):
        """Return list of logged samples.

        Returns
        -------
        list
            List of tuples containing (temperature, humidity)

        """
        # stop logging
        self.stop_log()

        # Prep iterators and results list
        [head_ptr, tail_ptr] = self.microblaze.read_mailbox(0x8, 2)
        readings = list()

        # sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            for i in range(head_ptr, tail_ptr, 8):
                [temp, humid] = self.microblaze.read_mailbox(i, 2)
                temp = temp / 32 - 50
                humid = humid / 16 - 24
                readings.append((temp, humid))
        else:
            for i in range(head_ptr, GROVE_TH02_LOG_END, 8):
                [temp, humid] = self.microblaze.read_mailbox(i, 2)
                temp = temp / 32 - 50
                humid = humid / 16 - 24
                readings.append((temp, humid))
            for i in range(GROVE_TH02_LOG_END, tail_ptr, 8):
                [temp, humid] = self.microblaze.read_mailbox(i, 2)
                temp = temp / 32 - 50
                humid = humid / 16 - 24
                readings.append((temp, humid))
        return readings
