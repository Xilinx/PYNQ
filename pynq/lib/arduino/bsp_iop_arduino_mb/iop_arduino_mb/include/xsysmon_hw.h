/******************************************************************************
*
* Copyright (C) 2007 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/
/****************************************************************************/
/**
*
* @file xsysmon_hw.h
* @addtogroup sysmon_v7_1
* @{
*
* This header file contains identifiers and basic driver functions (or
* macros) that can be used to access the System Monitor/ADC device or XADC.
*
* Refer to the device specification for more information about this driver.
*
* @note	 None.
*
* <pre>
*
* MODIFICATION HISTORY:
*
* Ver   Who    Date     Changes
* ----- -----  -------- -----------------------------------------------------
* 1.00a xd/sv  05/22/07 First release
* 2.00a sv     07/07/08 Added bit definitions for new Alarm Interrupts in the
*			Interrupt Registers.
* 3.00a sdm    02/09/09 Added register and bit definitions for V6 SysMon.
* 4.00a ktn    10/22/09 The macros have been renamed to remove _m from the name
*		       	of the macro.
* 5.00a sdm    06/15/11 Added new definitions for XADC.
* 5.01a bss    02/15/12 Updated for Zynq.
* 5.02a bss    11/23/12 Added macros XSM_CONVST_TEMPUPDT_MASK,
*			XSM_CONVST_WAITCYCLES_MASK and
*			XSM_CONVST_WAITCYCLES_SHIFT (CR #679872)
* 7.0	bss    7/25/14	To support Ultrascale:
*			Added XSM_IP_OFFSET macro.
*			Added Offsets and Masks for VUSER0 to VUSER3 channels.
*			Added Configuration Register 3 and Sequence Registers
*			8 and 9.
* 7.2   asa     03/11/16 Made changes so that XSM_CFR3_OFFSET is
*             visible only for Ultrasacle. Fix for CR#910905.
*
* </pre>
*
*****************************************************************************/

#ifndef XSYSMON_HW_H /* Prevent circular inclusions */
#define XSYSMON_HW_H /* by using protection macros  */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files ********************************/

#include "xil_types.h"
#include "xil_assert.h"
#include "xil_io.h"
#include "xparameters.h"

/************************** Constant Definitions ****************************/

#define SYSTEM_MANAGEMENT	1	/* Ultrascale */
#define XADC			0	/* 7 Series, Zynq */


#if XPAR_SYSMON_0_IP_TYPE == SYSTEM_MANAGEMENT
#define XSM_IP_OFFSET	0x200
#else
#define XSM_IP_OFFSET	0x00
#endif


/**@name Register offsets
 *
 * The following constants provide access to each of the registers of the
 * System Monitor/ADC device.
 * @{
 */

/*
 * System Monitor/ADC Local Registers
 */
#define XSM_SRR_OFFSET		0x00  /**< Software Reset Register */
#define XSM_SR_OFFSET		0x04  /**< Status Register */
#define XSM_AOR_OFFSET		0x08  /**< Alarm Output Register */
#define XSM_CONVST_OFFSET	0x0C  /**< ADC Convert Start Register */
#define XSM_ARR_OFFSET		0x10  /**< ADC Reset Register */

/*
 * System Monitor/ADC Interrupt Registers
 */
#define XSM_GIER_OFFSET		0x5C  /**< Global Interrupt Enable */
#define XSM_IPISR_OFFSET	0x60  /**< Interrupt Status Register */
#define XSM_IPIER_OFFSET	0x68  /**< Interrupt Enable register */

/*
 * System Monitor/ADC Internal Channel Registers
 */
#define XSM_TEMP_OFFSET		 (XSM_IP_OFFSET + 0x200)
					/**< On-chip Temperature Reg */
#define XSM_VCCINT_OFFSET	 (XSM_IP_OFFSET + 0x204)
					/**< On-chip VCCINT Data Reg */
#define XSM_VCCAUX_OFFSET	 (XSM_IP_OFFSET + 0x208)
					/**< On-chip VCCAUX Data Reg */
#define XSM_VPVN_OFFSET		 (XSM_IP_OFFSET + 0x20C)
					/**< ADC out of VP/VN	   */
#define XSM_VREFP_OFFSET	 (XSM_IP_OFFSET + 0x210)
					/**< On-chip VREFP Data Reg */
#define XSM_VREFN_OFFSET	 (XSM_IP_OFFSET + 0x214)
					/**< On-chip VREFN Data Reg */
#define XSM_VBRAM_OFFSET	 (XSM_IP_OFFSET + 0x218)
					/**< On-chip VBRAM Data,7-series/Zynq */
#define XSM_SUPPLY_CALIB_OFFSET	 (XSM_IP_OFFSET + 0x220)
					/**< Supply Offset Data Reg */
#define XSM_ADC_CALIB_OFFSET	 (XSM_IP_OFFSET + 0x224)
					/**< ADC Offset Data Reg */
#define XSM_GAINERR_CALIB_OFFSET (XSM_IP_OFFSET + 0x228)
					/**< Gain Error Data Reg  */
