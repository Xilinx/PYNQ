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

#ifndef __BAROMETER_H__
#define __BAROMETER_H__

#define DEFAULT_BMP_ADDRESS  0x77

const unsigned char OSS = 0;
long PressureCompensate;
float bmpGetTemperature(unsigned int ut);
long bmpGetPressure(unsigned long up);
float calcAltitude(float pressure);

void bmp_init(void);
char bmp_ReadByte(unsigned char address);
int bmp_ReadInt(unsigned char address);
float bmp_GetTemperature();
float bmp_GetPressure();
float bmp_CalcAltitude();

int ac1;
int ac2;
int ac3;
unsigned int ac4;
unsigned int ac5;
unsigned int ac6;
int b1;
int b2;
int mb;
int mc;
int md;

uint8_t bmpAddr;

#endif