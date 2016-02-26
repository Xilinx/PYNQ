-------------------------------------------------------------------------------
-- axi_bram_ctrl_funcs.vhd
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
------------------------------------------------------------------------------
-- Filename:        axi_bram_ctrl_funcs.vhd
--
-- Description:     Support functions for axi_bram_ctrl library modules.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
--
--
-- History:
--
-- ^^^^^^
-- JLJ      2/1/2011         v1.03a
-- ~~~~~~
--  Migrate to v1.03a.
--  Plus minor code cleanup.
-- ^^^^^^
-- JLJ      2/16/2011      v1.03a
-- ~~~~~~
--  Update ECC size on 128-bit data width configuration.
-- ^^^^^^
-- JLJ      2/23/2011      v1.03a
-- ~~~~~~
--  Add MIG functions for Hsiao ECC.
-- ^^^^^^
-- JLJ      2/24/2011      v1.03a
-- ~~~~~~
--  Add Find_ECC_Size function.
-- ^^^^^^
-- JLJ      3/15/2011      v1.03a
-- ~~~~~~
--  Add REDUCTION_OR function.
-- ^^^^^^
-- JLJ      3/17/2011      v1.03a
-- ~~~~~~
--  Recode Create_Size_Max with a case statement.
-- ^^^^^^
-- JLJ      3/31/2011      v1.03a
-- ~~~~~~
--  Add coverage tags.
-- ^^^^^^
-- JLJ      5/6/2011      v1.03a
-- ~~~~~~
--  Remove usage of C_FAMILY.  
--  Remove Family_To_LUT_Size function.
--  Remove String_To_Family function.
-- ^^^^^^
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

package axi_bram_ctrl_funcs is

  type TARGET_FAMILY_TYPE is (
                              -- pragma xilinx_rtl_off
                              SPARTAN3,
                              VIRTEX4,
                              VIRTEX5,
                              SPARTAN3E,
                              SPARTAN3A,
                              SPARTAN3AN,
                              SPARTAN3Adsp,
                              SPARTAN6,
                              VIRTEX6,
                              VIRTEX7,
                              KINTEX7,
                              -- pragma xilinx_rtl_on
                              RTL
                             );

  -- function String_To_Family (S : string; Select_RTL : boolean) return TARGET_FAMILY_TYPE;

  -- Get the maximum number of inputs to a LUT.
  -- function Family_To_LUT_Size(Family : TARGET_FAMILY_TYPE) return integer;

  function Equal_String( str1, str2 : STRING ) RETURN BOOLEAN;
  function log2(x : natural) return integer;
  function Int_ECC_Size (i: integer) return integer;
  function Find_ECC_Size (i: integer; j: integer) return integer;
  function Find_ECC_Full_Bit_Size (i: integer; j: integer) return integer;
  function Create_Size_Max (i: integer) return std_logic_vector;
  function REDUCTION_OR (A: in std_logic_vector) return std_logic;
  function REDUCTION_XOR (A: in std_logic_vector) return std_logic;
  function REDUCTION_NOR (A: in std_logic_vector) return std_logic;
  function BOOLEAN_TO_STD_LOGIC (A: in BOOLEAN) return std_logic;
    

end package axi_bram_ctrl_funcs;




library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;



package body axi_bram_ctrl_funcs is


-------------------------------------------------------------------------------
-- Function:    Int_ECC_Size
-- Purpose:     Determine internal size of ECC when enabled.
-------------------------------------------------------------------------------

function Int_ECC_Size (i: integer) return integer is
begin  

--coverage off

    if (i = 32) then
        return 7;   -- 7-bits ECC for 32-bit data
                    -- ECC port size fixed @ 8-bits
    elsif (i = 64) then
        return 8;
    elsif (i = 128) then
        return 9;   -- Hsiao is 9-bits for 128-bit data.
    else
        return 0;
    end if;

--coverage on
    
end Int_ECC_Size;

-------------------------------------------------------------------------------
-- Function:    Find_ECC_Size
-- Purpose:     Determine external size of ECC signals when enabled.
-------------------------------------------------------------------------------

function Find_ECC_Size (i: integer; j: integer) return integer is
begin  