#define XSM_VCCPINT_OFFSET	 (XSM_IP_OFFSET + 0x22C)
					/**< PS VCCPINT Data Reg - Zynq */
#define XSM_VCCPAUX_OFFSET	 (XSM_IP_OFFSET + 0x230)
					/**< PS VCCPAUX Data Reg - Zynq */
#define XSM_VCCPDRO_OFFSET	 (XSM_IP_OFFSET + 0x234)
					/**< PS VCCPDRO Data Reg - Zynq */
#define XSM_VUSR0_OFFSET	 (XSM_IP_OFFSET + 0x400)
					/**< VUSER0 Supply - Ultrascale */
#define XSM_VUSR1_OFFSET	 (XSM_IP_OFFSET + 0x404)
					/**< VUSER0 Supply - Ultrascale */
#define XSM_VUSR2_OFFSET	 (XSM_IP_OFFSET + 0x408)
					/**< VUSER0 Supply - Ultrascale */
#define XSM_VUSR3_OFFSET	 (XSM_IP_OFFSET + 0x40C)
					/**< VUSER0 Supply - Ultrascale */

/*
 * System Monitor/ADC External Channel Registers
 */
#define XSM_AUX00_OFFSET	(XSM_IP_OFFSET + 0x240)
					/**< ADC out of VAUXP0/VAUXN0 */
#define XSM_AUX01_OFFSET	(XSM_IP_OFFSET + 0x244)
					/**< ADC out of VAUXP1/VAUXN1 */
#define XSM_AUX02_OFFSET	(XSM_IP_OFFSET + 0x248)
					/**< ADC out of VAUXP2/VAUXN2 */
#define XSM_AUX03_OFFSET	(XSM_IP_OFFSET + 0x24C)
					/**< ADC out of VAUXP3/VAUXN3 */
#define XSM_AUX04_OFFSET	(XSM_IP_OFFSET + 0x250)
					/**< ADC out of VAUXP4/VAUXN4 */
#define XSM_AUX05_OFFSET	(XSM_IP_OFFSET + 0x254)
					/**< ADC out of VAUXP5/VAUXN5 */
#define XSM_AUX06_OFFSET	(XSM_IP_OFFSET + 0x258)
					/**< ADC out of VAUXP6/VAUXN6 */
#define XSM_AUX07_OFFSET	(XSM_IP_OFFSET + 0x25C)
					/**< ADC out of VAUXP7/VAUXN7 */
#define XSM_AUX08_OFFSET	(XSM_IP_OFFSET + 0x260)
					/**< ADC out of VAUXP8/VAUXN8 */
#define XSM_AUX09_OFFSET	(XSM_IP_OFFSET + 0x264)
					/**< ADC out of VAUXP9/VAUXN9 */
#define XSM_AUX10_OFFSET	(XSM_IP_OFFSET + 0x268)
					/**< ADC out of VAUXP10/VAUXN10 */
#define XSM_AUX11_OFFSET	(XSM_IP_OFFSET + 0x26C)
					/**< ADC out of VAUXP11/VAUXN11 */
#define XSM_AUX12_OFFSET	(XSM_IP_OFFSET + 0x270)
					/**< ADC out of VAUXP12/VAUXN12 */
#define XSM_AUX13_OFFSET	(XSM_IP_OFFSET + 0x274)
					/**< ADC out of VAUXP13/VAUXN13 */
#define XSM_AUX14_OFFSET	(XSM_IP_OFFSET + 0x278)
					/**< ADC out of VAUXP14/VAUXN14 */
#define XSM_AUX15_OFFSET	(XSM_IP_OFFSET + 0x27C)
					/**< ADC out of VAUXP15/VAUXN15 */

/*
 * System Monitor/ADC Registers for Maximum/Minimum data captured for the
 * on chip Temperature/VCCINT/VCCAUX data.
 */
#define XSM_MAX_TEMP_OFFSET	(XSM_IP_OFFSET + 0x280)
					/**< Maximum Temperature Reg */
#define XSM_MAX_VCCINT_OFFSET	(XSM_IP_OFFSET + 0x284)
					/**< Maximum VCCINT Register */
#define XSM_MAX_VCCAUX_OFFSET	(XSM_IP_OFFSET + 0x288)
					/**< Maximum VCCAUX Register */
#define XSM_MAX_VBRAM_OFFSET	(XSM_IP_OFFSET + 0x28C)
					/**< Maximum VBRAM Reg, 7 Series/Zynq */
#define XSM_MIN_TEMP_OFFSET	(XSM_IP_OFFSET + 0x290)
					/**< Minimum Temperature Reg */
#define XSM_MIN_VCCINT_OFFSET	(XSM_IP_OFFSET + 0x294)
					/**< Minimum VCCINT Register */
#define XSM_MIN_VCCAUX_OFFSET	(XSM_IP_OFFSET + 0x298)
					/**< Minimum VCCAUX Register */
#define XSM_MIN_VBRAM_OFFSET	(XSM_IP_OFFSET + 0x29C)
					/**< Maximum VBRAM Reg, 7 Series/Zynq */
