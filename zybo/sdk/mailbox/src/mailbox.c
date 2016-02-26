#include "xparameters.h"
#include "xil_types.h"
#include "xil_io.h"

#define XPAR_PMOD_IO_SWITCH_BASEADDR XPAR_MB_1_MB1_SWITCH_S00_AXI_BASEADDR


#define MAILBOX_CMD_ADDR (*(volatile unsigned *)(0x00007FFC)) // command from A9 to MB0
#define MAILBOX_ADDR (*(volatile unsigned *)(0x00007FF8)) // address of MB0
#define MAILBOX_DATA(x) (*(volatile unsigned *)(0x00007F00+((x)*4)))
// Command format
//	bit[0] : MP issued command when 1
// 	bit[2:1] : Data width=> 00 : byte, 01 : half-word, 1x : word
// 	bit[3] : Read/Write=> 0 :  Python requests write, 1 : Python requests read
// 	bit[15:8] :  Data size=> 1 : single read/write (use for register), multiple read/write (use for buffer)
//
// Byte write- 0x00000m01 => m being count ranging from 1 to 253
// Byte read- 0x00000m09
// Half-word write- 0x00000m03
// Half-word read- 0x00000m0B
// Word write- 0x00000m07
// Word read- 0x00000m0F

int main (void)
{
	int cmd, count, i;
  
	/*
    //	Configuring PMOD IO Switch to connect to GPIO
	Xil_Out32(XPAR_PMOD_IO_SWITCH_BASEADDR+0x1c,0x00000000); // isolate configuration port by writing 0 to slv_reg8[31]
	Xil_Out8(XPAR_PMOD_IO_SWITCH_BASEADDR,0x0); // select GPIO bit 0 to pmod bit 0
	Xil_Out8(XPAR_PMOD_IO_SWITCH_BASEADDR+4,0x1); // select GPIO bit 1 to pmod bit 1
	Xil_Out8(XPAR_PMOD_IO_SWITCH_BASEADDR+8,0x2); // select GPIO bit 2 to pmod bit 2
	Xil_Out8(XPAR_PMOD_IO_SWITCH_BASEADDR+0xc,0x3); // select GPIO bit 3 to pmod bit 3 
	Xil_Out8(XPAR_PMOD_IO_SWITCH_BASEADDR+0x10,0x4); // select GPIO bit 4 to pmod bit 4
	Xil_Out8(XPAR_PMOD_IO_SWITCH_BASEADDR+0x14,0x5); // select GPIO bit 5 to pmod bit 5
	Xil_Out8(XPAR_PMOD_IO_SWITCH_BASEADDR+0x18,0x6); // select GPIO bit 6 to pmod bit 6
	Xil_Out32(XPAR_PMOD_IO_SWITCH_BASEADDR+0x1c,0x80000007); // select GPIO bit 7 to pmod bit 7, Also enable configuration

*/

    while(1){
		while((MAILBOX_CMD_ADDR & 0x01)==0);
		cmd=MAILBOX_CMD_ADDR;
		count = (cmd & 0x0000ff00) >> 8;  // count
		if((count==0) || (count>253)) {
			MAILBOX_CMD_ADDR = 0xfffffffe; // clear bit[0] to indicate cmd processed,
										   // set rest to 1s to indicate error in cmd word
			return -1;
		}
		for(i=0; i<count; i++) {
			if (cmd & 0x08) // Python requests read - check bit[3]
			{
				switch ((cmd & 0x06) >> 1) { // use bit[2:1]
					case 0 : MAILBOX_DATA(i) = *(u8 *) MAILBOX_ADDR; break;
					case 1 : MAILBOX_DATA(i) = *(u16 *) MAILBOX_ADDR; break;
					case 2 :
					case 3 : MAILBOX_DATA(i) = *(u32 *) MAILBOX_ADDR; break;
				}
			}
			else // Python issues write
			{
				switch ((cmd & 0x06) >> 1) { // use bit[2:1]
				case 0 : *(u8 *)MAILBOX_ADDR = (u8 *) MAILBOX_DATA(i); break;
				case 1 : *(u16 *)MAILBOX_ADDR = (u16 *) MAILBOX_DATA(i); break;
				case 2 :
				case 3 : *(u32 *)MAILBOX_ADDR = (u32 *)MAILBOX_DATA(i); break;
				}
			}

		}
		MAILBOX_CMD_ADDR = 0x0;
	}
	return 0;
}
