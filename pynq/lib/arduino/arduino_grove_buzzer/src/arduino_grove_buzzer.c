/******************************************************************************
 *  Copyright (c) 2016, Xilinx, Inc.
 *  SPDX-License-Identifier: BSD-3-Clause
 *
 *****************************************************************************/
/******************************************************************************
 *
 *
 * @file arduino_grove_buzzer.c
 *
 * IOP code (MicroBlaze) for grove buzzer.
 * The grove buzzer has to be connected to an arduino interface 
 * via a shield socket.
 * Grove Buzzer is write only, and has simple one-bit GPIO interface.
 * Hardware version 1.2.
 * http://www.seeedstudio.com/wiki/Grove_-_Buzzer
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a pp  04/13/16 release
 * 1.00d yrq 07/26/16 separate pmod and arduino
 * 1.00e yrq 08/05/16 support arduino shield
 *
 * </pre>
 *
 *****************************************************************************/
 
#include "circular_buffer.h"
#include "gpio.h"
#include "timer.h"

// Mailbox commands
#define CONFIG_IOP_SWITCH       0x1
#define PLAY_TONE               0x3
#define PLAY_DEMO               0x5

// The driver instance for GPIO Devices
gpio speaker_gpio;


void generateTone(int period_us) {
    // turn-ON speaker
    gpio_write(speaker_gpio, 1);
    delay_us(period_us>>1);
    // turn-OFF speaker
    gpio_write(speaker_gpio, 0);
    delay_us(period_us>>1);
}

void playTone(int tone, int duration) { 
    // tone is in us delay
    long i;
    for (i = 0; i < duration * 1000L; i += tone * 2) {
        generateTone(tone*2);
    }
}

void playNote(char note, int duration) {

    char names[] = { 'c', 'd', 'e', 'f', 'g', 'a', 'b', 'C', 'D' };
    int tones[] = { 1915, 1700, 1519, 1432, 1275, 1136, 1014, 956, 1702 };
    int i;

    // play the tone corresponding to the note name
    for (i = 0; i < 8; i++) {
        if (names[i] == note) {
          playTone(tones[i], duration);
        }
    }
}

void melody_demo(void) {
    // The number of notes
    int length = 15;
    char notes[] = "ccggaagffeeddc ";
    int beats[] = { 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 2, 4 };
    int tempo = 300;
    int i;

    for(i = 0; i < length; i++) {
        if(notes[i] == ' ') {
            delay_ms(beats[i] * tempo);
        } else {
            playNote(notes[i], beats[i] * tempo);
        }
        // Delay between notes
        delay_ms(tempo / 2);
    }
}

int main(void) {
    int i=0;
    int period_us = 0x55;
    int num_cycles = 10;
    u32 cmd;

    while(1){
        while((MAILBOX_CMD_ADDR & 0x01)==0);
        cmd = MAILBOX_CMD_ADDR;
        
        switch(cmd){
            case CONFIG_IOP_SWITCH:
                speaker_gpio = gpio_open(MAILBOX_DATA(0));
                gpio_set_direction(speaker_gpio, GPIO_OUT);
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            case PLAY_TONE:
                period_us = MAILBOX_DATA(0);
                num_cycles = MAILBOX_DATA(1);
                for(i=0; i<num_cycles; i++){
                    generateTone(period_us);
                }
                MAILBOX_CMD_ADDR = 0x0;
                break;
                
            case PLAY_DEMO: 
                melody_demo();
                MAILBOX_CMD_ADDR = 0x0;
                break;
                    
            default:
                MAILBOX_CMD_ADDR = 0x0;
                break;
        }
    }
    return 0;
}

