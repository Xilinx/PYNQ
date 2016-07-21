/************************************************************************/
/*                                                                      */
/*  OledGrph.c  --  OLED Display Graphics Routines                      */
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
/*  06/03/2011(GeneA): created                                          */
/*  04/25/2016(Rock): abs function added                                */
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

#include "OledChar.h"
#include "OledGrph.h"

/* ------------------------------------------------------------ */
/*              Global Variables                                */
/* ------------------------------------------------------------ */
extern int      xcoOledCur;
extern int      ycoOledCur;
extern u8 *     pbOledCur;
extern u8       rgbOledBmp[];
extern int      bnOledCur;
extern u8       clrOledCur;
extern u8 *     pbOledFontUser;
extern u8 *     pbOledFontCur;
extern int      dxcoOledFontCur;
extern int      dycoOledFontCur;

/* ------------------------------------------------------------ */
/*              Local Variables                                 */
/* ------------------------------------------------------------ */

u8  (*pfnDoRop)(u8 bPix, u8 bDsp, u8 mskPix);
int     modOledCur;

/* ------------------------------------------------------------ */
/*              Forward Declarations                            */
/* ------------------------------------------------------------ */

void    OledMoveDown();
void    OledMoveUp();
void    OledMoveRight();
void    OledMoveLeft();
u8      OledRopSet(u8 bPix, u8 bDsp, u8 mskPix);
u8      OledRopOr(u8 bPix, u8 bDsp, u8 mskPix);
u8      OledRopAnd(u8 bPix, u8 bDsp, u8 mskPix);
u8      OledRopXor(u8 bPix, u8 bDsp, u8 mskPix);
int     OledClampXco(int xco);
int     OledClampYco(int yco);

/* ------------------------------------------------------------ */
/*              Procedure Definitions                           */
/* ------------------------------------------------------------ */
/***    OledMoveTo
**
**  Parameters:
**      xco         - x coordinate
**      yco         - y coordinate
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      Set the current graphics drawing position.
*/

void
OledMoveTo(int xco, int yco)
    {

    /* Clamp the specified coordinates to the display surface
    */
    xco = OledClampXco(xco);
    yco = OledClampYco(yco);

    /* Save the current position.
    */
    xcoOledCur = xco;
    ycoOledCur = yco;

    /* Compute the display access parameters corresponding to
    ** the specified position.
    */
    pbOledCur = &rgbOledBmp[((yco/8) * ccolOledMax) + xco];
    bnOledCur = yco & 7;

}

/* ------------------------------------------------------------ */
/***    OledGetPos
**
**  Parameters:
**      pxco    - variable to receive x coordinate
**      pyco    - variable to receive y coordinate
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      Fetch the current graphics drawing position
*/

void
OledGetPos(int * pxco, int * pyco)
    {

    *pxco = xcoOledCur;
    *pyco = ycoOledCur;

}

/* ------------------------------------------------------------ */
/***    OledSetDrawMode
**
**  Parameters:
**      mod     - drawing mode to select
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      Set the specified mode as the current drawing mode.
*/

void
OledSetDrawMode(int mod)
    {

    modOledCur = mod;

    switch(mod) {
        case    modOledSet:
            pfnDoRop = OledRopSet;
            break;

        case    modOledOr:
            pfnDoRop = OledRopOr;
            break;

        case    modOledAnd:
            pfnDoRop = OledRopAnd;
            break;

        case    modOledXor:
            pfnDoRop = OledRopXor;
            break;

        default:
            modOledCur = modOledSet;
            pfnDoRop = OledRopSet;
    }

}

/* ------------------------------------------------------------ */
/***    OledGetDrawMode
**
**  Parameters:
**      none

**  Return Value:
**      returns current drawing mode
**
**  Errors:
**      none
**
**  Description:
**      Get the current drawing mode
*/

int
OledGetDrawMode()
    {

    return modOledCur;

}

/* ------------------------------------------------------------ */
/***    OledDrawPixel
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
**      Set the pixel at the current drawing location to the
**      specified value.
*/

void
OledDrawPixel()
    {

    *pbOledCur = (*pfnDoRop)((clrOledCur << bnOledCur), *pbOledCur, (1<<bnOledCur));

}

/* ------------------------------------------------------------ */
/***    OledGetPixel
**
**  Parameters:
**      none
**
**  Return Value:
**      returns pixel value at current drawing location
**
**  Errors:
**      none
**
**  Description:
**      Return the value of the pixel at the current drawing location
*/

u8
OledGetPixel()
    {

    return (*pbOledCur & (1<<bnOledCur)) != 0 ? 1 : 0;

}

/* ------------------------------------------------------------ */
/***    OledLineTo
**
**  Parameters:
**      xco         - x coordinate
**      yco         - y coordinate
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      Draw a line from the current position to the specified
**      position.
*/

