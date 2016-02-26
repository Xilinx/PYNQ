-------------------------------------------------------------------------------
-- iic_pkg.vhd - Package
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
--  **  Copyright 2009 Xilinx, Inc.                                          **
--  **  All rights reserved.                                                 **
--  **                                                                       **
--  **  This disclaimer and copyright notice must be retained as part        **
--  **  of this file at all times.                                           **
--  ***************************************************************************
-------------------------------------------------------------------------------
-- Filename:        iic_pkg.vhd
-- Version:         v1.01.b                        
-- Description:     This file contains the constants used in the design of the
--                  iic bus interface.
--
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
-- ~~~~~~
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package iic_pkg is

   ----------------------------------------------------------------------------
   -- Constant Declarations
   ----------------------------------------------------------------------------
   constant RESET_ACTIVE : std_logic              := '1'; -- Reset Constant
   
   constant NUM_IIC_REGS : integer := 11;       -- should be same as C_NUM_IIC_REGS in axi_iic top

   constant DATA_BITS    : natural                := 8; -- FIFO Width Generic
   constant TX_FIFO_BITS : integer range 0 to 256 := 4; -- Number of addr bits
   constant RC_FIFO_BITS : integer range 0 to 256 := 4; -- Number of addr bits
   
   
   --IPIF Generics that must remain at these values for the IIC
   constant  INCLUDE_DEV_PENCODER      : BOOLEAN := False;  
   constant  IPIF_ABUS_WIDTH           : INTEGER := 32; 
   constant  INCLUDE_DEV_ISC           : Boolean := false;
   
   type STD_LOGIC_VECTOR_ARRAY is array (0 to NUM_IIC_REGS-1) of std_logic_vector(24 to 31);
   type INTEGER_ARRAY is array (24 to 31) of integer; 
   ----------------------------------------------------------------------------
   -- Function and Procedure Declarations
   ----------------------------------------------------------------------------
   function num_ctr_bits(C_S_AXI_ACLK_FREQ_HZ : integer;
                         C_IIC_FREQ : integer)  return integer;
   function ten_bit_addr_used(C_TEN_BIT_ADR : integer) return std_logic_vector;
   function gpo_bit_used(C_GPO_WIDTH : integer) return std_logic_vector;
   function count_reg_bits_used(REG_BITS_USED : STD_LOGIC_VECTOR_ARRAY) return
                                                                INTEGER_ARRAY;

end package iic_pkg;

-------------------------------------------------------------------------------
-- Package body
-------------------------------------------------------------------------------

package body iic_pkg is

   ----------------------------------------------------------------------------
   -- Function Definitions
   ----------------------------------------------------------------------------
   -- Function num_ctr_bits
   --
   -- This function returns the number of bits required to count 1/2 the period
   -- of the SCL clock.
   --
   ----------------------------------------------------------------------------
   function num_ctr_bits(C_S_AXI_ACLK_FREQ_HZ : integer;
                        C_IIC_FREQ : integer) return integer is
   
      variable num_bits    : integer :=0;
      variable i           : integer :=0;
   begin   
      --  for loop used because XST service pack 2 does not support While loops
      if C_S_AXI_ACLK_FREQ_HZ/C_IIC_FREQ > C_S_AXI_ACLK_FREQ_HZ/212766 then
         for i in 0 to 30 loop  -- 30 is a magic number needed for for loops
            if 2**i < C_S_AXI_ACLK_FREQ_HZ/C_IIC_FREQ then
                  num_bits := num_bits + 1;   
            end if;
         end loop;
         return (num_bits);
      else
         for i in 0 to 30 loop
            if 2**i < C_S_AXI_ACLK_FREQ_HZ/212766 then
                  num_bits := num_bits + 1; 
            end if;
         end loop;
         return (num_bits);
      end if;
   end function num_ctr_bits;         
     
   ----------------------------------------------------------------------------
   -- Function ten_bit_addr_used
   --
   -- This function returns either b"00000000" for no ten bit addressing or
   --                              b"00000111" for ten bit addressing
   --
   ----------------------------------------------------------------------------
   
   function ten_bit_addr_used(C_TEN_BIT_ADR : integer) return std_logic_vector is
   begin   
      if C_TEN_BIT_ADR = 0 then
         return (b"00000000");
      else
         return (b"00000111");
      end if;
   end function ten_bit_addr_used;         
   
   ----------------------------------------------------------------------------
   -- Function gpo_bit_used
   --
   -- This function returns b"00000000" up to b"11111111" depending on
   -- C_GPO_WIDTH
   --
   ----------------------------------------------------------------------------
   
   function gpo_bit_used(C_GPO_WIDTH : integer) return std_logic_vector is
   begin   
      if C_GPO_WIDTH = 1 then
         return (b"00000001");
      elsif C_GPO_WIDTH = 2 then
         return (b"00000011");
      elsif C_GPO_WIDTH = 3 then
         return (b"00000111");
      elsif C_GPO_WIDTH = 4 then
         return (b"00001111");
      elsif C_GPO_WIDTH = 5 then
         return (b"00011111");
      elsif C_GPO_WIDTH = 6 then
         return (b"00111111");
      elsif C_GPO_WIDTH = 7 then
         return (b"01111111");
      elsif C_GPO_WIDTH = 8 then
         return (b"11111111");
      end if;
   end function gpo_bit_used;  
   
   ----------------------------------------------------------------------------
   -- Function count_reg_bits_used
   --
   -- This function returns either b"00000000" for no ten bit addressing or
   --                              b"00000111" for ten bit addressing
   --
   ----------------------------------------------------------------------------
   
   function count_reg_bits_used(REG_BITS_USED : STD_LOGIC_VECTOR_ARRAY) 
                                         return INTEGER_ARRAY is 
      variable count : INTEGER_ARRAY;
   begin
      for i in 24 to 31 loop
         count(i) := 0;
         for m in 0 to NUM_IIC_REGS-1 loop --IP_REG_NUM - 1
            if (REG_BITS_USED(m)(i) = '1') then
               count(i) := count(i) + 1;
            end if;
         end loop;
      end loop;
      return count;
   end function count_reg_bits_used;
   
end package body iic_pkg;
