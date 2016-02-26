-------------------------------------------------------------------------------
-- axi_lite_if.vhd
-------------------------------------------------------------------------------
--
--  
-- (c) Copyright [2010 - 2013] Xilinx, Inc. All rights reserved.
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
--
-------------------------------------------------------------------------------
-- Filename:        axi_lite_if.vhd
--
-- Description:     Derived AXI-Lite interface module.
--                  
-- VHDL-Standard:   VHDL'93
--
-------------------------------------------------------------------------------
-- Structure:
--              axi_bram_ctrl.vhd (v1_03_a)
--                      |
--                      |-- full_axi.vhd
--                      |   -- sng_port_arb.vhd
--                      |   -- lite_ecc_reg.vhd
--                      |       -- axi_lite_if.vhd
--                      |   -- wr_chnl.vhd
--                      |       -- wrap_brst.vhd
--                      |       -- ua_narrow.vhd
--                      |       -- checkbit_handler.vhd
--                      |           -- xor18.vhd
--                      |           -- parity.vhd
--                      |       -- checkbit_handler_64.vhd
--                      |           -- (same helper components as checkbit_handler)
--                      |       -- parity.vhd
--                      |       -- correct_one_bit.vhd
--                      |       -- correct_one_bit_64.vhd
--                      |
--                      |   -- rd_chnl.vhd
--                      |       -- wrap_brst.vhd
--                      |       -- ua_narrow.vhd
--                      |       -- checkbit_handler.vhd
--                      |           -- xor18.vhd
--                      |           -- parity.vhd
--                      |       -- checkbit_handler_64.vhd
--                      |           -- (same helper components as checkbit_handler)
--                      |       -- parity.vhd
--                      |       -- correct_one_bit.vhd
--                      |       -- correct_one_bit_64.vhd
--                      |
--                      |-- axi_lite.vhd
--                      |   -- lite_ecc_reg.vhd
--                      |       -- axi_lite_if.vhd
--                      |   -- checkbit_handler.vhd
--                      |       -- xor18.vhd
--                      |       -- parity.vhd
--                      |   -- checkbit_handler_64.vhd
--                      |       -- (same helper components as checkbit_handler)
--                      |   -- correct_one_bit.vhd
--                      |   -- correct_one_bit_64.vhd
--
--
--
-------------------------------------------------------------------------------
--
-- History:
--
-- ^^^^^^
-- JLJ      2/1/2011         v1.03a
-- ~~~~~~
--  Migrate to v1.03a.
--  Plus minor code cleanup.
-- ^^^^^^
--                            
--
-- 
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity axi_lite_if is
  generic (
    -- AXI4-Lite slave generics
    -- C_S_AXI_BASEADDR        : std_logic_vector       := X"FFFF_FFFF";
    -- C_S_AXI_HIGHADDR        : std_logic_vector       := X"0000_0000";
    C_S_AXI_ADDR_WIDTH      : integer                := 32;
    C_S_AXI_DATA_WIDTH      : integer                := 32;
    C_REGADDR_WIDTH         : integer                := 4;    -- Address bits including register offset.
    C_DWIDTH                : integer                := 32);  -- Width of data bus.
  port (
    LMB_Clk : in std_logic;
    LMB_Rst : in std_logic;

    -- AXI4-Lite SLAVE SINGLE INTERFACE
    S_AXI_AWADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWVALID : in  std_logic;
    S_AXI_AWREADY : out std_logic;
    S_AXI_WDATA   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB   : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WVALID  : in  std_logic;
    S_AXI_WREADY  : out std_logic;
    S_AXI_BRESP   : out std_logic_vector(1 downto 0);
    S_AXI_BVALID  : out std_logic;
    S_AXI_BREADY  : in  std_logic;
    S_AXI_ARADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARVALID : in  std_logic;
    S_AXI_ARREADY : out std_logic;
    S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP   : out std_logic_vector(1 downto 0);
    S_AXI_RVALID  : out std_logic;
    S_AXI_RREADY  : in  std_logic;
    
    -- lmb_bram_if_cntlr signals
    RegWr         : out std_logic;
    RegWrData     : out std_logic_vector(0 to C_DWIDTH - 1);
    RegAddr       : out std_logic_vector(0 to C_REGADDR_WIDTH-1);  
    RegRdData     : in  std_logic_vector(0 to C_DWIDTH - 1));
