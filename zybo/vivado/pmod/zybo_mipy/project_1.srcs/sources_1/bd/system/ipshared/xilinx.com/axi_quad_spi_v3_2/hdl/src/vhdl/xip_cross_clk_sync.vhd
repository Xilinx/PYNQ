-------------------------------------------------------------------------------
-- xip_cross_clk_sync.vhd - Entity and architecture
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
-------------------------------------------------------------------------------
-- Filename:        xip_cross_clk_sync.vhd
-- Version:         v3.0
-- Description:     This is the CDC file for XIP mode
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
--
-- History:
-- ~~~~~~
--  SK 19/01/11  -- created v2.00.a version
-- ^^^^^^
-- 1. Created second version of the core.
-- ~~~~~~
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
library lib_fifo_v1_0_3;
    use lib_fifo_v1_0_3.async_fifo_fg;
library lib_cdc_v1_0_2;
	use lib_cdc_v1_0_2.cdc_sync;

library axi_quad_spi_v3_2_5;
    use axi_quad_spi_v3_2_5.all;
library unisim;
    use unisim.vcomponents.FDRE;
    use unisim.vcomponents.FDR;
-------------------------------------------------------------------------------
entity xip_cross_clk_sync is
     generic (
             C_S_AXI4_DATA_WIDTH          : integer;
             C_SPI_MEM_ADDR_BITS          : integer;
			 Async_Clk                    : integer ;

             C_NUM_SS_BITS                : integer
     );
     port (
              EXT_SPI_CLK               : in std_logic;

              S_AXI4_ACLK               : in std_logic;
              S_AXI4_ARESET             : in std_logic;

              S_AXI_ACLK                : in std_logic;
              S_AXI_ARESETN             : in std_logic;

              Rst_from_axi_cdc_to_spi       : in std_logic;
              ----------------------------
              spiXfer_done_cdc_from_spi      : in std_logic;
              spiXfer_done_cdc_to_axi_1     : out std_logic;
              ----------------------------
              mst_modf_err_cdc_from_spi      : in std_logic;
              mst_modf_err_cdc_to_axi       : out std_logic;
              mst_modf_err_cdc_to_axi4      : out std_logic;
              ----------------------------
              one_byte_xfer_cdc_from_axi     : in std_logic;
              one_byte_xfer_cdc_to_spi      : out std_logic;
              ----------------------
              two_byte_xfer_cdc_from_axi     : in std_logic;
              two_byte_xfer_cdc_to_spi      : out std_logic;
              ----------------------
              four_byte_xfer_cdc_from_axi    : in std_logic;
              four_byte_xfer_cdc_to_spi     : out std_logic;
              ----------------------
              Transmit_Addr_cdc_from_axi     : in std_logic_vector(C_SPI_MEM_ADDR_BITS-1 downto 0);
              Transmit_Addr_cdc_to_spi      : out std_logic_vector(C_SPI_MEM_ADDR_BITS-1 downto 0);
              ----------------------
              load_cmd_cdc_from_axi          : in std_logic;
              load_cmd_cdc_to_spi           : out std_logic;
              --------------------------
              CPOL_cdc_from_axi              : in std_logic;
              CPOL_cdc_to_spi               : out std_logic;
              --------------------------
              CPHA_cdc_from_axi              : in std_logic;
              CPHA_cdc_to_spi               : out std_logic;
              --------------------------
              SS_cdc_from_axi                : in std_logic_vector((C_NUM_SS_BITS-1) downto 0);
              SS_cdc_to_spi                 : out std_logic_vector((C_NUM_SS_BITS-1) downto 0);
              --------------------------
              type_of_burst_cdc_from_axi     : in std_logic;-- _vector(1 downto 0);
              type_of_burst_cdc_to_spi      : out std_logic;-- _vector(1 downto 0);
              --------------------------
              axi_length_cdc_from_axi        : in std_logic_vector(7 downto 0);
              axi_length_cdc_to_spi         : out std_logic_vector(7 downto 0);
              --------------------------
              dtr_length_cdc_from_axi        : in std_logic_vector(7 downto 0);
              dtr_length_cdc_to_spi         : out std_logic_vector(7 downto 0);
              --------------------------
              load_axi_data_cdc_from_axi     : in std_logic;
              load_axi_data_cdc_to_spi      : out std_logic;
              ------------------------------
              Rx_FIFO_Full_cdc_from_spi      : in std_logic;
              Rx_FIFO_Full_cdc_to_axi       : out std_logic;
              Rx_FIFO_Full_cdc_to_axi4      : out std_logic;
              ------------------------------
              wb_hpm_done_cdc_from_spi       : in std_logic;
              wb_hpm_done_cdc_to_axi        : out std_logic

);
end entity xip_cross_clk_sync;
-------------------------------------------------------------------------------
architecture imp of xip_cross_clk_sync is

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

signal size_length_cdc_to_spi_d1 : std_logic_vector(1 downto 0);
signal size_length_cdc_to_spi_d2 : std_logic_vector(1 downto 0);

