/******************************************************************************
*
* Copyright (C) 2006 - 2015 Xilinx, Inc.  All rights reserved.
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
* @file xiic_dyn_master.c
* @addtogroup iic_v3_1
* @{
*
* Contains master functions for the XIic component in Dynamic controller mode.
* This file is necessary to send or receive as a master on the IIC bus.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- --- ------- -----------------------------------------------------------
* 1.03a mta 04/10/06 Created.
* 1.13a wgr 03/22/07 Converted to new coding style.
* 2.00a ktn 10/22/09 Converted all register accesses to 32 bit access.
*		     Updated to use the HAL APIs/macros. The macros
*		     XIic_mDynSend7BitAddress and XIic_mDynSendStop have
*		     been removed from this file as they were already
*		     defined in a header file.
*		     Some of the macros have been renamed to remove _m from
*		     the name and Some of the macros have been renamed to be
*		     consistent, see the xiic_l.h file for further information.
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xiic.h"
#include "xiic_i.h"

/************************** Constant Definitions *****************************/

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/******************************************************************************
*
* This macro includes dynamic master code such that dynamic master operations,
* sending and receiving data, may be used. This function hooks the dynamic
* master processing to the driver such that events are handled properly and
* allows dynamic master processing to be optional. It must be called before any
* functions which are contained in this file are called, such as after the
* driver is initialized.
*
* @param	None.
*
* @return	None.
*
* @note 	None.
*
******************************************************************************/
#define XIIC_DYN_MASTER_INCLUDE						\
{									\
	XIic_RecvMasterFuncPtr = DynRecvMasterData;			\
	XIic_SendMasterFuncPtr = DynSendMasterData;			\
}

/************************** Function Prototypes ******************************/

static void DynRecvMasterData(XIic *InstancePtr);
static void DynSendMasterData(XIic *InstancePtr);
static int IsBusBusy(XIic *InstancePtr);

/************************** Variable Definitions *****************************/

/*****************************************************************************/
/**
* This function sends data as a Dynamic master on the IIC bus. If the bus is
* busy, it will indicate so and then enable an interrupt such that the status
* handler will be called when the bus is no longer busy. The slave address is
* sent by using XIic_DynSend7BitAddress().
*
* @param	InstancePtr points to the Iic instance to be worked on.
* @param	TxMsgPtr points to the data to be transmitted.
* @param	ByteCount is the number of message bytes to be sent.
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		None.
*
******************************************************************************/
int XIic_DynMasterSend(XIic *InstancePtr, u8 *TxMsgPtr, u8 ByteCount)
{
	u32 CntlReg;

	XIic_IntrGlobalDisable(InstancePtr->BaseAddress);

	/*
	 * Ensure that the Dynamic master processing has been included such that
	 * events will be properly handled.
	 */
	XIIC_DYN_MASTER_INCLUDE;
	InstancePtr->IsDynamic = TRUE;

	/*
	 * If the busy is busy, then exit the critical region and wait for the
	 * bus not to be busy. The function enables the BusNotBusy interrupt.
	 */
	if (IsBusBusy(InstancePtr)) {
		XIic_IntrGlobalEnable(InstancePtr->BaseAddress);

		return XST_FAILURE;
	}

	/*
	 * If it is already a master on the bus (repeated start), the direction
	 * was set to Tx which is throttling bus. The control register needs to
	 * be set before putting data into the FIFO.
	 */
	CntlReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);
	if (CntlReg & XIIC_CR_MSMS_MASK) {
		CntlReg &= ~XIIC_CR_NO_ACK_MASK;
		CntlReg |= XIIC_CR_DIR_IS_TX_MASK;
		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,
				CntlReg);
		InstancePtr->Stats.RepeatedStarts++;
	}

	/*
	 * Save message state.
	 */
	InstancePtr->SendByteCount = ByteCount;
	InstancePtr->SendBufferPtr = TxMsgPtr;

	/*
	 * Send the Seven Bit address. Only 7 bit addressing is supported in
	 * Dynamic mode.
	 */
	XIic_DynSend7BitAddress(InstancePtr->BaseAddress,
				 InstancePtr->AddrOfSlave,
				 XIIC_WRITE_OPERATION);

	/*
	 * Set the transmit address state to indicate the address has been sent
	 * for communication with event driven processing.
	 */
	InstancePtr->TxAddrMode = XIIC_TX_ADDR_SENT;

	/*
	 * Fill the Tx FIFO.
	 */
	if (InstancePtr->SendByteCount > 1) {
		XIic_TransmitFifoFill(InstancePtr, XIIC_MASTER_ROLE);
	}

	/*
	 * After filling fifo, if data yet to send > 1, enable Tx � empty
	 * interrupt.
	 */
	if (InstancePtr->SendByteCount > 1) {
		XIic_ClearEnableIntr(InstancePtr->BaseAddress,
					XIIC_INTR_TX_HALF_MASK);
	}

	/*
	 * Clear any pending Tx empty, Tx Error and then enable them.
	 */
	XIic_ClearEnableIntr(InstancePtr->BaseAddress,
				XIIC_INTR_TX_ERROR_MASK |
				XIIC_INTR_TX_EMPTY_MASK);

	/*
	 * Enable the Interrupts.
	 */
	XIic_IntrGlobalEnable(InstancePtr->BaseAddress);

	return XST_SUCCESS;
}

