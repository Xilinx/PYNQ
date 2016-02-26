-------------------------------------------------------------------------------
-- axi_bram_ctrl_top.vhd
-------------------------------------------------------------------------------
--
--
-- (c) Copyright [2010 - 2013] Xilinx, Inc. All rights reserved.
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
--
-------------------------------------------------------------------------------
-- Filename:        axi_bram_ctrl_top.vhd
--
-- Description:     This file is the top level module for the AXI BRAM
--                  controller IP core.
--
-- VHDL-Standard:   VHDL'93
--
-------------------------------------------------------------------------------
-- Structure:
--              axi_bram_ctrl_top.vhd (v4_0)
--                      |
--                      |-- full_axi.vhd
--                      |   -- sng_port_arb.vhd
--                      |   -- lite_ecc_reg.vhd
--                      |       -- axi_lite_if.vhd
--                      |   -- wr_chnl.vhd
--                      |       -- wrap_brst.vhd
--                      |       -- ua_narrow.vhd
--                      |       -- checkbit_handler.vhd
--                      |           -- xor18.vhd
--                      |           -- parity.vhd
--                      |       -- checkbit_handler_64.vhd
--                      |           -- (same helper components as checkbit_handler)
--                      |       -- parity.vhd
--                      |       -- correct_one_bit.vhd
--                      |       -- correct_one_bit_64.vhd
--                      |       -- ecc_gen.vhd
--                      |
--                      |   -- rd_chnl.vhd
--                      |       -- wrap_brst.vhd
--                      |       -- ua_narrow.vhd
--                      |       -- checkbit_handler.vhd
--                      |           -- xor18.vhd
--                      |           -- parity.vhd
--                      |       -- checkbit_handler_64.vhd
--                      |           -- (same helper components as checkbit_handler)
--                      |       -- parity.vhd
--                      |       -- correct_one_bit.vhd
--                      |       -- correct_one_bit_64.vhd
--                      |       -- ecc_gen.vhd
--                      |
--                      |-- axi_lite.vhd
--                      |   -- lite_ecc_reg.vhd
--                      |       -- axi_lite_if.vhd
--                      |   -- checkbit_handler.vhd
--                      |       -- xor18.vhd
--                      |       -- parity.vhd
--                      |   -- correct_one_bit.vhd
--                      |   -- ecc_gen.vhd
--
--
--
-------------------------------------------------------------------------------
--
-- History:
--
-- ^^^^^^
-- JLJ      2/1/2011         v1.03a
-- ~~~~~~
--  Migrate to v1.03a.
--  Plus minor code cleanup.
-- ^^^^^^
-- JLJ      2/2/2011         v1.03a
-- ~~~~~~
--  Remove library version # dependency.  Replace with work library.
-- ^^^^^^
-- JLJ      2/9/2011         v1.03a
-- ~~~~~~
--  Update Create_Size_Default function to support 512 & 1024-bit BRAM.
--  Replace usage of Create_Size_Default function.
-- ^^^^^^
-- JLJ      2/15/2011        v1.03a
-- ~~~~~~
--  Initial integration of Hsiao ECC algorithm.
--  Add C_ECC_TYPE top level parameter on full_axi module.
--  Update ECC signal sizes for 128-bit support.
-- ^^^^^^
-- JLJ      2/16/2011      v1.03a
-- ~~~~~~
--  Update WE size based on 128-bit ECC configuration.
-- ^^^^^^
-- JLJ      2/22/2011      v1.03a
-- ~~~~~~
--  Add C_ECC_TYPE top level parameter on axi_lite module.
-- ^^^^^^
-- JLJ      2/23/2011      v1.03a
-- ~~~~~~
--  Set C_ECC_TYPE = 1 for Hsiao DV regressions.
-- ^^^^^^
-- JLJ      2/24/2011      v1.03a
-- ~~~~~~
--  Move Find_ECC_Size function to package.
-- ^^^^^^
-- JLJ      3/17/2011      v1.03a
-- ~~~~~~
--  Add comments as noted in Spyglass runs.
-- ^^^^^^
-- JLJ      5/6/2011      v1.03a
-- ~~~~~~
--  Remove C_FAMILY from top level.
--  Remove C_FAMILY in axi_lite sub module.
-- ^^^^^^
-- JLJ      6/23/2011      v1.03a
-- ~~~~~~
--  Migrate 9-bit ECC to 16-bit ECC for 128-bit BRAM data width.
-- ^^^^^^
--
--
--
-------------------------------------------------------------------------------

-- Library declarations

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;

library work;
use work.axi_lite;
use work.full_axi;
use work.axi_bram_ctrl_funcs.all;

------------------------------------------------------------------------------


