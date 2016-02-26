-------------------------------------------------------------------------------
-- correct_one_bit_64.vhd
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
-- Filename:        correct_one_bit_64.vhd
--
-- Description:     Identifies single bit to correct in 64-bit word of
--                  data read from memory as indicated by the syndrome input
--                  vector.
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

entity Correct_One_Bit_64 is
  generic (
    C_USE_LUT6    : boolean := true;
    Correct_Value : std_logic_vector(0 to 7));
  port (
    DIn      : in  std_logic;
    Syndrome : in  std_logic_vector(0 to 7);
    DCorr    : out std_logic);
end entity Correct_One_Bit_64;

architecture IMP of Correct_One_Bit_64 is

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of IMP : architecture is "yes";

  -----------------------------------------------------------------------------
  -- Find which bit that has a '1'
  -- There is always one bit which has a '1'
  -----------------------------------------------------------------------------
  function find_one (Syn : std_logic_vector(0 to 7)) return natural is
  begin  -- function find_one
    for I in 0 to 7 loop
      if (Syn(I) = '1') then
        return I;
      end if;
    end loop;  -- I
    return 0;                           -- Should never reach this statement
  end function find_one;

  constant di_index : natural := find_one(Correct_Value);

  signal corr_sel : std_logic;
  signal corr_c   : std_logic;
  signal lut_compare  : std_logic_vector(0 to 6);
  signal lut_corr_val : std_logic_vector(0 to 6);

begin  -- architecture IMP

  Remove_DI_Index : process (Syndrome) is
  begin  -- process Remove_DI_Index
    if (di_index = 0) then
      lut_compare  <= Syndrome(1 to 7);
      lut_corr_val <= Correct_Value(1 to 7);
    elsif (di_index = 6) then
      lut_compare  <= Syndrome(0 to 6);
      lut_corr_val <= Correct_Value(0 to 6);
    else
      lut_compare  <= Syndrome(0 to di_index-1) & Syndrome(di_index+1 to 7);
      lut_corr_val <= Correct_Value(0 to di_index-1) & Correct_Value(di_index+1 to 7);
    end if;
  end process Remove_DI_Index;

  corr_sel <= '0' when lut_compare = lut_corr_val else '1';
  
  Corr_MUXCY : MUXCY_L
    port map (
      DI => Syndrome(di_index),
      CI => '0',
      S  => corr_sel,
      LO => corr_c);

  Corr_XORCY : XORCY
    port map (
      LI => DIn,
      CI => corr_c,
      O  => DCorr);

end architecture IMP;
