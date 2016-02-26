-------------------------------------------------------------------------------
-- reg_interface.vhd - entity/architecture pair
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
-- Filename:        reg_interface.vhd
-- Version:         v1.01.b                        
-- Description:
--                  This file contains the interface between the IPIF
--                  and the iic controller.  All registers are generated
--                  here and all interrupts are processed here.
--
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
-- ~~~~~~
--
--  NLR     01/07/11
-- ^^^^^^
--  - Release of v1.01.b
-- ~~~~~~
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.or_reduce;
use ieee.std_logic_arith.all;

library axi_iic_v2_0_9;
use axi_iic_v2_0_9.iic_pkg.all;

library unisim;
use unisim.all;

-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-- Definition of Generics:
--      C_TX_FIFO_EXIST     -- IIC transmit FIFO exist       
--      C_TX_FIFO_BITS      -- Transmit FIFO bit size 
--      C_RC_FIFO_EXIST     -- IIC receive FIFO exist       
--      C_RC_FIFO_BITS      -- Receive FIFO bit size
--      C_TEN_BIT_ADR       -- 10 bit slave addressing       
--      C_GPO_WIDTH         -- Width of General purpose output vector 
--      C_S_AXI_DATA_WIDTH      -- Slave bus data width      
--      C_NUM_IIC_REGS      -- Number of IIC Registers 
--
-- Definition of Ports:
--      Clk                   -- System clock
--      Rst                   -- System reset
--      Bus2IIC_Addr          -- Bus to IIC address bus
--      Bus2IIC_Data          -- Bus to IIC data bus
--      Bus2IIC_WrCE          -- Bus to IIC write chip enable
--      Bus2IIC_RdCE          -- Bus to IIC read chip enable
--      IIC2Bus_Data          -- IIC to Bus data bus
--      IIC2Bus_IntrEvent     -- IIC Interrupt events
--      Gpo                   -- General purpose outputs
--      Cr                    -- Control register
--      Msms_rst              -- MSMS reset signal
--      Rsta_rst              -- Repeated start reset
--      Msms_set              -- MSMS set 
--      DynMsmsSet            -- Dynamic MSMS set signal
--      DynRstaSet            -- Dynamic repeated start set signal
--      Cr_txModeSelect_set   -- Sets transmit mode select
--      Cr_txModeSelect_clr   -- Clears transmit mode select
--      Aas                   -- Addressed as slave indicator
--      Bb                    -- Bus busy indicator
--      Srw                   -- Slave read/write indicator
--      Abgc                  -- Addressed by general call indicator
--      Dtr                   -- Data transmit register
--      Rdy_new_xmt           -- New data loaded in shift reg indicator
--      Dtre                  -- Data transmit register empty
--      Drr                   -- Data receive register
--      Data_i2c              -- IIC data for processor
--      New_rcv_dta           -- New Receive Data ready
--      Ro_prev               -- Receive over run prevent
--      Adr                   -- IIC slave address
--      Ten_adr               -- IIC slave 10 bit address
--      Al                    -- Arbitration lost indicator
--      Txer                  -- Received acknowledge indicator
--      Tx_under_prev         -- DTR or Tx FIFO empty IRQ indicator
--      Tx_fifo_data          -- FIFO data to transmit
--      Tx_data_exists        -- next FIFO data exists
--      Tx_fifo_wr            -- Decode to enable writes to FIFO
--      Tx_fifo_rd            -- Decode to enable read from FIFO
--      Tx_fifo_rst           -- Reset Tx FIFO on IP Reset or CR(6)
--      Tx_fifo_Full          -- Transmit FIFO full indicator
--      Tx_addr               -- Transmit FIFO address
--      Rc_fifo_data          -- Read Fifo data for AXI
--      Rc_fifo_wr            -- Write IIC data to fifo
--      Rc_fifo_rd            -- AXI read from fifo
--      Rc_fifo_Full          -- Read Fifo is full prevent rcv overrun
--      Rc_data_Exists        -- Next FIFO data exists
--      Rc_addr               -- Receive FIFO address
-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------

entity reg_interface is
   generic(
      C_SCL_INERTIAL_DELAY : integer range 0 to 255 := 5;
      C_S_AXI_ACLK_FREQ_HZ : integer := 100000000;
      C_IIC_FREQ           : integer := 100000;
      C_SMBUS_PMBUS_HOST   : integer := 0;   -- SMBUS/PMBUS support
      C_TX_FIFO_EXIST      : boolean := TRUE;
      C_TX_FIFO_BITS       : integer := 4;
      C_RC_FIFO_EXIST      : boolean := TRUE;
      C_RC_FIFO_BITS       : integer := 4;
      C_TEN_BIT_ADR        : integer := 0;
      C_GPO_WIDTH          : integer := 0;
      C_S_AXI_ADDR_WIDTH   : integer := 32;
      C_S_AXI_DATA_WIDTH   : integer := 32;
      C_SIZE               : integer := 32;
      C_NUM_IIC_REGS       : integer;
      C_DEFAULT_VALUE      : std_logic_vector(7 downto 0) := X"FF"
      );
   port(
      -- IPIF Interface Signals
      Clk               : in std_logic;
      Rst               : in std_logic;
      Bus2IIC_Addr      : in std_logic_vector (0 to C_S_AXI_ADDR_WIDTH-1);
      Bus2IIC_Data      : in std_logic_vector (0 to C_S_AXI_DATA_WIDTH - 1);
      Bus2IIC_WrCE      : in std_logic_vector (0 to C_NUM_IIC_REGS - 1);
      Bus2IIC_RdCE      : in std_logic_vector (0 to C_NUM_IIC_REGS - 1);
      IIC2Bus_Data      : out std_logic_vector (0 to C_S_AXI_DATA_WIDTH - 1);
      IIC2Bus_IntrEvent : out std_logic_vector (0 to 7);

      -- Internal iic Bus Registers
      -- GPO Register  Offset 124h
      Gpo               : out std_logic_vector(32 - C_GPO_WIDTH to
                                            C_S_AXI_DATA_WIDTH - 1);
      -- Control Register  Offset 100h
      Cr                : out std_logic_vector(0 to 7);
      Msms_rst          : in  std_logic;  
      Rsta_rst          : in  std_logic;  
      Msms_set          : out std_logic;  

      DynMsmsSet          : in std_logic;  
      DynRstaSet          : in std_logic;  
      Cr_txModeSelect_set : in std_logic;  
      Cr_txModeSelect_clr : in std_logic;  

      -- Status Register  Offest 04h
      Aas                 : in std_logic;    
      Bb                  : in std_logic;    
      Srw                 : in std_logic;    
      Abgc                : in std_logic;    

      -- Data Transmit Register Offset 108h
      Dtr                 : out std_logic_vector(0 to 7);
      Rdy_new_xmt         : in  std_logic;
      Dtre                : out std_logic;

      -- Data Receive Register  Offset 10Ch
      Drr                 : out std_logic_vector(0 to 7);
      Data_i2c            : in  std_logic_vector(0 to 7);
      New_rcv_dta         : in  std_logic;  
      Ro_prev             : out std_logic;  

      -- Address Register Offset 10h
      Adr                 : out std_logic_vector(0 to 7);
        
      -- Ten Bit Address Register Offset 1Ch
      Ten_adr             : out std_logic_vector(5 to 7) := (others => '0');
      Al                  : in std_logic;  
      Txer                : in std_logic;  
      Tx_under_prev       : in std_logic;  

      -- Timing Parameters to iic_control
      Timing_param_tsusta : out std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_tsusto : out std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_thdsta : out std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_tsudat : out std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_tbuf   : out std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_thigh  : out std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_tlow   : out std_logic_vector(C_SIZE-1 downto 0);
      Timing_param_thddat : out std_logic_vector(C_SIZE-1 downto 0);

      --  FIFO input (fifo write) and output (fifo read)
      Tx_fifo_data        : in  std_logic_vector(0 to 7);  
      Tx_data_exists      : in  std_logic;  
      Tx_fifo_wr          : out std_logic;  
      Tx_fifo_rd          : out std_logic;  
      Tx_fifo_rst         : out std_logic;  
      Tx_fifo_Full        : in  std_logic;
      Tx_addr             : in  std_logic_vector(0 to C_TX_FIFO_BITS - 1);
      Rc_fifo_data        : in  std_logic_vector(0 to 7);  
      Rc_fifo_wr          : out std_logic;  
      Rc_fifo_rd          : out std_logic;  
      Rc_fifo_Full        : in  std_logic;  
      Rc_data_Exists      : in  std_logic;
      Rc_addr             : in  std_logic_vector(0 to C_RC_FIFO_BITS - 1);
      reg_empty           : in  std_logic

      );

