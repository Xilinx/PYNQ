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
 * @file arduino_grove_imu.c
 *
 * IOP code (MicroBlaze) for grove IMU 10DOF.
 * The grove IMU has to be connected to an arduino interface 
 * via a shield socket.
 * Grove IMU is read only, and has IIC interface.
 * Hardware version 1.1.
 * http://www.seeedstudio.com/wiki/Grove_-_IMU_10DOF
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a yrq 04/25/16 release
 * 1.00d yrq 07/26/16 separate pmod and arduino
 *
 * </pre>
 *
 *****************************************************************************/

#include "arduino.h"
#include "MPU9250.h"
#include "BMP180.h"

#define NUM_SAMPLES              100

// Mailbox commands
#define CONFIG_IOP_SWITCH       0x1
#define GET_ACCL_DATA           0x3
#define GET_GYRO_DATA           0x5
#define GET_COMPASS_DATA        0x7
#define GET_TEMPERATURE         0xB
#define GET_PRESSURE            0xD
#define RESET                   0xF

// Byte operations
int iic_readBytes(uint8_t devAddr, uint8_t regAddr, 
                uint8_t length, uint8_t *data){
    iic_write(XPAR_IIC_0_BASEADDR, devAddr, &regAddr, 1);
    return iic_read(XPAR_IIC_0_BASEADDR, devAddr, data, length);
}

int iic_readByte(uint8_t devAddr, uint8_t regAddr, uint8_t *data){
    iic_write(XPAR_IIC_0_BASEADDR, devAddr, &regAddr, 1);
    return iic_read(XPAR_IIC_0_BASEADDR, devAddr, data, 1);
}

int iic_writeBytes(uint8_t devAddr, uint8_t regAddr, 
                uint8_t length, uint8_t *data){
    int i;
    int len_total = (int)length+1;
    uint8_t temp[len_total];
    temp[0] = regAddr;
    for (i=1;i<len_total;i++){
        temp[i]=data[i-1];
    }
    return iic_write(XPAR_IIC_0_BASEADDR, devAddr, temp, len_total);
}

int iic_writeByte(uint8_t devAddr, uint8_t regAddr, uint8_t *data){
    uint8_t temp[2];
    temp[0] = regAddr;
    temp[1] = *data;
    return iic_write(XPAR_IIC_0_BASEADDR, devAddr, temp, 2);
}

// Bit operations
int8_t iic_readBits(uint8_t devAddr, uint8_t regAddr, 
                    uint8_t bitStart, uint8_t width, uint8_t *data) {
    /*
     * 01101001 read byte
     * 76543210 bit numbers
     *    xxx   parameters: bitStart=4, width=3
     *    010   masked
     *   -> 010 shifted
     */
    uint8_t count, b;
    uint8_t mask;
    if ((count = iic_readBytes(devAddr, regAddr, 1, &b)) != 0) {
        mask = ((1 << width) - 1) << (bitStart - width + 1);
        b &= mask;
        b >>= (bitStart - width + 1);
        *data = b;
    }
    return count;
}
int8_t iic_readBit(uint8_t devAddr, uint8_t regAddr, 
                   uint8_t bitStart, uint8_t *data) {
    return iic_readBits(devAddr, regAddr, bitStart, (uint8_t) 1, data);
}
    
int8_t iic_writeBits(uint8_t devAddr, uint8_t regAddr, 
                     uint8_t bitStart, uint8_t width, uint8_t *data) {
    /*
     * 010 value to write
     * 76543210 bit numbers
     *    xxx   parameters: bitStart=4, width=3
     * 00011100 mask byte
     * 10101111 original value (sample)
     * 10100011 original & ~mask
     * 10101011 masked | value
     */
    uint8_t b, temp;
    temp = *data;
    if (iic_readBytes(devAddr, regAddr, 1, &b) != 0) {
        uint8_t mask = ((1 << width) - 1) << (bitStart - width + 1);
        // shift data into correct position
        temp <<= (bitStart - width + 1);
        // zero all non-important bits in data
        temp &= mask;
        // zero all important bits in existing byte
        b &= ~(mask);
        // combine data with existing byte
        b |= temp;
        return iic_writeByte(devAddr, regAddr, &b);
    }
    else{
        return (int8_t)0;
    }
}
int8_t iic_writeBit(uint8_t devAddr, uint8_t regAddr, 
                    uint8_t bitStart, uint8_t *data) {
    return iic_writeBits(devAddr, regAddr, bitStart, (uint8_t) 1, data);
}

// MPU9250 driver functions
void mpu_init() {
    //device setup
    mpuAddr = MPU9250_DEFAULT_ADDRESS;
    mpu_setClockSource(MPU9250_CLOCK_INTERNAL);
    mpu_setFullScaleGyroRange(MPU9250_GYRO_FS_250);
    mpu_setFullScaleAccelRange(MPU9250_ACCEL_FS_2);
    mpu_setSleepEnabled(false);
    
}

