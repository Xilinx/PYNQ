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


import math
from . import Rpi
from . import RPI_SWCFG_SDA1
from . import RPI_SWCFG_SCL1


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


RPI_TOUCHPAD_PROGRAM = "rpi_touchpad.bin"
CONFIG_IOP_SWITCH = 0x1
GET_TOUCHPAD_DATA = 0x3
RESET = 0xF
PIN_MAPPING = {'circle': 0,
               'cross': 1,
               'square': 2,
               'r': 3,
               'home': 4,
               '+': 5,
               '-': 6,
               'l': 7,
               'down': 8,
               'right': 9,
               'up': 10,
               'left': 11,
               'power': 12,
               'rpi': 13,
               'logo': 14,
               'triangle': 15
               }


def _reg2int(reg_value, key_number):
    """Converts the key value from 32-bit register.

    Parameters
    ----------
    reg_value : int
        The 32-bit register value.
    key_number : int
        The number of the key on the touchpad, from 0 - 15.

    Returns
    -------
    int
        A signed integer translated from the register value.

    """
    return "{0:b}".format(reg_value).zfill(16)[-(key_number+1)]


class Rpi_Touchpad(object):
    """This class controls the Raspberry Pi touch keypad.

    The Raspberry Pi touch keypad is based on TONTEK TonTouch touch pad
    detector IC TTP229-LSF, supports up to 16 keys with adjustable sensitivity
    and built-in LD0. Touch keypad is read only, and has IIC interface
    connected to SDA1 and SCL1 on the Raspberry Pi interface.
    Data sheet of the detector IC can be found at
    http://www.tontek.com.tw/download.asp?sn=737

    Attributes
    ----------
    microblaze : Rpi
        Microblaze processor instance used by this module.
    keys : list
        List of the available keys detectable by the touchpad.
        
    """
    def __init__(self, mb_info):
        """Return a new instance of a Raspberry Pi touch keypad.

        Parameters
        ----------
        mb_info : dict
            A dictionary storing Microblaze information, such as the
            IP name and the reset name.

        """
        self.microblaze = Rpi(mb_info, RPI_TOUCHPAD_PROGRAM)
        self.microblaze.write_blocking_command(CONFIG_IOP_SWITCH)
        self.keys = list(PIN_MAPPING.keys())

    def reset(self):
        """Reset the module.

        This method will also reset the pin selection of the microblaze.
        This method is recommended to be called at the end of the program so
        users will not have trouble using PMODA modules later.

        Returns
        -------
        None
        
        """
        self.microblaze.write_blocking_command(RESET)

    def read(self, key_name):
        """Read the value associated with a key.

        The I2C will read 2 bytes of data: Data_0 and Data_1.
        Data_0: B7~B0 is TP0~TP7 on/off status. 0 is key off, 1 is key on.
        Data_1: B7~B0 is TP8~TP15 on/off status. 0 is key off, 1 is key on.

        Parameters
        ----------
        key_name: str
            The name of the key on the touchpad.

        Returns
        -------
        int
            An integer indicating whether or not the key is on.

        """
        if key_name not in self.keys:
            raise ValueError("Valid key names are {}.".format(self.keys))

        self.microblaze.write_blocking_command(GET_TOUCHPAD_DATA)
        reg_value = self.microblaze.read_mailbox(0)
        key_number = PIN_MAPPING[key_name]
        return _reg2int(reg_value, key_number)
