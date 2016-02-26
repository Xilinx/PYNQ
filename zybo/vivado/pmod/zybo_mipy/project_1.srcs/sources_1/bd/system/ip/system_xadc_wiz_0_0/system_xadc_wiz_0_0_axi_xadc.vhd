-------------------------------------------------------------------------------
-- system_xadc_wiz_0_0_axi_xadc.vhd - entity/architecture pair
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
-- ** Copyright 2010, 2013 Xilinx, Inc.                                  **
-- ** All rights reserved.                                               **
-- **                                                                    **
-- ** This disclaimer and copyright notice must be retained as part      **
-- ** of this file at all times.                                         **
-- ************************************************************************
-------------------------------------------------------------------------------
-- File          : system_xadc_wiz_0_0_axi_xadc.vhd
-- Version       : v3.0
-- Description   : XADC macro with AXI bus interface 
-- Standard      : VHDL-93
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Structure:
--             axi_xadc.vhd
--               -system_xadc_wiz_0_0_xadc_core_drp.vhd
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

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_arith.conv_std_logic_vector;
    use IEEE.std_logic_arith.unsigned;
    use IEEE.std_logic_arith.all;
    use IEEE.std_logic_misc.and_reduce;
    use IEEE.std_logic_misc.or_reduce;

library work;
    use work.system_xadc_wiz_0_0_ipif_pkg.all;
    use work.system_xadc_wiz_0_0_soft_reset;
    use work.system_xadc_wiz_0_0_ipif_pkg.calc_num_ce;
    use work.system_xadc_wiz_0_0_ipif_pkg.INTEGER_ARRAY_TYPE;
    use work.system_xadc_wiz_0_0_ipif_pkg.SLV64_ARRAY_TYPE;
    use work.system_xadc_wiz_0_0_ipif_pkg.INTR_POS_EDGE_DETECT;
    use work.system_xadc_wiz_0_0_proc_common_pkg.all;


-------------------------------------------------------------------------------
--                     Definition of Generics
--------------------
-- AXI LITE Generics
--------------------
-- C_BASEADDR            -- Base Address
-- C_HIGHADDR            -- high address  
-- C_S_AXI_DATA_WIDTH    -- AXI data bus width
-- C_S_AXI_ADDR_WIDTH    -- AXI address bus width
-- C_FAMILY              -- Target FPGA family, Virtex 6 only
-- C_INCLUDE_INTR        -- inclusion of interrupt 
-- C_SIM_MONITOR_FILE    -- simulation file
-------------------------------------------------------------------------------
--                  Definition of Ports
-------------------------------------------------------------------------------
-- s_axi_aclk            -- AXI Clock
-- s_axi_aresetn          -- AXI Reset
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
-------------------------------------------------------------------------------
-- Note: the unused signals in the port name lists are not listed here.
-------------------------------------------------------------------------------
-- SYSMON EXTERNAL INTERFACE --   INPUT Signals
-------------------------------------------------------------------------------
--    VAUXN           -- Sixteen auxiliary analog input pairs
--    VAUXP           -- low bandwidth differential analog inputs
--    CONVST          -- Conversion start signal for event-driven sampling mode
-------------------------------------------------------------------------------
-- SYSMON EXTERNAL INTERFACE --  OUTPUT Signals
-------------------------------------------------------------------------------
--    ip2intc_irpt    -- Interrupt to processor
--    alarm_out           -- SYSMON alarm output signals of the hard macro
-------------------------------------------------------------------------------

entity system_xadc_wiz_0_0_axi_xadc is
   generic
   (
    -----------------------------------------
--    C_BASEADDR              : std_logic_vector  := X"FFFF_FFFF";
--    C_HIGHADDR              : std_logic_vector  := X"0000_0000";
    -----------------------------------------
    -- AXI slave single block generics
    C_INSTANCE              : string := "system_xadc_wiz_0_0_axi_xadc";
    C_FAMILY                : string                   := "virtex7";
    C_S_AXI_ADDR_WIDTH      : integer range 2 to 32   := 11;
    C_S_AXI_DATA_WIDTH      : integer range 32 to 128  := 32;
    -----------------------------------------
    -- SYSMON Generics
    C_INCLUDE_INTR          : integer range 0 to 1   := 1;
    C_SIM_MONITOR_FILE      : string                 := "design.txt"
   );
   port
   (
    -- System interface
    s_axi_aclk      : in  std_logic;                                      
    s_axi_aresetn   : in  std_logic;                                      
    -- AXI Write address channel signals                                        
    s_axi_awaddr    : in  std_logic_vector((C_S_AXI_ADDR_WIDTH-1) downto 0);                  
    s_axi_awvalid   : in  std_logic;                                      
    s_axi_awready   : out std_logic;                                      
    -- AXI Write data channel signals                                           
    s_axi_wdata     : in  std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0);                  
    s_axi_wstrb     : in  std_logic_vector(((C_S_AXI_DATA_WIDTH/8)-1) downto 0);              
    s_axi_wvalid    : in  std_logic;                                      
    s_axi_wready    : out std_logic;                                      
    -- AXI Write response channel signals                                       
    s_axi_bresp     : out std_logic_vector(1 downto 0);                   
    s_axi_bvalid    : out std_logic;                                      
    s_axi_bready    : in  std_logic;                                      
    -- AXI Read address channel signals                                         
    s_axi_araddr    : in  std_logic_vector((C_S_AXI_ADDR_WIDTH-1) downto 0);                  
    s_axi_arvalid   : in  std_logic;                                      
    s_axi_arready   : out std_logic;                                      
    -- AXI Read address channel signals                                         
    s_axi_rdata     : out std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0);                  
    s_axi_rresp     : out std_logic_vector(1 downto 0);                   
    s_axi_rvalid    : out std_logic;                                      
    s_axi_rready    : in  std_logic;                                      
                                                                                
   -- Input to the system from the axi_xadc core
    ip2intc_irpt    : out std_logic;
   -- XADC External interface signals

    -- Conversion start control signal for Event driven mode
    vauxp6          : in  STD_LOGIC;                         -- Auxiliary Channel 6
    vauxn6          : in  STD_LOGIC;
    vauxp7          : in  STD_LOGIC;                         -- Auxiliary Channel 7
    vauxn7          : in  STD_LOGIC;
    vauxp14         : in  STD_LOGIC;                         -- Auxiliary Channel 14
    vauxn14         : in  STD_LOGIC;
    vauxp15         : in  STD_LOGIC;                         -- Auxiliary Channel 15
    vauxn15         : in  STD_LOGIC;
    busy_out        : out  STD_LOGIC;                        -- ADC Busy signal
    channel_out     : out  STD_LOGIC_VECTOR (4 downto 0);    -- Channel Selection Outputs
    eoc_out         : out  STD_LOGIC;                        -- End of Conversion Signal
    eos_out         : out  STD_LOGIC;                        -- End of Sequence Signal
    alarm_out       : out STD_LOGIC_VECTOR (7 downto 0);                         -- OR'ed output of all the Alarms
    vp_in           : in  STD_LOGIC;                         -- Dedicated Analog Input Pair
    vn_in           : in  STD_LOGIC
  );   

