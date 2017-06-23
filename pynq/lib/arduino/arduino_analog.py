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


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


ARDUINO_ANALOG_PROGRAM = "arduino_analog.bin"
ARDUINO_ANALOG_LOG_START = MAILBOX_OFFSET+16
ARDUINO_ANALOG_SAMPLES = 1000
CONFIG_IOP_SWITCH = 0x1
GET_RAW_DATA = 0x3
GET_VOLTAGE = 0x5
READ_AND_LOG_RAW = 0x7
READ_AND_LOG_FLOAT = 0x9
RESET_ANALOG = 0xB


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


class Arduino_Analog(object):
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
    def __init__(self, mb_info, gr_pin):
        """Return a new instance of an Arduino_Analog object. 
        
        Note
        ----
        The parameter `gr_pin` is a list of analog pins enabled.
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        gr_pin: list
            A group of pins on arduino-grove shield.
            
        """
        for pin in gr_pin:
            if pin not in range(ARDUINO_NUM_ANALOG_PINS):
                raise ValueError("Analog pin number can only be 0 - {}."
                                 .format(ARDUINO_NUM_ANALOG_PINS-1))

        self.microblaze = Arduino(mb_info, ARDUINO_ANALOG_PROGRAM)
        self.log_interval_ms = 1000
        self.log_running = 0
        self.gr_pin = gr_pin
        self.num_channels = len(gr_pin)

        # Enable all the analog pins
        data = [0 for _ in range(ARDUINO_NUM_ANALOG_PINS)]
        self.microblaze.write_mailbox(0, data)
        
        # Write configuration and wait for ACK
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

    def read_raw(self):
        """Read the analog raw value from the analog peripheral.
        
        Returns
        -------
        list
            The raw values from the analog device.
        
        """
        data_channels = 0
        for channel in self.gr_pin:
            data_channels |= (0x1 << channel)
        cmd = (data_channels << 8) + GET_RAW_DATA
        self.microblaze.write_blocking_command(cmd)

        return self.microblaze.read_mailbox(0, self.num_channels)
        
    def read(self):
        """Read the voltage value from the analog peripheral.
        
        Returns
        -------
        list
            The float values after translation.
        
        """
        data_channels = 0
        for channel in self.gr_pin:
            data_channels |= (0x1 << channel)
        cmd = (data_channels << 8) + GET_VOLTAGE
        self.microblaze.write_blocking_command(cmd)

        raw = self.microblaze.read_mailbox(0, self.num_channels)
        return [float("{0:.4f}".format(_reg2float(i))) for i in raw]
        
    def set_log_interval_ms(self, log_interval_ms):
        """Set the length of the log for the analog peripheral.
        
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
        self.microblaze.write_mailbox(4, log_interval_ms)

    def start_log_raw(self):
        """Start recording raw data in a log.
        
        This method will first call set_log_interval_ms() before writing to
        the MMIO.
            
        Returns
        -------
        None
        
        """
        self.log_running = 1
        self.set_log_interval_ms(self.log_interval_ms)

        data_channels = 0
        for channel in self.gr_pin:
            data_channels |= (0x1 << channel)
        cmd = (data_channels << 8) + READ_AND_LOG_RAW
        self.microblaze.write_non_blocking_command(cmd)
                        
    def start_log(self):
        """Start recording multiple voltage values (float) in a log.
        
        This method will first call set_log_interval_ms() before writing to
        the MMIO.
            
        Returns
        -------
        None
        
        """
        self.log_running = 1
        self.set_log_interval_ms(self.log_interval_ms)
        
        data_channels = 0
        for channel in self.gr_pin:
            data_channels |= (0x1 << channel)
        cmd = (data_channels << 8) + READ_AND_LOG_FLOAT
        self.microblaze.write_non_blocking_command(cmd)

    def stop_log_raw(self):
        """Stop recording the raw values in the log.
        
        Simply write 0xC to the MMIO to stop the log.
            
        Returns
        -------
        None
        
        """
        if self.log_running == 1:
            self.microblaze.write_non_blocking_command(RESET_ANALOG)
            self.log_running = 0
        else:
            raise RuntimeError("No analog log running.")
            
    def stop_log(self):
        """Stop recording the voltage values in the log.
        
        This can be done by calling the stop_log_raw() method.
            
        Returns
        -------
        None
        
        """
        if self.log_running == 1:
            self.microblaze.write_non_blocking_command(RESET_ANALOG)
            self.log_running = 0
        else:
            raise RuntimeError("No analog log running.")
        
    def get_log_raw(self):
        """Return list of logged raw samples.
            
        Returns
        -------
        list
            List of valid raw samples from the analog device.
        
        """
        # Stop logging
        self.stop_log()

        # Prep iterators and results list
        [head_ptr, tail_ptr] = self.microblaze.read_mailbox(0x8, 2)
        readings = []
        for _ in range(self.num_channels):
            readings.append([])

        # Calculate the log ending
        log_end = ARDUINO_ANALOG_LOG_START + \
            4*ARDUINO_ANALOG_SAMPLES*self.num_channels

        # Sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            for i in range(head_ptr, tail_ptr, 4*self.num_channels):
                raw = self.microblaze.read(i, self.num_channels)
                for j in range(self.num_channels):
                    readings[j].append(raw[j])
        else:
            for i in range(head_ptr, log_end, 4*self.num_channels):
                raw = self.microblaze.read(i, self.num_channels)
                for j in range(self.num_channels):
                    readings[j].append(raw[j])

            for i in range(ARDUINO_ANALOG_LOG_START, tail_ptr,
                           4*self.num_channels):
                raw = self.microblaze.read(i, self.num_channels)
                for j in range(self.num_channels):
                    readings[j].append(raw[j])
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
        readings = []
        for _ in range(self.num_channels):
            readings.append([])
        
        # Calculate the log ending
        log_end = ARDUINO_ANALOG_LOG_START + \
            4*ARDUINO_ANALOG_SAMPLES*self.num_channels
        
        # Sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            for i in range(head_ptr, tail_ptr, 4*self.num_channels):
                raw = self.microblaze.read(i, self.num_channels)
                for j in range(self.num_channels):
                    readings[j].append(float("{0:.4f}".format(
                        _reg2float(raw[j]))))

        else:
            for i in range(head_ptr, log_end, 4*self.num_channels):
                raw = self.microblaze.read(i, self.num_channels)
                for j in range(self.num_channels):
                    readings[j].append(float("{0:.4f}".format(
                        _reg2float(raw[j]))))

            for i in range(ARDUINO_ANALOG_LOG_START, tail_ptr,
                           4*self.num_channels):
                raw = self.microblaze.read(i, self.num_channels)
                for j in range(self.num_channels):
                    readings[j].append(float("{0:.4f}".format(
                        _reg2float(raw[j]))))
        return readings
        
    def reset(self):
        """Resets the system monitor for analog devices.
            
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(RESET_ANALOG)
