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

-- IP VLNV: xilinx.com:ip:lmb_v10:3.0
-- IP Revision: 7

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT system_dlmb_v10_1
  PORT (
    LMB_Clk : IN STD_LOGIC;
    SYS_Rst : IN STD_LOGIC;
    LMB_Rst : OUT STD_LOGIC;
    M_ABus : IN STD_LOGIC_VECTOR(0 TO 31);
    M_ReadStrobe : IN STD_LOGIC;
    M_WriteStrobe : IN STD_LOGIC;
    M_AddrStrobe : IN STD_LOGIC;
    M_DBus : IN STD_LOGIC_VECTOR(0 TO 31);
    M_BE : IN STD_LOGIC_VECTOR(0 TO 3);
    Sl_DBus : IN STD_LOGIC_VECTOR(0 TO 31);
    Sl_Ready : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    Sl_Wait : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    Sl_UE : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    Sl_CE : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    LMB_ABus : OUT STD_LOGIC_VECTOR(0 TO 31);
    LMB_ReadStrobe : OUT STD_LOGIC;
    LMB_WriteStrobe : OUT STD_LOGIC;
    LMB_AddrStrobe : OUT STD_LOGIC;
    LMB_ReadDBus : OUT STD_LOGIC_VECTOR(0 TO 31);
    LMB_WriteDBus : OUT STD_LOGIC_VECTOR(0 TO 31);
    LMB_Ready : OUT STD_LOGIC;
    LMB_Wait : OUT STD_LOGIC;
    LMB_UE : OUT STD_LOGIC;
    LMB_CE : OUT STD_LOGIC;
    LMB_BE : OUT STD_LOGIC_VECTOR(0 TO 3)
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : system_dlmb_v10_1
  PORT MAP (
    LMB_Clk => LMB_Clk,
    SYS_Rst => SYS_Rst,
    LMB_Rst => LMB_Rst,
    M_ABus => M_ABus,
    M_ReadStrobe => M_ReadStrobe,
    M_WriteStrobe => M_WriteStrobe,
    M_AddrStrobe => M_AddrStrobe,
    M_DBus => M_DBus,
    M_BE => M_BE,
    Sl_DBus => Sl_DBus,
    Sl_Ready => Sl_Ready,
    Sl_Wait => Sl_Wait,
    Sl_UE => Sl_UE,
    Sl_CE => Sl_CE,
    LMB_ABus => LMB_ABus,
    LMB_ReadStrobe => LMB_ReadStrobe,
    LMB_WriteStrobe => LMB_WriteStrobe,
    LMB_AddrStrobe => LMB_AddrStrobe,
    LMB_ReadDBus => LMB_ReadDBus,
    LMB_WriteDBus => LMB_WriteDBus,
    LMB_Ready => LMB_Ready,
    LMB_Wait => LMB_Wait,
    LMB_UE => LMB_UE,
    LMB_CE => LMB_CE,
    LMB_BE => LMB_BE
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

-- You must compile the wrapper file system_dlmb_v10_1.vhd when simulating
-- the core, system_dlmb_v10_1. When compiling the wrapper file, be sure to
-- reference the VHDL simulation library.

