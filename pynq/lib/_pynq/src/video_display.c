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
/*      08/31/2016(YRQ): Adjusted format                                */
/*                                                                      */
/************************************************************************/
/*
 * TODO: Functionality needs to be added to take advantage of the MMCM's 
 *       fractional divide. This will allow a far greater number of 
 *       frequencies to be synthesized.
 */


/* ------------------------------------------------------------ */
/*              Include File Definitions                        */
/* ------------------------------------------------------------ */

#include <stdio.h>
#include "math.h"
#include "xil_io.h"
#include "video_display.h"

/* ------------------------------------------------------------ */
/*              Procedure Definitions                           */
/* ------------------------------------------------------------ */

/***    DisplayStop(DisplayCtrl *dispPtr)
**
**  Parameters:
**      dispPtr - Pointer to the initialized DisplayCtrl struct
**
**  Return Value: int
**      XST_SUCCESS if successful.
**
**  Description:
**      Halts output to the display
**
*/
int DisplayStop(DisplayCtrl *dispPtr)
{
    /*
     * If already stopped, do nothing
     */
    if (dispPtr->state == DISPLAY_STOPPED)
    {
        return XST_SUCCESS;
    }

    /*
     * Disable the disp_ctrl core, and wait for the current frame to finish 
     * (the core cannot stop mid-frame)
     */
    XVtc_DisableGenerator(dispPtr->vtc);

    /*
     * Update Struct state
     */
    dispPtr->state = DISPLAY_STOPPED;

    return XST_SUCCESS;
}
/* ------------------------------------------------------------ */

