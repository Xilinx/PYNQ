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


import time
from . import Pmod
from . import PMOD_SWCFG_DIOALL
from . import PMOD_SWITCHCONFIG_NUMREGS
from . import PMOD_SWITCHCONFIG_BASEADDR
from . import MAILBOX_PY2IOP_ADDR_OFFSET
from . import MAILBOX_PY2IOP_DATA_OFFSET
from . import MAILBOX_PY2IOP_CMD_OFFSET
from . import MAILBOX_OFFSET
from . import WRITE_CMD
from . import READ_CMD


__author__ = "Graham Schelle, Giuseppe Natale, Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


PMOD_MAILBOX_PROGRAM = 'pmod_mailbox.bin'


def get_cmd_word(cmd, d_width, d_length):
    """Build the command word.

    Note
    ----
    The returned command word has the following format:
    Bit [0]     : valid bit.
    Bit [2:1]   : command data width.
    Bit [3]     : command type (read or write).
    Bit [15:8]  : command burst length.
    Bit [31:16] : unused.

    Parameters
    ----------        
    cmd : int
        Either 1 (read processor register) or 0 (write processor register).
    d_width : int
        Command data width.
    d_length : int
        Command burst length (currently only supporting d_length 1).

    Returns
    -------
    int
        The command word following a specific format.

    """
    word = 0x1                        # cmd valid
    word = word | (d_width - 1) << 1  # cmd dataWidth    (3->4B, 1->2B, 0->1B)
    word = word | cmd << 3            # cmd type         (1->RD, 0->WR)
    word = word | d_length << 8       # cmd burst length (1->1 word)
    word = word | 0 << 16             # unused

    return word


class Pmod_DevMode(object):
    """Control a Microblaze processor running the developer mode program. 
    
    This class will wait for Python to send commands to Microblaze processor.

    Attributes
    ----------
    microblaze : Pmod
        Microblaze processor instance used by this module.
    iop_switch_config :list
        Microblaze processor switch configuration (8 integers).

    """
    def __init__(self, mb_info, switch_config):
        """Return a new instance of a DevMode object.
        
        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.
        switch_config : list
            Microblaze Processor switch configuration (8 integers).
            
        """
        self.microblaze = Pmod(mb_info, PMOD_MAILBOX_PROGRAM)
        self.iop_switch_config = switch_config
                        
    def start(self):
        """Start the Microblaze processor.
        
        The processor will start automatically after instantiation.

        This method will:
        1. zero out mailbox CMD register;
        2. load switch config;
        3. set IP status as "RUNNING".
        
        """
        self.microblaze.run()
        self.microblaze.write(MAILBOX_OFFSET + MAILBOX_PY2IOP_CMD_OFFSET, 0)
        self.load_switch_config(self.iop_switch_config)

    def stop(self):
        """Put the Microblaze processor into reset.
        
        This method will set processor status as "STOPPED".
        
        """
        self.microblaze.reset()

    def load_switch_config(self, config=None):
        """Load the Microblaze processor's switch configuration.
        
        This method will update switch config. Each pin requires 8 bits for
        configuration.
        
        Parameters
        ----------
        config: list
            A switch configuration list of integers.

        Raises
        ----------
        ValueError
            If the config argument is not of the correct type.
            
        """
        if config is None:
            config = PMOD_SWCFG_DIOALL
        elif not len(config) == 4*PMOD_SWITCHCONFIG_NUMREGS:
            raise ValueError('Invalid switch config {}.'.format(config))

        # Build switch config word
        self.iop_switch_config = config
        sw_config_word_l = sw_config_word_h = 0
        for ix, cfg in enumerate(self.iop_switch_config[0:4]):
            sw_config_word_l |= (cfg << ix*8)
        for ix, cfg in enumerate(self.iop_switch_config[4:8]):
            sw_config_word_h |= (cfg << ix*8)

        # Configure switch
        self.write_cmd(PMOD_SWITCHCONFIG_BASEADDR, sw_config_word_l)
        self.write_cmd(PMOD_SWITCHCONFIG_BASEADDR + 4, sw_config_word_h)

    def status(self):
        """Returns the status of the Microblaze processor.
        
        Returns
        -------
        str
            The processor status ("IDLE", "RUNNING", or "STOPPED").
        
        """
        return self.microblaze.state
       
    def write_cmd(self, address, data, d_width=4, d_length=1, timeout=10):
        """Send a write command to the mailbox.
        
        Parameters
        ----------
        address : int
            The address tied to Microblaze processor's memory map.
        data : int
            32-bit value to be written (None for read).
        d_width : int
            Command data width.
        d_length : int
            Command burst length (currently only supporting d_length 1).
        timeout : int
            Time in milliseconds before function exits with warning.
        
        Returns
        -------
        None
        
        """
        # Write the address and data
        self.microblaze.write(MAILBOX_OFFSET + MAILBOX_PY2IOP_ADDR_OFFSET,
                              address)
        self.microblaze.write(MAILBOX_OFFSET + MAILBOX_PY2IOP_DATA_OFFSET,
                              data)

        # Build the write command
        cmd_word = get_cmd_word(WRITE_CMD, d_width, d_length)
        self.microblaze.write(MAILBOX_OFFSET + MAILBOX_PY2IOP_CMD_OFFSET,
                              cmd_word)

        # Wait for ACK in steps of 1ms
        countdown = timeout
        while not self.is_cmd_mailbox_idle() and countdown > 0:
            time.sleep(0.001)
            countdown -= 1

        # If ACK is not received, alert users.
        if countdown == 0:
            raise RuntimeError("PmodDevMode write_cmd() not acknowledged.")

    def read_cmd(self, address, d_width=4, d_length=1, timeout=10):
        """Send a read command to the mailbox.
        
        Parameters
        ----------
        address : int
            The address tied to Microblaze processor's memory map.
        d_width : int
            Command data width.
        d_length : int
            Command burst length (currently only supporting d_length 1).
        timeout : int
            Time in milliseconds before function exits with warning.
        
        Returns
        -------
        int
            Data returned by MMIO read.
        
        """
        # Write the address
        self.microblaze.write(MAILBOX_OFFSET + MAILBOX_PY2IOP_ADDR_OFFSET,
                              address)

        # Build the read command
        cmd_word = get_cmd_word(READ_CMD, d_width, d_length)
        self.microblaze.write(MAILBOX_OFFSET + MAILBOX_PY2IOP_CMD_OFFSET,
                              cmd_word)

        # Wait for ACK in steps of 1ms
        countdown = timeout
        while not self.is_cmd_mailbox_idle() and countdown > 0:
            time.sleep(0.001)
            countdown -= 1

        # If ACK is not received, alert users.
        if countdown == 0:
            raise RuntimeError("PmodDevMode read_cmd() not acknowledged.")
        result = self.microblaze.read(MAILBOX_OFFSET +
                                      MAILBOX_PY2IOP_DATA_OFFSET)
        return result

    def is_cmd_mailbox_idle(self): 
        """Check whether the command mailbox is idle.
        
        Returns
        -------
        bool
            True if the command in the mailbox is idle.
        
        """
        mb_cmd_word = self.microblaze.read(MAILBOX_OFFSET +
                                           MAILBOX_PY2IOP_CMD_OFFSET)
        return (mb_cmd_word & 0x1) == 0
