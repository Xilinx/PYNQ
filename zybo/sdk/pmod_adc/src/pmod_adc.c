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
 * @file pmod_adc.c
 *
 * IOP code (MicroBlaze) for PMOD AD2 SKU410-217.
 * The PmodAD2 is an analog-to-digital converter powered by the Analog Devices
 * AD7991. Users may communicate with the board through I2C to configure up to
 * 4 conversion channels at 12 bits of resolution.
 * http://store.digilentinc.com/pmodad2-4-channel-12-bit-a-d-converter/
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a pp  04/13/16 release
 *
 * </pre>
 *
 *****************************************************************************/

#include "xparameters.h"
#include "AD7991.h"
#include "xil_io.h"
#include "pmod.h"

/*****************************************************************************/
/************************** Macros Definitions *******************************/
/*****************************************************************************/

#define IIC_BASEADDR  XPAR_IIC_0_BASEADDR
// Reference voltage value = actual value * 10000
#define VREF 20480

u8 WriteBuffer[10];
u8 ReadBuffer[10];
u16 SlaveAddress;

int main()
{
    unsigned int sample;
    u8 useChan0, useChan1, useChan2, useChan3;
    u8 useVref, useFILT, useBIT, useSample;
    u32 delay;
    u32 cmd;
    u32 numofsamples;
    u8 numofchannels, i, j;

    pmod_init();
    /*  
     *  Configuring PMOD IO Switch to connect to I2C[0].
     *  SCLK to pmod bit 2, I2C[0].SDA to pmod bit 3
     *  rest of the bits are configured to default gpio channels
     *  i.e. pmod bit[0] to gpio[0], pmod bit[1] to gpio[1], etc.
     */
    // isolate configuration port by writing 0 to slv_reg1[31]
    Xil_Out32(SWITCH_BASEADDR+4,0x00000000);
    Xil_Out32(SWITCH_BASEADDR,0x76549810);
    // Enable configuration by writing 1 to slv_reg1[31]
    Xil_Out32(SWITCH_BASEADDR+4,0x80000000);

    // initialize pmod
    pmod_init();
    // to use internal VREF, bridge JP1 accross pin1 and center pin
    useVref=1;
    // filtering on SDA and SCL is enabled
    useFILT=0;
    // use BIT delay enabled
    useBIT=0;
    // use Sample delay enabled
    useSample=0;
    
    while(1){
        while((MAILBOX_CMD_ADDR & 0x01)==0); // wait for bit[0] to become 1
        cmd = MAILBOX_CMD_ADDR;
        numofchannels=0;
        // Channel 0
        if((cmd >> 1) & 0x01) {
            useChan0=1;
            numofchannels++;
        }
        else
            useChan0 = 0;
        // Channel 1
        if((cmd >> 2) & 0x01) {
            useChan1=1;
            numofchannels++;
        }
        else
            useChan1=0;
        // Channel 2
        if((cmd >> 3) & 0x01) {
            useChan2=1;
            numofchannels++;
        }
        else
            useChan2=0;
        // Channel 3: since VREF is used, channel 3 cannot be sampled
        useChan3=0;
        
        if(((cmd >> 16) & 0x0ffff)==0){
            // set delay to 1 second if the field is set to 0
            delay = 1000;
        }else{
            // A few milliseconds
            delay=(cmd >> 16) & 0x0ffff; 
        }
        
        // set to number of samples; "0" indicates infinite number of samples
        numofsamples=(cmd >> 8) & 0x0ff; 
        if(numofsamples==0) {
            // infinitely
               AD7991_Config(useChan3,useChan2,useChan1,useChan0,
                       useVref,useFILT,useBIT,useSample);
               while(1) {
                   for(j=0; j<numofchannels; j++) {
                       sample = AD7991_Read(1, VREF);
                       MAILBOX_DATA(j)=sample;
                       delay_ms(delay);
                   }
               }
        }else{
               AD7991_Config(useChan3,useChan2,useChan1,useChan0,
                       useVref,useFILT,useBIT,useSample);
               for(i=0;i<numofsamples;i++) {
                   for(j=0; j<numofchannels; j++) {
                       sample = AD7991_Read(1, VREF);
                       MAILBOX_DATA(i*numofchannels+j)=sample;
                       delay_ms(delay);
                   }
               }
        }
        MAILBOX_CMD_ADDR = 0x0;
    }
   return 0;
}