void mpu_setClockSource(uint8_t source) {
    iic_writeBits(mpuAddr, MPU9250_RA_PWR_MGMT_1, MPU9250_PWR1_CLKSEL_BIT, 
                    MPU9250_PWR1_CLKSEL_LENGTH, &source);
}

void mpu_setFullScaleGyroRange(uint8_t range) {
    iic_writeBits(mpuAddr, MPU9250_RA_GYRO_CONFIG, MPU9250_GCONFIG_FS_SEL_BIT, 
                    MPU9250_GCONFIG_FS_SEL_LENGTH, &range);
}

void mpu_setFullScaleAccelRange(uint8_t range) {
    iic_writeBits(mpuAddr, MPU9250_RA_ACCEL_CONFIG, 
                    MPU9250_ACONFIG_AFS_SEL_BIT, 
                    MPU9250_ACONFIG_AFS_SEL_LENGTH, &range);
}
            
void mpu_getMotion9(int16_t* ax, int16_t* ay, int16_t* az, 
                    int16_t* gx, int16_t* gy, int16_t* gz, 
                    int16_t* mx, int16_t* my, int16_t* mz) {
    
    //get accel and gyro
    iic_readBytes(mpuAddr, MPU9250_RA_ACCEL_XOUT_H, 14, buffer);
    delay_ms(60);
    *ax = (((int16_t)buffer[0]) << 8) | buffer[1];
    *ay = (((int16_t)buffer[2]) << 8) | buffer[3];
    *az = (((int16_t)buffer[4]) << 8) | buffer[5];
    *gx = (((int16_t)buffer[8]) << 8) | buffer[9];
    *gy = (((int16_t)buffer[10]) << 8) | buffer[11];
    *gz = (((int16_t)buffer[12]) << 8) | buffer[13];
    
    //read mag
    uint8_t data;
    data = 0x02;
    //set i2c bypass enable pin to access magnetometer
    iic_writeByte(mpuAddr, MPU9250_RA_INT_PIN_CFG, &data);
    delay_ms(10);
    data = 0x01;
    //enable the magnetometer
    iic_writeByte(MPU9150_RA_MAG_ADDRESS, 0x0A, &data);
    delay_ms(10);
    iic_readBytes(MPU9150_RA_MAG_ADDRESS, MPU9150_RA_MAG_XOUT_L, 6, buffer);
    delay_ms(60);
    *mx = (((int16_t)buffer[1]) << 8) | buffer[0];
    *my = (((int16_t)buffer[3]) << 8) | buffer[2];
    *mz = (((int16_t)buffer[5]) << 8) | buffer[4];
}

void mpu_reset() {
    uint8_t data = 0x01;
    iic_writeBit(mpuAddr, MPU9250_RA_PWR_MGMT_1, 
                    MPU9250_PWR1_DEVICE_RESET_BIT, &data);
}

void mpu_setSleepEnabled(uint8_t enabled) {
    iic_writeBit(mpuAddr, MPU9250_RA_PWR_MGMT_1, 
                    MPU9250_PWR1_SLEEP_BIT, &enabled);
}

// BMP180 driver functions
uint16_t bmp_readBytes(uint8_t address)
{
    // read 2 bytes from the address and return an int
    uint8_t msb, lsb;
    iic_readByte(bmpAddr, address, &msb);
    delay_ms(20);
    iic_readByte(bmpAddr, address+1, &lsb);
    delay_ms(20);
    return (int) msb<<8 | lsb;
}

uint8_t bmp_readByte(unsigned char address)
{
    // read a single byte from the address
    uint8_t data;
    iic_readByte(bmpAddr, address, &data);
    delay_ms(20);
    return data;
}

void bmp_init(){
    bmpAddr = DEFAULT_BMP_ADDRESS;
    ac1 = bmp_readBytes(0xAA);
    ac2 = bmp_readBytes(0xAC);
    ac3 = bmp_readBytes(0xAE);
    ac4 = bmp_readBytes(0xB0);
    ac5 = bmp_readBytes(0xB2);
    ac6 = bmp_readBytes(0xB4);
    b1  = bmp_readBytes(0xB6);
    b2  = bmp_readBytes(0xB8);
    mb  = bmp_readBytes(0xBA);
    mc  = bmp_readBytes(0xBC);
    md  = bmp_readBytes(0xBE);
}

float bmp_getTemperature()
{
    unsigned int ut;
    long x1, x2;
    float temp;
    uint8_t data;
    
    // get the uncompensated temperature
    data = 0x2E;
    iic_writeByte(bmpAddr, 0xF4, &data);
    delay_ms(20);
    ut = (long)bmp_readBytes(0xF6);
    
    // calculate the compensated temperature
    x1 = ((ut - ac6)*(long)ac5) >> 15;
    x2 = ((long)mc << 11)/(x1 + md);
    PressureCompensate = x1 + x2;
    temp = (float)((PressureCompensate + 8)>>4);
    temp = temp /10;

    return temp;
}

