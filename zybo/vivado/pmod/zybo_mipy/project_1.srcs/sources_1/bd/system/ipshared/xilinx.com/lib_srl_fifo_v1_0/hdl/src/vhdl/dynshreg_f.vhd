-- srl_fifo_rbu_f - entity / architecture pair
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
-- Filename:      dynshreg_f.vhd
--
-- Description:   This module implements a dynamic shift register with clock
--                enable. (Think, for example, of the function of the SRL16E.)
--                The width and depth of the shift register are selectable
--                via generics C_WIDTH and C_DEPTH, respectively. The C_FAMILY
--                allows the implementation to be tailored to the target
--                FPGA family. An inferred implementation is used if C_FAMILY
--                is "nofamily" (the default) or if synthesis will not produce
--                an optimal implementation.  Otherwise, a structural
--                implementation will be generated.
--
--                There is no restriction on the values of C_WIDTH and
--                C_DEPTH and, in particular, the C_DEPTH does not have
--                to be a power of two.
--
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--
-------------------------------------------------------------------------------
-- Author:          Farrell Ostler
--
-- History:
--   FLO   12/05/05   First Version. Derived from srl_fifo_rbu.
--
-- ~~~~~~
--  FLO         06/07/15
-- ^^^^^^
--  -XST was observed in some cases to produce a suboptimal implementation when
--   the depth, C_DEPTH, is a power of two and less than the native depth
--   of the SRL. Now a structural implementation is used for these cases.
--   (The particular case where a problem was found was for C_DEPTH=4 and
--    C_FAMILY="virtex5". In this case, rather than use an SRL, XST
--    made an implementation out of discrete FFs and LUTs.)
--  -Added Description.
-- ~~~~~~
--  FLO         07/12/12
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

---(
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.UNSIGNED;
use     ieee.numeric_std.TO_INTEGER;
library lib_pkg_v1_0_2;
use     lib_pkg_v1_0_2.lib_pkg.clog2;

entity dynshreg_f is
  generic (
    C_DEPTH  : positive := 32;
    C_DWIDTH : natural := 1;
    C_FAMILY : string := "nofamily"
  );
  port (
    Clk   : in  std_logic;
    Clken : in  std_logic;
    Addr  : in  std_logic_vector(0 to clog2(C_DEPTH)-1);
    Din   : in  std_logic_vector(0 to C_DWIDTH-1);
    Dout  : out std_logic_vector(0 to C_DWIDTH-1)
  );
end dynshreg_f;


library unisim;
use     unisim.all; -- Make unisim entities available for default binding.
architecture behavioral of dynshreg_f is

--  constant K_FAMILY : families_type := str2fam(C_FAMILY);
  --
--  constant W32 : boolean := supported(K_FAMILY, u_SRLC32E) and
--                            (C_DEPTH > 16 or not supported(K_FAMILY, u_SRL16E));
--  constant W16 : boolean := supported(K_FAMILY, u_SRLC16E) and not W32;
  constant W32 : boolean := (C_DEPTH > 16);
  constant W16 : boolean := (not W32);
  -- XST faster if these two constants are declared here
  -- instead of in STRUCTURAL_A_GEN. (I.25)
  --
  function power_of_2(n: positive) return boolean is
      variable i: positive := 1;
  begin
      while n > i loop i := i*2; end loop;
      return n = i;
  end power_of_2;
  --
--  constant USE_INFERRED     : boolean :=    (    power_of_2(C_DEPTH)
--                                             and (   (W16 and C_DEPTH >= 16)
--                                                  or (W32 and C_DEPTH >= 32)
--                                                 )
--                                            )
--                                         or (not W32 and not W16);

   constant USE_INFERRED : boolean := true;
  -- As of I.32, XST is not infering optimal dynamic shift registers for
  -- depths not a power of two (by not taking advantage of don't care
  -- at output when address not within the range of the depth)
  -- or a power of two less than the native SRL depth (by building shift
  -- register out of discrete FFs and LUTs instead of SRLs).
  constant USE_STRUCTURAL_A : boolean := not USE_INFERRED;

  function min(a, b: natural) return natural is
  begin
      if a<b then return a; else return b; end if;
  end min;

 ---------------------------------------------------------------------------- 
 -- Unisim components declared locally for maximum avoidance of default
 -- binding and vcomponents version issues.
 ---------------------------------------------------------------------------- 
  component SRLC16E
      generic
      (
          INIT : bit_vector := X"0000"
      );
      port
      (
          Q : out STD_ULOGIC;
          Q15 : out STD_ULOGIC;
          A0 : in STD_ULOGIC;
          A1 : in STD_ULOGIC;
          A2 : in STD_ULOGIC;
          A3 : in STD_ULOGIC;
          CE : in STD_ULOGIC;
          CLK : in STD_ULOGIC;
          D : in STD_ULOGIC
      );
  end component;

  component SRLC32E
      generic
      (
          INIT : bit_vector := X"00000000"
      );
      port
      (
          Q : out STD_ULOGIC;
          Q31 : out STD_ULOGIC;
          A : in STD_LOGIC_VECTOR (4 downto 0);
          CE : in STD_ULOGIC;
          CLK : in STD_ULOGIC;
          D : in STD_ULOGIC
      );
  end component;


begin

  ---(


  ---(
  INFERRED_GEN : if USE_INFERRED = true generate
    type dataType is array (0 to C_DEPTH-1) of std_logic_vector(0 to C_DWIDTH-1);
    signal data: dataType;
  begin
    process(Clk)
    begin
      if Clk'event and Clk = '1' then
        if Clken = '1' then
          data <= Din & data(0 to C_DEPTH-2);
        end if;
      end if;
    end process;

    Dout <= data(TO_INTEGER(UNSIGNED(Addr)))
                when (TO_INTEGER(UNSIGNED(Addr)) < C_DEPTH)
                else
            (others => '-');
  end generate INFERRED_GEN;
  ---)

end behavioral;
---)
