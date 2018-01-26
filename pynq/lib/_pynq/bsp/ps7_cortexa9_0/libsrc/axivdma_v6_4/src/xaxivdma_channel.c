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
* @file xaxivdma_channel.c
* @addtogroup axivdma_v6_0
* @{
*
* Implementation of the channel related functions. These functions are used
* internally by the driver, and are declared in xaxivdma_i.h.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a jz   08/16/10 First release
* 2.00a jz   12/10/10 Added support for direct register access mode, v3 core
* 2.01a jz   01/19/11 Added ability to re-assign BD addresses
* 	rkv  03/28/11 XAxiVdma_ChannelInit API is changed.
* 3.02a srt  08/26/11 - XAxiVdma_ChannelErrors API is changed to support for
*			Flush on Frame Sync feature.
*		      - Two flags, XST_VDMA_MISMATCH_ERROR & XAXIVDMA_MIS
*			MATCH_ERROR are added to report error status when
*			Flush on Frame Sync feature is enabled.
* 4.00a srt  11/21/11 - XAxiVdma_ChannelSetBufferAddr API is changed to
*			support 32 Frame Stores.
*		      - XAxiVdma_ChannelConfig API is changed to support
*			modified Park Offset Register bits.
*		      - Added APIs:
*			XAxiVdma_ChannelHiFrmAddrEnable()
*			XAxiVdma_ChannelHiFrmAddrDisable()
* 4.01a srt  06/13/12 - Added API:
*			XAxiVdma_ClearChannelErrors()
*			XAxiVdma_ChannelGetEnabledIntr()
*		      - XAxiVdma_ChannelErrors API is changed to remove
*			Mismatch error logic.
*		      - Removed Error checking logic in the APIs. Provided
*			User APIs to do this.
* 4.04a srt  03/03/13 - Changes for IPv5.04a:
*			Support for the GenlockRepeat Control bit (Bit 15)
*                       (CR: 691391)
*	     	- Support for *_ENABLE_DEBUG_INFO_* debug configuration
*			parameters (CR: 703738)
* 4.05a srt  04/26/13 - Added unalignment checks for Hsize and Stride
*			(CR 710279)
*
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/
#include "xaxivdma_hw.h"
#include "xaxivdma_i.h"
#include "xstatus.h"
#include "xaxivdma.h"

/************************** Constant Definitions *****************************/
/* Number of polling loops to do to check for reset completion
 *
 * This number is large enough to cover the maximum transfer length
 *
 * However, if the memory operation being throttled by the system, this number
 * is not large enough
 */
#define XAXIVDMA_RESET_POLLING      1000


/************************** Function Prototypes ******************************/

/* BD APIs, used by this file only
 */
static u32 XAxiVdma_BdRead(XAxiVdma_Bd *BdPtr, int Offset);
static void XAxiVdma_BdWrite(XAxiVdma_Bd *BdPtr, int Offset, u32 Value);
static void XAxiVdma_BdSetNextPtr(XAxiVdma_Bd *BdPtr, u32 NextPtr);
static void XAxiVdma_BdSetAddr(XAxiVdma_Bd *BdPtr, u32 Addr);
static int XAxiVdma_BdSetVsize(XAxiVdma_Bd *BdPtr, int Vsize);
static int XAxiVdma_BdSetHsize(XAxiVdma_Bd *BdPtr, int Vsize);
static int XAxiVdma_BdSetStride(XAxiVdma_Bd *BdPtr, int Stride);
static int XAxiVdma_BdSetFrmDly(XAxiVdma_Bd *BdPtr, int FrmDly);

/*****************************************************************************/
/*
 * Translate virtual address to physical address
 *
 * When port this driver to other RTOS, please change this definition to
 * be consistent with your target system.
 *
 * @param VirtAddr is the virtual address to work on
 *
 * @return
 *   The physical address of the virtual address
 *
 * @note
 *   The virtual address and the physical address are the same here.
 *
 *****************************************************************************/
#define XAXIVDMA_VIRT_TO_PHYS(VirtAddr) \
	(VirtAddr)

/*****************************************************************************/
/**
 * Set the channel to enable access to higher Frame Buffer Addresses (SG=0)
 *
 * @param Channel is the pointer to the channel to work on
 *
 *
 *****************************************************************************/
#define XAxiVdma_ChannelHiFrmAddrEnable(Channel) \
{ \
	XAxiVdma_WriteReg(Channel->ChanBase, \
			XAXIVDMA_HI_FRMBUF_OFFSET, XAXIVDMA_REGINDEX_MASK); \
}

/*****************************************************************************/
/**
 * Set the channel to disable access higher Frame Buffer Addresses (SG=0)
 *
 * @param Channel is the pointer to the channel to work on
 *
 *
 *****************************************************************************/
#define XAxiVdma_ChannelHiFrmAddrDisable(Channel) \
{ \
	XAxiVdma_WriteReg(Channel->ChanBase, \
		XAXIVDMA_HI_FRMBUF_OFFSET, (XAXIVDMA_REGINDEX_MASK >> 1)); \
}

/*****************************************************************************/
/**
 * Initialize a channel of a DMA engine
 *
 * This function initializes the BD ring for this channel
 *
 * @param Channel is the pointer to the DMA channel to work on
 *
 * @return
 *   None
 *
 *****************************************************************************/
void XAxiVdma_ChannelInit(XAxiVdma_Channel *Channel)
{
	int i;
	int NumFrames;
	XAxiVdma_Bd *FirstBdPtr = &(Channel->BDs[0]);
	XAxiVdma_Bd *LastBdPtr;

	/* Initialize the BD variables, so proper memory management
	 * can be done
	 */
	NumFrames = Channel->NumFrames;
	Channel->IsValid = 0;
	Channel->HeadBdPhysAddr = 0;
	Channel->HeadBdAddr = 0;
	Channel->TailBdPhysAddr = 0;
	Channel->TailBdAddr = 0;

	LastBdPtr = &(Channel->BDs[NumFrames - 1]);

	/* Setup the BD ring
	 */
	memset((void *)FirstBdPtr, 0, NumFrames * sizeof(XAxiVdma_Bd));

	for (i = 0; i < NumFrames; i++) {
		XAxiVdma_Bd *BdPtr;
		XAxiVdma_Bd *NextBdPtr;

		BdPtr = &(Channel->BDs[i]);

		/* The last BD connects to the first BD
		 */
		if (i == (NumFrames - 1)) {
			NextBdPtr = FirstBdPtr;
		}
		else {
			NextBdPtr = &(Channel->BDs[i + 1]);
		}

		XAxiVdma_BdSetNextPtr(BdPtr,
				XAXIVDMA_VIRT_TO_PHYS((UINTPTR)NextBdPtr));
	}

	Channel->AllCnt = NumFrames;

	/* Setup the BD addresses so that access the head/tail BDs fast
	 *
	 */
	Channel->HeadBdAddr = (UINTPTR)FirstBdPtr;
	Channel->HeadBdPhysAddr = XAXIVDMA_VIRT_TO_PHYS((UINTPTR)FirstBdPtr);

	Channel->TailBdAddr = (UINTPTR)LastBdPtr;
	Channel->TailBdPhysAddr = XAXIVDMA_VIRT_TO_PHYS((UINTPTR)LastBdPtr);


	Channel->IsValid = 1;

	return;
}

/*****************************************************************************/
/**
 * This function checks whether reset operation is done
 *
 * @param Channel is the pointer to the DMA channel to work on
 *
 * @return
 * - 0 if reset is done
 * - 1 if reset is still going
 *
 *****************************************************************************/
int XAxiVdma_ChannelResetNotDone(XAxiVdma_Channel *Channel)
{
	return (XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET) &
	        XAXIVDMA_CR_RESET_MASK);
}

