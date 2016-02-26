-------------------------------------------------------------------------------
-- jtag_control.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2003,2012,2014 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and 
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-------------------------------------------------------------------------------
-- Filename:        jtag_control.vhd
--
-- Description:     
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              jtag_control.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
--
-- History:
--   goran   2003-02-13    First Version
--   stefana 2012-03-16    Added support for 32 processors and external BSCAN
--   stefana 2013-11-01    Added extended debug: debug register access, debug
--                         memory access, cross trigger support
--   stefana 2013-06-15    Added support for external trace
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
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity JTAG_CONTROL is
  generic (
    C_MB_DBG_PORTS      : integer;
    C_USE_CONFIG_RESET  : integer;
    C_DBG_REG_ACCESS    : integer;
    C_DBG_MEM_ACCESS    : integer;
    C_M_AXI_ADDR_WIDTH  : integer;
    C_M_AXI_DATA_WIDTH  : integer;
    C_USE_CROSS_TRIGGER : integer;
    C_USE_UART          : integer;
    C_UART_WIDTH        : integer := 8;
    C_TRACE_OUTPUT      : integer;
    C_EN_WIDTH          : integer := 1
  );
  port (
    -- Global signals
    Config_Reset     : in std_logic;
    Scan_Reset_Sel   : in std_logic;
    Scan_Reset       : in std_logic;

    Clk              : in std_logic;
    Rst              : in std_logic;

    Clear_Ext_BRK    : in  std_logic;
    Ext_BRK          : out std_logic;
    Ext_NM_BRK       : out std_logic := '0';
    Debug_SYS_Rst    : out std_logic := '0';
    Debug_Rst        : out std_logic := '0';

    Read_RX_FIFO     : in  std_logic;
    Reset_RX_FIFO    : in  std_logic;
    RX_Data          : out std_logic_vector(0 to C_UART_WIDTH-1);
    RX_Data_Present  : out std_logic;
    RX_BUFFER_FULL   : out std_logic; 

    Write_TX_FIFO    : in  std_logic;
    Reset_TX_FIFO    : in  std_logic;
    TX_Data          : in  std_logic_vector(0 to C_UART_WIDTH-1);
    TX_Buffer_Full   : out std_logic;
    TX_Buffer_Empty  : out std_logic;

    -- Debug Register Access signals
    DbgReg_Access_Lock : in  std_logic;
    DbgReg_Force_Lock  : in  std_logic;
    DbgReg_Unlocked    : in  std_logic;
    JTAG_Access_Lock   : out std_logic;
    JTAG_Force_Lock    : out std_logic;
    JTAG_AXIS_Overrun  : in  std_logic;
    JTAG_Clear_Overrun : out std_logic;

    -- MDM signals
    TDI                : in  std_logic;
    RESET              : in  std_logic;
    UPDATE             : in  std_logic;
    SHIFT              : in  std_logic;
    CAPTURE            : in  std_logic;
    SEL                : in  std_logic;
    DRCK               : in  std_logic;
    TDO                : out std_logic;

    -- Bus Master signals
    M_AXI_ACLK         : in  std_logic;
    M_AXI_ARESETn      : in  std_logic;

    Master_rd_start    : out std_logic;
    Master_rd_addr     : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    Master_rd_len      : out std_logic_vector(4 downto 0);
    Master_rd_size     : out std_logic_vector(1 downto 0);
    Master_rd_excl     : out std_logic;
    Master_rd_idle     : in  std_logic;
    Master_rd_resp     : in  std_logic_vector(1 downto 0);
    Master_wr_start    : out std_logic;
    Master_wr_addr     : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    Master_wr_len      : out std_logic_vector(4 downto 0);
    Master_wr_size     : out std_logic_vector(1 downto 0);
    Master_wr_excl     : out std_logic;
    Master_wr_idle     : in  std_logic;
    Master_wr_resp     : in  std_logic_vector(1 downto 0);
    Master_data_rd     : out std_logic;
    Master_data_out    : in  std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
    Master_data_exists : in  std_logic;
    Master_data_wr     : out std_logic;
    Master_data_in     : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
    Master_data_empty  : in  std_logic;

    Master_dwr_addr    : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    Master_dwr_len     : out std_logic_vector(4 downto 0);
    Master_dwr_done    : in  std_logic;
    Master_dwr_resp    : in  std_logic_vector(1 downto 0);

    -- MicroBlaze Debug Signals
    MB_Debug_Enabled   : out std_logic_vector(C_EN_WIDTH-1 downto 0);
    Dbg_Clk            : out std_logic;
    Dbg_TDI            : out std_logic;
    Dbg_TDO            : in  std_logic;
    Dbg_Reg_En         : out std_logic_vector(0 to 7);
    Dbg_Capture        : out std_logic;
    Dbg_Shift          : out std_logic;
    Dbg_Update         : out std_logic;

    -- MicroBlaze Cross Trigger Signals
    Dbg_Trig_In_0      : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_1      : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_2      : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_3      : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_4      : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_5      : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_6      : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_7      : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_8      : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_9      : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_10     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_11     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_12     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_13     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_14     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_15     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_16     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_17     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_18     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_19     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_20     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_21     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_22     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_23     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_24     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_25     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_26     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_27     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_28     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_29     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_30     : in  std_logic_vector(0 to 7);
    Dbg_Trig_In_31     : in  std_logic_vector(0 to 7);

    Dbg_Trig_Ack_In_0  : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_1  : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_2  : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_3  : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_4  : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_5  : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_6  : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_7  : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_8  : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_9  : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_10 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_11 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_12 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_13 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_14 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_15 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_16 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_17 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_18 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_19 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_20 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_21 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_22 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_23 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_24 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_25 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_26 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_27 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_28 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_29 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_30 : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_31 : out std_logic_vector(0 to 7);

    Dbg_Trig_Out_0     : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_1     : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_2     : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_3     : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_4     : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_5     : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_6     : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_7     : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_8     : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_9     : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_10    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_11    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_12    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_13    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_14    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_15    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_16    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_17    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_18    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_19    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_20    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_21    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_22    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_23    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_24    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_25    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_26    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_27    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_28    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_29    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_30    : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_31    : out std_logic_vector(0 to 7);

    Dbg_Trig_Ack_Out_0  : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_1  : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_2  : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_3  : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_4  : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_5  : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_6  : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_7  : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_8  : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_9  : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_10 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_11 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_12 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_13 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_14 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_15 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_16 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_17 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_18 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_19 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_20 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_21 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_22 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_23 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_24 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_25 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_26 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_27 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_28 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_29 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_30 : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_31 : in  std_logic_vector(0 to 7);

    Ext_Trig_In         : in  std_logic_vector(0 to 3);
    Ext_Trig_Ack_In     : out std_logic_vector(0 to 3);
    Ext_Trig_Out        : out std_logic_vector(0 to 3);
    Ext_Trig_Ack_Out    : in  std_logic_vector(0 to 3);

    -- Trace signals
    Trace_Clk           : in  std_logic;
    Trace_Reset         : in  std_logic;
    Trace_Test_Pattern  : out std_logic_vector(0 to 3);
    Trace_Test_Start    : out std_logic;
    Trace_Test_Stop     : out std_logic;
    Trace_Test_Timed    : out std_logic;
    Trace_Delay         : out std_logic_vector(0 to 7);
    Trace_Stopped       : out std_logic
  );

end entity JTAG_CONTROL;

library unisim;
use unisim.vcomponents.all;

library mdm_v3_2_4;
use mdm_v3_2_4.SRL_FIFO;

