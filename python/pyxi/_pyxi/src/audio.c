/******************************************************************************
*
* Copyright (C) 2010 - 2015 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* XILINX CONSORTIUM BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/**
 * Driver for audio controller (audio.h)
 *
 * @author Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   3 DEC 2015
 * 
 * Code is edited from a Digilent Project (author: Sam Bobrowicz)
 */

#include <Python.h>
#include "i2cps.h"

#include "audio.h"
 
/******************************************************************************
 * Function to write 9-bits to one of the registers from the audio
 * controller.
 * @param   u8RegAddr is the register address.
 * @param   u16Data is the data word to write ( only least significant 9 bits).
 * @return none.
 *****************************************************************************/
//void AudioWriteToReg(unsigned char u8RegAddr, short u16Data, XIicPs *iic) {
void AudioWriteToReg(unsigned char u8RegAddr, short u16Data, int iic) {
    u8RegAddr = (u8RegAddr << 1) | ((u16Data >> 8) & 0x01);
    unsigned char u8Data = u16Data & 0xFF;

    int iic_fd = setI2C(iic, IIC_SLAVE_ADDR);
    writeI2C_byte(iic_fd, u8RegAddr, u8Data);
    unsetI2C(iic_fd);
}

/******************************************************************************
 * Configures Line-In input, ADC's, DAC's, Line-Out and HP-Out.
 * @param   none.
 * @return  none.
 *****************************************************************************/
//void LineinLineoutConfig(XIicPs *iic) {
void LineinLineoutConfig(int iic) {

    // software reset
    AudioWriteToReg(R15_SOFTWARE_RESET, 0x000, iic);
    // power mgmt: 0_00110000=>0,Power up, power up, OSC dn, out off, 
    // DAC up, ADC up, MIC off, LineIn up
    AudioWriteToReg(R6_POWER_MANAGEMENT, 0x030, iic);
    // left ADC Input: 0_01010111=>0,mute disable, Line volume 0 dB
    AudioWriteToReg(R0_LEFT_ADC_INPUT,0x017, iic);
    // right ADC Input: 0_00010111=>0,mute disable, Line volume 0 dB
    AudioWriteToReg(R1_RIGHT_ADC_INPUT,0x017, iic);
    AudioWriteToReg(R2_LEFT_DAC_VOLUME,0x079, iic);
    AudioWriteToReg(R3_RIGHT_DAC_VOLUME,0x079, iic);
    // analog audio path: 0_00010010=>0,-6 dB side attenuation, sidetone off, 
    // DAC selected, bypass disabled, line input, mic mute disabled, 0 dB mic
    AudioWriteToReg(R4_ANALOG_AUDIO_PATH, 0x012, iic);
    // digital audio path: 0_00000000=>0_000, clear offset, no mute, 
    // no de-emphasize, adc high-pass filter enabled
    AudioWriteToReg(R5_DIGITAL_AUDIO_PATH, 0x000, iic);
    // digital audio interface: 0_00001010=>0, BCLK not inverted, slave mode, 
    // no l-r swap, normal LRC and PBRC, 24-bit, I2S mode
    AudioWriteToReg(R7_DIGITAL_AUDIO_INTERFACE, 0x00A, iic);
    // Digital core:0_00000001=>0_0000000, activate core
    AudioWriteToReg(R9_ACTIVE, 0x001, iic);
    // power mgmt: 0_00100010 0_Power up, power up, OSC dn, out ON, DAC up, 
    // ADC up, MIC off, LineIn up

    // power mgmt: 001100010 turn on OUT
    AudioWriteToReg(R6_POWER_MANAGEMENT, 0x022, iic); 

}