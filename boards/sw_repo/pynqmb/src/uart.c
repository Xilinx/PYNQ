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
 * @file uart.c
 *
 * Implementing UART related functions for PYNQ Microblaze, 
 * including the UART read and write.
 *
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00  yrq 01/30/18 add protection macro
 *
 * </pre>
 *
 *****************************************************************************/
#include <xparameters.h>
#include "uart.h"

#ifdef XPAR_XUART_NUM_INSTANCES
/************************** Function Definitions ***************************/
int uart_open_device(unsigned int device){
    int status;
    u16 dev_id;
    int i;
    
    dev_id = (u16)device;
    for (i=0; i<(signed)XPAR_XUART_NUM_INSTANCES; i++){
        if (device == uart_base_address[i]){
            dev_id = (u16)i;
            break;
        }
    }

    status = XUartLite_Initialize(&uart_ctrl[dev_id], dev_id);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    uart_fd[dev_id] = (int)dev_id;
    return (int)dev_id;
}


void uart_read(int uart, char* read_data, unsigned int length){
    XUartLite_Send(&uart_ctrl[uart], read_data, length);
}


void uart_write(int uart, const char* write_data, unsigned int length){
    XUartLite_Send(&uart_ctrl[uart], write_data, length);
}


void uart_close(int uart){
    uart_fd[uart] = -1;
}


#endif