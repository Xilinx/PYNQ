
-------------------------------------------------------------------------------
-- counter_f - entity/architecture pair
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
-- ** Copyright (c) 2006-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        counter_f.vhd
--
-- Description:     Implements a parameterizable N-bit counter_f
--                      Up/Down Counter
--                      Count Enable
--                      Parallel Load
--                      Synchronous Reset
--                      The structural implementation has incremental cost
--                      of one LUT per bit.
--                      Precedence of operations when simultaneous:
--                        reset, load, count
--
--                  A default inferred-RTL implementation is provided and
--                  is used if the user explicitly specifies C_FAMILY=nofamily
--                  or ommits C_FAMILY (allowing it to default to nofamily).
--                  The default implementation is also used
--                  if needed primitives are not available in FPGAs of the
--                  type given by C_FAMILY.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
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
use IEEE.numeric_std.unsigned;
use IEEE.numeric_std."+";
use IEEE.numeric_std."-";

library unisim;
use unisim.all;

-----------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------

entity counter_f is
    generic(
            C_NUM_BITS : integer := 9;
            C_FAMILY   : string := "nofamily"
           );

    port(
         Clk           : in  std_logic;
         Rst           : in  std_logic;
         Load_In       : in  std_logic_vector(C_NUM_BITS - 1 downto 0);
         Count_Enable  : in  std_logic;
         Count_Load    : in  std_logic;
         Count_Down    : in  std_logic;
         Count_Out     : out std_logic_vector(C_NUM_BITS - 1 downto 0);
         Carry_Out     : out std_logic
        );
end entity counter_f;

-----------------------------------------------------------------------------
-- Architecture section
-----------------------------------------------------------------------------

architecture imp of counter_f is

    ---------------------------------------------------------------------
    -- Component declarations
    ---------------------------------------------------------------------  
    component MUXCY_L is
      port (
        DI : in  std_logic;
        CI : in  std_logic;
        S  : in  std_logic;
        LO : out std_logic);
    end component MUXCY_L;

    component XORCY is
      port (
        LI : in  std_logic;
        CI : in  std_logic;
        O  : out std_logic);
    end component XORCY;

    component FDRE is
      port (
        Q  : out std_logic;
        C  : in  std_logic;
        CE : in  std_logic;
        D  : in  std_logic;
        R  : in  std_logic
      );
    end component FDRE;
        signal icount_out    : unsigned(C_NUM_BITS downto 0);
        signal icount_out_x  : unsigned(C_NUM_BITS downto 0);
        signal load_in_x     : unsigned(C_NUM_BITS downto 0);

    ---------------------------------------------------------------------
    -- Constant declarations
    ---------------------------------------------------------------------
---------------------------------------------------------------------
-- Begin architecture
---------------------------------------------------------------------
begin
    ---------------------------------------------------------------------
    -- Generate Inferred code
    ---------------------------------------------------------------------
    --INFERRED_GEN : if USE_INFERRED generate



        load_in_x    <= unsigned('0' & Load_In);

        -- Mask out carry position to retain legacy self-clear on next enable.
 --        icount_out_x <= ('0' & icount_out(C_NUM_BITS-1 downto 0)); -- Echeck WA
         icount_out_x <= unsigned('0' & std_logic_vector(icount_out(C_NUM_BITS-1 downto 0)));

        -----------------------------------------------------------------
        -- Process to generate counter with - synchronous reset, load,
        -- counter enable, count down / up features.
        -----------------------------------------------------------------
        CNTR_PROC : process(Clk)
        begin
            if Clk'event and Clk = '1' then
                if Rst = '1' then
                    icount_out <= (others => '0');
                elsif Count_Load = '1' then
                    icount_out <= load_in_x;
                elsif Count_Down = '1'  and Count_Enable = '1' then
                    icount_out <= icount_out_x - 1;
                elsif Count_Enable = '1' then
                    icount_out <= icount_out_x + 1;
                end if;
            end if;
        end process CNTR_PROC;

        Carry_Out <= icount_out(C_NUM_BITS);
        Count_Out <= std_logic_vector(icount_out(C_NUM_BITS-1 downto 0));



end architecture imp;
---------------------------------------------------------------
-- End of file counter_f.vhd
---------------------------------------------------------------
