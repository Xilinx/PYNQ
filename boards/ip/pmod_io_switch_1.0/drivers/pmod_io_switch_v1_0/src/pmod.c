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
 * @file pmod.c
 *
 * Implementing useful functions, including the IIC read and write, 
 * initialization functions for SPI devices, delay functions, timer setup, 
 * etc.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00a pp  04/29/16 release
 * 1.00a pp  07/05/16 updated to be consistent with arduino io switch driver
 * </pre>
 *
 *****************************************************************************/

#include "pmod.h"

// The Timer Counter instance
XTmrCtr TimerInst_0;

void spi_transfer(u32 BaseAddress, int bytecount, 
                    u8* readBuffer, u8* writeBuffer) {
    int i;

    XSpi_WriteReg(BaseAddress,XSP_SSR_OFFSET, 0xfe); // 0xfe
    for (i=0; i<bytecount; i++)
    {
        XSpi_WriteReg(BaseAddress,XSP_DTR_OFFSET, writeBuffer[i]);
    }
    while(((XSpi_ReadReg(BaseAddress,XSP_SR_OFFSET) & 0x04)) != 0x04);
    // delay for about 100 ns
    XTmrCtr_SetResetValue(&TimerInst_0, 1, 10);
    // Start the timer0
    XTmrCtr_Start(&TimerInst_0, 1);
    // Wait for the delay to lapse
    while(!XTmrCtr_IsExpired(&TimerInst_0,1));
    // Stop the timer0
    XTmrCtr_Stop(&TimerInst_0, 1);
    
    // Read SPI
    for(i=0;i< bytecount; i++){
       readBuffer[i] = XSpi_ReadReg(BaseAddress,XSP_DRR_OFFSET);
    }
    XSpi_WriteReg(BaseAddress, XSP_SSR_OFFSET, 0xff);
}

