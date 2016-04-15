/*
 * pmod.h
 * Common header file for all PMOD IOP applications
 * API and drivers for IIC, SPI
 * Includes address mappings, and API for GPIO, SPI and IIC,
 * IOP Switch pin mappings and configuration
 * 
 * 
 * Author: cmccabe
 * Version 1.0 19 Nov 2015
 *
 *
 */

#ifndef PMOD_H_
#define PMOD_H_

#include "xparameters.h"
#include "xspi.h"      /* SPI device driver */
#include "xspi_l.h"

// Memory map
#define IIC_BASEADDR      XPAR_MB_1_MB_1_AXI_IIC_0_BASEADDR
#define SPI_BASEADDR      XPAR_SPI_0_BASEADDR // base address of QSPI[0]
#define SWITCH_BASEADDR   XPAR_MB_1_MB1_SWITCH_S00_AXI_BASEADDR // Base address of switch
#define GPIO              XPAR_GPIO_0_BASEADDR

#define MAILBOX_CMD_ADDR    (*(volatile unsigned *)(0x00007FFC)) // command from A9 to MB
#define MAILBOX_DATA(x)    (*(volatile unsigned *)(0x00007000 +((x)*4))) // Data from A9 to MB

// Switch mappings used for IOP Switch configuration
#define GPIO_0 0x0
#define GPIO_1 0x1
#define GPIO_2 0x2
#define GPIO_3 0x3
#define GPIO_4 0x4
#define GPIO_5 0x5
#define GPIO_6 0x6
#define GPIO_7 0x7
#define SCL    0x8
#define SDA    0x9
#define SPICLK 0xa
#define MISO   0xb
#define MOSI   0xc
#define SS     0xd
#define BLANK  0xe

// SPI API
// Predefined Control signals macros found in xspi_l.h
#define SPI_INHIBIT (XSP_CR_TRANS_INHIBIT_MASK|XSP_CR_MANUAL_SS_MASK|XSP_CR_ENABLE_MASK|XSP_CR_MASTER_MODE_MASK)
#define SPI_RELEASE (XSP_CR_MANUAL_SS_MASK|XSP_CR_MASTER_MODE_MASK|XSP_CR_ENABLE_MASK)

void SpiInit(void);
void spi_transfer(u32 BaseAddress, u8 numBytes, u8* readData, u8* writeData);

// IIC API
u32 iic_read(u32 sel); 
void iic_write(u32 sel, u8 data);

void delay_ms(u32 ms_count);
void delay(void);

// Switch Configuration
void configureSwitch(char pin1, char pin2, char pin3, char pin4, char pin5, char pin6, char pin7, char pin8);

#endif /* PMOD_H_ */
