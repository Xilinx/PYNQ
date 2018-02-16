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
import re

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"


# Microblaze constants
BIN_LOCATION = os.path.dirname(os.path.realpath(__file__)) + "/"
BSP_LOCATION = os.path.join(BIN_LOCATION, "bsp_iop_pmod")

# PYNQ-Z1 constants
PMODA = {'ip_name': 'iop_pmoda/mb_bram_ctrl',
         'rst_name': 'mb_iop_pmoda_reset',
         'intr_pin_name': 'iop_pmoda/dff_en_reset_vector_0/q',
         'intr_ack_name': 'mb_iop_pmoda_intr_ack'}
PMODB = {'ip_name': 'iop_pmodb/mb_bram_ctrl',
         'rst_name': 'mb_iop_pmodb_reset',
         'intr_pin_name': 'iop_pmodb/dff_en_reset_vector_0/q',
         'intr_ack_name': 'mb_iop_pmodb_intr_ack'}

# Pmod mailbox constants
MAILBOX_OFFSET = 0xF000
MAILBOX_SIZE = 0x1000
MAILBOX_PY2IOP_CMD_OFFSET = 0xffc
MAILBOX_PY2IOP_ADDR_OFFSET = 0xff8
MAILBOX_PY2IOP_DATA_OFFSET = 0xf00

# Pmod mailbox commands
WRITE_CMD = 0
READ_CMD = 1
IOP_MMIO_REGSIZE = 0x10000

# Pmod switch register map
PMOD_SWITCHCONFIG_BASEADDR = 0x44A20000
PMOD_SWITCHCONFIG_NUMREGS = 2

# Each Pmod pin can be tied to digital IO, SPI, or IIC
PMOD_NUM_DIGITAL_PINS = 8
PMOD_SWCFG_GPIO = 0x0
PMOD_SWCFG_SDA0 = 0xC
PMOD_SWCFG_SCL0 = 0xD

# Switch config - all digital IOs
PMOD_SWCFG_DIOALL = [PMOD_SWCFG_GPIO, PMOD_SWCFG_GPIO,
                     PMOD_SWCFG_GPIO, PMOD_SWCFG_GPIO,
                     PMOD_SWCFG_GPIO, PMOD_SWCFG_GPIO,
                     PMOD_SWCFG_GPIO, PMOD_SWCFG_GPIO]

# Switch config - IIC0, top row
PMOD_SWCFG_IIC0_TOPROW = [PMOD_SWCFG_GPIO, PMOD_SWCFG_GPIO,
                          PMOD_SWCFG_SCL0, PMOD_SWCFG_SDA0,
                          PMOD_SWCFG_GPIO, PMOD_SWCFG_GPIO,
                          PMOD_SWCFG_GPIO, PMOD_SWCFG_GPIO]

# Switch config - IIC0, bottom row
PMOD_SWCFG_IIC0_BOTROW = [PMOD_SWCFG_GPIO, PMOD_SWCFG_GPIO,
                          PMOD_SWCFG_GPIO, PMOD_SWCFG_GPIO,
                          PMOD_SWCFG_GPIO, PMOD_SWCFG_GPIO,
                          PMOD_SWCFG_SCL0, PMOD_SWCFG_SDA0]

# IIC register map
PMOD_XIIC_0_BASEADDR = 0x40800000
PMOD_XIIC_DGIER_OFFSET = 0x1C
PMOD_XIIC_IISR_OFFSET = 0x20
PMOD_XIIC_IIER_OFFSET = 0x28
PMOD_XIIC_RESETR_OFFSET = 0x40
PMOD_XIIC_CR_REG_OFFSET = 0x100
PMOD_XIIC_SR_REG_OFFSET = 0x104
PMOD_XIIC_DTR_REG_OFFSET = 0x108
PMOD_XIIC_DRR_REG_OFFSET = 0x10C
PMOD_XIIC_ADR_REG_OFFSET = 0x110
PMOD_XIIC_TFO_REG_OFFSET = 0x114
PMOD_XIIC_RFO_REG_OFFSET = 0x118
PMOD_XIIC_TBA_REG_OFFSET = 0x11C
PMOD_XIIC_RFD_REG_OFFSET = 0x120
PMOD_XIIC_GPO_REG_OFFSET = 0x124

# SPI register map
PMOD_SPI_0_BASEADDR = 0x44A10000
PMOD_XSP_DGIER_OFFSET = 0x1C
PMOD_XSP_IISR_OFFSET = 0x20
PMOD_XSP_IIER_OFFSET = 0x28
PMOD_XSP_SRR_OFFSET = 0x40
PMOD_XSP_CR_OFFSET = 0x60
PMOD_XSP_SR_OFFSET = 0x64
PMOD_XSP_DTR_OFFSET = 0x68
PMOD_XSP_DRR_OFFSET = 0x6C
PMOD_XSP_SSR_OFFSET = 0x70
PMOD_XSP_TFO_OFFSET = 0x74
PMOD_XSP_RFO_OFFSET = 0x78

# IO register map
PMOD_DIO_BASEADDR = 0x40000000
PMOD_DIO_DATA_OFFSET = 0x0
PMOD_DIO_TRI_OFFSET = 0x4
PMOD_DIO_DATA2_OFFSET = 0x8
PMOD_DIO_TRI2_OFFSET = 0xC
PMOD_DIO_GIE_OFFSET = 0x11C
PMOD_DIO_ISR_OFFSET = 0x120
PMOD_DIO_IER_OFFSET = 0x128

# AXI IO direction constants
PMOD_CFG_DIO_ALLOUTPUT = 0x0
PMOD_CFG_DIO_ALLINPUT = 0xff

# Stickit Pmod to grove pin mapping
PMOD_GROVE_G1 = [0, 4]
PMOD_GROVE_G2 = [1, 5]
PMOD_GROVE_G3 = [7, 3]
PMOD_GROVE_G4 = [6, 2]
