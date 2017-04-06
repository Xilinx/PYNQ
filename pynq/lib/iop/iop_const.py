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
__email__ = "pynq_support@xilinx.com"


import os

# Microblaze constants
BIN_LOCATION = os.path.dirname(os.path.realpath(__file__))+"/"
MAILBOX_PROGRAM = 'mailbox.bin'
IOP_FREQUENCY = 100000000

# IOP mailbox constants
MAILBOX_OFFSET = 0xF000
MAILBOX_SIZE   = 0x1000
MAILBOX_PY2IOP_CMD_OFFSET  = 0xffc
MAILBOX_PY2IOP_ADDR_OFFSET = 0xff8
MAILBOX_PY2IOP_DATA_OFFSET = 0xf00

# IOP mailbox commands
WRITE_CMD = 0
READ_CMD  = 1
IOP_MMIO_REGSIZE = 0x10000

# IOP Switch Register Map
PMOD_SWITCHCONFIG_BASEADDR     = 0x44A00000
PMOD_SWITCHCONFIG_NUMREGS      = 8

# Each Pmod pin can be tied to digital IO, SPI, or IIC
PMOD_SWCFG_DIO0 = 0
PMOD_SWCFG_DIO1 = 1
PMOD_SWCFG_DIO2 = 2
PMOD_SWCFG_DIO3 = 3
PMOD_SWCFG_DIO4 = 4
PMOD_SWCFG_DIO5 = 5
PMOD_SWCFG_DIO6 = 6
PMOD_SWCFG_DIO7 = 7
PMOD_SWCFG_IIC0_SCL = 8
PMOD_SWCFG_IIC0_SDA = 9

# Switch config - all digital IOs
PMOD_SWCFG_DIOALL = [   PMOD_SWCFG_DIO0,  PMOD_SWCFG_DIO1,
                        PMOD_SWCFG_DIO2,  PMOD_SWCFG_DIO3,
                        PMOD_SWCFG_DIO4,  PMOD_SWCFG_DIO5, 
                        PMOD_SWCFG_DIO6,  PMOD_SWCFG_DIO7]

# Switch config - IIC0, top row
PMOD_SWCFG_IIC0_TOPROW = [  PMOD_SWCFG_DIO0,  PMOD_SWCFG_DIO1,
                            PMOD_SWCFG_IIC0_SCL, PMOD_SWCFG_IIC0_SDA,
                            PMOD_SWCFG_DIO2,  PMOD_SWCFG_DIO3,
                            PMOD_SWCFG_DIO4,  PMOD_SWCFG_DIO5]

# Switch config - IIC0, bottom row
PMOD_SWCFG_IIC0_BOTROW = [  PMOD_SWCFG_DIO0,  PMOD_SWCFG_DIO1,
                            PMOD_SWCFG_DIO2,  PMOD_SWCFG_DIO3,
                            PMOD_SWCFG_DIO4,  PMOD_SWCFG_DIO5, 
                            PMOD_SWCFG_IIC0_SCL, PMOD_SWCFG_IIC0_SDA]

# IIC register map
PMOD_XIIC_0_BASEADDR       = 0x40800000
PMOD_XIIC_DGIER_OFFSET     = 0x1C
PMOD_XIIC_IISR_OFFSET      = 0x20
PMOD_XIIC_IIER_OFFSET      = 0x28
PMOD_XIIC_RESETR_OFFSET    = 0x40
PMOD_XIIC_CR_REG_OFFSET    = 0x100
PMOD_XIIC_SR_REG_OFFSET    = 0x104
PMOD_XIIC_DTR_REG_OFFSET   = 0x108
PMOD_XIIC_DRR_REG_OFFSET   = 0x10C
PMOD_XIIC_ADR_REG_OFFSET   = 0x110
PMOD_XIIC_TFO_REG_OFFSET   = 0x114
PMOD_XIIC_RFO_REG_OFFSET   = 0x118
PMOD_XIIC_TBA_REG_OFFSET   = 0x11C
PMOD_XIIC_RFD_REG_OFFSET   = 0x120
PMOD_XIIC_GPO_REG_OFFSET   = 0x124

# SPI register map
PMOD_SPI_0_BASEADDR        = 0x44A10000
PMOD_XSP_DGIER_OFFSET      = 0x1C
PMOD_XSP_IISR_OFFSET       = 0x20
PMOD_XSP_IIER_OFFSET       = 0x28
PMOD_XSP_SRR_OFFSET        = 0x40
PMOD_XSP_CR_OFFSET         = 0x60
PMOD_XSP_SR_OFFSET         = 0x64
PMOD_XSP_DTR_OFFSET        = 0x68
PMOD_XSP_DRR_OFFSET        = 0x6C
PMOD_XSP_SSR_OFFSET        = 0x70
PMOD_XSP_TFO_OFFSET        = 0x74
PMOD_XSP_RFO_OFFSET        = 0x78

