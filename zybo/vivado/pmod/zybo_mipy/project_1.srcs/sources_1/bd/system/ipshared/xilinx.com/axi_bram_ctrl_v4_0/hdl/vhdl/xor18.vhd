-------------------------------------------------------------------------------
-- xor18.vhd
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
-- Filename:        xor18.vhd
--
-- Description:     Basic 18-bit input XOR function.
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
-- JLJ      2/2/2011         v1.03a
-- ~~~~~~
--  Migrate to v1.03a.
--  Plus minor code cleanup.
-- ^^^^^^
-- JLJ      3/17/2011         v1.03a
-- ~~~~~~
--  Add default on C_USE_LUT6 parameter.
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

entity XOR18 is 
  generic (
    C_USE_LUT6 : boolean := FALSE );
  port (
    InA : in  std_logic_vector(0 to 17);
    res : out std_logic);
end entity XOR18;

architecture IMP of XOR18 is

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of IMP : architecture is "yes";

begin  -- architecture IMP

  Using_LUT6: if (C_USE_LUT6) generate
    signal xor6_1   : std_logic;
    signal xor6_2   : std_logic;
    signal xor6_3   : std_logic;
    signal xor18_c1 : std_logic;
    signal xor18_c2 : std_logic;
  begin  -- generate Using_LUT6

    XOR6_1_LUT : LUT6
      generic map(
        INIT => X"6996966996696996")
      port map(
        O    => xor6_1,
        I0   => InA(17),
        I1   => InA(16),
        I2   => InA(15),
        I3   => InA(14),
        I4   => InA(13),
        I5   => InA(12));

    XOR_1st_MUXCY : MUXCY_L
      port map (
        DI => '1',
        CI => '0',
        S  => xor6_1,
        LO => xor18_c1);

    XOR6_2_LUT : LUT6
      generic map(
        INIT => X"6996966996696996")
      port map(
        O    => xor6_2,
        I0   => InA(11),
        I1   => InA(10),
        I2   => InA(9),
        I3   => InA(8),
        I4   => InA(7),
        I5   => InA(6));

    XOR_2nd_MUXCY : MUXCY_L
      port map (
        DI => xor6_1,
        CI => xor18_c1,
        S  => xor6_2,
        LO => xor18_c2);

    XOR6_3_LUT : LUT6
      generic map(
        INIT => X"6996966996696996")
      port map(
        O    => xor6_3,
        I0   => InA(5),
        I1   => InA(4),
        I2   => InA(3),
        I3   => InA(2),
        I4   => InA(1),
        I5   => InA(0));

    XOR18_XORCY : XORCY
      port map (
        LI => xor6_3,
        CI => xor18_c2,
        O  => res);
    
  end generate Using_LUT6;

  Not_Using_LUT6: if (not C_USE_LUT6) generate
  begin  -- generate Not_Using_LUT6

    res <= InA(17) xor InA(16) xor InA(15) xor InA(14) xor InA(13) xor InA(12) xor
           InA(11) xor InA(10) xor InA(9) xor InA(8) xor InA(7) xor InA(6) xor
           InA(5) xor InA(4) xor InA(3) xor InA(2) xor InA(1) xor InA(0);    

  end generate Not_Using_LUT6;
end architecture IMP;
