/*
 * PMOD API functions
 * IIC, SPI, and IOP switch configuration functions
 * 
 * Author: cmccabe
 * Version 1.0 19 Nov 2015
 *
 */

#include "pmod.h"
XTmrCtr TimerInst_0; 	// The Timer Counter instance

void spi_delay(void) {
	int i=0;
	for(i=0;i<7;i++);
}

void spi_transfer(u32 BaseAddress, int bytecount, u8* readBuffer, u8* writeBuffer) {
	int i;

	XSpi_WriteReg(BaseAddress,XSP_CR_OFFSET,0x18e);
	XSpi_WriteReg(BaseAddress,XSP_SSR_OFFSET, 0xfe);
	for (i=0; i<bytecount; i++)
	{
		XSpi_WriteReg(BaseAddress,XSP_DTR_OFFSET, writeBuffer[i]);
	}
	XSpi_WriteReg(BaseAddress,XSP_CR_OFFSET,0x08e);
	while(((XSpi_ReadReg(BaseAddress,XSP_SR_OFFSET) & 0x04)) != 0x04);
	spi_delay();
	// Slave de-select
	XSpi_WriteReg(BaseAddress,XSP_SSR_OFFSET, 0xff);
    
    // Read SPI
    for(i=0;i< bytecount; i++){
       readBuffer[i] = XSpi_ReadReg(BaseAddress,XSP_DRR_OFFSET);
    }
    XSpi_WriteReg(BaseAddress, XSP_SSR_OFFSET, 0xff);
}

void spi_init(void) {
	u32 Control;

	// Soft reset SPI
	XSpi_WriteReg(SPI_BASEADDR, XSP_SRR_OFFSET, 0xa);
	// Master mode
	Control = XSpi_ReadReg(SPI_BASEADDR, XSP_CR_OFFSET);
	Control |= XSP_CR_MASTER_MODE_MASK; // Master Mode
	Control |= XSP_CR_ENABLE_MASK; // Enable SPI
	Control |= XSP_INTR_SLAVE_MODE_MASK; // Slave select manually
	Control |= XSP_CR_TRANS_INHIBIT_MASK; // Disable Transmitter
	XSpi_WriteReg(SPI_BASEADDR, XSP_CR_OFFSET, Control);
}

int iic_read(u32 addr, u8* buffer, u8 numbytes) 
{
    XIic_Recv(IIC_BASEADDR, addr, buffer, numbytes, XIIC_STOP);
    return 0;
}


int iic_write(u32 addr, u8* buffer, u8 numbytes)
{

	   XIic_Send(IIC_BASEADDR, addr, buffer, numbytes, XIIC_STOP);
	   return 0;
}

#if 0
int iic_init(u8 IicSlaveAddr) {
	XIic_Config *ConfigPtr;
	int Status;

	// Initialize the SPI driver so that it is  ready to use.
	ConfigPtr = XIic_LookupConfig(XPAR_IIC_0_DEVICE_ID);
	if (ConfigPtr == NULL) {
		return XST_DEVICE_NOT_FOUND;
	}

	Status = XIic_CfgInitialize(&IicInstance, ConfigPtr,
				  ConfigPtr->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = XIic_Start(&IicInstance);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = XIic_SetAddress(&IicInstance, XII_ADDR_TO_SEND_TYPE, IicSlaveAddr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	return 0;

}
#endif

int cb_init(circular_buffer *cb, volatile u32* log_start_addr, size_t capacity, size_t sz)
{
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

void cb_push_back(circular_buffer *cb, const void *item)
{

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

void cb_push_back_float(circular_buffer *cb, const float *item)
{

  // update data 
  float* tail_ptr = (float*) cb->tail;
  *tail_ptr = *item;
  
  cb_push_incr_ptrs(cb);

  // Mailbox API Update
  MAILBOX_DATA_FLOAT(0)  = *item;

}

void cb_push_incr_ptrs(circular_buffer *cb){

  // update pointers
  cb->tail = (char*)cb->tail + cb->sz;
  if(cb->tail >= cb->buffer_end)
    cb->tail = cb->buffer;

  if((cb->tail == cb->head) ) {
    cb->head  = (char*)cb->head + cb->sz;
  }

  // update mailbox API
  MAILBOX_DATA(2)        = (u32) cb->head;
  MAILBOX_DATA(3)        = (u32) cb->tail;
}

void delay_us(int usdelay) {
	XTmrCtr_SetResetValue(&TimerInst_0, 1, usdelay*100);	// us delay
	XTmrCtr_Start(&TimerInst_0, 1); // start the timer0 for usdelay us delay
    while(!XTmrCtr_IsExpired(&TimerInst_0,1)); // wait for usdelay us to lapse
	XTmrCtr_Stop(&TimerInst_0, 1); // stop the timer0
}

void delay_ms(u32 msdelay)
{
	XTmrCtr_SetResetValue(&TimerInst_0, 1, msdelay*100*1000);	// ms delay
	XTmrCtr_Start(&TimerInst_0, 1); // start the timer0 for usdelay us delay
    while(!XTmrCtr_IsExpired(&TimerInst_0,1)); // wait for usdelay us to lapse
	XTmrCtr_Stop(&TimerInst_0, 1); // stop the timer0
}

/*
 * Switch Configuration
 * 8 input chars, each representing the connection for 1 PMOD pin
 * Only the least significant 4-bits for each input char is used
 *
 * Configuration is done by writing a 32 bit value to the switch.
 * The 32-bit value represents 8 x 4-bit values concatenated; One 4-bit value to configure each PMOD pin.
 * PMOD pin 8 = bits [31:28]
 * PMOD pin 7 = bits [27:24]
 * PMOD pin 6 = bits [23:20]
 * PMOD pin 5 = bits [19:16]
 * PMOD pin 4 = bits [15:12]
 * PMOD pin 3 = bits [11:8]
 * PMOD pin 2 = bits [7:4]
 * PMOD pin 1 = bits [3:0]
 * e.g. Write GPIO 0 - 7 to PMOD 1-8 => switchConfigValue = 0x76543210
 */
void configureSwitch(char pin1, char pin2, char pin3, char pin4, char pin5, char pin6, char pin7, char pin8){
   u32 switchConfigValue;

   // Calculate switch configuration value
   switchConfigValue = (pin8<<28)|(pin7<<24)|(pin6<<20)|(pin5<<16)|(pin4<<12)|(pin3<<8)|(pin2<<4)|(pin1);

   Xil_Out32(SWITCH_BASEADDR+0x4,0x00000000); // isolate switch by writing 0 to bit 31
   Xil_Out32(SWITCH_BASEADDR, switchConfigValue); // Set pin configuration
   Xil_Out32(SWITCH_BASEADDR+0x4,0x80000000); // Re-enable Swtch by writing 1 to bit 31
}

int tmrctr_init(void) {
	int Status;

	// specify the device ID that is generated in xparameters.h
	Status = XTmrCtr_Initialize(&TimerInst_0, XPAR_TMRCTR_0_DEVICE_ID); // timer 0
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XTmrCtr_SetOptions(&TimerInst_0, 1, XTC_AUTO_RELOAD_OPTION | XTC_CSR_LOAD_MASK | XTC_CSR_DOWN_COUNT_MASK );
	XTmrCtr_Start(&TimerInst_0, 1);

	return 0;

}

void pmod_init(void) {
//#ifdef USE_SPI
	spi_init();
//#endif
	tmrctr_init();
}

