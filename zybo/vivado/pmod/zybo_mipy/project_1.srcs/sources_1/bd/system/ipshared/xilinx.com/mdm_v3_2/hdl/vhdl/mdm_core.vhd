-------------------------------------------------------------------------------
-- mdm_core.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2003-2014 Xilinx, Inc. All rights reserved.
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
-- Filename:        mdm_core.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              mdm_core.vhd
--                jtag_control.vhd
--                arbiter.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
--
-- History:
--   goran   2003-02-13    First Version
--   stefana 2012-03-16    Added support for 32 processors and external BSCAN
--   stefana 2012-12-14    Removed legacy interfaces
--   stefana 2013-11-01    Added extended debug: debug register access, debug
--                         memory access, cross trigger support
--   stefana 2014-04-30    Added external trace support
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
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
entity MDM_Core is

  generic (
    C_JTAG_CHAIN          : integer;
    C_USE_BSCAN           : integer;
    C_USE_CONFIG_RESET    : integer := 0;
    C_BASEADDR            : std_logic_vector(0 to 31);
    C_HIGHADDR            : std_logic_vector(0 to 31);
    C_MB_DBG_PORTS        : integer;
    C_EN_WIDTH            : integer;
    C_DBG_REG_ACCESS      : integer;
    C_REG_NUM_CE          : integer;
    C_REG_DATA_WIDTH      : integer;
    C_DBG_MEM_ACCESS      : integer;
    C_S_AXI_ACLK_FREQ_HZ  : integer;
    C_M_AXI_ADDR_WIDTH    : integer;
    C_M_AXI_DATA_WIDTH    : integer;
    C_USE_CROSS_TRIGGER   : integer;
    C_USE_UART            : integer;
    C_UART_WIDTH          : integer := 8;
    C_TRACE_OUTPUT        : integer;
    C_TRACE_DATA_WIDTH    : integer;
    C_TRACE_CLK_FREQ_HZ   : integer;
    C_TRACE_CLK_OUT_PHASE : integer;
    C_M_AXIS_DATA_WIDTH   : integer;
    C_M_AXIS_ID_WIDTH     : integer
  );

  port (
    -- Global signals
    Config_Reset    : in std_logic;
    Scan_Reset_Sel  : in std_logic;
    Scan_Reset      : in std_logic;

    M_AXIS_ACLK     : in std_logic;
    M_AXIS_ARESETN  : in std_logic;

    Interrupt       : out std_logic;
    Ext_BRK         : out std_logic;
    Ext_NM_BRK      : out std_logic;
    Debug_SYS_Rst   : out std_logic;

    -- Debug Register Access signals
    DbgReg_DRCK   : out std_logic;
    DbgReg_UPDATE : out std_logic;
    DbgReg_Select : out std_logic;
    JTAG_Busy     : in  std_logic;

    -- IPIC signals
    bus2ip_clk    : in  std_logic;
    bus2ip_resetn : in  std_logic;
    bus2ip_data   : in  std_logic_vector(C_REG_DATA_WIDTH-1 downto 0);
    bus2ip_rdce   : in  std_logic_vector(0 to C_REG_NUM_CE-1);
    bus2ip_wrce   : in  std_logic_vector(0 to C_REG_NUM_CE-1);
    bus2ip_cs     : in  std_logic;
    ip2bus_rdack  : out std_logic;
    ip2bus_wrack  : out std_logic;
    ip2bus_error  : out std_logic;
    ip2bus_data   : out std_logic_vector(C_REG_DATA_WIDTH-1 downto 0);

    -- Bus Master signals
    MB_Debug_Enabled   : out std_logic_vector(C_EN_WIDTH-1 downto 0);

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
    Master_dwr_data    : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
    Master_dwr_start   : out std_logic;
    Master_dwr_next    : in  std_logic;
    Master_dwr_done    : in  std_logic;
    Master_dwr_resp    : in  std_logic_vector(1 downto 0);

    -- JTAG signals
    JTAG_TDI     : in  std_logic;
    JTAG_RESET   : in  std_logic;
    UPDATE       : in  std_logic;
    JTAG_SHIFT   : in  std_logic;
    JTAG_CAPTURE : in  std_logic;
    SEL          : in  std_logic;
    DRCK         : in  std_logic;
    JTAG_TDO     : out std_logic;

    -- External Trace AXI Stream output
    M_AXIS_TDATA       : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
    M_AXIS_TID         : out std_logic_vector(C_M_AXIS_ID_WIDTH-1 downto 0);
    M_AXIS_TREADY      : in  std_logic;
    M_AXIS_TVALID      : out std_logic;

    -- External Trace output
    TRACE_CLK_OUT      : out std_logic;
    TRACE_CLK          : in  std_logic;
    TRACE_CTL          : out std_logic;
    TRACE_DATA         : out std_logic_vector(C_TRACE_DATA_WIDTH-1 downto 0);

    -- MicroBlaze Debug Signals
    Dbg_Clk_0          : out std_logic;
    Dbg_TDI_0          : out std_logic;
    Dbg_TDO_0          : in  std_logic;
    Dbg_Reg_En_0       : out std_logic_vector(0 to 7);
    Dbg_Capture_0      : out std_logic;
    Dbg_Shift_0        : out std_logic;
    Dbg_Update_0       : out std_logic;
    Dbg_Rst_0          : out std_logic;
    Dbg_Trig_In_0      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_0  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_0     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_0 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_0        : out std_logic;
    Dbg_TrData_0       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_0      : out std_logic;
    Dbg_TrValid_0      : in  std_logic;

    Dbg_Clk_1          : out std_logic;
    Dbg_TDI_1          : out std_logic;
    Dbg_TDO_1          : in  std_logic;
    Dbg_Reg_En_1       : out std_logic_vector(0 to 7);
    Dbg_Capture_1      : out std_logic;
    Dbg_Shift_1        : out std_logic;
    Dbg_Update_1       : out std_logic;
    Dbg_Rst_1          : out std_logic;
    Dbg_Trig_In_1      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_1  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_1     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_1 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_1        : out std_logic;
    Dbg_TrData_1       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_1      : out std_logic;
    Dbg_TrValid_1      : in  std_logic;

    Dbg_Clk_2          : out std_logic;
    Dbg_TDI_2          : out std_logic;
    Dbg_TDO_2          : in  std_logic;
    Dbg_Reg_En_2       : out std_logic_vector(0 to 7);
    Dbg_Capture_2      : out std_logic;
    Dbg_Shift_2        : out std_logic;
    Dbg_Update_2       : out std_logic;
    Dbg_Rst_2          : out std_logic;
    Dbg_Trig_In_2      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_2  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_2     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_2 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_2        : out std_logic;
    Dbg_TrData_2       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_2      : out std_logic;
    Dbg_TrValid_2      : in  std_logic;

    Dbg_Clk_3          : out std_logic;
    Dbg_TDI_3          : out std_logic;
    Dbg_TDO_3          : in  std_logic;
    Dbg_Reg_En_3       : out std_logic_vector(0 to 7);
    Dbg_Capture_3      : out std_logic;
    Dbg_Shift_3        : out std_logic;
    Dbg_Update_3       : out std_logic;
    Dbg_Rst_3          : out std_logic;
    Dbg_Trig_In_3      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_3  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_3     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_3 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_3        : out std_logic;
    Dbg_TrData_3       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_3      : out std_logic;
    Dbg_TrValid_3      : in  std_logic;

    Dbg_Clk_4          : out std_logic;
    Dbg_TDI_4          : out std_logic;
    Dbg_TDO_4          : in  std_logic;
    Dbg_Reg_En_4       : out std_logic_vector(0 to 7);
    Dbg_Capture_4      : out std_logic;
    Dbg_Shift_4        : out std_logic;
    Dbg_Update_4       : out std_logic;
    Dbg_Rst_4          : out std_logic;
    Dbg_Trig_In_4      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_4  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_4     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_4 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_4        : out std_logic;
    Dbg_TrData_4       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_4      : out std_logic;
    Dbg_TrValid_4      : in  std_logic;

    Dbg_Clk_5          : out std_logic;
    Dbg_TDI_5          : out std_logic;
    Dbg_TDO_5          : in  std_logic;
    Dbg_Reg_En_5       : out std_logic_vector(0 to 7);
    Dbg_Capture_5      : out std_logic;
    Dbg_Shift_5        : out std_logic;
    Dbg_Update_5       : out std_logic;
    Dbg_Rst_5          : out std_logic;
    Dbg_Trig_In_5      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_5  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_5     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_5 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_5        : out std_logic;
    Dbg_TrData_5       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_5      : out std_logic;
    Dbg_TrValid_5      : in  std_logic;

    Dbg_Clk_6          : out std_logic;
    Dbg_TDI_6          : out std_logic;
    Dbg_TDO_6          : in  std_logic;
    Dbg_Reg_En_6       : out std_logic_vector(0 to 7);
    Dbg_Capture_6      : out std_logic;
    Dbg_Shift_6        : out std_logic;
    Dbg_Update_6       : out std_logic;
    Dbg_Rst_6          : out std_logic;
    Dbg_Trig_In_6      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_6  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_6     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_6 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_6        : out std_logic;
    Dbg_TrData_6       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_6      : out std_logic;
    Dbg_TrValid_6      : in  std_logic;

    Dbg_Clk_7          : out std_logic;
    Dbg_TDI_7          : out std_logic;
    Dbg_TDO_7          : in  std_logic;
    Dbg_Reg_En_7       : out std_logic_vector(0 to 7);
    Dbg_Capture_7      : out std_logic;
    Dbg_Shift_7        : out std_logic;
    Dbg_Update_7       : out std_logic;
    Dbg_Rst_7          : out std_logic;
    Dbg_Trig_In_7      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_7  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_7     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_7 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_7        : out std_logic;
    Dbg_TrData_7       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_7      : out std_logic;
    Dbg_TrValid_7      : in  std_logic;

    Dbg_Clk_8          : out std_logic;
    Dbg_TDI_8          : out std_logic;
    Dbg_TDO_8          : in  std_logic;
    Dbg_Reg_En_8       : out std_logic_vector(0 to 7);
    Dbg_Capture_8      : out std_logic;
    Dbg_Shift_8        : out std_logic;
    Dbg_Update_8       : out std_logic;
    Dbg_Rst_8          : out std_logic;
    Dbg_Trig_In_8      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_8  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_8     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_8 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_8        : out std_logic;
    Dbg_TrData_8       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_8      : out std_logic;
    Dbg_TrValid_8      : in  std_logic;

    Dbg_Clk_9          : out std_logic;
    Dbg_TDI_9          : out std_logic;
    Dbg_TDO_9          : in  std_logic;
    Dbg_Reg_En_9       : out std_logic_vector(0 to 7);
    Dbg_Capture_9      : out std_logic;
    Dbg_Shift_9        : out std_logic;
    Dbg_Update_9       : out std_logic;
    Dbg_Rst_9          : out std_logic;
    Dbg_Trig_In_9      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_9  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_9     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_9 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_9        : out std_logic;
    Dbg_TrData_9       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_9      : out std_logic;
    Dbg_TrValid_9      : in  std_logic;

    Dbg_Clk_10          : out std_logic;
    Dbg_TDI_10          : out std_logic;
    Dbg_TDO_10          : in  std_logic;
    Dbg_Reg_En_10       : out std_logic_vector(0 to 7);
    Dbg_Capture_10      : out std_logic;
    Dbg_Shift_10        : out std_logic;
    Dbg_Update_10       : out std_logic;
    Dbg_Rst_10          : out std_logic;
    Dbg_Trig_In_10      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_10  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_10     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_10 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_10        : out std_logic;
    Dbg_TrData_10       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_10      : out std_logic;
    Dbg_TrValid_10      : in  std_logic;

    Dbg_Clk_11          : out std_logic;
    Dbg_TDI_11          : out std_logic;
    Dbg_TDO_11          : in  std_logic;
    Dbg_Reg_En_11       : out std_logic_vector(0 to 7);
    Dbg_Capture_11      : out std_logic;
    Dbg_Shift_11        : out std_logic;
    Dbg_Update_11       : out std_logic;
    Dbg_Rst_11          : out std_logic;
    Dbg_Trig_In_11      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_11  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_11     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_11 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_11        : out std_logic;
    Dbg_TrData_11       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_11      : out std_logic;
    Dbg_TrValid_11      : in  std_logic;

    Dbg_Clk_12          : out std_logic;
    Dbg_TDI_12          : out std_logic;
    Dbg_TDO_12          : in  std_logic;
    Dbg_Reg_En_12       : out std_logic_vector(0 to 7);
    Dbg_Capture_12      : out std_logic;
    Dbg_Shift_12        : out std_logic;
    Dbg_Update_12       : out std_logic;
    Dbg_Rst_12          : out std_logic;
    Dbg_Trig_In_12      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_12  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_12     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_12 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_12        : out std_logic;
    Dbg_TrData_12       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_12      : out std_logic;
    Dbg_TrValid_12      : in  std_logic;

    Dbg_Clk_13          : out std_logic;
    Dbg_TDI_13          : out std_logic;
    Dbg_TDO_13          : in  std_logic;
    Dbg_Reg_En_13       : out std_logic_vector(0 to 7);
    Dbg_Capture_13      : out std_logic;
    Dbg_Shift_13        : out std_logic;
    Dbg_Update_13       : out std_logic;
    Dbg_Rst_13          : out std_logic;
    Dbg_Trig_In_13      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_13  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_13     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_13 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_13        : out std_logic;
    Dbg_TrData_13       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_13      : out std_logic;
    Dbg_TrValid_13      : in  std_logic;

    Dbg_Clk_14          : out std_logic;
    Dbg_TDI_14          : out std_logic;
    Dbg_TDO_14          : in  std_logic;
    Dbg_Reg_En_14       : out std_logic_vector(0 to 7);
    Dbg_Capture_14      : out std_logic;
    Dbg_Shift_14        : out std_logic;
    Dbg_Update_14       : out std_logic;
    Dbg_Rst_14          : out std_logic;
    Dbg_Trig_In_14      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_14  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_14     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_14 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_14        : out std_logic;
    Dbg_TrData_14       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_14      : out std_logic;
    Dbg_TrValid_14      : in  std_logic;

    Dbg_Clk_15          : out std_logic;
    Dbg_TDI_15          : out std_logic;
    Dbg_TDO_15          : in  std_logic;
    Dbg_Reg_En_15       : out std_logic_vector(0 to 7);
    Dbg_Capture_15      : out std_logic;
    Dbg_Shift_15        : out std_logic;
    Dbg_Update_15       : out std_logic;
    Dbg_Rst_15          : out std_logic;
    Dbg_Trig_In_15      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_15  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_15     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_15 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_15        : out std_logic;
    Dbg_TrData_15       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_15      : out std_logic;
    Dbg_TrValid_15      : in  std_logic;

    Dbg_Clk_16          : out std_logic;
    Dbg_TDI_16          : out std_logic;
    Dbg_TDO_16          : in  std_logic;
    Dbg_Reg_En_16       : out std_logic_vector(0 to 7);
    Dbg_Capture_16      : out std_logic;
    Dbg_Shift_16        : out std_logic;
    Dbg_Update_16       : out std_logic;
    Dbg_Rst_16          : out std_logic;
    Dbg_Trig_In_16      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_16  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_16     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_16 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_16        : out std_logic;
    Dbg_TrData_16       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_16      : out std_logic;
    Dbg_TrValid_16      : in  std_logic;

    Dbg_Clk_17          : out std_logic;
    Dbg_TDI_17          : out std_logic;
    Dbg_TDO_17          : in  std_logic;
    Dbg_Reg_En_17       : out std_logic_vector(0 to 7);
    Dbg_Capture_17      : out std_logic;
    Dbg_Shift_17        : out std_logic;
    Dbg_Update_17       : out std_logic;
    Dbg_Rst_17          : out std_logic;
    Dbg_Trig_In_17      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_17  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_17     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_17 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_17        : out std_logic;
    Dbg_TrData_17       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_17      : out std_logic;
    Dbg_TrValid_17      : in  std_logic;

    Dbg_Clk_18          : out std_logic;
    Dbg_TDI_18          : out std_logic;
    Dbg_TDO_18          : in  std_logic;
    Dbg_Reg_En_18       : out std_logic_vector(0 to 7);
    Dbg_Capture_18      : out std_logic;
    Dbg_Shift_18        : out std_logic;
    Dbg_Update_18       : out std_logic;
    Dbg_Rst_18          : out std_logic;
    Dbg_Trig_In_18      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_18  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_18     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_18 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_18        : out std_logic;
    Dbg_TrData_18       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_18      : out std_logic;
    Dbg_TrValid_18      : in  std_logic;

    Dbg_Clk_19          : out std_logic;
    Dbg_TDI_19          : out std_logic;
    Dbg_TDO_19          : in  std_logic;
    Dbg_Reg_En_19       : out std_logic_vector(0 to 7);
    Dbg_Capture_19      : out std_logic;
    Dbg_Shift_19        : out std_logic;
    Dbg_Update_19       : out std_logic;
    Dbg_Rst_19          : out std_logic;
    Dbg_Trig_In_19      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_19  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_19     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_19 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_19        : out std_logic;
    Dbg_TrData_19       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_19      : out std_logic;
    Dbg_TrValid_19      : in  std_logic;

    Dbg_Clk_20          : out std_logic;
    Dbg_TDI_20          : out std_logic;
    Dbg_TDO_20          : in  std_logic;
    Dbg_Reg_En_20       : out std_logic_vector(0 to 7);
    Dbg_Capture_20      : out std_logic;
    Dbg_Shift_20        : out std_logic;
    Dbg_Update_20       : out std_logic;
    Dbg_Rst_20          : out std_logic;
    Dbg_Trig_In_20      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_20  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_20     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_20 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_20        : out std_logic;
    Dbg_TrData_20       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_20      : out std_logic;
    Dbg_TrValid_20      : in  std_logic;

    Dbg_Clk_21          : out std_logic;
    Dbg_TDI_21          : out std_logic;
    Dbg_TDO_21          : in  std_logic;
    Dbg_Reg_En_21       : out std_logic_vector(0 to 7);
    Dbg_Capture_21      : out std_logic;
    Dbg_Shift_21        : out std_logic;
    Dbg_Update_21       : out std_logic;
    Dbg_Rst_21          : out std_logic;
    Dbg_Trig_In_21      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_21  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_21     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_21 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_21        : out std_logic;
    Dbg_TrData_21       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_21      : out std_logic;
    Dbg_TrValid_21      : in  std_logic;

    Dbg_Clk_22          : out std_logic;
    Dbg_TDI_22          : out std_logic;
    Dbg_TDO_22          : in  std_logic;
    Dbg_Reg_En_22       : out std_logic_vector(0 to 7);
    Dbg_Capture_22      : out std_logic;
    Dbg_Shift_22        : out std_logic;
    Dbg_Update_22       : out std_logic;
    Dbg_Rst_22          : out std_logic;
    Dbg_Trig_In_22      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_22  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_22     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_22 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_22        : out std_logic;
    Dbg_TrData_22       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_22      : out std_logic;
    Dbg_TrValid_22      : in  std_logic;

    Dbg_Clk_23          : out std_logic;
    Dbg_TDI_23          : out std_logic;
    Dbg_TDO_23          : in  std_logic;
    Dbg_Reg_En_23       : out std_logic_vector(0 to 7);
    Dbg_Capture_23      : out std_logic;
    Dbg_Shift_23        : out std_logic;
    Dbg_Update_23       : out std_logic;
    Dbg_Rst_23          : out std_logic;
    Dbg_Trig_In_23      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_23  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_23     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_23 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_23        : out std_logic;
    Dbg_TrData_23       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_23      : out std_logic;
    Dbg_TrValid_23      : in  std_logic;

    Dbg_Clk_24          : out std_logic;
    Dbg_TDI_24          : out std_logic;
    Dbg_TDO_24          : in  std_logic;
    Dbg_Reg_En_24       : out std_logic_vector(0 to 7);
    Dbg_Capture_24      : out std_logic;
    Dbg_Shift_24        : out std_logic;
    Dbg_Update_24       : out std_logic;
    Dbg_Rst_24          : out std_logic;
    Dbg_Trig_In_24      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_24  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_24     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_24 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_24        : out std_logic;
    Dbg_TrData_24       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_24      : out std_logic;
    Dbg_TrValid_24      : in  std_logic;

    Dbg_Clk_25          : out std_logic;
    Dbg_TDI_25          : out std_logic;
    Dbg_TDO_25          : in  std_logic;
    Dbg_Reg_En_25       : out std_logic_vector(0 to 7);
    Dbg_Capture_25      : out std_logic;
    Dbg_Shift_25        : out std_logic;
    Dbg_Update_25       : out std_logic;
    Dbg_Rst_25          : out std_logic;
    Dbg_Trig_In_25      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_25  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_25     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_25 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_25        : out std_logic;
    Dbg_TrData_25       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_25      : out std_logic;
    Dbg_TrValid_25      : in  std_logic;

    Dbg_Clk_26          : out std_logic;
    Dbg_TDI_26          : out std_logic;
    Dbg_TDO_26          : in  std_logic;
    Dbg_Reg_En_26       : out std_logic_vector(0 to 7);
    Dbg_Capture_26      : out std_logic;
    Dbg_Shift_26        : out std_logic;
    Dbg_Update_26       : out std_logic;
    Dbg_Rst_26          : out std_logic;
    Dbg_Trig_In_26      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_26  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_26     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_26 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_26        : out std_logic;
    Dbg_TrData_26       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_26      : out std_logic;
    Dbg_TrValid_26      : in  std_logic;

    Dbg_Clk_27          : out std_logic;
    Dbg_TDI_27          : out std_logic;
    Dbg_TDO_27          : in  std_logic;
    Dbg_Reg_En_27       : out std_logic_vector(0 to 7);
    Dbg_Capture_27      : out std_logic;
    Dbg_Shift_27        : out std_logic;
    Dbg_Update_27       : out std_logic;
    Dbg_Rst_27          : out std_logic;
    Dbg_Trig_In_27      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_27  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_27     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_27 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_27        : out std_logic;
    Dbg_TrData_27       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_27      : out std_logic;
    Dbg_TrValid_27      : in  std_logic;

    Dbg_Clk_28          : out std_logic;
    Dbg_TDI_28          : out std_logic;
    Dbg_TDO_28          : in  std_logic;
    Dbg_Reg_En_28       : out std_logic_vector(0 to 7);
    Dbg_Capture_28      : out std_logic;
    Dbg_Shift_28        : out std_logic;
    Dbg_Update_28       : out std_logic;
    Dbg_Rst_28          : out std_logic;
    Dbg_Trig_In_28      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_28  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_28     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_28 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_28        : out std_logic;
    Dbg_TrData_28       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_28      : out std_logic;
    Dbg_TrValid_28      : in  std_logic;

    Dbg_Clk_29          : out std_logic;
    Dbg_TDI_29          : out std_logic;
    Dbg_TDO_29          : in  std_logic;
    Dbg_Reg_En_29       : out std_logic_vector(0 to 7);
    Dbg_Capture_29      : out std_logic;
    Dbg_Shift_29        : out std_logic;
    Dbg_Update_29       : out std_logic;
    Dbg_Rst_29          : out std_logic;
    Dbg_Trig_In_29      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_29  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_29     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_29 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_29        : out std_logic;
    Dbg_TrData_29       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_29      : out std_logic;
    Dbg_TrValid_29      : in  std_logic;

    Dbg_Clk_30          : out std_logic;
    Dbg_TDI_30          : out std_logic;
    Dbg_TDO_30          : in  std_logic;
    Dbg_Reg_En_30       : out std_logic_vector(0 to 7);
    Dbg_Capture_30      : out std_logic;
    Dbg_Shift_30        : out std_logic;
    Dbg_Update_30       : out std_logic;
    Dbg_Rst_30          : out std_logic;
    Dbg_Trig_In_30      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_30  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_30     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_30 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_30        : out std_logic;
    Dbg_TrData_30       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_30      : out std_logic;
    Dbg_TrValid_30      : in  std_logic;

    Dbg_Clk_31          : out std_logic;
    Dbg_TDI_31          : out std_logic;
    Dbg_TDO_31          : in  std_logic;
    Dbg_Reg_En_31       : out std_logic_vector(0 to 7);
    Dbg_Capture_31      : out std_logic;
    Dbg_Shift_31        : out std_logic;
    Dbg_Update_31       : out std_logic;
    Dbg_Rst_31          : out std_logic;
    Dbg_Trig_In_31      : in  std_logic_vector(0 to 7);
    Dbg_Trig_Ack_In_31  : out std_logic_vector(0 to 7);
    Dbg_Trig_Out_31     : out std_logic_vector(0 to 7);
    Dbg_Trig_Ack_Out_31 : in  std_logic_vector(0 to 7);
    Dbg_TrClk_31        : out std_logic;
    Dbg_TrData_31       : in  std_logic_vector(0 to 35);
    Dbg_TrReady_31      : out std_logic;
    Dbg_TrValid_31      : in  std_logic;

    -- External Trigger Signals
    Ext_Trig_In      : in  std_logic_vector(0 to 3);
    Ext_Trig_Ack_In  : out std_logic_vector(0 to 3);
    Ext_Trig_Out     : out std_logic_vector(0 to 3);
    Ext_Trig_Ack_Out : in  std_logic_vector(0 to 3);
    
    -- External JTAG Signals
    Ext_JTAG_DRCK    : out std_logic;
    Ext_JTAG_RESET   : out std_logic;
    Ext_JTAG_SEL     : out std_logic;
    Ext_JTAG_CAPTURE : out std_logic;
    Ext_JTAG_SHIFT   : out std_logic;
    Ext_JTAG_UPDATE  : out std_logic;
    Ext_JTAG_TDI     : out std_logic;
    Ext_JTAG_TDO     : in  std_logic
  );
