-------------------------------------------------------------------------------
-- pselect_mask.vhd - Entity and architecture
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
-- Filename:        pselect_mask.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              pselect_mask.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
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
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity pselect_mask is

  generic (
    C_AW   : integer                   := 32;
    C_BAR  : std_logic_vector(0 to 31) := "00000000000000100000000000000000";
    C_MASK : std_logic_vector(0 to 31) := "00000000000001111100000000000000"
    );
  port (
    A     : in  std_logic_vector(0 to C_AW-1);
    Valid : in  std_logic;
    CS    : out std_logic
    );

end entity pselect_mask;

architecture imp of pselect_mask is

  function Nr_Of_Ones (S : std_logic_vector) return natural is
    variable tmp : natural := 0;
  begin  -- function Nr_Of_Ones
    for I in S'range loop
      if (S(I) = '1') then
        tmp := tmp + 1;
      end if;
    end loop;  -- I
    return tmp;
  end function Nr_Of_Ones;

  function fix_AB (B : boolean; I : integer) return integer is
  begin  -- function fix_AB
    if (not B) then
      return I + 1;
    else
      return I;
    end if;
  end function fix_AB;

  constant Nr      : integer := Nr_Of_Ones(C_MASK);
  constant Use_CIN : boolean := ((Nr mod 4) = 0);
  constant AB      : integer := fix_AB(Use_CIN, Nr);
  
  attribute INIT : string;

  constant NUM_LUTS    : integer := (AB-1)/4+1;

  -- function to initialize LUT within pselect 
  type int4 is array (3 downto 0) of integer;
  function pselect_init_lut(i        : integer;
                            AB       : integer;
                            NUM_LUTS : integer;
                            C_AW     : integer;
                            C_BAR    : std_logic_vector(0 to 31)) 
    return bit_vector is
    variable init_vector : bit_vector(15 downto 0) := X"0001";
    variable j           : integer                 := 0;
    variable val_in      : int4;
  begin
    for j in 0 to 3 loop
      if i < NUM_LUTS-1 or j <= ((AB-1) mod 4) then
        val_in(j) := conv_integer(C_BAR(i*4+j));
      else val_in(j) := 0;
      end if;
    end loop;
    init_vector := To_bitvector(conv_std_logic_vector(2**(val_in(3)*8+
                                                          val_in(2)*4+val_in(1)*2+val_in(0)*1),16));
    return init_vector;
  end pselect_init_lut;

  signal A_Bus : std_logic_vector(0 to AB);
  signal BAR   : std_logic_vector(0 to AB);

-------------------------------------------------------------------------------
-- Begin architecture section
-------------------------------------------------------------------------------
begin  -- VHDL_RTL

  Make_Busses : process (A,Valid) is
    variable tmp : natural;
  begin  -- process Make_Busses
    tmp   := 0;
    A_Bus <= (others => '0');
    BAR   <= (others => '0');
    for I in C_MASK'range loop
      if (C_MASK(I) = '1') then
        A_Bus(tmp) <= A(I);
        BAR(tmp)   <= C_BAR(I);
        tmp        := tmp + 1;
      end if;
    end loop;  -- I
    if (not Use_CIN) then
      BAR(tmp) <= '1';
      A_Bus(tmp) <= Valid;
    end if;
  end process Make_Busses;

  CS <= Valid when A_Bus=BAR else '0';

end imp;