/*****************************************************************************/
/**
 * This function resets one DMA channel
 *
 * The registers will be default values after the reset
 *
 * @param Channel is the pointer to the DMA channel to work on
 *
 * @return
 *  None
 *
 *****************************************************************************/
void XAxiVdma_ChannelReset(XAxiVdma_Channel *Channel)
{
	XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET,
	    XAXIVDMA_CR_RESET_MASK);

	return;
}

/*****************************************************************************/
/*
 * Check whether a DMA channel is running
 *
 * @param Channel is the pointer to the channel to work on
 *
 * @return
 * - non zero if the channel is running
 * - 0 is the channel is idle
 *
 *****************************************************************************/
int XAxiVdma_ChannelIsRunning(XAxiVdma_Channel *Channel)
{
	u32 Bits;

	/* If halted bit set, channel is not running
	 */
	Bits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_SR_OFFSET) &
	          XAXIVDMA_SR_HALTED_MASK;

	if (Bits) {
		return 0;
	}

	/* If Run/Stop bit low, then channel is not running
	 */
	Bits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET) &
	          XAXIVDMA_CR_RUNSTOP_MASK;

	if (!Bits) {
		return 0;
	}

	return 1;
}

/*****************************************************************************/
/**
 * Check whether a DMA channel is busy
 *
 * @param Channel is the pointer to the channel to work on
 *
 * @return
 * - non zero if the channel is busy
 * - 0 is the channel is idle
 *
 *****************************************************************************/
int XAxiVdma_ChannelIsBusy(XAxiVdma_Channel *Channel)
{
	u32 Bits;

	/* If the channel is idle, then it is not busy
	 */
	Bits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_SR_OFFSET) &
	          XAXIVDMA_SR_IDLE_MASK;

	if (Bits) {
		return 0;
	}

	/* If the channel is halted, then it is not busy
	 */
	Bits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_SR_OFFSET) &
	          XAXIVDMA_SR_HALTED_MASK;

	if (Bits) {
		return 0;
	}

	/* Otherwise, it is busy
	 */
	return 1;
}

/*****************************************************************************/
/*
 * Check DMA channel errors
 *
 * @param Channel is the pointer to the channel to work on
 *
 * @return
 *  	Error bits of the channel, 0 means no errors
 *
 *****************************************************************************/
u32 XAxiVdma_ChannelErrors(XAxiVdma_Channel *Channel)
{
	return (XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_SR_OFFSET)
			& XAXIVDMA_SR_ERR_ALL_MASK);
}

/*****************************************************************************/
/*
 * Clear DMA channel errors
 *
 * @param Channel is the pointer to the channel to work on
 * @param ErrorMask is the mask of error bits to clear.
 *
 * @return
 *  	None
 *
 *****************************************************************************/
void XAxiVdma_ClearChannelErrors(XAxiVdma_Channel *Channel, u32 ErrorMask)
{
	u32 SrBits;

	/* Write on Clear bits */
        SrBits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_SR_OFFSET)
                        | ErrorMask;

	XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_SR_OFFSET,
	    SrBits);

	return;
}

/*****************************************************************************/
/**
 * Get the current status of a channel
 *
 * @param Channel is the pointer to the channel to work on
 *
 * @return
 * The status of the channel
 *
 *****************************************************************************/
u32 XAxiVdma_ChannelGetStatus(XAxiVdma_Channel *Channel)
{
	return XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_SR_OFFSET);
}

/*****************************************************************************/
/**
 * Set the channel to run in parking mode
 *
 * @param Channel is the pointer to the channel to work on
 *
 * @return
 *   - XST_SUCCESS if everything is fine
 *   - XST_FAILURE if hardware is not running
 *
 *****************************************************************************/
int XAxiVdma_ChannelStartParking(XAxiVdma_Channel *Channel)
{
	u32 CrBits;

	if (!XAxiVdma_ChannelIsRunning(Channel)) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Channel is not running, cannot start park mode\r\n");

		return XST_FAILURE;
	}

	CrBits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET) &
	            ~XAXIVDMA_CR_TAIL_EN_MASK;

	XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET,
	    CrBits);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * Set the channel to run in circular mode, exiting parking mode
 *
 * @param Channel is the pointer to the channel to work on
 *
 * @return
 *   None
 *
 *****************************************************************************/
