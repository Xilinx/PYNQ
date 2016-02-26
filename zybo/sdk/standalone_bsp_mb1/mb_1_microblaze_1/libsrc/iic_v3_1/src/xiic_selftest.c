/******************************************************************************
*
* Copyright (C) 2012 - 2015 Xilinx, Inc.  All rights reserved.
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
* @file xiic_selftest.c
* @addtogroup iic_v3_1
* @{
*
* Contains selftest functions for the XIic component.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- --- ------- -----------------------------------------------
* 1.01b jhl 03/26/02 repartioned the driver
* 1.01c ecm 12/05/02 new rev
* 1.01c sv  05/09/05 Changed the data being written to the Address/Control
*                    Register and removed the code for testing the
*                    Receive Data Register.
* 1.13a wgr 03/22/07 Converted to new coding style.
* 1.16a ktn 07/17/09 Updated the test to test only Interrupt Registers
*		     as the software reset only resets the interrupt logic
*		     and the Interrupt Registers are set to default values.
* 1.16a ktn 10/16/09 Updated the notes in the XIic_SelfTest() API and
*                    XIIC_RESET macro to mention that the complete IIC core
*                    is Reset on giving a software reset to the IIC core.
*                    Some previous versions of the core only reset the
*                    Interrupt Logic/Registers, please refer to the HW
*                    specification for futher details.
* 2.00a ktn 10/22/09 Converted all register accesses to 32 bit access.
*		     Updated to use the HAL APIs/macros.
*		     Some of the macros have been renamed to remove _m from
*		     the name and some of the macros have been renamed to be
*		     consistent, see the xiic_i.h and xiic_l.h files for further
*		     information
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
* Runs a limited self-test on the driver/device. This test does a read/write
* test of the Interrupt Registers There is no loopback capabilities for the
* device such that this test does not send or receive data.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return
*		- XST_SUCCESS if no errors are found
*		- XST_FAILURE if errors are found
*
* @note		None.
*
****************************************************************************/
int XIic_SelfTest(XIic *InstancePtr)
{
	int Status = XST_SUCCESS;
	int GlobalIntrStatus;
	u32 IntrEnableStatus;

	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Store the Global Interrupt Register and the Interrupt Enable Register
	 * contents.
	 */
	GlobalIntrStatus = XIic_IsIntrGlobalEnabled(InstancePtr->BaseAddress);
	IntrEnableStatus = XIic_ReadIier(InstancePtr->BaseAddress);

	/*
	 * Reset the device so it's in a known state and the default state of
	 * the interrupt registers can be tested.
	 */
	XIic_Reset(InstancePtr);

	if (XIic_IsIntrGlobalEnabled(InstancePtr->BaseAddress)!= 0) {
		Status = XST_FAILURE;
	}

	if (XIic_ReadIier(InstancePtr->BaseAddress)!= 0) {
		Status = XST_FAILURE;
	}

	/*
	 * Test Read/Write to the Interrupt Enable register.
	 */
	XIic_WriteIier(InstancePtr->BaseAddress, XIIC_TX_RX_INTERRUPTS);
	if (XIic_ReadIier(InstancePtr->BaseAddress)!= XIIC_TX_RX_INTERRUPTS) {
		Status = XST_FAILURE;
	}

	/*
	 * Reset device to remove the affects of the previous test.
	 */
	XIic_Reset(InstancePtr);

	/*
	 * Restore the Global Interrupt Register and the Interrupt Enable
	 * Register contents.
	 */
	if (GlobalIntrStatus == TRUE) {
		XIic_IntrGlobalEnable(InstancePtr->BaseAddress);
	}
	XIic_WriteIier(InstancePtr->BaseAddress, IntrEnableStatus);

	return Status;
}
/** @} */
