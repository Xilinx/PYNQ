-------------------------------------------------------------------------------
-- wr_chnl.vhd
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
-- Filename:        wr_chnl.vhd
--
-- Description:     This file is the top level module for the AXI BRAM
--                  controller write channel interfaces.  Controls all
--                  handshaking and data flow on the AXI write address (AW),
--                  write data (W) and write response (B) channels.
--
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--              axi_bram_ctrl.vhd (v1_03_a)
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
--
--
-------------------------------------------------------------------------------
--
-- History:
-- 
-- JLJ      2/2/2011       v1.03a
-- ~~~~~~
--  Migrate to v1.03a.
--  Minor code cleanup.
--  Remove library version # dependency.  Replace with work library.
-- ^^^^^^
-- JLJ      2/3/2011       v1.03a
-- ~~~~~~
--  Edits for scalability and support of 512 and 1024-bit data widths.
-- ^^^^^^
-- JLJ      2/10/2011      v1.03a
-- ~~~~~~
--  Initial integration of Hsiao ECC algorithm.
--  Add C_ECC_TYPE top level parameter.
-- ^^^^^^
-- JLJ      2/14/2011      v1.03a
-- ~~~~~~
--  Shift Hsiao ECC generate logic so not dependent on C_S_AXI_DATA_WIDTH.
-- ^^^^^^
-- JLJ      2/18/2011      v1.03a
-- ~~~~~~
--  Update WE size based on 128-bit ECC configuration.
--  Update for usage of ecc_gen.vhd module directly from MIG.
--  Clean-up XST warnings.
-- ^^^^^^
-- JLJ      2/22/2011      v1.03a
-- ~~~~~~
--  Found issue with ECC decoding on read path.  Remove MSB '0' usage 
--  in syndrome calculation, since h_matrix is based on 32 + 7 = 39 bits.
-- ^^^^^^
-- JLJ      2/23/2011      v1.03a
-- ~~~~~~
--  Code clean-up.
--  Move all MIG functions to package body.
-- ^^^^^^
-- JLJ      2/28/2011      v1.03a
-- ~~~~~~
--  Fix mapping on BRAM_WE with bram_we_int for 128-bit w/ ECC.
-- ^^^^^^
-- JLJ      3/1/2011        v1.03a
-- ~~~~~~
--  Fix XST handling for DIV functions.  Create seperate process when
--  divisor is not constant and a power of two.
-- ^^^^^^
-- JLJ      3/17/2011      v1.03a
-- ~~~~~~
--  Add comments as noted in Spyglass runs. And general code clean-up.
--  Fix double clock assertion of CE/UE error flags when asserted
--  during the RMW sequence.
-- ^^^^^^
-- JLJ      3/23/2011      v1.03a
-- ~~~~~~
--  Code clean-up.
-- ^^^^^^
-- JLJ      3/30/2011      v1.03a
-- ~~~~~~
--  Add code coverage on/off statements.
-- ^^^^^^
-- JLJ      4/8/2011      v1.03a
-- ~~~~~~
--  Modify back-to-back capability to remove combinatorial loop 
--  on WREADY to AXI interface.  Add internal constant, C_REG_WREADY.
--  Update axi_wready_int reset value (ensure it is '0').
--
--  Create new SM for C_REG_WREADY with dual port.  Seperate assertion of BVALID
--  from WREADY.  Create a FIFO to store AWID/BID values.
--  Use counter (with max of 8 ID values) to allow WREADY assertions 
--  to be ahead of BVALID assertions.
--  Add sub module, SRL_FIFO.
-- ^^^^^^
-- JLJ      4/11/2011      v1.03a
-- ~~~~~~
--  Implement similar updates on WREADY for single port & ECC configurations.
--  Remove use of signal, axi_wready_sng with constant, C_REG_WREADY.
--
--  For single port operation with registered WREADY, provide BVALID counter
--  value to arbitration SM, add output signal, AW2Arb_BVALID_Cnt.
--
--  Create an additional SM for single port when C_REG_WREADY.
-- ^^^^^^
-- JLJ      4/14/2011      v1.03a
-- ~~~~~~
--  Remove attempt to create AXI write data pipeline full flag outside of SM
--  logic.  Add corner case checks for BID FIFO/BVALID counter.
-- ^^^^^^
-- JLJ      4/15/2011      v1.03a
-- ~~~~~~
--  Clean up all code not related to C_REG_WREADY.  
--  Goal to remove internal constant, C_REG_WREADY.
--  Work on size optimization.  Implement signals to represent BVALID 
--  counter values.
-- ^^^^^^
-- JLJ      4/20/2011      v1.03a
-- ~~~~~~
--  Code clean up.  Remove unused signals.
--  Remove additional generate blocks with C_REG_WREADY.
-- ^^^^^^
-- JLJ      4/21/2011      v1.03a
-- ~~~~~~
--  Code clean up.  Remove use of IF_IS_AXI4 constant.
--  Create new SM TYPE for each configuration.
-- ^^^^^^
-- JLJ      4/22/2011      v1.03a
-- ~~~~~~
--  Add check in data SM on back-to-back for BVALID counter max.
--  Clean up AXI_WREADY generate blocks.
-- ^^^^^^
-- JLJ      4/22/2011         v1.03a
-- ~~~~~~
--  Code clean up.
-- ^^^^^^
-- JLJ      5/6/2011      v1.03a
-- ~~~~~~
--  Remove usage of C_FAMILY.  
--  Hard code C_USE_LUT6 constant.
-- ^^^^^^
-- JLJ      5/26/2011      v1.03a
-- ~~~~~~
--  Fix CR # 609695.
--  Modify usage of WLAST.  Ensure that WLAST is qualified with
--  WVALID/WREADY assertions.
--
--  With CR # 609695, update else clause for narrow_burst_cnt_ld to 
--  remove simulation warnings when axi_byte_div_curr_awsize = zero.
--
--  Catch code clean up with WLAST in data SM for axi_wr_burst_cmb
--  signal assertion.
-- ^^^^^^
--
--
--  
-------------------------------------------------------------------------------

-- Library declarations

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.srl_fifo;
use work.wrap_brst;
use work.ua_narrow;
use work.checkbit_handler;
use work.checkbit_handler_64;
use work.correct_one_bit;
use work.correct_one_bit_64;
use work.ecc_gen;
use work.axi_bram_ctrl_funcs.all;



------------------------------------------------------------------------------


entity wr_chnl is
generic (


    --  C_FAMILY : string := "virtex6";
        -- Specify the target architecture type

    C_AXI_ADDR_WIDTH    : integer := 32;
      -- Width of AXI address bus (in bits)
    
    C_BRAM_ADDR_ADJUST_FACTOR   : integer := 2;
      -- Adjust factor to BRAM address width based on data width (in bits)

    C_AXI_DATA_WIDTH  : integer := 32;
      -- Width of AXI data bus (in bits)
      
    C_AXI_ID_WIDTH : INTEGER := 4;
        --  AXI ID vector width

    C_S_AXI_SUPPORTS_NARROW : INTEGER := 1;
        -- Support for narrow burst operations

    C_S_AXI_PROTOCOL : string := "AXI4";
        -- Set to "AXI4LITE" to optimize out burst transaction support

    C_SINGLE_PORT_BRAM : INTEGER := 0;
        -- Enable single port usage of BRAM

    C_ECC : integer := 0;
        -- Enables or disables ECC functionality
        
    C_ECC_WIDTH : integer := 8;
        -- Width of ECC data vector
        
    C_ECC_TYPE : integer := 0          -- v1.03a 
        -- ECC algorithm format, 0 = Hamming code, 1 = Hsiao code

    );
  port (


    -- AXI Global Signals
    S_AXI_AClk              : in    std_logic;
    S_AXI_AResetn           : in    std_logic;      

    -- AXI Write Address Channel Signals (AW)
    AXI_AWID                : in    std_logic_vector(C_AXI_ID_WIDTH-1 downto 0);
    AXI_AWADDR              : in    std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);

    AXI_AWLEN               : in    std_logic_vector(7 downto 0);
        -- Specifies the number of data transfers in the burst
        -- "0000 0000"  1 data transfer
        -- "0000 0001"  2 data transfers
        -- ...
        -- "1111 1111" 256 data transfers
        
    AXI_AWSIZE              : in    std_logic_vector(2 downto 0);
        -- Specifies the max number of data bytes to transfer in each data beat
        -- "000"    1 byte to transfer
        -- "001"    2 bytes to transfer
        -- "010"    3 bytes to transfer
        -- ...
        
    
    AXI_AWBURST             : in    std_logic_vector(1 downto 0);
        -- Specifies burst type
        -- "00" FIXED = Fixed burst address (handled as INCR)
        -- "01" INCR = Increment burst address
        -- "10" WRAP = Incrementing address burst that wraps to lower order address at boundary
        -- "11" Reserved (not checked)
    
    AXI_AWLOCK              : in    std_logic;                          -- Currently unused         
    AXI_AWCACHE             : in    std_logic_vector(3 downto 0);       -- Currently unused
    AXI_AWPROT              : in    std_logic_vector(2 downto 0);       -- Currently unused
    AXI_AWVALID             : in    std_logic;
    AXI_AWREADY             : out   std_logic;


    -- AXI Write Data Channel Signals (W)
    AXI_WDATA               : in    std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    AXI_WSTRB               : in    std_logic_vector(C_AXI_DATA_WIDTH/8-1 downto 0);
    AXI_WLAST               : in    std_logic;

    AXI_WVALID              : in    std_logic;
    AXI_WREADY              : out   std_logic;


    -- AXI Write Data Response Channel Signals (B)
    AXI_BID                 : out   std_logic_vector(C_AXI_ID_WIDTH-1 downto 0);
    AXI_BRESP               : out   std_logic_vector(1 downto 0);

    AXI_BVALID              : out   std_logic;
    AXI_BREADY              : in    std_logic;

 
    -- ECC Register Interface Signals
    Enable_ECC              : in    std_logic;
    BRAM_Addr_En            : out   std_logic := '0';
    FaultInjectClr          : out   std_logic := '0'; 
    CE_Failing_We           : out   std_logic := '0'; 
    Sl_CE                   : out   std_logic := '0'; 
    Sl_UE                   : out   std_logic := '0'; 
    Active_Wr               : out   std_logic := '0';

    FaultInjectData         : in    std_logic_vector (C_AXI_DATA_WIDTH-1 downto 0);
    FaultInjectECC          : in    std_logic_vector (C_ECC_WIDTH-1 downto 0);
    

    -- Single Port Arbitration Signals
    Arb2AW_Active               : in    std_logic;
    AW2Arb_Busy                 : out   std_logic := '0';
    AW2Arb_Active_Clr           : out   std_logic := '0';
    AW2Arb_BVALID_Cnt           : out   std_logic_vector (2 downto 0) := (others => '0');

    Sng_BRAM_Addr_Rst           : out   std_logic := '0';
    Sng_BRAM_Addr_Ld_En         : out   std_logic := '0';
    Sng_BRAM_Addr_Ld            : out   std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) := (others => '0');
    Sng_BRAM_Addr_Inc           : out   std_logic := '0';
    Sng_BRAM_Addr               : in    std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR);
    
    
    -- BRAM Write Port Interface Signals
    BRAM_En                 : out   std_logic := '0';
    BRAM_WE                 : out   std_logic_vector (C_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_AXI_DATA_WIDTH/128))-1 downto 0);
    BRAM_Addr               : out   std_logic_vector (C_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
    BRAM_WrData             : out   std_logic_vector (C_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0) := (others => '0');
    BRAM_RdData             : in    std_logic_vector (C_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0)
       
    

    );


end entity wr_chnl;


-------------------------------------------------------------------------------

architecture implementation of wr_chnl is

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of implementation : architecture is "yes";


-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-- All functions defined in axi_bram_ctrl_funcs package.

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- Reset active level (common through core)
constant C_RESET_ACTIVE     : std_logic := '0';


constant RESP_OKAY      : std_logic_vector (1 downto 0) := "00";    -- Normal access OK response
constant RESP_SLVERR    : std_logic_vector (1 downto 0) := "10";    -- Slave error
-- For future support.      constant RESP_EXOKAY    : std_logic_vector (1 downto 0) := "01";    -- Exclusive access OK response
-- For future support.      constant RESP_DECERR    : std_logic_vector (1 downto 0) := "11";    -- Decode error


-- Set constants for AWLEN equal to a count of one or two beats.
constant AXI_AWLEN_ONE  : std_logic_vector (7 downto 0) := (others => '0');
constant AXI_AWLEN_TWO  : std_logic_vector (7 downto 0) := "00000001";
constant AXI_AWSIZE_ONE : std_logic_vector (2 downto 0) := "001";



-- Determine maximum size for narrow burst length counter
-- When C_AXI_DATA_WIDTH = 32, minimum narrow width burst is 8 bits
--              resulting in a count 3 downto 0 => so minimum counter width = 2 bits.
-- When C_AXI_DATA_WIDTH = 256, minimum narrow width burst is 8 bits
--              resulting in a count 31 downto 0 => so minimum counter width = 5 bits.

constant C_NARROW_BURST_CNT_LEN     : integer := log2 (C_AXI_DATA_WIDTH/8);
constant NARROW_CNT_MAX     : std_logic_vector (C_NARROW_BURST_CNT_LEN-1 downto 0) := (others => '0');



-- AXI Size Constants
--      constant C_AXI_SIZE_1BYTE       : std_logic_vector (2 downto 0) := "000";   -- 1 byte
--      constant C_AXI_SIZE_2BYTE       : std_logic_vector (2 downto 0) := "001";   -- 2 bytes
--      constant C_AXI_SIZE_4BYTE       : std_logic_vector (2 downto 0) := "010";   -- 4 bytes = max size for 32-bit BRAM
--      constant C_AXI_SIZE_8BYTE       : std_logic_vector (2 downto 0) := "011";   -- 8 bytes = max size for 64-bit BRAM
--      constant C_AXI_SIZE_16BYTE      : std_logic_vector (2 downto 0) := "100";   -- 16 bytes = max size for 128-bit BRAM
--      constant C_AXI_SIZE_32BYTE      : std_logic_vector (2 downto 0) := "101";   -- 32 bytes = max size for 256-bit BRAM
--      constant C_AXI_SIZE_64BYTE      : std_logic_vector (2 downto 0) := "110";   -- 64 bytes = max size for 512-bit BRAM
--      constant C_AXI_SIZE_128BYTE     : std_logic_vector (2 downto 0) := "111";   -- 128 bytes = max size for 1024-bit BRAM


-- Determine max value of ARSIZE based on the AXI data width.
-- Use function in axi_bram_ctrl_funcs package.
constant C_AXI_SIZE_MAX         : std_logic_vector (2 downto 0) := Create_Size_Max (C_AXI_DATA_WIDTH);




-- Modify C_BRAM_ADDR_SIZE to be adjusted for BRAM data width
-- When BRAM data width = 32 bits, BRAM_Addr (1:0) = "00"
-- When BRAM data width = 64 bits, BRAM_Addr (2:0) = "000"
-- When BRAM data width = 128 bits, BRAM_Addr (3:0) = "0000"
-- When BRAM data width = 256 bits, BRAM_Addr (4:0) = "00000"
-- Move to full_axi module
-- constant C_BRAM_ADDR_ADJUST_FACTOR  : integer := log2 (C_AXI_DATA_WIDTH/8);
-- Not used
-- constant C_BRAM_ADDR_ADJUST : integer := C_AXI_ADDR_WIDTH - C_BRAM_ADDR_ADJUST_FACTOR;

constant C_AXI_DATA_WIDTH_BYTES     : integer := C_AXI_DATA_WIDTH/8;

-- AXI Burst Types
-- AXI Spec 4.4
constant C_AXI_BURST_WRAP       : std_logic_vector (1 downto 0) := "10";  
constant C_AXI_BURST_INCR       : std_logic_vector (1 downto 0) := "01";  
constant C_AXI_BURST_FIXED      : std_logic_vector (1 downto 0) := "00";  


-- Internal ECC data width size.
constant C_INT_ECC_WIDTH : integer := Int_ECC_Size (C_AXI_DATA_WIDTH);


-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- AXI Write Address Channel Signals
-------------------------------------------------------------------------------


-- State machine type declarations
type WR_ADDR_SM_TYPE is ( IDLE,
                          LD_AWADDR
                        );
                    
signal wr_addr_sm_cs, wr_addr_sm_ns : WR_ADDR_SM_TYPE;

signal aw_active_set                : std_logic := '0';
signal aw_active_set_i              : std_logic := '0';

signal aw_active_clr                : std_logic := '0';
signal delay_aw_active_clr_cmb      : std_logic := '0'; 
signal delay_aw_active_clr          : std_logic := '0';
signal aw_active                    : std_logic := '0';
signal aw_active_d1                 : std_logic := '0';
signal aw_active_re                 : std_logic := '0';

signal axi_awaddr_pipe      : std_logic_vector (C_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');

signal curr_awaddr_lsb      : std_logic_vector (C_BRAM_ADDR_ADJUST_FACTOR-1 downto 0) := (others => '0');

signal awaddr_pipe_ld       : std_logic := '0';
signal awaddr_pipe_ld_i     : std_logic := '0';

signal awaddr_pipe_sel      : std_logic := '0';
    -- '0' indicates mux select from AXI
    -- '1' indicates mux select from AW Addr Register
signal axi_awaddr_full      : std_logic := '0';

signal axi_awid_pipe        : std_logic_vector (C_AXI_ID_WIDTH-1 downto 0) := (others => '0');
signal axi_awsize_pipe      : std_logic_vector(2 downto 0) := (others => '0');
signal curr_awsize          : std_logic_vector(2 downto 0) := (others => '0');
signal curr_awsize_reg      : std_logic_vector (2 downto 0) := (others => '0');


-- Narrow Burst Signals
signal curr_narrow_burst_cmb    : std_logic := '0';
signal curr_narrow_burst        : std_logic := '0';
signal curr_narrow_burst_en     : std_logic := '0';

signal narrow_burst_cnt_ld      : std_logic_vector (C_NARROW_BURST_CNT_LEN-1 downto 0) := (others => '0');
signal narrow_burst_cnt_ld_reg  : std_logic_vector (C_NARROW_BURST_CNT_LEN-1 downto 0) := (others => '0');
signal narrow_burst_cnt_ld_mod  : std_logic_vector (C_NARROW_BURST_CNT_LEN-1 downto 0) := (others => '0');

signal narrow_addr_rst          : std_logic := '0';     
signal narrow_addr_ld_en        : std_logic := '0';
signal narrow_addr_dec          : std_logic := '0';


signal axi_awlen_pipe           : std_logic_vector(7 downto 0) := (others => '0');

signal axi_awlen_pipe_1_or_2    : std_logic := '0';     
signal curr_awlen               : std_logic_vector(7 downto 0) := (others => '0');
signal curr_awlen_reg           : std_logic_vector(7 downto 0) := (others => '0');

signal curr_awlen_reg_1_or_2    : std_logic := '0';     


signal axi_awburst_pipe         : std_logic_vector(1 downto 0) := (others => '0');
signal axi_awburst_pipe_fixed   : std_logic := '0';     

signal curr_awburst             : std_logic_vector(1 downto 0) := (others => '0');
signal curr_wrap_burst          : std_logic := '0';
signal curr_wrap_burst_reg      : std_logic := '0';

signal curr_incr_burst          : std_logic := '0';     
signal curr_fixed_burst         : std_logic := '0';     
signal curr_fixed_burst_reg     : std_logic := '0';     

signal max_wrap_burst_mod       : std_logic := '0';

signal axi_awready_int          : std_logic := '0';

signal axi_aresetn_d1           : std_logic := '0';
signal axi_aresetn_d2           : std_logic := '0';
signal axi_aresetn_re           : std_logic := '0';
signal axi_aresetn_re_reg       : std_logic := '0';


-- BRAM Address Counter    
signal bram_addr_ld_en              : std_logic := '0';
signal bram_addr_ld_en_i            : std_logic := '0';


signal bram_addr_ld_en_mod          : std_logic := '0';

signal bram_addr_ld                 : std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)
                                        := (others => '0');