--coverage off

    if (i = 1) then
        if (j = 32) then
            return 8;   -- Keep at 8 for port size matchings
                        -- Only 7-bits ECC per 32-bit data
        elsif (j = 64) then
            return 8;
        elsif (j = 128) then
            return 9;
        else
            return 0;
        end if;
    else
        return 0;
        -- ECC data width = 0 when C_ECC = 0 (disabled)
    end if;

--coverage on
    
end Find_ECC_Size;

-------------------------------------------------------------------------------
-- Function:    Find_ECC_Full_Bit_Size
-- Purpose:     Determine external size of ECC signals when enabled in bytes.
-------------------------------------------------------------------------------

function Find_ECC_Full_Bit_Size (i: integer; j: integer) return integer is
begin  

--coverage off

    if (i = 1) then
        if (j = 32) then
            return 8;
        elsif (j = 64) then
            return 8;
        elsif (j = 128) then
            return 16;
        else
            return 0;
        end if;
    else
        return 0;
        -- ECC data width = 0 when C_ECC = 0 (disabled)
    end if;

--coverage on
    
end Find_ECC_Full_Bit_Size;


-------------------------------------------------------------------------------
-- Function:    Create_Size_Max
-- Purpose:     Create maximum value for AxSIZE based on AXI data bus width.
-------------------------------------------------------------------------------

function Create_Size_Max (i: integer)
    return std_logic_vector is

variable size_vector : std_logic_vector (2 downto 0);
begin

    case (i) is
        when 32 =>      size_vector := "010";           -- 2h (4 bytes)
        when 64 =>      size_vector := "011";           -- 3h (8 bytes)    
        when 128 =>     size_vector := "100";           -- 4h (16 bytes)
        when 256 =>     size_vector := "101";           -- 5h (32 bytes)
        when 512 =>     size_vector := "110";           -- 5h (32 bytes)
        when 1024 =>    size_vector := "111";           -- 5h (32 bytes)
--coverage off
        when others =>  size_vector := "000";           -- 0h    
--coverage on

    end case;

    return (size_vector);

end function Create_Size_Max;





-------------------------------------------------------------------------------
-- Function:    REDUCTION_OR
-- Purpose:     New in v1.03a
-------------------------------------------------------------------------------

function REDUCTION_OR (A: in std_logic_vector) return std_logic is
variable tmp : std_logic := '0';
begin
    for i in A'range loop
       tmp := tmp or A(i);
    end loop;
    return tmp;
end function REDUCTION_OR;




-------------------------------------------------------------------------------
-- Function:    REDUCTION_XOR
-- Purpose:     Derived from MIG v3.7 ecc_gen module for use by Hsiao ECC.
--              New in v1.03a
-------------------------------------------------------------------------------

function REDUCTION_XOR (A: in std_logic_vector) return std_logic is
  variable tmp : std_logic := '0';
begin
  for i in A'range loop
       tmp := tmp xor A(i);
  end loop;
  return tmp;
end function REDUCTION_XOR;




-------------------------------------------------------------------------------
-- Function:    REDUCTION_NOR
-- Purpose:     Derived from MIG v3.7 ecc_dec_fix module for use by Hsiao ECC.
--              New in v1.03a
-------------------------------------------------------------------------------

function REDUCTION_NOR (A: in std_logic_vector) return std_logic is
  variable tmp : std_logic := '0';
begin
  for i in A'range loop
       tmp := tmp or A(i);
  end loop;
  return not tmp;
end function REDUCTION_NOR;




-------------------------------------------------------------------------------
-- Function:    BOOLEAN_TO_STD_LOGIC
-- Purpose:     Derived from MIG v3.7 ecc_dec_fix module for use by Hsiao ECC.
--              New in v1.03a
-------------------------------------------------------------------------------

function BOOLEAN_TO_STD_LOGIC (A : in BOOLEAN) return std_logic is
begin
   if A = true then
       return '1';
   else
       return '0';
   end if;
end function BOOLEAN_TO_STD_LOGIC;


-------------------------------------------------------------------------------

function LowerCase_Char(char : character) return character is
begin

--coverage off

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

--coverage on

end LowerCase_Char;


-------------------------------------------------------------------------------


-- Returns true if case insensitive string comparison determines that
-- str1 and str2 are equal
function Equal_String ( str1, str2 : STRING ) RETURN BOOLEAN IS
  CONSTANT len1 : INTEGER := str1'length;
  CONSTANT len2 : INTEGER := str2'length;
  VARIABLE equal : BOOLEAN := TRUE;
