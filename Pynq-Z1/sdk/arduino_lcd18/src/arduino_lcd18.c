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
 * @file arduino_lcd18.c
 *
 * This is the module for the Adafruit LCD18 on Arduino interface.
 * https://www.adafruit.com/product/802.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- -------- -----------------------------------------------
 * 1.00a pp  11/16/16 release
 *
 * </pre>
 *
 *****************************************************************************/
#include <stdint.h>
#include "xparameters.h"
#include "ST7735.h"
#include "arduino.h"
#include "xgpio.h"
#include "xil_cache.h"
#include "xsysmon.h"
#include "logo.h"

#define CONFIG_IOP_SWITCH       0x1
#define CLEAR_SCREEN            0x3
#define DISPLAY                 0x5
#define DRAW_LINE               0x7
#define PRINT_STRING            0x9
#define FILL_RECTANGLE          0xb
#define READ_BUTTON             0xd

#define XPAR_D13_D0_DEVICE_ID   XPAR_GPIO_0_DEVICE_ID
#define V_REF 3.33
#define SYSMON_DEVICE_ID XPAR_SYSMON_0_DEVICE_ID

void swap_int16_t(int16_t* a, int16_t* b) { 
    int16_t t;
    t = *a; 
    *a = *b; 
    *b = t; 
}
int16_t abs_int16_t(int16_t x){
    if (x >= 0) {
        return x;
    }
    else{
        return -x;
    }
}

XGpio d13_d0_gpio;
u16 reset_dc_d7_to_d0;
static XSysMon SysMonInst;
XSysMon_Config *SysMonConfigPtr;
XSysMon *SysMonInstPtr = &SysMonInst;

int SetupGpio(void) {
    int Status;

    Status = XGpio_Initialize(&d13_d0_gpio, XPAR_D13_D0_DEVICE_ID);
    if (Status != XST_SUCCESS) {
         return XST_FAILURE;
    }

    // set the direction for all signals of channel 1 to be output
    XGpio_SetDataDirection(&d13_d0_gpio, 1, 0x00000000);

    /*
     * write 0 to all data pins
     * reset = 1 -> not in reset state
     * dc = 0    -> in command mode
     */
    reset_dc_d7_to_d0 = 0x200;    
    XGpio_DiscreteWrite(&d13_d0_gpio,1,reset_dc_d7_to_d0);

    return 0;
}

void display(int16_t x_pos, int16_t y_pos, int16_t width, int16_t height, 
             uint16_t *image, int16_t bg, int16_t orientation, 
             int times) {

    int i, x, y, dx, dy;
    x = x_pos;
    y = y_pos;
    dx = 1;
    dy = 1;
    
    ST7735_FillScreen(bg);
    ST7735_SetRotation(orientation);
    if (times==1) {
        // display for 1 time
        ST7735_DrawBitmap(x_pos, y_pos, image, width, height);
    } else {
        // display for multiple time (animation)
        for(i=0; i<times; i++) {
           ST7735_DrawBitmap(x, y, image, width, height);
           x = x + dx;
           y = y + dy;
           if (dy==1)
               ST7735_DrawFastHLine(x-dx-2, y-dy-height, width+3, bg);
           else
               ST7735_DrawFastHLine(x-dx-2, y-dy, width+3, bg); 
           if (dx==1)
               ST7735_DrawFastVLine(x-dx-1, y-dy-height, height+2, bg);
           else
               ST7735_DrawFastVLine(x-dx+width-1, y-dy-height, height+2, bg);
           
           if ((orientation == 1) || (orientation == 3)) {
               if (((x+width) >= 160) || (x < 1))
                   dx = -1*dx;
               if ((y >= 128) || (y <= height))
                   dy = -1*dy;
           } else {
               if (((x+width) >= 128) || (x < 1))
                   dx = -1*dx;
               if ((y >= 160) || (y <= height))
                   dy = -1*dy;
           }
        }
    }
}

void draw_line(int16_t x0, int16_t y0, int16_t x1, int16_t y1, 
               uint16_t color) {
  int16_t steep = abs_int16_t(y1 - y0) > abs_int16_t(x1 - x0);
  if (steep) {
    swap_int16_t(&x0, &y0);
    swap_int16_t(&x1, &y1);
  }

  if (x0 > x1) {
    swap_int16_t(&x0, &x1);
    swap_int16_t(&y0, &y1);
  }

  int16_t dx, dy;
  dx = x1 - x0;
  dy = abs_int16_t(y1 - y0);

  int16_t err = dx / 2;
  int16_t ystep;

  if (y0 < y1) {
    ystep = 1;
  } else {
    ystep = -1;
  }

  for (; x0<=x1; x0++) {
    if (steep) {
        ST7735_DrawPixel(y0, x0, color);
    } else {
        ST7735_DrawPixel(x0, y0, color);
    }
    err -= dy;
    if (err < 0) {
      y0 += ystep;
      err += dx;
    }
  }
}

