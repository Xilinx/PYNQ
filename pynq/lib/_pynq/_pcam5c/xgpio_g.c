/******************************************************************************
*
* Copyright (C) 2002 - 2019 Xilinx, Inc.  All rights reserved.
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
* @file xgpio_g.c
* @addtogroup gpio_v4_4
* @{
*
* This file contains a configuration table that specifies the configuration
* of GPIO devices in the system.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a rmm  02/04/02 First release
* 2.00a jhl  12/16/02 Update for dual channel and interrupt support
* 2.11a mta  03/21/07 Updated to new coding style
* 4.0   sha  07/15/15 Added XPAR_XGPIO_NUM_INSTANCES macro to control
*		      config table parameters.
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xgpio.h"
#include "xparameters.h"

/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/


/************************** Variable Prototypes ******************************/

/**
 * This table contains configuration information for each GPIO device
 * in the system.
 */
XGpio_Config XGpio_ConfigTable[] = {
	{
#ifdef XPAR_XGPIO_NUM_INSTANCES
	 XPAR_GPIO_0_DEVICE_ID,
	 XPAR_GPIO_0_BASEADDR,
	 XPAR_GPIO_0_INTERRUPT_PRESENT,
	 XPAR_GPIO_0_IS_DUAL
#endif
	}
};
/** @} */
