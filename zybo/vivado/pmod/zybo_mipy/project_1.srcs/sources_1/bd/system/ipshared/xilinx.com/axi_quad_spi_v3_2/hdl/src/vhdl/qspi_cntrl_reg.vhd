-------------------------------------------------------------------------------
-- qspi_cntrl_reg.vhd - Entity and architecture
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
-- Filename:        qspi_cntrl_reg.vhd
-- Version:         v3.0
-- Description:     control register module for axi quad spi. This module decides the
--                  behavior of the core in master/slave, CPOL/CPHA etc modes.
--
-------------------------------------------------------------------------------
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
    use ieee.std_logic_misc.all;

library lib_pkg_v1_0_2;
    use lib_pkg_v1_0_2.all;
    use lib_pkg_v1_0_2.lib_pkg.RESET_ACTIVE;

library unisim;
    use unisim.vcomponents.FDRE;
-------------------------------------------------------------------------------
--                     Definition of Generics
-------------------------------------------------------------------------------

--  C_S_AXI_DATA_WIDTH                --      Width of the slave data bus
--  C_SPI_NUM_BITS_REG              --      Width of SPI registers

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                  Definition of Ports
-------------------------------------------------------------------------------

-- SYSTEM

--  Bus2IP_Clk                  --      Bus to IP clock
--  Soft_Reset_op               --      Soft_Reset_op Signal

-- SLAVE ATTACHMENT INTERFACE
--  Wr_ce_reduce_ack_gen  --      common write ack generation logic input
--  Bus2IP_SPICR_data     --      Data written from the PLB bus
--  Bus2IP_SPICR_WrCE     --      Write CE for control register
--  Bus2IP_SPICR_RdCE     --      Read CE for control register
--  IP2Bus_SPICR_Data     --      Data to be send on the bus

-- SPI MODULE INTERFACE
--  Control_Register_Data       --      Data to be send on the bus
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Entity Declaration
-------------------------------------------------------------------------------
entity qspi_cntrl_reg is
      generic
      (
      ----------------------------
      C_S_AXI_DATA_WIDTH         : integer;       -- 32 bits
      ----------------------------
      -- Number of bits in register, 10 for control reg - to match old version
      C_SPI_NUM_BITS_REG         : integer;
      ----------------------------
      C_SPICR_REG_WIDTH          : integer;
      ----------------------------
      C_SPI_MODE                 : integer
      ----------------------------
      );
      port
      (
      Bus2IP_Clk                : in  std_logic;
      Soft_Reset_op             : in  std_logic;

      -- Slave attachment ports
      Wr_ce_reduce_ack_gen      : in  std_logic;
      Bus2IP_SPICR_WrCE         : in  std_logic;
      Bus2IP_SPICR_RdCE         : in  std_logic;
      Bus2IP_SPICR_data         : in  std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));

      -- SPI module ports
      SPICR_0_LOOP              : out std_logic;
      SPICR_1_SPE               : out std_logic;
      SPICR_2_MASTER_N_SLV      : out std_logic;
      SPICR_3_CPOL              : out std_logic;
      SPICR_4_CPHA              : out std_logic;
      SPICR_5_TXFIFO_RST        : out std_logic;
      SPICR_6_RXFIFO_RST        : out std_logic;
      SPICR_7_SS                : out std_logic;
      SPICR_8_TR_INHIBIT        : out std_logic;
      SPICR_9_LSB               : out std_logic;

      --------------------------
      -- to Status Register
      SPISR_1_LOOP_Back_Error   : out std_logic;
      SPISR_2_MSB_Error         : out std_logic;
      SPISR_3_Slave_Mode_Error  : out std_logic;

      -- SPISR_4_XIP_Mode_On       : out std_logic;
      SPISR_4_CPOL_CPHA_Error   : out std_logic;

      IP2Bus_SPICR_Data         : out std_logic_vector(0 to (C_SPICR_REG_WIDTH-1));

      Control_bit_7_8           : out std_logic_vector(0 to 1) --(7 to 8)
      );
end qspi_cntrl_reg;

-------------------------------------------------------------------------------
-- Architecture
--------------------------------------
architecture imp of qspi_cntrl_reg is
-------------------------------------

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

-- Signal Declarations
----------------------
signal SPICR_data_int            : std_logic_vector(0 to (C_SPICR_REG_WIDTH-1));
signal SPICR_3_4_Reset          : std_logic;
signal Control_bit_7_8_int      : std_logic_vector(7 to 8);

signal temp_wr_ce : std_logic;
-----
begin
-----
----------------------------
--  Combinatorial operations
----------------------------
-- Control_Register_Data   <= SPICR_data_int;

