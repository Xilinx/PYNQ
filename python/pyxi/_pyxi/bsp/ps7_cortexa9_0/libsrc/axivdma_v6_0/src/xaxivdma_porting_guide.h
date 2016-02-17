/******************************************************************************
*
* Copyright (C) 2012 - 2015 Xilinx, Inc.  All rights reserved.
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
* @file xaxivdma_porting_guide.h
* @addtogroup axivdma_v6_0
* @{
*
* This is a guide on how to move from using the xvdma driver to use xaxivdma
* driver.
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
* 3.00a srt  08/26/11 - Added support for Flush on Frame Sync and dynamic
*		      	programming of Line Buffer Thresholds.
*		      - XAxiVdma_ChannelErrors API is changed to support for
*			Flush on Frame Sync feature.
*		      - Two flags, XST_VDMA_MISMATCH_ERROR & XAXIVDMA_MIS
*			MATCH_ERROR are added to report error status when
*			Flush on Frame Sync feature is enabled.
* 4.00a srt  11/21/11 - XAxiVdma_ChannelSetBufferAddr API is changed to
*			support 32 Frame Stores.
*		      - XAxiVdma_ChannelConfig API is changed to support
*			modified Park Offset Register bits.
*		      - Added APIs:
*			XAxiVdma_FsyncSrcSelect()
*			XAxiVdma_GenLockSourceSelect()
*		      - Modified structures XAxiVdma_Config and XAxiVdma to
*		        include new parameters.
* 4.01a srt  06/13/12 - Added APIs:
*			XAxiVdma_GetDmaChannelErrors()
*			XAxiVdma_ClearDmaChannelErrors()
*			XAxiVdma_ClearChannelErrors()
*		      - XAxiVdma_ChannelErrors API is changed to remove
*			Mismatch error logic.
*		      - Removed Error checking logic in the channel APIs.
*			Provided User APIs to do this.
*		      - Added new error bit mask XAXIVDMA_SR_ERR_SOF_LATE_MASK
*		      - XAXIVDMA_MISMATCH_ERROR flag is deprecated.
* 		      - Modified the logic of Error handling in interrupt
*		        handlers.
* </pre>
*
* <b>Overview</b>
*
* The API for xaxivdma driver is similar to xvdma driver. However, the prefix
* for functions and structures is now XAxiVdma_. Due to hardware changes,
* for AXI_VDMA core in 12.3, we have changed some API functions, removed some
* API functions and added some new API functions.
*
* From 13.1 release, the hardware, v3.00a core supports direct register access
* mode where transfer is set through direct register writes. Scatter gather is
* no longer there if the direct register access mode is selected. This change
* does not impact the driver API.
*
* For 13.2 release, the driver supports re-assigning BD addresses. This comes
* from the user that it is desirable to change the BD addresses to a memory
* region that SG hardware can access.
*
* For 13.4 release, the hardware, v5.00a core has added new features to select
* Internal GenLock and Frame Sync Sources in the control register. Due to
* hardware changes, we have added new API functions for the two new features.
*
* For 14.2 release, the hardware, v5.02a core has modified the handling of
* VDMA errors.  To support this, we have changed some APIs and added some new
* APIs.
*
* <b>API That Only Have Prefix Changes</b>
*
* Note that API includes data structures and functions. For API functions that
* use VDMA data structures or their pointers as arguments, the structures need
* to use the new perfix as well.
*
* The following are the data structures that have prefix changed:
*
*       xvdma API structures         |    xaxivdma API structures
*------------------------------------|------------------------------
*      XVDma                         |       XAxiVdma
*      XVDma_Config                  |       XAxiVdma_Config
*      XVDma_DmaSetup                |       XAxiVdma_DmaSetup
*      XVDmaFrameCounter             |       XAxiVdma_FrameCounter
*
* The following is the list of API functions that only have the prefix changes:
*
*       xvdma API functions          |    xaxivdma API functions
*------------------------------------|------------------------------
*      XVDma_CfgInitialize           | XAxiVdma_CfgInitialize
*      XVDma_StartWriteFrame         | XAxiVdma_StartWriteFrame
*      XVDma_StartReadFrame          | XAxiVdma_StartReadFrame
*      XVDma_SetFrameCounter         | XAxiVdma_SetFrameCounter
*      XVDma_GetFrameCounter         | XAxiVdma_GetFrameCounter
*      XVDma_LookupConfig            | XAxiVdma_LookupConfig
*
* <b>API Functions That Have Been Changed</b>
*
* PLB VDMA only has one channel, while the AXI VDMA has two channels. This
* change has caused some of the API functions to take an extra argument to
* differentiate the channels. The following functions now take an extra
* argument (u16 Direction), the new argument is the last in the argument list:
*
*       xvdma API functions          |    xaxivdma API functions
*------------------------------------|------------------------------
*      XVDma_Reset                   | XAxiVdma_Reset
*      XVDma_IsBusy                  | XAxiVdma_IsBusy
*      XVDma_CurrFrameStore          | XAxiVdma_CurrFrameStore
*      XVDma_IntrEnable              | XAxiVdma_IntrEnable
*      XVDma_IntrDisable             | XAxiVdma_IntrDisable
*      XVDma_IntrGetPending          | XAxiVdma_IntrGetPending
*      XVDma_IntrClear               | XAxiVdma_IntrClear
*      XVDma_SetCallBack             | XAxiVdma_SetCallBack
*
* Note that the xvdma API functions that already have Direction as the argument
* are kept as they are, which are not necessarily having Direction as the last
* argument.
*
* Some API functions have changed return type from void to int. This is to make
* the driver more intelligent and signal the failure early on to the user. The
* following functions have change return type from void to int:
*
*       xvdma API functions          |    xaxivdma API functions
*------------------------------------|------------------------------
*     void XVDma_DmaConfig           | int XAxiVdma_DmaConfig
*     void XVDma_DmaSetBufferAddr    | int XAxiVdma_DmaSetBufferAddr
*     void XVDma_DmaStart            | int XAxiVdma_DmaStart
*
* <b>New API Functions</b>
*
* New core v5.02a has added new features, to support them these APIs are added
*
* int XAxiVdma_GetDmaChannelErrors(XAxiVdma *InstancePtr, u16 Direction)
* int XAxiVdma_ClearDmaChannelErrors(XAxiVdma *InstancePtr, u16 Direction,
*					u32 ErrorMask)
* void XAxiVdma_ClearChannelErrors(XAxiVdma_Channel *Channel, u32 ErrorMask)
*
*
* New core v5.00a has added new features, to support them these APIs are added
*
* int XAxiVdma_FsyncSrcSelect(XAxiVdma *InstancePtr, u32 Source,
*                               u16 Direction)
* int XAxiVdma_GenLockSourceSelect(XAxiVdma *InstancePtr, u32 Source,
*				u16 Direction)
*
*
* Due to addition of frame store register in hardware these functions are added
*
* int XAxiVdma_SetFrmStore(XAxiVdma *InstancePtr, u8 FrmStoreNum,
*								u16 Direction)
* void XAxiVdma_GetFrmStore(XAxiVdma *InstancePtr, u8 *FrmStoreNum,
*								u16 Direction)
*
* Due to the fact that AXI VDMA has two channels, and each channel has its own
* interrupt ID, we removed the single interrupt handler API from xvdma driver,
* and added two interrupt handlers:
*
* . void XAxiVdma_ReadIntrHandler(void *Ref)
* . void XAxiVdma_WriteIntrHandler(void *Ref)
*
* Based on customers feedback on xvdma, we added XAxiVdma_Stop to stop one
* channel:
*
* . void XAxiVdma_Stop(XAxiVdma *InstancePtr, u16 Direction)
*
* We need a function to check whether reset is done:
*
* . int XAxiVdma_ResetNotDone(XAxiVdma *InstancePtr, u16 Direction)
*
* While doing the development, it shows the need for getting the hardware
* status to provide as much information as possible for user's development.
*
* . u32 XAxiVdma_GetStatus(XAxiVdma *InstancePtr, u16 Direction)
*
* Because the hardware limitations, parking mode cannot be the initial mode to
* start the DMA engine. Entering and exiting parking mode have to be done
* after the hardware is running. Therefore, we add two API functions to enter
* and exit park mode.
*
* . void XAxiVdma_StartParking(XAxiVdma *InstancePtr, int FrameIndex,
*         u16 Direction);
* . void XAxiVdma_StopParking(XAxiVdma *InstancePtr, u16 Direction);
*
* Note that configuring the hardware to be in park mode using
* XAxiVdma_DmaConfig() is fine. The advantage of using _StartParking() and
* _StopParking() is the simplicity.
*
* . void XAxiVdma_StartFrmCntEnable(XAxiVdma *InstancePtr, u16 Direction);
*
* This function is used to enable frame count enable. It is much simpler to
* enable frame count enable this way than using the full configuration
* structure.
*
* . int XAxiVdma_SetBdAddrs(XAxiVdma *InstancePtr, u32 BdAddrPhys,
*      u32 BdAddrVirt, int NumBds, u16 Direction);
*
* This function provides the ability for the user application to re-assign
* the BD addresses to whereever in the memory it wants. This is to aid the
* situation that SG engine may have limited access to certain region of the
* memory, comparing to the processor's ability. The default BD addresses are
* inside the region that the processor can access.
*
* <b>API Functions That Have Been Removed</b>
*
* Due to hardware design change, some of the API functions are no longer
* needed:
*
* . XVDma_CmdInerfaceDisable()
* . XVDma_CmdInerfaceEnable()
* . XVDma_FullDuplexDisable()
* . XVDma_FullDuplexEnable()
* . XVDma_HoriCropDisable()
* . XVDma_HoriCropEnable()
* . XVDma_IntrEnableGlobal()
* . XVDma_IntrDisableGlobal()
* . XVDma_IntrHandler()
*
*
******************************************************************************/
/** @} */
