/******************************************************************************
 *  Copyright (c) 2018, Xilinx, Inc.
 *  All rights reserved.
 * 
 *  Redistribution and use in source and binary forms, with or without 
 *  modification, are permitted provided that the following conditions are met:
 *
 *  1.  Redistributions of source code must retain the above copyright notice, 
 *     this list of conditions and the following disclaimer.
 *
 *  2.  Redistributions in binary form must reproduce the above copyright 
 *      notice, this list of conditions and the following disclaimer in the 
 *      documentation and/or other materials provided with the distribution.
 *
 *  3.  Neither the name of the copyright holder nor the names of its 
 *      contributors may be used to endorse or promote products derived from 
 *      this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 *  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
 *  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 *  OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 *  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
 *  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
 *  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *****************************************************************************/
/*****************************************************************************/
/**
*
* @file axidma.h
*
* This file overwrites some of the functions in xaxidma.c, with the major
* changes of disabling XAxiDma_BdRingStart() function. Also, it addes a ew
* function for disabling interrupts. 
* The data type is also modified to be consistent with Python data types.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00  yrq  01/25/2018  Refactor the function change out of the xaxidma code
* </pre>
*
******************************************************************************/

#ifndef _AXIDMA_H_   /* prevent circular inclusions */
#define _AXIDMA_H_

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/
#include "xaxidma_bdring.h"
#include <string.h>
#include "xil_cache.h"

/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/

/**
 * The XAxiDma driver instance data. An instance must be allocated for each DMA
 * engine in use.
 */
typedef struct XAxiDma {
	u32 RegBase;		/* Virtual base address of DMA engine */

	int HasMm2S;		/* Has transmit channel */
	int HasS2Mm;		/* Has receive channel */
	int Initialized;	/* Driver has been initialized */
	int HasSg;

	XAxiDma_BdRing TxBdRing;     /* BD container management for TX channel */
	XAxiDma_BdRing RxBdRing[16]; /* BD container management for RX channel */
	int TxNumChannels;
	int RxNumChannels;
	int MicroDmaMode;
	int AddrWidth;		  /**< Address Width */
} XAxiDma;

/**
 * The configuration structure for AXI DMA engine
 *
 * This structure passes the hardware building information to the driver
 */
typedef struct {
	u32 DeviceId;
	UINTPTR BaseAddr;

	int HasStsCntrlStrm;
	int HasMm2S;
	int HasMm2SDRE;
	int Mm2SDataWidth;
	int HasS2Mm;
	int HasS2MmDRE;
	int S2MmDataWidth;
	int HasSg;
	int Mm2sNumChannels;
	int S2MmNumChannels;
	int Mm2SBurstSize;
	int S2MmBurstSize;
	int MicroDmaMode;
	int AddrWidth;		  /**< Address Width */
} XAxiDma_Config;


/***************** Macros (Inline Functions) Definitions *********************/
/*****************************************************************************/
/**
* Get Transmit (Tx) Ring ptr
*
* Warning: This has a different API than the LLDMA driver. It now returns
* the pointer to the BD ring.
*
* @param	InstancePtr is a pointer to the DMA engine instance to be
*		worked on.
*
* @return	Pointer to the Tx Ring
*
* @note		C-style signature:
* 		XAxiDma_BdRing * XAxiDma_GetTxRing(XAxiDma * InstancePtr)
* 		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_GetTxRing(InstancePtr) \
			(&((InstancePtr)->TxBdRing))

/*****************************************************************************/
/**
* Get Receive (Rx) Ring ptr
*
* Warning: This has a different API than the LLDMA driver. It now returns
* the pointer to the BD ring.
*
* @param	InstancePtr is a pointer to the DMA engine instance to be
*		worked on.
*
* @return	Pointer to the Rx Ring
*
* @note
* 		C-style signature:
* 		XAxiDma_BdRing * XAxiDma_GetRxRing(XAxiDma * InstancePtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_GetRxRing(InstancePtr) \
			(&((InstancePtr)->RxBdRing[0]))

/*****************************************************************************/
/**
* Get Receive (Rx) Ring ptr of a Index
*
* Warning: This has a different API than the LLDMA driver. It now returns
* the pointer to the BD ring.
*
* @param	InstancePtr is a pointer to the DMA engine instance to be
*		worked on.
* @param	RingIndex is the channel Index.
*
* @return	Pointer to the Rx Ring
*
* @note
* 		C-style signature:
* 		XAxiDma_BdRing * XAxiDma_GetRxIndexRing(XAxiDma * InstancePtr,
						int RingIndex)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_GetRxIndexRing(InstancePtr, RingIndex) \
			(&((InstancePtr)->RxBdRing[RingIndex]))

/*****************************************************************************/
/**
* This function checks whether system is configured as Simple or
* Scatter Gather mode
*
* @param	InstancePtr is a pointer to the DMA engine instance to be
*		worked on.
*
* @return
*		- TRUE if configured as SG mode
*		- FALSE if configured as simple mode
*
* @note		None
*
*****************************************************************************/
#define XAxiDma_HasSg(InstancePtr)	((InstancePtr)->HasSg) ? TRUE : FALSE

/*****************************************************************************/
/**
 * This function enables interrupts specified by the Mask in specified
 * direction, Interrupts that are not in the mask are not affected.
 *
 * @param	InstancePtr is the driver instance we are working on
 * @param	Mask is the mask for the interrupts to be enabled
 * @param	Direction is DMA transfer direction, valid values are
 *			- XAXIDMA_DMA_TO_DEVICE.
 *			- XAXIDMA_DEVICE_TO_DMA.
 * @return	None
 *
 * @note	None
 *
 *****************************************************************************/
