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
/*      12/01/2015(gnatale@xilinx.copm): Modified for MicroPython       */
/*      01/27/2016(gnatale@xilinx.copm): Modified for CPython           */
/*                                                                      */
/************************************************************************/
/*
 * TODO: The VDMA debugging options can be enabled in Vivado IPI to enable
 *       the frame count functionality. This provides an interrupt that is
 *       triggered at the end of every frame, and also provides the ability
 *       to grab a single frame and have the VDMA core then automatically
 *       halt. We should evaluate if adding this functionality is worth requiring
 *       users to enable the Debug mode of the VDMA core (it requires some
 *       manual TCL commands to be run).
 */



/* ------------------------------------------------------------ */
/*              Include File Definitions                        */
/* ------------------------------------------------------------ */
#include <stdio.h>
#include "math.h"
#include "xil_io.h"

#include "video_capture.h"

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

    /*
     * If already stopped, do nothing
     */
    if (videoPtr->state == VIDEO_PAUSED || videoPtr->state == VIDEO_DISCONNECTED)
    {
        return XST_SUCCESS;
    }

    /*
     * Stop the VDMA core
     */
    XAxiVdma_DmaStop(videoPtr->vdma, XAXIVDMA_WRITE);
    while(XAxiVdma_IsBusy(videoPtr->vdma, XAXIVDMA_WRITE));

    /*
     * This might actually be the better way to test if the core is halted, because
     * IsBusy seems to check a bit that may no longer be supported in the core.
     */
//  while(!(XAxiVdma_GetStatus(videoPtr->vdma, XAXIVDMA_WRITE) & XAXIVDMA_SR_HALTED_MASK));

    XAxiVdma_Reset(videoPtr->vdma, XAXIVDMA_WRITE);
    while(XAxiVdma_ResetNotDone(videoPtr->vdma, XAXIVDMA_WRITE));
    videoPtr->state = VIDEO_PAUSED;

