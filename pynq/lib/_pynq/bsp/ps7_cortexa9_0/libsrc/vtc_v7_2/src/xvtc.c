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
* @file xvtc.c
* @addtogroup vtc_v7_2
* @{
*
* This is main code of Xilinx MVI Video Timing Controller (VTC) device driver.
* The VTC device detects and generates video sync signals to Video IP cores
* like MVI Video Scaler. Please see xvtc.h for more details of the driver.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who    Date     Changes
* ----- ------ -------- --------------------------------------------------
* 1.00a xd     08/05/08 First release.
* 1.01a xd     07/23/10 Added GIER; Added more h/w generic info into
*                       xparameters.h; Feed callbacks with pending
*                       interrupt info. Added Doxygen & Version support.
* 3.00a cjm    08/01/12 Converted from xio.h to xil_io.h, translating
*                       basic types, MB cache functions, exceptions and
*                       assertions to xil_io format.
*                       Replaced the following:
*                       "XExc_Init" -> "Xil_ExceptionInit"
*                       "XExc_RegisterHandler" ->
*                       "Xil_ExceptionRegisterHandler"
*                       "XEXC_ID_NON_CRITICAL_INT" -> "XIL_EXCEPTION_ID_INT"
*                       "XExceptionHandler" -> "Xil_ExceptionHandler"
*                       "XExc_mEnableExceptions" -> "Xil_ExceptionEnable"
*                       "XEXC_NON_CRITICAL" -> "XIL_EXCEPTION_NON_CRITICAL"
*                       "XExc_DisableExceptions" -> "Xil_ExceptionDisable"
*                       "XExc_RemoveHandler" -> "Xil_ExceptionRemoveHandler"
*                       "microblaze_enable_interrupts" -> "Xil_ExceptionEnable"
*                       "microblaze_disable_interrupts" ->
*                       Xil_ExceptionDisable"
*                       "XCOMPONENT_IS_STARTED" -> "XIL_COMPONENT_IS_STARTED"
*                       "XCOMPONENT_IS_READY" -> "(XIL_COMPONENT_IS_READY)"
*
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
*                       "microblaze_init_dcache_range" ->
*                       "Xil_DCacheInvalidateRange"
*                       "XCache_DisableDCache" -> "Xil_DCacheDisable"
*                       "XCache_DisableICache" -> "Xil_ICacheDisable"
*                       "XCache_EnableDCache" -> "Xil_DCacheEnableRegion"
*                       "XCache_EnableICache" -> "Xil_ICacheEnableRegion"
*                       "XCache_InvalidateDCacheLine" ->
*                       "Xil_DCacheInvalidateRange"
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
* 4.00a cjm    02/08/13 Removed XVTC_CTL_HASS_MASK
* 5.00a cjm    08/07/13 Replaced CTL in Polarity and Encoding register
*                       definition with "POL" and "ENC"
* 5.00a cjm    10/30/13 Removed type parameter from XVtc_Enable which now
*                       enables both generator and detector.
*                       Added XVtc_EnableGenerator to enable only the Generator
*                       Added XVtc_EnableDetector to enable only the Detector
* 5.00a cjm    11/01/13 Added Timing, VideoMode and Signal Conversion Functions
*                       XVtc_ConvVideoMode2Timing
*                       XVtc_ConvTiming2Signal
*                       XVtc_ConvSignal2Timing
*                       XVtc_ConvTiming2VideoMode
*                       Added Timing and Video Mode Set/Get Functions
*                       XVtc_SetGeneratorTiming
*                       XVtc_SetGeneratorVideoMode
*                       XVtc_GetGeneratorTiming
*                       XVtc_GetGeneratorVideoMode
*                       XVtc_GetDetectorTiming
*                       XVtc_GetDetectorVideoMode
*                       Updated XVtc_GetGeneratorHoriOffset and
*                       XVtc_SetGeneratorHoriOffset. For adding interlaced or
*                       field-1 registers setting/getting updated
*                       XVtc_SetGenerator to align vsync to hsync
*                       horizontally by default.
*                       Added Field 1 set/get to XVtc_SetGenerator,
*                       XVtc_GetGenerator and XVtc_GetDetector.
* 5.00a cjm    11/03/13 Added Chroma/field parity bit masks.
*                       Replaced old timing bit masks/shifts with Start/End Bit
*                       masks/shifts.
* 6.1   adk    08/23/14 Modified HActiveVideo value to 1920 for
*                       XVTC_VMODE_1080I mode.
*                       Removed Major, Minor and Revision parameters from
*                       XVtc_GetVersion.
*                       Modified return type of XVtc_GetVersion from
*                       void to u32.
* 7.0   vns    25/02/15 Added progressive and interlaced mode switching feature.
*                       Modified XVtc_SetGenerator, XVtc_GetGenerator,
*                       XVtc_GetDetector, XVtc_ConvTiming2Signal and
*                       XVtc_ConvSignal2Timing APIs
* 7.1   vns    07/10/15 Corrected V0SyncStart and V1SyncStart values
*                       in APIs XVtc_ConvTiming2Signal and
*                       XVtc_ConvSignal2Timing
*                       Corrected register read to XVTC_DVSYNC_F1_OFFSET
*                       in API XVtc_GetDetector
*       vns    10/14/15 Modified XVtc_SetSource API to provided programming
*                       interlaced mode feature and modified XVtc_GetSource
*                       API to read interlaced mode status.
*                       Corrected XVtc_ConvSignal2Timing API to get interlaced
*                       mode from SignalCfgPtr structure.
* 7.2   mh     04/20/16 Removed call to XVtc_Reset from XVtc_CfgInitialize.
*       sk     08/16/16 Used UINTPTR instead of u32 for Baseaddress as part of
*                       adding 64 bit support. CR# 867425.
*                       Changed the prototype of XVtc_CfgInitialize API.
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xvtc.h"
#include "xenv.h"

/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/

/*
* Each of callback functions to be called on different types of interrupts.
* These stub functions are set during XVtc_CfgInitialize as default
* callback functions. If application is not registered any of the callback
* function, these functions will be called for doing nothing.
*/
static void StubCallBack(void *CallBackRef);
static void StubErrCallBack(void *CallBackRef, u32 ErrorMask);

/************************** Variable Definitions *****************************/


/************************** Function Definitions *****************************/

/*****************************************************************************/
/**
*
* This function initializes the VTC core. This function must be called
* prior to using the VTC core. Initialization of the VTC includes setting up
* the instance data, and ensuring the hardware is in a quiescent state.
*
* @param	InstancePtr is a pointer to the VTC core instance to be
*		worked on.
* @param	CfgPtr points to the configuration structure associated with
*		the VTC core.
* @param	EffectiveAddr is the base address of the device. If address
*		translation is being used, then this parameter must reflect the
*		virtual base address. Otherwise, the physical address should be
*		used.
*
* @return
*		- XST_SUCCESS if XVtc_CfgInitialize was successful.
*
* @note		None.
*
******************************************************************************/
int XVtc_CfgInitialize(XVtc *InstancePtr, XVtc_Config *CfgPtr,
				UINTPTR EffectiveAddr)
{
	/* Verify arguments */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(CfgPtr != NULL);
	Xil_AssertNonvoid((u32 *)EffectiveAddr != NULL);

	/* Setup the instance */
	memset((void *)InstancePtr, 0, sizeof(XVtc));

	memcpy((void *)&(InstancePtr->Config), (const void *)CfgPtr,
			   sizeof(XVtc_Config));
	InstancePtr->Config.BaseAddress = EffectiveAddr;

	/* Set all handlers to stub values, let user configure this data later */
	InstancePtr->FrameSyncCallBack = (XVtc_CallBack) StubCallBack;
	InstancePtr->LockCallBack = (XVtc_CallBack) StubCallBack;
	InstancePtr->DetectorCallBack = (XVtc_CallBack) StubCallBack;
	InstancePtr->GeneratorCallBack = (XVtc_CallBack) StubCallBack;
	InstancePtr->ErrCallBack = (XVtc_ErrorCallBack) StubErrCallBack;

	/* Set the flag to indicate the driver is ready */
	InstancePtr->IsReady = (u32)(XIL_COMPONENT_IS_READY);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function enables the VTC Generator core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_EnableGenerator(XVtc *InstancePtr)
{
	u32 CtrlRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/* Read Control register value back */
	CtrlRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
					(XVTC_CTL_OFFSET));

	/* Change the value according to the enabling type and write it back */
	CtrlRegValue |= XVTC_CTL_GE_MASK;

	XVtc_WriteReg(InstancePtr->Config.BaseAddress, (XVTC_CTL_OFFSET),
			CtrlRegValue);
}

/*****************************************************************************/
/**
*
* This function enables the VTC Detector core
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_EnableDetector(XVtc *InstancePtr)
{
	u32 CtrlRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/* Read Control register value back */
	CtrlRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
					(XVTC_CTL_OFFSET));

	/* Change the value according to the enabling type and write it back */
	CtrlRegValue |= XVTC_CTL_DE_MASK;

	XVtc_WriteReg(InstancePtr->Config.BaseAddress, (XVTC_CTL_OFFSET),
			CtrlRegValue);
}

/*****************************************************************************/
/**
*
* This function enables the Detector and Generator at same time of the
* VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_Enable(XVtc *InstancePtr)
{
	u32 CtrlRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/* Read Control register value back */
	CtrlRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
					(XVTC_CTL_OFFSET));

	/* Setup the SW Enable Bit and write it back */
	CtrlRegValue |= XVTC_CTL_SW_MASK;

	XVtc_WriteReg(InstancePtr->Config.BaseAddress, (XVTC_CTL_OFFSET),
				CtrlRegValue);
}

/*****************************************************************************/
/**
*
* This function disables the VTC Generator core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_DisableGenerator(XVtc *InstancePtr)
{
	u32 CtrlRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/* Read Control register value back */
	CtrlRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
					(XVTC_CTL_OFFSET));

	/* Change the value according to the disabling type and write it
	 * back
	 */
	CtrlRegValue &= (u32)(~(XVTC_CTL_GE_MASK));

	XVtc_WriteReg(InstancePtr->Config.BaseAddress, (XVTC_CTL_OFFSET),
			CtrlRegValue);
}

/*****************************************************************************/
/**
*
* This function disables the VTC Detector core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_DisableDetector(XVtc *InstancePtr)
{
	u32 CtrlRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/* Read Control register value back */
	CtrlRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
					(XVTC_CTL_OFFSET));

	/* Change the value according to the disabling type and write it
	 * back
	 */
	CtrlRegValue &= (u32)(~(XVTC_CTL_DE_MASK));

	XVtc_WriteReg(InstancePtr->Config.BaseAddress, (XVTC_CTL_OFFSET),
			CtrlRegValue);
}