signal spiXfer_done_d1            : std_logic;
signal spiXfer_done_d2            : std_logic;
signal spiXfer_done_d3            : std_logic;
signal spiXfer_done_cdc_from_spi_int_2 : std_logic;
signal byte_xfer_cdc_from_axi_d1       : std_logic;
signal byte_xfer_cdc_from_axi_d2       : std_logic;

signal hw_xfer_cdc_from_axi_d1         : std_logic;
signal hw_xfer_cdc_from_axi_d2         : std_logic;

signal word_xfer_cdc_from_axi_d1  : std_logic;
signal word_xfer_cdc_from_axi_d2  : std_logic;

signal SS_cdc_from_spi_d1 : std_logic_vector((C_NUM_SS_BITS-1) downto 0);
signal SS_cdc_from_spi_d2 : std_logic_vector((C_NUM_SS_BITS-1) downto 0);

signal mst_modf_err_d1 : std_logic;
signal mst_modf_err_d2 : std_logic;
signal mst_modf_err_d3 : std_logic;
signal mst_modf_err_d4 : std_logic;


signal dtr_length_cdc_from_axi_d1 : std_logic_vector(7 downto 0);
signal dtr_length_cdc_from_axi_d2 : std_logic_vector(7 downto 0);

signal axi_length_cdc_to_spi_d1 : std_logic_vector(7 downto 0);
signal axi_length_cdc_to_spi_d2 : std_logic_vector(7 downto 0);


signal CPOL_cdc_to_spi_d1 : std_logic;
signal CPOL_cdc_to_spi_d2 : std_logic;

signal CPHA_cdc_to_spi_d1 : std_logic;
signal CPHA_cdc_to_spi_d2 : std_logic;

signal load_axi_data_cdc_to_spi_d1 : std_logic;
signal load_axi_data_cdc_to_spi_d2 : std_logic;
signal load_axi_data_cdc_to_spi_d3 : std_logic;
signal Transmit_Addr_cdc_from_axi_d1 : std_logic_vector(C_SPI_MEM_ADDR_BITS-1 downto 0);
signal Transmit_Addr_cdc_from_axi_d2 : std_logic_vector(C_SPI_MEM_ADDR_BITS-1 downto 0);

signal type_of_burst_cdc_to_spi_d1 : std_logic;-- _vector(1 downto 0);
signal type_of_burst_cdc_to_spi_d2 : std_logic;-- _vector(1 downto 0);

     signal load_cmd_cdc_from_axi_d1 : std_logic;
     signal load_cmd_cdc_from_axi_d2 : std_logic;
     signal load_cmd_cdc_from_axi_d3 : std_logic;
     signal load_cmd_cdc_from_axi_int_2    : std_logic;

signal rx_fifo_full_d1 : std_logic;
signal rx_fifo_full_d2 : std_logic;
signal rx_fifo_full_d3 : std_logic;
signal rx_fifo_full_d4 : std_logic;
signal ld_axi_data_cdc_from_axi_int_2 : std_logic;
signal wb_hpm_done_cdc_from_spi_d1 : std_logic;
signal wb_hpm_done_cdc_from_spi_d2 : std_logic;



-- attribute ASYNC_REG : string;
-- attribute ASYNC_REG of XFER_DONE_SYNC_SPI2AXI     : label is "TRUE";
-- attribute ASYNC_REG of MST_MODF_SYNC_SPI2AXI      : label is "TRUE";
-- attribute ASYNC_REG of MST_MODF_SYNC_SPI2AXI4     : label is "TRUE";
-- attribute ASYNC_REG of BYTE_XFER_SYNC_AXI2SPI     : label is "TRUE";
-- attribute ASYNC_REG of HW_XFER_SYNC_AXI2SPI       : label is "TRUE";
-- attribute ASYNC_REG of WORD_XFER_SYNC_AXI2SPI     : label is "TRUE";
-- attribute ASYNC_REG of TYP_OF_XFER_SYNC_AXI2SPI   : label is "TRUE";
-- attribute ASYNC_REG of LD_AXI_DATA_SYNC_AXI2SPI   : label is "TRUE";
-- attribute ASYNC_REG of LD_CMD_SYNC_AXI2SPI        : label is "TRUE";

-- -- attribute ASYNC_REG of TRANSMIT_DATA_SYNC_AXI_2_SPI_1          : label is "TRUE";
-- attribute ASYNC_REG of CPOL_SYNC_AXI2SPI          : label is "TRUE";
-- attribute ASYNC_REG of CPHA_SYNC_AXI2SPI          : label is "TRUE";
-- attribute ASYNC_REG of Rx_FIFO_Full_SYNC_SPI2AXI  : label is "TRUE";
-- attribute ASYNC_REG of Rx_FIFO_Full_SYNC_SPI2AXI4 : label is "TRUE";
-- attribute ASYNC_REG of WB_HPM_DONE_SYNC_SPI2AXI   : label is "TRUE";

