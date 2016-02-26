-------------------------------------------------------------------------------
-- axi_bram_ctrl.vhd
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
-- Filename:        axi_bram_ctrl_wrapper.vhd
--
-- Description:     This file is the top level module for the AXI BRAM
--                  controller IP core.
--
-- VHDL-Standard:   VHDL'93
--
-------------------------------------------------------------------------------
-- Structure:
--              axi_bram_ctrl.vhd (v4_0)
--                  |
--                  |--axi_bram_ctrl_top.vhd
--                         |
--                         |-- full_axi.vhd
--                         |   -- sng_port_arb.vhd
--                         |   -- lite_ecc_reg.vhd
--                         |       -- axi_lite_if.vhd
--                         |   -- wr_chnl.vhd
--                         |       -- wrap_brst.vhd
--                         |       -- ua_narrow.vhd
--                         |       -- checkbit_handler.vhd
--                         |           -- xor18.vhd
--                         |           -- parity.vhd
--                         |       -- checkbit_handler_64.vhd
--                         |           -- (same helper components as checkbit_handler)
--                         |       -- parity.vhd
--                         |       -- correct_one_bit.vhd
--                         |       -- correct_one_bit_64.vhd
--                         |       -- ecc_gen.vhd
--                         |
--                         |   -- rd_chnl.vhd
--                         |       -- wrap_brst.vhd
--                         |       -- ua_narrow.vhd
--                         |       -- checkbit_handler.vhd
--                         |           -- xor18.vhd
--                         |           -- parity.vhd
--                         |       -- checkbit_handler_64.vhd
--                         |           -- (same helper components as checkbit_handler)
--                         |       -- parity.vhd
--                         |       -- correct_one_bit.vhd
--                         |       -- correct_one_bit_64.vhd
--                         |       -- ecc_gen.vhd
--                         |
--                         |-- axi_lite.vhd
--                         |   -- lite_ecc_reg.vhd
--                         |       -- axi_lite_if.vhd
--                         |   -- checkbit_handler.vhd
--                         |       -- xor18.vhd
--                         |       -- parity.vhd
--                         |   -- correct_one_bit.vhd
--                         |   -- ecc_gen.vhd
--
-------------------------------------------------------------------------------
-- Library declarations

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;

library work;
use work.axi_bram_ctrl_top;
use work.axi_bram_ctrl_funcs.all;
--use work.coregen_comp_defs.all;
library blk_mem_gen_v8_3_0;
use blk_mem_gen_v8_3_0.all;

------------------------------------------------------------------------------

