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
* @file xiic_master.c
* @addtogroup iic_v3_1
* @{
*
* Contains master functions for the XIic component. This file is necessary to
* send or receive as a master on the IIC bus.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- --- ------- -----------------------------------------------
* 1.01b jhl 03/27/02 Reparitioned the driver
* 1.01c ecm 12/05/02 new rev
* 1.13a wgr 03/22/07 Converted to new coding style.
* 2.00a ktn 10/22/09 Converted all register accesses to 32 bit access.
*		     Updated to use the HAL APIs/macros.
*		     Removed the macro XIic_mEnterCriticalRegion,
*		     XIic_IntrGlobalDisable should be used in its place.
*		     Removed the macro XIic_mExitCriticalRegion,
*		     XIic_IntrGlobalEnable should be used in its place.
*		     Some of the macros have been renamed to remove _m from
*		     the name and some of the macros have been renamed to be
*		     consistent, see the xiic_i.h and xiic_l.h files for
*		     further information
* 2.05a bss 02/05/12 Assigned RecvBufferPtr in XIic_MasterSend API and
*		     SendBufferPtr in XIic_MasterRecv NULL
* </pre>
*
****************************************************************************/

/***************************** Include Files *******************************/

#include "xiic.h"
#include "xiic_i.h"

/************************** Constant Definitions ***************************/


/**************************** Type Definitions *****************************/


/***************** Macros (Inline Functions) Definitions *******************/

/*****************************************************************************
*
* This macro includes master code such that master operations, sending
* and receiving data, may be used.  This function hooks the master processing
* to the driver such that events are handled properly and allows master
* processing to be optional.  It must be called before any functions which
* are contained in this file are called, such as after the driver is
* initialized.
*
* @param	None.
*
* @return 	None.
*
* @note		None.
*
******************************************************************************/
#define XIIC_MASTER_INCLUDE						\
{									\
	XIic_RecvMasterFuncPtr = RecvMasterData;			\
	XIic_SendMasterFuncPtr = SendMasterData;			\
}

/************************** Function Prototypes ****************************/

static void SendSlaveAddr(XIic *InstancePtr);
static void RecvMasterData(XIic *InstancePtr);
static void SendMasterData(XIic *InstancePtr);
static int IsBusBusy(XIic *InstancePtr);

/************************** Variable Definitions **************************/

/****************************************************************************/
/**
* This function sends data as a master on the IIC bus. If the bus is busy, it
* will indicate so and then enable an interrupt such that the status handler
* will be called when the bus is no longer busy.  The slave address which has
* been set with the XIic_SetAddress() function is the address to which the
* specific data is sent.  Sending data on the bus performs a write operation.
*
* @param	InstancePtr points to the Iic instance to be worked on.
* @param	TxMsgPtr points to the data to be transmitted.
* @param	ByteCount is the number of message bytes to be sent.
*
* @return
*		- XST_SUCCESS indicates the message transmission has been
*		initiated.
*		- XST_IIC_BUS_BUSY indicates the bus was in use and that
*		the BusNotBusy interrupt is enabled which will update the
*		EventStatus when the bus is no longer busy.
*
* @note		None.
*
******************************************************************************/
int XIic_MasterSend(XIic *InstancePtr, u8 *TxMsgPtr, int ByteCount)
{
	u32 CntlReg;

	XIic_IntrGlobalDisable(InstancePtr->BaseAddress);

	/*
	 * Ensure that the master processing has been included such that events
	 * will be properly handled.
	 */
	XIIC_MASTER_INCLUDE;
	InstancePtr->IsDynamic = FALSE;

	/*
	 * If the busy is busy, then exit the critical region and wait for the
	 * bus to not be busy, the function enables the bus not busy interrupt.
	 */
	if (IsBusBusy(InstancePtr)) {
		XIic_IntrGlobalEnable(InstancePtr->BaseAddress);

		return XST_IIC_BUS_BUSY;
	}

	/*
	 * If it is already a master on the bus (repeated start), the direction
	 * was set to Tx which is throttling bus. The control register needs to
	 * be set before putting data into the FIFO.
	 */
	CntlReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);
	if (CntlReg & XIIC_CR_MSMS_MASK) {
		CntlReg &= ~XIIC_CR_NO_ACK_MASK;
		CntlReg |= (XIIC_CR_DIR_IS_TX_MASK |
				XIIC_CR_REPEATED_START_MASK);

		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,
				CntlReg);
		InstancePtr->Stats.RepeatedStarts++;
	}

	/*
	 * Save message state.
	 */
	InstancePtr->SendByteCount = ByteCount;
	InstancePtr->SendBufferPtr = TxMsgPtr;
	InstancePtr->RecvBufferPtr = NULL;

	/*
	 * Put the address into the FIFO to be sent and indicate that the
	 * operation to be performed on the bus is a write operation,
	 * a general call address is handled the same as a 7 bit address even
	 * if 10 bit address is selected.
	 * Set the transmit address state to indicate the address has been sent.
	 */
	if ((InstancePtr->Options & XII_SEND_10_BIT_OPTION) &&
		(InstancePtr->AddrOfSlave != 0)) {
		XIic_Send10BitAddrByte1(InstancePtr->AddrOfSlave,
					 XIIC_WRITE_OPERATION);
		XIic_Send10BitAddrByte2(InstancePtr->AddrOfSlave);
	} else {
		XIic_Send7BitAddr(InstancePtr->AddrOfSlave,
				   XIIC_WRITE_OPERATION);
	}
	/*
	 * Set the transmit address state to indicate the address has been sent
	 * for communication with event driven processing.
	 */
	InstancePtr->TxAddrMode = XIIC_TX_ADDR_SENT;

	/*
	 * Fill remaining available FIFO with message data.
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
	 * When repeated start not used, MSMS must be set after putting data
	 * into transmit FIFO, start the transmitter.
	 */
	CntlReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);
	if ((CntlReg & XIIC_CR_MSMS_MASK) == 0) {
		CntlReg &= ~XIIC_CR_NO_ACK_MASK;
		CntlReg |= XIIC_CR_MSMS_MASK | XIIC_CR_DIR_IS_TX_MASK;
		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,
			 CntlReg);
	}

	XIic_IntrGlobalEnable(InstancePtr->BaseAddress);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
