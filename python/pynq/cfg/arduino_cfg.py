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
import IPython.core.display
from time import sleep
from pyeda.inter import exprvar
from pyeda.inter import expr2truthtable
from pynq import PL
from pynq import MMIO
from pynq import Xlnk
from pynq.cfg import request_cfg
from pynq.cfg import cfg_const
from pynq.cfg import ARDUINO
from pynq.cfg.cfg_const import XTRACE_CNTRL_BASEADDR
from pynq.cfg.cfg_const import XTRACE_CNTRL_ADDR_AP_CTRL
from pynq.cfg.cfg_const import XTRACE_CNTRL_LENGTH
from pynq.cfg.cfg_const import XTRACE_CNTRL_SAMPLE_RATE
from pynq.cfg.cfg_const import XTRACE_CNTRL_DATA_COMPARE_MSW
from pynq.cfg.cfg_const import XTRACE_CNTRL_DATA_COMPARE_LSW
from pynq.cfg.cfg_const import XTRACE_CNTRL_UNLOCK_DEVCFG_SLCR
from pynq.cfg.cfg_const import XTRACE_CNTRL_LEVEL_SHIFTER
from pynq.cfg.cfg_const import XTRACE_CNTRL_CLK1_CTRL
from pynq.cfg.cfg_const import XTRACE_CNTRL_CLK2_CTRL
from pynq.cfg.cfg_const import XTRACE_CNTRL_LOCK_DEVCFG_SLCR
from pynq.cfg.cfg_const import XTRACE_CNTRL_12_5_MHZ
from pynq.cfg.cfg_const import XTRACE_CNTRL_25_0_MHZ
from pynq.cfg.cfg_const import XTRACE_CNTRL_50_0_MHZ

IN_PINS = [['D3', 'D2', 'D1', 'D0'],
           ['D8', 'D7', 'D6', 'D5'],
           ['D13', 'D12', 'D11', 'D10'],
           ['A4', 'A3', 'A2', 'A1'],
           ['PB3', 'PB2', 'PB1', 'PB0']]
OUT_PINS = ['D4', 'D9', 'A0', 'A5']
LD_PINS = ['LD0', 'LD1', 'LD2', 'LD3', 'LD4', 'LD5']
# ARDUINO_CFG_PROGRAM = "arduino_cfg.bin"
ARDUINO_CFG_PROGRAM = "if_arduino_pg.bin"