/*****************************************************************************/
/**
*
* This function disables the Detector and Generator at same time of the VTC
* core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_Disable(XVtc *InstancePtr)
{
	u32 CtrlRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/* Read Control register value back */
	CtrlRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
					(XVTC_CTL_OFFSET));

	/* Change the value, clearing Core Enable, and write it back*/
	CtrlRegValue &= ~XVTC_CTL_SW_MASK;

	XVtc_WriteReg(InstancePtr->Config.BaseAddress, (XVTC_CTL_OFFSET),
			CtrlRegValue);
}

/*****************************************************************************/
/**
*
* This function sets up the output polarity of the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	PolarityPtr points to a Polarity configuration structure with
*		the setting to use on the VTC core.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XVtc_SetPolarity(XVtc *InstancePtr, XVtc_Polarity *PolarityPtr)
{
	u32 PolRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(PolarityPtr != NULL);

	/* Read Control register value back and clear all polarity
	 * bits first
	 */
	PolRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
					(XVTC_GPOL_OFFSET));
	PolRegValue &= (u32)(~(XVTC_POL_ALLP_MASK));

	/* Change the register value according to the setting in the Polarity
	 * configuration structure
	 */
	if (PolarityPtr->ActiveChromaPol)
		PolRegValue |= XVTC_POL_ACP_MASK;

	if (PolarityPtr->ActiveVideoPol)
		PolRegValue |= XVTC_POL_AVP_MASK;

	if (PolarityPtr->FieldIdPol)
		PolRegValue |= XVTC_POL_FIP_MASK;

	if (PolarityPtr->VBlankPol)
		PolRegValue |= XVTC_POL_VBP_MASK;

	if (PolarityPtr->VSyncPol)
		PolRegValue |= XVTC_POL_VSP_MASK;

	if (PolarityPtr->HBlankPol)
		PolRegValue |= XVTC_POL_HBP_MASK;

	if (PolarityPtr->HSyncPol)
		PolRegValue |= XVTC_POL_HSP_MASK;

	XVtc_WriteReg(InstancePtr->Config.BaseAddress, (XVTC_GPOL_OFFSET),
			PolRegValue);
}

/*****************************************************************************/
/**
*
* This function gets the output polarity setting used by the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	PolarityPtr points to a Polarity configuration structure that
*		will be populated with the setting used on the VTC core
*		after this function returns.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_GetPolarity(XVtc *InstancePtr, XVtc_Polarity *PolarityPtr)
{
	u32 PolRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(PolarityPtr != NULL);

	/* Clear the Polarity configuration structure */
	memset((void *)PolarityPtr, 0, sizeof(XVtc_Polarity));

	/* Read Control register value back */
	PolRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
					(XVTC_GPOL_OFFSET));

	/* Populate the Polarity configuration structure w/ the current setting
	 * used in the device
	 */
	if (PolRegValue & XVTC_POL_ACP_MASK)
		PolarityPtr->ActiveChromaPol = 1;

	if (PolRegValue & XVTC_POL_AVP_MASK)
		PolarityPtr->ActiveVideoPol = 1;

	if (PolRegValue & XVTC_POL_FIP_MASK)
		PolarityPtr->FieldIdPol = 1;

	if (PolRegValue & XVTC_POL_VBP_MASK)
		PolarityPtr->VBlankPol = 1;

	if (PolRegValue & XVTC_POL_VSP_MASK)
		PolarityPtr->VSyncPol = 1;

	if (PolRegValue & XVTC_POL_HBP_MASK)
		PolarityPtr->HBlankPol = 1;

	if (PolRegValue & XVTC_POL_HSP_MASK)
		PolarityPtr->HSyncPol = 1;
}

/*****************************************************************************/
/**
*
* This function gets the input polarity setting used by the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	PolarityPtr points to a Polarity configuration structure that
*		will be populated with the setting used on the VTC core after
*		this function returns.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_GetDetectorPolarity(XVtc *InstancePtr, XVtc_Polarity *PolarityPtr)
{
	u32 PolRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(PolarityPtr != NULL);

	/* Clear the Polarity configuration structure */
	memset((void *)PolarityPtr, 0, sizeof(XVtc_Polarity));

	/* Read Control register value back */
	PolRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
					(XVTC_DPOL_OFFSET));

	/* Populate the Polarity configuration structure w/ the current setting
	 * used in the core.
	 */
	if (PolRegValue & XVTC_POL_ACP_MASK)
		PolarityPtr->ActiveChromaPol = 1;

	if (PolRegValue & XVTC_POL_AVP_MASK)
		PolarityPtr->ActiveVideoPol = 1;

	if (PolRegValue & XVTC_POL_FIP_MASK)
		PolarityPtr->FieldIdPol = 1;

	if (PolRegValue & XVTC_POL_VBP_MASK)
		PolarityPtr->VBlankPol = 1;

	if (PolRegValue & XVTC_POL_VSP_MASK)
		PolarityPtr->VSyncPol = 1;

	if (PolRegValue & XVTC_POL_HBP_MASK)
		PolarityPtr->HBlankPol = 1;

	if (PolRegValue & XVTC_POL_HSP_MASK)
		PolarityPtr->HSyncPol = 1;
}

/*****************************************************************************/
/**
*
* This function sets up the source selecting of the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on
* @param 	SourcePtr points to a Source Selecting configuration structure
*		with the setting to use on the VTC device.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_SetSource(XVtc *InstancePtr, XVtc_SourceSelect *SourcePtr)
{
	u32 CtrlRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(SourcePtr != NULL);

	/* Read Control register value back and clear all source selection bits
	 * first
	 */
	CtrlRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
					(XVTC_CTL_OFFSET));
	CtrlRegValue &= ~XVTC_CTL_ALLSS_MASK;

	/* Change the register value according to the setting in the source
	 * selection configuration structure
	 */

	if (SourcePtr->FieldIdPolSrc)
		CtrlRegValue |= XVTC_CTL_FIPSS_MASK;

	if (SourcePtr->ActiveChromaPolSrc)
		CtrlRegValue |= XVTC_CTL_ACPSS_MASK;

	if (SourcePtr->ActiveVideoPolSrc)
		CtrlRegValue |= XVTC_CTL_AVPSS_MASK;

	if (SourcePtr->HSyncPolSrc)
		CtrlRegValue |= XVTC_CTL_HSPSS_MASK;

	if (SourcePtr->VSyncPolSrc)
		CtrlRegValue |= XVTC_CTL_VSPSS_MASK;

	if (SourcePtr->HBlankPolSrc)
		CtrlRegValue |= XVTC_CTL_HBPSS_MASK;

	if (SourcePtr->VBlankPolSrc)
		CtrlRegValue |= XVTC_CTL_VBPSS_MASK;


	if (SourcePtr->VChromaSrc)
		CtrlRegValue |= XVTC_CTL_VCSS_MASK;

	if (SourcePtr->VActiveSrc)
		CtrlRegValue |= XVTC_CTL_VASS_MASK;

	if (SourcePtr->VBackPorchSrc)
		CtrlRegValue |= XVTC_CTL_VBSS_MASK;

	if (SourcePtr->VSyncSrc)
		CtrlRegValue |= XVTC_CTL_VSSS_MASK;

	if (SourcePtr->VFrontPorchSrc)
		CtrlRegValue |= XVTC_CTL_VFSS_MASK;

	if (SourcePtr->VTotalSrc)
		CtrlRegValue |= XVTC_CTL_VTSS_MASK;

	if (SourcePtr->HBackPorchSrc)
		CtrlRegValue |= XVTC_CTL_HBSS_MASK;

	if (SourcePtr->HSyncSrc)
		CtrlRegValue |= XVTC_CTL_HSSS_MASK;

	if (SourcePtr->HFrontPorchSrc)
		CtrlRegValue |= XVTC_CTL_HFSS_MASK;

	if (SourcePtr->HTotalSrc)
		CtrlRegValue |= XVTC_CTL_HTSS_MASK;

	if (SourcePtr->InterlacedMode)
		CtrlRegValue |= XVTC_CTL_INTERLACE_MASK;

	XVtc_WriteReg(InstancePtr->Config.BaseAddress, (XVTC_CTL_OFFSET),
			CtrlRegValue);
}

/*****************************************************************************/
/**
*
* This function gets the source select setting used by the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param 	SourcePtr points to a source select configuration structure
*		that will be populated with the setting used on the VTC core
*		after this function returns.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XVtc_GetSource(XVtc *InstancePtr, XVtc_SourceSelect *SourcePtr)
{
	u32 CtrlRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(SourcePtr != NULL);

	/* Clear the source selection configuration structure */
	memset((void *)SourcePtr, 0, sizeof(XVtc_SourceSelect));

	/* Read Control register value back */
	CtrlRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
					(XVTC_CTL_OFFSET));

	/* Populate the source select configuration structure with the current
	 * setting used in the core
	 */
	if (CtrlRegValue & XVTC_CTL_FIPSS_MASK)
		SourcePtr->FieldIdPolSrc = 1;
	if (CtrlRegValue & XVTC_CTL_ACPSS_MASK)
		SourcePtr->ActiveChromaPolSrc = 1;
	if (CtrlRegValue & XVTC_CTL_AVPSS_MASK)
		SourcePtr->ActiveVideoPolSrc= 1;
	if (CtrlRegValue & XVTC_CTL_HSPSS_MASK)
		SourcePtr->HSyncPolSrc = 1;
	if (CtrlRegValue & XVTC_CTL_VSPSS_MASK)
		SourcePtr->VSyncPolSrc = 1;
	if (CtrlRegValue & XVTC_CTL_HBPSS_MASK)
		SourcePtr->HBlankPolSrc = 1;
	if (CtrlRegValue & XVTC_CTL_VBPSS_MASK)
		SourcePtr->VBlankPolSrc = 1;

	if (CtrlRegValue & XVTC_CTL_VCSS_MASK)
		SourcePtr->VChromaSrc = 1;
	if (CtrlRegValue & XVTC_CTL_VASS_MASK)
		SourcePtr->VActiveSrc = 1;
	if (CtrlRegValue & XVTC_CTL_VBSS_MASK)
		SourcePtr->VBackPorchSrc = 1;
	if (CtrlRegValue & XVTC_CTL_VSSS_MASK)
		SourcePtr->VSyncSrc = 1;
	if (CtrlRegValue & XVTC_CTL_VFSS_MASK)
		SourcePtr->VFrontPorchSrc = 1;
	if (CtrlRegValue & XVTC_CTL_VTSS_MASK)
		SourcePtr->VTotalSrc = 1;
	if (CtrlRegValue & XVTC_CTL_HBSS_MASK)
		SourcePtr->HBackPorchSrc = 1;
	if (CtrlRegValue & XVTC_CTL_HSSS_MASK)
		SourcePtr->HSyncSrc = 1;
	if (CtrlRegValue & XVTC_CTL_HFSS_MASK)
		SourcePtr->HFrontPorchSrc = 1;
	if (CtrlRegValue & XVTC_CTL_HTSS_MASK)
		SourcePtr->HTotalSrc = 1;
	if (CtrlRegValue & XVTC_CTL_INTERLACE_MASK)
		SourcePtr->InterlacedMode = 1;
}

