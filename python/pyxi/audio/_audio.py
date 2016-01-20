"""This module defines constants, functions and objects internally 
used by the audio sub-package.
"""


__author__      = "Giuseppe Natale"
__copyright__   = "Copyright 2015, Xilinx"
__version__     = "0.1"
__maintainer__  = "Giuseppe Natale"
__email__       = "giuseppe.natale@xilinx.com"

audio_base_address = 0x60000000

audio_emio_pin = 56

iicps_dict = {
    'BASEADDR':0xE0005000,
    'I2C_CLK_FREQ_HZ':108333336,
}
