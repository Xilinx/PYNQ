-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- upcnt_n - entity/architecture pair
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
-- ** Copyright 2010 Xilinx, Inc.                                        **
-- ** All rights reserved.                                               **
-- **                                                                    **
-- ** This disclaimer and copyright notice must be retained as part      **
-- ** of this file at all times.                                         **
-- ************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        upcnt_n.vhd
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
--  Kurt Conover      11/07/01      -- First Release
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
-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-- Definition of Generics:
--          C_SIZE    -- Number of bits in counter
--                          
--
-- Definition of Ports:
--          Data       -- parallel data input
--          Cnt_en     -- count enable
--          Load       -- Load Data
--          Clr        -- reset
--          Clk        -- Clock
--          Qout       -- Count output
--
-------------------------------------------------------------------------------
entity upcnt_n is
   generic(
           C_SIZE : Integer
          );
      
	port(
	     Data    : in  STD_LOGIC_VECTOR (C_SIZE-1 downto 0); 
	     Cnt_en  : in  STD_LOGIC;                            
	     Load    : in  STD_LOGIC;                            
 	     Clr     : in  STD_LOGIC;                            
	     Clk     : in  STD_LOGIC;                            
	     Qout    : out STD_LOGIC_VECTOR (C_SIZE-1 downto 0)
	    );
		
end upcnt_n;

architecture imp of upcnt_n is

constant CLEAR : std_logic := '0';

signal q_int : UNSIGNED (C_SIZE-1 downto 0) := (others => '1');

begin
   process(Clk)
   begin
	       
      if (Clk'event) and Clk = '1' then
          -- Clear output register
         if (Clr = CLEAR) then
            q_int <= (others => '0');
	       -- Load in start value
         elsif (Load = '1') then
            q_int <= UNSIGNED(Data);
	       -- If count enable is high
         elsif Cnt_en = '1' then
		      q_int <= q_int + 1;
         end if;
      end if;
   end process;

   Qout <= STD_LOGIC_VECTOR(q_int);

end imp;
  

