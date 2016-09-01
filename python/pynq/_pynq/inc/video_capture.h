/************************************************************************/
/*                                                                      */
/*  display_ctrl.h  --  Digilent Display Controller Driver              */
/*                                                                      */
/************************************************************************/
/*  Author: Sam Bobrowicz                                               */
/*  Copyright 2014, Digilent Inc.                                       */
/************************************************************************/
/*  Module Description:                                                 */
/*                                                                      */
/*      This module provides an easy to use API for controlling the     */
/*      Digilent display controller core (axi_dispctrl). It supports    */
/*      run-time resolution setting and seamless framebuffer-swapping   */
/*      for tear-free animation.                                        */
/*                                                                      */
/*      To use this driver, you must have an axi_dispctrl and axi_vdma  */
/*      core present in your system. For information on how to properly */
/*      configure these cores within your design, refer to the          */
/*      axi_dispctrl data sheet accessible from Vivado and XPS.         */
/*                                                                      */
/*      The following steps should be followed to use this driver:      */
/*      1) Create a DisplayCtrl object and pass a pointer to it to      */
/*         DisplayInitialize.                                           */
/*      2) Call DisplaySetMode to set the desired mode                  */
/*      3) Call DisplayStart to begin outputting data to the display    */
/*      4) To create a seamless animation, draw the next image to a     */
/*         framebuffer currently not being displayed. Then call         */
/*         DisplayChangeFrame to begin displaying that frame.           */
/*         Repeat as needed, only ever modifying inactive frames.       */
/*      5) To change the resolution, call DisplaySetMode, followed by   */
/*         DisplayStart again.                                          */
/*                                                                      */
/*      This module contains code from the Xilinx Demo titled           */
/*      "xiicps_polled_master_example.c." Xilinx XAPP888 was also       */
/*      referenced for information on reconfiguring the MMCM or PLL.    */
/*      Note that functions beginning with "DisplayClk" are used        */
/*      internally for this purpose and should not need to be called    */
/*      externally.                                                     */
/*                                                                      */
/************************************************************************/
/*  Revision History:                                                   */
/*                                                                      */
/*      02/20/2014(SamB): Created                                       */
/*      11/24/2015(GN): Modified for MicroPython                        */
/*      01/26/2016(GN): Modified for CPython                            */
/*      08/31/2016(YRQ): Added license header                           */
/*                                                                      */
/************************************************************************/

#ifndef VIDEO_CAPTURE_H_
#define VIDEO_CAPTURE_H_

/* ------------------------------------------------------------ */
/*              Include File Definitions                        */
/* ------------------------------------------------------------ */
#include <Python.h>
#include "xil_types.h"
#include "xaxivdma.h"
#include "xvtc.h"
#include "xgpio.h"
#include "py_xaxivdma.h"
#include "py_xvtc.h"
#include "py_xgpio.h"

/* ------------------------------------------------------------ */
/*                  Miscellaneous Declarations                  */
/* ------------------------------------------------------------ */

/*
 * This driver currently supports 3 frames.
 */
#define VIDEO_NUM_FRAMES 3

/*
 * These constants define the pins that the HPD and pixel clock
 * locked signals are conneced to on the AXI GPIO core
 */
#define HPD_CHANNEL 1
#define HPD_MASK 0x1
#define LOCKED_CHANNEL 2
#define LOCKED_MASK 0x1

/*
 * #ifdef XPAR_INTC_0_DEVICE_ID
 * #include "xintc.h"
 * #else
 * #include "xscugic.h"
 * #endif
 * #ifdef XPAR_INTC_0_DEVICE_ID
 * #define INTC_DEVICE_ID   XPAR_INTC_0_DEVICE_ID
 * #define INTC     XIntc
 * #define INTC_HANDLER XIntc_InterruptHandler
 * #else
 * #define INTC_DEVICE_ID   XPAR_SCUGIC_SINGLE_DEVICE_ID
 * #define INTC     XScuGic
 * #define INTC_HANDLER XScuGic_InterruptHandler
 * #endif
 */

/* ------------------------------------------------------------ */
/*                  General Type Declarations                   */
/* ------------------------------------------------------------ */

typedef enum {
    VIDEO_DISCONNECTED = 0,
    VIDEO_STREAMING = 1,
    VIDEO_PAUSED = 2
} VideoState;

typedef struct {
    XAxiVdma *vdma; //VDMA driver struct
    XAxiVdma_DmaSetup vdmaConfig; //VDMA channel configuration
    XVtc vtc; //VTC driver struct
    XVtc_Timing timing;
    u8 *framePtr[VIDEO_NUM_FRAMES]; // Array of pointers to the framebuffers
    u32 stride; // The line stride of the framebuffers, in bytes
    u32 curFrame; // Current frame being displayed
    XGpio *gpio; // XGPIO driver struct 
    u32 vtcBaseAddress; // Device BaseAddress of VTC core in xparameters.h
    int vtcIsInit; // flag indicating whether the VDMA was initialized
    int startOnDetect; // flag indicating whether VDMA starts by interrupt
    VideoState state; // Indicates if the Display is currently running
    /*
     * following codes retired
     * INTC *intc; // Interrupt controller driver struct
     *  u32 gpioInterruptId;
     *  u32 vtcInterruptId;
     */
} VideoCapture;

/* ------------------------------------------------------------ */
/*                  Variable Declarations                       */
/* ------------------------------------------------------------ */


/* ------------------------------------------------------------ */
/*                  Procedure Declarations                      */
/* ------------------------------------------------------------ */

int VideoStop(VideoCapture *videoPtr);
int VideoStart(VideoCapture *videoPtr);
int VideoInitialize(VideoCapture *videoPtr, PyObject *vdmaDict, 
                    PyObject *gpioDict, unsigned int vtcBaseAddress, 
                    u8 *framePtr[VIDEO_NUM_FRAMES], u32 stride,
                    unsigned int init_timeout);
int VideoChangeFrame(VideoCapture *videoPtr, u32 frameIndex);

//void GpioIsr(void *InstancePtr);
//void VtcIsr(void *InstancePtr, u32 pendingIrpt);
//void VtcDetIsr(void *InstancePtr, u32 pendingIrpt);
//int SetupInterruptSystem(VideoCapture *videoPtr);
void VtcDetect(VideoCapture *videoPtr);

/* ------------------------------------------------------------ */

/************************************************************************/

#endif /* VIDEO_CAPTURE_H_ */