/*****************************************************************************/
/**
*
* This function sets up the line skip setting of the Generator in the VTC
* core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param 	GeneratorChromaSkip indicates whether to skip 1 line between
*		active chroma for the Generator module. Use Non-0 value for
*		this parameter to skip 1 line, and 0 to not skip lines.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_SetSkipLine(XVtc *InstancePtr, int GeneratorChromaSkip)
{
	u32 FrameEncodeRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/* Read Control register value back and clear all skip bits first */
	FrameEncodeRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
						(XVTC_GFENC_OFFSET));
	FrameEncodeRegValue &= (u32)(~(XVTC_ENC_GACLS_MASK));

	/* Change the register value according to the skip setting passed
	 * into this function.
	 */
	if (GeneratorChromaSkip)
		FrameEncodeRegValue |= XVTC_ENC_GACLS_MASK;

	XVtc_WriteReg(InstancePtr->Config.BaseAddress, (XVTC_GFENC_OFFSET),
			FrameEncodeRegValue);
}

/*****************************************************************************/
/**
*
* This function gets the line skip setting used by the Generator in the VTC
* core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	GeneratorChromaSkipPtr will point to the value indicating
*		whether one line is skipped between active chroma for the
*		Generator module after this function returns. Value 1 means
*		that 1 line is skipped and zero means that no lines are
*		skipped.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_GetSkipLine(XVtc *InstancePtr, int *GeneratorChromaSkipPtr)
{
	u32 FrameEncodeRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(GeneratorChromaSkipPtr != NULL);

	/* Read Control register value back */
	FrameEncodeRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
						(XVTC_GFENC_OFFSET));

	/* Populate the skip variable values according to the skip setting
	 * used by the core.
	 */
	if (FrameEncodeRegValue & XVTC_ENC_GACLS_MASK)
		*GeneratorChromaSkipPtr = 1;
	else
		*GeneratorChromaSkipPtr = 0;
}

/*****************************************************************************/
/**
*
* This function sets up the pixel skip setting of the Generator in the VTC
* core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	GeneratorChromaSkip indicates whether to skip 1 pixel between
*		active chroma for the Generator module. Use Non-0 value for
*		this parameter to skip 1 pixel, and 0 to not skip pixels
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_SetSkipPixel(XVtc *InstancePtr, int GeneratorChromaSkip)
{
	u32 FrameEncodeRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == (u32)(XIL_COMPONENT_IS_READY));

	/* Read Control register value back and clear all skip bits first */
	FrameEncodeRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
						(XVTC_GFENC_OFFSET));
	FrameEncodeRegValue &= (u32)(~(XVTC_ENC_GACPS_MASK));

	/* Change the register value according to the skip setting passed
	 * into this function.
	 */
	if (GeneratorChromaSkip)
		FrameEncodeRegValue |= XVTC_ENC_GACPS_MASK;

	XVtc_WriteReg(InstancePtr->Config.BaseAddress, (XVTC_GFENC_OFFSET),
				FrameEncodeRegValue);
}

/*****************************************************************************/
/**
*
* This function gets the pixel skip setting used by the Generator in the VTC
* core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	GeneratorChromaSkipPtr will point to the value indicating
*		whether one pixel is skipped between active chroma for the
*		Generator module after this function returns. Value 1 means
*		that 1 pixel is skipped and zero means that no pixels are
*		skipped.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_GetSkipPixel(XVtc *InstancePtr, int *GeneratorChromaSkipPtr)
{
	u32 FrameEncodeRegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(GeneratorChromaSkipPtr != NULL);

	/* Read Control register value back */
	FrameEncodeRegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
						(XVTC_GFENC_OFFSET));

	/* Populate the skip variable values according to the skip setting
	 * used by the core.
	 */
	if (FrameEncodeRegValue & XVTC_ENC_GACPS_MASK)
		*GeneratorChromaSkipPtr = 1;
	else
		*GeneratorChromaSkipPtr = 0;
}

/*****************************************************************************/
/**
*
* This function sets up the Generator delay setting of the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param 	VertDelay indicates the number of total lines per frame to
*		delay the generator output. The valid range is from 0 to 4095.
* @param	HoriDelay indicates the number of total clock cycles per line
*		to delay the generator output. The valid range is from 0 to
*		4095.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_SetDelay(XVtc *InstancePtr, int VertDelay, int HoriDelay)
{
	u32 RegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(VertDelay >= 0);
	Xil_AssertVoid(HoriDelay >= 0);
	Xil_AssertVoid(VertDelay <= 4095);
	Xil_AssertVoid(HoriDelay <= 4095);

	/* Calculate the delay value */
	RegValue = HoriDelay & XVTC_GGD_HDELAY_MASK;
	RegValue |= (VertDelay << XVTC_GGD_VDELAY_SHIFT) &
			XVTC_GGD_VDELAY_MASK;

	/* Update the Generator Global Delay register w/ the value */
	XVtc_WriteReg(InstancePtr->Config.BaseAddress, (XVTC_GGD_OFFSET),
			RegValue);
}

/*****************************************************************************/
/**
*
* This function gets the Generator delay setting used by the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	VertDelayPtr will point to a value indicating the number of
*		total lines per frame to delay the generator output after
*		this function returns.
* @param	HoriDelayPtr will point to a value indicating the number of
*		total clock cycles per line to delay the generator output
*		after this function returns.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_GetDelay(XVtc *InstancePtr, int *VertDelayPtr, int *HoriDelayPtr)
{
	u32 RegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(VertDelayPtr != NULL);
	Xil_AssertVoid(HoriDelayPtr != NULL);

	/* Read the Generator Global Delay register value */
	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
				(XVTC_GGD_OFFSET));

	/* Calculate the delay values */
	*HoriDelayPtr = RegValue & XVTC_GGD_HDELAY_MASK;
	*VertDelayPtr = (RegValue & XVTC_GGD_VDELAY_MASK) >>
				XVTC_GGD_VDELAY_SHIFT;
}

/*****************************************************************************/
/**
*
* This function sets up the SYNC setting of a frame sync used by the VTC
* core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	FrameSyncIndex indicates the index number of the frame sync.
*		The valid range is from 0 to 15.
* @param	VertStart indicates the vertical line count during which the
*		frame sync is active. The valid range is from 0 to 4095.
* @param	HoriStart indicates the horizontal cycle count during which the
*		frame sync is active. The valid range is from 0 to 4095.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_SetFSync(XVtc *InstancePtr, u16 FrameSyncIndex, u16 VertStart,
			u16 HoriStart)
{
	u32 RegValue;
	u32 RegAddress;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(FrameSyncIndex <= 15);
	Xil_AssertVoid(VertStart <= 4095);
	Xil_AssertVoid(HoriStart <= 4095);

	/* Calculate the sync value */
	RegValue = HoriStart & XVTC_FSXX_HSTART_MASK;
	RegValue |= (VertStart << XVTC_FSXX_VSTART_SHIFT) &
			XVTC_FSXX_VSTART_MASK;

	/* Calculate the frame sync register address to write to */
	RegAddress = XVTC_FS00_OFFSET + FrameSyncIndex * XVTC_REG_ADDRGAP;

	/* Update the Generator Global Delay register w/ the value */
	XVtc_WriteReg(InstancePtr->Config.BaseAddress, RegAddress, RegValue);
}

/*****************************************************************************/
/**
*
* This function gets the SYNC setting of a frame sync used by the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	FrameSyncIndex indicates the index number of the frame sync.
* 		The valid range is from 0 to 15.
* @param	VertStartPtr will point to the value that indicates the
* 		vertical line count during which the frame sync is active once
*		this function returns.
* @param	HoriStartPtr will point to the value that indicates the
*		horizontal cycle count during which the frame sync is active
*		once this function returns.
*
* @return	None.
*
******************************************************************************/
void XVtc_GetFSync(XVtc *InstancePtr, u16 FrameSyncIndex,
			u16 *VertStartPtr, u16 *HoriStartPtr)
{
	u32 RegValue;
	u32 RegAddress;

	/* Assert bad arguments and conditions */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(FrameSyncIndex <= 15);
	Xil_AssertVoid(VertStartPtr != NULL);
	Xil_AssertVoid(VertStartPtr != NULL);

	/* Calculate the frame sync register address to read from */
	RegAddress = XVTC_FS00_OFFSET + FrameSyncIndex * XVTC_REG_ADDRGAP;

	/* Read the frame sync register value */
	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress, RegAddress);

	/* Calculate the frame sync values */
	*HoriStartPtr = RegValue & XVTC_FSXX_HSTART_MASK;
	*VertStartPtr = (RegValue & XVTC_FSXX_VSTART_MASK) >>
				XVTC_FSXX_VSTART_SHIFT;
}

/*****************************************************************************/
/**
 * This function sets the VBlank/VSync Horizontal Offsets for the Generator
 * in a VTC device.
 *
 * @param  InstancePtr is a pointer to the VTC device instance to be worked on.
 * @param  HoriOffsets points to a VBlank/VSync Horizontal Offset configuration
 *	   with the setting to use on the VTC device.
 * @return NONE.
 *
 *****************************************************************************/
void XVtc_SetGeneratorHoriOffset(XVtc *InstancePtr,
				XVtc_HoriOffsets *HoriOffsets)
{
	u32 RegValue;

	/* Assert bad arguments and conditions */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(HoriOffsets != NULL);

	/* Calculate and update Generator VBlank Hori. Offset 0 register value
	 */
	RegValue = (HoriOffsets->V0BlankHoriStart) & XVTC_XVXHOX_HSTART_MASK;
	RegValue |= (HoriOffsets->V0BlankHoriEnd << XVTC_XVXHOX_HEND_SHIFT) &
					XVTC_XVXHOX_HEND_MASK;
	XVtc_WriteReg(InstancePtr->Config.BaseAddress, XVTC_GVBHOFF_OFFSET,
								RegValue);

	/* Calculate and update Generator VSync Hori. Offset 0 register
	 * value
	 */
	RegValue = (HoriOffsets->V0SyncHoriStart) & XVTC_XVXHOX_HSTART_MASK;
	RegValue |= (HoriOffsets->V0SyncHoriEnd << XVTC_XVXHOX_HEND_SHIFT) &
					XVTC_XVXHOX_HEND_MASK;
	XVtc_WriteReg(InstancePtr->Config.BaseAddress, XVTC_GVSHOFF_OFFSET,
								RegValue);

	/* Calculate and update Generator VBlank Hori. Offset 1 register
	 * value
	 */
	RegValue = (HoriOffsets->V1BlankHoriStart) & XVTC_XVXHOX_HSTART_MASK;
	RegValue |= (HoriOffsets->V1BlankHoriEnd << XVTC_XVXHOX_HEND_SHIFT) &
					XVTC_XVXHOX_HEND_MASK;
	XVtc_WriteReg(InstancePtr->Config.BaseAddress, XVTC_GVBHOFF_F1_OFFSET,
								RegValue);

	/* Calculate and update Generator VSync Hori. Offset 1 register
	 * value
	 */
	RegValue = (HoriOffsets->V1SyncHoriStart) & XVTC_XVXHOX_HSTART_MASK;
	RegValue |= (HoriOffsets->V1SyncHoriEnd << XVTC_XVXHOX_HEND_SHIFT) &
					XVTC_XVXHOX_HEND_MASK;
	XVtc_WriteReg(InstancePtr->Config.BaseAddress,
						XVTC_GVSHOFF_F1_OFFSET,
								RegValue);
}

