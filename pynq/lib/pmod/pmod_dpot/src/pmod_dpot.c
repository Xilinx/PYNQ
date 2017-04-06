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
 * @file pmod_dpot.c
 *
 * IOP code (MicroBlaze) for Pmod DPOT.
 * Pmod DPOT is write only, and has SPI with MOSI only
 * Operations implemented in this application:
 *   1. Simple, single write to DPOT from data area
 *   2. Continuous write to DPOT with RAMP, DELAY and STEP SIZE
 * Switch configuration is done within this program, Pmod should
 * be plugged into upper row of connector
 * The Pmod DPOT is a digital potentiometer powered by AD5160. Users may set 
 * a desired resistance between 60Ω and 10kΩ by programming through SPI. 
 * http://store.digilentinc.com/pmoddpot-digital-potentiometer/
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a cmc 11/19/15 release
 * 1.00b pp  05/27/16 fix pmod_init()
 *
 * </pre>
 *
 *****************************************************************************/
 
#include "pmod.h"

/*
 * MAILBOX_WRITE_CMD
 * bit 0 : '1' Command received
 * bit 1 : '1' write single value to DPOT
 * bit 2 : '1' Write continuously to DPOT based on data defined in mailbox
 */

#define CANCEL 0x1
#define SET_POT_SIMPLE 0x3
#define SET_POT_RAMP 0x5

int main(void)
{
   int cmd;
   u8 dpot_value;
   u32 step_size, delay;

   pmod_init(0,1);
   config_pmod_switch(SS, MOSI, GPIO_2, SPICLK, 
                      GPIO_4, GPIO_5, GPIO_6, GPIO_7);

   // Run application
   while(1){
      while((MAILBOX_CMD_ADDR & 0x01)==0);
      cmd = MAILBOX_CMD_ADDR; // get cmd bits
      
      // Check commands
      switch(cmd){
         case CANCEL:
            // cancel outstanding transactions
            MAILBOX_CMD_ADDR = 0;
            break;
         case SET_POT_SIMPLE:
            dpot_value = MAILBOX_DATA(0);
            spi_transfer(SPI_BASEADDR, 1, NULL, &dpot_value);
            MAILBOX_CMD_ADDR = 0;
            break;
         case SET_POT_RAMP:
            dpot_value = MAILBOX_DATA(0);
            step_size = MAILBOX_DATA(1);
            delay = MAILBOX_DATA(2);
            MAILBOX_CMD_ADDR = 0;
            // do continuously until new command
            do{
               spi_transfer(SPI_BASEADDR, 1, NULL, &dpot_value);
               // Positive ramp
               dpot_value = dpot_value + step_size;
               delay_ms(delay);
            }while((MAILBOX_CMD_ADDR & 0x01)==0);
            break;
         default:
            MAILBOX_CMD_ADDR = 0;
            break;  
      }            
   }
   return(0);
}
