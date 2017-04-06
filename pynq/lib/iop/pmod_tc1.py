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

__author__      = "Thomas Fors"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


from struct import pack, unpack
import time
from pynq import MMIO
from pynq.iop import request_iop
from pynq.iop import iop_const
from pynq.iop import PMODA
from pynq.iop import PMODB

PMOD_TC1_PROGRAM = "pmod_tc1.bin"
PMOD_TC1_LOG_START = iop_const.MAILBOX_OFFSET+16
PMOD_TC1_LOG_END = PMOD_TC1_LOG_START+(1000*4)

class Pmod_TC1(object):
    """This class controls a thermocouple Pmod.

    The Digilent PmodTC1 is a cold-junction thermocouple-to-digital converter
    module designed for a classic K-Type thermocouple wire. With Maxim
    Integrated's MAX31855, this module reports the measured temperature in
    14-bits with 0.25 degC resolution.

    Attributes
    ----------
    iop : _IOP
        I/O processor instance used by TC1
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    log_interval_ms : int
        Time in milliseconds between sampled reads of the TC1 sensor

    """
    def __init__(self, if_id):
        """Return a new instance of a TC1 object.

        Parameters
        ----------
        if_id : int
            The interface ID (1, 2) corresponding to (PMODA, PMODB).

        """
        if not if_id in [PMODA, PMODB]:
            raise ValueError("No such IOP for Pmod device.")

        self.iop = request_iop(if_id, PMOD_TC1_PROGRAM)
        self.mmio = self.iop.mmio
        self.log_interval_ms = 1000

        self.iop.start()

    def read(self):
        """Read full 32-bit register of TC1 Pmod.

        Returns
        -------
        int
            The current register contents.

        """
        self.mmio.write(iop_const.MAILBOX_OFFSET +
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 3)
        while (self.mmio.read(iop_const.MAILBOX_OFFSET +
                                iop_const.MAILBOX_PY2IOP_CMD_OFFSET) == 3):
            pass
        return self.mmio.read(iop_const.MAILBOX_OFFSET)

    def reg_to_tc(self, reg_val):
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

    def reg_to_ref(self, reg_val):
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

    def reg_to_alarms(self, reg_val):
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

    def set_log_interval_ms(self,log_interval_ms):
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
        self.mmio.write(iop_const.MAILBOX_OFFSET+4, self.log_interval_ms)

    def start_log(self):
        """Start recording multiple values in a log.

        This method will first call set_log_interval_ms() before writting to
        the MMIO.

        Returns
        -------
        None

        """
        self.set_log_interval_ms(self.log_interval_ms)
        self.mmio.write(iop_const.MAILBOX_OFFSET+\
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 7)

    def stop_log(self):
        """Stop recording multiple values in a log.

        Simply write to the MMIO to stop the log.

        Returns
        -------
        None

        """
        self.mmio.write(iop_const.MAILBOX_OFFSET+\
                        iop_const.MAILBOX_PY2IOP_CMD_OFFSET, 1)

    def get_log(self):
        """Return list of logged samples.

        Returns
        -------
        List of valid samples from the TC1 sensor

        """
        # Stop logging
        self.stop_log()

        # Prep iterators and results list
        head_ptr = self.mmio.read(iop_const.MAILBOX_OFFSET+0x8)
        tail_ptr = self.mmio.read(iop_const.MAILBOX_OFFSET+0xC)
        readings = []

        # Sweep circular buffer for samples
        if head_ptr == tail_ptr:
            return None
        elif head_ptr < tail_ptr:
            for i in range(head_ptr,tail_ptr,4):
                readings.append(self.mmio.read(i))
        else:
            for i in range(head_ptr,PMOD_TC1_LOG_END,4):
                readings.append(self.mmio.read(i))
            for i in range(PMOD_TC1_LOG_START,tail_ptr,4):
                readings.append(self.mmio.read(i))

        return readings
