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

__author__      = "Graham Schelle, Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


import time
from . import _iop
from . import pmod_const
from pynq import MMIO
from pynq.iop import pmod_const


class DevMode(object):
    """Control an IO processor running the developer mode program. 
    
    This class will wait for Python to send commands to PMOD IO, IIC, or SPI.

    Attributes
    ----------
    iop : _IOP
        IO processor instance used by DevMode.
    iop_switch_config :list
        IO processor switch configuration (8 32-bit values).
    mmio : MMIO
        Memory-mapped IO instance to read and write instructions and data.
    
    """

    def __init__(self, pmod_id, switch_config):
        """Return a new instance of a DevMode object.
        
        Parameters
        ----------
        pmod_id : int
            ID of the PMOD to which the IO processor is attached.
        switch_config : list
            IO Processor switch configuration (8 32-bit values).
            
        """

        self.mailbox_op_addr_offest = 0xff8
        
        self.iop = _iop.request_iop(pmod_id, pmod_const.MAILBOX_PROGRAM)
        self.iop_switch_config = list(switch_config)
        self.mmio = MMIO(self.iop.mmio.base_addr + pmod_const.MAILBOX_OFFSET, 
                            pmod_const.MAILBOX_SIZE)
                        
    def start(self):
        """Start the IO Processor.
        
        The IOP instance will start automatically after instantiation.
        
        This method will:
        1. zero out mailbox CMD register;
        2. load switch config;
        3. set IOP status as "RUNNING".
        
        """
        self.iop.start()
        self.mmio.write(pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, 0)
        self.load_switch_config()

    def stop(self):
        """Put the IO Processor into Reset.
        
        This method will set IOP status as "STOPPED".
        
        """
        self.iop.stop()

    def load_switch_config(self, config=None):
        """Load the IO processor's switch configuration 
        
        Note
        ----
        This method will update switch config first if the configuration is
        provided (a list of 8 32-bit values). Otherwise, this method will 
        configure the switch with DevMode.iop_switch_config 
        
        Parameters
        ----------
        config: list
            A switch configuration list of 8 32-bit values.

        Raises
        ----------
        TypeError
            If the config argument is not of the correct type.
            
        """
        if config:
            if len(config) != pmod_const.IOPMM_SWITCHCONFIG_NUMREGS:
                raise TypeError('User supplied config {} is not a ' +
                        'list of 8 integers.'.format(config))
            self.iop_switch_config = config

        # Build switch config word 
        sw_config_word = 0
        for ix, cfg in enumerate(self.iop_switch_config): 
            sw_config_word |= (cfg << ix*4)

        # Disable, configure, enable switch
        self.write_cmd(pmod_const.IOPMM_SWITCHCONFIG_BASEADDR + 4, 0)
        self.write_cmd(pmod_const.IOPMM_SWITCHCONFIG_BASEADDR, \
                        sw_config_word)
        self.write_cmd(pmod_const.IOPMM_SWITCHCONFIG_BASEADDR + 7, \
                        0x80, dWidth=1)     

    def get_switch_config(self):
        """Print the IO processor's switch configuration.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        list
            A switch configuration list of 8 32-bit values.
        
        """
        sw_config = list()
        for ix, cfg in enumerate(self.iop_switch_config):
            sw_config.append(self.read_cmd(
                pmod_const.IOPMM_switch_config_BASEADDR + ix*4, dWidth=1))
        return sw_config

    def status(self):
        """Returns the status of the IO processor.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        str
            The IOP status ("IDLE", "RUNNING", or "STOPPED").
        
        """
        return self.iop.state
       
    def write_cmd(self, address, data, dWidth=4, dLength=1, timeout=10):
        """Send a write command to the mailbox.
        
        Parameters
        ----------
        address : int
            The address tied to IO processor's memory map.
        data : int
            32-bit value to be written (None for read).
        dWidth : int
            Command data width.
        dLength : int
            Command burst length (currently only supporting dLength 1).
        timeout : int
            Time in milliseconds before function exits with warning.
        
        Returns
        -------
        None
        
        """
        return self._send_cmd(pmod_const.WRITE_CMD, address, data, 
                                dWidth=dWidth, timeout=timeout)

    def read_cmd(self, address, dWidth=4, dLength=1, timeout=10):
        """Send a read command to the mailbox.
        
        Parameters
        ----------
        address : int
            The address tied to IO processor's memory map.
        dWidth : int
            Command data width.
        dLength : int
            Command burst length (currently only supporting dLength 1).
        timeout : int
            Time in milliseconds before function exits with warning.
        
        Returns
        -------
        list
            A list of data returned by MMIO read.
        
        """
        return self._send_cmd(pmod_const.READ_CMD, address, None, 
                                dWidth=dWidth, timeout=timeout)

    def is_cmd_mailbox_idle(self): 
        """Check whether the IOP command mailbox is idle.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        bool
            True if IOP command mailbox idle.
        
        """
        mb_cmd_word = self.mmio.read(pmod_const.MAILBOX_PY2IOP_CMD_OFFSET)
        return (mb_cmd_word & 0x1) == 0

    def get_cmd_word(self, cmd, dWidth, dLength):
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
            Either 1 (read IOP register) or 0 (write IOP register).
        dWidth : int
            Command data width.
        dLength : int
            Command burst length (currently only supporting dLength 1).
            
        Returns
        -------
        int
            The command word following a specific format.
            
        """
        word = 0x1                    # cmd valid
        word = word | (dWidth-1) << 1 # cmd dataWidth    (3->4B, 1->2B, 0->1B)
        word = word | (cmd) << 3      # cmd type         (1->RD, 0->WR)
        word = word | (dLength) << 8  # cmd burst length (1->1 word)
        word = word | (0) << 16       # unused
              
        return word

    def _send_cmd(self, cmd, address, data, dWidth=4, dLength=1, timeout=10):
        """Send a command to the IO processor via mailbox.

        Note
        ----
        User should avoid to call this method directly. 
        Use the read_cmd() or write_cmd() instead.

        Example:
            >>> _send_cmd(1, 4, None)  # Read address 4.
            
        Parameters
        ----------        
        cmd : int
            Either 1 (read IOP Reg) or 0 (write IOP Reg).
        address : int
            The address tied to IO processor's memory map.
        data : int
            32-bit value to be written (None for read).
        dWidth : int
            Command data width.
        dLength : int
            Command burst length (currently only supporting dLength 1).
        timeout : int
            Time in milliseconds before function exits with warning.
            
        Raises
        ------
        LookupError
            If it takes too long to receive the ACK from the IOP.


        """
        self.mmio.write(self.mailbox_op_addr_offest, address)
        if data != None:
            self.mmio.write(pmod_const.MAILBOX_PY2IOP_DATA_OFFSET, data)
        
        # Build the write command
        cmd_word = self.get_cmd_word(cmd, dWidth, dLength)

        self.mmio.write(pmod_const.MAILBOX_PY2IOP_CMD_OFFSET, cmd_word)

        # Wait for ACK in steps of 1ms
        cntdown = timeout
        while not self.is_cmd_mailbox_idle() and cntdown > 0:
            time.sleep(0.001)
            cntdown -= 1

        # If ACK is not received, alert users.
        if cntdown == 0:
            raise LookupError("DevMode _send_cmd() not acknowledged.")

        # Return data if expected from read, otherwise return None
        if cmd == pmod_const.WRITE_CMD: 
            return None
        else:
            return self.mmio.read(pmod_const.MAILBOX_PY2IOP_DATA_OFFSET)
            
