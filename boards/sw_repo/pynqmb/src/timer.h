/******************************************************************************
 *  Copyright (c) 2018, Xilinx, Inc.
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
 * @file timer.c
 *
 * Implementing timer related functions for PYNQ Microblaze, 
 * including the delay functions.
 *
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00  yrq 01/09/18 release
 * 1.01  yrq 01/30/18 add protection macro
 *
 * </pre>
 *
 *****************************************************************************/
#ifndef _TIMER_H_
#define _TIMER_H_

#include <xparameters.h>
#ifdef XPAR_XTMRCTR_NUM_INSTANCES
#include "xtmrctr.h"

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
// Default period value for 100000 us
#define MS1_VALUE 99998
// Default period value for 50% duty cycle
#define MS2_VALUE 49998

/* 
 * Timer API
 */
static XTmrCtr timer_ctrl[XPAR_XTMRCTR_NUM_INSTANCES];
static int timer_fd[XPAR_XTMRCTR_NUM_INSTANCES];

const unsigned int timer_base_address[XPAR_XTMRCTR_NUM_INSTANCES] = {
#ifdef XPAR_TMRCTR_0_BASEADDR
    XPAR_TMRCTR_0_BASEADDR,
#endif
#ifdef XPAR_TMRCTR_1_BASEADDR
    XPAR_TMRCTR_1_BASEADDR,
#endif
};


int timer_open_device(unsigned int device);
void timer_delay(int timer, unsigned int cycles);
void timer_close(int timer);
void timer_pwm_generate(int timer, unsigned int period, unsigned int pulse);
void timer_pwm_stop(int timer);

#endif


unsigned int timer_get_num_devices(void){
#ifdef XPAR_XTMRCTR_NUM_INSTANCES
    return XPAR_XTMRCTR_NUM_INSTANCES;
#else
    return 0;
#endif
}

#endif  // _TIMER_H_