attribute KEEP : string;
attribute KEEP of SS_cdc_from_spi_d2              : signal is "TRUE";
attribute KEEP of load_axi_data_cdc_to_spi_d3    : signal is "TRUE";
attribute KEEP of load_axi_data_cdc_to_spi_d2    : signal is "TRUE";
attribute KEEP of type_of_burst_cdc_to_spi_d2    : signal is "TRUE";
attribute KEEP of rx_fifo_full_d2            : signal is "TRUE";
attribute KEEP of CPHA_cdc_to_spi_d2             : signal is "TRUE";
attribute KEEP of CPOL_cdc_to_spi_d2             : signal is "TRUE";
attribute KEEP of Transmit_Addr_cdc_from_axi_d2   : signal is "TRUE";
attribute KEEP of load_cmd_cdc_from_axi_d3        : signal is "TRUE";
attribute KEEP of load_cmd_cdc_from_axi_d2        : signal is "TRUE";
attribute KEEP of word_xfer_cdc_from_axi_d2       : signal is "TRUE";
attribute KEEP of hw_xfer_cdc_from_axi_d2         : signal is "TRUE";
attribute KEEP of byte_xfer_cdc_from_axi_d2       : signal is "TRUE";
attribute KEEP of mst_modf_err_d2            : signal is "TRUE";
attribute KEEP of mst_modf_err_d4            : signal is "TRUE";
attribute KEEP of spiXfer_done_d2            : signal is "TRUE";
attribute KEEP of spiXfer_done_d3            : signal is "TRUE";
attribute KEEP of axi_length_cdc_to_spi_d2	     : signal is "TRUE";
attribute KEEP of dtr_length_cdc_from_axi_d2     : signal is "TRUE";

constant LOGIC_CHANGE : integer range 0 to 1 := 1;
constant MTBF_STAGES_AXI2S : integer range 0 to 6 := 3 ;
constant MTBF_STAGES_S2AXI : integer range 0 to 6 := 4 ;
-----
begin

LOGIC_GENERATION_FDR : if (Async_Clk = 0) generate
-----
SPI_XFER_DONE_STRETCH_1: process(EXT_SPI_CLK)is
begin
-----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
           if(Rst_from_axi_cdc_to_spi = '1') then
                   spiXfer_done_cdc_from_spi_int_2 <= '0';
           else
                   spiXfer_done_cdc_from_spi_int_2 <= spiXfer_done_cdc_from_spi xor
                                                 spiXfer_done_cdc_from_spi_int_2;
           end if;
     end if;
end process SPI_XFER_DONE_STRETCH_1;

XFER_DONE_SYNC_SPI2AXI: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => spiXfer_done_d1,
                         C  => S_AXI4_ACLK,
                         D  => spiXfer_done_cdc_from_spi_int_2,
                         R  => S_AXI4_ARESET
                       );
FER_DONE_SYNC_SPI2AXI_1: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => spiXfer_done_d2,
                         C  => S_AXI4_ACLK,
                         D  => spiXfer_done_d1,
                         R  => S_AXI4_ARESET
                       );
FER_DONE_SYNC_SPI2AXI_2: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => spiXfer_done_d3,
                         C  => S_AXI4_ACLK,
                         D  => spiXfer_done_d2,
                         R  => S_AXI4_ARESET
                       );
spiXfer_done_cdc_to_axi_1 <= spiXfer_done_d2 xor spiXfer_done_d3;
-------------------------------------------------------------------------------
MST_MODF_SYNC_SPI2AXI: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => mst_modf_err_d1,
                         C  => S_AXI_ACLK,
                         D  => mst_modf_err_cdc_from_spi,
                         R  => S_AXI_ARESETN
                       );
MST_MODF_SYNC_SPI2AXI_1: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => mst_modf_err_d2,
                         C  => S_AXI_ACLK,
                         D  => mst_modf_err_d1,
                         R  => S_AXI_ARESETN
                       );
mst_modf_err_cdc_to_axi <= mst_modf_err_d2;
-------------------------------------------------------------------------------
MST_MODF_SYNC_SPI2AXI4: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => mst_modf_err_d3,
                         C  => S_AXI4_ACLK,
                         D  => mst_modf_err_cdc_from_spi,
                         R  => S_AXI4_ARESET
                       );
MST_MODF_SYNC_SPI2AXI4_1: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => mst_modf_err_d4,
                         C  => S_AXI4_ACLK,
                         D  => mst_modf_err_d3,
                         R  => S_AXI4_ARESET
                       );
