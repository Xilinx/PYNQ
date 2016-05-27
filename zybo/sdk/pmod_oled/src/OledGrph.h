/************************************************************************/
/*                                                                      */
/*  OledGrph.h  --  Declarations for OLED Graphics Routines             */
/*                                                                      */
/************************************************************************/
/*  Author:     Gene Apperson                                           */
/*  Copyright 2011, Digilent Inc.                                       */
/************************************************************************/
/*  File Description:                                                   */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*  Revision History:                                                   */
/*                                                                      */
/*  06/03/2011(GeneA): created                                          */
/*  04/25/2016(Rock): abs function added                                */
/*                                                                      */
/************************************************************************/

/* ------------------------------------------------------------ */
/*                  Procedure Declarations                      */
/* ------------------------------------------------------------ */

void    OledSetDrawMode(int mod);
int     OledGetDrawMode();

void    OledMoveTo(int xco, int yco);
void    OledGetPos(int * pxco, int * pyco);
void    OledDrawPixel();
u8      OledGetPixel();
void    OledLineTo(int xco, int yco);
void    OledDrawRect(int xco, int yco);
void    OledDrawChar(char ch);
void    OledDrawString(char * sz);

int abs(int x);

/* ------------------------------------------------------------ */

/************************************************************************/
