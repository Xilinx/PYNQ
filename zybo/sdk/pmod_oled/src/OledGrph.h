/************************************************************************/
/*																		*/
/*	OledGrph.h	--	Declarations for OLED Graphics Routines				*/
/*																		*/
/************************************************************************/
/*	Author:		Gene Apperson											*/
/*	Copyright 2011, Digilent Inc.										*/
/************************************************************************/
/*  File Description:													*/
/*																		*/
/*																		*/
/************************************************************************/
/*  Revision History:													*/
/*																		*/
/*	06/03/2011(GeneA): created											*/
/*																		*/
/************************************************************************/

/* ------------------------------------------------------------ */
/*					Procedure Declarations						*/
/* ------------------------------------------------------------ */

void	OledSetDrawColor(u8 clr);
void	OledSetDrawMode(int mod);
int		OledGetDrawMode();
u8 *	OledGetStdPattern(int ipat);
void	OledSetFillPattern(u8 * pbPat);

void	OledMoveTo(int xco, int yco);
void	OledGetPos(int * pxco, int * pyco);
void	OledDrawPixel();
u8	    OledGetPixel();
void	OledLineTo(int xco, int yco);
void	OledDrawRect(int xco, int yco);
void	OledFillRect(int xco, int yco);
void	OledGetBmp(int dxco, int dyco, u8 * pbBmp);
void	OledPutBmp(int dxco, int dyco, u8 * pbBmp);
void	OledDrawChar(char ch);
void	OledDrawString(char * sz);

/* ------------------------------------------------------------ */

/************************************************************************/
