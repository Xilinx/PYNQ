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
* @file xiic_i.h
* @addtogroup iic_v3_1
* @{
*
* This header file contains internal identifiers, which are those shared
* between XIic components.  The identifiers in this file are not intended for
* use external to the driver.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.01a rfp  10/19/01 release
* 1.01c ecm  12/05/02 new rev
* 1.13a wgr  03/22/07 Converted to new coding style.
* 2.00a sdm  10/22/09 Converted all register accesses to 32 bit access.
*		      Removed the macro XIIC_CLEAR_STATS, user has to
*		      use the the XIic_ClearStats API in its place.
*		      Removed the macro XIic_mEnterCriticalRegion,
*		      XIic_IntrGlobalDisable should be used in its place.
*		      Removed the macro XIic_mExitCriticalRegion,
*		      XIic_IntrGlobalEnable should be used in its place.
*		      Removed the _m prefix from all the macros
*		      XIic_mSend10BitAddrByte1 is now XIic_Send10BitAddrByte1
*		      XIic_mSend10BitAddrByte2 is now XIic_Send10BitAddrByte2
*		      XIic_mSend7BitAddr is now XIic_Send7BitAddr
*		      XIic_mDisableIntr is now XIic_DisableIntr
*		      XIic_mEnableIntr is now XIic_EnableIntr
*		      XIic_mClearIntr is now XIic_ClearIntr
*		      XIic_mClearEnableIntr is now XIic_ClearEnableIntr
*		      XIic_mFlushRxFifo is now XIic_FlushRxFifo
*		      XIic_mFlushTxFifo is now XIic_FlushTxFifo
*		      XIic_mReadRecvByte is now XIic_ReadRecvByte
*		      XIic_mWriteSendByte is now XIic_WriteSendByte
*		      XIic_mSetControlRegister is now XIic_SetControlRegister
* 2.07a adk   18/04/13 Updated the code to avoid unused variable warnings when
*			  compiling with the -Wextra -Wall flags.
*			  Changes done in files xiic.c and xiic_i.h. CR:705001
*
* </pre>
*
******************************************************************************/

#ifndef XIIC_I_H		/* prevent circular inclusions */
#define XIIC_I_H		/* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xil_types.h"
#include "xil_assert.h"
#include "xstatus.h"
#include "xiic.h"

/************************** Constant Definitions *****************************/

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/******************************************************************************
*
* This macro sends the first byte of the address for a 10 bit address during
* both read and write operations. It takes care of the details to format the
* address correctly.
*
* address = 1111_0xxD   xx = address MSBits
*                        D = Tx direction = 0 = write
*
* @param	SlaveAddress contains the address of the slave to send to.
* @param	Operation indicates XIIC_READ_OPERATION or XIIC_WRITE_OPERATION
*
* @return	None.
*
* @note		Signature:
*		void XIic_Send10BitAddrByte1(u16 SlaveAddress, u8 Operation);
*
******************************************************************************/
#define XIic_Send10BitAddrByte1(SlaveAddress, Operation)		\
{									\
	u8 LocalAddr = (u8)((SlaveAddress) >> 7);			\
	LocalAddr = (LocalAddr & 0xF6) | 0xF0 | (Operation);		\
	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_DTR_REG_OFFSET,	\
			(u32) LocalAddr);				\
}

/******************************************************************************
*
* This macro sends the second byte of the address for a 10 bit address during
* both read and write operations. It takes care of the details to format the
* address correctly.
*
* @param	SlaveAddress contains the address of the slave to send to.
*
* @return	None.
*
* @note		Signature: void XIic_Send10BitAddrByte2(u16 SlaveAddress,
*				u8 Operation);
*
******************************************************************************/
#define XIic_Send10BitAddrByte2(SlaveAddress)				\
	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_DTR_REG_OFFSET,	\
			(u32)(SlaveAddress));				\

/******************************************************************************
*
* This macro sends the address for a 7 bit address during both read and write
* operations. It takes care of the details to format the address correctly.
*
* @param	SlaveAddress contains the address of the slave to send to.
* @param	Operation indicates XIIC_READ_OPERATION or XIIC_WRITE_OPERATION
*
* @return	None.
*
* @note		Signature:
*		void XIic_Send7BitAddr(u16 SlaveAddress, u8 Operation);
*
******************************************************************************/
#define XIic_Send7BitAddr(SlaveAddress, Operation)			\
{									\
	u8 LocalAddr = (u8)(SlaveAddress << 1);			\
	LocalAddr = (LocalAddr & 0xFE) | (Operation);			\
	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_DTR_REG_OFFSET,	\
			(u32) LocalAddr); 				\
}

