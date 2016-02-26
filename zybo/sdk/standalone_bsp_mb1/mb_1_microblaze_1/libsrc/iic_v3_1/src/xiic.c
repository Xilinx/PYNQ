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
* @file xiic.c
* @addtogroup iic_v3_1
* @{
*
* Contains required functions for the XIic component. See xiic.h for more
* information on the driver.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- --- ------- -----------------------------------------------
* 1.01a rfp  10/19/01 release
* 1.01c ecm  12/05/02 new rev
* 1.01c rmm  05/14/03 Fixed diab compiler warnings relating to asserts.
* 1.01d jhl  10/08/03 Added general purpose output feature
* 1.02a jvb  12/13/05 Added CfgInitialize(), and made CfgInitialize() take
*                     a pointer to a config structure instead of a device id.
*                     Moved Initialize() into xiic_sinit.c, and have
*                     Initialize() call CfgInitialize() after it retrieved the
*                     config structure using the device id. Removed include of
*                     xparameters.h along with any dependencies on xparameters.h
*                     and the _g.c config table.
* 1.02a mta  03/09/06 Added a new function XIic_IsIicBusy() which returns
*			whether IIC Bus is Busy or Free.
* 1.13a wgr  03/22/07 Converted to new coding style.
* 1.15a ktn  02/17/09 Fixed XIic_GetAddress() to return correct device address.
* 1.16a ktn  07/18/09 Updated the notes in XIic_Reset function to clearly
*                     indicate that only the Interrupt Registers are reset.
* 1.16a ktn  10/16/09 Updated the notes in the XIic_SelfTest() API to mention
*                     that the complete IIC core is Reset on giving a software
*                     reset to the IIC core. This issue is fixed in the latest
*                     version of the IIC core (some previous versions of the
*                     core only reset the Interrupt Logic/Registers), please
*		      see the Hw specification for further information.
* 2.00a ktn  10/22/09 Converted all register accesses to 32 bit access.
*		      Some of the macros have been renamed to remove _m from
*		      the name see the xiic_i.h and xiic_l.h file for further
*		      information (Example XIic_mClearIntr is now
*		      XIic_ClearIntr).
*		      Some of the macros have been renamed to be consistent,
*		      see the xiic_l.h file for further information
*		      (Example XIIC_WRITE_IIER is renamed as XIic_WriteIier).
*		      The driver has been updated to use the HAL APIs/macros.
* 2.07a adk   18/04/13 Updated the code to avoid unused variable warnings
*			  when compiling with the -Wextra -Wall flags.
*			  Changes done if files xiic.c and xiic_i.h. CR:705001.
*
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

static void XIic_StubStatusHandler(void *CallBackRef, int ErrorCode);

static void XIic_StubHandler(void *CallBackRef, int ByteCount);

/************************** Variable Definitions **************************/


/*****************************************************************************/
/**
*
* Initializes a specific XIic instance.  The initialization entails:
*
* - Initialize the driver to allow access to the device registers and
*   initialize other subcomponents necessary for the operation of the device.
* - Default options to:
*	 - 7-bit slave addressing
*	 - Send messages as a slave device
*	 - Repeated start off
*	 - General call recognition disabled
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
* @param	Config is a reference to a structure containing information
*		about a specific IIC device. This function can initialize
*		multiple instance objects with the use of multiple calls giving
*		different Config information on each call.
* @param	EffectiveAddr is the device base address in the virtual memory
*		address space. The caller is responsible for keeping the
*		address mapping from EffectiveAddr to the device physical base
*		address unchanged once this function is invoked. Unexpected
*		errors may occur if the address mapping changes after this
*		function is called. If address translation is not used, use
*		Config->BaseAddress for this parameters, passing the physical
*		address instead.
*
* @return
*		- XST_SUCCESS when successful
*		- XST_DEVICE_IS_STARTED indicates the device is started
*		(i.e. interrupts enabled and messaging is possible). Must stop
*		before re-initialization is allowed.
*
* @note		None.
*
****************************************************************************/
int XIic_CfgInitialize(XIic *InstancePtr, XIic_Config * Config,
			   u32 EffectiveAddr)
{
	/*
	 * Asserts test the validity of selected input arguments.
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);

	InstancePtr->IsReady = 0;

	/*
	 * If the device is started, disallow the initialize and return a Status
	 * indicating it is started.  This allows the user to stop the device
	 * and reinitialize, but prevents a user from inadvertently
	 * initializing.
	 */
	if (InstancePtr->IsStarted == XIL_COMPONENT_IS_STARTED) {
		return XST_DEVICE_IS_STARTED;
	}

	/*
	 * Set default values and configuration data, including setting the
	 * callback handlers to stubs  so the system will not crash should the
	 * application not assign its own callbacks.
	 */
	InstancePtr->IsStarted = 0;
	InstancePtr->BaseAddress = EffectiveAddr;
	InstancePtr->RecvHandler = XIic_StubHandler;
	InstancePtr->RecvBufferPtr = NULL;
	InstancePtr->SendHandler = XIic_StubHandler;
	InstancePtr->SendBufferPtr = NULL;
	InstancePtr->StatusHandler = XIic_StubStatusHandler;
	InstancePtr->Has10BitAddr = Config->Has10BitAddr;
	InstancePtr->IsReady = XIL_COMPONENT_IS_READY;
	InstancePtr->Options = 0;
	InstancePtr->BNBOnly = FALSE;
	InstancePtr->GpOutWidth = Config->GpOutWidth;
	InstancePtr->IsDynamic = FALSE;
	InstancePtr->IsSlaveSetAckOff = FALSE;

	/*
	 * Reset the device.
	 */
	XIic_Reset(InstancePtr);

	XIic_ClearStats(InstancePtr);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function starts the IIC device and driver by enabling the proper
* interrupts such that data may be sent and received on the IIC bus.
* This function must be called before the functions to send and receive data.
*
* Before XIic_Start() is called, the interrupt control must connect the ISR
* routine to the interrupt handler. This is done by the user, and not
* XIic_Start() to allow the user to use an interrupt controller of their choice.
*
* Start enables:
*  - IIC device
*  - Interrupts:
*	 - Addressed as slave to allow messages from another master
*	 - Arbitration Lost to detect Tx arbitration errors
*	 - Global IIC interrupt
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return	XST_SUCCESS always.
*
* @note
*
* The device interrupt is connected to the interrupt controller, but no
* "messaging" interrupts are enabled. Addressed as Slave is enabled to
* reception of messages when this devices address is written to the bus.
* The correct messaging interrupts are enabled when sending or receiving
* via the IicSend() and IicRecv() functions. No action is required
* by the user to control any IIC interrupts as the driver completely
* manages all 8 interrupts. Start and Stop control the ability
* to use the device. Stopping the device completely stops all device
* interrupts from the processor.
*
****************************************************************************/
int XIic_Start(XIic *InstancePtr)
{
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Mask off all interrupts, each is enabled when needed.
	 */
	XIic_WriteIier(InstancePtr->BaseAddress, 0);

	/*
	 * Clear all interrupts by reading and rewriting exact value back.
	 * Only those bits set will get written as 1 (writing 1 clears intr).
	 */
	XIic_ClearIntr(InstancePtr->BaseAddress, 0xFFFFFFFF);

	/*
	 * Enable the device.
	 */
	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,
		 XIIC_CR_ENABLE_DEVICE_MASK);
	/*
	 * Set Rx FIFO Occupancy depth to throttle at
	 * first byte(after reset = 0).
	 */
	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_RFD_REG_OFFSET, 0);

	/*
	 * Clear and enable the interrupts needed.
	 */
	XIic_ClearEnableIntr(InstancePtr->BaseAddress,
				XIIC_INTR_AAS_MASK | XIIC_INTR_ARB_LOST_MASK);

	InstancePtr->IsStarted = XIL_COMPONENT_IS_STARTED;
	InstancePtr->IsDynamic = FALSE;

	/*
	 * Enable the Global interrupt enable.
	 */
	XIic_IntrGlobalEnable(InstancePtr->BaseAddress);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function stops the IIC device and driver such that data is no longer
* sent or received on the IIC bus. This function stops the device by
* disabling interrupts. This function only disables interrupts within the
* device such that the caller is responsible for disconnecting the interrupt
* handler of the device from the interrupt source and disabling interrupts
* at other levels.
*
* Due to bus throttling that could hold the bus between messages when using
* repeated start option, stop will not occur when the device is actively
* sending or receiving data from the IIC bus or the bus is being throttled
* by this device, but instead return XST_IIC_BUS_BUSY.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return
*		- XST_SUCCESS indicates all IIC interrupts are disabled.
*		No messages can be received or transmitted until XIic_Start()
*		is called.
*		- XST_IIC_BUS_BUSY indicates this device is currently engaged
*		in message traffic and cannot be stopped.
*
* @note		None.
*
****************************************************************************/
int XIic_Stop(XIic *InstancePtr)
{
	u32 Status;
	u32 CntlReg;

	Xil_AssertNonvoid(InstancePtr != NULL);

	/*
	 * Disable all interrupts globally.
	 */
	XIic_IntrGlobalDisable(InstancePtr->BaseAddress);

	CntlReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);
	Status = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_SR_REG_OFFSET);

	if ((CntlReg & XIIC_CR_MSMS_MASK) ||
		(Status & XIIC_SR_ADDR_AS_SLAVE_MASK)) {
		/*
		 * When this device is using the bus
		 * - re-enable interrupts to finish current messaging
		 * - return bus busy
		 */
		XIic_IntrGlobalEnable(InstancePtr->BaseAddress);

		return XST_IIC_BUS_BUSY;
	}

	InstancePtr->IsStarted = 0;

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* Resets the IIC device.
*
* @param    InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return	None.
*
* @note     The complete IIC core is Reset on giving a software reset to
*           the IIC core. Some previous versions of the core only reset
*           the Interrupt Logic/Registers, please refer to the HW specification
*           for futher details about this.
*
****************************************************************************/
void XIic_Reset(XIic *InstancePtr)
{
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_RESETR_OFFSET,
			XIIC_RESET_MASK);
}