/******************************************************************************
*
* When the IIC Tx FIFO/register goes empty, this routine is called by the
* interrupt service routine to fill the transmit FIFO with data to be sent.
*
* This function also is called by the Tx � empty interrupt as the data handling
* is identical when you don't assume the FIFO is empty but use the Tx_FIFO_OCY
* register to indicate the available free FIFO bytes.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void DynSendMasterData(XIic *InstancePtr)
{
	u32 CntlReg;

	/*
	 * In between 1st and last byte of message, fill the FIFO with more data
	 * to send, disable the 1/2 empty interrupt based upon data left to
	 * send.
	 */
	if (InstancePtr->SendByteCount > 1) {
		XIic_TransmitFifoFill(InstancePtr, XIIC_MASTER_ROLE);

		if (InstancePtr->SendByteCount < 2) {
			XIic_DisableIntr(InstancePtr->BaseAddress,
					  XIIC_INTR_TX_HALF_MASK);
		}
	}

	/*
	 * If there is only one byte left to send, processing differs between
	 * repeated start and normal messages.
	 */
	else if (InstancePtr->SendByteCount == 1) {
		/*
		 * When using repeated start, another interrupt is expected
		 * after the last byte has been sent, so the message is not
		 * done yet.
		 */
		if (InstancePtr->Options & XII_REPEATED_START_OPTION) {
			XIic_WriteSendByte(InstancePtr);
		} else {
			XIic_DynSendStop(InstancePtr->BaseAddress,
					  *InstancePtr->SendBufferPtr);

			/*
			 * Wait for bus to not be busy before declaring message
			 * has been sent for the no repeated start operation.
			 * The callback will be called from the BusNotBusy part
			 * of the Interrupt handler to ensure that the message
			 * is completely sent. Disable the Tx interrupts and
			 * enable the BNB interrupt.
			 */
			InstancePtr->BNBOnly = FALSE;
			XIic_DisableIntr(InstancePtr->BaseAddress,
					  XIIC_TX_INTERRUPTS);
			XIic_EnableIntr(InstancePtr->BaseAddress,
					 XIIC_INTR_BNB_MASK);
		}
	} else {
		if (InstancePtr->Options & XII_REPEATED_START_OPTION) {
			/*
			 * The message being sent has completed. When using
			 * repeated start with no more bytes to send repeated
			 * start needs to be set in the control register so
			 * that the bus will still be held by this master.
			 */
			CntlReg = XIic_ReadReg(InstancePtr->BaseAddress,
					XIIC_CR_REG_OFFSET);
			CntlReg |= XIIC_CR_REPEATED_START_MASK;
			XIic_WriteReg(InstancePtr->BaseAddress,
					XIIC_CR_REG_OFFSET, CntlReg);

			/*
			 * If the message that was being sent has finished,
			 * disable all transmit interrupts and call the callback
			 * that was setup to indicate the message was sent,
			 * with 0 bytes remaining.
			 */
			XIic_DisableIntr(InstancePtr->BaseAddress,
					  XIIC_TX_INTERRUPTS);
			InstancePtr->SendHandler(InstancePtr->SendCallBackRef,
						 0);
		}
	}

	return;
}

