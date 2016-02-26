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
-- ************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        slave_attachment.vhd
-- Version:         v2.0
-- Description:     AXI slave attachment supporting single transfers
-------------------------------------------------------------------------------
-- Structure:   This section shows the hierarchical structure of axi_lite_ipif.
--
--              --axi_lite_ipif.vhd
--                    --slave_attachment.vhd
--                       --address_decoder.vhd
-------------------------------------------------------------------------------
-- Author:      BSB
--
-- History:
--
--  BSB      05/20/10      -- First version
-- ~~~~~~
--  - Created the first version v1.00.a
-- ^^^^^^
-- ~~~~~~
--  SK       06/09/10      -- updated to reduce the utilization
--  1. State machine is re-designed
--  2. R and B channels are registered and AW, AR, W channels are non-registered
--  3. Address decoding is done only for the required address bits and not complete
--     32 bits
--  4. combined the response signals like ip2bus_error in optimzed code to remove the mux
--  5. Added local function "clog2" with "integer" as input in place of proc_common_pkg
--     function.
-- ^^^^^^
-- ~~~~~~
--  SK       12/16/12      -- v2.0
--  1. up reved to major version for 2013.1 Vivado release. No logic updates.
--  2. Updated the version of AXI LITE IPIF to v2.0 in X.Y format
--  3. updated the proc common version to proc_common_base_v5_0
--  4. No Logic Updates
-- ^^^^^^
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_TYPE"
--      access_cs machine next state:               "*_ns"
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
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

--library proc_common_base_v5_0;
--use proc_common_base_v5_0.proc_common_pkg.clog2;
--use proc_common_base_v5_0.ipif_pkg.all;

library axi_lite_ipif_v3_0_3;
use axi_lite_ipif_v3_0_3.ipif_pkg.all;

-------------------------------------------------------------------------------
--                     Definition of Generics
-------------------------------------------------------------------------------
-- C_IPIF_ABUS_WIDTH     -- IPIF Address bus width
-- C_IPIF_DBUS_WIDTH     -- IPIF Data Bus width
-- C_S_AXI_MIN_SIZE      -- Minimum address range of the IP
-- C_USE_WSTRB           -- Use write strobs or not
-- C_DPHASE_TIMEOUT      -- Data phase time out counter
-- C_ARD_ADDR_RANGE_ARRAY-- Base /High Address Pair for each Address Range
-- C_ARD_NUM_CE_ARRAY    -- Desired number of chip enables for an address range
-- C_FAMILY              -- Target FPGA family
-------------------------------------------------------------------------------
--                  Definition of Ports
-------------------------------------------------------------------------------
-- S_AXI_ACLK            -- AXI Clock
-- S_AXI_ARESET          -- AXI Reset
-- S_AXI_AWADDR          -- AXI Write address
-- S_AXI_AWVALID         -- Write address valid
-- S_AXI_AWREADY         -- Write address ready
-- S_AXI_WDATA           -- Write data
-- S_AXI_WSTRB           -- Write strobes
-- S_AXI_WVALID          -- Write valid
-- S_AXI_WREADY          -- Write ready
-- S_AXI_BRESP           -- Write response
-- S_AXI_BVALID          -- Write response valid
-- S_AXI_BREADY          -- Response ready
-- S_AXI_ARADDR          -- Read address
-- S_AXI_ARVALID         -- Read address valid
-- S_AXI_ARREADY         -- Read address ready
-- S_AXI_RDATA           -- Read data
-- S_AXI_RRESP           -- Read response
-- S_AXI_RVALID          -- Read valid
-- S_AXI_RREADY          -- Read ready
-- Bus2IP_Clk            -- Synchronization clock provided to User IP
-- Bus2IP_Reset          -- Active high reset for use by the User IP
-- Bus2IP_Addr           -- Desired address of read or write operation
-- Bus2IP_RNW            -- Read or write indicator for the transaction
-- Bus2IP_BE             -- Byte enables for the data bus
-- Bus2IP_CS             -- Chip select for the transcations
-- Bus2IP_RdCE           -- Chip enables for the read
-- Bus2IP_WrCE           -- Chip enables for the write
-- Bus2IP_Data           -- Write data bus to the User IP
-- IP2Bus_Data           -- Input Read Data bus from the User IP
-- IP2Bus_WrAck          -- Active high Write Data qualifier from the IP
-- IP2Bus_RdAck          -- Active high Read Data qualifier from the IP
-- IP2Bus_Error          -- Error signal from the IP
-------------------------------------------------------------------------------