/*****************************************************************************/
/**
*
* This function sets the bus addresses. The addresses include the device
* address that the device responds to as a slave, or the slave address
* to communicate with on the bus.  The IIC device hardware is built to
* allow either 7 or 10 bit slave addressing only at build time rather
* than at run time. When this device is a master, slave addressing can
* be selected at run time to match addressing modes for other bus devices.
*
* Addresses are represented as hex values with no adjustment for the data
* direction bit as the software manages address bit placement.
* Example: For a 7 address written to the device of 1010 011X where X is
* the transfer direction (send/recv), the address parameter for this function
* needs to be 01010011 or 0x53 where the correct bit alllignment will be
* handled for 7 as well as 10 bit devices. This is especially important as
* the bit placement is not handled the same depending on which options are
* used such as repeated start.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
* @param	AddressType indicates which address is being modified, the
*		address which this device responds to on the IIC bus as a slave,
*		or the slave address to communicate with when this device is a
*		master. One of the following values must be contained in
*		this argument.
* <pre>
*   XII_ADDR_TO_SEND_TYPE	Slave being addressed by a this master
*   XII_ADDR_TO_RESPOND_TYPE	Address to respond to as a slave device
* </pre>
*
* @param	Address contains the address to be set, 7 bit or 10 bit address.
*		A ten bit address must be within the range: 0 - 1023 and a 7 bit
*		address must be within the range 0 - 127.
*
* @return
*		- XST_SUCCESS is returned if the address was successfully set.
*		- XST_IIC_NO_10_BIT_ADDRESSING indicates only 7 bit addressing
*		  supported.
*		- XST_INVALID_PARAM indicates an invalid parameter was
*		  specified.
*
* @note
*
* Upper bits of 10-bit address is written only when current device is built
* as a ten bit device.
*
****************************************************************************/
int XIic_SetAddress(XIic *InstancePtr, int AddressType, int Address)
{
	u32 SendAddr;

	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(Address < 1023);

	/*
	 * Set address to respond to for this device into address registers.
	 */
	if (AddressType == XII_ADDR_TO_RESPOND_TYPE) {
		/*
		 * Address in upper 7 bits.
		 */
		SendAddr = ((Address & 0x007F) << 1);
		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_ADR_REG_OFFSET,
				SendAddr);

		if (InstancePtr->Has10BitAddr == TRUE) {
			/*
			 * Write upper 3 bits of addr to DTR only when 10 bit
			 * option included in design i.e. register exists.
			 */
			SendAddr = ((Address & 0x0380) >> 7);
			XIic_WriteReg(InstancePtr->BaseAddress,
					XIIC_TBA_REG_OFFSET, SendAddr);
		}

		return XST_SUCCESS;
	}

	/*
	 * Store address of slave device being read from.
	 */
	if (AddressType == XII_ADDR_TO_SEND_TYPE) {
		InstancePtr->AddrOfSlave = Address;
		return XST_SUCCESS;
	}

	return XST_INVALID_PARAM;
}