entity axi_bram_ctrl_top is
generic (


    -- AXI Parameters

    C_BRAM_ADDR_WIDTH  : integer := 12;
        -- Width of AXI address bus (in bits)

    C_S_AXI_ADDR_WIDTH  : integer := 32;
        -- Width of AXI address bus (in bits)

    C_S_AXI_DATA_WIDTH  : integer := 32;
        -- Width of AXI data bus (in bits)

    C_S_AXI_ID_WIDTH : INTEGER := 4;
        --  AXI ID vector width

    C_S_AXI_PROTOCOL : string := "AXI4";
        -- Set to AXI4LITE to optimize out burst transaction support

    C_S_AXI_SUPPORTS_NARROW_BURST : INTEGER := 1;
        -- Support for narrow burst operations

    C_SINGLE_PORT_BRAM : INTEGER := 0;
        -- Enable single port usage of BRAM

    -- C_FAMILY : string := "virtex6";
        -- Specify the target architecture type



    -- AXI-Lite Register Parameters

    C_S_AXI_CTRL_ADDR_WIDTH : integer := 32;
        -- Width of AXI-Lite address bus (in bits)

    C_S_AXI_CTRL_DATA_WIDTH  : integer := 32;
        -- Width of AXI-Lite data bus (in bits)



    -- ECC Parameters

    C_ECC : integer := 0;
        -- Enables or disables ECC functionality
    C_ECC_TYPE  : integer := 1;           

    C_FAULT_INJECT : integer := 0;
        -- Enable fault injection registers
        -- (default = disabled)

    C_ECC_ONOFF_RESET_VALUE : integer := 1
        -- By default, ECC checking is on
        -- (can disable ECC @ reset by setting this to 0)


    -- Reserved parameters for future implementations.

        -- C_ENABLE_AXI_CTRL_REG_IF : integer := 1;
            -- By default the ECC AXI-Lite register interface is enabled

        -- C_CE_FAILING_REGISTERS : integer := 1;
            -- Enable CE (correctable error) failing registers

        -- C_UE_FAILING_REGISTERS : integer := 1;
            -- Enable UE (uncorrectable error) failing registers

        -- C_ECC_STATUS_REGISTERS : integer := 1;
            -- Enable ECC status registers

        -- C_ECC_ONOFF_REGISTER : integer := 1;
            -- Enable ECC on/off control register

        -- C_CE_COUNTER_WIDTH : integer := 0
            -- Selects CE counter width/threshold to assert ECC_Interrupt


       );
  port (


    -- AXI Interface Signals

    -- AXI Clock and Reset
    S_AXI_ACLK              : in    std_logic;
    S_AXI_ARESETN           : in    std_logic;

    ECC_Interrupt           : out   std_logic := '0';
    ECC_UE                  : out   std_logic := '0';

    -- AXI Write Address Channel Signals (AW)
    S_AXI_AWID              : in    std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_AWADDR            : in    std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWLEN             : in    std_logic_vector(7 downto 0);
    S_AXI_AWSIZE            : in    std_logic_vector(2 downto 0);
    S_AXI_AWBURST           : in    std_logic_vector(1 downto 0);
    S_AXI_AWLOCK            : in    std_logic;
    S_AXI_AWCACHE           : in    std_logic_vector(3 downto 0);
    S_AXI_AWPROT            : in    std_logic_vector(2 downto 0);
    S_AXI_AWVALID           : in    std_logic;
    S_AXI_AWREADY           : out   std_logic;


    -- AXI Write Data Channel Signals (W)
    S_AXI_WDATA             : in    std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB             : in    std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
    S_AXI_WLAST             : in    std_logic;

    S_AXI_WVALID            : in    std_logic;
    S_AXI_WREADY            : out   std_logic;


    -- AXI Write Data Response Channel Signals (B)
    S_AXI_BID               : out   std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_BRESP             : out   std_logic_vector(1 downto 0);

    S_AXI_BVALID            : out   std_logic;
    S_AXI_BREADY            : in    std_logic;



    -- AXI Read Address Channel Signals (AR)
    S_AXI_ARID              : in    std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_ARADDR            : in    std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARLEN             : in    std_logic_vector(7 downto 0);
    S_AXI_ARSIZE            : in    std_logic_vector(2 downto 0);
    S_AXI_ARBURST           : in    std_logic_vector(1 downto 0);
    S_AXI_ARLOCK            : in    std_logic;
    S_AXI_ARCACHE           : in    std_logic_vector(3 downto 0);
    S_AXI_ARPROT            : in    std_logic_vector(2 downto 0);

    S_AXI_ARVALID           : in    std_logic;
    S_AXI_ARREADY           : out   std_logic;


    -- AXI Read Data Channel Signals (R)
    S_AXI_RID               : out   std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_RDATA             : out   std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP             : out   std_logic_vector(1 downto 0);
    S_AXI_RLAST             : out   std_logic;

    S_AXI_RVALID            : out   std_logic;
    S_AXI_RREADY            : in    std_logic;




    -- AXI-Lite ECC Register Interface Signals

    -- AXI-Lite Clock and Reset
    -- Note: AXI-Lite Control IF and AXI IF share the same clock.
    -- S_AXI_CTRL_ACLK             : in    std_logic;
    -- S_AXI_CTRL_ARESETN          : in    std_logic;

    -- AXI-Lite Write Address Channel Signals (AW)
    S_AXI_CTRL_AWVALID          : in    std_logic;
    S_AXI_CTRL_AWREADY          : out   std_logic;
    S_AXI_CTRL_AWADDR           : in    std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);


    -- AXI-Lite Write Data Channel Signals (W)
    S_AXI_CTRL_WDATA            : in    std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    S_AXI_CTRL_WVALID           : in    std_logic;
    S_AXI_CTRL_WREADY           : out   std_logic;


    -- AXI-Lite Write Data Response Channel Signals (B)
    S_AXI_CTRL_BRESP            : out   std_logic_vector(1 downto 0);
    S_AXI_CTRL_BVALID           : out   std_logic;
    S_AXI_CTRL_BREADY           : in    std_logic;


    -- AXI-Lite Read Address Channel Signals (AR)
    S_AXI_CTRL_ARADDR           : in    std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
    S_AXI_CTRL_ARVALID          : in    std_logic;
    S_AXI_CTRL_ARREADY          : out   std_logic;


    -- AXI-Lite Read Data Channel Signals (R)
    S_AXI_CTRL_RDATA             : out   std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    S_AXI_CTRL_RRESP             : out   std_logic_vector(1 downto 0);
    S_AXI_CTRL_RVALID            : out   std_logic;
    S_AXI_CTRL_RREADY            : in    std_logic;



    -- BRAM Interface Signals (Port A)
    BRAM_Rst_A              : out   std_logic;
    BRAM_Clk_A              : out   std_logic;
    BRAM_En_A               : out   std_logic;
    BRAM_WE_A               : out   std_logic_vector (C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);
    BRAM_Addr_A             : out   std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0);
    BRAM_WrData_A           : out   std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);
    BRAM_RdData_A           : in    std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);


    -- BRAM Interface Signals (Port B)
    BRAM_Rst_B              : out   std_logic;
    BRAM_Clk_B              : out   std_logic;
    BRAM_En_B               : out   std_logic;
    BRAM_WE_B               : out   std_logic_vector (C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);
    BRAM_Addr_B             : out   std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0);
    BRAM_WrData_B           : out   std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);
    BRAM_RdData_B           : in    std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0)



    );



