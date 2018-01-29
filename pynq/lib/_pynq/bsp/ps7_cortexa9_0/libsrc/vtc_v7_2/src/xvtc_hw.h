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
* @file xvtc_hw.h
* @addtogroup vtc_v7_2
* @{
*
* This header file contains identifiers and register-level core functions (or
* macros) that can be used to access the Xilinx VTC core.
*
* For more information about the operation of this core, see the hardware
* specification and documentation in the higher level driver xvtc.h source
* code file.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who    Date     Changes
* ----- ------ -------- -------------------------------------------------------
* 1.00a xd     08/05/08 First release.
* 1.01a xd     07/23/10 Added GIER. Added more h/w generic info into
*                       xparameters.h. Feed callbacks with pending
*                       interrupt info. Added Doxygen & Version support.
* 2.00a cm     05/25/11 Renamed XVTC_CTL_GACS_MASK to XVTC_CTL_GACLS_MASKl.
*                       Added XVTC_CTL_GACPS_MASK.
* 3.00a cjm    08/01/12 Converted from xio.h to xil_io.h, translating basic
*                       types, MB cache functions, exceptions and assertions to
*                       xil_io format. Replaced the following
*                       "XExc_Init" -> "Xil_ExceptionInit"
*                       "XExc_RegisterHandler" -> "Xil_ExceptionRegisterHandler"
*                       "XEXC_ID_NON_CRITICAL_INT" -> "XIL_EXCEPTION_ID_INT"
*                       "XExceptionHandler" -> "Xil_ExceptionHandler"
*                       "XExc_mEnableExceptions" -> "Xil_ExceptionEnable"
*                       "XEXC_NON_CRITICAL" -> "XIL_EXCEPTION_NON_CRITICAL"
*                       "XExc_DisableExceptions" -> "Xil_ExceptionDisable"
*                       "XExc_RemoveHandler" -> "Xil_ExceptionRemoveHandler"
*                       "microblaze_enable_interrupts" -> "Xil_Exception
*                                                                      Enable"
*                       "microblaze_disable_interrupts" -> "Xil_Exception
*                                                                       Disable"
*
*                       "XCOMPONENT_IS_STARTED" -> "XIL_COMPONENT_IS_STARTED"
*                       "XCOMPONENT_IS_READY" -> "XIL_COMPONENT_IS_READY"
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
*                       "microblaze_init_dcache_range" -> "Xil_DCache
*                                                         InvalidateRange"
*
*                       "XCache_DisableDCache" -> "Xil_DCacheDisable"
*                       "XCache_DisableICache" -> "Xil_ICacheDisable"
*                       "XCache_EnableDCache" -> "Xil_DCacheEnableRegion"
*                       "XCache_EnableICache" -> "Xil_ICacheEnableRegion"
*                       "XCache_InvalidateDCacheLine" -> "Xil_DCache
*                                                       InvalidateRange"
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
* 3.00a cjm    08/02/12 Changed XVTC_RESET_RESET_MASK from 0x0000_000a
*                       to 0x8000_0000
* 4.00a cjm    02/07/13 Remove Unused defines: XVTC_GIER, XVTC_GIER_GIE_MASK.
* 4.00a cjm    02/08/13 Removed XVTC_CTL_HASS_MASK.
* 5.00a cjm    08/06/13 Replaced CTL in Polarity and Encoding register
*                       definition with "POL" and "ENC".
*                       Renamed XVTC_RESET_RESET_MASK to XVTC_CTL_RESET_MASK.
*                       Renamed XVTC_SYNC_RESET_MASK to XVTC_CTL_SRST_MASK.
*                       Renamed Error register bit defs to XVTC_ERR_*
*                       Added Patch and Internal Revision MASKs for.
*                       Revision register.
* 5.00a cjm    11/01/13 Removed Unused Hori Offset registers defines from
*                       0x0a0 - 0x0c0A
*                       Added interlaced register defines.
*                       Changed Version Register Revision shift from 12 to 8
*                       and changed mask to be 8 instead of 4 bits wide
* 5.00a cjm    11/03/13 Added Chroma/field parity bit masks.
*                       Replaced old timing bit masks/shifts with Start/End Bit
*                       masks/shifts.
* 6.1   adk    08/23/14 Removed XVTC_ERR_FIL_MASK macro because it is  not
*                       present in latest product guide.
*                       Modified register offsets from XVTC_* to XVTC_*_OFFSET
*                       for consistency.
*                       Added backward compatibility macros.
* 7.1   vns   10/14/15  Added XVTC_CTL_INTERLACE_MASK macro and
*                       modified XVTC_CTL_ALLSS_MASK
* </pre>
*
******************************************************************************/

#ifndef XVTC_HW_H_
#define XVTC_HW_H_	/**< prevent circular inclusions
			  * by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xil_io.h"

/************************** Constant Definitions *****************************/

/** @name Core Register Offsets
* @{
*/
#define XVTC_CTL_OFFSET		0x000	/**< Control Register Offset */
#define XVTC_ISR_OFFSET		0x004	/**< Status/Interrupt Status Register
					  *  Offset */
#define XVTC_ERROR_OFFSET	0x008	/**< Error Register Offset */
#define XVTC_IER_OFFSET		0x00C	/**< Interrupt Enable Register
					  *  Offset */
#define XVTC_VER_OFFSET		0x010	/**< Version Register Offset */

#define XVTC_DASIZE_OFFSET	0x020	/**< Detector Active Size Offset */
#define XVTC_DTSTAT_OFFSET	0x024	/**< Detector Timing Status Offset */
#define XVTC_DFENC_OFFSET	0x028	/**< Detector Encoding Offset */
#define XVTC_DPOL_OFFSET	0x02C	/**< Detector Polarity Offset */
#define XVTC_DHSIZE_OFFSET	0x030	/**< Detector Frame Horizontal Size
					  *  Offset */
#define XVTC_DVSIZE_OFFSET	0x034	/**< Detector Frame Vertical Size
					  *  Offset */
#define XVTC_DHSYNC_OFFSET	0x038	/**< Detector Horizontal sync
					  *  Offset */

#define XVTC_DVBHOFF_OFFSET	0x03C	/**< Detector Frame/F0 Vblank
					  *  Horizontal Offset */
#define XVTC_DVSYNC_OFFSET	0x040	/**< Detector Frame/F0 Vertical Sync
					  *  Offset */
#define XVTC_DVSHOFF_OFFSET	0x044	/**< Detector Frame/F0 Vsync Horizontal
					  *  Offset */

#define XVTC_DVBHOFF_F1_OFFSET 	0x048	/**< Detector Field 1 Vblank Horizontal
					  *  Offset */
#define XVTC_DVSYNC_F1_OFFSET	0x04C	/**< Detector Field 1 Vertical Sync
					  *  Offset */
#define XVTC_DVSHOFF_F1_OFFSET	0x050	/**< Detector Field 1 Vsync Horizontal
					  *  Offset */

#define XVTC_GASIZE_OFFSET	0x060	/**< Generator Active Size Offset */
#define XVTC_GTSTAT_OFFSET	0x064	/**< Generator Timing Status Offset */
#define XVTC_GFENC_OFFSET	0x068	/**< Generator Encoding Offset */
#define XVTC_GPOL_OFFSET	0x06C	/**< Generator Polarity Offset */
#define XVTC_GHSIZE_OFFSET	0x070	/**< Generator Frame Horizontal Size
					  *  Offset */
#define XVTC_GVSIZE_OFFSET	0x074	/**< Generator Frame Vertical Size
					  *  Offset */
#define XVTC_GHSYNC_OFFSET	0x078	/**< Generator Horizontal Sync
					  *  Offset */

#define XVTC_GVBHOFF_OFFSET	0x07C	/**< Generator Frame/F0 Vblank
					  *  Horizontal Offset */
#define XVTC_GVSYNC_OFFSET	0x080	/**< Generator Frame/F0 Vertical
					  *  Sync Offset */
#define XVTC_GVSHOFF_OFFSET	0x084	/**< Generator Frame/F0 Vsync
					  *  horizontal Offset */

#define XVTC_GVBHOFF_F1_OFFSET	0x088	/**< Generator Field 1 Vblank
					  *  Horizontal Offset */
#define XVTC_GVSYNC_F1_OFFSET	0x08C	/**< Generator Field 1 Vertical
					  *  Sync Offset */
#define XVTC_GVSHOFF_F1_OFFSET	0x090	/**< Generator Field 1 Vsync horizontal
					  *  Offset */

#define XVTC_FS00_OFFSET	0x100	/**< Frame Sync 00 Config
					  *  Register Offset */
#define XVTC_FS01_OFFSET	0x104	/**< Frame Sync 01 Config
					  *  Register Offset */
#define XVTC_FS02_OFFSET	0x108	/**< Frame Sync 02 Config
					  *  Register Offset */
#define XVTC_FS03_OFFSET	0x10C	/**< Frame Sync 03 Config
					  *  Register Offset */
#define XVTC_FS04_OFFSET	0x110	/**< Frame Sync 04 Config
					  *  Register Offset */
#define XVTC_FS05_OFFSET	0x114	/**< Frame Sync 05 Config
					  *  Register Offset */
#define XVTC_FS06_OFFSET	0x118	/**< Frame Sync 06 Config
					  *  Register Offset */
#define XVTC_FS07_OFFSET	0x11C	/**< Frame Sync 07 Config
					  *  Register Offset */
#define XVTC_FS08_OFFSET	0x120	/**< Frame Sync 08 Config
					  *  Register Offset */
#define XVTC_FS09_OFFSET	0x124	/**< Frame Sync 09 Config
					  *  Register Offset */
#define XVTC_FS10_OFFSET	0x128	/**< Frame Sync 10 Config
					  *  Register Offset */
#define XVTC_FS11_OFFSET	0x12C	/**< Frame Sync 11 Config
					  *  Register Offset */
#define XVTC_FS12_OFFSET	0x130	/**< Frame Sync 12 Config
					  *  Register Offset */
#define XVTC_FS13_OFFSET	0x134	/**< Frame Sync 13 Config
					  *  Register Offset */
#define XVTC_FS14_OFFSET	0x138	/**< Frame Sync 14 Config
					  *  Register Offset */
#define XVTC_FS15_OFFSET	0x13C	/**< Frame Sync 15 Config
					  *  Register Offset */

#define XVTC_GGD_OFFSET		0x140	/**< Generator Global Delay
					  *  Register Offset */
/*@}*/

/** @name Control Register Bit Definitions
* @{
*/
#define XVTC_CTL_RESET_MASK	0x80000000 /**< Software Reset Mask */
#define XVTC_CTL_SRST_MASK	0x40000000 /**< Frame Sync'ed Software
					      *  Reset Mask */
#define XVTC_CTL_FIPSS_MASK	0x04000000 /**< Field ID Output
					      *  Polarity Source Mask */
#define XVTC_CTL_ACPSS_MASK	0x02000000 /**< Active Chroma Output
					      *  Polarity Source Mask */
#define XVTC_CTL_AVPSS_MASK	0x01000000 /**< Active Video Output
					      *  Polarity Source Mask */
#define XVTC_CTL_HSPSS_MASK	0x00800000 /**< Horizontal Sync Output
					      *  Polarity Source Mask */
#define XVTC_CTL_VSPSS_MASK	0x00400000 /**< Vertical Sync Output
					      *  Polarity Source Mask */
#define XVTC_CTL_HBPSS_MASK	0x00200000 /**< Horizontal Blank Output
					      *  Polarity Source Mask */
#define XVTC_CTL_VBPSS_MASK	0x00100000 /**< Vertical Blank Output
					      *  Polarity Source Mask */

#define XVTC_CTL_INTERLACE_MASK	0x00080000 /**< Interlaced mode */

#define XVTC_CTL_VCSS_MASK	0x00040000 /**< Generator Chroma Polarity
					      *  and Encoding Source
					      *  Select Mask */
#define XVTC_CTL_VASS_MASK	0x00020000 /**< Generator Vertical Blank
					      *  Offset Source Select
					      *  Mask */
#define XVTC_CTL_VBSS_MASK	0x00010000 /**< Generator Vertical Sync End
					      *  (Back porch start) Source
					      *  Select Mask */
#define XVTC_CTL_VSSS_MASK	0x00008000 /**< Generator Vertical Sync
					     *  Start Source Select Mask */
#define XVTC_CTL_VFSS_MASK	0x00004000 /**< Generator Vertical Active Size
					     *  Source Select Mask */
#define XVTC_CTL_VTSS_MASK	0x00002000/**<  Generator Vertical Total Source
					     *   Select (Frame Size) Mask */

#define XVTC_CTL_HBSS_MASK	0x00000800 /**< Horizontal Back Porch Start
					      *  Register Source Select
					      *  (Sync End) Mask */
#define XVTC_CTL_HSSS_MASK	0x00000400 /**< Horizontal Sync Start Register
					      *  Source Select Mask */
#define XVTC_CTL_HFSS_MASK	0x00000200 /**< Horizontal Front Porch Start
					      *  Register Source Select
					      *  (Active Size) Mask */
#define XVTC_CTL_HTSS_MASK	0x00000100 /**< Horizontal Total Register
					      *  Source Select (Frame Size)
					      *  Mask */

#define XVTC_CTL_ALLSS_MASK	0x03FDEF00 /**< Bit mask for all source
					     *  select Mask */
//#define XVTC_CTL_LP_MASK	0x00000008 /**< Lock Polarity */
#define XVTC_CTL_SE_MASK	0x00000020 /**< Enable Sync with Detector */
#define XVTC_CTL_DE_MASK	0x00000008 /**< VTC Detector Enable */
#define XVTC_CTL_GE_MASK	0x00000004 /**< VTC Generator Enable */
#define XVTC_CTL_RU_MASK	0x00000002 /**< VTC Register Update */
#define XVTC_CTL_SW_MASK	0x00000001 /**< VTC Core Enable */
/*@}*/

/** @name Interrupt Status/Enable Register Bit Definitions
* @{
*/
#define XVTC_IXR_FSYNC15_MASK	0x80000000 /**< Frame Sync Interrupt 15
					      *  Mask */
#define XVTC_IXR_FSYNC14_MASK	0x40000000 /**< Frame Sync Interrupt 14
					      *  Mask */
#define XVTC_IXR_FSYNC13_MASK	0x20000000 /**< Frame Sync Interrupt 13
					      *  Mask */
#define XVTC_IXR_FSYNC12_MASK	0x10000000 /**< Frame Sync Interrupt 12
					      *  Mask */
#define XVTC_IXR_FSYNC11_MASK	0x08000000 /**< Frame Sync Interrupt 11
					      *  Mask */
#define XVTC_IXR_FSYNC10_MASK	0x04000000 /**< Frame Sync Interrupt 10
					      *  Mask */
#define XVTC_IXR_FSYNC09_MASK	0x02000000 /**< Frame Sync Interrupt 09
					      *  Mask */
#define XVTC_IXR_FSYNC08_MASK	0x01000000 /**< Frame Sync Interrupt 08
					      *  Mask */
#define XVTC_IXR_FSYNC07_MASK	0x00800000 /**< Frame Sync Interrupt 07
					      *  Mask */
#define XVTC_IXR_FSYNC06_MASK	0x00400000 /**< Frame Sync Interrupt 06
					      *  Mask */
#define XVTC_IXR_FSYNC05_MASK	0x00200000 /**< Frame Sync Interrupt 05
					      *  Mask */
#define XVTC_IXR_FSYNC04_MASK	0x00100000 /**< Frame Sync Interrupt 04
					      *  Mask */
#define XVTC_IXR_FSYNC03_MASK	0x00080000 /**< Frame Sync Interrupt 03
					      *  Mask */
#define XVTC_IXR_FSYNC02_MASK	0x00040000 /**< Frame Sync Interrupt 02
					      *  Mask */
#define XVTC_IXR_FSYNC01_MASK	0x00020000 /**< Frame Sync Interrupt 01
					      *  Mask */
#define XVTC_IXR_FSYNC00_MASK	0x00010000 /**< Frame Sync Interrupt 00
					      *  Mask */
#define XVTC_IXR_FSYNCALL_MASK	0xFFFF0000 /**< All Frame Sync Interrupt 0-15
					      *  Mask */

#define XVTC_IXR_G_AV_MASK	0x00002000 /**< Generator Active Video Intr
					      *  Mask */
#define XVTC_IXR_G_VBLANK_MASK	0x00001000 /**< Generator VBLANK Interrupt
					      *  Mask */
#define XVTC_IXR_G_ALL_MASK	0x00003000 /**< All Generator interrupts
					      *  Mask */

#define XVTC_IXR_D_AV_MASK	0x00000800 /**< Detector Active Video
					      *  Interrupt Mask */
#define XVTC_IXR_D_VBLANK_MASK	0x00000400 /**< Detector VBLANK Interrupt
					      *  Mask */
#define XVTC_IXR_D_ALL_MASK	0x00000C00 /**< All Detector Interrupts
					      *  Mask */

#define XVTC_IXR_LOL_MASK	0x00000200 /**< Lock Loss Mask */
#define XVTC_IXR_LO_MASK	0x00000100 /**< Lock Mask */
#define XVTC_IXR_LOCKALL_MASK	0x00000300 /**< All Signal Lock interrupt
					     *  Mask */

#define XVTC_IXR_ALLINTR_MASK	(XVTC_IXR_FSYNCALL_MASK |\
				 XVTC_IXR_G_ALL_MASK |\
				 XVTC_IXR_D_ALL_MASK |\
				 XVTC_IXR_LOCKALL_MASK) /**< Mask for all
							  *  interrupts Mask */

