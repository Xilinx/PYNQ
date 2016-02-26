-------------------------------------------------------------------------------
-- AXI_GPIO - entity/architecture pair 
-------------------------------------------------------------------------------
--
-- ***************************************************************************
-- DISCLAIMER OF LIABILITY
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright 2009 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
-- ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        axi_gpio.vhd
-- Version:         v2.0
-- Description:     General Purpose I/O for AXI Interface
--
-------------------------------------------------------------------------------
-- Structure:   
--                  axi_gpio.vhd
--                        -- axi_lite_ipif.vhd
--                        -- interrupt_control.vhd
--                        -- gpio_core.vhd
-------------------------------------------------------------------------------
-- Author:          KSB
-- History:   
-- ~~~~~~~~~~~~~~
--   KSB                07/28/09
-- ^^^^^^^^^^^^^^
--  First version of axi_gpio. Based on xps_gpio 2.00a
--
--   KSB                05/20/10
-- ^^^^^^^^^^^^^^
--  Updated for holes in address range
-- ~~~~~~~~~~~~~~
--   VB                09/23/10
-- ^^^^^^^^^^^^^^
--  Updated for  axi_lite_ipfi_v1_01_a
-- ~~~~~~~~~~~~~~
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
use std.textio.all;
-------------------------------------------------------------------------------
-- AXI common package of the proc common library is used for different
-- function declarations
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- axi_gpio_v2_0_8 library is used for axi4 component declarations
-------------------------------------------------------------------------------
library axi_lite_ipif_v3_0_3; 
use axi_lite_ipif_v3_0_3.ipif_pkg.calc_num_ce;
use axi_lite_ipif_v3_0_3.ipif_pkg.INTEGER_ARRAY_TYPE;
use axi_lite_ipif_v3_0_3.ipif_pkg.SLV64_ARRAY_TYPE;

-------------------------------------------------------------------------------
-- axi_gpio_v2_0_8 library is used for interrupt controller component 
-- declarations
-------------------------------------------------------------------------------

library interrupt_control_v3_1_2; 

-------------------------------------------------------------------------------
-- axi_gpio_v2_0_8 library is used for axi_gpio component declarations
-------------------------------------------------------------------------------

library axi_gpio_v2_0_8; 

-------------------------------------------------------------------------------
--                     Defination of Generics :                              --
-------------------------------------------------------------------------------
-- AXI generics
--  C_BASEADDR      -- Base address of the core
--  C_HIGHADDR      -- Permits alias of address space
--                           by making greater than xFFF
--  C_S_AXI_ADDR_WIDTH    -- Width of AXI Address interface (in bits)
--  C_S_AXI_DATA_WIDTH    -- Width of the AXI Data interface (in bits)

-- C_FAMILY               -- XILINX FPGA family
-- C_INSTANCE             -- Instance name ot the core in the EDK system

-- C_GPIO_WIDTH           -- GPIO Data Bus width.
-- C_ALL_INPUTS           -- Inputs Only. 
-- C_INTERRUPT_PRESENT    -- GPIO Interrupt.
-- C_IS_BIDIR             -- Selects gpio_io_i as input.
-- C_DOUT_DEFAULT         -- GPIO_DATA Register reset value.
-- C_TRI_DEFAULT          -- GPIO_TRI Register reset value.
-- C_IS_DUAL              -- Dual Channel GPIO.
-- C_ALL_INPUTS_2         -- Channel2 Inputs only.
-- C_IS_BIDIR_2           -- Selects gpio2_io_i as input.
-- C_DOUT_DEFAULT_2       -- GPIO2_DATA Register reset value.
-- C_TRI_DEFAULT_2        -- GPIO2_TRI Register reset value.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                  Defination of Ports                                      --
-------------------------------------------------------------------------------
-- AXI signals
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

-- GPIO Signals
-- gpio_io_i             -- Channel 1 General purpose I/O in port
-- gpio_io_o             -- Channel 1 General purpose I/O out port
-- gpio_io_t             -- Channel 1 General purpose I/O 
                         -- TRI-STATE control port