void XAxiVdma_ChannelStopParking(XAxiVdma_Channel *Channel)
{
	u32 CrBits;

	CrBits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET) |
	            XAXIVDMA_CR_TAIL_EN_MASK;

	XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET,
	    CrBits);

	return;
}

/*****************************************************************************/
/**
 * Set the channel to run in frame count enable mode
 *
 * @param Channel is the pointer to the channel to work on
 *
 * @return
 *   None
 *
 *****************************************************************************/
void XAxiVdma_ChannelStartFrmCntEnable(XAxiVdma_Channel *Channel)
{
	u32 CrBits;

	CrBits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET) |
	            XAXIVDMA_CR_FRMCNT_EN_MASK;

	XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET,
	    CrBits);

	return;
}

/*****************************************************************************/
/**
 * Setup BD addresses to a different memory region
 *
 * In some systems, it is convenient to put BDs into a certain region of the
 * memory. This function enables that.
 *
 * @param Channel is the pointer to the channel to work on
 * @param BdAddrPhys is the physical starting address for BDs
 * @param BdAddrVirt is the Virtual starting address for BDs. For systems that
 *         do not use MMU, then virtual address is the same as physical address
 *
 * @return
 * - XST_SUCCESS for a successful setup
 * - XST_DEVICE_BUSY if the DMA channel is not idle, BDs are still being used
 *
 * @notes
 * We assume that the memory region starting from BdAddrPhys is large enough
 * to hold all the BDs.
 *
 *****************************************************************************/
int XAxiVdma_ChannelSetBdAddrs(XAxiVdma_Channel *Channel, UINTPTR BdAddrPhys,
		UINTPTR BdAddrVirt)
{
	int NumFrames = Channel->AllCnt;
	int i;
	UINTPTR NextPhys = BdAddrPhys;
	UINTPTR CurrVirt = BdAddrVirt;

	if (Channel->HasSG && XAxiVdma_ChannelIsBusy(Channel)) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Channel is busy, cannot setup engine for transfer\r\n");

		return XST_DEVICE_BUSY;
	}

	memset((void *)BdAddrPhys, 0, NumFrames * sizeof(XAxiVdma_Bd));
	memset((void *)BdAddrVirt, 0, NumFrames * sizeof(XAxiVdma_Bd));

	/* Set up the BD link list */
	for (i = 0; i < NumFrames; i++) {
		XAxiVdma_Bd *BdPtr;

		BdPtr = (XAxiVdma_Bd *)CurrVirt;

		/* The last BD connects to the first BD
		 */
		if (i == (NumFrames - 1)) {
			NextPhys = BdAddrPhys;
		}
		else {
			NextPhys += sizeof(XAxiVdma_Bd);
		}

		XAxiVdma_BdSetNextPtr(BdPtr, NextPhys);
		CurrVirt += sizeof(XAxiVdma_Bd);
	}

	/* Setup the BD addresses so that access the head/tail BDs fast
	 *
	 */
	Channel->HeadBdPhysAddr = BdAddrPhys;
	Channel->HeadBdAddr = BdAddrVirt;
	Channel->TailBdPhysAddr = BdAddrPhys +
	                          (NumFrames - 1) * sizeof(XAxiVdma_Bd);
	Channel->TailBdAddr = BdAddrVirt +
	                          (NumFrames - 1) * sizeof(XAxiVdma_Bd);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * Start a transfer
 *
 * This function setup the DMA engine and start the engine to do the transfer.
 *
 * @param Channel is the pointer to the channel to work on
 * @param ChannelCfgPtr is the pointer to the setup structure
 *
 * @return
 * - XST_SUCCESS for a successful submission
 * - XST_FAILURE if channel has not being initialized
 * - XST_DEVICE_BUSY if the DMA channel is not idle, BDs are still being used
 * - XST_INVAID_PARAM if parameters in config structure not valid
 *
 *****************************************************************************/
int XAxiVdma_ChannelStartTransfer(XAxiVdma_Channel *Channel,
    XAxiVdma_ChannelSetup *ChannelCfgPtr)
{
	int Status;

	if (!Channel->IsValid) {
		xdbg_printf(XDBG_DEBUG_ERROR, "Channel not initialized\r\n");

		return XST_FAILURE;
	}

	if (Channel->HasSG && XAxiVdma_ChannelIsBusy(Channel)) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Channel is busy, cannot setup engine for transfer\r\n");

		return XST_DEVICE_BUSY;
	}

	Status = XAxiVdma_ChannelConfig(Channel, ChannelCfgPtr);
	if (Status != XST_SUCCESS) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Channel config failed %d\r\n", Status);

		return Status;
	}

	Status = XAxiVdma_ChannelSetBufferAddr(Channel,
	    ChannelCfgPtr->FrameStoreStartAddr, Channel->AllCnt);
	if (Status != XST_SUCCESS) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Channel setup buffer addr failed %d\r\n", Status);

		return Status;
	}

	Status = XAxiVdma_ChannelStart(Channel);
	if (Status != XST_SUCCESS) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Channel start failed %d\r\n", Status);

		return Status;
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * Configure one DMA channel using the configuration structure
 *
 * Setup the control register and BDs, however, BD addresses are not set.
 *
 * @param Channel is the pointer to the channel to work on
 * @param ChannelCfgPtr is the pointer to the setup structure
 *
 * @return
 * - XST_SUCCESS if successful
 * - XST_FAILURE if channel has not being initialized
 * - XST_DEVICE_BUSY if the DMA channel is not idle
 * - XST_INVALID_PARAM if fields in ChannelCfgPtr is not valid
 *
 *****************************************************************************/