/** @name Error Register Bit Definitions
* @{
*/
#define XVTC_ERR_ACL_MASK	0x00200000	/**< Active Chroma Signal
						  *  Lock Mask */
#define XVTC_ERR_AVL_MASK	0x00100000	/**< Active Video Signal
						  *  Lock Mask */
#define XVTC_ERR_HSL_MASK	0x00080000	/**< Horizontal Sync Signal
						  *  Lock Mask */
#define XVTC_ERR_VSL_MASK	0x00040000	/**< Vertical Sync Signal
						  *  Lock Mask */
#define XVTC_ERR_HBL_MASK	0x00020000	/**< Horizontal Blank Signal
						  *  Lock Mask */
#define XVTC_ERR_VBL_MASK	0x00010000	/**< Vertical Blank Signal
						  *  Lock Mask */
/*@}*/

/** @name Version Register Bit Definition and Shifts
* @{
*/
#define XVTC_VER_MAJOR_MASK	0xFF000000	/**< Major Version Mask */
#define XVTC_VER_MAJOR_SHIFT	24		/**< Major Version Bit Shift */
#define XVTC_VER_MINOR_MASK	0x00FF0000	/**< Minor Version Mask */
#define XVTC_VER_MINOR_SHIFT	16		/**< Minor Version Bit Shift */
#define XVTC_VER_REV_MASK	0x0000FF00	/**< Revision Version Mask */
#define XVTC_VER_REV_SHIFT	8		/**< Revision Version Bit
						  *  Shift */
