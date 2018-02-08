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
static XTmrCtr xtimer[XPAR_XTMRCTR_NUM_INSTANCES];
/************************** Function Definitions ***************************/
timer timer_open_device(unsigned int device) {
    int status;
    u16 dev_id;
    unsigned int base_address;

    dev_id = (u16)device;
#ifdef XPAR_TMRCTR_0_BASEADDR
    if (device == XPAR_TMRCTR_0_BASEADDR){
        dev_id = 0;
    }
#endif
#ifdef XPAR_TMRCTR_1_BASEADDR
    if (device == XPAR_TMRCTR_1_BASEADDR){
        dev_id = 1;
    }
#endif

    status = XTmrCtr_Initialize(&xtimer[dev_id], dev_id);
    if (status != XST_SUCCESS) {
        return -1;
    }
    XTmrCtr_SetOptions(&xtimer[dev_id], 1,
        XTC_AUTO_RELOAD_OPTION | XTC_CSR_LOAD_MASK | XTC_CSR_DOWN_COUNT_MASK);

    // Load timer's Load registers (period, high time)
    base_address = xtimer[dev_id].BaseAddress;
    XTmrCtr_WriteReg(base_address, 0, TLR0, MS1_VALUE);
    XTmrCtr_WriteReg(base_address, 1, TLR0, MS2_VALUE);
    /*
     * 0010 1011 0110 =>  no cascade, no all timers, enable pwm, 
     *                    interrupt status, enable timer,
     *                    no interrupt, no load timer, reload, 
     *                    no capture, enable external generate, 
     *                    down counter, generate mode
     */
    XTmrCtr_WriteReg(base_address, 0, TCSR0, 0x296);
    XTmrCtr_WriteReg(base_address, 1, TCSR0, 0x296);

    return (timer)dev_id;
}


#ifdef XPAR_IO_SWITCH_NUM_INSTANCES
#ifdef XPAR_IO_SWITCH_0_TIMER0_BASEADDR
timer timer_open(unsigned int pin){
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


#endif
