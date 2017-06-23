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
from . import Pmod
from . import PMOD_GROVE_G3
from . import PMOD_GROVE_G4
from . import MAILBOX_OFFSET


__author__ = "Cathal McCabe"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


PMOD_GROVE_ADC_PROGRAM = "pmod_grove_adc.bin"
GROVE_ADC_LOG_START = MAILBOX_OFFSET+16
GROVE_ADC_LOG_END = GROVE_ADC_LOG_START+(1000*4)
CONFIG_IOP_SWITCH = 0x1
READ_RAW_DATA = 0x2
READ_VOLTAGE = 0x3
READ_AND_LOG_RAW_DATA = 0x4
READ_AND_LOG_VOLTAGE = 0x5
SET_LOW_LEVEL = 0x6
SET_HIGH_LEVEL = 0x7
SET_HYSTERESIS_LEVEL = 0x8
READ_LOWEST_LEVEL = 0x9
READ_HIGHEST_LEVEL = 0xA
READ_STATUS = 0xB
RESET_ADC = 0xC


def _reg2float(reg):
    """Converts 32-bit register value to floats in Python.

    Parameters
    ----------
    reg: int
        A 32-bit register value read from the mailbox.

    Returns
    -------
    float
        A float number translated from the register value.

    """
    s = struct.pack('>l', reg)
    return struct.unpack('>f', s)[0]


class Grove_ADC(object):
    """This class controls the Grove IIC ADC. 
    
    Grove ADC is a 12-bit precision ADC module based on ADC121C021. Hardware
    version: v1.2.
    
    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
    log_running : int
        The state of the log (0: stopped, 1: started).
    log_interval_ms : int
        Time in milliseconds between sampled reads.
        
    """
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Grove ADC object. 
        
        Note
        ----
        The parameter `gr_pin` is a list organized as [scl_pin, sda_pin].
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on pmod-grove adapter.
            
        """
        if gr_pin not in [PMOD_GROVE_G3,
                          PMOD_GROVE_G4]:
            raise ValueError("Group number can only be G3 - G4.")

        self.microblaze = Pmod(mb_info, PMOD_GROVE_ADC_PROGRAM)
        self.log_interval_ms = 1000
        self.log_running = 0
        
        self.microblaze.write_mailbox(0, gr_pin)
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

    def read_raw(self):
        """Read the ADC raw value from the Grove ADC peripheral.
        
        Returns
        -------
        int
            The raw value from the sensor.
        
        """
        self.microblaze.write_blocking_command(READ_RAW_DATA)
        value = self.microblaze.read_mailbox(0)
        return value

    def read(self):
        """Read the ADC voltage from the Grove ADC peripheral.
        
        Returns
        -------
        float
            The float value after translation.
        
        """
        self.microblaze.write_blocking_command(READ_VOLTAGE)
        value = self.microblaze.read_mailbox(0)
        return _reg2float(value)

    def set_log_interval_ms(self, log_interval_ms):
        """Set the length of the log for the Grove ADC peripheral.

        This method can set the time interval between two samples, so that 
        users can read out multiple values in a single log. 
        
        Parameters
        ----------
        log_interval_ms : int
            The time between two samples in milliseconds, for logging only.
            
        Returns
        -------
        None
        
        """
        if log_interval_ms < 0:
            raise ValueError("Time between samples should be no less than 0.")
        
        self.log_interval_ms = log_interval_ms
        self.microblaze.write_mailbox(0x4, log_interval_ms)

    def start_log_raw(self):
        """Start recording raw data in a log.
        
        This method will first call set_log_interval_ms() before sending the
        command.
            
        Returns
        -------
        None
        
        """
        self.log_running = 1
        self.set_log_interval_ms(self.log_interval_ms)
        self.microblaze.write_non_blocking_command(READ_AND_LOG_RAW_DATA)

    def start_log(self):
        """Start recording multiple voltage values (float) in a log.
        
        This method will first call set_log_interval_ms() before sending the
        command.
            
        Returns
        -------
        None
        
        """
        self.log_running = 1
        self.set_log_interval_ms(self.log_interval_ms)
        self.microblaze.write_non_blocking_command(READ_AND_LOG_VOLTAGE)
                        
    def stop_log_raw(self):
        """Stop recording the raw values in the log.

        Simply send the command 0xC to stop the log.

        Returns
        -------
        None
        
        """
        if self.log_running == 1:
            self.microblaze.write_non_blocking_command(RESET_ADC)
            self.log_running = 0
        else:
            raise RuntimeError("No grove ADC log running.")

    def stop_log(self):
        """Stop recording the voltage values in the log.

        Simply send the command 0xC to stop the log.

        Returns
        -------
        None
        
        """
        if self.log_running == 1:
            self.microblaze.write_non_blocking_command(RESET_ADC)
            self.log_running = 0
        else:
            raise RuntimeError("No grove ADC log running.")
        
    def get_log_raw(self):
        """Return list of logged raw samples.
            
        Returns
        -------
        list
            List of valid raw samples from the ADC sensor.
        
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
            readings += data
        else:
            num_words = int(ceil((PMOD_ALS_LOG_END - head_ptr) / 4))
            data = self.microblaze.read(head_ptr, num_words)
            readings += data

            num_words = int(ceil((tail_ptr - PMOD_ALS_LOG_START) / 4))
            data = self.microblaze.read(PMOD_ALS_LOG_START, num_words)
            readings += data
        return readings
        
    def get_log(self):
        """Return list of logged samples.
            
        Returns
        -------
        list
            List of valid voltage samples (floats) from the ADC sensor.
        
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
            readings += [float("{0:.4f}".format(_reg2float(i))) for i in data]
        else:
            num_words = int(ceil((GROVE_ADC_LOG_END - head_ptr) / 4))
            data = self.microblaze.read(head_ptr, num_words)
            readings += [float("{0:.4f}".format(_reg2float(i))) for i in data]

            num_words = int(ceil((tail_ptr - GROVE_ADC_LOG_START) / 4))
            data = self.microblaze.read(GROVE_ADC_LOG_START, num_words)
            readings += [float("{0:.4f}".format(_reg2float(i))) for i in data]
        return readings

    def reset(self):
        """Resets/initializes the ADC.
            
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(RESET_ADC)