#define XVTC_VER_IREV_MASK	0x000000FF	/**< Internal Revision Version
						  *  Mask */
#define XVTC_VER_IREV_SHIFT	0		/**< Internal Revision Bit
						  *  Shift */
/*@}*/

/** @name Generator/Detector Active Video Size Register Bit Definitions and
* Shift
*  @{
*/
#define XVTC_ASIZE_VERT_MASK	0x1FFF0000 /**< Total number of lines
					      *  (including blanking) for
					      *  frame or field 1 */
#define XVTC_ASIZE_VERT_SHIFT	16	    /**<  Bit shift for End Cycle or
					      *   Line Count */
#define XVTC_ASIZE_HORI_MASK	0x00001FFF /**< Horizontal Active Frame
					      *  Size.The width of the frame
					      *  without blanking in number
					      *  of pixels or clocks. */
/*@}*/

/** @name Generator/Detector Status Bit Definitions
* @{
*/
#define XVTC_STAT_AVIDEO_MASK	0x00000004	/**< Active Video Interrupt
						  *  Status.Mask */
#define XVTC_STAT_VBLANK_MASK	0x00000002	/**< Vertical Blank Interrupt
						  *  Status Mask */
#define XVTC_STAT_LOCKED_MASK	0x00000001	/**< Lock Status. Set High when
						  *  all signals have locked.
						  *  (Detector only) Mask */
