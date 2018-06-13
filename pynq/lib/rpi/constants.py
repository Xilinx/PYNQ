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
BSP_LOCATION = os.path.join(BIN_LOCATION, "bsp_iop_rpi")

# PYNQ-Z1 constants
RPI = {'ip_name': 'iop4/mb_bram_ctrl',
       'rst_name': 'mb_iop4_reset',
       'intr_pin_name': 'iop4/dff_en_reset_0/q',
       'intr_ack_name': 'mb_iop4_intr_ack'}

# Raspberry Pi mailbox constants
MAILBOX_OFFSET = 0xF000
MAILBOX_SIZE = 0x1000
MAILBOX_PY2IOP_CMD_OFFSET = 0xffc
MAILBOX_PY2IOP_ADDR_OFFSET = 0xff8
MAILBOX_PY2IOP_DATA_OFFSET = 0xf00

# Raspberry Pi mailbox commands
WRITE_CMD = 0
READ_CMD = 1
IOP_MMIO_REGSIZE = 0x10000

# Raspberry Pi switch register map
RPI_SWITCHCONFIG_BASEADDR = 0x44A20000
RPI_SWITCHCONFIG_NUMREGS = 28

# Each Raspberry Pi pin can be tied to digital IO, SPI, or IIC
RPI_NUM_DIGITAL_PINS = 8
RPI_SWCFG_DIO = 0x0
RPI_SWCFG_INT = 0x1
RPI_SWCFG_PWM = 0x2
RPI_SWCFG_TIMER_G = 0x3
RPI_SWCFG_SPICLK = 0x4
RPI_SWCFG_MISO = 0x5
RPI_SWCFG_MOSI = 0x6
RPI_SWCFG_SS = 0x7
RPI_SWCFG_UART = 0x8
RPI_SWCFG_SDA0 = 0x9
RPI_SWCFG_SCL0 = 0xA
RPI_SWCFG_SDA1 = 0xB
RPI_SWCFG_SCL1 = 0xC
RPI_SWCFG_TIMER_IC = 0xD

# Switch config - all digital IOs
RPI_SWCFG_DIOALL = [RPI_SWCFG_DIO, RPI_SWCFG_DIO, RPI_SWCFG_DIO,
                    RPI_SWCFG_DIO, RPI_SWCFG_DIO, RPI_SWCFG_DIO,
                    RPI_SWCFG_DIO, RPI_SWCFG_DIO, RPI_SWCFG_DIO,
                    RPI_SWCFG_DIO, RPI_SWCFG_DIO, RPI_SWCFG_DIO,
                    RPI_SWCFG_DIO, RPI_SWCFG_DIO, RPI_SWCFG_DIO,
                    RPI_SWCFG_DIO, RPI_SWCFG_DIO, RPI_SWCFG_DIO,
                    RPI_SWCFG_DIO, RPI_SWCFG_DIO, RPI_SWCFG_DIO, RPI_SWCFG_DIO]

# IIC register map
RPI_XIIC_0_BASEADDR = 0x40800000
RPI_XIIC_1_BASEADDR = 0x40810000
RPI_XIIC_DGIER_OFFSET = 0x1C
RPI_XIIC_IISR_OFFSET = 0x20
RPI_XIIC_IIER_OFFSET = 0x28
RPI_XIIC_RESETR_OFFSET = 0x40
RPI_XIIC_CR_REG_OFFSET = 0x100
RPI_XIIC_SR_REG_OFFSET = 0x104
RPI_XIIC_DTR_REG_OFFSET = 0x108
RPI_XIIC_DRR_REG_OFFSET = 0x10C
RPI_XIIC_ADR_REG_OFFSET = 0x110
RPI_XIIC_TFO_REG_OFFSET = 0x114
RPI_XIIC_RFO_REG_OFFSET = 0x118
RPI_XIIC_TBA_REG_OFFSET = 0x11C
RPI_XIIC_RFD_REG_OFFSET = 0x120
RPI_XIIC_GPO_REG_OFFSET = 0x124

# SPI register map
RPI_SPI_0_BASEADDR = 0x44A10000
RPI_SPI_1_BASEADDR = 0x44A00000
RPI_XSP_DGIER_OFFSET = 0x1C
RPI_XSP_IISR_OFFSET = 0x20
RPI_XSP_IIER_OFFSET = 0x28
RPI_XSP_SRR_OFFSET = 0x40
RPI_XSP_CR_OFFSET = 0x60
RPI_XSP_SR_OFFSET = 0x64
RPI_XSP_DTR_OFFSET = 0x68
RPI_XSP_DRR_OFFSET = 0x6C
RPI_XSP_SSR_OFFSET = 0x70
RPI_XSP_TFO_OFFSET = 0x74
RPI_XSP_RFO_OFFSET = 0x78

# IO register map
RPI_DIO_BASEADDR = 0x40020000
RPI_DIO_DATA_OFFSET = 0x0
RPI_DIO_TRI_OFFSET = 0x4

# AXI IO direction constants
RPI_CFG_DIO_ALLOUTPUT = 0x0
RPI_CFG_DIO_ALLINPUT = 0xffffffff
