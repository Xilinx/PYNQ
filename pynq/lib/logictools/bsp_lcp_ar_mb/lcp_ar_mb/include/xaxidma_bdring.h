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
*
* @file xaxidma_bdring.h
* @addtogroup axidma_v9_8
* @{
*
* This file contains DMA channel related structure and constant definition
* as well as function prototypes. Each DMA channel is managed by a Buffer
* Descriptor ring, and XAxiDma_BdRing is chosen as the symbol prefix used in
* this file. See xaxidma.h for more information on how a BD ring is managed.
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
* 9.2   vak  15/04/16  Fixed the compilation warnings in axidma driver
* 9.7   rsp  01/11/18  Use UINTPTR instead of u32 for ChanBase CR#976392
*
* </pre>
*
******************************************************************************/

#ifndef XAXIDMA_BDRING_H_	/* prevent circular inclusions */
#define XAXIDMA_BDRING_H_

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xstatus.h"
#include "xaxidma_bd.h"
#include <stdlib.h>

/************************** Constant Definitions *****************************/
/* State of a DMA channel
 */
#define AXIDMA_CHANNEL_NOT_HALTED	1
#define AXIDMA_CHANNEL_HALTED		2

/* Argument constant to simplify argument setting
 */
#define XAXIDMA_NO_CHANGE		0xFFFFFFFF
#define XAXIDMA_ALL_BDS			0x0FFFFFFF /* 268 Million */

/**************************** Type Definitions *******************************/

/** Container structure for descriptor storage control. If address translation
 * is enabled, then all addresses and pointers excluding FirstBdPhysAddr are
 * expressed in terms of the virtual address.
 */
typedef struct {
	UINTPTR ChanBase;		/**< physical base address*/

	int IsRxChannel;	/**< Is this a receive channel */
	volatile int RunState;	/**< Whether channel is running */
	int HasStsCntrlStrm; 	/**< Whether has stscntrl stream */
	int HasDRE;
	int DataWidth;
	int Addr_ext;
	u32 MaxTransferLen;

	UINTPTR FirstBdPhysAddr;	/**< Physical address of 1st BD in list */
	UINTPTR FirstBdAddr;	/**< Virtual address of 1st BD in list */
	UINTPTR LastBdAddr;		/**< Virtual address of last BD in the list */
	u32 Length;		/**< Total size of ring in bytes */
	UINTPTR Separation;		/**< Number of bytes between the starting
				     address of adjacent BDs */
	XAxiDma_Bd *FreeHead;	/**< First BD in the free group */
	XAxiDma_Bd *PreHead;	/**< First BD in the pre-work group */
	XAxiDma_Bd *HwHead;	/**< First BD in the work group */
	XAxiDma_Bd *HwTail;	/**< Last BD in the work group */
	XAxiDma_Bd *PostHead;	/**< First BD in the post-work group */
	XAxiDma_Bd *BdaRestart;	/**< BD to load when channel is started */
	XAxiDma_Bd *CyclicBd;	/**< Useful for Cyclic DMA operations */
	int FreeCnt;		/**< Number of allocatable BDs in free group */
	int PreCnt;		/**< Number of BDs in pre-work group */
	int HwCnt;		/**< Number of BDs in work group */
	int PostCnt;		/**< Number of BDs in post-work group */
	int AllCnt;		/**< Total Number of BDs for channel */
	int RingIndex;		/**< Ring Index */
	int Cyclic;		/**< Check for cyclic DMA Mode */
} XAxiDma_BdRing;

/***************** Macros (Inline Functions) Definitions *********************/

/*****************************************************************************/
/**
* Use this macro at initialization time to determine how many BDs will fit
* within the given memory constraints.
*
* The results of this macro can be provided to XAxiDma_BdRingCreate().
*
* @param	Alignment specifies what byte alignment the BDs must fall
*		on and must be a power of 2 to get an accurate calculation
*		(32, 64, 126,...)
* @param	Bytes is the number of bytes to be used to store BDs.
*
* @return	Number of BDs that can fit in the given memory area
*
* @note
*		C-style signature:
*		int XAxiDma_BdRingCntCalc(u32 Alignment, u32 Bytes)
*		This function is used only when system is configured as SG mode
*
******************************************************************************/
#define XAxiDma_BdRingCntCalc(Alignment, Bytes)                           \
	(uint32_t)((Bytes)/((sizeof(XAxiDma_Bd)+((Alignment)-1))&~((Alignment)-1)))

/*****************************************************************************/
/**
* Use this macro at initialization time to determine how many bytes of memory
* are required to contain a given number of BDs at a given alignment.
*
* @param	Alignment specifies what byte alignment the BDs must fall on.
*		This parameter must be a power of 2 to get an accurate
*		calculation (32, 64,128,...)
* @param	NumBd is the number of BDs to calculate memory size
*		requirements
*
* @return	The number of bytes of memory required to create a BD list
*		with the given memory constraints.
*
* @note
*		C-style signature:
*		int XAxiDma_BdRingMemCalc(u32 Alignment, u32 NumBd)
*		This function is used only when system is configured as SG mode
*
******************************************************************************/
#define XAxiDma_BdRingMemCalc(Alignment, NumBd)			\
	(int)((sizeof(XAxiDma_Bd)+((Alignment)-1)) & ~((Alignment)-1))*(NumBd)

/****************************************************************************/
/**
* Return the total number of BDs allocated by this channel with
* XAxiDma_BdRingCreate().
*
* @param	RingPtr is the BD ring to operate on.
*
* @return	The total number of BDs allocated for this channel.
*
* @note
* 		C-style signature:
*		int XAxiDma_BdRingGetCnt(XAxiDma_BdRing* RingPtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingGetCnt(RingPtr) ((RingPtr)->AllCnt)

/****************************************************************************/
/**
* Return the number of BDs allocatable with XAxiDma_BdRingAlloc() for pre-
* processing.
*
* @param	RingPtr is the BD ring to operate on.
*
* @return	The number of BDs currently allocatable.
*
* @note
* 		C-style signature:
*		int XAxiDma_BdRingGetFreeCnt(XAxiDma_BdRing* RingPtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingGetFreeCnt(RingPtr)  ((RingPtr)->FreeCnt)


/****************************************************************************/
/**
* Snap shot the latest BD a BD ring is processing.
*
* @param	RingPtr is the BD ring to operate on.
*
* @return	None
*
* @note
*		C-style signature:
*		void XAxiDma_BdRingSnapShotCurrBd(XAxiDma_BdRing* RingPtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingSnapShotCurrBd(RingPtr)		  \
	{								  \
		if (!RingPtr->IsRxChannel) {				  \
			(RingPtr)->BdaRestart = 			  \
				(XAxiDma_Bd *)(UINTPTR)XAxiDma_ReadReg(		  \
					(RingPtr)->ChanBase,  		  \
					XAXIDMA_CDESC_OFFSET);		  \
		} else {						  \
			if (!RingPtr->RingIndex) {				  \
				(RingPtr)->BdaRestart = 		  \
				(XAxiDma_Bd *)(UINTPTR)XAxiDma_ReadReg(            \
					(RingPtr)->ChanBase, 		  \
					XAXIDMA_CDESC_OFFSET);		  \
			} else {					  \
				(RingPtr)->BdaRestart = 		  \
				(XAxiDma_Bd *)(UINTPTR)XAxiDma_ReadReg( 		  \
				(RingPtr)->ChanBase,                      \
				(XAXIDMA_RX_CDESC0_OFFSET +		  \
                                (RingPtr->RingIndex - 1) * 		  \
					XAXIDMA_RX_NDESC_OFFSET)); 	  \
			}						  \
		}							  \
	}

/****************************************************************************/
/**
* Get the BD a BD ring is processing.
*
* @param	RingPtr is the BD ring to operate on.
*
* @return	The current BD that the BD ring is working on
*
* @note
*		C-style signature:
*		XAxiDma_Bd * XAxiDma_BdRingGetCurrBd(XAxiDma_BdRing* RingPtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingGetCurrBd(RingPtr)               \
	(XAxiDma_Bd *)XAxiDma_ReadReg((RingPtr)->ChanBase, \
					XAXIDMA_CDESC_OFFSET)              \

/****************************************************************************/
/**
* Return the next BD in the ring.
*
* @param	RingPtr is the BD ring to operate on.
* @param	BdPtr is the current BD.
*
* @return	The next BD in the ring relative to the BdPtr parameter.
*
* @note
*		C-style signature:
*		XAxiDma_Bd *XAxiDma_BdRingNext(XAxiDma_BdRing* RingPtr,
*							XAxiDma_Bd *BdPtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingNext(RingPtr, BdPtr)			\
		(((UINTPTR)(BdPtr) >= (RingPtr)->LastBdAddr) ?	\
			(UINTPTR)(RingPtr)->FirstBdAddr :	\
			(UINTPTR)((UINTPTR)(BdPtr) + (RingPtr)->Separation))

/****************************************************************************/
/**
* Return the previous BD in the ring.
*
* @param	RingPtr is the DMA channel to operate on.
* @param	BdPtr is the current BD.
*
* @return	The previous BD in the ring relative to the BdPtr parameter.
*
* @note
*		C-style signature:
*		XAxiDma_Bd *XAxiDma_BdRingPrev(XAxiDma_BdRing* RingPtr,
*		XAxiDma_Bd *BdPtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingPrev(RingPtr, BdPtr)				\
		(((u32)(BdPtr) <= (RingPtr)->FirstBdAddr) ?		\
			(XAxiDma_Bd*)(RingPtr)->LastBdAddr :		\
			(XAxiDma_Bd*)((u32)(BdPtr) - (RingPtr)->Separation))

/****************************************************************************/
/**
* Retrieve the contents of the channel status register
*
* @param	RingPtr is the channel instance to operate on.
*
* @return	Current contents of status register
*
* @note
*		C-style signature:
*		u32 XAxiDma_BdRingGetSr(XAxiDma_BdRing* RingPtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingGetSr(RingPtr)				\
		XAxiDma_ReadReg((RingPtr)->ChanBase, XAXIDMA_SR_OFFSET)

/****************************************************************************/
/**
* Get error bits of a DMA channel
*
* @param	RingPtr is the channel instance to operate on.
*
* @return	Rrror bits in the status register, they should be interpreted
*		with XAXIDMA_ERR_*_MASK defined in xaxidma_hw.h
*
* @note
*		C-style signature:
*		u32 XAxiDma_BdRingGetError(XAxiDma_BdRing* RingPtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingGetError(RingPtr)				\
		(XAxiDma_ReadReg((RingPtr)->ChanBase, XAXIDMA_SR_OFFSET) \
			& XAXIDMA_ERR_ALL_MASK)

/****************************************************************************/
/**
* Check whether a DMA channel is started, meaning the channel is not halted.
*
* @param	RingPtr is the channel instance to operate on.
*
* @return
*		- 1 if channel is started
*		- 0 otherwise
*
* @note
*		C-style signature:
*		int XAxiDma_BdRingHwIsStarted(XAxiDma_BdRing* RingPtr)
*
*****************************************************************************/
#define XAxiDma_BdRingHwIsStarted(RingPtr)				\
		((XAxiDma_ReadReg((RingPtr)->ChanBase, XAXIDMA_SR_OFFSET) \
			& XAXIDMA_HALTED_MASK) ? FALSE : TRUE)

/****************************************************************************/
/**
* Check if the current DMA channel is busy with a DMA operation.
*
* @param	RingPtr is the channel instance to operate on.
*
* @return
*		- 1 if the DMA is busy.
*		- 0 otherwise
*
* @note
*		C-style signature:
*		int XAxiDma_BdRingBusy(XAxiDma_BdRing* RingPtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingBusy(RingPtr)					 \
		(XAxiDma_BdRingHwIsStarted(RingPtr) &&		\
		((XAxiDma_ReadReg((RingPtr)->ChanBase, XAXIDMA_SR_OFFSET) \
			& XAXIDMA_IDLE_MASK) ? FALSE : TRUE))

/****************************************************************************/
/**
* Set interrupt enable bits for a channel. This operation will modify the
* XAXIDMA_CR_OFFSET register.
*
* @param	RingPtr is the channel instance to operate on.
* @param	Mask consists of the interrupt signals to enable.Bits not
*		specified in the mask are not affected.
*
* @note
*		C-style signature:
*		void XAxiDma_BdRingIntEnable(XAxiDma_BdRing* RingPtr, u32 Mask)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingIntEnable(RingPtr, Mask)			\
		(XAxiDma_WriteReg((RingPtr)->ChanBase, XAXIDMA_CR_OFFSET, \
		XAxiDma_ReadReg((RingPtr)->ChanBase, XAXIDMA_CR_OFFSET) \
			| ((Mask) & XAXIDMA_IRQ_ALL_MASK)))

/****************************************************************************/
/**
* Get enabled interrupts of a channel. It is in XAXIDMA_CR_OFFSET register.
*
* @param	RingPtr is the channel instance to operate on.
* @return	Enabled interrupts of a channel. Use XAXIDMA_IRQ_* defined in
*		xaxidma_hw.h to interpret this returned value.
*
* @note
*		C-style signature:
*		u32 XAxiDma_BdRingIntGetEnabled(XAxiDma_BdRing* RingPtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingIntGetEnabled(RingPtr)				\
	(XAxiDma_ReadReg((RingPtr)->ChanBase, XAXIDMA_CR_OFFSET) \
		& XAXIDMA_IRQ_ALL_MASK)

/****************************************************************************/
/**
* Clear interrupt enable bits for a channel. It modifies the
* XAXIDMA_CR_OFFSET register.
*
* @param	RingPtr is the channel instance to operate on.
* @param	Mask consists of the interrupt signals to disable.Bits not
*		specified in the Mask are not affected.
*
* @note
*		C-style signature:
*		void XAxiDma_BdRingIntDisable(XAxiDma_BdRing* RingPtr,
*								u32 Mask)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingIntDisable(RingPtr, Mask)				\
		(XAxiDma_WriteReg((RingPtr)->ChanBase, XAXIDMA_CR_OFFSET, \
		XAxiDma_ReadReg((RingPtr)->ChanBase, XAXIDMA_CR_OFFSET) & \
			~((Mask) & XAXIDMA_IRQ_ALL_MASK)))

/****************************************************************************/
/**
* Retrieve the contents of the channel's IRQ register XAXIDMA_SR_OFFSET. This
* operation can be used to see which interrupts are pending.
*
* @param	RingPtr is the channel instance to operate on.
*
* @return	Current contents of the IRQ_OFFSET register. Use
*		XAXIDMA_IRQ_*** values defined in xaxidma_hw.h to interpret
*		the returned value.
*
* @note
*		C-style signature:
*		u32 XAxiDma_BdRingGetIrq(XAxiDma_BdRing* RingPtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingGetIrq(RingPtr)				\
		(XAxiDma_ReadReg((RingPtr)->ChanBase, XAXIDMA_SR_OFFSET) \
			& XAXIDMA_IRQ_ALL_MASK)

/****************************************************************************/
/**
* Acknowledge asserted interrupts. It modifies XAXIDMA_SR_OFFSET register.
* A mask bit set for an unasserted interrupt has no effect.
*
* @param 	RingPtr is the channel instance to operate on.
* @param	Mask are the interrupt signals to acknowledge
*
* @note
*		C-style signature:
*		void XAxiDma_BdRingAckIrq(XAxiDma_BdRing* RingPtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingAckIrq(RingPtr, Mask)				\
		XAxiDma_WriteReg((RingPtr)->ChanBase, XAXIDMA_SR_OFFSET,\
			(Mask) & XAXIDMA_IRQ_ALL_MASK)

/****************************************************************************/
/**
* Enable Cyclic DMA Mode.
*
* @param	RingPtr is the channel instance to operate on.
*
* @note
*		C-style signature:
*		void XAxiDma_BdRingEnableCyclicDMA(XAxiDma_BdRing* RingPtr)
*		This function is used only when system is configured as SG mode
*
*****************************************************************************/
#define XAxiDma_BdRingEnableCyclicDMA(RingPtr)			\
		(RingPtr->Cyclic = 1)

/****************************************************************************/

/************************* Function Prototypes ******************************/

/*
 * Descriptor ring functions xaxidma_bdring.c
 */
int XAxiDma_StartBdRingHw(XAxiDma_BdRing* RingPtr);
int XAxiDma_UpdateBdRingCDesc(XAxiDma_BdRing* RingPtr);
u32 XAxiDma_BdRingCreate(XAxiDma_BdRing * RingPtr, UINTPTR PhysAddr,
		UINTPTR VirtAddr, u32 Alignment, int BdCount);
int XAxiDma_BdRingClone(XAxiDma_BdRing * RingPtr, XAxiDma_Bd * SrcBdPtr);
int XAxiDma_BdRingAlloc(XAxiDma_BdRing * RingPtr, int NumBd,
		XAxiDma_Bd ** BdSetPtr);
int XAxiDma_BdRingUnAlloc(XAxiDma_BdRing * RingPtr, int NumBd,
		XAxiDma_Bd * BdSetPtr);
int XAxiDma_BdRingToHw(XAxiDma_BdRing * RingPtr, int NumBd,
		XAxiDma_Bd * BdSetPtr);
int XAxiDma_BdRingFromHw(XAxiDma_BdRing * RingPtr, int BdLimit,
		XAxiDma_Bd ** BdSetPtr);
int XAxiDma_BdRingFree(XAxiDma_BdRing * RingPtr, int NumBd,
		XAxiDma_Bd * BdSetPtr);
int XAxiDma_BdRingStart(XAxiDma_BdRing * RingPtr);
int XAxiDma_BdRingSetCoalesce(XAxiDma_BdRing * RingPtr, u32 Counter, u32 Timer);
void XAxiDma_BdRingGetCoalesce(XAxiDma_BdRing * RingPtr,
		u32 *CounterPtr, u32 *TimerPtr);

/* The following functions are for debug only
 */
int XAxiDma_BdRingCheck(XAxiDma_BdRing * RingPtr);
void XAxiDma_BdRingDumpRegs(XAxiDma_BdRing *RingPtr);
#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
/** @} */
