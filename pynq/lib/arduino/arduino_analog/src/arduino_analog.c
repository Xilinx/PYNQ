/******************************************************************************
 *  Copyright (c) 2016-2020, Xilinx, Inc.
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
 * @file arduino_analog.c
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
 * 1.00a pp  09/01/16 release
 * 1.00b yrq 09/06/16 adjust format, change log size
 * 1.00c lcc 11/10/16 voltage reference with single fl.point division
 * 1.10  mrn 10/11/20 Fix the log_capacity computation, it depends on the number
 *                    of channels. Enhancement remove floating point operations.
 *
 * </pre>
 *
 *****************************************************************************/
#include "circular_buffer.h"
#include "timer.h"
#include "xparameters.h"
#include "xsysmon.h"

// Mailbox commands
#define CONFIG_IOP_SWITCH       0x1
#define GET_RAW_DATA            0x3
#define READ_AND_LOG_RAW        0x7
#define RESET_ANALOG            0xB
/******************************************************************************
 *
 * Channels to be read is indicated in Mailbox command starting with bit[8] to
 * bit[13] as follows:
 * bit[8] = A0
 * bit[9] = A1
 * bit[10] = A2
 * bit[11] = A3
 * bit[12] = A4
 * bit[13] = A5
 *
 *****************************************************************************/
// Log constants
#define LOG_BASE_ADDRESS (MAILBOX_DATA_PTR(4))
#define LOG_INT_SIZE sizeof(int)
#define MAX_SAMPLES (4072 / LOG_INT_SIZE)

#define SYSMON_DEVICE_ID XPAR_SYSMON_0_DEVICE_ID

static XSysMon SysMonInst;
XSysMon_Config *SysMonConfigPtr;
XSysMon *SysMonInstPtr = &SysMonInst;

// Function to get number of set bits in binary digits
int count_set_bits(unsigned int n)
{
  unsigned int count = 0;
  while(n){
    count += n & 0x1;
    n >>= 1;
  }
  return count;
}

