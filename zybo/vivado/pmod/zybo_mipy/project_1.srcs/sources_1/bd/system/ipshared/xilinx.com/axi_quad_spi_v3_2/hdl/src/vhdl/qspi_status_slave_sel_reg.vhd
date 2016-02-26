-------------------------------------------------------------------------------
--  SPI Status Register Module - entity/architecture pair
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
-- Filename:        spi_status_reg.vhd
-- Version:         v3.0
-- Description:     Serial Peripheral Interface (SPI) Module for interfacing
--                  with a 32-bit AXI4 Bus. The file defines the logic for
--                  status and slave select register.
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
entity qspi_status_slave_sel_reg is
    generic
    (
        C_SPI_NUM_BITS_REG      : integer;    -- Number of bits in SR
        ------------------------
        C_S_AXI_DATA_WIDTH      : integer;       -- 32 bits
        ------------------------
        C_NUM_SS_BITS           : integer;    -- Number of bits in slave select
        ------------------------
        C_SPISR_REG_WIDTH       : integer
    );
    port
    (
       Bus2IP_Clk               : in  std_logic;
       Soft_Reset_op            : in  std_logic;
       -- I/P from control register

       SPISR_0_Command_Error      : in std_logic;       -- bit0 of SPISR
       SPISR_1_LOOP_Back_Error    : in std_logic;       -- bit1 of SPISR
       SPISR_2_MSB_Error          : in std_logic;
       SPISR_3_Slave_Mode_Error   : in std_logic;
       SPISR_4_CPOL_CPHA_Error    : in std_logic;       -- bit 4 of SPISR
       -- I/P from other modules
       SPISR_Ext_SPISEL_slave   : in std_logic; -- bit 5 of SPISR
       SPISR_7_Tx_Full          : in std_logic; -- bit 7 of SPISR
       SPISR_8_Tx_Empty         : in std_logic;
       SPISR_9_Rx_Full          : in std_logic;
       SPISR_10_Rx_Empty        : in std_logic; -- bit 10 of SPISR

       -- Slave attachment ports
       ModeFault_Strobe         : in  std_logic;
       Rd_ce_reduce_ack_gen     : in std_logic;
       Bus2IP_SPISR_RdCE        : in  std_logic;

       IP2Bus_SPISR_Data        : out std_logic_vector(0 to (C_SPISR_REG_WIDTH-1));
       SR_3_modf                : out std_logic;
       -- Reg/FIFO ports

       -- SPI module ports
       -----------------------------------
       -- Slave Select Register ports
       Bus2IP_SPISSR_WrCE   : in std_logic;
       Wr_ce_reduce_ack_gen : in std_logic;

       Bus2IP_SPISSR_RdCE   : in std_logic;
       Bus2IP_SPISSR_Data   : in std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));
       IP2Bus_SPISSR_Data   : out std_logic_vector(0 to (C_NUM_SS_BITS-1));
       -- SPI module ports
       SPISSR_Data_reg_op   : out std_logic_vector(0 to (C_NUM_SS_BITS-1))
   );
end qspi_status_slave_sel_reg;
-------------------------------------------------------------------------------
-- Architecture
---------------
architecture imp of qspi_status_slave_sel_reg is
----------------------------------------------------------

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

-- Signal Declarations
----------------------
signal SPISR_reg                : std_logic_vector(0 to (C_SPISR_REG_WIDTH-1));
signal modf                     : std_logic;
signal modf_Reset               : std_logic;
----------------------
signal SPISSR_Data_reg          : std_logic_vector(0 to (C_NUM_SS_BITS-1));
signal spissr_reg_en            : std_logic;

constant RESET_ACTIVE       : std_logic         := '1'; 