/*****************************************************************************/
/**
*
* This function gets the addresses for the IIC device driver. The addresses
* include the device address that the device responds to as a slave, or the
* slave address to communicate with on the bus. The address returned has the
* same format whether 7 or 10 bits.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
* @param	AddressType indicates which address, the address which this
*		responds to on the IIC bus as a slave, or the slave address to
*		communicate with when this device is a master. One of the
*		following values must be contained in this argument.
* <pre>
*   XII_ADDR_TO_SEND_TYPE	Slave being addressed as a master
*   XII_ADDR_TO_RESPOND_TYPE	Slave address to respond to as a slave
* </pre>
*  If neither of the two valid arguments are used, the function returns
*  the address of the slave device
*
* @return	The address retrieved.
*
* @note		None.
*
****************************************************************************/
u16 XIic_GetAddress(XIic *InstancePtr, int AddressType)
{
	u8  LowAddr;
	u16 HighAddr = 0;

	Xil_AssertNonvoid(InstancePtr != NULL);

	/*
	 * Return this device's address.
	 */
	if (AddressType == XII_ADDR_TO_RESPOND_TYPE) {

		LowAddr = (u8) XIic_ReadReg(InstancePtr->BaseAddress,
					     XIIC_ADR_REG_OFFSET);

		if (InstancePtr->Has10BitAddr == TRUE) {
			HighAddr = (u16) XIic_ReadReg(InstancePtr->BaseAddress,
							XIIC_TBA_REG_OFFSET);
		}
		return ((HighAddr << 8) | (u16) LowAddr);
	}

	/*
	 * Otherwise return address of slave device on the IIC bus.
	 */
	return InstancePtr->AddrOfSlave;
}

