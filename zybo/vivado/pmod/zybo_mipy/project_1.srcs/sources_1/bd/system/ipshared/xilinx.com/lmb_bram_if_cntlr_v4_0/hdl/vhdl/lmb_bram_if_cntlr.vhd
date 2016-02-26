-------------------------------------------------------------------------------
-- lmb_bram_if_cntlr.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright [2003] - [2015] Xilinx, Inc. All rights reserved.
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
-- PART OF THIS FILE AT ALL TIMES
--
------------------------------------------------------------------------------
-- Filename:        lmb_bram_if_cntlr.vhd
--
-- Description:
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--              lmb_bram_if_cntlr
--                lmb_mux
--                correct_one_bit
--                xor18.vhd
--                axi_interface
-------------------------------------------------------------------------------
-- Author:          rolandp
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lmb_bram_if_cntlr_v4_0_7;
use lmb_bram_if_cntlr_v4_0_7.all;

entity lmb_bram_if_cntlr is
  generic (
    C_FAMILY                   : string                    := "Virtex7";
    C_HIGHADDR                 : std_logic_vector(0 to 31) := X"00000000";
    C_BASEADDR                 : std_logic_vector(0 to 31) := X"FFFFFFFF";
    C_MASK                     : std_logic_vector(0 to 31) := X"00800000";
    C_MASK1                    : std_logic_vector(0 to 31) := X"00800000";
    C_MASK2                    : std_logic_vector(0 to 31) := X"00800000";
    C_MASK3                    : std_logic_vector(0 to 31) := X"00800000";
    C_LMB_AWIDTH               : integer                   := 32;
    C_LMB_DWIDTH               : integer                   := 32;
    C_ECC                      : integer                   := 0;
    C_INTERCONNECT             : integer                   := 1;
    C_FAULT_INJECT             : integer                   := 0;
    C_CE_FAILING_REGISTERS     : integer                   := 0;
    C_UE_FAILING_REGISTERS     : integer                   := 0;
    C_ECC_STATUS_REGISTERS     : integer                   := 0;
    C_ECC_ONOFF_REGISTER       : integer                   := 0;
    C_ECC_ONOFF_RESET_VALUE    : integer                   := 1;
    C_CE_COUNTER_WIDTH         : integer                   := 0;
    C_WRITE_ACCESS             : integer                   := 2;
    C_NUM_LMB                  : integer                   := 1;
    -- AXI generics
    C_S_AXI_CTRL_BASEADDR      : std_logic_vector       := X"FFFF_FFFF";
    C_S_AXI_CTRL_HIGHADDR      : std_logic_vector       := X"0000_0000";
    C_S_AXI_CTRL_ADDR_WIDTH    : integer                := 32;
    C_S_AXI_CTRL_DATA_WIDTH    : integer                := 32);
  port (
    LMB_Clk : in std_logic := '0';
    LMB_Rst : in std_logic := '0';

    -- LMB Bus
    LMB_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB_AddrStrobe  : in  std_logic;
    LMB_ReadStrobe  : in  std_logic;
    LMB_WriteStrobe : in  std_logic;
    LMB_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl_Ready        : out std_logic;
    Sl_Wait         : out std_logic;
    Sl_UE           : out std_logic;
    Sl_CE           : out std_logic;

    -- Supplementary LMB Bus 1
    LMB1_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB1_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB1_AddrStrobe  : in  std_logic;
    LMB1_ReadStrobe  : in  std_logic;
    LMB1_WriteStrobe : in  std_logic;
    LMB1_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl1_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl1_Ready        : out std_logic;
    Sl1_Wait         : out std_logic;
    Sl1_UE           : out std_logic;
    Sl1_CE           : out std_logic;

    -- Supplementary LMB Bus 2
    LMB2_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB2_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB2_AddrStrobe  : in  std_logic;
    LMB2_ReadStrobe  : in  std_logic;
    LMB2_WriteStrobe : in  std_logic;
    LMB2_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl2_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl2_Ready        : out std_logic;
    Sl2_Wait         : out std_logic;
    Sl2_UE           : out std_logic;
    Sl2_CE           : out std_logic;

    -- Supplementary LMB Bus 3
    LMB3_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB3_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB3_AddrStrobe  : in  std_logic;
    LMB3_ReadStrobe  : in  std_logic;
    LMB3_WriteStrobe : in  std_logic;
    LMB3_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl3_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl3_Ready        : out std_logic;
    Sl3_Wait         : out std_logic;
    Sl3_UE           : out std_logic;
    Sl3_CE           : out std_logic;
    
    -- ports to data memory block
    BRAM_Rst_A  : out std_logic;
    BRAM_Clk_A  : out std_logic;
    BRAM_Addr_A : out std_logic_vector(0 to C_LMB_AWIDTH-1);
    BRAM_EN_A   : out std_logic;
    BRAM_WEN_A  : out std_logic_vector(0 to (C_LMB_DWIDTH+8*C_ECC)/8-1);
    BRAM_Dout_A : out std_logic_vector(0 to C_LMB_DWIDTH+8*C_ECC-1);
    BRAM_Din_A  : in  std_logic_vector(0 to C_LMB_DWIDTH+8*C_ECC-1);

    -- AXI Interface
    S_AXI_CTRL_ACLK    : in  std_logic;
    S_AXI_CTRL_ARESETN : in  std_logic;
    S_AXI_CTRL_AWADDR  : in  std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
    S_AXI_CTRL_AWVALID : in  std_logic;
    S_AXI_CTRL_AWREADY : out std_logic;
    S_AXI_CTRL_WDATA   : in  std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    S_AXI_CTRL_WSTRB   : in  std_logic_vector((C_S_AXI_CTRL_DATA_WIDTH/8)-1 downto 0);
    S_AXI_CTRL_WVALID  : in  std_logic;
    S_AXI_CTRL_WREADY  : out std_logic;
    S_AXI_CTRL_BRESP   : out std_logic_vector(1 downto 0);
    S_AXI_CTRL_BVALID  : out std_logic;
    S_AXI_CTRL_BREADY  : in  std_logic;
    S_AXI_CTRL_ARADDR  : in  std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
    S_AXI_CTRL_ARVALID : in  std_logic;
    S_AXI_CTRL_ARREADY : out std_logic;
    S_AXI_CTRL_RDATA   : out std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    S_AXI_CTRL_RRESP   : out std_logic_vector(1 downto 0);
    S_AXI_CTRL_RVALID  : out std_logic;
    S_AXI_CTRL_RREADY  : in  std_logic;
   
    -- Interrupt and error signals
    UE        : out std_logic;
    CE        : out std_logic;
    Interrupt : out std_logic);