entity axi_bram_ctrl is
generic (

    C_BRAM_INST_MODE  : string := "EXTERNAL"; -- external ; internal
        --determines whether the bmg is external or internal to axi bram ctrl wrapper

    C_MEMORY_DEPTH  : integer := 4096;
        --Memory depth specified by the user

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

     C_FAMILY : string := "virtex7";
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
       );
  port (
    -- AXI Interface Signals

    -- AXI Clock and Reset
    s_axi_aclk              : in    std_logic;
    s_axi_aresetn           : in    std_logic;

    ecc_interrupt           : out   std_logic := '0';
    ecc_ue                  : out   std_logic := '0';

    -- axi write address channel Signals (AW)
    s_axi_awid              : in    std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    s_axi_awaddr            : in    std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_awlen             : in    std_logic_vector(7 downto 0);
    s_axi_awsize            : in    std_logic_vector(2 downto 0);
    s_axi_awburst           : in    std_logic_vector(1 downto 0);
    s_axi_awlock            : in    std_logic;
    s_axi_awcache           : in    std_logic_vector(3 downto 0);
    s_axi_awprot            : in    std_logic_vector(2 downto 0);
    s_axi_awvalid           : in    std_logic;
    s_axi_awready           : out   std_logic;

    -- axi write data channel Signals (W)
    s_axi_wdata             : in    std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_wstrb             : in    std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
    s_axi_wlast             : in    std_logic;

    s_axi_wvalid            : in    std_logic;
    s_axi_wready            : out   std_logic;

    -- axi write data response Channel Signals (B)
    s_axi_bid               : out   std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    s_axi_bresp             : out   std_logic_vector(1 downto 0);

    s_axi_bvalid            : out   std_logic;
    s_axi_bready            : in    std_logic;

    -- axi read address channel Signals (AR)
    s_axi_arid              : in    std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    s_axi_araddr            : in    std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_arlen             : in    std_logic_vector(7 downto 0);
    s_axi_arsize            : in    std_logic_vector(2 downto 0);
    s_axi_arburst           : in    std_logic_vector(1 downto 0);
    s_axi_arlock            : in    std_logic;
    s_axi_arcache           : in    std_logic_vector(3 downto 0);
    s_axi_arprot            : in    std_logic_vector(2 downto 0);

    s_axi_arvalid           : in    std_logic;
    s_axi_arready           : out   std_logic;

    -- axi read data channel Signals (R)
    s_axi_rid               : out   std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    s_axi_rdata             : out   std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_rresp             : out   std_logic_vector(1 downto 0);
    s_axi_rlast             : out   std_logic;

    s_axi_rvalid            : out   std_logic;
    s_axi_rready            : in    std_logic;

    -- axi-lite ecc register Interface Signals

    -- axi-lite clock and Reset
    -- note: axi-lite control IF and AXI IF share the same clock.
    -- s_axi_ctrl_aclk             : in    std_logic;
    -- s_axi_ctrl_aresetn          : in    std_logic;

    -- axi-lite write address Channel Signals (AW)
    s_axi_ctrl_awvalid          : in    std_logic;
    s_axi_ctrl_awready          : out   std_logic;
    s_axi_ctrl_awaddr           : in    std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);

    -- axi-lite write data Channel Signals (W)
    s_axi_ctrl_wdata            : in    std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    s_axi_ctrl_wvalid           : in    std_logic;
    s_axi_ctrl_wready           : out   std_logic;

    -- axi-lite write data Response Channel Signals (B)
    s_axi_ctrl_bresp            : out   std_logic_vector(1 downto 0);
    s_axi_ctrl_bvalid           : out   std_logic;
    s_axi_ctrl_bready           : in    std_logic;

    -- axi-lite read address Channel Signals (AR)
    s_axi_ctrl_araddr           : in    std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
    s_axi_ctrl_arvalid          : in    std_logic;
    s_axi_ctrl_arready          : out   std_logic;

    -- axi-lite read data Channel Signals (R)
    s_axi_ctrl_rdata             : out   std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    s_axi_ctrl_rresp             : out   std_logic_vector(1 downto 0);
    s_axi_ctrl_rvalid            : out   std_logic;
    s_axi_ctrl_rready            : in    std_logic;

    -- bram interface signals (Port A)
    bram_rst_a              : out   std_logic;
    bram_clk_a              : out   std_logic;
    bram_en_a               : out   std_logic;
    bram_we_a               : out   std_logic_vector (C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);
    bram_addr_a             : out   std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0);
    bram_wrdata_a           : out   std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);
    bram_rddata_a           : in    std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);

    -- bram interface signals (Port B)
    bram_rst_b              : out   std_logic;
    bram_clk_b              : out   std_logic;
    bram_en_b               : out   std_logic;
    bram_we_b               : out   std_logic_vector (C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);
    bram_addr_b             : out   std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0);
    bram_wrdata_b           : out   std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);
    bram_rddata_b           : in    std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0)
    );

end entity axi_bram_ctrl;

-------------------------------------------------------------------------------
architecture implementation of axi_bram_ctrl is

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of implementation : architecture is "yes";

  ------------------------------------------------------------------------------
  -- FUNCTION: if_then_else
  -- This function is used to implement an IF..THEN when such a statement is not
  --  allowed.
  ------------------------------------------------------------------------------
  FUNCTION if_then_else (
    condition : BOOLEAN;
    true_case : INTEGER;
    false_case : INTEGER)
  RETURN INTEGER IS
    VARIABLE retval : INTEGER := 0;
  BEGIN
    IF NOT condition THEN
      retval:=false_case;
    ELSE
      retval:=true_case;
    END IF;
    RETURN retval;
  END if_then_else;

  ---------------------------------------------------------------------------
  -- FUNCTION : log2roundup
  ---------------------------------------------------------------------------
  FUNCTION log2roundup (data_value : integer) RETURN integer IS
    VARIABLE width       : integer := 0;
    VARIABLE cnt         : integer := 1;
    CONSTANT lower_limit : integer := 1;
    CONSTANT upper_limit : integer := 8;
  BEGIN
    IF (data_value <= 1) THEN
      width   := 0;
    ELSE
      WHILE (cnt < data_value) LOOP
        width := width + 1;
        cnt   := cnt *2;
      END LOOP;
    END IF;
    RETURN width;
  END log2roundup;


-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- Only instantiate logic based on C_S_AXI_PROTOCOL.

-- Determine external ECC width.
-- Use function defined in axi_bram_ctrl_funcs package.

-- Set internal parameters for ECC register enabling when C_ECC = 1
                                                            -- Catastrophic error indicated with ECC_UE & Interrupt flags.

-- Counter only sized when C_ECC = 1.
-- Selects CE counter width/threshold to assert ECC_Interrupt
-- Hard coded at 8-bits to capture and count up to 256 correctable errors.

-- ECC algorithm format, 0 = Hamming code, 1 = Hsiao code

constant GND : std_logic := '0';
constant VCC : std_logic := '1';

constant ZERO1 : std_logic_vector(0 downto 0) := (others => '0');
constant ZERO2 : std_logic_vector(1 downto 0) := (others => '0');
constant ZERO3 : std_logic_vector(2 downto 0) := (others => '0');
constant ZERO4 : std_logic_vector(3 downto 0) := (others => '0');
constant ZERO8 : std_logic_vector(7 downto 0) := (others => '0');
constant WSTRB_ZERO : std_logic_vector(C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0) := (others => '0');
constant ZERO16 : std_logic_vector(15 downto 0) := (others => '0');
constant ZERO32 : std_logic_vector(31 downto 0) := (others => '0');
constant ZERO64 : std_logic_vector(C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0) := (others => '0');