void spi_init(u32 BaseAddress, u32 clk_phase, u32 clk_polarity){
    u32 Control;

    // Soft reset SPI
    XSpi_WriteReg(BaseAddress, XSP_SRR_OFFSET, 0xa);
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

int iic_read(u32 iic_BaseAddress, u32 addr, u8* buffer, u8 numbytes){
    XIic_Recv(iic_BaseAddress, addr, buffer, numbytes, XIIC_STOP);
    return 0;
}


int iic_write(u32 iic_BaseAddress, u32 addr, u8* buffer, u8 numbytes){
       XIic_Send(iic_BaseAddress, addr, buffer, numbytes, XIIC_STOP);
       return 0;
}

int cb_init(circular_buffer *cb, volatile u32* log_start_addr, 
            size_t capacity, size_t sz){
  cb->buffer = (volatile char*) log_start_addr;
  if(cb->buffer == NULL)
    return -1;
  cb->buffer_end = (char *)cb->buffer + capacity * sz;
  cb->capacity = capacity;
  cb->sz = sz;
  cb->head = cb->buffer;
  cb->tail = cb->buffer; 

  // Mailbox API Initialization
  MAILBOX_DATA(0)  = 0xffffffff;
  MAILBOX_DATA(2)  = (u32) cb->head;
  MAILBOX_DATA(3)  = (u32) cb->tail;
  
  return 0;
}

void cb_push_back(circular_buffer *cb, const void *item){

  u8 i;
  u8* tail_ptr = (u8*) cb->tail;
  u8* item_ptr = (u8*) item;

  // update data 
  for(i=0;i<cb->sz;i++){
    tail_ptr[i] = item_ptr[i]; 
  }

  cb_push_incr_ptrs(cb);

  // Mailbox API Update
  MAILBOX_DATA(0)  = (u32) item;
  MAILBOX_DATA(2)  = (u32) cb->head;
  MAILBOX_DATA(3)  = (u32) cb->tail;
}

void cb_push_back_float(circular_buffer *cb, const float *item){
  // update data 
  float* tail_ptr = (float*) cb->tail;
  *tail_ptr = *item;
  
  cb_push_incr_ptrs(cb);

  // Mailbox API Update
  MAILBOX_DATA_FLOAT(0)  = *item;
}

void cb_push_incr_ptrs(circular_buffer *cb){

  // Update pointers
  cb->tail = (char*)cb->tail + cb->sz;
  if(cb->tail >= cb->buffer_end)
    cb->tail = cb->buffer;

  if((cb->tail == cb->head) ) {
    cb->head  = (char*)cb->head + cb->sz;
  }

  // Update mailbox API
  MAILBOX_DATA(2) = (u32) cb->head;
  MAILBOX_DATA(3) = (u32) cb->tail;
}

void delay_us(int usdelay){
    // us delay
    XTmrCtr_SetResetValue(&TimerInst_0, 1, usdelay*100);
    // Start the timer0 for usdelay us delay
    XTmrCtr_Start(&TimerInst_0, 1);
    // Wait for usdelay us to lapse
    while(!XTmrCtr_IsExpired(&TimerInst_0,1));
    // Stop the timer0
    XTmrCtr_Stop(&TimerInst_0, 1);
}

void delay_ms(u32 msdelay){
    // ms delay
    XTmrCtr_SetResetValue(&TimerInst_0, 1, msdelay*100*1000);
    // Start the timer0 for usdelay us delay
    XTmrCtr_Start(&TimerInst_0, 1);
    // Wait for usdelay us to lapse
    while(!XTmrCtr_IsExpired(&TimerInst_0,1));
    // Stop the timer0
    XTmrCtr_Stop(&TimerInst_0, 1);
}

/*
 * Switch Configuration
 * 8 input chars, each representing the connection for 1 Pmod pin
 * Only the least significant 4-bits for each input char is used
 *
 * Configuration is done by writing a 32 bit value to the switch.
 * The 32-bit value represents 8 x 4-bit values concatenated.
 * One 4-bit value is used to configure each Pmod pin.
 * Pmod pin 8 = bits [31:28]
 * Pmod pin 7 = bits [27:24]
 * Pmod pin 6 = bits [23:20]
 * Pmod pin 5 = bits [19:16]
 * Pmod pin 4 = bits [15:12]
 * Pmod pin 3 = bits [11:8]
 * Pmod pin 2 = bits [7:4]
 * Pmod pin 1 = bits [3:0]
 * e.g. Write GPIO 0 - 7 to Pmod 1-8 => switchConfigValue = 0x76543210
 */
void config_pmod_switch(char pin0, char pin1, char pin2, char pin3, 
                        char pin4, char pin5, char pin6, char pin7){
   u32 switchConfigValue;

   // Calculate switch configuration value
   switchConfigValue = (pin7<<28)|(pin6<<24)|(pin5<<20)|(pin4<<16)|\
                        (pin3<<12)|(pin2<<8)|(pin1<<4)|(pin0);

   // isolate switch by writing 0 to bit 31
   Xil_Out32(SWITCH_BASEADDR+0x4,0x00000000);
   // Set pin configuration
   Xil_Out32(SWITCH_BASEADDR, switchConfigValue);
   // Re-enable Swtch by writing 1 to bit 31
   Xil_Out32(SWITCH_BASEADDR+0x4,0x80000000);
}

int tmrctr_init(void) {
    int Status;

    // specify the device ID that is generated in xparameters.h
    Status = XTmrCtr_Initialize(&TimerInst_0, XPAR_TMRCTR_0_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XTmrCtr_SetOptions(&TimerInst_0, 1, XTC_AUTO_RELOAD_OPTION | \
                            XTC_CSR_LOAD_MASK | XTC_CSR_DOWN_COUNT_MASK);
    XTmrCtr_Start(&TimerInst_0, 1);

    return 0;
}

void pmod_init(u32 clk_phase, u32 clk_polarity) {
    spi_init(SPI_BASEADDR, clk_phase, clk_polarity);
    tmrctr_init();
}
