#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from math import ceil
from . import Pmod
from . import MAILBOX_OFFSET




PMOD_ALS_PROGRAM = "pmod_als.bin"
PMOD_ALS_LOG_START = MAILBOX_OFFSET+16
PMOD_ALS_LOG_END = PMOD_ALS_LOG_START+(1000*4)
RESET = 0x1
READ_SINGLE_VALUE = 0x3
READ_AND_LOG = 0x7


class Pmod_ALS(object):
    """This class controls a light sensor Pmod.
    
    The Digilent Pmod ALS demonstrates light-to-digital sensing through a
    single ambient light sensor. This is based on an ADC081S021 
    analog-to-digital converter and a TEMT6000X01 ambient light sensor.

    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
    log_interval_ms : int
        Time in milliseconds between sampled reads.
        
    """
    def __init__(self, mb_info):
        """Return a new instance of an ALS object. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.

        """
        self.microblaze = Pmod(mb_info, PMOD_ALS_PROGRAM)
        self.log_interval_ms = 1000

    def read(self):
        """Read current light value measured by the ALS Pmod.
        
        Returns
        -------
        int
            The current sensor value.
        
        """
        self.microblaze.write_blocking_command(READ_SINGLE_VALUE)
        data = self.microblaze.read_mailbox(0)
        return data

    def set_log_interval_ms(self, log_interval_ms):
        """Set the length of the log in the ALS Pmod.
        
        This method can set the length of the log, so that users can read out
        multiple values in a single log. 
        
        Parameters
        ----------
        log_interval_ms : int
            The length of the log in milliseconds, for debug only.
            
        Returns
        -------
        None
        
        """
        if log_interval_ms < 0:
            raise ValueError("Log length should not be less than 0.")
        
        self.log_interval_ms = log_interval_ms
        self.microblaze.write_mailbox(0x4, log_interval_ms)

    def start_log(self):
        """Start recording multiple values in a log.

        This method will first call set_log_interval_ms() before sending the 
        command.

        Returns
        -------
        None

        """
        self.set_log_interval_ms(self.log_interval_ms)
        self.microblaze.write_non_blocking_command(READ_AND_LOG)

    def stop_log(self):
        """Stop recording multiple values in a log.
        
        Simply send the command to stop the log.
            
        Returns
        -------
        None
        
        """
        self.microblaze.write_non_blocking_command(RESET)

    def get_log(self):
        """Return list of logged samples.
            
        Returns
        -------
        List of valid samples from the ALS sensor [0-255]
        
        """
        # stop logging
        self.stop_log()

        # prep iterators and results list
        [head_ptr, tail_ptr] = self.microblaze.read_mailbox(0x8, 2)
        readings = []

        # sweep circular buffer for samples
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


