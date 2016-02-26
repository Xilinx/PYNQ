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
/****************************************************************************/
/**
*
* @file xiic_l.h
* @addtogroup iic_v3_1
* @{
*
* This header file contains identifiers and driver functions (or
* macros) that can be used to access the device in normal and dynamic
* controller mode.  High-level driver functions are defined in xiic.h.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00b jhl  05/07/02 First release
* 1.01c ecm  12/05/02 new rev
* 1.01d jhl  10/08/03 Added general purpose output feature
* 1.02a mta  03/09/06 Implemented Repeated Start in the Low Level Driver.
* 1.03a mta  04/04/06 Implemented Dynamic IIC core routines.
* 1.03a rpm  09/08/06 Added include of xstatus.h for completeness
* 1.13a wgr  03/22/07 Converted to new coding style.
* 1.16a ktn  07/18/09 Updated the notes in XIIC_RESET macro to clearly indicate
*                     that only the Interrupt Registers are reset.
* 1.16a ktn  10/16/09 Updated the notes in the XIIC_RESET macro to mention
*                     that the complete IIC core is Reset on giving a software
*                     reset to the IIC core. Some previous versions of the
*                     core only reset the Interrupt Logic/Registers, please
*                     refer to the HW specification for futher details.
* 2.00a sdm  10/22/09 Converted all register accesses to 32 bit access,
*		      the register offsets are defined to be on 32 bit boundry.
*		      Removed the macro XIIC_RESET, XIic_Reset API should be
*		      used in its place.
*		      Some of the macros have been renamed to be consistent -
*		      XIIC_GINTR_DISABLE is renamed as XIic_IntrGlobalDisable,
*		      XIIC_GINTR_ENABLE is renamed as XIic_IntrGlobalEnable,
*		      XIIC_IS_GINTR_ENABLED is renamed as
*		      XIic_IsIntrGlobalEnabled,
*		      XIIC_WRITE_IISR is renamed as XIic_WriteIisr,
*		      XIIC_READ_IISR is renamed as XIic_ReadIisr,
*		      XIIC_WRITE_IIER is renamed as XIic_WriteIier
*		      The _m prefix in the name of the macros has been removed -
*		      XIic_mClearIisr is now XIic_ClearIisr,
*		      XIic_mSend7BitAddress is now XIic_Send7BitAddress,
*		      XIic_mDynSend7BitAddress is now XIic_DynSend7BitAddress,
*		      XIic_mDynSendStartStopAddress is now
*		      XIic_DynSendStartStopAddress,
*		      XIic_mDynSendStop is now XIic_DynSendStop.
*
*
* </pre>
*
*****************************************************************************/
#ifndef XIIC_L_H		/* prevent circular inclusions */
#define XIIC_L_H		/* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files ********************************/

#include "xil_types.h"
#include "xil_assert.h"
#include "xstatus.h"
#include "xil_io.h"

/************************** Constant Definitions ****************************/

/** @name Register Map
 *
 * Register offsets for the XIic device.
 * @{
 */
#define XIIC_DGIER_OFFSET	0x1C  /**< Global Interrupt Enable Register */
#define XIIC_IISR_OFFSET	0x20  /**< Interrupt Status Register */
#define XIIC_IIER_OFFSET	0x28  /**< Interrupt Enable Register */
#define XIIC_RESETR_OFFSET	0x40  /**< Reset Register */
#define XIIC_CR_REG_OFFSET	0x100 /**< Control Register */
#define XIIC_SR_REG_OFFSET	0x104 /**< Status Register */
#define XIIC_DTR_REG_OFFSET	0x108 /**< Data Tx Register */
#define XIIC_DRR_REG_OFFSET	0x10C /**< Data Rx Register */
#define XIIC_ADR_REG_OFFSET	0x110 /**< Address Register */
#define XIIC_TFO_REG_OFFSET	0x114 /**< Tx FIFO Occupancy */
#define XIIC_RFO_REG_OFFSET	0x118 /**< Rx FIFO Occupancy */
#define XIIC_TBA_REG_OFFSET	0x11C /**< 10 Bit Address reg */
#define XIIC_RFD_REG_OFFSET	0x120 /**< Rx FIFO Depth reg */
#define XIIC_GPO_REG_OFFSET	0x124 /**< Output Register */
/* @} */


/**
 * @name Device Global Interrupt Enable Register masks (CR) mask(s)
 * @{
 */