-- gpio2_io_i            -- Channel 2 General purpose I/O in port
-- gpio2_io_o            -- Channel 2 General purpose I/O out port
-- gpio2_io_t            -- Channel 2 General purpose I/O 
                         -- TRI-STATE control port
-- System Signals
-- s_axi_aclk            -- AXI Clock
-- s_axi_aresetn          -- AXI Reset
-- ip2intc_irpt          -- AXI GPIO Interrupt

-------------------------------------------------------------------------------

entity axi_gpio is  
  generic
  (
--  -- System Parameter

    C_FAMILY               : string                         := "virtex7";
   
--  -- AXI Parameters
    C_S_AXI_ADDR_WIDTH     : integer range 9 to 9        := 9;
    C_S_AXI_DATA_WIDTH     : integer range 32 to 128        := 32;
    
--  -- GPIO Parameter    
    C_GPIO_WIDTH           : integer range 1 to 32          := 32;
    C_GPIO2_WIDTH          : integer range 1 to 32          := 32;
    C_ALL_INPUTS           : integer range 0 to 1     	    := 0;
    C_ALL_INPUTS_2         : integer range 0 to 1           := 0;

    C_ALL_OUTPUTS          : integer range 0 to 1     	    := 0;--2/28/2013
    C_ALL_OUTPUTS_2        : integer range 0 to 1           := 0;--2/28/2013

    C_INTERRUPT_PRESENT    : integer range 0 to 1      	    := 0;
    C_DOUT_DEFAULT         : std_logic_vector (31 downto 0) := X"0000_0000";
    C_TRI_DEFAULT          : std_logic_vector (31 downto 0) := X"FFFF_FFFF";
    C_IS_DUAL              : integer range 0 to 1           := 0;
    C_DOUT_DEFAULT_2       : std_logic_vector (31 downto 0) := X"0000_0000";
    C_TRI_DEFAULT_2        : std_logic_vector (31 downto 0) := X"FFFF_FFFF"
  );
  port
  (
    -- AXI interface Signals --------------------------------------------------
    s_axi_aclk              : in  std_logic;
    s_axi_aresetn           : in  std_logic;
    s_axi_awaddr            : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 
    								downto 0);
    s_axi_awvalid           : in  std_logic;
    s_axi_awready           : out std_logic;
    
    s_axi_wdata             : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 
    								downto 0);
    s_axi_wstrb             : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 
    								downto 0);
    s_axi_wvalid            : in  std_logic;
    s_axi_wready            : out std_logic;
    
    s_axi_bresp             : out std_logic_vector(1 downto 0);
    s_axi_bvalid            : out std_logic;
    s_axi_bready            : in  std_logic;
    
    s_axi_araddr            : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 
    								downto 0);
    s_axi_arvalid           : in  std_logic;
    s_axi_arready           : out std_logic;
    
    s_axi_rdata             : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 
    								downto 0);
    s_axi_rresp             : out std_logic_vector(1 downto 0);
    s_axi_rvalid            : out std_logic;
    s_axi_rready            : in  std_logic;
    
    -- Interrupt---------------------------------------------------------------
    ip2intc_irpt            : out std_logic;

    -- GPIO Signals------------------------------------------------------------
    gpio_io_i               : in  std_logic_vector(C_GPIO_WIDTH-1 downto 0);
    gpio_io_o               : out std_logic_vector(C_GPIO_WIDTH-1 downto 0);
    gpio_io_t               : out std_logic_vector(C_GPIO_WIDTH-1 downto 0);
    gpio2_io_i              : in  std_logic_vector(C_GPIO2_WIDTH-1 downto 0);
    gpio2_io_o              : out std_logic_vector(C_GPIO2_WIDTH-1 downto 0);
    gpio2_io_t              : out std_logic_vector(C_GPIO2_WIDTH-1 downto 0)
  );

-------------------------------------------------------------------------------
-- fan-out attributes for XST
-------------------------------------------------------------------------------

  attribute MAX_FANOUT                    : string;
  attribute MAX_FANOUT   of s_axi_aclk    : signal is "10000";
  attribute MAX_FANOUT   of s_axi_aresetn : signal is "10000";