int XAxiVdma_ChannelConfig(XAxiVdma_Channel *Channel,
        XAxiVdma_ChannelSetup *ChannelCfgPtr)
{
	u32 CrBits;
	int i;
	int NumBds;
	int Status;
	u32 hsize_align;
	u32 stride_align;

	if (!Channel->IsValid) {
		xdbg_printf(XDBG_DEBUG_ERROR, "Channel not initialized\r\n");

		return XST_FAILURE;
	}

	if (Channel->HasSG && XAxiVdma_ChannelIsBusy(Channel)) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Channel is busy, cannot config!\r\n");

		return XST_DEVICE_BUSY;
	}

	Channel->Vsize = ChannelCfgPtr->VertSizeInput;

	/* Check whether Hsize is properly aligned */
	if (Channel->direction == XAXIVDMA_WRITE) {
		if (ChannelCfgPtr->HoriSizeInput < Channel->WordLength) {
			hsize_align = (u32)Channel->WordLength;
		} else {
			hsize_align =
				(u32)(ChannelCfgPtr->HoriSizeInput % Channel->WordLength);
			if (hsize_align > 0)
				hsize_align = (Channel->WordLength - hsize_align);
		}
	} else {
		if (ChannelCfgPtr->HoriSizeInput < Channel->WordLength) {
			hsize_align = (u32)Channel->WordLength;
		} else {
			hsize_align =
				(u32)(ChannelCfgPtr->HoriSizeInput % Channel->StreamWidth);
			if (hsize_align > 0)
				hsize_align = (Channel->StreamWidth - hsize_align);
		}
	}

	/* Check whether Stride is properly aligned */
	if (ChannelCfgPtr->Stride < Channel->WordLength) {
		stride_align = (u32)Channel->WordLength;
	} else {
		stride_align = (u32)(ChannelCfgPtr->Stride % Channel->WordLength);
		if (stride_align > 0)
			stride_align = (Channel->WordLength - stride_align);
	}

	/* If hardware has no DRE, then Hsize and Stride must
	 * be word-aligned
	 */
	if (!Channel->HasDRE) {
		if (hsize_align != 0) {
			/* Adjust hsize to multiples of stream/mm data width*/
			ChannelCfgPtr->HoriSizeInput += hsize_align;
		}
		if (stride_align != 0) {
			/* Adjust stride to multiples of stream/mm data width*/
			ChannelCfgPtr->Stride += stride_align;
		}
	}

	Channel->Hsize = ChannelCfgPtr->HoriSizeInput;

	CrBits = XAxiVdma_ReadReg(Channel->ChanBase,
	     XAXIVDMA_CR_OFFSET);

	CrBits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET) &
	    ~(XAXIVDMA_CR_TAIL_EN_MASK | XAXIVDMA_CR_SYNC_EN_MASK |
	      XAXIVDMA_CR_FRMCNT_EN_MASK | XAXIVDMA_CR_RD_PTR_MASK);

	if (ChannelCfgPtr->EnableCircularBuf) {
		CrBits |= XAXIVDMA_CR_TAIL_EN_MASK;
	}
	else {
		/* Park mode */
		u32 FrmBits;
		u32 RegValue;

		if ((!XAxiVdma_ChannelIsRunning(Channel)) &&
		    Channel->HasSG) {
			xdbg_printf(XDBG_DEBUG_ERROR,
			    "Channel is not running, cannot set park mode\r\n");

			return XST_INVALID_PARAM;
		}

		if (ChannelCfgPtr->FixedFrameStoreAddr > XAXIVDMA_FRM_MAX) {
			xdbg_printf(XDBG_DEBUG_ERROR,
			    "Invalid frame to park on %d\r\n",
			    ChannelCfgPtr->FixedFrameStoreAddr);

			return XST_INVALID_PARAM;
		}

		if (Channel->IsRead) {
			FrmBits = ChannelCfgPtr->FixedFrameStoreAddr &
			              XAXIVDMA_PARKPTR_READREF_MASK;

			RegValue = XAxiVdma_ReadReg(Channel->InstanceBase,
			              XAXIVDMA_PARKPTR_OFFSET);

			RegValue &= ~XAXIVDMA_PARKPTR_READREF_MASK;

			RegValue |= FrmBits;

			XAxiVdma_WriteReg(Channel->InstanceBase,
			    XAXIVDMA_PARKPTR_OFFSET, RegValue);
		}
		else {
			FrmBits = ChannelCfgPtr->FixedFrameStoreAddr <<
			            XAXIVDMA_WRTREF_SHIFT;

			FrmBits &= XAXIVDMA_PARKPTR_WRTREF_MASK;

			RegValue = XAxiVdma_ReadReg(Channel->InstanceBase,
			              XAXIVDMA_PARKPTR_OFFSET);

			RegValue &= ~XAXIVDMA_PARKPTR_WRTREF_MASK;

			RegValue |= FrmBits;

			XAxiVdma_WriteReg(Channel->InstanceBase,
			    XAXIVDMA_PARKPTR_OFFSET, RegValue);
		}
	}

	if (ChannelCfgPtr->EnableSync) {
		if (Channel->GenLock != XAXIVDMA_GENLOCK_MASTER)
			CrBits |= XAXIVDMA_CR_SYNC_EN_MASK;
	}

	if (ChannelCfgPtr->GenLockRepeat) {
		if ((Channel->GenLock == XAXIVDMA_GENLOCK_MASTER) ||
			(Channel->GenLock == XAXIVDMA_DYN_GENLOCK_MASTER))
			CrBits |= XAXIVDMA_CR_GENLCK_RPT_MASK;
	}

	if (ChannelCfgPtr->EnableFrameCounter) {
		CrBits |= XAXIVDMA_CR_FRMCNT_EN_MASK;
	}

	CrBits |= (ChannelCfgPtr->PointNum << XAXIVDMA_CR_RD_PTR_SHIFT) &
	    XAXIVDMA_CR_RD_PTR_MASK;

	/* Write the control register value out
	 */
	XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET,
	    CrBits);

	if (Channel->HasSG) {
		/* Setup the information in BDs
		 *
		 * All information is available except the buffer addrs
		 * Buffer addrs are set through XAxiVdma_ChannelSetBufferAddr()
		 */
		NumBds = Channel->AllCnt;

		for (i = 0; i < NumBds; i++) {
			XAxiVdma_Bd *BdPtr = (XAxiVdma_Bd *)(Channel->HeadBdAddr +
			         i * sizeof(XAxiVdma_Bd));

			Status = XAxiVdma_BdSetVsize(BdPtr,
			             ChannelCfgPtr->VertSizeInput);
			if (Status != XST_SUCCESS) {
				xdbg_printf(XDBG_DEBUG_ERROR,
				    "Set vertical size failed %d\r\n", Status);

				return Status;
			}

			Status = XAxiVdma_BdSetHsize(BdPtr,
			    ChannelCfgPtr->HoriSizeInput);
			if (Status != XST_SUCCESS) {
				xdbg_printf(XDBG_DEBUG_ERROR,
				    "Set horizontal size failed %d\r\n", Status);

				return Status;
			}

			Status = XAxiVdma_BdSetStride(BdPtr,
			    ChannelCfgPtr->Stride);
			if (Status != XST_SUCCESS) {
				xdbg_printf(XDBG_DEBUG_ERROR,
				    "Set stride size failed %d\r\n", Status);

				return Status;
			}

			Status = XAxiVdma_BdSetFrmDly(BdPtr,
			ChannelCfgPtr->FrameDelay);
			if (Status != XST_SUCCESS) {
				xdbg_printf(XDBG_DEBUG_ERROR,
				    "Set frame delay failed %d\r\n", Status);

				return Status;
			}
		}
	}
	else {   /* direct register mode */
		if ((ChannelCfgPtr->VertSizeInput > XAXIVDMA_MAX_VSIZE) ||
		    (ChannelCfgPtr->VertSizeInput <= 0) ||
		    (ChannelCfgPtr->HoriSizeInput > XAXIVDMA_MAX_HSIZE) ||
		    (ChannelCfgPtr->HoriSizeInput <= 0) ||
		    (ChannelCfgPtr->Stride > XAXIVDMA_MAX_STRIDE) ||
		    (ChannelCfgPtr->Stride <= 0) ||
		    (ChannelCfgPtr->FrameDelay < 0) ||
		    (ChannelCfgPtr->FrameDelay > XAXIVDMA_FRMDLY_MAX)) {

			return XST_INVALID_PARAM;
		}

		XAxiVdma_WriteReg(Channel->StartAddrBase,
		    XAXIVDMA_HSIZE_OFFSET, ChannelCfgPtr->HoriSizeInput);

		XAxiVdma_WriteReg(Channel->StartAddrBase,
		    XAXIVDMA_STRD_FRMDLY_OFFSET,
		    (ChannelCfgPtr->FrameDelay << XAXIVDMA_FRMDLY_SHIFT) |
		    ChannelCfgPtr->Stride);
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * Configure buffer addresses for one DMA channel
 *
 * The buffer addresses are physical addresses.
 * Access to 32 Frame Buffer Addresses in direct mode is done through
 * XAxiVdma_ChannelHiFrmAddrEnable/Disable Functions.
 * 0 - Access Bank0 Registers (0x5C - 0x98)
 * 1 - Access Bank1 Registers (0x5C - 0x98)
 *
 * @param Channel is the pointer to the channel to work on
 * @param BufferAddrSet is the set of addresses for the transfers
 * @param NumFrames is the number of frames to set the address
 *
 * @return
 * - XST_SUCCESS if successful
 * - XST_FAILURE if channel has not being initialized
 * - XST_DEVICE_BUSY if the DMA channel is not idle, BDs are still being used
 * - XST_INVAID_PARAM if buffer address not valid, for example, unaligned
 * address with no DRE built in the hardware
 *
 *****************************************************************************/
int XAxiVdma_ChannelSetBufferAddr(XAxiVdma_Channel *Channel,
        UINTPTR *BufferAddrSet, int NumFrames)
{
	int i;
	u32 WordLenBits;
	int HiFrmAddr = 0;
	int FrmBound;
	if (Channel->AddrWidth > 32) {
		FrmBound = (XAXIVDMA_MAX_FRAMESTORE_64)/2 - 1;
	} else {
		FrmBound = (XAXIVDMA_MAX_FRAMESTORE)/2 - 1;
	}
	int Loop16 = 0;

	if (!Channel->IsValid) {
		xdbg_printf(XDBG_DEBUG_ERROR, "Channel not initialized\r\n");

		return XST_FAILURE;
	}

	WordLenBits = (u32)(Channel->WordLength - 1);

	/* If hardware has no DRE, then buffer addresses must
	 * be word-aligned
	 */
	for (i = 0; i < NumFrames; i++) {
		if (!Channel->HasDRE) {
			if (BufferAddrSet[i] & WordLenBits) {
				xdbg_printf(XDBG_DEBUG_ERROR,
				    "Unaligned address %d: %x without DRE\r\n",
				    i, BufferAddrSet[i]);

				return XST_INVALID_PARAM;
			}
		}
	}

	for (i = 0; i < NumFrames; i++, Loop16++) {
		XAxiVdma_Bd *BdPtr = (XAxiVdma_Bd *)(Channel->HeadBdAddr +
		         i * sizeof(XAxiVdma_Bd));

		if (Channel->HasSG) {
			XAxiVdma_BdSetAddr(BdPtr, BufferAddrSet[i]);
		}
		else {
			if ((i > FrmBound) && !HiFrmAddr) {
				XAxiVdma_ChannelHiFrmAddrEnable(Channel);
				HiFrmAddr = 1;
				Loop16 = 0;
			}

			if (Channel->AddrWidth > 32) {
				/* For a 40-bit address XAXIVDMA_MAX_FRAMESTORE
				 * value should be set to 16 */
				XAxiVdma_WriteReg(Channel->StartAddrBase,
					XAXIVDMA_START_ADDR_OFFSET +
					Loop16 * XAXIVDMA_START_ADDR_LEN + i*4,
					LOWER_32_BITS(BufferAddrSet[i]));

				XAxiVdma_WriteReg(Channel->StartAddrBase,
					XAXIVDMA_START_ADDR_MSB_OFFSET +
					Loop16 * XAXIVDMA_START_ADDR_LEN + i*4,
					UPPER_32_BITS((u64)BufferAddrSet[i]));
			} else {
				XAxiVdma_WriteReg(Channel->StartAddrBase,
					XAXIVDMA_START_ADDR_OFFSET +
					Loop16 * XAXIVDMA_START_ADDR_LEN,
					BufferAddrSet[i]);
			}


			if ((NumFrames > FrmBound) && (i == (NumFrames - 1)))
				XAxiVdma_ChannelHiFrmAddrDisable(Channel);
		}
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * Start one DMA channel
 *
 * @param Channel is the pointer to the channel to work on
 *
 * @return
 * - XST_SUCCESS if successful
 * - XST_FAILURE if channel is not initialized
 * - XST_DMA_ERROR if:
 *   . The DMA channel fails to stop
 *   . The DMA channel fails to start
 * - XST_DEVICE_BUSY is the channel is doing transfers
 *
 *****************************************************************************/
int XAxiVdma_ChannelStart(XAxiVdma_Channel *Channel)
{
	u32 CrBits;

	if (!Channel->IsValid) {
		xdbg_printf(XDBG_DEBUG_ERROR, "Channel not initialized\r\n");

		return XST_FAILURE;
	}

	if (Channel->HasSG && XAxiVdma_ChannelIsBusy(Channel)) {

		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Start DMA channel while channel is busy\r\n");

		return XST_DEVICE_BUSY;
	}

	/* If channel is not running, setup the CDESC register and
	 * set the channel to run
	 */
	if (!XAxiVdma_ChannelIsRunning(Channel)) {

		if (Channel->HasSG) {
			/* Set up the current bd register
			 *
			 * Can only setup current bd register when channel is halted
			 */
			XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_CDESC_OFFSET,
			    Channel->HeadBdPhysAddr);
		}

		/* Start DMA hardware
		 */
		CrBits = XAxiVdma_ReadReg(Channel->ChanBase,
		     XAXIVDMA_CR_OFFSET);

		CrBits = XAxiVdma_ReadReg(Channel->ChanBase,
		     XAXIVDMA_CR_OFFSET) | XAXIVDMA_CR_RUNSTOP_MASK;

		XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET,
		    CrBits);

	}

	if (XAxiVdma_ChannelIsRunning(Channel)) {

		/* Start DMA transfers
		 *
		 */

		if (Channel->HasSG) {
			/* SG mode:
			 * Update the tail pointer so that hardware will start
			 * fetching BDs
			 */
			XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_TDESC_OFFSET,
			   Channel->TailBdPhysAddr);
		}
		else {
			/* Direct register mode:
			 * Update vsize to start the channel
			 */
			XAxiVdma_WriteReg(Channel->StartAddrBase,
			    XAXIVDMA_VSIZE_OFFSET, Channel->Vsize);

		}

		return XST_SUCCESS;
	}
	else {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Failed to start channel %x\r\n",
			    (unsigned int)Channel->ChanBase);

		return XST_DMA_ERROR;
	}
}

