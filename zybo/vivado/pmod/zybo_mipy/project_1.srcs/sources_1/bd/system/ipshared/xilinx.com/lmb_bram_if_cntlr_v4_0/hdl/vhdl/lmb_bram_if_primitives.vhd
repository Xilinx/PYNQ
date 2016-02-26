-------------------------------------------------------------------------------
-- primitives.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2015 Xilinx, Inc. All rights reserved.
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
-- Filename:        primitives.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              lmb_bram_if_primitives.vhd
--
-------------------------------------------------------------------------------
-- Author:          rolandp
--
-- History:
--   rolandp  2015-01-22    First Version
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

----- entity LUT6 -----
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library lmb_bram_if_cntlr_v4_0_7;
use lmb_bram_if_cntlr_v4_0_7.lmb_bram_if_funcs.all;

entity MB_LUT6 is
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
end entity MB_LUT6;

library Unisim;
use Unisim.vcomponents.all;

architecture IMP of MB_LUT6 is
begin
  
  Using_RTL: if ( C_TARGET = RTL ) generate 
    constant INIT_reg : std_logic_vector(63 downto 0) := To_StdLogicVector(INIT);
  begin
    process (I0, I1, I2, I3, I4, I5)
      variable I_reg    : std_logic_vector(5 downto 0);
      variable I0_v, I1_v, I2_v, I3_v, I4_v, I5_v : std_logic;
    begin
      -- Filter unknowns
      if I0 = '0' then I0_v := '0'; else I0_v := '1'; end if;
      if I1 = '0' then I1_v := '0'; else I1_v := '1'; end if;
      if I2 = '0' then I2_v := '0'; else I2_v := '1'; end if;
      if I3 = '0' then I3_v := '0'; else I3_v := '1'; end if;
      if I4 = '0' then I4_v := '0'; else I4_v := '1'; end if;
      if I5 = '0' then I5_v := '0'; else I5_v := '1'; end if;
      I_reg := TO_STDLOGICVECTOR(I5_v & I4_v & I3_v &  I2_v & I1_v & I0_v);
      O     <= INIT_reg(TO_INTEGER(unsigned(I_reg)));
    end process;
  end generate Using_RTL;
  
  Using_FPGA: if ( C_TARGET /= RTL ) generate 
  begin
    Native: LUT6
      generic map(
        INIT    => INIT
      )
      port map(
        O       => O,
        I0      => I0,
        I1      => I1,
        I2      => I2,
        I3      => I3,
        I4      => I4,
        I5      => I5
      );
  end generate Using_FPGA;
  
end architecture IMP;

----- entity MUXCY -----
library IEEE;
use IEEE.std_logic_1164.all;

library lmb_bram_if_cntlr_v4_0_7;
use lmb_bram_if_cntlr_v4_0_7.lmb_bram_if_funcs.all;

entity MB_MUXCY is
  generic (
    C_TARGET : TARGET_FAMILY_TYPE
  );
  port (
    LO : out std_logic;
    CI : in  std_logic;
    DI : in  std_logic;
    S  : in  std_logic
  );
end entity MB_MUXCY;

library Unisim;
use Unisim.vcomponents.all;

architecture IMP of MB_MUXCY is
begin
  
  Using_RTL: if ( C_TARGET = RTL ) generate 
  begin
    LO <= DI when S = '0' else CI;
  end generate Using_RTL;
  
  Using_FPGA: if ( C_TARGET /= RTL ) generate 
  begin
    Native: MUXCY_L
      port map(
        LO => LO,
        CI => CI,
        DI => DI,
        S  => S
      );
  end generate Using_FPGA;
  
end architecture IMP;

----- entity XORCY -----
library IEEE;
use IEEE.std_logic_1164.all;

library lmb_bram_if_cntlr_v4_0_7;
use lmb_bram_if_cntlr_v4_0_7.lmb_bram_if_funcs.all;

entity MB_XORCY is
  generic (
    C_TARGET : TARGET_FAMILY_TYPE
  );
  port (
    O  : out std_logic;
    CI : in  std_logic;
    LI : in  std_logic
  );
end entity MB_XORCY;

library Unisim;
use Unisim.vcomponents.all;