/***    DisplayStart(DisplayCtrl *dispPtr)
**
**  Parameters:
**      dispPtr - Pointer to the initialized DisplayCtrl struct
**
**  Return Value: int
**      XST_SUCCESS if successful, XST_FAILURE otherwise
**
**  Errors:
**
**  Description:
**      Starts the display.
**
*/
int DisplayStart(DisplayCtrl *dispPtr)
{
    int Status;
    ClkConfig clkReg;
    ClkMode clkMode;
    int i;
    double pxlClkFreq;
    XVtc_Timing vtcTiming;
    XVtc_SourceSelect SourceSelect;

    /*
     * If already started, do nothing
     */
    if (dispPtr->state == DISPLAY_RUNNING)
    {
        return XST_SUCCESS;
    }


    /*
     * Calculate the PLL divider parameters based on the required 
     * pixel clock frequency
     */
    if (dispPtr->fHdmi == DISPLAY_HDMI)
    {
        pxlClkFreq = dispPtr->vMode.freq * 5;
    }
    else
    {
        pxlClkFreq = dispPtr->vMode.freq;
    }
    DisplayClkFindParams(pxlClkFreq, &clkMode);

    /*
     * Store the obtained frequency to pxlFreq. It is possible that the 
     * PLL was not able to exactly generate the desired pixel clock, 
     * so this may differ from vMode.freq.
     */
    dispPtr->pxlFreq = clkMode.freq;

    /*
     * Write to the PLL dynamic configuration registers to configure it 
     * with the calculated parameters.
     */
    if (!DisplayClkFindReg(&clkReg, &clkMode))
    {
        printf("Error calculating CLK register values\n\r");
        return XST_FAILURE;
    }
    DisplayClkWriteReg(&clkReg, dispPtr->dynClkAddr);

    /*
     * Enable the dynamically generated clock
    */
    Xil_Out32(dispPtr->dynClkAddr + OFST_DISPLAY_CTRL, 0);
    while((Xil_In32(dispPtr->dynClkAddr + OFST_DISPLAY_STATUS) & \
            (1 << BIT_CLOCK_RUNNING)));
    Xil_Out32(dispPtr->dynClkAddr + OFST_DISPLAY_CTRL, \
            (1 << BIT_DISPLAY_START));
    while(!(Xil_In32(dispPtr->dynClkAddr + OFST_DISPLAY_STATUS) & \
            (1 << BIT_CLOCK_RUNNING)));

    /*
     * Configure the vtc core with the display mode timing parameters
     */
    // Horizontal Active Video Size 
    vtcTiming.HActiveVideo = dispPtr->vMode.width;
    // Horizontal Front Porch Size
    vtcTiming.HFrontPorch = dispPtr->vMode.hps - dispPtr->vMode.width;
    // Horizontal Sync Width
    vtcTiming.HSyncWidth = dispPtr->vMode.hpe - dispPtr->vMode.hps;
    // Horizontal Back Porch Size
    vtcTiming.HBackPorch = dispPtr->vMode.hmax - dispPtr->vMode.hpe + 1;
    // Horizontal Sync Polarity
    vtcTiming.HSyncPolarity = dispPtr->vMode.hpol;
    // Vertical Active Video Size
    vtcTiming.VActiveVideo = dispPtr->vMode.height;
    // Vertical Front Porch Size
    vtcTiming.V0FrontPorch = dispPtr->vMode.vps - dispPtr->vMode.height;
    // Vertical Sync Width
    vtcTiming.V0SyncWidth = dispPtr->vMode.vpe - dispPtr->vMode.vps;
    // Horizontal Back Porch Size
    vtcTiming.V0BackPorch = dispPtr->vMode.vmax - dispPtr->vMode.vpe + 1;
    // Vertical Front Porch Size
    vtcTiming.V1FrontPorch = dispPtr->vMode.vps - dispPtr->vMode.height;
    // Vertical Sync Width
    vtcTiming.V1SyncWidth = dispPtr->vMode.vpe - dispPtr->vMode.vps;
    // Horizontal Back Porch Size
    vtcTiming.V1BackPorch = dispPtr->vMode.vmax - dispPtr->vMode.vpe + 1;
    // Vertical Sync Polarity
    vtcTiming.VSyncPolarity = dispPtr->vMode.vpol;
    // Interlaced / Progressive video
    vtcTiming.Interlaced = 0;

    /* 
     * Setup the VTC Source Select config structure.
     * 1=Generator registers are source
     * 0=Detector registers are source 
     */
    memset((void *)&SourceSelect, 0, sizeof(SourceSelect));
    SourceSelect.VBlankPolSrc = 1;
    SourceSelect.VSyncPolSrc = 1;
    SourceSelect.HBlankPolSrc = 1;
    SourceSelect.HSyncPolSrc = 1;
    SourceSelect.ActiveVideoPolSrc = 1;
    SourceSelect.ActiveChromaPolSrc= 1;
    SourceSelect.VChromaSrc = 1;
    SourceSelect.VActiveSrc = 1;
    SourceSelect.VBackPorchSrc = 1;
    SourceSelect.VSyncSrc = 1;
    SourceSelect.VFrontPorchSrc = 1;
    SourceSelect.VTotalSrc = 1;
    SourceSelect.HActiveSrc = 1;
    SourceSelect.HBackPorchSrc = 1;
    SourceSelect.HSyncSrc = 1;
    SourceSelect.HFrontPorchSrc = 1;
    SourceSelect.HTotalSrc = 1;

    XVtc_SelfTest(dispPtr->vtc);

    XVtc_RegUpdateEnable(dispPtr->vtc);
    XVtc_SetGeneratorTiming(dispPtr->vtc, &vtcTiming);
    XVtc_SetSource(dispPtr->vtc, &SourceSelect);
    
    /*
     * Enable VTC core, releasing backpressure on VDMA
     */
    XVtc_EnableGenerator(dispPtr->vtc);

    dispPtr->state = DISPLAY_RUNNING;

    return XST_SUCCESS;
}

/* ------------------------------------------------------------ */

