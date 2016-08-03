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
 * @file pmod_dac.c
 *
 * IOP code (MicroBlaze) for Pmod DA4
 * Pmod DA4 is write only, and has SPI interface.
 * Switch configuration is done within this program, Pmod can be plugged 
 * into upper row or lower row of the connector.
 * The Pmod DA4 is an 8 channel 12-bit digital-to-analog converter run via 
 * the analog devices AD5628. 
 * http://store.digilentinc.com/pmodda4-eight-12-bit-d-a-outputs/
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a cmc 03/29/16 release
 * 1.00b pp  05/27/16 fix pmod_init()
 *
 * </pre>
 *
 *****************************************************************************/

#include "xparameters.h"
#include "pmod.h"

#define SPI_BASEADDR XPAR_SPI_0_BASEADDR // base address of QSPI[0]
/*
 * Passed parameters in MAILBOX_WRITE_CMD
 * bits 31:20 => delay in microsecond if wave generation mode is selected
 * bits 31:20 => 12-bit value to be output if fixed value mode is selected
 * bits 19:16 => 4-bit value indicates channels to be used
 * bits 15:8 => number of cycles to be produced in wave generation mode, 
 *              if it is set to 0, then generate waveforms forever
 * bit 7 => not used
 * bit 6 => random wave generation - pattern is written in MAILBOX_DATA area
 *          with MAILBOX_DATA(0) having number of samples per cycle, followed 
 *          by 12-bit values in each word
 * bit 5 => Sine wave generation mode
 * bit 4 => Triangle waveform generation mode
 * bit 3 => Sawtooth generation mode
 * bit 2 => Square wave generation mode
 * bit 1 => Fixed Value mode
 * bit 0 => 1 command issued, 0 command completed
 *
 * Channels table
 * bits [19:16]
 * 0000 => Channel A
 * 0001 => Channel B
 * 0010 => Channel C
 * 0011 => Channel D
 * 0100 => Channel E
 * 0101 => Channel F
 * 0110 => Channel G
 * 1111 => All channels
 */

#define BUFFER_SIZE     6

typedef u8 DataBuffer[BUFFER_SIZE];

u8 WriteBuffer[BUFFER_SIZE];

static int sinetable[256] = {
        0x80, 0x83, 0x86, 0x89, 0x8C, 0x90, 0x93, 0x96,
        0x99, 0x9C, 0x9F, 0xA2, 0xA5, 0xA8, 0xAB, 0xAE,
        0xB1, 0xB3, 0xB6, 0xB9, 0xBC, 0xBF, 0xC1, 0xC4,
        0xC7, 0xC9, 0xCC, 0xCE, 0xD1, 0xD3, 0xD5, 0xD8,
        0xDA, 0xDC, 0xDE, 0xE0, 0xE2, 0xE4, 0xE6, 0xE8,
        0xEA, 0xEB, 0xED, 0xEF, 0xF0, 0xF1, 0xF3, 0xF4,
        0xF5, 0xF6, 0xF8, 0xF9, 0xFA, 0xFA, 0xFB, 0xFC,
        0xFD, 0xFD, 0xFE, 0xFE, 0xFE, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xFE, 0xFE, 0xFD,
        0xFD, 0xFC, 0xFB, 0xFA, 0xFA, 0xF9, 0xF8, 0xF6,
        0xF5, 0xF4, 0xF3, 0xF1, 0xF0, 0xEF, 0xED, 0xEB,
        0xEA, 0xE8, 0xE6, 0xE4, 0xE2, 0xE0, 0xDE, 0xDC,
        0xDA, 0xD8, 0xD5, 0xD3, 0xD1, 0xCE, 0xCC, 0xC9,
        0xC7, 0xC4, 0xC1, 0xBF, 0xBC, 0xB9, 0xB6, 0xB3,
        0xB1, 0xAE, 0xAB, 0xA8, 0xA5, 0xA2, 0x9F, 0x9C,
        0x99, 0x96, 0x93, 0x90, 0x8C, 0x89, 0x86, 0x83,
        0x80, 0x7D, 0x7A, 0x77, 0x74, 0x70, 0x6D, 0x6A,
        0x67, 0x64, 0x61, 0x5E, 0x5B, 0x58, 0x55, 0x52,
        0x4F, 0x4D, 0x4A, 0x47, 0x44, 0x41, 0x3F, 0x3C,
        0x39, 0x37, 0x34, 0x32, 0x2F, 0x2D, 0x2B, 0x28,
        0x26, 0x24, 0x22, 0x20, 0x1E, 0x1C, 0x1A, 0x18,
        0x16, 0x15, 0x13, 0x11, 0x10, 0x0F, 0x0D, 0x0C,
        0x0B, 0x0A, 0x08, 0x07, 0x06, 0x06, 0x05, 0x04,
        0x03, 0x03, 0x02, 0x02, 0x02, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x03,
        0x03, 0x04, 0x05, 0x06, 0x06, 0x07, 0x08, 0x0A,
        0x0B, 0x0C, 0x0D, 0x0F, 0x10, 0x11, 0x13, 0x15,
        0x16, 0x18, 0x1A, 0x1C, 0x1E, 0x20, 0x22, 0x24,
        0x26, 0x28, 0x2B, 0x2D, 0x2F, 0x32, 0x34, 0x37,
        0x39, 0x3C, 0x3F, 0x41, 0x44, 0x47, 0x4A, 0x4D,
        0x4F, 0x52, 0x55, 0x58, 0x5B, 0x5E, 0x61, 0x64,
        0x67, 0x6A, 0x6D, 0x70, 0x74, 0x77, 0x7A, 0x7D
         };