end entity axi_bram_ctrl_top;


-------------------------------------------------------------------------------

architecture implementation of axi_bram_ctrl_top is

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of implementation : architecture is "yes";

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-- All functions defined in axi_bram_ctrl_funcs package.


-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- Model behavior of AXI Interconnect in simulation for wrapping of ID values.
constant C_SIM_ONLY         : std_logic := '1';

-- Reset active level (common through core)
constant C_RESET_ACTIVE     : std_logic := '0';


-- Create top level constant to assign fixed value to ARSIZE and AWSIZE
-- when narrow bursting is parameterized out of the IP core instantiation.

-- constant AXI_FIXED_SIZE_WO_NARROW   : std_logic_vector (2 downto 0) := Create_Size_Default;

-- v1.03a
constant AXI_FIXED_SIZE_WO_NARROW   : integer := log2 (C_S_AXI_DATA_WIDTH/8);


-- Only instantiate logic based on C_S_AXI_PROTOCOL.
constant IF_IS_AXI4      : boolean := (Equal_String (C_S_AXI_PROTOCOL, "AXI4"));
constant IF_IS_AXI4LITE  : boolean := (Equal_String (C_S_AXI_PROTOCOL, "AXI4LITE"));


-- Determine external ECC width.
-- Use function defined in axi_bram_ctrl_funcs package.
constant C_ECC_WIDTH : integer := Find_ECC_Size (C_ECC, C_S_AXI_DATA_WIDTH);
constant C_ECC_FULL_BIT_WIDTH : integer := Find_ECC_Full_Bit_Size (C_ECC, C_S_AXI_DATA_WIDTH);


-- Set internal parameters for ECC register enabling when C_ECC = 1
constant C_ENABLE_AXI_CTRL_REG_IF_I : integer := C_ECC;
constant C_CE_FAILING_REGISTERS_I   : integer := C_ECC;
constant C_UE_FAILING_REGISTERS_I   : integer := 0;         -- Remove all UE registers
                                                            -- Catastrophic error indicated with ECC_UE & Interrupt flags.
constant C_ECC_STATUS_REGISTERS_I   : integer := C_ECC;
constant C_ECC_ONOFF_REGISTER_I     : integer := C_ECC;

constant C_CE_COUNTER_WIDTH         : integer := 8 * C_ECC;
-- Counter only sized when C_ECC = 1.
-- Selects CE counter width/threshold to assert ECC_Interrupt
-- Hard coded at 8-bits to capture and count up to 256 correctable errors.


--constant C_ECC_TYPE                 : integer := 1;             -- v1.03a
-- ECC algorithm format, 0 = Hamming code, 1 = Hsiao code


-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------


-- Internal BRAM Signals

-- Port A
signal bram_en_a_int            : std_logic := '0';
signal bram_we_a_int            : std_logic_vector (((C_S_AXI_DATA_WIDTH+C_ECC_FULL_BIT_WIDTH)/8)-1 downto 0) := (others => '0');
signal bram_addr_a_int          : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
signal bram_wrdata_a_int        : std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0) := (others => '0');
signal bram_rddata_a_int        : std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0) := (others => '0');

-- Port B
signal bram_addr_b_int          : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
signal bram_en_b_int            : std_logic := '0';
signal bram_we_b_int            : std_logic_vector (((C_S_AXI_DATA_WIDTH+C_ECC_FULL_BIT_WIDTH)/8)-1 downto 0) := (others => '0');
signal bram_wrdata_b_int        : std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0) := (others => '0');
signal bram_rddata_b_int        : std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0) := (others => '0');

signal axi_awsize_int           : std_logic_vector(2 downto 0) := (others => '0');
signal axi_arsize_int           : std_logic_vector(2 downto 0) := (others => '0');

signal S_AXI_ARREADY_int    : std_logic := '0';
signal S_AXI_AWREADY_int    : std_logic := '0';

signal S_AXI_RID_int        : std_logic_vector (C_S_AXI_ID_WIDTH-1 downto 0) := (others => '0');
signal S_AXI_BID_int        : std_logic_vector (C_S_AXI_ID_WIDTH-1 downto 0) := (others => '0');




-------------------------------------------------------------------------------
-- Architecture Body
-------------------------------------------------------------------------------