* This function receives data as a master from a slave device on the IIC bus.
* If the bus is busy, it will indicate so and then enable an interrupt such
* that the status handler will be called when the bus is no longer busy.  The
* slave address which has been set with the XIic_SetAddress() function is the
* address from which data is received. Receiving data on the bus performs a
* read operation.
*
* @param	InstancePtr is a pointer to the Iic instance to be worked on.
* @param	RxMsgPtr is a pointer to the data to be transmitted
* @param	ByteCount is the number of message bytes to be sent
*
* @return
*		- XST_SUCCESS indicates the message reception processes has
*		been initiated.
*		- XST_IIC_BUS_BUSY indicates the bus was in use and that the
*		BusNotBusy interrupt is enabled which will update the
*		EventStatus when the bus is no longer busy.
*		- XST_IIC_GENERAL_CALL_ADDRESS indicates the slave address
*		is set to the the general call address. This is not allowed
*		for Master receive mode.
*
* @internal
*
* The receive FIFO threshold is a zero based count such that 1 must be
* subtracted from the desired count to get the correct value. When receiving
* data it is also necessary to not receive the last byte with the prior bytes
* because the acknowledge must be setup before the last byte is received.
*
******************************************************************************/
int XIic_MasterRecv(XIic *InstancePtr, u8 *RxMsgPtr, int ByteCount)
{
	u32 CntlReg;
	u8 Temp;

	/*
	 * If the slave address is zero (general call) the master can't perform
	 * receive operations, indicate an error.
	 */
	if (InstancePtr->AddrOfSlave == 0) {
		return XST_IIC_GENERAL_CALL_ADDRESS;
	}

	XIic_IntrGlobalDisable(InstancePtr->BaseAddress);

	/*
	 * Ensure that the master processing has been included such that events
	 * will be properly handled.
	 */
	XIIC_MASTER_INCLUDE;
	InstancePtr->IsDynamic = FALSE;

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
	InstancePtr->SendBufferPtr = NULL;

	/*
	 * Clear and enable Rx full interrupt if using 7 bit, If 10 bit, wait
	 * until last address byte sent incase arbitration gets lost while
	 * sending out address.
	 */
	if ((InstancePtr->Options & XII_SEND_10_BIT_OPTION) == 0) {
		XIic_ClearEnableIntr(InstancePtr->BaseAddress,
					XIIC_INTR_RX_FULL_MASK);
	}

	/*
	 * If already a master on the bus, the direction was set by Rx Interrupt
	 * routine to Tx which is throttling bus because during Rxing, Tx reg is
	 * empty = throttle. CR needs setting before putting data or the address
	 * written will go out as Tx instead of receive. Start Master Rx by
	 * setting CR Bits MSMS to Master and msg direction.
	 */
	CntlReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);

	if (CntlReg & XIIC_CR_MSMS_MASK) {
		CntlReg |= XIIC_CR_REPEATED_START_MASK;
		XIic_SetControlRegister(InstancePtr, CntlReg, ByteCount);

		InstancePtr->Stats.RepeatedStarts++;
		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,
			 CntlReg);

	}

	/*
	 * Set receive FIFO occupancy depth which must be done prior to writing
	 * the address in the FIFO because the transmitter will immediatedly
	 * start when in repeated start mode followed by the receiver such that
	 * the number of  bytes to receive should be set 1st.
	 */
	if (ByteCount == 1) {
		Temp = 0;
	} else {
		if (ByteCount <= IIC_RX_FIFO_DEPTH) {
			Temp = ByteCount - 2;
		} else {
			Temp = IIC_RX_FIFO_DEPTH - 1;
		}
	}
	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_RFD_REG_OFFSET,
			(u32) Temp);

	if (InstancePtr->Options & XII_SEND_10_BIT_OPTION) {
		/*
		 * Send the 1st and 2nd byte of the 10 bit address of a write
		 * operation, write because it's a 10 bit address.
		 */
		XIic_Send10BitAddrByte1(InstancePtr->AddrOfSlave,
					 XIIC_WRITE_OPERATION);
		XIic_Send10BitAddrByte2(InstancePtr->AddrOfSlave);

		/*
		 * Set flag to indicate the next byte of the address needs to be
		 * send, clear and enable Tx empty interrupt.
		 */
		InstancePtr->TxAddrMode = XIIC_TX_ADDR_MSTR_RECV_MASK;
		XIic_ClearEnableIntr(InstancePtr->BaseAddress,
					XIIC_INTR_TX_EMPTY_MASK);
	} else {
		/*
		 * 7 bit slave address, send the address for a read operation
		 * and set the state to indicate the address has been sent.
		 */
		XIic_Send7BitAddr(InstancePtr->AddrOfSlave,
				   XIIC_READ_OPERATION);
		InstancePtr->TxAddrMode = XIIC_TX_ADDR_SENT;
	}

	/*
	 * Tx error is enabled incase the address (7 or 10) has no device to
	 * answer with Ack. When only one byte of data, must set NO ACK before
	 * address goes out therefore Tx error must not be enabled as it will
	 * go off immediately and the Rx full interrupt will be checked.
	 * If full, then the one byte was received and the Tx error will be
	 * disabled without sending an error callback msg.
	 */
	XIic_ClearEnableIntr(InstancePtr->BaseAddress,
				XIIC_INTR_TX_ERROR_MASK);

	/*
	 * When repeated start not used, MSMS gets set after putting data
	 * in Tx reg. Start Master Rx by setting CR Bits MSMS to Master and
	 * msg direction.
	 */
	CntlReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);
	if ((CntlReg & XIIC_CR_MSMS_MASK) == 0) {
		CntlReg |= XIIC_CR_MSMS_MASK;
		XIic_SetControlRegister(InstancePtr, CntlReg, ByteCount);
		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,
				CntlReg);
	}

	XIic_IntrGlobalEnable(InstancePtr->BaseAddress);

	return XST_SUCCESS;
}