//  dmaErr = XAxiVdma_GetDmaChannelErrors(videoPtr->vdma, XAXIVDMA_WRITE);
//  if (dmaErr)
//  {
//      printf("Clearing DMA errors...0X%X\r\n", dmaErr);
//      XAxiVdma_ClearDmaChannelErrors(videoPtr->vdma, XAXIVDMA_WRITE, 0xFFFFFFFF);
//      return XST_DMA_ERROR;
//  }

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
            PyErr_Format(PyExc_SystemError, "Please connect to a valid video \
                source before starting.\n The cable might be disconnected or \
                some previous errors prevent the VTC to properly detect the \
                source resolution.\n");
        return XST_NO_DATA;
    }
    if (videoPtr->state == VIDEO_STREAMING)
        return XST_SUCCESS;
    //TODO: Consider conditionally disabling the detector, resetting the VDMA, and then re-enabling the detector here
    /*
     * Configure the VDMA to access a frame with the same dimensions as the
     * current mode
     */
    videoPtr->vdmaConfig.VertSizeInput = videoPtr->timing.VActiveVideo;
    videoPtr->vdmaConfig.HoriSizeInput = videoPtr->timing.HActiveVideo * 3;
    videoPtr->vdmaConfig.FixedFrameStoreAddr = videoPtr->curFrame;
    /*
     *Also reset the stride and address values, in case the user manually changed them
     */
    videoPtr->vdmaConfig.Stride = videoPtr->stride;
    for (i = 0; i < VIDEO_NUM_FRAMES; i++)
    {
        videoPtr->vdmaConfig.FrameStoreStartAddr[i] =  
                                (u32) cma_get_phy_addr(videoPtr->framePtr[i]);
    }
    videoPtr->vdmaConfig.EnableFrameCounter = 0;

    /*
     * Perform the VDMA driver calls required to start a transfer. Note that no data is actually
     * transferred until the disp_ctrl core signals the VDMA core by pulsing fsync.
     */

    // printf("vdma config\n\r");
    Status = XAxiVdma_DmaConfig(videoPtr->vdma, XAXIVDMA_WRITE, &(videoPtr->vdmaConfig));
    if (Status != XST_SUCCESS)
    {
        printf("Write channel config failed %d\r\n", Status);
        return XST_FAILURE;
    }
    // printf("vdma setbuffer\n\r");
    Status = XAxiVdma_DmaSetBufferAddr(videoPtr->vdma, XAXIVDMA_WRITE, 
             videoPtr->vdmaConfig.FrameStoreStartAddr);
    if (Status != XST_SUCCESS)
    {
        printf("Write channel set buffer address failed %d\r\n", Status);
        return XST_FAILURE;
    }
    // printf("vdma start\n\r");
    Status = XAxiVdma_DmaStart(videoPtr->vdma, XAXIVDMA_WRITE);
    if (Status != XST_SUCCESS)
    {
        printf("Start Write transfer failed %d\r\n", Status);
        return XST_FAILURE;
    }
    Status = XAxiVdma_StartParking(videoPtr->vdma, videoPtr->curFrame, XAXIVDMA_WRITE);
    if (Status != XST_SUCCESS)
    {
        printf("Unable to park the Write channel %d\r\n", Status);
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
**      framePtr - array of pointers to the framebuffers. The framebuffers must be instantiated above this driver
**      stride - line stride of the framebuffers. This is the number of bytes between the start of one line and the start of another.
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
                    u8 *framePtr[VIDEO_NUM_FRAMES], u32 stride)
{
    //int Status;
    int i;

    /*
     * Initialize all the fields in the VideoCapture struct
     */
    videoPtr->curFrame = 0;
    for (i = 0; i < VIDEO_NUM_FRAMES; i++)
    {
        videoPtr->framePtr[i] = framePtr[i];
    }
    videoPtr->state = VIDEO_DISCONNECTED;
    videoPtr->stride = stride;
    //videoPtr->vMode = VMODE_640x480;

    videoPtr->vtcBaseAddress = (u32)vtcBaseAddress;

    XAxiVdma_Config vdmaCfg = Py_XAxiVdma_LookupConfig(vdmaDict);
    videoPtr->vdma = Py_XAxiVdma_CfgInitialize(&vdmaCfg);

    videoPtr->vtcIsInit = 0;
    videoPtr->startOnDetect = 1;

    //videoPtr->gpioInterruptId = (u32)gpioInterruptId;
    //videoPtr->vtcInterruptId = (u32)vtcInterruptId;

    /*
     * Initialize the VDMA Read configuration struct
     */
    videoPtr->vdmaConfig.FrameDelay = 0;
    videoPtr->vdmaConfig.EnableCircularBuf = 1;
    videoPtr->vdmaConfig.EnableSync = 0;
    videoPtr->vdmaConfig.PointNum = 0;
    videoPtr->vdmaConfig.EnableFrameCounter = 0;

    /* Initialize the GPIO driver */
    XGpio_Config gpioConfig = Py_XGpio_LookupConfig(gpioDict);
    videoPtr->gpio = Py_XGpio_CfgInitialize(&gpioConfig);

    /*
     * Perform a self-test on the GPIO.  This is a minimal test and only
     * verifies that there is not any bus error when reading the data
     * register
     */
    XGpio_SelfTest(videoPtr->gpio);

    /*
     * Setup direction registers, and ensure HPD is low
     */
    XGpio_DiscreteWrite(videoPtr->gpio, 1, 0);
    XGpio_SetDataDirection(videoPtr->gpio, 1, 0); //Set HPD channel as output
    XGpio_SetDataDirection(videoPtr->gpio, 2, 1); //Set Locked channel as input

    /*Status = SetupInterruptSystem(videoPtr);
    if (Status != XST_SUCCESS)
    {
        printf("interrupt setup failed\n\r");
        return XST_FAILURE;
    }*/

    /*
     * Set HPD high, which will signal the HDMI source to begin transmitting.
     */
    XGpio_DiscreteWrite(videoPtr->gpio, 1, 1);
    // printf("Video Initialized!\n\r");

    /*****************/
    /* from Gpio Isr */  
    u32 locked = 0, timeout = 0;
    while (!locked && timeout < 1000000000){
        locked = XGpio_DiscreteRead(videoPtr->gpio, 2); 
        timeout++;
    }
    if(timeout == 1000000000){
        PyErr_Format(PyExc_SystemError, "Unable to complete initialization, \
                     no video source detected.\n Check if video source is \
                     active and retry.\n");
        return XST_FAILURE;
    }
    XVtc_Config vtcConfig = Py_XVtc_LookupConfig(videoPtr->vtcBaseAddress);
    videoPtr->vtc = *Py_XVtc_CfgInitialize(&vtcConfig);
    XVtc_SelfTest(&videoPtr->vtc);
    XVtc_RegUpdateEnable(&videoPtr->vtc);
    XVtc_EnableDetector(&videoPtr->vtc);
    videoPtr->vtcIsInit = 1; //useless in this context
    VtcDetect(videoPtr);
    /****************/

    return XST_SUCCESS;
}
/* ------------------------------------------------------------ */