/*****************************************************************************/
/**
 * Stop one DMA channel
 *
 * @param Channel is the pointer to the channel to work on
 *
 * @return
 *  None
 *
 *****************************************************************************/
void XAxiVdma_ChannelStop(XAxiVdma_Channel *Channel)
{
	u32 CrBits;

	if (!XAxiVdma_ChannelIsRunning(Channel)) {
		return;
	}

	/* Clear the RS bit in CR register
	 */
	CrBits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET) &
		(~XAXIVDMA_CR_RUNSTOP_MASK);

	XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET, CrBits);

	return;
}

/*****************************************************************************/
/**
 * Dump registers from one DMA channel
 *
 * @param Channel is the pointer to the channel to work on
 *
 * @return
 *  None
 *
 *****************************************************************************/
void XAxiVdma_ChannelRegisterDump(XAxiVdma_Channel *Channel)
{
	xil_printf("Dump register for channel %p:\r\n", (void *)Channel->ChanBase);
	xil_printf("\tControl Reg: %x\r\n",
	    XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET));
	xil_printf("\tStatus Reg: %x\r\n",
	    XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_SR_OFFSET));
	xil_printf("\tCDESC Reg: %x\r\n",
	    XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CDESC_OFFSET));
	xil_printf("\tTDESC Reg: %x\r\n",
	    XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_TDESC_OFFSET));

	return;
}