/*****************************************************************************
*
* This function checks to see if the IIC bus is busy.  If so, it will enable
* the bus not busy interrupt such that the driver is notified when the bus
* is no longer busy.
*
* @param	InstancePtr points to the Iic instance to be worked on.
*
* @return
*		- FALSE indicates the IIC bus is not busy.
*		- TRUE indicates the bus was in use and that the BusNotBusy
*		interrupt is enabled which will update the EventStatus when
*		the bus is no longer busy.
*
* @note		None.
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
	 * repeated start and the bus is busy setup to wait for it to not be
	 * busy.
	 */
	if (((CntlReg & XIIC_CR_MSMS_MASK) == 0) &&	/* Not master */
		(StatusReg & XIIC_SR_BUS_BUSY_MASK)) {	/* Is busy */
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
* This function sends the proper byte of the address as well as generate the
* proper address bit fields depending on the address byte required and the
* direction of the data (write or read).
*
* A master receiving has the restriction that the direction must be switched
* from write to read when the third address byte is transmitted.
* For the last byte of the 10 bit address, repeated start must be set prior
* to writing the address. If repeated start options is enabled, the
* control register is written before the address is written to the Tx reg.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return	None.
*
* @note
*
* This function does read/modify/write to the device control register. Calling
* functions must ensure critical sections are used.
*
******************************************************************************/
static void SendSlaveAddr(XIic *InstancePtr)
{
	u32 CRreg;

	/*
	 * Set the control register for Master Receive, repeated start must be
	 * set before writing the address, MSMS should be already set, don't
	 * set here so if arbitration is lost or some other reason we don't
	 * want MSMS set incase of error.
	 */
	CRreg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);

	CRreg |= XIIC_CR_REPEATED_START_MASK;
	CRreg &= ~XIIC_CR_DIR_IS_TX_MASK;

	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET, CRreg);

	/*
	 * Send the 1st byte of the 10 bit address as a read operation, enable
	 * the receive interrupt to know when data is received, assuming that
	 * the receive FIFO threshold has been previously set.
	 */
	XIic_Send10BitAddrByte1(InstancePtr->AddrOfSlave, XIIC_READ_OPERATION);

	XIic_ClearEnableIntr(InstancePtr->BaseAddress, XIIC_INTR_RX_FULL_MASK);
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
static void SendMasterData(XIic *InstancePtr)
{
	u32 CntlReg;

	/*
	 * The device is a master on the bus.  If there is still more address
	 * bytes to send when in master receive operation and the slave device
	 * is 10 bit addressed.
	 * This requires the lower 7 bits of address to be resent when the mode
	 * switches to Read instead of write (while sending addresses).
	 */
	if (InstancePtr->TxAddrMode & XIIC_TX_ADDR_MSTR_RECV_MASK) {
		/*
		 * Send the 1st byte of the slave address in the read operation
		 * and change the state to indicate this has been done
		 */
		SendSlaveAddr(InstancePtr);
		InstancePtr->TxAddrMode = XIIC_TX_ADDR_SENT;
	}

	/*
	 * In between 1st and last byte of message, fill the FIFO with more data
	 * to send, disable the 1/2 empty interrupt based upon data left to
	 * send.
	 */
	else if (InstancePtr->SendByteCount > 1) {
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
		}

		/*
		 * When not using repeated start, the stop condition must be
		 * generated after the last byte is written. The bus is
		 * throttled waiting for the last byte.
		 */
		else {
			/*
			 * Set the stop condition before sending the last byte
			 * of data so that the stop condition will be generated
			 * immediately following the data another transmit
			 * interrupt is not expected so the message is done.
			 */
			CntlReg = XIic_ReadReg(InstancePtr->BaseAddress,
					XIIC_CR_REG_OFFSET);
			CntlReg &= ~XIIC_CR_MSMS_MASK;
			XIic_WriteReg(InstancePtr->BaseAddress,
					XIIC_CR_REG_OFFSET,
					CntlReg);

			XIic_WriteSendByte(InstancePtr);

			/*
			 * Wait for bus to not be busy before declaring message
			 * has been sent for the no repeated start operation.
			 * The callback will be called from the BusNotBusy part
			 * of the Interrupt handler to ensure that the message
			 * is completely sent.
			 * Disable the Tx interrupts and enable the BNB
			 * interrupt.
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
static void RecvMasterData(XIic *InstancePtr)
{
	u8 LoopCnt;
	int BytesInFifo;
	int BytesToRead;
	u32 CntlReg;

	/*
	 * Device is a master receiving, get the contents of the control
	 * register and determine the number of bytes in fifo to be read out.
	 */
	CntlReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);
	BytesInFifo = XIic_ReadReg(InstancePtr->BaseAddress,
				XIIC_RFO_REG_OFFSET) + 1;

	/*
	 * If data in FIFO holds all data to be retrieved - 1, set NOACK and
	 * disable the Tx error.
	 */
	if ((InstancePtr->RecvByteCount - BytesInFifo) == 1) {
		/*
		 * Disable Tx error interrupt to prevent interrupt
		 * as this device will cause it when it set NO ACK next.
		 */
		XIic_DisableIntr(InstancePtr->BaseAddress,
				  XIIC_INTR_TX_ERROR_MASK);
		XIic_ClearIntr(InstancePtr->BaseAddress,
				XIIC_INTR_TX_ERROR_MASK);

		/*
		 * Write control reg with NO ACK allowing last byte to
		 * have the No ack set to indicate to slave last byte read.
		 */
		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,
			 (CntlReg | XIIC_CR_NO_ACK_MASK));

		/*
		 * Read one byte to clear a place for the last byte to be read
		 * which will set the NO ACK.
		 */
		XIic_ReadRecvByte(InstancePtr);
	}

	/*
	 * If data in FIFO is all the data to be received then get the data
	 * and also leave the device in a good state for the next transaction.
	 */
	else if ((InstancePtr->RecvByteCount - BytesInFifo) == 0) {
		/*
		 * If repeated start option is off then the master should stop
		 * using the bus, otherwise hold the bus, setting repeated start
		 * stops the slave from transmitting data when the FIFO is read.
		 */
		if ((InstancePtr->Options & XII_REPEATED_START_OPTION) == 0) {
			CntlReg &= ~XIIC_CR_MSMS_MASK;
		} else {
			CntlReg |= XIIC_CR_REPEATED_START_MASK;
		}
		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,
			 CntlReg);

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

		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,
			 (CntlReg & ~XIIC_CR_NO_ACK_MASK));

		/*
		 * Send notification of msg Rx complete in RecvHandler callback.
		 */
		InstancePtr->RecvHandler(InstancePtr->RecvCallBackRef, 0);
	} else {
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
/** @} */