-------------------------------------------------------------------------------
-- Attributes
-------------------------------------------------------------------------------

   -- Fan-Out attributes for XST

   ATTRIBUTE MAX_FANOUT                    : string;
   ATTRIBUTE MAX_FANOUT   of s_axi_aclk    : signal is "10000";
   ATTRIBUTE MAX_FANOUT   of s_axi_aresetn : signal is "10000";

   -----------------------------------------------------------------
   -- Start of PSFUtil MPD attributes
   -----------------------------------------------------------------
   ATTRIBUTE HDL                        : string;
   ATTRIBUTE HDL of system_xadc_wiz_0_0_axi_xadc      : entity is "VHDL";

   ATTRIBUTE IPTYPE                     : string;
   ATTRIBUTE IPTYPE of system_xadc_wiz_0_0_axi_xadc   : entity is "PERIPHERAL";

   ATTRIBUTE IP_GROUP                   : string;
   ATTRIBUTE IP_GROUP of system_xadc_wiz_0_0_axi_xadc : entity is  "LOGICORE";

   ATTRIBUTE SIGIS                      : string;
   ATTRIBUTE SIGIS of s_axi_aclk        : signal is "Clk";
   ATTRIBUTE SIGIS of s_axi_aresetn     : signal is "Rst";
   ATTRIBUTE SIGIS of ip2intc_irpt      : signal is "INTR_LEVEL_HIGH";

   -----------------------------------------------------------------
   -- end of PSFUtil MPD attributes
   -----------------------------------------------------------------
end entity system_xadc_wiz_0_0_axi_xadc;
-------------------------------------------------------------------------------
-- Architecture Section
-------------------------------------------------------------------------------

architecture imp of system_xadc_wiz_0_0_axi_xadc is

component system_xadc_wiz_0_0_xadc_core_drp 
   generic
   (
      ----------------
      C_S_AXI_ADDR_WIDTH     : integer;
      C_S_AXI_DATA_WIDTH     : integer;
      C_FAMILY               : string;
      ----------------
      CE_NUMBERS             : integer;
      IP_INTR_NUM            : integer;
      C_SIM_MONITOR_FILE     : string ;
      ----------------
      MUX_ADDR_NO            : integer 
   );
   port
   (
      -- IP Interconnect (IPIC) port signals ---------
     Bus2IP_Clk             : in  std_logic;
     Bus2IP_Rst             : in  std_logic;
     -- Bus 2 IP IPIC interface
     Bus2IP_RdCE            : in std_logic_vector(0 to CE_NUMBERS-1);
     Bus2IP_WrCE            : in std_logic_vector(0 to CE_NUMBERS-1);
     Bus2IP_Addr            : in std_logic_vector(0 to (C_S_AXI_ADDR_WIDTH-1));
     Bus2IP_Data            : in std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));
     -- IP 2 Bus IPIC interface
     Sysmon_IP2Bus_Data     : out std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));
     Sysmon_IP2Bus_WrAck    : out std_logic;
     Sysmon_IP2Bus_RdAck    : out std_logic;
     ---------------- interrupt interface with the system  -----------
     Interrupt_status       : out std_logic_vector(0 to IP_INTR_NUM-1);
     ----------------  sysmon macro interface  -------------------
     vauxp6                 : in  STD_LOGIC;                         -- Auxiliary Channel 6
     vauxn6                 : in  STD_LOGIC;
     vauxp7                 : in  STD_LOGIC;                         -- Auxiliary Channel 7
     vauxn7                 : in  STD_LOGIC;
     vauxp14                : in  STD_LOGIC;                         -- Auxiliary Channel 14
     vauxn14                : in  STD_LOGIC;
     vauxp15                : in  STD_LOGIC;                         -- Auxiliary Channel 15
     vauxn15                : in  STD_LOGIC;
     busy_out               : out  STD_LOGIC;                        -- ADC Busy signal
     channel_out            : out  STD_LOGIC_VECTOR (4 downto 0);    -- Channel Selection Outputs
     eoc_out                : out  STD_LOGIC;                        -- End of Conversion Signal
     eos_out                : out  STD_LOGIC;                        -- End of Sequence Signal
     alarm_out              : out STD_LOGIC_VECTOR (7 downto 0);                   
     vp_in                  : in  STD_LOGIC;                         -- Dedicated Analog Input Pair
     vn_in                  : in  STD_LOGIC
   );

