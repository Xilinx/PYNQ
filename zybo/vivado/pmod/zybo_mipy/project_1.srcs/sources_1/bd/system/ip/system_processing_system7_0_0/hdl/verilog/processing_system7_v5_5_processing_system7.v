 
//-----------------------------------------------------------------------------
// processing_system7
// processor sub system wrapper
//-----------------------------------------------------------------------------
//
// ************************************************************************
// ** DISCLAIMER OF LIABILITY                                            **
// **                                                                    **
// ** This file contains proprietary and confidential information of     **
// ** Xilinx, Inc. ("Xilinx"), that is distributed under a license       **
// ** from Xilinx, and may be used, copied and/or diSCLosed only         **
// ** pursuant to the terms of a valid license agreement with Xilinx.    **
// **                                                                    **
// ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION              **
// ** ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER         **
// ** EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT                **
// ** LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,          **
// ** MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx      **
// ** does not warrant that functions included in the Materials will     **
// ** meet the requirements of Licensee, or that the operation of the    **
// ** Materials will be uninterrupted or error-free, or that defects     **
// ** in the Materials will be corrected. Furthermore, Xilinx does       **
// ** not warrant or make any representations regarding use, or the      **
// ** results of the use, of the Materials in terms of correctness,      **
// ** accuracy, reliability or otherwise.                                **
// **                                                                    **
// ** Xilinx products are not designed or intended to be fail-safe,      **
// ** or for use in any application requiring fail-safe performance,     **
// ** such as life-support or safety devices or systems, Class III       **
// ** medical devices, nuclear facilities, applications related to       **
// ** the deployment of airbags, or any other applications that could    **
// ** lead to death, personal injury or severe property or               **
// ** environmental damage (individually and collectively, "critical     **
// ** applications"). Customer assumes the sole risk and liability       **
// ** of any use of Xilinx products in critical applications,            **
// ** subject only to applicable laws and regulations governing          **
// ** limitations on product liability.                                  **
// **                                                                    **
// ** Copyright 2010 Xilinx, Inc.                                        **
// ** All rights reserved.                                               **
// **                                                                    **
// ** This disclaimer and copyright notice must be retained as part      **
// ** of this file at all times.                                         **
// ************************************************************************
//
//-----------------------------------------------------------------------------
// Filename:      processing_system7_v5_5_processing_system7.v
// Version:       v1.00.a
// Description:   This is the wrapper file for PSS. 
//-----------------------------------------------------------------------------
// Structure:   This section shows the hierarchical structure of 
//              pss_wrapper.
//
//              --processing_system7_v5_5_processing_system7.v
//                    --PS7.v - Unisim component
//-----------------------------------------------------------------------------
// Author:      SD
//
// History:
//
//  SD      09/20/11      -- First version
// ~~~~~~
// Created the first version v2.00.a
// ^^^^^^
//------------------------------------------------------------------------------
// ^^^^^^
//  SR     11/25/11       -- v3.00.a version
// ~~~~~~~
// Key changes are
// 1. Changed all clock, reset and clktrig ports to be individual
// signals instead of vectors. This is required for modeling of tools.
// 2. Interrupts are now defined as individual signals as well.
// 3. Added Clk buffer logic for FCLK_CLK
// 4. Includes the ACP related changes done
//
// TODO:
// 1. C_NUM_F2P_INTR_INPUTS needs to have control on the
//    number of interrupt ports connected for IRQ_F2P.
// 
//------------------------------------------------------------------------------
// ^^^^^^
//  KP     12/07/11       -- v3.00.a version
// ~~~~~~~
// Key changes are
//  C_NUM_F2P_INTR_INPUTS taken into account for IRQ_F2P
//------------------------------------------------------------------------------
// ^^^^^^
//  NR     12/09/11       -- v3.00.a version
// ~~~~~~~
// Key changes are
//  C_FCLK_CLK0_BUF to C_FCLK_CLK3_BUF parameters were updated 
//  to STRING and fix for CR 640523
//------------------------------------------------------------------------------
// ^^^^^^
//  NR     12/13/11       -- v3.00.a version
// ~~~~~~~
// Key changes are
// Updated IRQ_F2P logic to address CR 641523.
//------------------------------------------------------------------------------
// ^^^^^^
//  NR     02/01/12       -- v3.01.a version
// ~~~~~~~
// Key changes are
// Updated SDIO logic to address CR 636210.
//         |
//         Added C_PS7_SI_REV parameter to track SI Rev
// Removed compress/decompress logic to address CR 642527.
//------------------------------------------------------------------------------
// ^^^^^^
//  NR     02/27/12       -- v3.01.a version
// ~~~~~~~
// Key changes are
// TTC(0,1)_WAVE_OUT and TTC(0,1)_CLK_IN vector signals are made as individual 
// ports as fix for CR 646379
//------------------------------------------------------------------------------
// ^^^^^^
//  NR     03/05/12       -- v3.01.a version
// ~~~~~~~
// Key changes are
// Added/updated compress/decompress logic to address 648393
//------------------------------------------------------------------------------
// ^^^^^^
//  NR     03/14/12       -- v4.00.a version
// ~~~~~~~
// Unused parameters deleted CR 651120
// Addressed CR 651751
//------------------------------------------------------------------------------
// ^^^^^^
//  NR     04/17/12       -- v4.01.a version
// ~~~~~~~
// Added FTM trace buffer functionality
// Added support for ACP AxUSER ports local update
//------------------------------------------------------------------------------
// ^^^^^^
//  VR     05/18/12       -- v4.01.a version
// ~~~~~~~
// Fixed CR#659157
//------------------------------------------------------------------------------
// ^^^^^^
//  VR     07/25/12       -- v4.01.a version
// ~~~~~~~
// Changed S_AXI_HP{1,2}_WACOUNT port's width to 6 from 8 to match unisim model
// Changed fclk_clktrig_gnd width to 4 from 16 to match unisim model
//------------------------------------------------------------------------------
// ^^^^^^
//  VR     11/06/12       -- v5.00 version
// ~~~~~~~
// CR #682573
// Added BIBUF to fixed IO ports and IBUF to fixed input ports
//------------------------------------------------------------------------------
(*POWER= "<PROCESSOR name={system} numA9Cores={2} clockFreq={650} load={0.5} /><MEMORY name={code} memType={DDR3} dataWidth={32} clockFreq={525} readRate={0.5} writeRate={0.5} /><IO interface={UART} ioStandard={LVCMOS18} bidis={2} ioBank={Vcco_p1} clockFreq={100.000000} usageRate={0.5} /><IO interface={SD} ioStandard={LVCMOS18} bidis={7} ioBank={Vcco_p1} clockFreq={50.000000} usageRate={0.5} /><IO interface={GigE} ioStandard={LVCMOS18} bidis={12} ioBank={Vcco_p1} clockFreq={125.000000} usageRate={0.5} /><IO interface={QSPI} ioStandard={LVCMOS33} bidis={7} ioBank={Vcco_p0} clockFreq={200} usageRate={0.5} /><PLL domain={Processor} vco={1300.000} /><PLL domain={Memory} vco={1050.000} /><PLL domain={IO} vco={1000.000} /><AXI interface={M_AXI_GP0} dataWidth={32} clockFreq={100} usageRate={0.5} />/>" *)
(* CORE_GENERATION_INFO = "processing_system7_v5.5 ,processing_system7_v5.5_user_configuration,{ PCW_UIPARAM_DDR_FREQ_MHZ=525, PCW_UIPARAM_DDR_BANK_ADDR_COUNT=3, PCW_UIPARAM_DDR_ROW_ADDR_COUNT=14, PCW_UIPARAM_DDR_COL_ADDR_COUNT=10, PCW_UIPARAM_DDR_CL=7, PCW_UIPARAM_DDR_CWL=6, PCW_UIPARAM_DDR_T_RCD=7, PCW_UIPARAM_DDR_T_RP=7, PCW_UIPARAM_DDR_T_RC=48.75, PCW_UIPARAM_DDR_T_RAS_MIN=35.0, PCW_UIPARAM_DDR_T_FAW=40.0, PCW_UIPARAM_DDR_AL=0, PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0=-0.073, PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1=-0.034, PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2=-0.03, PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3=-0.082, PCW_UIPARAM_DDR_BOARD_DELAY0=0.176, PCW_UIPARAM_DDR_BOARD_DELAY1=0.159, PCW_UIPARAM_DDR_BOARD_DELAY2=0.162, PCW_UIPARAM_DDR_BOARD_DELAY3=0.187, PCW_UIPARAM_DDR_DQS_0_LENGTH_MM=0, PCW_UIPARAM_DDR_DQS_1_LENGTH_MM=0, PCW_UIPARAM_DDR_DQS_2_LENGTH_MM=0, PCW_UIPARAM_DDR_DQS_3_LENGTH_MM=0, PCW_UIPARAM_DDR_DQ_0_LENGTH_MM=0, PCW_UIPARAM_DDR_DQ_1_LENGTH_MM=0, PCW_UIPARAM_DDR_DQ_2_LENGTH_MM=0, PCW_UIPARAM_DDR_DQ_3_LENGTH_MM=0, PCW_UIPARAM_DDR_CLOCK_0_LENGTH_MM=0, PCW_UIPARAM_DDR_CLOCK_1_LENGTH_MM=0, PCW_UIPARAM_DDR_CLOCK_2_LENGTH_MM=0, PCW_UIPARAM_DDR_CLOCK_3_LENGTH_MM=0, PCW_UIPARAM_DDR_DQS_0_PACKAGE_LENGTH=101.239, PCW_UIPARAM_DDR_DQS_1_PACKAGE_LENGTH=79.5025, PCW_UIPARAM_DDR_DQS_2_PACKAGE_LENGTH=60.536, PCW_UIPARAM_DDR_DQS_3_PACKAGE_LENGTH=71.7715, PCW_UIPARAM_DDR_DQ_0_PACKAGE_LENGTH=104.5365, PCW_UIPARAM_DDR_DQ_1_PACKAGE_LENGTH=70.676, PCW_UIPARAM_DDR_DQ_2_PACKAGE_LENGTH=59.1615, PCW_UIPARAM_DDR_DQ_3_PACKAGE_LENGTH=81.319, PCW_UIPARAM_DDR_CLOCK_0_PACKAGE_LENGTH=54.563, PCW_UIPARAM_DDR_CLOCK_1_PACKAGE_LENGTH=54.563, PCW_UIPARAM_DDR_CLOCK_2_PACKAGE_LENGTH=54.563, PCW_UIPARAM_DDR_CLOCK_3_PACKAGE_LENGTH=54.563, PCW_UIPARAM_DDR_DQS_0_PROPOGATION_DELAY=160, PCW_UIPARAM_DDR_DQS_1_PROPOGATION_DELAY=160, PCW_UIPARAM_DDR_DQS_2_PROPOGATION_DELAY=160, PCW_UIPARAM_DDR_DQS_3_PROPOGATION_DELAY=160, PCW_UIPARAM_DDR_DQ_0_PROPOGATION_DELAY=160, PCW_UIPARAM_DDR_DQ_1_PROPOGATION_DELAY=160, PCW_UIPARAM_DDR_DQ_2_PROPOGATION_DELAY=160, PCW_UIPARAM_DDR_DQ_3_PROPOGATION_DELAY=160, PCW_UIPARAM_DDR_CLOCK_0_PROPOGATION_DELAY=160, PCW_UIPARAM_DDR_CLOCK_1_PROPOGATION_DELAY=160, PCW_UIPARAM_DDR_CLOCK_2_PROPOGATION_DELAY=160, PCW_UIPARAM_DDR_CLOCK_3_PROPOGATION_DELAY=160, PCW_CRYSTAL_PERIPHERAL_FREQMHZ=50.000000, PCW_APU_PERIPHERAL_FREQMHZ=650, PCW_DCI_PERIPHERAL_FREQMHZ=10.159, PCW_QSPI_PERIPHERAL_FREQMHZ=200, PCW_SMC_PERIPHERAL_FREQMHZ=100, PCW_USB0_PERIPHERAL_FREQMHZ=60, PCW_USB1_PERIPHERAL_FREQMHZ=60, PCW_SDIO_PERIPHERAL_FREQMHZ=50, PCW_UART_PERIPHERAL_FREQMHZ=100, PCW_SPI_PERIPHERAL_FREQMHZ=166.666666, PCW_CAN_PERIPHERAL_FREQMHZ=100, PCW_CAN0_PERIPHERAL_FREQMHZ=-1, PCW_CAN1_PERIPHERAL_FREQMHZ=-1, PCW_WDT_PERIPHERAL_FREQMHZ=133.333333, PCW_TTC_PERIPHERAL_FREQMHZ=50, PCW_TTC0_CLK0_PERIPHERAL_FREQMHZ=133.333333, PCW_TTC0_CLK1_PERIPHERAL_FREQMHZ=133.333333, PCW_TTC0_CLK2_PERIPHERAL_FREQMHZ=133.333333, PCW_TTC1_CLK0_PERIPHERAL_FREQMHZ=133.333333, PCW_TTC1_CLK1_PERIPHERAL_FREQMHZ=133.333333, PCW_TTC1_CLK2_PERIPHERAL_FREQMHZ=133.333333, PCW_PCAP_PERIPHERAL_FREQMHZ=200, PCW_TPIU_PERIPHERAL_FREQMHZ=200, PCW_FPGA0_PERIPHERAL_FREQMHZ=100, PCW_FPGA1_PERIPHERAL_FREQMHZ=50, PCW_FPGA2_PERIPHERAL_FREQMHZ=50, PCW_FPGA3_PERIPHERAL_FREQMHZ=50, PCW_OVERRIDE_BASIC_CLOCK=0, PCW_ARMPLL_CTRL_FBDIV=26, PCW_IOPLL_CTRL_FBDIV=20, PCW_DDRPLL_CTRL_FBDIV=21, PCW_CPU_CPU_PLL_FREQMHZ=1300.000, PCW_IO_IO_PLL_FREQMHZ=1000.000, PCW_DDR_DDR_PLL_FREQMHZ=1050.000, PCW_USE_M_AXI_GP0=1, PCW_USE_M_AXI_GP1=0, PCW_USE_S_AXI_GP0=0, PCW_USE_S_AXI_GP1=0, PCW_USE_S_AXI_ACP=0, PCW_USE_S_AXI_HP0=0, PCW_USE_S_AXI_HP1=0, PCW_USE_S_AXI_HP2=0, PCW_USE_S_AXI_HP3=0, PCW_M_AXI_GP0_FREQMHZ=100, PCW_M_AXI_GP1_FREQMHZ=10, PCW_S_AXI_GP0_FREQMHZ=10, PCW_S_AXI_GP1_FREQMHZ=10, PCW_S_AXI_ACP_FREQMHZ=10, PCW_S_AXI_HP0_FREQMHZ=10, PCW_S_AXI_HP1_FREQMHZ=10, PCW_S_AXI_HP2_FREQMHZ=10, PCW_S_AXI_HP3_FREQMHZ=10, PCW_USE_CROSS_TRIGGER=0, PCW_FTM_CTI_IN0=DISABLED, PCW_FTM_CTI_IN1=DISABLED, PCW_FTM_CTI_IN2=DISABLED, PCW_FTM_CTI_IN3=DISABLED, PCW_FTM_CTI_OUT0=DISABLED, PCW_FTM_CTI_OUT1=DISABLED, PCW_FTM_CTI_OUT2=DISABLED, PCW_FTM_CTI_OUT3=DISABLED, PCW_UART0_BAUD_RATE=115200, PCW_UART1_BAUD_RATE=115200, PCW_S_AXI_HP0_DATA_WIDTH=64, PCW_S_AXI_HP1_DATA_WIDTH=64, PCW_S_AXI_HP2_DATA_WIDTH=64, PCW_S_AXI_HP3_DATA_WIDTH=64, PCW_IRQ_F2P_MODE=DIRECT, PCW_PRESET_BANK0_VOLTAGE=LVCMOS 3.3V, PCW_PRESET_BANK1_VOLTAGE=LVCMOS 1.8V, PCW_UIPARAM_DDR_ENABLE=1, PCW_UIPARAM_DDR_ADV_ENABLE=0, PCW_UIPARAM_DDR_MEMORY_TYPE=DDR 3, PCW_UIPARAM_DDR_ECC=Disabled, PCW_UIPARAM_DDR_BUS_WIDTH=32 Bit, PCW_UIPARAM_DDR_BL=8, PCW_UIPARAM_DDR_HIGH_TEMP=Normal (0-85), PCW_UIPARAM_DDR_PARTNO=MT41K128M16 JT-125, PCW_UIPARAM_DDR_DRAM_WIDTH=16 Bits, PCW_UIPARAM_DDR_DEVICE_CAPACITY=2048 MBits, PCW_UIPARAM_DDR_SPEED_BIN=DDR3_1066F, PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL=1, PCW_UIPARAM_DDR_TRAIN_READ_GATE=1, PCW_UIPARAM_DDR_TRAIN_DATA_EYE=1, PCW_UIPARAM_DDR_CLOCK_STOP_EN=0, PCW_UIPARAM_DDR_USE_INTERNAL_VREF=0, PCW_DDR_PORT0_HPR_ENABLE=0, PCW_DDR_PORT1_HPR_ENABLE=0, PCW_DDR_PORT2_HPR_ENABLE=0, PCW_DDR_PORT3_HPR_ENABLE=0, PCW_DDR_HPRLPR_QUEUE_PARTITION=HPR(0)/LPR(32), PCW_DDR_LPR_TO_CRITICAL_PRIORITY_LEVEL=2, PCW_DDR_HPR_TO_CRITICAL_PRIORITY_LEVEL=15, PCW_DDR_WRITE_TO_CRITICAL_PRIORITY_LEVEL=2, PCW_NAND_PERIPHERAL_ENABLE=0, PCW_NAND_GRP_D8_ENABLE=0, PCW_NOR_PERIPHERAL_ENABLE=0, PCW_NOR_GRP_A25_ENABLE=0, PCW_NOR_GRP_CS0_ENABLE=0, PCW_NOR_GRP_SRAM_CS0_ENABLE=0, PCW_NOR_GRP_CS1_ENABLE=0, PCW_NOR_GRP_SRAM_CS1_ENABLE=0, PCW_NOR_GRP_SRAM_INT_ENABLE=0, PCW_QSPI_PERIPHERAL_ENABLE=1, PCW_QSPI_QSPI_IO=MIO 1 .. 6, PCW_QSPI_GRP_SINGLE_SS_ENABLE=1, PCW_QSPI_GRP_SINGLE_SS_IO=MIO 1 .. 6, PCW_QSPI_GRP_SS1_ENABLE=0, PCW_QSPI_GRP_IO1_ENABLE=0, PCW_QSPI_GRP_FBCLK_ENABLE=1, PCW_QSPI_GRP_FBCLK_IO=MIO 8, PCW_QSPI_INTERNAL_HIGHADDRESS=0xFCFFFFFF, PCW_ENET0_PERIPHERAL_ENABLE=1, PCW_ENET0_ENET0_IO=MIO 16 .. 27, PCW_ENET0_GRP_MDIO_ENABLE=0, PCW_ENET0_RESET_ENABLE=0, PCW_ENET1_PERIPHERAL_ENABLE=0, PCW_ENET1_GRP_MDIO_ENABLE=0, PCW_ENET1_RESET_ENABLE=0, PCW_SD0_PERIPHERAL_ENABLE=1, PCW_SD0_SD0_IO=MIO 40 .. 45, PCW_SD0_GRP_CD_ENABLE=1, PCW_SD0_GRP_CD_IO=MIO 47, PCW_SD0_GRP_WP_ENABLE=1, PCW_SD0_GRP_WP_IO=EMIO, PCW_SD0_GRP_POW_ENABLE=0, PCW_SD1_PERIPHERAL_ENABLE=0, PCW_SD1_GRP_CD_ENABLE=0, PCW_SD1_GRP_WP_ENABLE=0, PCW_SD1_GRP_POW_ENABLE=0, PCW_UART0_PERIPHERAL_ENABLE=0, PCW_UART0_GRP_FULL_ENABLE=0, PCW_UART1_PERIPHERAL_ENABLE=1, PCW_UART1_UART1_IO=MIO 48 .. 49, PCW_UART1_GRP_FULL_ENABLE=0, PCW_SPI0_PERIPHERAL_ENABLE=0, PCW_SPI0_GRP_SS0_ENABLE=0, PCW_SPI0_GRP_SS1_ENABLE=0, PCW_SPI0_GRP_SS2_ENABLE=0, PCW_SPI1_PERIPHERAL_ENABLE=0, PCW_SPI1_GRP_SS0_ENABLE=0, PCW_SPI1_GRP_SS1_ENABLE=0, PCW_SPI1_GRP_SS2_ENABLE=0, PCW_CAN0_PERIPHERAL_ENABLE=0, PCW_CAN0_GRP_CLK_ENABLE=0, PCW_CAN1_PERIPHERAL_ENABLE=0, PCW_CAN1_GRP_CLK_ENABLE=0, PCW_TRACE_PERIPHERAL_ENABLE=0, PCW_TRACE_GRP_2BIT_ENABLE=0, PCW_TRACE_GRP_4BIT_ENABLE=0, PCW_TRACE_GRP_8BIT_ENABLE=0, PCW_TRACE_GRP_16BIT_ENABLE=0, PCW_TRACE_GRP_32BIT_ENABLE=0, PCW_WDT_PERIPHERAL_ENABLE=0, PCW_TTC0_PERIPHERAL_ENABLE=0, PCW_TTC1_PERIPHERAL_ENABLE=0, PCW_PJTAG_PERIPHERAL_ENABLE=0, PCW_USB0_PERIPHERAL_ENABLE=0, PCW_USB0_RESET_ENABLE=0, PCW_USB1_PERIPHERAL_ENABLE=0, PCW_USB1_RESET_ENABLE=0, PCW_I2C0_PERIPHERAL_ENABLE=0, PCW_I2C0_GRP_INT_ENABLE=0, PCW_I2C0_RESET_ENABLE=0, PCW_I2C1_PERIPHERAL_ENABLE=0, PCW_I2C1_GRP_INT_ENABLE=0, PCW_I2C1_RESET_ENABLE=0, PCW_GPIO_PERIPHERAL_ENABLE=0, PCW_GPIO_MIO_GPIO_ENABLE=0, PCW_GPIO_EMIO_GPIO_ENABLE=1, PCW_GPIO_EMIO_GPIO_IO=6, PCW_APU_CLK_RATIO_ENABLE=6:2:1, PCW_ENET0_PERIPHERAL_FREQMHZ=1000 Mbps, PCW_ENET1_PERIPHERAL_FREQMHZ=1000 Mbps, PCW_CPU_PERIPHERAL_CLKSRC=ARM PLL, PCW_DDR_PERIPHERAL_CLKSRC=DDR PLL, PCW_SMC_PERIPHERAL_CLKSRC=IO PLL, PCW_QSPI_PERIPHERAL_CLKSRC=IO PLL, PCW_SDIO_PERIPHERAL_CLKSRC=IO PLL, PCW_UART_PERIPHERAL_CLKSRC=IO PLL, PCW_SPI_PERIPHERAL_CLKSRC=IO PLL, PCW_CAN_PERIPHERAL_CLKSRC=IO PLL, PCW_FCLK0_PERIPHERAL_CLKSRC=IO PLL, PCW_FCLK1_PERIPHERAL_CLKSRC=IO PLL, PCW_FCLK2_PERIPHERAL_CLKSRC=IO PLL, PCW_FCLK3_PERIPHERAL_CLKSRC=IO PLL, PCW_ENET0_PERIPHERAL_CLKSRC=IO PLL, PCW_ENET1_PERIPHERAL_CLKSRC=IO PLL, PCW_CAN0_PERIPHERAL_CLKSRC=External, PCW_CAN1_PERIPHERAL_CLKSRC=External, PCW_TPIU_PERIPHERAL_CLKSRC=External, PCW_TTC0_CLK0_PERIPHERAL_CLKSRC=CPU_1X, PCW_TTC0_CLK1_PERIPHERAL_CLKSRC=CPU_1X, PCW_TTC0_CLK2_PERIPHERAL_CLKSRC=CPU_1X, PCW_TTC1_CLK0_PERIPHERAL_CLKSRC=CPU_1X, PCW_TTC1_CLK1_PERIPHERAL_CLKSRC=CPU_1X, PCW_TTC1_CLK2_PERIPHERAL_CLKSRC=CPU_1X, PCW_WDT_PERIPHERAL_CLKSRC=CPU_1X, PCW_DCI_PERIPHERAL_CLKSRC=DDR PLL, PCW_PCAP_PERIPHERAL_CLKSRC=IO PLL, PCW_USB_RESET_POLARITY=Active Low, PCW_ENET_RESET_POLARITY=Active Low, PCW_I2C_RESET_POLARITY=Active Low, PCW_FPGA_FCLK0_ENABLE=1, PCW_FPGA_FCLK1_ENABLE=0, PCW_FPGA_FCLK2_ENABLE=0, PCW_FPGA_FCLK3_ENABLE=0, PCW_NOR_SRAM_CS0_T_TR=1, PCW_NOR_SRAM_CS0_T_PC=1, PCW_NOR_SRAM_CS0_T_WP=1, PCW_NOR_SRAM_CS0_T_CEOE=1, PCW_NOR_SRAM_CS0_T_WC=11, PCW_NOR_SRAM_CS0_T_RC=11, PCW_NOR_SRAM_CS0_WE_TIME=0, PCW_NOR_SRAM_CS1_T_TR=1, PCW_NOR_SRAM_CS1_T_PC=1, PCW_NOR_SRAM_CS1_T_WP=1, PCW_NOR_SRAM_CS1_T_CEOE=1, PCW_NOR_SRAM_CS1_T_WC=11, PCW_NOR_SRAM_CS1_T_RC=11, PCW_NOR_SRAM_CS1_WE_TIME=0, PCW_NOR_CS0_T_TR=1, PCW_NOR_CS0_T_PC=1, PCW_NOR_CS0_T_WP=1, PCW_NOR_CS0_T_CEOE=1, PCW_NOR_CS0_T_WC=11, PCW_NOR_CS0_T_RC=11, PCW_NOR_CS0_WE_TIME=0, PCW_NOR_CS1_T_TR=1, PCW_NOR_CS1_T_PC=1, PCW_NOR_CS1_T_WP=1, PCW_NOR_CS1_T_CEOE=1, PCW_NOR_CS1_T_WC=11, PCW_NOR_CS1_T_RC=11, PCW_NOR_CS1_WE_TIME=0, PCW_NAND_CYCLES_T_RR=1, PCW_NAND_CYCLES_T_AR=1, PCW_NAND_CYCLES_T_CLR=1, PCW_NAND_CYCLES_T_WP=1, PCW_NAND_CYCLES_T_REA=1, PCW_NAND_CYCLES_T_WC=11, PCW_NAND_CYCLES_T_RC=11 }" *)  
(* HW_HANDOFF = "system_processing_system7_0_0.hwdef" *)  

module processing_system7_v5_5_processing_system7

