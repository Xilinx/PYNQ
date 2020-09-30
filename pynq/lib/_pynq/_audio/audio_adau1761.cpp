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
 * @file audio_adau1761.c
 *
 * Functions to control audio controller.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who          Date     Changes
 * ----- ------------ -------- -----------------------------------------------
 * 1.00  Yun Rock Qu  12/04/17 Support for audio codec ADAU1761
 * 1.01  Yun Rock Qu  01/02/18 Enable microphone for CTIA and OMTP standards
 *
 * </pre>
 *
 *****************************************************************************/
#ifdef __cplusplus
extern "C" {
#endif

#include "i2cps.h"
#include "uio.h"
#include "audio_adau1761.h"
#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <linux/i2c-dev.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/ioctl.h>

#ifdef __cplusplus
}
#endif

/******************************************************************************
 * Function to write 8 bits to one of the registers from the audio
 * controller.
 * @param   u8RegAddr is the register address.
 * @param   u8Data is the data byte to write.
 * @param   iic_fd is the file descriptor for /dev/i2c-x
 * @return  none.
 *****************************************************************************/
void write_audio_reg(unsigned char u8RegAddr, 
                     unsigned char u8Data, int iic_fd) {
    unsigned char u8TxData[3];
    u8TxData[0] = 0x40; 
    u8TxData[1] = u8RegAddr;
    u8TxData[2] = u8Data;
    if (writeI2C_asFile(iic_fd, u8TxData, 3) < 0){
        printf("Unable to write audio register.\n");
    }
}

/******************************************************************************
 * Function to configure the audio PLL.
 * @param   iic_index is the i2c index in /dev list.
 * @return  none.
 *****************************************************************************/
extern "C" void config_audio_pll(int iic_index) {
    unsigned char u8TxData[8], u8RxData[6];
    int iic_fd;
    iic_fd = setI2C(iic_index, IIC_SLAVE_ADDR);
    if (iic_fd < 0) {
        printf("Unable to set I2C %d.\n", iic_index);
    }

    // Disable Core Clock
    write_audio_reg(R0_CLOCK_CONTROL, 0x0E, iic_fd);
    /*  MCLK = 10 MHz
     *  R = 0100 = 4, N = 0x023C = 572, M = 0x0271 = 625
     *  PLL required output = 1024x48 KHz = 49.152 MHz
     *  PLLout/MCLK         = 49.152 MHz/10 MHz = 4.9152 MHz
     *                      = R + (N/M)
     *                      = 4 + (572/625) 
     */
    // Register write address [15:8]
    u8TxData[0] = 0x40;
    // Register write address [7:0]
    u8TxData[1] = 0x02;
    // byte 6 - M[15:8]
    u8TxData[2] = 0x02;
    // byte 5 - M[7:0]
    u8TxData[3] = 0x71;
    // byte 4 - N[15:8]
    u8TxData[4] = 0x02;
    // byte 3 - N[7:0]
    u8TxData[5] = 0x3C;
    // byte 2 - bits 6:3 = R[3:0], 2:1 = X[1:0], 0 = PLL operation mode
    u8TxData[6] = 0x21;
    // byte 1 - 1 = PLL Lock, 0 = Core clock enable
    u8TxData[7] = 0x03;
    // Write bytes to PLL control register R1 at 0x4002
    if (writeI2C_asFile(iic_fd, u8TxData, 8) < 0){
        printf("Unable to write I2C %d.\n", iic_index);
    }

    // Poll PLL Lock bit
    u8TxData[0] = 0x40;
    u8TxData[1] = 0x02;
    do {
        if (writeI2C_asFile(iic_fd, u8TxData, 2) < 0){
            printf("Unable to write I2C %d.\n", iic_index);
        }
        if (readI2C_asFile(iic_fd, u8RxData, 6) < 0){
            printf("Unable to read I2C %d.\n", iic_index);
        }
    } while((u8RxData[5] & 0x02) == 0);

    /* Clock control register:  bit 3        CLKSRC = PLL Clock input
     *                          bit 2:1      INFREQ = 1024 x fs
     *                          bit 0        COREN = Core Clock enabled
     */
    write_audio_reg(R0_CLOCK_CONTROL, 0x0F, iic_fd);

    if (unsetI2C(iic_fd) < 0) {
        printf("Unable to unset I2C %d.\n", iic_index);
    }
}

