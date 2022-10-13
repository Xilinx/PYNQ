/******************************************************************************
 *  Copyright (c) 2016, Xilinx, Inc.
 *  SPDX-License-Identifier: BSD-3-Clause
 *
 *****************************************************************************/
/******************************************************************************
 *
 *
 * @file arduino_grove_adc.c
 *
 * IOP code (MicroBlaze) for grove ADC121C021.
 * The grove ADC has to be connected to an arduino interface 
 * via a shield socket.
 * Grove ADC is read only, and has IIC interface
 * Operations implemented:
 *  1. Simple, single read from sensor, and write to data area.
 *  2. Continuous read from sensor and log to data area.
 * Hardware version 1.2.
 * http://www.ti.com/lit/ds/symlink/adc121c021-q1.pdf
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a cmc 04/06/16 release
 * 1.00b yrq 05/02/16 support 2 stickit sockets
 * 1.00d yrq 07/26/16 separate pmod and arduino
 * 1.01  mrn 10/11/20 update initialize function
 * </pre>
 *
 *****************************************************************************/

#include "i2c.h"
#include "timer.h"
#include "circular_buffer.h"

#define IIC_ADDRESS 0x50

// VRef = Va measured on the board
#define V_REF 3.10

// Mailbox commands
// bit 1 always needs to be set

#define CONFIG_IOP_SWITCH      0x1
#define READ_RAW_DATA          0x2 
#define READ_VOLTAGE           0x3 
#define READ_AND_LOG_RAW_DATA  0x4 
#define READ_AND_LOG_VOLTAGE   0x5 
#define SET_LOW_LEVEL          0x6 
#define SET_HIGH_LEVEL         0x7
#define SET_HYSTERESIS_LEVEL   0x8 
#define READ_LOWEST_LEVEL      0x9
#define READ_HIGHEST_LEVEL     0xA
#define READ_STATUS            0xB
#define RESET_ADC              0xC

// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_ITEM_SIZE sizeof(float)
#define LOG_CAPACITY  (4000/LOG_ITEM_SIZE)

// ADC Registers
#define REG_ADDR_RESULT        0x00
#define REG_ADDR_ALERT         0x01
#define REG_ADDR_CONFIG        0x02
#define REG_ADDR_LIMITL        0x03
#define REG_ADDR_LIMITH        0x04
#define REG_ADDR_HYST          0x05
#define REG_ADDR_CONVL         0x06
#define REG_ADDR_CONVH         0x07

static i2c device;

// Read from a Register
u32 read_adc(u8 reg){
   u8 data_buffer[2];
   u32 sample;
   
   data_buffer[0] = reg; // Set the address pointer register
   i2c_write(device, IIC_ADDRESS, data_buffer, 1);
  
   i2c_read(device, IIC_ADDRESS,data_buffer,2);
   sample = ((data_buffer[0]&0x0f) << 8) | data_buffer[1];
   return sample; 
}


// Write a number of bytes to a Register
// Maximum of 2 data bytes can be written in one transaction
void write_adc(u8 reg, u32 data, u8 bytes){
   u8 data_buffer[3];
   data_buffer[0] = reg;
   if(bytes ==2){
      data_buffer[1] = data & 0x0f; // Bits 11:8
      data_buffer[2] = data & 0xff; // Bits 7:0
   }else{
      data_buffer[1] = data & 0xff; // Bits 7:0
   }
   i2c_write(device, IIC_ADDRESS, data_buffer, bytes+1);
}

int main(void)
{
   u32 cmd;
   u32 delay;

   u32 adc_raw_value;
   float adc_voltage;
   device = i2c_open_device(0);
 
   // Reset, set Tconvert x 32 (fconvert 27 ksps)
   write_adc(REG_ADDR_CONFIG, 0x20, 1); 
   // Run application
   while(1){

      // wait and store valid command
      while((MAILBOX_CMD_ADDR)==0);
      cmd = MAILBOX_CMD_ADDR;
      
      switch(cmd){
         case CONFIG_IOP_SWITCH:
            // use dedicated I2C
            MAILBOX_CMD_ADDR = 0x0;
            break;
            
         case READ_RAW_DATA:
            // write out adc_value, reset mailbox
            MAILBOX_DATA(0) = 2*read_adc(REG_ADDR_RESULT);
            MAILBOX_CMD_ADDR = 0x0; 
            break;
            
         case READ_VOLTAGE:
            // write out adc_value, reset mailbox
            adc_voltage = (float)((read_adc(REG_ADDR_RESULT))*V_REF*2/4096);
            MAILBOX_DATA_FLOAT(0) = adc_voltage;
            MAILBOX_CMD_ADDR = 0x0;
            break;
            
         case READ_AND_LOG_RAW_DATA:   
            // initialize logging variables, reset cmd
            cb_init(&circular_log, 
                    LOG_BASE_ADDRESS, LOG_CAPACITY, LOG_ITEM_SIZE, 1);
            delay = MAILBOX_DATA(1);
            while(MAILBOX_CMD_ADDR != RESET_ADC){   
               // push sample to log and delay
               adc_raw_value = 2*read_adc(REG_ADDR_RESULT);
               cb_push_back(&circular_log, &adc_raw_value);
               delay_ms(delay);
            }
            MAILBOX_CMD_ADDR = 0x0;
            break;
            
         case READ_AND_LOG_VOLTAGE:
            // initialize logging variables, reset cmd
            cb_init(&circular_log, 
                    LOG_BASE_ADDRESS, LOG_CAPACITY, LOG_ITEM_SIZE, 1);
            delay = MAILBOX_DATA(1);
            while(MAILBOX_CMD_ADDR != RESET_ADC){
               // push sample to log and delay
               adc_voltage = (float)((read_adc(REG_ADDR_RESULT))*V_REF*2/4096);
               cb_push_back_float(&circular_log, &adc_voltage);
               delay_ms(delay);
            }
            MAILBOX_CMD_ADDR = 0x0;
            break;
            
         case RESET_ADC:
            write_adc(REG_ADDR_CONFIG, 0x20, 1);
            MAILBOX_CMD_ADDR = 0x0;
            break;
            
         default:
            MAILBOX_CMD_ADDR = 0x0;
            break;
            
      }
   }
   return 0;
}

