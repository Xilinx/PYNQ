/******************************************************************************
*
* Copyright (C) 2012 - 2017 Xilinx, Inc.  All rights reserved.
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
* @file xaxivdma.c
* @addtogroup axivdma_v6_0
* @{
*
* Implementation of the driver API functions for the AXI Video DMA engine.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a jz   08/16/10 First release
* 2.00a jz   12/10/10 Added support for direct register access mode, v3 core
* 2.01a jz   01/19/11 Added ability to re-assign BD addresses
* 	rkv  03/28/11 Added support for frame store register.
* 3.00a srt  08/26/11 Added support for Flush on Frame Sync and dynamic
*		      programming of Line Buffer Thresholds and added API
*		      XAxiVdma_SetLineBufThreshold.
* 4.00a srt  11/21/11 - XAxiVdma_CfgInitialize API is modified to use the
*			EffectiveAddr.
*		      - Added APIs:
*			XAxiVdma_FsyncSrcSelect()
*			XAxiVdma_GenLockSourceSelect()
* 4.01a srt  06/13/12 - Added APIs:
*			XAxiVdma_GetDmaChannelErrors()
*			XAxiVdma_ClearDmaChannelErrors()
* 4.02a srt  09/25/12 - Fixed CR 678734
* 			XAxiVdma_SetFrmStore function changed to remove
*                       Reset logic after setting number of frame stores.
* 4.03a srt  01/18/13 - Updated logic of GenLockSourceSelect() & FsyncSrcSelect()
*                       APIs for newer versions of IP (CR: 691052).
*		      - Modified CfgInitialize() API to initialize
*			StreamWidth parameters. (CR 691866)
* 4.04a srt  03/03/13 - Support for *_ENABLE_DEBUG_INFO_* debug configuration
*			parameters (CR: 703738)
* 6.1   sk   11/10/15 Used UINTPTR instead of u32 for Baseaddress CR# 867425.
*                     Changed the prototype of XAxiVdma_CfgInitialize API.
*
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xaxivdma.h"
#include "xaxivdma_i.h"

/************************** Constant Definitions *****************************/
/* The polling upon starting the hardware
 *
 * We have the assumption that reset is fast upon hardware start
 */
#define INITIALIZATION_POLLING   100000

/*****************************************************************************/
/**
 * Get a channel
 *
 * @param InstancePtr is the DMA engine to work on
 * @param Direction is the direction for the channel to get
 *
 * @return
 * The pointer to the channel. Upon error, return NULL.
 *
 * @note
 * Since this function is internally used, we assume Direction is valid
 *****************************************************************************/
XAxiVdma_Channel *XAxiVdma_GetChannel(XAxiVdma *InstancePtr,
        u16 Direction)
{

	if (Direction == XAXIVDMA_READ) {
		return &(InstancePtr->ReadChannel);
	}
	else if (Direction == XAXIVDMA_WRITE) {
		return &(InstancePtr->WriteChannel);
	}
	else {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Invalid direction %x\r\n", Direction);

		return NULL;
	}
}

static int XAxiVdma_Major(XAxiVdma *InstancePtr) {
	u32 Reg;

	Reg = XAxiVdma_ReadReg(InstancePtr->BaseAddr, XAXIVDMA_VERSION_OFFSET);

	return (int)((Reg & XAXIVDMA_VERSION_MAJOR_MASK) >>
	          XAXIVDMA_VERSION_MAJOR_SHIFT);
}

/*****************************************************************************/
/**
 * Initialize the driver with hardware configuration
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param CfgPtr is the pointer to the hardware configuration structure
 * @param EffectiveAddr is the virtual address map for the device
 *
 * @return
 *  - XST_SUCCESS if everything goes fine
 *  - XST_FAILURE if reset the hardware failed, need system reset to recover
 *
 * @note
 * If channel fails reset,  then it will be set as invalid
 *****************************************************************************/
