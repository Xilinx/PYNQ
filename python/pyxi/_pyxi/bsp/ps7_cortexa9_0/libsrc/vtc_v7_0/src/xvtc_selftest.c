/******************************************************************************
*
* Copyright (C) 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xvtc_selftest.c
* @addtogroup vtc_v7_0
* @{
*
* This file contains the self test function for the VTC core.
* The self test function reads the Version register.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who    Date     Changes
* ----- ------ -------- --------------------------------------------------
* 6.1   adk    08/23/14 First Release.
*                       Implemented following function:
*                       XVtc_SelfTest.
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xvtc.h"

/************************** Constant Definitions *****************************/


/***************** Macros (Inline Functions) Definitions *********************/


/**************************** Type Definitions *******************************/


/************************** Function Prototypes ******************************/


/************************** Variable Definitions *****************************/


/************************** Function Definitions *****************************/

/*****************************************************************************/
/**
*
* This function reads version register of the VTC core and compares with zero
* as part of self test.
*
* @param	InstancePtr is a pointer to the XVtc instance.
*
* @return
*		- XST_SUCCESS if the Version register read test was successful.
*		- XST_FAILURE if the Version register read test failed.
*
* @note		None.
*
******************************************************************************/
int XVtc_SelfTest(XVtc *InstancePtr)
{
	u32 Version;
	int Status;

	/* Verify argument. */
	Xil_AssertNonvoid(InstancePtr != NULL);

	/* Read VTC core version register. */
	Version = XVtc_ReadReg((InstancePtr)->Config.BaseAddress,
					(XVTC_VER_OFFSET));

	/* Compare version with zero */
	if(Version != (u32)0x0) {
		Status = (u32)(XST_SUCCESS);
	}
	else {
		Status = (u32)(XST_FAILURE);
	}

	return Status;
}
/** @} */
