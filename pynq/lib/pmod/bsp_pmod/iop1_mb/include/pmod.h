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
 * @file pmod.h
 *
 * Common header file for all Pmod IOP applications.
 * This file includes address mappings, API for GPIO/SPI/IIC, and
 * IOP Switch pin mappings and configuration.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a pp  04/29/16 release
 * 1.00a pp  07/05/16 updated to be consistent with arduino io switch driver
 * </pre>
 *
 *****************************************************************************/

#ifndef PMOD_H_
#define PMOD_H_

#include "xparameters.h"
#include "xspi.h"      /* SPI device driver */
#include "xspi_l.h"
#include "xtmrctr.h"
#include "xiic.h"

// Memory map
#define IIC_BASEADDR      XPAR_IIC_0_BASEADDR
// Base address of QSPI[0]
#define SPI_BASEADDR      XPAR_SPI_0_BASEADDR
// Base address of switch
#define SWITCH_BASEADDR   XPAR_IOP1_MB1_PMOD_IO_SWITCH_S00_AXI_BASEADDR
#define GPIO             XPAR_GPIO_0_BASEADDR

// command from A9 to microblaze
#define MAILBOX_CMD_ADDR       (*(volatile u32 *)(0x0000FFFC))

#define MAILBOX_DATA(x)        (*(volatile u32 *)(0x0000F000 +((x)*4)))
#define MAILBOX_DATA_PTR(x)    ( (volatile u32 *)(0x0000F000 +((x)*4)))
 
#define MAILBOX_DATA_FLOAT(x)     (*(volatile float *)(0x0000F000 +((x)*4)))
#define MAILBOX_DATA_FLOAT_PTR(x) ( (volatile float *)(0x0000F000 +((x)*4)))


// Switch mappings used for IOP Switch configuration
#define GPIO_0 0x0
#define GPIO_1 0x1
#define GPIO_2 0x2
#define GPIO_3 0x3
#define GPIO_4 0x4
#define GPIO_5 0x5
#define GPIO_6 0x6
#define GPIO_7 0x7
#define SCL    0x8
#define SDA    0x9
#define SPICLK 0xa
#define MISO   0xb
#define MOSI   0xc
#define SS     0xd
#define PWM	   0xe
#define TIMER  0xf

void delay_us(int usdelay);
void delay_ms(u32 ms_count);

/*
 * SPI API
 * Predefined Control signals macros found in xspi_l.h
 */
#define SPI_INHIBIT (XSP_CR_TRANS_INHIBIT_MASK| \
            XSP_CR_MANUAL_SS_MASK|XSP_CR_ENABLE_MASK|XSP_CR_MASTER_MODE_MASK)
#define SPI_RELEASE (XSP_CR_MANUAL_SS_MASK| \
            XSP_CR_MASTER_MODE_MASK|XSP_CR_ENABLE_MASK)

void spi_init(u32 BaseAddress, u32 clk_phase, u32 clk_polarity);
void spi_transfer(u32 BaseAddress, int bytecount, 
                    u8* readBuffer, u8* writeBuffer);

/* 
 * IIC API
 */
int iic_read(u32 iic_BaseAddress, u32 addr, u8* buffer, u8 numbytes); 
int iic_write(u32 iic_BaseAddress, u32 addr, u8* buffer, u8 numbytes);

/*
 * Logging API for sensor Pmods
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

circular_buffer pmod_log;

int cb_init(circular_buffer *cb, volatile u32* log_start_addr, 
            size_t capacity, size_t sz);
void cb_push_back(circular_buffer *cb, const void *item);
void cb_push_back_float(circular_buffer *cb, const float *item);
void cb_push_incr_ptrs(circular_buffer *cb);


/*
 * Switch Configuration
 */
void config_pmod_switch(char pin0, char pin1, char pin2, char pin3, 
                        char pin4, char pin5, char pin6, char pin7);

/*
 * Initialize all Pmod IO Switch connected devices
 */
void pmod_init(u32 clk_phase, u32 clk_polarity);

#endif
