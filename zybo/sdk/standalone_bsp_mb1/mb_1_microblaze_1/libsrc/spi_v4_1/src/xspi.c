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
* @file xspi.c
* @addtogroup spi_v4_1
* @{
*
* Contains required functions of the XSpi driver component.  See xspi.h for
* a detailed description of the device and driver.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a rpm  10/11/01 First release
* 1.00b jhl  03/14/02 Repartitioned driver for smaller files.
* 1.00b rpm  04/25/02 Collapsed IPIF and reg base addresses into one
* 1.00b rmm  05/14/03 Fixed diab compiler warnings relating to asserts
* 1.01a jvb  12/13/05 Changed Initialize() into CfgInitialize(), and made
*                     CfgInitialize() take a pointer to a config structure
*                     instead of a device id. Moved Initialize() into
*                     xspi_sinit.c, and had Initialize() call CfgInitialize()
*                     after it retrieved the config structure using the device
*                     id. Removed include of xparameters.h along with any
*                     dependencies on xparameters.h and the _g.c config table.
* 1.11a wgr  03/22/07 Converted to new coding style.
* 1.11a rpm  01/22/08 Updated comment on Transfer regarding needing interrupts.
* 1.12a sdm  03/27/08 Updated the code to support 16/32 bit transfer width and
*                     polled mode of operation. Even for the polled mode of
*                     operation the Interrupt Logic in the core should be
*                     included. The driver can be put in polled mode of
*                     operation by disabling the Global Interrupt after the
*                     Spi Initialization is completed.
* 2.00a sdm  07/30/08 Updated the code to support 16/32 bit transfer width and
*                     polled mode of operation. Even for the polled mode of
*                     operation the Interrupt Logic in the core should be
*                     included. The driver can be put in polled mode of
*                     operation by disabling the Global Interrupt after the
*                     Spi Initialization is completed.
* 2.01b sdm  04/08/09 Fixed an issue in the XSpi_Transfer function where the
*                     Global Interrupt is being enabled in polled mode when a
*                     slave is not selected.
* 3.00a ktn  10/28/09 Updated all the register accesses as 32 bit access.
*		      Updated to use the HAL APIs/macros.
*		      Removed the macro XSpi_mReset, XSpi_Reset API should be
*		      used in its place.
*		      The macros have been renamed to remove _m from the name.
*		      Removed an unnecessary read to the core register in the
*		      XSpi_GetSlaveSelect API.
* 3.01a sdm  04/23/10 Updated the driver to handle new slave mode interrupts
*		      and the DTR Half Empty interrupt.
* 3.04a bss  03/21/12 Updated XSpi_CfgInitialize to support XIP Mode
* 3.05a adk  18/04/13 Updated the code to avoid unused variable 
*	              warnings when compiling with the -Wextra -Wall flags
*		      In the file xspi.c. CR:705005.
* 3.06a adk  07/08/13 Added a dummy read in the CfgInitialize(), if startup
*		      block is used in the h/w design (CR 721229).
* 3.07a adk 11/10/13  In the xspi_transfer function moved the assert slave chip
* 		      select after the configuration of the Data Transmit 
*		      register inorder to work with CPOL and CPHA High Options.
* 		      As per spec (Dual/Quad SPI Transaction instrunction 7,8,9)
* 		      CR:732962
* 4.1	bss 08/07/14  Modified XSpi_Transfer to check for Interrupt Status
*		      register Tx Empty bit instead of Status register
*		      CR#810294.
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

static void StubStatusHandler(void *CallBackRef, u32 StatusEvent,
				unsigned int ByteCount);

void XSpi_Abort(XSpi *InstancePtr);

/************************** Variable Definitions *****************************/


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
* @param	Config is a reference to a structure containing information
*		about a specific SPI device. This function initializes an
*		InstancePtr object for a specific device specified by the
*		contents of Config. This function can initialize multiple
*		instance objects with the use of multiple calls giving
		different Config information on each call.
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
*		- XST_SUCCESS if successful.
*		- XST_DEVICE_IS_STARTED if the device is started. It must be
*		  stopped to re-initialize.
*
* @note		None.
*
******************************************************************************/
int XSpi_CfgInitialize(XSpi *InstancePtr, XSpi_Config *Config,
			u32 EffectiveAddr)
{
	u8  Buffer[3];
	u32 ControlReg;
	
	Xil_AssertNonvoid(InstancePtr != NULL);

	/*
	 * If the device is started, disallow the initialize and return a status
	 * indicating it is started.  This allows the user to stop the device
	 * and reinitialize, but prevents a user from inadvertently
	 * initializing.
	 */
	if (InstancePtr->IsStarted == XIL_COMPONENT_IS_STARTED) {
		return XST_DEVICE_IS_STARTED;
	}

	/*
	 * Set some default values.
	 */
	InstancePtr->IsStarted = 0;
	InstancePtr->IsBusy = FALSE;

	InstancePtr->StatusHandler = StubStatusHandler;

	InstancePtr->SendBufferPtr = NULL;
	InstancePtr->RecvBufferPtr = NULL;
	InstancePtr->RequestedBytes = 0;
	InstancePtr->RemainingBytes = 0;
	InstancePtr->BaseAddr = EffectiveAddr;
	InstancePtr->HasFifos = Config->HasFifos;
	InstancePtr->SlaveOnly = Config->SlaveOnly;
	InstancePtr->NumSlaveBits = Config->NumSlaveBits;
	if (Config->DataWidth == 0) {
		InstancePtr->DataWidth = XSP_DATAWIDTH_BYTE;
	} else {
		InstancePtr->DataWidth = Config->DataWidth;
	}

	InstancePtr->SpiMode = Config->SpiMode;

	InstancePtr->FlashBaseAddr = Config->AxiFullBaseAddress;
	InstancePtr->XipMode = Config->XipMode;

	InstancePtr->IsReady = XIL_COMPONENT_IS_READY;

	/*
	 * Create a slave select mask based on the number of bits that can
	 * be used to deselect all slaves, initialize the value to put into
	 * the slave select register to this value.
	 */
	InstancePtr->SlaveSelectMask = (1 << InstancePtr->NumSlaveBits) - 1;
	InstancePtr->SlaveSelectReg = InstancePtr->SlaveSelectMask;

	/*
	 * Clear the statistics for this driver.
	 */
	InstancePtr->Stats.ModeFaults = 0;
	InstancePtr->Stats.XmitUnderruns = 0;
	InstancePtr->Stats.RecvOverruns = 0;
	InstancePtr->Stats.SlaveModeFaults = 0;
	InstancePtr->Stats.BytesTransferred = 0;
	InstancePtr->Stats.NumInterrupts = 0;
	
        if(Config->Use_Startup == 1) {
		/*  
		 * Perform a dummy read this is used when startup block is
		 * enabled in the hardware to fix CR #721229.
		 */
		ControlReg = XSpi_GetControlReg(InstancePtr);
		ControlReg |= XSP_CR_TXFIFO_RESET_MASK | XSP_CR_RXFIFO_RESET_MASK |
				XSP_CR_ENABLE_MASK | XSP_CR_MASTER_MODE_MASK ;
		XSpi_SetControlReg(InstancePtr, ControlReg);
		
		/* 
		 * Initiate Read command to get the ID. This Read command is for
		 * Numonyx flash.
		 *
		 * NOTE: If user interfaces different flash to the SPI controller 
		 * this command need to be changed according to target flash Read
		 * command.
		 */
		Buffer[0] = 0x9F;
		Buffer[1] = 0x00;
		Buffer[2] = 0x00;
	
		/* Write dummy ReadId to the DTR register */
		XSpi_WriteReg(InstancePtr->BaseAddr, XSP_DTR_OFFSET, Buffer[0]);
		XSpi_WriteReg(InstancePtr->BaseAddr, XSP_DTR_OFFSET, Buffer[1]);
		XSpi_WriteReg(InstancePtr->BaseAddr, XSP_DTR_OFFSET, Buffer[2]);
	
		/* Master Inhibit enable in the CR */
		ControlReg = XSpi_GetControlReg(InstancePtr);
		ControlReg &= ~XSP_CR_TRANS_INHIBIT_MASK;
		XSpi_SetControlReg(InstancePtr, ControlReg);
	
		/* Master Inhibit disable in the CR */
		ControlReg = XSpi_GetControlReg(InstancePtr);
		ControlReg |= XSP_CR_TRANS_INHIBIT_MASK;
		XSpi_SetControlReg(InstancePtr, ControlReg);
		
		/* Read the Rx Data Register */
		XSpi_ReadReg(InstancePtr->BaseAddr, XSP_DRR_OFFSET);
		XSpi_ReadReg(InstancePtr->BaseAddr, XSP_DRR_OFFSET);
	}
	
	/*
	 * Reset the SPI device to get it into its initial state. It is expected
	 * that device configuration will take place after this initialization
	 * is done, but before the device is started.
	 */
	XSpi_Reset(InstancePtr);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function enables interrupts for the SPI device. If the Spi driver is used
* in interrupt mode, it is up to the user to connect the SPI interrupt handler
* to the interrupt controller before this function is called. If the Spi driver
* is used in polled mode the user has to disable the Global Interrupts after
* this function is called. If the device is configured with FIFOs, the FIFOs are
* reset at this time.
*
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
*
* @return
*		- XST_SUCCESS if the device is successfully started
*		- XST_DEVICE_IS_STARTED if the device was already started.
*
* @note		None.
*
******************************************************************************/
int XSpi_Start(XSpi *InstancePtr)
{
	u32 ControlReg;

	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * If it is already started, return a status indicating so.
	 */
	if (InstancePtr->IsStarted == XIL_COMPONENT_IS_STARTED) {
		return XST_DEVICE_IS_STARTED;
	}

	/*
	 * Enable the interrupts.
	 */
	XSpi_IntrEnable(InstancePtr, XSP_INTR_DFT_MASK);

	/*
	 * Indicate that the device is started before we enable the transmitter
	 * or receiver or interrupts.
	 */
	InstancePtr->IsStarted = XIL_COMPONENT_IS_STARTED;

	/*
	 * Reset the transmit and receive FIFOs if present. There is a critical
	 * section here since this register is also modified during interrupt
	 * context. So we wait until after the r/m/w of the control register to
	 * enable the Global Interrupt Enable.
	 */
	ControlReg = XSpi_GetControlReg(InstancePtr);
	ControlReg |= XSP_CR_TXFIFO_RESET_MASK | XSP_CR_RXFIFO_RESET_MASK |
			XSP_CR_ENABLE_MASK;
	XSpi_SetControlReg(InstancePtr, ControlReg);

	/*
	 * Enable the Global Interrupt Enable just after we start.
	 */
	XSpi_IntrGlobalEnable(InstancePtr);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function stops the SPI device by disabling interrupts and disabling the
* device itself. Interrupts are disabled only within the device itself. If
* desired, the caller is responsible for disabling interrupts in the interrupt
* controller and disconnecting the interrupt handler from the interrupt
* controller.
*
* In interrupt mode, if the device is in progress of transferring data on the
* SPI bus, this function returns a status indicating the device is busy. The
* user will be notified via the status handler when the transfer is complete,
* and at that time can again try to stop the device. As a master, we do not
* allow the device to be stopped while a transfer is in progress because the
* slave may be left in a bad state. As a slave, we do not allow the device to be
* stopped while a transfer is in progress because the master is not done with
* its transfer yet.
*
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
*
* @return
* 		- XST_SUCCESS if the device is successfully started.
*		- XST_DEVICE_BUSY if a transfer is in progress and cannot be
*		  stopped.
*
* @note
*
* This function makes use of internal resources that are shared between the
* XSpi_Stop() and XSpi_SetOptions() functions. So if one task might be setting
* device options while another is trying to stop the device, the user is
* is required to provide protection of this shared data (typically using a
* semaphore).
*
******************************************************************************/
int XSpi_Stop(XSpi *InstancePtr)
{
	u32 ControlReg;

	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Do not allow the user to stop the device while a transfer is in
	 * progress.
	 */
	if (InstancePtr->IsBusy) {
		return XST_DEVICE_BUSY;
	}

	/*
	 * Disable the device. First disable the interrupts since there is
	 * a critical section here because this register is also modified during
	 * interrupt context. The device is likely disabled already since there
	 * is no transfer in progress, but we do it again just to be sure.
	 */
	XSpi_IntrGlobalDisable(InstancePtr);

	ControlReg = XSpi_GetControlReg(InstancePtr);
	XSpi_SetControlReg(InstancePtr, ControlReg & ~XSP_CR_ENABLE_MASK);

	InstancePtr->IsStarted = 0;

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* Resets the SPI device by writing to the Software Reset register. Reset must
* only be called after the driver has been initialized. The configuration of the
* device after reset is the same as its configuration after initialization.
* Refer to the XSpi_Initialize function for more details. This is a hard reset
* of the device. Any data transfer that is in progress is aborted.
*
* The upper layer software is responsible for re-configuring (if necessary)
* and restarting the SPI device after the reset.
*
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XSpi_Reset(XSpi *InstancePtr)
{
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Abort any transfer that is in progress.
	 */
	XSpi_Abort(InstancePtr);

	/*
	 * Reset any values that are not reset by the hardware reset such that
	 * the software state matches the hardware device.
	 */
	InstancePtr->IsStarted = 0;
	InstancePtr->SlaveSelectReg = InstancePtr->SlaveSelectMask;

	/*
	 * Reset the device.
	 */
	XSpi_WriteReg(InstancePtr->BaseAddr, XSP_SRR_OFFSET,
			XSP_SRR_RESET_MASK);
}

/*****************************************************************************/
/**
*
* Transfers the specified data on the SPI bus. If the SPI device is configured
* to be a master, this function initiates bus communication and sends/receives
* the data to/from the selected SPI slave. If the SPI device is configured to
* be a slave, this function prepares the data to be sent/received when selected
* by a master. For every byte sent, a byte is received.
*
* This function/driver operates in interrupt mode and polled mode.
*  - In interrupt mode this function is non-blocking and the transfer is
*    initiated by this function and completed by the interrupt service routine.
*  - In polled mode this function is blocking and the control exits this
*    function only after all the requested data is transferred.
*
* The caller has the option of providing two different buffers for send and
* receive, or one buffer for both send and receive, or no buffer for receive.
* The receive buffer must be at least as big as the send buffer to prevent
* unwanted memory writes. This implies that the byte count passed in as an
* argument must be the smaller of the two buffers if they differ in size.
* Here are some sample usages:
* <pre>
*	XSpi_Transfer(InstancePtr, SendBuf, RecvBuf, ByteCount)
*	The caller wishes to send and receive, and provides two different
*	buffers for send and receive.
*
*	XSpi_Transfer(InstancePtr, SendBuf, NULL, ByteCount)
*	The caller wishes only to send and does not care about the received
*	data. The driver ignores the received data in this case.
*
*	XSpi_Transfer(InstancePtr, SendBuf, SendBuf, ByteCount)
*	The caller wishes to send and receive, but provides the same buffer
*	for doing both. The driver sends the data and overwrites the send
*	buffer with received data as it transfers the data.
*
*	XSpi_Transfer(InstancePtr, RecvBuf, RecvBuf, ByteCount)
*	The caller wishes to only receive and does not care about sending
*	data.  In this case, the caller must still provide a send buffer, but
*	it can be the same as the receive buffer if the caller does not care
*	what it sends. The device must send N bytes of data if it wishes to
*	receive N bytes of data.
* </pre>
* In interrupt mode, though this function takes a buffer as an argument, the
* driver can only transfer a limited number of bytes at time. It transfers only
* one byte at a time if there are no FIFOs, or it can transfer the number of
* bytes up to the size of the FIFO if FIFOs exist.
*  - In interrupt mode a call to this function only starts the transfer, the
*    subsequent transfer of the data is performed by the interrupt service
*    routine until the entire buffer has been transferred.The status callback
*    function is called when the entire buffer has been sent/received.
*  - In polled mode this function is blocking and the control exits this
*    function only after all the requested data is transferred.
*
* As a master, the SetSlaveSelect function must be called prior to this
* function.
*
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
* @param	SendBufPtr is a pointer to a buffer of data which is to be sent.
*		This buffer must not be NULL.
* @param	RecvBufPtr is a pointer to a buffer which will be filled with
*		received data. This argument can be NULL if the caller does not
*		wish to receive data.
* @param	ByteCount contains the number of bytes to send/receive. The
*		number of bytes received always equals the number of bytes sent.
*
* @return
*		-XST_SUCCESS if the buffers are successfully handed off to the
*		driver for transfer. Otherwise, returns:
*		- XST_DEVICE_IS_STOPPED if the device must be started before
*		transferring data.
*		- XST_DEVICE_BUSY indicates that a data transfer is already in
*		progress. This is determined by the driver.
*		- XST_SPI_NO_SLAVE indicates the device is configured as a
*		master and a slave has not yet been selected.
*
* @notes
*
* This function is not thread-safe.  The higher layer software must ensure that
* no two threads are transferring data on the SPI bus at the same time.
*
******************************************************************************/
int XSpi_Transfer(XSpi *InstancePtr, u8 *SendBufPtr,
		  u8 *RecvBufPtr, unsigned int ByteCount)
{
	u32 ControlReg;
	u32 GlobalIntrReg;
	u32 StatusReg;
	u32 Data = 0;
	u8  DataWidth;

	/*
	 * The RecvBufPtr argument can be NULL.
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(SendBufPtr != NULL);
	Xil_AssertNonvoid(ByteCount > 0);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	if (InstancePtr->IsStarted != XIL_COMPONENT_IS_STARTED) {
		return XST_DEVICE_IS_STOPPED;
	}

	/*
	 * Make sure there is not a transfer already in progress. No need to
	 * worry about a critical section here. Even if the Isr changes the bus
	 * flag just after we read it, a busy error is returned and the caller
	 * can retry when it gets the status handler callback indicating the
	 * transfer is done.
	 */
	if (InstancePtr->IsBusy) {
		return XST_DEVICE_BUSY;
	}

	/*
	 * Save the Global Interrupt Enable Register.
	 */
	GlobalIntrReg = XSpi_IsIntrGlobalEnabled(InstancePtr);

	/*
	 * Enter a critical section from here to the end of the function since
	 * state is modified, an interrupt is enabled, and the control register
	 * is modified (r/m/w).
	 */
	XSpi_IntrGlobalDisable(InstancePtr);

	ControlReg = XSpi_GetControlReg(InstancePtr);

	/*
	 * If configured as a master, be sure there is a slave select bit set
	 * in the slave select register. If no slaves have been selected, the
	 * value of the register will equal the mask.  When the device is in
	 * loopback mode, however, no slave selects need be set.
	 */
	if (ControlReg & XSP_CR_MASTER_MODE_MASK) {
		if ((ControlReg & XSP_CR_LOOPBACK_MASK) == 0) {
			if (InstancePtr->SlaveSelectReg ==
				InstancePtr->SlaveSelectMask) {
				if (GlobalIntrReg == TRUE) {
					/* Interrupt Mode of operation */
					XSpi_IntrGlobalEnable(InstancePtr);
				}
				return XST_SPI_NO_SLAVE;
			}
		}
	}

	/*
	 * Set the busy flag, which will be cleared when the transfer
	 * is completely done.
	 */
	InstancePtr->IsBusy = TRUE;

	/*
	 * Set up buffer pointers.
	 */
	InstancePtr->SendBufferPtr = SendBufPtr;
	InstancePtr->RecvBufferPtr = RecvBufPtr;

	InstancePtr->RequestedBytes = ByteCount;
	InstancePtr->RemainingBytes = ByteCount;

	DataWidth = InstancePtr->DataWidth;

	/*
	 * Fill the DTR/FIFO with as many bytes as it will take (or as many as
	 * we have to send). We use the tx full status bit to know if the device
	 * can take more data. By doing this, the driver does not need to know
	 * the size of the FIFO or that there even is a FIFO. The downside is
	 * that the status register must be read each loop iteration.
	 */
	StatusReg = XSpi_GetStatusReg(InstancePtr);

	while (((StatusReg & XSP_SR_TX_FULL_MASK) == 0) &&
		(InstancePtr->RemainingBytes > 0)) {
		if (DataWidth == XSP_DATAWIDTH_BYTE) {
			/*
			 * Data Transfer Width is Byte (8 bit).
			 */
			Data = *InstancePtr->SendBufferPtr;
		} else if (DataWidth == XSP_DATAWIDTH_HALF_WORD) {
			/*
			 * Data Transfer Width is Half Word (16 bit).
			 */
			Data = *(u16 *)InstancePtr->SendBufferPtr;
		} else if (DataWidth == XSP_DATAWIDTH_WORD){
			/*
			 * Data Transfer Width is Word (32 bit).
			 */
			Data = *(u32 *)InstancePtr->SendBufferPtr;
		}

		XSpi_WriteReg(InstancePtr->BaseAddr, XSP_DTR_OFFSET, Data);
		InstancePtr->SendBufferPtr += (DataWidth >> 3);
		InstancePtr->RemainingBytes -= (DataWidth >> 3);
		StatusReg = XSpi_GetStatusReg(InstancePtr);
	}

	
	/*
	 * Set the slave select register to select the device on the SPI before
	 * starting the transfer of data.
	 */
	XSpi_SetSlaveSelectReg(InstancePtr,
				InstancePtr->SlaveSelectReg);
				
	/*
	 * Start the transfer by no longer inhibiting the transmitter and
	 * enabling the device. For a master, this will in fact start the
	 * transfer, but for a slave it only prepares the device for a transfer
	 * that must be initiated by a master.
	 */
	ControlReg = XSpi_GetControlReg(InstancePtr);
	ControlReg &= ~XSP_CR_TRANS_INHIBIT_MASK;
	XSpi_SetControlReg(InstancePtr, ControlReg);

	/*
	 * If the interrupts are enabled as indicated by Global Interrupt
	 * Enable Register, then enable the transmit empty interrupt to operate
	 * in Interrupt mode of operation.
	 */
	if (GlobalIntrReg == TRUE) { /* Interrupt Mode of operation */

		/*
		 * Enable the transmit empty interrupt, which we use to
		 * determine progress on the transmission.
		 */
		XSpi_IntrEnable(InstancePtr, XSP_INTR_TX_EMPTY_MASK);

		/*
		 * End critical section.
		 */
		XSpi_IntrGlobalEnable(InstancePtr);

	} else { /* Polled mode of operation */

		/*
		 * If interrupts are not enabled, poll the status register to
		 * Transmit/Receive SPI data.
		 */
		while(ByteCount > 0) {

			/*
			 * Wait for the transfer to be done by polling the
			 * Transmit empty status bit
			 */
			do {
				StatusReg = XSpi_IntrGetStatus(InstancePtr);
			} while ((StatusReg & XSP_INTR_TX_EMPTY_MASK) == 0);

			XSpi_IntrClear(InstancePtr,XSP_INTR_TX_EMPTY_MASK);

			/*
			 * A transmit has just completed. Process received data
			 * and check for more data to transmit. Always inhibit
			 * the transmitter while the transmit register/FIFO is
			 * being filled, or make sure it is stopped if we're
			 * done.
			 */
			ControlReg = XSpi_GetControlReg(InstancePtr);
			XSpi_SetControlReg(InstancePtr, ControlReg |
						XSP_CR_TRANS_INHIBIT_MASK);

			/*
			 * First get the data received as a result of the
			 * transmit that just completed. We get all the data
			 * available by reading the status register to determine
			 * when the Receive register/FIFO is empty. Always get
			 * the received data, but only fill the receive
			 * buffer if it points to something (the upper layer
			 * software may not care to receive data).
			 */
			StatusReg = XSpi_GetStatusReg(InstancePtr);

			while ((StatusReg & XSP_SR_RX_EMPTY_MASK) == 0) {

				Data = XSpi_ReadReg(InstancePtr->BaseAddr,
								XSP_DRR_OFFSET);
				if (DataWidth == XSP_DATAWIDTH_BYTE) {
					/*
					 * Data Transfer Width is Byte (8 bit).
					 */
					if(InstancePtr->RecvBufferPtr != NULL) {
						*InstancePtr->RecvBufferPtr++ =
							(u8)Data;
					}
				} else if (DataWidth ==
						XSP_DATAWIDTH_HALF_WORD) {
					/*
					 * Data Transfer Width is Half Word
					 * (16 bit).
					 */
					if (InstancePtr->RecvBufferPtr != NULL){
					    *(u16 *)InstancePtr->RecvBufferPtr =
							(u16)Data;
						InstancePtr->RecvBufferPtr += 2;
					}
				} else if (DataWidth == XSP_DATAWIDTH_WORD) {
					/*
					 * Data Transfer Width is Word (32 bit).
					 */
					if (InstancePtr->RecvBufferPtr != NULL){
					    *(u32 *)InstancePtr->RecvBufferPtr =
							Data;
						InstancePtr->RecvBufferPtr += 4;
					}
				}
				InstancePtr->Stats.BytesTransferred +=
						(DataWidth >> 3);
				ByteCount -= (DataWidth >> 3);
				StatusReg = XSpi_GetStatusReg(InstancePtr);
			}

			if (InstancePtr->RemainingBytes > 0) {

				/*
				 * Fill the DTR/FIFO with as many bytes as it
				 * will take (or as many as we have to send).
				 * We use the Tx full status bit to know if the
				 * device can take more data.
				 * By doing this, the driver does not need to
				 * know the size of the FIFO or that there even
				 * is a FIFO.
				 * The downside is that the status must be read
				 * each loop iteration.
				 */
				StatusReg = XSpi_GetStatusReg(InstancePtr);

				while(((StatusReg & XSP_SR_TX_FULL_MASK)== 0) &&
					(InstancePtr->RemainingBytes > 0)) {
					if (DataWidth == XSP_DATAWIDTH_BYTE) {
						/*
						 * Data Transfer Width is Byte
						 * (8 bit).
						 */
						Data = *InstancePtr->
								SendBufferPtr;

					} else if (DataWidth ==
						XSP_DATAWIDTH_HALF_WORD) {

						/*
						 * Data Transfer Width is Half
						 * Word (16 bit).
			 			 */
						Data = *(u16 *)InstancePtr->
								SendBufferPtr;
					} else if (DataWidth ==
							XSP_DATAWIDTH_WORD) {
						/*
						 * Data Transfer Width is Word
						 * (32 bit).
			 			 */
						Data = *(u32 *)InstancePtr->
								SendBufferPtr;
					}
					XSpi_WriteReg(InstancePtr->BaseAddr,
							XSP_DTR_OFFSET, Data);
					InstancePtr->SendBufferPtr +=
							(DataWidth >> 3);
					InstancePtr->RemainingBytes -=
							(DataWidth >> 3);
					StatusReg = XSpi_GetStatusReg(
							InstancePtr);
				}

				/*
				 * Start the transfer by not inhibiting the
				 * transmitter any longer.
				 */
				ControlReg = XSpi_GetControlReg(InstancePtr);
				ControlReg &= ~XSP_CR_TRANS_INHIBIT_MASK;
				XSpi_SetControlReg(InstancePtr, ControlReg);
			}
		}

		/*
		 * Stop the transfer (hold off automatic sending) by inhibiting
		 * the transmitter.
		 */
		ControlReg = XSpi_GetControlReg(InstancePtr);
		XSpi_SetControlReg(InstancePtr,
				    ControlReg | XSP_CR_TRANS_INHIBIT_MASK);

		/*
		 * Select the slave on the SPI bus when the transfer is
		 * complete, this is necessary for some SPI devices,
		 * such as serial EEPROMs work correctly as chip enable
		 * may be connected to slave select
		 */
		XSpi_SetSlaveSelectReg(InstancePtr,
					InstancePtr->SlaveSelectMask);
		InstancePtr->IsBusy = FALSE;
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* Selects or deselect the slave with which the master communicates. Each slave
* that can be selected is represented in the slave select register by a bit.
* The argument passed to this function is the bit mask with a 1 in the bit
* position of the slave being selected. Only one slave can be selected.
*
* The user is not allowed to deselect the slave while a transfer is in progress.
* If no transfer is in progress, the user can select a new slave, which
* implicitly deselects the current slave. In order to explicitly deselect the
* current slave, a zero can be passed in as the argument to the function.
*
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
* @param	SlaveMask is a 32-bit mask with a 1 in the bit position of the
*		slave being selected. Only one slave can be selected. The
*		SlaveMask can be zero if the slave is being deselected.
*
* @return
* 		- XST_SUCCESS if the slave is selected or deselected
*		successfully.
*		- XST_DEVICE_BUSY if a transfer is in progress, slave cannot be
*		changed
*		- XST_SPI_TOO_MANY_SLAVES if more than one slave is being
*		selected.
*
* @note
*
* This function only sets the slave which will be selected when a transfer
* occurs. The slave is not selected when the SPI is idle. The slave select
* has no affect when the device is configured as a slave.
*
******************************************************************************/
int XSpi_SetSlaveSelect(XSpi *InstancePtr, u32 SlaveMask)
{
	int NumAsserted;
	int Index;

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
	 * Verify that only one bit in the incoming slave mask is set.
	 */
	NumAsserted = 0;
	for (Index = (InstancePtr->NumSlaveBits - 1); Index >= 0; Index--) {
		if ((SlaveMask >> Index) & 0x1) {
			/* this bit is asserted */
			NumAsserted++;
		}
	}

	/*
	 * Return an error if more than one slave is selected.
	 */
	if (NumAsserted > 1) {
		return XST_SPI_TOO_MANY_SLAVES;
	}

	/*
	 * A single slave is either being selected or the incoming SlaveMask is
	 * zero, which means the slave is being deselected. Setup the value to
	 * be  written to the slave select register as the inverse of the slave
	 * mask.
	 */
	InstancePtr->SlaveSelectReg = ~SlaveMask;

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* Gets the current slave select bit mask for the SPI device.
*
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
*
* @return	The value returned is a 32-bit mask with a 1 in the bit position
*		of the slave currently selected. The value may be zero if no
*		slaves are selected.
*
* @note		This API is used to get the current slave select bit mask
*		that was set using the XSpi_SetSlaveSelect API.
*		This API deos not read the register from the core and returns
*		the slave select register stored in the instance pointer.
*
******************************************************************************/
u32 XSpi_GetSlaveSelect(XSpi *InstancePtr)
{
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Return the inverse of the value contained in
	 * InstancePtr->SlaveSelectReg. This value is set using the API
	 * XSpi_SetSlaveSelect.
	 */
	return ~InstancePtr->SlaveSelectReg;
}

/*****************************************************************************/
/**
*
* Sets the status callback function, the status handler, which the driver calls
* when it encounters conditions that should be reported to the higher layer
* software. The handler executes in an interrupt context, so it must minimize
* the amount of processing performed such as transferring data to a thread
* context. One of the following status events is passed to the status handler.
* <pre>
*   - XST_SPI_MODE_FAULT	A mode fault error occurred, meaning another
*				master tried to select this device as a slave
*				when this device was configured to be a master.
*				Any transfer in progress is aborted.
*
*   - XST_SPI_TRANSFER_DONE	The requested data transfer is done
*
*   - XST_SPI_TRANSMIT_UNDERRUN	As a slave device, the master clocked
*				data but there were none available in the
*				transmit register/FIFO. This typically means the
*				slave application did not issue a transfer
*				request fast enough, or the processor/driver
*				could not fill the transmit register/FIFO fast
*				enough.
*
*   - XST_SPI_RECEIVE_OVERRUN	The SPI device lost data. Data was received
*				but the receive data register/FIFO was full.
*				This indicates that the device is receiving data
*				faster than the processor/driver can consume it.
*
*   - XST_SPI_SLAVE_MODE_FAULT	A slave SPI device was selected as a slave while
*				it was disabled.  This indicates the master is
*				already transferring data (which is being
*				dropped until the slave application issues a
*				transfer).
* </pre>
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
* @param	CallBackRef is the upper layer callback reference passed back
*		when the callback function is invoked.
* @param	FuncPtr is the pointer to the callback function.
*
* @return	None.
*
* @note
*
* The handler is called within interrupt context, so it should do its work
* quickly and queue potentially time-consuming work to a task-level thread.
*
******************************************************************************/
void XSpi_SetStatusHandler(XSpi *InstancePtr, void *CallBackRef,
			   XSpi_StatusHandler FuncPtr)
{
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(FuncPtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	InstancePtr->StatusHandler = FuncPtr;
	InstancePtr->StatusRef = CallBackRef;
}

/*****************************************************************************/
/**
*
* This is a stub for the status callback. The stub is here in case the upper
* layers forget to set the handler.
*
* @param	CallBackRef is a pointer to the upper layer callback reference
* @param	StatusEvent is the event that just occurred.
* @param	ByteCount is the number of bytes transferred up until the event
*		occurred.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void StubStatusHandler(void *CallBackRef, u32 StatusEvent,
				unsigned int ByteCount)
{
	(void )CallBackRef;
	(void )StatusEvent;
	(void ) ByteCount;
	Xil_AssertVoidAlways();
}

/*****************************************************************************/
/**
*
* The interrupt handler for SPI interrupts. This function must be connected
* by the user to an interrupt source. This function does not save and restore
* the processor context such that the user must provide this processing.
*
* The interrupts that are handled are:
*
* - Mode Fault Error. This interrupt is generated if this device is selected
*   as a slave when it is configured as a master. The driver aborts any data
*   transfer that is in progress by resetting FIFOs (if present) and resetting
*   its buffer pointers. The upper layer software is informed of the error.
*
* - Data Transmit Register (FIFO) Empty. This interrupt is generated when the
*   transmit register or FIFO is empty. The driver uses this interrupt during a
*   transmission to continually send/receive data until there is no more data
*   to send/receive.
*
* - Data Transmit Register (FIFO) Underrun. This interrupt is generated when
*   the SPI device, when configured as a slave, attempts to read an empty
*   DTR/FIFO.  An empty DTR/FIFO usually means that software is not giving the
*   device data in a timely manner. No action is taken by the driver other than
*   to inform the upper layer software of the error.
*
* - Data Receive Register (FIFO) Overrun. This interrupt is generated when the
*   SPI device attempts to write a received byte to an already full DRR/FIFO.
*   A full DRR/FIFO usually means software is not emptying the data in a timely
*   manner.  No action is taken by the driver other than to inform the upper
*   layer software of the error.
*
* - Slave Mode Fault Error. This interrupt is generated if a slave device is
*   selected as a slave while it is disabled. No action is taken by the driver
*   other than to inform the upper layer software of the error.
*
* - Command Error. This interrupt occurs when the first byte in the Tx FIFO,
*   after the CS is asserted, doesn't match any command in the Lookup table.
*   This interrupt is valid only for axi_qspi.
*
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
*
* @return	None.
*
* @note
*
* The slave select register is being set to deselect the slave when a transfer
* is complete.  This is being done regardless of whether it is a slave or a
* master since the hardware does not drive the slave select as a slave.
*
******************************************************************************/
void XSpi_InterruptHandler(void *InstancePtr)
{
	XSpi *SpiPtr = (XSpi *)InstancePtr;
	u32 IntrStatus;
	unsigned int BytesDone;	/* number of bytes done so far */
	u32 Data = 0;
	u32 ControlReg;
	u32 StatusReg;
	u8  DataWidth;

	Xil_AssertVoid(InstancePtr != NULL);

	/*
	 * Update the statistics for the number of interrupts.
	 */
	SpiPtr->Stats.NumInterrupts++;

	/*
	 * Get the Interrupt Status. Immediately clear the interrupts in case
	 * this Isr causes another interrupt to be generated. If we clear at the
	 * end of the Isr, we may miss this newly generated interrupt. This
	 * occurs because we transmit from within the Isr, potentially causing
	 * another TX_EMPTY interrupt.
	 */
	IntrStatus = XSpi_IntrGetStatus(SpiPtr);
	XSpi_IntrClear(SpiPtr, IntrStatus);

	/*
	 * Check for mode fault error. We want to check for this error first,
	 * before checking for progress of a transfer, since this error needs
	 * to abort any operation in progress.
	 */
	if (IntrStatus & XSP_INTR_MODE_FAULT_MASK) {
		BytesDone = SpiPtr->RequestedBytes - SpiPtr->RemainingBytes;
		SpiPtr->Stats.ModeFaults++;

		/*
		 * Abort any operation currently in progress. This includes
		 * clearing the mode fault condition by reading the status
		 * register.
		 * Note that the status register should be read after the Abort
		 * since reading the status register clears the mode fault
		 * condition and would cause the device to restart any transfer
		 * that may be in progress.
		 */
		XSpi_Abort(SpiPtr);

		(void) XSpi_GetStatusReg(SpiPtr);

		SpiPtr->StatusHandler(SpiPtr->StatusRef, XST_SPI_MODE_FAULT,
					BytesDone);

		return;		/* Do not continue servicing other interrupts */
	}

	DataWidth = SpiPtr->DataWidth;
	if ((IntrStatus & XSP_INTR_TX_EMPTY_MASK) ||
	    (IntrStatus & XSP_INTR_TX_HALF_EMPTY_MASK)) {

		/*
		 * A transmit has just completed. Process received data and
		 * check for more data to transmit. Always inhibit the
		 * transmitter while the Isr re-fills the transmit
		 * register/FIFO, or make sure it is stopped if we're done.
		 */
		ControlReg = XSpi_GetControlReg(SpiPtr);
		XSpi_SetControlReg(SpiPtr, ControlReg |
					XSP_CR_TRANS_INHIBIT_MASK);

		/*
		 * First get the data received as a result of the transmit that
		 * just completed.  We get all the data available by reading the
		 * status register to determine when the receive register/FIFO
		 * is empty. Always get the received data, but only fill the
		 * receive buffer if it points to something (the upper layer
		 * software may not care to receive data).
		 */
		StatusReg = XSpi_GetStatusReg(SpiPtr);

		while ((StatusReg & XSP_SR_RX_EMPTY_MASK) == 0) {

			Data = XSpi_ReadReg(SpiPtr->BaseAddr, XSP_DRR_OFFSET);

			/*
			 * Data Transfer Width is Byte (8 bit).
			 */
			if (DataWidth == XSP_DATAWIDTH_BYTE) {
				if (SpiPtr->RecvBufferPtr != NULL) {
					*SpiPtr->RecvBufferPtr++ = (u8) Data;
				}
			} else if (DataWidth == XSP_DATAWIDTH_HALF_WORD) {
				if (SpiPtr->RecvBufferPtr != NULL) {
					*(u16 *) SpiPtr->RecvBufferPtr =
							(u16) Data;
					SpiPtr->RecvBufferPtr +=2;
				}
			} else if (DataWidth == XSP_DATAWIDTH_WORD) {
				if (SpiPtr->RecvBufferPtr != NULL) {
					*(u32 *) SpiPtr->RecvBufferPtr =
							Data;
					SpiPtr->RecvBufferPtr +=4;
				}
			}

			SpiPtr->Stats.BytesTransferred += (DataWidth >> 3);
			StatusReg = XSpi_GetStatusReg(SpiPtr);
		}

		/*
		 * See if there is more data to send.
		 */
		if (SpiPtr->RemainingBytes > 0) {
			/*
			 * Fill the DTR/FIFO with as many bytes as it will take
			 * (or as many as we have to send). We use the full
			 * status bit to know if the device can take more data.
			 * By doing this, the driver does not need to know the
			 * size of the FIFO or that there even is a FIFO.
			 * The downside is that the status must be read each
			 * loop iteration.
			 */
			StatusReg = XSpi_GetStatusReg(SpiPtr);
			while (((StatusReg & XSP_SR_TX_FULL_MASK) == 0) &&
				(SpiPtr->RemainingBytes > 0)) {
				if (DataWidth == XSP_DATAWIDTH_BYTE) {
					/*
					 * Data Transfer Width is Byte (8 bit).
					 */
					Data = *SpiPtr->SendBufferPtr;

				} else if (DataWidth ==
						XSP_DATAWIDTH_HALF_WORD) {
					/*
					 * Data Transfer Width is Half Word
					 * (16 bit).
					 */
					Data = *(u16 *) SpiPtr->SendBufferPtr;
				} else if (DataWidth ==
						XSP_DATAWIDTH_WORD) {
					/*
					 * Data Transfer Width is Word (32 bit).
					 */
					Data = *(u32 *) SpiPtr->SendBufferPtr;
				}

				XSpi_WriteReg(SpiPtr->BaseAddr, XSP_DTR_OFFSET,
						Data);
				SpiPtr->SendBufferPtr += (DataWidth >> 3);
				SpiPtr->RemainingBytes -= (DataWidth >> 3);
				StatusReg = XSpi_GetStatusReg(SpiPtr);
			}

			/*
			 * Start the transfer by not inhibiting the transmitter
			 * any longer.
			 */
			XSpi_SetControlReg(SpiPtr, ControlReg);
		} else {

			/*
			 * Select the slave on the SPI bus when the transfer is
			 * complete, this is necessary for some SPI devices,
			 * such as serial EEPROMs work correctly as chip enable
			 * may be connected to slave select.
			 */
			XSpi_SetSlaveSelectReg(SpiPtr,
						SpiPtr->SlaveSelectMask);
			/*
			 * No more data to send.  Disable the interrupt and
			 * inform the upper layer software that the transfer is
			 * done. The interrupt will be re-enabled when another
			 * transfer is initiated.
			 */
			XSpi_IntrDisable(SpiPtr, XSP_INTR_TX_EMPTY_MASK);

			SpiPtr->IsBusy = FALSE;

			SpiPtr->StatusHandler(SpiPtr->StatusRef,
						XST_SPI_TRANSFER_DONE,
						SpiPtr->RequestedBytes);
		}
	}

	/*
	 * Check if the device has been addressed as a slave. Report the status
	 * to the application layer.
	 */
	if (IntrStatus & XSP_INTR_SLAVE_MODE_MASK) {
		SpiPtr->StatusHandler(SpiPtr->StatusRef,
					XST_SPI_SLAVE_MODE, 0);
	}

	/*
	 * Check if the device has received data from the master. Report the
	 * status to the application layer.
	 */
	if (IntrStatus & XSP_INTR_RX_NOT_EMPTY_MASK) {
		SpiPtr->StatusHandler(SpiPtr->StatusRef,
					XST_SPI_RECEIVE_NOT_EMPTY, 0);
	}

	/*
	 * Check for slave mode fault. Simply report the error and update the
	 * statistics.
	 */
	if (IntrStatus & XSP_INTR_SLAVE_MODE_FAULT_MASK) {
		BytesDone = SpiPtr->RequestedBytes - SpiPtr->RemainingBytes;
		SpiPtr->Stats.SlaveModeFaults++;
		SpiPtr->StatusHandler(SpiPtr->StatusRef,
				XST_SPI_SLAVE_MODE_FAULT, BytesDone);
	}

	/*
	 * Check for overrun error. Simply report the error and update the
	 * statistics.
	 */
	if (IntrStatus & XSP_INTR_RX_OVERRUN_MASK) {
		BytesDone = SpiPtr->RequestedBytes - SpiPtr->RemainingBytes;
		SpiPtr->Stats.RecvOverruns++;
		SpiPtr->StatusHandler(SpiPtr->StatusRef,
				XST_SPI_RECEIVE_OVERRUN, BytesDone);
	}

	/*
	 * Check for underrun error. Simply report the error and update the
	 * statistics.
	 */
	if (IntrStatus & XSP_INTR_TX_UNDERRUN_MASK) {
		BytesDone = SpiPtr->RequestedBytes - SpiPtr->RemainingBytes;
		SpiPtr->Stats.XmitUnderruns++;
		SpiPtr->StatusHandler(SpiPtr->StatusRef,
				XST_SPI_TRANSMIT_UNDERRUN, BytesDone);
	}

	/*
	 * Check for command error. Simply report the error and update the
	 * statistics.
	 */
	if (IntrStatus & XSP_INTR_CMD_ERR_MASK) {
		BytesDone = SpiPtr->RequestedBytes - SpiPtr->RemainingBytes;
		SpiPtr->Stats.XmitUnderruns++;
		SpiPtr->StatusHandler(SpiPtr->StatusRef,
				XST_SPI_COMMAND_ERROR, BytesDone);
	}
}

/*****************************************************************************/
/**
*
* Aborts a transfer in progress by setting the stop bit in the control register,
* then resetting the FIFOs if present. The byte counts are cleared and the
* busy flag is set to false.
*
* @param	InstancePtr is a pointer to the XSpi instance to be worked on.
*
* @return	None.
*
* @note
*
* This function does a read/modify/write of the control register. The user of
* this function needs to take care of critical sections.
*
******************************************************************************/
void XSpi_Abort(XSpi *InstancePtr)
{
	u16 ControlReg;

	/*
	 * Deselect the slave on the SPI bus to abort a transfer, this must be
	 * done before the device is disabled such that the signals which are
	 * driven by the device are changed without the device enabled.
	 */
	XSpi_SetSlaveSelectReg(InstancePtr,
				InstancePtr->SlaveSelectMask);
	/*
	 * Abort the operation currently in progress. Clear the mode
	 * fault condition by reading the status register (done) then
	 * writing the control register.
	 */
	ControlReg = XSpi_GetControlReg(InstancePtr);

	/*
	 * Stop any transmit in progress and reset the FIFOs if they exist,
	 * don't disable the device just inhibit any data from being sent.
	 */
	ControlReg |= XSP_CR_TRANS_INHIBIT_MASK;

	if (InstancePtr->HasFifos) {
		ControlReg |= (XSP_CR_TXFIFO_RESET_MASK |
				XSP_CR_RXFIFO_RESET_MASK);
	}

	XSpi_SetControlReg(InstancePtr, ControlReg);

	InstancePtr->RemainingBytes = 0;
	InstancePtr->RequestedBytes = 0;
	InstancePtr->IsBusy = FALSE;
}

/** @} */
