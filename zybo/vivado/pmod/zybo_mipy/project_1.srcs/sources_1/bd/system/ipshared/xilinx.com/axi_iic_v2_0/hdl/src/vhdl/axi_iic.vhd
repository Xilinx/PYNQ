-------------------------------------------------------------------------------
-- axi_iic.vhd - entity/architecture pair
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
-- Filename:        axi_iic.vhd
-- Version:         v1.01.b
-- Description:
--                  This file is the top level file that contains the IIC AXI
--                  Interface.
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
--  - Added function calc_tbuf in iic_control to calculate the TBUF delay
-- ~~~~~~
--
--  NLR     01/07/11
-- ^^^^^^
--  - Fixed the CR#613282 and CR#613486
--  - Release of v1.01.b 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library axi_iic_v2_0_9;
use axi_iic_v2_0_9.iic_pkg.all;

-------------------------------------------------------------------------------
-- Definition of Generics:
--   C_IIC_FREQ             -- Maximum frequency of Master Mode in Hz
--   C_TEN_BIT_ADR          -- 10 bit slave addressing
--   C_GPO_WIDTH            -- Width of General purpose output vector
--   C_S_AXI_ACLK_FREQ_HZ   -- Specifies AXI clock frequency
--   C_SCL_INERTIAL_DELAY   -- SCL filtering
--   C_SDA_INERTIAL_DELAY   -- SDA filtering
--   C_SDA_LEVEL            -- SDA level
--   C_SMBUS_PMBUS_HOST     -- Acts as SMBus/PMBus host when enabled
--   C_S_AXI_DATA_WIDTH     -- Width of the AXI Data Bus (in bits)
--   C_FAMILY               -- XILINX FPGA family
-------------------------------------------------------------------------------
-- Definition of ports:
--
--   System Signals
--      s_axi_aclk            -- AXI Clock
--      s_axi_aresetn         -- AXI Reset
--      IP2INTC_Irpt          -- System interrupt output
--
--AXI signals
--      s_axi_awaddr          -- AXI Write address
--      s_axi_awvalid         -- Write address valid
--      s_axi_awready         -- Write address ready
--      s_axi_wdata           -- Write data
--      s_axi_wstrb           -- Write strobes
--      s_axi_wvalid          -- Write valid
--      s_axi_wready          -- Write ready
--      s_axi_bresp           -- Write response
--      s_axi_bvalid          -- Write response valid
--      s_axi_bready          -- Response ready
--      s_axi_araddr          -- Read address
--      s_axi_arvalid         -- Read address valid
--      s_axi_arready         -- Read address ready
--      s_axi_rdata           -- Read data
--      s_axi_rresp           -- Read response
--      s_axi_rvalid          -- Read valid
--      s_axi_rready          -- Read ready
--   IIC Signals
--      sda_i                 -- IIC serial data input
--      sda_o                 -- IIC serial data output
--      sda_t                 -- IIC seral data output enable
--      scl_i                 -- IIC serial clock input
--      scl_o                 -- IIC serial clock output
--      scl_t                 -- IIC serial clock output enable
--      gpo                   -- General purpose outputs
--
-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------

