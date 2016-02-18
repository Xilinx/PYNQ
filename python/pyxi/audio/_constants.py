"""This module defines constants, functions and objects internally 
used by the audio sub-package.
"""


__author__      = "Giuseppe Natale, Yun Rock Qu"
__copyright__   = "Copyright 2015, Xilinx"
__email__       = "giuseppe.natale@xilinx.com"


from pyxi import OVERLAY

ol = OVERLAY()
ol.add_bitstream('audiovideo.bit')

AUDIO_BASE_ADDRESS = int(ol.get_mmio_base('audiovideo.bit',\
                                            'zybo_audio_ctrl_0'),16)

AUDIO_GPIO_PIN = ol.get_gpio_base() + 56

IICPS_INDEX = 1
