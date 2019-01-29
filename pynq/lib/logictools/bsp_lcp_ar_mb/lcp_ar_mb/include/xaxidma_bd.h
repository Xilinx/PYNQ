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
 * @file xaxidma_bd.h
* @addtogroup axidma_v9_8
* @{
 *
 * Buffer descriptor (BD) management API.
 *
 * <b> Buffer Descriptors </b>
 *
 * A BD defines a DMA transaction (see "Transaction" section in xaxidma.h).
 * All accesses to a BD go through this set of API.
 *
 * The XAxiDma_Bd structure defines a BD. The first XAXIDMA_BD_HW_NUM_BYTES
 * are shared between hardware and software.
 *
 * <b> Actual Transfer Length </b>
 *
 * The actual transfer length for receive could be smaller than the requested
 * transfer length. The hardware sets the actual transfer length in the
 * completed BD. The API to retrieve the actual transfer length is
 * XAxiDma_GetActualLength().
 *
 * <b> User IP words </b>
 *
 * There are 5 user IP words in each BD.
 *
 * If hardware does not have the StsCntrl stream built in, then these words
 * are not usable. Retrieving these words get a NULL pointer and setting
 * these words results an error.
 *
 * <b> Performance </b>
 *
 * BDs are typically in a non-cached memory space. Reducing the number of
 * I/O operations to BDs can improve overall performance of the DMA channel.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- ---- -------- ------------------------------------------------------
 * 1.00a jz   05/18/10 First release
 * 2.00a jz   08/10/10 Second release, added in xaxidma_g.c, xaxidma_sinit.c,
 *                     updated tcl file, added xaxidma_porting_guide.h
 * 3.00a jz   11/22/10 Support IP core parameters change
 * 5.00a srt  08/25/11 Changed Cache Macros to have a common API for Zynq
 *		           and Microblaze.
 * 6.00a srt  01/24/12 Added APIs to support Multi-Channel DMA:
 *			XAxiDma_BdSetTId()
 *			XAxiDma_BdGetTId()
 *			XAxiDma_BdSetTDest()
 *			XAxiDma_BdGetTDest()
 *			XAxiDma_BdSetTUser()
 *			XAxiDma_BdGetTUser()
 *			XAxiDma_BdSetARCache()
 *			XAxiDma_BdGetARCache()
 *			XAxiDma_BdSetARUser()
 *			XAxiDma_BdGetARUser()
 *			XAxiDma_BdSetStride()
 *			XAxiDma_BdGetStride()
 *			XAxiDma_BdSetVSize()
 *			XAxiDma_BdGetVSize()
 *			- Changed APIs
 *			XAxiDma_BdGetActualLength(BdPtr, LengthMask)
 *			XAxiDma_BdGetLength(BdPtr, LengthMask)
 *			XAxiDma_BdSetLength(XAxiDma_Bd* BdPtr,
 *					u32 LenBytes, u32 LengthMask)
 * 7.01a srt  10/26/12  Changed the logic of MCDMA BD fields Set APIs, to
 *			clear the field first and set it.
 * 8.0   srt  01/29/14 Added support for Micro DMA Mode.
 * 9.2   vak  15/04/16 Fixed compilation warnings in axidma driver
 * 9.8   rsp  07/11/18 Fix cppcheck portability warnings. CR #1006164
 *
 * </pre>
 *****************************************************************************/

#ifndef XAXIDMA_BD_H_    /* To prevent circular inclusions */
#define XAXIDMA_BD_H_

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xaxidma_hw.h"
#include "xstatus.h"
#include "xdebug.h"
#include "xil_cache.h"

#ifdef __MICROBLAZE__
#include "xenv.h"
#else
#include <string.h>
#endif

/************************** Constant Definitions *****************************/

/**************************** Type Definitions *******************************/

/**
 * The XAxiDma_Bd is the type for a buffer descriptor (BD).
 */

typedef u32 XAxiDma_Bd[XAXIDMA_BD_NUM_WORDS];


/***************** Macros (Inline Functions) Definitions *********************/

/******************************************************************************
 * Define methods to flush and invalidate cache for BDs should they be
 * located in cached memory.
 *****************************************************************************/
#ifdef __aarch64__
#define XAXIDMA_CACHE_FLUSH(BdPtr)
#define XAXIDMA_CACHE_INVALIDATE(BdPtr)
#else
#define XAXIDMA_CACHE_FLUSH(BdPtr) \
	Xil_DCacheFlushRange((UINTPTR)(BdPtr), XAXIDMA_BD_HW_NUM_BYTES)

#define XAXIDMA_CACHE_INVALIDATE(BdPtr) \
	Xil_DCacheInvalidateRange((UINTPTR)(BdPtr), XAXIDMA_BD_HW_NUM_BYTES)
#endif

/*****************************************************************************/
/**
*
* Read the given Buffer Descriptor word.
*
* @param	BaseAddress is the base address of the BD to read
* @param	Offset is the word offset to be read
*
* @return	The 32-bit value of the field
*
* @note
*		C-style signature:
*		u32 XAxiDma_BdRead(u32 BaseAddress, u32 Offset)
*
******************************************************************************/
#define XAxiDma_BdRead(BaseAddress, Offset)				\
	(*(u32 *)((UINTPTR)(BaseAddress) + (u32)(Offset)))

/*****************************************************************************/
/**
*
* Write the given Buffer Descriptor word.
*
* @param	BaseAddress is the base address of the BD to write
* @param	Offset is the word offset to be written
* @param	Data is the 32-bit value to write to the field
*
* @return	None.
*
* @note
* 		C-style signature:
*		void XAxiDma_BdWrite(u32 BaseAddress, u32 RegOffset, u32 Data)
*
******************************************************************************/
#define XAxiDma_BdWrite(BaseAddress, Offset, Data)			\
	(*(u32 *)((UINTPTR)(void *)(BaseAddress) + (u32)(Offset))) = (u32)(Data)

/*****************************************************************************/
/**
*
* Write the given Buffer Descriptor word.
*
* @param	BaseAddress is the base address of the BD to write
* @param	Offset is the word offset to be written
* @param	Data is the 64-bit value to write to the field
*
* @return	None.
*
* @note
* 		C-style signature:
*		void XAxiDma_BdWrite(u64 BaseAddress, u32 RegOffset, u64 Data)
*
******************************************************************************/
#define XAxiDma_BdWrite64(BaseAddress, Offset, Data)			\
	(*(u64 *)((UINTPTR)(void *)(BaseAddress) + (u32)(Offset))) = (u64)(Data)

/*****************************************************************************/
/**
 * Zero out BD specific fields. BD fields that are for the BD ring or for the
 * system hardware build information are not touched.
 *
 * @param	BdPtr is the BD to operate on
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		void XAxiDma_BdClear(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdClear(BdPtr)                    \
  memset((void *)(((UINTPTR)(BdPtr)) + XAXIDMA_BD_START_CLEAR), 0, \
    XAXIDMA_BD_BYTES_TO_CLEAR)

/*****************************************************************************/
/**
 * Get the control bits for the BD
 *
 * @param	BdPtr is the BD to operate on
 *
 * @return	The bit mask for the control of the BD
 *
 * @note
 *		C-style signature:
 *		u32 XAxiDma_BdGetCtrl(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdGetCtrl(BdPtr)				\
		(XAxiDma_BdRead((BdPtr), XAXIDMA_BD_CTRL_LEN_OFFSET)	\
		& XAXIDMA_BD_CTRL_ALL_MASK)
/*****************************************************************************/
/**
 * Retrieve the status of a BD
 *
 * @param	BdPtr is the BD to operate on
 *
 * @return	Word at offset XAXIDMA_BD_DMASR_OFFSET. Use XAXIDMA_BD_STS_***
 *		values defined in xaxidma_hw.h to interpret the returned value
 *
 * @note
 *		C-style signature:
 *		u32 XAxiDma_BdGetSts(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdGetSts(BdPtr)              \
	(XAxiDma_BdRead((BdPtr), XAXIDMA_BD_STS_OFFSET) & \
		XAXIDMA_BD_STS_ALL_MASK)
/*****************************************************************************/
/**
 * Retrieve the length field value from the given BD.  The returned value is
 * the same as what was written with XAxiDma_BdSetLength(). Note that in the
 * this value does not reflect the real length of received data.
 * See the comments of XAxiDma_BdSetLength() for more details. To obtain the
 * actual transfer length, use XAxiDma_BdGetActualLength().
 *
 * @param	BdPtr is the BD to operate on.
 * @param	LengthMask is the Maximum Transfer Length.
 *
 * @return	The length value set in the BD.
 *
 * @note
 *		C-style signature:
 *		u32 XAxiDma_BdGetLength(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdGetLength(BdPtr, LengthMask)                \
	(XAxiDma_BdRead((BdPtr), XAXIDMA_BD_CTRL_LEN_OFFSET) & \
		LengthMask)


/*****************************************************************************/
/**
 * Set the ID field of the given BD. The ID is an arbitrary piece of data the
 * application can associate with a specific BD.
 *
 * @param	BdPtr is the BD to operate on
 * @param	Id is a 32 bit quantity to set in the BD
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		void XAxiDma_BdSetId(XAxiDma_Bd* BdPtr, void Id)
 *
 *****************************************************************************/
#define XAxiDma_BdSetId(BdPtr, Id)                                      \
	(XAxiDma_BdWrite((BdPtr), XAXIDMA_BD_ID_OFFSET, (UINTPTR)(Id)))


/*****************************************************************************/
/**
 * Retrieve the ID field of the given BD previously set with XAxiDma_BdSetId.
 *
 * @param	BdPtr is the BD to operate on
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		u32 XAxiDma_BdGetId(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdGetId(BdPtr) (XAxiDma_BdRead((BdPtr), XAXIDMA_BD_ID_OFFSET))

/*****************************************************************************/
/**
 * Get the BD's buffer address
 *
 * @param	BdPtr is the BD to operate on
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		u32 XAxiDma_BdGetBufAddr(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdGetBufAddr(BdPtr)                     \
	(XAxiDma_BdRead((BdPtr), XAXIDMA_BD_BUFA_OFFSET))

/*****************************************************************************/
/**
 * Check whether a BD has completed in hardware. This BD has been submitted
 * to hardware. The application can use this function to poll for the
 * completion of the BD.
 *
 * This function may not work if the BD is in cached memory.
 *
 * @param	BdPtr is the BD to check on
 *
 * @return
 *		- 0 if not complete
 *		- XAXIDMA_BD_STS_COMPLETE_MASK if completed, may contain
 * 		XAXIDMA_BD_STS_*_ERR_MASK bits.
 *
 * @note
 * 		C-style signature:
 *		int XAxiDma_BdHwCompleted(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdHwCompleted(BdPtr)                     \
	(XAxiDma_BdRead((BdPtr), XAXIDMA_BD_STS_OFFSET) & \
		XAXIDMA_BD_STS_COMPLETE_MASK)

/*****************************************************************************/
/**
 * Get the actual transfer length of a BD. The BD has completed in hw.
 *
 * This function may not work if the BD is in cached memory.
 *
 * @param	BdPtr is the BD to check on
 * @param	LengthMask is the Maximum Transfer Length.
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		int XAxiDma_BdGetActualLength(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdGetActualLength(BdPtr, LengthMask)      \
	(XAxiDma_BdRead((BdPtr), XAXIDMA_BD_STS_OFFSET) & \
		LengthMask)

/*****************************************************************************/
/**
 * Set the TID field of the TX BD.
 * Provides a stream identifier and can be used to differentiate between
 * multiple streams of data that are being transferred across the same
 * interface.
 *
 * @param	BdPtr is the BD to operate on
 * @param	TId is a 8 bit quantity to set in the BD
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		void XAxiDma_BdSetTId(XAxiDma_Bd* BdPtr, void TId)
 *
 *****************************************************************************/
#define XAxiDma_BdSetTId(BdPtr, TId) \
{ \
	u32 val; \
	val = (XAxiDma_BdRead((BdPtr), XAXIDMA_BD_MCCTL_OFFSET) & \
		~XAXIDMA_BD_TID_FIELD_MASK); \
	val |= ((u32)(TId) << XAXIDMA_BD_TID_FIELD_SHIFT); \
	XAxiDma_BdWrite((BdPtr), XAXIDMA_BD_MCCTL_OFFSET, val); \
}

/*****************************************************************************/
/**
 * Retrieve the TID field of the RX BD previously set with XAxiDma_BdSetTId.
 *
 * @param	BdPtr is the BD to operate on
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		u32 XAxiDma_BdGetTId(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdGetTId(BdPtr) \
	((XAxiDma_BdRead((BdPtr), XAXIDMA_BD_STS_OFFSET)) &  \
		XAXIDMA_BD_TID_FIELD_MASK)

/*****************************************************************************/
/**
 * Set the TDEST field of the TX BD.
 * Provides coarse routing information for the data stream.
 *
 * @param	BdPtr is the BD to operate on
 * @param	TDest is a 8 bit quantity to set in the BD
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		void XAxiDma_BdSetTDest(XAxiDma_Bd* BdPtr, void TDest)
 *
 *****************************************************************************/
#define XAxiDma_BdSetTDest(BdPtr, TDest) \
{ \
	u32 val; \
	val = (XAxiDma_BdRead((BdPtr), XAXIDMA_BD_MCCTL_OFFSET) & \
		~XAXIDMA_BD_TDEST_FIELD_MASK); \
	val |= ((u32)(TDest) << XAXIDMA_BD_TDEST_FIELD_SHIFT); \
	XAxiDma_BdWrite((BdPtr), XAXIDMA_BD_MCCTL_OFFSET, val); \
}

/*****************************************************************************/
/**
 * Retrieve the TDest field of the RX BD previously set with i
 * XAxiDma_BdSetTDest.
 *
 * @param	BdPtr is the BD to operate on
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		u32 XAxiDma_BdGetTDest(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdGetTDest(BdPtr) \
	((XAxiDma_BdRead((BdPtr), XAXIDMA_BD_STS_OFFSET)) &  \
		XAXIDMA_BD_TDEST_FIELD_MASK)

/*****************************************************************************/
/**
 * Set the TUSER field of the TX BD.
 * User defined sideband signaling.
 *
 * @param	BdPtr is the BD to operate on
 * @param	TUser is a 8 bit quantity to set in the BD
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		void XAxiDma_BdSetTUser(XAxiDma_Bd* BdPtr, void TUser)
 *
 *****************************************************************************/
#define XAxiDma_BdSetTUser(BdPtr, TUser)	\
{ \
	u32 val; \
	val = (XAxiDma_BdRead((BdPtr), XAXIDMA_BD_MCCTL_OFFSET) & \
		~XAXIDMA_BD_TUSER_FIELD_MASK); \
	val |= ((u32)(TUser) << XAXIDMA_BD_TUSER_FIELD_SHIFT); \
	XAxiDma_BdWrite((BdPtr), XAXIDMA_BD_MCCTL_OFFSET, val); \
}

/*****************************************************************************/
/**
 * Retrieve the TUSER field of the RX BD previously set with
 * XAxiDma_BdSetTUser.
 *
 * @param	BdPtr is the BD to operate on
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		u32 XAxiDma_BdGetTUser(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdGetTUser(BdPtr) \
	((XAxiDma_BdRead((BdPtr), XAXIDMA_BD_STS_OFFSET)) &  \
		XAXIDMA_BD_TUSER_FIELD_MASK)

/*****************************************************************************/
/**
 * Set the ARCACHE field of the given BD.
 * This signal provides additional information about the cacheable
 * characteristics of the transfer.
 *
 * @param	BdPtr is the BD to operate on
 * @param	ARCache is a 8 bit quantity to set in the BD
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		void XAxiDma_BdSetARCache(XAxiDma_Bd* BdPtr, void ARCache)
 *
 *****************************************************************************/
#define XAxiDma_BdSetARCache(BdPtr, ARCache) \
{ \
	u32 val; \
	val = (XAxiDma_BdRead((BdPtr), XAXIDMA_BD_MCCTL_OFFSET) & \
		~XAXIDMA_BD_ARCACHE_FIELD_MASK); \
	val |= ((u32)(ARCache) << XAXIDMA_BD_ARCACHE_FIELD_SHIFT); \
	XAxiDma_BdWrite((BdPtr), XAXIDMA_BD_MCCTL_OFFSET, val); \
}

/*****************************************************************************/
/**
 * Retrieve the ARCACHE field of the given BD previously set with
 * XAxiDma_BdSetARCache.
 *
 * @param	BdPtr is the BD to operate on
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		u32 XAxiDma_BdGetARCache(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdGetARCache(BdPtr) \
	((XAxiDma_BdRead((BdPtr), XAXIDMA_BD_MCCTL_OFFSET)) &  \
		XAXIDMA_BD_ARCACHE_FIELD_MASK)


/*****************************************************************************/
/**
 * Set the ARUSER field of the given BD.
 * Sideband signals used for user defined information.
 *
 * @param	BdPtr is the BD to operate on
 * @param	ARUser is a 8 bit quantity to set in the BD
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		void XAxiDma_BdSetARUser(XAxiDma_Bd* BdPtr, void ARUser)
 *
 *****************************************************************************/
#define XAxiDma_BdSetARUser(BdPtr, ARUser) \
{ \
	u32 val; \
	val = (XAxiDma_BdRead((BdPtr), XAXIDMA_BD_MCCTL_OFFSET) & \
		~XAXIDMA_BD_ARUSER_FIELD_MASK); \
	val |= ((u32)(ARUser) << XAXIDMA_BD_ARUSER_FIELD_SHIFT); \
	XAxiDma_BdWrite((BdPtr), XAXIDMA_BD_MCCTL_OFFSET, val); \
}


/*****************************************************************************/
/**
 * Retrieve the ARUSER field of the given BD previously set with
 * XAxiDma_BdSetARUser.
 *
 * @param	BdPtr is the BD to operate on
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		u32 XAxiDma_BdGetARUser(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdGetARUser(BdPtr) \
	((XAxiDma_BdRead((BdPtr), XAXIDMA_BD_MCCTL_OFFSET)) &  \
		XAXIDMA_BD_ARUSER_FIELD_MASK)

/*****************************************************************************/
/**
 * Set the STRIDE field of the given BD.
 * It is the address distance between the first address of successive
 * horizontal reads.
 *
 * @param	BdPtr is the BD to operate on
 * @param	Stride is a 32 bit quantity to set in the BD
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		void XAxiDma_BdSetStride(XAxiDma_Bd* BdPtr, void Stride)
 *
 *****************************************************************************/
#define XAxiDma_BdSetStride(BdPtr, Stride) \
{ \
	u32 val; \
	val = (XAxiDma_BdRead((BdPtr), XAXIDMA_BD_STRIDE_VSIZE_OFFSET) & \
		~XAXIDMA_BD_STRIDE_FIELD_MASK); \
	val |= ((u32)(Stride) << XAXIDMA_BD_STRIDE_FIELD_SHIFT); \
	XAxiDma_BdWrite((BdPtr), XAXIDMA_BD_STRIDE_VSIZE_OFFSET, val); \
}

/*****************************************************************************/
/**
 * Retrieve the STRIDE field of the given BD previously set with
 * XAxiDma_BdSetStride.
 *
 * @param	BdPtr is the BD to operate on
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		u32 XAxiDma_BdGetStride(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdGetStride(BdPtr) \
	((XAxiDma_BdRead((BdPtr), XAXIDMA_BD_STRIDE_VSIZE_OFFSET)) &  \
		XAXIDMA_BD_STRIDE_FIELD_MASK)

/*****************************************************************************/
/**
 * Set the VSIZE field of the given BD.
 * Number of horizontal lines for strided access.
 *
 * @param	BdPtr is the BD to operate on
 * @param	VSize is a 32 bit quantity to set in the BD
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		void XAxiDma_BdSetVSize(XAxiDma_Bd* BdPtr, void VSize)
 *
 *****************************************************************************/
#define XAxiDma_BdSetVSize(BdPtr, VSize) \
{ \
	u32 val; \
	val = (XAxiDma_BdRead((BdPtr), XAXIDMA_BD_STRIDE_VSIZE_OFFSET) & \
		~XAXIDMA_BD_VSIZE_FIELD_MASK); \
	val |= ((u32)(VSize) << XAXIDMA_BD_VSIZE_FIELD_SHIFT); \
	XAxiDma_BdWrite((BdPtr), XAXIDMA_BD_STRIDE_VSIZE_OFFSET, val); \
}

/*****************************************************************************/
/**
 * Retrieve the STRIDE field of the given BD previously set with
 * XAxiDma_BdSetVSize.
 *
 * @param	BdPtr is the BD to operate on
 *
 * @return	None
 *
 * @note
 *		C-style signature:
 *		u32 XAxiDma_BdGetVSize(XAxiDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiDma_BdGetVSize(BdPtr) \
	((XAxiDma_BdRead((BdPtr), XAXIDMA_BD_STRIDE_VSIZE_OFFSET)) &  \
		XAXIDMA_BD_VSIZE_FIELD_MASK)

/*****************************************************************************/

/************************** Function Prototypes ******************************/

int XAxiDma_BdSetLength(XAxiDma_Bd* BdPtr, u32 LenBytes, u32 LengthMask);
u32 XAxiDma_BdSetBufAddr(XAxiDma_Bd* BdPtr, UINTPTR Addr);
u32 XAxiDma_BdSetBufAddrMicroMode(XAxiDma_Bd* BdPtr, UINTPTR Addr);
int XAxiDma_BdSetAppWord(XAxiDma_Bd * BdPtr, int Offset, u32 Word);
u32 XAxiDma_BdGetAppWord(XAxiDma_Bd * BdPtr, int Offset, int *Valid);
void XAxiDma_BdSetCtrl(XAxiDma_Bd *BdPtr, u32 Data);

/* Debug utility
 */
void XAxiDma_DumpBd(XAxiDma_Bd* BdPtr);

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
/** @} */