int XAxiVdma_CfgInitialize(XAxiVdma *InstancePtr, XAxiVdma_Config *CfgPtr,
				UINTPTR EffectiveAddr)
{
	XAxiVdma_Channel *RdChannel;
	XAxiVdma_Channel *WrChannel;
	int Polls;

	/* Validate parameters */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(CfgPtr != NULL);

	/* Initially, no interrupt callback functions
	 */
	InstancePtr->ReadCallBack.CompletionCallBack = 0x0;
	InstancePtr->ReadCallBack.ErrCallBack = 0x0;
	InstancePtr->WriteCallBack.CompletionCallBack = 0x0;
	InstancePtr->WriteCallBack.ErrCallBack = 0x0;

	InstancePtr->BaseAddr = EffectiveAddr;
	InstancePtr->MaxNumFrames = CfgPtr->MaxFrameStoreNum;
	InstancePtr->HasMm2S = CfgPtr->HasMm2S;
	InstancePtr->HasS2Mm = CfgPtr->HasS2Mm;
	InstancePtr->UseFsync = CfgPtr->UseFsync;
	InstancePtr->InternalGenLock = CfgPtr->InternalGenLock;
	InstancePtr->AddrWidth = CfgPtr->AddrWidth;

	if (XAxiVdma_Major(InstancePtr) < 3) {
		InstancePtr->HasSG = 1;
	}
	else {
		InstancePtr->HasSG = CfgPtr->HasSG;
	}

	/* The channels are not valid until being initialized
	 */
	RdChannel = XAxiVdma_GetChannel(InstancePtr, XAXIVDMA_READ);
	RdChannel->IsValid = 0;

	WrChannel = XAxiVdma_GetChannel(InstancePtr, XAXIVDMA_WRITE);
	WrChannel->IsValid = 0;

	if (InstancePtr->HasMm2S) {
		RdChannel->direction = XAXIVDMA_READ;
		RdChannel->ChanBase = InstancePtr->BaseAddr + XAXIVDMA_TX_OFFSET;
		RdChannel->InstanceBase = InstancePtr->BaseAddr;
		RdChannel->HasSG = InstancePtr->HasSG;
		RdChannel->IsRead = 1;
		RdChannel->StartAddrBase = InstancePtr->BaseAddr +
		                              XAXIVDMA_MM2S_ADDR_OFFSET;

		RdChannel->NumFrames = CfgPtr->MaxFrameStoreNum;

		/* Flush on Sync */
		RdChannel->FlushonFsync = CfgPtr->FlushonFsync;

		/* Dynamic Line Buffers Depth */
		RdChannel->LineBufDepth = CfgPtr->Mm2SBufDepth;
		if(RdChannel->LineBufDepth > 0) {
			RdChannel->LineBufThreshold =
				XAxiVdma_ReadReg(RdChannel->ChanBase,
					XAXIVDMA_BUFTHRES_OFFSET);
			xdbg_printf(XDBG_DEBUG_GENERAL,
				"Read Channel Buffer Threshold %d bytes\n\r",
				RdChannel->LineBufThreshold);
		}
		RdChannel->HasDRE = CfgPtr->HasMm2SDRE;
		RdChannel->WordLength = CfgPtr->Mm2SWordLen >> 3;
		RdChannel->StreamWidth = CfgPtr->Mm2SStreamWidth >> 3;
		RdChannel->AddrWidth = InstancePtr->AddrWidth;

		/* Internal GenLock */
		RdChannel->GenLock = CfgPtr->Mm2SGenLock;

		/* Debug Info Parameter flags */
		if (!CfgPtr->EnableAllDbgFeatures) {
			if (CfgPtr->Mm2SThresRegEn) {
				RdChannel->DbgFeatureFlags |=
					XAXIVDMA_ENABLE_DBG_THRESHOLD_REG;
			}

			if (CfgPtr->Mm2SFrmStoreRegEn) {
				RdChannel->DbgFeatureFlags |=
					XAXIVDMA_ENABLE_DBG_FRMSTORE_REG;
			}

			if (CfgPtr->Mm2SDlyCntrEn) {
				RdChannel->DbgFeatureFlags |=
					XAXIVDMA_ENABLE_DBG_DLY_CNTR;
			}

			if (CfgPtr->Mm2SFrmCntrEn) {
				RdChannel->DbgFeatureFlags |=
					XAXIVDMA_ENABLE_DBG_FRM_CNTR;
			}

		} else {
			RdChannel->DbgFeatureFlags =
				XAXIVDMA_ENABLE_DBG_ALL_FEATURES;
		}

		XAxiVdma_ChannelInit(RdChannel);

		XAxiVdma_ChannelReset(RdChannel);

		/* At time of initialization, no transfers are going on,
		 * reset is expected to be quick
		 */
		Polls = INITIALIZATION_POLLING;

		while (Polls && XAxiVdma_ChannelResetNotDone(RdChannel)) {
			Polls -= 1;
		}

		if (!Polls) {
			xdbg_printf(XDBG_DEBUG_ERROR,
			    "Read channel reset failed %x\n\r",
			    (unsigned int)XAxiVdma_ChannelGetStatus(RdChannel));

			return XST_FAILURE;
		}
	}

	if (InstancePtr->HasS2Mm) {
		WrChannel->direction = XAXIVDMA_WRITE;
		WrChannel->ChanBase = InstancePtr->BaseAddr + XAXIVDMA_RX_OFFSET;
		WrChannel->InstanceBase = InstancePtr->BaseAddr;
		WrChannel->HasSG = InstancePtr->HasSG;
		WrChannel->IsRead = 0;
		WrChannel->StartAddrBase = InstancePtr->BaseAddr +
		                                 XAXIVDMA_S2MM_ADDR_OFFSET;
		WrChannel->NumFrames = CfgPtr->MaxFrameStoreNum;
		WrChannel->AddrWidth = InstancePtr->AddrWidth;

		/* Flush on Sync */
		WrChannel->FlushonFsync = CfgPtr->FlushonFsync;

		/* Dynamic Line Buffers Depth */
		WrChannel->LineBufDepth = CfgPtr->S2MmBufDepth;
		if(WrChannel->LineBufDepth > 0) {
			WrChannel->LineBufThreshold =
				XAxiVdma_ReadReg(WrChannel->ChanBase,
					XAXIVDMA_BUFTHRES_OFFSET);
			xdbg_printf(XDBG_DEBUG_GENERAL,
				"Write Channel Buffer Threshold %d bytes\n\r",
				WrChannel->LineBufThreshold);
		}
		WrChannel->HasDRE = CfgPtr->HasS2MmDRE;
		WrChannel->WordLength = CfgPtr->S2MmWordLen >> 3;
		WrChannel->StreamWidth = CfgPtr->S2MmStreamWidth >> 3;

		/* Internal GenLock */
		WrChannel->GenLock = CfgPtr->S2MmGenLock;

		/* Frame Sync Source Selection*/
		WrChannel->S2MmSOF = CfgPtr->S2MmSOF;

		/* Debug Info Parameter flags */
		if (!CfgPtr->EnableAllDbgFeatures) {
			if (CfgPtr->S2MmThresRegEn) {
				WrChannel->DbgFeatureFlags |=
					 XAXIVDMA_ENABLE_DBG_THRESHOLD_REG;
			}

			if (CfgPtr->S2MmFrmStoreRegEn) {
				WrChannel->DbgFeatureFlags |=
					XAXIVDMA_ENABLE_DBG_FRMSTORE_REG;
			}

			if (CfgPtr->S2MmDlyCntrEn) {
				WrChannel->DbgFeatureFlags |=
					XAXIVDMA_ENABLE_DBG_DLY_CNTR;
			}

			if (CfgPtr->S2MmFrmCntrEn) {
				WrChannel->DbgFeatureFlags |=
					XAXIVDMA_ENABLE_DBG_FRM_CNTR;
			}

		} else {
			WrChannel->DbgFeatureFlags =
					XAXIVDMA_ENABLE_DBG_ALL_FEATURES;
		}

		XAxiVdma_ChannelInit(WrChannel);

		XAxiVdma_ChannelReset(WrChannel);

		/* At time of initialization, no transfers are going on,
		 * reset is expected to be quick
		 */
		Polls = INITIALIZATION_POLLING;

		while (Polls && XAxiVdma_ChannelResetNotDone(WrChannel)) {
			Polls -= 1;
		}

		if (!Polls) {
			xdbg_printf(XDBG_DEBUG_ERROR,
			    "Write channel reset failed %x\n\r",
			    (unsigned int)XAxiVdma_ChannelGetStatus(WrChannel));

			return XST_FAILURE;
		}
	}

	InstancePtr->IsReady = XAXIVDMA_DEVICE_READY;

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * This function resets one DMA channel
 *
 * The registers will be default values after the reset
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the channel to work on, use XAXIVDMA_READ/WRITE
 *
 * @return
 * None
 *
 * @note
 * Due to undeterminism of system delays, check the reset status through
 * XAxiVdma_ResetNotDone(). If direction is invalid, do nothing.
 *****************************************************************************/
void XAxiVdma_Reset(XAxiVdma *InstancePtr, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return;
	}

	if (Channel->IsValid) {
		XAxiVdma_ChannelReset(Channel);

		return;
	}
}

