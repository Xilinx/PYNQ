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
* @file xiic_slave.c
* @addtogroup iic_v3_1
* @{
*
* Contains slave functions for the XIic component. This file is necessary when
* slave operations, sending and receiving data as a slave on the IIC bus,
* are desired.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- --- ------- -----------------------------------------------
* 1.01b jhl 3/26/02 repartioned the driver
* 1.01c ecm 12/05/02 new rev
* 1.13a wgr 03/22/07 Converted to new coding style.
* 1.15a ktn 03/18/09 Minor changes to comply to Doxygen
* 2.00a ktn 10/22/09 Converted all register accesses to 32 bit access.
*		     Updated to use the HAL APIs/macros.
*		     Removed the macro XIic_mEnterCriticalRegion and used
*		     XIic_IntrGlobalDisable int its place.
*		     Removed the macro XIic_mExitCriticalRegion and used
*		     XIic_IntrGlobalEnable in its place.
*		     Some of the macros have been renamed to remove _m from
*		     the name and some of the macros have been renamed to be
*		     consistent, see the xiic_i.h and xiic_l.h files for further
*		     information
* 2.03a rkv 01/25/11 Updated in NAAS interrupt handler to support data
*		     recieved less than FIFO size prior to NAAS interrupt.
*		     Fixed for CR590212.
* 2.04a sdm  07/22/11 Added IsSlaveSetAckOff flag to the instance structure.
*		      The IsSlaveSetAckOff is set when the Slave has set the
*		      Ack Off in the RecvSlaveData function and is cleared in the
*		      NotAddrAsSlaveHandler when the master has released the
*		      bus. This flag is to be used by slave applications for
*		      recovering when it has gone out of sync with the master.
*		      CR 615004.
* 3.1   adk  01/08/15 When configured as a slave return the actual number of
*		      bytes have been received/sent by the Master
*		      to the user callback (CR: 828504).
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

static void AddrAsSlaveHandler(XIic *InstancePtr);
static void NotAddrAsSlaveHandler(XIic *InstancePtr);
static void RecvSlaveData(XIic *InstancePtr);
static void SendSlaveData(XIic *InstancePtr);

/************************** Variable Definitions **************************/

/*****************************************************************************/
/**
*
* This function includes slave code such that slave events will be processsed.
* It is necessary to allow slave code to be optional to reduce the size of
* the driver. This function may be called at any time but must be prior to
* being selected as a slave on the IIC bus. This function may be called prior
* to the Cfg_Initialize() function and must be called before any functions in
* this file are called.
*
* @param	None.
*
* @return 	None.
*
* @note		None.
*
******************************************************************************/
void XIic_SlaveInclude()
{
	XIic_AddrAsSlaveFuncPtr = AddrAsSlaveHandler;
	XIic_NotAddrAsSlaveFuncPtr = NotAddrAsSlaveHandler;
	XIic_RecvSlaveFuncPtr = RecvSlaveData;
	XIic_SendSlaveFuncPtr = SendSlaveData;
}

/*****************************************************************************/
/**
*
* This function sends data as a slave on the IIC bus and should not be called
* until an event has occurred that indicates the device has been selected by
* a master attempting read from the slave (XII_MASTER_READ_EVENT).
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
* @param	TxMsgPtr is a pointer to the data to be transmitted.
* @param	ByteCount is the number of message bytes to be sent.
*
* @return
*		- XST_SUCCESS indicates the message transmission has been
*		initiated.
*		- XST_IIC_NOT_SLAVE indicates the device has not been
*		selected to be a slave on the IIC bus such that data
*		cannot be sent.
*
* @note		None.
*
******************************************************************************/
int XIic_SlaveSend(XIic *InstancePtr, u8 *TxMsgPtr, int ByteCount)
{
	u32 IntrStatus;
	u32 Status;

	/*
	 * If the device is not a slave on the IIC bus then indicate an error
	 * because data cannot be sent on the bus.
	 */
	Status = XIic_ReadReg(InstancePtr->BaseAddress,  XIIC_SR_REG_OFFSET);
	if ((Status & XIIC_SR_ADDR_AS_SLAVE_MASK) == 0) {
		return XST_IIC_NOT_SLAVE;
	}

	XIic_IntrGlobalDisable(InstancePtr->BaseAddress);

	/*
	 * Save message state and invalidate the receive buffer pointer to
	 * indicate the direction of transfer is sending.
	 */
	InstancePtr->SendByteCount = ByteCount;
	InstancePtr->SendBufferPtr = TxMsgPtr;
	InstancePtr->RecvBufferPtr = NULL;

	/*
	 * Start sending the specified data and then interrupt processing will
	 * complete it.
	 */
	XIic_TransmitFifoFill(InstancePtr, XIIC_SLAVE_ROLE);

	/* Clear any pending Tx empty, Tx Error and interrupt then enable them.
	 * The Tx error interrupt indicates when the message is complete.
	 * If data remaining to be sent, clear and enable Tx � empty interrupt.
	 */
	IntrStatus = (XIIC_INTR_TX_EMPTY_MASK | XIIC_INTR_TX_ERROR_MASK);
	if (InstancePtr->SendByteCount > 1) {
		IntrStatus |= XIIC_INTR_TX_HALF_MASK;
	}

	/*
	 * Clear the interrupts in the status and then enable them and then
	 * exit the critical region.
	 */
	XIic_ClearEnableIntr(InstancePtr->BaseAddress, IntrStatus);

	XIic_IntrGlobalEnable(InstancePtr->BaseAddress);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function sends data as a slave on the IIC bus and should not be called
* until an event has occurred that indicates the device has been selected by
* a master attempting read from the slave (XII_MASTER_READ_EVENT).
*
* If more data is received than specified a No Acknowledge will be sent to
* signal the Master to stop sending data. Any received data is read to prevent
* the slave device from throttling the bus.
*
* @param	InstancePtr is a pointer to the Iic instance to be worked on.
* @param	RxMsgPtr is a pointer to the data to be transmitted.
* @param	ByteCount is the number of message bytes to be sent.
*
* @return
*		- XST_SUCCESS indicates the message transmission has been
*		initiated.
*		- XST_IIC_NOT_SLAVE indicates the device has not been selected
*		to be a slave on the IIC bus such that data cannot be received.
*
* @internal
*
* The master signals the message completion differently depending on the
* repeated start options.
*
* When the master is not using repeated start:
*  - Not Adressed As Slave NAAS interrupt signals the master has sent a stop
*    condition and is no longer sending data. This doesn't imply that the master
*    will not send a No Ack. It covers when the master fails to send No
*    Ackowledge before releasing the bus.
*  - Tx Error interrupt signals end of message.
*
* When the master is using repeated start:
*  - the Tx Error interrupt signals the master finished sending the msg.
*  - NAAS interrupt will not signal when message is complete as the
*    master may want to write or read another message with this device.
*
* To prevent throttling, the slave must contine to read discard the data
* when the receive buffer is full. When unexpected bytes are received, No Ack
* must be set and the Rx buffer continually read until either NAAS
* or Bus Not Busy BND interrupt signals the master is no longer
* interacting with this slave. At this point the Ack is set to ON allowing
* this device to acknowlefge the an address sent to it for the next
* slave message.
*
* The slave will always receive 1 byte before the bus is throttled causing a
* receive pending interrupt before this routine is executed. After one byte
* the bus will throttle. The depth is set to the proper amount immediatelly
* allowing the master to send more bytes and then to again throttle, but at the
* proper fifo depth. The interrupt is a level. Clearing and enabling will cause
* the Rx interrupt to pend at the correct level.
*
******************************************************************************/
int XIic_SlaveRecv(XIic *InstancePtr, u8 *RxMsgPtr, int ByteCount)
{
	u32 Status;

	/*
	 * If the device is not a slave on the IIC bus then indicate an error
	 * because data cannot be received on the bus.
	 */
	Status = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_SR_REG_OFFSET);
	if ((Status & XIIC_SR_ADDR_AS_SLAVE_MASK) == 0) {
		return XST_IIC_NOT_SLAVE;
	}

	XIic_IntrGlobalDisable(InstancePtr->BaseAddress);

	/*
	 * Save message state and invalidate the send buffer pointer to indicate
	 * the direction of transfer is receive.
	 */
	InstancePtr->RecvByteCount = ByteCount;
	InstancePtr->RecvBufferPtr = RxMsgPtr;
	InstancePtr->SendBufferPtr = NULL;

	/*
	 * Set receive FIFO occupancy depth so the Rx interrupt will occur
	 * when all bytes received or if more bytes than will fit in FIFO,
	 * set to max depth.
	 */
	if (ByteCount > IIC_RX_FIFO_DEPTH) {
		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_RFD_REG_OFFSET,
			 IIC_RX_FIFO_DEPTH - 1);
	} else {
		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_RFD_REG_OFFSET,
			 ByteCount - 1);
	}

	/*
	 * Clear and enable receive full interrupt except when the bytes to
	 * receive is only 1, don't clear interrupt as it is the only one your
	 * going to get.
	 */
	if (ByteCount > 1) {
		XIic_ClearIntr(InstancePtr->BaseAddress,
				XIIC_INTR_RX_FULL_MASK);
	}

	XIic_EnableIntr(InstancePtr->BaseAddress, XIIC_INTR_RX_FULL_MASK);

	XIic_IntrGlobalEnable(InstancePtr->BaseAddress);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function is called when the IIC device is Addressed As a Slave (AAS).
