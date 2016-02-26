-------------------------------------------------------------------------------
--  qspi_core_interface Module - entity/architecture pair
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
-- Filename:        qspi_core_interface.vhd
-- Version:         v3.0
-- Description:     Serial Peripheral Interface (SPI) Module for interfacing
--                  with a 32-bit AXI bus.
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

Library UNISIM;
use UNISIM.vcomponents.all;

library axi_lite_ipif_v3_0_3;
use axi_lite_ipif_v3_0_3.axi_lite_ipif;
use axi_lite_ipif_v3_0_3.ipif_pkg.all;
library lib_fifo_v1_0_3;
    use lib_fifo_v1_0_3.async_fifo_fg;
library lib_srl_fifo_v1_0_2;
    use lib_srl_fifo_v1_0_2.srl_fifo_f;
	
library lib_cdc_v1_0_2;
	use lib_cdc_v1_0_2.cdc_sync;
library lib_pkg_v1_0_2;
    use lib_pkg_v1_0_2.all;
    use lib_pkg_v1_0_2.lib_pkg.log2;
   -- use lib_pkg_v1_0_2.lib_pkg.clog2;
    use lib_pkg_v1_0_2.lib_pkg.max2;
    use lib_pkg_v1_0_2.lib_pkg.RESET_ACTIVE;



library interrupt_control_v3_1_2;

library axi_quad_spi_v3_2_5;
    use axi_quad_spi_v3_2_5.all;
-------------------------------------------------------------------------------

entity qspi_core_interface is
generic(
        C_FAMILY              : string;
        C_SUB_FAMILY          : string;
        C_UC_FAMILY           : integer;
        C_S_AXI_DATA_WIDTH    : integer;
        Async_Clk             : integer;
        ----------------------
        -- local parameters
        C_NUM_CE_SIGNALS      : integer;
        ----------------------
        -- SPI parameters
        --C_AXI4_CLK_PS         : integer;
        --C_EXT_SPI_CLK_PS      : integer;
        C_FIFO_DEPTH          : integer;
        C_SCK_RATIO           : integer;
        C_NUM_SS_BITS         : integer;
        C_NUM_TRANSFER_BITS   : integer;
        C_SPI_MODE            : integer;
        C_USE_STARTUP         : integer;
        C_SPI_MEMORY          : integer;
        C_SHARED_STARTUP    : integer range 0 to 1 := 0;
        C_TYPE_OF_AXI4_INTERFACE : integer;
        ----------------------
        -- local constants
        C_FIFO_EXIST          : integer;
        C_SPI_NUM_BITS_REG    : integer;
        C_OCCUPANCY_NUM_BITS  : integer;
        ----------------------
        -- local constants
        C_IP_INTR_MODE_ARRAY  : INTEGER_ARRAY_TYPE;
        ----------------------
        -- local constants
        C_SPICR_REG_WIDTH     : integer;
        C_SPISR_REG_WIDTH     : integer;
        C_LSB_STUP            : integer
       );
   port(
        EXT_SPI_CLK      : in std_logic;
        ------------------------------------------------
        Bus2IP_Clk       : in std_logic;
        Bus2IP_Reset     : in std_logic;
        ------------------------------------------------
        Bus2IP_BE        : in std_logic_vector(0 to ((C_S_AXI_DATA_WIDTH/8)-1));
        Bus2IP_RdCE      : in std_logic_vector(0 to (C_NUM_CE_SIGNALS-1));
        Bus2IP_WrCE      : in std_logic_vector(0 to (C_NUM_CE_SIGNALS-1));
        Bus2IP_Data      : in std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));
        ------------------------------------------------
        IP2Bus_Data      : out std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));
        IP2Bus_WrAck     : out std_logic;
        IP2Bus_RdAck     : out std_logic;
        IP2Bus_Error     : out std_logic;
        ------------------------------------------------
        burst_tr         : in std_logic;
        rready           : in std_logic;
        WVALID           : in std_logic;
        --SPI Ports
        SCK_I            : in  std_logic;
        SCK_O            : out std_logic;
        SCK_T            : out std_logic;
        ------------------------------------------------
        IO0_I            : in  std_logic;
        IO0_O            : out std_logic;
        IO0_T            : out std_logic;
        ------------------------------------------------
        IO1_I            : in  std_logic;
        IO1_O            : out std_logic;
        IO1_T            : out std_logic;
        ------------------------------------------------
        IO2_I            : in  std_logic;
        IO2_O            : out std_logic;
        IO2_T            : out std_logic;
        ------------------------------------------------
        IO3_I            : in  std_logic;
        IO3_O            : out std_logic;
        IO3_T            : out std_logic;
        ------------------------------------------------
        SPISEL           : in  std_logic;
        ------------------------------------------------
        SS_I             : in  std_logic_vector((C_NUM_SS_BITS-1) downto C_LSB_STUP);
        SS_O             : out std_logic_vector((C_NUM_SS_BITS-1) downto C_LSB_STUP);
        SS_T             : out std_logic;
        ------------------------------------------------
        IP2INTC_Irpt     : out std_logic;
        ------------------------------------------------
	   ------------------------
	   -- STARTUP INTERFACE
	   ------------------------
	   cfgclk  : out std_logic;       -- FGCLK        , -- 1-bit output: Configuration main clock output
       cfgmclk : out std_logic; -- FGMCLK       , -- 1-bit output: Configuration internal oscillator clock output
       eos     : out std_logic;  -- OS           , -- 1-bit output: Active high output signal indicating the End Of Startup.
       preq    : out std_logic; -- REQ          , -- 1-bit output: PROGRAM request to fabric output
       di      : out std_logic_vector(1 downto 0); 	   -- output
       dts      : in std_logic_vector(1 downto 0); 	   -- input
       do      : in std_logic_vector(1 downto 0); 	   -- input
      -- fcsbo   : in std_logic;   -- input
      -- fcsbts  : in std_logic;   -- input
       clk     : in std_logic;   -- input
       gsr     : in std_logic;   -- input
       gts     : in std_logic;   -- input
       keyclearb : in std_logic;   -- input
       pack     : in std_logic;   -- input
       usrcclkts : in std_logic;   -- input
       usrdoneo : in std_logic;   -- input
       usrdonets : in std_logic   -- input
       );

end entity qspi_core_interface;

-------------------------------------------------------------------------------
------------
architecture imp of qspi_core_interface is
------------

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

-- function definition
----------------------
function clog2(x : positive) return natural is
  variable r  : natural := 0;
  variable rp : natural := 1; -- rp tracks the value 2**r
begin 
  while rp < x loop -- Termination condition T: x <= 2**r
    -- Loop invariant L: 2**(r-1) < x
    r := r + 1;
    if rp > integer'high - rp then exit; end if;  -- If doubling rp overflows
      -- the integer range, the doubled value would exceed x, so safe to exit.
    rp := rp + rp;
  end loop;
  -- L and T  <->  2**(r-1) < x <= 2**r  <->  (r-1) < log2(x) <= r
  return r; --
end clog2;

-------------------------------------------------------------------------------
-- constant definition

constant NEW_LOGIC : integer := 0;
-- These constants are indices into the "CE" arrays for the various registers.
 constant INTR_LO  : natural :=  0;
 constant INTR_HI  : natural := 15;
 constant SWRESET  : natural := 16;    -- at address C_BASEADDR + 40 h
 constant SPICR    : natural := 24; -- 17;    -- at address C_BASEADDR + 60 h
 constant SPISR    : natural := 25; -- 18;
 constant SPIDTR   : natural := 26; -- 19;
 constant SPIDRR   : natural := 27; -- 20;
 constant SPISSR   : natural := 28; -- 21;
 constant SPITFOR  : natural := 29; -- 22;
 constant SPIRFOR  : natural := 30; -- 23;    -- at address C_BASEADDR + 78 h

 constant REG_HOLE : natural := 31; -- 24;    -- at address C_BASEADDR + 7C h
 --Startup Signals
signal str_IO0_I : std_logic;
signal str_IO0_O : std_logic;
signal str_IO0_T : std_logic;
signal str_IO1_I : std_logic;
signal str_IO1_O : std_logic;
signal str_IO1_T : std_logic;
signal di_int  : std_logic_vector(3 downto 0); 	   -- output
signal di_int_sync  : std_logic_vector(3 downto 0); 	   -- output
signal dts_int : std_logic_vector(3 downto 0); 	   -- input
signal do_int  : std_logic_vector(3 downto 0); 	   -- input

 
 
 --SPI MODULE SIGNALS
 signal spiXfer_done_int         : std_logic;
 signal dtr_underrun_int         : std_logic;
 signal modf_strobe_int          : std_logic;
 signal slave_MODF_strobe_int    : std_logic;

 --OR REGISTER/FIFO SIGNALS
 --TO/FROM REG/FIFO DATA
 signal receive_Data_int       : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
 signal transmit_Data_int      : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));

 --Extra bit required for signal Register_Data_ctrl
 signal register_Data_cntrl_int :std_logic_vector(0 to (C_SPI_NUM_BITS_REG+1));
 signal register_Data_slvsel_int:std_logic_vector(0 to (C_NUM_SS_BITS-1));

 signal IP2Bus_SPICR_Data_int  :std_logic_vector(0 to (C_SPICR_REG_WIDTH-1));
 signal IP2Bus_SPISR_Data_int  :std_logic_vector(0 to (C_SPISR_REG_WIDTH-1));

 signal IP2Bus_Receive_Reg_Data_int :std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
 signal IP2Bus_Data_received_int:
                                  std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));
 signal IP2Bus_SPISSR_Data_int  : std_logic_vector(0 to (C_NUM_SS_BITS-1));
 signal IP2Bus_Tx_FIFO_OCC_Reg_Data_int:
                                std_logic_vector(0 to (C_OCCUPANCY_NUM_BITS-1));

 signal IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1:
                            std_logic_vector((C_OCCUPANCY_NUM_BITS-1) downto 0);
 signal IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1:
                            std_logic_vector((C_OCCUPANCY_NUM_BITS-1) downto 0);


 signal IP2Bus_Rx_FIFO_OCC_Reg_Data_int:
                                std_logic_vector(0 to (C_OCCUPANCY_NUM_BITS-1));

 --STATUS REGISTER SIGNALS
 signal sr_3_MODF_int            : std_logic;
 signal Tx_FIFO_Full_int         : std_logic;
 signal sr_5_Tx_Empty_int        : std_logic;
 signal tx_empty_signal_handshake_req        : std_logic;
 signal tx_empty_signal_handshake_gnt        : std_logic;
 signal sr_6_Rx_Full_int         : std_logic;
 signal Rc_FIFO_Empty_int        : std_logic;

 --RECEIVE AND TRANSMIT REGISTER SIGNALS
 signal drr_Overrun_int          : std_logic;
 signal dtr_Underrun_strobe_int  : std_logic;
 --FIFO SIGNALS
 signal rc_FIFO_Full_strobe_int  : std_logic;
 signal rc_FIFO_occ_Reversed_int :std_logic_vector
                                                ((C_OCCUPANCY_NUM_BITS-1) downto 0);
 signal rc_FIFO_occ_Reversed_int_2 :std_logic_vector
                                            ((C_OCCUPANCY_NUM_BITS-1) downto 0);

 signal rc_FIFO_Data_Out_int     : std_logic_vector
                                            (0 to (C_NUM_TRANSFER_BITS-1));

 signal sr_6_Rx_Full_int_1       : std_logic;
 signal FIFO_Empty_rx_1          : std_logic;
 signal FIFO_Empty_rx            : std_logic;

 signal data_Exists_RcFIFO_int   : std_logic;
 signal tx_FIFO_Empty_strobe_int : std_logic;
 signal tx_FIFO_occ_Reversed_int : std_logic_vector
                                            ((C_OCCUPANCY_NUM_BITS-1) downto 0);
 signal tx_FIFO_occ_Reversed_int_2 : std_logic_vector
                                            ((C_OCCUPANCY_NUM_BITS-1) downto 0);

 signal data_Exists_TxFIFO_int   : std_logic;
 signal data_Exists_TxFIFO_int_1 : std_logic;

 signal data_From_TxFIFO_int     : std_logic_vector
                                                 (0 to (C_NUM_TRANSFER_BITS-1));
 signal tx_FIFO_less_half_int    : std_logic;

 signal Tx_FIFO_Full_int_1       : std_logic;
 signal FIFO_Empty_tx            : std_logic;
 signal data_From_TxFIFO_int_1   : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));

 signal tx_occ_msb               : std_logic;
 signal tx_occ_msb_1             : std_logic:= '0';
 signal tx_occ_msb_2             : std_logic;
 signal tx_occ_msb_3             : std_logic;
 signal tx_occ_msb_4             : std_logic;

 signal reset_TxFIFO_ptr_int     : std_logic;
 signal reset_TxFIFO_ptr_int_to_spi     : std_logic;
 signal reset_RcFIFO_ptr_int     : std_logic;
 signal reset_RcFIFO_ptr_to_spi_clk : std_logic;
 signal ip2Bus_Data_Reg_int      : std_logic_vector
                                                  (0 to (C_S_AXI_DATA_WIDTH-1));
 signal ip2Bus_Data_occupancy_int: std_logic_vector
                                                  (0 to (C_S_AXI_DATA_WIDTH-1));
 signal ip2Bus_Data_SS_int       : std_logic_vector
                                                  (0 to (C_S_AXI_DATA_WIDTH-1));

 -- interface between signals on instance basis
 signal bus2IP_Reset_int         : std_logic;

 signal bus2IP_Data_for_interrupt_core  : std_logic_vector
                                                    (0 to C_S_AXI_DATA_WIDTH-1);

 signal ip2Bus_Error_int         : std_logic;
 signal ip2Bus_WrAck_int         : std_logic;-- := '0';
 signal ip2Bus_RdAck_int         : std_logic;-- := '0';
 signal ip2Bus_IntrEvent_int     : std_logic_vector
                                         (0 to (C_IP_INTR_MODE_ARRAY'length-1));
 signal transmit_ip2bus_error    : std_logic;
 signal receive_ip2bus_error     : std_logic;

 -- SOFT RESET SIGNALS
 signal reset2ip_reset_int       : std_logic;
 signal rst_ip2bus_wrack         : std_logic;
 signal rst_ip2bus_error         : std_logic;
 signal rst_ip2bus_rdack         : std_logic;

 -- INTERRUPT SIGNALS
 signal intr_ip2bus_data         : std_logic_vector
                                                  (0 to (C_S_AXI_DATA_WIDTH-1));
 signal intr_ip2bus_rdack        : std_logic;
 signal intr_ip2bus_wrack        : std_logic;
 signal intr_ip2bus_error        : std_logic;
 signal ip2bus_error_RdWr        : std_logic;
 --

 signal wr_ce_reduce_ack_gen: std_logic;
 --
 signal rd_ce_reduce_ack_gen     : std_logic;
 --
 signal control_bit_7_8_int      : std_logic_vector(0 to 1);
 signal spisel_pulse_o_int       : std_logic;
 signal Interrupt_WrCE_sig      : std_logic_vector(0 to 1);
 signal IPIF_Lvl_Interrupts_sig       : std_logic;
 signal spisel_d1_reg            : std_logic;
 signal Mst_N_Slv_mode           : std_logic;
-----
 signal bus2ip_intr_rdce         : std_logic_vector(INTR_LO to INTR_HI);
 signal bus2ip_intr_wrce         : std_logic_vector(INTR_LO to INTR_HI);

 signal ip2Bus_RdAck_intr_reg_hole      : std_logic;
 signal ip2Bus_RdAck_intr_reg_hole_d1   : std_logic;
 signal ip2Bus_WrAck_intr_reg_hole      : std_logic;
 signal ip2Bus_WrAck_intr_reg_hole_d1   : std_logic;
 signal intr_controller_rd_ce_or_reduce : std_logic;
 signal intr_controller_wr_ce_or_reduce : std_logic;

 signal wr_ce_or_reduce_core_cmb        : std_logic;
 signal ip2Bus_WrAck_core_reg_d1        : std_logic;
 signal ip2Bus_WrAck_core_reg           : std_logic;

 signal rd_ce_or_reduce_core_cmb        : std_logic;
 signal ip2Bus_RdAck_core_reg_d1        : std_logic;
 signal ip2Bus_RdAck_core_reg           : std_logic;

 signal SPISR_0_CMD_Error_int           : std_logic;
 signal SPISR_1_LOOP_Back_Error_int     : std_logic;
 signal SPISR_2_MSB_Error_int           : std_logic;
 signal SPISR_3_Slave_Mode_Error_int    : std_logic;
 signal SPISR_4_CPOL_CPHA_Error_int     : std_logic;
 signal SPISR_Ext_SPISEL_slave_int      : std_logic;

 signal SPICR_5_TXFIFO_RST_int          : std_logic;
-- signal SPICR_6_RXFIFO_RST_int          : std_logic;


 signal pr_state_idle_int              : std_logic;
 signal Quad_Phase_int                 : std_logic;

signal SPICR_0_LOOP_frm_axi      :std_logic;
signal SPICR_0_LOOP_to_spi       :std_logic;

signal SPICR_1_SPE_frm_axi       :std_logic;
signal SPICR_1_SPE_to_spi        :std_logic;

signal SPICR_2_MST_N_SLV_frm_axi :std_logic;
signal SPICR_2_MST_N_SLV_to_spi  :std_logic;

signal SPICR_3_CPOL_frm_axi      :std_logic;
signal SPICR_3_CPOL_to_spi       :std_logic;

signal SPICR_4_CPHA_frm_axi      :std_logic;
signal SPICR_4_CPHA_to_spi       :std_logic;

signal SPICR_5_TXFIFO_frm_axi    :std_logic;
signal SPICR_5_TXFIFO_to_spi     :std_logic;

--signal SPICR_6_RXFIFO_RST_frm_axi:std_logic;
--signal SPICR_6_RXFIFO_RST_to_spi :std_logic;

signal SPICR_7_SS_frm_axi        :std_logic;
signal SPICR_7_SS_to_spi         :std_logic;

signal SPICR_8_TR_INHIBIT_frm_axi:std_logic;
signal SPICR_8_TR_INHIBIT_to_spi :std_logic;

signal SPICR_9_LSB_frm_axi       :std_logic;
signal SPICR_9_LSB_to_spi        :std_logic;

signal SPICR_bits_7_8_frm_spi    :std_logic;
signal SPICR_bits_7_8_to_axi     :std_logic;

signal Rx_FIFO_Empty                  : std_logic;
signal rx_fifo_full_to_spi_clk        : std_logic;
signal tx_fifo_empty_to_axi_clk       : std_logic;
signal tx_fifo_full                   : std_logic;
signal spisel_d1_reg_to_axi_clk       : std_logic;
signal spicr_bits_7_8_frm_axi_clk     : std_logic_vector(1 downto 0);
signal spicr_8_tr_inhibit_to_spi_clk  : std_logic;
signal spicr_9_lsb_to_spi_clk         : std_logic;
signal spicr_bits_7_8_to_spi_clk      : std_logic_vector(0 to 1);
signal spicr_0_loop_frm_axi_clk       : std_logic;
signal spicr_1_spe_frm_axi_clk        : std_logic;
signal spicr_2_mst_n_slv_frm_axi_clk  : std_logic;
signal spicr_3_cpol_frm_axi_clk       : std_logic;
signal spicr_4_cpha_frm_axi_clk       : std_logic;
signal spicr_5_txfifo_rst_frm_axi_clk : std_logic;
signal spicr_6_rxfifo_rst_frm_axi_clk : std_logic;
signal spicr_7_ss_frm_axi_clk         : std_logic;
signal spicr_8_tr_inhibit_frm_axi_clk : std_logic;
signal spicr_9_lsb_frm_axi_clk        : std_logic;



signal Tx_FIFO_wr_ack_1 : std_logic;
signal rst_to_spi_int                 : std_logic;

signal spicr_0_loop_to_spi_clk        : std_logic;
signal spicr_1_spe_to_spi_clk         : std_logic;
signal spicr_2_mas_n_slv_to_spi_clk    : std_logic;
signal spicr_3_cpol_to_spi_clk        : std_logic;
signal spicr_4_cpha_to_spi_clk        : std_logic;
signal spicr_5_txfifo_rst_to_spi_clk   : std_logic;
signal spicr_6_rxfifo_rst_to_spi_clk   : std_logic;
signal spicr_7_ss_to_spi_clk          : std_logic;

signal sr_3_modf_to_spi_clk           : std_logic;
signal sr_3_modf_frm_axi_clk          : std_logic;

signal data_from_txfifo               : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));

signal Bus2IP_WrCE_d1 : std_logic;
signal Bus2IP_WrCE_d2 : std_logic;
signal Bus2IP_WrCE_d3 : std_logic;

signal Bus2IP_WrCE_pulse_1 : std_logic;
signal Bus2IP_WrCE_pulse_2 : std_logic;
signal Bus2IP_WrCE_pulse_3 : std_logic;


signal data_to_txfifo                 : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
signal tx_fifo_wr_ack                 : std_logic;
-- signal ext_spi_clk                 : std_logic;

signal tx_fifo_rd_ack_open            : std_logic;

signal tx_fifo_empty                  : std_logic;
signal tx_fifo_almost_full            : std_logic;
signal tx_fifo_almost_empty           : std_logic;
signal tx_fifo_occ_reversed           : std_logic_vector((C_OCCUPANCY_NUM_BITS-1) downto 0);
signal c_wr_count_width               : std_logic;


signal rx_fifo_wr_ack_open            : std_logic;
signal data_from_rx_fifo              : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
signal rx_fifo_rd_ack                 : std_logic;
signal rx_fifo_full                   : std_logic;

