-------------------------------------------------------------------------------
-- proc_sys_reset - entity/architecture pair
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
-- Filename:        proc_sys_reset.vhd
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
-- Author:      rolandp
-- History:
--  kc           11/07/01      -- First version
--
--  kc           02/25/2002    -- Changed generic names C_EXT_RST_ACTIVE to
--                                C_EXT_RESET_HIGH and C_AUX_RST_ACTIVE to
--                                C_AUX_RESET_HIGH to match generics used in
--                                MicroBlaze.  Added the DCM Lock as an input
--                                to keep reset active until after the Lock
--                                is valid.
-- lcw          10/11/2004  -- Updated for NCSim
-- Ravi         09/14/2006  -- Added Attributes for synthesis
-- rolandp      04/16/2007  -- version 2.00a
-- ~~~~~~~
--  SK          03/11/10
-- ^^^^^^^
-- 1. Updated the core so support the active low "Interconnect_aresetn" and
--    "Peripheral_aresetn" signals.
-- ^^^^^^^
-- ~~~~~~~
--  SK          05/12/11
-- ^^^^^^^
-- 1. Updated the core so remove the support for PPC related functionality.
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
--      combinatorial signals:                  "*_cmb"
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
library proc_sys_reset_v5_0_8;
    use proc_sys_reset_v5_0_8.all;

-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-- Definition of Generics:
--      C_EXT_RST_WIDTH       -- External Reset Low Pass Filter setting
--      C_AUX_RST_WIDTH       -- Auxiliary Reset Low Pass Filter setting

--      C_EXT_RESET_HIGH      -- External Reset Active High or Active Low
--      C_AUX_RESET_HIGH      -= Auxiliary Reset Active High or Active Low

--      C_NUM_BUS_RST         -- Number of Bus Structures reset to generate
--      C_NUM_PERP_RST        -- Number of Peripheral resets to generate
--
--      C_NUM_INTERCONNECT_ARESETN -- No. of Active low reset to interconnect
--      C_NUM_PERP_ARESETN         -- No. of Active low reset to peripheral

-- Definition of Ports:
--      slowest_sync_clk       -- Clock
--      ext_reset_in           -- External Reset Input
--      aux_reset_in           -- Auxiliary Reset Input
--      mb_debug_sys_rst       -- MDM Reset Input
--      dcm_locked             -- DCM Locked, hold system in reset until 1
--      mb_reset               -- MB core reset out
--      bus_struct_reset       -- Bus structure reset out
--      peripheral_reset       -- Peripheral reset out

--      interconnect_aresetn   -- Interconnect Bus structure registered rst out
--      peripheral_aresetn     -- Active Low Peripheral registered reset out
-------------------------------------------------------------------------------

entity proc_sys_reset is
  generic (
    C_FAMILY                 : string    := "virtex7";
    C_EXT_RST_WIDTH          : integer   := 4;
    C_AUX_RST_WIDTH          : integer   := 4;
    C_EXT_RESET_HIGH         : std_logic := '0'; -- High active input
    C_AUX_RESET_HIGH         : std_logic := '1'; -- High active input
    C_NUM_BUS_RST            : integer   := 1;
    C_NUM_PERP_RST           : integer   := 1;

    C_NUM_INTERCONNECT_ARESETN : integer   := 1; -- 3/15/2010
    C_NUM_PERP_ARESETN         : integer   := 1  -- 3/15/2010
  );
  port (
    slowest_sync_clk     : in  std_logic;

    ext_reset_in         : in  std_logic;
    aux_reset_in         : in  std_logic;

    -- from MDM
    mb_debug_sys_rst     : in  std_logic;
    -- DCM locked information
    dcm_locked           : in  std_logic := '1';

    -- -- from PPC
    -- Core_Reset_Req_0     : in  std_logic;
    -- Chip_Reset_Req_0     : in  std_logic;
    -- System_Reset_Req_0   : in  std_logic;
    -- Core_Reset_Req_1     : in  std_logic;
    -- Chip_Reset_Req_1     : in  std_logic;
    -- System_Reset_Req_1   : in  std_logic;

    -- RstcPPCresetcore_0   : out std_logic := '0';
    -- RstcPPCresetchip_0   : out std_logic := '0';
    -- RstcPPCresetsys_0    : out std_logic := '0';
    -- RstcPPCresetcore_1   : out std_logic := '0';
    -- RstcPPCresetchip_1   : out std_logic := '0';
    -- RstcPPCresetsys_1    : out std_logic := '0';

    -- to Microblaze active high reset
    mb_reset             : out std_logic := '0';
    -- active high resets
    bus_struct_reset     : out std_logic_vector(0 to C_NUM_BUS_RST - 1)
                                                           := (others => '0');
    peripheral_reset     : out std_logic_vector(0 to C_NUM_PERP_RST - 1)
                                                           := (others => '0');
    -- active low resets
    interconnect_aresetn : out
                          std_logic_vector(0 to (C_NUM_INTERCONNECT_ARESETN-1))
                                                            := (others => '1');
    peripheral_aresetn   : out std_logic_vector(0 to (C_NUM_PERP_ARESETN-1))
                                                             := (others => '1')
   );

