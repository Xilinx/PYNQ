-------------------------------------------------------------------------------
--  Slave Attachment - entity/architecture pair
-------------------------------------------------------------------------------
--
-- ************************************************************************
-- ** DISCLAIMER OF LIABILITY                                            **
-- **                                                                    **
-- ** This file contains proprietary and confidential information of     **
-- ** Xilinx, Inc. ("Xilinx"), that is distributed under a license       **
-- ** from Xilinx, and may be used, copied and/or disclosed only         **
-- ** pursuant to the terms of a valid license agreement with Xilinx.    **
-- **                                                                    **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION              **
-- ** ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER         **
-- ** EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT                **
-- ** LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,          **
-- ** MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx      **
-- ** does not warrant that functions included in the Materials will     **
-- ** meet the requirements of Licensee, or that the operation of the    **
-- ** Materials will be uninterrupted or error-free, or that defects     **
-- ** in the Materials will be corrected. Furthermore, Xilinx does       **
-- ** not warrant or make any representations regarding use, or the      **
-- ** results of the use, of the Materials in terms of correctness,      **
-- ** accuracy, reliability or otherwise.                                **
-- **                                                                    **
-- ** Xilinx products are not designed or intended to be fail-safe,      **
-- ** or for use in any application requiring fail-safe performance,     **
-- ** such as life-support or safety devices or systems, Class III       **
-- ** medical devices, nuclear facilities, applications related to       **
-- ** the deployment of airbags, or any other applications that could    **
-- ** lead to death, personal injury or severe property or               **
-- ** environmental damage (individually and collectively, "critical     **
-- ** applications"). Customer assumes the sole risk and liability       **
-- ** of any use of Xilinx products in critical applications,            **
-- ** subject only to applicable laws and regulations governing          **
-- ** limitations on product liability.                                  **
-- **                                                                    **
-- ** Copyright 2010 Xilinx, Inc.                                        **
-- ** All rights reserved.                                               **
-- **                                                                    **
-- ** This disclaimer and copyright notice must be retained as part      **
-- ** of this file at all times.                                         **
-- ************************************************************************
-- 
-------------------------------------------------------------------------------
-- Filename:        system_xadc_wiz_0_0_slave_attachment.vhd
-- Version:         v1.01.a
-- Description:     AXI slave attachment supporting single transfers
-------------------------------------------------------------------------------
-- Structure:   This section shows the hierarchical structure of axi_lite_ipif.
--
--              --system_xadc_wiz_0_0_axi_lite_ipif.vhd
--                    --system_xadc_wiz_0_0_slave_attachment.vhd
--                       --system_xadc_wiz_0_0_address_decoder.vhd
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

library work;
use work.system_xadc_wiz_0_0_proc_common_pkg.all;

use work.system_xadc_wiz_0_0_proc_common_pkg.max2;
use work.system_xadc_wiz_0_0_ipif_pkg.all;
use work.system_xadc_wiz_0_0_family_support.all;

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
-- s_axi_aclk            -- AXI Clock
-- S_AXI_ARESET          -- AXI Reset
-- s_axi_awaddr          -- AXI Write address
-- s_axi_awvalid         -- Write address valid
-- s_axi_awready         -- Write address ready
-- s_axi_wdata           -- Write data
-- s_axi_wstrb           -- Write strobes
-- s_axi_wvalid          -- Write valid
-- s_axi_wready          -- Write ready
-- s_axi_bresp           -- Write response
-- s_axi_bvalid          -- Write response valid
-- s_axi_bready          -- Response ready
-- s_axi_araddr          -- Read address
-- s_axi_arvalid         -- Read address valid
-- s_axi_arready         -- Read address ready
-- s_axi_rdata           -- Read data
-- s_axi_rresp           -- Read response
-- s_axi_rvalid          -- Read valid
-- s_axi_rready          -- Read ready
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

entity system_xadc_wiz_0_0_slave_attachment is
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
    s_axi_aclk          : in  std_logic;
    s_axi_aresetn       : in  std_logic;
    s_axi_awaddr        : in  std_logic_vector
                          (C_IPIF_ABUS_WIDTH-1 downto 0);
    s_axi_awvalid       : in  std_logic;
    s_axi_awready       : out std_logic;
    s_axi_wdata         : in  std_logic_vector
                          (C_IPIF_DBUS_WIDTH-1 downto 0);
    s_axi_wstrb         : in  std_logic_vector
                          ((C_IPIF_DBUS_WIDTH/8)-1 downto 0);
    s_axi_wvalid        : in  std_logic;
    s_axi_wready        : out std_logic;
    s_axi_bresp         : out std_logic_vector(1 downto 0);
    s_axi_bvalid        : out std_logic;
    s_axi_bready        : in  std_logic;
    s_axi_araddr        : in  std_logic_vector
                          (C_IPIF_ABUS_WIDTH-1 downto 0);
    s_axi_arvalid       : in  std_logic;
    s_axi_arready       : out std_logic;
    s_axi_rdata         : out std_logic_vector
                          (C_IPIF_DBUS_WIDTH-1 downto 0);
    s_axi_rresp         : out std_logic_vector(1 downto 0);
    s_axi_rvalid        : out std_logic;
    s_axi_rready        : in  std_logic;
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
end entity system_xadc_wiz_0_0_slave_attachment;

-------------------------------------------------------------------------------
architecture imp of system_xadc_wiz_0_0_slave_attachment is

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
-- Intermediate IPIC signals
signal bus2ip_addr_i          : std_logic_vector
                                ((C_IPIF_ABUS_WIDTH-1) downto 0);
signal timeout                : std_logic;

signal rd_done,wr_done        : std_logic;
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
-------------------------------------------------------------------------------
-- begin the architecture logic
-------------------------------------------------------------------------------
begin

-------------------------------------------------------------------------------
-- Address registered
-------------------------------------------------------------------------------
Bus2IP_Clk     <= s_axi_aclk;  
Bus2IP_Resetn  <= s_axi_aresetn;
bus2ip_rnw_i     <= '1' when s_axi_arvalid='1' 
                  else
                  '0';
BUS2IP_RNW     <= bus2ip_rnw_i;
Bus2IP_BE      <= s_axi_wstrb when ((C_USE_WSTRB = 1) and (bus2ip_rnw_i = '0'))
                  else
                  (others => '1');
Bus2IP_Data    <= s_axi_wdata;
Bus2IP_Addr    <= bus2ip_addr_i;

-- For AXI Lite interface, interconnect will duplicate the addresses on both the
-- read and write channel. so onlyone address is used for decoding as well as
-- passing it to IP.
bus2ip_addr_i  <= ZEROS & s_axi_araddr(C_ADDR_DECODE_BITS downto 0) 
                  when (s_axi_arvalid='1')
		  else
                  ZEROS & s_axi_awaddr(C_ADDR_DECODE_BITS downto 0);    

--------------------------------------------------------------------------------
-- start signal will be used to latch the incoming address

start<= (s_axi_arvalid or (s_axi_awvalid and s_axi_wvalid)) 
        when (state = SM_IDLE) 
        else
        '0';

-- x_done signals are used to release the hold from AXI, it will generate "ready"
-- signal on the read and write address channels.

rd_done <= IP2Bus_RdAck or timeout;
wr_done <= IP2Bus_WrAck or timeout;

temp_i  <= rd_done or wr_done;
-------------------------------------------------------------------------------
-- Address Decoder Component Instance
--
-- This component decodes the specified base address pairs and outputs the
-- specified number of chip enables and the target bus size.
-------------------------------------------------------------------------------
I_DECODER : entity work.system_xadc_wiz_0_0_address_decoder
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
     Bus_clk               =>  s_axi_aclk,
     Bus_rst               =>  s_axi_aresetn,
     Address_In_Erly       =>  bus2ip_addr_i(C_ADDR_DECODE_BITS downto 0),
     Address_Valid_Erly    =>  start,
     Bus_RNW               =>  s_axi_arvalid,
     Bus_RNW_Erly          =>  s_axi_arvalid,
     CS_CE_ld_enable       =>  start,
     Clear_CS_CE_Reg       =>  temp_i,
     RW_CE_ld_enable       =>  start,
     CS_for_gaps           =>  open,
      -- Decode output signals
     CS_Out                =>  Bus2IP_CS,
     RdCE_Out              =>  Bus2IP_RdCE,
     WrCE_Out              =>  Bus2IP_WrCE
      );


 -- REGISTERING_RESET_P: Invert the reset coming from AXI
 -----------------------
 REGISTERING_RESET_P : process (s_axi_aclk) is
  begin
    if s_axi_aclk'event and s_axi_aclk = '1' then
     rst <=  not s_axi_aresetn;
    end if;  
  end process REGISTERING_RESET_P;       
      
