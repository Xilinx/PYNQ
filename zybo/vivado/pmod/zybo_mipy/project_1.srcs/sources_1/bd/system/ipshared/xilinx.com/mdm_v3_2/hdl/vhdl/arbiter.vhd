-------------------------------------------------------------------------------
-- arbiter.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2014 Xilinx, Inc. All rights reserved.
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
-- Filename:        arbiter.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              arbiter.vhd
--                  mdm_primitives.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
--
-- History:
--   goran   2014/05/08    First Version
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
use ieee.numeric_std.all;

entity Arbiter is
  generic (
    Size      : natural := 32;
    Size_Log2 : natural := 5);
  port (
    Clk       : in  std_logic;
    Reset     : in  std_logic;

    Enable    : in  std_logic;
    Requests  : in  std_logic_vector(Size-1 downto 0);
    Granted   : out std_logic_vector(Size-1 downto 0);
    Valid_Sel : out std_logic;
    Selected  : out std_logic_vector(Size_Log2-1 downto 0));
end entity Arbiter;

architecture IMP of Arbiter is

  component select_bit
    generic (
      sel_value : std_logic_vector(1 downto 0));
    port (
      Mask      : in  std_logic_vector(1 downto 0);
      Request   : in  std_logic_vector(1 downto 0);
      Carry_In  : in  std_logic;
      Carry_Out : out std_logic);
  end component select_bit;

  component carry_or_vec
    generic (
      Size : natural);
    port (
      Carry_In  : in std_logic;
      In_Vec    : in  std_logic_vector(0 to Size-1);
      Carry_Out : out std_logic);
  end component carry_or_vec;

  component carry_and
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_and;

  component carry_or
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_or;

  subtype index_type is std_logic_vector(Size_Log2-1 downto 0);
  type int_array_type is array (natural range 2*Size-1 downto 0) of index_type;

  function init_index_table return int_array_type is
    variable tmp : int_array_type;
  begin  -- function init_index_table
    for I in 0 to Size-1 loop
      tmp(I)      := std_logic_vector(to_unsigned(I, Size_Log2));
      tmp(Size+I) := std_logic_vector(to_unsigned(I, Size_Log2));
    end loop;  -- I
    return tmp;
  end function init_index_table;

  constant index_table : int_array_type := init_index_table;

  signal long_req      : std_logic_vector(2*Size-1 downto 0);    
  signal mask          : std_logic_vector(2*Size-1 downto 0);

  signal grant_sel     : std_logic_vector(Size_Log2-1 downto 0);

  signal new_granted   : std_logic;
  signal reset_loop    : std_logic;
  signal mask_reset    : std_logic;

  signal valid_grant   : std_logic;

begin  -- architecture IMP

  long_req <= Requests & Requests;

  Request_Or : carry_or_vec
    generic map (
        Size    => Size)
    port map (
      Carry_In  => Enable,
      In_Vec    => Requests,            -- in  
      Carry_Out => new_granted);        -- out

  Valid_Sel <= new_granted;

  -----------------------------------------------------------------------------
  -- Generate Carry-Chain structure
  -----------------------------------------------------------------------------

  Chain: for I in Size_Log2-1 downto 0 generate
    signal carry : std_logic_vector(Size downto 0);  -- Assumes 2 bit/muxcy
  begin  -- generate Bits

    carry(Size) <= '0';

    Bits: for J in Size-1 downto 0 generate
      constant sel1 : std_logic := index_table(2*J+1)(I);
      constant sel0 : std_logic := index_table(2*J)(I);
      
      attribute keep_hierarchy : string;
      attribute keep_hierarchy of Select_bits : label is "yes";
    begin  -- generate Bits
      Select_bits : select_bit
        generic map (
            sel_value => sel1 & sel0)
        port map (
            Mask      => mask(2*J+1 downto 2*J),      -- in  
            Request   => long_req(2*J+1 downto 2*J),  -- in  
            Carry_In  => carry(J+1),                  -- in  
            Carry_Out => carry(J));                   -- out
    end generate Bits;

    grant_sel(I) <= carry(0);
  end generate Chain;

  Selected <= grant_sel;

  -----------------------------------------------------------------------------
  -- Handling Mask value
  -----------------------------------------------------------------------------

  -- if (Reset = '1') or ((new_granted and mask(1)) = '1') then
  Reset_loop_and : carry_and
    port map (
        Carry_IN  => new_granted,       -- in  
        A         => mask(1),           -- in  
        Carry_OUT => reset_loop);       -- out

  Mask_Reset_carry : carry_or
    port map (
        Carry_IN  => reset_loop,        -- in  
        A         => Reset,             -- in  
        Carry_OUT => mask_reset);       -- out

  Mask_Handler : process (Clk) is
  begin  -- process Mask_Handler
    if Clk'event and Clk = '1' then     -- rising clock edge
      if (mask_reset = '1') then        -- synchronous reset (active high)
        mask(2*Size-1 downto Size) <= (others => '1');
        mask(Size-1 downto 0)      <= (others => '0');
      else        
        if (new_granted = '1') then
          mask(2*Size-1 downto 1) <= mask(1) & mask(2*Size-1 downto 2);
        end if;
      end if;
    end if;
  end process Mask_Handler;

  -----------------------------------------------------------------------------
  -- Generate grant signal
  -----------------------------------------------------------------------------

  Grant_Signals: for K in Size-1 downto 1 generate
    signal tmp : std_logic;
    attribute keep : string;
    attribute keep of tmp : signal is "true";
  begin  -- generate Grant_Signals
    tmp <=  '1' when (K = to_integer(unsigned(grant_sel))) else '0';
    granted(K) <= tmp;
  end generate Grant_Signals;

  Granted(0) <= Requests(0) when to_integer(unsigned(grant_sel)) = 0 else '0';    

end architecture IMP;
