/*
 * PMOD API functions
 * IIC, SPI, and IOP switch configuration functions
 * 
 * Author: cmccabe
 * Version 1.0 19 Nov 2015
 *
 */

#include "pmod.h"

void spi_transfer(u32 BaseAddress, u8 numBytes, u8* readData, u8* writeData) {
	u8 i; // Byte counter

	Xil_Out32(BaseAddress+XSP_SSR_OFFSET, 0xfe); // CS Low
	Xil_Out32(BaseAddress+XSP_CR_OFFSET, SPI_INHIBIT ); // Disable transactions (inhibit master)

	// Write SPI
    for(i=0;i< numBytes; i++){
		Xil_Out32(BaseAddress+XSP_DTR_OFFSET, writeData[i]);  // Data Transfer Register (FIFO)
	}

	Xil_Out32(BaseAddress+XSP_CR_OFFSET, SPI_RELEASE); 	// Enable transactions

	while(((Xil_In32(BaseAddress+XSP_SR_OFFSET) & 0x04)) != 0x04);
	delay();

	// Read SPI
	for(i=0;i< numBytes; i++){
		readData[i] = Xil_In32(BaseAddress+XSP_DRR_OFFSET); // Data Read Register (FIFO)
	}
	Xil_Out32(BaseAddress+XSP_SSR_OFFSET, 0xff);	// CS de-select

}

void SpiInit(void) {
	u32 Control;

	// Reset SPI
	XSpi_WriteReg(SPI_BASEADDR, XSP_SRR_OFFSET, 0xa);
	// Master mode
	Control = Xil_In32(SPI_BASEADDR+XSP_CR_OFFSET);
	Control |= XSP_CR_MASTER_MODE_MASK; // Master Mode
	Control |= XSP_CR_ENABLE_MASK; // Enable SPI
	Control |= XSP_INTR_SLAVE_MODE_MASK; // Slave select manually
	Control |= XSP_CR_TRANS_INHIBIT_MASK; // Disable Transmitter
	Xil_Out32(SPI_BASEADDR+XSP_CR_OFFSET, Control);
}


u32 iic_read(u32 sel) // , u32 display)
{
    u32 rdata;
    // Set RX FIFO Depth to 3 bytes
    Xil_Out32((IIC_BASEADDR + 0x120), 0x03);
    
    // Reset TX FIFO
    Xil_Out32((IIC_BASEADDR + 0x100), 0x002);
    
    // Enable IIC Core
    Xil_Out32((IIC_BASEADDR + 0x100), 0x001);
    
    // Transmit 7-bit address and Read bit
    Xil_Out32((IIC_BASEADDR + 0x108), (0x101 | sel << 1));
    
    // Program IIC Core to read 2 bytes
    // and issue a STOP bit afterwards
    Xil_Out32((IIC_BASEADDR + 0x108), 0x202);
    
    // Wait for data to be available in RX FIFO
    while(((IIC_BASEADDR + 0x104) & 0x40) == 1);
    
    // Read data - First byte
    rdata = Xil_In32(IIC_BASEADDR + 0x10c) & 0xff;
    
    // Wait for data to be available in RX FIFO
    while(((IIC_BASEADDR + 0x104) & 0x40) == 1);
    
    // Read data - Second byte
    rdata = (rdata << 8) | (Xil_In32(IIC_BASEADDR + 0x10c) & 0xff);

    delay_ms(10);
    return(rdata);
}

void iic_write(u32 sel, u8 data)
{
	// Reset TX FIFO
    Xil_Out32((IIC_BASEADDR + 0x100), 0x002);
    
    // Enable IIC Core
    Xil_Out32((IIC_BASEADDR + 0x100), 0x001);
    delay_ms(1);
    
    // Transmit 7-bit address and Write bit
    Xil_Out32((IIC_BASEADDR + 0x108), (0x100 | sel << 1));
    
    // Transmit 1 byte of data and issue a STOP bit afterwards
    Xil_Out32((IIC_BASEADDR + 0x108), (0x200 | data));
    
    delay_ms(10);
}

void delay_ms(u32 ms_count)
{
    u32 count;
    for (count = 0; count < ((ms_count * 2500) + 1); count++)
    {
        asm("nop");
    }
}

void delay(void) {
	int i=0;
	for(i=0;i<9;i++);
}

// Switch Configuration
// 8 input chars, each representing the connection for 1 PMOD pin
// Only the least significant 4-bits for each input char is used
//
// Configuration is done by writing a 32 bit value to the switch.
// The 32-bit value represents 8 x 4-bit values concatenated; One 4-bit value to configure each PMOD pin.
// PMOD pin 8 = bits [31:28]
// PMOD pin 7 = bits [27:24]
// PMOD pin 6 = bits [23:20]
// PMOD pin 5 = bits [19:16]
// PMOD pin 4 = bits [15:12]
// PMOD pin 3 = bits [11:8]
// PMOD pin 2 = bits [7:4]
// PMOD pin 1 = bits [3:0]
// e.g. Write GPIO 0 - 7 to PMOD 1-8 => switchConfigValue = 0x76543210
void configureSwitch(char pin1, char pin2, char pin3, char pin4, char pin5, char pin6, char pin7, char pin8){
	u32 switchConfigValue;

	// Calculate switch configuration value
	switchConfigValue = (pin8<<28)|(pin7<<24)|(pin6<<20)|(pin5<<16)|(pin4<<12)|(pin3<<8)|(pin2<<4)|(pin1);

	Xil_Out32(SWITCH_BASEADDR+0x4,0x00000000); // isolate switch by writing 0 to bit 31
	Xil_Out32(SWITCH_BASEADDR, switchConfigValue); // Set pin configuration
	Xil_Out32(SWITCH_BASEADDR+0x4,0x80000000); // Re-enable Swtch by writing 1 to bit 31
}