/*****************************************************************************/
/**
 * This function checks one DMA channel for reset completion
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the channel to work on, use XAXIVDMA_READ/WRITE
 *
 * @return
 *  - 0 if reset is done
 *  - 1 if reset is ongoing
 *
 * @note
 * We do not check for channel validity, because channel is marked as invalid
 * before reset is done
 *****************************************************************************/
int XAxiVdma_ResetNotDone(XAxiVdma *InstancePtr, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	/* If dirction is invalid, reset is never done
	 */
	if (!Channel) {
		return 1;
	}

	return XAxiVdma_ChannelResetNotDone(Channel);
}

/*****************************************************************************/
/**
 * Check whether a DMA channel is busy
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the channel to work on, use XAXIVDMA_READ/WRITE
 *
 * @return
 * - Non-zero if the channel is busy
 * - Zero if the channel is idle
 *
 *****************************************************************************/
int XAxiVdma_IsBusy(XAxiVdma *InstancePtr, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return 0;
	}

	if (Channel->IsValid) {
		return XAxiVdma_ChannelIsBusy(Channel);
	}
	else {
		/* An invalid channel is never busy
		 */
		return 0;
	}
}

/*****************************************************************************/
/**
 * Get the current frame that hardware is working on
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the channel to work on, use XAXIVDMA_READ/WRITE
 *
 * @return
 * The current frame that the hardware is working on
 *
 * @note
 * If returned frame number is out of range, then the channel is invalid
 *****************************************************************************/
u32 XAxiVdma_CurrFrameStore(XAxiVdma *InstancePtr, u16 Direction)
{
	u32 Rc;

	Rc = XAxiVdma_ReadReg(InstancePtr->BaseAddr, XAXIVDMA_PARKPTR_OFFSET);

	if (Direction == XAXIVDMA_READ) {
		Rc &= XAXIVDMA_PARKPTR_READSTR_MASK;
		return (Rc >> XAXIVDMA_READSTR_SHIFT);
	}
	else if (Direction == XAXIVDMA_WRITE) {
		Rc &= XAXIVDMA_PARKPTR_WRTSTR_MASK;
		return (Rc >> XAXIVDMA_WRTSTR_SHIFT);
	}
	else {
		return 0xFFFFFFFF;
	}
}

/*****************************************************************************/
/**
 * Get the version of the hardware
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 *
 * @return
 * The version of the hardware
 *
 *****************************************************************************/
u32 XAxiVdma_GetVersion(XAxiVdma *InstancePtr)
{
	return XAxiVdma_ReadReg(InstancePtr->BaseAddr, XAXIVDMA_VERSION_OFFSET);
}

