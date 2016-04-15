/*
 * IOP code (MicroBlaze) for PMOD ALS
 * PMOD DPOT is write only, and has SPI with MOSI only
 * Operations implemented in this application:
 *   1. Simple, single write to DPOT from data area
 *   2. Continuous write to DPOT with RAMP, DELAY and STEP SIZE defined in data area
 * Switch configuration is done within this program, PMOD should
 * be plugged into upper row of connector
 *
 * CMC
 * Version 1.0 19 Nov 2015
 * To do: check how switch should be configured from uPython
*/
#include "pmod.h"

// MAILBOX_WRITE_CMD
// bit 0 : '1' Command received
// bit 1 : '1' write single value to DPOT
// bit 2 : '1' Write continuously to DPOT based on data defined in Mailbox

#define CANCEL 0x1
#define SET_POT_SIMPLE 0x3
#define SET_POT_RAMP 0x5

int main(void)
{
   int cmd;
   u8 dpot_value;
   u32 step_size, delay;

   configureSwitch(SS, MOSI, BLANK, SPICLK, BLANK, BLANK, BLANK, BLANK);

   // Configure SPI
   SpiInit();

   // Run application
   while(1){
      while((MAILBOX_CMD_ADDR & 0x01)==0); // wait for bit[0] to become 1
      cmd = MAILBOX_CMD_ADDR; // get cmd bits
      
      // Check commands
      switch(cmd){
         case CANCEL:    // cancel outstanding transactions
            MAILBOX_CMD_ADDR = 0;
            break;
         case SET_POT_SIMPLE:
            dpot_value = MAILBOX_DATA(0);
            spi_transfer(SPI_BASEADDR, 1, NULL, &dpot_value);
            MAILBOX_CMD_ADDR = 0; // reset mailbox
            break;
         case SET_POT_RAMP:
            dpot_value = MAILBOX_DATA(0);
            step_size = MAILBOX_DATA(1);
            delay = MAILBOX_DATA(2);
            MAILBOX_CMD_ADDR = 0; // reset mailbox
            do{
               spi_transfer(SPI_BASEADDR, 1, NULL, &dpot_value);
               dpot_value = dpot_value + step_size; // Positive ramp
               delay_ms(delay);
            }while((MAILBOX_CMD_ADDR & 0x01)==0); // do continuously until new command
            break;
         default:
            MAILBOX_CMD_ADDR = 0; // reset command
            break;  
      }            
   }
   return(0);
}
