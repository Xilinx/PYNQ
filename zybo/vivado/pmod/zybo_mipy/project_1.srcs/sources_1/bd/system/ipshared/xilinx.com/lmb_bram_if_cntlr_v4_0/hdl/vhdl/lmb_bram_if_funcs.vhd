-------------------------------------------------------------------------------
-- lmb_bram_if_funcs.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2001-2015 Xilinx, Inc. All rights reserved.
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
-- Filename:        lmb_bram_if_funcs.vhd
--
-- Description:     Support functions for lmb_bram_if_cntlr
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  lmb_bram_if_funcs.vhd
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

library IEEE;
use IEEE.std_logic_1164.all;

package lmb_bram_if_funcs is

  type TARGET_FAMILY_TYPE is (
                              -- pragma xilinx_rtl_off
                              VIRTEX7,
                              KINTEX7,
                              ARTIX7,
                              ZYNQ,
                              VIRTEXU,
                              KINTEXU,
                              ZYNQUPLUS,
                              VIRTEXUPLUS,
                              KINTEXUPLUS,
                              -- pragma xilinx_rtl_on
                              RTL
                             );

  function String_To_Family (S : string; Select_RTL : boolean) return TARGET_FAMILY_TYPE;

  -- Get the maximum number of inputs to a LUT.
  function Family_To_LUT_Size(Family : TARGET_FAMILY_TYPE) return integer;

end package lmb_bram_if_funcs;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package body lmb_bram_if_funcs is

  function LowerCase_Char(char : character) return character is
  begin
    -- If char is not an upper case letter then return char
    if char < 'A' or char > 'Z' then
      return char;
    end if;
    -- Otherwise map char to its corresponding lower case character and
    -- return that
    case char is
      when 'A'    => return 'a'; when 'B' => return 'b'; when 'C' => return 'c'; when 'D' => return 'd';
      when 'E'    => return 'e'; when 'F' => return 'f'; when 'G' => return 'g'; when 'H' => return 'h';
      when 'I'    => return 'i'; when 'J' => return 'j'; when 'K' => return 'k'; when 'L' => return 'l';
      when 'M'    => return 'm'; when 'N' => return 'n'; when 'O' => return 'o'; when 'P' => return 'p';
      when 'Q'    => return 'q'; when 'R' => return 'r'; when 'S' => return 's'; when 'T' => return 't';
      when 'U'    => return 'u'; when 'V' => return 'v'; when 'W' => return 'w'; when 'X' => return 'x';
      when 'Y'    => return 'y'; when 'Z' => return 'z';
      when others => return char;
    end case;
  end LowerCase_Char;

  -- Returns true if case insensitive string comparison determines that
  -- str1 and str2 are equal
  function Equal_String( str1, str2 : STRING ) RETURN BOOLEAN IS
    CONSTANT len1 : INTEGER := str1'length;
    CONSTANT len2 : INTEGER := str2'length;
    VARIABLE equal : BOOLEAN := TRUE;
  BEGIN
    IF NOT (len1=len2) THEN
      equal := FALSE;
    ELSE
      FOR i IN str1'range LOOP
        IF NOT (LowerCase_Char(str1(i)) = LowerCase_Char(str2(i))) THEN
          equal := FALSE;
        END IF;
      END LOOP;
    END IF;

    RETURN equal;
  END Equal_String;

  function String_To_Family (S : string; Select_RTL : boolean) return TARGET_FAMILY_TYPE is
  begin  -- function String_To_Family
    if ((Select_RTL) or Equal_String(S, "rtl")) then
      return RTL;
    elsif Equal_String(S, "virtex7") or Equal_String(S, "qvirtex7") then
      return VIRTEX7;
    elsif Equal_String(S, "kintex7")  or Equal_String(S, "kintex7l")  or
          Equal_String(S, "qkintex7") or Equal_String(S, "qkintex7l") then
      return KINTEX7;
    elsif Equal_String(S, "artix7")  or Equal_String(S, "artix7l")  or Equal_String(S, "aartix7") or
          Equal_String(S, "qartix7") or Equal_String(S, "qartix7l") then
      return ARTIX7;
    elsif Equal_String(S, "zynq")  or Equal_String(S, "azynq") or Equal_String(S, "qzynq") then
      return ZYNQ;
    elsif Equal_String(S, "virtexu") or Equal_String(S, "qvirtexu") then
      return VIRTEXU;
    elsif Equal_String(S, "kintexu")  or Equal_String(S, "kintexul")  or
          Equal_String(S, "qkintexu") or Equal_String(S, "qkintexul") then
      return KINTEXU;
    elsif Equal_String(S, "zynquplus") then
      return ZYNQUPLUS;
    elsif Equal_String(S, "virtexuplus") then
      return VIRTEXUPLUS;
    elsif Equal_String(S, "kintexuplus") then
      return KINTEXUPLUS;
    else
      -- assert (false) report "No known target family" severity failure;
      return RTL;
    end if;
  end function String_To_Family;

  function Family_To_LUT_Size(Family : TARGET_FAMILY_TYPE) return integer is
  begin
    return 6;
  end function Family_To_LUT_Size;

end package body lmb_bram_if_funcs;
