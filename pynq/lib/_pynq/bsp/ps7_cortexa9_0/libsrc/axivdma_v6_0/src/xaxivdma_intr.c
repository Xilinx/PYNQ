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
* @file xaxivdma_intr.c
* @addtogroup axivdma_v6_0
* @{
*
* Implementation of interrupt related functions.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a jz   08/16/10 First release
* 2.00a jz   12/10/10 Added support for direct register access mode, v3 core
* 2.01a jz   01/19/11 Added ability to re-assign BD addresses
* 4.01a srt  06/13/12 Modified the logic of Error handling in interrupt
*		      handlers.
* 4.06a srt  04/09/13 Added API XAxiVdma_MaskS2MMErrIntr which will mask
*		      the S2MM interrupt for the error mask provided.
*		      (CR 734741)
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xaxivdma.h"
#include "xaxivdma_i.h"

/*****************************************************************************/
/**
 * Enable specific interrupts for a channel
 *
 * Interrupts not specified by the mask will not be affected
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the DMA channel, use XAXIVDMA_READ or XAXIVDMA_WRITE
 * @param IntrType is the bit mask for the interrups to be enabled
 *
 * @return
 *  None
 *
 * @note
 * If channel is invalid, then nothing is done
 *****************************************************************************/
void XAxiVdma_IntrEnable(XAxiVdma *InstancePtr, u32 IntrType, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (Channel->IsValid) {
		XAxiVdma_ChannelEnableIntr(Channel, IntrType);
	}

	return;
}

/*****************************************************************************/
/**
 * Disable specific interrupts for a channel
 *
 * Interrupts not specified by the mask will not be affected
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param IntrType is the bit mask for the interrups to be disabled
 * @param Direction is the DMA channel, use XAXIVDMA_READ or XAXIVDMA_WRITE
 *
 * @return
 *  None
 *
 * @note
 * If channel is invalid, then nothing is done
 *****************************************************************************/
void XAxiVdma_IntrDisable(XAxiVdma *InstancePtr, u32 IntrType, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (Channel->IsValid) {
		XAxiVdma_ChannelDisableIntr(Channel, IntrType);
	}

	return;
}

/*****************************************************************************/
/**
 * Get the pending interrupts of a channel
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the DMA channel, use XAXIVDMA_READ or XAXIVDMA_WRITE
 *
 * @return
 * The bit mask for the currently pending interrupts
 *
 * @note
 * If Direction is invalid, return 0
 *****************************************************************************/
u32 XAxiVdma_IntrGetPending(XAxiVdma *InstancePtr, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "IntrGetPending: invalid direction %d\n\r", Direction);

		return 0;
	}

	if (Channel->IsValid) {
		return XAxiVdma_ChannelGetPendingIntr(Channel);
	}
	else {
		/* An invalid channel has no intr
		 */
		return 0;
	}
}

/*****************************************************************************/
/**
 * Clear the pending interrupts specified by the bit mask
 *
 * Interrupts not specified by the mask will not be affected
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param Direction is the DMA channel, use XAXIVDMA_READ or XAXIVDMA_WRITE
 * @param IntrType is the bit mask for the interrups to be cleared
 *
 * @return
 *  None
 *
 * @note
 * If channel is invalid, then nothing is done
 *****************************************************************************/
void XAxiVdma_IntrClear(XAxiVdma *InstancePtr, u32 IntrType, u16 Direction)
{
	XAxiVdma_Channel *Channel;

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (Channel->IsValid) {
		XAxiVdma_ChannelIntrClear(Channel, IntrType);
	}
	return;
}

/*****************************************************************************/
/**
 * Masks the S2MM error interrupt for the provided error mask value
 *
 * @param	InstancePtr is the XAxiVdma instance to operate on
 * @param	ErrorMask is the mask of error bits for which S2MM error
 *		interrupt can be disabled.
 * @param	Direction is the channel to work on, use XAXIVDMA_READ/WRITE
 *
 * @return	- XST_SUCCESS, when error bits are cleared.
 *		- XST_INVALID_PARAM, when channel pointer is invalid.
 *		- XST_DEVICE_NOT_FOUND, when the channel is not valid.
 *
 * @note	The register S2MM_DMA_IRQ_MASK is only applicable from IPv6.01a
 *		which is added at offset XAXIVDMA_S2MM_DMA_IRQ_MASK_OFFSET.
 *		For older versions, this offset location is reserved and so
 *		the API does not have any effect.
 *
 *****************************************************************************/
int XAxiVdma_MaskS2MMErrIntr(XAxiVdma *InstancePtr, u32 ErrorMask,
					u16 Direction)
{
	XAxiVdma_Channel *Channel;

	if (Direction != XAXIVDMA_WRITE) {
		return XST_INVALID_PARAM;
	}

	Channel = XAxiVdma_GetChannel(InstancePtr, Direction);

	if (!Channel) {
		return XST_INVALID_PARAM;
	}

	if (Channel->IsValid) {
		XAxiVdma_WriteReg(Channel->ChanBase,
			XAXIVDMA_S2MM_DMA_IRQ_MASK_OFFSET,
			ErrorMask & XAXIVDMA_S2MM_IRQ_ERR_ALL_MASK);

		return XST_SUCCESS;
	}

	return XST_DEVICE_NOT_FOUND;
}

