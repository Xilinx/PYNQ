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

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "xpp_support@xilinx.com"


import os

#: Microblaze program location
BIN_LOCATION = os.path.dirname(os.path.realpath(__file__))+"/"
MAILBOX_PROGRAM = 'mailbox.bin'

#: IOP mailbox constants
MAILBOX_OFFSET = 0x7000
MAILBOX_SIZE   = 0x1000
MAILBOX_PY2IOP_CMD_OFFSET  = 0xffc
MAILBOX_PY2IOP_ADDR_OFFSET = 0xff8
MAILBOX_PY2IOP_DATA_OFFSET = 0xf00

#: IOP mailbox commands
WRITE_CMD = 0
READ_CMD  = 1
IOP_MMIO_REGSIZE = 0x8000

#: IOP Switch Register Map
IOPMM_SWITCHCONFIG_BASEADDR    = 0x44A00000
IOPMM_SWITCHCONFIG_IO_0_OFFSET = 0
IOPMM_SWITCHCONFIG_IO_1_OFFSET = 4
IOPMM_SWITCHCONFIG_IO_2_OFFSET = 8
IOPMM_SWITCHCONFIG_IO_3_OFFSET = 12
IOPMM_SWITCHCONFIG_IO_4_OFFSET = 16
IOPMM_SWITCHCONFIG_IO_5_OFFSET = 20
IOPMM_SWITCHCONFIG_IO_6_OFFSET = 24
IOPMM_SWITCHCONFIG_IO_7_OFFSET = 28
IOPMM_SWITCHCONFIG_NUMREGS     = 8

#: Each PMOD Pin can be tied to PMODIO,SPI,IIC pins
IOP_SWCFG_PMODIO0 = 0
IOP_SWCFG_PMODIO1 = 1
IOP_SWCFG_PMODIO2 = 2
IOP_SWCFG_PMODIO3 = 3
IOP_SWCFG_PMODIO4 = 4
IOP_SWCFG_PMODIO5 = 5
IOP_SWCFG_PMODIO6 = 6
IOP_SWCFG_PMODIO7 = 7
IOP_SWCFG_IIC0_SDA = 0x9
IOP_SWCFG_IIC0_SCL = 0x8

#: Switch config - All PMODIOs
IOP_SWCFG_PMODIOALL = [ IOP_SWCFG_PMODIO0,  IOP_SWCFG_PMODIO1,
                        IOP_SWCFG_PMODIO2,  IOP_SWCFG_PMODIO3,
                        IOP_SWCFG_PMODIO4,  IOP_SWCFG_PMODIO5, 
                        IOP_SWCFG_PMODIO6,  IOP_SWCFG_PMODIO7]

#: Switch config - IIC0, Top Row
IOP_SWCFG_IIC0_TOPROW = [   IOP_SWCFG_PMODIO0,  IOP_SWCFG_PMODIO1,
                            IOP_SWCFG_IIC0_SCL, IOP_SWCFG_IIC0_SDA,
                            IOP_SWCFG_PMODIO2,  IOP_SWCFG_PMODIO3,                            
                            IOP_SWCFG_PMODIO4,  IOP_SWCFG_PMODIO5]

#: Switch config - IIC0, Bottom Row
IOP_SWCFG_IIC0_BOTROW = [   IOP_SWCFG_PMODIO0,  IOP_SWCFG_PMODIO1,
                            IOP_SWCFG_PMODIO2,  IOP_SWCFG_PMODIO3,
                            IOP_SWCFG_PMODIO4,  IOP_SWCFG_PMODIO5, 
                            IOP_SWCFG_IIC0_SCL, IOP_SWCFG_IIC0_SDA]

#: IIC register map
IOPMM_XIIC_0_BASEADDR       = 0x40800000
IOPMM_XIIC_DGIER_OFFSET     = 0x1C
IOPMM_XIIC_IISR_OFFSET      = 0x20
IOPMM_XIIC_IIER_OFFSET      = 0x28
IOPMM_XIIC_RESETR_OFFSET    = 0x40
IOPMM_XIIC_CR_REG_OFFSET    = 0x100
IOPMM_XIIC_SR_REG_OFFSET    = 0x104
IOPMM_XIIC_DTR_REG_OFFSET   = 0x108
IOPMM_XIIC_DRR_REG_OFFSET   = 0x10C
IOPMM_XIIC_ADR_REG_OFFSET   = 0x110
IOPMM_XIIC_TFO_REG_OFFSET   = 0x114
IOPMM_XIIC_RFO_REG_OFFSET   = 0x118
IOPMM_XIIC_TBA_REG_OFFSET   = 0x11C
IOPMM_XIIC_RFD_REG_OFFSET   = 0x120
IOPMM_XIIC_GPO_REG_OFFSET   = 0x124

#: SPI register map
IOPMM_SPI_0_BASEADDR        = 0x44A10000
IOPMM_XSP_DGIER_OFFSET      = 0x1C
IOPMM_XSP_IISR_OFFSET       = 0x20
IOPMM_XSP_IIER_OFFSET       = 0x28
IOPMM_XSP_SRR_OFFSET        = 0x40
IOPMM_XSP_CR_OFFSET         = 0x60
IOPMM_XSP_SR_OFFSET         = 0x64
IOPMM_XSP_DTR_OFFSET        = 0x68
IOPMM_XSP_DRR_OFFSET        = 0x6C
IOPMM_XSP_SSR_OFFSET        = 0x70
IOPMM_XSP_TFO_OFFSET        = 0x74
IOPMM_XSP_RFO_OFFSET        = 0x78

#: PMODIO register map
IOPMM_PMODIO_BASEADDR        = 0x40000000
IOPMM_PMODIO_DATA_OFFSET     = 0x0
IOPMM_PMODIO_TRI_OFFSET      = 0x4
IOPMM_PMODIO_DATA2_OFFSET    = 0x8
IOPMM_PMODIO_TRI2_OFFSET     = 0xC
IOPMM_PMODIO_GIE_OFFSET      = 0x11C
IOPMM_PMODIO_ISR_OFFSET      = 0x120
IOPMM_PMODIO_IER_OFFSET      = 0x128

# AXI GPIO direction constants
IOCFG_PMODIO_ALLOUTPUT = 0x0
IOCFG_PMODIO_ALLINPUT  = 0xff

# Stickit PMOD to Grove pin mapping
STICKIT_PINS_GR  = {1: [0,4],
                    2: [1,5],
                    3: [7,3],
                    4: [6,2]}