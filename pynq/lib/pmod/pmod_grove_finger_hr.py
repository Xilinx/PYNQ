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


from math import ceil
from . import Pmod
from . import PMOD_GROVE_G3
from . import PMOD_GROVE_G4
from . import MAILBOX_OFFSET


__author__ = "Marco Rabozzi, Luca Cerina, Giuseppe Natale"
__copyright__ = "Copyright 2016, NECST Laboratory, Politecnico di Milano"


PMOD_GROVE_FINGER_HR_PROGRAM = "pmod_grove_finger_hr.bin"
GROVE_FINGER_HR_LOG_START = MAILBOX_OFFSET+16
GROVE_FINGER_HR_LOG_END = GROVE_FINGER_HR_LOG_START+(1000*4)
CONFIG_IOP_SWITCH = 0x1
READ_DATA = 0x2
READ_AND_LOG_DATA = 0x3
STOP_LOG = 0xC


class Grove_FingerHR(object):
    """This class controls the Grove finger clip heart rate sensor. 
    
    Grove Finger sensor based on the TCS3414CS. 
    Hardware version: v1.3.
    
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
        """Return a new instance of an Grove_FingerHR object. 
        
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

        self.microblaze = Pmod(mb_info, PMOD_GROVE_FINGER_HR_PROGRAM)
        self.log_interval_ms = 1000
        self.log_running = 0

        self.microblaze.write_mailbox(0, gr_pin)
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)

    def read(self):
        """Read the heart rate value from the Grove Finger HR peripheral.
        
        Returns
        -------
        int
            An integer representing the heart rate frequency.
        
        """
        self.microblaze.write_blocking_command(READ_DATA)
        freq = self.microblaze.read_mailbox(0)
        return freq

    def start_log(self, log_interval_ms=100):
        """Start recording multiple heart rate values in a log.
        
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
            raise RuntimeError("No grove finger HR log running.")

    def get_log(self):
        """Return list of logged samples.
            
        Returns
        -------
        list
            List of integers containing the heart rate.
        
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
            num_words = int(ceil((GROVE_FINGER_HR_LOG_END - head_ptr) / 4))
            data = self.microblaze.read(head_ptr, num_words)
            readings += data

            num_words = int(ceil((tail_ptr - GROVE_FINGER_HR_LOG_START) / 4))
            data = self.microblaze.read(GROVE_FINGER_HR_LOG_START, num_words)
            readings += data
        return readings