architecture IMP of MB_XORCY is
begin
  
  Using_RTL: if ( C_TARGET = RTL ) generate 
  begin
    O <= (CI xor LI);
  end generate Using_RTL;
  
  Using_FPGA: if ( C_TARGET /= RTL ) generate 
  begin
    Native: XORCY
      port map(
        O  => O,
        CI => CI,
        LI => LI
      );
  end generate Using_FPGA;
  
end architecture IMP;

----- entity MUXF7 -----
library IEEE;
use IEEE.std_logic_1164.all;

library lmb_bram_if_cntlr_v4_0_7;
use lmb_bram_if_cntlr_v4_0_7.lmb_bram_if_funcs.all;

entity MB_MUXF7 is
  generic (
    C_TARGET : TARGET_FAMILY_TYPE
  );
  port (
    O  : out std_logic;
    I0 : in  std_logic;
    I1 : in  std_logic;
    S  : in  std_logic
  );
end entity MB_MUXF7;

library Unisim;
use Unisim.vcomponents.all;

architecture IMP of MB_MUXF7 is
begin
  
  Using_RTL: if ( C_TARGET = RTL ) generate 
  begin
    O <= I0 when S = '0' else I1;
  end generate Using_RTL;
  
  Using_FPGA: if ( C_TARGET /= RTL ) generate 
  begin
    Native: MUXF7
      port map(
        O  => O,
        I0 => I0,
        I1 => I1,
        S  => S
      );
  end generate Using_FPGA;
  
end architecture IMP;

----- entity MUXF8 -----
library IEEE;
use IEEE.std_logic_1164.all;

library lmb_bram_if_cntlr_v4_0_7;
use lmb_bram_if_cntlr_v4_0_7.lmb_bram_if_funcs.all;

entity MB_MUXF8 is
  generic (
    C_TARGET : TARGET_FAMILY_TYPE
  );
  port (
    O  : out std_logic;
    I0 : in  std_logic;
    I1 : in  std_logic;
    S  : in  std_logic
  );
end entity MB_MUXF8;

library Unisim;
use Unisim.vcomponents.all;

architecture IMP of MB_MUXF8 is
begin
  
  Using_RTL: if ( C_TARGET = RTL ) generate 
  begin
    O <= I0 when S = '0' else I1;
  end generate Using_RTL;
  
  Using_FPGA: if ( C_TARGET /= RTL ) generate 
  begin
    Native: MUXF8
      port map(
        O  => O,
        I0 => I0,
        I1 => I1,
        S  => S
      );
  end generate Using_FPGA;
  
end architecture IMP;

----- entity FDRE -----
library IEEE;
use IEEE.std_logic_1164.all;

library lmb_bram_if_cntlr_v4_0_7;
use lmb_bram_if_cntlr_v4_0_7.lmb_bram_if_funcs.all;

entity MB_FDRE is
  generic (
    C_TARGET : TARGET_FAMILY_TYPE;
    INIT : bit := '0'
  );
  port(
    Q  : out std_logic;
    C  : in  std_logic;
    CE : in  std_logic;
    D  : in  std_logic;
    R  : in  std_logic
  );
end entity MB_FDRE;

library Unisim;
use Unisim.vcomponents.all;

architecture IMP of MB_FDRE is
begin
  
  Using_RTL: if ( C_TARGET = RTL ) generate 
    function To_StdLogic(A : in bit ) return std_logic is
    begin
      if( A = '1' ) then
        return '1';
      end if;
      return '0';
    end;

    signal q_o : std_logic := To_StdLogic(INIT);
  begin
    Q <=  q_o;
    process(C)
    begin
      if (rising_edge(C)) then
        if (R = '1') then
          q_o <= '0';
        elsif (CE = '1') then
          q_o <= D;
        end if;
      end if;
    end process;
  end generate Using_RTL;
  
  Using_FPGA: if ( C_TARGET /= RTL ) generate 
  begin
    Native: FDRE
      generic map(
        INIT => INIT
      )
      port map(
        Q   => Q,
        C   => C,
        CE  => CE,
        D   => D,
        R   => R
      );
  end generate Using_FPGA;
  
end architecture IMP;

