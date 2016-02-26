-------------------------------------------------------------------------------
-- iic.vhd - entity/architecture pair
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
-- Filename:        iic.vhd
-- Version:         v1.01.b
-- Description:
--                  This file contains the top level file for the iic Bus
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
-- ~~~~~~
--
-- NLR      01/07/11
-- ^^^^^^
--  - Release of v1.01.b
--  - Fixed the CR#613282
-- ~~~~~~~
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library axi_iic_v2_0_9;
use axi_iic_v2_0_9.iic_pkg.all;


-------------------------------------------------------------------------------
-- Definition of Generics:
--
--   C_NUM_IIC_REGS         -- Number of IIC Registers
--   C_S_AXI_ACLK_FREQ_HZ   -- Specifies AXI clock frequency
--   C_IIC_FREQ             -- Maximum frequency of Master Mode in Hz
--   C_TEN_BIT_ADR          -- 10 bit slave addressing
--   C_GPO_WIDTH            -- Width of General purpose output vector
--   C_SCL_INERTIAL_DELAY   -- SCL filtering
--   C_SDA_INERTIAL_DELAY   -- SDA filtering
--   C_SDA_LEVEL            -- SDA level
--   C_TX_FIFO_EXIST        -- IIC transmit FIFO exist
--   C_RC_FIFO_EXIST        -- IIC receive FIFO exist
--   C_S_AXI_ADDR_WIDTH     -- Width of AXI Address Bus (in bits)
--   C_S_AXI_DATA_WIDTH     -- Width of the AXI Data Bus (in bits)
--   C_FAMILY               -- XILINX FPGA family
-------------------------------------------------------------------------------
-- Definition of ports:
--
--   System Signals
--      S_AXI_ACLK            -- AXI Clock
--      S_AXI_ARESETN         -- AXI Reset
--      IP2INTC_Irpt          -- System interrupt output
--
--   AXI signals
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
--   IIC Signals
--      Sda_I               -- IIC serial data input
--      Sda_O               -- IIC serial data output
--      Sda_T               -- IIC seral data output enable
--      Scl_I               -- IIC serial clock input
--      Scl_O               -- IIC serial clock output
--      Scl_T               -- IIC serial clock output enable
--      Gpo                 -- General purpose outputs
--
-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
entity iic is
   generic (

      -- System Generics
      C_NUM_IIC_REGS         : integer                   := 10;

      --IIC Generics to be set by user
      C_S_AXI_ACLK_FREQ_HZ   : integer  := 100000000;
      C_IIC_FREQ             : integer  := 100000;
      C_TEN_BIT_ADR          : integer  := 0;
      C_GPO_WIDTH            : integer  := 0;
      C_SCL_INERTIAL_DELAY   : integer  := 0;
      C_SDA_INERTIAL_DELAY   : integer  := 0;
      C_SDA_LEVEL            : integer  := 1;
      C_SMBUS_PMBUS_HOST     : integer  := 0;   -- SMBUS/PMBUS support
      C_TX_FIFO_EXIST        : boolean  := TRUE;
      C_RC_FIFO_EXIST        : boolean  := TRUE;
      C_S_AXI_ADDR_WIDTH     : integer  := 9;
      C_S_AXI_DATA_WIDTH     : integer range 32 to 32 := 32;
      C_FAMILY               : string   := "virtex7";
      C_DEFAULT_VALUE        : std_logic_vector(7 downto 0) := X"FF"
      );

   port
      (
-- System signals
      S_AXI_ACLK            : in  std_logic;
      S_AXI_ARESETN         : in  std_logic;
      IIC2INTC_Irpt         : out std_logic;

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

      -- IIC Bus Signals
      Sda_I          : in  std_logic;
      Sda_O          : out std_logic;
      Sda_T          : out std_logic;
      Scl_I          : in  std_logic;
      Scl_O          : out std_logic;
      Scl_T          : out std_logic;
      Gpo            : out std_logic_vector(0 to C_GPO_WIDTH-1)
      );

end entity iic;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

