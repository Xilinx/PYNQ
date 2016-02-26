-------------------------------------------------------------------------------
-- axi_quad_spi.vhd - Entity and architecture
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
-- Filename:        axi_quad_spi.vhd
-- Version:         v3.0
-- Description:     This is the top-level design file for the AXI Quad SPI core.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- History:
-- ~~~~~~
--  SK 19/01/11  -- created v1.00.a version
-- ^^^^^^
-- 1. Created first version of the core.
-- ~~~~~~
-- ~~~~~~
--  SK       12/16/12      -- v3.0
--  1. up reved to major version for 2013.1 Vivado release. No logic updates.
--  2. Updated the version of AXI LITE IPIF to v2.0 in X.Y format
--  3. updated the proc common version to proc_common_v4_0_2
--  4. No Logic Updates
-- ^^^^^^
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
entity cross_clk_sync_fifo_1 is
     generic (
             C_FAMILY                     : string;
             Async_Clk                    : integer;
             C_FIFO_DEPTH                 : integer;
             C_DATA_WIDTH                 : integer;
             --C_AXI4_CLK_PS                : integer;
             --C_EXT_SPI_CLK_PS             : integer;
             C_S_AXI_DATA_WIDTH           : integer;
             C_NUM_TRANSFER_BITS          : integer;
             --C_AXI_SPI_CLK_EQ_DIFF        : integer;
             C_NUM_SS_BITS                : integer
     );
     port (
              EXT_SPI_CLK               : in std_logic;
              Bus2IP_Clk                : in std_logic;
              Soft_Reset_op             : in std_logic;
              Rst_cdc_to_spi       : in std_logic;
              ----------------------------
              SPISR_0_CMD_Error_cdc_from_spi : in std_logic;
              SPISR_0_CMD_Error_cdc_to_axi  : out std_logic;
              ----------------------------------------
              spisel_d1_reg_cdc_from_spi     : in std_logic;
              spisel_d1_reg_cdc_to_axi      : out std_logic;
              ----------------------------------------
              spisel_pulse_cdc_from_spi      : in std_logic;
              spisel_pulse_cdc_to_axi       : out std_logic;
              ----------------------------
              Mst_N_Slv_mode_cdc_from_spi    : in std_logic;
              Mst_N_Slv_mode_cdc_to_axi     : out std_logic;
              ----------------------------
              slave_MODF_strobe_cdc_from_spi : in std_logic;
              slave_MODF_strobe_cdc_to_axi  : out std_logic;
              ----------------------------
              modf_strobe_cdc_from_spi       : in std_logic;
              modf_strobe_cdc_to_axi        : out std_logic;
              ----------------------------
              Rx_FIFO_Full_cdc_from_axi      : in std_logic;
              Rx_FIFO_Full_cdc_to_spi       : out std_logic;
              ----------------------------
              reset_RcFIFO_ptr_cdc_from_axi  : in std_logic;
              reset_RcFIFO_ptr_cdc_to_spi   : out std_logic;
              ----------------------------
              Rx_FIFO_Empty_cdc_from_axi     : in std_logic;
              Rx_FIFO_Empty_cdc_to_spi      : out std_logic;
              ----------------------------
              Tx_FIFO_Empty_cdc_from_spi     : in std_logic;
              Tx_FIFO_Empty_cdc_to_axi      : out std_logic;
              ----------------------------
              Tx_FIFO_Empty_SPISR_cdc_from_spi : in std_logic;
              Tx_FIFO_Empty_SPISR_cdc_to_axi  : out std_logic;
              ----------------------------
              Tx_FIFO_Full_cdc_from_axi      : in std_logic;
              Tx_FIFO_Full_cdc_to_spi       : out std_logic;
              ----------------------------
              spiXfer_done_cdc_from_spi      : in std_logic;
              spiXfer_done_cdc_to_axi       : out std_logic;
              ----------------------------
              dtr_underrun_cdc_from_spi      : in std_logic;
              dtr_underrun_cdc_to_axi       : out std_logic;
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
              SPISSR_cdc_to_spi             : out std_logic_vector(0 to (C_NUM_SS_BITS-1));
              ----------------------------
              spiXfer_done_cdc_to_axi_1     : out std_logic;
              ----------------------------
              drr_Overrun_int_cdc_from_spi   : in std_logic;
              drr_Overrun_int_cdc_to_axi    : out std_logic
);
end entity cross_clk_sync_fifo_1;
-------------------------------------------------------------------------------
architecture imp of cross_clk_sync_fifo_1 is
----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------


signal SPISR_0_CMD_Error_cdc_from_spi_d1: std_logic;
signal SPISR_0_CMD_Error_cdc_from_spi_d2: std_logic;

signal spisel_d1_reg_cdc_from_spi_d1    : std_logic;
signal spisel_d1_reg_cdc_from_spi_d2    : std_logic;

signal spisel_pulse_cdc_from_spi_d1     : std_logic;
signal spisel_pulse_cdc_from_spi_d2     : std_logic;
signal spisel_pulse_cdc_from_spi_d3     : std_logic;-- 2/21/2012
signal spisel_pulse_cdc_from_spi_d4     : std_logic;
signal Mst_N_Slv_mode_cdc_from_spi_d1   : std_logic;
signal Mst_N_Slv_mode_cdc_from_spi_d2   : std_logic;

signal slave_MODF_strobe_cdc_from_spi_d1: std_logic;
signal slave_MODF_strobe_cdc_from_spi_d2: std_logic;
signal slave_MODF_strobe_cdc_from_spi_d3: std_logic; -- 2/21/2012
signal Slave_MODF_strobe_cdc_from_spi_int_2 : std_logic;

signal modf_strobe_cdc_from_spi_d1      : std_logic;
signal modf_strobe_cdc_from_spi_d2      : std_logic;
signal modf_strobe_cdc_from_spi_d3      : std_logic;

signal SPICR_6_RXFIFO_RST_cdc_from_axi_d1 : std_logic;
signal SPICR_6_RXFIFO_RST_cdc_from_axi_d2 : std_logic;

signal Rx_FIFO_Full_cdc_from_axi_d1       : std_logic;
signal Rx_FIFO_Full_cdc_from_axi_d2       : std_logic;

signal reset_RcFIFO_ptr_cdc_from_axi_d1   : std_logic;
signal reset_RcFIFO_ptr_cdc_from_axi_d2   : std_logic;

signal Rx_FIFO_Empty_cdc_from_axi_d1      : std_logic;
signal Rx_FIFO_Empty_cdc_from_axi_d2      : std_logic;

signal Tx_FIFO_Empty_cdc_from_spi_d1      : std_logic;
signal Tx_FIFO_Empty_cdc_from_spi_d2      : std_logic;
-- signal Tx_FIFO_Empty_cdc_from_spi_d2      : std_logic_vector(2 downto 0);

signal Tx_FIFO_Full_cdc_from_axi_d1       : std_logic;
signal Tx_FIFO_Full_cdc_from_axi_d2       : std_logic;

signal modf_strobe_cdc_to_axi_d1         : std_logic;
signal modf_strobe_cdc_to_axi_d2         : std_logic;
signal modf_strobe_cdc_from_spi_int_2 : std_logic;

signal spiXfer_done_cdc_from_spi_d1       : std_logic;
signal spiXfer_done_cdc_from_spi_d2       : std_logic;