signal rx_fifo_almost_full            : std_logic;
signal rx_fifo_almost_empty           : std_logic;
signal rx_fifo_occ_reversed           : std_logic_vector((C_OCCUPANCY_NUM_BITS-1) downto 0);


signal SPISSR_frm_axi_clk : std_logic_vector(0 to (C_NUM_SS_BITS-1));
signal modf_strobe_frm_spi_clk : std_logic;
signal modf_strobe_to_axi_clk  : std_logic;
signal dtr_underrun_frm_spi_clk : std_logic;
signal dtr_underrun_to_axi_clk  : std_logic;

signal data_to_rx_fifo                : std_logic_vector
                                                 (0 to (C_NUM_TRANSFER_BITS-1));
signal spisel_d1_reg_frm_spi_clk : std_logic;

signal Mst_N_Slv_mode_frm_spi_clk: std_logic;
signal Mst_N_Slv_mode_to_axi_clk : std_logic;
signal SPICR_2_MST_N_SLV_to_spi_clk : std_logic;
signal spicr_5_txfifo_frm_axi_clk : std_logic;
signal spicr_5_txfifo_to_spi_clk: std_logic;
signal reset_RcFIFO_ptr_frm_axi_clk : std_logic;
-- signal reset_RcFIFO_ptr_to_spi_clk  : std_logic;
signal Data_To_Rx_FIFO_1    : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
signal SPIXfer_done_Rx_Wr_en, SPIXfer_done_rd_tx_en: std_logic;

signal Tx_FIFO_Empty_SPISR_frm_spi_clk : std_logic;
signal Tx_FIFO_Empty_SPISR_to_axi_clk  : std_logic;
signal Tx_FIFO_Empty_frm_spi_clk    : std_logic;
signal Rx_FIFO_Full_frm_axi_clk : std_logic;
signal Rx_FIFO_Full_int,Rx_FIFO_Full_i,RX_one_less_than_full, not_Tx_FIFO_FULL : std_logic;
signal updown_cnt_en_tx, updown_cnt_en_rx : std_logic;
signal TX_one_less_than_full : std_logic;
signal tx_cntr_xfer_done : std_logic;
   signal Tx_FIFO_one_less_to_Empty, Tx_FIFO_Full_i: std_logic;
   signal Tx_FIFO_Empty_i, Tx_FIFO_Empty_int : std_logic;
   signal Tx_FIFO_Empty_frm_axi_clk : std_logic;
   signal rx_fifo_empty_i : std_logic;
   signal Rx_FIFO_Empty_int : std_logic;
signal IP2Bus_WrAck_1 : std_logic;
signal ip2Bus_WrAck_core_reg_1 : std_logic;
signal IP2Bus_RdAck_1 : std_logic;
signal ip2Bus_RdAck_core_reg_1 : std_logic;
signal IP2Bus_Error_1 : std_logic;
signal ip2Bus_Data_1 : std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1)) ;

signal SPISR_0_CMD_Error_frm_spi_clk : std_logic;
signal SPISR_0_CMD_Error_to_axi_clk  : std_logic;

signal rx_fifo_reset, tx_fifo_reset : std_logic;
signal reg_hole_wr_ack: std_logic;
signal reg_hole_rd_ack: std_logic;

signal read_ack_delay_1: std_logic;
signal read_ack_delay_2: std_logic;
signal read_ack_delay_3: std_logic;
signal read_ack_delay_4: std_logic;
signal read_ack_delay_5: std_logic;
signal read_ack_delay_6: std_logic;
signal read_ack_delay_7: std_logic;
signal read_ack_delay_8: std_logic;

signal write_ack_delay_1: std_logic;
signal write_ack_delay_2: std_logic;
signal write_ack_delay_3: std_logic;
signal write_ack_delay_4: std_logic;
signal write_ack_delay_5: std_logic;
signal write_ack_delay_6: std_logic;
signal write_ack_delay_7: std_logic;
signal write_ack_delay_8: std_logic;

signal error_ack_delay_1: std_logic;
signal error_ack_delay_2: std_logic;
signal error_ack_delay_3: std_logic;
signal error_ack_delay_4: std_logic;
signal error_ack_delay_5: std_logic;
signal error_ack_delay_6: std_logic;
signal error_ack_delay_7: std_logic;
signal error_ack_delay_8: std_logic;
signal IO2_O_int  : std_logic;
signal IO2_T_int  : std_logic;

signal IO3_O_int  : std_logic;
signal IO3_T_int  : std_logic;
signal IO2_I_int  : std_logic;
signal IO3_I_int  : std_logic;
signal fcsbo_int  : std_logic;
signal SS_O_int  : std_logic_vector((C_NUM_SS_BITS-1) downto 0);
signal SS_T_int  : std_logic;
signal SS_I_int  : std_logic_vector((C_NUM_SS_BITS-1) downto 0);
signal fcsbts_int  : std_logic;
--------------------------------------------------------------------------------
begin
-----
DATA_STARTUP_EN : if (C_USE_STARTUP = 1 and C_UC_FAMILY = 1)
generate
   -----
    begin
   -----
---
    DI_INT_IO3_I_REG: component FD
     generic map
          (
          INIT => '0'
          )
     port map
          (
          Q  => di_int_sync(3),
          C  => EXT_SPI_CLK,
          D  => di_int(3) --MOSI_I
          );
     DI_INT_IO2_I_REG: component FD
     generic map
          (
          INIT => '0'
          )
     port map
          (
          Q  => di_int_sync(2),
          C  => EXT_SPI_CLK,
          D  => di_int(2) -- MISO_I
          );
     DI_INT_IO1_I_REG: component FD
       generic map
            (
            INIT => '0'
            )
       port map
            (
            Q  => di_int_sync(1),
            C  => EXT_SPI_CLK,
            D  => di_int(1)
            );
     -----------------------
     DI_INT_IO0_I_REG: component FD
       generic map
            (
            INIT => '0'
            )
       port map
            (
            Q  => di_int_sync(0),
            C  => EXT_SPI_CLK,
            D  => di_int(0)
            );
     
        
---
fcsbo_int <= SS_O_int(0);  
fcsbts_int <= SS_T_int;  
NUM_SS : if (C_NUM_SS_BITS = 1) generate
begin
SS_O <= (others => '0');
SS_T <= '0';
end generate NUM_SS;
NUM_SS_G1 : if (C_NUM_SS_BITS > 1) generate
begin

SS_I_int <= SS_I((C_NUM_SS_BITS-1) downto 1) & '1';
SS_O <= SS_O_int((C_NUM_SS_BITS-1) downto 1);
SS_T <= SS_T_int;

end generate NUM_SS_G1;
str_IO0_I <= di_int_sync(0);
do_int(0) <= str_IO0_O;
dts_int(0) <= str_IO0_T ;
str_IO1_I <= di_int_sync(1);
do_int(1) <= str_IO1_O;
dts_int(1) <= str_IO1_T;

DATA_OUT_NQUAD: if C_SPI_MODE = 0 or C_SPI_MODE = 1 generate
begin
di <= di_int_sync(3) & di_int_sync(2);
do_int(2) <= do(0);
do_int(3) <= do(1);
dts_int(2) <= dts(0);
dts_int(3) <= dts(1);
--do <= do_int(3) & do_int(1);
--dts <= dts_int(3) & dts_int(1);
end generate DATA_OUT_NQUAD;
DATA_OUT_QUAD: if C_SPI_MODE = 2 generate
begin
--di <= "00";--di_int_sync(3) & di_int_sync(2);
IO2_I_int <= di_int_sync(2);
do_int(2) <= IO2_O_int;--do(2);
do_int(3) <= IO3_O_int;--do(1);
--do <= do_int(3) & do_int(1);
IO3_I_int <= di_int_sync(3);
dts_int(2) <= IO2_T_int;--dts_int(3) & dts_int(1);
dts_int(3) <= IO3_T_int;--dts_int(3) & dts_int(1);
end generate DATA_OUT_QUAD;
end generate DATA_STARTUP_EN;

DATA_STARTUP_DIS : if (C_USE_STARTUP = 0 or (C_USE_STARTUP = 1 and C_UC_FAMILY = 0)) 
generate
   -----
    begin
   -----
str_IO0_I <= IO0_I;
IO0_O <= str_IO0_O;
IO0_T <= str_IO0_T;
str_IO1_I <= IO1_I;
IO1_O <= str_IO1_O;
IO1_T <= str_IO1_T;
fcsbo_int <= '0';  
fcsbts_int <= '0'; 
SS_O <= SS_O_int;  
SS_T <= SS_T_int;  
SS_I_int <= SS_I;
    end generate DATA_STARTUP_DIS;




-----------------------------------
-- Combinatorial operations for SPI
-----------------------------------
---- A write to read only register wont have any effect on register.
---- The transaction is completed by generating WrAck only.
not_Tx_FIFO_FULL <= not Tx_FIFO_Full;
Interrupt_WrCE_sig <= "00";
IPIF_Lvl_Interrupts_sig <= '0';

LEGACY_MD_WR_RD_ACK_GEN: if C_TYPE_OF_AXI4_INTERFACE = 0 generate
-----
begin
-----
-- A write to read only register wont have any effect on register.
-- The transaction is completed by generating WrAck only.
--------------------------------------------------------
-- IP2Bus_Error is generated under following conditions:
-- 1. If an full transmit register/FIFO is written into.
-- 2. If an empty receive register/FIFO is read from.
-- Due to software driver legacy, the register rule test is not applied to SPI.
--------------------------------------------------------
  IP2Bus_Error_1          <= intr_ip2bus_error   or
                           rst_ip2bus_error      or
                           transmit_ip2bus_error or
                           receive_ip2bus_error;
REG_ERR_ACK_P:process(Bus2IP_Clk)is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if (reset2ip_reset_int = RESET_ACTIVE) then
          IP2Bus_Error  <= '0';
      else
          IP2Bus_Error  <= IP2Bus_Error_1;
      end if;
    end if;
end process REG_ERR_ACK_P;
 wr_ce_or_reduce_core_cmb <= Bus2IP_WrCE(SPISR)  or -- read only register
                             Bus2IP_WrCE(SPIDRR) or -- read only register
                             (Bus2IP_WrCE(SPIDTR) and not_Tx_FIFO_FULL)  or -- common to
                                                    -- spi_fifo_ifmodule_1 and
                                                    -- spi_receive_reg_1
                                                    -- (FROM TRANSMITTER) module
                             Bus2IP_WrCE(SPICR)  or
                             Bus2IP_WrCE(SPISSR) or
                             Bus2IP_WrCE(SPITFOR)or -- locally generated
                             Bus2IP_WrCE(SPIRFOR)or -- locally generated
                             Bus2IP_WrCE(REG_HOLE) or -- register hole
                             or_reduce(Bus2IP_WrCE(17 to 23)); -- holes between reset end and start of SPICR register
--------------------------------------------------
WRITE_ACK_SPIDTR_REG_PROCESS: process(Bus2IP_Clk) is
---------------------------
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if (reset2ip_reset_int = RESET_ACTIVE) then
          Bus2IP_WrCE_d1 <= '0';
          Bus2IP_WrCE_d2 <= '0';
          Bus2IP_WrCE_d3 <= '0';
      else
          Bus2IP_WrCE_d1 <= Bus2IP_WrCE(SPIDTR);
          Bus2IP_WrCE_d2 <= Bus2IP_WrCE_d1;
          Bus2IP_WrCE_d3 <= Bus2IP_WrCE_d2;
      end if;   end if;
end process WRITE_ACK_SPIDTR_REG_PROCESS;

Bus2IP_WrCE_pulse_1 <= Bus2IP_WrCE(SPIDTR) and not Bus2IP_WrCE_d1;
Bus2IP_WrCE_pulse_2 <= Bus2IP_WrCE_d1 and not Bus2IP_WrCE_d2;
Bus2IP_WrCE_pulse_3 <= Bus2IP_WrCE_d2 and not Bus2IP_WrCE_d3;


--end generate WR_ACK_OR_REDUCE_FIFO_1_GEN;
-----------------------------------------


-- WRITE_ACK_CORE_REG_PROCESS   : The commong write ACK generation logic when FIFO is
-- ------------------------ not included in the design.
--------------------------------------------------
-- _____|-----|__________  wr_ce_or_reduce_fifo_no
-- ________|-----|_______  ip2Bus_WrAck_fifo_no_d1
-- ________|--|__________  ip2Bus_WrAck_fifo_no from common write ack register
--                         this ack will be used in register files for
--                         reference.
--------------------------------------------------
WRITE_ACK_CORE_REG_PROCESS: process(Bus2IP_Clk) is
---------------------------
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if (reset2ip_reset_int = RESET_ACTIVE) then
          ip2Bus_WrAck_core_reg_d1 <= '0';
          ip2Bus_WrAck_core_reg    <= '0';
          ip2Bus_WrAck_core_reg_1  <= '0';
      else
          ip2Bus_WrAck_core_reg_d1 <= wr_ce_or_reduce_core_cmb;
          ip2Bus_WrAck_core_reg   <= wr_ce_or_reduce_core_cmb and
                                                 (not ip2Bus_WrAck_core_reg_d1);
          ip2Bus_WrAck_core_reg_1  <= ip2Bus_WrAck_core_reg;
      end if;
    end if;
end process WRITE_ACK_CORE_REG_PROCESS;
-------------------------------------------------
-- internal logic uses this signal

wr_ce_reduce_ack_gen <= ip2Bus_WrAck_core_reg_1;
-------------------------------------------------
-- common WrAck to IPIF

IP2Bus_WrAck_1     <= intr_ip2bus_wrack          or -- common
                    rst_ip2bus_wrack           or -- common
                    ip2Bus_WrAck_intr_reg_hole or -- newly added to target the holes in register space
                    ip2Bus_WrAck_core_reg;--      or
                    --Tx_FIFO_wr_ack; -- newly added
REG_WR_ACK_P:process(Bus2IP_Clk)is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if (reset2ip_reset_int = RESET_ACTIVE) then
          IP2Bus_WrAck <= '0';
      else
          IP2Bus_WrAck <= IP2Bus_WrAck_1;
      end if;
    end if;
end process REG_WR_ACK_P;

-------------------------------------------------
--end generate LEGACY_MD_WR_ACK_GEN;
-------------------------------------------------
--LEGACY_MD_RD_ACK_GEN: if C_TYPE_OF_AXI4_INTERFACE = 0 generate
-----
--begin
-----
rd_ce_or_reduce_core_cmb <= Bus2IP_RdCE(SWRESET) or --common locally generated
                            Bus2IP_RdCE(SPIDTR)  or --common locally generated
                            Bus2IP_RdCE(SPISR)   or --common from status register
                            Bus2IP_RdCE(SPIDRR)  or --common to
                                                    --spi_fifo_ifmodule_1
                                                    --and spi_receive_reg_1
                                                    --(FROM RECEIVER) module
                            Bus2IP_RdCE(SPICR)   or --common spi_cntrl_reg_1
                            Bus2IP_RdCE(SPISSR)  or --common spi_status_reg_1
                            Bus2IP_RdCE(SPITFOR) or --only for fifo_occu TX reg
                            Bus2IP_RdCE(SPIRFOR) or --only for fifo_occu RX reg
                            Bus2IP_RdCE(REG_HOLE) or -- register hole
                             or_reduce(Bus2IP_RdCE(17 to 23)); -- holes between reset end and start of SPICR register;  --reg hole

-- READ_ACK_CORE_REG_PROCESS   : The commong write ACK generation logic
--------------------------------------------------
-- _____|-----|__________  wr_ce_or_reduce_fifo_no
-- ________|-----|_______  ip2Bus_WrAck_fifo_no_d1
-- ________|--|__________  ip2Bus_WrAck_fifo_no from common write ack register
--                         this ack will be used in register files for
--                         reference.
--------------------------------------------------
READ_ACK_CORE_REG_PROCESS: process(Bus2IP_Clk) is
-------------------
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if (reset2ip_reset_int = RESET_ACTIVE) then
           ip2Bus_RdAck_core_reg_d1 <= '0';
           ip2Bus_RdAck_core_reg    <= '0';
           ip2Bus_RdAck_core_reg_1  <= '0';
           read_ack_delay_1 <= '0';
	   read_ack_delay_2 <= '0';
	   read_ack_delay_3 <= '0';
	   read_ack_delay_4 <= '0';
	   read_ack_delay_5 <= '0';
	   read_ack_delay_6 <= '0';
	   read_ack_delay_7 <= '0';
        else
           --ip2Bus_RdAck_core_reg_d1 <= rd_ce_or_reduce_core_cmb;
           --ip2Bus_RdAck_core_reg    <= rd_ce_or_reduce_core_cmb and
           --                                      (not ip2Bus_RdAck_core_reg_d1);
	   read_ack_delay_1 <= rd_ce_or_reduce_core_cmb;
	   read_ack_delay_2 <= read_ack_delay_1;
	   read_ack_delay_3 <= read_ack_delay_2;
	   read_ack_delay_4 <= read_ack_delay_3;
	   read_ack_delay_5 <= read_ack_delay_4;
	   read_ack_delay_6 <= read_ack_delay_5;
	   read_ack_delay_7 <= read_ack_delay_6;
           
	   ip2Bus_RdAck_core_reg <= read_ack_delay_6 and (not read_ack_delay_7);
           ip2Bus_RdAck_core_reg_1  <= ip2Bus_RdAck_core_reg;
        end if;
    end if;
end process READ_ACK_CORE_REG_PROCESS;
-------------------------------------------------
-- internal logic uses this signal

rd_ce_reduce_ack_gen <= ip2Bus_RdAck_core_reg;
-------------------------------------------------
-- common RdAck to IPIF

IP2Bus_RdAck_1        <= intr_ip2bus_rdack          or      -- common
                         ip2Bus_RdAck_intr_reg_hole or
                         ip2Bus_RdAck_core_reg;

REG_RD_ACK_P:process(Bus2IP_Clk)is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if (reset2ip_reset_int = RESET_ACTIVE) then
          IP2Bus_RdAck <= '0';
      else
          IP2Bus_RdAck <= IP2Bus_RdAck_1;
      end if;
    end if;
end process REG_RD_ACK_P;
---------------------------------------------------
end generate LEGACY_MD_WR_RD_ACK_GEN;
-------------------------------------------------
ENHANCED_MD_WR_RD_ACK_GEN: if C_TYPE_OF_AXI4_INTERFACE = 1 generate
-----
begin
-----
-- A write to read only register wont have any effect on register.
-- The transaction is completed by generating WrAck only.
--------------------------------------------------------
-- IP2Bus_Error is generated under following conditions:
-- 1. If an full transmit register/FIFO is written into.
-- 2. If an empty receive register/FIFO is read from.
-- Due to software driver legacy, the register rule test is not applied to SPI.
--------------------------------------------------------
  IP2Bus_Error          <= intr_ip2bus_error   or
                           rst_ip2bus_error      or
                           transmit_ip2bus_error or
                           receive_ip2bus_error;

 wr_ce_or_reduce_core_cmb <= Bus2IP_WrCE(SPISR)  or -- read only register
                             Bus2IP_WrCE(SPIDRR) or -- read only register
                             (Bus2IP_WrCE(SPIDTR) and not_Tx_FIFO_FULL) or -- common to
                                                    -- spi_fifo_ifmodule_1 and
                                                    -- spi_receive_reg_1
                                                    -- (FROM TRANSMITTER) module
                             Bus2IP_WrCE(SPICR)  or
                             Bus2IP_WrCE(SPISSR) or
                             Bus2IP_WrCE(SPITFOR)or -- locally generated
                             Bus2IP_WrCE(SPIRFOR)or -- locally generated
                             Bus2IP_WrCE(REG_HOLE) or -- register hole
                             or_reduce(Bus2IP_WrCE(17 to 23)); -- holes between reset end and start of SPICR register; -- register hole

--------------------------------------------------
WRITE_ACK_SPIDTR_REG_PROCESS: process(Bus2IP_Clk) is
---------------------------
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if (reset2ip_reset_int = RESET_ACTIVE) then
          Bus2IP_WrCE_d1 <= '0';
          Bus2IP_WrCE_d2 <= '0';
          Bus2IP_WrCE_d3 <= '0';
      else
          Bus2IP_WrCE_d1 <= Bus2IP_WrCE(SPIDTR);
          Bus2IP_WrCE_d2 <= Bus2IP_WrCE_d1;
          Bus2IP_WrCE_d3 <= Bus2IP_WrCE_d2;
      end if;   end if;
end process WRITE_ACK_SPIDTR_REG_PROCESS;

Bus2IP_WrCE_pulse_1 <= Bus2IP_WrCE(SPIDTR) and not Bus2IP_WrCE_d1;
Bus2IP_WrCE_pulse_2 <= Bus2IP_WrCE_d1 and not Bus2IP_WrCE_d2;
Bus2IP_WrCE_pulse_3 <= Bus2IP_WrCE_d2 and not Bus2IP_WrCE_d3;



-- WRITE_ACK_CORE_REG_PROCESS   : The commong write ACK generation logic when FIFO is
-- ------------------------ not included in the design.
--------------------------------------------------
-- _____|-----|__________  wr_ce_or_reduce_fifo_no
-- ________|-----|_______  ip2Bus_WrAck_fifo_no_d1
-- ________|--|__________  ip2Bus_WrAck_fifo_no from common write ack register
--                         this ack will be used in register files for
--                         reference.
--------------------------------------------------
WRITE_ACK_CORE_REG_PROCESS: process(Bus2IP_Clk) is
---------------------------
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if (reset2ip_reset_int = RESET_ACTIVE) then
          ip2Bus_WrAck_core_reg_d1 <= '0';
          ip2Bus_WrAck_core_reg   <= '0';
          ip2Bus_WrAck_core_reg_1  <= '0';
      else
          ip2Bus_WrAck_core_reg_d1 <= wr_ce_or_reduce_core_cmb;
          ip2Bus_WrAck_core_reg   <= wr_ce_or_reduce_core_cmb and
                                                 (not ip2Bus_WrAck_core_reg_d1);
          ip2Bus_WrAck_core_reg_1  <= ip2Bus_WrAck_core_reg;
      end if;
    end if;
