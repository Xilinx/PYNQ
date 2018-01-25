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
*
* @file xaxidma_bdring.c
* @addtogroup axidma_v9_0
* @{
*
* This file implements buffer descriptor ring related functions. For more
* information on how to manage the BD ring, please see xaxidma.h.
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
* 5.00a srt  08/25/11 Added support for memory barrier.
* 6.00a srt  01/24/12 Added support for Multi-Channel DMA.
*		      - New API
*			* XAxiDma_UpdateBdRingCDesc(XAxiDma_BdRing * RingPtr,
*						int RingIndex)
*		      - Changed APIs
*			* XAxiDma_StartBdRingHw(XAxiDma_BdRing * RingPtr,
*					int RingIndex)
*			* XAxiDma_BdRingStart(XAxiDma_BdRing * RingPtr,
*						 int RingIndex)
*			* XAxiDma_BdRingToHw(XAxiDma_BdRing * RingPtr,
*        			int NumBd, XAxiDma_Bd * BdSetPtr, int RingIndex)
*			* XAxiDma_BdRingDumpRegs(XAxiDma_BdRing * RingPtr,
*						 int RingIndex)
*			* XAxiDma_BdRingSnapShotCurrBd(XAxiDma_BdRing * RingPtr,
*						 int RingIndex)
* 7.00a srt  06/18/12  All the APIs changed in v6_00_a are reverted back for
*		       backward compatibility.
*
*
* </pre>
******************************************************************************/

/***************************** Include Files *********************************/

#include "xaxidma_bdring.h"

/************************** Constant Definitions *****************************/
/* Use 100 milliseconds for 100 MHz
 * This interval is sufficient for hardware to finish 40MB transfer with
 * 32-bit bus.
 */
#define XAXIDMA_STOP_TIMEOUT	500000   /* about 100 milliseconds on 100MHz */

/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/
/* The following macros are helper functions inside this file.
 */

/******************************************************************************
 * Compute the physical address of a descriptor from its virtual address
 *
 * @param	BdPtr is the virtual address of the BD
 *
 * @returns	Physical address of BdPtr
 *
 * @note	Assume virtual and physical mapping is flat.
 *		RingPtr is an implicit parameter
 *
 *****************************************************************************/
#define XAXIDMA_VIRT_TO_PHYS(BdPtr) \
	((UINTPTR)(BdPtr) + (RingPtr->FirstBdPhysAddr - RingPtr->FirstBdAddr))

/******************************************************************************
 * Move the BdPtr argument ahead an arbitrary number of BDs wrapping around
 * to the beginning of the ring if needed.
 *
 * We know if a wraparound should occur if the new BdPtr is greater than
 * the high address in the ring OR if the new BdPtr crosses the 0xFFFFFFFF
 * to 0 boundary.
 *
 * @param	RingPtr is the ring BdPtr appears in
 * @param	BdPtr on input is the starting BD position and on output is the
 *		final BD position
 * @param	NumBd is the number of BD spaces to increment
 *
 * @returns	None
 *
 * @note	This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
#define XAXIDMA_RING_SEEKAHEAD(RingPtr, BdPtr, NumBd)                \
    {                                                                \
        UINTPTR Addr = (UINTPTR)(void *)(BdPtr);                                     \
                                                                     \
        Addr += ((RingPtr)->Separation * (NumBd));                   \
        if ((Addr > (RingPtr)->LastBdAddr) || ((UINTPTR)(BdPtr) > Addr)) \
        {                                                            \
            Addr -= (RingPtr)->Length;                               \
        }                                                            \
                                                                     \
        (BdPtr) = (XAxiDma_Bd*)(void *)Addr;                                 \
    }
/******************************************************************************
 * Move the BdPtr argument backwards an arbitrary number of BDs wrapping
 * around to the end of the ring if needed.
 *
 * We know if a wraparound should occur if the new BdPtr is less than
 * the base address in the ring OR if the new BdPtr crosses the 0xFFFFFFFF
 * to 0 boundary.
 *
 * @param	RingPtr is the ring BdPtr appears in
 * @param	BdPtr on input is the starting BD position and on output is the
 *		final BD position
 * @param	NumBd is the number of BD spaces to increment
 *
 * @returns	None
 *
 * @note	This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
#define XAXIDMA_RING_SEEKBACK(RingPtr, BdPtr, NumBd)                  \
    {                                                                 \
        UINTPTR Addr = (UINTPTR)(BdPtr);                                      \
                                                                      \
        Addr -= ((RingPtr)->Separation * (NumBd));                    \
        if ((Addr < (RingPtr)->FirstBdAddr) || ((UINTPTR)(BdPtr) < Addr)) \
        {                                                             \
            Addr += (RingPtr)->Length;                                \
        }                                                             \
                                                                      \
        (BdPtr) = (XAxiDma_Bd*)Addr;                                  \
    }

/************************** Function Prototypes ******************************/

/************************** Variable Definitions *****************************/


/*****************************************************************************/
/**
 * Update Current Descriptor
 *
 * @param	RingPtr is the Channel instance to be worked on
 *
 * @return
 *		- XST_SUCCESS upon success
 *		- XST_DMA_ERROR if no valid BD available to put into current
 *		BD register
 *
 * @note	This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
int XAxiDma_UpdateBdRingCDesc(XAxiDma_BdRing* RingPtr)
{
	u32 RegBase;
	UINTPTR BdPtr;
	int RingIndex = RingPtr->RingIndex;

	/* BD list has yet to be created for this channel */
	if (RingPtr->AllCnt == 0) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingStart: no bds\r\n");

		return XST_DMA_SG_NO_LIST;
	}

	/* Do nothing if already started */
	if (RingPtr->RunState == AXIDMA_CHANNEL_NOT_HALTED) {
		/* Need to update tail pointer if needed (Engine is not
		 * transferring)
		 */
		return XST_SUCCESS;
	}

	if (!XAxiDma_BdRingHwIsStarted(RingPtr)) {
		/* If hardware is not running, then we need to put a valid current
		 * BD pointer to the current BD register before start the hardware
		 */
		RegBase = RingPtr->ChanBase;

		/* Put a valid BD pointer in the current BD pointer register
		 * So, the hardware is ready to go when tail BD pointer is updated
		 */
		BdPtr = (UINTPTR)(void *)(RingPtr->BdaRestart);

		if (!XAxiDma_BdHwCompleted(BdPtr)) {
			if (RingPtr->IsRxChannel) {
				if (!RingIndex) {
					XAxiDma_WriteReg(RegBase,
							 XAXIDMA_CDESC_OFFSET,
							 (u32)(BdPtr & XAXIDMA_DESC_LSB_MASK));
					if (RingPtr->Addr_ext)
						XAxiDma_WriteReg(RegBase,
								 XAXIDMA_CDESC_MSB_OFFSET,
								 UPPER_32_BITS(BdPtr));
				}
				else {
					XAxiDma_WriteReg(RegBase,
					(XAXIDMA_RX_CDESC0_OFFSET +
					(RingIndex - 1) * XAXIDMA_RX_NDESC_OFFSET),
					(u32)(BdPtr & XAXIDMA_DESC_LSB_MASK));
					if (RingPtr->Addr_ext)
						XAxiDma_WriteReg(RegBase,
								 (XAXIDMA_RX_CDESC0_MSB_OFFSET +
								 (RingIndex - 1) * XAXIDMA_RX_NDESC_OFFSET),
								 UPPER_32_BITS(BdPtr));
				}
			}
			else {
				XAxiDma_WriteReg(RegBase,
						 XAXIDMA_CDESC_OFFSET,
						 (u32)(BdPtr & XAXIDMA_DESC_LSB_MASK));
				if (RingPtr->Addr_ext)
					XAxiDma_WriteReg(RegBase, XAXIDMA_CDESC_MSB_OFFSET,
							 UPPER_32_BITS(BdPtr));
			}
		}
		else {
			/* Look for an uncompleted BD
			*/
			while (XAxiDma_BdHwCompleted(BdPtr)) {
				BdPtr = XAxiDma_BdRingNext(RingPtr, BdPtr);

				if ((UINTPTR)BdPtr == (UINTPTR) RingPtr->BdaRestart) {
					xdbg_printf(XDBG_DEBUG_ERROR,
					"StartBdRingHw: Cannot find valid cdesc\r\n");

					return XST_DMA_ERROR;
				}

				if (!XAxiDma_BdHwCompleted(BdPtr)) {
					if (RingPtr->IsRxChannel) {
						if (!RingIndex) {
							XAxiDma_WriteReg(RegBase,
								XAXIDMA_CDESC_OFFSET,(u32) (BdPtr & XAXIDMA_DESC_LSB_MASK));
							if (RingPtr->Addr_ext)
								XAxiDma_WriteReg(RegBase, XAXIDMA_CDESC_MSB_OFFSET,
									UPPER_32_BITS(BdPtr));
						}
						else {
							XAxiDma_WriteReg(RegBase,
								(XAXIDMA_RX_CDESC0_OFFSET +
								(RingIndex - 1) * XAXIDMA_RX_NDESC_OFFSET),
								(u32)(BdPtr & XAXIDMA_DESC_LSB_MASK));
							if (RingPtr->Addr_ext)
								XAxiDma_WriteReg(RegBase,
									(XAXIDMA_RX_CDESC0_MSB_OFFSET +
									(RingIndex - 1) * XAXIDMA_RX_NDESC_OFFSET),
									UPPER_32_BITS(BdPtr));
						}
					}
					else {
						XAxiDma_WriteReg(RegBase,
								XAXIDMA_CDESC_OFFSET, (u32)(BdPtr & XAXIDMA_DESC_LSB_MASK));
						if (RingPtr->Addr_ext)
							XAxiDma_WriteReg(RegBase, XAXIDMA_CDESC_MSB_OFFSET,
									 UPPER_32_BITS(BdPtr));
					}
					break;
				}
			}
		}

	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * Using a memory segment allocated by the caller, This fundtion creates and
 * setup the BD ring.
 *
 * @param	RingPtr is the BD ring instance to be worked on.
 * @param	PhysAddr is the physical base address of application memory
 *		region.
 * @param	VirtAddr is the virtual base address of the application memory
 *		region.If address translation is not being utilized, then
 *		VirtAddr should be equivalent to PhysAddr.
 * @param	Alignment governs the byte alignment of individual BDs. This
 *		function will enforce a minimum alignment of
 *		XAXIDMA_BD_MINIMUM_ALIGNMENT bytes with no maximum as long as
 *		it is specified as a power of 2.
 * @param	BdCount is the number of BDs to setup in the application memory
 *		region. It is assumed the region is large enough to contain the
 *		BDs.Refer to the "SGDMA Ring Creation" section  in xaxidma.h
 *		for more information. The minimum valid value for this
 *		parameter is 1.
 *
 * @return
 *		- XST_SUCCESS if initialization was successful
 * 		- XST_NO_FEATURE if the provided instance is a non SGDMA type
 *		of DMA channel.
 *		- XST_INVALID_PARAM under any of the following conditions:
 *		1) BdCount is not positive
 *
 *		2) PhysAddr and/or VirtAddr are not aligned to the given
 *		Alignment parameter;
 *
 *		3) Alignment parameter does not meet minimum requirements or
 *		is not a power of 2 value.
 *
 *		- XST_DMA_SG_LIST_ERROR if the memory segment containing the
 *		list spans over address 0x00000000 in virtual address space.
 *
 * @note	This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
