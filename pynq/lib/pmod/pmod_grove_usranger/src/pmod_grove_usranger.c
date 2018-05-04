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
 * @file pmod_grove_usranger.c
 * IOP code (MicroBlaze) for grove ultrasonic range sensor.
 * The sensor has to be connected to a PMOD interface 
 * via a shield socket.
 * https://www.seeedstudio.com/Grove---Ultrasonic-Ranger-p-960.html
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- -------- -----------------------------------------------
 * 1.00a gv  09/22/17 release
 * 2.10  yrq 03/06/18 revise for latest release
 *
 * </pre>
 *
 *****************************************************************************/

#include "xparameters.h"
#include "xtmrctr.h"
#include "gpio.h"
#include "timer.h"
#include "circular_buffer.h"


// TCSR0 Timer 0 Control and Status Register
#define TCSR0 0x00
// TLR0 Timer 0 Load Register
#define TLR0 0x04
// TCR0 Timer 0 Counter Register
#define TCR0 0x08
// TCSR1 Timer 1 Control and Status Register
#define TCSR1 0x10
// TLR1 Timer 1 Load Register
#define TLR1 0x14
// TCR1 Timer 1 Counter Register
#define TCR1 0x18

// Mailbox commands
#define CONFIG_IOP_SWITCH       0x1
#define READ                    0x2
#define READ_AND_LOG_DATA       0x3
#define STOP_LOG                0xC

// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_ITEM_SIZE sizeof(float)
#define LOG_CAPACITY  (4000/LOG_ITEM_SIZE)
#define MAX_COUNT 0xFFFFFFFF
/*
 * Parameters passed in MAILBOX_DATA(0):
 * READ: Generate a 10 usec pulse on selected gpio and then switch to the 
 * timer mode to capture duration.
 * READ_AND_LOG_DATA: Continuously read multiple values for the duration 
 * provided by the user and log into buffer
 * STOP_LOG: [7:0]- Stop the meaurement logging 
 *
 * Results returned in MAILBOX_DATA(0):
 * READ: The duration of the pulse echoed back by the sensor
 * READ_AND_LOG_DATA: none
 * STOP_LOG: None
 */

static gpio usranger;

void create_10us_pulse(gpio usranger)
{
    gpio_set_direction(usranger, GPIO_OUT);

    gpio_write(usranger, 0);
    delay_us(2);
    gpio_write(usranger, 1);
    delay_us(10);
    gpio_write(usranger, 0);
}

void configure_as_input(gpio usranger)
{
    gpio_set_direction(usranger, GPIO_IN);
}

u32 capture_duration(gpio usranger)
{
    u32 count1, count2;
    /*
     * Use timer module 0 for finding signal pulse width
     * poll the GPIO to get the start and end of pulse
     */
    count1=0;
    count2=0;
    // Set Load Register with maximum value
    XTmrCtr_WriteReg(XPAR_TMRCTR_0_BASEADDR, 0, TLR0, 0x0);
    /*
    * 0001 1001 0000 =>  no cascade, no all timers, no pwm,
    *                    clear interrupt status, enable timer,
    *                    no interrupt, no load timer,
    *                    reload generate value,
    *                    Disable external capture,
    *                    disable external generate,
    *                    up counter, generate mode
    */
    // reset load bit and enable generate mode
    XTmrCtr_WriteReg(XPAR_TMRCTR_0_BASEADDR, 0, TCSR0, 0x190);
    // wait for rising edge
    while(!gpio_read(usranger));
    // read counter value
    count1=XTmrCtr_ReadReg(XPAR_TMRCTR_0_BASEADDR, 0, TCR0);
    // wait for falling edge
    while(gpio_read(usranger));
    // read counter value
    count2=XTmrCtr_ReadReg(XPAR_TMRCTR_0_BASEADDR, 0, TCR0);
    if(count2 > count1) {
     return (count2 - count1);
    }
    else {
    return((MAX_COUNT - count1) + count2);  
    }   
}

int main(void) {
    u32 cmd;
    u32 usranger_pin = 0;
    u32 value = 0, delay = 0;
    
    usranger = gpio_open(usranger_pin);

    while(1){
        while(MAILBOX_CMD_ADDR==0); // wait for CMD to be issued
        cmd = MAILBOX_CMD_ADDR;
        
        switch(cmd){
            case CONFIG_IOP_SWITCH:
                usranger_pin = MAILBOX_DATA(0);
                usranger = gpio_open(usranger_pin);
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case READ:
                //Start a 10 usec pulse on the selected pin  
                create_10us_pulse(usranger);
                configure_as_input(usranger);
                value = capture_duration(usranger);
                MAILBOX_DATA(0) = value;
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case READ_AND_LOG_DATA:
                // initialize logging variables, reset cmd
                cb_init(&circular_log, LOG_BASE_ADDRESS, 
                        LOG_CAPACITY, LOG_ITEM_SIZE);
                delay = MAILBOX_DATA(1);
                while(MAILBOX_CMD_ADDR != STOP_LOG){
                    // push sample to log and delay
                    create_10us_pulse(usranger);
                    configure_as_input(usranger);
                    value = capture_duration(usranger);
                    cb_push_back(&circular_log, &value);
                    delay_ms(delay);
                }
                MAILBOX_CMD_ADDR = 0x0;
                break;      
                
             default:
                MAILBOX_CMD_ADDR = 0x0;
                break;
            }
    }
    return 0;
}
