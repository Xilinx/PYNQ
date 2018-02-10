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
 * 2.10  yrq 01/12/18 io_switch refactor
 *
 * </pre>
 *
 *****************************************************************************/

#include "xparameters.h"
#include "xil_io.h"
#include "OledChar.h"
#include "OledGrph.h"
#include "circular_buffer.h"
#include "spi.h"
#include "timer.h"
#include "gpio.h"

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

//gpio reset_pin;
//gpio mode_pin;
//gpio vbat_pin;
//gpio vddc_pin;
gpio control_pins;
spi lcd_spi;
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
    u32 cmd;

    //mode_pin = gpio_open(4);
    //reset_pin = gpio_open(5);
    //vbat_pin = gpio_open(6);
    //vddc_pin = gpio_open(7);
    control_pins = gpio_open_device(0);
    control_pins = gpio_configure(control_pins, 4, 7, 1);
    gpio_set_direction(control_pins, 0);
    lcd_spi = spi_open(3,2,1,0);
    lcd_spi = spi_configure(lcd_spi, 0, 0);

    //gpio_set_direction(mode_pin, GPIO_OUT);
    //gpio_set_direction(reset_pin, GPIO_OUT);
    //gpio_set_direction(vbat_pin, GPIO_OUT);
    //gpio_set_direction(vddc_pin, GPIO_OUT);

    pinmask = 0;
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
    //gpio_write(reset_pin, RST_INACTIVE);
    //gpio_write(vbat_pin, VBAT_INACTIVE);
    //gpio_write(mode_pin, COMMAND_MODE);
    //gpio_write(vddc_pin, VDDC_ACTIVE);
    pinmask |= (RST_INACTIVE | VBAT_INACTIVE);
    pinmask &= ~(COMMAND_MODE_LOW|VDDC_ACTIVE_LOW);
    // command mode, reset inactive
    gpio_write(control_pins, pinmask);
    delay_ms(1);

    // send display off command
    WriteBuffer[0]=0xAE;
    spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);
    delay_ms(1);

    // reset the screen
    pinmask |= (VBAT_INACTIVE);
    pinmask &= ~(COMMAND_MODE_LOW|RST_ACTIVE_LOW|VDDC_ACTIVE_LOW);
    // command mode, reset active
    gpio_write(control_pins, pinmask);

    delay_ms(1);
    pinmask |= ( RST_INACTIVE | VBAT_INACTIVE);
    pinmask&=~(COMMAND_MODE_LOW|VDDC_ACTIVE_LOW);
    gpio_write(control_pins, pinmask);

    // send charge pump and set pre charge period commands
    WriteBuffer[0]=0x8D; // charge buffer 1
    spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);
    WriteBuffer[0]=0x14; // charge buffer 2
    spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);
    WriteBuffer[0]=0xD9; // charge buffer 3
    spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);
    WriteBuffer[0]=0xF1; // charge buffer 4
    spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);

    // turn on VBAT and wait 100ms (VBAT is always on)
    pinmask |= ( RST_INACTIVE);
    pinmask&=~(COMMAND_MODE_LOW|VBAT_ACTIVE_LOW|VDDC_ACTIVE_LOW);
    gpio_write(control_pins, pinmask);
    delay_ms(100);

    // send invert display and sequential COM config commands
    WriteBuffer[0]=0xA1; // invert charge buffer 1
    spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);
    WriteBuffer[0]=0xC8; // invert charge buffer 2
    spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);
    WriteBuffer[0]=0xDA; // invert charge buffer 3
    spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);
    WriteBuffer[0]=0x20; // invert charge buffer 4
    spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);

    // send display on command
    WriteBuffer[0]=0xAF; // display ON
    spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);
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
        gpio_write(control_pins, pinmask);
        // Set the page address
        WriteBuffer[0]=0x22; // set page command
        spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);
        WriteBuffer[0]=ipag; // set page number
        spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);
        // Start at the left column
        WriteBuffer[0]=0x00; // set low nibble of column
        spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);
        WriteBuffer[0]=0x10; // set high nibble of column
        spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);
        // set back to data mode
        pinmask |= (RST_INACTIVE | DATA_MODE);
        pinmask&=~(VBAT_ACTIVE_LOW|VDDC_ACTIVE_LOW);
        gpio_write(control_pins, pinmask);

        // Copy this memory page of display data.
        for (i = 0; i < ccolOledMax; i += 1) {
            WriteBuffer[0]=pb[i];
            spi_transfer(lcd_spi, (const char*)WriteBuffer, NULL, 1);
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