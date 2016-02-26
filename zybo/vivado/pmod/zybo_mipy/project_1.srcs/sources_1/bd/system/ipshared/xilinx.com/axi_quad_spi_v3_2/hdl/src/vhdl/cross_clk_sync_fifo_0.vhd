-------------------------------------------------------------------------------
-- cross_clk_sync_fifo_0.vhd - Entity and architecture
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
-- Filename:        cross_clk_sync_fifo_0.vhd
-- Version:         v3.1
-- Description:     This is the CDC logic when FIFO = 0.
--
-- VHDL-Standard:   VHDL'93
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
-------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_arith.conv_std_logic_vector;
    use ieee.std_logic_arith.all;
    use ieee.std_logic_signed.all;
    use ieee.std_logic_misc.all;
-- library unsigned is used for overloading of "=" which allows integer to
-- be compared to std_logic_vector
    use ieee.std_logic_unsigned.all;


library axi_lite_ipif_v3_0_3;
use axi_lite_ipif_v3_0_3.axi_lite_ipif;
use axi_lite_ipif_v3_0_3.ipif_pkg.all;
library lib_cdc_v1_0_2;
	use lib_cdc_v1_0_2.cdc_sync;

library axi_quad_spi_v3_2_5;
    use axi_quad_spi_v3_2_5.all;
library unisim;
    use unisim.vcomponents.FDRE;
    use unisim.vcomponents.FDR;
-------------------------------------------------------------------------------
entity cross_clk_sync_fifo_0 is
     generic (
                 C_NUM_TRANSFER_BITS : integer;
             Async_Clk             : integer;
             C_NUM_SS_BITS                : integer--;
             --C_AXI_SPI_CLK_EQ_DIFF             : integer
              );
     port (
              EXT_SPI_CLK               : in std_logic;
              Bus2IP_Clk                : in std_logic;
              Soft_Reset_op             : in std_logic;
              Rst_from_axi_cdc_to_spi       : in std_logic;
              ----------------------------
              tx_empty_signal_handshake_req     : in std_logic;
              tx_empty_signal_handshake_gnt     : out std_logic;
              Tx_FIFO_Empty_cdc_from_axi     : in std_logic;
              Tx_FIFO_Empty_cdc_to_spi      : out std_logic;
              ----------------------------------------------------------
              Tx_FIFO_Empty_SPISR_cdc_from_spi : in std_logic;
              Tx_FIFO_Empty_SPISR_cdc_to_axi  : out std_logic;
              ----------------------------------------------------------
              spisel_d1_reg_cdc_from_spi     : in std_logic; -- = spisel_pulse_cdc_from_spi_clk  , -- in
              spisel_d1_reg_cdc_to_axi      : out std_logic; -- = spisel_pulse_cdc_to_axi_clk   , -- out
              --------------------------:-------------------------------
              spisel_pulse_cdc_from_spi      : in std_logic; -- = spisel_pulse_cdc_from_spi_clk  , -- in
              spisel_pulse_cdc_to_axi       : out std_logic; -- = spisel_pulse_cdc_to_axi_clk   , -- out
              --------------------------:-------------------------------
              spiXfer_done_cdc_from_spi      : in std_logic; -- = spiXfer_done_cdc_from_spi_clk, -- in
              spiXfer_done_cdc_to_axi       : out std_logic; -- = spiXfer_done_cdc_to_axi_clk , -- out
              --------------------------:-------------------------------
              modf_strobe_cdc_from_spi       : in std_logic; -- = modf_strobe_cdc_from_spi_clk, -- in
              modf_strobe_cdc_to_axi        : out std_logic; -- = modf_strobe_cdc_to_axi_clk , -- out
              --------------------------:-------------------------------
              Slave_MODF_strobe_cdc_from_spi : in std_logic; -- = slave_MODF_strobe_cdc_from_spi_clk,-- in
              Slave_MODF_strobe_cdc_to_axi  : out std_logic; -- = slave_MODF_strobe_cdc_to_axi_clk      ,-- out
              --------------------------:-------------------------------
              receive_Data_cdc_from_spi      : in std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1)); -- = receive_Data_cdc_from_spi_clk, -- in
              receive_Data_cdc_to_axi       : out std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1)); -- = receive_data_cdc_to_axi_clk, -- out
              --------------------------:-------------------------------
              drr_Overrun_int_cdc_from_spi   : in std_logic;
              drr_Overrun_int_cdc_to_axi    : out std_logic;
              --------------------------:-------------------------------
              dtr_underrun_cdc_from_spi      : in std_logic; -- = dtr_underrun_cdc_from_spi_clk, -- in
              dtr_underrun_cdc_to_axi       : out std_logic; -- = dtr_underrun_cdc_to_axi_clk,  -- out
              --------------------------:-------------------------------
              transmit_Data_cdc_from_axi     : in std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1)); -- = transmit_Data_cdc_from_axi_clk, -- in
              transmit_Data_cdc_to_spi      : out std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1)); -- = transmit_Data_cdc_to_spi_clk   -- out
              ----------------------------
              SPICR_0_LOOP_cdc_from_axi      : in std_logic;
              SPICR_0_LOOP_cdc_to_spi       : out std_logic;
              ----------------------------
              SPICR_1_SPE_cdc_from_axi       : in std_logic;
              SPICR_1_SPE_cdc_to_spi        : out std_logic;
              ----------------------------
              SPICR_2_MST_N_SLV_cdc_from_axi : in std_logic;
              SPICR_2_MST_N_SLV_cdc_to_spi  : out std_logic;
              ----------------------------
              SPICR_3_CPOL_cdc_from_axi      : in std_logic;
              SPICR_3_CPOL_cdc_to_spi       : out std_logic;
              ----------------------------
              SPICR_4_CPHA_cdc_from_axi      : in std_logic;
              SPICR_4_CPHA_cdc_to_spi       : out std_logic;
              ----------------------------
              SPICR_5_TXFIFO_cdc_from_axi    : in std_logic;
              SPICR_5_TXFIFO_cdc_to_spi     : out std_logic;
              ----------------------------
              SPICR_6_RXFIFO_RST_cdc_from_axi: in std_logic;
              SPICR_6_RXFIFO_RST_cdc_to_spi : out std_logic;
              ----------------------------
              SPICR_7_SS_cdc_from_axi        : in std_logic;
              SPICR_7_SS_cdc_to_spi         : out std_logic;
              ----------------------------
              SPICR_8_TR_INHIBIT_cdc_from_axi: in std_logic;
              SPICR_8_TR_INHIBIT_cdc_to_spi : out std_logic;
              ----------------------------
              SPICR_9_LSB_cdc_from_axi       : in std_logic;
              SPICR_9_LSB_cdc_to_spi        : out std_logic;
              ----------------------------
              SPICR_bits_7_8_cdc_from_axi    : in std_logic_vector(1 downto 0); -- in std_logic_vector
              SPICR_bits_7_8_cdc_to_spi     : out std_logic_vector(1 downto 0);
              ----------------------------
              SR_3_modf_cdc_from_axi         : in std_logic;
              SR_3_modf_cdc_to_spi          : out std_logic;
              ----------------------------
              SPISSR_cdc_from_axi            : in std_logic_vector(0 to (C_NUM_SS_BITS-1));
              SPISSR_cdc_to_spi             : out std_logic_vector(0 to (C_NUM_SS_BITS-1))
              ----------------------------
     );
end entity cross_clk_sync_fifo_0;

architecture imp of cross_clk_sync_fifo_0 is
--------------------------------------------
----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------


