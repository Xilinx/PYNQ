/******************************************************************************
*
* Copyright (C) 2008 - 2014 Xilinx, Inc.  All rights reserved.
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
* @file xvtc_intr.c
* @addtogroup vtc_v7_2
* @{
*
* This file contains interrupt related functions of Xilinx VTC core.
* Please see xvtc.h for more details of the core.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who    Date     Changes
* ----- ------ -------- -----------------------------------------------
* 1.00a xd     08/05/08 First release
* 1.01a xd     07/23/10 Added GIER. Added more h/w generic info into
*                       xparameters.h. Feed callbacks with pending
*                       interrupt info. Added Doxygen & Version support.
* 3.00a cjm    08/01/12 Converted from xio.h to xil_io.h, translating
*                       basic types, MB cache functions, exceptions and
*                       assertions to xil_io format.
*                       Replaced the following:
*                       "XExc_Init" -> "Xil_ExceptionInit"
*                       "XExc_RegisterHandler" -> "Xil_Exception
*                                                 RegisterHandler"
*                       "XEXC_ID_NON_CRITICAL_INT" -> "XIL_EXCEPTION_ID_INT"
*                       "XExceptionHandler" -> "Xil_ExceptionHandler"
*                       "XExc_mEnableExceptions" -> "Xil_ExceptionEnable"
*                       "XEXC_NON_CRITICAL" -> "XIL_EXCEPTION_NON_CRITICAL"
*                       "XExc_DisableExceptions" -> "Xil_ExceptionDisable"
*                       "XExc_RemoveHandler" -> "Xil_ExceptionRemoveHandler"
*                       "microblaze_enable_interrupts" -> "Xil_Exception
*                                                         Enable"
*                       "microblaze_disable_interrupts" -> "Xil_Exception
*                                                           Disable"
*                       "XCOMPONENT_IS_STARTED" -> "XIL_COMPONENT_IS_STARTED"
*                       "XCOMPONENT_IS_READY" -> "XIL_COMPONENT_IS_READY"
*                       "XASSERT_NONVOID" -> "Xil_AssertNonvoid"
*                       "XASSERT_VOID_ALWAYS" -> "Xil_AssertVoidAlways"
*                       "XASSERT_VOID" -> "Xil_AssertVoid"
*                       "Xil_AssertVoid_ALWAYS" -> "Xil_AssertVoidAlways"
*                       "XAssertStatus" -> "Xil_AssertStatus"
*                       "XAssertSetCallback" -> "Xil_AssertCallback"
*
*                       "XASSERT_OCCURRED" -> "XIL_ASSERT_OCCURRED"
*                       "XASSERT_NONE" -> "XIL_ASSERT_NONE"
*
*                       "microblaze_disable_dcache" -> "Xil_DCacheDisable"
*                       "microblaze_enable_dcache" -> "Xil_DCacheEnable"
*                       "microblaze_enable_icache" -> "Xil_ICacheEnable"
*                       "microblaze_disable_icache" -> "Xil_ICacheDisable"
*                       "microblaze_init_dcache_range" -> "Xil_DCache
*                                                        InvalidateRange"
*
*                       "XCache_DisableDCache" -> "Xil_DCacheDisable"
*                       "XCache_DisableICache" -> "Xil_ICacheDisable"
*                       "XCache_EnableDCache" -> "Xil_DCacheEnableRegion"
*                       "XCache_EnableICache" -> "Xil_ICacheEnableRegion"
*                       "XCache_InvalidateDCacheLine" -> "Xil_DCache
*                                                             InvalidateRange"
*
*                       "XUtil_MemoryTest32" -> "Xil_TestMem32"
*                       "XUtil_MemoryTest16" -> "Xil_TestMem16"
*                       "XUtil_MemoryTest8" -> "Xil_TestMem8"
*
*                       "xutil.h" -> "xil_testmem.h"
*
*                       "xbasic_types.h" -> "xil_types.h"
*                       "xio.h" -> "xil_io.h"
*
*                       "XIo_In32" -> "Xil_In32"
*                       "XIo_Out32" -> "Xil_Out32"
*
*                       "XTRUE" -> "TRUE"
*                       "XFALSE" -> "FALSE"
*                       "XNULL" -> "NULL"
*
*                       "Xuint8" -> "u8"
*                       "Xuint16" -> "u16"
*                       "Xuint32" -> "u32"
*                       "Xint8" -> "char"
*                       "Xint16" -> "short"
*                       "Xint32" -> "long"
*                       "Xfloat32" -> "float"
*                       "Xfloat64" -> "double"
*                       "Xboolean" -> "int"
*                       "XTEST_FAILED" -> "XST_FAILURE"
*                       "XTEST_PASSED" -> "XST_SUCCESS"
* 6.1   adk    08/23/14 Alligned doxygen tags.
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xvtc.h"

/************************** Constant Definitions *****************************/


/***************** Macros (Inline Functions) Definitions *********************/


/**************************** Type Definitions *******************************/


/************************** Function Prototypes ******************************/


/************************** Variable Definitions *****************************/


/************************** Function Definitions *****************************/