architecture IMP of JTAG_CONTROL is

  component SRL_FIFO
    generic (
      C_DATA_BITS :     natural;
      C_DEPTH     :     natural
    );
    port (
      Clk           : in  std_logic;
      Reset         : in  std_logic;
      FIFO_Write    : in  std_logic;
      Data_In       : in  std_logic_vector(0 to C_DATA_BITS-1);
      FIFO_Read     : in  std_logic;
      Data_Out      : out std_logic_vector(0 to C_DATA_BITS-1);
      FIFO_Full     : out std_logic;
      Data_Exists   : out std_logic
    );
  end component SRL_FIFO;

  --
  -- Old Config Word in previous versions
  --
  -- Magic String + Has FSL +   0   + Has UART + UART Width + Num MB + Num hw ports + Debug Version 
  --    8 bits    +  1 bit  + 1 bit +  1 bit   +   5 bits   + 8 bits +    4 bits    +     4 bits  
  --
  -- New Config Word in mdm v2
  --
  -- Magic String +   00   + Has UART + UART Width + Num MB + UART version + Debug Version 
  --    8 bits    + 2 bits +  1 bit   +   5 bits   + 8 bits +    4 bits    +     4 bits  
  --
  -- New Config Word in mdm v2 with extended debug
  --
  -- Extended Config + Magic String +   1   + Extended  + Has UART + UART Width + Num MB + UART version + Debug Version 
  --    5 bits       +    8 bits    + 1 bit +   1 bit   +  1 bit   +   5 bits   + 8 bits +    4 bits    +     4 bits  
  --
  -- Debug Version Table
  --  0,1,2: Obsolete
  --    3,4: Watchpoint support
  --      5: Remove sync
  --      6: Change command and Reg_En signals to 8 bits
  --      7: Change MB_Debug_Enabled to 32 bits
  --
  -- UART Version Table
  --  0: Get version from Debug Version Table
  --  6: Non-buffered mode support
  --
  function TDI_Shifter_Size return integer is
  begin
    if C_USE_CROSS_TRIGGER = 1 or C_TRACE_OUTPUT = 3 then
      if C_MB_DBG_PORTS < 16 then
        return 16;
      else
        return C_MB_DBG_PORTS;
      end if;
    elsif C_TRACE_OUTPUT = 1 then
      if C_MB_DBG_PORTS < 14 then
        return 14;
      else
        return C_MB_DBG_PORTS;
      end if;
    elsif C_MB_DBG_PORTS > 8 then
      return C_MB_DBG_PORTS;
    end if;
    return 8;
  end function TDI_Shifter_Size;

  function Which_MB_Reg_Size return integer is
  begin
    if C_MB_DBG_PORTS > 8 then
      return C_MB_DBG_PORTS;
    end if;
    return 8;
  end function Which_MB_Reg_Size;

  constant No_MicroBlazes : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(C_MB_DBG_PORTS, 8));
  constant UART_VERSION   : std_logic_vector(3 downto 0) := "0110";
  constant DEBUG_VERSION  : std_logic_vector(3 downto 0) := "0111";

  constant Config_Init_Word_S : std_logic_vector(15 downto 0) :=
    (No_MicroBlazes & UART_VERSION & DEBUG_VERSION);
  constant Config_Init_Word   : bit_vector(15 downto 0)       :=
    to_bitvector(Config_Init_Word_S);

  constant C_EXT_CONFIG    : integer :=
    Boolean'Pos(C_DBG_MEM_ACCESS > 0 or C_DBG_REG_ACCESS > 0 or C_USE_CROSS_TRIGGER > 0 or C_TRACE_OUTPUT > 0);
  constant HAVE_EXTENDED : std_logic_vector(0 to 0) :=
    std_logic_vector(to_unsigned(C_EXT_CONFIG, 1));
  constant HAVE_UART    : std_logic_vector(0 to 0) :=
    std_logic_vector(to_unsigned(C_USE_UART, 1));
  constant UART_WIDTH   : std_logic_vector(0 to 4) :=
    std_logic_vector(to_unsigned(C_UART_WIDTH-1, 5));
  constant MAGIC_STRING : std_logic_vector(0 to 7) := "01000010";

  constant Config_Init_Word2_S : std_logic_vector(15 downto 0) :=
    (MAGIC_STRING & '1' & HAVE_EXTENDED & HAVE_UART & UART_WIDTH);
  constant Config_Init_Word2   : bit_vector(15 downto 0)       :=
    to_bitvector(Config_Init_Word2_S);

  constant Config_Init_Word3_S : std_logic_vector(15 downto 0) :=
    std_logic_vector(to_unsigned(0,                  11) &
                     to_unsigned(C_TRACE_OUTPUT,      2) &
                     to_unsigned(C_USE_CROSS_TRIGGER, 1) &
                     to_unsigned(C_DBG_REG_ACCESS,    1) &
                     to_unsigned(C_DBG_MEM_ACCESS,    1));
  constant Config_Init_Word3   : bit_vector(15 downto 0)       :=
    to_bitvector(Config_Init_Word3_S);

  signal config_TDO_1 : std_logic;
  signal config_TDO_2 : std_logic;
  signal config_TDO_3 : std_logic;
  signal config_TDO   : std_logic;
  signal ID_TDO       : std_logic;
  signal ID_TDO_1     : std_logic;
  signal ID_TDO_2     : std_logic;
  signal uart_TDO     : std_logic;
  signal compl_TDO    : std_logic;
  signal master_TDO   : std_logic;
  signal axis_TDO     : std_logic;
  signal ct_TDO       : std_logic;
  signal trace_TDO    : std_logic;

  -----------------------------------------------------------------------------
  -- JTAG signals
  -----------------------------------------------------------------------------
  signal data_cmd         : std_logic;
  signal data_cmd_n       : std_logic;
  signal data_cmd_noblock : std_logic;

  signal sel_n_reset : std_logic;
  signal sel_n       : std_logic;
  signal sel_n_delay : std_logic_vector(0 to 5);

  signal command     : std_logic_vector(0 to 7) := (others => '0');
  signal command_1   : std_logic_vector(0 to 7) := (others => '0');
  signal tdi_shifter : std_logic_vector(0 to TDI_Shifter_Size - 1) := (others => '0');

  signal shifting_Data : std_logic;

  signal   sync_detected : std_logic;
  signal   sync          : std_logic;
  constant SYNC_CONST    : std_logic_vector(1 to 8) := "01101001";

  signal shift_Count : std_logic_vector(4 + C_EXT_CONFIG downto 0) := (others => '0');

  signal mb_debug_enabled_i : std_logic_vector(C_EN_WIDTH-1 downto 0);

  constant C_NUM_DBG_CT : integer := 8;
  constant C_NUM_EXT_CT : integer := 4;
  type dbg_trig_type is array (0 to 31) of std_logic_vector(0 to C_NUM_DBG_CT - 1);
  signal dbg_trig_ack_in_i : dbg_trig_type;
  signal dbg_trig_out_i    : dbg_trig_type;
  signal ext_trig_ack_in_i : std_logic_vector(0 to C_NUM_EXT_CT - 1);
  signal ext_trig_out_i    : std_logic_vector(0 to C_NUM_EXT_CT - 1);

  signal completion_ctrl   : std_logic_vector(0  downto 0) := (others => '0');
  signal completion_status : std_logic_vector(15 downto 0) := (others => '0');
  signal completion_block  : std_logic := '0';
  signal clear_overrun     : std_logic := '0';
  signal mb_instr_overrun  : std_logic := '0';
  signal mb_instr_error    : std_logic := '0';
  signal mb_data_overrun   : std_logic := '0';
  signal master_overrun    : std_logic;
  signal master_error      : std_logic;

  -----------------------------------------------------------------------------
  -- Register handling
  -----------------------------------------------------------------------------
  constant MDM_DEBUG_ID          : std_logic_vector(0 to 7) := "00000000";
  constant MB_WRITE_CONTROL      : std_logic_vector(0 to 7) := "00000001";
  constant MB_WRITE_COMMAND      : std_logic_vector(0 to 7) := "00000010";
  constant MB_READ_STATUS        : std_logic_vector(0 to 7) := "00000011";
  constant MB_WRITE_INSTR        : std_logic_vector(0 to 7) := "00000100";
  --constant MB_WRITE_DATA         : std_logic_vector(0 to 7) := "00000101";
  constant MB_READ_DATA          : std_logic_vector(0 to 7) := "00000110";
  constant MB_READ_CONFIG        : std_logic_vector(0 to 7) := "00000111";
  constant MB_WRITE_BRK_RST_CTRL : std_logic_vector(0 to 7) := "00001000";
  constant UART_WRITE_BYTE       : std_logic_vector(0 to 7) := "00001001";
  constant UART_READ_STATUS      : std_logic_vector(0 to 7) := "00001010";
  constant UART_READ_BYTE        : std_logic_vector(0 to 7) := "00001011";
  constant MDM_READ_CONFIG       : std_logic_vector(0 to 7) := "00001100";
  constant MDM_WRITE_WHICH_MB    : std_logic_vector(0 to 7) := "00001101";
  constant UART_WRITE_CONTROL    : std_logic_vector(0 to 7) := "00001110";
  --constant MDM_WRITE_TO_FSL      : std_logic_vector(0 to 7) := "00001111";

  -- registers "00010000" to "00011111" are pc breakpoints 1-16

  constant BUSM_WRITE_DATA       : std_logic_vector(0 to 7) := "00100001";
  constant BUSM_READ_STATUS      : std_logic_vector(0 to 7) := "00100010";
  constant BUSM_READ_DATA        : std_logic_vector(0 to 7) := "00100011";
  constant BUSM_WRITE_COMMAND    : std_logic_vector(0 to 7) := "00100101";
  constant BUSM_WRITE_CONTROL    : std_logic_vector(0 to 7) := "00100110";

  constant MDM_READ_COMPL_STATUS : std_logic_vector(0 to 7) := "00101010";
  constant MDM_WRITE_COMPL_CTRL  : std_logic_vector(0 to 7) := "00101101";

  constant AXIS_READ_STATUS      : std_logic_vector(0 to 7) := "00110010";
  constant AXIS_WRITE_COMMAND    : std_logic_vector(0 to 7) := "00110110";

  constant CT_WRITE_EXT_CTRL     : std_logic_vector(0 to 7) := "01000000";
  constant CT_READ_STATUS        : std_logic_vector(0 to 7) := "01000010";
  constant CT_WRITE_CTRL         : std_logic_vector(0 to 7) := "01000110";

  constant TRACE_READ_STATUS     : std_logic_vector(0 to 7) := "01001010";
  constant TRACE_READ_ADDR       : std_logic_vector(0 to 7) := "01001011";
  constant TRACE_WRITE_LOW_ADDR  : std_logic_vector(0 to 7) := "01001100";
  constant TRACE_WRITE_HIGH_ADDR : std_logic_vector(0 to 7) := "01001101";
  constant TRACE_WRITE_CONTROL   : std_logic_vector(0 to 7) := "01001110";

  -- registers "01010000" to "11111111" are reserved for MicroBlaze

  -----------------------------------------------------------------------------
  -- Internal signals for debugging
  -----------------------------------------------------------------------------
  signal set_Ext_BRK     : std_logic := '0';
  signal ext_BRK_i       : std_logic := '0';

  signal Ext_NM_BRK_i    : std_logic := '0';
  signal Debug_SYS_Rst_i : std_logic := '0';
  signal Debug_Rst_i     : std_logic := '0';

  constant ID_Init_Word1 : bit_vector(15 downto 0) := x"4443";  -- Ascii
  constant ID_Init_Word2 : bit_vector(15 downto 0) := x"584D";  -- "XMDC"

  signal config_with_scan_reset : std_logic;

  attribute KEEP : string;

