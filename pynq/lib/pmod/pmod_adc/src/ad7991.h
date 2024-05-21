/******************************************************************************
 *  Copyright (c) 2016, Xilinx, Inc.
 *  SPDX-License-Identifier: BSD-3-Clause
 *
 *****************************************************************************/
/******************************************************************************
 *
 *
 * @file ad7991.h
 *
 * Header for Pmod AD2 SKU410-217.
 * The PmodAD2 is an analog-to-digital converter powered by the Analog Devices
 * AD7991. Users may communicate with the board through I2C to configure up to
 * 4 conversion channels at 12 bits of resolution.
 * http://store.digilentinc.com/pmodad2-4-channel-12-bit-a-d-converter/
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a pp  04/13/16 release
 * 1.00b yrq 05/03/16 changed adc_read methods
 *
 * </pre>
 *
 *****************************************************************************/

#include "xil_types.h"
#include "xparameters.h"

// ADP5589 IIC Address
#define AD7991IICAddr       0x28

// AD7911 Registers Bits
// Configuration Register
#define CH3                 7
#define CH2                 6
#define CH1                 5
#define CH0                 4
#define REF_SEL             3
#define FLTR                2
#define BitTrialDelay       1
#define SampleDelay         0
// Conversion Result Register
#define LeadingZeros        0xC000
#define CHID                0x3000
#define BitMask             0xFFF

void adc_init(void);
void adc_config(char chan3, char chan2, char chan1, char chan0, 
                    char ref, char filter, char bit, char sample);
int adc_read_raw();
float adc_read_voltage(u32 vref);

