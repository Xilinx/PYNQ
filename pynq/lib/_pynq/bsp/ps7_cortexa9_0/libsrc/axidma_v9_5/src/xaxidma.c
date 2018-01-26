/******************************************************************************
*
* Copyright (C) 2010 - 2017 Xilinx, Inc.  All rights reserved.
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
* @file xaxidma.c
* @addtogroup axidma_v9_4
* @{
*
* This file implements DMA engine-wise initialization and control functions.
* For more information on the implementation of this driver, see xaxidma.h.
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
*		      New API added for simple DMA mode are
*			- XAxiDma_Busy
*			- XAxiDma_SimpleTransfer
* 6.00a srt  01/24/12 Added support for Multi-Channel DMA mode.
*		      - Changed APIs:
*			* XAxiDma_Start(XAxiDma * InstancePtr, int RingIndex)
*			* XAxiDma_Started(XAxiDma * InstancePtr, int RingIndex)
*			* XAxiDma_Pause(XAxiDma * InstancePtr, int RingIndex)
*			* XAxiDma_Resume(XAxiDma * InstancePtr, int RingIndex)
*			* XAxiDma_SimpleTransfer(XAxiDma *InstancePtr,
*        					u32 BuffAddr, u32 Length,
*						int Direction, int RingIndex)
*		      - New API:
*			* XAxiDma_SelectKeyHole(XAxiDma *InstancePtr,
*						int Direction, int Select)
* 7.00a srt  06/18/12  All the APIs changed in v6_00_a are reverted back for
*		       backward compatibility.
* 7.01a srt  10/26/12  Fixed issue with driver as it fails with IP version
*		       < 6.00a as the parameter C_NUM_*_CHANNELS is not
*		       applicable.
* 8.0   srt  01/29/14  Added support for Micro DMA Mode and Cyclic mode of
*		       operations.
*		      - New API:
*			* XAxiDma_SelectCyclicMode(XAxiDma *InstancePtr,
*						int Direction, int Select)
* 9.1   sk   11/10/15 Used UINTPTR instead of u32 for Baseaddress CR# 867425.
*
* 9.1	vak  11/18/15 Removed warnings in the driver and examples (CR# 911664)
* 9.5   adk  26/10/17 Fix race condition in the XAxiDma_Reset() API. This API
*		      assumes a tx channel is always present it may be configured
*		      for rx only.
*
* </pre>
******************************************************************************/

/***************************** Include Files *********************************/

#include "xaxidma.h"

/************************** Constant Definitions *****************************/

/* Loop counter to check reset done
 */
#define XAXIDMA_RESET_TIMEOUT	500

/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/
static int XAxiDma_Start(XAxiDma * InstancePtr);
static int XAxiDma_Started(XAxiDma * InstancePtr);

/************************** Variable Definitions *****************************/

/*****************************************************************************/
/**
 * This function initializes a DMA engine.  This function must be called
 * prior to using a DMA engine. Initializing a engine includes setting
 * up the register base address, setting up the instance data, and ensuring the
 * hardware is in a quiescent state.
 *
 * @param	InstancePtr is a pointer to the DMA engine instance to be
 *		worked on.
 * @param	Config is a pointer to an XAxiDma_Config structure. It contains
 *		the information about the hardware build, including base
 *		address,and whether status control stream (StsCntrlStrm), MM2S
 *		and S2MM are included in the build.
 *
 * @return
 * 		- XST_SUCCESS for successful initialization
 * 		- XST_INVALID_PARAM if pointer to the configuration structure
 *		is NULL
 * 		- XST_DMA_ERROR if reset operation failed at the end of
 *		initialization
 *
 * @note	We assume the hardware building tool will check and error out
 *		for a hardware build that has no transfer channels.
 *****************************************************************************/