void RefOn(void) {
    // Turn ON internal reference voltage
    WriteBuffer[3]=0x01;
    // This byte must be 0
    WriteBuffer[2]=0x00;
    // channel number (0) | least significant 4-bits data
    WriteBuffer[1]=0x00;
    // write to and update requested channel
    WriteBuffer[0]=0x08;
    spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
}

void RefOFF(void) {
    // Turn OFF internal reference voltage
    WriteBuffer[3]=0x00;
    // This byte must be 0
    WriteBuffer[2]=0x00;
    // channel number (0) | least significant 4-bits data
    WriteBuffer[1]=0x00;
    // write to and update requested channel
    WriteBuffer[0]=0x08;
    spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
}

void FixedGen(u8 channels, u16 fixedvalue) {
    // 0x55 - this is the dummy data for 12-bit dac
    WriteBuffer[3] = 0x55;
    // least significant 8-bits data
    WriteBuffer[2] = fixedvalue & 0xff;
    // channel number (0) | most significant 4-bits data
    WriteBuffer[1] = (channels << 4) | (fixedvalue >> 8);
    // 4 most significant bits don't care | write and update DAC command
    WriteBuffer[0] = 0x03;

    spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
}

void SqWaveGen(u8 channels, u8 numofcycles, u16 delay) {
    int i, j;

    WriteBuffer[3] = 0x55;
    WriteBuffer[0] = 0x03;

    if(numofcycles==0){
        for(;;){
            WriteBuffer[2] = 0xff;
            WriteBuffer[1] = (channels << 4) | 0x0f;
            for(j=0; j< 4096; j++) {
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay>2)
                    delay_us(delay/2);
            }
            WriteBuffer[2] = 0x00;
            WriteBuffer[1] = (channels << 4) | 0x00;
            for(j=0; j< 4096; j++) {
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay>2)
                    delay_us(delay/2);
            }
        }
    }
    else {
        for(i=0; i<numofcycles ; i++) {
            WriteBuffer[2] = 0xff;
            WriteBuffer[1] = (channels << 4) | 0x0f;
            for(j=0; j< 4096; j++) {
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay>2)
                    delay_us(delay/2);
            }
            WriteBuffer[2] = 0x00;
            WriteBuffer[1] = (channels << 4) | 0x00;
            for(j=0; j< 4096; j++) {
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay>2)
                    delay_us(delay/2);
            }
        }
    }
}

void SawToothWaveGen(u8 channels, u8 numofcycles, u16 delay) {
    int i, j;

    WriteBuffer[3] = 0x55;
    WriteBuffer[0] = 0x03;

    if(numofcycles==0){
        for(;;){
            for(j=0; j< 4096; j++) {
                WriteBuffer[2] = j & 0xff;
                WriteBuffer[1] = (channels << 4) | ((j >> 8 ) & 0x0f);
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay)
                    delay_us(delay);
            }
            WriteBuffer[2] = 0x00;
            WriteBuffer[1] = (channels << 4) | 0x00;
            spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
            if(delay)
                delay_us(delay);
        }
    }
    else {
        for(i=0; i<numofcycles ; i++) {
            for(j=0; j< 4096; j++) {
                WriteBuffer[2] = j & 0xff;
                WriteBuffer[1] = (channels << 4) | ((j >> 8 ) & 0x0f);
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay)
                    delay_us(delay);
            }
            WriteBuffer[2] = 0x00;
            WriteBuffer[1] = (channels << 4) | 0x00;
            spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
            if(delay)
                delay_us(delay);
        }
    }
}

void TriangleWaveGen(u8 channels, u8 numofcycles, u16 delay) {
    int i, j;

    WriteBuffer[3] = 0x55;
    WriteBuffer[0] = 0x03;

    if(numofcycles==0){
        for(;;){
            for(j=0; j< 4096; j++) {
                WriteBuffer[2] = j & 0xff;
                WriteBuffer[1] = (channels << 4) | ((j >> 8 ) & 0x0f);
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay)
                    delay_us(delay);
            }
            for(j=4095; j>=0; j--) {
                WriteBuffer[2] = j & 0xff;
                WriteBuffer[1] = (channels << 4) | ((j >> 8 ) & 0x0f);
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay)
                    delay_us(delay);
            }
        }
    }
    else {
        for(i=0; i<numofcycles ; i++) {
            for(j=0; j< 4096; j++) {
                WriteBuffer[2] = j & 0xff;
                WriteBuffer[1] = (channels << 4) | ((j >> 8 ) & 0x0f);
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay)
                    delay_us(delay);
            }
            for(j=4095; j>=0; j--) {
                WriteBuffer[2] = j & 0xff;
                WriteBuffer[1] = (channels << 4) | ((j >> 8 ) & 0x0f);
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay)
                    delay_us(delay);
            }
        }
    }
}