/*@}*/

/** @name Generator/Detector Encoding Register Bit Definitions
* @{
*/
#define XVTC_ENC_GACPS_MASK	0x00000200	/**< Generator Active Chroma
						  *  Pixel Skip/Parity Mask */
#define XVTC_ENC_CPARITY_MASK	0x00000100	/**< Chroma Line Parity Mask */
#define XVTC_ENC_CPARITY_SHIFT	8		/**< Bit shift for Active
						  *  Chroma Line Parity */
#define XVTC_ENC_FPARITY_MASK	0x00000080	/**< Field Parity Mask  */
#define XVTC_ENC_PROG_MASK	0x00000040	/**< Progressive/Interlaced
						  *  Mask */
#define XVTC_ENC_PROG_SHIFT	6			/**< Progressive/Interlaced
						  *  Shift */
#define XVTC_ENC_GACLS_MASK	0x00000001	/**< Generator Active Chroma
						  *  Line Skip/parity Mask */
/*@}*/

/** @name Generator/Detector Polarity Register Bit Definitions
* @{
*/
#define XVTC_POL_FIP_MASK	0x00000040	/**< Field ID Output
						  *  Polarity Mask */
#define XVTC_POL_ACP_MASK	0x00000020	/**< Active Chroma Output
						  *  Polarity Mask */
