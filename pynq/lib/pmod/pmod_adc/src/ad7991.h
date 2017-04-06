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