/*****************************************************************************/
/**
 * Interrupt handler for the read channel
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 *
 * @return
 *  None
 *
 * @note
 * If the channel is invalid, then no interrupt handling
 *****************************************************************************/
void XAxiVdma_ReadIntrHandler(void * InstancePtr)
{
	XAxiVdma *DmaPtr;
	XAxiVdma_Channel *Channel;
	XAxiVdma_ChannelCallBack *CallBack;
	u32 PendingIntr;

	DmaPtr = (XAxiVdma *)InstancePtr;

	CallBack = &(DmaPtr->ReadCallBack);

	if (!CallBack->CompletionCallBack) {

		return;
	}

	Channel = XAxiVdma_GetChannel(DmaPtr, XAXIVDMA_READ);

	if (!Channel->IsValid) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Read channel is invalid, no intr handling\n\r");

		return;
	}

	PendingIntr = XAxiVdma_ChannelGetPendingIntr(Channel);
	PendingIntr &= XAxiVdma_ChannelGetEnabledIntr(Channel);

	XAxiVdma_ChannelIntrClear(Channel, PendingIntr);

	if (!PendingIntr || (PendingIntr & XAXIVDMA_IXR_ERROR_MASK)) {

		CallBack->ErrCallBack(CallBack->ErrRef,
		    PendingIntr & XAXIVDMA_IXR_ERROR_MASK);

		/* The channel's error callback should reset the channel
		 * There is no need to handle other interrupts
		 */
		return;
	}

	if (PendingIntr & XAXIVDMA_IXR_COMPLETION_MASK) {

		CallBack->CompletionCallBack(CallBack->CompletionRef,
		    PendingIntr);
	}

	return;
}

/*****************************************************************************/
/**
 * Interrupt handler for the write channel
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 *
 * @return
 *  None
 *
 * @note
 * If the channel is invalid, then no interrupt handling
 *****************************************************************************/
void XAxiVdma_WriteIntrHandler(void * InstancePtr)
{
	XAxiVdma *DmaPtr;
	XAxiVdma_Channel *Channel;
	XAxiVdma_ChannelCallBack *CallBack;
	u32 PendingIntr;

	DmaPtr = (XAxiVdma *)InstancePtr;

	Channel = XAxiVdma_GetChannel(DmaPtr, XAXIVDMA_WRITE);

	if (!Channel->IsValid) {
		xdbg_printf(XDBG_DEBUG_ERROR,
		    "Write channel is invalid, no intr handling\n\r");

		return;
	}

	PendingIntr = XAxiVdma_ChannelGetPendingIntr(Channel);
	PendingIntr &= XAxiVdma_ChannelGetEnabledIntr(Channel);

	XAxiVdma_ChannelIntrClear(Channel, PendingIntr);

	CallBack = &(DmaPtr->WriteCallBack);

	if (!CallBack->CompletionCallBack) {

		return;
	}

	if (!PendingIntr || (PendingIntr & XAXIVDMA_IXR_ERROR_MASK)) {

		CallBack->ErrCallBack(CallBack->ErrRef,
		    PendingIntr & XAXIVDMA_IXR_ERROR_MASK);

		/* The channel's error callback should reset the channel
		 * There is no need to handle other interrupts
		 */
		return;
	}

	if (PendingIntr & XAXIVDMA_IXR_COMPLETION_MASK) {

		CallBack->CompletionCallBack(CallBack->CompletionRef,
		    PendingIntr);
	}

	return;
}

/*****************************************************************************/
/**
 * Set call back function and call back reference pointer for one channel
 *
 * @param InstancePtr is the pointer to the DMA engine to work on
 * @param HandlerType is the interrupt type that this callback handles
 * @param CallBackFunc is the call back function pointer
 * @param CallBackRef is the call back reference pointer
 * @param Direction is the DMA channel, use XAXIVDMA_READ or XAXIVDMA_WRITE
 *
 * @return
 * - XST_SUCCESS if everything is fine
 * - XST_INVALID_PARAM if the handler type or direction invalid
 *
 * @note
 * This function overwrites the existing interrupt handler and its reference
 * pointer. The function sets the handlers even if the channels are invalid.
 *****************************************************************************/
int XAxiVdma_SetCallBack(XAxiVdma * InstancePtr, u32 HandlerType,
        void *CallBackFunc, void *CallBackRef, u16 Direction)
{
	XAxiVdma_ChannelCallBack *CallBack;

	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XAXIVDMA_DEVICE_READY);

	if ((HandlerType != XAXIVDMA_HANDLER_GENERAL) &&
	    (HandlerType != XAXIVDMA_HANDLER_ERROR)) {

		return XST_INVALID_PARAM;
	}

	if (Direction == XAXIVDMA_READ) {
		CallBack = &(InstancePtr->ReadCallBack);
	}
	else {
		CallBack = &(InstancePtr->WriteCallBack);
	}

	switch (HandlerType) {
	case XAXIVDMA_HANDLER_GENERAL:
		CallBack->CompletionCallBack = CallBackFunc;
		CallBack->CompletionRef = CallBackRef;
		break;

	case XAXIVDMA_HANDLER_ERROR:
		CallBack->ErrCallBack = CallBackFunc;
		CallBack->ErrRef = CallBackRef;
		break;

	default:
		return XST_INVALID_PARAM;
	}

	return XST_SUCCESS;
}
/** @} */
