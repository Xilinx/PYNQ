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

    // Stop the VDMA core
    XAxiVdma_DmaStop(videoPtr->vdma, XAXIVDMA_WRITE);
    while(XAxiVdma_IsBusy(videoPtr->vdma, XAXIVDMA_WRITE));

    /*
     * This might actually be the better way to test if the core is halted, 
     * because IsBusy seems to check a bit that may no longer be supported 
     * in the core.
     */
    XAxiVdma_Reset(videoPtr->vdma, XAXIVDMA_WRITE);
    while(XAxiVdma_ResetNotDone(videoPtr->vdma, XAXIVDMA_WRITE));
    videoPtr->state = VIDEO_PAUSED;
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
    int Status;
    int i;

    // printf("Video start entered\n\r");
    VtcDetect(videoPtr);
    if(videoPtr->timing.VActiveVideo == 0 
       || videoPtr->timing.HActiveVideo == 0
       || videoPtr->state == VIDEO_DISCONNECTED){
        return XST_NO_DATA;
    }
    if (videoPtr->state == VIDEO_STREAMING)
        return XST_SUCCESS;
    /*
     * TODO: Consider conditionally disabling the detector, 
     * resetting the VDMA, and then re-enabling the detector.
     * Configure the VDMA to access a frame with the same dimensions as the
     * current mode.
     */
    videoPtr->vdmaConfig.VertSizeInput = videoPtr->timing.VActiveVideo;
    videoPtr->vdmaConfig.HoriSizeInput = videoPtr->timing.HActiveVideo * 3;
    videoPtr->vdmaConfig.FixedFrameStoreAddr = videoPtr->curFrame;
    
    /*
     *Also reset the stride and address values, in case the user 
     * manually changed them.
     */
    videoPtr->vdmaConfig.Stride = videoPtr->stride;
    for (i = 0; i < VIDEO_NUM_FRAMES; i++)
    {
        videoPtr->vdmaConfig.FrameStoreStartAddr[i] =  
                                (u32) cma_get_phy_addr(videoPtr->framePtr[i]);
    }
    videoPtr->vdmaConfig.EnableFrameCounter = 0;

    /*
     * Perform the VDMA driver calls required to start a transfer. 
     * Note that no data is actually transferred until the disp_ctrl core 
     * signals the VDMA core by pulsing fsync.
     */
    Status = XAxiVdma_DmaConfig(videoPtr->vdma, XAXIVDMA_WRITE, \
                                &(videoPtr->vdmaConfig));
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }
    
    Status = XAxiVdma_DmaSetBufferAddr(videoPtr->vdma, XAXIVDMA_WRITE, 
             videoPtr->vdmaConfig.FrameStoreStartAddr);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }
    
    Status = XAxiVdma_DmaStart(videoPtr->vdma, XAXIVDMA_WRITE);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }
    
    Status = XAxiVdma_StartParking(videoPtr->vdma, videoPtr->curFrame, \
                                   XAXIVDMA_WRITE);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

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
    int i;
    
    // Initialize all the fields in the VideoCapture struct
    videoPtr->curFrame = 0;
    for (i = 0; i < VIDEO_NUM_FRAMES; i++)
    {
        videoPtr->framePtr[i] = framePtr[i];
    }
    videoPtr->state = VIDEO_DISCONNECTED;
    videoPtr->stride = stride;
    videoPtr->vtcBaseAddress = (u32)vtcBaseAddress;
    XAxiVdma_Config vdmaCfg = Py_XAxiVdma_LookupConfig(vdmaDict);
    videoPtr->vdma = Py_XAxiVdma_CfgInitialize(&vdmaCfg);
    videoPtr->vtcIsInit = 0;
    videoPtr->startOnDetect = 1;
    
    // Initialize the VDMA Read configuration struct
    videoPtr->vdmaConfig.FrameDelay = 0;
    videoPtr->vdmaConfig.EnableCircularBuf = 1;
    videoPtr->vdmaConfig.EnableSync = 0;
    videoPtr->vdmaConfig.PointNum = 0;
    videoPtr->vdmaConfig.EnableFrameCounter = 0;

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
    struct timeval time_1, time_2;
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
    VtcDetect(videoPtr);

    return XST_SUCCESS;
}

/* ------------------------------------------------------------ */

/***    VideoChangeFrame(VideoCapture *dispPtr, u32 frameIndex)
**
**  Parameters:
**      dispPtr - Pointer to the initialized VideoCapture struct
**      frameIndex - Index of the framebuffer to change to (must
**                   be between 0 and (DISPLAY_NUM_FRAMES - 1))
**
**  Return Value: int
**      XST_SUCCESS if successful, XST_FAILURE otherwise
**
**  Errors:
**
**  Description:
**      Changes the frame currently being displayed.
**
*/

int VideoChangeFrame(VideoCapture *videoPtr, u32 frameIndex)
{
    int Status;

    videoPtr->curFrame = frameIndex;
    /*
     * If currently running, then the DMA needs to be told to start reading 
     * from the desired frame at the end of the current frame.
     */
    if (videoPtr->state == VIDEO_STREAMING)
    {
        Status = XAxiVdma_StartParking(videoPtr->vdma, videoPtr->curFrame, \
                                       XAXIVDMA_WRITE);
        if (Status != XST_SUCCESS)
        {
            return XST_FAILURE;
        }
    }

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
