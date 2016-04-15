/*
 * IOP code (MicroBlaze) for groveoled
 * Grove OLED is write only, and has IIC interface
 *
 * April 13, 2016
 * Author: Yun Rock Qu
*/

/* Grove OLED is based on OLE35046P
http://www.seeedstudio.com/wiki/Grove_-_OLED_Display_0.96%22
*/

#include "pmod.h"
#include "MPU9250.h"
#include "BMP180.h"

#define NUM_SAMPLES              100

// Mailbox commands
// bit 1 always needs to be set
#define GET_ACCL_DATA           0x3
#define GET_GYRO_DATA           0x5
#define GET_COMPASS_DATA        0x7
#define GET_TEMPERATURE         0xB
#define GET_PRESSURE            0xD
#define RESET                   0xF

//// Byte operations ////
int iic_readBytes(uint8_t mpuAddr, uint8_t regAddr, uint8_t length, uint8_t *data){
    iic_write(mpuAddr, &regAddr, 1);
    return iic_read(mpuAddr, data, length);
}
int iic_readByte(uint8_t mpuAddr, uint8_t regAddr, uint8_t *data){
    return iic_readBytes(mpuAddr, regAddr, (uint8_t) 1, data);
}

int iic_writeBytes(uint8_t mpuAddr, uint8_t regAddr, uint8_t length, uint8_t *data){
    iic_write(mpuAddr, &regAddr, 1);
    return iic_write(mpuAddr, data, length);
}
int iic_writeByte(uint8_t mpuAddr, uint8_t regAddr, uint8_t *data){
    return iic_writeBytes(mpuAddr, regAddr, (uint8_t) 1, data);
}

//// Bit operations ////
int8_t iic_readBits(uint8_t mpuAddr, uint8_t regAddr, uint8_t bitStart, uint8_t width, uint8_t *data) {
    // 01101001 read byte
    // 76543210 bit numbers
    //    xxx   args: bitStart=4, width=3
    //    010   masked
    //   -> 010 shifted
    uint8_t count, b;
    uint8_t mask;
    if ((count = iic_readBytes(mpuAddr, regAddr, 1, &b)) != 0) {
        mask = ((1 << width) - 1) << (bitStart - width + 1);
        b &= mask;
        b >>= (bitStart - width + 1);
        *data = b;
    }
    return count;
}
int8_t iic_readBit(uint8_t mpuAddr, uint8_t regAddr, uint8_t bitStart, uint8_t *data) {
    return iic_readBits(mpuAddr, regAddr, bitStart, (uint8_t) 1, data);
}
    
int8_t iic_writeBits(uint8_t mpuAddr, uint8_t regAddr, uint8_t bitStart, uint8_t width, uint8_t *data) {
    //      010 value to write
    // 76543210 bit numbers
    //    xxx   args: bitStart=4, width=3
    // 00011100 mask byte
    // 10101111 original value (sample)
    // 10100011 original & ~mask
    // 10101011 masked | value
    uint8_t b, temp;
    temp = *data;
    if (iic_readBytes(mpuAddr, regAddr, 1, &b) != 0) {
        uint8_t mask = ((1 << width) - 1) << (bitStart - width + 1);
        temp <<= (bitStart - width + 1); // shift data into correct position
        temp &= mask; // zero all non-important bits in data
        b &= ~(mask); // zero all important bits in existing byte
        b |= temp; // combine data with existing byte
        return iic_writeBytes(mpuAddr, regAddr, 1, &b);
    }
    else{
        return (int8_t)0;
    }
}
int8_t iic_writeBit(uint8_t mpuAddr, uint8_t regAddr, uint8_t bitStart, uint8_t *data) {
    return iic_writeBits(mpuAddr, regAddr, bitStart, (uint8_t) 1, data);
}

//// MPU9250 Driver functions ////
void mpu_init() {
    mpuAddr = MPU9250_DEFAULT_ADDRESS;
    mpu_setClockSource(MPU9250_CLOCK_PLL_XGYRO);
    mpu_setFullScaleGyroRange(MPU9250_GYRO_FS_250);
    mpu_setFullScaleAccelRange(MPU9250_ACCEL_FS_2);
    mpu_setSleepEnabled(false);
}

bool mpu_testConnection() {
    return mpu_getDeviceID() == 0x71;
}

