/******************************************************************************
*
* Copyright (C) 2005 - 2015 Xilinx, Inc.  All rights reserved.
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
* @file xiic_sinit.c
* @addtogroup iic_v3_1
* @{
*
* The implementation of the Xiic component's static initialzation functionality.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- --- ------- -----------------------------------------------
* 1.02a jvb  10/13/05 release
* 1.13a wgr  03/22/07 Converted to new coding style.
* 2.00a ktn  10/22/09 Converted all register accesses to 32 bit access.
*		      Updated to use the HAL APIs/macros.
*		      Some of the macros have been renamed to remove _m from
*		      the name and some of the macros have been renamed to be
*		      consistent, see the xiic_i.h and xiic_l.h files for further
*		      information
* </pre>
*
****************************************************************************/

/***************************** Include Files *******************************/

#include "xstatus.h"
#include "xparameters.h"
#include "xiic_i.h"

/************************** Constant Definitions ***************************/


/**************************** Type Definitions *****************************/


/***************** Macros (Inline Functions) Definitions *******************/


/************************** Function Prototypes ****************************/

/************************** Variable Definitions **************************/


/*****************************************************************************/
/**
*
* Looks up the device configuration based on the unique device ID. The table
* IicConfigTable contains the configuration info for each device in the system.
*
* @param	DeviceId is the unique device ID to look for
*
* @return	A pointer to the configuration data of the device,
*		or NULL if no match is found.
*
* @note		None.
*
******************************************************************************/
XIic_Config *XIic_LookupConfig(u16 DeviceId)
{
	XIic_Config *CfgPtr = NULL;
	u32 Index;

	for (Index = 0; Index < XPAR_XIIC_NUM_INSTANCES; Index++) {
		if (XIic_ConfigTable[Index].DeviceId == DeviceId) {
			CfgPtr = &XIic_ConfigTable[Index];
			break;
		}
	}

	return CfgPtr;
}

/*****************************************************************************/
/**
*
* Initializes a specific XIic instance.  The initialization entails:
*
* - Check the device has an entry in the configuration table.
* - Initialize the driver to allow access to the device registers and
*   initialize other subcomponents necessary for the operation of the device.
* - Default options to:
*     - 7-bit slave addressing
*     - Send messages as a slave device
*     - Repeated start off
*     - General call recognition disabled
* - Clear messageing and error statistics
*
* The XIic_Start() function must be called after this function before the device
* is ready to send and receive data on the IIC bus.
*
* Before XIic_Start() is called, the interrupt control must connect the ISR
* routine to the interrupt handler. This is done by the user, and not
* XIic_Start() to allow the user to use an interrupt controller of their choice.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
* @param	DeviceId is the unique id of the device controlled by this XIic
*		instance.  Passing in a device id associates the generic XIic
*		instance to a specific device, as chosen by the caller or
*		application developer.
*
* @return
*		- XST_SUCCESS when successful
*		- XST_DEVICE_NOT_FOUND indicates the given device id isn't found
*		- XST_DEVICE_IS_STARTED indicates the device is started
*		(i.e. interrupts enabled and messaging is possible).
*		Must stop before re-initialization is allowed.
*
* @note		None.
*
****************************************************************************/
int XIic_Initialize(XIic *InstancePtr, u16 DeviceId)
{
	XIic_Config *ConfigPtr;	/* Pointer to configuration data */

	/*
	 * Asserts test the validity of selected input arguments.
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);

	/*
	 * Lookup the device configuration in the temporary CROM table. Use this
	 * configuration info down below when initializing this component.
	 */
	ConfigPtr = XIic_LookupConfig(DeviceId);
	if (ConfigPtr == NULL) {
		return XST_DEVICE_NOT_FOUND;
	}

	return XIic_CfgInitialize(InstancePtr, ConfigPtr,
				  ConfigPtr->BaseAddress);
}
/** @} */
