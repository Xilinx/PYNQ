-------------------------------------------------------------------------------
-- parityenable.vhd - Entity and architecture
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
-- Filename:        parity.vhd
--
-- Description:     Generate parity optimally for all target architectures
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  parity.vhd
--                    xor18.vhd
--                    parity_recursive_LUT6.vhd
--
-------------------------------------------------------------------------------
-- Author:          stefana
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

library lmb_bram_if_cntlr_v4_0_7;
use lmb_bram_if_cntlr_v4_0_7.all;
use lmb_bram_if_cntlr_v4_0_7.lmb_bram_if_funcs.all;

entity ParityEnable is
  generic (
    C_TARGET   : TARGET_FAMILY_TYPE;
    C_SIZE     :     integer := 4
    );
  port (
    InA        : in  std_logic_vector(0 to C_SIZE - 1);
    Enable     : in  std_logic;
    Res        : out std_logic
    );
end entity ParityEnable;

architecture IMP of ParityEnable is

  -- Non-recursive loop implementation
  function ParityGen (InA : std_logic_vector) return std_logic is
    variable result : std_logic;
  begin
    result := '0';
    for I in InA'range loop
      result := result xor InA(I);
    end loop;
    return result;
  end function ParityGen;

  component MB_LUT6 is
  generic (
    C_TARGET : TARGET_FAMILY_TYPE;
    INIT     : bit_vector := X"0000000000000000"
  );
  port (
    O  : out std_logic;
    I0 : in  std_logic;
    I1 : in  std_logic;
    I2 : in  std_logic;
    I3 : in  std_logic;
    I4 : in  std_logic;
    I5 : in  std_logic
  );
  end component MB_LUT6;

begin  -- architecture IMP

  Using_FPGA: if ( C_TARGET /= RTL ) generate 

    --------------------------------------------------------------------------------------------------
    -- Single LUT6
    --------------------------------------------------------------------------------------------------
    Single_LUT6 : if C_SIZE > 1 and C_SIZE <= 5 generate
      signal inA5 : std_logic_vector(0 to 4);
    begin

      Assign_InA : process (InA) is
      begin
        inA5                      <= (others => '0');
        inA5(0 to InA'length - 1) <= InA;
      end process Assign_InA;

      XOR6_LUT : MB_LUT6
        generic map(
          C_TARGET => C_TARGET,
          INIT => X"9669699600000000")
        port map(
          O  => Res,
          I0 => InA5(4),
          I1 => inA5(3),
          I2 => inA5(2),
          I3 => inA5(1),
          I4 => inA5(0),
          I5 => Enable);
    end generate Single_LUT6;

  end generate Using_FPGA;

  Using_RTL: if ( C_TARGET = RTL ) generate 
  begin
    Res <= Enable and ParityGen(InA);
  end generate Using_RTL;

end architecture IMP;
