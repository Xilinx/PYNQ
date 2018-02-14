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


import os
import numpy as np


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


# Microblaze constants
BIN_LOCATION = os.path.dirname(os.path.realpath(__file__)) + "/"

# Logictools mailbox constants
MAILBOX_OFFSET = 0xF000
MAILBOX_SIZE = 0x1000
MAILBOX_PY2DIF_CMD_OFFSET = 0xFFC
MAILBOX_PY2DIF_ADDR_OFFSET = 0xFF8
MAILBOX_PY2DIF_DATA_OFFSET = 0xF00

# Microblaze commands
CMD_INTF_SWITCH_CONFIG = 0x1
CMD_READ_INTF_SWITCH_CONFIG = 0xA
CMD_CONFIG_BOOLEAN = 0x2
CMD_READ_BOOLEAN_DIRECTION = 0xC
CMD_CONFIG_PATTERN = 0x3
CMD_CONFIG_FSM = 0x4
CMD_CONFIG_TRACE = 0x5
CMD_RUN = 0xD
CMD_STOP = 0xE
CMD_CHECK_STATUS = 0xF
CMD_STEP = 0xB
CMD_RESET = 0x10

RESET_STATE = 1
READY_STATE = 2
RUNNING_STATE = 4

BOOLEAN_ENGINE_BIT = 0x100
PATTERN_ENGINE_BIT = 0x200
FSM_ENGINE_BIT = 0x400
TRACE_ENGINE_BIT = 0x800

GENERATOR_STATE = {'RESET': RESET_STATE,
                   'READY': READY_STATE,
                   'RUNNING': RUNNING_STATE}
IOSWITCH_BOOLEAN_SELECT = 0
IOSWITCH_PATTERN_SELECT = 1
IOSWITCH_FSM_SELECT = 2
IOSWITCH_DISCONNECT = 3
GENERATOR_ENGINE_DICT = {'BooleanGenerator': BOOLEAN_ENGINE_BIT,
                         'PatternGenerator': PATTERN_ENGINE_BIT,
                         'FSMGenerator': FSM_ENGINE_BIT,
                         'TraceAnalyzer': TRACE_ENGINE_BIT}
LOGICTOOLS_ARDUINO_BIN = "logictools_arduino.bin"

# PYNQ-Z1 specification
ARDUINO = {'ip_name': 'lcp/mb_bram_ctrl',
           'rst_name': 'mb_lcp_reset'}
PYNQZ1_LOGICTOOLS_SPECIFICATION = {'interface_width': 20,
                                   'monitor_width': 64,
                                   'traceable_io_pins': {'D0': 0,
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
                                                         'D19': 19,
                                                         'SDA': 20,
                                                         'SCL': 21
                                                         },
                                   'traceable_tri_states': {'D0': 32,
                                                            'D1': 33,
                                                            'D2': 34,
                                                            'D3': 35,
                                                            'D4': 36,
                                                            'D5': 37,
                                                            'D6': 38,
                                                            'D7': 39,
                                                            'D8': 40,
                                                            'D9': 41,
                                                            'D10': 42,
                                                            'D11': 43,
                                                            'D12': 44,
                                                            'D13': 45,
                                                            'D14': 46,
                                                            'D15': 47,
                                                            'D16': 48,
                                                            'D17': 49,
                                                            'D18': 50,
                                                            'D19': 51,
                                                            'SDA': 52,
                                                            'SCL': 53
                                                            },
                                   'non_traceable_inputs': {'PB0': 20,
                                                            'PB1': 21,
                                                            'PB2': 22,
                                                            'PB3': 23
                                                            },
                                   'non_traceable_outputs': {'LD0': 20,
                                                             'LD1': 21,
                                                             'LD2': 22,
                                                             'LD3': 23
                                                             }
                                   }

# FSM generator constants
FSM_BRAM_ADDR_WIDTH = 13
FSM_MIN_STATE_BITS = 1
FSM_MAX_STATE_BITS = 9
FSM_MIN_NUM_STATES = 2
FSM_MAX_NUM_STATES = 511
FSM_MIN_INPUT_BITS = 1
FSM_MAX_INPUT_BITS = 8
FSM_MAX_STATE_INPUT_BITS = 13
FSM_MIN_OUTPUT_BITS = 1
FSM_MAX_OUTPUT_BITS = 19
FSM_DUMMY_STATE_BRAM_ADDRESS = 0x1FFF

# Pattern generator constants
MAX_NUM_PATTERN_SAMPLES = 4095

# Trace analyzer constants
MAX_NUM_TRACE_SAMPLES = 65535
DEFAULT_NUM_TRACE_SAMPLES = 128

# Clock constants
DEFAULT_CLOCK_FREQUENCY_MHZ = 10
MIN_CLOCK_FREQUENCY_MHZ = 0.25195
MAX_CLOCK_FREQUENCY_MHZ = 100
TRACE_CNTRL_32_ADDR_AP_CTRL = 0x00
TRACE_CNTRL_32_DATA_COMPARE = 0x10
TRACE_CNTRL_32_LENGTH = 0x18
TRACE_CNTRL_64_ADDR_AP_CTRL = 0x00
TRACE_CNTRL_64_DATA_COMPARE_LSW = 0x10
TRACE_CNTRL_64_DATA_COMPARE_MSW = 0x14
TRACE_CNTRL_64_LENGTH = 0x1C

# CData Width to Type Conversion
BYTE_WIDTH_TO_CTYPE = {4: "unsigned int",
                       8: "unsigned long long"}

# CData Width to Type Conversion
BYTE_WIDTH_TO_NPTYPE = {1: np.uint8,
                        2: np.uint16,
                        4: np.uint32,
                        8: np.uint64}
