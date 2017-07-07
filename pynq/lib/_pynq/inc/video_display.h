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
/*    This module provides an easy to use API for controlling the       */
/*    Digilent display controller core (axi_dispctrl). It supports      */
/*    run-time resolution setting and seamless framebuffer-swapping     */
/*    for tear-free animation.                                          */
/*                                                                      */
/*    To use this driver, you must have an axi_dispctrl and axi_vdma    */
/*    core present in your system. For information on how to properly   */
/*    configure these cores within your design, refer to the            */
/*    axi_dispctrl data sheet accessible from Vivado and XPS.           */
/*                                                                      */
/*    The following steps should be followed to use this driver:        */
/*    1) Create a DisplayCtrl object and pass a pointer to it to        */
/*       DisplayInitialize.                                             */
/*    2) Call DisplaySetMode to set the desired mode                    */
/*    3) Call DisplayStart to begin outputting data to the display      */
/*    4) To create a seamless animation, draw the next image to a       */
/*       framebuffer currently not being displayed. Then call           */
/*       DisplayChangeFrame to begin displaying that frame.             */
/*       Repeat as needed, only ever modifying inactive frames.         */
/*    5) To change the resolution, call DisplaySetMode, followed by     */
/*       DisplayStart again.                                            */
/*                                                                      */
/*    This module contains code from the Xilinx Demo titled             */
/*    "xiicps_polled_master_example.c." Xilinx XAPP888 was also         */
/*    referenced for information on reconfiguring the MMCM or PLL.      */
/*    Note that functions beginning with "DisplayClk" are used          */
/*    internally for this purpose and should not need to be called      */
/*    externally.                                                       */
/*                                                                      */
/************************************************************************/
/*  Revision History:                                                   */
/*                                                                      */
/*      02/20/2014(SamB): Created                                       */
/*      11/24/2015(GN): Modified for MicroPython                        */
/*      01/26/2016(GN): Modified for CPython                            */
/*      08/31/2016(YRQ): Added lisense header                           */
/*      09/01/2016(beja): vga_modes.h to video_modes.h                  */
/*                                                                      */
/************************************************************************/

#ifndef DISPLAY_CTRL_H_
#define DISPLAY_CTRL_H_

/* ------------------------------------------------------------ */
/*        Include File Definitions                              */
/* ------------------------------------------------------------ */
#include <Python.h>
#include "xil_types.h"
#include "xaxivdma.h"
#include "xvtc.h"
#include "py_xaxivdma.h"
#include "py_xvtc.h"
#include "video_modes.h"

/* ------------------------------------------------------------ */
/*          Miscellaneous Declarations                          */
/* ------------------------------------------------------------ */

#define CLK_BIT_WEDGE 13
#define CLK_BIT_NOCOUNT 12

#define ERR_CLKCOUNTCALC 0xFFFFFFFF //This value is used to signal an error

//#define OFST_DISPLAY_CTRL 0x0
//#define OFST_DISPLAY_STATUS 0x4
//#define OFST_DISPLAY_VIDEO_START 0x8
//#define OFST_DISPLAY_CLK_L 0x1C
//#define OFST_DISPLAY_FB_L 0x20
//#define OFST_DISPLAY_FB_H_CLK_H 0x24
//#define OFST_DISPLAY_DIV 0x28
//#define OFST_DISPLAY_LOCK_L 0x2C
//#define OFST_DISPLAY_FLTR_LOCK_H 0x30

#define OFST_DISPLAY_CTRL 0x0
#define OFST_DISPLAY_STATUS 0x4
#define OFST_DISPLAY_CLK_L 0x8
#define OFST_DISPLAY_FB_L 0x0C
#define OFST_DISPLAY_FB_H_CLK_H 0x10
#define OFST_DISPLAY_DIV 0x14
#define OFST_DISPLAY_LOCK_L 0x18
#define OFST_DISPLAY_FLTR_LOCK_H 0x1C

#define BIT_DISPLAY_RED 16
#define BIT_DISPLAY_BLUE 0
#define BIT_DISPLAY_GREEN 8

#define BIT_DISPLAY_START 0
#define BIT_CLOCK_RUNNING 0

#define DISPLAY_NOT_HDMI 0
#define DISPLAY_HDMI 1

/*
 * This driver currently supports 3 frames.
 */
#define DISPLAY_NUM_FRAMES  3

 
/*
 * WEDGE and NOCOUNT can't both be high, so this is used to signal an error
 */
#define ERR_CLKDIVIDER (1 << CLK_BIT_WEDGE | 1 << CLK_BIT_NOCOUNT)

/* ------------------------------------------------------------ */
/*          General Type Declarations                           */
/* ------------------------------------------------------------ */

typedef enum {
  DISPLAY_STOPPED = 0,
  DISPLAY_RUNNING = 1
} DisplayState;