-- signal declaration
signal spisel_d1_reg_cdc_from_spi_d1      : std_logic;
signal spisel_d1_reg_cdc_from_spi_d2      : std_logic;
signal spiXfer_done_cdc_from_spi_d1       : std_logic;
signal spiXfer_done_cdc_from_spi_d2       : std_logic;
signal modf_strobe_cdc_from_spi_d1        : std_logic;
signal modf_strobe_cdc_from_spi_d2        : std_logic;
signal modf_strobe_cdc_from_spi_d3        : std_logic;
signal Slave_MODF_strobe_cdc_from_spi_d1  : std_logic;
signal Slave_MODF_strobe_cdc_from_spi_d2  : std_logic;
signal Slave_MODF_strobe_cdc_from_spi_d3  : std_logic;
signal receive_Data_cdc_from_spi_d1       : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
signal receive_Data_cdc_from_spi_d2       : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
signal dtr_underrun_cdc_from_spi_d1       : std_logic;
signal dtr_underrun_cdc_from_spi_d2       : std_logic;
signal transmit_Data_cdc_from_axi_d1      : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
signal transmit_Data_cdc_from_axi_d2      : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));

signal spisel_pulse_cdc_from_spi_d1       : std_logic;
signal spisel_pulse_cdc_from_spi_d2       : std_logic;
signal spisel_pulse_cdc_from_spi_d3       : std_logic;

signal SPICR_0_LOOP_cdc_from_axi_d1       : std_logic;
signal SPICR_0_LOOP_cdc_from_axi_d2       : std_logic;

signal SPICR_1_SPE_cdc_from_axi_d1        : std_logic;
signal SPICR_1_SPE_cdc_from_axi_d2        : std_logic;

signal SPICR_2_MST_N_SLV_cdc_from_axi_d1  : std_logic;
signal SPICR_2_MST_N_SLV_cdc_from_axi_d2  : std_logic;

signal SPICR_3_CPOL_cdc_from_axi_d1       : std_logic;
signal SPICR_3_CPOL_cdc_from_axi_d2       : std_logic;

signal SPICR_4_CPHA_cdc_from_axi_d1       : std_logic;
signal SPICR_4_CPHA_cdc_from_axi_d2       : std_logic;

signal SPICR_5_TXFIFO_cdc_from_axi_d1     : std_logic;
signal SPICR_5_TXFIFO_cdc_from_axi_d2     : std_logic;

signal SPICR_7_SS_cdc_from_axi_d1         : std_logic;
signal SPICR_7_SS_cdc_from_axi_d2         : std_logic;

signal SPICR_8_TR_INHIBIT_cdc_from_axi_d1 : std_logic;
signal SPICR_8_TR_INHIBIT_cdc_from_axi_d2 : std_logic;

signal SPICR_9_LSB_cdc_from_axi_d1        : std_logic;
signal SPICR_9_LSB_cdc_from_axi_d2        : std_logic;

signal SPICR_bits_7_8_cdc_from_axi_d1     : std_logic_vector(1 downto 0);
signal SPICR_bits_7_8_cdc_from_axi_d2     : std_logic_vector(1 downto 0);

signal SPICR_6_RXFIFO_RST_cdc_from_axi_d1 : std_logic;
signal SPICR_6_RXFIFO_RST_cdc_from_axi_d2 : std_logic;

signal Tx_FIFO_Empty_cdc_from_axi_d1      : std_logic;
signal Tx_FIFO_Empty_cdc_from_axi_d2      : std_logic;
signal Tx_FIFO_Empty_SPISR_cdc_from_spi_d1 : std_logic;
signal Tx_FIFO_Empty_SPISR_cdc_from_spi_d2 : std_logic;

signal drr_Overrun_int_cdc_from_spi_d1 : std_logic;
signal drr_Overrun_int_cdc_from_spi_d2 : std_logic;
signal drr_Overrun_int_cdc_from_spi_d3 : std_logic;
signal drr_Overrun_int_cdc_from_spi_d4 : std_logic;

signal SR_3_modf_cdc_from_axi_d1          : std_logic;
signal SR_3_modf_cdc_from_axi_d2          : std_logic;
signal SPISSR_cdc_from_axi_d1             : std_logic_vector(0 to (C_NUM_SS_BITS-1));
signal SPISSR_cdc_from_axi_d2             : std_logic_vector(0 to (C_NUM_SS_BITS-1));
     signal spiXfer_done_cdc_from_spi_int_2 : std_logic;
     signal spiXfer_done_d1            : std_logic;
     signal spiXfer_done_d2, spiXfer_done_d3           : std_logic;
     signal spisel_pulse_cdc_from_spi_int_2 : std_logic;
     signal Tx_FIFO_Empty_cdc_from_axi_int_2 : std_logic;
     signal Tx_FIFO_Empty_cdc_from_axi_d3 : std_logic;
     signal drr_Overrun_int_cdc_from_spi_int_2 : std_logic;
     signal Slave_MODF_strobe_cdc_from_spi_int_2 : std_logic;
    signal modf_strobe_cdc_from_spi_int_2 : std_logic;


    signal Tx_FIFO_Empty_cdc_to_spi_i : std_logic;
-- signal declaration
-- signal spisel_d1_reg_cdc_from_spi_d1      : std_logic;
-- signal spisel_d1_reg_cdc_from_spi_d2      : std_logic;
-- signal spiXfer_done_cdc_from_spi_d1       : std_logic;
-- signal spiXfer_done_cdc_from_spi_d2       : std_logic;
-- signal modf_strobe_cdc_from_spi_d1        : std_logic;
-- signal modf_strobe_cdc_from_spi_d2        : std_logic;
-- signal modf_strobe_cdc_from_spi_d3        : std_logic;
-- signal Slave_MODF_strobe_cdc_from_spi_d1  : std_logic;
-- signal Slave_MODF_strobe_cdc_from_spi_d2  : std_logic;
-- signal Slave_MODF_strobe_cdc_from_spi_d3  : std_logic;
-- signal receive_Data_cdc_from_spi_d1       : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
-- signal receive_Data_cdc_from_spi_d2       : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
-- signal dtr_underrun_cdc_from_spi_d1       : std_logic;
-- signal dtr_underrun_cdc_from_spi_d2       : std_logic;
-- signal transmit_Data_cdc_from_axi_d1      : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
-- signal transmit_Data_cdc_from_axi_d2      : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));

-- signal spisel_pulse_cdc_from_spi_d1       : std_logic;
-- signal spisel_pulse_cdc_from_spi_d2       : std_logic;
-- signal spisel_pulse_cdc_from_spi_d3       : std_logic;

-- signal SPICR_0_LOOP_cdc_from_axi_d1       : std_logic;
-- signal SPICR_0_LOOP_cdc_from_axi_d2       : std_logic;

-- signal SPICR_1_SPE_cdc_from_axi_d1        : std_logic;
-- signal SPICR_1_SPE_cdc_from_axi_d2        : std_logic;

-- signal SPICR_2_MST_N_SLV_cdc_from_axi_d1  : std_logic;
-- signal SPICR_2_MST_N_SLV_cdc_from_axi_d2  : std_logic;

-- signal SPICR_3_CPOL_cdc_from_axi_d1       : std_logic;
-- signal SPICR_3_CPOL_cdc_from_axi_d2       : std_logic;

-- signal SPICR_4_CPHA_cdc_from_axi_d1       : std_logic;
-- signal SPICR_4_CPHA_cdc_from_axi_d2       : std_logic;

-- signal SPICR_5_TXFIFO_cdc_from_axi_d1     : std_logic;
-- signal SPICR_5_TXFIFO_cdc_from_axi_d2     : std_logic;

-- signal SPICR_7_SS_cdc_from_axi_d1         : std_logic;
-- signal SPICR_7_SS_cdc_from_axi_d2         : std_logic;

-- signal SPICR_8_TR_INHIBIT_cdc_from_axi_d1 : std_logic;
-- signal SPICR_8_TR_INHIBIT_cdc_from_axi_d2 : std_logic;

-- signal SPICR_9_LSB_cdc_from_axi_d1        : std_logic;
-- signal SPICR_9_LSB_cdc_from_axi_d2        : std_logic;

-- signal SPICR_bits_7_8_cdc_from_axi_d1     : std_logic_vector(1 downto 0);
-- signal SPICR_bits_7_8_cdc_from_axi_d2     : std_logic_vector(1 downto 0);

-- signal SPICR_6_RXFIFO_RST_cdc_from_axi_d1 : std_logic;
-- signal SPICR_6_RXFIFO_RST_cdc_from_axi_d2 : std_logic;

