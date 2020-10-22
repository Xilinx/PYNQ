/******************************************************************************
 *  Copyright (c) 2018-2020, Xilinx, Inc.
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
 * @file circular_buffer.c
 *
 * Implementing circular buffer on PYNQ Microblaze. 
 * The circular buffer allows data recording of indefinite length.
 *
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00  yrq 01/09/18 release
 * 1.01  mrn 09/28/20 Bug fix, the head of the circular 
 *                    buffer did not overflow
 * 1.02  mrn 10/11/20 Update initialize function. Bug fix: move the head 
 *                    according to the number of channels.
 *
 * </pre>
 *
 *****************************************************************************/
#include "circular_buffer.h"

/************************** Function Definitions ***************************/
int cb_init(circular_buffer *cb, volatile u32* log_start_addr,
            size_t capacity, size_t sz, size_t channels){
    cb->buffer = (volatile char*) log_start_addr;
    if(cb->buffer == NULL)
        return -1;
    cb->buffer_end = (char *)cb->buffer + capacity * sz;
    cb->capacity = capacity;
    cb->sz = sz;
    cb->channels = channels;
    cb->head = cb->buffer;
    cb->tail = cb->buffer;

    // initialize mailbox
    MAILBOX_DATA(0)  = 0xffffffff;
    MAILBOX_DATA(2)  = (u32) cb->head;
    MAILBOX_DATA(3)  = (u32) cb->tail;

    return 0;
}


void cb_push_back(circular_buffer *cb, const void *item){
    // update data
    u8 i;
    u8* tail_ptr = (u8*) cb->tail;
    u8* item_ptr = (u8*) item;
    for(i=0;i<cb->sz;i++){
        tail_ptr[i] = item_ptr[i];
    }
    cb_push_incr_ptrs(cb);

    // update mailbox data
    MAILBOX_DATA(0)  = (u32) item;
}


void cb_push_back_float(circular_buffer *cb, const float *item){
    // update data 
    float* tail_ptr = (float*) cb->tail;
    *tail_ptr = *item;
    cb_push_incr_ptrs(cb);

    // update mailbox data
    MAILBOX_DATA_FLOAT(0)  = *item;
}


void cb_push_incr_ptrs(circular_buffer *cb){
    // update pointers
    cb->tail = (char*)cb->tail + cb->sz;
    if (cb->tail >= cb->buffer_end)
        cb->tail = cb->buffer;

    if (cb->tail == cb->head) {
        cb->head  = (char*)cb->head + cb->sz * cb->channels;
        // Move the head pointer to buffer start
        if (cb->head >= cb->buffer_end)
            cb->head = cb->buffer;
    }
    // update mailbox head and tail
    MAILBOX_DATA(2) = (u32) cb->head;
    MAILBOX_DATA(3) = (u32) cb->tail;
}
