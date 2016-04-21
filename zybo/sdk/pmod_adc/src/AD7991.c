#include "xparameters.h"
#include "AD7991.h"
#include "pmod.h"

#define IIC_BASEADDR  XPAR_IIC_0_BASEADDR

// void AD7991_Init(void)
void AD7991_Init(void)
{
    u8 cfgValue;
    u8 WriteBuffer[6];
    
// Set default Configuration Register Values
//    Channel 3 - Selected for conversion
//    Channel 2 - Selected for conversion
//    Channel 1 - Selected for conversion
//    Channel 0 - Selected for conversion
//    reference Voltage - Supply Voltage
//    filtering on SDA and SCL - Enabled
//    bit Trial Delay - Enabled
//    sample Interval Delay - Enabled
    cfgValue = (1 << CH3)           |
               (1 << CH2)           |
               (1 << CH1)           |
               (1 << CH0)           |
               (0 << REF_SEL)       |
               (0 << FLTR)          |
               (0 << bitTrialDelay) |
               (0 << sampleDelay);
               
    // Write to the Configuration Register
    WriteBuffer[0]=cfgValue;
    iic_write(AD7991IICAddr, WriteBuffer, 1);
}

// Configure the AD7911 device.
// chan3 - CHAN3 bit in control register.
// chan2 - CHAN2 bit in control register.
// chan1 - CHAN1 bit in control register.
// chan0 - CHAN0 bit in control register.
// ref - REF bit in control register.
// filter - FILTER bit in control register.
// bit - BIT bit in control register.
// sample - SAMPLE bit in control register.
// void AD7991_Config(char chan3, char chan2, char chan1, char chan0, char ref, char filter, char bit, char sample)
void AD7991_Config(char chan3, char chan2, char chan1, char chan0, char ref, char filter, char bit, char sample)
{
    u8 cfgValue;
    u8 WriteBuffer[6];

    // Set Configuration Register Values
    cfgValue = (chan3 << CH3)         | // Read Channel 3
               (chan2 << CH2)         | // Read Channel 2
               (chan1 << CH1)         | // Read Channel 1
               (chan0 << CH0)         | // Read Channel 0
               (ref << REF_SEL)       | // Select External reference / Vcc as reference
               (filter << FLTR)       | // filter IIC Bus
               (bit << bitTrialDelay) | // Delay IIC Commands
               (sample << sampleDelay); // Delay IIC Messages
               
    // Write to the Configuration Register
    WriteBuffer[0]=cfgValue;
    iic_write(AD7991IICAddr, WriteBuffer, 1);
}

unsigned int AD7991_Read(u32 nr_cnv, u32 vref)
{
    int rxData;
    u8 rcvbuffer[10];
    char c[7] = {'0','.','0','0','0',0};
    u32 nr;
	int i;

	i = 5;
	c[7]= 0;
	c[6] = '0';
	c[5] = '0';
	c[4] = '0';
	c[3] = '0';
	c[2] = '0';
	c[1] = '.';
	c[0] = '0';

	// Read data from AD7991
	iic_read(AD7991IICAddr, rcvbuffer, 2);
	rxData = ((rcvbuffer[0] << 8) | rcvbuffer[1]);

	// Process read voltage value
	nr = (rxData & ADCValue) * vref / 4096;
	while(nr>0)
	{
		// Transform hex value into char
		// for display purposes
		c[i] = (nr % 10) + 48;
		nr = nr / 10;
		i = i - 1;

		// Skip the 2nd position (it is pre-loaded with '.')
		if(i == 1)
		{
			i = i-1;
		}
	}

	i = 5;

	// Determine if received data from AD7991 is correct
	// by checking the first 2 Leading zeros
	if((rxData & LeadingZeros) == 0)
	{
		return ((c[0] << 24) | (c[2] << 16) | (c[3] << 8) | c[4]);
	}
	else
	{
		return -1;
	}
}