void
OledLineTo(int xco, int yco)
    {
    int     err;
    int     del;
    int     lim;
    int     cpx;
    int     dxco;
    int     dyco;
    void    (*pfnMajor)();
    void    (*pfnMinor)();

    /* Clamp the point to be on the display.
    */
    xco = OledClampXco(xco);
    yco = OledClampYco(yco);

    /* Determine which octant the line occupies
    */
    dxco = xco - xcoOledCur;
    dyco = yco - ycoOledCur;
    if (abs(dxco) >= abs(dyco)) {
        /* Line is x-major
        */
        lim = abs(dxco);
        del = abs(dyco);
        if (dxco >= 0) {
            pfnMajor = OledMoveRight;
        }
        else {
            pfnMajor = OledMoveLeft;
        }

        if (dyco >= 0) {
            pfnMinor = OledMoveDown;
        }
        else {
            pfnMinor = OledMoveUp;
        }
    }
    else {
        /* Line is y-major
        */
        lim = abs(dyco);
        del = abs(dxco);
        if (dyco >= 0) {
            pfnMajor = OledMoveDown;
        }
        else {
            pfnMajor = OledMoveUp;
        }

        if (dxco >= 0) {
            pfnMinor = OledMoveRight;
        }
        else {
            pfnMinor = OledMoveLeft;
        }
    }

    /* Render the line. The algorithm is:
    **      Write the current pixel
    **      Move one pixel on the major axis
    **      Add the minor axis delta to the error accumulator
    **      if the error accumulator is greater than the major axis delta
    **          Move one pixel in the minor axis
    **          Subtract major axis delta from error accumulator
    */
    err = lim/2;
    cpx = lim;
    while (cpx > 0) {
        OledDrawPixel();
        (*pfnMajor)();
        err += del;
        if (err > lim) {
            err -= lim;
            (*pfnMinor)();
        }
        cpx -= 1;
    }

    /* Update the current location variables.
    */
    xcoOledCur = xco;
    ycoOledCur = yco;       

}

/* ------------------------------------------------------------ */
/***    OledDrawRect
**
**  Parameters:
**      xco     - x coordinate of other corner
**      yco     - y coordinate of other corner
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      Draw a rectangle bounded by the current location and
**      the specified location.
*/

void
OledDrawRect(int xco, int yco)
    {
    int     xco1;
    int     yco1;

    /* Clamp the point to be on the display.
    */
    xco = OledClampXco(xco);
    yco = OledClampYco(yco);

    xco1 = xcoOledCur;
    yco1 = ycoOledCur;
    OledLineTo(xco, yco1);
    OledLineTo(xco, yco);
    OledLineTo(xco1, yco);
    OledLineTo(xco1, yco1);
}

/* ------------------------------------------------------------ */
/***    OledGetBmp
**
**  Parameters:
**      dxco        - width of bitmap
**      dyco        - height of bitmap
**      pbBits      - pointer to the bitmap bits    
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      This routine will get the bits corresponding to the
**      rectangle implied by the current location and the
**      specified width and height. The buffer specified
**      by pbBits must be large enough to hold the resulting
**      bytes.
*/

void
OledGetBmp(int dxco, int dyco, u8 * pbBits)
    {
    int     xcoLeft;
    int     xcoRight;
    int     ycoTop;
    int     ycoBottom;
    u8 *    pbDspCur;
    u8 *    pbDspLeft;
    u8 *    pbBmpCur;
    u8 *    pbBmpLeft;
    int     xcoCur;
    int     bnAlign;
    u8  mskEnd;

    /* Set up the four sides of the source rectangle.
    */
    xcoLeft = xcoOledCur;
    xcoRight = xcoLeft + dxco;
    if (xcoRight >= ccolOledMax) {
        xcoRight = ccolOledMax - 1;
    }

    ycoTop = ycoOledCur;
    ycoBottom = ycoTop + dyco;
    if (ycoBottom >= crowOledMax) {
        ycoBottom = crowOledMax - 1;
    }

    bnAlign = ycoTop & 0x07;
    pbDspLeft = &rgbOledBmp[((ycoTop/8) * ccolOledMax) + xcoLeft];
    pbBmpLeft = pbBits;

    while (ycoTop < ycoBottom) {

        if ((ycoTop / 8) == ((ycoBottom-1) / 8)) {
            mskEnd = ((1 << (((ycoBottom-1)&0x07)+1)) - 1);
        }
        else {
            mskEnd = 0xFF;
        }
                                            
        xcoCur = xcoLeft;
        pbDspCur = pbDspLeft;
        pbBmpCur = pbBmpLeft;

        /* Loop through all of the bytes horizontally making up this stripe
        ** of the rectangle.
        */
        if (bnAlign == 0) {
            while (xcoCur < xcoRight) {
                *pbBmpCur = (*pbDspCur) & mskEnd;
                xcoCur += 1;
                pbBmpCur += 1;
                pbDspCur += 1;
            }
        }
        else {
            while (xcoCur < xcoRight) {
                *pbBmpCur = ((*pbDspCur >> bnAlign) |
                            ((*(pbDspCur+ccolOledMax)) << (8-bnAlign))) & mskEnd;
                xcoCur += 1;
                pbBmpCur += 1;
                pbDspCur += 1;
            }
        }

        /* Advance to the next horizontal stripe.
        */
        ycoTop += 8;
        pbDspLeft += ccolOledMax;
        pbBmpLeft += dxco;

    }

}

