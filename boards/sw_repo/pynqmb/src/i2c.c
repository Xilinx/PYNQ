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
 *
 * </pre>
 *
 *****************************************************************************/
#include <xparameters.h>
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


void i2c_read(i2c dev_id, unsigned int slave_address,
              unsigned char* buffer, unsigned int length){
    XIic_Recv(xi2c[dev_id].BaseAddress, 
              slave_address, buffer, length, XIIC_STOP);
}


#ifdef XPAR_IO_SWITCH_NUM_INSTANCES
#ifdef XPAR_IO_SWITCH_0_I2C0_BASEADDR
#include "xio_switch.h"
static int last_sda = -1;
static int last_scl = -1;

i2c i2c_open(unsigned int sda, unsigned int scl){
    if (last_sda != -1) set_pin(last_sda, GPIO);
    if (last_scl != -1) set_pin(last_scl, GPIO);
    last_sda = sda;
    last_scl = scl;
    set_pin(scl, SCL0);
    set_pin(sda, SDA0);
    return i2c_open_device(XPAR_IO_SWITCH_0_I2C0_BASEADDR);
}
#endif
#endif


void i2c_write(i2c dev_id, unsigned int slave_address,
               unsigned char* buffer, unsigned int length){
    XIic_Send(xi2c[dev_id].BaseAddress, 
              slave_address, buffer, length, XIIC_STOP);
}


void i2c_close(i2c dev_id){
    XIic_ClearStats(&xi2c[dev_id]);
}


unsigned int i2c_get_num_devices(void){
    return XPAR_XIIC_NUM_INSTANCES;
}

#endif