u32 XAxiDma_BdRingCreate(XAxiDma_BdRing *RingPtr, UINTPTR PhysAddr,
			UINTPTR VirtAddr, u32 Alignment, int BdCount)
{
	int i;
	UINTPTR BdVirtAddr;
	UINTPTR BdPhysAddr;

	if (BdCount <= 0) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCreate: non-positive BD"
				" number %d\r\n", BdCount);

		return XST_INVALID_PARAM;
	}

	/* In case there is a failure prior to creating list, make sure the
	 * following attributes are 0 to prevent calls to other SG functions
	 * from doing anything
	 */
	RingPtr->AllCnt = 0;
	RingPtr->FreeCnt = 0;
	RingPtr->HwCnt = 0;
	RingPtr->PreCnt = 0;
	RingPtr->PostCnt = 0;

	/* Make sure Alignment parameter meets minimum requirements */
	if (Alignment < XAXIDMA_BD_MINIMUM_ALIGNMENT) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCreate: alignment too "
		"small %d, need to be at least %d\r\n", (int)Alignment,
			XAXIDMA_BD_MINIMUM_ALIGNMENT);

		return XST_INVALID_PARAM;
	}

	/* Make sure Alignment is a power of 2 */
	if ((Alignment - 1) & Alignment) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCreate: alignment not"
				" valid %d\r\n", (int)Alignment);

		return XST_INVALID_PARAM;
	}

	/* Make sure PhysAddr and VirtAddr are on same Alignment */
	if ((PhysAddr % Alignment) || (VirtAddr % Alignment)) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCreate: Physical address"
		" %x and virtual address %x have different alignment\r\n",
			(unsigned int)PhysAddr, (unsigned int)VirtAddr);

		return XST_INVALID_PARAM;
	}

	/* Compute how many bytes will be between the start of adjacent BDs */
	RingPtr->Separation =
		(sizeof(XAxiDma_Bd) + (Alignment - 1)) & ~(Alignment - 1);

	/* Must make sure the ring doesn't span address 0x00000000. If it does,
	 * then the next/prev BD traversal macros will fail.
	 */
	if (VirtAddr > (VirtAddr + (RingPtr->Separation * BdCount) - 1)) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCreate: BD space cross "
			"0x0\r\n");

		return XST_DMA_SG_LIST_ERROR;
	}

	/* Initial ring setup:
	 *  - Clear the entire space
	 *  - Setup each BD's next pointer with the physical address of the
	 *    next BD
	 *  - Put hardware information in each BD
	 */
	memset((void *) VirtAddr, 0, (RingPtr->Separation * BdCount));

	BdVirtAddr = VirtAddr;
	BdPhysAddr = PhysAddr + RingPtr->Separation;
	for (i = 1; i < BdCount; i++) {
		XAxiDma_BdWrite(BdVirtAddr, XAXIDMA_BD_ADDRLEN_OFFSET,
				RingPtr->Addr_ext);
		XAxiDma_BdWrite(BdVirtAddr, XAXIDMA_BD_NDESC_OFFSET,
				(BdPhysAddr & XAXIDMA_DESC_LSB_MASK));
		XAxiDma_BdWrite(BdVirtAddr, XAXIDMA_BD_NDESC_MSB_OFFSET,
				UPPER_32_BITS(BdPhysAddr));

		/* Put hardware information in the BDs
		 */
		XAxiDma_BdWrite(BdVirtAddr, XAXIDMA_BD_HAS_STSCNTRL_OFFSET,
				(u32)RingPtr->HasStsCntrlStrm);

		XAxiDma_BdWrite(BdVirtAddr, XAXIDMA_BD_HAS_DRE_OFFSET,
		    (((u32)(RingPtr->HasDRE)) << XAXIDMA_BD_HAS_DRE_SHIFT) |
		    RingPtr->DataWidth);

		XAXIDMA_CACHE_FLUSH(BdVirtAddr);
		BdVirtAddr += RingPtr->Separation;
		BdPhysAddr += RingPtr->Separation;
	}

	/* At the end of the ring, link the last BD back to the top */
	XAxiDma_BdWrite(BdVirtAddr, XAXIDMA_BD_ADDRLEN_OFFSET,
			RingPtr->Addr_ext);
	XAxiDma_BdWrite(BdVirtAddr, XAXIDMA_BD_NDESC_OFFSET,
			(PhysAddr & XAXIDMA_DESC_LSB_MASK));
	XAxiDma_BdWrite(BdVirtAddr, XAXIDMA_BD_NDESC_MSB_OFFSET,
			UPPER_32_BITS(PhysAddr));


	/* Setup the last BD's hardware information */
	XAxiDma_BdWrite(BdVirtAddr, XAXIDMA_BD_HAS_STSCNTRL_OFFSET,
		(u32)RingPtr->HasStsCntrlStrm);

	XAxiDma_BdWrite(BdVirtAddr, XAXIDMA_BD_HAS_DRE_OFFSET,
	    (((u32)(RingPtr->HasDRE)) << XAXIDMA_BD_HAS_DRE_SHIFT) |
	    RingPtr->DataWidth);

	/* Setup and initialize pointers and counters */
	RingPtr->RunState = AXIDMA_CHANNEL_HALTED;
	RingPtr->FirstBdAddr = VirtAddr;
	RingPtr->FirstBdPhysAddr = PhysAddr;
	RingPtr->LastBdAddr = BdVirtAddr;
	RingPtr->Length = RingPtr->LastBdAddr - RingPtr->FirstBdAddr +
		RingPtr->Separation;
	RingPtr->AllCnt = BdCount;
	RingPtr->FreeCnt = BdCount;
	RingPtr->FreeHead = (XAxiDma_Bd *) VirtAddr;
	RingPtr->PreHead = (XAxiDma_Bd *) VirtAddr;
	RingPtr->HwHead = (XAxiDma_Bd *) VirtAddr;
	RingPtr->HwTail = (XAxiDma_Bd *) VirtAddr;
	RingPtr->PostHead = (XAxiDma_Bd *) VirtAddr;
	RingPtr->BdaRestart = (XAxiDma_Bd *) PhysAddr;

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * Clone the given BD into every BD in the ring. Only the fields offset from
 * XAXIDMA_BD_START_CLEAR are copied, for XAXIDMA_BD_BYTES_TO_CLEAR bytes.
 * This covers: BufferAddr, Control/Buffer length, status, APP words 0 - 4,
 * and software ID fields.
 *
 * This function can be called only when all BDs are in the free group such as
 * immediately after creation of the ring. This prevents modification
 * of BDs while they are in use by hardware or the application.
 *
 * @param	RingPtr is the BD ring instance to be worked on.
 * @param	SrcBdPtr is the source BD template to be cloned into the list.
 *
 * @return
 *		- XST_SUCCESS if the list was modified.
 *		- XST_DMA_SG_NO_LIST if a list has not been created.
 *		- XST_DEVICE_IS_STARTED if the DMA channel has not been stopped.
 *		- XST_DMA_SG_LIST_ERROR if some of the BDs in this channel are
 *		under hardware or application control.
 *
 * @note	This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