end process WRITE_ACK_CORE_REG_PROCESS;
-------------------------------------------------
-- internal logic uses this signal

wr_ce_reduce_ack_gen <= ip2Bus_WrAck_core_reg;--_1;
-------------------------------------------------
-- common WrAck to IPIF
-- in the enhanced mode for FIFO, the IP2bus_Wrack is provided by the enhanced mode statemachine only.
IP2Bus_WrAck      <= intr_ip2bus_wrack        or -- common
                    rst_ip2bus_wrack           or -- common
                    ip2Bus_WrAck_intr_reg_hole or -- newly added to target the holes in register space
                    (ip2Bus_WrAck_core_reg and (not burst_tr));-- or
                    --(Tx_FIFO_wr_ack and burst_tr); -- newly added

-------------------------------------------------

--ENHANCED_MD_RD_ACK_GEN: if C_TYPE_OF_AXI4_INTERFACE = 1 generate
-----
--begin
-----
FIFO_NO_RD_CE_GEN: if C_FIFO_EXIST = 0 generate
begin
rd_ce_or_reduce_core_cmb <= Bus2IP_RdCE(SWRESET) or --common locally generated
                            Bus2IP_RdCE(SPIDTR)  or --common locally generated
                            Bus2IP_RdCE(SPISR)   or --common from status register
                            Bus2IP_RdCE(SPIDRR)  or --common to
                                                    --spi_fifo_ifmodule_1
                                                    --and spi_receive_reg_1
                                                    --(FROM RECEIVER) module
                            Bus2IP_RdCE(SPICR)   or --common spi_cntrl_reg_1
                            Bus2IP_RdCE(SPISSR)  or --common spi_status_reg_1
                            Bus2IP_RdCE(SPITFOR) or --only for fifo_occu TX reg
                            Bus2IP_RdCE(SPIRFOR) or --only for fifo_occu RX reg
                            Bus2IP_RdCE(REG_HOLE) or -- register hole
                             or_reduce(Bus2IP_RdCE(17 to 23)); -- holes between reset end and start of SPICR register;  --reg hole
end generate FIFO_NO_RD_CE_GEN;

FIFO_YES_RD_CE_GEN: if C_FIFO_EXIST = 1 generate
begin
rd_ce_or_reduce_core_cmb <= Bus2IP_RdCE(SWRESET) or --common locally generated
                            Bus2IP_RdCE(SPIDTR)  or --common locally generated
                            Bus2IP_RdCE(SPISR)   or --common from status register
                            --Bus2IP_RdCE(SPIDRR)  or --common to
                                                    --spi_fifo_ifmodule_1
                                                    --and spi_receive_reg_1
                                                    --(FROM RECEIVER) module
                            Bus2IP_RdCE(SPICR)   or --common spi_cntrl_reg_1
                            Bus2IP_RdCE(SPISSR)  or --common spi_status_reg_1
                            Bus2IP_RdCE(SPITFOR) or --only for fifo_occu TX reg
                            Bus2IP_RdCE(SPIRFOR) or --only for fifo_occu RX reg
                            Bus2IP_RdCE(REG_HOLE) or -- register hole
                             or_reduce(Bus2IP_RdCE(17 to 23)); -- holes between reset end and start of SPICR register;  --reg hole
end generate FIFO_YES_RD_CE_GEN;

-- READ_ACK_CORE_REG_PROCESS   : The commong write ACK generation logic
--------------------------------------------------
-- _____|-----|__________  wr_ce_or_reduce_fifo_no
-- ________|-----|_______  ip2Bus_WrAck_fifo_no_d1
-- ________|--|__________  ip2Bus_WrAck_fifo_no from common write ack register
--                         this ack will be used in register files for
--                         reference.
--------------------------------------------------
READ_ACK_CORE_REG_PROCESS: process(Bus2IP_Clk) is
-------------------
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if (reset2ip_reset_int = RESET_ACTIVE) then
           ip2Bus_RdAck_core_reg_d1 <= '0';
           ip2Bus_RdAck_core_reg    <= '0';
           ip2Bus_RdAck_core_reg_1  <= '0';
           
	   read_ack_delay_1 <= '0';
	   read_ack_delay_2 <= '0';
	   read_ack_delay_3 <= '0';
	   read_ack_delay_4 <= '0';
	   read_ack_delay_5 <= '0';
	   read_ack_delay_6 <= '0';
	   read_ack_delay_7 <= '0';
        else
           --ip2Bus_RdAck_core_reg_d1 <= rd_ce_or_reduce_core_cmb;
           --ip2Bus_RdAck_core_reg    <= rd_ce_or_reduce_core_cmb and
           --                                      (not ip2Bus_RdAck_core_reg_d1);
           --ip2Bus_RdAck_core_reg_1  <= ip2Bus_RdAck_core_reg;
	   read_ack_delay_1 <= rd_ce_or_reduce_core_cmb;
	   read_ack_delay_2 <= read_ack_delay_1;
	   read_ack_delay_3 <= read_ack_delay_2;
	   read_ack_delay_4 <= read_ack_delay_3;
	   read_ack_delay_5 <= read_ack_delay_4;
	   read_ack_delay_6 <= read_ack_delay_5;
	   read_ack_delay_7 <= read_ack_delay_6;
           
	   ip2Bus_RdAck_core_reg <= read_ack_delay_6 and (not read_ack_delay_7);
           ip2Bus_RdAck_core_reg_1  <= ip2Bus_RdAck_core_reg;
        end if;
    end if;
end process READ_ACK_CORE_REG_PROCESS;
-------------------------------------------------
-- internal logic uses this signal

rd_ce_reduce_ack_gen <= ip2Bus_RdAck_core_reg; --_1;
-------------------------------------------------

-- common RdAck to IPIF

IP2Bus_RdAck         <= intr_ip2bus_rdack          or      -- common
                        ip2Bus_RdAck_intr_reg_hole or
                        ip2Bus_RdAck_core_reg or
                        (Rx_FIFO_rd_ack and rready);
-----------------------------------------------------
end generate ENHANCED_MD_WR_RD_ACK_GEN;
-------------------------------------------------
--=============================================================================
TX_FIFO_OCC_DATA_FIFO_16: if  C_FIFO_DEPTH = 16 generate
-------------------------
begin
-----
     IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1(0) <= IP2Bus_Tx_FIFO_OCC_Reg_Data_int(0)
                                             and not (Tx_FIFO_Empty_SPISR_to_axi_clk); -- (Tx_FIFO_Empty);
     IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1(1) <= IP2Bus_Tx_FIFO_OCC_Reg_Data_int(1)
                                             and not (Tx_FIFO_Empty_SPISR_to_axi_clk); --  (Tx_FIFO_Empty);
     IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1(2) <= IP2Bus_Tx_FIFO_OCC_Reg_Data_int(2)
                                             and not (Tx_FIFO_Empty_SPISR_to_axi_clk); --  (Tx_FIFO_Empty);
     IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1(3) <= IP2Bus_Tx_FIFO_OCC_Reg_Data_int(3)
                                             and not (Tx_FIFO_Empty_SPISR_to_axi_clk); --  (Tx_FIFO_Empty); --(FIFO_Empty_tx);

     IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1(0) <= IP2Bus_Rx_FIFO_OCC_Reg_Data_int(0)
                                             and not (Rx_FIFO_Empty);
     IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1(1) <= IP2Bus_Rx_FIFO_OCC_Reg_Data_int(1)
                                             and not (Rx_FIFO_Empty);
     IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1(2) <= IP2Bus_Rx_FIFO_OCC_Reg_Data_int(2)
                                             and not (Rx_FIFO_Empty);
     IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1(3) <= IP2Bus_Rx_FIFO_OCC_Reg_Data_int(3)
                                             and not (Rx_FIFO_Empty); --(FIFO_Empty_rx);

end generate TX_FIFO_OCC_DATA_FIFO_16;
--------------------------------------
TX_FIFO_OCC_DATA_FIFO_256: if  C_FIFO_DEPTH = 256 generate
-------------------------
begin
-----
     IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1(0) <= IP2Bus_Tx_FIFO_OCC_Reg_Data_int(0)
                                             and not  (Tx_FIFO_Empty_SPISR_to_axi_clk); -- (Tx_FIFO_Empty);
     IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1(1) <= IP2Bus_Tx_FIFO_OCC_Reg_Data_int(1)
                                             and not  (Tx_FIFO_Empty_SPISR_to_axi_clk); -- (Tx_FIFO_Empty);
     IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1(2) <= IP2Bus_Tx_FIFO_OCC_Reg_Data_int(2)
                                             and not  (Tx_FIFO_Empty_SPISR_to_axi_clk); -- (Tx_FIFO_Empty);
     IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1(3) <= IP2Bus_Tx_FIFO_OCC_Reg_Data_int(3)
                                             and not  (Tx_FIFO_Empty_SPISR_to_axi_clk); -- (Tx_FIFO_Empty);

     IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1(4) <= IP2Bus_Tx_FIFO_OCC_Reg_Data_int(4)
                                             and not  (Tx_FIFO_Empty_SPISR_to_axi_clk); -- (Tx_FIFO_Empty);
     IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1(5) <= IP2Bus_Tx_FIFO_OCC_Reg_Data_int(5)
                                             and not  (Tx_FIFO_Empty_SPISR_to_axi_clk); -- (Tx_FIFO_Empty);
     IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1(6) <= IP2Bus_Tx_FIFO_OCC_Reg_Data_int(6)
                                             and not  (Tx_FIFO_Empty_SPISR_to_axi_clk); -- (Tx_FIFO_Empty);
     IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1(7) <= IP2Bus_Tx_FIFO_OCC_Reg_Data_int(7)
                                             and not  (Tx_FIFO_Empty_SPISR_to_axi_clk); -- (Tx_FIFO_Empty);-- (FIFO_Empty_tx);

     IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1(0) <= IP2Bus_Rx_FIFO_OCC_Reg_Data_int(0)
                                             and not (Rx_FIFO_Empty);
     IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1(1) <= IP2Bus_Rx_FIFO_OCC_Reg_Data_int(1)
                                             and not (Rx_FIFO_Empty);
     IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1(2) <= IP2Bus_Rx_FIFO_OCC_Reg_Data_int(2)
                                             and not (Rx_FIFO_Empty);
     IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1(3) <= IP2Bus_Rx_FIFO_OCC_Reg_Data_int(3)
                                             and not (Rx_FIFO_Empty);

     IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1(4) <= IP2Bus_Rx_FIFO_OCC_Reg_Data_int(4)
                                             and not (Rx_FIFO_Empty);
     IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1(5) <= IP2Bus_Rx_FIFO_OCC_Reg_Data_int(5)
                                             and not (Rx_FIFO_Empty);
     IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1(6) <= IP2Bus_Rx_FIFO_OCC_Reg_Data_int(6)
                                             and not (Rx_FIFO_Empty);
     IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1(7) <= IP2Bus_Rx_FIFO_OCC_Reg_Data_int(7)
                                             and not (Rx_FIFO_Empty); --(FIFO_Empty_rx);

end generate TX_FIFO_OCC_DATA_FIFO_256;

--*****************************************************************************
ip2Bus_Data_occupancy_int(0 to (C_S_AXI_DATA_WIDTH-C_OCCUPANCY_NUM_BITS-1))
                         <= (others => '0');

ip2Bus_Data_occupancy_int((C_S_AXI_DATA_WIDTH-C_OCCUPANCY_NUM_BITS)
                                         to (C_S_AXI_DATA_WIDTH-1))
                         <= IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1 or
                            IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1;

-------------------------------------------------------------------------------
-- SPECIAL_CASE_WHEN_SS_NOT_EQL_32 : The Special case is executed whenever
--                                   C_NUM_SS_BITS is less than 32
-------------------------------------------------------------------------------

  SPECIAL_CASE_WHEN_SS_NOT_EQL_32: if(C_NUM_SS_BITS /= 32) generate
  -----
  begin
  -----
     ip2Bus_Data_SS_int(0 to (C_S_AXI_DATA_WIDTH-C_NUM_SS_BITS-1))
                                                 <= (others => '0');
  end generate SPECIAL_CASE_WHEN_SS_NOT_EQL_32;
  ---------------------------------------------

  ip2Bus_Data_SS_int((C_S_AXI_DATA_WIDTH-C_NUM_SS_BITS) to
                     (C_S_AXI_DATA_WIDTH-1)) <= IP2Bus_SPISSR_Data_int;

-------------------------------------------------------------------------------
  ip2Bus_Data_Reg_int(0 to C_S_AXI_DATA_WIDTH-C_SPISR_REG_WIDTH-1) <= (others => '0');
  ip2Bus_Data_Reg_int(C_S_AXI_DATA_WIDTH-C_SPISR_REG_WIDTH to C_S_AXI_DATA_WIDTH-1)
                                 <= IP2Bus_SPISR_Data_int or        -- SPISR - 11 bit
                                    ('0' & IP2Bus_SPICR_Data_int);  -- SPICR - 10 bit
-------------------------------------------------------------------------------
  -----------------------
  Receive_Reg_width_is_32: if(C_NUM_TRANSFER_BITS = 32) generate
  -----------------------
  begin
  -----

      IP2Bus_Data_received_int <= IP2Bus_Receive_Reg_Data_int;

  end generate Receive_Reg_width_is_32;
  -----------------------------------------

  ---------------------------
  Receive_Reg_width_is_not_32: if(C_NUM_TRANSFER_BITS /= 32) generate
  ---------------------------
  begin
  -----
      IP2Bus_Data_received_int(0 to C_S_AXI_DATA_WIDTH-C_NUM_TRANSFER_BITS-1)
                                                             <= (others => '0');
      IP2Bus_Data_received_int((C_S_AXI_DATA_WIDTH-C_NUM_TRANSFER_BITS) to
                               (C_S_AXI_DATA_WIDTH-1))
                                                 <= IP2Bus_Receive_Reg_Data_int;

  end generate Receive_Reg_width_is_not_32;
  -----------------------------------------
-------------------------------------------------------------------------------
LEGACY_MD_IP2BUS_DATA_GEN: if C_TYPE_OF_AXI4_INTERFACE = 0 generate
-----
begin
-----
  ip2Bus_Data_1      <= ip2Bus_Data_occupancy_int or -- occupancy reg data
                      ip2Bus_Data_SS_int        or -- Slave select reg data
                      ip2Bus_Data_Reg_int       or -- SPI CR & SR reg data
                      IP2Bus_Data_received_int  or -- SPI received data
                      intr_ip2bus_data          ;

REG_IP2BUS_DATA_P:process(Bus2IP_Clk)is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if (reset2ip_reset_int = RESET_ACTIVE) then
          ip2Bus_Data <= (others => '0');
      else
          ip2Bus_Data <= ip2Bus_Data_1;
      end if;
    end if;

end process REG_IP2BUS_DATA_P;
end generate LEGACY_MD_IP2BUS_DATA_GEN;
-------------------------------------------------------------------------------
ENHANCED_MD_IP2BUS_DATA_GEN: if C_TYPE_OF_AXI4_INTERFACE = 1 generate
-----
begin
-----
  ip2Bus_Data      <= ip2Bus_Data_occupancy_int or -- occupancy reg data
                      ip2Bus_Data_SS_int        or -- Slave select reg data
                      ip2Bus_Data_Reg_int       or -- SPI CR & SR reg data
                      IP2Bus_Data_received_int  or -- SPI received data
                      intr_ip2bus_data          ;

end generate ENHANCED_MD_IP2BUS_DATA_GEN;

-------------------------------------------------------------------------------

RESET_SYNC_AXI_SPI_CLK_INST:entity axi_quad_spi_v3_2_5.reset_sync_module
               port map(
                         EXT_SPI_CLK        => EXT_SPI_CLK        ,-- in std_logic;
                         --Bus2IP_Clk         => Bus2IP_Clk         ,-- in std_logic;
                         Soft_Reset_frm_axi => reset2ip_reset_int,-- in std_logic;
                         Rst_to_spi         => Rst_to_spi_int -- out std_logic;
               );

--------------------------------------
-- NO_FIFO_EXISTS : Signals initialisation and module
--                                     instantiation when C_FIFO_EXIST = 0
--------------------------------------