architecture RTL of iic is
  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";


   -- Calls the function from the iic_pkg.vhd
   constant C_SIZE : integer := num_ctr_bits(C_S_AXI_ACLK_FREQ_HZ, C_IIC_FREQ);

   signal Msms_rst       : std_logic;
   signal Msms_set       : std_logic;
   signal Rsta_rst       : std_logic;
   signal Dtc            : std_logic;
   signal Rdy_new_xmt    : std_logic;
   signal New_rcv_dta    : std_logic;
   signal Ro_prev        : std_logic;
   signal Dtre           : std_logic;
   signal Bb             : std_logic;
   signal Aas            : std_logic;
   signal Al             : std_logic;
   signal Srw            : std_logic;
   signal Txer           : std_logic;
   signal Tx_under_prev  : std_logic;
   signal Abgc           : std_logic;
   signal Data_i2c       : std_logic_vector(0 to 7);
   signal Adr            : std_logic_vector(0 to 7);
   signal Ten_adr        : std_logic_vector(5 to 7);
   signal Cr             : std_logic_vector(0 to 7);
   signal Drr            : std_logic_vector(0 to 7);
   signal Dtr            : std_logic_vector(0 to 7);
   signal Tx_fifo_data   : std_logic_vector(0 to 7);
   signal Tx_data_exists : std_logic;
   signal Tx_fifo_wr     : std_logic;
   signal Tx_fifo_wr_i   : std_logic;
   signal Tx_fifo_wr_d   : std_logic;
   signal Tx_fifo_rd     : std_logic;
   signal Tx_fifo_rd_i   : std_logic;
   signal Tx_fifo_rd_d   : std_logic;
   signal Tx_fifo_rst    : std_logic;
   signal Tx_fifo_full   : std_logic;
   signal Tx_addr        : std_logic_vector(0 to TX_FIFO_BITS - 1);
   signal Rc_fifo_data   : std_logic_vector(0 to 7);
   signal Rc_fifo_wr     : std_logic;
   signal Rc_fifo_wr_i   : std_logic;
   signal Rc_fifo_wr_d   : std_logic;
   signal Rc_fifo_rd     : std_logic;
   signal Rc_fifo_rd_i   : std_logic;
   signal Rc_fifo_rd_d   : std_logic;
   signal Rc_fifo_full   : std_logic;
   signal Rc_Data_Exists : std_logic;
   signal Rc_addr        : std_logic_vector(0 to RC_FIFO_BITS -1);
   signal Bus2IIC_Clk    : std_logic;
   signal Bus2IIC_Reset  : std_logic;
   signal IIC2Bus_Data   : std_logic_vector(0 to C_S_AXI_DATA_WIDTH - 1) :=
                           (others => '0');
   signal IIC2Bus_IntrEvent : std_logic_vector(0 to 7) := (others => '0');
   signal Bus2IIC_Addr   : std_logic_vector(0 to C_S_AXI_ADDR_WIDTH - 1);
   signal Bus2IIC_Data   : std_logic_vector(0 to C_S_AXI_DATA_WIDTH - 1);
   signal Bus2IIC_RNW    : std_logic;
   signal Bus2IIC_RdCE   : std_logic_vector(0 to C_NUM_IIC_REGS - 1);
   signal Bus2IIC_WrCE   : std_logic_vector(0 to C_NUM_IIC_REGS - 1);

   -- signals for dynamic start/stop
   signal ctrlFifoDin         : std_logic_vector(0 to 1);
   signal dynamic_MSMS        : std_logic_vector(0 to 1);
   signal dynRstaSet          : std_logic;
   signal dynMsmsSet          : std_logic;
   signal txak                : std_logic;
   signal earlyAckDataState   : std_logic;
   signal ackDataState        : std_logic;
   signal earlyAckHdr         : std_logic;
   signal cr_txModeSelect_set : std_logic;
   signal cr_txModeSelect_clr : std_logic;
   signal txFifoRd            : std_logic;
   signal Msms_rst_r          : std_logic;
   signal ctrl_fifo_wr_i      : std_logic;

   -- Cleaned up inputs
   signal scl_clean : std_logic;
   signal sda_clean : std_logic;

   -- Timing Parameters
   signal Timing_param_tsusta   : std_logic_vector(C_SIZE-1 downto 0);
   signal Timing_param_tsusto   : std_logic_vector(C_SIZE-1 downto 0);
   signal Timing_param_thdsta   : std_logic_vector(C_SIZE-1 downto 0);
   signal Timing_param_tsudat   : std_logic_vector(C_SIZE-1 downto 0);
   signal Timing_param_tbuf     : std_logic_vector(C_SIZE-1 downto 0);
   signal Timing_param_thigh    : std_logic_vector(C_SIZE-1 downto 0);
   signal Timing_param_tlow     : std_logic_vector(C_SIZE-1 downto 0);
   signal Timing_param_thddat   : std_logic_vector(C_SIZE-1 downto 0);