float bmp_getPressure()
{
    long x1, x2, x3, b3, b6, p;
    unsigned long b4, b7;
    unsigned char msb, lsb, xlsb;
    unsigned long up = 0;
    float temp;
    uint8_t data;
    
    // Read the temperature first to set PressureCompensate
    bmp_getTemperature();
    
    // get the uncompensated pressure
    data = 0x34;
    iic_writeByte(bmpAddr, 0xF4, &data);
    delay_ms(20);
    msb = bmp_readByte(0xF6);
    lsb = bmp_readByte(0xF7);
    xlsb = bmp_readByte(0xF8);
    up = (((unsigned long)msb<<16)|((unsigned long) lsb << 8)|
            (unsigned long) xlsb)>>(8-OSS);
    
    // calculate the  compensated pressure
    b6 = PressureCompensate - 4000;
    x1 = (b2 * (b6 * b6)>>12)>>11;
    x2 = (ac2 * b6)>>11;
    x3 = x1 + x2;
    b3 = (((((long)ac1)*4 + x3)<<OSS) + 2)>>2;
    x1 = (ac3 * b6)>>13;
    x2 = (b1 * ((b6 * b6)>>12))>>16;
    x3 = ((x1 + x2) + 2)>>2;
    b4 = (ac4 * (unsigned long)(x3 + 32768))>>15;

    b7 = ((unsigned long)(up - b3) * (50000>>OSS));
    if (b7 < 0x80000000){
        p = (b7<<1)/b4;
    }else{
        p = (b7/b4)<<1;
    }

    x1 = (p>>8) * (p>>8);
    x1 = (x1 * 3038)>>16;
    x2 = (-7357 * p)>>16;
    p += (x1 + x2 + 3791)>>4;
    temp = (float)p;
    
    return temp;
}

int main()
{
   int cmd;
   int16_t ax, ay, az;
   int16_t gx, gy, gz;
   int16_t mx, my, mz;
   
   arduino_init(0,0,0,0);
   config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, 
                         A_GPIO, A_SDA, A_SCL,
                         D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                         D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                         D_GPIO, D_GPIO, D_GPIO, D_GPIO);
   // Initialization
   mpu_init();
   bmp_init();
   // Run application
   while(1){
     // wait and store valid command
      while((MAILBOX_CMD_ADDR & 0x01)==0);
      cmd = MAILBOX_CMD_ADDR;

      switch(cmd){
          case CONFIG_IOP_SWITCH:
            // use dedicated I2C
            config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, 
                                  A_GPIO, A_SDA, A_SCL,
                                  D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                                  D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                                  D_GPIO, D_GPIO, D_GPIO, D_GPIO);
            mpu_init();
            bmp_init();
            MAILBOX_CMD_ADDR = 0x0;
            break;
            
         case GET_ACCL_DATA:
            mpu_getMotion9(&ax, &ay, &az, &gx, &gy, &gz, &mx, &my, &mz);
            MAILBOX_DATA(0) = (signed int)ax;
            MAILBOX_DATA(1) = (signed int)ay;
            MAILBOX_DATA(2) = (signed int)az;
            MAILBOX_CMD_ADDR = 0x0; 
            break;
            
         case GET_GYRO_DATA:
            mpu_getMotion9(&ax, &ay, &az, &gx, &gy, &gz, &mx, &my, &mz);
            MAILBOX_DATA(0) = (signed int)gx;
            MAILBOX_DATA(1) = (signed int)gy;
            MAILBOX_DATA(2) = (signed int)gz;
            MAILBOX_CMD_ADDR = 0x0; 
            break;
            
         case GET_COMPASS_DATA:
            mpu_getMotion9(&ax, &ay, &az, &gx, &gy, &gz, &mx, &my, &mz);
            MAILBOX_DATA(0) = (signed int)mx;
            MAILBOX_DATA(1) = (signed int)my;
            MAILBOX_DATA(2) = (signed int)mz;
            MAILBOX_CMD_ADDR = 0x0; 
            break;
            
         case GET_TEMPERATURE:
            MAILBOX_DATA_FLOAT(0) = bmp_getTemperature();
            MAILBOX_CMD_ADDR = 0x0; 
            break;
            
         case GET_PRESSURE:
            MAILBOX_DATA_FLOAT(0) = bmp_getPressure();
            MAILBOX_CMD_ADDR = 0x0; 
            break;
            
         case RESET:
            mpu_reset();
            MAILBOX_CMD_ADDR = 0x0; 
            break;
            
         default:
            MAILBOX_CMD_ADDR = 0x0;
            break;
      }
   }
   return 0;
}