#(
  parameter integer C_USE_DEFAULT_ACP_USER_VAL = 1,
  parameter integer C_S_AXI_ACP_ARUSER_VAL = 31,
  parameter integer C_S_AXI_ACP_AWUSER_VAL = 31,
  parameter integer C_M_AXI_GP0_THREAD_ID_WIDTH = 12,
  parameter integer C_M_AXI_GP1_THREAD_ID_WIDTH = 12, 
  parameter integer C_M_AXI_GP0_ENABLE_STATIC_REMAP = 1,
  parameter integer C_M_AXI_GP1_ENABLE_STATIC_REMAP = 1, 
  parameter integer C_M_AXI_GP0_ID_WIDTH = 12,
  parameter integer C_M_AXI_GP1_ID_WIDTH = 12,
  parameter integer C_S_AXI_GP0_ID_WIDTH = 6,
  parameter integer C_S_AXI_GP1_ID_WIDTH = 6,
  parameter integer C_S_AXI_HP0_ID_WIDTH = 6,
  parameter integer C_S_AXI_HP1_ID_WIDTH = 6,
  parameter integer C_S_AXI_HP2_ID_WIDTH = 6,
  parameter integer C_S_AXI_HP3_ID_WIDTH = 6,
  parameter integer C_S_AXI_ACP_ID_WIDTH = 3,
  parameter integer C_S_AXI_HP0_DATA_WIDTH = 64,
  parameter integer C_S_AXI_HP1_DATA_WIDTH = 64,
  parameter integer C_S_AXI_HP2_DATA_WIDTH = 64,
  parameter integer C_S_AXI_HP3_DATA_WIDTH = 64,
  parameter integer C_INCLUDE_ACP_TRANS_CHECK = 0,
  parameter integer C_NUM_F2P_INTR_INPUTS = 1,
  parameter         C_FCLK_CLK0_BUF = "TRUE",
  parameter         C_FCLK_CLK1_BUF = "TRUE",
  parameter         C_FCLK_CLK2_BUF = "TRUE",
  parameter         C_FCLK_CLK3_BUF = "TRUE",
  parameter integer C_EMIO_GPIO_WIDTH = 64,
  parameter integer C_INCLUDE_TRACE_BUFFER = 0,
  parameter integer C_TRACE_BUFFER_FIFO_SIZE = 128,
  parameter integer C_TRACE_BUFFER_CLOCK_DELAY = 12,
  parameter integer USE_TRACE_DATA_EDGE_DETECTOR = 0,
  parameter integer C_TRACE_PIPELINE_WIDTH = 8,
  parameter         C_PS7_SI_REV = "PRODUCTION",
  parameter integer C_EN_EMIO_ENET0 = 0,
  parameter integer C_EN_EMIO_ENET1 = 0,
  parameter integer C_EN_EMIO_TRACE = 0,
  parameter integer C_DQ_WIDTH = 32,
  parameter integer C_DQS_WIDTH = 4,
  parameter integer C_DM_WIDTH = 4,
  parameter integer C_MIO_PRIMITIVE = 54,
  parameter	    C_PACKAGE_NAME = "clg484",
  parameter C_IRQ_F2P_MODE = "DIRECT",
  parameter C_TRACE_INTERNAL_WIDTH = 32,
  parameter integer C_EN_EMIO_PJTAG = 0,
  
  // Enable and disable AFI Secure transaction 
  parameter C_USE_AXI_NONSECURE = 0,
  
  //parameters for HP enable ports 
  parameter C_USE_S_AXI_HP0 = 0,
  parameter C_USE_S_AXI_HP1 = 0,
  parameter C_USE_S_AXI_HP2 = 0,
  parameter C_USE_S_AXI_HP3 = 0,
  
  //parameters for GP and ACP enable ports */
  parameter C_USE_M_AXI_GP0 = 0,
  parameter C_USE_M_AXI_GP1 = 0,
  parameter C_USE_S_AXI_GP0 = 0,
  parameter C_USE_S_AXI_GP1 = 0,
  parameter C_USE_S_AXI_ACP = 0
   
)
(
  //FMIO =========================================
  
  //FMIO CAN0
  output          CAN0_PHY_TX,
  input           CAN0_PHY_RX,

  //FMIO CAN1
  output          CAN1_PHY_TX,  
  input           CAN1_PHY_RX,
  
  //FMIO ENET0
  output  reg     ENET0_GMII_TX_EN = 'b0,
  output  reg     ENET0_GMII_TX_ER = 'b0,
  output          ENET0_MDIO_MDC,
  output          ENET0_MDIO_O,
  output          ENET0_MDIO_T,
  output          ENET0_PTP_DELAY_REQ_RX,
  output          ENET0_PTP_DELAY_REQ_TX,
  output          ENET0_PTP_PDELAY_REQ_RX,
  output          ENET0_PTP_PDELAY_REQ_TX,
  output          ENET0_PTP_PDELAY_RESP_RX,
  output          ENET0_PTP_PDELAY_RESP_TX,
  output          ENET0_PTP_SYNC_FRAME_RX,
  output          ENET0_PTP_SYNC_FRAME_TX,
  output          ENET0_SOF_RX,
  output          ENET0_SOF_TX,
  
  
  output  reg [7:0]    ENET0_GMII_TXD,  

  
  input           ENET0_GMII_COL,
  input           ENET0_GMII_CRS,
  input           ENET0_GMII_RX_CLK,
  input           ENET0_GMII_RX_DV,
  input           ENET0_GMII_RX_ER,
  input           ENET0_GMII_TX_CLK,
  input           ENET0_MDIO_I,
  input           ENET0_EXT_INTIN,
  input [7:0]     ENET0_GMII_RXD,  

  //FMIO ENET1
  output   reg    ENET1_GMII_TX_EN = 'b0,
  output   reg    ENET1_GMII_TX_ER = 'b0,
  output          ENET1_MDIO_MDC,
  output          ENET1_MDIO_O,
  output          ENET1_MDIO_T,
  output          ENET1_PTP_DELAY_REQ_RX,
  output          ENET1_PTP_DELAY_REQ_TX,
  output          ENET1_PTP_PDELAY_REQ_RX,
  output          ENET1_PTP_PDELAY_REQ_TX,
  output          ENET1_PTP_PDELAY_RESP_RX,
  output          ENET1_PTP_PDELAY_RESP_TX,
  output          ENET1_PTP_SYNC_FRAME_RX,
  output          ENET1_PTP_SYNC_FRAME_TX,
  output          ENET1_SOF_RX,
  output          ENET1_SOF_TX,
  output reg [7:0]    ENET1_GMII_TXD,  

  input          ENET1_GMII_COL,
  input          ENET1_GMII_CRS,
  input          ENET1_GMII_RX_CLK,
  input          ENET1_GMII_RX_DV,
  input          ENET1_GMII_RX_ER,
  input          ENET1_GMII_TX_CLK,
  input          ENET1_MDIO_I,
  input          ENET1_EXT_INTIN,  
  input [7:0]    ENET1_GMII_RXD,
  
  //FMIO GPIO
  input    [(C_EMIO_GPIO_WIDTH-1):0] GPIO_I,
  output   [(C_EMIO_GPIO_WIDTH-1):0] GPIO_O,
  output   [(C_EMIO_GPIO_WIDTH-1):0] GPIO_T,  
  
  //FMIO I2C0
  input           I2C0_SDA_I,
  output          I2C0_SDA_O,
  output          I2C0_SDA_T,
  input           I2C0_SCL_I,
  output          I2C0_SCL_O,
  output          I2C0_SCL_T,

  //FMIO I2C1
  input           I2C1_SDA_I,
  output          I2C1_SDA_O,
  output          I2C1_SDA_T,
  input           I2C1_SCL_I,
  output          I2C1_SCL_O,
  output          I2C1_SCL_T,
  
  //FMIO PJTAG
  input           PJTAG_TCK,
  input           PJTAG_TMS,
  input           PJTAG_TDI,
  output          PJTAG_TDO,

  
  //FMIO SDIO0
  output          SDIO0_CLK,
  input           SDIO0_CLK_FB,
  output          SDIO0_CMD_O,
  input           SDIO0_CMD_I,
  output          SDIO0_CMD_T,
  input     [3:0] SDIO0_DATA_I,
  output    [3:0] SDIO0_DATA_O,
  output    [3:0] SDIO0_DATA_T,
  output          SDIO0_LED,
  input           SDIO0_CDN,
  input           SDIO0_WP,  
  output          SDIO0_BUSPOW,
  output    [2:0] SDIO0_BUSVOLT,

  //FMIO SDIO1
  output          SDIO1_CLK,
  input           SDIO1_CLK_FB,
  output          SDIO1_CMD_O,
  input           SDIO1_CMD_I,
  output          SDIO1_CMD_T,
  input     [3:0] SDIO1_DATA_I,
  output    [3:0] SDIO1_DATA_O,
  output    [3:0] SDIO1_DATA_T,  
  output          SDIO1_LED,
  input           SDIO1_CDN,  
  input           SDIO1_WP,
  output          SDIO1_BUSPOW,  
  output    [2:0] SDIO1_BUSVOLT,

  //FMIO SPI0
  input           SPI0_SCLK_I,
  output          SPI0_SCLK_O,
  output          SPI0_SCLK_T,
  input           SPI0_MOSI_I,
  output          SPI0_MOSI_O,
  output          SPI0_MOSI_T,
  input           SPI0_MISO_I,
  output          SPI0_MISO_O,
  output          SPI0_MISO_T,
  input           SPI0_SS_I,
  output          SPI0_SS_O,
  output          SPI0_SS1_O,
  output          SPI0_SS2_O,
  output          SPI0_SS_T,

  //FMIO SPI1
  input           SPI1_SCLK_I,
  output          SPI1_SCLK_O,
  output          SPI1_SCLK_T,
  input           SPI1_MOSI_I,
  output          SPI1_MOSI_O,
  output          SPI1_MOSI_T,
  input           SPI1_MISO_I,
  output          SPI1_MISO_O,
  output          SPI1_MISO_T,
  input           SPI1_SS_I,
  output          SPI1_SS_O,
  output          SPI1_SS1_O,
  output          SPI1_SS2_O,  
  output          SPI1_SS_T,

  //FMIO UART0
  output          UART0_DTRN,
  output          UART0_RTSN,  
  output          UART0_TX,
  input           UART0_CTSN,
  input           UART0_DCDN,
  input           UART0_DSRN,
  input           UART0_RIN,  
  input           UART0_RX,

  //FMIO UART1
  output          UART1_DTRN,
  output          UART1_RTSN,  
  output          UART1_TX,
  input           UART1_CTSN,
  input           UART1_DCDN,
  input           UART1_DSRN,
  input           UART1_RIN,  
  input           UART1_RX,

  //FMIO TTC0
  output    		TTC0_WAVE0_OUT,
  output    		TTC0_WAVE1_OUT,
  output    		TTC0_WAVE2_OUT,
  input     		TTC0_CLK0_IN,
  input     		TTC0_CLK1_IN,
  input     		TTC0_CLK2_IN,

  //FMIO TTC1
  output    		TTC1_WAVE0_OUT,
  output    		TTC1_WAVE1_OUT,
  output    		TTC1_WAVE2_OUT,
  input     		TTC1_CLK0_IN,
  input     		TTC1_CLK1_IN,
  input     		TTC1_CLK2_IN,

  //WDT
  input           WDT_CLK_IN,
  output          WDT_RST_OUT,

  //FTPORT
  input           TRACE_CLK,
  output          TRACE_CTL,
  output   [(C_TRACE_INTERNAL_WIDTH)-1:0] TRACE_DATA,
  output   reg		  TRACE_CLK_OUT,
  
  // USB
  output   [1:0]  USB0_PORT_INDCTL,
  output          USB0_VBUS_PWRSELECT,
  input           USB0_VBUS_PWRFAULT,

  output   [1:0]  USB1_PORT_INDCTL,
  output          USB1_VBUS_PWRSELECT,
  input           USB1_VBUS_PWRFAULT,
  
  input           SRAM_INTIN,

  //AIO ===================================================

  //M_AXI_GP0
  
  // -- Output
  
  output M_AXI_GP0_ARESETN,
  output M_AXI_GP0_ARVALID,
  output M_AXI_GP0_AWVALID,
  output M_AXI_GP0_BREADY,
  output M_AXI_GP0_RREADY,
  output M_AXI_GP0_WLAST,
  output M_AXI_GP0_WVALID,
  output [(C_M_AXI_GP0_THREAD_ID_WIDTH - 1):0] M_AXI_GP0_ARID,
  output [(C_M_AXI_GP0_THREAD_ID_WIDTH - 1):0] M_AXI_GP0_AWID,
  output [(C_M_AXI_GP0_THREAD_ID_WIDTH - 1):0] M_AXI_GP0_WID,
  output [1:0] M_AXI_GP0_ARBURST,
  output [1:0] M_AXI_GP0_ARLOCK,
  output [2:0] M_AXI_GP0_ARSIZE,
  output [1:0] M_AXI_GP0_AWBURST,
  output [1:0] M_AXI_GP0_AWLOCK,
  output [2:0] M_AXI_GP0_AWSIZE,
  output [2:0] M_AXI_GP0_ARPROT,
  output [2:0] M_AXI_GP0_AWPROT,
  output [31:0] M_AXI_GP0_ARADDR,
  output [31:0] M_AXI_GP0_AWADDR,
  output [31:0] M_AXI_GP0_WDATA,
  output [3:0] M_AXI_GP0_ARCACHE,
  output [3:0] M_AXI_GP0_ARLEN,
  output [3:0] M_AXI_GP0_ARQOS,
  output [3:0] M_AXI_GP0_AWCACHE,
  output [3:0] M_AXI_GP0_AWLEN,
  output [3:0] M_AXI_GP0_AWQOS,
  output [3:0] M_AXI_GP0_WSTRB, 
  
  // -- Input  
  
  input M_AXI_GP0_ACLK,
  input M_AXI_GP0_ARREADY,
  input M_AXI_GP0_AWREADY,
  input M_AXI_GP0_BVALID,
  input M_AXI_GP0_RLAST,
  input M_AXI_GP0_RVALID,
  input M_AXI_GP0_WREADY,
  input [(C_M_AXI_GP0_THREAD_ID_WIDTH - 1):0] M_AXI_GP0_BID,
  input [(C_M_AXI_GP0_THREAD_ID_WIDTH - 1):0] M_AXI_GP0_RID,
  input [1:0] M_AXI_GP0_BRESP,
  input [1:0] M_AXI_GP0_RRESP,
  input [31:0] M_AXI_GP0_RDATA,  


  //M_AXI_GP1
  
  // -- Output

  output M_AXI_GP1_ARESETN,
  output M_AXI_GP1_ARVALID,
  output M_AXI_GP1_AWVALID,
  output M_AXI_GP1_BREADY,
  output M_AXI_GP1_RREADY,
  output M_AXI_GP1_WLAST,
  output M_AXI_GP1_WVALID,
  output [(C_M_AXI_GP1_THREAD_ID_WIDTH - 1):0] M_AXI_GP1_ARID,
  output [(C_M_AXI_GP1_THREAD_ID_WIDTH - 1):0] M_AXI_GP1_AWID,
  output [(C_M_AXI_GP1_THREAD_ID_WIDTH - 1):0] M_AXI_GP1_WID,
  output [1:0] M_AXI_GP1_ARBURST,
  output [1:0] M_AXI_GP1_ARLOCK,
  output [2:0] M_AXI_GP1_ARSIZE,
  output [1:0] M_AXI_GP1_AWBURST,
  output [1:0] M_AXI_GP1_AWLOCK,
  output [2:0] M_AXI_GP1_AWSIZE,
  output [2:0] M_AXI_GP1_ARPROT,
  output [2:0] M_AXI_GP1_AWPROT,
  output [31:0] M_AXI_GP1_ARADDR,
  output [31:0] M_AXI_GP1_AWADDR,
  output [31:0] M_AXI_GP1_WDATA,
  output [3:0] M_AXI_GP1_ARCACHE,
  output [3:0] M_AXI_GP1_ARLEN,
  output [3:0] M_AXI_GP1_ARQOS,
  output [3:0] M_AXI_GP1_AWCACHE,
  output [3:0] M_AXI_GP1_AWLEN,
  output [3:0] M_AXI_GP1_AWQOS,
  output [3:0] M_AXI_GP1_WSTRB,
  
  // -- Input
  
  input M_AXI_GP1_ACLK,
  input M_AXI_GP1_ARREADY,
  input M_AXI_GP1_AWREADY,
  input M_AXI_GP1_BVALID,
  input M_AXI_GP1_RLAST,
  input M_AXI_GP1_RVALID,
  input M_AXI_GP1_WREADY,  
  input [(C_M_AXI_GP1_THREAD_ID_WIDTH - 1):0] M_AXI_GP1_BID,
  input [(C_M_AXI_GP1_THREAD_ID_WIDTH - 1):0] M_AXI_GP1_RID,
  input [1:0] M_AXI_GP1_BRESP,
  input [1:0] M_AXI_GP1_RRESP,
  input [31:0] M_AXI_GP1_RDATA,  
  

  // S_AXI_GP0
  
  // -- Output
  
  output S_AXI_GP0_ARESETN,
  output S_AXI_GP0_ARREADY,
  output S_AXI_GP0_AWREADY,
  output S_AXI_GP0_BVALID,
  output S_AXI_GP0_RLAST,
  output S_AXI_GP0_RVALID,
  output S_AXI_GP0_WREADY,  
  output [1:0] S_AXI_GP0_BRESP,
  output [1:0] S_AXI_GP0_RRESP,
  output [31:0] S_AXI_GP0_RDATA,
  output [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] S_AXI_GP0_BID,
  output [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] S_AXI_GP0_RID,
  
  // -- Input
  input S_AXI_GP0_ACLK,
  input S_AXI_GP0_ARVALID,
  input S_AXI_GP0_AWVALID,
  input S_AXI_GP0_BREADY,
  input S_AXI_GP0_RREADY,
  input S_AXI_GP0_WLAST,
  input S_AXI_GP0_WVALID,
  input [1:0] S_AXI_GP0_ARBURST,
  input [1:0] S_AXI_GP0_ARLOCK,
  input [2:0] S_AXI_GP0_ARSIZE,
  input [1:0] S_AXI_GP0_AWBURST,
  input [1:0] S_AXI_GP0_AWLOCK,
  input [2:0] S_AXI_GP0_AWSIZE,
  input [2:0] S_AXI_GP0_ARPROT,
  input [2:0] S_AXI_GP0_AWPROT,
  input [31:0] S_AXI_GP0_ARADDR,
  input [31:0] S_AXI_GP0_AWADDR,
  input [31:0] S_AXI_GP0_WDATA,
  input [3:0] S_AXI_GP0_ARCACHE,
  input [3:0] S_AXI_GP0_ARLEN,
  input [3:0] S_AXI_GP0_ARQOS,
  input [3:0] S_AXI_GP0_AWCACHE,
  input [3:0] S_AXI_GP0_AWLEN,
  input [3:0] S_AXI_GP0_AWQOS,
  input [3:0] S_AXI_GP0_WSTRB,
  input [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] S_AXI_GP0_ARID,
  input [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] S_AXI_GP0_AWID,
  input [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] S_AXI_GP0_WID,  

  // S_AXI_GP1
  
  // -- Output  
  output S_AXI_GP1_ARESETN,
  output S_AXI_GP1_ARREADY,
  output S_AXI_GP1_AWREADY,
  output S_AXI_GP1_BVALID,
  output S_AXI_GP1_RLAST,
  output S_AXI_GP1_RVALID,
  output S_AXI_GP1_WREADY,  
  output [1:0] S_AXI_GP1_BRESP,
  output [1:0] S_AXI_GP1_RRESP,
  output [31:0] S_AXI_GP1_RDATA,
  output [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] S_AXI_GP1_BID,
  output [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] S_AXI_GP1_RID,
  
  // -- Input
  input S_AXI_GP1_ACLK,
  input S_AXI_GP1_ARVALID,
  input S_AXI_GP1_AWVALID,
  input S_AXI_GP1_BREADY,
  input S_AXI_GP1_RREADY,
  input S_AXI_GP1_WLAST,
  input S_AXI_GP1_WVALID,
  input [1:0] S_AXI_GP1_ARBURST,
  input [1:0] S_AXI_GP1_ARLOCK,
  input [2:0] S_AXI_GP1_ARSIZE,
  input [1:0] S_AXI_GP1_AWBURST,
  input [1:0] S_AXI_GP1_AWLOCK,
  input [2:0] S_AXI_GP1_AWSIZE,
  input [2:0] S_AXI_GP1_ARPROT,
  input [2:0] S_AXI_GP1_AWPROT,
  input [31:0] S_AXI_GP1_ARADDR,
  input [31:0] S_AXI_GP1_AWADDR,
  input [31:0] S_AXI_GP1_WDATA,
  input [3:0] S_AXI_GP1_ARCACHE,
  input [3:0] S_AXI_GP1_ARLEN,
  input [3:0] S_AXI_GP1_ARQOS,
  input [3:0] S_AXI_GP1_AWCACHE,
  input [3:0] S_AXI_GP1_AWLEN,
  input [3:0] S_AXI_GP1_AWQOS,
  input [3:0] S_AXI_GP1_WSTRB,
  input [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] S_AXI_GP1_ARID,
  input [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] S_AXI_GP1_AWID,
  input [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] S_AXI_GP1_WID,  

  //S_AXI_ACP
  
  // -- Output  
  
  output S_AXI_ACP_ARESETN,
  output S_AXI_ACP_ARREADY,
  output S_AXI_ACP_AWREADY,
  output S_AXI_ACP_BVALID,
  output S_AXI_ACP_RLAST,
  output S_AXI_ACP_RVALID,
  output S_AXI_ACP_WREADY,  
  output [1:0] S_AXI_ACP_BRESP,
  output [1:0] S_AXI_ACP_RRESP,
  output [(C_S_AXI_ACP_ID_WIDTH - 1) : 0] S_AXI_ACP_BID,
  output [(C_S_AXI_ACP_ID_WIDTH - 1) : 0] S_AXI_ACP_RID,
  output [63:0] S_AXI_ACP_RDATA,
  
  // -- Input
  
  input S_AXI_ACP_ACLK,
  input S_AXI_ACP_ARVALID,
  input S_AXI_ACP_AWVALID,
  input S_AXI_ACP_BREADY,
  input S_AXI_ACP_RREADY,
  input S_AXI_ACP_WLAST,
  input S_AXI_ACP_WVALID,
  input [(C_S_AXI_ACP_ID_WIDTH - 1) : 0] S_AXI_ACP_ARID,
  input [2:0] S_AXI_ACP_ARPROT,
  input [(C_S_AXI_ACP_ID_WIDTH - 1) : 0] S_AXI_ACP_AWID,
  input [2:0] S_AXI_ACP_AWPROT,
  input [(C_S_AXI_ACP_ID_WIDTH - 1) : 0] S_AXI_ACP_WID,
  input [31:0] S_AXI_ACP_ARADDR,
  input [31:0] S_AXI_ACP_AWADDR,
  input [3:0] S_AXI_ACP_ARCACHE,
  input [3:0] S_AXI_ACP_ARLEN,
  input [3:0] S_AXI_ACP_ARQOS,
  input [3:0] S_AXI_ACP_AWCACHE,
  input [3:0] S_AXI_ACP_AWLEN,
  input [3:0] S_AXI_ACP_AWQOS,  
  input [1:0] S_AXI_ACP_ARBURST,
  input [1:0] S_AXI_ACP_ARLOCK,
  input [2:0] S_AXI_ACP_ARSIZE,
  input [1:0] S_AXI_ACP_AWBURST,
  input [1:0] S_AXI_ACP_AWLOCK,
  input [2:0] S_AXI_ACP_AWSIZE,
  input [4:0] S_AXI_ACP_ARUSER,
  input [4:0] S_AXI_ACP_AWUSER,
  input [63:0] S_AXI_ACP_WDATA,
  input [7:0] S_AXI_ACP_WSTRB,  
  
  // S_AXI_HP_0
  
  // -- Output
  output S_AXI_HP0_ARESETN,
  output S_AXI_HP0_ARREADY,
  output S_AXI_HP0_AWREADY,
  output S_AXI_HP0_BVALID,
  output S_AXI_HP0_RLAST,
  output S_AXI_HP0_RVALID,
  output S_AXI_HP0_WREADY,  
  output [1:0] S_AXI_HP0_BRESP,
  output [1:0] S_AXI_HP0_RRESP,
  output [(C_S_AXI_HP0_ID_WIDTH - 1) : 0] S_AXI_HP0_BID,
  output [(C_S_AXI_HP0_ID_WIDTH - 1) : 0] S_AXI_HP0_RID,
  output [(C_S_AXI_HP0_DATA_WIDTH - 1) :0] S_AXI_HP0_RDATA,
  output [7:0] S_AXI_HP0_RCOUNT,
  output [7:0] S_AXI_HP0_WCOUNT,
  output [2:0] S_AXI_HP0_RACOUNT,
  output [5:0] S_AXI_HP0_WACOUNT,
  
  // -- Input  
  input S_AXI_HP0_ACLK,
  input S_AXI_HP0_ARVALID,
  input S_AXI_HP0_AWVALID,
  input S_AXI_HP0_BREADY,
  input S_AXI_HP0_RDISSUECAP1_EN,
  input S_AXI_HP0_RREADY,
  input S_AXI_HP0_WLAST,
  input S_AXI_HP0_WRISSUECAP1_EN,
  input S_AXI_HP0_WVALID,
  input [1:0] S_AXI_HP0_ARBURST,
  input [1:0] S_AXI_HP0_ARLOCK,
  input [2:0] S_AXI_HP0_ARSIZE,
  input [1:0] S_AXI_HP0_AWBURST,
  input [1:0] S_AXI_HP0_AWLOCK,
  input [2:0] S_AXI_HP0_AWSIZE,
  input [2:0] S_AXI_HP0_ARPROT,
  input [2:0] S_AXI_HP0_AWPROT,
  input [31:0] S_AXI_HP0_ARADDR,
  input [31:0] S_AXI_HP0_AWADDR,
  input [3:0] S_AXI_HP0_ARCACHE,
  input [3:0] S_AXI_HP0_ARLEN,
  input [3:0] S_AXI_HP0_ARQOS,
  input [3:0] S_AXI_HP0_AWCACHE,
  input [3:0] S_AXI_HP0_AWLEN,
  input [3:0] S_AXI_HP0_AWQOS,
  input [(C_S_AXI_HP0_ID_WIDTH - 1) : 0] S_AXI_HP0_ARID,
  input [(C_S_AXI_HP0_ID_WIDTH - 1) : 0] S_AXI_HP0_AWID,
  input [(C_S_AXI_HP0_ID_WIDTH - 1) : 0] S_AXI_HP0_WID,
  input [(C_S_AXI_HP0_DATA_WIDTH - 1) :0] S_AXI_HP0_WDATA,
  input [((C_S_AXI_HP0_DATA_WIDTH/8)-1):0] S_AXI_HP0_WSTRB,  

  // S_AXI_HP1
  // -- Output
  output S_AXI_HP1_ARESETN,
  output S_AXI_HP1_ARREADY,
  output S_AXI_HP1_AWREADY,
  output S_AXI_HP1_BVALID,
  output S_AXI_HP1_RLAST,
  output S_AXI_HP1_RVALID,
  output S_AXI_HP1_WREADY,  
  output [1:0] S_AXI_HP1_BRESP,
  output [1:0] S_AXI_HP1_RRESP,
  output [(C_S_AXI_HP1_ID_WIDTH - 1) : 0] S_AXI_HP1_BID,
  output [(C_S_AXI_HP1_ID_WIDTH - 1) : 0] S_AXI_HP1_RID,
  output [(C_S_AXI_HP1_DATA_WIDTH - 1) :0] S_AXI_HP1_RDATA,
  output [7:0] S_AXI_HP1_RCOUNT,
  output [7:0] S_AXI_HP1_WCOUNT,
  output [2:0] S_AXI_HP1_RACOUNT,
  output [5:0] S_AXI_HP1_WACOUNT,
  
  
  // -- Input  
  input S_AXI_HP1_ACLK,
  input S_AXI_HP1_ARVALID,
  input S_AXI_HP1_AWVALID,
  input S_AXI_HP1_BREADY,
  input S_AXI_HP1_RDISSUECAP1_EN,
  input S_AXI_HP1_RREADY,
  input S_AXI_HP1_WLAST,
  input S_AXI_HP1_WRISSUECAP1_EN,
  input S_AXI_HP1_WVALID,
  input [1:0] S_AXI_HP1_ARBURST,
  input [1:0] S_AXI_HP1_ARLOCK,
  input [2:0] S_AXI_HP1_ARSIZE,
  input [1:0] S_AXI_HP1_AWBURST,
  input [1:0] S_AXI_HP1_AWLOCK,
  input [2:0] S_AXI_HP1_AWSIZE,
  input [2:0] S_AXI_HP1_ARPROT,
  input [2:0] S_AXI_HP1_AWPROT,
  input [31:0] S_AXI_HP1_ARADDR,
  input [31:0] S_AXI_HP1_AWADDR,
  input [3:0] S_AXI_HP1_ARCACHE,
  input [3:0] S_AXI_HP1_ARLEN,
  input [3:0] S_AXI_HP1_ARQOS,
  input [3:0] S_AXI_HP1_AWCACHE,
  input [3:0] S_AXI_HP1_AWLEN,
  input [3:0] S_AXI_HP1_AWQOS,
  input [(C_S_AXI_HP1_ID_WIDTH - 1) : 0] S_AXI_HP1_ARID,
  input [(C_S_AXI_HP1_ID_WIDTH - 1) : 0] S_AXI_HP1_AWID,
  input [(C_S_AXI_HP1_ID_WIDTH - 1) : 0] S_AXI_HP1_WID,
  input [(C_S_AXI_HP1_DATA_WIDTH - 1) :0] S_AXI_HP1_WDATA,
  input [((C_S_AXI_HP1_DATA_WIDTH/8)-1):0] S_AXI_HP1_WSTRB,  

  // S_AXI_HP2
  // -- Output
  output S_AXI_HP2_ARESETN,
  output S_AXI_HP2_ARREADY,
  output S_AXI_HP2_AWREADY,
  output S_AXI_HP2_BVALID,
  output S_AXI_HP2_RLAST,
  output S_AXI_HP2_RVALID,
  output S_AXI_HP2_WREADY,  
  output [1:0] S_AXI_HP2_BRESP,
  output [1:0] S_AXI_HP2_RRESP,
  output [(C_S_AXI_HP2_ID_WIDTH - 1) : 0] S_AXI_HP2_BID,
  output [(C_S_AXI_HP2_ID_WIDTH - 1) : 0] S_AXI_HP2_RID,
  output [(C_S_AXI_HP2_DATA_WIDTH - 1) :0] S_AXI_HP2_RDATA,
  output [7:0] S_AXI_HP2_RCOUNT,
  output [7:0] S_AXI_HP2_WCOUNT,
  output [2:0] S_AXI_HP2_RACOUNT,
  output [5:0] S_AXI_HP2_WACOUNT,
  
  
  // -- Input  
  input S_AXI_HP2_ACLK,
  input S_AXI_HP2_ARVALID,
  input S_AXI_HP2_AWVALID,
  input S_AXI_HP2_BREADY,
  input S_AXI_HP2_RDISSUECAP1_EN,
  input S_AXI_HP2_RREADY,
  input S_AXI_HP2_WLAST,
  input S_AXI_HP2_WRISSUECAP1_EN,
  input S_AXI_HP2_WVALID,
  input [1:0] S_AXI_HP2_ARBURST,
  input [1:0] S_AXI_HP2_ARLOCK,
  input [2:0] S_AXI_HP2_ARSIZE,
  input [1:0] S_AXI_HP2_AWBURST,
  input [1:0] S_AXI_HP2_AWLOCK,
  input [2:0] S_AXI_HP2_AWSIZE,
  input [2:0] S_AXI_HP2_ARPROT,
  input [2:0] S_AXI_HP2_AWPROT,
  input [31:0] S_AXI_HP2_ARADDR,
  input [31:0] S_AXI_HP2_AWADDR,
  input [3:0] S_AXI_HP2_ARCACHE,
  input [3:0] S_AXI_HP2_ARLEN,
  input [3:0] S_AXI_HP2_ARQOS,
  input [3:0] S_AXI_HP2_AWCACHE,
  input [3:0] S_AXI_HP2_AWLEN,
  input [3:0] S_AXI_HP2_AWQOS,
  input [(C_S_AXI_HP2_ID_WIDTH - 1) : 0] S_AXI_HP2_ARID,
  input [(C_S_AXI_HP2_ID_WIDTH - 1) : 0] S_AXI_HP2_AWID,
  input [(C_S_AXI_HP2_ID_WIDTH - 1) : 0] S_AXI_HP2_WID,
  input [(C_S_AXI_HP2_DATA_WIDTH - 1) :0] S_AXI_HP2_WDATA,
  input [((C_S_AXI_HP2_DATA_WIDTH/8)-1):0] S_AXI_HP2_WSTRB,  

  // S_AXI_HP_3
  
  // -- Output
  output S_AXI_HP3_ARESETN,
  output S_AXI_HP3_ARREADY,
  output S_AXI_HP3_AWREADY,
  output S_AXI_HP3_BVALID,
  output S_AXI_HP3_RLAST,
  output S_AXI_HP3_RVALID,
  output S_AXI_HP3_WREADY,  
  output [1:0] S_AXI_HP3_BRESP,
  output [1:0] S_AXI_HP3_RRESP,
  output [(C_S_AXI_HP3_ID_WIDTH - 1) : 0] S_AXI_HP3_BID,
  output [(C_S_AXI_HP3_ID_WIDTH - 1) : 0] S_AXI_HP3_RID,
  output [(C_S_AXI_HP3_DATA_WIDTH - 1) :0] S_AXI_HP3_RDATA,
  output [7:0] S_AXI_HP3_RCOUNT,
  output [7:0] S_AXI_HP3_WCOUNT,
  output [2:0] S_AXI_HP3_RACOUNT,
  output [5:0] S_AXI_HP3_WACOUNT,
  
  
  // -- Input  
  input S_AXI_HP3_ACLK,
  input S_AXI_HP3_ARVALID,
  input S_AXI_HP3_AWVALID,
  input S_AXI_HP3_BREADY,
  input S_AXI_HP3_RDISSUECAP1_EN,
  input S_AXI_HP3_RREADY,
  input S_AXI_HP3_WLAST,
  input S_AXI_HP3_WRISSUECAP1_EN,
  input S_AXI_HP3_WVALID,
  input [1:0] S_AXI_HP3_ARBURST,
  input [1:0] S_AXI_HP3_ARLOCK,
  input [2:0] S_AXI_HP3_ARSIZE,
  input [1:0] S_AXI_HP3_AWBURST,
  input [1:0] S_AXI_HP3_AWLOCK,
  input [2:0] S_AXI_HP3_AWSIZE,
  input [2:0] S_AXI_HP3_ARPROT,
  input [2:0] S_AXI_HP3_AWPROT,
  input [31:0] S_AXI_HP3_ARADDR,
  input [31:0] S_AXI_HP3_AWADDR,
  input [3:0] S_AXI_HP3_ARCACHE,
  input [3:0] S_AXI_HP3_ARLEN,
  input [3:0] S_AXI_HP3_ARQOS,
  input [3:0] S_AXI_HP3_AWCACHE,
  input [3:0] S_AXI_HP3_AWLEN,
  input [3:0] S_AXI_HP3_AWQOS,
  input [(C_S_AXI_HP3_ID_WIDTH - 1) : 0] S_AXI_HP3_ARID,
  input [(C_S_AXI_HP3_ID_WIDTH - 1) : 0] S_AXI_HP3_AWID,
  input [(C_S_AXI_HP3_ID_WIDTH - 1) : 0] S_AXI_HP3_WID,
  input [(C_S_AXI_HP3_DATA_WIDTH - 1) :0] S_AXI_HP3_WDATA,
  input [((C_S_AXI_HP3_DATA_WIDTH/8)-1):0] S_AXI_HP3_WSTRB,  
  
  //FIO ========================================

  //IRQ
  //output [28:0] IRQ_P2F,
  output IRQ_P2F_DMAC_ABORT ,
  output IRQ_P2F_DMAC0,
  output IRQ_P2F_DMAC1,
  output IRQ_P2F_DMAC2,
  output IRQ_P2F_DMAC3,
  output IRQ_P2F_DMAC4,
  output IRQ_P2F_DMAC5,
  output IRQ_P2F_DMAC6,
  output IRQ_P2F_DMAC7,
  output IRQ_P2F_SMC,
  output IRQ_P2F_QSPI,
  output IRQ_P2F_CTI,
  output IRQ_P2F_GPIO,
  output IRQ_P2F_USB0,
  output IRQ_P2F_ENET0,
  output IRQ_P2F_ENET_WAKE0,
  output IRQ_P2F_SDIO0,
  output IRQ_P2F_I2C0,
  output IRQ_P2F_SPI0,
  output IRQ_P2F_UART0,
  output IRQ_P2F_CAN0,
  output IRQ_P2F_USB1,
  output IRQ_P2F_ENET1,
  output IRQ_P2F_ENET_WAKE1,
  output IRQ_P2F_SDIO1,
  output IRQ_P2F_I2C1,
  output IRQ_P2F_SPI1,
  output IRQ_P2F_UART1,
  output IRQ_P2F_CAN1,
  input  [(C_NUM_F2P_INTR_INPUTS-1):0] IRQ_F2P,
  input         Core0_nFIQ,
  input         Core0_nIRQ,
  input         Core1_nFIQ,
  input         Core1_nIRQ,

  //DMA

  output [1:0] DMA0_DATYPE,  
  output DMA0_DAVALID,
  output DMA0_DRREADY,
  output DMA0_RSTN,  
  output [1:0] DMA1_DATYPE,  
  output DMA1_DAVALID,
  output DMA1_DRREADY,
  output DMA1_RSTN,  
  output [1:0] DMA2_DATYPE,  
  output DMA2_DAVALID,
  output DMA2_DRREADY,
  output DMA2_RSTN,  
  output [1:0] DMA3_DATYPE,    
  output DMA3_DAVALID,
  output DMA3_DRREADY,
  output DMA3_RSTN,  
  input DMA0_ACLK,
  input DMA0_DAREADY,
  input DMA0_DRLAST,
  input DMA0_DRVALID,
  input DMA1_ACLK,
  input DMA1_DAREADY,
  input DMA1_DRLAST,
  input DMA1_DRVALID,
  input DMA2_ACLK,
  input DMA2_DAREADY,
  input DMA2_DRLAST,
  input DMA2_DRVALID,
  input DMA3_ACLK,
  input DMA3_DAREADY,
  input DMA3_DRLAST,
  input DMA3_DRVALID,  
  input [1:0] DMA0_DRTYPE,
  input [1:0] DMA1_DRTYPE,
  input [1:0] DMA2_DRTYPE,
  input [1:0] DMA3_DRTYPE,
  
  //FCLK
  output    FCLK_CLK3,
  output    FCLK_CLK2,
  output    FCLK_CLK1,
  output    FCLK_CLK0,
 
  input     FCLK_CLKTRIG3_N,
  input     FCLK_CLKTRIG2_N,
  input     FCLK_CLKTRIG1_N,
  input     FCLK_CLKTRIG0_N,
 
  output    FCLK_RESET3_N,
  output    FCLK_RESET2_N,
  output    FCLK_RESET1_N,
  output    FCLK_RESET0_N,

  //FTMD
  input    [31:0] FTMD_TRACEIN_DATA,
  input           FTMD_TRACEIN_VALID,
  input           FTMD_TRACEIN_CLK,
  input    [3:0]  FTMD_TRACEIN_ATID,

  //FTMT
  input     FTMT_F2P_TRIG_0,
  output    FTMT_F2P_TRIGACK_0,
  input     FTMT_F2P_TRIG_1,
  output    FTMT_F2P_TRIGACK_1,
  input     FTMT_F2P_TRIG_2,
  output    FTMT_F2P_TRIGACK_2,
  input     FTMT_F2P_TRIG_3,
  output    FTMT_F2P_TRIGACK_3,
  input     [31:0] FTMT_F2P_DEBUG,  
  input     FTMT_P2F_TRIGACK_0,
  output    FTMT_P2F_TRIG_0,
  input     FTMT_P2F_TRIGACK_1,
  output    FTMT_P2F_TRIG_1,
  input     FTMT_P2F_TRIGACK_2,
  output    FTMT_P2F_TRIG_2,
  input     FTMT_P2F_TRIGACK_3,
  output    FTMT_P2F_TRIG_3,
  output    [31:0] FTMT_P2F_DEBUG,

  //FIDLE
  input           FPGA_IDLE_N,
  
  //EVENT

  output EVENT_EVENTO,
  output [1:0] EVENT_STANDBYWFE,
  output [1:0] EVENT_STANDBYWFI,  
  input EVENT_EVENTI,   
  

  //DARB
  input     [3:0] DDR_ARB,
  inout     [C_MIO_PRIMITIVE - 1:0] MIO,  
  
  //DDR
  inout         DDR_CAS_n,       // CASB
  inout         DDR_CKE,         // CKE
  inout         DDR_Clk_n,       // CKN
  inout         DDR_Clk,         // CKP
  inout         DDR_CS_n,        // CSB 
  inout         DDR_DRSTB,       // DDR_DRSTB  
  inout         DDR_ODT,         // ODT
  inout         DDR_RAS_n,       // RASB
  inout         DDR_WEB,
  inout  [2:0]  DDR_BankAddr,    // BA  
  inout  [14:0] DDR_Addr,        // A
  
  inout          DDR_VRN,
  inout          DDR_VRP,
  inout   [C_DM_WIDTH - 1:0]  DDR_DM,          // DM  
  inout   [C_DQ_WIDTH - 1:0] DDR_DQ,          // DQ
  inout   [C_DQS_WIDTH -1:0]  DDR_DQS_n,       // DQSN
  inout   [C_DQS_WIDTH - 1:0]  DDR_DQS,         // DQSP
  
  inout          PS_SRSTB,        // SRSTB    
  inout          PS_CLK,          // CLK
  inout          PS_PORB         // PORB 


);

wire [11:0]  M_AXI_GP0_AWID_FULL;
wire [11:0]  M_AXI_GP0_WID_FULL;
wire [11:0]  M_AXI_GP0_ARID_FULL;

wire [11:0]  M_AXI_GP0_BID_FULL;
wire [11:0]  M_AXI_GP0_RID_FULL;

wire [11:0]  M_AXI_GP1_AWID_FULL;
wire [11:0]  M_AXI_GP1_WID_FULL;
wire [11:0]  M_AXI_GP1_ARID_FULL;

wire [11:0]  M_AXI_GP1_BID_FULL;
wire [11:0]  M_AXI_GP1_RID_FULL;





// Wires for connecting to the PS7
wire    ENET0_GMII_TX_EN_i;
wire    ENET0_GMII_TX_ER_i;
reg          ENET0_GMII_COL_i;
reg          ENET0_GMII_CRS_i;
reg          ENET0_GMII_RX_DV_i;
reg          ENET0_GMII_RX_ER_i;
reg [7:0]    ENET0_GMII_RXD_i;
wire [7:0]   ENET0_GMII_TXD_i;

wire         ENET1_GMII_TX_EN_i;
wire         ENET1_GMII_TX_ER_i;
reg          ENET1_GMII_COL_i;
reg          ENET1_GMII_CRS_i;
reg          ENET1_GMII_RX_DV_i;
reg          ENET1_GMII_RX_ER_i;
reg [7:0]   ENET1_GMII_RXD_i;
wire [7:0]   ENET1_GMII_TXD_i;

reg    [31:0] FTMD_TRACEIN_DATA_notracebuf;
reg           FTMD_TRACEIN_VALID_notracebuf;
reg    [3:0]  FTMD_TRACEIN_ATID_notracebuf;

wire    [31:0] FTMD_TRACEIN_DATA_i;
wire           FTMD_TRACEIN_VALID_i;
wire    [3:0]  FTMD_TRACEIN_ATID_i;

wire    [31:0] FTMD_TRACEIN_DATA_tracebuf;
wire           FTMD_TRACEIN_VALID_tracebuf;
wire    [3:0]  FTMD_TRACEIN_ATID_tracebuf;

wire [5:0]    S_AXI_GP0_BID_out;
wire [5:0]    S_AXI_GP0_RID_out;
wire [5:0]    S_AXI_GP0_ARID_in;
wire [5:0]    S_AXI_GP0_AWID_in;
wire [5:0]    S_AXI_GP0_WID_in;

wire [5:0]    S_AXI_GP1_BID_out;
wire [5:0]    S_AXI_GP1_RID_out;
wire [5:0]    S_AXI_GP1_ARID_in;
wire [5:0]    S_AXI_GP1_AWID_in;
wire [5:0]    S_AXI_GP1_WID_in;

wire [5:0]    S_AXI_HP0_BID_out;
wire [5:0]    S_AXI_HP0_RID_out;
wire [5:0]    S_AXI_HP0_ARID_in;
wire [5:0]    S_AXI_HP0_AWID_in;
wire [5:0]    S_AXI_HP0_WID_in;

wire [5:0]    S_AXI_HP1_BID_out;
wire [5:0]    S_AXI_HP1_RID_out;
wire [5:0]    S_AXI_HP1_ARID_in;
wire [5:0]    S_AXI_HP1_AWID_in;
wire [5:0]    S_AXI_HP1_WID_in;

wire [5:0]    S_AXI_HP2_BID_out;
wire [5:0]    S_AXI_HP2_RID_out;
wire [5:0]    S_AXI_HP2_ARID_in;
wire [5:0]    S_AXI_HP2_AWID_in;
wire [5:0]    S_AXI_HP2_WID_in;

wire [5:0]    S_AXI_HP3_BID_out;
wire [5:0]    S_AXI_HP3_RID_out;
wire [5:0]    S_AXI_HP3_ARID_in;
wire [5:0]    S_AXI_HP3_AWID_in;
wire [5:0]    S_AXI_HP3_WID_in;

wire [2:0]    S_AXI_ACP_BID_out;
wire [2:0]    S_AXI_ACP_RID_out;
wire [2:0]    S_AXI_ACP_ARID_in;
wire [2:0]    S_AXI_ACP_AWID_in;
wire [2:0]    S_AXI_ACP_WID_in;  

