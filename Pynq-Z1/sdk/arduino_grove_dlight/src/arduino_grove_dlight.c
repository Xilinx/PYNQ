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
 * @file arduino_grove_dlight.c
 * IOP code (MicroBlaze) for grove digital light sensor.
 * The grove digital light sensor has to be connected to an arduino interface 
 * via a shield socket.
 * http://wiki.seeed.cc/Grove-Digital_Light_Sensor/
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- -------- -----------------------------------------------
 * 1.00a lcc 07/08/16 release
 * 1.00b gn  10/25/16 support arduino shield
 *
 * </pre>
 *
 *****************************************************************************/

#include "arduino.h"

#define  TSL2561_Control  0x80
#define  TSL2561_Timing   0x81
#define  TSL2561_Interrupt 0x86
#define  TSL2561_Channal0L 0x8C
#define  TSL2561_Channal0H 0x8D
#define  TSL2561_Channal1L 0x8E
#define  TSL2561_Channal1H 0x8F

#define TSL2561_Address  0x29       //device address

#define LUX_SCALE 14           // scale by 2^14
#define RATIO_SCALE 9          // scale ratio by 2^9
#define CH_SCALE 10            // scale channel values by 2^10
#define CHSCALE_TINT0 0x7517   // 322/11 * 2^CH_SCALE
#define CHSCALE_TINT1 0x0fe7   // 322/81 * 2^CH_SCALE

#define K1T 0x0040   // 0.125 * 2^RATIO_SCALE
#define B1T 0x01f2   // 0.0304 * 2^LUX_SCALE
#define M1T 0x01be   // 0.0272 * 2^LUX_SCALE
#define K2T 0x0080   // 0.250 * 2^RATIO_SCA
#define B2T 0x0214   // 0.0325 * 2^LUX_SCALE
#define M2T 0x02d1   // 0.0440 * 2^LUX_SCALE
#define K3T 0x00c0   // 0.375 * 2^RATIO_SCALE
#define B3T 0x023f   // 0.0351 * 2^LUX_SCALE
#define M3T 0x037b   // 0.0544 * 2^LUX_SCALE
#define K4T 0x0100   // 0.50 * 2^RATIO_SCALE
#define B4T 0x0270   // 0.0381 * 2^LUX_SCALE
#define M4T 0x03fe   // 0.0624 * 2^LUX_SCALE
#define K5T 0x0138   // 0.61 * 2^RATIO_SCALE
#define B5T 0x016f   // 0.0224 * 2^LUX_SCALE
#define M5T 0x01fc   // 0.0310 * 2^LUX_SCALE
#define K6T 0x019a   // 0.80 * 2^RATIO_SCALE
#define B6T 0x00d2   // 0.0128 * 2^LUX_SCALE
#define M6T 0x00fb   // 0.0153 * 2^LUX_SCALE
#define K7T 0x029a   // 1.3 * 2^RATIO_SCALE
#define B7T 0x0018   // 0.00146 * 2^LUX_SCALE
#define M7T 0x0012   // 0.00112 * 2^LUX_SCALE
#define K8T 0x029a   // 1.3 * 2^RATIO_SCALE
#define B8T 0x0000   // 0.000 * 2^LUX_SCALE
#define M8T 0x0000   // 0.000 * 2^LUX_SCALE