/*****************************************************************************/
/**
 * Get the status of a channel
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the channel to work on, use XAXIVDMA_READ/WRITE
 *
 * @return
 * The status of the channel
 *
 * @note
 * An invalid return value indicates that channel is invalid
 *****************************************************************************/
u32 XAxiVdma_GetStatus(XAxiVdma *InstancePtr, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return 0xFFFFFFFF;
	}

	if (Channel->IsValid) {
		return XAxiVdma_ChannelGetStatus(Channel);
	}
	else {
		return 0xFFFFFFFF;
	}
}

/*****************************************************************************/
/**
 * Configure Line Buffer Threshold
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param LineBufThreshold is the value to set threshold
 * @param Direction is the DMA channel to work on
 *
 * @return
 * - XST_SUCCESS if successful
 * - XST_FAILURE otherwise
 * - XST_NO_FEATURE if access to Threshold register is disabled
 *****************************************************************************/
int XAxiVdma_SetLineBufThreshold(XAxiVdma *InstancePtr, int LineBufThreshold,
	u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!(Channel->DbgFeatureFlags & XAXIVDMA_ENABLE_DBG_THRESHOLD_REG)) {
		xdbg_printf(XDBG_DEBUG_ERROR,
				"Threshold Register is disabled\n\r");
		return XST_NO_FEATURE;
	}

	if(Channel->LineBufThreshold) {
		if((LineBufThreshold < Channel->LineBufDepth) &&
			(LineBufThreshold % Channel->StreamWidth == 0)) {
			XAxiVdma_WriteReg(Channel->ChanBase,
				XAXIVDMA_BUFTHRES_OFFSET, LineBufThreshold);

			xdbg_printf(XDBG_DEBUG_GENERAL,
				"Line Buffer Threshold set to %x\n\r",
				XAxiVdma_ReadReg(Channel->ChanBase,
				XAXIVDMA_BUFTHRES_OFFSET));
		}
		else {
			xdbg_printf(XDBG_DEBUG_ERROR,
				"Invalid Line Buffer Threshold\n\r");
			return XST_FAILURE;
		}
	}
	else {
		xdbg_printf(XDBG_DEBUG_ERROR,
			"Failed to set Threshold\n\r");
		return XST_FAILURE;
	}
	return XST_SUCCESS;
}


/*****************************************************************************/
/**
 * Configure Frame Sync Source and valid only when C_USE_FSYNC is enabled.
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Source is the value to set the source of Frame Sync
 * @param Direction is the DMA channel to work on
 *
 * @return
 * - XST_SUCCESS if successful
 * - XST_FAILURE if C_USE_FSYNC is disabled.
 *
 *****************************************************************************/
int XAxiVdma_FsyncSrcSelect(XAxiVdma *InstancePtr, u32 Source,
				u16 Direction)
{
	XAxiVdma_Channel *Channel;
	u32 CrBits;
	u32 UseFsync;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (Direction == XAXIVDMA_WRITE) {
		UseFsync = ((InstancePtr->UseFsync == 1) ||
				(InstancePtr->UseFsync == 3)) ? 1 : 0;
	} else {
		UseFsync = ((InstancePtr->UseFsync == 1) ||
				(InstancePtr->UseFsync == 2)) ? 1 : 0;
	}

	if (UseFsync) {
		CrBits = XAxiVdma_ReadReg(Channel->ChanBase,
				XAXIVDMA_CR_OFFSET);

		switch (Source) {
		case XAXIVDMA_CHAN_FSYNC:
			/* Same Channel Frame Sync */
			CrBits &= ~(XAXIVDMA_CR_FSYNC_SRC_MASK);
			break;

		case XAXIVDMA_CHAN_OTHER_FSYNC:
			/* The other Channel Frame Sync */
			CrBits |= (XAXIVDMA_CR_FSYNC_SRC_MASK & ~(1 << 6));
			break;

		case XAXIVDMA_S2MM_TUSER_FSYNC:
			/* S2MM TUser Sync */
			if (Channel->S2MmSOF) {
				CrBits |= (XAXIVDMA_CR_FSYNC_SRC_MASK
						 & ~(1 << 5));
			}
			else
				return XST_FAILURE;
			break;
		}

		XAxiVdma_WriteReg(Channel->ChanBase,
			XAXIVDMA_CR_OFFSET, CrBits);

		return XST_SUCCESS;
	}

	xdbg_printf(XDBG_DEBUG_ERROR,
			"This bit is not valid for this configuration\n\r");
	return XST_FAILURE;
}

/*****************************************************************************/
/**
 * Configure Gen Lock Source
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Source is the value to set the source of Gen Lock
 * @param Direction is the DMA channel to work on
 *
 * @return
 * - XST_SUCCESS if successful
 * - XST_FAILURE if the channel is in GenLock Master Mode.
 *		 if C_INCLUDE_INTERNAL_GENLOCK is disabled.
 *
 *****************************************************************************/