CONSTANT MEM_TYPE : INTEGER := if_then_else((C_SINGLE_PORT_BRAM=1),0,2);
CONSTANT BWE_B : INTEGER := if_then_else((C_SINGLE_PORT_BRAM=1),0,1);
CONSTANT BMG_ADDR_WIDTH : INTEGER :=  log2roundup(C_MEMORY_DEPTH) + log2roundup(C_S_AXI_DATA_WIDTH/8) ;
-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------
signal clka_bram_clka_i      :  std_logic := '0';
signal rsta_bram_rsta_i      :  std_logic := '0';
signal ena_bram_ena_i        :  std_logic := '0';
signal REGCEA                :  std_logic := '0';
signal wea_bram_wea_i        :  std_logic_vector(C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0) := (others => '0');
signal addra_bram_addra_i    :  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
signal dina_bram_dina_i      :  std_logic_vector(C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0) := (others => '0');
signal douta_bram_douta_i    :  std_logic_vector(C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);

signal clkb_bram_clkb_i      :  std_logic := '0';
signal rstb_bram_rstb_i      :  std_logic := '0';
signal enb_bram_enb_i        :  std_logic := '0';
signal REGCEB                :  std_logic := '0';
signal web_bram_web_i        :  std_logic_vector(C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0) := (others => '0');
signal addrb_bram_addrb_i    :  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
signal dinb_bram_dinb_i      :  std_logic_vector(C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0) := (others => '0');
signal doutb_bram_doutb_i    :  std_logic_vector(C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);


-----------------------------------------------------------------------
-- Architecture Body
-----------------------------------------------------------------------

begin

gint_inst: IF (C_BRAM_INST_MODE = "INTERNAL" ) GENERATE

constant c_addrb_width    : INTEGER := log2roundup(C_MEMORY_DEPTH);
constant C_WEA_WIDTH_I    : INTEGER := (C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128))) ;
constant C_WRITE_WIDTH_A_I  : INTEGER := (C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))) ;
constant C_READ_WIDTH_A_I : INTEGER := (C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128)));
constant C_ADDRA_WIDTH_I  : INTEGER := log2roundup(C_MEMORY_DEPTH);
constant C_WEB_WIDTH_I     : INTEGER := (C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128)));
constant C_WRITE_WIDTH_B_I : INTEGER := (C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128)));
constant C_READ_WIDTH_B_I  : INTEGER := (C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128)));

signal s_axi_rdaddrecc_bmg_int : STD_LOGIC_VECTOR(c_addrb_width-1 DOWNTO 0);
signal s_axi_dbiterr_bmg_int : STD_LOGIC;
signal s_axi_sbiterr_bmg_int : STD_LOGIC;
signal s_axi_rvalid_bmg_int : STD_LOGIC;
signal s_axi_rlast_bmg_int : STD_LOGIC;
signal s_axi_rresp_bmg_int : STD_LOGIC_VECTOR(1 DOWNTO 0);
signal s_axi_rdata_bmg_int : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0); 
signal s_axi_rid_bmg_int : STD_LOGIC_VECTOR(3 DOWNTO 0);
signal s_axi_arready_bmg_int : STD_LOGIC;
signal s_axi_bvalid_bmg_int : STD_LOGIC;
signal s_axi_bresp_bmg_int : STD_LOGIC_VECTOR(1 DOWNTO 0);
signal s_axi_bid_bmg_int : STD_LOGIC_VECTOR(3 DOWNTO 0);
signal s_axi_wready_bmg_int : STD_LOGIC;
signal s_axi_awready_bmg_int : STD_LOGIC;
signal rdaddrecc_bmg_int : STD_LOGIC_VECTOR(c_addrb_width-1 DOWNTO 0);
signal dbiterr_bmg_int : STD_LOGIC;
signal sbiterr_bmg_int : STD_LOGIC;

begin