#define K1C 0x0043   // 0.130 * 2^RATIO_SCALE
#define B1C 0x0204   // 0.0315 * 2^LUX_SCALE
#define M1C 0x01ad   // 0.0262 * 2^LUX_SCALE
#define K2C 0x0085   // 0.260 * 2^RATIO_SCALE
#define B2C 0x0228   // 0.0337 * 2^LUX_SCALE
#define M2C 0x02c1   // 0.0430 * 2^LUX_SCALE
#define K3C 0x00c8   // 0.390 * 2^RATIO_SCALE
#define B3C 0x0253   // 0.0363 * 2^LUX_SCALE
#define M3C 0x0363   // 0.0529 * 2^LUX_SCALE
#define K4C 0x010a   // 0.520 * 2^RATIO_SCALE
#define B4C 0x0282   // 0.0392 * 2^LUX_SCALE
#define M4C 0x03df   // 0.0605 * 2^LUX_SCALE
#define K5C 0x014d   // 0.65 * 2^RATIO_SCALE
#define B5C 0x0177   // 0.0229 * 2^LUX_SCALE
#define M5C 0x01dd   // 0.0291 * 2^LUX_SCALE
#define K6C 0x019a   // 0.80 * 2^RATIO_SCALE
#define B6C 0x0101   // 0.0157 * 2^LUX_SCALE
#define M6C 0x0127   // 0.0180 * 2^LUX_SCALE
#define K7C 0x029a   // 1.3 * 2^RATIO_SCALE
#define B7C 0x0037   // 0.00338 * 2^LUX_SCALE
#define M7C 0x002b   // 0.00260 * 2^LUX_SCALE
#define K8C 0x029a   // 1.3 * 2^RATIO_SCALE
#define B8C 0x0000   // 0.000 * 2^LUX_SCALE
#define M8C 0x0000   // 0.000 * 2^LUX_SCALE

//MAILBOX COMMANDS
#define CONFIG_IOP_SWITCH 0x1
#define GET_LIGHT_VALUE 0x3
#define GET_LUX_VALUE 0x5

typedef struct{
    u16 ch0;
    u16 ch1;
}lightPoint;

uint8_t CH0_LOW,CH0_HIGH,CH1_LOW,CH1_HIGH;
uint16_t ch0,ch1;
unsigned long chScale;
unsigned long channel1;
unsigned long channel0;
unsigned long  ratio1;
unsigned int b;
unsigned int m;
unsigned long lux;
unsigned long temp;

void init_dlight();
int write_dlight(u8 reg, u32 data, u8 bytes);
void getLux_dlight();
lightPoint readValues_dlight();
u32 readVisibleLux_dlight();
u32 calculateLux_dlight(unsigned int iGain, unsigned int tInt,int iType);
u32 read_dlight(u8 reg);

int main(void)
{
    lightPoint lightValue;
    u32 Lux;
    int cmd;

    arduino_init(0,0,0,0);
    config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, 
                          A_GPIO, A_SDA, A_SCL,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO);
    init_dlight();

    /*Loop reading*/
    while(1)
    {
        // wait and store valid command
        while((MAILBOX_CMD_ADDR)==0);
        cmd = MAILBOX_CMD_ADDR;

        switch(cmd)
        {
        case CONFIG_IOP_SWITCH:
            // use dedicated I2C
            config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, 
                                  A_GPIO, A_SDA, A_SCL,
                                  D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                                  D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                                  D_GPIO, D_GPIO, D_GPIO, D_GPIO);     
            init_dlight();
            MAILBOX_CMD_ADDR = 0x0;
            break;

        case GET_LIGHT_VALUE:
            lightValue = readValues_dlight();
            MAILBOX_DATA(0) = lightValue.ch0;
            MAILBOX_DATA(1) = lightValue.ch1;
            MAILBOX_CMD_ADDR = 0x0;
            break;

        case GET_LUX_VALUE:
            Lux = readVisibleLux_dlight();
            MAILBOX_DATA(2) = Lux;
            MAILBOX_CMD_ADDR = 0x0;
            break;
        }
    }

    return 0;

}

void init_dlight()
{
    /*Power up */
    write_dlight(TSL2561_Control,0x03,1);
    write_dlight(TSL2561_Timing,0x10,1);
    write_dlight(TSL2561_Interrupt,0x00,1);
    write_dlight(TSL2561_Control,0x00,1);
}

int write_dlight(u8 reg, u32 data, u8 bytes)
{
    u8 data_buffer[3];
    data_buffer[0] = reg;
    if(bytes ==2){
        data_buffer[1] = data & 0x0f; // Bits 11:8
        data_buffer[2] = data & 0xff; // Bits 7:0
    }else{
        data_buffer[1] = data & 0xff; // Bits 7:0
    }

    return iic_write(XPAR_IIC_0_BASEADDR, TSL2561_Address, data_buffer, 
                     bytes+1);
}

