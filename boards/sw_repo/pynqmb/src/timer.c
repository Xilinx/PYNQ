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
#include <xparameters.h>
#include "timer.h"

#ifdef XPAR_XTMRCTR_NUM_INSTANCES
#include "xtmrctr.h"
static XTmrCtr xtimer[XPAR_XTMRCTR_NUM_INSTANCES];
XTmrCtr* xtimer_ptr = &xtimer[0];
extern XTmrCtr_Config XTmrCtr_ConfigTable[XPAR_XTMRCTR_NUM_INSTANCES];

/************************** Function Definitions ***************************/
timer timer_open_device(unsigned int device) {
    int status;
    u16 dev_id;
    if (device < XPAR_XTMRCTR_NUM_INSTANCES) {
        dev_id = (u16)device;
    } else {
        int found = 0;
        for (u16 i = 0; i < XPAR_XTMRCTR_NUM_INSTANCES; ++i) {
            if (XTmrCtr_ConfigTable[i].BaseAddress == device) {
                found = 1;
                dev_id = i;
                break;
            }
        }
        if (!found) return -1;
    }
    status = XTmrCtr_Initialize(&xtimer[dev_id], dev_id);
    if (status != XST_SUCCESS) {
        return -1;
    }
    XTmrCtr_SetOptions(&xtimer[dev_id], 1,
        XTC_AUTO_RELOAD_OPTION | XTC_CSR_LOAD_MASK | XTC_CSR_DOWN_COUNT_MASK);

    return (timer)dev_id;
}


#ifdef XPAR_IO_SWITCH_NUM_INSTANCES
#ifdef XPAR_IO_SWITCH_0_TIMER0_BASEADDR
#include "xio_switch.h"

static int last_timer0 = -1;

timer timer_open(unsigned int pin){
    if (last_timer0 != -1) set_pin(last_timer0, GPIO);
    last_timer0 = pin;
    set_pin(pin, TIMER_G0);
    return timer_open_device(XPAR_IO_SWITCH_0_TIMER0_BASEADDR);
}
#endif
#endif


void timer_delay(timer dev_id, unsigned int cycles){
    XTmrCtr_SetResetValue(&xtimer[dev_id], 1, cycles);
    XTmrCtr_Start(&xtimer[dev_id], 1);
    while(!XTmrCtr_IsExpired(&xtimer[dev_id],1));
    XTmrCtr_Stop(&xtimer[dev_id], 1);
}

__attribute__((constructor))
static void init_delay_timer() {
    static int initialized = 0;
    if (initialized == 0) {
        timer_open_device(0);
        initialized = 1;
    }
}

void delay_us(unsigned int us){
    unsigned int cycles_per_us = XPAR_MICROBLAZE_CORE_CLOCK_FREQ_HZ / 1000000;
    init_delay_timer();
    timer_delay(0, cycles_per_us * us);
}

void delay_ms(unsigned int ms){
    unsigned int cycles_per_ms = XPAR_MICROBLAZE_CORE_CLOCK_FREQ_HZ / 1000;
    init_delay_timer();
    timer_delay(0, cycles_per_ms * ms);
}


void timer_close(timer dev_id){
    XTmrCtr_Stop(&xtimer[dev_id], 0);
    XTmrCtr_Stop(&xtimer[dev_id], 1);
    XTmrCtr_ClearStats(&xtimer[dev_id]);
}


void timer_pwm_generate(timer dev_id, unsigned int period, unsigned int pulse){
    unsigned int base_address = xtimer[dev_id].BaseAddress;
    XTmrCtr_WriteReg(base_address, 0, TCSR0, 0x296);
    XTmrCtr_WriteReg(base_address, 1, TCSR0, 0x296);
    // period in number of clock cycles
    XTmrCtr_WriteReg(base_address, 0, TLR0, period);
    // pulse in number of clock cycles
    XTmrCtr_WriteReg(base_address, 1, TLR0, pulse);
}


void timer_pwm_stop(timer dev_id){
    unsigned int base_address = xtimer[dev_id].BaseAddress;
    XTmrCtr_WriteReg(base_address, 0, TCSR0, 0);
    // disable timer 1
    XTmrCtr_WriteReg(base_address, 1, TCSR0, 0);
}


unsigned int timer_get_num_devices(void){
    return XPAR_XTMRCTR_NUM_INSTANCES;
}


#endif
