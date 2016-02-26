/*
 * IOP code (MicroBlaze) for PMOD TMP2
 * PMOD TMP2 is read only, and has IIC interface
 * Operations implemented:
 *   1. Simple, single read from sensor, and write to data area
 *   2. Continuous read from sensor and write to data area
 *   3. Continuous read from sensor and log to data area
 * Switch configuration is done within this program.
 * There is only one configuration for this PMOD
 *
 * CMC
 * Version 1.0 12 Nov 2015
 * To do: check how switch should be configured from uPython
*/

#include "pmod.h"


// MAILBOX_WRITE_CMD
// bit 0 : '1' Command received
// bit 1 : '1' get single value from sensor
// bit 2 : '0' get data continuously from sensor
// bit 2 : '1' get data continuously from sensor and log;
//             Write pointer to MAILBOX_DATA(0), and data to rest of DATA space

#define CANCEL            0x1 // 0001
#define READ_SINGLE_VALUE 0x3 // 0011
#define READ_CONTINUOUS   0x5 // 0101
#define READ_AND_LOG      0x7 // 0111
// Read values, and log to data space. Write pointer value (location of current value to DATA(0)
// Can store 1023 - 1 values in data space
// Before using this cmd, "delay" should be set up in MAILBOX_DATA(0)

// Note, the first read from the iic always reads old (registered?) data. Fix for now is to read twice to get up-to-date data
int main(void)
{
   int cmd;
   u32 raw_data;
   u32 pointer;
   u32 delay;
   float temperature;
   
   configureSwitch(BLANK, BLANK, SCL, SDA, BLANK, BLANK, SCL, SDA);
   
   // Run application
   while(1){
      while((MAILBOX_CMD_ADDR & 0x01)==0); // wait for bit[0] to become 1
      cmd = MAILBOX_CMD_ADDR; // get cmd bits

      switch(cmd){
         case CANCEL:    // cancel outstanding transactions
            MAILBOX_CMD_ADDR = 0x0;
            break;
         case READ_SINGLE_VALUE:
            iic_read(0x4b); // Dummy read is required, as first data is stale
            raw_data = iic_read(0x4b);  // Do read to get up-to-date data
            temperature = (((float)raw_data)*0.0625)/8; // Calculate temperature in Celsius
            MAILBOX_DATA(0) = temperature;
            MAILBOX_CMD_ADDR = 0x0; // reset mailbox
            break;
         case READ_CONTINUOUS:
            MAILBOX_CMD_ADDR = 0x0; // reset mailbox
            do{
                iic_read(0x4b);
                raw_data = iic_read(0x4b);
               temperature = (((float)raw_data)*0.0625)/8; // Calculate temperature in Celsius
               MAILBOX_DATA(0) = temperature;
            }while((MAILBOX_CMD_ADDR & 0x01)==0); // do continuously until new command
            break;
         case READ_AND_LOG:
            pointer = 0;
            delay = MAILBOX_DATA(1);
            MAILBOX_CMD_ADDR = 0x0; // reset command
            do{
               iic_read(0x4b);
               raw_data = iic_read(0x4b);
               temperature = (((float)raw_data)*0.0625)/8; // Calculate temperature in Celsius
               MAILBOX_DATA(2) = pointer;
               MAILBOX_DATA((pointer%1000)+3) = temperature; // remove 4 LSB and cast to get 8-bit ALS data

               if(pointer < 1999){
                  pointer++;
               }else{
                  pointer = 1000;
               }
               delay_ms(delay);
               }
            while((MAILBOX_CMD_ADDR & 0x1)== 0); // do while no new command
            break;
         default:
            MAILBOX_CMD_ADDR = 0x0; // reset command
            break;
      }
   }
   return(0);
}
