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
 *  @file xaxicdma.h
* @addtogroup axicdma_v4_5
* @{
* @details
 *
 * This is the driver API for the AXI CDMA engine.
 *
 * For a full description of the features of the AXI CDMA engine, please
 * refer to the hardware specification. This driver supports the following
 * features:
 *
 *   - Simple DMA transfer
 *   - Scatter gather (SG) DMA transfer
 *   - Interrupt for error or completion of transfers
 *   - For SG DMA transfer:
 *      - Programmable interrupt coalescing
 *      - Programmable delay timer counter
 *      - Managing the buffer descriptors (BDs)
 *
 * <b>Two Hardware Building Modes</b>
 *
 * The hardware can be built in two modes:
 *
 *  - <b>Simple only mode</b>, in this mode, only simple transfers are
 *    supported by the hardware. The functionality is similar to the XPS
 *    Central DMA, however, the driver API to do the transfer is slightly
 *    different.
 *
 *  - <b>Hybrid mode</b>, in this mode, the hardware supports both the simple
 *  transfer and the SG transfer. However, only one kind of transfer can be
 *  active at a time. If an SG transfer is ongoing in the hardware, a
 *  submission of a simple transfer fails. If a simple transfer is ongoing in
 *  the hardware, a submission of an SG transfer is successful, however the
 *  SG transfer will not start until the simple transfer is done.
 *
 * <b>Transactions</b>
 *
 * The hardware supports two types of transfers, the simple DMA transfer and
 * the scatter gather (SG) DMA transfer.
 *
 * A simple DMA transfer only needs source buffer address, destination buffer
 * address and transfer length to do a DMA transfer. Only one transfer can be
 * submitted to the hardware at a time.
 *
 * A SG DMA transfer requires setting up a buffer descriptor (BD), which keeps
 * the transfer information, including source buffer address, destination
 * buffer address, and transfer length. The hardware updates the BD for the
 * completion status of the transfer. BDs that are connected to each other can
 * be submitted to the hardware at once, therefore, the SG DMA transfer has
 * better performance when the application is doing multiple transfers each
 * time.
 *
 * <b>Callback Function</b>
 *
 * Each transfer, for which the application cares about its completion, should
 * provide with the driver its callback function. The signature of the
 * callback function is as the following:
 *
 * void XAxiCdma_CallBackFn(void *CallBackRef, u32 IrqMask, int *NumPtr);
 *
 * Where the CallBackRef is a reference pointer that the application passes to
 * the driver along with the callback function. The driver passes IrqMask to
 * the application when it calls this callback. The NumPtr is only used in SG
 * mode to track how many BDs still left for this callback function.
 *
 * The callback function is set upon transfer submission:
 *
 *  - Simple transfer callback function setup:
 *
 *   <b>Only set the callback function if in interrupt mode.</b>
 *
 *   For simple transfers, the callback function along with the callback
 *   reference pointer is passed to the driver through the submission of the
 *   simple transfer:
 *
 *        XAxiCdma_SimpleTransfer(...)
 *
 *  - SG transfer callback function setup:
 *   For SG transfers, the callback function and the callback reference
 *   pointer are set through the transfer submission call:
 *
 *        XAxiCdma_BdRingToHw(...)
 *
 * <b>Simple Transfers</b>
 *
 * For an application that only does one DMA transfer at a time, and the DMA
 * engine is exclusively used by this application, simple DMA transfer is
 * sufficient.
 *
 * Using the simple DMA transfer has the advantage of ease of use comparing to
 * SG DMA transfer. For an individual DMA transfer, simple DMA transfer is
 * also faster because of simplicity in software and hardware.
 *
 * <b>Scatter Gather (SG) Transfers</b>
 *
 * For an application that has multiple DMA transfers sometimes, or the DMA
 * engine is shared by multiple applications, using SG DMA transfer yields
 * better performance over all applications.
 *
 * The SG DMA transfer provides queuing of multiple transfers, therefore, it
 * provides better performance because the hardware can continuously work on
 * all submitted transfers without software intervention.
 *
 * The down side of using the SG DMA transfer is that you have to manage the
 * memory for the buffer descriptors (BD), and setup BDs for the transfers.
 *
 * <b>Interrupts</b>
 *
 * The driver handles the interrupts.
 *
 * The completion of a transfer, that has a callback function associated with,
 * will trigger the driver to call the callback function. The IrqMask that is
 * passed through the callback function notifies the application about the
 * completion status of the transfer.
 *
 * <b>Interrupt Coalescing for SG Transfers</b>
 *
 * For SG transfers, the application can program the interrupt coalescing
 * threshold to reduce the frequency of interrupts. If the number of transfers
 * does not match well with the interrupt coalescing threshold, the completion
 * of the last transfer will not trigger the completion interrupt. However,
 * after the specified delay count time, the delay interrupt will fire.
 *
 * By default, the interrupt threshold for the hardware is one, which is one
 * interrupt per BD completion.
 *
 * <b>Delay Interrupt for SG Transfers</b>
 *
 * Delay interrupt is to signal the application about inactivity of transfers.
 * If the delay interrupt is enabled, the delay timer starts counting down
 * once a transfer has started. If the interval between transfers is longer
 * than the delay counter, the delay interrupt is fired.
 *
 * By default, the delay counter is zero, which means the delay interrupt is
 * disabled. To enable delay interrupt, the delay interrupt enable bit must be
 * set and the delay counter must be set to a value between 1 to 255.
 *
 * <b>BD management for SG DMA Transfers </b>
 *
 * BD is shared by the software and the hardware. To use BD for SG DMA
 * transfers, the application needs to use the driver API to do the following:
 *
 * - Setup the BD ring:
 *      - XAxiCdma_BdRingCreate(...)
 *
 *   Note that the memory for the BD ring is allocated and is later
 *   de-allocated by the application.
 *
 * - Request BD from the BD ring, more than one BDs can be requested at once:
 *      - XAxiCdma_BdRingAlloc(...)
 *
 * - Prepare BDs for the transfer, one BD at a time:
 *      - XAxiCdma_BdSetSrcBufAddr(...)
 *      - XAxiCdma_BdSetDstBufAddr(...)
 *      - XAxiCdma_BdSetLength(...)
 *
 * - Submit all prepared BDs to the hardware:
 *      - XAxiCdma_BdRingToHw(...)
 *
 * - Upon transfer completion, the application can request completed BDs from
 *   the hardware:
 *      - XAxiCdma_BdRingFromHw(...)
 *
 * - After the application has finished using the BDs, it should free the
 *   BDs back to the free pool:
 *      - XAxiCdma_BdRingFree(...)
 *
 * The driver also provides API functions to get the status of a completed
 * BD, along with get functions for other fields in the BD.
 *
 * The following two diagrams show the correct flow of BDs:
 *
 * The first diagram shows a complete cycle for BDs, starting from
 * requesting the BDs to freeing the BDs.
 * <pre>
 *
 *         XAxiCdma_BdRingAlloc()                   XAxiCdma_BdRingToHw()
 * Free ------------------------> Pre-process ----------------------> Hardware
 *                                                                    |
 *  /|\                                                               |
 *   |   XAxiCdma_BdRingFree()                XAxiCdma_BdRingFromHw() |
 *   +--------------------------- Post-process <----------------------+
 *
 * </pre>
 *
 * The second diagram shows when a DMA transfer is to be cancelled before
 * enqueuing to the hardware, application can return the requested BDs to the
 * free group using XAxiCdma_BdRingUnAlloc().
 * <pre>
 *
 *         XAxiCdma_BdRingUnAlloc()
 *   Free <----------------------- Pre-process
 *
 * </pre>
 *
 * <b>Physical/Virtual Addresses</b>
 *
 * Addresses for the transfer buffers are physical addresses.
 *
 * For SG transfers, the next BD pointer in a BD is also a physical address.
 *
 * However, application's reference to a BD and to the transfer buffers are
 * through virtual addresses.
 *
 * The application is responsible to translate the virtual addresses of its
 * transfer buffers to physical addresses before handing them to the driver.
 *
 * For systems where MMU is not used, or MMU is a direct mapping, then the
 * physical address and the virtual address are the same.
 *
 * <b>Cache Coherency</b>
 *
 * To prevent cache and memory inconsistency:
 *  - Flush the transmit buffer range before the transfer
 *  - Invalidate the receive buffer range before passing it to the hardware and
 *    before passing it to the application
 *
 * For SG transfers:
 *  - Flush the BDs once the preparation setup is done
 *  - Invalidate the memory region for BDs when BDs are retrieved from the
 *    hardware.
 *
 * <b>BD alignment for SG Transfers</b>
 *
 * The hardware has requirement for the minimum alignment of the BDs,
 * XAXICDMA_BD_MINIMUM_ALIGNMENT. It is OK to have an alignment larger than the
 * required minimum alignment, however, it must be multiple of the minimum
 * alignment. The alignment is passed into XAxiCdma_BdRingCreate().
 *
 * <b>Error Handling</b>
 *
 * The hardware halts upon all error conditions. The driver will reset the
 * hardware once the error occurs.
 *
 * The IrqMask argument in the callback function notifies the application about
 * error conditions for the transfer.
 *
 * <b>Mutual Exclusion</b>
 *
 * The driver does not provide mutual exclusion mechanisms, it is up to the
 * upper layer to handle this.
 *
 * <b>Hardware Defaults & Exclusive Use</b>
 *
 * The hardware is in the following condition on start or after a reset:
 *
 * - All interrupts are disabled.
 * - The engine is in simple mode.
 * - Interrupt coalescing counter is one.
 * - Delay counter is 0.
 *
 * The driver has exclusive use of the hardware registers and BDs. Accessing
 * the hardware registers or the BDs should always go through the driver API
 * functions.
 *
 * <b>Hardware Features That User Should Be Aware of</b>
 *
 * For performance reasons, the driver does not check the submission of
 * transfers during run time. It is the user's responsibility to submit
 * approrpiate transfers to the hardware. The following hardware features
 * should be considerred when submitting a transfer:
 *
 *  . Whether the hardware supports unaligned transfers, reflected through
 * C_INCLUDE_DRE in system.mhs file. Submitting unaligned transfers while the
 * hardware does not support it, causes errors upon transfer submission.
 * Aligned transfer is in respect to word length, and word length is defined
 * through the building parameter XPAR_AXI_CDMA_0_M_AXI_DATA_WIDTH.
 *
 *  . Memory range of the transfer addresses. Transfer data to executable
 * memory can crash the system.
 *
 *  . Lite mode. To save hardware resources (drastically), you may select
 * "lite" mode build of the hardware. However, with lite mode, the following
 * features are _not_ supported:
 *    - Cross page boundary transfer. Each transfer must be restrictly inside
 *      one page; otherwise, slave error occurs.
 *    - Unaligned transfer.
 *    - Data width larger than 64 bit
 *    - Maximum transfer length each time is limited to data_width * burst_len
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 *  . Updated the debug print on type casting to avoid warnings on u32. Cast
 *    u32 to (unsigned int) to use the %x format.
 *
 * Ver   Who  Date     Changes
 * ----- ---- -------- -------------------------------------------------------
 * 1.00a jz   07/08/10 First release
 * 2.01a rkv  01/25/11 Added TCL script to generate Test App code for peripheral
 *		       tests.
 * 		       Replaced with "\r\n" in place on "\n\r" in printf
 *		       statements. Made some minor modifications for Doxygen
 * 2.02a srt  01/18/13 Added support for Key Hole feature (CR: 687217).
 *		       Updated DDR base address for IPI designs (CR 703656).
 * 2.03a srt  04/13/13 Removed Warnings (CR 705006).
 * 		       Added logic to check if DDR is present in the test app
 *		       tcl file. (CR 700806)
 * 3.0   adk  19/12/13 Updated as per the New Tcl API's
 * 4.0	 adk  27/07/15 Added support for 64-bit Addressing.
 * 4.1   sk   11/10/15 Used UINTPTR instead of u32 for Baseaddress CR# 867425.
 *                     Changed the prototype of XAxiCdma_CfgInitialize API.
 * 4.3   mi   09/21/16 Fixed compilation warnings.
 *       ms   01/22/17 Modified xil_printf statement in main function for all
 *            examples to ensure that "Successfully ran" and "Failed" strings
 *            are available in all examples. This is a fix for CR-965028.
 *       ms   03/17/17 Added readme.txt file in examples folder for doxygen
 *                     generation.
 *       ms   04/05/17 Modified Comment lines in functions of axicdma
 *                     examples to recognize it as documentation block
 *                     for doxygen generation of examples.
 * </pre>
 *****************************************************************************/

#ifndef XAXICDMA_H_    /* prevent circular inclusions */
#define XAXICDMA_H_

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/
#include "xaxicdma_bd.h"

#ifdef __MICROBLAZE__
#include "xenv.h"
#else
#include <string.h>
#include "xil_cache.h"
#endif

/************************** Constant Definitions *****************************/
#define XAXICDMA_COALESCE_NO_CHANGE  0xFFFFFFFF
#define XAXICDMA_ALL_BDS             0x7FFFFFFF /* 2147 Million */

/* Constants for engine mode: simple/SG
 */
#define XAXICDMA_SG_MODE        1
#define XAXICDMA_SIMPLE_MODE    2

/* Maximum active SG interrupt handler this driver can manage
 *
 * The limitation comes from the interrupt handler. It is now one interrupt
 * handler for one transfer. It is possible to simplify, as in most use cases,
 * to have one interrupt handler for all SG transfers
 */
#define XAXICDMA_MAXIMUM_MAX_HANDLER 20

/* Constants of KeyHole feature selection: Write/Read
 */
#define XAXICDMA_KEYHOLE_READ	0
#define XAXICDMA_KEYHOLE_WRITE	1

/**************************** Type Definitions *******************************/

/**
 * @name Call Back function
 *
 * If interrupt is enabled, and the application wants to be notified about the
 * completion of a transfer, the application should register its call back
 * function to the driver.
 *
 * The call back function is registered through the transfer submission.
 *
 * @param CallBackRef is the call back reference passed in by application. A
 *        NULL pointer is acceptable.
 *
 * @param IrqMask is the interrupt mask regarding this completion
 * @param NumBdPtr is the pointer to number of BDs this handler should handle,
 *        for simple transfer, it is ignored.
 */
typedef void (*XAxiCdma_CallBackFn)(void *CallBackRef, u32 IrqMask,
    int *NumBdPtr);

/**
 * @name XAxiCdma_IntrHandlerList
 *
 * Interrupt handler list for scatter gather transfers
 *
 * @{
 */
typedef struct {
	XAxiCdma_CallBackFn CallBackFn; /**< Callback function */
	void *CallBackRef;              /**< Callback reference pointer */
	volatile int NumBds;            /**< Number of BDs this handler cares */
}XAxiCdma_IntrHandlerList;

/**
 * @name XAxiCdma_Config
 *
 * The hardware configuration structure, to be passed to the driver by the
 * user, or by tools if using XPS.
 *
 * @{
 */
typedef struct {
	u32 DeviceId;             /**< Unique ID of this instance */
	UINTPTR BaseAddress;          /**< Physical address of this instance */
	int HasDRE;               /**< Whether support unaligned transfers */
	int IsLite;               /**< Whether hardware build is lite mode */
	int DataWidth;            /**< Length of a word in bits */
	int BurstLen;             /**< Burst length */
	int AddrWidth;		  /**< Address Width */
}XAxiCdma_Config;

/**
 * @name XAxiCdma
 *
 * The structure to hold the driver instance data. An instance of this
 * structure corresponds to one DMA engine.
 *
 * @{
 */
typedef struct {
	UINTPTR BaseAddr;         /**< Virtual base address of the DMA engine */

	int Initialized;      /**< The driver/engine in working state */
	int SimpleOnlyBuild;  /**< Whether hardware is simple only build */
	int HasDRE;           /**< Whether support unaligned transfers */
	int IsLite;           /**< Whether hardware is in lite mode */
	int WordLength;       /**< Length of a word in bytes */
	int MaxTransLen;      /**< Length hardware supports */
	int SimpleNotDone;    /**< Flag that a simple transfer is ongoing */
	int SGWaiting;        /**< Flag that SG transfers are waiting */

	/* BD ring fields for SG transfer */
	UINTPTR FirstBdPhysAddr;  /**< Physical address of 1st BD in list */
	UINTPTR FirstBdAddr;      /**< Virtual address of 1st BD in list */
	UINTPTR LastBdAddr;       /**< Virtual address of last BD in the list */
	u32 BdRingTotalLen;   /**< Total size of ring in bytes */
	u32 BdSeparation;     /**< Distance between adjacent BDs in bytes */
	XAxiCdma_Bd *FreeBdHead;   /**< First BD in the free group */
	XAxiCdma_Bd *PreBdHead;    /**< First BD in the pre-work group */
	XAxiCdma_Bd *HwBdHead;     /**< First BD in the work group */
	XAxiCdma_Bd *HwBdTail;     /**< Last BD in the work group */
	XAxiCdma_Bd *PostBdHead;   /**< First BD in the post-work group */
	XAxiCdma_Bd *BdaRestart; /**< BD to load when hardware restarted */
	int FreeBdCnt;             /**< Number of allocatable BDs */
	int PreBdCnt;              /**< Number of BDs in pre-work group */
	int HwBdCnt;               /**< Number of BDs in work group */
	int PostBdCnt;             /**< Number of BDs in post-work group */
	int AllBdCnt;              /**< Total Number of BDs */

	/* Callback function for simple transfer*/
	XAxiCdma_CallBackFn SimpleCallBackFn; /**< Callback function for simple
                                               transfer */
	void *SimpleCallBackRef;       /**< Callback reference pointer */

	int SgHandlerHead;             /**< First active sg transfer handler */
	int SgHandlerTail;             /**< Last active sg transfer handler */
	XAxiCdma_IntrHandlerList Handlers[XAXICDMA_MAXIMUM_MAX_HANDLER];
	                               /**< List of interrupt handlers */
	int AddrWidth;		  /**< Address Width */

}XAxiCdma;
/* @} */

/***************** Macros (Inline Functions) Definitions *********************/

/*****************************************************************************/
/*
 * Macros to flush and invalidate cache for BDs should they be
 * located in cached memory. These macros may NOPs if the underlying
 * XCACHE_FLUSH_DCACHE_RANGE and XCACHE_INVALIDATE_DCACHE_RANGE macros are not
 * implemented or they do nothing.
 *****************************************************************************/
#ifdef __aarch64__
#define XAXICDMA_CACHE_FLUSH(BdPtr)
#define XAXICDMA_CACHE_INVALIDATE(BdPtr)
#elif __MICROBLAZE__
#ifdef XCACHE_FLUSH_DCACHE_RANGE
#define XAXICDMA_CACHE_FLUSH(BdPtr)               \
      XCACHE_FLUSH_DCACHE_RANGE((BdPtr), XAXICDMA_BD_HW_NUM_BYTES)
#else
#define XAXICDMA_CACHE_FLUSH(BdPtr)
#endif

#ifdef XCACHE_INVALIDATE_DCACHE_RANGE
#define XAXICDMA_CACHE_INVALIDATE(BdPtr)          \
      XCACHE_INVALIDATE_DCACHE_RANGE((BdPtr), XAXICDMA_BD_HW_NUM_BYTES)
#else
#define XAXICDMA_CACHE_INVALIDATE(BdPtr)
#endif

#else /* __MICROBLAZE__*/
#define XAXICDMA_CACHE_FLUSH(BdPtr)               \
	Xil_DCacheFlushRange((BdPtr), XAXICDMA_BD_HW_NUM_BYTES);

#define XAXICDMA_CACHE_INVALIDATE(BdPtr)          \
      Xil_DCacheInvalidateRange((BdPtr), XAXICDMA_BD_HW_NUM_BYTES)

#endif


/************************** Function Prototypes ******************************/

XAxiCdma_Config *XAxiCdma_LookupConfig(u32 DeviceId);

u32 XAxiCdma_CfgInitialize(XAxiCdma *InstancePtr, XAxiCdma_Config *CfgPtr,
        UINTPTR EffectiveAddr);
void XAxiCdma_Reset(XAxiCdma *InstancePtr);
int XAxiCdma_ResetIsDone(XAxiCdma *InstancePtr);
int XAxiCdma_IsBusy(XAxiCdma *InstancePtr);
int XAxiCdma_SetCoalesce(XAxiCdma *InstancePtr, u32 Counter, u32 Delay);
void XAxiCdma_GetCoalesce(XAxiCdma *InstancePtr, u32 *CounterPtr,
        u32 *DelayPtr);
u32 XAxiCdma_GetError(XAxiCdma *InstancePtr);
void XAxiCdma_IntrEnable(XAxiCdma *InstancePtr, u32 Mask);
u32 XAxiCdma_IntrGetEnabled(XAxiCdma *InstancePtr);
void XAxiCdma_IntrDisable(XAxiCdma *InstancePtr, u32 Mask);
void XAxiCdma_IntrHandler(void *HandlerRef);
u32 XAxiCdma_SimpleTransfer(XAxiCdma *InstancePtr, UINTPTR SrcAddr, UINTPTR DstAddr,
        int Length, XAxiCdma_CallBackFn SimpleCallBack, void *CallbackRef);
int XAxiCdma_SelectKeyHole(XAxiCdma *InstancePtr, u32 Direction, u32 Select);

/* BD ring API functions
 */
u32 XAxiCdma_BdRingCntCalc(u32 Alignment, u32 Bytes, UINTPTR BuffAddr);
u32 XAxiCdma_BdRingMemCalc(u32 Alignment, int NumBd);
u32 XAxiCdma_BdRingGetCnt(XAxiCdma *InstancePtr);
u32 XAxiCdma_BdRingGetFreeCnt(XAxiCdma *InstancePtr);
void XAxiCdma_BdRingSnapShotCurrBd(XAxiCdma *InstancePtr);
XAxiCdma_Bd *XAxiCdma_BdRingGetCurrBd(XAxiCdma *InstancePtr);
XAxiCdma_Bd *XAxiCdma_BdRingNext(XAxiCdma *InstancePtr, XAxiCdma_Bd *BdPtr);
XAxiCdma_Bd *XAxiCdma_BdRingPrev(XAxiCdma *InstancePtr, XAxiCdma_Bd *BdPtr);
LONG XAxiCdma_BdRingCreate(XAxiCdma *InstancePtr, UINTPTR PhysAddr,
        UINTPTR VirtAddr, u32 Alignment, int BdCount);
LONG XAxiCdma_BdRingClone(XAxiCdma *InstancePtr, XAxiCdma_Bd * TemplateBdPtr);
LONG XAxiCdma_BdRingAlloc(XAxiCdma *InstancePtr, int NumBd,
	XAxiCdma_Bd ** BdSetPtr);
LONG XAxiCdma_BdRingUnAlloc(XAxiCdma *InstancePtr, int NumBd,
	XAxiCdma_Bd * BdSetPtr);
LONG XAxiCdma_BdRingToHw(XAxiCdma *InstancePtr, int NumBd,
        XAxiCdma_Bd * BdSetPtr, XAxiCdma_CallBackFn CallBack,
        void *CallBackRef);
u32 XAxiCdma_BdRingFromHw(XAxiCdma *InstancePtr, int BdLimit,
        XAxiCdma_Bd ** BdSetPtr);
u32 XAxiCdma_BdRingFree(XAxiCdma *InstancePtr, int NumBd,
        XAxiCdma_Bd * BdSetPtr);
void XAxiCdma_BdSetCurBdPtr(XAxiCdma *InstancePtr, UINTPTR CurBdPtr);
void XAxiCdma_BdSetTailBdPtr(XAxiCdma *InstancePtr, UINTPTR TailBdPtr);

/* Debug utility function
 */
void XAxiCdma_DumpRegisters(XAxiCdma *InstancePtr);

#ifdef __cplusplus
}
#endif

#endif    /* prevent circular inclusions */
/** @} */