#define XVTC_POL_AVP_MASK	0x00000010	/**< Active Video Output
						  *  Polarity Mask */
#define XVTC_POL_HSP_MASK	0x00000008	/**< Horizontal Sync Output
						  *  Polarity Mask */
#define XVTC_POL_VSP_MASK	0x00000004	/**< Vertical Sync Output
						  *  Polarity Mask */
#define XVTC_POL_HBP_MASK	0x00000002	/**< Horizontal Blank Output
						  *  Polarity Mask */
#define XVTC_POL_VBP_MASK	0x00000001	/**< Vertical Blank Output
						  *  Polarity Mask */
#define XVTC_POL_ALLP_MASK	0x0000007F	/**< Bit mask for all
						  *  polarity bits Mask */
/*@}*/

/** @name Generator/Detector Full Vertical Size Register Bit Definitions
* and Shift
* @{
*/
#define XVTC_VSIZE_F1_MASK	0x1FFF0000 /**< Total number of lines
					      *  (including blanking) for
					      *  frame or field 1 */
#define XVTC_VSIZE_F1_SHIFT	16	/**< Bit shift for End Cycle or
					  *  Line Count */
#define XVTC_VSIZE_F0_MASK	0x00001FFF /**< Total number of lines
					      *  (including blanking) for
					      *  frame or field 0 */
