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
static XSpi xspi[XPAR_XTMRCTR_NUM_INSTANCES];
/************************** Function Definitions ***************************/
spi spi_open_device(unsigned int device){
    int status;
    u16 dev_id;
    unsigned int base_address;
    u32 control;
    
    dev_id = (u16)device;
#ifdef XPAR_SPI_0_BASEADDR
    if (device == XPAR_SPI_0_BASEADDR){
        dev_id = 0;
    }
#endif
#ifdef XPAR_SPI_1_BASEADDR
    if (device == XPAR_SPI_1_BASEADDR){
        dev_id = 1;
    }
#endif

    status = XSpi_Initialize(&xspi[dev_id], dev_id);
    if (status != XST_SUCCESS) {
        return -1;
    }
    base_address = xspi[dev_id].BaseAddr;
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

    return (spi)dev_id;
}


#ifdef XPAR_IO_SWITCH_NUM_INSTANCES
#ifdef XPAR_IO_SWITCH_0_SPI0_BASEADDR
spi spi_open(unsigned int spiclk, unsigned int miso, 
             unsigned int mosi, unsigned int ss){
    set_pin(spiclk, SPICLK0);
    set_pin(miso, MISO0);
    set_pin(mosi, MOSI0);
    set_pin(ss, SS0);
    return spi_open_device(XPAR_IO_SWITCH_0_SPI0_BASEADDR);
}
#endif
#endif


spi spi_configure(spi dev_id, unsigned int clk_phase, 
                   unsigned int clk_polarity){
    u32 control;
    unsigned int base_address = xspi[dev_id].BaseAddr;
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
    return dev_id;
}


void spi_transfer(spi dev_id, const char* write_data, char* read_data, 
                  unsigned int length){
    unsigned int i;
    unsigned volatile char j;
    unsigned int base_address = xspi[dev_id].BaseAddr;

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


void spi_close(spi dev_id){
    XSpi_ClearStats(&xspi[dev_id]);
}

#endif
