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
int gpio_open_device(unsigned int device){
    int status;
    u16 dev_id;
    int i;

    dev_id = (u16)device;
    for (i=0; i<(signed)XPAR_XGPIO_NUM_INSTANCES; i++){
        if (device == gpio_base_address[i]){
            dev_id = (u16)i;
            break;
        }
    }

    status = XGpio_Initialize(&gpio_ctrl[dev_id], dev_id);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    gpio_dev[dev_id].gpio_fd = dev_id;
    gpio_dev[dev_id].gpio_slice.low = GPIO_INDEX_MIN;
    gpio_dev[dev_id].gpio_slice.high = GPIO_INDEX_MAX;
    gpio_dev[dev_id].gpio_slice.channel = 1;
    return (int)dev_id;
}


void gpio_configure(int gpio, unsigned int low, unsigned int high, 
                   unsigned int channel){
    gpio_dev[gpio].gpio_slice.low = low;
    gpio_dev[gpio].gpio_slice.high = high;
    gpio_dev[gpio].gpio_slice.channel = channel;
}


void gpio_set_direction(int gpio, unsigned int direction){
    unsigned int channel;
    channel = gpio_dev[gpio].gpio_slice.channel;
    XGpio_SetDataDirection(&gpio_ctrl[gpio], channel, direction);
}


void gpio_set_slice_direction(int gpio, unsigned int direction){
    unsigned int mask, low, high, channel, direction_mask;
    low = gpio_dev[gpio].gpio_slice.low;
    high = gpio_dev[gpio].gpio_slice.high;
    channel = gpio_dev[gpio].gpio_slice.channel;
    mask = (0x1 << (high + 1)) - (0x1 << low);
    direction_mask = XGpio_GetDataDirection(&gpio_ctrl[gpio], channel);
    
    if (direction){
        // GPIO selected as input
        direction_mask |= mask;
    }else{
        // GPIO selected as output
        direction_mask &= ~mask;
    }
    XGpio_SetDataDirection(&gpio_ctrl[gpio], channel, direction_mask);
}


int gpio_read(int gpio){
    unsigned int read_value, channel;
    channel = gpio_dev[gpio].gpio_slice.channel;
    read_value = XGpio_DiscreteRead(&gpio_ctrl[gpio], channel);
    return (read_value>>gpio) & 0x1;
}


void gpio_write(int gpio, unsigned int data){
    unsigned int write_value, channel;
    channel = gpio_dev[gpio].gpio_slice.channel;
    write_value = XGpio_DiscreteRead(&gpio_ctrl[gpio], channel);
    if (data==0){
        write_value &= (~(0x1<<gpio));
    }else{
        write_value |= (0x1<<gpio);
    }
    XGpio_DiscreteWrite(&gpio_ctrl[gpio], channel, write_value);
}


void gpio_close(int gpio){
    gpio_dev[gpio].gpio_fd = -1;
}


#endif