* This occurs when another device on the bus, a master, has addressed this
* device to receive a message.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void AddrAsSlaveHandler(XIic *InstancePtr)
{
	u32 Status;
	int CallValue;

	/*
	 * Disable AAS interrupt to clear the interrupt condition since this is
	 * interrupt does not go away and enable the not addressed as a slave
	 * interrrupt to tell when the master stops data transfer.
	 */
	XIic_DisableIntr(InstancePtr->BaseAddress, XIIC_INTR_AAS_MASK);
	XIic_ClearEnableIntr(InstancePtr->BaseAddress, XIIC_INTR_NAAS_MASK);

	/*
	 * Determine how the slave is being addressed and call the handler to
	 * notify the user of the event.
	 */
	Status = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_SR_REG_OFFSET);

	/*
	 * Determine if the master is trying to perform a read or write
	 * operation.
	 */
	if (Status & XIIC_SR_MSTR_RDING_SLAVE_MASK) {
		CallValue = XII_MASTER_READ_EVENT;
	} else {
		CallValue = XII_MASTER_WRITE_EVENT;
	}

	/*
	 * If being addressed with general call also indicate to handler.
	 */
	if (Status & XIIC_SR_GEN_CALL_MASK) {
		CallValue |= XII_GENERAL_CALL_EVENT;
	}

	InstancePtr->StatusHandler(InstancePtr->StatusCallBackRef, CallValue);
	return;
}