/******************************************************************************
*
* This macro disables the specified interrupts in the Interrupt enable
* register.  It is non-destructive in that the register is read and only the
* interrupts specified is changed.
*
* @param	BaseAddress is the base address of the IIC device.
* @param	InterruptMask contains the interrupts to be disabled
*
* @return	None.
*
* @note		Signature:
*		void XIic_DisableIntr(u32 BaseAddress, u32 InterruptMask);
*
******************************************************************************/
#define XIic_DisableIntr(BaseAddress, InterruptMask)			\
	XIic_WriteIier((BaseAddress),					\
		XIic_ReadIier(BaseAddress) & ~(InterruptMask))

/******************************************************************************
*
* This macro enables the specified interrupts in the Interrupt enable
* register.  It is non-destructive in that the register is read and only the
* interrupts specified is changed.
*
* @param	BaseAddress is the base address of the IIC device.
* @param	InterruptMask contains the interrupts to be disabled
*
* @return	None.
*
* @note		Signature:
*		void XIic_EnableIntr(u32 BaseAddress, u32 InterruptMask);
*
******************************************************************************/
#define XIic_EnableIntr(BaseAddress, InterruptMask)			\
	XIic_WriteIier((BaseAddress),					\
		XIic_ReadIier(BaseAddress) | (InterruptMask))

/******************************************************************************
*
* This macro clears the specified interrupt in the Interrupt status
* register.  It is non-destructive in that the register is read and only the
* interrupt specified is cleared.  Clearing an interrupt acknowledges it.
*
* @param	BaseAddress is the base address of the IIC device.
* @param	InterruptMask contains the interrupts to be disabled
*
* @return	None.
*
* @note		Signature:
*		void XIic_ClearIntr(u32 BaseAddress, u32 InterruptMask);
*
******************************************************************************/
#define XIic_ClearIntr(BaseAddress, InterruptMask)			\
	XIic_WriteIisr((BaseAddress),					\
		XIic_ReadIisr(BaseAddress) & (InterruptMask))

/******************************************************************************
*
* This macro clears and enables the specified interrupt in the Interrupt
* status and enable registers.  It is non-destructive in that the registers are
* read and only the interrupt specified is modified.
* Clearing an interrupt acknowledges it.
*
* @param	BaseAddress is the base address of the IIC device.
* @param	InterruptMask contains the interrupts to be cleared and enabled
*
* @return	None.
*
* @note		Signature:
*		void XIic_ClearEnableIntr(u32 BaseAddress, u32 InterruptMask);
*
******************************************************************************/
#define XIic_ClearEnableIntr(BaseAddress, InterruptMask)		\
{									\
	XIic_WriteIisr(BaseAddress,					\
		(XIic_ReadIisr(BaseAddress) & (InterruptMask))); 	\
									\
	XIic_WriteIier(BaseAddress,					\
		(XIic_ReadIier(BaseAddress) | (InterruptMask)));	\
}

/******************************************************************************
*
* This macro flushes the receive FIFO such that all bytes contained within it
* are discarded.
*
* @param	InstancePtr is a pointer to the IIC instance containing the FIFO
*		to be flushed.
*
* @return	None.
*
* @note		Signature:
*		void XIic_FlushRxFifo(XIic *InstancePtr);
*
******************************************************************************/
#define XIic_FlushRxFifo(InstancePtr)					\
{									\
	int LoopCnt;							\
	u8 BytesToRead = XIic_ReadReg(InstancePtr->BaseAddress,	\
				XIIC_RFO_REG_OFFSET) + 1;		\
	for(LoopCnt = 0; LoopCnt < BytesToRead; LoopCnt++)		\
	{								\
		 XIic_ReadReg(InstancePtr->BaseAddress,	\
					  XIIC_DRR_REG_OFFSET);		\
	}								\
}

