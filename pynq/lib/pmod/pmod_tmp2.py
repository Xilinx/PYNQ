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


from math import ceil
from . import Pmod
from . import MAILBOX_OFFSET


__author__ = "Cathal McCabe, Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


PMOD_TMP2_PROGRAM = "pmod_tmp2.bin"
PMOD_TMP2_LOG_START = MAILBOX_OFFSET+16
PMOD_TMP2_LOG_END = PMOD_TMP2_LOG_START+(1000*4)
RESET = 0x1
READ_SINGLE_VALUE = 0x3
READ_AND_LOG = 0x7


def _reg2float(reg):
    """Translate the register value to a floating-point number.

    Note
    ----
    The float precision is specified to be 1 digit after the decimal 
    point.

    Bit [31]    (1 bit)        ->    Sign (S)
    Bit [30:23] (8 bits)       ->    Exponent (E)
    Bit [22:0]  (23 bits)      ->    Mantissa (M)

    Parameters
    ----------
    reg : int
        A 4-byte integer.

    Returns
    -------
    float
        The floating-point number translated from the input.

    """
    if reg == 0:
        return 0.0
    sign = (reg & 0x80000000) >> 31 & 0x01
    exp = ((reg & 0x7f800000) >> 23) - 127
    if exp == 0:
        man = (reg & 0x007fffff) / pow(2, 23)
    else:
        man = 1 + (reg & 0x007fffff) / pow(2, 23)
    result = pow(2, exp) * man * ((sign * -2) + 1)
    return float("{0:.1f}".format(result))


class Pmod_TMP2(object):
    """This class controls a temperature sensor Pmod.
    
    The Pmod TMP2 (PB 200-221) is an ambient temperature sensor powered by 
    ADT7420.

    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
    log_interval_ms : int
        Time in milliseconds between sampled reads.
        
    """
    def __init__(self, mb_info):
        """Return a new instance of a TMP2 object. 
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.

        """
        self.microblaze = Pmod(mb_info, PMOD_TMP2_PROGRAM)
        self.log_interval_ms = 1000

    def read(self):
        """Read current temperature value measured by the Pmod TMP2.
        
        Returns
        -------
        float
            The current sensor value.
        
        """
        self.microblaze.write_blocking_command(READ_SINGLE_VALUE)
        value = self.microblaze.read_mailbox(0)
        return _reg2float(value)
        
    def set_log_interval_ms(self, log_interval_ms):
        """Set the sampling interval for the Pmod TMP2.
        
        Parameters
        ----------
        log_interval_ms : int
            Time in milliseconds between sampled reads of the TMP2 sensor
            
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
        
        This method will first call set_log_interval_ms() before writting to
        the MMIO.
            
        Returns
        -------
        None
        
        """
        self.set_log_interval_ms(self.log_interval_ms)
        self.microblaze.write_non_blocking_command(READ_AND_LOG)

    def stop_log(self):
        """Stop recording multiple values in a log.
        
        Simply write to the MMIO to stop the log.
            
        Returns
        -------
        None
        
        """
        self.microblaze.write_non_blocking_command(RESET)

    def get_log(self):
        """Return list of logged samples.
            
        Returns
        -------
        List of valid samples from the temperature sensor in Celsius.
        
        """
        # First stop logging
        self.stop_log()

        # Prep iterators and results list
        [head_ptr, tail_ptr] = self.microblaze.read_mailbox(0x8, 2)
        temps = list()

        # Sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            num_words = int(ceil((tail_ptr - head_ptr) / 4))
            data = self.microblaze.read(head_ptr, num_words)
            temps += [_reg2float(i) for i in data]
        else:
            num_words = int(ceil((PMOD_TMP2_LOG_END - head_ptr) / 4))
            data = self.microblaze.read(head_ptr, num_words)
            temps += [_reg2float(i) for i in data]

            num_words = int(ceil((tail_ptr - PMOD_TMP2_LOG_START) / 4))
            data = self.microblaze.read(PMOD_TMP2_LOG_START, num_words)
            temps += [_reg2float(i) for i in data]
        return temps
