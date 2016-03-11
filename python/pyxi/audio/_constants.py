
__author__ = "Giuseppe Natale, Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "xpp_support@xilinx.com"


from pyxi import Overlay


ol = Overlay()
ol.add_bitstream('audiovideo.bit')


AUDIO_BASE_ADDRESS = int(ol.get_mmio_base('audiovideo.bit',
                                          'zybo_audio_ctrl_0'), 16)

AUDIO_GPIO_PIN = ol.get_gpio_base() + 54 + 2

IICPS_INDEX = 1
