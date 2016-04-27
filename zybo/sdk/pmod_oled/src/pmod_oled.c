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
 * IOP code (MicroBlaze) for PMOD OLED.
 * PMOD OLED is write only, and has IIC interface.
 * Switch configuration is done within this program, PMOD should
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
 *
 * </pre>
 *
 *****************************************************************************/

#include "xparameters.h"
#include "xgpio.h"
#include "xspi_l.h"
#include "OledChar.h"
#include "OledGrph.h"
#include "FillPat.h"
#include "pmod.h"

#define SPI_BASEADDR XPAR_SPI_0_BASEADDR // base address of QSPI[0]
/* 
 *  Passed parameters in MAILBOX_WRITE_CMD
 *      bits 31:8 => not used
 *      bit 7 => draw a filled rectangle
 *      bit 6 => draw square
 *      bit 5 => draw rectangle
 *      bit 4 => draw line
 *      bit 3 => print string
 *      bit 2 => print char
 *      bit 1 => clear display
 *      bit 0 => 1 command issued, 0 command completed
 *
 *  Passed parameters in MAILBOX_DATA
 *      Char mode =>    length (must be 1), x_position, y_position
 *      String mode =>  length (number of characters to be printed)
                        x_position, y_position
 *      Line mode =>    startx_position, starty_position, 
                        endx_position, endy_position
 *      Rectangle mode =>   startx_position, starty_position, 
                            endx_position, endy_position
 *      Square mode =>      startx_position, starty_position, size in pixels
 *      Filled mode =>      startx_position, starty_position, 
                            endx_position, endy_position, filled pattern
 *  Patterns 0 to 7
 *      iptnBlank       0
 *      iptnSolid       1
 *      iptnCross       2
 *      iptnSpekOpen    3
 *      iptnSpekTight   4
 *      iptnCirclesOpen 5
 *      iptnCircleBar   6
 *      iptnCarrots     7
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

#define BUFFER_SIZE      6

u8 WriteBuffer[BUFFER_SIZE];

/************************** Function Prototypes ******************************/
void OLED_Init(void);
void OledSetBuffer(void);
void OledClearBuffer(void);
void OledUpdate(void);

int EmptyBuffer(void);
void OledDvrInit(void);
int StoreBuff(void);

/************************** Global Variables *****************************/
extern u8 rgbOledFont0[];
extern u8 rgbOledFontUser[];
extern u8 rgbFillPat[];

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
u8 * pbOledPatCur;
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

void delay_ms(u32 ms_count)
{
    u32 count;
    for (count = 0; count < ((ms_count * 2500) + 1); count++)
    {
        asm("nop");
    }
}

void delay(void) {
    int i=0;
    for(i=0;i<7;i++);
}

void my_spi_transfer(u32 BaseAddress, int bytecount) {
    int i;

    Xil_Out32(BaseAddress+XSP_CR_OFFSET,0x186);
    Xil_Out32(BaseAddress+XSP_SSR_OFFSET, 0xfe);
    for (i=0; i<bytecount; i++)
    {
        Xil_Out32(BaseAddress+XSP_DTR_OFFSET, WriteBuffer[i]);
    }
    Xil_Out32(BaseAddress+XSP_CR_OFFSET,0x086);
    while(((Xil_In32(BaseAddress+XSP_SR_OFFSET) & 0x04)) != 0x04);
    delay();
    // Slave de-select
    Xil_Out32(BaseAddress+XSP_SSR_OFFSET, 0xff);
}

void SpiInit(void) {
    u32 Control;

    // Reset SPI
    XSpi_WriteReg(SPI_BASEADDR, XSP_SRR_OFFSET, 0xa);
    // Master mode
    Control = Xil_In32(SPI_BASEADDR+XSP_CR_OFFSET);
    Control |= XSP_CR_MASTER_MODE_MASK; // Master Mode
    Control |= XSP_CR_ENABLE_MASK; // Enable SPI
    Control |= XSP_INTR_SLAVE_MODE_MASK; // Slave select manually
    Control |= XSP_CR_TRANS_INHIBIT_MASK; // Disable Transmitter
    Xil_Out32(SPI_BASEADDR+XSP_CR_OFFSET, Control);
}