#define XIIC_GINTR_ENABLE_MASK	0x80000000 /**< Global Interrupt Enable Mask */
/* @} */

/** @name IIC Device Interrupt Status/Enable (INTR) Register Masks
 *
 * <b> Interrupt Status Register (IISR) </b>
 *
 * This register holds the interrupt status flags for the Spi device.
 *
 * <b> Interrupt Enable Register (IIER) </b>
 *
 * This register is used to enable interrupt sources for the IIC device.
 * Writing a '1' to a bit in this register enables the corresponding Interrupt.
 * Writing a '0' to a bit in this register disables the corresponding Interrupt.
 *
 * IISR/IIER registers have the same bit definitions and are only defined once.
 * @{
 */
#define XIIC_INTR_ARB_LOST_MASK	0x00000001 /**< 1 = Arbitration lost */
#define XIIC_INTR_TX_ERROR_MASK	0x00000002 /**< 1 = Tx error/msg complete */
#define XIIC_INTR_TX_EMPTY_MASK	0x00000004 /**< 1 = Tx FIFO/reg empty */
#define XIIC_INTR_RX_FULL_MASK	0x00000008 /**< 1 = Rx FIFO/reg=OCY level */
#define XIIC_INTR_BNB_MASK	0x00000010 /**< 1 = Bus not busy */
#define XIIC_INTR_AAS_MASK	0x00000020 /**< 1 = When addr as slave */
#define XIIC_INTR_NAAS_MASK	0x00000040 /**< 1 = Not addr as slave */
#define XIIC_INTR_TX_HALF_MASK	0x00000080 /**< 1 = Tx FIFO half empty */

/**
 * All Tx interrupts commonly used.
 */
#define XIIC_TX_INTERRUPTS	(XIIC_INTR_TX_ERROR_MASK | \
				 XIIC_INTR_TX_EMPTY_MASK |  \
				 XIIC_INTR_TX_HALF_MASK)

/**
 * All interrupts commonly used
 */
#define XIIC_TX_RX_INTERRUPTS	(XIIC_INTR_RX_FULL_MASK | XIIC_TX_INTERRUPTS)

/* @} */

/**
 * @name Reset Register mask
 * @{
 */
#define XIIC_RESET_MASK		0x0000000A /**< RESET Mask  */
/* @} */


/**
 * @name Control Register masks (CR) mask(s)
 * @{
 */
#define XIIC_CR_ENABLE_DEVICE_MASK	0x00000001 /**< Device enable = 1 */
#define XIIC_CR_TX_FIFO_RESET_MASK	0x00000002 /**< Transmit FIFO reset=1 */
#define XIIC_CR_MSMS_MASK		0x00000004 /**< Master starts Txing=1 */
#define XIIC_CR_DIR_IS_TX_MASK		0x00000008 /**< Dir of Tx. Txing=1 */
#define XIIC_CR_NO_ACK_MASK		0x00000010 /**< Tx Ack. NO ack = 1 */
#define XIIC_CR_REPEATED_START_MASK	0x00000020 /**< Repeated start = 1 */
#define XIIC_CR_GENERAL_CALL_MASK	0x00000040 /**< Gen Call enabled = 1 */
/* @} */

/**
 * @name Status Register masks (SR) mask(s)
 * @{
 */
#define XIIC_SR_GEN_CALL_MASK		0x00000001 /**< 1 = A Master issued
						    * a GC */
#define XIIC_SR_ADDR_AS_SLAVE_MASK	0x00000002 /**< 1 = When addressed as
						    * slave */
#define XIIC_SR_BUS_BUSY_MASK		0x00000004 /**< 1 = Bus is busy */
#define XIIC_SR_MSTR_RDING_SLAVE_MASK	0x00000008 /**< 1 = Dir: Master <--
						    * slave */
#define XIIC_SR_TX_FIFO_FULL_MASK	0x00000010 /**< 1 = Tx FIFO full */
#define XIIC_SR_RX_FIFO_FULL_MASK	0x00000020 /**< 1 = Rx FIFO full */
#define XIIC_SR_RX_FIFO_EMPTY_MASK	0x00000040 /**< 1 = Rx FIFO empty */
#define XIIC_SR_TX_FIFO_EMPTY_MASK	0x00000080 /**< 1 = Tx FIFO empty */
/* @} */

/**
 * @name Data Tx Register (DTR) mask(s)
 * @{
 */
