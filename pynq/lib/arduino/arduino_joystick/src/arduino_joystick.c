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
 * @file arduino_joystick.c
 *
 * IOP code (MicroBlaze) for joystick shield on Arduino interface.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- -------- -----------------------------------------------
 * 1.00a vg  09/22/17 initial support
 * 2.10  yrq 03/06/18 fix based on new API
 *
 * </pre>
 *
 *****************************************************************************/

#include "xparameters.h"
#include "circular_buffer.h"
#include "gpio.h"
#include "xsysmon.h"

// Mailbox commands
#define CONFIG_IOP_SWITCH  0x1
#define GET_RAW_DATA_X     0x3
#define GET_RAW_DATA_Y     0x5
#define GET_DIRECTION      0x7
#define GET_BUTTONS        0x9

/******************************************************************************
 *
 * Channels to be read is indicated in Mailbox command starting with bit[8] to
 * bit[13] as follows:
 * bit[8] = A0
 * bit[9] = A1
 * bit[10] = A2
 * bit[11] = A3
 * bit[12] = A4
 * bit[13] = A5
 *
 *****************************************************************************/

#define SYSMON_DEVICE_ID XPAR_SYSMON_0_DEVICE_ID

typedef enum directions {
up = 0, 
right_up, 
right, 
right_down, 
down, 
left_down, 
left, 
left_up,
centered
}direction_e; 

int X_THRESHOLD_LOW = 25000;
int X_THRESHOLD_HIGH = 39000;    

int Y_THRESHOLD_LOW = 25000;
int Y_THRESHOLD_HIGH = 39000;

static XSysMon SysMonInst;
XSysMon_Config *SysMonConfigPtr;
XSysMon *SysMonInstPtr = &SysMonInst;

static gpio gpio_buttons[5];

// Function to get number of set bits in binary digits
int count_set_bits(unsigned int n)
{
  unsigned int count = 0;
  while(n){
    count += n & 0x1;
    n >>= 1;
  }
  return count;
}

int main(void)
{
    u32 i, x_position, y_position, cmd;
    u32 xStatus;
    direction_e direction;

    // SysMon Initialize
    SysMonConfigPtr = XSysMon_LookupConfig(SYSMON_DEVICE_ID);
    if(SysMonConfigPtr == NULL)
        xil_printf("SysMon LookupConfig failed.\n\r");
    xStatus = XSysMon_CfgInitialize(SysMonInstPtr, SysMonConfigPtr,
                                    SysMonConfigPtr->BaseAddress);
    if(XST_SUCCESS != xStatus)
        xil_printf("SysMon CfgInitialize failed\r\n");
    // Clear the old status
    XSysMon_GetStatus(SysMonInstPtr);

    Xil_Out32(XPAR_IOP_ARDUINO_INTR_BASEADDR+4,0x0);
    Xil_Out32(XPAR_IOP_ARDUINO_INTR_BASEADDR,0x0);

    /*
     *  Initialize the gpio
     *  select button = D2
     *  Right button = D3
     *  Up button = D4
     *  Down button = D5 
     *  Left button = D6
     */
    for (i=0; i<5; i++){
        gpio_buttons[i] = gpio_open(i+2);
        gpio_set_direction(gpio_buttons[i], GPIO_IN);
    }

    while(1){
        // wait and store valid command
        while((MAILBOX_CMD_ADDR & 0x1)==0);
        cmd = (MAILBOX_CMD_ADDR & 0xF);

        switch(cmd){
            case CONFIG_IOP_SWITCH:
                /* 
                 * Assign default pin configurations
                 * set D3, D4, D5, D6 and D2 pins as input
                 */
                for (i=0; i<5; i++){
                    gpio_buttons[i] = gpio_open(i+2);
                    gpio_set_direction(gpio_buttons[i], GPIO_IN);
                }
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case GET_RAW_DATA_X:
                // Wait for the conversion complete
                while ((XSysMon_GetStatus(SysMonInstPtr) & 
                        XSM_SR_EOS_MASK) != XSM_SR_EOS_MASK);
                MAILBOX_DATA(0) = XSysMon_GetAdcData(SysMonInstPtr, \
                                            XSM_CH_AUX_MIN+1);
                Xil_Out32(XPAR_IOP_ARDUINO_INTR_BASEADDR,0x1);
                Xil_Out32(XPAR_IOP_ARDUINO_INTR_BASEADDR,0x0);
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case GET_RAW_DATA_Y:
                // Wait for the conversion complete
                while ((XSysMon_GetStatus(SysMonInstPtr) & 
                        XSM_SR_EOS_MASK) != XSM_SR_EOS_MASK);
                MAILBOX_DATA(0) = XSysMon_GetAdcData(SysMonInstPtr,
                                            XSM_CH_AUX_MIN+9);
                Xil_Out32(XPAR_IOP_ARDUINO_INTR_BASEADDR,0x1);
                Xil_Out32(XPAR_IOP_ARDUINO_INTR_BASEADDR,0x0);                
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case GET_DIRECTION:
                // Wait for the conversion complete
                while ((XSysMon_GetStatus(SysMonInstPtr) & 
                        XSM_SR_EOS_MASK) != XSM_SR_EOS_MASK);
 
                x_position = XSysMon_GetAdcData(
                                SysMonInstPtr,XSM_CH_AUX_MIN+1);
                y_position = XSysMon_GetAdcData(
                                SysMonInstPtr,XSM_CH_AUX_MIN+9);

                if (x_position > X_THRESHOLD_HIGH) {
                    if (y_position > Y_THRESHOLD_HIGH) {
                        direction = right_up;
                    } else if (y_position < Y_THRESHOLD_LOW) {
                        direction = right_down;
                    } else {
                        direction = right;
                    }
                } else if (x_position < X_THRESHOLD_LOW) {
                    if (y_position > Y_THRESHOLD_HIGH) {
                        direction = left_up;
                    } else if (y_position < Y_THRESHOLD_LOW) {
                        direction = left_down;
                    } else {
                        direction = left;
                    }
                } else {
                    if (y_position > Y_THRESHOLD_HIGH) {
                        direction = up;
                    } else if (y_position < Y_THRESHOLD_LOW) {
                        direction = down;
                    } else {
                        direction = centered;
                    }
                }
                MAILBOX_DATA(0) = direction;
                Xil_Out32(XPAR_IOP_ARDUINO_INTR_BASEADDR,0x1);
                Xil_Out32(XPAR_IOP_ARDUINO_INTR_BASEADDR,0x0);
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case GET_BUTTONS:
                for (i=0;i<5;i++){
                    MAILBOX_DATA(i) = gpio_read(gpio_buttons[i]);
                }
                Xil_Out32(XPAR_IOP_ARDUINO_INTR_BASEADDR,0x1);
                Xil_Out32(XPAR_IOP_ARDUINO_INTR_BASEADDR,0x0);  
                MAILBOX_CMD_ADDR = 0x0;
                break;
            
            default:
                MAILBOX_CMD_ADDR = 0x0;
                break;
        }
    }
    return 0;
}