/******************************************************************************
 * Function to configure the audio codec.
 * @param   iic_index is the i2c index in /dev list.
 * @return  none.
 *****************************************************************************/
extern "C" void config_audio_codec(int iic_index) {
    int iic_fd;
    iic_fd = setI2C(iic_index, IIC_SLAVE_ADDR);
    if (iic_fd < 0) {
        printf("Unable to set I2C %d.\n", iic_index);
    }

    /* 
     * Input path control registers are configured 
     * in select_mic and select_line_in
     */

    // Mute Mixer1 and Mixer2 here, enable when MIC and Line In used
    write_audio_reg(R4_RECORD_MIXER_LEFT_CONTROL_0, 0x00, iic_fd);
    write_audio_reg(R6_RECORD_MIXER_RIGHT_CONTROL_0, 0x00, iic_fd);
    // Set LDVOL and RDVOL to 21 dB and Enable left and right differential
    write_audio_reg(R8_LEFT_DIFFERENTIAL_INPUT_VOLUME_CONTROL, 0xB3, iic_fd);
    write_audio_reg(R9_RIGHT_DIFFERENTIAL_INPUT_VOLUME_CONTROL, 0xB3, iic_fd);
    // Enable MIC bias
    write_audio_reg(R10_RECORD_MICROPHONE_BIAS_CONTROL, 0x01, iic_fd);
    // Enable ALC control and noise gate
    write_audio_reg(R14_ALC_CONTROL_3, 0x20, iic_fd);
    // Put CODEC in Master mode
    write_audio_reg(R15_SERIAL_PORT_CONTROL_0, 0x01, iic_fd);
    // Enable ADC on both channels, normal polarity and ADC high-pass filter
    write_audio_reg(R19_ADC_CONTROL, 0x33, iic_fd);
    // Mute play back Mixer3 and Mixer4 and enable when output is required
    write_audio_reg(R22_PLAYBACK_MIXER_LEFT_CONTROL_0, 0x00, iic_fd);
    write_audio_reg(R24_PLAYBACK_MIXER_RIGHT_CONTROL_0, 0x00, iic_fd);
    // Mute left input to mixer3 (R23) and right input to mixer4 (R25)
    write_audio_reg(R23_PLAYBACK_MIXER_LEFT_CONTROL_1, 0x00, iic_fd);
    write_audio_reg(R25_PLAYBACK_MIXER_RIGHT_CONTROL_1, 0x00, iic_fd);
    // Mute left and right channels output; enable them when output is needed
    write_audio_reg(R29_PLAYBACK_HEADPHONE_LEFT_VOLUME_CONTROL, 0xE5, iic_fd);
    write_audio_reg(R30_PLAYBACK_HEADPHONE_RIGHT_VOLUME_CONTROL, 0xE5, iic_fd);
    // Enable play back right and left channels
    write_audio_reg(R35_PLAYBACK_POWER_MANAGEMENT, 0x03, iic_fd);
    // Enable DAC for both channels
    write_audio_reg(R36_DAC_CONTROL_0, 0x03, iic_fd);
    // Set SDATA_In to DAC
    write_audio_reg(R58_SERIAL_INPUT_ROUTE_CONTROL, 0x01, iic_fd);
    // Set SDATA_Out to ADC
    write_audio_reg(R59_SERIAL_OUTPUT_ROUTE_CONTROL, 0x01, iic_fd);
    // Enable DSP and DSP Run
    write_audio_reg(R61_DSP_ENABLE, 0x01, iic_fd);
    write_audio_reg(R62_DSP_RUN, 0x01, iic_fd);
    /* 
     * Enable Digital Clock Generator 0 and 1. 
     * Generator 0 generates sample rates for the ADCs, DACs, and DSP. 
     * Generator 1 generates BCLK and LRCLK for the serial port.
     */
    write_audio_reg(R65_CLOCK_ENABLE_0, 0x7F, iic_fd);
    write_audio_reg(R66_CLOCK_ENABLE_1, 0x03, iic_fd);

    if (unsetI2C(iic_fd) < 0) {
        printf("Unable to unset I2C %d.\n", iic_index);
    }
}

/******************************************************************************
 * Function to select LINE_IN as input.
 * @param  iic_index is the i2c index in /dev list.
 * @return none.
 *****************************************************************************/
