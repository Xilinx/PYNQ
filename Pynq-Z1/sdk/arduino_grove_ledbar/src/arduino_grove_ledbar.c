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
 * @file arduino_grove_ledbar.c
 *
 * IOP code (MicroBlaze) for grove LED05031P.
 * The grove ledbar has to be connected to an arduino interface 
 * via a shield socket.
 * Grove LED bar is write only, and has simple one-bit GPIO interface.
 * Hardware version 2.0.
 * http://www.seeedstudio.com/wiki/Grove_-_LED_Bar
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a np  04/13/16 release
 * 1.00d yrq 07/26/16 separate pmod and arduino
 *
 * </pre>
 *
 *****************************************************************************/

#include "arduino.h"
#include "xgpio_l.h"
#include "xgpio.h"

// Work on 8-bit mode
#define CONFIG_IOP_SWITCH           0x1
#define RESET                       0x3
#define WRITE_LEDS                  0x5
#define SET_BRIGHTNESS              0x7
#define SET_LEVEL                   0x9
#define READ_LEDS                   0xB

/*
 * Green-to-Red direction contains slight transparency to one led distance.
 * i.e. A LED that is OFF will glow slightly if a LED  beside it is ON
 */
#define GLB_CMDMODE                 0x00
#define HIGH                        0xFF
#define LOW                         0x01
#define MED                         0xAA
#define OFF                         0x00

/*
 * The XGpio driver instance data. The user is required to allocate a
 * variable of this type for every GPIO device in the system. A pointer
 * to a variable of this type is then passed to the driver API functions.
 */
XGpio gpo;
u32 shift = 0;

/* 
 * LED state, Brightness for each LED in
 * {Red, Orange, Green, Green, Green, Green, Green, Green, Green, Green}
 */
char ledbar_state[10] = {OFF, OFF, OFF, OFF, OFF, OFF, OFF, OFF, OFF, OFF};
char current_state[10] = {OFF, OFF, OFF, OFF, OFF, OFF, OFF, OFF, OFF, OFF};

// Current Level
int level_holder = 0;

// Current direction: 0 => Red-to-Green, 1 => Green-to-Red
int prev_inverse = 0;

void ledbar_init(){
    /*
     * Initialize GPIO driver instance
     * Set data direction for two pins
     * Pin 0 = Data
     * Pin 1 = Clock
     */
    XGpio_Initialize(&gpo, XPAR_GPIO_0_DEVICE_ID);
    // Both pins set as Outputs
    XGpio_SetDataDirection(&gpo, 1, 0);
}

void send_data(u8 data){
    int i;
    u32 data_state, clk_state, detect, data_internal;

    data_internal = data;

    // Working in 8-bit mode
    for (i = 0; i < 8; i++){
        /*
         * Read each bit of the data to be sent LSB first
         * Write it to the data_pin
         */
        data_state = (data_internal & 0x80) ? 0x00000001 : 0x00000000;
        XGpio_DiscreteWrite(&gpo, 1, data_state<< shift);

        // Read Clock pin and regenerate clock
        detect = XGpio_DiscreteRead(&gpo, 1);
        clk_state = detect ^ (2 << shift);
        XGpio_DiscreteWrite(&gpo, 1, clk_state);

        // Shift Incoming data to fetch next bit
        data_internal = data_internal << 1;
    }
}

void latch_data(){
    int i;

    XGpio_DiscreteWrite(&gpo, 1, 0);
    delay_ms(10);

    // Generate four pulses on the data pin as per data sheet
    for (i = 0; i < 4; i++){
        XGpio_DiscreteWrite(&gpo, 1, 1<<shift);
        XGpio_DiscreteWrite(&gpo, 1, 0);
    }
}

u16 reverse_data(u16 c){
    /*
     * Function to reverse incoming data
     * Allows LEDbar to be lit in reverse order
     */
    int shift0;
    u16 result = 0;

    for (shift0 = 0; shift0 < 16; shift0++){
        if (c & (0x0001 << shift0))
            result |= (0x8000 >> shift0);
    }

    // 10 LSBs are used as LED Control 6 MSBs are ignored
    result = result >> 6;
    return result;
}

void set_bits(u16 data){
    int h,i;
    int data_internal = data;

    for(h=0; h<10; h++){
        ledbar_state[h] = HIGH;
    }

    send_data(GLB_CMDMODE);

    for (i = 0; i < 10; i++){
        if ((data_internal & 0x0001) == 1) {
            send_data(ledbar_state[i]);
        } else {
            send_data(0x00);
            ledbar_state[i] = 0x00;
        }
        data_internal = data_internal >> 1;
    }
    // Two extra empty bits for padding the command to the correct length
    send_data(0x00);
    send_data(0x00);


    latch_data();
    // Store LEBbar state for reading purpose.
    for(h=0; h<10; h++){
        current_state[h] = ledbar_state[h];
    }
}

void set_led_brightness(u16 data, char set_brightness[]){
    int h,i;
    int data_internal = data;

    for(h=0; h<10; h++){
        ledbar_state[h] = set_brightness[h];
    }

    send_data(GLB_CMDMODE);

    for (i = 0; i < 10; i++){
        if ((data_internal & 0x0001) == 1) {
            send_data(ledbar_state[i]);
        } else {
            send_data(0x00);
            ledbar_state[i] = 0x00;
        }
        data_internal = data_internal >> 1;
    }
    // Two extra empty bits for padding the command to the correct length
    send_data(0x00);
    send_data(0x00);

    latch_data();
    // Store LEBbar state for reading purpose.
    for(h=0; h<10; h++){
        current_state[h] = ledbar_state[h];
    }
}