end entity MDM_Core;

library IEEE;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library mdm_v3_2_4;
use mdm_v3_2_4.all;

architecture IMP of MDM_CORE is

  function log2(x : natural) return integer is
    variable i  : integer := 0;   
  begin
    if x = 0 then return 0;
    else
      while 2**i < x loop
        i := i+1;
      end loop;
      return i;
    end if;
  end function log2;

  constant C_DRCK_FREQ_HZ : integer := 30000000;
  constant C_CLOCK_BITS   : integer := log2(C_S_AXI_ACLK_FREQ_HZ / C_DRCK_FREQ_HZ);

  component JTAG_CONTROL
    generic (
      C_MB_DBG_PORTS      : integer;
      C_USE_CONFIG_RESET  : integer;
      C_DBG_REG_ACCESS    : integer;
      C_DBG_MEM_ACCESS    : integer;
      C_M_AXI_ADDR_WIDTH  : integer;
      C_M_AXI_DATA_WIDTH  : integer;
      C_USE_CROSS_TRIGGER : integer;
      C_USE_UART          : integer;
      C_UART_WIDTH        : integer;
      C_TRACE_OUTPUT      : integer;
      C_EN_WIDTH          : integer := 1
    );
    port (
      -- Global signals
      Config_Reset    : in std_logic;
      Scan_Reset_Sel  : in std_logic;
      Scan_Reset      : in std_logic;

      Clk             : in std_logic;
      Rst             : in std_logic;

      Clear_Ext_BRK   : in  std_logic;
      Ext_BRK         : out std_logic;
      Ext_NM_BRK      : out std_logic;
      Debug_SYS_Rst   : out std_logic;
      Debug_Rst       : out std_logic;

      Read_RX_FIFO    : in  std_logic;
      Reset_RX_FIFO   : in  std_logic;
      RX_Data         : out std_logic_vector(0 to C_UART_WIDTH-1);
      RX_Data_Present : out std_logic;
      RX_Buffer_Full  : out std_logic;

      Write_TX_FIFO   : in  std_logic;
      Reset_TX_FIFO   : in  std_logic;
      TX_Data         : in  std_logic_vector(0 to C_UART_WIDTH-1);
      TX_Buffer_Full  : out std_logic;
      TX_Buffer_Empty : out std_logic;

      -- Debug Register Access signals
      DbgReg_Access_Lock : in  std_logic;
      DbgReg_Force_Lock  : in  std_logic;
      DbgReg_Unlocked    : in  std_logic;
      JTAG_Access_Lock   : out std_logic;
      JTAG_Force_Lock    : out std_logic;
      JTAG_AXIS_Overrun  : in  std_logic;
      JTAG_Clear_Overrun : out std_logic;

      -- MDM signals
      TDI     : in  std_logic;
      RESET   : in  std_logic;
      UPDATE  : in  std_logic;
      SHIFT   : in  std_logic;
      CAPTURE : in  std_logic;
      SEL     : in  std_logic;
      DRCK    : in  std_logic;
      TDO     : out std_logic;

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

      Trace_Clk           : in  std_logic;
      Trace_Reset         : in  std_logic;
      Trace_Test_Pattern  : out std_logic_vector(0 to 3);
      Trace_Test_Start    : out std_logic;
      Trace_Test_Stop     : out std_logic;
      Trace_Test_Timed    : out std_logic;
      Trace_Delay         : out std_logic_vector(0 to 7);
      Trace_Stopped       : out std_logic
    );
  end component JTAG_CONTROL;

  component Arbiter is
    generic (
      Size      : natural;
      Size_Log2 : natural);
    port (
      Clk       : in  std_logic;
      Reset     : in  std_logic;

      Enable    : in  std_logic;
      Requests  : in  std_logic_vector(Size-1 downto 0);
      Granted   : out std_logic_vector(Size-1 downto 0);
      Valid_Sel : out std_logic;
      Selected  : out std_logic_vector(Size_Log2-1 downto 0)
    );
  end component Arbiter;


  -- Returns the minimum value of the two parameters
  function IntMin (a, b : integer) return integer is
  begin
    if a < b then
      return a;
    else
      return b;
    end if;
  end function IntMin;

  signal config_reset_i    : std_logic;
  signal clear_Ext_BRK     : std_logic;

  signal sel_n_reset       : std_logic;
  signal shift_n_reset     : std_logic;

  signal enable_interrupts : std_logic;
  signal read_RX_FIFO      : std_logic;
  signal reset_RX_FIFO     : std_logic;

  signal rx_Data         : std_logic_vector(0 to C_UART_WIDTH-1);
  signal rx_Data_Present : std_logic;
  signal rx_Buffer_Full  : std_logic;

  signal tx_Data         : std_logic_vector(0 to C_UART_WIDTH-1);
  signal write_TX_FIFO   : std_logic;
  signal reset_TX_FIFO   : std_logic;
  signal tx_Buffer_Full  : std_logic;
  signal tx_Buffer_Empty : std_logic;

  signal xfer_Ack   : std_logic;
  signal mdm_Dbus_i : std_logic_vector(0 to 31);  -- Check!

  signal mdm_CS   : std_logic;  -- Valid address in a address phase
  signal mdm_CS_1 : std_logic;  -- Active as long as mdm_CS is active
  signal mdm_CS_2 : std_logic;
  signal mdm_CS_3 : std_logic;
  
  signal valid_access           : std_logic;  -- Active during the address phase (2 clock cycles)
  signal valid_access_1         : std_logic;  -- Will be a 1 clock delayed valid_access signal
  signal valid_access_2         : std_logic;  -- Active only 1 clock cycle
  signal reading                : std_logic;  -- Valid reading access
  signal valid_access_2_reading : std_logic;  -- signal to drive out data bus on a read access
  signal sl_rdDAck_i            : std_logic;
  signal sl_wrDAck_i            : std_logic;

  signal TDI     : std_logic;
  signal RESET   : std_logic;
  signal SHIFT   : std_logic;
  signal CAPTURE : std_logic;
  signal TDO     : std_logic;

  signal mb_debug_enabled_i : std_logic_vector(C_EN_WIDTH-1 downto 0);
  signal Dbg_Clk            : std_logic;
  signal Dbg_TDI            : std_logic;
  signal Dbg_TDO            : std_logic;
  signal Dbg_Reg_En         : std_logic_vector(0 to 7);
  signal Dbg_Capture        : std_logic;
  signal Dbg_Shift          : std_logic;
  signal Dbg_Update         : std_logic;

  signal Debug_SYS_Rst_i : std_logic;
  signal Debug_Rst_i     : std_logic;

  subtype Reg_En_TYPE is std_logic_vector(0 to 7);
  type Reg_EN_ARRAY is array(0 to 31) of Reg_En_TYPE;

  signal Dbg_TDO_I    : std_logic_vector(0 to 31);
  signal Dbg_Reg_En_I : Reg_EN_ARRAY;
  signal Dbg_Rst_I    : std_logic_vector(0 to 31);
  signal Dbg_TrClk    : std_logic;
  signal Dbg_TrReady  : std_logic_vector(0 to 31);

  signal PORT_Selector   : std_logic_vector(3 downto 0) := (others => '0');
  signal PORT_Selector_1 : std_logic_vector(3 downto 0) := (others => '0');
  signal TDI_Shifter     : std_logic_vector(3 downto 0) := (others => '0');
  signal Sl_rdDBus_int   : std_logic_vector(0 to 31);

  signal bus_clk : std_logic;
  signal bus_rst : std_logic;

  signal uart_ip2bus_rdack   : std_logic;
  signal uart_ip2bus_wrack   : std_logic;
  signal uart_ip2bus_error   : std_logic;
  signal uart_ip2bus_data    : std_logic_vector(C_REG_DATA_WIDTH-1 downto 0);

  signal dbgreg_ip2bus_rdack : std_logic;
  signal dbgreg_ip2bus_wrack : std_logic;
  signal dbgreg_ip2bus_error : std_logic;
  signal dbgreg_ip2bus_data  : std_logic_vector(C_REG_DATA_WIDTH-1 downto 0);

  signal dbgreg_access_lock  : std_logic;
  signal dbgreg_force_lock   : std_logic;
  signal dbgreg_unlocked     : std_logic;
  signal jtag_access_lock    : std_logic;
  signal jtag_force_lock     : std_logic;
  signal jtag_axis_overrun   : std_logic;
  signal jtag_clear_overrun  : std_logic;

  -- Full frame synchronization packet
  constant C_FF_SYNC_PACKET  : std_logic_vector(31 downto 0) := (31 => '0', others => '1');

  signal trace_clk_i         : std_logic;
  signal trace_reset         : std_logic;
  signal trace_word          : std_logic_vector(31 downto 0);
  signal trace_index         : std_logic_vector(4  downto 0);
  signal trace_trdata        : std_logic_vector(35 downto 0);
  signal trace_valid         : std_logic;
  signal trace_last_word     : std_logic;
  signal trace_started       : std_logic;
  signal trace_ready         : std_logic;
  signal trace_trready       : std_logic;
  signal trace_count_last    : std_logic;

  signal trace_test_pattern  : std_logic_vector(0 to 3);
  signal trace_test_start    : std_logic;
  signal trace_test_stop     : std_logic;
  signal trace_test_timed    : std_logic;
  signal trace_delay         : std_logic_vector(0 to 7);
  signal trace_stopped       : std_logic;

  -----------------------------------------------------------------------------
  -- Register mapping
  -----------------------------------------------------------------------------

  -- Magic string "01000010" + "00000000" + No of Jtag peripheral units "0010"
  -- + MDM Version no "00000110"
  --
  -- MDM Versions table:
  --  0,1,2,3: Not used
  --        4: opb_mdm v3
  --        5: mdm v1
  --        6: mdm v2
  
  constant New_MDM_Config_Word : std_logic_vector(31 downto 0) :=
    "01000010000000000000001000000110";

  signal Config_Reg : std_logic_vector(31 downto 0) := New_MDM_Config_Word;

  signal MDM_SEL : std_logic;

  signal Old_MDM_DRCK    : std_logic;
  signal Old_MDM_TDI     : std_logic;
  signal Old_MDM_TDO     : std_logic;
  signal Old_MDM_SEL     : std_logic;
  signal Old_MDM_SEL_Mux : std_logic;
  signal Old_MDM_SHIFT   : std_logic;
  signal Old_MDM_UPDATE  : std_logic;
  signal Old_MDM_RESET   : std_logic;
  signal Old_MDM_CAPTURE : std_logic;

  signal JTAG_Dec_Sel : std_logic_vector(15 downto 0);

