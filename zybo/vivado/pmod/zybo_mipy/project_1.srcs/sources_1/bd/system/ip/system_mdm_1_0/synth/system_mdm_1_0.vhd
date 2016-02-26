-- (c) Copyright 1995-2016 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: xilinx.com:ip:mdm:3.2
-- IP Revision: 4

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY mdm_v3_2_4;
USE mdm_v3_2_4.MDM;

ENTITY system_mdm_1_0 IS
  PORT (
    Debug_SYS_Rst : OUT STD_LOGIC;
    Dbg_Clk_0 : OUT STD_LOGIC;
    Dbg_TDI_0 : OUT STD_LOGIC;
    Dbg_TDO_0 : IN STD_LOGIC;
    Dbg_Reg_En_0 : OUT STD_LOGIC_VECTOR(0 TO 7);
    Dbg_Capture_0 : OUT STD_LOGIC;
    Dbg_Shift_0 : OUT STD_LOGIC;
    Dbg_Update_0 : OUT STD_LOGIC;
    Dbg_Rst_0 : OUT STD_LOGIC;
    Dbg_Clk_1 : OUT STD_LOGIC;
    Dbg_TDI_1 : OUT STD_LOGIC;
    Dbg_TDO_1 : IN STD_LOGIC;
    Dbg_Reg_En_1 : OUT STD_LOGIC_VECTOR(0 TO 7);
    Dbg_Capture_1 : OUT STD_LOGIC;
    Dbg_Shift_1 : OUT STD_LOGIC;
    Dbg_Update_1 : OUT STD_LOGIC;
    Dbg_Rst_1 : OUT STD_LOGIC;
    Dbg_Clk_2 : OUT STD_LOGIC;
    Dbg_TDI_2 : OUT STD_LOGIC;
    Dbg_TDO_2 : IN STD_LOGIC;
    Dbg_Reg_En_2 : OUT STD_LOGIC_VECTOR(0 TO 7);
    Dbg_Capture_2 : OUT STD_LOGIC;
    Dbg_Shift_2 : OUT STD_LOGIC;
    Dbg_Update_2 : OUT STD_LOGIC;
    Dbg_Rst_2 : OUT STD_LOGIC;
    Dbg_Clk_3 : OUT STD_LOGIC;
    Dbg_TDI_3 : OUT STD_LOGIC;
    Dbg_TDO_3 : IN STD_LOGIC;
    Dbg_Reg_En_3 : OUT STD_LOGIC_VECTOR(0 TO 7);
    Dbg_Capture_3 : OUT STD_LOGIC;
    Dbg_Shift_3 : OUT STD_LOGIC;
    Dbg_Update_3 : OUT STD_LOGIC;
    Dbg_Rst_3 : OUT STD_LOGIC
  );
END system_mdm_1_0;

