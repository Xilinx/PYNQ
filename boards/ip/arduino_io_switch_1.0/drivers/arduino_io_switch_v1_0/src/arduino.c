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
 * @file arduino.c
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
 * 1.00a pp  06/09/16 release
 * 1.00b yrq 09/06/16 adjust format
 *
 * </pre>
 *
 *****************************************************************************/
#include "arduino.h"

/*
 * Delay Timer related functions
 * Timer 5, module 2 is used
 */
XTmrCtr TimerInst_5;

void delay_us(int usdelay){
    XTmrCtr_SetResetValue(&TimerInst_5, 1, usdelay*100);
    // Start the timer5 for usdelay us delay
    XTmrCtr_Start(&TimerInst_5, 1);
    // Wait for usdelay us to lapse
    while(!XTmrCtr_IsExpired(&TimerInst_5,1));
    // Stop the timer5
    XTmrCtr_Stop(&TimerInst_5, 1);
}

void delay_ms(int msdelay){
    delay_us(msdelay*1000);
}

int tmrctr_init(void) {
    int Status;

    // specify the device ID
    Status = XTmrCtr_Initialize(&TimerInst_5, 
                    XPAR_IOP3_MB3_TIMERS_SUBSYSTEM_MB3_TIMER_5_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XTmrCtr_SetOptions(&TimerInst_5, 1, 
        XTC_AUTO_RELOAD_OPTION | XTC_CSR_LOAD_MASK | XTC_CSR_DOWN_COUNT_MASK);
    return 0;
}

// SPI related functions
void spi_transfer(u32 BaseAddress, int bytecount,
                  u8* readBuffer, u8* writeBuffer) {
    int i;

    XSpi_WriteReg(BaseAddress,XSP_SSR_OFFSET, 0xfe);
    for (i=0; i<bytecount; i++){
        XSpi_WriteReg(BaseAddress,XSP_DTR_OFFSET, writeBuffer[i]);
    }
    while(((XSpi_ReadReg(BaseAddress,XSP_SR_OFFSET) & 0x04)) != 0x04);
    // delay for about 100 ns
    XTmrCtr_SetResetValue(&TimerInst_5, 1, 10);
    // Start the timer5
    XTmrCtr_Start(&TimerInst_5, 1);
    // Wait for the delay to lapse
    while(!XTmrCtr_IsExpired(&TimerInst_5,1));
    // Stop the timer5
    XTmrCtr_Stop(&TimerInst_5, 1);

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

// IIC related functions
int iic_read(u32 iic_baseaddr, u32 addr, u8* buffer, u8 numbytes){
    XIic_Recv(iic_baseaddr, addr, buffer, numbytes, XIIC_STOP);
    return 0;
}


int iic_write(u32 iic_baseaddr, u32 addr, u8* buffer, u8 numbytes){
       XIic_Send(iic_baseaddr, addr, buffer, numbytes, XIIC_STOP);
       return 0;
}

// Circular buffer related functions
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

/*
 *  Switch Configuration
 *  Configuration is done by writing four 32 bit values to the switch.
 *  The 32-bit values represent as follows:
 *  Arduino Analog pin 0 = bits [1:0] -- register 0
 *  Arduino Analog pin 1 = bits [3:2]
 *  Arduino Analog pin 2 = bits [5:4]
 *  Arduino Analog pin 3 = bits [7:6]
 *  Arduino Analog pin 4 = bits [9:8]
 *  Arduino Analog pin 5 = bits [11:10]
 *  Arduino Digital pins 1 and 0 = bit [31]
 *  Arduino Digital pin 2 = bits [3:0] -- register 1
 *  Arduino Digital pin 3 = bits [7:4]
 *  Arduino Digital pin 4 = bits [11:8]
 *  Arduino Digital pin 5 = bits [15:12]
 *  Arduino Digital pin 6 = bits [3:0] -- register 2
 *  Arduino Digital pin 7 = bits [7:4]
 *  Arduino Digital pin 8 = bits [11:8]
 *  Arduino Digital pin 9 = bits [15:12]
 *  Arduino Digital pin 10 = bits [3:0] -- register 3
 *  Arduino Digital pin 11 = bits [7:4]
 *  Arduino Digital pin 12 = bits [11:8]
 *  Arduino Digital pin 13 = bits [15:12]
 */
void config_arduino_switch(char A_pin0, char A_pin1, char A_pin2, 
                           char A_pin3, char A_pin4, char A_pin5, 
                           char D_pin0_1,
                           char D_pin2, char D_pin3, char D_pin4, 
                           char D_pin5, char D_pin6, char D_pin7, 
                           char D_pin8, char D_pin9, char D_pin10, 
                           char D_pin11, char D_pin12, char D_pin13){
   u32 switchConfigValue0, switchConfigValue1;
   u32 switchConfigValue2, switchConfigValue3;

   // Calculate switch configuration values
   switchConfigValue0 = (D_pin0_1<<31)|(A_pin5<<10)|(A_pin4<<8)|\
                        (A_pin3<<6)|(A_pin2<<4)|(A_pin1<<2)|(A_pin0);
   switchConfigValue1 = (D_pin5<<12)|(D_pin4<<8)|(D_pin3<<4)|(D_pin2);
   switchConfigValue2 = (D_pin9<<12)|(D_pin8<<8)|(D_pin7<<4)|(D_pin6);
   switchConfigValue3 = (D_pin13<<12)|(D_pin12<<8)|(D_pin11<<4)|(D_pin10);

   // Set pin configuration
   Xil_Out32(SWITCH_BASEADDR, switchConfigValue0);
   Xil_Out32(SWITCH_BASEADDR+4, switchConfigValue1);
   Xil_Out32(SWITCH_BASEADDR+8, switchConfigValue2);
   Xil_Out32(SWITCH_BASEADDR+0xc, switchConfigValue3);
}

void arduino_init(u32 shared_clk_phase, u32 shared_clk_polarity, 
                  u32 direct_clk_phase, u32 direct_clk_polarity) {
    spi_init(SHARED_SPI_BASEADDR, shared_clk_phase, shared_clk_polarity);
    spi_init(DIRECT_SPI_BASEADDR, direct_clk_phase, direct_clk_polarity);
    tmrctr_init();
}