end component;

-------------------------------------------------------------------------------
-- Function Declarations starts
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Function: add_intr_ard_addr_range_array
-------------------------------------------------------------------------------
-- Add the interrupt base and high address to ARD_ADDR_RANGE_ARRAY, if
-- C_INCLUDE_INTR is = 1
-------------------------------------------------------------------------------
function add_intr_ard_addr_range_array
                           (include_intr         : integer;
			    USER_ARD_ADDR_RANGE_ARRAY       : SLV64_ARRAY_TYPE;    
			    INTR_USER_ARD_ADDR_RANGE_ARRAY  : SLV64_ARRAY_TYPE
			    )
                            return SLV64_ARRAY_TYPE is
  begin
    if include_intr = 1  then
  return INTR_USER_ARD_ADDR_RANGE_ARRAY;
    else
  return USER_ARD_ADDR_RANGE_ARRAY;
    end if;
end function add_intr_ard_addr_range_array;

-------------------------------------------------------------------------------
-- Function: add_intr_ce_range_array
-------------------------------------------------------------------------------
-- This function is used to add the 16 interrupts in the NUM_CE range array, if
-- C_INCLUDE_INTR is = 1
-------------------------------------------------------------------------------
function add_intr_ce_range_array
                           (include_intr           : integer;
			    USER_ARD_NUM_CE_ARRAY  : INTEGER_ARRAY_TYPE;
			    INTR_USER_ARD_NUM_CE_ARRAY  : INTEGER_ARRAY_TYPE
			    )
                            return INTEGER_ARRAY_TYPE is
  begin
    if include_intr = 1 then
       return INTR_USER_ARD_NUM_CE_ARRAY;
    else
       return USER_ARD_NUM_CE_ARRAY;
    end if;
end function add_intr_ce_range_array;
-------------------------------------------------------------------------------
-- Function Declaration ends
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Type Declaration
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Constant Declaration Starts
-------------------------------------------------------------------------------
 -- AXI lite parameters

constant    C_BASEADDR              : std_logic_vector  := X"0000_0000";
--constant    C_BASEADDR              : std_logic_vector  := X"FFFF_FFFF";
constant    C_HIGHADDR              : std_logic_vector  := X"0000_0000";
constant C_S_AXI_SYSMON_MIN_SIZE  : std_logic_vector(31 downto 0):= X"000003FF";
constant C_USE_WSTRB              : integer := 1;
constant C_DPHASE_TIMEOUT         : integer := 64;

--constant ZERO_ADDR_PAD   : std_logic_vector(0 to 64-C_S_AXI_ADDR_WIDTH-1)
--                         := (others => '0');
constant ZERO_ADDR_PAD   : std_logic_vector(0 to 64-32-1) := (others => '0');

constant INTERRUPT_NO    : natural  := 17; -- changed from 10 to 17 for adding
                                           -- falling edge interrupts
constant C_INTR_CE_NUM   : integer  := 16; -- this is fixed for interrupt controller

constant MUX_ADDR_NO     : integer := 5;   -- added for XADC

-------------------------------------------------------------------------------
-- The local register array contains
-- 1. Software Reset Register (SRR),            -- address C_BASEADDR + 0x00
-- 2. Status Register (SR),                     -- address C_BASEADDR + 0x04
-- 3. Alarm Output Status Register (AOSR),      -- address C_BASEADDR + 0x08
-- 4. CONVST Register (CONVSTR),                -- address C_BASEADDR + 0x0C
-- 5. SYSMON Reset Register (SYSMONRR).         -- address C_BASEADDR + 0x10
-- All registers are 32 bit width and their addresses are at word boundry.
-------------------------------------------------------------------------------
constant LOCAL_REG_BASEADDR : std_logic_vector  := C_BASEADDR or X"00000000";
constant LOCAL_REG_HIGHADDR : std_logic_vector  := C_BASEADDR or X"0000001F";
-------------------------------------------------------------------------------
-- The interrupt registers to be added if C_INCLUDE_INTR = 1
-------------------------------------------------------------------------------
constant INTR_BASEADDR      : std_logic_vector  := C_BASEADDR or X"00000040";
constant INTR_HIGHADDR      : std_logic_vector  := C_BASEADDR or x"0000007F";
-------------------------------------------------------------------------------
-- The address range is devided in the range of Status & Control registers
-- there are total 128 registers. First 64 are the status and remaning 64 are
-- control registers
-------------------------------------------------------------------------------
constant REG_FILE_BASEADDR  : std_logic_vector  := C_BASEADDR or X"00000200";
constant REG_FILE_HIGHADDR  : std_logic_vector  := C_BASEADDR or X"000003FF";
-------------------------------------------------------------------------------
--The address ranges for the registers are defined in USER_ARD_ADDR_RANGE_ARRAY
-------------------------------------------------------------------------------
constant USER_ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE :=
         (
          ZERO_ADDR_PAD & LOCAL_REG_BASEADDR,
          ZERO_ADDR_PAD & LOCAL_REG_HIGHADDR,

          ZERO_ADDR_PAD & REG_FILE_BASEADDR,
          ZERO_ADDR_PAD & REG_FILE_HIGHADDR
          );

constant INTR_USER_ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE :=
         (
          ZERO_ADDR_PAD & LOCAL_REG_BASEADDR,
          ZERO_ADDR_PAD & LOCAL_REG_HIGHADDR,

          ZERO_ADDR_PAD & INTR_BASEADDR,
          ZERO_ADDR_PAD & INTR_HIGHADDR,

          ZERO_ADDR_PAD & REG_FILE_BASEADDR,
          ZERO_ADDR_PAD & REG_FILE_HIGHADDR
          );