int XAxiVdma_GenLockSourceSelect(XAxiVdma *InstancePtr, u32 Source,
					u16 Direction)
{
	XAxiVdma_Channel *Channel, *XChannel;
	u32 CrBits;

	if (InstancePtr->HasMm2S && InstancePtr->HasS2Mm &&
			InstancePtr->InternalGenLock) {
		if (Direction == XAXIVDMA_WRITE) {
			Channel = XAxiVdma_GetChannel(InstancePtr, Direction);
			XChannel = XAxiVdma_GetChannel(InstancePtr, XAXIVDMA_READ);
		} else {
			Channel = XAxiVdma_GetChannel(InstancePtr, Direction);
			XChannel = XAxiVdma_GetChannel(InstancePtr, XAXIVDMA_WRITE);
		}

		if ((Channel->GenLock == XAXIVDMA_GENLOCK_MASTER &&
			XChannel->GenLock == XAXIVDMA_GENLOCK_SLAVE) ||
			(Channel->GenLock == XAXIVDMA_GENLOCK_SLAVE &&
				XChannel->GenLock == XAXIVDMA_GENLOCK_MASTER) ||
			(Channel->GenLock == XAXIVDMA_DYN_GENLOCK_MASTER &&
				XChannel->GenLock == XAXIVDMA_DYN_GENLOCK_SLAVE) ||
			(Channel->GenLock == XAXIVDMA_DYN_GENLOCK_SLAVE &&
				XChannel->GenLock == XAXIVDMA_DYN_GENLOCK_MASTER)) {

			CrBits = XAxiVdma_ReadReg(Channel->ChanBase,
				XAXIVDMA_CR_OFFSET);

			if (Source == XAXIVDMA_INTERNAL_GENLOCK)
				CrBits |= XAXIVDMA_CR_GENLCK_SRC_MASK;
			else if (Source == XAXIVDMA_EXTERNAL_GENLOCK)
				CrBits &= ~XAXIVDMA_CR_GENLCK_SRC_MASK;
			else {
				xdbg_printf(XDBG_DEBUG_ERROR,
					"Invalid argument\n\r");
				return XST_FAILURE;
			}

			XAxiVdma_WriteReg(Channel->ChanBase,
				XAXIVDMA_CR_OFFSET, CrBits);

			return XST_SUCCESS;
		}
	}

	xdbg_printf(XDBG_DEBUG_ERROR,
			"This bit is not valid for this configuration\n\r");
	return XST_FAILURE;
}

/*****************************************************************************/
/**
 * Start parking mode on a certain frame
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param FrameIndex is the frame to park on
 * @param Direction is the channel to work on, use XAXIVDMA_READ/WRITE
 *
 * @return
 *  - XST_SUCCESS if everything is fine
 *  - XST_INVALID_PARAM if
 *    . channel is invalid
 *    . FrameIndex is invalid
 *    . Direction is invalid
 *****************************************************************************/
int XAxiVdma_StartParking(XAxiVdma *InstancePtr, int FrameIndex,
         u16 Direction)
{
	XAxiVdma_Channel *Channel;
	u32 FrmBits;
	u32 RegValue;
	int Status;

	if (FrameIndex > XAXIVDMA_FRM_MAX) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Invalid frame to park on %d\r\n", FrameIndex);

		return XST_INVALID_PARAM;
	}

	if (Direction == XAXIVDMA_READ) {
		FrmBits = FrameIndex &
			XAXIVDMA_PARKPTR_READREF_MASK;

		RegValue = XAxiVdma_ReadReg(InstancePtr->BaseAddr,
		              XAXIVDMA_PARKPTR_OFFSET);

		RegValue &= ~XAXIVDMA_PARKPTR_READREF_MASK;

		RegValue |= FrmBits;

		XAxiVdma_WriteReg(InstancePtr->BaseAddr,
			    XAXIVDMA_PARKPTR_OFFSET, RegValue);
		}
	else if (Direction == XAXIVDMA_WRITE) {
		FrmBits = FrameIndex << XAXIVDMA_WRTREF_SHIFT;

		FrmBits &= XAXIVDMA_PARKPTR_WRTREF_MASK;

		RegValue = XAxiVdma_ReadReg(InstancePtr->BaseAddr,
		              XAXIVDMA_PARKPTR_OFFSET);

		RegValue &= ~XAXIVDMA_PARKPTR_WRTREF_MASK;

		RegValue |= FrmBits;

		XAxiVdma_WriteReg(InstancePtr->BaseAddr,
		    XAXIVDMA_PARKPTR_OFFSET, RegValue);
	}
	else {
		/* Invalid direction, do nothing
		 */
		return XST_INVALID_PARAM;
	}

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (Channel->IsValid) {
		Status = XAxiVdma_ChannelStartParking(Channel);
		if (Status != XST_SUCCESS) {
			xdbg_printf(XDBG_DEBUG_ERROR,
			    "Failed to start channel %x\r\n",
			    (unsigned int)Channel);

			return XST_FAILURE;
		}
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * Exit parking mode, the channel will return to circular buffer mode
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the channel to work on, use XAXIVDMA_READ/WRITE
 *
 * @return
 *   None
 *
 * @note
 * If channel is invalid, then do nothing
 *****************************************************************************/
void XAxiVdma_StopParking(XAxiVdma *InstancePtr, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return;
	}

	if (Channel->IsValid) {
		XAxiVdma_ChannelStopParking(Channel);
	}

	return;
}