-------------------------------------------------------
SPICR_0_LOOP            <= SPICR_data_int(C_SPICR_REG_WIDTH-1); -- as per the SPICR Fig 3 in DS this bit is @ 0th position
SPICR_1_SPE             <= SPICR_data_int(C_SPICR_REG_WIDTH-2); -- as per the SPICR Fig 3 in DS this bit is @ 1st position
SPICR_2_MASTER_N_SLV    <= SPICR_data_int(C_SPICR_REG_WIDTH-3); -- as per the SPICR Fig 3 in DS this bit is @ 2nd position
SPICR_3_CPOL            <= SPICR_data_int(C_SPICR_REG_WIDTH-4); -- as per the SPICR Fig 3 in DS this bit is @ 3rd position
SPICR_4_CPHA            <= SPICR_data_int(C_SPICR_REG_WIDTH-5); -- as per the SPICR Fig 3 in DS this bit is @ 4th position
SPICR_5_TXFIFO_RST      <= SPICR_data_int(C_SPICR_REG_WIDTH-6); -- as per the SPICR Fig 3 in DS this bit is @ 5th position
SPICR_6_RXFIFO_RST      <= SPICR_data_int(C_SPICR_REG_WIDTH-7); -- as per the SPICR Fig 3 in DS this bit is @ 6th position
SPICR_7_SS              <= SPICR_data_int(C_SPICR_REG_WIDTH-8); -- as per the SPICR Fig 3 in DS this bit is @ 7th position
SPICR_8_TR_INHIBIT      <= SPICR_data_int(C_SPICR_REG_WIDTH-9); -- as per the SPICR Fig 3 in DS this bit is @ 8th position
SPICR_9_LSB             <= SPICR_data_int(C_SPICR_REG_WIDTH-10);-- as per the SPICR Fig 3 in DS this bit is @ 9th position
-------------------------------------------------------


SPISR_DUAL_MODE_STATUS_GEN : if C_SPI_MODE = 1 or C_SPI_MODE = 2 generate
----------------------------
--signal ored_SPICR_7_12 : std_logic;
begin
-----
        --ored_SPICR_7_12 <= or_reduce(SPICR_data_int(7 to 12));

        -- C_SPICR_REG_WIDTH is of 10 bit wide
        SPISR_1_LOOP_Back_Error  <= SPICR_data_int(C_SPICR_REG_WIDTH-1);-- 9th bit in present SPICR

        SPISR_2_MSB_Error        <= SPICR_data_int(C_SPICR_REG_WIDTH-C_SPICR_REG_WIDTH);    -- 0th LSB bit in present SPICR

        SPISR_3_Slave_Mode_Error <= not SPICR_data_int(C_SPICR_REG_WIDTH-3); -- Mst_n_Slv 7th bit in control register - default is slave mode of operation

        SPISR_4_CPOL_CPHA_Error  <= SPICR_data_int(C_SPICR_REG_WIDTH-5) xor  -- bit 5-CPHA and 6-CPOL in present SPICR
                                    SPICR_data_int(C_SPICR_REG_WIDTH-4);-- CPOL-CPHA = 01 or 10 in control register

end generate SPISR_DUAL_MODE_STATUS_GEN;
----------------------------------------

SPISR_NO_DUAL_MODE_STATUS_GEN : if C_SPI_MODE = 0 generate
-------------------------------
begin
-----
        SPISR_1_LOOP_Back_Error  <= '0';
        SPISR_2_MSB_Error        <= '0';
        SPISR_3_Slave_Mode_Error <= '0';
        SPISR_4_CPOL_CPHA_Error  <= '0';

end generate SPISR_NO_DUAL_MODE_STATUS_GEN;
-------------------------------------------

    SPICR_REG_RD_GENERATE: for i in 0 to C_SPICR_REG_WIDTH-1 generate
    -----
    begin
    -----
        IP2Bus_SPICR_Data(i) <= SPICR_data_int(i) and Bus2IP_SPICR_RdCE;
    end generate SPICR_REG_RD_GENERATE;
    -----------------------------------

---------------------------------------------------------------
-- Bus2IP Data bit mapping - 0 to 21 - NA
-- 22    23    24    25    26      27   28   29     30  31
--
-- Control Register - 0 to 22 bit mapping
-- 0     1     2     3     4       5    6    7      8   9
-- LSB TRAN MANUAL RX FIFO TX FIFO CPHA CPOL MASTER SPE LOOP
--     INHI SLAVE  RST     RST
-- '0' '1'  '1'    '0'     '0'     '0'  '0'  '0'    '0' '0'
-----------------------------------------------------
-- AXI Data    31 downto 0                          |
-- valid bits in AXI start from LSB i.e. 0          |
-- Bus2IP_Data 0  to     31                         |
-- **** IMP Starts ****                             |
-- This is 1 is to 1 mapping with reverse bit order.|
-- **** IMP Ends   ****                             |
-- Bus2IP_Data 0 1 2 3 4 5 6 7  21 22--->31         |
-- Control Bits<-------NA--------> 0---->9          |
-----------------------------------------------------
--SPICR_NO_DUAL_MODE_WR_GEN: if C_SPI_MODE = 0 generate
---------------------------------
--begin
-----
--    SPICR_data_int(0 to 12) <= (others => '0');

