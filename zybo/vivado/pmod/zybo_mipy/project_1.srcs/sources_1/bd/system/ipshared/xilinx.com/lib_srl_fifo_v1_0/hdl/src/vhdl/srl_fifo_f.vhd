-- srl_fifo_f - entity / architecture pair
-------------------------------------------------------------------------------
--
-- *************************************************************************
-- **                                                                     **
-- ** DISCLAIMER OF LIABILITY                                             **
-- **                                                                     **
-- ** This text/file contains proprietary, confidential                   **
-- ** information of Xilinx, Inc., is distributed under                   **
-- ** license from Xilinx, Inc., and may be used, copied                  **
-- ** and/or disclosed only pursuant to the terms of a valid              **
-- ** license agreement with Xilinx, Inc. Xilinx hereby                   **
-- ** grants you a license to use this text/file solely for               **
-- ** design, simulation, implementation and creation of                  **
-- ** design files limited to Xilinx devices or technologies.             **
-- ** Use with non-Xilinx devices or technologies is expressly            **
-- ** prohibited and immediately terminates your license unless           **
-- ** covered by a separate agreement.                                    **
-- **                                                                     **
-- ** Xilinx is providing this design, code, or information               **
-- ** "as-is" solely for use in developing programs and                   **
-- ** solutions for Xilinx devices, with no obligation on the             **
-- ** part of Xilinx to provide support. By providing this design,        **
-- ** code, or information as one possible implementation of              **
-- ** this feature, application or standard, Xilinx is making no          **
-- ** representation that this implementation is free from any            **
-- ** claims of infringement. You are responsible for obtaining           **
-- ** any rights you may require for your implementation.                 **
-- ** Xilinx expressly disclaims any warranty whatsoever with             **
-- ** respect to the adequacy of the implementation, including            **
-- ** but not limited to any warranties or representations that this      **
-- ** implementation is free from claims of infringement, implied         **
-- ** warranties of merchantability or fitness for a particular           **
-- ** purpose.                                                            **
-- **                                                                     **
-- ** Xilinx products are not intended for use in life support            **
-- ** appliances, devices, or systems. Use in such applications is        **
-- ** expressly prohibited.                                               **
-- **                                                                     **
-- ** Any modifications that are made to the Source Code are              **
-- ** done at the user’s sole risk and will be unsupported.               **
-- ** The Xilinx Support Hotline does not have access to source           **
-- ** code and therefore cannot answer specific questions related         **
-- ** to source HDL. The Xilinx Hotline support of original source        **
-- ** code IP shall only address issues and questions related             **
-- ** to the standard Netlist version of the core (and thus               **
-- ** indirectly, the original core source).                              **
-- **                                                                     **
-- ** Copyright (c) 2005-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        srl_fifo_f.vhd
--
-- Description:     A small-to-medium depth FIFO. For
--                  data storage, the SRL elements native to the
--                  target FGPA family are used. If the FIFO depth
--                  exceeds the available depth of the SRL elements,
--                  then SRLs are cascaded and MUXFN elements are
--                  used to select the output of the appropriate SRL stage.
--
--                  Features:
--                      - Width and depth are arbitrary, but each doubling of
--                        depth, starting from the native SRL depth, adds
--                        a level of MUXFN. Generally, in performance-oriented
--                        applications, the fifo depth may need to be limited to
--                        not exceed the SRL cascade depth supported by local
--                        fast interconnect or the number of MUXFN levels.
--                        However, deeper fifos will correctly build.
--                      - Commands: read, write.
--                      - Flags: empty and full.
--                      - The Addr output is always one less than the current
--                        occupancy when the FIFO is non-empty, and is all ones
--                        otherwise. Therefore, the value <FIFO_Empty, Addr>--
--                        i.e. FIFO_Empty concatenated on the left to Addr--
--                        when taken as a signed value, is one less than the
--                        current occupancy.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              srl_fifo_f.vhd
--                srl_fifo_rbu_f.vhd
--                proc_common_pkg.vhd
--
-------------------------------------------------------------------------------
-- Author:          Farrell Ostler
--
-- History:
--   FLO   12/13/05   First Version.
--
-- FLO            04/27/06
-- ^^^^^^
--   C_FAMILY made to default to "nofamily".
-- ~~~~~~
--  FLO         2007-12-12
-- ^^^^^^
--  Using function clog2 now instead of log2 to eliminate superfluous warnings.
-- ~~~~~~
--
--     DET     1/17/2008     v5_0
-- ~~~~~~
--     - Changed proc_common library version to v5_0
--     - Incorporated new disclaimer header
-- ^^^^^^
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
--      predecessor value by # clks:            "*_p#"


library ieee;
use     ieee.std_logic_1164.all;
library lib_srl_fifo_v1_0_2;
library lib_pkg_v1_0_2;
use     lib_pkg_v1_0_2.lib_pkg.clog2;
--
entity srl_fifo_f is
  generic (
    C_DWIDTH : natural;
    C_DEPTH  : positive := 16;
    C_FAMILY : string := "nofamily"
    );
  port (
    Clk           : in  std_logic;
    Reset         : in  std_logic;
    FIFO_Write    : in  std_logic;
    Data_In       : in  std_logic_vector(0 to C_DWIDTH-1);
    FIFO_Read     : in  std_logic;
    Data_Out      : out std_logic_vector(0 to C_DWIDTH-1);
    FIFO_Empty    : out std_logic;
    FIFO_Full     : out std_logic;
    Addr          : out std_logic_vector(0 to clog2(C_DEPTH)-1)
    );

end entity srl_fifo_f;


--
architecture imp of srl_fifo_f is

attribute DowngradeIPIdentifiedWarnings: string;

attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";

    constant ZEROES : std_logic_vector(0 to clog2(C_DEPTH)-1) := (others => '0');
begin

    I_SRL_FIFO_RBU_F : entity lib_srl_fifo_v1_0_2.srl_fifo_rbu_f
    generic map (
                 C_DWIDTH => C_DWIDTH,
                 C_DEPTH  => C_DEPTH,
                 C_FAMILY => C_FAMILY
    )
    port map (
                 Clk           => Clk,
                 Reset         => Reset,
                 FIFO_Write    => FIFO_Write,
                 Data_In       => Data_In,
                 FIFO_Read     => FIFO_Read,
                 Data_Out      => Data_Out,
                 FIFO_Full     => FIFO_Full,
                 FIFO_Empty    => FIFO_Empty,
                 Addr          => Addr,
                 Num_To_Reread => ZEROES,
                 Underflow     => open,
                 Overflow      => open
    );

end architecture imp;