-------------------------------------------------------------------------------
-- AXI Transaction Controller
-------------------------------------------------------------------------------
-- Access_Control: As per suggestion to optimize the core, the below state machine
--                 is re-coded. Latches are removed from original suggestions
Access_Control : process (s_axi_aclk) is
    begin
    if s_axi_aclk'event and s_axi_aclk = '1' then
    if rst = '1' then
      state <= SM_IDLE;
    else
        case state is
          when SM_IDLE => if (s_axi_arvalid = '1') then  -- Read precedence over write
				state <= SM_READ;
			  elsif (s_axi_awvalid = '1' and s_axi_wvalid = '1') then
				state <= SM_WRITE;
			  else
			        state <= SM_IDLE;
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
            
          when SM_RESP => if ((s_axi_bvalid_i and s_axi_bready) or 
			      (s_axi_rvalid_i and s_axi_rready)) = '1' then
				state <= SM_IDLE;
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
S_AXI_RDATA_RESP_P : process (s_axi_aclk) is
  begin
    if s_axi_aclk'event and s_axi_aclk = '1' then
      if (rst = '1') then
      	 s_axi_rresp_i <= (others => '0');
	 s_axi_rdata_i <= (others => '0');
      elsif state = SM_READ then
	s_axi_rresp_i <= (IP2Bus_Error) & '0';
        s_axi_rdata_i <=  IP2Bus_Data;
      end if;  
    end if;  
