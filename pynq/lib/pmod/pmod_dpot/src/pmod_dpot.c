/******************************************************************************
 *  Copyright (c) 2016, Xilinx, Inc.
 *  SPDX-License-Identifier: BSD-3-Clause
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
 
#include "circular_buffer.h"
#include "timer.h"
#include "spi.h"

/*
 * MAILBOX_WRITE_CMD
 * bit 0 : '1' Command received
 * bit 1 : '1' write single value to DPOT
 * bit 2 : '1' Write continuously to DPOT based on data defined in mailbox
 */

#define CANCEL 0x1
#define SET_POT_SIMPLE 0x3
#define SET_POT_RAMP 0x5

static spi device;

int main(void)
{
   int cmd;
   char dpot_value;
   u32 step_size, delay;

   device = spi_open(3,2,1,0);
   device = spi_configure(device, 0, 1);

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
            spi_transfer(device, &dpot_value, NULL, 1);
            MAILBOX_CMD_ADDR = 0;
            break;
         case SET_POT_RAMP:
            dpot_value = MAILBOX_DATA(0);
            step_size = MAILBOX_DATA(1);
            delay = MAILBOX_DATA(2);
            MAILBOX_CMD_ADDR = 0;
            // do continuously until new command
            do{
               spi_transfer(device, &dpot_value, NULL, 1);
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