/*@}*/

/** @name Generator/Detector Sync/Blank Register Bit Definitions and Shift
* @{
*/
#define XVTC_SB_END_MASK	0x1FFF0000 /**< End cycle or line count
					      *  of horizontal sync, vertical
					      *  sync or vertical blank */
#define XVTC_SB_END_SHIFT	16	    /**< Bit shift for End Cycle or
					      *  Line Count */
#define XVTC_SB_START_MASK	0x00001FFF /**< Start cycle or line count
					      *  of horizontal sync, vertical
					      *  sync or vertical blank */
/*@}*/

/** @name Generator/Detector VBlank/VSync Horizontal Bit Definitions and Shift
* @{
*/
#define XVTC_XVXHOX_HEND_MASK	0x1FFF0000	/**< Horizontal Offset End
						  *  Mask */
#define XVTC_XVXHOX_HEND_SHIFT	16		/**< Horizontal End Shift */
#define XVTC_XVXHOX_HSTART_MASK	0x00001FFF	/**< Horizontal Offset Start
						  *  Offset */
/*@}*/

/** @name Frame Sync 00 - 15
* @{
*/
#define XVTC_FSXX_VSTART_MASK	0x1FFF0000 /**< Vertical line count during
					      *  which current Frame Sync is
					      *  active Mask */
