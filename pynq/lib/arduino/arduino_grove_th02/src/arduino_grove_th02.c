/******************************************************************************
 *  Copyright (c) 2016, NECST Laboratory, Politecnico di Milano
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
 * @file arduino_grove_ear_hr.c
 * IOP code (MicroBlaze) for grove Temperature & Humidity Sensor.
 * The sensor has to be connected to an arduino interface 
 * via a shield socket.
 * http://wiki.seeed.cc/Grove-TemptureAndHumidity_Sensor-High-Accuracy_\
 * AndMini-v1.0
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- -------- -----------------------------------------------
 * 1.00a ldt 07/05/16 release
 * 1.00b gn  10/25/16 support arduino shield
 * 1.01  mrn 10/11/20 update initialize function
 *
 * </pre>
 *
 *****************************************************************************/

#include <stdio.h>
#include "arduino_grove_th02.h"
#include "circular_buffer.h"
#include "timer.h"
#include "i2c.h"

static i2c device;

int main(void){
    u32 cmd;
    u32 delay;
    u32 tmp, humidity;

    device = i2c_open_device(0);

    while(1){
      // wait and store valid command
      while((MAILBOX_CMD_ADDR)==0);

      cmd = MAILBOX_CMD_ADDR;

      switch(cmd){
        case CONFIG_IOP_SWITCH:
            // use dedicated I2C - no operation needed

            MAILBOX_CMD_ADDR = 0x0;
            break;
        case READ_DATA:
            humidity = TH02_readHumidity();
            tmp = TH02_readTemperature();

            // write out hr, reset mailbox
            MAILBOX_DATA(0) = tmp;
            MAILBOX_DATA(1) = humidity;
            MAILBOX_CMD_ADDR = 0x0;
            break;
        case READ_AND_LOG_DATA:
            // initialize logging variables, reset cmd
            cb_init(&circular_log, LOG_BASE_ADDRESS, LOG_CAPACITY, 
                    LOG_ITEM_SIZE, 2);
            delay = MAILBOX_DATA(1);
            MAILBOX_CMD_ADDR = 0x0;
            do{
                // push sample to log and delay
                tmp = TH02_readTemperature();
                humidity = TH02_readHumidity();
                cb_push_back(&circular_log, &tmp);
                cb_push_back(&circular_log, &humidity);
                delay_ms(delay);
            } while(MAILBOX_CMD_ADDR == 0); // do while no new command
            break;
        default:
            MAILBOX_CMD_ADDR = 0x0; // reset command
            break;
        }
    }
    return 0;
}


uint16_t TH02_readTemperature(){
    //send measure temp command
    TH02_write(REG_CONFIG, CMD_MEASURE_TEMP);
    //wait until the conversion is done
    wait_for_data();
    uint16_t value = TH02_IIC_ReadData2byte();
    value = value >> 2;
    return value;
}

uint16_t TH02_readHumidity(){
    //send measure hum command
    TH02_write(REG_CONFIG, CMD_MEASURE_HUMI);
    wait_for_data();
    uint16_t value = TH02_IIC_ReadData2byte();
    value = value >> 4;
    return value;
}

void wait_for_data(){
    while((TH02_read(REG_STATUS) & STATUS_RDY_MASK) == 1);
}


void TH02_write(u8 reg, u8 data)
{
    //first is register, second is data
    u8 data_buffer[2];
    data_buffer[0] = reg;
    data_buffer[1] = data;
    i2c_write(device, TH02_I2C_DEV_ID, data_buffer, 2);
}

u8 TH02_read(u8 reg){
    u8 data = 0;
    data = reg; // Set the address pointer register
    i2c_write(device, TH02_I2C_DEV_ID, &data, 1);
    i2c_read(device, TH02_I2C_DEV_ID,&data, 1);
    return data;
}

void TH02_read_3(u8 reg, u8 * data_par){
    data_par[0] = reg; // Set the address pointer register
    i2c_write(device, TH02_I2C_DEV_ID, data_par, 1);
    i2c_read(device, TH02_I2C_DEV_ID, data_par, 3);
}

uint16_t TH02_IIC_ReadData2byte(){
    uint16_t tempData = 0;
    u8 tmpArray[3] = {};
    TH02_read_3(REG_DATA_H, tmpArray);
    tempData = (tmpArray[1]<<8) | (tmpArray[2]);
    return tempData;
}
