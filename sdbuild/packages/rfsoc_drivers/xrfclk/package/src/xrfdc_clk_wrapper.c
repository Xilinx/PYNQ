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

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include "xrfdc_clk.h"

#ifdef BOARD_ZCU111
int writeLmk04208Regs(int IicNum, unsigned int RegVals[26]) {
    unsigned int LMK04208_CKin[1][26];
    for(int i=0;i<26;i++)
	    LMK04208_CKin[0][i] = RegVals[i];
    LMK04208ClockConfig(IicNum, LMK04208_CKin);
    return 0;
 }
#endif /* BOARD_ZCU111 */
 
#ifdef BOARD_RFSoC2x2
int writeLmk04832Regs(int IicNum, unsigned int RegVals[125]) {
    unsigned int LMK04832_CKin[1][125];
    for(int i=0;i<125;i++)
	    LMK04832_CKin[0][i] = RegVals[i];
    LMK04832ClockConfig(IicNum, LMK04832_CKin);
    return 0;
}
#endif /* BOARD_RFSoC2x2 */

#if defined(BOARD_RFSoC2x2) || defined(BOARD_ZCU111)
int writeLmx2594Regs(int IicNum, unsigned int RegVals[113]) {
    int XIicDevFile;
    char XIicDevFilename[20];

    sprintf(XIicDevFilename, "/dev/i2c-%d", IicNum);
    XIicDevFile = open(XIicDevFilename, O_RDWR);

    if (ioctl(XIicDevFile, I2C_SLAVE_FORCE, I2C_SPI_ADDR) < 0) {
      printf("Error: Could not set address \n");
      return 1;
    }

    Lmx2594Updatei2c(XIicDevFile, RegVals);
    close(XIicDevFile);
    return 0;
}

int clearInt(int IicNum){
    int XIicDevFile;
    char XIicDevFilename[20];

    sprintf(XIicDevFilename, "/dev/i2c-%d", IicNum);
    XIicDevFile = open(XIicDevFilename, O_RDWR);

    if (ioctl(XIicDevFile, I2C_SLAVE_FORCE, I2C_SPI_ADDR) < 0) {
      printf("Error: Could not set address \n");
      return 1;
    }

    SC18IS602ClearInt(XIicDevFile);
    close(XIicDevFile);
    return 0;
}
#endif /* BOARD_RFSoC2x2 || BOARD_ZCU111 */