#define XSM_MAX_VCCPINT_OFFSET	(XSM_IP_OFFSET + 0x2A0)
					/**< Max VCCPINT Register, Zynq */
#define XSM_MAX_VCCPAUX_OFFSET	(XSM_IP_OFFSET + 0x2A4)
					/**< Max VCCPAUX Register, Zynq */
#define XSM_MAX_VCCPDRO_OFFSET	(XSM_IP_OFFSET + 0x2A8)
					/**< Max VCCPDRO Register, Zynq */
#define XSM_MIN_VCCPINT_OFFSET	(XSM_IP_OFFSET + 0x2AC)
					/**< Min VCCPINT Register, Zynq */
#define XSM_MIN_VCCPAUX_OFFSET	(XSM_IP_OFFSET + 0x2B0)
					/**< Min VCCPAUX Register, Zynq */
#define XSM_MIN_VCCPDRO_OFFSET	(XSM_IP_OFFSET + 0x2B4)
					/**< Min VCCPDRO Register, Zynq */
#define XSM_MAX_VUSR0_OFFSET	(XSM_IP_OFFSET + 0x480)
					/**< Maximum VUSER0 Supply Reg */
#define XSM_MAX_VUSR1_OFFSET	(XSM_IP_OFFSET + 0x484)
					/**< Maximum VUSER1 Supply Reg */
#define XSM_MAX_VUSR2_OFFSET	(XSM_IP_OFFSET + 0x488)
					/**< Maximum VUSER2 Supply Reg */
#define XSM_MAX_VUSR3_OFFSET	(XSM_IP_OFFSET + 0x48C)
					/**< Maximum VUSER3 Supply Reg */
#define XSM_MIN_VUSR0_OFFSET	(XSM_IP_OFFSET + 0x4A0)
					/**< Minimum VUSER0 Supply Reg */
#define XSM_MIN_VUSR1_OFFSET	(XSM_IP_OFFSET + 0x4A4)
					/**< Minimum VUSER1 Supply Reg */
#define XSM_MIN_VUSR2_OFFSET	(XSM_IP_OFFSET + 0x4A8)
					/**< Minimum VUSER2 Supply Reg */
#define XSM_MIN_VUSR3_OFFSET	(XSM_IP_OFFSET + 0x4AC)
					/**< Minimum VUSER3 Supply Reg */


#define XSM_FLAG_REG_OFFSET	(XSM_IP_OFFSET + 0x2FC) /**< General Status */

/*
 * System Monitor/ADC Configuration Registers
 */
#define XSM_CFR0_OFFSET		(XSM_IP_OFFSET + 0x300)
					/**< Configuration Register 0 */
#define XSM_CFR1_OFFSET		(XSM_IP_OFFSET + 0x304)
					/**< Configuration Register 1 */
#define XSM_CFR2_OFFSET		(XSM_IP_OFFSET + 0x308)
					/**< Configuration Register 2 */

#if XPAR_SYSMON_0_IP_TYPE == SYSTEM_MANAGEMENT
#define XSM_CFR3_OFFSET		(XSM_IP_OFFSET + 0x30C)
					/**< Configuration Register 3 */
#endif
/*
 * System Monitor/ADC Sequence Registers
 */
#define XSM_SEQ00_OFFSET	(XSM_IP_OFFSET + 0x320)
				      /**< Seq Reg 00 Adc Channel Selection */
#define XSM_SEQ01_OFFSET	(XSM_IP_OFFSET + 0x324)
				      /**< Seq Reg 01 Adc Channel Selection */
#define XSM_SEQ02_OFFSET	(XSM_IP_OFFSET + 0x328)
				      /**< Seq Reg 02 Adc Average Enable */
#define XSM_SEQ03_OFFSET	(XSM_IP_OFFSET + 0x32C)
				      /**< Seq Reg 03 Adc Average Enable */
#define XSM_SEQ04_OFFSET	(XSM_IP_OFFSET + 0x330)
				      /**< Seq Reg 04 Adc Input Mode Select */
#define XSM_SEQ05_OFFSET	(XSM_IP_OFFSET + 0x334)
				      /**< Seq Reg 05 Adc Input Mode Select */
#define XSM_SEQ06_OFFSET	(XSM_IP_OFFSET + 0x338)
				      /**< Seq Reg 06 Adc Acquisition Select */
#define XSM_SEQ07_OFFSET	(XSM_IP_OFFSET + 0x33C)
				      /**< Seq Reg 07 Adc Acquisition Select */
#define XSM_SEQ08_OFFSET	(XSM_IP_OFFSET + 0x318)
				      /**< Seq Reg 08 Adc Channel Selection */
#define XSM_SEQ09_OFFSET	(XSM_IP_OFFSET + 0x31C)
				      /**< Seq Reg 09 Adc Average Enable */

/*
 * System Monitor/ADC Alarm Threshold/Limit Registers (ATR)
 */
#define XSM_ATR_TEMP_UPPER_OFFSET	(XSM_IP_OFFSET + 0x340)
					/**< Temp Upper Alarm Register */
