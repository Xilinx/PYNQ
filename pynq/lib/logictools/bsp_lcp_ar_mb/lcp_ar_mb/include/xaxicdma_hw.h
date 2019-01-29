/******************************************************************************
*
* Copyright (C) 2010 - 2018 Xilinx, Inc.  All rights reserved.
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
 *  @file xaxicdma_hw.h
* @addtogroup axicdma_v4_5
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
 * 1.00a jz   04/08/10 First release
 * 2.02a srt  01/18/13 Added support for Key Hole feature (CR: 687217).
 * </pre>
 *
 *****************************************************************************/

#ifndef XAXICDMA_HW_H_    /* prevent circular inclusions */
#define XAXICDMA_HW_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "xil_types.h"
#include "xil_io.h"
#include "xparameters.h"

/************************** Constant Definitions *****************************/

/** @name Buffer Descriptor Alignment
 *  @{
 */
#define XAXICDMA_BD_MINIMUM_ALIGNMENT 0x40  /**< Minimum byte alignment
                                               requirement for descriptors to
                                               satisfy both hardware/software
                                               needs */
/*@}*/

/** @name Maximum transfer length
 *    This is determined by hardware
 * @{
 */
#define XAXICDMA_MAX_TRANSFER_LEN	0x7FFFFF  /**< Max length hw supports */
/*@}*/

/** @name Register offset definitions
 *   Register accesses are 32-bit.
 * @{
 */
#define XAXICDMA_CR_OFFSET	     0x00000000  /**< Control register */
#define XAXICDMA_SR_OFFSET	     0x00000004  /**< Status register */
#define XAXICDMA_CDESC_OFFSET        0x00000008  /**< Current descriptor
						    pointer */
#define XAXICDMA_CDESC_MSB_OFFSET    0x0000000C /**< Current descriptor pointer */
#define XAXICDMA_TDESC_OFFSET	     0x00000010  /**< Tail descriptor pointer */
#define XAXICDMA_TDESC_MSB_OFFSET    0x00000014  /**< Tail descriptor pointer */
#define XAXICDMA_SRCADDR_OFFSET	     0x00000018  /**< Source address register */
#define XAXICDMA_SRCADDR_MSB_OFFSET  0x0000001C /**< Source address register */
#define XAXICDMA_DSTADDR_OFFSET	     0x00000020  /**< Destination address
						register */
#define XAXICDMA_DSTADDR_MSB_OFFSET  0x00000024  /**< Destination address
						register */
#define XAXICDMA_BTT_OFFSET          0x00000028  /**< Bytes to transfer */
/*@}*/

/** @name Bitmasks of XAXICDMA_CR_OFFSET register
 * @{
 */
#define XAXICDMA_CR_RESET_MASK		0x00000004 /**< Reset DMA engine */
#define XAXICDMA_CR_SGMODE_MASK		0x00000008 /**< Scatter gather mode */
#define XAXICDMA_CR_KHOLE_RD_MASK	0x00000010 /**< Keyhole Read */
#define XAXICDMA_CR_KHOLE_WR_MASK	0x00000020 /**< Keyhole Write */
/*@}*/

/** @name Bitmasks of XAXICDMA_SR_OFFSET register
 * This register reports status of a DMA channel, including
 * idle state, errors, and interrupts
 * @{
 */
#define XAXICDMA_SR_IDLE_MASK         0x00000002  /**< DMA channel idle */
#define XAXICDMA_SR_SGINCLD_MASK      0x00000008  /**< Hybrid build */
#define XAXICDMA_SR_ERR_INTERNAL_MASK 0x00000010  /**< Datamover internal err */
#define XAXICDMA_BTT_OFFSET       0x00000028  /**< Bytes to transfer */
/*@}*/

/** @name Bitmasks of XAXICDMA_CR_OFFSET register
 * @{
 */
