/******************************************************************************
 *  Copyright (c) 2018, Xilinx, Inc.
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
 * @file gpio.h
 *
 * Header file for GPIO related functions for PYNQ Microblaze, 
 * including the GPIO read and write.
 *
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00  yrq 01/30/18 add protection macro
 *
 * </pre>
 *
 *****************************************************************************/
#ifndef _GPIO_H_
#define _GPIO_H_

#include <xparameters.h>
#ifdef XPAR_XGPIO_NUM_INSTANCES
#include "xgpio_l.h"
#include "xgpio.h"

enum {
GPIO_OUT = 0,
GPIO_IN = 1,
GPIO_INDEX_MIN = 0,
GPIO_INDEX_MAX = 31,
};

/*
 * GPIO bit format:
 * 5:0 low bit - pin index between 0 - 63
 * 11:6 high bit - pin index between 0 - 63
 * 15:12 channel - channel 1 or channel 2
 */
typedef union {
    unsigned short gpio_fd;
    struct {
        unsigned short low : 6, high : 6, channel : 4;
    } gpio_slice;
} gpio_device;

/* 
 * GPIO API
 */
static XGpio gpio_ctrl[XPAR_XGPIO_NUM_INSTANCES];
static gpio_device gpio_dev[XPAR_XGPIO_NUM_INSTANCES];

const unsigned int gpio_base_address[XPAR_XGPIO_NUM_INSTANCES] = {
#ifdef XPAR_GPIO_0_BASEADDR
    XPAR_GPIO_0_BASEADDR,
#endif
#ifdef XPAR_GPIO_1_BASEADDR
    XPAR_GPIO_1_BASEADDR,
#endif
};


int gpio_open_device(unsigned int device);
void gpio_direct(int gpio, unsigned int direction);
int gpio_read(int gpio);
void gpio_write(int gpio, unsigned int data);
void gpio_close(int gpio);

#endif


unsigned int gpio_get_num_devices(void){
#ifdef XPAR_XGPIO_NUM_INSTANCES
    return XPAR_XGPIO_NUM_INSTANCES;
#else
    return 0;
#endif
}


#endif  // _GPIO_H_
