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
 * @file gpio.c
 *
 * Implementing GPIO related functions for PYNQ Microblaze, 
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
#include <xparameters.h>
#include "gpio.h"

#ifdef XPAR_XGPIO_NUM_INSTANCES
/************************** Function Definitions ***************************/
gpio gpio_open_device(unsigned int device){
    int status;
    u16 dev_id;
    gpio mod_id;

    dev_id = (u16)device;
#ifdef XPAR_GPIO_0_BASEADDR
    if (device == XPAR_GPIO_0_BASEADDR){
        dev_id = 0;
    }
#endif
#ifdef XPAR_GPIO_1_BASEADDR
    if (device == XPAR_GPIO_1_BASEADDR){
        dev_id = 1;
    }
#endif

    status = XGpio_Initialize(&xgpio[dev_id], dev_id);
    if (status != XST_SUCCESS) {
        mod_id.fd = -1;
        return mod_id;
    }

    mod_id._gpio.valid = 0;
    mod_id._gpio.low = GPIO_INDEX_MIN;
    mod_id._gpio.high = GPIO_INDEX_MAX;
    mod_id._gpio.channel = 1;
    mod_id._gpio.device = dev_id;
    return mod_id;
}


gpio gpio_configure(gpio mod_id, unsigned int low, unsigned int high, 
                    unsigned int channel){
    mod_id._gpio.low = low;
    mod_id._gpio.high = high;
    mod_id._gpio.channel = channel;
    return mod_id;
}


void gpio_set_direction(gpio mod_id, unsigned int direction){
    unsigned int mask, low, high, channel, dev_id, direction_mask;
    low = mod_id._gpio.low;
    high = mod_id._gpio.high;
    channel = mod_id._gpio.channel;
    dev_id = mod_id._gpio.device;

    mask = (0x1 << (high + 1)) - (0x1 << low);
    direction_mask = XGpio_GetDataDirection(&xgpio[dev_id], channel);
    if (direction){
        // GPIO selected as input
        direction_mask |= mask;
    }else{
        // GPIO selected as output
        direction_mask &= ~mask;
    }
    XGpio_SetDataDirection(&xgpio[dev_id], channel, direction_mask);
}


int gpio_read(gpio mod_id){
    unsigned int read_value, mask, low, high, channel, dev_id;
    low = mod_id._gpio.low;
    high = mod_id._gpio.high;
    channel = mod_id._gpio.channel;
    dev_id = mod_id._gpio.device;

    mask = (0x1 << (high + 1)) - (0x1 << low);
    read_value = XGpio_DiscreteRead(&xgpio[dev_id], channel);
    return (read_value & mask) >> low;
}


void gpio_write(gpio mod_id, unsigned int data){
    unsigned int write_value, mask, low, high, channel, dev_id;
    low = mod_id._gpio.low;
    high = mod_id._gpio.high;
    channel = mod_id._gpio.channel;
    dev_id = mod_id._gpio.device;

    write_value = XGpio_DiscreteRead(&xgpio[dev_id], channel);
    mask = (0x1 << (high + 1)) - (0x1 << low);
    write_value = (write_value & mask) | (data << low);
    XGpio_DiscreteWrite(&xgpio[dev_id], channel, write_value);
}


void gpio_close(gpio mod_id){
    unsigned int mask, low, high, channel, dev_id;
    low = mod_id._gpio.low;
    high = mod_id._gpio.high;
    channel = mod_id._gpio.channel;
    dev_id = mod_id._gpio.device;
    mask = (0x1 << (high + 1)) - (0x1 << low);
    XGpio_DiscreteClear(&xgpio[dev_id], channel, mask);
}


#endif