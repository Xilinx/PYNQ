-------------------------------------------------------------------------------
-- lmb_mux.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright [2003] - [2011] Xilinx, Inc. All rights reserved.
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
-- Filename:        lmb_mux.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              lmb_mux.vhd
--                pselct_mask.vhd
--
-------------------------------------------------------------------------------
-- Author:          rolandp
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

entity lmb_mux is
  generic (
    C_BASEADDR   : std_logic_vector(0 to 31) := X"FFFFFFFF";
    C_MASK       : std_logic_vector(0 to 31) := X"00800000";
    C_MASK1      : std_logic_vector(0 to 31) := X"00800000";
    C_MASK2      : std_logic_vector(0 to 31) := X"00800000";
    C_MASK3      : std_logic_vector(0 to 31) := X"00800000";
    C_LMB_AWIDTH : integer                   := 32;
    C_LMB_DWIDTH : integer                   := 32;
    C_NUM_LMB    : integer                   := 1);
  port (
    LMB_Clk : in std_logic := '0';
    LMB_Rst : in std_logic := '0';

    -- LMB Bus 0
    LMB0_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB0_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB0_AddrStrobe  : in  std_logic;
    LMB0_ReadStrobe  : in  std_logic;
    LMB0_WriteStrobe : in  std_logic;
    LMB0_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl0_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl0_Ready        : out std_logic;
    Sl0_Wait         : out std_logic;
    Sl0_UE           : out std_logic;
    Sl0_CE           : out std_logic;

    -- LMB Bus 1
    LMB1_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB1_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB1_AddrStrobe  : in  std_logic;
    LMB1_ReadStrobe  : in  std_logic;
    LMB1_WriteStrobe : in  std_logic;
    LMB1_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl1_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl1_Ready        : out std_logic;
    Sl1_Wait         : out std_logic;
    Sl1_UE           : out std_logic;
    Sl1_CE           : out std_logic;

    -- LMB Bus 2
    LMB2_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB2_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB2_AddrStrobe  : in  std_logic;
    LMB2_ReadStrobe  : in  std_logic;
    LMB2_WriteStrobe : in  std_logic;
    LMB2_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl2_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl2_Ready        : out std_logic;
    Sl2_Wait         : out std_logic;
    Sl2_UE           : out std_logic;
    Sl2_CE           : out std_logic;

    -- LMB Bus 3
    LMB3_ABus        : in  std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB3_WriteDBus   : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB3_AddrStrobe  : in  std_logic;
    LMB3_ReadStrobe  : in  std_logic;
    LMB3_WriteStrobe : in  std_logic;
    LMB3_BE          : in  std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl3_DBus         : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl3_Ready        : out std_logic;
    Sl3_Wait         : out std_logic;
    Sl3_UE           : out std_logic;
    Sl3_CE           : out std_logic;
    
    -- Muxed LMB Bus
    LMB_ABus        : out std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB_WriteDBus   : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB_AddrStrobe  : out std_logic;
    LMB_ReadStrobe  : out std_logic;
    LMB_WriteStrobe : out std_logic;
    LMB_BE          : out std_logic_vector(0 to (C_LMB_DWIDTH/8 - 1));
    Sl_DBus         : in  std_logic_vector(0 to C_LMB_DWIDTH-1);
    Sl_Ready        : in  std_logic;
    Sl_Wait         : in  std_logic;
    Sl_UE           : in  std_logic;
    Sl_CE           : in  std_logic;

    lmb_select      : out std_logic);
end entity lmb_mux;

architecture imp of lmb_mux is

  component pselect_mask
    generic (
      C_AW   : integer                   := 32;
      C_BAR  : std_logic_vector(0 to 31) := X"00000000";
      C_MASK : std_logic_vector(0 to 31) := X"00800000");
    port (
      A     : in  std_logic_vector(0 to 31);
      CS    : out std_logic;
      Valid : in  std_logic);
  end component;

  signal one : std_logic;