ARCHITECTURE system_mdm_1_0_arch OF system_mdm_1_0 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : string;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF system_mdm_1_0_arch: ARCHITECTURE IS "yes";

  COMPONENT MDM IS
    GENERIC (
      C_FAMILY : STRING;
      C_JTAG_CHAIN : INTEGER;
      C_USE_BSCAN : INTEGER;
      C_USE_CONFIG_RESET : INTEGER;
      C_INTERCONNECT : INTEGER;
      C_MB_DBG_PORTS : INTEGER;
      C_USE_UART : INTEGER;
      C_DBG_REG_ACCESS : INTEGER;
      C_DBG_MEM_ACCESS : INTEGER;
      C_USE_CROSS_TRIGGER : INTEGER;
      C_TRACE_OUTPUT : INTEGER;
      C_TRACE_DATA_WIDTH : INTEGER;
      C_TRACE_CLK_FREQ_HZ : INTEGER;
      C_TRACE_CLK_OUT_PHASE : INTEGER;
      C_S_AXI_ADDR_WIDTH : INTEGER;
      C_S_AXI_DATA_WIDTH : INTEGER;
      C_S_AXI_ACLK_FREQ_HZ : INTEGER;
      C_M_AXI_ADDR_WIDTH : INTEGER;
      C_M_AXI_DATA_WIDTH : INTEGER;
      C_M_AXI_THREAD_ID_WIDTH : INTEGER;
      C_DATA_SIZE : INTEGER;
      C_M_AXIS_DATA_WIDTH : INTEGER;
      C_M_AXIS_ID_WIDTH : INTEGER
    );
    PORT (
      Config_Reset : IN STD_LOGIC;
      Scan_Reset : IN STD_LOGIC;
      Scan_Reset_Sel : IN STD_LOGIC;
      S_AXI_ACLK : IN STD_LOGIC;
      S_AXI_ARESETN : IN STD_LOGIC;
      M_AXI_ACLK : IN STD_LOGIC;
      M_AXI_ARESETN : IN STD_LOGIC;
      M_AXIS_ACLK : IN STD_LOGIC;
      M_AXIS_ARESETN : IN STD_LOGIC;
      Interrupt : OUT STD_LOGIC;
      Ext_BRK : OUT STD_LOGIC;
      Ext_NM_BRK : OUT STD_LOGIC;
      Debug_SYS_Rst : OUT STD_LOGIC;
      Trig_In_0 : IN STD_LOGIC;
      Trig_Ack_In_0 : OUT STD_LOGIC;
      Trig_Out_0 : OUT STD_LOGIC;
      Trig_Ack_Out_0 : IN STD_LOGIC;
      Trig_In_1 : IN STD_LOGIC;
      Trig_Ack_In_1 : OUT STD_LOGIC;
      Trig_Out_1 : OUT STD_LOGIC;
      Trig_Ack_Out_1 : IN STD_LOGIC;
      Trig_In_2 : IN STD_LOGIC;
      Trig_Ack_In_2 : OUT STD_LOGIC;
      Trig_Out_2 : OUT STD_LOGIC;
      Trig_Ack_Out_2 : IN STD_LOGIC;
      Trig_In_3 : IN STD_LOGIC;
      Trig_Ack_In_3 : OUT STD_LOGIC;
      Trig_Out_3 : OUT STD_LOGIC;
      Trig_Ack_Out_3 : IN STD_LOGIC;
      S_AXI_AWADDR : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      S_AXI_AWVALID : IN STD_LOGIC;
      S_AXI_AWREADY : OUT STD_LOGIC;
      S_AXI_WDATA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      S_AXI_WSTRB : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S_AXI_WVALID : IN STD_LOGIC;
      S_AXI_WREADY : OUT STD_LOGIC;
      S_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S_AXI_BVALID : OUT STD_LOGIC;
      S_AXI_BREADY : IN STD_LOGIC;
      S_AXI_ARADDR : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      S_AXI_ARVALID : IN STD_LOGIC;
      S_AXI_ARREADY : OUT STD_LOGIC;
      S_AXI_RDATA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      S_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S_AXI_RVALID : OUT STD_LOGIC;
      S_AXI_RREADY : IN STD_LOGIC;
      M_AXI_AWID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      M_AXI_AWADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      M_AXI_AWLEN : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      M_AXI_AWSIZE : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      M_AXI_AWBURST : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      M_AXI_AWLOCK : OUT STD_LOGIC;
      M_AXI_AWCACHE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M_AXI_AWPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      M_AXI_AWQOS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M_AXI_AWVALID : OUT STD_LOGIC;
      M_AXI_AWREADY : IN STD_LOGIC;
      M_AXI_WDATA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      M_AXI_WSTRB : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M_AXI_WLAST : OUT STD_LOGIC;
      M_AXI_WVALID : OUT STD_LOGIC;
      M_AXI_WREADY : IN STD_LOGIC;
      M_AXI_BRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      M_AXI_BID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      M_AXI_BVALID : IN STD_LOGIC;
      M_AXI_BREADY : OUT STD_LOGIC;
      M_AXI_ARID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      M_AXI_ARADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      M_AXI_ARLEN : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      M_AXI_ARSIZE : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      M_AXI_ARBURST : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      M_AXI_ARLOCK : OUT STD_LOGIC;
      M_AXI_ARCACHE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M_AXI_ARPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      M_AXI_ARQOS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M_AXI_ARVALID : OUT STD_LOGIC;
      M_AXI_ARREADY : IN STD_LOGIC;
      M_AXI_RID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      M_AXI_RDATA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      M_AXI_RRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      M_AXI_RLAST : IN STD_LOGIC;
      M_AXI_RVALID : IN STD_LOGIC;
      M_AXI_RREADY : OUT STD_LOGIC;
      LMB_Data_Addr_0 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_0 : OUT STD_LOGIC;
      LMB_Ready_0 : IN STD_LOGIC;
      LMB_Byte_Enable_0 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_0 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_0 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_0 : OUT STD_LOGIC;
      LMB_Write_Strobe_0 : OUT STD_LOGIC;
      LMB_CE_0 : IN STD_LOGIC;
      LMB_UE_0 : IN STD_LOGIC;
      LMB_Wait_0 : IN STD_LOGIC;
      LMB_Data_Addr_1 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_1 : OUT STD_LOGIC;
      LMB_Ready_1 : IN STD_LOGIC;
      LMB_Byte_Enable_1 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_1 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_1 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_1 : OUT STD_LOGIC;
      LMB_Write_Strobe_1 : OUT STD_LOGIC;
      LMB_CE_1 : IN STD_LOGIC;
      LMB_UE_1 : IN STD_LOGIC;
      LMB_Wait_1 : IN STD_LOGIC;
      LMB_Data_Addr_2 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_2 : OUT STD_LOGIC;
      LMB_Ready_2 : IN STD_LOGIC;
      LMB_Byte_Enable_2 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_2 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_2 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_2 : OUT STD_LOGIC;
      LMB_Write_Strobe_2 : OUT STD_LOGIC;
      LMB_CE_2 : IN STD_LOGIC;
      LMB_UE_2 : IN STD_LOGIC;
      LMB_Wait_2 : IN STD_LOGIC;
      LMB_Data_Addr_3 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_3 : OUT STD_LOGIC;
      LMB_Ready_3 : IN STD_LOGIC;
      LMB_Byte_Enable_3 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_3 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_3 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_3 : OUT STD_LOGIC;
      LMB_Write_Strobe_3 : OUT STD_LOGIC;
      LMB_CE_3 : IN STD_LOGIC;
      LMB_UE_3 : IN STD_LOGIC;
      LMB_Wait_3 : IN STD_LOGIC;
      LMB_Data_Addr_4 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_4 : OUT STD_LOGIC;
      LMB_Ready_4 : IN STD_LOGIC;
      LMB_Byte_Enable_4 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_4 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_4 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_4 : OUT STD_LOGIC;
      LMB_Write_Strobe_4 : OUT STD_LOGIC;
      LMB_CE_4 : IN STD_LOGIC;
      LMB_UE_4 : IN STD_LOGIC;
      LMB_Wait_4 : IN STD_LOGIC;
      LMB_Data_Addr_5 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_5 : OUT STD_LOGIC;
      LMB_Ready_5 : IN STD_LOGIC;
      LMB_Byte_Enable_5 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_5 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_5 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_5 : OUT STD_LOGIC;
      LMB_Write_Strobe_5 : OUT STD_LOGIC;
      LMB_CE_5 : IN STD_LOGIC;
      LMB_UE_5 : IN STD_LOGIC;
      LMB_Wait_5 : IN STD_LOGIC;
      LMB_Data_Addr_6 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_6 : OUT STD_LOGIC;
      LMB_Ready_6 : IN STD_LOGIC;
      LMB_Byte_Enable_6 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_6 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_6 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_6 : OUT STD_LOGIC;
      LMB_Write_Strobe_6 : OUT STD_LOGIC;
      LMB_CE_6 : IN STD_LOGIC;
      LMB_UE_6 : IN STD_LOGIC;
      LMB_Wait_6 : IN STD_LOGIC;
      LMB_Data_Addr_7 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_7 : OUT STD_LOGIC;
      LMB_Ready_7 : IN STD_LOGIC;
      LMB_Byte_Enable_7 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_7 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_7 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_7 : OUT STD_LOGIC;
      LMB_Write_Strobe_7 : OUT STD_LOGIC;
      LMB_CE_7 : IN STD_LOGIC;
      LMB_UE_7 : IN STD_LOGIC;
      LMB_Wait_7 : IN STD_LOGIC;
      LMB_Data_Addr_8 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_8 : OUT STD_LOGIC;
      LMB_Ready_8 : IN STD_LOGIC;
      LMB_Byte_Enable_8 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_8 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_8 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_8 : OUT STD_LOGIC;
      LMB_Write_Strobe_8 : OUT STD_LOGIC;
      LMB_CE_8 : IN STD_LOGIC;
      LMB_UE_8 : IN STD_LOGIC;
      LMB_Wait_8 : IN STD_LOGIC;
      LMB_Data_Addr_9 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_9 : OUT STD_LOGIC;
      LMB_Ready_9 : IN STD_LOGIC;
      LMB_Byte_Enable_9 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_9 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_9 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_9 : OUT STD_LOGIC;
      LMB_Write_Strobe_9 : OUT STD_LOGIC;
      LMB_CE_9 : IN STD_LOGIC;
      LMB_UE_9 : IN STD_LOGIC;
      LMB_Wait_9 : IN STD_LOGIC;
      LMB_Data_Addr_10 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_10 : OUT STD_LOGIC;
      LMB_Ready_10 : IN STD_LOGIC;
      LMB_Byte_Enable_10 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_10 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_10 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_10 : OUT STD_LOGIC;
      LMB_Write_Strobe_10 : OUT STD_LOGIC;
      LMB_CE_10 : IN STD_LOGIC;
      LMB_UE_10 : IN STD_LOGIC;
      LMB_Wait_10 : IN STD_LOGIC;
      LMB_Data_Addr_11 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_11 : OUT STD_LOGIC;
      LMB_Ready_11 : IN STD_LOGIC;
      LMB_Byte_Enable_11 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_11 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_11 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_11 : OUT STD_LOGIC;
      LMB_Write_Strobe_11 : OUT STD_LOGIC;
      LMB_CE_11 : IN STD_LOGIC;
      LMB_UE_11 : IN STD_LOGIC;
      LMB_Wait_11 : IN STD_LOGIC;
      LMB_Data_Addr_12 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_12 : OUT STD_LOGIC;
      LMB_Ready_12 : IN STD_LOGIC;
      LMB_Byte_Enable_12 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_12 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_12 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_12 : OUT STD_LOGIC;
      LMB_Write_Strobe_12 : OUT STD_LOGIC;
      LMB_CE_12 : IN STD_LOGIC;
      LMB_UE_12 : IN STD_LOGIC;
      LMB_Wait_12 : IN STD_LOGIC;
      LMB_Data_Addr_13 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_13 : OUT STD_LOGIC;
      LMB_Ready_13 : IN STD_LOGIC;
      LMB_Byte_Enable_13 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_13 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_13 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_13 : OUT STD_LOGIC;
      LMB_Write_Strobe_13 : OUT STD_LOGIC;
      LMB_CE_13 : IN STD_LOGIC;
      LMB_UE_13 : IN STD_LOGIC;
      LMB_Wait_13 : IN STD_LOGIC;
      LMB_Data_Addr_14 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_14 : OUT STD_LOGIC;
      LMB_Ready_14 : IN STD_LOGIC;
      LMB_Byte_Enable_14 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_14 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_14 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_14 : OUT STD_LOGIC;
      LMB_Write_Strobe_14 : OUT STD_LOGIC;
      LMB_CE_14 : IN STD_LOGIC;
      LMB_UE_14 : IN STD_LOGIC;
      LMB_Wait_14 : IN STD_LOGIC;
      LMB_Data_Addr_15 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_15 : OUT STD_LOGIC;
      LMB_Ready_15 : IN STD_LOGIC;
      LMB_Byte_Enable_15 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_15 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_15 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_15 : OUT STD_LOGIC;
      LMB_Write_Strobe_15 : OUT STD_LOGIC;
      LMB_CE_15 : IN STD_LOGIC;
      LMB_UE_15 : IN STD_LOGIC;
      LMB_Wait_15 : IN STD_LOGIC;
      LMB_Data_Addr_16 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_16 : OUT STD_LOGIC;
      LMB_Ready_16 : IN STD_LOGIC;
      LMB_Byte_Enable_16 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_16 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_16 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_16 : OUT STD_LOGIC;
      LMB_Write_Strobe_16 : OUT STD_LOGIC;
      LMB_CE_16 : IN STD_LOGIC;
      LMB_UE_16 : IN STD_LOGIC;
      LMB_Wait_16 : IN STD_LOGIC;
      LMB_Data_Addr_17 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_17 : OUT STD_LOGIC;
      LMB_Ready_17 : IN STD_LOGIC;
      LMB_Byte_Enable_17 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_17 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_17 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_17 : OUT STD_LOGIC;
      LMB_Write_Strobe_17 : OUT STD_LOGIC;
      LMB_CE_17 : IN STD_LOGIC;
      LMB_UE_17 : IN STD_LOGIC;
      LMB_Wait_17 : IN STD_LOGIC;
      LMB_Data_Addr_18 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_18 : OUT STD_LOGIC;
      LMB_Ready_18 : IN STD_LOGIC;
      LMB_Byte_Enable_18 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_18 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_18 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_18 : OUT STD_LOGIC;
      LMB_Write_Strobe_18 : OUT STD_LOGIC;
      LMB_CE_18 : IN STD_LOGIC;
      LMB_UE_18 : IN STD_LOGIC;
      LMB_Wait_18 : IN STD_LOGIC;
      LMB_Data_Addr_19 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_19 : OUT STD_LOGIC;
      LMB_Ready_19 : IN STD_LOGIC;
      LMB_Byte_Enable_19 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_19 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_19 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_19 : OUT STD_LOGIC;
      LMB_Write_Strobe_19 : OUT STD_LOGIC;
      LMB_CE_19 : IN STD_LOGIC;
      LMB_UE_19 : IN STD_LOGIC;
      LMB_Wait_19 : IN STD_LOGIC;
      LMB_Data_Addr_20 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_20 : OUT STD_LOGIC;
      LMB_Ready_20 : IN STD_LOGIC;
      LMB_Byte_Enable_20 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_20 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_20 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_20 : OUT STD_LOGIC;
      LMB_Write_Strobe_20 : OUT STD_LOGIC;
      LMB_CE_20 : IN STD_LOGIC;
      LMB_UE_20 : IN STD_LOGIC;
      LMB_Wait_20 : IN STD_LOGIC;
      LMB_Data_Addr_21 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_21 : OUT STD_LOGIC;
      LMB_Ready_21 : IN STD_LOGIC;
      LMB_Byte_Enable_21 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_21 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_21 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_21 : OUT STD_LOGIC;
      LMB_Write_Strobe_21 : OUT STD_LOGIC;
      LMB_CE_21 : IN STD_LOGIC;
      LMB_UE_21 : IN STD_LOGIC;
      LMB_Wait_21 : IN STD_LOGIC;
      LMB_Data_Addr_22 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_22 : OUT STD_LOGIC;
      LMB_Ready_22 : IN STD_LOGIC;
      LMB_Byte_Enable_22 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_22 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_22 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_22 : OUT STD_LOGIC;
      LMB_Write_Strobe_22 : OUT STD_LOGIC;
      LMB_CE_22 : IN STD_LOGIC;
      LMB_UE_22 : IN STD_LOGIC;
      LMB_Wait_22 : IN STD_LOGIC;
      LMB_Data_Addr_23 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_23 : OUT STD_LOGIC;
      LMB_Ready_23 : IN STD_LOGIC;
      LMB_Byte_Enable_23 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_23 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_23 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_23 : OUT STD_LOGIC;
      LMB_Write_Strobe_23 : OUT STD_LOGIC;
      LMB_CE_23 : IN STD_LOGIC;
      LMB_UE_23 : IN STD_LOGIC;
      LMB_Wait_23 : IN STD_LOGIC;
      LMB_Data_Addr_24 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_24 : OUT STD_LOGIC;
      LMB_Ready_24 : IN STD_LOGIC;
      LMB_Byte_Enable_24 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_24 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_24 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_24 : OUT STD_LOGIC;
      LMB_Write_Strobe_24 : OUT STD_LOGIC;
      LMB_CE_24 : IN STD_LOGIC;
      LMB_UE_24 : IN STD_LOGIC;
      LMB_Wait_24 : IN STD_LOGIC;
      LMB_Data_Addr_25 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_25 : OUT STD_LOGIC;
      LMB_Ready_25 : IN STD_LOGIC;
      LMB_Byte_Enable_25 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_25 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_25 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_25 : OUT STD_LOGIC;
      LMB_Write_Strobe_25 : OUT STD_LOGIC;
      LMB_CE_25 : IN STD_LOGIC;
      LMB_UE_25 : IN STD_LOGIC;
      LMB_Wait_25 : IN STD_LOGIC;
      LMB_Data_Addr_26 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_26 : OUT STD_LOGIC;
      LMB_Ready_26 : IN STD_LOGIC;
      LMB_Byte_Enable_26 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_26 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_26 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_26 : OUT STD_LOGIC;
      LMB_Write_Strobe_26 : OUT STD_LOGIC;
      LMB_CE_26 : IN STD_LOGIC;
      LMB_UE_26 : IN STD_LOGIC;
      LMB_Wait_26 : IN STD_LOGIC;
      LMB_Data_Addr_27 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_27 : OUT STD_LOGIC;
      LMB_Ready_27 : IN STD_LOGIC;
      LMB_Byte_Enable_27 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_27 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_27 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_27 : OUT STD_LOGIC;
      LMB_Write_Strobe_27 : OUT STD_LOGIC;
      LMB_CE_27 : IN STD_LOGIC;
      LMB_UE_27 : IN STD_LOGIC;
      LMB_Wait_27 : IN STD_LOGIC;
      LMB_Data_Addr_28 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_28 : OUT STD_LOGIC;
      LMB_Ready_28 : IN STD_LOGIC;
      LMB_Byte_Enable_28 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_28 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_28 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_28 : OUT STD_LOGIC;
      LMB_Write_Strobe_28 : OUT STD_LOGIC;
      LMB_CE_28 : IN STD_LOGIC;
      LMB_UE_28 : IN STD_LOGIC;
      LMB_Wait_28 : IN STD_LOGIC;
      LMB_Data_Addr_29 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_29 : OUT STD_LOGIC;
      LMB_Ready_29 : IN STD_LOGIC;
      LMB_Byte_Enable_29 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_29 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_29 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_29 : OUT STD_LOGIC;
      LMB_Write_Strobe_29 : OUT STD_LOGIC;
      LMB_CE_29 : IN STD_LOGIC;
      LMB_UE_29 : IN STD_LOGIC;
      LMB_Wait_29 : IN STD_LOGIC;
      LMB_Data_Addr_30 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_30 : OUT STD_LOGIC;
      LMB_Ready_30 : IN STD_LOGIC;
      LMB_Byte_Enable_30 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_30 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_30 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_30 : OUT STD_LOGIC;
      LMB_Write_Strobe_30 : OUT STD_LOGIC;
      LMB_CE_30 : IN STD_LOGIC;
      LMB_UE_30 : IN STD_LOGIC;
      LMB_Wait_30 : IN STD_LOGIC;
      LMB_Data_Addr_31 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Addr_Strobe_31 : OUT STD_LOGIC;
      LMB_Ready_31 : IN STD_LOGIC;
      LMB_Byte_Enable_31 : OUT STD_LOGIC_VECTOR(0 TO 3);
      LMB_Data_Read_31 : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_Data_Write_31 : OUT STD_LOGIC_VECTOR(0 TO 31);
      LMB_Read_Strobe_31 : OUT STD_LOGIC;
      LMB_Write_Strobe_31 : OUT STD_LOGIC;
      LMB_CE_31 : IN STD_LOGIC;
      LMB_UE_31 : IN STD_LOGIC;
      LMB_Wait_31 : IN STD_LOGIC;
      M_AXIS_TDATA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      M_AXIS_TID : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
      M_AXIS_TREADY : IN STD_LOGIC;
      M_AXIS_TVALID : OUT STD_LOGIC;
      TRACE_CLK_OUT : OUT STD_LOGIC;
      TRACE_CLK : IN STD_LOGIC;
      TRACE_CTL : OUT STD_LOGIC;
      TRACE_DATA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      Dbg_Clk_0 : OUT STD_LOGIC;
      Dbg_TDI_0 : OUT STD_LOGIC;
      Dbg_TDO_0 : IN STD_LOGIC;
      Dbg_Reg_En_0 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_0 : OUT STD_LOGIC;
      Dbg_Shift_0 : OUT STD_LOGIC;
      Dbg_Update_0 : OUT STD_LOGIC;
      Dbg_Rst_0 : OUT STD_LOGIC;
      Dbg_Trig_In_0 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_0 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_0 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_0 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_0 : OUT STD_LOGIC;
      Dbg_TrData_0 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_0 : OUT STD_LOGIC;
      Dbg_TrValid_0 : IN STD_LOGIC;
      Dbg_Clk_1 : OUT STD_LOGIC;
      Dbg_TDI_1 : OUT STD_LOGIC;
      Dbg_TDO_1 : IN STD_LOGIC;
      Dbg_Reg_En_1 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_1 : OUT STD_LOGIC;
      Dbg_Shift_1 : OUT STD_LOGIC;
      Dbg_Update_1 : OUT STD_LOGIC;
      Dbg_Rst_1 : OUT STD_LOGIC;
      Dbg_Trig_In_1 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_1 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_1 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_1 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_1 : OUT STD_LOGIC;
      Dbg_TrData_1 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_1 : OUT STD_LOGIC;
      Dbg_TrValid_1 : IN STD_LOGIC;
      Dbg_Clk_2 : OUT STD_LOGIC;
      Dbg_TDI_2 : OUT STD_LOGIC;
      Dbg_TDO_2 : IN STD_LOGIC;
      Dbg_Reg_En_2 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_2 : OUT STD_LOGIC;
      Dbg_Shift_2 : OUT STD_LOGIC;
      Dbg_Update_2 : OUT STD_LOGIC;
      Dbg_Rst_2 : OUT STD_LOGIC;
      Dbg_Trig_In_2 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_2 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_2 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_2 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_2 : OUT STD_LOGIC;
      Dbg_TrData_2 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_2 : OUT STD_LOGIC;
      Dbg_TrValid_2 : IN STD_LOGIC;
      Dbg_Clk_3 : OUT STD_LOGIC;
      Dbg_TDI_3 : OUT STD_LOGIC;
      Dbg_TDO_3 : IN STD_LOGIC;
      Dbg_Reg_En_3 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_3 : OUT STD_LOGIC;
      Dbg_Shift_3 : OUT STD_LOGIC;
      Dbg_Update_3 : OUT STD_LOGIC;
      Dbg_Rst_3 : OUT STD_LOGIC;
      Dbg_Trig_In_3 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_3 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_3 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_3 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_3 : OUT STD_LOGIC;
      Dbg_TrData_3 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_3 : OUT STD_LOGIC;
      Dbg_TrValid_3 : IN STD_LOGIC;
      Dbg_Clk_4 : OUT STD_LOGIC;
      Dbg_TDI_4 : OUT STD_LOGIC;
      Dbg_TDO_4 : IN STD_LOGIC;
      Dbg_Reg_En_4 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_4 : OUT STD_LOGIC;
      Dbg_Shift_4 : OUT STD_LOGIC;
      Dbg_Update_4 : OUT STD_LOGIC;
      Dbg_Rst_4 : OUT STD_LOGIC;
      Dbg_Trig_In_4 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_4 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_4 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_4 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_4 : OUT STD_LOGIC;
      Dbg_TrData_4 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_4 : OUT STD_LOGIC;
      Dbg_TrValid_4 : IN STD_LOGIC;
      Dbg_Clk_5 : OUT STD_LOGIC;
      Dbg_TDI_5 : OUT STD_LOGIC;
      Dbg_TDO_5 : IN STD_LOGIC;
      Dbg_Reg_En_5 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_5 : OUT STD_LOGIC;
      Dbg_Shift_5 : OUT STD_LOGIC;
      Dbg_Update_5 : OUT STD_LOGIC;
      Dbg_Rst_5 : OUT STD_LOGIC;
      Dbg_Trig_In_5 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_5 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_5 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_5 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_5 : OUT STD_LOGIC;
      Dbg_TrData_5 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_5 : OUT STD_LOGIC;
      Dbg_TrValid_5 : IN STD_LOGIC;
      Dbg_Clk_6 : OUT STD_LOGIC;
      Dbg_TDI_6 : OUT STD_LOGIC;
      Dbg_TDO_6 : IN STD_LOGIC;
      Dbg_Reg_En_6 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_6 : OUT STD_LOGIC;
      Dbg_Shift_6 : OUT STD_LOGIC;
      Dbg_Update_6 : OUT STD_LOGIC;
      Dbg_Rst_6 : OUT STD_LOGIC;
      Dbg_Trig_In_6 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_6 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_6 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_6 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_6 : OUT STD_LOGIC;
      Dbg_TrData_6 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_6 : OUT STD_LOGIC;
      Dbg_TrValid_6 : IN STD_LOGIC;
      Dbg_Clk_7 : OUT STD_LOGIC;
      Dbg_TDI_7 : OUT STD_LOGIC;
      Dbg_TDO_7 : IN STD_LOGIC;
      Dbg_Reg_En_7 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_7 : OUT STD_LOGIC;
      Dbg_Shift_7 : OUT STD_LOGIC;
      Dbg_Update_7 : OUT STD_LOGIC;
      Dbg_Rst_7 : OUT STD_LOGIC;
      Dbg_Trig_In_7 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_7 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_7 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_7 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_7 : OUT STD_LOGIC;
      Dbg_TrData_7 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_7 : OUT STD_LOGIC;
      Dbg_TrValid_7 : IN STD_LOGIC;
      Dbg_Clk_8 : OUT STD_LOGIC;
      Dbg_TDI_8 : OUT STD_LOGIC;
      Dbg_TDO_8 : IN STD_LOGIC;
      Dbg_Reg_En_8 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_8 : OUT STD_LOGIC;
      Dbg_Shift_8 : OUT STD_LOGIC;
      Dbg_Update_8 : OUT STD_LOGIC;
      Dbg_Rst_8 : OUT STD_LOGIC;
      Dbg_Trig_In_8 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_8 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_8 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_8 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_8 : OUT STD_LOGIC;
      Dbg_TrData_8 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_8 : OUT STD_LOGIC;
      Dbg_TrValid_8 : IN STD_LOGIC;
      Dbg_Clk_9 : OUT STD_LOGIC;
      Dbg_TDI_9 : OUT STD_LOGIC;
      Dbg_TDO_9 : IN STD_LOGIC;
      Dbg_Reg_En_9 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_9 : OUT STD_LOGIC;
      Dbg_Shift_9 : OUT STD_LOGIC;
      Dbg_Update_9 : OUT STD_LOGIC;
      Dbg_Rst_9 : OUT STD_LOGIC;
      Dbg_Trig_In_9 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_9 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_9 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_9 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_9 : OUT STD_LOGIC;
      Dbg_TrData_9 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_9 : OUT STD_LOGIC;
      Dbg_TrValid_9 : IN STD_LOGIC;
      Dbg_Clk_10 : OUT STD_LOGIC;
      Dbg_TDI_10 : OUT STD_LOGIC;
      Dbg_TDO_10 : IN STD_LOGIC;
      Dbg_Reg_En_10 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_10 : OUT STD_LOGIC;
      Dbg_Shift_10 : OUT STD_LOGIC;
      Dbg_Update_10 : OUT STD_LOGIC;
      Dbg_Rst_10 : OUT STD_LOGIC;
      Dbg_Trig_In_10 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_10 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_10 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_10 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_10 : OUT STD_LOGIC;
      Dbg_TrData_10 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_10 : OUT STD_LOGIC;
      Dbg_TrValid_10 : IN STD_LOGIC;
      Dbg_Clk_11 : OUT STD_LOGIC;
      Dbg_TDI_11 : OUT STD_LOGIC;
      Dbg_TDO_11 : IN STD_LOGIC;
      Dbg_Reg_En_11 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_11 : OUT STD_LOGIC;
      Dbg_Shift_11 : OUT STD_LOGIC;
      Dbg_Update_11 : OUT STD_LOGIC;
      Dbg_Rst_11 : OUT STD_LOGIC;
      Dbg_Trig_In_11 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_11 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_11 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_11 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_11 : OUT STD_LOGIC;
      Dbg_TrData_11 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_11 : OUT STD_LOGIC;
      Dbg_TrValid_11 : IN STD_LOGIC;
      Dbg_Clk_12 : OUT STD_LOGIC;
      Dbg_TDI_12 : OUT STD_LOGIC;
      Dbg_TDO_12 : IN STD_LOGIC;
      Dbg_Reg_En_12 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_12 : OUT STD_LOGIC;
      Dbg_Shift_12 : OUT STD_LOGIC;
      Dbg_Update_12 : OUT STD_LOGIC;
      Dbg_Rst_12 : OUT STD_LOGIC;
      Dbg_Trig_In_12 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_12 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_12 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_12 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_12 : OUT STD_LOGIC;
      Dbg_TrData_12 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_12 : OUT STD_LOGIC;
      Dbg_TrValid_12 : IN STD_LOGIC;
      Dbg_Clk_13 : OUT STD_LOGIC;
      Dbg_TDI_13 : OUT STD_LOGIC;
      Dbg_TDO_13 : IN STD_LOGIC;
      Dbg_Reg_En_13 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_13 : OUT STD_LOGIC;
      Dbg_Shift_13 : OUT STD_LOGIC;
      Dbg_Update_13 : OUT STD_LOGIC;
      Dbg_Rst_13 : OUT STD_LOGIC;
      Dbg_Trig_In_13 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_13 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_13 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_13 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_13 : OUT STD_LOGIC;
      Dbg_TrData_13 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_13 : OUT STD_LOGIC;
      Dbg_TrValid_13 : IN STD_LOGIC;
      Dbg_Clk_14 : OUT STD_LOGIC;
      Dbg_TDI_14 : OUT STD_LOGIC;
      Dbg_TDO_14 : IN STD_LOGIC;
      Dbg_Reg_En_14 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_14 : OUT STD_LOGIC;
      Dbg_Shift_14 : OUT STD_LOGIC;
      Dbg_Update_14 : OUT STD_LOGIC;
      Dbg_Rst_14 : OUT STD_LOGIC;
      Dbg_Trig_In_14 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_14 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_14 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_14 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_14 : OUT STD_LOGIC;
      Dbg_TrData_14 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_14 : OUT STD_LOGIC;
      Dbg_TrValid_14 : IN STD_LOGIC;
      Dbg_Clk_15 : OUT STD_LOGIC;
      Dbg_TDI_15 : OUT STD_LOGIC;
      Dbg_TDO_15 : IN STD_LOGIC;
      Dbg_Reg_En_15 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_15 : OUT STD_LOGIC;
      Dbg_Shift_15 : OUT STD_LOGIC;
      Dbg_Update_15 : OUT STD_LOGIC;
      Dbg_Rst_15 : OUT STD_LOGIC;
      Dbg_Trig_In_15 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_15 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_15 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_15 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_15 : OUT STD_LOGIC;
      Dbg_TrData_15 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_15 : OUT STD_LOGIC;
      Dbg_TrValid_15 : IN STD_LOGIC;
      Dbg_Clk_16 : OUT STD_LOGIC;
      Dbg_TDI_16 : OUT STD_LOGIC;
      Dbg_TDO_16 : IN STD_LOGIC;
      Dbg_Reg_En_16 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_16 : OUT STD_LOGIC;
      Dbg_Shift_16 : OUT STD_LOGIC;
      Dbg_Update_16 : OUT STD_LOGIC;
      Dbg_Rst_16 : OUT STD_LOGIC;
      Dbg_Trig_In_16 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_16 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_16 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_16 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_16 : OUT STD_LOGIC;
      Dbg_TrData_16 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_16 : OUT STD_LOGIC;
      Dbg_TrValid_16 : IN STD_LOGIC;
      Dbg_Clk_17 : OUT STD_LOGIC;
      Dbg_TDI_17 : OUT STD_LOGIC;
      Dbg_TDO_17 : IN STD_LOGIC;
      Dbg_Reg_En_17 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_17 : OUT STD_LOGIC;
      Dbg_Shift_17 : OUT STD_LOGIC;
      Dbg_Update_17 : OUT STD_LOGIC;
      Dbg_Rst_17 : OUT STD_LOGIC;
      Dbg_Trig_In_17 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_17 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_17 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_17 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_17 : OUT STD_LOGIC;
      Dbg_TrData_17 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_17 : OUT STD_LOGIC;
      Dbg_TrValid_17 : IN STD_LOGIC;
      Dbg_Clk_18 : OUT STD_LOGIC;
      Dbg_TDI_18 : OUT STD_LOGIC;
      Dbg_TDO_18 : IN STD_LOGIC;
      Dbg_Reg_En_18 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_18 : OUT STD_LOGIC;
      Dbg_Shift_18 : OUT STD_LOGIC;
      Dbg_Update_18 : OUT STD_LOGIC;
      Dbg_Rst_18 : OUT STD_LOGIC;
      Dbg_Trig_In_18 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_18 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_18 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_18 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_18 : OUT STD_LOGIC;
      Dbg_TrData_18 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_18 : OUT STD_LOGIC;
      Dbg_TrValid_18 : IN STD_LOGIC;
      Dbg_Clk_19 : OUT STD_LOGIC;
      Dbg_TDI_19 : OUT STD_LOGIC;
      Dbg_TDO_19 : IN STD_LOGIC;
      Dbg_Reg_En_19 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_19 : OUT STD_LOGIC;
      Dbg_Shift_19 : OUT STD_LOGIC;
      Dbg_Update_19 : OUT STD_LOGIC;
      Dbg_Rst_19 : OUT STD_LOGIC;
      Dbg_Trig_In_19 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_19 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_19 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_19 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_19 : OUT STD_LOGIC;
      Dbg_TrData_19 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_19 : OUT STD_LOGIC;
      Dbg_TrValid_19 : IN STD_LOGIC;
      Dbg_Clk_20 : OUT STD_LOGIC;
      Dbg_TDI_20 : OUT STD_LOGIC;
      Dbg_TDO_20 : IN STD_LOGIC;
      Dbg_Reg_En_20 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_20 : OUT STD_LOGIC;
      Dbg_Shift_20 : OUT STD_LOGIC;
      Dbg_Update_20 : OUT STD_LOGIC;
      Dbg_Rst_20 : OUT STD_LOGIC;
      Dbg_Trig_In_20 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_20 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_20 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_20 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_20 : OUT STD_LOGIC;
      Dbg_TrData_20 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_20 : OUT STD_LOGIC;
      Dbg_TrValid_20 : IN STD_LOGIC;
      Dbg_Clk_21 : OUT STD_LOGIC;
      Dbg_TDI_21 : OUT STD_LOGIC;
      Dbg_TDO_21 : IN STD_LOGIC;
      Dbg_Reg_En_21 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_21 : OUT STD_LOGIC;
      Dbg_Shift_21 : OUT STD_LOGIC;
      Dbg_Update_21 : OUT STD_LOGIC;
      Dbg_Rst_21 : OUT STD_LOGIC;
      Dbg_Trig_In_21 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_21 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_21 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_21 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_21 : OUT STD_LOGIC;
      Dbg_TrData_21 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_21 : OUT STD_LOGIC;
      Dbg_TrValid_21 : IN STD_LOGIC;
      Dbg_Clk_22 : OUT STD_LOGIC;
      Dbg_TDI_22 : OUT STD_LOGIC;
      Dbg_TDO_22 : IN STD_LOGIC;
      Dbg_Reg_En_22 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_22 : OUT STD_LOGIC;
      Dbg_Shift_22 : OUT STD_LOGIC;
      Dbg_Update_22 : OUT STD_LOGIC;
      Dbg_Rst_22 : OUT STD_LOGIC;
      Dbg_Trig_In_22 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_22 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_22 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_22 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_22 : OUT STD_LOGIC;
      Dbg_TrData_22 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_22 : OUT STD_LOGIC;
      Dbg_TrValid_22 : IN STD_LOGIC;
      Dbg_Clk_23 : OUT STD_LOGIC;
      Dbg_TDI_23 : OUT STD_LOGIC;
      Dbg_TDO_23 : IN STD_LOGIC;
      Dbg_Reg_En_23 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_23 : OUT STD_LOGIC;
      Dbg_Shift_23 : OUT STD_LOGIC;
      Dbg_Update_23 : OUT STD_LOGIC;
      Dbg_Rst_23 : OUT STD_LOGIC;
      Dbg_Trig_In_23 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_23 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_23 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_23 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_23 : OUT STD_LOGIC;
      Dbg_TrData_23 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_23 : OUT STD_LOGIC;
      Dbg_TrValid_23 : IN STD_LOGIC;
      Dbg_Clk_24 : OUT STD_LOGIC;
      Dbg_TDI_24 : OUT STD_LOGIC;
      Dbg_TDO_24 : IN STD_LOGIC;
      Dbg_Reg_En_24 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_24 : OUT STD_LOGIC;
      Dbg_Shift_24 : OUT STD_LOGIC;
      Dbg_Update_24 : OUT STD_LOGIC;
      Dbg_Rst_24 : OUT STD_LOGIC;
      Dbg_Trig_In_24 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_24 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_24 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_24 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_24 : OUT STD_LOGIC;
      Dbg_TrData_24 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_24 : OUT STD_LOGIC;
      Dbg_TrValid_24 : IN STD_LOGIC;
      Dbg_Clk_25 : OUT STD_LOGIC;
      Dbg_TDI_25 : OUT STD_LOGIC;
      Dbg_TDO_25 : IN STD_LOGIC;
      Dbg_Reg_En_25 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_25 : OUT STD_LOGIC;
      Dbg_Shift_25 : OUT STD_LOGIC;
      Dbg_Update_25 : OUT STD_LOGIC;
      Dbg_Rst_25 : OUT STD_LOGIC;
      Dbg_Trig_In_25 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_25 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_25 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_25 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_25 : OUT STD_LOGIC;
      Dbg_TrData_25 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_25 : OUT STD_LOGIC;
      Dbg_TrValid_25 : IN STD_LOGIC;
      Dbg_Clk_26 : OUT STD_LOGIC;
      Dbg_TDI_26 : OUT STD_LOGIC;
      Dbg_TDO_26 : IN STD_LOGIC;
      Dbg_Reg_En_26 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_26 : OUT STD_LOGIC;
      Dbg_Shift_26 : OUT STD_LOGIC;
      Dbg_Update_26 : OUT STD_LOGIC;
      Dbg_Rst_26 : OUT STD_LOGIC;
      Dbg_Trig_In_26 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_26 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_26 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_26 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_26 : OUT STD_LOGIC;
      Dbg_TrData_26 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_26 : OUT STD_LOGIC;
      Dbg_TrValid_26 : IN STD_LOGIC;
      Dbg_Clk_27 : OUT STD_LOGIC;
      Dbg_TDI_27 : OUT STD_LOGIC;
      Dbg_TDO_27 : IN STD_LOGIC;
      Dbg_Reg_En_27 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_27 : OUT STD_LOGIC;
      Dbg_Shift_27 : OUT STD_LOGIC;
      Dbg_Update_27 : OUT STD_LOGIC;
      Dbg_Rst_27 : OUT STD_LOGIC;
      Dbg_Trig_In_27 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_27 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_27 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_27 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_27 : OUT STD_LOGIC;
      Dbg_TrData_27 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_27 : OUT STD_LOGIC;
      Dbg_TrValid_27 : IN STD_LOGIC;
      Dbg_Clk_28 : OUT STD_LOGIC;
      Dbg_TDI_28 : OUT STD_LOGIC;
      Dbg_TDO_28 : IN STD_LOGIC;
      Dbg_Reg_En_28 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_28 : OUT STD_LOGIC;
      Dbg_Shift_28 : OUT STD_LOGIC;
      Dbg_Update_28 : OUT STD_LOGIC;
      Dbg_Rst_28 : OUT STD_LOGIC;
      Dbg_Trig_In_28 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_28 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_28 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_28 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_28 : OUT STD_LOGIC;
      Dbg_TrData_28 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_28 : OUT STD_LOGIC;
      Dbg_TrValid_28 : IN STD_LOGIC;
      Dbg_Clk_29 : OUT STD_LOGIC;
      Dbg_TDI_29 : OUT STD_LOGIC;
      Dbg_TDO_29 : IN STD_LOGIC;
      Dbg_Reg_En_29 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_29 : OUT STD_LOGIC;
      Dbg_Shift_29 : OUT STD_LOGIC;
      Dbg_Update_29 : OUT STD_LOGIC;
      Dbg_Rst_29 : OUT STD_LOGIC;
      Dbg_Trig_In_29 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_29 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_29 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_29 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_29 : OUT STD_LOGIC;
      Dbg_TrData_29 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_29 : OUT STD_LOGIC;
      Dbg_TrValid_29 : IN STD_LOGIC;
      Dbg_Clk_30 : OUT STD_LOGIC;
      Dbg_TDI_30 : OUT STD_LOGIC;
      Dbg_TDO_30 : IN STD_LOGIC;
      Dbg_Reg_En_30 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_30 : OUT STD_LOGIC;
      Dbg_Shift_30 : OUT STD_LOGIC;
      Dbg_Update_30 : OUT STD_LOGIC;
      Dbg_Rst_30 : OUT STD_LOGIC;
      Dbg_Trig_In_30 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_30 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_30 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_30 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_30 : OUT STD_LOGIC;
      Dbg_TrData_30 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_30 : OUT STD_LOGIC;
      Dbg_TrValid_30 : IN STD_LOGIC;
      Dbg_Clk_31 : OUT STD_LOGIC;
      Dbg_TDI_31 : OUT STD_LOGIC;
      Dbg_TDO_31 : IN STD_LOGIC;
      Dbg_Reg_En_31 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Capture_31 : OUT STD_LOGIC;
      Dbg_Shift_31 : OUT STD_LOGIC;
      Dbg_Update_31 : OUT STD_LOGIC;
      Dbg_Rst_31 : OUT STD_LOGIC;
      Dbg_Trig_In_31 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_In_31 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Out_31 : OUT STD_LOGIC_VECTOR(0 TO 7);
      Dbg_Trig_Ack_Out_31 : IN STD_LOGIC_VECTOR(0 TO 7);
      Dbg_TrClk_31 : OUT STD_LOGIC;
      Dbg_TrData_31 : IN STD_LOGIC_VECTOR(0 TO 35);
      Dbg_TrReady_31 : OUT STD_LOGIC;
      Dbg_TrValid_31 : IN STD_LOGIC;
      bscan_ext_tdi : IN STD_LOGIC;
      bscan_ext_reset : IN STD_LOGIC;
      bscan_ext_shift : IN STD_LOGIC;
      bscan_ext_update : IN STD_LOGIC;
      bscan_ext_capture : IN STD_LOGIC;
      bscan_ext_sel : IN STD_LOGIC;
      bscan_ext_drck : IN STD_LOGIC;
      bscan_ext_tdo : OUT STD_LOGIC;
      Ext_JTAG_DRCK : OUT STD_LOGIC;
      Ext_JTAG_RESET : OUT STD_LOGIC;
      Ext_JTAG_SEL : OUT STD_LOGIC;
      Ext_JTAG_CAPTURE : OUT STD_LOGIC;
      Ext_JTAG_SHIFT : OUT STD_LOGIC;
      Ext_JTAG_UPDATE : OUT STD_LOGIC;
      Ext_JTAG_TDI : OUT STD_LOGIC;
      Ext_JTAG_TDO : IN STD_LOGIC
    );
  END COMPONENT MDM;
  ATTRIBUTE X_CORE_INFO : STRING;
  ATTRIBUTE X_CORE_INFO OF system_mdm_1_0_arch: ARCHITECTURE IS "MDM,Vivado 2015.3";
  ATTRIBUTE CHECK_LICENSE_TYPE : STRING;
  ATTRIBUTE CHECK_LICENSE_TYPE OF system_mdm_1_0_arch : ARCHITECTURE IS "system_mdm_1_0,MDM,{}";
  ATTRIBUTE CORE_GENERATION_INFO : STRING;
  ATTRIBUTE CORE_GENERATION_INFO OF system_mdm_1_0_arch: ARCHITECTURE IS "system_mdm_1_0,MDM,{x_ipProduct=Vivado 2015.3,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=mdm,x_ipVersion=3.2,x_ipCoreRevision=4,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_FAMILY=zynq,C_JTAG_CHAIN=2,C_USE_BSCAN=0,C_USE_CONFIG_RESET=0,C_INTERCONNECT=2,C_MB_DBG_PORTS=4,C_USE_UART=0,C_DBG_REG_ACCESS=0,C_DBG_MEM_ACCESS=0,C_USE_CROSS_TRIGGER=0,C_TRACE_OUTPUT=0,C_TRACE_DATA_WIDTH=32,C_TRACE_CLK_FREQ_HZ=200000000,C_TRACE_CLK_OUT_PHASE=90,C_S_AXI_ADDR_WIDTH=32,C_S_AXI_DATA_WIDTH=32,C_S_AXI_ACLK_FREQ_HZ=100000000,C_M_AXI_ADDR_WIDTH=32,C_M_AXI_DATA_WIDTH=32,C_M_AXI_THREAD_ID_WIDTH=1,C_DATA_SIZE=32,C_M_AXIS_DATA_WIDTH=32,C_M_AXIS_ID_WIDTH=7}";
  ATTRIBUTE X_INTERFACE_INFO : STRING;
  ATTRIBUTE X_INTERFACE_INFO OF Debug_SYS_Rst: SIGNAL IS "xilinx.com:signal:reset:1.0 RST.Debug_SYS_Rst RST";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Clk_0: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_0 CLK";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_TDI_0: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_0 TDI";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_TDO_0: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_0 TDO";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Reg_En_0: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_0 REG_EN";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Capture_0: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_0 CAPTURE";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Shift_0: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_0 SHIFT";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Update_0: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_0 UPDATE";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Rst_0: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_0 RST";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Clk_1: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_1 CLK";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_TDI_1: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_1 TDI";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_TDO_1: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_1 TDO";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Reg_En_1: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_1 REG_EN";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Capture_1: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_1 CAPTURE";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Shift_1: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_1 SHIFT";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Update_1: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_1 UPDATE";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Rst_1: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_1 RST";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Clk_2: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_2 CLK";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_TDI_2: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_2 TDI";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_TDO_2: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_2 TDO";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Reg_En_2: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_2 REG_EN";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Capture_2: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_2 CAPTURE";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Shift_2: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_2 SHIFT";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Update_2: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_2 UPDATE";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Rst_2: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_2 RST";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Clk_3: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_3 CLK";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_TDI_3: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_3 TDI";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_TDO_3: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_3 TDO";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Reg_En_3: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_3 REG_EN";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Capture_3: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_3 CAPTURE";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Shift_3: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_3 SHIFT";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Update_3: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_3 UPDATE";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_Rst_3: SIGNAL IS "xilinx.com:interface:mbdebug:3.0 MBDEBUG_3 RST";