-------------------------------------------------------------------------------
-- The USER_ARD_ADDR_RANGE_ARRAY is subset of ARD_ADDR_RANGE_ARRAY based on the
-- C_INCLUDE_INTR parameter value.
-------------------------------------------------------------------------------
constant ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE  :=
         add_intr_ard_addr_range_array(
                                       C_INCLUDE_INTR,
                                       USER_ARD_ADDR_RANGE_ARRAY,
				       INTR_USER_ARD_ADDR_RANGE_ARRAY
                                      );
-------------------------------------------------------------------------------
--The total 128 DRP register address space is divided in two 64 register arrays
--The status and control registers are equally divided in the range to generate
--the chip enable signals.
--There are some local alarm registers, conversion start registers, ip reset
--registers present in the design.
--the no. of CE's required is defined in USER_ARD_NUM_CE_ARRAY array
-------------------------------------------------------------------------------
constant USER_ARD_NUM_CE_ARRAY : INTEGER_ARRAY_TYPE :=
         (
          0 => 8,   -- 5 chip enable + 3 dummy
                    --  CS_0 & CE_0 => SRR                    -- Addr = 00
                    --  CS_0 & CE_1 => SR                     -- Addr = 04
                    --  CS_0 & CE_2 => AOSR                   -- Addr = 08
                    --  CS_0 & CE_3 => CONVSTR                -- Addr = 0C
                    --  CS_0 & CE_4 => SYSMONRR               -- Addr = 10
		    --  CS_0 & CE_5 => dummy                  -- Addr = 14
		    --  CS_0 & CE_6 => dummy                  -- Addr = 18
		    --  CS_0 & CE_7 => dummy		      -- Addr = 1C
          1 => 1--, -- 1 chip enable
                    --  CS_1 & CE_8 => 1 CE required to access DRP
          );

constant INTR_USER_ARD_NUM_CE_ARRAY : INTEGER_ARRAY_TYPE :=
         (
          0 => 8, -- 5 chip enable + 3 dummy
                    --  CS_0 & CE_0 => SRR                    -- Addr = 00
                    --  CS_0 & CE_1 => SR                     -- Addr = 04
                    --  CS_0 & CE_2 => AOSR                   -- Addr = 08
                    --  CS_0 & CE_3 => CONVSTR                -- Addr = 0C
                    --  CS_0 & CE_4 => SYSMONRR               -- Addr = 10
		    --  CS_0 & CE_5 => dummy                  -- Addr = 14
		    --  CS_0 & CE_6 => dummy                  -- Addr = 18
		    --  CS_0 & CE_7 => dummy		      -- Addr = 1C
          1 => 16,  -- 16 chip enable
                    --  CS_1 & CE_15 => GIER                -- Addr = 5C
                    --  CS_1 & CE_16 => IPISR               -- Addr = 60
                    --  CS_1 & CE_18 => IPIER               -- Addr = 68
                    
   -- Following commented code is for reference with execution of above function
          2 => 1    -- 1 chip enable			   -- addr = 200 to 3FF
		    --  CS_2 & CE_24 => 1 CE required to access DRP
          );

-------------------------------------------------------------------------------
-- The USER_ARD_NUM_CE_ARRAY is subset of ARD_NUM_CE_ARRAY based on the
-- C_INCLUDE_INTR parameter value.
-------------------------------------------------------------------------------
constant ARD_NUM_CE_ARRAY : INTEGER_ARRAY_TYPE  :=
         add_intr_ce_range_array(
                                 C_INCLUDE_INTR,
                                 USER_ARD_NUM_CE_ARRAY,
				 INTR_USER_ARD_NUM_CE_ARRAY
                                 );
-------------------------------------------------------------------------------
-- Eight interrupts
-------------------------------------------------------------------------------
constant IP_INTR_MODE_ARRAY : INTEGER_ARRAY_TYPE(0 to INTERRUPT_NO-1):=
         (
          others => INTR_POS_EDGE_DETECT

         );
-------------------------------------------------------------------------------
-- Calculating index for interrupt logic
-------------------------------------------------------------------------------
constant SWRESET                : natural := 0;


constant INTR_LO                : natural := 0; 
constant INTR_HI                : natural := 15;


constant CS_NUMBERS             : integer :=((ARD_ADDR_RANGE_ARRAY'LENGTH/2));
constant RD_CE_NUMBERS          : integer :=(calc_num_ce(ARD_NUM_CE_ARRAY));
constant WR_CE_NUMBERS          : integer :=(calc_num_ce(ARD_NUM_CE_ARRAY));
constant IP_INTR_MODE_ARRAY_NUM : integer := IP_INTR_MODE_ARRAY'length;

constant RDCE_WRCE_SYSMON_CORE  : integer := 9;
--------------------------------------------------------------------------------
-- Constant Declaration Ends
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Signal and Type Declarations
--------------------------------------------------------------------------------
--bus2ip signals
signal bus2ip_clk       : std_logic;
signal bus2ip_reset     : std_logic;
---
signal bus2ip_rdce      : std_logic_vector((RD_CE_NUMBERS-1)downto 0);
signal bus2ip_rdce_int  : std_logic_vector(0 to (RD_CE_NUMBERS-1));
signal bus2ip_rdce_xadc_core : std_logic_vector(0 to (RDCE_WRCE_SYSMON_CORE-1));
---
signal bus2ip_wrce      : std_logic_vector((WR_CE_NUMBERS-1)downto 0);
signal bus2ip_wrce_int  : std_logic_vector(0 to (WR_CE_NUMBERS-1));
signal bus2ip_wrce_xadc_core : std_logic_vector(0 to (RDCE_WRCE_SYSMON_CORE-1));
---
signal bus2ip_addr      : std_logic_vector((C_S_AXI_ADDR_WIDTH-1)downto 0);
signal bus2ip_addr_int  : std_logic_vector(0 to (C_S_AXI_ADDR_WIDTH-1));
---
signal bus2ip_be        : std_logic_vector(((C_S_AXI_DATA_WIDTH/8)-1)downto 0);
signal bus2ip_be_int    : std_logic_vector(0 to (C_S_AXI_DATA_WIDTH/8)-1);
---
signal bus2ip_data      : std_logic_vector(((C_S_AXI_DATA_WIDTH)-1)downto 0);
signal bus2ip_data_int  : std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));
-- ip2bus signals
signal ip2bus_data      : std_logic_vector((C_S_AXI_DATA_WIDTH-1)downto 0)
                          := (others => '0');
