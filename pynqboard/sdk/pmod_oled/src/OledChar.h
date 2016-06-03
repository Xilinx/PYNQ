/************************************************************************/
/*                                                                      */
/*  OledChar.h  --  Interface Declarations for OledChar.c               */
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
/*  06/01/2011(GeneA): created                                          */
/*                                                                      */
/************************************************************************/
/* ------------------------------------------------------------ */
/*                  Miscellaneous Declarations                  */
/* ------------------------------------------------------------ */

#define cbOledDispMax   512     //max number of bytes in display buffer

#define ccolOledMax     128     //number of display columns
#define crowOledMax     32      //number of display rows
#define cpagOledMax     4       //number of display memory pages

#define cbOledChar      8       //font glyph definitions is 8 bytes long
#define chOledUserMax   0x20    //number of character defs in user font table
#define cbOledFontUser  (chOledUserMax*cbOledChar)

/* Graphics drawing modes. */
#define    modOledSet      0
#define    modOledOr       1
#define    modOledAnd      2
#define    modOledXor      3

/* ------------------------------------------------------------ */
/*                  Procedure Declarations                      */
/* ------------------------------------------------------------ */
void    OledSetCursor(int xch, int ych);
void    OledGetCursor(int * pxcy, int * pych);
int     OledDefUserChar(char ch, u8 * pbDef);
void    OledSetCharUpdate(int f);
int     OledGetCharUpdate();
void    OledPutChar(char ch);
void    OledPutString(char * sz);
void    OLEDNewline(void);
/* ------------------------------------------------------------ */

/************************************************************************/
