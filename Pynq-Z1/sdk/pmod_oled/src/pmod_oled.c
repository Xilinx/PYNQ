/******************************************************************************
 *  Copyright (c) 2016, Xilinx, Inc.
 *  All rights reserved.
 * 
 *  Redistribution and use in source and binary forms, with or without 
 *  modification, are permitted provided that the following conditions are met:
 *
 *  1.  Redistributions of source code must retain the above copyright notice, 
 *     this list of conditions and the following disclaimer.
 *
 *  2.  Redistributions in binary form must reproduce the above copyright 
 *      notice, this list of conditions and the following disclaimer in the 
 *      documentation and/or other materials provided with the distribution.
 *
 *  3.  Neither the name of the copyright holder nor the names of its 
 *      contributors may be used to endorse or promote products derived from 
 *      this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 *  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
 *  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 *  OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 *  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
 *  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
 *  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *****************************************************************************/
/******************************************************************************
 *
 *
 * @file pmod_oled.c
 *
 * IOP code (MicroBlaze) for Pmod OLED.
 * Pmod OLED is write only, and has IIC interface.
 * Switch configuration is done within this program, Pmod should
 * be plugged into upper row of connector
 * The PmodOLED is 128x32 pixel monochrome organic LED (OLED) panel powered by
 * SSD1306. Users can program the device through SPI.
 * http://store.digilentinc.com/pmodoled-organic-led-graphic-display/
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a gs  11/19/15 release
 * 1.00b yrq 05/27/16 reduce program size, use pmod_init()
 *
 * </pre>
 *
 *****************************************************************************/

#include "xparameters.h"
#include "xgpio.h"
#include "xspi_l.h"
#include "OledChar.h"
#include "OledGrph.h"
#include "pmod.h"

#define SPI_BASEADDR XPAR_SPI_0_BASEADDR // base address of QSPI[0]

#define CLEAR_DISPLAY       0x1
#define PRINT_STRING        0x3
#define DRAW_LINE           0x5
#define DRAW_RECT           0x7

/*
 *  Passed parameters in MAILBOX_DATA
 *      String mode =>      length (number of characters to be printed)
                            x_position, y_position
 *      Line mode =>        startx_position, starty_position, 
                            endx_position, endy_position
 *      Rectangle mode =>   startx_position, starty_position, 
                            endx_position, endy_position
 */


// constants used to write to GPIO pins
#define RST              0x2
#define DC               0x1
#define VDDC             0x4
#define VBAT             0x8
#define VBAT_ACTIVE      0
#define VDDC_ACTIVE      0
#define VBAT_INACTIVE    8
#define VDDC_INACTIVE    4
#define RST_INACTIVE     2
#define RST_ACTIVE_LOW   2
#define RST_ACTIVE       0
#define COMMAND_MODE     0
#define DATA_MODE        1

#define TABLE_OFFSET     6
#define VBAT_ACTIVE_LOW  8
#define VDDC_ACTIVE_LOW  4
#define COMMAND_MODE_LOW 1

#define GPIO_CHANNEL     1
#define BUFFER_SIZE      1

u8 WriteBuffer[BUFFER_SIZE];

/************************** Function Prototypes ******************************/
void OledInit(void);
void OledClearBuffer(void);
void OledUpdate(void);
void OledDvrInit(void);

/************************** Global Variables *****************************/
extern u8 rgbOledFont0[];
extern u8 rgbOledFontUser[];

extern int xchOledMax;
extern int ychOledMax;

/* 
 *  Coordinates of current pixel location on the display. The origin
 *  is at the upper left of the display. X increases to the right
 *  and y increases going down. 
 */

int xcoOledCur;
int ycoOledCur;
//address of byte corresponding to current location
u8 * pbOledCur;
//bit number of bit corresponding to current location
int bnOledCur;
//drawing color to use
u8 clrOledCur;
//current fill pattern
int fOledCharUpdate;
int dxcoOledFontCur;
int dycoOledFontCur;
u8 * pbOledFontCur;
u8 * pbOledFontUser;
u8 rgbOledBmp[cbOledDispMax];

