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
#include "ad7991.h"
#include "xil_io.h"
#include "pmod.h"

/*****************************************************************************/
/************************** Macros Definitions *******************************/
/*****************************************************************************/

// Reference voltage value = actual value * 10000
#define VREF 2.048
#define IIC_BASEADDR  XPAR_IIC_0_BASEADDR

#define RESET_ADC              0x1
#define READ_RAW_DATA          0x3
#define READ_VOLTAGE           0x5
#define READ_AND_LOG_RAW_DATA  0x7
#define READ_AND_LOG_VOLTAGE   0x9

// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_ITEM_SIZE sizeof(float)
#define LOG_CAPACITY  (4000/LOG_ITEM_SIZE)

u8 WriteBuffer[10];
u8 ReadBuffer[10];
u16 SlaveAddress;

int main()
{
    u8 useChan0, useChan1, useChan2, useChan3;
    u8 useVref, useFILT, useBIT, useSample;
    u32 delay;
    u32 cmd;
    u32 num_samples, num_channels;
    u32 channel;
    u8 i, j;
    u32 adc_raw_value;
    float adc_voltage;

    // initialize pmod
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

    // to use internal VREF, bridge JP1 accross pin1 and center pin
    useVref=1;
    // filtering on SDA and SCL is enabled
    useFILT=0;
    // use BIT delay enabled
    useBIT=0;
    // use Sample delay enabled
    useSample=0;
    // all the 3 channels are enabled
    useChan0 = 1;
    useChan1 = 1;
    useChan2 = 1; 
    // Channel 3: since VREF is used, channel 3 cannot be sampled
    useChan3 = 0;
    num_channels = useChan0 + useChan1 + useChan2 + useChan1;
    
    adc_config(useChan3,useChan2,useChan1,useChan0,
                    useVref,useFILT,useBIT,useSample);
    
    while(1){
        while((MAILBOX_CMD_ADDR & 0x01)==0); // wait for bit[0] to become 1
        cmd = MAILBOX_CMD_ADDR;
        
        switch(cmd){
            case RESET_ADC:
                adc_config(useChan3,useChan2,useChan1,useChan0,
                                useVref,useFILT,useBIT,useSample);
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            case READ_RAW_DATA:
                adc_config(useChan3,useChan2,useChan1,useChan0,
                            useVref,useFILT,useBIT,useSample);
                // set the delay in ms between two samples
                delay = MAILBOX_DATA(0);
                // set to number of samples
                num_samples = MAILBOX_DATA(1); 
                for(i=0;i<num_samples;i++) {
                    delay_ms(delay);
                    for(j=0; j<num_channels; j++) {
                        adc_raw_value = adc_read_raw();
                        MAILBOX_DATA(num_channels*i+j) = adc_raw_value;
                   }
                }
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            case READ_VOLTAGE:
                adc_config(useChan3,useChan2,useChan1,useChan0,
                            useVref,useFILT,useBIT,useSample);
                // set the delay in ms between two samples
                delay = MAILBOX_DATA(0);
                // set to number of samples
                num_samples = MAILBOX_DATA(1); 
                for(i=0;i<num_samples;i++) {
                    delay_ms(delay);
                    for(j=0; j<num_channels; j++) {
                        adc_voltage = adc_read_voltage(VREF);
                        MAILBOX_DATA_FLOAT(num_channels*i+j) = adc_voltage;
                   }
                }
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            case READ_AND_LOG_RAW_DATA:
                // set the delay in ms between samples
                delay = MAILBOX_DATA(0);
                // set the channel index, from 0 to 2
                channel = MAILBOX_DATA(1);
                // initialize logging variables, reset cmd
                cb_init(&pmod_log, LOG_BASE_ADDRESS, 
                            LOG_CAPACITY, LOG_ITEM_SIZE);
                while(MAILBOX_CMD_ADDR != RESET_ADC){
                    adc_config(useChan3,useChan2,useChan1,useChan0,
                                useVref,useFILT,useBIT,useSample);
                    for(j=0; j<num_channels; j++) {
                        adc_raw_value = adc_read_raw();
                        if (j == channel){
                            // push samples only for specified channel
                            cb_push_back(&pmod_log, &adc_raw_value);
                        }
                    }
                    delay_ms(delay);
                }
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            case READ_AND_LOG_VOLTAGE:
                // set the delay in ms between samples
                delay = MAILBOX_DATA(0);
                // set the channel index, from 0 to 2
                channel = MAILBOX_DATA(1);
                // initialize logging variables, reset cmd
                cb_init(&pmod_log, LOG_BASE_ADDRESS, 
                            LOG_CAPACITY, LOG_ITEM_SIZE);
                while(MAILBOX_CMD_ADDR != RESET_ADC){
                    adc_config(useChan3,useChan2,useChan1,useChan0,
                                useVref,useFILT,useBIT,useSample);
                    for(j=0; j<num_channels; j++) {
                        adc_voltage = adc_read_voltage(VREF);
                        if (j == channel){
                            // push samples only for specified channel
                            cb_push_back_float(&pmod_log, &adc_voltage);
                        }
                    }
                    delay_ms(delay);
                }
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            default:
                MAILBOX_CMD_ADDR = 0x0;
                break;
        }
    }
   return 0;
}

