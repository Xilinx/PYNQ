/******************************************************************************
 *  Copyright (c) 2016, Xilinx, Inc.
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
 * @file rpi_touchpad.c
 *
 * IOP code (MicroBlaze) for RPi touch keypad.
 * The touch keypad features TONTEK TonTouch touch pad detector IC 
 * TTP229-LSF, supports up to 16 keys with adjustable sensitivity and 
 * built-in LD0.
 * Touch keypad is read only, and has IIC interface.
 * https://www.seeedstudio.com/Raspberry-Pi-Touch-Keypad-p-2772.html
 * http://www.tontek.com.tw/download.asp?sn=737
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a yrq 11/30/17 release
 * 2.20  yrq 03/14/17 support pynqmb library, rename to rpi_touchpad
 *
 * </pre>
 *
 *****************************************************************************/

#include "xio_switch.h"
#include "circular_buffer.h"
#include "i2c.h"

// Device constants
#define TOUCHPAD_DEV_ADDRESS         0x57

// Mailbox commands
#define CONFIG_IOP_SWITCH       0x1
#define GET_TOUCHPAD_DATA       0x3
#define RESET                   0xF

static i2c device;

int main()
{
   int cmd;
   uint8_t data[2];

   device = i2c_open_device(1);

   // Run application
   while(1){
     // wait and store valid command
      while((MAILBOX_CMD_ADDR & 0x01)==0);
      cmd = MAILBOX_CMD_ADDR;

      switch(cmd){
          case CONFIG_IOP_SWITCH:
            // use dedicated I2C
            set_pin(2, SDA1);
            set_pin(3, SCL1);
            MAILBOX_CMD_ADDR = 0x0;
            break;
            
         case GET_TOUCHPAD_DATA:
            i2c_read(device, TOUCHPAD_DEV_ADDRESS, data, 2);
            MAILBOX_DATA(0) = (unsigned int) ((data[0] << 8) + data[1]);
            MAILBOX_CMD_ADDR = 0x0; 
            break;

         case RESET:
            MAILBOX_CMD_ADDR = 0x0;
            break;
            
         default:
            MAILBOX_CMD_ADDR = 0x0;
            break;
      }
   }
   return 0;
}
