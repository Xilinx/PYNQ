/******************************************************************************
*
* Copyright (C) 2002 - 2015 Xilinx, Inc.  All rights reserved.
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
* @file xiic_options.c
* @addtogroup iic_v3_1
* @{
*
* Contains options functions for the XIic component. This file is not required
* unless the functions in this file are called.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- --- ------- -----------------------------------------------
* 1.01b jhl 3/26/02 repartioned the driver
* 1.01c ecm 12/05/02 new rev
* 1.13a wgr 03/22/07 Converted to new coding style.
* 2.00a ktn 10/22/09 Converted all register accesses to 32 bit access.
*		     Updated to use the HAL APIs/macros.
* </pre>
*
****************************************************************************/

/***************************** Include Files *******************************/

#include "xiic.h"
#include "xiic_i.h"

/************************** Constant Definitions ***************************/


/**************************** Type Definitions *****************************/


/***************** Macros (Inline Functions) Definitions *******************/


/************************** Function Prototypes ****************************/


/************************** Variable Definitions **************************/


/*****************************************************************************/
/**
*
* This function sets the options for the IIC device driver. The options control
* how the device behaves relative to the IIC bus. If an option applies to
* how messages are sent or received on the IIC bus, it must be set prior to
* calling functions which send or receive data.
*
* To set multiple options, the values must be ORed together. To not change
* existing options, read/modify/write with the current options using
* XIic_GetOptions().
*
* <b>USAGE EXAMPLE:</b>
*
* Read/modify/write to enable repeated start:
* <pre>
*   u8 Options;
*   Options = XIic_GetOptions(&Iic);
*   XIic_SetOptions(&Iic, Options | XII_REPEATED_START_OPTION);
* </pre>
*
* Disabling General Call:
* <pre>
*   Options = XIic_GetOptions(&Iic);
*   XIic_SetOptions(&Iic, Options &= ~XII_GENERAL_CALL_OPTION);
* </pre>
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
* @param	NewOptions are the options to be set.  See xiic.h for a list of
*		the available options.
*
* @return	None.
*
* @note
*
* Sending or receiving messages with repeated start enabled, and then
* disabling repeated start, will not take effect until another master
* transaction is completed. i.e. After using repeated start, the bus will
* continue to be throttled after repeated start is disabled until a master
* transaction occurs allowing the IIC to release the bus.
* <br><br>
* Options enabled will have a 1 in its appropriate bit position.
*
****************************************************************************/
void XIic_SetOptions(XIic *InstancePtr, u32 NewOptions)
{
	u32 CntlReg;

	Xil_AssertVoid(InstancePtr != NULL);

	XIic_IntrGlobalDisable(InstancePtr->BaseAddress);

	/*
	 * Update the options in the instance and get the contents of the
	 * control register such that the general call option can be modified.
	 */
	InstancePtr->Options = NewOptions;
	CntlReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);

	/*
	 * The general call option is the only option that maps directly to
	 * a hardware register feature.
	 */
	if (NewOptions & XII_GENERAL_CALL_OPTION) {
		CntlReg |= XIIC_CR_GENERAL_CALL_MASK;
	} else {
		CntlReg &= ~XIIC_CR_GENERAL_CALL_MASK;
	}

	/*
	 * Write the new control register value to the register.
	 */
	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET, CntlReg);

	XIic_IntrGlobalEnable(InstancePtr->BaseAddress);
}

/*****************************************************************************/
/**
*
* This function gets the current options for the IIC device. Options control
* the how the device behaves on the IIC bus. See SetOptions for more information
* on options.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return	The options of the IIC device. See xiic.h for a list of
*		available options.
*
* @note
*
* Options enabled will have a 1 in its appropriate bit position.
*
****************************************************************************/
u32 XIic_GetOptions(XIic *InstancePtr)
{
	Xil_AssertNonvoid(InstancePtr != NULL);

	return InstancePtr->Options;
}
/** @} */
