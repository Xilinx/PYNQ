/******************************************************************************
*
* Copyright (C) 2001 - 2014 Xilinx, Inc.  All rights reserved.
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
* @file xspi_selftest.c
* @addtogroup spi_v4_1
* @{
*
* This component contains the implementation of selftest functions for the
* XSpi driver component.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00b jhl  2/27/02  First release
* 1.00b rpm  04/25/02 Collapsed IPIF and reg base addresses into one
* 1.11a wgr  03/22/07 Converted to new coding style.
* 1.12a sv   03/17/08 Updated the code to support 16/32 bit transfer width.
* 2.00a sv   07/30/08 Updated the code to support 16/32 bit transfer width.
* 3.00a sdm  10/28/09 Updated all the register accesses as 32 bit access.
* 3.02a sdm  05/04/11 Updated to run the loopback test only in standard spi
*		      mode.
* 3.03a sdm  08/09/11 Updated the selftest to check for a correct default value
*		      in the case of axi_qspi - CR 620502
* 3.04a bss  03/21/12 Updated Selftest to check for XIP mode and return if XIP
*		      mode is true
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xspi.h"
#include "xspi_i.h"

/************************** Constant Definitions *****************************/

#define XSP_SR_RESET_STATE	0x5	   /* Default to Tx/Rx reg empty */
#define XSP_CR_RESET_STATE	0x180

#define XSP_HALF_WORD_TESTBYTE	0x2200	   /* Test Byte for Half Word */
#define XSP_WORD_TESTBYTE	0xAA005500 /* Test Byte for Word */

/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/

static int LoopbackTest(XSpi *InstancePtr);

/************************** Variable Definitions *****************************/


/*****************************************************************************/
/**
*
* Runs a self-test on the driver/device. The self-test is destructive in that
* a reset of the device is performed in order to check the reset values of
* the registers and to get the device into a known state. A simple loopback
* test is also performed to verify that transmit and receive are working
* properly. The device is changed to master mode for the loopback test, since
* only a master can initiate a data transfer.
*
* Upon successful return from the self-test, the device is reset.
*
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
*
* @return
* 		- XST_SUCCESS if successful.
*		- XST_REGISTER_ERROR indicates a register did not read or write
*		  correctly.
* 		- XST_LOOPBACK_ERROR if a loopback error occurred.
*
* @note		None.
*
******************************************************************************/
int XSpi_SelfTest(XSpi *InstancePtr)
{
	int Result;
	u32 Register;

	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);


	/* Return Success if XIP Mode */
	if((InstancePtr->XipMode) == 1) {
		return XST_SUCCESS;
	}

	/*
	 * Reset the SPI device to leave it in a known good state.
	 */
	XSpi_Reset(InstancePtr);

	if(InstancePtr->XipMode)
	{
		Register = XSpi_GetControlReg(InstancePtr);
		if (Register != XSP_CR_RESET_STATE) {
			return XST_REGISTER_ERROR;
		}

		Register = XSpi_GetStatusReg(InstancePtr);
		if ((Register & XSP_SR_RESET_STATE) != XSP_SR_RESET_STATE) {
			return XST_REGISTER_ERROR;
		}
	}




	/*
	 * All the SPI registers should be in their default state right now.
	 */
	Register = XSpi_GetControlReg(InstancePtr);
	if (Register != XSP_CR_RESET_STATE) {
		return XST_REGISTER_ERROR;
	}

	Register = XSpi_GetStatusReg(InstancePtr);
	if ((Register & XSP_SR_RESET_STATE) != XSP_SR_RESET_STATE) {
		return XST_REGISTER_ERROR;
	}

	/*
	 * Each supported slave select bit should be set to 1.
	 */
	Register = XSpi_GetSlaveSelectReg(InstancePtr);
	if (Register != InstancePtr->SlaveSelectMask) {
		return XST_REGISTER_ERROR;
	}

	/*
	 * If configured with FIFOs, the occupancy values should be 0.
	 */
	if (InstancePtr->HasFifos) {
		Register = XSpi_ReadReg(InstancePtr->BaseAddr,
					 XSP_TFO_OFFSET);
		if (Register != 0) {
			return XST_REGISTER_ERROR;
		}
		Register = XSpi_ReadReg(InstancePtr->BaseAddr,
					 XSP_RFO_OFFSET);
		if (Register != 0) {
			return XST_REGISTER_ERROR;
		}
	}

	/*
	 * Run loopback test only in case of standard SPI mode.
	 */
	if (InstancePtr->SpiMode != XSP_STANDARD_MODE) {
		return XST_SUCCESS;
	}

	/*
	 * Run an internal loopback test on the SPI.
	 */
	Result = LoopbackTest(InstancePtr);
	if (Result != XST_SUCCESS) {
		return Result;
	}

	/*
	 * Reset the SPI device to leave it in a known good state.
	 */
	XSpi_Reset(InstancePtr);

	return XST_SUCCESS;
}