end process S_AXI_RDATA_RESP_P;          

s_axi_rresp <= s_axi_rresp_i;
s_axi_rdata <= s_axi_rdata_i;
-----------------------------

-- S_AXI_RVALID_I_P : below process generates the RVALID response on read channel
----------------------
S_AXI_RVALID_I_P : process (s_axi_aclk) is
  begin
    if s_axi_aclk'event and s_axi_aclk = '1' then
      if (rst = '1') then
         s_axi_rvalid_i <= '0';
      elsif ((state = SM_READ) and rd_done = '1') then
         s_axi_rvalid_i <= '1';
      elsif (s_axi_rready = '1') then
         s_axi_rvalid_i <= '0';
      end if; 
    end if;  
end process S_AXI_RVALID_I_P; 

-- -- S_AXI_BRESP_P: Below process provides logic for write response
-- -----------------
S_AXI_BRESP_P : process (s_axi_aclk) is
  begin
    if s_axi_aclk'event and s_axi_aclk = '1' then  
      if (rst = '1') then
      	 s_axi_bresp_i <= (others => '0');
      elsif (state = SM_WRITE) then
	 s_axi_bresp_i <= (IP2Bus_Error) & '0';
      end if; 
    end if;  
end process S_AXI_BRESP_P;      

s_axi_bresp <= s_axi_bresp_i;
--S_AXI_BVALID_I_P: below process provides logic for valid write response signal
-------------------
S_AXI_BVALID_I_P : process (s_axi_aclk) is
  begin
    if s_axi_aclk'event and s_axi_aclk = '1' then
      if rst = '1' then
         s_axi_bvalid_i <= '0';
      elsif ((state = SM_WRITE) and wr_done = '1') then
         s_axi_bvalid_i <= '1';
      elsif (s_axi_bready = '1') then
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

  DPTO_CNT_P : process (s_axi_aclk) is
    begin
      if (s_axi_aclk'event and s_axi_aclk = '1') then
        if ((state = SM_IDLE) or (state = SM_RESP)) then
           dpto_cnt <= (others=>'0');
        else 
           dpto_cnt <= dpto_cnt + 1;    
        end if;
      end if;  
  end process DPTO_CNT_P;

  timeout <= dpto_cnt(COUNTER_WIDTH); 

end generate INCLUDE_DPHASE_TIMER;
 
EXCLUDE_DPHASE_TIMER: if C_DPHASE_TIMEOUT = 0 generate
  timeout <= '0';
end generate EXCLUDE_DPHASE_TIMER;

-----------------------------------------------------------------------------
s_axi_bvalid <= s_axi_bvalid_i;
s_axi_rvalid <= s_axi_rvalid_i;
-----------------------------------------------------------------------------
s_axi_arready <= rd_done;
s_axi_awready <= wr_done;
s_axi_wready  <= wr_done;
-------------------------------------------------------------------------------
end imp;
