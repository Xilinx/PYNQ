-------------------------------------------------------------------------------
-- checkbit_handler.vhd - Entity and architecture
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
-- Filename:        gen_checkbits.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              gen_checkbits.vhd
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

library lmb_bram_if_cntlr_v4_0_7;
use lmb_bram_if_cntlr_v4_0_7.all;
use lmb_bram_if_cntlr_v4_0_7.lmb_bram_if_funcs.all;

entity checkbit_handler is
  generic (
    C_TARGET   : TARGET_FAMILY_TYPE;
    C_ENCODE   : boolean := true);
  port (
    DataIn     : in  std_logic_vector(0 to 31);
    CheckIn    : in  std_logic_vector(0 to 6);
    CheckOut   : out std_logic_vector(0 to 6);
    Syndrome   : out std_logic_vector(0 to 6);
    Enable_ECC : in  std_logic;
    UE_Q       : in  std_logic;
    CE_Q       : in  std_logic;
    UE         : out std_logic;
    CE         : out std_logic
    );
end entity checkbit_handler;

architecture IMP of checkbit_handler is

  component XOR18 is
    generic (
      C_TARGET   : TARGET_FAMILY_TYPE);
    port (
      InA : in  std_logic_vector(0 to 17);
      res : out std_logic);
  end component XOR18;
  
  component Parity is
    generic (
      C_TARGET   : TARGET_FAMILY_TYPE;
      C_SIZE     : integer);
    port (
      InA : in  std_logic_vector(0 to C_SIZE - 1);
      Res : out std_logic);
  end component Parity;

  component ParityEnable
    generic (
      C_TARGET   : TARGET_FAMILY_TYPE;
      C_SIZE     : integer);
    port (
      InA    : in  std_logic_vector(0 to C_SIZE - 1);
      Enable : in  std_logic;
      Res    : out std_logic);
  end component ParityEnable;

  component MB_MUXF7 is
  generic (
    C_TARGET : TARGET_FAMILY_TYPE
  );
  port (
    O  : out std_logic;
    I0 : in  std_logic;
    I1 : in  std_logic;
    S  : in  std_logic
  );
  end component MB_MUXF7;
  
  signal data_chk0 : std_logic_vector(0 to 17);
  signal data_chk1 : std_logic_vector(0 to 17);
  signal data_chk2 : std_logic_vector(0 to 17);
  signal data_chk3 : std_logic_vector(0 to 14);
  signal data_chk4 : std_logic_vector(0 to 14);
  signal data_chk5 : std_logic_vector(0 to 5);
  
