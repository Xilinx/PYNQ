-------------------------------------------------------------------
-- (c) Copyright 1984 - 2012 Xilinx, Inc. All rights reserved.
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
-------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Filename:        axi_qspi_enhanced_mode.vhd
-- Version:         v3.0
-- Description:     Serial Peripheral Interface (SPI) Module for interfacing
--                  enhanced mode with a 32-bit AXI bus.
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




library axi_lite_ipif_v3_0_3;
use axi_lite_ipif_v3_0_3.axi_lite_ipif;
use axi_lite_ipif_v3_0_3.ipif_pkg.all;
library lib_srl_fifo_v1_0_2;
    use lib_srl_fifo_v1_0_2.srl_fifo_f;
library lib_pkg_v1_0_2;
    use lib_pkg_v1_0_2.all;
    use lib_pkg_v1_0_2.lib_pkg.log2;
    use lib_pkg_v1_0_2.lib_pkg.clog2;
    use lib_pkg_v1_0_2.lib_pkg.max2;
    use lib_pkg_v1_0_2.lib_pkg.RESET_ACTIVE;

library interrupt_control_v3_1_2;

library axi_quad_spi_v3_2_5;
    use axi_quad_spi_v3_2_5.all;

entity axi_qspi_enhanced_mode is
     generic (
      -- General Parameters
      C_FAMILY                 : string               := "virtex7";
      C_SUB_FAMILY             : string               := "virtex7";
      -------------------------
      C_AXI4_CLK_PS            : integer              := 10000;--AXI clock period
      C_EXT_SPI_CLK_PS         : integer              := 10000;--ext clock period
      C_FIFO_DEPTH             : integer              := 16;-- allowed 0,16,256.
      C_SCK_RATIO              : integer              := 16;--default in legacy mode
      C_NUM_SS_BITS            : integer range 1 to 32:= 1;
      C_NUM_TRANSFER_BITS      : integer              := 8; -- allowed 8, 16, 32
      -------------------------
      C_SPI_MODE               : integer range 0 to 2 := 0; -- used for differentiating
      C_USE_STARTUP            : integer range 0 to 1 := 1; --
      C_SPI_MEMORY             : integer range 0 to 3 := 1; -- 0 - mixed mode,
      -------------------------
      -- AXI4 Full Interface Parameters
      --*C_S_AXI4_ADDR_WIDTH      : integer range 32 to 32 := 32;
      C_S_AXI4_ADDR_WIDTH      : integer range 24 to 24 := 24;
      C_S_AXI4_DATA_WIDTH      : integer range 32 to 32 := 32;
      C_S_AXI4_ID_WIDTH        : integer range 1 to 16  := 4;
      -------------------------
      --C_AXI4_BASEADDR          : std_logic_vector       := x"FFFFFFFF";
      --C_AXI4_HIGHADDR          : std_logic_vector       := x"00000000";
      -------------------------
      C_ARD_ADDR_RANGE_ARRAY   : SLV64_ARRAY_TYPE :=
       (
        X"0000_0000_7000_0000", -- IP user0 base address
        X"0000_0000_7000_00FF", -- IP user0 high address
        X"0000_0000_7000_0100", -- IP user1 base address
        X"0000_0000_7000_01FF"  -- IP user1 high address
       );
      C_ARD_NUM_CE_ARRAY       : INTEGER_ARRAY_TYPE :=
       (
        1,         -- User0 CE Number
        8          -- User1 CE Number
       );
       C_S_AXI_SPI_MIN_SIZE    : std_logic_vector(31 downto 0):= X"0000007c";
       C_SPI_MEM_ADDR_BITS         : integer -- newly added 
    );
    port (
     -- external async clock for SPI interface logic
     EXT_SPI_CLK    : in std_logic;
     S_AXI4_ACLK     : in std_logic;
     S_AXI4_ARESETN  : in std_logic;
     -------------------------------
     -------------------------------
     --*AXI4 Full port interface* --
     -------------------------------
     ------------------------------------
     -- AXI Write Address Channel Signals
     ------------------------------------
     S_AXI4_AWID    : in  std_logic_vector((C_S_AXI4_ID_WIDTH-1) downto 0);
     S_AXI4_AWADDR  : in  std_logic_vector((C_SPI_MEM_ADDR_BITS-1)  downto 0);--((C_S_AXI4_ADDR_WIDTH-1) downto 0);
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
     S_AXI4_ARADDR  : in  std_logic_vector((C_SPI_MEM_ADDR_BITS-1)  downto 0);--((C_S_AXI4_ADDR_WIDTH-1) downto 0);
     S_AXI4_ARLEN   : in  std_logic_vector(7 downto 0);
     S_AXI4_ARSIZE  : in  std_logic_vector(2 downto 0);
     S_AXI4_ARBURST : in  std_logic_vector(1 downto 0);
     S_AXI4_ARLOCK  : in  std_logic;                    -- not supported in design
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
     Bus2IP_Clk          : out std_logic;
     Bus2IP_Reset        : out std_logic;
     --Bus2IP_Addr         : out std_logic_vector
     --                      (C_S_AXI4_ADDR_WIDTH-1 downto 0);
     Bus2IP_RNW          : out std_logic;
     Bus2IP_BE           : out std_logic_vector
                           (((C_S_AXI4_DATA_WIDTH/8) - 1) downto 0);
     Bus2IP_CS           : out std_logic_vector
                           (((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2 - 1) downto 0);
     Bus2IP_RdCE         : out std_logic_vector
                           ((calc_num_ce(C_ARD_NUM_CE_ARRAY) - 1) downto 0);
     Bus2IP_WrCE         : out std_logic_vector
                           ((calc_num_ce(C_ARD_NUM_CE_ARRAY) - 1) downto 0);
     Bus2IP_Data         : out std_logic_vector
                           ((C_S_AXI4_DATA_WIDTH-1) downto 0);
     IP2Bus_Data         : in  std_logic_vector
                           ((C_S_AXI4_DATA_WIDTH-1) downto 0);
     IP2Bus_WrAck        : in  std_logic;
     IP2Bus_RdAck        : in  std_logic;
     IP2Bus_Error        : in  std_logic;
     ---------------------------------
     burst_tr            : out std_logic;
     rready              : out std_logic
    );
 end entity axi_qspi_enhanced_mode;

architecture imp of axi_qspi_enhanced_mode is

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

 -- constant declaration
 constant ACTIVE_LOW_RESET : std_logic := '0';
-- local type declarations
    type STATE_TYPE is (
                         IDLE,
                         AXI_SINGLE_RD,
                         AXI_RD,
                         AXI_SINGLE_WR,
                         AXI_WR,
                         CHECK_AXI_LENGTH_ERROR,
                         AX_WRONG_BURST_TYPE,
                         WR_RESP_1,
                         WR_RESP_2,
                         RD_RESP_1,RD_LAST,
                         RD_RESP_2,
                         ERROR_RESP,
                         RD_ERROR_RESP
                       );

-- Signal Declaration
-----------------------------
    signal axi_full_sm_ps : STATE_TYPE;
    signal axi_full_sm_ns : STATE_TYPE;

 -- function declaration
-------------------------------------------------------------------------------
-- Get_Addr_Bits: Function Declarations
-------------------------------------------------------------------------------
-- code coverage -- function Get_Addr_Bits (y : std_logic_vector(31 downto 0)) return integer is
-- code coverage -- variable i : integer := 0;
-- code coverage --     begin
-- code coverage --         for i in 31 downto 0 loop
-- code coverage --             if y(i)='1' then
-- code coverage --                return (i);
-- code coverage --             end if;
-- code coverage --         end loop;
-- code coverage --         return -1;
-- code coverage -- end function Get_Addr_Bits;
 -- constant declaration
 constant C_ADDR_DECODE_BITS   : integer := 6; -- Get_Addr_Bits(C_S_AXI_SPI_MIN_SIZE);
 constant C_NUM_DECODE_BITS    : integer := C_ADDR_DECODE_BITS +1;
 constant ZEROS                : std_logic_vector(31 downto
                               (C_ADDR_DECODE_BITS+1)) := (others=>'0');
--   type decode_bit_array_type is Array(natural range 0 to (
--                           (C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1) of
--                           integer;

--   type short_addr_array_type is Array(natural range 0 to
--                           C_ARD_ADDR_RANGE_ARRAY'LENGTH-1) of
--                           std_logic_vector(0 to(C_ADDR_DECODE_BITS-1));
 -- signal declaration
 signal axi_size_reg             : std_logic_vector(2 downto 0);
 signal axi_size_cmb             : std_logic_vector(2 downto 0);
 signal bus2ip_rnw_i             : std_logic;
 signal bus2ip_addr_i            : std_logic_vector(31 downto 0); -- (31 downto 0); -- 8/18/2013
 signal wr_transaction           : std_logic;
 signal wr_addr_transaction      : std_logic;
 signal arready_i                : std_logic;
 signal awready_i, s_axi_wready_i                : std_logic;
 signal S_AXI4_RID_reg           : std_logic_vector((C_S_AXI4_ID_WIDTH-1) downto 0);
 signal S_AXI4_BID_reg           : std_logic_vector((C_S_AXI4_ID_WIDTH-1) downto 0);
 signal s_axi_mem_bresp_reg      : std_logic_vector(2 downto 0);
 signal axi_full_sm_ps_IDLE_cmb  : std_logic;
 signal s_axi_mem_bvalid_reg     : std_logic;
 signal bus2ip_BE_reg            : std_logic_vector(((C_S_AXI4_DATA_WIDTH/8) - 1) downto 0);
 signal axi_length_cmb           : std_logic_vector(7 downto 0);
 signal axi_length_reg           : std_logic_vector(7 downto 0);
 signal burst_transfer_cmb      : std_logic;
 signal burst_transfer_reg      : std_logic;
 signal axi_burst_cmb            : std_logic_vector(1 downto 0);
 signal axi_burst_reg            : std_logic_vector(1 downto 0);
 signal length_cntr              : std_logic_vector(7 downto 0);
 signal last_data_cmb            : std_logic;
 signal last_bt_one_data_cmb            : std_logic;
 signal last_data_acked          : std_logic;
 signal pr_state_idle            : std_logic;
 signal length_error             : std_logic;
 signal rnw_reg, rnw_cmb         : std_logic;
 signal arready_cmb              : std_logic;
 signal awready_cmb              : std_logic;
 signal wready_cmb               : std_logic;
 signal store_axi_signal_cmb     : std_logic;
 signal combine_ack, start, temp_i, response              : std_logic;
 signal s_axi4_rdata_i   : std_logic_vector((C_S_AXI4_DATA_WIDTH-1) downto 0);
 signal s_axi4_rresp_i   : std_logic_vector(1 downto 0);
 signal s_axi_rvalid_i   : std_logic;
 signal S_AXI4_BRESP_i : std_logic_vector(1 downto 0);
 signal s_axi_bvalid_i : std_logic;
 signal pr_state_length_chk : std_logic;
 signal axi_full_sm_ns_IDLE_cmb : std_logic;
 signal last_data_reg: std_logic;
 signal rst_en : std_logic;
 signal s_axi_rvalid_cmb, last_data, burst_tr_i,rready_i, store_data : std_logic;
 signal Bus2IP_Reset_i : std_logic;
 -----
 begin
 -----
-------------------------------------------------------------------------------
-- Address registered
-------------------------------------------------------------------------------
-- REGISTERING_RESET_P: Invert the reset coming from AXI4
-----------------------
REGISTERING_RESET_P : process (S_AXI4_ACLK) is
-----
begin
-----
     if (S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
        Bus2IP_Reset_i <=  not S_AXI4_ARESETN;
     end if;
end process REGISTERING_RESET_P;

Bus2IP_Reset   <= Bus2IP_Reset_i;
Bus2IP_Clk     <= S_AXI4_ACLK;
--Bus2IP_Resetn  <= S_AXI4_ARESETN;
--bus2ip_rnw_i     <= rnw_reg;-- '1' when S_AXI4_ARVALID='1' else '0';
BUS2IP_RNW     <= bus2ip_rnw_i;
Bus2IP_Data    <= S_AXI4_WDATA;
--Bus2IP_Addr    <= bus2ip_addr_i;
wr_transaction      <= S_AXI4_AWVALID and (S_AXI4_WVALID);

bus2ip_addr_i  <= ZEROS & S_AXI4_ARADDR(C_ADDR_DECODE_BITS downto 0) when (S_AXI4_ARVALID='1')
                  else
                  ZEROS & S_AXI4_AWADDR(C_ADDR_DECODE_BITS downto 0);
		  --S_AXI4_ARADDR(C_ADDR_DECODE_BITS+1 downto 0) when (S_AXI4_ARVALID='1')
                  --else                                                    
		  --S_AXI4_AWADDR(C_ADDR_DECODE_BITS+1 downto 0);                         


-- read and write transactions should be separate
-- preferencec of read over write
-- only narrow transfer of 8-bit are supported
-- for 16-bit and 32-bit transactions error should be generated - dont provide these signals to internal logic
--wr_transaction      <= S_AXI4_AWVALID and (S_AXI4_WVALID);
--wr_addr_transaction <= S_AXI4_AWVALID and (not S_AXI4_WVALID);
-------------------------------------------------------------------------------
AXI_ARREADY_P: process (S_AXI4_ACLK) is
begin
    if (S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
       if (Bus2IP_Reset_i = RESET_ACTIVE) then
          arready_i <='0';
       else
          arready_i  <= arready_cmb;
       end if;
    end if;
end process AXI_ARREADY_P;
--------------------------
S_AXI4_ARREADY <= arready_i; -- arready_i;--IP2Bus_RdAck; --arready_i;
--------------------------
AXI_AWREADY_P: process (S_AXI4_ACLK) is
begin
    if (S_AXI4_ACLK'event and S_AXI4_ACLK = '1') then
        if (Bus2IP_Reset_i = RESET_ACTIVE) then
          awready_i <='0';
        else
          awready_i  <= awready_cmb;
        end if;
    end if;
end process AXI_AWREADY_P;
--------------------------
S_AXI4_AWREADY <= awready_i;
--------------------------
S_AXI4_BRESP_P : process (S_AXI4_ACLK) is
  begin
    if S_AXI4_ACLK'event and S_AXI4_ACLK = '1' then
      if (axi_full_sm_ps = IDLE) then
         S_AXI4_BRESP_i <= (others => '0');
      elsif (axi_full_sm_ps = AXI_WR) or (axi_full_sm_ps = AXI_SINGLE_WR) then
         S_AXI4_BRESP_i <= (IP2Bus_Error) & '0';
      end if;
    end if;
end process S_AXI4_BRESP_P;
---------------------------
S_AXI4_BRESP <= S_AXI4_BRESP_i;
-------------------------------
--S_AXI_BVALID_I_P: below process provides logic for valid write response signal
-------------------
S_AXI_BVALID_I_P : process (S_AXI4_ACLK) is
  begin
    if S_AXI4_ACLK'event and S_AXI4_ACLK = '1' then
      if S_AXI4_ARESETN = '0' then
         s_axi_bvalid_i <= '0';
      elsif(axi_full_sm_ps = WR_RESP_1)then
         s_axi_bvalid_i <= '1';
      elsif(S_AXI4_BREADY = '1')then
         s_axi_bvalid_i <= '0';
      end if;
    end if;
end process S_AXI_BVALID_I_P;
-----------------------------
S_AXI4_BVALID <= s_axi_bvalid_i;
--------------------------------
----S_AXI_WREADY_I_P: below process provides logic for valid write response signal
---------------------
S_AXI_WREADY_I_P : process (S_AXI4_ACLK) is
  begin
    if S_AXI4_ACLK'event and S_AXI4_ACLK = '1' then
      if S_AXI4_ARESETN = '0' then
         s_axi_wready_i <= '0';
      else
         s_axi_wready_i <= wready_cmb;
      end if;
    end if;
end process S_AXI_WREADY_I_P;
-------------------------------
S_AXI4_WREADY <= s_axi_wready_i;
--------------------------------
-------------------------------------------------------------------------------
-- REG_BID_P,REG_RID_P: Below process makes the RID and BID '0' at POR and
--                    : generate proper values based upon read/write
--                      transaction
-----------------------
REG_RID_P: process (S_AXI4_ACLK) is
begin
    if (S_AXI4_ACLK'event and S_AXI4_ACLK='1') then
       if (S_AXI4_ARESETN = '0') then
         S_AXI4_RID_reg       <= (others=> '0');
       elsif(store_axi_signal_cmb = '1')then
         S_AXI4_RID_reg       <= S_AXI4_ARID ;
       end if;
    end if;
end process REG_RID_P;
----------------------
S_AXI4_RID <= S_AXI4_RID_reg;
-----------------------------

REG_BID_P: process (S_AXI4_ACLK) is
begin
    if (S_AXI4_ACLK'event and S_AXI4_ACLK='1') then
       if (S_AXI4_ARESETN=ACTIVE_LOW_RESET) then
         S_AXI4_BID_reg       <= (others=> '0');
       elsif(store_axi_signal_cmb = '1')then
         S_AXI4_BID_reg       <= S_AXI4_AWID;-- and pr_state_length_chk;
       end if;
    end if;
end process REG_BID_P;
-----------------------
S_AXI4_BID <= S_AXI4_BID_reg;
------------------------------
------------------------
-- BUS2IP_BE_P:Register Bus2IP_BE for write strobe during write mode else '1'.
------------------------
BUS2IP_BE_P: process (S_AXI4_ACLK) is
------------
begin
    if (S_AXI4_ACLK'event and S_AXI4_ACLK='1') then
        if ((Bus2IP_Reset_i = RESET_ACTIVE)) then
            bus2ip_BE_reg   <= (others => '0');
        else
          if (rnw_cmb = '0'--    and
              --(wready_cmb = '1')
              ) then
              bus2ip_BE_reg <= S_AXI4_WSTRB;
          else -- if(rnw_cmb = '1') then
              bus2ip_BE_reg <= (others => '1');
          end if;
        end if;
    end if;
end process BUS2IP_BE_P;
------------------------
Bus2IP_BE      <= bus2ip_BE_reg;

axi_length_cmb <= S_AXI4_ARLEN when (rnw_cmb = '1')
                  else
                  S_AXI4_AWLEN;
burst_transfer_cmb <= (or_reduce(axi_length_cmb));

BURST_LENGTH_REG_P:process(S_AXI4_ACLK)is
-----
begin
-----
    if(S_AXI4_ACLK'event and S_AXI4_ACLK='1')then
        if (S_AXI4_ARESETN=ACTIVE_LOW_RESET) then
            axi_length_reg <= (others => '0');
            burst_transfer_reg <= '0';
        elsif((store_axi_signal_cmb = '1'))then
            axi_length_reg <= axi_length_cmb;
            burst_transfer_reg <= burst_transfer_cmb;
        end if;
    end if;
end process BURST_LENGTH_REG_P;
-----------------------
burst_tr_i <= burst_transfer_reg;
burst_tr <= burst_tr_i;
-------------------------------------------------------------------------------
axi_size_cmb <= S_AXI4_ARSIZE(2 downto 0) when (rnw_cmb = '1')
                else
                S_AXI4_AWSIZE(2 downto 0);
SIZE_REG_P:process(S_AXI4_ACLK)is
-----
begin
-----
    if(S_AXI4_ACLK'event and S_AXI4_ACLK='1')then
        if (S_AXI4_ARESETN=ACTIVE_LOW_RESET) then
            axi_size_reg <= (others => '0');
        elsif((store_axi_signal_cmb = '1'))then
            axi_size_reg <= axi_size_cmb;
        end if;
    end if;
end process SIZE_REG_P;
-----------------------
axi_burst_cmb <= S_AXI4_ARBURST when (rnw_cmb = '1')
                 else
                 S_AXI4_AWBURST;
BURST_REG_P:process(S_AXI4_ACLK)is
-----
begin
-----
    if(S_AXI4_ACLK'event and S_AXI4_ACLK='1')then
        if (S_AXI4_ARESETN = ACTIVE_LOW_RESET) then
            axi_burst_reg <= (others => '0');
        elsif(store_axi_signal_cmb = '1')then
            axi_burst_reg <= axi_burst_cmb;
        end if;
    end if;
end process BURST_REG_P;
-----------------------
combine_ack <= IP2Bus_WrAck or IP2Bus_RdAck;
--------------------------------------------
LENGTH_CNTR_P:process(S_AXI4_ACLK)is
begin
    if(S_AXI4_ACLK'event and S_AXI4_ACLK='1')then
        if (S_AXI4_ARESETN = ACTIVE_LOW_RESET) then
            length_cntr <= (others => '0');
        elsif((store_axi_signal_cmb = '1'))then
            length_cntr <= axi_length_cmb;
        elsif (wready_cmb = '1' and S_AXI4_WVALID = '1') or
              (S_AXI4_RREADY = '1' and s_axi_rvalid_i = '1') then   -- burst length error
            length_cntr <= length_cntr - '1';
        end if;
    end if;
end process LENGTH_CNTR_P;
--------------------------
--last_data_cmb    <= or_reduce(length_cntr(7 downto 1)) and length_cntr(1);
rready <= rready_i;

last_bt_one_data_cmb    <= not(or_reduce(length_cntr(7 downto 1))) and length_cntr(0) and S_AXI4_RREADY;
last_data_cmb <= not(or_reduce(length_cntr(7 downto 0)));
--temp_i           <= (combine_ack and last_data_reg)or rst_en;
LAST_DATA_ACKED_P: process (S_AXI4_ACLK) is
-----------------
begin
-----
    if (S_AXI4_ACLK'event and S_AXI4_ACLK='1') then
        if(axi_full_sm_ps_IDLE_cmb = '1')     then
            last_data_acked <= '0';
        elsif(burst_tr_i = '0')then
            if(S_AXI4_RREADY = '1' and last_data_acked = '1')then
               last_data_acked <= '0';
            else
               last_data_acked <= last_data_cmb and s_axi_rvalid_cmb;
            end if;
        else
            if(S_AXI4_RREADY = '1' and last_data_acked = '1') then
                    last_data_acked <= '0';
            elsif(S_AXI4_RREADY = '0' and last_data_acked = '1')then
                last_data_acked <= '1';
            else
                last_data_acked <= last_data and s_axi_rvalid_i and S_AXI4_RREADY;
            end if;
        end if;
    end if;
end process LAST_DATA_ACKED_P;
------------------------------
S_AXI4_RLAST <= last_data_acked;
--------------------------------

-- S_AXI4_RDATA_RESP_P : BElow process generates the RRESP and RDATA on AXI
-----------------------
S_AXI4_RDATA_RESP_P : process (S_AXI4_ACLK) is
  begin
    if S_AXI4_ACLK'event and S_AXI4_ACLK = '1' then
      if (S_AXI4_ARESETN = '0') then
         S_AXI4_RRESP_i <= (others => '0');
         S_AXI4_RDATA_i <= (others => '0');
      elsif(S_AXI4_RREADY = '1' )or(store_data = '1') then --if --((axi_full_sm_ps = AXI_SINGLE_RD) or (axi_full_sm_ps = AXI_BURST_RD)) then
        S_AXI4_RRESP_i <= (IP2Bus_Error) & '0';
        S_AXI4_RDATA_i <=  IP2Bus_Data;
      end if;
    end if;
end process S_AXI4_RDATA_RESP_P;

S_AXI4_RRESP <= S_AXI4_RRESP_i;
S_AXI4_RDATA <= S_AXI4_RDATA_i;
-----------------------------
-- S_AXI_RVALID_I_P : below process generates the RVALID response on read channel
----------------------
S_AXI_RVALID_I_P : process (S_AXI4_ACLK) is
  begin
    if S_AXI4_ACLK'event and S_AXI4_ACLK = '1' then
      if (axi_full_sm_ps = IDLE) then
         s_axi_rvalid_i <= '0';
      elsif(S_AXI4_RREADY = '0') and (s_axi_rvalid_i = '1') then
          s_axi_rvalid_i <= s_axi_rvalid_i;
      else
          s_axi_rvalid_i <= s_axi_rvalid_cmb;
      end if;
    end if;
end process S_AXI_RVALID_I_P;
-----------------------------
S_AXI4_RVALID <= s_axi_rvalid_i;
-- -----------------------------

  --   Addr_int    <= S_AXI_ARADDR when(rnw_cmb_dup = '1')
  --                  else
  --                  S_AXI_AWADDR;
axi_full_sm_ns_IDLE_cmb <= '1' when (axi_full_sm_ns = IDLE) else '0';
axi_full_sm_ps_IDLE_cmb <= '1' when (axi_full_sm_ps = IDLE) else '0';
pr_state_idle           <= '1' when axi_full_sm_ps = IDLE else '0';
pr_state_length_chk     <= '1' when axi_full_sm_ps = CHECK_AXI_LENGTH_ERROR
                           else
                           '0';
REGISTER_LOWER_ADDR_BITS_P:process(S_AXI4_ACLK) is
begin
-----
     if (S_AXI4_ACLK'event and S_AXI4_ACLK='1') then
        if (axi_full_sm_ps_IDLE_cmb = '1') then
            length_error <= '0';
        elsif(burst_transfer_cmb = '1')then -- means its a burst
             --if (bus2ip_addr_i (7 downto 3) = "01101")then
	     if (bus2ip_addr_i (6 downto 3) = "1101")then
                 length_error <= '0';
             else
                 length_error <= '1';
             end if;
        end if;
     end if;
end process REGISTER_LOWER_ADDR_BITS_P;
---------------------------------------
-- length_error <= '0';
---------------------------
REG_P: process (S_AXI4_ACLK) is
begin
-----
    if (S_AXI4_ACLK'event and S_AXI4_ACLK='1') then
        if (Bus2IP_Reset_i = RESET_ACTIVE) then
            axi_full_sm_ps   <= IDLE;
            last_data_reg  <= '0';
        else
            axi_full_sm_ps   <= axi_full_sm_ns;
            last_data_reg  <= last_data_cmb;
        end if;
    end if;
end process REG_P;
-------------------------------------------------------
STORE_SIGNALS_P: process (S_AXI4_ACLK) is
begin
-----
    if (S_AXI4_ACLK'event and S_AXI4_ACLK='1') then
        if (Bus2IP_Reset_i = RESET_ACTIVE) then
            rnw_reg        <= '0';
        else-- if(store_axi_signal_cmb = '1')then
            rnw_reg        <= rnw_cmb;
        end if;
    end if;
end process STORE_SIGNALS_P;
-------------------------------------------------------
 AXI_FULL_STATE_MACHINE_P:process(
                                  axi_full_sm_ps        ,
                                  S_AXI4_ARVALID        ,
                                  S_AXI4_AWVALID        ,
                                  S_AXI4_WVALID         ,
                                  S_AXI4_BREADY         ,
                                  S_AXI4_RREADY         ,
                                  wr_transaction        ,
                                  wr_addr_transaction   ,
                                  length_error          ,
                                  IP2Bus_WrAck          ,
                                  last_data_cmb         ,
                                  IP2Bus_RdAck          ,
                                  IP2Bus_Error          ,
                                  burst_transfer_cmb    ,
                                  last_bt_one_data_cmb  ,
                                  rnw_reg               ,
                                  length_cntr
                                  )is

 -----
 begin
 -----
     arready_cmb <= '0';
     awready_cmb <= '0';
     wready_cmb  <= '0';
     start       <= '0';
     rst_en <= '0';
     temp_i <= '0';
     store_axi_signal_cmb <= '0';
     s_axi_rvalid_cmb <= '0';
     rready_i <= '0';
rnw_cmb <= '0';
last_data <= '0';
store_data <= '0';
     case axi_full_sm_ps is
     when IDLE                => if(S_AXI4_ARVALID = '1') then
                                   start <= '1';
                                   store_axi_signal_cmb <= '1';
                                   arready_cmb <= '1';
                                   if(burst_transfer_cmb = '1') then
                                       axi_full_sm_ns <= AXI_RD;
                                   else
                                       axi_full_sm_ns <= AXI_SINGLE_RD;
                                   end if;
                                 elsif(wr_transaction = '1')then
                                   start <= '1';
                                   store_axi_signal_cmb <= '1';
                                   if(burst_transfer_cmb = '1') then
                                       awready_cmb <= '1';
                                       wready_cmb  <= '1';
                                       axi_full_sm_ns <= AXI_WR;
                                   else
                                       axi_full_sm_ns <= AXI_SINGLE_WR;
                                   end if;
                                 else
                                     axi_full_sm_ns <= IDLE;
                                 end if;
                                 rnw_cmb <= S_AXI4_ARVALID and (not S_AXI4_AWVALID);
     ------------------------------
     when CHECK_AXI_LENGTH_ERROR => if (length_error = '0') then
                                        if(rnw_reg = '1')then
                                            arready_cmb <= '1';
                                            axi_full_sm_ns <= AXI_RD;
                                        else
                                            awready_cmb <= '1';
                                            axi_full_sm_ns <= AXI_WR;
                                        end if;
                                        start <= '1';
                                    else

                                        axi_full_sm_ns <= ERROR_RESP;
                                    end if;
     ---------------------------------------------------------
     when AXI_SINGLE_RD         => --arready_cmb       <= IP2Bus_RdAck;
                                   s_axi_rvalid_cmb  <= IP2Bus_RdAck or IP2Bus_Error;
                                   temp_i            <= IP2Bus_RdAck or IP2Bus_Error;
                                   rready_i <= '1';
                                   if(IP2Bus_RdAck = '1')or (IP2Bus_Error = '1') then
                                       store_data <= not S_AXI4_RREADY;
                                       axi_full_sm_ns <= RD_LAST;
                                   else
                                       axi_full_sm_ns <= AXI_SINGLE_RD;
                                   end if;
                                   rnw_cmb <= rnw_reg;
     when AXI_RD                =>
                                   rready_i <= S_AXI4_RREADY and not last_data_cmb;
                                   last_data <= last_bt_one_data_cmb;
                                   if(last_data_cmb = '1') then
                                         if(S_AXI4_RREADY = '1')then
                                           temp_i <= '1';--IP2Bus_RdAck;--IP2Bus_WrAck;
                                           rst_en <= '1';--IP2Bus_RdAck;--IP2Bus_WrAck;
                                           axi_full_sm_ns <= IDLE;
                                         else
                                           s_axi_rvalid_cmb <= not S_AXI4_RREADY;
                                           last_data <= not S_AXI4_RREADY;
                                           temp_i <= '1';
                                           axi_full_sm_ns <= RD_LAST;
                                         end if;
                                   else
                                          s_axi_rvalid_cmb  <= IP2Bus_RdAck or IP2Bus_Error; -- not last_data_cmb;
                                          axi_full_sm_ns <= AXI_RD;
                                   end if;
                                   rnw_cmb <= rnw_reg;
     ----------------------------------------------------------
     when AXI_SINGLE_WR         => awready_cmb <= IP2Bus_WrAck or IP2Bus_Error;
                                   wready_cmb  <= IP2Bus_WrAck or IP2Bus_Error;
                                   temp_i      <= IP2Bus_WrAck or IP2Bus_Error;

                                   if(IP2Bus_WrAck = '1')or (IP2Bus_Error = '1')then

                                       axi_full_sm_ns <= WR_RESP_1;
                                   else
                                       axi_full_sm_ns <= AXI_SINGLE_WR;
                                   end if;
                                   rnw_cmb <= rnw_reg;
     when AXI_WR                => --if(IP2Bus_WrAck = '1')then
                                      wready_cmb <= '1';--IP2Bus_WrAck;
                                      if(last_data_cmb = '1') then
                                          wready_cmb <= '0';
                                          temp_i <= '1';--IP2Bus_WrAck;
                                          rst_en <= '1';--IP2Bus_WrAck;
                                          axi_full_sm_ns <= WR_RESP_1;
                                      else
                                          axi_full_sm_ns <= AXI_WR;
                                      end if;
                                   rnw_cmb <= rnw_reg;
     -----------------------------------------------------------
     when WR_RESP_1             =>  --if(S_AXI4_BREADY = '1') then
                                    --        axi_full_sm_ns <= IDLE;
                                  --else
                                           axi_full_sm_ns <= WR_RESP_2;
                                 -- end if;
     -----------------------------------------------------------
     when WR_RESP_2             =>  if(S_AXI4_BREADY = '1') then
                                     axi_full_sm_ns <= IDLE;
                                 else
                                     axi_full_sm_ns <= WR_RESP_2;
                                 end if;
     -----------------------------------------------------------
     when RD_LAST           => if(S_AXI4_RREADY = '1') then -- and (TX_FIFO_Empty = '1') then
                                    last_data <= not S_AXI4_RREADY;
                                    axi_full_sm_ns <= IDLE;
                                 else
                                    last_data <= not S_AXI4_RREADY;
                                    s_axi_rvalid_cmb <= not S_AXI4_RREADY;
                                    axi_full_sm_ns <= RD_LAST;
                                    temp_i <= '1';
                                 end if;

     -----------------------------------------------------------
     when RD_RESP_2           => if(S_AXI4_RREADY = '1') then
                                    axi_full_sm_ns <= IDLE;
                                else
                                    axi_full_sm_ns <= RD_RESP_2;
                                end if;
     -----------------------------------------------------------

     when ERROR_RESP          => if(length_cntr = "00000000") and
                                      (S_AXI4_BREADY = '1') then
                                       axi_full_sm_ns <= IDLE;
                                    else
                                       axi_full_sm_ns <= ERROR_RESP;
                                    end if;
                                    response <= '1';

     when others =>              axi_full_sm_ns <= IDLE;
     end case;
 end process AXI_FULL_STATE_MACHINE_P;

 -------------------------------------------------------------------------------
  -- AXI Transaction Controller signals registered
-------------------------------------------------------------------------------

I_DECODER : entity axi_quad_spi_v3_2_5.qspi_address_decoder
    generic map
    (
     C_BUS_AWIDTH          => C_NUM_DECODE_BITS, -- C_S_AXI4_ADDR_WIDTH,
     C_S_AXI4_MIN_SIZE     => C_S_AXI_SPI_MIN_SIZE,
     C_ARD_ADDR_RANGE_ARRAY=> C_ARD_ADDR_RANGE_ARRAY,
     C_ARD_NUM_CE_ARRAY    => C_ARD_NUM_CE_ARRAY,
     C_FAMILY              => "nofamily"
    )
    port map
    (
     Bus_clk               =>  S_AXI4_ACLK,
     Bus_rst               =>  S_AXI4_ARESETN,
     Address_In_Erly       =>  bus2ip_addr_i(C_ADDR_DECODE_BITS downto 0), -- (C_ADDR_DECODE_BITS downto 0),
     Address_Valid_Erly    =>  start,
     Bus_RNW               =>  S_AXI4_ARVALID,
     Bus_RNW_Erly          =>  S_AXI4_ARVALID,
     CS_CE_ld_enable       =>  start,
     Clear_CS_CE_Reg       =>  temp_i,
     RW_CE_ld_enable       =>  start,
     CS_for_gaps           =>  open,
      -- Decode output signals
     CS_Out                =>  Bus2IP_CS,
     RdCE_Out              =>  Bus2IP_RdCE,
     WrCE_Out              =>  Bus2IP_WrCE
      );

 end architecture imp;
 ------------------------------------------------------------------------------