NO_FIFO_EXISTS: if(C_FIFO_EXIST = 0) generate
----------------------------------
signal spisel_pulse_frm_spi_clk : std_logic;
signal spisel_pulse_to_axi_clk  : std_logic;
signal spiXfer_done_frm_spi_clk : std_logic;
signal spiXfer_done_to_axi_clk  : std_logic;
signal modf_strobe_frm_spi_clk  : std_logic;
-- signal modf_strobe_to_axi_clk   : std_logic;
signal slave_MODF_strobe_frm_spi_clk : std_logic;
signal slave_MODF_strobe_to_axi_clk  : std_logic;
signal receive_data_frm_spi_clk : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
signal receive_data_to_axi_clk  : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
signal transmit_Data_frm_axi_clk: std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
signal transmit_Data_to_spi_clk : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
signal transmit_Data_fifo_0     : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
signal drr_Overrun_int_frm_spi_clk: std_logic;
signal drr_Overrun_int_to_axi_clk : std_logic;
-----
begin
-----
     Rx_FIFO_rd_ack <= '0';
     Tx_FIFO_Full    <= '0';
     --------------------------------------------------------------------------
     -- I_RECEIVE_REG : INSTANTIATE RECEIVE REGISTER
     --------------------------------------------------------------------------

     QSPI_RX_TX_REG: entity axi_quad_spi_v3_2_5.qspi_receive_transmit_reg
     generic map
           (
             C_S_AXI_DATA_WIDTH      => C_S_AXI_DATA_WIDTH,
             C_NUM_TRANSFER_BITS     => C_NUM_TRANSFER_BITS
            )
     port map
            (
             Bus2IP_Clk              => Bus2IP_Clk,                             -- in
             Soft_Reset_op           => reset2ip_reset_int,                     -- in
             --SPI Receiver signals -- From AXI clock
             Bus2IP_Receive_Reg_RdCE => Bus2IP_RdCE(SPIDRR),                    -- in
             Receive_ip2bus_error    => receive_ip2bus_error,                   -- out
             IP2Bus_Receive_Reg_Data => IP2Bus_Receive_Reg_Data_int,            -- out
             --SPI module ports From SPI clock
             SPIXfer_done            => spiXfer_done_to_axi_clk,--spiXfer_done_int,-- in
             SPI_Received_Data       => receive_data_to_axi_clk,--receive_Data_int,-- in vec
             -- receive & transmit reg signals
             -- DRR_Overrun             => drr_Overrun_int,-- drr_Overrun_int,-- out
             SR_7_Rx_Empty           => Rx_FIFO_Empty_i,                          -- out
             -- From AXI clock
             Bus2IP_Transmit_Reg_Data=> Bus2IP_Data,                            -- in vec
             Bus2IP_Transmit_Reg_WrCE=> Bus2IP_WrCE(SPIDTR),                    -- in
             Wr_ce_reduce_ack_gen    => wr_ce_reduce_ack_gen,                   -- in
             Rd_ce_reduce_ack_gen    => rd_ce_reduce_ack_gen,                   -- in
             --SPI Transmitter signals from AXI clock
             Transmit_ip2bus_error   => transmit_ip2bus_error,                  -- out
             --SPI module ports
             DTR_underrun            => dtr_underrun_to_axi_clk,--dtr_underrun_int,-- in
             SR_5_Tx_Empty           => sr_5_Tx_Empty_int,                      -- out
             tx_empty_signal_handshake_req           => tx_empty_signal_handshake_req,                      -- out
             tx_empty_signal_handshake_gnt           => tx_empty_signal_handshake_gnt,                      -- in
             DTR_Underrun_strobe     => dtr_Underrun_strobe_int,                -- out
             Transmit_Reg_Data_Out   => transmit_Data_fifo_0--transmit_Data_int -- out vec
     );

     spisel_d1_reg_frm_spi_clk     <= spisel_d1_reg;
     spisel_pulse_frm_spi_clk      <= spisel_pulse_o_int;-- from SPI module
     spiXfer_done_frm_spi_clk      <= spiXfer_done_int  ;-- from SPI module
     modf_strobe_frm_spi_clk       <= modf_strobe_int   ;-- from SPI module
     slave_MODF_strobe_frm_spi_clk <= slave_MODF_strobe_int;-- from SPI module
     receive_data_frm_spi_clk      <= Data_To_Rx_FIFO ; -- from SPI module
     dtr_underrun_frm_spi_clk      <= dtr_underrun_int;  -- from SPI module

     transmit_Data_frm_axi_clk     <= transmit_Data_fifo_0; -- From AXI clock

     Tx_FIFO_Empty_frm_axi_clk     <= sr_5_Tx_Empty_int;
     Tx_FIFO_Empty_SPISR_frm_spi_clk <= sr_5_Tx_Empty_int;
     --Rx_FIFO_Empty_int           <= Rx_FIFO_Empty;

     Rx_FIFO_Empty_int             <= Rx_FIFO_Empty_i;
     drr_Overrun_int_frm_spi_clk   <= drr_Overrun_int;

     SR_3_modf_frm_axi_clk         <= SR_3_modf_int;

     CROSS_CLK_FIFO_0_INST:entity axi_quad_spi_v3_2_5.cross_clk_sync_fifo_0
     generic map(
                 C_NUM_TRANSFER_BITS    => C_NUM_TRANSFER_BITS,
                 Async_Clk              => Async_Clk          ,
                 --C_AXI_SPI_CLK_EQ_DIFF  => C_AXI_SPI_CLK_EQ_DIFF,
                         C_NUM_SS_BITS => C_NUM_SS_BITS
                 )
     port map(
              EXT_SPI_CLK               => EXT_SPI_CLK,
              Bus2IP_Clk                => Bus2IP_Clk ,
              Soft_Reset_op             => reset2ip_reset_int,
              Rst_from_axi_cdc_to_spi       => Rst_to_spi_int,                       -- out std_logic;
              ----------------------------------------------------------
              tx_empty_signal_handshake_req     => tx_empty_signal_handshake_req,
              tx_empty_signal_handshake_gnt     => tx_empty_signal_handshake_gnt,
              Tx_FIFO_Empty_cdc_from_axi     => Tx_FIFO_Empty_frm_axi_clk,
              Tx_FIFO_Empty_cdc_to_spi      => Tx_FIFO_Empty,
              ----------------------------------------------------------
              Tx_FIFO_Empty_SPISR_cdc_from_spi => Tx_FIFO_Empty_SPISR_frm_spi_clk,
              Tx_FIFO_Empty_SPISR_cdc_to_axi  => Tx_FIFO_Empty_SPISR_to_axi_clk,
              ----------------------------------------------------------
              spisel_d1_reg_cdc_from_spi     => spisel_d1_reg_frm_spi_clk  , -- in
              spisel_d1_reg_cdc_to_axi      => spisel_d1_reg_to_axi_clk   , -- out
              ----------------------------------------------------------
              spisel_pulse_cdc_from_spi      => spisel_pulse_frm_spi_clk   , -- in
              spisel_pulse_cdc_to_axi       => spisel_pulse_to_axi_clk    , -- out
              ----------------------------------------------------------
              spiXfer_done_cdc_from_spi      => spiXfer_done_frm_spi_clk   , -- in
              spiXfer_done_cdc_to_axi       => spiXfer_done_to_axi_clk    , -- out
              ----------------------------------------------------------
              modf_strobe_cdc_from_spi       => modf_strobe_frm_spi_clk, -- in
              modf_strobe_cdc_to_axi        => modf_strobe_to_axi_clk , -- out
              ----------------------------------------------------------
              Slave_MODF_strobe_cdc_from_spi => slave_MODF_strobe_frm_spi_clk,-- in
              Slave_MODF_strobe_cdc_to_axi  => slave_MODF_strobe_to_axi_clk ,-- out
              ----------------------------------------------------------
              receive_Data_cdc_from_spi      => receive_Data_frm_spi_clk, -- in
              receive_Data_cdc_to_axi       => receive_data_to_axi_clk, -- out
              ----------------------------------------------------------
              drr_Overrun_int_cdc_from_spi   => drr_Overrun_int_frm_spi_clk, -- in
              drr_Overrun_int_cdc_to_axi    => drr_Overrun_int_to_axi_clk,  -- out
              ----------------------------------------------------------
              dtr_underrun_cdc_from_spi      => dtr_underrun_frm_spi_clk, -- in
              dtr_underrun_cdc_to_axi       => dtr_underrun_to_axi_clk,  -- out
              ----------------------------------------------------------
              transmit_Data_cdc_from_axi     => transmit_Data_frm_axi_clk, -- in
              transmit_Data_cdc_to_spi      => transmit_Data_to_spi_clk,   -- out
              ----------------------------
              SPICR_0_LOOP_cdc_from_axi      => SPICR_0_LOOP_frm_axi_clk,-- in std_logic;
              SPICR_0_LOOP_cdc_to_spi       => SPICR_0_LOOP_to_spi_clk ,-- out
              ----------------------------
              SPICR_1_SPE_cdc_from_axi       => SPICR_1_SPE_frm_axi_clk ,-- in std_logic;
              SPICR_1_SPE_cdc_to_spi        => SPICR_1_SPE_to_spi_clk  ,-- out
              ----------------------------
              SPICR_2_MST_N_SLV_cdc_from_axi => SPICR_2_MST_N_SLV_frm_axi_clk,-- in std_logic;
              SPICR_2_MST_N_SLV_cdc_to_spi  => SPICR_2_MST_N_SLV_to_spi_clk, -- out
              ----------------------------
              SPICR_3_CPOL_cdc_from_axi      => SPICR_3_CPOL_frm_axi_clk,-- in std_logic;
              SPICR_3_CPOL_cdc_to_spi       => SPICR_3_CPOL_to_spi_clk ,-- out
              ----------------------------
              SPICR_4_CPHA_cdc_from_axi      => SPICR_4_CPHA_frm_axi_clk,-- in std_logic;
              SPICR_4_CPHA_cdc_to_spi       => SPICR_4_CPHA_to_spi_clk ,-- out
              ----------------------------
              SPICR_5_TXFIFO_cdc_from_axi    => SPICR_5_TXFIFO_frm_axi_clk,-- in std_logic;
              SPICR_5_TXFIFO_cdc_to_spi     => SPICR_5_TXFIFO_to_spi_clk,  -- out
              ----------------------------
              SPICR_6_RXFIFO_RST_cdc_from_axi=> SPICR_6_RXFIFO_RST_frm_axi_clk,-- in std_logic;
              SPICR_6_RXFIFO_RST_cdc_to_spi => SPICR_6_RXFIFO_RST_to_spi_clk ,-- out
              ----------------------------
              SPICR_7_SS_cdc_from_axi        => SPICR_7_SS_frm_axi_clk ,-- in std_logic;
              SPICR_7_SS_cdc_to_spi         => SPICR_7_SS_to_spi_clk ,-- out
              ----------------------------
              SPICR_8_TR_INHIBIT_cdc_from_axi=> SPICR_8_TR_INHIBIT_frm_axi_clk,-- in std_logic;
              SPICR_8_TR_INHIBIT_cdc_to_spi => SPICR_8_TR_INHIBIT_to_spi_clk,-- out
              ----------------------------
              SPICR_9_LSB_cdc_from_axi       => SPICR_9_LSB_frm_axi_clk,-- in std_logic;
              SPICR_9_LSB_cdc_to_spi        => SPICR_9_LSB_to_spi_clk,-- out
              ----------------------------
              SPICR_bits_7_8_cdc_from_axi    => SPICR_bits_7_8_frm_axi_clk,-- in std_logic_vector
              SPICR_bits_7_8_cdc_to_spi     => SPICR_bits_7_8_to_spi_clk,-- out
              ----------------------------
              SR_3_modf_cdc_from_axi         => SR_3_modf_frm_axi_clk, -- in
              SR_3_modf_cdc_to_spi          => SR_3_modf_to_spi_clk , -- out
              ----------------------------
              SPISSR_cdc_from_axi            => SPISSR_frm_axi_clk, -- in
              SPISSR_cdc_to_spi             => register_Data_slvsel_int -- out
              ----------------------------
     );
     Data_From_TxFIFO <= transmit_Data_to_spi_clk;

     rc_FIFO_Full_strobe_int      <= '0';
     rc_FIFO_occ_Reversed_int     <= (others => '0');
     rc_FIFO_Data_Out_int         <= (others => '0');
     data_Exists_RcFIFO_int       <= '0';
     tx_FIFO_Empty_strobe_int     <= '0';
     tx_FIFO_occ_Reversed_int     <= (others => '0');
     data_Exists_TxFIFO_int       <= '0';
     data_From_TxFIFO_int         <= (others => '0');
     tx_FIFO_less_half_int        <= '0';
     reset_TxFIFO_ptr_int         <= '0';
     reset_RcFIFO_ptr_int         <= '0';
     IP2Bus_Rx_FIFO_OCC_Reg_Data_int_1  <= (others => '0');
     IP2Bus_Tx_FIFO_OCC_Reg_Data_int_1  <= (others => '0');

     Tx_FIFO_Full_int                 <= not(sr_5_Tx_Empty_int); -- Tx_FIFO_Empty_to_axi_clk);
     Rx_FIFO_Full_int             <= not(Rx_FIFO_Empty_i);
     --------------------------------------------------------------------------

     bus2IP_Data_for_interrupt_core(0 to 14) <= Bus2IP_Data(0 to 14);

     bus2IP_Data_for_interrupt_core(15 to 22) <= (others => '0');

     -- below code manipulates the bus2ip_data going towards interrupt control
     -- unit. In FIFO=0, case bit 23 and 25 of IPIER are not applicable.

     -- Bu2IP Data to Interrupt Registers - IPISR and IPIER
     -- Bus2IP_Data - 0                 31
     -- IPISR/IPIER - 0        22 23    31
     --                <---NA---> <-used->
     --                           23        24          25         26       27   28       29    30    31
     --                           DRR_Not   Slave       Tx_FIFO    DRR_     DRR_ DTR_     DTR   Slave MODF
     --                           _Empty    Select_mode Half_Empty Over_Run Full Underrun Empty MODF
     --                           NA-fifo-0             NA -fifo-0

     bus2IP_Data_for_interrupt_core(23)      <= '0'; -- DRR_Not_Empty bit in IPIER/IPISR
     bus2IP_Data_for_interrupt_core(24)      <= Bus2IP_Data(24);
     bus2IP_Data_for_interrupt_core(25)      <= '0'; -- Tx FIFO Half Empty
     bus2IP_Data_for_interrupt_core(26 to (C_S_AXI_DATA_WIDTH-1)) <=
                                      Bus2IP_Data(26 to (C_S_AXI_DATA_WIDTH-1));
     --------------------------------------------------------------------------

     -- Interrupt Status Register(IPISR) Mapping
     ip2Bus_IntrEvent_int(13)     <= '0'; -- doesnt exist in the FIFO = 0 case
     ip2Bus_IntrEvent_int(12)     <= '0'; -- doesnt exist in the FIFO = 0 case
     ip2Bus_IntrEvent_int(11)     <= '0'; -- doesnt exist in the FIFO = 0 case
     ip2Bus_IntrEvent_int(10)     <= '0'; -- doesnt exist in the FIFO = 0 case
     ip2Bus_IntrEvent_int(9)      <= '0'; -- doesnt exist in the FIFO = 0 case
     ip2Bus_IntrEvent_int(8)      <= '0'; -- doesnt exist in the FIFO = 0 case
     ip2Bus_IntrEvent_int(7)      <= spisel_pulse_to_axi_clk;      -- spisel_pulse_o_int;
     ip2Bus_IntrEvent_int(6)      <= '0'; --
     ip2Bus_IntrEvent_int(5)      <= drr_Overrun_int_to_axi_clk; -- drr_Overrun_int_to_axi_clk;
     ip2Bus_IntrEvent_int(4)      <= spiXfer_done_to_axi_clk;      -- spiXfer_done_int;
     ip2Bus_IntrEvent_int(3)      <= dtr_Underrun_strobe_int;
     ip2Bus_IntrEvent_int(2)      <= spiXfer_done_to_axi_clk;      -- spiXfer_done_int;
     ip2Bus_IntrEvent_int(1)      <= slave_MODF_strobe_to_axi_clk; -- slave_MODF_strobe_int;
     ip2Bus_IntrEvent_int(0)      <= modf_strobe_to_axi_clk;       -- modf_strobe_int;



end generate NO_FIFO_EXISTS;

-------------------------------------------------------------------------------
-- FIFO_EXISTS : Signals initialisation and module
--                                  instantiation when C_FIFO_EXIST = 1
-------------------------------------------------------------------------------
FIFO_EXISTS: if(C_FIFO_EXIST = 1) generate
------------------------------
constant C_RD_COUNT_WIDTH_INT : integer := clog2(C_FIFO_DEPTH);
constant C_WR_COUNT_WIDTH_INT : integer := clog2(C_FIFO_DEPTH);
constant RX_FIFO_CNTR_WIDTH: integer := clog2(C_FIFO_DEPTH);
constant TX_FIFO_CNTR_WIDTH: integer := clog2(C_FIFO_DEPTH);
constant ZERO_RX_FIFO_CNT   : std_logic_vector(RX_FIFO_CNTR_WIDTH-1 downto 0) := (others => '0');
constant ZERO_TX_FIFO_CNT   : std_logic_vector(TX_FIFO_CNTR_WIDTH-1 downto 0) := (others => '0');
signal rx_fifo_count: std_logic_vector(RX_FIFO_CNTR_WIDTH-1 downto 0);
signal tx_fifo_count: std_logic_vector(TX_FIFO_CNTR_WIDTH-1 downto 0);
signal tx_fifo_count_d1: std_logic_vector(TX_FIFO_CNTR_WIDTH-1 downto 0);
signal tx_fifo_count_d2: std_logic_vector(TX_FIFO_CNTR_WIDTH-1 downto 0);
signal Tx_FIFO_Empty_1 : std_logic;
signal Tx_FIFO_Empty_intr : std_logic;
signal IP2Bus_RdAck_receive_enable  : std_logic;
signal IP2Bus_WrAck_transmit_enable : std_logic;
    constant ALL_0          : std_logic_vector(0 to TX_FIFO_CNTR_WIDTH-1)
                            := (others => '1');

signal data_Exists_RcFIFO_int_d1: std_logic;
signal data_Exists_RcFIFO_pulse : std_logic;

--signal FIFO_Empty_rx : std_logic;
--signal SPISR_0_CMD_Error_frm_spi_clk : std_logic;
--signal SPISR_0_CMD_Error_to_axi_clk  : std_logic;

--signal spisel_d1_reg_frm_spi_clk : std_logic;
--signal spisel_d1_reg_to_axi_clk  : std_logic;
 signal tx_occ_msb_111             : std_logic:= '0';
 signal tx_occ_msb_11             : std_logic_vector(TX_FIFO_CNTR_WIDTH-1 downto 0);

signal spisel_pulse_frm_spi_clk : std_logic;
signal spisel_pulse_to_axi_clk  : std_logic;

signal slave_MODF_strobe_frm_spi_clk : std_logic;
signal slave_MODF_strobe_to_axi_clk  : std_logic;

signal Rx_FIFO_Empty_frm_axi_clk : std_logic;
signal Rx_FIFO_Empty_to_spi_clk  : std_logic;

signal Tx_FIFO_Full_frm_axi_clk     : std_logic;
signal Tx_FIFO_Full_to_spi_clk      : std_logic;

signal spiXfer_done_frm_spi_clk : std_logic;
signal spiXfer_done_to_axi_clk  : std_logic;

signal SR_3_modf_frm_axi_clk    : std_logic;

signal spiXfer_done_to_axi_1 : std_logic;
signal spiXfer_done_to_axi_d1 : std_logic;
signal updown_cnt_en : std_logic;

signal drr_Overrun_int_to_axi_clk : std_logic;
signal drr_Overrun_int_frm_spi_clk: std_logic;
-----
begin
-----

     SPISR_0_CMD_Error_frm_spi_clk <= SPISR_0_CMD_Error_int;
     spisel_d1_reg_frm_spi_clk     <= spisel_d1_reg;
     spisel_pulse_frm_spi_clk      <= spisel_pulse_o_int;-- from SPI module
     slave_MODF_strobe_frm_spi_clk <= slave_MODF_strobe_int; -- from SPI module
     modf_strobe_frm_spi_clk       <= modf_strobe_int; -- spi module
     Rx_FIFO_Full_frm_axi_clk      <= Rx_FIFO_Full; -- from Async Receive FIFO
     Tx_FIFO_Empty_frm_spi_clk     <= Tx_FIFO_Empty_intr; -- Tx_FIFO_Empty; -- from Async Transmit FIFO
     spiXfer_done_frm_spi_clk      <= spiXfer_done_int; -- from SPI module
     dtr_underrun_frm_spi_clk      <= dtr_underrun_int; -- from SPI module
     Tx_FIFO_Empty_SPISR_frm_spi_clk <= Tx_FIFO_Empty;-- from TX FIFO for SPI Status register
     drr_Overrun_int_frm_spi_clk   <= drr_Overrun_int;

    -- SPICR_6_RXFIFO_RST_frm_axi_clk<= SPICR_6_RXFIFO_RST_frm_axi_clk; -- from SPICR
     reset_RcFIFO_ptr_frm_axi_clk  <= reset_RcFIFO_ptr_int; -- from AXI clock
     Rx_FIFO_Empty_frm_axi_clk     <= Rx_FIFO_Empty; -- from Async Receive FIFO AXI side
     Tx_FIFO_Full_frm_axi_clk      <= Tx_FIFO_Full; -- from Async Transmit FIFO AXI side
     SR_3_modf_frm_axi_clk         <= SR_3_modf_int;

