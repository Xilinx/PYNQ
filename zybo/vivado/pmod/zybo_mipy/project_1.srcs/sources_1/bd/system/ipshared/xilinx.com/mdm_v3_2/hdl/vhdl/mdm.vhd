-------------------------------------------------------------------------------
-- mdm.vhd - Entity and architecture
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
-- Filename:        mdm.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              mdm.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
--
-- History:
--   goran   2006-10-27    First Version
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

library unisim;
use unisim.vcomponents.all;

library mdm_v3_2_4;
use mdm_v3_2_4.all;

library axi_lite_ipif_v3_0_3;
use axi_lite_ipif_v3_0_3.axi_lite_ipif;
use axi_lite_ipif_v3_0_3.ipif_pkg.all;

entity MDM is
  generic (
    C_FAMILY                : string                        := "virtex7";
    C_JTAG_CHAIN            : integer                       := 2;
    C_USE_BSCAN             : integer                       := 0;
    C_USE_CONFIG_RESET      : integer                       := 0;
    C_INTERCONNECT          : integer                       := 0;
    C_BASEADDR              : std_logic_vector(0 to 31)     := X"FFFF_FFFF";
    C_HIGHADDR              : std_logic_vector(0 to 31)     := X"0000_0000";
    C_MB_DBG_PORTS          : integer                       := 1;
    C_DBG_REG_ACCESS        : integer                       := 0;
    C_DBG_MEM_ACCESS        : integer                       := 0;
    C_USE_UART              : integer                       := 1;
    C_USE_CROSS_TRIGGER     : integer                       := 0;
    C_TRACE_OUTPUT          : integer                       := 0;
    C_TRACE_DATA_WIDTH      : integer range 2 to 32         := 32;
    C_TRACE_CLK_FREQ_HZ     : integer                       := 200000000;
    C_TRACE_CLK_OUT_PHASE   : integer range 0 to 360        := 90;
    C_S_AXI_ACLK_FREQ_HZ    : integer                       := 100000000;
    C_S_AXI_ADDR_WIDTH      : integer range 32 to 36        := 32;
    C_S_AXI_DATA_WIDTH      : integer range 32 to 128       := 32;
    C_M_AXI_ADDR_WIDTH      : integer range 32 to 32        := 32;
    C_M_AXI_DATA_WIDTH      : integer range 32 to 32        := 32;
    C_M_AXI_THREAD_ID_WIDTH : integer                       := 1;
    C_DATA_SIZE             : integer range 32 to 32        := 32;
    C_M_AXIS_DATA_WIDTH     : integer range 32 to 32        := 32;
    C_M_AXIS_ID_WIDTH       : integer range 1  to 7         := 7
  );

  port (
    -- Global signals
    Config_Reset    : in std_logic := '0';
    Scan_Reset_Sel  : in std_logic := '0';
    Scan_Reset      : in std_logic := '0';

    S_AXI_ACLK      : in std_logic;
    S_AXI_ARESETN   : in std_logic;

    M_AXI_ACLK      : in std_logic;
    M_AXI_ARESETN   : in std_logic;

    M_AXIS_ACLK     : in std_logic;
    M_AXIS_ARESETN  : in std_logic;

    Interrupt       : out std_logic;
    Ext_BRK         : out std_logic;
    Ext_NM_BRK      : out std_logic;
    Debug_SYS_Rst   : out std_logic;

    -- External cross trigger signals
    Trig_In_0      : in  std_logic;
    Trig_Ack_In_0  : out std_logic;
    Trig_Out_0     : out std_logic;
    Trig_Ack_Out_0 : in  std_logic;

    Trig_In_1      : in  std_logic;
    Trig_Ack_In_1  : out std_logic;
    Trig_Out_1     : out std_logic;
    Trig_Ack_Out_1 : in  std_logic;

    Trig_In_2      : in  std_logic;
    Trig_Ack_In_2  : out std_logic;
    Trig_Out_2     : out std_logic;
    Trig_Ack_Out_2 : in  std_logic;

    Trig_In_3      : in  std_logic;
    Trig_Ack_In_3  : out std_logic;
    Trig_Out_3     : out std_logic;
    Trig_Ack_Out_3 : in  std_logic;

    -- AXI slave signals
    S_AXI_AWADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWVALID : in  std_logic;
    S_AXI_AWREADY : out std_logic;
    S_AXI_WDATA   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB   : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WVALID  : in  std_logic;
    S_AXI_WREADY  : out std_logic;
    S_AXI_BRESP   : out std_logic_vector(1 downto 0);
    S_AXI_BVALID  : out std_logic;
    S_AXI_BREADY  : in  std_logic;
    S_AXI_ARADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARVALID : in  std_logic;
    S_AXI_ARREADY : out std_logic;
    S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP   : out std_logic_vector(1 downto 0);
    S_AXI_RVALID  : out std_logic;
    S_AXI_RREADY  : in  std_logic;

    -- Bus master signals
    M_AXI_AWID          : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_AWADDR        : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    M_AXI_AWLEN         : out std_logic_vector(7 downto 0);
    M_AXI_AWSIZE        : out std_logic_vector(2 downto 0);
    M_AXI_AWBURST       : out std_logic_vector(1 downto 0);
    M_AXI_AWLOCK        : out std_logic;
    M_AXI_AWCACHE       : out std_logic_vector(3 downto 0);
    M_AXI_AWPROT        : out std_logic_vector(2 downto 0);
    M_AXI_AWQOS         : out std_logic_vector(3 downto 0);
    M_AXI_AWVALID       : out std_logic;
    M_AXI_AWREADY       : in  std_logic;
    M_AXI_WDATA         : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
    M_AXI_WSTRB         : out std_logic_vector((C_M_AXI_DATA_WIDTH/8)-1 downto 0);
    M_AXI_WLAST         : out std_logic;
    M_AXI_WVALID        : out std_logic;
    M_AXI_WREADY        : in  std_logic;
    M_AXI_BRESP         : in  std_logic_vector(1 downto 0);
    M_AXI_BID           : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_BVALID        : in  std_logic;
    M_AXI_BREADY        : out std_logic;
    M_AXI_ARID          : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_ARADDR        : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    M_AXI_ARLEN         : out std_logic_vector(7 downto 0);
    M_AXI_ARSIZE        : out std_logic_vector(2 downto 0);
    M_AXI_ARBURST       : out std_logic_vector(1 downto 0);
    M_AXI_ARLOCK        : out std_logic;
    M_AXI_ARCACHE       : out std_logic_vector(3 downto 0);
    M_AXI_ARPROT        : out std_logic_vector(2 downto 0);
    M_AXI_ARQOS         : out std_logic_vector(3 downto 0);
    M_AXI_ARVALID       : out std_logic;
    M_AXI_ARREADY       : in  std_logic;
    M_AXI_RID           : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_RDATA         : in  std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
    M_AXI_RRESP         : in  std_logic_vector(1 downto 0);
    M_AXI_RLAST         : in  std_logic;
    M_AXI_RVALID        : in  std_logic;
    M_AXI_RREADY        : out std_logic;

    LMB_Data_Addr_0     : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_0     : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_0    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_0   : out std_logic;
    LMB_Read_Strobe_0   : out std_logic;
    LMB_Write_Strobe_0  : out std_logic;
    LMB_Ready_0         : in  std_logic;
    LMB_Wait_0          : in  std_logic;
    LMB_CE_0            : in  std_logic;
    LMB_UE_0            : in  std_logic;
    LMB_Byte_Enable_0   : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_1     : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_1     : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_1    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_1   : out std_logic;
    LMB_Read_Strobe_1   : out std_logic;
    LMB_Write_Strobe_1  : out std_logic;
    LMB_Ready_1         : in  std_logic;
    LMB_Wait_1          : in  std_logic;
    LMB_CE_1            : in  std_logic;
    LMB_UE_1            : in  std_logic;
    LMB_Byte_Enable_1   : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_2     : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_2     : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_2    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_2   : out std_logic;
    LMB_Read_Strobe_2   : out std_logic;
    LMB_Write_Strobe_2  : out std_logic;
    LMB_Ready_2         : in  std_logic;
    LMB_Wait_2          : in  std_logic;
    LMB_CE_2            : in  std_logic;
    LMB_UE_2            : in  std_logic;
    LMB_Byte_Enable_2   : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_3     : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_3     : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_3    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_3   : out std_logic;
    LMB_Read_Strobe_3   : out std_logic;
    LMB_Write_Strobe_3  : out std_logic;
    LMB_Ready_3         : in  std_logic;
    LMB_Wait_3          : in  std_logic;
    LMB_CE_3            : in  std_logic;
    LMB_UE_3            : in  std_logic;
    LMB_Byte_Enable_3   : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_4     : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_4     : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_4    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_4   : out std_logic;
    LMB_Read_Strobe_4   : out std_logic;
    LMB_Write_Strobe_4  : out std_logic;
    LMB_Ready_4         : in  std_logic;
    LMB_Wait_4          : in  std_logic;
    LMB_CE_4            : in  std_logic;
    LMB_UE_4            : in  std_logic;
    LMB_Byte_Enable_4   : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_5     : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_5     : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_5    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_5   : out std_logic;
    LMB_Read_Strobe_5   : out std_logic;
    LMB_Write_Strobe_5  : out std_logic;
    LMB_Ready_5         : in  std_logic;
    LMB_Wait_5          : in  std_logic;
    LMB_CE_5            : in  std_logic;
    LMB_UE_5            : in  std_logic;
    LMB_Byte_Enable_5   : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_6     : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_6     : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_6    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_6   : out std_logic;
    LMB_Read_Strobe_6   : out std_logic;
    LMB_Write_Strobe_6  : out std_logic;
    LMB_Ready_6         : in  std_logic;
    LMB_Wait_6          : in  std_logic;
    LMB_CE_6            : in  std_logic;
    LMB_UE_6            : in  std_logic;
    LMB_Byte_Enable_6   : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_7     : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_7     : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_7    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_7   : out std_logic;
    LMB_Read_Strobe_7   : out std_logic;
    LMB_Write_Strobe_7  : out std_logic;
    LMB_Ready_7         : in  std_logic;
    LMB_Wait_7          : in  std_logic;
    LMB_CE_7            : in  std_logic;
    LMB_UE_7            : in  std_logic;
    LMB_Byte_Enable_7   : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_8     : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_8     : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_8    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_8   : out std_logic;
    LMB_Read_Strobe_8   : out std_logic;
    LMB_Write_Strobe_8  : out std_logic;
    LMB_Ready_8         : in  std_logic;
    LMB_Wait_8          : in  std_logic;
    LMB_CE_8            : in  std_logic;
    LMB_UE_8            : in  std_logic;
    LMB_Byte_Enable_8   : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_9     : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_9     : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_9    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_9   : out std_logic;
    LMB_Read_Strobe_9   : out std_logic;
    LMB_Write_Strobe_9  : out std_logic;
    LMB_Ready_9         : in  std_logic;
    LMB_Wait_9          : in  std_logic;
    LMB_CE_9            : in  std_logic;
    LMB_UE_9            : in  std_logic;
    LMB_Byte_Enable_9   : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_10    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_10    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_10   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_10  : out std_logic;
    LMB_Read_Strobe_10  : out std_logic;
    LMB_Write_Strobe_10 : out std_logic;
    LMB_Ready_10        : in  std_logic;
    LMB_Wait_10         : in  std_logic;
    LMB_CE_10           : in  std_logic;
    LMB_UE_10           : in  std_logic;
    LMB_Byte_Enable_10  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_11    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_11    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_11   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_11  : out std_logic;
    LMB_Read_Strobe_11  : out std_logic;
    LMB_Write_Strobe_11 : out std_logic;
    LMB_Ready_11        : in  std_logic;
    LMB_Wait_11         : in  std_logic;
    LMB_CE_11           : in  std_logic;
    LMB_UE_11           : in  std_logic;
    LMB_Byte_Enable_11  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_12    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_12    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_12   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_12  : out std_logic;
    LMB_Read_Strobe_12  : out std_logic;
    LMB_Write_Strobe_12 : out std_logic;
    LMB_Ready_12        : in  std_logic;
    LMB_Wait_12         : in  std_logic;
    LMB_CE_12           : in  std_logic;
    LMB_UE_12           : in  std_logic;
    LMB_Byte_Enable_12  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_13    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_13    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_13   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_13  : out std_logic;
    LMB_Read_Strobe_13  : out std_logic;
    LMB_Write_Strobe_13 : out std_logic;
    LMB_Ready_13        : in  std_logic;
    LMB_Wait_13         : in  std_logic;
    LMB_CE_13           : in  std_logic;
    LMB_UE_13           : in  std_logic;
    LMB_Byte_Enable_13  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_14    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_14    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_14   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_14  : out std_logic;
    LMB_Read_Strobe_14  : out std_logic;
    LMB_Write_Strobe_14 : out std_logic;
    LMB_Ready_14        : in  std_logic;
    LMB_Wait_14         : in  std_logic;
    LMB_CE_14           : in  std_logic;
    LMB_UE_14           : in  std_logic;
    LMB_Byte_Enable_14  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_15    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_15    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_15   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_15  : out std_logic;
    LMB_Read_Strobe_15  : out std_logic;
    LMB_Write_Strobe_15 : out std_logic;
    LMB_Ready_15        : in  std_logic;
    LMB_Wait_15         : in  std_logic;
    LMB_CE_15           : in  std_logic;
    LMB_UE_15           : in  std_logic;
    LMB_Byte_Enable_15  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_16    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_16    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_16   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_16  : out std_logic;
    LMB_Read_Strobe_16  : out std_logic;
    LMB_Write_Strobe_16 : out std_logic;
    LMB_Ready_16        : in  std_logic;
    LMB_Wait_16         : in  std_logic;
    LMB_CE_16           : in  std_logic;
    LMB_UE_16           : in  std_logic;
    LMB_Byte_Enable_16  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_17    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_17    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_17   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_17  : out std_logic;
    LMB_Read_Strobe_17  : out std_logic;
    LMB_Write_Strobe_17 : out std_logic;
    LMB_Ready_17        : in  std_logic;
    LMB_Wait_17         : in  std_logic;
    LMB_CE_17           : in  std_logic;
    LMB_UE_17           : in  std_logic;
    LMB_Byte_Enable_17  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_18    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_18    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_18   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_18  : out std_logic;
    LMB_Read_Strobe_18  : out std_logic;
    LMB_Write_Strobe_18 : out std_logic;
    LMB_Ready_18        : in  std_logic;
    LMB_Wait_18         : in  std_logic;
    LMB_CE_18           : in  std_logic;
    LMB_UE_18           : in  std_logic;
    LMB_Byte_Enable_18  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_19    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_19    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_19   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_19  : out std_logic;
    LMB_Read_Strobe_19  : out std_logic;
    LMB_Write_Strobe_19 : out std_logic;
    LMB_Ready_19        : in  std_logic;
    LMB_Wait_19         : in  std_logic;
    LMB_CE_19           : in  std_logic;
    LMB_UE_19           : in  std_logic;
    LMB_Byte_Enable_19  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_20    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_20    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_20   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_20  : out std_logic;
    LMB_Read_Strobe_20  : out std_logic;
    LMB_Write_Strobe_20 : out std_logic;
    LMB_Ready_20        : in  std_logic;
    LMB_Wait_20         : in  std_logic;
    LMB_CE_20           : in  std_logic;
    LMB_UE_20           : in  std_logic;
    LMB_Byte_Enable_20  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_21    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_21    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_21   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_21  : out std_logic;
    LMB_Read_Strobe_21  : out std_logic;
    LMB_Write_Strobe_21 : out std_logic;
    LMB_Ready_21        : in  std_logic;
    LMB_Wait_21         : in  std_logic;
    LMB_CE_21           : in  std_logic;
    LMB_UE_21           : in  std_logic;
    LMB_Byte_Enable_21  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_22    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_22    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_22   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_22  : out std_logic;
    LMB_Read_Strobe_22  : out std_logic;
    LMB_Write_Strobe_22 : out std_logic;
    LMB_Ready_22        : in  std_logic;
    LMB_Wait_22         : in  std_logic;
    LMB_CE_22           : in  std_logic;
    LMB_UE_22           : in  std_logic;
    LMB_Byte_Enable_22  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_23    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_23    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_23   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_23  : out std_logic;
    LMB_Read_Strobe_23  : out std_logic;
    LMB_Write_Strobe_23 : out std_logic;
    LMB_Ready_23        : in  std_logic;
    LMB_Wait_23         : in  std_logic;
    LMB_CE_23           : in  std_logic;
    LMB_UE_23           : in  std_logic;
    LMB_Byte_Enable_23  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_24    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_24    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_24   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_24  : out std_logic;
    LMB_Read_Strobe_24  : out std_logic;
    LMB_Write_Strobe_24 : out std_logic;
    LMB_Ready_24        : in  std_logic;
    LMB_Wait_24         : in  std_logic;
    LMB_CE_24           : in  std_logic;
    LMB_UE_24           : in  std_logic;
    LMB_Byte_Enable_24  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_25    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_25    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_25   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_25  : out std_logic;
    LMB_Read_Strobe_25  : out std_logic;
    LMB_Write_Strobe_25 : out std_logic;
    LMB_Ready_25        : in  std_logic;
    LMB_Wait_25         : in  std_logic;
    LMB_CE_25           : in  std_logic;
    LMB_UE_25           : in  std_logic;
    LMB_Byte_Enable_25  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_26    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_26    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_26   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_26  : out std_logic;
    LMB_Read_Strobe_26  : out std_logic;
    LMB_Write_Strobe_26 : out std_logic;
    LMB_Ready_26        : in  std_logic;
    LMB_Wait_26         : in  std_logic;
    LMB_CE_26           : in  std_logic;
    LMB_UE_26           : in  std_logic;
    LMB_Byte_Enable_26  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_27    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_27    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_27   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_27  : out std_logic;
    LMB_Read_Strobe_27  : out std_logic;
    LMB_Write_Strobe_27 : out std_logic;
    LMB_Ready_27        : in  std_logic;
    LMB_Wait_27         : in  std_logic;
    LMB_CE_27           : in  std_logic;
    LMB_UE_27           : in  std_logic;
    LMB_Byte_Enable_27  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_28    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_28    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_28   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_28  : out std_logic;
    LMB_Read_Strobe_28  : out std_logic;
    LMB_Write_Strobe_28 : out std_logic;
    LMB_Ready_28        : in  std_logic;
    LMB_Wait_28         : in  std_logic;
    LMB_CE_28           : in  std_logic;
    LMB_UE_28           : in  std_logic;
    LMB_Byte_Enable_28  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_29    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_29    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_29   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_29  : out std_logic;
    LMB_Read_Strobe_29  : out std_logic;
    LMB_Write_Strobe_29 : out std_logic;
    LMB_Ready_29        : in  std_logic;
    LMB_Wait_29         : in  std_logic;
    LMB_CE_29           : in  std_logic;
    LMB_UE_29           : in  std_logic;
    LMB_Byte_Enable_29  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_30    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_30    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_30   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_30  : out std_logic;
    LMB_Read_Strobe_30  : out std_logic;
    LMB_Write_Strobe_30 : out std_logic;
    LMB_Ready_30        : in  std_logic;
    LMB_Wait_30         : in  std_logic;
    LMB_CE_30           : in  std_logic;
    LMB_UE_30           : in  std_logic;
    LMB_Byte_Enable_30  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
    LMB_Data_Addr_31    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read_31    : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write_31   : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe_31  : out std_logic;
    LMB_Read_Strobe_31  : out std_logic;
    LMB_Write_Strobe_31 : out std_logic;
    LMB_Ready_31        : in  std_logic;
    LMB_Wait_31         : in  std_logic;
    LMB_CE_31           : in  std_logic;
    LMB_UE_31           : in  std_logic;
    LMB_Byte_Enable_31  : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);

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

    -- External BSCAN inputs
    -- These signals are used when C_USE_BSCAN = 2 (EXTERNAL)
    bscan_ext_tdi     : in  std_logic;
    bscan_ext_reset   : in  std_logic;
    bscan_ext_shift   : in  std_logic;
    bscan_ext_update  : in  std_logic;
    bscan_ext_capture : in  std_logic;
    bscan_ext_sel     : in  std_logic;
    bscan_ext_drck    : in  std_logic;
    bscan_ext_tdo     : out std_logic;

    -- External JTAG ports
    Ext_JTAG_DRCK    : out std_logic;
    Ext_JTAG_RESET   : out std_logic;
    Ext_JTAG_SEL     : out std_logic;
    Ext_JTAG_CAPTURE : out std_logic;
    Ext_JTAG_SHIFT   : out std_logic;
    Ext_JTAG_UPDATE  : out std_logic;
    Ext_JTAG_TDI     : out std_logic;
    Ext_JTAG_TDO     : in  std_logic

  );

