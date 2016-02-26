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

-- IP VLNV: xilinx.com:ip:lmb_bram_if_cntlr:4.0
-- IP Revision: 7

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY lmb_bram_if_cntlr_v4_0_7;
USE lmb_bram_if_cntlr_v4_0_7.lmb_bram_if_cntlr;

ENTITY system_lmb_bram_if_cntlr_0 IS
  PORT (
    LMB_Clk : IN STD_LOGIC;
    LMB_Rst : IN STD_LOGIC;
    LMB_ABus : IN STD_LOGIC_VECTOR(0 TO 31);
    LMB_WriteDBus : IN STD_LOGIC_VECTOR(0 TO 31);
    LMB_AddrStrobe : IN STD_LOGIC;
    LMB_ReadStrobe : IN STD_LOGIC;
    LMB_WriteStrobe : IN STD_LOGIC;
    LMB_BE : IN STD_LOGIC_VECTOR(0 TO 3);
    Sl_DBus : OUT STD_LOGIC_VECTOR(0 TO 31);
    Sl_Ready : OUT STD_LOGIC;
    Sl_Wait : OUT STD_LOGIC;
    Sl_UE : OUT STD_LOGIC;
    Sl_CE : OUT STD_LOGIC;
    LMB1_ABus : IN STD_LOGIC_VECTOR(0 TO 31);
    LMB1_WriteDBus : IN STD_LOGIC_VECTOR(0 TO 31);
    LMB1_AddrStrobe : IN STD_LOGIC;
    LMB1_ReadStrobe : IN STD_LOGIC;
    LMB1_WriteStrobe : IN STD_LOGIC;
    LMB1_BE : IN STD_LOGIC_VECTOR(0 TO 3);
    Sl1_DBus : OUT STD_LOGIC_VECTOR(0 TO 31);
    Sl1_Ready : OUT STD_LOGIC;
    Sl1_Wait : OUT STD_LOGIC;
    Sl1_UE : OUT STD_LOGIC;
    Sl1_CE : OUT STD_LOGIC;
    BRAM_Rst_A : OUT STD_LOGIC;
    BRAM_Clk_A : OUT STD_LOGIC;
    BRAM_Addr_A : OUT STD_LOGIC_VECTOR(0 TO 31);
    BRAM_EN_A : OUT STD_LOGIC;
    BRAM_WEN_A : OUT STD_LOGIC_VECTOR(0 TO 3);
    BRAM_Dout_A : OUT STD_LOGIC_VECTOR(0 TO 31);
    BRAM_Din_A : IN STD_LOGIC_VECTOR(0 TO 31)
  );
END system_lmb_bram_if_cntlr_0;