#define XIIC_TX_DYN_START_MASK		0x00000100 /**< 1 = Set dynamic start */
#define XIIC_TX_DYN_STOP_MASK		0x00000200 /**< 1 = Set dynamic stop */
#define IIC_TX_FIFO_DEPTH		16     /**< Tx fifo capacity */
/* @} */

/**
 * @name Data Rx Register (DRR) mask(s)
 * @{
 */
#define IIC_RX_FIFO_DEPTH		16	/**< Rx fifo capacity */
/* @} */


#define XIIC_TX_ADDR_SENT		0x00
#define XIIC_TX_ADDR_MSTR_RECV_MASK	0x02


/**
 * The following constants are used to specify whether to do
 * Read or a Write operation on IIC bus.
 */
#define XIIC_READ_OPERATION	1 /**< Read operation on the IIC bus */
#define XIIC_WRITE_OPERATION	0 /**< Write operation on the IIC bus */

/**
 * The following constants are used with the transmit FIFO fill function to
 * specify the role which the IIC device is acting as, a master or a slave.
 */
#define XIIC_MASTER_ROLE	1 /**< Master on the IIC bus */
#define XIIC_SLAVE_ROLE		0 /**< Slave on the IIC bus */

/**
 * The following constants are used with Transmit Function (XIic_Send) to
 * specify whether to STOP after the current transfer of data or own the bus
 * with a Repeated start.
 */
#define XIIC_STOP		0x00 /**< Send a stop on the IIC bus after
					* the current data transfer */
#define XIIC_REPEATED_START	0x01 /**< Donot Send a stop on the IIC bus after
					* the current data transfer */

/***************** Macros (Inline Functions) Definitions *********************/

#define XIic_In32 	Xil_In32
#define XIic_Out32 	Xil_Out32

/****************************************************************************/
/**
*
* Read from the specified IIC device register.
*
* @param	BaseAddress is the base address of the device.
* @param	RegOffset is the offset from the 1st register of the device to
*		select the specific register.
*
* @return	The value read from the register.
*
* @note		C-Style signature:
*		u32 XIic_ReadReg(u32 BaseAddress, u32 RegOffset);
*
* 		This macro does not do any checking to ensure that the
*		register exists if the register may be excluded due to
*		parameterization, such as the GPO Register.
*
******************************************************************************/
#define XIic_ReadReg(BaseAddress, RegOffset) \
	XIic_In32((BaseAddress) + (RegOffset))

/***************************************************************************/
/**
*
* Write to the specified IIC device register.
*
* @param	BaseAddress is the base address of the device.
* @param	RegOffset is the offset from the 1st register of the
*		device to select the specific register.
* @param	RegisterValue is the value to be written to the register.
*
* @return	None.
*
* @note		C-Style signature:
*		void XIic_WriteReg(u32 BaseAddress, u32 RegOffset,
*					u32 RegisterValue);
* 		This macro does not do any checking to ensure that the
*		register exists if the register may be excluded due to
*		parameterization, such as the GPO Register.
*
******************************************************************************/
#define XIic_WriteReg(BaseAddress, RegOffset, RegisterValue) \
	XIic_Out32((BaseAddress) + (RegOffset), (RegisterValue))

/******************************************************************************/
/**
*
* This macro disables all interrupts for the device by writing to the Global
* interrupt enable register.
*
* @param	BaseAddress is the base address of the IIC device.
*
* @return	None.
*
* @note		C-Style signature:
*		void XIic_IntrGlobalDisable(u32 BaseAddress);
*
******************************************************************************/
#define XIic_IntrGlobalDisable(BaseAddress)				\
	XIic_WriteReg((BaseAddress), XIIC_DGIER_OFFSET, 0)

/******************************************************************************/
/**
*
* This macro writes to the global interrupt enable register to enable
* interrupts from the device. This function does not enable individual
* interrupts as the Interrupt Enable Register must be set appropriately.
*
* @param	BaseAddress is the base address of the IIC device.
*
* @return	None.
*
* @note		C-Style signature:
*		void XIic_IntrGlobalEnable(u32 BaseAddress);
*
******************************************************************************/
#define XIic_IntrGlobalEnable(BaseAddress)				\
	XIic_WriteReg((BaseAddress), XIIC_DGIER_OFFSET, 		\
		XIIC_GINTR_ENABLE_MASK)