/*****************************************************************************/
/**
 * Set the frame counter and delay counter for one channel
 *
 * @param Channel is the pointer to the channel to work on
 * @param FrmCnt is the frame counter value to be set
 * @param DlyCnt is the delay counter value to be set
 *
 * @return
 *   - XST_SUCCESS if setup finishes successfully
 *   - XST_FAILURE if channel is not initialized
 *   - XST_INVALID_PARAM if the configuration structure has invalid values
 *   - XST_NO_FEATURE if Frame Counter or Delay Counter is disabled
 *
 *****************************************************************************/
int XAxiVdma_ChannelSetFrmCnt(XAxiVdma_Channel *Channel, u8 FrmCnt, u8 DlyCnt)
{
	u32 CrBits;

	if (!Channel->IsValid) {
		xdbg_printf(XDBG_DEBUG_ERROR, "Channel not initialized\r\n");

		return XST_FAILURE;
	}

	if (!FrmCnt) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Frame counter value must be non-zero\r\n");

		return XST_INVALID_PARAM;
	}

	CrBits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET) &
		~(XAXIVDMA_DELAY_MASK | XAXIVDMA_FRMCNT_MASK);

	if (Channel->DbgFeatureFlags & XAXIVDMA_ENABLE_DBG_FRM_CNTR) {
		CrBits |= (FrmCnt << XAXIVDMA_FRMCNT_SHIFT);
	} else {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Channel Frame counter is disabled\r\n");
		return XST_NO_FEATURE;
	}
	if (Channel->DbgFeatureFlags & XAXIVDMA_ENABLE_DBG_DLY_CNTR) {
		CrBits |= (DlyCnt << XAXIVDMA_DELAY_SHIFT);
	} else {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Channel Delay counter is disabled\r\n");
		return XST_NO_FEATURE;
	}

	XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET,
	    CrBits);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * Get the frame counter and delay counter for both channels
 *
 * @param Channel is the pointer to the channel to work on
 * @param FrmCnt is the pointer for the returning frame counter value
 * @param DlyCnt is the pointer for the returning delay counter value
 *
 * @return
 *  None
 *
 * @note
 *  If FrmCnt return as 0, then the channel is not initialized
 *****************************************************************************/