/*****************************************************************************/
/**
*
* This function is called when the IIC device receives Not Addressed As Slave
* (NAAS) interrupt which indicates that the master has released the bus implying
* a data transfer is complete.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void NotAddrAsSlaveHandler(XIic *InstancePtr)
{
	u32 Status;
	u32 CntlReg;
	u8 BytesToRead;
	u8 LoopCnt;
	u32 TxFifoOcy;

	/*
	 * Disable NAAS so that the condition will not continue to interrupt
	 * and enable the addressed as slave interrupt to know when a master
	 * selects a slave on the bus.
	 */
	XIic_DisableIntr(InstancePtr->BaseAddress, XIIC_INTR_NAAS_MASK);
	XIic_ClearEnableIntr(InstancePtr->BaseAddress, XIIC_INTR_AAS_MASK);

	/*
         * In the slave transmitter case pass the actual number of
         * bytes being recievd by the master to the user callback.
         */
	Status = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_SR_REG_OFFSET);
        TxFifoOcy = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_TFO_REG_OFFSET);
	if (!(Status & XIIC_SR_TX_FIFO_EMPTY_MASK)) {
		    InstancePtr->SendByteCount = InstancePtr->Stats.SendBytes -
                                        (TxFifoOcy+1) ;
	} else {
		    InstancePtr->SendByteCount = InstancePtr->Stats.SendBytes;
	}


	/*
	 * Flush Tx FIFO by toggling TxFIFOResetBit. FIFO runs normally at 0
	 * Do this incase needed to Tx FIFO with more than expected if what
	 * was set to Tx was less than what the Master expected - read more
	 * from this slave so FIFO had junk in it.
	 */
	XIic_FlushTxFifo(InstancePtr);

	/*
	 * NAAS interrupt was asserted but received data in recieve FIFO is
	 * less than Rc_FIFO_PIRQ to assert an receive full interrupt,in this
	 * condition as data recieved is valid we have to read data before FIFO
	 * flush.
	 */
	Status = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_SR_REG_OFFSET);

	if (!(Status & XIIC_SR_RX_FIFO_EMPTY_MASK)) {
		BytesToRead = (XIic_ReadReg(InstancePtr->BaseAddress,
							XIIC_RFO_REG_OFFSET)) + 1;
		if (InstancePtr->RecvByteCount > BytesToRead) {

			for (LoopCnt = 0; LoopCnt < BytesToRead; LoopCnt++) {
					XIic_ReadRecvByte(InstancePtr);
			}
		}
	}

	/*
	 * Flush Rx FIFO should slave Rx had a problem, sent No ack but
	 * still received a few bytes. Should the slave receive have disabled
	 * acknowledgement, clear Rx FIFO.
	 */
	XIic_FlushRxFifo(InstancePtr);

	/*
	 * Set FIFO occupancy depth = 1 so that the first byte will throttle
	 * next recieve msg.
	 */
	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_RFD_REG_OFFSET, 0);

	/*
	 * Should the slave receive have disabled acknowledgement,
	 * enable to allow acknowledgment for receipt of our address to
	 * again be used as a slave.
	 */
	CntlReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);
	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,
		 (CntlReg & ~XIIC_CR_NO_ACK_MASK));

	InstancePtr->IsSlaveSetAckOff = FALSE;

	/*
	 * Which callback depends on messaging direction, the buffer pointer NOT
	 * being used indicates the direction of data transfer.
	 */
	Status = XIic_ReadIier(InstancePtr->BaseAddress);
	if (InstancePtr->RecvBufferPtr == NULL) {
		/*
		 * Slave was sending data so disable all transmit interrupts and
		 * call the callback handler to indicate the transfer is
		 * complete.
		 */
		XIic_WriteIier(InstancePtr->BaseAddress,
					(Status & ~XIIC_TX_INTERRUPTS));
		InstancePtr->SendHandler(InstancePtr->SendCallBackRef,
					 InstancePtr->SendByteCount);
	}
	else {
		/*
		 * Slave was receiving data so disable receive full interrupt
		 * and call the callback handler to notify the transfer is
		 * complete.
		 */
		XIic_WriteIier(InstancePtr->BaseAddress,
					(Status & ~XIIC_INTR_RX_FULL_MASK));
		InstancePtr->RecvHandler(InstancePtr->RecvCallBackRef,
					 InstancePtr->RecvByteCount);
	}
	InstancePtr->RecvByteCount = 0;
	return;
}

