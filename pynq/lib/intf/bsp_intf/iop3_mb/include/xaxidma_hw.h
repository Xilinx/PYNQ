/******************************************************************************
*
* Copyright (C) 2010 - 2015 Xilinx, Inc.  All rights reserved.
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
 *  @file xaxidma_hw.h
* @addtogroup axidma_v9_0
* @{
 *
 * Hardware definition file. It defines the register interface and Buffer
 * Descriptor (BD) definitions.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- ---- -------- -------------------------------------------------------
 * 1.00a jz   05/18/10 First release
 * 2.00a jz   08/10/10 Second release, added in xaxidma_g.c, xaxidma_sinit.c,
 *                     updated tcl file, added xaxidma_porting_guide.h
 * 3.00a jz   11/22/10 Support IP core parameters change
 * 4.00a rkv  02/22/11 Added support for simple DMA mode
 * 6.00a srt  01/24/12 Added support for Multi-Channel DMA mode
 * 8.0   srt  01/29/14 Added support for Micro DMA Mode and Cyclic mode of
 *		       operations.
 *
 * </pre>
 *
 *****************************************************************************/

#ifndef XAXIDMA_HW_H_    /* prevent circular inclusions */
#define XAXIDMA_HW_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "xil_types.h"
#include "xil_io.h"

/************************** Constant Definitions *****************************/

/** @name DMA Transfer Direction
 *  @{
 */
#define XAXIDMA_DMA_TO_DEVICE		0x00
#define XAXIDMA_DEVICE_TO_DMA		0x01


/** @name Buffer Descriptor Alignment
 *  @{
 */
#define XAXIDMA_BD_MINIMUM_ALIGNMENT	0x40	/**< Minimum byte alignment
						requirement for descriptors to
						satisfy both hardware/software
						needs */
/*@}*/

/** @name Micro DMA Buffer Address Alignment
 *  @{
 */
#define XAXIDMA_MICROMODE_MIN_BUF_ALIGN	0xFFF	/**< Minimum byte alignment
						requirement for buffer address
						in Micro DMA mode */
/*@}*/

/** @name Maximum transfer length
 *	This is determined by hardware
 * @{
 */
#define XAXIDMA_MAX_TRANSFER_LEN	0x7FFFFF  /* Max length hw supports */
#define XAXIDMA_MCHAN_MAX_TRANSFER_LEN	0x00FFFF  /* Max length MCDMA
						     hw supports */
/*@}*/

/* Register offset definitions. Register accesses are 32-bit.
 */
/** @name Device registers
 *  Register sets on TX and RX channels are identical
 *  @{
 */
#define XAXIDMA_TX_OFFSET	0x00000000 /**< TX channel registers base
					     *  offset */
#define XAXIDMA_RX_OFFSET	0x00000030 /**< RX channel registers base
					     * offset */

/* This set of registers are applicable for both channels. Add
 * XAXIDMA_TX_OFFSET to get to TX channel, and XAXIDMA_RX_OFFSET to get to RX
 * channel
 */
#define XAXIDMA_CR_OFFSET	 0x00000000   /**< Channel control */
#define XAXIDMA_SR_OFFSET	 0x00000004   /**< Status */
#define XAXIDMA_CDESC_OFFSET	 0x00000008   /**< Current descriptor pointer */
#define XAXIDMA_CDESC_MSB_OFFSET 0x0000000C   /**< Current descriptor pointer */
#define XAXIDMA_TDESC_OFFSET	 0x00000010   /**< Tail descriptor pointer */
#define XAXIDMA_TDESC_MSB_OFFSET 0x00000014   /**< Tail descriptor pointer */
#define XAXIDMA_SRCADDR_OFFSET	 0x00000018   /**< Simple mode source address
						pointer */
#define XAXIDMA_SRCADDR_MSB_OFFSET	0x0000001C  /**< Simple mode source address
						pointer */
#define XAXIDMA_DESTADDR_OFFSET		0x00000018   /**< Simple mode destination address pointer */
#define XAXIDMA_DESTADDR_MSB_OFFSET	0x0000001C   /**< Simple mode destination address pointer */
#define XAXIDMA_BUFFLEN_OFFSET		0x00000028   /**< Tail descriptor pointer */
#define XAXIDMA_SGCTL_OFFSET		0x0000002c   /**< SG Control Register */

/** Multi-Channel DMA Descriptor Offsets **/
#define XAXIDMA_RX_CDESC0_OFFSET	0x00000040   /**< Rx Current Descriptor 0 */
#define XAXIDMA_RX_CDESC0_MSB_OFFSET	0x00000044   /**< Rx Current Descriptor 0 */
#define XAXIDMA_RX_TDESC0_OFFSET	0x00000048   /**< Rx Tail Descriptor 0 */
#define XAXIDMA_RX_TDESC0_MSB_OFFSET	0x0000004C   /**< Rx Tail Descriptor 0 */
#define XAXIDMA_RX_NDESC_OFFSET		0x00000020   /**< Rx Next Descriptor Offset */
/*@}*/

/** @name Bitmasks of XAXIDMA_CR_OFFSET register
 * @{
 */
