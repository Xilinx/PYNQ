-------------------------------------------------------------------------------
--  SPI Status Register Module - entity/architecture pair
-------------------------------------------------------------------------------
-- 
-- *******************************************************************
-- ** (c) Copyright [2010] - [2011] Xilinx, Inc. All rights reserved.*
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
-- Filename:        xip_status_reg.vhd
-- Version:         v3.0
-- Description:     Serial Peripheral Interface (SPI) Module for interfacing
--                  with a 32-bit AXI4 Bus. The file defines the logic for 
--                  status register in XIP mode.   
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

library lib_pkg_v1_0_2;
    use lib_pkg_v1_0_2.all;
    use lib_pkg_v1_0_2.lib_pkg.log2;
    use lib_pkg_v1_0_2.lib_pkg.RESET_ACTIVE;

library unisim;
    use unisim.vcomponents.FDRE;
-------------------------------------------------------------------------------
--                     Definition of Generics
-------------------------------------------------------------------------------

-- C_SPI_NUM_BITS_REG              -- Width of SPI registers
-- C_S_AXI_DATA_WIDTH                -- Native data bus width 32 bits only
-- C_NUM_SS_BITS               -- Number of bits in slave select
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                  Definition of Ports
-------------------------------------------------------------------------------

-- SYSTEM
--  Bus2IP_Clk                  --  Bus to IP clock
--  Soft_Reset_op                       --  Soft_Reset_op Signal

-- STATUS REGISTER RELATED SIGNALS
--================================
-- REGISTER/FIFO INTERFACE
-- Bus2IP_SPISR_RdCE      --  Status register Read Chip Enable
-- IP2Bus_SPISR_Data      --  Status register data to PLB based on PLB read

-- SR_3_modf                   --  Mode fault error status flag
-- SR_4_Tx_Full                --  Transmit register full status flag
-- SR_5_Tx_Empty               --  Transmit register empty status flag
-- SR_6_Rx_Full                --  Receive register full status flag
-- SR_7_Rx_Empty               --  Receive register empty stauts flag
-- ModeFault_Strobe            --  Mode fault strobe

-- SLAVE REGISTER RELATED SIGNALS
--===============================
-- Bus2IP_SPISSR_WrCE    -- slave select register write chip enable
-- Bus2IP_SPISSR_RdCE    -- slave select register read chip enable
-- Bus2IP_SPISSR_Data        -- slave register data from PLB Bus
-- IP2Bus_SPISSR_Data        -- Data from slave select register during PLB rd
-- SPISSR_Data_reg_op      -- Data to SPI Module
-- Wr_ce_reduce_ack_gen         -- commaon write ack generation signal
-- Rd_ce_reduce_ack_gen         -- commaon read ack generation signal

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Entity Declaration
-------------------------------------------------------------------------------
entity xip_status_reg is
    generic
    (
        C_S_AXI_DATA_WIDTH      : integer;       -- 32 bits
        ------------------------
        C_XIP_SPISR_REG_WIDTH       : integer
    );
    port
    (
       Bus2IP_Clk               : in  std_logic;
       Soft_Reset_op            : in  std_logic;
       --------------------------
       XIPSR_AXI_TR_ERR         : in std_logic; -- bit 4 of XIPSR
       XIPSR_CPHA_CPOL_ERR      : in std_logic; -- bit 3 of XIPSR
       XIPSR_MST_MODF_ERR       : in std_logic; -- bit 2 of XIPSR
       XIPSR_AXI_RX_FULL        : in std_logic; -- bit 1 of XIPSR
       XIPSR_AXI_RX_EMPTY 	    : in std_logic; -- bit 0 of XIPSR
       --------------------------
       Bus2IP_XIPSR_WrCE        : in std_logic;                             
       Bus2IP_XIPSR_RdCE        : in std_logic;
       --------------------------
       --IP2Bus_XIPSR_RdAck       : out std_logic;
       --IP2Bus_XIPSR_WrAck       : out std_logic;
       IP2Bus_XIPSR_Data        : out std_logic_vector((C_XIP_SPISR_REG_WIDTH-1) downto 0);
       ip2Bus_RdAck             : in std_logic
   );
end xip_status_reg;
-------------------------------------------------------------------------------
-- Architecture
---------------
architecture imp of xip_status_reg is
----------------------------------------------------------

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

-- Signal Declarations
----------------------
signal XIPSR_data_int                 : std_logic_vector(C_XIP_SPISR_REG_WIDTH-1 downto 0);
--signal ip2Bus_RdAck_core_reg          : std_logic;
--signal ip2Bus_RdAck_core_reg_d1       : std_logic;
--signal ip2Bus_WrAck_core_reg          : std_logic;
--signal ip2Bus_WrAck_core_reg_d1       : std_logic;
----------------------
begin
-----
-- XIPSR  - 31 -- -- 5 4                  3         2       1     0    
--          <-- NA --> AXI                CPOL_CPHA MODF    Rx    Rx   
--                     Transaction Error  Error     Error   Full  Empty
-- Default             0                  0	    0       0     0    
-------------------------------------------------------------------------------
--XIPSR_CMD_ERR <= '0';
---------------------------------------
XIPSR_DATA_STORE_P:process(Bus2IP_Clk)is
begin
-----
     if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if(Soft_Reset_op = RESET_ACTIVE) then
             XIPSR_data_int((C_XIP_SPISR_REG_WIDTH-1) downto 0)<= (others => '0');
	 elsif(ip2Bus_RdAck = '1') then
             XIPSR_data_int((C_XIP_SPISR_REG_WIDTH-1) downto 0)<= (others => '0');
         else
             XIPSR_data_int((C_XIP_SPISR_REG_WIDTH-1) downto 0) 
	                   <= XIPSR_AXI_TR_ERR     & -- bit 4
			              XIPSR_CPHA_CPOL_ERR  & 
			              XIPSR_MST_MODF_ERR   &
			              XIPSR_AXI_RX_FULL    &
			              XIPSR_AXI_RX_EMPTY   ; -- bit 0
         end if;
     end if;
end process XIPSR_DATA_STORE_P;
--------------------------------------------------
XIPSR_REG_RD_GENERATE: for i in C_XIP_SPISR_REG_WIDTH-1 downto 0 generate
-----
begin
-----
    IP2Bus_XIPSR_Data(i) <= XIPSR_data_int(i) and Bus2IP_XIPSR_RdCE ; --and ip2Bus_RdAck_core_reg;
end generate XIPSR_REG_RD_GENERATE;
-----------------------------------
---------------------------------------------------------------------------------
end imp;
--------------------------------------------------------------------------------
