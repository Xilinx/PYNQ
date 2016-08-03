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
 * @file pmod_tmp2.c
 *
 * IOP code (MicroBlaze) for Pmod TMP2
 * Pmod TMP2 is read only, and has IIC interface
 * Operations implemented:
 *   1. Simple, single read from sensor, and write to data area
 *   2. Continuous read from sensor and log to data area
 * Switch configuration is done within this program.
 * The Pmod TMP2 is an ambient temperature sensor powered by the ADT7420.
 * http://store.digilentinc.com/pmodtmp2-temperature-sensor/
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a cmc  03/29/16 release
 * 1.00b pp  05/27/16 fix pmod_init()
 *
 * </pre>
 *
 *****************************************************************************/

#include "pmod.h"

// Mailbox commands
#define READ_SINGLE_VALUE 0x3
#define READ_AND_LOG      0x7

// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_ITEM_SIZE sizeof(float)
#define LOG_CAPACITY  (4000/LOG_ITEM_SIZE)

float get_sample(){
  u8 raw_data[2];
  u32 sample;
  
  // TMP2 get sample in Celsius (x2 reads to clear stale data)
  iic_read(XPAR_IIC_0_BASEADDR,0x4b,raw_data,2);
  iic_read(XPAR_IIC_0_BASEADDR,0x4b,raw_data,2);
  sample = (raw_data[0] << 8) | raw_data[1];
  return (((float)sample)*0.0625)/8; 
}


int main(void)
{
   int cmd;
   u32 delay;
   float temperature;

   pmod_init(0,1);
   config_pmod_switch(GPIO_0, GPIO_1, SCL, SDA, GPIO_4, GPIO_5, SCL, SDA);
   
   // Run application
   while(1){

     // wait and store valid command
      while((MAILBOX_CMD_ADDR & 0x01)==0); 
      cmd = MAILBOX_CMD_ADDR; 

      switch(cmd){
        case READ_SINGLE_VALUE:
            // write out temperature, reset mailbox
            MAILBOX_DATA_FLOAT(0) = get_sample();
            MAILBOX_CMD_ADDR = 0x0;
            break;
            
        case READ_AND_LOG:    
            // initialize logging variables, reset cmd
            cb_init(&pmod_log, LOG_BASE_ADDRESS, LOG_CAPACITY, LOG_ITEM_SIZE);
            delay = MAILBOX_DATA(1);    
            MAILBOX_CMD_ADDR = 0x0; 

            do{
                // push sample to log and delay
                temperature = get_sample();
                cb_push_back_float(&pmod_log, &temperature);
                delay_ms(delay);
            } while((MAILBOX_CMD_ADDR & 0x1)== 0);
            break;
       
        default:
            MAILBOX_CMD_ADDR = 0x0;
            break;
      }
   }
   return 0;
}
