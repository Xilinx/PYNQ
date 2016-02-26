-------------------------------------------------------------------------------
 -- filter.vhd - entity/architecture pair
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
-- Filename:        filter.vhd
-- Version:         v1.01.b                        
-- Description:     
--                 This file implements a simple debounce (inertial delay)
--                 filter to remove short glitches from the SCL and SDA signals
--                 using user definable delay parameters. SCL cross couples to
--                 SDA to prevent SDA from changing near changes in SDA.
-- Notes:
-- 1) The default value for both debounce instances is '1' to conform to the
-- IIC bus default value of '1' ('H').
--
-- VHDL-Standard:   VHDL'93
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
-- ~~~~~
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi_iic_v2_0_9;
use axi_iic_v2_0_9.debounce;

-------------------------------------------------------------------------------
-- Definition of Generics:
--      SCL_INERTIAL_DELAY   -- SCL filtering delay 
--      SDA_INERTIAL_DELAY   -- SDA filtering delay 
-- Definition of Ports:
--      Sysclk               -- System clock
--      Scl_noisy            -- IIC SCL is noisy
--      Scl_clean            -- IIC SCL is clean
--      Sda_noisy            -- IIC SDA is Noisy
--      Sda_clean            -- IIC SDA is clean
-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
entity filter is
   
   generic (
      SCL_INERTIAL_DELAY : integer range 0 to 255 := 5;
      SDA_INERTIAL_DELAY : integer range 0 to 255 := 5
      );

   port (
      Sysclk    : in  std_logic;
      Rst       : in  std_logic;
      Scl_noisy : in  std_logic;
      Scl_clean : out std_logic;
      Sda_noisy : in  std_logic;
      Sda_clean : out std_logic
      );

end entity filter;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture RTL of filter is
  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";


   signal scl_unstable_n : std_logic;

begin

   ----------------------------------------------------------------------------
   -- The inertial delay is cross coupled between the two IIC signals to ensure
   -- that a delay in SCL because of a glitch also prevents any changes in SDA
   -- until SCL is clean. This prevents inertial delay on SCL from creating a
   -- situation whereby SCL is held high but SDA transitions low to high thus
   -- making the core think a STOP has occured. Changes on SDA do not inihibit
   -- SCL because that could alter the timing relationships for the clock
   -- edges. If other I2C devices follow the spec then SDA should be stable
   -- prior to the rising edge of SCL anyway. (Excluding noise of course)
   ----------------------------------------------------------------------------

   ----------------------------------------------------------------------------
   -- Assertion that reports the SCL inertial delay
   ----------------------------------------------------------------------------

   ASSERT (FALSE) REPORT "axi_iic configured for SCL inertial delay of "
      & integer'image(SCL_INERTIAL_DELAY) & " clocks."
      SEVERITY NOTE;
   
   ----------------------------------------------------------------------------
   -- Instantiating component debounce 
   ----------------------------------------------------------------------------
   
   SCL_DEBOUNCE : entity axi_iic_v2_0_9.debounce
      generic map (
         C_INERTIAL_DELAY => SCL_INERTIAL_DELAY, 
         C_DEFAULT        => '1')
      port map (
         Sysclk     => Sysclk,
         Rst        => Rst,

         Stable     => '1',
         Unstable_n => scl_unstable_n,

         Noisy      => Scl_noisy,  
         Clean      => Scl_clean); 

   ----------------------------------------------------------------------------
   -- Assertion that reports the SDA inertial delay
   ----------------------------------------------------------------------------
   
   ASSERT (FALSE) REPORT "axi_iic configured for SDA inertial delay of "
      & integer'image(SDA_INERTIAL_DELAY) & " clocks."
      SEVERITY NOTE;
   
   ----------------------------------------------------------------------------
   -- Instantiating component debounce 
   ----------------------------------------------------------------------------
   
   SDA_DEBOUNCE : entity axi_iic_v2_0_9.debounce
      generic map (
         C_INERTIAL_DELAY => SDA_INERTIAL_DELAY,  
         C_DEFAULT        => '1')
      port map (
         Sysclk     => Sysclk,
         Rst        => Rst,
         Stable     => scl_unstable_n,  
         Unstable_n => open,

         Noisy      => Sda_noisy,   
         Clean      => Sda_clean);  

end architecture RTL;
