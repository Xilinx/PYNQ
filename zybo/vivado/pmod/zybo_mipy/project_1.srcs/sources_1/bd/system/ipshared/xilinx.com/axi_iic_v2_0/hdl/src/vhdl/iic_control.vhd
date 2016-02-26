-------------------------------------------------------------------------------
-- iic_control.vhd - entity/architecture pair
-------------------------------------------------------------------------------
--  ***************************************************************************
--  ** DISCLAIMER OF LIABILITY                                               **
--  **                                                                       **
--  **  This file contains proprietary and confidential information of       **
--  **  Xilinx, Inc. ("Xilinx"), that is distributed under a license         **
--  **  from Xilinx, and may be used, copied and/or disclosed only           **
--  **  pursuant to the terms of a valid license agreement with Xilinx.      **
--  **                                                                       **
--  **  XILINX is PROVIDING THIS DESIGN, CODE, OR INFORMATION                **
--  **  ("MATERIALS") "AS is" WITHOUT WARRANTY OF ANY KIND, EITHER           **
--  **  EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT                  **
--  **  LIMITATION, ANY WARRANTY WITH RESPECT to NONINFRINGEMENT,            **
--  **  MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx        **
--  **  does not warrant that functions included in the Materials will       **
--  **  meet the requirements of Licensee, or that the operation of the      **
--  **  Materials will be uninterrupted or error-free, or that defects       **
--  **  in the Materials will be corrected. Furthermore, Xilinx does         **
--  **  not warrant or make any representations regarding use, or the        **
--  **  results of the use, of the Materials in terms of correctness,        **
--  **  accuracy, reliability or otherwise.                                  **
--  **                                                                       **
--  **  Xilinx products are not designed or intended to be fail-safe,        **
--  **  or for use in any application requiring fail-safe performance,       **
--  **  such as life-support or safety devices or systems, Class III         **
--  **  medical devices, nuclear facilities, applications related to         **
--  **  the deployment of airbags, or any other applications that could      **
--  **  lead to death, personal injury or severe property or                 **
--  **  environmental damage (individually and collectively, "critical       **
--  **  applications"). Customer assumes the sole risk and liability         **
--  **  of any use of Xilinx products in critical applications,              **
--  **  subject only to applicable laws and regulations governing            **
--  **  limitations on product liability.                                    **
--  **                                                                       **
--  **  Copyright 2011 Xilinx, Inc.                                          **
--  **  All rights reserved.                                                 **
--  **                                                                       **
--  **  This disclaimer and copyright notice must be retained as part        **
--  **  of this file at all times.                                           **
--  ***************************************************************************
-------------------------------------------------------------------------------
-- Filename:        iic_control.vhd
-- Version:         v1.01.b
-- Description:
--                  This file contains the main state machines for the iic
--                  bus interface logic
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--
--           axi_iic.vhd
--              -- iic.vhd
--                  -- axi_ipif_ssp1.vhd
--                      -- axi_lite_ipif.vhd
--                      -- interrupt_control.vhd
--                      -- soft_reset.vhd
--                  -- reg_interface.vhd
--                  -- filter.vhd
--                      -- debounce.vhd
--                  -- iic_control.vhd
--                      -- upcnt_n.vhd
--                      -- shift8.vhd
--                  -- dynamic_master.vhd
--                  -- iic_pkg.vhd
--
-------------------------------------------------------------------------------
-- Author:          USM
--
--  USM     10/15/09
-- ^^^^^^
--  - Initial release of v1.00.a
-- ~~~~~~
--
--  USM     09/06/10
-- ^^^^^^
--  - Release of v1.01.a
--  - Added function calc_tbuf to calculate the TBUF delay
-- ~~~~~~
--
--  NLR     01/07/11
-- ^^^^^^
--  - Fixed the CR#613282
--  - Release of v1.01.b
-- ~~~~~~
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library axi_iic_v2_0_9;
use axi_iic_v2_0_9.iic_pkg.all;
use axi_iic_v2_0_9.upcnt_n;
use axi_iic_v2_0_9.shift8;

-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-- Definition of Generics:
--      C_S_AXI_ACLK_FREQ_HZ-- Specifies AXI clock frequency
--      C_IIC_FREQ          -- Maximum IIC frequency of Master Mode in Hz
--      C_TEN_BIT_ADR       -- 10 bit slave addressing
--
-- Definition of Ports:
--      Sys_clk             -- System clock
--      Reset               -- System Reset
--      Sda_I               -- IIC serial data input
--      Sda_O               -- IIC serial data output
--      Sda_T               -- IIC seral data output enable
--      Scl_I               -- IIC serial clock input
--      Scl_O               -- IIC serial clock output
--      Scl_T               -- IIC serial clock output enable
--      Txak                -- Value for acknowledge when xmit
--      Gc_en               -- General purpose outputs
--      Ro_prev             -- Receive over run prevent
--      Dtre                -- Data transmit register empty
--      Msms                -- Data transmit register empty
--      Msms_rst            -- Msms Reset signal
--      Msms_set            -- Msms set
--      Rsta                -- Repeated start
--      Rsta_rst            -- Repeated start Reset
--      Tx                  -- Master read/write
--      Dtr                 -- Data transmit register
--      Adr                 -- IIC slave address
--      Ten_adr             -- IIC slave 10 bit address
--      Bb                  -- Bus busy indicator
--      Dtc                 -- Data transfer
--      Aas                 -- Addressed as slave indicator
--      Al                  -- Arbitration lost indicator
--      Srw                 -- Slave read/write indicator
--      Txer                -- Received acknowledge indicator
--      Abgc                -- Addressed by general call indicator
--      Data_i2c            -- IIC data for processor
--      New_rcv_dta         -- New Receive Data ready
--      Rdy_new_xmt         -- New data loaded in shift reg indicator
--      Tx_under_prev       -- DTR or Tx FIFO empty IRQ indicator
--      EarlyAckHdr         -- ACK_HEADER state strobe signal
--      EarlyAckDataState   -- Data ack early acknowledge signal
--      AckDataState        -- Data ack acknowledge signal
-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
entity iic_control is
   generic(
      C_SCL_INERTIAL_DELAY        : integer range 0 to 255 := 5;
      C_S_AXI_ACLK_FREQ_HZ        : integer := 100000000;
      C_IIC_FREQ                  : integer := 100000;
      C_SIZE                      : integer := 32;
      C_TEN_BIT_ADR               : integer := 0;
      C_SDA_LEVEL                 : integer := 1;
      C_SMBUS_PMBUS_HOST          : integer := 0   -- SMBUS/PMBUS support
      );
   port(

      -- System signals
      Sys_clk           : in std_logic;
      Reset             : in std_logic;

      -- iic bus tristate driver control signals
      Sda_I             : in  std_logic;
      Sda_O             : out std_logic;
      Sda_T             : out std_logic;
      Scl_I             : in  std_logic;
      Scl_O             : out std_logic;
      Scl_T             : out std_logic;

      Timing_param_tsusta   : in std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_tsusto   : in std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_thdsta   : in std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_tsudat   : in std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_tbuf     : in std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_thigh    : in std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_tlow     : in std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_thddat   : in std_logic_vector(C_SIZE-1 downto 0);

      -- interface signals from uP
      Txak              : in  std_logic;
      Gc_en             : in  std_logic;
      Ro_prev           : in  std_logic;
      Dtre              : in  std_logic;
      Msms              : in  std_logic;
      Msms_rst          : out std_logic;
      Msms_set          : in  std_logic;
      Rsta              : in  std_logic;
      Rsta_rst          : out std_logic;
      Tx                : in  std_logic;
      Dtr               : in  std_logic_vector(7 downto 0);
      Adr               : in  std_logic_vector(7 downto 0);
      Ten_adr           : in  std_logic_vector(7 downto 5);
      Bb                : out std_logic;
      Dtc               : out std_logic;
      Aas               : out std_logic;
      Al                : out std_logic;
      Srw               : out std_logic;
      Txer              : out std_logic;
      Abgc              : out std_logic;
      Data_i2c          : out std_logic_vector(7 downto 0);
      New_rcv_dta       : out std_logic;
      Rdy_new_xmt       : out std_logic;
      Tx_under_prev     : out std_logic;
      EarlyAckHdr       : out std_logic;
      EarlyAckDataState : out std_logic;
      AckDataState      : out std_logic;
      reg_empty         :out std_logic
      );

end iic_control;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

architecture RTL of iic_control is
  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";



   constant CLR_REG    : std_logic_vector(7 downto 0)       := "00000000";
   constant START_CNT  : std_logic_vector(3 downto 0)       := "0000";
   constant CNT_DONE   : std_logic_vector(3 downto 0)       := "1000";
   constant ZERO_CNT   : std_logic_vector(C_SIZE-1 downto 0):= (others => '0');
   constant ZERO       : std_logic                          := '0';
   constant ENABLE_N   : std_logic                          := '0';
   constant CNT_ALMOST_DONE : std_logic_vector (3 downto 0) := "0111";

   type state_type is (IDLE,
                       HEADER,
                       ACK_HEADER,
                       RCV_DATA,
                       ACK_DATA,
                       XMIT_DATA,
                       WAIT_ACK);
   signal state : state_type;

   type scl_state_type is (SCL_IDLE,
                           START,
                           START_EDGE,
                           SCL_LOW_EDGE,
                           SCL_LOW,
                           SCL_HIGH_EDGE,
                           SCL_HIGH,
                           STOP_EDGE,
                           STOP_WAIT);
   signal scl_state      : scl_state_type;
   signal next_scl_state : scl_state_type;

   signal scl_rin          : std_logic;  -- sampled version of scl
   signal scl_d1           : std_logic;  -- sampled version of scl
   signal scl_rin_d1       : std_logic;  -- delayed version of Scl_rin
   signal scl_cout         : std_logic;  -- combinatorial scl output
   signal scl_cout_reg     : std_logic;  -- registered version of scl_cout
   signal scl_rising_edge  : std_logic;  -- falling edge of SCL
   signal scl_falling_edge : std_logic;  -- falling edge of SCL
   signal scl_f_edg_d1     : std_logic;  -- falling edge of SCL delayed one
                                         -- clock
   signal scl_f_edg_d2     : std_logic;  -- falling edge of SCL delayed two
                                         -- clock
   signal scl_f_edg_d3     : std_logic;  -- falling edge of SCL delayed three
                                         -- clock
   signal sda_rin          : std_logic;  -- sampled version of sda
   signal sda_d1           : std_logic;  -- sampled version of sda
   signal sda_rin_d1       : std_logic;  -- delayed version of sda_rin
   signal sda_falling      : std_logic;  -- Pulses when SDA falls
   signal sda_rising       : std_logic;  -- Pulses when SDA rises
   signal sda_changing     : std_logic;  -- Pulses when SDA changes
   signal sda_setup        : std_logic;  -- SDA setup time in progress
   signal sda_setup_cnt    : std_logic_vector (C_SIZE-1 downto 0);
                                         -- SDA setup time count
   signal sda_cout         : std_logic;  -- combinatorial sda output
   signal sda_cout_reg     : std_logic;  -- registered version of sda_cout
   signal sda_cout_reg_d1  : std_logic;  -- delayed sda output for arb
                                         -- comparison
   signal sda_sample       : std_logic;  -- SDA_RIN sampled at SCL rising edge
   signal slave_sda        : std_logic;  -- sda value when slave
   signal master_sda       : std_logic;  -- sda value when master

   signal sda_oe       : std_logic;
   signal master_slave : std_logic;  -- 1 if master, 0 if slave

-- Shift Register and the controls
   signal shift_reg       : std_logic_vector(7 downto 0); -- iic data shift reg
   signal shift_out       : std_logic;
   signal shift_reg_en    : std_logic;
   signal shift_reg_ld    : std_logic;
   signal shift_reg_ld_d1 : std_logic;
   signal i2c_header      : std_logic_vector(7 downto 0);-- I2C header register
   signal i2c_header_en   : std_logic;
   signal i2c_header_ld   : std_logic;
   signal i2c_shiftout    : std_logic;

-- Used to check slave address detected
   signal addr_match : std_logic;

   signal arb_lost   : std_logic;  -- 1 if arbitration is lost
   signal msms_d1    : std_logic;  -- Msms processed to initiate a stop
                                   -- sequence after data has been transmitted
   signal msms_d2    : std_logic;  -- delayed sample of msms_d1
   signal msms_rst_i : std_logic;  -- internal msms_rst

   signal detect_start : std_logic;  -- START condition has been detected
   signal detect_stop  : std_logic;  -- STOP condition has been detected
   signal sm_stop      : std_logic;  -- STOP condition needs to be generated
                                     -- from state machine
   signal bus_busy     : std_logic;  -- indicates that the bus is busy
                                     -- set when START, cleared when STOP
   signal bus_busy_d1  : std_logic;  -- delayed sample of bus busy
   signal gen_start    : std_logic;  -- uP wants to generate a START
   signal gen_stop     : std_logic;  -- uP wants to generate a STOP
   signal rep_start    : std_logic;  -- uP wants to generate a repeated START
   signal stop_scl     : std_logic;  -- signal in SCL state machine
                                     -- indicating a STOP
   signal stop_scl_reg : std_logic;  -- registered version of STOP_SCL

-- Bit counter 0 to 7
   signal bit_cnt      : std_logic_vector(3 downto 0);
   signal bit_cnt_ld   : std_logic;
   signal bit_cnt_clr  : std_logic;
   signal bit_cnt_en   : std_logic;

-- Clock Counter
   signal clk_cnt     : std_logic_vector (C_SIZE-1 downto 0);
   signal clk_cnt_rst : std_logic;
   signal clk_cnt_en  : std_logic;

-- the following signals are only here because Viewlogic's VHDL compiler won't
-- allow a constant to be used in a component instantiation
   signal reg_clr   : std_logic_vector(7 downto 0);
   signal zero_sig  : std_logic;
   signal cnt_zero  : std_logic_vector(C_SIZE-1 downto 0);
   signal cnt_start : std_logic_vector(3 downto 0);

   signal data_i2c_i         : std_logic_vector(7 downto 0);
   signal aas_i              : std_logic;  -- internal addressed as slave
                                           -- signal
   signal srw_i              : std_logic;  -- internal slave read write signal
   signal abgc_i             : std_logic;  -- internal addressed by a general
                                           -- call
   signal dtc_i              : std_logic;  -- internal data transmit compete
                                           -- signal
   signal dtc_i_d1           : std_logic;  -- delayed internal data transmit
                                           -- complete
   signal dtc_i_d2           : std_logic;  -- 2nd register delay of dtc
   signal al_i               : std_logic;  -- internal arbitration lost signal
   signal al_prevent         : std_logic;  -- prevent arbitration lost when
                                           -- last word
   signal rdy_new_xmt_i      : std_logic;  -- internal ready to transmit new
                                           -- data
   signal tx_under_prev_i    : std_logic;  -- TX underflow prevent signal
   signal rsta_tx_under_prev : std_logic;  -- Repeated Start Tx underflow
                                           -- prevent
   signal rsta_d1            : std_logic;  -- Delayed one clock version of Rsta
   signal dtre_d1            : std_logic;  -- Delayed one clock version of Dtre
   signal txer_i             : std_logic;  -- internal Txer signal
   signal txer_edge          : std_logic;  -- Pulse for Txer IRQ

   -- the following signal are used only when 10-bit addressing has been
   -- selected
   signal msb_wr             : std_logic;  -- the 1st byte of 10 bit addressing
                                           -- comp
   signal msb_wr_d           : std_logic;  -- delayed version of msb_wr
   signal msb_wr_d1          : std_logic;  -- delayed version of msb_wr_d
   signal sec_addr           : std_logic := '0';  -- 2nd byte qualifier
   signal sec_adr_match      : std_logic;  -- 2nd byte compare
   signal adr_dta_l          : std_logic := '0';  -- prevents 2nd adr byte load
                                                  -- in DRR
   signal new_rcv_dta_i      : std_logic;  -- internal New_rcv_dta
   signal ro_prev_d1         : std_logic;  -- delayed version of Ro_prev


   signal gen_stop_and_scl_hi : std_logic;  -- signal to prevent SCL state
                              -- machine from getting stuck during a No Ack

   signal setup_cnt_rst      : std_logic;
   signal tx_under_prev_d1   : std_logic;
   signal tx_under_prev_fe   : std_logic;
   signal rsta_re            : std_logic;
   signal gen_stop_d1        : std_logic;
   signal gen_stop_re        : std_logic;
----Mathew
   signal shift_cnt          : std_logic_vector(8 downto 0);
--   signal reg_empty          : std_logic;
----------   
begin

   ----------------------------------------------------------------------------
   -- SCL Tristate driver controls for open-collector emulation
   ----------------------------------------------------------------------------
   Scl_T <= '0' when scl_cout_reg = '0'
                     -- Receive fifo overflow throttle condition
                     or Ro_prev = '1'
                     -- SDA changing requires additional setup to SCL change
                     or (sda_setup = '1' )
                     -- Restart w/ transmit underflow prevention throttle
                     -- condition
                     or rsta_tx_under_prev = '1'  else
            '1';

   Scl_O <= '0';

   ----------------------------------------------------------------------------
   -- SDA Tristate driver controls for open-collector emulation
   ----------------------------------------------------------------------------
   Sda_T <= '0' when ((master_slave = '1' and arb_lost = '0'
                       and sda_cout_reg = '0')
                       or (master_slave = '0' and slave_sda = '0')
                       or stop_scl_reg = '1') else
            '1';

   Sda_O <= '0';


   -- the following signals are only here because Viewlogic's VHDL compiler
   -- won't allow a constant to be used in a component instantiation
   reg_clr   <= CLR_REG;
   zero_sig  <= ZERO;
   cnt_zero  <= ZERO_CNT;
   cnt_start <= START_CNT;

   ----------------------------------------------------------------------------
   -- INT_DTRE_RSTA_DELAY_PROCESS
   ----------------------------------------------------------------------------
   -- This process delays Dtre and RSTA by one clock to edge detect
   -- Dtre = data transmit register empty
   -- Rsta = firmware restart command
   ----------------------------------------------------------------------------
   INT_DTRE_RSTA_DELAY_PROCESS : process (Sys_clk)
   begin
      if (Sys_clk'event and Sys_clk = '1') then
         if Reset = ENABLE_N then
            rsta_d1     <= '0';
            dtre_d1     <= '0';
            ro_prev_d1  <= '0';
            gen_stop_d1 <= '0';
            tx_under_prev_d1 <= '0';
         else
            rsta_d1     <= Rsta;
            dtre_d1     <= Dtre;
            ro_prev_d1  <= Ro_prev;
            gen_stop_d1 <= gen_stop;
            tx_under_prev_d1 <= tx_under_prev_i;
         end if;
      end if;
   end process INT_DTRE_RSTA_DELAY_PROCESS;

   tx_under_prev_fe <= tx_under_prev_d1 and not tx_under_prev_i;
   rsta_re <= Rsta and not rsta_d1 ;
   gen_stop_re <= gen_stop and not gen_stop_d1;

   ----------------------------------------------------------------------------
   -- INT_RSTA_TX_UNDER_PREV_PROCESS
   ----------------------------------------------------------------------------
   -- This process creates a signal that prevent SCL from going high when a
   -- underflow condition would be caused, by a repeated start condition.
   ----------------------------------------------------------------------------
   INT_RSTA_TX_UNDER_PREV_PROCESS : process (Sys_clk)
   begin
      if (Sys_clk'event and Sys_clk = '1') then
         if Reset = ENABLE_N then
            rsta_tx_under_prev <= '0';
         elsif (Rsta = '1' and rsta_d1 = '0' and Dtre = '1' ) then
            rsta_tx_under_prev <= '1';
         elsif (Dtre = '0' and dtre_d1 = '1') then
            rsta_tx_under_prev <= '0';
         else
            rsta_tx_under_prev <= rsta_tx_under_prev;
         end if;
      end if;
   end process INT_RSTA_TX_UNDER_PREV_PROCESS;

   ----------------------------------------------------------------------------
   -- INT_TX_UNDER_PREV_PROCESS
   ----------------------------------------------------------------------------
   -- This process creates a signal that prevent SCL from going high when a
   -- underflow condition would be caused. Transmit underflow can occur in both
   -- master and slave situations
   ----------------------------------------------------------------------------
   INT_TX_UNDER_PREV_PROCESS : process (Sys_clk)
   begin
      if (Sys_clk'event and Sys_clk = '1') then
         if Reset = ENABLE_N then
            tx_under_prev_i <= '0';
         elsif (Dtre = '1' and (state = WAIT_ACK or state = ACK_HEADER)
                and scl_falling_edge = '1' and gen_stop = '0'
                and ((aas_i = '0' and srw_i = '0')
                     or (aas_i = '1' and srw_i = '1'))) then
            tx_under_prev_i <= '1';
         elsif (state = RCV_DATA or state = IDLE or Dtre='0') then
            tx_under_prev_i <= '0';
         end if;
      end if;
   end process INT_TX_UNDER_PREV_PROCESS;

   Tx_under_prev <= tx_under_prev_i;

   ----------------------------------------------------------------------------
   -- SDASETUP
   ----------------------------------------------------------------------------
   -- Whenever SDA changes there is an associated setup time that must be
   -- obeyed before SCL can change. (The exceptions are starts/stops which
   -- haven't other timing specifications.) It doesn't matter whether this is
   -- a Slave | Master, TX | RX. The "setup" counter and the "sdasetup" process
   -- guarantee this time is met regardless of the devices on the bus and their
   -- attempts to manage setup time. The signal sda_setup, when asserted,
   -- causes SCL to be held low until the setup condition is removed. Anytime a
   -- change in SDA is detected on the bus the setup process is invoked. Also,
   -- sda_setup is asserted if the transmit throttle condition is active.
   -- When it deactivates, SDA **may** change on the SDA bus. In this way,
   -- the SCL_STATE machine will be held off as well because it waits for SCL
   -- to actually go high.
   ----------------------------------------------------------------------------
   SETUP_CNT : entity axi_iic_v2_0_9.upcnt_n
      generic map (
         C_SIZE => C_SIZE
         )

      port map(
               Clk    => Sys_clk,
               Clr    => Reset,
               Data   => cnt_zero,
               Cnt_en => sda_setup,
               Load   => sda_changing,
               Qout   => sda_setup_cnt
               );

   ----------------------------------------------------------------------------
   -- SDASETUP Process
   ----------------------------------------------------------------------------
   SDASETUP : process (Sys_clk)
   begin
      if (Sys_clk'event and Sys_clk = '1') then
         if Reset = ENABLE_N then
            sda_setup <= '0';
         elsif (
            -- If SDA is changing on the bus then enforce setup time
            sda_changing = '1'
            -- or if SDA is about to change ...
            or tx_under_prev_i = '1') -- modified
            -- For either of the above cases the controller only cares
            -- about SDA setup when it is legal to change SDA.
            and scl_rin='0' then
            sda_setup <= '1';
         elsif (sda_setup_cnt=Timing_param_tsudat) then
            sda_setup <= '0';
         end if;
      end if;
   end process SDASETUP;

   ----------------------------------------------------------------------------
   -- Arbitration Process
   -- This process checks the master's outgoing SDA with the incoming SDA to
   -- determine if control of the bus has been lost. SDA is checked only when
   -- SCL is high and during the states HEADER and XMIT_DATA (when data is
   -- actively being clocked out of the controller). When arbitration is lost,
   -- a Reset is generated for the Msms bit per the product spec.
   -- Note that when arbitration is lost, the mode is switched to slave.
   -- arb_lost stays set until scl state machine goes to IDLE state
   ----------------------------------------------------------------------------
   ARBITRATION : process (Sys_clk)
   begin
      if (Sys_clk'event and Sys_clk = '1') then
         if Reset = ENABLE_N then
            arb_lost   <= '0';
            msms_rst_i <= '0';
         elsif scl_state = SCL_IDLE or scl_state = STOP_WAIT then
            arb_lost   <= '0';
            msms_rst_i <= '0';
         elsif (master_slave = '1') then
            -- Actively generating SCL clock as the master and (possibly)
            -- participating in multi-master arbitration.
            if (scl_rising_edge='1'
                and (state = HEADER or state = XMIT_DATA)) then
               if (sda_cout_reg='1' and sda_rin = '0') then
                  -- Other master drove SDA to 0 but the controller is trying
                  -- to drive a 1. That is the exact case for loss of
                  -- arbitration
                  arb_lost   <= '1';
                  msms_rst_i <= '1';
               else
                  arb_lost   <= '0';
                  msms_rst_i <= '0';
               end if;
            else
               msms_rst_i <= '0';
            end if;

         end if;
      end if;
   end process ARBITRATION;

   Msms_rst <= msms_rst_i
               -- The spec states that the Msms bit should be cleared when an
               -- address is not-acknowledged. The sm_stop indicates that
               -- a not-acknowledge occured on either a data or address
               -- (header) transfer. This fixes CR439859.
               or sm_stop;

   ----------------------------------------------------------------------------
   -- SCL_GENERATOR_COMB Process
   -- This process generates SCL and SDA when in Master mode. It generates the
   -- START and STOP conditions. If arbitration is lost, SCL will not be
   -- generated until the end of the byte transfer.
   ----------------------------------------------------------------------------
   SCL_GENERATOR_COMB : process (
                                 scl_state,
                                 arb_lost,
                                 sm_stop,
                                 gen_stop,
                                 rep_start,
                                 bus_busy,
                                 gen_start,
                                 master_slave,
                                 stop_scl_reg,
                                 clk_cnt,
                                 scl_rin,
                                 sda_rin,
                                 state,
                                 sda_cout_reg,
                                 master_sda,
                                 Timing_param_tsusta,
                                 Timing_param_tsusto,
                                 Timing_param_thdsta,
                                 Timing_param_thddat,
                                 Timing_param_tbuf,
                                 Timing_param_tlow,
                                 Timing_param_thigh
                                 )
   begin
      -- state machine defaults
      scl_cout       <= '1';
      sda_cout       <= sda_cout_reg;
      stop_scl       <= stop_scl_reg;
      clk_cnt_en     <= '0';
      clk_cnt_rst    <= '1';
      next_scl_state <= scl_state;
      Rsta_rst       <= (ENABLE_N);

      case scl_state is

         when SCL_IDLE =>
            sda_cout <= '1';
            stop_scl <= '0';
            -- leave IDLE state when master, bus is idle, and gen_start
            if master_slave = '1' and bus_busy = '0' and gen_start = '1' then
               next_scl_state <= START;
            else
               next_scl_state <= SCL_IDLE;
            end if;

         when START =>
            -- generate start condition
            clk_cnt_en  <= '0';
            clk_cnt_rst <= '1';
            sda_cout    <= '0';
            stop_scl    <= '0';
            if sda_rin='0' then
               next_scl_state <= START_EDGE;
            else
               next_scl_state <= START;
            end if;

         when START_EDGE =>
            -- This state ensures that the hold time for the (repeated) start
            -- condition is met. The hold time is measured from the Vih level
            -- of SDA so it is critical for SDA to be sampled low prior to
            -- starting the hold time counter.
            clk_cnt_en  <= '1';
            clk_cnt_rst <= '0';
            -- generate Reset for repeat start bit if repeat start condition
            if rep_start = '1' then
               Rsta_rst <= not(ENABLE_N);
            end if;

            if clk_cnt = Timing_param_thdsta then
               next_scl_state <= SCL_LOW_EDGE;
            else
               next_scl_state <= START_EDGE;
            end if;

         when SCL_LOW_EDGE =>
            clk_cnt_rst    <= '1';
            scl_cout       <= '0';
            stop_scl       <= '0';
            if (scl_rin='0') then
               clk_cnt_en  <= '1';
               clk_cnt_rst <= '0';
            end if;
            if ((scl_rin = '0') and (clk_cnt = Timing_param_thddat)) then
               -- SCL sampled to be 0 so everything on the bus can see that it
               -- is low too. The very large propagation delays caused by
               -- potentially large (~300ns or more) fall time should not be
               -- ignored by the controller.It must VERIFY that the bus is low.
               next_scl_state <= SCL_LOW;
               clk_cnt_en  <= '0';
               clk_cnt_rst <= '1';
            else
               next_scl_state <= SCL_LOW_EDGE;
            end if;

         when SCL_LOW =>
            clk_cnt_en <= '1';
            clk_cnt_rst <= '0';
            scl_cout    <= '0';
            stop_scl <= '0';

            -- SDA (the data) can only be changed when SCL is low. Note that
            -- STOPS and RESTARTS could appear  after the SCL low period
            -- has expired because the controller is throttled.
            if (sm_stop = '1' or gen_stop = '1')
               and state /= ACK_DATA
               and state /= ACK_HEADER
               and state /= WAIT_ACK then
               stop_scl <= '1';
               -- Pull SDA low in anticipation of raising it to generate the
               -- STOP edge
               sda_cout <= '0';
            elsif rep_start = '1' then
               -- Release SDA in anticipation of dropping it to generate the
               -- START edge
               sda_cout <= '1';
            else
               sda_cout <= master_sda;
            end if;

            -- Wait until minimum low clock period requirement is met then
            -- proceed to release the SCL_COUT so that it is "possible" for the
            -- scl clock to go high on the bus. Note that a SLAVE device can
            -- continue to hold SCL low to throttle the bus OR the master
            -- itself may hold SCL low because of an internal throttle
            -- condition.
            if clk_cnt = Timing_param_tlow then
               next_scl_state <= SCL_HIGH_EDGE;
            else
               next_scl_state <= SCL_LOW;
            end if;

         when SCL_HIGH_EDGE =>
            clk_cnt_rst <= '1';
            stop_scl <= '0';
            -- SCL low time met. Try to release SCL to make it go high.
            scl_cout    <= '1';

            -- SDA (the data) can only be changed when SCL is low. In this
            -- state the fsm wants to change SCL to high and is waiting to see
            -- it go high. However, other processes may be inhibiting SCL from
            -- going high because the controller is throttled. While throttled,
            -- and scl is still low:
            -- (1) a STOP may be requested by the firmware, **OR**
            -- (2) a RESTART may be requested (with or without data available)
            --     by the firmware, **OR**
            -- (3) new data may get loaded into the TX_FIFO and the first bit
            --     is available to be loaded onto the SDA pin

            -- Removed this condition as sda_cout should not go low when
            -- SCL goes high. SDA should be changed in SCL_LOW state.
            if (sm_stop = '1' or gen_stop = '1')
               and state /= ACK_DATA
               and state /= ACK_HEADER
               and state /= WAIT_ACK then
               stop_scl <= '1';
            --   -- Pull SDA low in anticipation of raising it to generate the
            --   -- STOP edge
               sda_cout <= '0';
            elsif rep_start = '1' then
            --if stop_scl_reg = '1' then
            --   stop_scl <= '1';
            --   sda_cout <= '0';
            --elsif rep_start = '1' then
               -- Release SDA in anticipation of dropping it to generate the
               -- START edge
               sda_cout <= '1';
            else
               sda_cout <= master_sda;
            end if;

            -- Nothing in the controller should
            --  a) sample SDA_RIN until the controller actually verifies that
            --  SCL has gone high, and
            --  b) change SDA_COUT given that it is trying to change SCL now.
            -- Note that other processes may inhibit SCL from going high to
            -- wait for the transmit data register to be filled with data. In
            -- that case data setup requirements imposed by the I2C spec must
            -- be satisfied. Regardless, the SCL clock generator can wait here
            -- in SCL_HIGH_EDGE until that is accomplished.
            if (scl_rin='1') then
               next_scl_state <= SCL_HIGH;
            else
               next_scl_state <= SCL_HIGH_EDGE;
            end if;

         when SCL_HIGH =>
            -- SCL is now high (released) on the external bus. At this point
            -- the state machine doesn't have to worry about any throttle
            -- conditions -- by definition they are removed as SCL is no longer
            -- low. The firmware **must** signal the desire to STOP or Repeat
            -- Start when throttled.

            -- It is decision time. Should another SCL clock pulse get
            -- generated? (IE a low period + high period?) The answer depends
            -- on whether the previous clock was a DATA XFER clock or an ACK
            -- CLOCK. Should a Repeated Start be generated? Should a STOP be
            -- generated?

            clk_cnt_en  <= '1';
            clk_cnt_rst <= '0';
            scl_cout    <= '1';
            if (arb_lost='1') then
               -- No point in continuing! The other master will generate the
               -- clock.
               next_scl_state <= SCL_IDLE;
            else
               -- Determine HIGH time based on need to generate a repeated
               -- start, a stop or the full high period of the SCL clock.
               -- (Without some analysis it isn't clear if rep_start and
               -- stop_scl_reg are mutually exclusive. Hence the priority
               -- encoder.)
               if rep_start = '1' then
                  if (clk_cnt=Timing_param_tsusta) then
                    -- The hidden assumption here is that SDA has been released
                    -- by the slave|master receiver after the ACK clock so that
                    -- a repeated start is possible
                     next_scl_state <= START;
                     clk_cnt_en     <= '0';
                     clk_cnt_rst    <= '1';
                  end if;
               elsif stop_scl_reg = '1' then
                  if (clk_cnt=Timing_param_tsusto) then
                     -- The hidden assumption here is that SDA has been pulled
                     -- low by the master after the ACK clock so that a
                     -- stop is possible
                     next_scl_state <= STOP_EDGE;
                     clk_cnt_rst    <= '1';
                     clk_cnt_en     <= '0';
                     sda_cout       <= '1';  -- issue the stop
                     stop_scl       <= '0';
                  end if;
               else
                  -- Neither repeated start nor stop requested
                  if clk_cnt= Timing_param_thigh then
                     next_scl_state <= SCL_LOW_EDGE;
                     clk_cnt_rst    <= '1';
                     clk_cnt_en     <= '0';
                  end if;
               end if;
            end if;

         when STOP_EDGE =>
            if (sda_rin='1') then
               next_scl_state <= STOP_WAIT;
            else
               next_scl_state <= STOP_EDGE;
            end if;

         when STOP_WAIT =>
            -- The Stop setup time was satisfied and SDA was sampled high
            -- indicating the stop occured. Now wait the TBUF time required
            -- between a stop and the next start.
            clk_cnt_en  <= '1';
            clk_cnt_rst <= '0';
            stop_scl    <= '0';
            if clk_cnt = Timing_param_tbuf then
               next_scl_state <= SCL_IDLE;
            else
               next_scl_state <= STOP_WAIT;
            end if;

       -- coverage off
         when others  =>
            next_scl_state <= SCL_IDLE;
       -- coverage on

      end case;

   end process SCL_GENERATOR_COMB;

   ----------------------------------------------------------------------------
   --PROCESS : SCL_GENERATOR_REGS
   ----------------------------------------------------------------------------
   SCL_GENERATOR_REGS : process (Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            scl_state    <= SCL_IDLE;
            sda_cout_reg <= '1';
            scl_cout_reg <= '1';
            stop_scl_reg <= '0';
        else
           scl_state    <= next_scl_state;
           sda_cout_reg <= sda_cout;
           -- Ro_prev = receive overflow prevent = case where controller must
           -- hold SCL low itself until receive fifo is emptied by the firmware
           scl_cout_reg <= scl_cout and not Ro_prev;
           stop_scl_reg <= stop_scl;
        end if;
      end if;
   end process SCL_GENERATOR_REGS;

   ----------------------------------------------------------------------------
   -- Clock Counter Implementation
   -- The following code implements the counter that divides the sys_clock for
   -- creation of SCL. Control lines for this counter are set in SCL state
   -- machine
   ----------------------------------------------------------------------------
   CLKCNT : entity axi_iic_v2_0_9.upcnt_n
      generic map (
         C_SIZE => C_SIZE
         )

      port map(
                Clk    => Sys_clk,
                Clr    => Reset,
                Data    => cnt_zero,
                Cnt_en => clk_cnt_en,
                Load   => clk_cnt_rst,
                Qout   => clk_cnt
                );

   ----------------------------------------------------------------------------
   -- Input Registers Process
   -- This process samples the incoming SDA and SCL with the system clock
   ----------------------------------------------------------------------------
  
   sda_rin <= Sda_I;
   scl_rin <= Scl_I;

   INPUT_REGS : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then

          sda_rin_d1 <= sda_rin;  -- delay sda_rin to find edges

          scl_rin_d1 <= scl_rin;  -- delay Scl_rin to find edges

          sda_cout_reg_d1 <= sda_cout_reg;
      end if;
   end process INPUT_REGS;


   ----------------------------------------------------------------------------
   -- Master Slave Mode Select Process
   -- This process allows software to write the value of Msms with each data
   -- word to be transmitted.  So writing a '0' to Msms will initiate a stop
   -- sequence on the I2C bus after the that byte in the DTR has been sent.
   ----------------------------------------------------------------------------
   MSMS_PROCESS : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            msms_d1 <= '0';
            msms_d2 <= '0';
         else
            msms_d1 <= (Msms and not msms_rst_i)
                       or ((msms_d1 and not (dtc_i_d1 and not dtc_i_d2) and
                           not msms_rst_i)
                           and not Msms_set and not txer_i) ;
            msms_d2 <= msms_d1;
         end if;
      end if;
   end process MSMS_PROCESS;

   ----------------------------------------------------------------------------
   -- START/STOP Detect Process
   -- This process detects the start condition by finding the falling edge of
   -- sda_rin and checking that SCL is high. It detects the stop condition on
   -- the bus by finding a rising edge of SDA when SCL is high.
   ----------------------------------------------------------------------------
   sda_falling <= sda_rin_d1 and not sda_rin;
   sda_rising <= not sda_rin_d1 and sda_rin;
   sda_changing <= sda_falling or sda_rising or tx_under_prev_fe
                               or rsta_re    or gen_stop_re;

   ----------------------------------------------------------------------------
   -- START Detect Process
   ----------------------------------------------------------------------------

   START_DET_PROCESS : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N or state = HEADER then
            detect_start <= '0';
         elsif sda_falling = '1' then
            if scl_rin = '1' then
               detect_start <= '1';
            else
               detect_start <= '0';
            end if;
         end if;
      end if;
   end process START_DET_PROCESS;

   ----------------------------------------------------------------------------
   -- STOP Detect Process
   ----------------------------------------------------------------------------

   STOP_DET_PROCESS : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N or detect_start = '1' then
            detect_stop <= '0';
         elsif sda_rising = '1' then
            if scl_rin = '1' then
               detect_stop <= '1';
            else
               detect_stop <= '0';
            end if;
         elsif msms_d2 = '0' and msms_d1 = '1' then
            -- rising edge of Msms - generate start condition
            detect_stop <= '0';  -- clear on a generate start condition
         end if;
      end if;
   end process STOP_DET_PROCESS;

   ----------------------------------------------------------------------------
   -- Bus Busy Process
   -- This process sets bus_busy as soon as START is detected which would
   -- always set arb lost (Al).
   ----------------------------------------------------------------------------

   SET_BUS_BUSY_PROCESS : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            bus_busy    <= '0';
         else
            if detect_stop = '1' then
               bus_busy <= '0';
            elsif detect_start = '1' then
               bus_busy <= '1';
            end if;
         end if;
      end if;
   end process SET_BUS_BUSY_PROCESS;

   ----------------------------------------------------------------------------
   -- BUS_BUSY_REG_PROCESS:
   -- This process describes a delayed version of the bus busy bit which is
   -- used to determine arb lost (Al).
   ----------------------------------------------------------------------------

   BUS_BUSY_REG_PROCESS : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            bus_busy_d1 <= '0';
         else
            bus_busy_d1 <= bus_busy;
         end if;
      end if;
   end process BUS_BUSY_REG_PROCESS;

   ----------------------------------------------------------------------------
   -- GEN_START_PROCESS
   -- This process detects the rising and falling edges of Msms and sets
   -- signals to control generation of start condition
   ----------------------------------------------------------------------------

   GEN_START_PROCESS : process (Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
             gen_start    <= '0';
         else
             if msms_d2 = '0' and msms_d1 = '1' then
                -- rising edge of Msms - generate start condition
                gen_start <= '1';
             elsif detect_start = '1' then
                gen_start <= '0';
             end if;
          end if;
       end if;
   end process GEN_START_PROCESS;

   ----------------------------------------------------------------------------
   -- GEN_STOP_PROCESS
   -- This process detects the rising and falling edges of Msms and sets
   -- signals to control generation of stop condition
   ----------------------------------------------------------------------------

   GEN_STOP_PROCESS : process (Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
             gen_stop     <= '0';
         else
             if arb_lost = '0' and msms_d2 = '1' and msms_d1 = '0' then
                -- falling edge of Msms - generate stop condition only
                -- if arbitration has not been lost
                gen_stop <= '1';
             elsif detect_stop = '1' then
                gen_stop <= '0';
             end if;
          end if;
       end if;
   end process GEN_STOP_PROCESS;

   ----------------------------------------------------------------------------
   -- GEN_MASTRE_SLAVE_PROCESS
   -- This process sets the master slave bit based on Msms if and only if
   -- it is not in the middle of a cycle, i.e. bus_busy = '0'
   ----------------------------------------------------------------------------

   GEN_MASTRE_SLAVE_PROCESS : process (Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
             master_slave <= '0';
         else
             if bus_busy = '0' then
                master_slave <= msms_d1;
             elsif arb_lost = '1' then
                master_slave <= '0';
             else
                master_slave <= master_slave;
             end if;
          end if;
       end if;
   end process GEN_MASTRE_SLAVE_PROCESS;

   rep_start <= Rsta;         -- repeat start signal is Rsta control bit

   ----------------------------------------------------------------------------
   -- GEN_STOP_AND_SCL_HIGH
   ----------------------------------------------------------------------------
   -- This process does not go high until both gen_stop and SCL have gone high
   -- This is used to prevent the SCL state machine from getting stuck when a
   -- slave no acks during the last data byte being transmitted
   ----------------------------------------------------------------------------
   GEN_STOP_AND_SCL_HIGH : process (Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            gen_stop_and_scl_hi <= '0';
         elsif gen_stop = '0' then
            gen_stop_and_scl_hi <= '0';  --clear
         elsif gen_stop = '1' and scl_rin = '1' then
            gen_stop_and_scl_hi <= '1';
         else
            gen_stop_and_scl_hi <= gen_stop_and_scl_hi;  --hold condition
         end if;
      end if;
   end process GEN_STOP_AND_SCL_HIGH;

   ----------------------------------------------------------------------------
   -- SCL_EDGE_PROCESS
   ----------------------------------------------------------------------------
   -- This process generates a 1 Sys_clk wide pulse for both the rising edge
   -- and the falling edge of SCL_RIN
   ----------------------------------------------------------------------------
   SCL_EDGE_PROCESS : process (Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            scl_falling_edge <= '0';
            scl_rising_edge  <= '0';
            scl_f_edg_d1     <= '0';
            scl_f_edg_d2     <= '0';
            scl_f_edg_d3     <= '0';
         else
            scl_falling_edge <= scl_rin_d1 and (not scl_rin);  -- 1 to 0
            scl_rising_edge  <= (not scl_rin_d1) and scl_rin;  -- 0 to 1
            scl_f_edg_d1     <= scl_falling_edge;
            scl_f_edg_d2     <= scl_f_edg_d1;
            scl_f_edg_d3     <= scl_f_edg_d2;
         end if;
      end if;
   end process SCL_EDGE_PROCESS;

   ----------------------------------------------------------------------------
   -- EARLY_ACK_HDR_PROCESS
   ----------------------------------------------------------------------------
   -- This process generates 1 Sys_clk wide pulses when the statemachine enters
   -- the ACK_HEADER state
   ----------------------------------------------------------------------------
   EARLY_ACK_HDR_PROCESS : process (Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            EarlyAckHdr       <= '0';
         elsif (scl_f_edg_d3 = '1' and state = ACK_HEADER) then
            EarlyAckHdr <= '1';
         else
            EarlyAckHdr <= '0';
         end if;
      end if;
   end process EARLY_ACK_HDR_PROCESS;

   ----------------------------------------------------------------------------
   -- ACK_DATA_PROCESS
   ----------------------------------------------------------------------------
   -- This process generates 1 Sys_clk wide pulses when the statemachine enters
   -- ACK_DATA state
   ----------------------------------------------------------------------------
   ACK_DATA_PROCESS : process (Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            AckDataState <= '0';
         elsif (state = ACK_DATA) then
            AckDataState <= '1';
         else
            AckDataState <= '0';
         end if;
      end if;
   end process ACK_DATA_PROCESS;

   ----------------------------------------------------------------------------
   -- EARLY_ACK_DATA_PROCESS
   ----------------------------------------------------------------------------
   -- This process generates 1 Sys_clk wide pulses when the statemachine enters
   -- the ACK_DATA ot RCV_DATA state state
   ----------------------------------------------------------------------------
   EARLY_ACK_DATA_PROCESS : process (Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            EarlyAckDataState      <= '0';
         elsif (state = ACK_DATA or (state = RCV_DATA and
            (bit_cnt = CNT_ALMOST_DONE or bit_cnt = CNT_DONE))) then
            EarlyAckDataState <= '1';
         else
            EarlyAckDataState <= '0';
         end if;
      end if;
   end process EARLY_ACK_DATA_PROCESS;

   ----------------------------------------------------------------------------
   -- uP Status Register Bits Processes
   -- Dtc - data transfer complete. Since this only checks whether the
   -- bit_cnt="0111" it will be true for both data and address transfers.
   -- While one byte of data is being transferred, this bit is cleared.
   -- It is set by the falling edge of the 9th clock of a byte transfer and
   -- is not cleared at Reset
   ----------------------------------------------------------------------------
   DTC_I_BIT : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            dtc_i <= '0';
         elsif scl_falling_edge = '1' then
            if bit_cnt = "0111" then
               dtc_i <= '1';
            else
               dtc_i <= '0';
            end if;
         end if;
      end if;
   end process DTC_I_BIT;

   Dtc <= dtc_i;

   ----------------------------------------------------------------------------
   -- DTC_DELAY_PROCESS
   ----------------------------------------------------------------------------
   DTC_DELAY_PROCESS : process (Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            dtc_i_d1 <= '0';
            dtc_i_d2 <= '0';
         else
            dtc_i_d1 <= dtc_i;
            dtc_i_d2 <= dtc_i_d1;
         end if;
      end if;
   end process DTC_DELAY_PROCESS;

   ----------------------------------------------------------------------------
   -- aas_i - Addressed As Slave Bit
   ----------------------------------------------------------------------------
   -- When its own specific address (adr) matches the I2C Address, this bit is
   -- set.
   -- Then the CPU needs to check the Srw bit and this bit when a
   -- TX-RX mode accordingly.
   ----------------------------------------------------------------------------
   AAS_I_BIT : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            aas_i <= '0';
         elsif detect_stop = '1' or addr_match = '0' then
            aas_i <= '0';
         elsif state = ACK_HEADER then
            aas_i <= addr_match;
            -- the signal address match compares adr with I2_ADDR
         else
            aas_i <= aas_i;
         end if;
      end if;
   end process AAS_I_BIT;

   ----------------------------------------------------------------------------
   -- INT_AAS_PROCESS
   ----------------------------------------------------------------------------
   -- This process assigns the internal aas_i signal to the output port Aas
   ----------------------------------------------------------------------------
   INT_AAS_PROCESS : process (aas_i, sec_adr_match)
   begin  -- process
      Aas <= aas_i and sec_adr_match;
   end process INT_AAS_PROCESS;

   ----------------------------------------------------------------------------
   -- Bb - Bus Busy Bit
   ----------------------------------------------------------------------------
   -- This bit indicates the status of the bus. This bit is set when a START
   -- signal is detected and cleared when a stop signal is detected. It is
   -- also cleared on Reset. This bit is identical to the signal bus_busy set
   -- in the process set_bus_busy.
   ----------------------------------------------------------------------------
      Bb <= bus_busy;

   ----------------------------------------------------------------------------
   -- Al - Arbitration Lost Bit
   ----------------------------------------------------------------------------
   -- This bit is set when the arbitration procedure is lost.
   -- Arbitration is lost when:
   --    1. SDA is sampled low when the master drives high during addr or data
   --       transmit cycle
   --    2. SDA is sampled low when the master drives high during the
   --       acknowledge  bit of a data receive cycle
   --    3. A start cycle is attempted when the bus is busy
   --    4. A repeated start is requested in slave mode
   --    5. A stop condition is detected that the master did not request it.
   -- This bit is cleared upon Reset and when the software writes a '0' to it
   -- Conditions 1 & 2 above simply result in sda_rin not matching sda_cout
   -- while SCL is high. This design will not generate a START condition while
   -- the bus is busy. When a START is detected, this hardware will set the bus
   -- busy bit and gen_start stays set until detect_start asserts, therefore
   -- will have to compare with a delayed version of bus_busy. Condition 3 is
   -- really just a check on the uP software control registers as is condition
   -- 4. Condition 5 is also taken care of by the fact that sda_rin does not
   -- equal sda_cout, however, this process also tests for if a stop condition
   -- has been detected when this master did not generate it
   ----------------------------------------------------------------------------
   AL_I_BIT : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            al_i <= '0';
         elsif master_slave = '1' then
            if (arb_lost = '1') or
               (bus_busy_d1 = '1' and gen_start = '1') or
               (detect_stop = '1' and al_prevent = '0' and sm_stop = '0') then
               al_i <= '1';
            else
               al_i <= '0';   -- generate a pulse on al_i, arb lost interrupt
            end if;
         elsif Rsta = '1' then
            -- repeated start requested while slave
            al_i <= '1';
         else
            al_i <= '0';
         end if;
      end if;
   end process AL_I_BIT;

   ----------------------------------------------------------------------------
   -- INT_ARB_LOST_PROCESS
   ----------------------------------------------------------------------------
   -- This process assigns the internal al_i signal to the output port Al
   ----------------------------------------------------------------------------
   INT_ARB_LOST_PROCESS : process (al_i)
   begin  -- process
      Al <= al_i;
   end process INT_ARB_LOST_PROCESS;

   ----------------------------------------------------------------------------
   -- PREVENT_ARB_LOST_PROCESS
   ----------------------------------------------------------------------------
   -- This process prevents arb lost (al_i) when a stop has been initiated by
   -- this device operating as a master.
   ----------------------------------------------------------------------------
   PREVENT_ARB_LOST_PROCESS : process (Sys_clk)
   begin  -- make an SR flip flop that sets on gen_stop and resets on
          -- detect_start
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            al_prevent <= '0';
         elsif (gen_stop = '1' and detect_start = '0')
            or (sm_stop = '1' and detect_start = '0')then
            al_prevent <= '1';
         elsif detect_start = '1' then
            al_prevent <= '0';
         else
            al_prevent <= al_prevent;
         end if;
      end if;
   end process PREVENT_ARB_LOST_PROCESS;

   ----------------------------------------------------------------------------
   -- srw_i - Slave Read/Write Bit
   ----------------------------------------------------------------------------
   -- When aas_i is set, srw_i indicates the value of the R/W command bit of
   -- the calling address sent from the master. This bit is only valid when a
   -- complete transfer has occurred and no other  transfers have been
   -- initiated. The CPU uses this bit to set the slave transmit/receive mode.
   -- This bit is Reset by Reset
   ----------------------------------------------------------------------------
   SRW_I_BIT : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            srw_i <= '0';
         elsif state = ACK_HEADER then
            srw_i <= i2c_header(0);
         else
            srw_i <= srw_i;
         end if;
      end if;
   end process SRW_I_BIT;

   Srw <= srw_i;

   ----------------------------------------------------------------------------
   -- TXER_BIT process
   ----------------------------------------------------------------------------
   -- This process determines the state of the acknowledge bit which may be
   -- used as a transmit error or by a master receiver to indicate to the
   -- slave that the last byte has been transmitted
   ----------------------------------------------------------------------------
   TXER_BIT : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            txer_i <= '0';
         elsif scl_falling_edge = '1' then
            if state = ACK_HEADER or state = ACK_DATA or state = WAIT_ACK then
               txer_i <= sda_sample;
            end if;
         end if;
      end if;
   end process TXER_BIT;

   ----------------------------------------------------------------------------
   -- TXER_EDGE process
   ----------------------------------------------------------------------------
   -- This process creates a one wide clock pulse for Txer IRQ
   ----------------------------------------------------------------------------
   TXER_EDGE_PROCESS : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            txer_edge <= '0';
         elsif scl_falling_edge = '1' then
            if state = ACK_HEADER or state = ACK_DATA or state = WAIT_ACK then
               txer_edge <= sda_sample;
            end if;
         elsif scl_f_edg_d2 = '1' then
            txer_edge <= '0';
         end if;
      end if;
   end process TXER_EDGE_PROCESS;

   Txer <= txer_edge;

   ----------------------------------------------------------------------------
   -- uP Data Register
   -- Register for uP interface data_i2c_i
   ----------------------------------------------------------------------------
   DATA_I2C_I_PROC : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            data_i2c_i    <= (others => '0');
            new_rcv_dta_i <= '0';
         elsif (state = ACK_DATA) and Ro_prev = '0' and scl_falling_edge = '1'
                and adr_dta_l = '0'         then
            data_i2c_i    <= shift_reg;
            new_rcv_dta_i <= '1';
         else
            data_i2c_i    <= data_i2c_i;
            new_rcv_dta_i <= '0';
         end if;
      end if;
   end process DATA_I2C_I_PROC;

   ----------------------------------------------------------------------------
   -- INT_NEW_RCV_DATA_PROCESS
   ----------------------------------------------------------------------------
   -- This process assigns the internal receive data signals to the output port
   ----------------------------------------------------------------------------
   INT_NEW_RCV_DATA_PROCESS : process (new_rcv_dta_i)
   begin  -- process
      New_rcv_dta <= new_rcv_dta_i;
   end process INT_NEW_RCV_DATA_PROCESS;

   Data_i2c <= data_i2c_i;

   ----------------------------------------------------------------------------
   --  Determine if Addressed As Slave or by General Call
   ----------------------------------------------------------------------------
   -- This process determines when the I2C has been addressed as a slave
   -- that is the I2C header matches the slave address stored in ADR or a
   -- general call has happened
   ----------------------------------------------------------------------------
   NO_TEN_BIT_GEN : if C_TEN_BIT_ADR = 0 generate

      addr_match <= '1' when (i2c_header(7 downto 1) = Adr(7 downto 1))
                    or (abgc_i = '1')
                    else '0';

      -- Seven bit addressing, sec_adr_match is always true.
      sec_adr_match <= '1';

   end generate NO_TEN_BIT_GEN;


   TEN_BIT_GEN : if (C_TEN_BIT_ADR = 1) generate
      -------------------------------------------------------------------------
      -- The msb_wr signal indicates that the just received i2c_header matches
      -- the required first byte of a 2-byte, 10-bit address. Since the
      -- i2c_header shift register clocks on the scl rising edge but the timing
      -- of signals dependent on msb_wr expect it to change on the falling edge
      -- the scl_f_edge_d1 qualifier is used to create the expected timing.
      -------------------------------------------------------------------------
      MSB_WR_PROCESS : process (Sys_clk)
      begin
         if Sys_clk'event and Sys_clk = '1' then
            if Reset = ENABLE_N then
               msb_wr <= '0';
            elsif (abgc_i = '1') or
               (scl_f_edg_d1 = '1'
                and i2c_header(7 downto 3) = "11110"
                and (i2c_header(2 downto 1) = Ten_adr(7 downto 6)))
            then
               msb_wr <= '1';
            elsif (scl_f_edg_d1='1') then
               msb_wr <= '0';
            end if;
         end if;
      end process MSB_WR_PROCESS;

      -------------------------------------------------------------------------
      -- MSB_WR_D_PROCESS
      -------------------------------------------------------------------------
      -- msb_wr delay process
      -------------------------------------------------------------------------
      MSB_WR_D_PROCESS : process (Sys_clk)
      begin
         if Sys_clk'event and Sys_clk = '1' then
            if Reset = ENABLE_N then
               msb_wr_d  <= '0';
               msb_wr_d1 <= '0';
            else
               msb_wr_d  <= msb_wr;
               msb_wr_d1 <= msb_wr_d;  -- delayed to align with srw_i
            end if;
         end if;
      end process MSB_WR_D_PROCESS;

      -------------------------------------------------------------------------
      -- SRFF set on leading edge of MSB_WR, Reset on DTC and SCL falling edge
      -- this will qualify the 2nd byte as address and prevent it from being
      -- loaded into the DRR or Rc FIFO
      -------------------------------------------------------------------------
      SECOND_ADDR_PROCESS : process (Sys_clk)
      begin
         if Sys_clk'event and Sys_clk = '1' then
            if Reset = ENABLE_N then
               sec_addr <= '0';
            elsif (msb_wr = '1' and msb_wr_d = '0'
                   and i2c_header(0) = '0') then
               -- First byte of two byte (10-bit addr) matched and
               -- direction=write. Set sec_addr flag to indicate next byte
               -- should be checked against remainder of the address.
               sec_addr <= '1';
            elsif dtc_i = '1' and Ro_prev = '0' and scl_f_edg_d1 = '1'
            then
               sec_addr <= '0';
            else
               sec_addr <= sec_addr;
            end if;
         end if;
      end process SECOND_ADDR_PROCESS;

      -------------------------------------------------------------------------
      -- Compare 2nd byte to see if it matches slave address
      -- A repeated start with the Master writing to the slave must also
      -- compare the second address byte.
      -- A repeated start with the Master reading from the slave only compares
      -- the first (most significant).
      -------------------------------------------------------------------------
      SECOND_ADDR_COMP_PROCESS : process (Sys_clk)
      begin
         if Sys_clk'event and Sys_clk = '1' then
            if Reset = ENABLE_N then
               sec_adr_match <= '0';
            elsif detect_stop = '1'
               -- Repeated Start and Master Writing to Slave
               or (state = ACK_HEADER and i2c_header(0) = '0'
               and master_slave = '0' and msb_wr_d = '1' and abgc_i = '0') then
               sec_adr_match <= '0';

            elsif (abgc_i = '1')
               or (sec_addr = '1' and (shift_reg(7) = Ten_adr(5)
                                  and shift_reg(6 downto 0) = Adr (7 downto 1)
                                  and dtc_i = '1' and msb_wr_d1 = '1')) then
               sec_adr_match <= '1';
            else
               sec_adr_match <= sec_adr_match;
            end if;
         end if;
      end process SECOND_ADDR_COMP_PROCESS;

      -------------------------------------------------------------------------
      -- Prevents 2nd byte of 10 bit address from being loaded into DRR.
      -- When in ACK_HEADER and srw_i is lo then a repeated start or start
      -- condition occured and data is being written to slave so the next
      -- byte will be the remaining portion of the 10 bit address
      -------------------------------------------------------------------------
      ADR_DTA_L_PROCESS : process (Sys_clk)
      begin
         if Sys_clk'event and Sys_clk = '1' then
            if Reset = ENABLE_N then
               adr_dta_l <= '0';
            elsif ((i2c_header(0) = '0' and
                    msb_wr = '1' and
                    msb_wr_d = '0') and
                   sec_adr_match = '0') or
                  (state = ACK_HEADER and srw_i = '0' and
                   master_slave = '0' and
                   msb_wr_d1 = '1') then
               adr_dta_l <= '1';
            elsif (state = ACK_HEADER and
                   master_slave = '1' and
                   msb_wr_d1 = '0') then
               adr_dta_l <= '0';
            elsif (state = ACK_DATA and Ro_prev = '0'
                                    and scl_falling_edge = '1')
               or (detect_start = '1') or (abgc_i = '1')
           --  or (state = ACK_HEADER and srw_i = '1' and master_slave = '0')
            then
               adr_dta_l <= '0';
            else
               adr_dta_l <= adr_dta_l;
            end if;
         end if;
      end process ADR_DTA_L_PROCESS;

      -- Set address match high to get 2nd byte of slave address
      addr_match <= '1' when (msb_wr = '1' and sec_adr_match = '1')
                     or (sec_addr = '1')
                     else '0';

   end generate TEN_BIT_GEN;

   ----------------------------------------------------------------------------
   -- Process : SDA_SMPL
   -- Address by general call process
   ----------------------------------------------------------------------------
   ABGC_PROCESS : process (Sys_clk)
   begin
      if (Sys_clk'event and Sys_clk = '1') then
         if Reset = ENABLE_N then
            abgc_i <= '0';
         elsif detect_stop = '1' or detect_start = '1' then
            abgc_i <= '0';
         elsif i2c_header(7 downto 0) = "00000000" and Gc_en = '1'
            and (state = ACK_HEADER) then
            abgc_i <= '1';
         end if;
      end if;
   end process ABGC_PROCESS;

   Abgc <= abgc_i;

   ----------------------------------------------------------------------------
   -- Process : SDA_SMPL
   -- Sample the SDA_RIN for use in checking the acknowledge bit received by
   -- the controller
   ----------------------------------------------------------------------------
   SDA_SMPL: process (Sys_clk) is
   begin
      if (Sys_clk'event and Sys_clk = '1') then
         if Reset = ENABLE_N then
            sda_sample <= '0';
         elsif (scl_rising_edge='1') then
            sda_sample <= sda_rin;
         end if;
      end if;
   end process SDA_SMPL;

   ----------------------------------------------------------------------------
   -- Main State Machine Process
   -- The following process contains the main I2C state machine for both master
   -- and slave modes. This state machine is clocked on the falling edge of SCL
   -- DETECT_STOP must stay as an asynchronous Reset because once STOP has been
   -- generated, SCL clock stops. Note that the bit_cnt signal updates on the
   -- scl_falling_edge pulse and is available on scl_f_edg_d1. So the count is
   -- available prior to the STATE changing.
   ----------------------------------------------------------------------------
   STATE_MACHINE : process (Sys_clk)
   begin

      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N or detect_stop = '1' then
            state   <= IDLE;
            sm_stop <= '0';

         elsif scl_f_edg_d2 = '1' or (Ro_prev = '0' and ro_prev_d1 = '1') then

            case state is

               ------------- IDLE STATE -------------
               when IDLE =>
                  --sm_stop <= sm_stop ;
                  if detect_start = '1' then
                     state <= HEADER;
                  end if;

                  ------------- HEADER STATE -------------
               when HEADER =>
                  --sm_stop <= sm_stop ;
                  if bit_cnt = CNT_DONE then
                     state <= ACK_HEADER;
                  end if;

                  ------------- ACK_HEADER STATE -------------
               when ACK_HEADER =>
                --  sm_stop <= sm_stop ;
                  if arb_lost = '1' then
                     state <= IDLE;
                  elsif sda_sample = '0' then
                     -- ack has been received, check for master/slave
                     if master_slave = '1' then
                        -- master, so check tx bit for direction
                        if Tx = '0' then
                           -- receive mode
                           state <= RCV_DATA;
                        else
                           --transmit mode
                           state <= XMIT_DATA;
                        end if;
                     else
                        if addr_match = '1' then
                           --if aas_i = '1' then
                           -- addressed slave, so check I2C_HEADER(0)
                           -- for direction
                           if i2c_header(0) = '0' then
                              -- receive mode
                              state <= RCV_DATA;
                           else
                              -- transmit mode
                              state <= XMIT_DATA;
                           end if;
                        else
                           -- not addressed, go back to IDLE
                           state <= IDLE;
                        end if;
                     end if;
                  else
                     -- not acknowledge received, stop as the address put on
                     -- the bus was not recognized/accepted by any slave
                     state <= IDLE;
                     if master_slave = '1' then
                        sm_stop <= '1';
                     end if;

                  end if;

                  ------------- RCV_DATA State --------------
               when RCV_DATA =>

                  --sm_stop <= sm_stop ;
                  -- check for repeated start
                  if (detect_start = '1') then
                     state <= HEADER;
                  elsif bit_cnt = CNT_DONE then
                     if master_slave = '0' and addr_match = '0' then
                        state <= IDLE;
                     else
                        -- Send an acknowledge
                        state <= ACK_DATA;
                     end if;
                  end if;

                  ------------ XMIT_DATA State --------------
               when XMIT_DATA =>
                  --sm_stop <= sm_stop ;

                  -- check for repeated start
                  if (detect_start = '1') then
                     state <= HEADER;

                  elsif bit_cnt = CNT_DONE then

                     -- Wait for acknowledge
                     state <= WAIT_ACK;

                  end if;

                  ------------- ACK_DATA State --------------
               when ACK_DATA =>
                  --sm_stop <= sm_stop ;

                  if Ro_prev = '0' then  -- stay in ACK_DATA until
                     state <= RCV_DATA;  -- a read of DRR has occurred
                  else
                     state <= ACK_DATA;
                  end if;

                  ------------- WAIT_ACK State --------------
               when WAIT_ACK =>
                  if arb_lost = '1' then
                     state <= IDLE;
                  elsif (sda_sample = '0') then
                     if (master_slave = '0' and addr_match = '0') then
                        state <= IDLE;
                     else
                        state <= XMIT_DATA;
                     end if;
                  else
                     -- not acknowledge received. The master transmitter is
                     -- being told to quit sending data as the slave won't take
                     -- anymore. Generate a STOP per spec. (Note that it
                     -- isn't strickly necessary for the master to get off the
                     -- bus at this point. It could retain ownership. However,
                     -- product specification indicates that it will get off
                     -- the bus) The slave transmitter is being informed by the
                     -- master that it won't take any more data.
                     if master_slave = '1' then
                        sm_stop <= '1';
                     end if;
                     state <= IDLE;
                  end if;

       -- coverage off
               when others =>
                  state <= IDLE;
       -- coverage on

            end case;

         end if;
      end if;
   end process STATE_MACHINE;

   LEVEL_1_GEN: if C_SDA_LEVEL = 1 generate
   begin
   ----------------------------------------------------------------------------
   -- Master SDA
   ----------------------------------------------------------------------------
   MAS_SDA : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            master_sda <= '1';
        -- elsif state = HEADER or state = XMIT_DATA then
        --   master_sda <= shift_out;
         elsif state = HEADER or (state = XMIT_DATA and
                                  tx_under_prev_i = '0' ) then
            master_sda <= shift_out;
         ---------------------------------
         -- Updated for CR 555648
         ---------------------------------
         elsif (tx_under_prev_i = '1' and state = XMIT_DATA) then
            master_sda <= '1';
         elsif state = ACK_DATA then
            master_sda <= Txak;
         else
            master_sda <= '1';
         end if;
      end if;
   end process MAS_SDA;
  end generate LEVEL_1_GEN;

  LEVEL_0_GEN:  if C_SDA_LEVEL = 0 generate
  begin
   ----------------------------------------------------------------------------
   -- Master SDA
   ----------------------------------------------------------------------------
   MAS_SDA : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            master_sda <= '1';
        -- elsif state = HEADER or state = XMIT_DATA then
        --   master_sda <= shift_out;
         elsif state = HEADER or (state = XMIT_DATA and
                                  tx_under_prev_i = '0' ) then
            master_sda <= shift_out;
         ---------------------------------
         -- Updated for CR 555648
         ---------------------------------
         elsif (tx_under_prev_i = '1' and state = XMIT_DATA) then
            master_sda <= '0';
         elsif state = ACK_DATA then
            master_sda <= Txak;
         else
            master_sda <= '1';
         end if;
      end if;
   end process MAS_SDA;
  end generate LEVEL_0_GEN;
   ----------------------------------------------------------------------------
   -- Slave SDA
   ----------------------------------------------------------------------------
   SLV_SDA : process(Sys_clk)
   begin
         -- For the slave SDA, address match(aas_i) only has to be checked when
         -- state is ACK_HEADER because state
         -- machine will never get to state XMIT_DATA or ACK_DATA
         -- unless address match is a one.
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            slave_sda  <= '1';
         elsif (addr_match = '1' and state = ACK_HEADER) or
            (state = ACK_DATA) then
            slave_sda <= Txak;
         elsif (state = XMIT_DATA) then
            slave_sda <= shift_out;
         else
            slave_sda <= '1';
         end if;
      end if;
   end process SLV_SDA;

------------------------------------------------------------
--Mathew : Added below process for CR 707697
   SHIFT_COUNT : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            shift_cnt    <= "000000000";
         elsif(shift_reg_ld = '1') then
            shift_cnt    <= "000000001";
         elsif(shift_reg_en = '1') then
            shift_cnt   <=  shift_cnt(7 downto 0) & shift_cnt(8);
         else
            shift_cnt   <=  shift_cnt;
         end if;
       end if;
   end process SHIFT_COUNT ;
 reg_empty <= '1' when shift_cnt(8) = '1' else '0';
------------------------------------------------------------
   ----------------------------------------------------------------------------
   -- I2C Data Shift Register
   ----------------------------------------------------------------------------
   I2CDATA_REG : entity axi_iic_v2_0_9.shift8
      port map (
         Clk       => Sys_clk,
         Clr       => Reset,
         Data_ld   => shift_reg_ld,
         Data_in   => Dtr,
         Shift_in  => sda_rin,
         Shift_en  => shift_reg_en,
         Shift_out => shift_out,
         Data_out  => shift_reg);

   ----------------------------------------------------------------------------
   -- Process : I2CDATA_REG_EN_CTRL
   ----------------------------------------------------------------------------
   I2CDATA_REG_EN_CTRL : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            shift_reg_en <= '0';
         elsif (
            -- Grab second byte of 10-bit address?
            (master_slave = '1' and state = HEADER and scl_rising_edge='1')
            -- Grab data byte
            or (state = RCV_DATA and scl_rising_edge='1'
                                 and detect_start = '0')
            -- Send data byte. Note use of scl_f_edg_d2 which is the 2 clock
            -- delayed version of the SCL falling edge signal
            or (state = XMIT_DATA and scl_f_edg_d2 = '1'
                                  and detect_start = '0')) then
            shift_reg_en <= '1';
         else
            shift_reg_en <= '0';
         end if;
      end if;
   end process I2CDATA_REG_EN_CTRL;

   ----------------------------------------------------------------------------
   -- Process : I2CDATA_REG_LD_CTRL
   ----------------------------------------------------------------------------
   I2CDATA_REG_LD_CTRL : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            shift_reg_ld <= '0';
         elsif (
            (master_slave = '1' and state = IDLE)
            or (state = WAIT_ACK)
            -- Slave Transmitter (i2c_header(0)='1' mean master wants to read)
            or (state = ACK_HEADER and i2c_header(0) = '1'
                                   and master_slave = '0')
            -- Master has a byte to transmit
            or (state = ACK_HEADER and Tx = '1' and master_slave = '1')
            -- ??
            or (state = RCV_DATA and detect_start = '1'))
            or tx_under_prev_i = '1' then
            shift_reg_ld <= '1';
         else
            shift_reg_ld <= '0';
         end if;
      end if;
   end process I2CDATA_REG_LD_CTRL;

   ----------------------------------------------------------------------------
   -- SHFT_REG_LD_PROCESS
   ----------------------------------------------------------------------------
   -- This process registers shift_reg_ld signal
   ----------------------------------------------------------------------------
   SHFT_REG_LD_PROCESS : process (Sys_clk)
   begin  -- process
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            shift_reg_ld_d1 <= '0';
         else                 --  Delay shift_reg_ld one clock
            shift_reg_ld_d1 <= shift_reg_ld;
         end if;
      end if;
   end process SHFT_REG_LD_PROCESS;

   ----------------------------------------------------------------------------
   -- NEW_XMT_PROCESS
   ----------------------------------------------------------------------------
   -- This process sets Rdy_new_xmt signal high for one sysclk after data has
   -- been loaded into the shift register.  This is used to create the Dtre
   -- interrupt.
   ----------------------------------------------------------------------------
   NEW_XMT_PROCESS : process (Sys_clk)
   begin  -- process
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            rdy_new_xmt_i <= '0';
         elsif state = XMIT_DATA or (state = HEADER and Msms = '1') then
            rdy_new_xmt_i <= (not (shift_reg_ld)) and shift_reg_ld_d1;
         end if;
      end if;
   end process NEW_XMT_PROCESS;

   Rdy_new_xmt <= rdy_new_xmt_i;

   ----------------------------------------------------------------------------
   -- I2C Header Shift Register
   -- Header/Address Shift Register
   ----------------------------------------------------------------------------
   I2CHEADER_REG : entity axi_iic_v2_0_9.shift8
      port map (
         Clk       => Sys_clk,
         Clr       => Reset,
         Data_ld   => i2c_header_ld,
         Data_in   => reg_clr,
         Shift_in  => sda_rin,
         Shift_en  => i2c_header_en,
         Shift_out => i2c_shiftout,
         Data_out  => i2c_header);

   ----------------------------------------------------------------------------
   -- Process : I2CHEADER_REG_CTRL
   ----------------------------------------------------------------------------
   I2CHEADER_REG_CTRL : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            i2c_header_en <= '0';
         elsif (state = HEADER and scl_rising_edge='1') then
            i2c_header_en <= '1';
         else
            i2c_header_en <= '0';
         end if;
      end if;
   end process I2CHEADER_REG_CTRL;

   i2c_header_ld <= '0';

   ----------------------------------------------------------------------------
   -- Bit Counter
   ----------------------------------------------------------------------------
   BITCNT : entity axi_iic_v2_0_9.upcnt_n
      generic map (
         C_SIZE => 4
         )
      port map(
                Clk    => Sys_clk,
                Clr    => Reset,
                Data    => cnt_start,
                Cnt_en => bit_cnt_en,
                Load   => bit_cnt_ld,
                Qout   => bit_cnt);

   ----------------------------------------------------------------------------
   -- Process :  Counter control lines
   ----------------------------------------------------------------------------
   BIT_CNT_EN_CNTL : process(Sys_clk)
   begin
      if Sys_clk'event and Sys_clk = '1' then
         if Reset = ENABLE_N then
            bit_cnt_en <= '0';
         elsif (state = HEADER and scl_falling_edge = '1')
            or (state = RCV_DATA and scl_falling_edge = '1')
            or (state = XMIT_DATA and scl_falling_edge = '1') then
            bit_cnt_en <= '1';
         else
            bit_cnt_en <= '0';
         end if;
      end if;
   end process BIT_CNT_EN_CNTL;

   bit_cnt_ld <= '1' when (state = IDLE) or (state = ACK_HEADER)
                 or (state = ACK_DATA)
                 or (state = WAIT_ACK)
                 or (detect_start = '1') else '0';

end architecture RTL;
