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
 * @file audio_adau1761.h
 *
 *  Library for the audio control block.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who          Date     Changes
 * ----- ------------ -------- -----------------------------------------------
 * 1.00  Yun Rock Qu  12/04/17 Support for audio codec ADAU1761
 * 
 * </pre>
 *
******************************************************************************/
/*
 * ADAU audio controller parameters
 */
#ifndef _AUDIO_ADAU1761_H_
#define _AUDIO_ADAU1761_H_

// Slave address for the ADAU audio controller 8
#define IIC_SLAVE_ADDR          0x3B

// I2C Serial Clock frequency in Hertz
#define IIC_SCLK_RATE           400000

// I2S Register
#define I2S_DATA_RX_L_REG           0x00
#define I2S_DATA_RX_R_REG           0x04
#define I2S_DATA_TX_L_REG           0x08
#define I2S_DATA_TX_R_REG           0x0C
#define I2S_STATUS_REG              0x10

//ADAU internal registers
enum audio_adau1761_regs {
    R0_CLOCK_CONTROL                                = 0x00,
    R1_PLL_CONTROL                                  = 0x02,
    R2_DIGITAL_MIC_JACK_DETECTION_CONTROL           = 0x08,
    R3_RECORD_POWER_MANAGEMENT                      = 0x09,
    R4_RECORD_MIXER_LEFT_CONTROL_0                  = 0x0A,
    R5_RECORD_MIXER_LEFT_CONTROL_1                  = 0x0B,
    R6_RECORD_MIXER_RIGHT_CONTROL_0                 = 0x0C,
    R7_RECORD_MIXER_RIGHT_CONTROL_1                 = 0x0D,
    R8_LEFT_DIFFERENTIAL_INPUT_VOLUME_CONTROL       = 0x0E,
    R9_RIGHT_DIFFERENTIAL_INPUT_VOLUME_CONTROL      = 0x0F,
    R10_RECORD_MICROPHONE_BIAS_CONTROL              = 0x10,
    R11_ALC_CONTROL_0                               = 0x11,
    R12_ALC_CONTROL_1                               = 0x12,
    R13_ALC_CONTROL_2                               = 0x13,
    R14_ALC_CONTROL_3                               = 0x14,
    R15_SERIAL_PORT_CONTROL_0                       = 0x15,
    R16_SERIAL_PORT_CONTROL_1                       = 0x16,
    R17_CONVERTER_CONTROL_0                         = 0x17,
    R18_CONVERTER_CONTROL_1                         = 0x18,
    R19_ADC_CONTROL                                 = 0x19,
    R20_LEFT_INPUT_DIGITAL_VOLUME                   = 0x1A,
    R21_RIGHT_INPUT_DIGITAL_VOLUME                  = 0x1B,
    R22_PLAYBACK_MIXER_LEFT_CONTROL_0               = 0x1C,
    R23_PLAYBACK_MIXER_LEFT_CONTROL_1               = 0x1D,
    R24_PLAYBACK_MIXER_RIGHT_CONTROL_0              = 0x1E,
    R25_PLAYBACK_MIXER_RIGHT_CONTROL_1              = 0x1F,
    R26_PLAYBACK_LR_MIXER_LEFT_LINE_OUTPUT_CONTROL  = 0x20,
    R27_PLAYBACK_LR_MIXER_RIGHT_LINE_OUTPUT_CONTROL = 0x21,
    R28_PLAYBACK_LR_MIXER_MONO_OUTPUT_CONTROL       = 0x22,
    R29_PLAYBACK_HEADPHONE_LEFT_VOLUME_CONTROL      = 0x23,
    R30_PLAYBACK_HEADPHONE_RIGHT_VOLUME_CONTROL     = 0x24,
    R31_PLAYBACK_LINE_OUTPUT_LEFT_VOLUME_CONTROL    = 0x25,
    R32_PLAYBACK_LINE_OUTPUT_RIGHT_VOLUME_CONTROL   = 0x26,
    R33_PLAYBACK_MONO_OUTPUT_CONTROL                = 0x27,
    R34_PLAYBACK_POP_CLICK_SUPPRESSION              = 0x28,
    R35_PLAYBACK_POWER_MANAGEMENT                   = 0x29,
    R36_DAC_CONTROL_0                               = 0x2A,
    R37_DAC_CONTROL_1                               = 0x2B,
    R38_DAC_CONTROL_2                               = 0x2C,
    R39_SERIAL_PORT_PAD_CONTROL                     = 0x2D,
    R40_CONTROL_PORT_PAD_CONTROL_0                  = 0x2F,
    R41_CONTROL_PORT_PAD_CONTROL_1                  = 0x30,
    R42_JACK_DETECT_PIN_CONTROL                     = 0x31,
    R67_DEJITTER_CONTROL                            = 0x36,
    R58_SERIAL_INPUT_ROUTE_CONTROL                  = 0xF2,
    R59_SERIAL_OUTPUT_ROUTE_CONTROL                 = 0xF3,
    R61_DSP_ENABLE                                  = 0xF5,
    R62_DSP_RUN                                     = 0xF6,
    R63_DSP_SLEW_MODES                              = 0xF7,
    R64_SERIAL_PORT_SAMPLING_RATE                   = 0xF8,
    R65_CLOCK_ENABLE_0                              = 0xF9,
    R66_CLOCK_ENABLE_1                              = 0xFA
};

#endif /* _AUDIO_ADAU1761_H_ */