/*****************************************************************************/
/**
*
* This function sets the contents of the General Purpose Output register
* for the IIC device driver. Note that the number of bits in this register is
* parameterizable in the hardware such that it may not exist.  This function
* checks to ensure that it does exist to prevent bus errors, but does not
* ensure that the number of bits in the register are sufficient for the
* value being written (won't cause a bus error).
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
* @param	OutputValue contains the value to be written to the register.
*
* @return
*		- XST_SUCCESS if the given data is written to the GPO register.
* 		- XST_NO_FEATURE if the hardware is configured such that this
*		register does not contain any bits to read or write.
*
* @note		None.
*
****************************************************************************/
int XIic_SetGpOutput(XIic *InstancePtr, u8 OutputValue)
{
	Xil_AssertNonvoid(InstancePtr != NULL);

	/*
	 * If the general purpose output register is implemented by the hardware
	 * then write the specified value to it, otherwise indicate an error.
	 */
	if (InstancePtr->GpOutWidth > 0) {
		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_GPO_REG_OFFSET,
				OutputValue);
		return XST_SUCCESS;
	} else {
		return XST_NO_FEATURE;
	}
}

/*****************************************************************************/
/**
*
* This function gets the contents of the General Purpose Output register
* for the IIC device driver. Note that the number of bits in this register is
* parameterizable in the hardware such that it may not exist. This function
* checks to ensure that it does exist to prevent bus errors.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
* @param	OutputValuePtr contains the value which was read from the
*		register.
*
* @return
*		- XST_SUCCESS if the given data is read from the GPO register.
* 		- XST_NO_FEATURE if the hardware is configured such that this
*		register does not contain any bits to read or write.
*
* The OutputValuePtr is also an output as it contains the value read.
*
* @note		None.
*
****************************************************************************/
int XIic_GetGpOutput(XIic *InstancePtr, u8 *OutputValuePtr)
{
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(OutputValuePtr != NULL);

	/*
	 * If the general purpose output register is implemented by the hardware
	 * then read the value from it, otherwise indicate an error.
	 */
	if (InstancePtr->GpOutWidth > 0) {
		*OutputValuePtr = XIic_ReadReg(InstancePtr->BaseAddress,
						XIIC_GPO_REG_OFFSET);
		return XST_SUCCESS;
	} else {
		return XST_NO_FEATURE;
	}
}

/*****************************************************************************/
/**
*
* A function to determine if the device is currently addressed as a slave.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return
* 		- TRUE if the device is addressed as slave.
*		- FALSE if the device is NOT addressed as slave.
*
* @note		None.
*
****************************************************************************/
u32 XIic_IsSlave(XIic *InstancePtr)
{
	Xil_AssertNonvoid(InstancePtr != NULL);

	if ((XIic_ReadReg(InstancePtr->BaseAddress, XIIC_SR_REG_OFFSET) &
		 XIIC_SR_ADDR_AS_SLAVE_MASK) == 0) {
		return FALSE;
	}
	return TRUE;
}