/******************************************************************************/
/**
*
* This function determines if interrupts are enabled at the global level by
* reading the global interrupt register.
*
* @param	BaseAddress is the base address of the IIC device.
*
* @return
*		- TRUE if the global interrupt is enabled.
*		- FALSE if global interrupt is disabled.
*
* @note		C-Style signature:
*		int XIic_IsIntrGlobalEnabled(u32 BaseAddress);
*
******************************************************************************/
#define XIic_IsIntrGlobalEnabled(BaseAddress)			\
	(XIic_ReadReg((BaseAddress), XIIC_DGIER_OFFSET) ==		\
		XIIC_GINTR_ENABLE_MASK)

/******************************************************************************/
/**
*
* This function sets the Interrupt status register to the specified value.
*
* This register implements a toggle on write functionality. The interrupt is
* cleared by writing to this register with the bits to be cleared set to a one
* and all others to zero. Setting a bit which is zero within this register
* causes an interrupt to be generated.
*
* This function writes only the specified value to the register such that
* some status bits may be set and others cleared.  It is the caller's
* responsibility to get the value of the register prior to setting the value
* to prevent an destructive behavior.
*
* @param	BaseAddress is the base address of the IIC device.
* @param	Status is the value to be written to the Interrupt
*		status register.
*
* @return	None.
*
* @note		C-Style signature:
*		void XIic_WriteIisr(u32 BaseAddress, u32 Status);
*
******************************************************************************/
#define XIic_WriteIisr(BaseAddress, Status)	\
	XIic_WriteReg((BaseAddress), XIIC_IISR_OFFSET, (Status))

/******************************************************************************/
/**
*
* This function gets the contents of the Interrupt Status Register.
* This register indicates the status of interrupt sources for the device.
* The status is independent of whether interrupts are enabled such
* that the status register may also be polled when interrupts are not enabled.
*
* @param	BaseAddress is the base address of the IIC device.
*
* @return	The value read from the Interrupt Status Register.
*
* @note		C-Style signature:
*		u32 XIic_ReadIisr(u32 BaseAddress);
*
******************************************************************************/
#define XIic_ReadIisr(BaseAddress) 					\
	XIic_ReadReg((BaseAddress), XIIC_IISR_OFFSET)

/******************************************************************************/
/**
*
* This function sets the contents of the Interrupt Enable Register.
*
* This function writes only the specified value to the register such that
* some interrupt sources may be enabled and others disabled.  It is the
* caller's responsibility to get the value of the interrupt enable register
* prior to setting the value to prevent a destructive behavior.
*
* @param	BaseAddress is the base address of the IIC device.
* @param	Enable is the value to be written to the Interrupt Enable
*		Register. Bit positions of 1 will be enabled. Bit positions of 0
*		will be disabled.
*
* @return 	None
*
* @note		C-Style signature:
*		void XIic_WriteIier(u32 BaseAddress, u32 Enable);
*
******************************************************************************/
#define XIic_WriteIier(BaseAddress, Enable)				\
	XIic_WriteReg((BaseAddress), XIIC_IIER_OFFSET, (Enable))

/******************************************************************************/
/**
*
*
* This function gets the Interrupt Enable Register contents.
*
* @param	BaseAddress is the base address of the IIC device.
*
* @return	The contents read from the Interrupt Enable Register.
*		Bit positions of 1 indicate that the corresponding interrupt
*		is enabled. Bit positions of 0 indicate that the corresponding
*		interrupt is disabled.
*
* @note		C-Style signature:
*		u32 XIic_ReadIier(u32 BaseAddress)
*
******************************************************************************/
#define XIic_ReadIier(BaseAddress)					\
	XIic_ReadReg((BaseAddress), XIIC_IIER_OFFSET)

/******************************************************************************/
/**
*
* This macro clears the specified interrupt in the Interrupt status
* register.  It is non-destructive in that the register is read and only the
* interrupt specified is cleared.  Clearing an interrupt acknowledges it.
*
* @param	BaseAddress is the base address of the IIC device.
* @param	InterruptMask is the bit mask of the interrupts to be cleared.
*
* @return	None.
*
* @note		C-Style signature:
*		void XIic_ClearIisr(u32 BaseAddress, u32 InterruptMask);
*
******************************************************************************/
#define XIic_ClearIisr(BaseAddress, InterruptMask)		\
	XIic_WriteIisr((BaseAddress),			\
	XIic_ReadIisr(BaseAddress) & (InterruptMask))

