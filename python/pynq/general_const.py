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

__author__      = "Yun Rock Qu"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"


import os

# GPIO constants
GPIO_MIN_USER_PIN = 54

# Overlay constants
BS_SEARCH_PATH = os.path.dirname(os.path.realpath(__file__))+"/bitstream/"
BS_BOOT = BS_SEARCH_PATH + 'base.bit'
TCL_BOOT = BS_SEARCH_PATH + 'base.tcl'
BS_IS_PARTIAL = "/sys/devices/soc0/amba/f8007000.devcfg/is_partial_bitstream"
BS_XDEVCFG = "/dev/xdevcfg"

# MMIO constants
MMIO_FILE_NAME = '/dev/mem'
MMIO_WORD_LENGTH = 4
MMIO_WORD_MASK = ~(MMIO_WORD_LENGTH - 1)

# Clock constants
SRC_CLK_MHZ              = 50.000000
SCLR_BASE_ADDRESS        = 0xf8000000
ARM_PLL_DIV_OFFSET       = 0x100
DDR_PLL_DIV_OFFSET       = 0x104
IO_PLL_DIV_OFFSET        = 0x108
PLL_DIV_BIT_OFFSET       = 12
PLL_DIV_BIT_WIDTH        = 7
ARM_CLK_REG_OFFSET       = 0X120
ARM_CLK_SEL_BIT_OFFSET   = 4
ARM_CLK_SEL_BIT_WIDTH    = 2
ARM_CLK_DIV_BIT_OFFSET   = 8
ARM_CLK_DIV_BIT_WIDTH    = 6
DEFAULT_CLK_MHZ          = [100.000000,142.857143,200.000000,166.666667]
CLK_CTRL_REG_OFFSET      = [0x170,0x180,0x190,0x1A0]
CLK_SRC_BIT_OFFSET       = 4
CLK_SRC_BIT_WIDTH        = 2
CLK_DIV0_BIT_OFFSET      = 8
CLK_DIV0_BIT_WIDTH       = 6
CLK_DIV1_BIT_OFFSET      = 20
CLK_DIV1_BIT_WIDTH       = 6