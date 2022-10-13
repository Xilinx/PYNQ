/******************************************************************************
 *  Copyright (c) 2016, Xilinx, Inc.
 *  SPDX-License-Identifier: BSD-3-Clause
 *
 *****************************************************************************/
/******************************************************************************
 *
 *
 * @file BMP180.h
 *
 * Header file for BMP180 on grove IMU DOF10.
 * BMP180 is a high precision, ultra-low power digital pressure sensors.
 * http://www.seeedstudio.com/wiki/Grove_-_IMU_10DOF
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a yrq 04/25/16 release
 *
 * </pre>
 *
 *****************************************************************************/

#ifndef __BAROMETER_H__
#define __BAROMETER_H__

#include <stdint.h>

#define DEFAULT_BMP_ADDRESS  0x77

const unsigned char OSS = 0;
long PressureCompensate;
float bmpGetTemperature(unsigned int ut);
long bmpGetPressure(unsigned long up);
float calcAltitude(float pressure);

void bmp_init(void);
uint8_t bmp_readByte(unsigned char address);
uint16_t bmp_readBytes(unsigned char address);
float bmp_getTemperature();
float bmp_getPressure();

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

