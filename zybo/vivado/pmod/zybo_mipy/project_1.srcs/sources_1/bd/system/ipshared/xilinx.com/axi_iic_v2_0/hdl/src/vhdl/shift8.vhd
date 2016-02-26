-------------------------------------------------------------------------------
-- shift8.vhd - Entity and Architecture
-------------------------------------------------------------------------------
--  ***************************************************************************
--  ** DISCLAIMER OF LIABILITY                                               **
--  **                                                                       **
--  **  This file contains proprietary and confidential information of       **
--  **  Xilinx, Inc. ("Xilinx"), that is distributed under a license         **
--  **  from Xilinx, and may be used, copied and/or disclosed only           **
--  **  pursuant to the terms of a valid license agreement with Xilinx.      **
--  **                                                                       **
--  **  XILINX is PROVIDING THIS DESIGN, CODE, OR INFORMATION                **
--  **  ("MATERIALS") "AS is" WITHOUT WARRANTY OF ANY KIND, EITHER           **
--  **  EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT                  **
--  **  LIMITATION, ANY WARRANTY WITH RESPECT to NONINFRINGEMENT,            **
--  **  MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx        **
--  **  does not warrant that functions included in the Materials will       **
--  **  meet the requirements of Licensee, or that the operation of the      **
--  **  Materials will be uninterrupted or error-free, or that defects       **
--  **  in the Materials will be corrected. Furthermore, Xilinx does         **
--  **  not warrant or make any representations regarding use, or the        **
--  **  results of the use, of the Materials in terms of correctness,        **
--  **  accuracy, reliability or otherwise.                                  **
--  **                                                                       **
--  **  Xilinx products are not designed or intended to be fail-safe,        **
--  **  or for use in any application requiring fail-safe performance,       **
--  **  such as life-support or safety devices or systems, Class III         **
--  **  medical devices, nuclear facilities, applications related to         **
--  **  the deployment of airbags, or any other applications that could      **
--  **  lead to death, personal injury or severe property or                 **
--  **  environmental damage (individually and collectively, "critical       **
--  **  applications"). Customer assumes the sole risk and liability         **
--  **  of any use of Xilinx products in critical applications,              **
--  **  subject only to applicable laws and regulations governing            **
--  **  limitations on product liability.                                    **
--  **                                                                       **
--  **  Copyright 2011 Xilinx, Inc.                                          **
--  **  All rights reserved.                                                 **
--  **                                                                       **
--  **  This disclaimer and copyright notice must be retained as part        **
--  **  of this file at all times.                                           **
--  ***************************************************************************
-------------------------------------------------------------------------------
-- Filename:        shift8.vhd
-- Version:         v1.01.b                        
-- Description:     
--                  This file contains an 8 bit shift register 
--
--  VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--
--           axi_iic.vhd
--              -- iic.vhd
--                  -- axi_ipif_ssp1.vhd
--                      -- axi_lite_ipif.vhd
--                      -- interrupt_control.vhd
--                      -- soft_reset.vhd
--                  -- reg_interface.vhd
--                  -- filter.vhd
--                      -- debounce.vhd
--                  -- iic_control.vhd
--                      -- upcnt_n.vhd
--                      -- shift8.vhd
--                  -- dynamic_master.vhd
--                  -- iic_pkg.vhd
--
-------------------------------------------------------------------------------
-- Author:          USM
--
--  USM     10/15/09
-- ^^^^^^
--  - Initial release of v1.00.a
-- ~~~~~~
--
--  USM     09/06/10
-- ^^^^^^
--  - Release of v1.01.a
-- ~~~~~~
--
--  NLR     01/07/11
-- ^^^^^^
--  - Release of v1.01.b
-- ~~~~~~
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-- Definition of Ports:
--      Clk           -- System clock
--      Clr           -- System reset
--      Data_ld       -- Shift register data load enable
--      Data_in       -- Shift register data in
--      Shift_in      -- Shift register serial data in
--      Shift_en      -- Shift register shift enable
--      Shift_out     -- Shift register serial data out
--      Data_out      -- Shift register shift data out
-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------

entity shift8 is
    port(
         Clk         : in std_logic;    -- Clock
         Clr         : in std_logic;    -- Clear
         Data_ld     : in std_logic;    -- Data load enable
         Data_in     : in std_logic_vector (7 downto 0);-- Data to load in
         Shift_in    : in std_logic;    -- Serial data in
         Shift_en    : in std_logic;    -- Shift enable
         Shift_out   : out std_logic;   -- Shift serial data out
         Data_out    : out std_logic_vector (7 downto 0)  -- Shifted data
         );
        
end shift8;  

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture RTL of shift8 is
  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";


    constant enable_n : std_logic := '0';

    signal data_int : std_logic_vector (7 downto 0);

begin

   ----------------------------------------------------------------------------
   -- PROCESS: SHIFT_REG_GEN
   -- purpose: generate shift register
   ----------------------------------------------------------------------------
   
   SHIFT_REG_GEN : process(Clk)
   begin
      if Clk'event and Clk = '1' then
         if (Clr = enable_n) then -- Clear output register
            data_int <= (others => '0');
         elsif (Data_ld = '1') then  -- Load data
            data_int <= Data_in;
         elsif Shift_en = '1' then -- If shift enable is high
            data_int <= data_int(6 downto 0) & Shift_in; -- Shift the data
         end if;
      end if;
   end process SHIFT_REG_GEN;
   
    Shift_out <= data_int(7);     
    Data_out  <= data_int;

end architecture RTL; 