----------Mathew
-- signal transfer_done : std_logic;
 signal reg_empty     : std_logic;
----------Mathew
begin

   ----------------------------------------------------------------------------
   -- axi_ipif_ssp1 instantiation
   ----------------------------------------------------------------------------

   X_AXI_IPIF_SSP1 : entity axi_iic_v2_0_9.axi_ipif_ssp1
      generic map (
         C_NUM_IIC_REGS => C_NUM_IIC_REGS,


         C_S_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH,
         --  width of the AXI Address Bus (in bits)

         C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
         --  Width of AXI Data Bus (in bits) Must be 32

         C_FAMILY => C_FAMILY)
      port map (

         -- System signals ----------------------------------------------------
        S_AXI_ACLK          =>  S_AXI_ACLK,
        S_AXI_ARESETN       =>  S_AXI_ARESETN,
        IIC2Bus_IntrEvent   => IIC2Bus_IntrEvent,  -- IIC Interrupt events
        IIC2INTC_Irpt       => IIC2INTC_Irpt,

         -- AXI Interface signals --------------
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

         -- IP Interconnect (IPIC) port signals used by the IIC registers. ----
         Bus2IIC_Clk         => Bus2IIC_Clk,
         Bus2IIC_Reset       => Bus2IIC_Reset,
         Bus2IIC_Addr        => Bus2IIC_Addr,
         Bus2IIC_Data        => Bus2IIC_Data,
         Bus2IIC_RNW         => Bus2IIC_RNW,
         Bus2IIC_RdCE        => Bus2IIC_RdCE,
         Bus2IIC_WrCE        => Bus2IIC_WrCE,
         IIC2Bus_Data        => IIC2Bus_Data
         );

   ----------------------------------------------------------------------------
   -- reg_interface instantiation
   ----------------------------------------------------------------------------

   REG_INTERFACE_I : entity axi_iic_v2_0_9.reg_interface
      generic map (
         C_SCL_INERTIAL_DELAY => C_SCL_INERTIAL_DELAY, -- [range 0 to 255]
         C_S_AXI_ACLK_FREQ_HZ => C_S_AXI_ACLK_FREQ_HZ,
         C_IIC_FREQ           => C_IIC_FREQ,
         C_SMBUS_PMBUS_HOST   => C_SMBUS_PMBUS_HOST,
         C_TX_FIFO_EXIST      => C_TX_FIFO_EXIST ,
         C_TX_FIFO_BITS       => 4               ,
         C_RC_FIFO_EXIST      => C_RC_FIFO_EXIST ,
         C_RC_FIFO_BITS       => 4               ,
         C_TEN_BIT_ADR        => C_TEN_BIT_ADR   ,
         C_GPO_WIDTH          => C_GPO_WIDTH     ,
         C_S_AXI_ADDR_WIDTH   => C_S_AXI_ADDR_WIDTH  ,
         C_S_AXI_DATA_WIDTH   => C_S_AXI_DATA_WIDTH  ,
         C_SIZE               => C_SIZE             ,
         C_NUM_IIC_REGS       => C_NUM_IIC_REGS     ,
         C_DEFAULT_VALUE      => C_DEFAULT_VALUE
         )
      port map (
         Clk                 => Bus2IIC_Clk,
         Rst                 => Bus2IIC_Reset,
         Bus2IIC_Addr        => Bus2IIC_Addr,
         Bus2IIC_Data        => Bus2IIC_Data(0 to C_S_AXI_DATA_WIDTH - 1),
         Bus2IIC_RdCE        => Bus2IIC_RdCE,
         Bus2IIC_WrCE        => Bus2IIC_WrCE,
         IIC2Bus_Data        => IIC2Bus_Data(0 to C_S_AXI_DATA_WIDTH - 1),
         IIC2Bus_IntrEvent   => IIC2Bus_IntrEvent,
         Gpo                 => Gpo(0 to C_GPO_WIDTH-1),
         Cr                  => Cr,
         Dtr                 => Dtr,
         Drr                 => Drr,
         Adr                 => Adr,
         Ten_adr             => Ten_adr,
         Msms_set            => Msms_set,
         Msms_rst            => Msms_rst,
         DynMsmsSet          => dynMsmsSet,
         DynRstaSet          => dynRstaSet,
         Cr_txModeSelect_set => cr_txModeSelect_set,
         Cr_txModeSelect_clr => cr_txModeSelect_clr,
         Rsta_rst            => Rsta_rst,
         Rdy_new_xmt         => Rdy_new_xmt,
         New_rcv_dta         => New_rcv_dta,
         Ro_prev             => Ro_prev,
         Dtre                => Dtre,
         Aas                 => Aas,
         Bb                  => Bb,
         Srw                 => Srw,
         Al                  => Al,
         Txer                => Txer,
         Tx_under_prev       => Tx_under_prev,
         Abgc                => Abgc,
         Data_i2c            => Data_i2c,
         Timing_param_tsusta => Timing_param_tsusta,
         Timing_param_tsusto => Timing_param_tsusto,
         Timing_param_thdsta => Timing_param_thdsta,
         Timing_param_tsudat => Timing_param_tsudat,
         Timing_param_tbuf   => Timing_param_tbuf  ,
         Timing_param_thigh  => Timing_param_thigh ,
         Timing_param_tlow   => Timing_param_tlow  ,
         Timing_param_thddat => Timing_param_thddat,
         Tx_fifo_data        => Tx_fifo_data(0 to 7),
         Tx_data_exists      => Tx_data_exists,
         Tx_fifo_wr          => Tx_fifo_wr,
         Tx_fifo_rd          => Tx_fifo_rd,
         Tx_fifo_full        => Tx_fifo_full,
         Tx_fifo_rst         => Tx_fifo_rst,
         Tx_addr             => Tx_addr(0 to TX_FIFO_BITS - 1),
         Rc_fifo_data        => Rc_fifo_data(0 to 7),
         Rc_fifo_wr          => Rc_fifo_wr,
         Rc_fifo_rd          => Rc_fifo_rd,
         Rc_fifo_full        => Rc_fifo_full,
         Rc_Data_Exists      => Rc_Data_Exists,
         Rc_addr             => Rc_addr(0 to RC_FIFO_BITS - 1),
         reg_empty           => reg_empty
         );

   ----------------------------------------------------------------------------
   -- The V5 inputs are so fast that they typically create glitches longer then
   -- the clock period due to the extremely slow rise/fall times on SDA/SCL
   -- signals. The inertial delay filter removes these.
   ----------------------------------------------------------------------------

   FILTER_I: entity axi_iic_v2_0_9.filter
      generic map (
         SCL_INERTIAL_DELAY  => C_SCL_INERTIAL_DELAY, -- [range 0 to 255]
         SDA_INERTIAL_DELAY  => C_SDA_INERTIAL_DELAY  -- [range 0 to 255]
         )
      port map
         (
         Sysclk         => Bus2IIC_Clk,
         Rst            => Bus2IIC_Reset,
         Scl_noisy      => Scl_I,
         Scl_clean      => scl_clean,
         Sda_noisy      => Sda_I,
         Sda_clean      => sda_clean
         );

   ----------------------------------------------------------------------------
   -- iic_control instantiation
   ----------------------------------------------------------------------------

   IIC_CONTROL_I : entity axi_iic_v2_0_9.iic_control
      generic map
         (
         C_SCL_INERTIAL_DELAY   => C_SCL_INERTIAL_DELAY,
         C_S_AXI_ACLK_FREQ_HZ   => C_S_AXI_ACLK_FREQ_HZ,
         C_IIC_FREQ             => C_IIC_FREQ,
         C_SIZE                 => C_SIZE    ,
         C_TEN_BIT_ADR          => C_TEN_BIT_ADR,
         C_SDA_LEVEL            => C_SDA_LEVEL,
         C_SMBUS_PMBUS_HOST     => C_SMBUS_PMBUS_HOST
         )
      port map
         (
         Sys_clk               => Bus2IIC_Clk,
         Reset                 => Cr(7),
         Sda_I                 => sda_clean,
         Sda_O                 => Sda_O,
         Sda_T                 => Sda_T,
         Scl_I                 => scl_clean,
         Scl_O                 => Scl_O,
         Scl_T                 => Scl_T,

         Timing_param_tsusta   => Timing_param_tsusta,
         Timing_param_tsusto   => Timing_param_tsusto,
         Timing_param_thdsta   => Timing_param_thdsta,
         Timing_param_tsudat   => Timing_param_tsudat,
         Timing_param_tbuf     => Timing_param_tbuf  ,
         Timing_param_thigh    => Timing_param_thigh ,
         Timing_param_tlow     => Timing_param_tlow  ,
         Timing_param_thddat   => Timing_param_thddat,

         Txak                  => txak,
         Msms                  => Cr(5),
         Msms_set              => Msms_set,
         Msms_rst              => Msms_rst_r,
         Rsta                  => Cr(2),
         Rsta_rst              => Rsta_rst,
         Tx                    => Cr(4),
         Gc_en                 => Cr(1),
         Dtr                   => Dtr,
         Adr                   => Adr,
         Ten_adr               => Ten_adr,
         Bb                    => Bb,
         Dtc                   => Dtc,
         Aas                   => Aas,
         Al                    => Al,
         Srw                   => Srw,
         Txer                  => Txer,
         Tx_under_prev         => Tx_under_prev,
         Abgc                  => Abgc,
         Data_i2c              => Data_i2c,
         New_rcv_dta           => New_rcv_dta,
         Ro_prev               => Ro_prev,
         Dtre                  => Dtre,
         Rdy_new_xmt           => Rdy_new_xmt,
         EarlyAckHdr           => earlyAckHdr,
         EarlyAckDataState     => earlyAckDataState,
         AckDataState          => ackDataState,
         reg_empty             => reg_empty 
         );

   ----------------------------------------------------------------------------
   -- Transmitter FIFO instantiation
   ----------------------------------------------------------------------------

   WRITE_FIFO_I : entity axi_iic_v2_0_9.srl_fifo
      generic map (
         C_DATA_BITS    => DATA_BITS,
         C_DEPTH        => TX_FIFO_BITS
         )
      port map
         (
         Clk            => Bus2IIC_Clk,
         Reset          => Tx_fifo_rst,
         FIFO_Write     => Tx_fifo_wr_i,
         Data_In        => Bus2IIC_Data(24 to 31),
         FIFO_Read      => txFifoRd,
         Data_Out       => Tx_fifo_data(0 to 7),
         FIFO_Full      => Tx_fifo_full,
         Data_Exists    => Tx_data_exists,
         Addr           => Tx_addr(0 to TX_FIFO_BITS - 1)
         );
