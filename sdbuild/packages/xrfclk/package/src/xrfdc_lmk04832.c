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
* @file xrfdc_lmk04208.c
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
#ifndef __BAREMETAL__
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

#else
#include "xparameters.h"
#include "sleep.h"
#include "xuartps.h"
#include "xiicps.h"
#include "xil_printf.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
XIicPs Iic; /* Instance of the IIC Device */

#endif
#include "xrfdc_clk.h"

#define LMK04832_count 125

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
	int i, err;
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

static int Lmk04832UpdateFreq(int XIicDevFile,
		unsigned int LMK04832_CKin[1][125] )
{
	int Index;
	unsigned char tx_array[3];
	for (Index = 0; Index < LMK04832_count; Index++) {
		tx_array[2] = (unsigned char) (LMK04832_CKin[0][Index]) & (0xFF);
		tx_array[1] = (unsigned char) (LMK04832_CKin[0][Index] >> 8) & (0xFF);
		tx_array[0] = (unsigned char) (LMK04832_CKin[0][Index] >> 16) & (0xFF);
		if (IicWriteData(XIicDevFile, LMK_FUNCTION_ID, 3, tx_array)){
			printf("Error: IicWriteData failed. \n");
			return -1;
		}
		usleep(1000);
		if (IicWriteData(XIicDevFile, NC_FUNCTION_ID, 3, tx_array)){
			printf("Error: IicWriteData failed. \n");
			return -1;
		}
		usleep(1000);
		if (IicReadData(XIicDevFile, tx_array)){
			printf("Error: IicReadData failed. \n");
			return -1;
		}
	}
	return 0;
}

/****************************************************************************/
/**
*
* This function is used to configure LMK04832
*
* @param	XIicBus is the Controller Id/Bus number.
*           - For Baremetal it is the I2C controller Id to which LMK04832
*             device is connected.
*           - For Linux it is the Bus Id to which LMK04832 device is connected.
* @param	LMK04832_CKin is the configuration array to configure the LMK04832.
*
* @return
*		- None
*
* @note   	None
*
****************************************************************************/
void LMK04832ClockConfig(int XIicBus, unsigned int LMK04832_CKin[1][125])
{
	int XIicDevFile;
	char XIicDevFilename[20];

	sprintf(XIicDevFilename, "/dev/i2c-%d", XIicBus);
	XIicDevFile = open(XIicDevFilename, O_RDWR);

	if (ioctl(XIicDevFile, I2C_SLAVE_FORCE, I2C_SPI_ADDR) < 0) {
		printf("Error: Could not set address \n");
		return ;
	}

	Lmk04832UpdateFreq( XIicDevFile, LMK04832_CKin);
	close(XIicDevFile);
}