signal dtr_underrun_cdc_from_spi_d1       : std_logic;
signal dtr_underrun_cdc_from_spi_d2       : std_logic;

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

signal SR_3_modf_cdc_from_axi_d1          : std_logic;
signal SR_3_modf_cdc_from_axi_d2          : std_logic;

signal SPISSR_cdc_from_axi_d1             : std_logic_vector(0 to (C_NUM_SS_BITS-1));
signal SPISSR_cdc_from_axi_d2             : std_logic_vector(0 to (C_NUM_SS_BITS-1));

     signal rx_fifo_full_int, RST_RX_FF   : std_logic;
     signal rx_fifo_full_int_2 : std_logic;

     signal RST_spiXfer_done_FF        : std_logic;
     signal spiXfer_done_d1            : std_logic;
     signal spiXfer_done_d2, spiXfer_done_d3           : std_logic;
     signal spiXfer_done_cdc_from_spi_int_2 : std_logic;
     signal spiXfer_done_cdc_from_spi_int   : std_logic;

     signal Tx_FIFO_Empty_SPISR_cdc_from_spi_d1 : std_logic;
     signal Tx_FIFO_Empty_SPISR_cdc_from_spi_d2 : std_logic;

     signal reset_RX_FIFO_Rst_pulse : std_logic;
     signal SPICR_RX_FIFO_Rst_en_d1 : std_logic;
     signal SPICR_RX_FIFO_Rst_en    : std_logic;
     signal spisel_pulse_cdc_from_spi_int_2 : std_logic;
     signal SPISSR_cdc_from_axi_d1_and_reduce : std_logic;
signal drr_Overrun_int_cdc_from_spi_d1 : std_logic;
signal drr_Overrun_int_cdc_from_spi_d2 : std_logic;
signal drr_Overrun_int_cdc_from_spi_d3 : std_logic;
signal drr_Overrun_int_cdc_from_spi_int_2 : std_logic;
signal SPICR_RX_FIFO_Rst_en_d2 : std_logic;



-- signal SPISR_0_CMD_Error_cdc_from_spi_d1: std_logic;
-- signal SPISR_0_CMD_Error_cdc_from_spi_d2: std_logic;

-- signal spisel_d1_reg_cdc_from_spi_d1    : std_logic;
-- signal spisel_d1_reg_cdc_from_spi_d2    : std_logic;

-- signal spisel_pulse_cdc_from_spi_d1     : std_logic;
-- signal spisel_pulse_cdc_from_spi_d2     : std_logic;
-- signal spisel_pulse_cdc_from_spi_d3     : std_logic;-- 2/21/2012

-- signal Mst_N_Slv_mode_cdc_from_spi_d1   : std_logic;
-- signal Mst_N_Slv_mode_cdc_from_spi_d2   : std_logic;

-- signal slave_MODF_strobe_cdc_from_spi_d1: std_logic;
-- signal slave_MODF_strobe_cdc_from_spi_d2: std_logic;
-- signal slave_MODF_strobe_cdc_from_spi_d3: std_logic; -- 2/21/2012
-- signal Slave_MODF_strobe_cdc_from_spi_int_2 : std_logic;

-- signal modf_strobe_cdc_from_spi_d1      : std_logic;
-- signal modf_strobe_cdc_from_spi_d2      : std_logic;
-- signal modf_strobe_cdc_from_spi_d3      : std_logic;

-- signal SPICR_6_RXFIFO_RST_cdc_from_axi_d1 : std_logic;
-- signal SPICR_6_RXFIFO_RST_cdc_from_axi_d2 : std_logic;

-- signal Rx_FIFO_Full_cdc_from_axi_d1       : std_logic;
-- signal Rx_FIFO_Full_cdc_from_axi_d2       : std_logic;

-- signal reset_RcFIFO_ptr_cdc_from_axi_d1   : std_logic;
-- signal reset_RcFIFO_ptr_cdc_from_axi_d2   : std_logic;

-- signal Rx_FIFO_Empty_cdc_from_axi_d1      : std_logic;
-- signal Rx_FIFO_Empty_cdc_from_axi_d2      : std_logic;

-- signal Tx_FIFO_Empty_cdc_from_spi_d1      : std_logic;
-- signal Tx_FIFO_Empty_cdc_from_spi_d2      : std_logic;
-- -- signal Tx_FIFO_Empty_cdc_from_spi_d2      : std_logic_vector(2 downto 0);

-- signal Tx_FIFO_Full_cdc_from_axi_d1       : std_logic;
-- signal Tx_FIFO_Full_cdc_from_axi_d2       : std_logic;

-- signal modf_strobe_cdc_to_axi_d1         : std_logic;
-- signal modf_strobe_cdc_to_axi_d2         : std_logic;
-- signal modf_strobe_cdc_from_spi_int_2 : std_logic;

-- signal spiXfer_done_cdc_from_spi_d1       : std_logic;
-- signal spiXfer_done_cdc_from_spi_d2       : std_logic;

-- signal dtr_underrun_cdc_from_spi_d1       : std_logic;
-- signal dtr_underrun_cdc_from_spi_d2       : std_logic;

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

-- signal SR_3_modf_cdc_from_axi_d1          : std_logic;
-- signal SR_3_modf_cdc_from_axi_d2          : std_logic;

-- signal SPISSR_cdc_from_axi_d1             : std_logic_vector(0 to (C_NUM_SS_BITS-1));
-- signal SPISSR_cdc_from_axi_d2             : std_logic_vector(0 to (C_NUM_SS_BITS-1));

     -- signal rx_fifo_full_int, RST_RX_FF   : std_logic;
     -- signal rx_fifo_full_int_2 : std_logic;

     -- signal RST_spiXfer_done_FF        : std_logic;
     -- signal spiXfer_done_d1            : std_logic;
     -- signal spiXfer_done_d2, spiXfer_done_d3           : std_logic;
     -- signal spiXfer_done_cdc_from_spi_int_2 : std_logic;
     -- signal spiXfer_done_cdc_from_spi_int   : std_logic;

     -- signal Tx_FIFO_Empty_SPISR_cdc_from_spi_d1 : std_logic;
     -- signal Tx_FIFO_Empty_SPISR_cdc_from_spi_d2 : std_logic;

     -- signal reset_RX_FIFO_Rst_pulse : std_logic;
     -- signal SPICR_RX_FIFO_Rst_en_d1 : std_logic;
     -- signal SPICR_RX_FIFO_Rst_en    : std_logic;
     -- signal spisel_pulse_cdc_from_spi_int_2 : std_logic;
     -- signal SPISSR_cdc_from_axi_d1_and_reduce : std_logic;
-- signal drr_Overrun_int_cdc_from_spi_d1 : std_logic;
-- signal drr_Overrun_int_cdc_from_spi_d2 : std_logic;
-- signal drr_Overrun_int_cdc_from_spi_d3 : std_logic;
-- signal drr_Overrun_int_cdc_from_spi_int_2 : std_logic;

