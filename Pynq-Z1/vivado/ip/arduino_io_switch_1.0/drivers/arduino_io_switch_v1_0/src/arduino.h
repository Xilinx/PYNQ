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
 * @file arduino.h
 *
 * Common header file for all Arduido IOP applications.
 * This file includes address mappings, API for GPIO/SPI/IIC, and
 * IOP Switch pin mappings and configuration.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a pp  06/09/16 release
 * 1.00b yrq 09/06/16 adjust format
 *
 * </pre>
 *
 *****************************************************************************/
#ifndef SRC_ARDUINO_H_
#define SRC_ARDUINO_H_

#include "xparameters.h"
#include "xtmrctr.h"
#include "xiic.h"
#include "xspi_l.h"

/*
 * Memory map
 * IIC base address is defined in respective application
 * Base address of shared SPI which uses Digital pins 13-10
 */
#define SHARED_SPI_BASEADDR      XPAR_SPI_1_BASEADDR
// Base address of direct SPI which uses ISP connector
#define DIRECT_SPI_BASEADDR      XPAR_SPI_0_BASEADDR
// Base address of switch
#define SWITCH_BASEADDR   XPAR_IOP3_ARDUINO_IO_SWITCH_0_S_AXI_BASEADDR

// command from A9 to microblaze
#define MAILBOX_CMD_ADDR       (*(volatile u32 *)(0x0000FFFC))

#define MAILBOX_DATA(x)        (*(volatile u32 *)(0x0000F000 +((x)*4)))
#define MAILBOX_DATA_PTR(x)    ( (volatile u32 *)(0x0000F000 +((x)*4)))

#define MAILBOX_DATA_FLOAT(x)     (*(volatile float *)(0x0000F000 +((x)*4)))
#define MAILBOX_DATA_FLOAT_PTR(x) ( (volatile float *)(0x0000F000 +((x)*4)))

// Switch mappings used for Arduino Switch configuration
#define A_GPIO  0x0
#define A_INT   0x0
#define A_SDA   0x2
#define A_SCL   0x3

#define D_GPIO      0x0
#define D_UART      0x1
#define D_INT       0x1
#define D_PWM       0x2
#define D_TIMER_G   0x3
#define D_SPICLK    0x4
#define D_MISO      0x5
#define D_MOSI      0x6
#define D_SS        0x7
#define D_TIMER_IC  0xb

void delay_us(int usdelay);
void delay_ms(int ms_count);

// SPI API
#define SPI_INHIBIT (XSP_CR_TRANS_INHIBIT_MASK| \
            XSP_CR_MANUAL_SS_MASK|XSP_CR_ENABLE_MASK|XSP_CR_MASTER_MODE_MASK)
#define SPI_RELEASE (XSP_CR_MANUAL_SS_MASK| \
            XSP_CR_MASTER_MODE_MASK|XSP_CR_ENABLE_MASK)

void spi_init(u32 BaseAddress, u32 clk_phase, u32 clk_polarity);
void spi_transfer(u32 BaseAddress, int bytecount,
                    u8* readBuffer, u8* writeBuffer);

// IIC API
int iic_read(u32 iic_baseaddr, u32 addr, u8* buffer, u8 numbytes);
int iic_write(u32 iic_baseaddr, u32 addr, u8* buffer, u8 numbytes);

/*
 * Logging API
 * Using mailbox as a circular buffer
 * Modified to match mailbox API
 */
typedef struct circular_buffer
{
  volatile void *buffer;     // data buffer
  void *buffer_end;          // end of data buffer
  size_t capacity;           // maximum number of items in the buffer
  size_t count;              // number of items in the buffer
  size_t sz;                 // size of each item in the buffer
  volatile void *head;       // pointer to head
  volatile void *tail;       // pointer to tail
} circular_buffer;

circular_buffer arduino_log;

int cb_init(circular_buffer *cb, volatile u32* log_start_addr,
            size_t capacity, size_t sz);
void cb_push_back(circular_buffer *cb, const void *item);
void cb_push_back_float(circular_buffer *cb, const float *item);
void cb_push_incr_ptrs(circular_buffer *cb);


// Switch configuration
void config_arduino_switch(char A_pin0, char A_pin1, char A_pin2, 
                           char A_pin3, char A_pin4, char A_pin5, 
                           char D_pin0_1,
                           char D_pin2, char D_pin3, char D_pin4, 
                           char D_pin5, char D_pin6, char D_pin7, 
                           char D_pin8, char D_pin9, char D_pin10, 
                           char D_pin11, char D_pin12, char D_pin13);

// Initialize all Arduino IO Switch connected devices
void arduino_init(u32 shared_clk_phase, u32 shared_clk_polarity, 
                  u32 direct_clk_phase, u32 direct_clk_polarity);

#endif /* SRC_ARDUINO_SWITCH_H_ */