-------------------------------------------------------------------------------
-- Begin architecture section
-------------------------------------------------------------------------------
begin  -- VHDL_RTL

  LMB1_no: if (C_NUM_LMB < 2) generate
    Sl1_DBus               <= (others => '0');
    Sl1_Ready              <= '0';
    Sl1_Wait               <= '0';
    Sl1_UE                 <= '0';
    Sl1_CE                 <= '0';
  end generate LMB1_no;
  
  LMB2_no: if (C_NUM_LMB < 3) generate
    Sl2_DBus               <= (others => '0');
    Sl2_Ready              <= '0';
    Sl2_Wait               <= '0';
    Sl2_UE                 <= '0';
    Sl2_CE                 <= '0';
  end generate LMB2_no;

  LMB3_no: if (C_NUM_LMB < 4) generate
    Sl3_DBus               <= (others => '0');
    Sl3_Ready              <= '0';
    Sl3_Wait               <= '0';
    Sl3_UE                 <= '0';
    Sl3_CE                 <= '0';
  end generate LMB3_no;
    
  one <= '1';

  one_lmb: if (C_NUM_LMB = 1) generate
  begin
    
    -----------------------------------------------------------------------------
    -- Do the LMB address decoding
    -----------------------------------------------------------------------------
    pselect_mask_lmb : pselect_mask
      generic map (
        C_AW   => LMB_ABus'length,
        C_BAR  => C_BASEADDR,
        C_MASK => C_MASK)
      port map (
        A     => LMB0_ABus,
        CS    => lmb_select,
        Valid => one);

    LMB_ABus        <= LMB0_ABus;
    LMB_WriteDBus   <= LMB0_WriteDBus;
    LMB_AddrStrobe  <= LMB0_AddrStrobe;
    LMB_ReadStrobe  <= LMB0_ReadStrobe;
    LMB_WriteStrobe <= LMB0_WriteStrobe;
    LMB_BE          <= LMB0_BE;
    Sl0_DBus        <= Sl_DBus;
    Sl0_Ready       <= Sl_Ready;
    Sl0_Wait        <= Sl_Wait;
    Sl0_UE          <= Sl_UE;
    Sl0_CE          <= Sl_CE;

  end generate one_lmb;

  more_than_one_lmb: if (C_NUM_LMB > 1) generate

    type C_Mask_Vec_T is array (0 to 3) of std_logic_vector(0 to 31);
    constant C_Mask_Vec : C_MASK_Vec_T := (C_MASK, C_MASK1, C_MASK2, C_MASK3);

    type ABus_vec_T  is array (0 to C_NUM_LMB-1) of std_logic_vector(0 to C_LMB_AWIDTH - 1); 
    type DBus_vec_T  is array (0 to C_NUM_LMB-1) of std_logic_vector(0 to C_LMB_DWIDTH - 1); 
    type BE_vec_T    is array (0 to C_NUM_LMB-1) of std_logic_vector(0 to C_LMB_DWIDTH/8 - 1);
  
    signal LMB_ABus_vec          : ABus_vec_T;
    signal LMB_ABus_vec_i        : ABus_vec_T;
    signal LMB_ABus_vec_Q        : ABus_vec_T;
    signal LMB_WriteDBus_vec     : DBus_vec_T;
    signal LMB_WriteDBus_vec_i   : DBus_vec_T;
    signal LMB_WriteDBus_vec_Q   : DBus_vec_T;
    signal LMB_AddrStrobe_vec    : std_logic_vector(0 to C_NUM_LMB-1);
    signal LMB_AddrStrobe_vec_i  : std_logic_vector(0 to C_NUM_LMB-1);
    signal LMB_AddrStrobe_vec_Q  : std_logic_vector(0 to C_NUM_LMB-1);
    signal LMB_ReadStrobe_vec    : std_logic_vector(0 to C_NUM_LMB-1);
    signal LMB_ReadStrobe_vec_i  : std_logic_vector(0 to C_NUM_LMB-1);
    signal LMB_ReadStrobe_vec_Q  : std_logic_vector(0 to C_NUM_LMB-1);
    signal LMB_WriteStrobe_vec   : std_logic_vector(0 to C_NUM_LMB-1);
    signal LMB_WriteStrobe_vec_i : std_logic_vector(0 to C_NUM_LMB-1);
    signal LMB_WriteStrobe_vec_Q : std_logic_vector(0 to C_NUM_LMB-1);
    signal LMB_BE_vec            : BE_vec_T;
    signal LMB_BE_vec_i          : BE_vec_T;
    signal LMB_BE_vec_Q          : BE_vec_T;
    signal Sl_DBus_vec           : DBus_vec_T;
    signal Sl_Ready_vec          : std_logic_vector(0 to C_NUM_LMB-1);
    signal Sl_Wait_vec           : std_logic_vector(0 to C_NUM_LMB-1);
    signal Sl_UE_vec             : std_logic_vector(0 to C_NUM_LMB-1);
    signal Sl_CE_vec             : std_logic_vector(0 to C_NUM_LMB-1);

    signal wait_vec              : std_logic_vector(0 to C_NUM_LMB-1);
    signal lmb_select_vec        : std_logic_vector(0 to C_NUM_LMB-1);
    signal as_and_lmb_select_vec : std_logic_vector(0 to C_NUM_LMB-1);

    signal ongoing     : natural range 0 to C_NUM_LMB-1;
    signal ongoing_new : natural range 0 to C_NUM_LMB-1;
    signal ongoing_Q   : natural range 0 to C_NUM_LMB-1;

  begin

    LMB_ABus_vec(0)        <= LMB0_ABus;
    LMB_WriteDBus_vec(0)   <= LMB0_WriteDBus;
    LMB_AddrStrobe_vec(0)  <= LMB0_AddrStrobe;
    LMB_ReadStrobe_vec(0)  <= LMB0_ReadStrobe;
    LMB_WriteStrobe_vec(0) <= LMB0_WriteStrobe;
    LMB_BE_vec(0)          <= LMB0_BE;
    Sl0_DBus               <= Sl_DBus_vec(0);
    Sl0_Ready              <= Sl_Ready_vec(0);
    Sl0_Wait               <= Sl_Wait_vec(0);
    Sl0_UE                 <= Sl_UE_vec(0);
    Sl0_CE                 <= Sl_CE_vec(0);

    LMB_ABus_vec(1)        <= LMB1_ABus;
    LMB_WriteDBus_vec(1)   <= LMB1_WriteDBus;
    LMB_AddrStrobe_vec(1)  <= LMB1_AddrStrobe;
    LMB_ReadStrobe_vec(1)  <= LMB1_ReadStrobe;
    LMB_WriteStrobe_vec(1) <= LMB1_WriteStrobe;
    LMB_BE_vec(1)          <= LMB1_BE;
    Sl1_DBus               <= Sl_DBus_vec(1);
    Sl1_Ready              <= Sl_Ready_vec(1);
    Sl1_Wait               <= Sl_Wait_vec(1);
    Sl1_UE                 <= Sl_UE_vec(1);
    Sl1_CE                 <= Sl_CE_vec(1);

    LMB2_yes: if (C_NUM_LMB > 2) generate
      LMB_ABus_vec(2)        <= LMB2_ABus;
      LMB_WriteDBus_vec(2)   <= LMB2_WriteDBus;
      LMB_AddrStrobe_vec(2)  <= LMB2_AddrStrobe;
      LMB_ReadStrobe_vec(2)  <= LMB2_ReadStrobe;
      LMB_WriteStrobe_vec(2) <= LMB2_WriteStrobe;
      LMB_BE_vec(2)          <= LMB2_BE;
      Sl2_DBus               <= Sl_DBus_vec(2);
      Sl2_Ready              <= Sl_Ready_vec(2);
      Sl2_Wait               <= Sl_Wait_vec(2);
      Sl2_UE                 <= Sl_UE_vec(2);
      Sl2_CE                 <= Sl_CE_vec(2);
    end generate LMB2_yes;

    LMB3_yes: if (C_NUM_LMB > 3) generate
      LMB_ABus_vec(3)        <= LMB3_ABus;
      LMB_WriteDBus_vec(3)   <= LMB3_WriteDBus;
      LMB_AddrStrobe_vec(3)  <= LMB3_AddrStrobe;
      LMB_ReadStrobe_vec(3)  <= LMB3_ReadStrobe;
      LMB_WriteStrobe_vec(3) <= LMB3_WriteStrobe;
      LMB_BE_vec(3)          <= LMB3_BE;
      Sl3_DBus               <= Sl_DBus_vec(3);
      Sl3_Ready              <= Sl_Ready_vec(3);
      Sl3_Wait               <= Sl_Wait_vec(3);
      Sl3_UE                 <= Sl_UE_vec(3);
      Sl3_CE                 <= Sl_CE_vec(3);
    end generate LMB3_yes;

    lmb_mux_generate: for I in 0 to C_NUM_LMB-1 generate
    begin

      -----------------------------------------------------------------------------
      -- Do the LMB address decoding
      -----------------------------------------------------------------------------
      pselect_mask_lmb : pselect_mask
        generic map (
          C_AW   => LMB_ABus'length,
          C_BAR  => C_BASEADDR,
          C_MASK => C_Mask_Vec(I))
        port map (
          A     => LMB_ABus_vec(I),
          CS    => lmb_select_vec(I),
          Valid => one);

      as_and_lmb_select_vec(I) <= lmb_select_vec(I) and LMB_AddrStrobe_vec(I);

      remember_access : process (LMB_Clk) is
      begin
        if (LMB_Clk'event and LMB_Clk = '1') then
          if (LMB_Rst = '1') then
            LMB_ABus_vec_Q(I)        <= (others => '0');
            LMB_WriteDBus_vec_Q(I)   <= (others => '0');
            LMB_AddrStrobe_vec_Q(I)  <= '0';
            LMB_ReadStrobe_vec_Q(I)  <= '0';
            LMB_WriteStrobe_vec_Q(I) <= '0';
            LMB_BE_vec_Q(I)          <= (others => '0');
          elsif (as_and_lmb_select_vec(I) = '1' and ongoing /= I) then
            LMB_ABus_vec_Q(I)        <= LMB_ABus_vec(I);
            LMB_WriteDBus_vec_Q(I)   <= LMB_WriteDBus_vec(I);
            LMB_AddrStrobe_vec_Q(I)  <= LMB_AddrStrobe_vec(I);
            LMB_ReadStrobe_vec_Q(I)  <= LMB_ReadStrobe_vec(I);
            LMB_WriteStrobe_vec_Q(I) <= LMB_WriteStrobe_vec(I);
            LMB_BE_vec_Q(I)          <= LMB_BE_vec(I);
          end if;
        end if;
      end process remember_access;

      wait_proc : process (LMB_Clk) is
      begin
        if (LMB_Clk'event and LMB_Clk = '1') then
          if (LMB_Rst = '1') then
            wait_vec(I) <= '0';
          elsif (as_and_lmb_select_vec(I) = '1' and ongoing /= I) then
            wait_vec(I) <= '1';
          elsif (wait_vec(I) = '1' and ongoing = I) then
            wait_vec(I) <= '0';
          end if;
        end if;
      end process wait_proc;

      LMB_ABus_vec_i(I)        <= LMB_ABus_vec_Q(I) when wait_vec(I) = '1' else
                                  LMB_ABus_vec(I);
      LMB_WriteDBus_vec_i(I)   <= LMB_WriteDBus_vec_Q(I) when wait_vec(I) = '1' else
                                  LMB_WriteDBus_vec(I);
      LMB_AddrStrobe_vec_i(I)  <= LMB_AddrStrobe_vec_Q(I) when wait_vec(I) = '1' else
                                  LMB_AddrStrobe_vec(I);
      LMB_ReadStrobe_vec_i(I)  <= LMB_ReadStrobe_vec_Q(I) when wait_vec(I) = '1' else
                                  LMB_ReadStrobe_vec(I);
      LMB_WriteStrobe_vec_i(I) <= LMB_WriteStrobe_vec_Q(I) when wait_vec(I) = '1' else
                                  LMB_WriteStrobe_vec(I);
      LMB_BE_vec_i(I)          <= LMB_BE_vec_Q(I) when wait_vec(I) = '1' else
                                  LMB_BE_vec(I);

      -- Assign selected LMB from internal signals
      Sl_DBus_vec(I)  <= Sl_DBus;
      Sl_Ready_vec(I) <= Sl_Ready when ongoing_Q = I else
                        '0';
      Sl_Wait_vec(I)  <= Sl_Wait when ongoing_Q = I else
                         wait_vec(I);
      Sl_UE_vec(I)    <= Sl_UE when ongoing_Q = I else
                        '0';
      Sl_CE_vec(I)    <= Sl_CE when ongoing_Q = I else
                        '0';
    end generate lmb_mux_generate;

    OnGoing_Reg : process (LMB_Clk) is
    begin 
      if (LMB_Clk'event and LMB_Clk = '1') then
        if (LMB_Rst = '1') then
          ongoing_Q <= 0;
        else
          ongoing_Q <= ongoing;
        end if;
      end if;
    end process OnGoing_Reg;

    Arbit : process (as_and_lmb_select_vec, wait_vec) is
      variable N : natural range 0 to C_NUM_LMB-1;
    begin 
      ongoing_new <= 0;
      for N in 0 to C_NUM_LMB - 1 loop
        if as_and_lmb_select_vec(N) = '1' or wait_vec(N) = '1' then
          ongoing_new <= N;
          exit;
        end if;
      end loop;
    end process Arbit;
  
    ongoing <= ongoing_Q when Sl_Wait = '1' and Sl_Ready = '0' else
               ongoing_new;

    -- Assign selected LMB
    LMB_ABus        <= LMB_ABus_vec_i(ongoing);
    LMB_WriteDBus   <= LMB_WriteDBus_vec_i(ongoing);
    LMB_AddrStrobe  <= LMB_AddrStrobe_vec_i(ongoing);
    LMB_ReadStrobe  <= LMB_ReadStrobe_vec_i(ongoing);
    LMB_WriteStrobe <= LMB_WriteStrobe_vec_i(ongoing);
    LMB_BE          <= LMB_BE_vec_i(ongoing);

    lmb_select      <= lmb_select_vec(ongoing) or wait_vec(ongoing);
    
  end generate more_than_one_lmb;

end imp;