--------------------------
-- attribute ASYNC_REG : string;
-- attribute ASYNC_REG of CMD_ERR_S2AX_1_CDC          : label is "TRUE";
-- attribute ASYNC_REG of SPISEL_D1_REG_S2AX_1_CDC    : label is "TRUE";
-- attribute ASYNC_REG of SPISEL_PULSE_S2AX_1_CDC     : label is "TRUE";
-- attribute ASYNC_REG of MST_N_SLV_MODE_S2AX_1_CDC   : label is "TRUE";
-- -- attribute ASYNC_REG of SLAVE_MODF_STROBE_SYNC_SPI_2_AXI_1 : label is "TRUE";
-- attribute ASYNC_REG of RX_FIFO_EMPTY_AX2S_1_CDC    : label is "TRUE";
-- attribute ASYNC_REG of TX_FIFO_EMPTY_S2AX_1_CDC    : label is "TRUE";
-- attribute ASYNC_REG of TX_FIFO_FULL_AX2S_1_CDC     : label is "TRUE";
-- attribute ASYNC_REG of SPIXFER_DONE_S2AX_1_CDC     : label is "TRUE";
-- attribute ASYNC_REG of RX_FIFO_RST_AX2S_1_CDC      : label is "TRUE";  -- 3/25/2013
-- attribute ASYNC_REG of RX_FIFO_FULL_S2AX_1_CDC     : label is "TRUE";  -- 3/25/2013
-- attribute ASYNC_REG of SYNC_SPIXFER_DONE_S2AX_1_CDC: label is "TRUE";  -- 3/25/2013
-- attribute ASYNC_REG of DTR_UNDERRUN_S2AX_1_CDC     : label is "TRUE";  -- 3/25/2013

-- attribute ASYNC_REG of SPICR_0_LOOP_AX2S_1_CDC         : label is "TRUE";
-- attribute ASYNC_REG of SPICR_1_SPE_AX2S_1_CDC          : label is "TRUE";
-- attribute ASYNC_REG of SPICR_2_MST_N_SLV_AX2S_1_CDC    : label is "TRUE";
-- attribute ASYNC_REG of SPICR_3_CPOL_AX2S_1_CDC         : label is "TRUE";
-- attribute ASYNC_REG of SPICR_4_CPHA_AX2S_1_CDC         : label is "TRUE";
-- attribute ASYNC_REG of SPICR_5_TXFIFO_AX2S_1_CDC       : label is "TRUE";
-- attribute ASYNC_REG of SPICR_6_RXFIFO_RST_AX2S_1_CDC   : label is "TRUE";
-- attribute ASYNC_REG of SPICR_7_SS_AX2S_1_CDC           : label is "TRUE";
-- attribute ASYNC_REG of SPICR_8_TR_INHIBIT_AX2S_1_CDC   : label is "TRUE";
-- attribute ASYNC_REG of SPICR_9_LSB_AX2S_1_CDC          : label is "TRUE";
-- attribute ASYNC_REG of SR_3_MODF_AX2S_1_CDC            : label is "TRUE";
-- attribute ASYNC_REG of SLV_MODF_STRB_S2AX_1_CDC        : label is "TRUE";
-- attribute ASYNC_REG of MODF_STROBE_S2AX_1_CDC          : label is "TRUE";
-- attribute ASYNC_REG of TX_EMPT_4_SPISR_S2AX_1_CDC      : label is "TRUE";
-- attribute ASYNC_REG of DRR_OVERRUN_S2AX_1_CDC          : label is "TRUE"; -- 3/25/2013

attribute KEEP : string;
attribute KEEP of SPISR_0_CMD_Error_cdc_from_spi_d2: signal is "TRUE";
attribute KEEP of spisel_d1_reg_cdc_from_spi_d2: signal is "TRUE";
attribute KEEP of spisel_pulse_cdc_from_spi_d2: signal is "TRUE";
attribute KEEP of spisel_pulse_cdc_from_spi_d1: signal is "TRUE";
attribute KEEP of Mst_N_Slv_mode_cdc_from_spi_d2: signal is "TRUE";
attribute KEEP of Slave_MODF_strobe_cdc_from_spi_d2: signal is "TRUE";
attribute KEEP of Slave_MODF_strobe_cdc_from_spi_d1: signal is "TRUE";
attribute KEEP of modf_strobe_cdc_from_spi_d2      : signal is "TRUE";
attribute KEEP of modf_strobe_cdc_from_spi_d1      : signal is "TRUE";

constant LOGIC_CHANGE : integer range 0 to 1 := 1;
constant MTBF_STAGES_AXI2S : integer range 0 to 6 := 3 ;
constant MTBF_STAGES_S2AXI : integer range 0 to 6 := 4 ;
-----
begin
-----
SPISSR_cdc_from_axi_d1_and_reduce <= and_reduce(SPISSR_cdc_from_axi_d2);

LOGIC_GENERATION_FDR : if (Async_Clk = 0) generate
--==============================================================================
     CMD_ERR_S2AX_1_CDC: component FDR
                   generic map(INIT => '0' -- added on 16th Feb
                   )port map (
                              Q  => SPISR_0_CMD_Error_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => SPISR_0_CMD_Error_cdc_from_spi,
                              R  => Soft_Reset_op
                            );
     CMD_ERR_S2AX_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPISR_0_CMD_Error_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => SPISR_0_CMD_Error_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
     SPISR_0_CMD_Error_cdc_to_axi <= SPISR_0_CMD_Error_cdc_from_spi_d2;
     -----------------------------------------------------------
--==============================================================================
     SPISEL_D1_REG_S2AX_1_CDC: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => spisel_d1_reg_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => spisel_d1_reg_cdc_from_spi,
                              R  => Soft_Reset_op
                            );
     SPISEL_D1_REG_S2AX_2: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => spisel_d1_reg_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => spisel_d1_reg_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );

     spisel_d1_reg_cdc_to_axi <= spisel_d1_reg_cdc_from_spi_d2;
     -------------------------------------------------
--==============================================================================

     SPISEL_PULSE_STRETCH_1: process(EXT_SPI_CLK)is
     begin
          if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
                if(Rst_cdc_to_spi = '1') then
                        spisel_pulse_cdc_from_spi_int_2 <= '0';
                else
                        spisel_pulse_cdc_from_spi_int_2 <= --((not SPISSR_cdc_from_axi_d1_and_reduce) and
                                                      spisel_pulse_cdc_from_spi xor
                                                      spisel_pulse_cdc_from_spi_int_2;
                end if;
          end if;
     end process SPISEL_PULSE_STRETCH_1;

     SPISEL_PULSE_S2AX_1_CDC: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => spisel_pulse_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => spisel_pulse_cdc_from_spi_int_2, -- spisel_pulse_cdc_from_spi,
                              R  => Soft_Reset_op
                            );
     SPISEL_PULSE_S2AX_2: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => spisel_pulse_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => spisel_pulse_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
     SPISEL_PULSE_S2AX_3: component FDR    -- 2/21/2012
                   generic map(INIT => '1'
                   )port map (
                              Q  => spisel_pulse_cdc_from_spi_d3,
                              C  => Bus2IP_Clk,
                              D  => spisel_pulse_cdc_from_spi_d2,
                              R  => Soft_Reset_op
                            );

     -- spisel_pulse_cdc_to_axi <= spisel_pulse_cdc_from_spi_d2 xor spisel_pulse_cdc_from_spi_d1;
     spisel_pulse_cdc_to_axi <= spisel_pulse_cdc_from_spi_d3 xor spisel_pulse_cdc_from_spi_d2; -- 2/21/2012
     -----------------------------------------------
