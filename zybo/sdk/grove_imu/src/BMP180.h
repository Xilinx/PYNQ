/*
 * IOP code (MicroBlaze) for BMP180
*/

#ifndef __BAROMETER_H__
#define __BAROMETER_H__

#define DEFAULT_BMP_ADDRESS  0x77

const unsigned char OSS = 0;
long PressureCompensate;
float bmpGetTemperature(unsigned int ut);
long bmpGetPressure(unsigned long up);
float calcAltitude(float pressure);

void bmp_init(void);
uint8_t bmp_ReadByte(unsigned char address);
uint16_t bmp_ReadBytes(unsigned char address);
float bmp_GetTemperature();
float bmp_GetPressure();
float bmp_CalcAltitude();

short ac1;
short ac2;
short ac3;
unsigned short ac4;
unsigned short ac5;
unsigned short ac6;
short b1;
short b2;
short mb;
short mc;
short md;

uint8_t bmpAddr;

#endif