void XAxiVdma_ChannelGetFrmCnt(XAxiVdma_Channel *Channel, u8 *FrmCnt,
        u8 *DlyCnt)
{
	u32 CrBits;

	if (!Channel->IsValid) {
		xdbg_printf(XDBG_DEBUG_ERROR, "Channel not initialized\r\n");

		*FrmCnt = 0;
		return;
	}

	CrBits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET);

	if (Channel->DbgFeatureFlags & XAXIVDMA_ENABLE_DBG_FRM_CNTR) {
		*FrmCnt = (CrBits & XAXIVDMA_FRMCNT_MASK) >>
				XAXIVDMA_FRMCNT_SHIFT;
	} else {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Channel Frame counter is disabled\r\n");
	}
	if (Channel->DbgFeatureFlags & XAXIVDMA_ENABLE_DBG_DLY_CNTR) {
		*DlyCnt = (CrBits & XAXIVDMA_DELAY_MASK) >>
				XAXIVDMA_DELAY_SHIFT;
	} else {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Channel Delay counter is disabled\r\n");
	}


	return;
}

/*****************************************************************************/
/**
 * Enable interrupts for a channel. Interrupts that are not specified by the
 * interrupt mask are not affected.
 *
 * @param Channel is the pointer to the channel to work on
 * @param IntrType is the interrupt mask for interrupts to be enabled
 *
 * @return
 *  None.
 *
 *****************************************************************************/
void XAxiVdma_ChannelEnableIntr(XAxiVdma_Channel *Channel, u32 IntrType)
{
	u32 CrBits;

	if ((IntrType & XAXIVDMA_IXR_ALL_MASK) == 0) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Enable intr with null intr mask value %x\r\n",
		    (unsigned int)IntrType);

		return;
	}

	CrBits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET) &
	          ~XAXIVDMA_IXR_ALL_MASK;

	CrBits |= IntrType & XAXIVDMA_IXR_ALL_MASK;

	XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET,
	    CrBits);

	return;
}

/*****************************************************************************/
/**
 * Disable interrupts for a channel. Interrupts that are not specified by the
 * interrupt mask are not affected.
 *
 * @param Channel is the pointer to the channel to work on
 * @param IntrType is the interrupt mask for interrupts to be disabled
 *
 * @return
 *  None.
 *
 *****************************************************************************/
void XAxiVdma_ChannelDisableIntr(XAxiVdma_Channel *Channel, u32 IntrType)
{
	u32 CrBits;
	u32 IrqBits;

	if ((IntrType & XAXIVDMA_IXR_ALL_MASK) == 0) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Disable intr with null intr mask value %x\r\n",
		    (unsigned int)IntrType);

		return;
	}

	CrBits = XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET);

	IrqBits = (CrBits & XAXIVDMA_IXR_ALL_MASK) &
	           ~(IntrType & XAXIVDMA_IXR_ALL_MASK);

	CrBits &= ~XAXIVDMA_IXR_ALL_MASK;

	XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET,
	    CrBits | IrqBits);

	return;
}

/*****************************************************************************/
/**
 * Get pending interrupts of a channel.
 *
 * @param Channel is the pointer to the channel to work on
 *
 * @return
 *  The interrupts mask represents pending interrupts.
 *
 *****************************************************************************/
u32 XAxiVdma_ChannelGetPendingIntr(XAxiVdma_Channel *Channel)
{
	return (XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_SR_OFFSET) &
	          XAXIVDMA_IXR_ALL_MASK);
}

/*****************************************************************************/
/**
 * Clear interrupts of a channel. Interrupts that are not specified by the
 * interrupt mask are not affected.
 *
 * @param Channel is the pointer to the channel to work on
 * @param IntrType is the interrupt mask for interrupts to be cleared
 *
 * @return
 *  None.
 *
 *****************************************************************************/
void XAxiVdma_ChannelIntrClear(XAxiVdma_Channel *Channel, u32 IntrType)
{

	if ((IntrType & XAXIVDMA_IXR_ALL_MASK) == 0) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Clear intr with null intr mask value %x\r\n",
		    (unsigned int)IntrType);

		return;
	}

	/* Only interrupts bits are writable in status register
	 */
	XAxiVdma_WriteReg(Channel->ChanBase, XAXIVDMA_SR_OFFSET,
	    IntrType & XAXIVDMA_IXR_ALL_MASK);

	return;
}

/*****************************************************************************/
/**
 * Get the enabled interrupts of a channel.
 *
 * @param Channel is the pointer to the channel to work on
 *
 * @return
 *  The interrupts mask represents pending interrupts.
 *
 *****************************************************************************/
