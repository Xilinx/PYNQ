-------------------------------------------------------------------------------
-- pselect.vhd - Entity and architecture
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
-------------------------------------------------------------------------------
-- Filename:        pselect.vhd
--
-- Description:     Parameterizeable peripheral select (address decode).
--                  AValid qualifier comes in on Carry In at bottom 
--                  of carry chain. For version with AValid at top of
--                  carry chain, see pselect_top.vhd.
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--                  pselect.vhd
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

library lmb_bram_if_cntlr_v4_0_7;
use lmb_bram_if_cntlr_v4_0_7.all;
use lmb_bram_if_cntlr_v4_0_7.lmb_bram_if_funcs.all;

-----------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Generics:
--          C_AB            -- number of address bits to decode
--          C_AW            -- width of address bus
--          C_BAR           -- base address of peripheral (peripheral select
--                             is asserted when the C_AB most significant
--                             address bits match the C_AB most significant
--                             C_BAR bits
-- Definition of Ports:
--          A               -- address input
--          AValid          -- address qualifier
--          CS              -- peripheral select
-------------------------------------------------------------------------------

entity pselect is
  
  generic (
    C_TARGET : TARGET_FAMILY_TYPE;
    C_AB     : integer := 9;
    C_AW     : integer := 32;
    C_BAR    : std_logic_vector
    );
  port (
    A        : in   std_logic_vector(0 to C_AW-1);
    AValid   : in   std_logic;
    CS       : out  std_logic
    );

end entity pselect;

-----------------------------------------------------------------------------
-- Architecture section
-----------------------------------------------------------------------------

architecture imp of pselect is

  component MB_MUXCY is
  generic (
    C_TARGET : TARGET_FAMILY_TYPE
    );
    port (
      LO : out std_logic;
      CI : in  std_logic;
      DI : in  std_logic;
      S  : in  std_logic
    );
  end component MB_MUXCY;
   
  attribute INIT        : string;

-----------------------------------------------------------------------------
-- Constant Declarations
-----------------------------------------------------------------------------
  constant  NUM_LUTS    : integer := (C_AB+3)/4;

  -- C_BAR may not be indexed from 0 and may not be ascending;
  -- BAR recasts C_BAR to have these properties.
  constant BAR          : std_logic_vector(0 to C_BAR'length-1) := C_BAR;
  
-----------------------------------------------------------------------------
-- Signal Declarations
-----------------------------------------------------------------------------
  
--signal    lut_out     : std_logic_vector(0 to NUM_LUTS-1);
  signal    lut_out     : std_logic_vector(0 to NUM_LUTS); -- XST workaround

  signal    carry_chain : std_logic_vector(0 to NUM_LUTS);


-------------------------------------------------------------------------------
-- Begin architecture section
-------------------------------------------------------------------------------
begin

--------------------------------------------------------------------------------
-- Check that the passed generics allow for correct implementation.
--------------------------------------------------------------------------------
-- synthesis translate_off
   assert (C_AB <= C_BAR'length) and (C_AB <= C_AW)
   report "pselect generic error: " &
          "(C_AB <= C_BAR'length) and (C_AB <= C_AW)" &
          " does not hold."
   severity failure;
-- synthesis translate_on


--------------------------------------------------------------------------------
-- Build the decoder using the fast carry chain.
--------------------------------------------------------------------------------

carry_chain(0) <= AValid;

XST_WA: if NUM_LUTS > 0 generate              -- workaround for XST; remove this
                                              -- enclosing generate when fixed
GEN_DECODE: for i in 0 to NUM_LUTS-1 generate
  signal   lut_in    : std_logic_vector(3 downto 0);
  signal   invert    : std_logic_vector(3 downto 0);
  begin
    GEN_LUT_INPUTS: for j in 0 to 3 generate
       -- Generate to assign address bits to LUT4 inputs
       GEN_INPUT: if i < NUM_LUTS-1 or j <= ((C_AB-1) mod 4) generate
         lut_in(j) <= A(i*4+j);
         invert(j) <= not BAR(i*4+j);
       end generate;
       -- Generate to assign one to remaining LUT4, pad, inputs
       GEN_ZEROS: if not(i < NUM_LUTS-1 or j <= ((C_AB-1) mod 4)) generate
         lut_in(j) <= '1';
         invert(j) <= '0';
       end generate;
    end generate;

    ---------------------------------------------------------------------------
    -- RTL LUT instantiation
    ---------------------------------------------------------------------------
    lut_out(i) <=  (lut_in(0) xor invert(0)) and
                   (lut_in(1) xor invert(1)) and
                   (lut_in(2) xor invert(2)) and
                   (lut_in(3) xor invert(3));


    MUXCY_I: MB_MUXCY
      generic map (
        C_TARGET => C_TARGET)
      port map (
        LO => carry_chain(i+1), --[out]
        CI => carry_chain(i),   --[in]
        DI => '0',              --[in]
        S  => lut_out(i)        --[in]
      );    

end generate GEN_DECODE;
end generate XST_WA;

CS <= carry_chain(NUM_LUTS); -- assign end of carry chain to output;
                             -- if NUM_LUTS=0, then
                             -- CS <= carry_chain(0) <= AValid

end imp;