/*****************************************************************************/
/**
*
* This function gets the VBlank/VSync Horizontal Offsets currently used by
* the Generator in the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	HoriOffsets points to a VBlank/VSync Horizontal Offset
*		configuration structure that will be populated with the setting
*		currently used on the Generator in the given VTC device after
*		this function returns.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_GetGeneratorHoriOffset(XVtc *InstancePtr,
					XVtc_HoriOffsets *HoriOffsets)
{
	u32 RegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(HoriOffsets != NULL);

	/* Parse Generator VBlank Hori. Offset 0 register value */
	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_GVBHOFF_OFFSET);
	HoriOffsets->V0BlankHoriStart = RegValue & XVTC_XVXHOX_HSTART_MASK;
	HoriOffsets->V0BlankHoriEnd = (RegValue & XVTC_XVXHOX_HEND_MASK)
					>> XVTC_XVXHOX_HEND_SHIFT;

	/* Parse Generator VSync Hori. Offset 0 register value */
	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
						XVTC_GVSHOFF_OFFSET);
	HoriOffsets->V0SyncHoriStart = RegValue & XVTC_XVXHOX_HSTART_MASK;
	HoriOffsets->V0SyncHoriEnd = (RegValue & XVTC_XVXHOX_HEND_MASK)
					>> XVTC_XVXHOX_HEND_SHIFT;

	/* Parse Generator VBlank Hori. Offset 1 register value */
	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
						XVTC_GVBHOFF_F1_OFFSET);
	HoriOffsets->V1BlankHoriStart = RegValue & XVTC_XVXHOX_HSTART_MASK;
	HoriOffsets->V1BlankHoriEnd = (RegValue & XVTC_XVXHOX_HEND_MASK)
					>> XVTC_XVXHOX_HEND_SHIFT;

	/* Parse Generator VSync Hori. Offset 1 register value */
	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
					 XVTC_GVSHOFF_F1_OFFSET);
	HoriOffsets->V1SyncHoriStart = RegValue & XVTC_XVXHOX_HSTART_MASK;
	HoriOffsets->V1SyncHoriEnd = (RegValue & XVTC_XVXHOX_HEND_MASK)
					>> XVTC_XVXHOX_HEND_SHIFT;
}

/*****************************************************************************/
/**
*
* This function gets the VBlank/VSync Horizontal Offsets detected by
* the Detector in the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	HoriOffsets points to a VBlank/VSync Horizontal Offset
*		configuration structure that will be populated with the setting
*		detected on the Detector in the given VTC device after this
*		function returns.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_GetDetectorHoriOffset(XVtc *InstancePtr,
				XVtc_HoriOffsets *HoriOffsets)
{
	u32 RegValue;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(HoriOffsets != NULL);

	/* Parse Detector VBlank Hori. Offset 0 register value */
	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_DVBHOFF_OFFSET);
	HoriOffsets->V0BlankHoriStart = RegValue & XVTC_XVXHOX_HSTART_MASK;
	HoriOffsets->V0BlankHoriEnd = (RegValue & XVTC_XVXHOX_HEND_MASK)
					>> XVTC_XVXHOX_HEND_SHIFT;

	/* Parse Detector VSync Hori. Offset 0 register value */
	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
						XVTC_DVSHOFF_OFFSET);
	HoriOffsets->V0SyncHoriStart = RegValue & XVTC_XVXHOX_HSTART_MASK;
	HoriOffsets->V0SyncHoriEnd = (RegValue & XVTC_XVXHOX_HEND_MASK)
					>> XVTC_XVXHOX_HEND_SHIFT;

	/* Parse Detector VBlank Hori. Offset 1 register value */
	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
						XVTC_DVBHOFF_F1_OFFSET);
	HoriOffsets->V1BlankHoriStart = RegValue & XVTC_XVXHOX_HSTART_MASK;
	HoriOffsets->V1BlankHoriEnd = (RegValue & XVTC_XVXHOX_HEND_MASK)
					>> XVTC_XVXHOX_HEND_SHIFT;

	/* Parse Detector VSync Hori. Offset 1 register value */
	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
						XVTC_DVSHOFF_F1_OFFSET);
	HoriOffsets->V1SyncHoriStart = RegValue & XVTC_XVXHOX_HSTART_MASK;
	HoriOffsets->V1SyncHoriEnd = (RegValue & XVTC_XVXHOX_HEND_MASK)
					>> XVTC_XVXHOX_HEND_SHIFT;
}

/*****************************************************************************/
/**
*
* This function sets up VTC signal to be used by the Generator module
* in the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	SignalCfgPtr is a pointer to the VTC signal configuration
*		to be used by the Generator module in the VTC core.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XVtc_SetGenerator(XVtc *InstancePtr, XVtc_Signal *SignalCfgPtr)
{
	u32 RegValue;
	u32 r_htotal, r_vtotal, r_hactive, r_vactive;
	XVtc_Signal *SCPtr;
	XVtc_HoriOffsets horiOffsets;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(SignalCfgPtr != NULL);

	SCPtr = SignalCfgPtr;
	if(SCPtr->OriginMode == 0)
	{
		r_htotal = SCPtr->HTotal+1;
		r_vtotal = SCPtr->V0Total+1;

		r_hactive = r_htotal - SCPtr->HActiveStart;
		r_vactive = r_vtotal - SCPtr->V0ActiveStart;

		RegValue = (r_htotal) & XVTC_SB_START_MASK;
		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
					XVTC_GHSIZE_OFFSET, RegValue);

		RegValue = (r_vtotal) & XVTC_VSIZE_F0_MASK;
		RegValue |= ((SCPtr->V1Total+1) << XVTC_VSIZE_F1_SHIFT) &
							XVTC_VSIZE_F1_MASK;
		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
					XVTC_GVSIZE_OFFSET, RegValue);


		RegValue = (r_hactive) & XVTC_ASIZE_HORI_MASK;
		RegValue |= ((r_vactive) << XVTC_ASIZE_VERT_SHIFT ) &
							XVTC_ASIZE_VERT_MASK;
		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
						XVTC_GASIZE_OFFSET, RegValue);

		/* Update the Generator Horizontal 1 Register */
		RegValue = (SCPtr->HSyncStart + r_hactive) &
						XVTC_SB_START_MASK;
		RegValue |= ((SCPtr->HBackPorchStart + r_hactive) <<
				XVTC_SB_END_SHIFT) & XVTC_SB_END_MASK;
		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
					XVTC_GHSYNC_OFFSET, RegValue);

		/* Update the Generator Vertical 1 Register (field 0) */
		RegValue = (SCPtr->V0SyncStart + r_vactive -1) &
						XVTC_SB_START_MASK;
		RegValue |= ((SCPtr->V0BackPorchStart + r_vactive -1) <<
				XVTC_SB_END_SHIFT) & XVTC_SB_END_MASK;
		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
					XVTC_GVSYNC_OFFSET, RegValue);

		/* Update the Generator Vertical Sync Register (field 1) */
		RegValue = (SCPtr->V1SyncStart + r_vactive -1) &
						XVTC_SB_START_MASK;
		RegValue |= ((SCPtr->V1BackPorchStart + r_vactive -1) <<
					XVTC_SB_END_SHIFT) & XVTC_SB_END_MASK;
		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
					XVTC_GVSYNC_F1_OFFSET, RegValue);

		/* Chroma Start */
		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_GFENC_OFFSET);
		RegValue &= ~XVTC_ENC_CPARITY_MASK;
		RegValue = (((SCPtr->V0ChromaStart - SCPtr->V0ActiveStart) <<
						XVTC_ENC_CPARITY_SHIFT) &
					XVTC_ENC_CPARITY_MASK) | RegValue;

		RegValue &= ~XVTC_ENC_PROG_MASK;
		RegValue |= (SCPtr->Interlaced << XVTC_ENC_PROG_SHIFT) &
				XVTC_ENC_PROG_MASK;

		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
						XVTC_GFENC_OFFSET, RegValue);

		/* Setup default Horizontal Offsets - can override later with
		 * XVtc_SetGeneratorHoriOffset()
		 */
		horiOffsets.V0BlankHoriStart = r_hactive;
		horiOffsets.V0BlankHoriEnd = r_hactive;
		horiOffsets.V0SyncHoriStart = SCPtr->HSyncStart + r_hactive;
		horiOffsets.V0SyncHoriEnd = SCPtr->HSyncStart + r_hactive;

		horiOffsets.V1BlankHoriStart = r_hactive;
		horiOffsets.V1BlankHoriEnd = r_hactive;
		horiOffsets.V1SyncHoriStart = SCPtr->HSyncStart + r_hactive;
		horiOffsets.V1SyncHoriEnd = SCPtr->HSyncStart + r_hactive;

	}
	else
	{
		/* Total in mode=1 is the line width */
		r_htotal = SCPtr->HTotal;
		/* Total in mode=1 is the frame height */
		r_vtotal = SCPtr->V0Total;
		r_hactive = SCPtr->HFrontPorchStart;
		r_vactive = SCPtr->V0FrontPorchStart;

		RegValue = (r_htotal) & XVTC_SB_START_MASK;
		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
					XVTC_GHSIZE_OFFSET, RegValue);

		RegValue = (r_vtotal) & XVTC_VSIZE_F0_MASK;
		RegValue |= ((SCPtr->V1Total) << XVTC_VSIZE_F1_SHIFT) &
							XVTC_VSIZE_F1_MASK;
		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
						XVTC_GVSIZE_OFFSET, RegValue);


		RegValue = (r_hactive) & XVTC_ASIZE_HORI_MASK;
		RegValue |= ((r_vactive) << XVTC_ASIZE_VERT_SHIFT) &
							XVTC_ASIZE_VERT_MASK;
		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
						XVTC_GASIZE_OFFSET, RegValue);

		/* Update the Generator Horizontal 1 Register */
		RegValue = (SCPtr->HSyncStart) & XVTC_SB_START_MASK;
		RegValue |= ((SCPtr->HBackPorchStart) << XVTC_SB_END_SHIFT) &
						XVTC_SB_END_MASK;
		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
					XVTC_GHSYNC_OFFSET, RegValue);


		/* Update the Generator Vertical Sync Register (field 0) */
		RegValue = (SCPtr->V0SyncStart) & XVTC_SB_START_MASK;
		RegValue |= ((SCPtr->V0BackPorchStart) << XVTC_SB_END_SHIFT) &
						XVTC_SB_END_MASK;
		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
						XVTC_GVSYNC_OFFSET, RegValue);

		/* Update the Generator Vertical Sync Register (field 1) */
		RegValue = (SCPtr->V1SyncStart) & XVTC_SB_START_MASK;
		RegValue |= ((SCPtr->V1BackPorchStart) << XVTC_SB_END_SHIFT) &
						XVTC_SB_END_MASK;
		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
					XVTC_GVSYNC_F1_OFFSET, RegValue);

		/* Chroma Start */
		  RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_GFENC_OFFSET);
		RegValue &= ~XVTC_ENC_CPARITY_MASK;
		RegValue = (((SCPtr->V0ChromaStart - SCPtr->V0ActiveStart) <<
							XVTC_ENC_CPARITY_SHIFT)
					& XVTC_ENC_CPARITY_MASK) | RegValue;

		RegValue &= ~XVTC_ENC_PROG_MASK;
		RegValue |= (SCPtr->Interlaced << XVTC_ENC_PROG_SHIFT) &
						XVTC_ENC_PROG_MASK;

		XVtc_WriteReg(InstancePtr->Config.BaseAddress,
					XVTC_GFENC_OFFSET, RegValue);

		/* Setup default Horizontal Offsets - can override later with
		 * XVtc_SetGeneratorHoriOffset()
		 */
		horiOffsets.V0BlankHoriStart = r_hactive;
		horiOffsets.V0BlankHoriEnd = r_hactive;
		horiOffsets.V0SyncHoriStart = SCPtr->HSyncStart;
		horiOffsets.V0SyncHoriEnd = SCPtr->HSyncStart;
		horiOffsets.V1BlankHoriStart = r_hactive;
		horiOffsets.V1BlankHoriEnd = r_hactive;
		horiOffsets.V1SyncHoriStart = SCPtr->HSyncStart;
		horiOffsets.V1SyncHoriEnd = SCPtr->HSyncStart;

	}
	XVtc_SetGeneratorHoriOffset(InstancePtr, &horiOffsets);

}

