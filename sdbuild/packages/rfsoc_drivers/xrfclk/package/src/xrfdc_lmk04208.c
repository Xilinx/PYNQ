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
* For zcu111 board users are expected to define BOARD_ZCU111 macro
* while compiling this example.
*
*
* <pre>
*
* MODIFICATION HISTORY:
*
* Ver   Who    Date     Changes
* ----- -----  -------- -----------------------------------------------------
* 1.0   sd     04/11/18 First release
* 4.0   sd     05/22/18 Updated lmx configuration
* 5.0   sd     09/05/18 Updated lmx reset sequence
* 6.0 	ldm	   08/06/20 Seperated clocking chips into different files
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

#define LMK04208_count 26

union i2c_smbus_data {
	unsigned char byte;
	unsigned char block[XIIC_BLOCK_MAX+1];
};

#ifndef __BAREMETAL__

static inline void IicWriteData(int XIicDevFile, unsigned char command,
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
	ioctl(XIicDevFile,I2C_SMBUS,&args);
}

static int Lmk04208UpdateFreq(int XIicDevFile, unsigned int LMK04208_CKin[1][26] )
{
	int Index;
	unsigned char tx_array[4];
	for (Index = 0; Index < LMK04208_count; Index++) {
		tx_array[3] = (unsigned char) (LMK04208_CKin[0][Index]) & (0xFF);
		tx_array[2] = (unsigned char) (LMK04208_CKin[0][Index] >> 8) & (0xFF);
		tx_array[1] = (unsigned char) (LMK04208_CKin[0][Index] >> 16) & (0xFF);
		tx_array[0] = (unsigned char) (LMK04208_CKin[0][Index] >> 24) & (0xFF);
		IicWriteData(XIicDevFile, LMK_FUNCTION_ID, 4, tx_array);
		usleep(1000);
	}
	return 0;
}
#endif

/****************************************************************************/
/**
*
* This function is used to configure LMK04208
*
* @param	XIicBus is the Controller Id/Bus number.
*           - For Baremetal it is the I2C controller Id to which LMK04208
*             deviceis connected.
*           - For Linux it is the Bus Id to which LMK04208 device is connected.
* @param	LMK04208_CKin is the configuration array to configure the LMK04208.
*
* @return
*		- None
*
* @note   	None
*
****************************************************************************/
void LMK04208ClockConfig(int XIicBus, unsigned int LMK04208_CKin[1][26])
{
#ifdef __BAREMETAL__
	XIicPs_Config *Config_iic;
	int Status;
	u8 tx_array[10];
	u8 rx_array[10];
	u32 ClkRate = 100000;
	int Index;

	Config_iic = XIicPs_LookupConfig(XIicBus);
	if (NULL == Config_iic) {
		return;
	}

	Status = XIicPs_CfgInitialize(&Iic, Config_iic, Config_iic->BaseAddress);
	if (Status != XST_SUCCESS) {
		return;
	}

	Status = XIicPs_SetSClk(&Iic, ClkRate);
	if (Status != XST_SUCCESS) {
		return;
	}

	/*
	 * 0x02-enable Super clock module 0x20- analog I2C power module slaves
	 */
	tx_array[0] = 0x20;
	XIicPs_MasterSendPolled(&Iic, tx_array, 0x01, I2C_MUX_ADDR);
	while (XIicPs_BusIsBusy(&Iic))
		;
	usleep(25000);

	/*
	 * Receive the Data.
	 */
	Status = XIicPs_MasterRecvPolled(&Iic, rx_array, 1, I2C_MUX_ADDR);
	if (Status != XST_SUCCESS) {
		return;
	}

	/*
	 * Wait until bus is idle to start another transfer.
	 */
	while (XIicPs_BusIsBusy(&Iic))
		;


	/*
	 * Function Id.
	 */
	tx_array[0] = 0xF0;
	tx_array[1] = LMK_FUNCTION_ID;
	XIicPs_MasterSendPolled(&Iic, tx_array, 0x02, I2C_SPI_ADDR);
	while (XIicPs_BusIsBusy(&Iic))
		;
	usleep(25000);

	/*
	 * Receive the Data.
	 */
	Status = XIicPs_MasterRecvPolled(&Iic, rx_array,
			2, I2C_SPI_ADDR);
	if (Status != XST_SUCCESS) {
		return;
	}

	/*
	 * Wait until bus is idle to start another transfer.
	 */
	while (XIicPs_BusIsBusy(&Iic));


	for (Index = 0; Index < LMK04208_count; Index++) {
		tx_array[0] = 0x02;
		tx_array[4] = (u8) (LMK04208_CKin[0][Index]) & (0xFF);
		tx_array[3] = (u8) (LMK04208_CKin[0][Index] >> 8) & (0xFF);
		tx_array[2] = (u8) (LMK04208_CKin[0][Index] >> 16) & (0xFF);
		tx_array[1] = (u8) (LMK04208_CKin[0][Index] >> 24) & (0xFF);
		Status = XIicPs_MasterSendPolled(&Iic, tx_array, 0x05, I2C_SPI_ADDR);
		usleep(25000);
		while (XIicPs_BusIsBusy(&Iic))
			;
	}

	sleep(2);

#else
	int XIicDevFile;
	char XIicDevFilename[20];

	sprintf(XIicDevFilename, "/dev/i2c-%d", XIicBus);
	XIicDevFile = open(XIicDevFilename, O_RDWR);

	if (ioctl(XIicDevFile, I2C_SLAVE_FORCE, I2C_SPI_ADDR) < 0) {
		printf("Error: Could not set address \n");
		return ;
	}

	Lmk04208UpdateFreq( XIicDevFile, LMK04208_CKin);
	close(XIicDevFile);
#endif
}