/*****************************************************************************/
/**
*
* Sets the receive callback function, the receive handler, which the driver
* calls when it finishes receiving data. The number of bytes used to signal
* when the receive is complete is the number of bytes set in the XIic_Recv
* function.
*
* The handler executes in an interrupt context such that it must minimize
* the amount of processing performed such as transferring data to a thread
* context.
*
* The number of bytes received is passed to the handler as an argument.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
* @param	CallBackRef is the upper layer callback reference passed back
*		when the callback function is invoked.
* @param	FuncPtr is the pointer to the callback function.
*
* @return	None.
*
* @note		The handler is called within interrupt context .
*
****************************************************************************/
void XIic_SetRecvHandler(XIic *InstancePtr, void *CallBackRef,
			 XIic_Handler FuncPtr)
{
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(FuncPtr != NULL);

	InstancePtr->RecvHandler = FuncPtr;
	InstancePtr->RecvCallBackRef = CallBackRef;
}

/*****************************************************************************/
/**
*
* Sets the send callback function, the send handler, which the driver calls when
* it receives confirmation of sent data. The handler executes in an interrupt
* context such that it must minimize the amount of processing performed such
* as transferring data to a thread context.
*
* @param	InstancePtr the pointer to the XIic instance to be worked on.
* @param	CallBackRef the upper layer callback reference passed back when
*		the callback function is invoked.
* @param	FuncPtr the pointer to the callback function.
*
* @return	None.
*
* @note		The handler is called within interrupt context .
*
****************************************************************************/
void XIic_SetSendHandler(XIic *InstancePtr, void *CallBackRef,
			 XIic_Handler FuncPtr)
{
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(FuncPtr != NULL);

	InstancePtr->SendHandler = FuncPtr;
	InstancePtr->SendCallBackRef = CallBackRef;
}

/*****************************************************************************/
/**
*
* Sets the status callback function, the status handler, which the driver calls
* when it encounters conditions which are not data related. The handler
* executes in an interrupt context such that it must minimize the amount of
* processing performed such as transferring data to a thread context. The
* status events that can be returned are described in xiic.h.
*
* @param	InstancePtr points to the XIic instance to be worked on.
* @param	CallBackRef is the upper layer callback reference passed back
*		when the callback function is invoked.
* @param	FuncPtr is the pointer to the callback function.
*
* @return	None.
*
* @note		The handler is called within interrupt context .
*
****************************************************************************/
void XIic_SetStatusHandler(XIic *InstancePtr, void *CallBackRef,
			   XIic_StatusHandler FuncPtr)
{
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(FuncPtr != NULL);

	InstancePtr->StatusHandler = FuncPtr;
	InstancePtr->StatusCallBackRef = CallBackRef;
}

/*****************************************************************************
*
* This is a stub for the send and recv callbacks. The stub is here in case the
* upper layers forget to set the handlers.
*
* @param	CallBackRef is a pointer to the upper layer callback reference
* @param	ByteCount is the number of bytes sent or received
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void XIic_StubHandler(void *CallBackRef, int ByteCount)
{
	(void) ByteCount;
	(void) CallBackRef;
	Xil_AssertVoidAlways();
}

/*****************************************************************************
*
* This is a stub for the asynchronous error callback. The stub is here in case
* the upper layers forget to set the handler.
*
* @param	CallBackRef is a pointer to the upper layer callback reference.
* @param	ErrorCode is the Xilinx error code, indicating the cause of
*		the error.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void XIic_StubStatusHandler(void *CallBackRef, int ErrorCode)
{
	(void) ErrorCode;
	(void) CallBackRef;
	Xil_AssertVoidAlways();
}

/*****************************************************************************
*
* This is a function which tells whether Bus is Busy or free.
*
* @param	InstancePtr points to the XIic instance to be worked on.
*
* @return
*		- TRUE if the Bus is Busy.
*		- FALSE if the Bus is NOT Busy.
*
* @note		None.
*
******************************************************************************/
u32 XIic_IsIicBusy(XIic *InstancePtr)
{
	u32 StatusReg;

	StatusReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_SR_REG_OFFSET);
	if (StatusReg & XIIC_SR_BUS_BUSY_MASK) {
		return TRUE;
	} else {
		return FALSE;
	}
}
/** @} */
