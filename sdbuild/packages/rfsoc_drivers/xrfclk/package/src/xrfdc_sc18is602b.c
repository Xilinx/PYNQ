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
#define I2C_SMBUS_I2C_BLOCK  5

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

#endif