void mpu_setClockSource(uint8_t source) {
    iic_writeBits(mpuAddr, MPU9250_RA_PWR_MGMT_1, MPU9250_PWR1_CLKSEL_BIT, MPU9250_PWR1_CLKSEL_LENGTH, &source);
}

uint8_t mpu_getFullScaleGyroRange() {
    iic_readBits(mpuAddr, MPU9250_RA_GYRO_CONFIG, MPU9250_GCONFIG_FS_SEL_BIT, MPU9250_GCONFIG_FS_SEL_LENGTH, buffer);
    return buffer[0];
}

void mpu_setFullScaleGyroRange(uint8_t range) {
    iic_writeBits(mpuAddr, MPU9250_RA_GYRO_CONFIG, MPU9250_GCONFIG_FS_SEL_BIT, MPU9250_GCONFIG_FS_SEL_LENGTH, &range);
}

uint8_t mpu_getFullScaleAccelRange() {
    iic_readBits(mpuAddr, MPU9250_RA_ACCEL_CONFIG, MPU9250_ACONFIG_AFS_SEL_BIT, MPU9250_ACONFIG_AFS_SEL_LENGTH, buffer);
    return buffer[0];
}

void mpu_setFullScaleAccelRange(uint8_t range) {
    iic_writeBits(mpuAddr, MPU9250_RA_ACCEL_CONFIG, MPU9250_ACONFIG_AFS_SEL_BIT, MPU9250_ACONFIG_AFS_SEL_LENGTH, &range);
}

void mpu_calibrateMotion9(int16_t* Ax, int16_t* Ay, int16_t* Az, int16_t* Gx, int16_t* Gy, int16_t* Gz, int16_t* Mx, int16_t* My, int16_t* Mz) {
    float Mxyz[3];
    volatile float mx_sample[3];
    volatile float my_sample[3];
    volatile float mz_sample[3];
    static float mx_centre = 0;
    static float my_centre = 0;
    static float mz_centre = 0;
    int16_t ax, ay, az, gx, gy, gz, mx, my, mz;
    int i;
    for (i = 0; i < NUM_SAMPLES; i++){
        mpu_getMotion9(&ax, &ay, &az, &gx, &gy, &gz, &mx, &my, &mz);
        Mxyz[0] = (double) mx * 1200 / 4096;
        Mxyz[1] = (double) my * 1200 / 4096;
        Mxyz[2] = (double) mz * 1200 / 4096;
        mx_sample[2] = Mxyz[0];
        my_sample[2] = Mxyz[1];
        mz_sample[2] = Mxyz[2];
        if (i==0){
            mx_sample[0] = *Mx;
            my_sample[0] = *My;
            mz_sample[0] = *Mz;
            mx_sample[1] = *Mx;
            my_sample[1] = *My;
            mz_sample[1] = *Mz;
        }   
        //find max value
        if (mx_sample[2] >= mx_sample[1]) mx_sample[1] = mx_sample[2];
        if (my_sample[2] >= my_sample[1]) my_sample[1] = my_sample[2];
        if (mz_sample[2] >= mz_sample[1]) mz_sample[1] = mz_sample[2];
        //find min value
        if (mx_sample[2] <= mx_sample[0]) mx_sample[0] = mx_sample[2];
        if (my_sample[2] <= my_sample[0]) my_sample[0] = my_sample[2]; 
        if (mz_sample[2] <= mz_sample[0]) mz_sample[0] = mz_sample[2];
    }
    mx_centre = (mx_sample[1] + mx_sample[0]) / 2;
    my_centre = (my_sample[1] + my_sample[0]) / 2;
    mz_centre = (mz_sample[1] + mz_sample[0]) / 2;
            
    //do the final calculation
    mpu_getMotion9(&ax, &ay, &az, &gx, &gy, &gz, &mx, &my, &mz);
    *Ax = (double) ax / 16384;
    *Ay = (double) ay / 16384;
    *Az = (double) az / 16384;
    *Gx = (double) gx * 250 / 32768;
    *Gy = (double) gy * 250 / 32768;
    *Gz = (double) gz * 250 / 32768;
    Mxyz[0] = (double) mx * 1200 / 4096;
    Mxyz[1] = (double) my * 1200 / 4096;
    Mxyz[2] = (double) mz * 1200 / 4096;
    *Mx = Mxyz[0] - mx_centre;
    *My = Mxyz[1] - my_centre;
    *Mz = Mxyz[2] - mz_centre;
}
            
