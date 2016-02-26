-------------------------------------------------------------------------------
-- qspi_startup_block.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- *******************************************************************
-- ** (c) Copyright [2010] - [2012] Xilinx, Inc. All rights reserved.*
-- **                                                                *
-- ** This file contains confidential and proprietary information    *
-- ** of Xilinx, Inc. and is protected under U.S. and                *
-- ** international copyright and other intellectual property        *
-- ** laws.                                                          *
-- **                                                                *
-- ** DISCLAIMER                                                     *
-- ** This disclaimer is not a license and does not grant any        *
-- ** rights to the materials distributed herewith. Except as        *
-- ** otherwise provided in a valid license issued to you by         *
-- ** Xilinx, and to the maximum extent permitted by applicable      *
-- ** law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND        *
-- ** WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES    *
-- ** AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING      *
-- ** BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-         *
-- ** INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and       *
-- ** (2) Xilinx shall not be liable (whether in contract or tort,   *
-- ** including negligence, or under any other theory of             *
-- ** liability) for any loss or damage of any kind or nature        *
-- ** related to, arising under or in connection with these          *
-- ** materials, including for any direct, or any indirect,          *
-- ** special, incidental, or consequential loss or damage           *
-- ** (including loss of data, profits, goodwill, or any type of     *
-- ** loss or damage suffered as a result of any action brought      *
-- ** by a third party) even if such damage or loss was              *
-- ** reasonably foreseeable or Xilinx had been advised of the       *
-- ** possibility of the same.                                       *
-- **                                                                *
-- ** CRITICAL APPLICATIONS                                          *
-- ** Xilinx products are not designed or intended to be fail-       *
-- ** safe, or for use in any application requiring fail-safe        *
-- ** performance, such as life-support or safety devices or         *
-- ** systems, Class III medical devices, nuclear facilities,        *
-- ** applications related to the deployment of airbags, or any      *
-- ** other applications that could lead to death, personal          *
-- ** injury, or severe property or environmental damage             *
-- ** (individually and collectively, "Critical                      *
-- ** Applications"). Customer assumes the sole risk and             *
-- ** liability of any use of Xilinx products in Critical            *
-- ** Applications, subject only to applicable laws and              *
-- ** regulations governing limitations on product liability.        *
-- **                                                                *
-- ** THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS       *
-- ** PART OF THIS FILE AT ALL TIMES.                                *
-- *******************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        qspi_startup_block.vhd
-- Version:         v3.0
-- Description:     This module uses the STARTUP primitive based upon the generic.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x"
--      Soft_Reset_op signals:                          "rst", "rst_n"
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
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_misc.all;
-- library unsigned is used for overloading of "=" which allows integer to
-- be compared to std_logic_vector
use ieee.std_logic_unsigned.all;

library unisim;

    --use unisim.vcomponents.STARTUP_SPARTAN6;
    --use unisim.vcomponents.STARTUP_VIRTEX6;
    use unisim.vcomponents.STARTUPE2; -- for 7-series FPGA's
	use unisim.vcomponents.STARTUPE3; -- for 8 series FPGA's

------------------------------
entity qspi_startup_block is
        generic
        (
                C_SUB_FAMILY             : string  ;
                ---------------------
                C_USE_STARTUP            : integer ;
                ---------------------
                C_SHARED_STARTUP    : integer range 0 to 1 := 0;
                ---------------------
                C_SPI_MODE               : integer
                ---------------------
        );
        port
        (
                SCK_O          : in std_logic; -- input from the spi_mode_0_module
                IO1_I_startup  : in std_logic; -- input from the top level port list
                IO1_Int        : out std_logic;
		        Bus2IP_Clk     : in std_logic;
                reset2ip_reset : in std_logic;
				CFGCLK         : out std_logic;       -- FGCLK        , -- 1-bit output: Configuration main clock output
                CFGMCLK        : out std_logic; -- FGMCLK       , -- 1-bit output: Configuration internal oscillator clock output
                EOS            : out std_logic;-- OS           , -- 1-bit output: Active high output signal indicating the End Of Startup.
                PREQ           : out std_logic;-- REQ          , -- 1-bit output: PROGRAM request to fabric output
                DI             : out std_logic_vector(3 downto 0);-- output
                DO             : in std_logic_vector(3 downto 0);-- input
                DTS            : in std_logic_vector(3 downto 0);
                FCSBO          : in std_logic;
                FCSBTS         : in std_logic;
                CLK            : in std_logic;
                GSR            : in std_logic;
                GTS            : in std_logic;
                KEYCLEARB      : in std_logic;
                PACK           : in std_logic;
                USRCCLKTS      : in std_logic;
                USRDONEO       : in std_logic;
                USRDONETS      : in std_logic
 
        );
end entity qspi_startup_block;
------------------------------

architecture imp of qspi_startup_block is

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

-- 19-11-2012 added below parameter and signals to fix the CR #679609
constant ADD_PIPELINTE : integer := 8;
signal pipe_signal     : std_logic_vector(ADD_PIPELINTE-1 downto 0);
signal PREQ_int        : std_logic;
signal PACK_int        : std_logic;
-----
begin
-----
PREQ_REG_P:process(Bus2IP_Clk)is  -- 19-11-2012
begin
     if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if(reset2ip_reset = '1')then
              pipe_signal(0) <= '0';
         elsif(PREQ_int = '1')then
              pipe_signal(0) <= '1';
         end if;
     end if;
end process PREQ_REG_P;

PIPE_PACK_P:process(Bus2IP_Clk)is -- 19-11-2012
begin
     if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if(reset2ip_reset = '1')then
              pipe_signal(ADD_PIPELINTE-1 downto 1) <= (others => '0');
         else
              pipe_signal(1) <= pipe_signal(0);
              pipe_signal(2) <= pipe_signal(1);
              pipe_signal(3) <= pipe_signal(2);
              pipe_signal(4) <= pipe_signal(3);
              pipe_signal(5) <= pipe_signal(4);
              pipe_signal(6) <= pipe_signal(5);
              pipe_signal(7) <= pipe_signal(6);
--              pipe_signal(8) <= pipe_signal(7);
         end if;
     end if;
end process PIPE_PACK_P;

PACK_int  <= pipe_signal(7); -- 19-11-2012

-- STARTUP_7SERIES_GEN: Logic instantiation of STARTUP primitive in the core.
STARTUP_7SERIES_GEN: if ( -- In 7-series, the start up is allowed in all C_SPI_MODE values.
                         C_SUB_FAMILY = "virtex7" or
                         C_SUB_FAMILY = "kintex7" or
                         (C_SUB_FAMILY = "zynq") or
                         C_SUB_FAMILY = "artix7"
                         ) and (C_USE_STARTUP = 1 and C_SHARED_STARTUP = 0) generate
-----
begin
-----

   ASSERT (
           ( -- no check for C_SPI_MODE is needed here. On S6 the startup is not supported.
            -- (C_SUB_FAMILY = "virtex6") or
            (C_SUB_FAMILY = "virtex7") or
            (C_SUB_FAMILY = "kintex7") or
            (C_SUB_FAMILY = "zynq") or
            (C_SUB_FAMILY = "artix7")  
           )and
           (C_USE_STARTUP = 1)
          )
   REPORT "*** The use of STARTUP primitive is not supported on this targeted device. ***"
   SEVERITY error;


        -------------------
        IO1_Int <= IO1_I_startup;
        -------------------

        STARTUP2_7SERIES_inst : component STARTUPE2
        -----------------------
        generic map
        (
                PROG_USR      => "FALSE", -- Activate program event security feature.
                SIM_CCLK_FREQ => 0.0      -- Set the Configuration Clock Frequency(ns) for simulation.
        )
        port map
        (
                USRCCLKO  => SCK_O,      -- SRCCLKO      , -- 1-bit input: User CCLK input
                ----------
                CFGCLK    => CFGCLK,       -- FGCLK        , -- 1-bit output: Configuration main clock output
                CFGMCLK   => CFGMCLK,       -- FGMCLK       , -- 1-bit output: Configuration internal oscillator clock output
                EOS       => EOS,       -- OS           , -- 1-bit output: Active high output signal indicating the End Of Startup.
                PREQ      => PREQ_int,       -- REQ          , -- 1-bit output: PROGRAM request to fabric output
                ----------
                CLK       => '0',        -- LK           , -- 1-bit input: User start-up clock input
                GSR       => '0',        -- SR           , -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
                GTS       => '0',        -- TS           , -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
                KEYCLEARB => '0',        -- EYCLEARB     , -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
                PACK      => PACK_int, -- '1',        -- ACK          , -- 1-bit input: PROGRAM acknowledge input
                USRCCLKTS => '0',        -- SRCCLKTS     , -- 1-bit input: User CCLK 3-state enable input
                USRDONEO  => '1',        -- SRDONEO      , -- 1-bit input: User DONE pin output control
                USRDONETS => '1'         -- SRDONETS       -- 1-bit input: User DONE 3-state enable output
        );

end generate STARTUP_7SERIES_GEN;

STARTUP_SHARE_7SERIES_GEN: if ( -- In 7-series, the start up is allowed in all C_SPI_MODE values.
                         C_SUB_FAMILY = "virtex7" or
                         C_SUB_FAMILY = "kintex7" or
                         (C_SUB_FAMILY = "zynq") or
                         C_SUB_FAMILY = "artix7"
                         ) and (C_USE_STARTUP = 1 and C_SHARED_STARTUP = 1) generate
-----
begin
-----

   ASSERT (
           ( -- no check for C_SPI_MODE is needed here. On S6 the startup is not supported.
            -- (C_SUB_FAMILY = "virtex6") or
            (C_SUB_FAMILY = "virtex7") or
            (C_SUB_FAMILY = "kintex7") or
            (C_SUB_FAMILY = "zynq") or
            (C_SUB_FAMILY = "artix7")  
           )and
           (C_USE_STARTUP = 1)
          )
   REPORT "*** The use of STARTUP primitive is not supported on this targeted device. ***"
   SEVERITY error;


        -------------------
        IO1_Int <= IO1_I_startup;
        -------------------

        STARTUP2_7SERIES_inst : component STARTUPE2
        -----------------------
        generic map
        (
                PROG_USR      => "FALSE", -- Activate program event security feature.
                SIM_CCLK_FREQ => 0.0      -- Set the Configuration Clock Frequency(ns) for simulation.
        )
        port map
        (
                USRCCLKO  => SCK_O,      -- SRCCLKO      , -- 1-bit input: User CCLK input
                ----------
                CFGCLK    => CFGCLK,       -- FGCLK        , -- 1-bit output: Configuration main clock output
                CFGMCLK   => CFGMCLK,       -- FGMCLK       , -- 1-bit output: Configuration internal oscillator clock output
                EOS       => EOS,       -- OS           , -- 1-bit output: Active high output signal indicating the End Of Startup.
                PREQ      => PREQ_int,       -- REQ          , -- 1-bit output: PROGRAM request to fabric output
                ----------
                CLK       => CLK,        -- LK           , -- 1-bit input: User start-up clock input
                GSR       => GSR,        -- SR           , -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
                GTS       => GTS,        -- TS           , -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
                KEYCLEARB => KEYCLEARB,        -- EYCLEARB     , -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
                PACK      => PACK_int, -- '1',        -- ACK          , -- 1-bit input: PROGRAM acknowledge input
                USRCCLKTS => USRCCLKTS,        -- SRCCLKTS     , -- 1-bit input: User CCLK 3-state enable input
                USRDONEO  => USRDONEO,        -- SRDONEO      , -- 1-bit input: User DONE pin output control
                USRDONETS => USRDONETS         -- SRDONETS       -- 1-bit input: User DONE 3-state enable output
        );

end generate STARTUP_SHARE_7SERIES_GEN;

---------------------------------
---STARTUP for 8 series STARTUPE3
---------------------------------
 STARTUP_8SERIES_GEN: if ( -- In 8-series, the start up is allowed in all C_SPI_MODE values.
                          (C_SUB_FAMILY /= "virtex7") and
                          (C_SUB_FAMILY /= "kintex7") and
                          (C_SUB_FAMILY /= "zynq") and
                          (C_SUB_FAMILY /= "artix7")
                           ) and C_USE_STARTUP = 1 generate
-- -----
 begin
-- -----

    ASSERT (
            ( 
             (C_SUB_FAMILY /= "virtex7") and
             (C_SUB_FAMILY /= "kintex7") and
             (C_SUB_FAMILY /= "zynq") and
             (C_SUB_FAMILY /= "artix7")
            )and

            (C_USE_STARTUP = 1)
           )
    REPORT "*** The use of STARTUP primitive is not supported on this targeted device. ***"
    SEVERITY error;


         -------------------
         IO1_Int <= IO1_I_startup;
         -------------------

         STARTUP3_8SERIES_inst : component STARTUPE3
         -----------------------
         generic map
         (
                 PROG_USR      => "FALSE", -- Activate program event security feature.
                SIM_CCLK_FREQ => 0.0      -- Set the Configuration Clock Frequency(ns) for simulation.
         )
         port map
         (
                 USRCCLKO  => SCK_O,      -- SRCCLKO      , -- 1-bit input: User CCLK input
                 ----------
                 CFGCLK    => CFGCLK,       -- FGCLK        , -- 1-bit output: Configuration main clock output
                 CFGMCLK   => CFGMCLK,       -- FGMCLK       , -- 1-bit output: Configuration internal oscillator clock output
                 EOS       => EOS,       -- OS           , -- 1-bit output: Active high output signal indicating the End Of Startup.
                 PREQ      => PREQ_int,       -- REQ          , -- 1-bit output: PROGRAM request to fabric output
                 ----------
				 DO        => DO,      -- input
				 DI        => DI,       -- output
				 DTS       => DTS,        -- input
                 FCSBO     => FCSBO,        -- input
                 FCSBTS    => FCSBTS,        -- input
                 GSR       => GSR,        -- SR           , -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
                 GTS       => GTS,        -- TS           , -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
                 KEYCLEARB => KEYCLEARB,        -- EYCLEARB     , -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
                 PACK      => PACK_int, -- '1',        -- ACK          , -- 1-bit input: PROGRAM acknowledge input
                 USRCCLKTS => USRCCLKTS,        -- SRCCLKTS     , -- 1-bit input: User CCLK 3-state enable input
                 USRDONEO  => USRDONEO,        -- SRDONEO      , -- 1-bit input: User DONE pin output control
                 USRDONETS => USRDONETS         -- SRDONETS       -- 1-bit input: User DONE 3-state enable output
         );

 end generate STARTUP_8SERIES_GEN;


PREQ <= PREQ_int;

end architecture imp;