begin



    -- *** BRAM Port A Output Signals ***

    BRAM_Rst_A <= not (S_AXI_ARESETN);
    BRAM_Clk_A <= S_AXI_ACLK;
    BRAM_En_A <= bram_en_a_int;
    BRAM_WE_A ((((C_S_AXI_DATA_WIDTH + C_ECC_FULL_BIT_WIDTH)/8) - 1) downto (C_ECC_FULL_BIT_WIDTH/8)) <= bram_we_a_int((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    BRAM_Addr_A <= bram_addr_a_int;
    bram_rddata_a_int (C_S_AXI_DATA_WIDTH-1 downto 0) <= BRAM_RdData_A ((C_S_AXI_DATA_WIDTH + C_ECC_FULL_BIT_WIDTH - 1) downto (C_ECC_FULL_BIT_WIDTH));

    BRAM_WrData_A ((C_S_AXI_DATA_WIDTH + C_ECC_FULL_BIT_WIDTH - 1) downto (C_ECC_FULL_BIT_WIDTH)) <= bram_wrdata_a_int(C_S_AXI_DATA_WIDTH-1 downto 0);

    -- Added for 13.3
    -- Drive unused upper ECC bits to '0'
    -- For bram_block compatibility, must drive unused upper bits to '0' for ECC 128-bit use case.
    GEN_128_ECC_WR: if (C_S_AXI_DATA_WIDTH = 128) and (C_ECC = 1) generate
    begin
        BRAM_WrData_A ((C_ECC_FULL_BIT_WIDTH - 1) downto (C_ECC_WIDTH)) <= (others => '0');
        BRAM_WrData_A ((C_ECC_WIDTH-1) downto 0) <= bram_wrdata_a_int(C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto C_S_AXI_DATA_WIDTH);
        
        BRAM_WE_A ((C_ECC_FULL_BIT_WIDTH/8) - 1  downto 0) <= bram_we_a_int(((C_S_AXI_DATA_WIDTH+C_ECC_FULL_BIT_WIDTH)/8)-1 downto (C_S_AXI_DATA_WIDTH/8));
        
        bram_rddata_a_int (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto C_S_AXI_DATA_WIDTH) <= BRAM_RdData_A ((C_ECC_WIDTH-1) downto 0);
    end generate GEN_128_ECC_WR;

    GEN_ECC_WR: if ( not (C_S_AXI_DATA_WIDTH = 128) and (C_ECC = 1)) generate
    begin
        BRAM_WrData_A ((C_ECC_WIDTH - 1) downto 0) <= bram_wrdata_a_int(C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto C_S_AXI_DATA_WIDTH);

        BRAM_WE_A ((C_ECC_FULL_BIT_WIDTH/8) - 1 downto 0) <= bram_we_a_int(((C_S_AXI_DATA_WIDTH+C_ECC_FULL_BIT_WIDTH)/8)-1 downto (C_S_AXI_DATA_WIDTH/8));

        bram_rddata_a_int (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto C_S_AXI_DATA_WIDTH) <= BRAM_RdData_A ((C_ECC_WIDTH-1) downto 0);
    end generate GEN_ECC_WR;

    -- *** BRAM Port B Output Signals ***

    GEN_PORT_B: if (C_SINGLE_PORT_BRAM = 0) generate
    begin

        BRAM_Rst_B <= not (S_AXI_ARESETN);
        BRAM_WE_B ((((C_S_AXI_DATA_WIDTH + C_ECC_FULL_BIT_WIDTH)/8) - 1) downto (C_ECC_FULL_BIT_WIDTH/8)) <= bram_we_b_int((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        BRAM_Addr_B <= bram_addr_b_int;
        BRAM_En_B <= bram_en_b_int;
        bram_rddata_b_int (C_S_AXI_DATA_WIDTH-1 downto 0) <= BRAM_RdData_B ((C_S_AXI_DATA_WIDTH + C_ECC_FULL_BIT_WIDTH - 1) downto (C_ECC_FULL_BIT_WIDTH));
        BRAM_WrData_B ((C_S_AXI_DATA_WIDTH + C_ECC_FULL_BIT_WIDTH - 1) downto (C_ECC_FULL_BIT_WIDTH)) <= bram_wrdata_b_int(C_S_AXI_DATA_WIDTH-1 downto 0);


        -- 13.3
        --  BRAM_WrData_B <= bram_wrdata_b_int;


        -- Added for 13.3
        -- Drive unused upper ECC bits to '0'
        -- For bram_block compatibility, must drive unused upper bits to '0' for ECC 128-bit use case.
        GEN_128_ECC_WR: if (C_S_AXI_DATA_WIDTH = 128) and (C_ECC = 1) generate
        begin
          BRAM_WrData_B ((C_ECC_FULL_BIT_WIDTH - 1) downto (C_ECC_WIDTH)) <= (others => '0');
          BRAM_WrData_B ((C_ECC_WIDTH-1) downto 0) <= bram_wrdata_b_int(C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto C_S_AXI_DATA_WIDTH);

          BRAM_WE_B ((C_ECC_FULL_BIT_WIDTH/8) - 1 downto 0) <= bram_we_b_int(((C_S_AXI_DATA_WIDTH+C_ECC_FULL_BIT_WIDTH)/8)-1 downto (C_S_AXI_DATA_WIDTH/8));

          bram_rddata_b_int (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto C_S_AXI_DATA_WIDTH) <= BRAM_RdData_B ((C_ECC_WIDTH-1) downto 0); 
        end generate GEN_128_ECC_WR;


        GEN_ECC_WR: if ( not (C_S_AXI_DATA_WIDTH = 128) and (C_ECC = 1)) generate
        begin
          BRAM_WrData_B ((C_ECC_WIDTH - 1) downto 0) <= bram_wrdata_b_int(C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto C_S_AXI_DATA_WIDTH);
  
          BRAM_WE_B ((C_ECC_FULL_BIT_WIDTH/8) - 1 downto 0) <= bram_we_b_int(((C_S_AXI_DATA_WIDTH+C_ECC_FULL_BIT_WIDTH)/8)-1 downto (C_S_AXI_DATA_WIDTH/8));

          bram_rddata_b_int (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto C_S_AXI_DATA_WIDTH) <= BRAM_RdData_B ((C_ECC_WIDTH-1) downto 0); 
        end generate GEN_ECC_WR;

    end generate GEN_PORT_B;


    GEN_NO_PORT_B: if (C_SINGLE_PORT_BRAM = 1) generate
    begin

        BRAM_Rst_B <= '0';
        BRAM_WE_B <= (others => '0');
        BRAM_WrData_B <= (others => '0');
        BRAM_Addr_B <= (others => '0');
        BRAM_En_B <= '0';

    end generate GEN_NO_PORT_B;



    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_BRAM_CLK_B
    -- Purpose:     Only drive BRAM_Clk_B when dual port BRAM is enabled.
    --
    ---------------------------------------------------------------------------

    GEN_BRAM_CLK_B: if (C_SINGLE_PORT_BRAM = 0) generate
    begin
        BRAM_Clk_B <= S_AXI_ACLK;
    end generate GEN_BRAM_CLK_B;


    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_NO_BRAM_CLK_B
    -- Purpose:     Drive default value for BRAM_Clk_B when single port
    --              BRAM is enabled and no clock is necessary on the inactive
    --              BRAM port.
    --
    ---------------------------------------------------------------------------

    GEN_NO_BRAM_CLK_B: if (C_SINGLE_PORT_BRAM = 1) generate
    begin
        BRAM_Clk_B <= '0';
    end generate GEN_NO_BRAM_CLK_B;





    ---------------------------------------------------------------------------



    -- Generate top level ARSIZE and AWSIZE signals for rd_chnl and wr_chnl
    -- respectively, based on design parameter setting of generic,
    -- C_S_AXI_SUPPORTS_NARROW_BURST.


    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_W_NARROW
    -- Purpose:     Create internal AWSIZE and ARSIZE signal for write and
    --              read channel modules based on top level AXI signal inputs.
    --
    ---------------------------------------------------------------------------

    GEN_W_NARROW: if (C_S_AXI_SUPPORTS_NARROW_BURST = 1) and (IF_IS_AXI4) generate
    begin

        axi_awsize_int <= S_AXI_AWSIZE;
        axi_arsize_int <= S_AXI_ARSIZE;


    end generate GEN_W_NARROW;


    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_WO_NARROW
    -- Purpose:     Create internal AWSIZE and ARSIZE signal for write and
    --              read channel modules based on hard coded
    --              value that indicates all AXI transfers will be equal in
    --              size to the AXI data bus.
    --
    ---------------------------------------------------------------------------

    GEN_WO_NARROW: if (C_S_AXI_SUPPORTS_NARROW_BURST = 0) or (IF_IS_AXI4LITE) generate
    begin

        -- axi_awsize_int <= AXI_FIXED_SIZE_WO_NARROW;     -- When AXI-LITE (no narrow transfers supported)
        -- axi_arsize_int <= AXI_FIXED_SIZE_WO_NARROW;

        -- v1.03a
        axi_awsize_int <= std_logic_vector (to_unsigned (AXI_FIXED_SIZE_WO_NARROW, 3));
        axi_arsize_int <= std_logic_vector (to_unsigned (AXI_FIXED_SIZE_WO_NARROW, 3));


    end generate GEN_WO_NARROW;






    S_AXI_ARREADY <= S_AXI_ARREADY_int;
    S_AXI_AWREADY <= S_AXI_AWREADY_int;




    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_AXI_LITE
    -- Purpose:     Create internal signals for lower level write and read
    --              channel modules to discard unused AXI signals when the
    --              AXI protocol is set up for AXI-LITE.
    --
    ---------------------------------------------------------------------------

    GEN_AXI4LITE: if (IF_IS_AXI4LITE) generate
    begin




        -- For simulation purposes ONLY
        -- AXI Interconnect handles this in real system topologies.
        S_AXI_BID <= S_AXI_BID_int;
        S_AXI_RID <= S_AXI_RID_int;


        -----------------------------------------------------------------------
        --
        -- Generate:    GEN_SIM_ONLY
        -- Purpose:     Mimic behavior of AXI Interconnect in simulation.
        --              In real hardware system, AXI Interconnect stores and
        --              wraps value of ARID to RID and AWID to BID.
        --
        -----------------------------------------------------------------------

        GEN_SIM_ONLY: if (C_SIM_ONLY = '1') generate
        begin


            -------------------------------------------------------------------

            -- Must register and wrap the AWID signal
            REG_BID: process (S_AXI_ACLK)
            begin

                if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then

                    if (S_AXI_ARESETN = C_RESET_ACTIVE) then
                        S_AXI_BID_int <= (others => '0');

                    elsif (S_AXI_AWVALID = '1') and (S_AXI_AWREADY_int = '1') then
                        S_AXI_BID_int <= S_AXI_AWID;

                    else
                        S_AXI_BID_int <= S_AXI_BID_int;

                    end if;

                end if;

            end process REG_BID;


            -------------------------------------------------------------------

            -- Must register and wrap the ARID signal
            REG_RID: process (S_AXI_ACLK)
            begin

                if (S_AXI_ACLK'event and S_AXI_ACLK = '1') then

                    if (S_AXI_ARESETN = C_RESET_ACTIVE) then
                        S_AXI_RID_int <= (others => '0');

                    elsif (S_AXI_ARVALID = '1') and (S_AXI_ARREADY_int = '1') then
                        S_AXI_RID_int <= S_AXI_ARID;

                    else
                        S_AXI_RID_int <= S_AXI_RID_int;

                    end if;

                end if;

            end process REG_RID;


            -------------------------------------------------------------------



        end generate GEN_SIM_ONLY;




        ---------------------------------------------------------------------------
        --
        -- Generate:    GEN_HW
        -- Purpose:     Drive default values of RID and BID.  In real system
        --              these are left unconnected and AXI Interconnect is
        --              responsible for values.
        --
        ---------------------------------------------------------------------------

        GEN_HW: if (C_SIM_ONLY = '0') generate
        begin

            S_AXI_BID_int <= (others => '0');
            S_AXI_RID_int <= (others => '0');


        end generate GEN_HW;




        ---------------------------------------------------------------------------
        -- Instance:    I_AXI_LITE
        --
        -- Description:
        --              This module is for the AXI-Lite
        --              instantiation of the BRAM controller interface.
        --
        --              Responsible for shared address pipelining between the
        --              write address (AW) and read address (AR) channels.
        --              Controls (seperately) the data flows for the write data
        --              (W), write response (B), and read data (R) channels.
        --
        --              Creates a shared port to BRAM (for all read and write
        --              transactions) or dual BRAM port utilization based on a
        --              generic parameter setting.
        --
        --              Instantiates ECC register block if enabled and
        --              generates ECC logic, when enabled.
        --
        --
        ---------------------------------------------------------------------------

        I_AXI_LITE : entity work.axi_lite
        generic map (

            C_S_AXI_PROTOCOL                =>  C_S_AXI_PROTOCOL                ,
            C_S_AXI_DATA_WIDTH              =>  C_S_AXI_DATA_WIDTH              ,
            C_S_AXI_ADDR_WIDTH              =>  C_S_AXI_ADDR_WIDTH              ,
            C_SINGLE_PORT_BRAM              =>  C_SINGLE_PORT_BRAM              ,
            --  C_FAMILY                        =>  C_FAMILY                        ,

            C_S_AXI_CTRL_ADDR_WIDTH         =>  C_S_AXI_CTRL_ADDR_WIDTH         ,
            C_S_AXI_CTRL_DATA_WIDTH         =>  C_S_AXI_CTRL_DATA_WIDTH         ,

            C_ECC                           =>  C_ECC                           ,
            C_ECC_TYPE                      =>  C_ECC_TYPE                      ,   -- v1.03a
            C_ECC_WIDTH                     =>  C_ECC_WIDTH                     ,   -- 8-bits for ECC (32 & 64-bit data widths)
            C_ENABLE_AXI_CTRL_REG_IF        =>  C_ENABLE_AXI_CTRL_REG_IF_I      ,   -- Use internal constants determined by C_ECC
            C_FAULT_INJECT                  =>  C_FAULT_INJECT                ,
            C_CE_FAILING_REGISTERS          =>  C_CE_FAILING_REGISTERS_I        ,
            C_UE_FAILING_REGISTERS          =>  C_UE_FAILING_REGISTERS_I        ,
            C_ECC_STATUS_REGISTERS          =>  C_ECC_STATUS_REGISTERS_I        ,
            C_ECC_ONOFF_REGISTER            =>  C_ECC_ONOFF_REGISTER_I          ,
            C_ECC_ONOFF_RESET_VALUE         =>  C_ECC_ONOFF_RESET_VALUE         ,
            C_CE_COUNTER_WIDTH              =>  C_CE_COUNTER_WIDTH

        )
        port map (

            S_AXI_AClk              =>  S_AXI_ACLK          ,
            S_AXI_AResetn           =>  S_AXI_ARESETN       ,
            ECC_Interrupt           =>  ECC_Interrupt       ,
            ECC_UE                  =>  ECC_UE              ,

            AXI_AWADDR              =>  S_AXI_AWADDR        ,
            AXI_AWVALID             =>  S_AXI_AWVALID       ,
            AXI_AWREADY             =>  S_AXI_AWREADY_int   ,

            AXI_WDATA               =>  S_AXI_WDATA         ,
            AXI_WSTRB               =>  S_AXI_WSTRB         ,
            AXI_WVALID              =>  S_AXI_WVALID        ,
            AXI_WREADY              =>  S_AXI_WREADY        ,

            AXI_BRESP               =>  S_AXI_BRESP         ,
            AXI_BVALID              =>  S_AXI_BVALID        ,
            AXI_BREADY              =>  S_AXI_BREADY        ,

            AXI_ARADDR              =>  S_AXI_ARADDR        ,
            AXI_ARVALID             =>  S_AXI_ARVALID       ,
            AXI_ARREADY             =>  S_AXI_ARREADY_int   ,

            AXI_RDATA               =>  S_AXI_RDATA         ,
            AXI_RRESP               =>  S_AXI_RRESP         ,
            AXI_RLAST               =>  S_AXI_RLAST         ,
            AXI_RVALID              =>  S_AXI_RVALID        ,
            AXI_RREADY              =>  S_AXI_RREADY        ,


            -- Add AXI-Lite ECC Register Ports
            -- Note: AXI-Lite Control IF and AXI IF share the same clock.
            -- S_AXI_CTRL_ACLK         =>  S_AXI_CTRL_ACLK        ,
            -- S_AXI_CTRL_ARESETN      =>  S_AXI_CTRL_ARESETN     ,

            AXI_CTRL_AWVALID        =>  S_AXI_CTRL_AWVALID     ,
            AXI_CTRL_AWREADY        =>  S_AXI_CTRL_AWREADY     ,
            AXI_CTRL_AWADDR         =>  S_AXI_CTRL_AWADDR      ,

            AXI_CTRL_WDATA          =>  S_AXI_CTRL_WDATA       ,
            AXI_CTRL_WVALID         =>  S_AXI_CTRL_WVALID      ,
            AXI_CTRL_WREADY         =>  S_AXI_CTRL_WREADY      ,

            AXI_CTRL_BRESP          =>  S_AXI_CTRL_BRESP       ,
            AXI_CTRL_BVALID         =>  S_AXI_CTRL_BVALID      ,
            AXI_CTRL_BREADY         =>  S_AXI_CTRL_BREADY      ,

            AXI_CTRL_ARADDR         =>  S_AXI_CTRL_ARADDR      ,
            AXI_CTRL_ARVALID        =>  S_AXI_CTRL_ARVALID     ,
            AXI_CTRL_ARREADY        =>  S_AXI_CTRL_ARREADY     ,

            AXI_CTRL_RDATA          =>  S_AXI_CTRL_RDATA       ,
            AXI_CTRL_RRESP          =>  S_AXI_CTRL_RRESP       ,
            AXI_CTRL_RVALID         =>  S_AXI_CTRL_RVALID      ,
            AXI_CTRL_RREADY         =>  S_AXI_CTRL_RREADY      ,


            BRAM_En_A               =>  bram_en_a_int          ,
            BRAM_WE_A               =>  bram_we_a_int          ,
            BRAM_Addr_A             =>  bram_addr_a_int        ,
            BRAM_WrData_A           =>  bram_wrdata_a_int      ,
            BRAM_RdData_A           =>  bram_rddata_a_int      ,

            BRAM_En_B               =>  bram_en_b_int          ,
            BRAM_WE_B               =>  bram_we_b_int          ,
            BRAM_Addr_B             =>  bram_addr_b_int        ,
            BRAM_WrData_B           =>  bram_wrdata_b_int      ,
            BRAM_RdData_B           =>  bram_rddata_b_int


        );




    end generate GEN_AXI4LITE;








    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_AXI
    -- Purpose:     Only create internal signals for lower level write and read
    --              channel modules to assign AXI signals when the
    --              AXI protocol is set up for non AXI-LITE IF connections.
    --              For AXI4, all AXI signals are assigned to lower level modules.
    --
    --              For AXI-Lite connections, generate statement above will
    --              create default values on these signals (assigned here).
    --
    ---------------------------------------------------------------------------

    GEN_AXI4: if (IF_IS_AXI4) generate
    begin





        ---------------------------------------------------------------------------
        -- Instance: I_FULL_AXI
        --
        -- Description:
        --  Full AXI BRAM controller logic.
        --  Instantiates wr_chnl and rd_chnl modules.
        --  If enabled, ECC register interface is included.
        --
        ---------------------------------------------------------------------------

        I_FULL_AXI : entity work.full_axi
        generic map (

            C_S_AXI_ID_WIDTH                =>  C_S_AXI_ID_WIDTH                ,
            C_S_AXI_DATA_WIDTH              =>  C_S_AXI_DATA_WIDTH              ,
            C_S_AXI_ADDR_WIDTH              =>  C_S_AXI_ADDR_WIDTH              ,
            C_S_AXI_PROTOCOL                =>  C_S_AXI_PROTOCOL                ,
            C_SINGLE_PORT_BRAM              =>  C_SINGLE_PORT_BRAM              ,
            C_S_AXI_SUPPORTS_NARROW_BURST   =>  C_S_AXI_SUPPORTS_NARROW_BURST   ,

            C_S_AXI_CTRL_ADDR_WIDTH         =>  C_S_AXI_CTRL_ADDR_WIDTH         ,
            C_S_AXI_CTRL_DATA_WIDTH         =>  C_S_AXI_CTRL_DATA_WIDTH         ,

            C_ECC                           =>  C_ECC                           ,
            C_ECC_WIDTH                     =>  C_ECC_WIDTH                     ,   -- 8-bits for ECC (32 & 64-bit data widths)
            C_ECC_TYPE                      =>  C_ECC_TYPE                      ,   -- v1.03a
            C_FAULT_INJECT                  =>  C_FAULT_INJECT                  ,
            C_ECC_ONOFF_RESET_VALUE         =>  C_ECC_ONOFF_RESET_VALUE         ,

            C_ENABLE_AXI_CTRL_REG_IF        =>  C_ENABLE_AXI_CTRL_REG_IF_I      ,   -- Use internal constants determined by C_ECC
            C_CE_FAILING_REGISTERS          =>  C_CE_FAILING_REGISTERS_I        ,
            C_UE_FAILING_REGISTERS          =>  C_UE_FAILING_REGISTERS_I        ,
            C_ECC_STATUS_REGISTERS          =>  C_ECC_STATUS_REGISTERS_I        ,
            C_ECC_ONOFF_REGISTER            =>  C_ECC_ONOFF_REGISTER_I          ,
            C_CE_COUNTER_WIDTH              =>  C_CE_COUNTER_WIDTH

        )
        port map (

            S_AXI_AClk                  =>  S_AXI_ACLK          ,
            S_AXI_AResetn               =>  S_AXI_ARESETN       ,

            ECC_Interrupt               =>  ECC_Interrupt       ,
            ECC_UE                      =>  ECC_UE              ,

            S_AXI_AWID                  =>  S_AXI_AWID          ,
            S_AXI_AWADDR                =>  S_AXI_AWADDR(C_S_AXI_ADDR_WIDTH-1 downto 0),

            S_AXI_AWLEN                 =>  S_AXI_AWLEN         ,
            S_AXI_AWSIZE                =>  axi_awsize_int      ,
            S_AXI_AWBURST               =>  S_AXI_AWBURST       ,
            S_AXI_AWLOCK                =>  S_AXI_AWLOCK        ,
            S_AXI_AWCACHE               =>  S_AXI_AWCACHE       ,
            S_AXI_AWPROT                =>  S_AXI_AWPROT        ,
            S_AXI_AWVALID               =>  S_AXI_AWVALID       ,
            S_AXI_AWREADY               =>  S_AXI_AWREADY_int   ,

            S_AXI_WDATA                 =>  S_AXI_WDATA         ,
            S_AXI_WSTRB                 =>  S_AXI_WSTRB         ,
            S_AXI_WLAST                 =>  S_AXI_WLAST         ,
            S_AXI_WVALID                =>  S_AXI_WVALID        ,
            S_AXI_WREADY                =>  S_AXI_WREADY        ,

            S_AXI_BID                   =>  S_AXI_BID           ,
            S_AXI_BRESP                 =>  S_AXI_BRESP         ,
            S_AXI_BVALID                =>  S_AXI_BVALID        ,
            S_AXI_BREADY                =>  S_AXI_BREADY        ,


            S_AXI_ARID                  =>  S_AXI_ARID            ,
            S_AXI_ARADDR                =>  S_AXI_ARADDR(C_S_AXI_ADDR_WIDTH-1 downto 0),

            S_AXI_ARLEN                 =>  S_AXI_ARLEN           ,
            S_AXI_ARSIZE                =>  axi_arsize_int        ,
            S_AXI_ARBURST               =>  S_AXI_ARBURST         ,
            S_AXI_ARLOCK                =>  S_AXI_ARLOCK          ,
            S_AXI_ARCACHE               =>  S_AXI_ARCACHE         ,
            S_AXI_ARPROT                =>  S_AXI_ARPROT          ,
            S_AXI_ARVALID               =>  S_AXI_ARVALID         ,
            S_AXI_ARREADY               =>  S_AXI_ARREADY_int     ,

            S_AXI_RID                   =>  S_AXI_RID             ,
            S_AXI_RDATA                 =>  S_AXI_RDATA           ,
            S_AXI_RRESP                 =>  S_AXI_RRESP           ,
            S_AXI_RLAST                 =>  S_AXI_RLAST           ,
            S_AXI_RVALID                =>  S_AXI_RVALID          ,
            S_AXI_RREADY                =>  S_AXI_RREADY          ,


            -- Add AXI-Lite ECC Register Ports
            -- Note: AXI-Lite Control IF and AXI IF share the same clock.
            -- S_AXI_CTRL_ACLK             =>  S_AXI_CTRL_ACLK        ,
            -- S_AXI_CTRL_ARESETN          =>  S_AXI_CTRL_ARESETN     ,

            S_AXI_CTRL_AWVALID          =>  S_AXI_CTRL_AWVALID     ,
            S_AXI_CTRL_AWREADY          =>  S_AXI_CTRL_AWREADY     ,
            S_AXI_CTRL_AWADDR           =>  S_AXI_CTRL_AWADDR      ,

            S_AXI_CTRL_WDATA            =>  S_AXI_CTRL_WDATA       ,
            S_AXI_CTRL_WVALID           =>  S_AXI_CTRL_WVALID      ,
            S_AXI_CTRL_WREADY           =>  S_AXI_CTRL_WREADY      ,

            S_AXI_CTRL_BRESP            =>  S_AXI_CTRL_BRESP       ,
            S_AXI_CTRL_BVALID           =>  S_AXI_CTRL_BVALID      ,
            S_AXI_CTRL_BREADY           =>  S_AXI_CTRL_BREADY      ,

            S_AXI_CTRL_ARADDR           =>  S_AXI_CTRL_ARADDR      ,
            S_AXI_CTRL_ARVALID          =>  S_AXI_CTRL_ARVALID     ,
            S_AXI_CTRL_ARREADY          =>  S_AXI_CTRL_ARREADY     ,

            S_AXI_CTRL_RDATA            =>  S_AXI_CTRL_RDATA       ,
            S_AXI_CTRL_RRESP            =>  S_AXI_CTRL_RRESP       ,
            S_AXI_CTRL_RVALID           =>  S_AXI_CTRL_RVALID      ,
            S_AXI_CTRL_RREADY           =>  S_AXI_CTRL_RREADY      ,


            BRAM_En_A                   =>  bram_en_a_int          ,
            BRAM_WE_A                   =>  bram_we_a_int          ,
            BRAM_WrData_A               =>  bram_wrdata_a_int      ,
            BRAM_Addr_A                 =>  bram_addr_a_int        ,
            BRAM_RdData_A               =>  bram_rddata_a_int (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0) ,

            BRAM_En_B                   =>  bram_en_b_int          ,
            BRAM_WE_B                   =>  bram_we_b_int          ,
            BRAM_Addr_B                 =>  bram_addr_b_int        ,
            BRAM_WrData_B               =>  bram_wrdata_b_int      ,
            BRAM_RdData_B               =>  bram_rddata_b_int (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0)

        );




    -- v1.02a
    -- Seperate instantiations for wr_chnl and rd_chnl moved to
    -- full_axi module.



    end generate GEN_AXI4;





end architecture implementation;