/*****************************************************************************/
/**
*
* This function gets the VTC signal setting used by the Generator module
* in the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	SignalCfgPtr is a pointer to a VTC signal configuration
*		which will be populated with the setting used by the Generator
*		module in the VTC core once this function returns.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_GetGenerator(XVtc *InstancePtr, XVtc_Signal *SignalCfgPtr)
{
	u32 RegValue;
  u32 r_htotal, r_vtotal, r_hactive, r_vactive;
	XVtc_Signal *SCPtr;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(SignalCfgPtr != NULL);

	SCPtr = SignalCfgPtr;
  if(SCPtr->OriginMode == 0)
  {

	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress, XVTC_GHSIZE_OFFSET);
	r_htotal = (RegValue) & XVTC_SB_START_MASK;
	SCPtr->HTotal = (r_htotal-1) & XVTC_SB_START_MASK;

	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress, XVTC_GVSIZE_OFFSET);
	r_vtotal = (RegValue) & XVTC_VSIZE_F0_MASK;
	SCPtr->V0Total = (r_vtotal-1) & XVTC_VSIZE_F0_MASK;
	SCPtr->V1Total = (RegValue & XVTC_VSIZE_F1_MASK) >> XVTC_VSIZE_F1_SHIFT;
    if(SCPtr->V1Total != 0)
    {
      SCPtr->V1Total = SCPtr->V1Total - 1;
    }

	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress, XVTC_GASIZE_OFFSET);
	r_hactive = (RegValue) & XVTC_ASIZE_HORI_MASK;
	SCPtr->HActiveStart = (r_htotal - r_hactive) & XVTC_ASIZE_HORI_MASK;
	r_vactive = (RegValue & XVTC_ASIZE_VERT_MASK) >> XVTC_ASIZE_VERT_SHIFT;

	SCPtr->V0ActiveStart = (r_vtotal - r_vactive) & XVTC_VSIZE_F0_MASK;
	SCPtr->V1ActiveStart = (SCPtr->V1Total - r_vactive - 1) & XVTC_VSIZE_F0_MASK;

	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress, XVTC_GHSYNC_OFFSET);
    SCPtr->HSyncStart = ((RegValue - r_hactive) & XVTC_SB_START_MASK);
    SCPtr->HBackPorchStart = (((RegValue>>16) - r_hactive) & XVTC_SB_START_MASK);

	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress, XVTC_GVSYNC_OFFSET);
    SCPtr->V0SyncStart = ((RegValue-r_vactive+1) & XVTC_SB_START_MASK);
    SCPtr->V0BackPorchStart = (((RegValue>>16) - r_vactive+1) & XVTC_SB_START_MASK);

	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress, XVTC_GVSYNC_F1_OFFSET);
    SCPtr->V1SyncStart = ((RegValue-r_vactive+1) & XVTC_SB_START_MASK);
    SCPtr->V1BackPorchStart = (((RegValue>>16) - r_vactive+1) & XVTC_SB_START_MASK);


	/* Get signal values from the Generator Vertical 2 Register (field 0)*/
	RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress, XVTC_GFENC_OFFSET);
	SCPtr->V0ChromaStart = (((RegValue & XVTC_ENC_CPARITY_MASK) >>
					XVTC_ENC_CPARITY_SHIFT) + (r_vtotal - r_vactive)) & XVTC_SB_START_MASK;

	SCPtr->V1ChromaStart = (((RegValue & XVTC_ENC_CPARITY_MASK) >>
					XVTC_ENC_CPARITY_SHIFT) + (SCPtr->V1Total - r_vactive - 1)) & XVTC_SB_START_MASK;

	SCPtr->Interlaced = (RegValue & XVTC_ENC_PROG_MASK) >> XVTC_ENC_PROG_SHIFT;
    SCPtr->HFrontPorchStart = 0;
    SCPtr->V0FrontPorchStart = 0;
  }
	else
	{
		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_GHSIZE_OFFSET);
		r_htotal = (RegValue) & XVTC_SB_START_MASK;
		SCPtr->HTotal = (r_htotal) & XVTC_SB_START_MASK;

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_GVSIZE_OFFSET);
		r_vtotal = (RegValue) & XVTC_SB_START_MASK;
		SCPtr->V0Total = (r_vtotal) & XVTC_SB_START_MASK;
		SCPtr->V1Total = (RegValue>>XVTC_SB_END_SHIFT) &
							XVTC_SB_START_MASK;

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_GASIZE_OFFSET);
		r_hactive = (RegValue) & XVTC_SB_START_MASK;
		SCPtr->HFrontPorchStart = (r_hactive) & XVTC_SB_START_MASK;
		r_vactive = (RegValue>>XVTC_SB_END_SHIFT) & XVTC_SB_START_MASK;
		SCPtr->V0FrontPorchStart = (r_vactive) & XVTC_SB_START_MASK;
		SCPtr->V1FrontPorchStart = SCPtr->V0FrontPorchStart;

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_GHSYNC_OFFSET);
		SCPtr->HSyncStart = ((RegValue) & XVTC_SB_START_MASK);
		SCPtr->HBackPorchStart = (((RegValue>>XVTC_SB_END_SHIFT)) &
							XVTC_SB_START_MASK);

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_GVSYNC_OFFSET);
		SCPtr->V0SyncStart = ((RegValue) & XVTC_SB_START_MASK);
		SCPtr->V0BackPorchStart = (((RegValue>>XVTC_SB_END_SHIFT)) &
							XVTC_SB_START_MASK);

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_GVSYNC_F1_OFFSET);
		SCPtr->V1SyncStart = ((RegValue) & XVTC_SB_START_MASK);
		SCPtr->V1BackPorchStart = (((RegValue>>XVTC_SB_END_SHIFT)) &
							XVTC_SB_START_MASK);

		/* Get signal values from the Generator Vertical 2 Register (field 0)*/
		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_GFENC_OFFSET);
		SCPtr->V0ChromaStart = (((RegValue & XVTC_ENC_CPARITY_MASK) >>
				XVTC_ENC_CPARITY_SHIFT)) & XVTC_SB_START_MASK;
		SCPtr->V1ChromaStart = (((RegValue & XVTC_ENC_CPARITY_MASK) >>
				XVTC_ENC_CPARITY_SHIFT)) & XVTC_SB_START_MASK;
		SCPtr->Interlaced = (RegValue & XVTC_ENC_PROG_MASK) >> XVTC_ENC_PROG_SHIFT;

		SCPtr->HActiveStart = 0;
		SCPtr->V0ActiveStart = 0;
		SCPtr->V1ActiveStart = 0;
	}
}