int XAxiDma_BdRingClone(XAxiDma_BdRing * RingPtr, XAxiDma_Bd * SrcBdPtr)
{
	int i;
	UINTPTR CurBd;
	u32 Save;
	XAxiDma_Bd TmpBd;

	/* Can't do this function if there isn't a ring */
	if (RingPtr->AllCnt == 0) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingClone: no bds\r\n");

		return XST_DMA_SG_NO_LIST;
	}

	/* Can't do this function with the channel running */
	if (RingPtr->RunState == AXIDMA_CHANNEL_NOT_HALTED) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingClone: bd ring started "
			"already, cannot do\r\n");

		return XST_DEVICE_IS_STARTED;
	}

	/* Can't do this function with some of the BDs in use */
	if (RingPtr->FreeCnt != RingPtr->AllCnt) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingClone: some bds already "
			"in use %d/%d\r\n",RingPtr->FreeCnt, RingPtr->AllCnt);

		return XST_DMA_SG_LIST_ERROR;
	}

	/* Make a copy of the template then modify it by clearing
	 * the complete bit in status/control field
	 */
	memcpy(&TmpBd, SrcBdPtr, sizeof(XAxiDma_Bd));

	Save = XAxiDma_BdRead(&TmpBd, XAXIDMA_BD_STS_OFFSET);
	Save &= ~XAXIDMA_BD_STS_COMPLETE_MASK;
	XAxiDma_BdWrite(&TmpBd, XAXIDMA_BD_STS_OFFSET, Save);

	for (i = 0, CurBd = RingPtr->FirstBdAddr;
	     i < RingPtr->AllCnt; i++, CurBd += RingPtr->Separation) {

		memcpy((void *)((UINTPTR)CurBd + XAXIDMA_BD_START_CLEAR),
		    (void *)((UINTPTR)(&TmpBd) + XAXIDMA_BD_START_CLEAR),
		    XAXIDMA_BD_BYTES_TO_CLEAR);

		XAXIDMA_CACHE_FLUSH(CurBd);
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * Start a DMA channel and
 * Allow DMA transactions to commence on a given channel if descriptors are
 * ready to be processed.
 *
 * After a DMA channel is started, it is not halted, and it is idle (no active
 * DMA transfers).
 *
 * @param	RingPtr is the Channel instance to be worked on
 *
 * @return
 *		- XST_SUCCESS upon success
 *		- XST_DMA_ERROR if no valid BD available to put into current
 *		BD register
 *
 * @note	This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
int XAxiDma_StartBdRingHw(XAxiDma_BdRing * RingPtr)
{
	u32 RegBase;
	int RingIndex = RingPtr->RingIndex;

	if (!XAxiDma_BdRingHwIsStarted(RingPtr)) {
		/* Start the hardware
		*/
		RegBase = RingPtr->ChanBase;
		XAxiDma_WriteReg(RegBase, XAXIDMA_CR_OFFSET,
			XAxiDma_ReadReg(RegBase, XAXIDMA_CR_OFFSET)
			| XAXIDMA_CR_RUNSTOP_MASK);
	}

	if (XAxiDma_BdRingHwIsStarted(RingPtr)) {
		/* Note as started */
		RingPtr->RunState = AXIDMA_CHANNEL_NOT_HALTED;

		/* If there are unprocessed BDs then we want the channel to begin
		 * processing right away
		 */
		if (RingPtr->HwCnt > 0) {

			XAXIDMA_CACHE_INVALIDATE(RingPtr->HwTail);

			if ((XAxiDma_BdRead(RingPtr->HwTail,
				    XAXIDMA_BD_STS_OFFSET) &
				XAXIDMA_BD_STS_COMPLETE_MASK) == 0) {
				if (RingPtr->IsRxChannel) {
					if (!RingIndex) {
						XAxiDma_WriteReg(RingPtr->ChanBase,
							XAXIDMA_TDESC_OFFSET, (XAXIDMA_VIRT_TO_PHYS(RingPtr->HwTail) & XAXIDMA_DESC_LSB_MASK));
						if (RingPtr->Addr_ext)
							XAxiDma_WriteReg(RingPtr->ChanBase, XAXIDMA_TDESC_MSB_OFFSET,
								 UPPER_32_BITS(XAXIDMA_VIRT_TO_PHYS(RingPtr->HwTail)));
					}
					else {
						XAxiDma_WriteReg(RingPtr->ChanBase,
							(XAXIDMA_RX_TDESC0_OFFSET +
							(RingIndex - 1) * XAXIDMA_RX_NDESC_OFFSET),
							(XAXIDMA_VIRT_TO_PHYS(RingPtr->HwTail) & XAXIDMA_DESC_LSB_MASK ));
						if (RingPtr->Addr_ext)
							XAxiDma_WriteReg(RingPtr->ChanBase,
								(XAXIDMA_RX_TDESC0_MSB_OFFSET +
								(RingIndex - 1) * XAXIDMA_RX_NDESC_OFFSET),
								UPPER_32_BITS(XAXIDMA_VIRT_TO_PHYS(RingPtr->HwTail)));
					}
				}
				else {
					XAxiDma_WriteReg(RingPtr->ChanBase,
							XAXIDMA_TDESC_OFFSET, (XAXIDMA_VIRT_TO_PHYS(RingPtr->HwTail) & XAXIDMA_DESC_LSB_MASK));
					if (RingPtr->Addr_ext)
						XAxiDma_WriteReg(RingPtr->ChanBase, XAXIDMA_TDESC_MSB_OFFSET,
								 UPPER_32_BITS(XAXIDMA_VIRT_TO_PHYS(RingPtr->HwTail)));
				}
			}
		}

		return XST_SUCCESS;
	}

	return XST_DMA_ERROR;
}

/*****************************************************************************/
/**
 * Start a DMA channel, updates current descriptors and
 * Allow DMA transactions to commence on a given channel if descriptors are
 * ready to be processed.
 *
 * After a DMA channel is started, it is not halted, and it is idle (no active
 * DMA transfers).
 *
 * @param	RingPtr is the Channel instance to be worked on
 *
 * @return
 *		- XST_SUCCESS upon success
 *		- XST_DMA_ERROR if no valid BD available to put into current
 *		BD register
 *
 * @note	This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
int XAxiDma_BdRingStart(XAxiDma_BdRing * RingPtr)
{
	int Status;

	Status = XAxiDma_UpdateBdRingCDesc(RingPtr);
	if (Status != XST_SUCCESS) {
		 xdbg_printf(XDBG_DEBUG_ERROR, "BdRingStart: "
			"Updating Current Descriptor Failed\n\r");
		return Status;
	}

	Status = XAxiDma_StartBdRingHw(RingPtr);
	if (Status != XST_SUCCESS) {
		 xdbg_printf(XDBG_DEBUG_ERROR, "BdRingStart: "
			"Starting Hardware Failed\n\r");
		return Status;
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * Set interrupt coalescing parameters for the given descriptor ring channel.
 *
 * @param	RingPtr is a pointer to the descriptor ring instance to be
 *		worked on.
 * @param	Counter sets the packet counter on the channel. Valid range is
 *		- 1..255.
 *		- XAXIDMA_NO_CHANGE to leave this setting unchanged.
 * @param	Timer sets the waitbound timer on the channel. Valid range is
 * 		- 0..255.
 *		- XAXIDMA_NO_CHANGE to leave this setting unchanged.
 *		Each unit depend on hardware building parameter
 *		C_DLYTMR_RESOLUTION,which is in the range from 0 to 100,000
 *		clock cycles. A value of 0 disables the delay interrupt.
 *
 * @return
 *		- XST_SUCCESS if interrupt coalescing settings updated
 *		- XST_FAILURE if Counter or Timer parameters are out of range
 *
 * @note	This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
int XAxiDma_BdRingSetCoalesce(XAxiDma_BdRing *RingPtr, u32 Counter, u32 Timer)
{
	u32 Cr;

	Cr = XAxiDma_ReadReg(RingPtr->ChanBase, XAXIDMA_CR_OFFSET);

	if (Counter != XAXIDMA_NO_CHANGE) {
		if ((Counter == 0) || (Counter > 0xFF)) {

			xdbg_printf(XDBG_DEBUG_ERROR, "BdRingSetCoalesce: "
			"invalid  coalescing threshold %d", (int)Counter);
			return XST_FAILURE;
		}

		Cr = (Cr & ~XAXIDMA_COALESCE_MASK) |
			(Counter << XAXIDMA_COALESCE_SHIFT);
	}

	if (Timer != XAXIDMA_NO_CHANGE) {
		if (Timer > 0xFF) {

			xdbg_printf(XDBG_DEBUG_ERROR, "BdRingSetCoalesce: "
			"invalid  delay counter %d", (int)Timer);

			return XST_FAILURE;
		}

		Cr = (Cr & ~XAXIDMA_DELAY_MASK) |
			(Timer << XAXIDMA_DELAY_SHIFT);
	}

	XAxiDma_WriteReg(RingPtr->ChanBase, XAXIDMA_CR_OFFSET, Cr);

	return XST_SUCCESS;
}
/*****************************************************************************/
/**
 * Retrieve current interrupt coalescing parameters from the given descriptor
 * ring channel.
 *
 * @param	RingPtr is a pointer to the descriptor ring instance to be
 *		worked on.
 * @param	CounterPtr points to a memory location where the current packet
 *		counter will be written.
 * @param	TimerPtr points to a memory location where the current
 *		waitbound timer will be written.
 *
 * @return	The passed in parameters, CounterPtr and TimerPtr, holds the
 *		references to the return values.
 *
 * @note	This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
void XAxiDma_BdRingGetCoalesce(XAxiDma_BdRing * RingPtr,
			      u32 *CounterPtr, u32 *TimerPtr)
{
	u32 Cr;

	Cr = XAxiDma_ReadReg(RingPtr->ChanBase, XAXIDMA_CR_OFFSET);

	*CounterPtr = ((Cr & XAXIDMA_COALESCE_MASK) >> XAXIDMA_COALESCE_SHIFT);
	*TimerPtr = ((Cr & XAXIDMA_DELAY_MASK) >> XAXIDMA_DELAY_SHIFT);
}

/*****************************************************************************/
/**
 * Reserve locations in the BD ring. The set of returned BDs may be modified in
 * preparation for future DMA transactions. Once the BDs are ready to be
 * submitted to hardware, the application must call XAxiDma_BdRingToHw() in the
 * same order which they were allocated here. Example:
 *
 * <pre>
 *        NumBd = 2;
 *        Status = XDsma_RingBdAlloc(MyRingPtr, NumBd, &MyBdSet);
 *
 *        if (Status != XST_SUCCESS)
 *        {
 *            // Not enough BDs available for the request
 *        }
 *
 *        CurBd = MyBdSet;
 *        for (i=0; i<NumBd; i++)
 *        {
 *            // Prepare CurBd.....
 *
 *            // Onto next BD
 *            CurBd = XAxiDma_BdRingNext(MyRingPtr, CurBd);
 *        }
 *
 *        // Give list to hardware
 *        Status = XAxiDma_BdRingToHw(MyRingPtr, NumBd, MyBdSet);
 * </pre>
 *
 * A more advanced use of this function may allocate multiple sets of BDs.
 * They must be allocated and given to hardware in the correct sequence:
 * <pre>
 *        // Legal
 *        XAxiDma_BdRingAlloc(MyRingPtr, NumBd1, &MySet1);
 *        XAxiDma_BdRingToHw(MyRingPtr, NumBd1, MySet1);
 *
 *        // Legal
 *        XAxiDma_BdRingAlloc(MyRingPtr, NumBd1, &MySet1);
 *        XAxiDma_BdRingAlloc(MyRingPtr, NumBd2, &MySet2);
 *        XAxiDma_BdRingToHw(MyRingPtr, NumBd1, MySet1);
 *        XAxiDma_BdRingToHw(MyRingPtr, NumBd2, MySet2);
 *
 *        // Not legal
 *        XAxiDma_BdRingAlloc(MyRingPtr, NumBd1, &MySet1);
 *        XAxiDma_BdRingAlloc(MyRingPtr, NumBd2, &MySet2);
 *        XAxiDma_BdRingToHw(MyRingPtr, NumBd2, MySet2);
 *        XAxiDma_BdRingToHw(MyRingPtr, NumBd1, MySet1);
 * </pre>
 *
 * Use the API defined in xaxidmabd.h to modify individual BDs. Traversal of
 * the BD set can be done using XAxiDma_BdRingNext() and XAxiDma_BdRingPrev().
 *
 * @param	RingPtr is a pointer to the descriptor ring instance to be
 *		worked on.
 * @param	NumBd is the number of BDs to allocate
 * @param	BdSetPtr is an output parameter, it points to the first BD
 *		available for modification.
 *
 * @return
 *		- XST_SUCCESS if the requested number of BDs were returned in
 *		the BdSetPtr parameter.
 *		- XST_INVALID_PARAM if passed in NumBd is not positive
 *		- XST_FAILURE if there were not enough free BDs to satisfy
 *		the request.
 *
 * @note	This function should not be preempted by another XAxiDma_BdRing
 *		function call that modifies the BD space. It is the caller's
 *		responsibility to provide a mutual exclusion mechanism.
 *
 *		Do not modify more BDs than the number requested with the NumBd
 *		parameter. Doing so will lead to data corruption and system
 *		instability.
 *
 *		This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
int XAxiDma_BdRingAlloc(XAxiDma_BdRing * RingPtr, int NumBd,
	XAxiDma_Bd ** BdSetPtr)
{
	if (NumBd <= 0) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingAlloc: negative BD "
				"number %d\r\n", NumBd);

		return XST_INVALID_PARAM;
	}

	/* Enough free BDs available for the request? */
	if (RingPtr->FreeCnt < NumBd) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		"Not enough BDs to alloc %d/%d\r\n", NumBd, RingPtr->FreeCnt);

		return XST_FAILURE;
	}

	/* Set the return argument and move FreeHead forward */
	*BdSetPtr = RingPtr->FreeHead;
	XAXIDMA_RING_SEEKAHEAD(RingPtr, RingPtr->FreeHead, NumBd);
	RingPtr->FreeCnt -= NumBd;
	RingPtr->PreCnt += NumBd;

	return XST_SUCCESS;
}
/*****************************************************************************/
/**
 * Fully or partially undo an XAxiDma_BdRingAlloc() operation. Use this
 * function if all the BDs allocated by XAxiDma_BdRingAlloc() could not be
 * transferred to hardware with XAxiDma_BdRingToHw().
 *
 * This function releases the BDs after they have been allocated but before
 * they have been given to hardware.
 *
 * This function is not the same as XAxiDma_BdRingFree(). The Free function
 * returns BDs to the free list after they have been processed by hardware,
 * while UnAlloc returns them before being processed by hardware.
 *
 * There are two scenarios where this function can be used. Full UnAlloc or
 * Partial UnAlloc. A Full UnAlloc means all the BDs Alloc'd will be returned:
 *
 * <pre>
 *    Status = XAxiDma_BdRingAlloc(MyRingPtr, 10, &BdPtr);
 *        ...
 *        ...
 *    if (Error)
 *    {
 *        Status = XAxiDma_BdRingUnAlloc(MyRingPtr, 10, &BdPtr);
 *    }
 * </pre>
 *
 * A partial UnAlloc means some of the BDs Alloc'd will be returned:
 *
 * <pre>
 *    Status = XAxiDma_BdRingAlloc(MyRingPtr, 10, &BdPtr);
 *    BdsLeft = 10;
 *    CurBdPtr = BdPtr;
 *
 *    while (BdsLeft)
 *    {
 *       if (Error)
 *       {
 *          Status = XAxiDma_BdRingUnAlloc(MyRingPtr, BdsLeft, CurBdPtr);
 *       }
 *
 *       CurBdPtr = XAxiDma_BdRingNext(MyRingPtr, CurBdPtr);
 *       BdsLeft--;
 *    }
 * </pre>
 *
 * A partial UnAlloc must include the last BD in the list that was Alloc'd.
 *
 * @param	RingPtr is a pointer to the descriptor ring instance to be
 *		worked on.
 * @param	NumBd is the number of BDs to unallocate
 * @param	BdSetPtr points to the first of the BDs to be returned.
 *
 * @return
 *		- XST_SUCCESS if the BDs were unallocated.
 *		- XST_INVALID_PARAM if passed in NumBd is negative
 *		- XST_FAILURE if NumBd parameter was greater that the number of
 *		BDs in the preprocessing state.
 *
 * @note	This function should not be preempted by another XAxiDma ring
 *		function call that modifies the BD space. It is the caller's
 *		responsibility to provide a mutual exclusion mechanism.
 *
 *		This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
int XAxiDma_BdRingUnAlloc(XAxiDma_BdRing * RingPtr, int NumBd,
	XAxiDma_Bd * BdSetPtr)
{
	XAxiDma_Bd *TmpBd;

	if (NumBd <= 0) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingUnAlloc: negative BD"
		" number %d\r\n", NumBd);

		return XST_INVALID_PARAM;
	}

	/* Enough BDs in the preprocessing state for the request? */
	if (RingPtr->PreCnt < NumBd) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		"Pre-allocated BDs less than requested %d/%d\r\n",
		RingPtr->PreCnt, NumBd);

		return XST_FAILURE;
	}

	/* The last BD in the BD set must has the FreeHead as its next BD.
	 * Otherwise, this is not a valid operation.
	 */
	TmpBd = BdSetPtr;
	XAXIDMA_RING_SEEKAHEAD(RingPtr, TmpBd, NumBd);

	if (TmpBd != RingPtr->FreeHead) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Unalloc does not go back to free head\r\n");

		return XST_FAILURE;
	}

	/* Set the return argument and move FreeHead backward */
	XAXIDMA_RING_SEEKBACK(RingPtr, RingPtr->FreeHead, NumBd);
	RingPtr->FreeCnt += NumBd;
	RingPtr->PreCnt -= NumBd;

	return XST_SUCCESS;
}
/*****************************************************************************/
/**
 * Enqueue a set of BDs to hardware that were previously allocated by
 * XAxiDma_BdRingAlloc(). Once this function returns, the argument BD set goes
 * under hardware control. Changes to these BDs should be held until they are
 * finished by hardware to avoid data corruption and system instability.
 *
 * For transmit, the set will be rejected if the last BD of the set does not
 * mark the end of a packet or the first BD does not mark the start of a packet.
 *
 * @param	RingPtr is a pointer to the descriptor ring instance to be
 *		worked on.
 * @param	NumBd is the number of BDs in the set.
 * @param	BdSetPtr is the first BD of the set to commit to hardware.
 *
 * @return
 *		- XST_SUCCESS if the set of BDs was accepted and enqueued to
 *		hardware
 *		- XST_INVALID_PARAM if passed in NumBd is negative
 *		- XST_FAILURE if the set of BDs was rejected because the first
 *		BD does not have its start-of-packet bit set, or the last BD
 *		does not have its end-of-packet bit set, or any one of the BDs
 *		has 0 length.
 *		- XST_DMA_SG_LIST_ERROR if this function was called out of
 *		sequence with XAxiDma_BdRingAlloc()
 *
 * @note	This function should not be preempted by another XAxiDma ring
 *		function call that modifies the BD space. It is the caller's
 *		responsibility to provide a mutual exclusion mechanism.
 *
 *		This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
int XAxiDma_BdRingToHw(XAxiDma_BdRing * RingPtr, int NumBd,
	XAxiDma_Bd * BdSetPtr)
{
	XAxiDma_Bd *CurBdPtr;
	int i;
	u32 BdCr;
	u32 BdSts;
	int RingIndex = RingPtr->RingIndex;

	if (NumBd < 0) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingToHw: negative BD number "
			"%d\r\n", NumBd);

		return XST_INVALID_PARAM;
	}

	/* If the commit set is empty, do nothing */
	if (NumBd == 0) {
		return XST_SUCCESS;
	}

	/* Make sure we are in sync with XAxiDma_BdRingAlloc() */
	if ((RingPtr->PreCnt < NumBd) || (RingPtr->PreHead != BdSetPtr)) {

		xdbg_printf(XDBG_DEBUG_ERROR, "Bd ring has problems\r\n");
		return XST_DMA_SG_LIST_ERROR;
	}

	CurBdPtr = BdSetPtr;
	BdCr = XAxiDma_BdGetCtrl(CurBdPtr);
	BdSts = XAxiDma_BdGetSts(CurBdPtr);

	/* In case of Tx channel, the first BD should have been marked
	 * as start-of-frame
	 */
	if (!(RingPtr->IsRxChannel) && !(BdCr & XAXIDMA_BD_CTRL_TXSOF_MASK)) {

		xdbg_printf(XDBG_DEBUG_ERROR, "Tx first BD does not have "
								"SOF\r\n");

		return XST_FAILURE;
	}

	/* Clear the completed status bit
	 */
	for (i = 0; i < NumBd - 1; i++) {

		/* Make sure the length value in the BD is non-zero. */
		if (XAxiDma_BdGetLength(CurBdPtr,
				RingPtr->MaxTransferLen) == 0) {

			xdbg_printf(XDBG_DEBUG_ERROR, "0 length bd\r\n");

			return XST_FAILURE;
		}

		BdSts &=  ~XAXIDMA_BD_STS_COMPLETE_MASK;
		XAxiDma_BdWrite(CurBdPtr, XAXIDMA_BD_STS_OFFSET, BdSts);

		/* Flush the current BD so DMA core could see the updates */
		XAXIDMA_CACHE_FLUSH(CurBdPtr);

		CurBdPtr = (XAxiDma_Bd *)((void *)XAxiDma_BdRingNext(RingPtr, CurBdPtr));
		BdCr = XAxiDma_BdRead(CurBdPtr, XAXIDMA_BD_CTRL_LEN_OFFSET);
		BdSts = XAxiDma_BdRead(CurBdPtr, XAXIDMA_BD_STS_OFFSET);
	}

	/* In case of Tx channel, the last BD should have EOF bit set */
	if (!(RingPtr->IsRxChannel) && !(BdCr & XAXIDMA_BD_CTRL_TXEOF_MASK)) {

		xdbg_printf(XDBG_DEBUG_ERROR, "Tx last BD does not have "
								"EOF\r\n");

		return XST_FAILURE;
	}

	/* Make sure the length value in the last BD is non-zero. */
	if (XAxiDma_BdGetLength(CurBdPtr,
			RingPtr->MaxTransferLen) == 0) {

		xdbg_printf(XDBG_DEBUG_ERROR, "0 length bd\r\n");

		return XST_FAILURE;
	}

	/* The last BD should also have the completed status bit cleared
	 */
	BdSts &= ~XAXIDMA_BD_STS_COMPLETE_MASK;
	XAxiDma_BdWrite(CurBdPtr, XAXIDMA_BD_STS_OFFSET, BdSts);

	/* Flush the last BD so DMA core could see the updates */
	XAXIDMA_CACHE_FLUSH(CurBdPtr);
	DATA_SYNC;

	/* This set has completed pre-processing, adjust ring pointers and
	 * counters
	 */
	XAXIDMA_RING_SEEKAHEAD(RingPtr, RingPtr->PreHead, NumBd);
	RingPtr->PreCnt -= NumBd;
	RingPtr->HwTail = CurBdPtr;
	RingPtr->HwCnt += NumBd;

	/* If it is running, signal the engine to begin processing */
	if (RingPtr->RunState == AXIDMA_CHANNEL_NOT_HALTED) {
			if (RingPtr->IsRxChannel) {
				if (!RingIndex) {
					XAxiDma_WriteReg(RingPtr->ChanBase,
							XAXIDMA_TDESC_OFFSET, (XAXIDMA_VIRT_TO_PHYS(RingPtr->HwTail) & XAXIDMA_DESC_LSB_MASK));
					if (RingPtr->Addr_ext)
						XAxiDma_WriteReg(RingPtr->ChanBase, XAXIDMA_TDESC_MSB_OFFSET,
								 UPPER_32_BITS(XAXIDMA_VIRT_TO_PHYS(RingPtr->HwTail)));
				}
				else {
					XAxiDma_WriteReg(RingPtr->ChanBase,
						(XAXIDMA_RX_TDESC0_OFFSET +
						(RingIndex - 1) * XAXIDMA_RX_NDESC_OFFSET),
						(XAXIDMA_VIRT_TO_PHYS(RingPtr->HwTail) & XAXIDMA_DESC_LSB_MASK ));
					if (RingPtr->Addr_ext)
						XAxiDma_WriteReg(RingPtr->ChanBase,
							(XAXIDMA_RX_TDESC0_MSB_OFFSET +
							(RingIndex - 1) * XAXIDMA_RX_NDESC_OFFSET),
							UPPER_32_BITS(XAXIDMA_VIRT_TO_PHYS(RingPtr->HwTail)));
				}
			}
			else {
				XAxiDma_WriteReg(RingPtr->ChanBase,
							XAXIDMA_TDESC_OFFSET, (XAXIDMA_VIRT_TO_PHYS(RingPtr->HwTail) & XAXIDMA_DESC_LSB_MASK));
				if (RingPtr->Addr_ext)
					XAxiDma_WriteReg(RingPtr->ChanBase, XAXIDMA_TDESC_MSB_OFFSET,
								UPPER_32_BITS(XAXIDMA_VIRT_TO_PHYS(RingPtr->HwTail)));
			}
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
 * Returns a set of BD(s) that have been processed by hardware. The returned
 * BDs may be examined by the application to determine the outcome of the DMA
 * transactions. Once the BDs have been examined, the application must call
 * XAxiDma_BdRingFree() in the same order which they were retrieved here.
 *
 * Example:
 *
 * <pre>
 *        NumBd = XAxiDma_BdRingFromHw(MyRingPtr, XAXIDMA_ALL_BDS, &MyBdSet);
 *
 *        if (NumBd == 0)
 *        {
 *           // hardware has nothing ready for us yet
 *        }
 *
 *        CurBd = MyBdSet;
 *        for (i=0; i<NumBd; i++)
 *        {
 *           // Examine CurBd for post processing.....
 *
 *           // Onto next BD
 *           CurBd = XAxiDma_BdRingNext(MyRingPtr, CurBd);
 *        }
 *
 *        XAxiDma_BdRingFree(MyRingPtr, NumBd, MyBdSet); // Return the list
 * </pre>
 *
 * A more advanced use of this function may allocate multiple sets of BDs.
 * They must be retrieved from hardware and freed in the correct sequence:
 * <pre>
 *        // Legal
 *        XAxiDma_BdRingFromHw(MyRingPtr, NumBd1, &MySet1);
 *        XAxiDma_BdRingFree(MyRingPtr, NumBd1, MySet1);
 *
 *        // Legal
 *        XAxiDma_BdRingFromHw(MyRingPtr, NumBd1, &MySet1);
 *        XAxiDma_BdRingFromHw(MyRingPtr, NumBd2, &MySet2);
 *        XAxiDma_BdRingFree(MyRingPtr, NumBd1, MySet1);
 *        XAxiDma_BdRingFree(MyRingPtr, NumBd2, MySet2);
 *
 *        // Not legal
 *        XAxiDma_BdRingFromHw(MyRingPtr, NumBd1, &MySet1);
 *        XAxiDma_BdRingFromHw(MyRingPtr, NumBd2, &MySet2);
 *        XAxiDma_BdRingFree(MyRingPtr, NumBd2, MySet2);
 *        XAxiDma_BdRingFree(MyRingPtr, NumBd1, MySet1);
 * </pre>
 *
 * If hardware has partially completed a packet spanning multiple BDs, then
 * none of the BDs for that packet will be included in the results.
 *
 * @param	RingPtr is a pointer to the descriptor ring instance to be
 *		worked on.
 * @param	BdLimit is the maximum number of BDs to return in the set. Use
 *		XAXIDMA_ALL_BDS to return all BDs that have been processed.
 * @param	BdSetPtr is an output parameter, it points to the first BD
 *		available for examination.
 *
 * @return	The number of BDs processed by hardware. A value of 0 indicates
 *		that no data is available. No more than BdLimit BDs will be
 *		returned.
 *
 * @note	Treat BDs returned by this function as read-only.
 *
 * 		This function should not be preempted by another XAxiDma ring
 *		function call that modifies the BD space. It is the caller's
 *		responsibility to provide a mutual exclusion mechanism.
 *
 *		This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
int XAxiDma_BdRingFromHw(XAxiDma_BdRing * RingPtr, int BdLimit,
			     XAxiDma_Bd ** BdSetPtr)
{
	XAxiDma_Bd *CurBdPtr;
	int BdCount;
	int BdPartialCount;
	u32 BdSts;
	u32 BdCr;

	CurBdPtr = RingPtr->HwHead;
	BdCount = 0;
	BdPartialCount = 0;
	BdSts = 0;
	BdCr = 0;

	/* If no BDs in work group, then there's nothing to search */
	if (RingPtr->HwCnt == 0) {
		*BdSetPtr = (XAxiDma_Bd *)NULL;

		return 0;
	}

	if (BdLimit > RingPtr->HwCnt) {
		BdLimit = RingPtr->HwCnt;
	}

	/* Starting at HwHead, keep moving forward in the list until:
	 *  - A BD is encountered with its completed bit clear in the status
	 *    word which means hardware has not completed processing of that
	 *    BD.
	 *  - RingPtr->HwTail is reached
	 *  - The number of requested BDs has been processed
	 */

	while (BdCount < BdLimit) {
		/* Read the status */
		XAXIDMA_CACHE_INVALIDATE(CurBdPtr);
		BdSts = XAxiDma_BdRead(CurBdPtr, XAXIDMA_BD_STS_OFFSET);
		BdCr = XAxiDma_BdRead(CurBdPtr, XAXIDMA_BD_CTRL_LEN_OFFSET);

		/* If the hardware still hasn't processed this BD then we are
		 * done
		 */
		if (!(BdSts & XAXIDMA_BD_STS_COMPLETE_MASK)) {
			break;
		}

		BdCount++;

		/* Hardware has processed this BD so check the "last" bit. If
		 * it is clear, then there are more BDs for the current packet.
		 * Keep a count of these partial packet BDs.
		 *
		 * For tx BDs, EOF bit is in the control word
		 * For rx BDs, EOF bit is in the status word
		 */
		if (((!(RingPtr->IsRxChannel) &&
		(BdCr & XAXIDMA_BD_CTRL_TXEOF_MASK)) ||
		((RingPtr->IsRxChannel) && (BdSts &
			XAXIDMA_BD_STS_RXEOF_MASK)))) {

			BdPartialCount = 0;
		}
		else {
			BdPartialCount++;
		}

		/* Reached the end of the work group */
		if (CurBdPtr == RingPtr->HwTail) {
			break;
		}

		/* Move on to the next BD in work group */
		CurBdPtr = (XAxiDma_Bd *)((void *)XAxiDma_BdRingNext(RingPtr, CurBdPtr));
	}

	/* Subtract off any partial packet BDs found */
	BdCount -= BdPartialCount;

	/* If BdCount is non-zero then BDs were found to return. Set return
	 * parameters, update pointers and counters, return success
	 */
	if (BdCount) {
		*BdSetPtr = RingPtr->HwHead;
		RingPtr->HwCnt -= BdCount;
		RingPtr->PostCnt += BdCount;
		XAXIDMA_RING_SEEKAHEAD(RingPtr, RingPtr->HwHead, BdCount);

		return BdCount;
	}
	else {
		*BdSetPtr = (XAxiDma_Bd *)NULL;

		return 0;
	}
}
/*****************************************************************************/
/**
 * Frees a set of BDs that had been previously retrieved with
 * XAxiDma_BdRingFromHw().
 *
 * @param	RingPtr is a pointer to the descriptor ring instance to be
 *		worked on.
 * @param	NumBd is the number of BDs to free.
 * @param	BdSetPtr is the head of a list of BDs returned by
 *		XAxiDma_BdRingFromHw().
 *
 * @return
 *		- XST_SUCCESS if the set of BDs was freed.
 *		- XST_INVALID_PARAM if NumBd is negative
 *		- XST_DMA_SG_LIST_ERROR if this function was called out of
 *		sequence with XAxiDma_BdRingFromHw().
 *
 * @note	This function should not be preempted by another XAxiDma
 *		function call that modifies the BD space. It is the caller's
 *		responsibility to ensure mutual exclusion.
 *
 *		This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
int XAxiDma_BdRingFree(XAxiDma_BdRing * RingPtr, int NumBd,
		      XAxiDma_Bd * BdSetPtr)
{
	if (NumBd < 0) {

		xdbg_printf(XDBG_DEBUG_ERROR,
		    "BdRingFree: negative BDs %d\r\n", NumBd);

		return XST_INVALID_PARAM;
	}

	/* If the BD Set to free is empty, do nothing
	 */
	if (NumBd == 0) {
		return XST_SUCCESS;
	}

	/* Make sure we are in sync with XAxiDma_BdRingFromHw() */
	if ((RingPtr->PostCnt < NumBd) || (RingPtr->PostHead != BdSetPtr)) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingFree: Error free BDs: "
		"post count %d to free %d, PostHead %x to free ptr %x\r\n",
			RingPtr->PostCnt, NumBd,
			(UINTPTR)RingPtr->PostHead,
			(UINTPTR)BdSetPtr);

		return XST_DMA_SG_LIST_ERROR;
	}

	/* Update pointers and counters */
	RingPtr->FreeCnt += NumBd;
	RingPtr->PostCnt -= NumBd;
	XAXIDMA_RING_SEEKAHEAD(RingPtr, RingPtr->PostHead, NumBd);

	return XST_SUCCESS;
}
/*****************************************************************************/
/**
 * Check the internal data structures of the BD ring for the provided channel.
 * The following checks are made:
 *
 *	- The BD ring is linked correctly in physical address space.
 *	- The internal pointers point to BDs in the ring.
 *	- The internal counters add up.
 *
 * The channel should be stopped (through XAxiDma_Pause() or XAxiDma_Reset())
 * prior to calling this function.
 *
 * @param	RingPtr is a pointer to the descriptor ring to be worked on.
 *
 * @return
 *		- XST_SUCCESS if no errors were found.
 *		- XST_DMA_SG_NO_LIST if the ring has not been created.
 *		- XST_IS_STARTED if the channel is not stopped.
 *		- XST_DMA_SG_LIST_ERROR if a problem is found with the internal
 *		data structures. If this value is returned, the channel should
 *		be reset,and the BD ring should be recreated through
 *		XAxiDma_BdRingCreate() to avoid data corruption or system
 *		instability.
 *
 * @note	This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
int XAxiDma_BdRingCheck(XAxiDma_BdRing * RingPtr)
{
	u32 AddrV;
	u32 AddrP;
	int i;

	/* Is the list created */
	if (RingPtr->AllCnt == 0) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCheck: no BDs\r\n");

		return XST_DMA_SG_NO_LIST;
	}

	/* Can't check if channel is running */
	if (RingPtr->RunState == AXIDMA_CHANNEL_NOT_HALTED) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCheck: Bd ring is "
		"running, cannot check it\r\n");

		return XST_IS_STARTED;
	}

	/* RunState doesn't make sense */
	else if (RingPtr->RunState != AXIDMA_CHANNEL_HALTED) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCheck: unknown BD ring "
			"state %d ", RingPtr->RunState);

		return XST_DMA_SG_LIST_ERROR;
	}

	/* Verify internal pointers point to correct memory space */
	AddrV = (UINTPTR) RingPtr->FreeHead;
	if ((AddrV < RingPtr->FirstBdAddr) || (AddrV > RingPtr->LastBdAddr)) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCheck: FreeHead wrong "
		"%x, should be in range of %x/%x\r\n",
		    (unsigned int)AddrV,
		    (unsigned int)RingPtr->FirstBdAddr,
			(unsigned int)RingPtr->LastBdAddr);

		return XST_DMA_SG_LIST_ERROR;
	}

	AddrV = (UINTPTR) RingPtr->PreHead;
	if ((AddrV < RingPtr->FirstBdAddr) || (AddrV > RingPtr->LastBdAddr)) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCheck: PreHead wrong %x, "
			"should be in range of %x/%x\r\n",
		    (unsigned int)AddrV,
		    (unsigned int)RingPtr->FirstBdAddr,
			(unsigned int)RingPtr->LastBdAddr);

		return XST_DMA_SG_LIST_ERROR;
	}

	AddrV = (UINTPTR) RingPtr->HwHead;
	if ((AddrV < RingPtr->FirstBdAddr) || (AddrV > RingPtr->LastBdAddr)) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCheck: HwHead wrong %x, "
			"should be in range of %x/%x\r\n",
		    (unsigned int)AddrV,
		    (unsigned int)RingPtr->FirstBdAddr,
			(unsigned int)RingPtr->LastBdAddr);

		return XST_DMA_SG_LIST_ERROR;
	}

	AddrV = (UINTPTR) RingPtr->HwTail;
	if ((AddrV < RingPtr->FirstBdAddr) || (AddrV > RingPtr->LastBdAddr)) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCheck: HwTail wrong %x, "
			"should be in range of %x/%x\r\n",
		    (unsigned int)AddrV,
		    (unsigned int)RingPtr->FirstBdAddr,
			(unsigned int)RingPtr->LastBdAddr);

		return XST_DMA_SG_LIST_ERROR;
	}

	AddrV = (UINTPTR) RingPtr->PostHead;
	if ((AddrV < RingPtr->FirstBdAddr) || (AddrV > RingPtr->LastBdAddr)) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCheck: PostHead wrong "
		"%x, should be in range of %x/%x\r\n",
		    (unsigned int)AddrV,
		    (unsigned int)RingPtr->FirstBdAddr,
			(unsigned int)RingPtr->LastBdAddr);

		return XST_DMA_SG_LIST_ERROR;
	}

	/* Verify internal counters add up */
	if ((RingPtr->HwCnt + RingPtr->PreCnt + RingPtr->FreeCnt +
	     RingPtr->PostCnt) != RingPtr->AllCnt) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCheck: internal counter "
			"error\r\n");

		return XST_DMA_SG_LIST_ERROR;
	}

	/* Verify BDs are linked correctly */
	AddrV = RingPtr->FirstBdAddr;
	AddrP = RingPtr->FirstBdPhysAddr + RingPtr->Separation;
	for (i = 1; i < RingPtr->AllCnt; i++) {
		XAXIDMA_CACHE_INVALIDATE(AddrV);
		/* Check next pointer for this BD. It should equal to the
		 * physical address of next BD
		 */
		if (XAxiDma_BdRead(AddrV, XAXIDMA_BD_NDESC_OFFSET) != AddrP) {

			xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCheck: Next Bd "
			"ptr %x wrong, expect %x\r\n",
				(unsigned int)XAxiDma_BdRead(AddrV,
			        XAXIDMA_BD_NDESC_OFFSET),
				(unsigned int)AddrP);

			return XST_DMA_SG_LIST_ERROR;
		}

		/* Move on to next BD */
		AddrV += RingPtr->Separation;
		AddrP += RingPtr->Separation;
	}

	XAXIDMA_CACHE_INVALIDATE(AddrV);
	/* Last BD should point back to the beginning of ring */
	if (XAxiDma_BdRead(AddrV, XAXIDMA_BD_NDESC_OFFSET) !=
	    RingPtr->FirstBdPhysAddr) {

		xdbg_printf(XDBG_DEBUG_ERROR, "BdRingCheck: last Bd Next BD "
		"ptr %x wrong, expect %x\r\n",
			(unsigned int)XAxiDma_BdRead(AddrV,
		          XAXIDMA_BD_NDESC_OFFSET),
			(unsigned int)RingPtr->FirstBdPhysAddr);

		return XST_DMA_SG_LIST_ERROR;
	}

	/* No problems found */
	return XST_SUCCESS;
}
/*****************************************************************************/
/**
 * Dump the registers for a channel.
 *
 * @param	RingPtr is a pointer to the descriptor ring to be worked on.
 *
 * @return	None
 *
 * @note	This function can be used only when DMA is in SG mode
 *
 *****************************************************************************/
