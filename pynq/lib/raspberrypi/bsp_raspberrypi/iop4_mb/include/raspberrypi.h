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
 * @file raspberrypi.h
 *
 * Common header file for all Raspberry Pi IOP applications.
 * This file includes address mappings, API for GPIO/SPI/IIC, and
 * IOP Switch pin mappings and configuration.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a pp  10/09/17 release
 *
 * </pre>
 *
 *****************************************************************************/
#ifndef SRC_RASPBERRYPI_H_
#define SRC_RASPBERRYPI_H_

#include "xparameters.h"
#include "xtmrctr.h"
#include "xiic.h"
#include "xspi_l.h"

/*
 * Memory map
 */
// Base address of SPI0 which uses GPIO 7, 8, 9, 10, 11 
#define SPI0_BASEADDR      XPAR_SPI_0_BASEADDR
// Base address of SPI1 which uses GPIO 16, 19, 20, 21
#define SPI1_BASEADDR      XPAR_SPI_1_BASEADDR
// Base address of switch
#define SWITCH_BASEADDR   XPAR_IOP4_RP_IO_SWITCH_0_S_AXI_BASEADDR

// command from A9 to microblaze
#define MAILBOX_CMD_ADDR       (*(volatile u32 *)(0x0000FFFC))

#define MAILBOX_DATA(x)        (*(volatile u32 *)(0x0000F000 +((x)*4)))
#define MAILBOX_DATA_PTR(x)    ( (volatile u32 *)(0x0000F000 +((x)*4)))

#define MAILBOX_DATA_FLOAT(x)     (*(volatile float *)(0x0000F000 +((x)*4)))
#define MAILBOX_DATA_FLOAT_PTR(x) ( (volatile float *)(0x0000F000 +((x)*4)))

// Switch mappings used for raspberry pi Switch configuration
#define GPIO      0x0
#define INT       0x1
#define PWM       0x2
#define TIMER_G   0x3
#define SPICLK    0x4
#define MISO      0x5
#define MOSI      0x6
#define SS        0x7
#define UART      0x8
#define SDA0	  0x9
#define SCL0	  0xA
#define SDA1	  0xB
#define SCL1	  0xC
#define TIMER_IC  0xD

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

circular_buffer raspberrypi_log;

int cb_init(circular_buffer *cb, volatile u32* log_start_addr,
            size_t capacity, size_t sz);
void cb_push_back(circular_buffer *cb, const void *item);
void cb_push_back_float(circular_buffer *cb, const float *item);
void cb_push_incr_ptrs(circular_buffer *cb);


// Switch configuration
void config_raspberrypi_switch(char GPIO0, char GPIO1, char GPIO2,
                           char GPIO3, char GPIO4, char GPIO5,
                           char GPIO6, char GPIO7, char GPIO8,
                           char GPIO9, char GPIO10, char GPIO11,
                           char GPIO12, char GPIO13, char GPIO14,
                           char GPIO15, char GPIO16, char GPIO17,
                           char GPIO18, char GPIO19, char GPIO20,
                           char GPIO21, char GPIO22, char GPIO23,
                           char GPIO24, char GPIO25, char GPIO26, char GPIO27);

// Initialize all SPI devices connected to raspberry pi IO Switch s
void raspberrypi_init(u32 spi0_clk_phase, u32 spi0_clk_polarity,
                  u32 spi1_clk_phase, u32 spi1_clk_polarity);

#endif /* SRC_RASPBERRYPI_SWITCH_H_ */