--end generate SPICR_NO_DUAL_MODE_WR_GEN;
----------------------------------------------

    temp_wr_ce <= wr_ce_reduce_ack_gen and Bus2IP_SPICR_WrCE;

    -- --  SPICR_REG_0_PROCESS : Control Register Write Operation for bit 0 - LSB
    -- -----------------------------
    -- Behavioral Code **
    SPICR_REG_0_PROCESS:process(Bus2IP_Clk)
    -----
    begin
    -----
        if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
            if (Soft_Reset_op = RESET_ACTIVE) then
                SPICR_data_int(0) <= '0';
            elsif ((wr_ce_reduce_ack_gen  and Bus2IP_SPICR_WrCE)='1') then
                SPICR_data_int(0) <=
                        Bus2IP_SPICR_data(C_S_AXI_DATA_WIDTH-C_SPICR_REG_WIDTH);-- after 100 ps;
            end if;
        end if;
    end process SPICR_REG_0_PROCESS;
    --------------------------------

    CONTROL_REG_1_2_GENERATE: for i in 1 to 2 generate
    ------------------------
    begin
    -----
    -- SPICR_REG_1_2_PROCESS : Control Register Write Operation for bit 1_2 - TRAN_INHI and MANUAL_SLAVE
    -----------------------------
        SPICR_REG_1_2_PROCESS:process(Bus2IP_Clk)
        -----
        begin
        -----
            if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
                if (Soft_Reset_op = RESET_ACTIVE) then
                    SPICR_data_int(i) <= '1';
                elsif((wr_ce_reduce_ack_gen  and Bus2IP_SPICR_WrCE)='1') then
                    SPICR_data_int(i) <=
                      Bus2IP_SPICR_data(C_S_AXI_DATA_WIDTH-C_SPICR_REG_WIDTH+i);-- after 100 ps;
                end if;
            end if;
        end process SPICR_REG_1_2_PROCESS;
        ----------------------------------
    end generate CONTROL_REG_1_2_GENERATE;
    --------------------------------------

    -- the below reset signal is needed to de-assert the Tx/Rx FIFO reset signals.
    SPICR_3_4_Reset <= (not Bus2IP_SPICR_WrCE) or Soft_Reset_op;

    -- CONTROL_REG_3_4_GENERATE : Control Register Write Operation for bit 3_4 - Receive FIFO Reset and Transmit FIFO Reset
    -----------------------------
    CONTROL_REG_3_4_GENERATE: for i in 3 to 4 generate
    -----
    begin
    -----
        SPICR_REG_3_4_PROCESS:process(Bus2IP_Clk)
        -----
        begin
        -----
            if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
                if (SPICR_3_4_Reset = RESET_ACTIVE) then
                    SPICR_data_int(i) <= '0';
                elsif ((wr_ce_reduce_ack_gen  and Bus2IP_SPICR_WrCE)='1') then
                    SPICR_data_int(i) <=
                          Bus2IP_SPICR_data(C_S_AXI_DATA_WIDTH-C_SPICR_REG_WIDTH+i);-- after 100 ps;
                end if;
            end if;
        end process SPICR_REG_3_4_PROCESS;
        ----------------------------------
    end generate CONTROL_REG_3_4_GENERATE;
    --------------------------------------

    -- CONTROL_REG_5_9_GENERATE : Control Register Write Operation for bit 5:9 - CPHA, CPOL, MASTER, SPE, LOOP
    -----------------------------
    CONTROL_REG_5_9_GENERATE: for i in 5 to C_SPICR_REG_WIDTH-1 generate
    -----
    begin
    -----
        SPICR_REG_5_9_PROCESS:process(Bus2IP_Clk)
        -----
        begin
        -----
            if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
                if (Soft_Reset_op = RESET_ACTIVE) then
                    SPICR_data_int(i) <= '0';
                elsif ((wr_ce_reduce_ack_gen  and Bus2IP_SPICR_WrCE)='1') then
                    SPICR_data_int(i) <=
                          Bus2IP_SPICR_data(C_S_AXI_DATA_WIDTH-C_SPICR_REG_WIDTH+i);-- after 100 ps;
                end if;
            end if;
        end process SPICR_REG_5_9_PROCESS;
        ----------------------------------
    end generate CONTROL_REG_5_9_GENERATE;
    --------------------------------------

--
     -- SPICR_REG_78_GENERATE: This logic is newly added to register _T signals
     -- ------------------------ in IOB. This logic simplifies the register method
     --                          for _T in IOB, without affecting functionality.

     SPICR_REG_78_GENERATE: for i in 7 to 8 generate
     -----
     begin
     -----
     SPI_TRISTATE_CONTROL_I: component FDRE
             port map
             (
             Q  => Control_bit_7_8_int(i)    ,-- out:
             C  => Bus2IP_Clk                ,--: in
             CE => Bus2IP_SPICR_WrCE         ,--: in
             R  => Soft_Reset_op             ,-- : in
             D  => Bus2IP_SPICR_data(C_S_AXI_DATA_WIDTH-C_SPICR_REG_WIDTH+i)    --: in
             );
     end generate SPICR_REG_78_GENERATE;
     -----------------------------------

Control_bit_7_8 <= Control_bit_7_8_int;
---------------------------------------

end imp;
--------------------------------------------------------------------------------
