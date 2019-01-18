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

/*****************************************************************************/
/**
 *
 * @file audio_direct.h
 *
 *  Library for the audio control block.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who      Date     Changes
 * ----- -------- -------- -----------------------------------------------
 * 1.00a gn       01/24/15 First release
 * 1.00b yrq      08/31/16 Added license header
 * 2.10a yrq      11/10/17 Support for audio codec ADAU1761
 * 
 * </pre>
 *
******************************************************************************/
#ifndef _AUDIO_DIRECT_H_
#define _AUDIO_DIRECT_H_

/*
 * Bare audio controller parameters
 */
enum audio_direct_regs {
    //Audio controller registers
    PDM_RESET_REG               = 0x00,
    PDM_TRANSFER_CONTROL_REG    = 0x04,
    PDM_FIFO_CONTROL_REG        = 0x08,
    PDM_DATA_IN_REG             = 0x0c,
    PDM_DATA_OUT_REG            = 0x10,
    PDM_STATUS_REG              = 0x14,
    //Audio controller Status Register Flags
    TX_FIFO_EMPTY               = 0,
    TX_FIFO_FULL                = 1,
    RX_FIFO_EMPTY               = 16,
    RX_FIFO_FULL                = 17
};

#endif