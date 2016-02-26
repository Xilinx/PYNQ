/******************************************************************************
*
* Copyright (C) 2005 - 2014 Xilinx, Inc.  All rights reserved.
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
* @file xspi_sinit.c
* @addtogroup spi_v4_1
* @{
*
* The implementation of the XSpi component's static initialization
* functionality.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.01a jvb  10/13/05 First release
* 1.11a wgr  03/22/07 Converted to new coding style.
*
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xparameters.h"
#include "xspi.h"

/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/

/************************** Variable Definitions *****************************/

extern XSpi_Config XSpi_ConfigTable[];

/*****************************************************************************/
/**
*
* Looks up the device configuration based on the unique device ID. A table
* contains the configuration info for each device in the system.
*
* @param	DeviceId contains the ID of the device to look up the
*		configuration for.
*
* @return
*
* A pointer to the configuration found or NULL if the specified device ID was
* not found. See xspi.h for the definition of XSpi_Config.
*
* @note		None.
*
******************************************************************************/
XSpi_Config *XSpi_LookupConfig(u16 DeviceId)
{
	XSpi_Config *CfgPtr = NULL;
	u32 Index;

	for (Index = 0; Index < XPAR_XSPI_NUM_INSTANCES; Index++) {
		if (XSpi_ConfigTable[Index].DeviceId == DeviceId) {
			CfgPtr = &XSpi_ConfigTable[Index];
			break;
		}
	}

	return CfgPtr;
}

/*****************************************************************************/
/**
*
* Initializes a specific XSpi instance such that the driver is ready to use.
*
* The state of the device after initialization is:
*	- Device is disabled
*	- Slave mode
*	- Active high clock polarity
*	- Clock phase 0
*
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
* @param	DeviceId is the unique id of the device controlled by this XSpi
*		instance. Passing in a device id associates the generic XSpi
*		instance to a specific device, as chosen by the caller or
*		application developer.
*
* @return
*
*		- XST_SUCCESS if successful.
*		- XST_DEVICE_IS_STARTED if the device is started. It must be
*		  stopped to re-initialize.
*		- XST_DEVICE_NOT_FOUND if the device was not found in the
*		  configuration such that initialization could not be
*		  accomplished.
*
* @note		None.
*
******************************************************************************/
int XSpi_Initialize(XSpi *InstancePtr, u16 DeviceId)
{
	XSpi_Config *ConfigPtr;	/* Pointer to Configuration ROM data */

	Xil_AssertNonvoid(InstancePtr != NULL);

	/*
	 * Lookup the device configuration in the temporary CROM table. Use this
	 * configuration info down below when initializing this component.
	 */
	ConfigPtr = XSpi_LookupConfig(DeviceId);
	if (ConfigPtr == NULL) {
		return XST_DEVICE_NOT_FOUND;
	}

	return XSpi_CfgInitialize(InstancePtr, ConfigPtr,
				  ConfigPtr->BaseAddress);

}
/** @} */
