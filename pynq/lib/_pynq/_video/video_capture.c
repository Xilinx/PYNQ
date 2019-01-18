/************************************************************************/
/*                                                                      */
/*  display_ctrl.c  --  Digilent Display Controller Driver              */
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
/*      1) Create a VideoCapture object and pass a pointer to it to     */
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
/*      12/01/2015(GN): Modified for MicroPython                        */
/*      01/27/2016(GN): Modified for CPython                            */
/*      08/31/2016(YRQ): Adjusted format                                */
/*      09/01/2016(beja): timout adjustable & in seconds                */
/*                                                                      */
/************************************************************************/
/*
 * TODO: The VDMA debugging options can be enabled in Vivado IPI to enable
 *       the frame count functionality. This provides an interrupt that is
 *       triggered at the end of every frame, and also provides the ability
 *       to grab a single frame and have the VDMA core then automatically
 *       halt. We should evaluate if adding this functionality is worth 
 *       requiring users to enable the Debug mode of the VDMA core 
 *       (it requires some manual TCL commands to be run).
 */



/* ------------------------------------------------------------ */
/*              Include File Definitions                        */
/* ------------------------------------------------------------ */
#include <stdio.h>
#include "math.h"
#include "xil_io.h"
#include "video_capture.h"
#include <sys/time.h>

/* This function is taken from the GNU libc documentation */
static int timeval_subtract (struct timeval *result, struct timeval *x, struct timeval *y)
{
  /* Perform the carry for the later subtraction by updating y. */
  if (x->tv_usec < y->tv_usec) {
    int nsec = (y->tv_usec - x->tv_usec) / 1000000 + 1;
    y->tv_usec -= 1000000 * nsec;
    y->tv_sec += nsec;
  }
  if (x->tv_usec - y->tv_usec > 1000000) {
    int nsec = (x->tv_usec - y->tv_usec) / 1000000;
    y->tv_usec += 1000000 * nsec;
    y->tv_sec -= nsec;
  }

  /* Compute the time remaining to wait.
     tv_usec is certainly positive. */
  result->tv_sec = x->tv_sec - y->tv_sec;
  result->tv_usec = x->tv_usec - y->tv_usec;

  /* Return 1 if result is negative. */
  return x->tv_sec < y->tv_sec;
}

/* ------------------------------------------------------------ */
/*              Procedure Definitions                           */
/* ------------------------------------------------------------ */

/***    DisplayStop(VideoCapture *dispPtr)
**
**  Parameters:
**      dispPtr - Pointer to the initialized VideoCapture struct
**
**  Return Value: int
**      XST_SUCCESS if successful.
**      XST_DMA_ERROR if an error was detected on the DMA channel. The
**          Display is still successfully stopped, and the error is
**          cleared so that subsequent DisplayStart calls will be
**          successful. This typically indicates insufficient bandwidth
**          on the AXI Memory-Map Interconnect (VDMA<->DDR)
**
**  Description:
**      Halts output to the display
**
*/
int VideoStop(VideoCapture *videoPtr)
{
    // If already stopped, do nothing
    if (videoPtr->state == VIDEO_PAUSED || \
        videoPtr->state == VIDEO_DISCONNECTED)
    {
        return XST_SUCCESS;
    }

    return XST_SUCCESS;
}
/* ------------------------------------------------------------ */

/***    VideoStart(VideoCapture *videoPtr)
**
**  Parameters:
**      videoPtr - Pointer to the initialized VideoCapture struct
**
**  Return Value: int
**      XST_SUCCESS if successful, XST_FAILURE otherwise
**
**  Errors:
**
**  Description:
**      Starts the Video.
**
*/
int VideoStart(VideoCapture *videoPtr)
{
    VtcDetect(videoPtr);
    if(videoPtr->timing.VActiveVideo == 0 
       || videoPtr->timing.HActiveVideo == 0
       || videoPtr->state == VIDEO_DISCONNECTED){
        return XST_NO_DATA;
    }
    if (videoPtr->state == VIDEO_STREAMING)
        return XST_SUCCESS;

    videoPtr->state = VIDEO_STREAMING;

    return XST_SUCCESS;
}

/* ------------------------------------------------------------ */

/*
**  int VideoInitialize(VideoCapture *videoPtr, PyObject *vdmaDict, 
**                      PyObject *gpioDict, unsigned int vtcBaseAddress, 
**                      u8 *framePtr[VIDEO_NUM_FRAMES], u32 stride)
**
**  Parameters:
**      dispPtr - Pointer to the struct that will be initialized
**      vdmaDict - CPython dictionary for XAxiVdma
**      gpioDict - CPython dictionary for XGpio
**      vtcBaseAddress - BASE ADDRESS of the Video Timing Controller
**      framePtr - array of pointers to the framebuffers. The framebuffers 
**                 must be instantiated above this driver
**      stride - line stride of the framebuffers. This is the number of bytes 
**               between the start of one line and the start of another.
**      init_timeout - Timeout in seconds for initialization. signed init 
**                     because POSIX time_t is signed int. Check for negative
**                     values should be done in Python class.
**
**  Return Value: int
**      XST_SUCCESS if successful, XST_FAILURE otherwise
**
**  Errors:
**
**  Description:
**      Initializes the driver struct for use.
**
*/


