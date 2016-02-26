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
* @file xspi_options.c
* @addtogroup spi_v4_1
* @{
*
* Contains functions for the configuration of the XSpi driver component.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00b jhl  2/27/02  First release
* 1.00b rpm  04/25/02 Collapsed IPIF and reg base addresses into one
* 1.11a wgr  03/22/07 Converted to new coding style.
* 3.00a ktn  10/28/09 Updated all the register accesses as 32 bit access.
*		      Updated driver to use the HAL APIs/macros.
*
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xspi.h"
#include "xspi_i.h"

/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/


/************************** Variable Definitions *****************************/

/*
 * Create the table of options which are processed to get/set the device
 * options. These options are table driven to allow easy maintenance and
 * expansion of the options.
 */
typedef struct {
	u32 Option;
	u32 Mask;
} OptionsMap;

static OptionsMap OptionsTable[] = {
	{XSP_LOOPBACK_OPTION, XSP_CR_LOOPBACK_MASK},
	{XSP_CLK_ACTIVE_LOW_OPTION, XSP_CR_CLK_POLARITY_MASK},
	{XSP_CLK_PHASE_1_OPTION, XSP_CR_CLK_PHASE_MASK},
	{XSP_MASTER_OPTION, XSP_CR_MASTER_MODE_MASK},
	{XSP_MANUAL_SSELECT_OPTION, XSP_CR_MANUAL_SS_MASK}
};

#define XSP_NUM_OPTIONS		(sizeof(OptionsTable) / sizeof(OptionsMap))

/*****************************************************************************/
/**
*
* This function sets the options for the SPI device driver. The options control
* how the device behaves relative to the SPI bus. The device must be idle
* rather than busy transferring data before setting these device options.
*
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
* @param	Options contains the specified options to be set. This is a bit
*		mask where a 1 means to turn the option on, and a 0 means to
*		turn the option off. One or more bit values may be contained in
*		the mask.
*		See the bit definitions named XSP_*_OPTIONS in the file xspi.h.
*
* @return
*		-XST_SUCCESS if options are successfully set.
*		- XST_DEVICE_BUSY if the device is currently transferring data.
*		The transfer must complete or be aborted before setting options.
*		- XST_SPI_SLAVE_ONLY if the caller attempted to configure a
*		slave-only device as a master.
*
* @note
*
* This function makes use of internal resources that are shared between the
* XSpi_Stop() and XSpi_SetOptions() functions. So if one task might be setting
* device options while another is trying to stop the device, the user is
* required to provide protection of this shared data (typically using a
* semaphore).
*
******************************************************************************/
int XSpi_SetOptions(XSpi *InstancePtr, u32 Options)
{
	u32 ControlReg;
	u32 Index;

	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Do not allow the slave select to change while a transfer is in
	 * progress.
	 * No need to worry about a critical section here since even if the Isr
	 * changes the busy flag just after we read it, the function will return
	 * busy and the caller can retry when notified that their current
	 * transfer is done.
	 */
	if (InstancePtr->IsBusy) {
		return XST_DEVICE_BUSY;
	}
	/*
	 * Do not allow master option to be set if the device is slave only.
	 */
	if ((Options & XSP_MASTER_OPTION) && (InstancePtr->SlaveOnly)) {
		return XST_SPI_SLAVE_ONLY;
	}

	ControlReg = XSpi_GetControlReg(InstancePtr);

	/*
	 * Loop through the options table, turning the option on or off
	 * depending on whether the bit is set in the incoming options flag.
	 */
	for (Index = 0; Index < XSP_NUM_OPTIONS; Index++) {
		if (Options & OptionsTable[Index].Option) {
			/*
			 *Turn it ON.
			 */
			ControlReg |= OptionsTable[Index].Mask;
		}
		else {
			/*
			 *Turn it OFF.
			 */
			ControlReg &= ~OptionsTable[Index].Mask;
		}
	}

	/*
	 * Now write the control register. Leave it to the upper layers
	 * to restart the device.
	 */
	XSpi_SetControlReg(InstancePtr, ControlReg);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function gets the options for the SPI device. The options control how
* the device behaves relative to the SPI bus.
*
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
*
* @return
*
* Options contains the specified options to be set. This is a bit mask where a
* 1 means to turn the option on, and a 0 means to turn the option off. One or
* more bit values may be contained in the mask. See the bit definitions named
* XSP_*_OPTIONS in the file xspi.h.
*
* @note		None.
*
******************************************************************************/
u32 XSpi_GetOptions(XSpi *InstancePtr)
{
	u32 OptionsFlag = 0;
	u32 ControlReg;
	u32 Index;

	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Get the control register to determine which options are currently
	 * set.
	 */
	ControlReg = XSpi_GetControlReg(InstancePtr);

	/*
	 * Loop through the options table to determine which options are set.
	 */
	for (Index = 0; Index < XSP_NUM_OPTIONS; Index++) {
		if (ControlReg & OptionsTable[Index].Mask) {
			OptionsFlag |= OptionsTable[Index].Option;
		}
	}

	return OptionsFlag;
}
/** @} */