/*****************************************************************************/
/**
 * Start frame count enable on one channel
 *
 * This is needed to start limiting the number of frames to transfer so that
 * software can check the data etc after hardware stops transfer.
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the channel to work on, use XAXIVDMA_READ/WRITE
 *
 * @return
 *   None
 *
 *****************************************************************************/
void XAxiVdma_StartFrmCntEnable(XAxiVdma *InstancePtr, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (Channel->IsValid) {
		XAxiVdma_ChannelStartFrmCntEnable(Channel);
	}
}

/*****************************************************************************/
/**
 * Set BD addresses to be different.
 *
 * In some systems, it is convenient to put BDs into a certain region of the
 * memory. This function enables that.
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param BdAddrPhys is the physical starting address for BDs
 * @param BdAddrVirt is the Virtual starting address for BDs. For systems that
 *         do not use MMU, then virtual address is the same as physical address
 * @param NumBds is the number of BDs to setup with. This is required to be
 *        the same as the number of frame stores for that channel
 * @param Direction is the channel direction
 *
 * @return
 * - XST_SUCCESS for a successful setup
 * - XST_DEVICE_BUSY if the DMA channel is not idle, BDs are still being used
 * - XST_INVALID_PARAM if parameters not valid
 * - XST_DEVICE_NOT_FOUND if the channel is invalid
 *
 * @notes
 * We assume that the memory region starting from BdAddrPhys and BdAddrVirt are
 * large enough to hold all the BDs.
 *****************************************************************************/
int XAxiVdma_SetBdAddrs(XAxiVdma *InstancePtr, u32 BdAddrPhys, u32 BdAddrVirt,
         int NumBds, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (Channel->IsValid) {
		if (NumBds != Channel->AllCnt) {
			return XST_INVALID_PARAM;
		}

		if (BdAddrPhys & (XAXIVDMA_BD_MINIMUM_ALIGNMENT - 1)) {
			return XST_INVALID_PARAM;
		}

		if (BdAddrVirt & (XAXIVDMA_BD_MINIMUM_ALIGNMENT - 1)) {
			return XST_INVALID_PARAM;
		}

		return XAxiVdma_ChannelSetBdAddrs(Channel, BdAddrPhys, BdAddrVirt);
	}
	else {
		return XST_DEVICE_NOT_FOUND;
	}
}

/*****************************************************************************/
/**
 * Start a write operation
 *
 * Write corresponds to send data from device to memory
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param DmaConfigPtr is the pointer to the setup structure
 *
 * @return
 * - XST_SUCCESS for a successful submission
 * - XST_DEVICE_BUSY if the DMA channel is not idle, BDs are still being used
 * - XST_INVAID_PARAM if parameters in config structure not valid
 * - XST_DEVICE_NOT_FOUND if the channel is invalid
 *
 *****************************************************************************/
int XAxiVdma_StartWriteFrame(XAxiVdma *InstancePtr,
    XAxiVdma_DmaSetup *DmaConfigPtr)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, XAXIVDMA_WRITE);

	if (Channel->IsValid) {
		return XAxiVdma_ChannelStartTransfer(Channel,
		    (XAxiVdma_ChannelSetup *)DmaConfigPtr);
	}
	else {
		return XST_DEVICE_NOT_FOUND;
	}
}

/*****************************************************************************/
/**
 * Start a read operation
 *
 * Read corresponds to send data from memory to device
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param DmaConfigPtr is the pointer to the setup structure
 *
 * @return
 * - XST_SUCCESS for a successful submission
 * - XST_DEVICE_BUSY if the DMA channel is not idle, BDs are still being used
 * - XST_INVAID_PARAM if parameters in config structure not valid
 * - XST_DEVICE_NOT_FOUND if the channel is invalid
 *
 *****************************************************************************/
int XAxiVdma_StartReadFrame(XAxiVdma *InstancePtr,
        XAxiVdma_DmaSetup *DmaConfigPtr)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, XAXIVDMA_READ);

	if (Channel->IsValid) {
		return XAxiVdma_ChannelStartTransfer(Channel,
		    (XAxiVdma_ChannelSetup *)DmaConfigPtr);
	}
	else {
		return XST_DEVICE_NOT_FOUND;
	}
}

/*****************************************************************************/
/**
 * Configure one DMA channel using the configuration structure
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the DMA channel to work on
 * @param DmaConfigPtr is the pointer to the setup structure
 *
 * @return
 * - XST_SUCCESS if successful
 * - XST_DEVICE_BUSY if the DMA channel is not idle, BDs are still being used
 * - XST_INVAID_PARAM if buffer address not valid, for example, unaligned
 *   address with no DRE built in the hardware, or Direction invalid
 * - XST_DEVICE_NOT_FOUND if the channel is invalid
 *
 *****************************************************************************/
int XAxiVdma_DmaConfig(XAxiVdma *InstancePtr, u16 Direction,
        XAxiVdma_DmaSetup *DmaConfigPtr)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return XST_INVALID_PARAM;
	}


	if (Channel->IsValid) {

		return XAxiVdma_ChannelConfig(Channel,
		    (XAxiVdma_ChannelSetup *)DmaConfigPtr);
	}
	else {
		return XST_DEVICE_NOT_FOUND;
	}
}