end lmb_bram_if_cntlr;

library lmb_bram_if_cntlr_v4_0_7;
use lmb_bram_if_cntlr_v4_0_7.lmb_bram_if_funcs.all;

architecture imp of lmb_bram_if_cntlr is

------------------------------------------------------------------------------
-- component declarations
------------------------------------------------------------------------------

  component lmb_mux is
  generic (
    C_BASEADDR   : std_logic_vector(0 to 31) := X"FFFFFFFF";
    C_MASK       : std_logic_vector(0 to 31) := X"00800000";
    C_MASK1      : std_logic_vector(0 to 31) := X"00800000";
    C_MASK2      : std_logic_vector(0 to 31) := X"00800000";
    C_MASK3      : std_logic_vector(0 to 31) := X"00800000";
    C_LMB_AWIDTH : integer                   := 32;
    C_LMB_DWIDTH : integer                   := 32;
    C_NUM_LMB    : integer                   := 1);
  port (
    LMB_Clk : in std_logic := '0';
    LMB_Rst : in std_logic := '0';

    -- LMB Bus 0
    LMB0_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB0_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB0_AddrStrobe  : in  std_logic;
    LMB0_ReadStrobe  : in  std_logic;
    LMB0_WriteStrobe : in  std_logic;
    LMB0_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl0_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl0_Ready        : out std_logic;
    Sl0_Wait         : out std_logic;
    Sl0_UE           : out std_logic;
    Sl0_CE           : out std_logic;

    -- LMB Bus 1
    LMB1_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB1_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB1_AddrStrobe  : in  std_logic;
    LMB1_ReadStrobe  : in  std_logic;
    LMB1_WriteStrobe : in  std_logic;
    LMB1_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl1_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl1_Ready        : out std_logic;
    Sl1_Wait         : out std_logic;
    Sl1_UE           : out std_logic;
    Sl1_CE           : out std_logic;

    -- LMB Bus 2
    LMB2_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB2_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB2_AddrStrobe  : in  std_logic;
    LMB2_ReadStrobe  : in  std_logic;
    LMB2_WriteStrobe : in  std_logic;
    LMB2_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl2_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl2_Ready        : out std_logic;
    Sl2_Wait         : out std_logic;
    Sl2_UE           : out std_logic;
    Sl2_CE           : out std_logic;

    -- LMB Bus 3
    LMB3_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB3_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB3_AddrStrobe  : in  std_logic;
    LMB3_ReadStrobe  : in  std_logic;
    LMB3_WriteStrobe : in  std_logic;
    LMB3_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl3_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl3_Ready        : out std_logic;
    Sl3_Wait         : out std_logic;
    Sl3_UE           : out std_logic;
    Sl3_CE           : out std_logic;
    
    -- Muxed LMB Bus
    LMB_ABus        : out std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB_WriteDBus   : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB_AddrStrobe  : out std_logic;
    LMB_ReadStrobe  : out std_logic;
    LMB_WriteStrobe : out std_logic;
    LMB_BE          : out std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl_DBus         : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl_Ready        : in  std_logic;
    Sl_Wait         : in  std_logic;
    Sl_UE           : in  std_logic;
    Sl_CE           : in  std_logic;

    lmb_select       : out std_logic);
  end component lmb_mux;

  component axi_interface 
  generic (
    C_TARGET           : TARGET_FAMILY_TYPE;
    C_S_AXI_BASEADDR   : std_logic_vector := X"FFFF_FFFF";
    C_S_AXI_HIGHADDR   : std_logic_vector := X"0000_0000";
    C_S_AXI_ADDR_WIDTH : integer          := 32;
    C_S_AXI_DATA_WIDTH : integer          := 32;
    C_REGADDR_WIDTH    : integer          := 5;    -- Address bits including register offset.
    C_DWIDTH           : integer          := 32);  -- Width of data bus.
  port (
    LMB_Clk       : in std_logic;
    LMB_Rst       : in std_logic;
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
    RegWr         : out std_logic;
    RegWrData     : out std_logic_vector(0 to C_DWIDTH - 1);
    RegAddr       : out std_logic_vector(0 to C_REGADDR_WIDTH-1);  
    RegRdData     : in  std_logic_vector(0 to C_DWIDTH - 1));
  end component;

  component checkbit_handler is
    generic (
      C_TARGET   : TARGET_FAMILY_TYPE;
      C_ENCODE   : boolean);
    port (
      DataIn     : in  std_logic_vector(0 to 31);
      CheckIn    : in  std_logic_vector(0 to 6);
      CheckOut   : out std_logic_vector(0 to 6);
      Syndrome   : out std_logic_vector(0 to 6);
      Enable_ECC : in  std_logic;
      UE_Q       : in  std_logic;
      CE_Q       : in  std_logic;
      UE         : out std_logic;
      CE         : out std_logic);
  end component checkbit_handler;
  
  component Correct_One_Bit
    generic (
      C_TARGET      : TARGET_FAMILY_TYPE;
      Correct_Value : std_logic_vector(0 to 6));
    port (
      DIn      : in  std_logic;
      Syndrome : in  std_logic_vector(0 to 6);
      DCorr    : out std_logic);
  end component Correct_One_Bit;

  constant C_TARGET   : TARGET_FAMILY_TYPE := String_To_Family(C_FAMILY, false);
  
  constant C_HAS_FAULT_INJECT         : boolean := C_FAULT_INJECT = 1;
  constant C_HAS_CE_FAILING_REGISTERS : boolean := C_CE_FAILING_REGISTERS = 1;
  constant C_HAS_UE_FAILING_REGISTERS : boolean := C_UE_FAILING_REGISTERS = 1;
  constant C_HAS_ECC_STATUS_REGISTERS : boolean := C_ECC_STATUS_REGISTERS = 1;
  constant C_HAS_ECC_ONOFF_REGISTER   : boolean := C_ECC_ONOFF_REGISTER = 1;
  constant C_HAS_CE_COUNTER           : boolean := C_CE_COUNTER_WIDTH /= 0;

  constant C_BUS_NEEDED : boolean := C_HAS_FAULT_INJECT  or
                                     C_HAS_CE_FAILING_REGISTERS or
                                     C_HAS_UE_FAILING_REGISTERS or
                                     C_HAS_ECC_STATUS_REGISTERS or
                                     C_HAS_ECC_ONOFF_REGISTER or
                                     C_HAS_CE_COUNTER;

  constant C_AXI : integer := 2;

  constant C_HAS_AXI : boolean := C_ECC = 1 and C_INTERCONNECT = C_AXI and C_BUS_NEEDED;

  constant C_ECC_WIDTH : integer := 7;


  -- Intermediate signals to handle multiple LMB ports
  signal LMB_ABus_i        : std_logic_vector(0 to C_LMB_AWIDTH-1);
  signal LMB_WriteDBus_i   : std_logic_vector(0 to C_LMB_DWIDTH-1);
  signal LMB_AddrStrobe_i  : std_logic;
  signal LMB_ReadStrobe_i  : std_logic;
  signal LMB_WriteStrobe_i : std_logic;
  signal LMB_BE_i          : std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
  signal Sl_DBus_i         : std_logic_vector(0 to C_LMB_DWIDTH-1);
  signal Sl_Ready_i        : std_logic;
  signal Sl_Wait_i         : std_logic;
  signal Sl_UE_i           : std_logic;
  signal Sl_CE_i           : std_logic;

  signal lmb_select       : std_logic;
  signal lmb_as           : std_logic;

  signal lmb_we : std_logic_vector(0 to 3);

  signal Sl_Rdy : std_logic;

  signal bram_din_a_i  : std_logic_vector(0 to C_LMB_DWIDTH+8*C_ECC-1);