#define XAXIDMA_CR_RUNSTOP_MASK	0x00000001 /**< Start/stop DMA channel */
#define XAXIDMA_CR_RESET_MASK	0x00000004 /**< Reset DMA engine */
#define XAXIDMA_CR_KEYHOLE_MASK	0x00000008 /**< Keyhole feature */
#define XAXIDMA_CR_CYCLIC_MASK	0x00000010 /**< Cyclic Mode */
/*@}*/

/** @name Bitmasks of XAXIDMA_SR_OFFSET register
 *
 * This register reports status of a DMA channel, including
 * run/stop/idle state, errors, and interrupts (note that interrupt
 * masks are shared with XAXIDMA_CR_OFFSET register, and are defined
 * in the _IRQ_ section.
 *
 * The interrupt coalescing threshold value and delay counter value are
 * also shared with XAXIDMA_CR_OFFSET register, and are defined in a
 * later section.
 * @{
 */
#define XAXIDMA_HALTED_MASK		0x00000001  /**< DMA channel halted */
#define XAXIDMA_IDLE_MASK		0x00000002  /**< DMA channel idle */
#define XAXIDMA_ERR_INTERNAL_MASK	0x00000010  /**< Datamover internal
						      *  err */
#define XAXIDMA_ERR_SLAVE_MASK		0x00000020  /**< Datamover slave err */
#define XAXIDMA_ERR_DECODE_MASK		0x00000040  /**< Datamover decode
						      *  err */
#define XAXIDMA_ERR_SG_INT_MASK		0x00000100  /**< SG internal err */
#define XAXIDMA_ERR_SG_SLV_MASK		0x00000200  /**< SG slave err */
#define XAXIDMA_ERR_SG_DEC_MASK		0x00000400  /**< SG decode err */
#define XAXIDMA_ERR_ALL_MASK		0x00000770  /**< All errors */

/** @name Bitmask for interrupts
 * These masks are shared by XAXIDMA_CR_OFFSET register and
 * XAXIDMA_SR_OFFSET register
 * @{
 */
#define XAXIDMA_IRQ_IOC_MASK		0x00001000 /**< Completion intr */
#define XAXIDMA_IRQ_DELAY_MASK		0x00002000 /**< Delay interrupt */
#define XAXIDMA_IRQ_ERROR_MASK		0x00004000 /**< Error interrupt */
#define XAXIDMA_IRQ_ALL_MASK		0x00007000 /**< All interrupts */
/*@}*/

/** @name Bitmask and shift for delay and coalesce
 * These masks are shared by XAXIDMA_CR_OFFSET register and
 * XAXIDMA_SR_OFFSET register
 * @{
 */
#define XAXIDMA_DELAY_MASK		0xFF000000 /**< Delay timeout
						     *  counter */
#define XAXIDMA_COALESCE_MASK		0x00FF0000 /**< Coalesce counter */

#define XAXIDMA_DELAY_SHIFT		24
#define XAXIDMA_COALESCE_SHIFT		16
/*@}*/


/* Buffer Descriptor (BD) definitions
 */

/** @name Buffer Descriptor offsets
 *  USR* fields are defined by higher level IP.
 *  setup for EMAC type devices. The first 13 words are used by hardware.
 *  All words after the 13rd word are for software use only.
 *  @{
 */
#define XAXIDMA_BD_NDESC_OFFSET		0x00  /**< Next descriptor pointer */
#define XAXIDMA_BD_NDESC_MSB_OFFSET	0x04  /**< Next descriptor pointer */
#define XAXIDMA_BD_BUFA_OFFSET		0x08  /**< Buffer address */
#define XAXIDMA_BD_BUFA_MSB_OFFSET	0x0C  /**< Buffer address */
#define XAXIDMA_BD_MCCTL_OFFSET		0x10  /**< Multichannel Control Fields */
#define XAXIDMA_BD_STRIDE_VSIZE_OFFSET	0x14  /**< 2D Transfer Sizes */
#define XAXIDMA_BD_CTRL_LEN_OFFSET	0x18  /**< Control/buffer length */
#define XAXIDMA_BD_STS_OFFSET		0x1C  /**< Status */

#define XAXIDMA_BD_USR0_OFFSET		0x20  /**< User IP specific word0 */
#define XAXIDMA_BD_USR1_OFFSET		0x24  /**< User IP specific word1 */
#define XAXIDMA_BD_USR2_OFFSET		0x28  /**< User IP specific word2 */
#define XAXIDMA_BD_USR3_OFFSET		0x2C  /**< User IP specific word3 */
#define XAXIDMA_BD_USR4_OFFSET		0x30  /**< User IP specific word4 */

#define XAXIDMA_BD_ID_OFFSET		0x34  /**< Sw ID */
#define XAXIDMA_BD_HAS_STSCNTRL_OFFSET	0x38  /**< Whether has stscntrl strm */
#define XAXIDMA_BD_HAS_DRE_OFFSET	0x3C  /**< Whether has DRE */
#define XAXIDMA_BD_ADDRLEN_OFFSET	0x40  /**< Check for BD Addr */