/*****************************************************************************/
/**
* This function receives data as a master from a slave device on the IIC bus.
* If the bus is busy, it will indicate so and then enable an interrupt such
* that the status handler will be called when the bus is no longer busy. The
* slave address which has been set with the XIic_SetAddress() function is the
* address from which data is received. Receiving data on the bus performs a
* read operation.
*
* @param	InstancePtr is a pointer to the Iic instance to be worked on.
* @param	RxMsgPtr is a pointer to the data to be transmitted.
* @param	ByteCount is the number of message bytes to be sent.
*
* @return	- XST_SUCCESS indicates the message reception processes has been
* 		initiated.
*		- XST_IIC_BUS_BUSY indicates the bus was in use and that the
*		BusNotBusy interrupt is enabled which will update the
*		EventStatus when the bus is no longer busy.
*		- XST_IIC_GENERAL_CALL_ADDRESS indicates the slave address is
*		set to the general call address. This is not allowed for Master
*		receive mode.
*
* @note		The receive FIFO threshold is a zero based count such that 1
*		must be subtracted from the desired count to get the correct
*		value. When receiving data it is also necessary to not receive
*		the last byte with the prior bytes because the acknowledge must
*		be setup before the last byte is received.
*
******************************************************************************/
int XIic_DynMasterRecv(XIic *InstancePtr, u8 *RxMsgPtr, u8 ByteCount)
{
	u32 CntlReg;
	u32 RxFifoOccy;

	/*
	 * If the slave address is zero (general call) the master can't perform
	 * receive operations, indicate an error.
	 */
	if (InstancePtr->AddrOfSlave == 0) {
		return XST_IIC_GENERAL_CALL_ADDRESS;
	}

	/*
	 * Disable the Interrupts.
	 */
	XIic_IntrGlobalDisable(InstancePtr->BaseAddress);

	/*
	 * Ensure that the master processing has been included such that events
	 * will be properly handled.
	 */
	XIIC_DYN_MASTER_INCLUDE;
	InstancePtr->IsDynamic = TRUE;

	/*
	 * If the busy is busy, then exit the critical region and wait for the
	 * bus to not be busy, the function enables the bus not busy interrupt.
	 */
	if (IsBusBusy(InstancePtr)) {
		XIic_IntrGlobalEnable(InstancePtr->BaseAddress);

		return XST_IIC_BUS_BUSY;
	}

	/*
	 * Save message state for event driven processing.
	 */
	InstancePtr->RecvByteCount = ByteCount;
	InstancePtr->RecvBufferPtr = RxMsgPtr;

	/*
	 * Clear and enable Rx full interrupt.
	 */
	XIic_ClearEnableIntr(InstancePtr->BaseAddress, XIIC_INTR_RX_FULL_MASK);

	/*
	 * If already a master on the bus, the direction was set by Rx Interrupt
	 * routine to Tx which is throttling bus because during Rxing, Tx reg is
	 * empty = throttle. CR needs setting before putting data or the address
	 * written will go out as Tx instead of receive. Start Master Rx by
	 * setting CR Bits MSMS to Master and msg direction.
	 */
	CntlReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);
	if (CntlReg & XIIC_CR_MSMS_MASK) {
		/*
		 * Set the Repeated Start bit in CR.
		 */
		CntlReg |= XIIC_CR_REPEATED_START_MASK;
		XIic_SetControlRegister(InstancePtr, CntlReg, ByteCount);

		/*
		 * Increment stats counts.
		 */
		InstancePtr->Stats.RepeatedStarts++;
		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,
				CntlReg);
	}

	/*
	 * Set receive FIFO occupancy depth which must be done prior to writing
	 * the address in the FIFO because the transmitter will immediately
	 * start when in repeated start mode followed by the receiver such
	 * that the number of bytes to receive should be set 1st.
	 */
	if (ByteCount == 1) {
		RxFifoOccy = 0;
	}
	else {
		if (ByteCount <= IIC_RX_FIFO_DEPTH) {
			RxFifoOccy = ByteCount - 2;
		} else {
			RxFifoOccy = IIC_RX_FIFO_DEPTH - 1;
		}
	}

	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_RFD_REG_OFFSET,
			RxFifoOccy);

	/*
	 * Send the Seven Bit address. Only 7 bit addressing is supported in
	 * Dynamic mode and mark that the address has been sent.
	 */
	XIic_DynSend7BitAddress(InstancePtr->BaseAddress,
				 InstancePtr->AddrOfSlave, XIIC_READ_OPERATION);
	InstancePtr->TxAddrMode = XIIC_TX_ADDR_SENT;

	/*
	 * Send the bytecount to be received and set the stop bit.
	 */
	XIic_DynSendStop(InstancePtr->BaseAddress, ByteCount);

	/*
	 * Tx error is enabled incase the address has no device to answer
	 * with Ack. When only one byte of data, must set NO ACK before address
	 * goes out therefore Tx error must not be enabled as it will go off
	 * immediately and the Rx full interrupt will be checked. If full, then
	 * the one byte was received and the Tx error will be disabled without
	 * sending an error callback msg.
	 */
	XIic_ClearEnableIntr(InstancePtr->BaseAddress,
				XIIC_INTR_TX_ERROR_MASK);

	/*
	 * Enable the Interrupts.
	 */
	XIic_IntrGlobalEnable(InstancePtr->BaseAddress);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function is called when the receive register is full. The number
