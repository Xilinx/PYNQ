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
* @file xaxidma_porting_guide.h
* @addtogroup axidma_v9_4
* @{
*
* This is a guide on how to move from using the xlldma driver to use xaxidma
* driver.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a jz   05/18/10 First release
* 2.00a jz   08/10/10 Second release, added in xaxidma_g.c, xaxidma_sinit.c,
*                     updated tcl file, added xaxidma_porting_guide.h
* 4.00a rkv  02/22/11 Added support for simple DMA mode
* 6.00a srt  03/27/12 Added support for MCDMA mode
* 7.00a srt  06/18/12 API calls are reverted back for backward compatibility.
*
* </pre>
*
* <b>Overview</b>
*
* The API for xaxidma driver is similar to xlldma driver. The prefix for the
* API functions and structures is XAxiDma_ for the xaxidma driver.
*
* Due to hardware feature changes, signatures of some API functions are a
* little bit different from the xlldma API functions.
*
* We present API functions:
* - That only have prefix changes
* - That have different return type
* - That are new API functions
* - That have been removed
*
* Note that data structures have different prefix of XAxiDma_. Those API
* functions, that have data structures with prefix change, are considered as
* prefix change.
*
* <b>API Functions That Only Have Prefix Changes</b>
*
* <pre>
*         xlldma driver              |         xaxidma driver (upto v5_00_a)
* -----------------------------------------------------------------------
*    XLlDma_Reset(...)               |  XAxiDma_Reset(...)
*    XLlDma_BdRingSnapShotCurrBd(...)|  XAxiDma_BdRingSnapShotCurrBd(...)
*    XLlDma_BdRingNext(...)          |  XAxiDma_BdRingNext(...)
*    XLlDma_BdRingPrev(...)          |  XAxiDma_BdRingPrev(...)
*    XLlDma_BdRingGetSr(...)         |  XAxiDma_BdRingGetSr(...)
*    XLlDma_BdRingBusy(...)          |  XAxiDma_BdRingBusy(...)
*    XLlDma_BdRingIntEnable(...)     |  XAxiDma_BdRingIntEnable(...)
*    XLlDma_BdRingIntDisable(...)    |  XAxiDma_BdRingIntDisable(...)
*    XLlDma_BdRingIntGetEnabled(...) |  XAxiDma_BdRingIntGetEnabled(...)
*    XLlDma_BdRingGetIrq(...)        |  XAxiDma_BdRingGetIrq(...)
*    XLlDma_BdRingAckIrq(...)        |  XAxiDma_BdRingAckIrq(...)
*    XLlDma_BdRingCreate(...)        |  XAxiDma_BdRingCreate(...)
*    XLlDma_BdRingClone(...)         |  XAxiDma_BdRingClone(...)
*    XLlDma_BdRingAlloc(...)         |  XAxiDma_BdRingAlloc(...)
*    XLlDma_BdRingUnAlloc(...)       |  XAxiDma_BdRingUnAlloc(...)
*    XLlDma_BdRingToHw(...)          |  XAxiDma_BdRingToHw(...)
*    XLlDma_BdRingFromHw(...)        |  XAxiDma_BdRingFromHw(...)
*    XLlDma_BdRingFree(...)          |  XAxiDma_BdRingFree(...)
*    XLlDma_BdRingStart(...)         |  XAxiDma_BdRingStart(...)
*    XLlDma_BdRingCheck(...)         |  XAxiDma_BdRingCheck(...)
*    XLlDma_BdRingSetCoalesce(...)   |  XAxiDma_BdRingSetCoalesce(...)
*    XLlDma_BdRingGetCoalesce(...)   |  XAxiDma_BdRingGetCoalesce(...)
*    XLlDma_BdRead(...)              |  XAxiDma_BdRead(...)
*    XLlDma_BdWrite(...)             |  XAxiDma_BdWrite(...)
*    XLlDma_BdClear(...)             |  XAxiDma_BdClear(...)
*    XLlDma_BdSetId(...)             |  XAxiDma_BdSetId(...)
*    XLlDma_BdGetId(...)             |  XAxiDma_BdGetId(...)
*    XLlDma_BdGetLength(...)         |  XAxiDma_BdGetLength(...)
*    XLlDma_BdGetBufAddr(...)        |  XAxiDma_BdGetBufAddr(...)
*
*</pre>
*
* <b>API Functions That Have Different Return Type</b>
*
* Due to possible hardware failures, The caller should check the return value
* of the following functions.
*
* <pre>
*         xlldma driver              |         xaxidma driver
* -----------------------------------------------------------------------
* void XLlDma_Pause(...)             | int XAxiDma_Pause(...)
* void XLlDma_Resume(...)            | int XAxiDma_Resume(...)
* </pre>
*
* The following functions have return type changed:
*
* <pre>
*         xlldma driver              |         xaxidma driver
* -----------------------------------------------------------------------
* XLlDma_BdRing XLlDma_GetRxRing(...)| XAxiDma_BdRing * XAxiDma_GetRxRing(...)
* XLlDma_BdRing XLlDma_GetTxRing(...)| XAxiDma_BdRing * XAxiDma_GetTxRing(...)
* u32 XLlDma_BdRingMemCalc(...)      | int XAxiDma_BdRingMemCalc(...)
* u32 XLlDma_BdRingCntCalc(...)      | int XAxiDma_BdRingCntCalc(...)
* u32 XLlDma_BdRingGetCnt(...)       | int XAxiDma_BdRingGetCnt(...)
* u32 XLlDma_BdRingGetFreeCnt(...)   | int XAxiDma_BdRingGetFreeCnt(...)
* void XLlDma_BdSetLength(...)       | int XAxiDma_BdSetLength(...)
* void XLlDma_BdSetBufAddr(...)      | int XAxiDma_BdSetBufAddr(...)
*</pre>
*
* <b>API Functions That Are New API Functions</b>
*
* Now that the AXI DMA core is a standalone core, some new API are intrduced.
* Some other functions are added due to hardware interface change, so to
* replace old API functions.
*
* - XAxiDma_Config *XAxiDma_LookupConfig(u32 DeviceId);
* - int XAxiDma_CfgInitialize(XAxiDma * InstancePtr, XAxiDma_Config *Config);
* - int XAxiDma_ResetIsDone(XAxiDma * InstancePtr);
* - XAxiDma_Bd * XAxiDma_BdRingGetCurrBd(XAxiDma_BdRing* RingPtr);
* - int XAxiDma_BdRingHwIsStarted(XAxiDma_BdRing* RingPtr);
* - void XAxiDma_BdRingDumpRegs(XAxiDma_BdRing *RingPtr);
* - int XAxiDma_StartBdRingHw(XAxiDma_BdRing* RingPtr);
* - void XAxiDma_BdSetCtrl(XAxiDma_Bd *BdPtr, u32 Data);
* - u32 XAxiDma_BdGetCtrl(XAxiDma_Bd* BdPtr);
* - u32 XAxiDma_BdGetSts(XAxiDma_Bd* BdPtr);
* - int XAxiDma_BdHwCompleted(XAxiDma_Bd* BdPtr);
* - int XAxiDma_BdGetActualLength(XAxiDma_Bd* BdPtr);
* - int XAxiDma_BdSetAppWord(XAxiDma_Bd * BdPtr, int Offset, u32 Word);
* - u32 XAxiDma_BdGetAppWord(XAxiDma_Bd * BdPtr, int Offset, int *Valid);
*
* <b>API Functions That Have Been Removed</b>
*
* Please see individual function comments for how to replace the removed API
* function with new API functions.
*
* - void XLlDma_Initialize(XLlDma * InstancePtr, u32 BaseAddress).
*   This function is replaced by XAxiDma_LookupConfig()/XAxiDma_CfgInitialize()
*
* - u32 XLlDma_BdRingGetCr(XLlDma_BdRing* RingPtr).
*   This is replaced by XAxiDma_BdRingGetError(XAxiDma_BdRing* RingPtr)
*
* - u32 XLlDma_BdRingSetCr(XLlDma_BdRing* RingPtr, u32 Data).
*   This function is covered by other API functions:
*      - void XAxiDma_BdRingIntEnable(XAxiDma_BdRing* RingPtr, u32 Mask)
*      - void XAxiDma_BdRingIntDisable(XAxiDma_BdRing* RingPtr, u32 Mask)
*      - int XAxiDma_BdRingSetCoalesce(XAxiDma_BdRing * RingPtr, u32 Counter,
*            u32 Timer)
*
* - u32 XLlDma_BdSetStsCtrl(XLlDma_Bd* BdPtr, u32 Data).
*   Replaced by XAxiDma_BdSetCtrl(XAxiDma_Bd *BdPtr, u32 Data);
*
* - u32 XLlDma_BdGetStsCtrl(XLlDma_Bd* BdPtr).
*   Replaced by XAxiDma_BdGetCtrl(XAxiDma_Bd* BdPtr) and
*   XAxiDma_BdGetSts(XAxiDma_Bd* BdPtr).
*
* <b>API Functions That Have Been Added to support simple DMA mode</b>
*
* - u32 XAxiDma_Busy(XAxiDma *InstancePtr,int Direction);
* - int XAxiDma_SimpleTransfer(XAxiDma *InstancePtr, u32 BuffAddr, int Length,
*	int Direction);
* - XAxiDma_HasSg(InstancePtr);
* - XAxiDma_IntrEnable(InstancePtr,Mask,Direction);
* - XAxiDma_IntrGetEnabled(InstancePtr, Direction);
* - XAxiDma_IntrDisable(InstancePtr, Mask, Direction);
* - XAxiDma_IntrGetIrq(InstancePtr, Direction);
* - XAxiDma_IntrAckIrq(InstancePtr, Mask, Direction);
*
* <b> For xaxidma driver v6_00_a Multiple Channel Support
*     ---------------------------------------------------
* This driver supports Multi-channel mode and accordingly some APIs are
* changed to index multiple channels. Few new APIs are added.
*  - Changed APIs
*	* XAxiDma_GetRxRing(InstancePtr, RingIndex)
* 	* XAxiDma_Start(XAxiDma * InstancePtr, int RingIndex)
* 	* XAxiDma_Started(XAxiDma * InstancePtr, int RingIndex)
* 	* XAxiDma_Pause(XAxiDma * InstancePtr, int RingIndex)
* 	* XAxiDma_Resume(XAxiDma * InstancePtr, int RingIndex)
* 	* XAxiDma_SimpleTransfer(XAxiDma *InstancePtr,
*			u32 BuffAddr, u32 Length,
*			int Direction, int RingIndex)
*	* XAxiDma_StartBdRingHw(XAxiDma_BdRing * RingPtr,
*			int RingIndex)
*	* XAxiDma_BdRingStart(XAxiDma_BdRing * RingPtr,
*			 int RingIndex)
*	* XAxiDma_BdRingToHw(XAxiDma_BdRing * RingPtr,
*      			int NumBd, XAxiDma_Bd * BdSetPtr, int RingIndex)
*	* XAxiDma_BdRingDumpRegs(XAxiDma_BdRing * RingPtr,
*			 int RingIndex)
*	* XAxiDma_BdRingSnapShotCurrBd(XAxiDma_BdRing * RingPtr,
*			 int RingIndex)
*	* XAxiDma_BdSetLength(XAxiDma_Bd *BdPtr,
*			u32 LenBytes, u32 LengthMask)
*       * XAxiDma_BdGetActualLength(BdPtr, LengthMask)
*	* XAxiDma_BdGetLength(BdPtr, LengthMask)
*
*  - New APIs
*	* XAxiDma_SelectKeyHole(XAxiDma *InstancePtr,
*			int Direction, int Select)
*	* XAxiDma_UpdateBdRingCDesc(XAxiDma_BdRing * RingPtr,
*			int RingIndex)
*	* XAxiDma_BdSetTId()
*	* XAxiDma_BdGetTId()
*	* XAxiDma_BdSetTDest()
*	* XAxiDma_BdGetTDest()
*	* XAxiDma_BdSetTUser()
*	* XAxiDma_BdGetTUser()
*	* XAxiDma_BdSetARCache()
*	* XAxiDma_BdGetARCache()
*	* XAxiDma_BdSetARUser()
*	* XAxiDma_BdGetARUser()
*	* XAxiDma_BdSetStride()
*	* XAxiDma_BdGetStride()
*	* XAxiDma_BdSetVSize()
*	* XAxiDma_BdGetVSize()
* <b> For xaxidma driver v7_00_a
*     ---------------------------------------------------
*  - New API
*	* XAxiDma_GetRxIndexRing(InstancePtr, RingIndex)
*
*  - Changed APIs
*	All the APIs changed in v6_00_a are reverted back for backward
*	compatibility.
*</pre>
*
******************************************************************************/
/** @} */
