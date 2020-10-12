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
 * @file pmod_tc1.c
 *
 * IOP code (MicroBlaze) for Pmod TC1
 * Pmod TC1 is read only, and has SPI with MISO only (no MOSI)
 * Operations implemented in this application:
 *   1. Simple, single read from sensor, and write to data area
 *   2. Continuous read from sensor and log to data area
 * Switch configuration is done within this program, Pmod should
 * be plugged into upper row of connector.
 * The Pmod TC1 is based on MAX31855 thermocouple-to-digital converter.
 * http://store.digilentinc.com/pmodtc1-k-type-thermocouple-module-with-wire/
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who   Date     Changes
 * ----- ---   ------- -----------------------------------------------
 * 1.00  tfors 10/15/16 release
 * 1.01  mrn 10/11/20 update initialize function
 *
 * </pre>
 *
 *****************************************************************************/

#include "circular_buffer.h"
#include "timer.h"
#include "spi.h"

// MAILBOX_WRITE_CMD
#define READ_SINGLE_VALUE 0x3
#define READ_AND_LOG      0x7
// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_ITEM_SIZE sizeof(u32)
#define LOG_CAPACITY  (4000/LOG_ITEM_SIZE)

static spi device;

u32 get_sample(){
  /*
   * TC1 data is packed in a 32-bit word.
   * Four bytes need to be read.
   */
  u8 raw_data[4];
  spi_transfer(device, NULL, (char*)raw_data, 4);
  u32 v = ( (raw_data[0] << 24) + (raw_data[1] << 16)
	    + (raw_data[2] << 8) + raw_data[3] );
  return v;
}


int main(void)
{
   int cmd;
   u32 tc1_data;
   u32 delay;

   device = spi_open(3,2,1,0);
   device = spi_configure(device, 1, 1);
   // to initialize the device
   get_sample();

   // Run application
   while(1){

     // wait and store valid command
     while((MAILBOX_CMD_ADDR & 0x01)==0);
     cmd = MAILBOX_CMD_ADDR;

     switch(cmd){

        case READ_SINGLE_VALUE:
      // write out reading, reset mailbox
      MAILBOX_DATA(0) = get_sample();
      MAILBOX_CMD_ADDR = 0x0;

      break;

         case READ_AND_LOG:
       // initialize logging variables, reset cmd
       cb_init(&circular_log, 
        LOG_BASE_ADDRESS, LOG_CAPACITY, LOG_ITEM_SIZE, 1);
       delay = MAILBOX_DATA(1);
       MAILBOX_CMD_ADDR = 0x0;

            do{
               tc1_data = get_sample();
           cb_push_back(&circular_log, &tc1_data);
           delay_ms(delay);

            } while((MAILBOX_CMD_ADDR & 0x1)== 0);

            break;

         default:
            // reset command
            MAILBOX_CMD_ADDR = 0x0;
            break;
      }
   }
   return(0);
}
