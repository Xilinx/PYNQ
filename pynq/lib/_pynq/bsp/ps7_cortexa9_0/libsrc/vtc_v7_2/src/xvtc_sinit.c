/******************************************************************************
*
* Copyright (C) 2008 - 2014 Xilinx, Inc.  All rights reserved.
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
* @file xvtc_sinit.c
* @addtogroup vtc_v7_2
* @{
*
* This file contains static initialization methods for Xilinx VTC core.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who    Date     Changes
* ----- ------ -------- --------------------------------------------------
* 1.00a xd     08/05/08 First release.
* 1.01a xd     07/23/10 Added GIER; Added more h/w generic info into
*                       xparameters.h. Feed callbacks with pending
*                       interrupt info. Added Doxygen & Version support.
* 3.00a cjm    08/01/12 Converted from xio.h to xil_io.h, translating
*                       basic types, MB cache functions, exceptions and
*                       assertions to xil_io format.
*                       Replaced the following:
*                       "Xuint16" -> "u16".
* 6.1   adk    08/23/14 updated doxygen tags.
* 7.1   als    08/11/16 Provide protection against driver inclusion in the
*                       absence of VTC instantiation.
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xvtc.h"
#include "xparameters.h"

/************************** Constant Definitions *****************************/

#ifndef XPAR_XVTC_NUM_INSTANCES
#define XPAR_XVTC_NUM_INSTANCES 0
#endif

/***************** Macros (Inline Functions) Definitions *********************/


/**************************** Type Definitions *******************************/


/************************** Function Prototypes ******************************/


/************************** Variable Definitions *****************************/


/************************** Function Definitions *****************************/

/*****************************************************************************/
/**
*
* This function returns a reference to an XVtc_Config structure based on the
* core id, <i>DeviceId</i>. The return value will refer to an entry in
* the device configuration table defined in the xvtc_g.c file.
*
* @param	DeviceId is the unique core ID of the VTC core for the lookup
*		operation.
*
* @return	XVtc_LookupConfig returns a reference to a config record in
*		the configuration table (in xvtc_g.c) corresponding to
*		<i>DeviceId</i>, or NULL if no match is found.
*
* @note		None.
*
******************************************************************************/
XVtc_Config *XVtc_LookupConfig(u16 DeviceId)
{
	extern XVtc_Config XVtc_ConfigTable[];
	XVtc_Config *CfgPtr = NULL;
	int i;

	/* Checking for device id for which instance it is matching */
	for (i = 0; i < XPAR_XVTC_NUM_INSTANCES; i++) {
		/* Assigning address of config table if both device ids
		 * are matched
		 */
		if (XVtc_ConfigTable[i].DeviceId == DeviceId) {
			CfgPtr = &XVtc_ConfigTable[i];
			break;
		}
	}

	return CfgPtr;
}
/** @} */