bmgv81_inst : entity blk_mem_gen_v8_3_0.blk_mem_gen_v8_3_0

  GENERIC MAP(
  ----------------------------------------------------------------------------
  -- Generic Declarations
  ----------------------------------------------------------------------------
  --Device Family & Elaboration Directory Parameters:
    C_FAMILY                   => C_FAMILY,
    C_XDEVICEFAMILY            => C_FAMILY,
----    C_ELABORATION_DIR          => "NULL"                          ,
  
    C_INTERFACE_TYPE           => 0                           ,
  --General Memory Parameters:  
-----    C_ENABLE_32BIT_ADDRESS     => 0      ,
    C_MEM_TYPE                 => MEM_TYPE                  ,
    C_BYTE_SIZE                => 8                 ,
    C_ALGORITHM                => 1                 ,
    C_PRIM_TYPE                => 1                 ,
  
  --Memory Initialization Parameters:
    C_LOAD_INIT_FILE           => 0            ,
    C_INIT_FILE_NAME           => "no_coe_file_loaded"            ,
    C_USE_DEFAULT_DATA         => 0          ,
    C_DEFAULT_DATA             => "NULL"              ,
  
  --Port A Parameters:
    --Reset Parameters:
    C_HAS_RSTA                 => 0                  ,
  
    --Enable Parameters:
    C_HAS_ENA                  => 1                   ,
    C_HAS_REGCEA               => 0                ,
  
    --Byte Write Enable Parameters:
    C_USE_BYTE_WEA             => 1              ,
    C_WEA_WIDTH                => C_WEA_WIDTH_I, --(C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128)))                 ,
  
    --Write Mode:
    C_WRITE_MODE_A             => "WRITE_FIRST"              ,
  
    --Data-Addr Width Parameters:
    C_WRITE_WIDTH_A            => C_WRITE_WIDTH_A_I,--(C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128)))             ,
    C_READ_WIDTH_A             => C_READ_WIDTH_A_I,--(C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128)))              ,
    C_WRITE_DEPTH_A            => C_MEMORY_DEPTH             ,
    C_READ_DEPTH_A             => C_MEMORY_DEPTH             ,
    C_ADDRA_WIDTH              => C_ADDRA_WIDTH_I,--log2roundup(C_MEMORY_DEPTH)               ,
  
  --Port B Parameters:
    --Reset Parameters:
    C_HAS_RSTB                 => 0                  ,
  
    --Enable Parameters:
    C_HAS_ENB                  => 1                   ,
    C_HAS_REGCEB               => 0               ,
  
    --Byte Write Enable Parameters:
    C_USE_BYTE_WEB             => BWE_B              ,
    C_WEB_WIDTH                => C_WEB_WIDTH_I,--(C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128)))                 ,
  
    --Write Mode:
    C_WRITE_MODE_B             => "WRITE_FIRST"              ,
  
    --Data-Addr Width Parameters:
    C_WRITE_WIDTH_B            => C_WRITE_WIDTH_B_I,--(C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128)))             ,
    C_READ_WIDTH_B             => C_READ_WIDTH_B_I,--(C_S_AXI_DATA_WIDTH+C_ECC*8*(1+(C_S_AXI_DATA_WIDTH/128)))              ,
    C_WRITE_DEPTH_B            => C_MEMORY_DEPTH             ,
    C_READ_DEPTH_B             => C_MEMORY_DEPTH              ,
    C_ADDRB_WIDTH              => C_ADDRB_WIDTH,--log2roundup(C_MEMORY_DEPTH)               ,
  
  --Output Registers/ Pipelining Parameters:
    C_HAS_MEM_OUTPUT_REGS_A    => 0     ,
    C_HAS_MEM_OUTPUT_REGS_B    => 0     ,
    C_HAS_MUX_OUTPUT_REGS_A    => 0     ,
    C_HAS_MUX_OUTPUT_REGS_B    => 0     ,
    C_MUX_PIPELINE_STAGES      => 0      ,

   --Input/Output Registers for SoftECC :
    C_HAS_SOFTECC_INPUT_REGS_A => 0  ,
    C_HAS_SOFTECC_OUTPUT_REGS_B=> 0 ,
  
  --ECC Parameters
    C_USE_ECC                  => 0                  ,
    C_USE_SOFTECC              => 0              ,
    C_HAS_INJECTERR            => 0             ,
    C_EN_ECC_PIPE              => 0,
	C_EN_SLEEP_PIN             => 0,
	C_USE_URAM                 => 0, 
	C_EN_RDADDRA_CHG           => 0,
	C_EN_RDADDRB_CHG           => 0,
	C_EN_DEEPSLEEP_PIN         => 0,
	C_EN_SHUTDOWN_PIN          => 0,  
  --Simulation Model Parameters:
    C_SIM_COLLISION_CHECK      => "NONE"       ,
    C_COMMON_CLK               => 1                ,
    C_DISABLE_WARN_BHV_COLL    => 1     ,
    C_DISABLE_WARN_BHV_RANGE   => 1    
  ) 
  PORT MAP(
  ----------------------------------------------------------------------------
  -- Input and Output Declarations
  ----------------------------------------------------------------------------
  -- Native BMG Input and Output Port Declarations
  --Port A:
    clka                            => clka_bram_clka_i               ,
    rsta                            => rsta_bram_rsta_i              ,
    ena                             => ena_bram_ena_i                ,
    regcea                          => GND                           ,
    wea                             => wea_bram_wea_i                ,
    addra                           => addra_bram_addra_i(BMG_ADDR_WIDTH-1 downto (BMG_ADDR_WIDTH - C_BRAM_ADDR_WIDTH))            ,
    --addra                           => addra_bram_addra_i(C_S_AXI_ADDR_WIDTH-1 downto (C_S_AXI_ADDR_WIDTH - C_BRAM_ADDR_WIDTH))            ,
    dina                            => dina_bram_dina_i              ,
    douta                           => douta_bram_douta_i            ,
  
  --port b:
    clkb                            => clkb_bram_clkb_i              ,
    rstb                            => rstb_bram_rstb_i              ,
    enb                             => enb_bram_enb_i                ,
    regceb                          => GND                           ,
    web                             => web_bram_web_i                ,
    addrb                           => addrb_bram_addrb_i(BMG_ADDR_WIDTH-1 downto (BMG_ADDR_WIDTH - C_BRAM_ADDR_WIDTH))            ,
    --addrb                           => addrb_bram_addrb_i(C_S_AXI_ADDR_WIDTH-1 downto (C_S_AXI_ADDR_WIDTH - C_BRAM_ADDR_WIDTH))            ,
    dinb                            => dinb_bram_dinb_i              ,
    doutb                           => doutb_bram_doutb_i            ,
  
  --ecc:
    injectsbiterr                   => GND                           ,
    injectdbiterr                   => GND                           ,
    sbiterr                         => sbiterr_bmg_int,
    dbiterr                         => dbiterr_bmg_int,
    rdaddrecc                       => rdaddrecc_bmg_int,
    eccpipece                       => GND,
	sleep                           => GND,
	deepsleep                       => GND,
	shutdown                        => GND,   
   -- axi bmg input and output Port Declarations

    -- axi global signals
    s_aclk                        => GND                             ,
    s_aresetn                     => GND                             ,

    -- axi full/lite slave write (write side)
    s_axi_awid                    => ZERO4                           ,
    s_axi_awaddr                  => ZERO32                          ,
    s_axi_awlen                   => ZERO8                           ,
    s_axi_awsize                  => ZERO3                           ,
    s_axi_awburst                 => ZERO2                           ,
    s_axi_awvalid                 => GND                             ,
    s_axi_awready                 => s_axi_awready_bmg_int,
    s_axi_wdata                   => ZERO64                          ,
    s_axi_wstrb                   => WSTRB_ZERO,
    s_axi_wlast                   => GND                             ,
    s_axi_wvalid                  => GND                             ,
    s_axi_wready                  => s_axi_wready_bmg_int,
    s_axi_bid                     => s_axi_bid_bmg_int,
    s_axi_bresp                   => s_axi_bresp_bmg_int,
    s_axi_bvalid                  => s_axi_bvalid_bmg_int,
    s_axi_bready                  => GND                             ,

    -- axi full/lite slave read (Write side)
    s_axi_arid                    => ZERO4,
    s_axi_araddr                  => "00000000000000000000000000000000",
    s_axi_arlen                   => "00000000",
    s_axi_arsize                  => "000",
    s_axi_arburst                 => "00",
    s_axi_arvalid                 => '0',
    s_axi_arready                 => s_axi_arready_bmg_int,
    s_axi_rid                     => s_axi_rid_bmg_int,
    s_axi_rdata                   => s_axi_rdata_bmg_int,
    s_axi_rresp                   => s_axi_rresp_bmg_int,
    s_axi_rlast                   => s_axi_rlast_bmg_int,
    s_axi_rvalid                  => s_axi_rvalid_bmg_int,
    s_axi_rready                  => GND                             ,

    -- axi full/lite sideband Signals
    s_axi_injectsbiterr           => GND                             ,
    s_axi_injectdbiterr           => GND                             ,
    s_axi_sbiterr                 => s_axi_sbiterr_bmg_int,
    s_axi_dbiterr                 => s_axi_dbiterr_bmg_int,
    s_axi_rdaddrecc               => s_axi_rdaddrecc_bmg_int
  );