begin  -- architecture IMP

  config_with_scan_reset <= Config_Reset when Scan_Reset_Sel = '0' else
                            Scan_Reset;

  -----------------------------------------------------------------------------
  -- Control logic
  -----------------------------------------------------------------------------

  -- data_cmd | meaning
  -- ======================
  --     0    | Command phase
  --     1    | Data phase    

  sel_n_reset <= sel_n when Scan_Reset_Sel = '0' else
                 Scan_Reset;
  
  FDC_I : FDC_1
    port map (
      Q   => data_cmd_noblock,          -- [out std_logic]
      C   => Update,                    -- [in  std_logic]
      D   => data_cmd_n,                -- [in  std_logic]
      CLR => sel_n_reset);              -- [in  std_logic]

  data_cmd_n <= not data_cmd_noblock;
  data_cmd   <= data_cmd_noblock and not completion_block;

  --  sel_n        <= not SEL;
  -- Need to delay sel_n to make sure that it arrives at the FDC_I after the
  -- falling edge of Update. Update can get a long skew so extra LUTS are
  -- inserted as delay elements
  sel_n_delay(0) <= not SEL;

  Insert_Delays : for I in sel_n_delay'left to sel_n_delay'right-1 generate
    signal local_sel_n : std_logic;
    attribute KEEP of local_sel_n : signal is "TRUE";
  begin

    LUT_Delay : LUT4
      generic map(
        INIT => X"0002"
      )
      port map (
        O    => local_sel_n,            -- [out]
        I0   => sel_n_delay(I),         -- [in]
        I1   => '0',                    -- [in]
        I2   => '0',                    -- [in]
        I3   => '0');                   -- [in]

    sel_n_delay(I+1) <= local_sel_n;
  end generate Insert_Delays;

  sel_n <= sel_n_delay(sel_n_delay'right) or Config_Reset;

  Input_shifter : process (DRCK, config_with_scan_reset)
  begin
    if config_with_scan_reset = '1' then
      tdi_shifter <= (others => '0');
    elsif DRCK'event and DRCK = '1' then
      if SEL = '1' and SHIFT = '1' then
        tdi_shifter <= TDI & tdi_shifter(0 to tdi_shifter'right - 1);
      end if;
    end if;
  end process Input_shifter;

  Command_update : process (UPDATE, config_with_scan_reset)
  begin
    if config_with_scan_reset = '1' then
      command <= (others => '0');
    elsif UPDATE'event and UPDATE = '0' then
      if SEL = '1' then
        command <= command_1;
      end if;
    end if;
  end process Command_update;

  Command_update_1 : process (UPDATE, config_with_scan_reset)
  begin
    if config_with_scan_reset = '1' then
      command_1 <= (others => '0');
    elsif UPDATE'event and UPDATE = '1' then
      if SEL = '1' and data_cmd = '0' then
        command_1 <= tdi_shifter (0 to 7);
      end if;
    end if;
  end process Command_update_1;

  Dbg_Clk     <= DRCK;
  Dbg_Reg_En  <= command when data_cmd = '1' else (others => '0');
  Dbg_TDI     <= TDI;
  Dbg_Capture <= CAPTURE;
  Dbg_Update  <= UPDATE;

  -- No sync word requirement for commands other than "Write Instruction"
  shifting_Data <= (SHIFT and sync)
                   when (command = MB_WRITE_INSTR) and (data_cmd = '1')
                   else SHIFT;

  Dbg_Shift <= shifting_Data;

  sync_detected <= '1' when tdi_shifter(0 to 7) = SYNC_CONST and data_cmd = '1'
                   else '0';

  SYNC_FDRE : FDRE_1
    port map (
      Q  => sync,
      C  => DRCK,
      CE => sync_detected,
      D  => '1',
      R  => data_cmd_n);

  -----------------------------------------------------------------------------
  -- Shift Counter
  -----------------------------------------------------------------------------
  -- Keep a counter on the number of bits in the data phase after a sync has
  -- been detected
  Shift_Counter : process (DRCK, config_with_scan_reset) is
  begin  --  process Shift_Counter
    if config_with_scan_reset = '1' then
      shift_Count <= (others => '0');
    elsif DRCK'event and DRCK = '1' then   -- rising clock edge
      if SHIFT = '0' then
        shift_Count <= (others => '0');
      else
        shift_Count <= std_logic_vector(unsigned(Shift_Count) + 1);
      end if;
    end if;
  end process Shift_Counter;

  -----------------------------------------------------------------------------
  -- Config Register
  -----------------------------------------------------------------------------
  Use_Config_SRL16E : if (C_USE_CONFIG_RESET = 0) generate
  begin
    SRL16E_1 : SRL16E
      generic map (
        INIT => Config_Init_Word
      )
      port map (
        CE   => '0',                      -- [in  std_logic]
        D    => '0',                      -- [in  std_logic]
        Clk  => DRCK,                     -- [in  std_logic]
        A0   => shift_Count(0),           -- [in  std_logic]
        A1   => shift_Count(1),           -- [in  std_logic]
        A2   => shift_Count(2),           -- [in  std_logic]
        A3   => shift_Count(3),           -- [in  std_logic]
        Q    => config_TDO_1);            -- [out std_logic]

    SRL16E_2 : SRL16E
      generic map (
        INIT => Config_Init_Word2
      )
      port map (
        CE   => '0',                      -- [in  std_logic]
        D    => '0',                      -- [in  std_logic]
        Clk  => DRCK,                     -- [in  std_logic]
        A0   => shift_Count(0),           -- [in  std_logic]
        A1   => shift_Count(1),           -- [in  std_logic]
        A2   => shift_Count(2),           -- [in  std_logic]
        A3   => shift_Count(3),           -- [in  std_logic]
        Q    => config_TDO_2);            -- [out std_logic]

    Use_Ext_Config: if (C_EXT_CONFIG > 0) generate
    begin
      SRL16E_3 : SRL16E
        generic map (
          INIT => Config_Init_Word3
        )
        port map (
          CE   => '0',                      -- [in  std_logic]
          D    => '0',                      -- [in  std_logic]
          Clk  => DRCK,                     -- [in  std_logic]
          A0   => shift_Count(0),           -- [in  std_logic]
          A1   => shift_Count(1),           -- [in  std_logic]
          A2   => shift_Count(2),           -- [in  std_logic]
          A3   => shift_Count(3),           -- [in  std_logic]
          Q    => config_TDO_3);            -- [out std_logic]
    end generate Use_Ext_Config;

  end generate Use_Config_SRL16E;

  No_Config_SRL16E : if (C_USE_CONFIG_RESET = 1) generate
  begin
    config_TDO_1 <= Config_Init_Word_S(to_integer(unsigned(shift_Count(3 downto 0))));
    config_TDO_2 <= Config_Init_Word2_S(to_integer(unsigned(shift_Count(3 downto 0))));

    Use_Ext_Config: if (C_EXT_CONFIG > 0) generate
    begin
      config_TDO_3 <= Config_Init_Word3_S(to_integer(unsigned(shift_Count(3 downto 0))));
    end generate Use_Ext_Config;

  end generate No_Config_SRL16E;

  Use_Ext_Config: if (C_EXT_CONFIG > 0) generate
  begin
    config_TDO <= config_TDO_1 when shift_Count(5 downto 4) = "00" else
                  config_TDO_2 when shift_Count(5 downto 4) = "01" else
                  config_TDO_3;
  end generate Use_Ext_Config;

  No_Ext_Config: if (C_EXT_CONFIG = 0) generate
  begin
    config_TDO_3 <= '0'; -- Unused
    config_TDO <= config_TDO_1 when shift_Count(4) = '0' else config_TDO_2;
  end generate No_Ext_Config;

  -----------------------------------------------------------------------------
  -- ID Register
  -----------------------------------------------------------------------------
  Use_ID_SRL16E : if (C_USE_CONFIG_RESET = 0) generate
  begin
    SRL16E_ID_1 : SRL16E
      generic map (
        INIT => ID_Init_Word1
      )
      port map (
        CE   => '0',
        D    => '0',
        Clk  => DRCK,
        A0   => shift_Count(0),
        A1   => shift_Count(1),
        A2   => shift_Count(2),
        A3   => shift_Count(3),
        Q    => ID_TDO_1);

    SRL16E_ID_2 : SRL16E
      generic map (
        INIT => ID_Init_Word2
      )
      port map (
        CE   => '0',
        D    => '0',
        Clk  => DRCK,
        A0   => shift_Count(0),
        A1   => shift_Count(1),
        A2   => shift_Count(2),
        A3   => shift_Count(3),
        Q    => ID_TDO_2);
  end generate Use_ID_SRL16E;

  No_ID_SRL16E : if (C_USE_CONFIG_RESET = 1) generate
  begin
    ID_TDO_1 <= To_X01(ID_Init_Word1(to_integer(unsigned(shift_Count(3 downto 0)))));
    ID_TDO_2 <= To_X01(ID_Init_Word2(to_integer(unsigned(shift_Count(3 downto 0)))));
  end generate No_ID_SRL16E;

  ID_TDO <= ID_TDO_1 when shift_Count(4) = '0' else ID_TDO_2;

  -----------------------------------------------------------------------------
  -- Handling the Which_MB register
  -----------------------------------------------------------------------------
  More_Than_One_MB : if (C_MB_DBG_PORTS > 1) generate
    signal Which_MB_Reg : std_logic_vector(Which_MB_Reg_Size - 1 downto 0) := (others => '0');
  begin

    Which_MB_Reg_Handle : process (UPDATE, config_with_scan_reset)
    begin
      if config_with_scan_reset = '1' then
        Which_MB_Reg <= (others => '0');
      elsif UPDATE'event and UPDATE = '0' then
        if SEL = '1' and data_cmd = '1' and command = MDM_WRITE_WHICH_MB then
          Which_MB_Reg <= tdi_shifter(0 to Which_MB_Reg_Size - 1);
        end if;
      end if;
    end process Which_MB_Reg_Handle;

    mb_debug_enabled_i(C_MB_DBG_PORTS-1 downto 0) <=
      Which_MB_Reg(C_MB_DBG_PORTS-1 downto 0);

  end generate More_Than_One_MB;

  Only_One_MB : if (C_MB_DBG_PORTS = 1) generate
    mb_debug_enabled_i(0) <= '1';
  end generate Only_One_MB;

  No_MB : if (C_MB_DBG_PORTS = 0) generate
    mb_debug_enabled_i(0) <= '0';
  end generate No_MB;

  MB_Debug_Enabled <= mb_debug_enabled_i;

  -----------------------------------------------------------------------------
  -- Reset Control
  -----------------------------------------------------------------------------
  Reset_Control : process (UPDATE, config_with_scan_reset)
  begin  -- process Reset_Control
    if config_with_scan_reset = '1' then
      Debug_Rst_i     <= '0';
      Debug_SYS_Rst_i <= '0';
      set_Ext_BRK     <= '0';
      Ext_NM_BRK_i    <= '0';
    elsif UPDATE'event and UPDATE = '1' then
      if command = MB_WRITE_BRK_RST_CTRL and data_cmd = '1' then
        Debug_Rst_i     <= tdi_shifter(0);
        Debug_SYS_Rst_i <= tdi_shifter(1);
        set_Ext_BRK     <= tdi_shifter(2);
        Ext_NM_BRK_i    <= tdi_shifter(3);
      end if;
    end if;
  end process Reset_Control;

  -----------------------------------------------------------------------------
  -- Execute Commands
  -----------------------------------------------------------------------------
  Debug_SYS_Rst <= Debug_SYS_Rst_i;
  Debug_Rst     <= Debug_Rst_i;
  Ext_NM_BRK    <= Ext_NM_BRK_i;
  Ext_BRK       <= ext_BRK_i;

  -----------------------------------------------------------------------------
  -- TDO Mux
  -----------------------------------------------------------------------------
  with command select
    TDO <=
      ID_TDO     when MDM_DEBUG_ID,
      uart_TDO   when UART_READ_BYTE,
      uart_TDO   when UART_READ_STATUS,
      config_TDO when MDM_READ_CONFIG,
      master_TDO when BUSM_READ_DATA,
      master_TDO when BUSM_READ_STATUS,
      compl_TDO  when MDM_READ_COMPL_STATUS,
      axis_TDO   when AXIS_READ_STATUS,
      ct_TDO     when CT_READ_STATUS,
      trace_TDO  when TRACE_READ_ADDR,
      trace_TDO  when TRACE_READ_STATUS,
      Dbg_TDO    when others;

  -----------------------------------------------------------------------------
  -- Unified Overrun and Error Detection section
  -----------------------------------------------------------------------------

  -- Completion Control (clears completion count and block):
  -- 0      Enable completion block
  Completion_Control_Register : process (UPDATE, config_with_scan_reset)
  begin
    if config_with_scan_reset = '1' then
      completion_ctrl <= (others => '0');
    elsif UPDATE'event and UPDATE = '1' then
      if command = MDM_WRITE_COMPL_CTRL and data_cmd_noblock = '1' then
        completion_ctrl <= tdi_shifter(0 to 0);
      end if;
    end if;
  end process Completion_Control_Register;

  -- Completion Status:
  -- 0-9    Command count
  -- 10     MicroBlaze instruction insert overrun
  -- 11     MicroBlaze instruction insert exception occurred
  -- 12     MicroBlaze data read overrun
  -- 13     Bus Master interface overrun
  -- 14     Bus Master interface error occurred
  -- 15     AXI Slave interface access locked
  Completion_Status_Register : process (DRCK, config_with_scan_reset) is
    variable sample   : std_logic_vector(15 downto 13);
    variable sample_1 : std_logic_vector(15 downto 10);

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of sample : variable is "TRUE";
  begin  -- process Completion_Status_Register
    if config_with_scan_reset = '1' then
      completion_status <= (others => '0');
      completion_block  <= '0';
      clear_overrun     <= '0';
      sample            := (others => '0');
      sample_1          := (others => '0');
    elsif DRCK'event and DRCK = '1' then  -- rising clock edge
      if command = MDM_READ_COMPL_STATUS and data_cmd_noblock = '1' then
        if CAPTURE = '1' then
          completion_status(sample_1'range) <= sample_1;
        elsif SHIFT = '1' then
          completion_status <= '0' & completion_status(completion_status'left downto completion_status'right + 1);
        end if;
      elsif command = MDM_WRITE_COMPL_CTRL and data_cmd_noblock = '1' then
        if CAPTURE = '1' then
          completion_status(9 downto 0) <= (others => '0');
          completion_block <= '0';
          clear_overrun    <= '1';
        end if;
      else
        -- Sample and detect status change
        if completion_ctrl(0) = '1' then
          if (sample_1(10) = '0' and mb_instr_overrun = '1') or
             (sample_1(11) = '0' and mb_instr_error   = '1') or
             (sample_1(12) = '0' and mb_data_overrun  = '1') or
             (sample_1(13) = '0' and sample(13)       = '1') or
             (sample_1(14) = '0' and sample(14)       = '1') or
             (sample_1(15) = '0' and sample(15)       = '1') then
            completion_block <= '1';
          end if;
        end if;
        sample_1(15 downto 13) := sample;
        sample_1(10) := mb_instr_overrun;
        sample_1(11) := mb_instr_error;
        sample_1(12) := mb_data_overrun;
        sample(13)   := master_overrun;
        sample(14)   := master_error;
        sample(15)   := JTAG_AXIS_Overrun;

        -- Increment command count
        if CAPTURE = '1' then
          if data_cmd = '0' and completion_block = '0' then
            completion_status(9 downto 0) <= std_logic_vector(unsigned(completion_status(9 downto 0)) + 1);
          end if;
          clear_overrun <= '0';
        end if;
      end if;
    end if;
  end process Completion_Status_Register;

  compl_TDO <= completion_status(completion_status'right);

  Write_Instr_Status : process (DRCK, config_with_scan_reset) is
    variable count : std_logic_vector(0 to 1) := "00";
  begin  -- process Write_Instr_Status
    if config_with_scan_reset = '1' then
      mb_instr_overrun <= '0';
      mb_instr_error   <= '0';
      count            := "00";
    elsif DRCK'event and DRCK = '1' then  -- rising clock edge
      if command = MB_WRITE_INSTR and data_cmd = '1' then
        if CAPTURE = '1' then
          mb_instr_overrun <= '0';
          mb_instr_error   <= '0';
          count            := "00";
        elsif shifting_Data = '1' and count(0) = '0' then
          if count(1) = '0' then
            mb_instr_overrun <= Dbg_TDO;
          end if;
          if count(1) = '1' then
            mb_instr_error <= Dbg_TDO;
          end if;
          count := std_logic_vector(unsigned(count) + 1);
        end if;
      elsif command = MDM_WRITE_COMPL_CTRL and data_cmd_noblock = '1' then
        if CAPTURE = '1' then
          mb_instr_overrun <= '0';
          mb_instr_error   <= '0';
        end if;
      end if;
    end if;
  end process Write_Instr_Status;
  
  Data_Read_Status : process (DRCK, config_with_scan_reset) is
    variable count : std_logic_vector(0 to 5) := "000000";
  begin  -- process Data_Read_Status
    if config_with_scan_reset = '1' then
      mb_data_overrun <= '0';
      count           := "000000";
    elsif DRCK'event and DRCK = '1' then  -- rising clock edge
      if command = MB_READ_DATA and data_cmd = '1' then
        if CAPTURE = '1' then
          mb_data_overrun <= '0';
          count           := "000000";
        elsif SHIFT = '1' then
          if count = "100000" then
            mb_data_overrun <= not Dbg_TDO;
          end if;
          count := std_logic_vector(unsigned(count) + 1);
        end if;
      elsif command = MDM_WRITE_COMPL_CTRL and data_cmd_noblock = '1' then
        if CAPTURE = '1' then
          mb_data_overrun <= '0';
        end if;
      end if;
    end if;
  end process Data_Read_Status;

  -----------------------------------------------------------------------------
  -- UART section
  -----------------------------------------------------------------------------

  Use_UART : if (C_USE_UART = 1) generate
    signal execute           : std_logic := '0';
    signal execute_1         : std_logic := '0';
    signal execute_2         : std_logic := '0';
    signal execute_3         : std_logic := '0';
    signal fifo_DOut         : std_logic_vector(0 to C_UART_WIDTH-1);
    signal fifo_Data_Present : std_logic := '0';
    signal fifo_Din          : std_logic_vector(0 to C_UART_WIDTH-1);
    signal fifo_Read         : std_logic := '0';
    signal fifo_Write        : std_logic := '0';
    signal rx_Buffer_Full_I  : std_logic := '0';
    signal rx_Data_Present_I : std_logic := '0';
    signal status_reg        : std_logic_vector(0 to 7) := (others => '0');
    signal tdo_reg           : std_logic_vector(0 to C_UART_WIDTH-1) := (others => '0');
    signal tx_Buffer_Full_I  : std_logic := '0';
    signal tx_buffered       : std_logic := '0';  -- Non-buffered mode on startup
    signal tx_buffered_1     : std_logic := '0';
    signal tx_buffered_2     : std_logic := '0';
    signal tx_fifo_wen       : std_logic;
    signal data_cmd_reset    : std_logic;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of execute_1     : signal is "TRUE";
    attribute ASYNC_REG of execute_2     : signal is "TRUE";
    attribute ASYNC_REG of tx_buffered_1 : signal is "TRUE";
    attribute ASYNC_REG of tx_buffered_2 : signal is "TRUE";
  begin

    Ext_BRK_FDRSE : FDRSE
      port map (
        Q  => ext_BRK_i,                  --  [out std_logic]
        C  => Clk,                        --  [in  std_logic]
        CE => '0',                        --  [in  std_logic]
        D  => '0',                        --  [in  std_logic]
        R  => Clear_Ext_BRK,              --  [in  std_logic]
        S  => set_Ext_BRK);               --  [in  std_logic]

    -----------------------------------------------------------------------------
    -- Control Register
    -----------------------------------------------------------------------------

    -- Register accessible on the JTAG interface only
    Control_Register : process (UPDATE, config_with_scan_reset)
    begin
      if config_with_scan_reset = '1' then
        tx_buffered <= '0';
      elsif UPDATE'event and UPDATE = '1' then
        if command = UART_WRITE_CONTROL and data_cmd = '1' then
          tx_buffered <= tdi_shifter(0);
        end if;
      end if;
    end process Control_Register;
  
    Tx_Buffered_DFF: process (Clk)
    begin  -- process Tx_Buffered_DFF
      if Clk'event and Clk = '1' then
        tx_buffered_2 <= tx_buffered_1;
        tx_buffered_1 <= tx_buffered;
      end if;
    end process Tx_Buffered_DFF;

    data_cmd_reset <= data_cmd when Scan_Reset_Sel = '0' else
                      not Scan_Reset;

    Execute_UART_Command : process (UPDATE, data_cmd_reset)
    begin  -- process Execute_UART_Command
      if data_cmd_reset = '0' then
        execute   <= '0';
      elsif UPDATE'event and UPDATE = '1' then
        if (command = UART_READ_BYTE)  or
           (command = UART_WRITE_BYTE) then
          execute <= '1';
        else
          execute <= '0';
        end if;
      end if;
    end process Execute_UART_Command;

    Execute_FIFO_Command : process (Clk)
    begin  -- process Execute_FIFO_Command
      if Clk'event and Clk = '1' then
        fifo_Write     <= '0';
        fifo_Read      <= '0';
        if (execute_3 = '0') and (execute_2 = '1') then
          if (command = UART_WRITE_BYTE) then
            fifo_Write <= '1';
          end if;
          if (command = UART_READ_BYTE) then
            fifo_Read  <= '1';
          end if;
        end if;
        execute_3      <= execute_2;
        execute_2      <= execute_1;
        execute_1      <= execute;
      end if;
    end process Execute_FIFO_Command;

    -- Since only one bit can change in the status register at time
    -- we don't need to synchronize them with the DRCK clock
    status_reg(7) <= fifo_Data_Present;
    status_reg(6) <= tx_Buffer_Full_I;
    status_reg(5) <= not rx_Data_Present_I;
    status_reg(4) <= rx_Buffer_Full_I;
    status_reg(3) <= '0'; -- FSL0_S_Exists;
    status_reg(2) <= '0'; -- FSL0_M_Full;
    status_reg(1) <= '0'; -- FSL_Read_UnderRun;
    status_reg(0) <= '0'; -- FSL_Write_OverRun;

    -- Read UART registers
    TDO_Register : process (DRCK, config_with_scan_reset) is
    begin  -- process TDO_Register
      if config_with_scan_reset = '1' then
        tdo_reg <= (others => '0');
      elsif DRCK'event and DRCK = '1' then  -- rising clock edge
        if (CAPTURE = '1') then
          case Command is
            when UART_READ_STATUS =>
              tdo_reg <= (others => '0');
              tdo_reg(tdo_reg'right-status_reg'length+1 to tdo_reg'right) <= status_reg;
            when others =>
              tdo_reg <= fifo_DOut;
          end case;
        elsif SHIFT = '1' then
          tdo_reg <= '0' & tdo_reg(tdo_reg'left to tdo_reg'right-1);
        end if;
      end if;
    end process TDO_Register;

    uart_TDO <= tdo_reg(tdo_reg'right);

    -----------------------------------------------------------------------------
    -- TDI Register
    -----------------------------------------------------------------------------
    TDI_Register : process (DRCK, config_with_scan_reset) is
    begin  -- process TDI_Register
      if config_with_scan_reset = '1' then
        fifo_Din <= (others => '0');
      elsif DRCK'event and DRCK = '1' then   -- rising clock edge
        if shifting_Data = '1' then
          fifo_Din(fifo_Din'left+1 to fifo_Din'right) <=
            fifo_Din(fifo_Din'left to fifo_Din'right-1);
          fifo_Din(0) <= TDI;
        end if;
      end if;
    end process TDI_Register;

    ---------------------------------------------------------------------------
    -- FIFO
    ---------------------------------------------------------------------------
    RX_FIFO_I : SRL_FIFO
      generic map (
        C_DATA_BITS => C_UART_WIDTH,                   -- [natural]
        C_DEPTH     => 16)                             -- [natural]
      port map (
        Clk         => Clk,                            -- [in  std_logic]
        Reset       => Reset_RX_FIFO,                  -- [in  std_logic]
        FIFO_Write  => fifo_Write,                     -- [in  std_logic]
        Data_In     => fifo_Din(0 to C_UART_WIDTH-1),  -- [in  std_logic_vector(0 to C_DATA_BITS-1)]
        FIFO_Read   => Read_RX_FIFO,                   -- [in  std_logic]
        Data_Out    => RX_Data,                        -- [out std_logic_vector(0 to C_DATA_BITS-1)]
        FIFO_Full   => rx_Buffer_Full_I,               -- [out std_logic]
        Data_Exists => rx_Data_Present_I);             -- [out std_logic]

    RX_Data_Present <= rx_Data_Present_I;
    RX_Buffer_Full  <= rx_Buffer_Full_I;

    -- Discard transmit data until XMD enables buffered mode.
    tx_fifo_wen <= Write_TX_FIFO and tx_buffered_2;

    TX_FIFO_I : SRL_FIFO
      generic map (
        C_DATA_BITS => C_UART_WIDTH,        -- [natural]
        C_DEPTH     => 16)                  -- [natural]
      port map (
        Clk         => Clk,                 -- [in  std_logic]
        Reset       => Reset_TX_FIFO,       -- [in  std_logic]
        FIFO_Write  => tx_fifo_wen,         -- [in  std_logic]
        Data_In     => TX_Data,             -- [in  std_logic_vector(0 to C_DATA_BITS-1)]
        FIFO_Read   => fifo_Read,           -- [in  std_logic]
        Data_Out    => fifo_DOut,           -- [out std_logic_vector(0 to C_DATA_BITS-1)]
        FIFO_Full   => TX_Buffer_Full_I,    -- [out std_logic]
        Data_Exists => fifo_Data_Present);  -- [out std_logic]

    TX_Buffer_Full  <= TX_Buffer_Full_I;
    TX_Buffer_Empty <= not fifo_Data_Present;
    
  end generate Use_UART;

  No_UART : if (C_USE_UART = 0) generate
  begin
    ext_BRK_i       <= '0';
    uart_TDO        <= '0';

    RX_Data         <= (others => '0');
    RX_Data_Present <= '0';
    RX_BUFFER_FULL  <= '0';
    TX_Buffer_Full  <= '0';
    TX_Buffer_Empty <= '1';
  end generate No_UART;

  -----------------------------------------------------------------------------
  -- Bus Master Debug Memory Access section
  -----------------------------------------------------------------------------

  Use_Dbg_Mem_Access : if (C_DBG_MEM_ACCESS = 1) generate
    signal input           : std_logic_vector(0 to C_M_AXI_DATA_WIDTH-1);
    signal output          : std_logic_vector(0 to C_M_AXI_DATA_WIDTH-1);
    signal status          : std_logic_vector(0 to 7);
    signal execute         : std_logic := '0';
    signal execute_1       : std_logic := '0';
    signal execute_2       : std_logic := '0';
    signal execute_3       : std_logic := '0';
    signal clear_overrun_1 : std_logic := '0';
    signal clear_overrun_2 : std_logic := '0';
    signal access_idle_1   : std_logic := '0';
    signal access_idle_2   : std_logic := '0';
    signal rd_wr_len       : std_logic_vector(0 to 4) := (others => '0');
    signal rd_wr_size      : std_logic_vector(0 to 1) := (others => '0');
    signal rd_wr_excl      : std_logic := '0';
    signal rd_resp_zero    : boolean;
    signal wr_resp_zero    : boolean;
    signal data_cmd_reset  : std_logic;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of execute_1       : signal is "TRUE";
    attribute ASYNC_REG of execute_2       : signal is "TRUE";
    attribute ASYNC_REG of clear_overrun_1 : signal is "TRUE";
    attribute ASYNC_REG of clear_overrun_2 : signal is "TRUE";
    attribute ASYNC_REG of access_idle_1   : signal is "TRUE";
    attribute ASYNC_REG of access_idle_2   : signal is "TRUE";
  begin

    -----------------------------------------------------------------------------
    -- Control Register
    -----------------------------------------------------------------------------
    Control_Register : process (UPDATE, config_with_scan_reset)
    begin
      if config_with_scan_reset = '1' then
        rd_wr_excl <= '0';              -- no exclusive
        rd_wr_size <= "10";             -- word size
        rd_wr_len  <= (others => '0');  -- single word burst
      elsif UPDATE'event and UPDATE = '1' then
        if command = BUSM_WRITE_CONTROL and data_cmd = '1' then
          rd_wr_excl <= tdi_shifter(0);
          rd_wr_size <= tdi_shifter(1 to 2);
          rd_wr_len  <= tdi_shifter(3 to 7);
        end if;
      end if;
    end process Control_Register;

    Master_rd_len  <= rd_wr_len;
    Master_wr_len  <= rd_wr_len;
    Master_rd_size <= rd_wr_size;
    Master_wr_size <= rd_wr_size;
    Master_rd_excl <= rd_wr_excl;
    Master_wr_excl <= rd_wr_excl;
  
    -----------------------------------------------------------------------------
    -- Command Registers
    -----------------------------------------------------------------------------
    data_cmd_reset <= data_cmd when Scan_Reset_Sel = '0' else
                      not Scan_Reset;

    Execute_Bus_Command : process (UPDATE, data_cmd_reset)
    begin  -- process Execute_Bus_Command
      if data_cmd_reset = '0' then
        execute   <= '0';
      elsif UPDATE'event and UPDATE = '1' then
        if (command = BUSM_WRITE_COMMAND) or
           (command = BUSM_READ_DATA)     or
           (command = BUSM_WRITE_DATA)    then
          execute <= '1';
        else
          execute <= '0';
        end if;
      end if;
    end process Execute_Bus_Command;

    Execute_Data_Command : process (M_AXI_ACLK)
    begin  -- process Execute_Data_Command
      if M_AXI_ACLK'event and M_AXI_ACLK = '1' then
        if M_AXI_ARESETn = '0' then
          execute_3       <= '0';
          execute_2       <= '0';
          execute_1       <= '0';
          Master_data_wr  <= '0';
          Master_data_rd  <= '0';
          Master_rd_start <= '0';
          Master_wr_start <= '0';
          master_overrun  <= '0';
          master_error    <= '0';
          clear_overrun_2 <= '0';
          clear_overrun_1 <= '0';
          rd_resp_zero    <= true;
          wr_resp_zero    <= true;
        else
          Master_data_wr  <= '0';
          Master_data_rd  <= '0';
          Master_rd_start <= '0';
          Master_wr_start <= '0';
          if (execute_3 = '0') and (execute_2 = '1') then
            if (Master_rd_idle = '1') and (Master_wr_idle = '1') then
              if (command = BUSM_WRITE_DATA) then
                Master_data_wr <= '1';
              end if;
              if (command = BUSM_READ_DATA) then
                Master_data_rd <= '1';
              end if;
              if (command = BUSM_WRITE_COMMAND) then
                Master_rd_start <= Master_data_empty;
                Master_wr_start <= not Master_data_empty;
                master_error    <= '0';
              end if;
              master_overrun <= '0';
            else
              master_overrun <= '1';
            end if;
          end if;
          execute_3   <= execute_2;
          execute_2   <= execute_1;
          execute_1   <= execute;

          if clear_overrun_2 = '1' then
            master_overrun <= '0';
            master_error   <= '0';
          end if;
          clear_overrun_2 <= clear_overrun_1;
          clear_overrun_1 <= clear_overrun;

          if (Master_rd_resp /= "00" and rd_resp_zero) or (Master_wr_resp /= "00" and wr_resp_zero) then
            master_error <= '1';
          end if;
          rd_resp_zero <= Master_rd_resp = "00";
          wr_resp_zero <= Master_wr_resp = "00";
        end if;
      end if;
    end process Execute_Data_Command;

    -----------------------------------------------------------------------------
    -- Status Register and Data Read Register
    -----------------------------------------------------------------------------

    -- We don't need to synchronize status with DRCK clock
    status(7)      <= '0';
    status(6)      <= '0';
    status(4 to 5) <= Master_rd_resp;
    status(2 to 3) <= Master_wr_resp;
    status(1)      <= Master_rd_idle;
    status(0)      <= Master_wr_idle;

    Output_Register : process (DRCK, config_with_scan_reset) is
    begin  -- process Output_Register
      if config_with_scan_reset = '1' then
        output <= (others => '0');
      elsif DRCK'event and DRCK = '1' then  -- rising clock edge
        if (CAPTURE = '1') then
          case Command is
            when BUSM_READ_STATUS =>
              output <= (others => '0');
              output(output'right-status'length+1 to output'right) <= status;
            when others =>
              output <= Master_data_out;
          end case;
        elsif SHIFT = '1' then
          output <= '0' & output(output'left to output'right-1);
        end if;
      end if;
    end process Output_Register;

    master_TDO <= output(output'right);

    -----------------------------------------------------------------------------
    -- Write Data and Read/Write Address Register
    -----------------------------------------------------------------------------
    Input_Register : process (DRCK, config_with_scan_reset) is
    begin  -- process Input_Register
      if config_with_scan_reset = '1' then
        input <= (others => '0');
        access_idle_2 <= '0';
        access_idle_1 <= '0';
      elsif DRCK'event and DRCK = '1' then  -- rising clock edge
        if shifting_Data = '1' and data_cmd = '1' and access_idle_2 = '1' and
           (command = BUSM_WRITE_DATA or command = BUSM_WRITE_COMMAND) then
          input(input'left+1 to input'right) <= input(input'left to input'right-1);
          input(0) <= TDI;
        end if;
        access_idle_2 <= access_idle_1;
        access_idle_1 <= Master_rd_idle and Master_wr_idle;
      end if;
    end process Input_Register;

    Master_rd_addr <= input;
    Master_wr_addr <= input;
    Master_data_in <= input;

  end generate Use_Dbg_Mem_Access;

  No_Dbg_Mem_Access : if (C_DBG_MEM_ACCESS = 0) generate
  begin
    master_TDO      <= '0';
    master_overrun  <= '0';
    master_error    <= '0';

    Master_rd_start <= '0';
    Master_rd_addr  <= (others => '0');
    Master_rd_len   <= (others => '0');
    Master_rd_size  <= (others => '0');
    Master_rd_excl  <= '0';
    Master_wr_start <= '0';
    Master_wr_addr  <= (others => '0');
    Master_wr_len   <= (others => '0');
    Master_wr_size  <= (others => '0');
    Master_wr_excl  <= '0';
    Master_data_rd  <= '0';
    Master_data_wr  <= '0';
    Master_data_in  <= (others => '0');
  end generate No_Dbg_Mem_Access;

  -----------------------------------------------------------------------------
  -- AXI Slave Debug Register Access section
  -----------------------------------------------------------------------------

  Use_Dbg_Reg_Access : if (C_DBG_REG_ACCESS = 1) generate
    signal access_lock          : std_logic := '0';
    signal access_lock_cmd_rst  : std_logic;
    signal dbgreg_access_lock_1 : std_logic := '0';
    signal force_lock           : std_logic := '0';
    signal force_lock_cmd_rst   : std_logic;
    signal status_reg           : std_logic_vector(0 to 1);
    signal tdo_reg              : std_logic_vector(0 to 1) := (others => '0');
  begin

    -----------------------------------------------------------------------------
    -- Handle force lock command: first set it on update and then remove after
    -- it has been detected in the other clock region
    -----------------------------------------------------------------------------

    force_lock_cmd_rst <= Config_Reset or dbgreg_unlocked when Scan_Reset_Sel = '0' else
                          Scan_Reset;

    Force_Lock_Command_Handle : process (UPDATE, force_lock_cmd_rst)
    begin  -- process Force_Lock_Command_Handle
      if force_lock_cmd_rst = '1' then
        force_lock <= '0';
      elsif UPDATE'event and UPDATE = '1' then
        if command = AXIS_WRITE_COMMAND and data_cmd = '1' then
          force_lock <= tdi_shifter(0);
        end if;
      end if;
    end process Force_Lock_Command_Handle;

    JTAG_Force_Lock <= force_lock;

    -----------------------------------------------------------------------------
    -- Handle normal lock command: set it on update if not locked by other clock
    -- region and remove if force lock by other clock region
    -----------------------------------------------------------------------------

    access_lock_cmd_rst <= Config_Reset or DbgReg_Force_Lock when Scan_Reset_Sel = '0' else
                           Scan_Reset;

    Access_Lock_Command_Handle : process (UPDATE, access_lock_cmd_rst)
    begin  -- process Access_Lock_Command_Handle
      if access_lock_cmd_rst = '1' then
        access_lock <= '0';
      elsif UPDATE'event and UPDATE = '1' then
        if command = AXIS_WRITE_COMMAND and data_cmd = '1' then
          access_lock <= tdi_shifter(1) and not dbgreg_access_lock_1;
        end if;
      end if;
    end process Access_Lock_Command_Handle;

    Sync_Access_Lock : process (DRCK, config_with_scan_reset) is
    begin  -- process Sync_Access_Lock
      if config_with_scan_reset = '1' then
        dbgreg_access_lock_1 <= '0';
      elsif DRCK'event and DRCK = '1' then  -- rising clock edge
        dbgreg_access_lock_1 <= DbgReg_Access_Lock;
      end if;
    end process Sync_Access_Lock;

    JTAG_Access_Lock <= access_lock;

    -----------------------------------------------------------------------------
    -- Read AXI Slave status register
    -----------------------------------------------------------------------------

    status_reg(1) <= access_lock;
    status_reg(0) <= dbgreg_access_lock_1;

    TDO_Register : process (DRCK, config_with_scan_reset) is
    begin  -- process TDO_Register
      if config_with_scan_reset = '1' then
        tdo_reg <= (others => '0');
      elsif DRCK'event and DRCK = '1' then  -- rising clock edge
        if CAPTURE = '1' then
          -- AXIS_READ_STATUS
          tdo_reg <= status_reg;
        elsif SHIFT = '1' then
          tdo_reg <= '0' & tdo_reg(tdo_reg'left to tdo_reg'right-1);
        end if;
      end if;
    end process TDO_Register;

    axis_TDO <= tdo_reg(tdo_reg'right);

    JTAG_Clear_Overrun <= clear_overrun;

  end generate Use_Dbg_Reg_Access;

  No_Dbg_Reg_Acess : if (C_DBG_REG_ACCESS = 0) generate
  begin
    axis_TDO <= '0';

    JTAG_Access_Lock   <= '0';
    JTAG_Force_Lock    <= '0';
    JTAG_Clear_Overrun <= '0';
  end generate No_Dbg_Reg_Acess;

  -----------------------------------------------------------------------------
  -- Cross trigger section
  -----------------------------------------------------------------------------

  Use_Cross_Trigger : if (C_USE_CROSS_TRIGGER = 1) generate
    constant C_NUM_CT : integer := C_NUM_DBG_CT + C_NUM_EXT_CT;

    type dbg_in_all_type  is array(0 to C_EN_WIDTH - 1)   of std_logic_vector(0 to C_NUM_DBG_CT - 1);
    type in_all_type      is array(0 to C_EN_WIDTH - 1)   of std_logic_vector(0 to C_NUM_CT - 1);
    type dbg_out_type     is array(0 to C_NUM_DBG_CT - 1) of std_logic_vector(0 to 3);
    type dbg_out_all_type is array(0 to C_EN_WIDTH - 1)   of dbg_out_type;
    type ext_out_type     is array(0 to C_NUM_EXT_CT - 1) of std_logic_vector(0 to 3);

    constant C_DBG_IN_CTRL    : std_logic_vector(0 to C_NUM_DBG_CT - 1) := (0 to C_NUM_EXT_CT - 1 => '1', others => '0');
    constant C_DBG_OUT_CTRL   : dbg_out_type := ("1001", "1010", "1011", "1100", "1101", "1101", "1101", "1101");
    constant C_EXT_IN_CTRL    : std_logic_vector(0 to C_NUM_EXT_CT - 1) := (others => '1');
    constant C_EXT_OUT_CTRL   : ext_out_type := ("0001", "0010", "0011", "0100");

    signal dbg_trig_in_i      : dbg_trig_type;
    signal dbg_trig_Ack_Out_i : dbg_trig_type;

    signal in_andor_ctrl      : std_logic                               := '0';
    signal in_ctrl            : dbg_in_all_type                         := (others => C_DBG_IN_CTRL);
    signal out_ctrl           : dbg_out_all_type                        := (others => C_DBG_OUT_CTRL);
    signal ext_in_ctrl        : std_logic_vector(0 to C_NUM_EXT_CT - 1) := C_EXT_IN_CTRL;
    signal ext_out_ctrl       : ext_out_type                            := C_EXT_OUT_CTRL;

    signal status_reg         : std_logic_vector(0 to C_NUM_CT * 2 - 1) := (others => '0');
    signal tdo_reg            : std_logic_vector(0 to C_NUM_CT * 2 - 1) := (others => '0');

  begin

    -----------------------------------------------------------------------------
    -- Assign trigger outputs
    -----------------------------------------------------------------------------
    Assign_Outputs: process (in_ctrl, in_andor_ctrl, ext_in_ctrl,
                             out_ctrl, ext_out_ctrl, dbg_trig_in_i, Ext_Trig_In,
                             dbg_trig_ack_out_i, Ext_Trig_Ack_Out) is
      variable in_value_or      : dbg_in_all_type;
      variable in_value_and     : dbg_in_all_type;
      variable in_value         : in_all_type;
      variable in_value_ext_or  : std_logic_vector(0 to C_NUM_DBG_CT - 1);
      variable in_value_ext_and : std_logic_vector(0 to C_NUM_DBG_CT - 1);
      variable in_value_ext     : std_logic_vector(0 to C_NUM_CT - 1);
      variable out_value        : std_logic_vector(0 to 15);
      variable out_ack_value    : std_logic_vector(0 to 15);
      variable dbg_ack_value    : dbg_in_all_type;
      variable ext_ack_value    : std_logic_vector(0 to C_NUM_EXT_CT - 1);
      variable index            : integer range 0 to 15;
    begin  -- process Assign_Outputs
      -- Determine in_value per processor from inputs and input select control registers
      for N in 0 to C_EN_WIDTH - 1 loop
        for K in 0 to C_NUM_DBG_CT - 1 loop
          in_value_or(N)(K)   := '0';
          in_value_and(N)(K)  := '1';
          for I in 0 to C_EN_WIDTH - 1 loop
            if N /= I then -- exclude own processor input
              in_value_or(N)(K)  := in_value_or(N)(K)  or  (dbg_trig_in_i(I)(K) and in_ctrl(I)(K));
              in_value_and(N)(K) := in_value_and(N)(K) and (dbg_trig_in_i(I)(K) and in_ctrl(I)(K));
            end if;
          end loop;
        end loop;
        if in_andor_ctrl = '1' then
          in_value(N)(0 to C_NUM_DBG_CT - 1) := in_value_and(N);
        else
          in_value(N)(0 to C_NUM_DBG_CT - 1) := in_value_or(N);
        end if;
        for K in 0 to C_NUM_EXT_CT - 1 loop
          in_value(N)(K + C_NUM_DBG_CT) := Ext_Trig_In(K) and ext_in_ctrl(K);
        end loop;
      end loop;

      -- Determine in_value_ext from inputs and input select control registers
      for K in 0 to C_NUM_DBG_CT - 1 loop
        in_value_ext_or(K)  := '0';
        in_value_ext_and(K) := '1';
        for I in 0 to C_EN_WIDTH - 1 loop
          in_value_ext_or(K)  := in_value_ext_or(K)  or  (dbg_trig_in_i(I)(K) and in_ctrl(I)(K));
          in_value_ext_and(K) := in_value_ext_and(K) and (dbg_trig_in_i(I)(K) and in_ctrl(I)(K));
        end loop;
        if in_andor_ctrl = '1' then
          in_value_ext(0 to C_NUM_DBG_CT - 1) := in_value_ext_and;
        else
          in_value_ext(0 to C_NUM_DBG_CT - 1) := in_value_ext_or;
        end if;
        for K in 0 to C_NUM_EXT_CT - 1 loop
          in_value_ext(K + C_NUM_DBG_CT) := Ext_Trig_In(K) and ext_in_ctrl(K);
        end loop;
      end loop;

      -- Assign outputs from out_value based on out_ctrl control register
      dbg_trig_out_i <= (others => (others => '0'));
      for N in 0 to C_EN_WIDTH - 1 loop
        out_value := '1' & in_value(N) & "000";  -- 0000: constant 1, N=K: constant 0
        for K in 0 to C_NUM_DBG_CT - 1 loop
          index := to_integer(unsigned(out_ctrl(N)(K)));
          dbg_trig_out_i(N)(K) <= out_value(index);
        end loop;
      end loop;

      -- Assign external outputs from in_value based on ext_out_ctrl control register
      ext_trig_out_i <= (others => '0');
      out_value := '1' & in_value_ext & "000";  -- 0000: constant 1, 1101: constant 0
      for K in 0 to C_NUM_EXT_CT - 1 loop
        index := to_integer(unsigned(ext_out_ctrl(K)));
        ext_trig_out_i(K) <= out_value(index);
      end loop;

      -- Assign dbg_trig_ack_in_i from dbg_ack_value and Ext_Trig_Ack_Out
      -- Create combined acknowledge from all processors and external trig
      dbg_ack_value := (others => (others => '0'));
      dbg_trig_ack_in_i <= (others => (others => '0'));
      for K in 0 to C_NUM_DBG_CT - 1 loop
        for N in 0 to C_EN_WIDTH - 1 loop
          index := to_integer(unsigned(out_ctrl(N)(K)));
          out_ack_value := '0' & dbg_trig_ack_out_i(N) & Ext_Trig_Ack_Out & "000";
          dbg_ack_value(N)(K) := dbg_ack_value(N)(K) or out_ack_value(index);
        end loop;
      end loop;
      for K in 0 to C_NUM_DBG_CT - 1 loop
        for N in 0 to C_EN_WIDTH - 1 loop
          dbg_trig_ack_in_i(N)(K) <= dbg_ack_value(N)(K) and in_ctrl(N)(K);
        end loop;
      end loop;

      -- Assign ext_trig_ack_in_i from dbg_ack_value and Ext_Trig_Ack_Out
      -- Create combined acknowledge from all processors and external trig
      ext_ack_value := (others => '0');
      ext_trig_ack_in_i <= (others => '0');
      for K in 0 to C_NUM_EXT_CT - 1 loop
        index := to_integer(unsigned(ext_out_ctrl(K)));
        for N in 0 to C_EN_WIDTH - 1 loop
          out_ack_value := '0' & dbg_trig_ack_out_i(N) & Ext_Trig_Ack_Out & "000";
          ext_ack_value(K) := ext_ack_value(K) or out_ack_value(index);
        end loop;
      end loop;
      for K in 0 to C_NUM_EXT_CT - 1 loop
        ext_trig_ack_in_i(K) <= ext_ack_value(K) and ext_in_ctrl(K);
      end loop;
    end process Assign_Outputs;

    -----------------------------------------------------------------------------
    -- Control Registers:
    -- 4 output select + 8 input mask + and/or + 3 (index 0-7) = 16
    -- 4 output select + 4 input mask          + 2 (index 0-3) = 10
    -----------------------------------------------------------------------------

    Control_Registers : process (UPDATE, config_with_scan_reset)
      variable dbg_index : std_logic_vector(0 to 2);
      variable ext_index : std_logic_vector(0 to 1);
      variable K         : integer;
    begin
      if config_with_scan_reset = '1' then
        in_andor_ctrl <= '0';
        in_ctrl       <= (others => C_DBG_IN_CTRL);
        out_ctrl      <= (others => C_DBG_OUT_CTRL);
        ext_in_ctrl   <= C_EXT_IN_CTRL;
        ext_out_ctrl  <= C_EXT_OUT_CTRL;
      elsif UPDATE'event and UPDATE = '1' then
        if data_cmd = '1' then
          if command = CT_WRITE_CTRL and data_cmd = '1' then
            dbg_index := tdi_shifter(4 + C_NUM_DBG_CT + 1 to 4 + C_NUM_DBG_CT + 1 + 2);
            K := to_integer(unsigned(dbg_index));
            for I in 0 to C_EN_WIDTH - 1 loop
              if mb_debug_enabled_i(I) = '1' then
                out_ctrl(I)(K) <= tdi_shifter(0 to 3);
                in_ctrl(I)     <= tdi_shifter(4 to 4 + C_NUM_DBG_CT - 1);
              end if;
            end loop;
            in_andor_ctrl <= tdi_shifter(4 + C_NUM_DBG_CT);
          end if;
          if command = CT_WRITE_EXT_CTRL and data_cmd = '1' then
            ext_index := tdi_shifter(4 + C_NUM_EXT_CT to 4 + C_NUM_EXT_CT + 1);
            K := to_integer(unsigned(ext_index));
            ext_out_ctrl(K) <= tdi_shifter(0 to 3);
            ext_in_ctrl     <= tdi_shifter(4 to 4 + C_NUM_EXT_CT - 1);
          end if;
        end if;
      end if;
    end process Control_Registers;

    -----------------------------------------------------------------------------
    -- Status Register
    -----------------------------------------------------------------------------

    Assign_Status: process (dbg_trig_out_i, ext_trig_out_i, dbg_trig_in_i, Ext_Trig_In, mb_debug_enabled_i) is
    begin  -- process Assign_Status
      status_reg <= (others => '0');
      for I in 0 to C_EN_WIDTH - 1 loop
        if mb_debug_enabled_i(I) = '1' then
          status_reg(0 to C_NUM_DBG_CT * 2 - 1) <= dbg_trig_out_i(I) & dbg_trig_in_i(I);
        end if;
      end loop;
      status_reg(C_NUM_DBG_CT * 2 to C_NUM_CT * 2 - 1) <= ext_trig_out_i & Ext_Trig_In;
    end process Assign_Status;

    TDO_Register : process (DRCK, config_with_scan_reset) is
    begin  -- process TDO_Register
      if config_with_scan_reset = '1' then
        tdo_reg <= (others => '0');
      elsif DRCK'event and DRCK = '1' then  -- rising clock edge
        if (CAPTURE = '1') then
          -- CT_READ_STATUS
          tdo_reg <= status_reg;
        elsif SHIFT = '1' then
          tdo_reg <= '0' & tdo_reg(tdo_reg'left to tdo_reg'right-1);
        end if;
      end if;
    end process TDO_Register;

    ct_TDO <= tdo_reg(tdo_reg'right);

    dbg_trig_in_i(0)  <= Dbg_Trig_In_0;
    dbg_trig_in_i(1)  <= Dbg_Trig_In_1;
    dbg_trig_in_i(2)  <= Dbg_Trig_In_2;
    dbg_trig_in_i(3)  <= Dbg_Trig_In_3;
    dbg_trig_in_i(4)  <= Dbg_Trig_In_4;
    dbg_trig_in_i(5)  <= Dbg_Trig_In_5;
    dbg_trig_in_i(6)  <= Dbg_Trig_In_6;
    dbg_trig_in_i(7)  <= Dbg_Trig_In_7;
    dbg_trig_in_i(8)  <= Dbg_Trig_In_8;
    dbg_trig_in_i(9)  <= Dbg_Trig_In_9;
    dbg_trig_in_i(10) <= Dbg_Trig_In_10;
    dbg_trig_in_i(11) <= Dbg_Trig_In_11;
    dbg_trig_in_i(12) <= Dbg_Trig_In_12;
    dbg_trig_in_i(13) <= Dbg_Trig_In_13;
    dbg_trig_in_i(14) <= Dbg_Trig_In_14;
    dbg_trig_in_i(15) <= Dbg_Trig_In_15;
    dbg_trig_in_i(16) <= Dbg_Trig_In_16;
    dbg_trig_in_i(17) <= Dbg_Trig_In_17;
    dbg_trig_in_i(18) <= Dbg_Trig_In_18;
    dbg_trig_in_i(19) <= Dbg_Trig_In_19;
    dbg_trig_in_i(20) <= Dbg_Trig_In_20;
    dbg_trig_in_i(21) <= Dbg_Trig_In_21;
    dbg_trig_in_i(22) <= Dbg_Trig_In_22;
    dbg_trig_in_i(23) <= Dbg_Trig_In_23;
    dbg_trig_in_i(24) <= Dbg_Trig_In_24;
    dbg_trig_in_i(25) <= Dbg_Trig_In_25;
    dbg_trig_in_i(26) <= Dbg_Trig_In_26;
    dbg_trig_in_i(27) <= Dbg_Trig_In_27;
    dbg_trig_in_i(28) <= Dbg_Trig_In_28;
    dbg_trig_in_i(29) <= Dbg_Trig_In_29;
    dbg_trig_in_i(30) <= Dbg_Trig_In_30;
    dbg_trig_in_i(31) <= Dbg_Trig_In_31;

    dbg_trig_ack_out_i(0)  <= Dbg_Trig_Ack_Out_0;
    dbg_trig_ack_out_i(1)  <= Dbg_Trig_Ack_Out_1;
    dbg_trig_ack_out_i(2)  <= Dbg_Trig_Ack_Out_2;
    dbg_trig_ack_out_i(3)  <= Dbg_Trig_Ack_Out_3;
    dbg_trig_ack_out_i(4)  <= Dbg_Trig_Ack_Out_4;
    dbg_trig_ack_out_i(5)  <= Dbg_Trig_Ack_Out_5;
    dbg_trig_ack_out_i(6)  <= Dbg_Trig_Ack_Out_6;
    dbg_trig_ack_out_i(7)  <= Dbg_Trig_Ack_Out_7;
    dbg_trig_ack_out_i(8)  <= Dbg_Trig_Ack_Out_8;
    dbg_trig_ack_out_i(9)  <= Dbg_Trig_Ack_Out_9;
    dbg_trig_ack_out_i(10) <= Dbg_Trig_Ack_Out_10;
    dbg_trig_ack_out_i(11) <= Dbg_Trig_Ack_Out_11;
    dbg_trig_ack_out_i(12) <= Dbg_Trig_Ack_Out_12;
    dbg_trig_ack_out_i(13) <= Dbg_Trig_Ack_Out_13;
    dbg_trig_ack_out_i(14) <= Dbg_Trig_Ack_Out_14;
    dbg_trig_ack_out_i(15) <= Dbg_Trig_Ack_Out_15;
    dbg_trig_ack_out_i(16) <= Dbg_Trig_Ack_Out_16;
    dbg_trig_ack_out_i(17) <= Dbg_Trig_Ack_Out_17;
    dbg_trig_ack_out_i(18) <= Dbg_Trig_Ack_Out_18;
    dbg_trig_ack_out_i(19) <= Dbg_Trig_Ack_Out_19;
    dbg_trig_ack_out_i(20) <= Dbg_Trig_Ack_Out_20;
    dbg_trig_ack_out_i(21) <= Dbg_Trig_Ack_Out_21;
    dbg_trig_ack_out_i(22) <= Dbg_Trig_Ack_Out_22;
    dbg_trig_ack_out_i(23) <= Dbg_Trig_Ack_Out_23;
    dbg_trig_ack_out_i(24) <= Dbg_Trig_Ack_Out_24;
    dbg_trig_ack_out_i(25) <= Dbg_Trig_Ack_Out_25;
    dbg_trig_ack_out_i(26) <= Dbg_Trig_Ack_Out_26;
    dbg_trig_ack_out_i(27) <= Dbg_Trig_Ack_Out_27;
    dbg_trig_ack_out_i(28) <= Dbg_Trig_Ack_Out_28;
    dbg_trig_ack_out_i(29) <= Dbg_Trig_Ack_Out_29;
    dbg_trig_ack_out_i(30) <= Dbg_Trig_Ack_Out_30;
    dbg_trig_ack_out_i(31) <= Dbg_Trig_Ack_Out_31;
  end generate Use_Cross_Trigger;

  No_Cross_Trigger : if (C_USE_CROSS_TRIGGER = 0) generate
  begin
    dbg_trig_ack_in_i <= (others => (others => '0'));
    dbg_trig_out_i    <= (others => (others => '0'));
    ext_trig_ack_in_i <= (others => '0');
    ext_trig_out_i    <= (others => '0');

    ct_TDO <= '0';
  end generate No_Cross_Trigger;

  Dbg_Trig_Ack_In_0  <= dbg_trig_ack_in_i(0);
  Dbg_Trig_Ack_In_1  <= dbg_trig_ack_in_i(1);
  Dbg_Trig_Ack_In_2  <= dbg_trig_ack_in_i(2);
  Dbg_Trig_Ack_In_3  <= dbg_trig_ack_in_i(3);
  Dbg_Trig_Ack_In_4  <= dbg_trig_ack_in_i(4);
  Dbg_Trig_Ack_In_5  <= dbg_trig_ack_in_i(5);
  Dbg_Trig_Ack_In_6  <= dbg_trig_ack_in_i(6);
  Dbg_Trig_Ack_In_7  <= dbg_trig_ack_in_i(7);
  Dbg_Trig_Ack_In_8  <= dbg_trig_ack_in_i(8);
  Dbg_Trig_Ack_In_9  <= dbg_trig_ack_in_i(9);
  Dbg_Trig_Ack_In_10 <= dbg_trig_ack_in_i(10);
  Dbg_Trig_Ack_In_11 <= dbg_trig_ack_in_i(11);
  Dbg_Trig_Ack_In_12 <= dbg_trig_ack_in_i(12);
  Dbg_Trig_Ack_In_13 <= dbg_trig_ack_in_i(13);
  Dbg_Trig_Ack_In_14 <= dbg_trig_ack_in_i(14);
  Dbg_Trig_Ack_In_15 <= dbg_trig_ack_in_i(15);
  Dbg_Trig_Ack_In_16 <= dbg_trig_ack_in_i(16);
  Dbg_Trig_Ack_In_17 <= dbg_trig_ack_in_i(17);
  Dbg_Trig_Ack_In_18 <= dbg_trig_ack_in_i(18);
  Dbg_Trig_Ack_In_19 <= dbg_trig_ack_in_i(19);
  Dbg_Trig_Ack_In_20 <= dbg_trig_ack_in_i(20);
  Dbg_Trig_Ack_In_21 <= dbg_trig_ack_in_i(21);
  Dbg_Trig_Ack_In_22 <= dbg_trig_ack_in_i(22);
  Dbg_Trig_Ack_In_23 <= dbg_trig_ack_in_i(23);
  Dbg_Trig_Ack_In_24 <= dbg_trig_ack_in_i(24);
  Dbg_Trig_Ack_In_25 <= dbg_trig_ack_in_i(25);
  Dbg_Trig_Ack_In_26 <= dbg_trig_ack_in_i(26);
  Dbg_Trig_Ack_In_27 <= dbg_trig_ack_in_i(27);
  Dbg_Trig_Ack_In_28 <= dbg_trig_ack_in_i(28);
  Dbg_Trig_Ack_In_29 <= dbg_trig_ack_in_i(29);
  Dbg_Trig_Ack_In_30 <= dbg_trig_ack_in_i(30);
  Dbg_Trig_Ack_In_31 <= dbg_trig_ack_in_i(31);

  Dbg_Trig_Out_0     <= dbg_trig_out_i(0);
  Dbg_Trig_Out_1     <= dbg_trig_out_i(1);
  Dbg_Trig_Out_2     <= dbg_trig_out_i(2);
  Dbg_Trig_Out_3     <= dbg_trig_out_i(3);
  Dbg_Trig_Out_4     <= dbg_trig_out_i(4);
  Dbg_Trig_Out_5     <= dbg_trig_out_i(5);
  Dbg_Trig_Out_6     <= dbg_trig_out_i(6);
  Dbg_Trig_Out_7     <= dbg_trig_out_i(7);
  Dbg_Trig_Out_8     <= dbg_trig_out_i(8);
  Dbg_Trig_Out_9     <= dbg_trig_out_i(9);
  Dbg_Trig_Out_10    <= dbg_trig_out_i(10);
  Dbg_Trig_Out_11    <= dbg_trig_out_i(11);
  Dbg_Trig_Out_12    <= dbg_trig_out_i(12);
  Dbg_Trig_Out_13    <= dbg_trig_out_i(13);
  Dbg_Trig_Out_14    <= dbg_trig_out_i(14);
  Dbg_Trig_Out_15    <= dbg_trig_out_i(15);
  Dbg_Trig_Out_16    <= dbg_trig_out_i(16);
  Dbg_Trig_Out_17    <= dbg_trig_out_i(17);
  Dbg_Trig_Out_18    <= dbg_trig_out_i(18);
  Dbg_Trig_Out_19    <= dbg_trig_out_i(19);
  Dbg_Trig_Out_20    <= dbg_trig_out_i(20);
  Dbg_Trig_Out_21    <= dbg_trig_out_i(21);
  Dbg_Trig_Out_22    <= dbg_trig_out_i(22);
  Dbg_Trig_Out_23    <= dbg_trig_out_i(23);
  Dbg_Trig_Out_24    <= dbg_trig_out_i(24);
  Dbg_Trig_Out_25    <= dbg_trig_out_i(25);
  Dbg_Trig_Out_26    <= dbg_trig_out_i(26);
  Dbg_Trig_Out_27    <= dbg_trig_out_i(27);
  Dbg_Trig_Out_28    <= dbg_trig_out_i(28);
  Dbg_Trig_Out_29    <= dbg_trig_out_i(29);
  Dbg_Trig_Out_30    <= dbg_trig_out_i(30);
  Dbg_Trig_Out_31    <= dbg_trig_out_i(31);

  Ext_Trig_Ack_In    <= ext_trig_ack_in_i;
  Ext_Trig_Out       <= ext_trig_out_i;

  -----------------------------------------------------------------------------
  -- Trace section (external, AXI stream, AXI master)
  -----------------------------------------------------------------------------

  Use_Trace_External : if (C_TRACE_OUTPUT = 1) generate
    signal test_pattern     : std_logic_vector(0 to 3) := (others => '0');
    signal test_timed       : std_logic := '0';
    signal test_cont        : std_logic := '0';
    signal delay            : std_logic_vector(0 to 7) := (others => '0');
    signal new_test_pattern : std_logic_vector(0 to 3) := (others => '0');
    signal new_test_start   : std_logic := '0';
    signal new_test_stop    : std_logic := '0';
    signal new_test_timed   : std_logic := '0';
    signal new_delay        : std_logic_vector(0 to 7) := (others => '0');
    signal trace_stopped_i  : std_logic := '0';
    signal execute          : std_logic := '0';
    signal execute_1        : std_logic := '0';
    signal execute_2        : std_logic := '0';
    signal execute_3        : std_logic := '0';
    signal data_cmd_reset   : std_logic;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of execute_1       : signal is "TRUE";
    attribute ASYNC_REG of execute_2       : signal is "TRUE";
  begin

    -----------------------------------------------------------------------------
    -- Control Register (14 bits)
    -----------------------------------------------------------------------------
    Control_Register : process (UPDATE, config_with_scan_reset)
    begin
      if config_with_scan_reset = '1' then
        test_pattern <= "0000";           -- no test pattern
        test_timed   <= '0';              -- no timed test pattern
        test_cont    <= '0';              -- no continuous test pattern
        delay        <= (others => '0');  -- no delay
      elsif UPDATE'event and UPDATE = '1' then
        if command = TRACE_WRITE_CONTROL and data_cmd = '1' then
          test_pattern <= tdi_shifter(0 to 3);
          test_timed   <= tdi_shifter(4);
          test_cont    <= tdi_shifter(5);
          delay        <= tdi_shifter(6 to 13);
        end if;
      end if;
    end process Control_Register;

    data_cmd_reset <= data_cmd when Scan_Reset_Sel = '0' else
                      not Scan_Reset;

    Execute_Command : process (UPDATE, data_cmd_reset)
    begin  -- process Execute_Command
      if data_cmd_reset = '0' then
        execute   <= '0';
      elsif UPDATE'event and UPDATE = '1' then
        if command = TRACE_WRITE_CONTROL then
          execute <= '1';
        else
          execute <= '0';
        end if;
      end if;
    end process Execute_Command;

    Execute_Test_Command : process (Trace_Clk)
    begin  -- process Execute_Test_Command
      if Trace_Clk'event and Trace_Clk = '1' then
        if Trace_Reset = '1' then
          execute_3     <= '0';
          execute_2     <= '0';
          execute_1     <= '0';
        else
          if (execute_3 = '0') and (execute_2 = '1') then
            -- Execute test
            new_test_pattern <= test_pattern;
            new_test_start   <= test_cont or test_timed;
            new_test_stop    <= not (test_cont or test_timed);
            new_test_timed   <= test_timed;
            new_delay        <= delay;
            trace_stopped_i  <= test_cont or test_timed;
          else
            new_test_start   <= '0';
            new_test_stop    <= '0';
          end if;
          execute_3 <= execute_2;
          execute_2 <= execute_1;
          execute_1 <= execute;
        end if;
      end if;
    end process Execute_Test_Command;

    Trace_Test_Pattern <= new_test_pattern;
    Trace_Test_Start   <= new_test_start;
    Trace_Test_Stop    <= new_test_stop;
    Trace_Test_Timed   <= new_test_timed;
    Trace_Delay        <= new_delay;
    Trace_Stopped      <= trace_stopped_i;

    -- Unused
    Master_dwr_addr    <= (others => '0');
    Master_dwr_len     <= (others => '0');
    trace_TDO          <= '0';
  end generate Use_Trace_External;

  Use_Trace_AXI_Stream : if (C_TRACE_OUTPUT = 2) generate
    signal delay : std_logic_vector(0 to 7) := (others => '0');
  begin

    -----------------------------------------------------------------------------
    -- Control Register (8 bits)
    -----------------------------------------------------------------------------
    Control_Register : process (UPDATE, config_with_scan_reset)
    begin
      if config_with_scan_reset = '1' then
        delay <= (others => '0');  -- no delay
      elsif UPDATE'event and UPDATE = '1' then
        if command = TRACE_WRITE_CONTROL and data_cmd = '1' then
          delay <= tdi_shifter(0 to 7);
        end if;
      end if;
    end process Control_Register;

    Trace_Delay        <= delay;

    -- Unused
    Trace_Test_Pattern <= (others => '0');
    Trace_Test_Start   <= '0';
    Trace_Test_Stop    <= '0';
    Trace_Test_Timed   <= '0';
    Trace_Stopped      <= '0';
    Master_dwr_addr    <= (others => '0');
    Master_dwr_len     <= (others => '0');
    trace_TDO          <= '0';
  end generate Use_Trace_AXI_Stream;

  Use_Trace_AXI_Master : if (C_TRACE_OUTPUT = 3) generate
    constant C_BURST_LEN  : integer := 4;  -- Burst length 4 - Packet size 4*5 = 20

    signal full_stop      : std_logic := '0';
    signal wrap           : std_logic;
    signal wr_resp        : std_logic_vector(0 to 1);
    signal output         : std_logic_vector(0 to 31);
    signal status         : std_logic_vector(0 to 2);
    signal low_addr       : std_logic_vector(0 to 15) := (others => '0');
    signal high_addr      : std_logic_vector(0 to 15) := (others => '0');
    signal execute        : std_logic := '0';
    signal execute_1      : std_logic := '0';
    signal execute_2      : std_logic := '0';
    signal execute_3      : std_logic := '0';
    signal current_addr   : std_logic_vector(0 to 29);
    signal next_addr      : std_logic_vector(0 to 29);
    signal data_cmd_reset : std_logic;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of execute_1       : signal is "TRUE";
    attribute ASYNC_REG of execute_2       : signal is "TRUE";
  begin

    -----------------------------------------------------------------------------
    -- Control Register (1 bit)
    -----------------------------------------------------------------------------
    Control_Register : process (UPDATE, config_with_scan_reset)
    begin
      if config_with_scan_reset = '1' then
        full_stop <= '0';  -- no stop when full
      elsif UPDATE'event and UPDATE = '1' then
        if command = TRACE_WRITE_CONTROL and data_cmd = '1' then
          full_stop <= tdi_shifter(0);
        end if;
      end if;
    end process Control_Register;

    -- Unused
    Trace_Test_Pattern <= (others => '0');
    Trace_Test_Start   <= '0';
    Trace_Test_Stop    <= '0';
    Trace_Test_Timed   <= '0';
    Trace_Delay        <= (others => '0');

    -----------------------------------------------------------------------------
    -- Status Register
    -----------------------------------------------------------------------------

    -- We don't need to synchronize status with DRCK clock
    status(0)      <= wrap;
    status(1 to 2) <= wr_resp;

    Output_Register : process (DRCK, config_with_scan_reset) is
    begin  -- process Output_Register
      if config_with_scan_reset = '1' then
        output <= (others => '0');
      elsif DRCK'event and DRCK = '1' then  -- rising clock edge
        if (CAPTURE = '1') then
          case Command is
            when TRACE_READ_STATUS =>
              output <= (others => '0');
              output(output'right-status'length+1 to output'right) <= status;
            when others =>
              output <= current_addr & "00";
          end case;
        elsif SHIFT = '1' then
          output <= '0' & output(output'left to output'right-1);
        end if;
      end if;
    end process Output_Register;

    trace_TDO <= output(output'right);

    -----------------------------------------------------------------------------
    -- Low and High Address Registers
    -----------------------------------------------------------------------------
    Address_Registers : process (UPDATE, config_with_scan_reset) is
    begin  -- process Address_Registers
      if config_with_scan_reset = '1' then
        low_addr  <= (others => '0');
        high_addr <= (others => '0');
      elsif UPDATE'event and UPDATE = '1' then
        if data_cmd = '1' then
          if command = TRACE_WRITE_LOW_ADDR then
            low_addr <= tdi_shifter(0 to 15);
          end if;
          if command = TRACE_WRITE_HIGH_ADDR then
            high_addr <= tdi_shifter(0 to 15);
          end if;
        end if;
      end if;
    end process Address_Registers;

    -----------------------------------------------------------------------------
    -- Handle current address and status
    -----------------------------------------------------------------------------
    data_cmd_reset <= data_cmd when Scan_Reset_Sel = '0' else
                      not Scan_Reset;

    Execute_Command : process (UPDATE, data_cmd_reset)
    begin  -- process Execute_Command
      if data_cmd_reset = '0' then
        execute   <= '0';
      elsif UPDATE'event and UPDATE = '1' then
        if command = TRACE_WRITE_CONTROL then
          execute <= '1';
        else
          execute <= '0';
        end if;
      end if;
    end process Execute_Command;

    Execute_Addr_Status_Command : process (M_AXI_ACLK)
    begin  -- process Execute_Addr_Status_Command
      if M_AXI_ACLK'event and M_AXI_ACLK = '1' then
        if M_AXI_ARESETn = '0' then
          execute_3     <= '0';
          execute_2     <= '0';
          execute_1     <= '0';
          wrap          <= '0';
          wr_resp       <= (others => '0');
          current_addr  <= (others => '0');
          Trace_Stopped <= '0';
        else
          if (execute_3 = '0') and (execute_2 = '1') then
            -- Reset current address and clear status
            wrap          <= '0';
            wr_resp       <= (others => '0');
            current_addr  <= low_addr & (16 to 29 => '0');
            Trace_Stopped <= '0';
          else
            -- Increment current address and set sticky response status after each write
            if Master_dwr_done = '1' then
              if wr_resp = "00" then
                wr_resp <= Master_dwr_resp;
              end if;
              current_addr <= next_addr;
            end if;
            -- Stop trace or wrap if buffer full
            if current_addr(0 to 15) = high_addr and current_addr(16 to 25) = (16 to 25 => '1') then
              if full_stop = '1' then
                Trace_Stopped <= '1';
              else
                wrap          <= '1';
                current_addr  <= low_addr & (16 to 29 => '0');
              end if;
            end if;
          end if;
          execute_3 <= execute_2;
          execute_2 <= execute_1;
          execute_1 <= execute;
        end if;
      end if;
    end process Execute_Addr_Status_Command;

    next_addr <= std_logic_vector(unsigned(current_addr) + C_BURST_LEN);

    Master_dwr_addr <= current_addr & "00";
    Master_dwr_len  <= std_logic_vector(to_unsigned(C_BURST_LEN - 1, 5));

  end generate Use_Trace_AXI_Master;

  No_Trace : if (C_TRACE_OUTPUT = 0) generate
  begin
    Trace_Test_Pattern <= (others => '0');
    Trace_Test_Start   <= '0';
    Trace_Test_Stop    <= '0';
    Trace_Test_Timed   <= '0';
    Trace_Delay        <= (others => '0');
    Trace_Stopped      <= '0';

    Master_dwr_addr    <= (others => '0');
    Master_dwr_len     <= (others => '0');

    trace_TDO          <= '0';
  end generate No_Trace;

end architecture IMP;