/*****************************************************************************/
/**
 * Configure buffer addresses for one DMA channel
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the DMA channel to work on
 * @param BufferAddrSet is the set of addresses for the transfers
 *
 * @return
 * - XST_SUCCESS if successful
 * - XST_DEVICE_BUSY if the DMA channel is not idle, BDs are still being used
 * - XST_INVAID_PARAM if buffer address not valid, for example, unaligned
 *   address with no DRE built in the hardware, or Direction invalid
 * - XST_DEVICE_NOT_FOUND if the channel is invalid
 *
 *****************************************************************************/
int XAxiVdma_DmaSetBufferAddr(XAxiVdma *InstancePtr, u16 Direction,
        UINTPTR *BufferAddrSet)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return XST_INVALID_PARAM;
	}

	if (Channel->IsValid) {
		return XAxiVdma_ChannelSetBufferAddr(Channel, BufferAddrSet,
		    Channel->NumFrames);
	}
	else {
		return XST_DEVICE_NOT_FOUND;
	}
}

/*****************************************************************************/
/**
 * Start one DMA channel
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the DMA channel to work on
 *
 * @return
 * - XST_SUCCESS if channel started successfully
 * - XST_FAILURE otherwise
 * - XST_DEVICE_NOT_FOUND if the channel is invalid
 * - XST_INVALID_PARAM if Direction invalid
 *
 *****************************************************************************/
int XAxiVdma_DmaStart(XAxiVdma *InstancePtr, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return XST_INVALID_PARAM;
	}

	if (Channel->IsValid) {
		return XAxiVdma_ChannelStart(Channel);
	}
	else {
		return XST_DEVICE_NOT_FOUND;
	}
}

/*****************************************************************************/
/**
 * Stop one DMA channel
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the DMA channel to work on
 *
 * @return
 *  None
 *
 * @note
 * If channel is invalid, then do nothing on that channel
 *****************************************************************************/
void XAxiVdma_DmaStop(XAxiVdma *InstancePtr, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return;
	}

	if (Channel->IsValid) {
		XAxiVdma_ChannelStop(Channel);
	}

	return;
}

/*****************************************************************************/
/**
 * Dump registers of one DMA channel
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the DMA channel to work on
 *
 * @return
 *  None
 *
 * @note
 * If channel is invalid, then do nothing on that channel
 *****************************************************************************/
void XAxiVdma_DmaRegisterDump(XAxiVdma *InstancePtr, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return;
	}

	if (Channel->IsValid) {
		XAxiVdma_ChannelRegisterDump(Channel);
	}

	return;
}

/*****************************************************************************/
/**
 * Set the frame counter and delay counter for both channels
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param CfgPtr is the pointer to the configuration structure
 *
 * @return
 *   - XST_SUCCESS if setup finishes successfully
 *   - XST_INVALID_PARAM if the configuration structure has invalid values
 *   - Others if setting channel frame counter fails
 *
 * @note
 * If channel is invalid, then do nothing on that channel
 *****************************************************************************/
int XAxiVdma_SetFrameCounter(XAxiVdma *InstancePtr,
        XAxiVdma_FrameCounter *CfgPtr)
{
	int Status;
	XAxiVdma_Channel *Channel;

	/* Validate parameters */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XAXIVDMA_DEVICE_READY);
	Xil_AssertNonvoid(CfgPtr != NULL);

	if ((CfgPtr->ReadFrameCount == 0) ||
	    (CfgPtr->WriteFrameCount == 0)) {

		return XST_INVALID_PARAM;
	}

	Channel = XAxiVdma_GetChannel(InstancePtr, XAXIVDMA_READ);

	if (Channel->IsValid) {

		Status = XAxiVdma_ChannelSetFrmCnt(Channel, CfgPtr->ReadFrameCount,
				    CfgPtr->ReadDelayTimerCount);
		if (Status != XST_SUCCESS) {
			xdbg_printf(XDBG_DEBUG_ERROR,
			    "Setting read channel frame counter "
			    "failed with %d\r\n", Status);

			return Status;
		}
	}

	Channel = XAxiVdma_GetChannel(InstancePtr, XAXIVDMA_WRITE);

	if (Channel->IsValid) {

		Status = XAxiVdma_ChannelSetFrmCnt(Channel,
		          CfgPtr->WriteFrameCount,
			      CfgPtr->WriteDelayTimerCount);
		if (Status != XST_SUCCESS) {
			xdbg_printf(XDBG_DEBUG_ERROR,
			    "Setting write channel frame counter "
			    "failed with %d\r\n", Status);

			return Status;
		}
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * Get the frame counter and delay counter for both channels
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param CfgPtr is the configuration structure to contain return values
 *
 * @return
 *  None
 *
 * @note
 * If returned frame counter value is 0, then the channel is not valid
 *****************************************************************************/
void XAxiVdma_GetFrameCounter(XAxiVdma *InstancePtr,
        XAxiVdma_FrameCounter *CfgPtr)
{
	XAxiVdma_Channel *Channel;
	u8 FrmCnt;
	u8 DlyCnt;

	/* Validate parameters */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XAXIVDMA_DEVICE_READY);
	Xil_AssertVoid(CfgPtr != NULL);

	/* Use a zero frame counter value to indicate failure
	 */
	FrmCnt = 0;

	Channel = XAxiVdma_GetChannel(InstancePtr, XAXIVDMA_READ);

	if (Channel->IsValid) {
		XAxiVdma_ChannelGetFrmCnt(Channel, &FrmCnt, &DlyCnt);
	}

	CfgPtr->ReadFrameCount = FrmCnt;
	CfgPtr->ReadDelayTimerCount = DlyCnt;

	/* Use a zero frame counter value to indicate failure
	 */
	FrmCnt = 0;

	Channel = XAxiVdma_GetChannel(InstancePtr, XAXIVDMA_WRITE);

	if (Channel->IsValid) {
		XAxiVdma_ChannelGetFrmCnt(Channel, &FrmCnt, &DlyCnt);
	}

	CfgPtr->WriteFrameCount = FrmCnt;
	CfgPtr->WriteDelayTimerCount = DlyCnt;

	return;
}