abcv4_0_int_inst : entity work.axi_bram_ctrl_top
generic map(

    -- AXI Parameters

    C_BRAM_ADDR_WIDTH  => C_BRAM_ADDR_WIDTH                        ,

    C_S_AXI_ADDR_WIDTH  => C_S_AXI_ADDR_WIDTH                        ,
        -- Width of AXI address bus (in bits)

    C_S_AXI_DATA_WIDTH  => C_S_AXI_DATA_WIDTH                        ,
        -- Width of AXI data bus (in bits)

    C_S_AXI_ID_WIDTH    => C_S_AXI_ID_WIDTH                                ,
        --  AXI ID vector width

    C_S_AXI_PROTOCOL    => C_S_AXI_PROTOCOL                          ,
        -- Set to AXI4LITE to optimize out burst transaction support

    C_S_AXI_SUPPORTS_NARROW_BURST => C_S_AXI_SUPPORTS_NARROW_BURST   ,
        -- Support for narrow burst operations

    C_SINGLE_PORT_BRAM  => C_SINGLE_PORT_BRAM                        ,
        -- Enable single port usage of BRAM

    -- AXI-Lite Register Parameters
    C_S_AXI_CTRL_ADDR_WIDTH  => C_S_AXI_CTRL_ADDR_WIDTH              ,
        -- Width of AXI-Lite address bus (in bits)

    C_S_AXI_CTRL_DATA_WIDTH  => C_S_AXI_CTRL_DATA_WIDTH              ,
        -- Width of AXI-Lite data bus (in bits)

    -- ECC Parameters

    C_ECC => C_ECC                                                   ,
        -- Enables or disables ECC functionality
    C_ECC_TYPE                      =>  C_ECC_TYPE                      ,   

    C_FAULT_INJECT => C_FAULT_INJECT                                 ,
        -- Enable fault injection registers
        -- (default = disabled)

    C_ECC_ONOFF_RESET_VALUE => C_ECC_ONOFF_RESET_VALUE               
        -- By default, ECC checking is on
        -- (can disable ECC @ reset by setting this to 0)
       )
  port map(

    -- AXI Interface Signals

    -- AXI Clock and Reset
    S_AXI_ACLK              => S_AXI_ACLK                            ,
    S_AXI_ARESETN           => S_AXI_ARESETN                         ,

    ECC_Interrupt           => ECC_Interrupt                         ,
    ECC_UE                  => ECC_UE                                ,

    -- AXI Write Address Channel Signals (AW)
    S_AXI_AWID              => S_AXI_AWID                            ,
    S_AXI_AWADDR            => S_AXI_AWADDR                          ,
    S_AXI_AWLEN             => S_AXI_AWLEN                           ,
    S_AXI_AWSIZE            => S_AXI_AWSIZE                          , 
    S_AXI_AWBURST           => S_AXI_AWBURST                         ,
    S_AXI_AWLOCK            => S_AXI_AWLOCK                          , 
    S_AXI_AWCACHE           => S_AXI_AWCACHE                         ,
    S_AXI_AWPROT            => S_AXI_AWPROT                          ,
    S_AXI_AWVALID           => S_AXI_AWVALID                         ,
    S_AXI_AWREADY           => S_AXI_AWREADY                         ,

    -- AXI Write Data Channel Signals (W)
    S_AXI_WDATA             => S_AXI_WDATA                           ,
    S_AXI_WSTRB             => S_AXI_WSTRB                           ,
    S_AXI_WLAST             => S_AXI_WLAST                           ,

    S_AXI_WVALID            => S_AXI_WVALID                          ,
    S_AXI_WREADY            => S_AXI_WREADY                          ,

    -- AXI Write Data Response Channel Signals (B)
    S_AXI_BID               => S_AXI_BID                             ,
    S_AXI_BRESP             => S_AXI_BRESP                           ,

    S_AXI_BVALID            => S_AXI_BVALID                          ,
    S_AXI_BREADY            => S_AXI_BREADY                          ,

    -- AXI Read Address Channel Signals (AR)
    S_AXI_ARID              => S_AXI_ARID                            ,
    S_AXI_ARADDR            => S_AXI_ARADDR                          ,
    S_AXI_ARLEN             => S_AXI_ARLEN                           ,
    S_AXI_ARSIZE            => S_AXI_ARSIZE                          ,
    S_AXI_ARBURST           => S_AXI_ARBURST                         ,
    S_AXI_ARLOCK            => S_AXI_ARLOCK                          ,
    S_AXI_ARCACHE           => S_AXI_ARCACHE                         ,
    S_AXI_ARPROT            => S_AXI_ARPROT                          ,

    S_AXI_ARVALID           => S_AXI_ARVALID                         ,
    S_AXI_ARREADY           => S_AXI_ARREADY                         ,

    -- AXI Read Data Channel Signals (R)
    S_AXI_RID               => S_AXI_RID                             ,
    S_AXI_RDATA             => S_AXI_RDATA                           ,
    S_AXI_RRESP             => S_AXI_RRESP                           ,
    S_AXI_RLAST             => S_AXI_RLAST                           ,

    S_AXI_RVALID            => S_AXI_RVALID                          ,
    S_AXI_RREADY            => S_AXI_RREADY                          ,

    -- AXI-Lite ECC Register Interface Signals

    -- AXI-Lite Write Address Channel Signals (AW)
    S_AXI_CTRL_AWVALID          => S_AXI_CTRL_AWVALID                ,
    S_AXI_CTRL_AWREADY          => S_AXI_CTRL_AWREADY                ,
    S_AXI_CTRL_AWADDR           => S_AXI_CTRL_AWADDR                 ,

    -- AXI-Lite Write Data Channel Signals (W)
    S_AXI_CTRL_WDATA            => S_AXI_CTRL_WDATA                  ,
    S_AXI_CTRL_WVALID           => S_AXI_CTRL_WVALID                 ,
    S_AXI_CTRL_WREADY           => S_AXI_CTRL_WREADY                 ,

    -- AXI-Lite Write Data Response Channel Signals (B)
    S_AXI_CTRL_BRESP            => S_AXI_CTRL_BRESP                  ,
    S_AXI_CTRL_BVALID           => S_AXI_CTRL_BVALID                 ,
    S_AXI_CTRL_BREADY           => S_AXI_CTRL_BREADY                 ,

    -- AXI-Lite Read Address Channel Signals (AR)
    S_AXI_CTRL_ARADDR           => S_AXI_CTRL_ARADDR                 ,
    S_AXI_CTRL_ARVALID          => S_AXI_CTRL_ARVALID                ,
    S_AXI_CTRL_ARREADY          => S_AXI_CTRL_ARREADY                ,

    -- AXI-Lite Read Data Channel Signals (R)
    S_AXI_CTRL_RDATA             => S_AXI_CTRL_RDATA                 ,
    S_AXI_CTRL_RRESP             => S_AXI_CTRL_RRESP                 ,
    S_AXI_CTRL_RVALID            => S_AXI_CTRL_RVALID                ,
    S_AXI_CTRL_RREADY            => S_AXI_CTRL_RREADY                ,

    -- BRAM Interface Signals (Port A)
    BRAM_Rst_A              => rsta_bram_rsta_i                      ,
    BRAM_Clk_A              => clka_bram_clka_i                      ,
    BRAM_En_A               => ena_bram_ena_i                        ,
    BRAM_WE_A               => wea_bram_wea_i                        ,
    BRAM_Addr_A             => addra_bram_addra_i,
    BRAM_WrData_A           => dina_bram_dina_i                      ,
    BRAM_RdData_A           => douta_bram_douta_i                    ,

    -- BRAM Interface Signals (Port B)
    BRAM_Rst_B              => rstb_bram_rstb_i                      ,
    BRAM_Clk_B              => clkb_bram_clkb_i                      ,
    BRAM_En_B               => enb_bram_enb_i                        ,
    BRAM_WE_B               => web_bram_web_i                        ,
    BRAM_Addr_B             => addrb_bram_addrb_i                    ,
    BRAM_WrData_B           => dinb_bram_dinb_i                      ,
    BRAM_RdData_B           => doutb_bram_doutb_i                    
    );