void mpu_getMotion9(int16_t* ax, int16_t* ay, int16_t* az, int16_t* gx, int16_t* gy, int16_t* gz, int16_t* mx, int16_t* my, int16_t* mz) {
    
    //get accel and gyro
    mpu_getMotion6(ax, ay, az, gx, gy, gz);
    
    //read mag
    uint8_t data;
    data = 0x02;
    iic_writeByte(mpuAddr, MPU9250_RA_INT_PIN_CFG, &data); //set i2c bypass enable pin to access magnetometer
    delay_ms(10);
    data = 0x01;
    iic_writeByte(MPU9150_RA_MAG_ADDRESS, 0x0A, &data); //enable the magnetometer
    delay_ms(10);
    iic_readBytes(MPU9150_RA_MAG_ADDRESS, MPU9150_RA_MAG_XOUT_L, 6, buffer);
    *mx = (((int16_t)buffer[1]) << 8) | buffer[0];
    *my = (((int16_t)buffer[3]) << 8) | buffer[2];
    *mz = (((int16_t)buffer[5]) << 8) | buffer[4];
}

void mpu_getMotion6(int16_t* ax, int16_t* ay, int16_t* az, int16_t* gx, int16_t* gy, int16_t* gz) {
    iic_readBytes(mpuAddr, MPU9250_RA_ACCEL_XOUT_H, 14, buffer);
    *ax = (((int16_t)buffer[0]) << 8) | buffer[1];
    *ay = (((int16_t)buffer[2]) << 8) | buffer[3];
    *az = (((int16_t)buffer[4]) << 8) | buffer[5];
    *gx = (((int16_t)buffer[8]) << 8) | buffer[9];
    *gy = (((int16_t)buffer[10]) << 8) | buffer[11];
    *gz = (((int16_t)buffer[12]) << 8) | buffer[13];
}

void mpu_getAcceleration(int16_t* x, int16_t* y, int16_t* z) {
    iic_readBytes(mpuAddr, MPU9250_RA_ACCEL_XOUT_H, 6, buffer);
    *x = (((int16_t)buffer[0]) << 8) | buffer[1];
    *y = (((int16_t)buffer[2]) << 8) | buffer[3];
    *z = (((int16_t)buffer[4]) << 8) | buffer[5];
}

int16_t mpu_getTemperature() {
    iic_readBytes(mpuAddr, MPU9250_RA_TEMP_OUT_H, 2, buffer);
    return (((int16_t)buffer[0]) << 8) | buffer[1];
}

void mpu_getRotation(int16_t* x, int16_t* y, int16_t* z) {
    iic_readBytes(mpuAddr, MPU9250_RA_GYRO_XOUT_H, 6, buffer);
    *x = (((int16_t)buffer[0]) << 8) | buffer[1];
    *y = (((int16_t)buffer[2]) << 8) | buffer[3];
    *z = (((int16_t)buffer[4]) << 8) | buffer[5];
}

void mpu_reset() {
    uint8_t data = 0x01;
    iic_writeBit(mpuAddr, MPU9250_RA_PWR_MGMT_1, MPU9250_PWR1_DEVICE_RESET_BIT, &data);
}

void mpu_setSleepEnabled(uint8_t enabled) {
    iic_writeBit(mpuAddr, MPU9250_RA_PWR_MGMT_1, MPU9250_PWR1_SLEEP_BIT, &enabled);
}

uint8_t mpu_getDeviceID() {
    iic_readBits(mpuAddr, MPU9250_RA_WHO_AM_I, MPU9250_WHO_AM_I_BIT, MPU9250_WHO_AM_I_LENGTH, buffer);
    return buffer[0];
}

int bmp_ReadInt(uint8_t address)
{
    // read 2 bytes from the address and return an int
    uint8_t msb, lsb;
    iic_readByte(bmpAddr, address, &msb);
    iic_readByte(bmpAddr, address+1, &lsb);
    return (int) msb<<8 | lsb;
}

char bmp_ReadByte(unsigned char address)
{
    // read a single byte from the address
    uint8_t data;
    iic_readByte(bmpAddr, address, &data);
    return data;
}

