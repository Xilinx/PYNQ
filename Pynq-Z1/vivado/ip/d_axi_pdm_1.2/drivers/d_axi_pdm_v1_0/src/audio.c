/******************************************************************************
 * @file audio.c
 *
 * This file contains the functions needed to test the ZED i2s audio controller.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who          Date     Changes
 * ----- ------------ -------- -----------------------------------------------
 * 1.00a Mihaita Nagy 04/06/12 First release
 *
 * </pre>
 *
 *****************************************************************************/

/***************************** Include Files *********************************/
#include "audio.h"

/************************** Constant Definitions *****************************/
//Base addresses
#define AUDIO_BASE				XPAR_AUDIO_D_AXI_PDM_1_S_AXI_BASEADDR // 0x43C40000
#define DDR_BASE				XPAR_PS7_DDR_0_S_AXI_BASEADDR

//Audio controller registers
enum i2s_regs {
	PDM_RESET_REG				= AUDIO_BASE + 0x00,
	PDM_TRANSFER_CONTROL_REG	= AUDIO_BASE + 0x04,
	PDM_FIFO_CONTROL_REG      	= AUDIO_BASE + 0x08,
	PDM_DATA_IN_REG         	= AUDIO_BASE + 0x0c,
	PDM_DATA_OUT_REG          	= AUDIO_BASE + 0x10,
	PDM_STATUS_REG           	= AUDIO_BASE + 0x14
};

// Audio controller Status Register Flags
enum PDM_STATUS_REG_flags {
	TX_FIFO_EMPTY				= 0,
	TX_FIFO_FULL				= 1,
	RX_FIFO_EMPTY				= 16,
	RX_FIFO_FULL				= 17
};

/******************************************************************************
 * @param	u32MemOffset is the offset in the DDR3 from which the data will be
 * 			stored.
 * @param	u32NrSamples is the number of samples to store.
 *
 * @return	none.
 *****************************************************************************/
void AudioRecord(unsigned long u32MemOffset, unsigned long u32NrSamples) {

	unsigned long u32Temp, u32DRead, i=0;

	Xil_Out32(PDM_RESET_REG, 0x01);//reset pdm
	Xil_Out32(PDM_RESET_REG, 0x00);

	Xil_Out32(PDM_FIFO_CONTROL_REG, 0xC0000000);//reset fifos
	Xil_Out32(PDM_FIFO_CONTROL_REG, 0x00000000);

	Xil_Out32(PDM_TRANSFER_CONTROL_REG, 0x00);
	Xil_Out32(PDM_TRANSFER_CONTROL_REG, 0x05);//receive

	while(i < u32NrSamples){
		u32Temp = ((Xil_In32(PDM_STATUS_REG)) >> RX_FIFO_EMPTY) & 0x01;
		if(u32Temp == 0){
			Xil_Out32(PDM_FIFO_CONTROL_REG, 0x00000002);
			Xil_Out32(PDM_FIFO_CONTROL_REG, 0x00000000);
			u32DRead = Xil_In32(PDM_DATA_OUT_REG);
			Xil_Out32(DDR_BASE + u32MemOffset + i*4, u32DRead);
			i++;
		}
	}
	Xil_Out32(PDM_TRANSFER_CONTROL_REG, 0x02);//stop
}

/******************************************************************************
 * @param	u32MemOffset is the offset in the DDR3 from which the data will be
 * 			transmitted.
 * @param	u32NrSamples is the number of samples to transmit.
 *
 * @return	none.
 *****************************************************************************/
void AudioPlay(unsigned long u32MemOffset, unsigned long u32NrSamples) {

	unsigned long u32Temp, u32DWrite, i=0;

	Xil_Out32(PDM_RESET_REG, 0x01);//reset i2s
	Xil_Out32(PDM_RESET_REG, 0x00);

	Xil_Out32(PDM_FIFO_CONTROL_REG, 0xC0000000);//reset fifos
	Xil_Out32(PDM_FIFO_CONTROL_REG, 0x00000000);

	Xil_Out32(PDM_TRANSFER_CONTROL_REG, 0x00);
	Xil_Out32(PDM_TRANSFER_CONTROL_REG, 0x09);//transmit

	while(i < u32NrSamples) {
		u32Temp = ((Xil_In32(PDM_STATUS_REG)) >> TX_FIFO_FULL) & 0x01;
		if(u32Temp == 0) {
			u32DWrite = Xil_In32(DDR_BASE + u32MemOffset + i*4);
			Xil_Out32(PDM_DATA_IN_REG, u32DWrite);
			Xil_Out32(PDM_FIFO_CONTROL_REG, 0x00000001);
			Xil_Out32(PDM_FIFO_CONTROL_REG, 0x00000000);
			i++;
		}
	}
	Xil_Out32(PDM_TRANSFER_CONTROL_REG, 0x00);//stop/reset
}

