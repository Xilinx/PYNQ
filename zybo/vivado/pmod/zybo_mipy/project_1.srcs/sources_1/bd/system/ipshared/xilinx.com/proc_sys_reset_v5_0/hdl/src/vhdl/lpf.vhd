-------------------------------------------------------------------------------
-- lpf - entity/architecture pair
-------------------------------------------------------------------------------
--
-- ************************************************************************
-- ** DISCLAIMER OF LIABILITY                                            **
-- **                                                                    **
-- ** This file contains proprietary and confidential information of     **
-- ** Xilinx, Inc. ("Xilinx"), that is distributed under a license       **
-- ** from Xilinx, and may be used, copied and/or disclosed only         **
-- ** pursuant to the terms of a valid license agreement with Xilinx.    **
-- **                                                                    **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION              **
-- ** ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER         **
-- ** EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT                **
-- ** LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,          **
-- ** MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx      **
-- ** does not warrant that functions included in the Materials will     **
-- ** meet the requirements of Licensee, or that the operation of the    **
-- ** Materials will be uninterrupted or error-free, or that defects     **
-- ** in the Materials will be corrected. Furthermore, Xilinx does       **
-- ** not warrant or make any representations regarding use, or the      **
-- ** results of the use, of the Materials in terms of correctness,      **
-- ** accuracy, reliability or otherwise.                                **
-- **                                                                    **
-- ** Xilinx products are not designed or intended to be fail-safe,      **
-- ** or for use in any application requiring fail-safe performance,     **
-- ** such as life-support or safety devices or systems, Class III       **
-- ** medical devices, nuclear facilities, applications related to       **
-- ** the deployment of airbags, or any other applications that could    **
-- ** lead to death, personal injury or severe property or               **
-- ** environmental damage (individually and collectively, "critical     **
-- ** applications"). Customer assumes the sole risk and liability       **
-- ** of any use of Xilinx products in critical applications,            **
-- ** subject only to applicable laws and regulations governing          **
-- ** limitations on product liability.                                  **
-- **                                                                    **
-- ** Copyright 2012 Xilinx, Inc.                                        **
-- ** All rights reserved.                                               **
-- **                                                                    **
-- ** This disclaimer and copyright notice must be retained as part      **
-- ** of this file at all times.                                         **
-- ************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        lpf.vhd
-- Version:         v4.00a
-- Description:     Parameterizeable top level processor reset module.
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   This section should show the hierarchical structure of the
--              designs.Separate lines with blank lines if necessary to improve
--              readability.
--
--              proc_sys_reset.vhd
--                  upcnt_n.vhd
--                  lpf.vhd
--                  sequence.vhd
-------------------------------------------------------------------------------
-- Author:      Kurt Conover
-- History:
--  Kurt Conover      11/08/01      -- First Release
--
--  KC                02/25/2002    -- Added Dcm_locked as an input
--                                  -- Added Power on reset srl_time_out
--
--  KC                08/26/2003    -- Added attribute statements for power on 
--                                     reset SRL
--
-- ~~~~~~~
--  SK          03/11/10
-- ^^^^^^^
-- 1. Updated the core so support the active low "Interconnect_aresetn" and
--    "Peripheral_aresetn" signals.
-- ^^^^^^^
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
library lib_cdc_v1_0_2;
--use lib_cdc_v1_0_2.all;
library Unisim; 
    use Unisim.all; 
-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-- Definition of Generics:
--          C_EXT_RST_WIDTH       -- External Reset Low Pass Filter setting
--          C_AUX_RST_WIDTH       -- Auxiliary Reset Low Pass Filter setting   
--          C_EXT_RESET_HIGH      -- External Reset Active High or Active Low
--          C_AUX_RESET_HIGH      -= Auxiliary Reset Active High or Active Low
--
-- Definition of Ports:
--          Slowest_sync_clk       -- Clock 
--          External_System_Reset  -- External Reset Input
--          Auxiliary_System_Reset -- Auxiliary Reset Input
--          Dcm_locked             -- DCM Locked, hold system in reset until 1
--          Lpf_reset              -- Low Pass Filtered Output
--
-------------------------------------------------------------------------------
entity lpf is
   generic(
           C_EXT_RST_WIDTH    : Integer;
           C_AUX_RST_WIDTH    : Integer;
           C_EXT_RESET_HIGH   : std_logic;
           C_AUX_RESET_HIGH   : std_logic 
          );
      
   port(
        MB_Debug_Sys_Rst         : in  std_logic;
        Dcm_locked               : in  std_logic;
        External_System_Reset    : in  std_logic; 
        Auxiliary_System_Reset   : in  std_logic;                         
        Slowest_Sync_Clk         : in  std_logic; 
        Lpf_reset                : out std_logic                          
       );
      
end lpf;

architecture imp of lpf is

component SRL16 is 
-- synthesis translate_off 
  generic ( 
        INIT : bit_vector ); 
-- synthesis translate_on 
  port (D    : in  std_logic; 
        CLK  : in  std_logic; 
        A0   : in  std_logic; 
        A1   : in  std_logic; 
        A2   : in  std_logic; 
        A3   : in  std_logic; 
        Q    : out std_logic); 
end component SRL16; 


constant CLEAR : std_logic := '0';

signal exr_d1        : std_logic := '0'; -- delayed External_System_Reset
signal exr_lpf       : std_logic_vector(0 to C_EXT_RST_WIDTH - 1)
                             := (others => '0'); -- LPF DFF
                             
signal asr_d1        : std_logic := '0'; -- delayed Auxiliary_System_Reset
signal asr_lpf       : std_logic_vector(0 to C_AUX_RST_WIDTH - 1)
                             := (others => '0'); -- LPF DFF
                             
signal exr_and       : std_logic := '0'; -- varible input width "and" gate
signal exr_nand      : std_logic := '0'; -- vaiable input width "and" gate
                     
signal asr_and       : std_logic := '0'; -- varible input width "and" gate
signal asr_nand      : std_logic := '0'; -- vaiable input width "and" gate
                     
signal lpf_int       : std_logic := '0'; -- internal Lpf_reset
signal lpf_exr       : std_logic := '0';
signal lpf_asr       : std_logic := '0';
                     
signal srl_time_out  : std_logic;

attribute INIT             : string;
attribute INIT of POR_SRL_I: label is "FFFF";


begin

   Lpf_reset <= lpf_int;
   
-------------------------------------------------------------------------------
-- Power On Reset Generation
-------------------------------------------------------------------------------
--  This generates a reset for the first 16 clocks after a power up
-------------------------------------------------------------------------------
  POR_SRL_I: SRL16 
-- synthesis translate_off 
    generic map ( 
      INIT => X"FFFF") 
-- synthesis translate_on 
    port map ( 
      D   => '0', 
      CLK => Slowest_sync_clk, 
      A0  => '1', 
      A1  => '1', 
      A2  => '1', 
      A3  => '1', 
      Q   => srl_time_out); 
   
-------------------------------------------------------------------------------
-- LPF_OUTPUT_PROCESS
-------------------------------------------------------------------------------
--  This generates the reset pulse and the count enable to core reset counter
--
--ACTIVE_HIGH_LPF_EXT: if  (C_EXT_RESET_HIGH = '1') generate  
--begin
LPF_OUTPUT_PROCESS: process (Slowest_sync_clk)
begin
    if (Slowest_sync_clk'event and Slowest_sync_clk = '1') then
       lpf_int <= lpf_exr or lpf_asr or srl_time_out or not Dcm_locked;
    end if;
end process LPF_OUTPUT_PROCESS;
--end generate ACTIVE_HIGH_LPF_EXT;

--ACTIVE_LOW_LPF_EXT: if  (C_EXT_RESET_HIGH = '0') generate  
--begin
--LPF_OUTPUT_PROCESS: process (Slowest_sync_clk)
--   begin
--      if (Slowest_sync_clk'event and Slowest_sync_clk = '1') then
--         lpf_int <= not (lpf_exr      or 
--	                 lpf_asr      or 
--			 srl_time_out)or 
--			 not Dcm_locked;
--      end if;
--   end process;
--end generate ACTIVE_LOW_LPF_EXT;

EXR_OUTPUT_PROCESS: process (Slowest_sync_clk)
begin
   if (Slowest_sync_clk'event and Slowest_sync_clk = '1') then
      if exr_and = '1' then
         lpf_exr <= '1';
      elsif (exr_and = '0' and exr_nand = '1') then
         lpf_exr <= '0';
      end if;
   end if;
end process EXR_OUTPUT_PROCESS;

ASR_OUTPUT_PROCESS: process (Slowest_sync_clk)
begin
   if (Slowest_sync_clk'event and Slowest_sync_clk = '1') then
      if asr_and = '1' then
         lpf_asr <= '1';
      elsif (asr_and = '0' and asr_nand = '1') then
         lpf_asr <= '0';
      end if;
   end if;
end process ASR_OUTPUT_PROCESS;
-------------------------------------------------------------------------------
-- This If-generate selects an active high input for External System Reset 
-------------------------------------------------------------------------------
ACTIVE_HIGH_EXT: if (C_EXT_RESET_HIGH /= '0') generate  
begin
   -----------------------------------
exr_d1 <= External_System_Reset or MB_Debug_Sys_Rst;

ACT_HI_EXT: entity lib_cdc_v1_0_2.cdc_sync
  generic map (
    C_CDC_TYPE           => 1,
    C_RESET_STATE        => 0,
    C_SINGLE_BIT         => 1,
    C_FLOP_INPUT         => 0,
    C_VECTOR_WIDTH       => 2,
    C_MTBF_STAGES        => 4
            )
  port map(
    prmry_aclk            => '1',
    prmry_resetn          => '1',--S_AXI_ARESETN,
    prmry_in              => exr_d1,
    prmry_ack             => open,
    scndry_out            => exr_lpf(0),
    scndry_aclk           => Slowest_Sync_Clk,
    scndry_resetn         => '1', --S_AXIS_ARESETN,
    prmry_vect_in         => "00",
    scndry_vect_out       => open
     );

-----------------------------------
end generate ACTIVE_HIGH_EXT;
-------------------------------------------------------------------------------
-- This If-generate selects an active low input for External System Reset 
-------------------------------------------------------------------------------
ACTIVE_LOW_EXT: if  (C_EXT_RESET_HIGH = '0') generate  
begin
exr_d1 <= not External_System_Reset or MB_Debug_Sys_Rst;
   -------------------------------------

ACT_LO_EXT: entity lib_cdc_v1_0_2.cdc_sync
  generic map (
    C_CDC_TYPE           => 1,
    C_RESET_STATE        => 0,
    C_SINGLE_BIT         => 1,
    C_FLOP_INPUT         => 0,
    C_VECTOR_WIDTH       => 2,
    C_MTBF_STAGES        => 4
            )
  port map(
    prmry_aclk            => '1',
    prmry_resetn          => '1',--S_AXI_ARESETN,
    prmry_in              => exr_d1,
    prmry_ack             => open,
    scndry_out            => exr_lpf(0),
    scndry_aclk           => Slowest_Sync_Clk,
    scndry_resetn         => '1', --S_AXIS_ARESETN,
    prmry_vect_in         => "00",
    scndry_vect_out       => open
     );
-------------------------------------
end generate ACTIVE_LOW_EXT;

-------------------------------------------------------------------------------
-- This If-generate selects an active high input for Auxiliary System Reset 
-------------------------------------------------------------------------------
ACTIVE_HIGH_AUX: if (C_AUX_RESET_HIGH /= '0') generate  
begin
asr_d1 <= Auxiliary_System_Reset;
-------------------------------------

ACT_HI_AUX: entity lib_cdc_v1_0_2.cdc_sync
  generic map (
    C_CDC_TYPE           => 1,
    C_RESET_STATE        => 0,
    C_SINGLE_BIT         => 1,
    C_FLOP_INPUT         => 0,
    C_VECTOR_WIDTH       => 2,
    C_MTBF_STAGES        => 4
            )
  port map(
    prmry_aclk            => '1',
    prmry_resetn          => '1',--S_AXI_ARESETN,
    prmry_in              => asr_d1,
    prmry_ack             => open,
    scndry_out            => asr_lpf(0),
    scndry_aclk           => Slowest_Sync_Clk,
    scndry_resetn         => '1', --S_AXIS_ARESETN,
    prmry_vect_in         => "00",
    scndry_vect_out       => open
     );
   -------------------------------------
end generate ACTIVE_HIGH_AUX;
-------------------------------------------------------------------------------
-- This If-generate selects an active low input for Auxiliary System Reset 
-------------------------------------------------------------------------------
ACTIVE_LOW_AUX: if (C_AUX_RESET_HIGH = '0') generate  
begin
   -------------------------------------
asr_d1 <= not Auxiliary_System_Reset;

ACT_LO_AUX: entity lib_cdc_v1_0_2.cdc_sync
  generic map (
    C_CDC_TYPE           => 1,
    C_RESET_STATE        => 0,
    C_SINGLE_BIT         => 1,
    C_FLOP_INPUT         => 0,
    C_VECTOR_WIDTH       => 2,
    C_MTBF_STAGES        => 4
            )
  port map(
    prmry_aclk            => '1',
    prmry_resetn          => '1',--S_AXI_ARESETN,
    prmry_in              => asr_d1,
    prmry_ack             => open,
    scndry_out            => asr_lpf(0),
    scndry_aclk           => Slowest_Sync_Clk,
    scndry_resetn         => '1', --S_AXIS_ARESETN,
    prmry_vect_in         => "00",
    scndry_vect_out       => open
     );
   -------------------------------------
end generate ACTIVE_LOW_AUX;

-------------------------------------------------------------------------------
-- This For-generate creates the low pass filter D-Flip Flops
-------------------------------------------------------------------------------
EXT_LPF: for i in 1 to C_EXT_RST_WIDTH - 1 generate
begin
   ----------------------------------------
   EXT_LPF_DFF : process (Slowest_Sync_Clk)
   begin
      if (Slowest_Sync_Clk'event) and Slowest_Sync_Clk = '1' then
         exr_lpf(i) <= exr_lpf(i-1);
      end if;
   end process;
   ----------------------------------------
end generate EXT_LPF;
------------------------------------------------------------------------------------------
-- Implement the 'AND' function on the for the LPF
------------------------------------------------------------------------------------------
EXT_LPF_AND : process (exr_lpf)
Variable loop_and  : std_logic;
Variable loop_nand : std_logic;
Begin
   loop_and  := '1';
   loop_nand := '1';
   for j in 0 to C_EXT_RST_WIDTH - 1 loop
      loop_and  := loop_and and      exr_lpf(j);
      loop_nand := loop_nand and not exr_lpf(j);
   End loop;
  
   exr_and  <= loop_and;
   exr_nand <= loop_nand;

end process; 

-------------------------------------------------------------------------------
-- This For-generate creates the low pass filter D-Flip Flops
-------------------------------------------------------------------------------
AUX_LPF: for k in 1 to C_AUX_RST_WIDTH - 1 generate
begin
   ----------------------------------------
   AUX_LPF_DFF : process (Slowest_Sync_Clk)
   begin
      if (Slowest_Sync_Clk'event) and Slowest_Sync_Clk = '1' then
         asr_lpf(k) <= asr_lpf(k-1);
      end if;
   end process;
   ----------------------------------------
end generate AUX_LPF;
------------------------------------------------------------------------------------------
-- Implement the 'AND' function on the for the LPF
------------------------------------------------------------------------------------------
AUX_LPF_AND : process (asr_lpf)
Variable aux_loop_and  : std_logic;
Variable aux_loop_nand : std_logic;
Begin
   aux_loop_and  := '1';
   aux_loop_nand := '1';
   for m in 0 to C_AUX_RST_WIDTH - 1 loop
      aux_loop_and  := aux_loop_and and      asr_lpf(m);
      aux_loop_nand := aux_loop_nand and not asr_lpf(m);
   End loop;
  
   asr_and  <= aux_loop_and;
   asr_nand <= aux_loop_nand;

end process; 

end imp;
  