extern "C" void select_line_in(int iic_index) {
    int iic_fd;
    iic_fd = setI2C(iic_index, IIC_SLAVE_ADDR);
    if (iic_fd < 0) {
        printf("Unable to set I2C %d.\n", iic_index);
    }

    // Mixer 1  (left channel)
    write_audio_reg(R4_RECORD_MIXER_LEFT_CONTROL_0, 0x01, iic_fd);
    // Enable LAUX (MX1AUXG)
    write_audio_reg(R5_RECORD_MIXER_LEFT_CONTROL_1, 0x07, iic_fd);

    // Mixer 2
    write_audio_reg(R6_RECORD_MIXER_RIGHT_CONTROL_0, 0x01, iic_fd);
    // Enable RAUX (MX2AUXG)
    write_audio_reg(R7_RECORD_MIXER_RIGHT_CONTROL_1, 0x07, iic_fd);

    if (unsetI2C(iic_fd) < 0) {
        printf("Unable to unset I2C %d.\n", iic_index);
    }
}

/******************************************************************************
 * Function to select MIC as input.
 * @param  iic_index is the i2c index in /dev list.
 * @return none.
 *****************************************************************************/
extern "C" void select_mic(int iic_index) {
    int iic_fd;
    iic_fd = setI2C(iic_index, IIC_SLAVE_ADDR);
    if (iic_fd < 0) {
        printf("Unable to set I2C %d.\n", iic_index);
    }

    // Mixer 1 (left channel)
    write_audio_reg(R4_RECORD_MIXER_LEFT_CONTROL_0, 0x01, iic_fd);
    // LDBOOST, set to 20 dB
    write_audio_reg(R5_RECORD_MIXER_LEFT_CONTROL_1, 0x10, iic_fd);
    // LDVOL, set to 21 dB
    write_audio_reg(R8_LEFT_DIFFERENTIAL_INPUT_VOLUME_CONTROL, 0xB3, iic_fd);

    // Mixer 2 (right channel)
    write_audio_reg(R6_RECORD_MIXER_RIGHT_CONTROL_0, 0x01, iic_fd);
    // RDBOOST, set to 20 dB
    write_audio_reg(R7_RECORD_MIXER_RIGHT_CONTROL_1, 0x10, iic_fd);
    // RDVOL, set to 21 dB
    write_audio_reg(R9_RIGHT_DIFFERENTIAL_INPUT_VOLUME_CONTROL, 0xB3, iic_fd);

    if (unsetI2C(iic_fd) < 0) {
        printf("Unable to unset I2C %d.\n", iic_index);
    }
}

/******************************************************************************
 * Function to deselect input, either LINE_IN, or MIC.
 * @param  iic_index is the i2c index in /dev list.
 * @return none.
 *****************************************************************************/
extern "C" void deselect(int iic_index) {
    int iic_fd;
    iic_fd = setI2C(iic_index, IIC_SLAVE_ADDR);
    if (iic_fd < 0) {
        printf("Unable to set I2C %d.\n", iic_index);
    }

    //mute mixer 1 in left channel
    write_audio_reg(R4_RECORD_MIXER_LEFT_CONTROL_0, 0x00, iic_fd);
    //mute mixer 2 in right channel
    write_audio_reg(R6_RECORD_MIXER_RIGHT_CONTROL_0, 0x00, iic_fd);

    if (unsetI2C(iic_fd) < 0) {
        printf("Unable to unset I2C %d.\n", iic_index);
    }
}


/******************************************************************************
 * Record and play the audio without storing in the DDR3.
 *
 * @param   audio_mmap_size is the address range of the audio codec.
 * @param   nsamples is the number of samples to read and output.
 * @param   uio_index is the uio index in /dev list.
 * @param   iic_index is the i2c index in /dev list.
 * @return  none.
 *****************************************************************************/