/* ------------------------------------------------------------ */
/***    OledPutBmp
**
**  Parameters:
**      dxco        - width of bitmap
**      dyco        - height of bitmap
**      pbBits      - pointer to the bitmap bits    
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**      This routine will put the specified bitmap into the display
**      buffer at the current location.
*/

void
OledPutBmp(int dxco, int dyco, u8 * pbBits)
    {
    int     xcoLeft;
    int     xcoRight;
    int     ycoTop;
    int     ycoBottom;
    u8 *    pbDspCur;
    u8 *    pbDspLeft;
    u8 *    pbBmpCur;
    u8 *    pbBmpLeft;
    int     xcoCur;
    u8  bBmp;
    u8  mskEnd;
    u8  mskUpper;
    u8  mskLower;
    int     bnAlign;
    int     fTop;

    /* Set up the four sides of the destination rectangle.
    */
    xcoLeft = xcoOledCur;
    xcoRight = xcoLeft + dxco;
    if (xcoRight >= ccolOledMax) {
        xcoRight = ccolOledMax - 1;
    }

    ycoTop = ycoOledCur;
    ycoBottom = ycoTop + dyco;
    if (ycoBottom >= crowOledMax) {
        ycoBottom = crowOledMax - 1;
    }

    bnAlign = ycoTop & 0x07;
    mskUpper = (1 << bnAlign) - 1;
    mskLower = ~mskUpper;
    pbDspLeft = &rgbOledBmp[((ycoTop/8) * ccolOledMax) + xcoLeft];
    pbBmpLeft = pbBits;
    fTop = 1;

    while (ycoTop < ycoBottom) {
        /* Combine with a mask to preserve any upper bits in the byte that aren't
        ** part of the rectangle being filled.
        ** This mask will end up not preserving any bits for bytes that are in
        ** the middle of the rectangle vertically.
        */
        if ((ycoTop / 8) == ((ycoBottom-1) / 8)) {
            mskEnd = ((1 << (((ycoBottom-1)&0x07)+1)) - 1);
        }
        else {
            mskEnd = 0xFF;
        }
        if (fTop) {
            mskEnd &= ~mskUpper;
        }
                                            
        xcoCur = xcoLeft;
        pbDspCur = pbDspLeft;
        pbBmpCur = pbBmpLeft;

        /* Loop through all of the bytes horizontally making up this stripe
        ** of the rectangle.
        */
        if (bnAlign == 0) {
            while (xcoCur < xcoRight) {
                *pbDspCur = (*pfnDoRop)(*pbBmpCur, *pbDspCur, mskEnd);
                xcoCur += 1;
                pbDspCur += 1;
                pbBmpCur += 1;
            }
        }
        else {
            while (xcoCur < xcoRight) {
                bBmp = ((*pbBmpCur) << bnAlign);
                if (!fTop) {
                    bBmp |= ((*(pbBmpCur - dxco) >> (8-bnAlign)) & ~mskLower);
                }
                bBmp &= mskEnd;
                *pbDspCur = (*pfnDoRop)(bBmp, *pbDspCur, mskEnd);
                xcoCur += 1;
                pbDspCur += 1;
                pbBmpCur += 1;
            }
        }

        /* Advance to the next horizontal stripe.
        */
        ycoTop = 8*((ycoTop/8)+1);
        pbDspLeft += ccolOledMax;
        pbBmpLeft += dxco;
        fTop = 0;

    }

}

