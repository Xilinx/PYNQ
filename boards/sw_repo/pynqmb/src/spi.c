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
 * @file spi.c
 *
 * Implementing SPI related functions for PYNQ Microblaze, 
 * including the SPI initialization and transfer.
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
#include "spi.h"

/************************** Function Definitions ***************************/
void spi_init(u32 BaseAddress, u32 clk_phase, u32 clk_polarity){
    u32 Control;

    // Soft reset SPI
    XSpi_WriteReg(BaseAddress, XSP_SRR_OFFSET, 0xA);
    // Master mode
    Control = XSpi_ReadReg(BaseAddress, XSP_CR_OFFSET);
    // Master Mode
    Control |= XSP_CR_MASTER_MODE_MASK;
    // Enable SPI
    Control |= XSP_CR_ENABLE_MASK;
    // Slave select manually
    Control |= XSP_INTR_SLAVE_MODE_MASK;
    // Enable Transmitter
    Control &= ~XSP_CR_TRANS_INHIBIT_MASK;
    // XSP_CR_CLK_PHASE_MASK
    if(clk_phase)
        Control |= XSP_CR_CLK_PHASE_MASK;
    // XSP_CR_CLK_POLARITY_MASK
    if(clk_polarity)
        Control |= XSP_CR_CLK_POLARITY_MASK;
    XSpi_WriteReg(BaseAddress, XSP_CR_OFFSET, Control);
}

void spi_transfer(u32 BaseAddress, int bytecount,
                  u8* readBuffer, u8* writeBuffer, 
                  XTmrCtr* TmrInstancePtr) {
    int i;

    XSpi_WriteReg(BaseAddress, XSP_SSR_OFFSET, 0xfe);
    for (i=0; i<bytecount; i++){
        XSpi_WriteReg(BaseAddress, XSP_DTR_OFFSET, writeBuffer[i]);
    }
    while(((XSpi_ReadReg(BaseAddress, XSP_SR_OFFSET) & 0x04)) != 0x04);
    // delay for about 100 ns
    XTmrCtr_SetResetValue(TmrInstancePtr, 1, 10);
    // Start the timer5
    XTmrCtr_Start(TmrInstancePtr, 1);
    // Wait for the delay to lapse
    while(!XTmrCtr_IsExpired(TmrInstancePtr, 1));
    // Stop the timer5
    XTmrCtr_Stop(TmrInstancePtr, 1);

    // Read SPI
    for(i=0;i< bytecount; i++){
       readBuffer[i] = XSpi_ReadReg(BaseAddress, XSP_DRR_OFFSET);
    }
    XSpi_WriteReg(BaseAddress, XSP_SSR_OFFSET, 0xff);
}
