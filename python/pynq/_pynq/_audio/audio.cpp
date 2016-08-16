#include "xil_io.h"
#include "xil_types.h"


u32 Xil_In32(UINTPTR Addr)
{
	return *(volatile u32 *) Addr;
}

void Xil_Out32(UINTPTR Addr, u32 Value)
{
	volatile u32 *LocalAddr = (u32 *)Addr;
	*LocalAddr = Value;
}


/*****************************************************************************/

extern "C" void _Pynq_record(unsigned int BaseAddr, unsigned int * BufAddr, unsigned int nsamples)
{
	//Audio controller registers
	unsigned int PDM_RESET_REG				= 0x00;
	unsigned int PDM_TRANSFER_CONTROL_REG	= 0x04;
	unsigned int PDM_FIFO_CONTROL_REG      	= 0x08;
	unsigned int PDM_DATA_IN_REG         	= 0x0c;
	unsigned int PDM_DATA_OUT_REG          	= 0x10;
	unsigned int PDM_STATUS_REG           	= 0x14;
	// Audio controller Status Register Flags
	unsigned int TX_FIFO_EMPTY				= 0;
	unsigned int TX_FIFO_FULL				= 1;
	unsigned int RX_FIFO_EMPTY				= 16;
	unsigned int RX_FIFO_FULL				= 17;

	//...
	unsigned long u32Temp, i=0;

	//reset pdm
	Xil_Out32(BaseAddr + PDM_RESET_REG, 0x01);
	Xil_Out32(BaseAddr + PDM_RESET_REG, 0x00);
	//reset fifos
	Xil_Out32(BaseAddr + PDM_FIFO_CONTROL_REG, 0xC0000000);
	Xil_Out32(BaseAddr + PDM_FIFO_CONTROL_REG, 0x00000000);
	//receive
	Xil_Out32(BaseAddr + PDM_TRANSFER_CONTROL_REG, 0x00);
	Xil_Out32(BaseAddr + PDM_TRANSFER_CONTROL_REG, 0x05);

	//sample
	while(i < nsamples){
		u32Temp = ((Xil_In32(BaseAddr + PDM_STATUS_REG)) >> RX_FIFO_EMPTY) & 0x01;
		if(u32Temp == 0){
			Xil_Out32(BaseAddr + PDM_FIFO_CONTROL_REG, 0x00000002);
			Xil_Out32(BaseAddr + PDM_FIFO_CONTROL_REG, 0x00000000);
			BufAddr[i] = Xil_In32(BaseAddr + PDM_DATA_OUT_REG);
			i++;
		}
	}

	//stop
	Xil_Out32(BaseAddr + PDM_TRANSFER_CONTROL_REG, 0x02);
}

/*****************************************************************************/
extern "C" void _Pynq_play(unsigned int BaseAddr, unsigned int * BufAddr, unsigned int nsamples)
{
	//Audio controller registers
	unsigned int PDM_RESET_REG				= 0x00;
	unsigned int PDM_TRANSFER_CONTROL_REG	= 0x04;
	unsigned int PDM_FIFO_CONTROL_REG      	= 0x08;
	unsigned int PDM_DATA_IN_REG         	= 0x0c;
	unsigned int PDM_DATA_OUT_REG          	= 0x10;
	unsigned int PDM_STATUS_REG           	= 0x14;
	// Audio controller Status Register Flags
	unsigned int TX_FIFO_EMPTY				= 0;
	unsigned int TX_FIFO_FULL				= 1;
	unsigned int RX_FIFO_EMPTY				= 16;
	unsigned int RX_FIFO_FULL				= 17;

	//...
	unsigned long u32Temp, u32DWrite, i=0;
	//reset i2s
	Xil_Out32(BaseAddr + PDM_RESET_REG, 0x01);
	Xil_Out32(BaseAddr + PDM_RESET_REG, 0x00);
	//reset fifos
	Xil_Out32(BaseAddr + PDM_FIFO_CONTROL_REG, 0xC0000000);
	Xil_Out32(BaseAddr + PDM_FIFO_CONTROL_REG, 0x00000000);
	//transmit
	Xil_Out32(BaseAddr + PDM_TRANSFER_CONTROL_REG, 0x00);
	Xil_Out32(BaseAddr + PDM_TRANSFER_CONTROL_REG, 0x09);

	//play
	while(i < nsamples) {
		u32Temp = ((Xil_In32(BaseAddr + PDM_STATUS_REG)) >> TX_FIFO_FULL) & 0x01;
		if(u32Temp == 0) {
			Xil_Out32(BaseAddr + PDM_DATA_IN_REG, BufAddr[i]);
			Xil_Out32(BaseAddr + PDM_FIFO_CONTROL_REG, 0x00000001);
			Xil_Out32(BaseAddr + PDM_FIFO_CONTROL_REG, 0x00000000);
			i++;
		}
	}
	//stop/reset
	Xil_Out32(BaseAddr + PDM_TRANSFER_CONTROL_REG, 0x00);
}