// GPIO instance
XGpio Gpio;
// store pin values for friendly writes to GPIO
u32 pinmask;

void clear_display(void) {
    OledClearBuffer();
    OledUpdate();
}

void print_string(void) {
    int x_position, y_position, length;
    char ch[64];
    int i;

    length=MAILBOX_DATA(0);
    x_position=MAILBOX_DATA(1);
    y_position=MAILBOX_DATA(2);
    OledSetCursor(x_position, y_position);
    for(i=0; i<length; i++){
        ch[i] = MAILBOX_DATA(3+i);
    }
    ch[i]='\0'; // make sure it is null terminated string
    OledPutString(ch);
    OledUpdate();
}

void draw_line () {
    int x1_position, y1_position, x2_position, y2_position;

    x1_position=MAILBOX_DATA(0);
    y1_position=MAILBOX_DATA(1);
    x2_position=MAILBOX_DATA(2);
    y2_position=MAILBOX_DATA(3);
    OledMoveTo(x1_position, y1_position);
    OledLineTo(x2_position,y2_position);
    OledUpdate();
}

void draw_rectangle () {
    int x1_position, y1_position, x2_position, y2_position;

    x1_position=MAILBOX_DATA(0);
    y1_position=MAILBOX_DATA(1);
    x2_position=MAILBOX_DATA(2);
    y2_position=MAILBOX_DATA(3);
    OledMoveTo(x1_position, y1_position);
    OledDrawRect(x2_position,y2_position);
    OledUpdate();
}

int main (void) {
    int Status;
    u32 cmd;
    
    // initialize GPIO driver
    Status = XGpio_Initialize(&Gpio, XPAR_GPIO_0_DEVICE_ID);
    if (Status != XST_SUCCESS) {
      return XST_FAILURE;
    }
    // set data direction for GPIO
    XGpio_SetDataDirection(&Gpio, GPIO_CHANNEL, ~(VBAT | VDDC | RST | DC));
    
    // Initialize pmod
    pmod_init(0,0);
    /*
     *  Configuring Pmod IO Switch to connect to SPI[0].SS to pmod bit 0,
     *  SPI[0].MOSI to pmod bit 1, and SPI[0].SCLK to pmod bit 3
     *  rest of the bits are configured to default gpio channels
     */
    config_pmod_switch(SS,MOSI,GPIO_7,SPICLK,
                       GPIO_0,GPIO_1,GPIO_2,GPIO_3);
    
    // initialize OLED device and driver code
    pinmask=0;
    OledInit();
    OledDvrInit();
    OledClearBuffer();
    OledUpdate();
    while(1){
        while(MAILBOX_CMD_ADDR==0);
        cmd = MAILBOX_CMD_ADDR;
        
        switch(cmd){
            case CLEAR_DISPLAY:
                clear_display();
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            case PRINT_STRING:
                print_string();
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            case DRAW_LINE:
                draw_line();
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            case DRAW_RECT:
                draw_rectangle();
                MAILBOX_CMD_ADDR = 0x0;
                break;
            
            default:
                MAILBOX_CMD_ADDR = 0x0;
                break;
            }
    }
    return 0;
}