ARCHITECTURE system_lmb_bram_if_cntlr_0_arch OF system_lmb_bram_if_cntlr_0 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : string;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF system_lmb_bram_if_cntlr_0_arch: ARCHITECTURE IS "yes";

  COMPONENT lmb_bram_if_cntlr IS
    GENERIC (
      C_FAMILY : STRING;
      C_HIGHADDR : STD_LOGIC_VECTOR(0 TO 31);
      C_BASEADDR : STD_LOGIC_VECTOR(0 TO 31);
      C_NUM_LMB : INTEGER;
      C_MASK : STD_LOGIC_VECTOR(0 TO 31);
      C_MASK1 : STD_LOGIC_VECTOR(0 TO 31);
      C_MASK2 : STD_LOGIC_VECTOR(0 TO 31);
      C_MASK3 : STD_LOGIC_VECTOR(0 TO 31);
      C_LMB_AWIDTH : INTEGER;
      C_LMB_DWIDTH : INTEGER;
      C_ECC : INTEGER;
      C_INTERCONNECT : INTEGER;
      C_FAULT_INJECT : INTEGER;
      C_CE_FAILING_REGISTERS : INTEGER;
      C_UE_FAILING_REGISTERS : INTEGER;
      C_ECC_STATUS_REGISTERS : INTEGER;
      C_ECC_ONOFF_REGISTER : INTEGER;
      C_ECC_ONOFF_RESET_VALUE : INTEGER;
      C_CE_COUNTER_WIDTH : INTEGER;
      C_WRITE_ACCESS : INTEGER;
      C_S_AXI_CTRL_ADDR_WIDTH : INTEGER;
      C_S_AXI_CTRL_DATA_WIDTH : INTEGER
    );
    PORT (
      LMB_Clk : IN STD_LOGIC;
      LMB_Rst : IN STD_LOGIC;
      LMB_ABus : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_WriteDBus : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB_AddrStrobe : IN STD_LOGIC;
      LMB_ReadStrobe : IN STD_LOGIC;
      LMB_WriteStrobe : IN STD_LOGIC;
      LMB_BE : IN STD_LOGIC_VECTOR(0 TO 3);
      Sl_DBus : OUT STD_LOGIC_VECTOR(0 TO 31);
      Sl_Ready : OUT STD_LOGIC;
      Sl_Wait : OUT STD_LOGIC;
      Sl_UE : OUT STD_LOGIC;
      Sl_CE : OUT STD_LOGIC;
      LMB1_ABus : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB1_WriteDBus : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB1_AddrStrobe : IN STD_LOGIC;
      LMB1_ReadStrobe : IN STD_LOGIC;
      LMB1_WriteStrobe : IN STD_LOGIC;
      LMB1_BE : IN STD_LOGIC_VECTOR(0 TO 3);
      Sl1_DBus : OUT STD_LOGIC_VECTOR(0 TO 31);
      Sl1_Ready : OUT STD_LOGIC;
      Sl1_Wait : OUT STD_LOGIC;
      Sl1_UE : OUT STD_LOGIC;
      Sl1_CE : OUT STD_LOGIC;
      LMB2_ABus : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB2_WriteDBus : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB2_AddrStrobe : IN STD_LOGIC;
      LMB2_ReadStrobe : IN STD_LOGIC;
      LMB2_WriteStrobe : IN STD_LOGIC;
      LMB2_BE : IN STD_LOGIC_VECTOR(0 TO 3);
      Sl2_DBus : OUT STD_LOGIC_VECTOR(0 TO 31);
      Sl2_Ready : OUT STD_LOGIC;
      Sl2_Wait : OUT STD_LOGIC;
      Sl2_UE : OUT STD_LOGIC;
      Sl2_CE : OUT STD_LOGIC;
      LMB3_ABus : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB3_WriteDBus : IN STD_LOGIC_VECTOR(0 TO 31);
      LMB3_AddrStrobe : IN STD_LOGIC;
      LMB3_ReadStrobe : IN STD_LOGIC;
      LMB3_WriteStrobe : IN STD_LOGIC;
      LMB3_BE : IN STD_LOGIC_VECTOR(0 TO 3);
      Sl3_DBus : OUT STD_LOGIC_VECTOR(0 TO 31);
      Sl3_Ready : OUT STD_LOGIC;
      Sl3_Wait : OUT STD_LOGIC;
      Sl3_UE : OUT STD_LOGIC;
      Sl3_CE : OUT STD_LOGIC;
      BRAM_Rst_A : OUT STD_LOGIC;
      BRAM_Clk_A : OUT STD_LOGIC;
      BRAM_Addr_A : OUT STD_LOGIC_VECTOR(0 TO 31);
      BRAM_EN_A : OUT STD_LOGIC;
      BRAM_WEN_A : OUT STD_LOGIC_VECTOR(0 TO 3);
      BRAM_Dout_A : OUT STD_LOGIC_VECTOR(0 TO 31);
      BRAM_Din_A : IN STD_LOGIC_VECTOR(0 TO 31);
      S_AXI_CTRL_ACLK : IN STD_LOGIC;
      S_AXI_CTRL_ARESETN : IN STD_LOGIC;
      S_AXI_CTRL_AWADDR : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      S_AXI_CTRL_AWVALID : IN STD_LOGIC;
      S_AXI_CTRL_AWREADY : OUT STD_LOGIC;
      S_AXI_CTRL_WDATA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      S_AXI_CTRL_WSTRB : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S_AXI_CTRL_WVALID : IN STD_LOGIC;
      S_AXI_CTRL_WREADY : OUT STD_LOGIC;
      S_AXI_CTRL_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S_AXI_CTRL_BVALID : OUT STD_LOGIC;
      S_AXI_CTRL_BREADY : IN STD_LOGIC;
      S_AXI_CTRL_ARADDR : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      S_AXI_CTRL_ARVALID : IN STD_LOGIC;
      S_AXI_CTRL_ARREADY : OUT STD_LOGIC;
      S_AXI_CTRL_RDATA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      S_AXI_CTRL_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S_AXI_CTRL_RVALID : OUT STD_LOGIC;
      S_AXI_CTRL_RREADY : IN STD_LOGIC;
      UE : OUT STD_LOGIC;
      CE : OUT STD_LOGIC;
      Interrupt : OUT STD_LOGIC
    );
  END COMPONENT lmb_bram_if_cntlr;
  ATTRIBUTE X_INTERFACE_INFO : STRING;
  ATTRIBUTE X_INTERFACE_INFO OF LMB_Clk: SIGNAL IS "xilinx.com:signal:clock:1.0 CLK.LMB_Clk CLK";
  ATTRIBUTE X_INTERFACE_INFO OF LMB_Rst: SIGNAL IS "xilinx.com:signal:reset:1.0 RST.LMB_Rst RST";
  ATTRIBUTE X_INTERFACE_INFO OF LMB_ABus: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB ABUS";
  ATTRIBUTE X_INTERFACE_INFO OF LMB_WriteDBus: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB WRITEDBUS";
  ATTRIBUTE X_INTERFACE_INFO OF LMB_AddrStrobe: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB ADDRSTROBE";
  ATTRIBUTE X_INTERFACE_INFO OF LMB_ReadStrobe: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB READSTROBE";
  ATTRIBUTE X_INTERFACE_INFO OF LMB_WriteStrobe: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB WRITESTROBE";
  ATTRIBUTE X_INTERFACE_INFO OF LMB_BE: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB BE";
  ATTRIBUTE X_INTERFACE_INFO OF Sl_DBus: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB READDBUS";
  ATTRIBUTE X_INTERFACE_INFO OF Sl_Ready: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB READY";
  ATTRIBUTE X_INTERFACE_INFO OF Sl_Wait: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB WAIT";
  ATTRIBUTE X_INTERFACE_INFO OF Sl_UE: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB UE";
  ATTRIBUTE X_INTERFACE_INFO OF Sl_CE: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB CE";
  ATTRIBUTE X_INTERFACE_INFO OF LMB1_ABus: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB1 ABUS";
  ATTRIBUTE X_INTERFACE_INFO OF LMB1_WriteDBus: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB1 WRITEDBUS";
  ATTRIBUTE X_INTERFACE_INFO OF LMB1_AddrStrobe: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB1 ADDRSTROBE";
  ATTRIBUTE X_INTERFACE_INFO OF LMB1_ReadStrobe: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB1 READSTROBE";
  ATTRIBUTE X_INTERFACE_INFO OF LMB1_WriteStrobe: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB1 WRITESTROBE";
  ATTRIBUTE X_INTERFACE_INFO OF LMB1_BE: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB1 BE";
  ATTRIBUTE X_INTERFACE_INFO OF Sl1_DBus: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB1 READDBUS";
  ATTRIBUTE X_INTERFACE_INFO OF Sl1_Ready: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB1 READY";
  ATTRIBUTE X_INTERFACE_INFO OF Sl1_Wait: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB1 WAIT";
  ATTRIBUTE X_INTERFACE_INFO OF Sl1_UE: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB1 UE";
  ATTRIBUTE X_INTERFACE_INFO OF Sl1_CE: SIGNAL IS "xilinx.com:interface:lmb:1.0 SLMB1 CE";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_Rst_A: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORT RST";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_Clk_A: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORT CLK";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_Addr_A: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORT ADDR";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_EN_A: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORT EN";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_WEN_A: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORT WE";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_Dout_A: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORT DIN";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_Din_A: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORT DOUT";