#define XSM_ATR_VCCINT_UPPER_OFFSET	(XSM_IP_OFFSET + 0x344)
					/**< VCCINT Upper Alarm Reg */
#define XSM_ATR_VCCAUX_UPPER_OFFSET	(XSM_IP_OFFSET + 0x348)
					/**< VCCAUX Upper Alarm Reg */
#define XSM_ATR_OT_UPPER_OFFSET		(XSM_IP_OFFSET + 0x34C)
					/**< Over Temp Upper Alarm Reg */
#define XSM_ATR_TEMP_LOWER_OFFSET	(XSM_IP_OFFSET + 0x350)
					/**< Temp Lower Alarm Register */
#define XSM_ATR_VCCINT_LOWER_OFFSET	(XSM_IP_OFFSET + 0x354)
					/**< VCCINT Lower Alarm Reg */
#define XSM_ATR_VCCAUX_LOWER_OFFSET	(XSM_IP_OFFSET + 0x358)
					/**< VCCAUX Lower Alarm Reg */
#define XSM_ATR_OT_LOWER_OFFSET		(XSM_IP_OFFSET + 0x35C)
					/**< Over Temp Lower Alarm Reg */
#define XSM_ATR_VBRAM_UPPER_OFFSET	(XSM_IP_OFFSET + 0x360)
					/**< VBBAM Upper Alarm,7 Series */
#define XSM_ATR_VCCPINT_UPPER_OFFSET	(XSM_IP_OFFSET + 0x364)
					/**< VCCPINT Upper Alarm, Zynq */
#define XSM_ATR_VCCPAUX_UPPER_OFFSET	(XSM_IP_OFFSET + 0x368)
					/**< VCCPAUX Upper Alarm, Zynq */
#define XSM_ATR_VCCPDRO_UPPER_OFFSET	(XSM_IP_OFFSET + 0x36C)
					/**< VCCPDRO Upper Alarm, Zynq */
#define XSM_ATR_VBRAM_LOWER_OFFSET	(XSM_IP_OFFSET + 0x370)
					/**< VRBAM Lower Alarm, 7 Series*/
#define XSM_ATR_VCCPINT_LOWER_OFFSET	(XSM_IP_OFFSET + 0x374)
					/**< VCCPINT Lower Alarm, Zynq */
#define XSM_ATR_VCCPAUX_LOWER_OFFSET	(XSM_IP_OFFSET + 0x378)
					/**< VCCPAUX Lower Alarm, Zynq */
#define XSM_ATR_VCCPDRO_LOWER_OFFSET	(XSM_IP_OFFSET + 0x37C)
					/**< VCCPDRO Lower Alarm, Zynq */
#define XSM_ATR_VUSR0_UPPER_OFFSET	(XSM_IP_OFFSET + 0x380)
					/**< VUSER0 Upper Alarm Reg */
#define XSM_ATR_VUSR1_UPPER_OFFSET	(XSM_IP_OFFSET + 0x384)
					/**< VUSER1 Upper Alarm Reg */
#define XSM_ATR_VUSR2_UPPER_OFFSET	(XSM_IP_OFFSET + 0x388)
					/**< VUSER2 Upper Alarm Reg */
#define XSM_ATR_VUSR3_UPPER_OFFSET	(XSM_IP_OFFSET + 0x38C)
					/**< VUSER3 Upper Alarm Reg */
#define XSM_ATR_VUSR0_LOWER_OFFSET	(XSM_IP_OFFSET + 0x3A0)
					/**< VUSER0 Lower Alarm Reg */
#define XSM_ATR_VUSR1_LOWER_OFFSET	(XSM_IP_OFFSET + 0x3A4)
					/**< VUSER1 Lower Alarm Reg */
#define XSM_ATR_VUSR2_LOWER_OFFSET	(XSM_IP_OFFSET + 0x3A8)
					/**< VUSER2 Lower Alarm Reg */
#define XSM_ATR_VUSR3_LOWER_OFFSET	(XSM_IP_OFFSET + 0x3AC)
					/**< VUSER3 Lower Alarm Reg */

/*@}*/

/**
 * @name System Monitor/ADC Software Reset Register (SRR) mask(s)
 * @{
 */
#define XSM_SRR_IPRST_MASK	0x0000000A   /**< Device Reset Mask */

/*@}*/

/**
 * @name System Monitor/ADC Status Register (SR) mask(s)
 * @{
 */
#define XSM_SR_JTAG_BUSY_MASK	  0x00000400 /**< JTAG is busy */
#define XSM_SR_JTAG_MODIFIED_MASK 0x00000200 /**< JTAG Write has occurred */
#define XSM_SR_JTAG_LOCKED_MASK	  0x00000100 /**< JTAG is locked */
#define XSM_SR_BUSY_MASK	  0x00000080 /**< ADC is busy in conversion */
#define XSM_SR_EOS_MASK		  0x00000040 /**< End of Sequence */
#define XSM_SR_EOC_MASK		  0x00000020 /**< End of Conversion */
#define XSM_SR_CH_MASK		  0x0000001F /**< Input ADC channel */