void OledInit(void) {

    // Apply power to VCC, command mode, inactive reset pins
    pinmask |= (RST_INACTIVE | VBAT_INACTIVE);
    pinmask &= ~(COMMAND_MODE_LOW|VDDC_ACTIVE_LOW);
    // command mode, reset inactive
    XGpio_DiscreteWrite(&Gpio, GPIO_CHANNEL, pinmask);
    delay_ms(1);

    // send display off command
    WriteBuffer[0]=0xAE;
    spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);

    // reset the screen
    pinmask |= (VBAT_INACTIVE);
    pinmask &= ~(COMMAND_MODE_LOW|RST_ACTIVE_LOW|VDDC_ACTIVE_LOW);

    // command mode, reset active
    XGpio_DiscreteWrite(&Gpio, GPIO_CHANNEL, pinmask);

    delay_ms(1);
    pinmask |= ( RST_INACTIVE | VBAT_INACTIVE);
    pinmask&=~(COMMAND_MODE_LOW|VDDC_ACTIVE_LOW);
    XGpio_DiscreteWrite(&Gpio, GPIO_CHANNEL, pinmask);

    // send charge pump and set pre charge period commands
    WriteBuffer[0]=0x8D; // charge buffer 1
    spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);
    WriteBuffer[0]=0x14; // charge buffer 2
    spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);
    WriteBuffer[0]=0xD9; // charge buffer 3
    spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);
    WriteBuffer[0]=0xF1; // charge buffer 4
    spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);

    // turn on VBAT and wait 100ms (VBAT is always on)
    pinmask |= ( RST_INACTIVE);
    pinmask&=~(COMMAND_MODE_LOW|VBAT_ACTIVE_LOW|VDDC_ACTIVE_LOW);
    XGpio_DiscreteWrite(&Gpio, GPIO_CHANNEL, pinmask);
    delay_ms(100);

    // send invert display and sequential COM config commands
    WriteBuffer[0]=0xA1; // invert charge buffer 1
    spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);
    WriteBuffer[0]=0xC8; // invert charge buffer 2
    spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);
    WriteBuffer[0]=0xDA; // invert charge buffer 3
    spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);
    WriteBuffer[0]=0x20; // invert charge buffer 4
    spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);

    // send display on command
    WriteBuffer[0]=0xAF; // display ON
    spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);
}

void OledClearBuffer() {
    int ib;
    u8 * pb;
    pb = rgbOledBmp;
    OledSetCursor(0, 0);

    // Fill the memory buffer with 0.
    for (ib = 0; ib < cbOledDispMax; ib++)
      *pb++ = 0x00;
}

void OledUpdate(void) {
    u8  ipag;
    int i;
    u8 * pb;
    pb = rgbOledBmp;

    // update oled with bitmap
    for (ipag = 0; ipag < cpagOledMax; ipag++) {
        // set pin to command mode
        pinmask |= (RST_INACTIVE);
        pinmask&=~(COMMAND_MODE_LOW|VBAT_ACTIVE_LOW|VDDC_ACTIVE_LOW);
        XGpio_DiscreteWrite(&Gpio, GPIO_CHANNEL, pinmask);
        // Set the page address
        WriteBuffer[0]=0x22; // set page command
        spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);
        WriteBuffer[0]=ipag; // set page number
        spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);
        // Start at the left column
        WriteBuffer[0]=0x00; // set low nibble of column
        spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);
        WriteBuffer[0]=0x10; // set high nibble of column
        spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);
        // set back to data mode
        pinmask |= (RST_INACTIVE | DATA_MODE);
        pinmask&=~(VBAT_ACTIVE_LOW|VDDC_ACTIVE_LOW);
        XGpio_DiscreteWrite(&Gpio, GPIO_CHANNEL, pinmask);

        // Copy this memory page of display data.
        for (i = 0; i < ccolOledMax; i += 1) {
            WriteBuffer[0]=pb[i];
            spi_transfer(SPI_BASEADDR, 1, NULL, WriteBuffer);
        }
        pb += ccolOledMax;
    }
}

void OledDvrInit() {
    int ib;

    // Init the parameters for the default font
    dxcoOledFontCur = cbOledChar;
    dycoOledFontCur = 8;
    pbOledFontCur = rgbOledFont0;
    pbOledFontUser = rgbOledFontUser;

    for (ib = 0; ib < cbOledFontUser; ib++)
      rgbOledFontUser[ib] = 0;

    xchOledMax = ccolOledMax / dxcoOledFontCur;
    ychOledMax = crowOledMax / dycoOledFontCur;

    // Set the default character cursor position
    OledSetCursor(0, 0);

    // Set the default foreground draw color
    clrOledCur = 0x01;
    OledSetDrawMode(modOledSet);

    // Default the character routines to automatically update the display
    fOledCharUpdate = 1;
}