/*****************************************************************************/
/**
*
* This function is the interrupt handler for the VTC core.
*
* This handler reads the pending interrupt from the IER/ISR, determines the
* source of the interrupts, calls according callbacks and finally clears the
* interrupts.
*
* The application is responsible for connecting this function to the interrupt
* system. Application beyond this driver is also responsible for providing
* callbacks to handle interrupts and installing the callbacks using
* XVtc_SetCallBack() during initialization phase.
*
* @param	InstancePtr is a pointer to the XVtc instance that just
*		interrupted.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_IntrHandler(void *InstancePtr)
{
	u32 PendingIntr;
	u32 ErrorStatus;
	XVtc *XVtcPtr = (XVtc *) InstancePtr;

	/* Verify arguments. */
	Xil_AssertVoid(XVtcPtr != NULL);
	Xil_AssertVoid(XVtcPtr->IsReady == XIL_COMPONENT_IS_READY);

	/* Get pending interrupts */
	PendingIntr = XVtc_IntrGetPending(XVtcPtr);

	/* Clear pending interrupt(s) */
	XVtc_IntrClear(XVtcPtr, PendingIntr);

	/* Spurious interrupt has happened */
	if (0 == (PendingIntr | XVTC_IXR_ALLINTR_MASK)) {
		ErrorStatus = 0;
		XVtcPtr->ErrCallBack(XVtcPtr->ErrRef, ErrorStatus);
		return;
	}

	/* A generator event has happened */
	if ((PendingIntr & XVTC_IXR_G_ALL_MASK))
		XVtcPtr->GeneratorCallBack(XVtcPtr->GeneratorRef,
		PendingIntr);

	/* A detector event has happened */
	if ((PendingIntr & XVTC_IXR_D_ALL_MASK))
		XVtcPtr->DetectorCallBack(XVtcPtr->DetectorRef,
		PendingIntr);

	/* A frame sync is done */
	if ((PendingIntr & XVTC_IXR_FSYNCALL_MASK))
		XVtcPtr->FrameSyncCallBack(XVtcPtr->FrameSyncRef,
		PendingIntr);

	/* A signal lock is detected */
	if ((PendingIntr & XVTC_IXR_LOCKALL_MASK))
		XVtcPtr->LockCallBack(XVtcPtr->LockRef,
		PendingIntr);
}


/*****************************************************************************/
/**
*
* This routine installs an asynchronous callback function for the given
* HandlerType:
*
* <pre>
* HandlerType              Callback Function Type
* -----------------------  --------------------------------------------------
* XVTC_HANDLER_FRAMESYNC   XVtc_FrameSyncCallBack
* XVTC_HANDLER_LOCK        XVtc_LockCallBack
* XVTC_HANDLER_DETECTOR    XVtc_DetectorCallBack
* XVTC_HANDLER_GENERATOR   XVtc_GeneratorCallBack
* XVTC_HANDLER_ERROR       XVtc_ErrCallBack
*
* HandlerType              Invoked by this driver when:
* -----------------------  --------------------------------------------------
* XVTC_HANDLER_FRAMESYNC   A frame sync event happens
* XVTC_HANDLER_LOCK        A signal lock event happens
* XVTC_HANDLER_DETECTOR    A detector related event happens
* XVTC_HANDLER_GENERATOR   A generator related event happens
* XVTC_HANDLER_ERROR       An error condition happens
* </pre>
*
* @param	InstancePtr is a pointer to the XVtc instance to be worked
*		on.
* @param	HandlerType specifies which callback is to be attached.
* @param	CallBackFunc is the address of the callback function.
* @param	CallBackRef is a user data item that will be passed to the
*		callback function when it is invoked.
*
* @return
*		- XST_SUCCESS when handler is installed.
*		- XST_INVALID_PARAM when HandlerType is invalid.
*
* @note		Invoking this function for a handler that already has been
*		installed replaces it with the new handler.
*
******************************************************************************/
int XVtc_SetCallBack(XVtc *InstancePtr, u32 HandlerType,
				void *CallBackFunc, void *CallBackRef)
{

	/* Verify arguments. */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/* For specific handler type assigning callback function reference */
	switch (HandlerType) {
	case XVTC_HANDLER_FRAMESYNC:
		InstancePtr->FrameSyncCallBack =
				(XVtc_CallBack) CallBackFunc;
		InstancePtr->FrameSyncRef = CallBackRef;
		break;

	case XVTC_HANDLER_LOCK:
		InstancePtr->LockCallBack = (XVtc_CallBack) CallBackFunc;
		InstancePtr->LockRef = CallBackRef;
		break;

	case XVTC_HANDLER_DETECTOR:
		InstancePtr->DetectorCallBack =
				(XVtc_CallBack) CallBackFunc;
		InstancePtr->DetectorRef = CallBackRef;
		break;

	case XVTC_HANDLER_GENERATOR:
		InstancePtr->GeneratorCallBack =
				(XVtc_CallBack) CallBackFunc;
		InstancePtr->GeneratorRef = CallBackRef;
		break;

	case XVTC_HANDLER_ERROR:
		InstancePtr->ErrCallBack =
				(XVtc_ErrorCallBack) CallBackFunc;
		InstancePtr->ErrRef = CallBackRef;
		break;

	default:
		return XST_INVALID_PARAM;

	}
	return XST_SUCCESS;
}
/** @} */