* of bytes received to cause the interrupt is adjustable using the Receive FIFO
* Depth register. The number of bytes in the register is read in the Receive
* FIFO occupancy register. Both these registers are zero based values (0-15)
* such that a value of zero indicates 1 byte.
*
* For a Master Receiver to properly signal the end of a message, the data must
* be read in up to the message length - 1, where control register bits will be
* set for bus controls to occur on reading of the last byte.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void DynRecvMasterData(XIic *InstancePtr)
{
	u8 LoopCnt;
	u8 BytesInFifo;
	u8 BytesToRead;
	u32 CntlReg;

	/*
	 * Device is a master receiving, get the contents of the control
	 * register and determine the number of bytes in fifo to be read out.
	 */
	CntlReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);
	BytesInFifo = (u8) XIic_ReadReg(InstancePtr->BaseAddress,
					 XIIC_RFO_REG_OFFSET) + 1;

	/*
	 * If data in FIFO holds all data to be retrieved - 1, set NOACK and
	 * disable the Tx error.
	 */
	if ((InstancePtr->RecvByteCount - BytesInFifo) == 1) {
		/*
		 * Disable Tx error interrupt to prevent interrupt as this
		 * device will cause it when it set NO ACK next.
		 */
		XIic_DisableIntr(InstancePtr->BaseAddress,
				  XIIC_INTR_TX_ERROR_MASK);
		XIic_ClearIntr(InstancePtr->BaseAddress,
				XIIC_INTR_TX_ERROR_MASK);

		/*
		 * Read one byte to clear a place for the last byte to be read
		 * which will set the NO ACK.
		 */
		XIic_ReadRecvByte(InstancePtr);
	}

	/*
	 * If data in FIFO is all the data to be received then get the data and
	 * also leave the device in a good state for the next transaction.
	 */
	else if ((InstancePtr->RecvByteCount - BytesInFifo) == 0) {
		if (InstancePtr->Options & XII_REPEATED_START_OPTION) {
			CntlReg |= XIIC_CR_REPEATED_START_MASK;
			XIic_WriteReg(InstancePtr->BaseAddress,
					XIIC_CR_REG_OFFSET,
					CntlReg);
		}

		/*
		 * Read data from the FIFO then set zero based FIFO read depth
		 * for a byte.
		 */
		for (LoopCnt = 0; LoopCnt < BytesInFifo; LoopCnt++) {
			XIic_ReadRecvByte(InstancePtr);
		}

		XIic_WriteReg(InstancePtr->BaseAddress,
				XIIC_RFD_REG_OFFSET, 0);

		/*
		 * Disable Rx full interrupt and write the control reg with ACK
		 * allowing next byte sent to be acknowledged automatically.
		 */
		XIic_DisableIntr(InstancePtr->BaseAddress,
				  XIIC_INTR_RX_FULL_MASK);

		/*
		 * Send notification of msg Rx complete in RecvHandler callback.
		 */
		InstancePtr->RecvHandler(InstancePtr->RecvCallBackRef, 0);
	}
	else {
		/*
		 * Fifo data not at n-1, read all but the last byte of data
		 * from the slave, if more than a FIFO full yet to receive
		 * read a FIFO full.
		 */
		BytesToRead = InstancePtr->RecvByteCount - BytesInFifo - 1;
		if (BytesToRead > IIC_RX_FIFO_DEPTH) {
			BytesToRead = IIC_RX_FIFO_DEPTH;
		}

		/*
		 * Read in data from the FIFO.
		 */
		for (LoopCnt = 0; LoopCnt < BytesToRead; LoopCnt++) {
			XIic_ReadRecvByte(InstancePtr);
		}
	}
}

