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
#ifndef _RFDC_CLK_H_
#define _RFDC_CLK_H_

#ifdef BOARD_RFSoC2x2
void LMX2594ClockConfig(int XIicBus, int XFrequency);
void Lmx2594Updatei2c(int XIicDevFile, unsigned int r[113]);
void LMK04832ClockConfig(int XIicBus, unsigned int LMK04832_CKin[1][125]);
void LMK04832DebugConfig(int XIicBus, unsigned int LMK04832_CKin[1][125]);
int SC18IS602ClearInt(int XIicDevFile);
#define LMX_FUNCTION_ID 	0x3
#define LMK_FUNCTION_ID 	0x8
#define NC_FUNCTION_ID		0x4
#define I2C_SPI_ADDR 	    0x2A
#define I2C_MUX_ADDR	    0x71
#endif /* BOARD_RFSoC2x2 */


#ifdef BOARD_ZCU111
void LMX2594ClockConfig(int XIicBus, int XFrequency);
void Lmx2594Updatei2c(int XIicDevFile, unsigned int r[113]);
void LMK04208ClockConfig(int XIicBus, unsigned int LMK04208_CKin[1][26]);
#define LMX_FUNCTION_ID 	0xd
#define LMK_FUNCTION_ID 	0x2
#define I2C_SPI_ADDR 	    0x2F
#define I2C_MUX_ADDR	    0x74
#endif /* BOARD_ZCU111 */

#endif /* _RFDC_CLK_H_ */
