-------------------------------------------------------------------
-- (c) Copyright 1984 - 2012 Xilinx, Inc. All rights reserved.	 --
--								 --
-- This file contains confidential and proprietary information	 --
-- of Xilinx, Inc. and is protected under U.S. and		 --
-- international copyright and other intellectual property	 --
-- laws.							 --
--								 --
-- DISCLAIMER							 --
-- This disclaimer is not a license and does not grant any	 --
-- rights to the materials distributed herewith. Except as	 --
-- otherwise provided in a valid license issued to you by	 --
-- Xilinx, and to the maximum extent permitted by applicable	 --
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND	 --
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES	 --
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING	 --
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-	 --
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and	 --
-- (2) Xilinx shall not be liable (whether in contract or tort,	 --
-- including negligence, or under any other theory of		 --
-- liability) for any loss or damage of any kind or nature	 --
-- related to, arising under or in connection with these	 --
-- materials, including for any direct, or any indirect,	 --
-- special, incidental, or consequential loss or damage		 --
-- (including loss of data, profits, goodwill, or any type of	 --
-- loss or damage suffered as a result of any action brought	 --
-- by a third party) even if such damage or loss was		 --
-- reasonably foreseeable or Xilinx had been advised of the	 --
-- possibility of the same.					 --
--								 --
-- CRITICAL APPLICATIONS					 --
-- Xilinx products are not designed or intended to be fail-	 --
-- safe, or for use in any application requiring fail-safe	 --
-- performance, such as life-support or safety devices or	 --
-- systems, Class III medical devices, nuclear facilities,	 --
-- applications related to the deployment of airbags, or any	 --
-- other applications that could lead to death, personal	 --
-- injury, or severe property or environmental damage		 --
-- (individually and collectively, "Critical			 --
-- Applications"). Customer assumes the sole risk and		 --
-- liability of any use of Xilinx products in Critical		 --
-- Applications, subject only to applicable laws and		 --
-- regulations governing limitations on product liability.	 --
--								 --
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS	 --
-- PART OF THIS FILE AT ALL TIMES. 				 --
-------------------------------------------------------------------
-- ************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        axi_lite_ipif.vhd
-- Version:         v1.01.a
-- Description:     This is the top level design file for the axi_lite_ipif
--                  function. It provides a standardized slave interface
--                  between the IP and the AXI. This version supports
--                  single read/write transfers only.  It does not provide
--                  address pipelining or simultaneous read and write
--                  operations.
-------------------------------------------------------------------------------
-- Structure:   This section shows the hierarchical structure of axi_lite_ipif.
--
--              --axi_lite_ipif.vhd
--                    --slave_attachment.vhd
--                       --address_decoder.vhd
-------------------------------------------------------------------------------
-- Author:      BSB
--
-- History:
--
--  BSB      05/20/10      -- First version
-- ~~~~~~
--  - Created the first version v1.00.a
-- ^^^^^^
-- ~~~~~~
--  SK       06/09/10      -- v1.01.a
--  1. updated to reduce the utilization
--     Closed CR #574507
--  2. Optimized the state machine code
--  3. Optimized the address decoder logic to generate the CE's with common logic
--  4. Address GAP decoding logic is removed and timeout counter is made active
--     for all transactions.
-- ^^^^^^
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_TYPE"
--      state machine next state:               "*_ns"
--      state machine current state:            "*_cs"
--      combinatorial signals:                  "*_cmb"
--      pipelined or register delay signals:    "*_d#"
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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use work.common_types.all;


-------------------------------------------------------------------------------
--                     Definition of Generics
-------------------------------------------------------------------------------
-- C_S_AXI_DATA_WIDTH    -- AXI data bus width
-- C_S_AXI_ADDR_WIDTH    -- AXI address bus width
-- C_S_AXI_MIN_SIZE      -- Minimum address range of the IP
-- C_USE_WSTRB           -- Use write strobs or not
-- C_DPHASE_TIMEOUT      -- Data phase time out counter
-- C_ARD_ADDR_RANGE_ARRAY-- Base /High Address Pair for each Address Range
-- C_ARD_NUM_CE_ARRAY    -- Desired number of chip enables for an address range
-- C_FAMILY              -- Target FPGA family
-------------------------------------------------------------------------------
--                  Definition of Ports
-------------------------------------------------------------------------------
-- S_AXI_ACLK            -- AXI Clock
-- S_AXI_ARESETN         -- AXI Reset
-- S_AXI_AWADDR          -- AXI Write address
-- S_AXI_AWVALID         -- Write address valid
-- S_AXI_AWREADY         -- Write address ready
-- S_AXI_WDATA           -- Write data
-- S_AXI_WSTRB           -- Write strobes
-- S_AXI_WVALID          -- Write valid
-- S_AXI_WREADY          -- Write ready
-- S_AXI_BRESP           -- Write response
-- S_AXI_BVALID          -- Write response valid
-- S_AXI_BREADY          -- Response ready
-- S_AXI_ARADDR          -- Read address
-- S_AXI_ARVALID         -- Read address valid
-- S_AXI_ARREADY         -- Read address ready
-- S_AXI_RDATA           -- Read data
-- S_AXI_RRESP           -- Read response
-- S_AXI_RVALID          -- Read valid
-- S_AXI_RREADY          -- Read ready
-- Bus2IP_Clk            -- Synchronization clock provided to User IP
-- Bus2IP_Reset          -- Active high reset for use by the User IP
-- Bus2IP_Addr           -- Desired address of read or write operation
-- Bus2IP_RNW            -- Read or write indicator for the transaction
-- Bus2IP_BE             -- Byte enables for the data bus
-- Bus2IP_CS             -- Chip select for the transcations
-- Bus2IP_RdCE           -- Chip enables for the read
-- Bus2IP_WrCE           -- Chip enables for the write
-- Bus2IP_Data           -- Write data bus to the User IP
-- IP2Bus_Data           -- Input Read Data bus from the User IP
-- IP2Bus_WrAck          -- Active high Write Data qualifier from the IP
-- IP2Bus_RdAck          -- Active high Read Data qualifier from the IP
-- IP2Bus_Error          -- Error signal from the IP
-------------------------------------------------------------------------------

entity axi_lite_ipif is
    generic (

      C_S_AXI_DATA_WIDTH    : integer  range 32 to 32   := 32;
      C_S_AXI_ADDR_WIDTH    : integer                   := 32;
      C_S_AXI_MIN_SIZE      : std_logic_vector(31 downto 0):= X"000001FF";
      C_USE_WSTRB           : integer := 0;
      C_DPHASE_TIMEOUT      : integer range 0 to 512 := 8;
		
		
      C_ARD_ADDR_RANGE_ARRAY: SLV64_ARRAY_TYPE :=  -- not used
         (
           X"0000_0000_7000_0000", -- IP user0 base address
           X"0000_0000_7000_00FF", -- IP user0 high address
           X"0000_0000_7000_0100", -- IP user1 base address
           X"0000_0000_7000_01FF"  -- IP user1 high address
         );

      C_ARD_NUM_CE_ARRAY    : INTEGER_ARRAY_TYPE := -- not used
         (
           4,         -- User0 CE Number
           12         -- User1 CE Number
         );
      C_FAMILY              : string  := "virtex6"
           );
    port (

        --System signals
      S_AXI_ACLK            : in  std_logic;
      S_AXI_ARESETN         : in  std_logic;
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
      -- Controls to the IP/IPIF modules
      Bus2IP_Clk            : out std_logic;
      Bus2IP_Resetn         : out std_logic;
      Bus2IP_Addr           : out std_logic_vector
                              ((C_S_AXI_ADDR_WIDTH-1) downto 0);
      Bus2IP_RNW            : out std_logic;
      Bus2IP_BE             : out std_logic_vector
                              (((C_S_AXI_DATA_WIDTH/8)-1) downto 0);
      Bus2IP_CS             : out std_logic_vector
                              (((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2-1) downto 0);
      Bus2IP_RdCE           : out std_logic_vector
                              ((calc_num_ce(C_ARD_NUM_CE_ARRAY)-1) downto 0);
      Bus2IP_WrCE           : out std_logic_vector
                              ((calc_num_ce(C_ARD_NUM_CE_ARRAY)-1) downto 0);
      Bus2IP_Data           : out std_logic_vector
                              ((C_S_AXI_DATA_WIDTH-1) downto 0);
      IP2Bus_Data           : in  std_logic_vector
                              ((C_S_AXI_DATA_WIDTH-1) downto 0);
      IP2Bus_WrAck          : in  std_logic;
      IP2Bus_RdAck          : in  std_logic;
      IP2Bus_Error          : in  std_logic

       );

end axi_lite_ipif;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

architecture imp of axi_lite_ipif is

-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin

-------------------------------------------------------------------------------
-- Slave Attachment
-------------------------------------------------------------------------------

I_SLAVE_ATTACHMENT:  entity work.slave_attachment
    generic map(
        C_ARD_ADDR_RANGE_ARRAY    => C_ARD_ADDR_RANGE_ARRAY,
        C_ARD_NUM_CE_ARRAY        => C_ARD_NUM_CE_ARRAY,
        C_IPIF_ABUS_WIDTH         => C_S_AXI_ADDR_WIDTH,
        C_IPIF_DBUS_WIDTH         => C_S_AXI_DATA_WIDTH,
        C_USE_WSTRB               => C_USE_WSTRB,
        C_DPHASE_TIMEOUT          => C_DPHASE_TIMEOUT,
        C_S_AXI_MIN_SIZE          => C_S_AXI_MIN_SIZE,
        C_FAMILY                  => C_FAMILY
    )
    port map(
        -- AXI signals
        S_AXI_ACLK          =>  S_AXI_ACLK,
        S_AXI_ARESETN       =>  S_AXI_ARESETN,
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
        -- IPIC signals
        Bus2IP_Clk          =>  Bus2IP_Clk,
        Bus2IP_Resetn       =>  Bus2IP_Resetn,
        Bus2IP_Addr         =>  Bus2IP_Addr,
        Bus2IP_RNW          =>  Bus2IP_RNW,
        Bus2IP_BE           =>  Bus2IP_BE,
        Bus2IP_CS           =>  Bus2IP_CS,
        Bus2IP_RdCE         =>  Bus2IP_RdCE,
        Bus2IP_WrCE         =>  Bus2IP_WrCE,
        Bus2IP_Data         =>  Bus2IP_Data,
        IP2Bus_Data         =>  IP2Bus_Data,
        IP2Bus_WrAck        =>  IP2Bus_WrAck,
        IP2Bus_RdAck        =>  IP2Bus_RdAck,
        IP2Bus_Error        =>  IP2Bus_Error
    );

end imp;