/******************************************************************************
*
* This macro flushes the transmit FIFO such that all bytes contained within it
* are discarded.
*
* @param	InstancePtr is a pointer to the IIC instance containing the FIFO
*		to be flushed.
*
* @return	None.
*
* @note		Signature:
*		void XIic_FlushTxFifo(XIic *InstancePtr);
*
******************************************************************************/
#define XIic_FlushTxFifo(InstancePtr);					\
{									\
	u32 CntlReg = XIic_ReadReg(InstancePtr->BaseAddress,		\
					XIIC_CR_REG_OFFSET);		\
	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,	\
			CntlReg | XIIC_CR_TX_FIFO_RESET_MASK);		\
	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_CR_REG_OFFSET,	\
			CntlReg);					\
}

/******************************************************************************
*
* This macro reads the next available received byte from the receive FIFO
* and updates all the data structures to reflect it.
*
* @param	InstancePtr is a pointer to the IIC instance to be operated on.
*
* @return	None.
*
* @note		Signature:
*		void XIic_ReadRecvByte(XIic *InstancePtr);
*
******************************************************************************/
#define XIic_ReadRecvByte(InstancePtr)					\
{									\
	*InstancePtr->RecvBufferPtr++ =					\
	XIic_ReadReg(InstancePtr->BaseAddress, XIIC_DRR_REG_OFFSET);	\
	InstancePtr->RecvByteCount--;					\
	InstancePtr->Stats.RecvBytes++;					\
}

/******************************************************************************
*
* This macro writes the next byte to be sent to the transmit FIFO
* and updates all the data structures to reflect it.
*
* @param	InstancePtr is a pointer to the IIC instance to be operated on.
*
* @return	None.
*
* @note		Signature:
*		void XIic_WriteSendByte(XIic *InstancePtr);
*
******************************************************************************/
#define XIic_WriteSendByte(InstancePtr)				\
{									\
	XIic_WriteReg(InstancePtr->BaseAddress, XIIC_DTR_REG_OFFSET,	\
		*InstancePtr->SendBufferPtr++);				\
	InstancePtr->SendByteCount--;					\
	InstancePtr->Stats.SendBytes++;					\
}

/******************************************************************************
*
* This macro sets up the control register for a master receive operation.
* A write is necessary if a 10 bit operation is being performed.
*
* @param	InstancePtr is a pointer to the IIC instance to be operated on.
* @param	ControlRegister contains the contents of the IIC device control
*		register
* @param	ByteCount contains the number of bytes to be received for the
*		master receive operation
*
* @return	None.
*
* @note		Signature:
*		void XIic_SetControlRegister(XIic *InstancePtr,
*						u8 ControlRegister,
*						int ByteCount);
*
******************************************************************************/
#define XIic_SetControlRegister(InstancePtr, ControlRegister, ByteCount)     \
{									      \
	(ControlRegister) &= ~(XIIC_CR_NO_ACK_MASK | XIIC_CR_DIR_IS_TX_MASK); \
	if (InstancePtr->Options & XII_SEND_10_BIT_OPTION) {		\
		(ControlRegister) |= XIIC_CR_DIR_IS_TX_MASK;		\
	} else {							\
		if ((ByteCount) == 1)					\
		{							\
			(ControlRegister) |= XIIC_CR_NO_ACK_MASK;	\
		}							\
	}								\
}

/************************** Function Prototypes ******************************/

extern XIic_Config XIic_ConfigTable[];

/* The following variables are shared across files of the driver and
 * are function pointers that are necessary to break dependencies allowing
 * optional parts of the driver to be used without condition compilation
 */
extern void (*XIic_AddrAsSlaveFuncPtr) (XIic *InstancePtr);
extern void (*XIic_NotAddrAsSlaveFuncPtr) (XIic *InstancePtr);
extern void (*XIic_RecvSlaveFuncPtr) (XIic *InstancePtr);
extern void (*XIic_SendSlaveFuncPtr) (XIic *InstancePtr);
extern void (*XIic_RecvMasterFuncPtr) (XIic *InstancePtr);
extern void (*XIic_SendMasterFuncPtr) (XIic *InstancePtr);
extern void (*XIic_ArbLostFuncPtr) (XIic *InstancePtr);
extern void (*XIic_BusNotBusyFuncPtr) (XIic *InstancePtr);

void XIic_TransmitFifoFill(XIic *InstancePtr, int Role);

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
/** @} */