/*****************************************************************************/
/**
 * Set the number of frame store buffers to use.
 *
 * @param 	InstancePtr is the XAxiVdma instance to operate on
 * @param 	FrmStoreNum is the number of frame store buffers to use.
 * @param	Direction is the channel to work on, use XAXIVDMA_READ/WRITE
 *
 * @return	- XST_SUCCESS if operation is successful
 *		- XST_FAILURE if operation fails.
 *		- XST_NO_FEATURE if access to FrameStore register is disabled
 * @note	None
 *
 *****************************************************************************/
int XAxiVdma_SetFrmStore(XAxiVdma *InstancePtr, u8 FrmStoreNum, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	if(FrmStoreNum > InstancePtr->MaxNumFrames) {
		return XST_FAILURE;
	}

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return XST_FAILURE;
	}

	if(XAxiVdma_ChannelIsRunning(Channel)) {
		xdbg_printf(XDBG_DEBUG_ERROR, "Cannot set frame store..."
						"channel is running\r\n");
		return XST_FAILURE;
	}

	if (!(Channel->DbgFeatureFlags & XAXIVDMA_ENABLE_DBG_FRMSTORE_REG)) {
		xdbg_printf(XDBG_DEBUG_ERROR,
			"Frame Store Register is disabled\n\r");
		return XST_NO_FEATURE;
	}

	XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_FRMSTORE_OFFSET,
	    FrmStoreNum & XAXIVDMA_FRMSTORE_MASK);

	Channel->NumFrames = FrmStoreNum;

	XAxiVdma_ChannelInit(Channel);

	return XST_SUCCESS;

}

/*****************************************************************************/
/**
 * Get the number of frame store buffers to use.
 *
 * @param 	InstancePtr is the XAxiVdma instance to operate on
 * @param 	FrmStoreNum is the number of frame store buffers to use.
 * @param	Direction is the channel to work on, use XAXIVDMA_READ/WRITE
 *
 * @return	None
 *
 * @note	None
 *
 *****************************************************************************/
void XAxiVdma_GetFrmStore(XAxiVdma *InstancePtr, u8 *FrmStoreNum,
				u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return;
	}

	if (Channel->DbgFeatureFlags & XAXIVDMA_ENABLE_DBG_FRMSTORE_REG) {
		*FrmStoreNum = (XAxiVdma_ReadReg(Channel->ChanBase,
			XAXIVDMA_FRMSTORE_OFFSET)) & XAXIVDMA_FRMSTORE_MASK;
	} else {
		xdbg_printf(XDBG_DEBUG_ERROR,
			"Frame Store Register is disabled\n\r");
	}
}

/*****************************************************************************/
/**
 * Check for DMA Channel Errors.
 *
 * @param 	InstancePtr is the XAxiVdma instance to operate on
 * @param	Direction is the channel to work on, use XAXIVDMA_READ/WRITE
 *
 * @return	- Errors seen on the channel
 *		- XST_INVALID_PARAM, when channel pointer is invalid.
 *		- XST_DEVICE_NOT_FOUND, when the channel is not valid.
 *
 * @note	None
 *
 *****************************************************************************/
int XAxiVdma_GetDmaChannelErrors(XAxiVdma *InstancePtr, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return XST_INVALID_PARAM;
	}

	if (Channel->IsValid) {
		return XAxiVdma_ChannelErrors(Channel);
	}
	else {
		return XST_DEVICE_NOT_FOUND;
	}
}

/*****************************************************************************/
/**
 * Clear DMA Channel Errors.
 *
 * @param 	InstancePtr is the XAxiVdma instance to operate on
 * @param	Direction is the channel to work on, use XAXIVDMA_READ/WRITE
 * @param	ErrorMask is the mask of error bits to clear
 *
 * @return	- XST_SUCCESS, when error bits are cleared.
 *		- XST_INVALID_PARAM, when channel pointer is invalid.
 *		- XST_DEVICE_NOT_FOUND, when the channel is not valid.
 *
 * @note	None
 *
 *****************************************************************************/
int XAxiVdma_ClearDmaChannelErrors(XAxiVdma *InstancePtr, u16 Direction,
					u32 ErrorMask)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return XST_INVALID_PARAM;
	}

	if (Channel->IsValid) {
		XAxiVdma_ClearChannelErrors(Channel, ErrorMask);
		return XST_SUCCESS;
	}
	else {
		return XST_DEVICE_NOT_FOUND;
	}
}
/** @} */