/***    DisplayInitialize(DisplayCtrl *dispPtr, PyObject *vdmaDict, 
**          u32 dynClkAddr, int fHdmi, 
**          u32 *framePtr[DISPLAY_NUM_FRAMES], u32 stride)
**
**  Parameters:
**      dispPtr - Pointer to the struct that will be initialized
**      dynClkAddr - BASE ADDRESS of the axi_dynclk core
**      fHdmi - flag indicating if the C_USE_BUFR_DIV5 parameter is set for 
**              the axi_dispctrl core.
**              Use DISPLAY_HDMI if it is set, otherwise use DISPLAY_NOT_HDMI
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
int DisplayInitialize(DisplayCtrl *dispPtr,
                      unsigned int vtcBaseAddress, unsigned int dynClkAddr, 
                      unsigned int fHdmi)
{
    int i;
    ClkConfig clkReg;
    ClkMode clkMode;


    /*
     * Initialize all the fields in the DisplayCtrl struct
     */
    dispPtr->dynClkAddr = (u32)getVirtualAddress(dynClkAddr);
    dispPtr->fHdmi = (int)fHdmi;
    
    dispPtr->state = DISPLAY_STOPPED;
    dispPtr->vMode = VMODE_640x480;

    DisplayClkFindParams((double)dispPtr->vMode.freq * (double)5.0, &clkMode);
    
    /*
     * Store the obtained frequency to pxlFreq. It is possible that the PLL 
     * was not able to exactly generate the desired pixel clock, so this may 
     * differ from vMode.freq.
     */
    dispPtr->pxlFreq = clkMode.freq;

    /*
     * Write to the PLL dynamic configuration registers to configure it 
     * with the calculated parameters.
     */
    if (!DisplayClkFindReg(&clkReg, &clkMode))
    {
        return XST_FAILURE;
    }
    DisplayClkWriteReg(&clkReg, dispPtr->dynClkAddr);

    /*
     * Enable the dynamically generated clock
    */
    Xil_Out32(dispPtr->dynClkAddr + OFST_DISPLAY_CTRL, \
                (1 << BIT_DISPLAY_START));
    while(!(Xil_In32(dispPtr->dynClkAddr + OFST_DISPLAY_STATUS) & \
                (1 << BIT_CLOCK_RUNNING)));

    XVtc_Config vtcConfig = Py_XVtc_LookupConfig(vtcBaseAddress);
    dispPtr->vtc = Py_XVtc_CfgInitialize(&vtcConfig);
    
    return XST_SUCCESS;
}
/* ------------------------------------------------------------ */

/***    DisplaySetMode(DisplayCtrl *dispPtr, const VideoMode *newMode)
**
**  Parameters:
**      dispPtr - Pointer to the initialized DisplayCtrl struct
**      newMode - The VideoMode struct describing the new mode.
**
**  Return Value: int
**      XST_SUCCESS if successful, XST_FAILURE otherwise
**
**  Errors:
**
**  Description:
**      Changes the resolution being output to the display. If the display
**      is currently started, it is automatically stopped (DisplayStart must
**      be called again).
**
*/
int DisplaySetMode(DisplayCtrl *dispPtr, const VideoMode *newMode)
{
    int Status;

    /*
     * If currently running, stop
     */
    if (dispPtr->state == DISPLAY_RUNNING)
    {
        Status = DisplayStop(dispPtr);
        if (Status != XST_SUCCESS)
        {
            return XST_FAILURE;
        }
    }

    dispPtr->vMode = *newMode;

    return XST_SUCCESS;
}

u32 DisplayClkCountCalc(u32 divide)
{
    u32 output = 0;
    u32 divCalc = 0;

    divCalc = DisplayClkDivider(divide);
    if (divCalc == ERR_CLKDIVIDER)
        output = ERR_CLKCOUNTCALC;
    else
        output = (0xFFF & divCalc) | ((divCalc << 10) & 0x00C00000);
    return output;
}

u32 DisplayClkDivider(u32 divide)
{
    u32 output = 0;
    u32 highTime = 0;
    u32 lowTime = 0;

    if ((divide < 1) || (divide > 128))
        return ERR_CLKDIVIDER;

    if (divide == 1)
        return 0x1041;

    highTime = divide / 2;
    if (divide & 0b1)
    {
        lowTime = highTime + 1;
        output = 1 << CLK_BIT_WEDGE;
    }
    else
    {
        lowTime = highTime;
    }

    output |= 0x03F & lowTime;
    output |= 0xFC0 & (highTime << 6);
    return output;
}