end reg_interface;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture RTL of reg_interface is
  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";


   ----------------------------------------------------------------------------
   --  Constant Declarations
   ----------------------------------------------------------------------------
   
   -- Calls the function from the iic_pkg.vhd
   --constant C_SIZE : integer := num_ctr_bits(C_S_AXI_ACLK_FREQ_HZ, C_IIC_FREQ);


   constant IIC_CNT : integer := (C_S_AXI_ACLK_FREQ_HZ/C_IIC_FREQ - 14);

   -- Calls the function from the iic_pkg.vhd
   --constant C_SIZE : integer := num_ctr_bits(C_S_AXI_ACLK_FREQ_HZ, C_IIC_FREQ);

   -- number of SYSCLK in iic SCL High time
   constant HIGH_CNT : std_logic_vector(C_SIZE-1 downto 0)
      := conv_std_logic_vector(IIC_CNT/2 - C_SCL_INERTIAL_DELAY, C_SIZE);

   -- number of SYSCLK in iic SCL Low time
   constant LOW_CNT : std_logic_vector(C_SIZE-1 downto 0)
      := conv_std_logic_vector(IIC_CNT/2 - C_SCL_INERTIAL_DELAY, C_SIZE);

   -- half of HIGH_CNT
   constant HIGH_CNT_2 : std_logic_vector(C_SIZE-1 downto 0)
      := conv_std_logic_vector(IIC_CNT/4, C_SIZE);

   ----------------------------------------------------------------------------
   -- Function calc_tsusta
   --
   -- This function returns Setup time integer value for repeated start for
   -- Standerd mode or Fast mode opertation.
   ----------------------------------------------------------------------------

   FUNCTION calc_tsusta (
      constant C_IIC_FREQ : integer;
      constant C_S_AXI_ACLK_FREQ_HZ : integer;
      constant C_SIZE     : integer)
      RETURN std_logic_vector is
   begin
      -- Calculate setup time for repeated start condition depending on the
      -- mode {standard, fast}
      if (C_IIC_FREQ <= 100000) then
         -- Standard Mode timing 4.7 us
         RETURN  conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/175438, C_SIZE);
         -- Added to have 5.7 us (tr+tsu-sta)
      elsif (C_IIC_FREQ <= 400000) then
         -- Fast Mode timing is 0.6 us
         RETURN conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/1111111, C_SIZE);
         -- Added to have 0.9 us (tr+tsu-sta)
      else
         -- Fast Mode Plus timing is 0.26 us
         RETURN conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/2631579, C_SIZE);
         -- Added to have 0.380 us (tr+tsu-sta)
      end if;
   end FUNCTION calc_tsusta;

   ----------------------------------------------------------------------------
   -- Function calc_tsusto
   --
   -- This function returns Setup time integer value for stop condition for
   -- Standerd mode or Fast mode opertation.
   ----------------------------------------------------------------------------

   FUNCTION calc_tsusto (
      constant C_IIC_FREQ : integer;
      constant C_S_AXI_ACLK_FREQ_HZ : integer;
      constant C_SIZE     : integer)
      RETURN std_logic_vector is
   begin
      -- Calculate setup time for stop condition depending on the
      -- mode {standard, fast}
      if (C_IIC_FREQ <= 100000) then
         -- Standard Mode timing 4.0 us
         RETURN  conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/200000, C_SIZE);
         -- Added to have 5 us (tr+tsu-sto)
      elsif (C_IIC_FREQ <= 400000) then
         -- Fast Mode timing is 0.6 us
         RETURN  conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/1111111, C_SIZE);
         -- Added to have 0.9 us (tr+tsu-sto)
      else
         -- Fast-mode Plus timing is 0.26 us
         RETURN  conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/2631579, C_SIZE);
         -- Added to have 0.380 us (tr+tsu-sto)
      end if;
   end FUNCTION calc_tsusto;

   ----------------------------------------------------------------------------
   -- Function calc_thdsta
   --
   -- This function returns Hold time integer value for reapeted start for
   -- Standerd mode or Fast mode opertation.
   ----------------------------------------------------------------------------

   FUNCTION calc_thdsta (
      constant C_IIC_FREQ : integer;
      constant C_S_AXI_ACLK_FREQ_HZ : integer;
      constant C_SIZE     : integer)
      RETURN std_logic_vector is
   begin
      -- Calculate (repeated) START hold time depending on the
      -- mode {standard, fast}
      if (C_IIC_FREQ <= 100000) then
         -- Standard Mode timing 4.0 us
         RETURN  conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/232558, C_SIZE);
         -- Added to have 4.3 us (tf+thd-sta)
      elsif (C_IIC_FREQ <= 400000) then
         -- Fast Mode timing is 0.6 us
         RETURN conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/1111111, C_SIZE);
         -- Added to have 0.9 us (tf+thd-sta)
      else
         -- Fast-mode Plus timing is 0.26 us
         RETURN conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/2631579, C_SIZE);
         -- Added to have 0.380 us (tf+thd-sta)
      end if;
   end FUNCTION calc_thdsta;

   ----------------------------------------------------------------------------
   -- Function calc_tsudat
   --
   -- This function returns Data Setup time integer value for
   -- Standerd mode or Fast mode opertation.
   ----------------------------------------------------------------------------

   FUNCTION calc_tsudat (
      constant C_IIC_FREQ : integer;
      constant C_S_AXI_ACLK_FREQ_HZ : integer;
      constant C_SIZE     : integer)
      RETURN std_logic_vector is
   begin
      -- Calculate data setup time depending on the
      -- mode {standard, fast}
      if (C_IIC_FREQ <= 100000) then
         -- Standard Mode timing 250 ns
         RETURN  conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/1818181, C_SIZE);
         -- Added to have 550 ns (tf+tsu-dat)
      elsif (C_IIC_FREQ <= 400000) then
         -- Fast Mode timing is 100 ns
         RETURN conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/2500000, C_SIZE);
         -- Added to have 400 ns (tf+tsu-dat)
      else
         -- Fast-mode Plus timing is 50 ns
         RETURN conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/5882353, C_SIZE);
         -- Added to have 170 ns (tf+tsu-dat)
      end if;
   end FUNCTION calc_tsudat;

   ----------------------------------------------------------------------------
   -- Function calc_tbuf
   --
   -- This function returns Bus free time between a STOP and START condition 
   -- integer value for Standerd mode or Fast mode opertation.
   ----------------------------------------------------------------------------

   FUNCTION calc_tbuf (
      constant C_IIC_FREQ : integer;
      constant C_S_AXI_ACLK_FREQ_HZ : integer;
      constant C_SIZE     : integer)
      RETURN std_logic_vector is
   begin
      -- Calculate data setup time depending on the
      -- mode {standard, fast}
      if (C_IIC_FREQ <= 100000) then
         -- Standard Mode timing 4.7 us
         RETURN  conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/200000, C_SIZE);
         -- Added to have 5 us 
      elsif (C_IIC_FREQ <= 400000) then
         -- Fast Mode timing is 1.3 us
         RETURN conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/625000, C_SIZE);
         -- Added to have 1.6 us 
      else
         -- Fast-mode Plus timing is 0.5 us
         RETURN conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/1612904, C_SIZE);
         -- Added to have 0.62 us 
      end if;
   end FUNCTION calc_tbuf;

   ----------------------------------------------------------------------------
   -- Function calc_thddat
   --
   -- This function returns the data hold time integer value for I2C and
   -- SMBus/PMBus protocols. 
   ----------------------------------------------------------------------------

   FUNCTION calc_thddat (
      constant C_SMBUS_PMBUS_HOST : integer;
      constant C_IIC_FREQ : integer;
      constant C_S_AXI_ACLK_FREQ_HZ : integer;
      constant C_SIZE     : integer)
      RETURN std_logic_vector is
   begin
      -- Calculate data hold time depending on SMBus/PMBus compatability
      if (C_SMBUS_PMBUS_HOST = 1) then
         -- hold time of 300 ns for SMBus/PMBus
         RETURN  conv_std_logic_vector(C_S_AXI_ACLK_FREQ_HZ/3333334, C_SIZE);
      else
         -- hold time of 0 ns for normal I2C
         RETURN conv_std_logic_vector(1, C_SIZE);
      end if;
   end FUNCTION calc_thddat;

   -- Set-up time for a repeated start
   constant TSUSTA : std_logic_vector(C_SIZE-1 downto 0)
      := calc_tsusta(C_IIC_FREQ, C_S_AXI_ACLK_FREQ_HZ, C_SIZE);

   -- Set-up time for a stop
   constant TSUSTO : std_logic_vector(C_SIZE-1 downto 0)
      := calc_tsusto(C_IIC_FREQ, C_S_AXI_ACLK_FREQ_HZ, C_SIZE);

   -- Hold time (repeated) START condition. After this period, the first clock
   -- pulse is generated.
   constant THDSTA : std_logic_vector(C_SIZE-1 downto 0)
      := calc_thdsta(C_IIC_FREQ, C_S_AXI_ACLK_FREQ_HZ, C_SIZE);

   -- Data setup time.
   constant TSUDAT : std_logic_vector(C_SIZE-1 downto 0)
      := calc_tsudat(C_IIC_FREQ, C_S_AXI_ACLK_FREQ_HZ, C_SIZE);

   -- Bus free time.
   constant TBUF : std_logic_vector(C_SIZE-1 downto 0)
      := calc_tbuf(C_IIC_FREQ, C_S_AXI_ACLK_FREQ_HZ, C_SIZE);

   -- Data Hold time 
   constant THDDAT : std_logic_vector(C_SIZE-1 downto 0)
      := calc_thddat(C_SMBUS_PMBUS_HOST, C_IIC_FREQ, C_S_AXI_ACLK_FREQ_HZ, C_SIZE);


   ----------------------------------------------------------------------------
   -- Signal and Type Declarations
   ----------------------------------------------------------------------------

   signal cr_i           : std_logic_vector(0 to 7);  -- intrnl control reg
   signal sr_i           : std_logic_vector(0 to 7);  -- intrnl statuss reg
   signal dtr_i          : std_logic_vector(0 to 7);  -- intrnl dta trnsmt reg
   signal drr_i          : std_logic_vector(0 to 7);  -- intrnl dta receive reg
   signal adr_i          : std_logic_vector(0 to 7);  -- intrnl slave addr reg
   signal rc_fifo_pirq_i : std_logic_vector(4 to 7);  -- intrnl slave addr reg
   signal ten_adr_i      : std_logic_vector(5 to 7) := (others => '0');  
                                                      -- intrnl slave addr reg
   signal ro_a           : std_logic;  -- receive overrun SRFF
   signal ro_i           : std_logic;  -- receive overrun SRFF
   signal dtre_i         : std_logic;  -- data tranmit register empty register
   signal new_rcv_dta_d1 : std_logic;  -- delay new_rcv_dta to find rising edge
   signal msms_d1        : std_logic;  -- delay msms cr(5)
   signal ro_prev_i      : std_logic;  -- internal Ro_prev
   signal msms_set_i     : std_logic;  -- SRFF set on falling edge of msms
   signal rtx_i          : std_logic_vector(0 to 7);
   signal rrc_i          : std_logic_vector(0 to 7);
   signal rtn_i          : std_logic_vector(0 to 7);
   signal rpq_i          : std_logic_vector(0 to 7);
   signal gpo_i          : std_logic_vector(32 - C_GPO_WIDTH to 31); -- GPO

   signal timing_param_tsusta_i  : std_logic_vector(C_SIZE-1 downto 0);
   signal timing_param_tsusto_i  : std_logic_vector(C_SIZE-1 downto 0);
   signal timing_param_thdsta_i  : std_logic_vector(C_SIZE-1 downto 0);
   signal timing_param_tsudat_i  : std_logic_vector(C_SIZE-1 downto 0);
   signal timing_param_tbuf_i    : std_logic_vector(C_SIZE-1 downto 0);
   signal timing_param_thigh_i   : std_logic_vector(C_SIZE-1 downto 0);
   signal timing_param_tlow_i    : std_logic_vector(C_SIZE-1 downto 0);
   signal timing_param_thddat_i  : std_logic_vector(C_SIZE-1 downto 0);

   signal rback_data : std_logic_vector(0 to 32 * C_NUM_IIC_REGS - 1)
                                                           := (others => '0');
