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
#ifndef _XIO_SWITCH_H_
#define _XIO_SWITCH_H_
#ifdef __cplusplus 
extern "C" {
#endif
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
enum io_configuration {
    GPIO      = 0x00,
    UART0_TX  = 0x02,
    UART0_RX  = 0x03,
    SPICLK0   = 0x04,
    MISO0     = 0x05,
    MOSI0     = 0x06,
    SS0       = 0x07,
    SPICLK1   = 0x08,
    MISO1     = 0x09,
    MOSI1     = 0x0A,
    SS1       = 0x0B,
    SDA0      = 0x0C,
    SCL0      = 0x0D,
    SDA1      = 0x0E,
    SCL1      = 0x0F,
    PWM0      = 0x10,
    PWM1      = 0x11,
    PWM2      = 0x12,
    PWM3      = 0x13,
    PWM4      = 0x14,
    PWM5      = 0x15,
    TIMER_G0  = 0x18,
    TIMER_G1  = 0x19,
    TIMER_G2  = 0x1A,
    TIMER_G3  = 0x1B,
    TIMER_G4  = 0x1C,
    TIMER_G5  = 0x1D,
    TIMER_G6  = 0x1E,
    TIMER_G7  = 0x1F,
    UART1_TX  = 0x22,
    UART1_RX  = 0x23,
    TIMER_IC0 = 0x38,
    TIMER_IC1 = 0x39,
    TIMER_IC2 = 0x3A,
    TIMER_IC3 = 0x3B,
    TIMER_IC4 = 0x3C,
    TIMER_IC5 = 0x3D,
    TIMER_IC6 = 0x3E,
    TIMER_IC7 = 0x3F,
};

#define SWITCH_BASEADDR XPAR_IO_SWITCH_0_S_AXI_BASEADDR

// Functions defined in xio_switch.c					
void config_io_switch(int num_of_pins);
void set_pin(int pin_number, u8 pin_type);
void init_io_switch(void);

#ifdef __cplusplus 
}
#endif
#endif // _XIO_SWITCH_H_