BEGIN

--coverage off

    IF NOT (len1=len2) THEN
      equal := FALSE;
    ELSE
      FOR i IN str1'range LOOP
        IF NOT (LowerCase_Char(str1(i)) = LowerCase_Char(str2(i))) THEN
          equal := FALSE;
        END IF;
      END LOOP;
    END IF;

--coverage on

    RETURN equal;
    
END Equal_String;


-------------------------------------------------------------------------------


-- Remove usage of C_FAMILY.
-- Remove usage of String_To_Family function.
--
--    
--    function String_To_Family (S : string; Select_RTL : boolean) return TARGET_FAMILY_TYPE is
--    begin  -- function String_To_Family
--    
--    --coverage off
--    
--        if ((Select_RTL) or Equal_String(S, "rtl")) then
--          return RTL;
--        elsif Equal_String(S, "spartan3") or Equal_String(S, "aspartan3") then
--          return SPARTAN3;
--        elsif Equal_String(S, "spartan3E") or Equal_String(S, "aspartan3E") then
--          return SPARTAN3E;
--        elsif Equal_String(S, "spartan3A") or Equal_String(S, "aspartan3A") then
--          return SPARTAN3A;
--        elsif Equal_String(S, "spartan3AN") then
--          return SPARTAN3AN;
--        elsif Equal_String(S, "spartan3Adsp") or Equal_String(S, "aspartan3Adsp") then
--          return SPARTAN3Adsp;
--        elsif Equal_String(S, "spartan6")  or Equal_String(S, "spartan6l") or
--              Equal_String(S, "qspartan6") or Equal_String(S, "aspartan6") or Equal_String(S, "qspartan6l") then
--          return SPARTAN6;
--        elsif Equal_String(S, "virtex4") or Equal_String(S, "qvirtex4")
--           or Equal_String(S, "qrvirtex4") then
--          return VIRTEX4;
--        elsif Equal_String(S, "virtex5") or Equal_String(S, "qrvirtex5") then
--          return VIRTEX5;
--        elsif Equal_String(S, "virtex6") or Equal_String(S, "virtex6l") or Equal_String(S, "qvirtex6") then
--          return VIRTEX6;
--        elsif Equal_String(S, "virtex7") then
--          return VIRTEX7;
--        elsif Equal_String(S, "kintex7") then
--          return KINTEX7;
--    
--    --coverage on
--    
--        else
--          -- assert (false) report "No known target family" severity failure;
--          return RTL;
--        end if;
--        
--    end function String_To_Family;


-------------------------------------------------------------------------------

-- Remove usage of C_FAMILY.
-- Remove usage of Family_To_LUT_Size function.
--
--    function Family_To_LUT_Size (Family : TARGET_FAMILY_TYPE) return integer is
--    begin
--    
--    --coverage off
--    
--        if (Family = SPARTAN3) or (Family = SPARTAN3E) or (Family = SPARTAN3A) or
--           (Family = SPARTAN3AN) or (Family = SPARTAN3Adsp) or (Family = VIRTEX4) then
--          return 4;
--        end if;
--    
--        return 6;
--    
--    --coverage on
--    
--    end function Family_To_LUT_Size;


-------------------------------------------------------------------------------
-- Function log2 -- returns number of bits needed to encode x choices
--   x = 0  returns 0
--   x = 1  returns 0
--   x = 2  returns 1
--   x = 4  returns 2, etc.
-------------------------------------------------------------------------------

function log2(x : natural) return integer is
  variable i  : integer := 0; 
  variable val: integer := 1;
begin 

--coverage off

    if x = 0 then return 0;
    else
      for j in 0 to 29 loop -- for loop for XST 
        if val >= x then null; 
        else
          i := i+1;
          val := val*2;
        end if;
      end loop;
    -- Fix per CR520627  XST was ignoring this anyway and printing a  
    -- Warning in SRP file. This will get rid of the warning and not
    -- impact simulation.  
    -- synthesis translate_off
      assert val >= x
        report "Function log2 received argument larger" &
               " than its capability of 2^30. "
        severity failure;
    -- synthesis translate_on
      return i;
    end if;  

--coverage on

end function log2; 


-------------------------------------------------------------------------------


  

end package body axi_bram_ctrl_funcs;
