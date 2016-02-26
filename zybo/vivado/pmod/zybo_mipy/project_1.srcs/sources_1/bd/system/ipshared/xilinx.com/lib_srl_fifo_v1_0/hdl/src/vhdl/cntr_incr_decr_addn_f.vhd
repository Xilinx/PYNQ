-- cntr_incr_decr_addn_f - entity / architecture pair
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
-- ** Copyright (c) 2005 - 2010 Xilinx, Inc. All rights reserved.         **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        cntr_incr_decr_addn_f.vhd
--
-- Description:     This counter can increment, decrement or skip ahead
--                  by an arbitrary amount.
--
--                  If Reset is active, the value Cnt synchronously resets
--                  to all ones. (This reset value, different than the
--                  customary reset value of zero, caters to the original
--                  application of cntr_incr_decr_addn_f as the address
--                  counter for srl_fifo_rbu_f.)
--
--                  Otherwise, on each Clk, one is added to Cnt if Incr is
--                  asserted and one is subtracted if Decr is asserted. (If
--                  both are asserted, then there is no change to Cnt.)
--
--                  If Decr is not asserted, then the input value,
--                  Nm_to_add, is added. (Simultaneous assertion of Incr
--                  would add one more.) If Decr is asserted, then
--                  N_to_add, is ignored, i.e., it is possible to decrement
--                  by one or add N, but not both, and Decr overrides. 
--
--                  The value that Cnt will take on at the next clock
--                  is available as Cnt_p1.
--
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              cntr_incr_decr_addn_f.vhd
--
-------------------------------------------------------------------------------
--
-- History:
--   FLO   12/30/05   First Version.
--
-- ~~~~~~
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
--      predecessor value by # clks:            "*_p#"
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
--
entity cntr_incr_decr_addn_f is
  generic (
    C_SIZE   : natural;
    C_FAMILY : string  := "nofamily"
  );
  port (
    Clk           : in  std_logic;
    Reset         : in  std_logic; -- Note: the counter resets to all ones!
    Incr          : in  std_logic;
    Decr          : in  std_logic;
    N_to_add      : in  std_logic_vector(C_SIZE-1 downto 0);
    Cnt           : out std_logic_vector(C_SIZE-1 downto 0);
    Cnt_p1        : out std_logic_vector(C_SIZE-1 downto 0)
  );
end entity cntr_incr_decr_addn_f;


---(
library lib_srl_fifo_v1_0_2;
library ieee;
use     ieee.numeric_std.UNSIGNED;
use     ieee.numeric_std."+";
library unisim;
use     unisim.all; -- Make unisim entities available for default binding.
--
architecture imp of cntr_incr_decr_addn_f is


--  constant COUNTER_PRIMS_AVAIL : boolean :=
--               supported(C_FAMILY, (u_MUXCY_L, u_XORCY, u_FDS));
  constant COUNTER_PRIMS_AVAIL : boolean := false;
            

  signal cnt_i             : std_logic_vector(Cnt'range);  
  signal cnt_i_p1          : std_logic_vector(Cnt'range);

   ---------------------------------------------------------------------------- 
   -- Unisim components declared locally for maximum avoidance of default
   -- binding and vcomponents version issues.
   ---------------------------------------------------------------------------- 
  component MUXCY_L
      port
      (
          LO : out std_ulogic;
          CI : in std_ulogic;
          DI : in std_ulogic;
          S : in std_ulogic
      );
  end component;

  component XORCY
      port
      (
          O : out std_ulogic;
          CI : in std_ulogic;
          LI : in std_ulogic
      );
  end component;

  component FDS
      generic
      (
          INIT : bit := '1'
      );
      port
      (
          Q : out std_ulogic;
          C : in std_ulogic;
          D : in std_ulogic;
          S : in std_ulogic
      );
  end component;

begin  -- architecture imp


  ---(
  INFERRED_GEN : if COUNTER_PRIMS_AVAIL = false generate
    --
    CNT_I_P1_PROC : process( cnt_i, N_to_add, Decr, Incr
                         ) is
        --
        function qual_n_to_add(N_to_add : std_logic_vector;
                           Decr : std_logic
                          ) return UNSIGNED is
            variable r: UNSIGNED(N_to_add'range);
        begin
            for i in r'range loop
                r(i) := N_to_add(i) or Decr;
            end loop;
            return r;
        end;
        --
        function to_singleton_unsigned(s : std_logic) return unsigned is
            variable r : unsigned(0 to 0) := (others => s);
        begin
            return r;
        end;
        --
    begin
        cnt_i_p1 <= std_logic_vector(   UNSIGNED(cnt_i)
                                      + qual_n_to_add(N_to_add, Decr)
                                      + to_singleton_unsigned(Incr)
                                    );
    end process;
    --
    CNT_I_PROC : process(Clk) is
    begin
        if Clk'event and Clk = '1' then
            if Reset = '1' then
                cnt_i <= (others => '1');
            else
                cnt_i <= cnt_i_p1;
            end if;
        end if;
    end process;
    --
  end generate INFERRED_GEN;
  ---)

  Cnt    <= cnt_i; 
  Cnt_p1 <= cnt_i_p1; 

end architecture imp;
---)