begin

   ----------------------------------------------------------------------------
   -- CONTROL_REGISTER_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the AXI when there is a write request and 
   -- the control register is enabled.
   ----------------------------------------------------------------------------
   CONTROL_REGISTER_PROCESS : process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            cr_i <= (others => '0');
         elsif                --  Load Control Register with AXI
            --  data if there is a write request
            --  and the control register is enabled
            Bus2IIC_WrCE(0) = '1' then
            cr_i(0 to 7) <= Bus2IIC_Data(24 to 31);
         else                 -- Load Control Register with iic data
            cr_i(0) <= cr_i(0);
            cr_i(1) <= cr_i(1);
            cr_i(2) <= (cr_i(2) or DynRstaSet) and not(Rsta_rst);
            cr_i(3) <= cr_i(3);
            cr_i(4) <= (cr_i(4) or Cr_txModeSelect_set) and 
                                not(Cr_txModeSelect_clr);
            cr_i(5) <= (cr_i(5) or DynMsmsSet) and not (Msms_rst);
            cr_i(6) <= cr_i(6);
            cr_i(7) <= cr_i(7);
         end if;
      end if;
   end process CONTROL_REGISTER_PROCESS;
   Cr <= cr_i;

   ----------------------------------------------------------------------------
   -- Delay msms by one clock to find falling edge
   ----------------------------------------------------------------------------
   MSMS_DELAY_PROCESS : process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            msms_d1 <= '0';
         else
            msms_d1 <= cr_i(5);
         end if;
      end if;
   end process MSMS_DELAY_PROCESS;

   ----------------------------------------------------------------------------
   -- Set when a fall edge of msms has occurred and Ro_prev is active
   -- This will prevent a throttle condition when a master receiver and
   -- trying to initiate a stop condition.
   ----------------------------------------------------------------------------
   MSMS_EDGE_SET_PROCESS : process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            msms_set_i <= '0';
         elsif ro_prev_i = '1' and cr_i(5) = '0' and msms_d1 = '1' then
            msms_set_i <= '1';
         elsif (cr_i(5) = '1' and msms_d1 = '0') or Bb = '0' then
            msms_set_i <= '0';
         else
            msms_set_i <= msms_set_i;
         end if;
      end if;
   end process MSMS_EDGE_SET_PROCESS;

   Msms_set <= msms_set_i;

   ----------------------------------------------------------------------------
   -- STATUS_REGISTER_PROCESS
   ----------------------------------------------------------------------------
   -- This process resets the status register. The status register is read only
   ----------------------------------------------------------------------------
   STATUS_REGISTER_PROCESS : process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            sr_i <= (others => '0');
         else                         -- Load Status Register with iic data
            sr_i(0) <= not Tx_data_exists;
            sr_i(1) <= not Rc_data_Exists;
            sr_i(2) <= Rc_fifo_Full;
            sr_i(3) <= Tx_fifo_Full;  -- addressed by a general call
            sr_i(4) <= Srw;           -- slave read/write
            sr_i(5) <= Bb;            -- bus busy
            sr_i(6) <= Aas;           -- addressed as slave
            sr_i(7) <= Abgc;          -- addressed by a general call
         end if;
      end if;
   end process STATUS_REGISTER_PROCESS;
                          
   ----------------------------------------------------------------------------
   -- Transmit FIFO CONTROL signal GENERATION
   ----------------------------------------------------------------------------
   -- This process allows the AXI to write data to the  write FIFO and assigns
   -- that data to the output port and to the internal signals for reading
   ----------------------------------------------------------------------------
   FIFO_GEN_DTR : if C_TX_FIFO_EXIST generate
      
      -------------------------------------------------------------------------
      -- FIFO_WR_CNTL_PROCESS  - Tx fifo write process
      -------------------------------------------------------------------------
      FIFO_WR_CNTL_PROCESS : process (Clk)
      begin
         if (Clk'event and Clk = '1') then
            if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
               Tx_fifo_wr <= '0';
            elsif
               Bus2IIC_WrCE(2) = '1' then
               Tx_fifo_wr <= '1';
            else
               Tx_fifo_wr <= '0';
            end if;
         end if;
      end process FIFO_WR_CNTL_PROCESS;

      -------------------------------------------------------------------------
      -- FIFO_DTR_REG_PROCESS
      -------------------------------------------------------------------------
      FIFO_DTR_REG_PROCESS : process (Tx_fifo_data)
      begin  -- process
         Dtr   <= Tx_fifo_data;
         dtr_i <= Tx_fifo_data;
      end process FIFO_DTR_REG_PROCESS;

      -------------------------------------------------------------------------
      -- Tx_FIFO_RD_PROCESS
      -------------------------------------------------------------------------
      -- This process generates the Read from the Transmit FIFO
      -------------------------------------------------------------------------
      Tx_FIFO_RD_PROCESS : process (Clk)
      begin
         if (Clk'event and Clk = '1') then
            if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
               Tx_fifo_rd <= '0';
            elsif Rdy_new_xmt = '1' then
               Tx_fifo_rd <= '1';
            elsif Rdy_new_xmt = '0'  --and Tx_data_exists = '1'
            then Tx_fifo_rd <= '0';
            end if;
         end if;
      end process Tx_FIFO_RD_PROCESS;

      -------------------------------------------------------------------------
      -- DTRE_PROCESS
      -------------------------------------------------------------------------
      -- This process generates the Data Transmit Register Empty Interrupt
      -- Interrupt(2)
      -------------------------------------------------------------------------
      DTRE_PROCESS : process (Clk)
      begin
         if (Clk'event and Clk = '1') then
            if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
               dtre_i <= '0';
            else
               dtre_i <= not (Tx_data_exists);
            end if;
         end if;
      end process DTRE_PROCESS;

      -------------------------------------------------------------------------
      -- Additional FIFO Interrupt
      -------------------------------------------------------------------------
      -- FIFO_Int_PROCESS generates interrupts back to the IPIF when Tx FIFO 
      -- exists
      -------------------------------------------------------------------------
      FIFO_INT_PROCESS : process (Clk)
      begin
         if (Clk'event and Clk = '1') then
            if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
               IIC2Bus_IntrEvent(7) <= '0';
            else
               IIC2Bus_IntrEvent(7) <= not Tx_addr(3);  -- Tx FIFO half empty
            end if;
         end if;
      end process FIFO_INT_PROCESS;


      -------------------------------------------------------------------------
      -- Tx_FIFO_RESET_PROCESS
      -------------------------------------------------------------------------
      -- This process generates the Data Transmit Register Empty Interrupt
      -- Interrupt(2)
      -------------------------------------------------------------------------
      TX_FIFO_RESET_PROCESS : process (Clk)
      begin
         if (Clk'event and Clk = '1') then
            if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
               Tx_fifo_rst <= '1';
            else
               Tx_fifo_rst <= cr_i(6);
            end if;
         end if;
      end process TX_FIFO_RESET_PROCESS;


   end generate FIFO_GEN_DTR;
   
   Dtre <= dtre_i;
   
   ----------------------------------------------------------------------------
   -- If a read FIFO exists then generate control signals
   ----------------------------------------------------------------------------
   RD_FIFO_CNTRL : if (C_RC_FIFO_EXIST) generate
      
      -------------------------------------------------------------------------
      -- WRITE_TO_READ_FIFO_PROCESS
      -------------------------------------------------------------------------
      WRITE_TO_READ_FIFO_PROCESS : process (Clk)
      begin
         if (Clk'event and Clk = '1') then
            if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
               Rc_fifo_wr <= '0';
            -- Load iic Data When new data x-fer complete and not x-mitting
            elsif  
               New_rcv_dta = '1' and new_rcv_dta_d1 = '0' then
               Rc_fifo_wr <= '1';
            else
               Rc_fifo_wr <= '0';
            end if;
         end if;
      end process WRITE_TO_READ_FIFO_PROCESS;

      -------------------------------------------------------------------------
      -- Assign the Receive FIFO data to the DRR so AXI can read the data
      -------------------------------------------------------------------------
      AXI_READ_FROM_READ_FIFO_PROCESS : process (Clk)
      begin  -- process
         if (Clk'event and Clk = '1') then
            if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
               Rc_fifo_rd <= '0';
            elsif Bus2IIC_RdCE(3) = '1' then
               Rc_fifo_rd <= '1';
            else
               Rc_fifo_rd <= '0';
            end if;
         end if;
      end process AXI_READ_FROM_READ_FIFO_PROCESS;

      -------------------------------------------------------------------------
      -- Assign the Receive FIFO data to the DRR so AXI can read the data
      -------------------------------------------------------------------------
      RD_FIFO_DRR_PROCESS : process (Rc_fifo_data)
      begin
         Drr   <= Rc_fifo_data;
         drr_i <= Rc_fifo_data;
      end process RD_FIFO_DRR_PROCESS;
   
      -------------------------------------------------------------------------
      -- Rc_FIFO_PIRQ
      -------------------------------------------------------------------------
      -- This process loads data from the AXI when there is a write request and
      -- the Rc_FIFO_PIRQ register is enabled.
      -------------------------------------------------------------------------
      Rc_FIFO_PIRQ_PROCESS : process (Clk)
      begin  -- process
         if (Clk'event and Clk = '1') then
            if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
               rc_fifo_pirq_i <= (others => '0');
            elsif             --  Load Status Register with AXI
               --  data if there is a write request
               --  and the status register is enabled
               Bus2IIC_WrCE(8) = '1' then
               rc_fifo_pirq_i(4 to 7) <= Bus2IIC_Data(28 to 31);
            else
               rc_fifo_pirq_i(4 to 7) <= rc_fifo_pirq_i(4 to 7);
            end if;
         end if;
      end process Rc_FIFO_PIRQ_PROCESS;
   
      -------------------------------------------------------------------------
      -- RC_FIFO_FULL_PROCESS
      -------------------------------------------------------------------------
      -- This process throttles the bus when receiving and the RC_FIFO_PIRQ is 
      -- equalto the Receive FIFO Occupancy value
      -------------------------------------------------------------------------
      RC_FIFO_FULL_PROCESS : process (Clk)
      begin  -- process
         if (Clk'event and Clk = '1') then
            if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
               ro_prev_i <= '0';

            elsif msms_set_i = '1' then
               ro_prev_i <= '0';

            elsif (rc_fifo_pirq_i(4) = Rc_addr(3) and
                   rc_fifo_pirq_i(5) = Rc_addr(2) and
                   rc_fifo_pirq_i(6) = Rc_addr(1) and
                   rc_fifo_pirq_i(7) = Rc_addr(0)) and
               Rc_data_Exists = '1'
            then
               ro_prev_i <= '1';
            else
               ro_prev_i <= '0';
            end if;
         end if;
      end process RC_FIFO_FULL_PROCESS;

      Ro_prev <= ro_prev_i;

   end generate RD_FIFO_CNTRL;

   ----------------------------------------------------------------------------
   -- RCV_OVRUN_PROCESS
   ----------------------------------------------------------------------------
   -- This process determines when the data receive register has had new data
   -- written to it without a read of the old data
   ----------------------------------------------------------------------------
   NEW_RECIEVE_DATA_PROCESS : process (Clk)  -- delay new_rcv_dta to find edge
   begin
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            new_rcv_dta_d1 <= '0';
         else
            new_rcv_dta_d1 <= New_rcv_dta;
         end if;
      end if;
   end process NEW_RECIEVE_DATA_PROCESS;

   ----------------------------------------------------------------------------
   -- RCV_OVRUN_PROCESS
   ----------------------------------------------------------------------------
   RCV_OVRUN_PROCESS : process (Clk)
   begin  
      -- SRFF set when new data is received, reset when a read of DRR occurs
      -- The second SRFF is set when new data is again received before a
      -- read of DRR occurs.  This sets the Receive Overrun Status Bit
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            ro_a <= '0';
         elsif New_rcv_dta = '1' and new_rcv_dta_d1 = '0' then
            ro_a <= '1';
         elsif New_rcv_dta = '0' and Bus2IIC_RdCE(3) = '1'
         then ro_a <= '0';
         else
            ro_a <= ro_a;
         end if;
      end if;
   end process RCV_OVRUN_PROCESS;

   ----------------------------------------------------------------------------
   -- ADDRESS_REGISTER_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the AXI when there is a write request and 
   -- the address register is enabled.
   ----------------------------------------------------------------------------
   ADDRESS_REGISTER_PROCESS : process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            adr_i <= (others => '0');
         elsif                --  Load Status Register with AXI
            --  data if there is a write request
            --  and the status register is enabled
            --   Bus2IIC_WrReq = '1' and Bus2IIC_WrCE(4) = '1' then
            Bus2IIC_WrCE(4) = '1' then
            adr_i(0 to 7) <= Bus2IIC_Data(24 to 31);
         else
            adr_i <= adr_i;
         end if;
      end if;
   end process ADDRESS_REGISTER_PROCESS;

   Adr <= adr_i;


   --PER_BIT_0_TO_31_GEN : for i in 0 to C_S_AXI_DATA_WIDTH-1 generate
   -- BIT_0_TO_31_LOOP : process (rback_data, Bus2IIC_RdCE) is
   -- begin
   --    if (or_reduce(Bus2IIC_RdCE) = '1') then
   --       for m in 0 to C_NUM_IIC_REGS-1 loop
   --          if (Bus2IIC_RdCE(m) = '1') then
   --             IIC2Bus_Data(i) <= rback_data(m*32 + i);
   --          else
   --             IIC2Bus_Data(i) <= '0';
   --          end if;
   --       end loop;
   --    else
   --       IIC2Bus_Data(i) <= '0';
   --    end if;
   -- end process BIT_0_TO_31_LOOP;
   --end generate PER_BIT_0_TO_31_GEN;


   OUTPUT_DATA_GEN_P : process (rback_data, Bus2IIC_RdCE, Bus2IIC_Addr) is
   begin

       if (or_reduce(Bus2IIC_RdCE) = '1') then
           --IIC2Bus_Data <= rback_data((32*TO_INTEGER(unsigned(Bus2IIC_Addr(24 to 29)))) 
                             -- to ((32*TO_INTEGER(unsigned(Bus2IIC_Addr(24 to 29))))+31)); -- CR          
           --case Bus2IIC_Addr(C_S_AXI_ADDR_WIDTH-8 to C_S_AXI_ADDR_WIDTH-1) is
           case Bus2IIC_Addr(1 to 8) is
               when X"00"  => IIC2Bus_Data <= rback_data(0 to 31);    -- CR          
               when X"04"  => IIC2Bus_Data <= rback_data(32 to 63);   -- SR          
               when X"08"  => IIC2Bus_Data <= rback_data(64 to 95);   -- TX_FIFO          
               when X"0C"  => IIC2Bus_Data <= rback_data(96 to 127);  -- RX_FIFO          
               when X"10"  => IIC2Bus_Data <= rback_data(128 to 159); -- ADR          
               when X"14"  => IIC2Bus_Data <= rback_data(160 to 191); -- TX_FIFO_OCY          
               when X"18"  => IIC2Bus_Data <= rback_data(192 to 223); -- RX_FIFO_OCY          
               when X"1C"  => IIC2Bus_Data <= rback_data(224 to 255); -- TEN_ADR          
               when X"20"  => IIC2Bus_Data <= rback_data(256 to 287); -- RX_FIFO_PIRQ          
               when X"24"  => IIC2Bus_Data <= rback_data(288 to 319); -- GPO          
               when X"28"  => IIC2Bus_Data <= rback_data(320 to 351); -- TSUSTA          
               when X"2C"  => IIC2Bus_Data <= rback_data(352 to 383); -- TSUSTO          
               when X"30"  => IIC2Bus_Data <= rback_data(384 to 415); -- THDSTA          
               when X"34"  => IIC2Bus_Data <= rback_data(416 to 447); -- TSUDAT          
               when X"38"  => IIC2Bus_Data <= rback_data(448 to 479); -- TBUF          
               when X"3C"  => IIC2Bus_Data <= rback_data(480 to 511); -- THIGH          
               when X"40"  => IIC2Bus_Data <= rback_data(512 to 543); -- TLOW          
               when X"44"  => IIC2Bus_Data <= rback_data(544 to 575); -- THDDAT          
               when others => IIC2Bus_Data <= (others => '0');
           end case;
       else 
           IIC2Bus_Data <= (others => '0');
       end if;
   end process OUTPUT_DATA_GEN_P;


   ----------------------------------------------------------------------------
   -- READ_REGISTER_PROCESS
   ----------------------------------------------------------------------------
   rback_data(32*1-8 to 32*1-1) <= cr_i(0 to 7);
   rback_data(32*2-9 to 32*2-1) <= '0' & sr_i(0 to 7);--reg_empty & sr_i(0 to 7);
   rback_data(32*3-8 to 32*3-1) <= dtr_i(0 to 7);
   rback_data(32*4-8 to 32*4-1) <= drr_i(0 to 7);
   rback_data(32*5-8 to 32*5-2) <= adr_i(0 to 6);
   rback_data(32*6-8 to 32*6-1) <= rtx_i(0 to 7);
   rback_data(32*7-8 to 32*7-1) <= rrc_i(0 to 7);
   rback_data(32*8-8 to 32*8-1) <= rtn_i(0 to 7);
   rback_data(32*9-8 to 32*9-1) <= rpq_i(0 to 7);

   ----------------------------------------------------------------------------
   -- GPO_RBACK_GEN generate 
   ----------------------------------------------------------------------------
   GPO_RBACK_GEN : if C_GPO_WIDTH /= 0 generate
      rback_data(32*10-C_GPO_WIDTH to 32*10-1)
                       <= gpo_i(32 - C_GPO_WIDTH to C_S_AXI_DATA_WIDTH - 1);

   end generate GPO_RBACK_GEN;

   rback_data(32*11-C_SIZE to 32*11-1) <= timing_param_tsusta_i(C_SIZE-1 downto 0);
   rback_data(32*12-C_SIZE to 32*12-1) <= timing_param_tsusto_i(C_SIZE-1 downto 0);
   rback_data(32*13-C_SIZE to 32*13-1) <= timing_param_thdsta_i(C_SIZE-1 downto 0);
   rback_data(32*14-C_SIZE to 32*14-1) <= timing_param_tsudat_i(C_SIZE-1 downto 0);
   rback_data(32*15-C_SIZE to 32*15-1) <= timing_param_tbuf_i(C_SIZE-1 downto 0);
   rback_data(32*16-C_SIZE to 32*16-1) <= timing_param_thigh_i(C_SIZE-1 downto 0);
   rback_data(32*17-C_SIZE to 32*17-1) <= timing_param_tlow_i(C_SIZE-1 downto 0);
   rback_data(32*18-C_SIZE to 32*18-1) <= timing_param_thddat_i(C_SIZE-1 downto 0);

   rtx_i(0 to 3) <= (others => '0');
   rtx_i(4)      <= Tx_addr(3);
   rtx_i(5)      <= Tx_addr(2);
   rtx_i(6)      <= Tx_addr(1);
   rtx_i(7)      <= Tx_addr(0);

   rrc_i(0 to 3) <= (others => '0');
   rrc_i(4)      <= Rc_addr(3);
   rrc_i(5)      <= Rc_addr(2);
   rrc_i(6)      <= Rc_addr(1);
   rrc_i(7)      <= Rc_addr(0);

   rtn_i(0 to 4) <= (others => '0');
   rtn_i(5 to 7) <= ten_adr_i(5 to 7);

   rpq_i(0 to 3) <= (others => '0');
   rpq_i(4 to 7) <= rc_fifo_pirq_i(4 to 7);

   ----------------------------------------------------------------------------
   -- Interrupts
   ----------------------------------------------------------------------------
   -- Int_PROCESS generates interrupts back to the IPIF
   ----------------------------------------------------------------------------
   INT_PROCESS : process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            IIC2Bus_IntrEvent(0 to 6) <= (others => '0');
         else
            IIC2Bus_IntrEvent(0) <= Al;    -- arbitration lost interrupt
            IIC2Bus_IntrEvent(1) <= Txer;  -- transmit error interrupt
            IIC2Bus_IntrEvent(2) <= Tx_under_prev;  --dtre_i; 
                                           -- Data Tx Register Empty interrupt
            IIC2Bus_IntrEvent(3) <= ro_prev_i;  --New_rcv_dta; 
                                            -- Data Rc Register Full interrupt
            IIC2Bus_IntrEvent(4) <= not Bb;
            IIC2Bus_IntrEvent(5) <= Aas;
            IIC2Bus_IntrEvent(6) <= not Aas;
         end if;
      end if;
   end process INT_PROCESS;

   ----------------------------------------------------------------------------
   -- Ten Bit Slave Address Generate
   ----------------------------------------------------------------------------
   -- Int_PROCESS generates interrupts back to the IPIF
   ----------------------------------------------------------------------------
   TEN_ADR_GEN : if (C_TEN_BIT_ADR = 1) generate

      -------------------------------------------------------------------------
      -- TEN_ADR_REGISTER_PROCESS
      -------------------------------------------------------------------------
      TEN_ADR_REGISTER_PROCESS : process (Clk)
      begin  -- process
         if (Clk'event and Clk = '1') then
            if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
               ten_adr_i <= (others => '0');
            elsif             --  Load Status Register with AXI
               --  data if there is a write request
               --  and the status register is enabled
               Bus2IIC_WrCE(7) = '1' then
               ten_adr_i(5 to 7) <= Bus2IIC_Data(29 to 31);
            else
               ten_adr_i <= ten_adr_i;
            end if;
         end if;
      end process TEN_ADR_REGISTER_PROCESS;

      Ten_adr <= ten_adr_i;

   end generate TEN_ADR_GEN;

   ----------------------------------------------------------------------------
   -- General Purpose Ouput Register Generate
   ----------------------------------------------------------------------------
   -- Generate the GPO if C_GPO_WIDTH is not equal to zero
   ----------------------------------------------------------------------------
   GPO_GEN : if (C_GPO_WIDTH /= 0) generate

      -------------------------------------------------------------------------
      -- GPO_REGISTER_PROCESS
      -------------------------------------------------------------------------
      GPO_REGISTER_PROCESS : process (Clk)
      begin  -- process
         if Clk'event and Clk = '1' then
            if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
               gpo_i <= C_DEFAULT_VALUE(C_GPO_WIDTH - 1 downto 0);
            elsif             --  Load Status Register with AXI
               --  data if there is a write CE
               --Bus2IIC_WrCE(C_NUM_IIC_REGS - 1) = '1' then
               Bus2IIC_WrCE(9) = '1' then
               gpo_i(32 - C_GPO_WIDTH to 31) <= 
                                          Bus2IIC_Data(32 - C_GPO_WIDTH to 31);
            else
               gpo_i <= gpo_i;
            end if;
         end if;
      end process GPO_REGISTER_PROCESS;

      Gpo <= gpo_i;

   end generate GPO_GEN;

   ----------------------------------------------------------------------------
   -- TSUSTA_REGISTER_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the AXI when there is a write request and 
   -- the tsusta register is enabled.
   ----------------------------------------------------------------------------
   TSUSTA_REGISTER_PROCESS: process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            --timing_param_tsusta_i <= (others => '0');
            timing_param_tsusta_i <= TSUSTA;
         elsif                --  Load tsusta Register with AXI
            --  data if there is a write request
            --  and the tsusta register is enabled
            Bus2IIC_WrCE(10) = '1' then
               timing_param_tsusta_i(C_SIZE-1 downto 0) <= Bus2IIC_Data(C_S_AXI_DATA_WIDTH-C_SIZE to C_S_AXI_DATA_WIDTH-1);
         else                 -- Load Control Register with iic data
               timing_param_tsusta_i(C_SIZE-1 downto 0) <= timing_param_tsusta_i(C_SIZE-1 downto 0);
         end if;
      end if;
   end process TSUSTA_REGISTER_PROCESS;

   Timing_param_tsusta <= timing_param_tsusta_i;

   ----------------------------------------------------------------------------
   -- TSUSTO_REGISTER_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the AXI when there is a write request and 
   -- the tsusto register is enabled.
   ----------------------------------------------------------------------------
   TSUSTO_REGISTER_PROCESS: process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            --timing_param_tsusto_i <= (others => '0');
            timing_param_tsusto_i <= TSUSTO;
         elsif                --  Load tsusto Register with AXI
            --  data if there is a write request
            --  and the tsusto register is enabled
            Bus2IIC_WrCE(11) = '1' then
               timing_param_tsusto_i(C_SIZE-1 downto 0) <= Bus2IIC_Data(C_S_AXI_DATA_WIDTH-C_SIZE to C_S_AXI_DATA_WIDTH-1);
         else                 -- Load Control Register with iic data
               timing_param_tsusto_i(C_SIZE-1 downto 0) <= timing_param_tsusto_i(C_SIZE-1 downto 0);
         end if;
      end if;
   end process TSUSTO_REGISTER_PROCESS;

   Timing_param_tsusto <= timing_param_tsusto_i;

   ----------------------------------------------------------------------------
   -- THDSTA_REGISTER_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the AXI when there is a write request and 
   -- the thdsta register is enabled.
   ----------------------------------------------------------------------------
   THDSTA_REGISTER_PROCESS: process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            timing_param_thdsta_i <= THDSTA;
         elsif                --  Load thdsta Register with AXI
            --  data if there is a write request
            --  and the thdsta register is enabled
            Bus2IIC_WrCE(12) = '1' then
               timing_param_thdsta_i(C_SIZE-1 downto 0) <= Bus2IIC_Data(C_S_AXI_DATA_WIDTH-C_SIZE to C_S_AXI_DATA_WIDTH-1);
         else                 -- Load Control Register with iic data
               timing_param_thdsta_i(C_SIZE-1 downto 0) <= timing_param_thdsta_i(C_SIZE-1 downto 0);
         end if;
      end if;
   end process THDSTA_REGISTER_PROCESS;

   Timing_param_thdsta <= timing_param_thdsta_i;

   ----------------------------------------------------------------------------
   -- TSUDAT_REGISTER_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the AXI when there is a write request and 
   -- the thdsta register is enabled.
   ----------------------------------------------------------------------------
   TSUDAT_REGISTER_PROCESS: process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            timing_param_tsudat_i <= TSUDAT;
         elsif                --  Load tsudat Register with AXI
            --  data if there is a write request
            --  and the tsudat register is enabled
            Bus2IIC_WrCE(13) = '1' then
               timing_param_tsudat_i(C_SIZE-1 downto 0) <= Bus2IIC_Data(C_S_AXI_DATA_WIDTH-C_SIZE to C_S_AXI_DATA_WIDTH-1);
         else                 -- Load Control Register with iic data
               timing_param_tsudat_i(C_SIZE-1 downto 0) <= timing_param_tsudat_i(C_SIZE-1 downto 0);
         end if;
      end if;
   end process TSUDAT_REGISTER_PROCESS;

   Timing_param_tsudat <= timing_param_tsudat_i;

   ----------------------------------------------------------------------------
   -- TBUF_REGISTER_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the AXI when there is a write request and 
   -- the tbuf register is enabled.
   ----------------------------------------------------------------------------
   TBUF_REGISTER_PROCESS: process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            timing_param_tbuf_i <= TBUF;
         elsif                --  Load tbuf Register with AXI
            --  data if there is a write request
            --  and the tbuf register is enabled
            Bus2IIC_WrCE(14) = '1' then
               timing_param_tbuf_i(C_SIZE-1 downto 0) <= Bus2IIC_Data(C_S_AXI_DATA_WIDTH-C_SIZE to C_S_AXI_DATA_WIDTH-1);
         else                 -- Load Control Register with iic data
               timing_param_tbuf_i(C_SIZE-1 downto 0) <= timing_param_tbuf_i(C_SIZE-1 downto 0);
         end if;
      end if;
   end process TBUF_REGISTER_PROCESS;

   Timing_param_tbuf <= timing_param_tbuf_i;

   ----------------------------------------------------------------------------
   -- THIGH_REGISTER_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the AXI when there is a write request and 
   -- the thigh register is enabled.
   ----------------------------------------------------------------------------
   THIGH_REGISTER_PROCESS: process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            timing_param_thigh_i <= HIGH_CNT;
         elsif                --  Load thigh Register with AXI
            --  data if there is a write request
            --  and the thigh register is enabled
            Bus2IIC_WrCE(15) = '1' then
               timing_param_thigh_i(C_SIZE-1 downto 0) <= Bus2IIC_Data(C_S_AXI_DATA_WIDTH-C_SIZE to C_S_AXI_DATA_WIDTH-1);
         else                 -- Load Control Register with iic data
               timing_param_thigh_i(C_SIZE-1 downto 0) <= timing_param_thigh_i(C_SIZE-1 downto 0);
         end if;
      end if;
   end process THIGH_REGISTER_PROCESS;

   Timing_param_thigh <= timing_param_thigh_i;

   ----------------------------------------------------------------------------
   -- TLOW_REGISTER_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the AXI when there is a write request and 
   -- the thigh register is enabled.
   ----------------------------------------------------------------------------
   TLOW_REGISTER_PROCESS: process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            timing_param_tlow_i <= LOW_CNT;
         elsif                --  Load tlow Register with AXI
            --  data if there is a write request
            --  and the tlow register is enabled
            Bus2IIC_WrCE(16) = '1' then
               timing_param_tlow_i(C_SIZE-1 downto 0) <= Bus2IIC_Data(C_S_AXI_DATA_WIDTH-C_SIZE to C_S_AXI_DATA_WIDTH-1);
         else                 -- Load Control Register with iic data
               timing_param_tlow_i(C_SIZE-1 downto 0) <= timing_param_tlow_i(C_SIZE-1 downto 0);
         end if;
      end if;
   end process TLOW_REGISTER_PROCESS;

   Timing_param_tlow <= timing_param_tlow_i;

   ----------------------------------------------------------------------------
   -- THDDAT_REGISTER_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the AXI when there is a write request and 
   -- the thddat register is enabled.
   ----------------------------------------------------------------------------
   THDDAT_REGISTER_PROCESS: process (Clk)
   begin  -- process
      if (Clk'event and Clk = '1') then
         if Rst = axi_iic_v2_0_9.iic_pkg.RESET_ACTIVE then
            timing_param_thddat_i <= THDDAT;
         elsif                --  Load thddat Register with AXI
            --  data if there is a write request
            --  and the thddat register is enabled
            Bus2IIC_WrCE(17) = '1' then
               timing_param_thddat_i(C_SIZE-1 downto 0) <= Bus2IIC_Data(C_S_AXI_DATA_WIDTH-C_SIZE to C_S_AXI_DATA_WIDTH-1);
         else                 -- Load Control Register with iic data
               timing_param_thddat_i(C_SIZE-1 downto 0) <= timing_param_thddat_i(C_SIZE-1 downto 0);
         end if;
      end if;
   end process THDDAT_REGISTER_PROCESS;

   Timing_param_thddat <= timing_param_thddat_i;

end architecture RTL;
