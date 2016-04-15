#include "xil_types.h"
#include "xparameters.h"
#include "xil_io.h"

#define IIC_BASEADDR  XPAR_IIC_0_BASEADDR

void delay_ms(u32 ms_count) 
{
    u32 count;
    for (count = 0; count < ((ms_count * 3000) + 1); count++)
    {
        asm("nop");
    }
}

u32 AD7991_iic_read(u32 sel) // , u32 display)
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

void AD7991_iic_write(u32 sel, u8 data)
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
