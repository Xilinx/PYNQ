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
 * @file arduino_grove_USranger.c
 *
 *
 *****************************************************************************/

#include "xparameters.h"
#include "xgpio.h"
#include "arduino.h"

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
#define MAX_COUNT 0xFFFFFFFF

// Mailbox commands
#define CONFIG_IOP_SWITCH 	0x1
#define READ                    0x2
#define READ_AND_LOG_DATA       0x3
#define STOP_LOG                0xC

// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_ITEM_SIZE sizeof(float)
#define LOG_CAPACITY  (4000/LOG_ITEM_SIZE)

/*
 * Parameters passed in MAILBOX_DATA(0):
 * READ: Generate a 10 usec pulse on selected gpio and then switch to the timer mode to capture duration.
 * READ_AND_LOG_DATA: Continuously read multiple values for the duration provided by the user and log into buffer
 * STOP_LOG: [7:0]- Stop the meaurement logging 
 *
 * Results returned in MAILBOX_DATA(0):
 * READ: The duration of the pulse echoed back by the sensor
 * READ_AND_LOG_DATA: none
 * STOP_LOG: None
 */

// The Timer Counter instance
extern XTmrCtr TimerInst_0;

#define SET_OUT(x,n) (x &= ~(1 << n))
#define SET_IN(x,n)  (x |= (1 << n))

#define SET_LOW(x,n)  (x &= ~(1 << n))
#define SET_HIGH(x,n) (x |= (1 << n))

void fun_Create10usPulse(u32 pin)
{
        u32 Channel_direction;
        u32 Channel_Data;

	Channel_direction = Xil_In32(XPAR_GPIO_0_BASEADDR + 0x04);
	Channel_Data = Xil_In32(XPAR_GPIO_0_BASEADDR);

	Xil_Out32(XPAR_GPIO_0_BASEADDR + 0x04,SET_OUT(Channel_direction,pin));
	Xil_Out32(XPAR_GPIO_0_BASEADDR, SET_LOW(Channel_Data,pin)); 
	delay_us(2);
	Xil_Out32(XPAR_GPIO_0_BASEADDR, SET_HIGH(Channel_Data,pin)); 
	delay_us(10);
	Xil_Out32(XPAR_GPIO_0_BASEADDR, SET_LOW(Channel_Data,pin)); 
}

void fun_ConfigureAsInput(u32 pin)
{
	u32 Channel_direction;
	Channel_direction = Xil_In32(XPAR_GPIO_0_BASEADDR + 0x04);
	Xil_Out32(XPAR_GPIO_0_BASEADDR + 0x04,SET_IN(Channel_direction,pin));
}

u32 fun_CaptureDuration(u32 pin)
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
	while(!((Xil_In32(XPAR_GPIO_0_BASEADDR) & (1 << pin))));
        // read counter value
        count1=XTmrCtr_ReadReg(XPAR_TMRCTR_0_BASEADDR, 0, TCR0);
        // wait for falling edge
	while((Xil_In32(XPAR_GPIO_0_BASEADDR) & (1 << pin)));
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
    u32 value = 0 ,delay = 0;
    // Initialize arduino
    arduino_init(0,0,0,0);
    
    config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, 
                          A_GPIO, A_GPIO, A_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO);

    while(1){
        while(MAILBOX_CMD_ADDR==0); // wait for CMD to be issued
        cmd = MAILBOX_CMD_ADDR;
        
        switch(cmd){
	    case CONFIG_IOP_SWITCH:
		// Keep the pin as GPIO to be able to generate 10usec start pulse on read command.
    		config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, 
                          A_GPIO, A_GPIO, A_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO);
                MAILBOX_CMD_ADDR = 0x0;
                break;
            case READ:
                //Start a 10 usec pulse on the selected pin  
                usranger_pin = MAILBOX_DATA(0);
		fun_Create10usPulse(usranger_pin);
		fun_ConfigureAsInput(usranger_pin);
		value = fun_CaptureDuration(usranger_pin);
                MAILBOX_DATA(0)=value;
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case READ_AND_LOG_DATA:
                // initialize logging variables, reset cmd
                cb_init(&arduino_log, LOG_BASE_ADDRESS, 
                        LOG_CAPACITY, LOG_ITEM_SIZE);
                delay = MAILBOX_DATA(1);
                MAILBOX_CMD_ADDR = 0x0;
                do{
                    // push sample to log and delay
                    fun_Create10usPulse(usranger_pin);
		    fun_ConfigureAsInput(usranger_pin);
		    value = fun_CaptureDuration(usranger_pin);
                    cb_push_back(&arduino_log, &value);
                    delay_ms(delay);
                } while((MAILBOX_CMD_ADDR & 0x1)== 0);
                break;      
                
             default:
                MAILBOX_CMD_ADDR = 0x0;
                break;
            }
    }
    return 0;
}