u32 read_dlight(u8 reg)
{
   u8 data_buffer[2];
   u32 sample;

   data_buffer[0] = reg; // Set the address pointer register
   iic_write(XPAR_IIC_0_BASEADDR, TSL2561_Address, data_buffer, 1);

   iic_read(XPAR_IIC_0_BASEADDR, TSL2561_Address,data_buffer,2);
   sample = data_buffer[0]&0x0f;
   return sample;
}

void getLux_dlight()
{
    CH0_LOW = read_dlight(TSL2561_Channal0L);
    CH0_HIGH = read_dlight(TSL2561_Channal0H);
    CH1_LOW = read_dlight(TSL2561_Channal1L);
    CH1_HIGH = read_dlight(TSL2561_Channal1H);

    ch0 = CH0_HIGH << 8 | CH0_LOW;
    ch1 = CH1_HIGH << 8 | CH1_LOW;
}

lightPoint readValues_dlight()
{
    lightPoint tempRead;

    /*power up*/
    write_dlight(TSL2561_Control,0x03,1);

    /*wait data*/
    delay_ms(15);

    getLux_dlight();

    /*move data*/
    tempRead.ch0=ch0;
    tempRead.ch1=ch1;

    /*power down*/
    write_dlight(TSL2561_Control,0x00,1);

    return tempRead;
}

u32 readVisibleLux_dlight()
{
    /*power up*/
    write_dlight(TSL2561_Control,0x03,1);

    /*wait data*/
    delay_ms(15);

    getLux_dlight();

    /*power down*/
    write_dlight(TSL2561_Control,0x00,1);

    if(ch0/ch1 < 2 && ch0 > 4900)
    {
        return 0;
    }
    return calculateLux_dlight(1,0,0);
}

u32 calculateLux_dlight(unsigned int iGain, unsigned int tInt,int iType)
{
    switch(tInt)
    {
    case 0: //13.7msec
        chScale = CHSCALE_TINT0;
        break;
    case 1: //101msec
        chScale = CHSCALE_TINT1;
        break;
    default:
        chScale = (1 << CH_SCALE);
        break;
    }

    if(!iGain)
        chScale = chScale << 4;
    /*scale channel values*/
    channel0 = (ch0 * chScale) >> CH_SCALE;
    channel1 = (ch1 * chScale) >> CH_SCALE;

    ratio1 = 0;
    if(channel0 != 0)
        ratio1 = (channel1 << (RATIO_SCALE+1))/channel0;
    ratio1 = (ratio1 +1) >> 1;

    switch (iType)
    {
        case 0: // T package
            if ((ratio1 >= 0) && (ratio1 <= K1T))
                {b=B1T; m=M1T;}
            else if (ratio1 <= K2T)
                {b=B2T; m=M2T;}
            else if (ratio1 <= K3T)
                {b=B3T; m=M3T;}
            else if (ratio1 <= K4T)
                {b=B4T; m=M4T;}
            else if (ratio1 <= K5T)
                {b=B5T; m=M5T;}
            else if (ratio1 <= K6T)
                {b=B6T; m=M6T;}
            else if (ratio1 <= K7T)
                {b=B7T; m=M7T;}
            else if (ratio1 > K8T)
                {b=B8T; m=M8T;}
            break;
        case 1:// CS package
            if ((ratio1 >= 0) && (ratio1 <= K1C))
                {b=B1C; m=M1C;}
            else if (ratio1 <= K2C)
                {b=B2C; m=M2C;}
            else if (ratio1 <= K3C)
                {b=B3C; m=M3C;}
            else if (ratio1 <= K4C)
                {b=B4C; m=M4C;}
            else if (ratio1 <= K5C)
                {b=B5C; m=M5C;}
            else if (ratio1 <= K6C)
                {b=B6C; m=M6C;}
            else if (ratio1 <= K7C)
                {b=B7C; m=M7C;}
    }
    temp=((channel0*b)-(channel1*m));
    if(temp<0) temp=0;
    temp+=(1<<(LUX_SCALE-1));
    // strip off fractional portion
    lux=temp>>LUX_SCALE;
    return lux;
}