/*****************************************************************************/
/*
*
* Runs an internal loopback test on the SPI device. This is done as a master
* with a enough data to fill the FIFOs if FIFOs are present. If the device is
* configured as a slave-only, this function returns successfully even though
* no loopback test is performed.
*
* This function does not restore the device context after performing the test
* as it assumes the device will be reset after the call.
*
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
*
* @return
* 		- XST_SUCCESS if loopback was performed successfully or not
*		  performed at all if device is slave-only.
*		- XST_LOOPBACK_ERROR if loopback failed.
*
* @note		None.
*
******************************************************************************/
static int LoopbackTest(XSpi *InstancePtr)
{
	u32 StatusReg;
	u32 ControlReg;
	u32 Index;
	u32 Data;
	u32 RxData;
	u32 NumSent = 0;
	u32 NumRecvd = 0;
	u8  DataWidth;

	/*
	 * Cannot run as a slave-only because we need to be master in order to
	 * initiate a transfer. Still return success, though.
	 */
	if (InstancePtr->SlaveOnly) {
		return XST_SUCCESS;
	}

	/*
	 * Setup the control register to enable master mode and the loopback so
	 * that data can be sent and received.
	 */
	ControlReg = XSpi_GetControlReg(InstancePtr);
	XSpi_SetControlReg(InstancePtr, ControlReg |
			    XSP_CR_LOOPBACK_MASK | XSP_CR_MASTER_MODE_MASK);
	/*
	 * We do not need interrupts for this loopback test.
	 */
	XSpi_IntrGlobalDisable(InstancePtr);

	DataWidth = InstancePtr->DataWidth;
	/*
	 * Send data up to the maximum size of the transmit register, which is
	 * one byte without FIFOs.  We send data 4 times just to exercise the
	 * device through more than one iteration.
	 */
	for (Index = 0; Index < 4; Index++) {
		Data = 0;

		/*
		 * Fill the transmit register.
		 */
		StatusReg = XSpi_GetStatusReg(InstancePtr);
		while ((StatusReg & XSP_SR_TX_FULL_MASK) == 0) {
			if (DataWidth == XSP_DATAWIDTH_BYTE) {
				/*
				 * Data Transfer Width is Byte (8 bit).
				 */
				Data = 0;
			} else if (DataWidth == XSP_DATAWIDTH_HALF_WORD) {
				/*
				 * Data Transfer Width is Half Word (16 bit).
				 */
				Data = XSP_HALF_WORD_TESTBYTE;
			} else if (DataWidth == XSP_DATAWIDTH_WORD){
				/*
				 * Data Transfer Width is Word (32 bit).
				 */
				Data = XSP_WORD_TESTBYTE;
			}

			XSpi_WriteReg(InstancePtr->BaseAddr, XSP_DTR_OFFSET,
					Data + Index);
			NumSent += (DataWidth >> 3);
			StatusReg = XSpi_GetStatusReg(InstancePtr);
		}

		/*
		 * Start the transfer by not inhibiting the transmitter and
		 * enabling the device.
		 */
		ControlReg = XSpi_GetControlReg(InstancePtr) &
						 (~XSP_CR_TRANS_INHIBIT_MASK);
		XSpi_SetControlReg(InstancePtr, ControlReg |
				    XSP_CR_ENABLE_MASK);

		/*
		 * Wait for the transfer to be done by polling the transmit
		 * empty status bit.
		 */
		do {
			StatusReg = XSpi_IntrGetStatus(InstancePtr);
		} while ((StatusReg & XSP_INTR_TX_EMPTY_MASK) == 0);

		XSpi_IntrClear(InstancePtr, XSP_INTR_TX_EMPTY_MASK);

		/*
		 * Receive and verify the data just transmitted.
		 */
		StatusReg = XSpi_GetStatusReg(InstancePtr);
		while ((StatusReg & XSP_SR_RX_EMPTY_MASK) == 0) {

			RxData = XSpi_ReadReg(InstancePtr->BaseAddr,
						XSP_DRR_OFFSET);

			if (DataWidth == XSP_DATAWIDTH_BYTE) {
				if((u8)RxData != Index) {
					return XST_LOOPBACK_ERROR;
				}
			} else if (DataWidth ==
					XSP_DATAWIDTH_HALF_WORD) {
				if((u16)RxData != (u16)(Index +
						   XSP_HALF_WORD_TESTBYTE)) {
					return XST_LOOPBACK_ERROR;
				}
			} else if (DataWidth == XSP_DATAWIDTH_WORD) {
				if(RxData != (u32)(Index + XSP_WORD_TESTBYTE)) {
					return XST_LOOPBACK_ERROR;
				}
			}

			NumRecvd += (DataWidth >> 3);
			StatusReg = XSpi_GetStatusReg(InstancePtr);
		}

		/*
		 * Stop the transfer (hold off automatic sending) by inhibiting
		 * the transmitter and disabling the device.
		 */
		ControlReg |= XSP_CR_TRANS_INHIBIT_MASK;
		XSpi_SetControlReg(InstancePtr ,
				    ControlReg & ~ XSP_CR_ENABLE_MASK);
	}

	/*
	 * One final check to make sure the total number of bytes sent equals
	 * the total number of bytes received.
	 */
	if (NumSent != NumRecvd) {
		return XST_LOOPBACK_ERROR;
	}

	return XST_SUCCESS;
}
/** @} */
