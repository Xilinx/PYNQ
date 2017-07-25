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


from struct import pack
from struct import unpack
from math import ceil
from . import Pmod
from . import MAILBOX_OFFSET


__author__ = "Thomas Fors"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


PMOD_TC1_PROGRAM = "pmod_tc1.bin"
PMOD_TC1_LOG_START = MAILBOX_OFFSET+16
PMOD_TC1_LOG_END = PMOD_TC1_LOG_START+(1000*4)
RESET = 0x1
READ_SINGLE_VALUE = 0x3
READ_AND_LOG = 0x7


def reg_to_tc(reg_val):
    """Extracts Thermocouple temperature from 32-bit register value.

    Parameters
    ----------
    reg_val : int
        32-bit TC1 register value

    Returns
    -------
    float
        The thermocouple temperature in degC.

    """
    v = reg_val >> 18
    if v & 0x00020000:
        v |= 0xfffc0000
    else:
        v &= 0x0003ffff
    v = unpack('<i', pack('<I', v))[0]
    return v * 0.25


def reg_to_ref(reg_val):
    """Extracts Ref Junction temperature from 32-bit register value.

    Parameters
    ----------
    reg_val : int
        32-bit TC1 register value

    Returns
    -------
    float
        The reference junction temperature in degC.

    """
    v = reg_val >> 4
    if v & 0x00000800:
        v |= 0xfffff000
    else:
        v &= 0x00000fff
    v = unpack('<i', pack('<I', v))[0]
    return v * 0.0625


def reg_to_alarms(reg_val):
    """Extracts Alarm flags from 32-bit register value.

    Parameters
    ----------
    reg_val : int
        32-bit TC1 register value

    Returns
    -------
    u32
        The alarm flags from the TC1.
        bit  0 = 1 if thermocouple connection is open-circuit;
        bit  1 = 1 if thermocouple connection is shorted to generated;
        bit  2 = 1 if thermocouple connection is shorted to VCC;
        bit 16 = 1 if any if bits 0-2 are 1.

    """
    return reg_val & 0x0001000f


class Pmod_TC1(object):
    """This class controls a thermocouple Pmod.

    The Digilent PmodTC1 is a cold-junction thermocouple-to-digital converter
    module designed for a classic K-Type thermocouple wire. With Maxim
    Integrated's MAX31855, this module reports the measured temperature in
    14-bits with 0.25 degC resolution.

    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
    log_interval_ms : int
        Time in milliseconds between sampled reads.

    """
    def __init__(self, mb_info):
        """Return a new instance of a TC1 object.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.

        """
        self.microblaze = Pmod(mb_info, PMOD_TC1_PROGRAM)
        self.log_interval_ms = 1000

    def read_raw(self):
        """Read full 32-bit register of TC1 Pmod.

        Returns
        -------
        int
            The current register contents.

        """
        self.microblaze.write_blocking_command(READ_SINGLE_VALUE)
        return self.microblaze.read_mailbox(0)

    def read_junction_temperature(self):
        """Read the reference junction temperature.

        Returns
        -------
        float
            The reference junction temperature in degC.

        """
        return reg_to_ref(self.read_raw())

    def read_thermocouple_temperature(self):
        """Read the reference junction temperature.

        Returns
        -------
        float
            The thermocouple temperature in degC.

        """
        return reg_to_tc(self.read_raw())

    def read_alarm_flags(self):
        """Read the alarm flags from the raw value.

        Returns
        -------
        u32
            The alarm flags from the TC1.
            bit  0 = 1 if thermocouple connection is open-circuit;
            bit  1 = 1 if thermocouple connection is shorted to generated;
            bit  2 = 1 if thermocouple connection is shorted to VCC;
            bit 16 = 1 if any if bits 0-2 are 1.

        """
        return reg_to_alarms(self.read_raw())

    def set_log_interval_ms(self, log_interval_ms):
        """Set the length of the log in the TC1 Pmod.

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

        Note
        ----
        The logged samples are raw 32-bit samples captured from the sensor.

        Returns
        -------
        list
            List of valid samples from the TC1 sensor

        """
        # Stop logging
        self.stop_log()

        # Prep iterators and results list
        [head_ptr, tail_ptr] = self.microblaze.read_mailbox(0x8, 2)
        readings = []

        # Sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            num_words = int(ceil((tail_ptr-head_ptr)/4))
            data = self.microblaze.read(head_ptr, num_words)
            readings += data
        else:
            num_words = int(ceil((PMOD_TC1_LOG_END - head_ptr) / 4))
            data = self.microblaze.read(head_ptr, num_words)
            readings += data

            num_words = int(ceil((tail_ptr - PMOD_TC1_LOG_START) / 4))
            data = self.microblaze.read(PMOD_TC1_LOG_START, num_words)
            readings += data
        return readings
