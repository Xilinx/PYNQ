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
 * @file arduino_grove_haptic_motor.c
 * IOP code (MicroBlaze) for grove haptic motor.
 * The haptic motor has to be connected to an arduino interface 
 * via a shield socket.
 * http://wiki.seeed.cc/Grove-Haptic_Motor/
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- -------- -----------------------------------------------
 * 1.00a lcc 06/22/16 release
 * 1.00b mr  06/23/16 some fixes
 * 1.00c gn  10/25/16 support arduino shield
 *
 * </pre>
 *
 *****************************************************************************/

#include "arduino.h"


// Mailbox commands
// bit 1 always needs to be sets
#define CONFIG_IOP_SWITCH      0x1
#define START_WAVEFORM         0x2
#define STOP_WAVEFORM          0x3
#define READ_IS_PLAYING        0x4

#define STATUS_Reg          0x00
#define MODE_Reg            0x01
#define RTP_INPUT_Reg       0x02
#define LIB_SEL_Reg         0x03
#define WAV_SEQ1_Reg        0x04
#define WAV_SEQ2_Reg        0x05
#define WAV_SEQ3_Reg        0x06
#define WAV_SEQ4_Reg        0x07
#define WAV_SEQ5_Reg        0x08
#define WAV_SEQ6_Reg        0x09
#define WAV_SEQ7_Reg        0x0A
#define WAV_SEQ8_Reg        0x0B
#define GO_Reg              0x0C
#define ODT_OFFSET_Reg      0x0D
#define SPT_Reg             0x0E
#define SNT_Reg             0x0F
#define BRT_Reg             0x10
#define ATV_CON_Reg         0x11
#define ATV_MIN_IN_Reg      0x12
#define ATV_MAX_IN_Reg      0x13
#define ATV_MIN_OUT_Reg     0x14
#define ATV_MAX_OUT_Reg     0x15
#define RATED_VOLTAGE_Reg   0x16
#define OD_CLAMP_Reg        0x17
#define A_CAL_COMP_Reg      0x18
#define A_CAL_BEMF_Reg      0x19
#define FB_CON_Reg          0x1A
#define CONTRL1_Reg         0x1B
#define CONTRL2_Reg         0x1C
#define CONTRL3_Reg         0x1D
#define CONTRL4_Reg         0x1E
#define VBAT_MON_Reg        0x21
#define LRA_RESON_Reg       0x22

// haptic motor driver address
#define DRV2605_ADDRESS 0x5A


int write_hapt(u8 reg, u8 data);
u8 read_hapt(u8 reg);
void play_hapt(u8 *waveforms);
void stop_hapt();
u32 is_playing_hapt();
void auto_calibrate_hapt();


int write_hapt(u8 reg, u8 data)
{
    u8 data_buffer[2];
    data_buffer[0] = reg;
    data_buffer[1] = data;
    return iic_write(XPAR_IIC_0_BASEADDR, DRV2605_ADDRESS, data_buffer, 2);
}

u8 read_hapt(u8 reg){
    u8 data;

    data = reg; // Set the address pointer register
    iic_write(XPAR_IIC_0_BASEADDR, DRV2605_ADDRESS, &data, 1);
    iic_read(XPAR_IIC_0_BASEADDR, DRV2605_ADDRESS, &data, 1);
    return data;
}

void auto_calibrate_hapt()
{
    u8 temp = 0x00;

    /*set rated voltage*/
    write_hapt(RATED_VOLTAGE_Reg, 0x50);

    /*set overdrive voltage*/
    write_hapt(OD_CLAMP_Reg, 0x89);

    /*Setup feedback and control*/
    write_hapt(FB_CON_Reg,0xB6);
    write_hapt(CONTRL1_Reg,0x93);
    write_hapt(CONTRL2_Reg,0xF5);
    write_hapt(CONTRL3_Reg,0x80);

    /*Set autocalibration mode*/
    write_hapt(MODE_Reg,0x07);
    write_hapt(CONTRL4_Reg,0x20);

    /*Begin auto calibration*/
    write_hapt(GO_Reg, 0x01);

    while((temp & 0x01) != 0x01)
        temp = read_hapt(GO_Reg);
    while((temp & 0x01) != 0x00)
        temp = read_hapt(GO_Reg);
}

void play_hapt(u8 *waveforms)
{
    int i;

    write_hapt(GO_Reg, 0x00);
    write_hapt(MODE_Reg, 0x00);
    for(i=0; i<8; i++)
        write_hapt(WAV_SEQ1_Reg + i, waveforms[i]);
    write_hapt(GO_Reg, 0x01);
}

void stop_hapt()
{
    write_hapt(GO_Reg, 0x00);
}

u32 is_playing_hapt()
{
    return read_hapt(GO_Reg) & 0x01;
}

int main(void)
{
    u32 cmd;
    int i;
    u8 waveforms[8];

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

                // perform driver calibration
                auto_calibrate_hapt();

                MAILBOX_CMD_ADDR = 0x0;
                break;
            case START_WAVEFORM:
                // read waveforms from mailbox
                for(i=0; i<8; i++)
                    waveforms[i] = MAILBOX_DATA(i) & 0xff;
                play_hapt(waveforms);
                MAILBOX_CMD_ADDR = 0x0;
                break;
            case STOP_WAVEFORM:
                stop_hapt();
                MAILBOX_CMD_ADDR = 0x0;
                break;
            case READ_IS_PLAYING:
                MAILBOX_DATA(0) = is_playing_hapt();
                MAILBOX_CMD_ADDR = 0x0;
                break;
            default:
                MAILBOX_CMD_ADDR = 0x0; // reset command
                break;
        }
    }
    return 0;
}