int XAxiDma_CfgInitialize(XAxiDma * InstancePtr, XAxiDma_Config *Config)
{
	UINTPTR BaseAddr;
	int TimeOut;
	int Index;
	u32 MaxTransferLen;

	InstancePtr->Initialized = 0;

	if(!Config) {
		return XST_INVALID_PARAM;
	}

	BaseAddr = Config->BaseAddr;

	/* Setup the instance */
	memset(InstancePtr, 0, sizeof(XAxiDma));
	InstancePtr->RegBase = BaseAddr;

	/* Get hardware setting information from the configuration structure
	 */
	InstancePtr->HasMm2S = Config->HasMm2S;
	InstancePtr->HasS2Mm = Config->HasS2Mm;

	InstancePtr->HasSg = Config->HasSg;

	InstancePtr->MicroDmaMode = Config->MicroDmaMode;
	InstancePtr->AddrWidth = Config->AddrWidth;

	/* Get the number of channels */
	InstancePtr->TxNumChannels = Config->Mm2sNumChannels;
	InstancePtr->RxNumChannels = Config->S2MmNumChannels;

	/* This condition is for IP version < 6.00a */
	if (!InstancePtr->TxNumChannels)
		InstancePtr->TxNumChannels = 1;
	if (!InstancePtr->RxNumChannels)
		InstancePtr->RxNumChannels = 1;

	if ((InstancePtr->RxNumChannels > 1) ||
		(InstancePtr->TxNumChannels > 1)) {
		MaxTransferLen =
			XAXIDMA_MCHAN_MAX_TRANSFER_LEN;
	}
	else {
		MaxTransferLen =
			XAXIDMA_MAX_TRANSFER_LEN;
	}

	/* Initialize the ring structures */
	InstancePtr->TxBdRing.RunState = AXIDMA_CHANNEL_HALTED;
	InstancePtr->TxBdRing.IsRxChannel = 0;
	if (!InstancePtr->MicroDmaMode) {
		InstancePtr->TxBdRing.MaxTransferLen = MaxTransferLen;
	}
	else {
		/* In MicroDMA mode, Maximum length that can be transferred
		 * is '(Memory Data Width / 4) * Burst Size'
		 */
		InstancePtr->TxBdRing.MaxTransferLen =
				((Config->Mm2SDataWidth / 4) *
				 Config->Mm2SBurstSize);
	}
	InstancePtr->TxBdRing.RingIndex = 0;

	for (Index = 0; Index < InstancePtr->RxNumChannels; Index++) {
		InstancePtr->RxBdRing[Index].RunState
						 = AXIDMA_CHANNEL_HALTED;
		InstancePtr->RxBdRing[Index].IsRxChannel = 1;
		InstancePtr->RxBdRing[Index].RingIndex = Index;
	}

	if (InstancePtr->HasMm2S) {
		InstancePtr->TxBdRing.ChanBase =
				BaseAddr + XAXIDMA_TX_OFFSET;
		InstancePtr->TxBdRing.HasStsCntrlStrm =
					Config->HasStsCntrlStrm;
		if (InstancePtr->AddrWidth > 32)
			InstancePtr->TxBdRing.Addr_ext = 1;
		else
			InstancePtr->TxBdRing.Addr_ext = 0;

		InstancePtr->TxBdRing.HasDRE = Config->HasMm2SDRE;
		InstancePtr->TxBdRing.DataWidth =
			((unsigned int)Config->Mm2SDataWidth >> 3);
	}

	if (InstancePtr->HasS2Mm) {
		for (Index = 0;
			Index < InstancePtr->RxNumChannels; Index++) {
			InstancePtr->RxBdRing[Index].ChanBase =
					BaseAddr + XAXIDMA_RX_OFFSET;
			InstancePtr->RxBdRing[Index].HasStsCntrlStrm =
					Config->HasStsCntrlStrm;
			InstancePtr->RxBdRing[Index].HasDRE =
					Config->HasS2MmDRE;
			InstancePtr->RxBdRing[Index].DataWidth =
			((unsigned int)Config->S2MmDataWidth >> 3);

			if (!InstancePtr->MicroDmaMode) {
				InstancePtr->RxBdRing[Index].MaxTransferLen =
							MaxTransferLen;
			}
			else {
			/* In MicroDMA mode, Maximum length that can be transferred
			 * is '(Memory Data Width / 4) * Burst Size'
			 */
				InstancePtr->RxBdRing[Index].MaxTransferLen =
						((Config->S2MmDataWidth / 4) *
						Config->S2MmBurstSize);
			}
			if (InstancePtr->AddrWidth > 32)
				InstancePtr->RxBdRing[Index].Addr_ext = 1;
			else
				InstancePtr->RxBdRing[Index].Addr_ext = 0;
		}
	}

	/* Reset the engine so the hardware starts from a known state
	 */
	XAxiDma_Reset(InstancePtr);

	/* At the initialization time, hardware should finish reset quickly
	 */
	TimeOut = XAXIDMA_RESET_TIMEOUT;

	while (TimeOut) {

		if(XAxiDma_ResetIsDone(InstancePtr)) {
			break;
		}

		TimeOut -= 1;

	}

	if (!TimeOut) {
		xdbg_printf(XDBG_DEBUG_ERROR, "Failed reset in"
							"initialize\r\n");

		/* Need system hard reset to recover
		 */
		InstancePtr->Initialized = 0;
		return XST_DMA_ERROR;
	}

	/* Initialization is successful
	 */
	InstancePtr->Initialized = 1;

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
* Reset both TX and RX channels of a DMA engine.
*
* Reset one channel resets the whole AXI DMA engine.
*
* Any DMA transaction in progress will finish gracefully before engine starts
* reset. Any other transactions that have been submitted to hardware will be
* discarded by the hardware.
*
* @param	InstancePtr is a pointer to the DMA engine instance to be
*		worked on.
*
* @return	None
*
* @note		After the reset:
*		- All interrupts are disabled.
*		- Engine is halted
*
******************************************************************************/
void XAxiDma_Reset(XAxiDma * InstancePtr)
{
	u32 RegBase;
	XAxiDma_BdRing *TxRingPtr;
	XAxiDma_BdRing *RxRingPtr;
	int RingIndex;

	if (InstancePtr->HasMm2S) {
		TxRingPtr = XAxiDma_GetTxRing(InstancePtr);

		/* Save the locations of current BDs both rings are working on
		 * before the reset so later we can resume the rings smoothly.
		 */
		if(XAxiDma_HasSg(InstancePtr)){
			XAxiDma_BdRingSnapShotCurrBd(TxRingPtr);

			for (RingIndex = 0; RingIndex < InstancePtr->RxNumChannels;
							RingIndex++) {
				RxRingPtr = XAxiDma_GetRxIndexRing(InstancePtr,
							RingIndex);
				XAxiDma_BdRingSnapShotCurrBd(RxRingPtr);
			}
		}
	}

	/* Reset
	 */
	if (InstancePtr->HasMm2S) {
		RegBase = InstancePtr->RegBase + XAXIDMA_TX_OFFSET;
	}
	else {
		RegBase = InstancePtr->RegBase + XAXIDMA_RX_OFFSET;
	}

	XAxiDma_WriteReg(RegBase, XAXIDMA_CR_OFFSET, XAXIDMA_CR_RESET_MASK);

	/* Set TX/RX Channel state */
	if (InstancePtr->HasMm2S) {
		TxRingPtr = XAxiDma_GetTxRing(InstancePtr);

		TxRingPtr->RunState = AXIDMA_CHANNEL_HALTED;
	}

	if (InstancePtr->HasS2Mm) {
		for (RingIndex = 0; RingIndex < InstancePtr->RxNumChannels;
						RingIndex++) {
			RxRingPtr = XAxiDma_GetRxIndexRing(InstancePtr, RingIndex);
			if (InstancePtr->HasS2Mm) {
				RxRingPtr->RunState = AXIDMA_CHANNEL_HALTED;
			}
		}
	}
}

/*****************************************************************************/
/**
*
* Check whether reset is done
*
* @param	InstancePtr is a pointer to the DMA engine instance to be
*		worked on.
*
* @return
* 		- 1 if reset is done.
*		- 0 if reset is not done
*
* @note		None
*
******************************************************************************/
int XAxiDma_ResetIsDone(XAxiDma * InstancePtr)
{
	u32 RegisterValue;
	XAxiDma_BdRing *TxRingPtr;
	XAxiDma_BdRing *RxRingPtr;

	TxRingPtr = XAxiDma_GetTxRing(InstancePtr);
	RxRingPtr = XAxiDma_GetRxRing(InstancePtr);

	/* Check transmit channel
	 */
	if (InstancePtr->HasMm2S) {
		RegisterValue = XAxiDma_ReadReg(TxRingPtr->ChanBase,
			XAXIDMA_CR_OFFSET);

		/* Reset is done when the reset bit is low
		 */
		if(RegisterValue & XAXIDMA_CR_RESET_MASK) {

			return 0;
		}
	}

	/* Check receive channel
	 */
	if (InstancePtr->HasS2Mm) {
		RegisterValue = XAxiDma_ReadReg(RxRingPtr->ChanBase,
				XAXIDMA_CR_OFFSET);

		/* Reset is done when the reset bit is low
		 */
		if(RegisterValue & XAXIDMA_CR_RESET_MASK) {

			return 0;
		}
	}

	return 1;
}
/*****************************************************************************/
/*
* Start the DMA engine.
*
* Start a halted engine. Processing of BDs is not started.
*
* @param	InstancePtr is a pointer to the DMA engine instance to be
*		worked on.
*
* @return
* 		- XST_SUCCESS for success
* 		- XST_NOT_SGDMA if the driver instance has not been initialized
* 		- XST_DMA_ERROR if starting the hardware channel fails
*
* @note		None
*
*****************************************************************************/
static int XAxiDma_Start(XAxiDma * InstancePtr)
{
	XAxiDma_BdRing *TxRingPtr;
	XAxiDma_BdRing *RxRingPtr;
	int Status;
	int RingIndex = 0;

	if (!InstancePtr->Initialized) {

		xdbg_printf(XDBG_DEBUG_ERROR, "Start: Driver not initialized "
				"%d\r\n", InstancePtr->Initialized);

		return XST_NOT_SGDMA;
	}

	if (InstancePtr->HasMm2S) {
		TxRingPtr = XAxiDma_GetTxRing(InstancePtr);

		if (TxRingPtr->RunState == AXIDMA_CHANNEL_HALTED) {

			/* Start the channel
			 */
			if(XAxiDma_HasSg(InstancePtr)) {
				Status = XAxiDma_BdRingStart(TxRingPtr);
				if (Status != XST_SUCCESS) {
					xdbg_printf(XDBG_DEBUG_ERROR,
					"Start hw tx channel failed %d\r\n",
								Status);

					return XST_DMA_ERROR;
				}
			}
			else {
				XAxiDma_WriteReg(TxRingPtr->ChanBase,
					XAXIDMA_CR_OFFSET,
					XAxiDma_ReadReg(TxRingPtr->ChanBase,
					XAXIDMA_CR_OFFSET)
					| XAXIDMA_CR_RUNSTOP_MASK);
			}
			TxRingPtr->RunState = AXIDMA_CHANNEL_NOT_HALTED;
		}
	}

	if (InstancePtr->HasS2Mm) {

		for (RingIndex = 0; RingIndex < InstancePtr->RxNumChannels;
						RingIndex++) {
			RxRingPtr = XAxiDma_GetRxIndexRing(InstancePtr,
							 RingIndex);

			if (RxRingPtr->RunState != AXIDMA_CHANNEL_HALTED) {
				return XST_SUCCESS;
			}

			/* Start the channel
			 */
			if(XAxiDma_HasSg(InstancePtr)) {
				Status = XAxiDma_BdRingStart(RxRingPtr);
				if (Status != XST_SUCCESS) {
					xdbg_printf(XDBG_DEBUG_ERROR,
					"Start hw tx channel failed %d\r\n",
								Status);

					return XST_DMA_ERROR;
				}
			}
			else {
				XAxiDma_WriteReg(RxRingPtr->ChanBase,
					XAXIDMA_CR_OFFSET,
					XAxiDma_ReadReg(RxRingPtr->ChanBase,
					XAXIDMA_CR_OFFSET) |
					XAXIDMA_CR_RUNSTOP_MASK);
			}

			RxRingPtr->RunState = AXIDMA_CHANNEL_NOT_HALTED;
		}
	}

	return XST_SUCCESS;
}
/*****************************************************************************/
/**
* Pause DMA transactions on both channels.
*
* If the engine is running and doing transfers, this function does not stop
* the DMA transactions immediately, because then hardware will throw away
* our previously queued transfers. All submitted transfers will finish.
* Transfers submitted after this function will not start until
* XAxiDma_BdRingStart() or XAxiDma_Resume() is called.
*
* @param	InstancePtr is a pointer to the DMA engine instance to be
*		worked on.
*
* @return
* 		- XST_SUCCESS if successful
* 		- XST_NOT_SGDMA, if the driver instance is not initialized
*
* @note		None
*
*****************************************************************************/
int XAxiDma_Pause(XAxiDma * InstancePtr)
{
	XAxiDma_BdRing *TxRingPtr;
	XAxiDma_BdRing *RxRingPtr;
	int RingIndex = 0;

	if (!InstancePtr->Initialized) {

		xdbg_printf(XDBG_DEBUG_ERROR, "Pause: Driver not initialized"
					" %d\r\n",InstancePtr->Initialized);

		return XST_NOT_SGDMA;
	}

	if (InstancePtr->HasMm2S) {
		TxRingPtr = XAxiDma_GetTxRing(InstancePtr);

		/* If channel is halted, then we do not need to do anything
		 */
		if(!XAxiDma_HasSg(InstancePtr)) {
			XAxiDma_WriteReg(TxRingPtr->ChanBase,
				XAXIDMA_CR_OFFSET,
				XAxiDma_ReadReg(TxRingPtr->ChanBase,
				XAXIDMA_CR_OFFSET)
				& ~XAXIDMA_CR_RUNSTOP_MASK);
		}

		TxRingPtr->RunState = AXIDMA_CHANNEL_HALTED;
	}

	if (InstancePtr->HasS2Mm) {
		for (RingIndex = 0; RingIndex < InstancePtr->RxNumChannels;
				RingIndex++) {
			RxRingPtr = XAxiDma_GetRxIndexRing(InstancePtr, RingIndex);

			/* If channel is halted, then we do not need to do anything
			 */

			if(!XAxiDma_HasSg(InstancePtr) && !RingIndex) {
				XAxiDma_WriteReg(RxRingPtr->ChanBase,
					XAXIDMA_CR_OFFSET,
					XAxiDma_ReadReg(RxRingPtr->ChanBase,
					XAXIDMA_CR_OFFSET)
					& ~XAXIDMA_CR_RUNSTOP_MASK);
			}

			RxRingPtr->RunState = AXIDMA_CHANNEL_HALTED;
		}
	}

	return XST_SUCCESS;

}

/*****************************************************************************/
/**
* Resume DMA transactions on both channels.
*
* @param	InstancePtr is a pointer to the DMA engine instance to be
*		worked on.
*
* @return
*		- XST_SUCCESS for success
*		- XST_NOT_SGDMA if the driver instance has not been initialized
*		- XST_DMA_ERROR if one of the channels fails to start
*
* @note		None
*
*****************************************************************************/
int XAxiDma_Resume(XAxiDma * InstancePtr)
{
	XAxiDma_BdRing *TxRingPtr;
	XAxiDma_BdRing *RxRingPtr;
	int Status;
	int RingIndex = 0;

	if (!InstancePtr->Initialized) {

		xdbg_printf(XDBG_DEBUG_ERROR, "Resume: Driver not initialized"
		" %d\r\n",InstancePtr->Initialized);

		return XST_NOT_SGDMA;
	}

	/* If the DMA engine is not running, start it. Start may fail.
	 */
	if (!XAxiDma_Started(InstancePtr)) {
		Status = XAxiDma_Start(InstancePtr);

		if (Status != XST_SUCCESS) {
			xdbg_printf(XDBG_DEBUG_ERROR, "Resume: failed to start"
				" engine %d\r\n", Status);

			return Status;
		}
	}

	/* Mark the state to be not halted
	 */
	if (InstancePtr->HasMm2S) {
		TxRingPtr = XAxiDma_GetTxRing(InstancePtr);

		if(XAxiDma_HasSg(InstancePtr)) {
			Status = XAxiDma_BdRingStart(TxRingPtr);
			if (Status != XST_SUCCESS) {
				xdbg_printf(XDBG_DEBUG_ERROR, "Resume: failed"
				" to start tx ring %d\r\n", Status);

				return XST_DMA_ERROR;
			}
		}

		TxRingPtr->RunState = AXIDMA_CHANNEL_NOT_HALTED;
	}

	if (InstancePtr->HasS2Mm) {
		for (RingIndex = 0 ; RingIndex < InstancePtr->RxNumChannels;
					RingIndex++) {
			RxRingPtr = XAxiDma_GetRxIndexRing(InstancePtr, RingIndex);

			if(XAxiDma_HasSg(InstancePtr)) {
				Status = XAxiDma_BdRingStart(RxRingPtr);
				if (Status != XST_SUCCESS) {
					xdbg_printf(XDBG_DEBUG_ERROR, "Resume: failed"
					"to start rx ring %d\r\n", Status);

					return XST_DMA_ERROR;
				}
			}

			RxRingPtr->RunState = AXIDMA_CHANNEL_NOT_HALTED;
		}
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/*
* Check whether the DMA engine is started.
*
* @param	InstancePtr is a pointer to the DMA engine instance to be
*		worked on.
*
* @return
*		- 1 if engine is started
*		- 0 otherwise.
*
* @note		None
*
*****************************************************************************/
static int XAxiDma_Started(XAxiDma * InstancePtr)
{
	XAxiDma_BdRing *TxRingPtr;
	XAxiDma_BdRing *RxRingPtr;

	if (!InstancePtr->Initialized) {

		xdbg_printf(XDBG_DEBUG_ERROR, "Started: Driver not initialized"
		" %d\r\n",InstancePtr->Initialized);

		return 0;
	}

	if (InstancePtr->HasMm2S) {
		TxRingPtr = XAxiDma_GetTxRing(InstancePtr);

		if (!XAxiDma_BdRingHwIsStarted(TxRingPtr)) {
			xdbg_printf(XDBG_DEBUG_ERROR,
				"Started: tx ring not started\r\n");

			return 0;
		}
	}

	if (InstancePtr->HasS2Mm) {
		RxRingPtr = XAxiDma_GetRxRing(InstancePtr);

		if (!XAxiDma_BdRingHwIsStarted(RxRingPtr)) {
			xdbg_printf(XDBG_DEBUG_ERROR,
				"Started: rx ring not started\r\n");

			return 0;
		}
	}

	return 1;
}

/*****************************************************************************/
/**
 * This function checks whether specified DMA channel is busy
 *
 * @param	InstancePtr is the driver instance we are working on
 *
 * @param	Direction is DMA transfer direction, valid values are
 *			- XAXIDMA_DMA_TO_DEVICE.
 *			- XAXIDMA_DEVICE_TO_DMA.
 *
 * @return	- TRUE if channel is busy
 *		- FALSE if channel is idle
 *
 * @note	None.
 *
 *****************************************************************************/
u32 XAxiDma_Busy(XAxiDma *InstancePtr, int Direction)
{

	return ((XAxiDma_ReadReg(InstancePtr->RegBase +
				(XAXIDMA_RX_OFFSET * Direction),
				XAXIDMA_SR_OFFSET) &
				XAXIDMA_IDLE_MASK) ? FALSE : TRUE);
}


/*****************************************************************************/
/**
 * This function Enable or Disable KeyHole Feature
 *
 * @param	InstancePtr is the driver instance we are working on
 *
 * @param	Direction is DMA transfer direction, valid values are
 *			- XAXIDMA_DMA_TO_DEVICE.
 *			- XAXIDMA_DEVICE_TO_DMA.
 * @Select	Select is the option to enable (TRUE) or disable (FALSE).
 *
 * @return	- XST_SUCCESS for success
 *
 * @note	None.
 *
 *****************************************************************************/
int XAxiDma_SelectKeyHole(XAxiDma *InstancePtr, int Direction, int Select)
{
	u32 Value;

	Value = XAxiDma_ReadReg(InstancePtr->RegBase +
				(XAXIDMA_RX_OFFSET * Direction),
				XAXIDMA_CR_OFFSET);

	if (Select)
		Value |= XAXIDMA_CR_KEYHOLE_MASK;
	else
		Value &= ~XAXIDMA_CR_KEYHOLE_MASK;

	XAxiDma_WriteReg(InstancePtr->RegBase +
			(XAXIDMA_RX_OFFSET * Direction),
			XAXIDMA_CR_OFFSET, Value);

	return XST_SUCCESS;

}

/*****************************************************************************/
/**
 * This function Enable or Disable Cyclic Mode Feature
 *
 * @param	InstancePtr is the driver instance we are working on
 *
 * @param	Direction is DMA transfer direction, valid values are
 *			- XAXIDMA_DMA_TO_DEVICE.
 *			- XAXIDMA_DEVICE_TO_DMA.
 * @Select	Select is the option to enable (TRUE) or disable (FALSE).
 *
 * @return	- XST_SUCCESS for success
 *
 * @note	None.
 *
 *****************************************************************************/
int XAxiDma_SelectCyclicMode(XAxiDma *InstancePtr, int Direction, int Select)
{
	u32 Value;

	Value = XAxiDma_ReadReg(InstancePtr->RegBase +
				(XAXIDMA_RX_OFFSET * Direction),
				XAXIDMA_CR_OFFSET);

	if (Select)
		Value |= XAXIDMA_CR_CYCLIC_MASK;
	else
		Value &= ~XAXIDMA_CR_CYCLIC_MASK;

	XAxiDma_WriteReg(InstancePtr->RegBase +
			(XAXIDMA_RX_OFFSET * Direction),
			XAXIDMA_CR_OFFSET, Value);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * This function does one simple transfer submission
 *
 * It checks in the following sequence:
 *	- if engine is busy, cannot submit
 *	- if engine is in SG mode , cannot submit
 *
 * @param	InstancePtr is the pointer to the driver instance
 * @param	BuffAddr is the address of the source/destination buffer
 * @param	Length is the length of the transfer
 * @param	Direction is DMA transfer direction, valid values are
 *			- XAXIDMA_DMA_TO_DEVICE.
 *			- XAXIDMA_DEVICE_TO_DMA.

 * @return
 *		- XST_SUCCESS for success of submission
 *		- XST_FAILURE for submission failure, maybe caused by:
 *		Another simple transfer is still going
 *		- XST_INVALID_PARAM if:Length out of valid range [1:8M]
 *		Or, address not aligned when DRE is not built in
 *
 * @note	This function is used only when system is configured as
 *		Simple mode.
 *
 *****************************************************************************/
u32 XAxiDma_SimpleTransfer(XAxiDma *InstancePtr, UINTPTR BuffAddr, u32 Length,
	int Direction)
{
	u32 WordBits;
	int RingIndex = 0;

	/* If Scatter Gather is included then, cannot submit
	 */
	if (XAxiDma_HasSg(InstancePtr)) {
		xdbg_printf(XDBG_DEBUG_ERROR, "Simple DMA mode is not"
							" supported\r\n");

		return XST_FAILURE;
	}

	if(Direction == XAXIDMA_DMA_TO_DEVICE){
		if ((Length < 1) ||
			(Length > InstancePtr->TxBdRing.MaxTransferLen)) {
			return XST_INVALID_PARAM;
		}

		if (!InstancePtr->HasMm2S) {
			xdbg_printf(XDBG_DEBUG_ERROR, "MM2S channel is not"
							"supported\r\n");

			return XST_FAILURE;
		}

		/* If the engine is doing transfer, cannot submit
		 */

		if(!(XAxiDma_ReadReg(InstancePtr->TxBdRing.ChanBase,
				XAXIDMA_SR_OFFSET) & XAXIDMA_HALTED_MASK)) {
			if (XAxiDma_Busy(InstancePtr,Direction)) {
				xdbg_printf(XDBG_DEBUG_ERROR,
							"Engine is busy\r\n");
				return XST_FAILURE;
			}
		}

		if (!InstancePtr->MicroDmaMode) {
			WordBits = (u32)((InstancePtr->TxBdRing.DataWidth) - 1);
		}
		else {
			WordBits = XAXIDMA_MICROMODE_MIN_BUF_ALIGN;
		}

		if ((BuffAddr & WordBits)) {

			if (!InstancePtr->TxBdRing.HasDRE) {
				xdbg_printf(XDBG_DEBUG_ERROR,
					"Unaligned transfer without"
					" DRE %x\r\n",(unsigned int)BuffAddr);

				return XST_INVALID_PARAM;
			}
		}


		XAxiDma_WriteReg(InstancePtr->TxBdRing.ChanBase,
				 XAXIDMA_SRCADDR_OFFSET, LOWER_32_BITS(BuffAddr));
		if (InstancePtr->AddrWidth > 32)
			XAxiDma_WriteReg(InstancePtr->TxBdRing.ChanBase,
					 XAXIDMA_SRCADDR_MSB_OFFSET,
					 UPPER_32_BITS(BuffAddr));

		XAxiDma_WriteReg(InstancePtr->TxBdRing.ChanBase,
				XAXIDMA_CR_OFFSET,
				XAxiDma_ReadReg(
				InstancePtr->TxBdRing.ChanBase,
				XAXIDMA_CR_OFFSET)| XAXIDMA_CR_RUNSTOP_MASK);

		/* Writing to the BTT register starts the transfer
		 */
		XAxiDma_WriteReg(InstancePtr->TxBdRing.ChanBase,
					XAXIDMA_BUFFLEN_OFFSET, Length);
	}
	else if(Direction == XAXIDMA_DEVICE_TO_DMA){
		if ((Length < 1) ||
			(Length >
			InstancePtr->RxBdRing[RingIndex].MaxTransferLen)) {
			return XST_INVALID_PARAM;
		}


		if (!InstancePtr->HasS2Mm) {
			xdbg_printf(XDBG_DEBUG_ERROR, "S2MM channel is not"
							" supported\r\n");

			return XST_FAILURE;
		}

		if(!(XAxiDma_ReadReg(InstancePtr->RxBdRing[RingIndex].ChanBase,
				XAXIDMA_SR_OFFSET) & XAXIDMA_HALTED_MASK)) {
			if (XAxiDma_Busy(InstancePtr,Direction)) {
				xdbg_printf(XDBG_DEBUG_ERROR,
							"Engine is busy\r\n");
				return XST_FAILURE;
			}
		}

		if (!InstancePtr->MicroDmaMode) {
			WordBits =
			 (u32)((InstancePtr->RxBdRing[RingIndex].DataWidth) - 1);
		}
		else {
			WordBits = XAXIDMA_MICROMODE_MIN_BUF_ALIGN;
		}

		if ((BuffAddr & WordBits)) {

			if (!InstancePtr->RxBdRing[RingIndex].HasDRE) {
				xdbg_printf(XDBG_DEBUG_ERROR,
					"Unaligned transfer without"
				" DRE %x\r\n", (unsigned int)BuffAddr);

				return XST_INVALID_PARAM;
			}
		}


		XAxiDma_WriteReg(InstancePtr->RxBdRing[RingIndex].ChanBase,
				 XAXIDMA_DESTADDR_OFFSET, LOWER_32_BITS(BuffAddr));
		if (InstancePtr->AddrWidth > 32)
			XAxiDma_WriteReg(InstancePtr->RxBdRing[RingIndex].ChanBase,
					 XAXIDMA_DESTADDR_MSB_OFFSET,
					 UPPER_32_BITS(BuffAddr));

		XAxiDma_WriteReg(InstancePtr->RxBdRing[RingIndex].ChanBase,
				XAXIDMA_CR_OFFSET,
			XAxiDma_ReadReg(InstancePtr->RxBdRing[RingIndex].ChanBase,
			XAXIDMA_CR_OFFSET)| XAXIDMA_CR_RUNSTOP_MASK);
		/* Writing to the BTT register starts the transfer
		 */
		XAxiDma_WriteReg(InstancePtr->RxBdRing[RingIndex].ChanBase,
					XAXIDMA_BUFFLEN_OFFSET, Length);

	}

	return XST_SUCCESS;
}
/** @} */
