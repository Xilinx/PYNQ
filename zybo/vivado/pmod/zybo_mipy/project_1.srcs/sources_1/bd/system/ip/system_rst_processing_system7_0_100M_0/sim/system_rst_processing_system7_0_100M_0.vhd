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

-- IP VLNV: xilinx.com:ip:proc_sys_reset:5.0
-- IP Revision: 8

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY proc_sys_reset_v5_0_8;
USE proc_sys_reset_v5_0_8.proc_sys_reset;

ENTITY system_rst_processing_system7_0_100M_0 IS
  PORT (
    slowest_sync_clk : IN STD_LOGIC;
    ext_reset_in : IN STD_LOGIC;
    aux_reset_in : IN STD_LOGIC;
    mb_debug_sys_rst : IN STD_LOGIC;
    dcm_locked : IN STD_LOGIC;
    mb_reset : OUT STD_LOGIC;
    bus_struct_reset : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    peripheral_reset : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    interconnect_aresetn : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    peripheral_aresetn : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END system_rst_processing_system7_0_100M_0;

ARCHITECTURE system_rst_processing_system7_0_100M_0_arch OF system_rst_processing_system7_0_100M_0 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : string;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF system_rst_processing_system7_0_100M_0_arch: ARCHITECTURE IS "yes";

  COMPONENT proc_sys_reset IS
    GENERIC (
      C_FAMILY : STRING;
      C_EXT_RST_WIDTH : INTEGER;
      C_AUX_RST_WIDTH : INTEGER;
      C_EXT_RESET_HIGH : STD_LOGIC;
      C_AUX_RESET_HIGH : STD_LOGIC;
      C_NUM_BUS_RST : INTEGER;
      C_NUM_PERP_RST : INTEGER;
      C_NUM_INTERCONNECT_ARESETN : INTEGER;
      C_NUM_PERP_ARESETN : INTEGER
    );
    PORT (
      slowest_sync_clk : IN STD_LOGIC;
      ext_reset_in : IN STD_LOGIC;
      aux_reset_in : IN STD_LOGIC;
      mb_debug_sys_rst : IN STD_LOGIC;
      dcm_locked : IN STD_LOGIC;
      mb_reset : OUT STD_LOGIC;
      bus_struct_reset : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      peripheral_reset : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      interconnect_aresetn : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      peripheral_aresetn : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
  END COMPONENT proc_sys_reset;
  ATTRIBUTE X_INTERFACE_INFO : STRING;
  ATTRIBUTE X_INTERFACE_INFO OF slowest_sync_clk: SIGNAL IS "xilinx.com:signal:clock:1.0 clock CLK";
  ATTRIBUTE X_INTERFACE_INFO OF ext_reset_in: SIGNAL IS "xilinx.com:signal:reset:1.0 ext_reset RST";
  ATTRIBUTE X_INTERFACE_INFO OF aux_reset_in: SIGNAL IS "xilinx.com:signal:reset:1.0 aux_reset RST";
  ATTRIBUTE X_INTERFACE_INFO OF mb_debug_sys_rst: SIGNAL IS "xilinx.com:signal:reset:1.0 dbg_reset RST";
  ATTRIBUTE X_INTERFACE_INFO OF mb_reset: SIGNAL IS "xilinx.com:signal:reset:1.0 mb_rst RST";
  ATTRIBUTE X_INTERFACE_INFO OF bus_struct_reset: SIGNAL IS "xilinx.com:signal:reset:1.0 bus_struct_reset RST";
  ATTRIBUTE X_INTERFACE_INFO OF peripheral_reset: SIGNAL IS "xilinx.com:signal:reset:1.0 peripheral_high_rst RST";
  ATTRIBUTE X_INTERFACE_INFO OF interconnect_aresetn: SIGNAL IS "xilinx.com:signal:reset:1.0 interconnect_low_rst RST";
  ATTRIBUTE X_INTERFACE_INFO OF peripheral_aresetn: SIGNAL IS "xilinx.com:signal:reset:1.0 peripheral_low_rst RST";
BEGIN
  U0 : proc_sys_reset
    GENERIC MAP (
      C_FAMILY => "zynq",
      C_EXT_RST_WIDTH => 4,
      C_AUX_RST_WIDTH => 4,
      C_EXT_RESET_HIGH => '0',
      C_AUX_RESET_HIGH => '0',
      C_NUM_BUS_RST => 1,
      C_NUM_PERP_RST => 1,
      C_NUM_INTERCONNECT_ARESETN => 1,
      C_NUM_PERP_ARESETN => 1
    )
    PORT MAP (
      slowest_sync_clk => slowest_sync_clk,
      ext_reset_in => ext_reset_in,
      aux_reset_in => aux_reset_in,
      mb_debug_sys_rst => mb_debug_sys_rst,
      dcm_locked => dcm_locked,
      mb_reset => mb_reset,
      bus_struct_reset => bus_struct_reset,
      peripheral_reset => peripheral_reset,
      interconnect_aresetn => interconnect_aresetn,
      peripheral_aresetn => peripheral_aresetn
    );
END system_rst_processing_system7_0_100M_0_arch;