begin

  -----------------------------------------------------------------------------
  -- Cleaning incoming data from BRAM from 'U' for simulation purpose
  -- This is added since simulation model for BRAM will not initialize
  -- undefined memory locations with zero.
  -- Added as a work-around until this is fixed in the simulation model.
  -----------------------------------------------------------------------------
  Cleaning_machine: process (BRAM_Din_A) is
  begin  -- process Cleaning_machine
    -- Default assignments
    bram_din_a_i <= BRAM_Din_A;
    -- pragma translate_off
    bram_din_a_i <= To_StdLogicVector(To_bitvector(BRAM_Din_A));
    -- pragma translate_on
   
  end process Cleaning_machine;

  lmb_mux_I : lmb_mux
    generic map (
      C_BASEADDR   => C_BASEADDR,
      C_MASK       => C_MASK,
      C_MASK1      => C_MASK1,
      C_MASK2      => C_MASK2,
      C_MASK3      => C_MASK3,
      C_LMB_AWIDTH => C_LMB_AWIDTH,
      C_LMB_DWIDTH => C_LMB_DWIDTH,
      C_NUM_LMB    => C_NUM_LMB)
    port map (
      LMB_Clk          => LMB_Clk,
      LMB_Rst          => LMB_Rst,
      LMB0_ABus        => LMB_ABus,
      LMB0_WriteDBus   => LMB_WriteDBus,
      LMB0_AddrStrobe  => LMB_AddrStrobe,
      LMB0_ReadStrobe  => LMB_ReadStrobe,
      LMB0_WriteStrobe => LMB_WriteStrobe,
      LMB0_BE          => LMB_BE,
      Sl0_DBus         => Sl_DBus,
      Sl0_Ready        => Sl_Ready,
      Sl0_Wait         => Sl_Wait,
      Sl0_UE           => Sl_UE,
      Sl0_CE           => Sl_CE,
      LMB1_ABus        => LMB1_ABus,
      LMB1_WriteDBus   => LMB1_WriteDBus,
      LMB1_AddrStrobe  => LMB1_AddrStrobe,
      LMB1_ReadStrobe  => LMB1_ReadStrobe,
      LMB1_WriteStrobe => LMB1_WriteStrobe,
      LMB1_BE          => LMB1_BE,
      Sl1_DBus         => Sl1_DBus,
      Sl1_Ready        => Sl1_Ready,
      Sl1_Wait         => Sl1_Wait,
      Sl1_UE           => Sl1_UE,
      Sl1_CE           => Sl1_CE,
      LMB2_ABus        => LMB2_ABus,
      LMB2_WriteDBus   => LMB2_WriteDBus,
      LMB2_AddrStrobe  => LMB2_AddrStrobe,
      LMB2_ReadStrobe  => LMB2_ReadStrobe,
      LMB2_WriteStrobe => LMB2_WriteStrobe,
      LMB2_BE          => LMB2_BE,
      Sl2_DBus         => Sl2_DBus,
      Sl2_Ready        => Sl2_Ready,
      Sl2_Wait         => Sl2_Wait,
      Sl2_UE           => Sl2_UE,
      Sl2_CE           => Sl2_CE,
      LMB3_ABus        => LMB3_ABus,
      LMB3_WriteDBus   => LMB3_WriteDBus,
      LMB3_AddrStrobe  => LMB3_AddrStrobe,
      LMB3_ReadStrobe  => LMB3_ReadStrobe,
      LMB3_WriteStrobe => LMB3_WriteStrobe,
      LMB3_BE          => LMB3_BE,
      Sl3_DBus         => Sl3_DBus,
      Sl3_Ready        => Sl3_Ready,
      Sl3_Wait         => Sl3_Wait,
      Sl3_UE           => Sl3_UE,
      Sl3_CE           => Sl3_CE,
      LMB_ABus         => LMB_ABus_i,
      LMB_WriteDBus    => LMB_WriteDBus_i,
      LMB_AddrStrobe   => LMB_AddrStrobe_i,
      LMB_ReadStrobe   => LMB_ReadStrobe_i,
      LMB_WriteStrobe  => LMB_WriteStrobe_i,
      LMB_BE           => LMB_BE_i,
      Sl_DBus          => Sl_DBus_i,
      Sl_Ready         => Sl_Ready_i,
      Sl_Wait          => Sl_Wait_i,
      Sl_UE            => Sl_UE_i,
      Sl_CE            => Sl_CE_i,
      lmb_select       => lmb_select);  

  BRAM_Rst_A  <= '0';
  BRAM_Clk_A  <= LMB_Clk;

  lmb_we(0) <= LMB_BE_i(0) and LMB_WriteStrobe_i and lmb_select;
  lmb_we(1) <= LMB_BE_i(1) and LMB_WriteStrobe_i and lmb_select;
  lmb_we(2) <= LMB_BE_i(2) and LMB_WriteStrobe_i and lmb_select;
  lmb_we(3) <= LMB_BE_i(3) and LMB_WriteStrobe_i and lmb_select;
  

  No_ECC : if (C_ECC = 0) generate

  begin

    BRAM_EN_A   <= LMB_AddrStrobe_i;
    BRAM_WEN_A  <= lmb_we;
    BRAM_Dout_A <= LMB_WriteDBus_i;
    Sl_DBus_i   <= bram_din_a_i;
    BRAM_Addr_A <= LMB_ABus_i;

    -- only used wen ECC enabled, tie to constant inactive
    Sl_Wait_i   <= '0';
    Sl_UE_i     <= '0';
    Sl_CE_i     <= '0';
    UE          <= '0';
    CE          <= '0';
    Interrupt   <= '0';

    -----------------------------------------------------------------------------
    -- Writes are pipelined in MB with 5 stage pipeline
    -----------------------------------------------------------------------------
    Ready_Handling : process (LMB_Clk) is
    begin 
      if (LMB_Clk'event and LMB_Clk = '1') then
        if (LMB_Rst = '1') then
          Sl_Rdy <= '0';
          lmb_as <= '0';
        else
          Sl_Rdy <= lmb_select;
          lmb_as <= LMB_AddrStrobe_i;
        end if;
      end if;
    end process Ready_Handling;

    Sl_Ready_i <= Sl_Rdy and lmb_as;
    
  end generate No_ECC;
  
  ECC : if (C_ECC = 1) generate

    constant NO_WRITES  : integer := 0;
    constant ONLY_WORD  : integer := 1;
    constant ALL_WRITES : integer := 2;

    signal enable_ecc : std_logic;

    -- On/Off Register
    constant C_ECC_ONOFF         : natural := 31;
    constant C_ECC_ONOFF_WIDTH   : natural := 1;
    signal ECC_EnableCheckingReg : std_logic_vector(32-C_ECC_ONOFF_WIDTH to 31);
    
    -- Fault Inject Registers
    signal FaultInjectData   : std_logic_vector(0 to C_LMB_DWIDTH-1);
    signal FaultInjectECC    : std_logic_vector(32-C_ECC_WIDTH to 31);

    -- Signals for read modify write operation when byte/half-word write
    signal write_access           : std_logic;
    signal full_word_write_access : std_logic;
    signal IsWordWrite            : std_logic;
    signal RdModifyWr_Read        : std_logic;  -- Read cycle in read modify write sequence 
    signal RdModifyWr_Modify      : std_logic;  -- Modify cycle in read modify write sequence 
    signal RdModifyWr_Modify_i    : std_logic;  -- Modify cycle in read modify write sequence 
    signal RdModifyWr_Write       : std_logic;  -- Write cycle in read modify write sequence 
    signal LMB_ABus_Q             : std_logic_vector(0 to C_LMB_AWIDTH-1);

    -- Read ECC
    signal Syndrome          : std_logic_vector(0 to C_ECC_WIDTH-1);
    signal CorrectedRdData   : std_logic_vector(0 to C_LMB_DWIDTH-1);
    signal CorrectedRdData_Q : std_logic_vector(0 to C_LMB_DWIDTH-1);
    signal CE_Q              : std_logic;
    signal UE_Q              : std_logic;

    -- Enable and address same for both data and ECC BRAM
    signal bram_en   : std_logic;
    signal bram_addr : std_logic_vector(0 to C_LMB_AWIDTH-1);

    subtype syndrome_bits is std_logic_vector(0 to 6);
    type correct_data_table_type is array(natural range 0 to 31) of syndrome_bits;
    constant correct_data_table : correct_data_table_type := (
      0 => "1100001",  1 => "1010001",  2 => "0110001",  3 => "1110001",
      4 => "1001001",  5 => "0101001",  6 => "1101001",  7 => "0011001",
      8 => "1011001",  9 => "0111001",  10 => "1111001",  11 => "1000101",
      12 => "0100101",  13 => "1100101",  14 => "0010101",  15 => "1010101",
      16 => "0110101",  17 => "1110101",  18 => "0001101",  19 => "1001101",
      20 => "0101101",  21 => "1101101",  22 => "0011101",  23 => "1011101",
      24 => "0111101",  25 => "1111101",  26 => "1000011",  27 => "0100011",
      28 => "1100011",  29 => "0010011",  30 => "1010011",  31 => "0110011"
      );

    type bool_array is array (natural range 0 to 6) of boolean;
    constant inverted_bit : bool_array := (false,false,true,false,true,false,false);
  begin

    -- Enable BRAMs when access on LMB and in the second cycle in a read/modify write
    bram_en <= '1' when LMB_AddrStrobe_i = '1' or RdModifyWr_Write = '1' else
               '0';

    BRAM_EN_A <= bram_en;

    IsWordWrite <= LMB_WriteStrobe_i when (LMB_BE_i = "1111") else '0';

    -- ECC checking enable during access and when checking is turned on
    enable_ecc <= ECC_EnableCheckingReg(C_ECC_ONOFF) and Sl_Wait_i and not(full_word_write_access);

    -----------------------------------------------------------------------------
    -- Writes are pipelined in MB with 5 stage pipeline
    -----------------------------------------------------------------------------
    Ready_Handling : process (LMB_Clk) is
    begin 
      if (LMB_Clk'event and LMB_Clk = '1') then
        if (LMB_Rst = '1') then
          Sl_Rdy <= '0';
          lmb_as <= '0';

        else
          -- Directly drive ready on valid read access or on valid word write access
          -- otherwise drive ready when we have written the new data on a
          -- readmodifywrite sequence
          Sl_Rdy <= ((LMB_AddrStrobe_i and lmb_select) and (LMB_ReadStrobe_i or IsWordWrite))                         
                        or RdModifyWr_Write;
          lmb_as <= LMB_AddrStrobe_i;
        end if;
      end if;
    end process Ready_Handling;

    Sl_Ready_i <= Sl_Rdy;

    Wait_Handling: process (LMB_Clk) is
    begin  -- process Wait_Handling
      if (LMB_Clk'event and LMB_Clk = '1') then  -- rising clock edge
        if (LMB_Rst = '1') then
          Sl_Wait_i <= '0';          
        elsif (LMB_AddrStrobe_i = '1') then
          Sl_Wait_i <= lmb_select;
        elsif (Sl_Rdy = '1') then
          Sl_Wait_i <= '0';
        end if;
      end if;
    end process Wait_Handling;

    -- Generate ECC bits for checking data read from BRAM
    checkbit_handler_I1 : checkbit_handler
      generic map (
        C_TARGET   => C_TARGET,
        C_ENCODE   => false)                 -- [boolean]
      port map (
        DataIn     => bram_din_a_i(0 to 31),   -- [in  std_logic_vector(0 to 31)]
        CheckIn    => bram_din_a_i(33 to 39),  -- [in  std_logic_vector(0 to 6)]
        CheckOut   => open,                    -- [out std_logic_vector(0 to 6)]
        Syndrome   => Syndrome,                -- [out std_logic_vector(0 to 6)]
        Enable_ECC => enable_ecc,              -- [in  std_logic]
        UE_Q       => UE_Q,                    -- [in  std_logic]
        CE_Q       => CE_Q,                    -- [in  std_logic]
        UE         => Sl_UE_i,                 -- [out std_logic]
        CE         => Sl_CE_i);                -- [out std_logic]

    -- Discrete error signals
    UE <= Sl_UE_i and Sl_Ready_i;
    CE <= Sl_CE_i and Sl_Ready_i;
    
    -- Correct Data
    Gen_Correct_Data: for I in 0 to 31 generate
      Correct_One_Bit_I : Correct_One_Bit
        generic map (
          C_TARGET      => C_TARGET,
          Correct_Value => correct_data_table(I))
        port map (
          DIn           => bram_din_a_i(I),
          Syndrome      => Syndrome,
          DCorr         => CorrectedRdData(I));
    end generate Gen_Correct_Data;

    -- Drive corrected read data on LMB 
    Sl_DBus_i <= CorrectedRdData;

    -- Remember address and writestrobe
    AddressReg : process(LMB_Clk) is
    begin
      if (LMB_Clk'event and LMB_Clk = '1') then
        if LMB_Rst = '1' then
          LMB_ABus_Q             <= (others => '0');
          write_access           <= '0';
          full_word_write_access <= '0';
        elsif LMB_AddrStrobe_i = '1' then
          LMB_ABus_Q             <= LMB_ABus_i;
          write_access           <= LMB_WriteStrobe_i;
          full_word_write_access <= LMB_BE_i(0) and LMB_BE_i(1) and LMB_BE_i(2) and LMB_BE_i(3) and LMB_WriteStrobe_i;
        end if;
      end if;
    end process AddressReg;

    bram_addr <= LMB_ABus_Q when RdModifyWr_Write = '1' else
                 LMB_ABus_i;
    
    BRAM_Addr_A <= bram_addr;

    Do_Writes : if (C_WRITE_ACCESS /= NO_WRITES) generate
      signal WrData  : std_logic_vector(0 to C_LMB_DWIDTH-1);
      signal WrECC   : std_logic_vector(0 to C_ECC_WIDTH-1);
      constant null7 : std_logic_vector(0 to 6) := "0000000";
    begin

      DO_BYTE_HALFWORD_WRITES : if (C_WRITE_ACCESS = ALL_WRITES) generate
        signal wrdata_i    : std_logic_vector(0 to C_LMB_DWIDTH-1);
        signal writeDBus_Q : std_logic_vector(0 to C_LMB_DWIDTH-1);
        signal lmb_be_q    : std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
      begin

        -- Remember correctable/uncorrectable error from read in read modify write
        CorrReg : process(LMB_Clk) is
        begin
          if (LMB_Clk'event and LMB_Clk = '1') then
            if RdModifyWr_Modify = '1' then   -- Remember error signals 
              CE_Q <= Sl_CE_i;
              UE_Q <= Sl_UE_i;
            elsif RdModifyWr_Write = '1' then   -- Keep the signals one more cycle
              CE_Q <= CE_Q;
              UE_Q <= UE_Q;
            else              
              CE_Q <= '0';
              UE_Q <= '0';
            end if;          
          end if;
        end process CorrReg;

        -- Remember byte write enables one clock cycle to properly mux bytes to write,
        -- with read data in read/modify write operation
        -- Write in Read/Write always 1 cycle after Read
        StoreLMB_WE : process(LMB_Clk) is
        begin
          if (LMB_Clk'event and LMB_Clk = '1') then
            RdModifyWr_Modify_i <= RdModifyWr_Read;
            RdModifyWr_Write    <= RdModifyWr_Modify;
            CorrectedRdData_Q   <= CorrectedRdData;
          end if;
        end process StoreLMB_WE;

        RdModifyWr_Modify <= RdModifyWr_Modify_i and lmb_as;
        
        RdModifyWr_Read  <= '1' when lmb_we /= "1111" and lmb_we /= "0000" and (C_WRITE_ACCESS = ALL_WRITES) else
                            '0';

        -- Remember write data one cycle to be available after read has been completed in a
        -- read/modify write operation
        StoreWriteDBus : process(LMB_Clk) is
        begin
          if (LMB_Clk'event and LMB_Clk = '1') then
            if (LMB_Rst = '1') then
              WriteDBus_Q <= (others => '0');
              lmb_be_q    <= (others => '0');
            elsif (LMB_AddrStrobe_i = '1') then
              WriteDBus_Q <= LMB_WriteDBus_i;
              lmb_be_q    <= LMB_BE_i;
            end if;
          end if;
        end process StoreWriteDBus;

        wrdata_i <= WriteDBus_Q when RdModifyWr_Write = '1' else LMB_WriteDBus_i;
        
        -- Select BRAM data to write from LMB on 32-bit word access or a mix of
        -- read data and LMB write data for read/modify write operations
        WrData(0 to 7)   <= wrdata_i(0 to 7) when ((RdModifyWr_Write = '0' and LMB_BE_i(0) = '1') or
                                                   (RdModifyWr_Write = '1' and lmb_be_q(0) = '1')) else
                            CorrectedRdData_Q(0 to 7);
        WrData(8 to 15)  <= wrdata_i(8 to 15) when ((RdModifyWr_Write = '0' and LMB_BE_i(1) = '1') or
                                                    (RdModifyWr_Write = '1' and lmb_be_q(1) = '1')) else
                            CorrectedRdData_Q(8 to 15);
        WrData(16 to 23) <= wrdata_i(16 to 23) when ((RdModifyWr_Write = '0' and LMB_BE_i(2) = '1') or
                                                     (RdModifyWr_Write = '1' and lmb_be_q(2) = '1')) else
                            CorrectedRdData_Q(16 to 23);
        WrData(24 to 31) <= wrdata_i(24 to 31) when ((RdModifyWr_Write = '0' and LMB_BE_i(3) = '1') or
                                                     (RdModifyWr_Write = '1' and lmb_be_q(3) = '1')) else
                            CorrectedRdData_Q(24 to 31);
        
      end generate DO_BYTE_HALFWORD_WRITES;

      DO_Only_Word_Writes : if (C_WRITE_ACCESS = ONLY_WORD) generate
        RdModifyWr_Write  <= '0';
        RdModifyWr_Read   <= '0';
        RdModifyWr_Modify <= '0';
        CorrectedRdData_Q <= (others => '0');
        WrData            <= LMB_WriteDBus_i;
        CE_Q              <= '0';
        UE_Q              <= '0';
      end generate DO_Only_Word_Writes;

      -- Generate BRAM WEN, which will always be all 1's due to read modify write
      -- for non 32-bit word access
      WrDataSel : process(IsWordWrite, lmb_select, RdModifyWr_Modify, RdModifyWr_Write, UE_Q)
      begin
        if (RdModifyWr_Modify = '1') then
          BRAM_WEN_A <= (others => '0');          
        elsif (RdModifyWr_Write = '1') then
          if (UE_Q = '0') then
            BRAM_WEN_A <= (others => '1');  -- byte or half word write, and not UE
          else
            BRAM_WEN_A <= (others => '0');          
          end if;
        elsif (IsWordWrite = '1') then           -- word write
          BRAM_WEN_A <= (others => lmb_select);
        else
          BRAM_WEN_A <= (others => '0');
        end if;
      end process WrDataSel;
      
      -- Generate ECC bits for writing into BRAM      
      checkbit_handler_I2 : checkbit_handler
        generic map (
          C_TARGET   => C_TARGET,
          C_ENCODE   => true)           -- [boolean]
        port map (
          DataIn     => WrData,         -- [in  std_logic_vector(0 to 31)]
          CheckIn    => null7,          -- [in  std_logic_vector(0 to 6)]
          CheckOut   => WrECC,          -- [out std_logic_vector(0 to 6)]
          Syndrome   => open,           -- [out std_logic_vector(0 to 6)]
          Enable_ECC => '1',            -- [in  std_logic]
          UE_Q       => '0',            -- [in  std_logic]
          CE_Q       => '0',            -- [in  std_logic]
          UE         => open,           -- [out std_logic]
          CE         => open);          -- [out std_logic]
      
      -- Drive BRAM write data and inject fault if applicable
      BRAM_Dout_A(0 to 31)  <= WrData xor FaultInjectData;
      BRAM_Dout_A(32 to 39) <= ('0' & WrECC) xor ('0' & FaultInjectECC);
      
    end generate Do_Writes;

    No_Write_Accesses : if (C_WRITE_ACCESS = NO_WRITES) generate
      RdModifyWr_Write  <= '0';
      RdModifyWr_Read   <= '0';
      RdModifyWr_Modify <= '0';
      CorrectedRdData_Q <= (others => '0');
      FaultInjectData   <= (others => '0');
      FaultInjectECC    <= (others => '0');
      CE_Q              <= '0';
      UE_Q              <= '0';
      BRAM_WEN_A        <= (others => '0');
    end generate No_Write_Accesses;

    Has_AXI : if C_HAS_AXI generate

      -- Register accesses
      -- Register addresses use word address, i.e 2 LSB don't care
      -- Don't decode MSB, i.e. mirroring of registers in address space of module
      -- Don't decode unmapped addresses
      -- Data registers occupy 32 words to accommodate up to 1024-bit words in other IPs
      -- ECC registers occupy 16 words to accomodate up to 512-bit ECC in other IPs
      -- Address registers occupy 2 words to accommodate 64-bit address in other IPs
      constant C_REGADDR_WIDTH     : integer          := 8;
      constant C_ECC_StatusReg     : std_logic_vector := "00000000";  -- 0x000 ECC_STATUS
      constant C_ECC_EnableIRQReg  : std_logic_vector := "00000001";  -- 0x004 ECC_EN_IRQ
      constant C_ECC_OnOffReg      : std_logic_vector := "00000010";  -- 0x008 ECC_ONOFF
      constant C_CE_CounterReg     : std_logic_vector := "00000011";  -- 0x00C CE_CNT
      constant C_CE_FailingData    : std_logic_vector := "01000000";  -- 0x100 CE_FFD[31:0]
      constant C_CE_FailingECC     : std_logic_vector := "01100000";  -- 0x180 CE_FFE
      constant C_CE_FailingAddress : std_logic_vector := "01110000";  -- 0x1C0 CE_FFA[31:0]
      constant C_UE_FailingData    : std_logic_vector := "10000000";  -- 0x200 UE_FFD[31:0]
      constant C_UE_FailingECC     : std_logic_vector := "10100000";  -- 0x280 UE_FFE
      constant C_UE_FailingAddress : std_logic_vector := "10110000";  -- 0x2C0 UE_FFA[31:0]
      constant C_FaultInjectData   : std_logic_vector := "11000000";  -- 0x300 FI_D[31:0]
      constant C_FaultInjectECC    : std_logic_vector := "11100000";  -- 0x380 FI_ECC

      -- ECC Status register bit positions
      constant C_ECC_STATUS_CE        : natural := 30;
      constant C_ECC_STATUS_UE        : natural := 31;
      constant C_ECC_STATUS_WIDTH     : natural := 2;
      constant C_ECC_ENABLE_IRQ_CE    : natural := 30;
      constant C_ECC_ENABLE_IRQ_UE    : natural := 31;
      constant C_ECC_ENABLE_IRQ_WIDTH : natural := 2;

      -- Read and write data to internal registers
      constant C_DWIDTH : integer := 32;
      signal RegWrData  : std_logic_vector(0 to C_DWIDTH-1);
      signal RegRdData  : std_logic_vector(0 to C_DWIDTH-1);
      signal RegAddr    : std_logic_vector(0 to C_REGADDR_WIDTH-1); 
      signal RegWr      : std_logic;

      -- Correctable Error First Failing Register
      signal CE_FailingAddress : std_logic_vector(0 to C_LMB_AWIDTH-1);
      signal CE_FailingData    : std_logic_vector(0 to C_LMB_DWIDTH-1);
      signal CE_FailingECC     : std_logic_vector(32-C_ECC_WIDTH to 31);
      -- Uncorrectable Error First Failing Register
      signal UE_FailingAddress : std_logic_vector(0 to C_LMB_AWIDTH-1);
      signal UE_FailingData    : std_logic_vector(0 to C_LMB_DWIDTH-1);
      signal UE_FailingECC     : std_logic_vector(32-C_ECC_WIDTH to 31);
      -- ECC Status and Control register
      signal ECC_StatusReg     : std_logic_vector(32-C_ECC_STATUS_WIDTH to 31);
      signal ECC_EnableIRQReg  : std_logic_vector(32-C_ECC_ENABLE_IRQ_WIDTH to 31);

      -- Correctable Error Counter
      signal CE_CounterReg     : std_logic_vector(32-C_CE_COUNTER_WIDTH to 31);

      signal sample_registers : std_logic;      

    begin

      sample_registers <= lmb_as and not full_word_write_access;
        
      -- Implement fault injection registers
      Fault_Inject : if C_HAS_FAULT_INJECT and (C_WRITE_ACCESS /= NO_WRITES) generate
      begin
        FaultInjectDataReg : process(LMB_Clk) is
        begin
          if LMB_Clk'event and LMB_Clk = '1' then
            if LMB_Rst = '1' then
              FaultInjectData <= (others => '0');
              FaultInjectECC  <= (others => '0');
            elsif RegWr = '1' and RegAddr = C_FaultInjectData then
              FaultInjectData <= RegWrData;
            elsif RegWr = '1' and RegAddr = C_FaultInjectECC then
              FaultInjectECC  <= RegWrData(FaultInjectECC'range);
            elsif (Sl_Rdy = '1') and (write_access = '1') then  -- One shoot, clear after first LMB write
              FaultInjectData <= (others => '0');
              FaultInjectECC  <= (others => '0');
            end if;
          end if;
        end process FaultInjectDataReg;
      end generate Fault_Inject;

      No_Fault_Inject : if not C_HAS_FAULT_INJECT or (C_WRITE_ACCESS = NO_WRITES) generate
      begin
        FaultInjectData <= (others => '0');
        FaultInjectECC  <= (others => '0');
      end generate No_Fault_Inject;
      
      -- Implement Correctable Error First Failing Register
      CE_Failing_Registers : if C_HAS_CE_FAILING_REGISTERS generate
      begin
        CE_FailingReg : process(LMB_Clk) is
        begin
          if LMB_Clk'event and LMB_Clk = '1' then
            if LMB_Rst = '1' then
              CE_FailingAddress <= (others => '0');
              CE_FailingData    <= (others => '0');
              CE_FailingECC     <= (others => '0');
            elsif Sl_CE_i = '1' and sample_registers = '1' and ECC_StatusReg(C_ECC_STATUS_CE) = '0' then
              CE_FailingAddress <= LMB_ABus_Q;
              CE_FailingData    <= bram_din_a_i(CE_FailingData'range);
              CE_FailingECC     <= bram_din_a_i(33 to 33+C_ECC_WIDTH-1);
            end if;
          end if;
        end process CE_FailingReg;
      end generate CE_Failing_Registers;
      
      No_CE_Failing_Registers : if not C_HAS_CE_FAILING_REGISTERS generate
      begin
        CE_FailingAddress <= (others => '0');
        CE_FailingData    <= (others => '0');
        CE_FailingECC     <= (others => '0');
      end generate No_CE_Failing_Registers;
      
      -- Implement Unorrectable Error First Failing Register
      UE_Failing_Registers : if C_HAS_UE_FAILING_REGISTERS generate
      begin
        UE_FailingReg : process(LMB_Clk) is
        begin
          if LMB_Clk'event and LMB_Clk = '1' then
            if LMB_Rst = '1' then
              UE_FailingAddress <= (others => '0');
              UE_FailingData    <= (others => '0');
              UE_FailingECC     <= (others => '0');
            elsif Sl_UE_i = '1' and sample_registers = '1' and ECC_StatusReg(C_ECC_STATUS_UE) = '0' then
              UE_FailingAddress <= LMB_ABus_Q;
              UE_FailingData    <= bram_din_a_i(UE_FailingData'range);
              UE_FailingECC     <= bram_din_a_i(33 to 33+C_ECC_WIDTH-1);
            end if;
          end if;
        end process UE_FailingReg;
      end generate UE_Failing_Registers;
      
      No_UE_Failing_Registers : if not C_HAS_UE_FAILING_REGISTERS generate
      begin
        UE_FailingAddress <= (others => '0');
        UE_FailingData    <= (others => '0');
        UE_FailingECC     <= (others => '0');
      end generate No_UE_Failing_Registers;
      
      ECC_Status_Registers : if C_HAS_ECC_STATUS_REGISTERS generate
      begin

        StatusReg : process(LMB_Clk) is
        begin
          if LMB_Clk'event and LMB_Clk = '1' then
            if LMB_Rst = '1' then
              ECC_StatusReg <= (others => '0');
            elsif RegWr = '1' and RegAddr = C_ECC_StatusReg then
              -- CE Interrupt status bit
              if RegWrData(C_ECC_STATUS_CE) = '1' then
                ECC_StatusReg(C_ECC_STATUS_CE) <= '0';  -- Clear when write '1'
              end if;
              -- UE Interrupt status bit
              if RegWrData(C_ECC_STATUS_UE) = '1' then
                ECC_StatusReg(C_ECC_STATUS_UE) <= '0';  -- Clear when write '1'
              end if;
            else
              if Sl_CE_i = '1' and sample_registers = '1' then
                ECC_StatusReg(C_ECC_STATUS_CE) <= '1';  -- Set when CE occurs
              end if;
              if Sl_UE_i = '1' and sample_registers = '1' then
                ECC_StatusReg(C_ECC_STATUS_UE) <= '1';  -- Set when UE occurs
              end if;
            end if;
          end if;    
        end process StatusReg;

        EnableIRQReg : process(LMB_Clk) is
        begin
          if LMB_Clk'event and LMB_Clk = '1' then
            if LMB_Rst = '1' then
              ECC_EnableIRQReg <= (others => '0');
            elsif RegWr = '1' and RegAddr = C_ECC_EnableIRQReg then
              -- CE Interrupt enable bit
              ECC_EnableIRQReg(C_ECC_ENABLE_IRQ_CE) <= RegWrData(C_ECC_ENABLE_IRQ_CE);
              -- UE Interrupt enable bit
              ECC_EnableIRQReg(C_ECC_ENABLE_IRQ_UE) <= RegWrData(C_ECC_ENABLE_IRQ_UE);
            end if;
          end if;    
        end process EnableIRQReg;
        
        Interrupt <= (ECC_StatusReg(C_ECC_STATUS_CE) and ECC_EnableIRQReg(C_ECC_ENABLE_IRQ_CE)) or 
                     (ECC_StatusReg(C_ECC_STATUS_UE) and ECC_EnableIRQReg(C_ECC_ENABLE_IRQ_UE));

      end generate ECC_Status_Registers;

      No_ECC_Status_Registers : if not C_HAS_ECC_STATUS_REGISTERS generate
      begin
        ECC_EnableIRQReg <= (others => '0');
        ECC_StatusReg    <= (others => '0');
        Interrupt        <= '0';
      end generate No_ECC_Status_Registers;

      ECC_OnOff_Register : if C_HAS_ECC_ONOFF_REGISTER generate
      begin

        OnOffReg : process(LMB_Clk) is
        begin
          if LMB_Clk'event and LMB_Clk = '1' then
            if LMB_Rst = '1' then
              if C_ECC_ONOFF_RESET_VALUE = 0 then
                 ECC_EnableCheckingReg(C_ECC_ONOFF) <= '0';
              else
                 ECC_EnableCheckingReg(C_ECC_ONOFF) <= '1';
              end if;  
            elsif RegWr = '1' and RegAddr = C_ECC_OnOffReg then
              ECC_EnableCheckingReg(C_ECC_ONOFF) <= RegWrData(C_ECC_ONOFF);
            end if;
          end if;    
        end process OnOffReg;

      end generate ECC_OnOff_Register;

      No_ECC_OnOff_Register : if not C_HAS_ECC_ONOFF_REGISTER generate
      begin
        ECC_EnableCheckingReg(C_ECC_ONOFF) <= '1';
      end generate No_ECC_OnOff_Register;

      CE_Counter : if C_HAS_CE_COUNTER generate
        -- One extra bit compare to CE_CounterReg to handle carry bit
        signal CE_CounterReg_plus_1 : std_logic_vector(31-C_CE_COUNTER_WIDTH to 31);
      begin

        CountReg : process(LMB_Clk) is
        begin
          if (LMB_Clk'event and LMB_Clk = '1') then
            if (LMB_Rst = '1') then
              CE_CounterReg <= (others => '0');
            elsif RegWr = '1' and RegAddr = C_CE_CounterReg then
              CE_CounterReg <= RegWrData(CE_CounterReg'range);
            elsif Sl_CE_i = '1' and
                  sample_registers = '1' and
                  CE_CounterReg_plus_1(CE_CounterReg_plus_1'left) = '0' then
              CE_CounterReg <= CE_CounterReg_plus_1(32-C_CE_COUNTER_WIDTH to 31);
            end if;
          end if;
        end process CountReg;

        CE_CounterReg_plus_1 <= std_logic_vector(unsigned(('0' & CE_CounterReg)) + 1);
        
      end generate CE_Counter;

      No_CE_Counter : if not C_HAS_CE_COUNTER generate
      begin
        CE_CounterReg <= (others => '0');
      end generate No_CE_Counter;

      SelRegRdData : process (RegAddr,
                              ECC_StatusReg, ECC_EnableIRQReg, ECC_EnableCheckingReg, CE_CounterReg,
                              CE_FailingAddress, CE_FailingData, CE_FailingECC,
                              UE_FailingAddress, UE_FailingData, UE_FailingECC)
      begin
        RegRdData <= (others => '0');

        case RegAddr is
          when C_ECC_StatusReg     => RegRdData(ECC_StatusReg'range)          <= ECC_StatusReg;
          when C_ECC_EnableIRQReg  => RegRdData(ECC_EnableIRQReg'range)       <= ECC_EnableIRQReg;
          when C_ECC_OnOffReg      => RegRdData(ECC_EnableCheckingReg'range)  <= ECC_EnableCheckingReg;
          when C_CE_CounterReg     => RegRdData(CE_CounterReg'range)          <= CE_CounterReg;
          when C_CE_FailingAddress => RegRdData(CE_FailingAddress'range)      <= CE_FailingAddress;
          when C_CE_FailingData    => RegRdData(CE_FailingData'range)         <= CE_FailingData;
          when C_CE_FailingECC     => RegRdData(CE_FailingECC'range)          <= CE_FailingECC;
          when C_UE_FailingAddress => RegRdData(UE_FailingAddress'range)      <= UE_FailingAddress;
          when C_UE_FailingData    => RegRdData(UE_FailingData'range)         <= UE_FailingData;
          when C_UE_FailingECC     => RegRdData(UE_FailingECC'range)          <= UE_FailingECC;
          when others              => RegRdData                               <= (others => '0');
        end case;
      end process SelRegRdData;

      AXI : if C_HAS_AXI generate
      begin
        axi_I : axi_interface 
        generic map(
          C_TARGET           => C_TARGET,
          C_S_AXI_BASEADDR   => C_S_AXI_CTRL_BASEADDR,
          C_S_AXI_HIGHADDR   => C_S_AXI_CTRL_HIGHADDR,
          C_S_AXI_ADDR_WIDTH => C_S_AXI_CTRL_ADDR_WIDTH,
          C_S_AXI_DATA_WIDTH => C_S_AXI_CTRL_DATA_WIDTH,
          C_REGADDR_WIDTH    => C_REGADDR_WIDTH,
          C_DWIDTH           => C_DWIDTH)
        port map (
          LMB_Clk       => LMB_Clk,
          LMB_Rst       => LMB_Rst,
          S_AXI_AWADDR  => S_AXI_CTRL_AWADDR,
          S_AXI_AWVALID => S_AXI_CTRL_AWVALID,
          S_AXI_AWREADY => S_AXI_CTRL_AWREADY,
          S_AXI_WDATA   => S_AXI_CTRL_WDATA,
          S_AXI_WSTRB   => S_AXI_CTRL_WSTRB,
          S_AXI_WVALID  => S_AXI_CTRL_WVALID,
          S_AXI_WREADY  => S_AXI_CTRL_WREADY,
          S_AXI_BRESP   => S_AXI_CTRL_BRESP,
          S_AXI_BVALID  => S_AXI_CTRL_BVALID,
          S_AXI_BREADY  => S_AXI_CTRL_BREADY,
          S_AXI_ARADDR  => S_AXI_CTRL_ARADDR,
          S_AXI_ARVALID => S_AXI_CTRL_ARVALID,
          S_AXI_ARREADY => S_AXI_CTRL_ARREADY,
          S_AXI_RDATA   => S_AXI_CTRL_RDATA,
          S_AXI_RRESP   => S_AXI_CTRL_RRESP,
          S_AXI_RVALID  => S_AXI_CTRL_RVALID,
          S_AXI_RREADY  => S_AXI_CTRL_RREADY,
          RegWr         => RegWr,
          RegWrData     => RegWrData,
          RegAddr       => RegAddr,
          RegRdData     => RegRdData);
      end generate AXI;

    end generate Has_AXI;

    No_AXI : if not C_HAS_AXI generate
    begin
      FaultInjectData <= (others => '0');
      FaultInjectECC  <= (others => '0');
      Interrupt       <= '0';

      ECC_EnableCheckingReg(C_ECC_ONOFF) <= '1';
    end generate No_AXI;

  end generate ECC;

  No_AXI_ECC : if not C_HAS_AXI generate
  begin
    S_AXI_CTRL_AWREADY <= '0';
    S_AXI_CTRL_WREADY  <= '0';
    S_AXI_CTRL_BRESP   <= (others => '0');
    S_AXI_CTRL_BVALID  <= '0';
    S_AXI_CTRL_ARREADY <= '0';
    S_AXI_CTRL_RDATA   <= (others => '0');
    S_AXI_CTRL_RRESP   <= (others => '0');
    S_AXI_CTRL_RVALID  <= '0';
  end generate No_AXI_ECC;

end architecture imp;