-- signal Tx_FIFO_Empty_cdc_from_axi_d1      : std_logic;
-- signal Tx_FIFO_Empty_cdc_from_axi_d2      : std_logic;

-- signal Tx_FIFO_Empty_SPISR_cdc_from_spi_d1 : std_logic;
-- signal Tx_FIFO_Empty_SPISR_cdc_from_spi_d2 : std_logic;
-- signal Tx_FIFO_Empty_SPISR_cdc_from_spi_d3 : std_logic;
-- signal Tx_FIFO_Empty_SPISR_cdc_from_spi_d4 : std_logic;

-- signal drr_Overrun_int_cdc_from_spi_d1 : std_logic;
-- signal drr_Overrun_int_cdc_from_spi_d2 : std_logic;
-- signal drr_Overrun_int_cdc_from_spi_d3 : std_logic;

-- signal SR_3_modf_cdc_from_axi_d1          : std_logic;
-- signal SR_3_modf_cdc_from_axi_d2          : std_logic;
-- signal SPISSR_cdc_from_axi_d1             : std_logic_vector(0 to (C_NUM_SS_BITS-1));
-- signal SPISSR_cdc_from_axi_d2             : std_logic_vector(0 to (C_NUM_SS_BITS-1));
     -- signal spiXfer_done_cdc_from_spi_int_2 : std_logic;
     -- signal spiXfer_done_d1            : std_logic;
     -- signal spiXfer_done_d2, spiXfer_done_d3           : std_logic;
     -- signal spisel_pulse_cdc_from_spi_int_2 : std_logic;
     -- signal Tx_FIFO_Empty_cdc_from_axi_int_2 : std_logic;
     -- signal Tx_FIFO_Empty_cdc_from_axi_d3 : std_logic;
     -- signal drr_Overrun_int_cdc_from_spi_int_2 : std_logic;
     -- signal Slave_MODF_strobe_cdc_from_spi_int_2 : std_logic;
    -- signal modf_strobe_cdc_from_spi_int_2 : std_logic;


-- attribute ASYNC_REG : string;
-- attribute ASYNC_REG of SPISEL_D1_REG_SYNC_SPI_2_AXI_1 : label is "TRUE";
-- attribute ASYNC_REG of SYNC_SPIXFER_DONE_SYNC_SPI_2_AXI_1 : label is "TRUE";
-- attribute ASYNC_REG of TX_FIFO_EMPTY_SYNC_AXI_2_SPI_1     : label is "TRUE";
-- attribute ASYNC_REG of SLAVE_MODF_STROBE_SYNC_SPI_cdc_to_AXI_1: label is "TRUE";
-- attribute ASYNC_REG of MODF_STROBE_SYNC_SPI_cdc_to_AXI_1      : label is "TRUE";
-- attribute ASYNC_REG of DRR_OVERRUN_SYNC_SPI_cdc_to_AXI_1      : label is "TRUE";
-- attribute ASYNC_REG of SPICR_9_LSB_AX2S_1                 : label is "TRUE";
-- attribute ASYNC_REG of SPICR_8_TR_INHIBIT_AX2S_1          : label is "TRUE";
-- attribute ASYNC_REG of SPICR_7_SS_AX2S_1                  : label is "TRUE";
-- attribute ASYNC_REG of SPICR_6_RXFIFO_RST_AX2S_1          : label is "TRUE";
-- attribute ASYNC_REG of SPICR_5_TXFIFO_AX2S_1              : label is "TRUE";
-- attribute ASYNC_REG of SPICR_4_CPHA_AX2S_1                : label is "TRUE";
-- attribute ASYNC_REG of SPICR_3_CPOL_AX2S_1                : label is "TRUE";
-- attribute ASYNC_REG of SPICR_2_MST_N_SLV_AX2S_1           : label is "TRUE";
-- attribute ASYNC_REG of SPICR_1_SPE_AX2S_1                 : label is "TRUE";
-- attribute ASYNC_REG of SPICR_0_LOOP_AX2S_1                : label is "TRUE";
-- attribute ASYNC_REG of SR_3_MODF_AX2S_1                   : label is "TRUE";

constant LOGIC_CHANGE : integer range 0 to 1 := 1;
constant MTBF_STAGES_AXI2S : integer range 0 to 6 := 3 ;
constant MTBF_STAGES_S2AXI : integer range 0 to 6 := 4 ;



-----
begin
-----
-- SPI_AXI_EQUAL_GEN: AXI and SPI domain clocks are same
---------------------
--SPI_AXI_EQUAL_GEN: if C_AXI_SPI_CLK_EQ_DIFF = 0 generate
-----
--begin

-----

LOGIC_GENERATION_FDR : if (Async_Clk =0) generate

     TX_FIFO_EMPTY_FOR_SPISR_SYNC_SPI_2_AXI: process(Bus2IP_Clk) is
     begin
     -----
          if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
              if(Soft_Reset_op = '1')then
                  Tx_FIFO_Empty_SPISR_cdc_from_spi_d1 <= '1';
                  Tx_FIFO_Empty_SPISR_cdc_from_spi_d2 <= '1';
              else
                  Tx_FIFO_Empty_SPISR_cdc_from_spi_d1 <= Tx_FIFO_Empty_SPISR_cdc_from_spi;
                  Tx_FIFO_Empty_SPISR_cdc_from_spi_d2 <= Tx_FIFO_Empty_SPISR_cdc_from_spi_d1;
              end if;
          end if;
     end process TX_FIFO_EMPTY_FOR_SPISR_SYNC_SPI_2_AXI;
     -----------------------------------------
     Tx_FIFO_Empty_SPISR_cdc_to_axi <= Tx_FIFO_Empty_SPISR_cdc_from_spi_d2;
     -------------------------------------------------

         TX_FIFO_EMPTY_STRETCH_1: process(EXT_SPI_CLK)is
     begin
          if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
                if(Rst_from_axi_cdc_to_spi = '1') then
                        Tx_FIFO_Empty_cdc_from_axi_int_2 <= '1';
                else
                        Tx_FIFO_Empty_cdc_from_axi_int_2 <= Tx_FIFO_Empty_cdc_from_axi xor
                                                      Tx_FIFO_Empty_cdc_from_axi_int_2;
                end if;
          end if;
     end process TX_FIFO_EMPTY_STRETCH_1;

     TX_FIFO_EMPTY_SYNC_AXI_2_SPI_1: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => Tx_FIFO_Empty_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => Tx_FIFO_Empty_cdc_from_axi_int_2,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     TX_FIFO_EMPTY_SYNC_AXI_2_SPI_2: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => Tx_FIFO_Empty_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => Tx_FIFO_Empty_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );

--     Tx_FIFO_Empty_cdc_to_spi <= Tx_FIFO_Empty_cdc_from_axi_d2 xor Tx_FIFO_Empty_cdc_from_axi_d1;

     TX_FIFO_EMPTY_SYNC_AXI_2_SPI_3: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => Tx_FIFO_Empty_cdc_from_axi_d3,
                              C  => EXT_SPI_CLK,
                              D  => Tx_FIFO_Empty_cdc_from_axi_d2,
                              R  => Rst_from_axi_cdc_to_spi
                            );

       Tx_FIFO_Empty_cdc_to_spi <= Tx_FIFO_Empty_cdc_from_axi_d2 xor Tx_FIFO_Empty_cdc_from_axi_d3;
     -------------------------------------------------

     SPISEL_D1_REG_SYNC_SPI_2_AXI_1: component FDR
                   port map (
                              Q  => spisel_d1_reg_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => spisel_d1_reg_cdc_from_spi,
                              R  => Soft_Reset_op
                            );
     SPISEL_D1_REG_SYNC_SPI_2_AXI_2: component FDR
                   port map (
                              Q  => spisel_d1_reg_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => spisel_d1_reg_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );

     spisel_d1_reg_cdc_to_axi <= spisel_d1_reg_cdc_from_spi_d2;

    SPISEL_PULSE_STRETCH_1: process(EXT_SPI_CLK)is
     begin
          if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
                if(Rst_from_axi_cdc_to_spi = '1') then
                        spisel_pulse_cdc_from_spi_int_2 <= '0';
                else
                        spisel_pulse_cdc_from_spi_int_2 <= spisel_pulse_cdc_from_spi xor
                                                      spisel_pulse_cdc_from_spi_int_2;
                end if;
          end if;
     end process SPISEL_PULSE_STRETCH_1;
   SPISEL_PULSE_SPI_2_AXI_1: component FDR
                   port map (
                              Q  => spisel_pulse_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => spisel_pulse_cdc_from_spi_int_2,
                              R  => Soft_Reset_op
                            );
     SPISEL_PULSE_SPI_2_AXI_2: component FDR
                   port map (
                              Q  => spisel_pulse_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => spisel_pulse_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
     SPISEL_PULSE_SPI_2_AXI_3: component FDR
                   port map (
                              Q  => spisel_pulse_cdc_from_spi_d3,
                              C  => Bus2IP_Clk,
                              D  => spisel_pulse_cdc_from_spi_d2,
                              R  => Soft_Reset_op
                            );
spisel_pulse_cdc_to_axi <= spisel_pulse_cdc_from_spi_d2 xor spisel_pulse_cdc_from_spi_d3;
    ---------------------------------------------
         SPI_XFER_DONE_STRETCH_1: process(EXT_SPI_CLK)is
     begin
          if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
                if(Rst_from_axi_cdc_to_spi = '1') then
                        spiXfer_done_cdc_from_spi_int_2 <= '0';
                else
                        spiXfer_done_cdc_from_spi_int_2 <= spiXfer_done_cdc_from_spi xor
                                                      spiXfer_done_cdc_from_spi_int_2;
                end if;
          end if;
     end process SPI_XFER_DONE_STRETCH_1;

     SYNC_SPIXFER_DONE_SYNC_SPI_2_AXI_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => spiXfer_done_d1,
                              C  => Bus2IP_Clk,
                              D  => spiXfer_done_cdc_from_spi_int_2,
                              R  => Soft_Reset_op
                            );
     SYNC_SPIXFER_DONE_SYNC_SPI_2_AXI_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => spiXfer_done_d2,
                              C  => Bus2IP_Clk,
                              D  => spiXfer_done_d1,
                              R  => Soft_Reset_op
                            );
     SYNC_SPIXFER_DONE_SYNC_SPI_2_AXI_3: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => spiXfer_done_d3,
                              C  => Bus2IP_Clk,
                              D  => spiXfer_done_d2,
                              R  => Soft_Reset_op
                            );
    spiXfer_done_cdc_to_axi <= spiXfer_done_d2 xor spiXfer_done_d3; --spiXfer_done_cdc_from_spi_d2;
    -----------------------------------------------

    MODF_STROBE_STRETCH_1: process(EXT_SPI_CLK)is
    begin
         if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
               if(Rst_from_axi_cdc_to_spi = '1') then
                       modf_strobe_cdc_from_spi_int_2 <= '0';
               else
                       modf_strobe_cdc_from_spi_int_2 <= modf_strobe_cdc_from_spi xor
                                                     modf_strobe_cdc_from_spi_int_2;
               end if;
         end if;
    end process MODF_STROBE_STRETCH_1;
     MODF_STROBE_SYNC_SPI_cdc_to_AXI_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => modf_strobe_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => modf_strobe_cdc_from_spi_int_2,
                              R  => Soft_Reset_op
                            );
     MODF_STROBE_SYNC_SPI_cdc_to_AXI_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => modf_strobe_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => modf_strobe_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
     MODF_STROBE_SYNC_SPI_cdc_to_AXI_3: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => modf_strobe_cdc_from_spi_d3,
                              C  => Bus2IP_Clk,
                              D  => modf_strobe_cdc_from_spi_d2,
                              R  => Soft_Reset_op
                            );
    modf_strobe_cdc_to_axi <= modf_strobe_cdc_from_spi_d2 xor modf_strobe_cdc_from_spi_d3; --spiXfer_done_cdc_from_spi_d2;
    ---------------------------------------------------------
    SLAVE_MODF_STROBE_STRETCH_1: process(EXT_SPI_CLK)is
    begin
         if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
               if(Rst_from_axi_cdc_to_spi = '1') then
                       Slave_MODF_strobe_cdc_from_spi_int_2 <= '0';
               else
                       Slave_MODF_strobe_cdc_from_spi_int_2 <= Slave_MODF_strobe_cdc_from_spi xor
                                                     Slave_MODF_strobe_cdc_from_spi_int_2;
               end if;
         end if;
    end process SLAVE_MODF_STROBE_STRETCH_1;
     SLAVE_MODF_STROBE_SYNC_SPI_cdc_to_AXI_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Slave_MODF_strobe_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => Slave_MODF_strobe_cdc_from_spi_int_2,
                              R  => Soft_Reset_op
                            );
     SLAVE_MODF_STROBE_SYNC_SPI_cdc_to_AXI_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Slave_MODF_strobe_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => Slave_MODF_strobe_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
      SLAVE_MODF_STROBE_SYNC_SPI_cdc_to_AXI_3: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Slave_MODF_strobe_cdc_from_spi_d3,
                              C  => Bus2IP_Clk,
                              D  => Slave_MODF_strobe_cdc_from_spi_d2,
                              R  => Soft_Reset_op
                            );
   Slave_MODF_strobe_cdc_to_axi <= Slave_MODF_strobe_cdc_from_spi_d2 xor
                               Slave_MODF_strobe_cdc_from_spi_d3; --spiXfer_done_cdc_from_spi_d2;
    -----------------------------------------------

    ---------------------------------------------------------

    RECEIVE_DATA_SYNC_SPI_cdc_to_AXI_P: process(Bus2IP_Clk) is
    -------------------------
    begin
    -----
         if(Bus2IP_Clk'event and Bus2IP_Clk = '1')then
             receive_Data_cdc_from_spi_d1 <= receive_Data_cdc_from_spi;
             receive_Data_cdc_from_spi_d2 <= receive_Data_cdc_from_spi_d1;
         end if;
    end process RECEIVE_DATA_SYNC_SPI_cdc_to_AXI_P;
    -------------------------------------------
    receive_Data_cdc_to_axi <= receive_Data_cdc_from_spi_d2;
    -----------------------------------------------
     DRR_OVERRUN_STRETCH_1: process(EXT_SPI_CLK)is
     begin
          if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
                if(Rst_from_axi_cdc_to_spi = '1') then
                        drr_Overrun_int_cdc_from_spi_int_2 <= '0';
                else
                        drr_Overrun_int_cdc_from_spi_int_2 <= drr_Overrun_int_cdc_from_spi xor
                                                      drr_Overrun_int_cdc_from_spi_int_2;
                end if;
          end if;
     end process DRR_OVERRUN_STRETCH_1;

     DRR_OVERRUN_SYNC_SPI_cdc_to_AXI_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => drr_Overrun_int_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => drr_Overrun_int_cdc_from_spi_int_2,
                              R  => Soft_Reset_op
                            );
     DRR_OVERRUN_SYNC_SPI_cdc_to_AXI_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => drr_Overrun_int_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => drr_Overrun_int_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
     DRR_OVERRUN_SYNC_SPI_cdc_to_AXI_3: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => drr_Overrun_int_cdc_from_spi_d3,
                              C  => Bus2IP_Clk,
                              D  => drr_Overrun_int_cdc_from_spi_d2,
                              R  => Soft_Reset_op
                            );
    drr_Overrun_int_cdc_to_axi <= drr_Overrun_int_cdc_from_spi_d2 xor drr_Overrun_int_cdc_from_spi_d3; --spiXfer_done_cdc_from_spi_d2;
    -----------------------------------------------
     DTR_UNDERRUN_SYNC_SPI_2_AXI_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => dtr_underrun_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => dtr_underrun_cdc_from_spi,
                              R  => Soft_Reset_op
                            );
     DTR_UNDERRUN_SYNC_SPI_2_AXI_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => dtr_underrun_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => dtr_underrun_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );

    dtr_underrun_cdc_to_axi <= dtr_underrun_cdc_from_spi_d2;
    -----------------------------------------------