class Arduino_CFG:
    """Class for the Combinational Function Generator.

    This class can implement any combinational function on user IO pins. A
    typical function implemented for a bank of 5 pins can be 4-input and
    1-output. However, by connecting pins across different banks, users can
    implement more complex functions with more input/output pins.

    Attributes
    ----------
    if_id : int
        The interface ID (ARDUINO).
    cfg : _CFG
        CFG instance used by Arduino_CFG class.
    mmio : MMIO
        Memory-mapped I/O instance to read and write instructions and data.
    expr : list
        The list of boolean expressions; each expression is a string.
    led : bool
        Whether LED is used to indicate output.
    verbose : bool
        Whether to show verbose message to users.

    """

    def __init__(self, if_id, expr=None, led=True, verbose=True):
        """Return a new arduino_CFG object.

        For ARDUINO, the available input pins are data pins (D0-D13, A0-A5),
        the onboard push buttons (PB0-PB3). The available output pins are
        D4, D9, A0, A5, and the onboard LEDs (LD0-LD5).

        Bank 0:
        input 0 - 3: D0 - D3; output: D4/LD0.

        Bank 1:
        input 0 - 3: D5 - D8; output: D9/LD1.

        Bank 2:
        input 0 - 3: D10 - D13; output: A0/LD2.

        Bank 3:
        input 0 - 3: A1 - A4; output: A5/LD3.

        Bank 4:
        input 0 - 3: PB0 - PB3; output: LD4

        The input boolean expression can be of the following formats:
        (1) `D0 & D1 | D2`, or
        (2) `D4 = D0 & D1 | D2`.

        If no input boolean expression is specified, the default function
        implemented is `D0 & D1 & D2 & D3`.

        Note
        ----
        When LED is used as the output indicator, an LED `on` indicates the
        corresponding output is `logic high`.

        Parameters
        ----------
        if_id : int
            The interface ID (ARDUINO).
        expr : list
            The list of boolean expressions; each expression is a string.
        led : bool
            Whether LED is used to indicate output; defaults to true.
        verbose : bool
            Whether to show verbose message to users.

        """
        if os.geteuid() != 0:
            raise EnvironmentError('Root permissions required.')
        if not if_id in [ARDUINO]:
            raise ValueError("No such CFG for Arduino interface.")

        self.cfg = request_cfg(if_id, ARDUINO_CFG_PROGRAM)
        self.mmio = self.cfg.mmio
        self.if_id = if_id
        self.expr = expr
        self.led = led
        self.verbose = verbose

        # set up CFG
        if expr is None:
            self.mmio.write(cfg_const.MAILBOX_OFFSET +
                            cfg_const.MAILBOX_PY2CFG_CMD_OFFSET, 0x1)
            while (self.mmio.read(cfg_const.MAILBOX_OFFSET +
                                  cfg_const.MAILBOX_PY2CFG_CMD_OFFSET) == 0x1):
                pass
        else:
            self.bool_fun(expr, led, verbose)

        self.buf_manager = Xlnk()
        self.src_buf = None
        self.dst_buf = None
        self.cfg.start()

    def bool_func(self, expr, led=True, verbose=True):
        """Configure the CFG with new boolean expression or LED indicator.

        Implements boolean function at specified IO pins with optional led
        output.

        Parameters
        ----------
        expr : str
            The new boolean expression.
        led : bool
            Show boolean function output on onboard LED, defaults to true
        verbose : bool
            Whether to show verbose message to users.

        Returns
        -------
        None

        """
        if not isinstance(expr, str):
            raise TypeError("Boolean expression has to be a string.")

        self.expr = expr
        self.led = led
        self.verbose = verbose

        # parse boolean expression
        bank_out = None
        if "=" in expr:
            expr_out, expr_in = expr.split("=")
            expr_out = expr_out.strip()
            if expr_out in OUT_PINS:
                bank_out = OUT_PINS.index(expr_out)
            elif expr_out in LD_PINS:
                bank_out = LD_PINS.index(expr_out)
            else:
                raise ValueError("Invalid output pin.")
        else:
            expr_in = expr

        # parse the used pins
        pin_id = re.split("~|\||^|\&", expr_in.strip())
        pin_id = [e.strip() for e in pin_id if e]
        bank_in = 0
        for b in range(5):
            if pin_id[0] in IN_PINS[b]:
                bank_in = b
                break
        if (bank_out is not None) and (bank_in != bank_out):
            raise ValueError("Invalid combination of IO pins.")

        # check whether pins are valid
        intersect = set(IN_PINS[bank_in]) & set(pin_id)
        if set(intersect) != set(pin_id):
            raise ValueError("Invalid combination of IO pins.")

        for i in IN_PINS[bank_in]:
            if i not in expr_in:
                expr_in = '(' + expr_in + '&' + i + \
                          ')|(' + expr_in + '&~' + i + ')'

        # map to truth table
        p3, p2, p1, p0 = map(exprvar, IN_PINS[bank_in])
        expr_p = expr_in
        for i in range(4):
            expr_p = expr_p.replace('D' + str(i), 'p' + str(i))
            expr_p = expr_p.replace('D' + str(i + 5), 'p' + str(i))
            expr_p = expr_p.replace('D' + str(i + 10), 'p' + str(i))
            expr_p = expr_p.replace('A' + str(i + 1), 'p' + str(i))
            expr_p = expr_p.replace('PB' + str(i), 'p' + str(i))
        truth_table = expr2truthtable(eval(expr_p))
        if verbose:
            if led:
                print("Logic output mapped to {}".format(LD_PINS[bank_in]))
            if bank_in < 4:
                print("Logic output mapped to {}".format(OUT_PINS[bank_in]))
            print("Truth table:")
            print(truth_table)

        # parse truth table to send
        truth_list = str(truth_table).split("\n")
        truth_num = 0
        for i in range(16, 0, -1):
            truth_num = (truth_num << 1) + int(truth_list[i][-1])

        # construct the command word
        cmd_word = 0x3
        cmd_word |= (0x1 << (4 + bank_in))
        if led:
            cmd_word |= (0x1 << 12)

        self.mmio.write(cfg_const.MAILBOX_OFFSET, truth_num)
        self.mmio.write(cfg_const.MAILBOX_OFFSET +
                        cfg_const.MAILBOX_PY2CFG_CMD_OFFSET, cmd_word)
        while (self.mmio.read(cfg_const.MAILBOX_OFFSET +
                             cfg_const.MAILBOX_PY2CFG_CMD_OFFSET) == cmd_word):
            pass

    def start_pattern_single(self, pins, probes, num_samples, bit_pattern):
        """Configure the PG with a single bit pattern.

        Generates a bit pattern for a single shot operation at specified IO 
        pins with the specific vector depth
        
        Parameters
        ----------
        pins : list
            It is a list of 2-tuples, with each tuple containing the pin number
            and IO direction. pin numbers range from 0 to 19 and  IO direction
            is 'in' for an input and 'out' for output
            eg:[(0,'in'), (1,'in'), (2,'out')]
        probes : list
            List of signal names indexed according to pin number
        num_samples : int
            Bit pattern sample depth           
        bit_pattern : list
            Bit pattern for 20 pins 
            LSB --> D0 of Arduino
            MSB --> A5 of Arduino            

        Returns
        -------
        dict
            Returns the 'signal' dict in WaveJSON format
            
            Return dict contains signal data for the stimulus as well as the
            response

        """    
        clk_ctrl = MMIO(XTRACE_CNTRL_CLK1_CTRL, 4)
        reg_val = clk_ctrl.read(0)
        reg_val &= 0xFC0FC0FF
        reg_val |= 0x00A00A00 
        clk_ctrl.write(0, reg_val)

        src_buf0 = self.buf_manager.cma_alloc(num_samples * 4,
                                              data_type="uint8_t")
        src_buf1 = self.buf_manager.cma_get_buffer(src_buf0,
                                                   num_samples * 4)
        source = self.buf_manager.cma_get_phy_addr(src_buf0)

        dst_buf0 = self.buf_manager.cma_alloc(num_samples * 8,
                                              data_type="uint8_t")
        dst_buf1 = self.buf_manager.cma_get_buffer(dst_buf0,
                                                   num_samples * 8)
        destination = self.buf_manager.cma_get_phy_addr(dst_buf0)

        self.src_buf = src_buf0
        self.dst_buf = dst_buf0

        direction_mask = 0xFFFFF
        for index, i in enumerate(pins):
            if i[1] == 'in':
                direction_mask = direction_mask & ~(1 << index)

        for index, data in enumerate(bit_pattern):
            offset, data = index, int(data, 2)
            src_buf1[4 * offset + 3] = ((data >> 24) & 0xFF). \
                to_bytes(1, 'big')
            src_buf1[4 * offset + 2] = ((data >> 16) & 0xFF). \
                to_bytes(1, 'big')
            src_buf1[4 * offset + 1] = ((data >> 8) & 0xFF). \
                to_bytes(1, 'big')
            src_buf1[4 * offset] = (data & 0xFF). \
                to_bytes(1, 'big')

        print('direction mask:{}'.format(hex(direction_mask)))
        print('source: {}'.format(hex(source)))
        print('num samples: {}'.format(num_samples))
        print('destination: {}'.format(hex(destination)))
        self.mmio.write(cfg_const.MAILBOX_OFFSET, direction_mask)
        self.mmio.write(cfg_const.MAILBOX_OFFSET + 0x4, source)
        self.mmio.write(cfg_const.MAILBOX_OFFSET + 0x8, num_samples)
        self.mmio.write(cfg_const.MAILBOX_OFFSET + 0xC, destination)

        cmd_word = 0x197
        self.mmio.write(cfg_const.MAILBOX_OFFSET +
                        cfg_const.MAILBOX_PY2CFG_CMD_OFFSET, cmd_word)
        while not (self.mmio.read(cfg_const.MAILBOX_OFFSET +
                                    cfg_const.MAILBOX_PY2CFG_CMD_OFFSET) == 0):
            pass

        data = dict()
        data['signal'] = [{'name': '', 'wave': '', 'data': list()}
                          for _ in range(len(pins))]
        ref = [None] * len(pins)

        for offset in range(0, num_samples * 8, 8):
            for index, pin in enumerate(pins):
                if (direction_mask & 0x1) == 0:
                    byte_offset, bit_offset = divmod((pin[0] + 20), 8)              
                else:
                    byte_offset, bit_offset = divmod(pin[0], 8)
                    
                direction_mask >>= 1

                bit_sample = (int.from_bytes(dst_buf1[offset + byte_offset],
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
        self.buf_manager.cma_free(self.src_buf)
        self.buf_manager.cma_free(self.dst_buf)
