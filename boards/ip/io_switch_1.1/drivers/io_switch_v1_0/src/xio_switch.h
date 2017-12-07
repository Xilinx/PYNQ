/******************************************************************************
 *  Copyright (c) 2016, Xilinx, Inc.
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *
 *  1.  Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *
 *  2.  Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *  3.  Neither the name of the copyright holder nor the names of its
 *      contributors may be used to endorse or promote products derived from
 *      this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 *  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 *  OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 *  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 *  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *****************************************************************************/
/******************************************************************************
 *
 *
 * @file xio_switch.h
 *
 * Common header file for all pmod, arduino, and raspberrypi IOP applications.
 *
 * </pre>
 *
 *****************************************************************************/

/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"
#include "xparameters.h"
#include "xil_io.h"

#define IO_SWITCH_S_AXI_SLV_REG0_OFFSET 0
#define IO_SWITCH_S_AXI_SLV_REG1_OFFSET 4
#define IO_SWITCH_S_AXI_SLV_REG2_OFFSET 8
#define IO_SWITCH_S_AXI_SLV_REG3_OFFSET 12
#define IO_SWITCH_S_AXI_SLV_REG4_OFFSET 16
#define IO_SWITCH_S_AXI_SLV_REG5_OFFSET 20
#define IO_SWITCH_S_AXI_SLV_REG6_OFFSET 24
#define IO_SWITCH_S_AXI_SLV_REG7_OFFSET 28
#define IO_SWITCH_S_AXI_SLV_REG8_OFFSET 32

// Switch mappings used for the io Switch configuration
#define GPIO      0x00
#define UART0_TX  0x02
#define UART0_RX  0x03
#define SPICLK0   0x04
#define MISO0     0x05
#define MOSI0     0x06
#define SS0       0x07
#define SPICLK1   0x08
#define MISO1     0x09
#define MOSI1     0x0A
#define SS1       0x0B
#define SDA0	  0x0C
#define SCL0	  0x0D
#define SDA1	  0x0E
#define SCL1	  0x0F
#define PWM0      0x10
#define PWM1      0x11
#define PWM2      0x12
#define PWM3      0x13
#define PWM4      0x14
#define PWM5      0x15
#define TIMER_G0  0x18
#define TIMER_G1  0x19
#define TIMER_G2  0x1A
#define TIMER_G3  0x1B
#define TIMER_G4  0x1C
#define TIMER_G5  0x1D
#define TIMER_G6  0x1E
#define TIMER_G7  0x1F
#define UART1_TX  0x22
#define UART1_RX  0x23
#define TIMER_IC0 0x38
#define TIMER_IC1 0x39
#define TIMER_IC2 0x3A
#define TIMER_IC3 0x3B
#define TIMER_IC4 0x3C
#define TIMER_IC5 0x3D
#define TIMER_IC6 0x3E
#define TIMER_IC7 0x3F

#define SWITCH_BASEADDR XPAR_IO_SWITCH_0_S_AXI_BASEADDR

// Functions defined in xio_switch.c					
void config_io_switch(int num_of_pins);
void set_pin(int pin_number, u8 pin_type);
void init_io_switch(void);
