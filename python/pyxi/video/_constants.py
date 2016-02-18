"""This module defines constants, functions and objects internally 
used by the video sub-package.
"""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"

from pyxi import OVERLAY

ol = OVERLAY()
ol.add_bitstream('audiovideo.bit')

VDMA_DICT = {
    'BASEADDR': int(ol.get_mmio_base('audiovideo.bit','axi_vdma_0'),16),
    'NUM_FSTORES': 3,
    'INCLUDE_MM2S': 1,
    'INCLUDE_MM2S_DRE':0,
    'M_AXI_MM2S_DATA_WIDTH':32,
    'INCLUDE_S2MM':1,
    'INCLUDE_S2MM_DRE':0,
    'M_AXI_S2MM_DATA_WIDTH':32,
    'INCLUDE_SG':0,
    'ENABLE_VIDPRMTR_READS':1,
    'USE_FSYNC':1,
    'FLUSH_ON_FSYNC':1,
    'MM2S_LINEBUFFER_DEPTH':4096,
    'S2MM_LINEBUFFER_DEPTH':4096,
    'MM2S_GENLOCK_MODE':0,
    'S2MM_GENLOCK_MODE':0,
    'INCLUDE_INTERNAL_GENLOCK':1,
    'S2MM_SOF_ENABLE':1,
    'M_AXIS_MM2S_TDATA_WIDTH':24,
    'S_AXIS_S2MM_TDATA_WIDTH':24,
    'ENABLE_DEBUG_INFO_1':0,
    'ENABLE_DEBUG_INFO_5':0,
    'ENABLE_DEBUG_INFO_6':1,
    'ENABLE_DEBUG_INFO_7':1,
    'ENABLE_DEBUG_INFO_9':0,
    'ENABLE_DEBUG_INFO_13':0,
    'ENABLE_DEBUG_INFO_14':1,
    'ENABLE_DEBUG_INFO_15':1,
    'ENABLE_DEBUG_ALL':0,
    'ADDR_WIDTH':32,
}

VTC_DISPLAY_ADDR = int(ol.get_mmio_base('audiovideo.bit','v_tc_0'),16)
VTC_CAPTURE_ADDR = int(ol.get_mmio_base('audiovideo.bit','v_tc_1'),16)

DYN_CLK_ADDR = int(ol.get_mmio_base('audiovideo.bit','axi_dynclk_0'),16)

GPIO_DICT = {
    'BASEADDR':int(ol.get_mmio_base('audiovideo.bit','axi_gpio_video'),16),
    'INTERRUPT_PRESENT':1,
    'IS_DUAL':1,
}
