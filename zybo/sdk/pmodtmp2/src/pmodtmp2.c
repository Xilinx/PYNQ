/*
 * IOP code (MicroBlaze) for PMOD TMP2
 * PMOD TMP2 is read only, and has IIC interface
 * Operations implemented:
 *   1. Simple, single read from sensor, and write to data area
 *   2. Continuous read from sensor and log to data area
 * Switch configuration is done within this program.
 *
 * CMC
 * 29 Mar 2016
*/

#include "pmod.h"

// Mailbox commands
#define READ_SINGLE_VALUE 0x3 // 0011
#define READ_AND_LOG      0x7 // 0111

// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_ITEM_SIZE sizeof(float)
#define LOG_CAPACITY  (4000/LOG_ITEM_SIZE)

int main(void)
{
   int cmd;
   u8 raw_data[2];
   u32 sample;
   u32 delay;
   float temperature;

   configureSwitch(BLANK, BLANK, SCL, SDA, BLANK, BLANK, SCL, SDA);
   
   // Run application
   while(1){

     // wait and store valid command
      while((MAILBOX_CMD_ADDR & 0x01)==0); 
      cmd = MAILBOX_CMD_ADDR; 

      switch(cmd){

         case READ_SINGLE_VALUE:
	   
	   // get sample in Celsius (x2 reads to clear stale data)
	   iic_read(0x4b,raw_data,2); 
	   iic_read(0x4b,raw_data,2);  
	   sample = (raw_data[0] << 8) | raw_data[1];
	   temperature = (((float)sample)*0.0625)/8; 
	   
	   // write out temperature, reset mailbox
	   MAILBOX_DATA_FLOAT(0) = temperature;
	   MAILBOX_CMD_ADDR = 0x0; 
	   
	   break;
	   
         case READ_AND_LOG:
	   
	   // initialize logging variables, reset cmd
	   cb_init(&pmod_log, LOG_BASE_ADDRESS, LOG_CAPACITY, LOG_ITEM_SIZE);
	   delay = MAILBOX_DATA(1);	   
	   MAILBOX_CMD_ADDR = 0x0; 

	   do{	      
	     // get sample in Celsius (x2 reads to clear stale data)
	     iic_read(0x4b,raw_data,2); 
	     iic_read(0x4b,raw_data,2);
	     sample = (raw_data[0] << 8) | raw_data[1];
	     temperature = (((float)sample)*0.0625)/8; 
	     
	      // log temperature and delay
	     cb_push_back_float(&pmod_log, &temperature);
	     delay_ms(delay);

	   }
	   while((MAILBOX_CMD_ADDR & 0x1)== 0); // do while no new command
	   
	   break;
	   
      default:
	MAILBOX_CMD_ADDR = 0x0; // reset command
	break;
      }
   }
   return 0;
}
