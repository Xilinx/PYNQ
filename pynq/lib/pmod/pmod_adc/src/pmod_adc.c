/******************************************************************************
 *  Copyright (c) 2016-2020, Xilinx, Inc.
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
 * IOP code (MicroBlaze) for Pmod AD2 SKU410-217.
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
 * 1.00b pp  05/27/16 fix pmod_init()
 * 1.10  mrn 10/12/20 Comppute log_capacity computation depending on the number
 *                    of channels. update initialize function
 * </pre>
 *
 *****************************************************************************/

#include "xparameters.h"
#include "ad7991.h"
#include "xil_io.h"
#include "circular_buffer.h"
#include "timer.h"
#include "i2c.h"

/*****************************************************************************/
/************************** Macros Definitions *******************************/
/*****************************************************************************/

// Reference voltage value = actual value * 10000
#define VREF 2.048

#define RESET_ADC              0x1
#define READ_RAW_DATA          0x3
#define READ_VOLTAGE           0x5
#define READ_AND_LOG_RAW_DATA  0x7
#define READ_AND_LOG_VOLTAGE   0x9

// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_ITEM_SIZE sizeof(float)
#define MAX_SAMPLES (4032 / LOG_ITEM_SIZE)

u8 WriteBuffer[10];
u8 ReadBuffer[10];
i2c device;

int main()
{
    u8 useChan0, useChan1, useChan2, useChan3;
    u8 useVref, useFILT, useBIT, useSample;
    u32 delay;
    u32 cmd;
    u32 adc_raw_value;
    u32 log_capacity, num_channels;
    float adc_voltage;

    device = i2c_open(3, 2);
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

    while(1){
        while((MAILBOX_CMD_ADDR & 0x01)==0); // wait for bit[0] to become 1
        cmd = (MAILBOX_CMD_ADDR) & 0x0f;
        useChan0 = ((MAILBOX_CMD_ADDR) >> 4) & 0x01;
        useChan1 = ((MAILBOX_CMD_ADDR) >> 5) & 0x01;
        useChan2 = ((MAILBOX_CMD_ADDR) >> 6) & 0x01;
        num_channels = useChan0 + useChan1 + useChan2;
        log_capacity = ((u32)(MAX_SAMPLES/num_channels)) * num_channels;
        adc_config(useChan3,useChan2,useChan1,useChan0,
                    useVref,useFILT,useBIT,useSample);
        
        switch(cmd){
            case RESET_ADC:
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            case READ_RAW_DATA:
                MAILBOX_DATA(0)=0;
                MAILBOX_DATA(1)=0;
                MAILBOX_DATA(2)=0;
                if(useChan0)
                    MAILBOX_DATA(0) = adc_read_raw();
                if(useChan1)
                    MAILBOX_DATA(1) = adc_read_raw();
                if(useChan2)
                    MAILBOX_DATA(2) = adc_read_raw();
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            case READ_VOLTAGE:
                MAILBOX_DATA_FLOAT(0)=0;
                MAILBOX_DATA_FLOAT(1)=0;
                MAILBOX_DATA_FLOAT(2)=0;
                if(useChan0)
                    MAILBOX_DATA_FLOAT(0) = adc_read_voltage(VREF);
                if(useChan1)
                    MAILBOX_DATA_FLOAT(1) = adc_read_voltage(VREF);
                if(useChan2)
                    MAILBOX_DATA_FLOAT(2) = adc_read_voltage(VREF);
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            case READ_AND_LOG_RAW_DATA:
                // set the delay in us between samples
                delay = MAILBOX_DATA(0);
                cb_init(&circular_log, LOG_BASE_ADDRESS, 
                            log_capacity, LOG_ITEM_SIZE, num_channels);
                while((MAILBOX_CMD_ADDR & 0xf) != RESET_ADC){
                   if(useChan0)
                   {
                        adc_raw_value = adc_read_raw();
                        cb_push_back(&circular_log, &adc_raw_value);
                   }
                   if(useChan1)
                   {
                        adc_raw_value = adc_read_raw();
                        cb_push_back(&circular_log, &adc_raw_value);
                   }
                   if(useChan2)
                   {
                    adc_raw_value = adc_read_raw();
                    cb_push_back(&circular_log, &adc_raw_value);
                   }
                   delay_us(delay);
                }
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            case READ_AND_LOG_VOLTAGE:
                // set the delay in us between samples
                delay = MAILBOX_DATA(0);
                cb_init(&circular_log, LOG_BASE_ADDRESS, 
                            log_capacity, LOG_ITEM_SIZE, num_channels);
                while((MAILBOX_CMD_ADDR & 0x0f) != RESET_ADC){
                    if(useChan0)
                    {
                        adc_voltage = adc_read_voltage(VREF);
                        cb_push_back_float(&circular_log, &adc_voltage);
                    }
                    if(useChan1)
                    {
                        adc_voltage = adc_read_voltage(VREF);
                        cb_push_back_float(&circular_log, &adc_voltage);
                    }
                    if(useChan2)
                    {
                        adc_voltage = adc_read_voltage(VREF);
                        cb_push_back_float(&circular_log, &adc_voltage);
                    }
                    delay_us(delay);
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

