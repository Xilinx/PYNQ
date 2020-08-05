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
#include "xgpio_l.h"
#include "xgpio.h"
/* 
 * GPIO API
 * Internal GPIO bit format:
 * 0:0 valid bit
 * 6:1 low bit
 * 12:7 high bit
 * 15:13 channel 1 or channel 2
 * 31:16 device
 */
typedef int gpio;
typedef union {
    int device;
    struct {
        int valid: 1, low : 6, high : 6, channel : 3, device : 16;
    } _gpio;
} _gpio;

extern XGpio_Config XGpio_ConfigTable[];
static XGpio xgpio[XPAR_XGPIO_NUM_INSTANCES];
XGpio* xgpio_ptr = &xgpio[0];
/************************** Function Definitions ***************************/
gpio gpio_open_device(unsigned int device){
    int status;
    u16 dev_id;
    _gpio gpio_dev;
    if (device < XPAR_XGPIO_NUM_INSTANCES) {
        dev_id = (u16)device;
    } else {
        int found = 0;
        for (u16 i = 0; i < XPAR_XGPIO_NUM_INSTANCES; ++i) {
            if (XGpio_ConfigTable[i].BaseAddress == device) {
                found = 1;
                dev_id = i;
                break;
            }
        }
        if (!found) return -1;

    }
    status = XGpio_Initialize(&xgpio[dev_id], dev_id);
    if (status != XST_SUCCESS) {
        return -1;
    }

    gpio_dev._gpio.valid = 0;
    gpio_dev._gpio.low = GPIO_INDEX_MIN;
    gpio_dev._gpio.high = GPIO_INDEX_MAX;
    gpio_dev._gpio.channel = 1;
    gpio_dev._gpio.device = dev_id;
    return gpio_dev.device;
}

#ifdef XPAR_IO_SWITCH_NUM_INSTANCES
#ifdef XPAR_IO_SWITCH_0_GPIO_BASEADDR
#include "xio_switch.h"
gpio gpio_open(unsigned int pin) {
    set_pin(pin, GPIO);
    gpio dev = gpio_open_device(XPAR_IO_SWITCH_0_GPIO_BASEADDR);
    return gpio_configure(dev, pin, pin, 1);
}
#endif
#endif


gpio gpio_configure(gpio device, unsigned int low, unsigned int high, 
                    unsigned int channel){
    _gpio gpio_dev;
    gpio_dev.device = device;
    gpio_dev._gpio.low = low;
    gpio_dev._gpio.high = high;
    gpio_dev._gpio.channel = channel;
    return gpio_dev.device;
}


void gpio_set_direction(gpio device, unsigned int direction){
    unsigned int mask, low, high, channel, dev_id, direction_mask;
    _gpio gpio_dev;
    gpio_dev.device = device;
    low = gpio_dev._gpio.low;
    high = gpio_dev._gpio.high;
    channel = gpio_dev._gpio.channel;
    dev_id = gpio_dev._gpio.device;

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


int gpio_read(gpio device){
    unsigned int read_value, mask, low, high, channel, dev_id;
    _gpio gpio_dev;
    gpio_dev.device = device;
    low = gpio_dev._gpio.low;
    high = gpio_dev._gpio.high;
    channel = gpio_dev._gpio.channel;
    dev_id = gpio_dev._gpio.device;

    mask = (0x1 << (high + 1)) - (0x1 << low);
    read_value = XGpio_DiscreteRead(&xgpio[dev_id], channel);
    return (read_value & mask) >> low;
}


void gpio_write(gpio device, unsigned int data){
    unsigned int write_value, mask, low, high, channel, dev_id;
    _gpio gpio_dev;
    gpio_dev.device = device;
    low = gpio_dev._gpio.low;
    high = gpio_dev._gpio.high;
    channel = gpio_dev._gpio.channel;
    dev_id = gpio_dev._gpio.device;

    write_value = XGpio_DiscreteRead(&xgpio[dev_id], channel);
    mask = ~((0x1 << (high + 1)) - (0x1 << low));
    write_value = (write_value & mask) | (data << low);
    XGpio_DiscreteWrite(&xgpio[dev_id], channel, write_value);
}


void gpio_close(gpio device){
    unsigned int mask, low, high, channel, dev_id, direction_mask;
    _gpio mod_id;
    mod_id.device = device;
    low = mod_id._gpio.low;
    high = mod_id._gpio.high;
    channel = mod_id._gpio.channel;
    dev_id = mod_id._gpio.device;
    mask = (0x1 << (high + 1)) - (0x1 << low);
    direction_mask = XGpio_GetDataDirection(&xgpio[dev_id], channel);
    direction_mask |= mask;
    XGpio_SetDataDirection(&xgpio[dev_id], channel, direction_mask);
}


unsigned int gpio_get_num_devices(void){
    return XPAR_XGPIO_NUM_INSTANCES;
}

#endif