entity axi_iic is

   generic (

      -- FPGA Family Type specification
      C_FAMILY              : string := "virtex7";
      -- Select the target architecture type

    -- AXI Parameters
      --C_S_AXI_ADDR_WIDTH    : integer range 32 to 36        := 32; --9
      C_S_AXI_ADDR_WIDTH    : integer                       := 9; --9
      C_S_AXI_DATA_WIDTH    : integer range 32 to 32        := 32;

      -- AXI IIC Feature generics
      C_IIC_FREQ            : integer    := 100E3;
      C_TEN_BIT_ADR         : integer    := 0;
      C_GPO_WIDTH           : integer    := 1;
      C_S_AXI_ACLK_FREQ_HZ  : integer    := 25E6;
      C_SCL_INERTIAL_DELAY  : integer    := 0;  -- delay in nanoseconds
      C_SDA_INERTIAL_DELAY  : integer    := 0;  -- delay in nanoseconds
      C_SDA_LEVEL           : integer    := 1;  -- delay in nanoseconds
      C_SMBUS_PMBUS_HOST    : integer    := 0;   -- SMBUS/PMBUS support
      C_DEFAULT_VALUE       : std_logic_vector(7 downto 0) := X"FF"
      );

   port (

-- System signals
      s_axi_aclk            : in  std_logic;
      s_axi_aresetn         : in  std_logic := '1';
      iic2intc_irpt         : out std_logic;

-- AXI signals
      s_axi_awaddr          : in  std_logic_vector (8 downto 0);
                              --(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_awvalid         : in  std_logic;
      s_axi_awready         : out std_logic;
      s_axi_wdata           : in  std_logic_vector (31 downto 0);
                              --(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_wstrb           : in  std_logic_vector (3 downto 0);
                              --((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      s_axi_wvalid          : in  std_logic;
      s_axi_wready          : out std_logic;
      s_axi_bresp           : out std_logic_vector(1 downto 0);
      s_axi_bvalid          : out std_logic;
      s_axi_bready          : in  std_logic;
      s_axi_araddr          : in  std_logic_vector(8 downto 0);
                              --(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_arvalid         : in  std_logic;
      s_axi_arready         : out std_logic;
      s_axi_rdata           : out std_logic_vector (31 downto 0);
                              --(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_rresp           : out std_logic_vector(1 downto 0);
      s_axi_rvalid          : out std_logic;
      s_axi_rready          : in  std_logic;

      -- IIC interface signals
      sda_i            : in  std_logic;
      sda_o            : out std_logic;
      sda_t            : out std_logic;
      scl_i            : in  std_logic;
      scl_o            : out std_logic;
      scl_t            : out std_logic;
      gpo              : out std_logic_vector(C_GPO_WIDTH-1 downto 0)
      );

end entity axi_iic;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture RTL of axi_iic is
  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";


 
   constant C_NUM_IIC_REGS       : integer := 18;

begin

   X_IIC: entity axi_iic_v2_0_9.iic
      generic map (

         -- System Generics
         C_NUM_IIC_REGS        => C_NUM_IIC_REGS,   -- Number of IIC Registers

         --iic Generics to be set by user
         C_S_AXI_ACLK_FREQ_HZ  => C_S_AXI_ACLK_FREQ_HZ,
         C_IIC_FREQ            => C_IIC_FREQ,  --  default iic Serial 100KHz
         C_TEN_BIT_ADR         => C_TEN_BIT_ADR,  -- [integer]
         C_GPO_WIDTH           => C_GPO_WIDTH,    -- [integer]
         C_SCL_INERTIAL_DELAY  => C_SCL_INERTIAL_DELAY, -- delay in nanoseconds
         C_SDA_INERTIAL_DELAY  => C_SDA_INERTIAL_DELAY, -- delay in nanoseconds
         C_SDA_LEVEL           => C_SDA_LEVEL,
         C_SMBUS_PMBUS_HOST    => C_SMBUS_PMBUS_HOST,

         -- Transmit FIFO Generic
         -- Removed as user input 10/08/01
         -- Software will not be tested without FIFO's
         C_TX_FIFO_EXIST      => TRUE,  -- [boolean]

         -- Recieve FIFO Generic
         -- Removed as user input 10/08/01
         -- Software will not be tested without FIFO's
         C_RC_FIFO_EXIST     => TRUE,  -- [boolean]

         -- AXI interface generics

         C_S_AXI_ADDR_WIDTH  => C_S_AXI_ADDR_WIDTH, -- [integer 9]
         --  width of the AXI Address Bus (in bits)

         C_S_AXI_DATA_WIDTH  => C_S_AXI_DATA_WIDTH, -- [integer range 32 to 32]
         --  Width of the AXI Data Bus (in bits)

         C_FAMILY            => C_FAMILY,  -- [string]
         C_DEFAULT_VALUE     => C_DEFAULT_VALUE

         )
      port map
        (
         -- System signals
        S_AXI_ACLK          =>  s_axi_aclk,
        S_AXI_ARESETN       =>  s_axi_aresetn,
        IIC2INTC_IRPT       =>  iic2intc_iRPT,

         -- AXI Interface signals
        S_AXI_AWADDR        =>  s_axi_awaddr,
        S_AXI_AWVALID       =>  s_axi_awvalid,
        S_AXI_AWREADY       =>  s_axi_awready,
        S_AXI_WDATA         =>  s_axi_wdata,
        S_AXI_WSTRB         =>  s_axi_wstrb,
        S_AXI_WVALID        =>  s_axi_wvalid,
        S_AXI_WREADY        =>  s_axi_wready,
        S_AXI_BRESP         =>  s_axi_bresp,
        S_AXI_BVALID        =>  s_axi_bvalid,
        S_AXI_BREADY        =>  s_axi_bready,
        S_AXI_ARADDR        =>  s_axi_araddr,
        S_AXI_ARVALID       =>  s_axi_arvalid,
        S_AXI_ARREADY       =>  s_axi_arready,
        S_AXI_RDATA         =>  s_axi_rdata,
        S_AXI_RRESP         =>  s_axi_rresp,
        S_AXI_RVALID        =>  s_axi_rvalid,
        S_AXI_RREADY        =>  s_axi_rready,

         -- IIC Bus Signals
        SDA_I               => sda_i,
        SDA_O               => sda_o,
        SDA_T               => sda_t,
        SCL_I               => scl_i,
        SCL_O               => scl_o,
        SCL_T               => scl_t,
        GPO                 => gpo
        );
end architecture RTL;