typedef struct {
  u32 clk0L;
  u32 clkFBL;
  u32 clkFBH_clk0H;
  u32 divclk;
  u32 lockL;
  u32 fltr_lockH;
} ClkConfig;

typedef struct {
  double freq;
  u32 fbmult;
  u32 clkdiv;
  u32 maindiv;
} ClkMode;


typedef struct {
  u32 dynClkAddr; /*Physical Base address of the dynclk core*/
  int fHdmi; /*flag indicating if the display controller is being used*/
  XVtc *vtc; /*VTC driver struct*/
  VideoMode vMode; /*Current Video mode*/
  double pxlFreq; /* Frequency of clock currently being generated */
  DisplayState state; /* Indicates if the Display is currently running */
} DisplayCtrl;

/* ------------------------------------------------------------ */
/*          Variable Declarations                               */
/* ------------------------------------------------------------ */

static const u64 lock_lookup[64] = {
   0b0011000110111110100011111010010000000001,
   0b0011000110111110100011111010010000000001,
   0b0100001000111110100011111010010000000001,
   0b0101101011111110100011111010010000000001,
   0b0111001110111110100011111010010000000001,
   0b1000110001111110100011111010010000000001,
   0b1001110011111110100011111010010000000001,
   0b1011010110111110100011111010010000000001,
   0b1100111001111110100011111010010000000001,
   0b1110011100111110100011111010010000000001,
   0b1111111111111000010011111010010000000001,
   0b1111111111110011100111111010010000000001,
   0b1111111111101110111011111010010000000001,
   0b1111111111101011110011111010010000000001,
   0b1111111111101000101011111010010000000001,
   0b1111111111100111000111111010010000000001,
   0b1111111111100011111111111010010000000001,
   0b1111111111100010011011111010010000000001,
   0b1111111111100000110111111010010000000001,
   0b1111111111011111010011111010010000000001,
   0b1111111111011101101111111010010000000001,
   0b1111111111011100001011111010010000000001,
   0b1111111111011010100111111010010000000001,
   0b1111111111011001000011111010010000000001,
   0b1111111111011001000011111010010000000001,
   0b1111111111010111011111111010010000000001,
   0b1111111111010101111011111010010000000001,
   0b1111111111010101111011111010010000000001,
   0b1111111111010100010111111010010000000001,
   0b1111111111010100010111111010010000000001,
   0b1111111111010010110011111010010000000001,
   0b1111111111010010110011111010010000000001,
   0b1111111111010010110011111010010000000001,
   0b1111111111010001001111111010010000000001,
   0b1111111111010001001111111010010000000001,
   0b1111111111010001001111111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001,
   0b1111111111001111101011111010010000000001
};

static const u32 filter_lookup_low[64] = {
    0b0001011111,
    0b0001010111,
    0b0001111011,
    0b0001011011,
    0b0001101011,
    0b0001110011,
    0b0001110011,
    0b0001110011,
    0b0001110011,
    0b0001001011,
    0b0001001011,
    0b0001001011,
    0b0010110011,
    0b0001010011,
    0b0001010011,
    0b0001010011,
    0b0001010011,
    0b0001010011,
    0b0001010011,
    0b0001010011,
    0b0001010011,
    0b0001010011,
    0b0001010011,
    0b0001100011,
    0b0001100011,
    0b0001100011,
    0b0001100011,
    0b0001100011,
    0b0001100011,
    0b0001100011,
    0b0001100011,
    0b0001100011,
    0b0001100011,
    0b0001100011,
    0b0001100011,
    0b0001100011,
    0b0001100011,
    0b0010010011,
    0b0010010011,
    0b0010010011,
    0b0010010011,
    0b0010010011,
    0b0010010011,
    0b0010010011,
    0b0010010011,
    0b0010010011,
    0b0010010011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011,
    0b0010100011
};

/* ------------------------------------------------------------ */
/*          Procedure Declarations                              */
/* ------------------------------------------------------------ */

u32 DisplayClkCountCalc(u32 divide);
u32 DisplayClkDivider(u32 divide);
u32 DisplayClkFindReg (ClkConfig *regValues, ClkMode *clkParams);
void DisplayClkWriteReg (ClkConfig *regValues, u32 dynClkAddr);
double DisplayClkFindParams(double freq, ClkMode *bestPick);

int DisplayStop(DisplayCtrl *dispPtr);
int DisplayStart(DisplayCtrl *dispPtr);
int DisplayInitialize(DisplayCtrl *dispPtr, 
                      unsigned int vtcBaseAddress, unsigned int dynClkAddr, 
                      unsigned int fHdmi);
int DisplaySetMode(DisplayCtrl *dispPtr, const VideoMode *newMode);


/* ------------------------------------------------------------ */

/************************************************************************/

#endif /* DISPLAY_CTRL_H_ */