/*****************************************************************************/
/**
*
* This function handles data received from the IIC bus as a slave.
*
* When the slave expects more than the master has to send, the slave will stall
* waiting for data.
*
* When more data is received than data expected a Nack is done to signal master
* to stop sending data. The excess data is discarded to prevent bus throttling.
*
* The buffer may be full and the master continues to send data if the master
* and slave have different message lengths. This condition is handled by sending
* No Ack to the master and reading Rx data until the master stops sending data
* to prevent but throttling from locking up the bus. To ever receive as a slave
* again, must know when to renable bus ACKs. NAAS is used to detect when the
* master is finished sending messages for any mode.

* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void RecvSlaveData(XIic *InstancePtr)
{
	u32 CntlReg;
	u8 BytesToRead;
	u8 LoopCnt;
	u8 Temp;

	/*
	 * When receive buffer has no room for the receive data discard it.
	 */
	if (InstancePtr->RecvByteCount == 0) {
		/*
		 * Set ACKnowlege OFF to signal master to stop sending data.
		 */
		CntlReg = XIic_ReadReg(InstancePtr->BaseAddress,
						XIIC_CR_REG_OFFSET);
		CntlReg |= XIIC_CR_NO_ACK_MASK;
		XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,
				CntlReg);

		/*
		 * Set a Flag to indicate that the Slave has set the ACK Off.
		 */
		InstancePtr->IsSlaveSetAckOff = TRUE;


		/*
		 * Clear excess received data to prevent bus throttling and set
		 * receive FIFO occupancy to throttle at the 1st byte received.
		 */
		XIic_FlushRxFifo(InstancePtr);
		XIic_WriteReg(InstancePtr->BaseAddress,
					XIIC_RFD_REG_OFFSET, 0);

		return;
	}
	/*
	 * Use occupancy count to determine how many bytes to read from the
	 * FIFO, count is zero based so add 1, read that number of bytes from
	 * the FIFO.
	 */
	BytesToRead = (XIic_ReadReg(InstancePtr->BaseAddress,
					XIIC_RFO_REG_OFFSET)) + 1;
	for (LoopCnt = 0; LoopCnt < BytesToRead; LoopCnt++) {
		XIic_ReadRecvByte(InstancePtr);
	}

	/*
	 * Set receive FIFO depth for the number of bytes to be received such
	 * that a receive interrupt will occur, the count is 0 based, the
	 * last byte of the message has to be received seperately to ack the
	 * message.
	 */
	if (InstancePtr->RecvByteCount > IIC_RX_FIFO_DEPTH) {
		Temp = IIC_RX_FIFO_DEPTH - 1;
	} else {
		if (InstancePtr->RecvByteCount == 0) {
			Temp = 0;
		} else {
			Temp = InstancePtr->RecvByteCount - 1;
		}
	}
	XIic_WriteReg(InstancePtr->BaseAddress,
			XIIC_RFD_REG_OFFSET, (u32) Temp);

	return;
}