void set_level(int level, int intensity, int inverse){
    int h,i;
    int prev_inv ;

    prev_inv = prev_inverse;

    // Clear LED states from previous writes
    if (inverse != prev_inv) {
        for(h=0; h<10; h++){
            ledbar_state[h] = OFF;
        }
    }

    if (inverse == 0) { 
        // Execute when direction is Red-to-Green
        if (level < level_holder) {
            for(h=level_holder-1; h>level-1; h--){
                ledbar_state[h] = OFF;
            }
        }
        for(h=0; h<level; h++)
        {
            if (intensity == 1) {
                ledbar_state[h] = LOW;
            } else if (intensity == 2) {
                ledbar_state[h] = MED;
            } else if (intensity == 3) {
                ledbar_state[h] = HIGH;
            } else {
                ledbar_state[h] = OFF;
            }
        }
        for(h=level; h>10; h++){
            ledbar_state[h] = OFF;
        }
    } else if(inverse == 1) { // Execute when direction is Red-to-Green
        if (level < level_holder) {
            for(h=0; h>=10-level; h++)
            {
                ledbar_state[h] = OFF;
            }
        }
        for(h=9; h>=10-level; h--)
        {
            if (intensity == 1) {
                ledbar_state[h] = LOW;
            } else if (intensity == 2) {
                ledbar_state[h] = MED;
            } else if (intensity == 3) {
                ledbar_state[h] = HIGH;
            } else {
                ledbar_state[h] = OFF;
            }
        }
        if (level != 10) {
            for(h=10-level-1; h>=0; h--)
            {
                ledbar_state[h] = OFF;
            }
        }
    } else { // Execute when direction is Invalid Integer
        for(h=0; h<10; h++){
            ledbar_state[h] = OFF;
        }
    }

    send_data(GLB_CMDMODE);

    for (i = 0; i < 10; i++){
        send_data(ledbar_state[i]);
    }
    // Two extra empty bits for padding the command to the correct length
    send_data(0x00);
    send_data(0x00);

    // Two extra empty bits for padding the command to the correct length
    latch_data();
    // Store LEBbar Indication level for resetting level
    level_holder= level;
    // Store LEBbar direction for resetting direction
    prev_inverse = inverse;
    // Store LEBbar state for reading purpose.
    for(h=0; h<10; h++){
        current_state[h] = ledbar_state[h];
    }
}

u16 ledbar_read(){
    int h;
    u16 bits;

    bits = 0x0000;
    for(h=0; h<10; h++){
        if (current_state[h] != 0x00) {
            bits |= 0x0001 << h;
        }
    }
    bits = bits & 0x03FF;
    return bits;
}


int main(void)
{
    int cmd,level,brightness,red_to_green;
    char set_brightness[10];
    u16 get_bits;
    u16 data;

    arduino_init(0,0,0,0);
    config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, 
                          A_GPIO, A_GPIO, A_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO);
    ledbar_init();
    
    while(1){
        // wait and store valid command
        while((MAILBOX_CMD_ADDR & 0x01)==0);
        cmd = MAILBOX_CMD_ADDR;

        switch(cmd){
              case CONFIG_IOP_SWITCH:
                  // read new pin configuration
                  config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, 
                                        A_GPIO, A_GPIO, A_GPIO,
                                        D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                                        D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                                        D_GPIO, D_GPIO, D_GPIO, D_GPIO);
                  shift = MAILBOX_DATA(0);
                  MAILBOX_CMD_ADDR = 0x0;
                  break;
                  
              case RESET:
                  set_bits(0x0000);
                  level_holder = 0;
                  prev_inverse = 0;
                  MAILBOX_CMD_ADDR = 0x0;
                  break;

              case WRITE_LEDS:
                  data = (u16) MAILBOX_DATA(0);
                  set_bits(data);
                  MAILBOX_CMD_ADDR = 0x0;
                  break;

              case SET_BRIGHTNESS:
                  data = (u16) MAILBOX_DATA(0);
                  set_brightness[9] = MAILBOX_DATA(1);
                  set_brightness[8] = MAILBOX_DATA(2);
                  set_brightness[7] = MAILBOX_DATA(3);
                  set_brightness[6] = MAILBOX_DATA(4);
                  set_brightness[5] = MAILBOX_DATA(5);
                  set_brightness[4] = MAILBOX_DATA(6);
                  set_brightness[3] = MAILBOX_DATA(7);
                  set_brightness[2] = MAILBOX_DATA(8);
                  set_brightness[1] = MAILBOX_DATA(9);
                  set_brightness[0] = MAILBOX_DATA(10);
                  set_led_brightness(data, set_brightness);
                  MAILBOX_CMD_ADDR = 0x0;
                  break;

              case SET_LEVEL:
                  level = (int) MAILBOX_DATA(0);
                  brightness = (u8) MAILBOX_DATA(1);
                  red_to_green = (int) MAILBOX_DATA(2);
                  set_level(level,brightness,red_to_green);
                  MAILBOX_CMD_ADDR = 0x0;
                  break;

           case READ_LEDS:
                  get_bits = ledbar_read();
                  MAILBOX_DATA(0) = (unsigned)get_bits;
                  MAILBOX_CMD_ADDR = 0x0;
                  break;

              default:
                  MAILBOX_CMD_ADDR = 0x0; // reset command
                  break;
           }
         }
   return(0);
}