#define XAXIDMA_BD_HAS_DRE_MASK		0xF00 /**< Whether has DRE mask */
#define XAXIDMA_BD_WORDLEN_MASK		0xFF  /**< Whether has DRE mask */

#define XAXIDMA_BD_HAS_DRE_SHIFT	8     /**< Whether has DRE shift */
#define XAXIDMA_BD_WORDLEN_SHIFT	0     /**< Whether has DRE shift */

#define XAXIDMA_BD_START_CLEAR		8   /**< Offset to start clear */
#define XAXIDMA_BD_BYTES_TO_CLEAR	48  /**< BD specific bytes to be
					      *  cleared */

#define XAXIDMA_BD_NUM_WORDS		20U  /**< Total number of words for
					       * one BD*/
#define XAXIDMA_BD_HW_NUM_BYTES		52  /**< Number of bytes hw used */

/* The offset of the last app word.
 */
#define XAXIDMA_LAST_APPWORD		4

/*@}*/
#define XAXIDMA_DESC_LSB_MASK	(0xFFFFFFC0U)	/**< LSB Address mask */

/** @name Bitmasks of XAXIDMA_BD_CTRL_OFFSET register
 *  @{
 */
#define XAXIDMA_BD_CTRL_TXSOF_MASK	0x08000000 /**< First tx packet */
#define XAXIDMA_BD_CTRL_TXEOF_MASK	0x04000000 /**< Last tx packet */
#define XAXIDMA_BD_CTRL_ALL_MASK	0x0C000000 /**< All control bits */
/*@}*/

/** @name Bitmasks of XAXIDMA_BD_STS_OFFSET register
 *  @{
 */
#define XAXIDMA_BD_STS_COMPLETE_MASK	0x80000000 /**< Completed */
#define XAXIDMA_BD_STS_DEC_ERR_MASK	0x40000000 /**< Decode error */
#define XAXIDMA_BD_STS_SLV_ERR_MASK	0x20000000 /**< Slave error */
#define XAXIDMA_BD_STS_INT_ERR_MASK	0x10000000 /**< Internal err */
#define XAXIDMA_BD_STS_ALL_ERR_MASK	0x70000000 /**< All errors */
#define XAXIDMA_BD_STS_RXSOF_MASK	0x08000000 /**< First rx pkt */
#define XAXIDMA_BD_STS_RXEOF_MASK	0x04000000 /**< Last rx pkt */
#define XAXIDMA_BD_STS_ALL_MASK		0xFC000000 /**< All status bits */
/*@}*/

/** @name Bitmasks and shift values for XAXIDMA_BD_MCCTL_OFFSET register
 *  @{
 */
#define XAXIDMA_BD_TDEST_FIELD_MASK	0x0000000F
#define XAXIDMA_BD_TID_FIELD_MASK	0x00000F00
#define XAXIDMA_BD_TUSER_FIELD_MASK	0x000F0000
#define XAXIDMA_BD_ARCACHE_FIELD_MASK	0x0F000000
#define XAXIDMA_BD_ARUSER_FIELD_MASK	0xF0000000

#define XAXIDMA_BD_TDEST_FIELD_SHIFT	0
#define XAXIDMA_BD_TID_FIELD_SHIFT    	8
#define XAXIDMA_BD_TUSER_FIELD_SHIFT	16
#define XAXIDMA_BD_ARCACHE_FIELD_SHIFT	24
#define XAXIDMA_BD_ARUSER_FIELD_SHIFT	28

/** @name Bitmasks and shift values for XAXIDMA_BD_STRIDE_VSIZE_OFFSET register
 *  @{
 */
#define XAXIDMA_BD_STRIDE_FIELD_MASK	0x0000FFFF
#define XAXIDMA_BD_VSIZE_FIELD_MASK	0xFFF80000

#define XAXIDMA_BD_STRIDE_FIELD_SHIFT	0
#define XAXIDMA_BD_VSIZE_FIELD_SHIFT   	19

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

#define XAxiDma_In32	Xil_In32
#define XAxiDma_Out32	Xil_Out32

/*****************************************************************************/
/**
*
* Read the given register.
*
* @param	BaseAddress is the base address of the device
* @param	RegOffset is the register offset to be read
*
* @return	The 32-bit value of the register
*
* @note
*		C-style signature:
*		u32 XAxiDma_ReadReg(u32 BaseAddress, u32 RegOffset)
*
******************************************************************************/
#define XAxiDma_ReadReg(BaseAddress, RegOffset)             \
    XAxiDma_In32((BaseAddress) + (RegOffset))

/*****************************************************************************/
/**
*
* Write the given register.
*
* @param	BaseAddress is the base address of the device
* @param	RegOffset is the register offset to be written
* @param	Data is the 32-bit value to write to the register
*
* @return	None.
*
* @note
*		C-style signature:
*		void XAxiDma_WriteReg(u32 BaseAddress, u32 RegOffset, u32 Data)
*
******************************************************************************/
#define XAxiDma_WriteReg(BaseAddress, RegOffset, Data)          \
    XAxiDma_Out32((BaseAddress) + (RegOffset), (Data))

#ifdef __cplusplus
}
#endif

#endif
/** @} */