wire [63:0]   S_AXI_HP0_WDATA_in;
wire [7:0]    S_AXI_HP0_WSTRB_in;
wire [63:0]   S_AXI_HP0_RDATA_out;

wire [63:0]   S_AXI_HP1_WDATA_in;
wire [7:0]    S_AXI_HP1_WSTRB_in;
wire [63:0]   S_AXI_HP1_RDATA_out;

wire [63:0]   S_AXI_HP2_WDATA_in;
wire [7:0]    S_AXI_HP2_WSTRB_in;
wire [63:0]   S_AXI_HP2_RDATA_out;

wire [63:0]   S_AXI_HP3_WDATA_in;
wire [7:0]    S_AXI_HP3_WSTRB_in;
wire [63:0]   S_AXI_HP3_RDATA_out;
 
wire [1:0]    M_AXI_GP0_ARSIZE_i;
wire [1:0]    M_AXI_GP0_AWSIZE_i;

wire [1:0]    M_AXI_GP1_ARSIZE_i;
wire [1:0]    M_AXI_GP1_AWSIZE_i;

wire [(C_S_AXI_ACP_ID_WIDTH - 1) : 0]    SAXIACPBID_W;
wire [(C_S_AXI_ACP_ID_WIDTH - 1) : 0]    SAXIACPRID_W;
wire [(C_S_AXI_ACP_ID_WIDTH - 1) : 0]    SAXIACPARID_W;
wire [(C_S_AXI_ACP_ID_WIDTH - 1) : 0]    SAXIACPAWID_W;
wire [(C_S_AXI_ACP_ID_WIDTH - 1) : 0]    SAXIACPWID_W;  


wire SAXIACPARREADY_W;
wire SAXIACPAWREADY_W;
wire SAXIACPBVALID_W;
wire SAXIACPRLAST_W;
wire SAXIACPRVALID_W;
wire SAXIACPWREADY_W;  
wire [1:0] SAXIACPBRESP_W;
wire [1:0] SAXIACPRRESP_W;
wire [(C_S_AXI_ACP_ID_WIDTH - 1) : 0] S_AXI_ATC_BID;
wire [(C_S_AXI_ACP_ID_WIDTH - 1) : 0] S_AXI_ATC_RID;
wire [63:0] SAXIACPRDATA_W;
  
wire S_AXI_ATC_ARVALID;
wire S_AXI_ATC_AWVALID;
wire S_AXI_ATC_BREADY;
wire S_AXI_ATC_RREADY;
wire S_AXI_ATC_WLAST;
wire S_AXI_ATC_WVALID;
wire [(C_S_AXI_ACP_ID_WIDTH - 1) : 0] S_AXI_ATC_ARID;
wire [2:0] S_AXI_ATC_ARPROT;
wire [(C_S_AXI_ACP_ID_WIDTH - 1) : 0] S_AXI_ATC_AWID;
wire [2:0] S_AXI_ATC_AWPROT;
wire [(C_S_AXI_ACP_ID_WIDTH - 1) : 0] S_AXI_ATC_WID;
wire [31:0] S_AXI_ATC_ARADDR;
wire [31:0] S_AXI_ATC_AWADDR;
wire [3:0] S_AXI_ATC_ARCACHE;
wire [3:0] S_AXI_ATC_ARLEN;
wire [3:0] S_AXI_ATC_ARQOS;
wire [3:0] S_AXI_ATC_AWCACHE;
wire [3:0] S_AXI_ATC_AWLEN;
wire [3:0] S_AXI_ATC_AWQOS;  
wire [1:0] S_AXI_ATC_ARBURST;
wire [1:0] S_AXI_ATC_ARLOCK;
wire [2:0] S_AXI_ATC_ARSIZE;
wire [1:0] S_AXI_ATC_AWBURST;
wire [1:0] S_AXI_ATC_AWLOCK;
wire [2:0] S_AXI_ATC_AWSIZE;
wire [4:0] S_AXI_ATC_ARUSER;
wire [4:0] S_AXI_ATC_AWUSER;
wire [63:0] S_AXI_ATC_WDATA;
wire [7:0] S_AXI_ATC_WSTRB;  


wire SAXIACPARVALID_W;
wire SAXIACPAWVALID_W;
wire SAXIACPBREADY_W;
wire SAXIACPRREADY_W;
wire SAXIACPWLAST_W;
wire SAXIACPWVALID_W;
wire [2:0] SAXIACPARPROT_W;
wire [2:0] SAXIACPAWPROT_W;
wire [31:0] SAXIACPARADDR_W;
wire [31:0] SAXIACPAWADDR_W;
wire [3:0] SAXIACPARCACHE_W;
wire [3:0] SAXIACPARLEN_W;
wire [3:0] SAXIACPARQOS_W;
wire [3:0] SAXIACPAWCACHE_W;
wire [3:0] SAXIACPAWLEN_W;
wire [3:0] SAXIACPAWQOS_W;  
wire [1:0] SAXIACPARBURST_W;
wire [1:0] SAXIACPARLOCK_W;
wire [2:0] SAXIACPARSIZE_W;
wire [1:0] SAXIACPAWBURST_W;
wire [1:0] SAXIACPAWLOCK_W;
wire [2:0] SAXIACPAWSIZE_W;
wire [4:0] SAXIACPARUSER_W;
wire [4:0] SAXIACPAWUSER_W;
wire [63:0] SAXIACPWDATA_W;
wire [7:0] SAXIACPWSTRB_W;

// AxUSER signal update
wire [4:0] param_aruser;
wire [4:0] param_awuser;

// Added to address CR 651751
wire [3:0]   fclk_clktrig_gnd = 4'h0;


wire [19:0]   irq_f2p_i;
wire [15:0]   irq_f2p_null = 16'h0000;

// EMIO I2C0
wire          I2C0_SDA_T_n;
wire          I2C0_SCL_T_n;
// EMIO I2C1
wire          I2C1_SDA_T_n;
wire          I2C1_SCL_T_n;
// EMIO SPI0
wire          SPI0_SCLK_T_n;
wire          SPI0_MOSI_T_n;
wire          SPI0_MISO_T_n;
wire          SPI0_SS_T_n;
// EMIO SPI1
wire          SPI1_SCLK_T_n;
wire          SPI1_MOSI_T_n;
wire          SPI1_MISO_T_n;
wire          SPI1_SS_T_n;

// EMIO GEM0
wire          ENET0_MDIO_T_n;

// EMIO GEM1
wire          ENET1_MDIO_T_n;

// EMIO GPIO
wire  [(C_EMIO_GPIO_WIDTH-1):0]        GPIO_T_n;

wire [63:0]   gpio_out_t_n;
wire [63:0]   gpio_out;
wire [63:0]   gpio_in63_0;

//For Clock buffering
wire    [3:0] FCLK_CLK_unbuffered;
wire    [3:0] FCLK_CLK_buffered;
wire   		  FCLK_CLK0_temp;

// EMIO PJTAG
wire          PJTAG_TDO_O;
wire          PJTAG_TDO_T;
wire          PJTAG_TDO_T_n;

// EMIO SDIO0
wire          SDIO0_CMD_T_n;
wire [3:0]    SDIO0_DATA_T_n;

// EMIO SDIO1
wire          SDIO1_CMD_T_n;
wire [3:0]    SDIO1_DATA_T_n;

// buffered IO
wire  [C_MIO_PRIMITIVE - 1:0]  buffered_MIO;
wire  buffered_DDR_WEB;
wire  buffered_DDR_CAS_n;
wire  buffered_DDR_CKE;
wire  buffered_DDR_Clk_n;
wire  buffered_DDR_Clk;
wire  buffered_DDR_CS_n; 
wire  buffered_DDR_DRSTB;  
wire  buffered_DDR_ODT;
wire  buffered_DDR_RAS_n;
wire  [2:0]  buffered_DDR_BankAddr; 
wire  [14:0]  buffered_DDR_Addr;
  
wire  buffered_DDR_VRN;
wire  buffered_DDR_VRP;
wire  [C_DM_WIDTH - 1:0]  buffered_DDR_DM;  
wire  [C_DQ_WIDTH - 1:0]  buffered_DDR_DQ;
wire  [C_DQS_WIDTH -1:0]  buffered_DDR_DQS_n;
wire  [C_DQS_WIDTH - 1:0]  buffered_DDR_DQS;
  
wire  buffered_PS_SRSTB; 
wire  buffered_PS_CLK;
wire  buffered_PS_PORB;

wire [31:0] TRACE_DATA_i;
wire TRACE_CTL_i;
(* keep = "true" *) reg   TRACE_CTL_PIPE [(C_TRACE_PIPELINE_WIDTH - 1):0];
(* keep = "true" *) reg   [(C_TRACE_INTERNAL_WIDTH)-1:0] TRACE_DATA_PIPE [(C_TRACE_PIPELINE_WIDTH - 1):0];

// fixed CR #665394
integer j;
generate
  if (C_EN_EMIO_TRACE == 1) begin 
    always @(posedge TRACE_CLK) 
    begin
	  TRACE_CTL_PIPE[C_TRACE_PIPELINE_WIDTH - 1] <= TRACE_CTL_i;
	  TRACE_DATA_PIPE[C_TRACE_PIPELINE_WIDTH - 1] <= TRACE_DATA_i[(C_TRACE_INTERNAL_WIDTH-1):0];
	  for (j=(C_TRACE_PIPELINE_WIDTH-1); j>0; j=j-1) begin
		TRACE_CTL_PIPE[j-1] <= TRACE_CTL_PIPE[j];
		TRACE_DATA_PIPE[j-1] <= TRACE_DATA_PIPE[j];
      end
	  TRACE_CLK_OUT  <= ~TRACE_CLK_OUT;
	end
  end	
else
begin
always @*
begin
TRACE_CTL_PIPE[C_TRACE_PIPELINE_WIDTH - 1] <= 1'b0;
  TRACE_DATA_PIPE[C_TRACE_PIPELINE_WIDTH - 1] <= 1'b0; 
  for (j=(C_TRACE_PIPELINE_WIDTH-1); j>0; j=j-1) begin
  TRACE_CTL_PIPE[j-1] <= 1'b0;
		TRACE_DATA_PIPE[j-1] <= 1'b0;
		end
  TRACE_CLK_OUT  <= 1'b0; 
  end
end
endgenerate

assign TRACE_CTL = TRACE_CTL_PIPE[0];

assign TRACE_DATA = TRACE_DATA_PIPE[0];

//irq_p2f

// Updated IRQ_F2P logic to address CR 641523
generate 
  if(C_NUM_F2P_INTR_INPUTS == 0) begin : irq_f2p_select_null
    assign irq_f2p_i[19:0] = {Core1_nFIQ,Core0_nFIQ,Core1_nIRQ,Core0_nIRQ,irq_f2p_null[15:0]};
  end else if(C_NUM_F2P_INTR_INPUTS == 16) begin : irq_f2p_select_all
    assign irq_f2p_i[19:0] = {Core1_nFIQ,Core0_nFIQ,Core1_nIRQ,Core0_nIRQ,IRQ_F2P[15:0]};
  end else begin : irq_f2p_select
	if (C_IRQ_F2P_MODE == "DIRECT") begin
    assign irq_f2p_i[19:0] = {Core1_nFIQ,Core0_nFIQ,Core1_nIRQ,Core0_nIRQ,
				irq_f2p_null[(15-C_NUM_F2P_INTR_INPUTS):0],
				IRQ_F2P[(C_NUM_F2P_INTR_INPUTS-1):0]};
	end else begin
	assign irq_f2p_i[19:0] = {Core1_nFIQ,Core0_nFIQ,Core1_nIRQ,Core0_nIRQ,
				IRQ_F2P[(C_NUM_F2P_INTR_INPUTS-1):0],
				irq_f2p_null[(15-C_NUM_F2P_INTR_INPUTS):0]};
	end
  end
endgenerate

