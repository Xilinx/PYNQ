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
 * @file ad7991.c
 *
 * Required functions for Pmod AD2 SKU410-217.
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
 * 1.00b yrq 05/02/16 changed adc_read methods
 *
 * </pre>
 *
 *****************************************************************************/

#include "xparameters.h"
#include "ad7991.h"
#include "pmod.h"

#define IIC_BASEADDR  XPAR_IIC_0_BASEADDR

void adc_init(void)
{
    u8 cfgValue;
    u8 WriteBuffer[6];
    
/*  
 *  Set default Configuration Register Values
 *    Channel 3 - Selected for conversion
 *    Channel 2 - Selected for conversion
 *    Channel 1 - Selected for conversion
 *    Channel 0 - Selected for conversion
 *    reference Voltage - Supply Voltage
 *    filtering on SDA and SCL - Enabled
 *    bit Trial Delay - Enabled
 *    sample Interval Delay - Enabled
 */
    cfgValue = (1 << CH3)           |
               (1 << CH2)           |
               (1 << CH1)           |
               (1 << CH0)           |
               (0 << REF_SEL)       |
               (0 << FLTR)          |
               (0 << BitTrialDelay) |
               (0 << SampleDelay);
               
    // Write to the Configuration Register
    WriteBuffer[0]=cfgValue;
    iic_write(XPAR_IIC_0_BASEADDR, AD7991IICAddr, WriteBuffer, 1);
}

/*  
 *  Configure the AD7911 device.
 *    chan3 - CHAN3 bit in control register.
 *    chan2 - CHAN2 bit in control register.
 *    chan1 - CHAN1 bit in control register.
 *    chan0 - CHAN0 bit in control register.
 *    ref - REF bit in control register.
 *    filter - FILTER bit in control register.
 *    bit - BIT bit in control register.
 *    sample - SAMPLE bit in control register.
 */
void adc_config(char chan3, char chan2, char chan1, char chan0, 
                    char ref, char filter, char bit, char sample)
{
    u8 cfgValue;
    u8 WriteBuffer[6];

    // Set Configuration Register Values
    cfgValue = (chan3 << CH3)         | // Read Channel 3
               (chan2 << CH2)         | // Read Channel 2
               (chan1 << CH1)         | // Read Channel 1
               (chan0 << CH0)         | // Read Channel 0
               (ref << REF_SEL)       | // Select external reference / Vcc
               (filter << FLTR)       | // filter IIC Bus
               (bit << BitTrialDelay) | // Delay IIC Commands
               (sample << SampleDelay); // Delay IIC Messages
               
    // Write to the Configuration Register
    WriteBuffer[0]=cfgValue;
    iic_write(XPAR_IIC_0_BASEADDR, AD7991IICAddr, WriteBuffer, 1);
}

int adc_read_raw()
{
    int rxData;
    u8 rcvbuffer[2];

    // Read data from AD7991
    iic_read(XPAR_IIC_0_BASEADDR, AD7991IICAddr, rcvbuffer, 2);
    // The first byte is MSB, while the second byte is LSB
    rxData = ((rcvbuffer[0] << 8) | rcvbuffer[1]);

    // Process read voltage value
    return (rxData & BitMask);
    /*
     * We can also check whether received data from AD7991 is correct 
     * by checking the first 2 Leading zeros.
     */
}

float adc_read_voltage(u32 vref)
{
    // Process read voltage value
    return (float)(adc_read_raw() * vref / 4096.0);
}