#define XVTC_FSXX_VSTART_SHIFT	16	    /**< Bit shift for the vertical
					      *  line count */
#define XVTC_FSXX_HSTART_MASK	0x00001FFF /**< Horizontal cycle count
					      *  during which current
					      *  Frame Sync is active Mask */
/*@}*/

/** @name VTC Generator Global Delay Bit Definition and Shift
* @{
*/
#define XVTC_GGD_VDELAY_MASK	0x1FFF0000	/**< Total lines per frame to
						  *  delay generator output
						  *  Mask */
#define XVTC_GGD_VDELAY_SHIFT	16		/**< Bit shift for the total
						  *  lines */
#define XVTC_GGD_HDELAY_MASK	0x00001FFF	/**< Total clock cycles per
						  *  line to delay generator
						  *  output Mask */
/*@}*/

/** @name Compatibility Macros
* @{
*/
#define XVTC_CTL	XVTC_CTL_OFFSET
#define XVTC_ISR	XVTC_ISR_OFFSET
#define XVTC_ERROR	XVTC_ERROR_OFFSET
#define XVTC_IER	XVTC_IER_OFFSET
#define XVTC_VER	XVTC_VER_OFFSET
#define XVTC_DASIZE	XVTC_DASIZE_OFFSET
#define XVTC_DTSTAT	XVTC_DTSTAT_OFFSET
#define XVTC_DFENC	XVTC_DFENC_OFFSET
#define XVTC_DPOL	XVTC_DPOL_OFFSET
#define XVTC_DHSIZE	XVTC_DHSIZE_OFFSET
#define XVTC_DVSIZE	XVTC_DVSIZE_OFFSET
#define XVTC_DHSYNC	XVTC_DHSYNC_OFFSET
#define XVTC_DVBHOFF	XVTC_DVBHOFF_OFFSET
#define XVTC_DVSYNC	XVTC_DVSYNC_OFFSET
#define XVTC_DVSHOFF	XVTC_DVSHOFF_OFFSET
#define XVTC_DVBHOFF_F1	XVTC_DVBHOFF_F1_OFFSET
#define XVTC_DVSYNC_F1	XVTC_DVSYNC_F1_OFFSET
#define XVTC_DVSHOFF_F1	XVTC_DVSHOFF_F1_OFFSET
#define XVTC_GASIZE	XVTC_GASIZE_OFFSET
#define XVTC_GTSTAT	XVTC_GTSTAT_OFFSET
#define XVTC_GFENC	XVTC_GFENC_OFFSET
#define XVTC_GPOL	XVTC_GPOL_OFFSET
#define XVTC_GHSIZE	XVTC_GHSIZE_OFFSET
#define XVTC_GVSIZE	XVTC_GVSIZE_OFFSET
#define XVTC_GHSYNC	XVTC_GHSYNC_OFFSET
#define XVTC_GVBHOFF	XVTC_GVBHOFF_OFFSET
#define XVTC_GVSYNC	XVTC_GVSYNC_OFFSET
#define XVTC_GVSHOFF	XVTC_GVSHOFF_OFFSET
#define XVTC_GVBHOFF_F1	XVTC_GVBHOFF_F1_OFFSET
#define XVTC_GVSYNC_F1	XVTC_GVSYNC_F1_OFFSET
#define XVTC_GVSHOFF_F1	XVTC_GVSHOFF_F1_OFFSET
#define XVTC_FS00	XVTC_FS00_OFFSET
#define XVTC_FS01	XVTC_FS01_OFFSET
#define XVTC_FS02	XVTC_FS02_OFFSET
#define XVTC_FS03	XVTC_FS03_OFFSET
#define XVTC_FS04	XVTC_FS04_OFFSET
#define XVTC_FS05	XVTC_FS05_OFFSET
#define XVTC_FS06	XVTC_FS06_OFFSET
#define XVTC_FS07	XVTC_FS07_OFFSET
#define XVTC_FS08	XVTC_FS08_OFFSET
#define XVTC_FS09	XVTC_FS09_OFFSET
#define XVTC_FS10	XVTC_FS10_OFFSET
#define XVTC_FS11	XVTC_FS11_OFFSET
#define XVTC_FS12	XVTC_FS12_OFFSET
#define XVTC_FS13	XVTC_FS13_OFFSET
#define XVTC_FS14	XVTC_FS14_OFFSET
#define XVTC_FS15	XVTC_FS15_OFFSET
#define XVTC_GGD	XVTC_GGD_OFFSET
/*@}*/