mst_modf_err_cdc_to_axi4 <= mst_modf_err_d4;
-------------------------------------------------------------------------------
BYTE_XFER_SYNC_AXI2SPI: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => byte_xfer_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => one_byte_xfer_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     BYTE_XFER_SYNC_AXI2SPI_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => byte_xfer_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => byte_xfer_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );

     one_byte_xfer_cdc_to_spi <= byte_xfer_cdc_from_axi_d2;
     ------------------------------------------------
     HW_XFER_SYNC_AXI2SPI: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => hw_xfer_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => two_byte_xfer_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     HW_XFER_SYNC_AXI2SPI_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => hw_xfer_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => hw_xfer_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );

     two_byte_xfer_cdc_to_spi <= hw_xfer_cdc_from_axi_d2;
     ------------------------------------------------
     WORD_XFER_SYNC_AXI2SPI: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => word_xfer_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => four_byte_xfer_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     WORD_XFER_SYNC_AXI2SPI_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => word_xfer_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => word_xfer_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );

     four_byte_xfer_cdc_to_spi <= word_xfer_cdc_from_axi_d2;
     ------------------------------------------------
     LD_CMD_cdc_from_AXI_STRETCH: process(S_AXI4_ACLK)is
     begin
     -----
          if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1')then
                if(S_AXI4_ARESET = '1')then
                    load_cmd_cdc_from_axi_int_2 <= '0';
                else
                    load_cmd_cdc_from_axi_int_2 <= load_cmd_cdc_from_axi xor load_cmd_cdc_from_axi_int_2;
                end if;
          end if;
     end process LD_CMD_cdc_from_AXI_STRETCH;
     -------------------------------------
