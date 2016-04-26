
/************************************************************************/
/*                                                                      */
/*  FillPat.c   --  Pattern Table for Area Fill                         */
/*                                                                      */
/************************************************************************/
/*  Author:     Gene Apperson                                           */
/*  Copyright 2011, Digilent Inc.                                       */
/************************************************************************/
/*  Module Description:                                                 */
/*                                                                      */
/*  This module contains the data definitions for an set of8x8 pixel    */
/*  patterns used for area fill.                                        */
/*                                                                      */
/*  This pattern table is defined for a display where each byte         */
/*  represents 8 vertical pixels and consecutive bytes give adjacent    */
/*  sets of 8 vertical pixels progressing to the right across the       */
/*  display. This is rotated 90 degrees from the conventional video     */
/*  display orientation.                                                */
/*                                                                      */
/************************************************************************/
/*  Revision History:                                                   */
/*                                                                      */
/*  06/08/2011(GeneA): created                                          */
/*                                                                      */
/************************************************************************/

/* ------------------------------------------------------------ */
/*              Include File Definitions                        */
/* ------------------------------------------------------------ */
#include "xparameters.h"    /* SDK generated parameters */
#include "xspi.h"   // axi qspi driver
#include "xspi_l.h"
#include "xil_printf.h"
#include "xgpio.h"

/* ------------------------------------------------------------ */
/*              Global Variables                                */
/* ------------------------------------------------------------ */
const u8 rgbFillPat[] = {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 0x00
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // 0x01
    0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, // 0x02
    0x11, 0x44, 0x00, 0x11, 0x44, 0x00, 0x11, 0x44, // 0x03
    0x92, 0x45, 0x24, 0x92, 0x45, 0x24, 0x92, 0x45, // 0x04
    0x49, 0x92, 0x24, 0x49, 0x92, 0x24, 0x49, 0x92, // 0x05
    0x22, 0x11, 0x22, 0x00, 0x22, 0x11, 0x22, 0x00, // 0x06
    0x11, 0x22, 0x11, 0x00, 0x11, 0x22, 0x11, 0x00  // 0x07
};

/* ------------------------------------------------------------ */

/************************************************************************/