----------------------
begin
-----
-- SPISR  - 0       1       2     3        4         5          6    7       8        9       10
--          Command Loop BK MSB   Slv Mode CPOL_CPHA Slave Mode MODF Tx_Full Tx_Empty Rx_Full Rx_Empty
--          Error   Error   Error Error    Error     Select
-- Default  0       0       0     1        0         1          0    0       1        0       1
-------------------------------------------------------------------------------
--  Combinatorial operations
-------------------------------------------------------------------------------
 SPISR_reg(C_SPISR_REG_WIDTH - 11) <= SPISR_0_Command_Error;     -- SPISR bit 0 @ C_SPISR_REG_WIDTH = 11
 SPISR_reg(C_SPISR_REG_WIDTH - 10) <= SPISR_1_LOOP_Back_Error;   -- SPISR bit 1
 SPISR_reg(C_SPISR_REG_WIDTH - 9)  <= SPISR_2_MSB_Error;         -- SPISR bit 2
 SPISR_reg(C_SPISR_REG_WIDTH - 8)  <= SPISR_3_Slave_Mode_Error;  -- SPISR bit 3
 SPISR_reg(C_SPISR_REG_WIDTH - 7)  <= SPISR_4_CPOL_CPHA_Error;   -- SPISR bit 4
 SPISR_reg(C_SPISR_REG_WIDTH - 6)  <= SPISR_Ext_SPISEL_slave;    -- SPISR bit 5
 SPISR_reg(C_SPISR_REG_WIDTH - 5)  <= modf;                      -- SPISR bit 6
 SPISR_reg(C_SPISR_REG_WIDTH - 4)  <= SPISR_7_Tx_Full;           -- SPISR bit 7
 SPISR_reg(C_SPISR_REG_WIDTH - 3)  <= SPISR_8_Tx_Empty;          -- SPISR bit 8
 SPISR_reg(C_SPISR_REG_WIDTH - 2)  <= SPISR_9_Rx_Full;           -- SPISR bit 9
 SPISR_reg(C_SPISR_REG_WIDTH - 1)  <= SPISR_10_Rx_Empty;         -- SPISR bit 10

 SR_3_modf                   <= modf;
-------------------------------------------------------------------------------
--  STATUS_REG_RD_GENERATE : Status Register Read Generate
----------------------------
STATUS_REG_RD_GENERATE: for i in 0 to C_SPISR_REG_WIDTH-1 generate
-----
begin
-----

    IP2Bus_SPISR_Data(i) <= SPISR_reg(i) and Bus2IP_SPISR_RdCE;

end generate STATUS_REG_RD_GENERATE;
-------------------------------------------------------------------------------
-- MODF_REG_PROCESS : Set and Clear modf
------------------------
MODF_REG_PROCESS:process(Bus2IP_Clk) is
-----
begin
-----
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if (modf_Reset = RESET_ACTIVE) then
            modf <= '0';
        elsif (ModeFault_Strobe = '1') then
            modf <= '1';
        end if;
    end if;
end process MODF_REG_PROCESS;

modf_Reset <= (Rd_ce_reduce_ack_gen and Bus2IP_SPISR_RdCE) or Soft_Reset_op;

--******************************************************************************
-- logic for Slave Select Register

-- Combinatorial operations
----------------------------
SPISSR_Data_reg_op   <= SPISSR_Data_reg;

-------------------------------------------------------------------------------
--  SPISSR_WR_GEN : Slave Select Register Write Operation
----------------------------
SPISSR_WR_GEN: for i in 0 to C_NUM_SS_BITS-1 generate
-----
begin
-----
    spissr_reg_en <= Wr_ce_reduce_ack_gen and Bus2IP_SPISSR_WrCE;

    SPISSR_WR_PROCESS:process(Bus2IP_Clk) is
    -----
    begin
    -----
        if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
            if (Soft_Reset_op = RESET_ACTIVE) then
                SPISSR_Data_reg(i) <= '1';
        elsif ((Wr_ce_reduce_ack_gen and Bus2IP_SPISSR_WrCE) = '1') then
                SPISSR_Data_reg(i) <=
                        Bus2IP_SPISSR_Data(C_S_AXI_DATA_WIDTH-C_NUM_SS_BITS+i);
            end if;
        end if;
    end process SPISSR_WR_PROCESS;
        --SPISSR_WR_PROCESS_I: component FDRE
        --    generic map(
        --           INIT => '1'
        --    )
        --    port map
        --    (
        --    Q  => SPISSR_Data_reg(i)    ,-- out:
        --    C  => Bus2IP_Clk                ,--: in
        --    CE => spissr_reg_en             ,--: in
        --    R  => Soft_Reset_op             ,-- : in
        --    D  => Bus2IP_SPISSR_Data(C_S_AXI_DATA_WIDTH-C_NUM_SS_BITS+i)    --: in
        --    );
    ---------------------------------
-----
end generate SPISSR_WR_GEN;

-------------------------------------------------------------------------------
--  SLAVE_SEL_REG_RD_GENERATE : Slave Select Register Read Generate
-------------------------------
SLAVE_SEL_REG_RD_GENERATE: for i in 0 to C_NUM_SS_BITS-1 generate
-----
begin
-----
    IP2Bus_SPISSR_Data(i) <= SPISSR_Data_reg(i) and
                             Bus2IP_SPISSR_RdCE;
end generate SLAVE_SEL_REG_RD_GENERATE;
---------------------------------------

end imp;
--------------------------------------------------------------------------------