/*@}*/

/**
 * @name System Monitor/ADC Alarm Output Register (AOR) mask(s)
 * @{
 */
#define XSM_AOR_ALARM_ALL_MASK	0x00001FFF /**< Mask for all Alarms */
#define XSM_AOR_VUSR3_MASK	0x00001000 /**< ALM11 - VUSER3 Alarm Mask */
#define XSM_AOR_VUSR2_MASK	0x00000800 /**< ALM10 - VUSER2 Alarm Mask */
#define XSM_AOR_VUSR1_MASK	0x00000400 /**< ALM9 -  VUSER1 Alarm Mask */
#define XSM_AOR_VUSR0_MASK	0x00000200 /**< ALM8 -  VUSER0 Alarm Mask */
#define XSM_AOR_ALL_MASK	0x00000100 /**< ALM7 - All Alarms 0 to 6 */
#define XSM_AOR_VCCPDRO_MASK	0x00000080 /**< ALM6 - VCCPDRO  Mask, Zynq */
#define XSM_AOR_VCCPAUX_MASK	0x00000040 /**< ALM5 - VCCPAUX  Mask, Zynq */
#define XSM_AOR_VCCPINT_MASK	0x00000020 /**< ALM4 - VCCPINT Mask, Zynq */
#define XSM_AOR_VBRAM_MASK	0x00000010 /**< ALM3 - VBRAM Output Mask
					     *  - 7 Series and Zynq */
#define XSM_AOR_VCCAUX_MASK	0x00000008 /**< ALM2 - VCCAUX Output Mask  */
#define XSM_AOR_VCCINT_MASK	0x00000004 /**< ALM1 - VCCINT Alarm Mask */
#define XSM_AOR_TEMP_MASK	0x00000002 /**< ALM0 - Temp sensor Alarm Mask */
#define XSM_AOR_OT_MASK		0x00000001 /**< Over Temp Alarm Output */

/*@}*/

/**
 * @name System Monitor/ADC CONVST Register (CONVST) mask(s)
 * @{
 */
#define XSM_CONVST_CONVST_MASK		0x00000001
						/**< Conversion Start Mask */
#define XSM_CONVST_TEMPUPDT_MASK	0x00000002
						/**< Temperature Update
							Enable Mask */
#define XSM_CONVST_WAITCYCLES_SHIFT	2	/**< Wait Cycles Shift */
#define XSM_CONVST_WAITCYCLES_MASK	0x0003FFFC /**< Wait Cycles Mask */
#define XSM_CONVST_WAITCYCLES_DEFAULT	0x03E8	/**< Wait Cycles
							 default value */
/*@}*/

/**
 * @name System Monitor/ADC Reset Register (ARR) mask(s)
 * @{
 */
#define XSM_ARR_RST_MASK	0x00000001 /**< ADC Reset bit mask */

/*@}*/

/**
 * @name Global Interrupt Enable Register (GIER) mask(s)
 * @{
 */
#define XSM_GIER_GIE_MASK	0x80000000 /**< Global interrupt enable */
/*@}*/

/**
 * @name System Monitor/ADC device Interrupt Status/Enable Registers
 *
 * <b> Interrupt Status Register (IPISR) </b>
 *
 * This register holds the interrupt status flags for the device.
 *
 * <b> Interrupt Enable Register (IPIER) </b>
 *
 * This register is used to enable interrupt sources for the device.
 * Writing a '1' to a bit in this register enables the corresponding Interrupt.
 * Writing a '0' to a bit in this register disables the corresponding Interrupt
 *
 * IPISR/IPIER registers have the same bit definitions and are only defined
 * once.
 * @{
 */
#define XSM_IPIXR_VBRAM_MASK	      0x00000400 /**< ALM3 - VBRAM Output Mask
						   *  - 7 Series  and Zynq */
#define XSM_IPIXR_TEMP_DEACTIVE_MASK  0x00000200 /**< Alarm 0 DEACTIVE */
#define XSM_IPIXR_OT_DEACTIVE_MASK    0x00000100 /**< Over Temp DEACTIVE */
#define XSM_IPIXR_JTAG_MODIFIED_MASK  0x00000080 /**< JTAG Modified */
#define XSM_IPIXR_JTAG_LOCKED_MASK    0x00000040 /**< JTAG Locked */
#define XSM_IPIXR_EOC_MASK	      0x00000020 /**< End Of Conversion */
#define XSM_IPIXR_EOS_MASK	      0x00000010 /**< End Of Sequence */
#define XSM_IPIXR_VCCAUX_MASK	      0x00000008 /**< Alarm 2 - VCCAUX */
#define XSM_IPIXR_VCCINT_MASK	      0x00000004 /**< Alarm 1 - VCCINT */
#define XSM_IPIXR_TEMP_MASK	      0x00000002 /**< Alarm 0 - Temp ACTIVE */
#define XSM_IPIXR_OT_MASK	      0x00000001 /**< Over Temperature ACTIVE */
#define XSM_IPIXR_VUSR0_MASK	      0x00004000 /**< Alarm 8  VUSER0 */
#define XSM_IPIXR_VUSR1_MASK	      0x00008000 /**< Alarm 9  VUSER1 */
#define XSM_IPIXR_VUSR2_MASK	      0x00010000 /**< Alarm 10 VUSER2 */
#define XSM_IPIXR_VUSR3_MASK	      0x00020000 /**< Alarm 11 VUSER3 */
#define XSM_IPIXR_ALL_MASK	      0x0003C7FF /**< Mask of all interrupts */