end entity axi_lite_if;

library unisim;
use unisim.vcomponents.all;

architecture IMP of axi_lite_if is

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of IMP : architecture is "yes";

  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  signal new_write_access       : std_logic;
  signal new_read_access        : std_logic;
  signal ongoing_write          : std_logic;
  signal ongoing_read           : std_logic;

  signal S_AXI_RVALID_i         : std_logic;

  signal RegRdData_i            : std_logic_vector(C_DWIDTH - 1 downto 0);

begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- Handling the AXI4-Lite bus interface (AR/AW/W)
  -----------------------------------------------------------------------------
  
  -- Detect new transaction.
  -- Only allow one access at a time
  new_write_access  <= not (ongoing_read or ongoing_write) and S_AXI_AWVALID and S_AXI_WVALID;
  new_read_access   <= not (ongoing_read or ongoing_write) and S_AXI_ARVALID and not new_write_access;

  -- Acknowledge new transaction.
  S_AXI_AWREADY <= new_write_access;
  S_AXI_WREADY  <= new_write_access;
  S_AXI_ARREADY <= new_read_access;

  -- Store register address and write data 
  Reg: process (LMB_Clk) is
  begin
    if LMB_Clk'event and LMB_Clk = '1' then
      if LMB_Rst = '1' then
        RegAddr   <= (others => '0');
        RegWrData <= (others => '0');
      elsif new_write_access = '1' then
        RegAddr   <= S_AXI_AWADDR(C_REGADDR_WIDTH-1+2 downto 2);
        RegWrData <= S_AXI_WDATA(C_DWIDTH-1 downto 0);
      elsif new_read_access = '1' then
        RegAddr   <= S_AXI_ARADDR(C_REGADDR_WIDTH-1+2 downto 2);
      end if;
    end if;
  end process Reg;
  
  -- Handle write access.
  WriteAccess: process (LMB_Clk) is
  begin
    if LMB_Clk'event and LMB_Clk = '1' then
      if LMB_Rst = '1' then
        ongoing_write <= '0';
      elsif new_write_access = '1' then
        ongoing_write <= '1';
      elsif ongoing_write = '1' and S_AXI_BREADY = '1' then
        ongoing_write <= '0';
      end if;
      RegWr <= new_write_access;
    end if;
  end process WriteAccess;

  S_AXI_BVALID <= ongoing_write;
  S_AXI_BRESP  <= (others => '0');

  -- Handle read access
  ReadAccess: process (LMB_Clk) is
  begin
    if LMB_Clk'event and LMB_Clk = '1' then
      if LMB_Rst = '1' then
        ongoing_read   <= '0';
        S_AXI_RVALID_i <= '0';
      elsif new_read_access = '1' then
        ongoing_read   <= '1';
        S_AXI_RVALID_i <= '0';
      elsif ongoing_read = '1' then
        if S_AXI_RREADY = '1' and S_AXI_RVALID_i = '1' then
          ongoing_read   <= '0';
          S_AXI_RVALID_i <= '0';
        else
          S_AXI_RVALID_i <= '1'; -- Asserted one cycle after ongoing_read to match S_AXI_RDDATA
        end if;
      end if;
    end if;
  end process ReadAccess;

  S_AXI_RVALID <= S_AXI_RVALID_i;
  S_AXI_RRESP  <= (others => '0');
  
  Not_All_Bits_Are_Used: if (C_DWIDTH < C_S_AXI_DATA_WIDTH) generate
  begin
    S_AXI_RDATA(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH - C_DWIDTH)  <= (others=>'0');
  end generate Not_All_Bits_Are_Used;

  RegRdData_i <= RegRdData;             -- Swap to - downto
  
  S_AXI_RDATA_DFF : for I in C_DWIDTH - 1 downto 0 generate
  begin
    S_AXI_RDATA_FDRE : FDRE
      port map (
        Q  => S_AXI_RDATA(I),
        C  => LMB_Clk,
        CE => ongoing_read,
        D  => RegRdData_i(I),
        R  => LMB_Rst);
  end generate S_AXI_RDATA_DFF;
  
end architecture IMP;
