-------------------------------------------------------------------------------
-- lmb_v10.vhd - Entity and architecture
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
-------------------------------------------------------------------------------
-- Filename:        lmb_v10.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              lmb_v10.vhd
--
-------------------------------------------------------------------------------
-- Author:          rolandp
--
-- History:
--  goran   2002-01-30    First Version
--  paulo   2002-04-10    Renamed C_NUM_SLAVES to C_LMB_NUM_SLAVES
--  roland  2010-02-13    UE, CE and Wait signals added
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

entity lmb_v10 is

  generic (
    C_LMB_NUM_SLAVES     : integer := 4;
    C_LMB_DWIDTH     : integer := 32;
    C_LMB_AWIDTH     : integer := 32;
    C_EXT_RESET_HIGH : integer := 1
    );

  port (
    -- Global Ports
    LMB_Clk : in  std_logic;
    SYS_Rst : in  std_logic;
    LMB_Rst : out std_logic;

    -- LMB master signals
    M_ABus        : in std_logic_vector(0 to C_LMB_AWIDTH-1);
    M_ReadStrobe  : in std_logic;
    M_WriteStrobe : in std_logic;
    M_AddrStrobe  : in std_logic;
    M_DBus        : in std_logic_vector(0 to C_LMB_DWIDTH-1);
    M_BE          : in std_logic_vector(0 to (C_LMB_DWIDTH+7)/8-1);

    -- LMB slave signals
    Sl_DBus  : in std_logic_vector(0 to (C_LMB_DWIDTH*C_LMB_NUM_SLAVES)-1);
    Sl_Ready : in std_logic_vector(0 to C_LMB_NUM_SLAVES-1);
    Sl_Wait  : in std_logic_vector(0 to C_LMB_NUM_SLAVES-1);
    Sl_UE    : in std_logic_vector(0 to C_LMB_NUM_SLAVES-1);
    Sl_CE    : in std_logic_vector(0 to C_LMB_NUM_SLAVES-1);
    
    -- LMB output signals
    LMB_ABus        : out std_logic_vector(0 to C_LMB_AWIDTH-1);
    LMB_ReadStrobe  : out std_logic;
    LMB_WriteStrobe : out std_logic;
    LMB_AddrStrobe  : out std_logic;
    LMB_ReadDBus    : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB_WriteDBus   : out std_logic_vector(0 to C_LMB_DWIDTH-1);
    LMB_Ready       : out std_logic;
    LMB_Wait        : out std_logic;
    LMB_UE          : out std_logic;
    LMB_CE          : out std_logic;
    LMB_BE          : out std_logic_vector(0 to (C_LMB_DWIDTH+7)/8-1)
    );
end entity lmb_v10;

library unisim;
use unisim.all;

architecture IMP of lmb_v10 is

  component FDS is
    port(
      Q : out std_logic;
      D : in  std_logic;
      C : in  std_logic;
      S : in  std_logic);
  end component FDS;

  signal sys_rst_i    : std_logic;

begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- Driving the reset signal
  -----------------------------------------------------------------------------

  SYS_RST_PROC : process (SYS_Rst) is
    variable sys_rst_input : std_logic;
  begin
    if C_EXT_RESET_HIGH = 0 then
      sys_rst_input := not SYS_Rst;
    else
      sys_rst_input := SYS_Rst;
    end if;
    sys_rst_i <= sys_rst_input;
  end process SYS_RST_PROC;

  POR_FF_I : FDS
    port map (
      Q => LMB_Rst,
      D => '0',
      C => LMB_Clk,
      S => sys_rst_i);

  -----------------------------------------------------------------------------
  -- Drive all Master to Slave signals
  -----------------------------------------------------------------------------
  LMB_ABus        <= M_ABus;
  LMB_ReadStrobe  <= M_ReadStrobe;
  LMB_WriteStrobe <= M_WriteStrobe;
  LMB_AddrStrobe  <= M_AddrStrobe;
  LMB_BE          <= M_BE;
  LMB_WriteDBus   <= M_DBus;

  -----------------------------------------------------------------------------
  -- Drive all the Slave to Master signals
  -----------------------------------------------------------------------------
  Ready_ORing : process (Sl_Ready) is
    variable i : std_logic;
  begin  -- process Ready_ORing
    i := '0';
    for S in Sl_Ready'range loop
      i := i or Sl_Ready(S);
    end loop;  -- S
    LMB_Ready <= i;
  end process Ready_ORing;

  Wait_ORing : process (Sl_Wait) is
    variable i : std_logic;
  begin  -- process Wait_ORing
    i := '0';
    for S in Sl_Wait'range loop
      i := i or Sl_Wait(S);
    end loop;  -- S
    LMB_Wait <= i;
  end process Wait_ORing;

  SI_UE_ORing : process (Sl_UE) is
  variable i : std_logic;
  begin  -- process UE_ORing
    i := '0';
    for S in Sl_UE'range loop
      i := i or Sl_UE(S);
    end loop;  -- S
    LMB_UE <= i;
  end process SI_UE_ORing;

  SI_CE_ORing : process (Sl_CE) is
  variable i : std_logic;
  begin  -- process CE_ORing
    i := '0';
    for S in Sl_CE'range loop
      i := i or Sl_CE(S);
    end loop;  -- S
    LMB_CE <= i;
  end process SI_CE_ORing;

  DBus_Oring : process (Sl_Ready, Sl_DBus) is
    variable Res    : std_logic_vector(0 to C_LMB_DWIDTH-1);
    variable Tmp    : std_logic_vector(Sl_DBus'range);
    variable tmp_or : std_logic;
  begin  -- process DBus_Oring
    if (C_LMB_NUM_SLAVES = 1) then
      LMB_ReadDBus <= Sl_DBus;
    else
      -- First gating all data signals with their resp. ready signal
      for I in 0 to C_LMB_NUM_SLAVES-1 loop
        for J in 0 to C_LMB_DWIDTH-1 loop
          tmp(I*C_LMB_DWIDTH + J) := Sl_Ready(I) and Sl_DBus(I*C_LMB_DWIDTH + J);
        end loop;  -- J
      end loop;  -- I
      -- then oring the tmp signals together
      for J in 0 to C_LMB_DWIDTH-1 loop
        tmp_or := '0';
        for I in 0 to C_LMB_NUM_SLAVES-1 loop
          tmp_or := tmp_or or tmp(I*C_LMB_DWIDTH + j);
        end loop;  -- J
        res(J) := tmp_or;
      end loop;  -- I
      LMB_ReadDBus <= Res;
    end if;
  end process DBus_Oring;

end architecture IMP;