-------------------------------------------------------------------------------
-- Attributes for MPD file
-------------------------------------------------------------------------------
  attribute IP_GROUP             	: string ;
  attribute IP_GROUP of axi_gpio 	: entity is "LOGICORE";
  attribute SIGIS                	: string ;
  attribute SIGIS of s_axi_aclk         : signal is "Clk";
  attribute SIGIS of s_axi_aresetn      : signal is "Rst";
  attribute SIGIS of ip2intc_irpt  	: signal is "INTR_LEVEL_HIGH";

end entity axi_gpio; 
-------------------------------------------------------------------------------
-- Architecture Section
-------------------------------------------------------------------------------

architecture imp of axi_gpio is 

-- Pragma Added to supress synth warnings
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
-------------------------------------------------------------------------------
-- constant added for webtalk information
-------------------------------------------------------------------------------
--function chr(sl: std_logic) return character is
--    variable c: character;
--    begin
--      case sl is
--         when '0' => c:= '0';
--         when '1' => c:= '1';
--         when 'Z' => c:= 'Z';
--         when 'U' => c:= 'U';
--         when 'X' => c:= 'X';
--         when 'W' => c:= 'W';
--         when 'L' => c:= 'L';
--         when 'H' => c:= 'H';
--         when '-' => c:= '-';
--      end case;
--    return c;
--   end chr;
--
--function str(slv: std_logic_vector) return string is
--     variable result : string (1 to slv'length);
--     variable r : integer;
--   begin
--     r := 1;
--     for i in slv'range loop
--        result(r) := chr(slv(i));
--        r := r + 1;
--     end loop;
--     return result;
--   end str;

type     bo2na_type is array (boolean) of natural; -- boolean to 
							--natural conversion
constant bo2na      :  bo2na_type := (false => 0, true => 1);

-------------------------------------------------------------------------------
-- Function Declarations
-------------------------------------------------------------------------------
type BOOLEAN_ARRAY_TYPE is array(natural range <>) of boolean;

----------------------------------------------------------------------------
-- This function returns the number of elements that are true in
-- a boolean array.
----------------------------------------------------------------------------
function num_set( ba : BOOLEAN_ARRAY_TYPE ) return natural is
    variable n : natural := 0;
begin
    for i in ba'range loop
        n := n + bo2na(ba(i));
    end loop;
    return n;
end;

----------------------------------------------------------------------------
-- This function returns a num_ce integer array that is constructed by
-- taking only those elements of superset num_ce integer array
-- that will be defined by the current case.
-- The superset num_ce array is given by parameter num_ce_by_ard.
-- The current case the ard elements that will be used is given
-- by parameter defined_ards.
----------------------------------------------------------------------------
function qual_ard_num_ce_array( defined_ards  : BOOLEAN_ARRAY_TYPE;
                                num_ce_by_ard : INTEGER_ARRAY_TYPE
                              ) return INTEGER_ARRAY_TYPE is
    variable res : INTEGER_ARRAY_TYPE(num_set(defined_ards)-1 downto 0);
    variable i : natural := 0;
    variable j : natural := defined_ards'left;
begin
    while i /= res'length loop
          -- coverage off
        while defined_ards(j) = false loop
            j := j+1;
        end loop;
          -- coverage on
        res(i) := num_ce_by_ard(j);
        i := i+1;
        j := j+1;
    end loop;
    return res;
end;


----------------------------------------------------------------------------
-- This function returns a addr_range array that is constructed by
-- taking only those elements of superset addr_range array
-- that will be defined by the current case.
-- The superset addr_range array is given by parameter addr_range_by_ard.
-- The current case the ard elements that will be used is given
-- by parameter defined_ards.
----------------------------------------------------------------------------
function qual_ard_addr_range_array( defined_ards      : BOOLEAN_ARRAY_TYPE;
                                    addr_range_by_ard : SLV64_ARRAY_TYPE
                                  ) return SLV64_ARRAY_TYPE is
    variable res : SLV64_ARRAY_TYPE(0 to 2*num_set(defined_ards)-1);
    variable i : natural := 0;
    variable j : natural := defined_ards'left;
begin
    while i /= res'length loop
          -- coverage off
        while defined_ards(j) = false loop
            j := j+1;
        end loop;
          -- coverage on        
        res(i)   := addr_range_by_ard(2*j);
        res(i+1) := addr_range_by_ard((2*j)+1);
        i := i+2;
        j := j+1;
    end loop;
    return res;
end;

function qual_ard_ce_valid( defined_ards      : BOOLEAN_ARRAY_TYPE
                                  ) return std_logic_vector is
    variable res : std_logic_vector(0 to 31);
begin
      res := (others => '0');
    if defined_ards(defined_ards'right) then
      res(0 to 3) := "1111";
      res(12) := '1';
      res(13) := '1';
      res(15) := '1';
    else
      res(0 to 3) := "1111";
    end if;
    return res;
end;

----------------------------------------------------------------------------
-- This function returns the maximum width amongst the two GPIO Channels
-- and if there is only one channel, it returns just the width of that
-- channel.
----------------------------------------------------------------------------
function max_width( dual_channel    : INTEGER;
                    channel1_width  : INTEGER;
                    channel2_width  : INTEGER
                  ) return INTEGER is 
begin
     if (dual_channel = 0) then
         return channel1_width;
     else
         if (channel1_width > channel2_width) then
             return channel1_width;
         else
             return channel2_width;
         end if; 
     end if;
     
end;


-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
constant    C_AXI_MIN_SIZE       : std_logic_vector(31 downto 0):= X"000001FF";
constant    ZERO_ADDR_PAD 	 : std_logic_vector(0 to 31) := 
						(others => '0');

constant INTR_TYPE      : integer   := 5;

constant INTR_BASEADDR  : std_logic_vector(0 to 31):= X"00000100";
constant INTR_HIGHADDR  : std_logic_vector(0 to 31):= X"000001FF";
constant GPIO_HIGHADDR  : std_logic_vector(0 to 31):= X"0000000F";
								
constant MAX_GPIO_WIDTH : integer := max_width
					(C_IS_DUAL,C_GPIO_WIDTH,C_GPIO2_WIDTH);


constant ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE :=
    qual_ard_addr_range_array(
        (true,C_INTERRUPT_PRESENT=1),
        (ZERO_ADDR_PAD & X"00000000", 
         ZERO_ADDR_PAD & GPIO_HIGHADDR,
         ZERO_ADDR_PAD & INTR_BASEADDR,
         ZERO_ADDR_PAD & INTR_HIGHADDR
        )
    );

constant ARD_NUM_CE_ARRAY : INTEGER_ARRAY_TYPE :=
    qual_ard_num_ce_array(
                (true,C_INTERRUPT_PRESENT=1),
                (4,16)
    );  

constant ARD_CE_VALID : std_logic_vector(0 to 31) :=
    qual_ard_ce_valid(
      (true,C_INTERRUPT_PRESENT=1)
    );

constant IP_INTR_MODE_ARRAY : INTEGER_ARRAY_TYPE(0 to 0+bo2na(C_IS_DUAL=1))
                            := (others => 5);
                            
constant C_USE_WSTRB            : integer := 0;
constant C_DPHASE_TIMEOUT       : integer := 8;

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------

signal ip2bus_intrevent     : std_logic_vector(0 to 1);

signal GPIO_xferAck_i : std_logic;
signal Bus2IP_Data_i  : std_logic_vector(0 to C_S_AXI_DATA_WIDTH-1);
signal Bus2IP1_Data_i  : std_logic_vector(0 to C_S_AXI_DATA_WIDTH-1);
signal Bus2IP2_Data_i  : std_logic_vector(0 to C_S_AXI_DATA_WIDTH-1);
-- IPIC Used Signals

signal ip2bus_data    : std_logic_vector(0 to C_S_AXI_DATA_WIDTH-1);

signal bus2ip_addr    : std_logic_vector(0 to C_S_AXI_ADDR_WIDTH-1);
signal bus2ip_data    : std_logic_vector(0 to C_S_AXI_DATA_WIDTH-1);
signal bus2ip_rnw     : std_logic;
signal bus2ip_cs      : std_logic_vector(0 to 0 + bo2na
						      (C_INTERRUPT_PRESENT=1));
signal bus2ip_rdce    : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);
signal bus2ip_wrce    : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);