BEGIN
  U0 : MDM
    GENERIC MAP (
      C_FAMILY => "zynq",
      C_JTAG_CHAIN => 2,
      C_USE_BSCAN => 0,
      C_USE_CONFIG_RESET => 0,
      C_INTERCONNECT => 2,
      C_MB_DBG_PORTS => 4,
      C_USE_UART => 0,
      C_DBG_REG_ACCESS => 0,
      C_DBG_MEM_ACCESS => 0,
      C_USE_CROSS_TRIGGER => 0,
      C_TRACE_OUTPUT => 0,
      C_TRACE_DATA_WIDTH => 32,
      C_TRACE_CLK_FREQ_HZ => 200000000,
      C_TRACE_CLK_OUT_PHASE => 90,
      C_S_AXI_ADDR_WIDTH => 32,
      C_S_AXI_DATA_WIDTH => 32,
      C_S_AXI_ACLK_FREQ_HZ => 100000000,
      C_M_AXI_ADDR_WIDTH => 32,
      C_M_AXI_DATA_WIDTH => 32,
      C_M_AXI_THREAD_ID_WIDTH => 1,
      C_DATA_SIZE => 32,
      C_M_AXIS_DATA_WIDTH => 32,
      C_M_AXIS_ID_WIDTH => 7
    )
    PORT MAP (
      Config_Reset => '0',
      Scan_Reset => '0',
      Scan_Reset_Sel => '0',
      S_AXI_ACLK => '0',
      S_AXI_ARESETN => '0',
      M_AXI_ACLK => '0',
      M_AXI_ARESETN => '0',
      M_AXIS_ACLK => '0',
      M_AXIS_ARESETN => '0',
      Debug_SYS_Rst => Debug_SYS_Rst,
      Trig_In_0 => '0',
      Trig_Ack_Out_0 => '0',
      Trig_In_1 => '0',
      Trig_Ack_Out_1 => '0',
      Trig_In_2 => '0',
      Trig_Ack_Out_2 => '0',
      Trig_In_3 => '0',
      Trig_Ack_Out_3 => '0',
      S_AXI_AWADDR => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      S_AXI_AWVALID => '0',
      S_AXI_WDATA => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      S_AXI_WSTRB => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 4)),
      S_AXI_WVALID => '0',
      S_AXI_BREADY => '0',
      S_AXI_ARADDR => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      S_AXI_ARVALID => '0',
      S_AXI_RREADY => '0',
      M_AXI_AWREADY => '0',
      M_AXI_WREADY => '0',
      M_AXI_BRESP => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 2)),
      M_AXI_BID => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 1)),
      M_AXI_BVALID => '0',
      M_AXI_ARREADY => '0',
      M_AXI_RID => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 1)),
      M_AXI_RDATA => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      M_AXI_RRESP => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 2)),
      M_AXI_RLAST => '0',
      M_AXI_RVALID => '0',
      LMB_Ready_0 => '0',
      LMB_Data_Read_0 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_0 => '0',
      LMB_UE_0 => '0',
      LMB_Wait_0 => '0',
      LMB_Ready_1 => '0',
      LMB_Data_Read_1 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_1 => '0',
      LMB_UE_1 => '0',
      LMB_Wait_1 => '0',
      LMB_Ready_2 => '0',
      LMB_Data_Read_2 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_2 => '0',
      LMB_UE_2 => '0',
      LMB_Wait_2 => '0',
      LMB_Ready_3 => '0',
      LMB_Data_Read_3 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_3 => '0',
      LMB_UE_3 => '0',
      LMB_Wait_3 => '0',
      LMB_Ready_4 => '0',
      LMB_Data_Read_4 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_4 => '0',
      LMB_UE_4 => '0',
      LMB_Wait_4 => '0',
      LMB_Ready_5 => '0',
      LMB_Data_Read_5 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_5 => '0',
      LMB_UE_5 => '0',
      LMB_Wait_5 => '0',
      LMB_Ready_6 => '0',
      LMB_Data_Read_6 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_6 => '0',
      LMB_UE_6 => '0',
      LMB_Wait_6 => '0',
      LMB_Ready_7 => '0',
      LMB_Data_Read_7 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_7 => '0',
      LMB_UE_7 => '0',
      LMB_Wait_7 => '0',
      LMB_Ready_8 => '0',
      LMB_Data_Read_8 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_8 => '0',
      LMB_UE_8 => '0',
      LMB_Wait_8 => '0',
      LMB_Ready_9 => '0',
      LMB_Data_Read_9 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_9 => '0',
      LMB_UE_9 => '0',
      LMB_Wait_9 => '0',
      LMB_Ready_10 => '0',
      LMB_Data_Read_10 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_10 => '0',
      LMB_UE_10 => '0',
      LMB_Wait_10 => '0',
      LMB_Ready_11 => '0',
      LMB_Data_Read_11 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_11 => '0',
      LMB_UE_11 => '0',
      LMB_Wait_11 => '0',
      LMB_Ready_12 => '0',
      LMB_Data_Read_12 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_12 => '0',
      LMB_UE_12 => '0',
      LMB_Wait_12 => '0',
      LMB_Ready_13 => '0',
      LMB_Data_Read_13 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_13 => '0',
      LMB_UE_13 => '0',
      LMB_Wait_13 => '0',
      LMB_Ready_14 => '0',
      LMB_Data_Read_14 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_14 => '0',
      LMB_UE_14 => '0',
      LMB_Wait_14 => '0',
      LMB_Ready_15 => '0',
      LMB_Data_Read_15 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_15 => '0',
      LMB_UE_15 => '0',
      LMB_Wait_15 => '0',
      LMB_Ready_16 => '0',
      LMB_Data_Read_16 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_16 => '0',
      LMB_UE_16 => '0',
      LMB_Wait_16 => '0',
      LMB_Ready_17 => '0',
      LMB_Data_Read_17 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_17 => '0',
      LMB_UE_17 => '0',
      LMB_Wait_17 => '0',
      LMB_Ready_18 => '0',
      LMB_Data_Read_18 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_18 => '0',
      LMB_UE_18 => '0',
      LMB_Wait_18 => '0',
      LMB_Ready_19 => '0',
      LMB_Data_Read_19 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_19 => '0',
      LMB_UE_19 => '0',
      LMB_Wait_19 => '0',
      LMB_Ready_20 => '0',
      LMB_Data_Read_20 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_20 => '0',
      LMB_UE_20 => '0',
      LMB_Wait_20 => '0',
      LMB_Ready_21 => '0',
      LMB_Data_Read_21 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_21 => '0',
      LMB_UE_21 => '0',
      LMB_Wait_21 => '0',
      LMB_Ready_22 => '0',
      LMB_Data_Read_22 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_22 => '0',
      LMB_UE_22 => '0',
      LMB_Wait_22 => '0',
      LMB_Ready_23 => '0',
      LMB_Data_Read_23 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_23 => '0',
      LMB_UE_23 => '0',
      LMB_Wait_23 => '0',
      LMB_Ready_24 => '0',
      LMB_Data_Read_24 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_24 => '0',
      LMB_UE_24 => '0',
      LMB_Wait_24 => '0',
      LMB_Ready_25 => '0',
      LMB_Data_Read_25 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_25 => '0',
      LMB_UE_25 => '0',
      LMB_Wait_25 => '0',
      LMB_Ready_26 => '0',
      LMB_Data_Read_26 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_26 => '0',
      LMB_UE_26 => '0',
      LMB_Wait_26 => '0',
      LMB_Ready_27 => '0',
      LMB_Data_Read_27 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_27 => '0',
      LMB_UE_27 => '0',
      LMB_Wait_27 => '0',
      LMB_Ready_28 => '0',
      LMB_Data_Read_28 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_28 => '0',
      LMB_UE_28 => '0',
      LMB_Wait_28 => '0',
      LMB_Ready_29 => '0',
      LMB_Data_Read_29 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_29 => '0',
      LMB_UE_29 => '0',
      LMB_Wait_29 => '0',
      LMB_Ready_30 => '0',
      LMB_Data_Read_30 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_30 => '0',
      LMB_UE_30 => '0',
      LMB_Wait_30 => '0',
      LMB_Ready_31 => '0',
      LMB_Data_Read_31 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB_CE_31 => '0',
      LMB_UE_31 => '0',
      LMB_Wait_31 => '0',
      M_AXIS_TREADY => '1',
      TRACE_CLK => '0',
      Dbg_Clk_0 => Dbg_Clk_0,
      Dbg_TDI_0 => Dbg_TDI_0,
      Dbg_TDO_0 => Dbg_TDO_0,
      Dbg_Reg_En_0 => Dbg_Reg_En_0,
      Dbg_Capture_0 => Dbg_Capture_0,
      Dbg_Shift_0 => Dbg_Shift_0,
      Dbg_Update_0 => Dbg_Update_0,
      Dbg_Rst_0 => Dbg_Rst_0,
      Dbg_Trig_In_0 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_0 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_0 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_0 => '0',
      Dbg_Clk_1 => Dbg_Clk_1,
      Dbg_TDI_1 => Dbg_TDI_1,
      Dbg_TDO_1 => Dbg_TDO_1,
      Dbg_Reg_En_1 => Dbg_Reg_En_1,
      Dbg_Capture_1 => Dbg_Capture_1,
      Dbg_Shift_1 => Dbg_Shift_1,
      Dbg_Update_1 => Dbg_Update_1,
      Dbg_Rst_1 => Dbg_Rst_1,
      Dbg_Trig_In_1 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_1 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_1 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_1 => '0',
      Dbg_Clk_2 => Dbg_Clk_2,
      Dbg_TDI_2 => Dbg_TDI_2,
      Dbg_TDO_2 => Dbg_TDO_2,
      Dbg_Reg_En_2 => Dbg_Reg_En_2,
      Dbg_Capture_2 => Dbg_Capture_2,
      Dbg_Shift_2 => Dbg_Shift_2,
      Dbg_Update_2 => Dbg_Update_2,
      Dbg_Rst_2 => Dbg_Rst_2,
      Dbg_Trig_In_2 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_2 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_2 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_2 => '0',
      Dbg_Clk_3 => Dbg_Clk_3,
      Dbg_TDI_3 => Dbg_TDI_3,
      Dbg_TDO_3 => Dbg_TDO_3,
      Dbg_Reg_En_3 => Dbg_Reg_En_3,
      Dbg_Capture_3 => Dbg_Capture_3,
      Dbg_Shift_3 => Dbg_Shift_3,
      Dbg_Update_3 => Dbg_Update_3,
      Dbg_Rst_3 => Dbg_Rst_3,
      Dbg_Trig_In_3 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_3 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_3 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_3 => '0',
      Dbg_TDO_4 => '0',
      Dbg_Trig_In_4 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_4 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_4 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_4 => '0',
      Dbg_TDO_5 => '0',
      Dbg_Trig_In_5 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_5 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_5 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_5 => '0',
      Dbg_TDO_6 => '0',
      Dbg_Trig_In_6 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_6 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_6 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_6 => '0',
      Dbg_TDO_7 => '0',
      Dbg_Trig_In_7 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_7 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_7 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_7 => '0',
      Dbg_TDO_8 => '0',
      Dbg_Trig_In_8 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_8 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_8 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_8 => '0',
      Dbg_TDO_9 => '0',
      Dbg_Trig_In_9 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_9 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_9 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_9 => '0',
      Dbg_TDO_10 => '0',
      Dbg_Trig_In_10 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_10 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_10 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_10 => '0',
      Dbg_TDO_11 => '0',
      Dbg_Trig_In_11 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_11 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_11 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_11 => '0',
      Dbg_TDO_12 => '0',
      Dbg_Trig_In_12 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_12 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_12 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_12 => '0',
      Dbg_TDO_13 => '0',
      Dbg_Trig_In_13 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_13 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_13 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_13 => '0',
      Dbg_TDO_14 => '0',
      Dbg_Trig_In_14 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_14 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_14 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_14 => '0',
      Dbg_TDO_15 => '0',
      Dbg_Trig_In_15 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_15 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_15 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_15 => '0',
      Dbg_TDO_16 => '0',
      Dbg_Trig_In_16 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_16 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_16 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_16 => '0',
      Dbg_TDO_17 => '0',
      Dbg_Trig_In_17 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_17 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_17 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_17 => '0',
      Dbg_TDO_18 => '0',
      Dbg_Trig_In_18 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_18 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_18 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_18 => '0',
      Dbg_TDO_19 => '0',
      Dbg_Trig_In_19 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_19 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_19 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_19 => '0',
      Dbg_TDO_20 => '0',
      Dbg_Trig_In_20 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_20 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_20 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_20 => '0',
      Dbg_TDO_21 => '0',
      Dbg_Trig_In_21 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_21 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_21 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_21 => '0',
      Dbg_TDO_22 => '0',
      Dbg_Trig_In_22 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_22 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_22 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_22 => '0',
      Dbg_TDO_23 => '0',
      Dbg_Trig_In_23 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_23 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_23 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_23 => '0',
      Dbg_TDO_24 => '0',
      Dbg_Trig_In_24 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_24 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_24 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_24 => '0',
      Dbg_TDO_25 => '0',
      Dbg_Trig_In_25 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_25 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_25 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_25 => '0',
      Dbg_TDO_26 => '0',
      Dbg_Trig_In_26 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_26 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_26 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_26 => '0',
      Dbg_TDO_27 => '0',
      Dbg_Trig_In_27 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_27 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_27 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_27 => '0',
      Dbg_TDO_28 => '0',
      Dbg_Trig_In_28 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_28 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_28 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_28 => '0',
      Dbg_TDO_29 => '0',
      Dbg_Trig_In_29 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_29 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_29 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_29 => '0',
      Dbg_TDO_30 => '0',
      Dbg_Trig_In_30 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_30 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_30 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_30 => '0',
      Dbg_TDO_31 => '0',
      Dbg_Trig_In_31 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_Trig_Ack_Out_31 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 8)),
      Dbg_TrData_31 => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 36)),
      Dbg_TrValid_31 => '0',
      bscan_ext_tdi => '0',
      bscan_ext_reset => '0',
      bscan_ext_shift => '0',
      bscan_ext_update => '0',
      bscan_ext_capture => '0',
      bscan_ext_sel => '0',
      bscan_ext_drck => '0',
      Ext_JTAG_TDO => '0'
    );
END system_mdm_1_0_arch;