signal bram_addr_ld_wrap            : std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)
                                        := (others => '0');

signal bram_addr_inc                : std_logic := '0';
signal bram_addr_inc_mod            : std_logic := '0';
signal bram_addr_inc_wrap_mod       : std_logic := '0';         

signal bram_addr_rst                : std_logic := '0';
signal bram_addr_rst_cmb            : std_logic := '0';


signal narrow_bram_addr_inc         : std_logic := '0';
signal narrow_bram_addr_inc_d1      : std_logic := '0';
signal narrow_bram_addr_inc_re      : std_logic := '0';

signal narrow_addr_int              : std_logic_vector (C_NARROW_BURST_CNT_LEN-1 downto 0) := (others => '0');

signal curr_ua_narrow_wrap          : std_logic := '0';
signal curr_ua_narrow_incr          : std_logic := '0';     
signal ua_narrow_load               : std_logic_vector (C_NARROW_BURST_CNT_LEN-1 downto 0) := (others => '0');




-------------------------------------------------------------------------------
-- AXI Write Data Channel Signals
-------------------------------------------------------------------------------


-- State machine type declarations
type WR_DATA_SM_TYPE is (   IDLE,
                            W8_AWADDR,
                                                            -- W8_BREADY,
                            SNG_WR_DATA,
                            BRST_WR_DATA,
                                                            -- NEW_BRST_WR_DATA,
                            B2B_W8_WR_DATA                  --,
                                                            -- B2B_W8_BRESP,
                                                            -- W8_BRESP  
                          );
                    
signal wr_data_sm_cs, wr_data_sm_ns : WR_DATA_SM_TYPE;



type WR_DATA_SNG_SM_TYPE is (   IDLE,
                                SNG_WR_DATA,
                                BRST_WR_DATA  );

signal wr_data_sng_sm_cs, wr_data_sng_sm_ns : WR_DATA_SNG_SM_TYPE;



type WR_DATA_ECC_SM_TYPE is (   IDLE,
                                RMW_RD_DATA,
                                RMW_CHK_DATA,
                                RMW_MOD_DATA,
                                RMW_WR_DATA   );

signal wr_data_ecc_sm_cs, wr_data_ecc_sm_ns : WR_DATA_ECC_SM_TYPE;


-- Wr Data Buffer/Register
signal wrdata_reg_ld        : std_logic := '0';
signal axi_wready_int       : std_logic := '0';
signal axi_wready_int_mod   : std_logic := '0';
signal axi_wdata_full_cmb   : std_logic := '0';
signal axi_wdata_full       : std_logic := '0';
signal axi_wdata_empty      : std_logic := '0';
signal axi_wdata_full_reg   : std_logic := '0';



-- WE Generator Signals
signal clr_bram_we_cmb      : std_logic := '0';
signal clr_bram_we          : std_logic := '0';
signal bram_we_ld           : std_logic := '0';

signal axi_wr_burst_cmb     : std_logic := '0';
signal axi_wr_burst         : std_logic := '0';


signal wr_b2b_elgible           : std_logic := '0';
-- CR # 609695      signal last_data_ack            : std_logic := '0';
-- CR # 609695      signal last_data_ack_throttle   : std_logic := '0';
signal last_data_ack_mod        : std_logic := '0';
-- CR # 609695      signal w8_b2b_bresp             : std_logic := '0';


signal axi_wlast_d1             : std_logic := '0';
signal axi_wlast_re             : std_logic := '0';


-- Single Port Signals

-- Write busy flags only used in ECC configuration
-- when waiting for BVALID/BREADY handshake
signal wr_busy_cmb              : std_logic := '0';    
signal wr_busy_reg              : std_logic := '0';

-- Only used by ECC register module.
signal active_wr_cmb            : std_logic := '0';
signal active_wr_reg            : std_logic := '0';


-------------------------------------------------------------------------------
-- AXI Write Response Channel Signals
-------------------------------------------------------------------------------

signal axi_bid_temp         : std_logic_vector (C_AXI_ID_WIDTH-1 downto 0) := (others => '0');
signal axi_bid_temp_full    : std_logic := '0';

signal axi_bid_int          : std_logic_vector (C_AXI_ID_WIDTH-1 downto 0) := (others => '0');
signal axi_bresp_int        : std_logic_vector (1 downto 0) := (others => '0');
signal axi_bvalid_int       : std_logic := '0';
signal axi_bvalid_set_cmb   : std_logic := '0';


-------------------------------------------------------------------------------
-- Internal BRAM Signals
-------------------------------------------------------------------------------

signal reset_bram_we        : std_logic := '0';
signal set_bram_we_cmb      : std_logic := '0';
signal set_bram_we          : std_logic := '0';
signal bram_we_int          : std_logic_vector (C_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_AXI_DATA_WIDTH/128))-1 downto 0) := (others => '0');
signal bram_en_cmb          : std_logic := '0';
signal bram_en_int          : std_logic := '0';

signal bram_addr_int        : std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)
                                    := (others => '0');

signal bram_wrdata_int      : std_logic_vector (C_AXI_DATA_WIDTH-1 downto 0) := (others => '0');


-------------------------------------------------------------------------------
-- ECC Signals
-------------------------------------------------------------------------------

signal CorrectedRdData          : std_logic_vector(0 to C_AXI_DATA_WIDTH-1);
signal RdModifyWr_Modify        : std_logic := '0';  -- Modify cycle in read modify write sequence 
signal RdModifyWr_Write         : std_logic := '0';  -- Write cycle in read modify write sequence 
signal WrData                   : std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
signal WrData_cmb               : std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

signal UE_Q                     : std_logic := '0';


-------------------------------------------------------------------------------
-- BVALID  Signals
-------------------------------------------------------------------------------

signal bvalid_cnt_inc       : std_logic := '0';
signal bvalid_cnt_inc_d1    : std_logic := '0';
signal bvalid_cnt_dec       : std_logic := '0';
signal bvalid_cnt           : std_logic_vector (2 downto 0) := (others => '0');
signal bvalid_cnt_amax      : std_logic := '0';
signal bvalid_cnt_max       : std_logic := '0';
signal bvalid_cnt_non_zero  : std_logic := '0';


-------------------------------------------------------------------------------
-- BID FIFO  Signals
-------------------------------------------------------------------------------

signal bid_fifo_rst         : std_logic := '0';
signal bid_fifo_ld_en       : std_logic := '0';
signal bid_fifo_ld          : std_logic_vector (C_AXI_ID_WIDTH-1 downto 0) := (others => '0');
signal bid_fifo_rd_en       : std_logic := '0';
signal bid_fifo_rd          : std_logic_vector (C_AXI_ID_WIDTH-1 downto 0) := (others => '0');
signal bid_fifo_not_empty   : std_logic := '0';

signal bid_gets_fifo_load       : std_logic := '0';
signal bid_gets_fifo_load_d1    : std_logic := '0';

signal first_fifo_bid           : std_logic := '0';
signal b2b_fifo_bid             : std_logic := '0';





-------------------------------------------------------------------------------
-- Architecture Body
-------------------------------------------------------------------------------


