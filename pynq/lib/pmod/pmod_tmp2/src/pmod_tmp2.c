/******************************************************************************
 *  Copyright (c) 2016-2020, Xilinx, Inc.
 *  SPDX-License-Identifier: BSD-3-Clause
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
 * 1.01  mrn 10/11/20 update initialize function
 *
 * </pre>
 *
 *****************************************************************************/

#include "i2c.h"
#include "timer.h"
#include "circular_buffer.h"

// Mailbox commands
#define READ_SINGLE_VALUE 0x3
#define READ_AND_LOG      0x7

// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_ITEM_SIZE sizeof(float)
#define LOG_CAPACITY  (4000/LOG_ITEM_SIZE)

i2c device;

float get_sample(){
  u8 raw_data[2];
  u32 sample;
  
  // TMP2 get sample in Celsius (x2 reads to clear stale data)
  i2c_read(device,0x4b,raw_data,2);
  i2c_read(device,0x4b,raw_data,2);
  sample = (raw_data[0] << 8) | raw_data[1];
  return (((float)sample)*0.0625)/8; 
}


int main(void)
{
   int cmd;
   u32 delay;
   float temperature;

   device = i2c_open(3, 2);

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
            cb_init(&circular_log, 
              LOG_BASE_ADDRESS, LOG_CAPACITY, LOG_ITEM_SIZE, 1);
            delay = MAILBOX_DATA(1);    
            MAILBOX_CMD_ADDR = 0x0; 

            do{
                // push sample to log and delay
                temperature = get_sample();
                cb_push_back_float(&circular_log, &temperature);
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