-------Mathew
   --  transfer_done <= '1' when Tx_data_exists = '0' and reg_empty ='1' else '0';
-------Mathew
   ----------------------------------------------------------------------------
   -- Receiver FIFO instantiation
   ----------------------------------------------------------------------------

   READ_FIFO_I : entity axi_iic_v2_0_9.srl_fifo
      generic map (
         C_DATA_BITS    => DATA_BITS,
         C_DEPTH        => RC_FIFO_BITS
         )
      port map (
         Clk            => Bus2IIC_Clk,
         Reset          => Bus2IIC_Reset,
         FIFO_Write     => Rc_fifo_wr_i,
         Data_In        => Data_i2c(0 to 7),
         FIFO_Read      => Rc_fifo_rd_i,
         Data_Out       => Rc_fifo_data(0 to 7),
         FIFO_Full      => Rc_fifo_full,
         Data_Exists    => Rc_Data_Exists,
         Addr           => Rc_addr(0 to RC_FIFO_BITS - 1)
         );

   ----------------------------------------------------------------------------
   -- PROCESS: TX_FIFO_WR_GEN
   -- purpose: generate TX FIFO write control signals
   ----------------------------------------------------------------------------

   TX_FIFO_WR_GEN : process(Bus2IIC_Clk)
   begin
      if(Bus2IIC_Clk'event and Bus2IIC_Clk = '1') then
         if(Bus2IIC_Reset = '1') then
            Tx_fifo_wr_d <= '0';
            Tx_fifo_rd_d <= '0';
         else
            Tx_fifo_wr_d <= Tx_fifo_wr;
            Tx_fifo_rd_d <= Tx_fifo_rd;
         end if;
      end if;
   end process TX_FIFO_WR_GEN;

   ----------------------------------------------------------------------------
   -- PROCESS: RC_FIFO_WR_GEN
   -- purpose: generate TX FIFO write control signals
   ----------------------------------------------------------------------------

   RC_FIFO_WR_GEN : process(Bus2IIC_Clk)
   begin
      if(Bus2IIC_Clk'event and Bus2IIC_Clk = '1') then
         if(Bus2IIC_Reset = '1') then
            Rc_fifo_wr_d <= '0';
            Rc_fifo_rd_d <= '0';
         else
            Rc_fifo_wr_d <= Rc_fifo_wr;
            Rc_fifo_rd_d <= Rc_fifo_rd;
         end if;
      end if;
   end process RC_FIFO_WR_GEN;

   Tx_fifo_wr_i <= Tx_fifo_wr and (not Tx_fifo_wr_d);
   Rc_fifo_wr_i <= Rc_fifo_wr and (not Rc_fifo_wr_d);

   Tx_fifo_rd_i <= Tx_fifo_rd and (not Tx_fifo_rd_d);
   Rc_fifo_rd_i <= Rc_fifo_rd and (not Rc_fifo_rd_d);

   ----------------------------------------------------------------------------
   -- Dynamic master interface
   -- Dynamic master start/stop and control logic
   ----------------------------------------------------------------------------

   DYN_MASTER_I : entity axi_iic_v2_0_9.dynamic_master
      port map (
         Clk                 => Bus2IIC_Clk ,
         Rst                 => Tx_fifo_rst ,
         dynamic_MSMS        => dynamic_MSMS ,
         Cr                  => Cr ,
         Tx_fifo_rd_i        => Tx_fifo_rd_i ,
         Tx_data_exists      => Tx_data_exists ,
         ackDataState        => ackDataState ,
         Tx_fifo_data        => Tx_fifo_data ,
         earlyAckHdr         => earlyAckHdr ,
         earlyAckDataState   => earlyAckDataState ,
         Bb                  => Bb ,
         Msms_rst_r          => Msms_rst_r ,
         dynMsmsSet          => dynMsmsSet ,
         dynRstaSet          => dynRstaSet ,
         Msms_rst            => Msms_rst ,
         txFifoRd            => txFifoRd ,
         txak                => txak ,
         cr_txModeSelect_set => cr_txModeSelect_set,
         cr_txModeSelect_clr => cr_txModeSelect_clr
         );

   -- virtual reset. Since srl fifo address is rst at the same time, only the
   -- first entry in the srl fifo needs to have a value of '00' to appear
   -- reset. Also, force data to 0 if a byte write is done to the txFifo.
   ctrlFifoDin <= Bus2IIC_Data(22 to 23) when (Tx_fifo_rst = '0' and
                                               Bus2IIC_Reset = '0') else
                  "00";

   -- continuously write srl fifo while reset active
   ctrl_fifo_wr_i <= Tx_fifo_rst or Bus2IIC_Reset or Tx_fifo_wr_i;

   ----------------------------------------------------------------------------
   -- Control FIFO instantiation
   -- fifo used to set/reset MSMS bit in control register to create automatic
   -- START/STOP conditions
   ----------------------------------------------------------------------------

   WRITE_FIFO_CTRL_I : entity axi_iic_v2_0_9.srl_fifo
      generic map (
         C_DATA_BITS => 2,
         C_DEPTH     => TX_FIFO_BITS
         )
      port map
         (
         Clk         => Bus2IIC_Clk,
         Reset       => Tx_fifo_rst,
         FIFO_Write  => ctrl_fifo_wr_i,
         Data_In     => ctrlFifoDin,
         FIFO_Read   => txFifoRd,
         Data_Out    => dynamic_MSMS,
         FIFO_Full   => open,
         Data_Exists => open,
         Addr        => open
         );

end architecture RTL;
