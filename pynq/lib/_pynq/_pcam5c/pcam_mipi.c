/******************************************************************************
 *  Copyright (c) 2021, Xilinx, Inc.
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

/*
 * pcam_mipi.c
 *
 *  Created on: Aug 18, 2020
 *      Author: parimalp
 */
#include <stdio.h>
#include <stdint.h>
#include "xparameters.h"
#include "xscugic.h"
#include "xcsiss.h"
#include "xiicps.h"
#include "i2cps.h"
#include "xvidc.h"

#define PCAM_I2C_ADDR		0x3C
#define XCSIRXSS_DEVICE_ID	XPAR_CSISS_0_DEVICE_ID

// Function Prototypes
int StartPcam(int);
int init_pcam(int, unsigned long, int);

inline static uint32_t Read32(intptr_t addr) {
	return *(volatile uint32_t*)addr;
}

inline static void Write32(intptr_t addr, uint32_t value) {
	*(volatile uint32_t*)addr = value;
}

// This function initializes MIPI CSI2 RX SS and gets config parameters.
int InitializeCsiRxSs(void)
{
	XCsiSs CsiRxSs;
	u32 Status = 0;
	XCsiSs_Config *CsiRxSsCfgPtr = NULL;

	CsiRxSsCfgPtr = XCsiSs_LookupConfig(XCSIRXSS_DEVICE_ID);
	if (!CsiRxSsCfgPtr) {
		printf("CSI2RxSs LookupCfg failed\r\n");
		return XST_FAILURE;
	}

	Status = XCsiSs_CfgInitialize(&CsiRxSs, CsiRxSsCfgPtr,
			CsiRxSsCfgPtr->BaseAddr);

	if (Status != XST_SUCCESS) {
		printf("CsiRxSs Cfg init failed - %x\r\n", Status);
		return Status;
	}

	return XST_SUCCESS;
}

// This function programs colour space converter with the given width and height
// @param	width is Hsize of a packet in pixels.
// @param	height is number of lines of a packet.
void ConfigCSC(unsigned long VPROCSSCS_BaseAddress, u32 width , u32 height)
{
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0010), 0x0   );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0018), 0x0   );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0050), 0x1000);
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0058), 0x0   );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0060), 0x0   );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0068), 0x0   );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0070), 0x1000);
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0078), 0x0   );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0080), 0x0   );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0088), 0x0   );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0090), 0x1000);
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0098), 0x0   );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x00a0), 0x0   );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x00a8), 0x0   );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x00b0), 0x0   );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x00b8), 0xff  );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0020), width );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0028), height );
	Xil_Out32((VPROCSSCS_BaseAddress + 0x0000), 0x81  );
}

// This function programs colour space converter with the given width and height
// @param	width is Hsize of a packet in pixels.
// @param	height is number of lines of a packet.
void ConfigGammaLut(unsigned long GAMMALUT_BaseAddress, u32 width , u32 height)
{
	u32 count;
	Xil_Out32((GAMMALUT_BaseAddress + 0x10), width );
	Xil_Out32((GAMMALUT_BaseAddress + 0x18), height );
	Xil_Out32((GAMMALUT_BaseAddress + 0x20), 0x0   );

	for(count=0; count < 0x200; count += 2)
	{
		Xil_Out16((GAMMALUT_BaseAddress + 0x800 + count), count/2 );
	}

	for(count=0; count < 0x200; count += 2)
	{
		Xil_Out16((GAMMALUT_BaseAddress + 0x1000 + count), count/2 );
	}

	for(count=0; count < 0x200; count += 2)
	{
		Xil_Out16((GAMMALUT_BaseAddress + 0x1800 + count), count/2 );
	}

	Xil_Out32((GAMMALUT_BaseAddress + 0x00), 0x81   );

}

// This function programs colour space converter with the given width and height
// @param	width is Hsize of a packet in pixels.
// @param	height is number of lines of a packet.
void ConfigDemosaic(unsigned long DEMOSAIC_BaseAddress, u32 width , u32 height)
{
	Xil_Out32((DEMOSAIC_BaseAddress + 0x10), width );
	Xil_Out32((DEMOSAIC_BaseAddress + 0x18), height );
	Xil_Out32((DEMOSAIC_BaseAddress + 0x20), 0x0   );
	Xil_Out32((DEMOSAIC_BaseAddress + 0x28), 0x0   );
	Xil_Out32((DEMOSAIC_BaseAddress + 0x00), 0x81   );

}

// This function Initializes Image Processing blocks wrt to selected resolution
void InitImageProcessingPipe(unsigned long VPROCSSCS_BaseAddress, unsigned long GAMMALUT_BaseAddress, \
		unsigned long DEMOSAIC_BaseAddress, int video_mode)
{
	u32 width, height;

	if (video_mode == XVIDC_VM_1280x720_60_P){
		width = 1280;
		height = 720;
	}
	else if (video_mode == XVIDC_VM_1920x1080_30_P){
		width = 1920;
		height = 1080;		
	}
	ConfigCSC(VPROCSSCS_BaseAddress,width, height);
	ConfigGammaLut(GAMMALUT_BaseAddress,width, height);
	ConfigDemosaic(DEMOSAIC_BaseAddress, width, height);
}

// This function resets image processing pipe.
void Reset_IP_Pipe(unsigned long BaseAddress)
{
	Xil_Out32(BaseAddress, 0x01);
	Xil_Out32(BaseAddress, 0x00);
	Xil_Out32(BaseAddress, 0x01);
}

// Pcam_MIPI function to initialize the video pipleline and process user input
int pcam_mipi(
		int i2cbus, int usermode,
		unsigned long GPIO_IP_RESET_BaseAddress, unsigned long VPROCSSCS_BaseAddress, \
		unsigned long GAMMALUT_BaseAddress, unsigned long DEMOSAIC_BaseAddress)
{
	int i2c_fd, status, video_mode = -1;

	i2c_fd=setI2C(i2cbus, PCAM_I2C_ADDR);

	/* Reset Demosaic, Gamma_Lut and CSC IPs */
	Reset_IP_Pipe(GPIO_IP_RESET_BaseAddress);

	/* Initialize CSIRXSS  */
	status = InitializeCsiRxSs();
	if (status != XST_SUCCESS) {
		printf("CSI Rx Ss Init failed status = %x.\r\n", status);
		return -1;
	}
	if (usermode == 0)
		video_mode = XVIDC_VM_1280x720_60_P;
	else if (usermode ==1 )
		video_mode = XVIDC_VM_1920x1080_30_P;
	else {
		printf("User mode (%d) is not valid.\r\n", usermode);
		return -1;
	}

	status = init_pcam(i2c_fd,GPIO_IP_RESET_BaseAddress, video_mode);
	if (status != XST_SUCCESS) {
		printf("init_pcam failed.\r\n");
		return -1;
	}
	printf("PCam init done.\r\n");

	InitImageProcessingPipe(VPROCSSCS_BaseAddress, GAMMALUT_BaseAddress, DEMOSAIC_BaseAddress, video_mode);

	/* Start Camera Sensor to capture video */
	status = StartPcam(i2c_fd);
	if (status != XST_SUCCESS) {
		printf("StartPcam failed.\r\n");
		return -1;
	}
	unsetI2C(i2c_fd);

	return i2c_fd;
}
