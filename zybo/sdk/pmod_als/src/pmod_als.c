/*
 * IOP code (MicroBlaze) for PMOD ALS
 * PMOD ALS is read only, and has SPI with MISO only (no MOSI)
 * Operations implemented in this application:
 *   1. Simple, single read from sensor, and write to data area
 *   2. Continuous read from sensor and log to data area
 * Switch configuration is done within this program, PMOD should 
 * be plugged into upper row of connector
 *
 * CMC
 * 29 Mar 2016
*/

#include "pmod.h"

// MAILBOX_WRITE_CMD
#define READ_SINGLE_VALUE 0x3 // 0011
#define READ_AND_LOG      0x7 // 0111

// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_ITEM_SIZE sizeof(u32)
#define LOG_CAPACITY  (4000/LOG_ITEM_SIZE)


// ALS data is 8-bit in the middle of 16-bit stream. 
// Two bytes need to be read, and data extracted.
u32 get_sample(){
  u8 raw_data[2];
  spi_transfer(SPI_BASEADDR, 2, raw_data, NULL);
  return ((raw_data[0]<<4)+(raw_data[1]>>4)); 
}


int main(void)
{
   int cmd;
   u16 als_data;
   u32 delay;

   configureSwitch(SS, GPIO_1, MISO, SPICLK, GPIO_4, GPIO_5, GPIO_6, GPIO_7); 

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
	   cb_init(&pmod_log, LOG_BASE_ADDRESS, LOG_CAPACITY, LOG_ITEM_SIZE);
	   delay = MAILBOX_DATA(1);	   
	   MAILBOX_CMD_ADDR = 0x0; 

            do{
               als_data = get_sample();
	       cb_push_back(&pmod_log, &als_data);
	       delay_ms(delay);

            } while((MAILBOX_CMD_ADDR & 0x1)== 0); // do while no new command

            break;

         default:
            MAILBOX_CMD_ADDR = 0x0; // reset command
            break;
      }
   }
   return(0);
}


