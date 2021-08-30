/******************************************************************************
* Copyright (C) 2017 - 2020 Xilinx, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
*******************************************************************************/

/*****************************************************************************/
/**
*
* @file xrfdc_g.c
* @addtogroup rfdc_v8_1
* @{
*
* This file contains a configuration table that specifies the configuration of
* RFdc devices in the system.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who    Date     Changes
* ----- ---    -------- -----------------------------------------------
* 1.0   sk     05/16/17 Initial release
* 5.1   cog    01/29/19 Added FSMax, NumSlice & IP_Type.
* 7.0   cog    05/13/19 Formatting changes.
* 8.0   cog    02/10/20 Updated addtogroup.
*       cog    02/10/20 Added Silicon_Revision.
* 8.1   cog    06/24/20 Upversion.
*
* </pre>
*
******************************************************************************/
#ifdef __BAREMETAL__
/***************************** Include Files ********************************/
#include "xparameters.h"
#include "xrfdc.h"
/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Variable Definitions ****************************/
/**
 * The configuration table for devices
 */

XRFdc_Config XRFdc_ConfigTable[XPAR_XRFDC_NUM_INSTANCES] = {};

#endif
/** @} */
