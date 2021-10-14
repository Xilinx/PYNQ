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
 * pcam_5c.c
 */
#include <unistd.h>
#include <stdio.h>
#include <stdint.h>
#include "xparameters.h"
#include "xiicps.h"
#include "xvidc.h"
#include "pcam_5c.h"
#include "i2cps.h"

int ReadChannel(int i2c_fd, unsigned char writebuffer[], unsigned char RecvBuffer[], u8 write_num, int read_num)
{
    int Status;

    Status=writeI2C_asFile(i2c_fd, writebuffer, write_num);

    if (Status != XST_SUCCESS) {
        printf("Error in ReadChannel...writing, %d\r\n",Status);
        return XST_FAILURE;
    }
    Status = readI2C_asFile(i2c_fd, RecvBuffer, read_num); // chanDeviceID

    if (Status != XST_SUCCESS) {
        printf("Error in ReadChannel... reading, %d\r\n",Status);
        return XST_FAILURE;
    } 
    return 0;
}

int WriteCmd(int i2c_fd, unsigned char writebuffer[], u8 write_num) {
    int Status;

    Status = writeI2C_asFile(i2c_fd, writebuffer, write_num);
    if (Status != XST_SUCCESS) {
        printf("Error in ReadChannel, %d\r\n",Status);
        return XST_FAILURE;
    }
    return 0;
}

