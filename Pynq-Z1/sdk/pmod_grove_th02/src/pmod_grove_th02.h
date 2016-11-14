/******************************************************************************
 *  Copyright (c) 2016, NECST Laboratory, Politecnico di Milano
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
 * @file arduino_grove_ear_hr.c
 * IOP code (MicroBlaze) for grove Temperature & Humidity Sensor.
 * The sensor has to be connected to a PMOD interface 
 * via a shield socket.
 * http://wiki.seeed.cc/Grove-TemptureAndHumidity_Sensor-High-Accuracy_\
 * AndMini-v1.0
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- -------- -----------------------------------------------
 * 1.00a ldt 07/05/16 release
 * 1.00b gn  10/24/16 support for PYNQ-Z1
 *
 * </pre>
 *
 *****************************************************************************/

#ifndef _THO2_DEV_H
#define _THO2_DEV_H

#include <stdio.h>
#include "pmod.h"

#define TH02_I2C_DEV_ID      0x40
#define REG_STATUS           0x00
#define REG_DATA_H           0x01
#define REG_DATA_L           0x02
#define REG_CONFIG           0x03
#define REG_ID               0x11

#define STATUS_RDY_MASK      0x01    //poll RDY,0 indicate conversion is done

#define CMD_MEASURE_HUMI     0x01    //perform a humility measurement
#define CMD_MEASURE_TEMP     0x11    //perform a temperature measurement

#define TH02_WR_REG_MODE      0xC0
#define TH02_RD_REG_MODE      0x80

// Mailbox commands
// bit 1 always needs to be sets
#define CONFIG_IOP_SWITCH      0x1
#define READ_DATA          	   0x2
#define READ_AND_LOG_DATA  	   0x3
#define STOP_LOG               0xC

// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_ITEM_SIZE sizeof(float)
#define LOG_CAPACITY  (4000/LOG_ITEM_SIZE)

uint16_t TH02_readTemperature();
uint16_t TH02_readHumidity();
int TH02_write(u8 reg, u8 data);
u8 TH02_read(u8 reg);
void TH02_read_3(u8 reg, u8 * data_par);
uint16_t TH02_IIC_ReadData2byte();
void wait_for_data();

#endif
