/**
 * @author Sam Bobrowicz (Digilent Inc.)
 * @date   2014
 *
 * @edited Giuseppe Natale <giuseppe.natale@xilinx.com>
 * @date   3 DEC 2015
 */

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