/******************************************************************************/
/**
*
* This macro sends the address for a 7 bit address during both read and write
* operations. It takes care of the details to format the address correctly.
* This macro is designed to be called internally to the drivers.
*
* @param	BaseAddress is the base address of the IIC Device.
* @param	SlaveAddress is the address of the slave to send to.
* @param	Operation indicates XIIC_READ_OPERATION or XIIC_WRITE_OPERATION
*
* @return	None.
*
* @note		C-Style signature:
*		void XIic_Send7BitAddress(u32 BaseAddress, u8 SlaveAddress,
*						u8 Operation);
*
******************************************************************************/
#define XIic_Send7BitAddress(BaseAddress, SlaveAddress, Operation)	\
{									\
	u8 LocalAddr = (u8)(SlaveAddress << 1);				\
	LocalAddr = (LocalAddr & 0xFE) | (Operation);			\
	XIic_WriteReg(BaseAddress, XIIC_DTR_REG_OFFSET, LocalAddr);	\
}

/******************************************************************************/
/**
*
* This macro sends the address for a 7 bit address during both read and write
* operations. It takes care of the details to format the address correctly.
* This macro is designed to be called internally to the drivers for Dynamic
* controller functionality.
*
* @param	BaseAddress is the base address of the IIC Device.
* @param	SlaveAddress is the address of the slave to send to.
* @param	Operation indicates XIIC_READ_OPERATION or XIIC_WRITE_OPERATION.
*
* @return	None.
*
* @note		C-Style signature:
* 		void XIic_DynSend7BitAddress(u32 BaseAddress,
*				u8 SlaveAddress, u8 Operation);
*
******************************************************************************/
#define XIic_DynSend7BitAddress(BaseAddress, SlaveAddress, Operation)	\
{									\
	u8 LocalAddr = (u8)(SlaveAddress << 1);				\
	LocalAddr = (LocalAddr & 0xFE) | (Operation);			\
	XIic_WriteReg(BaseAddress, XIIC_DTR_REG_OFFSET,		\
			XIIC_TX_DYN_START_MASK | LocalAddr);		\
}

/******************************************************************************/
/**
*
* This macro sends the address, start and stop for a 7 bit address during both
* write operations. It takes care of the details to format the address
* correctly. This macro is designed to be called internally to the drivers.
*
* @param	BaseAddress is the base address of the IIC Device.
* @param	SlaveAddress is the address of the slave to send to.
* @param	Operation indicates XIIC_WRITE_OPERATION.
*
* @return	None.
*
* @note		C-Style signature:
* 		void XIic_DynSendStartStopAddress(u32 BaseAddress,
*							u8 SlaveAddress,
*							u8 Operation);
*
******************************************************************************/
#define XIic_DynSendStartStopAddress(BaseAddress, SlaveAddress, Operation) \
{									 \
	u8 LocalAddr = (u8)(SlaveAddress << 1);				 \
	LocalAddr = (LocalAddr & 0xFE) | (Operation);			 \
	XIic_WriteReg(BaseAddress, XIIC_DTR_REG_OFFSET,		 \
			XIIC_TX_DYN_START_MASK | XIIC_TX_DYN_STOP_MASK | \
			LocalAddr);					 \
}

/******************************************************************************/
/**
*
* This macro sends a stop condition on IIC bus for Dynamic logic.
*
* @param	BaseAddress is the base address of the IIC Device.
* @param	ByteCount is the number of Rx bytes received before the master.
*		doesn't respond with ACK.
*
* @return	None.
*
* @note		C-Style signature:
* 		void XIic_DynSendStop(u32 BaseAddress, u32 ByteCount);
*
******************************************************************************/
#define XIic_DynSendStop(BaseAddress, ByteCount)			\
{									\
	XIic_WriteReg(BaseAddress, XIIC_DTR_REG_OFFSET,		\
			XIIC_TX_DYN_STOP_MASK | ByteCount); 		\
}

/************************** Function Prototypes *****************************/

unsigned XIic_Recv(u32 BaseAddress, u8 Address,
		   u8 *BufferPtr, unsigned ByteCount, u8 Option);

unsigned XIic_Send(u32 BaseAddress, u8 Address,
		   u8 *BufferPtr, unsigned ByteCount, u8 Option);

unsigned XIic_DynRecv(u32 BaseAddress, u8 Address, u8 *BufferPtr, u8 ByteCount);

unsigned XIic_DynSend(u32 BaseAddress, u16 Address, u8 *BufferPtr,
		      u8 ByteCount, u8 Option);

int XIic_DynInit(u32 BaseAddress);


#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
/** @} */
