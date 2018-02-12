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
 *  @file xaxicdma_bd.h
* @addtogroup axicdma_v4_0
* @{
 *
 * The API definition for the Buffer Descriptor (BD).
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- ---- -------- -------------------------------------------------------
 * 1.00a jz   04/16/10 First release
 * </pre>
 *
 *****************************************************************************/

#ifndef XAXICDMA_BD_H_    /* prevent circular inclusions */
#define XAXICDMA_BD_H_

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/
#include "xstatus.h"
#include "xaxicdma_hw.h"
#include "xdebug.h"

/************************** Constant Definitions *****************************/

/**************************** Type Definitions *******************************/
/**
 * XAxiCdma_Bd
 *
 * Buffer descriptor, shared by hardware and software
 * The structure of the BD is as the following, however, the user never
 * directly accesses the fields in the BD. The following shows the fields
 * inside a BD:
 *
 *  u32 NextBdPtr;
 *  u32 NextBdPtrMsb;
 *  u32 SrcAddr;
 *  u32 SrcAddrMsb;
 *  u32 DstAddr;
 *  u32 DstAddrMsb;
 *  int Length;
 *  u32 Status;
 *  u32 PhysAddr;
 *  u32 IsLite;
 *  u32 HasDRE;
 *  u32 WordLen;
 *  u32 Addrlen;
 */
typedef UINTPTR XAxiCdma_Bd[XAXICDMA_BD_NUM_WORDS];

/**************************** Macros (Inline Functions) Definitions **********/

/*****************************************************************************/
/* Macros to read a word from a BD
 *
 * @note
 * c-style signature:
 *   u32 XAxiCdma_BdRead(XAxiCdma_Bd* BdPtr, int Offset);
 *****************************************************************************/
#define XAxiCdma_BdRead(BdPtr, Offset)   \
	(*(u32 *)((UINTPTR)((void *)(BdPtr)) + (u32)(Offset)))

/*****************************************************************************/
/* Macros to write to a word in a BD
 *
 * @note
 * c-style signature:
 *    u32 XAxiCdma_BdWrite(XAxiCdma_Bd* BdPtr, int Offset, u32 Value )
 *****************************************************************************/
#define XAxiCdma_BdWrite(BdPtr, Offset, Value)   \
	(*(u32 *)((UINTPTR)(void *)(BdPtr) + (u32)(Offset))) = (u32)(Value)

/*****************************************************************************/
/* Set the Addrelen field of the BD.
 *
 * @param  BdPtr is the BD to operate on
 * @param  Addrlen is the Address width of the CDMA
 *
 * @note
 * 	C-style signature:
 *	u32 XAxiCdma_BdSetAddrLen(XAxiCdma_Bd* BdPtr, int AddrLen)
 *****************************************************************************/
#define XAxiCdma_BdSetAddrLen(BdPtr, AddrLen)   \
       XAxiCdma_BdWrite(BdPtr, XAXICDMA_BD_ADDRLEN_OFFSET, AddrLen);

/*****************************************************************************/
/* Get the BD's Address length
 *
 * @param  BdPtr is the BD to operate on
 *
 * @return None
 *
 * @note
 *	C-style signature:
 *	u32 XAxiCdma_BdGetAddrLength(XAxiCdma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XAxiCdma_BdGetAddrLength(BdPtr)   \
       XAxiCdma_BdRead(BdPtr, XAXICDMA_BD_ADDRLEN_OFFSET);


/************************** Function Prototypes ******************************/

void XAxiCdma_BdClear(XAxiCdma_Bd *BdPtr);
void XAxiCdma_BdClone(XAxiCdma_Bd *BdPtr, XAxiCdma_Bd *TmpBd);
LONG XAxiCdma_BdGetNextPtr(XAxiCdma_Bd *BdPtr);
void XAxiCdma_BdSetNextPtr(XAxiCdma_Bd *BdPtr, UINTPTR NextBdPtr);
u32 XAxiCdma_BdGetSts(XAxiCdma_Bd *BdPtr);
void XAxiCdma_BdClearSts(XAxiCdma_Bd *BdPtr);
u32 XAxiCdma_BdSetSrcBufAddr(XAxiCdma_Bd *BdPtr, UINTPTR Addr);
LONG XAxiCdma_BdGetSrcBufAddr(XAxiCdma_Bd *BdPtr);
u32 XAxiCdma_BdSetDstBufAddr(XAxiCdma_Bd *BdPtr, UINTPTR Addr);
LONG XAxiCdma_BdGetDstBufAddr(XAxiCdma_Bd *BdPtr);
u32 XAxiCdma_BdSetLength(XAxiCdma_Bd *BdPtr, int LenBytes);
u32 XAxiCdma_BdGetLength(XAxiCdma_Bd *BdPtr);
void XAxiCdma_BdSetPhysAddr(XAxiCdma_Bd *BdPtr, UINTPTR PhysAddr);
void XAxiCdma_BdSetIsLite(XAxiCdma_Bd *BdPtr, int IsLite);
void XAxiCdma_BdSetHasDRE(XAxiCdma_Bd *BdPtr, int HasDRE);
void XAxiCdma_BdSetWordLen(XAxiCdma_Bd *BdPtr, int WordLen);
void XAxiCdma_BdSetMaxLen(XAxiCdma_Bd *BdPtr, int MaxLen);
LONG XAxiCdma_BdGetPhysAddr(XAxiCdma_Bd *BdPtr);

void XAxiCdma_DumpBd(XAxiCdma_Bd* BdPtr);

#ifdef __cplusplus
}
#endif

#endif    /* prevent circular inclusions */
/** @} */