--CLK_CROSS_I:
CLK_CROSS_I:entity axi_quad_spi_v3_2_5.cross_clk_sync_fifo_1
     generic map(
             C_FAMILY                     => C_FAMILY           ,
             C_FIFO_DEPTH                 => C_FIFO_DEPTH       ,
             Async_Clk                    => Async_Clk          ,
             C_DATA_WIDTH                 => C_S_AXI_DATA_WIDTH ,
             C_S_AXI_DATA_WIDTH           => C_S_AXI_DATA_WIDTH ,
             C_NUM_TRANSFER_BITS          => C_NUM_TRANSFER_BITS,
             C_NUM_SS_BITS                => C_NUM_SS_BITS

     )
     port map(
              EXT_SPI_CLK               => EXT_SPI_CLK        ,                 -- in std_logic;
              Bus2IP_Clk                => Bus2IP_Clk         ,                 -- in std_logic;
              Soft_Reset_op             => reset2ip_reset_int ,
              --Soft_Reset_op       => Soft_Reset_op      ,                     -- in std_logic;
              Rst_cdc_to_spi                => Rst_to_spi_int     ,                 -- out std_logic;
              ----------------------------
              SPISR_0_CMD_Error_cdc_from_spi => SPISR_0_CMD_Error_frm_spi_clk ,
              SPISR_0_CMD_Error_cdc_to_axi  => SPISR_0_CMD_Error_to_axi_clk  ,
              ----------------------------------------------------------
              spisel_d1_reg_cdc_from_spi     => spisel_d1_reg_frm_spi_clk  , -- in
              spisel_d1_reg_cdc_to_axi      => spisel_d1_reg_to_axi_clk   , -- out
              ----------------------------------------------------------
              spisel_pulse_cdc_from_spi      => spisel_pulse_frm_spi_clk   , -- in
              spisel_pulse_cdc_to_axi       => spisel_pulse_to_axi_clk    , -- out
              ----------------------------
              Mst_N_Slv_mode_cdc_from_spi    => Mst_N_Slv_mode_frm_spi_clk , -- in
              Mst_N_Slv_mode_cdc_to_axi     => Mst_N_Slv_mode_to_axi_clk  , -- out
              ----------------------------
              slave_MODF_strobe_cdc_from_spi => slave_MODF_strobe_frm_spi_clk, -- in
              slave_MODF_strobe_cdc_to_axi  => slave_MODF_strobe_to_axi_clk , -- out
              ----------------------------
              modf_strobe_cdc_from_spi       => modf_strobe_frm_spi_clk , -- in
              modf_strobe_cdc_to_axi        => modf_strobe_to_axi_clk  , -- out
              ----------------------------
              SPICR_6_RXFIFO_RST_cdc_from_axi=> SPICR_6_RXFIFO_RST_frm_axi_clk, -- in
              SPICR_6_RXFIFO_RST_cdc_to_spi => SPICR_6_RXFIFO_RST_to_spi_clk , -- out
              ----------------------------
              Rx_FIFO_Full_cdc_from_axi      => Rx_FIFO_Full_frm_axi_clk, -- in
              Rx_FIFO_Full_cdc_to_spi       => Rx_FIFO_Full_to_spi_clk , -- out
              ----------------------------
              reset_RcFIFO_ptr_cdc_from_axi  => reset_RcFIFO_ptr_frm_axi_clk, -- in
              reset_RcFIFO_ptr_cdc_to_spi   => reset_RcFIFO_ptr_to_spi_clk , -- out
              ----------------------------
              Rx_FIFO_Empty_cdc_from_axi     => Rx_FIFO_Empty_frm_axi_clk , -- in
              Rx_FIFO_Empty_cdc_to_spi      => Rx_FIFO_Empty_to_spi_clk , -- out
              ----------------------------
              Tx_FIFO_Empty_cdc_from_spi     => Tx_FIFO_Empty_frm_spi_clk, -- in
              Tx_FIFO_Empty_cdc_to_axi      => Tx_FIFO_Empty_to_Axi_clk, -- out
              ----------------------------
              Tx_FIFO_Empty_SPISR_cdc_from_spi => Tx_FIFO_Empty_SPISR_frm_spi_clk,
              Tx_FIFO_Empty_SPISR_cdc_to_axi  => Tx_FIFO_Empty_SPISR_to_axi_clk,

              Tx_FIFO_Full_cdc_from_axi      => Tx_FIFO_Full_frm_axi_clk,-- in
              Tx_FIFO_Full_cdc_to_spi       => Tx_FIFO_Full_to_spi_clk ,-- out
              ----------------------------
              spiXfer_done_cdc_from_spi      => spiXfer_done_frm_spi_clk, -- in
              spiXfer_done_cdc_to_axi       => spiXfer_done_to_axi_clk, -- out
              ----------------------------
              dtr_underrun_cdc_from_spi      => dtr_underrun_frm_spi_clk, -- in
              dtr_underrun_cdc_to_axi       => dtr_underrun_to_axi_clk , -- out
              ----------------------------
              SPICR_0_LOOP_cdc_from_axi      => SPICR_0_LOOP_frm_axi_clk,-- in std_logic;
              SPICR_0_LOOP_cdc_to_spi       => SPICR_0_LOOP_to_spi_clk ,-- out
              ----------------------------
              SPICR_1_SPE_cdc_from_axi       => SPICR_1_SPE_frm_axi_clk ,-- in std_logic;
              SPICR_1_SPE_cdc_to_spi        => SPICR_1_SPE_to_spi_clk  ,-- out
              ----------------------------
              SPICR_2_MST_N_SLV_cdc_from_axi => SPICR_2_MST_N_SLV_frm_axi_clk,-- in std_logic;
              SPICR_2_MST_N_SLV_cdc_to_spi  => SPICR_2_MST_N_SLV_to_spi_clk, -- out
              ----------------------------
              SPICR_3_CPOL_cdc_from_axi      => SPICR_3_CPOL_frm_axi_clk,-- in std_logic;
              SPICR_3_CPOL_cdc_to_spi       => SPICR_3_CPOL_to_spi_clk ,-- out
              ----------------------------
              SPICR_4_CPHA_cdc_from_axi      => SPICR_4_CPHA_frm_axi_clk,-- in std_logic;
              SPICR_4_CPHA_cdc_to_spi       => SPICR_4_CPHA_to_spi_clk ,-- out
              ----------------------------
              SPICR_5_TXFIFO_cdc_from_axi    => SPICR_5_TXFIFO_RST_frm_axi_clk,-- in std_logic;
              SPICR_5_TXFIFO_cdc_to_spi     => SPICR_5_TXFIFO_to_spi_clk,  -- out
              ----------------------------
              SPICR_7_SS_cdc_from_axi        => SPICR_7_SS_frm_axi_clk ,-- in std_logic;
              SPICR_7_SS_cdc_to_spi         => SPICR_7_SS_to_spi_clk ,-- out
              ----------------------------
              SPICR_8_TR_INHIBIT_cdc_from_axi=> SPICR_8_TR_INHIBIT_frm_axi_clk,-- in std_logic;
              SPICR_8_TR_INHIBIT_cdc_to_spi => SPICR_8_TR_INHIBIT_to_spi_clk,-- out
              ----------------------------
              SPICR_9_LSB_cdc_from_axi       => SPICR_9_LSB_frm_axi_clk,-- in std_logic;
              SPICR_9_LSB_cdc_to_spi        => SPICR_9_LSB_to_spi_clk,-- out
              ----------------------------
              SPICR_bits_7_8_cdc_from_axi    => SPICR_bits_7_8_frm_axi_clk,-- in std_logic_vector
              SPICR_bits_7_8_cdc_to_spi     => SPICR_bits_7_8_to_spi_clk,-- out
              ----------------------------
              SR_3_modf_cdc_from_axi         => SR_3_modf_frm_axi_clk, -- in
              SR_3_modf_cdc_to_spi          => SR_3_modf_to_spi_clk , -- out
              ----------------------------
              SPISSR_cdc_from_axi            => SPISSR_frm_axi_clk, -- in
              SPISSR_cdc_to_spi             => register_Data_slvsel_int, -- out
              ----------------------------
              spiXfer_done_cdc_to_axi_1     => spiXfer_done_to_axi_1,
              ----------------------------
              drr_Overrun_int_cdc_from_spi   => drr_Overrun_int_frm_spi_clk,
              drr_Overrun_int_cdc_to_axi    => drr_Overrun_int_to_axi_clk
              ----------------------------
);

     -- Bu2IP Data to Interrupt Registers - IPISR and IPIER
     -- Bus2IP_Data - 0                 31
     -- IPISR/IPIER - 0        17 18    31
     --                <---NA---> <-used->
     --                           18    19      20    21         22        23        24          25         26       27   28       29    30    31
     --                           CMD_  Loop_Bk MSB   Slave_Mode CPOL_CPHA DRR_Not   Slave       Tx_FIFO    DRR_     DRR_ DTR_     DTR   Slave MODF
     --                           Error Error   Error Error      Error     _Empty    Select_mode Half_Empty Over_Run Full Underrun Empty MODF
     --                                                                    In Slave
     --                                                                    mode_only
     --                           <--------------------------------------->         <------------------------------------------------------------->
     --                            In C_SPI_MODE 1 or 2 only                             Present in all conditions

     -- IPISR Write
     -- when FIFO = 1,all other the IPIER, IPISR interrupt bits are applicable based upon the SPI mode.
     -- DRR_Not_Empty bit (bit 23) - available only in case of core is selected in
     --                    slave mode and control register mst_n_slv bit is '0'.
     -- Slave_select_mode bit-available only in case of core is selected in slave mode

     -- common assignment to SPI_MODE 1/2 and SPI_MODE = 0
     bus2IP_Data_for_interrupt_core(0 to 17) <= Bus2IP_Data(0 to 17);

     DUAL_MD_IPISR_GEN: if C_SPI_MODE = 1 or C_SPI_MODE = 2 generate
     -----------------------
     begin
     -----
          bus2IP_Data_for_interrupt_core(18 to 22) <= Bus2IP_Data(18 to 22);

     end generate DUAL_MD_IPISR_GEN;
     ---------------------------------------------

     STD_MD_IPISR_GEN: if C_SPI_MODE = 0 generate
     -----------------------------------
     begin
     -----
          bus2IP_Data_for_interrupt_core(18 to 22)<= (others => '0');

     end generate STD_MD_IPISR_GEN;
     ------------------------------------------------

     bus2IP_Data_for_interrupt_core(23)      <= Bus2IP_Data(23)     and             -- exists only when FIFO = exists                      AND
                                                ((not spisel_d1_reg_to_axi_clk) --spisel_d1_reg)
                                                  or                                -- core is selected by asserting SPISEL by ext. master AND
                                                 (not SPICR_2_MST_N_SLV_frm_axi_clk) --Mst_N_Slv_mode)           -- core is in slave mode
                                                );
     bus2IP_Data_for_interrupt_core(24 to (C_S_AXI_DATA_WIDTH-1)) <=
                                      Bus2IP_Data(24 to (C_S_AXI_DATA_WIDTH-1));
     --

     ----------------------------------------------------
     -- _____|-------------  data_Exists_RcFIFO_int
     -- ________|----------  data_Exists_RcFIFO_int_d1
     -- _____|--|__________  data_Exists_RcFIFO_pulse
     ----------------------------------------------------
     DRR_NOT_EMPTY_PULSE_P: process(Bus2IP_Clk) is
     -----
     begin
     -----
         if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
             if (reset2ip_reset_int = RESET_ACTIVE) then
                 data_Exists_RcFIFO_int_d1   <= '0';
             else
                 data_Exists_RcFIFO_int_d1   <= not rx_fifo_empty_i; -- data_Exists_RcFIFO_int;
             end if;
         end if;
     end process DRR_NOT_EMPTY_PULSE_P;
     ------------------------------------
     data_Exists_RcFIFO_pulse  <= not rx_fifo_empty_i and
                                 (not data_Exists_RcFIFO_int_d1);
     ------------------------------------

     ---------------------------------------------------------------------------

     DUAL_MD_INTR_GEN: if C_SPI_MODE = 1 or C_SPI_MODE = 2 generate
     -----------------------
        signal SPISR_4_CPOL_CPHA_Error_d1    : std_logic;
        signal SPISR_3_Slave_Mode_Error_d1   : std_logic;
        signal SPISR_2_MSB_Error_d1          : std_logic;
        signal SPISR_1_LOOP_Back_Error_d1    : std_logic;
        signal SPISR_0_CMD_Error_d1          : std_logic;

        signal SPISR_4_CPOL_CPHA_Error_pulse : std_logic;
        signal SPISR_3_Slave_Mode_Error_pulse: std_logic;
        signal SPISR_2_MSB_Error_pulse       : std_logic;
        signal SPISR_1_LOOP_Back_Error_pulse : std_logic;
        signal SPISR_0_CMD_Error_pulse       : std_logic;
     -----
     begin
     -----
     INTR_UPPER_BITS_P: process(Bus2IP_Clk) is
     -----
     begin
     -----
         if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
           if (reset2ip_reset_int = RESET_ACTIVE) then
               SPISR_0_CMD_Error_d1        <= '0';
               SPISR_1_LOOP_Back_Error_d1  <= '0';
               SPISR_2_MSB_Error_d1        <= '0';
               SPISR_3_Slave_Mode_Error_d1 <= '0';
               SPISR_4_CPOL_CPHA_Error_d1  <= '0';
           else
               SPISR_0_CMD_Error_d1        <= SPISR_0_CMD_Error_to_axi_clk; -- SPISR_0_CMD_Error_int;
               SPISR_1_LOOP_Back_Error_d1  <= SPISR_1_LOOP_Back_Error_int; -- from SPICR
               SPISR_2_MSB_Error_d1        <= SPISR_2_MSB_Error_int;       -- from SPICR
               SPISR_3_Slave_Mode_Error_d1 <= SPISR_3_Slave_Mode_Error_int;-- from SPICR
               SPISR_4_CPOL_CPHA_Error_d1  <= SPISR_4_CPOL_CPHA_Error_int; -- from SPICR
           end if;
         end if;
     end process INTR_UPPER_BITS_P;
     ------------------------------------
     SPISR_0_CMD_Error_pulse        <= SPISR_0_CMD_Error_to_axi_clk -- SPISR_0_CMD_Error_int
                                       and (not SPISR_0_CMD_Error_d1);
     SPISR_1_LOOP_Back_Error_pulse  <= SPISR_1_LOOP_Back_Error_int
                                       and (not SPISR_1_LOOP_Back_Error_d1);
     SPISR_2_MSB_Error_pulse        <= SPISR_2_MSB_Error_int
                                       and (not SPISR_2_MSB_Error_d1);
     SPISR_3_Slave_Mode_Error_pulse <= SPISR_3_Slave_Mode_Error_int
                                       and (not SPISR_3_Slave_Mode_Error_d1);
     SPISR_4_CPOL_CPHA_Error_pulse  <= SPISR_4_CPOL_CPHA_Error_int
                                       and (not SPISR_4_CPOL_CPHA_Error_d1);

     -- Interrupt Status Register(IPISR) Mapping
     ip2Bus_IntrEvent_int(13) <= SPISR_0_CMD_Error_pulse;
     ip2Bus_IntrEvent_int(12) <= SPISR_1_LOOP_Back_Error_pulse;
     ip2Bus_IntrEvent_int(11) <= SPISR_2_MSB_Error_pulse;
     ip2Bus_IntrEvent_int(10) <= SPISR_3_Slave_Mode_Error_pulse;
     ip2Bus_IntrEvent_int(9)  <= SPISR_4_CPOL_CPHA_Error_pulse ;

     end generate DUAL_MD_INTR_GEN;
     --------------------------------------------

     STD_MD_INTR_GEN: if C_SPI_MODE = 0 generate
     -----------------------
     begin
     -----
         ip2Bus_IntrEvent_int(13) <= '0';
         ip2Bus_IntrEvent_int(12) <= '0';
         ip2Bus_IntrEvent_int(11) <= '0';
         ip2Bus_IntrEvent_int(10) <= '0';
         ip2Bus_IntrEvent_int(9)  <= '0';

     end generate STD_MD_INTR_GEN;
     -----------------------------------------------

     ip2Bus_IntrEvent_int(8)  <= data_Exists_RcFIFO_pulse and
                                 ((not spisel_d1_reg_to_axi_clk) -- spisel_d1_reg)
                                   or
                                  (not SPICR_2_MST_N_SLV_frm_axi_clk) -- Mst_N_Slv_mode)
                                  );
     ip2Bus_IntrEvent_int(7)  <= spisel_pulse_to_axi_clk;-- and not SPICR_2_MST_N_SLV_frm_axi_clk; -- spisel_pulse_o_int;-- spi_module

     ip2Bus_IntrEvent_int(6)  <= tx_FIFO_less_half_int;    -- qspi_fifo_ifmodule
     ip2Bus_IntrEvent_int(5)  <= drr_Overrun_int_to_axi_clk; -- drr_Overrun_int;          -- qspi_fifo_ifmodule
     ip2Bus_IntrEvent_int(4)  <= rc_FIFO_Full_strobe_int;  -- qspi_fifo_ifmodule
     ip2Bus_IntrEvent_int(3)  <= dtr_Underrun_strobe_int;  -- qspi_fifo_ifmodule
     ip2Bus_IntrEvent_int(2)  <= tx_FIFO_Empty_strobe_int; -- qspi_fifo_ifmodule
     ip2Bus_IntrEvent_int(1)  <= slave_MODF_strobe_to_axi_clk; --slave_MODF_strobe_int;-- spi_module
     ip2Bus_IntrEvent_int(0)  <= modf_strobe_to_axi_clk;       -- modf_strobe_int;     -- spi_module

     --Combinatorial operations
     reset_TxFIFO_ptr_int <= reset2ip_reset_int or SPICR_5_TXFIFO_RST_frm_axi_clk;
     reset_TxFIFO_ptr_int_to_spi <= Rst_to_spi_int or SPICR_5_TXFIFO_to_spi_clk;
	 
     --reset_RcFIFO_ptr_int <= Rst_to_spi_int or SPICR_6_RXFIFO_RST_to_spi_clk; -- SPICR_6_RXFIFO_RST_int;
     reset_RcFIFO_ptr_int <= reset2ip_reset_int or SPICR_6_RXFIFO_RST_frm_axi_clk;
     sr_5_Tx_Empty_int    <= not (data_Exists_TxFIFO_int);
     Rc_FIFO_Empty_int    <= Rx_FIFO_Empty;--not (data_Exists_RcFIFO_int);


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

  RX_RD_EN_LEG_MD_GEN: if C_TYPE_OF_AXI4_INTERFACE = 0 generate
  begin
  -----

  IP2Bus_RdAck_receive_enable  <= (rd_ce_reduce_ack_gen and
                                  Bus2IP_RdCE(SPIDRR)
                                  )and
                                  (not Rx_FIFO_Empty);
  end generate RX_RD_EN_LEG_MD_GEN;

  RX_RD_EN_ENHAN_MD_GEN: if C_TYPE_OF_AXI4_INTERFACE = 1 generate
  begin
  -----

  IP2Bus_RdAck_receive_enable  <= --(rd_ce_reduce_ack_gen and
                                  (rready and
                                  Bus2IP_RdCE(SPIDRR)
                                  )and
                                  (not Rx_FIFO_Empty);
  end generate RX_RD_EN_ENHAN_MD_GEN;
-- Receive FIFO Logic
rx_fifo_reset <= Rst_to_spi_int or reset_RcFIFO_ptr_to_spi_clk;

RX_FIFO_II: entity lib_fifo_v1_0_3.async_fifo_fg --axi_quad_spi_v3_2_5.async_fifo_fg --lib_fifo_v1_0_3.async_fifo_fg
  generic map(
        -- for first word fall through FIFO below two parameters setting is must please dont change
	C_PRELOAD_LATENCY  => 0                  ,-- this is newly added and async_fifo_fg is referred from proc common v4_0
        C_PRELOAD_REGS     => 1                  ,-- this is newly added and async_fifo_fg is referred from proc common v4_0
        -- variables
        C_ALLOW_2N_DEPTH   => 1                  , -- : Integer := 0;  -- New paramter to leverage FIFO Gen 2**N depth
        C_FAMILY           => C_FAMILY           , -- : String  := "virtex5";  -- new for FIFO Gen
        C_DATA_WIDTH       => C_NUM_TRANSFER_BITS, -- : integer := 16;
        C_FIFO_DEPTH       => C_FIFO_DEPTH       , -- : integer := 15;
        C_RD_COUNT_WIDTH   => C_RD_COUNT_WIDTH_INT,-- : integer := 3 ;
        C_WR_COUNT_WIDTH   => C_WR_COUNT_WIDTH_INT,-- : integer := 3 ;
        C_HAS_ALMOST_EMPTY => 1                  , -- : integer := 1 ;
        C_HAS_ALMOST_FULL  => 1                  , -- : integer := 1 ;
        C_HAS_RD_ACK       => 1                  , -- : integer := 0 ;
        C_HAS_RD_COUNT     => 1                  , -- : integer := 1 ;
        C_HAS_WR_ACK       => 1                  , -- : integer := 0 ;
        C_HAS_WR_COUNT     => 1                  , -- : integer := 1 ;
        -- constants
        C_HAS_RD_ERR       => 0                  , -- : integer := 0 ;
        C_HAS_WR_ERR       => 0                  , -- : integer := 0 ;
        C_RD_ACK_LOW       => 0                  , -- : integer := 0 ;
        C_RD_ERR_LOW       => 0                  , -- : integer := 0 ;
        C_WR_ACK_LOW       => 0                  , -- : integer := 0 ;
        C_WR_ERR_LOW       => 0                  , -- : integer := 0
        C_ENABLE_RLOCS     => 0                  , -- : integer := 0 ;  -- not supported in FG
        C_USE_BLOCKMEM     => 0                    -- : integer := 1 ;  -- 0 = distributed RAM, 1 = BRAM
    )
  port map(
        Din                => Data_To_Rx_FIFO           , -- : in std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
        Wr_en              => spiXfer_done_int, --SPIXfer_done_Rx_Wr_en, --            , -- : in std_logic := '1';
        Wr_clk             => EXT_SPI_CLK                 , -- : in std_logic := '1';
        Wr_ack             => Rx_FIFO_wr_ack_open         , -- : out std_logic;
        ------
        Dout               => Data_From_Rx_FIFO           , -- : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        Rd_en              => IP2Bus_RdAck_receive_enable , -- : in std_logic := '0';
        Rd_clk             => Bus2IP_Clk                  , -- : in std_logic := '1';
        Rd_ack             => Rx_FIFO_rd_ack              , -- : out std_logic;
        ------
        Full               => open, --Rx_FIFO_Full                , -- : out std_logic;
        Empty              => Rx_FIFO_Empty               , -- : out std_logic;
        Almost_full        => Rx_FIFO_almost_Full         , -- : out std_logic;
        Almost_empty       => Rx_FIFO_almost_Empty        , -- : out std_logic;
        Rd_count           => Rx_FIFO_occ_Reversed        , -- : out std_logic_vector(C_RD_COUNT_WIDTH-1 downto 0);
        ------
        Ainit              => rx_fifo_reset, -- reset_RcFIFO_ptr_to_spi_clk ,--reset_RcFIFO_ptr_int, -- reset_RcFIFO_ptr_to_spi_clk ,--Rx_FIFO_ptr_RST             , -- : in std_logic := '1';
        Wr_count           => open                        , -- : out std_logic_vector(C_WR_COUNT_WIDTH-1 downto 0);
        Rd_err             => open                        , -- : out std_logic;
        Wr_err             => open                          -- : out std_logic
    );

       RX_FIFO_FULL_CNTR_I : entity axi_quad_spi_v3_2_5.counter_f
      generic map(
        C_NUM_BITS    =>  RX_FIFO_CNTR_WIDTH,
        C_FAMILY      =>  "nofamily"
          )
      port map(
        Clk           =>  Bus2IP_Clk,      -- in
        Rst           =>  '0',             -- in
        Load_In       =>  ALL_0,           -- in
        Count_Enable  =>  updown_cnt_en_rx,     -- in
        ----------------
        Count_Load    =>  reset_RcFIFO_ptr_int, -- in
        ----------------
        Count_Down    =>  IP2Bus_RdAck_receive_enable,   -- in
        Count_Out     =>  rx_fifo_count,             -- out std_logic_vector
        Carry_Out     =>  open             -- out
        );

        updown_cnt_en_rx <= IP2Bus_RdAck_receive_enable xor spiXfer_done_to_axi_1;

   RX_one_less_than_full <= and_reduce(rx_fifo_count(RX_FIFO_CNTR_WIDTH-1 downto RX_FIFO_CNTR_WIDTH-RX_FIFO_CNTR_WIDTH+1)) and
                            (not rx_fifo_count(0))and spiXfer_done_to_axi_1;



   RX_FULL_EMP_MD_12_INTR_GEN: if C_SPI_MODE /= 0 generate
   -----
   --signal rx_fifo_empty_i : std_logic;
   begin
   -----
   RX_FIFO_EMPTY_P:process(Bus2IP_Clk)is
   begin
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
             if(reset2ip_reset_int = RESET_ACTIVE)then
                 rx_fifo_empty_i <= '1';
             elsif(reset_RcFIFO_ptr_int = '1')then
                 rx_fifo_empty_i <= '1';
             elsif(spiXfer_done_to_axi_1 = '1')then
                 rx_fifo_empty_i <= '0';
             end if;
        end if;
   end process RX_FIFO_EMPTY_P;

   RX_FIFO_FULL_P:process(Bus2IP_Clk)is
   begin
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
             if(reset2ip_reset_int = RESET_ACTIVE)then
                 Rx_FIFO_Full_int <= '0';
             elsif(reset_RcFIFO_ptr_int = '1') or (drr_Overrun_int_to_axi_clk = '1') then --(drr_Overrun_int = '1')then
                 Rx_FIFO_Full_int <= '0';
             elsif(RX_one_less_than_full = '1' and
                   spiXfer_done_to_axi_1 = '1' and
                   rx_fifo_empty_i = '0')then
                 Rx_FIFO_Full_int <= '1';
             end if;
        end if;
   end process RX_FIFO_FULL_P;

   end generate RX_FULL_EMP_MD_12_INTR_GEN;
   ------------------------------------

   RX_FULL_EMP_MD_0_GEN: if C_SPI_MODE = 0 generate
   --signal rx_fifo_empty_i : std_logic;
   -----
   begin
   -----
   RX_FIFO_EMPTY_P:process(Bus2IP_Clk)is
   begin
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
             if(reset2ip_reset_int = RESET_ACTIVE)then
                 rx_fifo_empty_i <= '1';
             elsif(reset_RcFIFO_ptr_int = '1')then
                 rx_fifo_empty_i <= '1';
             elsif(spiXfer_done_to_axi_1 = '1')then
                 rx_fifo_empty_i <= '0';
             end if;
        end if;
   end process RX_FIFO_EMPTY_P;


   -------------------------------------------
   RX_FIFO_ABT_TO_FULL_P:process(Bus2IP_Clk)is
   begin
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
             if(reset2ip_reset_int = RESET_ACTIVE)then
                    Rx_FIFO_Full_i <= '0';
             elsif(reset_RcFIFO_ptr_int = '1') or (drr_Overrun_int_to_axi_clk = '1') then -- (drr_Overrun_int = '1')then
                    Rx_FIFO_Full_i <= '0';
             elsif(Rx_FIFO_Full_int = '1')then
                    Rx_FIFO_Full_i <= '0';
             elsif(RX_one_less_than_full = '1')then
                    Rx_FIFO_Full_i <= '1';
             end if;
        end if;
   end process RX_FIFO_ABT_TO_FULL_P;
   -------------------------------------
   RX_FIFO_FULL_P: process(Bus2IP_Clk)is
   begin
   -----
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if(reset2ip_reset_int = RESET_ACTIVE)then
                Rx_FIFO_Full_int <= '0';
            elsif(reset_RcFIFO_ptr_int = '1') or (drr_Overrun_int_to_axi_clk = '1') then -- (drr_Overrun_int = '1')then
                 Rx_FIFO_Full_int <= '0';
            elsif(Rx_FIFO_Full_int = '1' and IP2Bus_RdAck_receive_enable = '1') then -- IP2Bus_RdAck_receive_enable = '1')then
                Rx_FIFO_Full_int <= '0';
            elsif(Rx_FIFO_Full_i = '1')then
                Rx_FIFO_Full_int <= '1';
            end if;
        end if;
   end process RX_FIFO_FULL_P;
   ---------------------------------
   Rx_FIFO_Full <= Rx_FIFO_Full_int;

   end generate RX_FULL_EMP_MD_0_GEN;

   Rx_FIFO_Empty_int <= Rx_FIFO_Empty or Rx_FIFO_Empty_i;

  -----------------------------------------------------------------------------
  --    AXI Clk domain   -- __________________ SPI clk domain
  --Din                  --|AXI clk           |-- Dout
  --Wr_en                --|                  |-- Rd_en
  --Wr_clk               --|                  |-- Rd_clk
                         --|                  |--
  --Tx_FIFO_Full         --|    Tx FIFO       |-- Tx_FIFO_Empty
  --Tx_FIFO_almost_Full  --|                  |-- Tx_FIFO_almost_Empty
  --Tx_FIFO_occ_Reversed --|                  |-- Tx_FIFO_rd_ack
  --Tx_FIFO_wr_ack       --|                  |--
                         --|                  |--
                         --|                  |--
                         --|                  |--
                         --|__________________|--
  TX_TR_EN_LEG_MD_GEN: if C_TYPE_OF_AXI4_INTERFACE = 0 generate
  begin
  -----
  IP2Bus_WrAck_transmit_enable <= (wr_ce_reduce_ack_gen and
                                  Bus2IP_WrCE(SPIDTR)
                                  ) and
                                 (not Tx_FIFO_Full);-- after 100 ps;
  end generate TX_TR_EN_LEG_MD_GEN;

  TX_TR_EN_ENHAN_MD_GEN: if C_TYPE_OF_AXI4_INTERFACE = 1 generate
  signal local_tr_en : std_logic;
  begin
  -----
  --IP2Bus_WrAck_transmit_enable <= (wr_ce_reduce_ack_gen and
  --                                Bus2IP_WrCE(SPIDTR)
  --                                ) and
  --                                (not Tx_FIFO_Full)
  --                               when burst_tr = '0' else
  --                                (Bus2IP_WrCE(SPIDTR)
  --                                 and
  --                                (not Tx_FIFO_Full));-- after 100 ps;
  local_tr_en  <= Bus2IP_WrCE(SPIDTR) and (not Tx_FIFO_Full);
  --local_tr_en1 <= Bus2IP_WrCE_d1      and (not Tx_FIFO_Full);
  TR_EN_P:process(wr_ce_reduce_ack_gen,
                  local_tr_en,
                  burst_tr,
                  WVALID)is
  begin
       if(burst_tr = '1') then
           IP2Bus_WrAck_transmit_enable <= local_tr_en and WVALID; -- Bus2IP_WrCE_d1 and (not Tx_FIFO_Full); --local_tr_en;
       else
           IP2Bus_WrAck_transmit_enable <= local_tr_en and wr_ce_reduce_ack_gen;
       end if;
  end process TR_EN_P;
  end generate TX_TR_EN_ENHAN_MD_GEN;