void XAxiDma_BdRingDumpRegs(XAxiDma_BdRing *RingPtr) {
	u32 RegBase = RingPtr->ChanBase;
	int RingIndex = RingPtr->RingIndex;

	xil_printf("Dump registers %x:\r\n", (unsigned int)RegBase);
	xil_printf("Control REG: %08x\r\n",
		(unsigned int)XAxiDma_ReadReg(RegBase, XAXIDMA_CR_OFFSET));
	xil_printf("Status REG: %08x\r\n",
		(unsigned int)XAxiDma_ReadReg(RegBase, XAXIDMA_SR_OFFSET));

	if (RingIndex) {
	xil_printf("Cur BD REG: %08x\r\n",
		(unsigned int)XAxiDma_ReadReg(RegBase,
		XAXIDMA_RX_CDESC0_OFFSET + ((RingIndex - 1) *
		XAXIDMA_RX_NDESC_OFFSET)));
	xil_printf("Tail BD REG: %08x\r\n",
		(unsigned int)XAxiDma_ReadReg(RegBase,
		XAXIDMA_RX_TDESC0_OFFSET + ((RingIndex - 1) *
		XAXIDMA_RX_NDESC_OFFSET)));
	}
	else {
	xil_printf("Cur BD REG: %08x\r\n",
		(unsigned int)XAxiDma_ReadReg(RegBase, XAXIDMA_CDESC_OFFSET));
	xil_printf("Tail BD REG: %08x\r\n",
		(unsigned int)XAxiDma_ReadReg(RegBase, XAXIDMA_TDESC_OFFSET));
	}

	xil_printf("\r\n");
}
/** @} */