signal ip2bus_data_int  : std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));
signal ip2bus_data_int1  : std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));
---

signal ip2bus_wrack     : std_logic;
signal ip2bus_rdack     : std_logic;
signal ip2bus_error     : std_logic;

signal ip2bus_wrack_int1     : std_logic;
signal ip2bus_rdack_int1     : std_logic;
signal ip2bus_error_int1     : std_logic;

signal xadc_ip2bus_data   : std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));
signal xadc_ip2bus_wrack  : std_logic;
signal xadc_ip2bus_rdack  : std_logic;
-- signal xadc_ip2bus_error  : std_logic;
signal interrupt_status_i   : std_logic_vector(0 to (IP_INTR_MODE_ARRAY_NUM-1));

signal intr_ip2bus_data  : std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));
signal intr_ip2bus_wrack : std_logic;
signal intr_ip2bus_rdack : std_logic;
signal intr_ip2bus_error : std_logic;

-- Software Reset Signals
signal reset2ip_reset      : std_logic := '0';
signal rst_ip2bus_wrack    : std_logic;
signal rst_ip2bus_error    : std_logic;
signal rst_ip2bus_rdack    : std_logic;
signal rst_ip2bus_rdack_d1 : std_logic;

-- following signals are used to impleemnt the register access rule
signal and_reduce_be : std_logic;
signal partial_reg_access_error : std_logic;

signal bus2ip_reset_active_low : std_logic;

signal bus2ip_reset_active_high: std_logic;
--------------------------------------------
signal dummy_local_reg_rdack_d1 : std_logic;
signal dummy_local_reg_rdack    : std_logic;
signal dummy_local_reg_wrack_d1 : std_logic;
signal dummy_local_reg_wrack    : std_logic;

signal bus2ip_rdce_intr : std_logic_vector(INTR_LO to INTR_HI);
signal bus2ip_wrce_intr : std_logic_vector(INTR_LO to INTR_HI);

-------------------------------------------------------------------------------
-- Architecture begins
-------------------------------------------------------------------------------
begin
--------------------------------------------
-- INSTANTIATE AXI SLAVE SINGLE
--------------------------------------------
AXI_LITE_IPIF_I : entity work.system_xadc_wiz_0_0_axi_lite_ipif
  generic map
   (
    C_S_AXI_ADDR_WIDTH        => C_S_AXI_ADDR_WIDTH,
    C_S_AXI_DATA_WIDTH        => C_S_AXI_DATA_WIDTH,

    C_S_AXI_MIN_SIZE          => C_S_AXI_SYSMON_MIN_SIZE,
    C_USE_WSTRB               => C_USE_WSTRB,
    C_DPHASE_TIMEOUT          => C_DPHASE_TIMEOUT,

    C_ARD_ADDR_RANGE_ARRAY    => ARD_ADDR_RANGE_ARRAY,
    C_ARD_NUM_CE_ARRAY        => ARD_NUM_CE_ARRAY,
    C_FAMILY                  => C_FAMILY
   )
 port map
   (
    s_axi_aclk                => s_axi_aclk,           -- in
    s_axi_aresetn             => s_axi_aresetn,        -- in

    s_axi_awaddr              => s_axi_awaddr,         -- in
    s_axi_awvalid             => s_axi_awvalid,        -- in
    s_axi_awready             => s_axi_awready,        -- out
    s_axi_wdata               => s_axi_wdata,          -- in
    s_axi_wstrb               => s_axi_wstrb,          -- in
    s_axi_wvalid              => s_axi_wvalid,         -- in
    s_axi_wready              => s_axi_wready,         -- out
    s_axi_bresp               => s_axi_bresp,          -- out
    s_axi_bvalid              => s_axi_bvalid,         -- out
    s_axi_bready              => s_axi_bready,         -- in
    
    s_axi_araddr              => s_axi_araddr,         -- in
    s_axi_arvalid             => s_axi_arvalid,        -- in
    s_axi_arready             => s_axi_arready,        -- out
    s_axi_rdata               => s_axi_rdata,          -- out
    s_axi_rresp               => s_axi_rresp,          -- out
    s_axi_rvalid              => s_axi_rvalid,         -- out
    s_axi_rready              => s_axi_rready,         -- in

 -- IP Interconnect (IPIC) port signals
    Bus2IP_Clk                => bus2ip_clk,           -- out
    Bus2IP_Resetn             => bus2ip_reset_active_low,     -- out

    Bus2IP_Addr               => bus2ip_addr,          -- out
    Bus2IP_RNW                => open,                 -- out
    Bus2IP_BE                 => bus2ip_be,            -- out
    Bus2IP_CS                 => open,                -- out
    Bus2IP_RdCE               => bus2ip_rdce,          -- out
    Bus2IP_WrCE               => bus2ip_wrce,          -- out
    Bus2IP_Data               => bus2ip_data,          -- out

    IP2Bus_Data               => ip2bus_data,          -- in
    IP2Bus_WrAck              => ip2bus_wrack,         -- in
    IP2Bus_RdAck              => ip2bus_rdack,         -- in
    IP2Bus_Error              => ip2bus_error          -- in
   );