void bmp_init(){
    bmpAddr = DEFAULT_BMP_ADDRESS;
    ac1 = bmp_ReadInt(0xAA);
    ac2 = bmp_ReadInt(0xAC);
    ac3 = bmp_ReadInt(0xAE);
    ac4 = bmp_ReadInt(0xB0);
    ac5 = bmp_ReadInt(0xB2);
    ac6 = bmp_ReadInt(0xB4);
    b1  = bmp_ReadInt(0xB6);
    b2  = bmp_ReadInt(0xB8);
    mb  = bmp_ReadInt(0xBA);
    mc  = bmp_ReadInt(0xBC);
    md  = bmp_ReadInt(0xBE);
}

float bmp_GetTemperature()
{
    unsigned int ut;
    long x1, x2, Compensate;
    float temp;
     uint8_t data[2];
    
    // get the uncompensated temperature
    data[0] = 0xF4;
    data[1] = 0x2E;
    iic_write(bmpAddr, data, 2);
    delay_ms(5);
    ut = bmp_ReadInt(0xF6);
    
    // calculate the compensated temperature
    x1 = (((long)ut - (long)ac6)*(long)ac5) >> 15;
    x2 = ((long)mc << 11)/(x1 + md);
    Compensate = x1 + x2;
    temp = (float)((Compensate + 8)>>4);
    temp = temp /10;

    return temp;
}

float bmp_GetPressure()
{
    long x1, x2, x3, b3, b6, p;
    unsigned long b4, b7;
    unsigned char msb, lsb, xlsb;
    unsigned long up = 0;
    float temp;
    uint8_t data[2];
    
    // get the uncompensated pressure
    data[0] = 0xF4;
    data[1] = 0x34 + (OSS<<6);
    iic_write(bmpAddr, data, 2);
    delay_ms(2 + (3<<OSS));
    msb = bmp_ReadByte(0xF6);
    lsb = bmp_ReadByte(0xF7);
    xlsb = bmp_ReadByte(0xF8);
    up = (((unsigned long)msb<<16)|((unsigned long) lsb << 8)|(unsigned long) xlsb)>>(8-OSS);
    
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
   
   configureSwitch(BLANK, BLANK, SDA, BLANK, BLANK, BLANK, SCL, BLANK);
   // Initialization
   mpu_init();
   bmp_init();
   // Run application
   while(1){
     // wait and store valid command
      while((MAILBOX_CMD_ADDR & 0x01)==0); 
      cmd = MAILBOX_CMD_ADDR; 

      switch(cmd){
         case GET_ACCL_DATA:
            mpu_calibrateMotion9(&ax, &ay, &az, &gx, &gy, &gz, &mx, &my, &mz);
            MAILBOX_DATA_FLOAT(0) = (float)ax;
            MAILBOX_DATA_FLOAT(1) = (float)ay;
            MAILBOX_DATA_FLOAT(2) = (float)az;
            MAILBOX_CMD_ADDR = 0x0; 
            break;
            
         case GET_GYRO_DATA:
            mpu_calibrateMotion9(&ax, &ay, &az, &gx, &gy, &gz, &mx, &my, &mz);
            MAILBOX_DATA_FLOAT(0) = (float)gx;
            MAILBOX_DATA_FLOAT(1) = (float)gy;
            MAILBOX_DATA_FLOAT(2) = (float)gz;
            MAILBOX_CMD_ADDR = 0x0; 
            break;
            
         case GET_COMPASS_DATA:
            mpu_calibrateMotion9(&ax, &ay, &az, &gx, &gy, &gz, &mx, &my, &mz);
            MAILBOX_DATA_FLOAT(0) = (float)mx;
            MAILBOX_DATA_FLOAT(1) = (float)my;
            MAILBOX_DATA_FLOAT(2) = (float)mz;
            MAILBOX_CMD_ADDR = 0x0; 
            break;
            
         case GET_TEMPERATURE:
            MAILBOX_DATA_FLOAT(0) = bmp_GetTemperature();
            MAILBOX_CMD_ADDR = 0x0; 
            break;
            
         case GET_PRESSURE:
            MAILBOX_DATA_FLOAT(0) = bmp_GetPressure();
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