/***************** Macros (Inline Functions) Definitions *********************/

/** @name Register Access Macro Definition
* @{
*/
#define XVtc_In32		Xil_In32	/**< Input Operations */
#define XVtc_Out32		Xil_Out32	/**< Output Operations */

/*****************************************************************************/
/**
*
* This function macro reads the given register.
*
* @param	BaseAddress is the base address of the VTC core.
* @param	RegOffset is the register offset of the register (defined at
*		top of this file).
*
* @return	The 32-bit value of the register.
*
* @note		C-style signature:
*		u32 XVtc_ReadReg(u32 BaseAddress, u32 RegOffset)
*
******************************************************************************/
#define XVtc_ReadReg(BaseAddress, RegOffset) \
		XVtc_In32((BaseAddress) + ((u32)RegOffset))

/*****************************************************************************/
/**
*
* Write the given register.
*
* @param	BaseAddress is the base address of the VTC core.
* @param	RegOffset is the register offset of the register (defined at
*		top of this file) to be written.
* @param	Data is the 32-bit value to write to the register.
*
* @return	None.
*
* @note		C-style signature:
*		void XVtc_WriteReg(u32 BaseAddress, u32 RegOffset, u32 Data)
*
******************************************************************************/
#define XVtc_WriteReg(BaseAddress, RegOffset, Data) 	\
		XVtc_Out32((BaseAddress) + ((u32)RegOffset), (u32)(Data))
/*@}*/

/**************************** Type Definitions *******************************/


/************************** Function Prototypes ******************************/


/************************** Variable Declarations ****************************/


#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
/** @} */
