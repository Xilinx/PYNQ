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

__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "xpp_support@xilinx.com"


VDMA_DICT = {
    'BASEADDR': 0x43000000,
    'NUM_FSTORES': 3,
    'INCLUDE_MM2S': 1,
    'INCLUDE_MM2S_DRE': 0,
    'M_AXI_MM2S_DATA_WIDTH': 32,
    'INCLUDE_S2MM': 1,
    'INCLUDE_S2MM_DRE': 0,
    'M_AXI_S2MM_DATA_WIDTH': 32,
    'INCLUDE_SG': 0,
    'ENABLE_VIDPRMTR_READS': 1,
    'USE_FSYNC': 1,
    'FLUSH_ON_FSYNC': 1,
    'MM2S_LINEBUFFER_DEPTH': 4096,
    'S2MM_LINEBUFFER_DEPTH': 4096,
    'MM2S_GENLOCK_MODE': 0,
    'S2MM_GENLOCK_MODE': 0,
    'INCLUDE_INTERNAL_GENLOCK': 1,
    'S2MM_SOF_ENABLE': 1,
    'M_AXIS_MM2S_TDATA_WIDTH': 24,
    'S_AXIS_S2MM_TDATA_WIDTH': 24,
    'ENABLE_DEBUG_INFO_1': 0,
    'ENABLE_DEBUG_INFO_5': 0,
    'ENABLE_DEBUG_INFO_6': 1,
    'ENABLE_DEBUG_INFO_7': 1,
    'ENABLE_DEBUG_INFO_9': 0,
    'ENABLE_DEBUG_INFO_13': 0,
    'ENABLE_DEBUG_INFO_14': 1,
    'ENABLE_DEBUG_INFO_15': 1,
    'ENABLE_DEBUG_ALL': 0,
    'ADDR_WIDTH': 32,
}

VTC_DISPLAY_ADDR = 0x43C00000
VTC_CAPTURE_ADDR = 0x43C20000
DYN_CLK_ADDR = 0x43C10000

GPIO_DICT = {
    'BASEADDR': 0x41230000,
    'INTERRUPT_PRESENT': 1,
    'IS_DUAL': 1,
}

MAX_FRAME_WIDTH = 1920
MAX_FRAME_HEIGHT = 1080
