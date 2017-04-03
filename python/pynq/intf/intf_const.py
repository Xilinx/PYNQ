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

# Microblaze constants
BIN_LOCATION = os.path.dirname(os.path.realpath(__file__))+"/"

# Interface mailbox constants
MAILBOX_OFFSET = 0xF000
MAILBOX_SIZE = 0x1000
MAILBOX_PY2DIF_CMD_OFFSET = 0xFFC
MAILBOX_PY2DIF_ADDR_OFFSET = 0xFF8
MAILBOX_PY2DIF_DATA_OFFSET = 0xF00

PMODA = 1
PMODB = 2
ARDUINO = 3

# Microblaze commands
CMD_GENERATE_DEFAULT_BOOLEAN = 0x001
CMD_GENERATE_USER_BOOLEAN = 0x003
CMD_GENERATE_PATTERN_SINGLE = 0x197
CMD_GENERATE_FSM_START = 0x009
CMD_GENERATE_FSM_STOP = 0x00B
CMD_TRACE_FSM_ONLY = 0x00D

# Pattern generator constants
PATTERN_FREQUENCY_MHZ = 10
INPUT_SAMPLE_SIZE = 64
OUTPUT_SAMPLE_SIZE = 32
OUTPUT_PIN_MAP = {'D0': 0,
                  'D1': 1,
                  'D2': 2,
                  'D3': 3,
                  'D4': 4,
                  'D5': 5,
                  'D6': 6,
                  'D7': 7,
                  'D8': 8,
                  'D9': 9,
                  'D10': 10,
                  'D11': 11,
                  'D12': 12,
                  'D13': 13,
                  'D14': 14,
                  'D15': 15,
                  'D16': 16,
                  'D17': 17,
                  'D18': 18,
                  'D19': 19}
INPUT_PIN_MAP = {'D0': 20,
                 'D1': 21,
                 'D2': 22,
                 'D3': 23,
                 'D4': 24,
                 'D5': 25,
                 'D6': 26,
                 'D7': 27,
                 'D8': 28,
                 'D9': 29,
                 'D10': 30,
                 'D11': 31,
                 'D12': 32,
                 'D13': 33,
                 'D14': 34,
                 'D15': 35,
                 'D16': 36,
                 'D17': 37,
                 'D18': 38,
                 'D19': 39}
TRI_STATE_MAP = {'D0': 42,
                 'D1': 43,
                 'D2': 44,
                 'D3': 45,
                 'D4': 46,
                 'D5': 47,
                 'D6': 48,
                 'D7': 49,
                 'D8': 50,
                 'D9': 51,
                 'D10': 52,
                 'D11': 53,
                 'D12': 54,
                 'D13': 55,
                 'D14': 56,
                 'D15': 57,
                 'D16': 58,
                 'D17': 59,
                 'D18': 60,
                 'D19': 61}

# FSM generator constants
FSM_BRAM_ADDR_WIDTH = 13
FSM_MAX_STATE_BITS = 9
FSM_MAX_INPUT_BITS = 8
FSM_MAX_STATE_INPUT_BITS = 13
FSM_MAX_OUTPUT_BITS = 19