/*****************************************************************************/
/**
*
* This function gets the VTC signal setting used by the Detector module
* in the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	SignalCfgPtr is a pointer to a VTC signal configuration
*		which will be populated with the setting used by the Detector
*		module in the VTC core once this function returns.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_GetDetector(XVtc *InstancePtr, XVtc_Signal *SignalCfgPtr)
{
	u32 RegValue;
	u32 r_htotal, r_vtotal, r_hactive, r_vactive;
	XVtc_Signal *SCPtr;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(SignalCfgPtr != NULL);

	SCPtr = SignalCfgPtr;

	if(SCPtr->OriginMode == 0)
	{
		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
						XVTC_DHSIZE_OFFSET);
		r_htotal = (RegValue) & XVTC_SB_START_MASK;
		SCPtr->HTotal = (r_htotal-1) & XVTC_SB_START_MASK;

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
						XVTC_DVSIZE_OFFSET);
		r_vtotal = (RegValue) & XVTC_SB_START_MASK;
		SCPtr->V0Total = (r_vtotal-1) & XVTC_SB_START_MASK;
		SCPtr->V1Total = (RegValue>>XVTC_SB_END_SHIFT) &
							XVTC_SB_START_MASK;
		if(SCPtr->V1Total != 0) {
			SCPtr->V1Total = SCPtr->V1Total - 1;
		}

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_DASIZE_OFFSET);
		r_hactive = (RegValue) & XVTC_SB_START_MASK;
		SCPtr->HActiveStart = (r_htotal - r_hactive) &
						XVTC_SB_START_MASK;
		r_vactive = (RegValue>>XVTC_SB_END_SHIFT) &
						XVTC_SB_START_MASK;
		SCPtr->V0ActiveStart = (r_vtotal - r_vactive) &
						XVTC_SB_START_MASK;
		SCPtr->V1ActiveStart = (SCPtr->V1Total - r_vactive - 1) &
							XVTC_SB_START_MASK;

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_DHSYNC_OFFSET);
		SCPtr->HSyncStart = ((RegValue - r_hactive) &
						XVTC_SB_START_MASK);
		SCPtr->HBackPorchStart = (((RegValue>>XVTC_SB_END_SHIFT) -
							r_hactive)
						& XVTC_SB_START_MASK);

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_DVSYNC_OFFSET);
		SCPtr->V0SyncStart = ((RegValue-r_vactive+1) &
							XVTC_SB_START_MASK);
		SCPtr->V0BackPorchStart = (((RegValue>>XVTC_SB_END_SHIFT) -
					r_vactive+1) & XVTC_SB_START_MASK);

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
						XVTC_GVSYNC_F1_OFFSET);
		SCPtr->V1SyncStart = ((RegValue-r_vactive+1) &
						XVTC_SB_START_MASK);
		SCPtr->V1BackPorchStart = (((RegValue>>XVTC_SB_END_SHIFT) -
								r_vactive+1)
							& XVTC_SB_START_MASK);

		/* Get signal values from the Generator Vertical 2 Register
		 * (field 0)
		 */
		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_DFENC_OFFSET);
		SCPtr->V0ChromaStart = (((RegValue & XVTC_ENC_CPARITY_MASK) >>
					XVTC_ENC_CPARITY_SHIFT) +
				(r_vtotal - r_vactive)) & XVTC_SB_START_MASK;

		SCPtr->V1ChromaStart = (((RegValue & XVTC_ENC_CPARITY_MASK) >>
						XVTC_ENC_CPARITY_SHIFT) +
			(SCPtr->V1Total - r_vactive - 1)) & XVTC_SB_START_MASK;
		SCPtr->Interlaced = (RegValue & XVTC_ENC_PROG_MASK) >> XVTC_ENC_PROG_SHIFT;

		SCPtr->HFrontPorchStart = 0;
		SCPtr->V0FrontPorchStart = 0;
	}
	else
	{
		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_DHSIZE_OFFSET);
		r_htotal = (RegValue) & XVTC_SB_START_MASK;
		SCPtr->HTotal = (r_htotal) & XVTC_SB_START_MASK;

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_DVSIZE_OFFSET);
		r_vtotal = (RegValue) & XVTC_SB_START_MASK;
		SCPtr->V0Total = (r_vtotal) & XVTC_SB_START_MASK;
		SCPtr->V1Total = (RegValue>>XVTC_SB_END_SHIFT) &
							XVTC_SB_START_MASK;

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_DASIZE_OFFSET);
		r_hactive = (RegValue) & XVTC_SB_START_MASK;
		SCPtr->HFrontPorchStart = (r_hactive) & XVTC_SB_START_MASK;
		r_vactive = (RegValue>>XVTC_SB_END_SHIFT) & XVTC_SB_START_MASK;
		SCPtr->V0FrontPorchStart = (r_vactive) & XVTC_SB_START_MASK;
		SCPtr->V1FrontPorchStart = SCPtr->V0FrontPorchStart;

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_DHSYNC_OFFSET);
		SCPtr->HSyncStart = ((RegValue) & XVTC_SB_START_MASK);
		SCPtr->HBackPorchStart = (((RegValue>>XVTC_SB_END_SHIFT)) &
							XVTC_SB_START_MASK);

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_DVSYNC_OFFSET);
		SCPtr->V0SyncStart = ((RegValue) & XVTC_SB_START_MASK);
		SCPtr->V0BackPorchStart = (((RegValue>>XVTC_SB_END_SHIFT)) &
							XVTC_SB_START_MASK);

		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_DVSYNC_F1_OFFSET);
		SCPtr->V1SyncStart = ((RegValue) & XVTC_SB_START_MASK);
		SCPtr->V1BackPorchStart = (((RegValue>>XVTC_SB_END_SHIFT)) &
							XVTC_SB_START_MASK);


		/* Get signal values from the Generator Vertical 2 Register
		 * (field 0)
		 */
		RegValue = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
							XVTC_DFENC_OFFSET);
		SCPtr->V0ChromaStart = (((RegValue & XVTC_ENC_CPARITY_MASK) >>
				XVTC_ENC_CPARITY_SHIFT)) & XVTC_SB_START_MASK;

		SCPtr->V1ChromaStart = (((RegValue & XVTC_ENC_CPARITY_MASK) >>
				XVTC_ENC_CPARITY_SHIFT)) & XVTC_SB_START_MASK;
		SCPtr->Interlaced = (RegValue & XVTC_ENC_PROG_MASK) >> XVTC_ENC_PROG_SHIFT;

		SCPtr->HActiveStart = 0;
		SCPtr->V0ActiveStart = 0;
		SCPtr->V1ActiveStart = 0;
	}


}

/*****************************************************************************/
/**
*
* This function facilitates software identification of exact version of the
* VTC hardware (h/w).
*
* @param	InstancePtr is a pointer to the XVtc instance.
*
* @return	Version, contents of a Version register.
*
* @note		None.
*
******************************************************************************/
u32 XVtc_GetVersion(XVtc *InstancePtr)
{
	u32 Version;

	/* Verify argument */
	Xil_AssertNonvoid(InstancePtr != NULL);

	/* Read Version register */
	Version = XVtc_ReadReg(InstancePtr->Config.BaseAddress,
				XVTC_VER_OFFSET);

	return Version;
}

/*****************************************************************************/
/**
*
* This function converts the video mode integer into the video timing
* information stored within the XVtc_Timing pointer.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	Mode is a u16 int defined as macro to one of the predefined
*		Video Modes.
* @param	TimingPtr is a pointer to a VTC Video Timing Structure.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_ConvVideoMode2Timing(XVtc *InstancePtr, u16 Mode,
					XVtc_Timing *TimingPtr)
{
	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(TimingPtr != NULL);

	/* clear timing structure. Set Interlaced to 0 by default */
	memset((void *)TimingPtr, 0, sizeof(XVtc_Timing));

	switch(Mode)
	{
	case XVTC_VMODE_720P: // 720p@60 (1280x720 HD 720)
	{

		// Horizontal Timing
		TimingPtr->HActiveVideo  = 1280;
		TimingPtr->HFrontPorch   = 110;
		TimingPtr->HSyncWidth    = 40;
		TimingPtr->HBackPorch    = 220;
		TimingPtr->HSyncPolarity = 1;

		// Vertical Timing
		TimingPtr->VActiveVideo  = 720;
		TimingPtr->V0FrontPorch   = 5;
		TimingPtr->V0SyncWidth    = 5;
		TimingPtr->V0BackPorch    = 20;
		TimingPtr->VSyncPolarity = 1;

		break;
	}
	case XVTC_VMODE_1080P: // 1080p@60 (1920x1080 HD 1080)
	{
		// Horizontal Timing
		TimingPtr->HActiveVideo  = 1920;
		TimingPtr->HFrontPorch   = 88;
		TimingPtr->HSyncWidth    = 44;
		TimingPtr->HBackPorch    = 148;
		TimingPtr->HSyncPolarity = 1;

		 // Vertical Timing
		TimingPtr->VActiveVideo  = 1080;
		TimingPtr->V0FrontPorch   = 4;
		TimingPtr->V0SyncWidth    = 5;
		TimingPtr->V0BackPorch    = 36;
		TimingPtr->VSyncPolarity = 1;

		break;
	}
	case XVTC_VMODE_480P: // 480p@60
	{
		// Horizontal Timing
		TimingPtr->HActiveVideo  = 720;
		TimingPtr->HFrontPorch   = 16;
		TimingPtr->HSyncWidth    = 62;
		TimingPtr->HBackPorch    = 60;
		TimingPtr->HSyncPolarity = 0;

		 // Vertical Timing
		TimingPtr->VActiveVideo  = 480;
		TimingPtr->V0FrontPorch   = 9;
		TimingPtr->V0SyncWidth    = 6;
		TimingPtr->V0BackPorch    = 30;
		TimingPtr->VSyncPolarity = 0;

		break;
	}
	case XVTC_VMODE_576P: // 576p@50
	{
		// Horizontal Timing
		TimingPtr->HActiveVideo  = 720;
		TimingPtr->HFrontPorch   = 12;
		TimingPtr->HSyncWidth    = 64;
		TimingPtr->HBackPorch    = 68;
		TimingPtr->HSyncPolarity = 0;

		 // Vertical Timing
		TimingPtr->VActiveVideo  = 576;
		TimingPtr->V0FrontPorch   = 5;
		TimingPtr->V0SyncWidth    = 5;
		TimingPtr->V0BackPorch    = 39;
		TimingPtr->VSyncPolarity = 0;

		break;
	}
	case XVTC_VMODE_VGA: // 640x480 (VGA)
	{
		// Horizontal Timing
		TimingPtr->HActiveVideo  = 656;
		TimingPtr->HFrontPorch   = 8;
		TimingPtr->HSyncWidth    = 96;
		TimingPtr->HBackPorch    = 40;
		TimingPtr->HSyncPolarity = 0;

		 // Vertical Timing
		TimingPtr->VActiveVideo  = 496;
		TimingPtr->V0FrontPorch   = 2;
		TimingPtr->V0SyncWidth    = 2;
		TimingPtr->V0BackPorch    = 25;
		TimingPtr->VSyncPolarity = 0;

		break;
	}
	case XVTC_VMODE_SVGA: // 800x600@60 (SVGA)
	{
		// Horizontal Timing
		TimingPtr->HActiveVideo  = 800;
		TimingPtr->HFrontPorch   = 40;
		TimingPtr->HSyncWidth    = 128;
		TimingPtr->HBackPorch    = 88;
		TimingPtr->HSyncPolarity = 1;

		 // Vertical Timing
		TimingPtr->VActiveVideo  = 600;
		TimingPtr->V0FrontPorch   = 1;
		TimingPtr->V0SyncWidth    = 4;
		TimingPtr->V0BackPorch    = 23;
		TimingPtr->VSyncPolarity = 1;

		break;
	}
	case XVTC_VMODE_XGA: // 1024x768@60 (XGA)
	{
		// Horizontal Timing
		TimingPtr->HActiveVideo  = 1024;
		TimingPtr->HFrontPorch   = 24;
		TimingPtr->HSyncWidth    = 136;
		TimingPtr->HBackPorch    = 160;
		TimingPtr->HSyncPolarity = 0;

		 // Vertical Timing
		TimingPtr->VActiveVideo  = 768;
		TimingPtr->V0FrontPorch   = 3;
		TimingPtr->V0SyncWidth    = 6;
		TimingPtr->V0BackPorch    = 29;
		TimingPtr->VSyncPolarity = 0;

		break;
	}
	case XVTC_VMODE_SXGA: // 1280x1024@60 (SXGA)
	{
		// Horizontal Timing
		TimingPtr->HActiveVideo  = 1280;
		TimingPtr->HFrontPorch   = 48;
		TimingPtr->HSyncWidth    = 112;
		TimingPtr->HBackPorch    = 248;
		TimingPtr->HSyncPolarity = 1;

		 // Vertical Timing
		TimingPtr->VActiveVideo  = 1024;
		TimingPtr->V0FrontPorch   = 1;
		TimingPtr->V0SyncWidth    = 3;
		TimingPtr->V0BackPorch    = 38;
		TimingPtr->VSyncPolarity = 1;

		break;
	}

	case XVTC_VMODE_WXGAPLUS: // 1440x900@60 (WXGA+)
	{
		// Horizontal Timing
		TimingPtr->HActiveVideo  = 1440;
		TimingPtr->HFrontPorch   = 80;
		TimingPtr->HSyncWidth    = 152;
		TimingPtr->HBackPorch    = 232;
		TimingPtr->HSyncPolarity = 0;

		 // Vertical Timing
		TimingPtr->VActiveVideo  = 900;
		TimingPtr->V0FrontPorch   = 3;
		TimingPtr->V0SyncWidth    = 6;
		TimingPtr->V0BackPorch    = 25;
		TimingPtr->VSyncPolarity = 1;

		break;
	}
	case XVTC_VMODE_WSXGAPLUS: // 1680x1050@60 (WSXGA+)
	{
		// Horizontal Timing
		TimingPtr->HActiveVideo  = 1680;
		TimingPtr->HFrontPorch   = 104;
		TimingPtr->HSyncWidth    = 176;
		TimingPtr->HBackPorch    = 280;
		TimingPtr->HSyncPolarity = 0;

		 // Vertical Timing
		TimingPtr->VActiveVideo  = 1050;
		TimingPtr->V0FrontPorch   = 3;
		TimingPtr->V0SyncWidth    = 6;
		TimingPtr->V0BackPorch    = 30;
		TimingPtr->VSyncPolarity = 1;

		break;
	}
	case XVTC_VMODE_1080I: // 1080i@60
	{
		TimingPtr->Interlaced = 1;

		// Horizontal Timing
		TimingPtr->HActiveVideo  = 1920;
		TimingPtr->HFrontPorch   = 88;
		TimingPtr->HSyncWidth    = 44;
		TimingPtr->HBackPorch    = 148;
		TimingPtr->HSyncPolarity = 1;

		 // Vertical Timing
		TimingPtr->VActiveVideo  = 540;
		TimingPtr->V0FrontPorch   = 2;
		TimingPtr->V0SyncWidth    = 5;
		TimingPtr->V0BackPorch    = 15;

		TimingPtr->V1FrontPorch   = 2;
		TimingPtr->V1SyncWidth    = 5;
		TimingPtr->V1BackPorch    = 16;

		TimingPtr->VSyncPolarity = 1;

		break;
	}
	case XVTC_VMODE_NTSC: //480i@60
	{
		TimingPtr->Interlaced = 1;
		// Horizontal Timing
		TimingPtr->HActiveVideo  = 720;
		TimingPtr->HFrontPorch   = 19;
		TimingPtr->HSyncWidth    = 62;
		TimingPtr->HBackPorch    = 57;
		TimingPtr->HSyncPolarity = 0;

		 // Vertical Timing
		TimingPtr->VActiveVideo  = 240;
		TimingPtr->V0FrontPorch   = 4;
		TimingPtr->V0SyncWidth    = 3;
		TimingPtr->V0BackPorch    = 15;

		TimingPtr->V1FrontPorch   = 4;
		TimingPtr->V1SyncWidth    = 3;
		TimingPtr->V1BackPorch    = 16;

		TimingPtr->VSyncPolarity = 0;

		break;
	}
	case XVTC_VMODE_PAL: //576i@50
	{
		TimingPtr->Interlaced = 1;
		// Horizontal Timing
		TimingPtr->HActiveVideo  = 720;
		TimingPtr->HFrontPorch   = 12;
		TimingPtr->HSyncWidth    = 63;
		TimingPtr->HBackPorch    = 69;
		TimingPtr->HSyncPolarity = 0;

		 // Vertical Timing
		TimingPtr->VActiveVideo  = 288;
		TimingPtr->V0FrontPorch   = 2;
		TimingPtr->V0SyncWidth    = 3;
		TimingPtr->V0BackPorch    = 19;

		TimingPtr->V1FrontPorch   = 2;
		TimingPtr->V1SyncWidth    = 3;
		TimingPtr->V1BackPorch    = 20;

		TimingPtr->VSyncPolarity = 0;

		break;
	}

	// add other video formats here
	}
}

