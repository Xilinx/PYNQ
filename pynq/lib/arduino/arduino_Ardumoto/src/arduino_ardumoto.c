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
 * @file arduino_ardumoto.c
 *
 * IOP code (MicroBlaze) for analog channels connected on PYNQ Shield board.
 * Any analog source providing analog voltage up to 3.3V can be connected.
 * Operations implemented:
 *  1. Simple, single read from sensor, and write to data area.
 *  2. Continuous read from sensor and log to data area.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- -------- -----------------------------------------------
 * 1.00a vg  09/22/17 initial support
 *
 * </pre>
 *
 *****************************************************************************/

#include "xparameters.h"
#include "arduino.h"
#include "xtmrctr_l.h"
#include "xgpio.h"

/*
 * TIMING_INTERVAL = (TLRx + 2) * AXI_CLOCK_PERIOD
 * PWM_PERIOD = (TLR0 + 2) * AXI_CLOCK_PERIOD
 * PWM_HIGH_TIME = (TLR1 + 2) * AXI_CLOCK_PERIOD
 */

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
// Default period value for 49hz
#define MS1_VALUE 625998
// Default period value for 50% duty cycle
#define MS2_VALUE 312998

// Mailbox commands
#define CONFIG_IOP_SWITCH  	0x1
#define CONFIGURE  		0x3
#define RECONFIGURE_DIR  	0x5
#define SET_DIRECTION  		0x7
#define SET_SPEED  		0x9
#define RUN  			0xB
#define STOP  			0xD

/*
 * Parameters passed in MAILBOX_WRITE_CMD
 * bits 31:16 => period in us
 * bits 15:8 is not used
 * bits 7:1 => duty cycle in %, valid range is 1 to 99
 */

/************************** Function Prototypes ******************************/
typedef enum motor {
MOTOR_A = 0,
MOTOR_B
}motor_e;

int pol_a = 0, pol_b = 0; // default polarity is mapped as FORWARD  is clockwise and REVERSE is anticlockwise
u32 duty = 1;

#define SET_OUT(x,n) (x &= ~(1 << n))
#define SET_IN(x,n)  (x |= (1 << n))

#define SET_LOW(x,n)  (x &= ~(1 << n))
#define SET_HIGH(x,n) (x |= (1 << n))

/************************** Function Prototypes ******************************/
void setup_start_timers_A(u32 duty) {

    // Load timer's Load registers (period, high time)
    XTmrCtr_WriteReg(XPAR_TMRCTR_0_BASEADDR, 0, TLR0, MS1_VALUE);
    XTmrCtr_WriteReg(XPAR_TMRCTR_0_BASEADDR, 1, TLR0, duty);
    /*
     * 0010 1011 0110 =>  no cascade, no all timers, enable pwm, 
     *                    interrupt status, enable timer,
     *                    no interrupt, no load timer, reload, 
     *                    no capture, enable external generate, 
     *                    down counter, generate mode
     */
    XTmrCtr_WriteReg(XPAR_TMRCTR_0_BASEADDR, 0, TCSR0, 0x296);
    XTmrCtr_WriteReg(XPAR_TMRCTR_0_BASEADDR, 1, TCSR0, 0x296);
}

void setup_start_timers_B(u32 duty) {

    // Load timer's Load registers (period, high time)
    XTmrCtr_WriteReg(XPAR_TMRCTR_5_BASEADDR, 0, TLR0, MS1_VALUE);
    XTmrCtr_WriteReg(XPAR_TMRCTR_5_BASEADDR, 1, TLR0, duty);
    /*
     * 0010 1011 0110 =>  no cascade, no all timers, enable pwm, 
     *                    interrupt status, enable timer,
     *                    no interrupt, no load timer, reload, 
     *                    no capture, enable external generate, 
     *                    down counter, generate mode
     */
    XTmrCtr_WriteReg(XPAR_TMRCTR_5_BASEADDR, 0, TCSR0, 0x296);
    XTmrCtr_WriteReg(XPAR_TMRCTR_5_BASEADDR, 1, TCSR0, 0x296);
}