BEGIN
  U0 : lmb_bram_if_cntlr
    GENERIC MAP (
      C_FAMILY => "zynq",
      C_HIGHADDR => X"00007FFF",
      C_BASEADDR => X"00000000",
      C_NUM_LMB => 2,
      C_MASK => X"00000000",
      C_MASK1 => X"40000000",
      C_MASK2 => X"00800000",
      C_MASK3 => X"00800000",
      C_LMB_AWIDTH => 32,
      C_LMB_DWIDTH => 32,
      C_ECC => 0,
      C_INTERCONNECT => 0,
      C_FAULT_INJECT => 0,
      C_CE_FAILING_REGISTERS => 0,
      C_UE_FAILING_REGISTERS => 0,
      C_ECC_STATUS_REGISTERS => 0,
      C_ECC_ONOFF_REGISTER => 0,
      C_ECC_ONOFF_RESET_VALUE => 1,
      C_CE_COUNTER_WIDTH => 0,
      C_WRITE_ACCESS => 2,
      C_S_AXI_CTRL_ADDR_WIDTH => 32,
      C_S_AXI_CTRL_DATA_WIDTH => 32
    )
    PORT MAP (
      LMB_Clk => LMB_Clk,
      LMB_Rst => LMB_Rst,
      LMB_ABus => LMB_ABus,
      LMB_WriteDBus => LMB_WriteDBus,
      LMB_AddrStrobe => LMB_AddrStrobe,
      LMB_ReadStrobe => LMB_ReadStrobe,
      LMB_WriteStrobe => LMB_WriteStrobe,
      LMB_BE => LMB_BE,
      Sl_DBus => Sl_DBus,
      Sl_Ready => Sl_Ready,
      Sl_Wait => Sl_Wait,
      Sl_UE => Sl_UE,
      Sl_CE => Sl_CE,
      LMB1_ABus => LMB1_ABus,
      LMB1_WriteDBus => LMB1_WriteDBus,
      LMB1_AddrStrobe => LMB1_AddrStrobe,
      LMB1_ReadStrobe => LMB1_ReadStrobe,
      LMB1_WriteStrobe => LMB1_WriteStrobe,
      LMB1_BE => LMB1_BE,
      Sl1_DBus => Sl1_DBus,
      Sl1_Ready => Sl1_Ready,
      Sl1_Wait => Sl1_Wait,
      Sl1_UE => Sl1_UE,
      Sl1_CE => Sl1_CE,
      LMB2_ABus => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB2_WriteDBus => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB2_AddrStrobe => '0',
      LMB2_ReadStrobe => '0',
      LMB2_WriteStrobe => '0',
      LMB2_BE => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 4)),
      LMB3_ABus => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB3_WriteDBus => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      LMB3_AddrStrobe => '0',
      LMB3_ReadStrobe => '0',
      LMB3_WriteStrobe => '0',
      LMB3_BE => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 4)),
      BRAM_Rst_A => BRAM_Rst_A,
      BRAM_Clk_A => BRAM_Clk_A,
      BRAM_Addr_A => BRAM_Addr_A,
      BRAM_EN_A => BRAM_EN_A,
      BRAM_WEN_A => BRAM_WEN_A,
      BRAM_Dout_A => BRAM_Dout_A,
      BRAM_Din_A => BRAM_Din_A,
      S_AXI_CTRL_ACLK => '0',
      S_AXI_CTRL_ARESETN => '0',
      S_AXI_CTRL_AWADDR => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      S_AXI_CTRL_AWVALID => '0',
      S_AXI_CTRL_WDATA => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      S_AXI_CTRL_WSTRB => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 4)),
      S_AXI_CTRL_WVALID => '0',
      S_AXI_CTRL_BREADY => '0',
      S_AXI_CTRL_ARADDR => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      S_AXI_CTRL_ARVALID => '0',
      S_AXI_CTRL_RREADY => '0'
    );
END system_lmb_bram_if_cntlr_0_arch;
