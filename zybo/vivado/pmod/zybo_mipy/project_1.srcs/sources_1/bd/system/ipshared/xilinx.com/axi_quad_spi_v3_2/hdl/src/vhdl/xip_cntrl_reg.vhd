-------------------------------------------------------------------------------
-- xip_cntrl_reg.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- *******************************************************************
-- ** (c) Copyright [2010] - [2012] Xilinx, Inc. All rights reserved.*
-- **                                                                *
-- ** This file contains confidential and proprietary information    *
-- ** of Xilinx, Inc. and is protected under U.S. and                *
-- ** international copyright and other intellectual property        *
-- ** laws.                                                          *
-- **                                                                *
-- ** DISCLAIMER                                                     *
-- ** This disclaimer is not a license and does not grant any        *
-- ** rights to the materials distributed herewith. Except as        *
-- ** otherwise provided in a valid license issued to you by         *
-- ** Xilinx, and to the maximum extent permitted by applicable      *
-- ** law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND        *
-- ** WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES    *
-- ** AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING      *
-- ** BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-         *
-- ** INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and       *
-- ** (2) Xilinx shall not be liable (whether in contract or tort,   *
-- ** including negligence, or under any other theory of             *
-- ** liability) for any loss or damage of any kind or nature        *
-- ** related to, arising under or in connection with these          *
-- ** materials, including for any direct, or any indirect,          *
-- ** special, incidental, or consequential loss or damage           *
-- ** (including loss of data, profits, goodwill, or any type of     *
-- ** loss or damage suffered as a result of any action brought      *
-- ** by a third party) even if such damage or loss was              *
-- ** reasonably foreseeable or Xilinx had been advised of the       *
-- ** possibility of the same.                                       *
-- **                                                                *
-- ** CRITICAL APPLICATIONS                                          *
-- ** Xilinx products are not designed or intended to be fail-       *
-- ** safe, or for use in any application requiring fail-safe        *
-- ** performance, such as life-support or safety devices or         *
-- ** systems, Class III medical devices, nuclear facilities,        *
-- ** applications related to the deployment of airbags, or any      *
-- ** other applications that could lead to death, personal          *
-- ** injury, or severe property or environmental damage             *
-- ** (individually and collectively, "Critical                      *
-- ** Applications"). Customer assumes the sole risk and             *
-- ** liability of any use of Xilinx products in Critical            *
-- ** Applications, subject only to applicable laws and              *
-- ** regulations governing limitations on product liability.        *
-- **                                                                *
-- ** THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS       *
-- ** PART OF THIS FILE AT ALL TIMES.                                *
-- *******************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        xip_cntrl_reg.vhd
-- Version:         v3.0
-- Description:     control register module for axi quad spi in XIP mode.
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

use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library lib_pkg_v1_0_2;
    use lib_pkg_v1_0_2.all;
    use lib_pkg_v1_0_2.lib_pkg.RESET_ACTIVE;

--library unisim;
--    use unisim.vcomponents.FDRE;
-------------------------------------------------------------------------------
--                     Definition of Generics
-------------------------------------------------------------------------------

--  C_S_AXI_DATA_WIDTH                --      Width of the slave data bus
--  C_XIP_SPICR_REG_WIDTH                 --      Width of SPI registers

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                  Definition of Ports
-------------------------------------------------------------------------------

-- SYSTEM

--  Bus2IP_Clk                  --      Bus to IP clock
--  Soft_Reset_op               --      Soft_Reset_op Signal

-- SLAVE ATTACHMENT INTERFACE
--  Wr_ce_reduce_ack_gen  --      common write ack generation logic input
--  Bus2IP_XIPCR_data     --      Data written from the PLB bus
--  Bus2IP_XIPCR_WrCE     --      Write CE for control register
--  Bus2IP_XIPCR_RdCE     --      Read CE for control register
--  IP2Bus_XIPCR_Data     --      Data to be send on the bus

-- SPI MODULE INTERFACE
--  Control_Register_Data       --      Data to be send on the bus
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Entity Declaration
-------------------------------------------------------------------------------
entity xip_cntrl_reg is
      generic
      (
      ----------------------------
      C_S_AXI_DATA_WIDTH         : integer;       -- 32 bits
      ----------------------------
      -- Number of bits in register,10 for control reg - 8 for cmd + 2 CPOL/CPHA
      C_XIP_SPICR_REG_WIDTH          : integer;
      ----------------------------
      C_SPI_MODE                 : integer
      ----------------------------
      );
      port
      (
      Bus2IP_Clk                : in  std_logic;
      Soft_Reset_op             : in  std_logic;

      -- Slave attachment ports
      Bus2IP_XIPCR_WrCE         : in  std_logic;
      Bus2IP_XIPCR_RdCE         : in  std_logic;
      Bus2IP_XIPCR_data         : in  std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0);

      ip2Bus_RdAck_core         : in  std_logic;
      ip2Bus_WrAck_core         : in  std_logic;

      XIPCR_1_CPOL              : out std_logic;
      XIPCR_0_CPHA              : out std_logic;
      --------------------------
      IP2Bus_XIPCR_Data         : out std_logic_vector((C_XIP_SPICR_REG_WIDTH-1) downto 0);
      --------------------------
      TO_XIPSR_CPHA_CPOL_ERR    : out std_logic
      );
end xip_cntrl_reg;

-------------------------------------------------------------------------------
-- Architecture
--------------------------------------
architecture imp of xip_cntrl_reg is
-------------------------------------

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

-- Signal Declarations
----------------------
signal XIPCR_data_int                 : std_logic_vector((C_XIP_SPICR_REG_WIDTH-1) downto 0);
         
-----
begin
-----
---------------------------------------
XIPCR_CPHA_CPOL_STORE_P:process(Bus2IP_Clk)is
begin
-----
     if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if(Soft_Reset_op = RESET_ACTIVE) then
             XIPCR_data_int((C_XIP_SPICR_REG_WIDTH-1) downto (C_XIP_SPICR_REG_WIDTH-C_XIP_SPICR_REG_WIDTH)) 
                           <= "00";
         elsif(ip2Bus_WrAck_core = '1') and (Bus2IP_XIPCR_WrCE = '1')then
             XIPCR_data_int((C_XIP_SPICR_REG_WIDTH-1) downto (0)) 
                           <= Bus2IP_XIPCR_data
                           ((C_XIP_SPICR_REG_WIDTH-1) downto (0));
         end if;
     end if;
end process XIPCR_CPHA_CPOL_STORE_P;
------------------------------------

XIPCR_1_CPOL <=	XIPCR_data_int(C_XIP_SPICR_REG_WIDTH-1);
XIPCR_0_CPHA <= XIPCR_data_int(0);
XIPCR_REG_RD_GENERATE: for i in C_XIP_SPICR_REG_WIDTH-1 downto 0 generate
-----
begin
-----
    IP2Bus_XIPCR_Data(i) <= XIPCR_data_int(i) and Bus2IP_XIPCR_RdCE;
end generate XIPCR_REG_RD_GENERATE;
-----------------------------------

TO_XIPSR_CPHA_CPOL_ERR <= (XIPCR_data_int(C_XIP_SPICR_REG_WIDTH-1)) xor 
                          (XIPCR_data_int(C_XIP_SPICR_REG_WIDTH-C_XIP_SPICR_REG_WIDTH));
end imp;
--------------------------------------------------------------------------------