--==============================================================================
     MST_N_SLV_MODE_S2AX_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Mst_N_Slv_mode_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => Mst_N_Slv_mode_cdc_from_spi,
                              R  => Soft_Reset_op
                            );
     MST_N_SLV_MODE_S2AX_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Mst_N_Slv_mode_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => Mst_N_Slv_mode_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );

     Mst_N_Slv_mode_cdc_to_axi <= Mst_N_Slv_mode_cdc_from_spi_d2;
     ---------------------------------------------------
--==============================================================================

    SLAVE_MODF_STROBE_STRETCH_1: process(EXT_SPI_CLK)is
    begin
         if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
               if(Rst_cdc_to_spi = '1') then
                       Slave_MODF_strobe_cdc_from_spi_int_2 <= '0';
               else
                       Slave_MODF_strobe_cdc_from_spi_int_2 <= Slave_MODF_strobe_cdc_from_spi xor
                                                          Slave_MODF_strobe_cdc_from_spi_int_2;
               end if;
         end if;
    end process SLAVE_MODF_STROBE_STRETCH_1;
     
    SLV_MODF_STRB_S2AX_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Slave_MODF_strobe_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => Slave_MODF_strobe_cdc_from_spi_int_2,
                              R  => Soft_Reset_op
                            );
    SLV_MODF_STRB_S2AX_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Slave_MODF_strobe_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => Slave_MODF_strobe_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
    SLV_MODF_STRB_S2AX_3: component FDR -- 2/21/2012
                   generic map(INIT => '0'
                   )port map (
                              Q  => Slave_MODF_strobe_cdc_from_spi_d3,
                              C  => Bus2IP_Clk,
                              D  => Slave_MODF_strobe_cdc_from_spi_d2,
                              R  => Soft_Reset_op
                            );
    -- Slave_MODF_strobe_cdc_to_axi <= Slave_MODF_strobe_cdc_from_spi_d2 xor Slave_MODF_strobe_cdc_from_spi_d1; --spiXfer_done_cdc_from_spi_d2;
    Slave_MODF_strobe_cdc_to_axi <= Slave_MODF_strobe_cdc_from_spi_d3 xor Slave_MODF_strobe_cdc_from_spi_d2;-- 2/21/2012

--==============================================================================

    MODF_STROBE_STRETCH_1: process(EXT_SPI_CLK)is
    begin
         if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
               if(Rst_cdc_to_spi = '1') then
                       modf_strobe_cdc_from_spi_int_2 <= '0';
               else
                       modf_strobe_cdc_from_spi_int_2 <= modf_strobe_cdc_from_spi xor
                                                     modf_strobe_cdc_from_spi_int_2;
               end if;
         end if;
    end process MODF_STROBE_STRETCH_1;
    
    MODF_STROBE_S2AX_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => modf_strobe_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => modf_strobe_cdc_from_spi_int_2,
                              R  => Soft_Reset_op
                            );
    MODF_STROBE_S2AX_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => modf_strobe_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => modf_strobe_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
    MODF_STROBE_S2AX_3: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => modf_strobe_cdc_from_spi_d3,
                              C  => Bus2IP_Clk,
                              D  => modf_strobe_cdc_from_spi_d2,
                              R  => Soft_Reset_op
                            );
    -- modf_strobe_cdc_to_axi <= modf_strobe_cdc_from_spi_d2 xor modf_strobe_cdc_from_spi_d1; --spiXfer_done_cdc_from_spi_d2;
    modf_strobe_cdc_to_axi <= modf_strobe_cdc_from_spi_d3 xor modf_strobe_cdc_from_spi_d2; -- 2/21/2012
    -----------------------------------------------
--==============================================================================

     RX_FIFO_EMPTY_AX2S_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Rx_FIFO_Empty_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK, -- Bus2IP_Clk,
                              D  => Rx_FIFO_Empty_cdc_from_axi,
                              R  => Rst_cdc_to_spi   -- Soft_Reset_op
                            );
     RX_FIFO_EMPTY_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Rx_FIFO_Empty_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK, -- Bus2IP_Clk,
                              D  => Rx_FIFO_Empty_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi   -- Soft_Reset_op
                            );
     Rx_FIFO_Empty_cdc_to_spi <= Rx_FIFO_Empty_cdc_from_axi_d2;
     -------------------------------------------------
--==============================================================================

     TX_FIFO_EMPTY_S2AX_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Tx_FIFO_Empty_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => Tx_FIFO_Empty_cdc_from_spi,
                              R  => Soft_Reset_op
                            );
     TX_FIFO_EMPTY_S2AX_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Tx_FIFO_Empty_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => Tx_FIFO_Empty_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
     Tx_FIFO_Empty_cdc_to_axi <= Tx_FIFO_Empty_cdc_from_spi_d2;
     -------------------------------------------------
--==============================================================================

     TX_EMPT_4_SPISR_S2AX_1_CDC: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => Tx_FIFO_Empty_SPISR_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => Tx_FIFO_Empty_SPISR_cdc_from_spi,
                              R  => Soft_Reset_op
                            );
     TX_EMPT_4_SPISR_S2AX_2: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => Tx_FIFO_Empty_SPISR_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => Tx_FIFO_Empty_SPISR_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
      Tx_FIFO_Empty_SPISR_cdc_to_axi <= Tx_FIFO_Empty_SPISR_cdc_from_spi_d2;
--==============================================================================

     TX_FIFO_FULL_AX2S_1_CDC: component FDR
                    generic map(INIT => '0'
                   )port map (
                              Q  => Tx_FIFO_Full_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK, -- Bus2IP_Clk,
                              D  => Tx_FIFO_Full_cdc_from_axi,
                              R  => Rst_cdc_to_spi   -- Soft_Reset_op
                            );
     TX_FIFO_FULL_AX2S_2: component FDR
                    generic map(INIT => '0'
                   )port map (
                              Q  => Tx_FIFO_Full_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK, -- Bus2IP_Clk,
                              D  => Tx_FIFO_Full_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi   -- Soft_Reset_op
                            );
     Tx_FIFO_Full_cdc_to_spi <= Tx_FIFO_Full_cdc_from_axi_d2;
     -----------------------------------------------
