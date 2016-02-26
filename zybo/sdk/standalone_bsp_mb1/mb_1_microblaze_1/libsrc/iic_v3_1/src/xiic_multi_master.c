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
* @file xiic_multi_master.c
* @addtogroup iic_v3_1
* @{
*
* Contains multi-master functions for the XIic component. This file is
* necessary if multiple masters are on the IIC bus such that arbitration can
* be lost or the bus can be busy.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- --- ------- -----------------------------------------------
* 1.01b jhl 3/27/02 Reparitioned the driver
* 1.01c ecm 12/05/02 new rev
* 1.13a wgr 03/22/07 Converted to new coding style.
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

static void BusNotBusyHandler(XIic *InstancePtr);
static void ArbitrationLostHandler(XIic *InstancePtr);

/************************** Variable Definitions **************************/


/****************************************************************************/
/**
* This function includes multi-master code such that multi-master events are
* handled properly. Multi-master events include a loss of arbitration and
* the bus transitioning from busy to not busy.  This function allows the
* multi-master processing to be optional.  This function must be called prior
* to allowing any multi-master events to occur, such as after the driver is
* initialized.
*
* @param	None.
*
* @return 	None.
*
* @note		None.
*
******************************************************************************/
void XIic_MultiMasterInclude()
{
	XIic_ArbLostFuncPtr = ArbitrationLostHandler;
	XIic_BusNotBusyFuncPtr = BusNotBusyHandler;
}

/*****************************************************************************/
/**
*
* The IIC bus busy signals when a master has control of the bus. Until the bus
* is released, i.e. not busy, other devices must wait to use it.
*
* When this interrupt occurs, it signals that the previous master has released
* the bus for another user.
*
* This interrupt is only enabled when the master Tx is waiting for the bus.
*
* This interrupt causes the following tasks:
* - Disable Bus not busy interrupt
* - Enable bus Ack
*	 Should the slave receive have disabled acknowledgement, enable to allow
*	 acknowledgment of the sending of our address to again be addresed as
*	 slave
* - Flush Rx FIFO
*	 Should the slave receive have disabled acknowledgement, a few bytes may
*	 be in FIFO if Rx full did not occur because of not enough byte in FIFO
*	 to have caused an interrupt.
* - Send status to user via status callback with the value:
*	XII_BUS_NOT_BUSY_EVENT
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void BusNotBusyHandler(XIic *InstancePtr)
{
	u32 Status;
	u32 CntlReg;

	/*
	 * Should the slave receive have disabled acknowledgement,
	 * enable to allow acknowledgment of the sending of our address to
	 * again be addresed as slave.
	 */
	CntlReg = XIic_ReadReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET);
	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,
		 (CntlReg & ~XIIC_CR_NO_ACK_MASK));

	/*
	 * Flush Tx FIFO by toggling TxFIFOResetBit. FIFO runs normally at 0
	 * Do this incase needed to Tx FIFO with more than expected if what
	 * was set to Tx was less than what the Master expected - read more
	 * from this slave so FIFO had junk in it.
	 */
	XIic_FlushTxFifo(InstancePtr);

	/*
	 * Flush Rx FIFO should slave Rx had a problem, sent No ack but
	 * still received a few bytes. Should the slave receive have disabled
	 * acknowledgement, clear Rx FIFO.
	 */
	XIic_FlushRxFifo(InstancePtr);

	/*
	 * Send Application messaging status via callbacks. Disable either Tx or
	 * Receive interrupt. Which callback depends on messaging direction.
	 */
	Status = XIic_ReadIier(InstancePtr->BaseAddress);
	if (InstancePtr->RecvBufferPtr == NULL) {
		/*
		 * Slave was sending data (master was reading), disable
		 * all the transmit interrupts.
		 */
		XIic_WriteIier(InstancePtr->BaseAddress,
				(Status & ~XIIC_TX_INTERRUPTS));
	}
	else {
		/*
		 * Slave was receiving data (master was writing) disable receive
		 * interrupts.
		 */
		XIic_WriteIier(InstancePtr->BaseAddress,
				(Status & ~XIIC_INTR_RX_FULL_MASK));
	}

	/*
	 * Send Status in StatusHandler callback.
	 */
	InstancePtr->StatusHandler(InstancePtr->StatusCallBackRef,
				   XII_BUS_NOT_BUSY_EVENT);
}

/*****************************************************************************/
/**
*
* When multiple IIC devices attempt to use the bus simultaneously, only
* a single device will be able to keep control as a master. Those devices
* that didn't retain control over the bus are said to have lost arbitration.
* When arbitration is lost, this interrupt occurs sigaling the user that
* the message did not get sent as expected.
*
* This function, at arbitration lost:
*   - Disables Tx empty, � empty and Tx error interrupts
*   - Clears any Tx empty, � empty Rx Full or Tx error interrupts
*   - Clears Arbitration lost interrupt,
*   - Flush Tx FIFO
*   - Call StatusHandler callback with the value: XII_ARB_LOST_EVENT
*
* @param	InstancePtr is a pointer to the XIic instance to be worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void ArbitrationLostHandler(XIic *InstancePtr)
{
	/*
	 * Disable Tx empty and � empty and Tx error interrupts before clearing
	 * them so they won't occur again.
	 */
	XIic_DisableIntr(InstancePtr->BaseAddress, XIIC_TX_INTERRUPTS);

	/*
	 * Clear any Tx empty, � empty Rx Full or Tx error interrupts.
	 */
	XIic_ClearIntr(InstancePtr->BaseAddress, XIIC_TX_INTERRUPTS);

	XIic_FlushTxFifo(InstancePtr);

	/*
	 * Update Status via StatusHandler callback.
	 */
	InstancePtr->StatusHandler(InstancePtr->StatusCallBackRef,
				   XII_ARB_LOST_EVENT);
}
/** @} */