entity slave_attachment is
  generic (

    C_ARD_ADDR_RANGE_ARRAY: SLV64_ARRAY_TYPE :=
       (
        X"0000_0000_7000_0000", -- IP user0 base address
        X"0000_0000_7000_00FF", -- IP user0 high address
        X"0000_0000_7000_0100", -- IP user1 base address
        X"0000_0000_7000_01FF"  -- IP user1 high address
       );
    C_ARD_NUM_CE_ARRAY  : INTEGER_ARRAY_TYPE :=
       (
        1,         -- User0 CE Number
        8          -- User1 CE Number
       );
    C_IPIF_ABUS_WIDTH   : integer := 32;
    C_IPIF_DBUS_WIDTH   : integer := 32;
    C_S_AXI_MIN_SIZE    : std_logic_vector(31 downto 0):= X"000001FF";
    C_USE_WSTRB         : integer := 0;
    C_DPHASE_TIMEOUT    : integer range 0 to 512 := 16;
    C_FAMILY            : string  := "virtex6"
        );
  port(
        -- AXI signals
    S_AXI_ACLK          : in  std_logic;
    S_AXI_ARESETN       : in  std_logic;
    S_AXI_AWADDR        : in  std_logic_vector
                          (C_IPIF_ABUS_WIDTH-1 downto 0);
    S_AXI_AWVALID       : in  std_logic;
    S_AXI_AWREADY       : out std_logic;
    S_AXI_WDATA         : in  std_logic_vector
                          (C_IPIF_DBUS_WIDTH-1 downto 0);
    S_AXI_WSTRB         : in  std_logic_vector
                          ((C_IPIF_DBUS_WIDTH/8)-1 downto 0);
    S_AXI_WVALID        : in  std_logic;
    S_AXI_WREADY        : out std_logic;
    S_AXI_BRESP         : out std_logic_vector(1 downto 0);
    S_AXI_BVALID        : out std_logic;
    S_AXI_BREADY        : in  std_logic;
    S_AXI_ARADDR        : in  std_logic_vector
                          (C_IPIF_ABUS_WIDTH-1 downto 0);
    S_AXI_ARVALID       : in  std_logic;
    S_AXI_ARREADY       : out std_logic;
    S_AXI_RDATA         : out std_logic_vector
                          (C_IPIF_DBUS_WIDTH-1 downto 0);
    S_AXI_RRESP         : out std_logic_vector(1 downto 0);
    S_AXI_RVALID        : out std_logic;
    S_AXI_RREADY        : in  std_logic;
    -- Controls to the IP/IPIF modules
    Bus2IP_Clk          : out std_logic;
    Bus2IP_Resetn       : out std_logic;
    Bus2IP_Addr         : out std_logic_vector
                          (C_IPIF_ABUS_WIDTH-1 downto 0);
    Bus2IP_RNW          : out std_logic;
    Bus2IP_BE           : out std_logic_vector
                          (((C_IPIF_DBUS_WIDTH/8) - 1) downto 0);
    Bus2IP_CS           : out std_logic_vector
                          (((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2 - 1) downto 0);
    Bus2IP_RdCE         : out std_logic_vector
                          ((calc_num_ce(C_ARD_NUM_CE_ARRAY) - 1) downto 0);
    Bus2IP_WrCE         : out std_logic_vector
                          ((calc_num_ce(C_ARD_NUM_CE_ARRAY) - 1) downto 0);
    Bus2IP_Data         : out std_logic_vector
                          ((C_IPIF_DBUS_WIDTH-1) downto 0);
    IP2Bus_Data         : in  std_logic_vector
                          ((C_IPIF_DBUS_WIDTH-1) downto 0);
    IP2Bus_WrAck        : in  std_logic;
    IP2Bus_RdAck        : in  std_logic;
    IP2Bus_Error        : in  std_logic
    );
end entity slave_attachment;

-------------------------------------------------------------------------------
architecture imp of slave_attachment is
----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Get_Addr_Bits: Function Declarations
-------------------------------------------------------------------------------
function Get_Addr_Bits (y : std_logic_vector(31 downto 0)) return integer is
variable i : integer := 0;
    begin
        for i in 31 downto 0 loop
            if y(i)='1' then
               return (i);
            end if;
        end loop;
        return -1;
end function Get_Addr_Bits;

-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
constant CS_BUS_SIZE          : integer := C_ARD_ADDR_RANGE_ARRAY'length/2;
constant CE_BUS_SIZE          : integer := calc_num_ce(C_ARD_NUM_CE_ARRAY);

constant C_ADDR_DECODE_BITS   : integer := Get_Addr_Bits(C_S_AXI_MIN_SIZE);
constant C_NUM_DECODE_BITS    : integer := C_ADDR_DECODE_BITS +1;
constant ZEROS                : std_logic_vector((C_IPIF_ABUS_WIDTH-1) downto
                               (C_ADDR_DECODE_BITS+1)) := (others=>'0');
-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
signal s_axi_bvalid_i         : std_logic:= '0';
signal s_axi_arready_i        : std_logic;
signal s_axi_rvalid_i         : std_logic:= '0';
signal start                  : std_logic;
signal start2                  : std_logic;
-- Intermediate IPIC signals
signal bus2ip_addr_i          : std_logic_vector
                                ((C_IPIF_ABUS_WIDTH-1) downto 0);
signal timeout                : std_logic;

signal rd_done,wr_done        : std_logic;
signal rd_done1,wr_done1        : std_logic;
--signal rd_done2,wr_done2        : std_logic;
signal wrack_1,rdack_1        : std_logic;
--signal wrack_2,rdack_2        : std_logic;
signal rst                    : std_logic;
signal temp_i                 : std_logic;

  type BUS_ACCESS_STATES is (
    SM_IDLE,
    SM_READ,
    SM_WRITE,
    SM_RESP
  );
signal state : BUS_ACCESS_STATES;

signal cs_for_gaps_i : std_logic;
signal bus2ip_rnw_i  : std_logic;
signal s_axi_bresp_i : std_logic_vector(1 downto 0):=(others => '0');
signal s_axi_rresp_i : std_logic_vector(1 downto 0):=(others => '0');
signal s_axi_rdata_i : std_logic_vector
                     (C_IPIF_DBUS_WIDTH-1 downto 0):=(others => '0');
signal is_read, is_write : std_logic;
-------------------------------------------------------------------------------
-- begin the architecture logic
-------------------------------------------------------------------------------
begin

-------------------------------------------------------------------------------
-- Address registered
-------------------------------------------------------------------------------
Bus2IP_Clk     <= S_AXI_ACLK;
Bus2IP_Resetn  <= S_AXI_ARESETN;
--bus2ip_rnw_i     <= '1' when S_AXI_ARVALID='1'
--                  else
--                  '0';
BUS2IP_RNW     <= bus2ip_rnw_i;
Bus2IP_BE      <= S_AXI_WSTRB when ((C_USE_WSTRB = 1) and (bus2ip_rnw_i = '0'))
                  else
                  (others => '1');
Bus2IP_Data    <= S_AXI_WDATA;
Bus2IP_Addr    <= bus2ip_addr_i;

-- For AXI Lite interface, interconnect will duplicate the addresses on both the
-- read and write channel. so onlyone address is used for decoding as well as
-- passing it to IP.
--bus2ip_addr_i  <= ZEROS & S_AXI_ARADDR(C_ADDR_DECODE_BITS downto 0)
--                  when (S_AXI_ARVALID='1')
--		  else
--                ZEROS & S_AXI_AWADDR(C_ADDR_DECODE_BITS downto 0);

--------------------------------------------------------------------------------
-- start signal will be used to latch the incoming address

--start<= (S_AXI_ARVALID or (S_AXI_AWVALID and S_AXI_WVALID))
--        when (state = SM_IDLE)
--        else
--        '0';

-- x_done signals are used to release the hold from AXI, it will generate "ready"
-- signal on the read and write address channels.

rd_done <= IP2Bus_RdAck or (timeout and is_read);
wr_done <= IP2Bus_WrAck or (timeout and is_write);

--wr_done1 <= (not (wrack_1) and IP2Bus_WrAck) or timeout;
--rd_done1 <= (not (rdack_1) and IP2Bus_RdAck) or timeout;

temp_i  <= rd_done or wr_done;
-------------------------------------------------------------------------------
-- Address Decoder Component Instance
--
-- This component decodes the specified base address pairs and outputs the
-- specified number of chip enables and the target bus size.
-------------------------------------------------------------------------------
I_DECODER : entity axi_lite_ipif_v3_0_3.address_decoder
    generic map
    (
     C_BUS_AWIDTH          => C_NUM_DECODE_BITS,
     C_S_AXI_MIN_SIZE      => C_S_AXI_MIN_SIZE,
     C_ARD_ADDR_RANGE_ARRAY=> C_ARD_ADDR_RANGE_ARRAY,
     C_ARD_NUM_CE_ARRAY    => C_ARD_NUM_CE_ARRAY,
     C_FAMILY              => "nofamily"
    )
    port map
    (
     Bus_clk               =>  S_AXI_ACLK,
     Bus_rst               =>  S_AXI_ARESETN,
     Address_In_Erly       =>  bus2ip_addr_i(C_ADDR_DECODE_BITS downto 0),
     Address_Valid_Erly    =>  start2,
     Bus_RNW               =>  bus2ip_rnw_i, --S_AXI_ARVALID,
     Bus_RNW_Erly          =>  bus2ip_rnw_i, --S_AXI_ARVALID,
     CS_CE_ld_enable       =>  start2,
     Clear_CS_CE_Reg       =>  temp_i,
     RW_CE_ld_enable       =>  start2,
     CS_for_gaps           =>  open,
      -- Decode output signals
     CS_Out                =>  Bus2IP_CS,
     RdCE_Out              =>  Bus2IP_RdCE,
     WrCE_Out              =>  Bus2IP_WrCE
      );


 -- REGISTERING_RESET_P: Invert the reset coming from AXI
 -----------------------
 REGISTERING_RESET_P : process (S_AXI_ACLK) is
  begin
    if S_AXI_ACLK'event and S_AXI_ACLK = '1' then
     rst <=  not S_AXI_ARESETN;
    end if;
  end process REGISTERING_RESET_P;


 REGISTERING_RESET_P2 : process (S_AXI_ACLK) is
  begin
    if S_AXI_ACLK'event and S_AXI_ACLK = '1' then
     if (rst = '1') then
    --   wrack_1 <= '0';
    --   rdack_1 <= '0';
    --   wrack_2 <= '0';
    --   rdack_2 <= '0';
    --   wr_done2 <= '0';
    --   rd_done2 <= '0';
       bus2ip_rnw_i     <= '0';
       bus2ip_addr_i <= (others => '0');
       start2 <= '0';
     else
    --   wrack_1 <= IP2Bus_WrAck;
    --   rdack_1 <= IP2Bus_RdAck;
    --   wrack_2 <= wrack_1;
    --   rdack_2 <= rdack_1;
    --   wr_done2 <= wr_done1;
    --   rd_done2 <= rd_done1;

       if (state = SM_IDLE and S_AXI_ARVALID='1') then
          bus2ip_addr_i  <= ZEROS & S_AXI_ARADDR(C_ADDR_DECODE_BITS downto 0);
          bus2ip_rnw_i     <= '1';
          start2 <= '1';
       elsif (state = SM_IDLE and (S_AXI_AWVALID = '1' and S_AXI_WVALID = '1')) then
          bus2ip_addr_i  <= ZEROS & S_AXI_AWADDR(C_ADDR_DECODE_BITS downto 0);
          bus2ip_rnw_i     <= '0';
          start2 <= '1';
       else
          bus2ip_rnw_i     <= bus2ip_rnw_i;
          bus2ip_addr_i <= bus2ip_addr_i;
          start2 <= '0';
       end if;
     end if;
    end if;
  end process REGISTERING_RESET_P2;


-------------------------------------------------------------------------------
-- AXI Transaction Controller
-------------------------------------------------------------------------------
-- Access_Control: As per suggestion to optimize the core, the below state machine
--                 is re-coded. Latches are removed from original suggestions
Access_Control : process (S_AXI_ACLK) is
    begin
    if S_AXI_ACLK'event and S_AXI_ACLK = '1' then
    if rst = '1' then
      state <= SM_IDLE;
      is_read <= '0';
      is_write <= '0';
    else
        case state is
          when SM_IDLE => if (S_AXI_ARVALID = '1') then  -- Read precedence over write
				state <= SM_READ;
                                is_read <='1';
                                is_write <= '0';
			  elsif (S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
				state <= SM_WRITE;
                                is_read <='0';
                                is_write <= '1';
			  else
			        state <= SM_IDLE;
                                is_read <='0';
                                is_write <= '0';
			  end if;

          when SM_READ => if rd_done = '1' then
				state <= SM_RESP;
		          else
				state <= SM_READ;
			  end if;

          when SM_WRITE=> if (wr_done = '1') then
		                state <= SM_RESP;
		          else
				state <= SM_WRITE;
			  end if;

          when SM_RESP => if ((s_axi_bvalid_i and S_AXI_BREADY) or
			      (s_axi_rvalid_i and S_AXI_RREADY)) = '1' then
				state <= SM_IDLE;
                                is_read <='0';
                                is_write <= '0';
			  else
				state <= SM_RESP;
			  end if;
	  -- coverage off
	  when others =>  state <= SM_IDLE;
	  -- coverage on
        end case;
    end if;
   end if;
  end process Access_Control;

-------------------------------------------------------------------------------
  -- AXI Transaction Controller signals registered
-------------------------------------------------------------------------------
-- S_AXI_RDATA_RESP_P : BElow process generates the RRESP and RDATA on AXI
-----------------------
S_AXI_RDATA_RESP_P : process (S_AXI_ACLK) is
  begin
    if S_AXI_ACLK'event and S_AXI_ACLK = '1' then
      if (rst = '1') then
      	 s_axi_rresp_i <= (others => '0');
	 s_axi_rdata_i <= (others => '0');
      elsif state = SM_READ then
	s_axi_rresp_i <= (IP2Bus_Error) & '0';
        s_axi_rdata_i <=  IP2Bus_Data;
      end if;
    end if;
end process S_AXI_RDATA_RESP_P;

S_AXI_RRESP <= s_axi_rresp_i;
S_AXI_RDATA <= s_axi_rdata_i;
-----------------------------

-- S_AXI_RVALID_I_P : below process generates the RVALID response on read channel
----------------------
S_AXI_RVALID_I_P : process (S_AXI_ACLK) is
  begin
    if S_AXI_ACLK'event and S_AXI_ACLK = '1' then
      if (rst = '1') then
         s_axi_rvalid_i <= '0';
      elsif ((state = SM_READ) and rd_done = '1') then
         s_axi_rvalid_i <= '1';
      elsif (S_AXI_RREADY = '1') then
         s_axi_rvalid_i <= '0';
      end if;
    end if;
end process S_AXI_RVALID_I_P;

-- -- S_AXI_BRESP_P: Below process provides logic for write response
-- -----------------
S_AXI_BRESP_P : process (S_AXI_ACLK) is
  begin
    if S_AXI_ACLK'event and S_AXI_ACLK = '1' then
      if (rst = '1') then
      	 s_axi_bresp_i <= (others => '0');
      elsif (state = SM_WRITE) then
	 s_axi_bresp_i <= (IP2Bus_Error) & '0';
      end if;
    end if;
end process S_AXI_BRESP_P;

S_AXI_BRESP <= s_axi_bresp_i;
--S_AXI_BVALID_I_P: below process provides logic for valid write response signal
-------------------
S_AXI_BVALID_I_P : process (S_AXI_ACLK) is
  begin
    if S_AXI_ACLK'event and S_AXI_ACLK = '1' then
      if rst = '1' then
         s_axi_bvalid_i <= '0';
      elsif ((state = SM_WRITE) and wr_done = '1') then
         s_axi_bvalid_i <= '1';
      elsif (S_AXI_BREADY = '1') then
         s_axi_bvalid_i <= '0';
      end if;
    end if;
end process S_AXI_BVALID_I_P;
-----------------------------------------------------------------------------

-- INCLUDE_DPHASE_TIMER: Data timeout counter included only when its value is non-zero.
--------------
INCLUDE_DPHASE_TIMER: if C_DPHASE_TIMEOUT /= 0 generate

  constant COUNTER_WIDTH        : integer := clog2((C_DPHASE_TIMEOUT));
  signal dpto_cnt               : std_logic_vector (COUNTER_WIDTH downto 0);
    -- dpto_cnt is one bit wider then COUNTER_WIDTH, which allows the timeout
    -- condition to be captured as a carry into this "extra" bit.
begin

  DPTO_CNT_P : process (S_AXI_ACLK) is
    begin
      if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then
        if ((state = SM_IDLE) or (state = SM_RESP)) then
           dpto_cnt <= (others=>'0');
        else
           dpto_cnt <= dpto_cnt + 1;
        end if;
      end if;
  end process DPTO_CNT_P;

  timeout <= '1' when (dpto_cnt = C_DPHASE_TIMEOUT) else '0';

end generate INCLUDE_DPHASE_TIMER;

EXCLUDE_DPHASE_TIMER: if C_DPHASE_TIMEOUT = 0 generate
  timeout <= '0';
end generate EXCLUDE_DPHASE_TIMER;

-----------------------------------------------------------------------------
S_AXI_BVALID <= s_axi_bvalid_i;
S_AXI_RVALID <= s_axi_rvalid_i;
-----------------------------------------------------------------------------
S_AXI_ARREADY <= rd_done;
S_AXI_AWREADY <= wr_done;
S_AXI_WREADY  <= wr_done;
-------------------------------------------------------------------------------
end imp;