/*@}*/

/**
 * @name Mask for all ADC converted data including Minimum/Maximum Measurements
 *	 and Threshold data.
 * @{
 */
#define XSM_ADCDATA_MAX_MASK	0x03FF

/*@}*/

/**
 * @name Configuration Register 0 (CFR0) mask(s)
 * @{
 */
#define XSM_CFR0_CAL_AVG_MASK	0x8000  /**< Averaging enable Mask */
#define XSM_CFR0_AVG_VALID_MASK	0x3000  /**< Averaging bit Mask */
#define XSM_CFR0_AVG1_MASK	0x0000  /**< No Averaging */
#define XSM_CFR0_AVG16_MASK	0x1000  /**< Average 16 samples */
#define XSM_CFR0_AVG64_MASK	0x2000  /**< Average 64 samples */
#define XSM_CFR0_AVG256_MASK	0x3000  /**< Average 256 samples */
#define XSM_CFR0_AVG_SHIFT	12	/**< Shift for the Averaging bits */
#define XSM_CFR0_MUX_MASK	0x0800  /**< External Mux Mask Enable
					  *  - 7 Series and Zynq  */
#define XSM_CFR0_DU_MASK	0x0400  /**< Bipolar/Unipolar mode */
#define XSM_CFR0_EC_MASK	0x0200  /**< Event driven/Continuous mode */
#define XSM_CFR0_ACQ_MASK	0x0100  /**< Add acquisition by 6 ADCCLK  */
#define XSM_CFR0_CHANNEL_MASK	0x003F  /**< Channel number bit Mask */

/*@}*/

/**
 * @name Configuration Register 1 (CFR1) mask(s)
 * @{
 */
#define XSM_CFR1_SEQ_VALID_MASK		  0xF000 /**< Sequence bit Mask */
#define XSM_CFR1_SEQ_SAFEMODE_MASK	  0x0000 /**< Default Safe Mode */
#define XSM_CFR1_SEQ_ONEPASS_MASK	  0x1000 /**< Onepass through Seq */
#define XSM_CFR1_SEQ_CONTINPASS_MASK	  0x2000 /**< Continuous Cycling Seq */
#define XSM_CFR1_SEQ_SINGCHAN_MASK	  0x3000 /**< Single channel - No Seq */
#define XSM_CFR1_SEQ_SIMUL_SAMPLING_MASK  0x4000 /**< Simulataneous Sampling
						   *  Mask */
#define XSM_CFR1_SEQ_INDEPENDENT_MASK	  0x8000 /**< Independent Mode */
#define XSM_CFR1_SEQ_SHIFT		  12     /**< Sequence bit shift */
#define XSM_CFR1_ALM_VCCPDRO_MASK	  0x0800 /**< Alarm 6 - VCCPDRO, Zynq */
#define XSM_CFR1_ALM_VCCPAUX_MASK	  0x0400 /**< Alarm 5 - VCCPAUX, Zynq */
#define XSM_CFR1_ALM_VCCPINT_MASK	  0x0200 /**< Alarm 4 - VCCPINT, Zynq */
#define XSM_CFR1_ALM_VBRAM_MASK	  	  0x0100 /**< Alarm 3 - VBRAM Enable
						   *  7 Series and Zynq */
#define XSM_CFR1_CAL_VALID_MASK		  0x00F0 /**< Valid Calibration Mask */
#define XSM_CFR1_CAL_PS_GAIN_OFFSET_MASK  0x0080 /**< Calibration 3 -Power
							Supply Gain/Offset
							Enable */
#define XSM_CFR1_CAL_PS_OFFSET_MASK	  0x0040 /**< Calibration 2 -Power
							Supply Offset Enable */
#define XSM_CFR1_CAL_ADC_GAIN_OFFSET_MASK 0x0020 /**< Calibration 1 -ADC Gain
							Offset Enable */
#define XSM_CFR1_CAL_ADC_OFFSET_MASK	  0x0010 /**< Calibration 0 -ADC Offset
							Enable */
#define XSM_CFR1_CAL_DISABLE_MASK	  0x0000 /**< No Calibration */
#define XSM_CFR1_ALM_ALL_MASK		  0x0F0F /**< Mask for all alarms */
#define XSM_CFR1_ALM_VCCAUX_MASK	  0x0008 /**< Alarm 2 - VCCAUX Enable */
#define XSM_CFR1_ALM_VCCINT_MASK	  0x0004 /**< Alarm 1 - VCCINT Enable */
#define XSM_CFR1_ALM_TEMP_MASK		  0x0002 /**< Alarm 0 - Temperature */
#define XSM_CFR1_OT_MASK		  0x0001 /**< Over Temperature Enable */