--==============================================================================
     SPIXFER_DONE_S2AX_1_CDC: component FDR
                    generic map(INIT => '0'
                   )port map (
                              Q  => spiXfer_done_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => spiXfer_done_cdc_from_spi,
                              R  => Soft_Reset_op
                            );
     SPIXFER_DONE_S2AX_2: component FDR
                    generic map(INIT => '0'
                   )port map (
                              Q  => spiXfer_done_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => spiXfer_done_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
     spiXfer_done_cdc_to_axi <= spiXfer_done_cdc_from_spi_d2;
     -----------------------------------------------
     SPICR_RX_FIFO_Rst_en <= reset_RcFIFO_ptr_cdc_from_axi xor SPICR_RX_FIFO_Rst_en_d1;

     SPICR_RX_FIFO_RST_REG_SPI_DOMAIN_P:process(Bus2IP_Clk)is
     begin
     -----
          if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
              if(Soft_Reset_op = '1') then --  or reset_RX_FIFO_Rst_pulse = '1')then
                  SPICR_RX_FIFO_Rst_en_d1 <= '0';
              else
                  SPICR_RX_FIFO_Rst_en_d1 <= SPICR_RX_FIFO_Rst_en;
              end if;
          end if;
     end process SPICR_RX_FIFO_RST_REG_SPI_DOMAIN_P;
     -------------------------------------------------
     --reset_RcFIFO_ptr_cdc_to_spi <= reset_RcFIFO_ptr_cdc_from_axi_d2;
     RX_FIFO_RST_AX2S_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => reset_RcFIFO_ptr_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_RX_FIFO_Rst_en_d1,
                              R  => Rst_cdc_to_spi
                            );
     RX_FIFO_RST_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => reset_RcFIFO_ptr_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => reset_RcFIFO_ptr_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     reset_RcFIFO_ptr_cdc_to_spi <= reset_RcFIFO_ptr_cdc_from_axi_d1 xor
                                reset_RcFIFO_ptr_cdc_from_axi_d2;
     --reset_RcFIFO_ptr_cdc_to_spi <= reset_RcFIFO_ptr_cdc_from_axi_d2;
     -----------------------------------------------------------

     ------------------------------------------
     RX_FIFO_FULL_S2AX_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Rx_FIFO_Full_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => Rx_FIFO_Full_cdc_from_axi,
                              R  => Rst_cdc_to_spi
                            );
     RX_FIFO_FULL_S2AX_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Rx_FIFO_Full_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => Rx_FIFO_Full_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     Rx_FIFO_Full_cdc_to_spi <= Rx_FIFO_Full_cdc_from_axi_d2;

     ------------------------------------------
     SPI_XFER_DONE_STRETCH_1: process(EXT_SPI_CLK)is
     begin
          if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
                if(Rst_cdc_to_spi = '1') then
                        spiXfer_done_cdc_from_spi_int_2 <= '0';
                else
                        spiXfer_done_cdc_from_spi_int_2 <= spiXfer_done_cdc_from_spi xor
                                                      spiXfer_done_cdc_from_spi_int_2;
                end if;
          end if;
     end process SPI_XFER_DONE_STRETCH_1;

     SYNC_SPIXFER_DONE_S2AX_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => spiXfer_done_d1,
                              C  => Bus2IP_Clk,
                              D  => spiXfer_done_cdc_from_spi_int_2,
                              R  => Soft_Reset_op
                            );
     SYNC_SPIXFER_DONE_S2AX_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => spiXfer_done_d2,
                              C  => Bus2IP_Clk,
                              D  => spiXfer_done_d1,
                              R  => Soft_Reset_op
                            );
     SYNC_SPIXFER_DONE_S2AX_3: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => spiXfer_done_d3,
                              C  => Bus2IP_Clk,
                              D  => spiXfer_done_d2,
                              R  => Soft_Reset_op
                            );
     spiXfer_done_cdc_to_axi_1 <= spiXfer_done_d2 xor spiXfer_done_d3;
     -------------------------------------------------------------------------
    DTR_UNDERRUN_S2AX_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => dtr_underrun_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => dtr_underrun_cdc_from_spi,
                              R  => Soft_Reset_op
                            );
     DTR_UNDERRUN_S2AX_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => dtr_underrun_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => dtr_underrun_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
     dtr_underrun_cdc_to_axi <= dtr_underrun_cdc_from_spi_d2;
     -------------------------------------------------
     SPICR_0_LOOP_AX2S_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_0_LOOP_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_0_LOOP_cdc_from_axi,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_0_LOOP_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_0_LOOP_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_0_LOOP_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_0_LOOP_cdc_to_spi <= SPICR_0_LOOP_cdc_from_axi_d2;
     -----------------------------------------------

     SPICR_1_SPE_AX2S_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_1_SPE_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_1_SPE_cdc_from_axi,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_1_SPE_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_1_SPE_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_1_SPE_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_1_SPE_cdc_to_spi <= SPICR_1_SPE_cdc_from_axi_d2;
     ---------------------------------------------

     SPICR_2_MST_N_SLV_AX2S_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_2_MST_N_SLV_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_2_MST_N_SLV_cdc_from_axi,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_2_MST_N_SLV_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_2_MST_N_SLV_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_2_MST_N_SLV_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_2_MST_N_SLV_cdc_to_spi <= SPICR_2_MST_N_SLV_cdc_from_axi_d2;
     ---------------------------------------------------------

     SPICR_3_CPOL_AX2S_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_3_CPOL_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_3_CPOL_cdc_from_axi,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_3_CPOL_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_3_CPOL_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_3_CPOL_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_3_CPOL_cdc_to_spi <= SPICR_3_CPOL_cdc_from_axi_d2;
     -----------------------------------------------

     SPICR_4_CPHA_AX2S_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_4_CPHA_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_4_CPHA_cdc_from_axi,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_4_CPHA_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_4_CPHA_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_4_CPHA_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_4_CPHA_cdc_to_spi <= SPICR_4_CPHA_cdc_from_axi_d2;
     -----------------------------------------------

     SPICR_5_TXFIFO_AX2S_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_5_TXFIFO_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_5_TXFIFO_cdc_from_axi,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_5_TXFIFO_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_5_TXFIFO_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_5_TXFIFO_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_5_TXFIFO_cdc_to_spi <= SPICR_5_TXFIFO_cdc_from_axi_d2;
     ---------------------------------------------------

     SPICR_6_RXFIFO_RST_AX2S_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_6_RXFIFO_RST_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_6_RXFIFO_RST_cdc_from_axi,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_6_RXFIFO_RST_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_6_RXFIFO_RST_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_6_RXFIFO_RST_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_6_RXFIFO_RST_cdc_to_spi <= SPICR_6_RXFIFO_RST_cdc_from_axi_d2;
     -----------------------------------------------------------

     SPICR_7_SS_AX2S_1_CDC: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SPICR_7_SS_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_7_SS_cdc_from_axi,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_7_SS_AX2S_2: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SPICR_7_SS_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_7_SS_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_7_SS_cdc_to_spi <= SPICR_7_SS_cdc_from_axi_d2;
     -------------------------------------------

     SPICR_8_TR_INHIBIT_AX2S_1_CDC: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SPICR_8_TR_INHIBIT_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_8_TR_INHIBIT_cdc_from_axi,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_8_TR_INHIBIT_AX2S_2: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SPICR_8_TR_INHIBIT_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_8_TR_INHIBIT_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_8_TR_INHIBIT_cdc_to_spi <= SPICR_8_TR_INHIBIT_cdc_from_axi_d2;
     -----------------------------------------------------------

     SPICR_9_LSB_AX2S_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_9_LSB_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_9_LSB_cdc_from_axi,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_9_LSB_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_9_LSB_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_9_LSB_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     SPICR_9_LSB_cdc_to_spi <= SPICR_9_LSB_cdc_from_axi_d2;
     ---------------------------------------------

     SPICR_BITS_7_8_SYNC_GEN: for i in 1 downto 0 generate
     attribute ASYNC_REG : string;
     attribute ASYNC_REG of SPICR_BITS_7_8_AX2S_1_CDC : label is "TRUE";
     begin
     -----
     SPICR_BITS_7_8_AX2S_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_bits_7_8_cdc_from_axi_d1(i),
                              C  => EXT_SPI_CLK,
                              D  => SPICR_bits_7_8_cdc_from_axi(i),
                              R  => Rst_cdc_to_spi
                            );
     SPICR_BITS_7_8_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SPICR_bits_7_8_cdc_from_axi_d2(i),
                              C  => EXT_SPI_CLK,
                              D  => SPICR_bits_7_8_cdc_from_axi_d1(i),
                              R  => Rst_cdc_to_spi
                            );
     end generate SPICR_BITS_7_8_SYNC_GEN;
     -------------------------------------
     SPICR_bits_7_8_cdc_to_spi <= SPICR_bits_7_8_cdc_from_axi_d2;
     ---------------------------------------------------

     SR_3_MODF_AX2S_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SR_3_modf_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SR_3_modf_cdc_from_axi,
                              R  => Rst_cdc_to_spi
                            );
     SR_3_MODF_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => SR_3_modf_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => SR_3_modf_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     SR_3_modf_cdc_to_spi <= SR_3_modf_cdc_from_axi_d2;
     -----------------------------------------

     SPISSR_SYNC_GEN: for i in 0 to C_NUM_SS_BITS-1 generate
     attribute ASYNC_REG : string;
     attribute ASYNC_REG of SPISSR_AX2S_1_CDC : label is "TRUE";
     -----
     begin
     -----
     SPISSR_AX2S_1_CDC: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SPISSR_cdc_from_axi_d1(i),
                              C  => EXT_SPI_CLK,
                              D  => SPISSR_cdc_from_axi(i),
                              R  => Rst_cdc_to_spi
                            );
     SPISSR_SYNC_AXI_2_SPI_2: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SPISSR_cdc_from_axi_d2(i),
                              C  => EXT_SPI_CLK,
                              D  => SPISSR_cdc_from_axi_d1(i),
                              R  => Rst_cdc_to_spi
                            );
     end generate SPISSR_SYNC_GEN;

     SPISSR_cdc_to_spi <= SPISSR_cdc_from_axi_d2;
     -----------------------------------

     DRR_OVERRUN_STRETCH_1: process(EXT_SPI_CLK)is
     begin
          if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
                if(Rst_cdc_to_spi = '1') then
                        drr_Overrun_int_cdc_from_spi_int_2 <= '0';
                else
                        drr_Overrun_int_cdc_from_spi_int_2 <= drr_Overrun_int_cdc_from_spi xor
                                                      drr_Overrun_int_cdc_from_spi_int_2;
                end if;
          end if;
     end process DRR_OVERRUN_STRETCH_1;

     DRR_OVERRUN_S2AX_1_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => drr_Overrun_int_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => drr_Overrun_int_cdc_from_spi_int_2,
                              R  => Soft_Reset_op
                            );
     DRR_OVERRUN_S2AX_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => drr_Overrun_int_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => drr_Overrun_int_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
     DRR_OVERRUN_S2AX_3: component FDR -- 2/21/2012
                   generic map(INIT => '0'
                   )port map (
                              Q  => drr_Overrun_int_cdc_from_spi_d3,
                              C  => Bus2IP_Clk,
                              D  => drr_Overrun_int_cdc_from_spi_d2,
                              R  => Soft_Reset_op
                            );
    --drr_Overrun_int_cdc_to_axi <= drr_Overrun_int_cdc_from_spi_d2 xor drr_Overrun_int_cdc_from_spi_d1;
    drr_Overrun_int_cdc_to_axi <= drr_Overrun_int_cdc_from_spi_d3 xor drr_Overrun_int_cdc_from_spi_d2; -- 2/21/2012
	
 end generate LOGIC_GENERATION_FDR ;

 
 LOGIC_GENERATION_CDC : if Async_Clk = 1 generate