#define XAXICDMA_CR_RESET_MASK		0x00000004 /**< Reset DMA engine */
#define XAXICDMA_CR_SGMODE_MASK		0x00000008 /**< Scatter gather mode */
#define XAXICDMA_CR_KHOLE_RD_MASK	0x00000010 /**< Keyhole Read */
#define XAXICDMA_CR_KHOLE_WR_MASK	0x00000020 /**< Keyhole Write */
/*@}*/

/** @name Bitmasks of XAXICDMA_SR_OFFSET register
 * This register reports status of a DMA channel, including
 * idle state, errors, and interrupts
 * @{
 */
#define XAXICDMA_SR_IDLE_MASK         0x00000002  /**< DMA channel idle */
#define XAXICDMA_SR_SGINCLD_MASK      0x00000008  /**< Hybrid build */
#define XAXICDMA_SR_ERR_INTERNAL_MASK 0x00000010  /**< Datamover internal err */
#define XAXICDMA_SR_ERR_SLAVE_MASK    0x00000020  /**< Datamover slave err */
#define XAXICDMA_SR_ERR_DECODE_MASK   0x00000040  /**< Datamover decode err */
#define XAXICDMA_SR_ERR_SG_INT_MASK   0x00000100  /**< SG internal err */
#define XAXICDMA_SR_ERR_SG_SLV_MASK   0x00000200  /**< SG slave err */
#define XAXICDMA_SR_ERR_SG_DEC_MASK   0x00000400  /**< SG decode err */
#define XAXICDMA_SR_ERR_ALL_MASK      0x00000770  /**< All errors */
/*@}*/

/** @name Bitmask for descriptor
 * @{
 */
#define XAXICDMA_DESC_LSB_MASK	(0xFFFFFFC0U)	/**< LSB Address mask */
/*@}*/


/** @name Bitmask for interrupts
 * These masks are shared by XAXICDMA_CR_OFFSET register and
 * XAXICDMA_SR_OFFSET register
 * @{
 */
#define XAXICDMA_XR_IRQ_IOC_MASK	0x00001000 /**< Completion interrupt */
#define XAXICDMA_XR_IRQ_DELAY_MASK	0x00002000 /**< Delay interrupt */
#define XAXICDMA_XR_IRQ_ERROR_MASK	0x00004000 /**< Error interrupt */
#define XAXICDMA_XR_IRQ_ALL_MASK	0x00007000 /**< All interrupts */
#define XAXICDMA_XR_IRQ_SIMPLE_ALL_MASK	0x00005000 /**< All interrupts for
                                                        simple only mode */
/*@}*/

/** @name Bitmask and shift for delay counter and coalescing counter
 * These masks are shared by XAXICDMA_CR_OFFSET register and
 * XAXICDMA_SR_OFFSET register
 * @{
 */
#define XAXICDMA_XR_DELAY_MASK    0xFF000000 /**< Delay timeout counter */
#define XAXICDMA_XR_COALESCE_MASK 0x00FF0000 /**< Coalesce counter */

#define XAXICDMA_DELAY_SHIFT    24
#define XAXICDMA_COALESCE_SHIFT 16

#define XAXICDMA_DELAY_MAX     0xFF    /**< Maximum delay counter value */
#define XAXICDMA_COALESCE_MAX  0xFF    /**< Maximum coalescing counter value */
/*@}*/


/* Buffer Descriptor (BD) definitions
 */

/** @name Buffer Descriptor offsets
 *  The first 8 words are used by hardware.
 *  Cache operations are required for words used by hardware to enforce data
 *  consistency.
 *  All words after the 8th word are for software use only.
 *  @{
 */
