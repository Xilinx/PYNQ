-------------------------------------------------------------------------------
-- mdm_primitives.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2014 Xilinx, Inc. All rights reserved.
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
-------------------------------------------------------------------------------
-- Filename:        mdm_primitives.vhd
--
-- Description:     one bit AND function using carry-chain
--
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              mdm_primitives.vhd
--
-------------------------------------------------------------------------------
-- Author:          stefana
--
-- History:
--   stefana  2014-05-23    First Version
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
library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity carry_and is
  port (
    Carry_IN  : in  std_logic;
    A         : in  std_logic;
    Carry_OUT : out std_logic);
end entity carry_and;

architecture IMP of carry_and is
  signal carry_out_i : std_logic;
begin  -- architecture IMP

  MUXCY_I : MUXCY_L
    port map (
      DI => '0',
      CI => Carry_IN,
      S  => A,
      LO => carry_out_i);    

  Carry_OUT <= carry_out_i;

end architecture IMP;

library IEEE;
use IEEE.std_logic_1164.all;

entity carry_or_vec is
  generic (
    Size : natural);
  port (
    Carry_In  : in std_logic;
    In_Vec    : in  std_logic_vector(0 to Size-1);
    Carry_Out : out std_logic);
end entity carry_or_vec;

library unisim;
use unisim.vcomponents.all;

architecture IMP of carry_or_vec is

  constant C_BITS_PER_LUT : natural := 6;

  signal sel   : std_logic_vector(0 to ((Size+(C_BITS_PER_LUT - 1))/C_BITS_PER_LUT) - 1);
  signal carry : std_logic_vector(0 to ((Size+(C_BITS_PER_LUT - 1))/C_BITS_PER_LUT));

  signal sig1  : std_logic_vector(0 to sel'length*C_BITS_PER_LUT - 1);

begin  -- architecture IMP

  assign_sigs : process (In_Vec) is
  begin  -- process assign_sigs
    sig1               <= (others => '0');
    sig1(0 to Size-1)  <= In_Vec;
  end process assign_sigs;

  carry(carry'right) <= Carry_In;

  The_Compare : for I in sel'right downto sel'left generate
  begin
    Compare_All_Bits: process(sig1)
      variable sel_I   : std_logic;
    begin
      sel_I  :=  '0';
      Compare_Bits: for J in C_BITS_PER_LUT - 1 downto 0 loop
        sel_I  := sel_I or ( sig1(C_BITS_PER_LUT * I + J) );
      end loop Compare_Bits;
      sel(I) <= not sel_I;
    end process Compare_All_Bits;

    MUXCY_L_I1 : MUXCY_L
      port map (
        DI => '1',                      -- [in  std_logic S = 0]
        CI => Carry(I+1),               -- [in  std_logic S = 1]
        S  => sel(I),                   -- [in  std_logic (Select)]
        LO => Carry(I));                -- [out std_logic]    
  end generate The_Compare;

  Carry_Out <= Carry(0);

end architecture IMP;

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity carry_or is
  port (
    Carry_IN  : in  std_logic;
    A         : in  std_logic;
    Carry_OUT : out std_logic);
end entity carry_or;

architecture IMP of carry_or is
  signal carry_out_i : std_logic;
  signal A_N : std_logic;

begin  -- architecture IMP

  A_N <= not A;

  MUXCY_I : MUXCY_L
    port map (
      DI => '1',
      CI => Carry_IN,
      S  => A_N,
      LO => carry_out_i);

  Carry_OUT <= carry_out_i;

end architecture IMP;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity select_bit is
  generic (
    sel_value : std_logic_vector(1 downto 0));
  port (
    Mask      : in  std_logic_vector(1 downto 0);
    Request   : in  std_logic_vector(1 downto 0);
    Carry_In  : in  std_logic;
    Carry_Out : out std_logic);
end entity select_bit;

architecture IMP of select_bit is

  signal di  : std_logic;
  signal sel : std_logic;

begin  -- architecture IMP

  -- Just pass the carry value if none is requesting or is enabled
  sel <= not( (Request(1) and Mask(1)) or (Request(0) and Mask(0)));
  
  di <= ((Request(0) and Mask(0) and sel_value(0))) or
        ( not(Request(0) and Mask(0)) and Request(1) and Mask(1) and sel_value(1));
  
  MUXCY_I : MUXCY_L
    port map (
      DI => di,
      CI => Carry_In,
      S  => sel,
      LO => Carry_Out);

end architecture IMP;