end entity proc_sys_reset;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture imp of proc_sys_reset is

-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-- signal Core_Reset_Req_0_d1   : std_logic := '0';  -- delayed Core_Reset_Req
-- signal Core_Reset_Req_0_d2   : std_logic := '0';  -- delayed Core_Reset_Req
-- signal Core_Reset_Req_0_d3   : std_logic := '0';  -- delayed Core_Reset_Req
-- signal Core_Reset_Req_1_d1   : std_logic := '0';  -- delayed Core_Reset_Req
-- signal Core_Reset_Req_1_d2   : std_logic := '0';  -- delayed Core_Reset_Req
-- signal Core_Reset_Req_1_d3   : std_logic := '0';  -- delayed Core_Reset_Req

signal core_cnt_en_0         : std_logic := '0'; -- Core_Reset_Req_0 counter enable
signal core_cnt_en_1         : std_logic := '0'; -- Core_Reset_Req_1 counter enable

signal core_req_edge_0       : std_logic := '1'; -- Rising edge of Core_Reset_Req_0
signal core_req_edge_1       : std_logic := '1'; -- Rising edge of Core_Reset_Req_1

signal core_cnt_0            : std_logic_vector(3 downto 0); -- core counter output
signal core_cnt_1            : std_logic_vector(3 downto 0); -- core counter output

signal lpf_reset             : std_logic; -- Low pass filtered ext or aux

--signal Chip_Reset_Req        : std_logic := '0';
--signal System_Reset_Req      : std_logic := '0';

signal Bsr_out   : std_logic;
signal Pr_out    : std_logic;

-- signal Core_out  : std_logic;
-- signal Chip_out  : std_logic;
-- signal Sys_out   : std_logic;
signal MB_out    : std_logic;

-------------------------------------------------------------------------------
-- Attributes to synthesis
-------------------------------------------------------------------------------

attribute equivalent_register_removal: string;
attribute equivalent_register_removal of bus_struct_reset : signal is "no";
attribute equivalent_register_removal of peripheral_reset : signal is "no";

attribute equivalent_register_removal of interconnect_aresetn : signal is "no";
attribute equivalent_register_removal of peripheral_aresetn : signal is "no";

begin
-------------------------------------------------------------------------------