end entity MDM;

architecture IMP of MDM is

  function int2std (val : integer) return std_logic is
  begin  -- function int2std
    if (val = 0) then
      return '0';
    else
      return '1';
    end if;
  end function int2std;

  --------------------------------------------------------------------------
  -- Constant declarations
  --------------------------------------------------------------------------

  constant ZEROES : std_logic_vector(31 downto 0) := X"00000000";

  constant C_REG_NUM_CE     : integer := 4 + 4  * C_DBG_REG_ACCESS;
  constant C_REG_DATA_WIDTH : integer := 8 + 24 * C_DBG_REG_ACCESS;
  constant C_S_AXI_MIN_SIZE : std_logic_vector(31 downto 0) :=
    (31 downto 5 => '0', 4 => int2std(C_DBG_REG_ACCESS), 3 downto 0 => '1');

  constant C_ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE := (
    -- Registers Base Address (not used)
    ZEROES & C_BASEADDR,
    ZEROES & (C_BASEADDR or C_S_AXI_MIN_SIZE)
  );

  constant C_ARD_NUM_CE_ARRAY : INTEGER_ARRAY_TYPE := (
    0 => C_REG_NUM_CE
  );

  constant C_USE_WSTRB      : integer := 0;
  constant C_DPHASE_TIMEOUT : integer := 0;

  constant C_TRACE_AXI_MASTER : boolean := C_TRACE_OUTPUT = 3;

  --------------------------------------------------------------------------
  -- Component declarations
  --------------------------------------------------------------------------  

  component MDM_Core
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
      C_M_AXIS_ID_WIDTH     : integer);

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

      -- AXI IPIC signals
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
    
      -- External JTAG
      Ext_JTAG_DRCK    : out std_logic;
      Ext_JTAG_RESET   : out std_logic;
      Ext_JTAG_SEL     : out std_logic;
      Ext_JTAG_CAPTURE : out std_logic;
      Ext_JTAG_SHIFT   : out std_logic;
      Ext_JTAG_UPDATE  : out std_logic;
      Ext_JTAG_TDI     : out std_logic;
      Ext_JTAG_TDO     : in  std_logic
    );
  end component MDM_Core;

  component bus_master is
    generic (
      C_M_AXI_DATA_WIDTH      : natural;
      C_M_AXI_THREAD_ID_WIDTH : natural;
      C_M_AXI_ADDR_WIDTH      : natural;
      C_DATA_SIZE             : natural;
      C_HAS_FIFO_PORTS        : boolean;
      C_HAS_DIRECT_PORT       : boolean
    );
    port (
      Rd_Start          : in  std_logic;
      Rd_Addr           : in  std_logic_vector(31 downto 0);
      Rd_Len            : in  std_logic_vector(4  downto 0);
      Rd_Size           : in  std_logic_vector(1  downto 0);
      Rd_Exclusive      : in  std_logic;
      Rd_Idle           : out std_logic;
      Rd_Response       : out std_logic_vector(1  downto 0);

      Wr_Start          : in  std_logic;
      Wr_Addr           : in  std_logic_vector(31 downto 0);
      Wr_Len            : in  std_logic_vector(4  downto 0);
      Wr_Size           : in  std_logic_vector(1  downto 0);
      Wr_Exclusive      : in  std_logic;
      Wr_Idle           : out std_logic;
      Wr_Response       : out std_logic_vector(1  downto 0);

      Data_Rd           : in  std_logic;
      Data_Out          : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
      Data_Exists       : out std_logic;

      Data_Wr           : in  std_logic;
      Data_In           : in  std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
      Data_Empty        : out std_logic;

      Direct_Wr_Addr    : in  std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
      Direct_Wr_Len     : in  std_logic_vector(4  downto 0);
      Direct_Wr_Data    : in  std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
      Direct_Wr_Start   : in  std_logic;
      Direct_Wr_Next    : out std_logic;
      Direct_Wr_Done    : out std_logic;
      Direct_Wr_Resp    : out std_logic_vector(1 downto 0);

      LMB_Data_Addr     : out std_logic_vector(0 to C_DATA_SIZE-1);
      LMB_Data_Read     : in  std_logic_vector(0 to C_DATA_SIZE-1);
      LMB_Data_Write    : out std_logic_vector(0 to C_DATA_SIZE-1);
      LMB_Addr_Strobe   : out std_logic;
      LMB_Read_Strobe   : out std_logic;
      LMB_Write_Strobe  : out std_logic;
      LMB_Ready         : in  std_logic;
      LMB_Wait          : in  std_logic;
      LMB_UE            : in  std_logic;
      LMB_Byte_Enable   : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);
    
      M_AXI_ACLK        : in  std_logic;
      M_AXI_ARESETn     : in  std_logic;

      M_AXI_AWID        : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
      M_AXI_AWADDR      : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
      M_AXI_AWLEN       : out std_logic_vector(7 downto 0);
      M_AXI_AWSIZE      : out std_logic_vector(2 downto 0);
      M_AXI_AWBURST     : out std_logic_vector(1 downto 0);
      M_AXI_AWLOCK      : out std_logic;
      M_AXI_AWCACHE     : out std_logic_vector(3 downto 0);
      M_AXI_AWPROT      : out std_logic_vector(2 downto 0);
      M_AXI_AWQOS       : out std_logic_vector(3 downto 0);
      M_AXI_AWVALID     : out std_logic;
      M_AXI_AWREADY     : in  std_logic;

      M_AXI_WLAST       : out std_logic;
      M_AXI_WDATA       : out std_logic_vector(31 downto 0);
      M_AXI_WSTRB       : out std_logic_vector(3 downto 0);
      M_AXI_WVALID      : out std_logic;
      M_AXI_WREADY      : in  std_logic;

      M_AXI_BRESP       : in  std_logic_vector(1 downto 0);
      M_AXI_BID         : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
      M_AXI_BVALID      : in  std_logic;
      M_AXI_BREADY      : out std_logic;

      M_AXI_ARADDR      : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
      M_AXI_ARID        : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
      M_AXI_ARLEN       : out std_logic_vector(7 downto 0);
      M_AXI_ARSIZE      : out std_logic_vector(2 downto 0);
      M_AXI_ARBURST     : out std_logic_vector(1 downto 0);
      M_AXI_ARLOCK      : out std_logic;
      M_AXI_ARCACHE     : out std_logic_vector(3 downto 0);
      M_AXI_ARPROT      : out std_logic_vector(2 downto 0);
      M_AXI_ARQOS       : out std_logic_vector(3 downto 0);
      M_AXI_ARVALID     : out std_logic;
      M_AXI_ARREADY     : in  std_logic;

      M_AXI_RLAST       : in  std_logic;
      M_AXI_RID         : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
      M_AXI_RDATA       : in  std_logic_vector(31 downto 0);
      M_AXI_RRESP       : in  std_logic_vector(1 downto 0);
      M_AXI_RVALID      : in  std_logic;
      M_AXI_RREADY      : out std_logic
    );
  end component bus_master;

  --------------------------------------------------------------------------
  -- Functions
  --------------------------------------------------------------------------  

  -- Returns at least 1
  function MakePos (a : integer) return integer is
  begin
    if a < 1 then
      return 1;
    else
      return a;
    end if;
  end function MakePos;

  constant C_EN_WIDTH : integer := MakePos(C_MB_DBG_PORTS);

  --------------------------------------------------------------------------
  -- Signal declarations
  --------------------------------------------------------------------------
  signal tdi     : std_logic;
  signal reset   : std_logic;
  signal update  : std_logic;
  signal capture : std_logic;
  signal shift   : std_logic;
  signal sel     : std_logic;
  signal drck    : std_logic;
  signal tdo     : std_logic;

  signal drck_i   : std_logic;
  signal update_i : std_logic;

  signal dbgreg_drck   : std_logic;
  signal dbgreg_update : std_logic;
  signal dbgreg_select : std_logic;
  signal jtag_busy     : std_logic;

  signal bus2ip_clk    : std_logic;
  signal bus2ip_resetn : std_logic;
  signal ip2bus_data   : std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0) := (others => '0');
  signal ip2bus_error  : std_logic                                         := '0';
  signal ip2bus_wrack  : std_logic                                         := '0';
  signal ip2bus_rdack  : std_logic                                         := '0';
  signal bus2ip_data   : std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0);
  signal bus2ip_cs     : std_logic_vector(((C_ARD_ADDR_RANGE_ARRAY'length)/2)-1 downto 0);
  signal bus2ip_rdce   : std_logic_vector(calc_num_ce(C_ARD_NUM_CE_ARRAY)-1 downto 0);
  signal bus2ip_wrce   : std_logic_vector(calc_num_ce(C_ARD_NUM_CE_ARRAY)-1 downto 0);

  signal mb_debug_enabled   : std_logic_vector(C_EN_WIDTH-1 downto 0);
  signal master_rd_start    : std_logic;
  signal master_rd_addr     : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
  signal master_rd_len      : std_logic_vector(4 downto 0);
  signal master_rd_size     : std_logic_vector(1 downto 0);
  signal master_rd_excl     : std_logic;
  signal master_rd_idle     : std_logic;
  signal master_rd_resp     : std_logic_vector(1 downto 0);
  signal master_wr_start    : std_logic;
  signal master_wr_addr     : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
  signal master_wr_len      : std_logic_vector(4 downto 0);
  signal master_wr_size     : std_logic_vector(1 downto 0);
  signal master_wr_excl     : std_logic;
  signal master_wr_idle     : std_logic;
  signal master_wr_resp     : std_logic_vector(1 downto 0);
  signal master_data_rd     : std_logic;
  signal master_data_out    : std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
  signal master_data_exists : std_logic;
  signal master_data_wr     : std_logic;
  signal master_data_in     : std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
  signal master_data_empty  : std_logic;

  signal master_dwr_addr    : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
  signal master_dwr_len     : std_logic_vector(4 downto 0);
  signal master_dwr_data    : std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
  signal master_dwr_start   : std_logic;
  signal master_dwr_next    : std_logic;
  signal master_dwr_done    : std_logic;
  signal master_dwr_resp    : std_logic_vector(1 downto 0);

  signal ext_trig_in        : std_logic_vector(0 to 3);
  signal ext_trig_Ack_In    : std_logic_vector(0 to 3);
  signal ext_trig_out       : std_logic_vector(0 to 3);
  signal ext_trig_Ack_Out   : std_logic_vector(0 to 3);

  --------------------------------------------------------------------------
  -- Attibute declarations
  --------------------------------------------------------------------------
  attribute period           : string;
  attribute period of update : signal is "200 ns";

  attribute buffer_type                : string;
  attribute buffer_type of update_i    : signal is "none";
  attribute buffer_type of MDM_Core_I1 : label is "none";

begin  -- architecture IMP

  Use_E2 : if C_USE_BSCAN /= 2 generate
  begin
    BSCANE2_I : BSCANE2
      generic map (
        DISABLE_JTAG => "FALSE",
        JTAG_CHAIN   => C_JTAG_CHAIN)
      port map (
        CAPTURE      => capture,          -- [out std_logic]
        DRCK         => drck_i,           -- [out std_logic]
        RESET        => reset,            -- [out std_logic]
        RUNTEST      => open,             -- [out std_logic]
        SEL          => sel,              -- [out std_logic]
        SHIFT        => shift,            -- [out std_logic]
        TCK          => open,             -- [out std_logic]
        TDI          => tdi,              -- [out std_logic]
        TMS          => open,             -- [out std_logic]
        UPDATE       => update_i,         -- [out std_logic]
        TDO          => tdo);             -- [in  std_logic]
  end generate Use_E2;

  Use_External : if C_USE_BSCAN = 2 generate
  begin
    capture       <= bscan_ext_capture;
    drck_i        <= bscan_ext_drck;
    reset         <= bscan_ext_reset;
    sel           <= bscan_ext_sel;
    shift         <= bscan_ext_shift;
    tdi           <= bscan_ext_tdi;
    update_i      <= bscan_ext_update;
    bscan_ext_tdo <= tdo;
  end generate Use_External;

  No_External : if C_USE_BSCAN /= 2 generate
  begin
    bscan_ext_tdo <= '0';
  end generate No_External;

  Use_Dbg_Reg_Access : if C_DBG_REG_ACCESS = 1 generate
    signal dbgreg_select_n : std_logic;
    signal dbgreg_drck_i   : std_logic;
    signal dbgreg_update_i : std_logic;
    signal update_set      : std_logic;
    signal update_reset    : std_logic;
  begin

    dbgreg_select_n <= not dbgreg_select;

    -- drck <= dbgreg_drck when dbgreg_select = '1' else drck_i;

    BUFG_DRCK : BUFG
      port map (
        O => dbgreg_drck_i,
        I => dbgreg_drck
      );

    BUFGCTRL_DRCK : BUFGCTRL
      generic map (
        INIT_OUT     => 0,
        PRESELECT_I0 => true,
        PRESELECT_I1 => false
      )
      port map (
        O       => drck,
        CE0     => '1',
        CE1     => '1',
        I0      => drck_i,
        I1      => dbgreg_drck_i,
        IGNORE0 => '1',
        IGNORE1 => '1',
        S0      => dbgreg_select_n,
        S1      => dbgreg_select
      );

    -- update <= dbgreg_update when dbgreg_select = '1' else update_i;

    BUFG_UPDATE : BUFG
      port map (
        O => dbgreg_update_i,
        I => dbgreg_update
      );

    BUFGCTRL_UPDATE : BUFGCTRL
      generic map (
        INIT_OUT     => 0,
        PRESELECT_I0 => true,
        PRESELECT_I1 => false
      )
      port map (
        O       => update,
        CE0     => '1',
        CE1     => '1',
        I0      => update_i,
        I1      => dbgreg_update_i,
        IGNORE0 => '1',
        IGNORE1 => '1',
        S0      => dbgreg_select_n,
        S1      => dbgreg_select
      );

    JTAG_Busy_Detect : process (drck_i, sel, update_set, Config_Reset)
    begin
      if sel = '0' or update_set = '1' or Config_Reset = '1' then
        jtag_busy <= '0';
        update_reset <= '1';
      elsif drck_i'event and drck_i = '1' then
        if sel = '1' and capture = '1' then
          jtag_busy <= '1';
        end if;
        update_reset <= '0';
      end if;
    end process JTAG_Busy_Detect;

    JTAG_Update_Detect : process (update_i, update_reset, Config_Reset)
    begin
      if update_reset = '1' or Config_Reset = '1' then
        update_set <= '0';
      elsif update_i'event and update_i = '1' then
        update_set <= '1';
      end if;
    end process JTAG_Update_Detect;

  end generate Use_Dbg_Reg_Access;

  No_Dbg_Reg_Access : if C_DBG_REG_ACCESS = 0 generate
  begin

    BUFG_DRCK : BUFG
      port map (
        O => drck,
        I => drck_i
      );

    update <= update_i;

    jtag_busy <= '0';
  end generate No_Dbg_Reg_Access;

  ---------------------------------------------------------------------------
  -- MDM core
  ---------------------------------------------------------------------------
  MDM_Core_I1 : MDM_Core
    generic map (
      C_JTAG_CHAIN          => C_JTAG_CHAIN,           -- [integer]
      C_USE_BSCAN           => C_USE_BSCAN,            -- [integer]
      C_USE_CONFIG_RESET    => C_USE_CONFIG_RESET,     -- [integer = 0]
      C_BASEADDR            => C_BASEADDR,             -- [std_logic_vector(0 to 31)]
      C_HIGHADDR            => C_HIGHADDR,             -- [std_logic_vector(0 to 31)]
      C_MB_DBG_PORTS        => C_MB_DBG_PORTS,         -- [integer]
      C_EN_WIDTH            => C_EN_WIDTH,             -- [integer]
      C_DBG_REG_ACCESS      => C_DBG_REG_ACCESS,       -- [integer]
      C_REG_NUM_CE          => C_REG_NUM_CE,           -- [integer]
      C_REG_DATA_WIDTH      => C_REG_DATA_WIDTH,       -- [integer]
      C_DBG_MEM_ACCESS      => C_DBG_MEM_ACCESS,       -- [integer]
      C_S_AXI_ACLK_FREQ_HZ  => C_S_AXI_ACLK_FREQ_HZ,   -- [integer]
      C_M_AXI_ADDR_WIDTH    => C_M_AXI_ADDR_WIDTH,     -- [integer]
      C_M_AXI_DATA_WIDTH    => C_M_AXI_DATA_WIDTH,     -- [integer]
      C_USE_CROSS_TRIGGER   => C_USE_CROSS_TRIGGER,    -- [integer]
      C_USE_UART            => C_USE_UART,             -- [integer]
      C_UART_WIDTH          => 8,                      -- [integer]
      C_TRACE_OUTPUT        => C_TRACE_OUTPUT,         -- [integer]
      C_TRACE_DATA_WIDTH    => C_TRACE_DATA_WIDTH,     -- [integer]
      C_TRACE_CLK_FREQ_HZ   => C_TRACE_CLK_FREQ_HZ,    -- [integer]
      C_TRACE_CLK_OUT_PHASE => C_TRACE_CLK_OUT_PHASE,  -- [integer]
      C_M_AXIS_DATA_WIDTH   => C_M_AXIS_DATA_WIDTH,    -- [integer]
      C_M_AXIS_ID_WIDTH     => C_M_AXIS_ID_WIDTH       -- [integer]
    )
    port map (
      -- Global signals
      Config_Reset    => Config_Reset,    -- [in  std_logic]
      Scan_Reset_Sel  => Scan_Reset_Sel,  -- [in  std_logic]
      Scan_Reset      => Scan_Reset,      -- [in  std_logic]

      M_AXIS_ACLK     => M_AXIS_ACLK,     -- [in  std_logic]
      M_AXIS_ARESETN  => M_AXIS_ARESETN,  -- [in  std_logic]

      Interrupt       => Interrupt,       -- [out std_logic]
      Ext_BRK         => Ext_BRK,         -- [out std_logic]
      Ext_NM_BRK      => Ext_NM_BRK,      -- [out std_logic]
      Debug_SYS_Rst   => Debug_SYS_Rst,   -- [out std_logic]

      -- Debug Register Access signals
      DbgReg_DRCK   => dbgreg_drck,     -- [out std_logic]
      DbgReg_UPDATE => dbgreg_update,   -- [out std_logic]
      DbgReg_Select => dbgreg_select,   -- [out std_logic]
      JTAG_Busy     => jtag_busy,       -- [in std_logic]

      -- AXI IPIC signals
      bus2ip_clk    => bus2ip_clk,
      bus2ip_resetn => bus2ip_resetn,
      bus2ip_data   => bus2ip_data(C_REG_DATA_WIDTH-1 downto 0),
      bus2ip_rdce   => bus2ip_rdce(C_REG_NUM_CE-1 downto 0),
      bus2ip_wrce   => bus2ip_wrce(C_REG_NUM_CE-1 downto 0),
      bus2ip_cs     => bus2ip_cs(0),
      ip2bus_rdack  => ip2bus_rdack,
      ip2bus_wrack  => ip2bus_wrack,
      ip2bus_error  => ip2bus_error,
      ip2bus_data   => ip2bus_data(C_REG_DATA_WIDTH-1 downto 0),

      -- Bus Master signals
      MB_Debug_Enabled   => mb_debug_enabled,

      M_AXI_ACLK         => M_AXI_ACLK,
      M_AXI_ARESETn      => M_AXI_ARESETn,

      Master_rd_start    => master_rd_start,
      Master_rd_addr     => master_rd_addr,
      Master_rd_len      => master_rd_len,
      Master_rd_size     => master_rd_size,
      Master_rd_excl     => master_rd_excl,
      Master_rd_idle     => master_rd_idle,
      Master_rd_resp     => master_rd_resp,
      Master_wr_start    => master_wr_start,
      Master_wr_addr     => master_wr_addr,
      Master_wr_len      => master_wr_len,
      Master_wr_size     => master_wr_size,
      Master_wr_excl     => master_wr_excl,
      Master_wr_idle     => master_wr_idle,
      Master_wr_resp     => master_wr_resp,
      Master_data_rd     => master_data_rd,
      Master_data_out    => master_data_out,
      Master_data_exists => master_data_exists,
      Master_data_wr     => master_data_wr,
      Master_data_in     => master_data_in,
      Master_data_empty  => master_data_empty,

      Master_dwr_addr    => master_dwr_addr,
      Master_dwr_len     => master_dwr_len,
      Master_dwr_data    => master_dwr_data,
      Master_dwr_start   => master_dwr_start,
      Master_dwr_next    => master_dwr_next,
      Master_dwr_done    => master_dwr_done,
      Master_dwr_resp    => master_dwr_resp,

      -- JTAG signals
      JTAG_TDI     => tdi,              -- [in  std_logic]
      JTAG_RESET   => reset,            -- [in  std_logic]
      UPDATE       => update,           -- [in  std_logic]
      JTAG_SHIFT   => shift,            -- [in  std_logic]
      JTAG_CAPTURE => capture,          -- [in  std_logic]
      SEL          => sel,              -- [in  std_logic]
      DRCK         => drck,             -- [in  std_logic]
      JTAG_TDO     => tdo,              -- [out std_logic]

      -- External Trace AXI Stream output
      M_AXIS_TDATA       => M_AXIS_TDATA,   -- [out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0)]
      M_AXIS_TID         => M_AXIS_TID,     -- [out std_logic_vector(C_M_AXIS_ID_WIDTH-1 downto 0)]
      M_AXIS_TREADY      => M_AXIS_TREADY,  -- [in  std_logic]
      M_AXIS_TVALID      => M_AXIS_TVALID,  -- [out std_logic]

      -- External Trace output
      TRACE_CLK_OUT      => TRACE_CLK_OUT,  -- [out std_logic]
      TRACE_CLK          => TRACE_CLK,      -- [in  std_logic]
      TRACE_CTL          => TRACE_CTL,      -- [out std_logic]
      TRACE_DATA         => TRACE_DATA,     -- [out std_logic_vector(C_TRACE_DATA_WIDTH-1 downto 0)]

      -- MicroBlaze Debug Signals
      Dbg_Clk_0          => Dbg_Clk_0,          -- [out std_logic]
      Dbg_TDI_0          => Dbg_TDI_0,          -- [out std_logic]
      Dbg_TDO_0          => Dbg_TDO_0,          -- [in  std_logic]
      Dbg_Reg_En_0       => Dbg_Reg_En_0,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_0      => Dbg_Capture_0,      -- [out std_logic]
      Dbg_Shift_0        => Dbg_Shift_0,        -- [out std_logic]
      Dbg_Update_0       => Dbg_Update_0,       -- [out std_logic]
      Dbg_Rst_0          => Dbg_Rst_0,          -- [out std_logic]
      Dbg_Trig_In_0      => Dbg_Trig_In_0,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_0  => Dbg_Trig_Ack_In_0,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_0     => Dbg_Trig_Out_0,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_0 => Dbg_Trig_Ack_Out_0, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_0        => Dbg_TrClk_0,        -- [out std_logic]
      Dbg_TrData_0       => Dbg_TrData_0,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_0      => Dbg_TrReady_0,      -- [out std_logic]
      Dbg_TrValid_0      => Dbg_TrValid_0,      -- [in  std_logic]

      Dbg_Clk_1          => Dbg_Clk_1,          -- [out std_logic]
      Dbg_TDI_1          => Dbg_TDI_1,          -- [out std_logic]
      Dbg_TDO_1          => Dbg_TDO_1,          -- [in  std_logic]
      Dbg_Reg_En_1       => Dbg_Reg_En_1,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_1      => Dbg_Capture_1,      -- [out std_logic]
      Dbg_Shift_1        => Dbg_Shift_1,        -- [out std_logic]
      Dbg_Update_1       => Dbg_Update_1,       -- [out std_logic]
      Dbg_Rst_1          => Dbg_Rst_1,          -- [out std_logic]
      Dbg_Trig_In_1      => Dbg_Trig_In_1,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_1  => Dbg_Trig_Ack_In_1,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_1     => Dbg_Trig_Out_1,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_1 => Dbg_Trig_Ack_Out_1, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_1        => Dbg_TrClk_1,        -- [out std_logic]
      Dbg_TrData_1       => Dbg_TrData_1,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_1      => Dbg_TrReady_1,      -- [out std_logic]
      Dbg_TrValid_1      => Dbg_TrValid_1,      -- [in  std_logic]

      Dbg_Clk_2          => Dbg_Clk_2,          -- [out std_logic]
      Dbg_TDI_2          => Dbg_TDI_2,          -- [out std_logic]
      Dbg_TDO_2          => Dbg_TDO_2,          -- [in  std_logic]
      Dbg_Reg_En_2       => Dbg_Reg_En_2,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_2      => Dbg_Capture_2,      -- [out std_logic]
      Dbg_Shift_2        => Dbg_Shift_2,        -- [out std_logic]
      Dbg_Update_2       => Dbg_Update_2,       -- [out std_logic]
      Dbg_Rst_2          => Dbg_Rst_2,          -- [out std_logic]
      Dbg_Trig_In_2      => Dbg_Trig_In_2,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_2  => Dbg_Trig_Ack_In_2,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_2     => Dbg_Trig_Out_2,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_2 => Dbg_Trig_Ack_Out_2, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_2        => Dbg_TrClk_2,        -- [out std_logic]
      Dbg_TrData_2       => Dbg_TrData_2,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_2      => Dbg_TrReady_2,      -- [out std_logic]
      Dbg_TrValid_2      => Dbg_TrValid_2,      -- [in  std_logic]

      Dbg_Clk_3          => Dbg_Clk_3,          -- [out std_logic]
      Dbg_TDI_3          => Dbg_TDI_3,          -- [out std_logic]
      Dbg_TDO_3          => Dbg_TDO_3,          -- [in  std_logic]
      Dbg_Reg_En_3       => Dbg_Reg_En_3,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_3      => Dbg_Capture_3,      -- [out std_logic]
      Dbg_Shift_3        => Dbg_Shift_3,        -- [out std_logic]
      Dbg_Update_3       => Dbg_Update_3,       -- [out std_logic]
      Dbg_Rst_3          => Dbg_Rst_3,          -- [out std_logic]
      Dbg_Trig_In_3      => Dbg_Trig_In_3,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_3  => Dbg_Trig_Ack_In_3,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_3     => Dbg_Trig_Out_3,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_3 => Dbg_Trig_Ack_Out_3, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_3        => Dbg_TrClk_3,        -- [out std_logic]
      Dbg_TrData_3       => Dbg_TrData_3,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_3      => Dbg_TrReady_3,      -- [out std_logic]
      Dbg_TrValid_3      => Dbg_TrValid_3,      -- [in  std_logic]

      Dbg_Clk_4          => Dbg_Clk_4,          -- [out std_logic]
      Dbg_TDI_4          => Dbg_TDI_4,          -- [out std_logic]
      Dbg_TDO_4          => Dbg_TDO_4,          -- [in  std_logic]
      Dbg_Reg_En_4       => Dbg_Reg_En_4,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_4      => Dbg_Capture_4,      -- [out std_logic]
      Dbg_Shift_4        => Dbg_Shift_4,        -- [out std_logic]
      Dbg_Update_4       => Dbg_Update_4,       -- [out std_logic]
      Dbg_Rst_4          => Dbg_Rst_4,          -- [out std_logic]
      Dbg_Trig_In_4      => Dbg_Trig_In_4,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_4  => Dbg_Trig_Ack_In_4,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_4     => Dbg_Trig_Out_4,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_4 => Dbg_Trig_Ack_Out_4, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_4        => Dbg_TrClk_4,        -- [out std_logic]
      Dbg_TrData_4       => Dbg_TrData_4,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_4      => Dbg_TrReady_4,      -- [out std_logic]
      Dbg_TrValid_4      => Dbg_TrValid_4,      -- [in  std_logic]

      Dbg_Clk_5          => Dbg_Clk_5,          -- [out std_logic]
      Dbg_TDI_5          => Dbg_TDI_5,          -- [out std_logic]
      Dbg_TDO_5          => Dbg_TDO_5,          -- [in  std_logic]
      Dbg_Reg_En_5       => Dbg_Reg_En_5,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_5      => Dbg_Capture_5,      -- [out std_logic]
      Dbg_Shift_5        => Dbg_Shift_5,        -- [out std_logic]
      Dbg_Update_5       => Dbg_Update_5,       -- [out std_logic]
      Dbg_Rst_5          => Dbg_Rst_5,          -- [out std_logic]
      Dbg_Trig_In_5      => Dbg_Trig_In_5,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_5  => Dbg_Trig_Ack_In_5,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_5     => Dbg_Trig_Out_5,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_5 => Dbg_Trig_Ack_Out_5, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_5        => Dbg_TrClk_5,        -- [out std_logic]
      Dbg_TrData_5       => Dbg_TrData_5,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_5      => Dbg_TrReady_5,      -- [out std_logic]
      Dbg_TrValid_5      => Dbg_TrValid_5,      -- [in  std_logic]

      Dbg_Clk_6          => Dbg_Clk_6,          -- [out std_logic]
      Dbg_TDI_6          => Dbg_TDI_6,          -- [out std_logic]
      Dbg_TDO_6          => Dbg_TDO_6,          -- [in  std_logic]
      Dbg_Reg_En_6       => Dbg_Reg_En_6,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_6      => Dbg_Capture_6,      -- [out std_logic]
      Dbg_Shift_6        => Dbg_Shift_6,        -- [out std_logic]
      Dbg_Update_6       => Dbg_Update_6,       -- [out std_logic]
      Dbg_Rst_6          => Dbg_Rst_6,          -- [out std_logic]
      Dbg_Trig_In_6      => Dbg_Trig_In_6,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_6  => Dbg_Trig_Ack_In_6,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_6     => Dbg_Trig_Out_6,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_6 => Dbg_Trig_Ack_Out_6, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_6        => Dbg_TrClk_6,        -- [out std_logic]
      Dbg_TrData_6       => Dbg_TrData_6,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_6      => Dbg_TrReady_6,      -- [out std_logic]
      Dbg_TrValid_6      => Dbg_TrValid_6,      -- [in  std_logic]

      Dbg_Clk_7          => Dbg_Clk_7,          -- [out std_logic]
      Dbg_TDI_7          => Dbg_TDI_7,          -- [out std_logic]
      Dbg_TDO_7          => Dbg_TDO_7,          -- [in  std_logic]
      Dbg_Reg_En_7       => Dbg_Reg_En_7,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_7      => Dbg_Capture_7,      -- [out std_logic]
      Dbg_Shift_7        => Dbg_Shift_7,        -- [out std_logic]
      Dbg_Update_7       => Dbg_Update_7,       -- [out std_logic]
      Dbg_Rst_7          => Dbg_Rst_7,          -- [out std_logic]
      Dbg_Trig_In_7      => Dbg_Trig_In_7,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_7  => Dbg_Trig_Ack_In_7,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_7     => Dbg_Trig_Out_7,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_7 => Dbg_Trig_Ack_Out_7, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_7        => Dbg_TrClk_7,        -- [out std_logic]
      Dbg_TrData_7       => Dbg_TrData_7,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_7      => Dbg_TrReady_7,      -- [out std_logic]
      Dbg_TrValid_7      => Dbg_TrValid_7,      -- [in  std_logic]

      Dbg_Clk_8          => Dbg_Clk_8,          -- [out std_logic]
      Dbg_TDI_8          => Dbg_TDI_8,          -- [out std_logic]
      Dbg_TDO_8          => Dbg_TDO_8,          -- [in  std_logic]
      Dbg_Reg_En_8       => Dbg_Reg_En_8,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_8      => Dbg_Capture_8,      -- [out std_logic]
      Dbg_Shift_8        => Dbg_Shift_8,        -- [out std_logic]
      Dbg_Update_8       => Dbg_Update_8,       -- [out std_logic]
      Dbg_Rst_8          => Dbg_Rst_8,          -- [out std_logic]
      Dbg_Trig_In_8      => Dbg_Trig_In_8,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_8  => Dbg_Trig_Ack_In_8,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_8     => Dbg_Trig_Out_8,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_8 => Dbg_Trig_Ack_Out_8, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_8        => Dbg_TrClk_8,        -- [out std_logic]
      Dbg_TrData_8       => Dbg_TrData_8,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_8      => Dbg_TrReady_8,      -- [out std_logic]
      Dbg_TrValid_8      => Dbg_TrValid_8,      -- [in  std_logic]

      Dbg_Clk_9          => Dbg_Clk_9,          -- [out std_logic]
      Dbg_TDI_9          => Dbg_TDI_9,          -- [out std_logic]
      Dbg_TDO_9          => Dbg_TDO_9,          -- [in  std_logic]
      Dbg_Reg_En_9       => Dbg_Reg_En_9,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_9      => Dbg_Capture_9,      -- [out std_logic]
      Dbg_Shift_9        => Dbg_Shift_9,        -- [out std_logic]
      Dbg_Update_9       => Dbg_Update_9,       -- [out std_logic]
      Dbg_Rst_9          => Dbg_Rst_9,          -- [out std_logic]
      Dbg_Trig_In_9      => Dbg_Trig_In_9,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_9  => Dbg_Trig_Ack_In_9,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_9     => Dbg_Trig_Out_9,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_9 => Dbg_Trig_Ack_Out_9, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_9        => Dbg_TrClk_9,        -- [out std_logic]
      Dbg_TrData_9       => Dbg_TrData_9,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_9      => Dbg_TrReady_9,      -- [out std_logic]
      Dbg_TrValid_9      => Dbg_TrValid_9,      -- [in  std_logic]

      Dbg_Clk_10          => Dbg_Clk_10,          -- [out std_logic]
      Dbg_TDI_10          => Dbg_TDI_10,          -- [out std_logic]
      Dbg_TDO_10          => Dbg_TDO_10,          -- [in  std_logic]
      Dbg_Reg_En_10       => Dbg_Reg_En_10,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_10      => Dbg_Capture_10,      -- [out std_logic]
      Dbg_Shift_10        => Dbg_Shift_10,        -- [out std_logic]
      Dbg_Update_10       => Dbg_Update_10,       -- [out std_logic]
      Dbg_Rst_10          => Dbg_Rst_10,          -- [out std_logic]
      Dbg_Trig_In_10      => Dbg_Trig_In_10,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_10  => Dbg_Trig_Ack_In_10,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_10     => Dbg_Trig_Out_10,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_10 => Dbg_Trig_Ack_Out_10, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_10        => Dbg_TrClk_10,        -- [out std_logic]
      Dbg_TrData_10       => Dbg_TrData_10,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_10      => Dbg_TrReady_10,      -- [out std_logic]
      Dbg_TrValid_10      => Dbg_TrValid_10,      -- [in  std_logic]

      Dbg_Clk_11          => Dbg_Clk_11,          -- [out std_logic]
      Dbg_TDI_11          => Dbg_TDI_11,          -- [out std_logic]
      Dbg_TDO_11          => Dbg_TDO_11,          -- [in  std_logic]
      Dbg_Reg_En_11       => Dbg_Reg_En_11,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_11      => Dbg_Capture_11,      -- [out std_logic]
      Dbg_Shift_11        => Dbg_Shift_11,        -- [out std_logic]
      Dbg_Update_11       => Dbg_Update_11,       -- [out std_logic]
      Dbg_Rst_11          => Dbg_Rst_11,          -- [out std_logic]
      Dbg_Trig_In_11      => Dbg_Trig_In_11,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_11  => Dbg_Trig_Ack_In_11,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_11     => Dbg_Trig_Out_11,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_11 => Dbg_Trig_Ack_Out_11, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_11        => Dbg_TrClk_11,        -- [out std_logic]
      Dbg_TrData_11       => Dbg_TrData_11,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_11      => Dbg_TrReady_11,      -- [out std_logic]
      Dbg_TrValid_11      => Dbg_TrValid_11,      -- [in  std_logic]

      Dbg_Clk_12          => Dbg_Clk_12,          -- [out std_logic]
      Dbg_TDI_12          => Dbg_TDI_12,          -- [out std_logic]
      Dbg_TDO_12          => Dbg_TDO_12,          -- [in  std_logic]
      Dbg_Reg_En_12       => Dbg_Reg_En_12,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_12      => Dbg_Capture_12,      -- [out std_logic]
      Dbg_Shift_12        => Dbg_Shift_12,        -- [out std_logic]
      Dbg_Update_12       => Dbg_Update_12,       -- [out std_logic]
      Dbg_Rst_12          => Dbg_Rst_12,          -- [out std_logic]
      Dbg_Trig_In_12      => Dbg_Trig_In_12,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_12  => Dbg_Trig_Ack_In_12,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_12     => Dbg_Trig_Out_12,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_12 => Dbg_Trig_Ack_Out_12, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_12        => Dbg_TrClk_12,        -- [out std_logic]
      Dbg_TrData_12       => Dbg_TrData_12,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_12      => Dbg_TrReady_12,      -- [out std_logic]
      Dbg_TrValid_12      => Dbg_TrValid_12,      -- [in  std_logic]

      Dbg_Clk_13          => Dbg_Clk_13,          -- [out std_logic]
      Dbg_TDI_13          => Dbg_TDI_13,          -- [out std_logic]
      Dbg_TDO_13          => Dbg_TDO_13,          -- [in  std_logic]
      Dbg_Reg_En_13       => Dbg_Reg_En_13,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_13      => Dbg_Capture_13,      -- [out std_logic]
      Dbg_Shift_13        => Dbg_Shift_13,        -- [out std_logic]
      Dbg_Update_13       => Dbg_Update_13,       -- [out std_logic]
      Dbg_Rst_13          => Dbg_Rst_13,          -- [out std_logic]
      Dbg_Trig_In_13      => Dbg_Trig_In_13,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_13  => Dbg_Trig_Ack_In_13,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_13     => Dbg_Trig_Out_13,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_13 => Dbg_Trig_Ack_Out_13, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_13        => Dbg_TrClk_13,        -- [out std_logic]
      Dbg_TrData_13       => Dbg_TrData_13,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_13      => Dbg_TrReady_13,      -- [out std_logic]
      Dbg_TrValid_13      => Dbg_TrValid_13,      -- [in  std_logic]

      Dbg_Clk_14          => Dbg_Clk_14,          -- [out std_logic]
      Dbg_TDI_14          => Dbg_TDI_14,          -- [out std_logic]
      Dbg_TDO_14          => Dbg_TDO_14,          -- [in  std_logic]
      Dbg_Reg_En_14       => Dbg_Reg_En_14,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_14      => Dbg_Capture_14,      -- [out std_logic]
      Dbg_Shift_14        => Dbg_Shift_14,        -- [out std_logic]
      Dbg_Update_14       => Dbg_Update_14,       -- [out std_logic]
      Dbg_Rst_14          => Dbg_Rst_14,          -- [out std_logic]
      Dbg_Trig_In_14      => Dbg_Trig_In_14,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_14  => Dbg_Trig_Ack_In_14,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_14     => Dbg_Trig_Out_14,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_14 => Dbg_Trig_Ack_Out_14, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_14        => Dbg_TrClk_14,        -- [out std_logic]
      Dbg_TrData_14       => Dbg_TrData_14,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_14      => Dbg_TrReady_14,      -- [out std_logic]
      Dbg_TrValid_14      => Dbg_TrValid_14,      -- [in  std_logic]

      Dbg_Clk_15          => Dbg_Clk_15,          -- [out std_logic]
      Dbg_TDI_15          => Dbg_TDI_15,          -- [out std_logic]
      Dbg_TDO_15          => Dbg_TDO_15,          -- [in  std_logic]
      Dbg_Reg_En_15       => Dbg_Reg_En_15,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_15      => Dbg_Capture_15,      -- [out std_logic]
      Dbg_Shift_15        => Dbg_Shift_15,        -- [out std_logic]
      Dbg_Update_15       => Dbg_Update_15,       -- [out std_logic]
      Dbg_Rst_15          => Dbg_Rst_15,          -- [out std_logic]
      Dbg_Trig_In_15      => Dbg_Trig_In_15,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_15  => Dbg_Trig_Ack_In_15,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_15     => Dbg_Trig_Out_15,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_15 => Dbg_Trig_Ack_Out_15, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_15        => Dbg_TrClk_15,        -- [out std_logic]
      Dbg_TrData_15       => Dbg_TrData_15,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_15      => Dbg_TrReady_15,      -- [out std_logic]
      Dbg_TrValid_15      => Dbg_TrValid_15,      -- [in  std_logic]

      Dbg_Clk_16          => Dbg_Clk_16,          -- [out std_logic]
      Dbg_TDI_16          => Dbg_TDI_16,          -- [out std_logic]
      Dbg_TDO_16          => Dbg_TDO_16,          -- [in  std_logic]
      Dbg_Reg_En_16       => Dbg_Reg_En_16,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_16      => Dbg_Capture_16,      -- [out std_logic]
      Dbg_Shift_16        => Dbg_Shift_16,        -- [out std_logic]
      Dbg_Update_16       => Dbg_Update_16,       -- [out std_logic]
      Dbg_Rst_16          => Dbg_Rst_16,          -- [out std_logic]
      Dbg_Trig_In_16      => Dbg_Trig_In_16,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_16  => Dbg_Trig_Ack_In_16,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_16     => Dbg_Trig_Out_16,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_16 => Dbg_Trig_Ack_Out_16, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_16        => Dbg_TrClk_16,        -- [out std_logic]
      Dbg_TrData_16       => Dbg_TrData_16,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_16      => Dbg_TrReady_16,      -- [out std_logic]
      Dbg_TrValid_16      => Dbg_TrValid_16,      -- [in  std_logic]

      Dbg_Clk_17          => Dbg_Clk_17,          -- [out std_logic]
      Dbg_TDI_17          => Dbg_TDI_17,          -- [out std_logic]
      Dbg_TDO_17          => Dbg_TDO_17,          -- [in  std_logic]
      Dbg_Reg_En_17       => Dbg_Reg_En_17,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_17      => Dbg_Capture_17,      -- [out std_logic]
      Dbg_Shift_17        => Dbg_Shift_17,        -- [out std_logic]
      Dbg_Update_17       => Dbg_Update_17,       -- [out std_logic]
      Dbg_Rst_17          => Dbg_Rst_17,          -- [out std_logic]
      Dbg_Trig_In_17      => Dbg_Trig_In_17,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_17  => Dbg_Trig_Ack_In_17,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_17     => Dbg_Trig_Out_17,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_17 => Dbg_Trig_Ack_Out_17, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_17        => Dbg_TrClk_17,        -- [out std_logic]
      Dbg_TrData_17       => Dbg_TrData_17,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_17      => Dbg_TrReady_17,      -- [out std_logic]
      Dbg_TrValid_17      => Dbg_TrValid_17,      -- [in  std_logic]

      Dbg_Clk_18          => Dbg_Clk_18,          -- [out std_logic]
      Dbg_TDI_18          => Dbg_TDI_18,          -- [out std_logic]
      Dbg_TDO_18          => Dbg_TDO_18,          -- [in  std_logic]
      Dbg_Reg_En_18       => Dbg_Reg_En_18,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_18      => Dbg_Capture_18,      -- [out std_logic]
      Dbg_Shift_18        => Dbg_Shift_18,        -- [out std_logic]
      Dbg_Update_18       => Dbg_Update_18,       -- [out std_logic]
      Dbg_Rst_18          => Dbg_Rst_18,          -- [out std_logic]
      Dbg_Trig_In_18      => Dbg_Trig_In_18,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_18  => Dbg_Trig_Ack_In_18,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_18     => Dbg_Trig_Out_18,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_18 => Dbg_Trig_Ack_Out_18, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_18        => Dbg_TrClk_18,        -- [out std_logic]
      Dbg_TrData_18       => Dbg_TrData_18,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_18      => Dbg_TrReady_18,      -- [out std_logic]
      Dbg_TrValid_18      => Dbg_TrValid_18,      -- [in  std_logic]

      Dbg_Clk_19          => Dbg_Clk_19,          -- [out std_logic]
      Dbg_TDI_19          => Dbg_TDI_19,          -- [out std_logic]
      Dbg_TDO_19          => Dbg_TDO_19,          -- [in  std_logic]
      Dbg_Reg_En_19       => Dbg_Reg_En_19,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_19      => Dbg_Capture_19,      -- [out std_logic]
      Dbg_Shift_19        => Dbg_Shift_19,        -- [out std_logic]
      Dbg_Update_19       => Dbg_Update_19,       -- [out std_logic]
      Dbg_Rst_19          => Dbg_Rst_19,          -- [out std_logic]
      Dbg_Trig_In_19      => Dbg_Trig_In_19,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_19  => Dbg_Trig_Ack_In_19,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_19     => Dbg_Trig_Out_19,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_19 => Dbg_Trig_Ack_Out_19, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_19        => Dbg_TrClk_19,        -- [out std_logic]
      Dbg_TrData_19       => Dbg_TrData_19,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_19      => Dbg_TrReady_19,      -- [out std_logic]
      Dbg_TrValid_19      => Dbg_TrValid_19,      -- [in  std_logic]

      Dbg_Clk_20          => Dbg_Clk_20,          -- [out std_logic]
      Dbg_TDI_20          => Dbg_TDI_20,          -- [out std_logic]
      Dbg_TDO_20          => Dbg_TDO_20,          -- [in  std_logic]
      Dbg_Reg_En_20       => Dbg_Reg_En_20,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_20      => Dbg_Capture_20,      -- [out std_logic]
      Dbg_Shift_20        => Dbg_Shift_20,        -- [out std_logic]
      Dbg_Update_20       => Dbg_Update_20,       -- [out std_logic]
      Dbg_Rst_20          => Dbg_Rst_20,          -- [out std_logic]
      Dbg_Trig_In_20      => Dbg_Trig_In_20,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_20  => Dbg_Trig_Ack_In_20,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_20     => Dbg_Trig_Out_20,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_20 => Dbg_Trig_Ack_Out_20, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_20        => Dbg_TrClk_20,        -- [out std_logic]
      Dbg_TrData_20       => Dbg_TrData_20,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_20      => Dbg_TrReady_20,      -- [out std_logic]
      Dbg_TrValid_20      => Dbg_TrValid_20,      -- [in  std_logic]

      Dbg_Clk_21          => Dbg_Clk_21,          -- [out std_logic]
      Dbg_TDI_21          => Dbg_TDI_21,          -- [out std_logic]
      Dbg_TDO_21          => Dbg_TDO_21,          -- [in  std_logic]
      Dbg_Reg_En_21       => Dbg_Reg_En_21,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_21      => Dbg_Capture_21,      -- [out std_logic]
      Dbg_Shift_21        => Dbg_Shift_21,        -- [out std_logic]
      Dbg_Update_21       => Dbg_Update_21,       -- [out std_logic]
      Dbg_Rst_21          => Dbg_Rst_21,          -- [out std_logic]
      Dbg_Trig_In_21      => Dbg_Trig_In_21,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_21  => Dbg_Trig_Ack_In_21,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_21     => Dbg_Trig_Out_21,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_21 => Dbg_Trig_Ack_Out_21, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_21        => Dbg_TrClk_21,        -- [out std_logic]
      Dbg_TrData_21       => Dbg_TrData_21,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_21      => Dbg_TrReady_21,      -- [out std_logic]
      Dbg_TrValid_21      => Dbg_TrValid_21,      -- [in  std_logic]

      Dbg_Clk_22          => Dbg_Clk_22,          -- [out std_logic]
      Dbg_TDI_22          => Dbg_TDI_22,          -- [out std_logic]
      Dbg_TDO_22          => Dbg_TDO_22,          -- [in  std_logic]
      Dbg_Reg_En_22       => Dbg_Reg_En_22,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_22      => Dbg_Capture_22,      -- [out std_logic]
      Dbg_Shift_22        => Dbg_Shift_22,        -- [out std_logic]
      Dbg_Update_22       => Dbg_Update_22,       -- [out std_logic]
      Dbg_Rst_22          => Dbg_Rst_22,          -- [out std_logic]
      Dbg_Trig_In_22      => Dbg_Trig_In_22,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_22  => Dbg_Trig_Ack_In_22,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_22     => Dbg_Trig_Out_22,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_22 => Dbg_Trig_Ack_Out_22, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_22        => Dbg_TrClk_22,        -- [out std_logic]
      Dbg_TrData_22       => Dbg_TrData_22,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_22      => Dbg_TrReady_22,      -- [out std_logic]
      Dbg_TrValid_22      => Dbg_TrValid_22,      -- [in  std_logic]

      Dbg_Clk_23          => Dbg_Clk_23,          -- [out std_logic]
      Dbg_TDI_23          => Dbg_TDI_23,          -- [out std_logic]
      Dbg_TDO_23          => Dbg_TDO_23,          -- [in  std_logic]
      Dbg_Reg_En_23       => Dbg_Reg_En_23,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_23      => Dbg_Capture_23,      -- [out std_logic]
      Dbg_Shift_23        => Dbg_Shift_23,        -- [out std_logic]
      Dbg_Update_23       => Dbg_Update_23,       -- [out std_logic]
      Dbg_Rst_23          => Dbg_Rst_23,          -- [out std_logic]
      Dbg_Trig_In_23      => Dbg_Trig_In_23,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_23  => Dbg_Trig_Ack_In_23,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_23     => Dbg_Trig_Out_23,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_23 => Dbg_Trig_Ack_Out_23, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_23        => Dbg_TrClk_23,        -- [out std_logic]
      Dbg_TrData_23       => Dbg_TrData_23,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_23      => Dbg_TrReady_23,      -- [out std_logic]
      Dbg_TrValid_23      => Dbg_TrValid_23,      -- [in  std_logic]

      Dbg_Clk_24          => Dbg_Clk_24,          -- [out std_logic]
      Dbg_TDI_24          => Dbg_TDI_24,          -- [out std_logic]
      Dbg_TDO_24          => Dbg_TDO_24,          -- [in  std_logic]
      Dbg_Reg_En_24       => Dbg_Reg_En_24,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_24      => Dbg_Capture_24,      -- [out std_logic]
      Dbg_Shift_24        => Dbg_Shift_24,        -- [out std_logic]
      Dbg_Update_24       => Dbg_Update_24,       -- [out std_logic]
      Dbg_Rst_24          => Dbg_Rst_24,          -- [out std_logic]
      Dbg_Trig_In_24      => Dbg_Trig_In_24,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_24  => Dbg_Trig_Ack_In_24,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_24     => Dbg_Trig_Out_24,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_24 => Dbg_Trig_Ack_Out_24, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_24        => Dbg_TrClk_24,        -- [out std_logic]
      Dbg_TrData_24       => Dbg_TrData_24,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_24      => Dbg_TrReady_24,      -- [out std_logic]
      Dbg_TrValid_24      => Dbg_TrValid_24,      -- [in  std_logic]

      Dbg_Clk_25          => Dbg_Clk_25,          -- [out std_logic]
      Dbg_TDI_25          => Dbg_TDI_25,          -- [out std_logic]
      Dbg_TDO_25          => Dbg_TDO_25,          -- [in  std_logic]
      Dbg_Reg_En_25       => Dbg_Reg_En_25,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_25      => Dbg_Capture_25,      -- [out std_logic]
      Dbg_Shift_25        => Dbg_Shift_25,        -- [out std_logic]
      Dbg_Update_25       => Dbg_Update_25,       -- [out std_logic]
      Dbg_Rst_25          => Dbg_Rst_25,          -- [out std_logic]
      Dbg_Trig_In_25      => Dbg_Trig_In_25,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_25  => Dbg_Trig_Ack_In_25,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_25     => Dbg_Trig_Out_25,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_25 => Dbg_Trig_Ack_Out_25, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_25        => Dbg_TrClk_25,        -- [out std_logic]
      Dbg_TrData_25       => Dbg_TrData_25,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_25      => Dbg_TrReady_25,      -- [out std_logic]
      Dbg_TrValid_25      => Dbg_TrValid_25,      -- [in  std_logic]

      Dbg_Clk_26          => Dbg_Clk_26,          -- [out std_logic]
      Dbg_TDI_26          => Dbg_TDI_26,          -- [out std_logic]
      Dbg_TDO_26          => Dbg_TDO_26,          -- [in  std_logic]
      Dbg_Reg_En_26       => Dbg_Reg_En_26,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_26      => Dbg_Capture_26,      -- [out std_logic]
      Dbg_Shift_26        => Dbg_Shift_26,        -- [out std_logic]
      Dbg_Update_26       => Dbg_Update_26,       -- [out std_logic]
      Dbg_Rst_26          => Dbg_Rst_26,          -- [out std_logic]
      Dbg_Trig_In_26      => Dbg_Trig_In_26,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_26  => Dbg_Trig_Ack_In_26,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_26     => Dbg_Trig_Out_26,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_26 => Dbg_Trig_Ack_Out_26, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_26        => Dbg_TrClk_26,        -- [out std_logic]
      Dbg_TrData_26       => Dbg_TrData_26,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_26      => Dbg_TrReady_26,      -- [out std_logic]
      Dbg_TrValid_26      => Dbg_TrValid_26,      -- [in  std_logic]

      Dbg_Clk_27          => Dbg_Clk_27,          -- [out std_logic]
      Dbg_TDI_27          => Dbg_TDI_27,          -- [out std_logic]
      Dbg_TDO_27          => Dbg_TDO_27,          -- [in  std_logic]
      Dbg_Reg_En_27       => Dbg_Reg_En_27,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_27      => Dbg_Capture_27,      -- [out std_logic]
      Dbg_Shift_27        => Dbg_Shift_27,        -- [out std_logic]
      Dbg_Update_27       => Dbg_Update_27,       -- [out std_logic]
      Dbg_Rst_27          => Dbg_Rst_27,          -- [out std_logic]
      Dbg_Trig_In_27      => Dbg_Trig_In_27,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_27  => Dbg_Trig_Ack_In_27,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_27     => Dbg_Trig_Out_27,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_27 => Dbg_Trig_Ack_Out_27, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_27        => Dbg_TrClk_27,        -- [out std_logic]
      Dbg_TrData_27       => Dbg_TrData_27,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_27      => Dbg_TrReady_27,      -- [out std_logic]
      Dbg_TrValid_27      => Dbg_TrValid_27,      -- [in  std_logic]

      Dbg_Clk_28          => Dbg_Clk_28,          -- [out std_logic]
      Dbg_TDI_28          => Dbg_TDI_28,          -- [out std_logic]
      Dbg_TDO_28          => Dbg_TDO_28,          -- [in  std_logic]
      Dbg_Reg_En_28       => Dbg_Reg_En_28,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_28      => Dbg_Capture_28,      -- [out std_logic]
      Dbg_Shift_28        => Dbg_Shift_28,        -- [out std_logic]
      Dbg_Update_28       => Dbg_Update_28,       -- [out std_logic]
      Dbg_Rst_28          => Dbg_Rst_28,          -- [out std_logic]
      Dbg_Trig_In_28      => Dbg_Trig_In_28,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_28  => Dbg_Trig_Ack_In_28,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_28     => Dbg_Trig_Out_28,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_28 => Dbg_Trig_Ack_Out_28, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_28        => Dbg_TrClk_28,        -- [out std_logic]
      Dbg_TrData_28       => Dbg_TrData_28,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_28      => Dbg_TrReady_28,      -- [out std_logic]
      Dbg_TrValid_28      => Dbg_TrValid_28,      -- [in  std_logic]

      Dbg_Clk_29          => Dbg_Clk_29,          -- [out std_logic]
      Dbg_TDI_29          => Dbg_TDI_29,          -- [out std_logic]
      Dbg_TDO_29          => Dbg_TDO_29,          -- [in  std_logic]
      Dbg_Reg_En_29       => Dbg_Reg_En_29,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_29      => Dbg_Capture_29,      -- [out std_logic]
      Dbg_Shift_29        => Dbg_Shift_29,        -- [out std_logic]
      Dbg_Update_29       => Dbg_Update_29,       -- [out std_logic]
      Dbg_Rst_29          => Dbg_Rst_29,          -- [out std_logic]
      Dbg_Trig_In_29      => Dbg_Trig_In_29,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_29  => Dbg_Trig_Ack_In_29,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_29     => Dbg_Trig_Out_29,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_29 => Dbg_Trig_Ack_Out_29, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_29        => Dbg_TrClk_29,        -- [out std_logic]
      Dbg_TrData_29       => Dbg_TrData_29,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_29      => Dbg_TrReady_29,      -- [out std_logic]
      Dbg_TrValid_29      => Dbg_TrValid_29,      -- [in  std_logic]

      Dbg_Clk_30          => Dbg_Clk_30,          -- [out std_logic]
      Dbg_TDI_30          => Dbg_TDI_30,          -- [out std_logic]
      Dbg_TDO_30          => Dbg_TDO_30,          -- [in  std_logic]
      Dbg_Reg_En_30       => Dbg_Reg_En_30,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_30      => Dbg_Capture_30,      -- [out std_logic]
      Dbg_Shift_30        => Dbg_Shift_30,        -- [out std_logic]
      Dbg_Update_30       => Dbg_Update_30,       -- [out std_logic]
      Dbg_Rst_30          => Dbg_Rst_30,          -- [out std_logic]
      Dbg_Trig_In_30      => Dbg_Trig_In_30,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_30  => Dbg_Trig_Ack_In_30,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_30     => Dbg_Trig_Out_30,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_30 => Dbg_Trig_Ack_Out_30, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_30        => Dbg_TrClk_30,        -- [out std_logic]
      Dbg_TrData_30       => Dbg_TrData_30,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_30      => Dbg_TrReady_30,      -- [out std_logic]
      Dbg_TrValid_30      => Dbg_TrValid_30,      -- [in  std_logic]

      Dbg_Clk_31          => Dbg_Clk_31,          -- [out std_logic]
      Dbg_TDI_31          => Dbg_TDI_31,          -- [out std_logic]
      Dbg_TDO_31          => Dbg_TDO_31,          -- [in  std_logic]
      Dbg_Reg_En_31       => Dbg_Reg_En_31,       -- [out std_logic_vector(0 to 7)]
      Dbg_Capture_31      => Dbg_Capture_31,      -- [out std_logic]
      Dbg_Shift_31        => Dbg_Shift_31,        -- [out std_logic]
      Dbg_Update_31       => Dbg_Update_31,       -- [out std_logic]
      Dbg_Rst_31          => Dbg_Rst_31,          -- [out std_logic]
      Dbg_Trig_In_31      => Dbg_Trig_In_31,      -- [in  std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_In_31  => Dbg_Trig_Ack_In_31,  -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Out_31     => Dbg_Trig_Out_31,     -- [out std_logic_vector(0 to 7)]
      Dbg_Trig_Ack_Out_31 => Dbg_Trig_Ack_Out_31, -- [in  std_logic_vector(0 to 7)]
      Dbg_TrClk_31        => Dbg_TrClk_31,        -- [out std_logic]
      Dbg_TrData_31       => Dbg_TrData_31,       -- [in  std_logic_vector(0 to 35)]
      Dbg_TrReady_31      => Dbg_TrReady_31,      -- [out std_logic]
      Dbg_TrValid_31      => Dbg_TrValid_31,      -- [in  std_logic]

      Ext_Trig_In        => ext_trig_in,          -- [in  std_logic_vector(0 to 3)]
      Ext_Trig_Ack_In    => ext_trig_ack_in,      -- [out std_logic_vector(0 to 3)]
      Ext_Trig_Out       => ext_trig_out,         -- [out std_logic_vector(0 to 3)]
      Ext_Trig_Ack_Out   => ext_trig_ack_out,     -- [in  std_logic_vector(0 to 3)]

      Ext_JTAG_DRCK      => Ext_JTAG_DRCK,
      Ext_JTAG_RESET     => Ext_JTAG_RESET,
      Ext_JTAG_SEL       => Ext_JTAG_SEL,
      Ext_JTAG_CAPTURE   => Ext_JTAG_CAPTURE,
      Ext_JTAG_SHIFT     => Ext_JTAG_SHIFT,
      Ext_JTAG_UPDATE    => Ext_JTAG_UPDATE,
      Ext_JTAG_TDI       => Ext_JTAG_TDI,
      Ext_JTAG_TDO       => Ext_JTAG_TDO
    );

  ext_trig_in      <= Trig_In_0 & Trig_In_1 & Trig_In_2 & Trig_In_3;
  ext_trig_ack_out <= Trig_Ack_Out_0 & Trig_Ack_Out_1 & Trig_Ack_Out_2 & Trig_Ack_Out_3;

  Trig_Ack_In_0 <= ext_trig_ack_in(0);
  Trig_Ack_In_1 <= ext_trig_ack_in(1);
  Trig_Ack_In_2 <= ext_trig_ack_in(2);
  Trig_Ack_In_3 <= ext_trig_ack_in(3);

  Trig_Out_0    <= ext_trig_out(0);
  Trig_Out_1    <= ext_trig_out(1);
  Trig_Out_2    <= ext_trig_out(2);
  Trig_Out_3    <= ext_trig_out(3);

  -- Bus Master port
  Use_Bus_MASTER : if (C_DBG_MEM_ACCESS = 1) generate
    type LMB_vec_type is array (natural range <>) of std_logic_vector(0 to C_DATA_SIZE - 1);

    signal lmb_data_addr       : std_logic_vector(0 to C_DATA_SIZE - 1);
    signal lmb_data_read       : std_logic_vector(0 to C_DATA_SIZE - 1);
    signal lmb_data_write      : std_logic_vector(0 to C_DATA_SIZE - 1);
    signal lmb_addr_strobe     : std_logic;
    signal lmb_read_strobe     : std_logic;
    signal lmb_write_strobe    : std_logic;
    signal lmb_ready           : std_logic;
    signal lmb_wait            : std_logic;
    signal lmb_ue              : std_logic;
    signal lmb_byte_enable     : std_logic_vector(0 to C_DATA_SIZE / 8 - 1);

    signal lmb_addr_strobe_vec : std_logic_vector(0 to 31);

    signal lmb_data_read_vec   : LMB_vec_type(0 to 31);
    signal lmb_ready_vec       : std_logic_vector(0 to 31);
    signal lmb_wait_vec        : std_logic_vector(0 to 31);
    signal lmb_ue_vec          : std_logic_vector(0 to 31);

    signal lmb_data_read_vec_q : LMB_vec_type(0 to C_EN_WIDTH - 1);
    signal lmb_ready_vec_q     : std_logic_vector(0 to C_EN_WIDTH - 1);
    signal lmb_wait_vec_q      : std_logic_vector(0 to C_EN_WIDTH - 1);
    signal lmb_ue_vec_q        : std_logic_vector(0 to C_EN_WIDTH - 1);
  begin

    bus_master_I : bus_master
    generic map  (
      C_M_AXI_DATA_WIDTH      => C_M_AXI_DATA_WIDTH,
      C_M_AXI_THREAD_ID_WIDTH => C_M_AXI_THREAD_ID_WIDTH,
      C_M_AXI_ADDR_WIDTH      => C_M_AXI_ADDR_WIDTH,
      C_DATA_SIZE             => C_DATA_SIZE,
      C_HAS_FIFO_PORTS        => true,
      C_HAS_DIRECT_PORT       => C_TRACE_AXI_MASTER
    )
    port map (
      Rd_Start          => master_rd_start,
      Rd_Addr           => master_rd_addr,
      Rd_Len            => master_rd_len,
      Rd_Size           => master_rd_size,
      Rd_Exclusive      => master_rd_excl,
      Rd_Idle           => master_rd_idle,
      Rd_Response       => master_rd_resp,
      Wr_Start          => master_wr_start,
      Wr_Addr           => master_wr_addr,
      Wr_Len            => master_wr_len,
      Wr_Size           => master_wr_size,
      Wr_Exclusive      => master_wr_excl,
      Wr_Idle           => master_wr_idle,
      Wr_Response       => master_wr_resp,
      Data_Rd           => master_data_rd,
      Data_Out          => master_data_out,
      Data_Exists       => master_data_exists,
      Data_Wr           => master_data_wr,
      Data_In           => master_data_in,
      Data_Empty        => master_data_empty,

      Direct_Wr_Addr    => master_dwr_addr,
      Direct_Wr_Len     => master_dwr_len,
      Direct_Wr_Data    => master_dwr_data,
      Direct_Wr_Start   => master_dwr_start,
      Direct_Wr_Next    => master_dwr_next,
      Direct_Wr_Done    => master_dwr_done,
      Direct_Wr_Resp    => master_dwr_resp,

      LMB_Data_Addr     => lmb_data_addr,
      LMB_Data_Read     => lmb_data_read,
      LMB_Data_Write    => lmb_data_write,
      LMB_Addr_Strobe   => lmb_addr_strobe,
      LMB_Read_Strobe   => lmb_read_strobe,
      LMB_Write_Strobe  => lmb_write_strobe,
      LMB_Ready         => lmb_ready,
      LMB_Wait          => lmb_wait,
      LMB_UE            => lmb_ue,
      LMB_Byte_Enable   => lmb_byte_enable,

      M_AXI_ACLK        => M_AXI_ACLK,
      M_AXI_ARESETn     => M_AXI_ARESETn,
      M_AXI_AWID        => M_AXI_AWID,
      M_AXI_AWADDR      => M_AXI_AWADDR,
      M_AXI_AWLEN       => M_AXI_AWLEN,
      M_AXI_AWSIZE      => M_AXI_AWSIZE,
      M_AXI_AWBURST     => M_AXI_AWBURST,
      M_AXI_AWLOCK      => M_AXI_AWLOCK,
      M_AXI_AWCACHE     => M_AXI_AWCACHE,
      M_AXI_AWPROT      => M_AXI_AWPROT,
      M_AXI_AWQOS       => M_AXI_AWQOS,
      M_AXI_AWVALID     => M_AXI_AWVALID,
      M_AXI_AWREADY     => M_AXI_AWREADY,
      M_AXI_WLAST       => M_AXI_WLAST,
      M_AXI_WDATA       => M_AXI_WDATA,
      M_AXI_WSTRB       => M_AXI_WSTRB,
      M_AXI_WVALID      => M_AXI_WVALID,
      M_AXI_WREADY      => M_AXI_WREADY,
      M_AXI_BRESP       => M_AXI_BRESP,
      M_AXI_BID         => M_AXI_BID,
      M_AXI_BVALID      => M_AXI_BVALID,
      M_AXI_BREADY      => M_AXI_BREADY,
      M_AXI_ARADDR      => M_AXI_ARADDR,
      M_AXI_ARID        => M_AXI_ARID,
      M_AXI_ARLEN       => M_AXI_ARLEN,
      M_AXI_ARSIZE      => M_AXI_ARSIZE,
      M_AXI_ARBURST     => M_AXI_ARBURST,
      M_AXI_ARLOCK      => M_AXI_ARLOCK,
      M_AXI_ARCACHE     => M_AXI_ARCACHE,
      M_AXI_ARPROT      => M_AXI_ARPROT,
      M_AXI_ARQOS       => M_AXI_ARQOS,
      M_AXI_ARVALID     => M_AXI_ARVALID,
      M_AXI_ARREADY     => M_AXI_ARREADY,
      M_AXI_RLAST       => M_AXI_RLAST,
      M_AXI_RID         => M_AXI_RID,
      M_AXI_RDATA       => M_AXI_RDATA,
      M_AXI_RRESP       => M_AXI_RRESP,
      M_AXI_RVALID      => M_AXI_RVALID,
      M_AXI_RREADY      => M_AXI_RREADY
    );

    Generate_LMB_Outputs : process (mb_debug_enabled, lmb_addr_strobe)
    begin  -- process Generate_LMB_Outputs
      lmb_addr_strobe_vec <= (others => '0');
      for I in 0 to C_EN_WIDTH - 1 loop
        lmb_addr_strobe_vec(I) <= lmb_addr_strobe and mb_debug_enabled(I);
      end loop;
    end process Generate_LMB_Outputs;

    LMB_Addr_Strobe_0  <= lmb_addr_strobe_vec(0);
    LMB_Addr_Strobe_1  <= lmb_addr_strobe_vec(1);
    LMB_Addr_Strobe_2  <= lmb_addr_strobe_vec(2);
    LMB_Addr_Strobe_3  <= lmb_addr_strobe_vec(3);
    LMB_Addr_Strobe_4  <= lmb_addr_strobe_vec(4);
    LMB_Addr_Strobe_5  <= lmb_addr_strobe_vec(5);
    LMB_Addr_Strobe_6  <= lmb_addr_strobe_vec(6);
    LMB_Addr_Strobe_7  <= lmb_addr_strobe_vec(7);
    LMB_Addr_Strobe_8  <= lmb_addr_strobe_vec(8);
    LMB_Addr_Strobe_9  <= lmb_addr_strobe_vec(9);
    LMB_Addr_Strobe_10 <= lmb_addr_strobe_vec(10);
    LMB_Addr_Strobe_11 <= lmb_addr_strobe_vec(11);
    LMB_Addr_Strobe_12 <= lmb_addr_strobe_vec(12);
    LMB_Addr_Strobe_13 <= lmb_addr_strobe_vec(13);
    LMB_Addr_Strobe_14 <= lmb_addr_strobe_vec(14);
    LMB_Addr_Strobe_15 <= lmb_addr_strobe_vec(15);
    LMB_Addr_Strobe_16 <= lmb_addr_strobe_vec(16);
    LMB_Addr_Strobe_17 <= lmb_addr_strobe_vec(17);
    LMB_Addr_Strobe_18 <= lmb_addr_strobe_vec(18);
    LMB_Addr_Strobe_19 <= lmb_addr_strobe_vec(19);
    LMB_Addr_Strobe_20 <= lmb_addr_strobe_vec(20);
    LMB_Addr_Strobe_21 <= lmb_addr_strobe_vec(21);
    LMB_Addr_Strobe_22 <= lmb_addr_strobe_vec(22);
    LMB_Addr_Strobe_23 <= lmb_addr_strobe_vec(23);
    LMB_Addr_Strobe_24 <= lmb_addr_strobe_vec(24);
    LMB_Addr_Strobe_25 <= lmb_addr_strobe_vec(25);
    LMB_Addr_Strobe_26 <= lmb_addr_strobe_vec(26);
    LMB_Addr_Strobe_27 <= lmb_addr_strobe_vec(27);
    LMB_Addr_Strobe_28 <= lmb_addr_strobe_vec(28);
    LMB_Addr_Strobe_29 <= lmb_addr_strobe_vec(29);
    LMB_Addr_Strobe_30 <= lmb_addr_strobe_vec(30);
    LMB_Addr_Strobe_31 <= lmb_addr_strobe_vec(31);

    LMB_Data_Addr_0  <= lmb_data_addr;
    LMB_Data_Addr_1  <= lmb_data_addr;
    LMB_Data_Addr_2  <= lmb_data_addr;
    LMB_Data_Addr_3  <= lmb_data_addr;
    LMB_Data_Addr_4  <= lmb_data_addr;
    LMB_Data_Addr_5  <= lmb_data_addr;
    LMB_Data_Addr_6  <= lmb_data_addr;
    LMB_Data_Addr_7  <= lmb_data_addr;
    LMB_Data_Addr_8  <= lmb_data_addr;
    LMB_Data_Addr_9  <= lmb_data_addr;
    LMB_Data_Addr_10 <= lmb_data_addr;
    LMB_Data_Addr_11 <= lmb_data_addr;
    LMB_Data_Addr_12 <= lmb_data_addr;
    LMB_Data_Addr_13 <= lmb_data_addr;
    LMB_Data_Addr_14 <= lmb_data_addr;
    LMB_Data_Addr_15 <= lmb_data_addr;
    LMB_Data_Addr_16 <= lmb_data_addr;
    LMB_Data_Addr_17 <= lmb_data_addr;
    LMB_Data_Addr_18 <= lmb_data_addr;
    LMB_Data_Addr_19 <= lmb_data_addr;
    LMB_Data_Addr_20 <= lmb_data_addr;
    LMB_Data_Addr_21 <= lmb_data_addr;
    LMB_Data_Addr_22 <= lmb_data_addr;
    LMB_Data_Addr_23 <= lmb_data_addr;
    LMB_Data_Addr_24 <= lmb_data_addr;
    LMB_Data_Addr_25 <= lmb_data_addr;
    LMB_Data_Addr_26 <= lmb_data_addr;
    LMB_Data_Addr_27 <= lmb_data_addr;
    LMB_Data_Addr_28 <= lmb_data_addr;
    LMB_Data_Addr_29 <= lmb_data_addr;
    LMB_Data_Addr_30 <= lmb_data_addr;
    LMB_Data_Addr_31 <= lmb_data_addr;

    LMB_Data_write_0  <= lmb_data_write;
    LMB_Data_write_1  <= lmb_data_write;
    LMB_Data_write_2  <= lmb_data_write;
    LMB_Data_write_3  <= lmb_data_write;
    LMB_Data_write_4  <= lmb_data_write;
    LMB_Data_write_5  <= lmb_data_write;
    LMB_Data_write_6  <= lmb_data_write;
    LMB_Data_write_7  <= lmb_data_write;
    LMB_Data_write_8  <= lmb_data_write;
    LMB_Data_write_9  <= lmb_data_write;
    LMB_Data_write_10 <= lmb_data_write;
    LMB_Data_write_11 <= lmb_data_write;
    LMB_Data_write_12 <= lmb_data_write;
    LMB_Data_write_13 <= lmb_data_write;
    LMB_Data_write_14 <= lmb_data_write;
    LMB_Data_write_15 <= lmb_data_write;
    LMB_Data_write_16 <= lmb_data_write;
    LMB_Data_write_17 <= lmb_data_write;
    LMB_Data_write_18 <= lmb_data_write;
    LMB_Data_write_19 <= lmb_data_write;
    LMB_Data_write_20 <= lmb_data_write;
    LMB_Data_write_21 <= lmb_data_write;
    LMB_Data_write_22 <= lmb_data_write;
    LMB_Data_write_23 <= lmb_data_write;
    LMB_Data_write_24 <= lmb_data_write;
    LMB_Data_write_25 <= lmb_data_write;
    LMB_Data_write_26 <= lmb_data_write;
    LMB_Data_write_27 <= lmb_data_write;
    LMB_Data_write_28 <= lmb_data_write;
    LMB_Data_write_29 <= lmb_data_write;
    LMB_Data_write_30 <= lmb_data_write;
    LMB_Data_write_31 <= lmb_data_write;

    LMB_Read_strobe_0  <= lmb_read_strobe;
    LMB_Read_strobe_1  <= lmb_read_strobe;
    LMB_Read_strobe_2  <= lmb_read_strobe;
    LMB_Read_strobe_3  <= lmb_read_strobe;
    LMB_Read_strobe_4  <= lmb_read_strobe;
    LMB_Read_strobe_5  <= lmb_read_strobe;
    LMB_Read_strobe_6  <= lmb_read_strobe;
    LMB_Read_strobe_7  <= lmb_read_strobe;
    LMB_Read_strobe_8  <= lmb_read_strobe;
    LMB_Read_strobe_9  <= lmb_read_strobe;
    LMB_Read_strobe_10 <= lmb_read_strobe;
    LMB_Read_strobe_11 <= lmb_read_strobe;
    LMB_Read_strobe_12 <= lmb_read_strobe;
    LMB_Read_strobe_13 <= lmb_read_strobe;
    LMB_Read_strobe_14 <= lmb_read_strobe;
    LMB_Read_strobe_15 <= lmb_read_strobe;
    LMB_Read_strobe_16 <= lmb_read_strobe;
    LMB_Read_strobe_17 <= lmb_read_strobe;
    LMB_Read_strobe_18 <= lmb_read_strobe;
    LMB_Read_strobe_19 <= lmb_read_strobe;
    LMB_Read_strobe_20 <= lmb_read_strobe;
    LMB_Read_strobe_21 <= lmb_read_strobe;
    LMB_Read_strobe_22 <= lmb_read_strobe;
    LMB_Read_strobe_23 <= lmb_read_strobe;
    LMB_Read_strobe_24 <= lmb_read_strobe;
    LMB_Read_strobe_25 <= lmb_read_strobe;
    LMB_Read_strobe_26 <= lmb_read_strobe;
    LMB_Read_strobe_27 <= lmb_read_strobe;
    LMB_Read_strobe_28 <= lmb_read_strobe;
    LMB_Read_strobe_29 <= lmb_read_strobe;
    LMB_Read_strobe_30 <= lmb_read_strobe;
    LMB_Read_strobe_31 <= lmb_read_strobe;

    LMB_Write_strobe_0  <= lmb_write_strobe;
    LMB_Write_strobe_1  <= lmb_write_strobe;
    LMB_Write_strobe_2  <= lmb_write_strobe;
    LMB_Write_strobe_3  <= lmb_write_strobe;
    LMB_Write_strobe_4  <= lmb_write_strobe;
    LMB_Write_strobe_5  <= lmb_write_strobe;
    LMB_Write_strobe_6  <= lmb_write_strobe;
    LMB_Write_strobe_7  <= lmb_write_strobe;
    LMB_Write_strobe_8  <= lmb_write_strobe;
    LMB_Write_strobe_9  <= lmb_write_strobe;
    LMB_Write_strobe_10 <= lmb_write_strobe;
    LMB_Write_strobe_11 <= lmb_write_strobe;
    LMB_Write_strobe_12 <= lmb_write_strobe;
    LMB_Write_strobe_13 <= lmb_write_strobe;
    LMB_Write_strobe_14 <= lmb_write_strobe;
    LMB_Write_strobe_15 <= lmb_write_strobe;
    LMB_Write_strobe_16 <= lmb_write_strobe;
    LMB_Write_strobe_17 <= lmb_write_strobe;
    LMB_Write_strobe_18 <= lmb_write_strobe;
    LMB_Write_strobe_19 <= lmb_write_strobe;
    LMB_Write_strobe_20 <= lmb_write_strobe;
    LMB_Write_strobe_21 <= lmb_write_strobe;
    LMB_Write_strobe_22 <= lmb_write_strobe;
    LMB_Write_strobe_23 <= lmb_write_strobe;
    LMB_Write_strobe_24 <= lmb_write_strobe;
    LMB_Write_strobe_25 <= lmb_write_strobe;
    LMB_Write_strobe_26 <= lmb_write_strobe;
    LMB_Write_strobe_27 <= lmb_write_strobe;
    LMB_Write_strobe_28 <= lmb_write_strobe;
    LMB_Write_strobe_29 <= lmb_write_strobe;
    LMB_Write_strobe_30 <= lmb_write_strobe;
    LMB_Write_strobe_31 <= lmb_write_strobe;

    LMB_Byte_enable_0  <= lmb_byte_enable;
    LMB_Byte_enable_1  <= lmb_byte_enable;
    LMB_Byte_enable_2  <= lmb_byte_enable;
    LMB_Byte_enable_3  <= lmb_byte_enable;
    LMB_Byte_enable_4  <= lmb_byte_enable;
    LMB_Byte_enable_5  <= lmb_byte_enable;
    LMB_Byte_enable_6  <= lmb_byte_enable;
    LMB_Byte_enable_7  <= lmb_byte_enable;
    LMB_Byte_enable_8  <= lmb_byte_enable;
    LMB_Byte_enable_9  <= lmb_byte_enable;
    LMB_Byte_enable_10 <= lmb_byte_enable;
    LMB_Byte_enable_11 <= lmb_byte_enable;
    LMB_Byte_enable_12 <= lmb_byte_enable;
    LMB_Byte_enable_13 <= lmb_byte_enable;
    LMB_Byte_enable_14 <= lmb_byte_enable;
    LMB_Byte_enable_15 <= lmb_byte_enable;
    LMB_Byte_enable_16 <= lmb_byte_enable;
    LMB_Byte_enable_17 <= lmb_byte_enable;
    LMB_Byte_enable_18 <= lmb_byte_enable;
    LMB_Byte_enable_19 <= lmb_byte_enable;
    LMB_Byte_enable_20 <= lmb_byte_enable;
    LMB_Byte_enable_21 <= lmb_byte_enable;
    LMB_Byte_enable_22 <= lmb_byte_enable;
    LMB_Byte_enable_23 <= lmb_byte_enable;
    LMB_Byte_enable_24 <= lmb_byte_enable;
    LMB_Byte_enable_25 <= lmb_byte_enable;
    LMB_Byte_enable_26 <= lmb_byte_enable;
    LMB_Byte_enable_27 <= lmb_byte_enable;
    LMB_Byte_enable_28 <= lmb_byte_enable;
    LMB_Byte_enable_29 <= lmb_byte_enable;
    LMB_Byte_enable_30 <= lmb_byte_enable;
    LMB_Byte_enable_31 <= lmb_byte_enable;

    Generate_LMB_Inputs : process (mb_debug_enabled, lmb_data_read_vec_q, lmb_ready_vec_q, lmb_wait_vec_q, lmb_ue_vec_q)
      variable data_mask : std_logic_vector(0 to C_DATA_SIZE - 1);
      variable data_read : std_logic_vector(0 to C_DATA_SIZE - 1);
      variable ready     : std_logic;
      variable wait_i    : std_logic;
      variable ue        : std_logic;
    begin  -- process Generate_LMB_Inputs
      data_read := (others => '0');
      ready     := '0';
      wait_i    := '0';
      ue        := '0';
      for I in 0 to C_EN_WIDTH - 1 loop
        data_mask := (0 to C_DATA_SIZE - 1 => mb_debug_enabled(I));
        data_read := data_read or (lmb_data_read_vec_q(I) and data_mask);
        ready     := ready     or (lmb_ready_vec_q(I)     and mb_debug_enabled(I));
        wait_i    := wait_i    or (lmb_wait_vec_q(I)      and mb_debug_enabled(I));
        ue        := ue        or (lmb_ue_vec_q(I)        and mb_debug_enabled(I));
      end loop;
      lmb_data_read <= data_read;
      lmb_ready     <= ready;
      lmb_wait      <= wait_i;
      lmb_ue        <= ue;
    end process Generate_LMB_Inputs;

    Clock_LMB_Inputs : process (M_AXI_ACLK)
    begin
      if M_AXI_ACLK'event and M_AXI_ACLK = '1' then -- rising clock edge
        for I in 0 to C_EN_WIDTH - 1 loop
          lmb_data_read_vec_q(I) <= lmb_data_read_vec(I);
          lmb_ready_vec_q(I)     <= lmb_ready_vec(I);
          lmb_wait_vec_q(I)      <= lmb_wait_vec(I);
          lmb_ue_vec_q(I)        <= lmb_ue_vec(I);
        end loop;
      end if;
    end process Clock_LMB_Inputs;

    lmb_data_read_vec(0)  <= LMB_Data_Read_0;
    lmb_data_read_vec(1)  <= LMB_Data_Read_1;
    lmb_data_read_vec(2)  <= LMB_Data_Read_2;
    lmb_data_read_vec(3)  <= LMB_Data_Read_3;
    lmb_data_read_vec(4)  <= LMB_Data_Read_4;
    lmb_data_read_vec(5)  <= LMB_Data_Read_5;
    lmb_data_read_vec(6)  <= LMB_Data_Read_6;
    lmb_data_read_vec(7)  <= LMB_Data_Read_7;
    lmb_data_read_vec(8)  <= LMB_Data_Read_8;
    lmb_data_read_vec(9)  <= LMB_Data_Read_9;
    lmb_data_read_vec(10) <= LMB_Data_Read_10;
    lmb_data_read_vec(11) <= LMB_Data_Read_11;
    lmb_data_read_vec(12) <= LMB_Data_Read_12;
    lmb_data_read_vec(13) <= LMB_Data_Read_13;
    lmb_data_read_vec(14) <= LMB_Data_Read_14;
    lmb_data_read_vec(15) <= LMB_Data_Read_15;
    lmb_data_read_vec(16) <= LMB_Data_Read_16;
    lmb_data_read_vec(17) <= LMB_Data_Read_17;
    lmb_data_read_vec(18) <= LMB_Data_Read_18;
    lmb_data_read_vec(19) <= LMB_Data_Read_19;
    lmb_data_read_vec(20) <= LMB_Data_Read_20;
    lmb_data_read_vec(21) <= LMB_Data_Read_21;
    lmb_data_read_vec(22) <= LMB_Data_Read_22;
    lmb_data_read_vec(23) <= LMB_Data_Read_23;
    lmb_data_read_vec(24) <= LMB_Data_Read_24;
    lmb_data_read_vec(25) <= LMB_Data_Read_25;
    lmb_data_read_vec(26) <= LMB_Data_Read_26;
    lmb_data_read_vec(27) <= LMB_Data_Read_27;
    lmb_data_read_vec(28) <= LMB_Data_Read_28;
    lmb_data_read_vec(29) <= LMB_Data_Read_29;
    lmb_data_read_vec(30) <= LMB_Data_Read_30;
    lmb_data_read_vec(31) <= LMB_Data_Read_31;

    lmb_ready_vec(0)      <= LMB_Ready_0;
    lmb_ready_vec(1)      <= LMB_Ready_1;
    lmb_ready_vec(2)      <= LMB_Ready_2;
    lmb_ready_vec(3)      <= LMB_Ready_3;
    lmb_ready_vec(4)      <= LMB_Ready_4;
    lmb_ready_vec(5)      <= LMB_Ready_5;
    lmb_ready_vec(6)      <= LMB_Ready_6;
    lmb_ready_vec(7)      <= LMB_Ready_7;
    lmb_ready_vec(8)      <= LMB_Ready_8;
    lmb_ready_vec(9)      <= LMB_Ready_9;
    lmb_ready_vec(10)     <= LMB_Ready_10;
    lmb_ready_vec(11)     <= LMB_Ready_11;
    lmb_ready_vec(12)     <= LMB_Ready_12;
    lmb_ready_vec(13)     <= LMB_Ready_13;
    lmb_ready_vec(14)     <= LMB_Ready_14;
    lmb_ready_vec(15)     <= LMB_Ready_15;
    lmb_ready_vec(16)     <= LMB_Ready_16;
    lmb_ready_vec(17)     <= LMB_Ready_17;
    lmb_ready_vec(18)     <= LMB_Ready_18;
    lmb_ready_vec(19)     <= LMB_Ready_19;
    lmb_ready_vec(20)     <= LMB_Ready_20;
    lmb_ready_vec(21)     <= LMB_Ready_21;
    lmb_ready_vec(22)     <= LMB_Ready_22;
    lmb_ready_vec(23)     <= LMB_Ready_23;
    lmb_ready_vec(24)     <= LMB_Ready_24;
    lmb_ready_vec(25)     <= LMB_Ready_25;
    lmb_ready_vec(26)     <= LMB_Ready_26;
    lmb_ready_vec(27)     <= LMB_Ready_27;
    lmb_ready_vec(28)     <= LMB_Ready_28;
    lmb_ready_vec(29)     <= LMB_Ready_29;
    lmb_ready_vec(30)     <= LMB_Ready_30;
    lmb_ready_vec(31)     <= LMB_Ready_31;

    lmb_wait_vec(0)       <= LMB_Wait_0;
    lmb_wait_vec(1)       <= LMB_Wait_1;
    lmb_wait_vec(2)       <= LMB_Wait_2;
    lmb_wait_vec(3)       <= LMB_Wait_3;
    lmb_wait_vec(4)       <= LMB_Wait_4;
    lmb_wait_vec(5)       <= LMB_Wait_5;
    lmb_wait_vec(6)       <= LMB_Wait_6;
    lmb_wait_vec(7)       <= LMB_Wait_7;
    lmb_wait_vec(8)       <= LMB_Wait_8;
    lmb_wait_vec(9)       <= LMB_Wait_9;
    lmb_wait_vec(10)      <= LMB_Wait_10;
    lmb_wait_vec(11)      <= LMB_Wait_11;
    lmb_wait_vec(12)      <= LMB_Wait_12;
    lmb_wait_vec(13)      <= LMB_Wait_13;
    lmb_wait_vec(14)      <= LMB_Wait_14;
    lmb_wait_vec(15)      <= LMB_Wait_15;
    lmb_wait_vec(16)      <= LMB_Wait_16;
    lmb_wait_vec(17)      <= LMB_Wait_17;
    lmb_wait_vec(18)      <= LMB_Wait_18;
    lmb_wait_vec(19)      <= LMB_Wait_19;
    lmb_wait_vec(20)      <= LMB_Wait_20;
    lmb_wait_vec(21)      <= LMB_Wait_21;
    lmb_wait_vec(22)      <= LMB_Wait_22;
    lmb_wait_vec(23)      <= LMB_Wait_23;
    lmb_wait_vec(24)      <= LMB_Wait_24;
    lmb_wait_vec(25)      <= LMB_Wait_25;
    lmb_wait_vec(26)      <= LMB_Wait_26;
    lmb_wait_vec(27)      <= LMB_Wait_27;
    lmb_wait_vec(28)      <= LMB_Wait_28;
    lmb_wait_vec(29)      <= LMB_Wait_29;
    lmb_wait_vec(30)      <= LMB_Wait_30;
    lmb_wait_vec(31)      <= LMB_Wait_31;

    lmb_ue_vec(0)         <= LMB_UE_0;
    lmb_ue_vec(1)         <= LMB_UE_1;
    lmb_ue_vec(2)         <= LMB_UE_2;
    lmb_ue_vec(3)         <= LMB_UE_3;
    lmb_ue_vec(4)         <= LMB_UE_4;
    lmb_ue_vec(5)         <= LMB_UE_5;
    lmb_ue_vec(6)         <= LMB_UE_6;
    lmb_ue_vec(7)         <= LMB_UE_7;
    lmb_ue_vec(8)         <= LMB_UE_8;
    lmb_ue_vec(9)         <= LMB_UE_9;
    lmb_ue_vec(10)        <= LMB_UE_10;
    lmb_ue_vec(11)        <= LMB_UE_11;
    lmb_ue_vec(12)        <= LMB_UE_12;
    lmb_ue_vec(13)        <= LMB_UE_13;
    lmb_ue_vec(14)        <= LMB_UE_14;
    lmb_ue_vec(15)        <= LMB_UE_15;
    lmb_ue_vec(16)        <= LMB_UE_16;
    lmb_ue_vec(17)        <= LMB_UE_17;
    lmb_ue_vec(18)        <= LMB_UE_18;
    lmb_ue_vec(19)        <= LMB_UE_19;
    lmb_ue_vec(20)        <= LMB_UE_20;
    lmb_ue_vec(21)        <= LMB_UE_21;
    lmb_ue_vec(22)        <= LMB_UE_22;
    lmb_ue_vec(23)        <= LMB_UE_23;
    lmb_ue_vec(24)        <= LMB_UE_24;
    lmb_ue_vec(25)        <= LMB_UE_25;
    lmb_ue_vec(26)        <= LMB_UE_26;
    lmb_ue_vec(27)        <= LMB_UE_27;
    lmb_ue_vec(28)        <= LMB_UE_28;
    lmb_ue_vec(29)        <= LMB_UE_29;
    lmb_ue_vec(30)        <= LMB_UE_30;
    lmb_ue_vec(31)        <= LMB_UE_31;
  end generate Use_Bus_MASTER;

  Use_Bus_MASTER_AXI : if (C_DBG_MEM_ACCESS = 0 and C_TRACE_AXI_MASTER) generate
  begin

    bus_master_I : bus_master
    generic map  (
      C_M_AXI_DATA_WIDTH      => C_M_AXI_DATA_WIDTH,
      C_M_AXI_THREAD_ID_WIDTH => C_M_AXI_THREAD_ID_WIDTH,
      C_M_AXI_ADDR_WIDTH      => C_M_AXI_ADDR_WIDTH,
      C_DATA_SIZE             => C_DATA_SIZE,
      C_HAS_FIFO_PORTS        => false,
      C_HAS_DIRECT_PORT       => true
    )
    port map (
      Rd_Start          => master_rd_start,
      Rd_Addr           => master_rd_addr,
      Rd_Len            => master_rd_len,
      Rd_Size           => master_rd_size,
      Rd_Exclusive      => master_rd_excl,
      Rd_Idle           => master_rd_idle,
      Rd_Response       => master_rd_resp,
      Wr_Start          => master_wr_start,
      Wr_Addr           => master_wr_addr,
      Wr_Len            => master_wr_len,
      Wr_Size           => master_wr_size,
      Wr_Exclusive      => master_wr_excl,
      Wr_Idle           => master_wr_idle,
      Wr_Response       => master_wr_resp,
      Data_Rd           => master_data_rd,
      Data_Out          => master_data_out,
      Data_Exists       => master_data_exists,
      Data_Wr           => master_data_wr,
      Data_In           => master_data_in,
      Data_Empty        => master_data_empty,

      Direct_Wr_Addr    => master_dwr_addr,
      Direct_Wr_Len     => master_dwr_len,
      Direct_Wr_Data    => master_dwr_data,
      Direct_Wr_Start   => master_dwr_start,
      Direct_Wr_Next    => master_dwr_next,
      Direct_Wr_Done    => master_dwr_done,
      Direct_Wr_Resp    => master_dwr_resp,

      LMB_Data_Addr     => open,
      LMB_Data_Read     => (others => '0'),
      LMB_Data_Write    => open,
      LMB_Addr_Strobe   => open,
      LMB_Read_Strobe   => open,
      LMB_Write_Strobe  => open,
      LMB_Ready         => '0',
      LMB_Wait          => '0',
      LMB_UE            => '0',
      LMB_Byte_Enable   => open,

      M_AXI_ACLK        => M_AXI_ACLK,
      M_AXI_ARESETn     => M_AXI_ARESETn,
      M_AXI_AWID        => M_AXI_AWID,
      M_AXI_AWADDR      => M_AXI_AWADDR,
      M_AXI_AWLEN       => M_AXI_AWLEN,
      M_AXI_AWSIZE      => M_AXI_AWSIZE,
      M_AXI_AWBURST     => M_AXI_AWBURST,
      M_AXI_AWLOCK      => M_AXI_AWLOCK,
      M_AXI_AWCACHE     => M_AXI_AWCACHE,
      M_AXI_AWPROT      => M_AXI_AWPROT,
      M_AXI_AWQOS       => M_AXI_AWQOS,
      M_AXI_AWVALID     => M_AXI_AWVALID,
      M_AXI_AWREADY     => M_AXI_AWREADY,
      M_AXI_WLAST       => M_AXI_WLAST,
      M_AXI_WDATA       => M_AXI_WDATA,
      M_AXI_WSTRB       => M_AXI_WSTRB,
      M_AXI_WVALID      => M_AXI_WVALID,
      M_AXI_WREADY      => M_AXI_WREADY,
      M_AXI_BRESP       => M_AXI_BRESP,
      M_AXI_BID         => M_AXI_BID,
      M_AXI_BVALID      => M_AXI_BVALID,
      M_AXI_BREADY      => M_AXI_BREADY,
      M_AXI_ARADDR      => M_AXI_ARADDR,
      M_AXI_ARID        => M_AXI_ARID,
      M_AXI_ARLEN       => M_AXI_ARLEN,
      M_AXI_ARSIZE      => M_AXI_ARSIZE,
      M_AXI_ARBURST     => M_AXI_ARBURST,
      M_AXI_ARLOCK      => M_AXI_ARLOCK,
      M_AXI_ARCACHE     => M_AXI_ARCACHE,
      M_AXI_ARPROT      => M_AXI_ARPROT,
      M_AXI_ARQOS       => M_AXI_ARQOS,
      M_AXI_ARVALID     => M_AXI_ARVALID,
      M_AXI_ARREADY     => M_AXI_ARREADY,
      M_AXI_RLAST       => M_AXI_RLAST,
      M_AXI_RID         => M_AXI_RID,
      M_AXI_RDATA       => M_AXI_RDATA,
      M_AXI_RRESP       => M_AXI_RRESP,
      M_AXI_RVALID      => M_AXI_RVALID,
      M_AXI_RREADY      => M_AXI_RREADY
    );

  end generate Use_Bus_MASTER_AXI;

  No_Bus_MASTER_AXI : if (C_DBG_MEM_ACCESS = 0 and not C_TRACE_AXI_MASTER) generate
  begin
    master_rd_idle      <= '1';
    master_rd_resp      <= "00";
    master_wr_idle      <= '1';
    master_wr_resp      <= "00";
    master_data_out     <= (others => '0');
    master_data_exists  <= '0';
    master_data_empty   <= '1';
    master_dwr_next     <= '0';
    master_dwr_done     <= '0';
    master_dwr_resp     <= (others => '0');

    M_AXI_AWID          <= (others => '0');
    M_AXI_AWADDR        <= (others => '0');
    M_AXI_AWLEN         <= (others => '0');
    M_AXI_AWSIZE        <= (others => '0');
    M_AXI_AWBURST       <= (others => '0');
    M_AXI_AWLOCK        <= '0';
    M_AXI_AWCACHE       <= (others => '0');
    M_AXI_AWPROT        <= (others => '0');
    M_AXI_AWQOS         <= (others => '0');
    M_AXI_AWVALID       <= '0';
    M_AXI_WDATA         <= (others => '0');
    M_AXI_WSTRB         <= (others => '0');
    M_AXI_WLAST         <= '0';
    M_AXI_WVALID        <= '0';
    M_AXI_BREADY        <= '0';
    M_AXI_ARID          <= (others => '0');
    M_AXI_ARADDR        <= (others => '0');
    M_AXI_ARLEN         <= (others => '0');
    M_AXI_ARSIZE        <= (others => '0');
    M_AXI_ARBURST       <= (others => '0');
    M_AXI_ARLOCK        <= '0';
    M_AXI_ARCACHE       <= (others => '0');
    M_AXI_ARPROT        <= (others => '0');
    M_AXI_ARQOS         <= (others => '0');
    M_AXI_ARVALID       <= '0';
    M_AXI_RREADY        <= '0';
  end generate No_Bus_MASTER_AXI;

  No_Bus_MASTER_LMB : if (C_DBG_MEM_ACCESS = 0) generate
  begin
    LMB_Data_Addr_0     <= (others => '0');
    LMB_Data_Write_0    <= (others => '0');
    LMB_Addr_Strobe_0   <= '0';
    LMB_Read_Strobe_0   <= '0';
    LMB_Write_Strobe_0  <= '0';
    LMB_Byte_Enable_0   <= (others => '0');

    LMB_Data_Addr_1     <= (others => '0');
    LMB_Data_Write_1    <= (others => '0');
    LMB_Addr_Strobe_1   <= '0';
    LMB_Read_Strobe_1   <= '0';
    LMB_Write_Strobe_1  <= '0';
    LMB_Byte_Enable_1   <= (others => '0');

    LMB_Data_Addr_2     <= (others => '0');
    LMB_Data_Write_2    <= (others => '0');
    LMB_Addr_Strobe_2   <= '0';
    LMB_Read_Strobe_2   <= '0';
    LMB_Write_Strobe_2  <= '0';
    LMB_Byte_Enable_2   <= (others => '0');

    LMB_Data_Addr_3     <= (others => '0');
    LMB_Data_Write_3    <= (others => '0');
    LMB_Addr_Strobe_3   <= '0';
    LMB_Read_Strobe_3   <= '0';
    LMB_Write_Strobe_3  <= '0';
    LMB_Byte_Enable_3   <= (others => '0');

    LMB_Data_Addr_4     <= (others => '0');
    LMB_Data_Write_4    <= (others => '0');
    LMB_Addr_Strobe_4   <= '0';
    LMB_Read_Strobe_4   <= '0';
    LMB_Write_Strobe_4  <= '0';
    LMB_Byte_Enable_4   <= (others => '0');

    LMB_Data_Addr_5     <= (others => '0');
    LMB_Data_Write_5    <= (others => '0');
    LMB_Addr_Strobe_5   <= '0';
    LMB_Read_Strobe_5   <= '0';
    LMB_Write_Strobe_5  <= '0';
    LMB_Byte_Enable_5   <= (others => '0');

    LMB_Data_Addr_6     <= (others => '0');
    LMB_Data_Write_6    <= (others => '0');
    LMB_Addr_Strobe_6   <= '0';
    LMB_Read_Strobe_6   <= '0';
    LMB_Write_Strobe_6  <= '0';
    LMB_Byte_Enable_6   <= (others => '0');

    LMB_Data_Addr_7     <= (others => '0');
    LMB_Data_Write_7    <= (others => '0');
    LMB_Addr_Strobe_7   <= '0';
    LMB_Read_Strobe_7   <= '0';
    LMB_Write_Strobe_7  <= '0';
    LMB_Byte_Enable_7   <= (others => '0');

    LMB_Data_Addr_8     <= (others => '0');
    LMB_Data_Write_8    <= (others => '0');
    LMB_Addr_Strobe_8   <= '0';
    LMB_Read_Strobe_8   <= '0';
    LMB_Write_Strobe_8  <= '0';
    LMB_Byte_Enable_8   <= (others => '0');

    LMB_Data_Addr_9     <= (others => '0');
    LMB_Data_Write_9    <= (others => '0');
    LMB_Addr_Strobe_9   <= '0';
    LMB_Read_Strobe_9   <= '0';
    LMB_Write_Strobe_9  <= '0';
    LMB_Byte_Enable_9   <= (others => '0');

    LMB_Data_Addr_10    <= (others => '0');
    LMB_Data_Write_10   <= (others => '0');
    LMB_Addr_Strobe_10  <= '0';
    LMB_Read_Strobe_10  <= '0';
    LMB_Write_Strobe_10 <= '0';
    LMB_Byte_Enable_10  <= (others => '0');

    LMB_Data_Addr_11    <= (others => '0');
    LMB_Data_Write_11   <= (others => '0');
    LMB_Addr_Strobe_11  <= '0';
    LMB_Read_Strobe_11  <= '0';
    LMB_Write_Strobe_11 <= '0';
    LMB_Byte_Enable_11  <= (others => '0');

    LMB_Data_Addr_12    <= (others => '0');
    LMB_Data_Write_12   <= (others => '0');
    LMB_Addr_Strobe_12  <= '0';
    LMB_Read_Strobe_12  <= '0';
    LMB_Write_Strobe_12 <= '0';
    LMB_Byte_Enable_12  <= (others => '0');

    LMB_Data_Addr_13    <= (others => '0');
    LMB_Data_Write_13   <= (others => '0');
    LMB_Addr_Strobe_13  <= '0';
    LMB_Read_Strobe_13  <= '0';
    LMB_Write_Strobe_13 <= '0';
    LMB_Byte_Enable_13  <= (others => '0');

    LMB_Data_Addr_14    <= (others => '0');
    LMB_Data_Write_14   <= (others => '0');
    LMB_Addr_Strobe_14  <= '0';
    LMB_Read_Strobe_14  <= '0';
    LMB_Write_Strobe_14 <= '0';
    LMB_Byte_Enable_14  <= (others => '0');

    LMB_Data_Addr_15    <= (others => '0');
    LMB_Data_Write_15   <= (others => '0');
    LMB_Addr_Strobe_15  <= '0';
    LMB_Read_Strobe_15  <= '0';
    LMB_Write_Strobe_15 <= '0';
    LMB_Byte_Enable_15  <= (others => '0');

    LMB_Data_Addr_16    <= (others => '0');
    LMB_Data_Write_16   <= (others => '0');
    LMB_Addr_Strobe_16  <= '0';
    LMB_Read_Strobe_16  <= '0';
    LMB_Write_Strobe_16 <= '0';
    LMB_Byte_Enable_16  <= (others => '0');

    LMB_Data_Addr_17    <= (others => '0');
    LMB_Data_Write_17   <= (others => '0');
    LMB_Addr_Strobe_17  <= '0';
    LMB_Read_Strobe_17  <= '0';
    LMB_Write_Strobe_17 <= '0';
    LMB_Byte_Enable_17  <= (others => '0');

    LMB_Data_Addr_18    <= (others => '0');
    LMB_Data_Write_18   <= (others => '0');
    LMB_Addr_Strobe_18  <= '0';
    LMB_Read_Strobe_18  <= '0';
    LMB_Write_Strobe_18 <= '0';
    LMB_Byte_Enable_18  <= (others => '0');

    LMB_Data_Addr_19    <= (others => '0');
    LMB_Data_Write_19   <= (others => '0');
    LMB_Addr_Strobe_19  <= '0';
    LMB_Read_Strobe_19  <= '0';
    LMB_Write_Strobe_19 <= '0';
    LMB_Byte_Enable_19  <= (others => '0');

    LMB_Data_Addr_20    <= (others => '0');
    LMB_Data_Write_20   <= (others => '0');
    LMB_Addr_Strobe_20  <= '0';
    LMB_Read_Strobe_20  <= '0';
    LMB_Write_Strobe_20 <= '0';
    LMB_Byte_Enable_20  <= (others => '0');

    LMB_Data_Addr_21    <= (others => '0');
    LMB_Data_Write_21   <= (others => '0');
    LMB_Addr_Strobe_21  <= '0';
    LMB_Read_Strobe_21  <= '0';
    LMB_Write_Strobe_21 <= '0';
    LMB_Byte_Enable_21  <= (others => '0');

    LMB_Data_Addr_22    <= (others => '0');
    LMB_Data_Write_22   <= (others => '0');
    LMB_Addr_Strobe_22  <= '0';
    LMB_Read_Strobe_22  <= '0';
    LMB_Write_Strobe_22 <= '0';
    LMB_Byte_Enable_22  <= (others => '0');

    LMB_Data_Addr_23    <= (others => '0');
    LMB_Data_Write_23   <= (others => '0');
    LMB_Addr_Strobe_23  <= '0';
    LMB_Read_Strobe_23  <= '0';
    LMB_Write_Strobe_23 <= '0';
    LMB_Byte_Enable_23  <= (others => '0');

    LMB_Data_Addr_24    <= (others => '0');
    LMB_Data_Write_24   <= (others => '0');
    LMB_Addr_Strobe_24  <= '0';
    LMB_Read_Strobe_24  <= '0';
    LMB_Write_Strobe_24 <= '0';
    LMB_Byte_Enable_24  <= (others => '0');

    LMB_Data_Addr_25    <= (others => '0');
    LMB_Data_Write_25   <= (others => '0');
    LMB_Addr_Strobe_25  <= '0';
    LMB_Read_Strobe_25  <= '0';
    LMB_Write_Strobe_25 <= '0';
    LMB_Byte_Enable_25  <= (others => '0');

    LMB_Data_Addr_26    <= (others => '0');
    LMB_Data_Write_26   <= (others => '0');
    LMB_Addr_Strobe_26  <= '0';
    LMB_Read_Strobe_26  <= '0';
    LMB_Write_Strobe_26 <= '0';
    LMB_Byte_Enable_26  <= (others => '0');

    LMB_Data_Addr_27    <= (others => '0');
    LMB_Data_Write_27   <= (others => '0');
    LMB_Addr_Strobe_27  <= '0';
    LMB_Read_Strobe_27  <= '0';
    LMB_Write_Strobe_27 <= '0';
    LMB_Byte_Enable_27  <= (others => '0');

    LMB_Data_Addr_28    <= (others => '0');
    LMB_Data_Write_28   <= (others => '0');
    LMB_Addr_Strobe_28  <= '0';
    LMB_Read_Strobe_28  <= '0';
    LMB_Write_Strobe_28 <= '0';
    LMB_Byte_Enable_28  <= (others => '0');

    LMB_Data_Addr_29    <= (others => '0');
    LMB_Data_Write_29   <= (others => '0');
    LMB_Addr_Strobe_29  <= '0';
    LMB_Read_Strobe_29  <= '0';
    LMB_Write_Strobe_29 <= '0';
    LMB_Byte_Enable_29  <= (others => '0');

    LMB_Data_Addr_30    <= (others => '0');
    LMB_Data_Write_30   <= (others => '0');
    LMB_Addr_Strobe_30  <= '0';
    LMB_Read_Strobe_30  <= '0';
    LMB_Write_Strobe_30 <= '0';
    LMB_Byte_Enable_30  <= (others => '0');

    LMB_Data_Addr_31    <= (others => '0');
    LMB_Data_Write_31   <= (others => '0');
    LMB_Addr_Strobe_31  <= '0';
    LMB_Read_Strobe_31  <= '0';
    LMB_Write_Strobe_31 <= '0';
    LMB_Byte_Enable_31  <= (others => '0');
  end generate No_Bus_MASTER_LMB;
    
  Use_AXI_IPIF : if (C_USE_UART = 1) or (C_DBG_REG_ACCESS = 1) generate
  begin
    -- ip2bus_data assignment - as core may use less than 32 bits
    ip2bus_data(C_S_AXI_DATA_WIDTH-1 downto C_REG_DATA_WIDTH) <= (others => '0');

    ---------------------------------------------------------------------------
    -- AXI lite IPIF
    ---------------------------------------------------------------------------
    AXI_LITE_IPIF_I : entity axi_lite_ipif_v3_0_3.axi_lite_ipif
      generic map (
        C_FAMILY               => C_FAMILY,
        C_S_AXI_ADDR_WIDTH     => C_S_AXI_ADDR_WIDTH,
        C_S_AXI_DATA_WIDTH     => C_S_AXI_DATA_WIDTH,
        C_S_AXI_MIN_SIZE       => C_S_AXI_MIN_SIZE,
        C_USE_WSTRB            => C_USE_WSTRB,
        C_DPHASE_TIMEOUT       => C_DPHASE_TIMEOUT,
        C_ARD_ADDR_RANGE_ARRAY => C_ARD_ADDR_RANGE_ARRAY,
        C_ARD_NUM_CE_ARRAY     => C_ARD_NUM_CE_ARRAY
      )

      port map(
        S_AXI_ACLK    => S_AXI_ACLK,
        S_AXI_ARESETN => S_AXI_ARESETN,
        S_AXI_AWADDR  => S_AXI_AWADDR,
        S_AXI_AWVALID => S_AXI_AWVALID,
        S_AXI_AWREADY => S_AXI_AWREADY,
        S_AXI_WDATA   => S_AXI_WDATA,
        S_AXI_WSTRB   => S_AXI_WSTRB,
        S_AXI_WVALID  => S_AXI_WVALID,
        S_AXI_WREADY  => S_AXI_WREADY,
        S_AXI_BRESP   => S_AXI_BRESP,
        S_AXI_BVALID  => S_AXI_BVALID,
        S_AXI_BREADY  => S_AXI_BREADY,
        S_AXI_ARADDR  => S_AXI_ARADDR,
        S_AXI_ARVALID => S_AXI_ARVALID,
        S_AXI_ARREADY => S_AXI_ARREADY,
        S_AXI_RDATA   => S_AXI_RDATA,
        S_AXI_RRESP   => S_AXI_RRESP,
        S_AXI_RVALID  => S_AXI_RVALID,
        S_AXI_RREADY  => S_AXI_RREADY,

        -- IP Interconnect (IPIC) port signals
        Bus2IP_Clk    => bus2ip_clk,
        Bus2IP_Resetn => bus2ip_resetn,
        IP2Bus_Data   => ip2bus_data,
        IP2Bus_WrAck  => ip2bus_wrack,
        IP2Bus_RdAck  => ip2bus_rdack,
        IP2Bus_Error  => ip2bus_error,
        Bus2IP_Addr   => open,
        Bus2IP_Data   => bus2ip_data,
        Bus2IP_RNW    => open,
        Bus2IP_BE     => open,
        Bus2IP_CS     => bus2ip_cs,
        Bus2IP_RdCE   => bus2ip_rdce,
        Bus2IP_WrCE   => bus2ip_wrce
      );

  end generate Use_AXI_IPIF;

  No_AXI_IPIF : if (C_USE_UART = 0) and (C_DBG_REG_ACCESS = 0) generate
  begin
    S_AXI_AWREADY <= '0';
    S_AXI_WREADY  <= '0';
    S_AXI_BRESP   <= (others => '0');
    S_AXI_BVALID  <= '0';
    S_AXI_ARREADY <= '0';
    S_AXI_RDATA   <= (others => '0');
    S_AXI_RRESP   <= (others => '0');
    S_AXI_RVALID  <= '0';

    bus2ip_clk    <= '0';
    bus2ip_resetn <= '0';
    bus2ip_data   <= (others => '0');
    bus2ip_rdce   <= (others => '0');
    bus2ip_wrce   <= (others => '0');
    bus2ip_cs     <= (others => '0');
  end generate No_AXI_IPIF;

end architecture IMP;