/***    VideoSetMode(VideoCapture *dispPtr, const VideoMode *newMode)
**
**  Parameters:
**      dispPtr - Pointer to the initialized VideoCapture struct
**      newMode - The VideoMode struct describing the new mode.
**
**  Return Value: int
**      XST_SUCCESS if successful, XST_FAILURE otherwise
**
**  Errors:
**
**  Description:
**      Changes the resolution being output to the display. If the display
**      is currently started, it is automatically stopped (VideoStart must
**      be called again).
**
*/
//int VideoSetMode(VideoCapture *dispPtr, const VideoMode *newMode)
//{
//  int Status;
//
//  /*
//   * If currently running, stop
//   */
//  if (dispPtr->state == DISPLAY_RUNNING)
//  {
//      Status = VideoStop(dispPtr);
//      if (Status != XST_SUCCESS)
//      {
//          printf("Cannot change mode, unable to stop display %d\r\n", Status);
//          return XST_FAILURE;
//      }
//  }
//
//  dispPtr->vMode = *newMode;
//
//  return XST_SUCCESS;
//}
/* ------------------------------------------------------------ */

/***    VideoChangeFrame(VideoCapture *dispPtr, u32 frameIndex)
**
**  Parameters:
**      dispPtr - Pointer to the initialized VideoCapture struct
**      frameIndex - Index of the framebuffer to change to (must
**              be between 0 and (DISPLAY_NUM_FRAMES - 1))
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
     * If currently running, then the DMA needs to be told to start reading from the desired frame
     * at the end of the current frame
     */
    if (videoPtr->state == VIDEO_STREAMING)
    {
        Status = XAxiVdma_StartParking(videoPtr->vdma, videoPtr->curFrame, XAXIVDMA_WRITE);
        if (Status != XST_SUCCESS)
        {
            printf("Cannot change frame, unable to start parking %d\r\n", Status);
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
//int SetupInterruptSystem(VideoCapture *videoPtr)
//{
//    int Result;
//
// #ifdef XPAR_INTC_0_DEVICE_ID
//  /*
//   * Initialize the interrupt controller driver so that it's ready to use.
//   * specify the device ID that was generated in xparameters.h
//   */
//  Result = XIntc_Initialize(IntcInstancePtr, INTC_DEVICE_ID);
//  if (Result != XST_SUCCESS) {
//      return Result;
//  }
//
//  /* Hook up interrupt service routine */
//  XIntc_Connect(IntcInstancePtr, INTC_GPIO_INTERRUPT_ID,
//            (Xil_ExceptionHandler)GpioIsr, &Gpio);
//
//  /* Enable the interrupt vector at the interrupt controller */
//
//  XIntc_Enable(IntcInstancePtr, INTC_GPIO_INTERRUPT_ID);
//
//  /*
//   * Start the interrupt controller such that interrupts are recognized
//   * and handled by the processor
//   */
//  Result = XIntc_Start(IntcInstancePtr, XIN_REAL_MODE);
//  if (Result != XST_SUCCESS) {
//      return Result;
//  }
//
// #else
//
//    /*
//    * Initialize the interrupt controller driver so that it is ready to
//    * use.
//    */
//    XScuGic_Config IntcConfig = Py_XScuGic_LookupConfig(gicDict);
//    if ((videoPtr->intc = Py_XScuGic_CfgInitialize(&IntcConfig)) == NULL)
//        return XST_FAILURE;
//
//    XScuGic_SetPriorityTriggerType(videoPtr->intc, videoPtr->vtcInterruptId,
//                                   0xB0, 0x3);
//    Result = XScuGic_Connect(videoPtr->intc, videoPtr->vtcInterruptId,
//                       (Xil_ExceptionHandler)XVtc_IntrHandler, &videoPtr->vtc);
//    if (Result != XST_SUCCESS)
//        return Result;
//    XScuGic_Enable(videoPtr->intc, videoPtr->vtcInterruptId);
//
//    XScuGic_SetPriorityTriggerType(videoPtr->intc, videoPtr->gpioInterruptId,
//                                   0xA0, 0x3);
//    /*
//    * Connect the interrupt handler that will be called when an
//    * interrupt occurs for the device.
//    */
//    Result = XScuGic_Connect(videoPtr->intc, videoPtr->gpioInterruptId,
//                             (Xil_ExceptionHandler)GpioIsr, videoPtr);
//    if (Result != XST_SUCCESS)
//        return Result;
//    XScuGic_Enable(videoPtr->intc, videoPtr->gpioInterruptId);
// #endif
//
//    /*
//     * Enable the GPIO channel interrupts so that push button can be
//     * detected and enable interrupts for the GPIO device
//     */
//    XGpio_InterruptEnable(videoPtr->gpio, XGPIO_IR_CH2_MASK);
//
//    /*
//     * TODO: Consider adding code here to check if locked is high, and then initialize the VTC if it is high.
//     *       The point here would be to handle the case where a HDMI source ignores the HPD signal and is always
//     *       transmitting a clock. Currently it is possible that this case will not cause a GPIO interrupt, and
//     *       therefore the VTC will never get initialized. Probably could just get away with setting the GPIO irpt flag
//     */
//
//    XGpio_InterruptGlobalEnable(videoPtr->gpio);
//
//    /*
//     * Initialize the exception table and register the interrupt
//     * controller handler with the exception table
//     */
//    Xil_ExceptionInit(); // DEPRACATED, currently does nothing
//
//    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
//                         (Xil_ExceptionHandler)INTC_HANDLER, videoPtr->intc);
//
//    /* Enable non-critical exceptions */
//    Xil_ExceptionEnable();
//
//    return XST_SUCCESS;
//}


//void GpioIsr(void *InstancePtr)
//{
//    VideoCapture *videoPtr = (VideoCapture *)InstancePtr;
//    u32 locked;
//    //int Status;
//
//    //printf("~");
//    /*
//     * Disable the interrupt
//     */
//     //XGpio_InterruptDisable(GpioPtr, XGPIO_IR_CH2_MASK);
//     (void)XGpio_InterruptClear(videoPtr->gpio, XGPIO_IR_CH2_MASK);
//     locked = XGpio_DiscreteRead(videoPtr->gpio, 2);
//     if (locked)
//     {
//         //if (!videoPtr->vtcIsInit)
//         {
//             //printf("1");
//             XVtc_Config vtcConfig = Py_XVtc_LookupConfig(videoPtr->vtcBaseAddress);

//             //printf("2");
//             videoPtr->vtc = *Py_XVtc_CfgInitialize(&vtcConfig);
//             /*if (vtc == NULL) {
//                 return (XST_FAILURE);
//             }*/

//             //printf("3");
//             XVtc_SelfTest(&videoPtr->vtc);

//             //printf("4");
//             XVtc_RegUpdateEnable(&videoPtr->vtc);
//             XVtc_SetCallBack(&videoPtr->vtc, XVTC_HANDLER_LOCK, VtcIsr, videoPtr);
//             //XVtc_SetCallBack(&(videoPtr->vtc), XVTC_HANDLER_DETECTOR, VtcDetIsr, videoPtr);
//             XVtc_IntrEnable(&videoPtr->vtc, 0x100);
//             XVtc_EnableDetector(&videoPtr->vtc);
//             //XVtc_IntrEnable(&(videoPtr->vtc), XVTC_IXR_LOCKALL_MASK);
//             videoPtr->vtcIsInit = 1;

//             //printf("5");
//         }
//         /*
//          * TODO: Add Preprocessor check for microblaze
//          */
//         XScuGic_Enable(videoPtr->intc, videoPtr->vtcInterruptId);
//     }
//     else
//     {
//         VideoStop(videoPtr);
//         /*
//          * TODO: Add Preprocessor check for microblaze
//          */
//         XScuGic_Disable(videoPtr->intc, videoPtr->vtcInterruptId);
//         videoPtr->state = VIDEO_DISCONNECTED;
//     }


//      /* Clear the interrupt such that it is no longer pending in the GPIO */

//      //(void)XGpio_InterruptClear(GpioPtr, XGPIO_IR_CH2_MASK);

//      /*
//       * Enable the interrupt
//       */
//      //XGpio_InterruptEnable(GpioPtr, XGPIO_IR_CH2_MASK);

// }

/*
 * TODO: Add the option for users to add hooks into this ISR
 */
// void VtcIsr(void *InstancePtr, u32 pendingIrpt)
// {
//     VideoCapture *videoPtr = (VideoCapture *)InstancePtr;

//     //printf("$");
//     if (XVtc_GetDetectionStatus(&videoPtr->vtc) & XVTC_STAT_LOCKED_MASK)
//     {
//         XVtc_GetDetectorTiming(&videoPtr->vtc,&videoPtr->timing);
//         videoPtr->state = VIDEO_PAUSED;
//         //printf("1");
//         if (videoPtr->startOnDetect)
//         {
//             //printf("2");
//             VideoStart(videoPtr);
//             //printf("3");
//         }
//         XVtc_IntrDisable(&videoPtr->vtc, 0x100);
//         XVtc_IntrClear(&videoPtr->vtc, 0x100);
//     }

// }

void VtcDetect(VideoCapture *videoPtr){
    //if (XVtc_GetDetectionStatus(&videoPtr->vtc) & XVTC_STAT_LOCKED_MASK)
    //{
        XVtc_GetDetectorTiming(&videoPtr->vtc,&videoPtr->timing);
       
        if(videoPtr->timing.VActiveVideo == 0 
                    || videoPtr->timing.HActiveVideo == 0){
            if(videoPtr->state == VIDEO_DISCONNECTED){
                videoPtr->state = VIDEO_PAUSED;
                //if (videoPtr->startOnDetect)
                //{
                //    VideoStart(videoPtr);
                //}
            }
        }       
    //}
}

/************************************************************************/