-- from AXI4 to SPI
LD_CMD_SYNC_AXI2SPI: component FDR
                   port map (
                              Q  => load_cmd_cdc_from_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => load_cmd_cdc_from_axi_int_2,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     LD_CMD_SYNC_AXI2SPI_1: component FDR
                   port map (
                              Q  => load_cmd_cdc_from_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => load_cmd_cdc_from_axi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     LD_CMD_SYNC_AXI2SPI_2: component FDR
                   port map (
                              Q  => load_cmd_cdc_from_axi_d3,
                              C  => EXT_SPI_CLK,
                              D  => load_cmd_cdc_from_axi_d2,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     load_cmd_cdc_to_spi          <= load_cmd_cdc_from_axi_d3 xor
                                 load_cmd_cdc_from_axi_d2;
     --------------------------------------------------------------------------
-- from AXI4 to SPI
     TRANS_ADDR_SYNC_GEN: for i in C_SPI_MEM_ADDR_BITS-1 downto 0 generate
     attribute ASYNC_REG : string;
     attribute ASYNC_REG of TRANS_ADDR_SYNC_AXI2SPI_CDC  : label is "TRUE";

     -----
     begin
     -----
     TRANS_ADDR_SYNC_AXI2SPI_CDC: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Transmit_Addr_cdc_from_axi_d1(i),
                              C  => EXT_SPI_CLK,
                              D  => Transmit_Addr_cdc_from_axi(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
     TRANS_ADDR_SYNC_AXI2SPI_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Transmit_Addr_cdc_from_axi_d2(i),
                              C  => EXT_SPI_CLK,
                              D  => Transmit_Addr_cdc_from_axi_d1(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
     end generate TRANS_ADDR_SYNC_GEN;
     -- Transmit_Addr_cdc_to_spi <= Transmit_Addr_cdc_from_axi_d2; -- 4/19/2013
     Transmit_Addr_cdc_to_spi <= Transmit_Addr_cdc_from_axi_d1; -- 4/19/2013
     ------------------------------------------------
     -- from AXI4 Lite to SPI
     CPOL_SYNC_AXI2SPI: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => CPOL_cdc_to_spi_d1,
                              C  => EXT_SPI_CLK,
                              D  => CPOL_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     CPOL_SYNC_AXI2SPI_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => CPOL_cdc_to_spi_d2,
                              C  => EXT_SPI_CLK,
                              D  => CPOL_cdc_to_spi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     CPOL_cdc_to_spi <= CPOL_cdc_to_spi_d2;
     ------------------------------------------------
     -- from AXI4 Lite to SPI
     CPHA_SYNC_AXI2SPI: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => CPHA_cdc_to_spi_d1,
                              C  => EXT_SPI_CLK,
                              D  => CPHA_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     CPHA_SYNC_AXI2SPI_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => CPHA_cdc_to_spi_d2,
                              C  => EXT_SPI_CLK,
                              D  => CPHA_cdc_to_spi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     CPHA_cdc_to_spi <= CPHA_cdc_to_spi_d2;
     ------------------------------------------------
     LD_AXI_DATA_STRETCH: process(S_AXI4_ACLK)is
     begin
     -----
          if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1')then
                if(S_AXI4_ARESET = '1')then
                    ld_axi_data_cdc_from_axi_int_2 <= '0';
                else
                    ld_axi_data_cdc_from_axi_int_2 <= load_axi_data_cdc_from_axi xor
                                                 ld_axi_data_cdc_from_axi_int_2;
                end if;
          end if;
     end process LD_AXI_DATA_STRETCH;
     -------------------------------------
     LD_AXI_DATA_SYNC_AXI2SPI: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => load_axi_data_cdc_to_spi_d1,
                              C  => EXT_SPI_CLK,
                              D  => ld_axi_data_cdc_from_axi_int_2,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     LD_AXI_DATA_SYNC_AXI2SPI_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => load_axi_data_cdc_to_spi_d2,
                              C  => EXT_SPI_CLK,
                              D  => load_axi_data_cdc_to_spi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     LD_AXI_DATA_SYNC_AXI2SPI_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => load_axi_data_cdc_to_spi_d3,
                              C  => EXT_SPI_CLK,
                              D  => load_axi_data_cdc_to_spi_d2,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     load_axi_data_cdc_to_spi <= load_axi_data_cdc_to_spi_d3 xor load_axi_data_cdc_to_spi_d2;
     ------------------------------------------------
     SS_SYNC_AXI_SPI_GEN: for i in (C_NUM_SS_BITS-1) downto 0 generate
     ---------------------
     attribute ASYNC_REG : string;
     attribute ASYNC_REG of SS_SYNC_AXI2SPI_CDC : label is "TRUE";
     begin
     -----
          SS_SYNC_AXI2SPI_CDC: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SS_cdc_from_spi_d1(i),
                              C  => EXT_SPI_CLK,
                              D  => SS_cdc_from_axi(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
          SS_SYNC_AXI2SPI_1: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => SS_cdc_from_spi_d2(i),
                              C  => EXT_SPI_CLK,
                              D  => SS_cdc_from_spi_d1(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
     end generate SS_SYNC_AXI_SPI_GEN;

     SS_cdc_to_spi <= SS_cdc_from_spi_d2;
     ------------------------------------------------------------------------
     TYP_OF_XFER_SYNC_AXI2SPI: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => type_of_burst_cdc_to_spi_d1,
                              C  => EXT_SPI_CLK,
                              D  => type_of_burst_cdc_from_axi,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     TYP_OF_XFER_SYNC_AXI2SPI_1: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => type_of_burst_cdc_to_spi_d2,
                              C  => EXT_SPI_CLK,
                              D  => type_of_burst_cdc_to_spi_d1,
                              R  => Rst_from_axi_cdc_to_spi
                            );
     --end generate TYP_OF_XFER_GEN;
     ------------------------------
     type_of_burst_cdc_to_spi   <= type_of_burst_cdc_to_spi_d2;
     ------------------------------------------------
     AXI_LEN_SYNC_AXI_SPI_GEN: for i in 7 downto 0 generate
     ---------------------
     attribute ASYNC_REG : string;
     attribute ASYNC_REG of AXI_LEN_SYNC_AXI2SPI : label is "TRUE";
     begin
     -----
          AXI_LEN_SYNC_AXI2SPI: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => axi_length_cdc_to_spi_d1(i),
                              C  => EXT_SPI_CLK,
                              D  => axi_length_cdc_from_axi(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
          AXI_LEN_SYNC_AXI2SPI_1: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => axi_length_cdc_to_spi_d2(i),
                              C  => EXT_SPI_CLK,
                              D  => axi_length_cdc_to_spi_d1(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
     end generate AXI_LEN_SYNC_AXI_SPI_GEN;
     axi_length_cdc_to_spi <= axi_length_cdc_to_spi_d2;
     ------------------------------------------------------------------------
     DTR_LEN_SYNC_AXI_SPI_GEN: for i in 7 downto 0 generate
     ---------------------
     attribute ASYNC_REG : string;
     attribute ASYNC_REG of DTR_LEN_SYNC_AXI2SPI : label is "TRUE";
     begin
     -----
          DTR_LEN_SYNC_AXI2SPI: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => dtr_length_cdc_from_axi_d1(i),
                              C  => EXT_SPI_CLK,
                              D  => dtr_length_cdc_from_axi(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
          DTR_LEN_SYNC_AXI2SPI_1: component FDR
                   generic map(INIT => '1'
                   )port map (
                              Q  => dtr_length_cdc_from_axi_d2(i),
                              C  => EXT_SPI_CLK,
                              D  => dtr_length_cdc_from_axi_d1(i),
                              R  => Rst_from_axi_cdc_to_spi
                            );
     end generate DTR_LEN_SYNC_AXI_SPI_GEN;
     dtr_length_cdc_to_spi <= dtr_length_cdc_from_axi_d2;
     ------------------------------------------------------------------------
-- from SPI to AXI Lite
Rx_FIFO_Full_SYNC_SPI2AXI: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => rx_fifo_full_d1,
                         C  => S_AXI_ACLK,
                         D  => Rx_FIFO_Full_cdc_from_spi,
                         R  => S_AXI_ARESETN
                       );
Rx_FIFO_Full_SYNC_SPI2AXI_1: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => rx_fifo_full_d2,
                         C  => S_AXI_ACLK,
                         D  => rx_fifo_full_d1,
                         R  => S_AXI_ARESETN
                       );
Rx_FIFO_Full_cdc_to_axi <= rx_fifo_full_d2;
-------------------------------------------------------------------------------
-- from SPI to AXI4
Rx_FIFO_Full_SYNC_SPI2AXI4: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => rx_fifo_full_d3,
                         C  => S_AXI4_ACLK,
                         D  => Rx_FIFO_Full_cdc_from_spi,
                         R  => S_AXI4_ARESET
                       );
Rx_FIFO_Full_SYNC_SPI2AXI4_1: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => rx_fifo_full_d4,
                         C  => S_AXI4_ACLK,
                         D  => rx_fifo_full_d3,
                         R  => S_AXI4_ARESET
                       );
Rx_FIFO_Full_cdc_to_axi4 <= rx_fifo_full_d4;
-------------------------------------------------------------------------------
-- from SPI to AXI4
WB_HPM_DONE_SYNC_SPI2AXI: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => wb_hpm_done_cdc_from_spi_d1,
                         C  => S_AXI4_ACLK,
                         D  => wb_hpm_done_cdc_from_spi,
                         R  => S_AXI4_ARESET
                       );
WB_HPM_DONE_SYNC_SPI2AXI_1: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => wb_hpm_done_cdc_from_spi_d2,
                         C  => S_AXI4_ACLK,
                         D  => wb_hpm_done_cdc_from_spi_d1,
                         R  => S_AXI4_ARESET
                       );
wb_hpm_done_cdc_to_axi <= wb_hpm_done_cdc_from_spi_d2;
-------------------------------------------------------------------------------
end generate LOGIC_GENERATION_FDR;


LOGIC_GENERATION_CDC : if (Async_Clk = 1) generate
-------------------------------------------------------------------------------
SPI_XFER_DONE_STRETCH_1: process(EXT_SPI_CLK)is
begin
-----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK= '1') then
     
           if(Rst_from_axi_cdc_to_spi = '1') then
                   spiXfer_done_cdc_from_spi_int_2 <= '0';
				   --spiXfer_done_d1            <= '0';
           else
                   spiXfer_done_cdc_from_spi_int_2 <= spiXfer_done_cdc_from_spi xor spiXfer_done_cdc_from_spi_int_2;
				   --spiXfer_done_d1            <= spiXfer_done_cdc_from_spi_int_2;
           end if;
     end if;
end process SPI_XFER_DONE_STRETCH_1;

XFER_DONE_SYNC_SPI2AXI_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 2 is ack based level sync
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 1 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK , 
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => spiXfer_done_cdc_from_spi_int_2,--spiXfer_done_d1 ,
        scndry_aclk          => S_AXI4_ACLK ,
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => S_AXI4_ARESET ,
        scndry_out            => spiXfer_done_d2
    ); 
	
	SPI_XFER_DONE_STRETCH_1_CDC: process(S_AXI4_ACLK)is
begin
-----
     if(S_AXI4_ACLK'event and S_AXI4_ACLK= '1') then
     
           if(S_AXI4_ARESET = '1') then
                   spiXfer_done_d3 <= '0';
				  
           else
                   spiXfer_done_d3 <= spiXfer_done_d2 ;
           end if;
     end if;
end process SPI_XFER_DONE_STRETCH_1_CDC;

spiXfer_done_cdc_to_axi_1 <= spiXfer_done_d2 xor spiXfer_done_d3;
-------------------------------------------------------------------------------

MST_MODF_SYNC_SPI2AXI_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => S_AXI_ACLK , 
        prmry_resetn         => S_AXI_ARESETN ,
        prmry_in             => mst_modf_err_cdc_from_spi ,
        scndry_aclk          => S_AXI_ACLK ,
	    prmry_vect_in        => (others => '0' ), 
        scndry_resetn        => S_AXI_ARESETN ,
        scndry_out           => mst_modf_err_cdc_to_axi
    ); 
-------------------------------------------------------------------------------


MST_MODF_SYNC_SPI2AXI4_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => S_AXI4_ACLK , 
        prmry_resetn         => S_AXI4_ARESET ,
        prmry_in             => mst_modf_err_cdc_from_spi ,
        scndry_aclk          => S_AXI4_ACLK ,
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => S_AXI4_ARESET ,
        scndry_out           => mst_modf_err_cdc_to_axi4
    ); 