-------------------------------------------------------------------------------

-------------------------------
bus2ip_rdce_int <= bus2ip_rdce;
-------------------------------
bus2ip_wrce_int	<= bus2ip_wrce;
-------------------------------
ip2bus_data     <= ip2bus_data_int;
-------------------------------
----------------------
--REG_RESET_FROM_IPIF: convert active low to active hig reset to rest of
--                     the core.
----------------------
REG_RESET_FROM_IPIF: process (s_axi_aclk) is
begin
     if(s_axi_aclk'event and s_axi_aclk = '1') then
         bus2ip_reset_active_high <= not(bus2ip_reset_active_low);
     end if;
end process REG_RESET_FROM_IPIF;
----------------------

-------------------------------------------------------------------------------
-------------------- when interrupt is used.
RDCE_WRCE_GEN_I: if (C_INCLUDE_INTR = 1) generate
-----------------
--------
begin
--------

  bus2ip_rdce_intr <= bus2ip_rdce_int -- (25-16=8) to (25-2=23)
                   (((RD_CE_NUMBERS-C_INTR_CE_NUM)-1)to (RD_CE_NUMBERS-2));
  bus2ip_wrce_intr <= bus2ip_wrce_int -- (25-16=8) to (25-2=23)
                   (((WR_CE_NUMBERS-C_INTR_CE_NUM)-1)to (WR_CE_NUMBERS-2));

  bus2ip_rdce_xadc_core <= bus2ip_rdce_int -- 0 to ((25-16=8)-2)=7
                             ((RD_CE_NUMBERS-RD_CE_NUMBERS)to 
		              ((RD_CE_NUMBERS-C_INTR_CE_NUM)-2)
		             ) 
			     &		     -- 24 = last rdce
			     bus2ip_rdce_int(RD_CE_NUMBERS-1);

  bus2ip_wrce_xadc_core <= bus2ip_wrce_int -- 0 to ((25-16=8)-1)=7
                             ((WR_CE_NUMBERS-WR_CE_NUMBERS)to 
		              ((WR_CE_NUMBERS-C_INTR_CE_NUM)-2)
		             ) 
			     &		     -- 24 = last wrce
			     bus2ip_wrce_int(WR_CE_NUMBERS-1);
end generate RDCE_WRCE_GEN_I;
-----------------------------
-------------------------------------------------------------------------------
-------------------- when interrupt is NOT used.
RDCE_WRCE_NOT_GEN_I: if (C_INCLUDE_INTR = 0) generate
-----------------
--------
begin
--------

  bus2ip_rdce_xadc_core <= bus2ip_rdce_int;
  bus2ip_wrce_xadc_core <= bus2ip_wrce_int;

end generate RDCE_WRCE_NOT_GEN_I;
---------------------------------
-------------------------------------------------------------------------------

--------------------------------------------
-- XADC_CORE_I: INSTANTIATE XADC CORE
--------------------------------------------

AXI_XADC_CORE_I : system_xadc_wiz_0_0_xadc_core_drp
   generic map
   (
   ----------------              -------------------------
   C_S_AXI_ADDR_WIDTH            => C_S_AXI_ADDR_WIDTH,
   C_S_AXI_DATA_WIDTH            => C_S_AXI_DATA_WIDTH,
   C_FAMILY                      => C_FAMILY,
   ----------------              -------------------------
   CE_NUMBERS                    => RDCE_WRCE_SYSMON_CORE,
   IP_INTR_NUM                   => IP_INTR_MODE_ARRAY_NUM,
   C_SIM_MONITOR_FILE            => C_SIM_MONITOR_FILE,
   ------------------            -------------------------
   MUX_ADDR_NO                   => MUX_ADDR_NO
   )
   port map
   (
    -- IP Interconnect (IPIC) port signals ---------
    Bus2IP_Clk                   => bus2ip_clk,
    Bus2IP_Rst                   => reset2ip_reset,
    Bus2IP_RdCE                  => bus2ip_rdce_xadc_core,
    Bus2IP_WrCE                  => bus2ip_wrce_xadc_core,
    Bus2IP_Addr                  => bus2ip_addr,
    Bus2IP_Data                  => bus2ip_data,       
    -- ip2bus signals ------------------------------
    Sysmon_IP2Bus_Data           => xadc_ip2bus_data,
    Sysmon_IP2Bus_WrAck          => xadc_ip2bus_wrack,
    Sysmon_IP2Bus_RdAck          => xadc_ip2bus_rdack,
    Interrupt_status             => interrupt_status_i,
    --- external interface signals ------------------
    vauxp6                       => vauxp6,
    vauxn6                       => vauxn6,
    vauxp7                       => vauxp7,
    vauxn7                       => vauxn7,
    vauxp14                      => vauxp14,
    vauxn14                      => vauxn14,
    vauxp15                      => vauxp15,
    vauxn15                      => vauxn15,
    busy_out                     => busy_out,
    channel_out                  => channel_out,
    eoc_out                      => eoc_out,
    eos_out                      => eos_out,
    alarm_out                    => alarm_out,
    vp_in                        => vp_in,
    vn_in                        => vn_in
   );

----------------------------------------------------------
-- SOFT_RESET_I: INSTANTIATE SOFTWARE RESET REGISTER (SRR)
----------------------------------------------------------
SOFT_RESET_I: entity work.system_xadc_wiz_0_0_soft_reset
   generic map
   (
    C_SIPIF_DWIDTH               => C_S_AXI_DATA_WIDTH,
    -- Width of triggered reset in Bus Clocks
    C_RESET_WIDTH                => 16
   )
   port map
   (
    -- Inputs From the AXI Slave Single Bus
    Bus2IP_Reset                 => bus2ip_reset_active_high,  -- in
    Bus2IP_Clk                   => bus2ip_clk,                -- in
    Bus2IP_WrCE                  => bus2ip_wrce_int(SWRESET),  -- in
    Bus2IP_Data                  => bus2ip_data,         -- in
    Bus2IP_BE                    => bus2ip_be,           -- in
    -- Final Device Reset Output
    Reset2IP_Reset               => reset2ip_reset,      -- out
    -- Status Reply Outputs to the Bus
    Reset2Bus_WrAck              => rst_ip2bus_wrack,    -- out
    Reset2Bus_Error              => rst_ip2bus_error,    -- out
    Reset2Bus_ToutSup            => open                 -- out
   );

------------------------------------------------------------
-- INSTANTIATE INTERRUPT CONTROLLER MODULE (IPISR,IPIER,GIER)
------------------------------------------------------------
-- INTR_CTRLR_GEN_I: Generate logic to be used to pass signals,
-------------------- when interrupt is used.
INTR_CTRLR_GEN_I: if (C_INCLUDE_INTR = 1) generate
-----------------
   --------
   signal bus2ip_rdce_intr_int : std_logic_vector(INTR_LO to INTR_HI);
   signal bus2ip_wrce_intr_int : std_logic_vector(INTR_LO to INTR_HI);

   signal dummy_bus2ip_rdce_intr : std_logic;
   signal dummy_bus2ip_wrce_intr : std_logic;
   signal dummy_intr_reg_rdack_d1: std_logic;
   signal dummy_intr_reg_rdack   : std_logic;
   signal dummy_intr_reg_wrack_d1: std_logic;
   signal dummy_intr_reg_wrack   : std_logic;


--------
begin
--------

bus2ip_rdce_intr_int <= "0000000"                  &
                        bus2ip_rdce_intr(7 to 8)   &
    		        "0"                        &
		        bus2ip_rdce_intr(10)       &
		        "00000";

		    
bus2ip_wrce_intr_int <= "0000000"                  &
                        bus2ip_wrce_intr(7 to 8)   &
		        "0"                        &
		        bus2ip_wrce_intr(10)       &
		        "00000";

dummy_bus2ip_rdce_intr <= or_reduce(bus2ip_rdce_intr(0 to 6))  or
	                            bus2ip_rdce_intr(9)        or
			  or_reduce(bus2ip_rdce_intr(11 to 15));

dummy_bus2ip_wrce_intr <= or_reduce(bus2ip_wrce_intr(0 to 6)) or
	                            bus2ip_wrce_intr(9)       or
			  or_reduce(bus2ip_wrce_intr(11 to 15));
			  
---------------------------------------------
DUMMY_INTR_RD_WR_ACK_GEN_PROCESS:process(Bus2IP_Clk) is
begin
  if (bus2ip_clk'event and bus2ip_clk = '1') then
    if (reset2ip_reset = RESET_ACTIVE) then
        dummy_intr_reg_rdack_d1 <= '0';
        dummy_intr_reg_rdack    <= '0';
	dummy_intr_reg_wrack_d1 <= '0'; 
	dummy_intr_reg_wrack    <= '0'; 
    else
        dummy_intr_reg_rdack_d1 <= dummy_bus2ip_rdce_intr;
        dummy_intr_reg_rdack    <= dummy_bus2ip_rdce_intr and
                                   (not dummy_intr_reg_rdack_d1);

        dummy_intr_reg_wrack_d1 <= dummy_bus2ip_wrce_intr;
        dummy_intr_reg_wrack    <= dummy_bus2ip_wrce_intr and
                                   (not dummy_intr_reg_wrack_d1);

    end if;
  end if;
end process DUMMY_INTR_RD_WR_ACK_GEN_PROCESS;
---------------------------------------------

  INTERRUPT_CONTROL_I: entity work.system_xadc_wiz_0_0_interrupt_control
      generic map
      (
       C_NUM_CE                     => C_INTR_CE_NUM,
       C_NUM_IPIF_IRPT_SRC          =>  1,  -- Set to 1 to avoid null array
       C_IP_INTR_MODE_ARRAY         => IP_INTR_MODE_ARRAY,
       -- Specifies device Priority Encoder function
       C_INCLUDE_DEV_PENCODER       => FALSE,
       -- Specifies device ISC hierarchy
       C_INCLUDE_DEV_ISC            => FALSE,
       C_IPIF_DWIDTH                => C_S_AXI_DATA_WIDTH
      )
      port map
      (
       Bus2IP_Clk                   =>  Bus2IP_Clk,
       Bus2IP_Reset                 =>  reset2ip_reset,
       
       Bus2IP_Data                  =>  bus2ip_data,
       Bus2IP_BE                    =>  bus2ip_be,  
       Interrupt_RdCE               =>  bus2ip_rdce_intr_int,
       Interrupt_WrCE               =>  bus2ip_wrce_intr_int,
       IPIF_Reg_Interrupts          =>  "00", -- Tie off the unused reg intr's
       IPIF_Lvl_Interrupts          =>  "0",  -- Tie off the dummy lvl intr
       IP2Bus_IntrEvent             =>  interrupt_status_i,
       Intr2Bus_DevIntr             =>  ip2intc_irpt,
       Intr2Bus_DBus                =>  intr_ip2bus_data,
       Intr2Bus_WrAck               =>  intr_ip2bus_wrack,
       Intr2Bus_RdAck               =>  intr_ip2bus_rdack,
       Intr2Bus_Error               =>  intr_ip2bus_error,
       Intr2Bus_Retry               =>  open,
       Intr2Bus_ToutSup             =>  open
      );

  ip2bus_wrack_int1  <= xadc_ip2bus_wrack  or 
                   rst_ip2bus_wrack     or 
		   intr_ip2bus_wrack    or
		   dummy_intr_reg_wrack or
		   dummy_local_reg_wrack;

  ip2bus_rdack_int1  <= xadc_ip2bus_rdack  or 
                   rst_ip2bus_rdack     or 
		   intr_ip2bus_rdack    or
		   dummy_intr_reg_rdack or
		   dummy_local_reg_rdack;

  ip2bus_error_int1  <= rst_ip2bus_error     or 
                   intr_ip2bus_error    or 
		   partial_reg_access_error;

  ip2bus_data_int1 <= xadc_ip2bus_data or 
                     intr_ip2bus_data;

process (Bus2IP_Clk)
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if (reset2ip_reset = '1') then
           ip2bus_wrack <= '0';
           ip2bus_rdack <= '0';
           ip2bus_error <= '0';
           ip2bus_data_int <= (others => '0');
        else
           ip2bus_wrack <= ip2bus_wrack_int1;
           ip2bus_rdack <= ip2bus_rdack_int1;
           ip2bus_error <= ip2bus_error_int1;
           ip2bus_data_int <= ip2bus_data_int1;
        end if;   
    end if;
end process;

end generate INTR_CTRLR_GEN_I;
------------------------------

-------------------------------------------------------------------------------

-- NO_INTR_CTRLR_GEN_I: Generate logic to be used to pass signals,
----------------------- when interrupt is not used.
NO_INTR_CTRLR_GEN_I : if (C_INCLUDE_INTR = 0) generate
-----
begin
-----
  ip2bus_wrack_int1  <= xadc_ip2bus_wrack or 
                   rst_ip2bus_wrack    or
		   dummy_local_reg_wrack;

  ip2bus_rdack_int1  <= xadc_ip2bus_rdack or 
                   rst_ip2bus_rdack    or
		   dummy_local_reg_rdack;

  ip2bus_error_int1  <= rst_ip2bus_error    or 
                   partial_reg_access_error;

  ip2bus_data_int1  <= xadc_ip2bus_data;

  ip2intc_irpt  <= '0';

process (Bus2IP_Clk)
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if (reset2ip_reset = '1') then
           ip2bus_wrack <= '0';
           ip2bus_rdack <= '0';
           ip2bus_error <= '0';
           ip2bus_data_int <= (others => '0');
        else
           ip2bus_wrack <= ip2bus_wrack_int1;
           ip2bus_rdack <= ip2bus_rdack_int1;
           ip2bus_error <= ip2bus_error_int1;
           ip2bus_data_int <= ip2bus_data_int1;
        end if;   
    end if;
end process;


end generate NO_INTR_CTRLR_GEN_I;
---------------------------------

-------------------------------------------------------------------------------

------------------------------------------------------------
-- SW_RESET_REG_READ_ACK_GEN_PROCESS:IMPLEMENT READ ACK LOGIC FOR SOFTWARE
--                                   RESET MODULE. This is dummy read as read is
--                                   not allowed on reset core.
------------------------------------------------------------
SW_RESET_REG_READ_ACK_GEN_PROCESS:process(Bus2IP_Clk) is
begin
  if (bus2ip_clk'event and bus2ip_clk = '1') then
    if (reset2ip_reset = RESET_ACTIVE) then
        rst_ip2bus_rdack_d1 <= '0';
        rst_ip2bus_rdack    <= '0';
    else
        rst_ip2bus_rdack_d1 <= bus2ip_rdce_int(SWRESET);
        rst_ip2bus_rdack    <= bus2ip_rdce_int(SWRESET) and
                               (not rst_ip2bus_rdack_d1);
    end if;
  end if;
end process SW_RESET_REG_READ_ACK_GEN_PROCESS;
---------------------------------------------
-------------------------------------------------------------------------------
-- Logic for generation of error signal for partial word access byte enables
and_reduce_be <= and_reduce(bus2ip_be);

partial_reg_access_error <= (not and_reduce_be)  and
                            (xadc_ip2bus_rdack or 
			     xadc_ip2bus_wrack);
-------------------------------------------------------------------------------

--------------------------------------------------------------
---- SW_RESET_REG_READ_ACK_GEN_PROCESS:Implement read ack logic for dummy register
----                                   holes. This is dummy read as read/write is
----                                   not returning any value. In local registers.
--------------------------------------------------------------
DUMMY_REG_READ_WRITE_ACK_GEN_PROCESS:process(Bus2IP_Clk) is
begin
  if (bus2ip_clk'event and bus2ip_clk = '1') then
    if (reset2ip_reset = RESET_ACTIVE) then
        dummy_local_reg_rdack_d1 <= '0';
        dummy_local_reg_rdack    <= '0';
	dummy_local_reg_wrack_d1 <= '0'; 
	dummy_local_reg_wrack    <= '0'; 
    else
        dummy_local_reg_rdack_d1 <= or_reduce(bus2ip_rdce_int(5 to 7));
        dummy_local_reg_rdack    <= or_reduce(bus2ip_rdce_int(5 to 7)) and
                                   (not dummy_local_reg_rdack_d1);

        dummy_local_reg_wrack_d1 <= or_reduce(bus2ip_wrce_int(5 to 7));
        dummy_local_reg_wrack    <= or_reduce(bus2ip_wrce_int(5 to 7)) and
                                   (not dummy_local_reg_wrack_d1);

    end if;
  end if;
end process DUMMY_REG_READ_WRITE_ACK_GEN_PROCESS;
-----------------------------------------------
end architecture imp;
