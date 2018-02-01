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
 * 1.01  yrq 01/30/18 add protection macro
 *
 * </pre>
 *
 *****************************************************************************/
#include <xparameters.h>
#include "spi.h"

#ifdef XPAR_XSPI_NUM_INSTANCES
/************************** Function Definitions ***************************/
int spi_open_device(unsigned int device){
    u32 control;
    u16 dev_id;
    int i;
    unsigned int base_address;
    
    dev_id = (u16)device;
    for (i=0; i<(signed)XPAR_XSPI_NUM_INSTANCES; i++){
        if (device == spi_base_address[i]){
            dev_id = (u16)i;
            break;
        }
    }
    base_address = spi_base_address[dev_id];

    // Soft reset SPI
    XSpi_WriteReg(base_address, XSP_SRR_OFFSET, 0xA);
    // Master mode
    control = XSpi_ReadReg(base_address, XSP_CR_OFFSET);
    // Master Mode
    control |= XSP_CR_MASTER_MODE_MASK;
    // Enable SPI
    control |= XSP_CR_ENABLE_MASK;
    // Slave select manually
    control |= XSP_INTR_SLAVE_MODE_MASK;
    // Enable Transmitter
    control &= ~XSP_CR_TRANS_INHIBIT_MASK;
    // Write configuration word
    XSpi_WriteReg(base_address, XSP_CR_OFFSET, control);

    spi_clk_phase[dev_id] = 0;
    spi_clk_polarity[dev_id] = 0;
    spi_fd[dev_id] = (int)dev_id;
    return (int)dev_id;
}


void spi_configure(int spi, unsigned int clk_phase, unsigned int clk_polarity){
    u32 control;
    unsigned int base_address;
    base_address = spi_base_address[spi];

    // Soft reset SPI
    XSpi_WriteReg(base_address, XSP_SRR_OFFSET, 0xA);
    // Master mode
    control = XSpi_ReadReg(base_address, XSP_CR_OFFSET);
    // Master Mode
    control |= XSP_CR_MASTER_MODE_MASK;
    // Enable SPI
    control |= XSP_CR_ENABLE_MASK;
    // Slave select manually
    control |= XSP_INTR_SLAVE_MODE_MASK;
    // Enable Transmitter
    control &= ~XSP_CR_TRANS_INHIBIT_MASK;
    // XSP_CR_CLK_PHASE_MASK
    if(clk_phase){
        control |= XSP_CR_CLK_PHASE_MASK;
    }
    // XSP_CR_CLK_POLARITY_MASK
    if(clk_polarity){
        control |= XSP_CR_CLK_POLARITY_MASK;
    }
    // Write configuration word
    XSpi_WriteReg(base_address, XSP_CR_OFFSET, control);
    // Update clock phase and polarity
    spi_clk_phase[spi] = clk_phase;
    spi_clk_polarity[spi] = clk_polarity;
}


void spi_transfer(int spi, const char* write_data, char* read_data, 
                  unsigned int length){
    unsigned int i;
    unsigned volatile char j;
    unsigned int base_address;
    base_address = spi_base_address[spi];

    XSpi_WriteReg(base_address, XSP_SSR_OFFSET, 0xfe);
    for (i=0; i<length; i++){
        XSpi_WriteReg(base_address, XSP_DTR_OFFSET, write_data[i]);
    }
    while(((XSpi_ReadReg(base_address, XSP_SR_OFFSET) & 0x04)) != 0x04);

    // delay for 10 clock cycles
    j = 10;
    while(j--);

    for(i=0; i<length; i++){
       read_data[i] = XSpi_ReadReg(base_address, XSP_DRR_OFFSET);
    }
    XSpi_WriteReg(base_address, XSP_SSR_OFFSET, 0xff);
}


void spi_close(int spi){
    spi_fd[spi] = -1;
}

#endif