-- The following signals are driven 0's to remove the synthesis warnings
    bram_rst_a              <= '0';
    bram_clk_a              <= '0';
    bram_en_a               <= '0';
    bram_we_a               <= (others => '0');
    bram_addr_a             <= (others => '0');
    bram_wrdata_a           <= (others => '0');

    bram_rst_b              <= '0';
    bram_clk_b              <= '0'; 
    bram_en_b               <= '0';
    bram_we_b               <= (others => '0');
    bram_addr_b             <= (others => '0');
    bram_wrdata_b           <= (others => '0');


  END GENERATE gint_inst; -- End of internal bram instance 


gext_inst: IF (C_BRAM_INST_MODE = "EXTERNAL" ) GENERATE

abcv4_0_ext_inst : entity work.axi_bram_ctrl_top
generic map(

    -- AXI Parameters

    C_BRAM_ADDR_WIDTH  => C_BRAM_ADDR_WIDTH                        ,

    C_S_AXI_ADDR_WIDTH  => C_S_AXI_ADDR_WIDTH                        ,
        -- Width of AXI address bus (in bits)

    C_S_AXI_DATA_WIDTH  => C_S_AXI_DATA_WIDTH                        ,
        -- Width of AXI data bus (in bits)

    C_S_AXI_ID_WIDTH    => C_S_AXI_ID_WIDTH                                ,
        --  AXI ID vector width

    C_S_AXI_PROTOCOL    => C_S_AXI_PROTOCOL                          ,
        -- Set to AXI4LITE to optimize out burst transaction support

    C_S_AXI_SUPPORTS_NARROW_BURST => C_S_AXI_SUPPORTS_NARROW_BURST   ,
        -- Support for narrow burst operations

    C_SINGLE_PORT_BRAM  => C_SINGLE_PORT_BRAM                        ,
        -- Enable single port usage of BRAM

    -- AXI-Lite Register Parameters
    C_S_AXI_CTRL_ADDR_WIDTH  => C_S_AXI_CTRL_ADDR_WIDTH              ,
        -- Width of AXI-Lite address bus (in bits)

    C_S_AXI_CTRL_DATA_WIDTH  => C_S_AXI_CTRL_DATA_WIDTH              ,
        -- Width of AXI-Lite data bus (in bits)

    -- ECC Parameters

    C_ECC => C_ECC                                                   ,
        -- Enables or disables ECC functionality
    C_ECC_TYPE                      =>  C_ECC_TYPE                      ,   

    C_FAULT_INJECT => C_FAULT_INJECT                                 ,
        -- Enable fault injection registers
        -- (default = disabled)

    C_ECC_ONOFF_RESET_VALUE => C_ECC_ONOFF_RESET_VALUE               
        -- By default, ECC checking is on
        -- (can disable ECC @ reset by setting this to 0)
       )
  port map(

    -- AXI Interface Signals

    -- AXI Clock and Reset
    s_axi_aclk              => s_axi_aclk                            ,
    s_axi_aresetn           => s_axi_aresetn                         ,

    ecc_interrupt           => ecc_interrupt                         ,
    ecc_ue                  => ecc_ue                                ,

    -- axi write address channel signals (aw)
    s_axi_awid              => s_axi_awid                            ,
    s_axi_awaddr            => s_axi_awaddr                          ,
    s_axi_awlen             => s_axi_awlen                           ,
    s_axi_awsize            => s_axi_awsize                          , 
    s_axi_awburst           => s_axi_awburst                         ,
    s_axi_awlock            => s_axi_awlock                          , 
    s_axi_awcache           => s_axi_awcache                         ,
    s_axi_awprot            => s_axi_awprot                          ,
    s_axi_awvalid           => s_axi_awvalid                         ,
    s_axi_awready           => s_axi_awready                         ,

    -- axi write data channel signals (w)
    s_axi_wdata             => s_axi_wdata                           ,
    s_axi_wstrb             => s_axi_wstrb                           ,
    s_axi_wlast             => s_axi_wlast                           ,

    s_axi_wvalid            => s_axi_wvalid                          ,
    s_axi_wready            => s_axi_wready                          ,

    -- axi write data response channel signals (b)
    s_axi_bid               => s_axi_bid                             ,
    s_axi_bresp             => s_axi_bresp                           ,

    s_axi_bvalid            => s_axi_bvalid                          ,
    s_axi_bready            => s_axi_bready                          ,

    -- axi read address channel signals (ar)
    s_axi_arid              => s_axi_arid                            ,
    s_axi_araddr            => s_axi_araddr                          ,
    s_axi_arlen             => s_axi_arlen                           ,
    s_axi_arsize            => s_axi_arsize                          ,
    s_axi_arburst           => s_axi_arburst                         ,
    s_axi_arlock            => s_axi_arlock                          ,
    s_axi_arcache           => s_axi_arcache                         ,
    s_axi_arprot            => s_axi_arprot                          ,

    s_axi_arvalid           => s_axi_arvalid                         ,
    s_axi_arready           => s_axi_arready                         ,

    -- axi read data channel signals (r)
    s_axi_rid               => s_axi_rid                             ,
    s_axi_rdata             => s_axi_rdata                           ,
    s_axi_rresp             => s_axi_rresp                           ,
    s_axi_rlast             => s_axi_rlast                           ,

    s_axi_rvalid            => s_axi_rvalid                          ,
    s_axi_rready            => s_axi_rready                          ,

    -- axi-lite ecc register interface signals

    -- axi-lite write address channel signals (aw)
    s_axi_ctrl_awvalid          => s_axi_ctrl_awvalid                ,
    s_axi_ctrl_awready          => s_axi_ctrl_awready                ,
    s_axi_ctrl_awaddr           => s_axi_ctrl_awaddr                 ,

    -- axi-lite write data channel signals (w)
    s_axi_ctrl_wdata            => s_axi_ctrl_wdata                  ,
    s_axi_ctrl_wvalid           => s_axi_ctrl_wvalid                 ,
    s_axi_ctrl_wready           => s_axi_ctrl_wready                 ,

    -- axi-lite write data response channel signals (b)
    s_axi_ctrl_bresp            => s_axi_ctrl_bresp                  ,
    s_axi_ctrl_bvalid           => s_axi_ctrl_bvalid                 ,
    s_axi_ctrl_bready           => s_axi_ctrl_bready                 ,

    -- axi-lite read address channel signals (ar)
    s_axi_ctrl_araddr           => s_axi_ctrl_araddr                 ,
    s_axi_ctrl_arvalid          => s_axi_ctrl_arvalid                ,
    s_axi_ctrl_arready          => s_axi_ctrl_arready                ,

    -- axi-lite read data channel signals (r)
    s_axi_ctrl_rdata             => s_axi_ctrl_rdata                 ,
    s_axi_ctrl_rresp             => s_axi_ctrl_rresp                 ,
    s_axi_ctrl_rvalid            => s_axi_ctrl_rvalid                ,
    s_axi_ctrl_rready            => s_axi_ctrl_rready                ,

    -- bram interface signals (port a)
    bram_rst_a                   => bram_rst_a                       ,
    bram_clk_a                   => bram_clk_a                       ,
    bram_en_a                    => bram_en_a                        ,
    bram_we_a                    => bram_we_a                        ,
    bram_addr_a                  => bram_addr_a                      ,
    bram_wrdata_a                => bram_wrdata_a                    ,
    bram_rddata_a                => bram_rddata_a                    ,

    -- bram interface signals (port b)
    bram_rst_b                   => bram_rst_b                       ,
    bram_clk_b                   => bram_clk_b                       ,
    bram_en_b                    => bram_en_b                        ,
    bram_we_b                    => bram_we_b                        ,
    bram_addr_b                  => bram_addr_b                      ,
    bram_wrdata_b                => bram_wrdata_b                    ,
    bram_rddata_b                => bram_rddata_b                    
    );
  END GENERATE gext_inst; -- End of internal bram instance 

end architecture implementation;

