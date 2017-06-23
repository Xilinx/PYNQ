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

# Interface mailbox constants
MAILBOX_OFFSET = 0xF000
MAILBOX_SIZE = 0x1000
MAILBOX_PY2DIF_CMD_OFFSET = 0xFFC
MAILBOX_PY2DIF_ADDR_OFFSET = 0xFF8
MAILBOX_PY2DIF_DATA_OFFSET = 0xF00

# Microblaze commands
CMD_GENERATE_DEFAULT_BOOLEAN = 0x001
CMD_GENERATE_USER_BOOLEAN = 0x003
CMD_GENERATE_PATTERN_SINGLE = 0x197
CMD_GENERATE_FSM_START = 0x009
CMD_GENERATE_FSM_STOP = 0x00B
CMD_TRACE_FSM_ONLY = 0x00D

CMD_INTF_SWITCH_CONFIG = 0x1
CMD_READ_INTF_SWITCH_CONFIG = 0xA
CMD_CONFIG_CFG = 0x2
CMD_CONFIG_PG = 0x3
CMD_CONFIG_SMG = 0x4
CMD_CONFIG_TRACE = 0x5
CMD_ARM_CFG = 0x6
CMD_ARM_PG = 0x7
CMD_ARM_SMG = 0x8
CMD_ARM_TRACE = 0x9
CMD_RUN = 0xD
CMD_STOP = 0xE
CMD_RUN_STATUS = 0xF
CMD_READ_CFG_DIRECTION = 0xC

IOSWITCH_BG_SELECT = 0
IOSWITCH_PG_SELECT = 1
IOSWITCH_SMG_SELECT = 2
CMDS_ARM_BUILDER_LIST = [CMD_ARM_CFG, CMD_ARM_PG, CMD_ARM_SMG, CMD_ARM_TRACE]
INTF_MICROBLAZE_BIN = "arduino_intf.bin"

# PYNQ-Z1 specification
ARDUINO = {'ip_name': 'mb_bram_ctrl_3',
           'rst_name': 'mb_3_reset'}
PYNQZ1_DIO_SPECIFICATION = {'clock_mhz': 10,
                            'interface_width': 20,
                            'monitor_width': 64,
                            'traceable_outputs': {'D0': 0,
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
                                                  'A0': 14,
                                                  'A1': 15,
                                                  'A2': 16,
                                                  'A3': 17,
                                                  'A4': 18,
                                                  'A5': 19
                                                  },
                            'traceable_inputs': {'D0': 20,
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
                                                 'D19': 39,
                                                 'A0': 34,
                                                 'A1': 35,
                                                 'A2': 36,
                                                 'A3': 37,
                                                 'A4': 38,
                                                 'A5': 39
                                                 },
                            'traceable_tri_states': {'D0': 42,
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
                                                     'D19': 61,
                                                     'A0': 56,
                                                     'A1': 57,
                                                     'A2': 58,
                                                     'A3': 59,
                                                     'A4': 60,
                                                     'A5': 61
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
FSM_MAX_NUM_STATES = 512
FSM_MIN_INPUT_BITS = 1
FSM_MAX_INPUT_BITS = 8
FSM_MAX_STATE_INPUT_BITS = 13
FSM_MIN_OUTPUT_BITS = 1
FSM_MAX_OUTPUT_BITS = 19

# Pattern generator constants
MAX_NUM_PATTERN_SAMPLES = 4096

# Trace analyzer constants
MAX_NUM_TRACE_SAMPLES = 65536

# CData Width to Type Conversion
BYTE_WIDTH_TO_CTYPE = {4: "unsigned int",
                       8: "unsigned long long"}

# CData Width to Type Conversion
BYTE_WIDTH_TO_NPTYPE = {1: np.uint8,
                        2: np.uint16,
                        4: np.uint32,
                        8: np.uint64}
