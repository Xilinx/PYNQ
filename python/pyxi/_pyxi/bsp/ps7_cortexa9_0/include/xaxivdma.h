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
* @file xaxivdma.h
* @addtogroup axivdma_v6_0
* @{
* @details
*
* This is the Xilinx MVI AXI Video DMA device driver. The DMA engine transfers
* frames from the AXI Bus or to the AXI Bus. It is in the chain of video
* IPs, which process video frames.
*
* It supports the following features:
*  - Continuous transfers of video frames, AKA circular buffer mode
*  - Continuous transfers of one specific video frame, AKA park mode
*  - Optionally only transfer a certain amount of video frames
*  - Optionally transfer unaligned frame buffers
*
* An AXI Video DMA engine can have one or two channels. If configured as two
* channels, then one of the channels reads data from memory, and the other
* channel writes to the memory.
*
* For a full description of AXI Video DMA features, please see the hardware
* spec.
*
* The driver composes of three parts: initialization, start a DMA transfer, and
* interrupt handling.
*
* <b> Driver Initialization </b>
*
* To initialize the driver, the caller needs to pass a configuration structure
* to the driver. This configuration structure contains information about the
* hardware build.
*
* A caller can manually setup the configuration structure, or call
* XAxiVdma_LoopkupConfig().
*
* The sequence of initialization of the driver is:
*  1. XAxiVdma_LookupConfig() to get the configuration structure, or manually
*     setup the structure.
*  2. XAxiVdma_CfgInitialize() to initialize the driver & device.
*  3. XAxiVdma_SetFrmStore() to set the desired frame store number which
*     is optional.
*  4. If interrupt is desired:
*     - Set frame counter using XAxiVdma_SetFrameCounter()
*     - Set call back functions for each channel. There are two types of call
*       backfunctions: general and error
*     - Enable interrupts that the user cares about
*
* <b>Start a DMA Transaction </b>
*
* If you are using the driver API to start the transfer, then there are two
* ways to start a DMA transaction:
*
* 1. Invoke XAxiVdma_StartWriteFrame() or XAxiVdma_StartReadFrame() to start a
*    DMA operation, depending on the purpose of the transfer (Read or Write).
*
* 2. Or, call the phased functions as the following:
*    - Call XAxiVdma_DmaConfig() to set up a DMA operation configuration
*    - Call XAxiVdma_DmaSetBufferAddr() to set up the DMA buffers
*    - Call XAxiVdma_DmaStart() to kick off the DMA operation
*
* If you are writing your own functions to start the transfer, the order of
* setting up the hardware must be the following:
*
* - Do any processing or setting, but do not start the hardware, means do not
* set the RUN/STOP bit in the XAXIVDMA_CR_OFFSET register.
* - After any reset you need to do, write the head of your BD ring into the
* XAXIVDMA_CDESC_OFFSET register.
* - You can do other setup for the harware.
* - Start your hardware, by setting up the RUN/STOP bit in the
* XAXIVDMA_CR_OFFSET register.
* - You can do other setup for the hardware.
* - If you are done with all the setup, now write the tail of your BD ring to
* the XAXIVDMA_TDESC_OFFSET register to start the transfer.
*
* You can refer to XAxiVdma_ChannelStartTransfer() to see how this order is
* preserved there. The function is in xaxivdma_channel.c.
*
* Note a Read VDMA could work with one out of multiple write VDMA instances
* and vice versa. The PointNum in structure XAxiVdma_DmaSetup decides which
* VDMA instance this VDMA is working with.
*
* <b>Interrupt Handling </b>
*
* Each VDMA channel supports 2 kinds of interrupts:
* - General Interrupt: An interrupt other than error interrupt.
* - Error Interrupt: An error just happened.
*
* The driver does the interrupt handling, and dispatch to the user application
* through callback functions that user has registered. If there are no
* registered callback functions, then a stub callback function is called.
*
* Each channel has two interrupt callback functions. One for IOC and delay
* interrupt, or general interrupt; one for error interrupt.
*
* <b>Reset</b>
*
* Reset a DMA channel causes the channel enter the following state:
*
* - Interrupts are disabled
* - Coalescing threshold is one
* - Delay counter is 0
* - RUN/STOP bit low
* - Halted bit high
* - XAXIVDMA_CDESC_OFFSET register has 0
* - XAXIVDMA_TDESC_OFFSET register has 0
*
* If there is an active transfer going on when reset (or stop) is issued to
* the hardware, the current transfer will gracefully finish. For a maximum
* transfer length of (0x1FFF * 0xFFFF) bytes, on a 100 MHz system, it can take
* as long as 1.34 seconds, assuming that the system responds to DMA engine's
* requests quickly.
*
* To ensure that the hardware finishes the reset, please use
* XAxiVdma_ResetNotDone() to check for completion of the reset.
*
* To start a transfer after a reset, the following actions are the minimal
* requirement before setting RUN/STOP bit high to avoid crashing the system:
*
* - XAXIVDMA_CDESC_OFFSET register has a valid BD pointer, it should be the
* head of the BD ring.
* - XAXIVDMA_TDESC_OFFSET register has a valid BD pointer, it should be the
* tail of the BD ring.
*
* If you are using the driver API to start a transfer after a reset, then it
* should be fine.
*
* <b>Stop</b>
*
* Stop a channel using XAxiVDma_DmaStop() is similar to a reset, except the
* registers are kept intact.
*
* To start a transfer after a stop:
*
* - If there are error bits in the status register, then a reset is necessary.
* Please refer to the <b>Reset</b> section for more details on how to start a
* transfer after a reset.
* - If there are no error bits in the status register, then you can call
* XAxiVdma_DmaStart() to start the transfer again. Note that the transfer
* always starts from the first video frame.
*
* <b> Examples</b>
*
* We provide one example on how to use the AXI VDMA with AXI Video IPs. This
* example does not work by itself. To make it work, you must have two other
* Video IPs to connect to the VDMA. One of the Video IP does the write and the
* other does the read.
*
* <b>Cache Coherency</b>
*
* This driver does not handle any cache coherency for the data buffers.
* The application is responsible for handling cache coherency, if the cache
* is enabled.
*
* <b>Alignment</b>
*
* The VDMA supports any buffer alignment when DRE is enabled in the hardware
* configuration. It only supports word-aligned buffers otherwise. Note that
* "word" is defined by C_M_AXIS_MM2S_TDATA_WIDTH and C_S_AXIS_S2MM_TDATA_WIDTH
* for the read and write channel specifically.
*
* If the horizonal frame size is not word-aligned, then DRE must be enabled
* in the hardware. Otherwise, undefined results happen.
*
* <b>Address Translation</b>
*
* Buffer addresses for transfers are physical addresses. If the system does not
* use MMU, then physical and virtual addresses are the same.
*
* <b>API Change from PLB Video DMA</b>
*
* We try to keep the API as consistent with the PLB Video DMA driver as
* possible. However, due to hardware differences, some of the PLB video DMA
* driver APIs are changed or removed. Two API functions are added to the AXI
* DMA driver.
*
* For details on the API changes, please refer to xaxivdma_porting_guide.h.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a jz   08/16/10 First release
* 2.00a jz   12/10/10 Added support for direct register access mode, v3 core
* 2.01a jz   01/19/11 Added ability to re-assign BD addresses
*		      Replaced include xenv.h with string.h in xaxivdma_i.h
* 		      file.
* 2.01a	rkv  03/28/11 Added support for frame store register and
*                     XAxiVdma_ChannelInit API is changed.
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
* 4.02a srt  10/11/12 - XAxiVdma_SetFrmStore function changed to remove
*                       Reset logic after setting number of frame stores.
*			(CR 678734)
*		      - Changed Error bitmasks to support IP version 5.02a.
*			(CR 679959)
* 4.03a srt  01/18/13 - Updated logic of GenLockSourceSelect() & FsyncSrcSelect()
*                       APIs for newer versions of IP (CR: 691052).
*		      - Modified CfgInitialize() API to initialize
*			StreamWidth parameters and added TDATA_WIDTH parameters
*			to tcl file (CR 691866)
*		      - Updated DDR base address for IPI designs (CR 703656).
* 4.04a srt  03/03/13 - Support for the GenlockRepeat Control bit (Bit 15)
*                       added in the new version of IP v5.04 (CR: 691391)
*
*			  - Updated driver tcl, xaxivdma_g.c and  XAxiVdma_Config
*			structure in xaxivdma.h to import the relevant VDMA IP
*			DEBUG_INFO_* parameters into the driver.
*			This fixes CR# 703738.
* 4.05a srt  05/01/3  - Merged v4.03a driver with v4.04a driver.
*		             Driver v4.03a - Supports VDMA IPv5.04a XPS release
*		             Driver v4.04a - Supports VDMA IPv6.00a IPI release
*	                 The parameters C_ENABLE_DEBUG_* are only available in
*		         VDMA IPv6.00a. These parameters should be set to '1'
*		         for older versions of IP (XPS) and added this logic in
*		         the driver tcl file.
* 		      - Added unalignment checks for Hsize and Stride
*			(CR 710279)
* 4.06a srt  04/09/13 - Added support for the newly added S2MM_DMA_IRQ_MASK
*                       register (CR 734741)
* 5.0   adk  19/12/13 - Updated as per the New Tcl API's
* 5.1   adk  20/01/15  Added support for peripheral test. Created the self
*		       test example to include it on peripheral test's(CR#823144).
* 5.1   adk  29/01/15  Added the sefltest api (XAxiVdma_Selftest) to the driver source files
*                     (xaxivdma_selftest.c) and called this from the selftest example
* 6.0   vak  27/07/15  Added example for demonstarting triple buffer api.
* 6.0   vak  27/07/15  Added 64 bit addressing support to the driver.
* 6.0   vak  26/08/15  Added checks to align hsize and stride based on channel direction
*                      (read or write)(CR 874861)
*
* </pre>
*
******************************************************************************/

#ifndef XAXIVDMA_H_     /* Prevent circular inclusions */
#define XAXIVDMA_H_     /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xaxivdma_hw.h"
#include "xaxivdma_i.h"
#include "xstatus.h"
#include "xil_assert.h"


/************************** Constant Definitions *****************************/

/**
 * VDMA data transfer direction
 */
#define XAXIVDMA_WRITE       1        /**< DMA transfer into memory */
#define XAXIVDMA_READ        2        /**< DMA transfer from memory */

/**
 * Frame Sync Source Selection
 */
#define XAXIVDMA_CHAN_FSYNC		0
#define XAXIVDMA_CHAN_OTHER_FSYNC	1
#define XAXIVDMA_S2MM_TUSER_FSYNC	2

/**
 * GenLock Source Selection
 */
#define XAXIVDMA_EXTERNAL_GENLOCK	0
#define XAXIVDMA_INTERNAL_GENLOCK	1

/**
 * GenLock Mode Constants
 */
#define XAXIVDMA_GENLOCK_MASTER		0
#define XAXIVDMA_GENLOCK_SLAVE		1
#define XAXIVDMA_DYN_GENLOCK_MASTER	2
#define XAXIVDMA_DYN_GENLOCK_SLAVE	3

/**
 * Interrupt type for setting up callback
 */
#define XAXIVDMA_HANDLER_GENERAL   1  /**< Non-Error Interrupt Type */
#define XAXIVDMA_HANDLER_ERROR     2  /**< Error Interrupt Type */

/**
 * Flag to signal that device is ready to be used
 */
#define XAXIVDMA_DEVICE_READY      0x11111111

/**
 * Debug Configuration Parameter Constants (C_ENABLE_DEBUG_INFO_*)
 */
#define XAXIVDMA_ENABLE_DBG_THRESHOLD_REG	0x01
#define XAXIVDMA_ENABLE_DBG_FRMSTORE_REG	0x02
#define XAXIVDMA_ENABLE_DBG_FRM_CNTR	0x04
#define XAXIVDMA_ENABLE_DBG_DLY_CNTR	0x08
#define XAXIVDMA_ENABLE_DBG_ALL_FEATURES	0x0F

/* Defined for backward compatiblity.
 * This  is a typical DMA Internal Error, which on detection doesnt require a
 * reset (as opposed to other errors). So user on seeing this need only to
 * reinitialize channels.
 *
 */
#ifndef XST_VDMA_MISMATCH_ERROR
#define XST_VDMA_MISMATCH_ERROR 1430
#endif

/**************************** Type Definitions *******************************/

/*****************************************************************************/
/**
 * Callback type for general interrupts
 *
 * @param   CallBackRef is a callback reference passed in by the upper layer
 *          when setting the callback functions, and passed back to the
 *          upper layer when the callback is called.
 * @param   InterruptTypes indicates the detailed type(s) of the interrupt.
 *          Its value equals 'OR'ing one or more XAXIVDMA_IXR_* values defined
 *          in xaxivdma_hw.h
 *****************************************************************************/
typedef void (*XAxiVdma_CallBack) (void *CallBackRef, u32 InterruptTypes);

/*****************************************************************************/
/**
 * Callback type for Error interrupt.
 *
 * @param   CallBackRef is a callback reference passed in by the upper layer
 *          when setting the callback function, and it is passed back to the
 *          upper layer when the callback is called.
 * @param   ErrorMask is a bit mask indicating the cause of the error. Its
 *          value equals 'OR'ing one or more XAXIVDMA_IXR_* values defined in
 *          xaxivdma_hw.h
 *****************************************************************************/
typedef void (*XAxiVdma_ErrorCallBack) (void *CallBackRef, u32 ErrorMask);

/**
 * This typedef contains the hardware configuration information for a VDMA
 * device. Each VDMA device should have a configuration structure associated
 * with it.
 */
typedef struct {
    u16 DeviceId;         /**< DeviceId is the unique ID  of the device */
    UINTPTR BaseAddress;      /**< BaseAddress is the physical base address of the
                            *  device's registers */
    u16 MaxFrameStoreNum; /**< The maximum number of Frame Stores */
    int HasMm2S;          /**< Whether hw build has read channel */
    int HasMm2SDRE;       /**< Read channel supports unaligned transfer */
    int Mm2SWordLen;      /**< Read channel word length */
    int HasS2Mm;          /**< Whether hw build has write channel */
    int HasS2MmDRE;       /**< Write channel supports unaligned transfer */
    int S2MmWordLen;      /**< Write channel word length */
    int HasSG;            /**< Whether hardware has SG engine */
    int EnableVIDParamRead;
			  /**< Read Enable for video parameters in direct
			    *  register mode */
    int UseFsync;	  /**< DMA operations synchronized to Frame Sync */
    int FlushonFsync;	  /**< VDMA Transactions are flushed & channel states
			    *	reset on Frame Sync */
    int Mm2SBufDepth;	  /**< Depth of Read Channel Line Buffer FIFO */
    int S2MmBufDepth;	  /**< Depth of Write Channel Line Buffer FIFO */
    int Mm2SGenLock;	  /**< Mm2s Gen Lock Mode */
    int S2MmGenLock;	  /**< S2Mm Gen Lock Mode */
    int InternalGenLock;  /**< Internal Gen Lock */
    int S2MmSOF;	  /**< S2MM Start of Flag Enable */
    int Mm2SStreamWidth;  /**< MM2S TData Width */
    int S2MmStreamWidth;  /**< S2MM TData Width */
    int Mm2SThresRegEn;   /**< MM2S Threshold Register Enable Flag
							   This corresponds to C_ENABLE_DEBUG_INFO_1
							   configuration parameter */
    int Mm2SFrmStoreRegEn;/**< MM2S Frame Store Register Enable Flag
							   This corresponds to C_ENABLE_DEBUG_INFO_5
							   configuration parameter */
    int Mm2SDlyCntrEn;	  /**< MM2S Delay Counter (Control Reg) Enable Flag
							   This corresponds to C_ENABLE_DEBUG_INFO_6
							   configuration parameter */
    int Mm2SFrmCntrEn;    /**< MM2S Frame Counter (Control Reg) Enable Flag
							   This corresponds to C_ENABLE_DEBUG_INFO_7
							   configuration parameter */
    int S2MmThresRegEn;   /**< S2MM Threshold Register Enable Flag
							   This corresponds to C_ENABLE_DEBUG_INFO_9
							   configuration parameter */
    int S2MmFrmStoreRegEn;/**< S2MM Frame Store Register Enable Flag
							   This corresponds to C_ENABLE_DEBUG_INFO_13
							   configuration parameter */
    int S2MmDlyCntrEn;	  /**< S2MM Delay Counter (Control Reg) Enable Flag
							   This corresponds to C_ENABLE_DEBUG_INFO_14
							   configuration parameter */
    int S2MmFrmCntrEn;	  /**< S2MM Frame Counter (Control Reg) Enable Flag
						       This corresponds to C_ENABLE_DEBUG_INFO_15
							   configuration parameter */
    int EnableAllDbgFeatures;/**< Enable all Debug features
						       This corresponds to C_ENABLE_DEBUG_ALL
							   configuration parameter */
	int AddrWidth;		  /**< Address Width */
} XAxiVdma_Config;

/**
 * The XAxiVdma_DmaSetup structure contains all the necessary information to
 * start a frame write or read.
 *
 */
typedef struct {
    int VertSizeInput;      /**< Vertical size input */
    int HoriSizeInput;      /**< Horizontal size input */
    int Stride;             /**< Stride */
    int FrameDelay;         /**< Frame Delay */

    int EnableCircularBuf;  /**< Circular Buffer Mode? */
    int EnableSync;         /**< Gen-Lock Mode? */
    int PointNum;           /**< Master we synchronize with */
    int EnableFrameCounter; /**< Frame Counter Enable */
    UINTPTR FrameStoreStartAddr[XAXIVDMA_MAX_FRAMESTORE];
                            /**< Start Addresses of Frame Store Buffers. */
    int FixedFrameStoreAddr;/**< Fixed Frame Store Address index */
    int GenLockRepeat;      /**< Gen-Lock Repeat? */
} XAxiVdma_DmaSetup;

/**
 * The XAxiVdmaFrameCounter structure contains the interrupt threshold settings
 * for both the transmit and the receive channel.
 *
 */
typedef struct {
    u8 ReadFrameCount;      /**< Interrupt threshold for Receive */
    u8 ReadDelayTimerCount; /**< Delay timer threshold for receive */
    u8 WriteFrameCount;     /**< Interrupt threshold for transmit */
    u8 WriteDelayTimerCount;/**< Delay timer threshold for transmit */
} XAxiVdma_FrameCounter;

/**
 * Channel callback functions
 */
typedef struct {
    XAxiVdma_CallBack CompletionCallBack; /**< Call back for completion intr */
    void *CompletionRef;                  /**< Call back ref */

    XAxiVdma_ErrorCallBack ErrCallBack;   /**< Call back for error intr */
    void *ErrRef;                         /**< Call back ref */
} XAxiVdma_ChannelCallBack;

/**
 * The XAxiVdma driver instance data.
 */
typedef struct {
    UINTPTR BaseAddr;                   /**< Memory address for this device */
    int HasSG;                      /**< Whether hardware has SG engine */
    int IsReady;                    /**< Whether driver is initialized */

    int MaxNumFrames;                /**< Number of frames to work on */
    int HasMm2S;                    /**< Whether hw build has read channel */
    int HasMm2SDRE;                 /**< Whether read channel has DRE */
    int HasS2Mm;                    /**< Whether hw build has write channel */
    int HasS2MmDRE;                 /**< Whether write channel has DRE */
    int EnableVIDParamRead;	    /**< Read Enable for video parameters in
				      *  direct register mode */
    int UseFsync;       	    /**< DMA operations synchronized to
				      * Frame Sync */
    int InternalGenLock;  	    /**< Internal Gen Lock */
    XAxiVdma_ChannelCallBack ReadCallBack;  /**< Call back for read channel */
    XAxiVdma_ChannelCallBack WriteCallBack; /**< Call back for write channel */

    XAxiVdma_Channel ReadChannel;  /**< Channel to read from memory */
    XAxiVdma_Channel WriteChannel; /**< Channel to write to memory */
	int AddrWidth;		  /**< Address Width */
} XAxiVdma;


/************************** Function Prototypes ******************************/
/* Initialization */
XAxiVdma_Config *XAxiVdma_LookupConfig(u16 DeviceId);

int XAxiVdma_CfgInitialize(XAxiVdma *InstancePtr, XAxiVdma_Config *CfgPtr,
					u32 EffectiveAddr);

/* Engine and channel operations */
void XAxiVdma_Reset(XAxiVdma *InstancePtr, u16 Direction);
int XAxiVdma_ResetNotDone(XAxiVdma *InstancePtr, u16 Direction);
int XAxiVdma_IsBusy(XAxiVdma *InstancePtr, u16 Direction);
u32 XAxiVdma_CurrFrameStore(XAxiVdma *InstancePtr, u16 Direction);
u32 XAxiVdma_GetVersion(XAxiVdma *InstancePtr);
u32 XAxiVdma_GetStatus(XAxiVdma *InstancePtr, u16 Direction);
int XAxiVdma_SetLineBufThreshold(XAxiVdma *InstancePtr, int LineBufThreshold,
	u16 Direction);
int XAxiVdma_StartParking(XAxiVdma *InstancePtr, int FrameIndex,
         u16 Direction);
void XAxiVdma_StopParking(XAxiVdma *InstancePtr, u16 Direction);
void XAxiVdma_StartFrmCntEnable(XAxiVdma *InstancePtr, u16 Direction);

void XAxiVdma_IntrEnable(XAxiVdma *InstancePtr, u32 IntrType, u16 Direction);
void XAxiVdma_IntrDisable(XAxiVdma *InstancePtr, u32 IntrType ,u16 Direction);
u32 XAxiVdma_IntrGetPending(XAxiVdma *InstancePtr, u16 Direction);
void XAxiVdma_IntrClear(XAxiVdma *InstancePtr, u32 IntrType ,u16 Direction);

int XAxiVdma_SetBdAddrs(XAxiVdma *InstancePtr, u32 BdAddrPhys, u32 BdAddrVirt,
         int NumBds, u16 Direction);

XAxiVdma_Channel *XAxiVdma_GetChannel(XAxiVdma *InstancePtr, u16 Direction);
int XAxiVdma_SetFrmStore(XAxiVdma *InstancePtr, u8 FrmStoreNum, u16 Direction);
void XAxiVdma_GetFrmStore(XAxiVdma *InstancePtr, u8 *FrmStoreNum,
								u16 Direction);
int XAxiVdma_FsyncSrcSelect(XAxiVdma *InstancePtr, u32 Source,
                                u16 Direction);
int XAxiVdma_GenLockSourceSelect(XAxiVdma *InstancePtr, u32 Source,
                                        u16 Direction);
int XAxiVdma_GetDmaChannelErrors(XAxiVdma *InstancePtr, u16 Direction);
int XAxiVdma_ClearDmaChannelErrors(XAxiVdma *InstancePtr, u16 Direction,
					u32 ErrorMask);
int XAxiVdma_MaskS2MMErrIntr(XAxiVdma *InstancePtr, u32 ErrorMask,
                                        u16 Direction);

/* Transfers */
int XAxiVdma_StartWriteFrame(XAxiVdma *InstancePtr,
        XAxiVdma_DmaSetup *DmaConfigPtr);
int XAxiVdma_StartReadFrame(XAxiVdma *InstancePtr,
        XAxiVdma_DmaSetup *DmaConfigPtr);

int XAxiVdma_DmaConfig(XAxiVdma *InstancePtr, u16 Direction,
        XAxiVdma_DmaSetup *DmaConfigPtr);
int XAxiVdma_DmaSetBufferAddr(XAxiVdma *InstancePtr, u16 Direction,
        UINTPTR *BufferAddrSet);
int XAxiVdma_DmaStart(XAxiVdma *InstancePtr, u16 Direction);
void XAxiVdma_DmaStop(XAxiVdma *InstancePtr, u16 Direction);
void XAxiVdma_DmaRegisterDump(XAxiVdma *InstancePtr, u16 Direction);

int XAxiVdma_SetFrameCounter(XAxiVdma *InstancePtr,
        XAxiVdma_FrameCounter *FrameCounterCfgPtr);
void XAxiVdma_GetFrameCounter(XAxiVdma *InstancePtr,
         XAxiVdma_FrameCounter *FrameCounterCfgPtr);

/*
 * Interrupt related functions in xaxivdma_intr.c
 */
void XAxiVdma_ReadIntrHandler(void * InstancePtr);
void XAxiVdma_WriteIntrHandler(void * InstancePtr);
int XAxiVdma_SetCallBack(XAxiVdma * InstancePtr, u32 HandlerType,
        void *CallBackFunc, void *CallBackRef, u16 Direction);
int XAxiVdma_Selftest(XAxiVdma * InstancePtr);

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
