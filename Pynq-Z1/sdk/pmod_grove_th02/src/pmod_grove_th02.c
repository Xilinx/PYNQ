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
 * The sensor has to be connected to a PMOD interface 
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
 * 1.00b gn  10/24/16 support for PYNQ-Z1
 *
 * </pre>
 *
 *****************************************************************************/

#include <stdio.h>
#include "pmod_grove_th02.h"
#include "pmod.h"

int main(void){
    u32 cmd;
    u32 delay;
    u8 iop_pins[8];
    u32 scl, sda;
    u32 tmp, humidity;

    // Initialize Pmod
    pmod_init(0,1);
    config_pmod_switch(GPIO_0, GPIO_1, SDA, SDA, GPIO_4, GPIO_5, SCL, SCL);

    // Run application
    while(1){
        // wait and store valid command
        while((MAILBOX_CMD_ADDR)==0);

        cmd = MAILBOX_CMD_ADDR;

        switch(cmd){
            case CONFIG_IOP_SWITCH:
                // read new pin configuration
                scl = MAILBOX_DATA(0);
                sda = MAILBOX_DATA(1);
                iop_pins[0] = GPIO_0;
                iop_pins[1] = GPIO_1;
                iop_pins[2] = GPIO_2;
                iop_pins[3] = GPIO_3;
                iop_pins[4] = GPIO_4;
                iop_pins[5] = GPIO_5;
                iop_pins[6] = GPIO_6;
                iop_pins[7] = GPIO_7;
                // set new pin configuration
                iop_pins[scl] = SCL;
                iop_pins[sda] = SDA;
                config_pmod_switch(iop_pins[0], iop_pins[1], iop_pins[2], 
                       iop_pins[3], iop_pins[4], iop_pins[5], 
                       iop_pins[6], iop_pins[7]);

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
                cb_init(&pmod_log, LOG_BASE_ADDRESS, LOG_CAPACITY, 
                        LOG_ITEM_SIZE);
                delay = MAILBOX_DATA(1);
                MAILBOX_CMD_ADDR = 0x0;
                do{
                // push sample to log and delay
                tmp = TH02_readTemperature();
                humidity = TH02_readHumidity();
                cb_push_back(&pmod_log, &tmp);
                cb_push_back(&pmod_log, &humidity);
                delay_ms(delay);
                } while(MAILBOX_CMD_ADDR == 0);
                break;
            default:
                MAILBOX_CMD_ADDR = 0x0; // reset command
                break;
        }
    }
    return 0;
}


uint16_t TH02_readTemperature(){
    //we want to measure a temperature
    TH02_write(REG_CONFIG, CMD_MEASURE_TEMP);
    //wait until the conversion is done
    wait_for_data();
    uint16_t value = TH02_IIC_ReadData2byte();
    value = value >> 2;
    return value;
}

uint16_t TH02_readHumidity(){
    //we want to measure humidity
    TH02_write(REG_CONFIG, CMD_MEASURE_HUMI);
    wait_for_data();
    uint16_t value = TH02_IIC_ReadData2byte();
    value = value >> 4;
    return value;
}

void wait_for_data(){
    while((TH02_read(REG_STATUS) & STATUS_RDY_MASK) == 1);
}


int TH02_write(u8 reg, u8 data)
{
    //first is register, second is data
    u8 data_buffer[2];
    data_buffer[0] = reg;
    data_buffer[1] = data;
    return iic_write(IIC_BASEADDR, TH02_I2C_DEV_ID, data_buffer, 2);
}

u8 TH02_read(u8 reg){
    u8 data = 0;

    data = reg; // Set the address pointer register

    iic_write(IIC_BASEADDR, TH02_I2C_DEV_ID, &data, 1);
    iic_read(IIC_BASEADDR, TH02_I2C_DEV_ID,&data, 1);

    return data;
}

void TH02_read_3(u8 reg, u8 * data_par){
    data_par[0] = reg; // Set the address pointer register
    iic_write(IIC_BASEADDR, TH02_I2C_DEV_ID, data_par, 1);
    iic_read(IIC_BASEADDR, TH02_I2C_DEV_ID, data_par, 3);
}

uint16_t TH02_IIC_ReadData2byte(){
    uint16_t tempData = 0;
    u8 tmpArray[3] = {};

    //TH02_write(REG_DATA_H,0x1);
    //iic_write(TH02_I2C_DEV_ID,REG_DATA_H,1);
    TH02_read_3(REG_DATA_H, tmpArray);

    tempData = (tmpArray[1]<<8) | (tmpArray[2]);

    return tempData;
}