extern "C" void bypass(unsigned int audio_mmap_size,
                       unsigned int nsamples, unsigned int volume,
                       int uio_index, int iic_index) {
    int i, status;
    void *uio_ptr;
    int DataL, DataR;
    int iic_fd;

    uio_ptr = setUIO(uio_index, audio_mmap_size);
    iic_fd = setI2C(iic_index, IIC_SLAVE_ADDR);
    if (iic_fd < 0) {
        printf("Unable to set I2C %d.\n", iic_index);
    }

    // Mute mixer1 and mixer2 input
    write_audio_reg(R23_PLAYBACK_MIXER_LEFT_CONTROL_1, 0x00, iic_fd);
    write_audio_reg(R25_PLAYBACK_MIXER_RIGHT_CONTROL_1, 0x00, iic_fd);
    // Enable Mixer3 and Mixer4
    write_audio_reg(R22_PLAYBACK_MIXER_LEFT_CONTROL_0, 0x21, iic_fd);
    write_audio_reg(R24_PLAYBACK_MIXER_RIGHT_CONTROL_0, 0x41, iic_fd);

    unsigned char vol_register = (unsigned char)volume << 2 | 0x3;
    // Enable Left/Right Headphone out
    write_audio_reg(R29_PLAYBACK_HEADPHONE_LEFT_VOLUME_CONTROL,
                    vol_register,
                    iic_fd);
    write_audio_reg(R30_PLAYBACK_HEADPHONE_RIGHT_VOLUME_CONTROL,
                    vol_register,
                    iic_fd);

    for(i=0; i<nsamples; i++){
        //wait for RX data to become available
        do {
            status = \
            *((volatile unsigned *)(((uint8_t *)uio_ptr) + I2S_STATUS_REG));
        } while (status == 0);
        *((volatile unsigned *)(((uint8_t *)uio_ptr) + I2S_STATUS_REG)) = \
            0x00000001;

        // Read the sample from the input
        DataL = *((volatile int *)(((uint8_t *)uio_ptr) + I2S_DATA_RX_L_REG));
        DataR = *((volatile int *)(((uint8_t *)uio_ptr) + I2S_DATA_RX_R_REG));

        // Write the sample to output
        *((volatile int *)(((uint8_t *)uio_ptr) + I2S_DATA_TX_L_REG)) = DataL;
        *((volatile int *)(((uint8_t *)uio_ptr) + I2S_DATA_TX_R_REG)) = DataR;
    }

    write_audio_reg(R23_PLAYBACK_MIXER_LEFT_CONTROL_1, 0x00, iic_fd);
    write_audio_reg(R25_PLAYBACK_MIXER_RIGHT_CONTROL_1, 0x00, iic_fd);
    write_audio_reg(R22_PLAYBACK_MIXER_LEFT_CONTROL_0, 0x00, iic_fd);
    write_audio_reg(R24_PLAYBACK_MIXER_RIGHT_CONTROL_0, 0x00, iic_fd);
    write_audio_reg(R29_PLAYBACK_HEADPHONE_LEFT_VOLUME_CONTROL, 0xE5, iic_fd);
    write_audio_reg(R30_PLAYBACK_HEADPHONE_RIGHT_VOLUME_CONTROL, 0xE5, iic_fd);

    if (unsetUIO(uio_ptr, audio_mmap_size) < 0){
        printf("Unable to free UIO %d.\n", uio_index);
    }
    if (unsetI2C(iic_fd) < 0) {
        printf("Unable to unset I2C %d.\n", iic_index);
    }
}

/******************************************************************************
 * Function to support audio recording without the audio codec controller.
 *
 * Notice that the buffer has to be twice the size of the number of samples,
 * because both left and right channels are sampled. 
 *
 * @param   audio_mmap_size is the address range of the audio codec.
 * @param   BufAddr is the buffer address.
 * @param   nsamples is the number of samples.
 * @param   uio_index is the uio index in /dev list.
 * @param   iic_index is the i2c index in /dev list.
 * @return  none.
 *****************************************************************************/