signal Intrpt_bus2ip_rdce              : std_logic_vector(0 to 15);
signal Intrpt_bus2ip_wrce              : std_logic_vector(0 to 15);
signal intr_wr_ce_or_reduce            : std_logic; 
signal intr_rd_ce_or_reduce  	       : std_logic;
signal ip2Bus_RdAck_intr_reg_hole      : std_logic;
signal ip2Bus_RdAck_intr_reg_hole_d1   : std_logic;
signal ip2Bus_WrAck_intr_reg_hole      : std_logic;
signal ip2Bus_WrAck_intr_reg_hole_d1   : std_logic;



signal bus2ip_be      : std_logic_vector(0 to (C_S_AXI_DATA_WIDTH / 8) - 1);
signal bus2ip_clk     : std_logic;
signal bus2ip_reset   : std_logic;
signal bus2ip_resetn  : std_logic;
signal intr2bus_data  : std_logic_vector(0 to C_S_AXI_DATA_WIDTH-1);
signal intr2bus_wrack : std_logic;
signal intr2bus_rdack : std_logic;
signal intr2bus_error : std_logic;

signal ip2bus_data_i      : std_logic_vector(0 to C_S_AXI_DATA_WIDTH-1);
signal ip2bus_data_i_D1   : std_logic_vector(0 to C_S_AXI_DATA_WIDTH-1);
signal ip2bus_wrack_i     : std_logic;
signal ip2bus_wrack_i_D1  : std_logic;
signal ip2bus_rdack_i     : std_logic;
signal ip2bus_rdack_i_D1  : std_logic;
signal ip2bus_error_i     : std_logic;
signal IP2INTC_Irpt_i     : std_logic;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