begin  -- architecture IMP

  config_reset_i <= Config_Reset when C_USE_CONFIG_RESET /= 0 else '0';

  sel_n_reset    <= not SEL or config_reset_i when Scan_Reset_Sel = '0' else
                    Scan_Reset;

  shift_n_reset  <= not SHIFT or config_reset_i when Scan_Reset_Sel = '0' else
                    Scan_Reset;

  -----------------------------------------------------------------------------
  -- TDI Shift Register
  -----------------------------------------------------------------------------
  -- Shifts data in when PORT 0 is selected. PORT 0 does not actually
  -- exist externaly, but gets selected after asserting the SELECT signal.
  -- The first value shifted in after SELECT goes high will select the new
  -- PORT. 
  JTAG_Mux_Shifting : process (DRCK, sel_n_reset)
  begin
    if sel_n_reset = '1' then
      TDI_Shifter   <= (others => '0');
    elsif DRCK'event and DRCK = '1' then
      if MDM_SEL = '1' and SHIFT = '1' then
        TDI_Shifter <= TDI & TDI_Shifter(3 downto 1);
      end if;
    end if;
  end process JTAG_Mux_Shifting;

  -----------------------------------------------------------------------------
  -- PORT Selector Register
  -----------------------------------------------------------------------------
  -- Captures the shifted data when PORT 0 is selected. The data is captured at
  -- the end of the BSCAN transaction (i.e. when the update signal goes low) to
  -- prevent any other BSCAN signals to assert incorrectly.
  -- Reference : XAPP 139  
  PORT_Selector_Updating : process (UPDATE, sel_n_reset)
  begin
    if sel_n_reset = '1' then
      PORT_Selector   <= (others => '0');
    elsif Update'event and Update = '0' then
      PORT_Selector <= Port_Selector_1;
    end if;
  end process PORT_Selector_Updating;

  PORT_Selector_Updating_1 : process (UPDATE, sel_n_reset)
  begin
    if sel_n_reset = '1' then
      PORT_Selector_1   <= (others => '0');
    elsif Update'event and Update = '1' then
      if MDM_SEL = '1' then
        PORT_Selector_1 <= TDI_Shifter;
      end if;
    end if;
  end process PORT_Selector_Updating_1;

  -----------------------------------------------------------------------------
  -- Configuration register
  -----------------------------------------------------------------------------
  -- TODO Can be replaced by SRLs
  Config_Shifting : process (DRCK, shift_n_reset)
  begin
    if shift_n_reset = '1' then
      Config_Reg <= New_MDM_Config_Word;
    elsif DRCK'event and DRCK = '1' then   -- rising clock edge
      Config_Reg <= '0' & Config_Reg(31 downto 1);
    end if;
  end process Config_Shifting;

  -----------------------------------------------------------------------------
  -- Muxing and demuxing of JTAG Bscan User 1/2/3/4 signals
  --
  -- This block enables the older MDM/JTAG to co-exist with the newer
  -- JTAG multiplexer block
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- TDO Mux
  -----------------------------------------------------------------------------
  with PORT_Selector select
    TDO <=
    Config_Reg(0) when "0000",
    Old_MDM_TDO   when "0001",
    Ext_JTAG_TDO  when "0010",
    '1'           when others;

  -----------------------------------------------------------------------------
  -- SELECT Decoder
  -----------------------------------------------------------------------------
  MDM_SEL         <= SEL when PORT_Selector = "0000" else '0';
  Old_MDM_SEL_Mux <= SEL when PORT_Selector = "0001" else '0';
  Ext_JTAG_SEL    <= SEL when PORT_Selector = "0010" else '0';

  -----------------------------------------------------------------------------
  -- Old MDM signals
  -----------------------------------------------------------------------------
  Old_MDM_DRCK    <= DRCK;
  Old_MDM_TDI     <= TDI;
  Old_MDM_CAPTURE <= CAPTURE;
  Old_MDM_SHIFT   <= SHIFT;
  Old_MDM_UPDATE  <= UPDATE;
  Old_MDM_RESET   <= RESET;

  -----------------------------------------------------------------------------
  -- External JTAG signals
  -----------------------------------------------------------------------------
  Ext_JTAG_DRCK    <= DRCK;
  Ext_JTAG_TDI     <= TDI;
  Ext_JTAG_CAPTURE <= CAPTURE;
  Ext_JTAG_SHIFT   <= SHIFT;
  Ext_JTAG_UPDATE  <= UPDATE;
  Ext_JTAG_RESET   <= RESET;

  -----------------------------------------------------------------------------
  -- AXI bus interface
  -----------------------------------------------------------------------------
  ip2bus_rdack <= uart_ip2bus_rdack or dbgreg_ip2bus_rdack;
  ip2bus_wrack <= uart_ip2bus_wrack or dbgreg_ip2bus_wrack;
  ip2bus_error <= uart_ip2bus_error or dbgreg_ip2bus_error;
  ip2bus_data  <= uart_ip2bus_data  or dbgreg_ip2bus_data;

  Use_AXI_IPIF : if (C_USE_UART = 1) or (C_DBG_REG_ACCESS = 1) generate
  begin
    bus_clk <= bus2ip_clk;
    bus_rst <= not bus2ip_resetn;
  end generate Use_AXI_IPIF;

  No_AXI_IPIF : if (C_USE_UART = 0) and (C_DBG_REG_ACCESS = 0) generate
  begin
    bus_clk <= '0';
    bus_rst <= '0';
  end generate No_AXI_IPIF;

  -----------------------------------------------------------------------------
  -- UART
  -----------------------------------------------------------------------------
  Use_Uart : if (C_USE_UART = 1) generate
    -- Read Only
    signal status_Reg : std_logic_vector(7 downto 0);
    -- bit 4 enable_interrupts
    -- bit 3 tx_Buffer_Full
    -- bit 2 tx_Buffer_Empty
    -- bit 1 rx_Buffer_Full
    -- bit 0 rx_Data_Present

    -- Write Only
    -- Control Register
    -- bit 7-5 Dont'Care
    -- bit 4   enable_interrupts
    -- bit 3   Dont'Care
    -- bit 2   Clear Ext BRK signal
    -- bit 1   Reset_RX_FIFO
    -- bit 0   Reset_TX_FIFO

    signal tx_Buffer_Empty_Pre : std_logic;
  begin
    ---------------------------------------------------------------------------
    -- Acknowledgement and error signals
    ---------------------------------------------------------------------------
    uart_ip2bus_rdack <= bus2ip_rdce(0) or bus2ip_rdce(2) or bus2ip_rdce(1)
                         or bus2ip_rdce(3);

    uart_ip2bus_wrack <= bus2ip_wrce(1) or bus2ip_wrce(3) or bus2ip_wrce(0)
                         or bus2ip_wrce(2);

    uart_ip2bus_error <= ((bus2ip_rdce(0) and not rx_Data_Present) or
                          (bus2ip_wrce(1) and tx_Buffer_Full) );
    
    ---------------------------------------------------------------------------
    -- Status register
    ---------------------------------------------------------------------------
    status_Reg(0) <= rx_Data_Present;
    status_Reg(1) <= rx_Buffer_Full;
    status_Reg(2) <= tx_Buffer_Empty;
    status_Reg(3) <= tx_Buffer_Full;
    status_Reg(4) <= enable_interrupts;
    status_Reg(7 downto 5) <= "000";

    ---------------------------------------------------------------------------
    -- Control Register    
    ---------------------------------------------------------------------------
    CTRL_REG_DFF : process (bus2ip_clk) is
    begin
      if bus2ip_clk'event and bus2ip_clk = '1' then -- rising clock edge
        if bus2ip_resetn = '0' then                 -- synchronous reset (active low)
          enable_interrupts <= '0';
          clear_Ext_BRK     <= '0';
          reset_RX_FIFO     <= '1';
          reset_TX_FIFO     <= '1';
        elsif (bus2ip_wrce(3) = '1') then  -- Control Register is reg 3
           enable_interrupts <= bus2ip_data(4); -- Bit 4 in control reg
           clear_Ext_BRK     <= bus2ip_data(2); -- Bit 2 in control reg
           reset_RX_FIFO     <= bus2ip_data(1); -- Bit 1 in control reg
           reset_TX_FIFO     <= bus2ip_data(0); -- Bit 0 in control reg
        else
          clear_Ext_BRK <= '0';
          reset_RX_FIFO <= '0';
          reset_TX_FIFO <= '0';
        end if;
      end if;
    end process CTRL_REG_DFF;
                               
    ---------------------------------------------------------------------------
    -- Read bus interface
    ---------------------------------------------------------------------------
    READ_MUX : process (status_reg, bus2ip_rdce(2), bus2ip_rdce(0), rx_Data) is
    begin
      uart_ip2bus_data <= (others => '0');
      if (bus2ip_rdce(2) = '1') then    -- Status register is reg 2
        uart_ip2bus_data(status_reg'length-1 downto 0) <= status_reg;
      elsif (bus2ip_rdce(0) = '1') then -- RX FIFO is reg 0
        uart_ip2bus_data(C_UART_WIDTH-1 downto 0) <= rx_Data;
      end if;
    end process READ_MUX;
    
    ---------------------------------------------------------------------------
    -- Write bus interface
    ---------------------------------------------------------------------------
    tx_Data <=  bus2ip_data(C_UART_WIDTH-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Read and write pulses to the FIFOs
    ---------------------------------------------------------------------------
    write_TX_FIFO <= bus2ip_wrce(1);    -- TX FIFO is reg 1
    read_RX_FIFO  <= bus2ip_rdce(0);    -- RX FIFO is reg 0

    -- Sample the tx_Buffer_Empty signal in order to detect a rising edge 
    TX_Buffer_Empty_FDRE : FDRE
      port map (
        Q  => tx_Buffer_Empty_Pre, 
        C  => bus_clk,
        CE => '1',
        D  => tx_Buffer_Empty,
        R  => write_TX_FIFO);

    ---------------------------------------------------------------------------
    -- Interrupt handling
    ---------------------------------------------------------------------------
    Interrupt <= enable_interrupts and ( rx_Data_Present or
                                         ( tx_Buffer_Empty and
                                           not tx_Buffer_Empty_Pre ) );
  end generate Use_UART;

  No_UART : if (C_USE_UART = 0) generate
  begin
    uart_ip2bus_rdack <= '0';
    uart_ip2bus_wrack <= '0';
    uart_ip2bus_error <= '0';
    uart_ip2bus_data  <= (others => '0');

    Interrupt         <= '0';

    reset_TX_FIFO     <= '1';
    reset_RX_FIFO     <= '1';
    enable_interrupts <= '0';
    clear_Ext_BRK     <= '0';
    tx_Data           <= (others => '0');
    write_TX_FIFO     <= '0';
    read_RX_FIFO      <= '0';
  end generate No_UART;

  -----------------------------------------------------------------------------
  -- Debug Register Access
  -----------------------------------------------------------------------------
  Use_Dbg_Reg_Access : if (C_DBG_REG_ACCESS = 1) generate
    type state_type is
      (idle, select_dr, capture_dr, shift_dr, exit1, pause, exit2, update_dr, cmd_done, data_done);

    signal bit_size       : std_logic_vector(8 downto 0);
    signal cmd_val        : std_logic_vector(7 downto 0);
    signal type_lock      : std_logic_vector(1 downto 0);
    signal use_mdm        : std_logic;
    signal reg_data       : std_logic_vector(31 downto 0);

    signal bit_cnt        : std_logic_vector(0 to 8);
    signal clk_cnt        : std_logic_vector(0 to C_CLOCK_BITS / 2);
    signal clk_fall       : boolean;
    signal clk_rise       : boolean;
    signal shifting       : boolean;
    signal data_shift     : boolean;
    signal direction      : std_logic;
    signal rd_wr_n        : boolean;
    signal rdack_data     : std_logic;
    signal selected       : std_logic := '0';
    signal shift_index    : std_logic_vector(0 to 4);
    signal state          : state_type;
    signal unlocked       : boolean;
    signal wrack_data     : std_logic;

    signal dbgreg_TDI     : std_logic;
    signal dbgreg_RESET   : std_logic;
    signal dbgreg_SHIFT   : std_logic;
    signal dbgreg_CAPTURE : std_logic;
    signal dbgreg_SEL     : std_logic;
  begin

    ---------------------------------------------------------------------------
    -- Acknowledgement and error signals
    ---------------------------------------------------------------------------
    dbgreg_ip2bus_rdack <= bus2ip_rdce(4) or rdack_data;
    dbgreg_ip2bus_wrack <= bus2ip_wrce(4) or bus2ip_wrce(6) or wrack_data;
    dbgreg_ip2bus_error <= (bus2ip_rdce(5) or bus2ip_wrce(5)) and not dbgreg_access_lock;

    ---------------------------------------------------------------------------
    -- Control register
    ---------------------------------------------------------------------------
    CTRL_REG_DFF : process (bus2ip_clk) is
    begin
      if bus2ip_clk'event and bus2ip_clk = '1' then -- rising clock edge
        if bus2ip_resetn = '0' then                 -- synchronous reset (active low)
          use_mdm   <= '0';
          type_lock <= (others => '0');
          cmd_val   <= (others => '0');
          bit_size  <= (others => '0');
        elsif (bus2ip_wrce(4) = '1') and unlocked then  -- Control Register is reg 4
          type_lock <= bus2ip_data(19 downto 18);
          use_mdm   <= bus2ip_data(17);
          cmd_val   <= bus2ip_data(16 downto 9);
          bit_size  <= bus2ip_data(8  downto 0);
        end if;
      end if;
    end process CTRL_REG_DFF;

    ---------------------------------------------------------------------------
    -- Data register and TAP state machine
    ---------------------------------------------------------------------------
    DATA_REG_DFF : process (bus2ip_clk) is
    begin
      if bus2ip_clk'event and bus2ip_clk = '1' then -- rising clock edge
        if bus2ip_resetn = '0' then                 -- synchronous reset (active low)
          reg_data       <= (others => '0');
          rdack_data     <= '0';
          wrack_data     <= '0';
          state          <= idle;
          shifting       <= false;
          data_shift     <= false;
          direction      <= '1';
          rd_wr_n        <= false;
          clk_rise       <= false;
          clk_fall       <= false;
          clk_cnt        <= (others => '0');
          bit_cnt        <= "000000111";
          shift_index    <= "00000";
          dbgreg_TDI     <= '0';
          dbgreg_RESET   <= '0';
          dbgreg_SHIFT   <= '0';
          dbgreg_CAPTURE <= '0';
          dbgreg_SEL     <= '0';
          DbgReg_DRCK    <= '0';
          DbgReg_UPDATE  <= '0';
          selected       <= '0';
        else
          rdack_data    <= '0';
          wrack_data    <= '0';
          if unlocked and dbgreg_access_lock = '1' and not shifting then
            if bus2ip_wrce(5) = '1' then
              reg_data <= bus2ip_data;
              shifting <= true;
              rd_wr_n  <= false;
            end if;
            if bus2ip_rdce(5) = '1' then
              shifting <= true;
              rd_wr_n  <= true;
            end if;
          end if;
          if clk_rise then
            case state is
              when idle =>
                -- Idle - Start when data access occurs
                if shifting then
                  state <= select_dr;
                end if;
                bit_cnt     <= "000000111";
                shift_index <= "00000";
                selected    <= '0';
              when select_dr =>
                -- TAP state Select DR - Set SEL
                state <= capture_dr;
                dbgreg_SEL  <= '1';
                selected    <= '1';
              when capture_dr =>
                -- TAP state Capture DR - Set CAPTURE and pulse DRCK
                state <= shift_dr;
                dbgreg_CAPTURE <= '1';
                DbgReg_DRCK    <= '1';
              when shift_dr =>
                -- TAP state Shift DR - Set SHIFT and pulse DRCK until done or pause
                if bit_cnt = (bit_cnt'range => '0') then
                  state <= exit2;         -- Shift done
                elsif shift_index = (shift_index'range => direction) then
                  state <= exit1;         -- Acknowledge and pause until next word
                  if rd_wr_n then
                    rdack_data <= '1';
                  else
                    wrack_data <= '1';
                  end if;
                end if;
                if data_shift then
                  dbgreg_TDI   <= reg_data(to_integer(unsigned(shift_index)));
                  reg_data(to_integer(unsigned(shift_index))) <= Old_MDM_TDO;
                else
                  dbgreg_TDI   <= cmd_val(to_integer(unsigned(shift_index)));
                end if;
                dbgreg_CAPTURE <= '0';
                dbgreg_SHIFT   <= '1';
                DbgReg_DRCK    <= '1';
                bit_cnt        <= std_logic_vector(unsigned(bit_cnt) - 1);
                if direction = '1' then
                  shift_index  <= std_logic_vector(unsigned(shift_index) + 1);
                else
                  shift_index  <= std_logic_vector(unsigned(shift_index) - 1);
                end if;
              when exit1 =>
                -- TAP state Exit1 DR - End shift and go to pause
                state <= pause;
                shifting     <= false;
                dbgreg_SHIFT <= '0';
                DbgReg_DRCK  <= '0';
              when pause =>
                -- TAP state Pause DR - Pause until new data access or abort
                if dbgreg_access_lock = '0' then
                  state <= exit2;         -- Abort shift
                elsif shifting then
                  state <= shift_dr;      -- Continue with next word
                end if;
                DbgReg_DRCK <= '0';
              when exit2 =>
                -- TAP state Exit2 DR - Delay before update
                state <= update_dr;
                dbgreg_SHIFT <= '0';
                DbgReg_DRCK  <= '0';
              when update_dr =>
                -- TAP state Update DR - Pulse UPDATE and acknowledge data access
                if data_shift then
                  state <= data_done;
                  if rd_wr_n then
                    rdack_data  <= '1';
                  else
                    wrack_data  <= '1';
                  end if;
                else
                  state <= cmd_done;
                end if;
                DbgReg_UPDATE <= '1';
              when cmd_done =>
                -- Command phase done - Continue with data phase
                state <= select_dr;
                data_shift    <= true;
                bit_cnt       <= bit_size;
                if use_mdm = '1' then
                  shift_index <= (others => '0');
                else
                  shift_index <= bit_size(shift_index'length - 1 downto 0);
                end if;
                direction     <= use_mdm;
                DbgReg_UPDATE <= '0';
              when data_done =>
                -- Data phase done - End shifting and go back to idle
                state         <= idle;
                data_shift    <= false;
                shifting      <= false;
                direction     <= '1';
                DbgReg_UPDATE <= '0';
            end case;
          elsif clk_fall then
            DbgReg_DRCK <= '0';
          end if;
          if clk_cnt(clk_cnt'left + 1 to clk_cnt'right) = (clk_cnt'left + 1 to clk_cnt'right => '0') then
            clk_rise <= (clk_cnt(clk_cnt'left) = '0');
            clk_fall <= (clk_cnt(clk_cnt'left) = '1');
          else
            clk_rise <= false;
            clk_fall <= false;
          end if;
          clk_cnt <= std_logic_vector(unsigned(clk_cnt) - 1);
        end if;
      end if;
    end process DATA_REG_DFF;

    ---------------------------------------------------------------------------
    -- Lock register
    ---------------------------------------------------------------------------
    LOCK_REG_DFF : process (bus2ip_clk) is
    begin
      if bus2ip_clk'event and bus2ip_clk = '1' then  -- rising clock edge
        if bus2ip_resetn = '0' then                  -- synchronous reset (active low)
          unlocked <= false;
        elsif (bus2ip_wrce(6) = '1') then  -- Lock Register is reg 6
          unlocked <= (bus2ip_data(15 downto 0) = X"EBAB") and (not unlocked);
        end if;
      end if;
    end process LOCK_REG_DFF;

    ---------------------------------------------------------------------------
    -- Read bus interface
    ---------------------------------------------------------------------------
    READ_MUX : process (bus2ip_rdce(4), rdack_data, dbgreg_access_lock, reg_data) is
    begin
      dbgreg_ip2bus_data <= (others => '0');
      if (bus2ip_rdce(4) = '1') then    -- Status register is reg 4
        dbgreg_ip2bus_data(0) <= dbgreg_access_lock;
      elsif rdack_data = '1' then       -- Data register is reg 5
        dbgreg_ip2bus_data <= reg_data;
      end if;
    end process READ_MUX;
    
    ---------------------------------------------------------------------------
    -- Access lock handling
    ---------------------------------------------------------------------------
    Handle_Access_Lock : process (bus2ip_clk) is
      variable jtag_access_lock_1   : std_logic;
      variable jtag_force_lock_1    : std_logic;
      variable jtag_clear_overrun_1 : std_logic;
      variable jtag_busy_1          : std_logic;                                          

      attribute ASYNC_REG : string;
      attribute ASYNC_REG of jtag_access_lock_1   : variable is "TRUE";
      attribute ASYNC_REG of jtag_force_lock_1    : variable is "TRUE";
      attribute ASYNC_REG of jtag_clear_overrun_1 : variable is "TRUE";
      attribute ASYNC_REG of jtag_busy_1          : variable is "TRUE";
    begin
      if bus2ip_clk'event and bus2ip_clk = '1' then  -- rising clock edge
        if bus2ip_resetn = '0' then                  -- synchronous reset (active low)
          dbgreg_access_lock   <= '0';
          dbgreg_force_lock    <= '0';
          dbgreg_unlocked      <= '0';
          jtag_axis_overrun    <= '0';
          jtag_access_lock_1   := '0';
          jtag_force_lock_1    := '0';
          jtag_clear_overrun_1 := '0';
          jtag_busy_1          := '0';
        else
          -- Unlock after last access for type "01"
          if state = data_done and type_lock = "01" then
            dbgreg_access_lock <= '0';
          end if;

          -- Write to Debug Access Control Register
          if bus2ip_wrce(4) = '1' then
            case bus2ip_data(19 downto 18) is
              when "00" =>                -- Release lock to abort atomic sequence
                dbgreg_access_lock <= '0';
              when "01" | "10" =>         -- Lock before first access
                if dbgreg_access_lock = '0' and jtag_busy_1 = '0' and jtag_access_lock_1 = '0' then
                  dbgreg_access_lock <= '1';
                end if;
              when "11" =>                -- Force access lock
                dbgreg_access_lock <= '1';
                dbgreg_force_lock  <= '1';
              -- coverage off
              when others =>
                null;
              -- coverage on
            end case;
          else
            dbgreg_force_lock <= '0';
          end if;
          jtag_access_lock_1 := JTAG_Access_Lock;

          -- JTAG force lock
          if jtag_force_lock_1 = '1' then
            dbgreg_access_lock <= '0';
            dbgreg_unlocked    <= '1';
          else
            dbgreg_unlocked    <= '0';
          end if;
          jtag_force_lock_1 := jtag_force_lock;

          -- JTAG overrun detection
          if selected = '1' and jtag_busy_1 = '1' then
            jtag_axis_overrun  <= '1';
          elsif jtag_clear_overrun_1 = '1' then
            jtag_axis_overrun  <= '0';
          end if;
          jtag_clear_overrun_1 := jtag_clear_overrun;
          jtag_busy_1          := jtag_busy;
        end if;
      end if;
    end process;

    DbgReg_Select <= selected;

    Old_MDM_SEL <= dbgreg_SEL     when selected = '1' else Old_MDM_SEL_Mux;
    TDI         <= dbgreg_TDI     when selected = '1' else JTAG_TDI;
    RESET       <= dbgreg_RESET   when selected = '1' else JTAG_RESET;
    SHIFT       <= dbgreg_SHIFT   when selected = '1' else JTAG_SHIFT;
    CAPTURE     <= dbgreg_CAPTURE when selected = '1' else JTAG_CAPTURE;
    JTAG_TDO    <= '0'            when selected = '1' else TDO;
  end generate Use_Dbg_Reg_Access;

  No_Dbg_Reg_Access : if (C_DBG_REG_ACCESS = 0) generate
  begin
    DbgReg_DRCK    <= '0';
    DbgReg_UPDATE  <= '0';
    DbgReg_Select  <= '0';

    dbgreg_ip2bus_rdack <= '0';
    dbgreg_ip2bus_wrack <= '0';
    dbgreg_ip2bus_error <= '0';
    dbgreg_ip2bus_data  <= (others => '0');

    dbgreg_access_lock <= '0';
    dbgreg_force_lock  <= '0';
    dbgreg_unlocked    <= '0';
    jtag_axis_overrun  <= '0';
    
    Old_MDM_SEL  <= Old_MDM_SEL_Mux;
    TDI          <= JTAG_TDI;
    RESET        <= JTAG_RESET;
    SHIFT        <= JTAG_SHIFT;
    CAPTURE      <= JTAG_CAPTURE;
    JTAG_TDO     <= TDO;
  end generate No_Dbg_Reg_Access;

  -----------------------------------------------------------------------------
  -- Trace: External Output, AXI Stream Output and AXI Master Output
  -----------------------------------------------------------------------------
  Use_Trace : if (C_TRACE_OUTPUT > 0) generate
    type TrData_Type is array(0 to 31) of std_logic_vector(0 to 35);

    signal Dbg_TrData  : TrData_Type;
    signal Dbg_TrValid : std_logic_vector(31 downto 0);
  begin

    More_Than_One_MB : if (C_MB_DBG_PORTS > 1) generate
      constant C_LOG2_MB_DBG_PORTS : natural := log2(C_MB_DBG_PORTS);

      signal index : std_logic_vector(C_LOG2_MB_DBG_PORTS-1 downto 0);
      signal valid : std_logic;
      signal idle  : std_logic;
    begin

      Arbiter_i : Arbiter
        generic map (
          Size      => C_MB_DBG_PORTS,                          -- [natural]
          Size_Log2 => C_LOG2_MB_DBG_PORTS)                     -- [natural]
        port map (
          Clk       => trace_clk_i,                             -- [in  std_logic]
          Reset     => trace_reset,                             -- [in  std_logic]
          Enable    => '0',                                     -- [in  std_logic]
          Requests  => Dbg_TrValid(C_MB_DBG_PORTS-1 downto 0),  -- [in  std_logic_vector(Size-1 downto 0)]
          Granted   => open,                                    -- [out std_logic_vector(Size-1 downto 0)]
          Valid_Sel => valid,                                   -- [out std_logic]
          Selected  => index                                    -- [out std_logic_vector(Size_Log2-1 downto 0)]
        );

      Arbiter_Keep: process (trace_clk_i) is
      begin  -- process Arbiter_Keep
        if trace_clk_i'event and trace_clk_i = '1' then  -- rising clock edge
          if trace_reset = '1' then                      -- synchronous reset (active high)
            trace_index(C_LOG2_MB_DBG_PORTS-1 downto 0) <= (others => '0');
            trace_valid <= '0';
            idle        <= '1';
          else
            if idle = '1' or trace_last_word = '1' then
              trace_index(C_LOG2_MB_DBG_PORTS-1 downto 0) <= index;
              trace_valid <= valid;
              idle        <= not valid;
            end if;
          end if;
        end if;
      end process Arbiter_Keep;

      trace_index(4 downto C_LOG2_MB_DBG_PORTS) <= (others => '0');

      trace_trdata <= Dbg_TrData(to_integer(unsigned(trace_index)));

      Assign_Ready: process (trace_trready, trace_index) is
      begin  -- process Assign_Ready
        Dbg_TrReady <= (others => '0');
        Dbg_TrReady(to_integer(unsigned(trace_index))) <= trace_trready;
      end process Assign_Ready;

    end generate More_Than_One_MB;

    Only_One_MB : if (C_MB_DBG_PORTS = 1) generate
    begin
      trace_index          <= "00000";
      trace_trdata         <= Dbg_TrData(0);
      trace_valid          <= Dbg_TrValid(0);
      Dbg_TrReady(0)       <= trace_trready;
      Dbg_TrReady(1 to 31) <= (others => '0');
    end generate Only_One_MB;

    No_MB : if (C_MB_DBG_PORTS = 0) generate
    begin
      trace_index  <= "00000";
      trace_trdata <= (others => '0');
      trace_valid  <= '0';
      Dbg_TrReady  <= (others => '0');
    end generate No_MB;

    Dbg_TrData(0)  <= Dbg_TrData_0;
    Dbg_TrData(1)  <= Dbg_TrData_1;
    Dbg_TrData(2)  <= Dbg_TrData_2;
    Dbg_TrData(3)  <= Dbg_TrData_3;
    Dbg_TrData(4)  <= Dbg_TrData_4;
    Dbg_TrData(5)  <= Dbg_TrData_5;
    Dbg_TrData(6)  <= Dbg_TrData_6;
    Dbg_TrData(7)  <= Dbg_TrData_7;
    Dbg_TrData(8)  <= Dbg_TrData_8;
    Dbg_TrData(9)  <= Dbg_TrData_9;
    Dbg_TrData(10) <= Dbg_TrData_10;
    Dbg_TrData(11) <= Dbg_TrData_11;
    Dbg_TrData(12) <= Dbg_TrData_12;
    Dbg_TrData(13) <= Dbg_TrData_13;
    Dbg_TrData(14) <= Dbg_TrData_14;
    Dbg_TrData(15) <= Dbg_TrData_15;
    Dbg_TrData(16) <= Dbg_TrData_16;
    Dbg_TrData(17) <= Dbg_TrData_17;
    Dbg_TrData(18) <= Dbg_TrData_18;
    Dbg_TrData(19) <= Dbg_TrData_19;
    Dbg_TrData(20) <= Dbg_TrData_20;
    Dbg_TrData(21) <= Dbg_TrData_21;
    Dbg_TrData(22) <= Dbg_TrData_22;
    Dbg_TrData(23) <= Dbg_TrData_23;
    Dbg_TrData(24) <= Dbg_TrData_24;
    Dbg_TrData(25) <= Dbg_TrData_25;
    Dbg_TrData(26) <= Dbg_TrData_26;
    Dbg_TrData(27) <= Dbg_TrData_27;
    Dbg_TrData(28) <= Dbg_TrData_28;
    Dbg_TrData(29) <= Dbg_TrData_29;
    Dbg_TrData(30) <= Dbg_TrData_30;
    Dbg_TrData(31) <= Dbg_TrData_31;

    Dbg_TrValid(0)  <= Dbg_TrValid_0;
    Dbg_TrValid(1)  <= Dbg_TrValid_1;
    Dbg_TrValid(2)  <= Dbg_TrValid_2;
    Dbg_TrValid(3)  <= Dbg_TrValid_3;
    Dbg_TrValid(4)  <= Dbg_TrValid_4;
    Dbg_TrValid(5)  <= Dbg_TrValid_5;
    Dbg_TrValid(6)  <= Dbg_TrValid_6;
    Dbg_TrValid(7)  <= Dbg_TrValid_7;
    Dbg_TrValid(8)  <= Dbg_TrValid_8;
    Dbg_TrValid(9)  <= Dbg_TrValid_9;
    Dbg_TrValid(10) <= Dbg_TrValid_10;
    Dbg_TrValid(11) <= Dbg_TrValid_11;
    Dbg_TrValid(12) <= Dbg_TrValid_12;
    Dbg_TrValid(13) <= Dbg_TrValid_13;
    Dbg_TrValid(14) <= Dbg_TrValid_14;
    Dbg_TrValid(15) <= Dbg_TrValid_15;
    Dbg_TrValid(16) <= Dbg_TrValid_16;
    Dbg_TrValid(17) <= Dbg_TrValid_17;
    Dbg_TrValid(18) <= Dbg_TrValid_18;
    Dbg_TrValid(19) <= Dbg_TrValid_19;
    Dbg_TrValid(20) <= Dbg_TrValid_20;
    Dbg_TrValid(21) <= Dbg_TrValid_21;
    Dbg_TrValid(22) <= Dbg_TrValid_22;
    Dbg_TrValid(23) <= Dbg_TrValid_23;
    Dbg_TrValid(24) <= Dbg_TrValid_24;
    Dbg_TrValid(25) <= Dbg_TrValid_25;
    Dbg_TrValid(26) <= Dbg_TrValid_26;
    Dbg_TrValid(27) <= Dbg_TrValid_27;
    Dbg_TrValid(28) <= Dbg_TrValid_28;
    Dbg_TrValid(29) <= Dbg_TrValid_29;
    Dbg_TrValid(30) <= Dbg_TrValid_30;
    Dbg_TrValid(31) <= Dbg_TrValid_31;
  end generate Use_Trace;

  Use_Trace_External_AXI_Master : if (C_TRACE_OUTPUT = 1 or C_TRACE_OUTPUT = 3) generate
    type ID_Type is array(boolean, integer range 1 to 4) of std_logic_vector(2 downto 0);

    constant C_ID : ID_Type :=
      (false => ("010", "001", "011", "100"),   -- C_USE_BSCAN = 0
       true  => ("001", "001", "001", "001"));  -- C_USE_BSCAN = 2

    -- 16 x 32 bit LUTROM
    type Mux_Select_Type is (Extra, Final, ID, D0, D1, D2, D3, S1, S2, S3);
    type Mux_Select_Array_Type is array (3 downto 0) of Mux_Select_Type;
    type Output_Select_Type is array(0 to 31) of Mux_Select_Array_Type;

    constant output_select : Output_Select_Type := (
      0      => (D2,    D1,    D0,    ID),
      1      => (D2,    D1,    D0,    S3),
      2      => (D1,    D0,    Extra, S3),
      3      => (Final, D0,    S3,    S2),

      4      => (Extra, S3,    S2,    S1),  -- Only saved, block trready
      5      => (D3,    D2,    D1,    D0),
      6      => (D3,    D2,    D1,    D0),
      7      => (Final, D1,    D0,    Extra),

      8      => (D0,    S3,    S2,    ID),
      9      => (Extra, S3,    S2,    S1),  -- Only saved, block trready
      10     => (D3,    D2,    D1,    D0),
      11     => (Final, D2,    D1,    D0),

      12     => (D1,    D0,    Extra, S3),
      13     => (D1,    D0,    S3,    S2),
      14     => (D0,    Extra, S3,    S2),
      15     => (Final, S3,    S2,    S1),  -- Only saved, block trready

      16     => (D2,    D1,    D0,    ID),
      17     => (D1,    D0,    Extra, S3),
      18     => (D1,    D0,    S3,    S2),
      19     => (Final, Extra, S3,    S2),  -- Only saved, block trready

      others => (D2,    D1,    D0,    ID)
    );

    attribute rom_style : string;
    attribute rom_style of output_select : constant is "distributed";

    constant block_trready : std_logic_vector(0 to 31) := "00001000010000010001000000000000";

    type Mux_Data_Select_Type is array(Mux_Select_Type) of std_logic_vector(7 downto 0);

    signal dbg_trdata_mux       : Mux_Data_Select_Type;
    signal frame_word_index     : std_logic_vector(0 to 4);
    signal frame_word_first     : std_logic;
    signal frame_word_last      : boolean;
    signal frame_word_next_last : boolean;
    signal output_select_data   : Mux_Select_Array_Type;
    signal block_trready_val    : std_logic;
    signal trace_data_0         : std_logic_vector(7  downto 0);
    signal trace_data_1         : std_logic_vector(7  downto 0);
    signal trace_data_2         : std_logic_vector(7  downto 0);
    signal trace_data_3         : std_logic_vector(7  downto 0);
    signal saved_extra          : std_logic_vector(7  downto 0);
    signal final_byte           : std_logic_vector(7  downto 0);
    signal saved_final          : std_logic_vector(5  downto 0);
    signal saved_trdata         : std_logic_vector(31 downto 8);
    signal trace_id             : std_logic_vector(7  downto 0);
  begin

    output_select_data <= output_select(to_integer(unsigned(frame_word_index)));
    block_trready_val  <= block_trready(to_integer(unsigned(frame_word_index)));

    dbg_trdata_mux <= (
      ID    => trace_id,
      Extra => saved_extra,
      Final => final_byte,
      D0    => trace_trdata(7  downto 0),
      D1    => trace_trdata(15 downto 8),
      D2    => trace_trdata(25 downto 18),
      D3    => trace_trdata(33 downto 26),
      S1    => saved_trdata(15 downto 8),
      S2    => saved_trdata(23 downto 16),
      S3    => saved_trdata(31 downto 24)
    );

    trace_data_0 <= dbg_trdata_mux(output_select_data(0));
    trace_data_1 <= dbg_trdata_mux(output_select_data(1));
    trace_data_2 <= dbg_trdata_mux(output_select_data(2));
    trace_data_3 <= dbg_trdata_mux(output_select_data(3));
    final_byte   <= trace_data_2(0) & trace_data_0(0) & saved_final;

    Mux_Output: process (trace_clk_i) is
      variable trace_data_0_lsb : std_logic;
    begin  -- process Mux_Output
      if trace_clk_i'event and trace_clk_i = '1' then  -- rising clock edge
        if trace_reset = '1' then                      -- synchronous reset (active high)
          trace_word       <= C_FF_SYNC_PACKET;
          saved_extra      <= (others => '0');
          saved_final      <= (others => '0');
          saved_trdata     <= (others => '0');
          frame_word_index <= (others => '0');
          frame_word_first <= '0';
          frame_word_last  <= false;
          trace_started    <= '0';
          trace_last_word  <= '0';
        else
          if (trace_valid = '1' and trace_stopped = '0' and trace_count_last = '1') or (trace_started = '1') then
            trace_last_word <= '0';
            trace_started   <= '1';
            if trace_ready = '1' or trace_started = '0' then
              if output_select_data(0) = ID then
                trace_data_0_lsb := '1';
              else
                trace_data_0_lsb := '0';
              end if;
              trace_word(7  downto 0)  <= trace_data_0(7 downto 1) & trace_data_0_lsb;
              trace_word(15 downto 8)  <= trace_data_1;
              trace_word(23 downto 16) <= trace_data_2(7 downto 1) & '0';
              trace_word(31 downto 24) <= trace_data_3;
              if block_trready_val = '0' then
                saved_extra  <= trace_trdata(35 downto 34) & trace_trdata(17 downto 16) & saved_extra(7 downto 4);
              end if;
              saved_final  <= trace_data_2(0) & trace_data_0(0) & saved_final(5 downto 2);
              saved_trdata <= trace_trdata(33 downto 18) & trace_trdata(15 downto 8);
              if frame_word_last then
                frame_word_index <= (others => '0');
                frame_word_first <= '1';
              else
                frame_word_index <= std_logic_vector(unsigned(frame_word_index) + 1);
                frame_word_first <= '0';
              end if;
              if frame_word_next_last then
                trace_last_word <= '1';
              end if;
              frame_word_last <= frame_word_next_last;
            end if;
            if trace_ready = '1' and frame_word_first = '1' then
              trace_word       <= C_FF_SYNC_PACKET;
              frame_word_index <= (others => '0');
              frame_word_first <= '0';
              frame_word_last  <= false;
              trace_started    <= '0';
            end if;
          else
            trace_word       <= C_FF_SYNC_PACKET;
            saved_extra      <= (others => '0');
            saved_final      <= (others => '0');
            saved_trdata     <= (others => '0');
            frame_word_index <= (others => '0');
            frame_word_first <= '0';
            frame_word_last  <= false;
            trace_started    <= '0';
            trace_last_word  <= '0';
          end if;
        end if;
      end if;
    end process Mux_Output;

    frame_word_next_last <= frame_word_index = "10010";  -- 20 32-bit words per packet = 16 36-bit words

    trace_id <= C_ID(C_USE_BSCAN = 2, C_JTAG_CHAIN) & trace_index;

    trace_trready <=
      (trace_valid and not trace_stopped and not trace_started) or                         -- first word
      (trace_ready and trace_started and not block_trready_val and not frame_word_first);  -- remaining words

  end generate Use_Trace_External_AXI_Master;

  Use_Trace_External : if (C_TRACE_OUTPUT = 1) generate
    type pattern_select_type is (ZERO, IDLE, ONE, PAT_FE, SHIFT, PAT_55, PAT_AA);
    type trig_type is array (natural range <>) of std_logic_vector(2 to 3);

    signal pattern_sel      : pattern_select_type := ZERO;
    signal pattern          : std_logic_vector(C_TRACE_DATA_WIDTH - 1 downto 0);
    signal next_pattern     : std_logic_vector(C_TRACE_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal delay_count      : std_logic_vector(0 to 7) := (others => '0');
    signal next_delay_count : std_logic_vector(0 to 7);
    signal delay_count_zero : boolean;
    signal sync_packet      : std_logic := '0';
    signal sync_count       : std_logic_vector(0 to 4)  := (others => '0');
    signal testing          : std_logic := '0';
    signal test_ctl         : std_logic := '1';
    signal trace_clk_div2   : std_logic := '0';
    signal trace_data_i     : std_logic_vector(C_TRACE_DATA_WIDTH-1 downto 0)  := (others => '0');
    signal trace_ctl_i      : std_logic := '1';
    signal trace_ctl_o      : std_logic := '1';
    signal trace_ctl_next   : std_logic;
    signal trace_trig       : trig_type(0 to 31);
    signal trig_on          : std_logic := '0';
    signal trig_pending     : std_logic := '0';
    signal trig_counting    : std_logic := '0';
    signal trig_count       : std_logic_vector(0 to 16) := (0 => '1', others => '0');
    signal trig_count_init  : std_logic_vector(0 to 16);

    attribute dont_touch : string;
    attribute dont_touch of trace_ctl_i : signal is "true";  -- Keep FF for internal use
    attribute dont_touch of trace_ctl_o : signal is "true";  -- Keep FF for IOB insertion
  begin

    -- Generate test patterns
    pattern(0) <= next_pattern(C_TRACE_DATA_WIDTH - 1) when pattern_sel = SHIFT  else
                 '1'                                   when pattern_sel = IDLE   or
                                                            pattern_sel = ONE    or
                                                            pattern_sel = PAT_55 else
                 '0';

    Gen_Test_Pattern: for I in 1 to C_TRACE_DATA_WIDTH - 1 generate
    begin
      pattern(I) <= next_pattern(I-1) when (pattern_sel = SHIFT)                    else
                    '1'               when (pattern_sel = ONE)                      or
                                           (pattern_sel = PAT_FE)                   or
                                           (pattern_sel = PAT_55 and (I mod 2) = 0) or
                                           (pattern_sel = PAT_AA and (I mod 2) = 1) else
                    '0';
    end generate Gen_Test_Pattern;

    Pattern_DFF: process (trace_clk_i) is
      type state_type is (IDLE, STARTING, WALKING_1, WALKING_0, PAT_AA, PAT_55, PAT_FF, PAT_00);

      variable state : state_type := IDLE;
    begin  -- process Pattern_DFF
      if trace_clk_i'event and trace_clk_i = '1' then  -- rising clock edge
        if trace_reset = '1' then                      -- synchronous reset (active high)
          pattern_sel  <= ZERO;
          delay_count  <= trace_delay;
          testing      <= '0';
          test_ctl     <= '1';
          state        := IDLE;
          next_pattern <= (others => '0');
        else
          case state is
            when IDLE =>
              pattern_sel <= ZERO;
              delay_count <= trace_delay;
              testing     <= '0';
              test_ctl    <= '1';
              if trace_test_start = '1' then
                state := STARTING;
              end if;
            when STARTING =>
              pattern_sel <= ZERO;
              delay_count <= trace_delay;
              if trace_started = '0' and trace_count_last = '1' then
                if trace_test_pattern(3)    = '1' then  -- Alternating FF/00
                  pattern_sel <= ONE;
                  state := PAT_FF;
                elsif trace_test_pattern(2) = '1' then  -- Alternating AA/55
                  pattern_sel <= PAT_55;
                  state := PAT_55;
                elsif trace_test_pattern(1) = '1' then  -- Walking 0s
                  pattern_sel <= PAT_FE;
                  state := WALKING_0;
                elsif trace_test_pattern(0) = '1' then  -- Walking 1s
                  pattern_sel <= IDLE;
                  state := WALKING_1;
                end if;
                testing  <= '1';
                test_ctl <= '0';
              end if;
            when PAT_FF =>
              delay_count <= next_delay_count;
              if trace_test_stop = '1' then
                test_ctl <= '1';
                pattern_sel <= IDLE;
                state := IDLE;
              elsif delay_count_zero then
                delay_count <= trace_delay;
                if trace_test_pattern(2)    = '1' then  -- Alternating AA/55
                  pattern_sel <= PAT_55;
                  state := PAT_55;
                elsif trace_test_pattern(1) = '1' then  -- Walking 0s
                  pattern_sel <= PAT_FE;
                  state := WALKING_0;
                elsif trace_test_pattern(0) = '1' then  -- Walking 1s
                  pattern_sel <= IDLE;
                  state := WALKING_1;
                else
                  test_ctl <= '1';
                  pattern_sel <= IDLE;
                  state := IDLE;
                end if;
              else
                pattern_sel <= ZERO;
                state := PAT_00;
              end if;
            when PAT_00 =>
              delay_count <= next_delay_count;
              if trace_test_stop = '1' then
                test_ctl <= '1';
                pattern_sel <= IDLE;
                state := IDLE;
              elsif delay_count_zero then
                delay_count <= trace_delay;
                if trace_test_pattern(2)    = '1' then  -- Alternating AA/55
                  pattern_sel <= PAT_55;
                  state := PAT_55;
                elsif trace_test_pattern(1) = '1' then  -- Walking 0s
                  pattern_sel <= PAT_FE;
                  state := WALKING_0;
                elsif trace_test_pattern(0) = '1' then  -- Walking 1s
                  pattern_sel <= IDLE;
                  state := WALKING_1;
                else
                  test_ctl <= '1';
                  pattern_sel <= IDLE;
                  state := IDLE;
                end if;
              else
                pattern_sel <= ONE;
                state := PAT_FF;
              end if;
            when PAT_55 =>
              delay_count <= next_delay_count;
              if trace_test_stop = '1' then
                test_ctl <= '1';
                pattern_sel <= IDLE;
                state := IDLE;
              elsif delay_count_zero then
                delay_count <= trace_delay;
                if trace_test_pattern(1)    = '1' then  -- Walking 0s
                  pattern_sel <= PAT_FE;
                  state := WALKING_0;
                elsif trace_test_pattern(0) = '1' then  -- Walking 1s
                  pattern_sel <= IDLE;
                  state := WALKING_1;
                else
                  test_ctl <= '1';
                  pattern_sel <= IDLE;
                  state := IDLE;
                end if;
              else
                pattern_sel <= PAT_AA;
                state := PAT_AA;
              end if;
            when PAT_AA =>
              delay_count <= next_delay_count;
              if trace_test_stop = '1' then
                test_ctl <= '1';
                pattern_sel <= IDLE;
                state := IDLE;
              elsif delay_count_zero then
                delay_count <= trace_delay;
                if trace_test_pattern(1)    = '1' then  -- Walking 0s
                  pattern_sel <= PAT_FE;
                  state := WALKING_0;
                elsif trace_test_pattern(0) = '1' then  -- Walking 1s
                  pattern_sel <= IDLE;
                  state := WALKING_1;
                else
                  test_ctl <= '1';
                  pattern_sel <= IDLE;
                  state := IDLE;
                end if;
              else
                pattern_sel <= PAT_55;
                state := PAT_55;
              end if;
            when WALKING_0 =>
              delay_count <= next_delay_count;
              pattern_sel <= SHIFT;
              if trace_test_stop = '1' then
                test_ctl <= '1';
                pattern_sel <= IDLE;
                state := IDLE;
              elsif delay_count_zero then
                delay_count <= trace_delay;
                pattern_sel <= IDLE;
                if trace_test_pattern(0) = '1' then  -- Walking 1s
                  state := WALKING_1;
                else
                  test_ctl <= '1';
                  state := IDLE;
                end if;
              end if;
            when WALKING_1 =>
              delay_count <= next_delay_count;
              pattern_sel <= SHIFT;
              if delay_count_zero or trace_test_stop = '1' then
                test_ctl <= '1';
                pattern_sel <= IDLE;
                state := IDLE;
              end if;
            -- coverage off
            when others =>
              null;
            -- coverage on
          end case;

          next_pattern <= pattern;
        end if;
      end if;
    end process Pattern_DFF;

    next_delay_count <= std_logic_vector(unsigned(delay_count) - 1);
    delay_count_zero <= delay_count = (delay_count'range => '0') and trace_test_timed = '1';

    -- Output data or test pattern according to width
    Has_Full_Width: if C_TRACE_DATA_WIDTH = 32 generate
    begin

      Data_Output: process (trace_clk_i) is
      begin  -- process Data_Output
        if trace_clk_i'event and trace_clk_i = '1' then  -- rising clock edge
          if trace_reset = '1' then                      -- synchronous reset (active high)
            trace_data_i    <= (others => '0');
            trace_data_i(0) <= '1';
            trace_ctl_i     <= '1';
            trace_ctl_o     <= '1';
          else
            if testing = '0' then
              trace_ctl_i  <= trace_ctl_next;
              trace_ctl_o  <= trace_ctl_next;
              trace_data_i <= trace_word;
              if trace_ctl_next = '1' then
                trace_data_i    <= (others => '0');
                trace_data_i(0) <= '1';              -- Indicates trace disable when TRACE_CTL = '1'
                if trig_on = '1' and sync_packet = '0' then
                  trace_data_i(1 downto 0) <= "10";  -- Indicates trigger when TRACE_CTL = '1'
                end if;
              end if;
            else
              trace_ctl_i  <= test_ctl;
              trace_ctl_o  <= test_ctl;
              trace_data_i <= pattern(C_TRACE_DATA_WIDTH - 1 downto 0);
            end if;
          end if;
        end if;
      end process Data_Output;

      trace_ready      <= not testing;
      trace_count_last <= '1';

    end generate Has_Full_Width;

    Not_Full_Width: if C_TRACE_DATA_WIDTH < 32 generate
      constant C_COUNTER_WIDTH : integer := log2(32 / C_TRACE_DATA_WIDTH);

      signal data_count      : std_logic_vector(0 to C_COUNTER_WIDTH - 1) := (others => '0');
      signal data_count_next : std_logic_vector(0 to C_COUNTER_WIDTH - 1);
      signal last_word_keep  : std_logic := '0'; 
      signal last_word_next  : std_logic := '0';
    begin

      Data_Output: process (trace_clk_i) is
        variable data_index : integer range 0 to 32 / C_TRACE_DATA_WIDTH - 1;
      begin  -- process Data_Output
        if trace_clk_i'event and trace_clk_i = '1' then  -- rising clock edge
          if trace_reset = '1' then                      -- synchronous reset (active high)
            trace_data_i    <= (others => '0');
            trace_data_i(0) <= '1';
            data_count      <= (others => '0');
            trace_ctl_i     <= '1';
            trace_ctl_o     <= '1';
            last_word_keep  <= '0';
            last_word_next  <= '0';
          else
            if testing = '0' then
              trace_ctl_i  <= trace_ctl_next;
              trace_ctl_o  <= trace_ctl_next;
              data_index   := to_integer(unsigned(data_count));
              trace_data_i <= trace_word(data_index * C_TRACE_DATA_WIDTH + C_TRACE_DATA_WIDTH - 1 downto
                                         data_index * C_TRACE_DATA_WIDTH);
              if trace_last_word = '1' then
                last_word_keep <= '1';
              end if;
              if trace_count_last = '1' then
                data_count     <= (others => '0');
                last_word_next <= last_word_keep;
                last_word_keep <= '0';
              else
                data_count <= data_count_next;
              end if;
              if trace_ctl_next = '1' then
                trace_data_i    <= (others => '0');
                trace_data_i(0) <= '1';              -- Indicates trace disable when TRACE_CTL = '1'
                if trig_on = '1' and sync_packet = '0' then
                  trace_data_i(1 downto 0) <= "10";  -- Indicates trigger when TRACE_CTL = '1'
                end if;
              end if;
            else
              trace_ctl_i  <= test_ctl;
              trace_ctl_o  <= test_ctl;
              trace_data_i <= pattern(C_TRACE_DATA_WIDTH - 1 downto 0);
              data_count   <= (others => '0');
            end if;
          end if;
        end if;
      end process Data_Output;

      data_count_next  <= std_logic_vector(unsigned(data_count) + 1);

      trace_count_last <= '1' when data_count = (data_count'range => '1') else '0';
      trace_ready      <= (not trace_ctl_i) and trace_count_last;

    end generate Not_Full_Width;

    trace_ctl_next <= not (trace_started or sync_packet);

    -- Synchronize reset
    Reset_DFF: process (trace_clk_i) is
      variable sample : std_logic_vector(0 to 1) := "11";

      attribute ASYNC_REG : string;
      attribute ASYNC_REG of sample : variable is "TRUE";
    begin  -- process Sync_Reset
      if trace_clk_i'event and trace_clk_i = '1' then  -- rising clock edge
        trace_reset <= sample(1);
        sample(1)   := sample(0);
        sample(0)   := Debug_SYS_Rst_i or config_reset_i;
      end if;
    end process Reset_DFF;

    -- Generate half frequency output clock
    Use_PLL: if C_TRACE_CLK_OUT_PHASE /= 0 generate
      constant C_CLKFBOUT_MULT  : integer := (800000000 + C_TRACE_CLK_FREQ_HZ - 1000000) / C_TRACE_CLK_FREQ_HZ;
      constant C_CLKIN_PERIOD   : real    := 1000000000.0 / real(C_TRACE_CLK_FREQ_HZ);
      constant C_CLKOUT0_DIVIDE : integer := C_CLKFBOUT_MULT * 2;
      constant C_CLKOUT0_PHASE  : real    := real(C_TRACE_CLK_OUT_PHASE);

      signal trace_clk_o        : std_logic;
      signal trace_clk_fbin     : std_logic;
      signal trace_clk_fbout    : std_logic;
    begin

      PLL_TRACE_CLK : PLLE2_BASE
      generic map (
         BANDWIDTH          => "OPTIMIZED",
         CLKFBOUT_MULT      => C_CLKFBOUT_MULT,
         CLKFBOUT_PHASE     => 0.000,
         CLKIN1_PERIOD      => C_CLKIN_PERIOD,
         CLKOUT0_DIVIDE     => C_CLKOUT0_DIVIDE,
         CLKOUT0_DUTY_CYCLE => 0.500,
         CLKOUT0_PHASE      => C_CLKOUT0_PHASE,
         CLKOUT1_DIVIDE     => 1,
         CLKOUT1_DUTY_CYCLE => 0.500,
         CLKOUT1_PHASE      => 0.000,
         CLKOUT2_DIVIDE     => 1,
         CLKOUT2_DUTY_CYCLE => 0.500,
         CLKOUT2_PHASE      => 0.000,
         CLKOUT3_DIVIDE     => 1,
         CLKOUT3_DUTY_CYCLE => 0.500,
         CLKOUT3_PHASE      => 0.000,
         CLKOUT4_DIVIDE     => 1,
         CLKOUT4_DUTY_CYCLE => 0.500,
         CLKOUT4_PHASE      => 0.000,
         CLKOUT5_DIVIDE     => 1,
         CLKOUT5_DUTY_CYCLE => 0.500,
         CLKOUT5_PHASE      => 0.000,
         DIVCLK_DIVIDE      => 1,
         REF_JITTER1        => 0.010,
         STARTUP_WAIT       => "FALSE"
      )
      port map (
         CLKFBOUT => trace_clk_fbout,
         CLKOUT0  => trace_clk_div2,
         CLKOUT1  => open,
         CLKOUT2  => open,
         CLKOUT3  => open,
         CLKOUT4  => open,
         CLKOUT5  => open,
         LOCKED   => open,
         CLKFBIN  => trace_clk_fbin,
         CLKIN1   => trace_clk_i,
         PWRDWN   => '0',
         RST      => trace_reset
      );

      BUFG_TRACE_CLK_FB : BUFG
      port map (
        O => trace_clk_fbin,
        I => trace_clk_fbout
      );

      BUFG_TRACE_CLK : BUFG
      port map (
        O => trace_clk_o,
        I => trace_clk_div2
      );

      TRACE_CLK_OUT <= trace_clk_o;

    end generate Use_PLL;

    No_PLL: if C_TRACE_CLK_OUT_PHASE = 0 generate
      signal trace_clk_div2 : std_logic := '0';
      signal trace_clk_o    : std_logic := '0';

      attribute dont_touch : string;
      attribute dont_touch of trace_clk_o : signal is "true";  -- Keep FF for IOB insertion
    begin

      TRACE_CLK_OUT_DFF: process (trace_clk_i) is
      begin  -- process TRACE_CLK_OUT_DFF
        if trace_clk_i'event and trace_clk_i = '1' then  -- rising clock edge
          trace_clk_div2 <= not trace_clk_div2;
          trace_clk_o    <= trace_clk_div2;
        end if;
      end process TRACE_CLK_OUT_DFF;

      TRACE_CLK_OUT <= trace_clk_o;  -- Any clock delay, phase shift or buffering is done outside MDM

    end generate No_PLL;

    TRACE_CTL   <= trace_ctl_o;
    TRACE_DATA  <= trace_data_i;

    trace_clk_i <= TRACE_CLK;  -- Any clock doubling from external port is done outside MDM

    -- Generate synchronization packets
    Sync_Gen: process (trace_clk_i) is
    begin  -- process Sync_Gen
      if trace_clk_i'event and trace_clk_i = '1' then  -- rising clock edge
        if trace_reset = '1' then                      -- synchronous reset (active high)
          sync_packet <= '0';
          sync_count  <= (others => '0');
        else
          if sync_count(0) = '1' then
            sync_count  <= (others => '0');
            sync_packet <= '1';
          elsif trace_last_word = '1' then
            sync_count <= std_logic_vector(unsigned(sync_count) + 1);
          end if;
          if trace_started = '0' and sync_packet = '1' and trace_count_last = '1' then
            sync_packet <= '0';
          end if;
        end if;
      end if;
    end process Sync_Gen;

    -- Generate trigger
    Tigger_Detect: process (trace_clk_i) is
      variable sample   : trig_type(0 to C_MB_DBG_PORTS - 1) := (others => (others => '0'));
      variable sample_1 : trig_type(0 to C_MB_DBG_PORTS - 1) := (others => (others => '0'));
      variable sample_2 : trig_type(0 to C_MB_DBG_PORTS - 1) := (others => (others => '0'));

      attribute ASYNC_REG : string;
      attribute ASYNC_REG of sample   : variable is "TRUE";
      attribute ASYNC_REG of sample_1 : variable is "TRUE";
    begin  -- process Tigger_Detect
      if trace_clk_i'event and trace_clk_i = '1' then  -- rising clock edge
        if trace_reset = '1' then                      -- synchronous reset (active high)
          trig_on       <= '0';
          trig_pending  <= '0';
          trig_counting <= '0';
          trig_count    <= trig_count_init;
          sample_2      := (others => (others => '0'));
          sample_1      := (others => (others => '0'));
          sample        := (others => (others => '0'));
        else
          -- Sample and edge-detect triggers
          for I in 0 to C_MB_DBG_PORTS - 1 loop
            if sample_2(I)(2) = '0' and sample_1(I)(2) = '1' then
              -- Trigger on trace stop, or start counting on trace stop
              trig_pending  <= trig_pending  or trace_test_pattern(0);
              trig_counting <= trig_counting or trace_test_pattern(1);
            end if;
            if sample_2(I)(3) = '0' and sample_1(I)(3) = '1' then
              -- Trigger on trace start, or start counting on trace start
              trig_pending  <= trig_pending  or trace_test_pattern(2);
              trig_counting <= trig_counting or trace_test_pattern(3);
            end if;
          end loop;
          sample_2 := sample_1;
          sample_1 := sample;
          sample   := trace_trig(0 to C_MB_DBG_PORTS - 1);

          -- Decrement trigger count
          if trig_counting = '1' then
            if trig_count(0) = '0' then
              trig_count    <= trig_count_init;
              trig_counting <= '0';
              trig_pending  <= '1';
            else
              trig_count <= std_logic_vector(unsigned(trig_count) - 1);
            end if;
          else
            trig_count <= trig_count_init;
          end if;

          -- Pending trigger output
          if testing = '0' and trace_ctl_i = '1' and sync_packet = '0' and trace_count_last = '1' then
            trig_on      <= trig_pending;
            trig_pending <= '0';
          else
            trig_on      <= '0';
          end if;
        end if;
      end if;
    end process Tigger_Detect;

    trig_count_init <= '1' & trace_delay & "00000000";

    trace_trig(0)  <= Dbg_Trig_In_0(2 to 3);
    trace_trig(1)  <= Dbg_Trig_In_1(2 to 3);
    trace_trig(2)  <= Dbg_Trig_In_2(2 to 3);
    trace_trig(3)  <= Dbg_Trig_In_3(2 to 3);
    trace_trig(4)  <= Dbg_Trig_In_4(2 to 3);
    trace_trig(5)  <= Dbg_Trig_In_5(2 to 3);
    trace_trig(6)  <= Dbg_Trig_In_6(2 to 3);
    trace_trig(7)  <= Dbg_Trig_In_7(2 to 3);
    trace_trig(8)  <= Dbg_Trig_In_8(2 to 3);
    trace_trig(9)  <= Dbg_Trig_In_9(2 to 3);
    trace_trig(10) <= Dbg_Trig_In_10(2 to 3);
    trace_trig(11) <= Dbg_Trig_In_11(2 to 3);
    trace_trig(12) <= Dbg_Trig_In_12(2 to 3);
    trace_trig(13) <= Dbg_Trig_In_13(2 to 3);
    trace_trig(14) <= Dbg_Trig_In_14(2 to 3);
    trace_trig(15) <= Dbg_Trig_In_15(2 to 3);
    trace_trig(16) <= Dbg_Trig_In_16(2 to 3);
    trace_trig(17) <= Dbg_Trig_In_17(2 to 3);
    trace_trig(18) <= Dbg_Trig_In_18(2 to 3);
    trace_trig(19) <= Dbg_Trig_In_19(2 to 3);
    trace_trig(20) <= Dbg_Trig_In_20(2 to 3);
    trace_trig(21) <= Dbg_Trig_In_21(2 to 3);
    trace_trig(22) <= Dbg_Trig_In_22(2 to 3);
    trace_trig(23) <= Dbg_Trig_In_23(2 to 3);
    trace_trig(24) <= Dbg_Trig_In_24(2 to 3);
    trace_trig(25) <= Dbg_Trig_In_25(2 to 3);
    trace_trig(26) <= Dbg_Trig_In_26(2 to 3);
    trace_trig(27) <= Dbg_Trig_In_27(2 to 3);
    trace_trig(28) <= Dbg_Trig_In_28(2 to 3);
    trace_trig(29) <= Dbg_Trig_In_29(2 to 3);
    trace_trig(30) <= Dbg_Trig_In_30(2 to 3);
    trace_trig(31) <= Dbg_Trig_In_31(2 to 3);

    -- Unused
    M_AXIS_TDATA     <= (others => '0');
    M_AXIS_TID       <= (others => '0');
    M_AXIS_TVALID    <= '0';
    Master_dwr_data  <= (others => '0');
    Master_dwr_start <= '0';
  end generate Use_Trace_External;

  Use_Trace_AXI_Stream : if (C_TRACE_OUTPUT = 2) generate
    type ID_Type is array(boolean, integer range 1 to 4) of std_logic_vector(1 downto 0);

    constant C_ID : ID_Type :=
      (false => ("01", "00", "10", "11"),   -- C_USE_BSCAN = 0
       true  => ("00", "00", "00", "00"));  -- C_USE_BSCAN = 2

    -- 12 x 32 bit LUTROM
    type Mux_Select_Type is (Extra, D0, D1, D2, D3, S1, S2, S3);
    type Mux_Select_Array_Type is array (3 downto 0) of Mux_Select_Type;
    type Output_Select_Type is array(0 to 31) of Mux_Select_Array_Type;

    constant output_select : Output_Select_Type := (
      0      => (D3,    D2,    D1,    D0),
      1      => (D3,    D2,    D1,    D0),
      2      => (D2,    D1,    D0,    Extra),
      3      => (D2,    D1,    D0,    S3),

      4      => (D1,    D0,    Extra, S3),
      5      => (D1,    D0,    S3,    S2),
      6      => (D0,    Extra, S3,    S2),
      7      => (D0,    S3,    S2,    S1),

      8      => (Extra, S3,    S2,    S1),  -- Only saved, block trready

      9      => (D3,    D2,    D1,    D0),
      10     => (D3,    D2,    D1,    D0),
      11     => (D2,    D1,    D0,    Extra),
      12     => (D2,    D1,    D0,    S3),

      13     => (D1,    D0,    Extra, S3),
      14     => (D1,    D0,    S3,    S2),
      15     => (D0,    Extra, S3,    S2),
      16     => (D0,    S3,    S2,    S1),

      17     => (Extra, S3,    S2,    S1),  -- Only saved, block trready

      others => (Extra, Extra, Extra, Extra)
    );

    attribute rom_style : string;
    attribute rom_style of output_select : constant is "distributed";

    constant block_trready : std_logic_vector(0 to 31) := "00000000100000000100000000000000";

    type Mux_Data_Select_Type is array(Mux_Select_Type) of std_logic_vector(7 downto 0);

    signal dbg_trdata_mux     : Mux_Data_Select_Type;
    signal frame_word_index   : std_logic_vector(0 to 4);
    signal frame_word_first   : std_logic;
    signal output_select_data : Mux_Select_Array_Type;
    signal block_trready_val  : std_logic;
    signal trace_data_0       : std_logic_vector(7  downto 0);
    signal trace_data_1       : std_logic_vector(7  downto 0);
    signal trace_data_2       : std_logic_vector(7  downto 0);
    signal trace_data_3       : std_logic_vector(7  downto 0);
    signal saved_extra        : std_logic_vector(7  downto 0);
    signal saved_trdata       : std_logic_vector(31 downto 8);
    signal delay_count        : std_logic_vector(0  to 7);
    signal delay_zero         : std_logic;
    signal trace_id           : std_logic_vector(6  downto 0);
    signal trace_tvalid       : std_logic;
  begin

    output_select_data <= output_select(to_integer(unsigned(frame_word_index)));
    block_trready_val  <= block_trready(to_integer(unsigned(frame_word_index)));

    dbg_trdata_mux <= (
      Extra => saved_extra,
      D0    => trace_trdata(7  downto 0),
      D1    => trace_trdata(15 downto 8),
      D2    => trace_trdata(25 downto 18),
      D3    => trace_trdata(33 downto 26),
      S1    => saved_trdata(15 downto 8),
      S2    => saved_trdata(23 downto 16),
      S3    => saved_trdata(31 downto 24)
    );

    trace_data_0 <= dbg_trdata_mux(output_select_data(0));
    trace_data_1 <= dbg_trdata_mux(output_select_data(1));
    trace_data_2 <= dbg_trdata_mux(output_select_data(2));
    trace_data_3 <= dbg_trdata_mux(output_select_data(3));

    Mux_Output: process (trace_clk_i) is
    begin  -- process Mux_Output
      if trace_clk_i'event and trace_clk_i = '1' then  -- rising clock edge
        if trace_reset = '1' then                      -- synchronous reset (active high)
          trace_word       <= (others => '0');
          saved_extra      <= (others => '0');
          saved_trdata     <= (others => '0');
          trace_started    <= '0';
          trace_last_word  <= '0';
          trace_tvalid     <= '0';
          frame_word_index <= (others => '0');
          frame_word_first <= '0';
        else
          if (trace_valid = '1' or trace_started = '1') and (delay_zero = '1') then
            trace_last_word <= '0';
            trace_started   <= '1';
            trace_tvalid    <= '1';
            if trace_ready = '1' or trace_started = '0' then
              trace_word(7  downto 0)  <= trace_data_0;
              trace_word(15 downto 8)  <= trace_data_1;
              trace_word(23 downto 16) <= trace_data_2;
              trace_word(31 downto 24) <= trace_data_3;
              saved_extra  <= trace_trdata(35 downto 34) & trace_trdata(17 downto 16) & saved_extra(7 downto 4);
              saved_trdata <= trace_trdata(33 downto 18) & trace_trdata(15 downto 8);
              if (frame_word_index = "10001") then  -- 18 32-bit words per packet = 16 36-bit words
                frame_word_index <= (others => '0');
                trace_started    <= '0';
                frame_word_first <= '1';
              else
                frame_word_index <= std_logic_vector(unsigned(frame_word_index) + 1);
                frame_word_first <= '0';
              end if;
              if frame_word_index = "10000" then -- 18 32-bit words per packet = 16 36-bit words
                trace_last_word <= '1';
              end if;
            end if;
            if trace_ready = '1' and frame_word_first = '1' then
              frame_word_first <= '0';
            end if;
          else
            trace_tvalid     <= '0';
            frame_word_first <= '0';
          end if;
        end if;
      end if;
    end process Mux_Output;

    Delay_Counter: process (trace_clk_i) is
    begin  -- process Delay_Counter
      if trace_clk_i'event and trace_clk_i = '1' then  -- rising clock edge
        if trace_reset = '1' then                      -- synchronous reset (active high)
          delay_count <= trace_delay;
          delay_zero  <= '1';
        else
          if trace_delay = (trace_delay'range => '0') then
            delay_count <= trace_delay;
            delay_zero  <= '1';
          elsif (trace_valid = '1' or trace_started = '1') and (delay_zero = '1') and
                (trace_ready = '1' or trace_started = '0') then
            delay_count <= trace_delay;
            delay_zero  <= '0';
          elsif delay_count = (delay_count'range => '0') then
            delay_zero  <= '1';
          else
            delay_count <= std_logic_vector(unsigned(delay_count) - 1);
            delay_zero  <= '0';
          end if;
        end if;
      end if;
    end process Delay_Counter;

    Trace_ID_Output: process (trace_clk_i) is
    begin  -- process Trace_ID_Output
      if trace_clk_i'event and trace_clk_i = '1' then  -- rising clock edge
        if trace_reset = '1' then                      -- synchronous reset (active high)
          trace_id <= (others => '0');
        else
          trace_id <= C_ID(C_USE_BSCAN = 2, C_JTAG_CHAIN) & trace_index;
        end if;
      end if;
    end process Trace_ID_Output;

    M_AXIS_TDATA     <= trace_word;
    M_AXIS_TVALID    <= trace_tvalid;
    M_AXIS_TID       <= trace_id(C_M_AXIS_ID_WIDTH-1 downto 0);

    trace_clk_i      <= M_AXIS_ACLK;
    trace_reset      <= not M_AXIS_ARESETN;
    trace_ready      <= M_AXIS_TREADY;
    trace_trready    <=
      (trace_valid and not trace_started and delay_zero) or                                              -- first word
      (trace_ready and trace_started and not block_trready_val and not frame_word_first and delay_zero); -- remaining

    -- Unused
    TRACE_CLK_OUT    <= '0';
    TRACE_CTL        <= '1';
    TRACE_DATA       <= (others => '0');
    Master_dwr_data  <= (others => '0');
    Master_dwr_start <= '0';
    trace_count_last <= '0';
  end generate Use_Trace_AXI_Stream;

  Use_Trace_AXI_Master : if (C_TRACE_OUTPUT = 3) generate
  begin
    Master_dwr_data  <= trace_word;
    Master_dwr_start <= (trace_valid and not trace_stopped) or trace_started;

    trace_clk_i      <= M_AXI_ACLK;
    trace_reset      <= not M_AXI_ARESETN;
    trace_ready      <= Master_dwr_next;
    trace_count_last <= '1';

    -- Unused
    M_AXIS_TDATA     <= (others => '0');
    M_AXIS_TID       <= (others => '0');
    M_AXIS_TVALID    <= '0';
    TRACE_CLK_OUT    <= '0';
    TRACE_CTL        <= '1';
    TRACE_DATA       <= (others => '0');
  end generate Use_Trace_AXI_Master;

  No_Trace : if (C_TRACE_OUTPUT = 0) generate
  begin
    Dbg_TrReady      <= (others => '0');

    trace_clk_i      <= '0';
    trace_reset      <= '0';
    trace_word       <= (others => '0');
    trace_index      <= (others => '0');
    trace_trdata     <= (others => '0');
    trace_valid      <= '0';
    trace_last_word  <= '0';
    trace_ready      <= '0';
    trace_trready    <= '0';
    trace_started    <= '0';
    trace_count_last <= '0';

    M_AXIS_TDATA     <= (others => '0');
    M_AXIS_TID       <= (others => '0');
    M_AXIS_TVALID    <= '0';

    TRACE_CLK_OUT    <= '0';
    TRACE_CTL        <= '1';
    TRACE_DATA       <= (others => '0');

    Master_dwr_data  <= (others => '0');
    Master_dwr_start <= '0';
  end generate No_Trace;

  Dbg_TrClk <= trace_clk_i;

  ---------------------------------------------------------------------------
  -- Instantiating the receive and transmit modules
  ---------------------------------------------------------------------------
  JTAG_CONTROL_I : JTAG_CONTROL
    generic map (
      C_MB_DBG_PORTS      => C_MB_DBG_PORTS,
      C_USE_CONFIG_RESET  => C_USE_CONFIG_RESET,
      C_DBG_REG_ACCESS    => C_DBG_REG_ACCESS,
      C_DBG_MEM_ACCESS    => C_DBG_MEM_ACCESS,
      C_M_AXI_ADDR_WIDTH  => C_M_AXI_ADDR_WIDTH,
      C_M_AXI_DATA_WIDTH  => C_M_AXI_DATA_WIDTH,
      C_USE_CROSS_TRIGGER => C_USE_CROSS_TRIGGER,
      C_USE_UART          => C_USE_UART,
      C_UART_WIDTH        => C_UART_WIDTH,
      C_TRACE_OUTPUT      => C_TRACE_OUTPUT,
      C_EN_WIDTH          => C_EN_WIDTH
    )
    port map (
      Config_Reset    => config_reset_i,   -- [in  std_logic]
      Scan_Reset_Sel  => Scan_Reset_Sel,   -- [in  std_logic]
      Scan_Reset      => Scan_Reset,       -- [in  std_logic]

      Clk             => bus_clk,          -- [in  std_logic]
      Rst             => bus_rst,          -- [in  std_logic]

      Clear_Ext_BRK   => clear_Ext_BRK,    -- [in  std_logic]
      Ext_BRK         => Ext_BRK,          -- [out  std_logic]
      Ext_NM_BRK      => Ext_NM_BRK,       -- [out  std_logic]
      Debug_SYS_Rst   => Debug_SYS_Rst_i,  -- [out  std_logic]
      Debug_Rst       => Debug_Rst_i,      -- [out  std_logic]

      Read_RX_FIFO    => read_RX_FIFO,     -- [in  std_logic]
      Reset_RX_FIFO   => reset_RX_FIFO,    -- [in  std_logic]
      RX_Data         => rx_Data,          -- [out std_logic_vector(0 to 7)]
      RX_Data_Present => rx_Data_Present,  -- [out std_logic]
      RX_Buffer_Full  => rx_Buffer_Full,   -- [out std_logic]

      Write_TX_FIFO   => write_TX_FIFO,    -- [in  std_logic]
      Reset_TX_FIFO   => reset_TX_FIFO,    -- [in  std_logic]
      TX_Data         => tx_Data,          -- [in  std_logic_vector(0 to 7)]
      TX_Buffer_Full  => tx_Buffer_Full,   -- [out std_logic]
      TX_Buffer_Empty => tx_Buffer_Empty,  -- [out std_logic]

      -- Debug Register Access signals
      DbgReg_Access_Lock => dbgreg_access_lock,  -- [in  std_logic]
      DbgReg_Force_Lock  => dbgreg_force_lock,   -- [in  std_logic]
      DbgReg_Unlocked    => dbgreg_unlocked,     -- [in  std_logic]
      JTAG_Access_Lock   => jtag_access_lock,    -- [out std_logic]
      JTAG_Force_Lock    => jtag_force_lock,     -- [out std_logic]
      JTAG_AXIS_Overrun  => jtag_axis_overrun,   -- [in  std_logic]
      JTAG_Clear_Overrun => jtag_clear_overrun,  -- [out std_logic]

      -- MDM signals
      TDI     => Old_MDM_TDI,         -- [in  std_logic]
      RESET   => Old_MDM_RESET,       -- [in  std_logic]
      UPDATE  => Old_MDM_UPDATE,      -- [in  std_logic]
      SHIFT   => Old_MDM_SHIFT,       -- [in  std_logic]
      CAPTURE => Old_MDM_CAPTURE,     -- [in  std_logic]
      SEL     => Old_MDM_SEL,         -- [in  std_logic]
      DRCK    => Old_MDM_DRCK,        -- [in  std_logic]
      TDO     => Old_MDM_TDO,         -- [out std_logic]

      -- AXI Master signals
      M_AXI_ACLK         => M_AXI_ACLK,          -- [in  std_logic]
      M_AXI_ARESETn      => M_AXI_ARESETn,       -- [in  std_logic]

      Master_rd_start    => Master_rd_start,     -- [out std_logic]
      Master_rd_addr     => Master_rd_addr,      -- [out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0)]
      Master_rd_len      => Master_rd_len,       -- [out std_logic_vector(4 downto 0)]
      Master_rd_size     => Master_rd_size,      -- [out std_logic_vector(1 downto 0)]
      Master_rd_excl     => Master_rd_excl,      -- [out std_logic]
      Master_rd_idle     => Master_rd_idle,      -- [out std_logic]
      Master_rd_resp     => Master_rd_resp,      -- [out std_logic_vector(1 downto 0)]
      Master_wr_start    => Master_wr_start,     -- [out std_logic]
      Master_wr_addr     => Master_wr_addr,      -- [out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0)]
      Master_wr_len      => Master_wr_len,       -- [out std_logic_vector(4 downto 0)]
      Master_wr_size     => Master_wr_size,      -- [out std_logic_vector(1 downto 0)]
      Master_wr_excl     => Master_wr_excl,      -- [out std_logic]
      Master_wr_idle     => Master_wr_idle,      -- [out std_logic]
      Master_wr_resp     => Master_wr_resp,      -- [out std_logic_vector(1 downto 0)]
      Master_data_rd     => Master_data_rd,      -- [out std_logic]
      Master_data_out    => Master_data_out,     -- [in  std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0)]
      Master_data_exists => Master_data_exists,  -- [in  std_logic]
      Master_data_wr     => Master_data_wr,      -- [out std_logic]
      Master_data_in     => Master_data_in,      -- [out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0)]
      Master_data_empty  => Master_data_empty,   -- [in  std_logic]

      Master_dwr_addr    => Master_dwr_addr,     -- [out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0)]
      Master_dwr_len     => Master_dwr_len,      -- [out std_logic_vector(4 downto 0)]
      Master_dwr_done    => Master_dwr_done,     -- [in  std_logic]
      Master_dwr_resp    => Master_dwr_resp,     -- [in  std_logic]

      -- MicroBlaze Debug Signals
      MB_Debug_Enabled => mb_debug_enabled_i,    -- [out std_logic_vector(7 downto 0)]
      Dbg_Clk          => Dbg_Clk,               -- [out std_logic]
      Dbg_TDI          => Dbg_TDI,               -- [in  std_logic]
      Dbg_TDO          => Dbg_TDO,               -- [out std_logic]
      Dbg_Reg_En       => Dbg_Reg_En,            -- [out std_logic_vector(0 to 7)]
      Dbg_Capture      => Dbg_Capture,           -- [out std_logic]
      Dbg_Shift        => Dbg_Shift,             -- [out std_logic]
      Dbg_Update       => Dbg_Update,            -- [out std_logic]

      -- MicroBlaze Cross Trigger Signals
      Dbg_Trig_In_0        => Dbg_Trig_In_0,       -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_1        => Dbg_Trig_In_1,       -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_2        => Dbg_Trig_In_2,       -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_3        => Dbg_Trig_In_3,       -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_4        => Dbg_Trig_In_4,       -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_5        => Dbg_Trig_In_5,       -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_6        => Dbg_Trig_In_6,       -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_7        => Dbg_Trig_In_7,       -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_8        => Dbg_Trig_In_8,       -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_9        => Dbg_Trig_In_9,       -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_10       => Dbg_Trig_In_10,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_11       => Dbg_Trig_In_11,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_12       => Dbg_Trig_In_12,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_13       => Dbg_Trig_In_13,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_14       => Dbg_Trig_In_14,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_15       => Dbg_Trig_In_15,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_16       => Dbg_Trig_In_16,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_17       => Dbg_Trig_In_17,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_18       => Dbg_Trig_In_18,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_19       => Dbg_Trig_In_19,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_20       => Dbg_Trig_In_20,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_21       => Dbg_Trig_In_21,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_22       => Dbg_Trig_In_22,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_23       => Dbg_Trig_In_23,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_24       => Dbg_Trig_In_24,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_25       => Dbg_Trig_In_25,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_26       => Dbg_Trig_In_26,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_27       => Dbg_Trig_In_27,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_28       => Dbg_Trig_In_28,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_29       => Dbg_Trig_In_29,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_30       => Dbg_Trig_In_30,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_In_31       => Dbg_Trig_In_31,      -- [in  std_logic_vector(0 to 7)]

      Dbg_Trig_Ack_In_0    => Dbg_Trig_Ack_In_0,   -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_1    => Dbg_Trig_Ack_In_1,   -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_2    => Dbg_Trig_Ack_In_2,   -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_3    => Dbg_Trig_Ack_In_3,   -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_4    => Dbg_Trig_Ack_In_4,   -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_5    => Dbg_Trig_Ack_In_5,   -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_6    => Dbg_Trig_Ack_In_6,   -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_7    => Dbg_Trig_Ack_In_7,   -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_8    => Dbg_Trig_Ack_In_8,   -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_9    => Dbg_Trig_Ack_In_9,   -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_10   => Dbg_Trig_Ack_In_10,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_11   => Dbg_Trig_Ack_In_11,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_12   => Dbg_Trig_Ack_In_12,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_13   => Dbg_Trig_Ack_In_13,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_14   => Dbg_Trig_Ack_In_14,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_15   => Dbg_Trig_Ack_In_15,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_16   => Dbg_Trig_Ack_In_16,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_17   => Dbg_Trig_Ack_In_17,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_18   => Dbg_Trig_Ack_In_18,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_19   => Dbg_Trig_Ack_In_19,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_20   => Dbg_Trig_Ack_In_20,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_21   => Dbg_Trig_Ack_In_21,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_22   => Dbg_Trig_Ack_In_22,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_23   => Dbg_Trig_Ack_In_23,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_24   => Dbg_Trig_Ack_In_24,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_25   => Dbg_Trig_Ack_In_25,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_26   => Dbg_Trig_Ack_In_26,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_27   => Dbg_Trig_Ack_In_27,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_28   => Dbg_Trig_Ack_In_28,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_29   => Dbg_Trig_Ack_In_29,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_30   => Dbg_Trig_Ack_In_30,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_31   => Dbg_Trig_Ack_In_31,  -- [out std_logic_vector(0 to 7)]

      Dbg_Trig_Out_0       => Dbg_Trig_Out_0,      -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_1       => Dbg_Trig_Out_1,      -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_2       => Dbg_Trig_Out_2,      -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_3       => Dbg_Trig_Out_3,      -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_4       => Dbg_Trig_Out_4,      -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_5       => Dbg_Trig_Out_5,      -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_6       => Dbg_Trig_Out_6,      -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_7       => Dbg_Trig_Out_7,      -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_8       => Dbg_Trig_Out_8,      -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_9       => Dbg_Trig_Out_9,      -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_10      => Dbg_Trig_Out_10,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_11      => Dbg_Trig_Out_11,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_12      => Dbg_Trig_Out_12,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_13      => Dbg_Trig_Out_13,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_14      => Dbg_Trig_Out_14,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_15      => Dbg_Trig_Out_15,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_16      => Dbg_Trig_Out_16,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_17      => Dbg_Trig_Out_17,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_18      => Dbg_Trig_Out_18,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_19      => Dbg_Trig_Out_19,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_20      => Dbg_Trig_Out_20,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_21      => Dbg_Trig_Out_21,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_22      => Dbg_Trig_Out_22,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_23      => Dbg_Trig_Out_23,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_24      => Dbg_Trig_Out_24,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_25      => Dbg_Trig_Out_25,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_26      => Dbg_Trig_Out_26,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_27      => Dbg_Trig_Out_27,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_28      => Dbg_Trig_Out_28,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_29      => Dbg_Trig_Out_29,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_30      => Dbg_Trig_Out_30,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_31      => Dbg_Trig_Out_31,     -- [out std_logic_vector(0 to 7)]

      Dbg_Trig_Ack_Out_0   => Dbg_Trig_Ack_Out_0,  -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_1   => Dbg_Trig_Ack_Out_1,  -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_2   => Dbg_Trig_Ack_Out_2,  -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_3   => Dbg_Trig_Ack_Out_3,  -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_4   => Dbg_Trig_Ack_Out_4,  -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_5   => Dbg_Trig_Ack_Out_5,  -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_6   => Dbg_Trig_Ack_Out_6,  -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_7   => Dbg_Trig_Ack_Out_7,  -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_8   => Dbg_Trig_Ack_Out_8,  -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_9   => Dbg_Trig_Ack_Out_9,  -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_10  => Dbg_Trig_Ack_Out_10, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_11  => Dbg_Trig_Ack_Out_11, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_12  => Dbg_Trig_Ack_Out_12, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_13  => Dbg_Trig_Ack_Out_13, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_14  => Dbg_Trig_Ack_Out_14, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_15  => Dbg_Trig_Ack_Out_15, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_16  => Dbg_Trig_Ack_Out_16, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_17  => Dbg_Trig_Ack_Out_17, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_18  => Dbg_Trig_Ack_Out_18, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_19  => Dbg_Trig_Ack_Out_19, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_20  => Dbg_Trig_Ack_Out_20, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_21  => Dbg_Trig_Ack_Out_21, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_22  => Dbg_Trig_Ack_Out_22, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_23  => Dbg_Trig_Ack_Out_23, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_24  => Dbg_Trig_Ack_Out_24, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_25  => Dbg_Trig_Ack_Out_25, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_26  => Dbg_Trig_Ack_Out_26, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_27  => Dbg_Trig_Ack_Out_27, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_28  => Dbg_Trig_Ack_Out_28, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_29  => Dbg_Trig_Ack_Out_29, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_30  => Dbg_Trig_Ack_Out_30, -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_31  => Dbg_Trig_Ack_Out_31, -- [in  std_logic_vector(0 to 7)]

      Ext_Trig_In          => Ext_Trig_In,         -- [in  std_logic_vector(0 to 3)]
      Ext_Trig_Ack_In      => Ext_Trig_Ack_In,     -- [out std_logic_vector(0 to 3)]
      Ext_Trig_Out         => Ext_Trig_Out,        -- [out std_logic_vector(0 to 3)]
      Ext_Trig_Ack_Out     => Ext_Trig_Ack_Out,    -- [in  std_logic_vector(0 to 3)]

      Trace_Clk            => trace_clk_i,         -- [in  std_logic]
      Trace_Reset          => trace_reset,         -- [in  std_logic]
      Trace_Test_Pattern   => trace_test_pattern,  -- [out std_logic_vector(0 to 3)]
      Trace_Test_Start     => trace_test_start,    -- [out std_logic]
      Trace_Test_Stop      => trace_test_stop,     -- [out std_logic]
      Trace_Test_Timed     => trace_test_timed,    -- [out std_logic]
      Trace_Delay          => trace_delay,         -- [out std_logic_vector(0 to 7)]
      Trace_Stopped        => trace_stopped        -- [out std_logic]
    );

  -----------------------------------------------------------------------------
  -- Enables for each debug port
  -----------------------------------------------------------------------------
  Generate_Dbg_Port_Signals : process (mb_debug_enabled_i, Dbg_Reg_En,
                                       Dbg_TDO_I, Debug_Rst_I)

    variable dbg_tdo_or : std_logic;

  begin  -- process Generate_Dbg_Port_Signals
    dbg_tdo_or   := '0';
    for I in 0 to C_EN_WIDTH-1 loop
      if (mb_debug_enabled_i(I) = '1') then
        Dbg_Reg_En_I(I) <= Dbg_Reg_En;
        Dbg_Rst_I(I)    <= Debug_Rst_i;
      else
        Dbg_Reg_En_I(I) <= (others => '0');
        Dbg_Rst_I(I)    <= '0';
      end if;
      dbg_tdo_or := dbg_tdo_or or Dbg_TDO_I(I);
    end loop;  -- I
    for I in C_EN_WIDTH to 31 loop
      Dbg_Reg_En_I(I)   <= (others => '0');
      Dbg_Rst_I(I)      <= '0';
    end loop;  -- I
    Dbg_TDO             <= dbg_tdo_or;
  end process Generate_Dbg_Port_Signals;

  Debug_SYS_Rst <= Debug_SYS_Rst_i;

  MB_Debug_Enabled <= mb_debug_enabled_i;

  Dbg_Clk_0     <= Dbg_Clk;
  Dbg_TDI_0     <= Dbg_TDI;
  Dbg_Reg_En_0  <= Dbg_Reg_En_I(0);
  Dbg_Capture_0 <= Dbg_Capture;
  Dbg_Shift_0   <= Dbg_Shift;
  Dbg_Update_0  <= Dbg_Update;
  Dbg_Rst_0     <= Dbg_Rst_I(0);
  Dbg_TDO_I(0)  <= Dbg_TDO_0;
  Dbg_TrClk_0   <= Dbg_TrClk;
  Dbg_TrReady_0 <= Dbg_TrReady(0);

  Dbg_Clk_1     <= Dbg_Clk;
  Dbg_TDI_1     <= Dbg_TDI;
  Dbg_Reg_En_1  <= Dbg_Reg_En_I(1);
  Dbg_Capture_1 <= Dbg_Capture;
  Dbg_Shift_1   <= Dbg_Shift;
  Dbg_Update_1  <= Dbg_Update;
  Dbg_Rst_1     <= Dbg_Rst_I(1);
  Dbg_TDO_I(1)  <= Dbg_TDO_1;
  Dbg_TrClk_1   <= Dbg_TrClk;
  Dbg_TrReady_1 <= Dbg_TrReady(1);

  Dbg_Clk_2     <= Dbg_Clk;
  Dbg_TDI_2     <= Dbg_TDI;
  Dbg_Reg_En_2  <= Dbg_Reg_En_I(2);
  Dbg_Capture_2 <= Dbg_Capture;
  Dbg_Shift_2   <= Dbg_Shift;
  Dbg_Update_2  <= Dbg_Update;
  Dbg_Rst_2     <= Dbg_Rst_I(2);
  Dbg_TDO_I(2)  <= Dbg_TDO_2;
  Dbg_TrClk_2   <= Dbg_TrClk;
  Dbg_TrReady_2 <= Dbg_TrReady(2);

  Dbg_Clk_3     <= Dbg_Clk;
  Dbg_TDI_3     <= Dbg_TDI;
  Dbg_Reg_En_3  <= Dbg_Reg_En_I(3);
  Dbg_Capture_3 <= Dbg_Capture;
  Dbg_Shift_3   <= Dbg_Shift;
  Dbg_Update_3  <= Dbg_Update;
  Dbg_Rst_3     <= Dbg_Rst_I(3);
  Dbg_TDO_I(3)  <= Dbg_TDO_3;
  Dbg_TrClk_3   <= Dbg_TrClk;
  Dbg_TrReady_3 <= Dbg_TrReady(3);

  Dbg_Clk_4     <= Dbg_Clk;
  Dbg_TDI_4     <= Dbg_TDI;
  Dbg_Reg_En_4  <= Dbg_Reg_En_I(4);
  Dbg_Capture_4 <= Dbg_Capture;
  Dbg_Shift_4   <= Dbg_Shift;
  Dbg_Update_4  <= Dbg_Update;
  Dbg_Rst_4     <= Dbg_Rst_I(4);
  Dbg_TDO_I(4)  <= Dbg_TDO_4;
  Dbg_TrClk_4   <= Dbg_TrClk;
  Dbg_TrReady_4 <= Dbg_TrReady(4);

  Dbg_Clk_5     <= Dbg_Clk;
  Dbg_TDI_5     <= Dbg_TDI;
  Dbg_Reg_En_5  <= Dbg_Reg_En_I(5);
  Dbg_Capture_5 <= Dbg_Capture;
  Dbg_Shift_5   <= Dbg_Shift;
  Dbg_Update_5  <= Dbg_Update;
  Dbg_Rst_5     <= Dbg_Rst_I(5);
  Dbg_TDO_I(5)  <= Dbg_TDO_5;
  Dbg_TrClk_5   <= Dbg_TrClk;
  Dbg_TrReady_5 <= Dbg_TrReady(5);

  Dbg_Clk_6     <= Dbg_Clk;
  Dbg_TDI_6     <= Dbg_TDI;
  Dbg_Reg_En_6  <= Dbg_Reg_En_I(6);
  Dbg_Capture_6 <= Dbg_Capture;
  Dbg_Shift_6   <= Dbg_Shift;
  Dbg_Update_6  <= Dbg_Update;
  Dbg_Rst_6     <= Dbg_Rst_I(6);
  Dbg_TDO_I(6)  <= Dbg_TDO_6;
  Dbg_TrClk_6   <= Dbg_TrClk;
  Dbg_TrReady_6 <= Dbg_TrReady(6);

  Dbg_Clk_7     <= Dbg_Clk;
  Dbg_TDI_7     <= Dbg_TDI;
  Dbg_Reg_En_7  <= Dbg_Reg_En_I(7);
  Dbg_Capture_7 <= Dbg_Capture;
  Dbg_Shift_7   <= Dbg_Shift;
  Dbg_Update_7  <= Dbg_Update;
  Dbg_Rst_7     <= Dbg_Rst_I(7);
  Dbg_TDO_I(7)  <= Dbg_TDO_7;
  Dbg_TrClk_7   <= Dbg_TrClk;
  Dbg_TrReady_7 <= Dbg_TrReady(7);

  Dbg_Clk_8     <= Dbg_Clk;
  Dbg_TDI_8     <= Dbg_TDI;
  Dbg_Reg_En_8  <= Dbg_Reg_En_I(8);
  Dbg_Capture_8 <= Dbg_Capture;
  Dbg_Shift_8   <= Dbg_Shift;
  Dbg_Update_8  <= Dbg_Update;
  Dbg_Rst_8     <= Dbg_Rst_I(8);
  Dbg_TDO_I(8)  <= Dbg_TDO_8;
  Dbg_TrClk_8   <= Dbg_TrClk;
  Dbg_TrReady_8 <= Dbg_TrReady(8);

  Dbg_Clk_9     <= Dbg_Clk;
  Dbg_TDI_9     <= Dbg_TDI;
  Dbg_Reg_En_9  <= Dbg_Reg_En_I(9);
  Dbg_Capture_9 <= Dbg_Capture;
  Dbg_Shift_9   <= Dbg_Shift;
  Dbg_Update_9  <= Dbg_Update;
  Dbg_Rst_9     <= Dbg_Rst_I(9);
  Dbg_TDO_I(9)  <= Dbg_TDO_9;
  Dbg_TrClk_9   <= Dbg_TrClk;
  Dbg_TrReady_9 <= Dbg_TrReady(9);

  Dbg_Clk_10     <= Dbg_Clk;
  Dbg_TDI_10     <= Dbg_TDI;
  Dbg_Reg_En_10  <= Dbg_Reg_En_I(10);
  Dbg_Capture_10 <= Dbg_Capture;
  Dbg_Shift_10   <= Dbg_Shift;
  Dbg_Update_10  <= Dbg_Update;
  Dbg_Rst_10     <= Dbg_Rst_I(10);
  Dbg_TDO_I(10)  <= Dbg_TDO_10;
  Dbg_TrClk_10   <= Dbg_TrClk;
  Dbg_TrReady_10 <= Dbg_TrReady(10);

  Dbg_Clk_11     <= Dbg_Clk;
  Dbg_TDI_11     <= Dbg_TDI;
  Dbg_Reg_En_11  <= Dbg_Reg_En_I(11);
  Dbg_Capture_11 <= Dbg_Capture;
  Dbg_Shift_11   <= Dbg_Shift;
  Dbg_Update_11  <= Dbg_Update;
  Dbg_Rst_11     <= Dbg_Rst_I(11);
  Dbg_TDO_I(11)  <= Dbg_TDO_11;
  Dbg_TrClk_11   <= Dbg_TrClk;
  Dbg_TrReady_11 <= Dbg_TrReady(11);

  Dbg_Clk_12     <= Dbg_Clk;
  Dbg_TDI_12     <= Dbg_TDI;
  Dbg_Reg_En_12  <= Dbg_Reg_En_I(12);
  Dbg_Capture_12 <= Dbg_Capture;
  Dbg_Shift_12   <= Dbg_Shift;
  Dbg_Update_12  <= Dbg_Update;
  Dbg_Rst_12     <= Dbg_Rst_I(12);
  Dbg_TDO_I(12)  <= Dbg_TDO_12;
  Dbg_TrClk_12   <= Dbg_TrClk;
  Dbg_TrReady_12 <= Dbg_TrReady(12);

  Dbg_Clk_13     <= Dbg_Clk;
  Dbg_TDI_13     <= Dbg_TDI;
  Dbg_Reg_En_13  <= Dbg_Reg_En_I(13);
  Dbg_Capture_13 <= Dbg_Capture;
  Dbg_Shift_13   <= Dbg_Shift;
  Dbg_Update_13  <= Dbg_Update;
  Dbg_Rst_13     <= Dbg_Rst_I(13);
  Dbg_TDO_I(13)  <= Dbg_TDO_13;
  Dbg_TrClk_13   <= Dbg_TrClk;
  Dbg_TrReady_13 <= Dbg_TrReady(13);

  Dbg_Clk_14     <= Dbg_Clk;
  Dbg_TDI_14     <= Dbg_TDI;
  Dbg_Reg_En_14  <= Dbg_Reg_En_I(14);
  Dbg_Capture_14 <= Dbg_Capture;
  Dbg_Shift_14   <= Dbg_Shift;
  Dbg_Update_14  <= Dbg_Update;
  Dbg_Rst_14     <= Dbg_Rst_I(14);
  Dbg_TDO_I(14)  <= Dbg_TDO_14;
  Dbg_TrClk_14   <= Dbg_TrClk;
  Dbg_TrReady_14 <= Dbg_TrReady(14);

  Dbg_Clk_15     <= Dbg_Clk;
  Dbg_TDI_15     <= Dbg_TDI;
  Dbg_Reg_En_15  <= Dbg_Reg_En_I(15);
  Dbg_Capture_15 <= Dbg_Capture;
  Dbg_Shift_15   <= Dbg_Shift;
  Dbg_Update_15  <= Dbg_Update;
  Dbg_Rst_15     <= Dbg_Rst_I(15);
  Dbg_TDO_I(15)  <= Dbg_TDO_15;
  Dbg_TrClk_15   <= Dbg_TrClk;
  Dbg_TrReady_15 <= Dbg_TrReady(15);

  Dbg_Clk_16     <= Dbg_Clk;
  Dbg_TDI_16     <= Dbg_TDI;
  Dbg_Reg_En_16  <= Dbg_Reg_En_I(16);
  Dbg_Capture_16 <= Dbg_Capture;
  Dbg_Shift_16   <= Dbg_Shift;
  Dbg_Update_16  <= Dbg_Update;
  Dbg_Rst_16     <= Dbg_Rst_I(16);
  Dbg_TDO_I(16)  <= Dbg_TDO_16;
  Dbg_TrClk_16   <= Dbg_TrClk;
  Dbg_TrReady_16 <= Dbg_TrReady(16);

  Dbg_Clk_17     <= Dbg_Clk;
  Dbg_TDI_17     <= Dbg_TDI;
  Dbg_Reg_En_17  <= Dbg_Reg_En_I(17);
  Dbg_Capture_17 <= Dbg_Capture;
  Dbg_Shift_17   <= Dbg_Shift;
  Dbg_Update_17  <= Dbg_Update;
  Dbg_Rst_17     <= Dbg_Rst_I(17);
  Dbg_TDO_I(17)  <= Dbg_TDO_17;
  Dbg_TrClk_17   <= Dbg_TrClk;
  Dbg_TrReady_17 <= Dbg_TrReady(17);

  Dbg_Clk_18     <= Dbg_Clk;
  Dbg_TDI_18     <= Dbg_TDI;
  Dbg_Reg_En_18  <= Dbg_Reg_En_I(18);
  Dbg_Capture_18 <= Dbg_Capture;
  Dbg_Shift_18   <= Dbg_Shift;
  Dbg_Update_18  <= Dbg_Update;
  Dbg_Rst_18     <= Dbg_Rst_I(18);
  Dbg_TDO_I(18)  <= Dbg_TDO_18;
  Dbg_TrClk_18   <= Dbg_TrClk;
  Dbg_TrReady_18 <= Dbg_TrReady(18);

  Dbg_Clk_19     <= Dbg_Clk;
  Dbg_TDI_19     <= Dbg_TDI;
  Dbg_Reg_En_19  <= Dbg_Reg_En_I(19);
  Dbg_Capture_19 <= Dbg_Capture;
  Dbg_Shift_19   <= Dbg_Shift;
  Dbg_Update_19  <= Dbg_Update;
  Dbg_Rst_19     <= Dbg_Rst_I(19);
  Dbg_TDO_I(19)  <= Dbg_TDO_19;
  Dbg_TrClk_19   <= Dbg_TrClk;
  Dbg_TrReady_19 <= Dbg_TrReady(19);

  Dbg_Clk_20     <= Dbg_Clk;
  Dbg_TDI_20     <= Dbg_TDI;
  Dbg_Reg_En_20  <= Dbg_Reg_En_I(20);
  Dbg_Capture_20 <= Dbg_Capture;
  Dbg_Shift_20   <= Dbg_Shift;
  Dbg_Update_20  <= Dbg_Update;
  Dbg_Rst_20     <= Dbg_Rst_I(20);
  Dbg_TDO_I(20)  <= Dbg_TDO_20;
  Dbg_TrClk_20   <= Dbg_TrClk;
  Dbg_TrReady_20 <= Dbg_TrReady(20);

  Dbg_Clk_21     <= Dbg_Clk;
  Dbg_TDI_21     <= Dbg_TDI;
  Dbg_Reg_En_21  <= Dbg_Reg_En_I(21);
  Dbg_Capture_21 <= Dbg_Capture;
  Dbg_Shift_21   <= Dbg_Shift;
  Dbg_Update_21  <= Dbg_Update;
  Dbg_Rst_21     <= Dbg_Rst_I(21);
  Dbg_TDO_I(21)  <= Dbg_TDO_21;
  Dbg_TrClk_21   <= Dbg_TrClk;
  Dbg_TrReady_21 <= Dbg_TrReady(21);

  Dbg_Clk_22     <= Dbg_Clk;
  Dbg_TDI_22     <= Dbg_TDI;
  Dbg_Reg_En_22  <= Dbg_Reg_En_I(22);
  Dbg_Capture_22 <= Dbg_Capture;
  Dbg_Shift_22   <= Dbg_Shift;
  Dbg_Update_22  <= Dbg_Update;
  Dbg_Rst_22     <= Dbg_Rst_I(22);
  Dbg_TDO_I(22)  <= Dbg_TDO_22;
  Dbg_TrClk_22   <= Dbg_TrClk;
  Dbg_TrReady_22 <= Dbg_TrReady(22);

  Dbg_Clk_23     <= Dbg_Clk;
  Dbg_TDI_23     <= Dbg_TDI;
  Dbg_Reg_En_23  <= Dbg_Reg_En_I(23);
  Dbg_Capture_23 <= Dbg_Capture;
  Dbg_Shift_23   <= Dbg_Shift;
  Dbg_Update_23  <= Dbg_Update;
  Dbg_Rst_23     <= Dbg_Rst_I(23);
  Dbg_TDO_I(23)  <= Dbg_TDO_23;
  Dbg_TrClk_23   <= Dbg_TrClk;
  Dbg_TrReady_23 <= Dbg_TrReady(23);

  Dbg_Clk_24     <= Dbg_Clk;
  Dbg_TDI_24     <= Dbg_TDI;
  Dbg_Reg_En_24  <= Dbg_Reg_En_I(24);
  Dbg_Capture_24 <= Dbg_Capture;
  Dbg_Shift_24   <= Dbg_Shift;
  Dbg_Update_24  <= Dbg_Update;
  Dbg_Rst_24     <= Dbg_Rst_I(24);
  Dbg_TDO_I(24)  <= Dbg_TDO_24;
  Dbg_TrClk_24   <= Dbg_TrClk;
  Dbg_TrReady_24 <= Dbg_TrReady(24);

  Dbg_Clk_25     <= Dbg_Clk;
  Dbg_TDI_25     <= Dbg_TDI;
  Dbg_Reg_En_25  <= Dbg_Reg_En_I(25);
  Dbg_Capture_25 <= Dbg_Capture;
  Dbg_Shift_25   <= Dbg_Shift;
  Dbg_Update_25  <= Dbg_Update;
  Dbg_Rst_25     <= Dbg_Rst_I(25);
  Dbg_TDO_I(25)  <= Dbg_TDO_25;
  Dbg_TrClk_25   <= Dbg_TrClk;
  Dbg_TrReady_25 <= Dbg_TrReady(25);

  Dbg_Clk_26     <= Dbg_Clk;
  Dbg_TDI_26     <= Dbg_TDI;
  Dbg_Reg_En_26  <= Dbg_Reg_En_I(26);
  Dbg_Capture_26 <= Dbg_Capture;
  Dbg_Shift_26   <= Dbg_Shift;
  Dbg_Update_26  <= Dbg_Update;
  Dbg_Rst_26     <= Dbg_Rst_I(26);
  Dbg_TDO_I(26)  <= Dbg_TDO_26;
  Dbg_TrClk_26   <= Dbg_TrClk;
  Dbg_TrReady_26 <= Dbg_TrReady(26);

  Dbg_Clk_27     <= Dbg_Clk;
  Dbg_TDI_27     <= Dbg_TDI;
  Dbg_Reg_En_27  <= Dbg_Reg_En_I(27);
  Dbg_Capture_27 <= Dbg_Capture;
  Dbg_Shift_27   <= Dbg_Shift;
  Dbg_Update_27  <= Dbg_Update;
  Dbg_Rst_27     <= Dbg_Rst_I(27);
  Dbg_TDO_I(27)  <= Dbg_TDO_27;
  Dbg_TrClk_27   <= Dbg_TrClk;
  Dbg_TrReady_27 <= Dbg_TrReady(27);

  Dbg_Clk_28     <= Dbg_Clk;
  Dbg_TDI_28     <= Dbg_TDI;
  Dbg_Reg_En_28  <= Dbg_Reg_En_I(28);
  Dbg_Capture_28 <= Dbg_Capture;
  Dbg_Shift_28   <= Dbg_Shift;
  Dbg_Update_28  <= Dbg_Update;
  Dbg_Rst_28     <= Dbg_Rst_I(28);
  Dbg_TDO_I(28)  <= Dbg_TDO_28;
  Dbg_TrClk_28   <= Dbg_TrClk;
  Dbg_TrReady_28 <= Dbg_TrReady(28);

  Dbg_Clk_29     <= Dbg_Clk;
  Dbg_TDI_29     <= Dbg_TDI;
  Dbg_Reg_En_29  <= Dbg_Reg_En_I(29);
  Dbg_Capture_29 <= Dbg_Capture;
  Dbg_Shift_29   <= Dbg_Shift;
  Dbg_Update_29  <= Dbg_Update;
  Dbg_Rst_29     <= Dbg_Rst_I(29);
  Dbg_TDO_I(29)  <= Dbg_TDO_29;
  Dbg_TrClk_29   <= Dbg_TrClk;
  Dbg_TrReady_29 <= Dbg_TrReady(29);

  Dbg_Clk_30     <= Dbg_Clk;
  Dbg_TDI_30     <= Dbg_TDI;
  Dbg_Reg_En_30  <= Dbg_Reg_En_I(30);
  Dbg_Capture_30 <= Dbg_Capture;
  Dbg_Shift_30   <= Dbg_Shift;
  Dbg_Update_30  <= Dbg_Update;
  Dbg_Rst_30     <= Dbg_Rst_I(30);
  Dbg_TDO_I(30)  <= Dbg_TDO_30;
  Dbg_TrClk_30   <= Dbg_TrClk;
  Dbg_TrReady_30 <= Dbg_TrReady(30);

  Dbg_Clk_31     <= Dbg_Clk;
  Dbg_TDI_31     <= Dbg_TDI;
  Dbg_Reg_En_31  <= Dbg_Reg_En_I(31);
  Dbg_Capture_31 <= Dbg_Capture;
  Dbg_Shift_31   <= Dbg_Shift;
  Dbg_Update_31  <= Dbg_Update;
  Dbg_Rst_31     <= Dbg_Rst_I(31);
  Dbg_TDO_I(31)  <= Dbg_TDO_31;
  Dbg_TrClk_31   <= Dbg_TrClk;
  Dbg_TrReady_31 <= Dbg_TrReady(31);

end architecture IMP;
