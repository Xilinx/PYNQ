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
 * IOP code (MicroBlaze) for ardumoto shield on arduino interface.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- -------- -----------------------------------------------
 * 1.00a vg  09/22/17 initial support
 * 2.10  yrq 03/06/18 fix based on new API
 *
 * </pre>
 *
 *****************************************************************************/

#include "xparameters.h"
#include "xio_switch.h"
#include "circular_buffer.h"
#include "gpio.h"
#include "timer.h"

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
#define DEFAULT_PERIOD 625998
// Default period value for 50% duty cycle
#define DEFAULT_DUTY 312998

// Mailbox commands
#define CONFIG_IOP_SWITCH   0x1
#define CONFIGURE_PIN       0x3
#define CONFIGURE_POLAR     0x5
#define SET_DIRECTION       0x7
#define SET_SPEED           0x9
#define RUN                 0xB
#define STOP                0xD

/************************** Function Prototypes ******************************/
typedef enum motor {
MOTOR_A = 0,
MOTOR_B = 1,
}motor_e;

int pol_a = 0, pol_b = 0; // default polarity is mapped as FORWARD (clockwise)
u32 duty = 1;

/************************** Function Prototypes ******************************/
static timer timer_a;
static timer timer_b;
static gpio gpio_a;
static gpio gpio_b;

int main(void)
{
    u32 cmd;
    u32 timer_a_duty, timer_b_duty;
    u8  pwm_a_pin = 8, pwm_b_pin = 16, dir_a_pin = 7, dir_b_pin = 9;
    u8 configuration = 0;
    u32 dir_a = 0, dir_b = 0, dir = 0; //0 = forward; 1 = reverse
    u8 duty_a = 50, duty_b = 50; 
    motor_e motor = 0;

    /* 
     *  Assign default configurations for motor pin connections:
     *  pin 3 - PWM control (speed) for motor A
     *  pin 11 - PWM control (speed) for motor B
     *  pin 2 - Direction control for motor A
     *  pin 4 - Direction control for motor B
     */
    timer_a = timer_open_device(0);
    timer_b = timer_open_device(5);
    set_pin(3, PWM0);
    set_pin(11, PWM5);
    gpio_a = gpio_open(2);
    gpio_b = gpio_open(4);
    gpio_set_direction(gpio_a, GPIO_OUT);
    gpio_set_direction(gpio_b, GPIO_OUT);

    while(1){
        // wait and store valid command
        while((MAILBOX_CMD_ADDR & 0x1)==0);
        cmd = (MAILBOX_CMD_ADDR & 0xF);

        switch(cmd){
            case CONFIG_IOP_SWITCH:
                set_pin(8, PWM0);
                set_pin(16, PWM5);
                gpio_a = gpio_open(7);
                gpio_b = gpio_open(9);
                gpio_set_direction(gpio_a, GPIO_OUT);
                gpio_set_direction(gpio_b, GPIO_OUT);
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case CONFIGURE_PIN:
                /* Configure pin configurations for motor pin connections:
                 *   (alternative)
                 *      pin 9 - PWM control (speed) for motor A
                 *      pin 10 - PWM control (speed) for motor B
                 *      pin 8 - Direction control for motor A
                 *      pin 7 - Direction control for motor B
                 *
                 *   (default)
                 *      pin 3 - PWM control (speed) for motor A
                 *      pin 11 - PWM control (speed) for motor B
                 *      pin 2 - Direction control for motor A
                 *      pin 4 - Direction control for motor B
                 */
                configuration = MAILBOX_DATA(0);
                if(configuration) {
                    pwm_a_pin = 9;
                    pwm_b_pin = 10;
                    dir_a_pin = 8;
                    dir_b_pin = 7;
                }
                else {
                    pwm_a_pin = 3;
                    pwm_b_pin = 11;
                    dir_a_pin = 2;
                    dir_b_pin = 4;
                }
                set_pin(pwm_a_pin, PWM0);
                set_pin(pwm_b_pin, PWM5);
                gpio_a = gpio_open(dir_a_pin);
                gpio_b = gpio_open(dir_b_pin);
                gpio_set_direction(gpio_a, GPIO_OUT);
                gpio_set_direction(gpio_b, GPIO_OUT);
     
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case CONFIGURE_POLAR:
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
                    dir_a = (dir)? pol_a : !pol_a;
                }
                else if (motor == MOTOR_B){
                    dir_b = (dir)? pol_b : !pol_b;
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
                if (motor == MOTOR_A) {
                    gpio_write(gpio_a, dir_a);
                    timer_a_duty = duty_a*DEFAULT_PERIOD/100;
                    timer_pwm_generate(timer_a, DEFAULT_PERIOD, timer_a_duty);
                }
                else if(motor == MOTOR_B) {
                    gpio_write(gpio_b, dir_b);
                    timer_b_duty = duty_b*DEFAULT_PERIOD/100;
                    timer_pwm_generate(timer_b, DEFAULT_PERIOD, timer_b_duty);
                }
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case STOP:
                motor = MAILBOX_DATA(0);
                if (motor == MOTOR_A) {
                    timer_pwm_stop(timer_a);
                }
                else if (motor == MOTOR_B){
                    timer_pwm_stop(timer_b);
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