assign M_AXI_GP0_ARSIZE[2:0] = {1'b0, M_AXI_GP0_ARSIZE_i[1:0]};
assign M_AXI_GP0_AWSIZE[2:0] = {1'b0, M_AXI_GP0_AWSIZE_i[1:0]};
assign M_AXI_GP1_ARSIZE[2:0] = {1'b0, M_AXI_GP1_ARSIZE_i[1:0]};
assign M_AXI_GP1_AWSIZE[2:0] = {1'b0, M_AXI_GP1_AWSIZE_i[1:0]};


  wire S_AXI_GP0_ARESETN_shim;
  wire S_AXI_GP0_ARREADY_shim;
  wire S_AXI_GP0_AWREADY_shim;
  wire S_AXI_GP0_BVALID_shim;
  wire S_AXI_GP0_RLAST_shim;
  wire S_AXI_GP0_RVALID_shim;
  wire S_AXI_GP0_WREADY_shim;  
  wire [1:0] S_AXI_GP0_BRESP_shim;
  wire [1:0] S_AXI_GP0_RRESP_shim;
  wire [31:0] S_AXI_GP0_RDATA_shim;
  wire [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] S_AXI_GP0_BID_out_shim;
  wire [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] S_AXI_GP0_RID_out_shim;
  wire [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] S_AXI_GP0_BID_shim;
  wire [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] S_AXI_GP0_RID_shim;
  
  wire S_AXI_GP0_ACLK_shim;
  wire S_AXI_GP0_ARVALID_shim;
  wire S_AXI_GP0_AWVALID_shim;
  wire S_AXI_GP0_BREADY_shim;
  wire S_AXI_GP0_RREADY_shim;
  wire S_AXI_GP0_WLAST_shim;
  wire S_AXI_GP0_WVALID_shim;
  wire [1:0] S_AXI_GP0_ARBURST_shim;
  wire [1:0] S_AXI_GP0_ARLOCK_shim;
  wire [2:0] S_AXI_GP0_ARSIZE_shim;
  wire [1:0] S_AXI_GP0_AWBURST_shim;
  wire [1:0] S_AXI_GP0_AWLOCK_shim;
  wire [2:0] S_AXI_GP0_AWSIZE_shim;
  wire [2:0] S_AXI_GP0_ARPROT_shim;
  wire [2:0] S_AXI_GP0_AWPROT_shim;
  wire [31:0] S_AXI_GP0_ARADDR_shim;
  wire [31:0] S_AXI_GP0_AWADDR_shim;
  wire [31:0] S_AXI_GP0_WDATA_shim;
  wire [3:0] S_AXI_GP0_ARCACHE_shim;
  wire [3:0] S_AXI_GP0_ARLEN_shim;
  wire [3:0] S_AXI_GP0_ARQOS_shim;
  wire [3:0] S_AXI_GP0_AWCACHE_shim;
  wire [3:0] S_AXI_GP0_AWLEN_shim;
  wire [3:0] S_AXI_GP0_AWQOS_shim;
  wire [3:0] S_AXI_GP0_WSTRB_shim;
  wire [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] S_AXI_GP0_ARID_in_shim;
  wire [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] S_AXI_GP0_AWID_in_shim;
  wire [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] S_AXI_GP0_WID_in_shim;  



xlnx_axi_wrshim_unwrap #
(
	.ID_WIDTH(C_S_AXI_GP0_ID_WIDTH),  
    .D_WIDTH(32) 

)xlnx_axi_wrshim_unwrap_inst_gp0
(
  .clk(S_AXI_GP0_ACLK_temp),
  .rst_n(S_AXI_GP0_ARESETN),

  .awqos_in(S_AXI_GP0_AWQOS),
  .awid_in(S_AXI_GP0_AWID_in),
  .awaddr_in(S_AXI_GP0_AWADDR),
  .awlen_in(S_AXI_GP0_AWLEN),
  .awsize_in(S_AXI_GP0_AWSIZE),
  .awburst_in(S_AXI_GP0_AWBURST),
  .awlock_in(S_AXI_GP0_AWLOCK),
  .awcache_in(S_AXI_GP0_AWCACHE),
  .awprot_in(S_AXI_GP0_AWPROT),
  .awvalid_in(S_AXI_GP0_AWVALID),
  .wdata_in(S_AXI_GP0_WDATA),
  .wid_in(S_AXI_GP0_WID_in),
  .wstrb_in(S_AXI_GP0_WSTRB),
  .wlast_in(S_AXI_GP0_WLAST),
  .wvalid_in(S_AXI_GP0_WVALID),
  .bready_in(S_AXI_GP0_BREADY),
  .arqos_in(S_AXI_GP0_ARQOS),
  .arid_in(S_AXI_GP0_ARID_in),
  .araddr_in(S_AXI_GP0_ARADDR),
  .arlen_in(S_AXI_GP0_ARLEN),
  .arsize_in(S_AXI_GP0_ARSIZE),
  .arburst_in(S_AXI_GP0_ARBURST),
  .arlock_in(S_AXI_GP0_ARLOCK),
  .arcache_in(S_AXI_GP0_ARCACHE),
  .arprot_in(S_AXI_GP0_ARPROT),
  .arvalid_in(S_AXI_GP0_ARVALID),
  .rready_in(S_AXI_GP0_RREADY),
  
  .awready_in(S_AXI_GP0_AWREADY),
  .arready_in(S_AXI_GP0_ARREADY),
  .rid_in(S_AXI_GP0_RID),
  .rdata_in(S_AXI_GP0_RDATA),
  .rresp_in(S_AXI_GP0_RRESP),
  .rlast_in(S_AXI_GP0_RLAST),
  .rvalid_in(S_AXI_GP0_RVALID),
  .wready_in(S_AXI_GP0_WREADY),
  .bid_in(S_AXI_GP0_BID),
  .bresp_in(S_AXI_GP0_BRESP),
  .bvalid_in(S_AXI_GP0_BVALID),
  
  
  .awqos_out(S_AXI_GP0_AWQOS_shim),
  .awid_out(S_AXI_GP0_AWID_in_shim),
  .awaddr_out(S_AXI_GP0_AWADDR_shim),
  .awlen_out(S_AXI_GP0_AWLEN_shim),
  .awsize_out(S_AXI_GP0_AWSIZE_shim),
  .awburst_out(S_AXI_GP0_AWBURST_shim),
  .awlock_out(S_AXI_GP0_AWLOCK_shim),
  .awcache_out(S_AXI_GP0_AWCACHE_shim),
  .awprot_out(S_AXI_GP0_AWPROT_shim),
  .awvalid_out(S_AXI_GP0_AWVALID_shim),
  .wdata_out(S_AXI_GP0_WDATA_shim),
  .wid_out(S_AXI_GP0_WID_in_shim),
  .wstrb_out(S_AXI_GP0_WSTRB_shim),
  .wlast_out(S_AXI_GP0_WLAST_shim),
  .wvalid_out(S_AXI_GP0_WVALID_shim),
  .bready_out(S_AXI_GP0_BREADY_shim),
  .arqos_out(S_AXI_GP0_ARQOS_shim),
  .arid_out(S_AXI_GP0_ARID_in_shim),
  .araddr_out(S_AXI_GP0_ARADDR_shim),
  .arlen_out(S_AXI_GP0_ARLEN_shim),
  .arsize_out(S_AXI_GP0_ARSIZE_shim),
  .arburst_out(S_AXI_GP0_ARBURST_shim),
  .arlock_out(S_AXI_GP0_ARLOCK_shim),
  .arcache_out(S_AXI_GP0_ARCACHE_shim),
  .arprot_out(S_AXI_GP0_ARPROT_shim),
  .arvalid_out(S_AXI_GP0_ARVALID_shim),
  .rready_out(S_AXI_GP0_RREADY_shim),
  
  .awready_out(S_AXI_GP0_AWREADY_shim),
  .arready_out(S_AXI_GP0_ARREADY_shim),
  .rid_out(S_AXI_GP0_RID_shim),
  .rdata_out(S_AXI_GP0_RDATA_shim),
  .rresp_out(S_AXI_GP0_RRESP_shim),
  .rlast_out(S_AXI_GP0_RLAST_shim),
  .rvalid_out(S_AXI_GP0_RVALID_shim),
  .wready_out(S_AXI_GP0_WREADY_shim),
  .bid_out(S_AXI_GP0_BID_shim),
  .bresp_out(S_AXI_GP0_BRESP_shim),
  .bvalid_out(S_AXI_GP0_BVALID_shim));

  
  

  wire S_AXI_GP1_ARESETN_shim;
  wire S_AXI_GP1_ARREADY_shim;
  wire S_AXI_GP1_AWREADY_shim;
  wire S_AXI_GP1_BVALID_shim;
  wire S_AXI_GP1_RLAST_shim;
  wire S_AXI_GP1_RVALID_shim;
  wire S_AXI_GP1_WREADY_shim;  
  wire [1:0] S_AXI_GP1_BRESP_shim;
  wire [1:0] S_AXI_GP1_RRESP_shim;
  wire [31:0] S_AXI_GP1_RDATA_shim;
  wire [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] S_AXI_GP1_BID_out_shim;
  wire [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] S_AXI_GP1_RID_out_shim;
  wire [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] S_AXI_GP1_BID_shim;
  wire [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] S_AXI_GP1_RID_shim;
  
  // -- Input
  wire S_AXI_GP1_ACLK_shim;
  wire S_AXI_GP1_ARVALID_shim;
  wire S_AXI_GP1_AWVALID_shim;
  wire S_AXI_GP1_BREADY_shim;
  wire S_AXI_GP1_RREADY_shim;
  wire S_AXI_GP1_WLAST_shim;
  wire S_AXI_GP1_WVALID_shim;
  wire [1:0] S_AXI_GP1_ARBURST_shim;
  wire [1:0] S_AXI_GP1_ARLOCK_shim;
  wire [2:0] S_AXI_GP1_ARSIZE_shim;
  wire [1:0] S_AXI_GP1_AWBURST_shim;
  wire [1:0] S_AXI_GP1_AWLOCK_shim;
  wire [2:0] S_AXI_GP1_AWSIZE_shim;
  wire [2:0] S_AXI_GP1_ARPROT_shim;
  wire [2:0] S_AXI_GP1_AWPROT_shim;
  wire [31:0] S_AXI_GP1_ARADDR_shim;
  wire [31:0] S_AXI_GP1_AWADDR_shim;
  wire [31:0] S_AXI_GP1_WDATA_shim;
  wire [3:0] S_AXI_GP1_ARCACHE_shim;
  wire [3:0] S_AXI_GP1_ARLEN_shim;
  wire [3:0] S_AXI_GP1_ARQOS_shim;
  wire [3:0] S_AXI_GP1_AWCACHE_shim;
  wire [3:0] S_AXI_GP1_AWLEN_shim;
  wire [3:0] S_AXI_GP1_AWQOS_shim;
  wire [3:0] S_AXI_GP1_WSTRB_shim;
  wire [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] S_AXI_GP1_ARID_in_shim;
  wire [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] S_AXI_GP1_AWID_in_shim;
  wire [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] S_AXI_GP1_WID_in_shim;  
  
  


xlnx_axi_wrshim_unwrap #
(
	.ID_WIDTH(C_S_AXI_GP1_ID_WIDTH),  
    .D_WIDTH(32) 

)xlnx_axi_wrshim_unwrap_inst_gp1
(
  .clk(S_AXI_GP1_ACLK_temp),
  .rst_n(S_AXI_GP1_ARESETN),

  .awqos_in(S_AXI_GP1_AWQOS),
  .awid_in(S_AXI_GP1_AWID_in),
  .awaddr_in(S_AXI_GP1_AWADDR),
  .awlen_in(S_AXI_GP1_AWLEN),
  .awsize_in(S_AXI_GP1_AWSIZE),
  .awburst_in(S_AXI_GP1_AWBURST),
  .awlock_in(S_AXI_GP1_AWLOCK),
  .awcache_in(S_AXI_GP1_AWCACHE),
  .awprot_in(S_AXI_GP1_AWPROT),
  .awvalid_in(S_AXI_GP1_AWVALID),
  .wdata_in(S_AXI_GP1_WDATA),
  .wid_in(S_AXI_GP1_WID_in),
  .wstrb_in(S_AXI_GP1_WSTRB),
  .wlast_in(S_AXI_GP1_WLAST),
  .wvalid_in(S_AXI_GP1_WVALID),
  .bready_in(S_AXI_GP1_BREADY),
  .arqos_in(S_AXI_GP1_ARQOS),
  .arid_in(S_AXI_GP1_ARID_in),
  .araddr_in(S_AXI_GP1_ARADDR),
  .arlen_in(S_AXI_GP1_ARLEN),
  .arsize_in(S_AXI_GP1_ARSIZE),
  .arburst_in(S_AXI_GP1_ARBURST),
  .arlock_in(S_AXI_GP1_ARLOCK),
  .arcache_in(S_AXI_GP1_ARCACHE),
  .arprot_in(S_AXI_GP1_ARPROT),
  .arvalid_in(S_AXI_GP1_ARVALID),
  .rready_in(S_AXI_GP1_RREADY),
  
  .awready_in(S_AXI_GP1_AWREADY),
  .arready_in(S_AXI_GP1_ARREADY),
  .rid_in(S_AXI_GP1_RID),
  .rdata_in(S_AXI_GP1_RDATA),
  .rresp_in(S_AXI_GP1_RRESP),
  .rlast_in(S_AXI_GP1_RLAST),
  .rvalid_in(S_AXI_GP1_RVALID),
  .wready_in(S_AXI_GP1_WREADY),
  .bid_in(S_AXI_GP1_BID),
  .bresp_in(S_AXI_GP1_BRESP),
  .bvalid_in(S_AXI_GP1_BVALID),
  
  
  .awqos_out(S_AXI_GP1_AWQOS_shim),
  .awid_out(S_AXI_GP1_AWID_in_shim),
  .awaddr_out(S_AXI_GP1_AWADDR_shim),
  .awlen_out(S_AXI_GP1_AWLEN_shim),
  .awsize_out(S_AXI_GP1_AWSIZE_shim),
  .awburst_out(S_AXI_GP1_AWBURST_shim),
  .awlock_out(S_AXI_GP1_AWLOCK_shim),
  .awcache_out(S_AXI_GP1_AWCACHE_shim),
  .awprot_out(S_AXI_GP1_AWPROT_shim),
  .awvalid_out(S_AXI_GP1_AWVALID_shim),
  .wdata_out(S_AXI_GP1_WDATA_shim),
  .wid_out(S_AXI_GP1_WID_in_shim),
  .wstrb_out(S_AXI_GP1_WSTRB_shim),
  .wlast_out(S_AXI_GP1_WLAST_shim),
  .wvalid_out(S_AXI_GP1_WVALID_shim),
  .bready_out(S_AXI_GP1_BREADY_shim),
  .arqos_out(S_AXI_GP1_ARQOS_shim),
  .arid_out(S_AXI_GP1_ARID_in_shim),
  .araddr_out(S_AXI_GP1_ARADDR_shim),
  .arlen_out(S_AXI_GP1_ARLEN_shim),
  .arsize_out(S_AXI_GP1_ARSIZE_shim),
  .arburst_out(S_AXI_GP1_ARBURST_shim),
  .arlock_out(S_AXI_GP1_ARLOCK_shim),
  .arcache_out(S_AXI_GP1_ARCACHE_shim),
  .arprot_out(S_AXI_GP1_ARPROT_shim),
  .arvalid_out(S_AXI_GP1_ARVALID_shim),
  .rready_out(S_AXI_GP1_RREADY_shim),
  
  .awready_out(S_AXI_GP1_AWREADY_shim),
  .arready_out(S_AXI_GP1_ARREADY_shim),
  .rid_out(S_AXI_GP1_RID_shim),
  .rdata_out(S_AXI_GP1_RDATA_shim),
  .rresp_out(S_AXI_GP1_RRESP_shim),
  .rlast_out(S_AXI_GP1_RLAST_shim),
  .rvalid_out(S_AXI_GP1_RVALID_shim),
  .wready_out(S_AXI_GP1_WREADY_shim),
  .bid_out(S_AXI_GP1_BID_shim),
  .bresp_out(S_AXI_GP1_BRESP_shim),
  .bvalid_out(S_AXI_GP1_BVALID_shim));  

// Compress Function

   
// Modified as per CR 631955   
//function [11:0] uncompress_id; 
//   input [5:0] id; 
//      begin 
//         case (id[5:0]) 
//            // dmac0 
//            6'd1 : uncompress_id = 12'b010000_1000_00 ; 
//            6'd2 : uncompress_id = 12'b010000_0000_00 ; 
//            6'd3 : uncompress_id = 12'b010000_0001_00 ; 
//            6'd4 : uncompress_id = 12'b010000_0010_00 ; 
//            6'd5 : uncompress_id = 12'b010000_0011_00 ; 
//            6'd6 : uncompress_id = 12'b010000_0100_00 ; 
//            6'd7 : uncompress_id = 12'b010000_0101_00 ; 
//            6'd8 : uncompress_id = 12'b010000_0110_00 ; 
//            6'd9 : uncompress_id = 12'b010000_0111_00 ; 
//            // ioum 
//            6'd10 : uncompress_id = 12'b0100000_000_01 ; 
//            6'd11 : uncompress_id = 12'b0100000_001_01 ; 
//            6'd12 : uncompress_id = 12'b0100000_010_01 ; 
//            6'd13 : uncompress_id = 12'b0100000_011_01 ; 
//            6'd14 : uncompress_id = 12'b0100000_100_01 ; 
//            6'd15 : uncompress_id = 12'b0100000_101_01 ; 
//            // devci 
//            6'd16 : uncompress_id = 12'b1000_0000_0000 ; 
//            // dap 
//            6'd17 : uncompress_id = 12'b1000_0000_0001 ; 
//            // l2m1 (CPU000) 
//            6'd18 : uncompress_id = 12'b11_000_000_00_00 ; 
//            6'd19 : uncompress_id = 12'b11_010_000_00_00 ; 
//            6'd20 : uncompress_id = 12'b11_011_000_00_00 ; 
//            6'd21 : uncompress_id = 12'b11_100_000_00_00 ; 
//            6'd22 : uncompress_id = 12'b11_101_000_00_00 ; 
//            6'd23 : uncompress_id = 12'b11_110_000_00_00 ; 
//            6'd24 : uncompress_id = 12'b11_111_000_00_00 ; 
//            // l2m1 (CPU001) 
//            6'd25 : uncompress_id = 12'b11_000_001_00_00 ; 
//            6'd26 : uncompress_id = 12'b11_010_001_00_00 ; 
//            6'd27 : uncompress_id = 12'b11_011_001_00_00 ; 
//            6'd28 : uncompress_id = 12'b11_100_001_00_00 ; 
//            6'd29 : uncompress_id = 12'b11_101_001_00_00 ; 
//            6'd30 : uncompress_id = 12'b11_110_001_00_00 ; 
//            6'd31 : uncompress_id = 12'b11_111_001_00_00 ; 
//            // l2m1 (L2CC) 
//            6'd32 : uncompress_id = 12'b11_000_00101_00 ; 
//            6'd33 : uncompress_id = 12'b11_000_01001_00 ; 
//            6'd34 : uncompress_id = 12'b11_000_01101_00 ; 
//            6'd35 : uncompress_id = 12'b11_000_10011_00 ; 
//            6'd36 : uncompress_id = 12'b11_000_10111_00 ; 
//            6'd37 : uncompress_id = 12'b11_000_11011_00 ; 
//            6'd38 : uncompress_id = 12'b11_000_11111_00 ; 
//            6'd39 : uncompress_id = 12'b11_000_00011_00 ; 
//            6'd40 : uncompress_id = 12'b11_000_00111_00 ; 
//            6'd41 : uncompress_id = 12'b11_000_01011_00 ; 
//            6'd42 : uncompress_id = 12'b11_000_01111_00 ; 
//            6'd43 : uncompress_id = 12'b11_000_00001_00 ; 
//            // l2m1 (ACP) 
//            6'd44 : uncompress_id = 12'b11_000_10000_00 ; 
//            6'd45 : uncompress_id = 12'b11_001_10000_00 ; 
//            6'd46 : uncompress_id = 12'b11_010_10000_00 ; 
//            6'd47 : uncompress_id = 12'b11_011_10000_00 ; 
//            6'd48 : uncompress_id = 12'b11_100_10000_00 ; 
//            6'd49 : uncompress_id = 12'b11_101_10000_00 ; 
//            6'd50 : uncompress_id = 12'b11_110_10000_00 ; 
//            6'd51 : uncompress_id = 12'b11_111_10000_00 ; 
//         default : uncompress_id = ~0; 
//      endcase 
//   end 
//endfunction 
// 
//function [5:0] compress_id; 
//   input [11:0] id; 
//      begin 
//         case (id[11:0]) 
//         // dmac0 
//            12'b010000_1000_00 : compress_id = 'd1 ; 
//            12'b010000_0000_00 : compress_id = 'd2 ; 
//            12'b010000_0001_00 : compress_id = 'd3 ; 
//            12'b010000_0010_00 : compress_id = 'd4 ; 
//            12'b010000_0011_00 : compress_id = 'd5 ; 
//            12'b010000_0100_00 : compress_id = 'd6 ; 
//            12'b010000_0101_00 : compress_id = 'd7 ; 
//            12'b010000_0110_00 : compress_id = 'd8 ; 
//            12'b010000_0111_00 : compress_id = 'd9 ; 
//            // ioum 
//            12'b0100000_000_01 : compress_id = 'd10 ; 
//            12'b0100000_001_01 : compress_id = 'd11 ; 
//            12'b0100000_010_01 : compress_id = 'd12 ; 
//            12'b0100000_011_01 : compress_id = 'd13 ; 
//            12'b0100000_100_01 : compress_id = 'd14 ; 
//            12'b0100000_101_01 : compress_id = 'd15 ; 
//            // devci 
//            12'b1000_0000_0000 : compress_id = 'd16 ; 
//            // dap 
//            12'b1000_0000_0001 : compress_id = 'd17 ; 
//            // l2m1 (CPU000) 
//            12'b11_000_000_00_00 : compress_id = 'd18 ; 
//            12'b11_010_000_00_00 : compress_id = 'd19 ; 
//            12'b11_011_000_00_00 : compress_id = 'd20 ; 
//            12'b11_100_000_00_00 : compress_id = 'd21 ; 
//            12'b11_101_000_00_00 : compress_id = 'd22 ; 
//            12'b11_110_000_00_00 : compress_id = 'd23 ; 
//            12'b11_111_000_00_00 : compress_id = 'd24 ; 
//            // l2m1 (CPU001) 
//            12'b11_000_001_00_00 : compress_id = 'd25 ; 
//            12'b11_010_001_00_00 : compress_id = 'd26 ; 
//            12'b11_011_001_00_00 : compress_id = 'd27 ; 
//            12'b11_100_001_00_00 : compress_id = 'd28 ; 
//            12'b11_101_001_00_00 : compress_id = 'd29 ; 
//            12'b11_110_001_00_00 : compress_id = 'd30 ; 
//            12'b11_111_001_00_00 : compress_id = 'd31 ; 
//            // l2m1 (L2CC) 
//            12'b11_000_00101_00 : compress_id = 'd32 ; 
//            12'b11_000_01001_00 : compress_id = 'd33 ; 
//            12'b11_000_01101_00 : compress_id = 'd34 ; 
//            12'b11_000_10011_00 : compress_id = 'd35 ; 
//            12'b11_000_10111_00 : compress_id = 'd36 ; 
//            12'b11_000_11011_00 : compress_id = 'd37 ; 
//            12'b11_000_11111_00 : compress_id = 'd38 ; 
//            12'b11_000_00011_00 : compress_id = 'd39 ; 
//            12'b11_000_00111_00 : compress_id = 'd40 ; 
//            12'b11_000_01011_00 : compress_id = 'd41 ; 
//            12'b11_000_01111_00 : compress_id = 'd42 ; 
//            12'b11_000_00001_00 : compress_id = 'd43 ; 
//            // l2m1 (ACP) 
//            12'b11_000_10000_00 : compress_id = 'd44 ; 
//            12'b11_001_10000_00 : compress_id = 'd45 ; 
//            12'b11_010_10000_00 : compress_id = 'd46 ; 
//            12'b11_011_10000_00 : compress_id = 'd47 ; 
//            12'b11_100_10000_00 : compress_id = 'd48 ; 
//            12'b11_101_10000_00 : compress_id = 'd49 ; 
//            12'b11_110_10000_00 : compress_id = 'd50 ; 
//            12'b11_111_10000_00 : compress_id = 'd51 ; 
//         default: compress_id = ~0; 
//      endcase 
//   end 
//endfunction 

// Modified as per CR 648393

	function [5:0] compress_id; 
		input [11:0] id; 
			begin 
				compress_id[0] = id[7] | (id[4] & id[2]) | (~id[11] & id[2]) | (id[11] & id[0]); 
				compress_id[1] = id[8] | id[5] | (~id[11] & id[3]); 
				compress_id[2] = id[9] | (id[6] & id[3] & id[2]) | (~id[11] & id[4]); 
				compress_id[3] = (id[11] & id[10] & id[4]) | (id[11] & id[10] & id[2]) | (~id[11] & id[10] & ~id[5] & ~id[0]); 
				compress_id[4] = (id[11] & id[3]) | (id[10] & id[0]) | (id[11] & id[10] & ~id[2] &~id[6]); 
				compress_id[5] = id[11] & id[10] & ~id[3]; 
			end 
	endfunction 

	function [11:0] uncompress_id; 
		input [5:0] id; 
			begin 
				case (id[5:0]) 
					// dmac0 
					6'b000_010 : uncompress_id = 12'b010000_1000_00 ; 
					6'b001_000 : uncompress_id = 12'b010000_0000_00 ; 
					6'b001_001 : uncompress_id = 12'b010000_0001_00 ; 
					6'b001_010 : uncompress_id = 12'b010000_0010_00 ; 
					6'b001_011 : uncompress_id = 12'b010000_0011_00 ; 
					6'b001_100 : uncompress_id = 12'b010000_0100_00 ; 
					6'b001_101 : uncompress_id = 12'b010000_0101_00 ; 
					6'b001_110 : uncompress_id = 12'b010000_0110_00 ; 
					6'b001_111 : uncompress_id = 12'b010000_0111_00 ; 
					// ioum 
					6'b010_000 : uncompress_id = 12'b0100000_000_01 ; 
					6'b010_001 : uncompress_id = 12'b0100000_001_01 ; 
					6'b010_010 : uncompress_id = 12'b0100000_010_01 ; 
					6'b010_011 : uncompress_id = 12'b0100000_011_01 ; 
					6'b010_100 : uncompress_id = 12'b0100000_100_01 ; 
					6'b010_101 : uncompress_id = 12'b0100000_101_01 ; 
					// devci 
					6'b000_000 : uncompress_id = 12'b1000_0000_0000 ; 
					// dap 
					6'b000_001 : uncompress_id = 12'b1000_0000_0001 ; 
					// l2m1 (CPU000) 
					6'b110_000 : uncompress_id = 12'b11_000_000_00_00 ; 
					6'b110_010 : uncompress_id = 12'b11_010_000_00_00 ; 
					6'b110_011 : uncompress_id = 12'b11_011_000_00_00 ; 
					6'b110_100 : uncompress_id = 12'b11_100_000_00_00 ; 
					6'b110_101 : uncompress_id = 12'b11_101_000_00_00 ; 
					6'b110_110 : uncompress_id = 12'b11_110_000_00_00 ; 
					6'b110_111 : uncompress_id = 12'b11_111_000_00_00 ; 
					// l2m1 (CPU001) 
					6'b111_000 : uncompress_id = 12'b11_000_001_00_00 ; 
					6'b111_010 : uncompress_id = 12'b11_010_001_00_00 ; 
					6'b111_011 : uncompress_id = 12'b11_011_001_00_00 ; 
					6'b111_100 : uncompress_id = 12'b11_100_001_00_00 ; 
					6'b111_101 : uncompress_id = 12'b11_101_001_00_00 ; 
					6'b111_110 : uncompress_id = 12'b11_110_001_00_00 ; 
					6'b111_111 : uncompress_id = 12'b11_111_001_00_00 ; 
					// l2m1 (L2CC) 
					6'b101_001 : uncompress_id = 12'b11_000_00101_00 ; 
					6'b101_010 : uncompress_id = 12'b11_000_01001_00 ; 
					6'b101_011 : uncompress_id = 12'b11_000_01101_00 ; 
					6'b011_100 : uncompress_id = 12'b11_000_10011_00 ; 
					6'b011_101 : uncompress_id = 12'b11_000_10111_00 ; 
					6'b011_110 : uncompress_id = 12'b11_000_11011_00 ; 
					6'b011_111 : uncompress_id = 12'b11_000_11111_00 ; 
					6'b011_000 : uncompress_id = 12'b11_000_00011_00 ; 
					6'b011_001 : uncompress_id = 12'b11_000_00111_00 ; 
					6'b011_010 : uncompress_id = 12'b11_000_01011_00 ; 
					6'b011_011 : uncompress_id = 12'b11_000_01111_00 ; 
					6'b101_000 : uncompress_id = 12'b11_000_00001_00 ; 
					// l2m1 (ACP) 
					6'b100_000 : uncompress_id = 12'b11_000_10000_00 ; 
					6'b100_001 : uncompress_id = 12'b11_001_10000_00 ; 
					6'b100_010 : uncompress_id = 12'b11_010_10000_00 ; 
					6'b100_011 : uncompress_id = 12'b11_011_10000_00 ; 
					6'b100_100 : uncompress_id = 12'b11_100_10000_00 ; 
					6'b100_101 : uncompress_id = 12'b11_101_10000_00 ; 
					6'b100_110 : uncompress_id = 12'b11_110_10000_00 ; 
					6'b100_111 : uncompress_id = 12'b11_111_10000_00 ; 
					default : uncompress_id = 12'hx ; 
				endcase 
			end 
	endfunction

   
// Static Remap logic Enablement and Disablement for C_M_AXI0 port
        
        assign M_AXI_GP0_AWID        = (C_M_AXI_GP0_ENABLE_STATIC_REMAP == 1) ? compress_id(M_AXI_GP0_AWID_FULL) : M_AXI_GP0_AWID_FULL;
        assign M_AXI_GP0_WID         = (C_M_AXI_GP0_ENABLE_STATIC_REMAP == 1) ? compress_id(M_AXI_GP0_WID_FULL)  : M_AXI_GP0_WID_FULL;   
        assign M_AXI_GP0_ARID        = (C_M_AXI_GP0_ENABLE_STATIC_REMAP == 1) ? compress_id(M_AXI_GP0_ARID_FULL) : M_AXI_GP0_ARID_FULL;      
        assign M_AXI_GP0_BID_FULL    = (C_M_AXI_GP0_ENABLE_STATIC_REMAP == 1) ? uncompress_id(M_AXI_GP0_BID)     : M_AXI_GP0_BID;
        assign M_AXI_GP0_RID_FULL    = (C_M_AXI_GP0_ENABLE_STATIC_REMAP == 1) ? uncompress_id(M_AXI_GP0_RID)     : M_AXI_GP0_RID;      

  // Static Remap logic Enablement and Disablement for C_M_AXI1 port   

        assign M_AXI_GP1_AWID        = (C_M_AXI_GP1_ENABLE_STATIC_REMAP == 1) ? compress_id(M_AXI_GP1_AWID_FULL) : M_AXI_GP1_AWID_FULL;
        assign M_AXI_GP1_WID         = (C_M_AXI_GP1_ENABLE_STATIC_REMAP == 1) ? compress_id(M_AXI_GP1_WID_FULL)  : M_AXI_GP1_WID_FULL;   
        assign M_AXI_GP1_ARID        = (C_M_AXI_GP1_ENABLE_STATIC_REMAP == 1) ? compress_id(M_AXI_GP1_ARID_FULL) : M_AXI_GP1_ARID_FULL;      
        assign M_AXI_GP1_BID_FULL    = (C_M_AXI_GP1_ENABLE_STATIC_REMAP == 1) ? uncompress_id(M_AXI_GP1_BID)     : M_AXI_GP1_BID;
        assign M_AXI_GP1_RID_FULL    = (C_M_AXI_GP1_ENABLE_STATIC_REMAP == 1) ? uncompress_id(M_AXI_GP1_RID)     : M_AXI_GP1_RID;      


//// Compress_id and uncompress_id has been removed to address CR 642527
//// AXI interconnect v1.05.a and beyond implements dynamic ID compression/decompression.
//        assign M_AXI_GP0_AWID        =  M_AXI_GP0_AWID_FULL;
//        assign M_AXI_GP0_WID         =  M_AXI_GP0_WID_FULL;   
//        assign M_AXI_GP0_ARID        =  M_AXI_GP0_ARID_FULL;      
//        assign M_AXI_GP0_BID_FULL    =  M_AXI_GP0_BID;
//        assign M_AXI_GP0_RID_FULL    =  M_AXI_GP0_RID;      
//
//        assign M_AXI_GP1_AWID        =  M_AXI_GP1_AWID_FULL;
//        assign M_AXI_GP1_WID         =  M_AXI_GP1_WID_FULL;   
//        assign M_AXI_GP1_ARID        =  M_AXI_GP1_ARID_FULL;      
//        assign M_AXI_GP1_BID_FULL    =  M_AXI_GP1_BID;
//        assign M_AXI_GP1_RID_FULL    =  M_AXI_GP1_RID;      
						  
  
// Pipeline Stage for ENET0
	
generate
  if (C_EN_EMIO_ENET0 == 1) begin
  always @(posedge ENET0_GMII_TX_CLK)
  begin
      ENET0_GMII_TXD    <= ENET0_GMII_TXD_i;
      ENET0_GMII_TX_EN  <= ENET0_GMII_TX_EN_i; //1'b0; //ENET0_GMII_TX_EN_i;
	  ENET0_GMII_TX_ER  <= ENET0_GMII_TX_ER_i; //1'b0;//ENET0_GMII_TX_ER_i;
      ENET0_GMII_COL_i  <= ENET0_GMII_COL;
      ENET0_GMII_CRS_i  <= ENET0_GMII_CRS;
    end
	end
	else
	always@*
	 begin
	  ENET0_GMII_TXD    <= 'b0;//ENET0_GMII_TXD_i;
      ENET0_GMII_TX_EN  <= 'b0;//ENET0_GMII_TX_EN_i; //1'b0; //ENET0_GMII_TX_EN_i;
	  ENET0_GMII_TX_ER  <= 'b0;//ENET0_GMII_TX_ER_i; //1'b0;//ENET0_GMII_TX_ER_i;
	  ENET0_GMII_COL_i <= 'b0;
	  ENET0_GMII_CRS_i <= 'b0;
	 end  
endgenerate
  
generate
  if (C_EN_EMIO_ENET0 == 1) begin 
    always @(posedge ENET0_GMII_RX_CLK) 
    begin
      ENET0_GMII_RXD_i    <= ENET0_GMII_RXD;
      ENET0_GMII_RX_DV_i  <= ENET0_GMII_RX_DV;
      ENET0_GMII_RX_ER_i  <= ENET0_GMII_RX_ER;
    end
  end
	else
	begin
	always @*
	begin
	ENET0_GMII_RXD_i    <= 0;
   ENET0_GMII_RX_DV_i  <= 0;
    ENET0_GMII_RX_ER_i  <= 0;
	end
	end
endgenerate

// Pipeline Stage for ENET1
	
generate
  if (C_EN_EMIO_ENET1 == 1) begin 
    always @(posedge ENET1_GMII_TX_CLK) 
    begin
      ENET1_GMII_TXD    <= ENET1_GMII_TXD_i;
      ENET1_GMII_TX_EN  <= ENET1_GMII_TX_EN_i;
      ENET1_GMII_TX_ER  <= ENET1_GMII_TX_ER_i;
      ENET1_GMII_COL_i  <= ENET1_GMII_COL;
      ENET1_GMII_CRS_i  <= ENET1_GMII_CRS;
    end
  end
  else
  begin
  always@*
	 begin
	  ENET1_GMII_TXD    <= 'b0;//ENET0_GMII_TXD_i;
      ENET1_GMII_TX_EN  <= 'b0;//ENET0_GMII_TX_EN_i; //1'b0; //ENET0_GMII_TX_EN_i;
	  ENET1_GMII_TX_ER  <= 'b0;//ENET0_GMII_TX_ER_i; //1'b0;//ENET0_GMII_TX_ER_i;
	  ENET1_GMII_COL_i <= 0;
	  ENET1_GMII_CRS_i <= 0;
	 end  
  end
endgenerate
   
generate	
  if (C_EN_EMIO_ENET1 == 1) begin 
    always @(posedge ENET1_GMII_RX_CLK) 
    begin
      ENET1_GMII_RXD_i    <= ENET1_GMII_RXD;
      ENET1_GMII_RX_DV_i  <= ENET1_GMII_RX_DV;
      ENET1_GMII_RX_ER_i  <= ENET1_GMII_RX_ER;
    end
  end	
else
	begin
	always @*
	begin
	ENET1_GMII_RXD_i    <= 'b0;
   ENET1_GMII_RX_DV_i  <= 'b0;
  ENET1_GMII_RX_ER_i  <= 'b0;
	end
	end  
endgenerate   
   
// Trace buffer instantiated when C_INCLUDE_TRACE_BUFFER is 1.

generate
  if (C_EN_EMIO_TRACE == 1)  begin
    if (C_INCLUDE_TRACE_BUFFER == 0) begin : gen_no_trace_buffer
        
      // Pipeline Stage for Traceport ATID
      always @(posedge FTMD_TRACEIN_CLK) 
      begin
       	FTMD_TRACEIN_DATA_notracebuf    <= FTMD_TRACEIN_DATA;
        FTMD_TRACEIN_VALID_notracebuf   <= FTMD_TRACEIN_VALID;
	FTMD_TRACEIN_ATID_notracebuf    <= FTMD_TRACEIN_ATID;
      end

      assign FTMD_TRACEIN_DATA_i   = FTMD_TRACEIN_DATA_notracebuf;
      assign FTMD_TRACEIN_VALID_i  = FTMD_TRACEIN_VALID_notracebuf;
      assign FTMD_TRACEIN_ATID_i   = FTMD_TRACEIN_ATID_notracebuf;

    end else begin : gen_trace_buffer
    
      processing_system7_v5_5_trace_buffer #(.FIFO_SIZE (C_TRACE_BUFFER_FIFO_SIZE),
      .USE_TRACE_DATA_EDGE_DETECTOR(USE_TRACE_DATA_EDGE_DETECTOR),
      .C_DELAY_CLKS(C_TRACE_BUFFER_CLOCK_DELAY)
       )
      trace_buffer_i (
        .TRACE_CLK(FTMD_TRACEIN_CLK), 
        .RST(~FCLK_RESET0_N), 
        .TRACE_VALID_IN(FTMD_TRACEIN_VALID), 
        .TRACE_DATA_IN(FTMD_TRACEIN_DATA), 
        .TRACE_ATID_IN(FTMD_TRACEIN_ATID), 
        .TRACE_ATID_OUT(FTMD_TRACEIN_ATID_tracebuf), 
        .TRACE_VALID_OUT(FTMD_TRACEIN_VALID_tracebuf), 
        .TRACE_DATA_OUT(FTMD_TRACEIN_DATA_tracebuf)
      );

      assign FTMD_TRACEIN_DATA_i   = FTMD_TRACEIN_DATA_tracebuf;
      assign FTMD_TRACEIN_VALID_i  = FTMD_TRACEIN_VALID_tracebuf;
      assign FTMD_TRACEIN_ATID_i   = FTMD_TRACEIN_ATID_tracebuf;
 
    end
  end
  else
  begin
  assign FTMD_TRACEIN_DATA_i   = 1'b0;
      assign FTMD_TRACEIN_VALID_i  = 1'b0;
      assign FTMD_TRACEIN_ATID_i   = 1'b0;
	  end
endgenerate
  
   
   // ID Width Control on AXI Slave ports
   // S_AXI_GP0
   
     function [5:0] id_in_gp0;
       input [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] axi_id_gp0_in;
     begin
        case (C_S_AXI_GP0_ID_WIDTH)
              1:  id_in_gp0  = {5'b0, axi_id_gp0_in};
              2:  id_in_gp0  = {4'b0, axi_id_gp0_in};
              3:  id_in_gp0  = {3'b0, axi_id_gp0_in};
              4:  id_in_gp0  = {2'b0, axi_id_gp0_in};
              5:  id_in_gp0  = {1'b0, axi_id_gp0_in};
              6:  id_in_gp0  = axi_id_gp0_in;    
              default : id_in_gp0 =  axi_id_gp0_in;
        endcase
     end
     endfunction

    assign S_AXI_GP0_ARID_in = id_in_gp0(S_AXI_GP0_ARID);
    assign S_AXI_GP0_AWID_in = id_in_gp0(S_AXI_GP0_AWID);
    assign S_AXI_GP0_WID_in  = id_in_gp0(S_AXI_GP0_WID);

     function [5:0] id_out_gp0;
       input [(C_S_AXI_GP0_ID_WIDTH - 1) : 0] axi_id_gp0_out;
     begin
        case (C_S_AXI_GP0_ID_WIDTH)
              1:  id_out_gp0  = axi_id_gp0_out[0];
              2:  id_out_gp0  = axi_id_gp0_out[1:0];
              3:  id_out_gp0  = axi_id_gp0_out[2:0];
              4:  id_out_gp0  = axi_id_gp0_out[3:0];
              5:  id_out_gp0  = axi_id_gp0_out[4:0];
              6:  id_out_gp0  = axi_id_gp0_out;    
              default : id_out_gp0 =  axi_id_gp0_out;              
        endcase
     end
     endfunction
    
    assign S_AXI_GP0_BID_shim     = id_out_gp0(S_AXI_GP0_BID_out_shim);
    assign S_AXI_GP0_RID_shim     = id_out_gp0(S_AXI_GP0_RID_out_shim);    
   
   // S_AXI_GP1
   
     function [5:0] id_in_gp1;
       input [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] axi_id_gp1_in;
     begin
        case (C_S_AXI_GP1_ID_WIDTH)
              1:  id_in_gp1  = {5'b0, axi_id_gp1_in};
              2:  id_in_gp1  = {4'b0, axi_id_gp1_in};
              3:  id_in_gp1  = {3'b0, axi_id_gp1_in};
              4:  id_in_gp1  = {2'b0, axi_id_gp1_in};
              5:  id_in_gp1  = {1'b0, axi_id_gp1_in};
              6:  id_in_gp1  = axi_id_gp1_in;    
              default : id_in_gp1 =  axi_id_gp1_in;
        endcase
     end
     endfunction

    assign S_AXI_GP1_ARID_in = id_in_gp1(S_AXI_GP1_ARID);
    assign S_AXI_GP1_AWID_in = id_in_gp1(S_AXI_GP1_AWID);
    assign S_AXI_GP1_WID_in  = id_in_gp1(S_AXI_GP1_WID);

     function [5:0] id_out_gp1;
       input [(C_S_AXI_GP1_ID_WIDTH - 1) : 0] axi_id_gp1_out;
     begin
        case (C_S_AXI_GP1_ID_WIDTH)
              1:  id_out_gp1  = axi_id_gp1_out[0];
              2:  id_out_gp1  = axi_id_gp1_out[1:0];
              3:  id_out_gp1  = axi_id_gp1_out[2:0];
              4:  id_out_gp1  = axi_id_gp1_out[3:0];
              5:  id_out_gp1  = axi_id_gp1_out[4:0];
              6:  id_out_gp1  = axi_id_gp1_out;    
              default : id_out_gp1 =  axi_id_gp1_out;              
        endcase
     end
     endfunction
    
    assign S_AXI_GP1_BID_shim     = id_out_gp1(S_AXI_GP1_BID_out_shim);
    assign S_AXI_GP1_RID_shim     = id_out_gp1(S_AXI_GP1_RID_out_shim);    
    
// S_AXI_HP0    
    
     function [5:0] id_in_hp0;
       input [(C_S_AXI_HP0_ID_WIDTH - 1) : 0] axi_id_hp0_in;
     begin
        case (C_S_AXI_HP0_ID_WIDTH)
              1:  id_in_hp0  = {5'b0, axi_id_hp0_in};
              2:  id_in_hp0  = {4'b0, axi_id_hp0_in};
              3:  id_in_hp0  = {3'b0, axi_id_hp0_in};
              4:  id_in_hp0  = {2'b0, axi_id_hp0_in};
              5:  id_in_hp0  = {1'b0, axi_id_hp0_in};
              6:  id_in_hp0  = axi_id_hp0_in;    
              default : id_in_hp0 =  axi_id_hp0_in;
        endcase
     end
     endfunction

    assign S_AXI_HP0_ARID_in = id_in_hp0(S_AXI_HP0_ARID);
    assign S_AXI_HP0_AWID_in = id_in_hp0(S_AXI_HP0_AWID);
    assign S_AXI_HP0_WID_in  = id_in_hp0(S_AXI_HP0_WID);

     function [5:0] id_out_hp0;
       input [(C_S_AXI_HP0_ID_WIDTH - 1) : 0] axi_id_hp0_out;
     begin
        case (C_S_AXI_HP0_ID_WIDTH)
              1:  id_out_hp0  = axi_id_hp0_out[0];
              2:  id_out_hp0  = axi_id_hp0_out[1:0];
              3:  id_out_hp0  = axi_id_hp0_out[2:0];
              4:  id_out_hp0  = axi_id_hp0_out[3:0];
              5:  id_out_hp0  = axi_id_hp0_out[4:0];
              6:  id_out_hp0  = axi_id_hp0_out;    
              default : id_out_hp0 =  axi_id_hp0_out;              
        endcase
     end
     endfunction
    
    assign S_AXI_HP0_BID     = id_out_hp0(S_AXI_HP0_BID_out);
    assign S_AXI_HP0_RID     = id_out_hp0(S_AXI_HP0_RID_out);  
    
    assign S_AXI_HP0_WDATA_in        = (C_S_AXI_HP0_DATA_WIDTH == 64) ? S_AXI_HP0_WDATA : {32'b0,S_AXI_HP0_WDATA};
    assign S_AXI_HP0_WSTRB_in        = (C_S_AXI_HP0_DATA_WIDTH == 64) ? S_AXI_HP0_WSTRB : {4'b0,S_AXI_HP0_WSTRB};       
    assign S_AXI_HP0_RDATA           = (C_S_AXI_HP0_DATA_WIDTH == 64) ? S_AXI_HP0_RDATA_out : S_AXI_HP0_RDATA_out[31:0];
    
// S_AXI_HP1    

     function [5:0] id_in_hp1;
       input [(C_S_AXI_HP1_ID_WIDTH - 1) : 0] axi_id_hp1_in;
     begin
        case (C_S_AXI_HP1_ID_WIDTH)
              1:  id_in_hp1  = {5'b0, axi_id_hp1_in};
              2:  id_in_hp1  = {4'b0, axi_id_hp1_in};
              3:  id_in_hp1  = {3'b0, axi_id_hp1_in};
              4:  id_in_hp1  = {2'b0, axi_id_hp1_in};
              5:  id_in_hp1  = {1'b0, axi_id_hp1_in};
              6:  id_in_hp1  = axi_id_hp1_in;    
              default : id_in_hp1 =  axi_id_hp1_in;
        endcase
     end
     endfunction
     
     

    assign S_AXI_HP1_ARID_in = id_in_hp1(S_AXI_HP1_ARID);
    assign S_AXI_HP1_AWID_in = id_in_hp1(S_AXI_HP1_AWID);
    assign S_AXI_HP1_WID_in  = id_in_hp1(S_AXI_HP1_WID);

     function [5:0] id_out_hp1;
       input [(C_S_AXI_HP1_ID_WIDTH - 1) : 0] axi_id_hp1_out;
     begin
        case (C_S_AXI_HP1_ID_WIDTH)
              1:  id_out_hp1  = axi_id_hp1_out[0];
              2:  id_out_hp1  = axi_id_hp1_out[1:0];
              3:  id_out_hp1  = axi_id_hp1_out[2:0];
              4:  id_out_hp1  = axi_id_hp1_out[3:0];
              5:  id_out_hp1  = axi_id_hp1_out[4:0];
              6:  id_out_hp1  = axi_id_hp1_out;    
              default : id_out_hp1 =  axi_id_hp1_out;              
        endcase
     end
     endfunction
    
    assign S_AXI_HP1_BID     = id_out_hp1(S_AXI_HP1_BID_out);
    assign S_AXI_HP1_RID     = id_out_hp1(S_AXI_HP1_RID_out); 
    
    assign S_AXI_HP1_WDATA_in        = (C_S_AXI_HP1_DATA_WIDTH == 64) ? S_AXI_HP1_WDATA : {32'b0,S_AXI_HP1_WDATA};
    assign S_AXI_HP1_WSTRB_in        = (C_S_AXI_HP1_DATA_WIDTH == 64) ? S_AXI_HP1_WSTRB : {4'b0,S_AXI_HP1_WSTRB};       
    assign S_AXI_HP1_RDATA           = (C_S_AXI_HP1_DATA_WIDTH == 64) ? S_AXI_HP1_RDATA_out : S_AXI_HP1_RDATA_out[31:0];
    
    
// S_AXI_HP2    

     function [5:0] id_in_hp2;
       input [(C_S_AXI_HP2_ID_WIDTH - 1) : 0] axi_id_hp2_in;
     begin
        case (C_S_AXI_HP2_ID_WIDTH)
              1:  id_in_hp2  = {5'b0, axi_id_hp2_in};
              2:  id_in_hp2  = {4'b0, axi_id_hp2_in};
              3:  id_in_hp2  = {3'b0, axi_id_hp2_in};
              4:  id_in_hp2  = {2'b0, axi_id_hp2_in};
              5:  id_in_hp2  = {1'b0, axi_id_hp2_in};
              6:  id_in_hp2  = axi_id_hp2_in;    
              default : id_in_hp2 =  axi_id_hp2_in;
        endcase
     end
     endfunction
     
    assign S_AXI_HP2_ARID_in = id_in_hp2(S_AXI_HP2_ARID);
    assign S_AXI_HP2_AWID_in = id_in_hp2(S_AXI_HP2_AWID);
    assign S_AXI_HP2_WID_in  = id_in_hp2(S_AXI_HP2_WID);
 

     function [5:0] id_out_hp2;
       input [(C_S_AXI_HP2_ID_WIDTH - 1) : 0] axi_id_hp2_out;
     begin
        case (C_S_AXI_HP2_ID_WIDTH)
              1:  id_out_hp2  = axi_id_hp2_out[0];
              2:  id_out_hp2  = axi_id_hp2_out[1:0];
              3:  id_out_hp2  = axi_id_hp2_out[2:0];
              4:  id_out_hp2  = axi_id_hp2_out[3:0];
              5:  id_out_hp2  = axi_id_hp2_out[4:0];
              6:  id_out_hp2  = axi_id_hp2_out;    
              default : id_out_hp2 =  axi_id_hp2_out;              
        endcase
     end
     endfunction
    
    assign S_AXI_HP2_BID     = id_out_hp2(S_AXI_HP2_BID_out);
    assign S_AXI_HP2_RID     = id_out_hp2(S_AXI_HP2_RID_out);  
    
    assign S_AXI_HP2_WDATA_in        = (C_S_AXI_HP2_DATA_WIDTH == 64) ? S_AXI_HP2_WDATA : {32'b0,S_AXI_HP2_WDATA};
    assign S_AXI_HP2_WSTRB_in        = (C_S_AXI_HP2_DATA_WIDTH == 64) ? S_AXI_HP2_WSTRB : {4'b0,S_AXI_HP2_WSTRB};       
    assign S_AXI_HP2_RDATA           = (C_S_AXI_HP2_DATA_WIDTH == 64) ? S_AXI_HP2_RDATA_out : S_AXI_HP2_RDATA_out[31:0];
    
    
// S_AXI_HP3    

     function [5:0] id_in_hp3;
       input [(C_S_AXI_HP3_ID_WIDTH - 1) : 0] axi_id_hp3_in;
     begin
        case (C_S_AXI_HP3_ID_WIDTH)
              1:  id_in_hp3  = {5'b0, axi_id_hp3_in};
              2:  id_in_hp3  = {4'b0, axi_id_hp3_in};
              3:  id_in_hp3  = {3'b0, axi_id_hp3_in};
              4:  id_in_hp3  = {2'b0, axi_id_hp3_in};
              5:  id_in_hp3  = {1'b0, axi_id_hp3_in};
              6:  id_in_hp3  = axi_id_hp3_in;    
              default : id_in_hp3 =  axi_id_hp3_in;
        endcase
     end
     endfunction
     
    assign S_AXI_HP3_ARID_in = id_in_hp3(S_AXI_HP3_ARID);
    assign S_AXI_HP3_AWID_in = id_in_hp3(S_AXI_HP3_AWID);
    assign S_AXI_HP3_WID_in  = id_in_hp3(S_AXI_HP3_WID);
     


     function [5:0] id_out_hp3;
       input [(C_S_AXI_HP3_ID_WIDTH - 1) : 0] axi_id_hp3_out;
     begin
        case (C_S_AXI_HP3_ID_WIDTH)
              1:  id_out_hp3  = axi_id_hp3_out[0];
              2:  id_out_hp3  = axi_id_hp3_out[1:0];
              3:  id_out_hp3  = axi_id_hp3_out[2:0];
              4:  id_out_hp3  = axi_id_hp3_out[3:0];
              5:  id_out_hp3  = axi_id_hp3_out[4:0];
              6:  id_out_hp3  = axi_id_hp3_out;    
              default : id_out_hp3 =  axi_id_hp3_out;              
        endcase
     end
     endfunction
    
    assign S_AXI_HP3_BID     = id_out_hp3(S_AXI_HP3_BID_out);
    assign S_AXI_HP3_RID     = id_out_hp3(S_AXI_HP3_RID_out); 
    
    assign S_AXI_HP3_WDATA_in        = (C_S_AXI_HP3_DATA_WIDTH == 64) ? S_AXI_HP3_WDATA : {32'b0,S_AXI_HP3_WDATA};
    assign S_AXI_HP3_WSTRB_in        = (C_S_AXI_HP3_DATA_WIDTH == 64) ? S_AXI_HP3_WSTRB : {4'b0,S_AXI_HP3_WSTRB};       
    assign S_AXI_HP3_RDATA           = (C_S_AXI_HP3_DATA_WIDTH == 64) ? S_AXI_HP3_RDATA_out : S_AXI_HP3_RDATA_out[31:0];
    
    
// S_AXI_ACP    

     function [2:0] id_in_acp;
       input [(C_S_AXI_ACP_ID_WIDTH - 1) : 0] axi_id_acp_in;
     begin
        case (C_S_AXI_ACP_ID_WIDTH)
              1:  id_in_acp  = {2'b0, axi_id_acp_in};
              2:  id_in_acp  = {1'b0, axi_id_acp_in};
              3:  id_in_acp  = axi_id_acp_in;
              default : id_in_acp =  axi_id_acp_in;
        endcase
     end
     endfunction

    assign S_AXI_ACP_ARID_in = id_in_acp(SAXIACPARID_W);
    assign S_AXI_ACP_AWID_in = id_in_acp(SAXIACPAWID_W);
    assign S_AXI_ACP_WID_in  = id_in_acp(SAXIACPWID_W);

     function [2:0] id_out_acp;
       input [(C_S_AXI_ACP_ID_WIDTH - 1) : 0] axi_id_acp_out;
     begin
        case (C_S_AXI_ACP_ID_WIDTH)
              1:  id_out_acp  = axi_id_acp_out[0];
              2:  id_out_acp  = axi_id_acp_out[1:0];
              3:  id_out_acp  = axi_id_acp_out;
              default : id_out_acp =  axi_id_acp_out;              
        endcase
     end
     endfunction
    
    assign SAXIACPBID_W     = id_out_acp(S_AXI_ACP_BID_out);
    assign SAXIACPRID_W     = id_out_acp(S_AXI_ACP_RID_out);  
    
// FMIO Tristate Inversion logic 

//FMIO I2C0
assign        I2C0_SDA_T  = ~ I2C0_SDA_T_n;
assign        I2C0_SCL_T  = ~ I2C0_SCL_T_n;
//FMIO I2C1                     
assign        I2C1_SDA_T  = ~ I2C1_SDA_T_n;
assign        I2C1_SCL_T  = ~ I2C1_SCL_T_n;
//FMIO SPI0             
assign        SPI0_SCLK_T = ~ SPI0_SCLK_T_n;
assign        SPI0_MOSI_T = ~ SPI0_MOSI_T_n;
assign        SPI0_MISO_T = ~ SPI0_MISO_T_n;
assign        SPI0_SS_T   = ~ SPI0_SS_T_n;
//FMIO SPI1             
assign        SPI1_SCLK_T = ~ SPI1_SCLK_T_n;
assign        SPI1_MOSI_T = ~ SPI1_MOSI_T_n;
assign        SPI1_MISO_T = ~ SPI1_MISO_T_n;
assign        SPI1_SS_T   = ~ SPI1_SS_T_n;



// EMIO GEM0 MDIO
assign        ENET0_MDIO_T = ~ ENET0_MDIO_T_n;
    
// EMIO GEM1 MDIO
assign        ENET1_MDIO_T = ~ ENET1_MDIO_T_n;

// EMIO GPIO
assign        GPIO_T = ~ GPIO_T_n;

// EMIO GPIO Width Control 

  function [63:0] gpio_width_adjust_in;
    input [(C_EMIO_GPIO_WIDTH - 1) : 0] gpio_in;
  begin
     case (C_EMIO_GPIO_WIDTH)
           1:  gpio_width_adjust_in   = {63'b0, gpio_in};
           2:  gpio_width_adjust_in   = {62'b0, gpio_in};
           3:  gpio_width_adjust_in   = {61'b0, gpio_in};
           4:  gpio_width_adjust_in   = {60'b0, gpio_in};
           5:  gpio_width_adjust_in   = {59'b0, gpio_in};
           6:  gpio_width_adjust_in   = {58'b0, gpio_in};
           7:  gpio_width_adjust_in   = {57'b0, gpio_in};
           8:  gpio_width_adjust_in   = {56'b0, gpio_in};
           9:  gpio_width_adjust_in   = {55'b0, gpio_in};
           10:  gpio_width_adjust_in  = {54'b0, gpio_in};
           11:  gpio_width_adjust_in  = {53'b0, gpio_in};
           12:  gpio_width_adjust_in  = {52'b0, gpio_in};
           13:  gpio_width_adjust_in  = {51'b0, gpio_in};
           14:  gpio_width_adjust_in  = {50'b0, gpio_in};
           15:  gpio_width_adjust_in  = {49'b0, gpio_in};
           16:  gpio_width_adjust_in  = {48'b0, gpio_in};
           17:  gpio_width_adjust_in  = {47'b0, gpio_in};
           18:  gpio_width_adjust_in  = {46'b0, gpio_in};
           19:  gpio_width_adjust_in  = {45'b0, gpio_in};
           20:  gpio_width_adjust_in  = {44'b0, gpio_in};
           21:  gpio_width_adjust_in  = {43'b0, gpio_in};
           22:  gpio_width_adjust_in  = {42'b0, gpio_in};
           23:  gpio_width_adjust_in  = {41'b0, gpio_in};
           24:  gpio_width_adjust_in  = {40'b0, gpio_in};
           25:  gpio_width_adjust_in  = {39'b0, gpio_in};
           26:  gpio_width_adjust_in  = {38'b0, gpio_in};
           27:  gpio_width_adjust_in  = {37'b0, gpio_in};
           28:  gpio_width_adjust_in  = {36'b0, gpio_in};
           29:  gpio_width_adjust_in  = {35'b0, gpio_in};
           30:  gpio_width_adjust_in  = {34'b0, gpio_in};
           31:  gpio_width_adjust_in  = {33'b0, gpio_in};
           32:  gpio_width_adjust_in  = {32'b0, gpio_in};
           33:  gpio_width_adjust_in  = {31'b0, gpio_in};
           34:  gpio_width_adjust_in  = {30'b0, gpio_in};
           35:  gpio_width_adjust_in  = {29'b0, gpio_in};
           36:  gpio_width_adjust_in  = {28'b0, gpio_in};
           37:  gpio_width_adjust_in  = {27'b0, gpio_in};
           38:  gpio_width_adjust_in  = {26'b0, gpio_in};
           39:  gpio_width_adjust_in  = {25'b0, gpio_in};
           40:  gpio_width_adjust_in  = {24'b0, gpio_in};
           41:  gpio_width_adjust_in  = {23'b0, gpio_in};
           42:  gpio_width_adjust_in  = {22'b0, gpio_in};
           43:  gpio_width_adjust_in  = {21'b0, gpio_in};
           44:  gpio_width_adjust_in  = {20'b0, gpio_in};
           45:  gpio_width_adjust_in  = {19'b0, gpio_in};
           46:  gpio_width_adjust_in  = {18'b0, gpio_in};
           47:  gpio_width_adjust_in  = {17'b0, gpio_in};
           48:  gpio_width_adjust_in  = {16'b0, gpio_in};
           49:  gpio_width_adjust_in  = {15'b0, gpio_in};
           50:  gpio_width_adjust_in  = {14'b0, gpio_in};
           51:  gpio_width_adjust_in  = {13'b0, gpio_in};
           52:  gpio_width_adjust_in  = {12'b0, gpio_in};
           53:  gpio_width_adjust_in  = {11'b0, gpio_in};
           54:  gpio_width_adjust_in  = {10'b0, gpio_in};
           55:  gpio_width_adjust_in  = {9'b0, gpio_in};
           56:  gpio_width_adjust_in  = {8'b0, gpio_in};
           57:  gpio_width_adjust_in  = {7'b0, gpio_in};
           58:  gpio_width_adjust_in  = {6'b0, gpio_in};
           59:  gpio_width_adjust_in  = {5'b0, gpio_in};
           60:  gpio_width_adjust_in  = {4'b0, gpio_in};
           61:  gpio_width_adjust_in  = {3'b0, gpio_in};
           62:  gpio_width_adjust_in  = {2'b0, gpio_in};
           63:  gpio_width_adjust_in  = {1'b0, gpio_in};
           64:  gpio_width_adjust_in  = gpio_in;    
           default : gpio_width_adjust_in =  gpio_in;
     endcase
  end
  endfunction

 assign gpio_in63_0 = gpio_width_adjust_in(GPIO_I);


  function [63:0] gpio_width_adjust_out;
    input [(C_EMIO_GPIO_WIDTH - 1) : 0] gpio_o;
  begin
     case (C_EMIO_GPIO_WIDTH)
           1:  gpio_width_adjust_out    = gpio_o[0];
           2:  gpio_width_adjust_out    = gpio_o[1:0];
           3:  gpio_width_adjust_out    = gpio_o[2:0];
           4:  gpio_width_adjust_out    = gpio_o[3:0];
           5:  gpio_width_adjust_out    = gpio_o[4:0];
           6:  gpio_width_adjust_out    = gpio_o[5:0];
           7:  gpio_width_adjust_out    = gpio_o[6:0];
           8:  gpio_width_adjust_out    = gpio_o[7:0];
           9:  gpio_width_adjust_out    = gpio_o[8:0];
           10: gpio_width_adjust_out    = gpio_o[9:0];
           11: gpio_width_adjust_out    = gpio_o[10:0];
           12: gpio_width_adjust_out    = gpio_o[11:0];
           13: gpio_width_adjust_out    = gpio_o[12:0];
           14: gpio_width_adjust_out    = gpio_o[13:0];
           15: gpio_width_adjust_out    = gpio_o[14:0];
           16: gpio_width_adjust_out    = gpio_o[15:0];
           17: gpio_width_adjust_out    = gpio_o[16:0];
           18: gpio_width_adjust_out    = gpio_o[17:0];
           19: gpio_width_adjust_out    = gpio_o[18:0];
           20: gpio_width_adjust_out    = gpio_o[19:0];
           21: gpio_width_adjust_out    = gpio_o[20:0];
           22: gpio_width_adjust_out    = gpio_o[21:0];
           23: gpio_width_adjust_out    = gpio_o[22:0];
           24: gpio_width_adjust_out    = gpio_o[23:0];
           25: gpio_width_adjust_out    = gpio_o[24:0];
           26: gpio_width_adjust_out    = gpio_o[25:0];
           27: gpio_width_adjust_out    = gpio_o[26:0];
           28: gpio_width_adjust_out    = gpio_o[27:0];
           29: gpio_width_adjust_out    = gpio_o[28:0];
           30: gpio_width_adjust_out    = gpio_o[29:0];
           31: gpio_width_adjust_out    = gpio_o[30:0];
           32: gpio_width_adjust_out    = gpio_o[31:0];
           33: gpio_width_adjust_out    = gpio_o[32:0];
           34: gpio_width_adjust_out    = gpio_o[33:0];
           35: gpio_width_adjust_out    = gpio_o[34:0];
           36: gpio_width_adjust_out    = gpio_o[35:0];
           37: gpio_width_adjust_out    = gpio_o[36:0];
           38: gpio_width_adjust_out    = gpio_o[37:0];
           39: gpio_width_adjust_out    = gpio_o[38:0];
           40: gpio_width_adjust_out    = gpio_o[39:0];
           41: gpio_width_adjust_out    = gpio_o[40:0];
           42: gpio_width_adjust_out    = gpio_o[41:0];
           43: gpio_width_adjust_out    = gpio_o[42:0];
           44: gpio_width_adjust_out    = gpio_o[43:0];
           45: gpio_width_adjust_out    = gpio_o[44:0];
           46: gpio_width_adjust_out    = gpio_o[45:0];
           47: gpio_width_adjust_out    = gpio_o[46:0];
           48: gpio_width_adjust_out    = gpio_o[47:0];
           49: gpio_width_adjust_out    = gpio_o[48:0];
           50: gpio_width_adjust_out    = gpio_o[49:0];
           51: gpio_width_adjust_out    = gpio_o[50:0];
           52: gpio_width_adjust_out    = gpio_o[51:0];
           53: gpio_width_adjust_out    = gpio_o[52:0];
           54: gpio_width_adjust_out    = gpio_o[53:0];
           55: gpio_width_adjust_out    = gpio_o[54:0];
           56: gpio_width_adjust_out    = gpio_o[55:0];
           57: gpio_width_adjust_out    = gpio_o[56:0];
           58: gpio_width_adjust_out    = gpio_o[57:0];
           59: gpio_width_adjust_out    = gpio_o[58:0];
           60: gpio_width_adjust_out    = gpio_o[59:0];
           61: gpio_width_adjust_out    = gpio_o[60:0];
           62: gpio_width_adjust_out    = gpio_o[61:0];
           63: gpio_width_adjust_out    = gpio_o[62:0];
           64: gpio_width_adjust_out    = gpio_o;    
           default : gpio_width_adjust_out =  gpio_o;
     endcase
  end
  endfunction

 assign GPIO_O[(C_EMIO_GPIO_WIDTH - 1) : 0]   = gpio_width_adjust_out(gpio_out);
 assign GPIO_T_n[(C_EMIO_GPIO_WIDTH - 1) : 0] = gpio_width_adjust_out(gpio_out_t_n);

// Adding OBUFT to JTAG out port
generate
  if ( C_EN_EMIO_PJTAG == 1 ) begin : PJTAG_OBUFT_TRUE
	OBUFT jtag_obuft_inst (
	.O(PJTAG_TDO),
	.I(PJTAG_TDO_O),
	.T(PJTAG_TDO_T)  
	);
  end
  else
  begin
  assign PJTAG_TDO = 1'b0;
  end
endgenerate
// -------
// EMIO PJTAG
assign        PJTAG_TDO_T = ~ PJTAG_TDO_T_n;

// EMIO SDIO0 : No negation required as per CR#636210 for 1.0 version of  Silicon,
// FOR Other SI REV, inversion is required
 
assign        SDIO0_CMD_T       =   (C_PS7_SI_REV == "1.0") ? (SDIO0_CMD_T_n) : (~ SDIO0_CMD_T_n);
assign        SDIO0_DATA_T[3:0] =   (C_PS7_SI_REV == "1.0") ? (SDIO0_DATA_T_n[3:0]) : (~ SDIO0_DATA_T_n[3:0]);

// EMIO SDIO1 : No negation required as per CR#636210 for 1.0 version of  Silicon,
// FOR Other SI REV, inversion is required
assign        SDIO1_CMD_T       =  (C_PS7_SI_REV == "1.0") ? (SDIO1_CMD_T_n) : (~ SDIO1_CMD_T_n);
assign        SDIO1_DATA_T[3:0] =  (C_PS7_SI_REV == "1.0") ? (SDIO1_DATA_T_n[3:0]) : (~ SDIO1_DATA_T_n[3:0]);

// FCLK_CLK optional clock buffers

generate
   if (C_FCLK_CLK0_BUF == "TRUE" | C_FCLK_CLK0_BUF == "true") begin : buffer_fclk_clk_0
     BUFG FCLK_CLK_0_BUFG (.I(FCLK_CLK_unbuffered[0]), .O(FCLK_CLK_buffered[0]));
   end
   if (C_FCLK_CLK1_BUF == "TRUE" | C_FCLK_CLK1_BUF == "true") begin : buffer_fclk_clk_1
     BUFG FCLK_CLK_1_BUFG (.I(FCLK_CLK_unbuffered[1]), .O(FCLK_CLK_buffered[1]));
   end
   if (C_FCLK_CLK2_BUF == "TRUE" | C_FCLK_CLK2_BUF == "true") begin : buffer_fclk_clk_2
     BUFG FCLK_CLK_2_BUFG (.I(FCLK_CLK_unbuffered[2]), .O(FCLK_CLK_buffered[2]));
   end
   if (C_FCLK_CLK3_BUF == "TRUE" | C_FCLK_CLK3_BUF == "true") begin : buffer_fclk_clk_3
     BUFG FCLK_CLK_3_BUFG (.I(FCLK_CLK_unbuffered[3]), .O(FCLK_CLK_buffered[3]));
   end
endgenerate 

assign FCLK_CLK0_temp = (C_FCLK_CLK0_BUF == "TRUE" | C_FCLK_CLK0_BUF == "true") ? FCLK_CLK_buffered[0] : FCLK_CLK_unbuffered[0];
assign FCLK_CLK1 = (C_FCLK_CLK1_BUF == "TRUE" | C_FCLK_CLK1_BUF == "true") ? FCLK_CLK_buffered[1] : FCLK_CLK_unbuffered[1];
assign FCLK_CLK2 = (C_FCLK_CLK2_BUF == "TRUE" | C_FCLK_CLK2_BUF == "true") ? FCLK_CLK_buffered[2] : FCLK_CLK_unbuffered[2];
assign FCLK_CLK3 = (C_FCLK_CLK3_BUF == "TRUE" | C_FCLK_CLK3_BUF == "true") ? FCLK_CLK_buffered[3] : FCLK_CLK_unbuffered[3];

assign FCLK_CLK0 = FCLK_CLK0_temp;

// Adding BIBUF for fixed IO Ports and IBUF for fixed Input Ports

BIBUF DDR_CAS_n_BIBUF (.PAD(DDR_CAS_n), .IO(buffered_DDR_CAS_n));
BIBUF DDR_CKE_BIBUF (.PAD(DDR_CKE), .IO(buffered_DDR_CKE));
BIBUF DDR_Clk_n_BIBUF (.PAD(DDR_Clk_n), .IO(buffered_DDR_Clk_n));
BIBUF DDR_Clk_BIBUF (.PAD(DDR_Clk), .IO(buffered_DDR_Clk));
BIBUF DDR_CS_n_BIBUF (.PAD(DDR_CS_n), .IO(buffered_DDR_CS_n));
BIBUF DDR_DRSTB_BIBUF (.PAD(DDR_DRSTB), .IO(buffered_DDR_DRSTB));
BIBUF DDR_ODT_BIBUF (.PAD(DDR_ODT), .IO(buffered_DDR_ODT));
BIBUF DDR_RAS_n_BIBUF (.PAD(DDR_RAS_n), .IO(buffered_DDR_RAS_n));
BIBUF DDR_WEB_BIBUF (.PAD(DDR_WEB), .IO(buffered_DDR_WEB));
BIBUF DDR_VRN_BIBUF (.PAD(DDR_VRN), .IO(buffered_DDR_VRN));
BIBUF DDR_VRP_BIBUF (.PAD(DDR_VRP), .IO(buffered_DDR_VRP));
BIBUF PS_SRSTB_BIBUF (.PAD(PS_SRSTB), .IO(buffered_PS_SRSTB));
BIBUF PS_CLK_BIBUF (.PAD(PS_CLK), .IO(buffered_PS_CLK));
BIBUF PS_PORB_BIBUF (.PAD(PS_PORB), .IO(buffered_PS_PORB));

genvar i;
generate
	for (i=0; i < C_MIO_PRIMITIVE; i=i+1) begin
		BIBUF MIO_BIBUF (.PAD(MIO[i]), .IO(buffered_MIO[i]));
	end
endgenerate

generate
	for (i=0; i < 3; i=i+1) begin
		BIBUF DDR_BankAddr_BIBUF (.PAD(DDR_BankAddr[i]), .IO(buffered_DDR_BankAddr[i]));
	end
endgenerate

generate
	for (i=0; i < 15; i=i+1) begin
		BIBUF DDR_Addr_BIBUF (.PAD(DDR_Addr[i]), .IO(buffered_DDR_Addr[i]));
	end
endgenerate

generate
	for (i=0; i < C_DM_WIDTH; i=i+1) begin
		BIBUF DDR_DM_BIBUF (.PAD(DDR_DM[i]), .IO(buffered_DDR_DM[i]));
	end
endgenerate

generate
	for (i=0; i < C_DQ_WIDTH; i=i+1) begin
		BIBUF DDR_DQ_BIBUF (.PAD(DDR_DQ[i]), .IO(buffered_DDR_DQ[i]));
	end
endgenerate

generate
	for (i=0; i < C_DQS_WIDTH; i=i+1) begin
		BIBUF DDR_DQS_n_BIBUF (.PAD(DDR_DQS_n[i]), .IO(buffered_DDR_DQS_n[i]));
	end
endgenerate

generate
	for (i=0; i < C_DQS_WIDTH; i=i+1) begin
		BIBUF DDR_DQS_BIBUF (.PAD(DDR_DQS[i]), .IO(buffered_DDR_DQS[i]));
	end
endgenerate

// Connect FCLK in case of disable the AXI port for non Secure Transaction
//Start
wire S_AXI_HP0_ACLK_temp;
wire S_AXI_HP1_ACLK_temp;
wire S_AXI_HP2_ACLK_temp;
wire S_AXI_HP3_ACLK_temp;

generate
  if ( C_USE_AXI_NONSECURE == 1 && C_USE_S_AXI_HP0 == 0) begin 
   assign S_AXI_HP0_ACLK_temp = FCLK_CLK0_temp;
  end
  else begin
  assign S_AXI_HP0_ACLK_temp = S_AXI_HP0_ACLK;
  end
endgenerate

generate
  if ( C_USE_AXI_NONSECURE == 1 && C_USE_S_AXI_HP1 == 0) begin 
	assign S_AXI_HP1_ACLK_temp = FCLK_CLK0_temp;
  end
  else begin
	assign S_AXI_HP1_ACLK_temp = S_AXI_HP1_ACLK;
  end
endgenerate

generate
  if ( C_USE_AXI_NONSECURE == 1 && C_USE_S_AXI_HP2 == 0) begin 
	assign S_AXI_HP2_ACLK_temp = FCLK_CLK0_temp;
  end
  else begin
	assign S_AXI_HP2_ACLK_temp = S_AXI_HP2_ACLK;
  end
endgenerate

generate
  if ( C_USE_AXI_NONSECURE == 1 && C_USE_S_AXI_HP3 == 0) begin 
	assign S_AXI_HP3_ACLK_temp = FCLK_CLK0_temp;
  end
  else begin
	assign S_AXI_HP3_ACLK_temp = S_AXI_HP3_ACLK;
  end
endgenerate

//Start
wire M_AXI_GP0_ACLK_temp;
wire M_AXI_GP1_ACLK_temp;
wire S_AXI_GP0_ACLK_temp;
wire S_AXI_GP1_ACLK_temp;
wire S_AXI_ACP_ACLK_temp;

generate
  if ( C_USE_AXI_NONSECURE == 1 && C_USE_M_AXI_GP0 == 0) begin 
	assign M_AXI_GP0_ACLK_temp = FCLK_CLK0_temp;
  end
  else begin
	assign M_AXI_GP0_ACLK_temp = M_AXI_GP0_ACLK;  
  end
endgenerate

generate
  if ( C_USE_AXI_NONSECURE == 1 && C_USE_M_AXI_GP1 == 0) begin 
	assign M_AXI_GP1_ACLK_temp = FCLK_CLK0_temp;
  end
  else begin
	assign M_AXI_GP1_ACLK_temp = M_AXI_GP1_ACLK;    
  end
endgenerate

generate
  if ( C_USE_AXI_NONSECURE == 1 && C_USE_S_AXI_GP0 == 0) begin 
	assign S_AXI_GP0_ACLK_temp = FCLK_CLK0_temp;
  end
  else begin
	assign S_AXI_GP0_ACLK_temp = S_AXI_GP0_ACLK;    
    end
endgenerate

generate
  if ( C_USE_AXI_NONSECURE == 1 && C_USE_S_AXI_GP1 == 0) begin 
	assign S_AXI_GP1_ACLK_temp = FCLK_CLK0_temp;
  end
  else begin
	assign S_AXI_GP1_ACLK_temp = S_AXI_GP1_ACLK;      
   end
endgenerate

generate
  if ( C_USE_AXI_NONSECURE == 1 && C_USE_S_AXI_ACP == 0) begin 
	assign S_AXI_ACP_ACLK_temp = FCLK_CLK0_temp;
  end
  else begin
	assign S_AXI_ACP_ACLK_temp = S_AXI_ACP_ACLK;        
  end
endgenerate

//END
//====================
//PSS TOP             
//====================
generate 
if (C_PACKAGE_NAME == "clg225" ) begin
	wire [21:0] dummy;
	PS7 PS7_i (
	  .DMA0DATYPE		   (DMA0_DATYPE ),
	  .DMA0DAVALID		   (DMA0_DAVALID),
	  .DMA0DRREADY		   (DMA0_DRREADY),  
	  .DMA0RSTN		   (DMA0_RSTN   ),  
	  .DMA1DATYPE		   (DMA1_DATYPE ),
	  .DMA1DAVALID		   (DMA1_DAVALID),
	  .DMA1DRREADY		   (DMA1_DRREADY),
	  .DMA1RSTN		   (DMA1_RSTN   ),
	  .DMA2DATYPE		   (DMA2_DATYPE ),
	  .DMA2DAVALID		   (DMA2_DAVALID),
	  .DMA2DRREADY		   (DMA2_DRREADY),
	  .DMA2RSTN		   (DMA2_RSTN   ),
	  .DMA3DATYPE		   (DMA3_DATYPE ),
	  .DMA3DAVALID		   (DMA3_DAVALID),
	  .DMA3DRREADY		   (DMA3_DRREADY),
	  .DMA3RSTN		   (DMA3_RSTN   ),  
	  .EMIOCAN0PHYTX	   (CAN0_PHY_TX ),
	  .EMIOCAN1PHYTX	   (CAN1_PHY_TX ),  
	  .EMIOENET0GMIITXD	  (ENET0_GMII_TXD_i), // (ENET0_GMII_TXD_i ),
	  .EMIOENET0GMIITXEN	(ENET0_GMII_TX_EN_i), //   (ENET0_GMII_TX_EN_i),
	  .EMIOENET0GMIITXER	(ENET0_GMII_TX_ER_i), //   (ENET0_GMII_TX_ER_i),
	  .EMIOENET0MDIOMDC	   (ENET0_MDIO_MDC),
	  .EMIOENET0MDIOO	   (ENET0_MDIO_O  ),
	  .EMIOENET0MDIOTN	   (ENET0_MDIO_T_n  ),
	  .EMIOENET0PTPDELAYREQRX  (ENET0_PTP_DELAY_REQ_RX),
	  .EMIOENET0PTPDELAYREQTX  (ENET0_PTP_DELAY_REQ_TX),
	  .EMIOENET0PTPPDELAYREQRX (ENET0_PTP_PDELAY_REQ_RX),
	  .EMIOENET0PTPPDELAYREQTX (ENET0_PTP_PDELAY_REQ_TX),
	  .EMIOENET0PTPPDELAYRESPRX(ENET0_PTP_PDELAY_RESP_RX),
	  .EMIOENET0PTPPDELAYRESPTX(ENET0_PTP_PDELAY_RESP_TX),
	  .EMIOENET0PTPSYNCFRAMERX (ENET0_PTP_SYNC_FRAME_RX),
	  .EMIOENET0PTPSYNCFRAMETX (ENET0_PTP_SYNC_FRAME_TX),
	  .EMIOENET0SOFRX          (ENET0_SOF_RX),
	  .EMIOENET0SOFTX          (ENET0_SOF_TX),   
	  .EMIOENET1GMIITXD	   (ENET1_GMII_TXD_i), //(ENET1_GMII_TXD_i),
	  .EMIOENET1GMIITXEN	(ENET1_GMII_TX_EN_i), //  (ENET1_GMII_TX_EN_i),
	  .EMIOENET1GMIITXER	(ENET1_GMII_TX_ER_i), // (ENET1_GMII_TX_ER_i),
	  .EMIOENET1MDIOMDC	   (ENET1_MDIO_MDC),
	  .EMIOENET1MDIOO	   (ENET1_MDIO_O),
	  .EMIOENET1MDIOTN	   (ENET1_MDIO_T_n),
	  .EMIOENET1PTPDELAYREQRX  (ENET1_PTP_DELAY_REQ_RX),
	  .EMIOENET1PTPDELAYREQTX  (ENET1_PTP_DELAY_REQ_TX),
	  .EMIOENET1PTPPDELAYREQRX (ENET1_PTP_PDELAY_REQ_RX),
	  .EMIOENET1PTPPDELAYREQTX (ENET1_PTP_PDELAY_REQ_TX),
	  .EMIOENET1PTPPDELAYRESPRX(ENET1_PTP_PDELAY_RESP_RX),
	  .EMIOENET1PTPPDELAYRESPTX(ENET1_PTP_PDELAY_RESP_TX),
	  .EMIOENET1PTPSYNCFRAMERX (ENET1_PTP_SYNC_FRAME_RX),
	  .EMIOENET1PTPSYNCFRAMETX (ENET1_PTP_SYNC_FRAME_TX),
	  .EMIOENET1SOFRX          (ENET1_SOF_RX),
	  .EMIOENET1SOFTX          (ENET1_SOF_TX),  
	  .EMIOGPIOO	           (gpio_out),
	  .EMIOGPIOTN	           (gpio_out_t_n),
	  .EMIOI2C0SCLO            (I2C0_SCL_O),
	  .EMIOI2C0SCLTN           (I2C0_SCL_T_n),
	  .EMIOI2C0SDAO	           (I2C0_SDA_O),
	  .EMIOI2C0SDATN	   (I2C0_SDA_T_n),
	  .EMIOI2C1SCLO	           (I2C1_SCL_O),
	  .EMIOI2C1SCLTN           (I2C1_SCL_T_n),
	  .EMIOI2C1SDAO	           (I2C1_SDA_O),
	  .EMIOI2C1SDATN	   (I2C1_SDA_T_n),
	  .EMIOPJTAGTDO  	   (PJTAG_TDO_O),
	  .EMIOPJTAGTDTN	   (PJTAG_TDO_T_n),
	  .EMIOSDIO0BUSPOW         (SDIO0_BUSPOW),
	  .EMIOSDIO0CLK		   (SDIO0_CLK   ),
	  .EMIOSDIO0CMDO	   (SDIO0_CMD_O ),
	  .EMIOSDIO0CMDTN	   (SDIO0_CMD_T_n ),
	  .EMIOSDIO0DATAO	   (SDIO0_DATA_O),
	  .EMIOSDIO0DATATN	   (SDIO0_DATA_T_n),
	  .EMIOSDIO0LED            (SDIO0_LED),
	  .EMIOSDIO1BUSPOW         (SDIO1_BUSPOW),  
	  .EMIOSDIO1CLK            (SDIO1_CLK   ),
	  .EMIOSDIO1CMDO           (SDIO1_CMD_O ),
	  .EMIOSDIO1CMDTN          (SDIO1_CMD_T_n ),
	  .EMIOSDIO1DATAO          (SDIO1_DATA_O),
	  .EMIOSDIO1DATATN         (SDIO1_DATA_T_n),
	  .EMIOSDIO1LED            (SDIO1_LED),  
	  .EMIOSPI0MO		   (SPI0_MOSI_O),
	  .EMIOSPI0MOTN	           (SPI0_MOSI_T_n),
	  .EMIOSPI0SCLKO	   (SPI0_SCLK_O),
	  .EMIOSPI0SCLKTN	   (SPI0_SCLK_T_n),
	  .EMIOSPI0SO		   (SPI0_MISO_O),
	  .EMIOSPI0STN	           (SPI0_MISO_T_n),
	  .EMIOSPI0SSON	           ({SPI0_SS2_O,SPI0_SS1_O,SPI0_SS_O}),
	  .EMIOSPI0SSNTN	   (SPI0_SS_T_n),
	  .EMIOSPI1MO		   (SPI1_MOSI_O),
	  .EMIOSPI1MOTN	           (SPI1_MOSI_T_n),
	  .EMIOSPI1SCLKO	   (SPI1_SCLK_O),
	  .EMIOSPI1SCLKTN	   (SPI1_SCLK_T_n),
	  .EMIOSPI1SO		   (SPI1_MISO_O),
	  .EMIOSPI1STN	           (SPI1_MISO_T_n),
	  .EMIOSPI1SSON	           ({SPI1_SS2_O,SPI1_SS1_O,SPI1_SS_O}),
	  .EMIOSPI1SSNTN	   (SPI1_SS_T_n),
	  .EMIOTRACECTL		   (TRACE_CTL_i),
	  .EMIOTRACEDATA	   (TRACE_DATA_i),
	  .EMIOTTC0WAVEO	   ({TTC0_WAVE2_OUT,TTC0_WAVE1_OUT,TTC0_WAVE0_OUT}),
	  .EMIOTTC1WAVEO	   ({TTC1_WAVE2_OUT,TTC1_WAVE1_OUT,TTC1_WAVE0_OUT}),
	  .EMIOUART0DTRN	   (UART0_DTRN),
	  .EMIOUART0RTSN	   (UART0_RTSN),
	  .EMIOUART0TX		   (UART0_TX  ),
	  .EMIOUART1DTRN	   (UART1_DTRN),
	  .EMIOUART1RTSN	   (UART1_RTSN),
	  .EMIOUART1TX		   (UART1_TX  ),
	  .EMIOUSB0PORTINDCTL      (USB0_PORT_INDCTL),  
	  .EMIOUSB0VBUSPWRSELECT   (USB0_VBUS_PWRSELECT),
	  .EMIOUSB1PORTINDCTL      (USB1_PORT_INDCTL),
	  .EMIOUSB1VBUSPWRSELECT   (USB1_VBUS_PWRSELECT),  
	  .EMIOWDTRSTO    	   (WDT_RST_OUT),
	  .EVENTEVENTO             (EVENT_EVENTO),
	  .EVENTSTANDBYWFE         (EVENT_STANDBYWFE),
	  .EVENTSTANDBYWFI         (EVENT_STANDBYWFI),  
	  .FCLKCLK		   (FCLK_CLK_unbuffered),
	  .FCLKRESETN		   ({FCLK_RESET3_N,FCLK_RESET2_N,FCLK_RESET1_N,FCLK_RESET0_N}),  
	  .EMIOSDIO0BUSVOLT        (SDIO0_BUSVOLT), 
	  .EMIOSDIO1BUSVOLT        (SDIO1_BUSVOLT),  
	  .FTMTF2PTRIGACK	   ({FTMT_F2P_TRIGACK_3,FTMT_F2P_TRIGACK_2,FTMT_F2P_TRIGACK_1,FTMT_F2P_TRIGACK_0}),
	  .FTMTP2FDEBUG		   (FTMT_P2F_DEBUG  ),
	  .FTMTP2FTRIG		   ({FTMT_P2F_TRIG_3,FTMT_P2F_TRIG_2,FTMT_P2F_TRIG_1,FTMT_P2F_TRIG_0}),
	  .IRQP2F		   ({IRQ_P2F_DMAC_ABORT, IRQ_P2F_DMAC7, IRQ_P2F_DMAC6, IRQ_P2F_DMAC5, IRQ_P2F_DMAC4, IRQ_P2F_DMAC3, IRQ_P2F_DMAC2, IRQ_P2F_DMAC1, IRQ_P2F_DMAC0, IRQ_P2F_SMC, IRQ_P2F_QSPI, IRQ_P2F_CTI, IRQ_P2F_GPIO, IRQ_P2F_USB0, IRQ_P2F_ENET0, IRQ_P2F_ENET_WAKE0, IRQ_P2F_SDIO0, IRQ_P2F_I2C0, IRQ_P2F_SPI0, IRQ_P2F_UART0, IRQ_P2F_CAN0, IRQ_P2F_USB1, IRQ_P2F_ENET1, IRQ_P2F_ENET_WAKE1, IRQ_P2F_SDIO1, IRQ_P2F_I2C1, IRQ_P2F_SPI1, IRQ_P2F_UART1, IRQ_P2F_CAN1}),    
	  .MAXIGP0ARADDR	   (M_AXI_GP0_ARADDR),
	  .MAXIGP0ARBURST	   (M_AXI_GP0_ARBURST),
	  .MAXIGP0ARCACHE	   (M_AXI_GP0_ARCACHE),
	  .MAXIGP0ARESETN	   (M_AXI_GP0_ARESETN),
	  .MAXIGP0ARID	           (M_AXI_GP0_ARID_FULL   ),
	  .MAXIGP0ARLEN	           (M_AXI_GP0_ARLEN  ),
	  .MAXIGP0ARLOCK	   (M_AXI_GP0_ARLOCK ),
	  .MAXIGP0ARPROT	   (M_AXI_GP0_ARPROT ),
	  .MAXIGP0ARQOS	           (M_AXI_GP0_ARQOS  ),
	  .MAXIGP0ARSIZE	   (M_AXI_GP0_ARSIZE_i ),
	  .MAXIGP0ARVALID	   (M_AXI_GP0_ARVALID),
	  .MAXIGP0AWADDR	   (M_AXI_GP0_AWADDR ),
	  .MAXIGP0AWBURST	   (M_AXI_GP0_AWBURST),
	  .MAXIGP0AWCACHE	   (M_AXI_GP0_AWCACHE),
	  .MAXIGP0AWID	           (M_AXI_GP0_AWID_FULL   ),
	  .MAXIGP0AWLEN	           (M_AXI_GP0_AWLEN  ),
	  .MAXIGP0AWLOCK	   (M_AXI_GP0_AWLOCK ),
	  .MAXIGP0AWPROT	   (M_AXI_GP0_AWPROT ),
	  .MAXIGP0AWQOS	           (M_AXI_GP0_AWQOS  ),
	  .MAXIGP0AWSIZE	   (M_AXI_GP0_AWSIZE_i ),
	  .MAXIGP0AWVALID	   (M_AXI_GP0_AWVALID),
	  .MAXIGP0BREADY	   (M_AXI_GP0_BREADY ),
	  .MAXIGP0RREADY	   (M_AXI_GP0_RREADY ),
	  .MAXIGP0WDATA	           (M_AXI_GP0_WDATA  ),
	  .MAXIGP0WID	           (M_AXI_GP0_WID_FULL    ),
	  .MAXIGP0WLAST	           (M_AXI_GP0_WLAST  ),
	  .MAXIGP0WSTRB	           (M_AXI_GP0_WSTRB  ),
	  .MAXIGP0WVALID	   (M_AXI_GP0_WVALID ),
	  .MAXIGP1ARADDR	   (M_AXI_GP1_ARADDR ),
	  .MAXIGP1ARBURST	   (M_AXI_GP1_ARBURST),
	  .MAXIGP1ARCACHE	   (M_AXI_GP1_ARCACHE),
	  .MAXIGP1ARESETN	   (M_AXI_GP1_ARESETN),
	  .MAXIGP1ARID	           (M_AXI_GP1_ARID_FULL   ),
	  .MAXIGP1ARLEN	           (M_AXI_GP1_ARLEN  ),
	  .MAXIGP1ARLOCK	   (M_AXI_GP1_ARLOCK ),
	  .MAXIGP1ARPROT	   (M_AXI_GP1_ARPROT ),
	  .MAXIGP1ARQOS	           (M_AXI_GP1_ARQOS  ),
	  .MAXIGP1ARSIZE	   (M_AXI_GP1_ARSIZE_i ),
	  .MAXIGP1ARVALID	   (M_AXI_GP1_ARVALID),
	  .MAXIGP1AWADDR	   (M_AXI_GP1_AWADDR ),
	  .MAXIGP1AWBURST	   (M_AXI_GP1_AWBURST),
	  .MAXIGP1AWCACHE	   (M_AXI_GP1_AWCACHE),
	  .MAXIGP1AWID	           (M_AXI_GP1_AWID_FULL   ),
	  .MAXIGP1AWLEN	           (M_AXI_GP1_AWLEN  ),
	  .MAXIGP1AWLOCK	   (M_AXI_GP1_AWLOCK ),
	  .MAXIGP1AWPROT	   (M_AXI_GP1_AWPROT ),
	  .MAXIGP1AWQOS	           (M_AXI_GP1_AWQOS  ),
	  .MAXIGP1AWSIZE	   (M_AXI_GP1_AWSIZE_i ),
	  .MAXIGP1AWVALID	   (M_AXI_GP1_AWVALID),
	  .MAXIGP1BREADY	   (M_AXI_GP1_BREADY ),
	  .MAXIGP1RREADY	   (M_AXI_GP1_RREADY ),
	  .MAXIGP1WDATA	           (M_AXI_GP1_WDATA  ),
	  .MAXIGP1WID	           (M_AXI_GP1_WID_FULL    ),
	  .MAXIGP1WLAST	           (M_AXI_GP1_WLAST  ),
	  .MAXIGP1WSTRB	           (M_AXI_GP1_WSTRB  ),
	  .MAXIGP1WVALID	   (M_AXI_GP1_WVALID ),
	  .SAXIACPARESETN	   (S_AXI_ACP_ARESETN),
	  .SAXIACPARREADY	   (SAXIACPARREADY_W),
	  .SAXIACPAWREADY	   (SAXIACPAWREADY_W),
	  .SAXIACPBID	           (S_AXI_ACP_BID_out    ),
	  .SAXIACPBRESP	           (SAXIACPBRESP_W  ),
	  .SAXIACPBVALID	   (SAXIACPBVALID_W ),
	  .SAXIACPRDATA	           (SAXIACPRDATA_W  ),
	  .SAXIACPRID	           (S_AXI_ACP_RID_out),
	  .SAXIACPRLAST	           (SAXIACPRLAST_W  ),
	  .SAXIACPRRESP	           (SAXIACPRRESP_W  ),
	  .SAXIACPRVALID	   (SAXIACPRVALID_W ),
	  .SAXIACPWREADY	   (SAXIACPWREADY_W ),
	  .SAXIGP0ARESETN	   (S_AXI_GP0_ARESETN),
	  .SAXIGP0ARREADY	   (S_AXI_GP0_ARREADY_shim),
	  .SAXIGP0AWREADY	   (S_AXI_GP0_AWREADY_shim),
	  .SAXIGP0BID	           (S_AXI_GP0_BID_out_shim),
	  .SAXIGP0BRESP	           (S_AXI_GP0_BRESP_shim  ),
	  .SAXIGP0BVALID	   (S_AXI_GP0_BVALID_shim ),
	  .SAXIGP0RDATA	           (S_AXI_GP0_RDATA_shim  ),
	  .SAXIGP0RID	           (S_AXI_GP0_RID_out_shim ),
	  .SAXIGP0RLAST	           (S_AXI_GP0_RLAST_shim  ),
	  .SAXIGP0RRESP	           (S_AXI_GP0_RRESP_shim  ),
	  .SAXIGP0RVALID	   (S_AXI_GP0_RVALID_shim ),
	  .SAXIGP0WREADY	   (S_AXI_GP0_WREADY_shim ),
	  .SAXIGP1ARESETN	   (S_AXI_GP1_ARESETN),
	  .SAXIGP1ARREADY	   (S_AXI_GP1_ARREADY_shim),
	  .SAXIGP1AWREADY	   (S_AXI_GP1_AWREADY_shim),
	  .SAXIGP1BID	           (S_AXI_GP1_BID_out_shim    ),
	  .SAXIGP1BRESP	           (S_AXI_GP1_BRESP_shim  ),
	  .SAXIGP1BVALID	   (S_AXI_GP1_BVALID_shim ),
	  .SAXIGP1RDATA	           (S_AXI_GP1_RDATA_shim  ),
	  .SAXIGP1RID	           (S_AXI_GP1_RID_out_shim    ),
	  .SAXIGP1RLAST	           (S_AXI_GP1_RLAST_shim  ),
	  .SAXIGP1RRESP	           (S_AXI_GP1_RRESP_shim  ),
	  .SAXIGP1RVALID	   (S_AXI_GP1_RVALID_shim ),
	  .SAXIGP1WREADY	   (S_AXI_GP1_WREADY_shim ),
	  .SAXIHP0ARESETN	   (S_AXI_HP0_ARESETN),
	  .SAXIHP0ARREADY	   (S_AXI_HP0_ARREADY),
	  .SAXIHP0AWREADY	   (S_AXI_HP0_AWREADY),
	  .SAXIHP0BID	           (S_AXI_HP0_BID_out    ),
	  .SAXIHP0BRESP	           (S_AXI_HP0_BRESP  ),
	  .SAXIHP0BVALID	   (S_AXI_HP0_BVALID ),
	  .SAXIHP0RACOUNT          (S_AXI_HP0_RACOUNT),
	  .SAXIHP0RCOUNT	   (S_AXI_HP0_RCOUNT),
	  .SAXIHP0RDATA	           (S_AXI_HP0_RDATA_out),
	  .SAXIHP0RID	           (S_AXI_HP0_RID_out ),
	  .SAXIHP0RLAST	           (S_AXI_HP0_RLAST),
	  .SAXIHP0RRESP	           (S_AXI_HP0_RRESP),
	  .SAXIHP0RVALID	   (S_AXI_HP0_RVALID),
	  .SAXIHP0WCOUNT	   (S_AXI_HP0_WCOUNT),
	  .SAXIHP0WACOUNT          (S_AXI_HP0_WACOUNT),  
	  .SAXIHP0WREADY	   (S_AXI_HP0_WREADY),
	  .SAXIHP1ARESETN	   (S_AXI_HP1_ARESETN),
	  .SAXIHP1ARREADY	   (S_AXI_HP1_ARREADY),
	  .SAXIHP1AWREADY	   (S_AXI_HP1_AWREADY),
	  .SAXIHP1BID	           (S_AXI_HP1_BID_out    ),
	  .SAXIHP1BRESP	           (S_AXI_HP1_BRESP  ),
	  .SAXIHP1BVALID	   (S_AXI_HP1_BVALID ),
	  .SAXIHP1RACOUNT	   (S_AXI_HP1_RACOUNT ),  
	  .SAXIHP1RCOUNT	   (S_AXI_HP1_RCOUNT ),
	  .SAXIHP1RDATA	           (S_AXI_HP1_RDATA_out),
	  .SAXIHP1RID	           (S_AXI_HP1_RID_out    ),
	  .SAXIHP1RLAST	           (S_AXI_HP1_RLAST  ),
	  .SAXIHP1RRESP	           (S_AXI_HP1_RRESP  ),
	  .SAXIHP1RVALID	   (S_AXI_HP1_RVALID),
	  .SAXIHP1WACOUNT	   (S_AXI_HP1_WACOUNT),  
	  .SAXIHP1WCOUNT	   (S_AXI_HP1_WCOUNT),
	  .SAXIHP1WREADY	   (S_AXI_HP1_WREADY),
	  .SAXIHP2ARESETN	   (S_AXI_HP2_ARESETN),
	  .SAXIHP2ARREADY	   (S_AXI_HP2_ARREADY),
	  .SAXIHP2AWREADY	   (S_AXI_HP2_AWREADY),
	  .SAXIHP2BID	           (S_AXI_HP2_BID_out ),
	  .SAXIHP2BRESP	           (S_AXI_HP2_BRESP),
	  .SAXIHP2BVALID	   (S_AXI_HP2_BVALID),
	  .SAXIHP2RACOUNT	   (S_AXI_HP2_RACOUNT),  
	  .SAXIHP2RCOUNT	   (S_AXI_HP2_RCOUNT),
	  .SAXIHP2RDATA	           (S_AXI_HP2_RDATA_out),
	  .SAXIHP2RID	           (S_AXI_HP2_RID_out ),
	  .SAXIHP2RLAST	           (S_AXI_HP2_RLAST),
	  .SAXIHP2RRESP	           (S_AXI_HP2_RRESP),
	  .SAXIHP2RVALID	   (S_AXI_HP2_RVALID),
	  .SAXIHP2WACOUNT	   (S_AXI_HP2_WACOUNT),  
	  .SAXIHP2WCOUNT	   (S_AXI_HP2_WCOUNT),
	  .SAXIHP2WREADY	   (S_AXI_HP2_WREADY),
	  .SAXIHP3ARESETN	   (S_AXI_HP3_ARESETN),
	  .SAXIHP3ARREADY	   (S_AXI_HP3_ARREADY),
	  .SAXIHP3AWREADY	   (S_AXI_HP3_AWREADY),
	  .SAXIHP3BID	           (S_AXI_HP3_BID_out),
	  .SAXIHP3BRESP	           (S_AXI_HP3_BRESP),
	  .SAXIHP3BVALID	   (S_AXI_HP3_BVALID),
	  .SAXIHP3RACOUNT	   (S_AXI_HP3_RACOUNT),    
	  .SAXIHP3RCOUNT	   (S_AXI_HP3_RCOUNT),
	  .SAXIHP3RDATA	           (S_AXI_HP3_RDATA_out),
	  .SAXIHP3RID	           (S_AXI_HP3_RID_out),
	  .SAXIHP3RLAST	           (S_AXI_HP3_RLAST),
	  .SAXIHP3RRESP	           (S_AXI_HP3_RRESP),
	  .SAXIHP3RVALID	   (S_AXI_HP3_RVALID),
	  .SAXIHP3WCOUNT	   (S_AXI_HP3_WCOUNT),
	  .SAXIHP3WACOUNT	   (S_AXI_HP3_WACOUNT),    
	  .SAXIHP3WREADY	   (S_AXI_HP3_WREADY), 
	  .DDRARB                  (DDR_ARB), 
	  .DMA0ACLK		   (DMA0_ACLK   ),
	  .DMA0DAREADY		   (DMA0_DAREADY),
	  .DMA0DRLAST		   (DMA0_DRLAST ),
	  .DMA0DRTYPE              (DMA0_DRTYPE),
	  .DMA0DRVALID		   (DMA0_DRVALID),
	  .DMA1ACLK		   (DMA1_ACLK   ),
	  .DMA1DAREADY		   (DMA1_DAREADY),
	  .DMA1DRLAST		   (DMA1_DRLAST ),
	  .DMA1DRTYPE              (DMA1_DRTYPE),  
	  .DMA1DRVALID		   (DMA1_DRVALID),
	  .DMA2ACLK		   (DMA2_ACLK   ),
	  .DMA2DAREADY		   (DMA2_DAREADY),
	  .DMA2DRLAST		   (DMA2_DRLAST ),
	  .DMA2DRTYPE              (DMA2_DRTYPE),    
	  .DMA2DRVALID		   (DMA2_DRVALID),
	  .DMA3ACLK		   (DMA3_ACLK   ),
	  .DMA3DAREADY		   (DMA3_DAREADY),
	  .DMA3DRLAST		   (DMA3_DRLAST ),
	  .DMA3DRTYPE              (DMA3_DRTYPE),      
	  .DMA3DRVALID		   (DMA3_DRVALID),
	  .EMIOCAN0PHYRX	   (CAN0_PHY_RX),  
	  .EMIOCAN1PHYRX	   (CAN1_PHY_RX),
	  .EMIOENET0EXTINTIN       (ENET0_EXT_INTIN),  
	  .EMIOENET0GMIICOL        (ENET0_GMII_COL_i),
	  .EMIOENET0GMIICRS        (ENET0_GMII_CRS_i),
	  .EMIOENET0GMIIRXCLK      (ENET0_GMII_RX_CLK),
	  .EMIOENET0GMIIRXD        (ENET0_GMII_RXD_i),
	  .EMIOENET0GMIIRXDV       (ENET0_GMII_RX_DV_i),
	  .EMIOENET0GMIIRXER       (ENET0_GMII_RX_ER_i),
	  .EMIOENET0GMIITXCLK      (ENET0_GMII_TX_CLK),
	  .EMIOENET0MDIOI          (ENET0_MDIO_I),
	  .EMIOENET1EXTINTIN       (ENET1_EXT_INTIN),    
	  .EMIOENET1GMIICOL        (ENET1_GMII_COL_i),
	  .EMIOENET1GMIICRS        (ENET1_GMII_CRS_i),
	  .EMIOENET1GMIIRXCLK      (ENET1_GMII_RX_CLK),
	  .EMIOENET1GMIIRXD        (ENET1_GMII_RXD_i),
	  .EMIOENET1GMIIRXDV       (ENET1_GMII_RX_DV_i),
	  .EMIOENET1GMIIRXER       (ENET1_GMII_RX_ER_i),
	  .EMIOENET1GMIITXCLK      (ENET1_GMII_TX_CLK),
	  .EMIOENET1MDIOI          (ENET1_MDIO_I),  
	  .EMIOGPIOI	           (gpio_in63_0  ),
	  .EMIOI2C0SCLI	           (I2C0_SCL_I),
	  .EMIOI2C0SDAI	           (I2C0_SDA_I),
	  .EMIOI2C1SCLI	           (I2C1_SCL_I),
	  .EMIOI2C1SDAI	           (I2C1_SDA_I),
	  .EMIOPJTAGTCK		   (PJTAG_TCK),
	  .EMIOPJTAGTDI		   (PJTAG_TDI),
	  .EMIOPJTAGTMS		   (PJTAG_TMS),
	  .EMIOSDIO0CDN            (SDIO0_CDN),
	  .EMIOSDIO0CLKFB	   (SDIO0_CLK_FB  ),
	  .EMIOSDIO0CMDI	   (SDIO0_CMD_I   ),
	  .EMIOSDIO0DATAI	   (SDIO0_DATA_I  ),
	  .EMIOSDIO0WP             (SDIO0_WP),
	  .EMIOSDIO1CDN            (SDIO1_CDN),  
	  .EMIOSDIO1CLKFB	   (SDIO1_CLK_FB  ),
	  .EMIOSDIO1CMDI	   (SDIO1_CMD_I   ),
	  .EMIOSDIO1DATAI	   (SDIO1_DATA_I  ),
	  .EMIOSDIO1WP             (SDIO1_WP),
	  .EMIOSPI0MI		   (SPI0_MISO_I),
	  .EMIOSPI0SCLKI	   (SPI0_SCLK_I),
	  .EMIOSPI0SI		   (SPI0_MOSI_I),
	  .EMIOSPI0SSIN 	   (SPI0_SS_I),
	  .EMIOSPI1MI		   (SPI1_MISO_I),
	  .EMIOSPI1SCLKI	   (SPI1_SCLK_I),
	  .EMIOSPI1SI		   (SPI1_MOSI_I),
	  .EMIOSPI1SSIN	           (SPI1_SS_I),
	  .EMIOSRAMINTIN           (SRAM_INTIN),  
	  .EMIOTRACECLK		   (TRACE_CLK),
	  .EMIOTTC0CLKI	           ({TTC0_CLK2_IN, TTC0_CLK1_IN, TTC0_CLK0_IN}),
	  .EMIOTTC1CLKI	           ({TTC1_CLK2_IN, TTC1_CLK1_IN, TTC1_CLK0_IN}),
	  .EMIOUART0CTSN	   (UART0_CTSN),
	  .EMIOUART0DCDN	   (UART0_DCDN),
	  .EMIOUART0DSRN	   (UART0_DSRN),
	  .EMIOUART0RIN		   (UART0_RIN ),
	  .EMIOUART0RX		   (UART0_RX  ),
	  .EMIOUART1CTSN	   (UART1_CTSN),
	  .EMIOUART1DCDN	   (UART1_DCDN),
	  .EMIOUART1DSRN	   (UART1_DSRN),
	  .EMIOUART1RIN		   (UART1_RIN ),
	  .EMIOUART1RX		   (UART1_RX  ),
	  .EMIOUSB0VBUSPWRFAULT    (USB0_VBUS_PWRFAULT),
	  .EMIOUSB1VBUSPWRFAULT    (USB1_VBUS_PWRFAULT),  
	  .EMIOWDTCLKI		   (WDT_CLK_IN),  
	  .EVENTEVENTI             (EVENT_EVENTI),
	  .FCLKCLKTRIGN		   (fclk_clktrig_gnd),
	  .FPGAIDLEN		   (FPGA_IDLE_N),  
	  .FTMDTRACEINATID	   (FTMD_TRACEIN_ATID_i),  
	  .FTMDTRACEINCLOCK	   (FTMD_TRACEIN_CLK),
	  .FTMDTRACEINDATA	   (FTMD_TRACEIN_DATA_i),
	  .FTMDTRACEINVALID	   (FTMD_TRACEIN_VALID_i),
	  .FTMTF2PDEBUG		   (FTMT_F2P_DEBUG  ),
	  .FTMTF2PTRIG		   ({FTMT_F2P_TRIG_3,FTMT_F2P_TRIG_2,FTMT_F2P_TRIG_1,FTMT_F2P_TRIG_0}),
	  .FTMTP2FTRIGACK	   ({FTMT_P2F_TRIGACK_3,FTMT_P2F_TRIGACK_2,FTMT_P2F_TRIGACK_1,FTMT_P2F_TRIGACK_0}),  
	  .IRQF2P		   (irq_f2p_i),  
	  .MAXIGP0ACLK	           (M_AXI_GP0_ACLK_temp),
	  .MAXIGP0ARREADY	   (M_AXI_GP0_ARREADY),
	  .MAXIGP0AWREADY	   (M_AXI_GP0_AWREADY),
	  .MAXIGP0BID	           (M_AXI_GP0_BID_FULL    ),
	  .MAXIGP0BRESP	           (M_AXI_GP0_BRESP  ),
	  .MAXIGP0BVALID	   (M_AXI_GP0_BVALID ),
	  .MAXIGP0RDATA	           (M_AXI_GP0_RDATA  ),
	  .MAXIGP0RID	           (M_AXI_GP0_RID_FULL    ),
	  .MAXIGP0RLAST	           (M_AXI_GP0_RLAST  ),
	  .MAXIGP0RRESP	           (M_AXI_GP0_RRESP  ),
	  .MAXIGP0RVALID	   (M_AXI_GP0_RVALID ),
	  .MAXIGP0WREADY	   (M_AXI_GP0_WREADY ),
	  .MAXIGP1ACLK	           (M_AXI_GP1_ACLK_temp   ),
	  .MAXIGP1ARREADY	   (M_AXI_GP1_ARREADY),
	  .MAXIGP1AWREADY	   (M_AXI_GP1_AWREADY),
	  .MAXIGP1BID	           (M_AXI_GP1_BID_FULL ),
	  .MAXIGP1BRESP	           (M_AXI_GP1_BRESP  ),
	  .MAXIGP1BVALID	   (M_AXI_GP1_BVALID ),
	  .MAXIGP1RDATA	           (M_AXI_GP1_RDATA  ),
	  .MAXIGP1RID	           (M_AXI_GP1_RID_FULL    ),
	  .MAXIGP1RLAST	           (M_AXI_GP1_RLAST  ),
	  .MAXIGP1RRESP	           (M_AXI_GP1_RRESP  ),
	  .MAXIGP1RVALID	   (M_AXI_GP1_RVALID ),
	  .MAXIGP1WREADY	   (M_AXI_GP1_WREADY ),  
	  .SAXIACPACLK	           (S_AXI_ACP_ACLK_temp   ),
	  .SAXIACPARADDR	   (SAXIACPARADDR_W ),
	  .SAXIACPARBURST	   (SAXIACPARBURST_W),
	  .SAXIACPARCACHE	   (SAXIACPARCACHE_W),
	  .SAXIACPARID	           (S_AXI_ACP_ARID_in   ),
	  .SAXIACPARLEN	           (SAXIACPARLEN_W  ),
	  .SAXIACPARLOCK	   (SAXIACPARLOCK_W ),
	  .SAXIACPARPROT	   (SAXIACPARPROT_W ),
	  .SAXIACPARQOS	           (S_AXI_ACP_ARQOS  ),
	  .SAXIACPARSIZE	   (SAXIACPARSIZE_W[1:0] ),
	  .SAXIACPARUSER	   (SAXIACPARUSER_W ),
	  .SAXIACPARVALID	   (SAXIACPARVALID_W),
	  .SAXIACPAWADDR	   (SAXIACPAWADDR_W ),
	  .SAXIACPAWBURST	   (SAXIACPAWBURST_W),
	  .SAXIACPAWCACHE	   (SAXIACPAWCACHE_W),
	  .SAXIACPAWID	           (S_AXI_ACP_AWID_in   ),
	  .SAXIACPAWLEN	           (SAXIACPAWLEN_W  ),
	  .SAXIACPAWLOCK	   (SAXIACPAWLOCK_W ),
	  .SAXIACPAWPROT	   (SAXIACPAWPROT_W ),
	  .SAXIACPAWQOS	           (S_AXI_ACP_AWQOS  ),
	  .SAXIACPAWSIZE	   (SAXIACPAWSIZE_W[1:0] ),
	  .SAXIACPAWUSER	   (SAXIACPAWUSER_W ),
	  .SAXIACPAWVALID	   (SAXIACPAWVALID_W),
	  .SAXIACPBREADY	   (SAXIACPBREADY_W ),
	  .SAXIACPRREADY	   (SAXIACPRREADY_W ),
	  .SAXIACPWDATA	           (SAXIACPWDATA_W  ),
	  .SAXIACPWID	           (S_AXI_ACP_WID_in    ),
	  .SAXIACPWLAST	           (SAXIACPWLAST_W  ),
	  .SAXIACPWSTRB	           (SAXIACPWSTRB_W  ),
	  .SAXIACPWVALID	   (SAXIACPWVALID_W ),
	  .SAXIGP0ACLK             (S_AXI_GP0_ACLK_temp   ),
	  .SAXIGP0ARADDR           (S_AXI_GP0_ARADDR_shim ),
	  .SAXIGP0ARBURST          (S_AXI_GP0_ARBURST_shim),
	  .SAXIGP0ARCACHE          (S_AXI_GP0_ARCACHE_shim),
	  .SAXIGP0ARID             (S_AXI_GP0_ARID_in_shim   ),
	  .SAXIGP0ARLEN            (S_AXI_GP0_ARLEN_shim  ),
	  .SAXIGP0ARLOCK           (S_AXI_GP0_ARLOCK_shim ),
	  .SAXIGP0ARPROT           (S_AXI_GP0_ARPROT_shim ),
	  .SAXIGP0ARQOS            (S_AXI_GP0_ARQOS_shim  ),
	  .SAXIGP0ARSIZE           (S_AXI_GP0_ARSIZE_shim[1:0] ),
	  .SAXIGP0ARVALID          (S_AXI_GP0_ARVALID_shim),
	  .SAXIGP0AWADDR           (S_AXI_GP0_AWADDR_shim ),
	  .SAXIGP0AWBURST          (S_AXI_GP0_AWBURST_shim),
	  .SAXIGP0AWCACHE          (S_AXI_GP0_AWCACHE_shim),
	  .SAXIGP0AWID             (S_AXI_GP0_AWID_in_shim   ),
	  .SAXIGP0AWLEN            (S_AXI_GP0_AWLEN_shim  ),
	  .SAXIGP0AWLOCK           (S_AXI_GP0_AWLOCK_shim ),
	  .SAXIGP0AWPROT           (S_AXI_GP0_AWPROT_shim ),
	  .SAXIGP0AWQOS            (S_AXI_GP0_AWQOS_shim  ),
	  .SAXIGP0AWSIZE           (S_AXI_GP0_AWSIZE_shim[1:0] ),
	  .SAXIGP0AWVALID          (S_AXI_GP0_AWVALID_shim),
	  .SAXIGP0BREADY           (S_AXI_GP0_BREADY_shim ),
	  .SAXIGP0RREADY           (S_AXI_GP0_RREADY_shim ),
	  .SAXIGP0WDATA            (S_AXI_GP0_WDATA_shim  ),
	  .SAXIGP0WID              (S_AXI_GP0_WID_in_shim ),
	  .SAXIGP0WLAST            (S_AXI_GP0_WLAST_shim  ),
	  .SAXIGP0WSTRB            (S_AXI_GP0_WSTRB_shim  ),
	  .SAXIGP0WVALID           (S_AXI_GP0_WVALID_shim ),
	  .SAXIGP1ACLK	           (S_AXI_GP1_ACLK_temp   ),
	  .SAXIGP1ARADDR	   (S_AXI_GP1_ARADDR_shim ),
	  .SAXIGP1ARBURST	   (S_AXI_GP1_ARBURST_shim),
	  .SAXIGP1ARCACHE	   (S_AXI_GP1_ARCACHE_shim),
	  .SAXIGP1ARID	           (S_AXI_GP1_ARID_in_shim   ),
	  .SAXIGP1ARLEN	           (S_AXI_GP1_ARLEN_shim  ),
	  .SAXIGP1ARLOCK	   (S_AXI_GP1_ARLOCK_shim ),
	  .SAXIGP1ARPROT	   (S_AXI_GP1_ARPROT_shim ),
	  .SAXIGP1ARQOS	           (S_AXI_GP1_ARQOS_shim  ),
	  .SAXIGP1ARSIZE	   (S_AXI_GP1_ARSIZE_shim[1:0] ),
	  .SAXIGP1ARVALID	   (S_AXI_GP1_ARVALID_shim),
	  .SAXIGP1AWADDR	   (S_AXI_GP1_AWADDR_shim ),
	  .SAXIGP1AWBURST	   (S_AXI_GP1_AWBURST_shim),
	  .SAXIGP1AWCACHE	   (S_AXI_GP1_AWCACHE_shim),
	  .SAXIGP1AWID	           (S_AXI_GP1_AWID_in_shim   ),
	  .SAXIGP1AWLEN	           (S_AXI_GP1_AWLEN_shim  ),
	  .SAXIGP1AWLOCK	   (S_AXI_GP1_AWLOCK_shim ),
	  .SAXIGP1AWPROT	   (S_AXI_GP1_AWPROT_shim ),
	  .SAXIGP1AWQOS	           (S_AXI_GP1_AWQOS_shim  ),
	  .SAXIGP1AWSIZE	   (S_AXI_GP1_AWSIZE_shim[1:0] ),
	  .SAXIGP1AWVALID	   (S_AXI_GP1_AWVALID_shim),
	  .SAXIGP1BREADY	   (S_AXI_GP1_BREADY_shim ),
	  .SAXIGP1RREADY	   (S_AXI_GP1_RREADY_shim ),
	  .SAXIGP1WDATA	           (S_AXI_GP1_WDATA_shim  ),
	  .SAXIGP1WID	           (S_AXI_GP1_WID_in_shim    ),
	  .SAXIGP1WLAST	           (S_AXI_GP1_WLAST_shim  ),
	  .SAXIGP1WSTRB	           (S_AXI_GP1_WSTRB_shim  ),
	  .SAXIGP1WVALID	   (S_AXI_GP1_WVALID_shim ),  
	  .SAXIHP0ACLK             (S_AXI_HP0_ACLK_temp   ),
	  .SAXIHP0ARADDR           (S_AXI_HP0_ARADDR),
	  .SAXIHP0ARBURST          (S_AXI_HP0_ARBURST),
	  .SAXIHP0ARCACHE          (S_AXI_HP0_ARCACHE),
	  .SAXIHP0ARID             (S_AXI_HP0_ARID_in),
	  .SAXIHP0ARLEN            (S_AXI_HP0_ARLEN),
	  .SAXIHP0ARLOCK           (S_AXI_HP0_ARLOCK),
	  .SAXIHP0ARPROT           (S_AXI_HP0_ARPROT),
	  .SAXIHP0ARQOS            (S_AXI_HP0_ARQOS),
	  .SAXIHP0ARSIZE           (S_AXI_HP0_ARSIZE[1:0]),
	  .SAXIHP0ARVALID          (S_AXI_HP0_ARVALID),
	  .SAXIHP0AWADDR           (S_AXI_HP0_AWADDR),
	  .SAXIHP0AWBURST          (S_AXI_HP0_AWBURST),
	  .SAXIHP0AWCACHE          (S_AXI_HP0_AWCACHE),
	  .SAXIHP0AWID             (S_AXI_HP0_AWID_in),
	  .SAXIHP0AWLEN            (S_AXI_HP0_AWLEN),
	  .SAXIHP0AWLOCK           (S_AXI_HP0_AWLOCK),
	  .SAXIHP0AWPROT           (S_AXI_HP0_AWPROT),
	  .SAXIHP0AWQOS            (S_AXI_HP0_AWQOS),
	  .SAXIHP0AWSIZE           (S_AXI_HP0_AWSIZE[1:0]),
	  .SAXIHP0AWVALID          (S_AXI_HP0_AWVALID),
	  .SAXIHP0BREADY           (S_AXI_HP0_BREADY),
	  .SAXIHP0RDISSUECAP1EN    (S_AXI_HP0_RDISSUECAP1_EN),
	  .SAXIHP0RREADY           (S_AXI_HP0_RREADY),
	  .SAXIHP0WDATA            (S_AXI_HP0_WDATA_in),
	  .SAXIHP0WID              (S_AXI_HP0_WID_in),
	  .SAXIHP0WLAST            (S_AXI_HP0_WLAST),
	  .SAXIHP0WRISSUECAP1EN    (S_AXI_HP0_WRISSUECAP1_EN),
	  .SAXIHP0WSTRB            (S_AXI_HP0_WSTRB_in),
	  .SAXIHP0WVALID           (S_AXI_HP0_WVALID),
	  .SAXIHP1ACLK             (S_AXI_HP1_ACLK_temp),
	  .SAXIHP1ARADDR           (S_AXI_HP1_ARADDR),
	  .SAXIHP1ARBURST          (S_AXI_HP1_ARBURST),
	  .SAXIHP1ARCACHE          (S_AXI_HP1_ARCACHE),
	  .SAXIHP1ARID             (S_AXI_HP1_ARID_in),
	  .SAXIHP1ARLEN            (S_AXI_HP1_ARLEN),
	  .SAXIHP1ARLOCK           (S_AXI_HP1_ARLOCK),
	  .SAXIHP1ARPROT           (S_AXI_HP1_ARPROT),
	  .SAXIHP1ARQOS            (S_AXI_HP1_ARQOS),
	  .SAXIHP1ARSIZE           (S_AXI_HP1_ARSIZE[1:0]),
	  .SAXIHP1ARVALID          (S_AXI_HP1_ARVALID),
	  .SAXIHP1AWADDR           (S_AXI_HP1_AWADDR),
	  .SAXIHP1AWBURST          (S_AXI_HP1_AWBURST),
	  .SAXIHP1AWCACHE          (S_AXI_HP1_AWCACHE),
	  .SAXIHP1AWID             (S_AXI_HP1_AWID_in),
	  .SAXIHP1AWLEN            (S_AXI_HP1_AWLEN),
	  .SAXIHP1AWLOCK           (S_AXI_HP1_AWLOCK),
	  .SAXIHP1AWPROT           (S_AXI_HP1_AWPROT),
	  .SAXIHP1AWQOS            (S_AXI_HP1_AWQOS),
	  .SAXIHP1AWSIZE           (S_AXI_HP1_AWSIZE[1:0]),
	  .SAXIHP1AWVALID          (S_AXI_HP1_AWVALID),
	  .SAXIHP1BREADY           (S_AXI_HP1_BREADY),
	  .SAXIHP1RDISSUECAP1EN    (S_AXI_HP1_RDISSUECAP1_EN),
	  .SAXIHP1RREADY           (S_AXI_HP1_RREADY),
	  .SAXIHP1WDATA            (S_AXI_HP1_WDATA_in),
	  .SAXIHP1WID              (S_AXI_HP1_WID_in),
	  .SAXIHP1WLAST            (S_AXI_HP1_WLAST),
	  .SAXIHP1WRISSUECAP1EN    (S_AXI_HP1_WRISSUECAP1_EN),
	  .SAXIHP1WSTRB            (S_AXI_HP1_WSTRB_in),
	  .SAXIHP1WVALID           (S_AXI_HP1_WVALID),
	  .SAXIHP2ACLK             (S_AXI_HP2_ACLK_temp),
	  .SAXIHP2ARADDR           (S_AXI_HP2_ARADDR),
	  .SAXIHP2ARBURST          (S_AXI_HP2_ARBURST),
	  .SAXIHP2ARCACHE          (S_AXI_HP2_ARCACHE),
	  .SAXIHP2ARID             (S_AXI_HP2_ARID_in),
	  .SAXIHP2ARLEN            (S_AXI_HP2_ARLEN),
	  .SAXIHP2ARLOCK           (S_AXI_HP2_ARLOCK),
	  .SAXIHP2ARPROT           (S_AXI_HP2_ARPROT),
	  .SAXIHP2ARQOS            (S_AXI_HP2_ARQOS),
	  .SAXIHP2ARSIZE           (S_AXI_HP2_ARSIZE[1:0]),
	  .SAXIHP2ARVALID          (S_AXI_HP2_ARVALID),
	  .SAXIHP2AWADDR           (S_AXI_HP2_AWADDR),
	  .SAXIHP2AWBURST          (S_AXI_HP2_AWBURST),
	  .SAXIHP2AWCACHE          (S_AXI_HP2_AWCACHE),
	  .SAXIHP2AWID             (S_AXI_HP2_AWID_in),
	  .SAXIHP2AWLEN            (S_AXI_HP2_AWLEN),
	  .SAXIHP2AWLOCK           (S_AXI_HP2_AWLOCK),
	  .SAXIHP2AWPROT           (S_AXI_HP2_AWPROT),
	  .SAXIHP2AWQOS            (S_AXI_HP2_AWQOS),
	  .SAXIHP2AWSIZE           (S_AXI_HP2_AWSIZE[1:0]),
	  .SAXIHP2AWVALID          (S_AXI_HP2_AWVALID),
	  .SAXIHP2BREADY           (S_AXI_HP2_BREADY),
	  .SAXIHP2RDISSUECAP1EN    (S_AXI_HP2_RDISSUECAP1_EN),
	  .SAXIHP2RREADY           (S_AXI_HP2_RREADY),
	  .SAXIHP2WDATA            (S_AXI_HP2_WDATA_in),
	  .SAXIHP2WID              (S_AXI_HP2_WID_in),
	  .SAXIHP2WLAST            (S_AXI_HP2_WLAST),
	  .SAXIHP2WRISSUECAP1EN    (S_AXI_HP2_WRISSUECAP1_EN),
	  .SAXIHP2WSTRB            (S_AXI_HP2_WSTRB_in),
	  .SAXIHP2WVALID           (S_AXI_HP2_WVALID),  
	  .SAXIHP3ACLK             (S_AXI_HP3_ACLK_temp),
	  .SAXIHP3ARADDR           (S_AXI_HP3_ARADDR ),
	  .SAXIHP3ARBURST          (S_AXI_HP3_ARBURST),
	  .SAXIHP3ARCACHE          (S_AXI_HP3_ARCACHE),
	  .SAXIHP3ARID             (S_AXI_HP3_ARID_in   ),
	  .SAXIHP3ARLEN            (S_AXI_HP3_ARLEN),
	  .SAXIHP3ARLOCK           (S_AXI_HP3_ARLOCK),
	  .SAXIHP3ARPROT           (S_AXI_HP3_ARPROT),
	  .SAXIHP3ARQOS            (S_AXI_HP3_ARQOS),
	  .SAXIHP3ARSIZE           (S_AXI_HP3_ARSIZE[1:0]),
	  .SAXIHP3ARVALID          (S_AXI_HP3_ARVALID),
	  .SAXIHP3AWADDR           (S_AXI_HP3_AWADDR),
	  .SAXIHP3AWBURST          (S_AXI_HP3_AWBURST),
	  .SAXIHP3AWCACHE          (S_AXI_HP3_AWCACHE),
	  .SAXIHP3AWID             (S_AXI_HP3_AWID_in),
	  .SAXIHP3AWLEN            (S_AXI_HP3_AWLEN),
	  .SAXIHP3AWLOCK           (S_AXI_HP3_AWLOCK),
	  .SAXIHP3AWPROT           (S_AXI_HP3_AWPROT),
	  .SAXIHP3AWQOS            (S_AXI_HP3_AWQOS),
	  .SAXIHP3AWSIZE           (S_AXI_HP3_AWSIZE[1:0]),
	  .SAXIHP3AWVALID          (S_AXI_HP3_AWVALID),
	  .SAXIHP3BREADY           (S_AXI_HP3_BREADY),
	  .SAXIHP3RDISSUECAP1EN    (S_AXI_HP3_RDISSUECAP1_EN),
	  .SAXIHP3RREADY           (S_AXI_HP3_RREADY),
	  .SAXIHP3WDATA            (S_AXI_HP3_WDATA_in),
	  .SAXIHP3WID              (S_AXI_HP3_WID_in),
	  .SAXIHP3WLAST            (S_AXI_HP3_WLAST),
	  .SAXIHP3WRISSUECAP1EN    (S_AXI_HP3_WRISSUECAP1_EN),
	  .SAXIHP3WSTRB            (S_AXI_HP3_WSTRB_in),
	  .SAXIHP3WVALID           (S_AXI_HP3_WVALID),
	  .DDRA		           (buffered_DDR_Addr),
	  .DDRBA		   (buffered_DDR_BankAddr),
	  .DDRCASB		   (buffered_DDR_CAS_n),
	  .DDRCKE		   (buffered_DDR_CKE),
	  .DDRCKN		   (buffered_DDR_Clk_n),
	  .DDRCKP		   (buffered_DDR_Clk),
	  .DDRCSB		   (buffered_DDR_CS_n),
	  .DDRDM		   (buffered_DDR_DM),
	  .DDRDQ		   (buffered_DDR_DQ),
	  .DDRDQSN		   (buffered_DDR_DQS_n),
	  .DDRDQSP		   (buffered_DDR_DQS),
	  .DDRDRSTB                (buffered_DDR_DRSTB),
	  .DDRODT		   (buffered_DDR_ODT),  
	  .DDRRASB		   (buffered_DDR_RAS_n),
	  .DDRVRN          (buffered_DDR_VRN),
	  .DDRVRP          (buffered_DDR_VRP),
	  .DDRWEB          (buffered_DDR_WEB),
	  .MIO			   ({buffered_MIO[31:30],dummy[21:20],buffered_MIO[29:28],dummy[19:12],buffered_MIO[27:16],dummy[11:0],buffered_MIO[15:0]}),
	  .PSCLK		   (buffered_PS_CLK),  
	  .PSPORB		   (buffered_PS_PORB),  
	  .PSSRSTB		   (buffered_PS_SRSTB)  
  

);
 end
 else begin
	PS7 PS7_i (
	  .DMA0DATYPE		   (DMA0_DATYPE ),
	  .DMA0DAVALID		   (DMA0_DAVALID),
	  .DMA0DRREADY		   (DMA0_DRREADY),  
	  .DMA0RSTN		   (DMA0_RSTN   ),  
	  .DMA1DATYPE		   (DMA1_DATYPE ),
	  .DMA1DAVALID		   (DMA1_DAVALID),
	  .DMA1DRREADY		   (DMA1_DRREADY),
	  .DMA1RSTN		   (DMA1_RSTN   ),
	  .DMA2DATYPE		   (DMA2_DATYPE ),
	  .DMA2DAVALID		   (DMA2_DAVALID),
	  .DMA2DRREADY		   (DMA2_DRREADY),
	  .DMA2RSTN		   (DMA2_RSTN   ),
	  .DMA3DATYPE		   (DMA3_DATYPE ),
	  .DMA3DAVALID		   (DMA3_DAVALID),
	  .DMA3DRREADY		   (DMA3_DRREADY),
	  .DMA3RSTN		   (DMA3_RSTN   ),  
	  .EMIOCAN0PHYTX	   (CAN0_PHY_TX ),
	  .EMIOCAN1PHYTX	   (CAN1_PHY_TX ),  
	  .EMIOENET0GMIITXD	  (ENET0_GMII_TXD_i), // (ENET0_GMII_TXD_i ),
	  .EMIOENET0GMIITXEN	(ENET0_GMII_TX_EN_i), //  (ENET0_GMII_TX_EN_i),
	  .EMIOENET0GMIITXER   (ENET0_GMII_TX_ER_i), //	 (ENET0_GMII_TX_ER_i),
	  .EMIOENET0MDIOMDC	   (ENET0_MDIO_MDC),
	  .EMIOENET0MDIOO	   (ENET0_MDIO_O  ),
	  .EMIOENET0MDIOTN	   (ENET0_MDIO_T_n  ),
	  .EMIOENET0PTPDELAYREQRX  (ENET0_PTP_DELAY_REQ_RX),
	  .EMIOENET0PTPDELAYREQTX  (ENET0_PTP_DELAY_REQ_TX),
	  .EMIOENET0PTPPDELAYREQRX (ENET0_PTP_PDELAY_REQ_RX),
	  .EMIOENET0PTPPDELAYREQTX (ENET0_PTP_PDELAY_REQ_TX),
	  .EMIOENET0PTPPDELAYRESPRX(ENET0_PTP_PDELAY_RESP_RX),
	  .EMIOENET0PTPPDELAYRESPTX(ENET0_PTP_PDELAY_RESP_TX),
	  .EMIOENET0PTPSYNCFRAMERX (ENET0_PTP_SYNC_FRAME_RX),
	  .EMIOENET0PTPSYNCFRAMETX (ENET0_PTP_SYNC_FRAME_TX),
	  .EMIOENET0SOFRX          (ENET0_SOF_RX),
	  .EMIOENET0SOFTX          (ENET0_SOF_TX),   
	  .EMIOENET1GMIITXD	 (ENET1_GMII_TXD_i), //  (ENET1_GMII_TXD_i),
	  .EMIOENET1GMIITXEN	(ENET1_GMII_TX_EN_i), // (ENET1_GMII_TX_EN_i),
	  .EMIOENET1GMIITXER	(ENET1_GMII_TX_ER_i), //  (ENET1_GMII_TX_ER_i),
	  .EMIOENET1MDIOMDC	   (ENET1_MDIO_MDC),
	  .EMIOENET1MDIOO	   (ENET1_MDIO_O  ),
	  .EMIOENET1MDIOTN	   (ENET1_MDIO_T_n),
	  .EMIOENET1PTPDELAYREQRX  (ENET1_PTP_DELAY_REQ_RX),
	  .EMIOENET1PTPDELAYREQTX  (ENET1_PTP_DELAY_REQ_TX),
	  .EMIOENET1PTPPDELAYREQRX (ENET1_PTP_PDELAY_REQ_RX),
	  .EMIOENET1PTPPDELAYREQTX (ENET1_PTP_PDELAY_REQ_TX),
	  .EMIOENET1PTPPDELAYRESPRX(ENET1_PTP_PDELAY_RESP_RX),
	  .EMIOENET1PTPPDELAYRESPTX(ENET1_PTP_PDELAY_RESP_TX),
	  .EMIOENET1PTPSYNCFRAMERX (ENET1_PTP_SYNC_FRAME_RX),
	  .EMIOENET1PTPSYNCFRAMETX (ENET1_PTP_SYNC_FRAME_TX),
	  .EMIOENET1SOFRX          (ENET1_SOF_RX),
	  .EMIOENET1SOFTX          (ENET1_SOF_TX),  
	  .EMIOGPIOO	           (gpio_out),
	  .EMIOGPIOTN	           (gpio_out_t_n),
	  .EMIOI2C0SCLO            (I2C0_SCL_O),
	  .EMIOI2C0SCLTN           (I2C0_SCL_T_n),
	  .EMIOI2C0SDAO	           (I2C0_SDA_O),
	  .EMIOI2C0SDATN	   (I2C0_SDA_T_n),
	  .EMIOI2C1SCLO	           (I2C1_SCL_O),
	  .EMIOI2C1SCLTN           (I2C1_SCL_T_n),
	  .EMIOI2C1SDAO	           (I2C1_SDA_O),
	  .EMIOI2C1SDATN	   (I2C1_SDA_T_n),
	  .EMIOPJTAGTDO  	   (PJTAG_TDO_O),
	  .EMIOPJTAGTDTN	   (PJTAG_TDO_T_n),
	  .EMIOSDIO0BUSPOW         (SDIO0_BUSPOW),
	  .EMIOSDIO0CLK		   (SDIO0_CLK   ),
	  .EMIOSDIO0CMDO	   (SDIO0_CMD_O ),
	  .EMIOSDIO0CMDTN	   (SDIO0_CMD_T_n ),
	  .EMIOSDIO0DATAO	   (SDIO0_DATA_O),
	  .EMIOSDIO0DATATN	   (SDIO0_DATA_T_n),
	  .EMIOSDIO0LED            (SDIO0_LED),
	  .EMIOSDIO1BUSPOW         (SDIO1_BUSPOW),  
	  .EMIOSDIO1CLK            (SDIO1_CLK   ),
	  .EMIOSDIO1CMDO           (SDIO1_CMD_O ),
	  .EMIOSDIO1CMDTN          (SDIO1_CMD_T_n ),
	  .EMIOSDIO1DATAO          (SDIO1_DATA_O),
	  .EMIOSDIO1DATATN         (SDIO1_DATA_T_n),
	  .EMIOSDIO1LED            (SDIO1_LED),  
	  .EMIOSPI0MO		   (SPI0_MOSI_O),
	  .EMIOSPI0MOTN	           (SPI0_MOSI_T_n),
	  .EMIOSPI0SCLKO	   (SPI0_SCLK_O),
	  .EMIOSPI0SCLKTN	   (SPI0_SCLK_T_n),
	  .EMIOSPI0SO		   (SPI0_MISO_O),
	  .EMIOSPI0STN	           (SPI0_MISO_T_n),
	  .EMIOSPI0SSON	           ({SPI0_SS2_O,SPI0_SS1_O,SPI0_SS_O}),
	  .EMIOSPI0SSNTN	   (SPI0_SS_T_n),
	  .EMIOSPI1MO		   (SPI1_MOSI_O),
	  .EMIOSPI1MOTN	           (SPI1_MOSI_T_n),
	  .EMIOSPI1SCLKO	   (SPI1_SCLK_O),
	  .EMIOSPI1SCLKTN	   (SPI1_SCLK_T_n),
	  .EMIOSPI1SO		   (SPI1_MISO_O),
	  .EMIOSPI1STN	           (SPI1_MISO_T_n),
	  .EMIOSPI1SSON	           ({SPI1_SS2_O,SPI1_SS1_O,SPI1_SS_O}),
	  .EMIOSPI1SSNTN	   (SPI1_SS_T_n),
	  .EMIOTRACECTL		   (TRACE_CTL_i),
	  .EMIOTRACEDATA	   (TRACE_DATA_i),
	  .EMIOTTC0WAVEO	   ({TTC0_WAVE2_OUT,TTC0_WAVE1_OUT,TTC0_WAVE0_OUT}),
	  .EMIOTTC1WAVEO	   ({TTC1_WAVE2_OUT,TTC1_WAVE1_OUT,TTC1_WAVE0_OUT}),
	  .EMIOUART0DTRN	   (UART0_DTRN),
	  .EMIOUART0RTSN	   (UART0_RTSN),
	  .EMIOUART0TX		   (UART0_TX  ),
	  .EMIOUART1DTRN	   (UART1_DTRN),
	  .EMIOUART1RTSN	   (UART1_RTSN),
	  .EMIOUART1TX		   (UART1_TX  ),
	  .EMIOUSB0PORTINDCTL      (USB0_PORT_INDCTL),  
	  .EMIOUSB0VBUSPWRSELECT   (USB0_VBUS_PWRSELECT),
	  .EMIOUSB1PORTINDCTL      (USB1_PORT_INDCTL),
	  .EMIOUSB1VBUSPWRSELECT   (USB1_VBUS_PWRSELECT),  
	  .EMIOWDTRSTO    	   (WDT_RST_OUT),
	  .EVENTEVENTO             (EVENT_EVENTO),
	  .EVENTSTANDBYWFE         (EVENT_STANDBYWFE),
	  .EVENTSTANDBYWFI         (EVENT_STANDBYWFI),  
	  .FCLKCLK		   (FCLK_CLK_unbuffered),
	  .FCLKRESETN		   ({FCLK_RESET3_N,FCLK_RESET2_N,FCLK_RESET1_N,FCLK_RESET0_N}),  
	  .EMIOSDIO0BUSVOLT        (SDIO0_BUSVOLT), 
	  .EMIOSDIO1BUSVOLT        (SDIO1_BUSVOLT),  
	  .FTMTF2PTRIGACK	   ({FTMT_F2P_TRIGACK_3,FTMT_F2P_TRIGACK_2,FTMT_F2P_TRIGACK_1,FTMT_F2P_TRIGACK_0}),
	  .FTMTP2FDEBUG		   (FTMT_P2F_DEBUG  ),
	  .FTMTP2FTRIG		   ({FTMT_P2F_TRIG_3,FTMT_P2F_TRIG_2,FTMT_P2F_TRIG_1,FTMT_P2F_TRIG_0}),
	  .IRQP2F		   ({IRQ_P2F_DMAC_ABORT, IRQ_P2F_DMAC7, IRQ_P2F_DMAC6, IRQ_P2F_DMAC5, IRQ_P2F_DMAC4, IRQ_P2F_DMAC3, IRQ_P2F_DMAC2, IRQ_P2F_DMAC1, IRQ_P2F_DMAC0, IRQ_P2F_SMC, IRQ_P2F_QSPI, IRQ_P2F_CTI, IRQ_P2F_GPIO, IRQ_P2F_USB0, IRQ_P2F_ENET0, IRQ_P2F_ENET_WAKE0, IRQ_P2F_SDIO0, IRQ_P2F_I2C0, IRQ_P2F_SPI0, IRQ_P2F_UART0, IRQ_P2F_CAN0, IRQ_P2F_USB1, IRQ_P2F_ENET1, IRQ_P2F_ENET_WAKE1, IRQ_P2F_SDIO1, IRQ_P2F_I2C1, IRQ_P2F_SPI1, IRQ_P2F_UART1, IRQ_P2F_CAN1}),    
	  .MAXIGP0ARADDR	   (M_AXI_GP0_ARADDR),
	  .MAXIGP0ARBURST	   (M_AXI_GP0_ARBURST),
	  .MAXIGP0ARCACHE	   (M_AXI_GP0_ARCACHE),
	  .MAXIGP0ARESETN	   (M_AXI_GP0_ARESETN),
	  .MAXIGP0ARID	           (M_AXI_GP0_ARID_FULL   ),
	  .MAXIGP0ARLEN	           (M_AXI_GP0_ARLEN  ),
	  .MAXIGP0ARLOCK	   (M_AXI_GP0_ARLOCK ),
	  .MAXIGP0ARPROT	   (M_AXI_GP0_ARPROT ),
	  .MAXIGP0ARQOS	           (M_AXI_GP0_ARQOS  ),
	  .MAXIGP0ARSIZE	   (M_AXI_GP0_ARSIZE_i ),
	  .MAXIGP0ARVALID	   (M_AXI_GP0_ARVALID),
	  .MAXIGP0AWADDR	   (M_AXI_GP0_AWADDR ),
	  .MAXIGP0AWBURST	   (M_AXI_GP0_AWBURST),
	  .MAXIGP0AWCACHE	   (M_AXI_GP0_AWCACHE),
	  .MAXIGP0AWID	           (M_AXI_GP0_AWID_FULL   ),
	  .MAXIGP0AWLEN	           (M_AXI_GP0_AWLEN  ),
	  .MAXIGP0AWLOCK	   (M_AXI_GP0_AWLOCK ),
	  .MAXIGP0AWPROT	   (M_AXI_GP0_AWPROT ),
	  .MAXIGP0AWQOS	           (M_AXI_GP0_AWQOS  ),
	  .MAXIGP0AWSIZE	   (M_AXI_GP0_AWSIZE_i ),
	  .MAXIGP0AWVALID	   (M_AXI_GP0_AWVALID),
	  .MAXIGP0BREADY	   (M_AXI_GP0_BREADY ),
	  .MAXIGP0RREADY	   (M_AXI_GP0_RREADY ),
	  .MAXIGP0WDATA	           (M_AXI_GP0_WDATA  ),
	  .MAXIGP0WID	           (M_AXI_GP0_WID_FULL    ),
	  .MAXIGP0WLAST	           (M_AXI_GP0_WLAST  ),
	  .MAXIGP0WSTRB	           (M_AXI_GP0_WSTRB  ),
	  .MAXIGP0WVALID	   (M_AXI_GP0_WVALID ),
	  .MAXIGP1ARADDR	   (M_AXI_GP1_ARADDR ),
	  .MAXIGP1ARBURST	   (M_AXI_GP1_ARBURST),
	  .MAXIGP1ARCACHE	   (M_AXI_GP1_ARCACHE),
	  .MAXIGP1ARESETN	   (M_AXI_GP1_ARESETN),
	  .MAXIGP1ARID	           (M_AXI_GP1_ARID_FULL   ),
	  .MAXIGP1ARLEN	           (M_AXI_GP1_ARLEN  ),
	  .MAXIGP1ARLOCK	   (M_AXI_GP1_ARLOCK ),
	  .MAXIGP1ARPROT	   (M_AXI_GP1_ARPROT ),
	  .MAXIGP1ARQOS	           (M_AXI_GP1_ARQOS  ),
	  .MAXIGP1ARSIZE	   (M_AXI_GP1_ARSIZE_i ),
	  .MAXIGP1ARVALID	   (M_AXI_GP1_ARVALID),
	  .MAXIGP1AWADDR	   (M_AXI_GP1_AWADDR ),
	  .MAXIGP1AWBURST	   (M_AXI_GP1_AWBURST),
	  .MAXIGP1AWCACHE	   (M_AXI_GP1_AWCACHE),
	  .MAXIGP1AWID	           (M_AXI_GP1_AWID_FULL   ),
	  .MAXIGP1AWLEN	           (M_AXI_GP1_AWLEN  ),
	  .MAXIGP1AWLOCK	   (M_AXI_GP1_AWLOCK ),
	  .MAXIGP1AWPROT	   (M_AXI_GP1_AWPROT ),
	  .MAXIGP1AWQOS	           (M_AXI_GP1_AWQOS  ),
	  .MAXIGP1AWSIZE	   (M_AXI_GP1_AWSIZE_i ),
	  .MAXIGP1AWVALID	   (M_AXI_GP1_AWVALID),
	  .MAXIGP1BREADY	   (M_AXI_GP1_BREADY ),
	  .MAXIGP1RREADY	   (M_AXI_GP1_RREADY ),
	  .MAXIGP1WDATA	           (M_AXI_GP1_WDATA  ),
	  .MAXIGP1WID	           (M_AXI_GP1_WID_FULL    ),
	  .MAXIGP1WLAST	           (M_AXI_GP1_WLAST  ),
	  .MAXIGP1WSTRB	           (M_AXI_GP1_WSTRB  ),
	  .MAXIGP1WVALID	   (M_AXI_GP1_WVALID ),
	  .SAXIACPARESETN	   (S_AXI_ACP_ARESETN),
	  .SAXIACPARREADY	   (SAXIACPARREADY_W),
	  .SAXIACPAWREADY	   (SAXIACPAWREADY_W),
	  .SAXIACPBID	           (S_AXI_ACP_BID_out    ),
	  .SAXIACPBRESP	           (SAXIACPBRESP_W  ),
	  .SAXIACPBVALID	   (SAXIACPBVALID_W ),
	  .SAXIACPRDATA	           (SAXIACPRDATA_W  ),
	  .SAXIACPRID	           (S_AXI_ACP_RID_out),
	  .SAXIACPRLAST	           (SAXIACPRLAST_W  ),
	  .SAXIACPRRESP	           (SAXIACPRRESP_W  ),
	  .SAXIACPRVALID	   (SAXIACPRVALID_W ),
	  .SAXIACPWREADY	   (SAXIACPWREADY_W ),
	  .SAXIGP0ARESETN	   (S_AXI_GP0_ARESETN),
	  .SAXIGP0ARREADY	   (S_AXI_GP0_ARREADY_shim),
	  .SAXIGP0AWREADY	   (S_AXI_GP0_AWREADY_shim),
	  .SAXIGP0BID	           (S_AXI_GP0_BID_out_shim),
	  .SAXIGP0BRESP	           (S_AXI_GP0_BRESP_shim  ),
	  .SAXIGP0BVALID	   (S_AXI_GP0_BVALID_shim ),
	  .SAXIGP0RDATA	           (S_AXI_GP0_RDATA_shim  ),
	  .SAXIGP0RID	           (S_AXI_GP0_RID_out_shim ),
	  .SAXIGP0RLAST	           (S_AXI_GP0_RLAST_shim  ),
	  .SAXIGP0RRESP	           (S_AXI_GP0_RRESP_shim  ),
	  .SAXIGP0RVALID	   (S_AXI_GP0_RVALID_shim ),
	  .SAXIGP0WREADY	   (S_AXI_GP0_WREADY_shim ),
	  .SAXIGP1ARESETN	   (S_AXI_GP1_ARESETN),
	  .SAXIGP1ARREADY	   (S_AXI_GP1_ARREADY_shim),
	  .SAXIGP1AWREADY	   (S_AXI_GP1_AWREADY_shim),
	  .SAXIGP1BID	           (S_AXI_GP1_BID_out_shim    ),
	  .SAXIGP1BRESP	           (S_AXI_GP1_BRESP_shim  ),
	  .SAXIGP1BVALID	   (S_AXI_GP1_BVALID_shim ),
	  .SAXIGP1RDATA	           (S_AXI_GP1_RDATA_shim  ),
	  .SAXIGP1RID	           (S_AXI_GP1_RID_out_shim    ),
	  .SAXIGP1RLAST	           (S_AXI_GP1_RLAST_shim  ),
	  .SAXIGP1RRESP	           (S_AXI_GP1_RRESP_shim  ),
	  .SAXIGP1RVALID	   (S_AXI_GP1_RVALID_shim ),
	  .SAXIGP1WREADY	   (S_AXI_GP1_WREADY_shim ),
	  .SAXIHP0ARESETN	   (S_AXI_HP0_ARESETN),
	  .SAXIHP0ARREADY	   (S_AXI_HP0_ARREADY),
	  .SAXIHP0AWREADY	   (S_AXI_HP0_AWREADY),
	  .SAXIHP0BID	           (S_AXI_HP0_BID_out    ),
	  .SAXIHP0BRESP	           (S_AXI_HP0_BRESP  ),
	  .SAXIHP0BVALID	   (S_AXI_HP0_BVALID ),
	  .SAXIHP0RACOUNT          (S_AXI_HP0_RACOUNT),
	  .SAXIHP0RCOUNT	   (S_AXI_HP0_RCOUNT),
	  .SAXIHP0RDATA	           (S_AXI_HP0_RDATA_out),
	  .SAXIHP0RID	           (S_AXI_HP0_RID_out ),
	  .SAXIHP0RLAST	           (S_AXI_HP0_RLAST),
	  .SAXIHP0RRESP	           (S_AXI_HP0_RRESP),
	  .SAXIHP0RVALID	   (S_AXI_HP0_RVALID),
	  .SAXIHP0WCOUNT	   (S_AXI_HP0_WCOUNT),
	  .SAXIHP0WACOUNT          (S_AXI_HP0_WACOUNT),  
	  .SAXIHP0WREADY	   (S_AXI_HP0_WREADY),
	  .SAXIHP1ARESETN	   (S_AXI_HP1_ARESETN),
	  .SAXIHP1ARREADY	   (S_AXI_HP1_ARREADY),
	  .SAXIHP1AWREADY	   (S_AXI_HP1_AWREADY),
	  .SAXIHP1BID	           (S_AXI_HP1_BID_out    ),
	  .SAXIHP1BRESP	           (S_AXI_HP1_BRESP  ),
	  .SAXIHP1BVALID	   (S_AXI_HP1_BVALID ),
	  .SAXIHP1RACOUNT	   (S_AXI_HP1_RACOUNT ),  
	  .SAXIHP1RCOUNT	   (S_AXI_HP1_RCOUNT ),
	  .SAXIHP1RDATA	           (S_AXI_HP1_RDATA_out),
	  .SAXIHP1RID	           (S_AXI_HP1_RID_out    ),
	  .SAXIHP1RLAST	           (S_AXI_HP1_RLAST  ),
	  .SAXIHP1RRESP	           (S_AXI_HP1_RRESP  ),
	  .SAXIHP1RVALID	   (S_AXI_HP1_RVALID),
	  .SAXIHP1WACOUNT	   (S_AXI_HP1_WACOUNT),  
	  .SAXIHP1WCOUNT	   (S_AXI_HP1_WCOUNT),
	  .SAXIHP1WREADY	   (S_AXI_HP1_WREADY),
	  .SAXIHP2ARESETN	   (S_AXI_HP2_ARESETN),
	  .SAXIHP2ARREADY	   (S_AXI_HP2_ARREADY),
	  .SAXIHP2AWREADY	   (S_AXI_HP2_AWREADY),
	  .SAXIHP2BID	           (S_AXI_HP2_BID_out ),
	  .SAXIHP2BRESP	           (S_AXI_HP2_BRESP),
	  .SAXIHP2BVALID	   (S_AXI_HP2_BVALID),
	  .SAXIHP2RACOUNT	   (S_AXI_HP2_RACOUNT),  
	  .SAXIHP2RCOUNT	   (S_AXI_HP2_RCOUNT),
	  .SAXIHP2RDATA	           (S_AXI_HP2_RDATA_out),
	  .SAXIHP2RID	           (S_AXI_HP2_RID_out ),
	  .SAXIHP2RLAST	           (S_AXI_HP2_RLAST),
	  .SAXIHP2RRESP	           (S_AXI_HP2_RRESP),
	  .SAXIHP2RVALID	   (S_AXI_HP2_RVALID),
	  .SAXIHP2WACOUNT	   (S_AXI_HP2_WACOUNT),  
	  .SAXIHP2WCOUNT	   (S_AXI_HP2_WCOUNT),
	  .SAXIHP2WREADY	   (S_AXI_HP2_WREADY),
	  .SAXIHP3ARESETN	   (S_AXI_HP3_ARESETN),
	  .SAXIHP3ARREADY	   (S_AXI_HP3_ARREADY),
	  .SAXIHP3AWREADY	   (S_AXI_HP3_AWREADY),
	  .SAXIHP3BID	           (S_AXI_HP3_BID_out),
	  .SAXIHP3BRESP	           (S_AXI_HP3_BRESP),
	  .SAXIHP3BVALID	   (S_AXI_HP3_BVALID),
	  .SAXIHP3RACOUNT	   (S_AXI_HP3_RACOUNT),    
	  .SAXIHP3RCOUNT	   (S_AXI_HP3_RCOUNT),
	  .SAXIHP3RDATA	           (S_AXI_HP3_RDATA_out),
	  .SAXIHP3RID	           (S_AXI_HP3_RID_out),
	  .SAXIHP3RLAST	           (S_AXI_HP3_RLAST),
	  .SAXIHP3RRESP	           (S_AXI_HP3_RRESP),
	  .SAXIHP3RVALID	   (S_AXI_HP3_RVALID),
	  .SAXIHP3WCOUNT	   (S_AXI_HP3_WCOUNT),
	  .SAXIHP3WACOUNT	   (S_AXI_HP3_WACOUNT),    
	  .SAXIHP3WREADY	   (S_AXI_HP3_WREADY), 
	  .DDRARB                  (DDR_ARB), 
	  .DMA0ACLK		   (DMA0_ACLK   ),
	  .DMA0DAREADY		   (DMA0_DAREADY),
	  .DMA0DRLAST		   (DMA0_DRLAST ),
	  .DMA0DRTYPE              (DMA0_DRTYPE),
	  .DMA0DRVALID		   (DMA0_DRVALID),
	  .DMA1ACLK		   (DMA1_ACLK   ),
	  .DMA1DAREADY		   (DMA1_DAREADY),
	  .DMA1DRLAST		   (DMA1_DRLAST ),
	  .DMA1DRTYPE              (DMA1_DRTYPE),  
	  .DMA1DRVALID		   (DMA1_DRVALID),
	  .DMA2ACLK		   (DMA2_ACLK   ),
	  .DMA2DAREADY		   (DMA2_DAREADY),
	  .DMA2DRLAST		   (DMA2_DRLAST ),
	  .DMA2DRTYPE              (DMA2_DRTYPE),    
	  .DMA2DRVALID		   (DMA2_DRVALID),
	  .DMA3ACLK		   (DMA3_ACLK   ),
	  .DMA3DAREADY		   (DMA3_DAREADY),
	  .DMA3DRLAST		   (DMA3_DRLAST ),
	  .DMA3DRTYPE              (DMA3_DRTYPE),      
	  .DMA3DRVALID		   (DMA3_DRVALID),
	  .EMIOCAN0PHYRX	   (CAN0_PHY_RX),  
	  .EMIOCAN1PHYRX	   (CAN1_PHY_RX),
	  .EMIOENET0EXTINTIN       (ENET0_EXT_INTIN),  
	  .EMIOENET0GMIICOL        (ENET0_GMII_COL_i),
	  .EMIOENET0GMIICRS        (ENET0_GMII_CRS_i),
	  .EMIOENET0GMIIRXCLK      (ENET0_GMII_RX_CLK),
	  .EMIOENET0GMIIRXD        (ENET0_GMII_RXD_i),
	  .EMIOENET0GMIIRXDV       (ENET0_GMII_RX_DV_i),
	  .EMIOENET0GMIIRXER       (ENET0_GMII_RX_ER_i),
	  .EMIOENET0GMIITXCLK      (ENET0_GMII_TX_CLK),
	  .EMIOENET0MDIOI          (ENET0_MDIO_I),
	  .EMIOENET1EXTINTIN       (ENET1_EXT_INTIN),    
	  .EMIOENET1GMIICOL        (ENET1_GMII_COL_i),
	  .EMIOENET1GMIICRS        (ENET1_GMII_CRS_i),
	  .EMIOENET1GMIIRXCLK      (ENET1_GMII_RX_CLK),
	  .EMIOENET1GMIIRXD        (ENET1_GMII_RXD_i),
	  .EMIOENET1GMIIRXDV       (ENET1_GMII_RX_DV_i),
	  .EMIOENET1GMIIRXER       (ENET1_GMII_RX_ER_i),
	  .EMIOENET1GMIITXCLK      (ENET1_GMII_TX_CLK),
	  .EMIOENET1MDIOI          (ENET1_MDIO_I),  
	  .EMIOGPIOI	           (gpio_in63_0  ),
	  .EMIOI2C0SCLI	           (I2C0_SCL_I),
	  .EMIOI2C0SDAI	           (I2C0_SDA_I),
	  .EMIOI2C1SCLI	           (I2C1_SCL_I),
	  .EMIOI2C1SDAI	           (I2C1_SDA_I),
	  .EMIOPJTAGTCK		   (PJTAG_TCK),
	  .EMIOPJTAGTDI		   (PJTAG_TDI),
	  .EMIOPJTAGTMS		   (PJTAG_TMS),
	  .EMIOSDIO0CDN            (SDIO0_CDN),
	  .EMIOSDIO0CLKFB	   (SDIO0_CLK_FB  ),
	  .EMIOSDIO0CMDI	   (SDIO0_CMD_I   ),
	  .EMIOSDIO0DATAI	   (SDIO0_DATA_I  ),
	  .EMIOSDIO0WP             (SDIO0_WP),
	  .EMIOSDIO1CDN            (SDIO1_CDN),  
	  .EMIOSDIO1CLKFB	   (SDIO1_CLK_FB  ),
	  .EMIOSDIO1CMDI	   (SDIO1_CMD_I   ),
	  .EMIOSDIO1DATAI	   (SDIO1_DATA_I  ),
	  .EMIOSDIO1WP             (SDIO1_WP),
	  .EMIOSPI0MI		   (SPI0_MISO_I),
	  .EMIOSPI0SCLKI	   (SPI0_SCLK_I),
	  .EMIOSPI0SI		   (SPI0_MOSI_I),
	  .EMIOSPI0SSIN 	   (SPI0_SS_I),
	  .EMIOSPI1MI		   (SPI1_MISO_I),
	  .EMIOSPI1SCLKI	   (SPI1_SCLK_I),
	  .EMIOSPI1SI		   (SPI1_MOSI_I),
	  .EMIOSPI1SSIN	           (SPI1_SS_I),
	  .EMIOSRAMINTIN           (SRAM_INTIN),  
	  .EMIOTRACECLK		   (TRACE_CLK),
	  .EMIOTTC0CLKI	           ({TTC0_CLK2_IN, TTC0_CLK1_IN, TTC0_CLK0_IN}),
	  .EMIOTTC1CLKI	           ({TTC1_CLK2_IN, TTC1_CLK1_IN, TTC1_CLK0_IN}),
	  .EMIOUART0CTSN	   (UART0_CTSN),
	  .EMIOUART0DCDN	   (UART0_DCDN),
	  .EMIOUART0DSRN	   (UART0_DSRN),
	  .EMIOUART0RIN		   (UART0_RIN ),
	  .EMIOUART0RX		   (UART0_RX  ),
	  .EMIOUART1CTSN	   (UART1_CTSN),
	  .EMIOUART1DCDN	   (UART1_DCDN),
	  .EMIOUART1DSRN	   (UART1_DSRN),
	  .EMIOUART1RIN		   (UART1_RIN ),
	  .EMIOUART1RX		   (UART1_RX  ),
	  .EMIOUSB0VBUSPWRFAULT    (USB0_VBUS_PWRFAULT),
	  .EMIOUSB1VBUSPWRFAULT    (USB1_VBUS_PWRFAULT),  
	  .EMIOWDTCLKI		   (WDT_CLK_IN),  
	  .EVENTEVENTI             (EVENT_EVENTI),
	  .FCLKCLKTRIGN		   (fclk_clktrig_gnd),
	  .FPGAIDLEN		   (FPGA_IDLE_N),  
	  .FTMDTRACEINATID	   (FTMD_TRACEIN_ATID_i),  
	  .FTMDTRACEINCLOCK	   (FTMD_TRACEIN_CLK),
	  .FTMDTRACEINDATA	   (FTMD_TRACEIN_DATA_i),
	  .FTMDTRACEINVALID	   (FTMD_TRACEIN_VALID_i),
	  .FTMTF2PDEBUG		   (FTMT_F2P_DEBUG  ),
	  .FTMTF2PTRIG		   ({FTMT_F2P_TRIG_3,FTMT_F2P_TRIG_2,FTMT_F2P_TRIG_1,FTMT_F2P_TRIG_0}),
	  .FTMTP2FTRIGACK	   ({FTMT_P2F_TRIGACK_3,FTMT_P2F_TRIGACK_2,FTMT_P2F_TRIGACK_1,FTMT_P2F_TRIGACK_0}),  
	  .IRQF2P		   (irq_f2p_i),  
	  .MAXIGP0ACLK	           (M_AXI_GP0_ACLK_temp),
	  .MAXIGP0ARREADY	   (M_AXI_GP0_ARREADY),
	  .MAXIGP0AWREADY	   (M_AXI_GP0_AWREADY),
	  .MAXIGP0BID	           (M_AXI_GP0_BID_FULL    ),
	  .MAXIGP0BRESP	           (M_AXI_GP0_BRESP  ),
	  .MAXIGP0BVALID	   (M_AXI_GP0_BVALID ),
	  .MAXIGP0RDATA	           (M_AXI_GP0_RDATA  ),
	  .MAXIGP0RID	           (M_AXI_GP0_RID_FULL    ),
	  .MAXIGP0RLAST	           (M_AXI_GP0_RLAST  ),
	  .MAXIGP0RRESP	           (M_AXI_GP0_RRESP  ),
	  .MAXIGP0RVALID	   (M_AXI_GP0_RVALID ),
	  .MAXIGP0WREADY	   (M_AXI_GP0_WREADY ),
	  .MAXIGP1ACLK	           (M_AXI_GP1_ACLK_temp ),
	  .MAXIGP1ARREADY	   (M_AXI_GP1_ARREADY),
	  .MAXIGP1AWREADY	   (M_AXI_GP1_AWREADY),
	  .MAXIGP1BID	           (M_AXI_GP1_BID_FULL ),
	  .MAXIGP1BRESP	           (M_AXI_GP1_BRESP  ),
	  .MAXIGP1BVALID	   (M_AXI_GP1_BVALID ),
	  .MAXIGP1RDATA	           (M_AXI_GP1_RDATA  ),
	  .MAXIGP1RID	           (M_AXI_GP1_RID_FULL    ),
	  .MAXIGP1RLAST	           (M_AXI_GP1_RLAST  ),
	  .MAXIGP1RRESP	           (M_AXI_GP1_RRESP  ),
	  .MAXIGP1RVALID	   (M_AXI_GP1_RVALID ),
	  .MAXIGP1WREADY	   (M_AXI_GP1_WREADY ),  
	  .SAXIACPACLK	           (S_AXI_ACP_ACLK_temp),
	  .SAXIACPARADDR	   (SAXIACPARADDR_W ),
	  .SAXIACPARBURST	   (SAXIACPARBURST_W),
	  .SAXIACPARCACHE	   (SAXIACPARCACHE_W),
	  .SAXIACPARID	           (S_AXI_ACP_ARID_in   ),
	  .SAXIACPARLEN	           (SAXIACPARLEN_W  ),
	  .SAXIACPARLOCK	   (SAXIACPARLOCK_W ),
	  .SAXIACPARPROT	   (SAXIACPARPROT_W ),
	  .SAXIACPARQOS	           (S_AXI_ACP_ARQOS  ),
	  .SAXIACPARSIZE	   (SAXIACPARSIZE_W[1:0] ),
	  .SAXIACPARUSER	   (SAXIACPARUSER_W ),
	  .SAXIACPARVALID	   (SAXIACPARVALID_W),
	  .SAXIACPAWADDR	   (SAXIACPAWADDR_W ),
	  .SAXIACPAWBURST	   (SAXIACPAWBURST_W),
	  .SAXIACPAWCACHE	   (SAXIACPAWCACHE_W),
	  .SAXIACPAWID	           (S_AXI_ACP_AWID_in   ),
	  .SAXIACPAWLEN	           (SAXIACPAWLEN_W  ),
	  .SAXIACPAWLOCK	   (SAXIACPAWLOCK_W ),
	  .SAXIACPAWPROT	   (SAXIACPAWPROT_W ),
	  .SAXIACPAWQOS	           (S_AXI_ACP_AWQOS  ),
	  .SAXIACPAWSIZE	   (SAXIACPAWSIZE_W[1:0] ),
	  .SAXIACPAWUSER	   (SAXIACPAWUSER_W ),
	  .SAXIACPAWVALID	   (SAXIACPAWVALID_W),
	  .SAXIACPBREADY	   (SAXIACPBREADY_W ),
	  .SAXIACPRREADY	   (SAXIACPRREADY_W ),
	  .SAXIACPWDATA	           (SAXIACPWDATA_W  ),
	  .SAXIACPWID	           (S_AXI_ACP_WID_in    ),
	  .SAXIACPWLAST	           (SAXIACPWLAST_W  ),
	  .SAXIACPWSTRB	           (SAXIACPWSTRB_W  ),
	  .SAXIACPWVALID	   (SAXIACPWVALID_W ),
	  .SAXIGP0ACLK             (S_AXI_GP0_ACLK_temp   ),
	  .SAXIGP0ARADDR           (S_AXI_GP0_ARADDR_shim ),
	  .SAXIGP0ARBURST          (S_AXI_GP0_ARBURST_shim),
	  .SAXIGP0ARCACHE          (S_AXI_GP0_ARCACHE_shim),
	  .SAXIGP0ARID             (S_AXI_GP0_ARID_in_shim   ),
	  .SAXIGP0ARLEN            (S_AXI_GP0_ARLEN_shim  ),
	  .SAXIGP0ARLOCK           (S_AXI_GP0_ARLOCK_shim ),
	  .SAXIGP0ARPROT           (S_AXI_GP0_ARPROT_shim ),
	  .SAXIGP0ARQOS            (S_AXI_GP0_ARQOS_shim  ),
	  .SAXIGP0ARSIZE           (S_AXI_GP0_ARSIZE_shim[1:0] ),
	  .SAXIGP0ARVALID          (S_AXI_GP0_ARVALID_shim),
	  .SAXIGP0AWADDR           (S_AXI_GP0_AWADDR_shim ),
	  .SAXIGP0AWBURST          (S_AXI_GP0_AWBURST_shim),
	  .SAXIGP0AWCACHE          (S_AXI_GP0_AWCACHE_shim),
	  .SAXIGP0AWID             (S_AXI_GP0_AWID_in_shim   ),
	  .SAXIGP0AWLEN            (S_AXI_GP0_AWLEN_shim  ),
	  .SAXIGP0AWLOCK           (S_AXI_GP0_AWLOCK_shim ),
	  .SAXIGP0AWPROT           (S_AXI_GP0_AWPROT_shim ),
	  .SAXIGP0AWQOS            (S_AXI_GP0_AWQOS_shim  ),
	  .SAXIGP0AWSIZE           (S_AXI_GP0_AWSIZE_shim[1:0] ),
	  .SAXIGP0AWVALID          (S_AXI_GP0_AWVALID_shim),
	  .SAXIGP0BREADY           (S_AXI_GP0_BREADY_shim ),
	  .SAXIGP0RREADY           (S_AXI_GP0_RREADY_shim ),
	  .SAXIGP0WDATA            (S_AXI_GP0_WDATA_shim  ),
	  .SAXIGP0WID              (S_AXI_GP0_WID_in_shim ),
	  .SAXIGP0WLAST            (S_AXI_GP0_WLAST_shim  ),
	  .SAXIGP0WSTRB            (S_AXI_GP0_WSTRB_shim  ),
	  .SAXIGP0WVALID           (S_AXI_GP0_WVALID_shim ),
	  .SAXIGP1ACLK	           (S_AXI_GP1_ACLK_temp   ),
	  .SAXIGP1ARADDR	   (S_AXI_GP1_ARADDR_shim ),
	  .SAXIGP1ARBURST	   (S_AXI_GP1_ARBURST_shim),
	  .SAXIGP1ARCACHE	   (S_AXI_GP1_ARCACHE_shim),
	  .SAXIGP1ARID	           (S_AXI_GP1_ARID_in_shim   ),
	  .SAXIGP1ARLEN	           (S_AXI_GP1_ARLEN_shim  ),
	  .SAXIGP1ARLOCK	   (S_AXI_GP1_ARLOCK_shim ),
	  .SAXIGP1ARPROT	   (S_AXI_GP1_ARPROT_shim ),
	  .SAXIGP1ARQOS	           (S_AXI_GP1_ARQOS_shim  ),
	  .SAXIGP1ARSIZE	   (S_AXI_GP1_ARSIZE_shim[1:0] ),
	  .SAXIGP1ARVALID	   (S_AXI_GP1_ARVALID_shim),
	  .SAXIGP1AWADDR	   (S_AXI_GP1_AWADDR_shim ),
	  .SAXIGP1AWBURST	   (S_AXI_GP1_AWBURST_shim),
	  .SAXIGP1AWCACHE	   (S_AXI_GP1_AWCACHE_shim),
	  .SAXIGP1AWID	           (S_AXI_GP1_AWID_in_shim   ),
	  .SAXIGP1AWLEN	           (S_AXI_GP1_AWLEN_shim  ),
	  .SAXIGP1AWLOCK	   (S_AXI_GP1_AWLOCK_shim ),
	  .SAXIGP1AWPROT	   (S_AXI_GP1_AWPROT_shim ),
	  .SAXIGP1AWQOS	           (S_AXI_GP1_AWQOS_shim  ),
	  .SAXIGP1AWSIZE	   (S_AXI_GP1_AWSIZE_shim[1:0] ),
	  .SAXIGP1AWVALID	   (S_AXI_GP1_AWVALID_shim),
	  .SAXIGP1BREADY	   (S_AXI_GP1_BREADY_shim ),
	  .SAXIGP1RREADY	   (S_AXI_GP1_RREADY_shim ),
	  .SAXIGP1WDATA	           (S_AXI_GP1_WDATA_shim  ),
	  .SAXIGP1WID	           (S_AXI_GP1_WID_in_shim    ),
	  .SAXIGP1WLAST	           (S_AXI_GP1_WLAST_shim  ),
	  .SAXIGP1WSTRB	           (S_AXI_GP1_WSTRB_shim  ),
	  .SAXIGP1WVALID	   (S_AXI_GP1_WVALID_shim ),  
	  .SAXIHP0ACLK             (S_AXI_HP0_ACLK_temp   ),
	  .SAXIHP0ARADDR           (S_AXI_HP0_ARADDR),
	  .SAXIHP0ARBURST          (S_AXI_HP0_ARBURST),
	  .SAXIHP0ARCACHE          (S_AXI_HP0_ARCACHE),
	  .SAXIHP0ARID             (S_AXI_HP0_ARID_in),
	  .SAXIHP0ARLEN            (S_AXI_HP0_ARLEN),
	  .SAXIHP0ARLOCK           (S_AXI_HP0_ARLOCK),
	  .SAXIHP0ARPROT           (S_AXI_HP0_ARPROT),
	  .SAXIHP0ARQOS            (S_AXI_HP0_ARQOS),
	  .SAXIHP0ARSIZE           (S_AXI_HP0_ARSIZE[1:0]),
	  .SAXIHP0ARVALID          (S_AXI_HP0_ARVALID),
	  .SAXIHP0AWADDR           (S_AXI_HP0_AWADDR),
	  .SAXIHP0AWBURST          (S_AXI_HP0_AWBURST),
	  .SAXIHP0AWCACHE          (S_AXI_HP0_AWCACHE),
	  .SAXIHP0AWID             (S_AXI_HP0_AWID_in),
	  .SAXIHP0AWLEN            (S_AXI_HP0_AWLEN),
	  .SAXIHP0AWLOCK           (S_AXI_HP0_AWLOCK),
	  .SAXIHP0AWPROT           (S_AXI_HP0_AWPROT),
	  .SAXIHP0AWQOS            (S_AXI_HP0_AWQOS),
	  .SAXIHP0AWSIZE           (S_AXI_HP0_AWSIZE[1:0]),
	  .SAXIHP0AWVALID          (S_AXI_HP0_AWVALID),
	  .SAXIHP0BREADY           (S_AXI_HP0_BREADY),
	  .SAXIHP0RDISSUECAP1EN    (S_AXI_HP0_RDISSUECAP1_EN),
	  .SAXIHP0RREADY           (S_AXI_HP0_RREADY),
	  .SAXIHP0WDATA            (S_AXI_HP0_WDATA_in),
	  .SAXIHP0WID              (S_AXI_HP0_WID_in),
	  .SAXIHP0WLAST            (S_AXI_HP0_WLAST),
	  .SAXIHP0WRISSUECAP1EN    (S_AXI_HP0_WRISSUECAP1_EN),
	  .SAXIHP0WSTRB            (S_AXI_HP0_WSTRB_in),
	  .SAXIHP0WVALID           (S_AXI_HP0_WVALID),
	  .SAXIHP1ACLK             (S_AXI_HP1_ACLK_temp),
	  .SAXIHP1ARADDR           (S_AXI_HP1_ARADDR),
	  .SAXIHP1ARBURST          (S_AXI_HP1_ARBURST),
	  .SAXIHP1ARCACHE          (S_AXI_HP1_ARCACHE),
	  .SAXIHP1ARID             (S_AXI_HP1_ARID_in),
	  .SAXIHP1ARLEN            (S_AXI_HP1_ARLEN),
	  .SAXIHP1ARLOCK           (S_AXI_HP1_ARLOCK),
	  .SAXIHP1ARPROT           (S_AXI_HP1_ARPROT),
	  .SAXIHP1ARQOS            (S_AXI_HP1_ARQOS),
	  .SAXIHP1ARSIZE           (S_AXI_HP1_ARSIZE[1:0]),
	  .SAXIHP1ARVALID          (S_AXI_HP1_ARVALID),
	  .SAXIHP1AWADDR           (S_AXI_HP1_AWADDR),
	  .SAXIHP1AWBURST          (S_AXI_HP1_AWBURST),
	  .SAXIHP1AWCACHE          (S_AXI_HP1_AWCACHE),
	  .SAXIHP1AWID             (S_AXI_HP1_AWID_in),
	  .SAXIHP1AWLEN            (S_AXI_HP1_AWLEN),
	  .SAXIHP1AWLOCK           (S_AXI_HP1_AWLOCK),
	  .SAXIHP1AWPROT           (S_AXI_HP1_AWPROT),
	  .SAXIHP1AWQOS            (S_AXI_HP1_AWQOS),
	  .SAXIHP1AWSIZE           (S_AXI_HP1_AWSIZE[1:0]),
	  .SAXIHP1AWVALID          (S_AXI_HP1_AWVALID),
	  .SAXIHP1BREADY           (S_AXI_HP1_BREADY),
	  .SAXIHP1RDISSUECAP1EN    (S_AXI_HP1_RDISSUECAP1_EN),
	  .SAXIHP1RREADY           (S_AXI_HP1_RREADY),
	  .SAXIHP1WDATA            (S_AXI_HP1_WDATA_in),
	  .SAXIHP1WID              (S_AXI_HP1_WID_in),
	  .SAXIHP1WLAST            (S_AXI_HP1_WLAST),
	  .SAXIHP1WRISSUECAP1EN    (S_AXI_HP1_WRISSUECAP1_EN),
	  .SAXIHP1WSTRB            (S_AXI_HP1_WSTRB_in),
	  .SAXIHP1WVALID           (S_AXI_HP1_WVALID),
	  .SAXIHP2ACLK             (S_AXI_HP2_ACLK_temp),
	  .SAXIHP2ARADDR           (S_AXI_HP2_ARADDR),
	  .SAXIHP2ARBURST          (S_AXI_HP2_ARBURST),
	  .SAXIHP2ARCACHE          (S_AXI_HP2_ARCACHE),
	  .SAXIHP2ARID             (S_AXI_HP2_ARID_in),
	  .SAXIHP2ARLEN            (S_AXI_HP2_ARLEN),
	  .SAXIHP2ARLOCK           (S_AXI_HP2_ARLOCK),
	  .SAXIHP2ARPROT           (S_AXI_HP2_ARPROT),
	  .SAXIHP2ARQOS            (S_AXI_HP2_ARQOS),
	  .SAXIHP2ARSIZE           (S_AXI_HP2_ARSIZE[1:0]),
	  .SAXIHP2ARVALID          (S_AXI_HP2_ARVALID),
	  .SAXIHP2AWADDR           (S_AXI_HP2_AWADDR),
	  .SAXIHP2AWBURST          (S_AXI_HP2_AWBURST),
	  .SAXIHP2AWCACHE          (S_AXI_HP2_AWCACHE),
	  .SAXIHP2AWID             (S_AXI_HP2_AWID_in),
	  .SAXIHP2AWLEN            (S_AXI_HP2_AWLEN),
	  .SAXIHP2AWLOCK           (S_AXI_HP2_AWLOCK),
	  .SAXIHP2AWPROT           (S_AXI_HP2_AWPROT),
	  .SAXIHP2AWQOS            (S_AXI_HP2_AWQOS),
	  .SAXIHP2AWSIZE           (S_AXI_HP2_AWSIZE[1:0]),
	  .SAXIHP2AWVALID          (S_AXI_HP2_AWVALID),
	  .SAXIHP2BREADY           (S_AXI_HP2_BREADY),
	  .SAXIHP2RDISSUECAP1EN    (S_AXI_HP2_RDISSUECAP1_EN),
	  .SAXIHP2RREADY           (S_AXI_HP2_RREADY),
	  .SAXIHP2WDATA            (S_AXI_HP2_WDATA_in),
	  .SAXIHP2WID              (S_AXI_HP2_WID_in),
	  .SAXIHP2WLAST            (S_AXI_HP2_WLAST),
	  .SAXIHP2WRISSUECAP1EN    (S_AXI_HP2_WRISSUECAP1_EN),
	  .SAXIHP2WSTRB            (S_AXI_HP2_WSTRB_in),
	  .SAXIHP2WVALID           (S_AXI_HP2_WVALID),  
	  .SAXIHP3ACLK             (S_AXI_HP3_ACLK_temp),
	  .SAXIHP3ARADDR           (S_AXI_HP3_ARADDR ),
	  .SAXIHP3ARBURST          (S_AXI_HP3_ARBURST),
	  .SAXIHP3ARCACHE          (S_AXI_HP3_ARCACHE),
	  .SAXIHP3ARID             (S_AXI_HP3_ARID_in   ),
	  .SAXIHP3ARLEN            (S_AXI_HP3_ARLEN),
	  .SAXIHP3ARLOCK           (S_AXI_HP3_ARLOCK),
	  .SAXIHP3ARPROT           (S_AXI_HP3_ARPROT),
	  .SAXIHP3ARQOS            (S_AXI_HP3_ARQOS),
	  .SAXIHP3ARSIZE           (S_AXI_HP3_ARSIZE[1:0]),
	  .SAXIHP3ARVALID          (S_AXI_HP3_ARVALID),
	  .SAXIHP3AWADDR           (S_AXI_HP3_AWADDR),
	  .SAXIHP3AWBURST          (S_AXI_HP3_AWBURST),
	  .SAXIHP3AWCACHE          (S_AXI_HP3_AWCACHE),
	  .SAXIHP3AWID             (S_AXI_HP3_AWID_in),
	  .SAXIHP3AWLEN            (S_AXI_HP3_AWLEN),
	  .SAXIHP3AWLOCK           (S_AXI_HP3_AWLOCK),
	  .SAXIHP3AWPROT           (S_AXI_HP3_AWPROT),
	  .SAXIHP3AWQOS            (S_AXI_HP3_AWQOS),
	  .SAXIHP3AWSIZE           (S_AXI_HP3_AWSIZE[1:0]),
	  .SAXIHP3AWVALID          (S_AXI_HP3_AWVALID),
	  .SAXIHP3BREADY           (S_AXI_HP3_BREADY),
	  .SAXIHP3RDISSUECAP1EN    (S_AXI_HP3_RDISSUECAP1_EN),
	  .SAXIHP3RREADY           (S_AXI_HP3_RREADY),
	  .SAXIHP3WDATA            (S_AXI_HP3_WDATA_in),
	  .SAXIHP3WID              (S_AXI_HP3_WID_in),
	  .SAXIHP3WLAST            (S_AXI_HP3_WLAST),
	  .SAXIHP3WRISSUECAP1EN    (S_AXI_HP3_WRISSUECAP1_EN),
	  .SAXIHP3WSTRB            (S_AXI_HP3_WSTRB_in),
	  .SAXIHP3WVALID           (S_AXI_HP3_WVALID),
	  .DDRA		           (buffered_DDR_Addr),
	  .DDRBA		   (buffered_DDR_BankAddr),
	  .DDRCASB		   (buffered_DDR_CAS_n),
	  .DDRCKE		   (buffered_DDR_CKE),
	  .DDRCKN		   (buffered_DDR_Clk_n),
	  .DDRCKP		   (buffered_DDR_Clk),
	  .DDRCSB		   (buffered_DDR_CS_n),
	  .DDRDM		   (buffered_DDR_DM),
	  .DDRDQ		   (buffered_DDR_DQ),
	  .DDRDQSN		   (buffered_DDR_DQS_n),
	  .DDRDQSP		   (buffered_DDR_DQS),
	  .DDRDRSTB                (buffered_DDR_DRSTB),
	  .DDRODT		   (buffered_DDR_ODT),  
	  .DDRRASB		   (buffered_DDR_RAS_n),
	  .DDRVRN                  (buffered_DDR_VRN),
	  .DDRVRP                  (buffered_DDR_VRP),
	  .DDRWEB                  (buffered_DDR_WEB),
	  .MIO			   (buffered_MIO),
	  .PSCLK		   (buffered_PS_CLK),  
	  .PSPORB		   (buffered_PS_PORB),  
	  .PSSRSTB		   (buffered_PS_SRSTB)  
	  

	);
 	
 end
 endgenerate


// Generating the AxUSER Values locally when the C_USE_DEFAULT_ACP_USER_VAL is enabled.
// Otherwise a master connected to the ACP port will drive the AxUSER Ports
assign param_aruser = C_USE_DEFAULT_ACP_USER_VAL? C_S_AXI_ACP_ARUSER_VAL : S_AXI_ACP_ARUSER;
assign param_awuser = C_USE_DEFAULT_ACP_USER_VAL? C_S_AXI_ACP_AWUSER_VAL : S_AXI_ACP_AWUSER;

  assign  SAXIACPARADDR_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_ARADDR  : S_AXI_ACP_ARADDR;
  assign  SAXIACPARBURST_W     = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_ARBURST : S_AXI_ACP_ARBURST;
  assign  SAXIACPARCACHE_W     = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_ARCACHE : S_AXI_ACP_ARCACHE;
  assign  SAXIACPARLEN_W       = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_ARLEN   : S_AXI_ACP_ARLEN;
  assign  SAXIACPARLOCK_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_ARLOCK  : S_AXI_ACP_ARLOCK;
  assign  SAXIACPARPROT_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_ARPROT  : S_AXI_ACP_ARPROT;
  assign  SAXIACPARSIZE_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_ARSIZE  : S_AXI_ACP_ARSIZE;
  //assign  SAXIACPARUSER_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_ARUSER  : S_AXI_ACP_ARUSER;
  assign  SAXIACPARUSER_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_ARUSER  : param_aruser;
  
  assign  SAXIACPARVALID_W     = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_ARVALID : S_AXI_ACP_ARVALID ;
  assign  SAXIACPAWADDR_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_AWADDR  : S_AXI_ACP_AWADDR;
  assign  SAXIACPAWBURST_W     = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_AWBURST : S_AXI_ACP_AWBURST;
  
  
  assign  SAXIACPAWCACHE_W     = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_AWCACHE : S_AXI_ACP_AWCACHE;
  assign  SAXIACPAWLEN_W       = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_AWLEN   : S_AXI_ACP_AWLEN;
  assign  SAXIACPAWLOCK_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_AWLOCK  : S_AXI_ACP_AWLOCK;
  assign  SAXIACPAWPROT_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_AWPROT  : S_AXI_ACP_AWPROT;
  assign  SAXIACPAWSIZE_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_AWSIZE  : S_AXI_ACP_AWSIZE;
  //assign  SAXIACPAWUSER_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_AWUSER  : S_AXI_ACP_AWUSER;
  assign  SAXIACPAWUSER_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_AWUSER  : param_awuser;
  assign  SAXIACPAWVALID_W     = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_AWVALID : S_AXI_ACP_AWVALID;
  assign  SAXIACPBREADY_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_BREADY  : S_AXI_ACP_BREADY;
  assign  SAXIACPRREADY_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_RREADY  : S_AXI_ACP_RREADY;
  assign  SAXIACPWDATA_W       = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_WDATA   : S_AXI_ACP_WDATA;
  assign  SAXIACPWLAST_W       = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_WLAST   : S_AXI_ACP_WLAST;
  assign  SAXIACPWSTRB_W       = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_WSTRB   : S_AXI_ACP_WSTRB;  
  assign  SAXIACPWVALID_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_WVALID  : S_AXI_ACP_WVALID;      
  
  assign  SAXIACPARID_W     = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_ARID    : S_AXI_ACP_ARID;    
  assign  SAXIACPAWID_W     = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_AWID    : S_AXI_ACP_AWID;      
  assign  SAXIACPWID_W      = (C_INCLUDE_ACP_TRANS_CHECK == 1) ? S_AXI_ATC_WID     : S_AXI_ACP_WID;        
  

  generate
    if (C_INCLUDE_ACP_TRANS_CHECK == 0) begin : gen_no_atc
    
    assign S_AXI_ACP_AWREADY          =   SAXIACPAWREADY_W;
    assign S_AXI_ACP_WREADY           =   SAXIACPWREADY_W;
    assign S_AXI_ACP_BID              =   SAXIACPBID_W;    
    assign S_AXI_ACP_BRESP            =   SAXIACPBRESP_W;  
    assign S_AXI_ACP_BVALID           =   SAXIACPBVALID_W;    
    assign S_AXI_ACP_RDATA            =	  SAXIACPRDATA_W;    
    assign S_AXI_ACP_RID              =	  SAXIACPRID_W;        
    assign S_AXI_ACP_RLAST            =	  SAXIACPRLAST_W;  
    assign S_AXI_ACP_RRESP            =	  SAXIACPRRESP_W;  
    assign S_AXI_ACP_RVALID           =	  SAXIACPRVALID_W; 
    assign S_AXI_ACP_ARREADY          =	  SAXIACPARREADY_W;
    

    end else begin : gen_atc
    
  processing_system7_v5_5_atc #(
   .C_AXI_ID_WIDTH                   (C_S_AXI_ACP_ID_WIDTH),
   .C_AXI_AWUSER_WIDTH               (5),
   .C_AXI_ARUSER_WIDTH               (5)
   )
   
  atc_i (

   // Global Signals
   .ACLK                                (S_AXI_ACP_ACLK_temp),
   .ARESETN                             (S_AXI_ACP_ARESETN),

   // Slave Interface Write Address Ports
   .S_AXI_AWID                           (S_AXI_ACP_AWID),
   .S_AXI_AWADDR                         (S_AXI_ACP_AWADDR),
   .S_AXI_AWLEN                          (S_AXI_ACP_AWLEN),
   .S_AXI_AWSIZE                         (S_AXI_ACP_AWSIZE),
   .S_AXI_AWBURST                        (S_AXI_ACP_AWBURST),
   .S_AXI_AWLOCK                         (S_AXI_ACP_AWLOCK),
   .S_AXI_AWCACHE                        (S_AXI_ACP_AWCACHE),
   .S_AXI_AWPROT                         (S_AXI_ACP_AWPROT),
   //.S_AXI_AWUSER                         (S_AXI_ACP_AWUSER),
   .S_AXI_AWUSER                         (param_awuser),
   .S_AXI_AWVALID                        (S_AXI_ACP_AWVALID),
   .S_AXI_AWREADY                        (S_AXI_ACP_AWREADY),
   // Slave Interface Write Data Ports
   .S_AXI_WID                            (S_AXI_ACP_WID),
   .S_AXI_WDATA                          (S_AXI_ACP_WDATA),
   .S_AXI_WSTRB                          (S_AXI_ACP_WSTRB),
   .S_AXI_WLAST                          (S_AXI_ACP_WLAST),
   .S_AXI_WUSER                          (),
   .S_AXI_WVALID                         (S_AXI_ACP_WVALID),
   .S_AXI_WREADY                         (S_AXI_ACP_WREADY),
   // Slave Interface Write Response Ports
   .S_AXI_BID                            (S_AXI_ACP_BID),
   .S_AXI_BRESP                          (S_AXI_ACP_BRESP),
   .S_AXI_BUSER                          (),
   .S_AXI_BVALID                         (S_AXI_ACP_BVALID),
   .S_AXI_BREADY                         (S_AXI_ACP_BREADY),
   // Slave Interface Read Address Ports
   .S_AXI_ARID                           (S_AXI_ACP_ARID),
   .S_AXI_ARADDR                         (S_AXI_ACP_ARADDR),
   .S_AXI_ARLEN                          (S_AXI_ACP_ARLEN),
   .S_AXI_ARSIZE                         (S_AXI_ACP_ARSIZE),
   .S_AXI_ARBURST                        (S_AXI_ACP_ARBURST),
   .S_AXI_ARLOCK                         (S_AXI_ACP_ARLOCK),
   .S_AXI_ARCACHE                        (S_AXI_ACP_ARCACHE),
   .S_AXI_ARPROT                         (S_AXI_ACP_ARPROT),
   //.S_AXI_ARUSER                         (S_AXI_ACP_ARUSER),
   .S_AXI_ARUSER                         (param_aruser),
   .S_AXI_ARVALID                        (S_AXI_ACP_ARVALID),
   .S_AXI_ARREADY                        (S_AXI_ACP_ARREADY),
   // Slave Interface Read Data Ports
   .S_AXI_RID                            (S_AXI_ACP_RID),
   .S_AXI_RDATA                          (S_AXI_ACP_RDATA),
   .S_AXI_RRESP                          (S_AXI_ACP_RRESP),
   .S_AXI_RLAST                          (S_AXI_ACP_RLAST),
   .S_AXI_RUSER                          (),
   .S_AXI_RVALID                         (S_AXI_ACP_RVALID),
   .S_AXI_RREADY                         (S_AXI_ACP_RREADY),

    // Slave Interface Write Address Ports
   .M_AXI_AWID                           (S_AXI_ATC_AWID),
   .M_AXI_AWADDR                         (S_AXI_ATC_AWADDR),
   .M_AXI_AWLEN                          (S_AXI_ATC_AWLEN),
   .M_AXI_AWSIZE                         (S_AXI_ATC_AWSIZE),
   .M_AXI_AWBURST                        (S_AXI_ATC_AWBURST),
   .M_AXI_AWLOCK                         (S_AXI_ATC_AWLOCK),
   .M_AXI_AWCACHE                        (S_AXI_ATC_AWCACHE),
   .M_AXI_AWPROT                         (S_AXI_ATC_AWPROT),
   .M_AXI_AWUSER                         (S_AXI_ATC_AWUSER),
   .M_AXI_AWVALID                        (S_AXI_ATC_AWVALID),
   .M_AXI_AWREADY                        (SAXIACPAWREADY_W),
   // Slave Interface Write Data Ports
   .M_AXI_WID                            (S_AXI_ATC_WID),
   .M_AXI_WDATA                          (S_AXI_ATC_WDATA),
   .M_AXI_WSTRB                          (S_AXI_ATC_WSTRB),
   .M_AXI_WLAST                          (S_AXI_ATC_WLAST),
   .M_AXI_WUSER                          (),
   .M_AXI_WVALID                         (S_AXI_ATC_WVALID),
   .M_AXI_WREADY                         (SAXIACPWREADY_W),
   // Slave Interface Write Response Ports
   .M_AXI_BID                            (SAXIACPBID_W),
   .M_AXI_BRESP                          (SAXIACPBRESP_W),
   .M_AXI_BUSER                          (),
   .M_AXI_BVALID                         (SAXIACPBVALID_W),
   .M_AXI_BREADY                         (S_AXI_ATC_BREADY),
   // Slave Interface Read Address Ports
   .M_AXI_ARID                           (S_AXI_ATC_ARID),
   .M_AXI_ARADDR                         (S_AXI_ATC_ARADDR),
   .M_AXI_ARLEN                          (S_AXI_ATC_ARLEN),
   .M_AXI_ARSIZE                         (S_AXI_ATC_ARSIZE),
   .M_AXI_ARBURST                        (S_AXI_ATC_ARBURST),
   .M_AXI_ARLOCK                         (S_AXI_ATC_ARLOCK),
   .M_AXI_ARCACHE                        (S_AXI_ATC_ARCACHE),
   .M_AXI_ARPROT                         (S_AXI_ATC_ARPROT),
   .M_AXI_ARUSER                         (S_AXI_ATC_ARUSER),
   .M_AXI_ARVALID                        (S_AXI_ATC_ARVALID),
   .M_AXI_ARREADY                        (SAXIACPARREADY_W),
   // Slave Interface Read Data Ports
   .M_AXI_RID                            (SAXIACPRID_W),
   .M_AXI_RDATA                          (SAXIACPRDATA_W),
   .M_AXI_RRESP                          (SAXIACPRRESP_W),
   .M_AXI_RLAST                          (SAXIACPRLAST_W),
   .M_AXI_RUSER                          (),
   .M_AXI_RVALID                         (SAXIACPRVALID_W),
   .M_AXI_RREADY                         (S_AXI_ATC_RREADY),

   
   .ERROR_TRIGGER(),
   .ERROR_TRANSACTION_ID()
   );    



    end
  endgenerate




endmodule


/****************************************************************************
 *  Xilinx Confidential
 *  Copyright 2013 Xilinx, Inc.  All rights reserved
 *
 *       File:           xlnx_axi_wrshim_unwrap.sv
 *       Owner:          jmurray
 *       Initial Date:   22-May-2013
 *
 *
 *       Description:
 *         - Wr Shim to prevent PCIe lockup scenario
 *         - Should be inserted inline with any masters WrData and WrCmd AXI
 *           channels
 *         - Will not allow the wrCmd to be issued unless the first beat of
 *           the associated wrBurst is available
 *         - Likewise, will not allow the first beat of wrData to be issued
 *           unless the associated wrCmd is available
 *
 ****************************************************************************/
module xlnx_axi_wrshim_unwrap #(
    parameter ID_WIDTH =  6,    // ID width
    parameter AD_WIDTH = 32,    // Address Width
    parameter D_WIDTH  = 64     // Data Width
   )

(
//
//***********  MISC Signals ***************** 
//
  input                clk,
  input                rst_n,
  //input                apb_en_wrshim,
//
//*********** FUll AXI Interface Input (from Master) ***************** 
//
  input[3:0]           awqos_in,
  input[ID_WIDTH-1:0]  awid_in,
  input[AD_WIDTH-1:0]  awaddr_in,
  input[3:0]           awlen_in,
  input[2:0]           awsize_in,
  input[1:0]           awburst_in,
  input[1:0]           awlock_in,
  input[3:0]           awcache_in,
  input[2:0]           awprot_in,
  input                awvalid_in,
  output               awready_in,
  input[D_WIDTH-1:0]   wdata_in,
  input[ID_WIDTH-1:0]  wid_in,
  input[D_WIDTH/8-1:0] wstrb_in,
  input                wlast_in,
  input                wvalid_in,
  output               wready_in,
  output[ID_WIDTH-1:0] bid_in,
  output[1:0]          bresp_in,
  output               bvalid_in,
  input                bready_in,
  input[3:0]           arqos_in,
  input[ID_WIDTH-1:0]  arid_in,
  input[AD_WIDTH-1:0]  araddr_in,
  input[3:0]           arlen_in,
  input[2:0]           arsize_in,
  input[1:0]           arburst_in,
  input[1:0]           arlock_in,
  input[3:0]           arcache_in,
  input[2:0]           arprot_in,
  input                arvalid_in,
  output               arready_in,
  output[ID_WIDTH-1:0] rid_in,
  output[D_WIDTH-1:0]  rdata_in,
  output[1:0]          rresp_in,
  output               rlast_in,
  output               rvalid_in,
  input                rready_in,
//
//*********** FUll AXI Interface Input (to Slave ) *****************
//
  output[3:0]           awqos_out,
  output[ID_WIDTH-1:0]  awid_out,
  output[AD_WIDTH-1:0]  awaddr_out,
  output[3:0]           awlen_out,
  output[2:0]           awsize_out,
  output[1:0]           awburst_out,
  output[1:0]           awlock_out,
  output[3:0]           awcache_out,
  output[2:0]           awprot_out,
  output                awvalid_out,
  input                 awready_out,
  output[D_WIDTH-1:0]   wdata_out,
  output[ID_WIDTH-1:0]  wid_out,
  output[D_WIDTH/8-1:0] wstrb_out,
  output                wlast_out,
  output                wvalid_out,
  input                 wready_out,
  input[ID_WIDTH-1:0]   bid_out,
  input[1:0]            bresp_out,
  input                 bvalid_out,
  output                bready_out,
  output[3:0]           arqos_out,
  output[ID_WIDTH-1:0]  arid_out,
  output[AD_WIDTH-1:0]  araddr_out,
  output[3:0]           arlen_out,
  output[2:0]           arsize_out,
  output[1:0]           arburst_out,
  output[1:0]           arlock_out,
  output[3:0]           arcache_out,
  output[2:0]           arprot_out,
  output                arvalid_out,
  input                 arready_out,
  input[ID_WIDTH-1:0]   rid_out,
  input[D_WIDTH-1:0]    rdata_out,
  input[1:0]            rresp_out,
  input                 rlast_out,
  input                 rvalid_out,
  output                rready_out
);


/* ========================================================================== */
//  Register and Wire Declarations
/* ========================================================================== */
  wire   wlast_consumed;
  wire   en_wrshim;
  reg    wlast_detect;
  reg    stall_awvalid;
  reg    store_first_beat;
  reg    previous_cmd_done;
  reg    burst_still_active;
  reg [2:0]   awsize_i;
  reg [D_WIDTH-1:0]   wdata_i;
  reg [1:0] address_offset;
 
  localparam  AXI_WRSHIM_APB_SYNC_LEVELS = 2;

/* ========================================================================== */
// Code the Shim
/* ========================================================================== */
  // Sync the APB enable signal for the shim
 /*  
 xlnx_sync_bit #(AXI_WRSHIM_APB_SYNC_LEVELS, 0) axi_wrshim_en_sync (
    .clk         (clk),
    .rst_n       (rst_n),
    .raw_input   (apb_en_wrshim),
    .sync_out    (en_wrshim)
  );
 */

 wire axi_burst_length_is_zero= (awvalid_in && (awlen_in==0))?1'b1:1'b0;
 wire zero_length_transfer=axi_burst_length_is_zero ;
 //assign en_wrshim=zero_length_transfer;
 assign en_wrshim=1'b1;
//
//*********** AXI signals Flow Throughs ***************** 
//
  assign bid_in      = bid_out;
  assign bresp_in    = bresp_out;
  assign bvalid_in   = bvalid_out;
  assign arready_in  = arready_out;
  assign rid_in      = rid_out;
  assign rdata_in    = rdata_out;
  assign rresp_in    = rresp_out;
  assign rlast_in    = rlast_out;
  assign rvalid_in   = rvalid_out;
  assign awqos_out   = awqos_in;
  assign awid_out    = awid_in;
  assign awaddr_out[31:2]  = awaddr_in[31:2];
  assign awaddr_out[1:0]  = (zero_length_transfer==1)?address_offset:awaddr_in[1:0];
  assign awlen_out   = awlen_in;
  assign awsize_out  = (zero_length_transfer==1)?awsize_i:awsize_in;
  assign awburst_out = awburst_in;
  assign awlock_out  = awlock_in;
  assign awcache_out = awcache_in;
  assign awprot_out  = awprot_in;
  //assign wdata_out   = (zero_length_transfer==1)?wdata_i:wdata_in;
  assign wdata_out   = wdata_in;
  assign wid_out     = wid_in;
  assign wstrb_out   = wstrb_in;
  assign wlast_out   = wlast_in;
  assign bready_out  = bready_in;
  assign arqos_out   = arqos_in;
  assign arid_out    = arid_in;
  assign araddr_out  = araddr_in;
  assign arlen_out   = arlen_in;
  assign arsize_out  = arsize_in;
  assign arburst_out = arburst_in;
  assign arlock_out  = arlock_in;
  assign arcache_out = arcache_in;
  assign arprot_out  = arprot_in;
  assign arvalid_out = arvalid_in;
  assign rready_out  = rready_in;


// *****************************************************************
// ************************* WRITE COMMAND ****************************
// *****************************************************************
  // Detect a Wlast. This is required since we cannot release the next AwCmd
  // before we have seen a wlast from the previous WrBurst
  always @(posedge clk )
    if (!rst_n) 
      wlast_detect <= 1'b1;
    else begin
      if (wlast_consumed)
        wlast_detect <= 1'b1;
     else if (en_wrshim && wvalid_out && wready_out)
        wlast_detect <= 1'b0;
    end

  // Detect the First WrData Beat of a wrBurst - only need to determine if
  // it is available, NOT that it is consumed
  wire first_beat_detect = wlast_detect && wvalid_in;

  // Enable the Write Command to be issued
  wire awcmd_en = en_wrshim ? ((first_beat_detect && !stall_awvalid) || 
                                store_first_beat) : 1'b1;
  
  //assign awvalid_out = (zero_length_transfer==1)?awvalid_in && awcmd_en:awvalid_in;
  assign awvalid_out = awvalid_in && awcmd_en;

  // Also need to flow control the AwReady
  //assign awready_in = (zero_length_transfer==1)?awready_out && awcmd_en:awready_out;
  assign awready_in = awready_out && awcmd_en;


  // Detect the case where AwCmd is released, but the wrData is not consumed
  always @(posedge clk )
    if (!rst_n) 
      stall_awvalid <= 1'b0;
    else begin
      if (en_wrshim && awvalid_out && awready_out && !wready_out)
        stall_awvalid <= 1'b1;
      else if (wready_out)
        stall_awvalid <= 1'b0;
    end
  

  // Detect the case where AwValid=1, WValid=1, but AWReady=0 (WReady=1)
  always @(posedge clk )
    if (!rst_n) 
      store_first_beat <= 1'b0;
    else begin
      if (en_wrshim && first_beat_detect && !awready_out)
        store_first_beat <= 1'b1;
      else if (awready_out)
        store_first_beat <= 1'b0;
    end



// *****************************************************************
// ************************* WRITE DATA ****************************
// *****************************************************************
  assign wlast_consumed = (wvalid_out && wready_out && wlast_in);

  // For the Write Data, We need to enable the entire wrBurst
  wire start_wr = wlast_detect && awvalid_in && previous_cmd_done;

  // Detect if the previous AwCmd was consumed - May be backpressure
  always @(posedge clk )
    if (!rst_n)
      previous_cmd_done <= 1'b1;
    else begin
      if (awvalid_out && awready_out)
        previous_cmd_done <= 1'b1;
      else if (awvalid_out && en_wrshim)
        previous_cmd_done <= 1'b0;
    end


  // Store the enable unless it is a single beat wrCmd
  always @(posedge clk )
    if (!rst_n)
      burst_still_active <= 1'b0;
    else begin
      if (start_wr && !wlast_consumed && en_wrshim)
        burst_still_active <= 1'b1;
      else if (wlast_consumed)
        burst_still_active <= 1'b0;
    end

  wire write_data_en = en_wrshim ? (burst_still_active || start_wr) : 1'b1;

  //assign wvalid_out = (zero_length_transfer==1)? wvalid_in && write_data_en:wvalid_in;
  //assign wready_in  = (zero_length_transfer==1)? wready_out && write_data_en:wready_out;
  assign wvalid_out =  wvalid_in && write_data_en;
  assign wready_in  =  wready_out && write_data_en;
 
  always @ *
    case (wstrb_in)
           4'b0001:begin
                      awsize_i=0;
                      wdata_i=wdata_in[7:0];
                      address_offset<=0; 
                   end
           4'b0010:begin
                      awsize_i=0;   
                      wdata_i=wdata_in[15:8];
                      address_offset<=1;
                   end    
           4'b0100:begin
                      awsize_i=0;
                      wdata_i=wdata_in[23:16];
                      address_offset<=2;
                   end
           4'b1000:begin
                      awsize_i=0;        
                      wdata_i=wdata_in[31:24];
                      address_offset<=3;
                   end
           4'b1100:begin
                      awsize_i=1;        
                      wdata_i=wdata_in[31:16];
                      address_offset<=2;
                   end
           4'b0011:begin
                      awsize_i=1;         
                      wdata_i=wdata_in[15:0];
                      address_offset<=0;
                   end
           default: begin
                      awsize_i=awsize_in;    
                      wdata_i=wdata_in;
                      address_offset<=0;
                    end
    endcase

  
endmodule
