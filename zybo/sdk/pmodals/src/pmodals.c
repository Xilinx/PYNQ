/*
 * IOP code (MicroBlaze) for PMOD ALS
 * PMOD ALS is read only, and has SPI with MISO only (no MOSI)
 * Operations implemented in this application:
 *   1. Simple, single read from sensor, and write to data area
 *   2. Continuous read from sensor and write to data area
 *   3. Continuous read from sensor and log to data area
 * Switch configuration is done within this program, PMOD should 
 * be plugged into upper row of connector
 *
 * NOTE: ALS data is 8-bit received in the middle of a 16-bit stream.
 * CMC
 * Version 1.0 12 Nov 2015
 * To do: check how switch should be configured from uPython
*/

#include "pmod.h"

// MAILBOX_WRITE_CMD
// bit 0 : '1' Command received
// bit 1 : '1' get single value of light value from sensor
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

int main(void)
{
   int cmd;
   u8 raw_data[2];
   u16 als_data;
   u32 pointer;
   u32 delay;

   // Configure switch
   configureSwitch(SS, BLANK, MISO, SPICLK, BLANK, BLANK, BLANK, BLANK); // Config top or bottom row

   // Run application
   while(1){
      while((MAILBOX_CMD_ADDR & 0x01)==0); // wait for cmd (bit[0] to become 1)

      cmd = MAILBOX_CMD_ADDR;

      // ALS data is 8-bit in the middle of 16-bit stream. Two bytes need to be read, and data extracted
      switch(cmd){
         case CANCEL:    // cancel outstanding transactions
            MAILBOX_CMD_ADDR = 0x0;
            break;
         case READ_SINGLE_VALUE:
            spi_transfer(SPI_BASEADDR, 2, raw_data, NULL);
            als_data = ((raw_data[0]<<4)+(raw_data[1]>>4)); // Format 16-bit raw_data to 8-bit ALS data
            MAILBOX_DATA(0) = als_data; // Write data to mailbox
            MAILBOX_CMD_ADDR = 0x0; // reset command
            break;
         case READ_CONTINUOUS:
            MAILBOX_CMD_ADDR = 0x0; // reset command
            do{
               spi_transfer(SPI_BASEADDR, 2, raw_data, NULL);
               als_data = ((raw_data[0]<<4)+(raw_data[1]>>4));
               MAILBOX_DATA(0) = als_data; // remove 4 LSB and cast to get 8-bit ALS data
            }while((MAILBOX_CMD_ADDR & 0x1)== 0); // do while no new command
            break;
         case READ_AND_LOG:
            pointer = 0;
            delay = MAILBOX_DATA(1);
            MAILBOX_CMD_ADDR = 0x0; // reset command
            do{
               spi_transfer(SPI_BASEADDR, 2, raw_data, NULL);
               als_data = ((raw_data[0]<<4)+(raw_data[1]>>4));
               MAILBOX_DATA(2) = pointer;
               MAILBOX_DATA((pointer%1000)+3) = als_data; // remove 4 LSB and cast to get 8-bit ALS data

               if(pointer < 1999){
                  pointer++;
               }else{
                  pointer = 1000;
               }
               delay_ms(delay);
            }while((MAILBOX_CMD_ADDR & 0x1)== 0); // do while no new command
            break;
         default:
            MAILBOX_CMD_ADDR = 0x0; // reset command
            break;
      }
   }
   return(0);
}