int main(void)
{
    u32 cmd, data_channels, delay;
    u32 xStatus, num_channels;
    int i, log_capacity;
    u32 xadc_raw_value;

    // SysMon Initialize
    SysMonConfigPtr = XSysMon_LookupConfig(SYSMON_DEVICE_ID);
    if(SysMonConfigPtr == NULL)
        xil_printf("SysMon LookupConfig failed.\n\r");
    xStatus = XSysMon_CfgInitialize(SysMonInstPtr, SysMonConfigPtr,
                                    SysMonConfigPtr->BaseAddress);
    if(XST_SUCCESS != xStatus)
        xil_printf("SysMon CfgInitialize failed\r\n");
    // Clear the old status
    XSysMon_GetStatus(SysMonInstPtr);

    while(1){
        // wait and store valid command
        while((MAILBOX_CMD_ADDR & 0x1)==0);
        cmd = (MAILBOX_CMD_ADDR & 0xF);

        switch(cmd){
            case CONFIG_IOP_SWITCH:
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case GET_RAW_DATA:
                i=0;
                // Wait for the conversion complete
                while ((XSysMon_GetStatus(SysMonInstPtr) & 
                        XSM_SR_EOS_MASK) != XSM_SR_EOS_MASK);
                data_channels = MAILBOX_CMD_ADDR >> 8;
                if(data_channels & 0x1)
                    MAILBOX_DATA(i++) = XSysMon_GetAdcData(SysMonInstPtr,
                                            XSM_CH_AUX_MIN+1);
                if(data_channels & 0x2)
                    MAILBOX_DATA(i++) = XSysMon_GetAdcData(SysMonInstPtr,
                                            XSM_CH_AUX_MIN+9);
                if(data_channels & 0x4)
                    MAILBOX_DATA(i++) = XSysMon_GetAdcData(SysMonInstPtr,
                                            XSM_CH_AUX_MIN+6);
                if(data_channels & 0x8)
                    MAILBOX_DATA(i++) = XSysMon_GetAdcData(SysMonInstPtr,
                                            XSM_CH_AUX_MIN+15);
                if(data_channels & 0x10)
                    MAILBOX_DATA(i++) = XSysMon_GetAdcData(SysMonInstPtr,
                                            XSM_CH_AUX_MIN+5);
                if(data_channels & 0x20)
                    MAILBOX_DATA(i++) = XSysMon_GetAdcData(SysMonInstPtr,
                                            XSM_CH_AUX_MIN+13);
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case READ_AND_LOG_RAW:
                // initialize logging variables, reset cmd
                delay = MAILBOX_DATA(1);
                // get channels to be sampled
                data_channels = MAILBOX_CMD_ADDR >> 8;
                num_channels = count_set_bits(data_channels);
                // allocate as many samples per channel as possible
                log_capacity = ((u32)(MAX_SAMPLES/num_channels)) * num_channels;
                cb_init(&circular_log, LOG_BASE_ADDRESS, 
                        log_capacity, LOG_INT_SIZE, num_channels);
                while(MAILBOX_CMD_ADDR != RESET_ANALOG){
                    // wait for sample conversion
                    while ((XSysMon_GetStatus(SysMonInstPtr) & 
                            XSM_SR_EOS_MASK) != XSM_SR_EOS_MASK);
                            
                    if(data_channels & 0x1) {
                        xadc_raw_value = XSysMon_GetAdcData(SysMonInstPtr,
                                                        XSM_CH_AUX_MIN+1);
                        cb_push_back(&circular_log, &xadc_raw_value);
                    }
                    if(data_channels & 0x2) {
                        xadc_raw_value = XSysMon_GetAdcData(SysMonInstPtr,
                                                        XSM_CH_AUX_MIN+9);
                        cb_push_back(&circular_log, &xadc_raw_value);
                    }
                    if(data_channels & 0x4) {
                        xadc_raw_value = XSysMon_GetAdcData(SysMonInstPtr,
                                                        XSM_CH_AUX_MIN+6);
                        cb_push_back(&circular_log, &xadc_raw_value);
                    }
                    if(data_channels & 0x8) {
                        xadc_raw_value = XSysMon_GetAdcData(SysMonInstPtr,
                                                        XSM_CH_AUX_MIN+15);
                        cb_push_back(&circular_log, &xadc_raw_value);
                    }
                    if(data_channels & 0x10) {
                        xadc_raw_value = XSysMon_GetAdcData(SysMonInstPtr,
                                                        XSM_CH_AUX_MIN+5);
                        cb_push_back(&circular_log, &xadc_raw_value);
                    }
                    if(data_channels & 0x20) {
                        xadc_raw_value = XSysMon_GetAdcData(SysMonInstPtr,
                                                        XSM_CH_AUX_MIN+13);
                        cb_push_back(&circular_log, &xadc_raw_value);
                    }
                    delay_ms(delay);
                }
                MAILBOX_CMD_ADDR = 0x0;
                break;

            case RESET_ANALOG:
                // SysMon Initialize
                SysMonConfigPtr = XSysMon_LookupConfig(SYSMON_DEVICE_ID);
                if(SysMonConfigPtr == NULL)
                    xil_printf("SysMon LookupConfig failed.\n\r");
                xStatus = XSysMon_CfgInitialize(SysMonInstPtr, 
                            SysMonConfigPtr, SysMonConfigPtr->BaseAddress);
                if(XST_SUCCESS != xStatus)
                    xil_printf("SysMon CfgInitialize failed.\r\n");
                // Clear the old status
                XSysMon_GetStatus(SysMonInstPtr);
                MAILBOX_CMD_ADDR = 0x0;
                break;
            
            default:
                MAILBOX_CMD_ADDR = 0x0;
                break;
    }
  }
  return 0;
}
