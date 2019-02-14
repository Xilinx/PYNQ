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
 * @file circular_buffer.h
 *
 * Header file for circular buffer on PYNQ Microblaze. 
 * The circular buffer allows data recording of indefinite length.
 *
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00  yrq 01/09/18 release
 *
 * </pre>
 *
 *****************************************************************************/
#ifndef _CIRCULAR_BUFFER_H_
#define _CIRCULAR_BUFFER_H_
#ifdef __cplusplus 
extern "C" {
#endif
#include <xparameters.h>
#include "xil_types.h"

#define MAILBOX_CMD_ADDR       (*(volatile u32 *)(0x0000FFFC))
#define MAILBOX_DATA(x)        (*(volatile u32 *)(0x0000F000 +((x)*4)))
#define MAILBOX_DATA_PTR(x)    ( (volatile u32 *)(0x0000F000 +((x)*4)))
#define MAILBOX_DATA_FLOAT(x)     (*(volatile float *)(0x0000F000 +((x)*4)))
#define MAILBOX_DATA_FLOAT_PTR(x) ( (volatile float *)(0x0000F000 +((x)*4)))

/*
 * Logging API
 * Using mailbox as a circular buffer
 * Modified to match mailbox API
 */
typedef struct circular_buffer
{
  volatile void *buffer;     // data buffer
  void *buffer_end;          // end of data buffer
  size_t capacity;           // maximum number of items in the buffer
  size_t count;              // number of items in the buffer
  size_t sz;                 // size of each item in the buffer
  volatile void *head;       // pointer to head
  volatile void *tail;       // pointer to tail
} circular_buffer;

circular_buffer circular_log;

int cb_init(circular_buffer *cb, volatile u32* log_start_addr,
            size_t capacity, size_t sz);
void cb_push_back(circular_buffer *cb, const void *item);
void cb_push_back_float(circular_buffer *cb, const float *item);
void cb_push_incr_ptrs(circular_buffer *cb);

#ifdef __cplusplus 
}
#endif
#endif  // _CIRCULAR_BUFFER_H_