# IO register map
PMOD_DIO_BASEADDR        = 0x40000000
PMOD_DIO_DATA_OFFSET     = 0x0
PMOD_DIO_TRI_OFFSET      = 0x4
PMOD_DIO_DATA2_OFFSET    = 0x8
PMOD_DIO_TRI2_OFFSET     = 0xC
PMOD_DIO_GIE_OFFSET      = 0x11C
PMOD_DIO_ISR_OFFSET      = 0x120
PMOD_DIO_IER_OFFSET      = 0x128

# AXI IO direction constants
PMOD_CFG_DIO_ALLOUTPUT = 0x0
PMOD_CFG_DIO_ALLINPUT  = 0xff

# IOP switch register map
ARDUINO_SWITCHCONFIG_BASEADDR   = 0x44A20000
ARDUINO_SWITCHCONFIG_NUMREGS    = 19

# Each arduino pin can be tied to digital IO, SPI, or IIC
ARDUINO_SWCFG_AIO       =    0x0
ARDUINO_SWCFG_AINT      =    0x0
ARDUINO_SWCFG_SDA       =    0x2
ARDUINO_SWCFG_SCL       =    0x3
ARDUINO_SWCFG_DIO       =    0x0
ARDUINO_SWCFG_DUART     =    0x1
ARDUINO_SWCFG_DINT      =    0x1
ARDUINO_SWCFG_DPWM      =    0x2
ARDUINO_SWCFG_DTIMERG   =    0x3
ARDUINO_SWCFG_DSPICLK   =    0x4
ARDUINO_SWCFG_DMISO     =    0x5
ARDUINO_SWCFG_DMOSI     =    0x6
ARDUINO_SWCFG_DSS       =    0x7
ARDUINO_SWCFG_DTIMERIC  =    0xB

# Switch config - all digital IOs
ARDUINO_SWCFG_DIOALL = [ ARDUINO_SWCFG_AIO, ARDUINO_SWCFG_AIO, 
                         ARDUINO_SWCFG_AIO, ARDUINO_SWCFG_AIO, 
                         ARDUINO_SWCFG_AIO, ARDUINO_SWCFG_AIO, 
                         ARDUINO_SWCFG_DIO, ARDUINO_SWCFG_DIO,
                         ARDUINO_SWCFG_DIO, ARDUINO_SWCFG_DIO,
                         ARDUINO_SWCFG_DIO, ARDUINO_SWCFG_DIO, 
                         ARDUINO_SWCFG_DIO, ARDUINO_SWCFG_DIO,
                         ARDUINO_SWCFG_DIO, ARDUINO_SWCFG_DIO,
                         ARDUINO_SWCFG_DIO, ARDUINO_SWCFG_DIO,
                         ARDUINO_SWCFG_DIO]

# IO register map
ARDUINO_AIO_BASEADDR        = 0x40020000
ARDUINO_AIO_DATA_OFFSET     = 0x8
ARDUINO_AIO_TRI_OFFSET      = 0xc
ARDUINO_DIO_BASEADDR        = 0x40020000
ARDUINO_DIO_DATA_OFFSET     = 0x0
ARDUINO_DIO_TRI_OFFSET      = 0x4
ARDUINO_UART_BASEADDR       = 0x40600000
ARDUINO_UART_DATA_OFFSET    = 0x0
ARDUINO_UART_TRI_OFFSET     = 0x4

# AXI IO direction constants
ARDUINO_CFG_AIO_ALLOUTPUT   = 0x0
ARDUINO_CFG_AIO_ALLINPUT    = 0xffffffff
ARDUINO_CFG_DIO_ALLOUTPUT   = 0x0
ARDUINO_CFG_DIO_ALLINPUT    = 0xffffffff
ARDUINO_CFG_UART_ALLOUTPUT  = 0x0
ARDUINO_CFG_UART_ALLINPUT   = 0xffffffff

# IOP mapping
PMODA = 1
PMODB = 2
ARDUINO = 3

# Stickit Pmod to grove pin mapping
PMOD_GROVE_G1 = [0,4]
PMOD_GROVE_G2 = [1,5]
PMOD_GROVE_G3 = [7,3]
PMOD_GROVE_G4 = [6,2]

# Arduino shield to grove pin mapping
ARDUINO_GROVE_A1     =  [0,1]
ARDUINO_GROVE_A2     =  [2,3]
ARDUINO_GROVE_A3     =  [3,4]
ARDUINO_GROVE_A4     =  [4,5]
ARDUINO_GROVE_I2C    =  []
ARDUINO_GROVE_UART   =  [0,1]
ARDUINO_GROVE_G1     =  [2,3]
ARDUINO_GROVE_G2     =  [3,4]
ARDUINO_GROVE_G3     =  [4,5]
ARDUINO_GROVE_G4     =  [6,7]
ARDUINO_GROVE_G5     =  [8,9]
ARDUINO_GROVE_G6     =  [10,11]
ARDUINO_GROVE_G7     =  [12,13]