#define XAXICDMA_BD_NDESC_OFFSET     0x00 /**< Next descriptor pointer */
#define XAXICDMA_BD_NDESC_MSB_OFFSET     0x04 /**< Next descriptor pointer */
#define XAXICDMA_BD_BUFSRC_OFFSET    0x08 /**< Buffer source address */
#define XAXICDMA_BD_BUFSRC_MSB_OFFSET    0x0C /**< Buffer source address */
#define XAXICDMA_BD_BUFDST_OFFSET    0x10 /**< Buffer destination address */
#define XAXICDMA_BD_BUFDST_MSB_OFFSET    0x14 /**< Buffer destination address */
#define XAXICDMA_BD_CTRL_LEN_OFFSET  0x18 /**< Control/buffer length */
#define XAXICDMA_BD_STS_OFFSET       0x1C /**< Status */
#define XAXICDMA_BD_PHYS_ADDR_OFFSET 0x20 /**< Physical address of the BD */
#define XAXICDMA_BD_PHYS_ADDR_MSB_OFFSET 0x24 /**< Physical address of the BD */
#define XAXICDMA_BD_ISLITE_OFFSET    0x28 /**< Lite mode hardware build? */
#define XAXICDMA_BD_HASDRE_OFFSET    0x2C /**< Support unaligned transfers? */
#define XAXICDMA_BD_WORDLEN_OFFSET   0x30 /**< Word length in bytes */
#define XAXICDMA_BD_MAX_LEN_OFFSET   0x34 /**< Word length in bytes */
#define XAXICDMA_BD_ADDRLEN_OFFSET   0x38 /**< Word length in bytes */

#define XAXICDMA_BD_START_CLEAR    8   /**< Offset to start clear */
#define XAXICDMA_BD_TO_CLEAR       24  /**< BD specific bytes to be cleared */
#define XAXICDMA_BD_NUM_WORDS      16U  /**< Total number of words for one BD*/
#define XAXICDMA_BD_HW_NUM_BYTES   32  /**< Number of bytes hw used */
/*@}*/


/** @name Bitmasks of XAXICDMA_BD_CTRL_OFFSET register
 *  @{
 */
#define XAXICDMA_BD_CTRL_LENGTH_MASK 0x007FFFFF /**< Requested len */
/*@}*/

/** @name Bitmasks of XAXICDMA_BD_STS_OFFSET register
 *  @{
 */
#define XAXICDMA_BD_STS_COMPLETE_MASK   0x80000000 /**< Completed */
#define XAXICDMA_BD_STS_DEC_ERR_MASK    0x40000000 /**< Decode error */
#define XAXICDMA_BD_STS_SLV_ERR_MASK    0x20000000 /**< Slave error */
#define XAXICDMA_BD_STS_INT_ERR_MASK    0x10000000 /**< Internal err */
#define XAXICDMA_BD_STS_ALL_ERR_MASK    0x70000000 /**< All errors */
#define XAXICDMA_BD_STS_ALL_MASK        0xF0000000 /**< All status bits */
/*@}*/

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

#define XAxiCdma_In32  Xil_In32
#define XAxiCdma_Out32 Xil_Out32

/*****************************************************************************/
/**
*
* Read a given register.
*
* @param    BaseAddress is the base virtual address of the device
* @param    RegOffset is the register offset to be read
*
* @return   The 32-bit value of the register
*
* @note
* C-style signature:
*    u32 XAxiCdma_ReadReg(u32 BaseAddress, u32 RegOffset)
*
******************************************************************************/
#define XAxiCdma_ReadReg(BaseAddress, RegOffset)             \
    XAxiCdma_In32((BaseAddress) + (u32)(RegOffset))

/*****************************************************************************/
/**
*
* Write to a given register.
*
* @param    BaseAddress is the base virtual address of the device
* @param    RegOffset is the register offset to be written
* @param    Data is the 32-bit value to write to the register
*
* @return   None.
*
* @note
* C-style signature:
*    void XAxiCdma_WriteReg(u32 BaseAddress, u32 RegOffset, u32 Data)
*
******************************************************************************/
#define XAxiCdma_WriteReg(BaseAddress, RegOffset, Data)          \
    XAxiCdma_Out32((BaseAddress) + (u32)(RegOffset), (u32)(Data))

#ifdef __cplusplus
}
#endif

#endif
/** @} */