Data_To_TxFIFO <= Bus2IP_Data((C_S_AXI_DATA_WIDTH-C_NUM_TRANSFER_BITS) to(C_S_AXI_DATA_WIDTH-1));-- after 100 ps;
-- Transmit FIFO Logic
tx_fifo_reset <= reset2ip_reset_int or reset_TxFIFO_ptr_int;
TX_FIFO_II: entity lib_fifo_v1_0_3.async_fifo_fg -- entity axi_quad_spi_v3_2_5.async_fifo_fg -- lib_fifo_v1_0_3.async_fifo_fg
  generic map
      (
        -- for first word fall through FIFO below two parameters setting is must please dont change
	C_PRELOAD_LATENCY  => 0                  ,-- this is newly added and async_fifo_fg is referred from proc common v4_0
        C_PRELOAD_REGS     => 1                  ,-- this is newly added and async_fifo_fg is referred from proc common v4_0
	-- variables
        C_ALLOW_2N_DEPTH   => 1                  , -- : Integer := 0;  -- New paramter to leverage FIFO Gen 2**N depth
        C_FAMILY           => C_FAMILY           , -- : String  := "virtex5";  -- new for FIFO Gen
        C_DATA_WIDTH       => C_NUM_TRANSFER_BITS, -- : integer := 16;
        C_FIFO_DEPTH       => C_FIFO_DEPTH       , -- : integer := 15;
        C_RD_COUNT_WIDTH   => C_RD_COUNT_WIDTH_INT,-- : integer := 3 ;
        C_WR_COUNT_WIDTH   => C_WR_COUNT_WIDTH_INT,-- : integer := 3 ;
        C_HAS_ALMOST_EMPTY => 1                  , -- : integer := 1 ;
        C_HAS_ALMOST_FULL  => 1                  , -- : integer := 1 ;
        C_HAS_RD_ACK       => 1                  , -- : integer := 0 ;
        C_HAS_RD_COUNT     => 1                  , -- : integer := 1 ;
        C_HAS_WR_ACK       => 1                  , -- : integer := 0 ;
        C_HAS_WR_COUNT     => 1                  , -- : integer := 1 ;
        -- constants
        C_HAS_RD_ERR       => 0                  , -- : integer := 0 ;
        C_HAS_WR_ERR       => 0                  , -- : integer := 0 ;
        C_RD_ACK_LOW       => 0                  , -- : integer := 0 ;
        C_RD_ERR_LOW       => 0                  , -- : integer := 0 ;
        C_WR_ACK_LOW       => 0                  , -- : integer := 0 ;
        C_WR_ERR_LOW       => 0                  , -- : integer := 0
        C_ENABLE_RLOCS     => 0                  , -- : integer := 0 ;  -- not supported in FG
        C_USE_BLOCKMEM     => 0                    -- : integer := 1 ;  -- 0 = distributed RAM, 1 = BRAM
      )
  port map
      (
        -- writing will be through AXI clock
        Wr_clk             => Bus2IP_Clk                  , -- : in std_logic := '1';
        Din                => Data_To_TxFIFO              , -- : in std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
        Wr_en              => IP2Bus_WrAck_transmit_enable, -- : in std_logic := '1';
        Wr_ack             => Tx_FIFO_wr_ack              , -- : out std_logic;
        ------
        -- reading will be through SPI clock
        Rd_clk             => EXT_SPI_CLK                 , -- : in std_logic := '1';
        Dout               => Data_From_TxFIFO            , -- : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        Rd_en              => SPIXfer_done_rd_tx_en            , -- : in std_logic := '0';
        Rd_ack             => Tx_FIFO_rd_ack_open         , -- : out std_logic;
        ------
        Full               => Tx_FIFO_Full                , -- : out std_logic;
        Empty              => Tx_FIFO_Empty               , -- : out std_logic;
        Almost_full        => Tx_FIFO_almost_Full         , -- : out std_logic;
        Almost_empty       => Tx_FIFO_almost_Empty        , -- : out std_logic;
        Rd_count           => open        , -- : out std_logic_vector(C_RD_COUNT_WIDTH-1 downto 0);
        ------
        Ainit              => reset_TxFIFO_ptr_int        ,--Tx_FIFO_ptr_RST             , -- : in std_logic := '1';
        Wr_count           => Tx_FIFO_occ_Reversed        , -- : out std_logic_vector(C_WR_COUNT_WIDTH-1 downto 0);
        Rd_err             => open                        , -- : out std_logic;
        Wr_err             => open                          -- : out std_logic
    );

    --tx_occ_msb             <= tx_fifo_count(TX_FIFO_CNTR_WIDTH-1); -- --Tx_FIFO_occ_Reversed(C_WR_COUNT_WIDTH_INT-1);
    --tx_occ_msb_1             <= (tx_fifo_count(TX_FIFO_CNTR_WIDTH-1));-- and not(or_reduce(tx_fifo_count(TX_FIFO_CNTR_WIDTH-2 downto 0))) ;--
                              --and not Tx_FIFO_Empty_SPISR_to_axi_clk;-- and not Tx_FIFO_Full_int; -- --Tx_FIFO_occ_Reversed(C_WR_COUNT_WIDTH_INT-1);
    tx_occ_msb_11             <= (tx_fifo_count);

    FIFO_16_OCC_MSB_GEN: if C_FIFO_DEPTH = 16 generate
    begin
        tx_occ_msb_1 <= tx_occ_msb_11(3);
    end generate FIFO_16_OCC_MSB_GEN;

    FIFO_256_OCC_MSB_GEN: if C_FIFO_DEPTH = 256 generate
    begin
        tx_occ_msb_1 <= tx_occ_msb_11(7);
    end generate FIFO_256_OCC_MSB_GEN;

    TX_OCC_MSB_P: process (Bus2IP_Clk)is
    begin
         if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
               if(reset2ip_reset_int = RESET_ACTIVE)then
                   tx_occ_msb_2 <= '0';
                   tx_occ_msb_3 <= '0';
                   tx_occ_msb_4 <= '0';
               else
                   tx_occ_msb_2 <= tx_occ_msb_1;
                   tx_occ_msb_3 <= tx_occ_msb_2;
                   tx_occ_msb_4 <= tx_occ_msb_3;
               end if;
         end if;
    end process TX_OCC_MSB_P;
    tx_occ_msb <= tx_occ_msb_4 and not Tx_FIFO_Empty_SPISR_to_axi_clk;

    data_Exists_TxFIFO_int <= not (Tx_FIFO_Empty);
    -----------------------------------------------------------
    TX_FIFO_EMPTY_CNTR_I : entity axi_quad_spi_v3_2_5.counter_f
      generic map(
        C_NUM_BITS    =>  TX_FIFO_CNTR_WIDTH,
        C_FAMILY      =>  "nofamily"
          )
      port map(
        Clk           =>  Bus2IP_Clk,      -- in
        Rst           =>  '0',             -- in
        Load_In       =>  ALL_0,           -- in
        Count_Enable  =>  updown_cnt_en,     -- in
        ----------------
        Count_Load    =>  reset_TxFIFO_ptr_int, -- in
        ----------------
        Count_Down    =>  spiXfer_done_to_axi_1,   -- in
        Count_Out     =>  tx_fifo_count,             -- out std_logic_vector
        Carry_Out     =>  open             -- out
        );

   updown_cnt_en <= IP2Bus_WrAck_transmit_enable xor spiXfer_done_to_axi_1;
   ----------------------------------------
   TX_FULL_EMP_INTR_MD_12_GEN: if C_SPI_MODE /=0 generate
   -----
   begin
   -----
   Tx_FIFO_Empty_intr <= not (or_reduce(tx_fifo_count(TX_FIFO_CNTR_WIDTH-1 downto 0)))
                                      -- and (tx_fifo_count(0))
                                      and spiXfer_done_to_axi_1
                                      and ( Tx_FIFO_Empty_SPISR_to_axi_clk); -- and ( Tx_FIFO_Empty);

   Tx_FIFO_Full_int       <= Tx_FIFO_Full;

   end generate TX_FULL_EMP_INTR_MD_12_GEN;
   ----------------------------------------

   ----------------------------------------
   TX_FULL_EMP_INTR_MD_0_GEN: if C_SPI_MODE =0 generate
   -----
   begin
   -----
    -- Tx_FIFO_one_less_to_Empty <= not(or_reduce(tx_fifo_count(TX_FIFO_CNTR_WIDTH-1 downto 0)))
    --                                    --and (tx_fifo_count(0))
    --                                    and spiXfer_done_to_axi_1;--tx_cntr_xfer_done_to_axi_1_clk; --
    -- --------------------------------------------
    -- TX_FIFO_ABT_TO_EMPTY_P:process(Bus2IP_Clk)is
    -- begin
    --       if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
    --            if(reset2ip_reset_int = RESET_ACTIVE)then
    --             Tx_FIFO_Empty_i <= '0';
    --            elsif(Tx_FIFO_Empty_int = '1')then
    --               Tx_FIFO_Empty_i <= '0';
    --            elsif(Tx_FIFO_one_less_to_Empty = '1') or then
    --              Tx_FIFO_Empty_i <= '1';
    --            end if;
    --       end if;
    -- end process TX_FIFO_ABT_TO_EMPTY_P;
    -- --------------------------------------
    -- TX_FIFO_EMPTY_P: process(Bus2IP_Clk)is
    -- begin
    -- -----
    --      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
    --          if(reset2ip_reset_int = RESET_ACTIVE)then
    --              Tx_FIFO_Empty_int <= '0';
    --          elsif(Tx_FIFO_Empty_int = '1' and spiXfer_done_to_axi_1 = '1')then
    --              Tx_FIFO_Empty_int <= '0';
    --          elsif(Tx_FIFO_Empty_i = '1')then
    --              Tx_FIFO_Empty_int <= '1';
    --          end if;
    --      end if;
    -- end process TX_FIFO_EMPTY_P;
    --------------------------------
    -- Tx_FIFO_Empty_intr <= Tx_FIFO_Empty_int and spiXfer_done_to_axi_1;
    --------------------------------
    TX_FIFO_CNTR_DELAY_P: process(Bus2IP_Clk)is
    begin
    -----
         if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
             if(reset2ip_reset_int = RESET_ACTIVE)then
                 tx_fifo_count_d1 <= (others => '0');
		 tx_fifo_count_d2 <= (others => '0');
		 spiXfer_done_to_axi_d1 <= '0';
             else
		 tx_fifo_count_d1 <= tx_fifo_count;
		 tx_fifo_count_d2 <= tx_fifo_count_d1;
		 spiXfer_done_to_axi_d1 <= spiXfer_done_to_axi_1;
             end if;
         end if;
    end process TX_FIFO_CNTR_DELAY_P;

    Tx_FIFO_Empty_intr <= (not (or_reduce(tx_fifo_count_d2(TX_FIFO_CNTR_WIDTH-1 downto 0)))
                                          -- and (tx_fifo_count(0))
                                          and spiXfer_done_to_axi_d1
                                          and ( Tx_FIFO_Empty_SPISR_to_axi_clk));

    TX_one_less_than_full <= and_reduce(tx_fifo_count(TX_FIFO_CNTR_WIDTH-1 downto TX_FIFO_CNTR_WIDTH-TX_FIFO_CNTR_WIDTH+1)) and
                            (not tx_fifo_count(0))and IP2Bus_WrAck_transmit_enable;
    -------------------------------------------
    TX_FIFO_ABT_TO_FULL_P:process(Bus2IP_Clk)is
    begin
         if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
              if(reset2ip_reset_int = RESET_ACTIVE)then
                 Tx_FIFO_Full_i <= '0';
              elsif(reset_TxFIFO_ptr_int = '1')then
                 Tx_FIFO_Full_i <= '0';
              elsif(Tx_FIFO_Full_int = '1')then
                 Tx_FIFO_Full_i <= '0';
              elsif(TX_one_less_than_full = '1')then
             Tx_FIFO_Full_i <= '1';
              end if;
         end if;
    end process TX_FIFO_ABT_TO_FULL_P;
    ----------------------------------
    TX_FIFO_FULL_P: process(Bus2IP_Clk)is
    begin
    -----
         if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
             if(reset2ip_reset_int = RESET_ACTIVE)then
                 Tx_FIFO_Full_int <= '0';
             elsif(reset_TxFIFO_ptr_int = '1')then
                 Tx_FIFO_Full_int <= '0';
             elsif(Tx_FIFO_Full_int = '1' and spiXfer_done_to_axi_1 = '1')then
                 Tx_FIFO_Full_int <= '0';
             elsif(Tx_FIFO_Full_i = '1') then --  and spiXfer_done_to_axi_1 = '1')then
                 Tx_FIFO_Full_int <= '1';
             end if;
         end if;
    end process TX_FIFO_FULL_P;
    ---------------------------
   end generate TX_FULL_EMP_INTR_MD_0_GEN;
   ----------------------------------------

-------------------------------------------------------------------------------
-- I_FIFO_IF_MODULE : INSTANTIATE FIFO INTERFACE MODULE
-------------------------------------------------------------------------------
     FIFO_IF_MODULE_I: entity axi_quad_spi_v3_2_5.qspi_fifo_ifmodule
        generic map
             (
              C_NUM_TRANSFER_BITS   => C_NUM_TRANSFER_BITS
             )
        port map
             (
              Bus2IP_Clk            => Bus2IP_Clk   ,                           -- in
              Soft_Reset_op         => reset2ip_reset_int,                      -- in
              -- Slave attachment ports from AXI clock
              Bus2IP_RcFIFO_RdCE    => Bus2IP_RdCE(SPIDRR),-- axiclk            -- in
              Bus2IP_TxFIFO_WrCE    => Bus2IP_WrCE(SPIDTR),-- axi clk           -- in
              Rd_ce_reduce_ack_gen  => rd_ce_reduce_ack_gen,-- axi clk          -- in
              -- FIFO ports
              Data_From_TxFIFO      => Data_From_TxFIFO    ,-- spi clk          -- in vec
              Data_From_Rc_FIFO     => Data_From_Rx_FIFO   ,-- axi clk          -- in vec
              Tx_FIFO_Data_WithZero => transmit_Data_int   ,-- spi clk          -- out vec
              IP2Bus_RX_FIFO_Data   => IP2Bus_Receive_Reg_Data_int,             -- out vec
              ---------------------
              Rc_FIFO_Full          => Rx_FIFO_Full_int, -- Rx_FIFO_Full_to_axi_clk,                 -- in
              Rc_FIFO_Full_strobe   => rc_FIFO_Full_strobe_int,                 -- out
              ---------------------
              Tx_FIFO_Empty         => Tx_FIFO_Empty_intr , -- Tx_FIFO_Empty_to_Axi_clk, -- sr_5_Tx_Empty_int,-- spi clk -- in
              Tx_FIFO_Empty_strobe  => tx_FIFO_Empty_strobe_int,                -- out
              ---------------------
              Rc_FIFO_Empty         => Rx_FIFO_Empty_int, -- 13-09-2012   rx_fifo_empty_i, -- Rx_FIFO_Empty , -- Rc_FIFO_Empty_int,                       -- in
              Receive_ip2bus_error  => receive_ip2bus_error,                    -- out
              Tx_FIFO_Full          => Tx_FIFO_Full_int,                        -- in
              Transmit_ip2bus_error => transmit_ip2bus_error,                   -- out
              ---------------------
              Tx_FIFO_Occpncy_MSB   => tx_occ_msb,                              -- in
              Tx_FIFO_less_half     => tx_FIFO_less_half_int,                   -- out
              ---------------------
              DTR_underrun          => dtr_underrun_to_axi_clk,-- dtr_underrun_int,-- in
              DTR_Underrun_strobe   => dtr_Underrun_strobe_int,                 -- out
              ---------------------
              SPIXfer_done          => spiXfer_done_to_axi_1, -- spiXfer_done_int, -- in
              rready                => rready
             -- DRR_Overrun_reg       => drr_Overrun_int                          -- out
        );

-------------------------------------------------------------------------------
-- TX_OCCUPANCY_I : INSTANTIATE TRANSMIT OCCUPANCY REGISTER
-------------------------------------------------------------------------------

     TX_OCCUPANCY_I: entity axi_quad_spi_v3_2_5.qspi_occupancy_reg
        generic map
             (
              C_OCCUPANCY_NUM_BITS => C_OCCUPANCY_NUM_BITS
             )
        port map
             (
          --Slave attachment ports
              Bus2IP_OCC_REG_RdCE      => Bus2IP_RdCE(SPITFOR),                 -- in

          --FIFO port
              IP2Reg_OCC_Data          => tx_fifo_count, -- tx_FIFO_occ_Reversed,             -- in vec
              IP2Bus_OCC_REG_Data      => IP2Bus_Tx_FIFO_OCC_Reg_Data_int       -- out vec
             );

