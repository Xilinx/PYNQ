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
 
/*****************************************************************************/
/**
 *
 * @file audio.h
 *
 *  Libraries for audio class.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who      Date     Changes
 * ----- -------- -------- -----------------------------------------------
 * 1.00a gn       01/24/15 First release
 * 1.00b yrq      08/31/16 Added license header
 * 
 * </pre>
 *
******************************************************************************/

#ifndef __AUDIO_H__
#define __AUDIO_H__

//#include "xiicps.h"

//Slave address for the ADAU audio controller
#define IIC_SLAVE_ADDR          0x1A

//I2C Serial Clock frequency in Hertz
#define IIC_SCLK_RATE           100000

//ADAU internal registers
enum audio_regs {
    R0_LEFT_ADC_INPUT          = 0x00,
    R1_RIGHT_ADC_INPUT         = 0x01,
    R2_LEFT_DAC_VOLUME         = 0x02,
    R3_RIGHT_DAC_VOLUME        = 0x03,
    R4_ANALOG_AUDIO_PATH       = 0x04,
    R5_DIGITAL_AUDIO_PATH      = 0x05,
    R6_POWER_MANAGEMENT        = 0x06,
    R7_DIGITAL_AUDIO_INTERFACE = 0x07,
    R8_SAMPLING_RATE           = 0x08,
    R9_ACTIVE                  = 0x09,
    R15_SOFTWARE_RESET         = 0x0F,
    R16_ALC_CONTROL_1          = 0x10,
    R17_ALC_CONTROL_2          = 0x11,
    R18_NOISE_GATE             = 0x12
};

//Audio controller registers
enum i2s_regs {
    I2S_DATA_RX_L_OFFSET = 0x00,
    I2S_DATA_RX_R_OFFSET = 0x04,
    I2S_DATA_TX_L_OFFSET = 0x08,
    I2S_DATA_TX_R_OFFSET = 0x0c,
    I2S_STATUS_OFFSET    = 0x10
};

//void AudioWriteToReg(unsigned char u8RegAddr, short u16Data, XIicPs *iic);
//void LineinLineoutConfig(XIicPs *iic);
//XIicPs *IicConfig(PyObject *iicps_dict);
void AudioWriteToReg(unsigned char u8RegAddr, short u16Data, int iic_fd);
void LineinLineoutConfig(int iic);

#endif // __AUDIO_H__