begin -- architecture IMP

  
    AXI_LITE_IPIF_I : entity axi_lite_ipif_v3_0_3.axi_lite_ipif
      generic map
       (
        C_S_AXI_ADDR_WIDTH        => C_S_AXI_ADDR_WIDTH,
        C_S_AXI_DATA_WIDTH        => C_S_AXI_DATA_WIDTH,
        C_S_AXI_MIN_SIZE          => C_AXI_MIN_SIZE,
        C_USE_WSTRB               => C_USE_WSTRB,
        C_DPHASE_TIMEOUT          => C_DPHASE_TIMEOUT,
        C_ARD_ADDR_RANGE_ARRAY    => ARD_ADDR_RANGE_ARRAY,
        C_ARD_NUM_CE_ARRAY        => ARD_NUM_CE_ARRAY,
        C_FAMILY                  => C_FAMILY
       )
     port map
       (
        S_AXI_ACLK          =>  s_axi_aclk,
        S_AXI_ARESETN       =>  s_axi_aresetn,
        S_AXI_AWADDR        =>  s_axi_awaddr,
        S_AXI_AWVALID       =>  s_axi_awvalid,
        S_AXI_AWREADY       =>  s_axi_awready,
        S_AXI_WDATA         =>  s_axi_wdata,
        S_AXI_WSTRB         =>  s_axi_wstrb,
        S_AXI_WVALID        =>  s_axi_wvalid,
        S_AXI_WREADY        =>  s_axi_wready,
        S_AXI_BRESP         =>  s_axi_bresp,
        S_AXI_BVALID        =>  s_axi_bvalid,
        S_AXI_BREADY        =>  s_axi_bready,
        S_AXI_ARADDR        =>  s_axi_araddr,
        S_AXI_ARVALID       =>  s_axi_arvalid,
        S_AXI_ARREADY       =>  s_axi_arready,
        S_AXI_RDATA         =>  s_axi_rdata,
        S_AXI_RRESP         =>  s_axi_rresp,
        S_AXI_RVALID        =>  s_axi_rvalid,
        S_AXI_RREADY        =>  s_axi_rready,
     
     -- IP Interconnect (IPIC) port signals 
        Bus2IP_Clk     => bus2ip_clk,
        Bus2IP_Resetn  => bus2ip_resetn,
        IP2Bus_Data    => ip2bus_data_i_D1,
        IP2Bus_WrAck   => ip2bus_wrack_i_D1,
        IP2Bus_RdAck   => ip2bus_rdack_i_D1,
        --IP2Bus_WrAck   => ip2bus_wrack_i,
        --IP2Bus_RdAck   => ip2bus_rdack_i,
        IP2Bus_Error   => ip2bus_error_i,
        Bus2IP_Addr    => bus2ip_addr,
        Bus2IP_Data    => bus2ip_data,
        Bus2IP_RNW     => bus2ip_rnw,
        Bus2IP_BE      => bus2ip_be,
        Bus2IP_CS      => bus2ip_cs,
        Bus2IP_RdCE    => bus2ip_rdce,
        Bus2IP_WrCE    => bus2ip_wrce
       );



    ip2bus_data_i   <= intr2bus_data  or ip2bus_data;
    
    ip2bus_wrack_i  <= intr2bus_wrack 			    or 
               	       (GPIO_xferAck_i and not(bus2ip_rnw)) or 
               	       ip2Bus_WrAck_intr_reg_hole;-- Holes in Address range
               	       
    ip2bus_rdack_i  <= intr2bus_rdack                  or 
    		       (GPIO_xferAck_i and bus2ip_rnw) or
    		       ip2Bus_RdAck_intr_reg_hole; -- Holes in Address range
    	
    	       
    I_WRACK_RDACK_DELAYS: process(Bus2IP_Clk) is
    begin
       if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if (bus2ip_reset = '1') then
        	ip2bus_wrack_i_D1     <= '0';
        	ip2bus_rdack_i_D1     <= '0';
        	ip2bus_data_i_D1      <= (others => '0');
         else
        	ip2bus_wrack_i_D1     <= ip2bus_wrack_i;
        	ip2bus_rdack_i_D1     <= ip2bus_rdack_i;
        	ip2bus_data_i_D1      <= ip2bus_data_i;
         end if;
       end if;
    end process I_WRACK_RDACK_DELAYS;   
      
      
    ip2bus_error_i  <= intr2bus_error;

  ----------------------
  --REG_RESET_FROM_IPIF: convert active low to active hig reset to rest of
  --                     the core.
  ----------------------
  REG_RESET_FROM_IPIF: process (s_axi_aclk) is
  begin
       if(s_axi_aclk'event and s_axi_aclk = '1') then
           bus2ip_reset <= not(bus2ip_resetn);
       end if;
  end process REG_RESET_FROM_IPIF;
    ---------------------------------------------------------------------------
    -- Interrupts
    ---------------------------------------------------------------------------

    INTR_CTRLR_GEN : if (C_INTERRUPT_PRESENT = 1) generate
         constant NUM_IPIF_IRPT_SRC     : natural := 1;
         constant NUM_CE                : integer := 16;

         signal errack_reserved         : std_logic_vector(0 to 1);
         signal ipif_lvl_interrupts     : std_logic_vector(0 to 
         						NUM_IPIF_IRPT_SRC-1);
    begin

      ipif_lvl_interrupts    <= (others => '0');  
      errack_reserved        <= (others => '0');
      
      
      --- Addr 0X11c, 0X120, 0X128 valid addresses, remaining are holes 
      
      Intrpt_bus2ip_rdce <= "0000000" & bus2ip_rdce(11) & bus2ip_rdce(12) & '0'
				      & bus2ip_rdce(14)	& "00000";
				      
      Intrpt_bus2ip_wrce <= "0000000" & bus2ip_wrce(11) & bus2ip_wrce(12) & '0'
				      & bus2ip_wrce(14)	& "00000";
				      
				      
      intr_rd_ce_or_reduce <= or_reduce(bus2ip_rdce(4 to 10)) or
                                    Bus2IP_RdCE(13)      or
   				    or_reduce(Bus2IP_RdCE(15 to 19));
   				    
      intr_wr_ce_or_reduce <= or_reduce(bus2ip_wrce(4 to 10)) or
                                    bus2ip_wrce(13)      or
   				    or_reduce(bus2ip_wrce(15 to 19));   
   				    
      I_READ_ACK_INTR_HOLES: process(Bus2IP_Clk) is
      begin
         if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
           if (bus2ip_reset = '1') then
     	  	ip2Bus_RdAck_intr_reg_hole     <= '0';
     	  	ip2Bus_RdAck_intr_reg_hole_d1  <= '0';
           else
     	  	ip2Bus_RdAck_intr_reg_hole_d1 <= intr_rd_ce_or_reduce;
     	  	ip2Bus_RdAck_intr_reg_hole    <= intr_rd_ce_or_reduce and
     					   (not ip2Bus_RdAck_intr_reg_hole_d1);
           end if;
         end if;
      end process I_READ_ACK_INTR_HOLES;   
      
      
      
       I_WRITE_ACK_INTR_HOLES: process(Bus2IP_Clk) is
       begin
          if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
           if (bus2ip_reset = '1') then
                ip2Bus_WrAck_intr_reg_hole     <= '0';
                ip2Bus_WrAck_intr_reg_hole_d1  <= '0';
            else
                ip2Bus_WrAck_intr_reg_hole_d1 <= intr_wr_ce_or_reduce;
                ip2Bus_WrAck_intr_reg_hole    <= intr_wr_ce_or_reduce and
                                            (not ip2Bus_WrAck_intr_reg_hole_d1);
            end if;
          end if;
       end process I_WRITE_ACK_INTR_HOLES;

   				    
      INTERRUPT_CONTROL_I : entity interrupt_control_v3_1_2.interrupt_control
        generic map
        (
          C_NUM_CE                => NUM_CE,
          C_NUM_IPIF_IRPT_SRC     => NUM_IPIF_IRPT_SRC,   
          C_IP_INTR_MODE_ARRAY    => IP_INTR_MODE_ARRAY,
          C_INCLUDE_DEV_PENCODER  => false,
          C_INCLUDE_DEV_ISC       => false,
          C_IPIF_DWIDTH           => C_S_AXI_DATA_WIDTH
        )
        port map
        (
          -- Inputs From the IPIF Bus 
          Bus2IP_Clk           => Bus2IP_Clk,
          Bus2IP_Reset         => bus2ip_reset, 
          Bus2IP_Data          => bus2ip_data,
          Bus2IP_BE            => bus2ip_be,
          Interrupt_RdCE       => Intrpt_bus2ip_rdce,
          Interrupt_WrCE       => Intrpt_bus2ip_wrce,

          -- Interrupt inputs from the IPIF sources that will 
          -- get registered in this design
          IPIF_Reg_Interrupts  => errack_reserved,     

          -- Level Interrupt inputs from the IPIF sources
          IPIF_Lvl_Interrupts  => ipif_lvl_interrupts,     

          -- Inputs from the IP Interface  
          IP2Bus_IntrEvent     => ip2bus_intrevent(IP_INTR_MODE_ARRAY'range),  

          -- Final Device Interrupt Output
          Intr2Bus_DevIntr     => IP2INTC_Irpt_i,       

          -- Status Reply Outputs to the Bus 
          Intr2Bus_DBus        => intr2bus_data,           
          Intr2Bus_WrAck       => intr2bus_wrack,   
          Intr2Bus_RdAck       => intr2bus_rdack,   
          Intr2Bus_Error       => intr2bus_error,   
          Intr2Bus_Retry       => open,          
          Intr2Bus_ToutSup     => open      
        );

       -- registering interrupt
       I_INTR_DELAY: process(Bus2IP_Clk) is
       begin
          if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if (bus2ip_reset = '1') then
           	ip2intc_irpt          <= '0';
            else
           	ip2intc_irpt          <= IP2INTC_Irpt_i;
            end if;
          end if;
       end process I_INTR_DELAY;   
      
    end generate INTR_CTRLR_GEN;
    -----------------------------------------------------------------------
    -- Assigning the intr2bus signal to zero's when interrupt is not 
    -- present
    -----------------------------------------------------------------------
    REMOVE_INTERRUPT : if (C_INTERRUPT_PRESENT = 0) generate

         intr2bus_data     <=  (others => '0');
         ip2intc_irpt      <=  '0';
         intr2bus_error    <=  '0'; 
         intr2bus_rdack    <=  '0'; 
         intr2bus_wrack    <=  '0'; 
         ip2Bus_WrAck_intr_reg_hole    <=  '0';
         ip2Bus_RdAck_intr_reg_hole    <=  '0';

    end generate REMOVE_INTERRUPT; 

    gpio_core_1 : entity axi_gpio_v2_0_8.gpio_core
      generic map 
           (
             C_DW                => C_S_AXI_DATA_WIDTH,
             C_AW                => C_S_AXI_ADDR_WIDTH,
             C_GPIO_WIDTH        => C_GPIO_WIDTH,
             C_GPIO2_WIDTH       => C_GPIO2_WIDTH,
             C_MAX_GPIO_WIDTH    => MAX_GPIO_WIDTH,
             C_INTERRUPT_PRESENT => C_INTERRUPT_PRESENT,
             C_DOUT_DEFAULT      => C_DOUT_DEFAULT,
             C_TRI_DEFAULT       => C_TRI_DEFAULT,
             C_IS_DUAL           => C_IS_DUAL,
             C_DOUT_DEFAULT_2    => C_DOUT_DEFAULT_2,
             C_TRI_DEFAULT_2     => C_TRI_DEFAULT_2,
             C_FAMILY            => C_FAMILY
           )
    
           port map 
           (
             Clk              => Bus2IP_Clk,
             Rst              => bus2ip_reset,
             ABus_Reg         => Bus2IP_Addr,
             BE_Reg           => Bus2IP_BE(0 to C_S_AXI_DATA_WIDTH/8-1),
             DBus_Reg         => Bus2IP_Data_i(0 to MAX_GPIO_WIDTH-1),
             RNW_Reg          => Bus2IP_RNW, 
             GPIO_DBus        => IP2Bus_Data(0 to C_S_AXI_DATA_WIDTH-1),
             GPIO_xferAck     => GPIO_xferAck_i,
             GPIO_Select      => bus2ip_cs(0),
             GPIO_intr        => ip2bus_intrevent(0),
             GPIO2_intr       => ip2bus_intrevent(1),
             GPIO_IO_I        => gpio_io_i,
             GPIO_IO_O        => gpio_io_o,
             GPIO_IO_T        => gpio_io_t,
             GPIO2_IO_I       => gpio2_io_i,
             GPIO2_IO_O       => gpio2_io_o,
             GPIO2_IO_T       => gpio2_io_t
           );
    
    
    
           Bus2IP_Data_i  <= Bus2IP1_Data_i when bus2ip_cs(0) = '1' 
           				and bus2ip_addr (5) = '0'else 
           				Bus2IP2_Data_i;
           
    
    	BUS_CONV_ch1 : for i in 0 to C_GPIO_WIDTH-1 generate
    		Bus2IP1_Data_i(i) <= Bus2IP_Data(i+
    					C_S_AXI_DATA_WIDTH-C_GPIO_WIDTH);
    	end generate BUS_CONV_ch1;       
    
    
    
    	BUS_CONV_ch2 : for i in 0 to C_GPIO2_WIDTH-1 generate
    		Bus2IP2_Data_i(i) <= Bus2IP_Data(i+
    					C_S_AXI_DATA_WIDTH-C_GPIO2_WIDTH);
	end generate BUS_CONV_ch2;  



end architecture imp;
