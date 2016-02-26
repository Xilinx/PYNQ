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

-- IP VLNV: xilinx.com:ip:microblaze:9.5
-- IP Revision: 2

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT system_mb_3_0
  PORT (
    Clk : IN STD_LOGIC;
    Reset : IN STD_LOGIC;
    Interrupt : IN STD_LOGIC;
    Interrupt_Address : IN STD_LOGIC_VECTOR(0 TO 31);
    Interrupt_Ack : OUT STD_LOGIC_VECTOR(0 TO 1);
    Instr_Addr : OUT STD_LOGIC_VECTOR(0 TO 31);
    Instr : IN STD_LOGIC_VECTOR(0 TO 31);
    IFetch : OUT STD_LOGIC;
    I_AS : OUT STD_LOGIC;
    IReady : IN STD_LOGIC;
    IWAIT : IN STD_LOGIC;
    ICE : IN STD_LOGIC;
    IUE : IN STD_LOGIC;
    Data_Addr : OUT STD_LOGIC_VECTOR(0 TO 31);
    Data_Read : IN STD_LOGIC_VECTOR(0 TO 31);
    Data_Write : OUT STD_LOGIC_VECTOR(0 TO 31);
    D_AS : OUT STD_LOGIC;
    Read_Strobe : OUT STD_LOGIC;
    Write_Strobe : OUT STD_LOGIC;
    DReady : IN STD_LOGIC;
    DWait : IN STD_LOGIC;
    DCE : IN STD_LOGIC;
    DUE : IN STD_LOGIC;
    Byte_Enable : OUT STD_LOGIC_VECTOR(0 TO 3);
    M_AXI_DP_AWADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_DP_AWPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_DP_AWVALID : OUT STD_LOGIC;
    M_AXI_DP_AWREADY : IN STD_LOGIC;
    M_AXI_DP_WDATA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_DP_WSTRB : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M_AXI_DP_WVALID : OUT STD_LOGIC;
    M_AXI_DP_WREADY : IN STD_LOGIC;
    M_AXI_DP_BRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_DP_BVALID : IN STD_LOGIC;
    M_AXI_DP_BREADY : OUT STD_LOGIC;
    M_AXI_DP_ARADDR : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_DP_ARPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_DP_ARVALID : OUT STD_LOGIC;
    M_AXI_DP_ARREADY : IN STD_LOGIC;
    M_AXI_DP_RDATA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    M_AXI_DP_RRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_DP_RVALID : IN STD_LOGIC;
    M_AXI_DP_RREADY : OUT STD_LOGIC;
    Dbg_Clk : IN STD_LOGIC;
    Dbg_TDI : IN STD_LOGIC;
    Dbg_TDO : OUT STD_LOGIC;
    Dbg_Reg_En : IN STD_LOGIC_VECTOR(0 TO 7);
    Dbg_Shift : IN STD_LOGIC;
    Dbg_Capture : IN STD_LOGIC;
    Dbg_Update : IN STD_LOGIC;
    Debug_Rst : IN STD_LOGIC
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : system_mb_3_0
  PORT MAP (
    Clk => Clk,
    Reset => Reset,
    Interrupt => Interrupt,
    Interrupt_Address => Interrupt_Address,
    Interrupt_Ack => Interrupt_Ack,
    Instr_Addr => Instr_Addr,
    Instr => Instr,
    IFetch => IFetch,
    I_AS => I_AS,
    IReady => IReady,
    IWAIT => IWAIT,
    ICE => ICE,
    IUE => IUE,
    Data_Addr => Data_Addr,
    Data_Read => Data_Read,
    Data_Write => Data_Write,
    D_AS => D_AS,
    Read_Strobe => Read_Strobe,
    Write_Strobe => Write_Strobe,
    DReady => DReady,
    DWait => DWait,
    DCE => DCE,
    DUE => DUE,
    Byte_Enable => Byte_Enable,
    M_AXI_DP_AWADDR => M_AXI_DP_AWADDR,
    M_AXI_DP_AWPROT => M_AXI_DP_AWPROT,
    M_AXI_DP_AWVALID => M_AXI_DP_AWVALID,
    M_AXI_DP_AWREADY => M_AXI_DP_AWREADY,
    M_AXI_DP_WDATA => M_AXI_DP_WDATA,
    M_AXI_DP_WSTRB => M_AXI_DP_WSTRB,
    M_AXI_DP_WVALID => M_AXI_DP_WVALID,
    M_AXI_DP_WREADY => M_AXI_DP_WREADY,
    M_AXI_DP_BRESP => M_AXI_DP_BRESP,
    M_AXI_DP_BVALID => M_AXI_DP_BVALID,
    M_AXI_DP_BREADY => M_AXI_DP_BREADY,
    M_AXI_DP_ARADDR => M_AXI_DP_ARADDR,
    M_AXI_DP_ARPROT => M_AXI_DP_ARPROT,
    M_AXI_DP_ARVALID => M_AXI_DP_ARVALID,
    M_AXI_DP_ARREADY => M_AXI_DP_ARREADY,
    M_AXI_DP_RDATA => M_AXI_DP_RDATA,
    M_AXI_DP_RRESP => M_AXI_DP_RRESP,
    M_AXI_DP_RVALID => M_AXI_DP_RVALID,
    M_AXI_DP_RREADY => M_AXI_DP_RREADY,
    Dbg_Clk => Dbg_Clk,
    Dbg_TDI => Dbg_TDI,
    Dbg_TDO => Dbg_TDO,
    Dbg_Reg_En => Dbg_Reg_En,
    Dbg_Shift => Dbg_Shift,
    Dbg_Capture => Dbg_Capture,
    Dbg_Update => Dbg_Update,
    Debug_Rst => Debug_Rst
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

-- You must compile the wrapper file system_mb_3_0.vhd when simulating
-- the core, system_mb_3_0. When compiling the wrapper file, be sure to
-- reference the VHDL simulation library.