/*****************************************************************************/
/**
*
* This function converts the video timing structure into the VTC signal
* configuration structure, horizontal offsets structure and the
* polarity structure.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	TimingPtr is a pointer to a Video Timing structure to be read.
* @param	SignalCfgPtr is a pointer to a VTC signal configuration to be
*		set.
* @param	HOffPtr is a pointer to a VTC horizontal offsets structure to
*		be set.
* @param	PolarityPtr is a pointer to a VTC polarity structure to be set.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_ConvTiming2Signal(XVtc *InstancePtr, XVtc_Timing *TimingPtr,
			XVtc_Signal *SignalCfgPtr, XVtc_HoriOffsets *HOffPtr,
			XVtc_Polarity *PolarityPtr)
{
	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(TimingPtr != NULL);
	Xil_AssertVoid(SignalCfgPtr != NULL);
	Xil_AssertVoid(HOffPtr != NULL);
	Xil_AssertVoid(PolarityPtr != NULL);


	/* Setting up VTC Polarity.  */
	memset((void *)PolarityPtr, 0, sizeof(XVtc_Polarity));
	PolarityPtr->ActiveChromaPol = 1;
	PolarityPtr->ActiveVideoPol  = 1;
	PolarityPtr->FieldIdPol      = 1;
	/* Vblank matches Vsync Polarity */
	PolarityPtr->VBlankPol       = TimingPtr->VSyncPolarity;
	PolarityPtr->VSyncPol        = TimingPtr->VSyncPolarity;
	/* hblank matches hsync Polarity */
	PolarityPtr->HBlankPol       = TimingPtr->HSyncPolarity;
	PolarityPtr->HSyncPol        = TimingPtr->HSyncPolarity;


	memset((void *)SignalCfgPtr, 0, sizeof(XVtc_Signal));
	memset((void *)HOffPtr, 0, sizeof(XVtc_HoriOffsets));

	/* Populate the VTC Signal config structure. */
	/* Active Video starts at 0 */
	SignalCfgPtr->OriginMode = 1;
	SignalCfgPtr->HActiveStart      = 0;
	SignalCfgPtr->HFrontPorchStart  = TimingPtr->HActiveVideo;
	SignalCfgPtr->HSyncStart        = SignalCfgPtr->HFrontPorchStart +
							TimingPtr->HFrontPorch;
	SignalCfgPtr->HBackPorchStart   = SignalCfgPtr->HSyncStart +
							TimingPtr->HSyncWidth;
	SignalCfgPtr->HTotal            = SignalCfgPtr->HBackPorchStart +
							TimingPtr->HBackPorch;

	SignalCfgPtr->V0ChromaStart     = 0;
	SignalCfgPtr->V0ActiveStart     = 0;
	SignalCfgPtr->V0FrontPorchStart = TimingPtr->VActiveVideo;
	SignalCfgPtr->V0SyncStart       = SignalCfgPtr->V0FrontPorchStart +
						TimingPtr->V0FrontPorch - 1;
	SignalCfgPtr->V0BackPorchStart  = SignalCfgPtr->V0SyncStart +
						TimingPtr->V0SyncWidth;
	SignalCfgPtr->V0Total           = SignalCfgPtr->V0BackPorchStart +
						TimingPtr->V0BackPorch + 1;

	HOffPtr->V0BlankHoriStart = SignalCfgPtr->HFrontPorchStart;
	HOffPtr->V0BlankHoriEnd   = SignalCfgPtr->HFrontPorchStart;
	HOffPtr->V0SyncHoriStart  = SignalCfgPtr->HSyncStart;
	HOffPtr->V0SyncHoriEnd    = SignalCfgPtr->HSyncStart;

	if(TimingPtr->Interlaced == 1) {
		SignalCfgPtr->V1ChromaStart     = 0;
		SignalCfgPtr->V1ActiveStart     = 0;
		SignalCfgPtr->V1FrontPorchStart = TimingPtr->VActiveVideo;
		SignalCfgPtr->V1SyncStart       =
					SignalCfgPtr->V1FrontPorchStart +
					TimingPtr->V1FrontPorch - 1;
		SignalCfgPtr->V1BackPorchStart  =
						SignalCfgPtr->V1SyncStart +
							TimingPtr->V1SyncWidth;
		SignalCfgPtr->V1Total           =
					SignalCfgPtr->V1BackPorchStart +
						TimingPtr->V1BackPorch + 1;
		SignalCfgPtr->Interlaced 		= 1;

		/* Align to H blank */
		HOffPtr->V1BlankHoriStart = SignalCfgPtr->HFrontPorchStart;
		/* Align to H Blank */
		HOffPtr->V1BlankHoriEnd   = SignalCfgPtr->HFrontPorchStart;

		/* Align to half line */
		HOffPtr->V1SyncHoriStart  = SignalCfgPtr->HSyncStart -
						(SignalCfgPtr->HTotal / 2);
		HOffPtr->V1SyncHoriEnd    = SignalCfgPtr->HSyncStart -
						(SignalCfgPtr->HTotal / 2);
	}
	/* Progressive formats */
	else {
	/* Set Field 1 same as Field 0 */
		SignalCfgPtr->V1ChromaStart     = SignalCfgPtr->V0ChromaStart;
		SignalCfgPtr->V1ActiveStart     = SignalCfgPtr->V0ActiveStart;
		SignalCfgPtr->V1FrontPorchStart =
					SignalCfgPtr->V0FrontPorchStart;
		SignalCfgPtr->V1SyncStart       = SignalCfgPtr->V0SyncStart;
		SignalCfgPtr->V1BackPorchStart  =
					SignalCfgPtr->V0BackPorchStart;
		SignalCfgPtr->V1Total           = SignalCfgPtr->V0Total;
		SignalCfgPtr->Interlaced		= 0;

		HOffPtr->V1BlankHoriStart = HOffPtr->V0BlankHoriStart;
		HOffPtr->V1BlankHoriEnd   = HOffPtr->V0BlankHoriEnd;
		HOffPtr->V1SyncHoriStart  = HOffPtr->V0SyncHoriStart;
		HOffPtr->V1SyncHoriEnd    = HOffPtr->V0SyncHoriEnd;
	}

}