-------------------------------------------------------------------------------

BYTE_XFER_SYNC_AXI2SPI_CDC: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => one_byte_xfer_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
		prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => one_byte_xfer_cdc_to_spi
    ); 
-------------------------------------------------------------------------------
HW_XFER_SYNC_AXI2SPI_CDC: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => two_byte_xfer_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
		prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => two_byte_xfer_cdc_to_spi
    ); 
-------------------------------------------------------------------------------

WORD_XFER_SYNC_AXI2SPI_CDC: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => four_byte_xfer_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => four_byte_xfer_cdc_to_spi
    ); 
-------------------------------------------------------------------------------

LD_CMD_cdc_from_AXI_STRETCH_CDC: process(S_AXI4_ACLK)is
     begin
     -----
          if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1')then
                if(S_AXI4_ARESET = '1')then
                    load_cmd_cdc_from_axi_int_2 <= '0';
                    --load_cmd_cdc_from_axi_d1    <= '0';
                else
                    load_cmd_cdc_from_axi_int_2 <= load_cmd_cdc_from_axi xor load_cmd_cdc_from_axi_int_2;
                    --load_cmd_cdc_from_axi_d1    <= load_cmd_cdc_from_axi_int_2;
                end if;
          end if;
     end process LD_CMD_cdc_from_AXI_STRETCH_CDC;

 LD_CMD_SYNC_AXI2SPI_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 2 is ack based level sync
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 1 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => S_AXI4_ACLK , 
        prmry_resetn         => S_AXI4_ARESET ,
        prmry_in             => load_cmd_cdc_from_axi_int_2,--load_cmd_cdc_from_axi_d1 ,
        scndry_aclk          => EXT_SPI_CLK ,
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out            => load_cmd_cdc_from_axi_d2
    ); 
	
	LD_CMD_cdc_from_AXI_STRETCH: process(EXT_SPI_CLK)is
     begin
     -----
          if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                if(Rst_from_axi_cdc_to_spi = '1')then
                    load_cmd_cdc_from_axi_d3 <= '0';
                    
                else
                    load_cmd_cdc_from_axi_d3 <= load_cmd_cdc_from_axi_d2;
                end if;
          end if;
     end process LD_CMD_cdc_from_AXI_STRETCH;
     
          load_cmd_cdc_to_spi          <= load_cmd_cdc_from_axi_d3 xor
                                 load_cmd_cdc_from_axi_d2;