--==============================================================================

CMD_ERR_S2AX_1: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SPISR_0_CMD_Error_cdc_from_spi ,
        scndry_aclk          => Bus2IP_Clk ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out           => SPISR_0_CMD_Error_cdc_to_axi
    ); 
--==============================================================================

     
SPISEL_D1_REG_S2AX_1: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => spisel_d1_reg_cdc_from_spi ,
        scndry_aclk          => Bus2IP_Clk ,
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out           => spisel_d1_reg_cdc_to_axi
    ); 

--==============================================================================

SPISEL_PULSE_STRETCH_1: process(EXT_SPI_CLK)is
     begin
          if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
                if(Rst_cdc_to_spi = '1') then
                        spisel_pulse_cdc_from_spi_int_2 <= '0';
                else
                        spisel_pulse_cdc_from_spi_int_2 <= --((not SPISSR_cdc_from_axi_d1_and_reduce) and
                                                      spisel_pulse_cdc_from_spi xor
                                                      spisel_pulse_cdc_from_spi_int_2;
                end if;
          end if;
     end process SPISEL_PULSE_STRETCH_1;

     SPISEL_PULSE_S2AX_1_CDC: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => spisel_pulse_cdc_from_spi_d1,
                              C  => Bus2IP_Clk,
                              D  => spisel_pulse_cdc_from_spi_int_2, -- spisel_pulse_cdc_from_spi,
                              R  => Soft_Reset_op
                            );
     SPISEL_PULSE_S2AX_2: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => spisel_pulse_cdc_from_spi_d2,
                              C  => Bus2IP_Clk,
                              D  => spisel_pulse_cdc_from_spi_d1,
                              R  => Soft_Reset_op
                            );
     SPISEL_PULSE_S2AX_3: component FDR    -- 2/21/2012
                   generic map(INIT => '1'
                   )port map (
                              Q  => spisel_pulse_cdc_from_spi_d3,
                              C  => Bus2IP_Clk,
                              D  => spisel_pulse_cdc_from_spi_d2,
                              R  => Soft_Reset_op
                            );
    SPISEL_PULSE_S2AX_4: component FDR    -- 2/21/2012
                   generic map(INIT => '1'
                   )port map (
                              Q  => spisel_pulse_cdc_from_spi_d4,
                              C  => Bus2IP_Clk,
                              D  => spisel_pulse_cdc_from_spi_d3,
                              R  => Soft_Reset_op
                            );                        

     -- spisel_pulse_cdc_to_axi <= spisel_pulse_cdc_from_spi_d2 xor spisel_pulse_cdc_from_spi_d1;
     spisel_pulse_cdc_to_axi <= spisel_pulse_cdc_from_spi_d3 xor spisel_pulse_cdc_from_spi_d4;
--==============================================================================
    
MST_N_SLV_MODE_S2AX_1: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK , 
        prmry_resetn         => Rst_cdc_to_spi ,
        prmry_in             => Mst_N_Slv_mode_cdc_from_spi ,
        scndry_aclk          => Bus2IP_Clk ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out           => Mst_N_Slv_mode_cdc_to_axi
    ); 
