-------------------------------------------------------------------------------
-- axi_ipif_ssp1.vhd - entity/architecture pair
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
-- Filename:        axi_ipif_ssp1.vhd
-- Version:         v1.01.b
--
-- Description:     AXI IPIF Slave Services Package 1
--                      This block provides the following services:
--                      - wraps the axi_lite_ipif interface to IPIC block and
--                        sets up its address decoding.
--                      - Provides the Software Reset register
--                      - Provides interrupt servicing
--                      - IPIC multiplexing service between the external IIC
--                        register block IP2Bus data path and the internal
--                        Interrupt controller's IP2Bus data path.
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
--  NLR     01/07/11
-- ^^^^^^
--  - Updated the version to v1_01_b
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.or_reduce;

library axi_iic_v2_0_9;

library axi_lite_ipif_v3_0_3;
-- axi_lite_ipif refered from axi_lite_ipif_v2_0
use axi_lite_ipif_v3_0_3.axi_lite_ipif;
use axi_lite_ipif_v3_0_3.ipif_pkg.all;

library interrupt_control_v3_1_2;

-------------------------------------------------------------------------------
-- Definition of Generics:
--      C_NUM_IIC_REGS             -- Number of IIC registers
--      C_S_AXI_ADDR_WIDTH         -- Width of AXI Address Bus (in bits)
--      C_S_AXI_DATA_WIDTH         -- Width of the AXI Data Bus (in bits)
--      C_FAMILY                   -- Target FPGA architecture
-------------------------------------------------------------------------------
-- Definition of Ports:
--   System Signals
--      S_AXI_ACLK            -- AXI Clock
--      S_AXI_ARESETN         -- AXI Reset
--      IP2INTC_Irpt          -- System interrupt output
--
--  AXI signals
--      S_AXI_AWADDR          -- AXI Write address
--      S_AXI_AWVALID         -- Write address valid
--      S_AXI_AWREADY         -- Write address ready
--      S_AXI_WDATA           -- Write data
--      S_AXI_WSTRB           -- Write strobes
--      S_AXI_WVALID          -- Write valid
--      S_AXI_WREADY          -- Write ready
--      S_AXI_BRESP           -- Write response
--      S_AXI_BVALID          -- Write response valid
--      S_AXI_BREADY          -- Response ready
--      S_AXI_ARADDR          -- Read address
--      S_AXI_ARVALID         -- Read address valid
--      S_AXI_ARREADY         -- Read address ready
--      S_AXI_RDATA           -- Read data
--      S_AXI_RRESP           -- Read response
--      S_AXI_RVALID          -- Read valid
--      S_AXI_RREADY          -- Read ready
--
--  IP interconnect port signals
--      Bus2IP_Clk           -- Bus to IIC clock
--      Bus2IP_Reset         -- Bus to IIC reset
--      Bus2IIC_Addr         -- Bus to IIC address
--      Bus2IIC_Data         -- Bus to IIC data bus
--      Bus2IIC_RNW          -- Bus to IIC read not write
--      Bus2IIC_RdCE         -- Bus to IIC read chip enable
--      Bus2IIC_WrCE         -- Bus to IIC write chip enable
--      IIC2Bus_Data         -- IIC to Bus data bus
--      IIC2Bus_IntrEvent    -- IIC Interrupt events
-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------

