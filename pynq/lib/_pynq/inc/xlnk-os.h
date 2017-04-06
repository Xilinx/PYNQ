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
 * @file xlnk-os.h
 *
 * Libraries for xlnk driver.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a gn  01/26/16 release
 * 1.00b yrq 08/31/16 add license header
 *
 * </pre>
 *
 *****************************************************************************/
 
#ifndef _XLNK_OS_H
#define _XLNK_OS_H

#include <stddef.h>

#define XLNK_FLAG_COHERENT          0x00000001
#define XLNK_FLAG_KERNEL_BUFFER     0x00000002
#define XLNK_FLAG_DMAPOLLING        0x00000004
#define XLNK_FLAG_PHYSICAL_ADDR     0x00000100
#define XLNK_FLAG_VIRTUAL_ADDR      0x00000200

#define CF_FLAG_CACHE_FLUSH_INVALIDATE 0x00000001
#define CF_FLAG_PHYSICALLY_CONTIGUOUS  0x00000002
#define CF_FLAG_DMAPOLLING             0x00000004

typedef unsigned long xlnk_handle_t;

enum xlnk_dma_direction {
    XLNK_DMA_BI = 0,
    XLNK_DMA_TO_DEVICE = 1,
    XLNK_DMA_FROM_DEVICE = 2,
    XLNK_DMA_NONE = 3,
};

struct dmabuf_args {
    int dmabuf_fd;
    void *user_addr;
};

typedef union {
    struct {
        unsigned int len;
        unsigned int *idptr;
                unsigned int *phyaddrptr;
        unsigned int cacheable;
    } allocbuf;
    struct {
        unsigned int id;
        void *buf;
    } freebuf;
    struct {
        int dmabuf_fd;
        void *user_addr;
    } dmabuf;
    struct {
        char name[64]; /* max length of 64 */
        xlnk_handle_t dmachan; /* return value */
        unsigned int bd_space_phys_addr;/*for bd chain used by dmachan*/
        unsigned int bd_space_size; /* bd chain size in bytes */
    } dmarequest;
#define XLNK_MAX_APPWORDS 5
    struct {
        xlnk_handle_t dmachan;
        void *buf;      /* buffer base address */
        void *buf2; /* used to point src_buf in cdma case */
                unsigned int buf_offset; /* used on kernel allocated buffers */
        unsigned int len;
        unsigned int bufflag; /* zero all the time so far */
        xlnk_handle_t sglist; /* ignored */
        unsigned int sgcnt; /* ignored */
        enum xlnk_dma_direction dmadir;
        unsigned int nappwords_i; /* n appwords passed to BD */
        unsigned int appwords_i[XLNK_MAX_APPWORDS];
        unsigned int nappwords_o; /* n appwords passed from BD */
        /* appwords array we only accept 5 max */
        unsigned int flag;
        xlnk_handle_t dmahandle; /* return value */
        unsigned int last_bd_index; /*index of last bd used by request*/
    } dmasubmit;
    struct {
        xlnk_handle_t dmahandle;
        unsigned int nappwords; /* n appwords read from BD */
        unsigned int appwords[XLNK_MAX_APPWORDS];
        /* appwords array we only accept 5 max */
    } dmawait;
    struct {
        xlnk_handle_t dmachan;
    } dmarelease;
    struct {
        unsigned long base;
        unsigned int size;
        unsigned int irqs[8];
        char name[32];
        unsigned int id;
    } devregister;
    struct {
        unsigned int base;
    } devunregister;
    struct {
        char name[32];
        unsigned int id;
        unsigned long base;
        unsigned int size;
        unsigned int chan_num;
        unsigned int chan0_dir;
        unsigned int chan0_irq;
        unsigned int chan0_poll_mode;
        unsigned int chan0_include_dre;
        unsigned int chan0_data_width;
        unsigned int chan1_dir;
        unsigned int chan1_irq;
        unsigned int chan1_poll_mode;
        unsigned int chan1_include_dre;
        unsigned int chan1_data_width;
    } dmaregister;
    struct {
        char name[32];
        unsigned int id;
        unsigned long base;
        unsigned int size;
        unsigned int mm2s_chan_num;
        unsigned int mm2s_chan_irq;
        unsigned int s2mm_chan_num;
        unsigned int s2mm_chan_irq;
    } mcdmaregister;
    struct {
        void *phys_addr;
        int size;
        int action;
    } cachecontrol;
} xlnk_args;


#endif