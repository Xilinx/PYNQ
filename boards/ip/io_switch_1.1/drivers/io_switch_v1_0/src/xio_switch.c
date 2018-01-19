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
 * @file xio_switch.c
 *
 * Configuring IO Switch and set pin to desired functionality 
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a pp  01/08/18 release
 * 1.00a yrq 01/14/18 fix set_pin() function
 *
 * </pre>
 *
 *****************************************************************************/
#include "xio_switch.h"

// Byte array for pins. Elements include pin type defined in io_switch.h
char pins[XPAR_IO_SWITCH_0_IO_SWITCH_WIDTH]; 

// Basic API for configuring the switch. 
// Function: Configure pins with desired functionality
// Input: Number of pins to be configured and pins array pre-loaded before 
//        calling this function
// Output: None
void config_io_switch(int num_of_pins) {
    int i,j,num_words,num_bytes;
    u32 switchConfigValue;

    num_words=num_of_pins/4;
    num_bytes=num_of_pins%4;
    for (i=0, j=0; j<num_words; i=i+4, j++) {
        switchConfigValue = (pins[i+3]<<24)|(pins[i+2]<<16)| \
        (pins[i+1]<<8)|(pins[i]);
        Xil_Out32(SWITCH_BASEADDR+i, switchConfigValue);
    }
    if(num_bytes) {
        switchConfigValue=0;
        for (j=0; j<num_bytes; j++)
            switchConfigValue = switchConfigValue | \
            (pins[num_words*4+j] << j*8);
        Xil_Out32(SWITCH_BASEADDR+num_words*4, switchConfigValue);
    }
}

// Basic API for setting a pin to the desired functionality
// Input: pin number and pin type 
// Output: None
void set_pin(int pin_number, u8 pin_type) {
    int numWordstoPass, byteNumber;
    u32 switchConfigValue;

    numWordstoPass=pin_number/4;
    byteNumber=pin_number%4;
    switchConfigValue=Xil_In32(SWITCH_BASEADDR+4*numWordstoPass);
    switchConfigValue = (switchConfigValue & (~(0xFF<<(byteNumber*8)))) | \
    (pin_type<<(byteNumber*8));
    Xil_Out32(SWITCH_BASEADDR+numWordstoPass*4, switchConfigValue);
}

// Basic API for setting all pins to GPIO
// Input: None 
// Output: None
void init_io_switch(void) {
    int i;
    for(i=0; i<XPAR_IO_SWITCH_0_IO_SWITCH_WIDTH; i++)
        pins[i]=GPIO;
    config_io_switch(XPAR_IO_SWITCH_0_IO_SWITCH_WIDTH); // All GPIO
}

/************************** Function Definitions ***************************/