int main(void)
{
    u32 cmd, xStatus;
    u16 pix_x1, pix_y1, pix_x2, pix_y2, times, orientation;
    u16 color, bgcolor, textsize, width, height;
    u16 background;
    u16 analog_read;
    u8 iop_pins[19];
    char *pt;
    u32 logo_ptr;

    // disable DCache
    Xil_DCacheDisable();

    // initialize SPIs with clk_polarity and clk_phase as 0
    arduino_init(0,0,0,0);

    // SysMon Initialize
    SysMonConfigPtr = XSysMon_LookupConfig(SYSMON_DEVICE_ID);
    if(SysMonConfigPtr == NULL)
        xil_printf("LookupConfig FAILURE\n\r");
    xStatus = XSysMon_CfgInitialize(SysMonInstPtr,SysMonConfigPtr,
                                    SysMonConfigPtr->BaseAddress);
    if(XST_SUCCESS != xStatus)
        xil_printf("CfgInitialize FAILED\r\n");

    // Clear the old status
    XSysMon_GetStatus(SysMonInstPtr);

    /*
     * Configure A0-A5 as GPIO, D0-D9 as GPIO, 
     * D10-D13 as Shared SPI (MISO is not used)
     */
    config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, A_GPIO, A_GPIO, A_GPIO,
                           D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                           D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                           D_SS, D_MOSI, D_GPIO, D_SPICLK);

    SetupGpio();
    Xil_Out32(XPAR_IOP3_MB3_INTR_BASEADDR+4,0x0);
    Xil_Out32(XPAR_IOP3_MB3_INTR_BASEADDR,0x0);

    ST7735_InitR(INITR_REDTAB);
    orientation=3;
    // text color or line color: white
    color=0xffff;
    // background color: pink
    bgcolor=ST7735_BLUE | ST7735_RED;
    background = bgcolor;
    ST7735_FillScreen(bgcolor);
    // orientation: 3
    ST7735_SetRotation(3);
    // use built-in PYNQ Logo of 126x42
    ST7735_DrawBitmap(17,85,logo,126,42);

    while(1) {
        while(MAILBOX_CMD_ADDR==0);
        cmd = MAILBOX_CMD_ADDR;

        switch(cmd) {
            case CONFIG_IOP_SWITCH:
                // Assign default pin configurations
                iop_pins[0] = A_GPIO;
                iop_pins[1] = A_GPIO;
                iop_pins[2] = A_GPIO;
                iop_pins[3] = A_GPIO;
                iop_pins[4] = A_GPIO;
                iop_pins[5] = A_GPIO;
                iop_pins[6] = D_GPIO;
                iop_pins[7] = D_GPIO;
                iop_pins[8] = D_GPIO;
                iop_pins[9] = D_GPIO;
                iop_pins[10] = D_GPIO;
                iop_pins[11] = D_GPIO;
                iop_pins[12] = D_GPIO;
                iop_pins[13] = D_GPIO;
                iop_pins[14] = D_GPIO;
                iop_pins[15] = D_SS;
                iop_pins[16] = D_MOSI;
                iop_pins[17] = MAILBOX_DATA(0);
                iop_pins[18] = D_SPICLK;
                config_arduino_switch(iop_pins[0], iop_pins[1], iop_pins[2], 
                                      iop_pins[3], iop_pins[4], iop_pins[5], 
                                      iop_pins[6], iop_pins[7], iop_pins[8], 
                                      iop_pins[9], iop_pins[10], iop_pins[11],
                                      iop_pins[12], iop_pins[13], 
                                      iop_pins[14], iop_pins[15],
                                      iop_pins[16], iop_pins[17], 
                                      iop_pins[18]);
                MAILBOX_CMD_ADDR = 0x0;
                break;
            case CLEAR_SCREEN:
                ST7735_FillScreen(0);
                background = 0;
                MAILBOX_CMD_ADDR = 0x0;
                break;
            case DISPLAY:
                pix_x1 = MAILBOX_DATA(0);
                pix_y1 = MAILBOX_DATA(1);
                width = MAILBOX_DATA(2);
                height = MAILBOX_DATA(3);
                logo_ptr = MAILBOX_DATA(4) | 0x20000000;
                bgcolor = MAILBOX_DATA(5);
                orientation = MAILBOX_DATA(6);
                times = MAILBOX_DATA(7);
                // display picture
                display(pix_x1, pix_y1, width, height, 
                            (uint16_t *) logo_ptr,bgcolor,orientation,times);
                Xil_Out32(XPAR_IOP3_MB3_INTR_BASEADDR,0x1);
                Xil_Out32(XPAR_IOP3_MB3_INTR_BASEADDR,0x0);
                MAILBOX_CMD_ADDR = 0x0;
                break;
            case DRAW_LINE:
                pix_x1 = MAILBOX_DATA(0);
                pix_y1 = MAILBOX_DATA(1);
                pix_x2 = MAILBOX_DATA(2);
                pix_y2 = MAILBOX_DATA(3);
                color = MAILBOX_DATA(4);
                bgcolor = MAILBOX_DATA(5);
                orientation = MAILBOX_DATA(6);
                // fill screen and set orientation
                if (background!=bgcolor){
                    ST7735_FillScreen(bgcolor);
                    background = bgcolor;
                }
                ST7735_SetRotation(orientation);
                draw_line(pix_x1,pix_y1,pix_x2,pix_y2,color);
                Xil_Out32(XPAR_IOP3_MB3_INTR_BASEADDR,0x1);
                Xil_Out32(XPAR_IOP3_MB3_INTR_BASEADDR,0x0);
                MAILBOX_CMD_ADDR = 0x0;
                break;
            case PRINT_STRING:
                pix_x1 = MAILBOX_DATA(0);
                pix_y1 = MAILBOX_DATA(1);
                color = MAILBOX_DATA(2);
                bgcolor = MAILBOX_DATA(3);
                orientation = MAILBOX_DATA(4);
                pt = (char *)XPAR_IOP3_MB3_LMB_LMB_BRAM_IF_CNTLR_BASEADDR + \
                      0x0F000 + 5*4;
                // fill screen and set orientation
                if (background!=bgcolor){
                    ST7735_FillScreen(bgcolor);
                    background = bgcolor;
                }
                ST7735_SetRotation(orientation);
                // currently only supporting size 1
                textsize = 1;
                ST7735_DrawString(pix_x1,pix_y1,pt,color,bgcolor,textsize);
                Xil_Out32(XPAR_IOP3_MB3_INTR_BASEADDR,0x1);
                Xil_Out32(XPAR_IOP3_MB3_INTR_BASEADDR,0x0);
                MAILBOX_CMD_ADDR = 0x0;
                break;
            case FILL_RECTANGLE:
                pix_x1 = MAILBOX_DATA(0);
                pix_y1 = MAILBOX_DATA(1);
                width = MAILBOX_DATA(2);
                height = MAILBOX_DATA(3);
                color = MAILBOX_DATA(4);
                bgcolor = MAILBOX_DATA(5);
                orientation = MAILBOX_DATA(6);
                // fill screen and set orientation
                if (background!=bgcolor){
                    ST7735_FillScreen(bgcolor);
                    background = bgcolor;
                }
                ST7735_SetRotation(orientation);
                ST7735_FillRect(pix_x1,pix_y1,width,height,color);
                Xil_Out32(XPAR_IOP3_MB3_INTR_BASEADDR,0x1);
                Xil_Out32(XPAR_IOP3_MB3_INTR_BASEADDR,0x0);
                MAILBOX_CMD_ADDR = 0x0;
                break;
            case READ_BUTTON: 
                // read analog on A3
                while ((XSysMon_GetStatus(SysMonInstPtr) & \
                        XSM_SR_EOS_MASK) != XSM_SR_EOS_MASK);
                analog_read = XSysMon_GetAdcData(SysMonInstPtr,
                              XSM_CH_AUX_MIN+15);
                if(analog_read < 0x2000)
                    // left button
                    MAILBOX_DATA(0)=1;
                else if (analog_read < 0x4000)
                    // down button
                    MAILBOX_DATA(0)=2;
                else if (analog_read < 0x6000)
                    // center button
                    MAILBOX_DATA(0)=3;
                else if (analog_read < 0x8000)
                    // right button
                    MAILBOX_DATA(0)=4;
                else if (analog_read < 0xc000)
                    // up button
                    MAILBOX_DATA(0)=5;
                else
                    // no button pressed
                    MAILBOX_DATA(0)=0;
                Xil_Out32(XPAR_IOP3_MB3_INTR_BASEADDR,0x1);
                Xil_Out32(XPAR_IOP3_MB3_INTR_BASEADDR,0x0);
                MAILBOX_CMD_ADDR = 0x0;
                break;
            default:
                MAILBOX_CMD_ADDR = 0x0;
                break;
        }
    }
}
