-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- axi_qspi_xip_if.vhd - Entity and architecture
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
-- Filename:        axi_qspi_xip_if.vhd
-- Version:         v3.0
-- Description:     This is the top-level design file for the AXI Quad SPI core
--                  in XIP mode.
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
    -- use ieee.std_logic_signed.all;
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
    use unisim.vcomponents.FD;
    use unisim.vcomponents.FDR;
-------------------------------------------------------------------------------

entity axi_qspi_xip_if is
   generic(
       -- General Parameters
       C_FAMILY                 : string               := "virtex7";
       Async_Clk                : integer              := 0;
       C_SUB_FAMILY             : string               := "virtex7";
       -------------------------
       C_SPI_MEM_ADDR_BITS          : integer              ; -- default is 24 bit, options are 24 or 32 bits
       -------------------------
      -- C_AXI4_CLK_PS            : integer              := 10000;--AXI clock period
      -- C_EXT_SPI_CLK_PS         : integer              := 10000;--ext clock period
       C_XIP_FIFO_DEPTH             : integer          := 64;-- Fixed value for XIP mode.
       C_SCK_RATIO              : integer              := 16;--default in legacy mode
       C_NUM_SS_BITS            : integer range 1 to 32:= 1;
       C_NUM_TRANSFER_BITS      : integer              := 8; -- Fixed 8 bit for XIP mode
       -------------------------
       C_SPI_MODE               : integer range 0 to 2 := 0; -- used for differentiating
                                                             -- Standard, Dual or Quad mode
                                                             -- in Ports as well as internal
                                                             -- functionality
       C_USE_STARTUP            : integer range 0 to 1 := 1; --
       C_SPI_MEMORY             : integer range 0 to 3 := 1; -- 0 - mixed mode,
                                                             -- 1 - winbond,
                                                             -- 2 - numonyx
															 -- 3 - spansion
                                                             -- used to differentiate
                                                             -- internal look up table
                                                             -- for commands.
       -------------------------
       -- AXI4 Lite Interface Parameters
       --*C_S_AXI_ADDR_WIDTH       : integer range 32 to 32 := 32;
       C_S_AXI_ADDR_WIDTH       : integer range 7 to 7   := 7;
       C_S_AXI_DATA_WIDTH       : integer range 32 to 32 := 32;
       -------------------------
       --*C_BASEADDR               : std_logic_vector       := x"FFFFFFFF";
       --*C_HIGHADDR               : std_logic_vector       := x"00000000";
       -------------------------
       -- AXI4 Full Interface Parameters
       --*C_S_AXI4_ADDR_WIDTH      : integer range 32 to 32 := 32;
       C_S_AXI4_ADDR_WIDTH      : integer ;-- range 32 to 32 := 32;
       C_S_AXI4_DATA_WIDTH      : integer range 32 to 32 := 32;
       C_S_AXI4_ID_WIDTH        : integer range 1 to 16  := 4;
       -------------------------
       --*C_AXI4_BASEADDR          : std_logic_vector       := x"FFFFFFFF";
       --*C_AXI4_HIGHADDR          : std_logic_vector       := x"00000000";
       -------------------------
       C_XIP_FULL_ARD_ADDR_RANGE_ARRAY: SLV64_ARRAY_TYPE :=
           (
            X"0000_0000_0100_0000", --  IP user0 base address
            X"0000_0000_01FF_FFFF"  --  IP user0 high address
           );
       C_XIP_FULL_ARD_NUM_CE_ARRAY  : INTEGER_ARRAY_TYPE :=
           (
            2,
            1 -- User0 CE Number
           )
   );
   port(
       -- external async clock for SPI interface logic
       EXT_SPI_CLK    : in std_logic;
       S_AXI4_ACLK     : in std_logic;

       Rst_to_spi      : in std_logic;
       S_AXI4_ARESET  : in std_logic;
       -------------------------------
       S_AXI_ACLK      : in std_logic;
       S_AXI_ARESETN   : in std_logic;
       ------------------------------------
       -- AXI Write Address Channel Signals
       ------------------------------------
       S_AXI4_AWID    : in  std_logic_vector((C_S_AXI4_ID_WIDTH-1) downto 0);
       S_AXI4_AWADDR  : in  std_logic_vector((C_SPI_MEM_ADDR_BITS-1) downto 0);
       S_AXI4_AWLEN   : in  std_logic_vector(7 downto 0);
       S_AXI4_AWSIZE  : in  std_logic_vector(2 downto 0);
       S_AXI4_AWBURST : in  std_logic_vector(1 downto 0);
       S_AXI4_AWLOCK  : in  std_logic;                   -- not supported in design
       S_AXI4_AWCACHE : in  std_logic_vector(3 downto 0);-- not supported in design
       S_AXI4_AWPROT  : in  std_logic_vector(2 downto 0);-- not supported in design
       S_AXI4_AWVALID : in  std_logic;
       S_AXI4_AWREADY : out std_logic;
       ---------------------------------------
       -- AXI4 Full Write Data Channel Signals
       ---------------------------------------
       S_AXI4_WDATA   : in  std_logic_vector((C_S_AXI4_DATA_WIDTH-1)downto 0);
       S_AXI4_WSTRB   : in  std_logic_vector(((C_S_AXI4_DATA_WIDTH/8)-1) downto 0);
       S_AXI4_WLAST   : in  std_logic;
       S_AXI4_WVALID  : in  std_logic;
       S_AXI4_WREADY  : out std_logic;
       -------------------------------------------
       -- AXI4 Full Write Response Channel Signals
       -------------------------------------------
       S_AXI4_BID     : out std_logic_vector((C_S_AXI4_ID_WIDTH-1) downto 0);
       S_AXI4_BRESP   : out std_logic_vector(1 downto 0);
       S_AXI4_BVALID  : out std_logic;
       S_AXI4_BREADY  : in  std_logic;
       -----------------------------------
       -- AXI Read Address Channel Signals
       -----------------------------------
       S_AXI4_ARID    : in  std_logic_vector((C_S_AXI4_ID_WIDTH-1) downto 0);
       S_AXI4_ARADDR  : in  std_logic_vector((C_SPI_MEM_ADDR_BITS-1) downto 0);
       S_AXI4_ARLEN   : in  std_logic_vector(7 downto 0);
       S_AXI4_ARSIZE  : in  std_logic_vector(2 downto 0);
       S_AXI4_ARBURST : in  std_logic_vector(1 downto 0);
       S_AXI4_ARLOCK  : in  std_logic;                -- not supported in design
       S_AXI4_ARCACHE : in  std_logic_vector(3 downto 0);-- not supported in design
       S_AXI4_ARPROT  : in  std_logic_vector(2 downto 0);-- not supported in design
       S_AXI4_ARVALID : in  std_logic;
       S_AXI4_ARREADY : out std_logic;
       --------------------------------
       -- AXI Read Data Channel Signals
       --------------------------------
       S_AXI4_RID     : out std_logic_vector((C_S_AXI4_ID_WIDTH-1) downto 0);
       S_AXI4_RDATA   : out std_logic_vector((C_S_AXI4_DATA_WIDTH-1) downto 0);
       S_AXI4_RRESP   : out std_logic_vector(1 downto 0);
       S_AXI4_RLAST   : out std_logic;
       S_AXI4_RVALID  : out std_logic;
       S_AXI4_RREADY  : in  std_logic;
       --------------------------------
       XIPSR_CPHA_CPOL_ERR     : in std_logic;
       TO_XIPSR_trans_error    : out std_logic;
       --------------------------------
       TO_XIPSR_mst_modf_err   : out std_logic;
       TO_XIPSR_axi_rx_full    : out std_logic;
       TO_XIPSR_axi_rx_empty   : out std_logic;

       XIPCR_1_CPOL            : in std_logic;
       XIPCR_0_CPHA            : in std_logic;
       -------------------------------
       --*SPI port interface      * --
       -------------------------------
       IO0_I          : in std_logic;  -- MOSI signal in standard SPI
       IO0_O          : out std_logic;
       IO0_T          : out std_logic;
       -------------------------------
       IO1_I          : in std_logic;  -- MISO signal in standard SPI
       IO1_O          : out std_logic;
       IO1_T          : out std_logic;
       -----------------
       -- quad mode pins
       -----------------
       IO2_I          : in std_logic;
       IO2_O          : out std_logic;
       IO2_T          : out std_logic;
       ---------------
       IO3_I          : in std_logic;
       IO3_O          : out std_logic;
       IO3_T          : out std_logic;
       ---------------------------------
       -- common pins
       ----------------
       SPISEL         : in std_logic;
       -----
       SCK_I          : in std_logic;
       SCK_O_reg      : out std_logic;
       SCK_T          : out std_logic;
       -----
       SS_I           : in std_logic_vector((C_NUM_SS_BITS-1) downto 0);
       SS_O           : out std_logic_vector((C_NUM_SS_BITS-1) downto 0);
       SS_T           : out std_logic
       ---------------------------------
   );
end entity axi_qspi_xip_if;
--------------------------------------------------------------------------------
architecture imp of axi_qspi_xip_if is

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

constant NEW_LOGIC : integer := 0; -- 3/29/2013
constant ACTIVE_LOW_RESET : std_logic := '0';
constant CMD_BITS_LENGTH : integer:= 8; -- 3/29/2013
-----
-- code coverage -- function assign_addr_bits (logic_info : integer) return integer is
-- code coverage --          variable addr_width_24 : integer:= 24;
-- code coverage --          variable addr_width_32 : integer:= 32;
-- code coverage -- begin
-- code coverage --      if logic_info = 0 then -- old logic for 24 bit addressing
-- code coverage --         return addr_width_24;
-- code coverage --      else
-- code coverage --         return addr_width_32;
-- code coverage --      end if;
-- code coverage -- end function assign_addr_bits;

signal nm_wr_en_CMD : std_logic_vector(7 downto 0);
signal nm_4byte_addr_en_CMD : std_logic_vector(7 downto 0);
type NM_WR_EN_STATE_TYPE is
      (NM_WR_EN_IDLE,       -- decode command can be combined here later
       NM_WR_EN,
       NM_WR_EN_DONE
       );
signal nm_wr_en_cntrl_ps : NM_WR_EN_STATE_TYPE;
signal nm_wr_en_cntrl_ns : NM_WR_EN_STATE_TYPE;
signal wr_en_under_process        : std_logic;
signal wr_en_under_process_d1     : std_logic;
signal load_wr_en, wr_en_done_reg : std_logic;
signal wr_en_done_d1, wr_en_done_d2 : std_logic;
signal wr_en_done     : std_logic;
signal data_loaded, cmd_sent : std_logic;

type NM_32_BIT_WR_EN_STATE_TYPE is
      (NM_32_BIT_IDLE,       -- decode command can be combined here later
       NM_32_BIT_EN,
       NM_32_BIT_EN_DONE
       );
signal nm_sm_4_byte_addr_ps : NM_32_BIT_WR_EN_STATE_TYPE;
signal nm_sm_4_byte_addr_ns : NM_32_BIT_WR_EN_STATE_TYPE;
signal four_byte_en_under_process         : std_logic;
signal four_byte_addr_under_process_d1    : std_logic;
signal load_4_byte_addr_en, four_byte_en_done, four_byte_en_done_reg : std_logic;
-----
-- constant declaration
constant FAST_READ         : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0):="00001011"; -- 0B
constant FAST_READ_DUAL_IO : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0):="00111011"; -- 3B
constant FAST_READ_QUAD_IO : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0):="10111011"; -- BB
constant C_RD_COUNT_WIDTH_INT : integer := clog2(C_XIP_FIFO_DEPTH);
constant C_WR_COUNT_WIDTH_INT : integer := clog2(C_XIP_FIFO_DEPTH);
constant RX_FIFO_CNTR_WIDTH   : integer := clog2(C_XIP_FIFO_DEPTH);

constant XIP_MIN_SIZE  : std_logic_vector(31 downto 0):= X"00ffffff";-- 24 bit address
--constant XIP_ADDR_BITS : integer := 24;
constant XIP_ADDR_BITS : integer := C_SPI_MEM_ADDR_BITS; -- assign_addr_bits(NEW_LOGIC);

constant RESET_ACTIVE : std_logic := '1';
constant COUNT_WIDTH  : INTEGER   := log2(C_NUM_TRANSFER_BITS)+1;
constant ACTIVE_HIGH_RESET : std_logic := '1';
constant ZERO_RX_FIFO_CNT   : std_logic_vector(RX_FIFO_CNTR_WIDTH-1 downto 0) := (others => '0');
signal   rx_fifo_count: std_logic_vector(RX_FIFO_CNTR_WIDTH-1 downto 0);
constant ALL_1          : std_logic_vector(0 to RX_FIFO_CNTR_WIDTH-1)
                            := (others => '0');
signal updown_cnt_en_rx,down_cnt_en_rx : std_logic;

type AXI_IF_STATE_TYPE is
                  (
                   IDLE,       -- decode command can be combined here later
                   RD_BURST
                   );
signal xip_sm_ps: AXI_IF_STATE_TYPE;
signal xip_sm_ns: AXI_IF_STATE_TYPE;

type STATE_TYPE is
                  (IDLE,       -- decode command can be combined here later
                   CMD_SEND,
                   HPM_DUMMY,
                   ADDR_SEND,
                   TEMP_ADDR_SEND,
                   --DUMMY_SEND,
                   DATA_SEND,
                   TEMP_DATA_SEND,
                   DATA_RECEIVE,
                   TEMP_DATA_RECEIVE
                   );
signal qspi_cntrl_ns : STATE_TYPE;
signal qspi_cntrl_ps : STATE_TYPE;

type WB_STATE_TYPE is
                  (WB_IDLE,       -- decode command can be combined here later
                   WB_WR_HPM,
                   WB_DONE
                   );
signal wb_cntrl_ns : WB_STATE_TYPE;
signal wb_cntrl_ps : WB_STATE_TYPE;

signal valid_decode      : std_logic;
signal s_axi_arready_cmb : std_logic;
signal temp_i            : std_logic;
signal SS_frm_axi        : std_logic_vector(C_NUM_SS_BITS-1 downto 0);
signal SS_frm_axi_int    : std_logic_vector(C_NUM_SS_BITS-1 downto 0);
signal SS_frm_axi_reg    : std_logic_vector(C_NUM_SS_BITS-1 downto 0);
signal type_of_burst     : std_logic; --_vector(1 downto 0);
signal axi_length        : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal size_length       : std_logic_vector(1 downto 0);
signal S_AXI4_RID_reg    : std_logic_vector(C_S_AXI4_ID_WIDTH-1 downto 0);
signal XIP_ADDR          : std_logic_vector(XIP_ADDR_BITS-1 downto 0);
signal one_byte_transfer : std_logic;
signal two_byte_transfer : std_logic;
signal four_byte_transfer: std_logic;
signal dtr_length        : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal write_length      : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal s_axi_rvalid_i    : std_logic;
signal dtr_cntr_empty    : std_logic;
signal last_bt_one_data_cmb : std_logic;
signal last_data_cmb        : std_logic;
signal last_data_acked      : std_logic;
signal last_data            : std_logic;
signal rd_error_int         : std_logic;
signal Data_From_Rx_FIFO    : std_logic_vector(C_S_AXI4_DATA_WIDTH-1 downto 0);
signal S_AXI4_RRESP_i       : std_logic_vector(1 downto 0);
signal S_AXI4_RDATA_i       : std_logic_vector(C_S_AXI4_DATA_WIDTH-1 downto 0);
-- signal s_axi_rvalid_i       : std_logic;
signal s_axi_rvalid_cmb     : std_logic;
signal xip_pr_state_idle    : std_logic;
signal pr_state_idle        : std_logic;
signal rready_i             : std_logic;
signal wrap_around_to_axi_clk : std_logic;
signal spiXfer_done_to_axi_1  : std_logic;
signal Rx_FIFO_Empty          : std_logic;
signal IO0_T_cntrl_axi        : std_logic;
signal IO1_T_cntrl_axi        : std_logic;
signal IO2_T_cntrl_axi        : std_logic;
signal IO3_T_cntrl_axi        : std_logic;
signal SCK_T_cntrl_axi        : std_logic;
signal load_axi_data_frm_axi  : std_logic;
--signal Transmit_addr_int      : std_logic_vector(23 downto 0);            -- 3/30/2013
signal Transmit_addr_int      : std_logic_vector(XIP_ADDR_BITS-1 downto 0); -- 3/30/2013
signal Rx_FIFO_rd_ack         : std_logic;
signal Data_To_Rx_FIFO        : std_logic_vector(C_S_AXI4_DATA_WIDTH-1 downto 0);
signal store_date_in_drr_fifo : std_logic;
--signal Rx_FIFO_Empty          : std_logic;
signal Rx_FIFO_almost_Full    : std_logic;
signal Rx_FIFO_almost_Empty   : std_logic;
--signal pr_state_idle          : std_logic;
signal spiXfer_done_frm_spi_clk: std_logic;
signal mst_modf_err_frm_spi_clk: std_logic;
signal wrap_around_frm_spi_clk : std_logic;
signal one_byte_xfer_frm_axi_clk  : std_logic;
signal two_byte_xfer_frm_axi_clk  : std_logic;
signal four_byte_xfer_frm_axi_clk : std_logic;
signal load_axi_data_frm_axi_clk  : std_logic;
--signal Transmit_Addr_frm_axi_clk  : std_logic_vector(23 downto 0);           -- 3/30/2013
signal Transmit_Addr_frm_axi_clk  : std_logic_vector(XIP_ADDR_BITS-1 downto 0);-- 3/30/2013
signal CPOL_frm_axi_clk           : std_logic;
signal CPHA_frm_axi_clk           : std_logic;
signal SS_frm_axi_clk             : std_logic_vector(C_NUM_SS_BITS-1 downto 0);
signal type_of_burst_frm_axi_clk  : std_logic; -- _vector(1 downto 0);
signal type_of_burst_frm_axi      : std_logic; -- _vector(1 downto 0);
signal axi_length_frm_axi_clk     : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal dtr_length_frm_axi_clk     : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal load_axi_data_to_spi_clk   : std_logic;
--signal Transmit_Addr_to_spi_clk   : std_logic_vector(23 downto 0);            -- 3/30/2013
signal Transmit_Addr_to_spi_clk   : std_logic_vector(XIP_ADDR_BITS-1 downto 0); -- 3/30/2013
signal last_7_addr_bits           : std_logic_vector(7 downto 0);
signal CPOL_to_spi_clk            : std_logic;
signal CPHA_to_spi_clk            : std_logic;
signal SS_to_spi_clk              : std_logic_vector(C_NUM_SS_BITS-1 downto 0);
signal type_of_burst_to_spi       : std_logic;
signal type_of_burst_to_spi_clk   : std_logic;
signal axi_length_to_spi_clk      : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal dtr_length_to_spi_clk      : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
--signal wrap_around_to_axi_clk     : std_logic;
signal spi_addr                   : std_logic_vector(31 downto 0);
signal spi_addr_i                 : std_logic_vector(XIP_ADDR_BITS-1  downto 0); -- (23 downto 0);
signal spi_addr_int               : std_logic_vector(XIP_ADDR_BITS-1  downto 0); -- (23 downto 0);
signal spi_addr_wrap              : std_logic_vector(XIP_ADDR_BITS-1  downto 0); -- (23 downto 0);
signal spi_addr_wrap_1            : std_logic_vector(XIP_ADDR_BITS-1  downto 0); -- (23 downto 0);

--signal Transmit_Addr_to_spi_clk   : std_logic_vector(23 downto 0);
signal load_wrap_addr             : std_logic;
signal wrap_two                   : std_logic;
signal wrap_four                  : std_logic;
signal wrap_eight                 : std_logic;
signal wrap_sixteen               : std_logic;
signal SPIXfer_done_int           : std_logic;
signal size_length_cntr           : std_logic_vector(1 downto 0);
signal size_length_cntr_fixed     : std_logic_vector(1 downto 0);
signal length_cntr                : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal cmd_addr_sent              : std_logic;
signal SR_5_Tx_Empty, SR_5_Tx_Empty_d1, SR_5_Tx_Empty_d2              : std_logic;
signal wrap_around                : std_logic;
signal rst_wrap_around            : std_logic;
--signal pr_state_idle              : std_logic;
signal one_byte_xfer_to_spi_clk   : std_logic;
signal two_byte_xfer_to_spi_clk   : std_logic;
signal four_byte_xfer_to_spi_clk  : std_logic;
--signal store_date_in_drr_fifo     : std_logic;
signal Data_To_Rx_FIFO_int        : std_logic_vector(C_S_AXI4_DATA_WIDTH-1 downto 0);
signal SPIXfer_done_int_pulse_d2  : std_logic;
signal receive_Data_int           : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
--signal Data_To_Rx_FIFO            : std_logic_vector(7 downto 0);
--signal load_axi_data_to_spi_clk   : std_logic;
signal Tx_Data_d1                 : std_logic_vector(31 downto 0);
signal Tx_Data_d2                 : std_logic_vector(39 downto 0);
signal internal_count             : std_logic_vector(3 downto 0);
signal SPI_cmd                    : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal Transmit_Data              : std_logic_vector(0 to C_NUM_TRANSFER_BITS-1);
signal Data_Dir                   : std_logic;
signal Data_Mode_1                : std_logic;
signal Data_Mode_0                : std_logic;
signal Data_Phase                 : std_logic;
signal Quad_Phase                 : std_logic;
signal Addr_Mode_1                : std_logic;
signal Addr_Mode_0                : std_logic;
signal Addr_Bit                   : std_logic;
signal Addr_Phase                 : std_logic;
signal CMD_Mode_1                 : std_logic;
signal CMD_Mode_0                 : std_logic;
--signal cmd_addr_cntr              : std_logic_vector(2 downto 0);
--signal cmd_addr_sent              : std_logic;
signal transfer_start             : std_logic;
signal last_bt_one_data           : std_logic;
--signal SPIXfer_done_int           : std_logic;
signal actual_SPIXfer_done_int    : std_logic;
signal transfer_start_d1          : std_logic;
signal transfer_start_d2          : std_logic;
signal transfer_start_d3          : std_logic;
signal transfer_start_pulse       : std_logic;
signal SPIXfer_done_int_d1        : std_logic;
signal SPIXfer_done_int_pulse     : std_logic;
signal SPIXfer_done_int_pulse_d1  : std_logic;
--signal SPIXfer_done_int_pulse_d2  : std_logic;
signal SPIXfer_done_int_pulse_d3  : std_logic;
--signal SPIXfer_done_int           : std_logic;
signal mode_1                     : std_logic;
signal mode_0                     : std_logic;
signal Count                      : std_logic_vector(COUNT_WIDTH downto 0);
--signal receive_Data_int           : std_logic_vector(7 downto 0);
signal rx_shft_reg_mode_0011      : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
signal Sync_Set                   : std_logic;
signal Sync_Reset                 : std_logic;
signal sck_o_int                  : std_logic;
signal sck_d1                     : std_logic;
signal sck_d2                     : std_logic;
signal sck_rising_edge            : std_logic;
signal Shift_Reg                  : std_logic_vector(0 to C_NUM_TRANSFER_BITS-1);
signal Serial_Dout_0              : std_logic;
signal Serial_Dout_1              : std_logic;
signal Serial_Dout_2              : std_logic;
signal Serial_Dout_3              : std_logic;
signal pr_state_cmd_ph            : std_logic;

--signal qspi_cntrl_ps              : std_logic;
signal stop_clock                 : std_logic;
signal stop_clock_reg             : std_logic;
signal pr_state_data_receive      : std_logic;
signal pr_state_non_idle          : std_logic;
--signal pr_state_idle            : std_logic;
--signal pr_state_cmd_ph                  : std_logic;
--signal SPIXfer_done_int_pulse   : std_logic;
signal no_slave_selected          : std_logic;
--signal rst_wrap_around                  : std_logic;
signal IO0_T_control              : std_logic;
signal IO1_T_control              : std_logic;
signal IO2_T_control              : std_logic;
signal IO3_T_control              : std_logic;
signal addr_cnt                   : std_logic_vector(2 downto 0);
signal addr_cnt1                  : std_logic_vector(1 downto 0);
signal pr_state_addr_ph           : std_logic;
signal SS_tri_state_en_control    : std_logic;
signal SCK_tri_state_en_control   : std_logic;
signal IO0_tri_state_en_control   : std_logic;
signal IO1_tri_state_en_control   : std_logic;
signal IO2_tri_state_en_control   : std_logic;
signal IO3_tri_state_en_control   : std_logic;
signal IO0_T_cntrl_spi            : std_logic;
signal MODF_strobe_int            : std_logic;
signal SPISEL_sync                : std_logic;
signal spisel_d1                  : std_logic;
signal MODF_strobe                : std_logic;
signal Allow_MODF_Strobe          : std_logic;
signal sck_o_in                   : std_logic;
--signal SCK_O_reg                : std_logic;
signal slave_mode                 : std_logic;
--signal pr_state_non_idle        : std_logic;
signal mst_modf_err_to_axi_clk    : std_logic;
signal mst_modf_err_to_axi4_clk    : std_logic;
signal Rx_FIFO_Full_to_axi4_clk    : std_logic;
signal Rx_FIFO_Full_to_axi_clk     : std_logic;
signal Rx_FIFO_Full                : std_logic;
signal one_byte_xfer               : std_logic;
signal two_byte_xfer               : std_logic;
signal four_byte_xfer              : std_logic;
signal XIP_trans_error             : std_logic;
signal XIP_trans_cdc_to_error             : std_logic;
signal load_cmd                    : std_logic;
signal load_cmd_to_spi_clk         : std_logic;
--signal load_axi_data_frm_axi_clk : std_logic;
signal load_cmd_frm_axi_clk        : std_logic;
signal axi_len_two     : std_logic;
signal axi_len_four    : std_logic;
signal axi_len_eight   : std_logic;
signal axi_len_sixteen : std_logic;
signal reset_inversion : std_logic;

signal new_tr            : std_logic;
signal SR_5_Tx_Empty_int : std_logic;
signal only_last_count   : std_logic;
signal rx_fifo_cntr_rst, rx_fifo_not_empty : std_logic;

signal store_date_in_drr_fifo_d1 : std_logic;
signal store_date_in_drr_fifo_d2 : std_logic;
signal store_date_in_drr_fifo_d3 : std_logic;
signal xip_ns_state_idle         : std_logic;
signal wrap_around_d1            : std_logic;
signal wrap_ack                  : std_logic;
signal wrap_ack_1                : std_logic;
signal wrap_around_d2            : std_logic;
signal wrap_around_d3            : std_logic;
signal start_after_wrap          : std_logic;
signal store_last_b4_wrap        : std_logic;

signal wrp_addr_len_16_siz_32 : std_logic;
signal wrp_addr_len_8_siz_32  : std_logic;
signal wrp_addr_len_4_siz_32  : std_logic;
signal wrp_addr_len_2_siz_32  : std_logic;

signal wrp_addr_len_16_siz_16 : std_logic;
signal wrp_addr_len_8_siz_16  : std_logic;
signal wrp_addr_len_4_siz_16  : std_logic;
signal wrp_addr_len_2_siz_16, start_after_wrap_d1  : std_logic;
signal SS_O_1                 : std_logic_vector((C_NUM_SS_BITS-1) downto 0);

signal WB_wr_en_CMD  : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);-- (7 downto 0);
signal WB_wr_sr_CMD  : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);-- (7 downto 0);
signal WB_wr_sr_DATA : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);-- (7 downto 0);
signal WB_wr_hpm_CMD : std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);-- (7 downto 0);
signal wb_wr_en_done       : std_logic;
signal wb_wr_sr_done       : std_logic;
signal wb_wr_sr_data_done  : std_logic;
signal wb_wr_hpm_done      : std_logic;

signal load_wr_en_cmd      : std_logic;
signal load_wr_sr_cmd      : std_logic;
signal load_wr_sr_d0       : std_logic;
signal load_wr_sr_d1       : std_logic;
signal load_rd_sr          : std_logic;
signal load_wr_hpm         : std_logic;
signal wb_hpm_done         : std_logic;
signal wb_hpm_done_reg     : std_logic;
signal dis_sr_5_empty_reg  : std_logic;
signal dis_sr_5_empty      : std_logic;

signal wb_hpm_done_frm_spi,wb_hpm_done_frm_spi_clk,wb_hpm_done_to_axi : std_logic;
signal hpm_under_process         : std_logic;
signal hpm_under_process_d1      : std_logic;
signal s_axi_rlast_cmb           : std_logic;
signal store_date_in_drr_fifo_en : std_logic;



signal XIP_trans_error_cmb, XIP_trans_error_d1, XIP_trans_error_d2, XIP_trans_error_d3 : std_logic;
signal axi4_tr_over_d1, axi4_tr_over_d2               : std_logic;
signal arready_d1, arready_d2, arready_d3 : std_logic;
signal XIPSR_CPHA_CPOL_ERR_d1, XIPSR_CPHA_CPOL_ERR_d2 : std_logic;
signal axi4_tr_over_d3       : std_logic;
signal last_data_acked_int_2 : std_logic;
signal XIP_trans_error_int_2 : std_logic;
signal s_axi_arready_int_2                : std_logic;



-- signal XIP_trans_error_cmb : std_logic;
-- signal axi4_tr_over_d1, axi4_tr_over_d2               : std_logic;
-- signal arready_d1, arready_d2, arready_d3 : std_logic;
-- signal XIPSR_CPHA_CPOL_ERR_d1, XIPSR_CPHA_CPOL_ERR_d2 : std_logic;
-- signal axi4_tr_over_d3       : std_logic;
-- signal last_data_acked_int_2 : std_logic;
-- signal XIP_trans_error_int_2 : std_logic;
-- signal s_axi_arready_int_2                : std_logic;


signal Rx_FIFO_Empty_d1, Rx_FIFO_Empty_d2             : std_logic;
signal XIPSR_CPHA_CPOL_ERR_4                          : std_logic;
--signal mst_modf_err_to_axi4clk: std_logic;
signal xip_done                           : std_logic;
signal en_xip                             : std_logic;
signal new_tr_at_axi4                     : std_logic;

signal axi4_tr_over          : std_logic;
--attribute ASYNC_REG          : string;
--attribute ASYNC_REG of XIP_TRANS_ERROR_AXI2AXI4_CDC : label is "TRUE";
--attribute ASYNC_REG of Rx_FIFO_Empty_AXI42AXI : label is "TRUE";
--attribute ASYNC_REG of CPHA_CPOL_ERR_AXI2AXI4_CDC  : label is "TRUE";
--attribute ASYNC_REG of ARREADY_PULSE_AXI42AXI_CDC: label is "TRUE";
--attribute ASYNC_REG of AXI4_TR_OVER_AXI42AXI_CDC   : label is "TRUE";

constant LOGIC_CHANGE : integer range 0 to 1 := 1;
constant MTBF_STAGES_AXI2S : integer range 0 to 6 := 3 ;
constant MTBF_STAGES_S2AXI : integer range 0 to 6 := 4 ;
constant MTBF_STAGES_AXI2AXILITE : integer range 0 to 6 := 4 ;


-----
begin
-----
S_AXI4_WREADY <= '0';
S_AXI4_BID    <= (others => '0');
S_AXI4_BRESP  <= (others => '0');
S_AXI4_BVALID <= '0';
S_AXI4_AWREADY<= '0';

valid_decode <= S_AXI4_ARVALID and xip_pr_state_idle;
reset_inversion <= not S_AXI4_ARESET;
-- address decoder and CS generation in AXI interface
I_DECODER : entity axi_quad_spi_v3_2_5.qspi_address_decoder
    generic map
    (
     C_BUS_AWIDTH          => XIP_ADDR_BITS, -- C_S_AXI4_ADDR_WIDTH,
     C_S_AXI4_MIN_SIZE     => XIP_MIN_SIZE,
     C_ARD_ADDR_RANGE_ARRAY=> C_XIP_FULL_ARD_ADDR_RANGE_ARRAY,
     C_ARD_NUM_CE_ARRAY    => C_XIP_FULL_ARD_NUM_CE_ARRAY,
     C_FAMILY              => "nofamily"
    )
    port map
    (
     Bus_clk               =>  S_AXI4_ACLK,                             -- in  std_logic;
     Bus_rst               =>  reset_inversion,                         -- in  std_logic;
     Address_In_Erly       =>  S_AXI4_ARADDR(XIP_ADDR_BITS-1 downto 0), -- in  std_logic_vector(0 to C_BUS_AWIDTH-1);
     Address_Valid_Erly    =>  s_axi_arready_cmb,                       -- in  std_logic;                            
     Bus_RNW               =>  valid_decode,                            -- in  std_logic;                            
     Bus_RNW_Erly          =>  valid_decode,                            -- in  std_logic;                            
     CS_CE_ld_enable       =>  s_axi_arready_cmb,                       -- in  std_logic;       
     Clear_CS_CE_Reg       =>  temp_i,                                  -- in  std_logic;
     RW_CE_ld_enable       =>  s_axi_arready_cmb,                       -- in  std_logic;
     CS_for_gaps           =>  open,                                    -- out std_logic;
      -- Decode output signals
     CS_Out                =>  SS_frm_axi,
     RdCE_Out              =>  open,
     WrCE_Out              =>  open
      );
-------------------------------------------------
STORE_AXI_ARBURST_P: process (S_AXI4_ACLK) is
begin
    if (S_AXI4_ACLK'event and S_AXI4_ACLK='1') then
       if (S_AXI4_ARESET = ACTIVE_HIGH_RESET) then -- S_AXI4_ARESET is already inverted and made active high
         type_of_burst     <= '0';-- "01"; -- default is INCR burst
       elsif(s_axi_arready_cmb = '1')then
         type_of_burst     <= S_AXI4_ARBURST(1) ;
       end if;
    end if;
end process STORE_AXI_ARBURST_P;
-----------------------

S_AXI4_ARREADY_P:process(S_AXI4_ACLK)is
-----
begin
-----
    if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
        if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
            S_AXI4_ARREADY <= '0';
        else
            S_AXI4_ARREADY <= s_axi_arready_cmb;
        end if;
    end if;
end process S_AXI4_ARREADY_P;

-- S_AXI4_ARREADY <= s_axi_arready_cmb;

STORE_AXI_LENGTH_P:process(S_AXI4_ACLK)is
-----
begin
-----
    if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
        if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
            axi_length <= (others => '0');
        elsif(s_axi_arready_cmb = '1')then
            axi_length <= S_AXI4_ARLEN;
        end if;
    end if;
end process STORE_AXI_LENGTH_P;
---------------------------------------------------
STORE_AXI_SIZE_P:process(S_AXI4_ACLK)is
-----
begin
-----
    if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
        if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
            size_length <= (others => '0');
        elsif(s_axi_arready_cmb = '1')then
            size_length <= S_AXI4_ARSIZE(1 downto 0);
        end if;
    end if;
end process STORE_AXI_SIZE_P;
-------------------------------------------------------------------------------
REG_RID_P: process (S_AXI4_ACLK) is
begin
    if (S_AXI4_ACLK'event and S_AXI4_ACLK='1') then
       if (S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
         S_AXI4_RID_reg       <= (others=> '0');
       elsif(s_axi_arready_cmb = '1')then
         S_AXI4_RID_reg       <= S_AXI4_ARID ;
       end if;
    end if;
end process REG_RID_P;
----------------------
S_AXI4_RID <= S_AXI4_RID_reg;
-----------------------------
OLD_LOGIC_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
begin
    STORE_AXI_ADDR_P:process(S_AXI4_ACLK)is
    -----
    begin
    -----
        if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
            if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
                XIP_ADDR <= (others => '0');
            elsif(s_axi_arready_cmb = '1')then
                XIP_ADDR <= S_AXI4_ARADDR(23 downto 0);-- support for 24 bit address
            end if;
        end if;
    end process STORE_AXI_ADDR_P;
end generate OLD_LOGIC_GEN;
---------------------------

NEW_LOGIC_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
begin
    STORE_AXI_ADDR_P:process(S_AXI4_ACLK)is
    -----
    begin
    -----
        if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
            if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
                XIP_ADDR <= (others => '0');
            elsif(s_axi_arready_cmb = '1')then
                XIP_ADDR <= S_AXI4_ARADDR(C_SPI_MEM_ADDR_BITS-1 downto 0);-- support for 24 or 32 bit address
            end if;
        end if;
    end process STORE_AXI_ADDR_P;
end generate NEW_LOGIC_GEN;
---------------------------
------------------------------------------------------------------------------

ONE_BYTE_XFER_P:process(S_AXI4_ACLK) is
begin
-----
     if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
        if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
            one_byte_xfer <= '0';
        elsif(s_axi_arready_cmb = '1')then
            one_byte_xfer <= not(or_reduce(S_AXI4_ARSIZE(1 downto 0)));
        end if;
     end if;
end process ONE_BYTE_XFER_P;

TWO_BYTE_XFER_P:process(S_AXI4_ACLK) is
begin
-----
     if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
        if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
            two_byte_xfer <= '0';
        elsif(s_axi_arready_cmb = '1')then
            two_byte_xfer <= S_AXI4_ARSIZE(0);
        end if;
     end if;
end process TWO_BYTE_XFER_P;

FOUR_BYTE_XFER_P:process(S_AXI4_ACLK) is
begin
-----
     if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
        if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
            four_byte_xfer <= '0';
        elsif(s_axi_arready_cmb = '1')then
            four_byte_xfer <= S_AXI4_ARSIZE(1);
        end if;
     end if;
end process FOUR_BYTE_XFER_P;

---------------------------------------------------------------------------------
STORE_DTR_LENGTH_P:process(S_AXI4_ACLK)is
-----
begin
-----
    if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
        if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
            dtr_length <= (others => '0');
        elsif(s_axi_arready_cmb = '1')then
            dtr_length <= S_AXI4_ARLEN;-- + "00000001";
       -- elsif(S_AXI4_RREADY = '1' and s_axi_rvalid_i = '1') then
      elsif(Rx_FIFO_rd_ack = '1') then
            dtr_length <=  dtr_length - '1';
        end if;
    end if;
end process STORE_DTR_LENGTH_P;
-----------------------------------------------------
STORE_WRITE_LENGTH_P:process(S_AXI4_ACLK)is
-----
begin
-----
    if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
        if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then -- if(xip_sm_ps = IDLE)then
            write_length <= (others => '0');
        elsif(s_axi_arready_cmb = '1')then
            write_length <= S_AXI4_ARLEN + "00000001";
        elsif(spiXfer_done_to_axi_1 = '1')then
            write_length <=  write_length - '1';
        end if;
    end if;
end process STORE_WRITE_LENGTH_P;
-----------------------------------------------------
--dtr_cntr_empty <= or_Reduce(dtr_length);
-----------------------------------------------------
last_bt_one_data_cmb <= not(or_reduce(dtr_length(C_NUM_TRANSFER_BITS-1 downto 1))) and
                                                 dtr_length(0) and
                                                 S_AXI4_RREADY;
last_data_cmb        <= not(or_reduce(dtr_length(C_NUM_TRANSFER_BITS-1 downto 0)));

      RX_FIFO_FULL_CNTR_I : entity axi_quad_spi_v3_2_5.counter_f
      generic map(
        C_NUM_BITS    =>  RX_FIFO_CNTR_WIDTH,
        C_FAMILY      =>  "nofamily"
          )
      port map(
        Clk           =>  S_AXI4_ACLK,      -- in
        Rst           =>  S_AXI4_ARESET,   -- '0',              -- in
	-- coverage off
        Load_In       =>  ALL_1,            -- in
	-- coverage on
        Count_Enable  =>  updown_cnt_en_rx, -- in
        ----------------
        Count_Load    =>  s_axi_arready_cmb,-- in
        ----------------
        Count_Down    =>  down_cnt_en_rx,   -- in
        Count_Out     =>  rx_fifo_count,    -- out std_logic_vector
        Carry_Out     =>  open              -- out
        );

        updown_cnt_en_rx <= s_axi_arready_cmb     or
                            spiXfer_done_to_axi_1 or
                            (down_cnt_en_rx); -- this is to make the counter enable for decreasing.
        down_cnt_en_rx   <= S_AXI4_RREADY and s_axi_rvalid_i;
        only_last_count  <= not(or_reduce(rx_fifo_count(RX_FIFO_CNTR_WIDTH-1 downto 0))) and
                            last_data_cmb;
        rx_fifo_not_empty <= or_reduce(rx_fifo_count(RX_FIFO_CNTR_WIDTH-1 downto 0));

LAST_DATA_ACKED_P: process (S_AXI4_ACLK) is
-----------------
begin
-----
    if (S_AXI4_ACLK'event and S_AXI4_ACLK='1') then
        if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET)     then
            last_data_acked <= '0';
        else
            if(S_AXI4_RREADY = '1' and last_data_acked = '1') then -- AXI Ready and Rlast active
                last_data_acked <= '0';
            elsif(S_AXI4_RREADY = '0' and last_data_acked = '1')then-- AXI not Ready and Rlast active, then hold the RLAST signal
                last_data_acked <= '1';
            else
                last_data_acked <=(last_data_cmb and
                                   Rx_FIFO_rd_ack);


            end if;
        end if;
    end if;
end process LAST_DATA_ACKED_P;
------------------------------
S_AXI4_RLAST <= last_data_acked;
--------------------------------
S_AXI4_RDATA_RESP_P : process (S_AXI4_ACLK) is
begin
  if S_AXI4_ACLK'event and S_AXI4_ACLK = '1' then
    if (S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
       S_AXI4_RRESP_i <= (others => '0');
       S_AXI4_RDATA_i <= (others => '0');
    else-- if(S_AXI4_RREADY = '1' )then --  and (Rx_FIFO_Empty = '0')then
       S_AXI4_RRESP_i  <= --(rd_error_int or mst_modf_err_to_axi_clk) & '0';
                         (mst_modf_err_to_axi4_clk) & '0';
       S_AXI4_RDATA_i  <= Data_From_Rx_FIFO;
    end if;
  end if;
end process S_AXI4_RDATA_RESP_P;
--------------------------------
S_AXI4_RRESP <= S_AXI4_RRESP_i;
S_AXI4_RDATA <= S_AXI4_RDATA_i;
-------------------------------
-----------------------------
-- S_AXI_RVALID_I_P : below process generates the RVALID response on read channel
----------------------
S_AXI_RVALID_I_P : process (S_AXI4_ACLK) is
  begin
    if S_AXI4_ACLK'event and S_AXI4_ACLK = '1' then
      if (S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
          s_axi_rvalid_i <= '0';
      elsif(S_AXI4_RREADY = '1') then -- and (s_axi_rvalid_i = '1') then -- AXI Ready and Rlast active
          s_axi_rvalid_i <= Rx_FIFO_rd_ack; -- '0';
      elsif(S_AXI4_RREADY = '0') and (s_axi_rvalid_i = '1') then
          s_axi_rvalid_i <= s_axi_rvalid_i;
      else
          s_axi_rvalid_i <= Rx_FIFO_rd_ack;
      end if;
    end if;
end process S_AXI_RVALID_I_P;
-----------------------------
S_AXI4_RVALID <= s_axi_rvalid_i;
-- -----------------------------

xip_pr_state_idle <= '1' when xip_sm_ps = IDLE else '0';
xip_ns_state_idle <= '1' when xip_sm_ns = IDLE else '0';

rready_i      <= S_AXI4_RREADY and not last_data_cmb;


------------------------------------------------------------------------------
XIP_trans_error_cmb <= not(or_reduce(S_AXI4_ARBURST)) and (S_AXI4_ARVALID);
-- XIP_TR_ERROR_PULSE_STRETCH_1: single pulse for AXI4 transaction error

LOGIC_GENERATION_FDR : if (Async_Clk = 0) generate
attribute ASYNC_REG          : string;
attribute ASYNC_REG of XIP_TRANS_ERROR_AXI2AXI4_CDC : label is "TRUE";
--attribute ASYNC_REG of Rx_FIFO_Empty_AXI42AXI : label is "TRUE";
attribute ASYNC_REG of CPHA_CPOL_ERR_AXI2AXI4_CDC  : label is "TRUE";
attribute ASYNC_REG of ARREADY_PULSE_AXI42AXI_CDC: label is "TRUE";
attribute ASYNC_REG of AXI4_TR_OVER_AXI42AXI_CDC   : label is "TRUE";
begin
XIP_TR_ERROR_PULSE_STRETCH_1: process(S_AXI4_ACLK)is
begin
     if(S_AXI4_ACLK'event and S_AXI4_ACLK= '1') then
           if(S_AXI4_ARESET = '1') then
               XIP_trans_error_int_2 <= '0';
           else
               XIP_trans_error_int_2 <= XIP_trans_error_cmb xor
                                        XIP_trans_error_int_2;
           end if;
     end if;
end process XIP_TR_ERROR_PULSE_STRETCH_1;
-------------------------------------

XIP_TRANS_ERROR_AXI2AXI4_CDC: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => XIP_trans_error_d1,
                         C  => S_AXI_ACLK,
                         D  => XIP_trans_error_int_2,
                         R  => S_AXI_ARESETN
                       );
XIP_TRANS_ERROR_AXI2AXI4_1: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => XIP_trans_error_d2,
                         C  => S_AXI_ACLK,
                         D  => XIP_trans_error_d1,
                         R  => S_AXI_ARESETN
                       );
XIP_TRANS_ERROR_AXI2AXI4_2: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => XIP_trans_error_d3,
                         C  => S_AXI_ACLK,
                         D  => XIP_trans_error_d2,
                         R  => S_AXI_ARESETN
                       );
XIP_trans_error <= XIP_trans_error_d2 xor XIP_trans_error_d3;


------------------------------------------------------------------------------
--mst_modf_err_to_axi <= mst_modf_err_d2;

-- TO XIP Status Register


-- LAST_DATA_PULSE_STRETCH_1: single pulse for AXI4 transaction completion
LAST_DATA_PULSE_STRETCH_1: process(S_AXI4_ACLK)is
begin
     if(S_AXI4_ACLK'event and S_AXI4_ACLK= '1') then
           if(S_AXI4_ARESET = '1') then
                   last_data_acked_int_2 <= '0';
           else
                  last_data_acked_int_2 <= last_data_acked xor
                                           last_data_acked_int_2;
           end if;
     end if;
end process LAST_DATA_PULSE_STRETCH_1;
-------------------------------------
AXI4_TR_OVER_AXI42AXI_CDC: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => axi4_tr_over_d1,
                         C  => S_AXI_ACLK,
                         D  => last_data_acked_int_2,
                         R  => S_AXI_ARESETN
                       );
AXI4_TR_OVER_AXI42AXI_1: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => axi4_tr_over_d2,
                         C  => S_AXI_ACLK,
                         D  => axi4_tr_over_d1,
                         R  => S_AXI_ARESETN
                       );
AXI4_TR_OVER_AXI42AXI_2: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => axi4_tr_over_d3,
                         C  => S_AXI_ACLK,
                         D  => axi4_tr_over_d2,
                         R  => S_AXI_ARESETN
                       );
axi4_tr_over <= axi4_tr_over_d2 xor axi4_tr_over_d3;
-------------------------------------------------------------
-- ARREADY_PULSE_STRETCH_1: single pulse for AXI4 transaction acceptance
ARREADY_PULSE_STRETCH_1: process(S_AXI4_ACLK)is
begin
     if(S_AXI4_ACLK'event and S_AXI4_ACLK= '1') then
           if(S_AXI4_ARESET = '1') then
                   s_axi_arready_int_2 <= '0';
           else
                   s_axi_arready_int_2 <= s_axi_arready_cmb xor
                                          s_axi_arready_int_2;
           end if;
     end if;
end process ARREADY_PULSE_STRETCH_1;
-------------------------------------
ARREADY_PULSE_AXI42AXI_CDC: component FDR
              generic map(INIT => '1'
              )port map (
                         Q  => arready_d1,
                         C  => S_AXI_ACLK,
                         D  => s_axi_arready_int_2,
                         R  => S_AXI_ARESETN
                       );
ARREADY_PULSE_AXI42AXI_2: component FDR
              generic map(INIT => '1'
              )port map (
                         Q  => arready_d2,
                         C  => S_AXI_ACLK,
                         D  => arready_d1,
                         R  => S_AXI_ARESETN
                       );
ARREADY_PULSE_AXI42AXI_3: component FDR    -- 2/21/2012
              generic map(INIT => '1'
              )port map (
                         Q  => arready_d3,
                         C  => S_AXI_ACLK,
                         D  => arready_d2,
                         R  => S_AXI_ARESETN
                       );
new_tr_at_axi4 <= arready_d2 xor arready_d3;
-------------------------------------


------------------------------------------------------------------------------
-- CPHA_CPOL_ERR_AXI2AXI4_CDC: CDC flop at cross clock boundary
CPHA_CPOL_ERR_AXI2AXI4_CDC: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => XIPSR_CPHA_CPOL_ERR_d1,
                         C  => S_AXI4_ACLK,
                         D  => XIPSR_CPHA_CPOL_ERR,
                         R  => S_AXI4_ARESET
                       );
CPHA_CPOL_ERR_AXI2AXI4_1: component FDR
              generic map(INIT => '0'
              )port map (
                         Q  => XIPSR_CPHA_CPOL_ERR_d2,
                         C  => S_AXI4_ACLK,
                         D  => XIPSR_CPHA_CPOL_ERR_d1,
                         R  => S_AXI4_ARESET
                       );
XIPSR_CPHA_CPOL_ERR_4 <= XIPSR_CPHA_CPOL_ERR_d2;
-------------------------------------------------------------------------------

end generate LOGIC_GENERATION_FDR;

LOGIC_GENERATION_CDC : if (Async_Clk = 1) generate
--=================================================================================

XIP_TR_ERROR_PULSE_STRETCH_1_P: process(S_AXI4_ACLK)is
begin
     if(S_AXI4_ACLK'event and S_AXI4_ACLK= '1') then
           if(S_AXI4_ARESET = '1') then
               XIP_trans_error_int_2 <= '0';
           else
               XIP_trans_error_int_2 <= XIP_trans_error_cmb xor
                                        XIP_trans_error_int_2;
           end if;
     end if;
end process XIP_TR_ERROR_PULSE_STRETCH_1_P;

XIP_TRANS_ERROR_AXI42AXI: entity lib_cdc_v1_0_2.cdc_sync
    generic map (
        C_CDC_TYPE                  => 1 , -- 2 is ack based level sync
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2AXILITE 
                )

    port map (
        prmry_aclk           => S_AXI4_ACLK , 
        prmry_resetn         => S_AXI_ARESETN ,
        prmry_in             => XIP_trans_error_int_2 ,
        scndry_aclk          => S_AXI_ACLK ,
        prmry_vect_in        => (others => '0') ,
        scndry_resetn        => S_AXI_ARESETN ,
        scndry_out            => XIP_trans_error_d2
    ); 
	XIP_TR_ERROR_PULSE_STRETCH_1: process(S_AXI_ACLK)is
begin
     if(S_AXI_ACLK'event and S_AXI_ACLK= '1') then
     
     XIP_trans_error_d3 <= XIP_trans_error_d2 ;
              
           end if;
end process XIP_TR_ERROR_PULSE_STRETCH_1;
XIP_trans_cdc_to_error <= XIP_trans_error_d2 xor XIP_trans_error_d3;
XIP_trans_error <= XIP_trans_cdc_to_error;
--=================================================================================
LAST_DATA_PULSE_STRETCH_1_CDC: process(S_AXI4_ACLK)is
begin
     if(S_AXI4_ACLK'event and S_AXI4_ACLK= '1') then
           if(S_AXI4_ARESET = '1') then
                   last_data_acked_int_2 <= '0';
                   --axi4_tr_over_d1       <= '0';
           else
                  last_data_acked_int_2 <= last_data_acked xor
                                           last_data_acked_int_2;
                  --axi4_tr_over_d1       <= last_data_acked_int_2;
           end if;
     end if;
end process LAST_DATA_PULSE_STRETCH_1_CDC;

AXI4_TR_OVER_AXI42AXI: entity lib_cdc_v1_0_2.cdc_sync 
    generic map (
        C_CDC_TYPE                  => 1 , -- 2 is ack based level sync
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 1 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2AXILITE 
                )

    port map (
        prmry_aclk           => S_AXI4_ACLK , 
        prmry_resetn         => S_AXI4_ARESET ,
        prmry_in             => last_data_acked_int_2 ,
        scndry_aclk          => S_AXI_ACLK ,
            prmry_vect_in        => (others => '0') ,
        scndry_resetn        => S_AXI_ARESETN ,
        scndry_out           => axi4_tr_over_d2
    ); 
	LAST_DATA_PULSE_STRETCH_1: process(S_AXI_ACLK)is
begin
     if(S_AXI_ACLK'event and S_AXI_ACLK= '1') then
          
               axi4_tr_over_d3 <= axi4_tr_over_d2 ;
              
         --  end if;
     end if;
end process LAST_DATA_PULSE_STRETCH_1;
axi4_tr_over <= axi4_tr_over_d2 xor axi4_tr_over_d3;
--=================================================================================

ARREADY_PULSE_STRETCH_1_CDC: process(S_AXI4_ACLK)is
begin
     if(S_AXI4_ACLK'event and S_AXI4_ACLK= '1') then
           if(S_AXI4_ARESET = '1') then
                   s_axi_arready_int_2 <= '1';
                   --arready_d1          <= '0';
           else
                   s_axi_arready_int_2 <= s_axi_arready_cmb xor
                                          s_axi_arready_int_2;
                   --arready_d1          <= s_axi_arready_int_2;
           end if;
     end if;
end process ARREADY_PULSE_STRETCH_1_CDC;


ARREADY_PULSE_AXI42AXI: entity lib_cdc_v1_0_2.cdc_sync 
    generic map (
        C_CDC_TYPE                  => 1 , -- 2 is ack based level sync
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 1 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2AXILITE 
                )

    port map (
        prmry_aclk           => S_AXI4_ACLK , 
        prmry_resetn         => S_AXI4_ARESET ,
        prmry_in             => s_axi_arready_int_2 ,
        scndry_aclk          => S_AXI_ACLK ,
        prmry_vect_in        => (others => '0') ,
        scndry_resetn        => S_AXI_ARESETN ,
        scndry_out            => arready_d2
    );  
	ARREADY_PULSE_STRETCH_1: process(S_AXI_ACLK)is
begin
     if(S_AXI_ACLK'event and S_AXI_ACLK= '1') then
           
               arready_d3 <= arready_d2;
              
          -- end if;
     end if;
end process ARREADY_PULSE_STRETCH_1;
new_tr_at_axi4 <= arready_d2 xor arready_d3;
--==================================================================================

CPHA_CPOL_ERR_AXI2AXI4: entity lib_cdc_v1_0_2.cdc_sync 
    generic map (
        C_CDC_TYPE                  => 1 , -- 1 is level synch
        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
        C_SINGLE_BIT                => 1 , 
        C_FLOP_INPUT                => 0 ,
        C_VECTOR_WIDTH              => 1 ,
        C_MTBF_STAGES               => MTBF_STAGES_AXI2AXILITE 
                )

    port map (
        prmry_aclk           => S_AXI_ACLK , 
        prmry_resetn         => S_AXI_ARESETN ,
        prmry_in             => XIPSR_CPHA_CPOL_ERR ,
        scndry_aclk          => S_AXI4_ACLK ,
            prmry_vect_in        => (others => '0') ,
        scndry_resetn        => S_AXI4_ARESET ,
        scndry_out           => XIPSR_CPHA_CPOL_ERR_4
    ); 
--==================================================================================

end generate LOGIC_GENERATION_CDC;


XIPSR_RX_EMPTY_P: process(S_AXI_ACLK)is
begin
    if(S_AXI_ACLK'event and S_AXI_ACLK = '1')then
        if(S_AXI_ARESETN =  ACTIVE_HIGH_RESET) then
            TO_XIPSR_axi_rx_empty <= '1';
        elsif(axi4_tr_over = '1')then
            TO_XIPSR_axi_rx_empty <= '1';
        elsif(new_tr_at_axi4 = '1')then
            TO_XIPSR_axi_rx_empty <= '0';
        end if;
    end if;
end process XIPSR_RX_EMPTY_P;
-------------------------------------

TO_XIPSR_trans_error      <= XIP_trans_error;
TO_XIPSR_mst_modf_err     <= mst_modf_err_to_axi_clk;
TO_XIPSR_axi_rx_full      <= Rx_FIFO_Full_to_axi_clk;


-- XIP_PS_TO_NS_PROCESS: stores the next state memory
XIP_PS_TO_NS_PROCESS: process(S_AXI4_ACLK)is
-----
begin
-----
    if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
        if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
            xip_sm_ps <= IDLE;
        else
            xip_sm_ps <= xip_sm_ns;
        end if;
    end if;
end process XIP_PS_TO_NS_PROCESS;
-----------------------------
-- XIP_SM_P: below state machine is AXI interface state machine and controls the 
--           acceptance of new transaction as well as monitors data transaction
XIP_SM_P:process(
                 xip_sm_ps              ,
                 S_AXI4_ARVALID          ,
                 S_AXI4_RREADY          ,
                 S_AXI4_ARBURST         ,
                 XIP_trans_error_cmb        ,
                 mst_modf_err_to_axi4_clk,
                 Rx_FIFO_Full_to_Axi4_clk,
                 XIPSR_CPHA_CPOL_ERR_4  ,
                 Rx_FIFO_Empty          ,
                 wb_hpm_done_to_axi     ,
                 spiXfer_done_to_axi_1  ,
                 last_data_cmb          ,
                 Rx_FIFO_rd_ack         ,--,
                 last_data_acked
                 --wrap_around_to_axi_clk ,
                 --last_bt_one_data_cmb   ,
                 --Rx_FIFO_Empty          ,
                 --only_last_count        ,
                 --rx_fifo_not_empty      ,
                 --rx_fifo_count          ,
                 )is

begin
-----
    s_axi_arready_cmb <= '0';
    load_axi_data_frm_axi <= '0';
    load_cmd          <= '0';
    s_axi_rlast_cmb <= '0';
    s_axi_rvalid_cmb  <= '0';
    last_data <= '0';
    --IO0_T_cntrl_axi <= '1';
    --IO1_T_cntrl_axi <= '1';
    --IO2_T_cntrl_axi <= '1';
    --IO3_T_cntrl_axi <= '1';
    --SCK_T_cntrl_axi <= '1';

    temp_i          <= '0';

    case xip_sm_ps is
        when IDLE      => --if(XIP_cmd_error = '0') then
                            if(S_AXI4_ARVALID = '1')           and
                              (XIP_trans_error_cmb = '0')          and
                              (mst_modf_err_to_axi4_clk = '0') and
                              (Rx_FIFO_Full_to_axi4_clk = '0') and
                              (XIPSR_CPHA_CPOL_ERR_4 = '0')    and
                              (Rx_FIFO_Empty = '1')            and
                              (wb_hpm_done_to_axi = '1')
                              then
                              s_axi_arready_cmb     <= S_AXI4_ARVALID;
                              load_axi_data_frm_axi <= S_AXI4_ARVALID;
                              load_cmd              <= S_AXI4_ARVALID;
                              xip_sm_ns             <= RD_BURST;
                          else
                              xip_sm_ns <= IDLE;
                          end if;
        when RD_BURST =>
                         --if(last_data_cmb = '1') and (Rx_FIFO_rd_ack = '1') then--(rx_fifo_count = "000001") then
						 if (last_data_acked = '1') then
                             if(S_AXI4_RREADY = '1') then
                                 temp_i    <= '1';
                                 xip_sm_ns <= IDLE;
                             else
                                 xip_sm_ns <= RD_BURST;
                             end if;
                         else
                             xip_sm_ns <= RD_BURST;
                         end if;
        -- coverage off
        when others => xip_sm_ns <= IDLE;
        -- coverage on
    end case;
end process XIP_SM_P;
----------------------
-- AXI_24_BIT_ADDR_STORE_GEN: stores 24 bit axi address
AXI_24_BIT_ADDR_STORE_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
begin
    LOAD_TRANSMIT_ADDR_P:process(S_AXI4_ACLK)is
    -----
    begin
    -----
         if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
            if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
                Transmit_addr_int <= (others => '0');
            elsif(load_axi_data_frm_axi = '1') then
                Transmit_addr_int <= S_AXI4_ARADDR(23 downto 0);-- & XIPCR_7_0_CMD;
            end if;
         end if;
    end process LOAD_TRANSMIT_ADDR_P;
end generate AXI_24_BIT_ADDR_STORE_GEN;
-----------------------------------------
-- AXI_32_BIT_ADDR_STORE_GEN: stores 32 bit axi address
AXI_32_BIT_ADDR_STORE_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate -- 3/30/2013 updated for 32 or 24 bit addressing modes
begin
    LOAD_TRANSMIT_ADDR_P:process(S_AXI4_ACLK)is
    -----
    begin
    -----
         if(S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
            if(S_AXI4_ARESET =  ACTIVE_HIGH_RESET) then
                Transmit_addr_int <= (others => '0');
            elsif(load_axi_data_frm_axi = '1') then
                Transmit_addr_int <= S_AXI4_ARADDR(C_SPI_MEM_ADDR_BITS-1 downto 0);-- & XIPCR_7_0_CMD;
            end if;
         end if;
    end process LOAD_TRANSMIT_ADDR_P;
end generate AXI_32_BIT_ADDR_STORE_GEN;
-----------------------------------------
                         --      24/32-bit     --
  --    AXI Clk domain   -- __________________ SPI clk domain
  --Dout                 --|AXI clk           |-- Din
  --Rd_en                --|                  |-- Wr_en
  --Rd_clk               --|                  |-- Wr_clk
                         --|                  |--
  --Rx_FIFO_Empty        --|    Rx FIFO       |-- Rx_FIFO_Full
  --Rx_FIFO_almost_Empty --|                  |-- Rx_FIFO_almost_Full
  --Rx_FIFO_occ_Reversed --|                  |--
  --Rx_FIFO_rd_ack       --|                  |--
                         --|                  |--
                         --|                  |--
                         --|                  |--
                         --|__________________|--


-------------------------------------------------------------------------------
XIP_RECEIVE_FIFO_II: entity lib_fifo_v1_0_3.async_fifo_fg
  generic map(
        -- 3/30/2013 starts
        --C_PRELOAD_LATENCY  => 0                  ,-- this is newly added and async_fifo_fg is referred from proc common v4_0
        --C_PRELOAD_REGS     => 1                  ,-- this is newly added and async_fifo_fg is referred from proc common v4_0
        -- 3/30/2013 ends

        -- variables
        C_ALLOW_2N_DEPTH   => 1                   , -- : Integer := 0;  -- New paramter to leverage FIFO Gen 2**N depth
        C_FAMILY           => C_FAMILY            , -- : String  := "virtex5";  -- new for FIFO Gen
        C_DATA_WIDTH       => C_S_AXI4_DATA_WIDTH , -- : integer := 16;
        C_FIFO_DEPTH       => C_XIP_FIFO_DEPTH    , -- : integer := 256;
        C_RD_COUNT_WIDTH   => C_RD_COUNT_WIDTH_INT, -- : integer := 3 ;
        C_WR_COUNT_WIDTH   => C_WR_COUNT_WIDTH_INT, -- : integer := 3 ;
        C_HAS_ALMOST_EMPTY => 1                   , -- : integer := 1 ;
        C_HAS_ALMOST_FULL  => 1                   , -- : integer := 1 ;
        C_HAS_RD_ACK       => 1                   , -- : integer := 0 ;
        C_HAS_RD_COUNT     => 1                   , -- : integer := 1 ;
        C_HAS_WR_ACK       => 1                   , -- : integer := 0 ;
        C_HAS_WR_COUNT     => 1                   , -- : integer := 1 ;
        -- constants
        C_HAS_RD_ERR       => 0                   , -- : integer := 0 ;
        C_HAS_WR_ERR       => 0                   , -- : integer := 0 ;
        C_RD_ACK_LOW       => 0                   , -- : integer := 0 ;
        C_RD_ERR_LOW       => 0                   , -- : integer := 0 ;
        C_WR_ACK_LOW       => 0                   , -- : integer := 0 ;
        C_WR_ERR_LOW       => 0                   , -- : integer := 0
        C_ENABLE_RLOCS     => 0                   , -- : integer := 0 ;  -- not supported in FG
        C_USE_BLOCKMEM     => 0                     -- : integer := 1 ;  -- 0 = distributed RAM, 1 = BRAM
    )
  port map(
        Dout               => Data_From_Rx_FIFO           , -- : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        Rd_en              => S_AXI4_RREADY               , -- : in std_logic := '0';
        Rd_clk             => S_AXI4_ACLK                 , -- : in std_logic := '1';
        Rd_ack             => Rx_FIFO_rd_ack              , -- : out std_logic;
        ------
        Din                => Data_To_Rx_FIFO             , -- : in std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
        Wr_en              => store_date_in_drr_fifo_en   , --SPIXfer_done_Rx_Wr_en, --            , -- : in std_logic := '1';
        Wr_clk             => EXT_SPI_CLK                 , -- : in std_logic := '1';
        Wr_ack             => open, -- Rx_FIFO_wr_ack_open, -- : out std_logic;
        ------
        Full               => Rx_FIFO_Full, --Rx_FIFO_Full, -- : out std_logic;
        Empty              => Rx_FIFO_Empty               , -- : out std_logic;
        Almost_full        => Rx_FIFO_almost_Full         , -- : out std_logic;
        Almost_empty       => Rx_FIFO_almost_Empty        , -- : out std_logic;
        Rd_count           => open                        , -- : out std_logic_vector(C_RD_COUNT_WIDTH-1 downto 0);
        ------
        Ainit              => Rst_to_spi               ,--reset_RcFIFO_ptr_int, -- reset_RcFIFO_ptr_to_spi_clk ,--Rx_FIFO_ptr_RST             , -- : in std_logic := '1';
        Wr_count           => open                        , -- : out std_logic_vector(C_WR_COUNT_WIDTH-1 downto 0);
        Rd_err             => rd_error_int                , -- : out std_logic;
        Wr_err             => open                          -- : out std_logic
    );
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- from SPI clock
spiXfer_done_frm_spi_clk      <= store_date_in_drr_fifo_en; --spiXfer_done_int;
mst_modf_err_frm_spi_clk      <= not SPISEL_sync; -- 9/7/2013 -- MODF_strobe; -- 9/7/2013
--wrap_around_frm_spi_clk     <= wrap_around;
wb_hpm_done_frm_spi_clk       <= wb_hpm_done;
-- from AXI clocks
--size_length_frm_axi_clk       <= size_length;
one_byte_xfer_frm_axi_clk     <= one_byte_xfer;
two_byte_xfer_frm_axi_clk     <= two_byte_xfer;
four_byte_xfer_frm_axi_clk    <= four_byte_xfer;
load_axi_data_frm_axi_clk     <= load_axi_data_frm_Axi;-- 1 bit
Transmit_Addr_frm_axi_clk     <= Transmit_addr_int;    -- 24 bit
load_cmd_frm_axi_clk          <= load_cmd;
CPOL_frm_axi_clk              <= XIPCR_1_CPOL;         -- 1 bit
CPHA_frm_axi_clk              <= XIPCR_0_CPHA;         -- 1 bit

SS_frm_axi_clk                <= SS_frm_axi;    -- _reg;   -- based upon C_NUM_SS_BITS
type_of_burst_frm_axi_clk     <= type_of_burst; -- 1 bit signal take MSB only to differentiate WRAP and INCR burst
axi_length_frm_axi_clk        <= axi_length;    -- 8 bit used for WRAP transfer
dtr_length_frm_axi_clk        <= dtr_length;    -- 8 bit used for internbal counter

XIP_CLK_DOMAIN_SIGNALS:entity axi_quad_spi_v3_2_5.xip_cross_clk_sync
     generic map(
        C_S_AXI4_DATA_WIDTH     => C_S_AXI4_DATA_WIDTH ,
        Async_Clk               => Async_Clk          ,
        C_NUM_SS_BITS           => C_NUM_SS_BITS       ,
        C_SPI_MEM_ADDR_BITS         => XIP_ADDR_BITS
      )
     port map(
      EXT_SPI_CLK               => EXT_SPI_CLK   ,

      S_AXI4_ACLK               => S_AXI4_ACLK   ,
      S_AXI4_ARESET             => S_AXI4_ARESET ,

      S_AXI_ACLK                => S_AXI_ACLK    ,
      S_AXI_ARESETN             => S_AXI_ARESETN ,

      Rst_from_axi_cdc_to_spi       => Rst_to_spi    ,
      ----------------------------
      spiXfer_done_cdc_from_spi      => spiXfer_done_frm_spi_clk     ,
      spiXfer_done_cdc_to_axi_1     => spiXfer_done_to_axi_1        ,
      ----------------------------
      mst_modf_err_cdc_from_spi      => mst_modf_err_frm_spi_clk     ,
      mst_modf_err_cdc_to_axi       => mst_modf_err_to_axi_clk      ,
      mst_modf_err_cdc_to_axi4      => mst_modf_err_to_axi4_clk     ,
      ----------------------------
      one_byte_xfer_cdc_from_axi     => one_byte_xfer_frm_axi_clk    ,
      one_byte_xfer_cdc_to_spi      => one_byte_xfer_to_spi_clk     ,
      ----------------------------
      two_byte_xfer_cdc_from_axi     => two_byte_xfer_frm_axi_clk    ,
      two_byte_xfer_cdc_to_spi      => two_byte_xfer_to_spi_clk     ,
      ----------------------------
      four_byte_xfer_cdc_from_axi    => four_byte_xfer_frm_axi_clk   ,
      four_byte_xfer_cdc_to_spi     => four_byte_xfer_to_spi_clk    ,
      ----------------------------
      load_axi_data_cdc_from_axi     => load_axi_data_frm_axi_clk    ,
      load_axi_data_cdc_to_spi      => load_axi_data_to_spi_clk     ,
      ----------------------------
      Transmit_Addr_cdc_from_axi     => Transmit_Addr_frm_axi_clk    ,
      Transmit_Addr_cdc_to_spi      => Transmit_Addr_to_spi_clk     ,
      ----------------------------
      load_cmd_cdc_from_axi          => load_cmd_frm_axi_clk         ,
      load_cmd_cdc_to_spi           => load_cmd_to_spi_clk          ,
      ----------------------------
      CPOL_cdc_from_axi              => CPOL_frm_axi_clk             ,
      CPOL_cdc_to_spi               => CPOL_to_spi_clk              ,
      ----------------------------
      CPHA_cdc_from_axi              => CPHA_frm_axi_clk             ,
      CPHA_cdc_to_spi               => CPHA_to_spi_clk              ,
      ------------------------------
      SS_cdc_from_axi                => SS_frm_axi_clk               ,
      SS_cdc_to_spi                 => SS_to_spi_clk                ,
      ----------------------------
      type_of_burst_cdc_from_axi     => type_of_burst_frm_axi_clk    ,
      type_of_burst_cdc_to_spi      => type_of_burst_to_spi_clk     ,
      ----------------------------
      axi_length_cdc_from_axi        => axi_length_frm_axi_clk       ,
      axi_length_cdc_to_spi         => axi_length_to_spi_clk        ,
      ----------------------------
      dtr_length_cdc_from_axi        => dtr_length_frm_axi_clk       ,
      dtr_length_cdc_to_spi         => dtr_length_to_spi_clk        , --,
      ----------------------------
      Rx_FIFO_Full_cdc_from_spi      => Rx_FIFO_Full                 ,
      Rx_FIFO_Full_cdc_to_axi       => Rx_FIFO_Full_to_axi_clk      ,
      Rx_FIFO_Full_cdc_to_axi4      => Rx_FIFO_Full_to_axi4_clk     ,
      ----------------------------
      wb_hpm_done_cdc_from_spi       => wb_hpm_done_frm_spi_clk      ,
      wb_hpm_done_cdc_to_axi        => wb_hpm_done_to_axi
     );

-------------------------------------------------------------------------------
-- STORE_NEW_TR_P: This process is used in INCR and WRAP to check for any new transaction from AXI
STORE_NEW_TR_32_BIT_ADDR_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
begin
-----
     -------------------------------------
     STORE_NEW_TR_P:process(EXT_SPI_CLK)is
     -----
     begin
     -----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
             if(Rst_to_spi = '1') then
                     new_tr <= '0';
             elsif( (load_axi_data_to_spi_clk = '1') 
                 or (load_wr_hpm = '1') -- needed for enabling 32 bit addressing mode
                 or (load_wr_en = '1')  -- needed for write enabling before enabling the 32 bit addressing mode
                 ) then
                     new_tr <= '1';
             elsif(SR_5_Tx_Empty_int = '1') then --(wrap_around = '0' and qspi_cntrl_ns = IDLE)then
                     new_tr <= '0';
             end if;
     end if;
     end process STORE_NEW_TR_P;
     -------------------------------------
end generate STORE_NEW_TR_32_BIT_ADDR_GEN;
---------------------------------------------

STORE_NEW_TR_24_BIT_ADDR_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
begin
-----
        -------------------------------------
	STORE_NEW_TR_P:process(EXT_SPI_CLK)is
	-----
	begin
	-----
	if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
		if(Rst_to_spi = '1') then
			new_tr <= '0';
		elsif(  (load_axi_data_to_spi_clk = '1') 
		     or (load_wr_hpm = '1') 
                 -- or (load_wr_en = '1') 
                     ) then
			new_tr <= '1';
		elsif(SR_5_Tx_Empty_int = '1') then --(wrap_around = '0' and qspi_cntrl_ns = IDLE)then
			new_tr <= '0';
		end if;
	end if;
	end process STORE_NEW_TR_P;
        -------------------------------------
end generate STORE_NEW_TR_24_BIT_ADDR_GEN;
-------------------------------------------------------------------------------

-- STORE_INITAL_ADDR_P: The address frm AXI should be stored in the SPI environment
-- as the address generation logic will work in this domain.
STORE_24_BIT_SPI_ADDR_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
begin
-----
    -------------------------------------
    STORE_INITAL_ADDR_P:process(EXT_SPI_CLK)is
    -----
    begin
    -----
         if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
             if(Rst_to_spi = '1') then
                spi_addr <= (others => '0');
             elsif(load_axi_data_to_spi_clk = '1')then
                spi_addr <= "00000000" & Transmit_Addr_to_spi_clk;-- (31 downto 8);
             elsif(load_wrap_addr = '1')then --  and (type_of_burst_to_spi = '1') then
                spi_addr <= "00000000" & spi_addr_wrap;
             end if;
         end if;
    end process STORE_INITAL_ADDR_P;
    -------------------------------------
end generate STORE_24_BIT_SPI_ADDR_GEN;
-----------------------------------------

STORE_32_BIT_SPI_ADDR_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate -- 3/30/2013
begin
-----
     ----------------------------------
     STORE_INITAL_ADDR_P:process(EXT_SPI_CLK)is
     -----
     begin
     -----
          if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
              if(Rst_to_spi = '1') then
                 spi_addr <= (others => '0');
              elsif(load_axi_data_to_spi_clk = '1')then
                 spi_addr <= Transmit_Addr_to_spi_clk;-- (31 downto 0);
              elsif(load_wrap_addr = '1')then --  and (type_of_burst_to_spi = '1') then
                 spi_addr <= spi_addr_wrap;
              end if;
          end if;
     end process STORE_INITAL_ADDR_P;
     ----------------------------------
end generate STORE_32_BIT_SPI_ADDR_GEN;
---------------------------------------
-------------------------------------------------------------------------------

-- below signals will store the length of AXI transaction in the SPI domain
axi_len_two     <= not(or_Reduce(axi_length_to_spi_clk(3 downto 1))) and
                                 axi_length_to_spi_clk(0);
axi_len_four    <= not(or_Reduce(axi_length_to_spi_clk(3 downto 2))) and
                       and_reduce(axi_length_to_spi_clk(1 downto 0));
axi_len_eight   <= not(axi_length_to_spi_clk(3)) and
                      and_Reduce(axi_length_to_spi_clk(2 downto 0));
axi_len_sixteen <= and_reduce(axi_length_to_spi_clk(3 downto 0));
-------------------------------------------------------------------------------

-- below signals store the WRAP information in SPI domain
wrap_two       <= '1' when (type_of_burst_to_spi_clk = '1' and
                            axi_len_two = '1')
                  else
                  '0';
wrap_four      <= '1' when (type_of_burst_to_spi_clk = '1' and
                            axi_len_four = '1')
                  else
                  '0';
wrap_eight     <= '1' when (type_of_burst_to_spi_clk = '1' and
                            axi_len_eight = '1')
                  else
                  '0';
wrap_sixteen   <= '1' when (type_of_burst_to_spi_clk = '1' and
                            axi_len_sixteen = '1')
                  else
                  '0';
-------------------------------------------------------------------------------

-- SPI_ADDRESS_REG: This process stores the initial address coming from the AXI in
--                  two registers. one register will store this address till the
--                  transaction ends, while other will be updated based upon type of
--                  transaction as well as at the end of each SPI transfer. this is
--                  used for internal use only.
SPI_24_BIT_ADDRESS_REG_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate 
begin
-----
    SPI_ADDRESS_REG : process(EXT_SPI_CLK) is
    --variable xfer : std_logic_vector(2 downto 0);
    begin
    --   xfer := four_byte_xfer_to_spi_clk & two_byte_xfer_to_spi_clk & one_byte_xfer_to_spi_clk;
       if (EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
           if (Rst_to_spi = RESET_ACTIVE) then
              spi_addr_i <= (others => '0');
              spi_addr_int <= (others => '0');
           else
              if (load_cmd_to_spi_clk = '1') then
                     spi_addr_i   <= Transmit_Addr_to_spi_clk(23 downto 0);
                     spi_addr_int <= Transmit_Addr_to_spi_clk(23 downto 0);
              -- below is address generation for the WRAP mode
              elsif (type_of_burst_to_spi_clk = '1')  and
                    (SPIXfer_done_int_pulse_d2 = '1') and
                    (cmd_addr_sent = '1') then
                  spi_addr_int(23 downto 0) <= spi_addr_int(23 downto 0) + '1';
                  case size_length_cntr is
                  when "00" => -- 8-bit access
                    if(wrap_two = '1') then
                      spi_addr_i(23 downto 1) <= spi_addr_i(23 downto 1);
                      spi_addr_i(0)           <= not (spi_addr_i(0));
                    elsif(wrap_four = '1') then -- the byte address increment will take 2 address bits
                      spi_addr_i(23 downto 2) <= spi_addr_i(23 downto 2);
                      spi_addr_i(1 downto 0)  <= spi_addr_i(1 downto 0) + "01";
                    elsif(wrap_eight = '1') then -- the byte address increment will take 3 address bits
                      spi_addr_i(23 downto 3) <= spi_addr_i(23 downto 3);
                      spi_addr_i(2 downto 0)  <= spi_addr_i(2 downto 0) + "001";
                    elsif(wrap_sixteen = '1') then -- the byte address increment will take 4 address bits for 16's wrap
                      spi_addr_i(23 downto 4) <= spi_addr_i(23 downto 4);
                      spi_addr_i(3 downto 0)  <= spi_addr_i(3 downto 0) + "0001";
                    else
                      spi_addr_i <= spi_addr_i + "0001";
                    end if;
                  when "01" => -- 16-bit access
                    if(wrap_two = '1') then
                      spi_addr_i(23 downto 2) <= spi_addr_i(23 downto 2);
                      spi_addr_i(1 downto 0)  <= spi_addr_i(1 downto 0) + "10";
                    elsif(wrap_four = '1') then
                      spi_addr_i(23 downto 3) <= spi_addr_i(23 downto 3);
                      spi_addr_i(2 downto 0)  <= spi_addr_i(2 downto 0) + "010";
                    elsif(wrap_eight = '1') then
                      spi_addr_i(23 downto 4) <= spi_addr_i(23 downto 4);
                      spi_addr_i(3 downto 0)  <= spi_addr_i(3 downto 0) + "0010";
                    elsif(wrap_sixteen = '1') then
                      spi_addr_i(23 downto 5) <= spi_addr_i(23 downto 5);
                      spi_addr_i(4 downto 0)  <= spi_addr_i(4 downto 0) + "00010";
                    else
                      spi_addr_i <= spi_addr_i + "0010";
                    end if;
                when "10" => -- 32-bit access
                    if(wrap_two = '1') then
                      spi_addr_i(23 downto 3) <= spi_addr_i(23 downto 3);
                      spi_addr_i(2 downto 0)  <=spi_addr_i(2 downto 0) + "100";
                    elsif(wrap_four = '1') then
                      spi_addr_i(23 downto 4) <= spi_addr_i(23 downto 4);
                      spi_addr_i(3 downto 0)  <=spi_addr_i(3 downto 0) + "0100";
                    elsif(wrap_eight = '1') then
                      spi_addr_i(23 downto 5) <= spi_addr_i(23 downto 5);
                      spi_addr_i(4 downto 0)  <=spi_addr_i(4 downto 0) + "00100";
                    elsif(wrap_sixteen = '1') then
                      spi_addr_i(23 downto 6) <= spi_addr_i(23 downto 6);
                      spi_addr_i(5 downto 0)  <=spi_addr_i(5 downto 0) + "000100";
                    else
                       spi_addr_i <= spi_addr_i + "0100";
                    end if;
                  -- coverage off
                  when others =>
                    spi_addr_i <= spi_addr_i;
                  -- coverage on
                  end case;
           -- below is address generation for the INCR mode
           elsif (type_of_burst_to_spi_clk = '0')  and
                 (SPIXfer_done_int_pulse_d2 = '1') and
                 (cmd_addr_sent = '1') then
                  spi_addr_i(23 downto 0) <= spi_addr_i(23 downto 0) + '1';
           end if;
       end if;
      end if;
    end process SPI_ADDRESS_REG;
    ----------------------------------
end generate SPI_24_BIT_ADDRESS_REG_GEN;
----------------------------------------

SPI_32_BIT_ADDRESS_REG_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate 
begin
-----
    SPI_ADDRESS_REG : process(EXT_SPI_CLK) is
    --variable xfer : std_logic_vector(2 downto 0);
    begin
    --   xfer := four_byte_xfer_to_spi_clk & two_byte_xfer_to_spi_clk & one_byte_xfer_to_spi_clk;
       if (EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
           if (Rst_to_spi = RESET_ACTIVE) then
              spi_addr_i <= (others => '0');
              spi_addr_int <= (others => '0');
           else
              if (load_cmd_to_spi_clk = '1') then
                     spi_addr_i   <= Transmit_Addr_to_spi_clk(31 downto 0);
                     spi_addr_int <= Transmit_Addr_to_spi_clk(31 downto 0);
              -- below is address generation for the WRAP mode
              elsif (type_of_burst_to_spi_clk = '1')  and
                    (SPIXfer_done_int_pulse_d2 = '1') and
                    (cmd_addr_sent = '1') then
                  spi_addr_int(31 downto 0) <= spi_addr_int(31 downto 0) + '1';

                  case size_length_cntr is
                    when "00" => -- 8-bit access
                      if(wrap_two = '1') then
                        spi_addr_i(31 downto 1) <= spi_addr_i(31 downto 1);
                        spi_addr_i(0)           <= not (spi_addr_i(0));
                      elsif(wrap_four = '1') then -- the byte address increment will take 2 address bits
                        spi_addr_i(31 downto 2) <= spi_addr_i(31 downto 2);
                        spi_addr_i(1 downto 0)  <= spi_addr_i(1 downto 0) + "01";
                      elsif(wrap_eight = '1') then -- the byte address increment will take 3 address bits
                        spi_addr_i(31 downto 3) <= spi_addr_i(31 downto 3);
                        spi_addr_i(2 downto 0)  <= spi_addr_i(2 downto 0) + "001";
                      elsif(wrap_sixteen = '1') then -- the byte address increment will take 4 address bits for 16's wrap
                        spi_addr_i(31 downto 4) <= spi_addr_i(31 downto 4);
                        spi_addr_i(3 downto 0)  <= spi_addr_i(3 downto 0) + "0001";
                      else
                        spi_addr_i <= spi_addr_i + "0001";
                      end if;
                    when "01" => -- 16-bit access
                      if(wrap_two = '1') then
                        spi_addr_i(31 downto 2) <= spi_addr_i(31 downto 2);
                        spi_addr_i(1 downto 0)  <= spi_addr_i(1 downto 0) + "10";
                      elsif(wrap_four = '1') then
                        spi_addr_i(31 downto 3) <= spi_addr_i(31 downto 3);
                        spi_addr_i(2 downto 0)  <= spi_addr_i(2 downto 0) + "010";
                      elsif(wrap_eight = '1') then
                        spi_addr_i(31 downto 4) <= spi_addr_i(31 downto 4);
                        spi_addr_i(3 downto 0)  <= spi_addr_i(3 downto 0) + "0010";
                      elsif(wrap_sixteen = '1') then
                        spi_addr_i(31 downto 5) <= spi_addr_i(31 downto 5);
                        spi_addr_i(4 downto 0)  <= spi_addr_i(4 downto 0) + "00010";
                      else
                        spi_addr_i <= spi_addr_i + "0010";
                      end if;
                    when "10" => -- 32-bit access
                      if(wrap_two = '1') then
                        spi_addr_i(31 downto 3) <= spi_addr_i(31 downto 3);
                        spi_addr_i(2 downto 0)  <=spi_addr_i(2 downto 0) + "100";
                      elsif(wrap_four = '1') then
                        spi_addr_i(31 downto 4) <= spi_addr_i(31 downto 4);
                        spi_addr_i(3 downto 0)  <=spi_addr_i(3 downto 0) + "0100";
                      elsif(wrap_eight = '1') then
                        spi_addr_i(31 downto 5) <= spi_addr_i(31 downto 5);
                        spi_addr_i(4 downto 0)  <=spi_addr_i(4 downto 0) + "00100";
                      elsif(wrap_sixteen = '1') then
                        spi_addr_i(31 downto 6) <= spi_addr_i(31 downto 6);
                        spi_addr_i(5 downto 0)  <=spi_addr_i(5 downto 0) + "000100";
                      else
                         spi_addr_i <= spi_addr_i + "0100";
                      end if;
                  -- coverage off
                  when others =>
                    spi_addr_i <= spi_addr_i;
                  -- coverage on
                  end case;
           -- below is address generation for the INCR mode
           elsif (type_of_burst_to_spi_clk = '0')  and
                 (SPIXfer_done_int_pulse_d2 = '1') and
                 (cmd_addr_sent = '1') then
                  spi_addr_i(31 downto 0) <= spi_addr_i(31 downto 0) + '1';
           end if;
       end if;
      end if;
    end process SPI_ADDRESS_REG;
end generate SPI_32_BIT_ADDRESS_REG_GEN;
----------------------------------------

-- SPI_WRAP_ADDR_REG: this is separate process used for WRAP address generation
SPI_24_WRAP_ADDR_REG_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate 
begin
  SPI_WRAP_ADDR_REG : process(EXT_SPI_CLK) is
  --variable xfer : std_logic_vector(2 downto 0);
  begin
  --   xfer := four_byte_xfer_to_spi_clk & two_byte_xfer_to_spi_clk & one_byte_xfer_to_spi_clk;
     if (EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
         if (Rst_to_spi = RESET_ACTIVE) then
            spi_addr_wrap <= (others => '0');
         else
            if (load_cmd_to_spi_clk = '1') then
                   spi_addr_wrap   <= Transmit_Addr_to_spi_clk(23 downto 0);
            elsif(wrap_ack_1 = '1') then
                   spi_addr_wrap <= spi_addr_wrap_1;
            -- below is address generation for the WRAP mode
            elsif (type_of_burst_to_spi_clk = '1') and
                  (store_date_in_drr_fifo = '1')   and
                  (cmd_addr_sent = '1') then
                case size_length_cntr_fixed is
                when "00" => -- 8-bit access
                  if(wrap_two = '1') then
                    spi_addr_wrap(23 downto 1) <= spi_addr_wrap(23 downto 1);
                    spi_addr_wrap(0)           <= not (spi_addr_wrap(0));
                  elsif(wrap_four = '1') then -- the byte address increment will take 2 address bits
                    spi_addr_wrap(23 downto 2) <= spi_addr_wrap(23 downto 2);
                    spi_addr_wrap(1 downto 0)  <= spi_addr_wrap(1 downto 0) + "01";
                  elsif(wrap_eight = '1') then -- the byte address increment will take 3 address bits
                    spi_addr_wrap(23 downto 3) <= spi_addr_wrap(23 downto 3);
                    spi_addr_wrap(2 downto 0)  <= spi_addr_wrap(2 downto 0) + "001";
                  elsif(wrap_sixteen = '1') then -- the byte address increment will take 4 address bits for 16's wrap
                    spi_addr_wrap(23 downto 4) <= spi_addr_wrap(23 downto 4);
                    spi_addr_wrap(3 downto 0)  <= spi_addr_wrap(3 downto 0) + "0001";
                  else
                    spi_addr_wrap <= spi_addr_wrap + "0001";
                  end if;
                when "01" => -- 16-bit access
                  if(wrap_two = '1') then
                    spi_addr_wrap(23 downto 2) <= spi_addr_wrap(23 downto 2);
                    spi_addr_wrap(1 downto 0)  <= spi_addr_wrap(1 downto 0) + "10";
                  elsif(wrap_four = '1') then
                    spi_addr_wrap(23 downto 3) <= spi_addr_wrap(23 downto 3);
                    spi_addr_wrap(2 downto 0)  <= spi_addr_wrap(2 downto 0) + "010";
                  elsif(wrap_eight = '1') then
                    spi_addr_wrap(23 downto 4) <= spi_addr_wrap(23 downto 4);
                    spi_addr_wrap(3 downto 0)  <= spi_addr_wrap(3 downto 0) + "0010";
                  elsif(wrap_sixteen = '1') then
                    spi_addr_wrap(23 downto 5) <= spi_addr_wrap(23 downto 5);
                    spi_addr_wrap(4 downto 0)  <= spi_addr_wrap(4 downto 0) + "00010";
                  else
                    spi_addr_wrap <= spi_addr_wrap + "0010";
                  end if;
                when "10" => -- 32-bit access
                    if(wrap_two = '1') then
                      spi_addr_wrap(23 downto 3) <= spi_addr_wrap(23 downto 3);
                      spi_addr_wrap(2 downto 0)  <=spi_addr_wrap(2 downto 0) + "100";
                    elsif(wrap_four = '1') then
                      spi_addr_wrap(23 downto 4) <= spi_addr_wrap(23 downto 4);
                      spi_addr_wrap(3 downto 0)  <=spi_addr_wrap(3 downto 0) + "0100";
                    elsif(wrap_eight = '1') then
                      spi_addr_wrap(23 downto 5) <= spi_addr_wrap(23 downto 5);
                      spi_addr_wrap(4 downto 0)  <=spi_addr_wrap(4 downto 0) + "00100";
                    elsif(wrap_sixteen = '1') then
                      spi_addr_wrap(23 downto 6) <= spi_addr_wrap(23 downto 6);
                      spi_addr_wrap(5 downto 0)  <=spi_addr_wrap(5 downto 0) + "000100";
                    else
                       spi_addr_wrap <= spi_addr_wrap + "0100";
                    end if;
                -- coverage off
                when others =>
                  spi_addr_wrap <= spi_addr_wrap;
                -- coverage on
                end case;
         end if;
     end if;
    end if;
  end process SPI_WRAP_ADDR_REG;
end generate SPI_24_WRAP_ADDR_REG_GEN;
--------------------------------------
SPI_32_WRAP_ADDR_REG_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate 
begin
  SPI_WRAP_ADDR_REG : process(EXT_SPI_CLK) is
  --variable xfer : std_logic_vector(2 downto 0);
  begin
  --   xfer := four_byte_xfer_to_spi_clk & two_byte_xfer_to_spi_clk & one_byte_xfer_to_spi_clk;
     if (EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
         if (Rst_to_spi = RESET_ACTIVE) then
            spi_addr_wrap <= (others => '0');
         else
            if (load_cmd_to_spi_clk = '1') then
                   spi_addr_wrap   <= Transmit_Addr_to_spi_clk(31 downto 0);
            elsif(wrap_ack_1 = '1') then
                   spi_addr_wrap <= spi_addr_wrap_1;
            -- below is address generation for the WRAP mode
            elsif (type_of_burst_to_spi_clk = '1') and
                  (store_date_in_drr_fifo = '1')   and
                  (cmd_addr_sent = '1') then
                case size_length_cntr_fixed is
                  when "00" => -- 8-bit access
                    if(wrap_two = '1') then
                      spi_addr_wrap(31 downto 1) <= spi_addr_wrap(31 downto 1);
                      spi_addr_wrap(0)           <= not (spi_addr_wrap(0));
                    elsif(wrap_four = '1') then -- the byte address increment will take 2 address bits
                      spi_addr_wrap(31 downto 2) <= spi_addr_wrap(31 downto 2);
                      spi_addr_wrap(1 downto 0)  <= spi_addr_wrap(1 downto 0) + "01";
                    elsif(wrap_eight = '1') then -- the byte address increment will take 3 address bits
                      spi_addr_wrap(31 downto 3) <= spi_addr_wrap(31 downto 3);
                      spi_addr_wrap(2 downto 0)  <= spi_addr_wrap(2 downto 0) + "001";
                    elsif(wrap_sixteen = '1') then -- the byte address increment will take 4 address bits for 16's wrap
                      spi_addr_wrap(31 downto 4) <= spi_addr_wrap(31 downto 4);
                      spi_addr_wrap(3 downto 0)  <= spi_addr_wrap(3 downto 0) + "0001";
                    else
                      spi_addr_wrap <= spi_addr_wrap + "0001";
                    end if;
                  when "01" => -- 16-bit access
                    if(wrap_two = '1') then
                      spi_addr_wrap(31 downto 2) <= spi_addr_wrap(31 downto 2);
                      spi_addr_wrap(1 downto 0)  <= spi_addr_wrap(1 downto 0) + "10";
                    elsif(wrap_four = '1') then
                      spi_addr_wrap(31 downto 3) <= spi_addr_wrap(31 downto 3);
                      spi_addr_wrap(2 downto 0)  <= spi_addr_wrap(2 downto 0) + "010";
                    elsif(wrap_eight = '1') then
                      spi_addr_wrap(31 downto 4) <= spi_addr_wrap(31 downto 4);
                      spi_addr_wrap(3 downto 0)  <= spi_addr_wrap(3 downto 0) + "0010";
                    elsif(wrap_sixteen = '1') then
                      spi_addr_wrap(31 downto 5) <= spi_addr_wrap(31 downto 5);
                      spi_addr_wrap(4 downto 0)  <= spi_addr_wrap(4 downto 0) + "00010";
                    else
                      spi_addr_wrap <= spi_addr_wrap + "0010";
                    end if;
                  when "10" => -- 32-bit access
                    if(wrap_two = '1') then
                      spi_addr_wrap(31 downto 3) <= spi_addr_wrap(31 downto 3);
                      spi_addr_wrap(2 downto 0)  <=spi_addr_wrap(2 downto 0) + "100";
                    elsif(wrap_four = '1') then
                      spi_addr_wrap(31 downto 4) <= spi_addr_wrap(31 downto 4);
                      spi_addr_wrap(3 downto 0)  <=spi_addr_wrap(3 downto 0) + "0100";
                    elsif(wrap_eight = '1') then
                      spi_addr_wrap(31 downto 5) <= spi_addr_wrap(31 downto 5);
                      spi_addr_wrap(4 downto 0)  <=spi_addr_wrap(4 downto 0) + "00100";
                    elsif(wrap_sixteen = '1') then
                      spi_addr_wrap(31 downto 6) <= spi_addr_wrap(31 downto 6);
                      spi_addr_wrap(5 downto 0)  <=spi_addr_wrap(5 downto 0) + "000100";
                    else
                       spi_addr_wrap <= spi_addr_wrap + "0100";
                    end if;
                  -- coverage off
                  when others =>
                    spi_addr_wrap <= spi_addr_wrap;
                  -- coverage on
                end case;
         end if;
     end if;
    end if;
  end process SPI_WRAP_ADDR_REG;
  ----------------------------------
end generate SPI_32_WRAP_ADDR_REG_GEN;

--------------------------------------
-------------------------------------------------------------------------------
-- SPI_WRAP_ADDR_REG: this is separate process used for WRAP address generation
LOAD_SPI_WRAP_ADDR_REG : process(EXT_SPI_CLK) is
begin
-----
   if (EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
       if (Rst_to_spi = RESET_ACTIVE) then
          spi_addr_wrap_1 <= (others => '0');
       else
          if (wrap_around = '1') then
          -- below is address generation for the WRAP mode
              case size_length_cntr_fixed is
                when "00" => -- 8-bit access
                  if(wrap_two = '1') then
                    spi_addr_wrap_1 <= spi_addr_wrap + '1';
                  elsif(wrap_four = '1') then -- the byte address increment will take 2 address bits
                    spi_addr_wrap_1 <= spi_addr_wrap + "01";
                  elsif(wrap_eight = '1') then -- the byte address increment will take 3 address bits
                    spi_addr_wrap_1 <= spi_addr_wrap + "001";
                  elsif(wrap_sixteen = '1') then -- the byte address increment will take 4 address bits for 16's wrap
                    spi_addr_wrap_1 <= spi_addr_wrap + "0001";
                  else
                    spi_addr_wrap_1 <= spi_addr_wrap + "0001";
                  end if;
                when "01" => -- 16-bit access
                  if(wrap_two = '1') then
                    spi_addr_wrap_1 <= spi_addr_wrap + "10";
                  elsif(wrap_four = '1') then
                    spi_addr_wrap_1 <= spi_addr_wrap + "010";
                  elsif(wrap_eight = '1') then
                    spi_addr_wrap_1 <= spi_addr_wrap + "0010";
                  elsif(wrap_sixteen = '1') then
                    spi_addr_wrap_1 <= spi_addr_wrap + "00010";
                  else
                    spi_addr_wrap_1 <= spi_addr_wrap + "0010";
                  end if;
                when "10" => -- 32-bit access
                  if(wrap_two = '1') then
                    spi_addr_wrap_1 <=spi_addr_wrap + "100";
                  elsif(wrap_four = '1') then
                    spi_addr_wrap_1 <=spi_addr_wrap + "0100";
                  elsif(wrap_eight = '1') then
                    spi_addr_wrap_1 <=spi_addr_wrap + "00100";
                  elsif(wrap_sixteen = '1') then
                    spi_addr_wrap_1 <=spi_addr_wrap + "000100";
                  else
                    spi_addr_wrap_1 <=spi_addr_wrap + "0100";
                  end if;
                -- coverage off
                when others =>
                  spi_addr_wrap_1 <= spi_addr_wrap;
                -- coverage on
              end case;
       end if;
   end if;
  end if;
end process LOAD_SPI_WRAP_ADDR_REG;
-------------------------------------------------------------------------------
-- WRAP_AROUND_GEN_P : WRAP boundary detection logic
WRAP_AROUND_GEN_P:process(EXT_SPI_CLK)is
begin
-----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
         if(  (Rst_to_spi = '1')
	    or(rst_wrap_around = '1')
	   ) then
              wrap_around <= '0';
         elsif(type_of_burst_to_spi_clk = '1')then
             case size_length_cntr_fixed is
                 when "00" => -- byte transfer
                     if(wrap_two = '1')         and
                       (spi_addr_wrap(1) = '1') and
                       (store_date_in_drr_fifo = '1')then -- then
                       wrap_around <= --spi_addr_wrap(1) and
                                      not SR_5_Tx_Empty;
                     elsif(wrap_four = '1')                  and
                          (spi_addr_wrap(1 downto 0) = "11") and
                          (store_date_in_drr_fifo = '1')then -- then -- the byte address increment will take 2 address bits
                       wrap_around <= --and_reduce(spi_addr_wrap(1 downto 0)) and
                                      not SR_5_Tx_Empty;
                     elsif(wrap_eight = '1')                  and
                          (spi_addr_wrap(2 downto 0) = "111") and
                          (store_date_in_drr_fifo = '1')then -- then -- the byte address increment will take 3 address bits
                       wrap_around <= --and_reduce(spi_addr_wrap(2 downto 0)) and
                                      not SR_5_Tx_Empty;
                     elsif(wrap_sixteen = '1')                 and
                          (spi_addr_wrap(3 downto 0) = "1111") and
                          (store_date_in_drr_fifo = '1')then -- the byte address increment will take 4 address bits for 16's wrap
                       wrap_around <= --and_reduce(spi_addr_wrap(3 downto 0)) and
                                      not SR_5_Tx_Empty;
                     else
                       wrap_around <= '0';
                     end if;
                 when "01" => -- 16-bit access
                     if(wrap_two = '1') then -- and (spi_addr_wrap(1 downto 0) = "10") and (store_date_in_drr_fifo = '1')then
                       wrap_around <= not SR_5_Tx_Empty      and
                                      store_date_in_drr_fifo and
                                      wrp_addr_len_2_siz_16;
                     elsif(wrap_four = '1') then -- and (spi_addr_wrap(2 downto 0) = "110") and (store_date_in_drr_fifo = '1')then
                       wrap_around <= not SR_5_Tx_Empty      and
                                      store_date_in_drr_fifo and
                                      wrp_addr_len_4_siz_16;
                     elsif(wrap_eight = '1') then -- and (spi_addr_wrap(3 downto 0) = "1110") and (store_date_in_drr_fifo = '1')then
                       wrap_around <= not SR_5_Tx_Empty      and
                                      store_date_in_drr_fifo and
                                      wrp_addr_len_8_siz_16;
                     elsif(wrap_sixteen = '1') then -- and (spi_addr_wrap(4 downto 0) =  "11110") and (store_date_in_drr_fifo = '1') then
                       wrap_around <= not SR_5_Tx_Empty      and
                                      store_date_in_drr_fifo and
                                      wrp_addr_len_16_siz_16;
                     else
                       wrap_around <= '0';
                     end if;
                 when "10" => -- 32-bit access
                     if(wrap_two = '1') then -- and (spi_addr_wrap(2 downto 0) = "100") and (store_date_in_drr_fifo = '1') then
                       wrap_around <= not SR_5_Tx_Empty      and
                                      store_date_in_drr_fifo and
                                      wrp_addr_len_2_siz_32;
                     elsif(wrap_four = '1') then -- and (spi_addr_wrap(3 downto 0) = "1100") and (store_date_in_drr_fifo = '1') then
                       wrap_around <= not SR_5_Tx_Empty      and
                                      store_date_in_drr_fifo and
                                      wrp_addr_len_4_siz_32;
                     elsif(wrap_eight = '1') then -- and (spi_addr_wrap(4 downto 0) = "11100") and (store_date_in_drr_fifo = '1') then
                       wrap_around <= not SR_5_Tx_Empty      and
                                      store_date_in_drr_fifo and
                                      wrp_addr_len_8_siz_32;
                     elsif(wrap_sixteen = '1') then --and (spi_addr_wrap(5 downto 0) = "111100") and (store_date_in_drr_fifo = '1') then
                       wrap_around <=  not SR_5_Tx_Empty      and
                                       store_date_in_drr_fifo and
                                       wrp_addr_len_16_siz_32;
                     else
                       wrap_around <= '0';
                     end if;
                 -- coverage off
                 when others => wrap_around <= wrap_around;
                 -- coverage on
                 end case;
         end if;
     end if;
end process WRAP_AROUND_GEN_P;
-------------------------------------------------------------------------------
load_wrap_addr <= wrap_around;

wrp_addr_len_16_siz_32 <= '1' when (spi_addr_wrap(5 downto 0) = "111100") else '0';
wrp_addr_len_8_siz_32  <= '1' when (spi_addr_wrap(4 downto 0) =  "11100") else '0';
wrp_addr_len_4_siz_32  <= '1' when (spi_addr_wrap(3 downto 0) =   "1100") else '0';
wrp_addr_len_2_siz_32  <= '1' when (spi_addr_wrap(2 downto 0) =    "100") else '0';
-----------------------------------------------------------------------------------
wrp_addr_len_16_siz_16 <= '1' when (spi_addr_wrap(4 downto 0) =  "11110") else '0';
wrp_addr_len_8_siz_16  <= '1' when (spi_addr_wrap(3 downto 0) =   "1110") else '0';
wrp_addr_len_4_siz_16  <= '1' when (spi_addr_wrap(2 downto 0) =    "110") else '0';
wrp_addr_len_2_siz_16  <= '1' when (spi_addr_wrap(1 downto 0) =     "10") else '0';
-----------------------------------------------------------------------------------
-- LEN_CNTR_P: This is data length counter. this counter will start decrementing
--             only when the first 4 bytes are transferred from SPI.
LEN_CNTR_24_BIT_GEN:  if C_SPI_MEM_ADDR_BITS = 24 generate 
begin
-----
  LEN_CNTR_P:process(EXT_SPI_CLK)is
  begin
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
           if(Rst_to_spi = '1') then
               length_cntr <= (others => '0');
           elsif(load_wr_hpm='1') then
               length_cntr <= "00000011";
           elsif(load_cmd_to_spi_clk = '1')then
               length_cntr <= dtr_length_to_spi_clk;
           elsif((SPIXfer_done_int = '1')  and
                 (((size_length_cntr = "00") and
                   (cmd_addr_sent = '1')
                   )or
                   (hpm_under_process_d1 = '1'))
                   )then
               length_cntr <= length_cntr - "00000001";
           end if;
       end if;
  end process LEN_CNTR_P;
  -----------------------
end generate LEN_CNTR_24_BIT_GEN;
---------------------------------
LEN_CNTR_32_BIT_GEN:  if C_SPI_MEM_ADDR_BITS = 32 generate 
begin
-----
  LEN_CNTR_P:process(EXT_SPI_CLK)is
  begin
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
           if(Rst_to_spi = '1') then
               length_cntr <= (others => '0');
           elsif(load_wr_hpm='1') then
               length_cntr <= "00000000";
           elsif(load_cmd_to_spi_clk = '1')then
               length_cntr <= dtr_length_to_spi_clk;
           elsif((SPIXfer_done_int = '1')  and
                 (((size_length_cntr = "00") and
                   (cmd_addr_sent = '1')
                   )or
                   (hpm_under_process_d1 = '1') or (wr_en_under_process_d1 = '1'))
                   )then
               length_cntr <= length_cntr - "00000001";
           end if;
       end if;
  end process LEN_CNTR_P;
  -----------------------
end generate LEN_CNTR_32_BIT_GEN;
---------------------------------
-------------------------------------------------------------------------------
SR_5_TX_EMPTY_32_BIT_ADDR_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
begin

    SR_5_Tx_Empty_int<= (not(or_reduce(length_cntr)) and
                         store_date_in_drr_fifo      and
                         cmd_addr_sent)
                         or
                        (-- (hpm_under_process_d1 or wr_en_under_process_d1)       and
                        (hpm_under_process or wr_en_under_process)       and
                         not(or_reduce(length_cntr)) and
                         SPIXfer_done_int_pulse);

    -- LEN_CNTR_P: This is data length counter. this counter will start decrementing
    --             only when the first 4 bytesfor 24 bit addressing and 5 bytes for 32 bit addressing mode are transferred from SPI.
    SR_5_TX_EMPTY_P:process(EXT_SPI_CLK)is
    begin
         if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
             if(Rst_to_spi = '1') then
                 SR_5_Tx_Empty <= '1';
             elsif(load_cmd_to_spi_clk = '1') or (load_wr_hpm = '1') or (load_wr_en = '1') then
                 SR_5_Tx_Empty <= '0';
             elsif(SR_5_Tx_Empty_int = '1')then
                 SR_5_Tx_Empty <= '1';
             end if;
         end if;
    end process SR_5_TX_EMPTY_P;

end generate SR_5_TX_EMPTY_32_BIT_ADDR_GEN;
-------------------------------------------------------------------------------

SR_5_TX_EMPTY_24_BIT_ADDR_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
begin
     SR_5_Tx_Empty_int<= (not(or_reduce(length_cntr)) and
                         store_date_in_drr_fifo      and
                         cmd_addr_sent)
                         or
                         (-- (hpm_under_process_d1 or wr_en_under_process_d1)       and
                         (hpm_under_process 
                          --or wr_en_under_process
                          )   
			  and
                          not(
			      or_reduce(length_cntr)) 
			      and
                              SPIXfer_done_int_pulse
			      );

    -- LEN_CNTR_P: This is data length counter. this counter will start decrementing
    --             only when the first 4 bytesfor 24 bit addressing and 5 bytes for 32 bit addressing mode are transferred from SPI.
    SR_5_TX_EMPTY_P:process(EXT_SPI_CLK)is
    begin
         if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
             if(Rst_to_spi = '1') then
                 SR_5_Tx_Empty <= '1';
             elsif(load_cmd_to_spi_clk = '1') or (load_wr_hpm = '1') 
                  --or (load_wr_en = '1')
                  then
                 SR_5_Tx_Empty <= '0';
             elsif(SR_5_Tx_Empty_int = '1')then
                 SR_5_Tx_Empty <= '1';
             end if;
         end if;
    end process SR_5_TX_EMPTY_P;
end generate SR_5_TX_EMPTY_24_BIT_ADDR_GEN;

-------------------------------------------
DELAY_FIFO_EMPTY_P:process(EXT_SPI_CLK)is
begin
     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
         if(Rst_to_spi = '1') then
             SR_5_Tx_Empty_d1 <= '1';
             SR_5_Tx_Empty_d2 <= '1';
         else
             SR_5_Tx_Empty_d1 <= SR_5_Tx_Empty;
             SR_5_Tx_Empty_d2 <= SR_5_Tx_Empty_d1;
         end if;
     end if;
end process DELAY_FIFO_EMPTY_P;
-------------------------------------------------------------------------------
last_bt_one_data <= not(or_reduce(length_cntr(7 downto 1))) and length_cntr(0);
-------------------------------------------------------------------------------

SIZE_CNTR_LD_SPI_CLK_P:process(EXT_SPI_CLK)is
-----
begin
-----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
         if(Rst_to_spi = '1') then
             size_length_cntr_fixed <= (others => '0');
             size_length_cntr       <= (others => '0');
         elsif(
                (pr_state_idle = '1') or ((SPIXfer_done_int = '1') and
                                          (size_length_cntr = "00"))
                )then
             --if(one_byte_xfer_to_spi_clk = '1' )then
             --    size_length_cntr_fixed <= "00";
             --    size_length_cntr <= "00";             -- 1 byte
             --els
             if(two_byte_xfer_to_spi_clk = '1')then
                 size_length_cntr_fixed <= "01";
                 size_length_cntr <= "01";             -- half word
             elsif(four_byte_xfer_to_spi_clk = '1') then
                 size_length_cntr_fixed <= "10";
                 size_length_cntr <= "11";             -- word
             else
                 size_length_cntr_fixed <= "00";
                 size_length_cntr <= "00";             -- other and one_byte_xfer_to_spi_clk = '1' is merged here
             end if;
         elsif(SPIXfer_done_int = '1')        and
              (one_byte_xfer_to_spi_clk = '0')and
              (cmd_addr_sent = '1') then -- (size_length_cntr /= "00") then
             size_length_cntr <= size_length_cntr - "01";
         end if;
     end if;
end process SIZE_CNTR_LD_SPI_CLK_P;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

store_date_in_drr_fifo <= not(or_reduce(size_length_cntr)) and
                          SPIXfer_done_int                 and 
                          cmd_addr_sent;
-------------------------------------------------------------------------------

STORE_STROBE_SPI_CLK_P:process(EXT_SPI_CLK)is
begin
-----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
         if(Rst_to_spi = '1') then
             store_date_in_drr_fifo_d1 <= '0';
             store_date_in_drr_fifo_d2 <= '0';
             store_date_in_drr_fifo_d3 <= '0';
         else
             store_date_in_drr_fifo_d1 <= store_date_in_drr_fifo;
             store_date_in_drr_fifo_d2 <= store_date_in_drr_fifo_d1;
             store_date_in_drr_fifo_d3 <= store_date_in_drr_fifo_d2;
         end if;
     end if;
end process STORE_STROBE_SPI_CLK_P;
-------------------------------------------------------------------------------

MD_12_WR_EN_TO_FIFO_GEN: if C_SPI_MODE = 1 or C_SPI_MODE = 2 generate
begin
-----
     --------------------------------------------------------------------
     WB_FIFO_WR_EN_GEN: if C_SPI_MEMORY = 1 generate
     begin
     -----
	  store_date_in_drr_fifo_en <= store_date_in_drr_fifo_d3;
     end generate WB_FIFO_WR_EN_GEN;
     --------------------------------------------------------------------
     NM_FIFO_WR_EN_GEN: if C_SPI_MEMORY = 2 generate
     begin
     -----
          STORE_DATA_24_BIT_ADDRESS_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
          begin
               store_date_in_drr_fifo_en <= store_date_in_drr_fifo_d3;  
          end generate STORE_DATA_24_BIT_ADDRESS_GEN;
          -------------------------------------------
          STORE_DATA_32_BIT_ADDRESS_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
          begin
               store_date_in_drr_fifo_en <= store_date_in_drr_fifo_d3;     
          end generate STORE_DATA_32_BIT_ADDRESS_GEN;
          -------------------------------------------
     end generate NM_FIFO_WR_EN_GEN;
     --------------------------------------------------------------------
	      SP_FIFO_WR_EN_GEN: if C_SPI_MEMORY = 3 generate
     begin
     -----
          STORE_DATA_24_BIT_ADDRESS_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
          begin
               store_date_in_drr_fifo_en <= store_date_in_drr_fifo_d3;  
          end generate STORE_DATA_24_BIT_ADDRESS_GEN;
          -------------------------------------------
          STORE_DATA_32_BIT_ADDRESS_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
          begin
               store_date_in_drr_fifo_en <= store_date_in_drr_fifo_d3;     
          end generate STORE_DATA_32_BIT_ADDRESS_GEN;
          -------------------------------------------
     end generate SP_FIFO_WR_EN_GEN;

     --------------------------------------------------------------------
	 
end generate MD_12_WR_EN_TO_FIFO_GEN;


MD_0_WR_EN_TO_FIFO_GEN: if C_SPI_MODE = 0 generate
begin
-----
     WB_FIFO_WR_EN_GEN: if C_SPI_MEMORY = 1 generate
     begin
     -----
     store_date_in_drr_fifo_en <= store_date_in_drr_fifo;
     end generate WB_FIFO_WR_EN_GEN;

     NM_FIFO_WR_EN_GEN: if C_SPI_MEMORY = 2 generate
     begin
     -----
     store_date_in_drr_fifo_en <= store_date_in_drr_fifo;
     end generate NM_FIFO_WR_EN_GEN;
	 
	 SP_FIFO_WR_EN_GEN: if C_SPI_MEMORY = 3 generate
     begin
     -----
     store_date_in_drr_fifo_en <= store_date_in_drr_fifo;
     end generate SP_FIFO_WR_EN_GEN;

end generate MD_0_WR_EN_TO_FIFO_GEN;
-------------------------------------------------------------------------------
SHIFT_TX_REG_24_BIT_GEN: if  C_SPI_MEM_ADDR_BITS = 24 generate
begin
  SHIFT_TX_REG_SPI_CLK_P:process(EXT_SPI_CLK)is
  -----
  begin
  -----
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
           if(Rst_to_spi = '1')then
               Tx_Data_d1 <= (others => '0');
           elsif(load_wr_hpm = '1') then
               Tx_Data_d1(31 downto 24) <= WB_wr_hpm_CMD;
               Tx_Data_d1(23 downto 0)  <= (others => '0');
           elsif(load_axi_data_to_spi_clk = '1')then
              Tx_Data_d1 <= SPI_cmd & Transmit_Addr_to_spi_clk; --  & SPI_cmd;-- (31 downto 8);
           elsif(wrap_around = '1') then
               Tx_Data_d1 <= SPI_cmd & spi_addr_wrap;--spi_addr_i & SPI_cmd;
           elsif(SPIXfer_done_int = '1')then
               Tx_Data_d1 <= --"11111111" & -- Tx_Data_d1(7 downto 0) &
                             --                 --Tx_Data_d1(31 downto 8);
                             --                 Tx_Data_d1(31 downto 8);
                             Tx_Data_d1(23 downto 0) & "11111111";
           end if;
       end if;
  end process SHIFT_TX_REG_SPI_CLK_P;
Transmit_Data <= Tx_Data_d1(31 downto 24);
end generate SHIFT_TX_REG_24_BIT_GEN;
-------------------------------------------------------
SHIFT_TX_REG_32_BIT_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
begin
  SHIFT_TX_REG_SPI_CLK_P:process(EXT_SPI_CLK)is
  -----
  begin
  -----
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
           if(Rst_to_spi = '1')then
               Tx_Data_d1       <= (others => '0');
               --last_7_addr_bits <= (others => '0');
           elsif(load_wr_en = '1') then
               Tx_Data_d1(31 downto 24) <= "00000110"; ---nm_wr_en_CMD;
               Tx_Data_d1(23 downto 0)  <= (others => '0');
           elsif(load_wr_hpm = '1')then
               Tx_Data_d1(31 downto 24) <= "10110111"; ---nm_4byte_addr_en_CMD;
               Tx_Data_d1(23 downto 0)  <= (others => '0');
           elsif(load_axi_data_to_spi_clk = '1')then
              Tx_Data_d1        <= SPI_cmd & Transmit_Addr_to_spi_clk(31 downto 8); --  & SPI_cmd;-- (31 downto 8);
              last_7_addr_bits  <= Transmit_Addr_to_spi_clk(7 downto 0);
           --   internal_count    <= (others => '0');
           elsif(wrap_around = '1') then
               Tx_Data_d1        <= SPI_cmd & spi_addr_wrap(31 downto 8);--spi_addr_i & SPI_cmd;
               last_7_addr_bits  <= spi_addr_wrap(7 downto 0);
           elsif(SPIXfer_done_int = '1') then -- and internal_count < "0101")then
               Tx_Data_d1 <= --"11111111" & -- Tx_Data_d1(7 downto 0) &
                             --                 --Tx_Data_d1(31 downto 8);
                             --                 Tx_Data_d1(31 downto 8);
                             Tx_Data_d1(23 downto 0) & -- Transmit_Addr_to_spi_clk(7 downto 0);
                                                       -- spi_addr_wrap(7 downto 0);
                                                       last_7_addr_bits(7 downto 0);
           --    internal_count <= internal_count + "0001";
           --elsif(SPIXfer_done_int = '1' and internal_count = "0101") then
           --    Tx_Data_d1 <= (others => '1');
           end if;
       end if;
  end process SHIFT_TX_REG_SPI_CLK_P;

Transmit_Data <= Tx_Data_d1(31 downto 24);
  -- STORE_INFO_P:process(EXT_SPI_CLK)is
  -- -----
  -- begin
  -- -----
  --      if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
  --          if(Rst_to_spi = '1')then
  --              data_loaded       <= '0';
  --              cmd_sent          <= '0';
  --          elsif(load_axi_data_to_spi_clk = '1' or wrap_around = '1) then
  --               data_loaded       <= '1';
  --          elsif(data_loaded = '1' and SPIXfer_done_int = '1') then
  --               cmd_sent          <= '1';
  --          end if;
  --      end if;
  -- end process STORE_INFO_P;

end generate SHIFT_TX_REG_32_BIT_GEN;
-------------------------------------------------------
-- Transmit_Data <= Tx_Data_d1(31 downto 24);
-------------------------------------------------------

-------------------------------------------------------------------------------
STD_MODE_CONTROL_GEN: if C_SPI_MODE = 0 generate
-----
begin
-----
     WB_MEM_STD_MD_GEN: if C_SPI_MODE = 0 and C_SPI_MEMORY = 1 generate
     -----------
       signal cmd_addr_cntr  : std_logic_vector(2 downto 0);
       signal hw_wd_cntr     : std_logic_vector(1 downto 0);
       -----
       begin
       -----
       wb_hpm_done    <= '1';
       load_wr_en     <= '0';-- 4/12/2013 applicable only for Numonyx memories
       ---- Std mode command = 0x0B - Fast Read
       SPI_cmd <= "00001011"; -- FAST_READ
       --                 |<---- cmd error
       -- WB 000 000 0100 0<-cmd error
       -- NM 000 000 0100 0
       
       
       Data_Dir            <= '0';
       Data_Mode_1         <= '0';
       Data_Mode_0         <= '0';
       Data_Phase          <= '0';
       --------------------
       Quad_Phase          <= '0';-- permanent '0'
       --------------------
       Addr_Mode_1         <= '0';
       Addr_Mode_0         <= '0';
       Addr_Bit            <= '0';
       Addr_Phase          <= '1';
       --------------------
       CMD_Mode_1          <= '0';
       CMD_Mode_0          <= '0';
       ---------------------------
       -- CMD_ADDR_CNTR_P: in each SPI transaction, the first 5 transactions are of
       --                  CMD, A0, A1, A2 and dummy. Total 5 bytes need to be removed from the
       --                  calculation of total no. of pure data bytes.
       --                  the actual data from the SPI memory will be stored in the
       --                  receive FIFO only when the first 5 bytes are transferred.
       --                  below counter is for that purpose only. This is applicable only for Winbond memory.
       CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
       begin
            if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                if(Rst_to_spi = '1') or (wrap_around = '1') then
                    cmd_addr_cntr <= "000";
                    cmd_addr_sent <= '0';
                elsif(pr_state_idle = '1')then
                    cmd_addr_cntr <= "000";
                    cmd_addr_sent <= wrap_around;
                elsif(SPIXfer_done_int = '1')then
                    if(cmd_addr_cntr = "101")then
                        cmd_addr_sent <= '1';
                    else
                        cmd_addr_cntr <= cmd_addr_cntr + "001";
                        cmd_addr_sent <= '0';
                    end if;
                end if;
            end if;
       end process CMD_ADDR_CNTR_P;
       ----------------------------
       
       -- TWO_BIT_CNTR_P: This is specifically used for HW data storage
       TWO_BIT_CNTR_P:process(EXT_SPI_CLK)is
       begin
       -----
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
           if(load_axi_data_to_spi_clk = '1') or (wrap_around = '1') then
               hw_wd_cntr <= (others => '0');
           elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1')then
               hw_wd_cntr <= hw_wd_cntr + "01";
           end if;
       end if;
       end process TWO_BIT_CNTR_P;
       ----------------------------------------------
       
       STORE_RX_DATA_SPI_CLK_P:process(EXT_SPI_CLK)is
       begin
       -----
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
            if(load_axi_data_to_spi_clk = '1') then
                    Data_To_Rx_FIFO_int <= (others => '0');
            elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1') then
                if(one_byte_xfer_to_spi_clk = '1') then
                    case spi_addr_i(1 downto 0) is
                        when "00" =>
                         Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 8) &
                                                receive_Data_int;
                        when "01" =>
                         Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 16)&
                                                receive_Data_int                 &
                                                Data_To_Rx_FIFO_int(7 downto 0);
                        when "10" =>
                         Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 24)&
                                                receive_Data_int                 &
                                                Data_To_Rx_FIFO_int(15 downto 0);
                        when "11" =>
                         Data_To_Rx_FIFO_int <= receive_Data_int                 &
                                                Data_To_Rx_FIFO_int(23 downto 0);
                        when others => null;
                    end case;
                elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '0') then  -- adjustment for half word
                    if(spi_addr_i(1) = '0') then
                       Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);-- & receive_Data_int;
                       Data_To_Rx_FIFO_int(15 downto 0)  <= receive_Data_int & Data_To_Rx_FIFO_int(15 downto 8);-- & receive_Data_int;
                    else
                       Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);-- & receive_Data_int;
                       Data_To_Rx_FIFO_int(31 downto 16)<= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 24);-- & receive_Data_int;
                    end if;
                elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '1') then  -- adjustment for half word
                    if(hw_wd_cntr = "00") then -- fill in D0
                        Data_To_Rx_FIFO_int(31 downto 8) <= Data_To_Rx_FIFO_int(31 downto 8);
                        Data_To_Rx_FIFO_int(7 downto 0)  <= receive_Data_int;
                    elsif(hw_wd_cntr = "01")then -- fill in D1
                        Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);
                        Data_To_Rx_FIFO_int(15 downto 8)  <= receive_Data_int;
                        Data_To_Rx_FIFO_int(7 downto 0) <= Data_To_Rx_FIFO_int(7 downto 0);
                    elsif(hw_wd_cntr = "10")then -- fill in D2
                        Data_To_Rx_FIFO_int(31 downto 24) <= Data_To_Rx_FIFO_int(31 downto 24);
                        Data_To_Rx_FIFO_int(23 downto 16)  <= receive_Data_int;
                        Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);
                    else
                        Data_To_Rx_FIFO_int(31 downto 24) <= receive_Data_int;
                        Data_To_Rx_FIFO_int(23 downto 0) <= Data_To_Rx_FIFO_int(23 downto 0);
                    end if;
                else   -- adjustment for complete word
                       --Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(23 downto 0) & receive_Data_int;
                       Data_To_Rx_FIFO_int <= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 8);
                end if;
        end if;
       end if;
       end process STORE_RX_DATA_SPI_CLK_P;
       ----------------------------
       Data_To_Rx_FIFO <= Data_To_Rx_FIFO_int;
       ---------------------------------------
       RECEIVE_DATA_STROBE_PROCESS: process(EXT_SPI_CLK)
       -----
       begin 
       -----
           if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
              if(load_axi_data_to_spi_clk = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
                      receive_Data_int  <= (others => '0');
              elsif(SPIXfer_done_int_pulse = '1') then
                      receive_Data_int  <= rx_shft_reg_mode_0011;
              elsif(SPIXfer_done_int_pulse_d1 = '1') and (cmd_addr_sent = '1')then
					  receive_Data_int <= receive_Data_int
                                         ((C_NUM_TRANSFER_BITS-2) downto 0) &
                                                                  IO1_I ; --MISO_I;

              end if;
           end if;
       end process RECEIVE_DATA_STROBE_PROCESS;
       -----------------------------------------
     end generate WB_MEM_STD_MD_GEN;
     ------------------------
     --------------------------------------------------------------------------
     NM_MEM_STD_MD_GEN: if C_SPI_MODE = 0 and C_SPI_MEMORY = 2 generate
       signal cmd_addr_cntr  : std_logic_vector(2 downto 0);
       signal hw_wd_cntr     : std_logic_vector(1 downto 0);
       -----
       begin
       -----
       ---- Std mode command = 0x0B - Fast Read
       STD_SPI_CMD_NM_24_BIT_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
       begin
         SPI_cmd <= "00001011";-- FAST_READ - 0x0Bh
         --                 |<---- cmd error
         -- NM 000 000 0100 0
         four_byte_en_done <= '1';
         wb_hpm_done <= '1'; 
         DRIVE_CONTROL_SIG_P: process(EXT_SPI_CLK, wb_hpm_done, wr_en_done_reg ) is -- wb_hpm_done, wr_en_done_reg) is
         variable temp: std_logic_vector(1 downto 0);
         begin
                temp := wb_hpm_done & wr_en_done_reg;
                if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                        --case wb_hpm_done is
                        --    -- when "00"|"01" => -- write enable is under process
                        --    when '0'       => -- write enable and/or Enable 4 byte addressing is under process
                        --                   Data_Dir            <= '0';                  
                        --                   Data_Mode_1         <= '0';                  
                        --                   Data_Mode_0         <= '0';                  
                        --                   Data_Phase          <= '0';                  
                        --                   --------------------                         
                        --                   Quad_Phase          <= '0';-- permanent '0'  
                        --                   --------------------                         
                        --                   Addr_Mode_1         <= '0';                  
                        --                   Addr_Mode_0         <= '0';                  
                        --                   Addr_Bit            <= '0';                  
                        --                   Addr_Phase          <= '0';                  
                        --                   --------------------                         
                        --                   CMD_Mode_1          <= '0';                  
                        --                   CMD_Mode_0          <= '0';                  
                        --    -- when "01"   => -- Enable 4 byte addressing is under process
                        --    --                Data_Dir            <= '0';                  
                        --    --                Data_Mode_1         <= '0';                  
                        --    --                Data_Mode_0         <= '0';                  
                        --    --                Data_Phase          <= '0';                  
                        --    --                --------------------                         
                        --    --                Quad_Phase          <= '0';-- permanent '0'  
                        --    --                --------------------                         
                        --    --                Addr_Mode_1         <= '0';                  
                        --    --                Addr_Mode_0         <= '0';                  
                        --    --                Addr_Bit            <= '0';                  
                        --    --                Addr_Phase          <= '0';                  
                        --    --                --------------------                         
                        --    --                CMD_Mode_1          <= '0';                  
                        --    --                CMD_Mode_0          <= '0';                  
                        --    -- when "10"   => -- write enable is done and enable 4 byte addressing is also done
                        --    when '1'       => -- write enable and enable 4 byte addressing is also done
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '1';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                        --    -- coverage off
                        --    when others => 
                        --                   Data_Dir            <= '0';                  
                        --                   Data_Mode_1         <= '0';                  
                        --                   Data_Mode_0         <= '0';                  
                        --                   Data_Phase          <= '0';                  
                        --                   --------------------                         
                        --                   Quad_Phase          <= '0';-- permanent '0'  
                        --                   --------------------                         
                        --                   Addr_Mode_1         <= '0';                  
                        --                   Addr_Mode_0         <= '0';                  
                        --                   Addr_Bit            <= '0';                  
                        --                   Addr_Phase          <= '0';                  
                        --                   --------------------                         
                        --                   CMD_Mode_1          <= '0';                  
                        --                   CMD_Mode_0          <= '0';                  
                        --    -- coverage on
                        --end case;
                end if;
         end process DRIVE_CONTROL_SIG_P;
         ---------------------------------------------------------------------
      end generate STD_SPI_CMD_NM_24_BIT_GEN;
       
      STD_SPI_CMD_NM_32_BIT_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
      begin
        SPI_cmd <= "00001100";-- FAST_READ_4Byte - 0x0Ch
        --                 |<---- cmd error
        -- NM 000 000 0100 0
      --end generate STD_SPI_CMD_NM_32_BIT_GEN;

      --NM_EN_32_ADDR_MD_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
      --begin
      -----
         nm_wr_en_CMD         <= "00000110"; -- 0x06 h Write Enable
         nm_4byte_addr_en_CMD <= "10110111"; -- 0xB7 h Enable 4 Byte Addressing Mode
         ----------------------------------------------------
         NM_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
         -----
         begin
         -----
             if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                 if(Rst_to_spi = RESET_ACTIVE) then
                     nm_wr_en_cntrl_ps      <= NM_WR_EN_IDLE;
                     wr_en_under_process_d1 <= '0';
                     wr_en_done_reg         <= '0';
                 else
                     nm_wr_en_cntrl_ps      <= nm_wr_en_cntrl_ns;
                     wr_en_under_process_d1 <= wr_en_under_process;
                     wr_en_done_reg         <= wr_en_done;

                 end if;
             end if;
         end process NM_PS_TO_NS_PROCESS;
         ----------------------------------
         --
         NM_WR_EN_CNTRL_PROCESS: process(
                                        nm_wr_en_cntrl_ps     ,
                                        --SPIXfer_done_int_pulse,
                                        --SPIXfer_done_int      ,
                                        Rst_to_spi            ,
                                        SR_5_Tx_Empty         ,
                                        wr_en_done_reg
                                        ) is
         -----
         begin
         -----
              --load_wr_en_cmd <= '0';
              --load_wr_sr_cmd <= '0';
              --load_wr_sr_d0  <= '0';
              --load_wr_sr_d1  <= '0';
              load_wr_en    <= '0';
              wr_en_done    <= '0';
              wr_en_under_process <= '0';
              case nm_wr_en_cntrl_ps is
                  when NM_WR_EN_IDLE => --load_wr_en_cmd <= '1';
                                      load_wr_en          <= '1';
                                      wr_en_under_process <= '1';
                                      nm_wr_en_cntrl_ns   <= NM_WR_EN;
                  when NM_WR_EN      => if (SR_5_Tx_Empty = '1')then
                                            --wr_en_done <= '1';
                                            nm_wr_en_cntrl_ns <= NM_WR_EN_DONE;
                                        else
                                            --wr_en_under_process <= '1';
                                            nm_wr_en_cntrl_ns <= NM_WR_EN;
                                        end if;
                                        wr_en_done          <= SR_5_Tx_Empty;
                                        wr_en_under_process <= not SR_5_Tx_Empty;

                  when NM_WR_EN_DONE => if (Rst_to_spi = '1') then
                                            nm_wr_en_cntrl_ns <= NM_WR_EN_IDLE;
                                        else
                                            nm_wr_en_cntrl_ns <= NM_WR_EN_DONE;
                                        end if;
                                        wr_en_done <= wr_en_done_reg;
              end case;
         end process NM_WR_EN_CNTRL_PROCESS;

           ----------------------------------------------------
           NM_4_BYTE_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
           -----
           begin
           -----
               if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                   if(Rst_to_spi = RESET_ACTIVE) then
                       nm_sm_4_byte_addr_ps           <= NM_32_BIT_IDLE;
                       --four_byte_addr_under_process_d1 <= '0';
                       hpm_under_process_d1   <= '0';
                       wr_en_done_d1          <= '0';
                       wr_en_done_d2          <= '0';
                       wb_hpm_done_reg        <= '0';
                   else
                       nm_sm_4_byte_addr_ps   <= nm_sm_4_byte_addr_ns;
                       hpm_under_process_d1   <= hpm_under_process;
                       --four_byte_en_done_reg           <= four_byte_en_done;   
                       wr_en_done_d1          <= wr_en_done_reg; -- wr_en_done;
                       wr_en_done_d2          <= wr_en_done_d1;
                       wb_hpm_done_reg        <= wb_hpm_done;
                   end if;
               end if;
           end process NM_4_BYTE_PS_TO_NS_PROCESS;
           ----------------------------------
           --
           NM_4_BYTE_ADDR_EN_PROCESS: process(
                                              nm_sm_4_byte_addr_ps  ,
                                              Rst_to_spi            ,
                                              SR_5_Tx_Empty         ,
                                              wr_en_done_d2         ,
                                              wb_hpm_done_reg
                                             ) is
           -----
           begin
           -----
                -- load_4_byte_addr_en     <= '0';
                load_wr_hpm <= '0';
                wb_hpm_done <= '0';
                hpm_under_process <= '0';
                four_byte_en_done          <= '0';
                four_byte_en_under_process <= '0';
                case nm_sm_4_byte_addr_ps is
                    when NM_32_BIT_IDLE     => if (wr_en_done_d2 = '1') then
                                                   --load_wr_hpm <= '1';
                                                   --hpm_under_process <= '1';
                                                   nm_sm_4_byte_addr_ns      <= NM_32_BIT_EN;
                                               else
                                                   nm_sm_4_byte_addr_ns      <= NM_32_BIT_IDLE;
                                               end if;
                                               load_wr_hpm       <= wr_en_done_d2; 
                                               hpm_under_process <= wr_en_done_d2;
           
                    when NM_32_BIT_EN      => if (SR_5_Tx_Empty = '1') then
                                                  -- wb_hpm_done        <= '1';
                                                  nm_sm_4_byte_addr_ns <= NM_32_BIT_EN_DONE;
                                              else
                                                  -- hpm_under_process  <= '1';
                                                  nm_sm_4_byte_addr_ns <= NM_32_BIT_EN;
                                              end if;
                                              wb_hpm_done        <= SR_5_Tx_Empty;
                                              hpm_under_process  <= not(SR_5_Tx_Empty);
                    when NM_32_BIT_EN_DONE => if(Rst_to_spi = '1')then
                                                  nm_sm_4_byte_addr_ns <= NM_32_BIT_IDLE;
                                              else
                                                --  if (SR_5_Tx_Empty = '1')then
                                                --      --four_byte_en_done          <= '1';
                                                --      wb_hpm_done <= '1';
                                                --  else
                                                --      -- four_byte_en_under_process <= '1';
                                                --      hpm_under_process <= '1';
                                                --  end if;
                                                --  four_byte_en_done     <= four_byte_en_done_reg;     
                                                  -- wb_hpm_done <= '1';
                                                  nm_sm_4_byte_addr_ns <= NM_32_BIT_EN_DONE;
                                              end if;
                                              wb_hpm_done <= wb_hpm_done_reg;
           
                end case;
           end process NM_4_BYTE_ADDR_EN_PROCESS;
           --------------------------------------
             DRIVE_CONTROL_SIG_P: process(EXT_SPI_CLK, wb_hpm_done, wr_en_done_reg) is -- wb_hpm_done, wr_en_done_reg) is
             variable temp: std_logic_vector(1 downto 0);
             begin
                   temp := wb_hpm_done & wr_en_done_reg;
                   if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                           case wb_hpm_done is
                               -- when "00"|"01" => -- write enable is under process
                    when '0'       => -- write enable and/or Enable 4 byte addressing is under process
                                              Data_Dir            <= '0';                  
                                              Data_Mode_1         <= '0';                  
                                              Data_Mode_0         <= '0';                  
                                              Data_Phase          <= '0';                  
                                              --------------------                         
                                              Quad_Phase          <= '0';-- permanent '0'  
                                              --------------------                         
                                              Addr_Mode_1         <= '0';                  
                                              Addr_Mode_0         <= '0';                  
                                              Addr_Bit            <= '0';                  
                                              Addr_Phase          <= '0';                  
                                              --------------------                         
                                              CMD_Mode_1          <= '0';                  
                                              CMD_Mode_0          <= '0';                  
                               -- when "01"   => -- Enable 4 byte addressing is under process
                               --                Data_Dir            <= '0';                  
                               --                Data_Mode_1         <= '0';                  
                               --                Data_Mode_0         <= '0';                  
                               --                Data_Phase          <= '0';                  
                               --                --------------------                         
                               --                Quad_Phase          <= '0';-- permanent '0'  
                               --                --------------------                         
                               --                Addr_Mode_1         <= '0';                  
                               --                Addr_Mode_0         <= '0';                  
                               --                Addr_Bit            <= '0';                  
                               --                Addr_Phase          <= '0';                  
                               --                --------------------                         
                               --                CMD_Mode_1          <= '0';                  
                               --                CMD_Mode_0          <= '0';                  
                               -- when "10"   => -- write enable is done and enable 4 byte addressing is also done
                    when '1'       => -- write enable and enable 4 byte addressing is also done
                                              Data_Dir            <= '0';                  
                                              Data_Mode_1         <= '0';                  
                                              Data_Mode_0         <= '0';                  
                                              Data_Phase          <= '1';                  
                                              --------------------                         
                                              Quad_Phase          <= '0';-- permanent '0'  
                                              --------------------                         
                                              Addr_Mode_1         <= '0';                  
                                              Addr_Mode_0         <= '0';                  
                                              Addr_Bit            <= '1';                  
                                              Addr_Phase          <= '1';                  
                                              --------------------                         
                                              CMD_Mode_1          <= '0';                  
                                              CMD_Mode_0          <= '0';                  
                               -- coverage off
                    when others => 
                                              Data_Dir            <= '0';                  
                                              Data_Mode_1         <= '0';                  
                                              Data_Mode_0         <= '0';                  
                                              Data_Phase          <= '0';                  
                                              --------------------                         
                                              Quad_Phase          <= '0';-- permanent '0'  
                                              --------------------                         
                                              Addr_Mode_1         <= '0';                  
                                              Addr_Mode_0         <= '0';                  
                                              Addr_Bit            <= '0';                  
                                              Addr_Phase          <= '0';                  
                                              --------------------                         
                                              CMD_Mode_1          <= '0';                  
                                              CMD_Mode_0          <= '0';                  
                               -- coverage on
                end case;
                   end if;
             end process DRIVE_CONTROL_SIG_P;
             ---------------------------------------------------------------------
      --end generate NM_EN_32_ADDR_MD_GEN;
       end generate STD_SPI_CMD_NM_32_BIT_GEN;
       ---------------------------------------
       -- wb_hpm_done    <= four_byte_en_done;
       
       --Data_Dir            <= '0';
       --Data_Mode_1         <= '0';
       --Data_Mode_0         <= '0';
       --Data_Phase          <= '0';
       ----------------------
       --Quad_Phase          <= '0';-- permanent '0'
       ----------------------
       --Addr_Mode_1         <= '0';
       --Addr_Mode_0         <= '0';
       --Addr_Bit            <= '0';
       --Addr_Phase          <= '1';
       ----------------------
       --CMD_Mode_1          <= '0';
       --CMD_Mode_0          <= '0';
       ---------------------------

       -----
       RECEIVE_DATA_STROBE_PROCESS: process(EXT_SPI_CLK)
       -----
       begin
       -----
           if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
              if(load_axi_data_to_spi_clk = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
                      receive_Data_int  <= (others => '0');
              -- elsif(SPIXfer_done_int = '1') and (cmd_addr_cntr = "110")then
              elsif(SPIXfer_done_int_pulse = '1') then
                      receive_Data_int  <= rx_shft_reg_mode_0011;
              elsif(SPIXfer_done_int_pulse_d1 = '1') and (cmd_addr_sent = '1')then
					  receive_Data_int <= receive_Data_int
                                         ((C_NUM_TRANSFER_BITS-2) downto 0) &
                                                                  IO1_I ; --MISO_I;
              end if;
           end if;
       end process RECEIVE_DATA_STROBE_PROCESS;

       CMD_ADDR_24_BIT_CNTR_GEN : if  C_SPI_MEM_ADDR_BITS = 24 generate
       begin      
         -- CMD_ADDR_CNTR_P: in each SPI transaction, the first 5 transactions are of
         --                  CMD, A0, A1, A2 and dummy. Total 5 bytes need to be removed from the
         --                  calculation of total no. of pure data bytes.
         --                  the actual data from the SPI memory will be stored in the
         --                  receive FIFO only when the first 5 bytes are transferred.
         --                  below counter is for that purpose only. Tihs is for 24 bit addressing mode only.
         CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
         begin
              if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                  if(Rst_to_spi = '1') or (wrap_around = '1') then
                      cmd_addr_cntr <= "000";
                      cmd_addr_sent <= '0';
                  elsif(pr_state_idle = '1') then --  and store_date_in_drr_fifo_d3 = '1')then
                      cmd_addr_cntr <= "000";
                      cmd_addr_sent <= wrap_around;
                  elsif(SPIXfer_done_int = '1')then
                      if(cmd_addr_cntr = "101")then
                          cmd_addr_sent <= '1';
                      else
                          cmd_addr_cntr <= cmd_addr_cntr + "001";
                          cmd_addr_sent <= '0';
                      end if;
                  end if;
              end if;
         end process CMD_ADDR_CNTR_P;
         ----------------------------
       end generate CMD_ADDR_24_BIT_CNTR_GEN;
       --------------------------------------
       
       CMD_ADDR_32_BIT_CNTR_GEN : if C_SPI_MEM_ADDR_BITS = 32 generate
       begin      
         -- * -- -----
         -- * -- RECEIVE_DATA_STROBE_PROCESS: process(EXT_SPI_CLK)
         -- * -- -----
         -- * -- begin
         -- * -- -----
         -- * --     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
         -- * --        if(load_axi_data_to_spi_clk = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
         -- * --                receive_Data_int  <= (others => '0');
         -- * --        elsif(SPIXfer_done_int_pulse_d1 = '1') and (cmd_addr_sent = '1') then  -- and (cmd_addr_cntr = "111")then
         -- * --                receive_Data_int  <= rx_shft_reg_mode_0011;
         -- * --        end if;
         -- * --     end if;
         -- * -- end process RECEIVE_DATA_STROBE_PROCESS;
         -- CMD_ADDR_CNTR_P: in each SPI transaction, the first 6 transactions are of
         --                  CMD, A0, A1, A2, A3 and dummy. Total 6 bytes need to be removed from the
         --                  calculation of total no. of pure data bytes.
         --                  the actual data from the SPI memory will be stored in the
         --                  receive FIFO only when the first 6 bytes are transferred.
         --                  below counter is for that purpose only. This is for 32 bit addressing mode only.
         CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
         begin
              if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                  if(Rst_to_spi = '1') or (wrap_around = '1') then
                      cmd_addr_cntr <= "000";
                      cmd_addr_sent <= '0';
                  elsif(pr_state_idle = '1' and store_date_in_drr_fifo_d3 = '1')then
                      cmd_addr_cntr <= "000";
                      cmd_addr_sent <= wrap_around;
                  elsif(SPIXfer_done_int = '1' and wb_hpm_done = '1')then
                      if(cmd_addr_cntr = "110")then
                          cmd_addr_sent <= '1';
                      else
                          cmd_addr_cntr <= cmd_addr_cntr + "001";
                          cmd_addr_sent <= '0';
                      end if;
                  end if;
              end if;
         end process CMD_ADDR_CNTR_P;
         ----------------------------
       end generate CMD_ADDR_32_BIT_CNTR_GEN;
       --------------------------------------
       
       -- TWO_BIT_CNTR_P: This is specifically used for HW data storage
       TWO_BIT_CNTR_P:process(EXT_SPI_CLK)is
       begin
       -----
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
           if(load_axi_data_to_spi_clk = '1') or (wrap_around = '1') then
               hw_wd_cntr <= (others => '0');
           elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1')then
               hw_wd_cntr <= hw_wd_cntr + "01";
           end if;
       end if;
       end process TWO_BIT_CNTR_P;
       ----------------------------------------------
       
       STORE_RX_DATA_SPI_CLK_P:process(EXT_SPI_CLK)is
       begin
       -----
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
            if(load_axi_data_to_spi_clk = '1') then
                    Data_To_Rx_FIFO_int <= (others => '0');
            elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1') then
                if(one_byte_xfer_to_spi_clk = '1') then
                    case spi_addr_i(1 downto 0) is
                        when "00" =>
                         Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 8) &
                                                receive_Data_int;
                        when "01" =>
                         Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 16)&
                                                receive_Data_int                 &
                                                Data_To_Rx_FIFO_int(7 downto 0);
                        when "10" =>
                         Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 24)&
                                                receive_Data_int                 &
                                                Data_To_Rx_FIFO_int(15 downto 0);
                        when "11" =>
                         Data_To_Rx_FIFO_int <= receive_Data_int                 &
                                                Data_To_Rx_FIFO_int(23 downto 0);
                        when others => null;
                    end case;
                elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '0') then  -- adjustment for half word
                    if(spi_addr_i(1) = '0') then
                       Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);-- & receive_Data_int;
                       Data_To_Rx_FIFO_int(15 downto 0)  <= receive_Data_int & Data_To_Rx_FIFO_int(15 downto 8);-- & receive_Data_int;
                    else
                       Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);-- & receive_Data_int;
                       Data_To_Rx_FIFO_int(31 downto 16)<= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 24);-- & receive_Data_int;
                    end if;
                elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '1') then  -- adjustment for half word
                    if(hw_wd_cntr = "00") then -- fill in D0
                        Data_To_Rx_FIFO_int(31 downto 8) <= Data_To_Rx_FIFO_int(31 downto 8);
                        Data_To_Rx_FIFO_int(7 downto 0)  <= receive_Data_int;
                    elsif(hw_wd_cntr = "01")then -- fill in D1
                        Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);
                        Data_To_Rx_FIFO_int(15 downto 8)  <= receive_Data_int;
                        Data_To_Rx_FIFO_int(7 downto 0) <= Data_To_Rx_FIFO_int(7 downto 0);
                    elsif(hw_wd_cntr = "10")then -- fill in D2
                        Data_To_Rx_FIFO_int(31 downto 24) <= Data_To_Rx_FIFO_int(31 downto 24);
                        Data_To_Rx_FIFO_int(23 downto 16)  <= receive_Data_int;
                        Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);
                    else
                        Data_To_Rx_FIFO_int(31 downto 24) <= receive_Data_int;
                        Data_To_Rx_FIFO_int(23 downto 0) <= Data_To_Rx_FIFO_int(23 downto 0);
                    end if;
                else   -- adjustment for complete word
                       --Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(23 downto 0) & receive_Data_int;
                       Data_To_Rx_FIFO_int <= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 8);
                end if;
        end if;
       end if;
       end process STORE_RX_DATA_SPI_CLK_P;
       ----------------------------
       Data_To_Rx_FIFO <= Data_To_Rx_FIFO_int;
       ---------------------------------------
     end generate NM_MEM_STD_MD_GEN;
     ------------------------
	 
	     SP_MEM_STD_MD_GEN: if C_SPI_MODE = 0 and C_SPI_MEMORY = 3 generate
       signal cmd_addr_cntr  : std_logic_vector(2 downto 0);
       signal hw_wd_cntr     : std_logic_vector(1 downto 0);
       -----
       begin
       -----
       ---- Std mode command = 0x0B - Fast Read
       STD_SPI_CMD_SP_24_BIT_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
       begin
         SPI_cmd <= "00001011";-- FAST_READ - 0x0Bh
         --                 |<---- cmd error
         -- NM 000 000 0100 0
         four_byte_en_done <= '1';
         wb_hpm_done <= '1'; 
         DRIVE_CONTROL_SIG_P: process(EXT_SPI_CLK) is -- wb_hpm_done, wr_en_done_reg) is
         variable temp: std_logic_vector(1 downto 0);
         begin
                temp := wb_hpm_done & wr_en_done_reg;
                if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                        --case wb_hpm_done is
                        --    -- when "00"|"01" => -- write enable is under process
                        --    when '0'       => -- write enable and/or Enable 4 byte addressing is under process
                        --                   Data_Dir            <= '0';                  
                        --                   Data_Mode_1         <= '0';                  
                        --                   Data_Mode_0         <= '0';                  
                        --                   Data_Phase          <= '0';                  
                        --                   --------------------                         
                        --                   Quad_Phase          <= '0';-- permanent '0'  
                        --                   --------------------                         
                        --                   Addr_Mode_1         <= '0';                  
                        --                   Addr_Mode_0         <= '0';                  
                        --                   Addr_Bit            <= '0';                  
                        --                   Addr_Phase          <= '0';                  
                        --                   --------------------                         
                        --                   CMD_Mode_1          <= '0';                  
                        --                   CMD_Mode_0          <= '0';                  
                        --    -- when "01"   => -- Enable 4 byte addressing is under process
                        --    --                Data_Dir            <= '0';                  
                        --    --                Data_Mode_1         <= '0';                  
                        --    --                Data_Mode_0         <= '0';                  
                        --    --                Data_Phase          <= '0';                  
                        --    --                --------------------                         
                        --    --                Quad_Phase          <= '0';-- permanent '0'  
                        --    --                --------------------                         
                        --    --                Addr_Mode_1         <= '0';                  
                        --    --                Addr_Mode_0         <= '0';                  
                        --    --                Addr_Bit            <= '0';                  
                        --    --                Addr_Phase          <= '0';                  
                        --    --                --------------------                         
                        --    --                CMD_Mode_1          <= '0';                  
                        --    --                CMD_Mode_0          <= '0';                  
                        --    -- when "10"   => -- write enable is done and enable 4 byte addressing is also done
                        --    when '1'       => -- write enable and enable 4 byte addressing is also done
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '1';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                        --    -- coverage off
                        --    when others => 
                        --                   Data_Dir            <= '0';                  
                        --                   Data_Mode_1         <= '0';                  
                        --                   Data_Mode_0         <= '0';                  
                        --                   Data_Phase          <= '0';                  
                        --                   --------------------                         
                        --                   Quad_Phase          <= '0';-- permanent '0'  
                        --                   --------------------                         
                        --                   Addr_Mode_1         <= '0';                  
                        --                   Addr_Mode_0         <= '0';                  
                        --                   Addr_Bit            <= '0';                  
                        --                   Addr_Phase          <= '0';                  
                        --                   --------------------                         
                        --                   CMD_Mode_1          <= '0';                  
                        --                   CMD_Mode_0          <= '0';                  
                        --    -- coverage on
                        --end case;
                end if;
         end process DRIVE_CONTROL_SIG_P;
         ---------------------------------------------------------------------
      end generate STD_SPI_CMD_SP_24_BIT_GEN;
       
      STD_SPI_CMD_SP_32_BIT_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
      begin
        SPI_cmd <= "00001100";-- FAST_READ_4Byte - 0x0Ch
        --                 |<---- cmd error
        -- NM 000 000 0100 0
      --end generate STD_SPI_CMD_NM_32_BIT_GEN;

      --NM_EN_32_ADDR_MD_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
      --begin
      -----
         nm_wr_en_CMD         <= "00000110"; -- 0x06 h Write Enable
         nm_4byte_addr_en_CMD <= "10110111"; -- 0xB7 h Enable 4 Byte Addressing Mode
         ----------------------------------------------------
         SP_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
         -----
         begin
         -----
             if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                 if(Rst_to_spi = RESET_ACTIVE) then
                     nm_wr_en_cntrl_ps      <= NM_WR_EN_IDLE;
                     wr_en_under_process_d1 <= '0';
                     wr_en_done_reg         <= '0';
                 else
                     nm_wr_en_cntrl_ps      <= nm_wr_en_cntrl_ns;
                     wr_en_under_process_d1 <= wr_en_under_process;
                     wr_en_done_reg         <= wr_en_done;

                 end if;
             end if;
         end process SP_PS_TO_NS_PROCESS;
         ----------------------------------
         --
         SP_WR_EN_CNTRL_PROCESS: process(
                                        nm_wr_en_cntrl_ps     ,
                                        --SPIXfer_done_int_pulse,
                                        --SPIXfer_done_int      ,
                                        Rst_to_spi            ,
                                        SR_5_Tx_Empty         ,
                                        wr_en_done_reg
                                        ) is
         -----
         begin
         -----
              --load_wr_en_cmd <= '0';
              --load_wr_sr_cmd <= '0';
              --load_wr_sr_d0  <= '0';
              --load_wr_sr_d1  <= '0';
              load_wr_en    <= '0';
              wr_en_done    <= '0';
              wr_en_under_process <= '0';
              case nm_wr_en_cntrl_ps is
                  when NM_WR_EN_IDLE => --load_wr_en_cmd <= '1';
                                      load_wr_en          <= '1';
                                      wr_en_under_process <= '1';
                                      nm_wr_en_cntrl_ns   <= NM_WR_EN;
                  when NM_WR_EN      => if (SR_5_Tx_Empty = '1')then
                                            --wr_en_done <= '1';
                                            nm_wr_en_cntrl_ns <= NM_WR_EN_DONE;
                                        else
                                            --wr_en_under_process <= '1';
                                            nm_wr_en_cntrl_ns <= NM_WR_EN;
                                        end if;
                                        wr_en_done          <= SR_5_Tx_Empty;
                                        wr_en_under_process <= not SR_5_Tx_Empty;

                  when NM_WR_EN_DONE => if (Rst_to_spi = '1') then
                                            nm_wr_en_cntrl_ns <= NM_WR_EN_IDLE;
                                        else
                                            nm_wr_en_cntrl_ns <= NM_WR_EN_DONE;
                                        end if;
                                        wr_en_done <= wr_en_done_reg;
              end case;
         end process SP_WR_EN_CNTRL_PROCESS;

           ----------------------------------------------------
           SP_4_BYTE_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
           -----
           begin
           -----
               if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                   if(Rst_to_spi = RESET_ACTIVE) then
                       nm_sm_4_byte_addr_ps           <= NM_32_BIT_IDLE;
                       --four_byte_addr_under_process_d1 <= '0';
                       hpm_under_process_d1   <= '0';
                       wr_en_done_d1          <= '0';
                       wr_en_done_d2          <= '0';
                       wb_hpm_done_reg        <= '0';
                   else
                       nm_sm_4_byte_addr_ps   <= nm_sm_4_byte_addr_ns;
                       hpm_under_process_d1   <= hpm_under_process;
                       --four_byte_en_done_reg           <= four_byte_en_done;   
                       wr_en_done_d1          <= wr_en_done_reg; -- wr_en_done;
                       wr_en_done_d2          <= wr_en_done_d1;
                       wb_hpm_done_reg        <= wb_hpm_done;
                   end if;
               end if;
           end process SP_4_BYTE_PS_TO_NS_PROCESS;
           ----------------------------------
           --
           SP_4_BYTE_ADDR_EN_PROCESS: process(
                                              nm_sm_4_byte_addr_ps  ,
                                              Rst_to_spi            ,
                                              SR_5_Tx_Empty         ,
                                              wr_en_done_d2         ,
                                              wb_hpm_done_reg
                                             ) is
           -----
           begin
           -----
                -- load_4_byte_addr_en     <= '0';
                load_wr_hpm <= '0';
                wb_hpm_done <= '0';
                hpm_under_process <= '0';
                four_byte_en_done          <= '0';
                four_byte_en_under_process <= '0';
                case nm_sm_4_byte_addr_ps is
                    when NM_32_BIT_IDLE     => if (wr_en_done_d2 = '1') then
                                                   --load_wr_hpm <= '1';
                                                   --hpm_under_process <= '1';
                                                   nm_sm_4_byte_addr_ns      <= NM_32_BIT_EN;
                                               else
                                                   nm_sm_4_byte_addr_ns      <= NM_32_BIT_IDLE;
                                               end if;
                                               load_wr_hpm       <= wr_en_done_d2; 
                                               hpm_under_process <= wr_en_done_d2;
           
                    when NM_32_BIT_EN      => if (SR_5_Tx_Empty = '1') then
                                                  -- wb_hpm_done        <= '1';
                                                  nm_sm_4_byte_addr_ns <= NM_32_BIT_EN_DONE;
                                              else
                                                  -- hpm_under_process  <= '1';
                                                  nm_sm_4_byte_addr_ns <= NM_32_BIT_EN;
                                              end if;
                                              wb_hpm_done        <= SR_5_Tx_Empty;
                                              hpm_under_process  <= not(SR_5_Tx_Empty);
                    when NM_32_BIT_EN_DONE => if(Rst_to_spi = '1')then
                                                  nm_sm_4_byte_addr_ns <= NM_32_BIT_IDLE;
                                              else
                                                --  if (SR_5_Tx_Empty = '1')then
                                                --      --four_byte_en_done          <= '1';
                                                --      wb_hpm_done <= '1';
                                                --  else
                                                --      -- four_byte_en_under_process <= '1';
                                                --      hpm_under_process <= '1';
                                                --  end if;
                                                --  four_byte_en_done     <= four_byte_en_done_reg;     
                                                  -- wb_hpm_done <= '1';
                                                  nm_sm_4_byte_addr_ns <= NM_32_BIT_EN_DONE;
                                              end if;
                                              wb_hpm_done <= wb_hpm_done_reg;
           
                end case;
           end process SP_4_BYTE_ADDR_EN_PROCESS;
           --------------------------------------
             DRIVE_CONTROL_SIG_P: process(EXT_SPI_CLK) is -- wb_hpm_done, wr_en_done_reg) is
             variable temp: std_logic_vector(1 downto 0);
             begin
                   temp := wb_hpm_done & wr_en_done_reg;
                   if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                           case wb_hpm_done is
                               -- when "00"|"01" => -- write enable is under process
                    when '0'       => -- write enable and/or Enable 4 byte addressing is under process
                                              Data_Dir            <= '0';                  
                                              Data_Mode_1         <= '0';                  
                                              Data_Mode_0         <= '0';                  
                                              Data_Phase          <= '0';                  
                                              --------------------                         
                                              Quad_Phase          <= '0';-- permanent '0'  
                                              --------------------                         
                                              Addr_Mode_1         <= '0';                  
                                              Addr_Mode_0         <= '0';                  
                                              Addr_Bit            <= '0';                  
                                              Addr_Phase          <= '0';                  
                                              --------------------                         
                                              CMD_Mode_1          <= '0';                  
                                              CMD_Mode_0          <= '0';                  
                               -- when "01"   => -- Enable 4 byte addressing is under process
                               --                Data_Dir            <= '0';                  
                               --                Data_Mode_1         <= '0';                  
                               --                Data_Mode_0         <= '0';                  
                               --                Data_Phase          <= '0';                  
                               --                --------------------                         
                               --                Quad_Phase          <= '0';-- permanent '0'  
                               --                --------------------                         
                               --                Addr_Mode_1         <= '0';                  
                               --                Addr_Mode_0         <= '0';                  
                               --                Addr_Bit            <= '0';                  
                               --                Addr_Phase          <= '0';                  
                               --                --------------------                         
                               --                CMD_Mode_1          <= '0';                  
                               --                CMD_Mode_0          <= '0';                  
                               -- when "10"   => -- write enable is done and enable 4 byte addressing is also done
                    when '1'       => -- write enable and enable 4 byte addressing is also done
                                              Data_Dir            <= '0';                  
                                              Data_Mode_1         <= '0';                  
                                              Data_Mode_0         <= '0';                  
                                              Data_Phase          <= '1';                  
                                              --------------------                         
                                              Quad_Phase          <= '0';-- permanent '0'  
                                              --------------------                         
                                              Addr_Mode_1         <= '0';                  
                                              Addr_Mode_0         <= '0';                  
                                              Addr_Bit            <= '1';                  
                                              Addr_Phase          <= '1';                  
                                              --------------------                         
                                              CMD_Mode_1          <= '0';                  
                                              CMD_Mode_0          <= '0';                  
                               -- coverage off
                    when others => 
                                              Data_Dir            <= '0';                  
                                              Data_Mode_1         <= '0';                  
                                              Data_Mode_0         <= '0';                  
                                              Data_Phase          <= '0';                  
                                              --------------------                         
                                              Quad_Phase          <= '0';-- permanent '0'  
                                              --------------------                         
                                              Addr_Mode_1         <= '0';                  
                                              Addr_Mode_0         <= '0';                  
                                              Addr_Bit            <= '0';                  
                                              Addr_Phase          <= '0';                  
                                              --------------------                         
                                              CMD_Mode_1          <= '0';                  
                                              CMD_Mode_0          <= '0';                  
                               -- coverage on
                end case;
                   end if;
             end process DRIVE_CONTROL_SIG_P;
             ---------------------------------------------------------------------
      --end generate NM_EN_32_ADDR_MD_GEN;
       end generate STD_SPI_CMD_SP_32_BIT_GEN;
       ---------------------------------------
       -- wb_hpm_done    <= four_byte_en_done;
       
       --Data_Dir            <= '0';
       --Data_Mode_1         <= '0';
       --Data_Mode_0         <= '0';
       --Data_Phase          <= '0';
       ----------------------
       --Quad_Phase          <= '0';-- permanent '0'
       ----------------------
       --Addr_Mode_1         <= '0';
       --Addr_Mode_0         <= '0';
       --Addr_Bit            <= '0';
       --Addr_Phase          <= '1';
       ----------------------
       --CMD_Mode_1          <= '0';
       --CMD_Mode_0          <= '0';
       ---------------------------

       -----
       RECEIVE_DATA_STROBE_PROCESS: process(EXT_SPI_CLK)
       -----
       begin
       -----
           if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
              if(load_axi_data_to_spi_clk = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
                      receive_Data_int  <= (others => '0');
              -- elsif(SPIXfer_done_int = '1') and (cmd_addr_cntr = "110")then
              elsif(SPIXfer_done_int_pulse = '1') then
                      receive_Data_int  <= rx_shft_reg_mode_0011;
              elsif(SPIXfer_done_int_pulse_d1 = '1') and (cmd_addr_sent = '1')then
					  receive_Data_int <= receive_Data_int
                                         ((C_NUM_TRANSFER_BITS-2) downto 0) &
                                                                  IO1_I ; --MISO_I;
              end if;
           end if;
       end process RECEIVE_DATA_STROBE_PROCESS;

       CMD_ADDR_24_BIT_CNTR_GEN : if  C_SPI_MEM_ADDR_BITS = 24 generate
       begin      
         -- CMD_ADDR_CNTR_P: in each SPI transaction, the first 5 transactions are of
         --                  CMD, A0, A1, A2 and dummy. Total 5 bytes need to be removed from the
         --                  calculation of total no. of pure data bytes.
         --                  the actual data from the SPI memory will be stored in the
         --                  receive FIFO only when the first 5 bytes are transferred.
         --                  below counter is for that purpose only. Tihs is for 24 bit addressing mode only.
         CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
         begin
              if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                  if(Rst_to_spi = '1') or (wrap_around = '1') then
                      cmd_addr_cntr <= "000";
                      cmd_addr_sent <= '0';
                  elsif(pr_state_idle = '1') then --  and store_date_in_drr_fifo_d3 = '1')then
                      cmd_addr_cntr <= "000";
                      cmd_addr_sent <= wrap_around;
                  elsif(SPIXfer_done_int = '1')then
                      if(cmd_addr_cntr = "101")then
                          cmd_addr_sent <= '1';
                      else
                          cmd_addr_cntr <= cmd_addr_cntr + "001";
                          cmd_addr_sent <= '0';
                      end if;
                  end if;
              end if;
         end process CMD_ADDR_CNTR_P;
         ----------------------------
       end generate CMD_ADDR_24_BIT_CNTR_GEN;
       --------------------------------------
       
       CMD_ADDR_32_BIT_CNTR_GEN : if C_SPI_MEM_ADDR_BITS = 32 generate
       begin      
         -- * -- -----
         -- * -- RECEIVE_DATA_STROBE_PROCESS: process(EXT_SPI_CLK)
         -- * -- -----
         -- * -- begin
         -- * -- -----
         -- * --     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
         -- * --        if(load_axi_data_to_spi_clk = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
         -- * --                receive_Data_int  <= (others => '0');
         -- * --        elsif(SPIXfer_done_int_pulse_d1 = '1') and (cmd_addr_sent = '1') then  -- and (cmd_addr_cntr = "111")then
         -- * --                receive_Data_int  <= rx_shft_reg_mode_0011;
         -- * --        end if;
         -- * --     end if;
         -- * -- end process RECEIVE_DATA_STROBE_PROCESS;
         -- CMD_ADDR_CNTR_P: in each SPI transaction, the first 6 transactions are of
         --                  CMD, A0, A1, A2, A3 and dummy. Total 6 bytes need to be removed from the
         --                  calculation of total no. of pure data bytes.
         --                  the actual data from the SPI memory will be stored in the
         --                  receive FIFO only when the first 6 bytes are transferred.
         --                  below counter is for that purpose only. This is for 32 bit addressing mode only.
         CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
         begin
              if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                  if(Rst_to_spi = '1') or (wrap_around = '1') then
                      cmd_addr_cntr <= "000";
                      cmd_addr_sent <= '0';
                  elsif(pr_state_idle = '1' and store_date_in_drr_fifo_d3 = '1')then
                      cmd_addr_cntr <= "000";
                      cmd_addr_sent <= wrap_around;
                  elsif(SPIXfer_done_int = '1' and wb_hpm_done = '1')then
                      if(cmd_addr_cntr = "110")then
                          cmd_addr_sent <= '1';
                      else
                          cmd_addr_cntr <= cmd_addr_cntr + "001";
                          cmd_addr_sent <= '0';
                      end if;
                  end if;
              end if;
         end process CMD_ADDR_CNTR_P;
         ----------------------------
       end generate CMD_ADDR_32_BIT_CNTR_GEN;
       --------------------------------------
       
       -- TWO_BIT_CNTR_P: This is specifically used for HW data storage
       TWO_BIT_CNTR_P:process(EXT_SPI_CLK)is
       begin
       -----
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
           if(load_axi_data_to_spi_clk = '1') or (wrap_around = '1') then
               hw_wd_cntr <= (others => '0');
           elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1')then
               hw_wd_cntr <= hw_wd_cntr + "01";
           end if;
       end if;
       end process TWO_BIT_CNTR_P;
       ----------------------------------------------
       
       STORE_RX_DATA_SPI_CLK_P:process(EXT_SPI_CLK)is
       begin
       -----
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
            if(load_axi_data_to_spi_clk = '1') then
                    Data_To_Rx_FIFO_int <= (others => '0');
            elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1') then
                if(one_byte_xfer_to_spi_clk = '1') then
                    case spi_addr_i(1 downto 0) is
                        when "00" =>
                         Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 8) &
                                                receive_Data_int;
                        when "01" =>
                         Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 16)&
                                                receive_Data_int                 &
                                                Data_To_Rx_FIFO_int(7 downto 0);
                        when "10" =>
                         Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 24)&
                                                receive_Data_int                 &
                                                Data_To_Rx_FIFO_int(15 downto 0);
                        when "11" =>
                         Data_To_Rx_FIFO_int <= receive_Data_int                 &
                                                Data_To_Rx_FIFO_int(23 downto 0);
                        when others => null;
                    end case;
                elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '0') then  -- adjustment for half word
                    if(spi_addr_i(1) = '0') then
                       Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);-- & receive_Data_int;
                       Data_To_Rx_FIFO_int(15 downto 0)  <= receive_Data_int & Data_To_Rx_FIFO_int(15 downto 8);-- & receive_Data_int;
                    else
                       Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);-- & receive_Data_int;
                       Data_To_Rx_FIFO_int(31 downto 16)<= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 24);-- & receive_Data_int;
                    end if;
                elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '1') then  -- adjustment for half word
                    if(hw_wd_cntr = "00") then -- fill in D0
                        Data_To_Rx_FIFO_int(31 downto 8) <= Data_To_Rx_FIFO_int(31 downto 8);
                        Data_To_Rx_FIFO_int(7 downto 0)  <= receive_Data_int;
                    elsif(hw_wd_cntr = "01")then -- fill in D1
                        Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);
                        Data_To_Rx_FIFO_int(15 downto 8)  <= receive_Data_int;
                        Data_To_Rx_FIFO_int(7 downto 0) <= Data_To_Rx_FIFO_int(7 downto 0);
                    elsif(hw_wd_cntr = "10")then -- fill in D2
                        Data_To_Rx_FIFO_int(31 downto 24) <= Data_To_Rx_FIFO_int(31 downto 24);
                        Data_To_Rx_FIFO_int(23 downto 16)  <= receive_Data_int;
                        Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);
                    else
                        Data_To_Rx_FIFO_int(31 downto 24) <= receive_Data_int;
                        Data_To_Rx_FIFO_int(23 downto 0) <= Data_To_Rx_FIFO_int(23 downto 0);
                    end if;
                else   -- adjustment for complete word
                       --Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(23 downto 0) & receive_Data_int;
                       Data_To_Rx_FIFO_int <= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 8);
                end if;
        end if;
       end if;
       end process STORE_RX_DATA_SPI_CLK_P;
       ----------------------------
       Data_To_Rx_FIFO <= Data_To_Rx_FIFO_int;
       ---------------------------------------
     end generate SP_MEM_STD_MD_GEN;
 
end generate STD_MODE_CONTROL_GEN;

-------------------------------------------------------------------------------
DUAL_MODE_CONTROL_GEN: if C_SPI_MODE = 1 generate
signal cmd_addr_cntr : std_logic_vector(2 downto 0);-----
signal hw_wd_cntr    : std_logic_vector(1 downto 0);
begin
-----
        WB_MEM_DUAL_MD_GEN: if C_SPI_MEMORY = 1 generate
        -----
        begin
        -----
          wb_wr_hpm_CMD <= "10100011"; -- 0xA3 h HPM mode
          --
          ----------------------------------------------------
          WB_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
          -----
          begin
          -----
              if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                  if(Rst_to_spi = RESET_ACTIVE) then
                      wb_cntrl_ps        <= WB_IDLE;
                      hpm_under_process_d1 <= '0';
                  else
                      wb_cntrl_ps        <= wb_cntrl_ns;
                      hpm_under_process_d1 <= hpm_under_process;
                  end if;
              end if;
          end process WB_PS_TO_NS_PROCESS;
          ----------------------------------
          --
          WB_DUAL_CNTRL_PROCESS: process(
                                         wb_cntrl_ps           ,
                                         SPIXfer_done_int_pulse,
                                         SPIXfer_done_int      ,
                                         Rst_to_spi            ,
                                         SR_5_Tx_Empty
                                         ) is
          -----
          begin
          -----
               load_wr_en_cmd <= '0';
               load_wr_sr_cmd <= '0';
               load_wr_sr_d0  <= '0';
               load_wr_sr_d1  <= '0';
               load_wr_hpm    <= '0';
               wb_hpm_done    <= '0';
               hpm_under_process <= '0';
               case wb_cntrl_ps is
                   when WB_IDLE     => --load_wr_en_cmd <= '1';
                                        load_wr_hpm <= '1';
                                        hpm_under_process <= '1';
                                       wb_cntrl_ns <= WB_WR_HPM;
                   when WB_WR_HPM   => if (SR_5_Tx_Empty = '1')then
                                           wb_hpm_done <= '1';
                                           wb_cntrl_ns <= WB_DONE;
                                       else
                                           hpm_under_process <= '1';
                                           wb_cntrl_ns <= WB_WR_HPM;
                                       end if;
                   when WB_DONE     => if (Rst_to_spi = '1') then
                                           wb_cntrl_ns <= WB_IDLE;
                                       else
                                           wb_hpm_done <= '1';
                                           wb_cntrl_ns <= WB_DONE;
                                       end if;
               end case;
          end process WB_DUAL_CNTRL_PROCESS;
          
          ---- Dual mode command = 0x3B - DOFR
          --SPI_cmd <= "00111011";
          SPI_cmd <= "10111011"; -- 0xBB - DIOFR
          -- WB 0011 000 100 0
          -- NM 0011 000 100 0<-cmd error
          -- NM 0011 010 100 0<-cmd error -- For 0xbbh DIOFR
          Data_Dir            <= '0';
          Data_Mode_1         <= '0';
          Data_Mode_0         <= '1';
          Data_Phase          <= '1';
          --------------------
          Quad_Phase          <= '0';-- permanent '0'
          --------------------
          Addr_Mode_1         <= '0';
          Addr_Mode_0         <= '1'; -- <- '0' for DOFR, '1' for DIOFR
          Addr_Bit            <= '0';
          Addr_Phase          <= '1';
          --------------------
          CMD_Mode_1          <= '0';
          CMD_Mode_0          <= '0';
          
          ---------------------------------------------------------------------
          --RECEIVE_DATA_WB_GEN: if C_SPI_MEMORY = 1 and C_SPI_MODE /=0 generate
          --begin
          -----
          RECEIVE_DATA_STROBE_PROCESS: process(EXT_SPI_CLK)
          -----
          begin
          -----
              if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                 if(load_axi_data_to_spi_clk = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
                         receive_Data_int  <= (others => '0');
                elsif(SPIXfer_done_int_pulse = '1') then
                      receive_Data_int  <= rx_shft_reg_mode_0011;
                 elsif(SPIXfer_done_int_pulse_d1 = '1') and (cmd_addr_sent = '1')then
					  receive_Data_int <= receive_Data_int
                                         ((C_NUM_TRANSFER_BITS-3) downto 0) &
                                                                  IO1_I &  -- MISO_I - MSB first
                                                                  IO0_I ;  -- MOSI_I
                 end if;
              end if;
          end process RECEIVE_DATA_STROBE_PROCESS;
          --end generate RECEIVE_DATA_WB_GEN;
          ---------------------------------------------------------------------
          -- CMD_ADDR_CNTR_P: in each SPI transaction, the firs 4 transactions are of
          --                  CMD, A0, A1, A2. Total 4 bytes need to be removed from the
          --                  calculation of total no. of pure data bytes.
          --                  the actual data from the SPI memory will be stored in the
          --                  receive FIFO only when the first 4 bytes are transferred.
          --                  below counter is for that purpose only.
          CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
          -----
          begin
          -----
               if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                   if(Rst_to_spi = '1') or (store_last_b4_wrap = '1') then
                       cmd_addr_cntr <= "000";--(others => '1');
                       cmd_addr_sent <= '0';
                   elsif(pr_state_idle = '1')then
                       cmd_addr_cntr <= "000";
                       cmd_addr_sent <= store_last_b4_wrap;
                   elsif(SPIXfer_done_int_pulse_d2 = '1')then
                       if(cmd_addr_cntr = "100")then
                           cmd_addr_sent <= '1';
                       else
                           cmd_addr_cntr <= cmd_addr_cntr + "001";
                           cmd_addr_sent <= '0';
                       end if;
                   end if;
               end if;
          end process CMD_ADDR_CNTR_P;
          ----------------------------
          TWO_BIT_CNTR_P:process(EXT_SPI_CLK)is
          begin
          -----
          if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
              if(load_axi_data_to_spi_clk = '1') or (store_last_b4_wrap = '1') then
                  hw_wd_cntr <= (others => '0');
              elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1')then
                  hw_wd_cntr <= hw_wd_cntr + "01";
              end if;
          end if;
          end process TWO_BIT_CNTR_P;
          ----------------------------------------------
          STORE_RX_DATA_SPI_CLK_P:process(EXT_SPI_CLK)is
          begin
          -----
          if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
              if(load_axi_data_to_spi_clk = '1') then
                  Data_To_Rx_FIFO_int <= (others => '0');
              elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1') then
                  if(one_byte_xfer_to_spi_clk = '1') then
                     case spi_addr_i(1 downto 0) is
                          when "00" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 8) &
                                                             receive_Data_int;
                          when "01" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 16)&
                                                             receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(7 downto 0);
                          when "10" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 24)&
                                                             receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(15 downto 0);
                          when "11" =>
                                      Data_To_Rx_FIFO_int <= receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(23 downto 0);
                          when others => null;
                     end case;
                  elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '0') then  -- adjustment for half word
                     if(spi_addr_i(1) = '0') then
                         Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);-- & receive_Data_int;
                         Data_To_Rx_FIFO_int(15 downto 0)  <= receive_Data_int & Data_To_Rx_FIFO_int(15 downto 8);-- & receive_Data_int;
                     else
                         Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);-- & receive_Data_int;
                         Data_To_Rx_FIFO_int(31 downto 16)<= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 24);-- & receive_Data_int;
                     end if;
                  elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '1') then  -- adjustment for half word
                     if(hw_wd_cntr = "00") then -- fill in D0
                         Data_To_Rx_FIFO_int(31 downto 8) <= Data_To_Rx_FIFO_int(31 downto 8);
                         Data_To_Rx_FIFO_int(7 downto 0)  <= receive_Data_int;
                     elsif(hw_wd_cntr = "01")then -- fill in D1
                         Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);
                         Data_To_Rx_FIFO_int(15 downto 8)  <= receive_Data_int;
                         Data_To_Rx_FIFO_int(7 downto 0) <= Data_To_Rx_FIFO_int(7 downto 0);
                     elsif(hw_wd_cntr = "10")then -- fill in D2
                         Data_To_Rx_FIFO_int(31 downto 24) <= Data_To_Rx_FIFO_int(31 downto 24);
                         Data_To_Rx_FIFO_int(23 downto 16)  <= receive_Data_int;
                         Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);
                     else
                         Data_To_Rx_FIFO_int(31 downto 24) <= receive_Data_int;
                         Data_To_Rx_FIFO_int(23 downto 0) <= Data_To_Rx_FIFO_int(23 downto 0);
                     end if;
                  else   -- adjustment for complete word
                     --Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(23 downto 0) & receive_Data_int;
                     Data_To_Rx_FIFO_int <= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 8);
                  end if;
              end if;
          end if;
          end process STORE_RX_DATA_SPI_CLK_P;
          ----------------------------
          Data_To_Rx_FIFO <= Data_To_Rx_FIFO_int;
          ---------------------------------------
        end generate WB_MEM_DUAL_MD_GEN;
        ---------------=============-------------------------------------------
        
        NM_MEM_DUAL_MD_GEN: if C_SPI_MEMORY = 2 generate
        -----
        begin
        -----
          --wb_hpm_done    <= '1';
          ---- Dual mode command = 0x3B - DOFR
          --SPI_cmd <= "00111011";
          --------------------------------------------------------
          DUAL_SPI_CMD_NM_24_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
          -----
          begin
          -----
              ---------------------------
              SPI_cmd <= "10111011"; -- 0xBB - DIOFR
              wb_hpm_done <= '1';
              --------------------------- 
              Data_Dir            <= '0';-- for BB       
              Data_Mode_1         <= '0';                       
              Data_Mode_0         <= '1';                       
              Data_Phase          <= '1';                       
              --------------------                      
              Quad_Phase          <= '0';-- permanent '0'       
              --------------------                      
              Addr_Mode_1         <= '0';                       
              Addr_Mode_0         <= '1';                       
              Addr_Bit            <= '0';                       
              Addr_Phase          <= '1';                       
              --------------------                      
              CMD_Mode_1          <= '0';                       
              CMD_Mode_0          <= '0';                        
              ---------------------------
          end generate DUAL_SPI_CMD_NM_24_GEN;
          ------------------------------------

          DUAL_SPI_CMD_NM_32_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
          -----
          begin
          -----
              
              SPI_cmd <= "10111100"; -- 0xBCh - DIOFR_4Byte

          end generate DUAL_SPI_CMD_NM_32_GEN;
          ------------------------------------
          
          NM_EN_32_ADDR_MD_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
          begin
          -----
             nm_wr_en_CMD         <= "00000110"; -- 0x06 h Write Enable
             nm_4byte_addr_en_CMD <= "10110111"; -- 0xB7 h Enable 4 Byte Addressing Mode
             ----------------------------------------------------
             NM_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
             -----
             begin
             -----
                 if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                     if(Rst_to_spi = RESET_ACTIVE) then
                         nm_wr_en_cntrl_ps      <= NM_WR_EN_IDLE;
                         wr_en_under_process_d1 <= '0';
                   wr_en_done_reg         <= '0';
                     else
                         nm_wr_en_cntrl_ps      <= nm_wr_en_cntrl_ns;
                         wr_en_under_process_d1 <= wr_en_under_process;
                   wr_en_done_reg         <= wr_en_done;
          
                     end if;
                 end if;
             end process NM_PS_TO_NS_PROCESS;
             ----------------------------------
             --
             NM_WR_EN_CNTRL_PROCESS: process(
                                            nm_wr_en_cntrl_ps     ,
                                            --SPIXfer_done_int_pulse,
                                            --SPIXfer_done_int      ,
                                            Rst_to_spi            ,
                                            SR_5_Tx_Empty         ,
                                            wr_en_done_reg
                                            ) is
             -----
             begin
             -----
                  --load_wr_en_cmd <= '0';
                  --load_wr_sr_cmd <= '0';
                  --load_wr_sr_d0  <= '0';
                  --load_wr_sr_d1  <= '0';
                  load_wr_en    <= '0';
                  wr_en_done    <= '0';
                  wr_en_under_process <= '0';
                  case nm_wr_en_cntrl_ps is
                      when NM_WR_EN_IDLE => --load_wr_en_cmd <= '1';
                                          load_wr_en          <= '1';
                                          wr_en_under_process <= '1';
                                          nm_wr_en_cntrl_ns   <= NM_WR_EN;
                      when NM_WR_EN      => if (SR_5_Tx_Empty = '1')then
                                                --wr_en_done <= '1';
                                                nm_wr_en_cntrl_ns <= NM_WR_EN_DONE;
                                            else
                                                --wr_en_under_process <= '1';
                                                nm_wr_en_cntrl_ns <= NM_WR_EN;
                                            end if;
                                            wr_en_done          <= SR_5_Tx_Empty;
                                            wr_en_under_process <= not SR_5_Tx_Empty;
          
                      when NM_WR_EN_DONE => if (Rst_to_spi = '1') then
                                                nm_wr_en_cntrl_ns <= NM_WR_EN_IDLE;
                                            else
                                                nm_wr_en_cntrl_ns <= NM_WR_EN_DONE;
                                            end if;
                                            wr_en_done <= wr_en_done_reg;
                  end case;
             end process NM_WR_EN_CNTRL_PROCESS;
          
               ----------------------------------------------------
               NM_4_BYTE_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
               -----
               begin
               -----
                   if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                       if(Rst_to_spi = RESET_ACTIVE) then
                           nm_sm_4_byte_addr_ps           <= NM_32_BIT_IDLE;
                           --four_byte_addr_under_process_d1 <= '0';
                     hpm_under_process_d1   <= '0';
                     wr_en_done_d1          <= '0';
                     wr_en_done_d2          <= '0';
                     wb_hpm_done_reg        <= '0';
                       else
                           nm_sm_4_byte_addr_ps   <= nm_sm_4_byte_addr_ns;
                           hpm_under_process_d1   <= hpm_under_process;
                           --four_byte_en_done_reg           <= four_byte_en_done;   
                     wr_en_done_d1          <= wr_en_done_reg; -- wr_en_done;
                     wr_en_done_d2          <= wr_en_done_d1;
                     wb_hpm_done_reg        <= wb_hpm_done;
                       end if;
                   end if;
               end process NM_4_BYTE_PS_TO_NS_PROCESS;
               ----------------------------------
               --
               NM_4_BYTE_ADDR_EN_PROCESS: process(
                                                  nm_sm_4_byte_addr_ps  ,
                                                  Rst_to_spi            ,
                                                  SR_5_Tx_Empty         ,
                                                  wr_en_done_d2         ,
                                            wb_hpm_done_reg
                                                 ) is
               -----
               begin
               -----
                    -- load_4_byte_addr_en     <= '0';
              load_wr_hpm <= '0';
                    wb_hpm_done <= '0';
              hpm_under_process <= '0';
                    four_byte_en_done          <= '0';
                    four_byte_en_under_process <= '0';
                    case nm_sm_4_byte_addr_ps is
                        when NM_32_BIT_IDLE     => if (wr_en_done_d2 = '1') then
                                                 --load_wr_hpm <= '1';
                                                 --hpm_under_process <= '1';
                                                       nm_sm_4_byte_addr_ns      <= NM_32_BIT_EN;
                                                   else
                                                       nm_sm_4_byte_addr_ns      <= NM_32_BIT_IDLE;
                                                   end if;
                                             load_wr_hpm       <= wr_en_done_d2; 
                                             hpm_under_process <= wr_en_done_d2;
               
                        when NM_32_BIT_EN      => if (SR_5_Tx_Empty = '1') then
                                                -- wb_hpm_done        <= '1';
                                                nm_sm_4_byte_addr_ns <= NM_32_BIT_EN_DONE;
                                            else
                                                -- hpm_under_process  <= '1';
                                                      nm_sm_4_byte_addr_ns <= NM_32_BIT_EN;
                                            end if;
                                                  wb_hpm_done        <= SR_5_Tx_Empty;
                                            hpm_under_process  <= not(SR_5_Tx_Empty);
                  when NM_32_BIT_EN_DONE => if(Rst_to_spi = '1')then
                                                      nm_sm_4_byte_addr_ns <= NM_32_BIT_IDLE;
                                                  else
                                                    --  if (SR_5_Tx_Empty = '1')then
                                                    --      --four_byte_en_done          <= '1';
                                              --      wb_hpm_done <= '1';
                                                    --  else
                                                    --      -- four_byte_en_under_process <= '1';
                                              --      hpm_under_process <= '1';
                                                    --  end if;
                                                    --  four_byte_en_done     <= four_byte_en_done_reg;     
                                                      -- wb_hpm_done <= '1';
                                                nm_sm_4_byte_addr_ns <= NM_32_BIT_EN_DONE;
                                                  end if;
                                                  wb_hpm_done <= wb_hpm_done_reg;
               
                    end case;
               end process NM_4_BYTE_ADDR_EN_PROCESS;
               --------------------------------------
         DRIVE_CONTROL_SIG_P: process(EXT_SPI_CLK, wb_hpm_done, wr_en_done_reg) is -- wb_hpm_done, wr_en_done_reg) is
         variable temp: std_logic_vector(1 downto 0);
         begin
                temp := wb_hpm_done & wr_en_done_reg;
                if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                        case wb_hpm_done is
                            -- when "00"|"01" => -- write enable is under process
                            when '0'       => -- write enable and/or Enable 4 byte addressing is under process
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '0';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- when "01"   => -- Enable 4 byte addressing is under process
                            --                Data_Dir            <= '0';                  
                            --                Data_Mode_1         <= '0';                  
                            --                Data_Mode_0         <= '0';                  
                            --                Data_Phase          <= '0';                  
                            --                --------------------                         
                            --                Quad_Phase          <= '0';-- permanent '0'  
                            --                --------------------                         
                            --                Addr_Mode_1         <= '0';                  
                            --                Addr_Mode_0         <= '0';                  
                            --                Addr_Bit            <= '0';                  
                            --                Addr_Phase          <= '0';                  
                            --                --------------------                         
                            --                CMD_Mode_1          <= '0';                  
                            --                CMD_Mode_0          <= '0';                  
                            -- when "10"   => -- write enable is done and enable 4 byte addressing is also done
                            when '1'       => -- write enable and enable 4 byte addressing is also done
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '1';                  
                                           Data_Phase          <= '1';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '1';                  
                                           Addr_Bit            <= '1';                  
                                           Addr_Phase          <= '1';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- coverage off
                            when others => 
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '0';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- coverage on
                        end case;
                end if;
         end process DRIVE_CONTROL_SIG_P;
         
         end generate NM_EN_32_ADDR_MD_GEN;
         --------------------------------------
         -- -- WB 0011 000 100 0
         -- -- NM 0011 000 100 0<-cmd error
         -- -- NM 0011 010 100 0<-cmd error -- For 0xbbh DIOFR
         --       0011 011 100 0
         -- Data_Dir            <= '0';<-- for BB       -- '0';<-- for BC
         -- Data_Mode_1         <= '0';                 -- '0';
         -- Data_Mode_0         <= '1';                 -- '1';
         -- Data_Phase          <= '1';                 -- '1';
         -- --------------------                        -- 
         -- Quad_Phase          <= '0';-- permanent '0' -- '0';
         -- --------------------                        -- 
         -- Addr_Mode_1         <= '0';                 -- '0';
         -- Addr_Mode_0         <= '1';                 -- '1';
         -- Addr_Bit            <= '0';                 -- '1';
         -- Addr_Phase          <= '1';                 -- '1';
         -- --------------------                        -- 
         -- CMD_Mode_1          <= '0';                 -- '0'
         -- CMD_Mode_0          <= '0';                 -- '0';

          ---------------------------------------------------------------------
          -- RECEIVE_DATA_STROBE_PROCESS : Strobe data from shift register to receive
          --                               data register
          --------------------------------
          -- For a SCK ratio of 2 the Done needs to be delayed by an extra cycle
          -- due to the serial input being captured on the falling edge of the PLB
          -- clock. this is purely required for dealing with the real SPI slave memories.
            --RECEIVE_DATA_NM_GEN: if C_SPI_MEMORY = 2 and C_SPI_MODE /=0 generate
            --begin
            -----
            RECEIVE_DATA_STROBE_PROCESS: process(EXT_SPI_CLK)
            -----
            begin
            -----
                if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                   if(load_axi_data_to_spi_clk = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
                           receive_Data_int  <= (others => '0');
              elsif(SPIXfer_done_int_pulse = '1') then
                      receive_Data_int  <= rx_shft_reg_mode_0011;
              elsif(SPIXfer_done_int_pulse_d1 = '1') then
					  receive_Data_int <= receive_Data_int
                                         ((C_NUM_TRANSFER_BITS-3) downto 0) &
                                                                  IO1_I &  -- MISO_I - MSB first
                                                                  IO0_I ;  -- MOSI_I
                   end if;
                end if;
            end process RECEIVE_DATA_STROBE_PROCESS;
            --end generate RECEIVE_DATA_NM_GEN;
            -----------------------------------------------------------------------------
          CMD_ADDR_NM_24_BIT_GEN: if  C_SPI_MEM_ADDR_BITS = 24 generate
          begin
            -- CMD_ADDR_CNTR_P: in each SPI transaction, the firs 4 transactions are of
            --                  CMD, A0, A1, A2. Total 4 bytes need to be removed from the
            --                  calculation of total no. of pure data bytes.
            --                  the actual data from the SPI memory will be stored in the
            --                  receive FIFO only when the first 4 bytes are transferred.
            --                  below counter is for that purpose only.
            CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
            -----
            begin
            -----
             if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                 if(Rst_to_spi = '1') or (store_last_b4_wrap = '1') then
                     cmd_addr_cntr <= "000";--(others => '1');
                     cmd_addr_sent <= '0';
                 elsif(pr_state_idle = '1')then
                     cmd_addr_cntr <= "000";
                     cmd_addr_sent <= store_last_b4_wrap;
                 elsif(SPIXfer_done_int_pulse_d2 = '1')then
                     if(cmd_addr_cntr = "101")then
                         cmd_addr_sent <= '1';
                     else
                         cmd_addr_cntr <= cmd_addr_cntr + "001";
                         cmd_addr_sent <= '0';
                     end if;
                 end if;
             end if;
            end process CMD_ADDR_CNTR_P;
            ----------------------------
          end generate CMD_ADDR_NM_24_BIT_GEN;
          ------------------------------------
          CMD_ADDR_NM_32_BIT_GEN: if  C_SPI_MEM_ADDR_BITS = 32 generate
          begin
            -- CMD_ADDR_CNTR_P: in each SPI transaction, the firs 5 transactions are of
            --                  CMD, A0, A1, A2, A3. Total 5 bytes need to be removed from the
            --                  calculation of total no. of pure data bytes.
            --                  the actual data from the SPI memory will be stored in the
            --                  receive FIFO only when the first 5 bytes are transferred.
            --                  below counter is for that purpose only. This is 4 byte addessing mode of NM memory.
            CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
            -----
            begin
            -----
             if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                 if(Rst_to_spi = '1') or (store_last_b4_wrap = '1') then
                     cmd_addr_cntr <= "000";--(others => '1');
                     cmd_addr_sent <= '0';
                 elsif(pr_state_idle = '1')then
                     cmd_addr_cntr <= "000";
                     cmd_addr_sent <= store_last_b4_wrap;
                 elsif(SPIXfer_done_int_pulse_d2 = '1')then
                     if(cmd_addr_cntr = "111")then
                         cmd_addr_sent <= '1';
                     else
                         cmd_addr_cntr <= cmd_addr_cntr + "001";
                         cmd_addr_sent <= '0';
                     end if;
                 end if;
             end if;
            end process CMD_ADDR_CNTR_P;
            ----------------------------
          end generate CMD_ADDR_NM_32_BIT_GEN;
          ------------------------------------
          
          TWO_BIT_CNTR_P:process(EXT_SPI_CLK)is
          begin
          -----
          if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
              if(load_axi_data_to_spi_clk = '1') or (store_last_b4_wrap = '1') then
                  hw_wd_cntr <= (others => '0');
              elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1')then
                  hw_wd_cntr <= hw_wd_cntr + "01";
              end if;
          end if;
          end process TWO_BIT_CNTR_P;
          ----------------------------------------------
          STORE_RX_DATA_32_BIT_ADDR: if C_SPI_MEM_ADDR_BITS = 32 generate
          begin
          -----
          STORE_RX_DATA_SPI_CLK_P:process(EXT_SPI_CLK)is
          begin
          -----
          if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
              if(load_axi_data_to_spi_clk = '1') then
                  Data_To_Rx_FIFO_int <= (others => '0');
              elsif(SPIXfer_done_int_pulse_d3 = '1') and (cmd_addr_sent = '1') then
                  if(one_byte_xfer_to_spi_clk = '1') then
                     case spi_addr_i(1 downto 0) is
                          when "00" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 8) &
                                                             receive_Data_int;
                          when "01" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 16)&
                                                             receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(7 downto 0);
                          when "10" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 24)&
                                                             receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(15 downto 0);
                          when "11" =>
                                      Data_To_Rx_FIFO_int <= receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(23 downto 0);
                          when others => null;
                     end case;
                  elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '0') then  -- adjustment for half word
                     if(spi_addr_i(1) = '0') then
                         Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);-- & receive_Data_int;
                         Data_To_Rx_FIFO_int(15 downto 0)  <= receive_Data_int & Data_To_Rx_FIFO_int(15 downto 8);-- & receive_Data_int;
                     else
                         Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);-- & receive_Data_int;
                         Data_To_Rx_FIFO_int(31 downto 16)<= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 24);-- & receive_Data_int;
                     end if;
                  elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '1') then  -- adjustment for half word
                     if(hw_wd_cntr = "00") then -- fill in D0
                         Data_To_Rx_FIFO_int(31 downto 8) <= Data_To_Rx_FIFO_int(31 downto 8);
                         Data_To_Rx_FIFO_int(7 downto 0)  <= receive_Data_int;
                     elsif(hw_wd_cntr = "01")then -- fill in D1
                         Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);
                         Data_To_Rx_FIFO_int(15 downto 8)  <= receive_Data_int;
                         Data_To_Rx_FIFO_int(7 downto 0) <= Data_To_Rx_FIFO_int(7 downto 0);
                     elsif(hw_wd_cntr = "10")then -- fill in D2
                         Data_To_Rx_FIFO_int(31 downto 24) <= Data_To_Rx_FIFO_int(31 downto 24);
                         Data_To_Rx_FIFO_int(23 downto 16)  <= receive_Data_int;
                         Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);
                     else
                         Data_To_Rx_FIFO_int(31 downto 24) <= receive_Data_int;
                         Data_To_Rx_FIFO_int(23 downto 0) <= Data_To_Rx_FIFO_int(23 downto 0);
                     end if;
                  else   -- adjustment for complete word
                     --Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(23 downto 0) & receive_Data_int;
                     Data_To_Rx_FIFO_int <= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 8);
                  end if;
              end if;
          end if;
          end process STORE_RX_DATA_SPI_CLK_P;
          end generate STORE_RX_DATA_32_BIT_ADDR;

          STORE_RX_DATA_24_BIT_ADDR: if C_SPI_MEM_ADDR_BITS = 24 generate
          begin
          -----
          STORE_RX_DATA_SPI_CLK_P:process(EXT_SPI_CLK)is
          begin
          -----
          if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
              if(load_axi_data_to_spi_clk = '1') then
                  Data_To_Rx_FIFO_int <= (others => '0');
              elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1') then
                  if(one_byte_xfer_to_spi_clk = '1') then
                     case spi_addr_i(1 downto 0) is
                          when "00" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 8) &
                                                             receive_Data_int;
                          when "01" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 16)&
                                                             receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(7 downto 0);
                          when "10" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 24)&
                                                             receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(15 downto 0);
                          when "11" =>
                                      Data_To_Rx_FIFO_int <= receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(23 downto 0);
                          when others => null;
                     end case;
                  elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '0') then  -- adjustment for half word
                     if(spi_addr_i(1) = '0') then
                         Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);-- & receive_Data_int;
                         Data_To_Rx_FIFO_int(15 downto 0)  <= receive_Data_int & Data_To_Rx_FIFO_int(15 downto 8);-- & receive_Data_int;
                     else
                         Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);-- & receive_Data_int;
                         Data_To_Rx_FIFO_int(31 downto 16)<= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 24);-- & receive_Data_int;
                     end if;
                  elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '1') then  -- adjustment for half word
                     if(hw_wd_cntr = "00") then -- fill in D0
                         Data_To_Rx_FIFO_int(31 downto 8) <= Data_To_Rx_FIFO_int(31 downto 8);
                         Data_To_Rx_FIFO_int(7 downto 0)  <= receive_Data_int;
                     elsif(hw_wd_cntr = "01")then -- fill in D1
                         Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);
                         Data_To_Rx_FIFO_int(15 downto 8)  <= receive_Data_int;
                         Data_To_Rx_FIFO_int(7 downto 0) <= Data_To_Rx_FIFO_int(7 downto 0);
                     elsif(hw_wd_cntr = "10")then -- fill in D2
                         Data_To_Rx_FIFO_int(31 downto 24) <= Data_To_Rx_FIFO_int(31 downto 24);
                         Data_To_Rx_FIFO_int(23 downto 16)  <= receive_Data_int;
                         Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);
                     else
                         Data_To_Rx_FIFO_int(31 downto 24) <= receive_Data_int;
                         Data_To_Rx_FIFO_int(23 downto 0) <= Data_To_Rx_FIFO_int(23 downto 0);
                     end if;
                  else   -- adjustment for complete word
                     --Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(23 downto 0) & receive_Data_int;
                     Data_To_Rx_FIFO_int <= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 8);
                  end if;
              end if;
          end if;
          end process STORE_RX_DATA_SPI_CLK_P;
          end generate STORE_RX_DATA_24_BIT_ADDR;

        ----------------------------
        Data_To_Rx_FIFO <= Data_To_Rx_FIFO_int;
        ---------------------------------------
        end generate NM_MEM_DUAL_MD_GEN;
        SP_MEM_DUAL_MD_GEN: if C_SPI_MEMORY = 3 generate
        -----
        begin
        -----
          --wb_hpm_done    <= '1';
          ---- Dual mode command = 0x3B - DOFR
          --SPI_cmd <= "00111011";
          --------------------------------------------------------
          DUAL_SPI_CMD_NM_24_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
          -----
          begin
          -----
              ---------------------------
              SPI_cmd <= "10111011"; -- 0xBB - DIOFR
              wb_hpm_done <= '1';
              --------------------------- 
              Data_Dir            <= '0';-- for BB       
              Data_Mode_1         <= '0';                       
              Data_Mode_0         <= '1';                       
              Data_Phase          <= '1';                       
              --------------------                      
              Quad_Phase          <= '0';-- permanent '0'       
              --------------------                      
              Addr_Mode_1         <= '0';                       
              Addr_Mode_0         <= '1';                       
              Addr_Bit            <= '0';                       
              Addr_Phase          <= '1';                       
              --------------------                      
              CMD_Mode_1          <= '0';                       
              CMD_Mode_0          <= '0';                        
              ---------------------------
          end generate DUAL_SPI_CMD_NM_24_GEN;
          ------------------------------------

          DUAL_SPI_CMD_NM_32_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
          -----
          begin
          -----
              
              SPI_cmd <= "10111100"; -- 0xBCh - DIOFR_4Byte

          end generate DUAL_SPI_CMD_NM_32_GEN;
          ------------------------------------
          
          NM_EN_32_ADDR_MD_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
          begin
          -----
             nm_wr_en_CMD         <= "00000110"; -- 0x06 h Write Enable
             nm_4byte_addr_en_CMD <= "10110111"; -- 0xB7 h Enable 4 Byte Addressing Mode
             ----------------------------------------------------
             NM_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
             -----
             begin
             -----
                 if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                     if(Rst_to_spi = RESET_ACTIVE) then
                         nm_wr_en_cntrl_ps      <= NM_WR_EN_IDLE;
                         wr_en_under_process_d1 <= '0';
                   wr_en_done_reg         <= '0';
                     else
                         nm_wr_en_cntrl_ps      <= nm_wr_en_cntrl_ns;
                         wr_en_under_process_d1 <= wr_en_under_process;
                   wr_en_done_reg         <= wr_en_done;
          
                     end if;
                 end if;
             end process NM_PS_TO_NS_PROCESS;
             ----------------------------------
             --
             NM_WR_EN_CNTRL_PROCESS: process(
                                            nm_wr_en_cntrl_ps     ,
                                            --SPIXfer_done_int_pulse,
                                            --SPIXfer_done_int      ,
                                            Rst_to_spi            ,
                                            SR_5_Tx_Empty         ,
                                            wr_en_done_reg
                                            ) is
             -----
             begin
             -----
                  --load_wr_en_cmd <= '0';
                  --load_wr_sr_cmd <= '0';
                  --load_wr_sr_d0  <= '0';
                  --load_wr_sr_d1  <= '0';
                  load_wr_en    <= '0';
                  wr_en_done    <= '0';
                  wr_en_under_process <= '0';
                  case nm_wr_en_cntrl_ps is
                      when NM_WR_EN_IDLE => --load_wr_en_cmd <= '1';
                                          load_wr_en          <= '1';
                                          wr_en_under_process <= '1';
                                          nm_wr_en_cntrl_ns   <= NM_WR_EN;
                      when NM_WR_EN      => if (SR_5_Tx_Empty = '1')then
                                                --wr_en_done <= '1';
                                                nm_wr_en_cntrl_ns <= NM_WR_EN_DONE;
                                            else
                                                --wr_en_under_process <= '1';
                                                nm_wr_en_cntrl_ns <= NM_WR_EN;
                                            end if;
                                            wr_en_done          <= SR_5_Tx_Empty;
                                            wr_en_under_process <= not SR_5_Tx_Empty;
          
                      when NM_WR_EN_DONE => if (Rst_to_spi = '1') then
                                                nm_wr_en_cntrl_ns <= NM_WR_EN_IDLE;
                                            else
                                                nm_wr_en_cntrl_ns <= NM_WR_EN_DONE;
                                            end if;
                                            wr_en_done <= wr_en_done_reg;
                  end case;
             end process NM_WR_EN_CNTRL_PROCESS;
          
               ----------------------------------------------------
               NM_4_BYTE_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
               -----
               begin
               -----
                   if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                       if(Rst_to_spi = RESET_ACTIVE) then
                           nm_sm_4_byte_addr_ps           <= NM_32_BIT_IDLE;
                           --four_byte_addr_under_process_d1 <= '0';
                     hpm_under_process_d1   <= '0';
                     wr_en_done_d1          <= '0';
                     wr_en_done_d2          <= '0';
                     wb_hpm_done_reg        <= '0';
                       else
                           nm_sm_4_byte_addr_ps   <= nm_sm_4_byte_addr_ns;
                           hpm_under_process_d1   <= hpm_under_process;
                           --four_byte_en_done_reg           <= four_byte_en_done;   
                     wr_en_done_d1          <= wr_en_done_reg; -- wr_en_done;
                     wr_en_done_d2          <= wr_en_done_d1;
                     wb_hpm_done_reg        <= wb_hpm_done;
                       end if;
                   end if;
               end process NM_4_BYTE_PS_TO_NS_PROCESS;
               ----------------------------------
               --
               NM_4_BYTE_ADDR_EN_PROCESS: process(
                                                  nm_sm_4_byte_addr_ps  ,
                                                  Rst_to_spi            ,
                                                  SR_5_Tx_Empty         ,
                                                  wr_en_done_d2         ,
                                            wb_hpm_done_reg
                                                 ) is
               -----
               begin
               -----
                    -- load_4_byte_addr_en     <= '0';
              load_wr_hpm <= '0';
                    wb_hpm_done <= '0';
              hpm_under_process <= '0';
                    four_byte_en_done          <= '0';
                    four_byte_en_under_process <= '0';
                    case nm_sm_4_byte_addr_ps is
                        when NM_32_BIT_IDLE     => if (wr_en_done_d2 = '1') then
                                                 --load_wr_hpm <= '1';
                                                 --hpm_under_process <= '1';
                                                       nm_sm_4_byte_addr_ns      <= NM_32_BIT_EN;
                                                   else
                                                       nm_sm_4_byte_addr_ns      <= NM_32_BIT_IDLE;
                                                   end if;
                                             load_wr_hpm       <= wr_en_done_d2; 
                                             hpm_under_process <= wr_en_done_d2;
               
                        when NM_32_BIT_EN      => if (SR_5_Tx_Empty = '1') then
                                                -- wb_hpm_done        <= '1';
                                                nm_sm_4_byte_addr_ns <= NM_32_BIT_EN_DONE;
                                            else
                                                -- hpm_under_process  <= '1';
                                                      nm_sm_4_byte_addr_ns <= NM_32_BIT_EN;
                                            end if;
                                                  wb_hpm_done        <= SR_5_Tx_Empty;
                                            hpm_under_process  <= not(SR_5_Tx_Empty);
                  when NM_32_BIT_EN_DONE => if(Rst_to_spi = '1')then
                                                      nm_sm_4_byte_addr_ns <= NM_32_BIT_IDLE;
                                                  else
                                                    --  if (SR_5_Tx_Empty = '1')then
                                                    --      --four_byte_en_done          <= '1';
                                              --      wb_hpm_done <= '1';
                                                    --  else
                                                    --      -- four_byte_en_under_process <= '1';
                                              --      hpm_under_process <= '1';
                                                    --  end if;
                                                    --  four_byte_en_done     <= four_byte_en_done_reg;     
                                                      -- wb_hpm_done <= '1';
                                                nm_sm_4_byte_addr_ns <= NM_32_BIT_EN_DONE;
                                                  end if;
                                                  wb_hpm_done <= wb_hpm_done_reg;
               
                    end case;
               end process NM_4_BYTE_ADDR_EN_PROCESS;
               --------------------------------------
         DRIVE_CONTROL_SIG_P: process(EXT_SPI_CLK) is -- wb_hpm_done, wr_en_done_reg) is
         variable temp: std_logic_vector(1 downto 0);
         begin
                temp := wb_hpm_done & wr_en_done_reg;
                if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                        case wb_hpm_done is
                            -- when "00"|"01" => -- write enable is under process
                            when '0'       => -- write enable and/or Enable 4 byte addressing is under process
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '0';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- when "01"   => -- Enable 4 byte addressing is under process
                            --                Data_Dir            <= '0';                  
                            --                Data_Mode_1         <= '0';                  
                            --                Data_Mode_0         <= '0';                  
                            --                Data_Phase          <= '0';                  
                            --                --------------------                         
                            --                Quad_Phase          <= '0';-- permanent '0'  
                            --                --------------------                         
                            --                Addr_Mode_1         <= '0';                  
                            --                Addr_Mode_0         <= '0';                  
                            --                Addr_Bit            <= '0';                  
                            --                Addr_Phase          <= '0';                  
                            --                --------------------                         
                            --                CMD_Mode_1          <= '0';                  
                            --                CMD_Mode_0          <= '0';                  
                            -- when "10"   => -- write enable is done and enable 4 byte addressing is also done
                            when '1'       => -- write enable and enable 4 byte addressing is also done
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '1';                  
                                           Data_Phase          <= '1';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '1';                  
                                           Addr_Bit            <= '1';                  
                                           Addr_Phase          <= '1';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- coverage off
                            when others => 
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '0';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- coverage on
                        end case;
                end if;
         end process DRIVE_CONTROL_SIG_P;
         
         end generate NM_EN_32_ADDR_MD_GEN;
         --------------------------------------
         -- -- WB 0011 000 100 0
         -- -- NM 0011 000 100 0<-cmd error
         -- -- NM 0011 010 100 0<-cmd error -- For 0xbbh DIOFR
         --       0011 011 100 0
         -- Data_Dir            <= '0';<-- for BB       -- '0';<-- for BC
         -- Data_Mode_1         <= '0';                 -- '0';
         -- Data_Mode_0         <= '1';                 -- '1';
         -- Data_Phase          <= '1';                 -- '1';
         -- --------------------                        -- 
         -- Quad_Phase          <= '0';-- permanent '0' -- '0';
         -- --------------------                        -- 
         -- Addr_Mode_1         <= '0';                 -- '0';
         -- Addr_Mode_0         <= '1';                 -- '1';
         -- Addr_Bit            <= '0';                 -- '1';
         -- Addr_Phase          <= '1';                 -- '1';
         -- --------------------                        -- 
         -- CMD_Mode_1          <= '0';                 -- '0'
         -- CMD_Mode_0          <= '0';                 -- '0';

          ---------------------------------------------------------------------
          -- RECEIVE_DATA_STROBE_PROCESS : Strobe data from shift register to receive
          --                               data register
          --------------------------------
          -- For a SCK ratio of 2 the Done needs to be delayed by an extra cycle
          -- due to the serial input being captured on the falling edge of the PLB
          -- clock. this is purely required for dealing with the real SPI slave memories.
            --RECEIVE_DATA_NM_GEN: if C_SPI_MEMORY = 2 and C_SPI_MODE /=0 generate
            --begin
            -----
            RECEIVE_DATA_STROBE_PROCESS: process(EXT_SPI_CLK)
            -----
            begin
            -----
                if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                   if(load_axi_data_to_spi_clk = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
                           receive_Data_int  <= (others => '0');
              elsif(SPIXfer_done_int_pulse = '1') then
                      receive_Data_int  <= rx_shft_reg_mode_0011;
              elsif(SPIXfer_done_int_pulse_d1 = '1') then
					  receive_Data_int <= receive_Data_int
                                         ((C_NUM_TRANSFER_BITS-3) downto 0) &
                                                                  IO1_I &  -- MISO_I - MSB first
                                                                  IO0_I ;  -- MOSI_I
                   end if;
                end if;
            end process RECEIVE_DATA_STROBE_PROCESS;
            --end generate RECEIVE_DATA_NM_GEN;
            -----------------------------------------------------------------------------
          CMD_ADDR_NM_24_BIT_GEN: if  C_SPI_MEM_ADDR_BITS = 24 generate
          begin
            -- CMD_ADDR_CNTR_P: in each SPI transaction, the firs 4 transactions are of
            --                  CMD, A0, A1, A2. Total 4 bytes need to be removed from the
            --                  calculation of total no. of pure data bytes.
            --                  the actual data from the SPI memory will be stored in the
            --                  receive FIFO only when the first 4 bytes are transferred.
            --                  below counter is for that purpose only.
            CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
            -----
            begin
            -----
             if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                 if(Rst_to_spi = '1') or (store_last_b4_wrap = '1') then
                     cmd_addr_cntr <= "000";--(others => '1');
                     cmd_addr_sent <= '0';
                 elsif(pr_state_idle = '1')then
                     cmd_addr_cntr <= "000";
                     cmd_addr_sent <= store_last_b4_wrap;
                 elsif(SPIXfer_done_int_pulse_d2 = '1')then
                     if(cmd_addr_cntr = "100")then
                         cmd_addr_sent <= '1';
                     else
                         cmd_addr_cntr <= cmd_addr_cntr + "001";
                         cmd_addr_sent <= '0';
                     end if;
                 end if;
             end if;
            end process CMD_ADDR_CNTR_P;
            ----------------------------
          end generate CMD_ADDR_NM_24_BIT_GEN;
          ------------------------------------
          CMD_ADDR_NM_32_BIT_GEN: if  C_SPI_MEM_ADDR_BITS = 32 generate
          begin
            -- CMD_ADDR_CNTR_P: in each SPI transaction, the firs 5 transactions are of
            --                  CMD, A0, A1, A2, A3. Total 5 bytes need to be removed from the
            --                  calculation of total no. of pure data bytes.
            --                  the actual data from the SPI memory will be stored in the
            --                  receive FIFO only when the first 5 bytes are transferred.
            --                  below counter is for that purpose only. This is 4 byte addessing mode of NM memory.
            CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
            -----
            begin
            -----
             if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                 if(Rst_to_spi = '1') or (store_last_b4_wrap = '1') then
                     cmd_addr_cntr <= "000";--(others => '1');
                     cmd_addr_sent <= '0';
                 elsif(pr_state_idle = '1')then
                     cmd_addr_cntr <= "000";
                     cmd_addr_sent <= store_last_b4_wrap;
                 elsif(SPIXfer_done_int_pulse_d2 = '1')then
                     if(cmd_addr_cntr = "110")then
                         cmd_addr_sent <= '1';
                     else
                         cmd_addr_cntr <= cmd_addr_cntr + "001";
                         cmd_addr_sent <= '0';
                     end if;
                 end if;
             end if;
            end process CMD_ADDR_CNTR_P;
            ----------------------------
          end generate CMD_ADDR_NM_32_BIT_GEN;
          ------------------------------------
          
          TWO_BIT_CNTR_P:process(EXT_SPI_CLK)is
          begin
          -----
          if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
              if(load_axi_data_to_spi_clk = '1') or (store_last_b4_wrap = '1') then
                  hw_wd_cntr <= (others => '0');
              elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1')then
                  hw_wd_cntr <= hw_wd_cntr + "01";
              end if;
          end if;
          end process TWO_BIT_CNTR_P;
          ----------------------------------------------
          STORE_RX_DATA_32_BIT_ADDR: if C_SPI_MEM_ADDR_BITS = 32 generate
          begin
          -----
          STORE_RX_DATA_SPI_CLK_P:process(EXT_SPI_CLK)is
          begin
          -----
          if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
              if(load_axi_data_to_spi_clk = '1') then
                  Data_To_Rx_FIFO_int <= (others => '0');
              elsif(SPIXfer_done_int_pulse_d3 = '1') and (cmd_addr_sent = '1') then
                  if(one_byte_xfer_to_spi_clk = '1') then
                     case spi_addr_i(1 downto 0) is
                          when "00" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 8) &
                                                             receive_Data_int;
                          when "01" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 16)&
                                                             receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(7 downto 0);
                          when "10" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 24)&
                                                             receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(15 downto 0);
                          when "11" =>
                                      Data_To_Rx_FIFO_int <= receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(23 downto 0);
                          when others => null;
                     end case;
                  elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '0') then  -- adjustment for half word
                     if(spi_addr_i(1) = '0') then
                         Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);-- & receive_Data_int;
                         Data_To_Rx_FIFO_int(15 downto 0)  <= receive_Data_int & Data_To_Rx_FIFO_int(15 downto 8);-- & receive_Data_int;
                     else
                         Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);-- & receive_Data_int;
                         Data_To_Rx_FIFO_int(31 downto 16)<= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 24);-- & receive_Data_int;
                     end if;
                  elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '1') then  -- adjustment for half word
                     if(hw_wd_cntr = "00") then -- fill in D0
                         Data_To_Rx_FIFO_int(31 downto 8) <= Data_To_Rx_FIFO_int(31 downto 8);
                         Data_To_Rx_FIFO_int(7 downto 0)  <= receive_Data_int;
                     elsif(hw_wd_cntr = "01")then -- fill in D1
                         Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);
                         Data_To_Rx_FIFO_int(15 downto 8)  <= receive_Data_int;
                         Data_To_Rx_FIFO_int(7 downto 0) <= Data_To_Rx_FIFO_int(7 downto 0);
                     elsif(hw_wd_cntr = "10")then -- fill in D2
                         Data_To_Rx_FIFO_int(31 downto 24) <= Data_To_Rx_FIFO_int(31 downto 24);
                         Data_To_Rx_FIFO_int(23 downto 16)  <= receive_Data_int;
                         Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);
                     else
                         Data_To_Rx_FIFO_int(31 downto 24) <= receive_Data_int;
                         Data_To_Rx_FIFO_int(23 downto 0) <= Data_To_Rx_FIFO_int(23 downto 0);
                     end if;
                  else   -- adjustment for complete word
                     --Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(23 downto 0) & receive_Data_int;
                     Data_To_Rx_FIFO_int <= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 8);
                  end if;
              end if;
          end if;
          end process STORE_RX_DATA_SPI_CLK_P;
          end generate STORE_RX_DATA_32_BIT_ADDR;

          STORE_RX_DATA_24_BIT_ADDR: if C_SPI_MEM_ADDR_BITS = 24 generate
          begin
          -----
          STORE_RX_DATA_SPI_CLK_P:process(EXT_SPI_CLK)is
          begin
          -----
          if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
              if(load_axi_data_to_spi_clk = '1') then
                  Data_To_Rx_FIFO_int <= (others => '0');
              elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1') then
                  if(one_byte_xfer_to_spi_clk = '1') then
                     case spi_addr_i(1 downto 0) is
                          when "00" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 8) &
                                                             receive_Data_int;
                          when "01" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 16)&
                                                             receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(7 downto 0);
                          when "10" =>
                                      Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 24)&
                                                             receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(15 downto 0);
                          when "11" =>
                                      Data_To_Rx_FIFO_int <= receive_Data_int                 &
                                                             Data_To_Rx_FIFO_int(23 downto 0);
                          when others => null;
                     end case;
                  elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '0') then  -- adjustment for half word
                     if(spi_addr_i(1) = '0') then
                         Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);-- & receive_Data_int;
                         Data_To_Rx_FIFO_int(15 downto 0)  <= receive_Data_int & Data_To_Rx_FIFO_int(15 downto 8);-- & receive_Data_int;
                     else
                         Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);-- & receive_Data_int;
                         Data_To_Rx_FIFO_int(31 downto 16)<= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 24);-- & receive_Data_int;
                     end if;
                  elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '1') then  -- adjustment for half word
                     if(hw_wd_cntr = "00") then -- fill in D0
                         Data_To_Rx_FIFO_int(31 downto 8) <= Data_To_Rx_FIFO_int(31 downto 8);
                         Data_To_Rx_FIFO_int(7 downto 0)  <= receive_Data_int;
                     elsif(hw_wd_cntr = "01")then -- fill in D1
                         Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);
                         Data_To_Rx_FIFO_int(15 downto 8)  <= receive_Data_int;
                         Data_To_Rx_FIFO_int(7 downto 0) <= Data_To_Rx_FIFO_int(7 downto 0);
                     elsif(hw_wd_cntr = "10")then -- fill in D2
                         Data_To_Rx_FIFO_int(31 downto 24) <= Data_To_Rx_FIFO_int(31 downto 24);
                         Data_To_Rx_FIFO_int(23 downto 16)  <= receive_Data_int;
                         Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);
                     else
                         Data_To_Rx_FIFO_int(31 downto 24) <= receive_Data_int;
                         Data_To_Rx_FIFO_int(23 downto 0) <= Data_To_Rx_FIFO_int(23 downto 0);
                     end if;
                  else   -- adjustment for complete word
                     --Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(23 downto 0) & receive_Data_int;
                     Data_To_Rx_FIFO_int <= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 8);
                  end if;
              end if;
          end if;
          end process STORE_RX_DATA_SPI_CLK_P;
          end generate STORE_RX_DATA_24_BIT_ADDR;

        ----------------------------
        Data_To_Rx_FIFO <= Data_To_Rx_FIFO_int;
        ---------------------------------------
        end generate SP_MEM_DUAL_MD_GEN;

end generate DUAL_MODE_CONTROL_GEN;

QUAD_MODE_CONTROL_GEN: if C_SPI_MODE = 2 generate
-----
begin
-----
-- WB 0011 0101 00 0<-cmd error
-- NM 001100101 00 0<-cmd error
     WB_MEM_QUAD_MD_GEN:if C_SPI_MEMORY = 1 generate
     signal cmd_addr_cntr   : std_logic_vector(2 downto 0);
     signal hw_wd_cntr : std_logic_vector(1 downto 0);
     -----
     begin
     -----
        wb_wr_hpm_CMD <= "10100011"; -- 0xA3 h HPM mode
        --
        ----------------------------------------------------
        WB_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
        -----
        begin
        -----
            if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                if(Rst_to_spi = RESET_ACTIVE) then
                    wb_cntrl_ps        <= WB_IDLE;
                    hpm_under_process_d1 <= '0';
                else
                    wb_cntrl_ps        <= wb_cntrl_ns;
                    hpm_under_process_d1 <= hpm_under_process;
                end if;
            end if;
        end process WB_PS_TO_NS_PROCESS;
        ----------------------------------
        --
        WB_DUAL_CNTRL_PROCESS: process(
                                       wb_cntrl_ps           ,
                                       SPIXfer_done_int_pulse,
                                       SPIXfer_done_int      ,
                                       Rst_to_spi            ,
                                       SR_5_Tx_Empty
                                       ) is
        -----
        begin
        -----
             load_wr_en_cmd <= '0';
             load_wr_sr_cmd <= '0';
             load_wr_sr_d0  <= '0';
             load_wr_sr_d1  <= '0';
             load_wr_hpm    <= '0';
             wb_hpm_done    <= '0';
             hpm_under_process <= '0';
             case wb_cntrl_ps is
                 when WB_IDLE     => load_wr_hpm <= '1';
                                     hpm_under_process <= '1';
                                     wb_cntrl_ns <= WB_WR_HPM;
                 when WB_WR_HPM   => if (SR_5_Tx_Empty = '1')then
                                         wb_hpm_done <= '1';
                                         wb_cntrl_ns <= WB_DONE;
                                     else
                                         hpm_under_process <= '1';
                                         wb_cntrl_ns <= WB_WR_HPM;
                                     end if;
                 when WB_DONE     => if (Rst_to_spi = '1') then
                                         wb_cntrl_ns <= WB_IDLE;
                                     else
                                         wb_hpm_done <= '1';
                                         wb_cntrl_ns <= WB_DONE;
                                     end if;
             end case;
        end process WB_DUAL_CNTRL_PROCESS;

     ---- Quad mode command = 0x6B - QOFR Read
     -- SPI_cmd <= "01101011";
                -- 0101 000 100 0
     ---- Quad mode command = 0xEB - QIOFR Read
     SPI_cmd <= "11101011";
                -- 0101 100 100 0  -- QUAD_IO_FAST_RD

     Data_Dir            <= '0';
     Data_Mode_1         <= '1';
     Data_Mode_0         <= '0';
     Data_Phase          <= '1';
     --------------------
     Quad_Phase          <= '0';-- permanent '0'
     --------------------
     Addr_Mode_1         <= '1';-- '0' for QOFR and '1' for QIOFR
     Addr_Mode_0         <= '0';
     Addr_Bit            <= '0';
     Addr_Phase          <= '1';
     --------------------
     CMD_Mode_1          <= '0';
     CMD_Mode_0          <= '0';

     ---------------------------------------------------------------------
     --RECEIVE_DATA_WB_GEN: if C_SPI_MEMORY = 1 and C_SPI_MODE /=0 generate
     --begin
     -----
     RECEIVE_DATA_STROBE_PROCESS: process(EXT_SPI_CLK)
     -----
     begin
     -----
         if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
            if(load_axi_data_to_spi_clk = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
                    receive_Data_int  <= (others => '0');
              elsif(SPIXfer_done_int_pulse = '1') then
                      receive_Data_int  <= rx_shft_reg_mode_0011;
              elsif(SPIXfer_done_int_pulse_d1 = '1') and (cmd_addr_sent = '1')then
					  receive_Data_int <= receive_Data_int
                                         ((C_NUM_TRANSFER_BITS-5) downto 0) &
                                                                  IO3_I &  -- MSB first
                                                                  IO2_I &
                                                                  IO1_I &
                                                                  IO0_I ;
            end if;
         end if;
     end process RECEIVE_DATA_STROBE_PROCESS;
     --end generate RECEIVE_DATA_WB_GEN;
        ---------------------------------------------------------------------
     -- CMD_ADDR_CNTR_P: in each SPI transaction, the firs 4 transactions are of
     --                  CMD, A0, A1, A2. Total 4 bytes need to be removed from the
     --                  calculation of total no. of pure data bytes.
     --                  the actual data from the SPI memory will be stored in the
     --                  receive FIFO only when the first 4 bytes are transferred.
     --                  below counter is for that purpose only.
     CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
     -----
     begin
     -----
          if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
              if(Rst_to_spi = '1') or (load_axi_data_to_spi_clk = '1') then
                  cmd_addr_cntr <= "000";--(others => '1');
                  cmd_addr_sent <= '0';
              elsif(pr_state_idle = '1')then
                  cmd_addr_cntr <= "000";
                  cmd_addr_sent <= store_last_b4_wrap;
              elsif(SPIXfer_done_int_pulse_d2 = '1')then
                  if(cmd_addr_cntr = "110")then
                      cmd_addr_sent <= '1';
                  else
                      cmd_addr_cntr <= cmd_addr_cntr + "001";
                      cmd_addr_sent <= '0';
                  end if;
              end if;
          end if;
     end process CMD_ADDR_CNTR_P;
     ----------------------------
          TWO_BIT_CNTR_P:process(EXT_SPI_CLK)is
     begin
     -----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
         if(load_axi_data_to_spi_clk = '1') or (start_after_wrap = '1') then
             hw_wd_cntr <= (others => '0');
         elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1')then
             hw_wd_cntr <= hw_wd_cntr + "01";
         end if;
     end if;
     end process TWO_BIT_CNTR_P;

     STORE_RX_DATA_SPI_CLK_P:process(EXT_SPI_CLK)is
     begin
     -----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
         if(load_axi_data_to_spi_clk = '1') then
             Data_To_Rx_FIFO_int <= (others => '0');
         elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1') then
             if(one_byte_xfer_to_spi_clk = '1') then
                case spi_addr_i(1 downto 0) is
                     when "00" =>
                                 Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 8) &
                                                        receive_Data_int;
                     when "01" =>
                                 Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 16)&
                                                        receive_Data_int                 &
                                                        Data_To_Rx_FIFO_int(7 downto 0);
                     when "10" =>
                                 Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 24)&
                                                        receive_Data_int                 &
                                                        Data_To_Rx_FIFO_int(15 downto 0);
                     when "11" =>
                                 Data_To_Rx_FIFO_int <= receive_Data_int                 &
                                                        Data_To_Rx_FIFO_int(23 downto 0);
                     when others => null;
                end case;
             elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '0') then  -- adjustment for half word
                if(spi_addr_i(1) = '0') then
                    Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);-- & receive_Data_int;
                    Data_To_Rx_FIFO_int(15 downto 0)  <= receive_Data_int & Data_To_Rx_FIFO_int(15 downto 8);-- & receive_Data_int;
                else
                    Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);-- & receive_Data_int;
                    Data_To_Rx_FIFO_int(31 downto 16)<= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 24);-- & receive_Data_int;
                end if;
             elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '1') then  -- adjustment for half word
                if(hw_wd_cntr = "00") then -- fill in D0
                    Data_To_Rx_FIFO_int(31 downto 8) <= Data_To_Rx_FIFO_int(31 downto 8);
                    Data_To_Rx_FIFO_int(7 downto 0)  <= receive_Data_int;
                elsif(hw_wd_cntr = "01")then -- fill in D1
                    Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);
                    Data_To_Rx_FIFO_int(15 downto 8)  <= receive_Data_int;
                    Data_To_Rx_FIFO_int(7 downto 0) <= Data_To_Rx_FIFO_int(7 downto 0);
                elsif(hw_wd_cntr = "10")then -- fill in D2
                    Data_To_Rx_FIFO_int(31 downto 24) <= Data_To_Rx_FIFO_int(31 downto 24);
                    Data_To_Rx_FIFO_int(23 downto 16)  <= receive_Data_int;
                    Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);
                else
                    Data_To_Rx_FIFO_int(31 downto 24) <= receive_Data_int;
                    Data_To_Rx_FIFO_int(23 downto 0) <= Data_To_Rx_FIFO_int(23 downto 0);
                end if;
             else   -- adjustment for complete word
                --Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(23 downto 0) & receive_Data_int;
                Data_To_Rx_FIFO_int <= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 8);
             end if;
         end if;
        end if;
        end process STORE_RX_DATA_SPI_CLK_P;
        ----------------------------
        Data_To_Rx_FIFO <= Data_To_Rx_FIFO_int;
        ---------------------------------------

     ----------------------------

     end generate WB_MEM_QUAD_MD_GEN;
     -- NM 0011 0 0101 00 0<-cmd error

     NM_MEM_QUAD_MD_GEN:if C_SPI_MEMORY = 2 generate
     signal cmd_addr_cntr   : std_logic_vector(3 downto 0);
     signal hw_wd_cntr : std_logic_vector(1 downto 0);
     begin
     -----
       --wb_hpm_done    <= '1';
----   Quad mode command = 0x6B - QOFR Read - 0xEBh
       --SPI_cmd <= --  "01101011";
                  -- 0101 1 000100 0
       QUAD_SPI_CMD_NM_24_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
       begin
           SPI_cmd <= "11101011"; -- QIOFR
                  -- 0101 1 100100 0
           wb_hpm_done <= '1';
         DRIVE_CONTROL_SIG_P: process(EXT_SPI_CLK, wb_hpm_done, wr_en_done_reg) is -- wb_hpm_done, wr_en_done_reg) is
         variable temp: std_logic_vector(1 downto 0);
         begin
                temp := wb_hpm_done & wr_en_done_reg;
                if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                        case wb_hpm_done is
                            -- when "00"|"01" => -- write enable is under process
                            when '0'       => -- write enable and/or Enable 4 byte addressing is under process
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '0';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- when "01"   => -- Enable 4 byte addressing is under process
                            --                Data_Dir            <= '0';                  
                            --                Data_Mode_1         <= '0';                  
                            --                Data_Mode_0         <= '0';                  
                            --                Data_Phase          <= '0';                  
                            --                --------------------                         
                            --                Quad_Phase          <= '0';-- permanent '0'  
                            --                --------------------                         
                            --                Addr_Mode_1         <= '0';                  
                            --                Addr_Mode_0         <= '0';                  
                            --                Addr_Bit            <= '0';                  
                            --                Addr_Phase          <= '0';                  
                            --                --------------------                         
                            --                CMD_Mode_1          <= '0';                  
                            --                CMD_Mode_0          <= '0';                  
                            -- when "10"   => -- write enable is done and enable 4 byte addressing is also done
                            when '1'       => -- write enable and enable 4 byte addressing is also done
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '1';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '1';                  
                                           --------------------                         
                                           Quad_Phase          <= '1';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '1';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '1';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- coverage off
                            when others => 
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '0';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- coverage on
                        end case;
                end if;
         end process DRIVE_CONTROL_SIG_P;
         --------------------------------

       end generate QUAD_SPI_CMD_NM_24_GEN;
       
       QUAD_SPI_CMD_NM_32_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
       begin
           SPI_cmd <= "11101100"; -- QIOFR_4Byte 0xECh
                  -- 0101 1 100100 0
       end generate QUAD_SPI_CMD_NM_32_GEN;

       NM_EN_32_ADDR_MD_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
       begin
       -----
          nm_wr_en_CMD         <= "00000110"; -- 0x06 h Write Enable
          nm_4byte_addr_en_CMD <= "10110111"; -- 0xB7 h Enable 4 Byte Addressing Mode
          ----------------------------------------------------
          NM_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
          -----
          begin
          -----
              if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                  if(Rst_to_spi = RESET_ACTIVE) then
                      nm_wr_en_cntrl_ps      <= NM_WR_EN_IDLE;
                      wr_en_under_process_d1 <= '0';
                wr_en_done_reg         <= '0';
                  else
                      nm_wr_en_cntrl_ps      <= nm_wr_en_cntrl_ns;
                      wr_en_under_process_d1 <= wr_en_under_process;
                wr_en_done_reg         <= wr_en_done;
       
                  end if;
              end if;
          end process NM_PS_TO_NS_PROCESS;
          ----------------------------------
          --
          NM_WR_EN_CNTRL_PROCESS: process(
                                         nm_wr_en_cntrl_ps     ,
                                         --SPIXfer_done_int_pulse,
                                         --SPIXfer_done_int      ,
                                         Rst_to_spi            ,
                                         SR_5_Tx_Empty         ,
                                   wr_en_done_reg
                                         ) is
          -----
          begin
          -----
               --load_wr_en_cmd <= '0';
               --load_wr_sr_cmd <= '0';
               --load_wr_sr_d0  <= '0';
               --load_wr_sr_d1  <= '0';
               load_wr_en    <= '0';
               wr_en_done    <= '0';
               wr_en_under_process <= '0';
               case nm_wr_en_cntrl_ps is
                   when NM_WR_EN_IDLE => --load_wr_en_cmd <= '1';
                                       load_wr_en          <= '1';
                                       wr_en_under_process <= '1';
                                       nm_wr_en_cntrl_ns   <= NM_WR_EN;
                   when NM_WR_EN      => if (SR_5_Tx_Empty = '1')then
                                             --wr_en_done <= '1';
                                             nm_wr_en_cntrl_ns <= NM_WR_EN_DONE;
                                         else
                                             --wr_en_under_process <= '1';
                                             nm_wr_en_cntrl_ns <= NM_WR_EN;
                                         end if;
                                         wr_en_done          <= SR_5_Tx_Empty;
                                         wr_en_under_process <= not SR_5_Tx_Empty;
       
                   when NM_WR_EN_DONE => if (Rst_to_spi = '1') then
                                             nm_wr_en_cntrl_ns <= NM_WR_EN_IDLE;
                                         else
                                             nm_wr_en_cntrl_ns <= NM_WR_EN_DONE;
                                         end if;
                                         wr_en_done <= wr_en_done_reg;
               end case;
          end process NM_WR_EN_CNTRL_PROCESS;
       
            ----------------------------------------------------
            NM_4_BYTE_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
            -----
            begin
            -----
                if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                    if(Rst_to_spi = RESET_ACTIVE) then
                        nm_sm_4_byte_addr_ps           <= NM_32_BIT_IDLE;
                        --four_byte_addr_under_process_d1 <= '0';
                  hpm_under_process_d1   <= '0';
                  wr_en_done_d1          <= '0';
                  wr_en_done_d2          <= '0';
                  wb_hpm_done_reg        <= '0';
                    else
                        nm_sm_4_byte_addr_ps   <= nm_sm_4_byte_addr_ns;
                        hpm_under_process_d1   <= hpm_under_process;
                        --four_byte_en_done_reg           <= four_byte_en_done;   
                  wr_en_done_d1          <= wr_en_done_reg; -- wr_en_done;
                  wr_en_done_d2          <= wr_en_done_d1;
                  wb_hpm_done_reg        <= wb_hpm_done;
                    end if;
                end if;
            end process NM_4_BYTE_PS_TO_NS_PROCESS;
            ----------------------------------
            --
            NM_4_BYTE_ADDR_EN_PROCESS: process(
                                               nm_sm_4_byte_addr_ps  ,
                                               Rst_to_spi            ,
                                               SR_5_Tx_Empty         ,
                                               wr_en_done_d2         ,
                                         wb_hpm_done_reg
                                              ) is
            -----
            begin
            -----
                 -- load_4_byte_addr_en     <= '0';
           load_wr_hpm <= '0';
                 wb_hpm_done <= '0';
           hpm_under_process <= '0';
                 four_byte_en_done          <= '0';
                 four_byte_en_under_process <= '0';
                 case nm_sm_4_byte_addr_ps is
                     when NM_32_BIT_IDLE     => if (wr_en_done_d2 = '1') then
                                              --load_wr_hpm <= '1';
                                              --hpm_under_process <= '1';
                                                    nm_sm_4_byte_addr_ns      <= NM_32_BIT_EN;
                                                else
                                                    nm_sm_4_byte_addr_ns      <= NM_32_BIT_IDLE;
                                                end if;
                                          load_wr_hpm       <= wr_en_done_d2; 
                                          hpm_under_process <= wr_en_done_d2;
            
                     when NM_32_BIT_EN      => if (SR_5_Tx_Empty = '1') then
                                             -- wb_hpm_done        <= '1';
                                             nm_sm_4_byte_addr_ns <= NM_32_BIT_EN_DONE;
                                         else
                                             -- hpm_under_process  <= '1';
                                                   nm_sm_4_byte_addr_ns <= NM_32_BIT_EN;
                                         end if;
                                               wb_hpm_done        <= SR_5_Tx_Empty;
                                         hpm_under_process  <= not(SR_5_Tx_Empty);
               when NM_32_BIT_EN_DONE => if(Rst_to_spi = '1')then
                                                   nm_sm_4_byte_addr_ns <= NM_32_BIT_IDLE;
                                               else
                                                 --  if (SR_5_Tx_Empty = '1')then
                                                 --      --four_byte_en_done          <= '1';
                                           --      wb_hpm_done <= '1';
                                                 --  else
                                                 --      -- four_byte_en_under_process <= '1';
                                           --      hpm_under_process <= '1';
                                                 --  end if;
                                                 --  four_byte_en_done     <= four_byte_en_done_reg;     
                                                   -- wb_hpm_done <= '1';
                                             nm_sm_4_byte_addr_ns <= NM_32_BIT_EN_DONE;
                                               end if;
                                               wb_hpm_done <= wb_hpm_done_reg;
            
                 end case;
            end process NM_4_BYTE_ADDR_EN_PROCESS;
            --------------------------------------
         DRIVE_CONTROL_SIG_P: process(EXT_SPI_CLK, wb_hpm_done, wr_en_done_reg) is -- wb_hpm_done, wr_en_done_reg) is
         variable temp: std_logic_vector(1 downto 0);
         begin
                temp := wb_hpm_done & wr_en_done_reg;
                if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                        case wb_hpm_done is
                            -- when "00"|"01" => -- write enable is under process
                            when '0'       => -- write enable and/or Enable 4 byte addressing is under process
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '0';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- when "01"   => -- Enable 4 byte addressing is under process
                            --                Data_Dir            <= '0';                  
                            --                Data_Mode_1         <= '0';                  
                            --                Data_Mode_0         <= '0';                  
                            --                Data_Phase          <= '0';                  
                            --                --------------------                         
                            --                Quad_Phase          <= '0';-- permanent '0'  
                            --                --------------------                         
                            --                Addr_Mode_1         <= '0';                  
                            --                Addr_Mode_0         <= '0';                  
                            --                Addr_Bit            <= '0';                  
                            --                Addr_Phase          <= '0';                  
                            --                --------------------                         
                            --                CMD_Mode_1          <= '0';                  
                            --                CMD_Mode_0          <= '0';                  
                            -- when "10"   => -- write enable is done and enable 4 byte addressing is also done
                            when '1'       => -- write enable and enable 4 byte addressing is also done
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '1';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '1';                  
                                           --------------------                         
                                           Quad_Phase          <= '1';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '1';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '1';                  
                                           Addr_Phase          <= '1';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- coverage off
                            when others => 
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '0';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- coverage on
                        end case;
                end if;
         end process DRIVE_CONTROL_SIG_P;
         --------------------------------
       end generate NM_EN_32_ADDR_MD_GEN;
       -------------------------------------
       -- Data_Dir            <= '0';
       -- Data_Mode_1         <= '1';
       -- Data_Mode_0         <= '0';
       -- Data_Phase          <= '1';
       -- --------------------
       -- Quad_Phase          <= '1';-- for NM this is 0
       -- --------------------
       -- Addr_Mode_1         <= '1';
       -- Addr_Mode_0         <= '0';
       -- Addr_Bit            <= '0';
       -- Addr_Phase          <= '1';
       -- --------------------
       -- CMD_Mode_1          <= '0';
       -- CMD_Mode_0          <= '0';
       
       ---------------------------------------------------------------------
       -- RECEIVE_DATA_STROBE_PROCESS : Strobe data from shift register to receive
       --                               data register
       --------------------------------
       -- For a SCK ratio of 2 the Done needs to be delayed by an extra cycle
       -- due to the serial input being captured on the falling edge of the PLB
       -- clock. this is purely required for dealing with the real SPI slave memories.
         --RECEIVE_DATA_NM_GEN: if C_SPI_MEMORY = 2 and C_SPI_MODE /=0 generate
         --begin
         -----
         RECEIVE_DATA_STROBE_PROCESS: process(EXT_SPI_CLK)
         -----
         begin
         -----
             if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                if(load_axi_data_to_spi_clk = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
                        receive_Data_int  <= (others => '0');
              elsif(SPIXfer_done_int_pulse = '1') then
                      receive_Data_int  <= rx_shft_reg_mode_0011;
              elsif(SPIXfer_done_int_pulse_d1 = '1') then
					  receive_Data_int <= receive_Data_int
                                         ((C_NUM_TRANSFER_BITS-5) downto 0) &
                                                                  IO3_I &  -- MSB first
                                                                  IO2_I &
                                                                  IO1_I &
                                                                  IO0_I ;
                end if;
             end if;
         end process RECEIVE_DATA_STROBE_PROCESS;
         --end generate RECEIVE_DATA_NM_GEN;
       -----------------------------------------------------------------------------
       CMD_ADDR_NM_24_BIT_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
       begin
         -- CMD_ADDR_CNTR_P: in each SPI transaction, the firs 5 transactions are of
         --                  CMD, A0, A1, A2. Total 4 bytes need to be removed from the
         --                  calculation of total no. of pure data bytes.
         --                  the actual data from the SPI memory will be stored in the
         --                  receive FIFO only when the first 4 bytes are transferred.
         --                  below counter is for that purpose only. This is for 24 bit addressing of NM memories only.
         CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
         -----
         begin
         -----
              if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                  if(Rst_to_spi = '1')               or
                    (load_axi_data_to_spi_clk = '1') or
                    (store_last_b4_wrap = '1') then
                      cmd_addr_cntr <= "0000";--(others => '1');
                      cmd_addr_sent <= '0';
                  elsif(pr_state_idle = '1')then
                      cmd_addr_cntr <= "0000";
                      cmd_addr_sent <= store_last_b4_wrap;
                  elsif(SPIXfer_done_int_pulse_d2 = '1')then
                      if(cmd_addr_cntr = "1000")then
                          cmd_addr_sent <= '1';
                      else
                          cmd_addr_cntr <= cmd_addr_cntr + "0001";
                          cmd_addr_sent <= '0';
                      end if;
                  end if;
              end if;
         end process CMD_ADDR_CNTR_P;
       end generate CMD_ADDR_NM_24_BIT_GEN;
       ------------------------------------
       CMD_ADDR_NM_32_BIT_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
       begin
         -- CMD_ADDR_CNTR_P: in each SPI transaction, the firs 6 transactions are of
         --                  CMD, A0, A1, A2, A3. Total 5 bytes need to be removed from the
         --                  calculation of total no. of pure data bytes.
         --                  the actual data from the SPI memory will be stored in the
         --                  receive FIFO only when the first 5 bytes are transferred.
         --                  below counter is for that purpose only. This is for 32 bit addressing of NM memories only.
         CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
         -----
         begin
         -----
              if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                  if(Rst_to_spi = '1')               or
                    (load_axi_data_to_spi_clk = '1') or
                    (store_last_b4_wrap = '1') then
                      cmd_addr_cntr <= "0000";--(others => '1');
                      cmd_addr_sent <= '0';
                  elsif(pr_state_idle = '1')then
                      cmd_addr_cntr <= "0000";
                      cmd_addr_sent <= store_last_b4_wrap;
                  elsif(SPIXfer_done_int_pulse_d2 = '1')then
                      if(cmd_addr_cntr = "1001")then -- note the differene in counter value
                          cmd_addr_sent <= '1';
                      else
                          cmd_addr_cntr <= cmd_addr_cntr + "0001";
                          cmd_addr_sent <= '0';
                      end if;
                  end if;
              end if;
         end process CMD_ADDR_CNTR_P;
       end generate CMD_ADDR_NM_32_BIT_GEN;
       ------------------------------------
       TWO_BIT_CNTR_P:process(EXT_SPI_CLK)is
       begin
       -----
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
           if(load_axi_data_to_spi_clk = '1') or (start_after_wrap = '1') then
               hw_wd_cntr <= (others => '0');
           elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1')then
               hw_wd_cntr <= hw_wd_cntr + "01";
           end if;
       end if;
       end process TWO_BIT_CNTR_P;
       ---------------------------       
       STORE_RX_DATA_SPI_CLK_P:process(EXT_SPI_CLK)is
       begin
       -----
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
           if(load_axi_data_to_spi_clk = '1') then
               Data_To_Rx_FIFO_int <= (others => '0');
           elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1') then
               if(one_byte_xfer_to_spi_clk = '1') then
                  case spi_addr_i(1 downto 0) is
                       when "00" =>
                                   Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 8) &
                                                          receive_Data_int;
                       when "01" =>
                                   Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 16)&
                                                          receive_Data_int                 &
                                                          Data_To_Rx_FIFO_int(7 downto 0);
                       when "10" =>
                                   Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 24)&
                                                          receive_Data_int                 &
                                                          Data_To_Rx_FIFO_int(15 downto 0);
                       when "11" =>
                                   Data_To_Rx_FIFO_int <= receive_Data_int                 &
                                                          Data_To_Rx_FIFO_int(23 downto 0);
                       when others => null;
                  end case;
               elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '0') then  -- adjustment for half word
                  if(spi_addr_i(1) = '0') then
                      Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);-- & receive_Data_int;
                      Data_To_Rx_FIFO_int(15 downto 0)  <= receive_Data_int & Data_To_Rx_FIFO_int(15 downto 8);-- & receive_Data_int;
                  else
                      Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);-- & receive_Data_int;
                      Data_To_Rx_FIFO_int(31 downto 16)<= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 24);-- & receive_Data_int;
                  end if;
               elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '1') then  -- adjustment for half word
                  if(hw_wd_cntr = "00") then -- fill in D0
                      Data_To_Rx_FIFO_int(31 downto 8) <= Data_To_Rx_FIFO_int(31 downto 8);
                      Data_To_Rx_FIFO_int(7 downto 0)  <= receive_Data_int;
                  elsif(hw_wd_cntr = "01")then -- fill in D1
                      Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);
                      Data_To_Rx_FIFO_int(15 downto 8)  <= receive_Data_int;
                      Data_To_Rx_FIFO_int(7 downto 0) <= Data_To_Rx_FIFO_int(7 downto 0);
                  elsif(hw_wd_cntr = "10")then -- fill in D2
                      Data_To_Rx_FIFO_int(31 downto 24) <= Data_To_Rx_FIFO_int(31 downto 24);
                      Data_To_Rx_FIFO_int(23 downto 16)  <= receive_Data_int;
                      Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);
                  else
                      Data_To_Rx_FIFO_int(31 downto 24) <= receive_Data_int;
                      Data_To_Rx_FIFO_int(23 downto 0) <= Data_To_Rx_FIFO_int(23 downto 0);
                  end if;
               else   -- adjustment for complete word
                  --Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(23 downto 0) & receive_Data_int;
                  Data_To_Rx_FIFO_int <= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 8);
               end if;
           end if;
          end if;
          end process STORE_RX_DATA_SPI_CLK_P;
          ----------------------------
          Data_To_Rx_FIFO <= Data_To_Rx_FIFO_int;
          ---------------------------------------

     --------------------------------
     end generate NM_MEM_QUAD_MD_GEN;
 
    --------------------------------
	     SP_MEM_QUAD_MD_GEN:if C_SPI_MEMORY = 3 generate
     signal cmd_addr_cntr   : std_logic_vector(3 downto 0);
     signal hw_wd_cntr : std_logic_vector(1 downto 0);
     begin
     -----
       --wb_hpm_done    <= '1';
----   Quad mode command = 0x6B - QOFR Read - 0xEBh
       --SPI_cmd <= --  "01101011";
                  -- 0101 1 000100 0
       QUAD_SPI_CMD_NM_24_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
       begin
           SPI_cmd <= "11101011"; -- QIOFR
                  -- 0101 1 100100 0
           wb_hpm_done <= '1';
         DRIVE_CONTROL_SIG_P: process(EXT_SPI_CLK) is -- wb_hpm_done, wr_en_done_reg) is
         variable temp: std_logic_vector(1 downto 0);
         begin
                temp := wb_hpm_done & wr_en_done_reg;
                if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                        case wb_hpm_done is
                            -- when "00"|"01" => -- write enable is under process
                            when '0'       => -- write enable and/or Enable 4 byte addressing is under process
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '0';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- when "01"   => -- Enable 4 byte addressing is under process
                            --                Data_Dir            <= '0';                  
                            --                Data_Mode_1         <= '0';                  
                            --                Data_Mode_0         <= '0';                  
                            --                Data_Phase          <= '0';                  
                            --                --------------------                         
                            --                Quad_Phase          <= '0';-- permanent '0'  
                            --                --------------------                         
                            --                Addr_Mode_1         <= '0';                  
                            --                Addr_Mode_0         <= '0';                  
                            --                Addr_Bit            <= '0';                  
                            --                Addr_Phase          <= '0';                  
                            --                --------------------                         
                            --                CMD_Mode_1          <= '0';                  
                            --                CMD_Mode_0          <= '0';                  
                            -- when "10"   => -- write enable is done and enable 4 byte addressing is also done
                            when '1'       => -- write enable and enable 4 byte addressing is also done
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '1';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '1';                  
                                           --------------------                         
                                           Quad_Phase          <= '1';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '1';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '1';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- coverage off
                            when others => 
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '0';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- coverage on
                        end case;
                end if;
         end process DRIVE_CONTROL_SIG_P;
         --------------------------------

       end generate QUAD_SPI_CMD_NM_24_GEN;
       
       QUAD_SPI_CMD_NM_32_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
       begin
           SPI_cmd <= "11101100"; -- QIOFR_4Byte 0xECh
                  -- 0101 1 100100 0
       end generate QUAD_SPI_CMD_NM_32_GEN;

       NM_EN_32_ADDR_MD_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
       begin
       -----
          nm_wr_en_CMD         <= "00000110"; -- 0x06 h Write Enable
          nm_4byte_addr_en_CMD <= "10110111"; -- 0xB7 h Enable 4 Byte Addressing Mode
          ----------------------------------------------------
          NM_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
          -----
          begin
          -----
              if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                  if(Rst_to_spi = RESET_ACTIVE) then
                      nm_wr_en_cntrl_ps      <= NM_WR_EN_IDLE;
                      wr_en_under_process_d1 <= '0';
                wr_en_done_reg         <= '0';
                  else
                      nm_wr_en_cntrl_ps      <= nm_wr_en_cntrl_ns;
                      wr_en_under_process_d1 <= wr_en_under_process;
                wr_en_done_reg         <= wr_en_done;
       
                  end if;
              end if;
          end process NM_PS_TO_NS_PROCESS;
          ----------------------------------
          --
          NM_WR_EN_CNTRL_PROCESS: process(
                                         nm_wr_en_cntrl_ps     ,
                                         --SPIXfer_done_int_pulse,
                                         --SPIXfer_done_int      ,
                                         Rst_to_spi            ,
                                         SR_5_Tx_Empty         ,
                                   wr_en_done_reg
                                         ) is
          -----
          begin
          -----
               --load_wr_en_cmd <= '0';
               --load_wr_sr_cmd <= '0';
               --load_wr_sr_d0  <= '0';
               --load_wr_sr_d1  <= '0';
               load_wr_en    <= '0';
               wr_en_done    <= '0';
               wr_en_under_process <= '0';
               case nm_wr_en_cntrl_ps is
                   when NM_WR_EN_IDLE => --load_wr_en_cmd <= '1';
                                       load_wr_en          <= '1';
                                       wr_en_under_process <= '1';
                                       nm_wr_en_cntrl_ns   <= NM_WR_EN;
                   when NM_WR_EN      => if (SR_5_Tx_Empty = '1')then
                                             --wr_en_done <= '1';
                                             nm_wr_en_cntrl_ns <= NM_WR_EN_DONE;
                                         else
                                             --wr_en_under_process <= '1';
                                             nm_wr_en_cntrl_ns <= NM_WR_EN;
                                         end if;
                                         wr_en_done          <= SR_5_Tx_Empty;
                                         wr_en_under_process <= not SR_5_Tx_Empty;
       
                   when NM_WR_EN_DONE => if (Rst_to_spi = '1') then
                                             nm_wr_en_cntrl_ns <= NM_WR_EN_IDLE;
                                         else
                                             nm_wr_en_cntrl_ns <= NM_WR_EN_DONE;
                                         end if;
                                         wr_en_done <= wr_en_done_reg;
               end case;
          end process NM_WR_EN_CNTRL_PROCESS;
       
            ----------------------------------------------------
            NM_4_BYTE_PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
            -----
            begin
            -----
                if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                    if(Rst_to_spi = RESET_ACTIVE) then
                        nm_sm_4_byte_addr_ps           <= NM_32_BIT_IDLE;
                        --four_byte_addr_under_process_d1 <= '0';
                  hpm_under_process_d1   <= '0';
                  wr_en_done_d1          <= '0';
                  wr_en_done_d2          <= '0';
                  wb_hpm_done_reg        <= '0';
                    else
                        nm_sm_4_byte_addr_ps   <= nm_sm_4_byte_addr_ns;
                        hpm_under_process_d1   <= hpm_under_process;
                        --four_byte_en_done_reg           <= four_byte_en_done;   
                  wr_en_done_d1          <= wr_en_done_reg; -- wr_en_done;
                  wr_en_done_d2          <= wr_en_done_d1;
                  wb_hpm_done_reg        <= wb_hpm_done;
                    end if;
                end if;
            end process NM_4_BYTE_PS_TO_NS_PROCESS;
            ----------------------------------
            --
            NM_4_BYTE_ADDR_EN_PROCESS: process(
                                               nm_sm_4_byte_addr_ps  ,
                                               Rst_to_spi            ,
                                               SR_5_Tx_Empty         ,
                                               wr_en_done_d2         ,
                                         wb_hpm_done_reg
                                              ) is
            -----
            begin
            -----
                 -- load_4_byte_addr_en     <= '0';
           load_wr_hpm <= '0';
                 wb_hpm_done <= '0';
           hpm_under_process <= '0';
                 four_byte_en_done          <= '0';
                 four_byte_en_under_process <= '0';
                 case nm_sm_4_byte_addr_ps is
                     when NM_32_BIT_IDLE     => if (wr_en_done_d2 = '1') then
                                              --load_wr_hpm <= '1';
                                              --hpm_under_process <= '1';
                                                    nm_sm_4_byte_addr_ns      <= NM_32_BIT_EN;
                                                else
                                                    nm_sm_4_byte_addr_ns      <= NM_32_BIT_IDLE;
                                                end if;
                                          load_wr_hpm       <= wr_en_done_d2; 
                                          hpm_under_process <= wr_en_done_d2;
            
                     when NM_32_BIT_EN      => if (SR_5_Tx_Empty = '1') then
                                             -- wb_hpm_done        <= '1';
                                             nm_sm_4_byte_addr_ns <= NM_32_BIT_EN_DONE;
                                         else
                                             -- hpm_under_process  <= '1';
                                                   nm_sm_4_byte_addr_ns <= NM_32_BIT_EN;
                                         end if;
                                               wb_hpm_done        <= SR_5_Tx_Empty;
                                         hpm_under_process  <= not(SR_5_Tx_Empty);
               when NM_32_BIT_EN_DONE => if(Rst_to_spi = '1')then
                                                   nm_sm_4_byte_addr_ns <= NM_32_BIT_IDLE;
                                               else
                                                 --  if (SR_5_Tx_Empty = '1')then
                                                 --      --four_byte_en_done          <= '1';
                                           --      wb_hpm_done <= '1';
                                                 --  else
                                                 --      -- four_byte_en_under_process <= '1';
                                           --      hpm_under_process <= '1';
                                                 --  end if;
                                                 --  four_byte_en_done     <= four_byte_en_done_reg;     
                                                   -- wb_hpm_done <= '1';
                                             nm_sm_4_byte_addr_ns <= NM_32_BIT_EN_DONE;
                                               end if;
                                               wb_hpm_done <= wb_hpm_done_reg;
            
                 end case;
            end process NM_4_BYTE_ADDR_EN_PROCESS;
            --------------------------------------
         DRIVE_CONTROL_SIG_P: process(EXT_SPI_CLK) is -- wb_hpm_done, wr_en_done_reg) is
         variable temp: std_logic_vector(1 downto 0);
         begin
                temp := wb_hpm_done & wr_en_done_reg;
                if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                        case wb_hpm_done is
                            -- when "00"|"01" => -- write enable is under process
                            when '0'       => -- write enable and/or Enable 4 byte addressing is under process
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '0';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- when "01"   => -- Enable 4 byte addressing is under process
                            --                Data_Dir            <= '0';                  
                            --                Data_Mode_1         <= '0';                  
                            --                Data_Mode_0         <= '0';                  
                            --                Data_Phase          <= '0';                  
                            --                --------------------                         
                            --                Quad_Phase          <= '0';-- permanent '0'  
                            --                --------------------                         
                            --                Addr_Mode_1         <= '0';                  
                            --                Addr_Mode_0         <= '0';                  
                            --                Addr_Bit            <= '0';                  
                            --                Addr_Phase          <= '0';                  
                            --                --------------------                         
                            --                CMD_Mode_1          <= '0';                  
                            --                CMD_Mode_0          <= '0';                  
                            -- when "10"   => -- write enable is done and enable 4 byte addressing is also done
                            when '1'       => -- write enable and enable 4 byte addressing is also done
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '1';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '1';                  
                                           --------------------                         
                                           Quad_Phase          <= '1';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '1';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '1';                  
                                           Addr_Phase          <= '1';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- coverage off
                            when others => 
                                           Data_Dir            <= '0';                  
                                           Data_Mode_1         <= '0';                  
                                           Data_Mode_0         <= '0';                  
                                           Data_Phase          <= '0';                  
                                           --------------------                         
                                           Quad_Phase          <= '0';-- permanent '0'  
                                           --------------------                         
                                           Addr_Mode_1         <= '0';                  
                                           Addr_Mode_0         <= '0';                  
                                           Addr_Bit            <= '0';                  
                                           Addr_Phase          <= '0';                  
                                           --------------------                         
                                           CMD_Mode_1          <= '0';                  
                                           CMD_Mode_0          <= '0';                  
                            -- coverage on
                        end case;
                end if;
         end process DRIVE_CONTROL_SIG_P;
         --------------------------------
       end generate NM_EN_32_ADDR_MD_GEN;
       -------------------------------------
       -- Data_Dir            <= '0';
       -- Data_Mode_1         <= '1';
       -- Data_Mode_0         <= '0';
       -- Data_Phase          <= '1';
       -- --------------------
       -- Quad_Phase          <= '1';-- for NM this is 0
       -- --------------------
       -- Addr_Mode_1         <= '1';
       -- Addr_Mode_0         <= '0';
       -- Addr_Bit            <= '0';
       -- Addr_Phase          <= '1';
       -- --------------------
       -- CMD_Mode_1          <= '0';
       -- CMD_Mode_0          <= '0';
       
       ---------------------------------------------------------------------
       -- RECEIVE_DATA_STROBE_PROCESS : Strobe data from shift register to receive
       --                               data register
       --------------------------------
       -- For a SCK ratio of 2 the Done needs to be delayed by an extra cycle
       -- due to the serial input being captured on the falling edge of the PLB
       -- clock. this is purely required for dealing with the real SPI slave memories.
         --RECEIVE_DATA_NM_GEN: if C_SPI_MEMORY = 2 and C_SPI_MODE /=0 generate
         --begin
         -----
         RECEIVE_DATA_STROBE_PROCESS: process(EXT_SPI_CLK)
         -----
         begin
         -----
             if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
                if(load_axi_data_to_spi_clk = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
                        receive_Data_int  <= (others => '0');
              elsif(SPIXfer_done_int_pulse = '1') then
                      receive_Data_int  <= rx_shft_reg_mode_0011;
              elsif(SPIXfer_done_int_pulse_d1 = '1') then
					  receive_Data_int <= receive_Data_int
                                         ((C_NUM_TRANSFER_BITS-5) downto 0) &
                                                                  IO3_I &  -- MSB first
                                                                  IO2_I &
                                                                  IO1_I &
                                                                  IO0_I ;
                end if;
             end if;
         end process RECEIVE_DATA_STROBE_PROCESS;
         --end generate RECEIVE_DATA_NM_GEN;
       -----------------------------------------------------------------------------
       CMD_ADDR_NM_24_BIT_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
       begin
         -- CMD_ADDR_CNTR_P: in each SPI transaction, the firs 5 transactions are of
         --                  CMD, A0, A1, A2. Total 4 bytes need to be removed from the
         --                  calculation of total no. of pure data bytes.
         --                  the actual data from the SPI memory will be stored in the
         --                  receive FIFO only when the first 4 bytes are transferred.
         --                  below counter is for that purpose only. This is for 24 bit addressing of NM memories only.
         CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
         -----
         begin
         -----
              if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                  if(Rst_to_spi = '1')               or
                    (load_axi_data_to_spi_clk = '1') or
                    (store_last_b4_wrap = '1') then
                      cmd_addr_cntr <= "0000";--(others => '1');
                      cmd_addr_sent <= '0';
                  elsif(pr_state_idle = '1')then
                      cmd_addr_cntr <= "0000";
                      cmd_addr_sent <= store_last_b4_wrap;
                  elsif(SPIXfer_done_int_pulse_d2 = '1')then
                      if(cmd_addr_cntr = "0110")then
                          cmd_addr_sent <= '1';
                      else
                          cmd_addr_cntr <= cmd_addr_cntr + "0001";
                          cmd_addr_sent <= '0';
                      end if;
                  end if;
              end if;
         end process CMD_ADDR_CNTR_P;
       end generate CMD_ADDR_NM_24_BIT_GEN;
       ------------------------------------
       CMD_ADDR_NM_32_BIT_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
       begin
         -- CMD_ADDR_CNTR_P: in each SPI transaction, the firs 6 transactions are of
         --                  CMD, A0, A1, A2, A3. Total 5 bytes need to be removed from the
         --                  calculation of total no. of pure data bytes.
         --                  the actual data from the SPI memory will be stored in the
         --                  receive FIFO only when the first 5 bytes are transferred.
         --                  below counter is for that purpose only. This is for 32 bit addressing of NM memories only.
         CMD_ADDR_CNTR_P:process(EXT_SPI_CLK)is
         -----
         begin
         -----
              if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
                  if(Rst_to_spi = '1')               or
                    (load_axi_data_to_spi_clk = '1') or
                    (store_last_b4_wrap = '1') then
                      cmd_addr_cntr <= "0000";--(others => '1');
                      cmd_addr_sent <= '0';
                  elsif(pr_state_idle = '1')then
                      cmd_addr_cntr <= "0000";
                      cmd_addr_sent <= store_last_b4_wrap;
                  elsif(SPIXfer_done_int_pulse_d2 = '1')then
                      if(cmd_addr_cntr = "0111")then -- note the differene in counter value
                          cmd_addr_sent <= '1';
                      else
                          cmd_addr_cntr <= cmd_addr_cntr + "0001";
                          cmd_addr_sent <= '0';
                      end if;
                  end if;
              end if;
         end process CMD_ADDR_CNTR_P;
       end generate CMD_ADDR_NM_32_BIT_GEN;
       ------------------------------------
       TWO_BIT_CNTR_P:process(EXT_SPI_CLK)is
       begin
       -----
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
           if(load_axi_data_to_spi_clk = '1') or (start_after_wrap = '1') then
               hw_wd_cntr <= (others => '0');
           elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1')then
               hw_wd_cntr <= hw_wd_cntr + "01";
           end if;
       end if;
       end process TWO_BIT_CNTR_P;
       ---------------------------       
       STORE_RX_DATA_SPI_CLK_P:process(EXT_SPI_CLK)is
       begin
       -----
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1')then
           if(load_axi_data_to_spi_clk = '1') then
               Data_To_Rx_FIFO_int <= (others => '0');
           elsif(SPIXfer_done_int_pulse_d2 = '1') and (cmd_addr_sent = '1') then
               if(one_byte_xfer_to_spi_clk = '1') then
                  case spi_addr_i(1 downto 0) is
                       when "00" =>
                                   Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 8) &
                                                          receive_Data_int;
                       when "01" =>
                                   Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 16)&
                                                          receive_Data_int                 &
                                                          Data_To_Rx_FIFO_int(7 downto 0);
                       when "10" =>
                                   Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(31 downto 24)&
                                                          receive_Data_int                 &
                                                          Data_To_Rx_FIFO_int(15 downto 0);
                       when "11" =>
                                   Data_To_Rx_FIFO_int <= receive_Data_int                 &
                                                          Data_To_Rx_FIFO_int(23 downto 0);
                       when others => null;
                  end case;
               elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '0') then  -- adjustment for half word
                  if(spi_addr_i(1) = '0') then
                      Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);-- & receive_Data_int;
                      Data_To_Rx_FIFO_int(15 downto 0)  <= receive_Data_int & Data_To_Rx_FIFO_int(15 downto 8);-- & receive_Data_int;
                  else
                      Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);-- & receive_Data_int;
                      Data_To_Rx_FIFO_int(31 downto 16)<= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 24);-- & receive_Data_int;
                  end if;
               elsif (two_byte_xfer_to_spi_clk = '1') and (type_of_burst_to_spi_clk = '1') then  -- adjustment for half word
                  if(hw_wd_cntr = "00") then -- fill in D0
                      Data_To_Rx_FIFO_int(31 downto 8) <= Data_To_Rx_FIFO_int(31 downto 8);
                      Data_To_Rx_FIFO_int(7 downto 0)  <= receive_Data_int;
                  elsif(hw_wd_cntr = "01")then -- fill in D1
                      Data_To_Rx_FIFO_int(31 downto 16) <= Data_To_Rx_FIFO_int(31 downto 16);
                      Data_To_Rx_FIFO_int(15 downto 8)  <= receive_Data_int;
                      Data_To_Rx_FIFO_int(7 downto 0) <= Data_To_Rx_FIFO_int(7 downto 0);
                  elsif(hw_wd_cntr = "10")then -- fill in D2
                      Data_To_Rx_FIFO_int(31 downto 24) <= Data_To_Rx_FIFO_int(31 downto 24);
                      Data_To_Rx_FIFO_int(23 downto 16)  <= receive_Data_int;
                      Data_To_Rx_FIFO_int(15 downto 0) <= Data_To_Rx_FIFO_int(15 downto 0);
                  else
                      Data_To_Rx_FIFO_int(31 downto 24) <= receive_Data_int;
                      Data_To_Rx_FIFO_int(23 downto 0) <= Data_To_Rx_FIFO_int(23 downto 0);
                  end if;
               else   -- adjustment for complete word
                  --Data_To_Rx_FIFO_int <= Data_To_Rx_FIFO_int(23 downto 0) & receive_Data_int;
                  Data_To_Rx_FIFO_int <= receive_Data_int & Data_To_Rx_FIFO_int(31 downto 8);
               end if;
           end if;
          end if;
          end process STORE_RX_DATA_SPI_CLK_P;
          ----------------------------
          Data_To_Rx_FIFO <= Data_To_Rx_FIFO_int;
          ---------------------------------------

     --------------------------------
     end generate SP_MEM_QUAD_MD_GEN;

end generate QUAD_MODE_CONTROL_GEN;

WRAP_DELAY_P:process(EXT_SPI_CLK)is
begin
      if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
          if(Rst_to_spi = RESET_ACTIVE) or (load_axi_data_to_spi_clk = '1') then
              wrap_around_d1 <= '0';
              wrap_around_d2 <= '0';
              wrap_around_d3 <= '0';
              --wrap_around_d4 <= '0';
          else
              wrap_around_d1 <= wrap_around;
              wrap_around_d2 <= wrap_around_d1;
              wrap_around_d3 <= wrap_around_d2;
              --wrap_around_d4 <= wrap_around_d3;
          end if;
      end if;
end process WRAP_DELAY_P;
wrap_ack         <= (not wrap_around_d2) and wrap_around_d1;
wrap_ack_1       <= (not wrap_around_d3) and wrap_around_d2;
start_after_wrap <= wrap_around_d2 and (not wrap_around_d1) and not SR_5_Tx_Empty;
store_last_b4_wrap    <= wrap_around_d3 and (not wrap_around_d2);
--xsfer_start_aftr_wrap <= wrap_around_d4 and (not wrap_around_d3);
DELAY_START_AFTR_WRAP:process(EXT_SPI_CLK)is
begin
      if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
          if(Rst_to_spi = RESET_ACTIVE) then
                start_after_wrap_d1 <= '0';
          else
                start_after_wrap_d1 <= start_after_wrap;
          end if;
      end if;
end process DELAY_START_AFTR_WRAP;
----------------------------------
TRANSFER_START_24_BIT_ADDR_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
begin
-----
TRANSFER_START_P:process(EXT_SPI_CLK)is
begin
      if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
          if(Rst_to_spi = RESET_ACTIVE) then
              transfer_start <= '0';
          elsif(wrap_around = '1') then -- and (actual_SPIXfer_done_int = '1')then
              transfer_start <= '0';
          elsif(hpm_under_process_d1 = '1' and wb_hpm_done = '1')-- or 
               --(wr_en_under_process_d1 = '1' and wr_en_done = '1')
               then
              transfer_start <= '0';
          elsif   (load_axi_data_to_spi_clk = '1') 
               or (start_after_wrap_d1 = '1')      
               or (load_wr_hpm = '1')              
               --or (load_wr_en = '1') 
               then
              transfer_start <= '1';
          elsif(SR_5_Tx_Empty_int = '1') then
              transfer_start <= '0';
          end if;
      end if;
end process TRANSFER_START_P;
end generate TRANSFER_START_24_BIT_ADDR_GEN;

TRANSFER_START_32_BIT_ADDR_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
begin
-----
TRANSFER_START_P:process(EXT_SPI_CLK)is
begin
      if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
          if(Rst_to_spi = RESET_ACTIVE) then
              transfer_start <= '0';
          elsif(wrap_around = '1') then -- and (actual_SPIXfer_done_int = '1')then
              transfer_start <= '0';
          elsif(hpm_under_process_d1 = '1' and wb_hpm_done = '1') or 
               (wr_en_under_process_d1 = '1' and wr_en_done = '1')then
              transfer_start <= '0';
          elsif(load_axi_data_to_spi_clk = '1') or
               (start_after_wrap_d1 = '1')      or
               (load_wr_hpm = '1')              or
               (load_wr_en = '1') then
              transfer_start <= '1';
          elsif(SR_5_Tx_Empty_int = '1') then
              transfer_start <= '0';
          end if;
      end if;
end process TRANSFER_START_P;
end generate TRANSFER_START_32_BIT_ADDR_GEN;

-------------------------------------------------------------------------------
-- TRANSFER_START_1CLK_PROCESS : Delay transfer start by 1 clock cycle
--------------------------------
TRANSFER_START_1CLK_PROCESS: process(EXT_SPI_CLK)is
-----
begin
-----
    if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(Rst_to_spi = RESET_ACTIVE) or (load_axi_data_to_spi_clk = '1') then
            transfer_start_d1 <= '0';
            transfer_start_d2 <= '0';
            transfer_start_d3 <= '0';
        else
            transfer_start_d1 <= transfer_start;
            transfer_start_d2 <= transfer_start_d1;
            transfer_start_d3 <= transfer_start_d2;
        end if;
    end if;
end process TRANSFER_START_1CLK_PROCESS;

transfer_start_pulse <= --transfer_start and (not transfer_start_d1);
                        --transfer_start_d2 and (not transfer_start_d3);
                        transfer_start and (not(transfer_start_d1));

    -------------------------------------------------------------------------------
    -- TRANSFER_DONE_1CLK_PROCESS : Delay SPI transfer done signal by 1 clock cycle
    -------------------------------
    TRANSFER_DONE_1CLK_PROCESS: process(EXT_SPI_CLK)is
    -----
    begin
    -----
        if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
            if(Rst_to_spi = RESET_ACTIVE) or (load_axi_data_to_spi_clk = '1') then
                SPIXfer_done_int_d1 <= '0';
            else
                SPIXfer_done_int_d1 <= SPIXfer_done_int;
            end if;
        end if;
    end process TRANSFER_DONE_1CLK_PROCESS;
    --
    -- transfer done pulse generating logic
    SPIXfer_done_int_pulse <= SPIXfer_done_int and (not(SPIXfer_done_int_d1));

    -------------------------------------------------------------------------------
    -- TRANSFER_DONE_PULSE_DLY_PROCESS : Delay SPI transfer done pulse by 1 and 2
    --                                   clock cycles
    ------------------------------------
    -- Delay the Done pulse by a further cycle. This is used as the output Rx
    -- data strobe when C_SCK_RATIO = 2
    TRANSFER_DONE_PULSE_DLY_PROCESS: process(EXT_SPI_CLK)is
    -----
    begin
    -----
        if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
            if(Rst_to_spi = RESET_ACTIVE) or (load_axi_data_to_spi_clk = '1') then
                SPIXfer_done_int_pulse_d1 <= '0';
                SPIXfer_done_int_pulse_d2 <= '0';
                SPIXfer_done_int_pulse_d3 <= '0';
            else
                SPIXfer_done_int_pulse_d1 <= SPIXfer_done_int_pulse;
                SPIXfer_done_int_pulse_d2 <= SPIXfer_done_int_pulse_d1;
                SPIXfer_done_int_pulse_d3 <= SPIXfer_done_int_pulse_d2;
            end if;
        end if;
    end process TRANSFER_DONE_PULSE_DLY_PROCESS;
--------------------------------------------
-------------------------------------------------------------------------------
-- RX_DATA_GEN1: Only for C_SCK_RATIO = 2 mode.
----------------
-- RX_DATA_SCK_RATIO_2_GEN1 : if C_SCK_RATIO = 2 generate
-----
-- begin
-----
  -------------------------------------------------------------------------------
  -- TRANSFER_DONE_PROCESS : Generate SPI transfer done signal. This will stop the SPI clock.
  --------------------------
  TRANSFER_DONE_PROCESS: process(EXT_SPI_CLK)is
  -----
  begin
  -----
      if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
          if(Rst_to_spi = RESET_ACTIVE) then
              SPIXfer_done_int <= '0';
          elsif(transfer_start_pulse = '1') then
              SPIXfer_done_int <= '0';
          else
              if(mode_1 = '1' and mode_0 = '0')then
                      SPIXfer_done_int <= Count(1) and
                                          not(Count(0));
              elsif(mode_1 = '0' and mode_0 = '1')then
                      SPIXfer_done_int <= not(Count(0)) and
                                              Count(2)  and
                                              Count(1);
              else
                      SPIXfer_done_int <= --Count(COUNT_WIDTH);
                                            Count(COUNT_WIDTH-1) and
                                            Count(COUNT_WIDTH-2) and
                                            Count(COUNT_WIDTH-3) and
                                            not Count(COUNT_WIDTH-4);
              end if;
          end if;
      end if;
  end process TRANSFER_DONE_PROCESS;

-- -- RECEIVE_DATA_STROBE_PROCESS : Strobe data from shift register to receive
-- --                               data register
-- --------------------------------
-- -- For a SCK ratio of 2 the Done needs to be delayed by an extra cycle
-- -- due to the serial input being captured on the falling edge of the PLB
-- -- clock. this is purely required for dealing with the real SPI slave memories.
--   RECEIVE_DATA_NM_GEN: if C_SPI_MEMORY = 2 and C_SPI_MODE /=0 generate
--   begin
--   -----
--   RECEIVE_DATA_STROBE_PROCESS: process(EXT_SPI_CLK)
--   -----
--   begin
--   -----
--       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
--          if(load_axi_data_to_spi_clk = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
--                  receive_Data_int  <= (others => '0');
--          elsif(SPIXfer_done_int_pulse_d1 = '1') then -- and (cmd_addr_sent = '1')then
--                  receive_Data_int  <= rx_shft_reg_mode_0011;
--          end if;
--       end if;
--   end process RECEIVE_DATA_STROBE_PROCESS;
--   end generate RECEIVE_DATA_NM_GEN;
--   -----------------------------------------------------------------------------

--  -----------------------------------------------------------------------------
--  RECEIVE_DATA_WB_GEN: if C_SPI_MEMORY = 1 and C_SPI_MODE /=0 generate
--  begin
--  -----
--  RECEIVE_DATA_STROBE_PROCESS: process(EXT_SPI_CLK)
--  -----
--  begin
--  -----
--      if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
--         if(load_axi_data_to_spi_clk = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
--                 receive_Data_int  <= (others => '0');
--         elsif(SPIXfer_done_int_pulse_d1 = '1') and (cmd_addr_sent = '1')then
--                 receive_Data_int  <= rx_shft_reg_mode_0011;
--         end if;
--      end if;
--  end process RECEIVE_DATA_STROBE_PROCESS;
--  end generate RECEIVE_DATA_WB_GEN;

-----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- RATIO_OF_2_GENERATE : Logic to be used when C_SCK_RATIO is equal to 2
------------------------
RATIO_OF_2_GENERATE: if(C_SCK_RATIO = 2) generate
--------------------
---------------attribute IOB                                   : string;
---------------attribute IOB of QSPI_SCK_T        : label is "true";

begin
-----
-------------------------------------------------------------------------------
-- SCK_CYCLE_COUNT_PROCESS : Counts number of trigger pulses provided. Used for
--                           controlling the number of bits to be transfered
--                           based on generic C_NUM_TRANSFER_BITS
----------------------------
  RATIO_2_SCK_CYCLE_COUNT_PROCESS: process(EXT_SPI_CLK)is
  begin

    if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(Rst_to_spi = RESET_ACTIVE) or (transfer_start = '0') or (store_last_b4_wrap = '1') then -- (wrap_ack_1 = '1')then
            Count <= (others => '0');
        elsif(SPIXfer_done_int = '1')then
            Count <= (others => '0');
        elsif((Count(COUNT_WIDTH) = '0') and
              ((CPOL_to_spi_clk and CPHA_to_spi_clk) = '0')) then
            Count <=  Count + 1;
        elsif(transfer_start_d2 = '1') and (Count(COUNT_WIDTH) = '0') then
            Count <=  Count + 1;
        end if;
    end if;
  end process RATIO_2_SCK_CYCLE_COUNT_PROCESS;
  ------------------------------------

SCK_SET_RESET_32_BIT_ADDR_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate
begin
    -------------------------------------------------------------------------------
    -- SCK_SET_GEN_PROCESS : Generate SET control for SCK_O_reg
    ------------------------
    SCK_SET_GEN_PROCESS: process(CPOL_to_spi_clk,
                                 CPHA_to_spi_clk,
                                 SPIXfer_done_int,
                                 transfer_start_pulse,--,
                                 load_axi_data_to_spi_clk,
                                 wrap_ack_1,
                                 load_wr_hpm,
                                 load_wr_en
                                 ) is
    -----
    begin
    -----
        if(SPIXfer_done_int = '1')or(load_axi_data_to_spi_clk = '1') or (load_wr_hpm = '1') or (load_wr_en = '1')then
            Sync_Set <= (CPOL_to_spi_clk xor CPHA_to_spi_clk);
        else
            Sync_Set <= '0';
        end if;
    end process SCK_SET_GEN_PROCESS;

    -------------------------------------------------------------------------------
    -- SCK_RESET_GEN_PROCESS : Generate SET control for SCK_O_reg
    --------------------------
    SCK_RESET_GEN_PROCESS: process(CPOL_to_spi_clk,
                                   CPHA_to_spi_clk,
                                   transfer_start_pulse,
                                   SPIXfer_done_int,
                                   load_axi_data_to_spi_clk,
                                   load_wr_hpm,
                                   load_wr_en
                                   )is
    -----
    begin
    -----
        if(SPIXfer_done_int = '1')or(load_axi_data_to_spi_clk = '1')or(load_wr_hpm = '1') or (load_wr_en = '1') then
            Sync_Reset <= not(CPOL_to_spi_clk xor CPHA_to_spi_clk);
        else
            Sync_Reset <= '0';
        end if;
    end process SCK_RESET_GEN_PROCESS;

end generate SCK_SET_RESET_32_BIT_ADDR_GEN;
-------------------------------------------
SCK_SET_RESET_24_BIT_ADDR_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate
begin
    -------------------------------------------------------------------------------
    -- SCK_SET_GEN_PROCESS : Generate SET control for SCK_O_reg
    ------------------------
    SCK_SET_GEN_PROCESS: process(CPOL_to_spi_clk,
                                 CPHA_to_spi_clk,
                                 SPIXfer_done_int,
                                 transfer_start_pulse,--,
                                 load_axi_data_to_spi_clk,
                                 wrap_ack_1,
                                 load_wr_hpm--,
                                 --load_wr_en
                                 ) is
    -----
    begin
    -----
        if(SPIXfer_done_int = '1')or(load_axi_data_to_spi_clk = '1') or (load_wr_hpm = '1') 
        --or (load_wr_en = '1')
        then
            Sync_Set <= (CPOL_to_spi_clk xor CPHA_to_spi_clk);
        else
            Sync_Set <= '0';
        end if;
    end process SCK_SET_GEN_PROCESS;

    -------------------------------------------------------------------------------
    -- SCK_RESET_GEN_PROCESS : Generate SET control for SCK_O_reg
    --------------------------
    SCK_RESET_GEN_PROCESS: process(CPOL_to_spi_clk,
                                   CPHA_to_spi_clk,
                                   transfer_start_pulse,
                                   SPIXfer_done_int,
                                   load_axi_data_to_spi_clk,
                                   load_wr_hpm--,
                                   --load_wr_en
                                   )is
    -----
    begin
    -----
        if(SPIXfer_done_int = '1')or(load_axi_data_to_spi_clk = '1')or(load_wr_hpm = '1')
          --or (load_wr_en = '1') 
          then
            Sync_Reset <= not(CPOL_to_spi_clk xor CPHA_to_spi_clk);
        else
            Sync_Reset <= '0';
        end if;
    end process SCK_RESET_GEN_PROCESS;

end generate SCK_SET_RESET_24_BIT_ADDR_GEN;
-------------------------------------------

  -------------------------------------------------------------------------------
  -- SCK_SET_RESET_PROCESS : Sync set/reset toggle flip flop controlled by
  --                         transfer_start signal
  --------------------------
  RATIO_2_SCK_SET_RESET_PROCESS: process(EXT_SPI_CLK)
  begin
      if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
          if((Rst_to_spi = RESET_ACTIVE) or (Sync_Reset = '1') or
             (new_tr = '0') or (wrap_ack_1 = '1')) then
              sck_o_int <= '0';
          elsif(Sync_Set = '1') then
              sck_o_int <= '1';
          elsif (transfer_start = '1') then
              sck_o_int <= (not sck_o_int);
          end if;
      end if;
  end process RATIO_2_SCK_SET_RESET_PROCESS;
  ----------------------------------

      -- DELAY_CLK: Delay the internal clock for a cycle to generate internal enable
    --         -- signal for data register.
    -------------
    RATIO_2_DELAY_CLK: process(EXT_SPI_CLK)is
    -----
    begin
    -----
       if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
          if (Rst_to_spi = RESET_ACTIVE)then
             sck_d1 <= '0';
             sck_d2 <= '0';
          else
             sck_d1 <= sck_o_int;
             sck_d2 <= sck_d1;
          end if;
       end if;
    end process RATIO_2_DELAY_CLK;
    ------------------------------------
    -- Rising egde pulse
    sck_rising_edge <= sck_d2 and (not sck_d1);

  --   CAPT_RX_FE_MODE_00_11: The below logic is to capture data for SPI mode of
  --------------------------- 00 and 11.
  -- Generate a falling edge pulse from the serial clock. Use this to
  -- capture the incoming serial data into a shift register.
  RATIO_2_CAPT_RX_FE_MODE_00_11 : process(EXT_SPI_CLK)is
  begin
    if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then -- SPIXfer_done_int_pulse_d2
          if (Rst_to_spi = RESET_ACTIVE) then --  or (wrap_ack_1 = '1')then
                  rx_shft_reg_mode_0011 <= (others => '0');
          elsif((sck_d2='0') and --(sck_rising_edge = '1') and
                (Data_Dir='0')  -- data direction = 0 is read mode
               )then
               -------
               if(mode_1 = '0' and mode_0 = '0')then    -- for Standard transfer
                      rx_shft_reg_mode_0011 <= rx_shft_reg_mode_0011
                                         (1 to (C_NUM_TRANSFER_BITS-1)) &
                                                                  IO1_I ; --MISO_I;
               elsif(mode_1 = '0' and mode_0 = '1')then -- for Dual transfer
                      rx_shft_reg_mode_0011 <= rx_shft_reg_mode_0011
                                         (2 to (C_NUM_TRANSFER_BITS-1)) &
                                                                  IO1_I &  -- MISO_I - MSB first
                                                                  IO0_I ;  -- MOSI_I
               elsif(mode_1 = '1' and mode_0 = '0')then -- for Quad transfer
                      rx_shft_reg_mode_0011 <= rx_shft_reg_mode_0011
                                         (4 to (C_NUM_TRANSFER_BITS-1)) &
                                                                  IO3_I &  -- MSB first
                                                                  IO2_I &
                                                                  IO1_I &
                                                                  IO0_I ;
               end if;
               -------
          else
             rx_shft_reg_mode_0011<= rx_shft_reg_mode_0011;
          end if;
      end if;
  end process RATIO_2_CAPT_RX_FE_MODE_00_11;
  ----------------------------------
  QSPI_NM_MEM_DATA_CAP_GEN: if (C_SPI_MODE = 0 and (C_SPI_MEMORY = 0 or
                                                                 C_SPI_MEMORY = 2))
                                              or
                                              (
                                               ( C_SPI_MODE = 1
                                                 or
                                                 C_SPI_MODE = 2
                                               )
                                               and
                                               C_SPI_MEMORY = 2
                                             )generate
  --------------------------------------
  begin
  -----
  -------------------------------------------------------------------------------
  -- CAPTURE_AND_SHIFT_PROCESS : This logic essentially controls the entire
  --                             capture and shift operation for serial data in
  ------------------------------ master SPI mode only
  RATIO_2_CAPTURE_AND_SHIFT_PROCESS: process(EXT_SPI_CLK)is
  begin
      if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
          if(Rst_to_spi = RESET_ACTIVE) then
              Shift_Reg(0 to C_NUM_TRANSFER_BITS -1) <= (others => '0');
              Serial_Dout_0 <= '0';-- default values of the IO0_O
              Serial_Dout_1 <= '0';
              Serial_Dout_2 <= '0';
              Serial_Dout_3 <= '0';
          elsif(transfer_start = '1') then
              if(transfer_start_pulse = '1' or SPIXfer_done_int_d1 = '1') then --
              --if(Load_tx_data_to_shift_reg_int = '1') then
                      Shift_Reg   <= Transmit_Data;
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Transmit_Data(0);
                        Serial_Dout_3 <= Quad_Phase;--pr_state_cmd_ph and Quad_Phase;-- this is to make the DQ3 bit 1 in quad command transfer mode.
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Transmit_Data(0); -- msb to IO1_O
                        Serial_Dout_0 <= Transmit_Data(1);
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Transmit_Data(0); -- msb to IO3_O
                        Serial_Dout_2 <= Transmit_Data(1);
                        Serial_Dout_1 <= Transmit_Data(2);
                        Serial_Dout_0 <= Transmit_Data(3);
                      end if;
              elsif(
                    (Count(0) = '0')
                    )then -- Shift Data on even
                  if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Shift_Reg(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;
                  elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Shift_Reg(0); -- msb to IO1_O
                        Serial_Dout_0 <= Shift_Reg(1);
                  elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Shift_Reg(0); -- msb to IO3_O
                        Serial_Dout_2 <= Shift_Reg(1);
                        Serial_Dout_1 <= Shift_Reg(2);
                        Serial_Dout_0 <= Shift_Reg(3);
                  end if;
              elsif(
                    (Count(0) = '1')       --and
                    ) then -- Capture Data on odd
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                           Shift_Reg <= Shift_Reg
                                        (1 to C_NUM_TRANSFER_BITS -1) &
                                                                IO1_I ;-- MISO_I;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                          Shift_Reg   <= Shift_Reg
                                        (2 to C_NUM_TRANSFER_BITS -1) &
                                                                IO1_I &
                                                                IO0_I ;
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                          Shift_Reg   <= Shift_Reg
                                        (4 to C_NUM_TRANSFER_BITS -1) &
                                                                IO3_I &
                                                                IO2_I &
                                                                IO1_I &
                                                                IO0_I ;
                      end if;
              end if;
          end if;
      end if;
  end process RATIO_2_CAPTURE_AND_SHIFT_PROCESS;
  ----------------------------------------------
  end generate QSPI_NM_MEM_DATA_CAP_GEN;
  ----------------------------------
  QSPI_SP_MEM_DATA_CAP_GEN: if (C_SPI_MODE = 0 and (C_SPI_MEMORY = 0 or
                                                                 C_SPI_MEMORY = 3))
                                              or
                                              (
                                               ( C_SPI_MODE = 1
                                                 or
                                                 C_SPI_MODE = 2
                                               )
                                               and
                                               C_SPI_MEMORY = 3
                                             )generate
  --------------------------------------
  begin
  -----
  -------------------------------------------------------------------------------
  -- CAPTURE_AND_SHIFT_PROCESS : This logic essentially controls the entire
  --                             capture and shift operation for serial data in
  ------------------------------ master SPI mode only
  RATIO_2_CAPTURE_AND_SHIFT_PROCESS: process(EXT_SPI_CLK)is
  begin
      if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
          if(Rst_to_spi = RESET_ACTIVE) then
              Shift_Reg(0 to C_NUM_TRANSFER_BITS -1) <= (others => '0');
              Serial_Dout_0 <= '0';-- default values of the IO0_O
              Serial_Dout_1 <= '0';
              Serial_Dout_2 <= '0';
              Serial_Dout_3 <= '0';
          elsif(transfer_start = '1') then
              if(transfer_start_pulse = '1' or SPIXfer_done_int_d1 = '1') then --
              --if(Load_tx_data_to_shift_reg_int = '1') then
                      Shift_Reg   <= Transmit_Data;
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Transmit_Data(0);
                        Serial_Dout_3 <= Quad_Phase;--pr_state_cmd_ph and Quad_Phase;-- this is to make the DQ3 bit 1 in quad command transfer mode.
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Transmit_Data(0); -- msb to IO1_O
                        Serial_Dout_0 <= Transmit_Data(1);
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Transmit_Data(0); -- msb to IO3_O
                        Serial_Dout_2 <= Transmit_Data(1);
                        Serial_Dout_1 <= Transmit_Data(2);
                        Serial_Dout_0 <= Transmit_Data(3);
                      end if;
              elsif(
                    (Count(0) = '0')
                    )then -- Shift Data on even
                  if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Shift_Reg(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;
                  elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Shift_Reg(0); -- msb to IO1_O
                        Serial_Dout_0 <= Shift_Reg(1);
                  elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Shift_Reg(0); -- msb to IO3_O
                        Serial_Dout_2 <= Shift_Reg(1);
                        Serial_Dout_1 <= Shift_Reg(2);
                        Serial_Dout_0 <= Shift_Reg(3);
                  end if;
              elsif(
                    (Count(0) = '1')       --and
                    ) then -- Capture Data on odd
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                           Shift_Reg <= Shift_Reg
                                        (1 to C_NUM_TRANSFER_BITS -1) &
                                                                IO1_I ;-- MISO_I;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                          Shift_Reg   <= Shift_Reg
                                        (2 to C_NUM_TRANSFER_BITS -1) &
                                                                IO1_I &
                                                                IO0_I ;
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                          Shift_Reg   <= Shift_Reg
                                        (4 to C_NUM_TRANSFER_BITS -1) &
                                                                IO3_I &
                                                                IO2_I &
                                                                IO1_I &
                                                                IO0_I ;
                      end if;
              end if;
          end if;
      end if;
  end process RATIO_2_CAPTURE_AND_SHIFT_PROCESS;
  ----------------------------------------------
  end generate QSPI_SP_MEM_DATA_CAP_GEN;
  ----------------------------------

  QSPI_WINBOND_MEM_DATA_CAP_GEN: if (
                                     (C_SPI_MODE = 0 and (C_SPI_MEMORY = 0 or
                                                             C_SPI_MEMORY = 1))
                                     or
                                     (
                                       ( C_SPI_MODE = 1
                                        or
                                        C_SPI_MODE = 2
                                       )
                                          and
                                      C_SPI_MEMORY = 1
                                     )) generate
  -----------------------------------------
  begin
  -----
  -------------------------------------------------------------------------------
  -- CAPTURE_AND_SHIFT_PROCESS : This logic essentially controls the entire
  --                             capture and shift operation for serial data in
  ------------------------------ master SPI mode only
  RATIO_2_CAPTURE_AND_SHIFT_PROCESS: process(EXT_SPI_CLK)is
  begin
      if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
          if(Rst_to_spi = RESET_ACTIVE) then
              Shift_Reg(0 to C_NUM_TRANSFER_BITS -1) <= (others => '0');
              Serial_Dout_0 <= '0';-- default values of the IO0_O
              Serial_Dout_1 <= '0';
              Serial_Dout_2 <= '0';
              Serial_Dout_3 <= '0';
          elsif(transfer_start = '1') then
              --if(Load_tx_data_to_shift_reg_int = '1') then
              if(transfer_start_pulse = '1' or SPIXfer_done_int_d1 = '1') then --
                      Shift_Reg   <= Transmit_Data;
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Transmit_Data(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;-- this is to make the DQ3 bit 1 in quad command transfer mode.
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Transmit_Data(0); -- msb to IO1_O
                        Serial_Dout_0 <= Transmit_Data(1);
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Transmit_Data(0); -- msb to IO3_O
                        Serial_Dout_2 <= Transmit_Data(1);
                        Serial_Dout_1 <= Transmit_Data(2);
                        Serial_Dout_0 <= Transmit_Data(3);
                      end if;
              elsif(
                    (Count(0) = '0')       --and
                    )then -- Shift Data on even
                  if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Shift_Reg(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;
                  elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Shift_Reg(0); -- msb to IO1_O
                        Serial_Dout_0 <= Shift_Reg(1);
                  elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Shift_Reg(0); -- msb to IO3_O
                        Serial_Dout_2 <= Shift_Reg(1);
                        Serial_Dout_1 <= Shift_Reg(2);
                        Serial_Dout_0 <= Shift_Reg(3);
                  end if;
              elsif(
                    (Count(0) = '1')       --and
                    ) then -- Capture Data on odd
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                           Shift_Reg <= Shift_Reg
                                        (1 to C_NUM_TRANSFER_BITS -1) &
                                                                 IO1_I;-- MISO_I;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                          Shift_Reg   <= Shift_Reg
                                        (2 to C_NUM_TRANSFER_BITS -1) &
                                                                IO1_I &
                                                                IO0_I ;
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                          Shift_Reg   <= Shift_Reg
                                        (4 to C_NUM_TRANSFER_BITS -1) &
                                                                IO3_I &
                                                                IO2_I &
                                                                IO1_I &
                                                                IO0_I ;
                      end if;
              end if;
          end if;
      end if;
  end process RATIO_2_CAPTURE_AND_SHIFT_PROCESS;
  ----------------------------------------------
  end generate QSPI_WINBOND_MEM_DATA_CAP_GEN;
  ------------------------------------------------------
--------------------------------
XIP_STD_DUAL_MODE_WB_MEM_GEN: if (
                                  (C_SPI_MODE = 0 or C_SPI_MODE = 1) and
                                  (
                                   (C_SPI_MEMORY = 1 or C_SPI_MEMORY = 0)
                                   )
                                 )generate
--------------------------------
begin
-----
--------------------------------------------------
PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
-----
begin
-----
    if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(Rst_to_spi = RESET_ACTIVE) then
            qspi_cntrl_ps <= IDLE;
            stop_clock_reg <= '0';
        else
            qspi_cntrl_ps <= qspi_cntrl_ns;
            stop_clock_reg <= stop_clock;
        end if;
    end if;
end process PS_TO_NS_PROCESS;
-----------------------------
pr_state_data_receive <= '1' when qspi_cntrl_ps = DATA_RECEIVE else
                         '0';
pr_state_non_idle     <= '1' when qspi_cntrl_ps /= IDLE else
                         '0';
pr_state_idle         <= '1' when qspi_cntrl_ps = IDLE else
                         '0';
pr_state_cmd_ph       <= '1' when qspi_cntrl_ps = CMD_SEND else
                         '0';


QSPI_CNTRL_PROCESS: process(
                            ---------------------
                            new_tr              ,
                            CMD_Mode_1          ,
                            CMD_Mode_0          ,
                            ---------------------
                            Addr_Phase          ,
                            Addr_Bit            ,
                            Addr_Mode_1         ,
                            Addr_Mode_0         ,
                            ---------------------
                            Data_Phase          ,
                            Data_Dir            ,
                            Data_Mode_1         ,
                            Data_Mode_0         ,
                            ---------------------
                            addr_cnt            ,
                            Quad_Phase          ,
                            ---------------------
                            SR_5_Tx_Empty       ,
                            SPIXfer_done_int_pulse,
                            stop_clock_reg,
                            ---------------------
                            qspi_cntrl_ps       ,
                            no_slave_selected   ,
                            ---------------------
                            wrap_around         ,
                            transfer_start      ,
                            wrap_ack_1          ,
                            wb_hpm_done         ,
                            hpm_under_process_d1
                    )is
-----
begin
-----
     mode_1 <= '0';
     mode_0 <= '0';
     --------------
     IO0_T_control <= '1';
     IO1_T_control <= '1';
     -------------
     stop_clock    <= '0';
     -------------
     rst_wrap_around <= '0';
     -------------
     case qspi_cntrl_ps is
        when IDLE         => if((SR_5_Tx_Empty = '0') and -- this will be used specially in case of WRAP transactions
                                 (transfer_start = '1')and
                                 (new_tr = '1')
                                )then
                                 IO0_T_control <= CMD_Mode_0;
                                 IO3_T_control <= not Quad_Phase;--
                                 qspi_cntrl_ns <= CMD_SEND;
                             else
                                 qspi_cntrl_ns <= IDLE;
                             end if;
                             stop_clock    <= '1';
                             ------------------------------------------------
        when CMD_SEND     => mode_1 <= CMD_Mode_1;
                             mode_0 <= CMD_Mode_0;

                             IO0_T_control <= CMD_Mode_0;
                             IO1_T_control <= (CMD_Mode_1) or (not CMD_Mode_0);

                                 if(SPIXfer_done_int_pulse = '1')then
                                    if(hpm_under_process_d1 = '1')then
                                        qspi_cntrl_ns <= HPM_DUMMY;
                                    elsif(Addr_Phase='1')then
                                        qspi_cntrl_ns <= ADDR_SEND;
                                    else
                                        qspi_cntrl_ns <= IDLE;
                                    end if;
                                 else
                                    qspi_cntrl_ns <= CMD_SEND;
                                 end if;
                             ------------------------------------------------
        when HPM_DUMMY    => IO0_T_control <= CMD_Mode_0;
                             IO1_T_control <= (CMD_Mode_1) or (not CMD_Mode_0);

                             if(SR_5_Tx_Empty='1') then
                                 qspi_cntrl_ns <= IDLE;
                             else
                                 qspi_cntrl_ns <= HPM_DUMMY;
                             end if;
                             ------------------------------------------------
        when ADDR_SEND    => mode_1 <= Addr_Mode_1;
                             mode_0 <= Addr_Mode_0;

                             IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                             IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);-- (Addr_Mode_1) or(not Addr_Mode_0);

                             --stop_clock    <= not SR_5_Tx_Empty;

                             if((SR_5_Tx_Empty='1') and
                                (Data_Phase='0')
                               ) or (wrap_ack_1 = '1') then
                                 if (no_slave_selected = '1') or (wrap_ack_1 = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                 else
                                        qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                 end if;
                             else
                                 if(
                                    (addr_cnt = "011") and -- 24 bit address
                                    (Addr_Bit='0')     and (Data_Phase='1')
                                    )then
                                     IO0_T_control <= '1';
                                     IO1_T_control <= '1';
                                     qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                 else
                                     qspi_cntrl_ns <= ADDR_SEND;
                                 end if;
                             end if;
                             ------------------------------------------------
        when TEMP_ADDR_SEND =>
                               mode_1 <= Addr_Mode_1;
                               mode_0 <= Addr_Mode_0;

                               IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                               IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);-- (Addr_Mode_1) or(not Addr_Mode_0);

                               stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                     qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= ADDR_SEND;
                               end if;
        when DATA_RECEIVE => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             if(SR_5_Tx_Empty='1') or (wrap_ack_1 = '1')then
                                 rst_wrap_around <= '1';
                                 if(no_slave_selected = '1') or
                                   (wrap_around = '1')then
                                    qspi_cntrl_ns <= IDLE;
                                    stop_clock    <= wrap_ack_1;
                                 else
                                    stop_clock    <= SR_5_Tx_Empty;
                                    qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_RECEIVE => mode_1 <= Data_Mode_1;
                                  mode_0 <= Data_Mode_0;
                                  stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_RECEIVE;
                               end if;

        -- coverage off
        when others => qspi_cntrl_ns <= IDLE;
                             ------------------------------------------------
        -- coverage on
     end case;
-------------------------------
end process QSPI_CNTRL_PROCESS;
-------------------------------

pr_state_addr_ph <= '1' when (qspi_cntrl_ps = ADDR_SEND) else
                    '0';

QSPI_ADDR_CNTR_PROCESS: process(EXT_SPI_CLK)is
-----
begin
-----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(pr_state_addr_ph = '0') then
                addr_cnt <= (others => '0');
        elsif(pr_state_addr_ph = '1')then
                addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse;
        end if;
     end if;
end process QSPI_ADDR_CNTR_PROCESS;
-----------------------------------

end generate XIP_STD_DUAL_MODE_WB_MEM_GEN;
------------------------------------------
--------------------------------------------------
XIP_STD_DUAL_MODE_NM_MEM_GEN: if ((C_SPI_MODE = 1 or C_SPI_MODE = 0) and
                                  (C_SPI_MEMORY = 2 or C_SPI_MEMORY = 0)
                                  )generate
-------------------
begin
-----
--------------------------------------------------
PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
-----
begin
-----
    if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(Rst_to_spi = RESET_ACTIVE) then
            qspi_cntrl_ps <= IDLE;
            stop_clock_reg <= '0';
        else
            qspi_cntrl_ps <= qspi_cntrl_ns;
            stop_clock_reg <= stop_clock;
        end if;
    end if;
end process PS_TO_NS_PROCESS;
-----------------------------
pr_state_data_receive <= '1' when qspi_cntrl_ps = DATA_RECEIVE else
                         '0';
pr_state_non_idle     <= '1' when qspi_cntrl_ps /= IDLE else
                         '0';
pr_state_idle         <= '1' when qspi_cntrl_ps = IDLE else
                         '0';
pr_state_cmd_ph       <= '1' when qspi_cntrl_ps = CMD_SEND else
                         '0';

QSPI_CNTRL_PROCESS: process(
                            ---------------------
                            --CMD_decoded         ,
                            new_tr,
                            CMD_Mode_1          ,
                            CMD_Mode_0          ,
                            --CMD_Error           ,
                            ---------------------
                            Addr_Phase          ,
                            Addr_Bit            ,
                            Addr_Mode_1         ,
                            Addr_Mode_0         ,
                            ---------------------
                            Data_Phase          ,
                            Data_Dir            ,
                            Data_Mode_1         ,
                            Data_Mode_0         ,
                            ---------------------
                            addr_cnt            ,
                            ---------------------
                            SR_5_Tx_Empty       ,SPIXfer_done_int_pulse,
                            stop_clock_reg,
                            no_slave_selected   ,
                            ---------------------
                            qspi_cntrl_ps       ,
                            ---------------------
                            wrap_around         ,
                            transfer_start      ,
							Quad_Phase          ,
                            wrap_ack_1
                    )is
-----
begin
-----
     mode_1 <= '0';
     mode_0 <= '0';
     --------------
     IO0_T_control <= '1';
     IO1_T_control <= '1';
     --------------
     stop_clock    <= '0';
     --------------
     rst_wrap_around <= '0';
     --------------
     case qspi_cntrl_ps is
        when IDLE         => if((SR_5_Tx_Empty = '0') and -- this will be used specially in case of WRAP transactions
                                (transfer_start = '1')and
                                (new_tr = '1')
                                )then
                                 IO0_T_control <= CMD_Mode_0;
                                 IO3_T_control <= not Quad_Phase;--
                                 qspi_cntrl_ns <= CMD_SEND;
                             else
                                 qspi_cntrl_ns <= IDLE;
                             end if;
                             stop_clock    <= '1';
                             ------------------------------------------------
        when CMD_SEND     => mode_1 <= CMD_Mode_1;
                             mode_0 <= CMD_Mode_0;

                             IO0_T_control <= CMD_Mode_1;

                                 --if(SPIXfer_done_int_pulse_d2 = '1')then
                                 if(SPIXfer_done_int_pulse = '1')then
                                    if(Addr_Phase='1')then
                                        qspi_cntrl_ns <= ADDR_SEND;
                                    else
                                        qspi_cntrl_ns <= IDLE;
                                    end if;
                                 else
                                    qspi_cntrl_ns <= CMD_SEND;
                                 end if;
                             ------------------------------------------------
        when ADDR_SEND    => mode_1 <= Addr_Mode_1;
                             mode_0 <= Addr_Mode_0;

                             IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                             IO1_T_control <= not(Addr_Mode_0);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if(((SR_5_Tx_Empty='1')           and
                                (Data_Phase='0')) or (wrap_ack_1 = '1')
                               )then
                                 if (no_slave_selected = '1') or (wrap_ack_1 = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                 else
                                        qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                 end if;
                             else
                                 if(
                                    (addr_cnt = "011") and -- 24 bit address
                                    (Addr_Bit='0')     and (Data_Phase='1')
                                    )then
                                          if((Data_Dir='1'))then
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;
                                              IO0_T_control <= Data_Mode_1;
                                              IO1_T_control <= not(Data_Mode_0);
                                              qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                          else
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          end if;
                                 elsif(
                                       (addr_cnt = "100") and -- 32 bit
                                       (Addr_Bit = '1')   and (Data_Phase='1')
                                      ) then
                                          --if((Data_Dir='1'))then
                                          --    qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                          --else
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          --end if;
                                 else
                                     qspi_cntrl_ns <= ADDR_SEND;
                                 end if;
                             end if;
        --                   ------------------------------------------------
        when TEMP_ADDR_SEND => mode_1 <= Addr_Mode_1;
                               mode_0 <= Addr_Mode_0;

                               IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                               IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);-- (Addr_Mode_1) or(not Addr_Mode_0);

                               stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= ADDR_SEND;
                               end if;

        when DATA_SEND    => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= Data_Mode_1;
                             IO1_T_control <= not(Data_Mode_0);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if(no_slave_selected = '1')then
                                qspi_cntrl_ns <= IDLE;
                             else
                                qspi_cntrl_ns <= TEMP_DATA_SEND;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_SEND =>
                              mode_1 <= Data_Mode_1;
                              mode_0 <= Data_Mode_0;
                              IO0_T_control <= Data_Mode_1;
                              IO1_T_control <= not(Data_Mode_0);

                              stop_clock    <= stop_clock_reg;
                              if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  end if;
                             else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_SEND;
                             end if;

        when DATA_RECEIVE => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             --stop_clock    <= SR_5_Tx_Empty;

                             if(SR_5_Tx_Empty='1') or (wrap_ack_1 = '1')then
                                 rst_wrap_around <= wrap_ack_1;
                                 if(no_slave_selected = '1') or (wrap_ack_1 = '1')then
                                    stop_clock <= wrap_ack_1;
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                     mode_1 <= Data_Mode_1;
                                     mode_0 <= Data_Mode_0;
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_RECEIVE => mode_1 <= Data_Mode_1;
                                  mode_0 <= Data_Mode_0;
                                  stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_RECEIVE;
                               end if;

        -- coverage off
        when others => qspi_cntrl_ns <= IDLE;
                             ------------------------------------------------
        -- coverage on
     end case;
-------------------------------
end process QSPI_CNTRL_PROCESS;
-------------------------------
pr_state_addr_ph <= '1' when qspi_cntrl_ps = ADDR_SEND else
                    '0';

QSPI_ADDR_CNTR_PROCESS: process(EXT_SPI_CLK)is
-----
begin
-----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(pr_state_addr_ph = '0') then
                addr_cnt <= (others => '0');
        elsif(pr_state_addr_ph = '1')then
                addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse;
        end if;
     end if;
end process QSPI_ADDR_CNTR_PROCESS;
-----------------------------------
end generate XIP_STD_DUAL_MODE_NM_MEM_GEN;
--------------------------------
--------------------------------------------------
XIP_STD_DUAL_MODE_SP_MEM_GEN: if ((C_SPI_MODE = 1 or C_SPI_MODE = 0) and
                                  (C_SPI_MEMORY = 3 or C_SPI_MEMORY = 0)
                                  )generate
-------------------
begin
-----
--------------------------------------------------
PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
-----
begin
-----
    if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(Rst_to_spi = RESET_ACTIVE) then
            qspi_cntrl_ps <= IDLE;
            stop_clock_reg <= '0';
        else
            qspi_cntrl_ps <= qspi_cntrl_ns;
            stop_clock_reg <= stop_clock;
        end if;
    end if;
end process PS_TO_NS_PROCESS;
-----------------------------
pr_state_data_receive <= '1' when qspi_cntrl_ps = DATA_RECEIVE else
                         '0';
pr_state_non_idle     <= '1' when qspi_cntrl_ps /= IDLE else
                         '0';
pr_state_idle         <= '1' when qspi_cntrl_ps = IDLE else
                         '0';
pr_state_cmd_ph       <= '1' when qspi_cntrl_ps = CMD_SEND else
                         '0';

QSPI_CNTRL_PROCESS: process(
                            ---------------------
                            --CMD_decoded         ,
                            new_tr,
                            CMD_Mode_1          ,
                            CMD_Mode_0          ,
                            --CMD_Error           ,
                            ---------------------
                            Addr_Phase          ,
                            Addr_Bit            ,
                            Addr_Mode_1         ,
                            Addr_Mode_0         ,
                            ---------------------
                            Data_Phase          ,
                            Data_Dir            ,
                            Data_Mode_1         ,
                            Data_Mode_0         ,
                            ---------------------
                            addr_cnt            ,
                            ---------------------
                            SR_5_Tx_Empty       ,SPIXfer_done_int_pulse,
                            stop_clock_reg,
                            no_slave_selected   ,
                            ---------------------
                            qspi_cntrl_ps       ,
                            ---------------------
                            wrap_around         ,
                            transfer_start      ,
                            wrap_ack_1
                    )is
-----
begin
-----
     mode_1 <= '0';
     mode_0 <= '0';
     --------------
     IO0_T_control <= '1';
     IO1_T_control <= '1';
     --------------
     stop_clock    <= '0';
     --------------
     rst_wrap_around <= '0';
     --------------
     case qspi_cntrl_ps is
        when IDLE         => if((SR_5_Tx_Empty = '0') and -- this will be used specially in case of WRAP transactions
                                (transfer_start = '1')and
                                (new_tr = '1')
                                )then
                                 IO0_T_control <= CMD_Mode_0;
                                 IO3_T_control <= not Quad_Phase;--
                                 qspi_cntrl_ns <= CMD_SEND;
                             else
                                 qspi_cntrl_ns <= IDLE;
                             end if;
                             stop_clock    <= '1';
                             ------------------------------------------------
        when CMD_SEND     => mode_1 <= CMD_Mode_1;
                             mode_0 <= CMD_Mode_0;

                             IO0_T_control <= CMD_Mode_1;

                                 --if(SPIXfer_done_int_pulse_d2 = '1')then
                                 if(SPIXfer_done_int_pulse = '1')then
                                    if(Addr_Phase='1')then
                                        qspi_cntrl_ns <= ADDR_SEND;
                                    else
                                        qspi_cntrl_ns <= IDLE;
                                    end if;
                                 else
                                    qspi_cntrl_ns <= CMD_SEND;
                                 end if;
                             ------------------------------------------------
        when ADDR_SEND    => mode_1 <= Addr_Mode_1;
                             mode_0 <= Addr_Mode_0;

                             IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                             IO1_T_control <= not(Addr_Mode_0);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if(((SR_5_Tx_Empty='1')           and
                                (Data_Phase='0')) or (wrap_ack_1 = '1')
                               )then
                                 if (no_slave_selected = '1') or (wrap_ack_1 = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                 else
                                        qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                 end if;
                             else
                                 if(
                                    (addr_cnt = "011") and -- 24 bit address
                                    (Addr_Bit='0')     and (Data_Phase='1')
                                    )then
                                          if((Data_Dir='1'))then
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;
                                              IO0_T_control <= Data_Mode_1;
                                              IO1_T_control <= not(Data_Mode_0);
                                              qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                          else
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          end if;
                                 elsif(
                                       (addr_cnt = "100") and -- 32 bit
                                       (Addr_Bit = '1')   and (Data_Phase='1')
                                      ) then
                                          --if((Data_Dir='1'))then
                                          --    qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                          --else
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          --end if;
                                 else
                                     qspi_cntrl_ns <= ADDR_SEND;
                                 end if;
                             end if;
        --                   ------------------------------------------------
        when TEMP_ADDR_SEND => mode_1 <= Addr_Mode_1;
                               mode_0 <= Addr_Mode_0;

                               IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                               IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);-- (Addr_Mode_1) or(not Addr_Mode_0);

                               stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= ADDR_SEND;
                               end if;

        when DATA_SEND    => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= Data_Mode_1;
                             IO1_T_control <= not(Data_Mode_0);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if(no_slave_selected = '1')then
                                qspi_cntrl_ns <= IDLE;
                             else
                                qspi_cntrl_ns <= TEMP_DATA_SEND;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_SEND =>
                              mode_1 <= Data_Mode_1;
                              mode_0 <= Data_Mode_0;
                              IO0_T_control <= Data_Mode_1;
                              IO1_T_control <= not(Data_Mode_0);

                              stop_clock    <= stop_clock_reg;
                              if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  end if;
                             else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_SEND;
                             end if;

        when DATA_RECEIVE => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             --stop_clock    <= SR_5_Tx_Empty;

                             if(SR_5_Tx_Empty='1') or (wrap_ack_1 = '1')then
                                 rst_wrap_around <= wrap_ack_1;
                                 if(no_slave_selected = '1') or (wrap_ack_1 = '1')then
                                    stop_clock <= wrap_ack_1;
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                     mode_1 <= Data_Mode_1;
                                     mode_0 <= Data_Mode_0;
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_RECEIVE => mode_1 <= Data_Mode_1;
                                  mode_0 <= Data_Mode_0;
                                  stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_RECEIVE;
                               end if;

        -- coverage off
        when others => qspi_cntrl_ns <= IDLE;
                             ------------------------------------------------
        -- coverage on
     end case;
-------------------------------
end process QSPI_CNTRL_PROCESS;
-------------------------------
pr_state_addr_ph <= '1' when qspi_cntrl_ps = ADDR_SEND else
                    '0';

QSPI_ADDR_CNTR_PROCESS: process(EXT_SPI_CLK)is
-----
begin
-----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(pr_state_addr_ph = '0') then
                addr_cnt <= (others => '0');
        elsif(pr_state_addr_ph = '1')then
                addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse;
        end if;
     end if;
end process QSPI_ADDR_CNTR_PROCESS;
-----------------------------------
end generate XIP_STD_DUAL_MODE_SP_MEM_GEN;

--------------------------------------------------
XIP_QUAD_MODE_WB_MEM_GEN: if (
                               C_SPI_MODE = 2 and
                               C_SPI_MEMORY = 1
                              )
                              generate
-------------------
begin
-----
--------------------------------------------------
PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
-----
begin
-----
    if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(Rst_to_spi = RESET_ACTIVE) then
            qspi_cntrl_ps <= IDLE;
            stop_clock_reg <= '0';
        else
            qspi_cntrl_ps <= qspi_cntrl_ns;
            stop_clock_reg <= stop_clock;
        end if;
    end if;
end process PS_TO_NS_PROCESS;
-----------------------------
pr_state_data_receive <= '1' when qspi_cntrl_ps = DATA_RECEIVE else
                         '0';
pr_state_non_idle     <= '1' when qspi_cntrl_ps /= IDLE else
                         '0';
pr_state_idle         <= '1' when qspi_cntrl_ps = IDLE else
                         '0';
pr_state_cmd_ph       <= '1' when qspi_cntrl_ps = CMD_SEND else
                         '0';

QSPI_CNTRL_PROCESS: process(
                            ---------------------
                            new_tr,
                            CMD_Mode_1          ,
                            CMD_Mode_0          ,
                            ---------------------
                            Addr_Phase          ,
                            Addr_Bit            ,
                            Addr_Mode_1         ,
                            Addr_Mode_0         ,
                            ---------------------
                            Data_Phase          ,
                            Data_Dir            ,
                            Data_Mode_1         ,
                            Data_Mode_0         ,
                            ---------------------
                            addr_cnt            ,
                            Quad_Phase         ,
                            ---------------------
                            SR_5_Tx_Empty       ,
                            SPIXfer_done_int_pulse,
                            stop_clock_reg,
                            ---------------------
                            qspi_cntrl_ps       ,
                            no_slave_selected   ,
                            ---------------------
                            wrap_around         ,
                            transfer_start      ,
                            wrap_ack_1          ,
                            wb_hpm_done         ,
                            hpm_under_process_d1
                    )is
-----
begin
-----
     mode_1 <= '0';
     mode_0 <= '0';
     --------------
     IO0_T_control <= '1';
     IO1_T_control <= '1';
     IO2_T_control <= '1';
     IO3_T_control <= '1';
     --------------
     stop_clock    <= '0';
     --------------
     rst_wrap_around <= '0';
     --------------
     case qspi_cntrl_ps is
        when IDLE         => if(--(CMD_decoded = '1') and
                                 (SR_5_Tx_Empty = '0') and -- this will be used specially in case of WRAP transactions
                                 (transfer_start = '1')and
                                 (new_tr = '1')
                                 --(CMD_Error = '0')         -- proceed only when there is no command error
                                )then
                                 IO0_T_control <= CMD_Mode_0;
                                 IO3_T_control <= not Quad_Phase;--
                                 qspi_cntrl_ns <= CMD_SEND;
                             else
                                 qspi_cntrl_ns <= IDLE; -- CMD_DECODE;
                             end if;
                             stop_clock    <= '1';
                             ------------------------------------------------
        when CMD_SEND     => mode_1 <= CMD_Mode_1;
                             mode_0 <= CMD_Mode_0;

                             IO0_T_control <= CMD_Mode_0;
                             IO3_T_control <= not Quad_Phase;--

                                 --if(SPIXfer_done_int_pulse_d2 = '1')then
                                 if(SPIXfer_done_int_pulse = '1')then
                                    if(hpm_under_process_d1 = '1')then
                                        qspi_cntrl_ns <= HPM_DUMMY;
                                    elsif(Addr_Phase='1')then
                                        qspi_cntrl_ns <= ADDR_SEND;
                                    else
                                        qspi_cntrl_ns <= IDLE;
                                    end if;
                                 else
                                    qspi_cntrl_ns <= CMD_SEND;
                                 end if;
                             ------------------------------------------------
        when HPM_DUMMY    => IO0_T_control <= CMD_Mode_0;
                             IO1_T_control <= (CMD_Mode_1) or (not CMD_Mode_0);

                             if(SR_5_Tx_Empty='1') then
                                 qspi_cntrl_ns <= IDLE;
                             else
                                 qspi_cntrl_ns <= HPM_DUMMY;
                             end if;
                             ------------------------------------------------
         when ADDR_SEND    => mode_1 <= Addr_Mode_1;
                              mode_0 <= Addr_Mode_0;

                             IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                             IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);
                             IO2_T_control <= (not Addr_Mode_1);
                             IO3_T_control <= (not Addr_Mode_1);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if((SR_5_Tx_Empty='1') and
                                 (Data_Phase='0')
                                )then
                                 if (no_slave_selected = '1')then
                                     qspi_cntrl_ns <= IDLE;
                                 else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                 end if;
                             else
                                  if(
                                     (addr_cnt = "011") and -- 24 bit address
                                     (Addr_Bit='0')     and(Data_Phase='1')
                                     )then
                                         if((Data_Dir='1'))then
                                             mode_1 <= Data_Mode_1;
                                             mode_0 <= Data_Mode_0;
                                             IO0_T_control <= '0';              -- data output
                                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                                             IO2_T_control <= not (Data_Mode_1);-- active only
                                             IO3_T_control <= not (Data_Mode_1);-- active only
                                             qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                         else
                                             IO0_T_control <= '1';
                                             IO1_T_control <= '1';
                                             IO2_T_control <= '1';
                                             IO3_T_control <= '1';
                                             qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                         end if;
                                  -- -- coverage off
                                  -- -- below piece of code is for 32-bit address check, and left for future use
                                  -- elsif(
                                  --       (addr_cnt = "100") and -- 32 bit
                                  --       (Addr_Bit = '1')   and (Data_Phase='1')
                                  --       )then
                                  --         if((Data_Dir='1'))then
                                  --             qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                  --         else
                                  --             qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                  --         end if;
                                  -- -- coverage on
                                 else
                                     qspi_cntrl_ns <= ADDR_SEND;
                                 end if;
                              end if;
                              ------------------------------------------------
        when TEMP_ADDR_SEND => mode_1 <= Addr_Mode_1;
                               mode_0 <= Addr_Mode_0;

                               IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                               IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);
                               IO2_T_control <= (not Addr_Mode_1);
                               IO3_T_control <= (not Addr_Mode_1);

                               stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= ADDR_SEND;
                               end if;
        -----------------------------------------------------------------------
        when DATA_SEND    => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= '0';              -- data output active only in Dual mode
                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                             IO2_T_control <= not (Data_Mode_1);-- active only in quad mode
                             IO3_T_control <= not (Data_Mode_1);-- active only in quad mode

                             --stop_clock    <= SR_5_Tx_Empty;
                             if(SR_5_Tx_Empty='1')then
                                 if(no_slave_selected = '1')then
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                    qspi_cntrl_ns <= TEMP_DATA_SEND;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_SEND;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_SEND => mode_1 <= Data_Mode_1;
                               mode_0 <= Data_Mode_0;

                             IO0_T_control <= '0';              -- data output active only in Dual mode
                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                             IO2_T_control <= not (Data_Mode_1);-- active only in quad mode
                             IO3_T_control <= not (Data_Mode_1);-- active only in quad mode

                             stop_clock    <= stop_clock_reg;
                             if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  end if;
                             else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_SEND;
                             end if;

        when DATA_RECEIVE => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             --stop_clock    <= SR_5_Tx_Empty;
                             if(SR_5_Tx_Empty='1')or (wrap_ack_1 = '1')then
                                 rst_wrap_around <= wrap_ack_1;
                                 if(no_slave_selected = '1')or (wrap_ack_1 = '1')then
                                    stop_clock <= wrap_ack_1;
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                    stop_clock    <= SR_5_Tx_Empty;
                                    qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_RECEIVE => mode_1 <= Data_Mode_1;
                                  mode_0 <= Data_Mode_0;
                                  stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_RECEIVE;
                               end if;
                             ------------------------------------------------
        -- coverage off
        when others => qspi_cntrl_ns <= IDLE;
                             ------------------------------------------------
        -- coverage on
     end case;
-------------------------------
end process QSPI_CNTRL_PROCESS;
-------------------------------
pr_state_addr_ph <= '1' when qspi_cntrl_ps = ADDR_SEND else
                    '0';

QSPI_ADDR_CNTR_PROCESS: process(EXT_SPI_CLK)is
-----
begin
-----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(pr_state_addr_ph = '0') then
                addr_cnt <= (others => '0');
        elsif(pr_state_addr_ph = '1')then
                --addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse_d2;
                addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse;
        end if;
     end if;
end process QSPI_ADDR_CNTR_PROCESS;
-----------------------------------
------------------------------------------
end generate XIP_QUAD_MODE_WB_MEM_GEN;
------------------------------------------

--------------------------------------------------
XIP_QUAD_MODE_NM_MEM_GEN: if C_SPI_MODE = 2 and C_SPI_MEMORY = 2 generate
-------------------
begin
-----
--------------------------------------------------
PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
-----
begin
-----
    if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(Rst_to_spi = RESET_ACTIVE) then
            qspi_cntrl_ps <= IDLE;
            stop_clock_reg <= '0';
        else
            qspi_cntrl_ps <= qspi_cntrl_ns;
            stop_clock_reg <= stop_clock;
        end if;
    end if;
end process PS_TO_NS_PROCESS;
-----------------------------
pr_state_data_receive <= '1' when qspi_cntrl_ps = DATA_RECEIVE else
                         '0';
pr_state_non_idle     <= '1' when qspi_cntrl_ps /= IDLE else
                         '0';
pr_state_idle         <= '1' when qspi_cntrl_ps = IDLE else
                         '0';
pr_state_cmd_ph       <= '1' when qspi_cntrl_ps = CMD_SEND else
                         '0';

QSPI_CNTRL_PROCESS: process(
                            ---------------------
                            --CMD_decoded         ,
                            new_tr,
                            CMD_Mode_1          ,
                            CMD_Mode_0          ,
                            --CMD_Error           ,
                            ---------------------
                            Addr_Phase          ,
                            Addr_Bit            ,
                            Addr_Mode_1         ,
                            Addr_Mode_0         ,
                            ---------------------
                            Data_Phase          ,
                            Data_Dir            ,
                            Data_Mode_1         ,
                            Data_Mode_0         ,
                            ---------------------
                            addr_cnt            ,
                            Quad_Phase         ,
                            ---------------------
                            SR_5_Tx_Empty       ,
                            --SPIXfer_done_int_pulse_d2,
                            SPIXfer_done_int_pulse,
                            stop_clock_reg,
                            no_slave_selected   ,
                            ---------------------
                            qspi_cntrl_ps       ,
                            ---------------------
                            wrap_around         ,
                            transfer_start_d1   ,
                            transfer_start      ,
                            wrap_ack_1
                    )is
-----
begin
-----
     mode_1 <= '0';
     mode_0 <= '0';
     --------------
     IO0_T_control <= '1';
     IO1_T_control <= '1';
     IO2_T_control <= '1';
     IO3_T_control <= '1';
     -------------
     stop_clock    <= '0';
     -------------
     rst_wrap_around <= '0';
     -------------
     case qspi_cntrl_ps is
        when IDLE          => if(--(CMD_decoded = '1') and
                                 (SR_5_Tx_Empty = '0') and -- this will be used specially in case of WRAP transactions
                                 (transfer_start = '1')and
                                 (new_tr = '1')
                                 --(CMD_Error = '0') -- proceed only when there is no command error
                                )then
                                IO0_T_control <= CMD_Mode_0;
                                IO3_T_control <= not Quad_Phase;

                                qspi_cntrl_ns <= CMD_SEND;
                             else
                                 qspi_cntrl_ns <= IDLE;
                             end if;
                             stop_clock    <= '1';

                             ------------------------------------------------
        when CMD_SEND     => mode_1 <= CMD_Mode_1;
                             mode_0 <= CMD_Mode_0;

                             IO0_T_control <= CMD_Mode_0;
                             IO3_T_control <= not Quad_Phase;-- this is due to sending '1' on DQ3 line during command phase for Quad instructions only.

                                 --if(SPIXfer_done_int_pulse_d2 = '1')then
                                 if(SPIXfer_done_int_pulse = '1')then
                                    if(Addr_Phase='1')then
                                        qspi_cntrl_ns <= ADDR_SEND;
                                    else
                                        qspi_cntrl_ns <= IDLE;
                                    end if;
                                 else
                                    qspi_cntrl_ns <= CMD_SEND;
                                 end if;
                             ------------------------------------------------
        when ADDR_SEND    => mode_1 <= Addr_Mode_1;
                             mode_0 <= Addr_Mode_0;

                             IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                             IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);
                             IO2_T_control <= (not Addr_Mode_1);
                             IO3_T_control <= (not Addr_Mode_1);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if((SR_5_Tx_Empty='1')           and
                                (Data_Phase='0')
                               )then
                                 if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                 else
                                        qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                 end if;
                             else
                                 if(
                                    (addr_cnt = "011") and -- 24 bit address
                                    (Addr_Bit='0')     and
                                    (Data_Phase='1')
                                    )then
                                          if((Data_Dir='1'))then
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;

                                              IO0_T_control <= '0';
                                              IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                                              IO2_T_control <= not (Data_Mode_1);
                                              IO3_T_control <= not (Data_Mode_1);
                                              qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                          else
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              IO2_T_control <= '1';
                                              IO3_T_control <= '1';
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          end if;
                                 elsif(
                                       (addr_cnt = "100") and -- 32 bit
                                       (Addr_Bit = '1')   and
                                       (Data_Phase='1')
                                      ) then
                                          --if((Data_Dir='1'))then
                                          --    qspi_cntrl_ns <= DATA_SEND; -- o/p
                                          --else
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              IO2_T_control <= '1';
                                              IO3_T_control <= '1';
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          --end if;
                                 else
                                     qspi_cntrl_ns <= ADDR_SEND;
                                 end if;
                             end if;
        --                     ------------------------------------------------
        when TEMP_ADDR_SEND => mode_1 <= Addr_Mode_1;
                               mode_0 <= Addr_Mode_0;

                               IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                               IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);
                               IO2_T_control <= (not Addr_Mode_1);
                               IO3_T_control <= (not Addr_Mode_1);

                               stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= ADDR_SEND;
                               end if;

        when DATA_SEND    => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= '0';
                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                             IO2_T_control <= not (Data_Mode_1);
                             IO3_T_control <= not (Data_Mode_1);

                             --stop_clock    <= SR_5_Tx_Empty;
                             if(SR_5_Tx_Empty='1')then
                                 if(no_slave_selected = '1')then
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                    qspi_cntrl_ns <= TEMP_DATA_SEND;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_SEND;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_SEND=> mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= '0';
                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                             IO2_T_control <= not (Data_Mode_1);
                             IO3_T_control <= not (Data_Mode_1);

                             stop_clock    <= stop_clock_reg;
                             if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  end if;
                             else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_SEND;
                             end if;

        when DATA_RECEIVE => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             --stop_clock    <= SR_5_Tx_Empty;
                             if(SR_5_Tx_Empty='1') or (wrap_ack_1 = '1')then
                                 rst_wrap_around <= wrap_ack_1;
                                 --if(no_slave_selected = '1') or (wrap_around = '1')then
                                    stop_clock <= wrap_ack_1 or SR_5_Tx_Empty;
                                    qspi_cntrl_ns <= IDLE;
                                 --else
                                 --   stop_clock    <= SR_5_Tx_Empty;
                                 --   qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                 --end if;
                             else
                                 qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_RECEIVE =>  mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;
                             stop_clock    <= stop_clock_reg;
                             --if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  end if;
                             --else
                             --      stop_clock    <= '0';
                             --      qspi_cntrl_ns <= DATA_RECEIVE;
                             --end if;
                             ------------------------------------------------
        -- coverage off
        when others => qspi_cntrl_ns <= IDLE; -- CMD_DECODE;
                             ------------------------------------------------
        -- coverage on
     end case;
-------------------------------
end process QSPI_CNTRL_PROCESS;
-------------------------------
pr_state_addr_ph <= '1' when qspi_cntrl_ps = ADDR_SEND else
                    '0';

QSPI_ADDR_CNTR_PROCESS: process(EXT_SPI_CLK)is
-----
begin
-----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(pr_state_addr_ph = '0') then
                addr_cnt <= (others => '0');
        elsif(pr_state_addr_ph = '1')then
                --addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse_d2;
                addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse;
        end if;
     end if;
end process QSPI_ADDR_CNTR_PROCESS;
-----------------------------------
end generate XIP_QUAD_MODE_NM_MEM_GEN;
---------------------------------------
XIP_QUAD_MODE_SP_MEM_GEN: if C_SPI_MODE = 2 and C_SPI_MEMORY = 3 generate
-------------------
begin
-----
--------------------------------------------------
PS_TO_NS_PROCESS: process(EXT_SPI_CLK)is
-----
begin
-----
    if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(Rst_to_spi = RESET_ACTIVE) then
            qspi_cntrl_ps <= IDLE;
            stop_clock_reg <= '0';
        else
            qspi_cntrl_ps <= qspi_cntrl_ns;
            stop_clock_reg <= stop_clock;
        end if;
    end if;
end process PS_TO_NS_PROCESS;
-----------------------------
pr_state_data_receive <= '1' when qspi_cntrl_ps = DATA_RECEIVE else
                         '0';
pr_state_non_idle     <= '1' when qspi_cntrl_ps /= IDLE else
                         '0';
pr_state_idle         <= '1' when qspi_cntrl_ps = IDLE else
                         '0';
pr_state_cmd_ph       <= '1' when qspi_cntrl_ps = CMD_SEND else
                         '0';

QSPI_CNTRL_PROCESS: process(
                            ---------------------
                            --CMD_decoded         ,
                            new_tr,
                            CMD_Mode_1          ,
                            CMD_Mode_0          ,
                            --CMD_Error           ,
                            ---------------------
                            Addr_Phase          ,
                            Addr_Bit            ,
                            Addr_Mode_1         ,
                            Addr_Mode_0         ,
                            ---------------------
                            Data_Phase          ,
                            Data_Dir            ,
                            Data_Mode_1         ,
                            Data_Mode_0         ,
                            ---------------------
                            addr_cnt            ,
                            Quad_Phase         ,
                            ---------------------
                            SR_5_Tx_Empty       ,
                            --SPIXfer_done_int_pulse_d2,
                            SPIXfer_done_int_pulse,
                            stop_clock_reg,
                            no_slave_selected   ,
                            ---------------------
                            qspi_cntrl_ps       ,
                            ---------------------
                            wrap_around         ,
                            transfer_start_d1   ,
                            transfer_start      ,
                            wrap_ack_1
                    )is
-----
begin
-----
     mode_1 <= '0';
     mode_0 <= '0';
     --------------
     IO0_T_control <= '1';
     IO1_T_control <= '1';
     IO2_T_control <= '1';
     IO3_T_control <= '1';
     -------------
     stop_clock    <= '0';
     -------------
     rst_wrap_around <= '0';
     -------------
     case qspi_cntrl_ps is
        when IDLE          => if(--(CMD_decoded = '1') and
                                 (SR_5_Tx_Empty = '0') and -- this will be used specially in case of WRAP transactions
                                 (transfer_start = '1')and
                                 (new_tr = '1')
                                 --(CMD_Error = '0') -- proceed only when there is no command error
                                )then
                                IO0_T_control <= CMD_Mode_0;
                                IO3_T_control <= not Quad_Phase;

                                qspi_cntrl_ns <= CMD_SEND;
                             else
                                 qspi_cntrl_ns <= IDLE;
                             end if;
                             stop_clock    <= '1';

                             ------------------------------------------------
        when CMD_SEND     => mode_1 <= CMD_Mode_1;
                             mode_0 <= CMD_Mode_0;

                             IO0_T_control <= CMD_Mode_0;
                             IO3_T_control <= not Quad_Phase;-- this is due to sending '1' on DQ3 line during command phase for Quad instructions only.

                                 --if(SPIXfer_done_int_pulse_d2 = '1')then
                                 if(SPIXfer_done_int_pulse = '1')then
                                    if(Addr_Phase='1')then
                                        qspi_cntrl_ns <= ADDR_SEND;
                                    else
                                        qspi_cntrl_ns <= IDLE;
                                    end if;
                                 else
                                    qspi_cntrl_ns <= CMD_SEND;
                                 end if;
                             ------------------------------------------------
        when ADDR_SEND    => mode_1 <= Addr_Mode_1;
                             mode_0 <= Addr_Mode_0;

                             IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                             IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);
                             IO2_T_control <= (not Addr_Mode_1);
                             IO3_T_control <= (not Addr_Mode_1);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if((SR_5_Tx_Empty='1')           and
                                (Data_Phase='0')
                               )then
                                 if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                 else
                                        qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                 end if;
                             else
                                 if(
                                    (addr_cnt = "011") and -- 24 bit address
                                    (Addr_Bit='0')     and
                                    (Data_Phase='1')
                                    )then
                                          if((Data_Dir='1'))then
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;

                                              IO0_T_control <= '0';
                                              IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                                              IO2_T_control <= not (Data_Mode_1);
                                              IO3_T_control <= not (Data_Mode_1);
                                              qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                          else
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              IO2_T_control <= '1';
                                              IO3_T_control <= '1';
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          end if;
                                 elsif(
                                       (addr_cnt = "100") and -- 32 bit
                                       (Addr_Bit = '1')   and
                                       (Data_Phase='1')
                                      ) then
                                          --if((Data_Dir='1'))then
                                          --    qspi_cntrl_ns <= DATA_SEND; -- o/p
                                          --else
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              IO2_T_control <= '1';
                                              IO3_T_control <= '1';
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          --end if;
                                 else
                                     qspi_cntrl_ns <= ADDR_SEND;
                                 end if;
                             end if;
        --                     ------------------------------------------------
        when TEMP_ADDR_SEND => mode_1 <= Addr_Mode_1;
                               mode_0 <= Addr_Mode_0;

                               IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                               IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);
                               IO2_T_control <= (not Addr_Mode_1);
                               IO3_T_control <= (not Addr_Mode_1);

                               stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= ADDR_SEND;
                               end if;

        when DATA_SEND    => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= '0';
                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                             IO2_T_control <= not (Data_Mode_1);
                             IO3_T_control <= not (Data_Mode_1);

                             --stop_clock    <= SR_5_Tx_Empty;
                             if(SR_5_Tx_Empty='1')then
                                 if(no_slave_selected = '1')then
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                    qspi_cntrl_ns <= TEMP_DATA_SEND;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_SEND;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_SEND=> mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= '0';
                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                             IO2_T_control <= not (Data_Mode_1);
                             IO3_T_control <= not (Data_Mode_1);

                             stop_clock    <= stop_clock_reg;
                             if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  end if;
                             else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_SEND;
                             end if;

        when DATA_RECEIVE => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             --stop_clock    <= SR_5_Tx_Empty;
                             if(SR_5_Tx_Empty='1') or (wrap_ack_1 = '1')then
                                 rst_wrap_around <= wrap_ack_1;
                                 --if(no_slave_selected = '1') or (wrap_around = '1')then
                                    stop_clock <= wrap_ack_1 or SR_5_Tx_Empty;
                                    qspi_cntrl_ns <= IDLE;
                                 --else
                                 --   stop_clock    <= SR_5_Tx_Empty;
                                 --   qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                 --end if;
                             else
                                 qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_RECEIVE =>  mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;
                             stop_clock    <= stop_clock_reg;
                             --if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  end if;
                             --else
                             --      stop_clock    <= '0';
                             --      qspi_cntrl_ns <= DATA_RECEIVE;
                             --end if;
                             ------------------------------------------------
        -- coverage off
        when others => qspi_cntrl_ns <= IDLE; -- CMD_DECODE;
                             ------------------------------------------------
        -- coverage on
     end case;
-------------------------------
end process QSPI_CNTRL_PROCESS;
-------------------------------
pr_state_addr_ph <= '1' when qspi_cntrl_ps = ADDR_SEND else
                    '0';

QSPI_ADDR_CNTR_PROCESS: process(EXT_SPI_CLK)is
-----
begin
-----
     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
        if(pr_state_addr_ph = '0') then
                addr_cnt <= (others => '0');
        elsif(pr_state_addr_ph = '1')then
                --addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse_d2;
                addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse;
        end if;
     end if;
end process QSPI_ADDR_CNTR_PROCESS;
-----------------------------------
end generate XIP_QUAD_MODE_SP_MEM_GEN;
---------------------------------------

IO0_O                           <= Serial_Dout_0;
IO1_O                           <= Serial_Dout_1;
IO2_O                           <= Serial_Dout_2;
IO3_O                           <= Serial_Dout_3;
--SCK_O                           <= SCK_O_reg;
--SS_O                            <= SS_to_spi_clk;
--* -------------------------------------------------------------------------------
--* -- MASTER_TRIST_EN_PROCESS : If not master make tristate enabled
--* ----------------------------
SS_tri_state_en_control <= '0' when
                           (
                            -- (SR_5_Tx_Empty_d1 = '0') and -- Length counter is not exited
                            (transfer_start = '1') and 
                            (wrap_ack = '0')   and -- no wrap around
                            --(MODF_strobe_int ='0')   -- no mode fault -- 9/7/2013
			    (SPISEL_sync = '1')  -- 9/7/2013
                           )
                           else
                           '1';

--QSPI_SS_T: tri-state register for SS,ideal state-deactive
QSPI_SS_T: component FD
   generic map
        (
        INIT => '1'
        )
   port map
        (
        Q  => SS_T,
        C  => EXT_SPI_CLK,
        D  => SS_tri_state_en_control
        );
    --QSPI_SCK_T : Tri-state register for SCK_T, ideal state-deactive
SCK_tri_state_en_control <= '0' when
                             (
                              -- (SR_5_Tx_Empty = '0')       and -- Length counter is not exited
                              (transfer_start = '1')      and -- 4/14/2013
                              (wrap_ack = '0')            and -- no wrap around-- (pr_state_non_idle = '1')    and -- CR#619275 - this is commented to operate the mode 3 with SW flow
                              --(MODF_strobe_int ='0')         -- no mode fault -- 9/7/2013
			      (SPISEL_sync = '1') -- 9/7/2013
                             ) else
                             '1';
							 
    QSPI_SCK_T: component FD
       generic map
           (
           INIT => '1'
           )
       port map
           (
           Q  => SCK_T,
           C  => EXT_SPI_CLK,
           D  => SCK_tri_state_en_control
           );
    IO0_tri_state_en_control <= '0' when
                         (
                          (IO0_T_control = '0')   and
                          --(MODF_strobe_int = '0')-- no mode fault-- 9/7/2013
			  (SPISEL_sync = '1') -- 9/7/2013
                         ) else
                         '1';
    --QSPI_IO0_T: tri-state register for MOSI, ideal state-deactive
    QSPI_IO0_T: component FD
       generic map
            (
            INIT => '1'
            )
       port map
            (
            Q  => IO0_T,     -- MOSI_T,
            C  => EXT_SPI_CLK,
            D  => IO0_tri_state_en_control -- master_tri_state_en_control
            );
    IO1_tri_state_en_control <= '0' when
                         (
                          (IO1_T_control = '0')   and
                          --(MODF_strobe_int = '0')-- no mode fault-- 9/7/2013
			  (SPISEL_sync = '1') -- 9/7/2013
                         ) else
                         '1';

    --QSPI_IO0_T: tri-state register for MISO, ideal state-deactive
    QSPI_IO1_T: component FD
       generic map
            (
            INIT => '1'
            )
       port map
            (
            Q  => IO1_T,      -- MISO_T,
            C  => EXT_SPI_CLK,
            D  => IO1_tri_state_en_control
            );
-------------------------------------------------------------------------------
QSPI_NO_MODE_2_T_CONTROL: if C_SPI_MODE = 1 or C_SPI_MODE = 0 generate
----------------------
begin
-----
    --------------------------------------
    IO2_tri_state_en_control <= '1';
    IO3_tri_state_en_control <= '1';
    IO2_T <= '1';
    IO3_T <= '1';
    --------------------------------------
end generate QSPI_NO_MODE_2_T_CONTROL;
--------------------------------------
-------------------------------------------------------------------------------
QSPI_MODE_2_T_CONTROL: if C_SPI_MODE = 2 generate
----------------------
begin
-----
    --------------------------------------
    IO2_tri_state_en_control <= '0' when
                         (
                          (IO2_T_control = '0')   and
                          --(MODF_strobe_int = '0')-- no mode fault -- 9/7/2013
			  (SPISEL_sync = '1') -- 9/7/2013
                         ) else
                         '1';
    --QSPI_IO0_T: tri-state register for MOSI, ideal state-deactive
    QSPI_IO2_T: component FD
       generic map
            (
            INIT => '1'
            )
       port map
            (
            Q  => IO2_T,     -- MOSI_T,
            C  => EXT_SPI_CLK,
            D  => IO2_tri_state_en_control -- master_tri_state_en_control
            );
    --------------------------------------
    IO3_tri_state_en_control <= '0' when
                         (
                          (IO3_T_control = '0')   and
                          --(MODF_strobe_int = '0')-- no mode fault-- 9/7/2013
			  (SPISEL_sync = '1') -- 9/7/2013
                         ) else
                         '1';

    --QSPI_IO0_T: tri-state register for MISO, ideal state-deactive
    QSPI_IO3_T: component FD
       generic map
            (
            INIT => '1'
            )
       port map
            (
            Q  => IO3_T,      -- MISO_T,
            C  => EXT_SPI_CLK,
            D  => IO3_tri_state_en_control
            );
    --------------------------------------
end generate QSPI_MODE_2_T_CONTROL;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- QSPI_SPISEL: first synchronize the incoming signal, this is required is slave
--------------- mode of the core.

    QSPI_SPISEL: component FD
       generic map
            (
            INIT => '1' -- default '1' to make the device in default master mode
            )
       port map
            (
            Q  => SPISEL_sync,
            C  => EXT_SPI_CLK,
            D  => SPISEL
            );
    -- SPISEL_DELAY_1CLK_PROCESS_P : Detect active SCK edge in slave mode
    -----------------------------
    SPISEL_DELAY_1CLK_PROCESS_P: process(EXT_SPI_CLK)
    begin
        if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
            if(Rst_to_spi = RESET_ACTIVE) then
                spisel_d1 <= '1';
            else
                spisel_d1 <= SPISEL_sync;
            end if;
        end if;
    end process SPISEL_DELAY_1CLK_PROCESS_P;
    ------------------------------------------------

    -- MODF_STROBE_PROCESS : Strobe MODF signal when master is addressed as slave
    ------------------------
    MODF_STROBE_PROCESS: process(EXT_SPI_CLK)is
    -----
    begin
    -----
        if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
           if((Rst_to_spi = RESET_ACTIVE) or (SPISEL_sync = '1')) then
               MODF_strobe       <= '0';
               MODF_strobe_int   <= '0';
               Allow_MODF_Strobe <= '1';
           elsif(
                 (SPISEL_sync = '0') and
                 (Allow_MODF_Strobe = '1')
                 ) then
               MODF_strobe       <= '1';
               MODF_strobe_int   <= '1';
               Allow_MODF_Strobe <= '0';
           else
               MODF_strobe       <= '0';
               MODF_strobe_int   <= '0';
           end if;
        end if;
    end process MODF_STROBE_PROCESS;

SS_O_24_BIT_ADDR_GEN: if C_SPI_MEM_ADDR_BITS = 24 generate 
-----
begin
-----
    -------------------------------------------------------------------------------
    -- SELECT_OUT_PROCESS : This process sets SS active-low, one-hot encoded select
    --                      bit. Changing SS is premitted during a transfer by
    --                      hardware, but is to be prevented by software. In Auto
    --                      mode SS_O reflects value of Slave_Select_Reg only
    --                      when transfer is in progress, otherwise is SS_O is held
    --                      high
    -----------------------
    SELECT_OUT_PROCESS: process(EXT_SPI_CLK)is
    begin
        if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
           if(Rst_to_spi = RESET_ACTIVE) then
               SS_O                   <= (others => '1');
           elsif(wrap_ack_1 = '1') or (store_last_b4_wrap = '1') or (SR_5_Tx_Empty ='1') then
               SS_O                   <= (others => '1');
           elsif(hpm_under_process_d1 = '1') then
               for i in (C_NUM_SS_BITS-1) downto 0 loop
                   SS_O(i) <= (SS_to_spi_clk(C_NUM_SS_BITS-1-i));
               end loop;
           elsif(store_last_b4_wrap = '0') then
               for i in (C_NUM_SS_BITS-1) downto 0 loop
                   SS_O(i) <= not(SS_to_spi_clk(C_NUM_SS_BITS-1-i));
               end loop;
           end if;
        end if;
    end process SELECT_OUT_PROCESS;
    ----------------------------
end generate SS_O_24_BIT_ADDR_GEN;
----------------------------------

SS_O_32_BIT_ADDR_GEN: if C_SPI_MEM_ADDR_BITS = 32 generate 
-----
begin
-----
    -------------------------------------------------------------------------------
    -- SELECT_OUT_PROCESS : This process sets SS active-low, one-hot encoded select
    --                      bit. Changing SS is premitted during a transfer by
    --                      hardware, but is to be prevented by software. In Auto
    --                      mode SS_O reflects value of Slave_Select_Reg only
    --                      when transfer is in progress, otherwise is SS_O is held
    --                      high
    -----------------------
    SELECT_OUT_PROCESS: process(EXT_SPI_CLK)is
    begin
        if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
           if(Rst_to_spi = RESET_ACTIVE) then
               SS_O                   <= (others => '1');
           elsif(wrap_ack_1 = '1') or (store_last_b4_wrap = '1') or (transfer_start = '0' and SR_5_Tx_Empty_d1='1') then
               SS_O                   <= (others => '1');
           elsif(hpm_under_process = '1') or (wr_en_under_process = '1') then
               for i in (C_NUM_SS_BITS-1) downto 0 loop
                   SS_O(i) <= (SS_to_spi_clk(C_NUM_SS_BITS-1-i));
               end loop;
           elsif(store_last_b4_wrap = '0') then
               for i in (C_NUM_SS_BITS-1) downto 0 loop
                   SS_O(i) <= not(SS_to_spi_clk(C_NUM_SS_BITS-1-i));
               end loop;
           end if;
        end if;
    end process SELECT_OUT_PROCESS;
    ----------------------------
end generate SS_O_32_BIT_ADDR_GEN;
----------------------------------
    no_slave_selected <= and_reduce(SS_to_spi_clk((C_NUM_SS_BITS-1) downto 0));
    -------------------------------------------------------------------------------
    SCK_O_NQ_4_NO_STARTUP_USED: if (C_USE_STARTUP = 0) generate
    ----------------
    attribute IOB                         : string;
    attribute IOB of SCK_O_NE_4_FDRE_INST : label is "true";
    signal slave_mode                     : std_logic;
    ----------------
    begin
    -----
    -------------------------------------------------------------------------------
    -- SCK_O_SELECT_PROCESS : Select the idle state (CPOL bit) when not transfering
    --                        data else select the clock for slave device
    -------------------------
    SCK_O_NQ_4_SELECT_PROCESS: process(--Mst_N_Slv         ,-- in master mode
                                       sck_o_int         ,-- value driven on sck_int
                                       CPOL_to_spi_clk              ,-- CPOL mode thr SPICR
                                       transfer_start    ,
                                       transfer_start_d1 ,
                                       Count(COUNT_WIDTH),
                                       pr_state_non_idle  -- State machine is in Non-idle state
                                      )is
    begin
            if((transfer_start = '1')    and
               --(transfer_start_d1 = '1') and
               --(Count(COUNT_WIDTH) = '0')and
               (pr_state_non_idle = '1')
               ) then
                    sck_o_in <= sck_o_int;
            else
                    sck_o_in <= CPOL_to_spi_clk;
            end if;
    end process SCK_O_NQ_4_SELECT_PROCESS;
    ---------------------------------

    slave_mode <= '0'; -- create the reset condition by inverting the mst_n_slv signal. 1 - master mode, 0 - slave mode.
    -- FDRE: Single Data Rate D Flip-Flop with Synchronous Reset and
    -- Clock Enable (posedge clk). during slave mode no clock should be generated from the core.
    SCK_O_NE_4_FDRE_INST : component FDRE
    generic map (
                 INIT => '0'
                 ) -- Initial value of register (’0’ or ’1’)
          port map
                (
                 Q  => SCK_O_reg,   -- Data output
                 C  => EXT_SPI_CLK,  -- Clock input
                 CE => '1',         -- Clock enable input
                 R  => Rst_to_spi,  -- Synchronous reset input
                 D  => sck_o_in     -- Data input
                );

    end generate SCK_O_NQ_4_NO_STARTUP_USED;
    -------------------------------

    SCK_O_NQ_4_STARTUP_USED: if (C_USE_STARTUP = 1) generate
    -------------
    begin
    -----
    -------------------------------------------------------------------------------
    -- SCK_O_SELECT_PROCESS : Select the idle state (CPOL bit) when not transfering
    --                        data else select the clock for slave device
    -------------------------
    SCK_O_NQ_4_SELECT_PROCESS: process(sck_o_int         ,
                                       CPOL_to_spi_clk              ,
                                       transfer_start    ,
                                       transfer_start_d1 ,
                                       Count(COUNT_WIDTH)
                                      )is
    begin
            if((transfer_start = '1')   -- and
               --(transfer_start_d1 = '1') --and
               --(Count(COUNT_WIDTH) = '0')
               ) then
                    sck_o_in <= sck_o_int;
            else
                    sck_o_in <= CPOL_to_spi_clk;
            end if;
    end process SCK_O_NQ_4_SELECT_PROCESS;
    ---------------------------------

     ---------------------------------------------------------------------------
     -- SCK_O_FINAL_PROCESS : Register the final SCK_O_reg
     ------------------------
     SCK_O_NQ_4_FINAL_PROCESS: process(EXT_SPI_CLK)
     -----
     begin
     -----
         if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
         --If Soft_Reset_op or slave Mode.Prevents SCK_O_reg to be generated in slave
            if((Rst_to_spi = RESET_ACTIVE)
              ) then
                 SCK_O_reg <= '0';
            elsif((pr_state_non_idle='0')-- or  -- dont allow sck to go out when
                  --(Mst_N_Slv = '0')
                  )then      -- SM is in IDLE state or core in slave mode
                 SCK_O_reg <= '0';
            else
                 SCK_O_reg <= sck_o_in;
            end if;
         end if;
     end process SCK_O_NQ_4_FINAL_PROCESS;
     -------------------------------------
    end generate SCK_O_NQ_4_STARTUP_USED;
    -------------------------------------
--end generate RATIO_NOT_EQUAL_4_GENERATE;
end generate RATIO_OF_2_GENERATE;
end architecture imp;
-------------------------------------------------------------------------------