begin  -- architecture IMP
  data_chk0 <= DataIn(0) & DataIn(1) & DataIn(3) & DataIn(4) & DataIn(6) & DataIn(8) & DataIn(10) &
               DataIn(11) & DataIn(13) & DataIn(15) & DataIn(17) & DataIn(19) & DataIn(21) &
               DataIn(23) & DataIn(25) & DataIn(26) & DataIn(28) & DataIn(30);

  data_chk1 <= DataIn(0) & DataIn(2) & DataIn(3) & DataIn(5) & DataIn(6) & DataIn(9) & DataIn(10) &
               DataIn(12) & DataIn(13) & DataIn(16) & DataIn(17) & DataIn(20) & DataIn(21) &
               DataIn(24) & DataIn(25) & DataIn(27) & DataIn(28) & DataIn(31);

  data_chk2 <= DataIn(1) & DataIn(2) & DataIn(3) & DataIn(7) & DataIn(8) & DataIn(9) & DataIn(10) &
               DataIn(14) & DataIn(15) & DataIn(16) & DataIn(17) & DataIn(22) & DataIn(23) & DataIn(24) &
               DataIn(25) & DataIn(29) & DataIn(30) & DataIn(31);

  data_chk3 <= DataIn(4) & DataIn(5) & DataIn(6) & DataIn(7) & DataIn(8) & DataIn(9) & DataIn(10) &
               DataIn(18) & DataIn(19) & DataIn(20) & DataIn(21) & DataIn(22) & DataIn(23) & DataIn(24) &
               DataIn(25);

  data_chk4 <= DataIn(11) & DataIn(12) & DataIn(13) & DataIn(14) & DataIn(15) & DataIn(16) & DataIn(17) &
               DataIn(18) & DataIn(19) & DataIn(20) & DataIn(21) & DataIn(22) & DataIn(23) & DataIn(24) &
               DataIn(25);

  data_chk5 <= DataIn(26) & DataIn(27) & DataIn(28) & DataIn(29) & DataIn(30) & DataIn(31);

  -- Encode bits for writing data
  Encode_Bits : if (C_ENCODE) generate
    signal data_chk3_i : std_logic_vector(0 to 17);
    signal data_chk4_i : std_logic_vector(0 to 17);
    signal data_chk6   : std_logic_vector(0 to 17);
  begin
    ------------------------------------------------------------------------------------------------
    -- Checkbit 0 built up using XOR18
    ------------------------------------------------------------------------------------------------
    XOR18_I0 : XOR18
      generic map (
        C_TARGET => C_TARGET)
      port map (
        InA => data_chk0,               -- [in  std_logic_vector(0 to 17)]
        res => CheckOut(0));            -- [out std_logic]

    ------------------------------------------------------------------------------------------------
    -- Checkbit 1 built up using XOR18
    ------------------------------------------------------------------------------------------------
    XOR18_I1 : XOR18
      generic map (
        C_TARGET => C_TARGET)
      port map (
        InA => data_chk1,               -- [in  std_logic_vector(0 to 17)]
        res => CheckOut(1));            -- [out std_logic]

    ------------------------------------------------------------------------------------------------
    -- Checkbit 2 built up using XOR18
    ------------------------------------------------------------------------------------------------
    XOR18_I2 : XOR18
      generic map (
        C_TARGET => C_TARGET)
      port map (
        InA => data_chk2,               -- [in  std_logic_vector(0 to 17)]
        res => CheckOut(2));            -- [out std_logic]

    ------------------------------------------------------------------------------------------------
    -- Checkbit 3 built up using XOR18
    ------------------------------------------------------------------------------------------------
    data_chk3_i <= data_chk3 & "000";
    XOR18_I3 : XOR18
      generic map (
        C_TARGET => C_TARGET)
      port map (
        InA => data_chk3_i,             -- [in  std_logic_vector(0 to 17)]
        res => CheckOut(3));            -- [out std_logic]

    ------------------------------------------------------------------------------------------------
    -- Checkbit 4 built up using XOR18
    ------------------------------------------------------------------------------------------------
    data_chk4_i <= data_chk4 & "000";
    XOR18_I4 : XOR18
      generic map (
        C_TARGET => C_TARGET)
      port map (
        InA => data_chk4_i,             -- [in  std_logic_vector(0 to 17)]
        res => CheckOut(4));            -- [out std_logic]

    ------------------------------------------------------------------------------------------------
    -- Checkbit 5 built up from 1 LUT6
    ------------------------------------------------------------------------------------------------
    Parity_chk5_1 : Parity
      generic map (
        C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA => data_chk5,             -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => CheckOut(5));          -- [out std_logic]
    
    ------------------------------------------------------------------------------------------------
    -- Checkbit 6 built up from 3 LUT7 and 4 LUT6
    ------------------------------------------------------------------------------------------------
    data_chk6 <= DataIn(0) & DataIn(1) & DataIn(2) & DataIn(4) & DataIn(5) & DataIn(7) & DataIn(10) &
                 DataIn(11) & DataIn(12) & DataIn(14) & DataIn(17) & DataIn(18) & DataIn(21) &
                 DataIn(23) & DataIn(24) & DataIn(26) & DataIn(27) & DataIn(29);
    XOR18_I6 : XOR18
      generic map (
        C_TARGET => C_TARGET)       -- [boolean]
      port map (
        InA => data_chk6,             -- [in  std_logic_vector(0 to 17)]
        res => CheckOut(6));            -- [out std_logic]

    -- Unused
    Syndrome <= (others => '0');
    UE       <= '0';
    CE       <= '0';
  end generate Encode_Bits;

  --------------------------------------------------------------------------------------------------
  -- Decode bits to get syndrome and UE/CE signals
  --------------------------------------------------------------------------------------------------
  Decode_Bits : if (not C_ENCODE) generate
    signal syndrome_i  : std_logic_vector(0 to 6);
    signal chk0_1 : std_logic_vector(0 to 3);
    signal chk1_1 : std_logic_vector(0 to 3);
    signal chk2_1 : std_logic_vector(0 to 3);
    signal data_chk3_i : std_logic_vector(0 to 15);
    signal chk3_1 : std_logic_vector(0 to 1);
    signal data_chk4_i : std_logic_vector(0 to 15);
    signal chk4_1 : std_logic_vector(0 to 1);
    signal data_chk5_i : std_logic_vector(0 to 6);
    signal data_chk6   : std_logic_vector(0 to 38);
    signal chk6_1 : std_logic_vector(0 to 5);

    signal syndrome_3_to_5       : std_logic_vector(3 to 5);
    signal syndrome_3_to_5_multi : std_logic;
    signal syndrome_3_to_5_zero  : std_logic;
    signal ue_i_0 : std_logic;
    signal ue_i_1 : std_logic;

  begin
    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 0 built up from 3 LUT6 and 1 LUT4
    ------------------------------------------------------------------------------------------------
    chk0_1(3) <= CheckIn(0);
    Parity_chk0_1 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA                   => data_chk0(0 to 5),  -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res                   => chk0_1(0));  -- [out std_logic]
    Parity_chk0_2 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA                   => data_chk0(6 to 11),  -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res                   => chk0_1(1));  -- [out std_logic]
    Parity_chk0_3 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA                   => data_chk0(12 to 17),  -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res                   => chk0_1(2));  -- [out std_logic]
    Parity_chk0_4 : ParityEnable
      generic map (C_TARGET => C_TARGET, C_SIZE => 4)
      port map (
        InA                   => chk0_1,  -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Enable                => Enable_ECC,  -- [in  std_logic]
        Res                   => syndrome_i(0));  -- [out std_logic]

    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 1 built up from 3 LUT6 and 1 LUT4
    ------------------------------------------------------------------------------------------------
    chk1_1(3) <= CheckIn(1);
    Parity_chk1_1 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA => data_chk1(0 to 5),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk1_1(0));              -- [out std_logic]
    Parity_chk1_2 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA => data_chk1(6 to 11),      -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk1_1(1));              -- [out std_logic]
    Parity_chk1_3 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA => data_chk1(12 to 17),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk1_1(2));              -- [out std_logic]
    Parity_chk1_4 : ParityEnable      
      generic map (C_TARGET => C_TARGET, C_SIZE => 4)
      port map (
        InA => chk1_1,             -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Enable => Enable_ECC,  -- [in  std_logic]
        Res => syndrome_i(1));          -- [out std_logic]

    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 2 built up from 3 LUT6 and 1 LUT4
    ------------------------------------------------------------------------------------------------
    chk2_1(3) <= CheckIn(2);
    Parity_chk2_1 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA => data_chk2(0 to 5),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk2_1(0));              -- [out std_logic]
    Parity_chk2_2 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA => data_chk2(6 to 11),      -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk2_1(1));              -- [out std_logic]
    Parity_chk2_3 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA => data_chk2(12 to 17),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk2_1(2));              -- [out std_logic]
    Parity_chk2_4 : ParityEnable
      generic map (C_TARGET => C_TARGET, C_SIZE => 4)
      port map (
        InA => chk2_1,             -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Enable => Enable_ECC,  -- [in  std_logic]
        Res => syndrome_i(2));          -- [out std_logic]

    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 3 built up from 2 LUT8 and 1 LUT2
    ------------------------------------------------------------------------------------------------
    data_chk3_i <= data_chk3 & CheckIn(3);
    Parity_chk3_1 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 8)
      port map (
        InA => data_chk3_i(0 to 7),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk3_1(0));              -- [out std_logic]
    Parity_chk3_2 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 8)
      port map (
        InA => data_chk3_i(8 to 15),      -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk3_1(1));              -- [out std_logic]
    Parity_chk3_3 : ParityEnable
      generic map (C_TARGET => C_TARGET, C_SIZE => 2)
      port map (
        InA => chk3_1,                  -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Enable => Enable_ECC,  -- [in  std_logic]
        Res => syndrome_i(3));              -- [out std_logic]

    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 4 built up from 2 LUT8 and 1 LUT2
    ------------------------------------------------------------------------------------------------
    data_chk4_i <= data_chk4 & CheckIn(4);
    Parity_chk4_1 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 8)
      port map (
        InA => data_chk4_i(0 to 7),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk4_1(0));              -- [out std_logic]
    Parity_chk4_2 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 8)
      port map (
        InA => data_chk4_i(8 to 15),      -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk4_1(1));              -- [out std_logic]
    Parity_chk4_3 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 2)
      port map (
        InA => chk4_1,                  -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => syndrome_i(4));              -- [out std_logic]


    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 5 built up from 1 LUT7
    ------------------------------------------------------------------------------------------------
    data_chk5_i <= data_chk5 & CheckIn(5);
    Parity_chk5_1 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 7)
      port map (
        InA => data_chk5_i,             -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => syndrome_i(5));          -- [out std_logic]
    
    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 6 built up from 3 LUT7 and 4 LUT6
    ------------------------------------------------------------------------------------------------
    data_chk6 <= DataIn(0) & DataIn(1) & DataIn(2) & DataIn(3) & DataIn(4) & DataIn(5) & DataIn(6) & DataIn(7) &
                 DataIn(8) & DataIn(9) & DataIn(10) & DataIn(11) & DataIn(12) & DataIn(13) & DataIn(14) &
                 DataIn(15) & DataIn(16) & DataIn(17) & DataIn(18) & DataIn(19) & DataIn(20) & DataIn(21) &
                 DataIn(22) & DataIn(23) & DataIn(24) & DataIn(25) & DataIn(26) & DataIn(27) & DataIn(28) &
                 DataIn(29) & DataIn(30) & DataIn(31) & CheckIn(5) & CheckIn(4) & CheckIn(3) & CheckIn(2) &
                 CheckIn(1) & CheckIn(0) & CheckIn(6);
    Parity_chk6_1 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA => data_chk6(0 to 5),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk6_1(0));              -- [out std_logic]
    Parity_chk6_2 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA => data_chk6(6 to 11),      -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk6_1(1));              -- [out std_logic]
    Parity_chk6_3 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA => data_chk6(12 to 17),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk6_1(2));              -- [out std_logic]
    Parity_chk6_4 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 7)
      port map (
        InA => data_chk6(18 to 24),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk6_1(3));              -- [out std_logic]
    Parity_chk6_5 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 7)
      port map (
        InA => data_chk6(25 to 31),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk6_1(4));              -- [out std_logic]
    Parity_chk6_6 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 7)
      port map (
        InA => data_chk6(32 to 38),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk6_1(5));              -- [out std_logic]
    Parity_chk6_7 : Parity
      generic map (C_TARGET => C_TARGET, C_SIZE => 6)
      port map (
        InA => chk6_1,             -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => syndrome_i(6));          -- [out std_logic]

    Syndrome <= syndrome_i;
    
    syndrome_3_to_5 <= (chk3_1(0) xor chk3_1(1)) & (chk4_1(0) xor chk4_1(1)) & syndrome_i(5);
    syndrome_3_to_5_zero <= '1' when syndrome_3_to_5 = "000" else '0';
    syndrome_3_to_5_multi <= '1' when (syndrome_3_to_5 = "111" or
                                       syndrome_3_to_5 = "011" or
                                       syndrome_3_to_5 = "101") else
                             '0';

    CE <= '0' when (Enable_ECC = '0') else
          (syndrome_i(6) or CE_Q) when (syndrome_3_to_5_multi = '0') else
          CE_Q;

    ue_i_0 <= '0' when (Enable_ECC = '0') else
              '1' when (syndrome_3_to_5_zero = '0') or (syndrome_i(0 to 2) /= "000") else
              UE_Q;
    ue_i_1 <= '0' when (Enable_ECC = '0') else
              (syndrome_3_to_5_multi or UE_Q);

    Use_FPGA: if (C_TARGET /= RTL) generate
      UE_MUXF7 : MB_MUXF7
        generic map (
          C_TARGET => C_TARGET)
        port map (
          I0 => ue_i_0,
          I1 => ue_i_1,
          S  => syndrome_i(6),
          O  => UE);      
    end generate Use_FPGA;

    Use_RTL: if (C_TARGET = RTL) generate
      UE <= ue_i_1 when syndrome_i(6) = '1' else ue_i_0;
    end generate Use_RTL;

    -- Unused
    CheckOut <= (others => '0');
  end generate Decode_Bits;

end architecture IMP;
