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
 * @file i2c.c
 *
 * Implementing I2C related functions for PYNQ Microblaze, 
 * including the IIC read and write.
 *
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00  yrq 01/09/18 release
 * 1.01  yrq 01/30/18 add protection macro
 * 1.02  pko 10/01/20 Add switching support
 *
 * </pre>
 *
 *****************************************************************************/
#include <xparameters.h>
#include <sys/errno.h>
#include "i2c.h"

#ifdef XPAR_XIIC_NUM_INSTANCES
#include "xiic.h"
#include "xiic_l.h"
static XIic xi2c[XPAR_XIIC_NUM_INSTANCES];
XIic* xi2c_ptr = &xi2c[0];
extern XIic_Config XIic_ConfigTable[];

/************************** Function Definitions ***************************/
i2c i2c_open_device(unsigned int device){
    int status;
    u16 dev_id;

    if (device < XPAR_XIIC_NUM_INSTANCES) {
        dev_id = (u16)device;
    } else {
        int found = 0;
        for (u16 i = 0; i < XPAR_XIIC_NUM_INSTANCES; ++i) {
            if (XIic_ConfigTable[i].BaseAddress == device) {
                found = 1;
                dev_id = i;
                break;
            }
        }
        if (!found) return -1;
    }
    status = XIic_Initialize(&xi2c[dev_id], dev_id);
    if (status != XST_SUCCESS) {
        return -1;
    }
    return (i2c)dev_id;
}


#if defined XPAR_IO_SWITCH_NUM_INSTANCES && defined XPAR_IO_SWITCH_0_I2C0_BASEADDR

#include "xio_switch.h"
#ifndef MAX_I2C_DEVICES
#define MAX_I2C_DEVICES 4
#endif

#define SWITCH_FLAG 0x10000

/* In this mode the i2c object is either the index of the physical device or,
 * if the SWITCH_FLAG bit is set, the index in the info table.
 *
 * The i2c_set_switch() function converts an i2c object to the physical device
 * index */

struct i2c_switch_info {
    unsigned int sda;
    unsigned int scl;
    int phys_id;
    int channel; // Either 0 or 1
    int count;
};

static struct i2c_switch_info i2c_info[MAX_I2C_DEVICES];

static int last_sda = -1;
static int last_scl = -1;

i2c i2c_open(unsigned int sda, unsigned int scl){
#if XPAR_IO_SWITCH_0_INTERFACE_TYPE == 3 // Arduino is special as it doesn't use the IO switch
    return i2c_open_device(XPAR_IIC_0_BASEADDR);
#else
    for (int i = 0; i < MAX_I2C_DEVICES; ++i) {
        if (i2c_info[i].count && (sda == i2c_info[i].sda) && (scl == i2c_info[i].scl)) {
            i2c_info[i].count++;
            return i | SWITCH_FLAG;
        }
    }
    int info_id = -1;
    for (int i = 0; i < MAX_I2C_DEVICES; ++i) {
        if (i2c_info[i].count == 0) {
            info_id = i;
            break;
        }
    }
    if (info_id == -1) { return -ENOMEM; }
#if XPAR_IO_SWITCH_0_INTERFACE_TYPE == 2 // Dual Pmod
    if (sda == 3 || sda == 7) {
        i2c_info[info_id].channel = 0;
        i2c_info[info_id].phys_id = i2c_open_device(XPAR_IO_SWITCH_0_I2C0_BASEADDR);
    } else {
        i2c_info[info_id].channel = 1;
        i2c_info[info_id].phys_id = i2c_open_device(XPAR_IO_SWITCH_0_I2C1_BASEADDR);
    }
#elif XPAR_IO_SWITCH_0_INTERFACE_TYPE == 4 // Raspberry Pi
    if (sda == 0) {
        i2c_info[info_id].channel = 0;
        i2c_info[info_id].phys_id = i2c_open_device(XPAR_IO_SWITCH_0_I2C0_BASEADDR);
    } else {
        i2c_info[info_id].channel = 1;
        i2c_info[info_id].phys_id = i2c_open_device(XPAR_IO_SWITCH_0_I2C1_BASEADDR);
    }
#else // Pmod and other
    i2c_info[info_id].channel = 0;
    i2c_info[info_id].phys_id = i2c_open_device(XPAR_IO_SWITCH_0_I2C0_BASEADDR);
#endif // Interface types
    i2c_info[info_id].sda = sda;
    i2c_info[info_id].scl = scl;
    i2c_info[info_id].count = 1;
    return info_id | SWITCH_FLAG;
#endif // Arduino interface type
}

static i2c i2c_set_switch(i2c dev_id) {
    if ((dev_id & SWITCH_FLAG) == 0) return dev_id;
    int info_id = dev_id ^ SWITCH_FLAG;
    int sda = i2c_info[info_id].sda;
    int scl = i2c_info[info_id].scl;
    if (last_sda != -1) set_pin(last_sda, GPIO);
    if (last_scl != -1) set_pin(last_scl, GPIO);
    last_sda = sda;
    last_scl = scl;
    if (i2c_info[info_id].channel == 0) {
        set_pin(scl, SCL0);
        set_pin(sda, SDA0);
    } else {
        set_pin(scl, SCL1);
        set_pin(sda, SDA1);
    }
    return i2c_info[info_id].phys_id;
}

#else
static i2c i2c_set_switch(i2c dev_id) { return dev_id; }
#endif


py_int i2c_read(i2c dev_id, unsigned int slave_address,
             unsigned char* buffer, unsigned int length){
    i2c dev = i2c_set_switch(dev_id);
    int status  = XIic_Recv(xi2c[dev].BaseAddress,
                            slave_address, buffer, length, XIIC_STOP);
    if (status == 0) return -EIO;
    return status;
}


py_int i2c_write(i2c dev_id, unsigned int slave_address,
              unsigned char* buffer, unsigned int length){
    i2c dev = i2c_set_switch(dev_id);
    int status =  XIic_Send(xi2c[dev].BaseAddress,
                            slave_address, buffer, length, XIIC_STOP);
    if (status == 0) return -EIO;
    return status;
}


void i2c_close(i2c dev_id) {
#if defined XPAR_IO_SWITCH_NUM_INSTANCES && defined XPAR_IO_SWITCH_0_I2C0_BASEADDR
    if ((dev_id & SWITCH_FLAG) == SWITCH_FLAG) {
        int info_id = dev_id ^ SWITCH_FLAG;
        i2c_info[info_id].count--;
    }
#else
    XIic_ClearStats(&xi2c[dev_id]);
#endif
}


unsigned int i2c_get_num_devices(void){
    return XPAR_XIIC_NUM_INSTANCES;
}

#endif