-- ---------------------
-- -- MB_RESET_HIGH_GEN: Generate active high reset for Micro-Blaze
-- ---------------------
-- MB_RESET_HIGH_GEN: if C_INT_RESET_HIGH = 1 generate
-- begin
  MB_Reset_PROCESS: process (slowest_sync_clk)
  begin
    if (slowest_sync_clk'event and slowest_sync_clk = '1') then
      mb_reset <= MB_out;
    end if;
  end process;
-- ----------------------------------------------------------------------------
-- -- This For-generate creates D-Flip Flops for the Bus_Struct_Reset output(s)
-- ----------------------------------------------------------------------------
  BSR_OUT_DFF: for i in 0 to (C_NUM_BUS_RST-1) generate
    BSR_DFF : process (slowest_sync_clk)
    begin
      if (slowest_sync_clk'event and slowest_sync_clk = '1') then
        bus_struct_reset(i) <= Bsr_out;
      end if;
    end process;
  end generate BSR_OUT_DFF;

-- ---------------------------------------------------------------------------
-- This For-generate creates D-Flip Flops for the Interconnect_aresetn op(s)
-- ---------------------------------------------------------------------------
  ACTIVE_LOW_BSR_OUT_DFF: for i in 0 to (C_NUM_INTERCONNECT_ARESETN-1) generate
    BSR_DFF : process (slowest_sync_clk)
    begin
      if (slowest_sync_clk'event and slowest_sync_clk = '1') then
        interconnect_aresetn(i) <= not (Bsr_out);
      end if;
    end process;
  end generate ACTIVE_LOW_BSR_OUT_DFF;
-------------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- -- This For-generate creates D-Flip Flops for the Peripheral_Reset output(s)
-- ----------------------------------------------------------------------------
  PR_OUT_DFF: for i in 0 to (C_NUM_PERP_RST-1) generate
    PR_DFF : process (slowest_sync_clk)
    begin
      if (slowest_sync_clk'event and slowest_sync_clk = '1') then
        peripheral_reset(i) <= Pr_out;
      end if;
    end process;
  end generate PR_OUT_DFF;

-- ----------------------------------------------------------------------------
-- This For-generate creates D-Flip Flops for the Peripheral_aresetn op(s)
-- ----------------------------------------------------------------------------
  ACTIVE_LOW_PR_OUT_DFF: for i in 0 to (C_NUM_PERP_ARESETN-1) generate
    ACTIVE_LOW_PR_DFF : process (slowest_sync_clk)
    begin
      if (slowest_sync_clk'event and slowest_sync_clk = '1') then
        peripheral_aresetn(i) <= not(Pr_out);
      end if;
    end process;
  end generate ACTIVE_LOW_PR_OUT_DFF;
-------------------------------------------------------------------------------
-- This process defines the RstcPPCreset and MB_Reset outputs
-------------------------------------------------------------------------------
  -- Rstc_output_PROCESS_0: process (Slowest_sync_clk)
  -- begin
  --   if (Slowest_sync_clk'event and Slowest_sync_clk = '1') then
  --     RstcPPCresetcore_0  <= not (core_cnt_0(3) and core_cnt_0(2) and
  --                                 core_cnt_0(1) and core_cnt_0(0))
  --                            or Core_out;
  --     RstcPPCresetchip_0  <= Chip_out;
  --     RstcPPCresetsys_0   <= Sys_out;
  --   end if;
  -- end process;

  -- Rstc_output_PROCESS_1: process (Slowest_sync_clk)
  -- begin
  --   if (Slowest_sync_clk'event and Slowest_sync_clk = '1') then
  --     RstcPPCresetcore_1  <= not (core_cnt_1(3) and core_cnt_1(2) and
  --                                 core_cnt_1(1) and core_cnt_1(0))
  --                               or Core_out;
  --     RstcPPCresetchip_1  <= Chip_out;
  --     RstcPPCresetsys_1   <= Sys_out;
  --   end if;
  -- end process;

-------------------------------------------------------------------------------

---------------------------------------------------------------------------------
---- This process delays signals so the the edge can be detected and used
----  Double register to sync up with slowest_sync_clk
---------------------------------------------------------------------------------
--  DELAY_PROCESS_0: process (Slowest_sync_clk)
--  begin
--    if (Slowest_sync_clk'event and Slowest_sync_clk = '1') then
--      core_reset_req_0_d1   <= Core_Reset_Req_0;
--      core_reset_req_0_d2   <= core_reset_req_0_d1;
--      core_reset_req_0_d3   <= core_reset_req_0_d2;
--    end if;
--  end process;
--
--  DELAY_PROCESS_1: process (Slowest_sync_clk)
--  begin
--    if (Slowest_sync_clk'event and Slowest_sync_clk = '1') then
--      core_reset_req_1_d1   <= Core_Reset_Req_1;
--      core_reset_req_1_d2   <= core_reset_req_1_d1;
--      core_reset_req_1_d3   <= core_reset_req_1_d2;
--    end if;
--  end process;


-- ** -- -------------------------------------------------------------------------------
-- ** -- -- This instantiates a counter to ensure the Core_Reset_Req_* will genereate a
-- ** -- -- RstcPPCresetcore_* that is a mimimum of 15 clocks
-- ** -- -------------------------------------------------------------------------------
-- ** --   CORE_RESET_0 : entity proc_sys_reset_v5_0_8.UPCNT_N
-- ** --   generic map (C_SIZE => 4)
-- ** --   port map(
-- ** --     Data     => "0000",                    -- in  STD_LOGIC_VECTOR (C_SIZE-1 downto 0);
-- ** --     Cnt_en   => core_cnt_en_0,             -- in  STD_LOGIC;                           
-- ** --     Load     => '0',                       -- in  STD_LOGIC;                           
-- ** --     Clr      => core_req_edge_0,           -- in  STD_LOGIC;                           
-- ** --     Clk      => Slowest_sync_clk,          -- in  STD_LOGIC;                           
-- ** --     Qout     => core_cnt_0                 -- out STD_LOGIC_VECTOR (C_SIZE-1 downto 0) 
-- ** --   );
-- ** -- 
-- ** --   CORE_RESET_1 : entity proc_sys_reset_v5_0_8.UPCNT_N
-- ** --   generic map (C_SIZE => 4)
-- ** --   port map(
-- ** --     Data     => "0000",                    -- in  STD_LOGIC_VECTOR (C_SIZE-1 downto 0);
-- ** --     Cnt_en   => core_cnt_en_1,             -- in  STD_LOGIC;                           
-- ** --     Load     => '0',                       -- in  STD_LOGIC;                           
-- ** --     Clr      => core_req_edge_1,           -- in  STD_LOGIC;                           
-- ** --     Clk      => Slowest_sync_clk,          -- in  STD_LOGIC;                           
-- ** --     Qout     => core_cnt_1                 -- out STD_LOGIC_VECTOR (C_SIZE-1 downto 0) 
-- ** --   );
-- ** -- 
-- ** -- -------------------------------------------------------------------------------
-- ** -- -- CORE_RESET_PROCESS
-- ** -- -------------------------------------------------------------------------------
-- ** -- --  This generates the reset pulse and the count enable to core reset counter
-- ** -- --
-- ** --   CORE_RESET_PROCESS_0: process (Slowest_sync_clk)
-- ** --   begin
-- ** --      if (Slowest_sync_clk'event and Slowest_sync_clk = '1') then
-- ** --        core_cnt_en_0   <= not (core_cnt_0(3) and core_cnt_0(2) and core_cnt_0(1));
-- ** --                           --or not core_req_edge_0;
-- ** --        --core_req_edge_0 <= not(Core_Reset_Req_0_d2 and not Core_Reset_Req_0_d3);
-- ** --      end if;
-- ** --   end process;
-- ** -- 
-- ** --   CORE_RESET_PROCESS_1: process (Slowest_sync_clk)
-- ** --   begin
-- ** --     if (Slowest_sync_clk'event and Slowest_sync_clk = '1') then
-- ** --       core_cnt_en_1   <= not (core_cnt_1(3) and core_cnt_1(2) and core_cnt_1(1));
-- ** --                          --or not core_req_edge_1;
-- ** --       --core_req_edge_1 <= not(Core_Reset_Req_1_d2 and not Core_Reset_Req_1_d3);
-- ** --     end if;
-- ** --   end process;

-------------------------------------------------------------------------------
-- This instantiates a low pass filter to filter both External and Auxiliary
-- Reset Inputs.
-------------------------------------------------------------------------------
  EXT_LPF : entity proc_sys_reset_v5_0_8.LPF
  generic map (
    C_EXT_RST_WIDTH  => C_EXT_RST_WIDTH,
    C_AUX_RST_WIDTH  => C_AUX_RST_WIDTH,
    C_EXT_RESET_HIGH => C_EXT_RESET_HIGH,
    C_AUX_RESET_HIGH => C_AUX_RESET_HIGH
  )
  port map(
    MB_Debug_Sys_Rst       => mb_debug_sys_rst,        --  in  std_logic
    Dcm_locked             => dcm_locked,              --  in  std_logic
    External_System_Reset  => ext_reset_in,            --  in  std_logic
    Auxiliary_System_Reset => aux_reset_in,            --  in  std_logic
    Slowest_Sync_Clk       => slowest_sync_clk,        --  in  std_logic
    Lpf_reset              => lpf_reset                --  out std_logic
  );

-------------------------------------------------------------------------------
-- This instantiates the sequencer
--  This controls the time between resets becoming inactive
-------------------------------------------------------------------------------

  -- System_Reset_Req <= System_Reset_Req_0 or System_Reset_Req_1;

  -- Chip_Reset_Req   <= Chip_Reset_Req_0 or Chip_Reset_Req_1;

  SEQ : entity proc_sys_reset_v5_0_8.SEQUENCE_PSR
  --generic map (
  --  C_EXT_RESET_HIGH_1 => C_EXT_RESET_HIGH
  --)
  port map(
    Lpf_reset         => lpf_reset,                    -- in  std_logic
    --System_Reset_Req  => '0', -- System_Reset_Req,     -- in  std_logic
    --Chip_Reset_Req    => '0', -- Chip_Reset_Req,       -- in  std_logic
    Slowest_Sync_Clk  => slowest_sync_clk,             -- in  std_logic
    Bsr_out           => Bsr_out,                      -- out std_logic
    Pr_out            => Pr_out,                       -- out std_logic
    --Core_out          => open, -- Core_out,            -- out std_logic
    --Chip_out          => open, -- Chip_out,            -- out std_logic
    --Sys_out           => open, -- Sys_out,             -- out std_logic
    MB_out            => MB_out);                      -- out std_logic

end imp;

--END_SINGLE_FILE_TAG