u32 XAxiVdma_ChannelGetEnabledIntr(XAxiVdma_Channel *Channel)
{
	return (XAxiVdma_ReadReg(Channel->ChanBase, XAXIVDMA_CR_OFFSET) &
	          XAXIVDMA_IXR_ALL_MASK);
}

/*********************** BD Functions ****************************************/
/*****************************************************************************/
/*
 * Read one word from BD
 *
 * @param BdPtr is the BD to work on
 * @param Offset is the byte offset to read from
 *
 * @return
 *  The word value
 *
 *****************************************************************************/
static u32 XAxiVdma_BdRead(XAxiVdma_Bd *BdPtr, int Offset)
{
	return (*(u32 *)((UINTPTR)(void *)BdPtr + Offset));
}

/*****************************************************************************/
/*
 * Set one word in BD
 *
 * @param BdPtr is the BD to work on
 * @param Offset is the byte offset to write to
 * @param Value is the value to write to the BD
 *
 * @return
 *  None
 *
 *****************************************************************************/
static void XAxiVdma_BdWrite(XAxiVdma_Bd *BdPtr, int Offset, u32 Value)
{
	*(u32 *)((UINTPTR)(void *)BdPtr + Offset) = Value;

	return;
}

/*****************************************************************************/
/*
 * Set the next ptr from BD
 *
 * @param BdPtr is the BD to work on
 * @param NextPtr is the next ptr to set in BD
 *
 * @return
 *  None
 *
 *****************************************************************************/
static void XAxiVdma_BdSetNextPtr(XAxiVdma_Bd *BdPtr, u32 NextPtr)
{
	XAxiVdma_BdWrite(BdPtr, XAXIVDMA_BD_NDESC_OFFSET, NextPtr);
	return;
}

/*****************************************************************************/
/*
 * Set the start address from BD
 *
 * The address is physical address.
 *
 * @param BdPtr is the BD to work on
 * @param Addr is the address to set in BD
 *
 * @return
 *  None
 *
 *****************************************************************************/
static void XAxiVdma_BdSetAddr(XAxiVdma_Bd *BdPtr, u32 Addr)
{
	XAxiVdma_BdWrite(BdPtr, XAXIVDMA_BD_START_ADDR_OFFSET, Addr);

	return;
}

/*****************************************************************************/
/*
 * Set the vertical size for a BD
 *
 * @param BdPtr is the BD to work on
 * @param Vsize is the vertical size to set in BD
 *
 * @return
 *  - XST_SUCCESS if successful
 *  - XST_INVALID_PARAM if argument Vsize is invalid
 *
 *****************************************************************************/
static int XAxiVdma_BdSetVsize(XAxiVdma_Bd *BdPtr, int Vsize)
{
	if ((Vsize <= 0) || (Vsize > XAXIVDMA_VSIZE_MASK)) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Veritcal size %d is not valid\r\n", Vsize);

		return XST_INVALID_PARAM;
	}

	XAxiVdma_BdWrite(BdPtr, XAXIVDMA_BD_VSIZE_OFFSET, Vsize);
	return XST_SUCCESS;
}

/*****************************************************************************/
/*
 * Set the horizontal size for a BD
 *
 * @param BdPtr is the BD to work on
 * @param Hsize is the horizontal size to set in BD
 *
 * @return
 *  - XST_SUCCESS if successful
 *  - XST_INVALID_PARAM if argument Hsize is invalid
 *
 *****************************************************************************/
static int XAxiVdma_BdSetHsize(XAxiVdma_Bd *BdPtr, int Hsize)
{
	if ((Hsize <= 0) || (Hsize > XAXIVDMA_HSIZE_MASK)) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Horizontal size %d is not valid\r\n", Hsize);

		return XST_INVALID_PARAM;
	}

	XAxiVdma_BdWrite(BdPtr, XAXIVDMA_BD_HSIZE_OFFSET, Hsize);
	return XST_SUCCESS;
}

/*****************************************************************************/
/*
 * Set the stride size for a BD
 *
 * @param BdPtr is the BD to work on
 * @param Stride is the stride size to set in BD
 *
 * @return
 *  - XST_SUCCESS if successful
 *  - XST_INVALID_PARAM if argument Stride is invalid
 *
 *****************************************************************************/
static int XAxiVdma_BdSetStride(XAxiVdma_Bd *BdPtr, int Stride)
{
	u32 Bits;

	if ((Stride <= 0) || (Stride > XAXIVDMA_STRIDE_MASK)) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Stride size %d is not valid\r\n", Stride);

		return XST_INVALID_PARAM;
	}

	Bits = XAxiVdma_BdRead(BdPtr, XAXIVDMA_BD_STRIDE_OFFSET) &
	        ~XAXIVDMA_STRIDE_MASK;

	XAxiVdma_BdWrite(BdPtr, XAXIVDMA_BD_STRIDE_OFFSET, Bits | Stride);

	return XST_SUCCESS;
}

/*****************************************************************************/
/*
 * Set the frame delay for a BD
 *
 * @param BdPtr is the BD to work on
 * @param FrmDly is the frame delay value to set in BD
 *
 * @return
 *  - XST_SUCCESS if successful
 *  - XST_INVALID_PARAM if argument FrmDly is invalid
 *
 *****************************************************************************/
static int XAxiVdma_BdSetFrmDly(XAxiVdma_Bd *BdPtr, int FrmDly)
{
	u32 Bits;

	if ((FrmDly < 0) || (FrmDly > XAXIVDMA_FRMDLY_MAX)) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "FrmDly size %d is not valid\r\n", FrmDly);

		return XST_INVALID_PARAM;
	}

	Bits = XAxiVdma_BdRead(BdPtr, XAXIVDMA_BD_STRIDE_OFFSET) &
	        ~XAXIVDMA_FRMDLY_MASK;

	XAxiVdma_BdWrite(BdPtr, XAXIVDMA_BD_STRIDE_OFFSET,
	    Bits | (FrmDly << XAXIVDMA_FRMDLY_SHIFT));

	return XST_SUCCESS;
}
/** @} */