/*****************************************************************************/
/**
*
* This function sends data on the IIC bus as a slave.
*
* When message data has been sent, but the master keeps reading data, the FIFO
* is filled to prevent bus throttling. There is no way to notify master of this
* condition. While sending data as a slave a transmit error indicates the
* master has completed the data transfer.
*
* NAAS interrupt signals when repeated start occurred and the msg is finished
* and BNB signals when the master sent a stop.
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void SendSlaveData(XIic *InstancePtr)
{
	/*
	 * When message has been sent, but master keeps reading data, must put a
	 * byte in the FIFO or bus will throttle. There is no way to notify
	 * master of this condition.
	 */
	if (InstancePtr->SendByteCount == 0) {
		XIic_WriteReg(InstancePtr->BaseAddress,
				XIIC_DTR_REG_OFFSET, 0xFF);
		return;
	}

	/*
	 * Send the data by filling the transmit FIFO.
	 */
	XIic_TransmitFifoFill(InstancePtr, XIIC_SLAVE_ROLE);
	/*
	 * When the amount of data remaining to send is less than the half mark
	 * of the FIFO making the use of � empty interrupt unnecessary,
	 * disable it. Is this a problem that it's checking against 1 rather
	 * than half?
	 */
	if (InstancePtr->SendByteCount < 1) {
		XIic_DisableIntr(InstancePtr->BaseAddress,
				  XIIC_INTR_TX_HALF_MASK);
	}
	return;
}
/** @} */