#define  XAxiDma_IntrEnable(InstancePtr, Mask, Direction) 	\
	XAxiDma_WriteReg((InstancePtr)->RegBase + \
			(XAXIDMA_RX_OFFSET * Direction), XAXIDMA_CR_OFFSET, \
			(XAxiDma_ReadReg((InstancePtr)->RegBase + \
			(XAXIDMA_RX_OFFSET * Direction), XAXIDMA_CR_OFFSET)) \
			| (Mask & XAXIDMA_IRQ_ALL_MASK))


/*****************************************************************************/
/**
 * This function gets the mask for the interrupts that are currently enabled
 *
 * @param	InstancePtr is the driver instance we are working on
 * @param	Direction is DMA transfer direction, valid values are
 *			- XAXIDMA_DMA_TO_DEVICE.
 *			- XAXIDMA_DEVICE_TO_DMA.
 *
 * @return	The bit mask for the interrupts that are currently enabled
 *
 * @note	None
 *
 *****************************************************************************/
#define   XAxiDma_IntrGetEnabled(InstancePtr, Direction)	\
			XAxiDma_ReadReg((InstancePtr)->RegBase + \
			(XAXIDMA_RX_OFFSET * Direction), XAXIDMA_CR_OFFSET) &\
							XAXIDMA_IRQ_ALL_MASK)



/*****************************************************************************/
/**
 * This function disables interrupts specified by the Mask. Interrupts that
 * are not in the mask are not affected.
 *
 * @param	InstancePtr is the driver instance we are working on
 * @param	Mask is the mask for the interrupts to be disabled
 * @param	Direction is DMA transfer direction, valid values are
 *			- XAXIDMA_DMA_TO_DEVICE.
 *			- XAXIDMA_DEVICE_TO_DMA.
 * @return	None
 *
 * @note	None
 *
 *****************************************************************************/
 #define XAxiDma_IntrDisable(InstancePtr, Mask, Direction)	\
		XAxiDma_WriteReg((InstancePtr)->RegBase + \
			(XAXIDMA_RX_OFFSET * Direction), XAXIDMA_CR_OFFSET, \
			(XAxiDma_ReadReg((InstancePtr)->RegBase + \
			(XAXIDMA_RX_OFFSET * Direction), XAXIDMA_CR_OFFSET)) \
			& ~(Mask & XAXIDMA_IRQ_ALL_MASK))


/*****************************************************************************/
/**
 * This function gets the interrupts that are asserted.
 *
 * @param	InstancePtr is the driver instance we are working on
 * @param	Direction is DMA transfer direction, valid values are
 *			- XAXIDMA_DMA_TO_DEVICE.
 *			- XAXIDMA_DEVICE_TO_DMA.
 *
 * @return	The bit mask for the interrupts asserted.
 *
 * @note	None
 *
 *****************************************************************************/
#define  XAxiDma_IntrGetIrq(InstancePtr, Direction)	\
			(XAxiDma_ReadReg((InstancePtr)->RegBase + \
			(XAXIDMA_RX_OFFSET * Direction), XAXIDMA_SR_OFFSET) &\
							XAXIDMA_IRQ_ALL_MASK)

/*****************************************************************************/
/**
 * This function acknowledges the interrupts that are specified in Mask
 *
 * @param	InstancePtr is the driver instance we are working on
 * @param	Mask is the mask for the interrupts to be acknowledge
 * @param	Direction is DMA transfer direction, valid values are
 *			- XAXIDMA_DMA_TO_DEVICE.
 *			- XAXIDMA_DEVICE_TO_DMA.
 *
 * @return	None
 *
 * @note	None.
 *
 *****************************************************************************/
#define  XAxiDma_IntrAckIrq(InstancePtr, Mask, Direction)	\
			XAxiDma_WriteReg((InstancePtr)->RegBase + \
			(XAXIDMA_RX_OFFSET * Direction), XAXIDMA_SR_OFFSET, \
			(Mask) & XAXIDMA_IRQ_ALL_MASK)



/************************** Function Prototypes ******************************/

/*
 * Initialization and control functions in axidma.c
 */
XAxiDma_Config *XAxiDma_LookupConfig(u32 DeviceId);
XAxiDma_Config *XAxiDma_LookupConfigBaseAddr(u32 Baseaddr);
/*
 * Modified functions in axidma.c
 */
int AxiDma_CfgInitialize(XAxiDma * InstancePtr, XAxiDma_Config *Config);
void AxiDma_Reset(XAxiDma * InstancePtr);
int AxiDma_ResetIsDone(XAxiDma * InstancePtr);
int AxiDma_Pause(XAxiDma * InstancePtr);
int AxiDma_Resume(XAxiDma * InstancePtr);
u32 AxiDma_Busy(XAxiDma *InstancePtr,int Direction);
u32 AxiDma_SimpleTransfer(XAxiDma *InstancePtr, UINTPTR BuffAddr, u32 Length,
	int Direction);
int AxiDma_SelectKeyHole(XAxiDma *InstancePtr, int Direction, int Select);
int AxiDma_SelectCyclicMode(XAxiDma *InstancePtr, int Direction, int Select);
int AxiDma_Selftest(XAxiDma * InstancePtr);
/*
 * New functions added in axidma.c
 */
void AxiDma_DisableInterruptsAll(XAxiDma * InstancePtr);

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
