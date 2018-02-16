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

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


# Microblaze constants
BIN_LOCATION = os.path.dirname(os.path.realpath(__file__)) + "/"
BSP_LOCATION = os.path.join(BIN_LOCATION, "bsp_iop_arduino")

# PYNQ-Z1 constants
ARDUINO = {'ip_name': 'iop3/mb_bram_ctrl',
           'rst_name': 'mb_iop3_reset',
           'intr_pin_name': 'iop3/dff_en_reset_vector_0/q',
           'intr_ack_name': 'mb_iop3_intr_ack'}

# Arduino mailbox constants
MAILBOX_OFFSET = 0xF000
MAILBOX_SIZE = 0x1000
MAILBOX_PY2IOP_CMD_OFFSET = 0xffc
MAILBOX_PY2IOP_ADDR_OFFSET = 0xff8
MAILBOX_PY2IOP_DATA_OFFSET = 0xf00

# Arduino mailbox commands
WRITE_CMD = 0
READ_CMD = 1
IOP_MMIO_REGSIZE = 0x10000

# Arduino switch register map
ARDUINO_SWITCHCONFIG_BASEADDR = 0x44A20000
ARDUINO_SWITCHCONFIG_NUMREGS = 5

# Each arduino pin can be tied to digital IO, SPI, or IIC
ARDUINO_NUM_DIGITAL_PINS = 14
ARDUINO_NUM_ANALOG_PINS = 6
ARDUINO_SWCFG_GPIO = 0x0
ARDUINO_SWCFG_UART_TX = 0x2
ARDUINO_SWCFG_UART_RX = 0x3
ARDUINO_SWCFG_SPICLK0 = 0x4
ARDUINO_SWCFG_MISO0 = 0x5
ARDUINO_SWCFG_MOSI0 = 0x6
ARDUINO_SWCFG_SS0 = 0x7
ARDUINO_SWCFG_PWM0 = 0x10
ARDUINO_SWCFG_TIMER_G0 = 0x18
ARDUINO_SWCFG_TIMER_G1 = 0x19
ARDUINO_SWCFG_TIMER_G2 = 0x1A
ARDUINO_SWCFG_TIMER_G3 = 0x1B
ARDUINO_SWCFG_TIMER_G4 = 0x1C
ARDUINO_SWCFG_TIMER_G5 = 0x1D
ARDUINO_SWCFG_TIMER_G6 = 0x1E
ARDUINO_SWCFG_TIMER_G7 = 0x1F
ARDUINO_SWCFG_TIMER_IC0 = 0x38

# Switch config - all digital IOs
ARDUINO_SWCFG_DIOALL = [ARDUINO_SWCFG_GPIO, ARDUINO_SWCFG_GPIO,
                        ARDUINO_SWCFG_GPIO, ARDUINO_SWCFG_GPIO,
                        ARDUINO_SWCFG_GPIO, ARDUINO_SWCFG_GPIO,
                        ARDUINO_SWCFG_GPIO, ARDUINO_SWCFG_GPIO,
                        ARDUINO_SWCFG_GPIO, ARDUINO_SWCFG_GPIO,
                        ARDUINO_SWCFG_GPIO, ARDUINO_SWCFG_GPIO,
                        ARDUINO_SWCFG_GPIO, ARDUINO_SWCFG_GPIO,
                        ARDUINO_SWCFG_GPIO, ARDUINO_SWCFG_GPIO,
                        ARDUINO_SWCFG_GPIO, ARDUINO_SWCFG_GPIO,
                        ARDUINO_SWCFG_GPIO, ARDUINO_SWCFG_GPIO]

# IO register map
ARDUINO_DIO_BASEADDR = 0x40020000
ARDUINO_DIO_DATA_OFFSET = 0x0
ARDUINO_DIO_TRI_OFFSET = 0x4
ARDUINO_UART_BASEADDR = 0x40600000
ARDUINO_UART_DATA_OFFSET = 0x0
ARDUINO_UART_TRI_OFFSET = 0x4

# AXI IO direction constants
ARDUINO_CFG_DIO_ALLOUTPUT = 0x0
ARDUINO_CFG_DIO_ALLINPUT = 0xffffffff
ARDUINO_CFG_UART_ALLOUTPUT = 0x0
ARDUINO_CFG_UART_ALLINPUT = 0xffffffff

# Arduino shield to grove pin mapping
ARDUINO_GROVE_A1 = [0, 1]
ARDUINO_GROVE_A2 = [2, 3]
ARDUINO_GROVE_A3 = [3, 4]
ARDUINO_GROVE_A4 = [4, 5]
ARDUINO_GROVE_I2C = []
ARDUINO_GROVE_UART = [0, 1]
ARDUINO_GROVE_G1 = [2, 3]
ARDUINO_GROVE_G2 = [3, 4]
ARDUINO_GROVE_G3 = [4, 5]
ARDUINO_GROVE_G4 = [6, 7]
ARDUINO_GROVE_G5 = [8, 9]
ARDUINO_GROVE_G6 = [10, 11]
ARDUINO_GROVE_G7 = [12, 13]