// https://digilent.com/reference/add-ons/pcam-5c/reference-manual?redirect=1
int init_pcam(int pcam_i2c_fd, unsigned long GPIO_IP_RESET_BaseAddress, int mode) {
    int i;
    unsigned char u8TxData[3], u8RxData[3];

//  Execute a power-cycle by applying a low pulse of 100ms on CAM_PWUP, then driving it high.
    Xil_Out32(GPIO_IP_RESET_BaseAddress + 0x8, 0);
    usleep(100000);
    Xil_Out32(GPIO_IP_RESET_BaseAddress + 0x8, 1);
//  Wait for 50ms
    usleep(50000);
    printf("*** After pulsing CAM_GPIO low***\r\n");

//  Read sensor ID from registers 0x300A and 0x300B and check against 0x56 and 0x40, respectively.
    u8TxData[0]=0x30;
    u8TxData[1]=0x0A;
    ReadChannel(pcam_i2c_fd, u8TxData, u8RxData, 2, 1);
    if(u8RxData[0]!=0x56) {
        printf("Data read at 0x300A=%0x\r\n",u8RxData[0]);
        return XST_FAILURE;
    }
    u8TxData[0]=0x30;
    u8TxData[1]=0x0B;
    ReadChannel(pcam_i2c_fd, u8TxData, u8RxData, 2, 1);
    if(u8RxData[0]!=0x40) {
        printf("Data read at 0x300B=%0x\r\n",u8RxData[0]);
        return XST_FAILURE;
    }
    printf("PCAM device detected\r\n");
//  Choose system input clock from pad by writing 0x11 to register address 0x3103.
    u8TxData[0]=0x31;
    u8TxData[1]=0x03;
    u8TxData[2]=0x11;
    if (WriteCmd(pcam_i2c_fd, u8TxData, 3) != XST_SUCCESS) {
        return -1;
    }
//  Execute software reset by writing 0x82 to register address 0x3008.
    u8TxData[0]=0x30;
    u8TxData[1]=0x08;
    u8TxData[2]=0x82;
    if (WriteCmd(pcam_i2c_fd, u8TxData, 3) != XST_SUCCESS) {
        return -1;
    }
//  Wait for 10ms.
    usleep(10000);
//  De-assert reset and enable power down until configuration is done by writing 0x42 to register address 0x3008.
//  Choose system input clock from PLL by writing 0x03 to register address 0x3103.
//  Set PLL registers for desired MIPI data rate and sensor timing (frame rate).
//  Set imaging configuration registers.
//  Enable MIPI interface by writing either 0x45 for two-lane mode or 0x25 for one-lane mode to register address 0x300E.
//  Let MIPI clock free-run, and force LP11 when no packet transmission by writing 0x14 to register address 0x4800.
//  Set output format to RAW10 by writing 0x00 to register address 0x4300 and 0x03 to register address 0x501F.
//  Wake up sensor by writing 0x02 to register address 0x3800.
    for(i=0; i<sizeof(cfg_init_)/sizeof(cfg_init_[0]);i++) {
        u8TxData[0]=((cfg_init_[i].addr) >> 8) & 0xff;  // upper byte of the address
        u8TxData[1]=(cfg_init_[i].addr) & 0xff;         // lower byte of the address
        u8TxData[2]=cfg_init_[i].data;                  // data
        if (WriteCmd(pcam_i2c_fd, u8TxData, 3) != XST_SUCCESS) {
            return -1;
        }
        usleep(10000);
    }
    printf("*** After PCAM initialization***\r\n");

    printf("Applying soft reset\r\n");
    //[7]=0 Software reset; [6]=1 Software power down; Default=0x02
    u8TxData[0]=0x30;
    u8TxData[1]=0x08;
    u8TxData[2]=0x42;
    if (WriteCmd(pcam_i2c_fd, u8TxData, 3) != XST_SUCCESS) {
        return -1;
    }

    switch(mode){
        case XVIDC_VM_1280x720_60_P: {
            printf("Configuring for 1280 x 720 @ 60fps, RAW10\r\n");
            for(i=0; i<sizeof(cfg_720p_60fps_)/sizeof(cfg_720p_60fps_[0]);i++) {
                u8TxData[0]=((cfg_720p_60fps_[i].addr) >> 8) & 0xff;    // upper byte of the address
                u8TxData[1]=(cfg_720p_60fps_[i].addr) & 0xff;           // lower byte of the address
                u8TxData[2]=cfg_720p_60fps_[i].data;                    // data
                if (WriteCmd(pcam_i2c_fd, u8TxData, 3) != XST_SUCCESS) {
                    return -1;
                }
                usleep(10000);
            }
            printf("*** After configuring 1280 x 720 @ 60fps, RAW10***\r\n");
        }
        break;
        case XVIDC_VM_1920x1080_30_P: {
            printf("Configuring for 1920 x 1080 @ 30fps, RAW10\r\n");
            for(i=0; i<sizeof(cfg_1080p_30fps_)/sizeof(cfg_1080p_30fps_[0]);i++) {
                u8TxData[0]=((cfg_1080p_30fps_[i].addr) >> 8) & 0xff;   // upper byte of the address
                u8TxData[1]=(cfg_1080p_30fps_[i].addr) & 0xff;          // lower byte of the address
                u8TxData[2]=cfg_1080p_30fps_[i].data;                   // data
                if (WriteCmd(pcam_i2c_fd, u8TxData, 3) != XST_SUCCESS) {
                    return -1;
                }
                usleep(10000);
            }
            printf("*** After configuring 1920 x 1080 @ 30fps, RAW10***\r\n");
        }
        break;
    }
    u8TxData[0]=0x30;
    u8TxData[1]=0x08;
    u8TxData[2]=0x02;
    if (WriteCmd(pcam_i2c_fd, u8TxData, 3) != XST_SUCCESS) {
        return -1;
    }
    usleep(10000);
    u8TxData[0]=0x30;
    u8TxData[1]=0x08;
    u8TxData[2]=0x42;
    if (WriteCmd(pcam_i2c_fd, u8TxData, 3) != XST_SUCCESS) {
        return -1;
    }

    printf("Configuring for advanced_awb\r\n");
    for(i=0; i<sizeof(cfg_advanced_awb_)/sizeof(cfg_advanced_awb_[0]);i++) {
        u8TxData[0]=((cfg_advanced_awb_[i].addr) >> 8) & 0xff;  // upper byte of the address
        u8TxData[1]=(cfg_advanced_awb_[i].addr) & 0xff;         // lower byte of the address
        u8TxData[2]=cfg_advanced_awb_[i].data;                  // data
        if (WriteCmd(pcam_i2c_fd, u8TxData, 3) != XST_SUCCESS) {
            return -1;
        }
        usleep(10000);
    }
    return 0;
}

int StartPcam(int pcam_i2c_fd) {
    unsigned char u8TxData[3];
    int status;

    u8TxData[0]=0x30;
    u8TxData[1]=0x08;
    u8TxData[2]=0x02;
    status = WriteCmd(pcam_i2c_fd, u8TxData, 3);
    return status;
}
