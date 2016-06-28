/******************************************************************************
*
* (c) Copyright 2012-2013 Xilinx, Inc. All rights reserved.
*
* This file contains confidential and proprietary information of Xilinx, Inc.
* and is protected under U.S. and international copyright and other
* intellectual property laws.
*
* DISCLAIMER
* This disclaimer is not a license and does not grant any rights to the
* materials distributed herewith. Except as otherwise provided in a valid
* license issued to you by Xilinx, and to the maximum extent permitted by
* applicable law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL
* FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS,
* IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
* MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE;
* and (2) Xilinx shall not be liable (whether in contract or tort, including
* negligence, or under any other theory of liability) for any loss or damage
* of any kind or nature related to, arising under or in connection with these
* materials, including for any direct, or any indirect, special, incidental,
* or consequential loss or damage (including loss of data, profits, goodwill,
* or any type of loss or damage suffered as a result of any action brought by
* a third party) even if such damage or loss was reasonably foreseeable or
* Xilinx had been advised of the possibility of the same.
*
* CRITICAL APPLICATIONS
* Xilinx products are not designed or intended to be fail-safe, or for use in
* any application requiring fail-safe performance, such as life-support or
* safety devices or systems, Class III medical devices, nuclear facilities,
* applications related to the deployment of airbags, or any other applications
* that could lead to death, personal injury, or severe property or
* environmental damage (individually and collectively, "Critical
* Applications"). Customer assumes the sole risk and liability of any use of
* Xilinx products in Critical Applications, subject only to applicable laws
* and regulations governing limitations on product liability.
*
* THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE
* AT ALL TIMES.
*
*******************************************************************************/

/*****************************************************************************
*
* @file fsbl_hooks.c
*
* This file provides functions that serve as user hooks.  The user can add the
* additional functionality required into these routines.  This would help retain
* the normal FSBL flow unchanged.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date        Changes
* ----- ---- -------- -------------------------------------------------------
* 3.00a np   08/03/12 Initial release
* </pre>
*
* @note
*
******************************************************************************/


#include "fsbl.h"
#include "xstatus.h"
#include "fsbl_hooks.h"
#include "xparameters.h"
#include "xiicps.h"
#include "xemacps.h"

/************************** Variable Definitions *****************************/


/************************** Function Prototypes ******************************/


/******************************************************************************
* This function is the hook which will be called  before the bitstream download.
* The user can add all the customized code required to be executed before the
* bitstream download to this routine.
*
* @param None
*
* @return
*       - XST_SUCCESS to indicate success
*       - XST_FAILURE.to indicate failure
*
****************************************************************************/
u32 FsblHookBeforeBitstreamDload(void)
{
    u32 Status;

    Status = XST_SUCCESS;

    /*
     * User logic to be added here. Errors to be stored in the status variable
     * and returned
     */
    fsbl_printf(DEBUG_INFO,"In FsblHookBeforeBitstreamDload function \r\n");

    return (Status);
}

/******************************************************************************
* This function is the hook which will be called  after the bitstream download.
* The user can add all the customized code required to be executed after the
* bitstream download to this routine.
*
* @param None
*
* @return
*       - XST_SUCCESS to indicate success
*       - XST_FAILURE.to indicate failure
*
****************************************************************************/
u32 FsblHookAfterBitstreamDload(void)
{
    u32 Status;

    Status = XST_SUCCESS;

    /*
     * User logic to be added here.
     * Errors to be stored in the status variable and returned
     */
    fsbl_printf(DEBUG_INFO, "In FsblHookAfterBitstreamDload function \r\n");

    return (Status);
}

/******************************************************************************
* This function is the hook which will be called  before the FSBL does a handoff
* to the application. The user can add all the customized code required to be
* executed before the handoff to this routine.
*
* @param None
*
* @return
*       - XST_SUCCESS to indicate success
*       - XST_FAILURE.to indicate failure
*
****************************************************************************/
u32 FsblHookBeforeHandoff(void)
{
    u32 Status;

    Status = XST_SUCCESS;

    /*
     * User logic to be added here.
     * Errors to be stored in the status variable and returned
     */
    fsbl_printf(DEBUG_INFO,"In FsblHookBeforeHandoff function \r\n");

    /* Read Out MAC Address */
    {
        int Status;
        XIicPs Iic;
        XIicPs_Config *Iic_Config;
        XEmacPs Emac;
        XEmacPs_Config *Mac_Config;

        unsigned char mac_addr[6];
        int i = 0;

        fsbl_printf(DEBUG_GENERAL,"Look Up I2C Configuration\n\r");
        Iic_Config = XIicPs_LookupConfig(XPAR_PS7_I2C_1_DEVICE_ID);
        if(Iic_Config == NULL) {
            return XST_FAILURE;
        }

        fsbl_printf(DEBUG_GENERAL,"I2C Initialization\n\r");
        Status = XIicPs_CfgInitialize(&Iic, Iic_Config, Iic_Config->BaseAddress);
        if(Status != XST_SUCCESS) {
            return XST_FAILURE;
        }

        fsbl_printf(DEBUG_GENERAL,"Set I2C Clock\n\r");
        XIicPs_SetSClk(&Iic, 200000);

        mac_addr[0] = 0xFA;

        fsbl_printf(DEBUG_GENERAL,"Set Memory Read Address\n\r");
        XIicPs_MasterSendPolled(&Iic, mac_addr, 1, 0x50);
        while(XIicPs_BusIsBusy(&Iic));
        fsbl_printf(DEBUG_GENERAL,"Get Mac Address\n\r");
        XIicPs_MasterRecvPolled(&Iic, mac_addr, 6, 0x50);
        while(XIicPs_BusIsBusy(&Iic));

        fsbl_printf(DEBUG_GENERAL,"MAC Addr: ");
        for(i = 0; i < 6; i++) {
            fsbl_printf(DEBUG_GENERAL,"%02x ", mac_addr[i]);
        }
        fsbl_printf(DEBUG_GENERAL,"\n\r");

        fsbl_printf(DEBUG_GENERAL,"Look Up Emac Configuration\n\r");
        Mac_Config = XEmacPs_LookupConfig(XPAR_PS7_ETHERNET_0_DEVICE_ID);
        if(Mac_Config == NULL) {
            return XST_FAILURE;
        }

        fsbl_printf(DEBUG_GENERAL,"Emac Initialization\n\r");
        Status = XEmacPs_CfgInitialize(&Emac, Mac_Config, Mac_Config->BaseAddress);
        if(Status != XST_SUCCESS){
            return XST_FAILURE;
        }

        fsbl_printf(DEBUG_GENERAL,"Set Emac MAC Address\n\r");
        Status = XEmacPs_SetMacAddress(&Emac, mac_addr, 1);
        if(Status != XST_SUCCESS){
            return XST_FAILURE;
        }

        fsbl_printf(DEBUG_GENERAL,"Verify Emac MAC Address\n\r");
        XEmacPs_GetMacAddress(&Emac, mac_addr, 1);
        if(Status != XST_SUCCESS){
            return XST_FAILURE;
        }

        xil_printf("MAC Addr: ");
        for(i = 0; i < 6; i++) {
            xil_printf("%02x ", mac_addr[i]);
        }
        xil_printf("\n\r");
    }


    return (Status);
}


/******************************************************************************
* This function is the hook which will be called in case FSBL fall back
*
* @param None
*
* @return None
*
****************************************************************************/
void FsblHookFallback(void)
{
    /*
     * User logic to be added here.
     * Errors to be stored in the status variable and returned
     */
    fsbl_printf(DEBUG_INFO,"In FsblHookFallback function \r\n");
    while(1);
}


