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
 * @file i2c.h
 *
 * Header file for I2C related functions for PYNQ Microblaze, 
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
#ifndef _I2C_H_
#define _I2C_H_

#include <xparameters.h>
#ifdef XPAR_XIIC_NUM_INSTANCES
#include "xiic.h"

/* 
 * IIC API
 */
static int i2c_fd[XPAR_XIIC_NUM_INSTANCES];
static unsigned int i2c_dev_address[XPAR_XIIC_NUM_INSTANCES];

const unsigned int i2c_base_address[XPAR_XIIC_NUM_INSTANCES] = {
#ifdef XPAR_IIC_0_BASEADDR
    XPAR_IIC_0_BASEADDR,
#endif
#ifdef XPAR_IIC_1_BASEADDR
    XPAR_IIC_1_BASEADDR,
#endif
};


int i2c_open_device(unsigned int device);
void i2c_configure(int i2c, unsigned int dev_addr);
void i2c_read(int i2c, unsigned char* buffer, unsigned int length);
void i2c_write(int i2c, unsigned char* buffer, unsigned int length);
void i2c_close(int i2c);

#endif


unsigned int i2c_get_num_devices(void){
#ifdef XPAR_XIIC_NUM_INSTANCES
    return XPAR_XIIC_NUM_INSTANCES;
#else
    return 0;
#endif
}


#endif  // _I2C_H_