begin 



    ---------------------------------------------------------------------------
    -- AXI Write Address Channel Output Signals
    ---------------------------------------------------------------------------
    AXI_AWREADY <= axi_awready_int;



    ---------------------------------------------------------------------------
    -- AXI Write Data Channel Output Signals
    ---------------------------------------------------------------------------

    -- WREADY same signal assertion regardless of ECC or single port configuration.
    AXI_WREADY <= axi_wready_int_mod;
    
    

    ---------------------------------------------------------------------------
    -- AXI Write Response Channel Output Signals
    ---------------------------------------------------------------------------

    AXI_BRESP <= axi_bresp_int;
    AXI_BVALID <= axi_bvalid_int;

    AXI_BID <= axi_bid_int;   





    ---------------------------------------------------------------------------
    -- *** AXI Write Address Channel Interface ***
    ---------------------------------------------------------------------------

    
    ---------------------------------------------------------------------------
    -- Generate:    GEN_AW_PIPE_SNG
    -- Purpose:     Only generate pipeline registers when in dual port BRAM mode.
    ---------------------------------------------------------------------------

    GEN_AW_PIPE_SNG: if C_SINGLE_PORT_BRAM = 1 generate
    begin
    
        -- Unused AW pipeline (set default values)
        awaddr_pipe_ld <= '0';
        axi_awaddr_pipe <= AXI_AWADDR;
        axi_awid_pipe <= AXI_AWID;
        axi_awsize_pipe <= AXI_AWSIZE;
        axi_awlen_pipe <= AXI_AWLEN;
        axi_awburst_pipe <= AXI_AWBURST;
        axi_awlen_pipe_1_or_2 <= '0';
        axi_awburst_pipe_fixed <= '0';
        axi_awaddr_full <= '0';
            
    end generate GEN_AW_PIPE_SNG;



    ---------------------------------------------------------------------------
    -- Generate:    GEN_AW_PIPE_DUAL
    -- Purpose:     Only generate pipeline registers when in dual port BRAM mode.
    ---------------------------------------------------------------------------

    GEN_AW_PIPE_DUAL: if C_SINGLE_PORT_BRAM = 0 generate
    begin


        -----------------------------------------------------------------------
        --
        -- AXI Write Address Buffer/Register
        -- (mimic behavior of address pipeline for AXI_AWID)
        --
        -----------------------------------------------------------------------

        GEN_AWADDR: for i in C_AXI_ADDR_WIDTH-1 downto 0 generate
        begin

            REG_AWADDR: process (S_AXI_AClk)
            begin

                if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                    if (awaddr_pipe_ld = '1') then
                        axi_awaddr_pipe (i) <= AXI_AWADDR (i);
                    else
                        axi_awaddr_pipe (i) <= axi_awaddr_pipe (i);

                    end if;
                end if;

            end process REG_AWADDR;

        end generate GEN_AWADDR;



        -----------------------------------------------------------------------
        
        -- Register AWID

        REG_AWID: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (awaddr_pipe_ld = '1') then
                    axi_awid_pipe <= AXI_AWID;
                else
                    axi_awid_pipe <= axi_awid_pipe;

                end if;
            end if;

        end process REG_AWID;



        ---------------------------------------------------------------------------

        -- In parallel to AWADDR pipeline and AWID
        -- Use same control signals to capture AXI_AWSIZE, AXI_AWLEN & AXI_AWBURST.

        -- Register AXI_AWSIZE, AXI_AWLEN & AXI_AWBURST


        REG_AWCTRL: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (awaddr_pipe_ld = '1') then
                    axi_awsize_pipe <= AXI_AWSIZE;
                    axi_awlen_pipe <= AXI_AWLEN;
                    axi_awburst_pipe <= AXI_AWBURST;
                else
                    axi_awsize_pipe <= axi_awsize_pipe;
                    axi_awlen_pipe <= axi_awlen_pipe;
                    axi_awburst_pipe <= axi_awburst_pipe;

                end if;
            end if;

        end process REG_AWCTRL;



        ---------------------------------------------------------------------------


        -- Create signals that indicate value of AXI_AWLEN in pipeline stage
        -- Used to decode length of burst when BRAM address can be loaded early
        -- when pipeline is full.
        --
        -- Add early decode of AWBURST in pipeline.


        REG_AWLEN_PIPE: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (awaddr_pipe_ld = '1') then

                    -- Create merge to decode AWLEN of ONE or TWO
                    if (AXI_AWLEN = AXI_AWLEN_ONE) or (AXI_AWLEN = AXI_AWLEN_TWO) then
                        axi_awlen_pipe_1_or_2 <= '1';
                    else
                        axi_awlen_pipe_1_or_2 <= '0';
                    end if;


                    -- Early decode on value in pipeline of AWBURST
                    if (AXI_AWBURST = C_AXI_BURST_FIXED) then
                        axi_awburst_pipe_fixed <= '1';                
                    else
                        axi_awburst_pipe_fixed <= '0';
                    end if;


                else

                    axi_awlen_pipe_1_or_2 <= axi_awlen_pipe_1_or_2;
                    axi_awburst_pipe_fixed <= axi_awburst_pipe_fixed;

                end if;
            end if;

        end process REG_AWLEN_PIPE;


        ---------------------------------------------------------------------------


        -- Create full flag for AWADDR pipeline
        -- Set when write address register is loaded.
        -- Cleared when write address stored in register is loaded into BRAM
        -- address counter.


        REG_WRADDR_FULL: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                   (bram_addr_ld_en = '1' and awaddr_pipe_sel = '1') then
                    axi_awaddr_full <= '0';

                elsif (awaddr_pipe_ld = '1') then
                    axi_awaddr_full <= '1';
                else
                    axi_awaddr_full <= axi_awaddr_full;

                end if;
            end if;

        end process REG_WRADDR_FULL;



        ---------------------------------------------------------------------------



    end generate GEN_AW_PIPE_DUAL;





    ---------------------------------------------------------------------------
    -- Generate:    GEN_DUAL_ADDR_CNT
    -- Purpose:     Instantiate BRAM address counter unique for wr_chnl logic
    --              only when controller configured in dual port mode.
    ---------------------------------------------------------------------------
    
    GEN_DUAL_ADDR_CNT: if (C_SINGLE_PORT_BRAM = 0) generate
    begin
    

        ----------------------------------------------------------------------------

        -- Replace I_ADDR_CNT module usage of pf_counter in proc_common library.
        -- Only need to use lower 12-bits of address due to max AXI burst size
        -- Since AXI guarantees bursts do not cross 4KB boundary, the counting part 
        -- of I_ADDR_CNT can be reduced to max 4KB. 
        --
        --  Counter size is adjusted based on data width of BRAM.
        --  For example, 32-bit data width BRAM, BRAM_Addr (1:0)
        --  are fixed at "00".  So, counter increments from
        --  (C_AXI_ADDR_WIDTH - 1 : C_BRAM_ADDR_ADJUST).
        
        ----------------------------------------------------------------------------


        I_ADDR_CNT: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then

                -- Reset usage differs from RD CHNL
                if (bram_addr_rst = '1') then
                    bram_addr_int <= (others => '0');

                elsif (bram_addr_ld_en_mod = '1') then
                    bram_addr_int <= bram_addr_ld;

                elsif (bram_addr_inc_mod = '1') then
                    bram_addr_int (C_AXI_ADDR_WIDTH-1 downto 12) <= 
                            bram_addr_int (C_AXI_ADDR_WIDTH-1 downto 12);
                    bram_addr_int (11 downto C_BRAM_ADDR_ADJUST_FACTOR) <= 
                            std_logic_vector (unsigned (bram_addr_int (11 downto C_BRAM_ADDR_ADJUST_FACTOR)) + 1);

                    end if;

                end if;

        end process I_ADDR_CNT;


        -- Set defaults to shared address counter
        -- Only used in single port configurations
        Sng_BRAM_Addr_Rst <= '0';
        Sng_BRAM_Addr_Ld_En <= '0';
        Sng_BRAM_Addr_Ld <= (others => '0');
        Sng_BRAM_Addr_Inc <= '0';
        

    end generate GEN_DUAL_ADDR_CNT;
    
    
    
    ---------------------------------------------------------------------------
    -- Generate:    GEN_SNG_ADDR_CNT
    -- Purpose:     When configured in single port BRAM mode, address counter
    --              is shared with rd_chnl module.  Assign output signals here
    --              to counter instantiation at full_axi module level.
    ---------------------------------------------------------------------------
    GEN_SNG_ADDR_CNT: if (C_SINGLE_PORT_BRAM = 1) generate
    begin
    
        Sng_BRAM_Addr_Rst <= bram_addr_rst;
        Sng_BRAM_Addr_Ld_En <= bram_addr_ld_en_mod;
        Sng_BRAM_Addr_Ld <= bram_addr_ld;
        Sng_BRAM_Addr_Inc <= bram_addr_inc_mod;
        bram_addr_int <= Sng_BRAM_Addr; 
    

    end generate GEN_SNG_ADDR_CNT;




    ---------------------------------------------------------------------------
    --
    -- Add BRAM counter reset for @ end of transfer
    -- 
    -- Create a unique BRAM address reset signal
    -- If the write transaction is throttling on the AXI bus, then
    -- the BRAM EN may get negated during the write transfer
    --
    -- Use combinatorial output from SM, bram_addr_rst_cmb, but ensure the
    -- BRAM address is not reset while loading a new address.

    bram_addr_rst <= (not (S_AXI_AResetn)) or (bram_addr_rst_cmb and 
                                               not (bram_addr_ld_en_mod) and not (bram_addr_inc_mod));


    ---------------------------------------------------------------------------


    -- BRAM address counter load mux
    -- 
    -- Either load BRAM counter directly from AXI bus or from stored registered value
    --
    -- Added bram_addr_ld_wrap for loading on wrap burst types
    -- Use registered signal to indicate current operation is a WRAP burst
    --
    -- Do not load bram_addr_ld_wrap when bram_addr_ld_en signal is asserted at beginning of write burst
    -- BRAM address counter load.  Due to condition when max_wrap_burst_mod remains asserted, due to BRAM address
    -- counter not incrementing (at the end of the previous write burst).

    --  bram_addr_ld <= bram_addr_ld_wrap when 
    --                      (max_wrap_burst_mod = '1' and curr_wrap_burst_reg = '1' and bram_addr_ld_en = '0') else    
    --                  axi_awaddr_pipe (C_BRAM_ADDR_SIZE-1 downto C_BRAM_ADDR_ADJUST_FACTOR) 
    --                      when (awaddr_pipe_sel = '1') else 
    --                  AXI_AWADDR (C_BRAM_ADDR_SIZE-1 downto C_BRAM_ADDR_ADJUST_FACTOR);

    -- Replace C_BRAM_ADDR_SIZE w/ C_AXI_ADDR_WIDTH parameter usage

    bram_addr_ld <= bram_addr_ld_wrap when 
                        (max_wrap_burst_mod = '1' and curr_wrap_burst_reg = '1' and bram_addr_ld_en = '0') else    
                    axi_awaddr_pipe (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) 
                        when (awaddr_pipe_sel = '1') else 
                    AXI_AWADDR (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR);



    ---------------------------------------------------------------------------
    
   

    -- On wrap burst max loads (simultaneous BRAM address increment is asserted).
    -- Ensure that load has higher priority over increment.

    -- Use registered signal to indicate current operation is a WRAP burst
    --   bram_addr_ld_en_mod <= '1' when (bram_addr_ld_en = '1' or 
    --                                    (max_wrap_burst_mod = '1' and 
    --                                     curr_wrap_burst_reg = '1' and 
    --                                     bram_addr_inc_mod = '1'))
    --                           else '0';


    -- Use duplicate version of bram_addr_ld_en in effort
    -- to reduce fanout of signal routed to BRAM address counter
    bram_addr_ld_en_mod <= '1' when (bram_addr_ld_en = '1' or 
                                     (max_wrap_burst_mod = '1' and 
                                      curr_wrap_burst_reg = '1' and 
                                      bram_addr_inc_wrap_mod = '1'))
                            else '0';



    -- Create a special bram_addr_inc_mod for use in the bram_addr_ld_en_mod signal
    -- logic.  No need for the check if the current operation is NOT a fixed AND a wrap
    -- burst.  The transfer will be one or the other.

    -- Found issue when narrow FIXED length burst is incorrectly 
    -- incrementing BRAM address counter
    bram_addr_inc_wrap_mod <= bram_addr_inc when (curr_narrow_burst = '0') 
                            else narrow_bram_addr_inc_re;





    ----------------------------------------------------------------------------

    -- Handling for WRAP burst types
    --
    -- For WRAP burst types, the counter value will roll over when the burst
    -- boundary is reached.
    -- Boundary is reached based on ARSIZE and ARLEN.
    --
    -- Goal is to minimize muxing on initial load of counter value.
    -- On WRAP burst types, detect when the max address is reached.
    -- When the max address is reached, re-load counter with lower
    -- address value set to '0'.



    ----------------------------------------------------------------------------


    -- Detect valid WRAP burst types    
    curr_wrap_burst <= '1' when (curr_awburst = C_AXI_BURST_WRAP) else '0';


    -- Detect INCR & FIXED burst type operations
    curr_incr_burst <= '1' when (curr_awburst = C_AXI_BURST_INCR) else '0';    


    curr_fixed_burst <= '1' when (curr_awburst = C_AXI_BURST_FIXED) else '0';


    ----------------------------------------------------------------------------


    -- Register curr_wrap_burst signal when BRAM address counter is initially
    -- loaded

    REG_CURR_WRAP_BRST: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1') then

            -- Add reset same as BRAM address counter
            if (S_AXI_AResetn = C_RESET_ACTIVE) or (bram_addr_rst = '1' and bram_addr_ld_en = '0') then
                curr_wrap_burst_reg <= '0';

            elsif (bram_addr_ld_en = '1') then 
                curr_wrap_burst_reg <= curr_wrap_burst;

            else
                curr_wrap_burst_reg <= curr_wrap_burst_reg;
            end if;

        end if;

    end process REG_CURR_WRAP_BRST;



    ----------------------------------------------------------------------------


    -- Register curr_fixed_burst signal when BRAM address counter is initially
    -- loaded

    REG_CURR_FIXED_BRST: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1') then

            -- Add reset same as BRAM address counter
            if (S_AXI_AResetn = C_RESET_ACTIVE) or (bram_addr_rst = '1' and bram_addr_ld_en = '0') then
                curr_fixed_burst_reg <= '0';

            elsif (bram_addr_ld_en = '1') then 
                curr_fixed_burst_reg <= curr_fixed_burst;

            else
                curr_fixed_burst_reg <= curr_fixed_burst_reg;
            end if;

        end if;

    end process REG_CURR_FIXED_BRST;


    ----------------------------------------------------------------------------





    ---------------------------------------------------------------------------
    --
    -- Instance: I_WRAP_BRST
    --
    -- Description:
    --
    --      Instantiate WRAP_BRST module
    --      Logic to generate the wrap around value to load into the BRAM address
    --      counter on WRAP burst transactions.
    --      WRAP value is based on current AWLEN, AWSIZE (for narrows) and
    --      data width of BRAM module.
    --
    ---------------------------------------------------------------------------

    I_WRAP_BRST : entity work.wrap_brst
    generic map (

        C_AXI_ADDR_WIDTH                =>  C_AXI_ADDR_WIDTH                ,
        C_BRAM_ADDR_ADJUST_FACTOR       =>  C_BRAM_ADDR_ADJUST_FACTOR       ,
        C_AXI_DATA_WIDTH                =>  C_AXI_DATA_WIDTH              

    )
    port map (

        S_AXI_AClk                  =>  S_AXI_AClk                  ,
        S_AXI_AResetn               =>  S_AXI_AResetn               ,   

        curr_axlen                  =>  curr_awlen                  ,
        curr_axsize                 =>  curr_awsize                 ,
        curr_narrow_burst           =>  curr_narrow_burst           ,
        narrow_bram_addr_inc_re     =>  narrow_bram_addr_inc_re     ,
        bram_addr_ld_en             =>  bram_addr_ld_en             ,
        bram_addr_ld                =>  bram_addr_ld                ,
        bram_addr_int               =>  bram_addr_int               ,
        bram_addr_ld_wrap           =>  bram_addr_ld_wrap           ,
        max_wrap_burst_mod          =>  max_wrap_burst_mod     

    );    
    
    
    
    

    ---------------------------------------------------------------------------
    -- Generate:    GEN_WO_NARROW
    -- Purpose:     Create BRAM address increment signal when narrow bursts
    --              are disabled.
    ---------------------------------------------------------------------------

    GEN_WO_NARROW: if (C_S_AXI_SUPPORTS_NARROW = 0) generate
    begin

        -- For non narrow burst operations, use bram_addr_inc from data SM.
        -- Add in check that burst type is not FIXED, curr_fixed_burst_reg
        bram_addr_inc_mod <= bram_addr_inc and not (curr_fixed_burst_reg);
        
        -- The signal, curr_narrow_burst should always be set to '0' when narrow bursts
        -- are disabled.
        curr_narrow_burst <= '0';
        narrow_bram_addr_inc_re <= '0';   
    

    end generate GEN_WO_NARROW;


    ---------------------------------------------------------------------------

    
    -- Only instantiate NARROW_CNT and supporting logic when narrow transfers
    -- are supported and utilized by masters in the AXI system.
    -- The design parameter, C_S_AXI_SUPPORTS_NARROW will indicate this.
    
     


    ---------------------------------------------------------------------------
    -- Generate:    GEN_NARROW_CNT
    -- Purpose:     Instantiate narrow counter and logic when narrow
    --              operation support is enabled.
    --              And, only instantiate logic for narrow operations when
    --              AXI bus protocol is not set for AXI-LITE.
    ---------------------------------------------------------------------------

    GEN_NARROW_CNT: if (C_S_AXI_SUPPORTS_NARROW = 1) generate
    begin



        -- Based on current operation being a narrow burst, hold off BRAM
        -- address increment until narrow burst fits BRAM data width.
        -- For non narrow burst operations, use bram_addr_inc from data SM.

        -- Add in check that burst type is not FIXED, curr_fixed_burst_reg
        bram_addr_inc_mod <= (bram_addr_inc and not (curr_fixed_burst_reg)) when (curr_narrow_burst = '0') 
                                -- else narrow_bram_addr_inc_re;
                                -- Seeing incorrect BRAM address increment on narrow 
                                -- fixed length burst operations.
                                -- Add this check for curr_fixed_burst_reg
                             else (narrow_bram_addr_inc_re and not (curr_fixed_burst_reg));



        ---------------------------------------------------------------------------
        --
        -- Generate seperate smaller counter for narrow burst operations
        -- Replace I_NARROW_CNT module usage of pf_counter_top from proc_common library.
        --
        -- Counter size is adjusted based on size of data burst.
        --
        -- For example, 32-bit data width BRAM, minimum narrow width 
        -- burst is 8 bits resulting in a count 3 downto 0.  So the
        -- minimum counter width = 2 bits.
        --
        -- When C_AXI_DATA_WIDTH = 256, minimum narrow width burst 
        -- is 8 bits resulting in a count 31 downto 0.  So the
        -- minimum counter width = 5 bits.
        --
        -- Size of counter = C_NARROW_BURST_CNT_LEN
        --
        ---------------------------------------------------------------------------

        I_NARROW_CNT: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then

                if (narrow_addr_rst = '1') then
                    narrow_addr_int <= (others => '0');
                
                -- Load narrow address counter
                elsif (narrow_addr_ld_en = '1') then
                    narrow_addr_int <= narrow_burst_cnt_ld_mod;

                -- Decrement ONLY (no increment functionality)
                elsif (narrow_addr_dec = '1') then
                    narrow_addr_int (C_NARROW_BURST_CNT_LEN-1 downto 0) <= 
                            std_logic_vector (unsigned (narrow_addr_int (C_NARROW_BURST_CNT_LEN-1 downto 0)) - 1);

                end if;

            end if;

        end process I_NARROW_CNT;


        ---------------------------------------------------------------------------


        narrow_addr_rst <= not (S_AXI_AResetn);


        -- Narrow burst counter load mux
        -- Modify narrow burst count load value based on
        -- unalignment of AXI address value
        -- Account for INCR burst types at unaligned addresses
        narrow_burst_cnt_ld_mod <= ua_narrow_load when (curr_ua_narrow_wrap = '1' or curr_ua_narrow_incr = '1') else
                                   narrow_burst_cnt_ld when (bram_addr_ld_en = '1') else
                                   narrow_burst_cnt_ld_reg;


        narrow_addr_dec <= bram_addr_inc when (curr_narrow_burst = '1') else '0';

        narrow_addr_ld_en <= (curr_narrow_burst_cmb and bram_addr_ld_en) or narrow_bram_addr_inc_re;


        narrow_bram_addr_inc <= '1' when (narrow_addr_int = NARROW_CNT_MAX) and (curr_narrow_burst = '1') 

                                             -- Ensure that narrow address counter doesn't 
                                             -- flag max or get loaded to
                                             -- reset narrow counter until AXI read data 
                                             -- bus has acknowledged current
                                             -- data on the AXI bus.  Use rd_adv_buf signal 
                                             -- to indicate the non throttle
                                             -- condition on the AXI bus.

                                             and (bram_addr_inc = '1')                                             
                                    else '0';



        -- Detect rising edge of narrow_bram_addr_inc
        REG_NARROW_BRAM_ADDR_INC: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then

                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    narrow_bram_addr_inc_d1 <= '0';
                else
                    narrow_bram_addr_inc_d1 <= narrow_bram_addr_inc;
                end if;

            end if;
        end process REG_NARROW_BRAM_ADDR_INC;


        narrow_bram_addr_inc_re <= '1' when (narrow_bram_addr_inc = '1') and 
                                            (narrow_bram_addr_inc_d1 = '0') 
                                    else '0';


        ---------------------------------------------------------------------------

 
     end generate GEN_NARROW_CNT;



    ---------------------------------------------------------------------------
    -- Generate:    GEN_AWREADY
    -- Purpose:     AWREADY is only created here when in dual port BRAM mode.
    ---------------------------------------------------------------------------
    
    GEN_AWREADY: if (C_SINGLE_PORT_BRAM = 0) generate
    begin

        
        -- v1.03a
        
        ----------------------------------------------------------------------------
        --  AXI_AWREADY Output Register
        --  Description:    Keep AXI_AWREADY output asserted until AWADDR pipeline
        --                  is full.  When a full condition is reached, negate
        --                  AWREADY as another AW address can not be accepted.
        --                  Add condition to keep AWReady asserted if loading current
        ---                 AWADDR pipeline value into the BRAM address counter.
        --                  Indicated by assertion of bram_addr_ld_en & awaddr_pipe_sel.
        --
        ----------------------------------------------------------------------------

        REG_AWREADY: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then

                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    axi_awready_int <= '0';

                -- Detect end of S_AXI_AResetn to assert AWREADY and accept 
                -- new AWADDR values
                elsif (axi_aresetn_re_reg = '1') or (bram_addr_ld_en = '1' and awaddr_pipe_sel = '1') then
                    axi_awready_int <= '1';

                elsif (awaddr_pipe_ld = '1') then
                    axi_awready_int <= '0';
                else
                    axi_awready_int <= axi_awready_int;
                end if;
            end if;

        end process REG_AWREADY;



        ----------------------------------------------------------------------------

        -- Need to detect end of reset cycle to assert AWREADY on AXI bus
        REG_ARESETN: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                axi_aresetn_d1 <= S_AXI_AResetn;
                axi_aresetn_d2 <= axi_aresetn_d1;
                axi_aresetn_re_reg <= axi_aresetn_re;
            end if;

        end process REG_ARESETN;


        -- Create combinatorial RE detect of S_AXI_AResetn
        axi_aresetn_re <= '1' when (S_AXI_AResetn = '1' and axi_aresetn_d1 = '0') else '0';



    end generate GEN_AWREADY;



    ----------------------------------------------------------------------------



    -- Specify current AWSIZE signal 
    -- Address pipeline MUX
    curr_awsize <= axi_awsize_pipe when (awaddr_pipe_sel = '1') else AXI_AWSIZE;


    -- Register curr_awsize when bram_addr_ld_en = '1'

    REG_AWSIZE: process (S_AXI_AClk)
    begin
    
        if (S_AXI_AClk'event and S_AXI_AClk = '1') then
    
            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                curr_awsize_reg <= (others => '0');
                
            elsif (bram_addr_ld_en = '1') then
                curr_awsize_reg <= curr_awsize;
                
            else
                curr_awsize_reg <= curr_awsize_reg;
            end if;
    
        end if;
    end process REG_AWSIZE;




    

    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_NARROW_EN
    -- Purpose:     Only instantiate logic to determine if current burst
    --              is a narrow burst when narrow bursting logic is supported.
    --
    ---------------------------------------------------------------------------

    GEN_NARROW_EN: if (C_S_AXI_SUPPORTS_NARROW = 1) generate
    begin


        -----------------------------------------------------------------------
        -- Determine "narrow" burst transfers
        -- Compare the AWSIZE to the BRAM data width
        -----------------------------------------------------------------------

        -- v1.03a
        -- Detect if current burst operation is of size /= to the full
        -- AXI data bus width.  If not, then the current operation is a 
        -- "narrow" burst.
        
        curr_narrow_burst_cmb <= '1' when (curr_awsize /= C_AXI_SIZE_MAX) else '0';


        ---------------------------------------------------------------------------


        curr_narrow_burst_en <= '1' when (bram_addr_ld_en = '1') and 
                                     (curr_awlen /= AXI_AWLEN_ONE) and 
                                     (curr_fixed_burst = '0')
                                    else '0';


        -- Register flag indicating the current operation
        -- is a narrow write burst
        NARROW_BURST_REG: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then

                -- Need to reset this flag at end of narrow burst operation
                -- Use handshaking signals on AXI
                if (S_AXI_AResetn = C_RESET_ACTIVE) or 

                    -- Check for back to back narrow burst.  If that is the case, then
                    -- do not clear curr_narrow_burst flag.

                   (axi_wlast_re = '1' and
                    curr_narrow_burst_en = '0'
                    
                    -- If ECC is enabled, no clear to curr_narrow_burst when WLAST is asserted
                    -- this causes the BRAM address to incorrectly get asserted on the last
                    -- beat in the burst (due to delay in RMW logic)
                    
                    and C_ECC = 0) then

                    curr_narrow_burst <= '0';                  


                elsif (curr_narrow_burst_en = '1') then
                    curr_narrow_burst <= curr_narrow_burst_cmb;
                end if;

            end if;

        end process NARROW_BURST_REG;


        ---------------------------------------------------------------------------

        -- Detect RE of AXI_WLAST
        -- Only used when narrow bursts are enabled.
        
        WLAST_REG: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    axi_wlast_d1 <= '0';
                else
                    -- axi_wlast_d1 <= AXI_WLAST and axi_wready_int_mod;
                    -- CR # 609695
                    axi_wlast_d1 <= AXI_WLAST and axi_wready_int_mod and AXI_WVALID;
                end if;

            end if;

        end process WLAST_REG;

        -- axi_wlast_re <= (AXI_WLAST and axi_wready_int_mod) and not (axi_wlast_d1);
        -- CR # 609695
        axi_wlast_re <= (AXI_WLAST and axi_wready_int_mod and AXI_WVALID) and not (axi_wlast_d1);



    end generate GEN_NARROW_EN;




    ---------------------------------------------------------------------------
    -- Generate registered flag that active burst is a "narrow" burst
    -- and load narrow burst counter
    ---------------------------------------------------------------------------



    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_NARROW_CNT_LD
    -- Purpose:     Only instantiate logic to determine narrow burst counter
    --              load value when narrow bursts are enabled.
    --
    ---------------------------------------------------------------------------

    GEN_NARROW_CNT_LD: if (C_S_AXI_SUPPORTS_NARROW = 1) generate
    
    signal curr_awsize_unsigned : unsigned (2 downto 0) := (others => '0');
    signal axi_byte_div_curr_awsize : integer := 1;
    
    begin


        -- v1.03a
        -- Create narrow burst counter load value based on current operation
        -- "narrow" data width (indicated by value of AWSIZE).
        
        curr_awsize_unsigned <= unsigned (curr_awsize);
            
        -- XST does not support divisors that are not constants and powers of 2.
        -- Create process to create a fixed value for divisor.
        
        -- Replace this statement:
        --     narrow_burst_cnt_ld <= std_logic_vector (
        --                             to_unsigned (
        --                                    (C_AXI_DATA_WIDTH_BYTES / (2**(to_integer (curr_awsize_unsigned))) ) - 1, 
        --                                     C_NARROW_BURST_CNT_LEN));
        
        
        --     -- With this new process and subsequent signal assignment:
        --     DIV_AWSIZE: process (curr_awsize_unsigned)
        --     begin
        --     
        --         case (to_integer (curr_awsize_unsigned)) is
        --             when 0 =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 1;
        --             when 1 =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 2;
        --             when 2 =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 4;
        --             when 3 =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 8;
        --             when 4 =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 16;
        --             when 5 =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 32;
        --             when 6 =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 64;
        --             when 7 =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 128;
        --         --coverage off
        --             when others => axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES;
        --         --coverage on
        --         end case;
        --     
        --     end process DIV_AWSIZE;


        -- w/ CR # 609695

        -- With this new process and subsequent signal assignment:
        DIV_AWSIZE: process (curr_awsize_unsigned)
        begin

            case (curr_awsize_unsigned) is
                when "000" =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 1;
                when "001" =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 2;
                when "010" =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 4;
                when "011" =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 8;
                when "100" =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 16;
                when "101" =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 32;
                when "110" =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 64;
                when "111" =>   axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES / 128;
            --coverage off
                when others => axi_byte_div_curr_awsize <= C_AXI_DATA_WIDTH_BYTES;
            --coverage on
            end case;

        end process DIV_AWSIZE;

        
        
        ---------------------------------------------------------------------------
        
        -- Create narrow burst count load value.
        --
        -- Size is based on [C_NARROW_BURST_CNT_LEN-1 : 0]
        -- For 32-bit BRAM, C_NARROW_BURST_CNT_LEN = 2.
        -- For 64-bit BRAM, C_NARROW_BURST_CNT_LEN = 3.
        -- For 128-bit BRAM, C_NARROW_BURST_CNT_LEN = 4. (etc.)
        --
        -- Signal, narrow_burst_cnt_ld signal is sized according to C_AXI_DATA_WIDTH.
        

        -- Updated else clause for simulation warnings w/ CR # 609695

        narrow_burst_cnt_ld <= std_logic_vector (
                                to_unsigned (
                                        (axi_byte_div_curr_awsize) - 1, 
                                        C_NARROW_BURST_CNT_LEN))
                               when (axi_byte_div_curr_awsize > 0)
                               else std_logic_vector (to_unsigned (0, C_NARROW_BURST_CNT_LEN));


        ---------------------------------------------------------------------------

        -- Register narrow_burst_cnt_ld
        REG_NAR_BRST_CNT_LD: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then

                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    narrow_burst_cnt_ld_reg <= (others => '0');
                elsif (bram_addr_ld_en = '1') then 
                    narrow_burst_cnt_ld_reg <= narrow_burst_cnt_ld;
                else
                    narrow_burst_cnt_ld_reg <= narrow_burst_cnt_ld_reg;
                end if;

            end if;
        end process REG_NAR_BRST_CNT_LD;


        ---------------------------------------------------------------------------
   


    end generate GEN_NARROW_CNT_LD;





    ----------------------------------------------------------------------------

    -- Specify current AWBURST signal 
    -- Input address pipeline MUX
    curr_awburst <= axi_awburst_pipe when (awaddr_pipe_sel = '1') else AXI_AWBURST;

    ----------------------------------------------------------------------------

    -- Specify current AWBURST signal 
    -- Input address pipeline MUX
    curr_awlen <= axi_awlen_pipe when (awaddr_pipe_sel = '1') else AXI_AWLEN;

    
    
    
    -- Duplicate early decode of AWLEN value to use in wr_b2b_elgible logic
    
    REG_CURR_AWLEN: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                curr_awlen_reg_1_or_2 <= '0';

            elsif (bram_addr_ld_en = '1') then

                -- Create merge to decode AWLEN of ONE or TWO
                if (curr_awlen = AXI_AWLEN_ONE) or (curr_awlen = AXI_AWLEN_TWO) then
                    curr_awlen_reg_1_or_2 <= '1';
                else
                    curr_awlen_reg_1_or_2 <= '0';
                end if;
            else
                curr_awlen_reg_1_or_2 <= curr_awlen_reg_1_or_2;
            end if;
        end if;

    end process REG_CURR_AWLEN;
    
        
    
    
    ----------------------------------------------------------------------------





    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_UA_NARROW
    -- Purpose:     Only instantiate logic for burst narrow WRAP operations when
    --              AXI bus protocol is not set for AXI-LITE and narrow
    --              burst operations are supported.
    --
    ---------------------------------------------------------------------------
       
    GEN_UA_NARROW: if (C_S_AXI_SUPPORTS_NARROW = 1) generate
    begin


        ---------------------------------------------------------------------------

        -- New logic to detect unaligned address on a narrow WRAP burst transaction.
        -- If this condition is met, then the narrow burst counter will be
        -- initially loaded with an offset value corresponding to the unalignment
        -- in the ARADDR value.


        -- Create a sub module for all logic to determine the narrow burst counter
        -- offset value on unaligned WRAP burst operations.
        
        -- Module generates the following signals:
        --
        --      => curr_ua_narrow_wrap, to indicate the current
        --         operation is an unaligned narrow WRAP burst.
        --
        --      => curr_ua_narrow_incr, to load narrow burst counter
        --         for unaligned INCR burst operations.
        --
        --      => ua_narrow_load, narrow counter load value.
        --         Sized, (C_NARROW_BURST_CNT_LEN-1 downto 0)
        --        
        ---------------------------------------------------------------------------
      

        ---------------------------------------------------------------------------
        -- Instance: I_UA_NARROW
        --
        -- Description:
        --
        --      Creates a narrow burst count load value when an operation
        --      is an unaligned narrow WRAP or INCR burst type.  Used by
        --      I_NARROW_CNT module.
        --
        --      Logic is customized for each C_AXI_DATA_WIDTH.
        ---------------------------------------------------------------------------

        I_UA_NARROW : entity work.ua_narrow
        generic map (
            C_AXI_DATA_WIDTH            =>  C_AXI_DATA_WIDTH            ,
            C_BRAM_ADDR_ADJUST_FACTOR   =>  C_BRAM_ADDR_ADJUST_FACTOR   ,
            C_NARROW_BURST_CNT_LEN      =>  C_NARROW_BURST_CNT_LEN
        )
        port map (

            curr_wrap_burst             =>  curr_wrap_burst             ,       -- in
            curr_incr_burst             =>  curr_incr_burst             ,       -- in
            bram_addr_ld_en             =>  bram_addr_ld_en             ,       -- in

            curr_axlen                  =>  curr_awlen                  ,       -- in
            curr_axsize                 =>  curr_awsize                 ,       -- in
            curr_axaddr_lsb             =>  curr_awaddr_lsb             ,       -- in
            
            curr_ua_narrow_wrap         =>  curr_ua_narrow_wrap         ,       -- out
            curr_ua_narrow_incr         =>  curr_ua_narrow_incr         ,       -- out
            ua_narrow_load              =>  ua_narrow_load                      -- out

        );    
    
    
    
        -- Use in all C_AXI_DATA_WIDTH generate statements

        -- Only probe least significant BRAM address bits
        -- C_BRAM_ADDR_ADJUST_FACTOR offset down to 0.
        curr_awaddr_lsb <= axi_awaddr_pipe (C_BRAM_ADDR_ADJUST_FACTOR-1 downto 0) 
                            when (awaddr_pipe_sel = '1') else 
                        AXI_AWADDR (C_BRAM_ADDR_ADJUST_FACTOR-1 downto 0);




    end generate GEN_UA_NARROW;

   
    

    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_AW_SNG
    -- Purpose:     If single port BRAM configuration, set all AW flags from
    --              logic generated in sng_port_arb module.
    --
    ---------------------------------------------------------------------------
    

    GEN_AW_SNG: if (C_SINGLE_PORT_BRAM = 1) generate
    begin
        
        aw_active <= Arb2AW_Active;
        bram_addr_ld_en <= aw_active_re;
        AW2Arb_Active_Clr <= aw_active_clr;
        AW2Arb_Busy <= wr_busy_reg;
        AW2Arb_BVALID_Cnt <= bvalid_cnt;
        
 
    end generate GEN_AW_SNG;    
    
    
    
    -- Rising edge detect of aw_active
    -- For single port configurations, aw_active = Arb2AW_Active.
    -- For dual port configurations, aw_active generated in ADDR SM.
    RE_AW_ACT: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1') then
            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                aw_active_d1 <= '0';
            else
                aw_active_d1 <= aw_active;
            end if;
        end if;
    end process RE_AW_ACT;
    
    aw_active_re <= '1' when (aw_active = '1' and aw_active_d1 = '0') else '0';

    

    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_AW_DUAL
    -- Purpose:     Generate AW control state machine logic only when AXI4
    --              controller is configured for dual port mode.  In dual port
    --              mode, wr_chnl has full access over AW & port A of BRAM.
    --
    ---------------------------------------------------------------------------
    
    
    GEN_AW_DUAL: if (C_SINGLE_PORT_BRAM = 0) generate
    begin


        AW2Arb_Active_Clr <= '0';   -- Only used in single port case
        AW2Arb_Busy <= '0';         -- Only used in single port case

        AW2Arb_BVALID_Cnt <= (others => '0');


        ----------------------------------------------------------------------------


        
        REG_LAST_DATA_ACK: process (S_AXI_AClk)
        begin
            if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    last_data_ack_mod <= '0';
                else
                    -- last_data_ack_mod <= AXI_WLAST;
                    -- CR # 609695
                    last_data_ack_mod <= AXI_WLAST and AXI_WVALID and axi_wready_int_mod;
                end if;
            end if;
        end process REG_LAST_DATA_ACK;



        ----------------------------------------------------------------------------




        ---------------------------------------------------------------------------
        -- WR ADDR State Machine
        --
        -- Description:     Central processing unit for AXI write address
        --                  channel interface handling and handshaking.
        --
        -- Outputs:         awaddr_pipe_ld      Combinatorial
        --                  awaddr_pipe_sel
        --                  bram_addr_ld_en
        --
        --
        --
        -- WR_ADDR_SM_CMB_PROCESS:      Combinational process to determine next state.
        -- WR_ADDR_SM_REG_PROCESS:      Registered process of the state machine.
        ---------------------------------------------------------------------------
        WR_ADDR_SM_CMB_PROCESS: process ( AXI_AWVALID,
                                          bvalid_cnt_max,
                                          axi_awaddr_full,
                                          aw_active,

                                          wr_b2b_elgible,           
                                          last_data_ack_mod,        

                                          wr_addr_sm_cs )

        begin

        -- assign default values for state machine outputs
        wr_addr_sm_ns <= wr_addr_sm_cs;
        awaddr_pipe_ld_i <= '0';
        bram_addr_ld_en_i <= '0';
        aw_active_set_i <= '0';


        case wr_addr_sm_cs is


                ---------------------------- IDLE State ---------------------------

                when IDLE =>


                    -- Check for pending operation in address pipeline that may
                    -- be elgible for back-to-back performance to BRAM.

                    -- Prevent loading BRAM address counter if BID FIFO can not
                    -- store the AWID value.  Check the BVALID counter.

                    if (wr_b2b_elgible = '1') and (last_data_ack_mod = '1') and
                       -- Ensure the BVALID counter does not roll over (max = 8 ID values)
                       (bvalid_cnt_max = '0') then

                        wr_addr_sm_ns <= IDLE;

                        -- Load BRAM address counter from pipelined value
                        bram_addr_ld_en_i <= '1';

                        aw_active_set_i <= '1';


                    -- Ensure AWVALID is recognized.
                    -- Address pipeline may be loaded, but BRAM counter 
                    -- can not be loaded if at max of BID FIFO.
                    
                    elsif (AXI_AWVALID = '1') then
                           
                        -- If address pipeline is full
                        -- AWReady output is negated

                        -- If write address logic is ready for new operation
                        -- Load BRAM address counter and set aw_active = '1'
                        -- If address pipeline is already full to start next operation
                        -- load address counter from pipeline.

                        -- Prevent loading BRAM address counter if BID FIFO can not
                        -- store the AWID value.  Check the BVALID counter.
                    
                        -- Remain in this state
                        if (aw_active = '0') and 
                          -- Ensure the BVALID counter does not roll over (max = 8 ID values)
                           (bvalid_cnt_max = '0') then

                            wr_addr_sm_ns <= IDLE;
                            
                            -- Stay in this state to capture AWVALID if asserted
                            -- in next clock cycle.

                            bram_addr_ld_en_i <= '1';

                            aw_active_set_i <= '1';


                        -- Address counter is currently busy.
                        -- No check on BVALID counter for address pipeline load.
                        -- Only the BRAM address counter is checked for BID FIFO capacity.
                        
                        else

                            -- Check if AWADDR pipeline is not full and can be loaded
                            if (axi_awaddr_full = '0') then

                                wr_addr_sm_ns <= LD_AWADDR;
                                awaddr_pipe_ld_i <= '1';

                            end if;

                        end if; -- aw_active


                    -- Pending operation in pipeline that is waiting
                    -- until current operation is complete (aw_active = '0')

                    elsif (axi_awaddr_full = '1') and (aw_active = '0') and 
                          -- Ensure the BVALID counter does not roll over (max = 8 ID values)
                          (bvalid_cnt_max = '0') then

                        wr_addr_sm_ns <= IDLE;

                        -- Load BRAM address counter from pipelined value
                        bram_addr_ld_en_i <= '1';

                        aw_active_set_i <= '1';

                    end if; -- AWVALID




                ---------------------------- LD_AWADDR State ---------------------------

                when LD_AWADDR =>

                    wr_addr_sm_ns <= IDLE;

                    if (wr_b2b_elgible = '1') and (last_data_ack_mod = '1') and 
                       -- Ensure the BVALID counter does not roll over (max = 8 ID values)
                       (bvalid_cnt_max = '0') then

                        -- Load BRAM address counter from pipelined value
                        bram_addr_ld_en_i <= '1';

                        aw_active_set_i <= '1';

                    end if;


        --coverage off
                ------------------------------ Default ----------------------------
                when others =>
                    wr_addr_sm_ns <= IDLE;
        --coverage on

            end case;

        end process WR_ADDR_SM_CMB_PROCESS;



        ---------------------------------------------------------------------------

        -- CR # 582705
        -- Ensure combinatorial SM output signals do not get set before
        -- the end of the reset (and ARREAADY can be set).
        bram_addr_ld_en <= bram_addr_ld_en_i and axi_aresetn_d2;
        aw_active_set <= aw_active_set_i and axi_aresetn_d2;
        awaddr_pipe_ld <= awaddr_pipe_ld_i and axi_aresetn_d2;


        WR_ADDR_SM_REG_PROCESS: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                -- if (S_AXI_AResetn = C_RESET_ACTIVE) then

                -- CR # 582705
                -- Ensure that ar_active does not get asserted (from SM) before 
                -- the end of reset and the ARREADY flag is set.
                if (axi_aresetn_d2 = C_RESET_ACTIVE) then
                    wr_addr_sm_cs <= IDLE;                
                else
                    wr_addr_sm_cs <= wr_addr_sm_ns;
                end if;
            end if;

        end process WR_ADDR_SM_REG_PROCESS;


        ---------------------------------------------------------------------------

        -- Asserting awaddr_pipe_sel outside of SM logic
        -- The BRAM address counter will get loaded with value in AWADDR pipeline
        -- when data is stored in the AWADDR pipeline.

        awaddr_pipe_sel <= '1' when (axi_awaddr_full = '1') else '0';
        
        ---------------------------------------------------------------------------

        -- Register for aw_active 
        REG_AW_ACT: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
            
                -- CR # 582705
                -- if (S_AXI_AResetn = C_RESET_ACTIVE) then
                if (axi_aresetn_d2 = C_RESET_ACTIVE) then
                    aw_active <= '0';
                
                elsif (aw_active_set = '1') then 
                    aw_active <= '1';

                elsif (aw_active_clr = '1') then 
                    aw_active <= '0';
                else 
                    aw_active <= aw_active;
                end if;
            end if;
        end process REG_AW_ACT;

        ---------------------------------------------------------------------------


    end generate GEN_AW_DUAL;










    ---------------------------------------------------------------------------
    -- *** AXI Write Data Channel Interface ***
    ---------------------------------------------------------------------------




    ---------------------------------------------------------------------------
    -- AXI WrData Buffer/Register
    ---------------------------------------------------------------------------

    GEN_WRDATA: for i in C_AXI_DATA_WIDTH-1 downto 0 generate
    begin

        REG_WRDATA: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (wrdata_reg_ld = '1') then
                    bram_wrdata_int (i) <= AXI_WDATA (i);
                else
                    bram_wrdata_int (i) <= bram_wrdata_int (i);

                end if;
            end if;

        end process REG_WRDATA;

    end generate GEN_WRDATA;




    ---------------------------------------------------------------------------
    -- Generate:    GEN_WR_NO_ECC
    -- Purpose:     Generate BRAM WrData and WE signals based on AXI_WRDATA
    --              and AXI_WSTRBs when C_ECC is disabled.
    ---------------------------------------------------------------------------

    GEN_WR_NO_ECC: if C_ECC = 0 generate
    begin
    

        ---------------------------------------------------------------------------
        -- AXI WSTRB Buffer/Register
        -- Use AXI write data channel data strobe signals to generate BRAM WE.
        ---------------------------------------------------------------------------

        REG_BRAM_WE: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                -- Ensure we don't clear WE when loading subsequent WSTRB value
                if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                   (clr_bram_we = '1' and bram_we_ld = '0') then 
                    bram_we_int <= (others => '0');

                elsif (bram_we_ld = '1') then                          
                    bram_we_int <= AXI_WSTRB;

                else
                    bram_we_int <= bram_we_int;  
                end if;

            end if;

        end process REG_BRAM_WE;




        ----------------------------------------------------------------------------

        -- New logic to detect if pending operation in AWADDR pipeline is
        -- elgible for back-to-back no "bubble" performance. And BRAM address
        -- counter can be loaded upon last BRAM address presented for the current
        -- operation.

        -- This condition exists when the AWADDR pipeline is full and the pending
        -- operation is a burst >= length of two data beats.
        -- And not a FIXED burst type (must be INCR or WRAP type).
        --
        -- Narrow bursts are be neglible 
        --
        -- Add check to complete current single and burst of two data bursts
        -- prior to loading BRAM counter

        wr_b2b_elgible <= '1' when (axi_awaddr_full = '1') and

                                    -- Replace comparator logic here with register signal (pre pipeline stage
                                    -- on axi_awlen_pipe value
                                    -- Use merge in decode of ONE or TWO
                                   (axi_awlen_pipe_1_or_2 /= '1') and

                                   (axi_awburst_pipe_fixed /= '1') and

                                   -- Use merge in decode of ONE or TWO
                                   (curr_awlen_reg_1_or_2 /= '1')

                            else '0';


        ----------------------------------------------------------------------------


    end generate GEN_WR_NO_ECC;


    ---------------------------------------------------------------------------
    -- Generate:    GEN_WR_ECC
    -- Purpose:     Generate BRAM WrData and WE signals based on AXI_WRDATA
    --              and AXI_WSTRBs when C_ECC is enabled.
    ---------------------------------------------------------------------------

    GEN_WR_ECC: if C_ECC = 1 generate
    begin
    
    
        wr_b2b_elgible <= '0';

        ---------------------------------------------------------------------------
        -- AXI WSTRB Buffer/Register
        -- Use AXI write data channel data strobe signals to generate BRAM WE.
        ---------------------------------------------------------------------------

        REG_BRAM_WE: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                -- Ensure we don't clear WE when loading subsequent WSTRB value
                if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                   (reset_bram_we = '1') then
                    bram_we_int <= (others => '0');

                elsif (set_bram_we = '1') then
                    bram_we_int <= (others => '1');

                else
                    bram_we_int <= bram_we_int;  
                end if;

            end if;

        end process REG_BRAM_WE;


    end generate GEN_WR_ECC;



    -----------------------------------------------------------------------



    -- v1.03a

    -----------------------------------------------------------------------
    --
    --  Implement WREADY to be a registered output.  Used by all configurations.
    --  This will disable the back-to-back streamlined WDATA
    --  for write operations to BRAM.
    --
    -----------------------------------------------------------------------
    
    REG_WREADY: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                axi_wready_int_mod <= '0';

            -- Keep AXI WREADY asserted unless write data register is full
            -- Use combinatorial signal from SM.
            
            elsif (axi_wdata_full_cmb = '1') then
                axi_wready_int_mod <= '0';
            else
                axi_wready_int_mod <= '1';

            end if;
        end if;

    end process REG_WREADY;

    
        

    ---------------------------------------------------------------------------







    ----------------------------------------------------------------------------
    -- Generate:    GEN_WDATA_SM_ECC
    -- Purpose:     Create seperate SM for ECC read-modify-write logic.
    --              Only used in single port BRAM mode.  So, no address
    --              pipelining.  Must use aw_active from arbitration logic
    --              to determine start of write to BRAM.
    --
    ----------------------------------------------------------------------------

    -- Test using same write data SM for single or dual port configuration.
    -- The difference is the source of aw_active.  In a single port configuration,
    -- the aw_active is coming from the arbiter SM.  In a dual port configuration,
    -- the aw_active is coming from the write address SM in this module.

    GEN_WDATA_SM_ECC: if C_ECC = 1 generate
    begin

        -- Unused in this SM configuration
        bram_we_ld <= '0';
        bram_addr_rst_cmb <= '0';    

        -- Output only used by ECC register module.
        Active_Wr <= active_wr_reg;


        ---------------------------------------------------------------------------
        --
        -- WR DATA State Machine
        --
        -- Description:     Central processing unit for AXI write data
        --                  channel interface handling and AXI write data response
        --                  handshaking when ECC is enabled.  SM will handle
        --                  each transaction as a read-modify-write to ensure
        --                  the correct ECC bits are stored in BRAM.
        --
        --                  Dedicated to single port BRAM interface.  Transaction
        --                  is not initiated until valid AWADDR is arbitration,
        --                  ie. aw_active will be asserted.  SM can do early reads
        --                  while waiting for WVALID to be asserted.
        --
        --                  Valid AWADDR recieve indicator comes from arbitration 
        --                  logic (aw_active will be asserted).
        --
        -- Outputs:         Name                    Type
        --
        --                  aw_active_clr           Not Registered
        --                  axi_wdata_full_reg      Registered
        --                  wrdata_reg_ld           Not Registered
        --                  bvalid_cnt_inc          Not Registered 
        --                  bram_addr_inc           Not Registered
        --                  bram_en_int             Registered
        --                  reset_bram_we           Not Registered
        --                  set_bram_we             Not Registered
        --
        --
        -- WR_DATA_ECC_SM_CMB_PROCESS:      Combinational process to determine next state.
        -- WR_DATA_ECC_SM_REG_PROCESS:      Registered process of the state machine.
        --
        ---------------------------------------------------------------------------

        WR_DATA_ECC_SM_CMB_PROCESS: process (   AXI_WVALID,
                                                AXI_WLAST,
                                                aw_active,
                                                wr_busy_reg,
                                                axi_wdata_full_reg,
                                                axi_wr_burst,   
                                                AXI_BREADY,
                                                active_wr_reg,
                                                wr_data_ecc_sm_cs )

        begin

        -- Assign default values for state machine outputs
        wr_data_ecc_sm_ns <= wr_data_ecc_sm_cs;
        aw_active_clr <= '0';
        wr_busy_cmb <= wr_busy_reg;
        bvalid_cnt_inc <= '0';              
        
        wrdata_reg_ld <= '0';
        reset_bram_we <= '0';
        set_bram_we_cmb <= '0';
        bram_en_cmb <= '0';
        bram_addr_inc <= '0';

        axi_wdata_full_cmb <= axi_wdata_full_reg;
        axi_wr_burst_cmb <= axi_wr_burst;   
        active_wr_cmb <= active_wr_reg;


        case wr_data_ecc_sm_cs is


                ---------------------------- IDLE State ---------------------------

                when IDLE =>


                    -- Prior to AWVALID assertion, WVALID may be asserted
                    -- and data accepted into WDATA register.
                    -- Catch this condition and ensure the register full flag is set.
                    -- Check that data pipeline is not already full.
                    
                    if (AXI_WVALID = '1') and (axi_wdata_full_reg = '0') then
                        
                        wrdata_reg_ld <= '1';               -- Load write data register
                        axi_wdata_full_cmb <= '1';          -- Hold off accepting any new write data
                        
                        -- w/ CR # 609695
                        --
                        --   -- Set flag to check if single or not
                        --   if (AXI_WLAST = '1') then
                        --       axi_wr_burst_cmb <= '0';
                        --   else
                        --       axi_wr_burst_cmb <= '1';
                        --   end if;
                        
                        axi_wr_burst_cmb <= not (AXI_WLAST);    -- Set flag to check if single or not
                   
                    end if;



                    -- Check if AWVALID is asserted & wins arbitration
                    if (aw_active = '1') then
                    
                        active_wr_cmb <= '1';           -- Set flag that RMW SM is active
                                                        -- Controls mux select for BRAM and ECC register module 
                                                        -- (Set to '1' wr_chnl or '0' for rd_chnl control)
                        
                        bram_en_cmb <= '1';             -- Initiate BRAM read transfer
                        reset_bram_we <= '1';           -- Disable Port A write enables

                        -- Will proceed to read-modify-write if we get a
                        -- valid write address early (before WVALID)

                        wr_data_ecc_sm_ns <= RMW_RD_DATA;


                    end if; -- WVALID


                ------------------------- RMW_RD_DATA State -------------------------

                when RMW_RD_DATA =>


                    -- Check if data to write is available in data pipeline
                    if (axi_wdata_full_reg = '1') then
                        wr_data_ecc_sm_ns <= RMW_CHK_DATA;   
                        
                    
                    -- Else may have address, but not yet data from W channel
                    elsif (AXI_WVALID = '1') then
                        
                        -- Ensure that WDATA pipeline is marked as full, so WREADY negates
                        axi_wdata_full_cmb <= '1';          -- Hold off accepting any new write data
                        
                        wrdata_reg_ld <= '1';               -- Load write data register
                    
                        -- w/ CR # 609695
                        --
                        --   -- Set flag to check if single or not
                        --   if (AXI_WLAST = '1') then
                        --       axi_wr_burst_cmb <= '0';
                        --   else
                        --       axi_wr_burst_cmb <= '1';
                        --   end if;
                        
                        axi_wr_burst_cmb <= not (AXI_WLAST);    -- Set flag to check if single or not
                        
                        wr_data_ecc_sm_ns <= RMW_CHK_DATA;   

                    else
                        -- Hold here and wait for write data
                        wr_data_ecc_sm_ns <= RMW_RD_DATA;

                    end if;



                ------------------------- RMW_CHK_DATA State -------------------------

                when RMW_CHK_DATA =>
                
                
                    -- New state here to add register stage on calculating
                    -- checkbits for read data and then muxing/creating new
                    -- checkbits for write cycle.
                    
                    
                    -- Go immediately to MODIFY stage in RMW sequence
                    wr_data_ecc_sm_ns <= RMW_MOD_DATA;

                    set_bram_we_cmb <= '1';             -- Enable all WEs to BRAM



                ------------------------- RMW_MOD_DATA State -------------------------

                when RMW_MOD_DATA =>


                    -- Modify clock cycle in RMW sequence
                    -- Only reach this state after a read AND we have data
                    -- in the write data pipeline to modify and subsequently write to BRAM.

                    bram_en_cmb <= '1';             -- Initiate BRAM write transfer
                    
                    -- Can clear WDATA pipeline full condition flag                   
                    if (axi_wr_burst = '1') then
                        axi_wdata_full_cmb <= '0';
                    end if;
                    
                    
                    wr_data_ecc_sm_ns <= RMW_WR_DATA;     -- Go to write data to BRAM
                    
                    
                    
                ------------------------- RMW_WR_DATA State -------------------------

                when RMW_WR_DATA =>


                    -- Check if last data beat in a burst (or the write is a single)
                    
                    if (axi_wr_burst = '0') then

                        -- Can clear WDATA pipeline full condition flag now that
                        -- write data has gone out to BRAM (for single data transfers)
                        axi_wdata_full_cmb <= '0';  
                        
                        bvalid_cnt_inc <= '1';              -- Set flag to assert BVALID and increment counter
                        wr_data_ecc_sm_ns <= IDLE;          -- Go back to IDLE, BVALID assertion is seperate
                        wr_busy_cmb <= '0';                 -- Clear flag to arbiter
                        active_wr_cmb <= '0';               -- Clear flag (wr_chnl is done accessing BRAM)
                                                            -- Used for single port arbitration SM
                        axi_wr_burst_cmb <= '0';
                        
                        
                        aw_active_clr <= '1';               -- Clear aw_active flag
                        reset_bram_we <= '1';               -- Disable Port A write enables   
                        
                    else
                    
                        -- Continue with read-modify-write sequence for write burst
                                                
                        -- If next data beat is available on AXI, capture the data
                        if (AXI_WVALID = '1') then
                            
                            wrdata_reg_ld <= '1';               -- Load write data register
                            axi_wdata_full_cmb <= '1';          -- Hold off accepting any new write data
                            
                            
                            -- w/ CR # 609695
                            --
                            --   -- Set flag to check if single or not
                            --   if (AXI_WLAST = '1') then
                            --       axi_wr_burst_cmb <= '0';
                            --   else
                            --       axi_wr_burst_cmb <= '1';
                            --   end if;
                            
                            axi_wr_burst_cmb <= not (AXI_WLAST);    -- Set flag to check if single or not
                            
                        end if;

                        
                        -- After write cycle (in RMW) => Increment BRAM address counter
                        bram_addr_inc <= '1';

                        bram_en_cmb <= '1';             -- Initiate BRAM read transfer
                        reset_bram_we <= '1';           -- Disable Port A write enables

                        -- Will proceed to read-modify-write if we get a
                        -- valid write address early (before WVALID)
                        wr_data_ecc_sm_ns <= RMW_RD_DATA;


                    end if;
                    

        --coverage off

                ------------------------------ Default ----------------------------

                when others =>
                    wr_data_ecc_sm_ns <= IDLE;

        --coverage on

            end case;

        end process WR_DATA_ECC_SM_CMB_PROCESS;


        ---------------------------------------------------------------------------


        WR_DATA_ECC_SM_REG_PROCESS: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    wr_data_ecc_sm_cs <= IDLE;
                    bram_en_int <= '0';
                    axi_wdata_full_reg <= '0';
                    wr_busy_reg <= '0';
                    active_wr_reg <= '0';
                    set_bram_we <= '0';

                else
                    wr_data_ecc_sm_cs <= wr_data_ecc_sm_ns;
                    bram_en_int <= bram_en_cmb;
                    axi_wdata_full_reg <= axi_wdata_full_cmb;
                    wr_busy_reg <= wr_busy_cmb;
                    active_wr_reg <= active_wr_cmb;
                    
                    set_bram_we <= set_bram_we_cmb;

                end if;
            end if;

        end process WR_DATA_ECC_SM_REG_PROCESS;



        ---------------------------------------------------------------------------


    end generate GEN_WDATA_SM_ECC;
    

    
    
    
    -- v1.03a
    
    

    ----------------------------------------------------------------------------
    --
    -- Generate:    GEN_WDATA_SM_NO_ECC_SNG_REG_WREADY
    -- Purpose:     Create seperate SM use case of no ECC (no read-modify-write)
    --              and single port BRAM configuration (no back to back operations
    --              are supported).  Must wait for aw_active from arbiter to indicate
    --              control on BRAM interface.
    --
    ----------------------------------------------------------------------------

    GEN_WDATA_SM_NO_ECC_SNG_REG_WREADY: if C_ECC = 0 and 
                                           C_SINGLE_PORT_BRAM = 1  
                                           generate
    begin


        -- Unused in this SM configuration
        wr_busy_cmb <= '0';             -- Unused
        wr_busy_reg <= '0';             -- Unused
        active_wr_cmb <= '0';           -- Unused
        active_wr_reg <= '0';           -- Unused
        Active_Wr <= '0';               -- Unused
        
        

        ---------------------------------------------------------------------------
        --
        -- WR DATA State Machine
        --
        -- Description:     Central processing unit for AXI write data
        --                  channel interface handling and AXI write data response
        --                  handshaking.
        --
        -- Outputs:         Name                    Type
        --                  aw_active_clr           Not Registered
        --                  bvalid_cnt_inc          Not Registered  
        --                  wrdata_reg_ld           Not Registered
        --                  bram_we_ld              Not Registered
        --                  bram_en_int             Registered
        --                  clr_bram_we             Registered
        --                  bram_addr_inc           Not Registered
        --                  wrdata_reg_ld           Not Registered
        --
        --                  Note:
        --
        --                  On "narrow burst transfers" BRAM address only 
        --                  gets incremented at BRAM data width.
        --                  On WRAP bursts, the BRAM address must wrap when 
        --                  the max is reached
        --
        --
        --
        -- WR_DATA_SNG_SM_CMB_PROCESS:      Combinational process to determine next state.
        -- WR_DATA_SNG_SM_REG_PROCESS:      Registered process of the state machine.
        --
        ---------------------------------------------------------------------------

        WR_DATA_SNG_SM_CMB_PROCESS: process (   AXI_WVALID,
                                                AXI_WLAST,
                                                aw_active,
                                                
                                                axi_wr_burst,                                                
                                                axi_wdata_full_reg,

                                                wr_data_sng_sm_cs )

        begin

        -- assign default values for state machine outputs
        wr_data_sng_sm_ns <= wr_data_sng_sm_cs;
        aw_active_clr <= '0';
        
        bvalid_cnt_inc <= '0';         
        axi_wr_burst_cmb <= axi_wr_burst;    

        wrdata_reg_ld <= '0';
        bram_we_ld <= '0';

        bram_en_cmb <= '0';
        clr_bram_we_cmb <= '0';

        bram_addr_inc <= '0';
        bram_addr_rst_cmb <= '0';

        axi_wdata_full_cmb <= axi_wdata_full_reg;


        case wr_data_sng_sm_cs is


                ---------------------------- IDLE State ---------------------------

                when IDLE =>


                    -- Prior to AWVALID assertion, WVALID may be asserted
                    -- and data accepted into WDATA register.
                    -- Catch this condition and ensure the register full flag is set.
                    -- Check that data pipeline is not already full.
                    --
                    -- Modify WE pipeline and mux to BRAM
                    -- as well.  Since WE may be asserted early (when pipeline is loaded),
                    -- but not yet ready to go out to BRAM.
                    --
                    -- Only first data beat will be accepted early into data pipeline.
                    -- All remaining beats in a burst will only be accepted upon WVALID.
                    
                    if (AXI_WVALID = '1') and (axi_wdata_full_reg = '0') then
                        
                        wrdata_reg_ld <= '1';                   -- Load write data register
                        bram_we_ld <= '1';                      -- Load WE register
                        axi_wdata_full_cmb <= '1';              -- Hold off accepting any new write data
                        axi_wr_burst_cmb <= not (AXI_WLAST);    -- Set flag to check if single or not

                    end if;

                   
                    -- Wait for WVALID and aw_active to initiate write transfer
                    if (aw_active = '1' and 
                        (AXI_WVALID = '1' or axi_wdata_full_reg = '1')) then

                        
                        -- If operation is a single, then it goes directly out to BRAM
                        -- WDATA register is never marked as FULL in this case.

                        -- If data pipeline is not previously loaded, do so now.
                        if (axi_wdata_full_reg = '0') then
                            wrdata_reg_ld <= '1';           -- Load write data register
                            bram_we_ld <= '1';              -- Load WE register
                        end if;
                        
                        -- Initiate BRAM write transfer
                        bram_en_cmb <= '1';
                        
                        -- If data goes out to BRAM, mark data register as EMPTY
                        axi_wdata_full_cmb <= '0';

                        axi_wr_burst_cmb <= not (AXI_WLAST);    -- Set flag to check if single or not
                    
                        -- Check for singles, by checking WLAST assertion w/ WVALID
                        -- Only if write data pipeline is not yet filled, check WLAST
                        -- Otherwise, if pipeline is already full, use registered value of WLAST
                        -- to check for single vs. burst write operation.
                        if (AXI_WLAST = '1' and axi_wdata_full_reg = '0') or
                           (axi_wdata_full_reg = '1' and axi_wr_burst = '0') then

                            -- Single data write
                            wr_data_sng_sm_ns <= SNG_WR_DATA;

                            -- Set flag to assert BVALID and increment counter
                            bvalid_cnt_inc <= '1';

                            -- BRAM WE only asserted for single clock cycle
                            clr_bram_we_cmb <= '1';

                        else
                            -- Burst data write
                            wr_data_sng_sm_ns <= BRST_WR_DATA;

                        end if; -- WLAST             
                    
                    end if;


                ------------------------- SNG_WR_DATA State -------------------------

                when SNG_WR_DATA =>

                    
                    -- If WREADY is registered, then BVALID generation is seperate
                    -- from write data flow.
                                    
                    -- Go back to IDLE automatically
                    -- BVALID will get asserted seperately from W channel
                    wr_data_sng_sm_ns <= IDLE;
                    bram_addr_rst_cmb <= '1';
                    aw_active_clr <= '1';
                    

                    -- Check for capture of next data beat (WREADY will be asserted)
                    if (AXI_WVALID = '1') then
                    
                        wrdata_reg_ld <= '1';                   -- Load write data register
                        bram_we_ld <= '1';                      -- Load WE register
                        axi_wdata_full_cmb <= '1';              -- Hold off accepting any new write data
                        axi_wr_burst_cmb <= not (AXI_WLAST);    -- Set flag to check if single or not

                    else
                        axi_wdata_full_cmb <= '0';              -- If no next data, ensure data register is flagged EMPTY.

                    end if;                                        
                    
                    
                ------------------------- BRST_WR_DATA State -------------------------

                when BRST_WR_DATA =>


                    -- Reach this state at the 2nd data beat of a burst
                    -- AWADDR is already accepted
                    -- Continue to accept data from AXI write channel
                    -- and wait for assertion of WLAST

                    -- Check that WVALID remains asserted for burst
                    -- If negated, indicates throttling from AXI master
                    if (AXI_WVALID = '1') then

                        -- If WVALID is asserted for the 2nd and remaining 
                        -- data beats of the transfer
                        -- Continue w/ BRAM write enable assertion & advance
                        -- write data register
                        
                        -- Write data goes directly out to BRAM.
                        -- WDATA register is never marked as FULL in this case.
                        
                        wrdata_reg_ld <= '1';           -- Load write data register
                        bram_we_ld <= '1';              -- Load WE register

                        -- Initiate BRAM write transfer
                        bram_en_cmb <= '1';

                        -- Increment BRAM address counter
                        bram_addr_inc <= '1';


                        -- Check for last data beat in burst transfer
                        if (AXI_WLAST = '1') then

                            -- Last/single data write
                            wr_data_sng_sm_ns <= SNG_WR_DATA;

                            -- Set flag to assert BVALID and increment counter
                            bvalid_cnt_inc <= '1';

                            -- BRAM WE only asserted for single clock cycle
                            clr_bram_we_cmb <= '1';

                        end if; -- WLAST


                    -- Throttling
                    -- Suspend BRAM write & halt write data & WE register load
                    else

                        -- Negate write data register load
                        wrdata_reg_ld <= '0';

                        -- Negate WE register load
                        bram_we_ld <= '0';

                        -- Negate write to BRAM
                        bram_en_cmb <= '0';

                        -- Do not increment BRAM address counter
                        bram_addr_inc <= '0';

                    end if; -- WVALID



        --coverage off

                ------------------------------ Default ----------------------------

                when others =>
                    wr_data_sng_sm_ns <= IDLE;

        --coverage on

            end case;

        end process WR_DATA_SNG_SM_CMB_PROCESS;


        ---------------------------------------------------------------------------


        WR_DATA_SNG_SM_REG_PROCESS: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    wr_data_sng_sm_cs <= IDLE;
                    bram_en_int <= '0';
                    clr_bram_we <= '0';
                    axi_wdata_full_reg <= '0';
                    
                else
                    wr_data_sng_sm_cs <= wr_data_sng_sm_ns;
                    bram_en_int <= bram_en_cmb;
                    clr_bram_we <= clr_bram_we_cmb;
                    axi_wdata_full_reg <= axi_wdata_full_cmb;

                end if;
            end if;

        end process WR_DATA_SNG_SM_REG_PROCESS;


        ---------------------------------------------------------------------------



    end generate GEN_WDATA_SM_NO_ECC_SNG_REG_WREADY;
    





    ----------------------------------------------------------------------------
    --
    -- Generate:    GEN_WDATA_SM_NO_ECC_DUAL_REG_WREADY
    --
    -- Purpose:     Create seperate SM for new logic to register out WREADY
    --              signal.  Behavior for back-to-back operations is different
    --              than with combinatorial genearted WREADY output to AXI.
    --          
    --              New SM design supports seperate WREADY and BVALID responses.
    --
    --              New logic here for axi_bvalid_int output register based
    --              on counter design of BVALID.
    --
    ----------------------------------------------------------------------------

    GEN_WDATA_SM_NO_ECC_DUAL_REG_WREADY: if C_ECC = 0 and 
                                            C_SINGLE_PORT_BRAM = 0 
                                            generate

    begin

        
        -- Unused in this SM configuration               
        active_wr_cmb <= '0';           -- Unused
        active_wr_reg <= '0';           -- Unused
        Active_Wr <= '0';               -- Unused
        
        wr_busy_cmb <= '0';             -- Unused
        wr_busy_reg <= '0';             -- Unused


        ---------------------------------------------------------------------------
        --
        -- WR DATA State Machine
        --
        -- Description:     Central processing unit for AXI write data
        --                  channel interface handling and AXI write data response
        --                  handshaking.
        --
        -- Outputs:         Name                    Type
        --                  bvalid_cnt_inc          Not Registered  
        --                  aw_active_clr           Not Registered
        --                  delay_aw_active_clr     Registered
        --                  axi_wdata_full_reg      Registered
        --                  bram_en_int             Registered
        --                  wrdata_reg_ld           Not Registered
        --                  bram_we_ld              Not Registered
        --                  clr_bram_we             Registered
        --                  bram_addr_inc
        --
        --                  Note:
        --
        --                  On "narrow burst transfers" BRAM address only 
        --                  gets incremented at BRAM data width.
        --                  On WRAP bursts, the BRAM address must wrap when 
        --                  the max is reached
        --
        --                  Add check on BVALID counter max.  Check with
        --                  AWVALID assertions (since AWID is connected to AWVALID).
        --
        --
        -- WR_DATA_SM_CMB_PROCESS:      Combinational process to determine next state.
        -- WR_DATA_SM_REG_PROCESS:      Registered process of the state machine.
        --
        ---------------------------------------------------------------------------

        WR_DATA_SM_CMB_PROCESS: process ( AXI_WVALID,
                                          AXI_WLAST,
                                          bvalid_cnt_max,
                                          bvalid_cnt_amax,
                                          
                                          aw_active,
                                          delay_aw_active_clr,
                                          AXI_AWVALID,
                                          axi_awready_int,

                                          bram_addr_ld_en,          
                                          axi_awaddr_full,          
                                          awaddr_pipe_sel,          

                                          axi_wr_burst,
                                          axi_wdata_full_reg,

                                          wr_b2b_elgible,

                                          wr_data_sm_cs )

        begin

        -- assign default values for state machine outputs
        wr_data_sm_ns <= wr_data_sm_cs;
        aw_active_clr <= '0';
        delay_aw_active_clr_cmb <= delay_aw_active_clr;
        bvalid_cnt_inc <= '0';
        
        axi_wr_burst_cmb <= axi_wr_burst;    

        wrdata_reg_ld <= '0';
        bram_we_ld <= '0';

        bram_en_cmb <= '0';
        clr_bram_we_cmb <= '0';

        bram_addr_inc <= '0';      
        bram_addr_rst_cmb <= '0';
        axi_wdata_full_cmb <= axi_wdata_full_reg;
        

        case wr_data_sm_cs is


                ---------------------------- IDLE State ---------------------------

                when IDLE =>

                    -- Check valid write data on AXI write data channel
                    if (AXI_WVALID = '1') then

                        wrdata_reg_ld <= '1';       -- Load write data register
                        bram_we_ld <= '1';          -- Load WE register

                        -- Add condition to check for simultaneous assertion
                        -- of AWVALID and AWREADY                    
                        if ((aw_active = '1') or (AXI_AWVALID = '1' and axi_awready_int = '1')) and 
                           
                           -- Ensure the BVALID counter does not roll over (max = 8 ID values)
                           (bvalid_cnt_max = '0') then

                            -- Initiate BRAM write transfer
                            bram_en_cmb <= '1';

                            -- Check for singles, by checking WLAST assertion w/ WVALID
                            if (AXI_WLAST = '1') then

                                -- Single data write
                                wr_data_sm_ns <= SNG_WR_DATA;

                                -- Set flag to assert BVALID and increment counter
                                bvalid_cnt_inc <= '1';

                                -- Set flag to delay clear of AW active flag
                                delay_aw_active_clr_cmb <= '1'; 

                                -- BRAM WE only asserted for single clock cycle
                                clr_bram_we_cmb <= '1';

                                axi_wr_burst_cmb <= '0';

                            else
                                -- Burst data write
                                wr_data_sm_ns <= BRST_WR_DATA;
                                axi_wr_burst_cmb <= '1';

                            end if; -- WLAST

                        else

                            -- AWADDR not yet received
                            -- Go to wait for write address
                            wr_data_sm_ns <= W8_AWADDR;

                            -- Set flag that AXI write data pipe is full
                            -- and can not accept any more data beats
                            -- WREADY on AXI will negate in this condition.
                            axi_wdata_full_cmb <= '1';

                            -- Set flag for single/burst write operation
                            -- when AWADDR is not yet received
                            if (AXI_WLAST = '1') then
                                axi_wr_burst_cmb <= '0';
                            else
                                axi_wr_burst_cmb <= '1';

                            end if; -- WLAST

                        end if; -- aw_active

                    end if; -- WVALID


                ------------------------- W8_AWADDR State -------------------------

                when W8_AWADDR =>


                    -- As we transition into this state, the write data pipeline
                    -- is already filled.  axi_wdata_full_reg should be = '1'.


                    -- Disable any additional loads into write data register
                    -- Default value in SM is applied.
                    

                    -- Wait for write address to be acknowledged
                    if (((aw_active = '1') or (AXI_AWVALID = '1' and axi_awready_int = '1')) or

                        -- Detect load of BRAM address counter from value stored in pipeline.
                        -- No need to wait until aw_active is asserted or address is captured from AXI bus.
                        -- As BRAM address is loaded from pipe and ready to be presented to BRAM. 
                        -- Assert BRAM WE.

                        (bram_addr_ld_en = '1' and axi_awaddr_full = '1' and awaddr_pipe_sel = '1')) and
                        
                        
                        -- Ensure the BVALID counter does not roll over (max = 8 ID values)
                        (bvalid_cnt_max = '0') then


                        -- Initiate BRAM write transfer
                        bram_en_cmb <= '1';

                        -- Negate write data full condition
                        axi_wdata_full_cmb <= '0';
                        

                        -- Check if single or burst operation
                        if (axi_wr_burst = '1') then
                            wr_data_sm_ns <= BRST_WR_DATA;
                        else

                            wr_data_sm_ns <= SNG_WR_DATA;

                            -- BRAM WE only asserted for single clock cycle
                            clr_bram_we_cmb <= '1';

                            -- Set flag to assert BVALID and increment counter
                            bvalid_cnt_inc <= '1';

                            delay_aw_active_clr_cmb <= '1'; 


                        end if;

                    else

                        -- Set flag that AXI write data pipe is full
                        -- and can not accept any more data beats
                        -- WREADY on AXI will negate in this condition.
                        axi_wdata_full_cmb <= '1';

                    end if;


                ------------------------- SNG_WR_DATA State -------------------------

                when SNG_WR_DATA =>


                    
                    -- No need to check for BVALID assertion here.

                    -- Move here under if clause on write response channel
                    -- acknowledging completion of write data.
                    -- If aw_active was not cleared prior to this state, then
                    -- clear the flag now.

                    if (delay_aw_active_clr = '1') then
                        delay_aw_active_clr_cmb <= '0';
                        aw_active_clr <= '1';
                    end if;



                    -- Add check here if while writing single data beat to BRAM,
                    -- a new AXI data beat is received (prior to the AWVALID assertion).
                    -- Ensure here that full flag is asserted for data pipeline state.

                    -- Check valid write data on AXI write data channel
                    if (AXI_WVALID = '1') then

                        -- Load write data register
                        wrdata_reg_ld <= '1';

                        -- Must also load WE register
                        bram_we_ld <= '1';


                        -- Set flag that AXI write data pipe is full
                        -- and can not accept any more data beats
                        -- WREADY on AXI will negate in this condition.

                        -- Ensure that axi_wdata_full_reg is asserted
                        -- to prevent early captures on next data burst (or single data
                        -- transfer)
                        -- This ensures that the data beats do not get skipped.
                        axi_wdata_full_cmb <= '1';


                        -- AWADDR not yet received
                        -- Go to wait for write address
                        wr_data_sm_ns <= W8_AWADDR;

                        -- Accept no more new write data after this first data beat
                        -- Pipeline is already full in this state. No need to assert
                        -- no_wdata_accept flag to '1'.

                        -- Set flag for single/burst write operation
                        -- when AWADDR is not yet received
                        if (AXI_WLAST = '1') then
                            axi_wr_burst_cmb <= '0';
                        else
                            axi_wr_burst_cmb <= '1';
                        end if; -- WLAST


                    else

                        -- No subsequent pending operation
                        -- Return to IDLE
                        wr_data_sm_ns <= IDLE;

                        bram_addr_rst_cmb <= '1';

                    end if;






                ------------------------- BRST_WR_DATA State -------------------------

                when BRST_WR_DATA =>


                    -- Reach this state at the 2nd data beat of a burst
                    -- AWADDR is already accepted
                    -- Continue to accept data from AXI write channel
                    -- and wait for assertion of WLAST

                    -- Check that WVALID remains asserted for burst
                    -- If negated, indicates throttling from AXI master
                    if (AXI_WVALID = '1') then

                        -- If WVALID is asserted for the 2nd and remaining 
                        -- data beats of the transfer
                        -- Continue w/ BRAM write enable assertion & advance
                        -- write data register
                        
                        wrdata_reg_ld <= '1';           -- Load write data register
                        bram_we_ld <= '1';              -- Load WE register
                        bram_en_cmb <= '1';             -- Initiate BRAM write transfer
                        bram_addr_inc <= '1';           -- Increment BRAM address counter


                        -- Check for last data beat in burst transfer
                        if (AXI_WLAST = '1') then

                            -- Set flag to assert BVALID and increment counter
                            bvalid_cnt_inc <= '1';
                                
                            -- The elgible signal will not be asserted for a subsequent
                            -- single data beat operation. Next operation is a burst.
                            -- And the AWADDR is loaded in the address pipeline.

                            -- Only if BVALID counter can handle next transfer,
                            -- proceed with back-to-back.  Otherwise, go to IDLE
                            -- (after last data write).
                            
                            if (wr_b2b_elgible = '1' and bvalid_cnt_amax = '0') then


                                -- Go to next operation and handle as a 
                                -- back-to-back burst.  No empty clock cycles.

                                -- Go to handle new burst for back to back condition
                                wr_data_sm_ns <= B2B_W8_WR_DATA;

                                axi_wr_burst_cmb <= '1';
                                

                            -- No pending subsequent transfer (burst > 2 data beats) 
                            -- to process                        
                            else

                                -- Last/single data write
                                wr_data_sm_ns <= SNG_WR_DATA;
                                
                                -- Be sure to clear aw_active flag at end of write burst
                                -- But delay when the flag is cleared
                                delay_aw_active_clr_cmb <= '1'; 
                                
                            end if;


                        end if; -- WLAST


                    -- Throttling
                    -- Suspend BRAM write & halt write data & WE register load
                    else
                        
                        wrdata_reg_ld <= '0';               -- Negate write data register load
                        bram_we_ld <= '0';                  -- Negate WE register load
                        bram_en_cmb <= '0';                 -- Negate write to BRAM
                        bram_addr_inc <= '0';               -- Do not increment BRAM address counter



                    end if;     -- WVALID



                ------------------------- B2B_W8_WR_DATA --------------------------

                when B2B_W8_WR_DATA =>


                    -- Reach this state upon a back-to-back condition
                    -- when BVALID/BREADY handshake is received,
                    -- but WVALID is not yet asserted for subsequent transfer.


                    -- Check valid write data on AXI write data channel
                    if (AXI_WVALID = '1') then

                        -- Load write data register
                        wrdata_reg_ld <= '1';

                        -- Load WE register
                        bram_we_ld <= '1';

                        -- Initiate BRAM write transfer
                        bram_en_cmb <= '1';

                        -- Burst data write
                        wr_data_sm_ns <= BRST_WR_DATA;
                        axi_wr_burst_cmb <= '1';
            
                        -- Make modification to last_data_ack_mod signal
                        -- so that it is asserted when this state is reached
                        -- and the BRAM address counter gets loaded.


                    -- WVALID not yet asserted
                    else 

                        wrdata_reg_ld <= '0';           -- Negate write data register load
                        bram_we_ld <= '0';              -- Negate WE register load
                        bram_en_cmb <= '0';             -- Negate write to BRAM
                        bram_addr_inc <= '0';           -- Do not increment BRAM address counter

                    end if;


        --coverage off

                ------------------------------ Default ----------------------------

                when others =>
                    wr_data_sm_ns <= IDLE;

        --coverage on

            end case;

        end process WR_DATA_SM_CMB_PROCESS;


        ---------------------------------------------------------------------------


        WR_DATA_SM_REG_PROCESS: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    wr_data_sm_cs <= IDLE;
                    bram_en_int <= '0';
                    clr_bram_we <= '0';
                    delay_aw_active_clr <= '0';
                    axi_wdata_full_reg <= '0';

                else
                    wr_data_sm_cs <= wr_data_sm_ns;
                    bram_en_int <= bram_en_cmb;
                    clr_bram_we <= clr_bram_we_cmb;
                    delay_aw_active_clr <= delay_aw_active_clr_cmb;
                    axi_wdata_full_reg <= axi_wdata_full_cmb;

                end if;
            end if;

        end process WR_DATA_SM_REG_PROCESS;


        ---------------------------------------------------------------------------




    end generate GEN_WDATA_SM_NO_ECC_DUAL_REG_WREADY;





    ---------------------------------------------------------------------------

    WR_BURST_REG_PROCESS: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                axi_wr_burst <= '0';
            else
                axi_wr_burst <= axi_wr_burst_cmb;
            end if;
        end if;

    end process WR_BURST_REG_PROCESS;

    
    ---------------------------------------------------------------------------







    ---------------------------------------------------------------------------
    -- *** AXI Write Response Channel Interface ***
    ---------------------------------------------------------------------------


    -- v1.03a


    ---------------------------------------------------------------------------
    --
    -- 
    -- New FIFO storage for BID, so AWID can be stored in 
    -- a FIFO and B response is seperated from W response.
    --
    -- Use registered WREADY & BID FIFO in single port configuration.
    --
    ---------------------------------------------------------------------------
    
    
    -- Instantiate FIFO to store BID values to be asserted back on B channel.
    -- Only 8 entries deep, BVALID counter only allows W channel to be 8 ahead of
    -- B channel.
    -- 
    -- If AWID is a single bit wide, sythesis optimizes the module, srl_fifo, 
    -- to a single SRL16E library module.
    
    BID_FIFO: entity work.srl_fifo
    generic map (
        C_DATA_BITS  => C_AXI_ID_WIDTH,
        C_DEPTH      => 8
    )
    port map (
        Clk          => S_AXI_AClk,
        Reset        => bid_fifo_rst,
        FIFO_Write   => bid_fifo_ld_en,
        Data_In      => bid_fifo_ld,
        FIFO_Read    => bid_fifo_rd_en,
        Data_Out     => bid_fifo_rd,
        FIFO_Full    => open,
        Data_Exists  => bid_fifo_not_empty,
        Addr         => open
    );
    
    
    bid_fifo_rst <= not (S_AXI_AResetn);
    
    bid_fifo_ld_en <= bram_addr_ld_en; 
    bid_fifo_ld <= AXI_AWID when (awaddr_pipe_sel = '0') else axi_awid_pipe;
    
    -- Read from FIFO when BVALID is to be asserted on bus, or in a back-to-back assertion 
    -- when a BID value is available in the FIFO.
    bid_fifo_rd_en <= bid_fifo_not_empty and                    -- Only read if data is available.
    
                      ((bid_gets_fifo_load_d1) or               -- a) Do the FIFO read in the clock cycle
                                                                --    following the BID value directly
                                                                --    aserted on the B channel (from AWID or pipeline).
                                                                
                       (first_fifo_bid) or                      -- b) Read from FIFO when BID is previously stored
                                                                --    but BVALID is not yet asserted on AXI.
                                                                
                       (bvalid_cnt_dec));                       -- c) Or read when next BID value is to be updated 
                                                                --    on B channel (and exists waiting in FIFO).
    
    
    -- 1)   Special case (1st load in FIFO) (and single clock cycle turnaround needed on BID, from AWID).
    --      If loading the FIFO and BVALID is to be asserted in the next clock cycle
    --      Then capture this condition to read from FIFO in the subsequent clock cycle 
    --      (and clear the BID value stored in the FIFO).
    bid_gets_fifo_load <= '1' when (bid_fifo_ld_en = '1') and 
                                   (first_fifo_bid = '1' or b2b_fifo_bid = '1') else '0';
    
    first_fifo_bid <= '1' when ((bvalid_cnt_inc = '1') and (bvalid_cnt_non_zero = '0')) else '0';  
                                                                    
    
    -- 2)   An additional special case.
    --      When write data register is loaded for single (bvalid_cnt = "001", due to WLAST/WVALID)
    --      But, AWID not yet received (FIFO is still empty).
    --      If BID FIFO is still empty with the BVALID counter decrement, but simultaneously 
    --      is increment (same condition as first_fifo_bid).
    b2b_fifo_bid <= '1' when (bvalid_cnt_inc = '1' and bvalid_cnt_dec = '1' and 
                          bvalid_cnt = "001" and bid_fifo_not_empty = '0') else '0';


    -- Output BID register to B AXI channel
    REG_BID: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                axi_bid_int <= (others => '0');
                
            -- If loading the FIFO and BVALID is to be asserted in the next clock cycle
            -- Then output the AWID or pipelined value (the same BID that gets loaded into FIFO).
            elsif (bid_gets_fifo_load = '1') then   
                axi_bid_int <= bid_fifo_ld;
                
            -- If new value read from FIFO then ensure that value is updated on AXI.    
            elsif (bid_fifo_rd_en = '1') then
                axi_bid_int <= bid_fifo_rd;
            else
                axi_bid_int <= axi_bid_int;            
            end if;

        end if;
    end process REG_BID;



    -- Capture condition of BID output updated while the FIFO is also
    -- getting updated.  Read FIFO in the subsequent clock cycle to
    -- clear the value stored in the FIFO.
    
    REG_BID_LD: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                bid_gets_fifo_load_d1 <= '0';
            else
                bid_gets_fifo_load_d1 <= bid_gets_fifo_load;            
            end if;

        end if;
    end process REG_BID_LD;



   
        
    ---------------------------------------------------------------------------
    -- AXI_BRESP Output Register
    ---------------------------------------------------------------------------
    

    ---------------------------------------------------------------------------
    -- Generate:    GEN_BRESP
    -- Purpose:     Generate BRESP output signal when ECC is disabled.
    --              Only allowable output is RESP_OKAY.
    ---------------------------------------------------------------------------
    GEN_BRESP: if C_ECC = 0 generate
    begin
    
        REG_BRESP: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    axi_bresp_int <= (others => '0');

                -- elsif (AXI_WLAST = '1') then
                -- CR # 609695
                elsif ((AXI_WLAST and AXI_WVALID and axi_wready_int_mod) = '1') then

                    -- AXI BRAM only supports OK response for normal operations
                    -- Exclusive operations not yet supported
                    axi_bresp_int <= RESP_OKAY;
                else
                    axi_bresp_int <= axi_bresp_int;

                end if;
            end if;

        end process REG_BRESP;

    end generate GEN_BRESP;



    ---------------------------------------------------------------------------
    -- Generate:    GEN_BRESP_ECC
    -- Purpose:     Generate BRESP output signal when ECC is enabled
    --              If no ECC error condition is detected during the RMW
    --              sequence, then output will be RESP_OKAY.  When an
    --              uncorrectable error is detected, the output will RESP_SLVERR.
    ---------------------------------------------------------------------------
    
    GEN_BRESP_ECC: if C_ECC = 1 generate    
    
    signal UE_Q_reg   : std_logic := '0';    
    
    begin
    
        REG_BRESP: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    axi_bresp_int <= (others => '0');

                elsif (bvalid_cnt_inc_d1 = '1') then

                --coverage off
                
                    -- Exclusive operations not yet supported
                    -- If no ECC errors occur, respond with OK
                    if (UE_Q = '1') or (UE_Q_reg = '1') then
                        axi_bresp_int <= RESP_SLVERR;
                        
                --coverage on
                
                    else
                        axi_bresp_int <= RESP_OKAY;
                    end if;
                else
                    axi_bresp_int <= axi_bresp_int;
                end if;
            end if;

        end process REG_BRESP;
        
        
        -- Check if any error conditions occured during the write operation.
        -- Capture condition for each write transfer.
        
        REG_UE: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                -- Clear at end of current write (and ensure the flag is cleared
                -- at the beginning of a write transfer)
                if (S_AXI_AResetn = C_RESET_ACTIVE) or (aw_active_re = '1') or 
                   (AXI_BREADY = '1' and axi_bvalid_int = '1') then
                    UE_Q_reg <= '0';
                
                --coverage off

                elsif (UE_Q = '1') then
                    UE_Q_reg <= '1';

                --coverage on

                else
                    UE_Q_reg <= UE_Q_reg;
                end if;
            end if;

        end process REG_UE;

    end generate GEN_BRESP_ECC;





    -- v1.03a

    ---------------------------------------------------------------------------
    -- Instantiate BVALID counter outside of specific SM generate block.
    ---------------------------------------------------------------------------


    ---------------------------------------------------------------------------

    -- BVALID counter to track the # of required BVALID/BREADY handshakes
    -- needed to occur on the AXI interface.  Based on early and seperate
    -- AWVALID/AWREADY and WVALID/WREADY handshake exchanges.

    REG_BVALID_CNT: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                bvalid_cnt <= (others => '0');

            -- Ensure we only increment counter wyhen BREADY is not asserted
            elsif (bvalid_cnt_inc = '1') and (bvalid_cnt_dec = '0') then
                bvalid_cnt <= std_logic_vector (unsigned (bvalid_cnt (2 downto 0)) + 1);
        
            -- Ensure that we only decrement when SM is not incrementing
            elsif (bvalid_cnt_dec = '1') and (bvalid_cnt_inc = '0') then
                bvalid_cnt <= std_logic_vector (unsigned (bvalid_cnt (2 downto 0)) - 1);

            else
                bvalid_cnt <= bvalid_cnt;
            end if;

        end if;

    end process REG_BVALID_CNT;
    
    
    bvalid_cnt_dec <= '1' when (AXI_BREADY = '1' and 
                                axi_bvalid_int = '1' and 
                                bvalid_cnt_non_zero = '1') else '0';

    bvalid_cnt_non_zero <= '1' when (bvalid_cnt /= "000") else '0';  
    bvalid_cnt_amax <= '1' when (bvalid_cnt = "110") else '0';
    bvalid_cnt_max <= '1' when (bvalid_cnt = "111") else '0';
    


    -- Replace BVALID output register
    -- Assert BVALID as long as BVALID counter /= zero

    REG_BVALID: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                -- Ensure that if we are also incrementing BVALID counter, the BVALID stays asserted.
               (bvalid_cnt = "001" and bvalid_cnt_dec = '1' and bvalid_cnt_inc = '0') then
                axi_bvalid_int <= '0';

            elsif (bvalid_cnt_non_zero = '1') or (bvalid_cnt_inc = '1') then
                axi_bvalid_int <= '1';
            else
                axi_bvalid_int <= '0';
            end if;

        end if;

    end process REG_BVALID;
    
    






    ---------------------------------------------------------------------------
    -- *** ECC Logic ***
    ---------------------------------------------------------------------------



    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_ECC
    -- Purpose:     Generate BRAM ECC write data and check ECC on read operations.
    --              Create signals to update ECC registers (lite_ecc_reg module interface).
    --
    ---------------------------------------------------------------------------

    GEN_ECC: if C_ECC = 1 generate
    
    constant null7      : std_logic_vector(0 to 6) := "0000000"; -- Specific to 32-bit data width (AXI-Lite)
    constant null8      : std_logic_vector(0 to 7) := "00000000";    -- Specific to 64-bit data width 
    
    -- constant C_USE_LUT6 : boolean := Family_To_LUT_Size (String_To_Family (C_FAMILY,false)) = 6;
    -- Remove usage of C_FAMILY.
    -- All architectures supporting AXI will support a LUT6. 
    -- Hard code this internal constant used in ECC algorithm.
    constant C_USE_LUT6 : boolean := TRUE;
    
    
    signal RdECC            : std_logic_vector(C_INT_ECC_WIDTH-1 downto 0) := (others => '0'); -- Temp 
    
    signal WrECC            : std_logic_vector(C_INT_ECC_WIDTH-1 downto 0) := (others => '0'); -- Specific to BRAM data width
    signal WrECC_i          : std_logic_vector(C_ECC_WIDTH-1 downto 0) := (others => '0');
    
    signal AXI_WSTRB_Q      : std_logic_vector((C_AXI_DATA_WIDTH/8 - 1) downto 0) := (others => '0');

    signal Syndrome         : std_logic_vector(0 to C_INT_ECC_WIDTH-1) := (others => '0'); -- Specific to BRAM data width
    signal Syndrome_4       : std_logic_vector (0 to 1) := (others => '0');         -- Specific to 32-bit ECC
    signal Syndrome_6       : std_logic_vector (0 to 5) := (others => '0');         -- Specific to 32-bit ECC
    signal Syndrome_7       : std_logic_vector (0 to 11) := (others => '0');        -- Specific to 64-bit ECC

    signal syndrome_reg_i       : std_logic_vector(0 to C_INT_ECC_WIDTH-1) := (others => '0');     -- Specific to BRAM data width
    signal syndrome_reg         : std_logic_vector(0 to C_INT_ECC_WIDTH-1) := (others => '0');     -- Specific to BRAM data width

    signal RdModifyWr_Read      : std_logic := '0';  -- Read cycle in read modify write sequence 
    signal RdModifyWr_Read_i    : std_logic := '0'; 
    signal RdModifyWr_Check     : std_logic := '0'; 
 
    signal bram_din_a_i         : std_logic_vector(0 to C_AXI_DATA_WIDTH+C_ECC_WIDTH-1) := (others => '0'); -- Set for port data width
    signal UnCorrectedRdData    : std_logic_vector(0 to C_AXI_DATA_WIDTH-1) := (others => '0');
 
    signal CE_Q             : std_logic := '0';
    signal Sl_CE_i          : std_logic := '0';
    signal Sl_UE_i          : std_logic := '0';
 
    subtype syndrome_bits is std_logic_vector(0 to C_INT_ECC_WIDTH-1);
    -- 0:6 for 32-bit ECC
    -- 0:7 for 64-bit ECC

    type correct_data_table_type is array (natural range 0 to C_AXI_DATA_WIDTH-1) of syndrome_bits;
 
    type bool_array is array (natural range 0 to 6) of boolean;
    constant inverted_bit : bool_array := (false,false,true,false,true,false,false);

        
    -- v1.03a
    
    constant CODE_WIDTH : integer := C_AXI_DATA_WIDTH + C_INT_ECC_WIDTH;
    constant ECC_WIDTH  : integer := C_INT_ECC_WIDTH;
    
    signal h_rows        : std_logic_vector (CODE_WIDTH * ECC_WIDTH - 1 downto 0);

  
    begin
     
        -- Generate signal to advance BRAM read address pipeline to
        -- capture address for ECC error conditions (in lite_ecc_reg module).
        BRAM_Addr_En <= RdModifyWr_Read;
         
         
        
        -- v1.03a

        RdModifyWr_Read <= '1' when (wr_data_ecc_sm_cs = RMW_RD_DATA) else '0';
        RdModifyWr_Modify <= '1' when (wr_data_ecc_sm_cs = RMW_MOD_DATA) else '0';
        RdModifyWr_Write <= '1' when (wr_data_ecc_sm_cs = RMW_WR_DATA) else '0';

        
        -----------------------------------------------------------------------


       -- Remember write data one cycle to be available after read has been completed in a
       -- read/modify write operation.
       -- Save WSTRBs here in this register
       
       REG_WSTRB : process (S_AXI_AClk) is
       begin
           if (S_AXI_AClk'event and S_AXI_AClk = '1') then
               if (S_AXI_AResetn = C_RESET_ACTIVE) then
                   AXI_WSTRB_Q <= (others => '0');

               elsif (wrdata_reg_ld = '1') then
                   AXI_WSTRB_Q <= AXI_WSTRB;    
               end if;
           end if;
       end process REG_WSTRB;



       -- v1.03a

       ------------------------------------------------------------------------
       -- Generate:     GEN_WRDATA_CMB
       -- Purpose:      Replace manual signal assignment for WrData_cmb with 
       --               generate funtion.
       --
       --               Ensure correct byte swapping occurs with 
       --               CorrectedRdData (0 to C_AXI_DATA_WIDTH-1) assignment
       --               to WrData_cmb (C_AXI_DATA_WIDTH-1 downto 0).
       --
       --               AXI_WSTRB_Q (C_AXI_DATA_WIDTH_BYTES-1 downto 0) matches
       --               to WrData_cmb (C_AXI_DATA_WIDTH-1 downto 0).
       --
       ------------------------------------------------------------------------

       GEN_WRDATA_CMB: for i in C_AXI_DATA_WIDTH_BYTES-1 downto 0 generate
       begin

           WrData_cmb ( (((i+1)*8)-1) downto i*8 ) <= bram_wrdata_int ((((i+1)*8)-1) downto i*8) when 
                                           (RdModifyWr_Modify = '1' and AXI_WSTRB_Q(i) = '1') 
                                        else CorrectedRdData ( (C_AXI_DATA_WIDTH - ((i+1)*8)) to 
                                                               (C_AXI_DATA_WIDTH - (i*8) - 1) );
       end generate GEN_WRDATA_CMB;


       REG_WRDATA : process (S_AXI_AClk) is
       begin
            -- Remove reset value to minimize resources & improve timing
            if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                WrData <= WrData_cmb;   
            end if;
       end process REG_WRDATA;
       


       ------------------------------------------------------------------------

        -- New assignment of ECC bits to BRAM write data outside generate
        -- blocks.  Same signal assignment regardless of ECC type.
        
        BRAM_WrData ((C_AXI_DATA_WIDTH + C_ECC_WIDTH - 1) downto C_AXI_DATA_WIDTH)
                    <= WrECC_i xor FaultInjectECC;  



       ------------------------------------------------------------------------


           
        -- v1.03a

        ------------------------------------------------------------------------
        -- Generate:     GEN_HSIAO_ECC
        -- Purpose:      Determine type of ECC encoding.  Hsiao or Hamming.  
        --               Add parameter/generate level.
        --               Derived from MIG v3.7 Hsiao HDL.
        ------------------------------------------------------------------------
        
        GEN_HSIAO_ECC: if C_ECC_TYPE = 1 generate

        constant ECC_WIDTH  : integer := C_INT_ECC_WIDTH;

        type type_int0 is array (C_AXI_DATA_WIDTH - 1 downto 0) of std_logic_vector (ECC_WIDTH - 1 downto 0);

        signal syndrome_ns  : std_logic_vector(ECC_WIDTH - 1 downto 0);
        signal syndrome_r   : std_logic_vector(ECC_WIDTH - 1 downto 0);

        signal ecc_rddata_r : std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0);
        signal h_matrix     : type_int0;

        signal flip_bits    : std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0);

        begin

            ---------------------- Hsiao ECC Write Logic ----------------------

            -- Instantiate ecc_gen_hsiao module, generated from MIG

            ECC_GEN_HSIAO: entity work.ecc_gen
               generic map (
                  code_width  => CODE_WIDTH,
                  ecc_width   => ECC_WIDTH,
                  data_width  => C_AXI_DATA_WIDTH
               )
               port map (
                  -- Output
                  h_rows  => h_rows (CODE_WIDTH * ECC_WIDTH - 1 downto 0)
               );
        

            -- Merge muxed rd/write data to gen               
            HSIAO_ECC: process (h_rows, WrData)
            constant DQ_WIDTH : integer := CODE_WIDTH;
            
            variable ecc_wrdata_tmp : std_logic_vector(DQ_WIDTH-1 downto C_AXI_DATA_WIDTH);
            
            begin
                                
                -- Loop to generate all ECC bits
                for k in 0 to  ECC_WIDTH - 1 loop                        
                    ecc_wrdata_tmp (CODE_WIDTH - k - 1) := REDUCTION_XOR ( (WrData (C_AXI_DATA_WIDTH - 1 downto 0) 
                                                                            and h_rows (k * CODE_WIDTH + C_AXI_DATA_WIDTH - 1 downto k * CODE_WIDTH)));
                end loop;

                WrECC (C_INT_ECC_WIDTH-1 downto 0) <= ecc_wrdata_tmp (DQ_WIDTH-1 downto C_AXI_DATA_WIDTH);
                 
            end process HSIAO_ECC;




            -----------------------------------------------------------------------
            -- Generate:     GEN_ECC_32
            -- Purpose:      For 32-bit ECC implementations, assign unused
            --               MSB of ECC output to BRAM with '0'.
            -----------------------------------------------------------------------
            GEN_ECC_32: if C_AXI_DATA_WIDTH = 32 generate
            begin
                -- Account for 32-bit and MSB '0' of ECC bits
                WrECC_i <= '0' & WrECC;
            end generate GEN_ECC_32;


            -----------------------------------------------------------------------
            -- Generate:     GEN_ECC_N
            -- Purpose:      For all non 32-bit ECC implementations, assign ECC
            --               bits for BRAM output.
            -----------------------------------------------------------------------
            GEN_ECC_N: if C_AXI_DATA_WIDTH /= 32 generate
            begin
                WrECC_i <= WrECC;
            end generate GEN_ECC_N;



            ---------------------- Hsiao ECC Read Logic -----------------------

            GEN_RD_ECC: for m in 0 to ECC_WIDTH - 1 generate
            begin
                syndrome_ns (m) <= REDUCTION_XOR ( BRAM_RdData (CODE_WIDTH-1 downto 0)
                                                   and h_rows ((m*CODE_WIDTH)+CODE_WIDTH-1 downto (m*CODE_WIDTH)));
            end generate GEN_RD_ECC;

            -- Insert register stage for syndrome 
            REG_SYNDROME: process (S_AXI_AClk)
            begin        
                if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then            
                    syndrome_r <= syndrome_ns;                    
                end if;
            end process REG_SYNDROME;

            ecc_rddata_r <= UnCorrectedRdData;

            -- Reconstruct H-matrix
            H_COL: for n in 0 to C_AXI_DATA_WIDTH - 1 generate
            begin
                H_BIT: for p in 0 to ECC_WIDTH - 1 generate
                begin
                    h_matrix (n)(p) <= h_rows (p * CODE_WIDTH + n);
                end generate H_BIT;
            end generate H_COL;


            GEN_FLIP_BIT: for r in 0 to C_AXI_DATA_WIDTH - 1 generate
            begin
               flip_bits (r) <= BOOLEAN_TO_STD_LOGIC (h_matrix (r) = syndrome_r);
            end generate GEN_FLIP_BIT;


            CorrectedRdData (0 to C_AXI_DATA_WIDTH-1) <= ecc_rddata_r (C_AXI_DATA_WIDTH-1 downto 0) xor
                                                             flip_bits (C_AXI_DATA_WIDTH-1 downto 0);

            Sl_CE_i <= not (REDUCTION_NOR (syndrome_r (ECC_WIDTH-1 downto 0))) and (REDUCTION_XOR (syndrome_r (ECC_WIDTH-1 downto 0)));
            Sl_UE_i <= not (REDUCTION_NOR (syndrome_r (ECC_WIDTH-1 downto 0))) and not (REDUCTION_XOR (syndrome_r (ECC_WIDTH-1 downto 0)));


        end generate GEN_HSIAO_ECC;
 
        
        
        
        



        ------------------------------------------------------------------------
        -- Generate:     GEN_HAMMING_ECC
        -- Purpose:      Determine type of ECC encoding.  Hsiao or Hamming.  
        --               Add parameter/generate level.
        ------------------------------------------------------------------------
        GEN_HAMMING_ECC: if C_ECC_TYPE = 0 generate
        begin
        
       
       
            -----------------------------------------------------------------
            -- Generate:  GEN_ECC_32
            -- Purpose:   Assign ECC out data vector (N:0) unique for 32-bit BRAM.
            --            Add extra '0' at MSB of ECC vector for data2mem alignment
            --            w/ 32-bit BRAM data widths.
            --            ECC bits are in upper order bits.
            -----------------------------------------------------------------

            GEN_ECC_32: if C_AXI_DATA_WIDTH = 32 generate

            constant correct_data_table_32 : correct_data_table_type := (
              0 => "1100001",  1 => "1010001",  2 => "0110001",  3 => "1110001",
              4 => "1001001",  5 => "0101001",  6 => "1101001",  7 => "0011001",
              8 => "1011001",  9 => "0111001",  10 => "1111001",  11 => "1000101",
              12 => "0100101",  13 => "1100101",  14 => "0010101",  15 => "1010101",
              16 => "0110101",  17 => "1110101",  18 => "0001101",  19 => "1001101",
              20 => "0101101",  21 => "1101101",  22 => "0011101",  23 => "1011101",
              24 => "0111101",  25 => "1111101",  26 => "1000011",  27 => "0100011",
              28 => "1100011",  29 => "0010011",  30 => "1010011",  31 => "0110011"
              );

            signal syndrome_4_reg       : std_logic_vector (0 to 1) := (others => '0');            -- Specific for 32-bit ECC
            signal syndrome_6_reg       : std_logic_vector (0 to 5)  := (others => '0');            -- Specific for 32-bit ECC

            begin


                --------------------- Hamming 32-bit ECC Write Logic ------------------



                -------------------------------------------------------------------------
                -- Instance:        CHK_HANDLER_WR_32
                -- Description:     Generate ECC bits for writing into BRAM.
                --                  WrData (N:0)
                -------------------------------------------------------------------------



                CHK_HANDLER_WR_32: entity work.checkbit_handler
                generic map (
                    C_ENCODE         => true,                -- [boolean]
                    C_USE_LUT6       => C_USE_LUT6)          -- [boolean]
                port map (
                    DataIn           => WrData,              -- [in  std_logic_vector(0 to 31)]
                    CheckIn          => null7,               -- [in  std_logic_vector(0 to 6)]
                    CheckOut         => WrECC,               -- [out std_logic_vector(0 to 6)]
                    Syndrome         => open,                -- [out std_logic_vector(0 to 6)]
                    Syndrome_4       => open,                -- [out std_logic_vector(0 to 1)]
                    Syndrome_6       => open,                -- [out std_logic_vector(0 to 5)]
                    Syndrome_Chk     => null7,               -- [in  std_logic_vector(0 to 6)]
                    Enable_ECC       => '1',                 -- [in  std_logic]
                    UE_Q             => '0',                 -- [in  std_logic]
                    CE_Q             => '0',                 -- [in  std_logic]
                    UE               => open,                -- [out std_logic]
                    CE               => open );              -- [out std_logic]
               

                -- v1.03a            
                -- Account for 32-bit and MSB '0' of ECC bits
                WrECC_i <= '0' & WrECC;




                --------------------- Hamming 32-bit ECC Read Logic -------------------



                --------------------------------------------------------------------------
                -- Instance:        CHK_HANDLER_RD_32
                -- Description:     Generate ECC bits for checking data read from BRAM.
                --                  All vectors oriented (0:N)
                --------------------------------------------------------------------------

                CHK_HANDLER_RD_32: entity work.checkbit_handler
                generic map (
                        C_ENCODE   => false,                 -- [boolean]
                        C_USE_LUT6 => C_USE_LUT6)            -- [boolean]
                port map (

                        -- DataIn (8:39)
                        -- CheckIn (1:7)
                        DataIn          =>  bram_din_a_i(C_INT_ECC_WIDTH+1 to C_INT_ECC_WIDTH+C_AXI_DATA_WIDTH),    -- [in  std_logic_vector(0 to 31)]
                        CheckIn         =>  bram_din_a_i(1 to C_INT_ECC_WIDTH),                                     -- [in  std_logic_vector(0 to 6)]

                        CheckOut        =>  open,                                                                   -- [out std_logic_vector(0 to 6)]
                        Syndrome        =>  Syndrome,                                                               -- [out std_logic_vector(0 to 6)]
                        Syndrome_4      =>  Syndrome_4,                                                             -- [out std_logic_vector(0 to 1)]
                        Syndrome_6      =>  Syndrome_6,                                                             -- [out std_logic_vector(0 to 5)]
                        Syndrome_Chk    =>  syndrome_reg_i,                                                         -- [in  std_logic_vector(0 to 6)]
                        Enable_ECC      =>  Enable_ECC,                                                             -- [in  std_logic]
                        UE_Q            =>  UE_Q,                                                                   -- [in  std_logic]
                        CE_Q            =>  CE_Q,                                                                   -- [in  std_logic]
                        UE              =>  Sl_UE_i,                                                                -- [out std_logic]
                        CE              =>  Sl_CE_i );                                                              -- [out std_logic]


                ---------------------------------------------------------------------------

                -- Insert register stage for syndrome 
                REG_SYNDROME: process (S_AXI_AClk)
                begin        
                    if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then            
                        syndrome_reg <= Syndrome;                    
                        syndrome_4_reg <= Syndrome_4;
                        syndrome_6_reg <= Syndrome_6;                  
                    end if;

                end process REG_SYNDROME;


               ---------------------------------------------------------------------------

                -- Do last XOR on select syndrome bits outside of checkbit_handler (to match rd_chnl 
                -- w/ balanced pipeline stage) before correct_one_bit module.
                syndrome_reg_i (0 to 3) <= syndrome_reg (0 to 3);

                PARITY_CHK4: entity work.parity
                generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 2)
                port map (
                  InA   =>  syndrome_4_reg (0 to 1),                        -- [in  std_logic_vector(0 to C_SIZE - 1)]
                  Res   =>  syndrome_reg_i (4) );                           -- [out std_logic]

                syndrome_reg_i (5) <= syndrome_reg (5);

                PARITY_CHK6: entity work.parity
                generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
                port map (
                  InA   =>  syndrome_6_reg (0 to 5),                        -- [in  std_logic_vector(0 to C_SIZE - 1)]
                  Res   =>  syndrome_reg_i (6) );                           -- [out std_logic]



               ---------------------------------------------------------------------------
               -- Generate: GEN_CORR_32
               -- Purpose:  Generate corrected read data based on syndrome value.
               --           All vectors oriented (0:N)
               ---------------------------------------------------------------------------
               GEN_CORR_32: for i in 0 to C_AXI_DATA_WIDTH-1 generate
               begin

                    ---------------------------------------------------------------------------
                    -- Instance:        CORR_ONE_BIT_32
                    -- Description:     Generate ECC bits for checking data read from BRAM.
                    ---------------------------------------------------------------------------
                    CORR_ONE_BIT_32: entity work.correct_one_bit
                    generic map (
                        C_USE_LUT6    => C_USE_LUT6,
                        Correct_Value => correct_data_table_32 (i))
                    port map (
                        DIn           => UnCorrectedRdData (i),
                        Syndrome      => syndrome_reg_i,
                        DCorr         => CorrectedRdData (i));

                end generate GEN_CORR_32;
        
        


            end generate GEN_ECC_32;
        
        
        

            -----------------------------------------------------------------
            -- Generate:  GEN_ECC_64
            -- Purpose:   Assign ECC out data vector (N:0) unique for 64-bit BRAM.
            --            No extra '0' at MSB of ECC vector for data2mem alignment
            --            w/ 64-bit BRAM data widths.
            --            ECC bits are in upper order bits.
            -----------------------------------------------------------------
        
            GEN_ECC_64: if C_AXI_DATA_WIDTH = 64 generate

             constant correct_data_table_64 : correct_data_table_type := (
               0 => "11000001",  1 => "10100001",  2 => "01100001",  3 => "11100001",
               4 => "10010001",  5 => "01010001",  6 => "11010001",  7 => "00110001",
               8 => "10110001",  9 => "01110001",  10 => "11110001",  11 => "10001001",
               12 => "01001001",  13 => "11001001",  14 => "00101001",  15 => "10101001",
               16 => "01101001",  17 => "11101001",  18 => "00011001",  19 => "10011001",
               20 => "01011001",  21 => "11011001",  22 => "00111001",  23 => "10111001",
               24 => "01111001",  25 => "11111001",  26 => "10000101",  27 => "01000101",
               28 => "11000101",  29 => "00100101",  30 => "10100101",  31 => "01100101",
               32 => "11100101",  33 => "00010101",  34 => "10010101",  35 => "01010101",
               36 => "11010101",  37 => "00110101",  38 => "10110101",  39 => "01110101",
               40 => "11110101",  41 => "00001101",  42 => "10001101",  43 => "01001101",
               44 => "11001101",  45 => "00101101",  46 => "10101101",  47 => "01101101",      
               48 => "11101101",  49 => "00011101",  50 => "10011101",  51 => "01011101",
               52 => "11011101",  53 => "00111101",  54 => "10111101",  55 => "01111101",
               56 => "11111101",  57 => "10000011",  58 => "01000011",  59 => "11000011",
               60 => "00100011",  61 => "10100011",  62 => "01100011",  63 => "11100011"
               );

            signal syndrome_7_reg       : std_logic_vector (0 to 11) := (others => '0');
            signal syndrome7_a          : std_logic := '0';
            signal syndrome7_b          : std_logic := '0';

            begin


                --------------------- Hamming 64-bit ECC Write Logic ------------------

          

                ---------------------------------------------------------------------------
                -- Instance:        CHK_HANDLER_WR_64
                -- Description:     Generate ECC bits for writing into BRAM when configured
                --                  as 64-bit wide BRAM.
                --                  WrData (N:0)
                --                   Enable C_REG on encode path.
                ---------------------------------------------------------------------------

                CHK_HANDLER_WR_64: entity work.checkbit_handler_64
                generic map (
                       C_ENCODE         =>  true,           -- [boolean]
                       C_REG            =>  true,           -- [boolean]
                       C_USE_LUT6       =>  C_USE_LUT6)     -- [boolean]
                port map (
                       Clk              =>  S_AXI_AClk,     -- [in std_logic]
                       DataIn           =>  WrData_cmb,     -- [in  std_logic_vector(0 to 63)]
                       CheckIn          =>  null8,          -- [in  std_logic_vector(0 to 7)]
                       CheckOut         =>  WrECC,          -- [out std_logic_vector(0 to 7)]
                       Syndrome         =>  open,           -- [out std_logic_vector(0 to 7)]
                       Syndrome_7       =>  open,           -- [out std_logic_vector(0 to 11)]
                       Syndrome_Chk     =>  null8,          -- [in  std_logic_vector(0 to 7)]
                       Enable_ECC       =>  '1',            -- [in  std_logic]
                       UE_Q             =>  '0',            -- [in  std_logic]
                       CE_Q             =>  '0',            -- [in  std_logic]
                       UE               =>  open,           -- [out std_logic]
                       CE               =>  open );         -- [out std_logic]


                -- Note: (7:0) Old bit lane assignment
                -- BRAM_WrData ((C_ECC_WIDTH - 1) downto 0) 

                -- v1.02a
                -- WrECC is assigned to BRAM_WrData (71:64)
                
                -- v1.03a
                -- BRAM_WrData (71:64) assignment done outside of this
                -- ECC type generate block.

                WrECC_i <= WrECC;
                

            
                --------------------- Hamming 64-bit ECC Read Logic -------------------
            


                ---------------------------------------------------------------------------
                -- Instance:        CHK_HANDLER_RD_64
                -- Description:     Generate ECC bits for checking data read from BRAM.
                --                  All vectors oriented (0:N)
                ---------------------------------------------------------------------------

                CHK_HANDLER_RD_64: entity work.checkbit_handler_64
                     generic map (
                       C_ENCODE         =>  false,                 -- [boolean]
                       C_REG            =>  false,                 -- [boolean]
                       C_USE_LUT6       =>  C_USE_LUT6)            -- [boolean]
                     port map (
                       Clk              =>  S_AXI_AClk,                                                                  -- [in  std_logic]
                       -- DataIn (8:71)
                       -- CheckIn (0:7)
                       DataIn           =>  bram_din_a_i (C_INT_ECC_WIDTH to C_INT_ECC_WIDTH+C_AXI_DATA_WIDTH-1),        -- [in  std_logic_vector(0 to 63)]
                       CheckIn          =>  bram_din_a_i (0 to C_INT_ECC_WIDTH-1),                                       -- [in  std_logic_vector(0 to 7)]

                       CheckOut         =>  open,                                                                        -- [out std_logic_vector(0 to 7)]
                       Syndrome         =>  Syndrome,                                                                    -- [out std_logic_vector(0 to 7)]
                       Syndrome_7       =>  Syndrome_7,                                                                  -- [out std_logic_vector(0 to 11)]
                       Syndrome_Chk     =>  syndrome_reg_i,                                                              -- [in  std_logic_vector(0 to 7)]
                       Enable_ECC       =>  Enable_ECC,                                                                  -- [in  std_logic]
                       UE_Q             =>  UE_Q,                                                                        -- [in  std_logic]
                       CE_Q             =>  CE_Q,                                                                        -- [in  std_logic]
                       UE               =>  Sl_UE_i,                                                                     -- [out std_logic]
                       CE               =>  Sl_CE_i );                                                                   -- [out std_logic]



                ---------------------------------------------------------------------------

                -- Insert register stage for syndrome 
                REG_SYNDROME: process (S_AXI_AClk)
                begin        
                    if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then            
                        syndrome_reg <= Syndrome;                    
                        syndrome_7_reg <= Syndrome_7;                  
                    end if;

                end process REG_SYNDROME;


                ---------------------------------------------------------------------------

                -- Move final XOR to registered side of syndrome bits.
                -- Do last XOR on select syndrome bits after pipeline stage 
                -- before correct_one_bit_64 module.

                syndrome_reg_i (0 to 6) <= syndrome_reg (0 to 6);

                PARITY_CHK7_A: entity work.parity
                generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
                port map (
                  InA     =>  syndrome_7_reg (0 to 5),                      -- [in  std_logic_vector(0 to C_SIZE - 1)]
                  Res     =>  syndrome7_a );                                -- [out std_logic]

                PARITY_CHK7_B: entity work.parity
                generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
                port map (
                  InA     =>  syndrome_7_reg (6 to 11),                     -- [in  std_logic_vector(0 to C_SIZE - 1)]
                  Res     =>  syndrome7_b );                                -- [out std_logic]


                syndrome_reg_i (7) <= syndrome7_a xor syndrome7_b;    



               ---------------------------------------------------------------------------
               -- Generate: GEN_CORRECT_DATA
               -- Purpose:  Generate corrected read data based on syndrome value.
               --           All vectors oriented (0:N)
               ---------------------------------------------------------------------------
               GEN_CORR_64: for i in 0 to C_AXI_DATA_WIDTH-1 generate
               begin

                   ---------------------------------------------------------------------------
                   -- Instance:        CORR_ONE_BIT_64
                   -- Description:     Generate ECC bits for checking data read from BRAM.
                   ---------------------------------------------------------------------------
                   CORR_ONE_BIT_64: entity work.correct_one_bit_64
                   generic map (
                       C_USE_LUT6    => C_USE_LUT6,
                       Correct_Value => correct_data_table_64 (i))
                   port map (
                       DIn           => UnCorrectedRdData (i),
                       Syndrome      => syndrome_reg_i,
                       DCorr         => CorrectedRdData (i));

               end generate GEN_CORR_64;


            end generate GEN_ECC_64;


        end generate GEN_HAMMING_ECC;


        -- Remember correctable/uncorrectable error from BRAM read
        CORR_REG: process(S_AXI_AClk) is
        begin
            if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                if RdModifyWr_Modify = '1' then     -- Capture error signals 
                    CE_Q <= Sl_CE_i;
                    UE_Q <= Sl_UE_i;

                else              
                    CE_Q <= '0';
                    UE_Q <= '0';
                end if;          
            end if;
        end process CORR_REG;

       
        -- ECC register block gets registered UE or CE conditions to update
        -- ECC registers/interrupt/flag outputs.
        Sl_CE <= CE_Q;
        Sl_UE <= UE_Q;

        CE_Failing_We <= CE_Q;

        FaultInjectClr <= '1' when (bvalid_cnt_inc_d1 = '1') else '0';


        -----------------------------------------------------------------------

        -- Add register delay on BVALID counter increment
        -- Used to clear fault inject register.
        
        REG_BVALID_CNT: process (S_AXI_AClk)
        begin
        
            if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    bvalid_cnt_inc_d1 <= '0';
                else
                    bvalid_cnt_inc_d1 <= bvalid_cnt_inc;
                end if;
            end if;
        
        end process REG_BVALID_CNT;


                           
        -----------------------------------------------------------------------

        -- Map BRAM_RdData (N:0) to bram_din_a_i (0:N)
        -- Including read back ECC bits.
        bram_din_a_i (0 to C_AXI_DATA_WIDTH+C_ECC_WIDTH-1) <= 
                    BRAM_RdData (C_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0);
    

        -----------------------------------------------------------------------



        -----------------------------------------------------------------------
        -- Generate:     GEN_ECC_32
        -- Purpose:      For 32-bit ECC implementations, account for 
        --               extra bit in read data mapping on registered value.
        -----------------------------------------------------------------------
        GEN_ECC_32: if C_AXI_DATA_WIDTH = 32 generate
        begin

            -- Insert register stage for read data to correct
            REG_CHK_DATA: process (S_AXI_AClk)
            begin        
                if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then            
                    UnCorrectedRdData <= bram_din_a_i(C_INT_ECC_WIDTH+1 to C_INT_ECC_WIDTH+C_AXI_DATA_WIDTH);
                end if;
            end process REG_CHK_DATA;

        end generate GEN_ECC_32;


        -----------------------------------------------------------------------
        -- Generate:     GEN_ECC_N
        -- Purpose:      For all non 32-bit ECC implementations, assign ECC
        --               bits for BRAM output.
        -----------------------------------------------------------------------
        GEN_ECC_N: if C_AXI_DATA_WIDTH /= 32 generate
        begin

            -- Insert register stage for read data to correct
            REG_CHK_DATA: process (S_AXI_AClk)
            begin        
                if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then            
                    UnCorrectedRdData <= bram_din_a_i(C_INT_ECC_WIDTH to C_INT_ECC_WIDTH+C_AXI_DATA_WIDTH-1);
                end if;
            end process REG_CHK_DATA;

        end generate GEN_ECC_N;


                        
    end generate GEN_ECC;


    ---------------------------------------------------------------------------



    ---------------------------------------------------------------------------
    -- Generate:    GEN_NO_ECC
    -- Purpose:     Drive default output signals when ECC is diabled.
    ---------------------------------------------------------------------------

    GEN_NO_ECC: if C_ECC = 0 generate
    begin
    
        BRAM_Addr_En <= '0';
        FaultInjectClr <= '0'; 
        CE_Failing_We <= '0'; 
        Sl_CE <= '0';
        Sl_UE <= '0'; 

    end generate GEN_NO_ECC;







    ---------------------------------------------------------------------------
    -- *** BRAM Interface Signals ***
    ---------------------------------------------------------------------------


    ---------------------------------------------------------------------------
    -- Generate:    GEN_BRAM_WE
    -- Purpose:     BRAM WE generate process
    --              One WE per 8-bits of BRAM data.
    ---------------------------------------------------------------------------
    
    GEN_BRAM_WE: for i in C_AXI_DATA_WIDTH/8 + (C_ECC*(1+(C_AXI_DATA_WIDTH/128))) - 1 downto 0 generate
    begin
        BRAM_WE (i) <= bram_we_int (i);
    end generate GEN_BRAM_WE;
            

    ---------------------------------------------------------------------------

    BRAM_En <= bram_en_int;   




    ---------------------------------------------------------------------------
    -- BRAM Address Generate
    ---------------------------------------------------------------------------


    ---------------------------------------------------------------------------
    -- Generate:    GEN_L_BRAM_ADDR
    -- Purpose:     Generate zeros on lower order address bits adjustable
    --              based on BRAM data width.
    ---------------------------------------------------------------------------

    GEN_L_BRAM_ADDR: for i in C_BRAM_ADDR_ADJUST_FACTOR-1 downto 0 generate
    begin    
        BRAM_Addr (i) <= '0';        
    end generate GEN_L_BRAM_ADDR;
 
  
    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_BRAM_ADDR
    -- Purpose:     Assign BRAM address output from address counter.
    --
    ---------------------------------------------------------------------------
 
    GEN_BRAM_ADDR: for i in C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR generate
    begin    
 
        BRAM_Addr (i) <= bram_addr_int (i);        
    end generate GEN_BRAM_ADDR;
    

    ---------------------------------------------------------------------------
    -- Generate:    GEN_BRAM_WRDATA
    -- Purpose:     Generate BRAM Write Data.
    ---------------------------------------------------------------------------

    GEN_BRAM_WRDATA: for i in C_AXI_DATA_WIDTH-1 downto 0 generate
    begin        
            
            
        -- Check if ECC is enabled
        -- If so, XOR the fault injection vector with the data
        -- (post-pipeline) to avoid any timing issues on the data vector
        -- from AXI.
        
        
        -----------------------------------------------------------------------
        -- Generate:    GEN_NO_ECC
        -- Purpose:     Generate output write data when ECC is disabled.
        -----------------------------------------------------------------------
        GEN_NO_ECC : if C_ECC = 0 generate
        begin
            BRAM_WrData (i) <= bram_wrdata_int (i);  
        end generate GEN_NO_ECC;
        
        -----------------------------------------------------------------------
        -- Generate:    GEN_NO_ECC
        -- Purpose:     Generate output write data when ECC is enable 
        --              (use fault vector)
        --              (N:0)
        --              for 32-bit (31:0) WrData while (ECC = [39:32])
        -----------------------------------------------------------------------
        GEN_W_ECC : if C_ECC = 1 generate
        begin
            BRAM_WrData (i) <= WrData (i) xor FaultInjectData (i);
        end generate GEN_W_ECC;

                
        
    end generate GEN_BRAM_WRDATA;


    ---------------------------------------------------------------------------





end architecture implementation;