-------------------------------------------------------------------------------
-- RX_OCCUPANCY_I : INSTANTIATE RECEIVE OCCUPANCY REGISTER
-------------------------------------------------------------------------------

     RX_OCCUPANCY_I: entity axi_quad_spi_v3_2_5.qspi_occupancy_reg
        generic map
             (
              C_OCCUPANCY_NUM_BITS => C_OCCUPANCY_NUM_BITS--,
             )
        port map
             (
          --Slave attachment ports
              Bus2IP_OCC_REG_RdCE      => Bus2IP_RdCE(SPIRFOR),                 -- in

          --FIFO port
              IP2Reg_OCC_Data          => rx_fifo_count, --rx_FIFO_occ_Reversed,             -- in vec
              IP2Bus_OCC_REG_Data      => IP2Bus_Rx_FIFO_OCC_Reg_Data_int       -- out vec
             );

 end generate FIFO_EXISTS;
 --------------------------------------------


-- LOGIC_FOR_MD_0_GEN: in stantiate the original SPI module when the core is configured in Standard SPI mode.
------------------------------
LOGIC_FOR_MD_0_GEN: if C_SPI_MODE = 0 generate
---------------------------
signal SCK_O_int : std_logic;
signal MISO_I_int: std_logic;
-----
begin
-----
   -- un used IO2 and IO3 O/P ports are tied to 0 and T ports are tied to '1'
    DATA_STARTUP_USED : if C_USE_STARTUP = 1 generate
   -----
    begin
   -----
--   IO2_O <= do(2);
--   IO2_T <= dts(2);
--   IO3_O <= do(3);
--   IO3_T <= dts(3);
        IO2_O <= '0';
        IO2_T <= '1';
        IO3_O <= '0';
        IO3_T <= '1';
 
   SPISR_0_CMD_Error_int <= '0'; -- no command error when C_SPI_MODE= 0
end generate DATA_STARTUP_USED;
   -------------------------------------------------------
   SCK_MISO_NO_STARTUP_USED: if C_USE_STARTUP = 0 generate
   -----
   begin
   -----
        IO2_O <= '0';
        IO2_T <= '1';
        IO3_O <= '0';
        IO3_T <= '1';
        SCK_O      <= SCK_O_int;   -- output from the core
        MISO_I_int <= IO1_I;       -- input to the core

   end generate SCK_MISO_NO_STARTUP_USED;
   -------------------------------------------------------

   -------------------------------------------------------
   SCK_MISO_STARTUP_USED: if C_USE_STARTUP = 1 generate
   -----
   begin
   -----
   QSPI_STARTUP_BLOCK_I: entity axi_quad_spi_v3_2_5.qspi_startup_block
   ---------------------
   generic map
        (
                C_SUB_FAMILY     => C_SUB_FAMILY , -- support for V6/V7/K7/A7 families only
                -----------------
                C_USE_STARTUP    => C_USE_STARTUP,
                -----------------
                C_SHARED_STARTUP          => C_SHARED_STARTUP,
                -----------------
                C_SPI_MODE       => C_SPI_MODE
                -----------------
        )
   port map
        (
               SCK_O          => SCK_O_int, -- : in std_logic; -- input from the qspi_mode_0_module
               IO1_I_startup  => IO1_I,     -- : in std_logic; -- input from the top level port list
               IO1_Int        => MISO_I_int,-- : out std_logic
		         Bus2IP_Clk     => Bus2IP_Clk,
		         reset2ip_reset => reset2ip_reset_int,
			      CFGCLK         => cfgclk,       -- FGCLK        , -- 1-bit output: Configuration main clock output
               CFGMCLK        => cfgmclk, -- FGMCLK       , -- 1-bit output: Configuration internal oscillator clock output
               EOS            => eos,  -- OS           , -- 1-bit output: Active high output signal indicating the End Of Startup.
               PREQ           => preq, -- REQ          , -- 1-bit output: PROGRAM request to fabric output
               DI             => di_int,    -- output
               DO             => do_int,    -- 4-bit input
               DTS            => dts_int,   -- 4-bit input
               FCSBO          => fcsbo_int, -- 1-bit input
               FCSBTS         => fcsbts_int,-- 1-bit input
               CLK            => clk,   -- 1-bit input, SetReset
               GSR            => gsr,   -- 1-bit input, SetReset
               GTS            => gts,   -- 1-bit input
               KEYCLEARB      => keyclearb, --1-bit input
               PACK           => pack, --1-bit input
               USRCCLKTS      => usrcclkts, -- SRCCLKTS     , -- 1-bit input
               USRDONEO       => usrdoneo, -- SRDONEO      , -- 1-bit input
               USRDONETS      => usrdonets -- SRDONETS       -- 1-bit input


        );
   --------------------

   end generate SCK_MISO_STARTUP_USED;
   -------------------------------------------------------

   ----------------------------------------------------------------------------
   -- SPI_MODULE_I : INSTANTIATE SPI MODULE
   ----------------------------------------------------------------------------

   SPI_MODULE_I: entity axi_quad_spi_v3_2_5.qspi_mode_0_module
   -------------
   generic map
        (
         C_SCK_RATIO           => C_SCK_RATIO         ,
         C_USE_STARTUP         => C_USE_STARTUP       ,
         C_SPICR_REG_WIDTH     => C_SPICR_REG_WIDTH   ,
         C_NUM_SS_BITS         => C_NUM_SS_BITS       ,
         C_NUM_TRANSFER_BITS   => C_NUM_TRANSFER_BITS ,
         C_SUB_FAMILY          => C_SUB_FAMILY        ,
         C_FIFO_EXIST          => C_FIFO_EXIST
        )
   port map
        (
         Bus2IP_Clk            => EXT_SPI_CLK,                                   -- in
         Soft_Reset_op         => Rst_to_spi_int,                           -- in
         ------------------------
         SPICR_0_LOOP          => SPICR_0_LOOP_to_spi_clk,--_int,
         SPICR_1_SPE           => SPICR_1_SPE_to_spi_clk,--_int,
         SPICR_2_MASTER_N_SLV  => SPICR_2_MST_N_SLV_to_spi_clk,--_int,
         SPICR_3_CPOL          => SPICR_3_CPOL_to_spi_clk,--_int,
         SPICR_4_CPHA          => SPICR_4_CPHA_to_spi_clk,--_int,
         SPICR_5_TXFIFO_RST    => SPICR_5_TXFIFO_to_spi_clk, -- SPICR_5_TXFIFO_RST_to_spi_clk,--_int,
         SPICR_6_RXFIFO_RST    => SPICR_6_RXFIFO_RST_to_spi_clk,--_int,
         SPICR_7_SS            => SPICR_7_SS_to_spi_clk,--_int,
         SPICR_8_TR_INHIBIT    => SPICR_8_TR_INHIBIT_to_spi_clk,--_int,
         SPICR_9_LSB           => SPICR_9_LSB_to_spi_clk,--_int,
         ------------------------
         Rx_FIFO_Empty_i_no_fifo           => Rx_FIFO_Empty_i,                          -- in

         SR_3_MODF             => SR_3_modf_to_spi_clk,                         -- in
         SR_5_Tx_Empty         => Tx_FIFO_Empty, -- sr_5_Tx_Empty_int,          -- in
         Slave_MODF_strobe     => slave_MODF_strobe_int,                        -- out
         MODF_strobe           => modf_strobe_int,                              -- out

         Slave_Select_Reg      => register_Data_slvsel_int, -- already updated  -- in vec
         Transmit_Data         => Data_From_TxFIFO, -- transmit_Data_int,       -- in vec
         Receive_Data          => Data_To_Rx_FIFO, -- receive_Data_int,         -- out vec
         SPIXfer_done          => spiXfer_done_int,                             -- out
         -- SPIXfer_done_Rx_Wr_en=> SPIXfer_done_Rx_Wr_en,
         DTR_underrun          => dtr_underrun_int,                             -- out
         SPIXfer_done_rd_tx_en=> SPIXfer_done_rd_tx_en,

       --SPI Ports
         SCK_I                 => SCK_I,                                        -- in
         SCK_O_reg             => SCK_O_int,                                    -- out
         SCK_T                 => SCK_T,                                        -- out

         MISO_I                => str_IO1_I, --IO0_I,  -- MOSI_I,                     -- in  std_logic; -- MISO
         MISO_O                => str_IO1_O,--IO0_O,  -- MOSI_O,                     -- out std_logic;
         MISO_T                => str_IO1_T, --IO0_T,  -- MOSI_T,                     -- out std_logic;

         MOSI_I                => str_IO0_I,--MISO_I_int, -- IO1_I,  -- MISO_I,      -- in  std_logic;
         MOSI_O                => str_IO0_O,--IO1_O,  -- MISO_O,                     -- out std_logic; -- MOSI
         MOSI_T                => str_IO0_T,--IO1_T,  -- MISO_T,                     -- out std_logic;

         --MISO_I                => MISO_I_int, -- IO1_I,  -- MISO_I,             -- in
         --MISO_O                => IO1_O,  -- MISO_O,                            -- out
         --MISO_T                => IO1_T,  -- MISO_T,                            -- out

         --MOSI_I                => IO0_I,  -- MOSI_I,                            -- in
         --MOSI_O                => IO0_O,  -- MOSI_O,                            -- out
         --MOSI_T                => IO0_T,  -- MOSI_T,                            -- out

         SPISEL                => SPISEL,                                       -- in

         SS_I                  => SS_I_int,                                         -- in
         SS_O                  => SS_O_int,                                         -- out
         SS_T                  => SS_T_int,                                         -- out

         SPISEL_pulse_op      => spisel_pulse_o_int          ,          -- out std_logic;
         SPISEL_d1_reg        => spisel_d1_reg               ,          -- out std_logic;
         control_bit_7_8       => SPICR_bits_7_8_to_spi_clk,                          -- in vec
         Mst_N_Slv_mode        => Mst_N_Slv_mode             ,
         Rx_FIFO_Full         => Rx_FIFO_Full_to_spi_clk,
         DRR_Overrun_reg       => drr_Overrun_int,               -- out
         reset_RcFIFO_ptr_to_spi => reset_RcFIFO_ptr_to_spi_clk,
         tx_cntr_xfer_done    => tx_cntr_xfer_done
        );
   -------------

end generate LOGIC_FOR_MD_0_GEN;
----------------------------------------

-- LOGIC_FOR_MD_12_GEN: to generate the functionality for mode 1 and 2.
------------------------------
LOGIC_FOR_MD_12_GEN: if C_SPI_MODE /= 0  generate
---------------------------
signal SCK_O_int : std_logic;
signal MISO_I_int: std_logic;

signal Data_Dir_int    : std_logic;
signal Data_Mode_1_int : std_logic;
signal Data_Mode_0_int : std_logic;
signal Data_Phase_int  : std_logic;

signal Addr_Mode_1_int : std_logic;
signal Addr_Mode_0_int : std_logic;
signal Addr_Bit_int    : std_logic;
signal Addr_Phase_int  : std_logic;

signal CMD_Mode_1_int  : std_logic;
signal CMD_Mode_0_int  : std_logic;
signal CMD_Error_int   : std_logic;

signal CMD_decoded_int : std_logic;
signal Dummy_Bits_int  : std_logic_vector(3 downto 0);

-----
begin
-----
 
    LOGIC_FOR_C_SPI_MODE_1_GEN: if C_SPI_MODE = 1 generate
     -------
     begin
     -------
-- DATA_STARTUP_USED_MODE1 : if C_USE_STARTUP = 1 generate
--   -----
--    begin
--   -----
--   IO2_O <= do(2);
--   IO2_T <= dts(2);
--   IO3_O <= do(3);
--   IO3_T <= dts(3);
--   --IO2_I_int <= di(2);-- assign default value as this bit is not used in thid mode
--   IO2_I_int <= '0';-- assign default value as this bit is not used in thid mode
--   --IO3_I_int <= di(3);-- assign default value as this bit is not used in thid mode
--   IO3_I_int <= '0';-- assign default value as this bit is not used in thid mode
--end generate DATA_STARTUP_USED_MODE1;
--
--DATA_NOSTARTUP_USED_MODE1 : if C_USE_STARTUP = 0 generate
--   -----
--    begin
--   -----

          IO2_O <= '0'; -- not used in the logic
          IO3_O <= '0'; -- not used in the logic

          IO2_T <= '1'; -- disable the tri-state buffers
          IO3_T <= '1'; -- disable the tri-state buffers

          IO2_I_int <= '0';-- assign default value as this bit is not used in thid mode

          IO3_I_int <= '0';-- assign default value as this bit is not used in thid mode
--end generate DATA_NOSTARTUP_USED_MODE1;

     end generate LOGIC_FOR_C_SPI_MODE_1_GEN;
     ---------------------------------------
     LOGIC_FOR_C_SPI_MODE_2_GEN: if C_SPI_MODE = 2 generate
     -------
     begin
     -------
 DATA_STARTUP_USED_MODE2 : if (C_USE_STARTUP = 1 and C_UC_FAMILY = 1) generate
   -----
    begin
   -----
          di <= "00";
     end generate DATA_STARTUP_USED_MODE2;

 DATA_NOSTARTUP_USED_MODE2 : if (C_USE_STARTUP = 0 or (C_USE_STARTUP = 1 and C_UC_FAMILY = 0)) generate
   -----
    begin
   -----

          IO2_I_int <= IO2_I;    -- assign this bit from the top level port
          IO2_O     <= IO2_O_int;
          IO2_T     <= IO2_T_int;

          IO3_I_int <= IO3_I;    -- assign this bit from the top level port
          IO3_O     <= IO3_O_int;
          IO3_T     <= IO3_T_int;
     end generate DATA_NOSTARTUP_USED_MODE2;

     end generate LOGIC_FOR_C_SPI_MODE_2_GEN;
     ---------------------------------------


          SPISR_0_CMD_Error_int <= CMD_Error_int;
          dtr_underrun_int      <= '0'; -- SPI MODE 1 & 2 are master modes, so DTR under run wont be present
          slave_MODF_strobe_int <= '0'; -- SPI MODE 1 & 2 are master modes, so the slave mode fault error wont appear
          Mst_N_Slv_mode        <= '1';
          -------------------------------------------------------
          -- SCK_O      <= SCK_O_int;   -- output from the core
          -- MISO_I_int <= IO1_I;       -- input to the core
-- *
          -------------------------------------------------------
          SCK_MISO_NO_STARTUP_USED: if C_USE_STARTUP = 0 generate
          -----
          begin
          -----
               SCK_O      <= SCK_O_int;   -- output from the core
               MISO_I_int <= IO1_I;       -- input to the core

          end generate SCK_MISO_NO_STARTUP_USED;
          -------------------------------------------------------

          -------------------------------------------------------
          SCK_MISO_STARTUP_USED: if C_USE_STARTUP = 1 generate
          -----
          begin
          -----
          QSPI_STARTUP_BLOCK_I: entity axi_quad_spi_v3_2_5.qspi_startup_block
          ---------------------
          generic map
               (
                       C_SUB_FAMILY     => C_SUB_FAMILY , -- support for V6/V7/K7/A7 families only
                       -----------------
                       C_USE_STARTUP    => C_USE_STARTUP,
                       -----------------
                       C_SHARED_STARTUP          => C_SHARED_STARTUP,

                       -----------------
                       C_SPI_MODE       => C_SPI_MODE
                       -----------------
               )
          port map
               (
                       SCK_O          => SCK_O_int, -- : in std_logic; -- input from the qspi_mode_0_module
                       IO1_I_startup  => IO1_I,     -- : in std_logic; -- input from the top level port list
                       IO1_Int        => MISO_I_int,-- : out std_logic
		       Bus2IP_Clk     => Bus2IP_Clk,
		       reset2ip_reset => reset2ip_reset_int,
			   CFGCLK         => cfgclk,       -- FGCLK        , -- 1-bit output: Configuration main clock output
               CFGMCLK        => cfgmclk, -- FGMCLK       , -- 1-bit output: Configuration internal oscillator clock output
               EOS            => eos,  -- OS           , -- 1-bit output: Active high output signal indicating the End Of Startup.
               PREQ           => preq, -- REQ          , -- 1-bit output: PROGRAM request to fabric output
               DI             => di_int,    -- output
               DO             => do_int,    -- 4-bit input
               DTS            => dts_int,   -- 4-bit input
               FCSBO          => fcsbo_int, -- 1-bit input
               FCSBTS         => fcsbts_int,-- 1-bit input
               CLK            => clk,   -- 1-bit input, SetReset
               GSR            => gsr,   -- 1-bit input, SetReset
               GTS            => gts,   -- 1-bit input
               KEYCLEARB      => keyclearb, --1-bit input
               PACK           => pack, --1-bit input
               USRCCLKTS      => usrcclkts, -- SRCCLKTS     , -- 1-bit input
               USRDONEO       => usrdoneo, -- SRDONEO      , -- 1-bit input
               USRDONETS      => usrdonets -- SRDONETS       -- 1-bit input


               );
          --------------------

          end generate SCK_MISO_STARTUP_USED;
          -------------------------------------------------------
