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

# DIF mailbox constants
MAILBOX_OFFSET = 0xF000
MAILBOX_SIZE   = 0x1000
MAILBOX_PY2DIF_CMD_OFFSET  = 0xFFC
MAILBOX_PY2DIF_ADDR_OFFSET = 0xFF8
MAILBOX_PY2DIF_DATA_OFFSET = 0xF00

# Trace controller related constants
XTRACE_CNTRL_BASEADDR = 0x44A20000
XTRACE_CNTRL_ADDR_AP_CTRL = 0x00
XTRACE_CNTRL_LENGTH = 0x1C
XTRACE_CNTRL_SAMPLE_RATE = 0x24
XTRACE_CNTRL_DATA_COMPARE_MSW = 0x14
XTRACE_CNTRL_DATA_COMPARE_LSW = 0x10

XTRACE_CNTRL_UNLOCK_DEVCFG_SLCR = 0xF8000008
XTRACE_CNTRL_LEVEL_SHIFTER = 0xF8000900
XTRACE_CNTRL_CLK0_CTRL = 0xF8000170
XTRACE_CNTRL_CLK1_CTRL = 0xF8000180
XTRACE_CNTRL_CLK2_CTRL = 0xF8000190
XTRACE_CNTRL_CLK3_CTRL = 0xF80001A0
XTRACE_CNTRL_LOCK_DEVCFG_SLCR = 0xF8000004
XTRACE_CNTRL_12_5_MHZ = 0x00A00800
XTRACE_CNTRL_25_0_MHZ = 0x00A00400
XTRACE_CNTRL_50_0_MHZ = 0x00500400