-------------------------------------------------------------------------------

  

TRANS_ADDR_SYNC_GEN_CDC: for i in C_SPI_MEM_ADDR_BITS-1 downto 0 generate
     attribute ASYNC_REG : string;
     attribute ASYNC_REG of TRANS_ADDR_SYNC_AXI2SPI_CDC  : label is "TRUE";

     -----
     begin
     -----
     
 TRANS_ADDR_SYNC_AXI2SPI_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 ,-- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK,
        prmry_resetn         => Rst_from_axi_cdc_to_spi,
        prmry_in             => Transmit_Addr_cdc_from_axi(i),
        scndry_aclk          => EXT_SPI_CLK, 
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi,
        scndry_out           => Transmit_Addr_cdc_from_axi_d2(i)
    );
    
    end generate TRANS_ADDR_SYNC_GEN_CDC;
    Transmit_Addr_cdc_to_spi <= Transmit_Addr_cdc_from_axi_d2;
-------------------------------------------------------------------------------


CPOL_SYNC_AXI2SPI_CDC: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => CPOL_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => CPOL_cdc_to_spi
    ); 
	
	-------------------------------------------------------------------------------
	
		
   CPHA_SYNC_AXI2SPI_CDC: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => CPHA_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => CPHA_cdc_to_spi
    ); 
    -------------------------------------------------------------------------------
    
    LD_AXI_DATA_STRETCH_CDC: process(S_AXI4_ACLK)is
         begin
         -----
              if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1')then
                    if(S_AXI4_ARESET = '1')then
                        ld_axi_data_cdc_from_axi_int_2 <= '0';
                        --load_axi_data_cdc_to_spi_d1   <= '0';
                    else
                        ld_axi_data_cdc_from_axi_int_2 <= load_axi_data_cdc_from_axi xor
                                                 ld_axi_data_cdc_from_axi_int_2;
                       -- load_axi_data_cdc_to_spi_d1   <= ld_axi_data_cdc_from_axi_int_2;
                    end if;
              end if;
     end process LD_AXI_DATA_STRETCH_CDC;
    
   LD_AXI_DATA_SYNC_AXI2SPI_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 2 is ack based level sync
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 1 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => S_AXI4_ACLK , 
        prmry_resetn         => S_AXI4_ARESET ,
        prmry_in             => ld_axi_data_cdc_from_axi_int_2,--load_axi_data_cdc_to_spi_d1 ,
	prmry_vect_in        => (others => '0' ),
        scndry_aclk          => EXT_SPI_CLK ,
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out            => load_axi_data_cdc_to_spi_d2
    ); 
	
	LD_AXI_DATA_STRETCH: process(EXT_SPI_CLK)is
         begin
         -----
              if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                    if(Rst_from_axi_cdc_to_spi = '1')then
                        load_axi_data_cdc_to_spi_d3 <= '0';
                        
                    else
                        load_axi_data_cdc_to_spi_d3 <= load_axi_data_cdc_to_spi_d2 ;
                    end if;
              end if;
     end process LD_AXI_DATA_STRETCH;
     
      load_axi_data_cdc_to_spi <= load_axi_data_cdc_to_spi_d3 xor load_axi_data_cdc_to_spi_d2;
	---------------------------------------------------------------------------------------
	
	     
	SS_SYNC_AXI_SPI_GEN_CDC: for i in (C_NUM_SS_BITS-1) downto 0 generate
	     ---------------------
	     attribute ASYNC_REG : string;
	     attribute ASYNC_REG of SS_SYNC_AXI2SPI_CDC : label is "TRUE";
     begin
    SS_SYNC_AXI2SPI_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK,
        prmry_resetn         => Rst_from_axi_cdc_to_spi,
        prmry_in             => SS_cdc_from_axi(i),
        scndry_aclk          => EXT_SPI_CLK, 
        scndry_resetn        => Rst_from_axi_cdc_to_spi,
	    prmry_vect_in        => (others => '0' ),
        scndry_out           => SS_cdc_from_spi_d2(i)
    );
    end generate SS_SYNC_AXI_SPI_GEN_CDC;
    SS_cdc_to_spi <= SS_cdc_from_spi_d2;
    
     ------------------------------------------------------------------------------------------
     
       
	 
	 TYP_OF_XFER_SYNC_AXI2SPI_CDC: entity lib_cdc_v1_0_2.cdc_sync
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
        prmry_resetn         => Rst_from_axi_cdc_to_spi ,
        prmry_in             => type_of_burst_cdc_from_axi ,
        scndry_aclk          => EXT_SPI_CLK ,
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi ,
        scndry_out           => type_of_burst_cdc_to_spi
    ); 
	---------------------------------------------------------------------------------------
	
	     
	AXI_LEN_SYNC_AXI_SPI_GEN_CDC: for i in 7 downto 0 generate
	     ---------------------
	     attribute ASYNC_REG : string;
	     attribute ASYNC_REG of AXI_LEN_SYNC_AXI2SPI_CDC : label is "TRUE";
     begin
     -------------
    AXI_LEN_SYNC_AXI2SPI_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK,
        prmry_resetn         => Rst_from_axi_cdc_to_spi,
        prmry_in             => axi_length_cdc_from_axi(i),
        scndry_aclk          => EXT_SPI_CLK, 
	    prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi,
        scndry_out           => axi_length_cdc_to_spi_d2(i)
    );
    end generate AXI_LEN_SYNC_AXI_SPI_GEN_CDC;
     axi_length_cdc_to_spi <= axi_length_cdc_to_spi_d2;
     ---------------------------------------------------------------------------------------
     
          
     DTR_LEN_SYNC_AXI_SPI_GEN_CDC: for i in 7 downto 0 generate
          ---------------------
          attribute ASYNC_REG : string;
          attribute ASYNC_REG of DTR_LEN_SYNC_AXI2SPI_CDC : label is "TRUE";
          begin
     -----
    DTR_LEN_SYNC_AXI2SPI_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2S 
		)

    port map (
        prmry_aclk           => EXT_SPI_CLK,
        prmry_resetn         => Rst_from_axi_cdc_to_spi,
        prmry_in             => dtr_length_cdc_from_axi(i),
        scndry_aclk          => EXT_SPI_CLK, 
		prmry_vect_in        => (others => '0' ),
        scndry_resetn        => Rst_from_axi_cdc_to_spi,
        scndry_out            => dtr_length_cdc_from_axi_d2(i)
    );
    end generate DTR_LEN_SYNC_AXI_SPI_GEN_CDC;
     dtr_length_cdc_to_spi <= dtr_length_cdc_from_axi_d2;
     ------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------
	 
	 
	 	 
	 Rx_FIFO_Full_SYNC_SPI2AXI_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => S_AXI_ACLK , 
        prmry_resetn         => S_AXI_ARESETN ,
        prmry_in             => Rx_FIFO_Full_cdc_from_spi ,
	prmry_vect_in        => (others => '0' ),
        scndry_aclk          => S_AXI_ACLK ,
        scndry_resetn        => S_AXI_ARESETN ,
        scndry_out           => Rx_FIFO_Full_cdc_to_axi
    ); 
     ------------------------------------------------------------------------
     
     	     
 Rx_FIFO_Full_SYNC_SPI2AXI4_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => S_AXI4_ACLK , 
        prmry_resetn         => S_AXI4_ARESET ,
        prmry_in             => Rx_FIFO_Full_cdc_from_spi ,
	prmry_vect_in        => (others => '0' ),
        scndry_aclk          => S_AXI4_ACLK ,
        scndry_resetn        => S_AXI4_ARESET ,
        scndry_out           => Rx_FIFO_Full_cdc_to_axi4
    ); 
-------------------------------------------------------------------------------
	     

WB_HPM_DONE_SYNC_SPI2AXI_CDC: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_S2AXI 
		)

    port map (
        prmry_aclk           => S_AXI4_ACLK , 
        prmry_resetn         => S_AXI4_ARESET ,
        prmry_in             => wb_hpm_done_cdc_from_spi ,
	prmry_vect_in        => (others => '0' ),
        scndry_aclk          => S_AXI4_ACLK ,
        scndry_resetn        => S_AXI4_ARESET ,
        scndry_out           => wb_hpm_done_cdc_to_axi
    ); 
-------------------------------------------------------------------------------
byte_xfer_cdc_from_axi_d2 <= '0' ;
hw_xfer_cdc_from_axi_d2   <= '0' ;
word_xfer_cdc_from_axi_d2 <= '0' ;
mst_modf_err_d2 <= '0' ;
mst_modf_err_d4 <= '0' ;
CPOL_cdc_to_spi_d2 <= '0' ;
CPHA_cdc_to_spi_d2 <= '0' ;
type_of_burst_cdc_to_spi_d2 <= '0' ;
rx_fifo_full_d2 <= '0' ;





end generate LOGIC_GENERATION_CDC;

end architecture imp;
---------------------