void SineWaveGen(u8 channels, u8 numofcycles, u16 delay) {
    int i, j;
    int num;

    WriteBuffer[3] = 0x55;
    WriteBuffer[0] = 0x03;

    if(numofcycles==0){
        for(;;){
            for(j=0; j< 4096; j++) {
                num = (sinetable[j%256] << 4);
                WriteBuffer[2] = num & 0xff;
                WriteBuffer[1] = (channels << 4) | ((num >> 8 ) & 0x0f);
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay)
                    delay_us(delay);
            }
        }
    }
    else {
        for(i=0; i<numofcycles ; i++) {
            for(j=0; j< 4096; j++) {
                num = (sinetable[j%256] << 4);
                WriteBuffer[2] = num & 0xff;
                WriteBuffer[1] = (channels << 4) | ((num >> 8 ) & 0x0f);
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay)
                    delay_us(delay);
            }
        }
    }

}

void RandomWaveGen(u8 channels, u8 numofcycles, u16 delay) {
    int i, j;
    int num, numofsamples;

    WriteBuffer[3] = 0x55;
    WriteBuffer[0] = 0x03;

    numofsamples=MAILBOX_DATA(0);
    if(numofcycles==0){
        for(;;){
            for(j=0; j< numofsamples; j++) {
                num = MAILBOX_DATA((j%256)+1);
                WriteBuffer[2] = num & 0xff;
                WriteBuffer[1] = (channels << 4) | ((num >> 8 ) & 0x0f);
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay)
                    delay_us(delay);
            }
        }
    }
    else {
        for(i=0; i<numofcycles ; i++) {
            for(j=0; j< numofsamples; j++) {
                num = MAILBOX_DATA((j%256)+1);
                WriteBuffer[2] = num & 0xff;
                WriteBuffer[1] = (channels << 4) | ((num >> 8 ) & 0x0f);
                spi_transfer(SPI_BASEADDR, 4, NULL, WriteBuffer);
                if(delay)
                    delay_us(delay);
            }
        }
    }

}

void dac(u8 channels, u8 mode, u16 fixedvalue, u8 numofcycles, u16 delay)
{

    switch(mode) {
        case 1:FixedGen(channels,fixedvalue); break;
        case 2:SqWaveGen(channels, numofcycles, delay); break;
        case 3:SawToothWaveGen(channels, numofcycles, delay); break;
        case 4:TriangleWaveGen(channels, numofcycles, delay); break;
        case 5:SineWaveGen(channels, numofcycles, delay); break;
        case 6:RandomWaveGen(channels, numofcycles, delay); break;
    }
}

int main(void)
{
    u16 delay;
    u32 cmd;
    u8 numofcycles;
    u16 fixedvalue;
    u8 mode, channels;

    pmod_init(0,1);
    /*
     *  Configuring Pmod IO Switch to connect to SPI[0].SS to pmod bit 0
     *  SPI[0].MOSI to pmod bit 1, and SPI[0].SCLK to pmod bit 3
     *  rest of the bits are configured to default gpio channels 
     *  i.e. gpio[0] to pmod bit 2, gpio[1] to pmod bit 4, etc.
     */
    config_pmod_switch(SS,MOSI,GPIO_2,SPICLK,
                       GPIO_4,GPIO_5, GPIO_6, GPIO_7);

    RefOn();
    while(1){
        while((MAILBOX_CMD_ADDR & 0x01)==0);
        cmd = MAILBOX_CMD_ADDR;
        mode=0;
        if((cmd >> 1) & 0x01)
            mode=1;
        else if((cmd >> 2) & 0x01)
            mode=2;
        else if((cmd >> 3) & 0x01)
            mode=3;
        else if((cmd >> 4) & 0x01)
            mode=4;
        else if((cmd >> 5) & 0x01)
            mode=5;
        else if((cmd >> 6) & 0x01)
            mode=6;
        channels = (cmd >> 16) & 0x0f;
        fixedvalue = (cmd >> 20) & 0x0fff;
        if(((cmd >> 20) & 0x0fff)==0)
            // set to 1 second if the field is set to 0
            delay = 1000;
        else
            // multiple of approximate milliseconds
            delay=(cmd >> 20) & 0xfff;
        if(((cmd >> 8) & 0x000ff)==0)
            // indicate infinite number of samples
            numofcycles = 0;
        else
            // set to number of samples
            numofcycles=(cmd >> 8) & 0x0ff;
        dac(channels,mode,fixedvalue,numofcycles,delay);
        MAILBOX_CMD_ADDR = 0x0;
    }
    return XST_SUCCESS;
}


