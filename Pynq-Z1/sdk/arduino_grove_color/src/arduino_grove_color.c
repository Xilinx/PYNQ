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
 * @file aduino_grove_color.c
 * IOP code (MicroBlaze) for grove color sensor.
 * The grove color sensor has to be connected to an arduino interface 
 * via a shield socket.
 * http://wiki.seeed.cc/Grove-I2C_Color_Sensor
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- -------- -----------------------------------------------
 * 1.00a lcc 06/22/16 release
 * 1.00b gn  10/25/16 support arduino shield
 *
 * </pre>
 *
 *****************************************************************************/

#include "arduino.h"

// Mailbox commands
// bit 1 always needs to be sets
#define CONFIG_IOP_SWITCH      0x1
#define READ_DATA            0x2
#define READ_AND_LOG_DATA    0x3
#define STOP_LOG               0xC


/*control registers*/
//the I2C address for the color sensor
#define COLOR_SENSOR_ADDR  0x39
#define REG_CTL 0x80
#define REG_TIMING 0x81
#define REG_INT 0x82
#define REG_INT_SOURCE 0x83
#define REG_ID 0x84
#define REG_GAIN 0x87
#define REG_LOW_THRESH_LOW_BYTE 0x88
#define REG_LOW_THRESH_HIGH_BYTE 0x89
#define REG_HIGH_THRESH_LOW_BYTE 0x8A
#define REG_HIGH_THRESH_HIGH_BYTE 0x8B
//The REG_BLOCK_READ and REG_GREEN_LOW direction are the same
#define REG_BLOCK_READ 0xD0
#define REG_GREEN_LOW 0xD0
#define REG_GREEN_HIGH 0xD1
#define CTL_DAT_INIITIATE 0x03
#define CLR_INT 0xE0

//Timing Register
#define SYNC_EDGE 0x40
#define INTEG_MODE_FREE 0x00
#define INTEG_MODE_MANUAL 0x10
#define INTEG_MODE_SYN_SINGLE 0x20
#define INTEG_MODE_SYN_MULTI 0x30

#define INTEG_PARAM_PULSE_COUNT1 0x00
#define INTEG_PARAM_PULSE_COUNT2 0x01
#define INTEG_PARAM_PULSE_COUNT4 0x02
#define INTEG_PARAM_PULSE_COUNT8 0x03

//Interrupt Control Register
#define INTR_STOP 40
#define INTR_DISABLE 0x00
#define INTR_LEVEL 0x10
#define INTR_PERSIST_EVERY 0x00
#define INTR_PERSIST_SINGLE 0x01

//Interrupt Souce Register
#define INT_SOURCE_GREEN 0x00

//Gain Register
#define GAIN_1 0x00
#define GAIN_4 0x10
#define GAIN_16 0x20
#define GAIN_64 0x30
#define PRESCALER_1 0x00
#define PRESCALER_2 0x01
#define PRESCALER_4 0x02
#define PRESCALER_8 0x03
#define PRESCALER_16 0x04
#define PRESCALER_32 0x05
#define PRESCALER_64 0x06

//Timing constants
#define READ_DELAY_MS 100

// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_ITEM_SIZE sizeof(float)
#define LOG_CAPACITY  (4000/LOG_ITEM_SIZE)


void init_csens();
int write_csens(u8 reg, u32 data);
void read_csens(u8 reg, u8 *data_buffer, int numbytes);
void readRGB_csens(u32 rgb[4]);


void init_csens(){
    write_csens(REG_TIMING, INTEG_MODE_FREE | INTEG_PARAM_PULSE_COUNT1);
    delay_ms(10);
    write_csens(REG_GAIN, GAIN_1 | PRESCALER_1);
    delay_ms(10);
    write_csens(REG_CTL, CTL_DAT_INIITIATE);
    delay_ms(10);
}

int write_csens(u8 reg, u32 data){
    u8 data_buffer[3];
    data_buffer[0] = reg;
    data_buffer[1] = data & 0xff; // Bits 7:0
    return iic_write(XPAR_IIC_0_BASEADDR, COLOR_SENSOR_ADDR, data_buffer, 2);
}

void read_csens(u8 reg, u8 *data_buffer, int numbytes){
    data_buffer[0] = reg; // Set the address pointer register
    iic_write(XPAR_IIC_0_BASEADDR, COLOR_SENSOR_ADDR, data_buffer, 1);
    delay_ms(READ_DELAY_MS);
    iic_read(XPAR_IIC_0_BASEADDR, COLOR_SENSOR_ADDR, data_buffer, numbytes);
}
 
void readRGB_csens(u32 rgb[4])
{
    u8 readData[8];
    read_csens(REG_BLOCK_READ, readData, 8);
    rgb[0] = readData[1] * 256 + readData[0]; //green
    rgb[1] = readData[3] * 256 + readData[2]; //red
    rgb[2] = readData[5] * 256 + readData[4]; //blue
    rgb[3] = readData[7] * 256 + readData[6]; //clear
}

int main(void)
{
    u32 cmd;
    u32 rgb[4];

    arduino_init(0,0,0,0);
    config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, 
                          A_GPIO, A_SDA, A_SCL,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO);

    // Run application
    while(1){
        // wait and store valid command
        while((MAILBOX_CMD_ADDR)==0);
        cmd = MAILBOX_CMD_ADDR;

        switch(cmd){
            case CONFIG_IOP_SWITCH:
                // use dedicated I2C
                config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, 
                                      A_GPIO, A_SDA, A_SCL,
                                      D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                                      D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                                      D_GPIO, D_GPIO, D_GPIO, D_GPIO);  
            
                init_csens();
                MAILBOX_CMD_ADDR = 0x0;
                break;
            case READ_DATA:
                readRGB_csens(rgb);
                // write out readColor, reset mailbox
                MAILBOX_DATA(0) = rgb[0];
                MAILBOX_DATA(1) = rgb[1];
                MAILBOX_DATA(2) = rgb[2];
                MAILBOX_DATA(3) = rgb[3];
                MAILBOX_CMD_ADDR = 0x0;
                break;

            default:
                MAILBOX_CMD_ADDR = 0x0; // reset command
                break;
        }
    }
    return 0;
}
