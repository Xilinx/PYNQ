/******************************************************************************
Copyright (C) 2020 Xilinx, Inc.  All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Except as contained in this notice, the name of the Xilinx shall not be used
in advertising or otherwise to promote the sale, use or other dealings in
this Software without prior written authorization from Xilinx.

******************************************************************************/
/*****************************************************************************
*
* @file xrfdc_clk.c
*
* This file contains a programming example for using the lmk04208 clock 
* generator.
* For zcu111 board users are expected to define BOARD_RFSoC2x2 macro
* while compiling this example.
*
*
* <pre>
*
* MODIFICATION HISTORY:
*
* Ver   Who    Date     Changes
* ----- -----  -------- -----------------------------------------------------
* 1.0   yrq    07/11/20 First release
*
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <limits.h>
#include <dirent.h>
#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>

#define XIIC_BLOCK_MAX	16	/* Max data length */
#define I2C_SMBUS_WRITE	0
#define I2C_SMBUS_READ	1
#define I2C_SMBUS_I2C_BYTE   1
#define I2C_SMBUS_I2C_BLOCK  6

#include "xrfdc_clk.h"

union i2c_smbus_data {
	unsigned char byte;
	unsigned char block[XIIC_BLOCK_MAX+1];
};

static inline int IicWriteData(int XIicDevFile, unsigned char command,
		unsigned char length,
		const unsigned char *values)
{
	struct i2c_smbus_ioctl_data args;
	union i2c_smbus_data data;
	int Index;
	for (Index = 1; Index <= length; Index++)
		data.block[Index] = values[Index-1];
	data.block[0] = length;
	args.read_write = I2C_SMBUS_WRITE;
	args.command = command;
	args.size = I2C_SMBUS_I2C_BLOCK;
	args.data = &data;
	return ioctl(XIicDevFile,I2C_SMBUS,&args);
}

static inline int IicReadData(int XIicDevFile, unsigned char *value)
{
	struct i2c_smbus_ioctl_data args;
	union i2c_smbus_data data;
	args.read_write = I2C_SMBUS_READ;
	args.command = 0;
	args.size = I2C_SMBUS_I2C_BYTE;
	args.data = &data;
	if (ioctl(XIicDevFile,I2C_SMBUS,&args)) {
		return -1;
	}
	else {
		value[0] = 0xff & data.byte;
		return 0;
	}
}

/* Function to write frequency update to I2C for LMK clocks */
int LmkUpdateFreq(int XIicDevFile, unsigned int *CKin)
{
	int Index;
	unsigned char tx_array[TX_SIZE];
	
	for (Index = 0; Index < REG_COUNT; Index++) {
#ifdef BOARD_ZCU111
		tx_array[3] = (unsigned char) (CKin[Index]) & (0xFF);
		tx_array[2] = (unsigned char) (CKin[Index] >> 8) & (0xFF);
		tx_array[1] = (unsigned char) (CKin[Index] >> 16) & (0xFF);
		tx_array[0] = (unsigned char) (CKin[Index] >> 24) & (0xFF);
		if (IicWriteData(XIicDevFile, LMK_FUNCTION_ID, TX_SIZE, tx_array)){
			printf("Error: IicWriteData failed. \n");
			return -1;
		}
		usleep(1000);
#elif BOARD_RFSoC2x2
		tx_array[2] = (unsigned char) (CKin[Index]) & (0xFF);
		tx_array[1] = (unsigned char) (CKin[Index] >> 8) & (0xFF);
		tx_array[0] = (unsigned char) (CKin[Index] >> 16) & (0xFF);

		if (IicWriteData(XIicDevFile, LMK_FUNCTION_ID, TX_SIZE, tx_array)){
			printf("Error: IicWriteData failed. \n");
			return -1;
		}
		usleep(1000);
		if (IicWriteData(XIicDevFile, NC_FUNCTION_ID, TX_SIZE, tx_array)){
			printf("Error: IicWriteData failed. \n");
			return -1;
		}
		usleep(1000);
		if (IicReadData(XIicDevFile, tx_array)){
			printf("Error: IicReadData failed. \n");
			return -1;
		}
#endif
	}
	return 0;
}


/* Function to configure I2C for the LMX2594 clock */
void Lmx2594Updatei2c(int XIicDevFile,unsigned int *CKin)
{
	int Index=0;
	unsigned char tx_array[LMX_TX_SIZE];
    
/* 1. Apply power to device. */
    
/* 2. Program RESET = 1 to reset registers. */
	tx_array[2] = 0x2;
	tx_array[1] = 0;
	tx_array[0] = 0;
	IicWriteData(XIicDevFile, LMX_FUNCTION_ID, LMX_TX_SIZE, tx_array);
	usleep(1000);
    
/* 3. Program RESET = 0 to remove reset. */
	tx_array[2] = 0;
	tx_array[1] = 0;
	tx_array[0] = 0;
	IicWriteData(XIicDevFile, LMX_FUNCTION_ID, LMX_TX_SIZE, tx_array);
	usleep(1000);
    
/* 4. Program registers as shown in the register map in REVERSE order 
 *    from highest to lowest. */
	for (Index = 0; Index < LMX_REG_COUNT; Index++) {
		tx_array[2] = (unsigned char) (CKin[Index]) & (0xFF);
		tx_array[1] = (unsigned char) (CKin[Index] >> 8) & (0xFF);
		tx_array[0] = (unsigned char) (CKin[Index] >> 16) & (0xFF);
		IicWriteData(XIicDevFile, LMX_FUNCTION_ID, LMX_TX_SIZE, tx_array);
		usleep(1000);
	}
    
/* 5. Program register R0 one additional time with FCAL_EN = 1 to ensure 
 *    that the VCO calibration runs from a stable state. */
	tx_array[2] = (unsigned char) (CKin[112]) & (0xFF);
	tx_array[1] = (unsigned char) (CKin[112] >> 8) & (0xFF);
	tx_array[0] = (unsigned char) (CKin[112] >> 16) & (0xFF);
	IicWriteData(XIicDevFile, LMX_FUNCTION_ID, LMX_TX_SIZE, tx_array);
}


/* Function to Clear SC18IS602 I2C-bus to SPI bridge */
int SC18IS602ClearInt(int XIicDevFile)
{   
    struct i2c_smbus_ioctl_data args;
    union i2c_smbus_data data;
    data.block[0] = 0;
    args.read_write = I2C_SMBUS_WRITE;
    args.command = 0xF1;
    args.size = 2;
    args.data = &data;
    ioctl(XIicDevFile,I2C_SMBUS,&args);
    return 0;
}