extern "C" void record(unsigned int audio_mmap_size,
                       unsigned int* BufAddr, unsigned int nsamples, 
                       int uio_index, int iic_index){
    unsigned int  i, status;
    void *uio_ptr;
    int DataL, DataR;
    int iic_fd;

    uio_ptr = setUIO(uio_index, audio_mmap_size);
    iic_fd = setI2C(iic_index, IIC_SLAVE_ADDR);
    if (iic_fd < 0) {
        printf("Unable to set I2C %d.\n", iic_index);
    }

    for(i=0; i<nsamples; i++) {
        do {
            status = \
            *((volatile unsigned *)(((uint8_t *)uio_ptr) + I2S_STATUS_REG));
        } while (status == 0);
        *((volatile unsigned *)(((uint8_t *)uio_ptr) + I2S_STATUS_REG)) = \
            0x00000001;

        // Read the sample from the input
        DataL = *((volatile int *)(((uint8_t *)uio_ptr) + I2S_DATA_RX_L_REG));
        DataR = *((volatile int *)(((uint8_t *)uio_ptr) + I2S_DATA_RX_R_REG));

        // Write the sample into memory
        *(BufAddr+2*i) = DataL;
        *(BufAddr+2*i+1) = DataR;
    }

    if (unsetUIO(uio_ptr, audio_mmap_size) < 0){
        printf("Unable to free UIO %d.\n", uio_index);
    }
    if (unsetI2C(iic_fd) < 0) {
        printf("Unable to unset I2C %d.\n", iic_index);
    }
}

/******************************************************************************
 * Function to support audio playing without the audio codec controller.
 *
 * Notice that the buffer has to be twice the size of the number of samples,
 * because both left and right channels are sampled.
 *
 * @param   audio_mmap_size is the address range of the audio codec.
 * @param   BufAddr is the buffer address.
 * @param   nsamples is the number of samples.
 * @param   uio_index is the uio index in /dev list.
 * @param   iic_index is the i2c index in /dev list.
 * @return  none.
 *****************************************************************************/
extern "C" void play(unsigned int audio_mmap_size,
                     unsigned int* BufAddr, unsigned int nsamples, 
                     unsigned int volume, int uio_index, int iic_index){
    unsigned int  i, status;
    void *uio_ptr;
    int DataL, DataR;
    int iic_fd;

    uio_ptr = setUIO(uio_index, audio_mmap_size);
    iic_fd = setI2C(iic_index, IIC_SLAVE_ADDR);
    if (iic_fd < 0) {
        printf("Unable to set I2C %d.\n", iic_index);
    }

    // Unmute left and right DAC, enable Mixer3 and Mixer4
    write_audio_reg(R22_PLAYBACK_MIXER_LEFT_CONTROL_0, 0x21, iic_fd);
    write_audio_reg(R24_PLAYBACK_MIXER_RIGHT_CONTROL_0, 0x41, iic_fd);

    unsigned char vol_register = (unsigned char)volume << 2 | 0x3;
    // Enable Left/Right Headphone out
    write_audio_reg(R29_PLAYBACK_HEADPHONE_LEFT_VOLUME_CONTROL,
                    vol_register,
                    iic_fd);
    write_audio_reg(R30_PLAYBACK_HEADPHONE_RIGHT_VOLUME_CONTROL,
                    vol_register,
                    iic_fd);

    for(i=0; i<nsamples; i++){
        do {
            status = \
            *((volatile unsigned *)(((uint8_t *)uio_ptr) + I2S_STATUS_REG));
        } while (status == 0);
        *((volatile unsigned *)(((uint8_t *)uio_ptr) + I2S_STATUS_REG)) = \
            0x00000001;

        // Read the sample from memory
        DataL = *(BufAddr+2*i);
        DataR = *(BufAddr+2*i+1);

        // Write the sample to output
        *((volatile int *)(((uint8_t *)uio_ptr) + I2S_DATA_TX_L_REG)) = DataL;
        *((volatile int *)(((uint8_t *)uio_ptr) + I2S_DATA_TX_R_REG)) = DataR;
    }

    // Mute left and right DAC
    write_audio_reg(R22_PLAYBACK_MIXER_LEFT_CONTROL_0, 0x01, iic_fd);
    write_audio_reg(R24_PLAYBACK_MIXER_RIGHT_CONTROL_0, 0x01, iic_fd);
    // Mute left input to mixer3 (R23) and right input to mixer4 (R25)
    write_audio_reg(R23_PLAYBACK_MIXER_LEFT_CONTROL_1, 0x00, iic_fd);
    write_audio_reg(R25_PLAYBACK_MIXER_RIGHT_CONTROL_1, 0x00, iic_fd);

    if (unsetUIO(uio_ptr, audio_mmap_size) < 0){
        printf("Unable to free UIO %d.\n", uio_index);
    }
    if (unsetI2C(iic_fd) < 0) {
        printf("Unable to unset I2C %d.\n", iic_index);
    }
}
