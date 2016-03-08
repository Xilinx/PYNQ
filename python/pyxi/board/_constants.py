"""This module defines constants internally used by the onboard gpios."""

from pyxi import Overlay

ol = Overlay()
ol.add_bitstream('pmod.bit')

BTNS_ADDR = int(ol.get_mmio_base('pmod.bit','btns'),16)
SWS_ADDR  = int(ol.get_mmio_base('pmod.bit','sws'),16)
LEDS_ADDR = int(ol.get_mmio_base('pmod.bit','leds'),16)
LEDS_OFFSET = 0x8