/* ------------------------------------------------------------ */
/***    OledDrawChar
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
OledDrawChar(char ch)
    {
    u8 *    pbFont;

    if ((ch & 0x80) != 0) {
        return;
    }

    if (ch < chOledUserMax) {
        pbFont = pbOledFontUser + ch*cbOledChar;
    }
    else if ((ch & 0x80) == 0) {
        pbFont = pbOledFontCur + (ch-chOledUserMax) * cbOledChar;
    }

    OledPutBmp(dxcoOledFontCur, dycoOledFontCur, pbFont);

    xcoOledCur += dxcoOledFontCur;

}

/* ------------------------------------------------------------ */
/***    OledDrawString
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
OledDrawString(char * sz)
    {

    while (*sz != '\0') {
        OledDrawChar(*sz);
        sz += 1;
    }
}

/* ------------------------------------------------------------ */
/*              Internal Support Routines                       */
/* ------------------------------------------------------------ */
/***    OledRopSet
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

u8
OledRopSet(u8 bPix, u8 bDsp, u8 mskPix)
    {

    return (bDsp & ~mskPix) | (bPix & mskPix);

}

/* ------------------------------------------------------------ */
/***    OledRopOr
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

u8
OledRopOr(u8 bPix, u8 bDsp, u8 mskPix)
    {

    return bDsp | (bPix & mskPix);

}

/* ------------------------------------------------------------ */
/***    OledRopAnd
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

u8
OledRopAnd(u8 bPix, u8 bDsp, u8 mskPix)
    {

    return bDsp & (bPix & mskPix);

}

/* ------------------------------------------------------------ */
/***    OledRopXor
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

u8
OledRopXor(u8 bPix, u8 bDsp, u8 mskPix)
    {

    return bDsp ^ (bPix & mskPix);

}

/* ------------------------------------------------------------ */
/***    OledMoveUp
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
**      Updates global variables related to current position on the
**      display.
*/

void
OledMoveUp()
    {

    /* Go up one bit position in the current byte.
    */
    bnOledCur -= 1;

    /* If we have gone off the end of the current byte
    ** go up 1 page.
    */
    if (bnOledCur < 0) {
        bnOledCur = 7;
        pbOledCur -= ccolOledMax;
        /* If we have gone off of the top of the display,
        ** go back down.
        */
        if (pbOledCur < rgbOledBmp) {
            pbOledCur += ccolOledMax;
        }
    }
}

/* ------------------------------------------------------------ */
/***    OledMoveDown
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
**      Updates global variables related to current position on the
**      display.
*/

void
OledMoveDown()
    {

    /* Go down one bit position in the current byte.
    */
    bnOledCur += 1;

    /* If we have gone off the end of the current byte,
    ** go down one page in the display memory.
    */
    if (bnOledCur > 7) {
        bnOledCur = 0;
        pbOledCur += ccolOledMax;
        /* If we have gone off the end of the display memory
        ** go back up a page.
        */
        if (pbOledCur >= rgbOledBmp+cbOledDispMax) {
            pbOledCur -= ccolOledMax;
        }
    }
}

/* ------------------------------------------------------------ */
/***    OledMoveLeft
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
**      Updates global variables related to current position on the
**      display.
*/

void
OledMoveLeft()
    {

    /* Are we at the left edge of the display already
    */
    if (((pbOledCur - rgbOledBmp) & (ccolOledMax-1)) == 0) {
        return;
    }

    /* Not at the left edge, so go back one byte.
    */
    pbOledCur -= 1;

}

/* ------------------------------------------------------------ */
/***    OledMoveRight
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
**      Updates global variables related to current position on the
**      display.
*/

void
OledMoveRight()
    {

    /* Are we at the right edge of the display already
    */
    if (((pbOledCur-rgbOledBmp) & (ccolOledMax-1)) == (ccolOledMax-1)) {
        return;
    }

    /* Not at the right edge, so go forward one byte
    */
    pbOledCur += 1;

}

/* ------------------------------------------------------------ */
/***    OledClampXco
**
**  Parameters:
**      xco     - x value to clamp
**
**  Return Value:
**      Returns clamped x value
**
**  Errors:
**      none
**
**  Description:
**      This routine forces the x value to be on the display.
*/

int
OledClampXco(int xco)
    {
    if (xco < 0) {
        xco = 0;
    }
    if (xco >= ccolOledMax) {
        xco = ccolOledMax-1;
    }

    return xco;

}

/* ------------------------------------------------------------ */
/***    OledClampYco
**
**  Parameters:
**      yco     - y value to clamp
**
**  Return Value:
**      Returns clamped y value
**
**  Errors:
**      none
**
**  Description:
**      This routine forces the y value to be on the display.
*/

int
OledClampYco(int yco)
    {
    if (yco < 0) {
        yco = 0;
    }
    if (yco >= crowOledMax) {
        yco = crowOledMax-1;
    }

    return yco;

}

/* ------------------------------------------------------------ */
/***    abs
**
**  Parameters:
**      x     - an integer to convert
**
**  Return Value:
**      Returns the absolute value
**
**  Errors:
**      none
**
**  Description:
**      none
*/

int
abs(int x)
    {
    if (x >= 0) {
        return x;
    }
    else{
        return -x;
    }
}

/* ------------------------------------------------------------ */

/************************************************************************/