--==============================================================================
SLAVE_MODF_STROBE_STRETCH_1_CDC: process(EXT_SPI_CLK)is
    begin
         if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
               if(Rst_cdc_to_spi = '1') then
                       Slave_MODF_strobe_cdc_from_spi_int_2 <= '0';
                       --Slave_MODF_strobe_cdc_from_spi_d1    <= '0';
               else
                       Slave_MODF_strobe_cdc_from_spi_int_2 <= Slave_MODF_strobe_cdc_from_spi xor
                                                          Slave_MODF_strobe_cdc_from_spi_int_2;
                       --Slave_MODF_strobe_cdc_from_spi_d1    <= Slave_MODF_strobe_cdc_from_spi_int_2;
               end if;
         end if;
    end process SLAVE_MODF_STROBE_STRETCH_1_CDC;
    
    SLV_MODF_STRB_S2AX_1: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_resetn         => Rst_cdc_to_spi ,
        prmry_in             => Slave_MODF_strobe_cdc_from_spi_int_2,--Slave_MODF_strobe_cdc_from_spi_d1 ,
        scndry_aclk          => Bus2IP_Clk ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out            => Slave_MODF_strobe_cdc_from_spi_d2
    ); 
	
	SLAVE_MODF_STROBE_STRETCH_1: process(Bus2IP_Clk)is
    begin
         if(Bus2IP_Clk'event and Bus2IP_Clk= '1') then
               
                       Slave_MODF_strobe_cdc_from_spi_d3 <= Slave_MODF_strobe_cdc_from_spi_d2 ;
               
         end if;
    end process SLAVE_MODF_STROBE_STRETCH_1;
	
    Slave_MODF_strobe_cdc_to_axi <= Slave_MODF_strobe_cdc_from_spi_d3 xor Slave_MODF_strobe_cdc_from_spi_d2;

--==============================================================================
MODF_STROBE_STRETCH_1_CDC: process(EXT_SPI_CLK)is
    begin
         if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
               if(Rst_cdc_to_spi = '1') then
                       modf_strobe_cdc_from_spi_int_2 <= '0';
                      -- modf_strobe_cdc_from_spi_d1    <= '0';
               else
                       modf_strobe_cdc_from_spi_int_2 <= modf_strobe_cdc_from_spi xor
                                                     modf_strobe_cdc_from_spi_int_2;
                      -- modf_strobe_cdc_from_spi_d1    <= modf_strobe_cdc_from_spi_int_2;
               end if;
         end if;
    end process MODF_STROBE_STRETCH_1_CDC;

    MODF_STROBE_S2AX_1: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_resetn         => Rst_cdc_to_spi ,
        prmry_in             => modf_strobe_cdc_from_spi_int_2,--modf_strobe_cdc_from_spi_d1 ,
        scndry_aclk          => Bus2IP_Clk ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out            => modf_strobe_cdc_from_spi_d2
    ); 
	MODF_STROBE_STRETCH_1: process(Bus2IP_Clk)is
    begin
         if(Bus2IP_Clk'event and Bus2IP_Clk= '1') then
               
                       modf_strobe_cdc_from_spi_d3 <= modf_strobe_cdc_from_spi_d2;
               
         end if;
    end process MODF_STROBE_STRETCH_1;
    modf_strobe_cdc_to_axi <= modf_strobe_cdc_from_spi_d3 xor modf_strobe_cdc_from_spi_d2;

--==============================================================================

   

    RX_FIFO_EMPTY_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK , 
        prmry_resetn         => Rst_cdc_to_spi ,
        prmry_in             => Rx_FIFO_Empty_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => Rx_FIFO_Empty_cdc_to_spi
    ); 
--==============================================================================
    

    TX_FIFO_EMPTY_S2AX_1: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => Tx_FIFO_Empty_cdc_from_spi ,
        scndry_aclk          => Bus2IP_Clk ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out           => Tx_FIFO_Empty_cdc_to_axi
    ); 
--==============================================================================

     TX_EMPT_4_SPISR_S2AX_1: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => Tx_FIFO_Empty_SPISR_cdc_from_spi ,
        scndry_aclk          => Bus2IP_Clk ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out           => Tx_FIFO_Empty_SPISR_cdc_to_axi
    ); 
--==============================================================================
   

    TX_FIFO_FULL_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_in             => Tx_FIFO_Full_cdc_from_axi ,
        scndry_aclk          => Bus2IP_Clk ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out           => Tx_FIFO_Full_cdc_to_spi
    ); 
--==============================================================================
    

SPIXFER_DONE_S2AX_1: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => spiXfer_done_cdc_from_spi ,
        scndry_aclk          => Bus2IP_Clk ,
		prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out           => spiXfer_done_cdc_to_axi
    ); 
--==============================================================================
    RX_FIFO_FULL_S2AX_1: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => Rx_FIFO_Full_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => Rx_FIFO_Full_cdc_to_spi
    ); 
--==============================================================================

SPI_XFER_DONE_STRETCH_1_CDC: process(EXT_SPI_CLK)is
     begin
          if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
                if(Rst_cdc_to_spi = '1') then
                        spiXfer_done_cdc_from_spi_int_2 <= '0';
                      --  spiXfer_done_d1            <= '0';
                else
                        spiXfer_done_cdc_from_spi_int_2 <= spiXfer_done_cdc_from_spi xor
                                                      spiXfer_done_cdc_from_spi_int_2;
                       -- spiXfer_done_d1            <= spiXfer_done_cdc_from_spi_int_2;
                end if;
          end if;
     end process SPI_XFER_DONE_STRETCH_1_CDC;
     
    SYNC_SPIXFER_DONE_S2AX_1: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_resetn         => Rst_cdc_to_spi ,
        prmry_in             => spiXfer_done_cdc_from_spi_int_2,--spiXfer_done_cdc_from_spi_int_2,--spiXfer_done_d1 ,
        scndry_aclk          => Bus2IP_Clk ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out            => spiXfer_done_d2
    ); 