void stop_timers_A(void) {
   //Stop the generation of PWM signal
   // disable timer 0
    XTmrCtr_WriteReg(XPAR_TMRCTR_0_BASEADDR, 0, TCSR0, 0);
   // disable timer 1
    XTmrCtr_WriteReg(XPAR_TMRCTR_0_BASEADDR, 1, TCSR0, 0);
}
void stop_timers_B(void) {
   //Stop the generation of PWM signal
   // disable timer 0
    XTmrCtr_WriteReg(XPAR_TMRCTR_5_BASEADDR, 0, TCSR0, 0);
   // disable timer 1
    XTmrCtr_WriteReg(XPAR_TMRCTR_5_BASEADDR, 1, TCSR0, 0);
}

int main(void)
{
    u32 cmd;
    u32 timer_a_duty, timer_b_duty;
    u8 iop_pins[19];
    u8 	PWMA = 8,PWMB = 16,DIRA = 7,DIRB = 9;
    u8 reconfigure = 0;
    u8 dir_A = 0, dir_B = 0, dir = 0; //0 = forward 1 = reverse
    u8 duty_a = 50, duty_b = 50; 
    motor_e motor = 0;
    u32 Channel_direction;
    u32 Channel_Data;

    arduino_init(0,0,0,0);

    // Initialize the default switch
    config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, A_GPIO, A_GPIO, A_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO,
                          D_GPIO, D_GPIO, D_GPIO, D_GPIO);

    while(1){
        // wait and store valid command
        while((MAILBOX_CMD_ADDR & 0x1)==0);
        cmd = (MAILBOX_CMD_ADDR & 0xF);

        switch(cmd){
            case CONFIG_IOP_SWITCH:
            /* Assign default pin configurations for below motor pin connections:
	       pin 2 - Direction control for motor A
	       pin 3 - PWM control (speed) for motor A
	       pin 4 - Direction control for motor B
	       pin 11 - PWM control (speed) for motor B
	    */
                iop_pins[0] = A_GPIO;
                iop_pins[1] = A_GPIO;
                iop_pins[2] = A_GPIO;
                iop_pins[3] = A_GPIO;
                iop_pins[4] = A_GPIO;
                iop_pins[5] = A_GPIO;
                iop_pins[6] = D_GPIO; //0,1
                iop_pins[7] = D_GPIO; //2
                iop_pins[8] = D_GPIO;//3
                iop_pins[9] = D_GPIO;//4
                iop_pins[10] = D_GPIO;//5
                iop_pins[11] = D_GPIO;//6
                iop_pins[12] = D_GPIO;//7
                iop_pins[13] = D_GPIO;//8
                iop_pins[14] = D_GPIO;//9
                iop_pins[15] = D_GPIO;//10
                iop_pins[16] = D_GPIO;//11
                iop_pins[17] = D_GPIO;//12
                iop_pins[18] = D_GPIO;//13
                config_arduino_switch(iop_pins[0], iop_pins[1], iop_pins[2], 
                                      iop_pins[3], iop_pins[4], iop_pins[5], 
                                      iop_pins[6], iop_pins[7],
                                      iop_pins[8], iop_pins[9], 
                                      iop_pins[10], iop_pins[11], 
                                      iop_pins[12], iop_pins[13], 
                                      iop_pins[14], iop_pins[15],
                                      iop_pins[16], iop_pins[17], 
                                      iop_pins[18]);
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case CONFIGURE:
            /* Reconfigure pin configurations for motor pin connections:
	1) pin 2 - Direction control for motor A
	   pin 3 - PWM control (speed) for motor A
	   pin 4 - Direction control for motor B
	   pin 11 - PWM control (speed) for motor B

	2) pin 8 - Direction control for motor A
	   pin 9 - PWM control (speed) for motor A
	   pin 7 - Direction control for motor B
	   pin 10 - PWM control (speed) for motor B
	    */
		reconfigure = MAILBOX_DATA(0);
		if(reconfigure) {
		PWMA = 14;
		PWMB = 15;
		DIRA = 13;
		DIRB = 12;
		}
		else {
		PWMA = 8;
		PWMB = 16;
		DIRA = 7;
		DIRB = 9;
		}
                iop_pins[PWMA] = D_PWM;
                iop_pins[PWMB] = D_PWM;
                iop_pins[DIRA] = A_GPIO;
                iop_pins[DIRB] = A_GPIO;
                config_arduino_switch(iop_pins[0], iop_pins[1], iop_pins[2], 
                                      iop_pins[3], iop_pins[4], iop_pins[5], 
                                      iop_pins[6], iop_pins[7],
                                      iop_pins[8], iop_pins[9], 
                                      iop_pins[10], iop_pins[11], 
                                      iop_pins[12], iop_pins[13], 
                                      iop_pins[14], iop_pins[15],
                                      iop_pins[16], iop_pins[17], 
                                      iop_pins[18]);
     
		MAILBOX_CMD_ADDR = 0x0;
                break;

            case RECONFIGURE_DIR:
		motor = MAILBOX_DATA(0);
		if (motor == MOTOR_A) {
			pol_a = MAILBOX_DATA(1);
		}
		if (motor == MOTOR_B) {
			pol_b = MAILBOX_DATA(1);
		}
                MAILBOX_CMD_ADDR = 0x0;
                break;


            case SET_DIRECTION:
		motor = MAILBOX_DATA(0);
		dir = MAILBOX_DATA(1);
		if (motor == MOTOR_A){
			if(dir) {
				dir_A = pol_a;
			}
			else {
				dir_A = !(pol_a);
			}
		}
		else if (motor == MOTOR_B){
			if(dir) {
				dir_B = pol_b;
			}
			else {
				dir_B = !(pol_b);
			}
		}

                MAILBOX_CMD_ADDR = 0x0;
                break;

            case SET_SPEED:
		motor = MAILBOX_DATA(0);
		if (motor == MOTOR_A) {
			duty_a = MAILBOX_DATA(1);
		}
		if (motor == MOTOR_B) {
			duty_b = MAILBOX_DATA(1);
		}
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case RUN:
		motor = MAILBOX_DATA(0);
		Channel_direction = Xil_In32(XPAR_GPIO_0_BASEADDR + 0x04);
		Xil_Out32(XPAR_GPIO_0_BASEADDR + 0x04,SET_OUT(Channel_direction,(DIRA-5)));
		Xil_Out32(XPAR_GPIO_0_BASEADDR + 0x04,SET_OUT(Channel_direction,(DIRB-5)));
		Channel_Data = Xil_In32(XPAR_GPIO_0_BASEADDR);
		if (motor == MOTOR_A) {
			if(dir_A){
				Xil_Out32(XPAR_GPIO_0_BASEADDR, SET_HIGH(Channel_Data,(DIRA-5))); 
			}
			else {
				Xil_Out32(XPAR_GPIO_0_BASEADDR, SET_LOW(Channel_Data,(DIRA-5))); 
			}
		
                timer_a_duty = (duty_a)*MS1_VALUE/100;
		setup_start_timers_A(timer_a_duty);
		}
		else if(motor == MOTOR_B) {
			if(dir_B){
				Xil_Out32(XPAR_GPIO_0_BASEADDR, SET_HIGH(Channel_Data,(DIRB-5))); 
			}
			else {
				Xil_Out32(XPAR_GPIO_0_BASEADDR, SET_LOW(Channel_Data,(DIRB-5)));
			}

                timer_b_duty = (duty_b)*MS1_VALUE/100;
		setup_start_timers_B(timer_b_duty);
		}
		
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case STOP:
		motor = MAILBOX_DATA(0);
		if (motor == MOTOR_A) {
		stop_timers_A();
		}
		else if (motor == MOTOR_B){
		stop_timers_B();
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