/*@}*/

/**
 * @name Configuration Register 2 (CFR2) mask(s)
 * @{
 */
#define XSM_CFR2_CD_VALID_MASK	0xFF00  /**<Clock Divisor bit Mask   */
#define XSM_CFR2_CD_SHIFT	8	/**<Num of shift on division */
#define XSM_CFR2_CD_MIN		8	/**<Minimum value of divisor */
#define XSM_CFR2_CD_MAX		255	/**<Maximum value of divisor */

#define XSM_CFR2_PD_MASK	0x0030	/**<Power Down Mask */
#define XSM_CFR2_PD_XADC_MASK	0x0030	/**<Power Down XADC Mask */
#define XSM_CFR2_PD_ADC1_MASK	0x0020	/**<Power Down XADC Mask */
#define XSM_CFR2_PD_SHIFT	4	/**<Power Down Shift */

/*@}*/

/**
 * @name Configuration Register 3 (CFR3) mask(s)
 * @{
 */

#define XSM_CFR3_ALM_ALL_MASK		  0x000F /**< Mask for all alarms */
#define XSM_CFR3_ALM_VUSR3_MASK		  0x0008 /**< VUSER 0 Supply */
#define XSM_CFR3_ALM_VUSR2_MASK		  0x0004 /**< VUSER 1 Supply */
#define XSM_CFR3_ALM_VUSR1_MASK		  0x0002 /**< VUSER 2 Supply */
#define XSM_CFR3_ALM_VUSR0_MASK		  0x0001 /**< VUSER 3 Supply */

/* Mask for all Alarms in CFR1 and CFR3 */
#define XSM_CFR_ALM_ALL_MASK		  0xF0F0F

/*@}*/

/**
 * @name Alarm masks for channels in Configuration registers 1 and 3
 * @{
 */
#define XSM_CFR_ALM_VUSR3_MASK		0x00080000 /**< VUSER 0 Supply */
#define XSM_CFR_ALM_VUSR2_MASK		0x00040000 /**< VUSER 1 Supply */
#define XSM_CFR_ALM_VUSR1_MASK		0x00020000 /**< VUSER 2 Supply */
#define XSM_CFR_ALM_VUSR0_MASK		0x00010000 /**< VUSER 3 Supply */
#define XSM_CFR_ALM_VCCPDRO_MASK	0x0800 /**< Alarm 6 - VCCPDRO, Zynq */
#define XSM_CFR_ALM_VCCPAUX_MASK	0x0400 /**< Alarm 5 - VCCPAUX, Zynq */
#define XSM_CFR_ALM_VCCPINT_MASK	0x0200 /**< Alarm 4 - VCCPINT, Zynq */
#define XSM_CFR_ALM_VBRAM_MASK	 	0x0100 /**< Alarm 3 - VBRAM Enable
						*  7 Series and Zynq */
#define XSM_CFR_ALM_VCCAUX_MASK	0x0008 /**< Alarm 2 - VCCAUX Enable */
#define XSM_CFR_ALM_VCCINT_MASK	0x0004 /**< Alarm 1 - VCCINT Enable */
#define XSM_CFR_ALM_TEMP_MASK		0x0002 /**< Alarm 0 - Temperature */
#define XSM_CFR_OT_MASK		0x0001 /**< Over Temperature Enable */

/**
 * @name Sequence Register (SEQ) Bit Definitions
 * @{
 */
