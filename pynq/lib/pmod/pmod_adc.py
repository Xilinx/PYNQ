#   Copyright (c) 2016-2020, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import struct
from math import ceil
from . import Pmod
from . import MAILBOX_OFFSET




PMOD_ADC_PROGRAM = "pmod_adc.bin"
PMOD_ADC_LOG_START = MAILBOX_OFFSET+16
PMOD_ADC_LOG_END = PMOD_ADC_LOG_START+(1008*4)
RESET_ADC = 0x1
READ_RAW_DATA = 0x3
READ_VOLTAGE = 0x5
READ_AND_LOG_RAW_DATA = 0x7
READ_AND_LOG_VOLTAGE = 0x9


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
    return round(struct.unpack('>f', s)[0], 4)


class Pmod_ADC(object):
    """This class controls an Analog to Digital Converter Pmod.
    
    The Pmod AD2 (PB 200-217) is an analog-to-digital converter powered by 
    AD7991. Users may configure up to 4 conversion channels at 12 bits of 
    resolution.
    
    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
    log_running : int
        The state of the log (0: stopped, 1: started).
        
    """

    def __init__(self, mb_info):
        """Return a new instance of an ADC object.
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.

        """
        self.microblaze = Pmod(mb_info, PMOD_ADC_PROGRAM)
        self.log_running = 0
    
    def reset(self):
        """Reset the ADC.
        
        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(RESET_ADC)

    def read_raw(self, ch1=1, ch2=0, ch3=0):
        """Get the raw value from the Pmod ADC.
        
        When ch1, ch2, and ch3 values are 1 then the corresponding channel
        is included. 
        
        For each channel selected, this method reads and returns one sample. 
        
                
        Note
        ----
        The 4th channel is not available due to the jumper (JP1) setting on 
        ADC.
        
        Note
        ----
        This method reads the raw value from ADC.
        
        Parameters
        ----------
        ch1 : int
            1 means include channel 1, 0 means do not include.
        ch2 : int
            1 means include channel 2, 0 means do not include.
        ch3 : int
            1 means include channel 3, 0 means do not include.
        
        Returns
        -------
        list
            The raw values read from the 3 channels of the Pmod ADC.

        """
        if ch1 not in range(2):
            raise ValueError("Valid value for ch1 is 0 or 1.")
        if ch2 not in range(2):
            raise ValueError("Valid value for ch2 is 0 or 1.")
        if ch3 not in range(2):
            raise ValueError("Valid value for ch3 is 0 or 1.")
        cmd = (ch3 << 6) | (ch2 << 5) | (ch1 << 4) | READ_RAW_DATA
       
        # Send the command
        self.microblaze.write_blocking_command(cmd)

        # Read the samples from ADC
        readings = self.microblaze.read_mailbox(0, 3)
        results = []
        if ch1:
            results.append(readings[0])
        if ch2:
            results.append(readings[1])
        if ch3:
            results.append(readings[2])
        return results

    def read(self, ch1=1, ch2=0, ch3=0):
        """Get the voltage from the Pmod ADC.
        
        When ch1, ch2, and ch3 values are 1 then the corresponding channel
        is included. 
        
        For each channel selected, this method reads and returns one sample. 
               
        Note
        ----
        The 4th channel is not available due to the jumper setting on ADC.
        
        Note
        ----
        This method reads the voltage values from ADC.
        
        Parameters
        ----------
        ch1 : int
            1 means include channel 1, 0 means do not include.
        ch2 : int
            1 means include channel 2, 0 means do not include.
        ch3 : int
            1 means include channel 3, 0 means do not include.
        
        Returns
        -------
        list
            The voltage values read from the 3 channels of the Pmod ADC.
        
        """
        if ch1 not in range(2):
            raise ValueError("Valid value for ch1 is 0 or 1.")
        if ch2 not in range(2):
            raise ValueError("Valid value for ch2 is 0 or 1.")
        if ch3 not in range(2):
            raise ValueError("Valid value for ch3 is 0 or 1.")
        cmd = (ch3 << 6) | (ch2 << 5) | (ch1 << 4) | READ_VOLTAGE
       
        # Send the command
        self.microblaze.write_blocking_command(cmd)

        # Read the last sample from ADC
        readings = self.microblaze.read_mailbox(0, 3)
        results = []
        if ch1:
            results.append(_reg2float(readings[0]))
        if ch2:
            results.append(_reg2float(readings[1]))
        if ch3:
            results.append(_reg2float(readings[2]))
        return results

    def start_log_raw(self, ch1=1, ch2=0, ch3=0, log_interval_us=100):
        """Start the log of raw values with the interval specified.
        
        This parameter `log_interval_us` can set the time interval between 
        two samples, so that users can read out multiple values in a single 
        log.  
        
        Parameters
        ----------
        ch1 : int
            1 means include channel 1, 0 means do not include.
        ch2 : int
            1 means include channel 2, 0 means do not include.
        ch3 : int
            1 means include channel 3, 0 means do not include.
        log_interval_us : int
            The length of the log in milliseconds, for debug only.
            
        Returns
        -------
        None
        
        """
        if log_interval_us < 0:
            raise ValueError("Time between samples should be no less than 0.")
        if ch1 not in range(2):
            raise ValueError("Valid value for ch1 is 0 or 1.")
        if ch2 not in range(2):
            raise ValueError("Valid value for ch2 is 0 or 1.")
        if ch3 not in range(2):
            raise ValueError("Valid value for ch3 is 0 or 1.")
        
        cmd = (ch3 << 6) | (ch2 << 5) | (ch1 << 4) | READ_AND_LOG_RAW_DATA
        self.log_running = 1
        
        # Send log interval
        self.microblaze.write_mailbox(0, log_interval_us)
        
        # Send the command
        self.microblaze.write_non_blocking_command(cmd)
        
    def start_log(self, ch1=1, ch2=0, ch3=0, log_interval_us=100):
        """Start the log of voltage values with the interval specified.
        
        This parameter `log_interval_us` can set the time interval between 
        two samples, so that users can read out multiple values in a single 
        log.  
        
        Parameters
        ----------
        ch1 : int
            1 means include channel 1, 0 means do not include.
        ch2 : int
            1 means include channel 2, 0 means do not include.
        ch3 : int
            1 means include channel 3, 0 means do not include.
        log_interval_us : int
            The length of the log in milliseconds, for debug only.
            
        Returns
        -------
        None
        
        """
        if log_interval_us < 0:
            raise ValueError("Time between samples should be no less than 0.")
        if ch1 not in range(2):
            raise ValueError("Valid value for ch1 is 0 or 1.")
        if ch2 not in range(2):
            raise ValueError("Valid value for ch2 is 0 or 1.")
        if ch3 not in range(2):
            raise ValueError("Valid value for ch3 is 0 or 1.")
        
        cmd = (ch3 << 6) | (ch2 << 5) | (ch1 << 4) | READ_AND_LOG_VOLTAGE
        
        self.log_running = 1

        # Send log interval
        self.microblaze.write_mailbox(0, log_interval_us)

        # Send the command
        self.microblaze.write_non_blocking_command(cmd)

    def stop_log_raw(self):
        """Stop the log of raw values.
        
        This is done by sending the reset command to IOP. There is no need to
        wait for the IOP.
        
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
        """Stop the log of voltage values.
        
        This is done by sending the reset command to IOP. There is no need to
        wait for the IOP.
        
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
        """Get the log of raw values.
        
        First stop the log before getting the log.
        
        Returns
        -------
        list
            List of raw samples from the ADC.
        
        """
        # Stop logging
        self.stop_log_raw()

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
            num_words = int(ceil((PMOD_ADC_LOG_END - head_ptr) / 4))
            data = self.microblaze.read(head_ptr, num_words)
            readings += data

            num_words = int(ceil((tail_ptr - PMOD_ADC_LOG_START) / 4))
            data = self.microblaze.read(PMOD_ADC_LOG_START, num_words)
            readings += data
        return readings
        
    def get_log(self):
        """Get the log of voltage values.
        
        First stop the log before getting the log.
        
        Returns
        -------
        list
            List of voltage samples from the ADC.
        
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
            readings += [_reg2float(i) for i in data]
        else:
            num_words = int(ceil((PMOD_ADC_LOG_END - head_ptr) / 4))
            data = self.microblaze.read(head_ptr, num_words)
            readings += [_reg2float(i) for i in data]

            num_words = int(ceil((tail_ptr - PMOD_ADC_LOG_START) / 4))
            data = self.microblaze.read(PMOD_ADC_LOG_START, num_words)
            readings += [_reg2float(i) for i in data]
        return readings