void clear_display(void) {
    OledClearBuffer();
    OledUpdate();
}

void print_char(void) {
    int x_position, y_position;
    char ch;

    x_position=MAILBOX_DATA(1);
    y_position=MAILBOX_DATA(2);
    ch=(u8) MAILBOX_DATA(3);
    OledSetCursor(x_position, y_position);
    OledPutChar(ch);
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

void draw_filled_rectangle () {
    int x1_position, y1_position, x2_position, y2_position;
    u8 pattern;

    x1_position=MAILBOX_DATA(0);
    y1_position=MAILBOX_DATA(1);
    x2_position=MAILBOX_DATA(2);
    y2_position=MAILBOX_DATA(3);
    pattern=(u8)MAILBOX_DATA(4);
    OledSetFillPattern(&pattern);
    OledMoveTo(x1_position, y1_position);
    OledFillRect(x2_position,y2_position);
    OledUpdate();
}

void draw_square () {
    int x1_position, y1_position, x2_position, y2_position, size;

    x1_position=MAILBOX_DATA(0);
    y1_position=MAILBOX_DATA(1);
    size=MAILBOX_DATA(2);
    x2_position=x1_position+size;
    y2_position=y1_position+size;
    OledMoveTo(x1_position, y1_position);
    OledDrawRect(x2_position,y2_position);
    OledUpdate();
}

int process_cmd (u8 mode){
    switch(mode) {
        case 1:clear_display(); break;  // clear display
        case 2:print_char(); break; // print a char
        case 3:print_string(); break; // print a string
        case 4:draw_line(); break; // draw a line
        case 5:draw_rectangle(); break; // draw a rectangle
        case 6:draw_square(); break; // draw a square
        case 7:draw_filled_rectangle(); break; // draw a filled rectangle
    }
    return 0;
}

int main (void) {
    int Status;
    u8 mode;
    u32 cmd;

    // initialize GPIO driver
    Status = XGpio_Initialize(&Gpio, XPAR_GPIO_0_DEVICE_ID);
    if (Status != XST_SUCCESS) {
      return XST_FAILURE;
    }

    // set data direction for GPIO
    XGpio_SetDataDirection(&Gpio, GPIO_CHANNEL, ~(VBAT | VDDC | RST | DC));

    /*
     *  Configuring PMOD IO Switch to connect to SPI[0].SS to pmod bit 0,
     *  SPI[0].MOSI to pmod bit 1, and SPI[0].SCLK to pmod bit 3
     *  rest of the bits are configured to default gpio channels
     *  i.e. gpio[7] to pmod bit 2, gpio[0] to pmod bit 4, etc.
     */
    
    // isolate configuration port by writing 0 to slv_reg1[31]
    Xil_Out32(SWITCH_BASEADDR+4,0x00000000);
    Xil_Out32(SWITCH_BASEADDR,0x3210A7CD);
    // Enable configuration by writing 1 to slv_reg1[31]
    Xil_Out32(SWITCH_BASEADDR+4,0x80000000); 

    SpiInit();

    // initialize OLED device and driver code
    pinmask=0;
    OLED_Init();
    OledDvrInit();
    OledClearBuffer();
    OledUpdate();
    while(1){
        while((MAILBOX_CMD_ADDR & 0x01)==0);
        cmd = MAILBOX_CMD_ADDR;
        mode=0;
        if((cmd >> 1) & 0x01)
            mode=1;
        else if((cmd >> 2) & 0x01)
            mode=2;
        else if((cmd >> 3) & 0x01)
            mode=3;
        else if((cmd >> 4) & 0x01)
            mode=4;
        else if((cmd >> 5) & 0x01)
            mode=5;
        else if((cmd >> 6) & 0x01)
            mode=6;
        else if((cmd >> 7) & 0x01)
            mode=7;
        Status=process_cmd(mode);
        MAILBOX_CMD_ADDR = 0x0;
    }
    return Status;
}

void OLED_Init(void) {

    // Apply power to VCC, command mode, inactive reset pins
    pinmask |= (RST_INACTIVE | VBAT_INACTIVE);
    pinmask &= ~(COMMAND_MODE_LOW|VDDC_ACTIVE_LOW);
    // command mode, reset inactive
    XGpio_DiscreteWrite(&Gpio, GPIO_CHANNEL, pinmask);
    delay_ms(1);

    // send display off command
    WriteBuffer[0]=0xAE;
    my_spi_transfer(SPI_BASEADDR, 1);

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
    my_spi_transfer(SPI_BASEADDR, 1);
    WriteBuffer[0]=0x14; // charge buffer 2
    my_spi_transfer(SPI_BASEADDR, 1);
    WriteBuffer[0]=0xD9; // charge buffer 3
    my_spi_transfer(SPI_BASEADDR, 1);
    WriteBuffer[0]=0xF1; // charge buffer 4
    my_spi_transfer(SPI_BASEADDR, 1);

    // turn on VBAT and wait 100ms (VBAT is always on)
    pinmask |= ( RST_INACTIVE);
    pinmask&=~(COMMAND_MODE_LOW|VBAT_ACTIVE_LOW|VDDC_ACTIVE_LOW);
    XGpio_DiscreteWrite(&Gpio, GPIO_CHANNEL, pinmask);
    delay_ms(100);

    // send invert display and sequential COM config commands
    WriteBuffer[0]=0xA1; // invert charge buffer 1
    my_spi_transfer(SPI_BASEADDR, 1);
    WriteBuffer[0]=0xC8; // invert charge buffer 2
    my_spi_transfer(SPI_BASEADDR, 1);
    WriteBuffer[0]=0xDA; // invert charge buffer 3
    my_spi_transfer(SPI_BASEADDR, 1);
    WriteBuffer[0]=0x20; // invert charge buffer 4
    my_spi_transfer(SPI_BASEADDR, 1);

    // send display on command
    WriteBuffer[0]=0xAF; // display ON
    my_spi_transfer(SPI_BASEADDR, 1);
}

void OledSetBuffer() {
    int ib;
    u8 * pb;

    pb = rgbOledBmp;

    // Fill the memory buffer with 0.
    for (ib = 0; ib < cbOledDispMax; ib++)
      *pb++ = 0xFF;
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
        my_spi_transfer(SPI_BASEADDR, 1);
        WriteBuffer[0]=ipag; // set page number
        my_spi_transfer(SPI_BASEADDR, 1);
        // Start at the left column
        WriteBuffer[0]=0x00; // set low nibble of column
        my_spi_transfer(SPI_BASEADDR, 1);
        WriteBuffer[0]=0x10; // set high nibble of column
        my_spi_transfer(SPI_BASEADDR, 1);
        // set back to data mode
        pinmask |= (RST_INACTIVE | DATA_MODE);
        pinmask&=~(VBAT_ACTIVE_LOW|VDDC_ACTIVE_LOW);
        XGpio_DiscreteWrite(&Gpio, GPIO_CHANNEL, pinmask);

        // Copy this memory page of display data.
        for (i = 0; i < ccolOledMax; i += 1) {
            WriteBuffer[0]=pb[i];
            my_spi_transfer(SPI_BASEADDR, 1);
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

    // Set the default foreground draw color and fill pattern
    clrOledCur = 0x01;
    pbOledPatCur = rgbFillPat;
    OledSetDrawMode(modOledSet);

    // Default the character routines to automatically update the display
    fOledCharUpdate = 1;
}