/*****************************************************************************/
/**
*
* This function converts the VTC signal structure, horizontal offsets
* structure and the polarity structure into the Video Timing structure.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	SignalCfgPtr is a pointer to a VTC signal configuration to
*		be read
* @param	HOffPtr is a pointer to a VTC horizontal offsets structure
*		to be read
* @param	PolarityPtr is a pointer to a VTC polarity structure to be
*		read.
* @param	TimingPtr is a pointer to a Video Timing structure to be set.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_ConvSignal2Timing(XVtc *InstancePtr, XVtc_Signal *SignalCfgPtr,
				XVtc_HoriOffsets *HOffPtr,
				XVtc_Polarity *PolarityPtr,
				XVtc_Timing *TimingPtr)
{
	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(SignalCfgPtr != NULL);
	Xil_AssertVoid(HOffPtr != NULL);
	Xil_AssertVoid(PolarityPtr != NULL);
	Xil_AssertVoid(TimingPtr != NULL);
	Xil_AssertVoid(SignalCfgPtr->OriginMode == 1);

	memset((void *)TimingPtr, 0, sizeof(XVtc_Timing));

	/* Set Polarity */
	TimingPtr->VSyncPolarity = PolarityPtr->VSyncPol;
	TimingPtr->HSyncPolarity = PolarityPtr->HSyncPol;

	/* Horizontal Timing */
	TimingPtr->HActiveVideo = SignalCfgPtr->HFrontPorchStart;


	TimingPtr->HFrontPorch  = SignalCfgPtr->HSyncStart -
					SignalCfgPtr->HFrontPorchStart;
	TimingPtr->HSyncWidth   = SignalCfgPtr->HBackPorchStart -
				        SignalCfgPtr->HSyncStart;
	TimingPtr->HBackPorch   = SignalCfgPtr->HTotal -
					SignalCfgPtr->HBackPorchStart;

	/* Vertical Timing */
	TimingPtr->VActiveVideo  = SignalCfgPtr->V0FrontPorchStart;


	TimingPtr->V0FrontPorch  = SignalCfgPtr->V0SyncStart -
					  SignalCfgPtr->V0FrontPorchStart + 1;
	TimingPtr->V0SyncWidth   = SignalCfgPtr->V0BackPorchStart -
						SignalCfgPtr->V0SyncStart + 1;
	TimingPtr->V0BackPorch   = SignalCfgPtr->V0Total -
					SignalCfgPtr->V0BackPorchStart;

	TimingPtr->V1FrontPorch  = SignalCfgPtr->V1SyncStart -
					SignalCfgPtr->V1FrontPorchStart + 1;
	TimingPtr->V1SyncWidth   = SignalCfgPtr->V1BackPorchStart -
						SignalCfgPtr->V1SyncStart + 1;
	TimingPtr->V1BackPorch   = SignalCfgPtr->V1Total -
					SignalCfgPtr->V1BackPorchStart;

	/* Interlaced */
	TimingPtr->Interlaced  = SignalCfgPtr->Interlaced;

}

/*****************************************************************************/
/**
*
* This function converts the video timing structure into predefined video
* mode values returned as a short integer.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	TimingPtr is a pointer to a Video Timing structure to be read.
*
* @return	VideoMode is the video mode of the VTC core.
*
* @note		None.
*
******************************************************************************/
u16 XVtc_ConvTiming2VideoMode(XVtc *InstancePtr, XVtc_Timing *TimingPtr)
{
	/* Verify arguments. */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertNonvoid(TimingPtr != NULL);

	/* Checking for Interlaced value */
	if(TimingPtr->Interlaced == 0) {
		if(TimingPtr->HActiveVideo == 1280) {
			if (TimingPtr->VActiveVideo == 720) {
				return XVTC_VMODE_720P;
			}
			else if (TimingPtr->VActiveVideo == 1024) {
				return XVTC_VMODE_SXGA;
			}

		}
		else if((TimingPtr->HActiveVideo == 1920) &&
				(TimingPtr->VActiveVideo == 1080)) {
			return XVTC_VMODE_1080P;
		}
		else if(TimingPtr->HActiveVideo == 720) {
			if (TimingPtr->VActiveVideo == 480) {
				return XVTC_VMODE_480P;
			}
			else if (TimingPtr->VActiveVideo == 576) {
				return XVTC_VMODE_576P;
			}
		}
		else if((TimingPtr->HActiveVideo == 656) &&
				(TimingPtr->VActiveVideo == 496)) {
			return XVTC_VMODE_VGA;
		}
		else if((TimingPtr->HActiveVideo == 800) &&
				(TimingPtr->VActiveVideo == 600)) {
			return XVTC_VMODE_SVGA;
		}
		else if((TimingPtr->HActiveVideo == 1024) &&
			(TimingPtr->VActiveVideo == 768)) {
			return XVTC_VMODE_XGA;
		}
		else if((TimingPtr->HActiveVideo == 1440) &&
				(TimingPtr->VActiveVideo == 900)) {
			return XVTC_VMODE_WXGAPLUS;
		}
		else if((TimingPtr->HActiveVideo == 1680) &&
				(TimingPtr->VActiveVideo == 1050)) {
			return XVTC_VMODE_WSXGAPLUS;
		}

	}
	/* Interlaced */
	else {
		if((TimingPtr->HActiveVideo == 720) &&
			(TimingPtr->VActiveVideo == 240)) {
			return XVTC_VMODE_NTSC;
		}
		else if((TimingPtr->HActiveVideo == 1920) &&
			(TimingPtr->VActiveVideo == 540)) {
			return XVTC_VMODE_1080I;
		}
		else if((TimingPtr->HActiveVideo == 720) &&
				(TimingPtr->VActiveVideo == 288)) {
			return XVTC_VMODE_PAL;
		}

	}

	/* Not found - read from Timing to discover format */
	return 0;
}

/*****************************************************************************/
/**
*
* This function sets up the generator (Polarity, H/V values and horizontal
* offsets) by reading the configuration from a video timing structure.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	TimingPtr is a pointer to a Video Timing Structure to be read.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_SetGeneratorTiming(XVtc *InstancePtr, XVtc_Timing * TimingPtr)
{
	XVtc_Polarity Polarity;
	XVtc_Signal Signal;
	XVtc_HoriOffsets Hoff;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(TimingPtr != NULL);

	XVtc_ConvTiming2Signal(InstancePtr, TimingPtr, &Signal, &Hoff,
				&Polarity);
	XVtc_SetPolarity(InstancePtr, &Polarity);
	XVtc_SetGenerator(InstancePtr, &Signal);
	XVtc_SetGeneratorHoriOffset(InstancePtr, &Hoff);
}

/*****************************************************************************/
/**
*
* This function sets up the generator (Polarity, H/V values and horizontal
* offsets) by reading the configuration from a video mode short integer.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	Mode is a short integer predefined video mode.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_SetGeneratorVideoMode(XVtc *InstancePtr, u16 Mode)
{
	XVtc_Timing Timing;

	/* Verify arguments */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	XVtc_ConvVideoMode2Timing(InstancePtr, Mode, &Timing);

	XVtc_SetGeneratorTiming(InstancePtr, &Timing);

}

/*****************************************************************************/
/**
*
* This function gets the video timing structure settings currently used by
* generator in the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	TimingPtr is a pointer to a Video Timing Structure to be set.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_GetGeneratorTiming(XVtc *InstancePtr, XVtc_Timing *TimingPtr)
{

	XVtc_Polarity Polarity;
	XVtc_Signal Signal;
	XVtc_HoriOffsets Hoff;

	/* Verify arguments. */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(TimingPtr != NULL);


	Signal.OriginMode = 1;
	XVtc_GetPolarity(InstancePtr, &Polarity);
	XVtc_GetGeneratorHoriOffset(InstancePtr, &Hoff);
	XVtc_GetGenerator(InstancePtr, &Signal);

	XVtc_ConvSignal2Timing(InstancePtr, &Signal, &Hoff, &Polarity,
					TimingPtr);
}

/*****************************************************************************/
/**
*
* This function gets the video mode currently used by the generator
* in the VTC core. If the video mode is unknown or not recognized, then 0
* will be returned.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
*
* @return	VideoMode is the video mode of the VTC core.
*
* @note		Note.
*
******************************************************************************/
u16 XVtc_GetGeneratorVideoMode(XVtc *InstancePtr)
{

	u16 mode;
	XVtc_Timing Timing;

	/* Verify arguments */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	XVtc_GetGeneratorTiming(InstancePtr, &Timing);
	mode = XVtc_ConvTiming2VideoMode(InstancePtr, &Timing);

	return mode;
}

/*****************************************************************************/
/**
*
* This function gets the video timing structure settings currently reported by
* the detector in the VTC core.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
* @param	TimingPtr is a pointer to a Video Timing structure to be set.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVtc_GetDetectorTiming(XVtc *InstancePtr, XVtc_Timing *TimingPtr)
{
	XVtc_Polarity Polarity;
	XVtc_Signal Signal;
	XVtc_HoriOffsets Hoff;

	/* Verify arguments */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(TimingPtr != NULL);


	Signal.OriginMode = 1;
	XVtc_GetDetector(InstancePtr, &Signal);
	XVtc_GetDetectorPolarity(InstancePtr, &Polarity);
	XVtc_GetDetectorHoriOffset(InstancePtr, &Hoff);

	XVtc_ConvSignal2Timing(InstancePtr, &Signal, &Hoff, &Polarity,
					TimingPtr);
}

/*****************************************************************************/
/**
*
* This function gets the video mode currently reported by the detector
* in the VTC core. If the video mode is unknown or not recognized, then 0
* will be returned.
*
* @param	InstancePtr is a pointer to the VTC instance to be
*		worked on.
*
* @return 	VideoMode is the video mode of the VTC core.
*
* @note		None.
*
******************************************************************************/
u16 XVtc_GetDetectorVideoMode(XVtc *InstancePtr)
{
	u16 mode;
	XVtc_Timing Timing;

	/* Verify arguments */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);


	XVtc_GetDetectorTiming(InstancePtr, &Timing);
	mode = XVtc_ConvTiming2VideoMode(InstancePtr, &Timing);

	return mode;
}

/*****************************************************************************/
/**
*
* This routine is a stub for the asynchronous callbacks. The stub is here in
* case the upper layer forgot to set the handlers. On initialization, all
* handlers except error handler are set to this callback. It is considered an
* error for this handler to be invoked.
*
* @param	CallBackRef is a callback reference passed in by the upper
*		layer when setting the callback functions, and passed back
*		to the upper layer when the callback is invoked.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void StubCallBack(void *CallBackRef)
{
	(void)CallBackRef;
	Xil_AssertVoidAlways();
}

/*****************************************************************************/
/**
*
* This routine is a stub for the asynchronous error interrupt callback. The
* stub is here in case the upper layer forgot to set the handler. On
* initialization, Error interrupt handler is set to this callback. It is
* considered an error for this handler to be invoked.
*
* @param	CallBackRef is a callback reference passed in by the upper
*		layer when setting the callback functions, and passed back to
*		the upper layer when the callback is invoked.
* @param 	ErrorMask is a bit mask indicating the cause of the error. Its
*		value equals 'OR'ing one or more XVTC_IXR_*_MASK values defined
*		in xvtc_hw.h.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void StubErrCallBack(void *CallBackRef, u32 ErrorMask)
{
	(void)CallBackRef;
	(void)ErrorMask;
	Xil_AssertVoidAlways();
}
/** @} */