TR_DATA_SYNC_AX2SP_GEN: for i in 0 to (C_NUM_TRANSFER_BITS-1) generate
     attribute ASYNC_REG : string;
     attribute ASYNC_REG of TR_DATA_SYNC_AX2SP_1: label is "TRUE";
     -----
     begin
     -----
     TR_DATA_SYNC_AX2SP_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => transmit_Data_cdc_from_axi_d1(i),
                              C  => EXT_SPI_CLK,
                              D  => transmit_Data_cdc_from_axi(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
     TR_DATA_SYNC_AX2SP_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => transmit_Data_cdc_from_axi_d2(i),
                              C  => EXT_SPI_CLK,
                              D  => transmit_Data_cdc_from_axi_d1(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
end generate TR_DATA_SYNC_AX2SP_GEN;

transmit_Data_cdc_to_spi <= transmit_Data_cdc_from_axi_d2;
-----------------------------------------------

     SPICR_0_LOOP_AX2S_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_0_LOOP_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_0_LOOP_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_0_LOOP_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_0_LOOP_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_0_LOOP_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );

     SPICR_0_LOOP_cdc_to_spi <= SPICR_0_LOOP_cdc_from_axi_d2;
     -----------------------------------------------

     SPICR_1_SPE_AX2S_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_1_SPE_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_1_SPE_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_1_SPE_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_1_SPE_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_1_SPE_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_1_SPE_cdc_to_spi <= SPICR_1_SPE_cdc_from_axi_d2;
     ---------------------------------------------

          SPICR_2_MST_N_SLV_AX2S_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_2_MST_N_SLV_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_2_MST_N_SLV_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_2_MST_N_SLV_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_2_MST_N_SLV_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_2_MST_N_SLV_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_2_MST_N_SLV_cdc_to_spi <= SPICR_2_MST_N_SLV_cdc_from_axi_d2;
     ---------------------------------------------------------

     SPICR_3_CPOL_AX2S_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_3_CPOL_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_3_CPOL_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_3_CPOL_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_3_CPOL_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_3_CPOL_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_3_CPOL_cdc_to_spi <= SPICR_3_CPOL_cdc_from_axi_d2;
     -----------------------------------------------
     SPICR_4_CPHA_AX2S_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_4_CPHA_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_4_CPHA_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_4_CPHA_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_4_CPHA_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_4_CPHA_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_4_CPHA_cdc_to_spi <= SPICR_4_CPHA_cdc_from_axi_d2;
     -----------------------------------------------
     SPICR_5_TXFIFO_AX2S_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_5_TXFIFO_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_5_TXFIFO_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_5_TXFIFO_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_5_TXFIFO_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_5_TXFIFO_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_5_TXFIFO_cdc_to_spi <= SPICR_5_TXFIFO_cdc_from_axi_d2;
     ---------------------------------------------------
     SPICR_6_RXFIFO_RST_AX2S_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_6_RXFIFO_RST_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_6_RXFIFO_RST_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_6_RXFIFO_RST_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_6_RXFIFO_RST_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_6_RXFIFO_RST_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_6_RXFIFO_RST_cdc_to_spi <= SPICR_6_RXFIFO_RST_cdc_from_axi_d2;
     -----------------------------------------------------------
     SPICR_7_SS_AX2S_1: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SPICR_7_SS_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_7_SS_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_7_SS_AX2S_2: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SPICR_7_SS_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_7_SS_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_7_SS_cdc_to_spi <= SPICR_7_SS_cdc_from_axi_d2;
     -------------------------------------------
     SPICR_8_TR_INHIBIT_AX2S_1: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SPICR_8_TR_INHIBIT_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_8_TR_INHIBIT_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_8_TR_INHIBIT_AX2S_2: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SPICR_8_TR_INHIBIT_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_8_TR_INHIBIT_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_8_TR_INHIBIT_cdc_to_spi <= SPICR_8_TR_INHIBIT_cdc_from_axi_d2;
     -----------------------------------------------------------
          SPICR_9_LSB_AX2S_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_9_LSB_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_9_LSB_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_9_LSB_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_9_LSB_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_9_LSB_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_9_LSB_cdc_to_spi <= SPICR_9_LSB_cdc_from_axi_d2;
     ---------------------------------------------
          SPICR_BITS_7_8_SYNC_GEN: for i in 1 downto 0 generate
     attribute ASYNC_REG : string;
     attribute ASYNC_REG of SPICR_BITS_7_8_AX2S_1 : label is "TRUE";
     begin
     -----
     SPICR_BITS_7_8_AX2S_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_bits_7_8_cdc_from_axi_d1(i),
                              C  => EXT_SPI_CLK,
                              D  => SPICR_bits_7_8_cdc_from_axi(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPICR_BITS_7_8_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_bits_7_8_cdc_from_axi_d2(i),
                              C  => EXT_SPI_CLK,
                              D  => SPICR_bits_7_8_cdc_from_axi_d1(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
     end generate SPICR_BITS_7_8_SYNC_GEN;
     -------------------------------------
     SPICR_bits_7_8_cdc_to_spi <= SPICR_bits_7_8_cdc_from_axi_d2;
     ---------------------------------------------------
     SR_3_MODF_AX2S_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SR_3_modf_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SR_3_modf_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SR_3_MODF_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SR_3_modf_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SR_3_modf_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SR_3_modf_cdc_to_spi <= SR_3_modf_cdc_from_axi_d2;
     -----------------------------------------

     SPISSR_SYNC_GEN: for i in 0 to C_NUM_SS_BITS-1 generate
     attribute ASYNC_REG : string;
     attribute ASYNC_REG of SPISSR_AX2S_1                  : label is "TRUE";
     -----
     begin
     -----
     SPISSR_AX2S_1: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SPISSR_cdc_from_axi_d1(i),
                              C  => EXT_SPI_CLK,
                              D  => SPISSR_cdc_from_axi(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
     SPISSR_SYNC_AXI_2_SPI_2: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SPISSR_cdc_from_axi_d2(i),
                              C  => EXT_SPI_CLK,
                              D  => SPISSR_cdc_from_axi_d1(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
     end generate SPISSR_SYNC_GEN;

     SPISSR_cdc_to_spi <= SPISSR_cdc_from_axi_d2;
     -----------------------------------
     
     end generate LOGIC_GENERATION_FDR ;
     
--============================================================================================================
	 
LOGIC_GENERATION_CDC : if (Async_Clk =1) generate 

--============================================================================================================    
	
-- Tx_FIFO_Empty_cdc_from_axi <= Tx_FIFO_Empty_cdc_from_axi;
-- Tx_FIFO_Empty_cdc_to_spi       <= Tx_FIFO_Empty_cdc_cdc_to_spi;

-- Tx_FIFO_Empty_SPISR_cdc_from_spi <= Tx_FIFO_Empty_SPISR_cdc_from_spi;
-- Tx_FIFO_Empty_SPISR_cdc_to_axi       <= Tx_FIFO_Empty_SPISR_cdc_cdc_to_axi;

-- spisel_d1_reg_cdc_from_spi <= spisel_d1_reg_cdc_from_spi;
-- spisel_d1_reg_cdc_to_axi      <= spisel_d1_reg_cdc_cdc_to_axi;

-- spisel_pulse_cdc_from_spi <= spisel_pulse_cdc_from_spi;
-- spisel_pulse_cdc_to_axi       <= spisel_pulse_cdc_cdc_to_axi;

-- spiXfer_done_cdc_from_spi <= spiXfer_done_cdc_from_spi;
-- spiXfer_done_cdc_to_axi       <= spiXfer_done_cdc_cdc_to_axi;

-- modf_strobe_cdc_from_spi <= modf_strobe_cdc_from_spi;
-- modf_strobe_cdc_to_axi       <= modf_strobe_cdc_cdc_to_axi;

-- Slave_MODF_strobe_cdc_from_spi <= Slave_MODF_strobe_cdc_from_spi;
-- Slave_MODF_strobe_cdc_to_axi       <= Slave_MODF_strobe_cdc_cdc_to_axi;

-- receive_Data_cdc_from_spi <= receive_Data_cdc_from_spi;
-- receive_Data_cdc_to_axi       <= receive_Data_cdc_cdc_to_axi;

-- drr_Overrun_int_cdc_from_spi <= drr_Overrun_int_cdc_from_spi;
-- drr_Overrun_int_cdc_to_axi       <= drr_Overrun_int_cdc_cdc_to_axi;

-- dtr_underrun_cdc_from_spi <= dtr_underrun_cdc_from_spi;
-- dtr_underrun_cdc_to_axi       <= dtr_underrun_cdc_cdc_to_axi;

-- transmit_Data_cdc_from_axi <= transmit_Data_cdc_from_axi;
-- transmit_Data_cdc_to_spi       <= transmit_Data_cdc_cdc_to_spi;

-- SPICR_0_LOOP_cdc_from_axi <= SPICR_0_LOOP_cdc_from_axi;
-- SPICR_0_LOOP_cdc_to_spi       <= SPICR_0_LOOP_cdc_cdc_to_spi;

-- SPICR_1_SPE_cdc_from_axi <= SPICR_1_SPE_cdc_from_axi;
-- SPICR_1_SPE_cdc_to_spi       <= SPICR_1_SPE_cdc_cdc_to_spi;

-- SPICR_2_MST_N_SLV_cdc_from_axi <= SPICR_2_MST_N_SLV_cdc_from_axi;
-- SPICR_2_MST_N_SLV_cdc_to_spi       <= SPICR_2_MST_N_SLV_cdc_cdc_to_spi;

-- SPICR_3_CPOL_cdc_from_axi <= SPICR_3_CPOL_cdc_from_axi;
-- SPICR_3_CPOL_cdc_to_spi       <= SPICR_3_CPOL_cdc_cdc_to_spi;

-- SPICR_4_CPHA_cdc_from_axi <= SPICR_4_CPHA_cdc_from_axi;
-- SPICR_4_CPHA_cdc_to_spi      <= SPICR_4_CPHA_cdc_cdc_to_spi;

-- SPICR_5_TXFIFO_cdc_from_axi <= SPICR_5_TXFIFO_cdc_from_axi;
-- SPICR_5_TXFIFO_cdc_to_spi       <= SPICR_5_TXFIFO_cdc_cdc_to_spi;

-- SPICR_6_RXFIFO_RST_cdc_from_axi <= SPICR_6_RXFIFO_RST_cdc_from_axi;
-- SPICR_6_RXFIFO_RST_cdc_to_spi       <= SPICR_6_RXFIFO_RST_cdc_cdc_to_spi;

-- SPICR_7_SS_cdc_from_axi <= SPICR_7_SS_cdc_from_axi;
-- SPICR_7_SS_cdc_to_spi       <= SPICR_7_SS_cdc_cdc_to_spi;

-- SPICR_8_TR_INHIBIT_cdc_from_axi <= SPICR_8_TR_INHIBIT_cdc_from_axi;
-- SPICR_8_TR_INHIBIT_cdc_to_spi       <= SPICR_8_TR_INHIBIT_cdc_cdc_to_spi;

-- SPICR_9_LSB_cdc_from_axi <= SPICR_9_LSB_cdc_from_axi;
-- SPICR_9_LSB_cdc_to_spi       <= SPICR_9_LSB_cdc_cdc_to_spi;

-- SPICR_bits_7_8_cdc_from_axi <= SPICR_bits_7_8_cdc_from_axi;
-- SPICR_bits_7_8_cdc_to_spi       <= SPICR_bits_7_8_cdc_cdc_to_spi;

-- SR_3_modf_cdc_from_axi <= SR_3_modf_cdc_from_axi;
-- SR_3_modf_cdc_to_spi       <= SR_3_modf_cdc_cdc_to_spi;

-- SPISSR_cdc_from_axi <= SPISSR_cdc_from_axi;
-- SPISSR_cdc_to_spi       <= SPISSR_cdc_cdc_to_spi;

--============================================================================================================    
	
	-- all the signals pass through FF with reset before CDC_SYNC module to initialise the value of the signal 
	-- at its reset state. As many signals coming from bram have initial value of XX.
	
	
	
	
       
    TX_FIFO_EMPTY_FOR_SPISR_SYNC_SPI_2_AXI_CDC : entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 ,   -- 1 is level synch
        C_RESET_STATE               => 0 ,   -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK , 
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => Tx_FIFO_Empty_SPISR_cdc_from_spi ,
        scndry_aclk          => Bus2IP_Clk ,
	    prmry_vect_in        => (others => '0') ,
        scndry_resetn        => Soft_Reset_op ,
        scndry_out           => Tx_FIFO_Empty_SPISR_cdc_to_axi
    ); 
     
--------------------------------------------------------------------------------------------------------------
----  --  TX_FIFO_EMPTY_STRETCH_1: process(Bus2IP_Clk)is
----  --   begin
----  --        if(Bus2IP_Clk'event and Bus2IP_Clk= '1') then
----  --              if(Soft_Reset_op = '1') then
----  --                      Tx_FIFO_Empty_cdc_from_axi_int_2 <= '1';
----  --              else
----  --                      Tx_FIFO_Empty_cdc_from_axi_int_2 <= Tx_FIFO_Empty_cdc_from_axi xor
----  --                                                    Tx_FIFO_Empty_cdc_from_axi_int_2;
----  --              end if;
----  --        end if;
----  --   end process TX_FIFO_EMPTY_STRETCH_1;
----
----    TX_FIFO_EMPTY_SYNC_AXI_2_SPI_CDC : entity lib_cdc_v1_0_2.cdc_sync
----    generic map (
----        C_CDC_TYPE                  => 1, -- 2 is ack based level sync
----        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
----        C_SINGLE_BIT                => 1 , 
----        C_FLOP_INPUT                => 0 ,
----        C_VECTOR_WIDTH              => 1 ,
----        C_MTBF_STAGES               => MTBF_STAGES_AXI2S   
----		)
----
----    port map (
----        prmry_aclk           => Bus2IP_Clk , 
----        prmry_resetn         => Soft_Reset_op ,
----        prmry_in             => Tx_FIFO_Empty_cdc_from_axi,--Tx_FIFO_Empty_cdc_from_axi_int_2,--Tx_FIFO_Empty_cdc_from_axi_d1 ,
----        scndry_aclk          => EXT_SPI_CLK ,
----	    prmry_vect_in        => (others => '0' ),
----        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
----        scndry_out            => Tx_FIFO_Empty_cdc_from_axi_d2 --Tx_FIFO_Empty_cdc_from_axi_d2--Tx_FIFO_Empty_cdc_to_spi
----        --scndry_out            => Tx_FIFO_Empty_cdc_to_spi --Tx_FIFO_Empty_cdc_from_axi_d2--Tx_FIFO_Empty_cdc_to_spi
----       );
----	   
------	   TX_FIFO_EMPTY_STRETCH_1_CDC: process(EXT_SPI_CLK)is
------         begin
------              if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
------                    
------                            Tx_FIFO_Empty_cdc_from_axi_d3 <= Tx_FIFO_Empty_cdc_from_axi_d2;                          
------                    
------              end if;
------     end process TX_FIFO_EMPTY_STRETCH_1_CDC;
------     Tx_FIFO_Empty_cdc_to_spi <= Tx_FIFO_Empty_cdc_from_axi_d2 xor Tx_FIFO_Empty_cdc_from_axi_d3;
----
----	   TX_FIFO_EMPTY_STRETCH_1_CDC: process(EXT_SPI_CLK)is
----         begin
----              if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
----                    
----                            Tx_FIFO_Empty_cdc_from_axi_d3 <= Tx_FIFO_Empty_cdc_from_axi_d2;                          
----                    
----              end if;
----     end process TX_FIFO_EMPTY_STRETCH_1_CDC;
----     Tx_FIFO_Empty_cdc_to_spi <= Tx_FIFO_Empty_cdc_from_axi_d2 or Tx_FIFO_Empty_cdc_from_axi_d3;


    Tx_FIFO_Empty_cdc_to_spi <= Tx_FIFO_Empty_cdc_to_spi_i;



    TX_FIFO_EMPTY_HANDSHAKE_REQ_AXI_2_SPI_CDC : entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1, -- 2 is ack based level sync
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S   
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => tx_empty_signal_handshake_req,
        scndry_aclk          => EXT_SPI_CLK ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => Tx_FIFO_Empty_cdc_to_spi_i 
       );



    TX_FIFO_EMPTY_HANDSHAKE_GNT_SPI_2_AXI_CDC : entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1, -- 2 is ack based level sync
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S   
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => Tx_FIFO_Empty_cdc_to_spi_i,
        scndry_aclk          => Bus2IP_Clk ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => tx_empty_signal_handshake_gnt 
       );




	----------------------------------------------------------------------------------------------------------
	
	
   
	SPISEL_D1_REG_SYNC_SPI_2_AXI_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 ,  -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK , 
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => spisel_d1_reg_cdc_from_spi ,
        scndry_aclk          => Bus2IP_Clk ,
        prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out           => spisel_d1_reg_cdc_to_axi
    );			
    -----------------------------------------------------------------------------------------------------------
    
   SPISEL_PULSE_STRETCH_1_CDC: process(EXT_SPI_CLK)is
         begin
              if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
                    if(Rst_from_axi_cdc_to_spi = '1') then
                            spisel_pulse_cdc_from_spi_int_2 <= '0';
                            --spisel_pulse_cdc_from_spi_d1    <= '0';
                    else
                            spisel_pulse_cdc_from_spi_int_2 <= spisel_pulse_cdc_from_spi xor
                                                      spisel_pulse_cdc_from_spi_int_2;
                            --spisel_pulse_cdc_from_spi_d1    <= spisel_pulse_cdc_from_spi_int_2;                          
                    end if;
              end if;
     end process SPISEL_PULSE_STRETCH_1_CDC;

	SPISEL_PULSE_SPI_2_AXI_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 2 is ack based level sync
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI   
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK , 
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => spisel_pulse_cdc_from_spi_int_2 ,
        scndry_aclk          => Bus2IP_Clk ,
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out            => spisel_pulse_cdc_from_spi_d2
    );
	SPISEL_PULSE_STRETCH_1: process(Bus2IP_Clk)is
         begin
              if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
                    
                            spisel_pulse_cdc_from_spi_d3 <= spisel_pulse_cdc_from_spi_d2;
                                                    
                    
              end if;
     end process SPISEL_PULSE_STRETCH_1;
	 spisel_pulse_cdc_to_axi <= spisel_pulse_cdc_from_spi_d2 xor spisel_pulse_cdc_from_spi_d3;
    --------------------------------------------------------------------------------------------------------------
	 SPI_XFER_DONE_STRETCH_1_CDC: process(EXT_SPI_CLK)is
	      begin
	           if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
	                 if(Rst_from_axi_cdc_to_spi = '1') then
	                         spiXfer_done_cdc_from_spi_int_2 <= '0';
	                        -- spiXfer_done_d2            <= '0';
	                 else
	                         spiXfer_done_cdc_from_spi_int_2 <= spiXfer_done_cdc_from_spi xor
                                                      spiXfer_done_cdc_from_spi_int_2;
                                -- spiXfer_done_d2            <= spiXfer_done_cdc_from_spi_int_2;
	                 end if;
	           end if;
     end process SPI_XFER_DONE_STRETCH_1_CDC;
	  
	 SYNC_SPIXFER_DONE_SYNC_SPI_2_AXI_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 2 is ack based level sync
        C_RESET_STATE               => 0 ,-- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI  
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK , 
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => spiXfer_done_cdc_from_spi_int_2,--spiXfer_done_d2 ,
        scndry_aclk          => Bus2IP_Clk ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out           => spiXfer_done_d2--spiXfer_done_cdc_to_axi
    );
	
	SPI_XFER_DONE_STRETCH_1: process(Bus2IP_Clk)is
	      begin
	           if(Bus2IP_Clk'event and Bus2IP_Clk= '1') then
	                 
	                         spiXfer_done_d3 <= spiXfer_done_d2 ;
	                 
	           end if;
     end process SPI_XFER_DONE_STRETCH_1;
     spiXfer_done_cdc_to_axi <= spiXfer_done_d2 xor spiXfer_done_d3;
	 --------------------------------------------------------------------------------------------------------------
	
	MODF_STROBE_STRETCH_1_CDC: process(EXT_SPI_CLK)is
	    begin
	         if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
	               if(Rst_from_axi_cdc_to_spi = '1') then
	                       modf_strobe_cdc_from_spi_int_2 <= '0';
	                       --modf_strobe_cdc_from_spi_d1    <= '0';
	               else
	                       modf_strobe_cdc_from_spi_int_2 <= modf_strobe_cdc_from_spi xor
                                                     modf_strobe_cdc_from_spi_int_2;
                              -- modf_strobe_cdc_from_spi_d1    <= modf_strobe_cdc_from_spi_int_2;
	               end if;
	         end if;
    end process MODF_STROBE_STRETCH_1_CDC;
	
	
	MODF_STROBE_SYNC_SPI_cdc_to_AXI_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 2 is ack based level sync
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK , 
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => modf_strobe_cdc_from_spi_int_2,--modf_strobe_cdc_from_spi_d1 ,
        scndry_aclk          => Bus2IP_Clk ,
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out            => modf_strobe_cdc_from_spi_d2--modf_strobe_cdc_to_axi
    );
	
	MODF_STROBE_STRETCH_1: process(Bus2IP_Clk)is
	    begin
	         if(Bus2IP_Clk'event and Bus2IP_Clk= '1') then
	               
	                       modf_strobe_cdc_from_spi_d3 <= modf_strobe_cdc_from_spi_d2 ;
	               
	         end if;
    end process MODF_STROBE_STRETCH_1;
    modf_strobe_cdc_to_axi <= modf_strobe_cdc_from_spi_d2 xor modf_strobe_cdc_from_spi_d3;
    ----------------------------------------------------------------------------------------------------------------
     
     SLAVE_MODF_STROBE_STRETCH_1_CDC: process(EXT_SPI_CLK)is
         begin
              if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
                    if(Rst_from_axi_cdc_to_spi = '1') then
                            Slave_MODF_strobe_cdc_from_spi_int_2 <= '0';
    --                        Slave_MODF_strobe_cdc_from_spi_d1    <= '0';
                    else
                            Slave_MODF_strobe_cdc_from_spi_int_2 <= Slave_MODF_strobe_cdc_from_spi xor
                                                     Slave_MODF_strobe_cdc_from_spi_int_2;
     --                       Slave_MODF_strobe_cdc_from_spi_d1    <= Slave_MODF_strobe_cdc_from_spi_int_2;
                    end if;
              end if;
    end process SLAVE_MODF_STROBE_STRETCH_1_CDC;
	
     SLAVE_MODF_STROBE_SYNC_SPI_cdc_to_AXI_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 2 is ack based level sync
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK , 
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => Slave_MODF_strobe_cdc_from_spi_int_2 ,
        scndry_aclk          => Bus2IP_Clk ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out           => Slave_MODF_strobe_cdc_from_spi_d2
    ); 
    
         SLAVE_MODF_STROBE_STRETCH_1: process(Bus2IP_Clk)is
             begin
                  if(Bus2IP_Clk'event and Bus2IP_Clk= '1') then
                        
                                Slave_MODF_strobe_cdc_from_spi_d3 <= Slave_MODF_strobe_cdc_from_spi_d2 ;
         
                        
                  end if;
    end process SLAVE_MODF_STROBE_STRETCH_1;
       Slave_MODF_strobe_cdc_to_axi <= Slave_MODF_strobe_cdc_from_spi_d2 xor
                               Slave_MODF_strobe_cdc_from_spi_d3;  
    -----------------------------------------------------------------------------------------------------

     RECEIVE_DATA_SYNC_SPI_cdc_to_AXI_P_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 0 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => C_NUM_TRANSFER_BITS ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK,
        prmry_resetn         => Rst_from_axi_cdc_to_spi,
        prmry_vect_in        => receive_Data_cdc_from_spi,
        scndry_aclk          => Bus2IP_Clk,
        prmry_in               => '0',
        scndry_resetn        => Soft_Reset_op,
        scndry_vect_out      => receive_Data_cdc_to_axi
    );        
    -------------------------------------------------------------------------------------------------------
    DRR_OVERRUN_STRETCH_1: process(EXT_SPI_CLK)is
         begin
              if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
                    if(Rst_from_axi_cdc_to_spi = '1') then
                            drr_Overrun_int_cdc_from_spi_int_2 <= '0';
                    else
                            drr_Overrun_int_cdc_from_spi_int_2 <= drr_Overrun_int_cdc_from_spi xor
                                                          drr_Overrun_int_cdc_from_spi_int_2;
                    end if;
              end if;
         end process DRR_OVERRUN_STRETCH_1;
    
         DRR_OVERRUN_SYNC_SPI_cdc_to_AXI_1: component FDR
                       generic map(INIT => '0'
                       )port map (
                                  Q  => drr_Overrun_int_cdc_from_spi_d1,
                                  C  => Bus2IP_Clk,
                                  D  => drr_Overrun_int_cdc_from_spi_int_2,
                                  R  => Soft_Reset_op
                                );
         DRR_OVERRUN_SYNC_SPI_cdc_to_AXI_2: component FDR
                       generic map(INIT => '0'
                       )port map (
                                  Q  => drr_Overrun_int_cdc_from_spi_d2,
                                  C  => Bus2IP_Clk,
                                  D  => drr_Overrun_int_cdc_from_spi_d1,
                                  R  => Soft_Reset_op
                                );
         DRR_OVERRUN_SYNC_SPI_cdc_to_AXI_3: component FDR
                       generic map(INIT => '0'
                       )port map (
                                  Q  => drr_Overrun_int_cdc_from_spi_d3,
                                  C  => Bus2IP_Clk,
                                  D  => drr_Overrun_int_cdc_from_spi_d2,
                                  R  => Soft_Reset_op
                                );
         DRR_OVERRUN_SYNC_SPI_cdc_to_AXI_4: component FDR
                       generic map(INIT => '0'
                       )port map (
                                  Q  => drr_Overrun_int_cdc_from_spi_d4,
                                  C  => Bus2IP_Clk,
                                  D  => drr_Overrun_int_cdc_from_spi_d3,
                                  R  => Soft_Reset_op
                                );                       
    drr_Overrun_int_cdc_to_axi <= drr_Overrun_int_cdc_from_spi_d4 xor drr_Overrun_int_cdc_from_spi_d3;
    
    
    
    -------------------------------------------------------------------------------------------------------

    
     DTR_UNDERRUN_SYNC_SPI_2_AXI_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 ,-- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK , 
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => dtr_underrun_cdc_from_spi ,
        scndry_aclk          => Bus2IP_Clk ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out           => dtr_underrun_cdc_to_axi
    );
    -------------------------------------------------------------------------------------------------------
      
     SPICR_0_LOOP_AX2S_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SPICR_0_LOOP_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
        prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => SPICR_0_LOOP_cdc_to_spi
    );
    ------------------------------------------------------------------------------------------------------

	SPICR_1_SPE_AX2S_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SPICR_1_SPE_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => SPICR_1_SPE_cdc_to_spi
    );
	----------------------------------------------------------------------------------------------------
	
     
     SPICR_2_MST_N_SLV_AX2S_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SPICR_2_MST_N_SLV_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => SPICR_2_MST_N_SLV_cdc_to_spi
    );
     --------------------------------------------------------------------------------------------------
     
     SPICR_3_CPOL_AX2S_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SPICR_3_CPOL_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
        prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => SPICR_3_CPOL_cdc_to_spi
    );
    --------------------------------------------------------------------------------------------------
     
     SPICR_4_CPHA_AX2S_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SPICR_4_CPHA_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => SPICR_4_CPHA_cdc_to_spi
    );
    --------------------------------------------------------------------------------------------------
         
    SPICR_5_TXFIFO_AX2S_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SPICR_5_TXFIFO_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
        prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => SPICR_5_TXFIFO_cdc_to_spi
    );
    --------------------------------------------------------------------------------------------------
     
    SPICR_6_RXFIFO_RST_AX2S_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SPICR_6_RXFIFO_RST_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => SPICR_6_RXFIFO_RST_cdc_to_spi
    );
     --------------------------------------------------------------------------------------------------
     
     
    SPICR_7_SS_AX2S_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SPICR_7_SS_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => SPICR_7_SS_cdc_to_spi
    );
    --------------------------------------------------------------------------------------------------
        
    SPICR_8_TR_INHIBIT_AX2S_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SPICR_8_TR_INHIBIT_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => SPICR_8_TR_INHIBIT_cdc_to_spi
    );
     --------------------------------------------------------------------------------------------------
          
    SPICR_9_LSB_AX2S_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SPICR_9_LSB_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
        prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => SPICR_9_LSB_cdc_to_spi
    );
	-----------------------------------------------------------------------------------------------------
     
     TR_DATA_SYNC_AX2SP_GEN_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 0 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => C_NUM_TRANSFER_BITS ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk,
        prmry_resetn         => Soft_Reset_op,
        prmry_vect_in        => transmit_Data_cdc_from_axi,
        scndry_aclk          => EXT_SPI_CLK, 
	prmry_in             => '0' ,
        scndry_resetn        => Rst_from_axi_cdc_to_spi,
        scndry_vect_out      => transmit_Data_cdc_to_spi
    );        
	--------------------------------------------------------------------------------------------------
     
    SR_3_MODF_AX2S_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SR_3_modf_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => SR_3_modf_cdc_to_spi
    );
    -----------------------------------------------------------------------------------------------------

     SPISSR_SYNC_GEN_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 0 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => C_NUM_SS_BITS ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk,
        prmry_resetn         => Soft_Reset_op,
        prmry_vect_in        => SPISSR_cdc_from_axi,
        scndry_aclk          => EXT_SPI_CLK, 
	    prmry_in             => '0' ,
        scndry_resetn        => Rst_from_axi_cdc_to_spi,
        scndry_vect_out      => SPISSR_cdc_to_spi
    );
	---------------------------------------------
	
    
	
     SPICR_BITS_7_8_SYNC_GEN_CDC: for i in 1 downto 0 generate
     attribute ASYNC_REG : string;
     attribute ASYNC_REG of SPICR_BITS_7_8_AX2S_1_CDC : label is "TRUE";
     begin
    SPICR_BITS_7_8_AX2S_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
    	    generic map (
    	        C_CDC_TYPE                  => 1 , -- 1 is level synch
    	        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
    	        C_SINGLE_BIT                => 1 , 
    	        C_FLOP_INPUT                => 0 ,
    	        C_VECTOR_WIDTH              => 1 ,
    	        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
    			)
    	
    	    port map (
	        	        prmry_aclk           => Bus2IP_Clk,
	        	        prmry_resetn         => Soft_Reset_op,
	        	        prmry_in             => SPICR_bits_7_8_cdc_from_axi(i),
	        	        scndry_aclk          => EXT_SPI_CLK, 
				prmry_vect_in        => (others => '0' ),
	        	        scndry_resetn        => Rst_from_axi_cdc_to_spi,
	        	        scndry_out           => SPICR_bits_7_8_cdc_from_axi_d2(i)
	    );
         -----------------------------------------
        end generate SPICR_BITS_7_8_SYNC_GEN_CDC;
	 	SPICR_bits_7_8_cdc_to_spi <= SPICR_bits_7_8_cdc_from_axi_d2; 	 	 
	end generate LOGIC_GENERATION_CDC;
end architecture imp;


