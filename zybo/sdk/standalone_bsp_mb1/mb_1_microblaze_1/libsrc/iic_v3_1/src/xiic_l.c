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
* @file xiic_l.c
* @addtogroup iic_v3_1
* @{
*
* This file contains low-level driver functions that can be used to access the
* device in normal and dynamic controller mode. The user should refer to the
* hardware device specification for more details of the device operation.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- --- -------   -----------------------------------------------
* 1.01b jhl 05/13/02  First release
* 1.01b jhl 10/14/02  Corrected bug in the receive function, the setup of the
*                     interrupt status mask was not being done in the loop such
*                     that a read would sometimes fail on the last byte because
*                     the transmit error which should have been ignored was
*                     being used.  This would leave an extra byte in the FIFO
*                     and the bus throttled such that the next operation would
*                     also fail.  Also updated the receive function to not
*                     disable the device after the last byte until after the
*                     bus transitions to not busy which is more consistent
*                     with the expected behavior.
* 1.01c ecm  12/05/02 new rev
* 1.02a mta  03/09/06 Implemented Repeated Start in the Low Level Driver.
* 1.03a mta  04/04/06 Implemented Dynamic IIC core routines.
* 1.03a ecm  06/15/06 Fixed the hang in low_level_eeprom_test with -O0
*                     Added polling loops for BNB to allow the slave to
*                     respond correctly. Also added polling loop prior
*                     to reset in _Recv.
* 1.13a wgr  03/22/07 Converted to new coding style.
* 1.13b ecm  11/29/07 added BB polling loops to the DynSend and DynRecv
*			routines to handle the race condition with BNB in IISR.
* 2.00a sdm  10/22/09 Converted all register accesses to 32 bit access.
*		      Updated to use the HAL APIs/macros.
*		      Some of the macros have been renamed to remove _m from
*		      the name and Some of the macros have been renamed to be
*		      consistent, see the xiic_i.h and xiic_l.h files for
*		      further information.
* 2.02a sdm  10/08/10 Updated to disable the device at the end of the transfer,
*		      only when addressed as slave in XIic_Send for CR565373.
* 2.04a sdm  07/22/11 Removed a compiler warning by adding parenthesis around &
*		      at line 479.
* 2.08a adk  29/07/13 In Low level driver In repeated start condition the
*		      Direction of Tx bit must be disabled in Receive
*		      condition It Fixes the CR:685759 Changes are done
*		      in the function XIic_Recv.
* </pre>
*
****************************************************************************/

/***************************** Include Files *******************************/

#include "xil_types.h"
#include "xil_assert.h"
#include "xiic_l.h"

/************************** Constant Definitions ***************************/

/**************************** Type Definitions *****************************/

/***************** Macros (Inline Functions) Definitions *******************/

/************************** Function Prototypes ****************************/

static unsigned RecvData(u32 BaseAddress, u8 *BufferPtr,
			 unsigned ByteCount, u8 Option);
static unsigned SendData(u32 BaseAddress, u8 *BufferPtr,
			 unsigned ByteCount, u8 Option);

static unsigned DynRecvData(u32 BaseAddress, u8 *BufferPtr, u8 ByteCount);
static unsigned DynSendData(u32 BaseAddress, u8 *BufferPtr,
				u8 ByteCount, u8 Option);

/************************** Variable Definitions **************************/

/****************************************************************************/
/**
* Receive data as a master on the IIC bus.  This function receives the data
* using polled I/O and blocks until the data has been received. It only
* supports 7 bit addressing mode of operation. The user is responsible for
* ensuring the bus is not busy if multiple masters are present on the bus.
*
* @param	BaseAddress contains the base address of the IIC device.
* @param	Address contains the 7 bit IIC address of the device to send the
*		specified data to.
* @param	BufferPtr points to the data to be sent.
* @param	ByteCount is the number of bytes to be sent.
* @param	Option indicates whether to hold or free the bus after reception
*		of data, XIIC_STOP = end with STOP condition,
*		XIIC_REPEATED_START = don't end with STOP condition.
*
* @return	The number of bytes received.
*
* @note		None.
*
******************************************************************************/
unsigned XIic_Recv(u32 BaseAddress, u8 Address,
			u8 *BufferPtr, unsigned ByteCount, u8 Option)
{
	u32 CntlReg;
	unsigned RemainingByteCount;
	volatile u32 StatusReg;

	/* Tx error is enabled incase the address (7 or 10) has no device to
	 * answer with Ack. When only one byte of data, must set NO ACK before
	 * address goes out therefore Tx error must not be enabled as it will go
	 * off immediately and the Rx full interrupt will be checked.  If full,
	 * then the one byte was received and the Tx error will be disabled
	 * without sending an error callback msg
	 */
	XIic_ClearIisr(BaseAddress,
			XIIC_INTR_RX_FULL_MASK | XIIC_INTR_TX_ERROR_MASK |
			XIIC_INTR_ARB_LOST_MASK);

	/* Set receive FIFO occupancy depth for 1 byte (zero based) */
	XIic_WriteReg(BaseAddress,  XIIC_RFD_REG_OFFSET, 0);


	/* Check to see if already Master on the Bus.
	 * If Repeated Start bit is not set send Start bit by setting MSMS bit
	 * else Send the address
	 */
	CntlReg = XIic_ReadReg(BaseAddress,  XIIC_CR_REG_OFFSET);
	if ((CntlReg & XIIC_CR_REPEATED_START_MASK) == 0) {
		/* 7 bit slave address, send the address for a read operation
		 * and set the state to indicate the address has been sent
		 */
		XIic_Send7BitAddress(BaseAddress, Address,
					XIIC_READ_OPERATION);


		/* MSMS gets set after putting data in FIFO. Start the master
		 * receive operation by setting CR Bits MSMS to Master, if the
		 * buffer is only one byte, then it should not be acknowledged
		 * to indicate the end of data
		 */
		CntlReg = XIIC_CR_MSMS_MASK | XIIC_CR_ENABLE_DEVICE_MASK;
		if (ByteCount == 1) {
			CntlReg |= XIIC_CR_NO_ACK_MASK;
		}

		/* Write out the control register to start receiving data and
		 * call the function to receive each byte into the buffer
		 */
		XIic_WriteReg(BaseAddress,  XIIC_CR_REG_OFFSET, CntlReg);

		/* Clear the latched interrupt status for the bus not busy bit
		 * which must be done while the bus is busy
		 */
		StatusReg = XIic_ReadReg(BaseAddress,  XIIC_SR_REG_OFFSET);

		while ((StatusReg & XIIC_SR_BUS_BUSY_MASK) == 0) {
			StatusReg = XIic_ReadReg(BaseAddress,
						  XIIC_SR_REG_OFFSET);
		}

		XIic_ClearIisr(BaseAddress, XIIC_INTR_BNB_MASK);
	} else {
	        /* Before writing 7bit slave address the Direction of Tx bit
		 * must be disabled
		 */
		CntlReg &= ~XIIC_CR_DIR_IS_TX_MASK;
		XIic_WriteReg(BaseAddress,  XIIC_CR_REG_OFFSET, CntlReg);
		/* Already owns the Bus indicating that its a Repeated Start
		 * call. 7 bit slave address, send the address for a read
		 * operation and set the state to indicate the address has been
		 * sent
		 */
		XIic_Send7BitAddress(BaseAddress, Address,
					XIIC_READ_OPERATION);
	}
	/* Try to receive the data from the IIC bus */

	RemainingByteCount = RecvData(BaseAddress, BufferPtr,
				      ByteCount, Option);

	CntlReg = XIic_ReadReg(BaseAddress,  XIIC_CR_REG_OFFSET);
	if ((CntlReg & XIIC_CR_REPEATED_START_MASK) == 0) {
		/* The receive is complete, disable the IIC device if the Option
		 * is to release the Bus after Reception of data and return the
		 * number of bytes that was received
		 */
		XIic_WriteReg(BaseAddress,  XIIC_CR_REG_OFFSET, 0);
	}

	/* Return the number of bytes that was received */
	return ByteCount - RemainingByteCount;
}

/******************************************************************************
*
* Receive the specified data from the device that has been previously addressed
* on the IIC bus.  This function assumes that the 7 bit address has been sent
* and it should wait for the transmit of the address to complete.
*
* @param	BaseAddress contains the base address of the IIC device.
* @param	BufferPtr points to the buffer to hold the data that is
*		received.
* @param	ByteCount is the number of bytes to be received.
* @param	Option indicates whether to hold or free the bus after reception
*		of data, XIIC_STOP = end with STOP condition,
*		XIIC_REPEATED_START = don't end with STOP condition.
*
* @return	The number of bytes remaining to be received.
*
* @note
*
* This function does not take advantage of the receive FIFO because it is
* designed for minimal code space and complexity.  It contains loops that
* that could cause the function not to return if the hardware is not working.
*
* This function assumes that the calling function will disable the IIC device
* after this function returns.
*
******************************************************************************/
static unsigned RecvData(u32 BaseAddress, u8 *BufferPtr,
			 unsigned ByteCount, u8 Option)
{
	u32 CntlReg;
	u32 IntrStatusMask;
	u32 IntrStatus;

	/* Attempt to receive the specified number of bytes on the IIC bus */

	while (ByteCount > 0) {
		/* Setup the mask to use for checking errors because when
		 * receiving one byte OR the last byte of a multibyte message an
		 * error naturally occurs when the no ack is done to tell the
		 * slave the last byte
		 */
		if (ByteCount == 1) {
			IntrStatusMask =
				XIIC_INTR_ARB_LOST_MASK | XIIC_INTR_BNB_MASK;
		} else {
			IntrStatusMask =
				XIIC_INTR_ARB_LOST_MASK |
				XIIC_INTR_TX_ERROR_MASK | XIIC_INTR_BNB_MASK;
		}

		/* Wait for the previous transmit and the 1st receive to
		 * complete by checking the interrupt status register of the
		 * IPIF
		 */
		while (1) {
			IntrStatus = XIic_ReadIisr(BaseAddress);
			if (IntrStatus & XIIC_INTR_RX_FULL_MASK) {
				break;
			}
			/* Check the transmit error after the receive full
			 * because when sending only one byte transmit error
			 * will occur because of the no ack to indicate the end
			 * of the data
			 */
			if (IntrStatus & IntrStatusMask) {
				return ByteCount;
			}
		}

		CntlReg = XIic_ReadReg(BaseAddress,  XIIC_CR_REG_OFFSET);

		/* Special conditions exist for the last two bytes so check for
		 * them. Note that the control register must be setup for these
		 * conditions before the data byte which was already received is
		 * read from the receive FIFO (while the bus is throttled
		 */
		if (ByteCount == 1) {
			if (Option == XIIC_STOP) {

				/* If the Option is to release the bus after the
				 * last data byte, it has already been read and
				 * no ack has been done, so clear MSMS while
				 * leaving the device enabled so it can get off
				 * the IIC bus appropriately with a stop
				 */
				XIic_WriteReg(BaseAddress,  XIIC_CR_REG_OFFSET,
					 XIIC_CR_ENABLE_DEVICE_MASK);
			}
		}

		/* Before the last byte is received, set NOACK to tell the slave
		 * IIC device that it is the end, this must be done before
		 * reading the byte from the FIFO
		 */
		if (ByteCount == 2) {
			/* Write control reg with NO ACK allowing last byte to
			 * have the No ack set to indicate to slave last byte
			 * read
			 */
			XIic_WriteReg(BaseAddress,  XIIC_CR_REG_OFFSET,
				 CntlReg | XIIC_CR_NO_ACK_MASK);
		}

		/* Read in data from the FIFO and unthrottle the bus such that
		 * the next byte is read from the IIC bus
		 */
		*BufferPtr++ = (u8) XIic_ReadReg(BaseAddress,
						  XIIC_DRR_REG_OFFSET);

		if ((ByteCount == 1) && (Option == XIIC_REPEATED_START)) {

			/* RSTA bit should be set only when the FIFO is
			 * completely Empty.
			 */
			XIic_WriteReg(BaseAddress,  XIIC_CR_REG_OFFSET,
				 XIIC_CR_ENABLE_DEVICE_MASK | XIIC_CR_MSMS_MASK
				 | XIIC_CR_REPEATED_START_MASK);

		}

		/* Clear the latched interrupt status so that it will be updated
		 * with the new state when it changes, this must be done after
		 * the receive register is read
		 */
		XIic_ClearIisr(BaseAddress, XIIC_INTR_RX_FULL_MASK |
				XIIC_INTR_TX_ERROR_MASK |
				XIIC_INTR_ARB_LOST_MASK);
		ByteCount--;
	}

	if (Option == XIIC_STOP) {

		/* If the Option is to release the bus after Reception of data,
		 * wait for the bus to transition to not busy before returning,
		 * the IIC device cannot be disabled until this occurs. It
		 * should transition as the MSMS bit of the control register was
		 * cleared before the last byte was read from the FIFO
		 */
		while (1) {
			if (XIic_ReadIisr(BaseAddress) & XIIC_INTR_BNB_MASK) {
				break;
			}
		}
	}

	return ByteCount;
}

/****************************************************************************/
/**
* Send data as a master on the IIC bus.  This function sends the data
* using polled I/O and blocks until the data has been sent. It only supports
* 7 bit addressing mode of operation.  The user is responsible for ensuring
* the bus is not busy if multiple masters are present on the bus.
*
* @param	BaseAddress contains the base address of the IIC device.
* @param	Address contains the 7 bit IIC address of the device to send the
*		specified data to.
* @param	BufferPtr points to the data to be sent.
* @param	ByteCount is the number of bytes to be sent.
* @param	Option indicates whether to hold or free the bus after
* 		transmitting the data.
*
* @return	The number of bytes sent.
*
* @note		None.
*
******************************************************************************/
unsigned XIic_Send(u32 BaseAddress, u8 Address,
		   u8 *BufferPtr, unsigned ByteCount, u8 Option)
{
	unsigned RemainingByteCount;
	u32 ControlReg;
	volatile u32 StatusReg;

	/* Check to see if already Master on the Bus.
	 * If Repeated Start bit is not set send Start bit by setting
	 * MSMS bit else Send the address.
	 */
	ControlReg = XIic_ReadReg(BaseAddress,  XIIC_CR_REG_OFFSET);
	if ((ControlReg & XIIC_CR_REPEATED_START_MASK) == 0) {
		/*
		 * Put the address into the FIFO to be sent and indicate
		 * that the operation to be performed on the bus is a
		 * write operation
		 */
		XIic_Send7BitAddress(BaseAddress, Address,
					XIIC_WRITE_OPERATION);
		/* Clear the latched interrupt status so that it will
		 * be updated with the new state when it changes, this
		 * must be done after the address is put in the FIFO
		 */
		XIic_ClearIisr(BaseAddress, XIIC_INTR_TX_EMPTY_MASK |
				XIIC_INTR_TX_ERROR_MASK |
				XIIC_INTR_ARB_LOST_MASK);

		/*
		 * MSMS must be set after putting data into transmit FIFO,
		 * indicate the direction is transmit, this device is master
		 * and enable the IIC device
		 */
		XIic_WriteReg(BaseAddress,  XIIC_CR_REG_OFFSET,
			 XIIC_CR_MSMS_MASK | XIIC_CR_DIR_IS_TX_MASK |
			 XIIC_CR_ENABLE_DEVICE_MASK);

		/*
		 * Clear the latched interrupt
		 * status for the bus not busy bit which must be done while
		 * the bus is busy
		 */
		StatusReg = XIic_ReadReg(BaseAddress,  XIIC_SR_REG_OFFSET);
		while ((StatusReg & XIIC_SR_BUS_BUSY_MASK) == 0) {
			StatusReg = XIic_ReadReg(BaseAddress,
						  XIIC_SR_REG_OFFSET);
		}

		XIic_ClearIisr(BaseAddress, XIIC_INTR_BNB_MASK);
	}
	else {
		/*
		 * Already owns the Bus indicating that its a Repeated Start
		 * call. 7 bit slave address, send the address for a write
		 * operation and set the state to indicate the address has
		 * been sent.
		 */
		XIic_Send7BitAddress(BaseAddress, Address,
					XIIC_WRITE_OPERATION);
	}

	/* Send the specified data to the device on the IIC bus specified by the
	 * the address
	 */
	RemainingByteCount = SendData(BaseAddress, BufferPtr,
					ByteCount, Option);

	ControlReg = XIic_ReadReg(BaseAddress,  XIIC_CR_REG_OFFSET);
	if ((ControlReg & XIIC_CR_REPEATED_START_MASK) == 0) {
		/*
		 * The Transmission is completed, disable the IIC device if
		 * the Option is to release the Bus after transmission of data
		 * and return the number of bytes that was received. Only wait
		 * if master, if addressed as slave just reset to release
		 * the bus.
		 */
		if ((ControlReg & XIIC_CR_MSMS_MASK) != 0) {
			XIic_WriteReg(BaseAddress,  XIIC_CR_REG_OFFSET,
				 (ControlReg & ~XIIC_CR_MSMS_MASK));
			StatusReg = XIic_ReadReg(BaseAddress,
					XIIC_SR_REG_OFFSET);
			while ((StatusReg & XIIC_SR_BUS_BUSY_MASK) != 0) {
				StatusReg = XIic_ReadReg(BaseAddress,
						XIIC_SR_REG_OFFSET);
			}
		}

		if ((XIic_ReadReg(BaseAddress, XIIC_SR_REG_OFFSET) &
		    XIIC_SR_ADDR_AS_SLAVE_MASK) != 0) {
			XIic_WriteReg(BaseAddress,  XIIC_CR_REG_OFFSET, 0);
		}
	}

	return ByteCount - RemainingByteCount;
}

/******************************************************************************
*
* Send the specified buffer to the device that has been previously addressed
* on the IIC bus.  This function assumes that the 7 bit address has been sent
* and it should wait for the transmit of the address to complete.
*
* @param	BaseAddress contains the base address of the IIC device.
* @param	BufferPtr points to the data to be sent.
* @param	ByteCount is the number of bytes to be sent.
* @param	Option indicates whether to hold or free the bus after
*		transmitting the data.
*
* @return	The number of bytes remaining to be sent.
*
* @note
*
* This function does not take advantage of the transmit FIFO because it is
* designed for minimal code space and complexity.  It contains loops that
* that could cause the function not to return if the hardware is not working.
*
******************************************************************************/
static unsigned SendData(u32 BaseAddress, u8 *BufferPtr,
			 unsigned ByteCount, u8 Option)
{
	u32 IntrStatus;

	/*
	 * Send the specified number of bytes in the specified buffer by polling
	 * the device registers and blocking until complete
	 */
	while (ByteCount > 0) {
		/*
		 * Wait for the transmit to be empty before sending any more
		 * data by polling the interrupt status register
		 */
		while (1) {
			IntrStatus = XIic_ReadIisr(BaseAddress);

			if (IntrStatus & (XIIC_INTR_TX_ERROR_MASK |
					  XIIC_INTR_ARB_LOST_MASK |
					  XIIC_INTR_BNB_MASK)) {
				return ByteCount;
			}

			if (IntrStatus & XIIC_INTR_TX_EMPTY_MASK) {
				break;
			}
		}
		/* If there is more than one byte to send then put the
		 * next byte to send into the transmit FIFO
		 */
		if (ByteCount > 1) {
			XIic_WriteReg(BaseAddress,  XIIC_DTR_REG_OFFSET,
				 *BufferPtr++);
		}
		else {
			if (Option == XIIC_STOP) {
				/*
				 * If the Option is to release the bus after
				 * the last data byte, Set the stop Option
				 * before sending the last byte of data so
				 * that the stop Option will be generated
				 * immediately following the data. This is
				 * done by clearing the MSMS bit in the
				 * control register.
				 */
				XIic_WriteReg(BaseAddress,  XIIC_CR_REG_OFFSET,
					 XIIC_CR_ENABLE_DEVICE_MASK |
					 XIIC_CR_DIR_IS_TX_MASK);
			}

			/*
			 * Put the last byte to send in the transmit FIFO
			 */
			XIic_WriteReg(BaseAddress,  XIIC_DTR_REG_OFFSET,
				 *BufferPtr++);

			if (Option == XIIC_REPEATED_START) {
				XIic_ClearIisr(BaseAddress,
						XIIC_INTR_TX_EMPTY_MASK);
				/*
				 * Wait for the transmit to be empty before
				 * setting RSTA bit.
				 */
				while (1) {
					IntrStatus =
						XIic_ReadIisr(BaseAddress);
					if (IntrStatus &
						XIIC_INTR_TX_EMPTY_MASK) {
						/*
						 * RSTA bit should be set only
						 * when the FIFO is completely
						 * Empty.
						 */
						XIic_WriteReg(BaseAddress,
							 XIIC_CR_REG_OFFSET,
						   XIIC_CR_REPEATED_START_MASK |
						   XIIC_CR_ENABLE_DEVICE_MASK |
						   XIIC_CR_DIR_IS_TX_MASK |
						   XIIC_CR_MSMS_MASK);
						break;
					}
				}
			}
		}

		/*
		 * Clear the latched interrupt status register and this must be
		 * done after the transmit FIFO has been written to or it won't
		 * clear
		 */
		XIic_ClearIisr(BaseAddress, XIIC_INTR_TX_EMPTY_MASK);

		/*
		 * Update the byte count to reflect the byte sent and clear
		 * the latched interrupt status so it will be updated for the
		 * new state
		 */
		ByteCount--;
	}

	if (Option == XIIC_STOP) {
		/*
		 * If the Option is to release the bus after transmission of
		 * data, Wait for the bus to transition to not busy before
		 * returning, the IIC device cannot be disabled until this
		 * occurs. Note that this is different from a receive operation
		 * because the stop Option causes the bus to go not busy.
		 */
		while (1) {
			if (XIic_ReadIisr(BaseAddress) &
				XIIC_INTR_BNB_MASK) {
				break;
			}
		}
	}

	return ByteCount;
}

/*****************************************************************************/
/**
* Receive data as a master on the IIC bus. This function receives the data
* using polled I/O and blocks until the data has been received. It only
* supports 7 bit addressing. The user is responsible for ensuring the bus is
* not busy if multiple masters are present on the bus.
*
* @param	BaseAddress contains the base address of the IIC Device.
* @param	Address contains the 7 bit IIC Device address of the device to
*		send the specified data to.
* @param	BufferPtr points to the data to be sent.
* @param	ByteCount is the number of bytes to be sent. This value can't be
*		greater than 255 and needs to be greater than 0.
*
* @return	The number of bytes received.
*
* @note		Upon entry to this function, the IIC interface needs to be
*		already enabled in the CR register.
*
******************************************************************************/
unsigned XIic_DynRecv(u32 BaseAddress, u8 Address, u8 *BufferPtr, u8 ByteCount)
{
	unsigned RemainingByteCount;
	u32 StatusRegister;

	/*
	 * Clear the latched interrupt status so that it will be updated with
	 * the new state when it changes.
	 */
	XIic_ClearIisr(BaseAddress, XIIC_INTR_TX_EMPTY_MASK |
			XIIC_INTR_TX_ERROR_MASK | XIIC_INTR_ARB_LOST_MASK);

	/*
	 * Send the 7 bit slave address for a read operation and set the state
	 * to indicate the address has been sent. Upon writing the address, a
	 * start condition is initiated. MSMS is automatically set to master
	 * when the address is written to the Fifo. If MSMS was already set,
	 * then a re-start is sent prior to the address.
	 */
	XIic_DynSend7BitAddress(BaseAddress, Address, XIIC_READ_OPERATION);

	/*
	 * Wait for the bus to go busy.
	 */
	StatusRegister = XIic_ReadReg(BaseAddress,  XIIC_SR_REG_OFFSET);

	while (( StatusRegister & XIIC_SR_BUS_BUSY_MASK)
			!= XIIC_SR_BUS_BUSY_MASK) {
		StatusRegister = XIic_ReadReg(BaseAddress,
				XIIC_SR_REG_OFFSET);
	}

	/*
	 * Clear the latched interrupt status for the bus not busy bit which
	 * must be done while the bus is busy.
	 */
	XIic_ClearIisr(BaseAddress, XIIC_INTR_BNB_MASK);

	/*
	 * Write to the Tx Fifo the dynamic stop control bit with the number of
	 * bytes that are to be read over the IIC interface from the presently
	 * addressed device.
	 */
	XIic_DynSendStop(BaseAddress, ByteCount);

	/*
	 * Receive the data from the IIC bus.
	 */
	RemainingByteCount = DynRecvData(BaseAddress, BufferPtr, ByteCount);

	/*
	 * The receive is complete. Return the number of bytes that were
	 * received.
	 */
	return ByteCount - RemainingByteCount;
}

/*****************************************************************************/
/**
* Receive the specified data from the device that has been previously addressed
* on the IIC bus. This function assumes the following:
* - The Rx Fifo occupancy depth has been set to its max.
* - Upon entry, the Rx Fifo is empty.
* - The 7 bit address has been sent.
* - The dynamic stop and number of bytes to receive has been written to Tx
*   Fifo.
*
* @param	BaseAddress contains the base address of the IIC Device.
* @param	BufferPtr points to the buffer to hold the data that is
*		received.
* @param	ByteCount is the number of bytes to be received. The range of
*		this value is greater than 0 and not higher than 255.
*
* @return	The number of bytes remaining to be received.
*
* @note		This function contains loops that could cause the function not
*		to return if the hardware is not working.
*
******************************************************************************/
static unsigned DynRecvData(u32 BaseAddress, u8 *BufferPtr, u8 ByteCount)
{
	u32 StatusReg;
	u32 IntrStatus;
	u32 IntrStatusMask;

	while (ByteCount > 0) {

		/*
		 * Setup the mask to use for checking errors because when
		 * receiving one byte OR the last byte of a multibyte message
		 * an error naturally occurs when the no ack is done to tell
		 * the slave the last byte.
		 */
		if (ByteCount == 1) {
			IntrStatusMask =
				XIIC_INTR_ARB_LOST_MASK | XIIC_INTR_BNB_MASK;
		} else {
			IntrStatusMask =
				XIIC_INTR_ARB_LOST_MASK |
				XIIC_INTR_TX_ERROR_MASK | XIIC_INTR_BNB_MASK;
		}

		/*
		 * Wait for a byte to show up in the Rx Fifo.
		 */
		while (1) {
			IntrStatus = XIic_ReadIisr(BaseAddress);
			StatusReg = XIic_ReadReg(BaseAddress,
						  XIIC_SR_REG_OFFSET);

			if ((StatusReg & XIIC_SR_RX_FIFO_EMPTY_MASK) !=
				XIIC_SR_RX_FIFO_EMPTY_MASK) {
				break;
			}
			/*
			 * Check the transmit error after the receive full
			 * because when sending only one byte transmit error
			 * will occur because of the no ack to indicate the end
			 * of the data.
			 */
			if (IntrStatus & IntrStatusMask) {
				return ByteCount;
			}
		}

		/*
		 * Read in byte from the Rx Fifo. If the Fifo reached the
		 * programmed occupancy depth as programmed in the Rx occupancy
		 * reg, this read access will un throttle the bus such that
		 * the next byte is read from the IIC bus.
		 */
		*BufferPtr++ = XIic_ReadReg(BaseAddress,  XIIC_DRR_REG_OFFSET);
		ByteCount--;
	}

	return ByteCount;
}

/*****************************************************************************/
/**
* Send data as a master on the IIC bus. This function sends the data using
* polled I/O and blocks until the data has been sent. It only supports 7 bit
* addressing. The user is responsible for ensuring the bus is not busy if
* multiple masters are present on the bus.
*
* @param	BaseAddress contains the base address of the IIC Device.
* @param	Address contains the 7 bit IIC address of the device to send the
*		specified data to.
* @param	BufferPtr points to the data to be sent.
* @param	ByteCount is the number of bytes to be sent.
* @param	Option: XIIC_STOP = end with STOP condition,
*		XIIC_REPEATED_START = don't end with STOP condition.
*
* @return	The number of bytes sent.
*
* @note		None.
*
******************************************************************************/
unsigned XIic_DynSend(u32 BaseAddress, u16 Address, u8 *BufferPtr,
			u8 ByteCount, u8 Option)
{
	unsigned RemainingByteCount;
	u32 StatusRegister;

	/*
	 * Clear the latched interrupt status so that it will be updated with
	 * the new state when it changes, this must be done after the address
	 * is put in the FIFO
	 */
	XIic_ClearIisr(BaseAddress, XIIC_INTR_TX_EMPTY_MASK |
			XIIC_INTR_TX_ERROR_MASK | XIIC_INTR_ARB_LOST_MASK);

	/*
	 * Put the address into the Fifo to be sent and indicate that the
	 * operation to be performed on the bus is a write operation. Upon
	 * writing the address, a start condition is initiated. MSMS is
	 * automatically set to master when the address is written to the Fifo.
	 * If MSMS was already set, then a re-start is sent prior to the
	 * address.
	 */
	if(!(Address & XIIC_TX_DYN_STOP_MASK)) {

		XIic_DynSend7BitAddress(BaseAddress, Address,
				XIIC_WRITE_OPERATION);
	} else {
		XIic_DynSendStartStopAddress(BaseAddress, Address,
					XIIC_WRITE_OPERATION);
	}

	/*
	 * Wait for the bus to go busy.
	 */
	StatusRegister = XIic_ReadReg(BaseAddress,  XIIC_SR_REG_OFFSET);

	while (( StatusRegister & XIIC_SR_BUS_BUSY_MASK) !=
			XIIC_SR_BUS_BUSY_MASK) {
		StatusRegister = XIic_ReadReg(BaseAddress,
				XIIC_SR_REG_OFFSET);
	}

	/*
	 * Clear the latched interrupt status for the bus not busy bit which
	 * must be done while the bus is busy.
	 */
	XIic_ClearIisr(BaseAddress, XIIC_INTR_BNB_MASK);

	/*
	 * Send the specified data to the device on the IIC bus specified by the
	 * the address.
	 */
	RemainingByteCount = DynSendData(BaseAddress, BufferPtr, ByteCount,
					 Option);

	/*
	 * The send is complete return the number of bytes that was sent.
	 */
	return ByteCount - RemainingByteCount;
}

/******************************************************************************
*
* Send the specified buffer to the device that has been previously addressed
* on the IIC bus. This function assumes that the 7 bit address has been sent.
*
* @param	BaseAddress contains the base address of the IIC Device.
* @param	BufferPtr points to the data to be sent.
* @param	ByteCount is the number of bytes to be sent.
* @param	Option: XIIC_STOP = end with STOP condition, XIIC_REPEATED_START
*		= don't end with STOP condition.
*
* @return	The number of bytes remaining to be sent.
*
* @note		This function does not take advantage of the transmit Fifo
*		because it is designed for minimal code space and complexity.
*
******************************************************************************/
static unsigned DynSendData(u32 BaseAddress, u8 *BufferPtr,
			    u8 ByteCount, u8 Option)
{
	u32 IntrStatus;

	while (ByteCount > 0) {
		/*
		 * Wait for the transmit to be empty before sending any more
		 * data by polling the interrupt status register.
		 */
		while (1) {
			IntrStatus = XIic_ReadIisr(BaseAddress);
			if (IntrStatus & (XIIC_INTR_TX_ERROR_MASK |
					  XIIC_INTR_ARB_LOST_MASK |
					  XIIC_INTR_BNB_MASK)) {
				/*
				 * Error condition (NACK or ARB Lost or BNB
				 * Error Has occurred. Clear the Control
				 * register to send a STOP condition on the Bus
				 * and return the number of bytes still to
				 * transmit.
				 */
				XIic_WriteReg(BaseAddress,  XIIC_CR_REG_OFFSET,
						0x03);
				XIic_WriteReg(BaseAddress,  XIIC_CR_REG_OFFSET,
						0x01);

				return ByteCount;
			}

			/*
			 * Check for the transmit Fifo to become Empty.
			 */
			if (IntrStatus & XIIC_INTR_TX_EMPTY_MASK) {
				break;
			}
		}

		/*
		 * Send data to Tx Fifo. If a stop condition is specified and
		 * the last byte is being sent, then set the dynamic stop bit.
		 */
		if ((ByteCount == 1) && (Option == XIIC_STOP)) {
			/*
			 * The MSMS will be cleared automatically upon setting
			 *  dynamic stop.
			 */
			XIic_WriteReg(BaseAddress,  XIIC_DTR_REG_OFFSET,
					XIIC_TX_DYN_STOP_MASK | *BufferPtr++);
		} else {
			XIic_WriteReg(BaseAddress,  XIIC_DTR_REG_OFFSET,
					*BufferPtr++);
		}

		/*
		 * Update the byte count to reflect the byte sent.
		 */
		ByteCount--;
	}

	if (Option == XIIC_STOP) {
		/*
		 * If the Option is to release the bus after transmission of
		 * data, Wait for the bus to transition to not busy before
		 * returning, the IIC device cannot be disabled until this
		 * occurs.
		 */
		while (1) {
			if (XIic_ReadIisr(BaseAddress) & XIIC_INTR_BNB_MASK) {
				break;
			}
		}
	}

	return ByteCount;
}

/******************************************************************************
*
* Initialize the IIC core for Dynamic Functionality.
*
* @param	BaseAddress contains the base address of the IIC Device.
*
* @return	XST_SUCCESS if Successful else XST_FAILURE.
*
* @note		None.
*
******************************************************************************/
int XIic_DynInit(u32 BaseAddress)
{
	u32 Status;

	/*
	 * Reset IIC Core.
	 */
	XIic_WriteReg(BaseAddress, XIIC_RESETR_OFFSET, XIIC_RESET_MASK);

	/*
	 * Set receive Fifo depth to maximum (zero based).
	 */
	XIic_WriteReg(BaseAddress,  XIIC_RFD_REG_OFFSET,
			IIC_RX_FIFO_DEPTH - 1);

	/*
	 * Reset Tx Fifo.
	 */
	XIic_WriteReg(BaseAddress,  XIIC_CR_REG_OFFSET,
			XIIC_CR_TX_FIFO_RESET_MASK);

	/*
	 * Enable IIC Device, remove Tx Fifo reset & disable general call.
	 */
	XIic_WriteReg(BaseAddress, XIIC_CR_REG_OFFSET,
			XIIC_CR_ENABLE_DEVICE_MASK);

	/*
	 * Read status register and verify IIC Device is in initial state. Only
	 * the Tx Fifo and Rx Fifo empty bits should be set.
	 */
	Status = XIic_ReadReg(BaseAddress,  XIIC_SR_REG_OFFSET);
	if(Status == (XIIC_SR_RX_FIFO_EMPTY_MASK |
		XIIC_SR_TX_FIFO_EMPTY_MASK)) {
		return XST_SUCCESS;
	}

	return XST_FAILURE;
}
/** @} */