u32 DisplayClkFindReg (ClkConfig *regValues, ClkMode *clkParams)
{
    if ((clkParams->fbmult < 2) || clkParams->fbmult > 64 )
        return 0;

    regValues->clk0L = DisplayClkCountCalc(clkParams->clkdiv);
    if (regValues->clk0L == ERR_CLKCOUNTCALC)
        return 0;

    regValues->clkFBL = DisplayClkCountCalc(clkParams->fbmult);
    if (regValues->clkFBL == ERR_CLKCOUNTCALC)
        return 0;

    regValues->clkFBH_clk0H = 0;

    regValues->divclk = DisplayClkDivider(clkParams->maindiv);
    if (regValues->divclk == ERR_CLKDIVIDER)
        return 0;

    regValues->lockL = (u32) (lock_lookup[clkParams->fbmult - 1] & \
                                0xFFFFFFFF);

    regValues->fltr_lockH = (u32) ((lock_lookup[clkParams->fbmult - 1] >> \
                                    32) & 0x000000FF);
    regValues->fltr_lockH |= ((filter_lookup_low[clkParams->fbmult - 1] << \
                                    16) & 0x03FF0000);

    return 1;
}

void DisplayClkWriteReg (ClkConfig *regValues, u32 dynClkAddr)
{
    Xil_Out32(dynClkAddr + OFST_DISPLAY_CLK_L, regValues->clk0L);
    Xil_Out32(dynClkAddr + OFST_DISPLAY_FB_L, regValues->clkFBL);
    Xil_Out32(dynClkAddr + OFST_DISPLAY_FB_H_CLK_H, regValues->clkFBH_clk0H);
    Xil_Out32(dynClkAddr + OFST_DISPLAY_DIV, regValues->divclk);
    Xil_Out32(dynClkAddr + OFST_DISPLAY_LOCK_L, regValues->lockL);
    Xil_Out32(dynClkAddr + OFST_DISPLAY_FLTR_LOCK_H, regValues->fltr_lockH);
}

/*
 * TODO:This function currently requires that the reference clock is 100MHz.
 *      This should be changed so that the ref. clock can be specified, 
 *      or read directly out of hardware.
 */
double DisplayClkFindParams(double freq, ClkMode *bestPick)
{
    double bestError = 2000.0;
    double curError;
    double curClkMult;
    double curFreq;
    u32 curDiv, curFb, curClkDiv;
    u32 minFb = 0;
    u32 maxFb = 0;


    bestPick->freq = 0.0;
/*
 * TODO: replace with a smarter algorithm that doesn't check every 
 * possible combination
 */
    for (curDiv = 1; curDiv <= 10; curDiv++)
    {
        // accounts for the 100MHz input and the 600MHz minimum VCO
        minFb = curDiv * 6;
        // accounts for the 100MHz input and the 1200MHz maximum VCO
        maxFb = curDiv * 12;
        if (maxFb > 64)
            maxFb = 64;

        // multiplier is used to find the best clkDiv value for each FB value
        curClkMult = ((double) 100.0 / (double) curDiv) / (double) freq;

        curFb = minFb;
        while (curFb <= maxFb)
        {
            curClkDiv = (u32) ((curClkMult * (double)curFb) + (double) 0.5);
            curFreq = (((double) 100.0 / (double) curDiv) / \
                        (double) curClkDiv) * (double) curFb;
            curError = fabs(curFreq - freq);
            if (curError < bestError)
            {
                bestError = curError;
                bestPick->clkdiv = curClkDiv;
                bestPick->fbmult = curFb;
                bestPick->maindiv = curDiv;
                bestPick->freq = curFreq;
            }

            curFb++;
        }
    }

    return bestError;
}

/************************************************************************/
