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

-- IP VLNV: xilinx.com:ip:processing_system7:5.5
-- IP Revision: 3

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT system_processing_system7_0_0
  PORT (
    GPIO_I : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    GPIO_O : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    GPIO_T : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    SDIO0_WP : IN STD_LOGIC;
    M_AXI_GP0_ARVALID : OUT STD_LOGIC;
    M_AXI_GP0_AWVALID : OUT STD_LOGIC;
    M_AXI_GP0_BREADY : OUT STD_LOGIC;
    M_AXI_GP0_RREADY : OUT STD_LOGIC;
    M_AXI_GP0_WLAST : OUT STD_LOGIC;
    M_AXI_GP0_WVALID : OUT STD_LOGIC;
    M_AXI_GP0_ARID : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
    M_AXI_GP0_AWID : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
    M_AXI_GP0_WID : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
    M_AXI_GP0_ARBURST : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_GP0_ARLOCK : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_GP0_ARSIZE : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_GP0_AWBURST : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_GP0_AWLOCK : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_GP0_AWSIZE : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_GP0_ARPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_GP0_AWPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_GP0_ARADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_GP0_AWADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_GP0_WDATA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_GP0_ARCACHE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M_AXI_GP0_ARLEN : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M_AXI_GP0_ARQOS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M_AXI_GP0_AWCACHE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M_AXI_GP0_AWLEN : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M_AXI_GP0_AWQOS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M_AXI_GP0_WSTRB : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M_AXI_GP0_ACLK : IN STD_LOGIC;
    M_AXI_GP0_ARREADY : IN STD_LOGIC;
    M_AXI_GP0_AWREADY : IN STD_LOGIC;
    M_AXI_GP0_BVALID : IN STD_LOGIC;
    M_AXI_GP0_RLAST : IN STD_LOGIC;
    M_AXI_GP0_RVALID : IN STD_LOGIC;
    M_AXI_GP0_WREADY : IN STD_LOGIC;
    M_AXI_GP0_BID : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    M_AXI_GP0_RID : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    M_AXI_GP0_BRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_GP0_RRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_GP0_RDATA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    FCLK_CLK0 : OUT STD_LOGIC;
    FCLK_RESET0_N : OUT STD_LOGIC;
    MIO : INOUT STD_LOGIC_VECTOR(53 DOWNTO 0);
    DDR_CAS_n : INOUT STD_LOGIC;
    DDR_CKE : INOUT STD_LOGIC;
    DDR_Clk_n : INOUT STD_LOGIC;
    DDR_Clk : INOUT STD_LOGIC;
    DDR_CS_n : INOUT STD_LOGIC;
    DDR_DRSTB : INOUT STD_LOGIC;
    DDR_ODT : INOUT STD_LOGIC;
    DDR_RAS_n : INOUT STD_LOGIC;
    DDR_WEB : INOUT STD_LOGIC;
    DDR_BankAddr : INOUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    DDR_Addr : INOUT STD_LOGIC_VECTOR(14 DOWNTO 0);
    DDR_VRN : INOUT STD_LOGIC;
    DDR_VRP : INOUT STD_LOGIC;
    DDR_DM : INOUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    DDR_DQ : INOUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    DDR_DQS_n : INOUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    DDR_DQS : INOUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    PS_SRSTB : INOUT STD_LOGIC;
    PS_CLK : INOUT STD_LOGIC;
    PS_PORB : INOUT STD_LOGIC
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : system_processing_system7_0_0
  PORT MAP (
    GPIO_I => GPIO_I,
    GPIO_O => GPIO_O,
    GPIO_T => GPIO_T,
    SDIO0_WP => SDIO0_WP,
    M_AXI_GP0_ARVALID => M_AXI_GP0_ARVALID,
    M_AXI_GP0_AWVALID => M_AXI_GP0_AWVALID,
    M_AXI_GP0_BREADY => M_AXI_GP0_BREADY,
    M_AXI_GP0_RREADY => M_AXI_GP0_RREADY,
    M_AXI_GP0_WLAST => M_AXI_GP0_WLAST,
    M_AXI_GP0_WVALID => M_AXI_GP0_WVALID,
    M_AXI_GP0_ARID => M_AXI_GP0_ARID,
    M_AXI_GP0_AWID => M_AXI_GP0_AWID,
    M_AXI_GP0_WID => M_AXI_GP0_WID,
    M_AXI_GP0_ARBURST => M_AXI_GP0_ARBURST,
    M_AXI_GP0_ARLOCK => M_AXI_GP0_ARLOCK,
    M_AXI_GP0_ARSIZE => M_AXI_GP0_ARSIZE,
    M_AXI_GP0_AWBURST => M_AXI_GP0_AWBURST,
    M_AXI_GP0_AWLOCK => M_AXI_GP0_AWLOCK,
    M_AXI_GP0_AWSIZE => M_AXI_GP0_AWSIZE,
    M_AXI_GP0_ARPROT => M_AXI_GP0_ARPROT,
    M_AXI_GP0_AWPROT => M_AXI_GP0_AWPROT,
    M_AXI_GP0_ARADDR => M_AXI_GP0_ARADDR,
    M_AXI_GP0_AWADDR => M_AXI_GP0_AWADDR,
    M_AXI_GP0_WDATA => M_AXI_GP0_WDATA,
    M_AXI_GP0_ARCACHE => M_AXI_GP0_ARCACHE,
    M_AXI_GP0_ARLEN => M_AXI_GP0_ARLEN,
    M_AXI_GP0_ARQOS => M_AXI_GP0_ARQOS,
    M_AXI_GP0_AWCACHE => M_AXI_GP0_AWCACHE,
    M_AXI_GP0_AWLEN => M_AXI_GP0_AWLEN,
    M_AXI_GP0_AWQOS => M_AXI_GP0_AWQOS,
    M_AXI_GP0_WSTRB => M_AXI_GP0_WSTRB,
    M_AXI_GP0_ACLK => M_AXI_GP0_ACLK,
    M_AXI_GP0_ARREADY => M_AXI_GP0_ARREADY,
    M_AXI_GP0_AWREADY => M_AXI_GP0_AWREADY,
    M_AXI_GP0_BVALID => M_AXI_GP0_BVALID,
    M_AXI_GP0_RLAST => M_AXI_GP0_RLAST,
    M_AXI_GP0_RVALID => M_AXI_GP0_RVALID,
    M_AXI_GP0_WREADY => M_AXI_GP0_WREADY,
    M_AXI_GP0_BID => M_AXI_GP0_BID,
    M_AXI_GP0_RID => M_AXI_GP0_RID,
    M_AXI_GP0_BRESP => M_AXI_GP0_BRESP,
    M_AXI_GP0_RRESP => M_AXI_GP0_RRESP,
    M_AXI_GP0_RDATA => M_AXI_GP0_RDATA,
    FCLK_CLK0 => FCLK_CLK0,
    FCLK_RESET0_N => FCLK_RESET0_N,
    MIO => MIO,
    DDR_CAS_n => DDR_CAS_n,
    DDR_CKE => DDR_CKE,
    DDR_Clk_n => DDR_Clk_n,
    DDR_Clk => DDR_Clk,
    DDR_CS_n => DDR_CS_n,
    DDR_DRSTB => DDR_DRSTB,
    DDR_ODT => DDR_ODT,
    DDR_RAS_n => DDR_RAS_n,
    DDR_WEB => DDR_WEB,
    DDR_BankAddr => DDR_BankAddr,
    DDR_Addr => DDR_Addr,
    DDR_VRN => DDR_VRN,
    DDR_VRP => DDR_VRP,
    DDR_DM => DDR_DM,
    DDR_DQ => DDR_DQ,
    DDR_DQS_n => DDR_DQS_n,
    DDR_DQS => DDR_DQS,
    PS_SRSTB => PS_SRSTB,
    PS_CLK => PS_CLK,
    PS_PORB => PS_PORB
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

-- You must compile the wrapper file system_processing_system7_0_0.vhd when simulating
-- the core, system_processing_system7_0_0. When compiling the wrapper file, be sure to
-- reference the VHDL simulation library.

