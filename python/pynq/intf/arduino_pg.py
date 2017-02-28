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

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"

import os
import re
import csv
import json
from pyeda.inter import exprvar
from pyeda.inter import expr2truthtable
from pynq import PL
from pynq import MMIO
from pynq import Xlnk
from .intf_const import ARDUINO
from .intf_const import MAILBOX_OFFSET
from .intf_const import MAILBOX_PY2DIF_CMD_OFFSET
from .intf_const import XTRACE_CNTRL_BASEADDR
from .intf_const import XTRACE_CNTRL_ADDR_AP_CTRL
from .intf_const import XTRACE_CNTRL_LENGTH
from .intf_const import XTRACE_CNTRL_SAMPLE_RATE
from .intf_const import XTRACE_CNTRL_DATA_COMPARE_MSW
from .intf_const import XTRACE_CNTRL_DATA_COMPARE_LSW
from .intf_const import XTRACE_CNTRL_UNLOCK_DEVCFG_SLCR
from .intf_const import XTRACE_CNTRL_LEVEL_SHIFTER
from .intf_const import XTRACE_CNTRL_CLK1_CTRL
from .intf_const import XTRACE_CNTRL_CLK2_CTRL
from .intf_const import XTRACE_CNTRL_LOCK_DEVCFG_SLCR
from .intf_const import XTRACE_CNTRL_12_5_MHZ
from .intf_const import XTRACE_CNTRL_25_0_MHZ
from .intf_const import XTRACE_CNTRL_50_0_MHZ
from .intf import request_intf

ARDUINO_PG_PROGRAM = "arduino_pg.bin"


class Arduino_PG:
    """Class for the Pattern Generator.

    This class can generate digital IO patterns / stimulus on output pins. 
    On input pins, the response can be captured as well. Users can specify
    whether to use a pin as input or output.

    Attributes
    ----------
    if_id : int
        The interface ID (ARDUINO).
    intf : _INTF
        INTF instance used by Arduino_PG class.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    buf_manager: Xlnk
        Buffer manager to allocate and free contiguous memory.
    stimulus_buf: cffi.FFI.CData
        The buffer storing the stimuli, which can be accessed as array.
    response_buf: cffi.FFI.CData
        The buffer storing the responses, which can be accessed as array.

    """

    def __init__(self, if_id):
        """Return a new Arduino_PG object.

        Parameters
        ----------
        if_id : int
            The interface ID (ARDUINO).

        """
        if os.geteuid() != 0:
            raise EnvironmentError('Root permissions required.')
        if not if_id in [ARDUINO]:
            raise ValueError("No such INTF for Arduino interface.")

        self.if_id = if_id
        self.intf = request_intf(if_id, ARDUINO_PG_PROGRAM)
        self.mmio = self.intf.mmio
        self.buf_manager = Xlnk()
        self.stimulus_buf = None
        self.response_buf = None

    def start_pattern_single(self, pins, probes, num_samples, bit_pattern):
        """Configure the PG with a single bit pattern.

        Generates a bit pattern for a single shot operation at specified IO 
        pins with the specified number of samples.
        
        Each bit of the 20-bit patterns, from LSB to MSB, corresponds to:
        D0, D1, ..., D19, A0, A1, ..., A5, respectively.
        
        Parameters
        ----------
        pins : list
            It is a list of 2-tuples (pin number, IO direction). Pin numbers 
            range from 0 to 19; IO direction is `in` or 'out'. For example, 
            [(0,'in'), (2,'in'), (5,'out')].
        probes : list
            List of signal names indexed according to pin number.
        num_samples : int
            Number of samples generated.
        bit_pattern : list
            A list of 20-bit patterns.

        Returns
        -------
        dict
            A Jason format dictionary containing both stimuli and responses.

        """    
        clk_ctrl = MMIO(XTRACE_CNTRL_CLK1_CTRL, 4)
        reg_val = clk_ctrl.read(0)
        reg_val &= 0xFC0FC0FF
        reg_val |= 0x00A00A00 
        clk_ctrl.write(0, reg_val)

        stimulus_buf0 = self.buf_manager.cma_alloc(num_samples * 4,
                                                   data_type="uint8_t")
        stimulus_buf1 = self.buf_manager.cma_get_buffer(stimulus_buf0,
                                                        num_samples * 4)
        stimulus_addr = self.buf_manager.cma_get_phy_addr(stimulus_buf0)

        response_buf0 = self.buf_manager.cma_alloc(num_samples * 8,
                                                   data_type="uint8_t")
        response_buf1 = self.buf_manager.cma_get_buffer(response_buf0,
                                                        num_samples * 8)
        response_addr = self.buf_manager.cma_get_phy_addr(response_buf0)

        self.stimulus_buf = stimulus_buf0
        self.response_buf = response_buf0

        direction_mask = 0xFFFFF
        for i,j in pins:
            if j == 'in':
                direction_mask = direction_mask & ~(1 << i)

        for index, data in enumerate(bit_pattern):
            offset, data = index, int(data, 2)
            # To do: storing and parsing bytes more efficiently
            stimulus_buf1[4 * offset + 3] = ((data >> 24) & 0xFF). \
                to_bytes(1, 'big')
            stimulus_buf1[4 * offset + 2] = ((data >> 16) & 0xFF). \
                to_bytes(1, 'big')
            stimulus_buf1[4 * offset + 1] = ((data >> 8) & 0xFF). \
                to_bytes(1, 'big')
            stimulus_buf1[4 * offset] = (data & 0xFF). \
                to_bytes(1, 'big')

        self.mmio.write(MAILBOX_OFFSET, direction_mask)
        self.mmio.write(MAILBOX_OFFSET + 0x4, stimulus_addr)
        self.mmio.write(MAILBOX_OFFSET + 0x8, num_samples)
        self.mmio.write(MAILBOX_OFFSET + 0xC, response_addr)

        cmd_word = 0x197
        self.mmio.write(MAILBOX_OFFSET +
                        MAILBOX_PY2DIF_CMD_OFFSET, cmd_word)
        while not (self.mmio.read(MAILBOX_OFFSET +
                                  MAILBOX_PY2DIF_CMD_OFFSET) == 0):
            pass

        data = dict()
        data['signal'] = [{'name': '', 'wave': '', 'data': list()}
                          for _ in range(len(pins))]
        ref = [None] * len(pins)

        for offset in range(0, num_samples * 8, 8):
            for index, pin in enumerate(pins):
                # To do: cache byte and bit offsets, no need to recalculate
                if (direction_mask & 0x1) == 0:
                    byte_offset, bit_offset = divmod((pin[0] + 20), 8)
                else:
                    byte_offset, bit_offset = divmod(pin[0], 8)
                direction_mask >>= 1

                bit_sample = (int.from_bytes(
                                response_buf1[offset + byte_offset],
                                'big') >> bit_offset) & 0x1

                if bit_sample == 1:
                    logic_sample = 'h'
                else:
                    logic_sample = 'l'

                if offset == 0:
                    ref[index] = logic_sample
                    data['signal'][index]['name'] = probes[index]
                    data['signal'][index]['wave'] += logic_sample
                else:
                    if logic_sample == ref[index]:
                        data['signal'][index]['wave'] += '.'
                    else:
                        ref[index] = logic_sample
                        data['signal'][index]['wave'] += logic_sample

        return data

    def free(self):
        """Free the memory allocated for stimuli and responses.
        
        This step has to be done manually. If skipped, the Arduino_PG class
        may leak memory.
        
        """
        self.buf_manager.cma_free(self.stimulus_buf)
        self.buf_manager.cma_free(self.response_buf)