#define XSM_SEQ_CH_CALIB	0x00000001 /**< ADC Calibration Channel */
#define XSM_SEQ_CH_VCCPINT	0x00000020 /**< VCCPINT, Zynq Only */
#define XSM_SEQ_CH_VCCPAUX	0x00000040 /**< VCCPAUX, Zynq Only */
#define XSM_SEQ_CH_VCCPDRO	0x00000080 /**< VCCPDRO, Zynq Only */
#define XSM_SEQ_CH_TEMP		0x00000100 /**< On Chip Temperature Channel */
#define XSM_SEQ_CH_VCCINT	0x00000200 /**< VCCINT Channel */
#define XSM_SEQ_CH_VCCAUX	0x00000400 /**< VCCAUX Channel */
#define XSM_SEQ_CH_VPVN		0x00000800 /**< VP/VN analog inputs Channel */
#define XSM_SEQ_CH_VREFP	0x00001000 /**< VREFP Channel */
#define XSM_SEQ_CH_VREFN	0x00002000 /**< VREFN Channel */
#define XSM_SEQ_CH_VBRAM	0x00004000 /**< VBRAM Channel, 7 series/Zynq */
#define XSM_SEQ_CH_AUX00	0x00010000 /**< 1st Aux Channel */
#define XSM_SEQ_CH_AUX01	0x00020000 /**< 2nd Aux Channel */
#define XSM_SEQ_CH_AUX02	0x00040000 /**< 3rd Aux Channel */
#define XSM_SEQ_CH_AUX03	0x00080000 /**< 4th Aux Channel */
#define XSM_SEQ_CH_AUX04	0x00100000 /**< 5th Aux Channel */
#define XSM_SEQ_CH_AUX05	0x00200000 /**< 6th Aux Channel */
#define XSM_SEQ_CH_AUX06	0x00400000 /**< 7th Aux Channel */
#define XSM_SEQ_CH_AUX07	0x00800000 /**< 8th Aux Channel */
#define XSM_SEQ_CH_AUX08	0x01000000 /**< 9th Aux Channel */
#define XSM_SEQ_CH_AUX09	0x02000000 /**< 10th Aux Channel */
#define XSM_SEQ_CH_AUX10	0x04000000 /**< 11th Aux Channel */
#define XSM_SEQ_CH_AUX11	0x08000000 /**< 12th Aux Channel */
#define XSM_SEQ_CH_AUX12	0x10000000 /**< 13th Aux Channel */
#define XSM_SEQ_CH_AUX13	0x20000000 /**< 14th Aux Channel */
#define XSM_SEQ_CH_AUX14	0x40000000 /**< 15th Aux Channel */
#define XSM_SEQ_CH_AUX15	0x80000000 /**< 16th Aux Channel */
#define XSM_SEQ_CH_VUSR0	0x100000000 /**<  VUSER0 Channel */
#define XSM_SEQ_CH_VUSR1	0x200000000 /**<  VUSER1 Channel */
#define XSM_SEQ_CH_VUSR2	0x400000000 /**<  VUSER2 Channel */
#define XSM_SEQ_CH_VUSR3	0x800000000 /**<  VUSER3 Channel */

#define XSM_SEQ00_CH_VALID_MASK	0x7FE1 /**< Mask for the valid channels */
#define XSM_SEQ01_CH_VALID_MASK	0xFFFF /**< Mask for the valid channels */

#define XSM_SEQ02_CH_VALID_MASK	0x7FE0 /**< Mask for the valid channels */
#define XSM_SEQ03_CH_VALID_MASK	0xFFFF /**< Mask for the valid channels */

#define XSM_SEQ04_CH_VALID_MASK	0x0800 /**< Mask for the valid channels */
#define XSM_SEQ05_CH_VALID_MASK	0xFFFF /**< Mask for the valid channels */

#define XSM_SEQ06_CH_VALID_MASK	0x0800 /**< Mask for the valid channels */
#define XSM_SEQ07_CH_VALID_MASK	0xFFFF /**< Mask for the valid channels */

#define XSM_SEQ08_CH_VALID_MASK 0x000F /**< Mask for the valid channels */
#define XSM_SEQ09_CH_VALID_MASK 0x000F /**< Mask for the valid channels */

#define XSM_SEQ_CH_AUX_SHIFT	16 /**< Shift for the Aux Channel */

#define XSM_SEQ_CH_VUSR_SHIFT	32 /**< Shift for the Aux Channel */

/*@}*/

/**
 * @name OT Upper Alarm Threshold Register Bit Definitions
 * @{
 */

#define XSM_ATR_OT_UPPER_ENB_MASK	0x000F /**< Mask for OT enable */
#define XSM_ATR_OT_UPPER_VAL_MASK	0xFFF0 /**< Mask for OT value */
#define XSM_ATR_OT_UPPER_VAL_SHIFT	4      /**< Shift for OT value */
#define XSM_ATR_OT_UPPER_ENB_VAL	0x0003 /**< Value for OT enable */
#define XSM_ATR_OT_UPPER_VAL_MAX	0x0FFF /**< Max OT value */

/*@}*/

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/*****************************************************************************/
/**
*
* Read a register of the System Monitor/ADC device. This macro provides register
* access to all registers using the register offsets defined above.
*
* @param	BaseAddress contains the base address of the device.
* @param	RegOffset is the offset of the register to read.
*
* @return	The contents of the register.
*
* @note		C-style Signature:
*		u32 XSysMon_ReadReg(u32 BaseAddress, u32 RegOffset);
*
******************************************************************************/
#define XSysMon_ReadReg(BaseAddress, RegOffset) \
		(Xil_In32((BaseAddress) + (RegOffset)))

/*****************************************************************************/
/**
*
* Write a register of the System Monitor/ADC device. This macro provides
* register access to all registers using the register offsets defined above.
*
* @param	BaseAddress contains the base address of the device.
* @param	RegOffset is the offset of the register to write.
* @param	Data is the value to write to the register.
*
* @return	None.
*
* @note 	C-style Signature:
*		void XSysMon_WriteReg(u32 BaseAddress,
*					u32 RegOffset,u32 Data)
*
******************************************************************************/
#define XSysMon_WriteReg(BaseAddress, RegOffset, Data) \
		(Xil_Out32((BaseAddress) + (RegOffset), (Data)))

/************************** Function Prototypes ******************************/

#ifdef __cplusplus
}
#endif

#endif  /* End of protection macro. */
/** @} */