entity axi_ipif_ssp1 is
   generic
      (
      C_NUM_IIC_REGS        : integer                       := 10;
         -- Number of IIC Registers
      C_S_AXI_ADDR_WIDTH    : integer                       := 9;
      C_S_AXI_DATA_WIDTH    : integer range 32 to 32        := 32;

      C_FAMILY              : string                        := "virtex7"
         -- Select the target architecture type
      );
   port
      (
      -- System signals
      S_AXI_ACLK            : in  std_logic;
      S_AXI_ARESETN         : in  std_logic;
      IIC2Bus_IntrEvent     : in  std_logic_vector (0 to 7);
                                              -- IIC Interrupt events
      IIC2INTC_Irpt         : out std_logic;  -- IP-2-interrupt controller

      -- AXI signals
      S_AXI_AWADDR          : in  std_logic_vector
                              (C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_AWVALID         : in  std_logic;
      S_AXI_AWREADY         : out std_logic;
      S_AXI_WDATA           : in  std_logic_vector
                              (C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_WSTRB           : in  std_logic_vector
                              ((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      S_AXI_WVALID          : in  std_logic;
      S_AXI_WREADY          : out std_logic;
      S_AXI_BRESP           : out std_logic_vector(1 downto 0);
      S_AXI_BVALID          : out std_logic;
      S_AXI_BREADY          : in  std_logic;
      S_AXI_ARADDR          : in  std_logic_vector
                              (C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_ARVALID         : in  std_logic;
      S_AXI_ARREADY         : out std_logic;
      S_AXI_RDATA           : out std_logic_vector
                              (C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP           : out std_logic_vector(1 downto 0);
      S_AXI_RVALID          : out std_logic;
      S_AXI_RREADY          : in  std_logic;

      -- IP Interconnect (IPIC) port signals used by the IIC registers.
      Bus2IIC_Clk           : out std_logic;
      Bus2IIC_Reset         : out std_logic;
      Bus2IIC_Addr          : out std_logic_vector(0 to C_S_AXI_ADDR_WIDTH - 1);
      Bus2IIC_Data          : out std_logic_vector(0 to C_S_AXI_DATA_WIDTH - 1);
      Bus2IIC_RNW           : out std_logic;
      Bus2IIC_RdCE          : out std_logic_vector(0 to C_NUM_IIC_REGS-1);
      Bus2IIC_WrCE          : out std_logic_vector(0 to C_NUM_IIC_REGS-1);
      IIC2Bus_Data          : in  std_logic_vector(0 to C_S_AXI_DATA_WIDTH - 1)
      );
end entity axi_ipif_ssp1;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

architecture RTL of axi_ipif_ssp1 is
  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";


-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
   constant ZEROES : std_logic_vector(0 to 31)  := X"00000000";

   constant INTR_BASEADDR    : std_logic_vector := X"00000000";

   constant INTR_HIGHADDR    : std_logic_vector
                             := X"0000003F";

   constant RST_BASEADDR     : std_logic_vector
                             := X"00000040";

   constant RST_HIGHADDR     : std_logic_vector
                             := X"00000043";

   constant IIC_REG_BASEADDR : std_logic_vector
                             := X"00000100";

   constant IIC_REG_HIGHADDR : std_logic_vector
                             := X"000001FF";

   constant C_ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE :=
      (
         ZEROES & INTR_BASEADDR,     -- Interrupt controller
         ZEROES & INTR_HIGHADDR,
         ZEROES & RST_BASEADDR,      -- Software reset register
         ZEROES & RST_HIGHADDR,
         ZEROES & IIC_REG_BASEADDR,  -- IIC registers
         ZEROES & IIC_REG_HIGHADDR
         );

   constant C_ARD_IDX_INTERRUPT : integer := 0;
   constant C_ARD_IDX_RESET     : integer := 1;
   constant C_ARD_IDX_IIC_REGS  : integer := 2;

-- The C_IP_INTR_MODE_ARRAY must have the same width as the IP2Bus_IntrEvent
-- entity port.
   constant C_IP_INTR_MODE_ARRAY   : integer_array_type
                                     := (3, 3, 3, 3, 3, 3, 3, 3);
   constant C_INCLUDE_DEV_PENCODER : boolean            := FALSE;
   constant C_INCLUDE_DEV_ISC      : boolean            := FALSE;

   constant C_NUM_INTERRUPT_REGS   : integer := 16;
   constant C_NUM_RESET_REGS       : integer := 1;

   constant C_ARD_NUM_CE_ARRAY : INTEGER_ARRAY_TYPE :=
      (
         C_ARD_IDX_INTERRUPT => C_NUM_INTERRUPT_REGS,
         C_ARD_IDX_RESET     => C_NUM_RESET_REGS,
         C_ARD_IDX_IIC_REGS  => C_NUM_IIC_REGS
      );

   constant C_S_AXI_MIN_SIZE       : std_logic_vector(31 downto 0)
                                   := X"000001FF";

   constant C_USE_WSTRB            : integer := 0;

   constant C_DPHASE_TIMEOUT       : integer := 8;

   SUBTYPE INTERRUPT_CE_RNG is integer
      range calc_start_ce_index(C_ARD_NUM_CE_ARRAY, 0)
      to calc_start_ce_index(C_ARD_NUM_CE_ARRAY, 0)+C_ARD_NUM_CE_ARRAY(0)-1;

   SUBTYPE RESET_CE_RNG is integer
      range calc_start_ce_index(C_ARD_NUM_CE_ARRAY, 1)
      to calc_start_ce_index(C_ARD_NUM_CE_ARRAY, 1)+C_ARD_NUM_CE_ARRAY(1)-1;

   SUBTYPE IIC_CE_RNG is integer
      range calc_start_ce_index(C_ARD_NUM_CE_ARRAY, 2)
      to calc_start_ce_index(C_ARD_NUM_CE_ARRAY, 2)+C_ARD_NUM_CE_ARRAY(2)-1;

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
-- IPIC Signals

   signal AXI_Bus2IP_Clk   : std_logic;
   signal AXI_Bus2IP_Resetn: std_logic;
   signal AXI_Bus2IP_Reset : std_logic;
   signal AXI_IP2Bus_Data  : std_logic_vector(0 to C_S_AXI_DATA_WIDTH - 1);
   signal AXI_IP2Bus_WrAck : std_logic;
   signal AXI_IP2Bus_RdAck : std_logic;
   signal AXI_IP2Bus_WrAck1 : std_logic;
   signal AXI_IP2Bus_RdAck1 : std_logic;
   signal AXI_IP2Bus_WrAck2 : std_logic;
   signal AXI_IP2Bus_RdAck2 : std_logic;
   signal Intr2Bus_WrAck   : std_logic;
   signal Intr2Bus_RdAck   : std_logic;
   signal AXI_IP2Bus_Error : std_logic;
   signal AXI_Bus2IP_Addr  : std_logic_vector(0 to C_S_AXI_ADDR_WIDTH - 1);
   signal AXI_Bus2IP_Data  : std_logic_vector(0 to C_S_AXI_DATA_WIDTH - 1);
   signal AXI_Bus2IP_RNW   : std_logic;
   signal AXI_Bus2IP_CS    : std_logic_vector(0 to
                               ((C_ARD_ADDR_RANGE_ARRAY'length)/2)-1);
   signal AXI_Bus2IP_RdCE  : std_logic_vector(0 to
                                calc_num_ce(C_ARD_NUM_CE_ARRAY)-1);
   signal AXI_Bus2IP_WrCE  : std_logic_vector(0 to
                                calc_num_ce(C_ARD_NUM_CE_ARRAY)-1);
-- Derived IPIC signals for use with the reset register functionality
   signal reset2Bus_Error  : std_logic;
   signal reset2IP_Reset   : std_logic;

-- Derived IPIC signals for use with the interrupt controller
   signal Intr2Bus_DevIntr : std_logic;
   signal Intr2Bus_DBus    : std_logic_vector(0 to C_S_AXI_DATA_WIDTH-1);

-------------------------------------------------------------------------------
begin
-------------------------------------------------------------------------------
--------------------------------------------------------------------------
-- RESET signal assignment - IPIC RESET is active low
--------------------------------------------------------------------------

    AXI_Bus2IP_Reset <= not AXI_Bus2IP_Resetn;

    AXI_LITE_IPIF_I : entity axi_lite_ipif_v3_0_3.axi_lite_ipif
      generic map
       (
        C_FAMILY                  => C_FAMILY,
        C_S_AXI_ADDR_WIDTH        => C_S_AXI_ADDR_WIDTH,
        C_S_AXI_DATA_WIDTH        => C_S_AXI_DATA_WIDTH,
        C_S_AXI_MIN_SIZE          => C_S_AXI_MIN_SIZE,
        C_USE_WSTRB               => C_USE_WSTRB,
        C_DPHASE_TIMEOUT          => C_DPHASE_TIMEOUT,
        C_ARD_ADDR_RANGE_ARRAY    => C_ARD_ADDR_RANGE_ARRAY,
        C_ARD_NUM_CE_ARRAY        => C_ARD_NUM_CE_ARRAY
       )
     port map
      (
         -- System signals
        S_AXI_ACLK          =>  S_AXI_ACLK,
        S_AXI_ARESETN       =>  S_AXI_ARESETN,

         -- AXI Interface signals
        S_AXI_AWADDR        =>  S_AXI_AWADDR,
        S_AXI_AWVALID       =>  S_AXI_AWVALID,
        S_AXI_AWREADY       =>  S_AXI_AWREADY,
        S_AXI_WDATA         =>  S_AXI_WDATA,
        S_AXI_WSTRB         =>  S_AXI_WSTRB,
        S_AXI_WVALID        =>  S_AXI_WVALID,
        S_AXI_WREADY        =>  S_AXI_WREADY,
        S_AXI_BRESP         =>  S_AXI_BRESP,
        S_AXI_BVALID        =>  S_AXI_BVALID,
        S_AXI_BREADY        =>  S_AXI_BREADY,
        S_AXI_ARADDR        =>  S_AXI_ARADDR,
        S_AXI_ARVALID       =>  S_AXI_ARVALID,
        S_AXI_ARREADY       =>  S_AXI_ARREADY,
        S_AXI_RDATA         =>  S_AXI_RDATA,
        S_AXI_RRESP         =>  S_AXI_RRESP,
        S_AXI_RVALID        =>  S_AXI_RVALID,
        S_AXI_RREADY        =>  S_AXI_RREADY,

         -- IP Interconnect (IPIC) port signals
        Bus2IP_Clk          =>  AXI_Bus2IP_Clk,
        Bus2IP_Resetn       =>  AXI_Bus2IP_Resetn,
        IP2Bus_Data         =>  AXI_IP2Bus_Data,
        IP2Bus_WrAck        =>  AXI_IP2Bus_WrAck,
        IP2Bus_RdAck        =>  AXI_IP2Bus_RdAck,
        IP2Bus_Error        =>  AXI_IP2Bus_Error,
        Bus2IP_Addr         =>  AXI_Bus2IP_Addr,
        Bus2IP_Data         =>  AXI_Bus2IP_Data,
        Bus2IP_RNW          =>  AXI_Bus2IP_RNW,
        Bus2IP_BE           =>  open,
        Bus2IP_CS           =>  AXI_Bus2IP_CS,
        Bus2IP_RdCE         =>  AXI_Bus2IP_RdCE,
        Bus2IP_WrCE         =>  AXI_Bus2IP_WrCE
        );

-------------------------------------------------------------------------------
-- INTERRUPT DEVICE
-------------------------------------------------------------------------------

   X_INTERRUPT_CONTROL : entity interrupt_control_v3_1_2.interrupt_control
      generic map (
         C_NUM_CE => C_NUM_INTERRUPT_REGS,  -- [integer range 4 to 16]
         -- Number of register chip enables required
         -- For C_IPIF_DWIDTH=32  Set C_NUM_CE = 16
         -- For C_IPIF_DWIDTH=64  Set C_NUM_CE = 8
         -- For C_IPIF_DWIDTH=128 Set C_NUM_CE = 4

         C_NUM_IPIF_IRPT_SRC => 1,  -- [integer range 1 to 29]

         C_IP_INTR_MODE_ARRAY => C_IP_INTR_MODE_ARRAY,  -- [INTEGER_ARRAY_TYPE]
         -- Interrupt Modes
         --1,  -- pass through (non-inverting)
         --2,  -- pass through (inverting)
         --3,  -- registered level (non-inverting)
         --4,  -- registered level (inverting)
         --5,  -- positive edge detect
         --6   -- negative edge detect

         C_INCLUDE_DEV_PENCODER => C_INCLUDE_DEV_PENCODER,  -- [boolean]
         -- Specifies device Priority Encoder function

         C_INCLUDE_DEV_ISC => C_INCLUDE_DEV_ISC,  -- [boolean]
         -- Specifies device ISC hierarchy
         -- Exclusion of Device ISC requires
         -- exclusion of Priority encoder

         C_IPIF_DWIDTH => C_S_AXI_DATA_WIDTH  -- [integer range 32 to 128]
         )
      port map (

         -- Inputs From the IPIF Bus
         Bus2IP_Clk     => AXI_Bus2IP_Clk,
         Bus2IP_Reset   => reset2IP_Reset,
         Bus2IP_Data    => AXI_Bus2IP_Data,
         Bus2IP_BE      => "1111",
         Interrupt_RdCE => AXI_Bus2IP_RdCE(INTERRUPT_CE_RNG),
         Interrupt_WrCE => AXI_Bus2IP_WrCE(INTERRUPT_CE_RNG),

         -- Interrupt inputs from the IPIF sources that will
         -- get registered in this design
         IPIF_Reg_Interrupts => "00",

         -- Level Interrupt inputs from the IPIF sources
         IPIF_Lvl_Interrupts => "0",

         -- Inputs from the IP Interface
         IP2Bus_IntrEvent => IIC2Bus_IntrEvent,

         -- Final Device Interrupt Output
         Intr2Bus_DevIntr => IIC2INTC_Irpt,

         -- Status Reply Outputs to the Bus
         Intr2Bus_DBus    => Intr2Bus_DBus,
         Intr2Bus_WrAck   => open,
         Intr2Bus_RdAck   => open,
         Intr2Bus_Error   => open,
         Intr2Bus_Retry   => open,
         Intr2Bus_ToutSup => open
         );

-------------------------------------------------------------------------------
-- SOFT RESET REGISTER
-------------------------------------------------------------------------------

   X_SOFT_RESET : entity axi_iic_v2_0_9.soft_reset
      generic map (
         C_SIPIF_DWIDTH => C_S_AXI_DATA_WIDTH,  -- [integer]
         -- Width of the write data bus
         C_RESET_WIDTH => 4)
      port map (

         -- Inputs From the IPIF Bus
         Bus2IP_Reset      => AXI_Bus2IP_Reset,
         Bus2IP_Clk        => AXI_Bus2IP_Clk,
         Bus2IP_WrCE       => AXI_Bus2IP_WrCE(RESET_CE_RNG'LEFT),
         Bus2IP_Data       => AXI_Bus2IP_Data,
         Bus2IP_BE         => "1111",

         -- Final Device Reset Output
         reset2IP_Reset    => reset2IP_Reset,

         -- Status Reply Outputs to the Bus
         reset2Bus_WrAck   => open,
         reset2Bus_Error   => reset2Bus_Error,
         Reset2Bus_ToutSup => open);

-------------------------------------------------------------------------------
-- IIC Register (External) Connections
-------------------------------------------------------------------------------
        Bus2IIC_Clk   <= AXI_Bus2IP_Clk;
        Bus2IIC_Reset <= reset2IP_Reset;
        Bus2IIC_Addr  <= AXI_Bus2IP_Addr;
        Bus2IIC_Data  <= AXI_Bus2IP_Data;
        Bus2IIC_RNW   <= AXI_Bus2IP_RNW;
        Bus2IIC_RdCE  <= AXI_Bus2IP_RdCE(IIC_CE_RNG);
        Bus2IIC_WrCE  <= AXI_Bus2IP_WrCE(IIC_CE_RNG);

-------------------------------------------------------------------------------
-- Read Ack/Write Ack generation
-------------------------------------------------------------------------------
      process(AXI_Bus2IP_Clk)
        begin
          if(AXI_Bus2IP_Clk'event and AXI_Bus2IP_Clk = '1') then
            AXI_IP2Bus_RdAck2 <= or_reduce(AXI_Bus2IP_CS) and AXI_Bus2IP_RNW;
            AXI_IP2Bus_RdAck1 <= AXI_IP2Bus_RdAck2;
          end if;
      end process;

      AXI_IP2Bus_RdAck <= (not (AXI_IP2Bus_RdAck1)) and AXI_IP2Bus_RdAck2;

      process(AXI_Bus2IP_Clk)
        begin
          if(AXI_Bus2IP_Clk'event and AXI_Bus2IP_Clk = '1') then
            AXI_IP2Bus_WrAck2 <= (or_reduce(AXI_Bus2IP_CS) and not AXI_Bus2IP_RNW);
            AXI_IP2Bus_WrAck1 <= AXI_IP2Bus_WrAck2;
          end if;
      end process;

      AXI_IP2Bus_WrAck <= (not AXI_IP2Bus_WrAck1) and AXI_IP2Bus_WrAck2;
-------------------------------------------------------------------------------
-- Data and Error generation
-------------------------------------------------------------------------------
    AXI_IP2Bus_Data <= Intr2Bus_DBus or IIC2Bus_Data;
    AXI_IP2Bus_Error <= reset2Bus_Error;
end architecture RTL;
