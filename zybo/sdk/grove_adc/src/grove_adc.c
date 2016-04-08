/*
 * IOP code (MicroBlaze) for groveadc
 * Grove ADC is read only, and has IIC interface
 * Operations implemented:
 *   1. Simple, single read from sensor, and write to data area
 *   2. Continuous read from sensor and log to data area
 * Switch configuration is done within this program.
 *
 * CMC
 * 6 April 2016
*/

/* Grove ADC is based on adc121c021  
http://www.ti.com/lit/ds/symlink/adc121c021-q1.pdf
*/

#include "pmod.h"

#define IIC_ADDRESS 0x50

#define V_REF 3.30

// Mailbox commands
// bit 1 always needs to be set
#define READ_SINGLE_VALUE_INT   0x3 
#define READ_SINGLE_VALUE_FLOAT 0x5 
#define READ_AND_LOG_INT        0x7 
#define READ_AND_LOG_FLOAT      0x9 
#define SET_LOW_LEVEL           0xB 
#define SET_HIGH_LEVEL          0xD
#define SET_HYSTERESIS_LEVEL    0xF 
#define READ_LOWEST_LEVEL       0x11
#define READ_HIGHEST_LEVEL      0x13
#define READ_STATUS             0x15
#define RESET_ADC               0x17

// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_ITEM_SIZE sizeof(float)
#define LOG_CAPACITY  (4000/LOG_ITEM_SIZE)

// ADC Registers
#define REG_ADDR_RESULT         0x00
#define REG_ADDR_ALERT          0x01
#define REG_ADDR_CONFIG         0x02
#define REG_ADDR_LIMITL         0x03
#define REG_ADDR_LIMITH         0x04
#define REG_ADDR_HYST           0x05
#define REG_ADDR_CONVL          0x06
#define REG_ADDR_CONVH          0x07

/*float read_adc(){
   u8 raw_data[2];
   u32 sample;
   
   raw_data[0] = REG_ADDR_RESULT;
  
   //iic_write(IIC_ADDRESS, raw_data, 1);
   iic_read(IIC_ADDRESS,raw_data,2); 
   sample = ((raw_data[0]&0x0f) << 8) | raw_data[1];
   return (float)sample*V_REF*2/4096; 
}*/

u32 read_adc(u8 reg){
   u8 raw_data[2];
   u32 sample;
   
   raw_data[0] = reg; // Set the address pointer
   
   iic_write(IIC_ADDRESS, raw_data, 1);
  
   iic_read(IIC_ADDRESS,raw_data,2); 
   sample = ((raw_data[0]&0x0f) << 8) | raw_data[1];
   return sample; 
}

void init_adc(){
   u8 raw_data[2];
   raw_data[0] = REG_ADDR_CONFIG;
   raw_data[1] = 0x20; // Tconvert x 32 ; Typical fconvert 27 ksps 

   iic_write(IIC_ADDRESS, raw_data, 2);
}

// Set high/low/hysteresis limits and clear lowest/highest conversion results
void write_adc(u8 reg, u32 data, u8 bytes){
   u8 raw_data[3];
   raw_data[0] = reg;
   if(bytes ==2){
      raw_data[1] = data & 0x0f; // Bits 11:8
      raw_data[2] = data & 0xff; // Bits 7:0
   }else if(bytes == 2){
      raw_data[1] = data; // Bits 11:8
   }
   
     
   iic_write(IIC_ADDRESS, raw_data, bytes+1);  
   
   raw_data[0] = REG_ADDR_RESULT; // Reset to the result address
   
   iic_write(IIC_ADDRESS, raw_data, 1);
}

int main(void)
{
   int cmd;
   u32 delay;
   int adc_value_int;
   float adc_value_float;
   

   configureSwitch( BLANK, BLANK, SDA, BLANK, BLANK, BLANK, SCL, BLANK);
   init_adc();
   // Run application
   while(1){

     // wait and store valid command
      while((MAILBOX_CMD_ADDR & 0x01)==0); 
      
      cmd = MAILBOX_CMD_ADDR; 
      
      switch(cmd){
         case READ_SINGLE_VALUE_INT:
            // write out adc_value, reset mailbox
            MAILBOX_DATA(0) = read_adc(REG_ADDR_RESULT);
            MAILBOX_CMD_ADDR = 0x0; 

            break;
         case READ_SINGLE_VALUE_FLOAT:
            // write out adc_value, reset mailbox
            MAILBOX_DATA_FLOAT(0) = (float)((read_adc(REG_ADDR_RESULT))*V_REF*2/4096);
            MAILBOX_CMD_ADDR = 0x0; 

            break;
         case READ_AND_LOG_INT:   
            // initialize logging variables, reset cmd
            cb_init(&pmod_log, LOG_BASE_ADDRESS, LOG_CAPACITY, LOG_ITEM_SIZE);
            delay = MAILBOX_DATA(1);   
            MAILBOX_CMD_ADDR = 0x0; 

            do{   
               // push sample to log and delay
               adc_value_int = read_adc(REG_ADDR_RESULT);
               cb_push_back(&pmod_log, &adc_value_int);
               delay_ms(delay);

            } while((MAILBOX_CMD_ADDR & 0x1)== 0); // do while no new command

            break;
         case READ_AND_LOG_FLOAT:   
            // initialize logging variables, reset cmd
            cb_init(&pmod_log, LOG_BASE_ADDRESS, LOG_CAPACITY, LOG_ITEM_SIZE);
            delay = MAILBOX_DATA(1);   
            MAILBOX_CMD_ADDR = 0x0; 

            do{   
               // push sample to log and delay
               adc_value_float = (float)((read_adc(REG_ADDR_RESULT))*V_REF*2/4096);
               cb_push_back_float(&pmod_log, &adc_value_float);
               delay_ms(delay);

            } while((MAILBOX_CMD_ADDR & 0x1)== 0); // do while no new command

            break;
         case SET_LOW_LEVEL:
            write_adc(REG_ADDR_LIMITL, MAILBOX_DATA(0), 2);
            MAILBOX_CMD_ADDR = 0x0; 
            break;
         case SET_HIGH_LEVEL:   
            write_adc(REG_ADDR_LIMITH, MAILBOX_DATA(0), 2);
            MAILBOX_CMD_ADDR = 0x0; 
            break;
         case SET_HYSTERESIS_LEVEL:
            write_adc(REG_ADDR_HYST, MAILBOX_DATA(0), 2);
            MAILBOX_CMD_ADDR = 0x0; 
            break;
         case READ_LOWEST_LEVEL:
            MAILBOX_DATA_FLOAT(0) = read_adc(REG_ADDR_CONVL);
            MAILBOX_CMD_ADDR = 0x0; 
            break;
         case READ_HIGHEST_LEVEL:
            MAILBOX_DATA_FLOAT(0) = read_adc(REG_ADDR_CONVH);
            MAILBOX_CMD_ADDR = 0x0; 
            break;           
         case READ_STATUS:
            MAILBOX_DATA_FLOAT(0) = read_adc(REG_ADDR_ALERT);
            MAILBOX_CMD_ADDR = 0x0; 
            break;
         case RESET_ADC:
            write_adc(REG_ADDR_CONFIG, 0x20, 1);
            MAILBOX_CMD_ADDR = 0x0; 
            break;
         default:
            MAILBOX_CMD_ADDR = 0x0; // reset command
            break;
      }
   }
   return 0;
}
