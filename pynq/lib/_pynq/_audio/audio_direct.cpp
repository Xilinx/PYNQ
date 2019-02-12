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
 * @file audio_direct.c
 *
 * Functions to control audio controller.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who          Date     Changes
 * ----- ------------ -------- -----------------------------------------------
 * 1.00a Mihaita Nagy 04/06/12 First release
 * 1.00b beja         08/15/16 Rewritten for Pynq-Z1
 * 1.00c beja         09/07/16 Header added
 * 2.10a Yun Rock Qu  11/10/17 Support for audio codec ADAU1761
 *
 * </pre>
 *
 *****************************************************************************/

#include <stdint.h>
#include "audio_direct.h"

inline static uint32_t Read32(intptr_t addr) {
	return *(volatile uint32_t*)addr;
}

inline static void Write32(intptr_t addr, uint32_t value) {
	*(volatile uint32_t*)addr = value;
}

/******************************************************************************
 * Function to support audio recording without the audio codec controller.
 *
 * @param	BaseAddr is the address of the controller MMIO.
 * @param	BufAddr is the buffer address.
 * @param	nsamples is the number of samples.
 *
 * @return	none.
 *****************************************************************************/
extern "C" void record(unsigned int BaseAddr, unsigned int * BufAddr, 
                       unsigned int nsamples){
    //Auxiliary
    unsigned long u32Temp, i=0;

    //Reset pdm
    Write32(BaseAddr + PDM_RESET_REG, 0x01);
    Write32(BaseAddr + PDM_RESET_REG, 0x00);
    //Reset fifos
    Write32(BaseAddr + PDM_FIFO_CONTROL_REG, 0xC0000000);
    Write32(BaseAddr + PDM_FIFO_CONTROL_REG, 0x00000000);
    //Receive
    Write32(BaseAddr + PDM_TRANSFER_CONTROL_REG, 0x00);
    Write32(BaseAddr + PDM_TRANSFER_CONTROL_REG, 0x05);

    //Sample
    while(i < nsamples){
        u32Temp = ((Read32(BaseAddr + PDM_STATUS_REG)) 
                   >> RX_FIFO_EMPTY) & 0x01;
        if(u32Temp == 0){
            Write32(BaseAddr + PDM_FIFO_CONTROL_REG, 0x00000002);
            Write32(BaseAddr + PDM_FIFO_CONTROL_REG, 0x00000000);
            BufAddr[i] = Read32(BaseAddr + PDM_DATA_OUT_REG);
            i++;
        }
    }

    //Stop
    Write32(BaseAddr + PDM_TRANSFER_CONTROL_REG, 0x02);
}

/******************************************************************************
 * Function to support audio playing without the audio codec controller.
 *
 * @param	BaseAddr is the address of the controller MMIO.
 * @param	BufAddr is the buffer address.
 * @param	nsamples is the number of samples.
 *
 * @return	none.
 *****************************************************************************/
extern "C" void play(unsigned int BaseAddr, unsigned int * BufAddr, 
                     unsigned int nsamples){
    //Auxiliary
    unsigned long u32Temp, u32DWrite, i=0;
    //Reset i2s
    Write32(BaseAddr + PDM_RESET_REG, 0x01);
    Write32(BaseAddr + PDM_RESET_REG, 0x00);
    //Reset fifos
    Write32(BaseAddr + PDM_FIFO_CONTROL_REG, 0xC0000000);
    Write32(BaseAddr + PDM_FIFO_CONTROL_REG, 0x00000000);
    //Transmit
    Write32(BaseAddr + PDM_TRANSFER_CONTROL_REG, 0x00);
    Write32(BaseAddr + PDM_TRANSFER_CONTROL_REG, 0x09);

    //Play
    while(i < nsamples) {
        u32Temp = ((Read32(BaseAddr + PDM_STATUS_REG)) 
                   >> TX_FIFO_FULL) & 0x01;
        if(u32Temp == 0) {
            Write32(BaseAddr + PDM_DATA_IN_REG, BufAddr[i]);
            Write32(BaseAddr + PDM_FIFO_CONTROL_REG, 0x00000001);
            Write32(BaseAddr + PDM_FIFO_CONTROL_REG, 0x00000000);
            i++;
        }
    }
    //Stop/Reset
    Write32(BaseAddr + PDM_TRANSFER_CONTROL_REG, 0x00);
}