int VideoInitialize(VideoCapture *videoPtr, PyObject *vdmaDict, 
                    PyObject *gpioDict, unsigned int vtcBaseAddress, 
                    u8 *framePtr[VIDEO_NUM_FRAMES], u32 stride, 
                    unsigned int init_timeout)
{
    // Initialize all the fields in the VideoCapture struct
    videoPtr->state = VIDEO_DISCONNECTED;
    videoPtr->vtcBaseAddress = (u32)vtcBaseAddress;
    // Initialize the GPIO driver
    XGpio_Config gpioConfig = Py_XGpio_LookupConfig(gpioDict);
    videoPtr->gpio = Py_XGpio_CfgInitialize(&gpioConfig);

    /*
     * Perform a self-test on the GPIO.  This is a minimal test and only
     * verifies that there is not any bus error when reading the data
     * register
     */
    XGpio_SelfTest(videoPtr->gpio);
    
    // Setup direction registers, and ensure HPD is low
    XGpio_DiscreteWrite(videoPtr->gpio, 1, 0);
    //Set HPD channel as output
    XGpio_SetDataDirection(videoPtr->gpio, 1, 0);
    //Set Locked channel as input
    XGpio_SetDataDirection(videoPtr->gpio, 2, 1);
    
    // Set HPD high, which will signal the HDMI source to begin transmitting.
    XGpio_DiscreteWrite(videoPtr->gpio, 1, 1);

    // from Gpio Isr
    u32 locked = 0, timeout = 0;
    struct timeval time_1, time_2, time_locked, time_reset;
    gettimeofday(&time_1, NULL);
    while (!locked && (signed int)timeout < init_timeout){
        locked = XGpio_DiscreteRead(videoPtr->gpio, 2); 
        gettimeofday(&time_2, NULL);
        timeout = time_2.tv_sec - time_1.tv_sec;
    }
    if((signed int)timeout >= init_timeout){
        return XST_FAILURE;
    }
    XVtc_Config vtcConfig = Py_XVtc_LookupConfig(videoPtr->vtcBaseAddress);
    videoPtr->vtc = *Py_XVtc_CfgInitialize(&vtcConfig);
    XVtc_SelfTest(&videoPtr->vtc);
    XVtc_RegUpdateEnable(&videoPtr->vtc);
    XVtc_EnableDetector(&videoPtr->vtc);
    videoPtr->vtcIsInit = 1;
    locked = 0;
    gettimeofday(&time_reset, NULL);
    while ((signed int)timeout < init_timeout){
        gettimeofday(&time_2, NULL);
        u32 islocked = CaptureLocked(videoPtr);
        if (islocked) {
            if (locked) {
                /* Lock is currently stable - if stable for 1 second then exit*/
                struct timeval diff;
                timeval_subtract(&diff, &time_2, &time_locked);
                if (diff.tv_sec > 0) break;
            } else {
                /* First time that the system has locked on this iteration */
                time_locked = time_2;
                /* Reset the reset timer as well as the VTC is working */
                time_reset = time_2;
                locked = islocked;
            } 
        } else {
            if (locked) {
                locked = 0;
            } /*else {
                struct timeval diff;
                timeval_subtract(&diff, &time_2, &time_reset);
                if (diff.tv_sec > 4) {
                    // Reset the VTC if it hasn't locked in 5 seconds
                    XVtc_Reset(&videoPtr->vtc);
                    while (XVtc_ReadReg(videoPtr->vtc.Config.BaseAddress, XVTC_CTL_OFFSET) & XVTC_CTL_RESET_MASK);
                    XVtc_RegUpdateEnable(&videoPtr->vtc);
                    XVtc_EnableDetector(&videoPtr->vtc);
                    time_reset = time_2;
                }
            }*/
        }
        timeout = time_2.tv_sec - time_1.tv_sec;
    }
    if (!locked) {
        return XST_FAILURE;
    }
    VtcDetect(videoPtr);

    return XST_SUCCESS;
}


/****************************************************************************/
/**
* This function sets up the interrupt system for the example.  The processing
* contained in this funtion assumes the hardware system was built with
* and interrupt controller.
*
* @param    None.
*
* @return   A status indicating XST_SUCCESS or a value that is contained in
*       xstatus.h.
*
* @note     None.
*
*****************************************************************************/
void VtcDetect(VideoCapture *videoPtr){
        XVtc_GetDetectorTiming(&videoPtr->vtc,&videoPtr->timing);
       
        if(videoPtr->timing.VActiveVideo == 0 || \
            videoPtr->timing.HActiveVideo == 0)
        {
            if(videoPtr->state == VIDEO_DISCONNECTED)
            {
                videoPtr->state = VIDEO_PAUSED;
            }
        }
}

/************************************************************************/

int CaptureLocked(VideoCapture *videoPtr) {
	return ((XVtc_ReadReg(videoPtr->vtc.Config.BaseAddress, XVTC_DTSTAT_OFFSET)) & XVTC_STAT_LOCKED_MASK) != 0;
}

int CaptureLockLost(VideoCapture *videoPtr) {
	return (XVtc_ReadReg(videoPtr->vtc.Config.BaseAddress, XVTC_ISR_OFFSET) & XVTC_IXR_LOL_MASK) != 0;
}