/******************************************************************************
*
* This function checks to see if the IIC bus is busy. If so, it will enable
* the bus not busy interrupt such that the driver is notified when the bus
* is no longer busy.
*
* @param	InstancePtr points to the Iic instance to be worked on.
*
* @return 	FALSE if the IIC bus is not busy else TRUE.
*
* @note		The BusNotBusy interrupt is enabled which will update the
*		EventStatus when the bus is no longer busy.
*
******************************************************************************/
static int IsBusBusy(XIic *InstancePtr)
{
	u32 CntlReg;
	u32 StatusReg;

	CntlReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);
	StatusReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_SR_REG_OFFSET);

	/*
	 * If this device is already master of the bus as when using the
	 * repeated start and the bus is busy setup to wait for it to not
	 * be busy.
	 */
	if (((CntlReg & XIIC_CR_MSMS_MASK) == 0) &&	/* Not master */
		(StatusReg & XIIC_SR_BUS_BUSY_MASK)) {	/* Is busy    */
		/*
		 * The bus is busy, clear pending BNB interrupt incase
		 * previously set and then enable BusNotBusy interrupt.
		 */
		InstancePtr->BNBOnly = TRUE;
		XIic_ClearEnableIntr(InstancePtr->BaseAddress,
					XIIC_INTR_BNB_MASK);
		InstancePtr->Stats.BusBusy++;

		return TRUE;
	}

	return FALSE;
}

/******************************************************************************
*
* Initialize the IIC core for Dynamic Functionality.
*
* @param	InstancePtr points to the Iic instance to be worked on.
*
* @return	XST_SUCCESS if Successful else XST_FAILURE.
*
* @note		None.
*
******************************************************************************/
int XIic_DynamicInitialize(XIic *InstancePtr)
{
	int Status;

	Xil_AssertNonvoid(InstancePtr != NULL);

	Status = XIic_DynInit(InstancePtr->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}
/** @} */