-- *
          -- Add instance for Look up table logic
          SPI_MODE_1_LUT_LOGIC_I: entity axi_quad_spi_v3_2_5.qspi_look_up_logic
          -------------
          generic map
               (
                 C_FAMILY            => C_FAMILY           ,
                 C_SPI_MODE          => C_SPI_MODE         ,
                 C_SPI_MEMORY        => C_SPI_MEMORY       ,
                 C_NUM_TRANSFER_BITS => C_NUM_TRANSFER_BITS
               )
          port map
               (
                 EXT_SPI_CLK         => EXT_SPI_CLK         ,                   -- : in std_logic;
                 Rst_to_spi          => Rst_to_spi_int      ,                   -- : in std_logic;
                 TXFIFO_RST          => reset_TxFIFO_ptr_int_to_spi,                   -- : in std_logic;
                 --------------------                                           --
                 DTR_FIFO_Data_Exists=> data_Exists_TxFIFO_int,                 -- : in std_logic;
                 Data_From_TxFIFO    => Data_From_TxFIFO   ,                    -- : in std_logic_vector
                                                                                --              (0 to (C_NUM_TRANSFER_BITS-1))
                 pr_state_idle       => pr_state_idle_int  ,                    --
                 --------------------                                           --
                 Data_Dir            => Data_Dir_int       ,                    -- : out std_logic;
                 Data_Mode_1         => Data_Mode_1_int    ,                    -- : out std_logic;
                 Data_Mode_0         => Data_Mode_0_int    ,                    -- : out std_logic;
                 Data_Phase          => Data_Phase_int     ,                    -- : out std_logic;
                 --------------------                                           --
                 Quad_Phase          => Quad_Phase_int     ,
                 --------------------                                           --
                 Addr_Mode_1         => Addr_Mode_1_int    ,                    -- : out std_logic;
                 Addr_Mode_0         => Addr_Mode_0_int    ,                    -- : out std_logic;
                 Addr_Bit            => Addr_Bit_int       ,                    -- : out std_logic;
                 Addr_Phase          => Addr_Phase_int     ,                    -- : out std_logic;
                 --------------------                                           --
                 CMD_Mode_1          => CMD_Mode_1_int     ,                    -- : out std_logic;
                 CMD_Mode_0          => CMD_Mode_0_int     ,                    -- : out std_logic;
                 CMD_Error           => CMD_Error_int      ,                    -- : out std_logic;
                 --------------------                                           -- -
                 CMD_decoded         => CMD_decoded_int                         -- : out std_logic
               );
          ---------

          SPI_MODE_CONTROL_LOGIC_I: entity axi_quad_spi_v3_2_5.qspi_mode_control_logic
          -------------
          generic map
               (
                 C_SCK_RATIO          => C_SCK_RATIO         ,
                 C_NUM_TRANSFER_BITS  => C_NUM_TRANSFER_BITS ,
                 C_SPI_MODE           => C_SPI_MODE          ,
                 C_USE_STARTUP        => C_USE_STARTUP       ,
                 C_NUM_SS_BITS        => C_NUM_SS_BITS       ,
                 C_SPI_MEMORY         => C_SPI_MEMORY        ,
                 C_SUB_FAMILY         => C_SUB_FAMILY
               )
          port map
               (
                 Bus2IP_Clk           =>  EXT_SPI_CLK               , -- Bus2IP_Clk                ,           -- in std_logic;
                 Soft_Reset_op        =>  Rst_to_spi_int            ,           -- in std_logic;
                 --------------------                               ,           --
                 DTR_FIFO_Data_Exists =>  data_Exists_TxFIFO_int    ,           -- in std_logic;
                 Slave_Select_Reg     =>  register_Data_slvsel_int  , -- already updated            -- in  std_logic_vector(0 to (C_NUM_SS_BITS-1));
                 Transmit_Data        =>  Data_From_TxFIFO,--transmit_Data_int         , -- already updated           -- in  std_logic_vector(0 to (C_NUM_TRANSFER_BITS
                 Receive_Data         =>  Data_To_Rx_FIFO           ,           -- out std_logic_vector(0 to (C_NUM_TRANSFER_BITS
                 --Data_To_Rx_FIFO_1    => Data_To_Rx_FIFO_1,
                 SPIXfer_done         =>  spiXfer_done_int          , -- already updated           -- out std_logic;
                 SPIXfer_done_Rx_Wr_en=> SPIXfer_done_Rx_Wr_en,
                 MODF_strobe          =>  modf_strobe_int           , -- already updated
                 SPIXfer_done_rd_tx_en=> SPIXfer_done_rd_tx_en,
                 ---------------------                                         --
                 SR_3_MODF            =>  SR_3_modf_to_spi_clk      ,           -- in std_logic;
                 SR_5_Tx_Empty        =>  Tx_FIFO_Empty             , -- sr_5_Tx_Empty_int   -- in std_logic;
                 --SR_6_Rx_Full         =>  Rx_FIFO_Full              ,           -- in
                 pr_state_idle        =>  pr_state_idle_int         ,           --
                 ---------------------                                          -- from control register
                 SPICR_0_LOOP         =>  SPICR_0_LOOP_to_spi_clk     ,--SPICR_0_LOOP_int          ,           -- in std_logic;
                 SPICR_1_SPE          =>  SPICR_1_SPE_to_spi_clk      ,--_int           ,           -- in std_logic;
                 SPICR_2_MASTER_N_SLV =>  SPICR_2_MST_N_SLV_to_spi_clk,--_int  ,           -- in std_logic;
                 SPICR_3_CPOL         =>  SPICR_3_CPOL_to_spi_clk     ,--_int          ,           -- in std_logic;
                 SPICR_4_CPHA         =>  SPICR_4_CPHA_to_spi_clk     ,--_int          ,           -- in std_logic;
                 SPICR_5_TXFIFO_RST   =>  SPICR_5_TXFIFO_RST_to_spi_clk,--_int    ,           -- in std_logic;
                 SPICR_6_RXFIFO_RST   =>  SPICR_6_RXFIFO_RST_to_spi_clk,--_int    ,           -- in std_logic;
                 SPICR_7_SS           =>  SPICR_7_SS_to_spi_clk        ,--_int            ,           -- in std_logic;
                 SPICR_8_TR_INHIBIT   =>  SPICR_8_TR_INHIBIT_to_spi_clk,--_int    ,           -- in std_logic;
                 SPICR_9_LSB          =>  SPICR_9_LSB_to_spi_clk       ,--_int           ,           -- in std_logic;
                 ---------------------                                          --

                 ---------------------                                          -- from look up table
                 Data_Dir             => Data_Dir_int               ,           -- in std_logic;
                 Data_Mode_1          => Data_Mode_1_int            ,           -- in std_logic;
                 Data_Mode_0          => Data_Mode_0_int            ,           -- in std_logic;
                 Data_Phase           => Data_Phase_int             ,
                 ---------------------
                 --Dummy_Bits           => Dummy_Bits_int             ,           -- in std_logic_vector(3 downto 0);
                 Quad_Phase           => Quad_Phase_int             ,
                 ---------------------                                          -- in std_logic;
                 Addr_Mode_1          => Addr_Mode_1_int            ,           -- in std_logic;
                 Addr_Mode_0          => Addr_Mode_0_int            ,           -- in std_logic;
                 Addr_Bit             => Addr_Bit_int               ,           -- in std_logic;
                 Addr_Phase           => Addr_Phase_int             ,           -- in std_logic;
                 ---------------------
                 CMD_Mode_1           => CMD_Mode_1_int             ,           -- in std_logic;
                 CMD_Mode_0           => CMD_Mode_0_int             ,           -- in std_logic;
                 CMD_Error            => CMD_Error_int              ,           -- in std_logic;
                 ---------------------                                          --
                 CMD_decoded          => CMD_decoded_int            ,           -- in std_logic;

                 --SPI Interface                                                --
                 SCK_I                => SCK_I,                                 -- in  std_logic;
                 SCK_O_reg            => SCK_O_int,                             -- out std_logic;
                 SCK_T                => SCK_T,                                 -- out std_logic;
                                                                                --
                 IO0_I                => str_IO0_I, --IO0_I,  -- MOSI_I,                     -- in  std_logic; -- MISO
                 IO0_O                => str_IO0_O,--IO0_O,  -- MOSI_O,                     -- out std_logic;
                 IO0_T                => str_IO0_T, --IO0_T,  -- MOSI_T,                     -- out std_logic;

                 IO1_I                => str_IO1_I,--MISO_I_int, -- IO1_I,  -- MISO_I,      -- in  std_logic;
                 IO1_O                => str_IO1_O,--IO1_O,  -- MISO_O,                     -- out std_logic; -- MOSI
                 IO1_T                => str_IO1_T,--IO1_T,  -- MISO_T,                     -- out std_logic;
                                                                                --
                 IO2_I                => IO2_I_int,  --                         -- in  std_logic;
                 IO2_O                => IO2_O_int,  --                         -- out std_logic;
                 IO2_T                => IO2_T_int,  --                         -- out std_logic;
                                                                                --
                 IO3_I                => IO3_I_int,  --                         -- in  std_logic;
                 IO3_O                => IO3_O_int,  --                         -- out std_logic;
                 IO3_T                => IO3_T_int,  --                         -- out std_logic;
                                                                                --
                 SPISEL               => SPISEL,                                -- in  std_logic;
                                                                                --
                 SS_I                 => SS_I_int,                                  -- in std_logic_vector(0 to (C_NUM_SS_BITS-1));
                 SS_O                 => SS_O_int,                                  -- out std_logic_vector(0 to (C_NUM_SS_BITS-1));
                 SS_T                 => SS_T_int,                                  -- out std_logic;
                                                                                --
                 SPISEL_pulse_op      => spisel_pulse_o_int          ,          -- out std_logic;
                 SPISEL_d1_reg        => spisel_d1_reg               ,          -- out std_logic;
                 Control_bit_7_8      => SPICR_bits_7_8_to_spi_clk   ,           -- in std_logic_vector(0 to 1) --(7 to 8)
                 Rx_FIFO_Full         => Rx_FIFO_Full,
                 DRR_Overrun_reg       => drr_Overrun_int,
                 reset_RcFIFO_ptr_to_spi => reset_RcFIFO_ptr_to_spi_clk
               );
          -------------

end generate LOGIC_FOR_MD_12_GEN;
------------------------------------------
--------------------------------------------------------------------------------
 CONTROL_REG_I: entity axi_quad_spi_v3_2_5.qspi_cntrl_reg
             generic map
             (
             --------------------------
             C_S_AXI_DATA_WIDTH         => C_S_AXI_DATA_WIDTH,
             --------------------------
             -- Number of bits in regis
             C_SPI_NUM_BITS_REG         => C_SPI_NUM_BITS_REG,
             --------------------------
             C_SPICR_REG_WIDTH          => C_SPICR_REG_WIDTH,
             --------------------------
             C_SPI_MODE                 => C_SPI_MODE
             --------------------------
             )
             port map
             (                                                                  -- in
             Bus2IP_Clk                 => Bus2IP_Clk,                          -- in
             Soft_Reset_op              => reset2ip_reset_int,
             ---------------------------
             Wr_ce_reduce_ack_gen       => Wr_ce_reduce_ack_gen,                -- in
             Bus2IP_SPICR_WrCE          => Bus2IP_WrCE(SPICR),                  -- in
             Bus2IP_SPICR_RdCE          => Bus2IP_RdCE(SPICR),                  -- in
             Bus2IP_SPICR_data          => Bus2IP_Data,                         -- in vec
             ---------------------------
             SPICR_0_LOOP               => SPICR_0_LOOP_frm_axi_clk,                    -- out
             SPICR_1_SPE                => SPICR_1_SPE_frm_axi_clk,                     -- out
             SPICR_2_MASTER_N_SLV       => SPICR_2_MST_N_SLV_frm_axi_clk,            -- out
             SPICR_3_CPOL               => SPICR_3_CPOL_frm_axi_clk,                    -- out
             SPICR_4_CPHA               => SPICR_4_CPHA_frm_axi_clk,                    -- out
             SPICR_5_TXFIFO_RST         => SPICR_5_TXFIFO_RST_frm_axi_clk,              -- out
             SPICR_6_RXFIFO_RST         => SPICR_6_RXFIFO_RST_frm_axi_clk,              -- out
             SPICR_7_SS                 => SPICR_7_SS_frm_axi_clk,                      -- out
             SPICR_8_TR_INHIBIT         => SPICR_8_TR_INHIBIT_frm_axi_clk,              -- out
             SPICR_9_LSB                => SPICR_9_LSB_frm_axi_clk,                     -- out
             -- to Status Register
             SPISR_1_LOOP_Back_Error    => SPISR_1_LOOP_Back_Error_int,         -- out
             SPISR_2_MSB_Error          => SPISR_2_MSB_Error_int,               -- out
             SPISR_3_Slave_Mode_Error   => SPISR_3_Slave_Mode_Error_int,        -- out
             SPISR_4_CPOL_CPHA_Error    => SPISR_4_CPOL_CPHA_Error_int,         -- out
             ---------------------------
             IP2Bus_SPICR_Data          => IP2Bus_SPICR_Data_int,               -- out vec
             ---------------------------
             Control_bit_7_8            => SPICR_bits_7_8_frm_axi_clk           -- out vec
             ---------------------------
             );


-------------------------------------------------------------------------------
-- STATUS_REG_I : INSTANTIATE STATUS REGISTER
-------------------------------------------------------------------------------
   STATUS_REG_MODE_0_GEN: if C_SPI_MODE = 0 generate
   begin

       STATUS_SLAVE_SEL_REG_I: entity axi_quad_spi_v3_2_5.qspi_status_slave_sel_reg
                generic map(
                C_SPI_NUM_BITS_REG      => C_SPI_NUM_BITS_REG            ,
                ------------------------   ------------------------
                C_S_AXI_DATA_WIDTH      => C_S_AXI_DATA_WIDTH            ,
                ------------------------   ------------------------
                C_NUM_SS_BITS           => C_NUM_SS_BITS                 ,
                ------------------------   ------------------------
                C_SPISR_REG_WIDTH       => C_SPISR_REG_WIDTH
                )
                port map(
                Bus2IP_Clk                  =>  Bus2IP_Clk                    , -- in
                Soft_Reset_op               =>  reset2ip_reset_int            , -- in
                -- I/P from control regis
                SPISR_0_Command_Error       =>  '0'                           , -- SPISR_0_CMD_Error_int         , -- in-- should come from look up table
                SPISR_1_LOOP_Back_Error     =>  SPISR_1_LOOP_Back_Error_int   , -- in
                SPISR_2_MSB_Error           =>  SPISR_2_MSB_Error_int         , -- in
                SPISR_3_Slave_Mode_Error    =>  SPISR_3_Slave_Mode_Error_int  , -- in
                SPISR_4_CPOL_CPHA_Error     =>  SPISR_4_CPOL_CPHA_Error_int   , -- in
                -- I/P from other modules
                SPISR_Ext_SPISEL_slave      =>  spisel_d1_reg_to_axi_clk      , -- in
                SPISR_7_Tx_Full             =>  Tx_FIFO_Full_int                  , -- in
                SPISR_8_Tx_Empty            =>  Tx_FIFO_Empty_SPISR_to_axi_clk, -- Tx_FIFO_Empty_to_Axi_clk      , -- in
                SPISR_9_Rx_Full             =>  Rx_FIFO_Full_int, -- Rx_FIFO_Full_to_axi_clk       , -- in
                SPISR_10_Rx_Empty           =>  Rx_FIFO_Empty_int                 , -- in

                -- Slave attachment ports
                ModeFault_Strobe            =>  modf_strobe_to_axi_clk        , -- in
                Rd_ce_reduce_ack_gen        =>  rd_ce_reduce_ack_gen          , -- in
                Bus2IP_SPISR_RdCE           =>  Bus2IP_RdCE(SPISR)            , -- in

                IP2Bus_SPISR_Data           =>  IP2Bus_SPISR_Data_int         , -- out vec
                SR_3_modf                   =>  SR_3_modf_int                 , -- out
                -- Slave Select Register
                Bus2IP_SPISSR_WrCE          =>  Bus2IP_WrCE(SPISSR)           , -- in
                Wr_ce_reduce_ack_gen        =>  Wr_ce_reduce_ack_gen          , -- in
                Bus2IP_SPISSR_RdCE          =>  Bus2IP_RdCE(SPISSR)           , -- in
                Bus2IP_SPISSR_Data          =>  Bus2IP_Data                   , -- in vec
                IP2Bus_SPISSR_Data          =>  IP2Bus_SPISSR_Data_int        , -- out vec

                SPISSR_Data_reg_op          =>  SPISSR_frm_axi_clk        -- out vec
                );

   end generate STATUS_REG_MODE_0_GEN;

   STATUS_REG_MODE_12_GEN: if C_SPI_MODE /= 0 generate
   begin

       STATUS_SLAVE_SEL_REG_I: entity axi_quad_spi_v3_2_5.qspi_status_slave_sel_reg
                generic map(
                C_SPI_NUM_BITS_REG      => C_SPI_NUM_BITS_REG            ,
                ------------------------   ------------------------
                C_S_AXI_DATA_WIDTH      => C_S_AXI_DATA_WIDTH            ,
                ------------------------   ------------------------
                C_NUM_SS_BITS           => C_NUM_SS_BITS                 ,
                ------------------------   ------------------------
                C_SPISR_REG_WIDTH       => C_SPISR_REG_WIDTH
                )
                port map(
                Bus2IP_Clk                  =>  Bus2IP_Clk                    , -- in
                Soft_Reset_op               =>  reset2ip_reset_int            , -- in
                -- I/P from control regis
                SPISR_0_Command_Error       =>  SPISR_0_CMD_Error_to_axi_clk  , -- SPISR_0_CMD_Error_int         , -- in-- should come from look up table
                SPISR_1_LOOP_Back_Error     =>  SPISR_1_LOOP_Back_Error_int   , -- in
                SPISR_2_MSB_Error           =>  SPISR_2_MSB_Error_int         , -- in
                SPISR_3_Slave_Mode_Error    =>  SPISR_3_Slave_Mode_Error_int  , -- in
                SPISR_4_CPOL_CPHA_Error     =>  SPISR_4_CPOL_CPHA_Error_int   , -- in
                -- I/P from other modules
                SPISR_Ext_SPISEL_slave      =>  spisel_d1_reg_to_axi_clk      , -- in
                SPISR_7_Tx_Full             =>  Tx_FIFO_Full_int                  , -- in
                SPISR_8_Tx_Empty            =>  Tx_FIFO_Empty_SPISR_to_axi_clk, -- Tx_FIFO_Empty_to_Axi_clk      , -- in
                SPISR_9_Rx_Full             =>  Rx_FIFO_Full_int, -- Rx_FIFO_Full_to_axi_clk       , -- in
                SPISR_10_Rx_Empty           =>  Rx_FIFO_Empty_int                 , -- in

                -- Slave attachment ports
                ModeFault_Strobe            =>  modf_strobe_to_axi_clk        , -- in
                Rd_ce_reduce_ack_gen        =>  rd_ce_reduce_ack_gen          , -- in
                Bus2IP_SPISR_RdCE           =>  Bus2IP_RdCE(SPISR)            , -- in

                IP2Bus_SPISR_Data           =>  IP2Bus_SPISR_Data_int         , -- out vec
                SR_3_modf                   =>  SR_3_modf_int                 , -- out
                -- Slave Select Register
                Bus2IP_SPISSR_WrCE          =>  Bus2IP_WrCE(SPISSR)           , -- in
                Wr_ce_reduce_ack_gen        =>  Wr_ce_reduce_ack_gen          , -- in
                Bus2IP_SPISSR_RdCE          =>  Bus2IP_RdCE(SPISSR)           , -- in
                Bus2IP_SPISSR_Data          =>  Bus2IP_Data                   , -- in vec
                IP2Bus_SPISSR_Data          =>  IP2Bus_SPISSR_Data_int        , -- out vec

                SPISSR_Data_reg_op          =>  SPISSR_frm_axi_clk        -- out vec
                );
    end generate STATUS_REG_MODE_12_GEN;
-------------------------------------------------------------------------------
-- SOFT_RESET_I : INSTANTIATE SOFT RESET
-------------------------------------------------------------------------------
     SOFT_RESET_I: entity axi_quad_spi_v3_2_5.soft_reset
        generic map
             (
              C_SIPIF_DWIDTH     => C_S_AXI_DATA_WIDTH,
              -- Width of triggered reset in Bus Clocks
              C_RESET_WIDTH      => 16
             )
        port map
             (
              -- Inputs From the PLBv46 Slave Single Bus
              Bus2IP_Clk         => Bus2IP_Clk,                                 -- in
              Bus2IP_Reset       => Bus2IP_Reset,                               -- in

              Bus2IP_WrCE        => Bus2IP_WrCE(SWRESET),                       -- in
              Bus2IP_Data        => Bus2IP_Data,                                -- in
              Bus2IP_BE          => Bus2IP_BE,                                  -- in

              -- Final Device Reset Output
              Reset2IP_Reset     => reset2ip_reset_int,                         -- out

              -- Status Reply Outputs to the Bus
              Reset2Bus_WrAck    => rst_ip2bus_wrack,                           -- out
              Reset2Bus_Error    => rst_ip2bus_error,                           -- out
              Reset2Bus_ToutSup  => open                                        -- out
             );

-------------------------------------------------------------------------------
-- INTERRUPT_CONTROL_I : INSTANTIATE INTERRUPT CONTROLLER
-------------------------------------------------------------------------------

 bus2ip_intr_rdce <= "0000000"      &
                     Bus2IP_RdCE(7) &
                     Bus2IP_RdCE(8) &
                     '0'            &
                     Bus2IP_RdCE(10)&
                     "00000";

 bus2ip_intr_wrce <= "0000000"      &
                     Bus2IP_WrCE(7) &
                     Bus2IP_WrCE(8) &
                     '0'            &
                     Bus2IP_WrCE(10)&
                     "00000";

 ------------------------------------------------------------------------------
 intr_controller_rd_ce_or_reduce <= or_reduce(Bus2IP_RdCE(0 to 6)) or
                                    Bus2IP_RdCE(9)                 or
                                    or_reduce(Bus2IP_RdCE(11 to 15));

 ------------------------------------------------------------------------------
 I_READ_ACK_INTR_HOLES: process(Bus2IP_Clk) is
 begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if (reset2ip_reset_int = RESET_ACTIVE) then
          ip2Bus_RdAck_intr_reg_hole     <= '0';
          ip2Bus_RdAck_intr_reg_hole_d1  <= '0';
      else
          ip2Bus_RdAck_intr_reg_hole_d1 <= intr_controller_rd_ce_or_reduce;
          ip2Bus_RdAck_intr_reg_hole    <= intr_controller_rd_ce_or_reduce and
                                            (not ip2Bus_RdAck_intr_reg_hole_d1);
      end if;
    end if;
 end process I_READ_ACK_INTR_HOLES;
 ------------------------------------------------------------------------------
 intr_controller_wr_ce_or_reduce <= or_reduce(Bus2IP_WrCE(0 to 6)) or
                                    Bus2IP_WrCE(9)                 or
                                    or_reduce(Bus2IP_WrCE(11 to 15));

 ------------------------------------------------------------------------------
 I_WRITE_ACK_INTR_HOLES: process(Bus2IP_Clk) is
 -----
 begin
 -----
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if (reset2ip_reset_int = RESET_ACTIVE) then
          ip2Bus_WrAck_intr_reg_hole     <= '0';
          ip2Bus_WrAck_intr_reg_hole_d1  <= '0';
      else
          ip2Bus_WrAck_intr_reg_hole_d1 <= intr_controller_wr_ce_or_reduce;
          ip2Bus_WrAck_intr_reg_hole    <= intr_controller_wr_ce_or_reduce and
                                            (not ip2Bus_WrAck_intr_reg_hole_d1);
      end if;
    end if;
 end process I_WRITE_ACK_INTR_HOLES;
 ------------------------------------------------------------------------------

     INTERRUPT_CONTROL_I: entity interrupt_control_v3_1_2.interrupt_control
        generic map
             (
              C_NUM_CE               => 16,
              C_NUM_IPIF_IRPT_SRC    =>  1,  -- Set to 1 to avoid null array
              C_IP_INTR_MODE_ARRAY   => C_IP_INTR_MODE_ARRAY,

              -- Specifies device Priority Encoder function
              C_INCLUDE_DEV_PENCODER => false,

              -- Specifies device ISC hierarchy
              C_INCLUDE_DEV_ISC      => false,

              C_IPIF_DWIDTH          => C_S_AXI_DATA_WIDTH
             )
        port map
             (
              Bus2IP_Clk             =>  Bus2IP_Clk,                            -- in
              Bus2IP_Reset           =>  reset2ip_reset_int,                    -- in
              Bus2IP_Data            =>  bus2IP_Data_for_interrupt_core,                 -- in vec
              Bus2IP_BE              =>  Bus2IP_BE,                             -- in vec
              Interrupt_RdCE         =>  bus2ip_intr_rdce,                      -- in vec
              Interrupt_WrCE         =>  bus2ip_intr_wrce,                      -- in vec
              IPIF_Reg_Interrupts    =>  "00", -- Tie off the unused reg intrs
              IPIF_Lvl_Interrupts    =>  "0",  -- Tie off the dummy lvl intr
              IP2Bus_IntrEvent       =>  ip2Bus_IntrEvent_int,                  -- in
              Intr2Bus_DevIntr       =>  IP2INTC_Irpt,                          -- out
              Intr2Bus_DBus          =>  intr_ip2bus_data,                      -- out vec
              Intr2Bus_WrAck         =>  intr_ip2bus_wrack,                     -- out
              Intr2Bus_RdAck         =>  intr_ip2bus_rdack,                     -- out
              Intr2Bus_Error         =>  intr_ip2bus_error,                     -- out
              Intr2Bus_Retry         =>  open,
              Intr2Bus_ToutSup       =>  open
             );
--------------------------------------------------------------------------------
end imp;
--------------------------------------------------------------------------------
