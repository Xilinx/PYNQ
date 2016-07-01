/************************************************************************/
/*                                                                      */
/*  OledChar.c  --  Character Output Routines for OLED Display          */
/*                                                                      */
/************************************************************************/
/*  Author:     Gene Apperson                                           */
/*  Copyright 2011, Digilent Inc.                                       */
/************************************************************************/
/*  Module Description:                                                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*  Revision History:                                                   */
/*                                                                      */
/*  06/01/2011(GeneA): created                                          */
/*                                                                      */
/************************************************************************/


/* ------------------------------------------------------------ */
/*              Include File Definitions                        */
/* ------------------------------------------------------------ */

#include "xparameters.h"    /* SDK generated parameters */
#include "xspi.h"   // axi qspi driver
#include "xspi_l.h"

#include "xgpio.h"
#include "OledChar.h"
#include "OledGrph.h"
/* ------------------------------------------------------------ */
/*              Global Variables                                */
/* ------------------------------------------------------------ */
extern int      xcoOledCur;
extern int      ycoOledCur;

extern u8 *     pbOledCur;
extern u8       mskOledCur;
extern int      bnOledCur;
extern int      fOledCharUpdate;

extern int      dxcoOledFontCur;
extern int      dycoOledFontCur;

extern  u8 *    pbOledFontCur;
extern  u8 *    pbOledFontUser;

/* ------------------------------------------------------------ */
/*              Local Variables                                 */
/* ------------------------------------------------------------ */

int     xchOledCur;
int     ychOledCur;

int     xchOledMax;
int     ychOledMax;

u8 *    pbOledFontExt;
u8      rgbOledFontUser[cbOledFontUser];

/* ------------------------------------------------------------ */
/*              Forward Declarations                            */
/* ------------------------------------------------------------ */

void    OledDrawGlyph(char ch);
void    OledAdvanceCursor();

/* ------------------------------------------------------------ */
/*              Procedure Definitions                           */
/* ------------------------------------------------------------ */
/***    OledSetCursor
**
**  Parameters:
**      xch         - horizontal character position
**      ych         - vertical character position
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      Set the character cursor position to the specified location.
**      If either the specified X or Y location is off the display, it
**      is clamped to be on the display.
*/

void
OledSetCursor(int xch, int ych)
    {

    /* Clamp the specified location to the display surface
    */
    if (xch >= xchOledMax) {
        xch = xchOledMax-1;
    }

    if (ych >= ychOledMax) {
        ych = ychOledMax-1;
    }

    /* Save the given character location.
    */
    xchOledCur = xch;
    ychOledCur = ych;

    /* Convert the character location to a frame buffer address.
    */
    OledMoveTo(xch*dxcoOledFontCur, ych*dycoOledFontCur);

}

/* ------------------------------------------------------------ */
/***    OledGetCursor
**
**  Parameters:
**      pxch        - pointer to variable to receive horizontal position
**      pych        - pointer to variable to receive vertical position
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      Fetch the current cursor position
*/

void
OledGetCursor( int * pxch, int * pych)
    {

    *pxch = xchOledCur;
    *pych = ychOledCur;

}

/* ------------------------------------------------------------ */
/***    OledSetCharUpdate
**
**  Parameters:
**      f       - enable/disable automatic update
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      Set the character update mode. This determines whether
**      or not the display is automatically updated after a
**      character or string is drawn. A non-zero value turns
**      automatic updating on.
*/

void
OledSetCharUpdate(int f)
    {

    fOledCharUpdate = (f != 0) ? 1 : 0;

}

/* ------------------------------------------------------------ */
/***    OledGetCharUpdate
**
**  Parameters:
**      none
**
**  Return Value:
**      returns current character update mode
**
**  Errors:
**      none
**
**  Description:
**      Return the current character update mode.
*/

int
OledGetCharUpdate()
    {

    return fOledCharUpdate;

}

/* ------------------------------------------------------------ */
/***    OledPutChar
**
**  Parameters:
**      ch          - character to write to display
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      Write the specified character to the display at the current
**      cursor position and advance the cursor.
*/

void
OledPutChar(char ch)
    {

    OledDrawGlyph(ch);
    OledAdvanceCursor();

}

/* ------------------------------------------------------------ */
/***    OledPutString
**
**  Parameters:
**      sz      - pointer to the null terminated string
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      Write the specified null terminated character string to the
**      display and advance the cursor.
*/

void
OledPutString(char * sz)
    {

    while (*sz != '\0') {
        if(*sz=='\n'){
            OLEDNewline();
        }
        else{
        OledDrawGlyph(*sz);
        OledAdvanceCursor();
        }
        sz += 1;

    }
    }
/* ------------------------------------------------------------ */
/***    OledDrawGlyph
**
**  Parameters:
**      ch      - character code of character to draw
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      Renders the specified character into the display buffer
**      at the current character cursor location. This does not
**      affect the current character cursor location or the 
**      current drawing position in the display buffer.
*/

void
OledDrawGlyph(char ch)
    {
    u8 *    pbFont;
    u8 *    pbBmp;
    int     ib;

    if ((ch & 0x80) != 0) {
        return;
    }

    if (ch < chOledUserMax) {
        pbFont = pbOledFontUser + ch*cbOledChar;
    }
    else if ((ch & 0x80) == 0) {
        pbFont = pbOledFontCur + (ch-chOledUserMax) * cbOledChar;
    }

    pbBmp = pbOledCur;

    for (ib = 0; ib < dxcoOledFontCur; ib++) {
        *pbBmp++ = *pbFont++;
    }

}

/* ------------------------------------------------------------ */
/***    OledAdvanceCursor
**
**  Parameters:
**      none
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      Advance the character cursor by one character location,
**      wrapping at the end of line and back to the top at the
**      end of the display.
*/

void
OledAdvanceCursor()
    {

    xchOledCur += 1;
    if (xchOledCur >= xchOledMax) {
        xchOledCur = 0;
        ychOledCur += 1;
    }
    if (ychOledCur >= ychOledMax) {
        ychOledCur = 0;
    }

    OledSetCursor(xchOledCur, ychOledCur);

}

/* ------------------------------------------------------------ */
/***    ProcName
**
**  Parameters:
**
**  Return Value:
**
**  Errors:
**
**  Description:
**
*/

/* ------------------------------------------------------------ */

/************************************************************************/
void OLEDNewline(void){
    xchOledCur = 0;
    ychOledCur += 1;
    if(ychOledCur>=ychOledMax){ ychOledCur=0;}
    OledSetCursor(xchOledCur, ychOledCur);
    return;
}