SPI_XFER_DONE_STRETCH_1: process(Bus2IP_Clk)is
     begin
          if(Bus2IP_Clk'event and Bus2IP_Clk= '1') then
                
                        spiXfer_done_d3 <= spiXfer_done_d2;
                
          end if;
     end process SPI_XFER_DONE_STRETCH_1;
	 
    spiXfer_done_cdc_to_axi_1 <= spiXfer_done_d2 xor spiXfer_done_d3;
    
   --==============================================================================
   
    DTR_UNDERRUN_S2AX_1: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => dtr_underrun_cdc_from_spi ,
        scndry_aclk          => Bus2IP_Clk ,
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out           => dtr_underrun_cdc_to_axi
    ); 
   --==============================================================================
    
    SPICR_0_LOOP_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 ,  -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK , 
        prmry_resetn         => Rst_cdc_to_spi ,
        prmry_in             => SPICR_0_LOOP_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
		prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => SPICR_0_LOOP_cdc_to_spi
    ); 
    --==============================================================================
     
    SPICR_1_SPE_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK , 
        prmry_resetn         => Rst_cdc_to_spi ,
        prmry_in             => SPICR_1_SPE_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
		prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => SPICR_1_SPE_cdc_to_spi
    ); 
    --==============================================================================

     
    SPICR_2_MST_N_SLV_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
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
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => SPICR_2_MST_N_SLV_cdc_to_spi
    ); 
    --==============================================================================
     
    SPICR_3_CPOL_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
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
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => SPICR_3_CPOL_cdc_to_spi
    ); 
     --==============================================================================
     
    SPICR_4_CPHA_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
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
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => SPICR_4_CPHA_cdc_to_spi
    ); 
     --==============================================================================
        
    SPICR_5_TXFIFO_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => Bus2IP_Clk  , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SPICR_5_TXFIFO_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
		prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => SPICR_5_TXFIFO_cdc_to_spi
    ); 
  --==============================================================================
          
    SPICR_6_RXFIFO_RST_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
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
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => SPICR_6_RXFIFO_RST_cdc_to_spi
    ); 
   --==============================================================================
     
    SPICR_7_SS_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_resetn         => Soft_Reset_op  ,
        prmry_in             => SPICR_7_SS_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => SPICR_7_SS_cdc_to_spi
    ); 
    --==============================================================================
     
    SPICR_8_TR_INHIBIT_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_resetn         => Soft_Reset_op  ,
        prmry_in             => SPICR_8_TR_INHIBIT_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => SPICR_8_TR_INHIBIT_cdc_to_spi
    ); 
   --==============================================================================
     
    SPICR_9_LSB_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_resetn         => Soft_Reset_op  ,
        prmry_in             => SPICR_9_LSB_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => SPICR_9_LSB_cdc_to_spi
    ); 
   --==============================================================================
    
    SR_3_MODF_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
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
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => SR_3_modf_cdc_to_spi
    ); 
    --==============================================================================
     
    SPISSR_SYNC_GEN_CDC: for i in 0 to C_NUM_SS_BITS-1 generate
         attribute ASYNC_REG : string;
         attribute ASYNC_REG of SPISSR_AX2S_1_CDC : label is "TRUE";
         -----
     begin
    SPISSR_AX2S_1_CDC: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_in             => SPISSR_cdc_from_axi(i),
        scndry_aclk          => EXT_SPI_CLK,
        prmry_vect_in        => (others => '0' ),		
        scndry_resetn        => Rst_cdc_to_spi,
        scndry_out           => SPISSR_cdc_from_axi_d2(i)
    );
     end generate SPISSR_SYNC_GEN_CDC;
     
     SPISSR_cdc_to_spi <= SPISSR_cdc_from_axi_d2;
    
     -----------------------------------
     DRR_OVERRUN_STRETCH_1_CDC: process(EXT_SPI_CLK)is
          begin
               if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
                     if(Rst_cdc_to_spi = '1') then
                             drr_Overrun_int_cdc_from_spi_int_2 <= '0';
                            -- drr_Overrun_int_cdc_from_spi_d1    <= '0';
                     else
                             drr_Overrun_int_cdc_from_spi_int_2 <= drr_Overrun_int_cdc_from_spi xor
                                                      drr_Overrun_int_cdc_from_spi_int_2;
                             --drr_Overrun_int_cdc_from_spi_d1    <= drr_Overrun_int_cdc_from_spi_int_2;
                     end if;
               end if;
     end process DRR_OVERRUN_STRETCH_1_CDC;
     
	 DRR_OVERRUN_S2AX_1: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_resetn         => Rst_cdc_to_spi ,
        prmry_in             => drr_Overrun_int_cdc_from_spi_int_2,--drr_Overrun_int_cdc_from_spi_d1 ,
        scndry_aclk          => Bus2IP_Clk ,
	prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Soft_Reset_op ,
        scndry_out            => drr_Overrun_int_cdc_from_spi_d2
    ); 
	
	DRR_OVERRUN_STRETCH_1: process(Bus2IP_Clk)is
          begin
               if(Bus2IP_Clk'event and Bus2IP_Clk= '1') then
                     
                             drr_Overrun_int_cdc_from_spi_d3 <= drr_Overrun_int_cdc_from_spi_d2;
                    
               end if;
     end process DRR_OVERRUN_STRETCH_1;
    drr_Overrun_int_cdc_to_axi <= drr_Overrun_int_cdc_from_spi_d3 xor drr_Overrun_int_cdc_from_spi_d2;
    -------------------------------------------------------------
    
    
SPICR_RX_FIFO_Rst_en <= reset_RcFIFO_ptr_cdc_from_axi xor SPICR_RX_FIFO_Rst_en_d1;

SPICR_RX_FIFO_RST_REG_SPI_DOMAIN_P_CDC:process(Bus2IP_Clk)is
     begin
     -----
          if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
              if(Soft_Reset_op = '1') then --  or reset_RX_FIFO_Rst_pulse = '1')then
                  SPICR_RX_FIFO_Rst_en_d1 <= '0';
              else
                  SPICR_RX_FIFO_Rst_en_d1 <= SPICR_RX_FIFO_Rst_en;
              end if;
          end if;
     end process SPICR_RX_FIFO_RST_REG_SPI_DOMAIN_P_CDC;
	 
	     -------------------------------------------------
RX_FIFO_RST_AX2S_1: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => 1      --AXI to SPI as already 2 stages included
		)

    port map (
        prmry_aclk           => Bus2IP_Clk , 
        prmry_resetn         => Soft_Reset_op ,
        prmry_in             => SPICR_RX_FIFO_Rst_en_d1 ,
        scndry_aclk          => EXT_SPI_CLK ,
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_cdc_to_spi ,
        scndry_out           => SPICR_RX_FIFO_Rst_en_d2
    ); 
     --reset_RcFIFO_ptr_cdc_to_spi <= reset_RcFIFO_ptr_cdc_from_axi_d2;
          
     RX_FIFO_RST_AX2S_1_CDC_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => reset_RcFIFO_ptr_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => SPICR_RX_FIFO_Rst_en_d2,
                              R  => Rst_cdc_to_spi
                            );
     RX_FIFO_RST_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => reset_RcFIFO_ptr_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => reset_RcFIFO_ptr_cdc_from_axi_d1,
                              R  => Rst_cdc_to_spi
                            );
     reset_RcFIFO_ptr_cdc_to_spi <= reset_RcFIFO_ptr_cdc_from_axi_d1 xor
                                reset_RcFIFO_ptr_cdc_from_axi_d2;
     --reset_RcFIFO_ptr_cdc_to_spi <= reset_RcFIFO_ptr_cdc_from_axi_d2;
     
     ----------------------------------------------------------------------------------
     
   
	 
SPICR_BITS_7_8_SYNC_GEN_CDC: for i in 1 downto 0 generate
     attribute ASYNC_REG : string;
     attribute ASYNC_REG of SPICR_BITS_7_8_AX2S_1_CDC : label is "TRUE";
     begin
     -----
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
             prmry_aclk           => Bus2IP_Clk , 
             prmry_resetn         => Soft_Reset_op ,
             prmry_in             => SPICR_bits_7_8_cdc_from_axi(i) ,
             scndry_aclk          => EXT_SPI_CLK ,
	     prmry_vect_in        => (others => '0' ),
             scndry_resetn        => Rst_cdc_to_spi ,
             scndry_out           => SPICR_bits_7_8_cdc_from_axi_d2(i)
    ); 
     end generate SPICR_BITS_7_8_SYNC_GEN_CDC;
     -------------------------------------
     SPICR_bits_7_8_cdc_to_spi <= SPICR_bits_7_8_cdc_from_axi_d2;
	 
SPISR_0_CMD_Error_cdc_from_spi_d2 <= '0';	 
spisel_d1_reg_cdc_from_spi_d2 <= '0';	 
Mst_N_Slv_mode_cdc_from_spi_d2 <= '0';	 
slave_MODF_strobe_cdc_from_spi_d1 <= '0';	 
modf_strobe_cdc_from_spi_d1 <= '0';	 
	 
	 end generate LOGIC_GENERATION_CDC ;

	 
end architecture imp;
---------------------

