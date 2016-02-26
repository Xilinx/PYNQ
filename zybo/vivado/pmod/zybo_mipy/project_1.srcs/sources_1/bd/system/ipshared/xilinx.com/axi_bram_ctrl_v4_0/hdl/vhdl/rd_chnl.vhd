-------------------------------------------------------------------------------
-- rd_chnl.vhd
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
-- Filename:        rd_chnl.vhd
--
-- Description:     This file is the top level module for the AXI BRAM
--                  controller read channel interfaces.  Controls all
--                  handshaking and data flow on the AXI read address (AR)
--                  and read data (R) channels.
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
-- JLJ      2/14/2011      v1.03a
-- ~~~~~~
--  Initial integration of Hsiao ECC algorithm.
--  Add C_ECC_TYPE top level parameter.
--  Similar edits as wr_chnl on Hsiao ECC code.
-- ^^^^^^
-- JLJ      2/18/2011      v1.03a
-- ~~~~~~
--  Update for usage of ecc_gen.vhd module directly from MIG.
--  Clean-up XST warnings.
-- ^^^^^^
-- JLJ      2/22/2011      v1.03a
-- ~~~~~~
--  Found issue with ECC decoding on read path.  Remove MSB '0' usage 
--  in syndrome calculation, since h_matrix is based on 32 + 7 = 39 bits.
--  Modify read data signal used in single bit error correction.
-- ^^^^^^
-- JLJ      2/23/2011      v1.03a
-- ~~~~~~
--  Move all MIG functions to package body.
-- ^^^^^^
-- JLJ      3/2/2011        v1.03a
-- ~~~~~~
--  Fix XST handling for DIV functions.  Create seperate process when
--  divisor is not constant and a power of two.
-- ^^^^^^
-- JLJ      3/15/2011        v1.03a
-- ~~~~~~
--  Clean-up unused signal, narrow_addr_inc.
-- ^^^^^^
-- JLJ      3/17/2011      v1.03a
-- ~~~~~~
--  Add comments as noted in Spyglass runs. And general code clean-up.
-- ^^^^^^
-- JLJ      4/21/2011      v1.03a
-- ~~~~~~
--  Code clean up.
--  Add defaults to araddr_pipe_sel & axi_arready_int when in single port mode.
--  Remove use of IF_IS_AXI4 constant.
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
--  With CR # 609695, update else clause for narrow_burst_cnt_ld to 
--  remove simulation warnings when axi_byte_div_curr_arsize = zero.
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
use work.wrap_brst;
use work.ua_narrow;
use work.checkbit_handler;
use work.checkbit_handler_64;
use work.correct_one_bit;
use work.correct_one_bit_64;
use work.ecc_gen;
use work.parity;
use work.axi_bram_ctrl_funcs.all;


 ------------------------------------------------------------------------------


entity rd_chnl is
generic (


    --  C_FAMILY : string := "virtex6";
        -- Specify the target architecture type

    C_AXI_ADDR_WIDTH    : integer := 32;
      -- Width of AXI address bus (in bits)
      
    C_BRAM_ADDR_ADJUST_FACTOR   : integer := 2;
      -- Adjust factor to BRAM address width based on data width (in bits)
    
    C_AXI_DATA_WIDTH  : integer := 32;
      -- Width of AXI data bus (in bits)
      
    C_AXI_ID_WIDTH : integer := 4;
        --  AXI ID vector width

    C_S_AXI_SUPPORTS_NARROW : integer := 1;
        -- Support for narrow burst operations

    C_S_AXI_PROTOCOL : string := "AXI4";
        -- Set to "AXI4LITE" to optimize out burst transaction support

    C_SINGLE_PORT_BRAM : integer := 0;
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


    -- AXI Read Address Channel Signals (AR)
    AXI_ARID                : in    std_logic_vector(C_AXI_ID_WIDTH-1 downto 0);
    AXI_ARADDR              : in    std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
    
    AXI_ARLEN               : in    std_logic_vector(7 downto 0);
        -- Specifies the number of data transfers in the burst
        -- "0000 0000"  1 data transfer
        -- "0000 0001"  2 data transfers
        -- ...
        -- "1111 1111" 256 data transfers
      
    AXI_ARSIZE              : in    std_logic_vector(2 downto 0);
        -- Specifies the max number of data bytes to transfer in each data beat
        -- "000"    1 byte to transfer
        -- "001"    2 bytes to transfer
        -- "010"    3 bytes to transfer
        -- ...
      
    AXI_ARBURST             : in    std_logic_vector(1 downto 0);
        -- Specifies burst type
        -- "00" FIXED = Fixed burst address (handled as INCR)
        -- "01" INCR = Increment burst address
        -- "10" WRAP = Incrementing address burst that wraps to lower order address at boundary
        -- "11" Reserved (not checked)
    
    AXI_ARLOCK              : in    std_logic;                                  
    AXI_ARCACHE             : in    std_logic_vector(3 downto 0);
    AXI_ARPROT              : in    std_logic_vector(2 downto 0);

    AXI_ARVALID             : in    std_logic;
    AXI_ARREADY             : out   std_logic;
    

    -- AXI Read Data Channel Signals (R)
    AXI_RID                 : out   std_logic_vector(C_AXI_ID_WIDTH-1 downto 0);
    AXI_RDATA               : out   std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    AXI_RRESP               : out   std_logic_vector(1 downto 0);
    AXI_RLAST               : out   std_logic;

    AXI_RVALID              : out   std_logic;
    AXI_RREADY              : in    std_logic;
    

    -- ECC Register Interface Signals
    Enable_ECC              : in    std_logic;
    BRAM_Addr_En            : out   std_logic;
    CE_Failing_We           : out   std_logic := '0'; 
    Sl_CE                   : out   std_logic := '0'; 
    Sl_UE                   : out   std_logic := '0'; 
    

    -- Single Port Arbitration Signals
    Arb2AR_Active               : in   std_logic;
    AR2Arb_Active_Clr           : out  std_logic := '0';

    Sng_BRAM_Addr_Ld_En         : out   std_logic := '0';
    Sng_BRAM_Addr_Ld            : out   std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) := (others => '0');
    Sng_BRAM_Addr_Inc           : out   std_logic := '0';
    Sng_BRAM_Addr               : in    std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR);

    
    -- BRAM Read Port Interface Signals
    BRAM_En                 : out   std_logic;
    BRAM_Addr               : out   std_logic_vector (C_AXI_ADDR_WIDTH-1 downto 0);
    BRAM_RdData             : in    std_logic_vector (C_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0)
       
    

    );



end entity rd_chnl;


-------------------------------------------------------------------------------

architecture implementation of rd_chnl is

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

-- Set constants for ARLEN equal to a count of one or two beats.
constant AXI_ARLEN_ONE  : std_logic_vector(7 downto 0) := (others => '0');
constant AXI_ARLEN_TWO  : std_logic_vector(7 downto 0) := "00000001";


-- Modify C_BRAM_ADDR_SIZE to be adjusted for BRAM data width
-- When BRAM data width = 32 bits, BRAM_Addr (1:0) = "00"
-- When BRAM data width = 64 bits, BRAM_Addr (2:0) = "000"
-- When BRAM data width = 128 bits, BRAM_Addr (3:0) = "0000"
-- When BRAM data width = 256 bits, BRAM_Addr (4:0) = "00000"
-- Move to full_axi module
-- constant C_BRAM_ADDR_ADJUST_FACTOR : integer := log2 (C_AXI_DATA_WIDTH/8);
-- Not used
-- constant C_BRAM_ADDR_ADJUST : integer := C_AXI_ADDR_WIDTH - C_BRAM_ADDR_ADJUST_FACTOR;


-- Determine maximum size for narrow burst length counter
-- When C_AXI_DATA_WIDTH = 32, minimum narrow width burst is 8 bits
--              resulting in a count 3 downto 0 => so minimum counter width = 2 bits.
-- When C_AXI_DATA_WIDTH = 256, minimum narrow width burst is 8 bits
--              resulting in a count 31 downto 0 => so minimum counter width = 5 bits.

constant C_NARROW_BURST_CNT_LEN : integer := log2 (C_AXI_DATA_WIDTH/8);
constant NARROW_CNT_MAX     : std_logic_vector (C_NARROW_BURST_CNT_LEN-1 downto 0) := (others => '0');


-- Max length burst count AXI4 specification
constant C_MAX_BRST_CNT         : integer := 256;
constant C_BRST_CNT_SIZE        : integer := log2 (C_MAX_BRST_CNT);

-- When the burst count = 0
constant C_BRST_CNT_ZERO    : std_logic_vector(C_BRST_CNT_SIZE-1 downto 0) := (others => '0');

-- Burst count = 1
constant C_BRST_CNT_ONE     : std_logic_vector(7 downto 0) := "00000001";

-- Burst count = 2
constant C_BRST_CNT_TWO     : std_logic_vector(7 downto 0) := "00000010";          


-- Read data mux select constants (for signal rddata_mux_sel)
    -- '0' selects BRAM
    -- '1' selects read skid buffer
constant C_RDDATA_MUX_BRAM          : std_logic := '0';
constant C_RDDATA_MUX_SKID_BUF      : std_logic := '1';   


-- Determine the number of bytes based on the AXI data width.
constant C_AXI_DATA_WIDTH_BYTES     : integer := C_AXI_DATA_WIDTH/8;


-- AXI Burst Types
-- AXI Spec 4.4
constant C_AXI_BURST_WRAP       : std_logic_vector (1 downto 0) := "10";  
constant C_AXI_BURST_INCR       : std_logic_vector (1 downto 0) := "01";  
constant C_AXI_BURST_FIXED      : std_logic_vector (1 downto 0) := "00";  


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

-- Internal ECC data width size.
constant C_INT_ECC_WIDTH : integer := Int_ECC_Size (C_AXI_DATA_WIDTH);

-- For use with ECC functions (to use LUT6 components or let synthesis infer the optimal implementation).
-- constant C_USE_LUT6 : boolean := Family_To_LUT_Size (String_To_Family (C_FAMILY,false)) = 6;
-- Remove usage of C_FAMILY.
-- All architectures supporting AXI will support a LUT6. 
-- Hard code this internal constant used in ECC algorithm.
constant C_USE_LUT6 : boolean := TRUE;



-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- AXI Read Address Channel Signals
-------------------------------------------------------------------------------


-- State machine type declarations
type RD_ADDR_SM_TYPE is ( IDLE,
                          LD_ARADDR
                        );
                    
signal rd_addr_sm_cs, rd_addr_sm_ns : RD_ADDR_SM_TYPE;

signal ar_active_set            : std_logic := '0';
signal ar_active_set_i          : std_logic := '0';
signal ar_active_clr            : std_logic := '0';
signal ar_active                : std_logic := '0';
signal ar_active_d1             : std_logic := '0';
signal ar_active_re             : std_logic := '0';


signal axi_araddr_pipe          : std_logic_vector (C_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');

signal curr_araddr_lsb          : std_logic_vector (C_BRAM_ADDR_ADJUST_FACTOR-1 downto 0) := (others => '0');
signal araddr_pipe_ld           : std_logic := '0';
signal araddr_pipe_ld_i         : std_logic := '0';
signal araddr_pipe_sel          : std_logic := '0';
    -- '0' indicates mux select from AXI
    -- '1' indicates mux select from AR Addr Register
signal axi_araddr_full          : std_logic := '0';

signal axi_arready_int          : std_logic := '0';
signal axi_early_arready_int    : std_logic := '0';


signal axi_aresetn_d1           : std_logic := '0';
signal axi_aresetn_d2           : std_logic := '0';
signal axi_aresetn_re           : std_logic := '0';
signal axi_aresetn_re_reg       : std_logic := '0';


signal no_ar_ack_cmb        : std_logic := '0';
signal no_ar_ack            : std_logic := '0';

signal pend_rd_op_cmb       : std_logic := '0';
signal pend_rd_op           : std_logic := '0';


signal axi_arid_pipe            : std_logic_vector (C_AXI_ID_WIDTH-1 downto 0) := (others => '0');

signal axi_arsize_pipe          : std_logic_vector (2 downto 0) := (others => '0');
signal axi_arsize_pipe_4byte    : std_logic := '0';
signal axi_arsize_pipe_8byte    : std_logic := '0';
signal axi_arsize_pipe_16byte   : std_logic := '0';
signal axi_arsize_pipe_32byte   : std_logic := '0';

-- v1.03a
signal axi_arsize_pipe_max      : std_logic := '0';


signal curr_arsize              : std_logic_vector (2 downto 0) := (others => '0');
signal curr_arsize_reg          : std_logic_vector (2 downto 0) := (others => '0');



signal axi_arlen_pipe           : std_logic_vector(7 downto 0) := (others => '0');
signal axi_arlen_pipe_1_or_2    : std_logic := '0';           

signal curr_arlen               : std_logic_vector(7 downto 0) := (others => '0');
signal curr_arlen_reg           : std_logic_vector(7 downto 0) := (others => '0');

signal axi_arburst_pipe         : std_logic_vector(1 downto 0) := (others => '0');
signal axi_arburst_pipe_fixed   : std_logic := '0';            

signal curr_arburst             : std_logic_vector(1 downto 0) := (others => '0');
signal curr_wrap_burst          : std_logic := '0';
signal curr_wrap_burst_reg      : std_logic := '0';
signal max_wrap_burst           : std_logic := '0';

signal curr_incr_burst          : std_logic := '0';

signal curr_fixed_burst         : std_logic := '0';
signal curr_fixed_burst_reg     : std_logic := '0';




-- BRAM Address Counter    
signal bram_addr_ld_en          : std_logic := '0';
signal bram_addr_ld_en_i        : std_logic := '0';
signal bram_addr_ld_en_mod      : std_logic := '0';

signal bram_addr_ld             : std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)
                                    := (others => '0');
signal bram_addr_ld_wrap        : std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)
                                    := (others => '0');

signal bram_addr_inc                : std_logic := '0';
signal bram_addr_inc_mod            : std_logic := '0';
signal bram_addr_inc_wrap_mod       : std_logic := '0';         



-------------------------------------------------------------------------------
-- AXI Read Data Channel Signals
-------------------------------------------------------------------------------


-- State machine type declarations
type RD_DATA_SM_TYPE is ( IDLE,
                          SNG_ADDR,
                          SEC_ADDR,
                          FULL_PIPE,
                          FULL_THROTTLE,
                          LAST_ADDR,
                          LAST_THROTTLE,
                          LAST_DATA,
                          LAST_DATA_AR_PEND
                        );
                    
signal rd_data_sm_cs, rd_data_sm_ns : RD_DATA_SM_TYPE;

signal rd_adv_buf               : std_logic := '0';
signal axi_rd_burst             : std_logic := '0';
signal axi_rd_burst_two         : std_logic := '0';

signal act_rd_burst             : std_logic := '0';
signal act_rd_burst_set         : std_logic := '0';
signal act_rd_burst_clr         : std_logic := '0';
signal act_rd_burst_two         : std_logic := '0';

-- Rd Data Buffer/Register
signal rd_skid_buf_ld_cmb       : std_logic := '0';
signal rd_skid_buf_ld_reg       : std_logic := '0';
signal rd_skid_buf_ld           : std_logic := '0';
signal rd_skid_buf_ld_imm       : std_logic := '0';
signal rd_skid_buf              : std_logic_vector (C_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

signal rddata_mux_sel_cmb   : std_logic := '0';
signal rddata_mux_sel       : std_logic := '0';

signal axi_rdata_en         : std_logic := '0';
signal axi_rdata_mux        : std_logic_vector (C_AXI_DATA_WIDTH+8*C_ECC-1 downto 0) := (others => '0');



-- Read Burst Counter
signal brst_cnt_max         : std_logic := '0';
signal brst_cnt_max_d1      : std_logic := '0';
signal brst_cnt_max_re      : std_logic := '0';

signal end_brst_rd_clr_cmb  : std_logic := '0';
signal end_brst_rd_clr      : std_logic := '0';
signal end_brst_rd          : std_logic := '0';

signal brst_zero            : std_logic := '0';
signal brst_one             : std_logic := '0';


signal brst_cnt_ld          : std_logic_vector (C_BRST_CNT_SIZE-1 downto 0) := (others => '0');
signal brst_cnt_rst         : std_logic := '0';
signal brst_cnt_ld_en       : std_logic := '0';
signal brst_cnt_ld_en_i     : std_logic := '0';
signal brst_cnt_dec         : std_logic := '0';
signal brst_cnt             : std_logic_vector (C_BRST_CNT_SIZE-1 downto 0) := (others => '0');



-- AXI Read Response Signals
signal axi_rid_temp         : std_logic_vector (C_AXI_ID_WIDTH-1 downto 0) := (others => '0');
signal axi_rid_temp_full    : std_logic := '0';
signal axi_rid_temp_full_d1 : std_logic := '0';
signal axi_rid_temp_full_fe : std_logic := '0';


signal axi_rid_temp2        : std_logic_vector (C_AXI_ID_WIDTH-1 downto 0) := (others => '0');
signal axi_rid_temp2_full   : std_logic := '0';

signal axi_b2b_rid_adv      : std_logic := '0';     
signal axi_rid_int          : std_logic_vector (C_AXI_ID_WIDTH-1 downto 0) := (others => '0');

signal axi_rresp_int        : std_logic_vector (1 downto 0) := (others => '0');

signal axi_rvalid_clr_ok    : std_logic := '0';     
signal axi_rvalid_set_cmb   : std_logic := '0';
signal axi_rvalid_set       : std_logic := '0';
signal axi_rvalid_int       : std_logic := '0';

signal axi_rlast_int        : std_logic := '0';
signal axi_rlast_set        : std_logic := '0';
    

-- Internal BRAM Signals
signal bram_en_cmb          : std_logic := '0';
signal bram_en_int          : std_logic := '0';

signal bram_addr_int        : std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)
                                := (others => '0');



-- Narrow Burst Signals
signal curr_narrow_burst_cmb    : std_logic := '0';
signal curr_narrow_burst        : std_logic := '0';
signal narrow_burst_cnt_ld      : std_logic_vector (C_NARROW_BURST_CNT_LEN-1 downto 0) := (others => '0');
signal narrow_burst_cnt_ld_reg  : std_logic_vector (C_NARROW_BURST_CNT_LEN-1 downto 0) := (others => '0');
signal narrow_burst_cnt_ld_mod  : std_logic_vector (C_NARROW_BURST_CNT_LEN-1 downto 0) := (others => '0');


signal narrow_addr_rst          : std_logic := '0';       
signal narrow_addr_ld_en        : std_logic := '0';
signal narrow_addr_dec          : std_logic := '0';


signal narrow_bram_addr_inc         : std_logic := '0';
signal narrow_bram_addr_inc_d1      : std_logic := '0';
signal narrow_bram_addr_inc_re      : std_logic := '0';

signal narrow_addr_int              : std_logic_vector (C_NARROW_BURST_CNT_LEN-1 downto 0) := (others => '0');

signal curr_ua_narrow_wrap          : std_logic := '0';
signal curr_ua_narrow_incr          : std_logic := '0';
signal ua_narrow_load               : std_logic_vector (C_NARROW_BURST_CNT_LEN-1 downto 0) := (others => '0');




-- State machine type declarations
type RLAST_SM_TYPE is ( IDLE,
                        W8_THROTTLE,
                        W8_2ND_LAST_DATA,
                        W8_LAST_DATA,
                        -- W8_LAST_DATA_B2,
                        W8_THROTTLE_B2
                        );
                    
signal rlast_sm_cs, rlast_sm_ns : RLAST_SM_TYPE;

signal last_bram_addr               : std_logic := '0';
signal set_last_bram_addr           : std_logic := '0';

signal alast_bram_addr              : std_logic := '0';

signal rd_b2b_elgible               : std_logic := '0';
signal rd_b2b_elgible_no_thr_check  : std_logic := '0';
signal throttle_last_data           : std_logic := '0';

signal disable_b2b_brst_cmb         : std_logic := '0';
signal disable_b2b_brst             : std_logic := '0';

signal axi_b2b_brst_cmb             : std_logic := '0';
signal axi_b2b_brst                 : std_logic := '0';

signal do_cmplt_burst_cmb           : std_logic := '0';
signal do_cmplt_burst               : std_logic := '0';
signal do_cmplt_burst_clr           : std_logic := '0';


-------------------------------------------------------------------------------
-- ECC Signals
-------------------------------------------------------------------------------

signal UnCorrectedRdData    : std_logic_vector (0 to C_AXI_DATA_WIDTH-1) := (others => '0');

-- Move vector from core ECC module to use in AXI RDATA register output
signal Syndrome             : std_logic_vector(0 to C_INT_ECC_WIDTH-1) := (others => '0');     -- Specific to BRAM data width
signal Syndrome_4           : std_logic_vector (0 to 1) := (others => '0');                     -- Only used in 32-bit ECC
signal Syndrome_6           : std_logic_vector (0 to 5) := (others => '0');                     -- Specific to ECC @ 32-bit data width
signal Syndrome_7           : std_logic_vector (0 to 11) := (others => '0');                    -- Specific to ECC @ 64-bit data width

signal syndrome_reg         : std_logic_vector(0 to C_INT_ECC_WIDTH-1) := (others => '0');     -- Specific to BRAM data width
signal syndrome_reg_i       : std_logic_vector(0 to C_INT_ECC_WIDTH-1) := (others => '0');     -- Specific to BRAM data width

signal Sl_UE_i              : std_logic := '0';
signal UE_Q                 : std_logic := '0';

-- v1.03a
-- Hsiao ECC
signal syndrome_r   : std_logic_vector (C_INT_ECC_WIDTH - 1 downto 0) := (others => '0');

constant CODE_WIDTH : integer := C_AXI_DATA_WIDTH + C_INT_ECC_WIDTH;
constant ECC_WIDTH  : integer := C_INT_ECC_WIDTH;

signal h_rows       : std_logic_vector (CODE_WIDTH * ECC_WIDTH - 1 downto 0);



-------------------------------------------------------------------------------
-- Architecture Body
-------------------------------------------------------------------------------


begin 





    ---------------------------------------------------------------------------
    -- AXI Read Address Channel Output Signals
    ---------------------------------------------------------------------------



    ---------------------------------------------------------------------------
    -- Generate:    GEN_ARREADY_DUAL
    -- Purpose:     Generate AXI_ARREADY when in dual port mode.
    ---------------------------------------------------------------------------
    GEN_ARREADY_DUAL: if C_SINGLE_PORT_BRAM = 0 generate
    begin

        -- Ensure ARREADY only gets asserted early when acknowledge recognized
        -- on AXI read data channel.
        AXI_ARREADY <= axi_arready_int or (axi_early_arready_int and rd_adv_buf);

    end generate GEN_ARREADY_DUAL;
    
    

    ---------------------------------------------------------------------------
    -- Generate:    GEN_ARREADY_SNG
    -- Purpose:     Generate AXI_ARREADY when in single port mode.
    ---------------------------------------------------------------------------
    GEN_ARREADY_SNG: if C_SINGLE_PORT_BRAM = 1 generate
    begin

        -- ARREADY generated by sng_port_arb module
        AXI_ARREADY <= '0';
        axi_arready_int <= '0';
        
    end generate GEN_ARREADY_SNG;
    
   

    

    ---------------------------------------------------------------------------
    -- AXI Read Data Channel Output Signals
    ---------------------------------------------------------------------------

    -- UE flag is detected is same clock cycle that read data is presented on 
    -- the AXI bus.  Must drive SLVERR combinatorially to align with corrupted 
    -- detected data word.
    AXI_RRESP <= RESP_SLVERR when (C_ECC = 1 and Sl_UE_i = '1') else axi_rresp_int;
    AXI_RVALID <= axi_rvalid_int;

    AXI_RID <= axi_rid_int;             
    AXI_RLAST <= axi_rlast_int;




    ---------------------------------------------------------------------------
    --
    -- *** AXI Read Address Channel Interface ***
    --
    ---------------------------------------------------------------------------



    ---------------------------------------------------------------------------
    -- Generate:    GEN_AR_PIPE_SNG
    -- Purpose:     Only generate pipeline registers when in dual port BRAM mode.
    ---------------------------------------------------------------------------

    GEN_AR_PIPE_SNG: if C_SINGLE_PORT_BRAM = 1 generate
    begin
    
        -- Unused AW pipeline (set default values)
        araddr_pipe_ld <= '0';
        axi_araddr_pipe <= AXI_ARADDR;
        axi_arid_pipe <= AXI_ARID;
        axi_arsize_pipe <= AXI_ARSIZE;
        axi_arlen_pipe <= AXI_ARLEN;
        axi_arburst_pipe <= AXI_ARBURST;
        axi_arlen_pipe_1_or_2 <= '0';
        axi_arburst_pipe_fixed <= '0';
        axi_araddr_full <= '0';
            
    end generate GEN_AR_PIPE_SNG;






    ---------------------------------------------------------------------------
    -- Generate:    GEN_AR_PIPE_DUAL
    -- Purpose:     Only generate pipeline registers when in dual port BRAM mode.
    ---------------------------------------------------------------------------

    GEN_AR_PIPE_DUAL: if C_SINGLE_PORT_BRAM = 0 generate
    begin

        -----------------------------------------------------------------------
        -- AXI Read Address Buffer/Register
        -- (mimic behavior of address pipeline for AXI_ARID)
        -----------------------------------------------------------------------

        GEN_ARADDR: for i in C_AXI_ADDR_WIDTH-1 downto 0 generate
        begin

            REG_ARADDR: process (S_AXI_AClk)
            begin

                if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                    -- No reset condition to save resources/timing

                    if (araddr_pipe_ld = '1') then
                        axi_araddr_pipe (i) <= AXI_ARADDR (i);
                    else
                        axi_araddr_pipe (i) <= axi_araddr_pipe (i);

                    end if;
                end if;
            end process REG_ARADDR;

        end generate GEN_ARADDR;

    
        -------------------------------------------------------------------
        -- Register ARID
        -- No reset condition to save resources/timing
        -------------------------------------------------------------------

        REG_ARID: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (araddr_pipe_ld = '1') then
                    axi_arid_pipe <= AXI_ARID;
                else
                    axi_arid_pipe <= axi_arid_pipe;

                end if;
            end if;
        end process REG_ARID;



        ---------------------------------------------------------------------------

        -- In parallel to ARADDR pipeline and ARID
        -- Use same control signals to capture AXI_ARSIZE, AXI_ARLEN & AXI_ARBURST.

        -- Register AXI_ARSIZE, AXI_ARLEN & AXI_ARBURST
        -- No reset condition to save resources/timing

        REG_ARCTRL: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (araddr_pipe_ld = '1') then
                    axi_arsize_pipe <= AXI_ARSIZE;
                    axi_arlen_pipe <= AXI_ARLEN;
                    axi_arburst_pipe <= AXI_ARBURST;
                else
                    axi_arsize_pipe <= axi_arsize_pipe;
                    axi_arlen_pipe <= axi_arlen_pipe;
                    axi_arburst_pipe <= axi_arburst_pipe;

                end if;

            end if;

        end process REG_ARCTRL;


        ---------------------------------------------------------------------------


        -- Create signals that indicate value of AXI_ARLEN in pipeline stage
        -- Used to decode length of burst when BRAM address can be loaded early
        -- when pipeline is full.
        --
        -- Add early decode of ARBURST in pipeline.
        -- Copy logic from WR_CHNL module (similar logic).
        -- Add early decode of ARSIZE = 4 bytes in pipeline.


        REG_ARLEN_PIPE: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                -- No reset condition to save resources/timing

                if (araddr_pipe_ld = '1') then

                    -- Create merge to decode ARLEN of ONE or TWO
                    if (AXI_ARLEN = AXI_ARLEN_ONE) or (AXI_ARLEN = AXI_ARLEN_TWO) then
                        axi_arlen_pipe_1_or_2 <= '1';
                    else
                        axi_arlen_pipe_1_or_2 <= '0';
                    end if;


                    -- Early decode on value in pipeline of ARBURST
                    if (AXI_ARBURST = C_AXI_BURST_FIXED) then
                        axi_arburst_pipe_fixed <= '1';                
                    else
                        axi_arburst_pipe_fixed <= '0';
                    end if;

                else

                    axi_arlen_pipe_1_or_2 <= axi_arlen_pipe_1_or_2;
                    axi_arburst_pipe_fixed <= axi_arburst_pipe_fixed;

                end if;

            end if;

        end process REG_ARLEN_PIPE;



        ---------------------------------------------------------------------------

        -- Create full flag for ARADDR pipeline
        -- Set when read address register is loaded.
        -- Cleared when read address stored in register is loaded into BRAM
        -- address counter.

        REG_RDADDR_FULL: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                   -- (bram_addr_ld_en = '1' and araddr_pipe_sel = '1') then

                   (bram_addr_ld_en = '1' and araddr_pipe_sel = '1' and araddr_pipe_ld = '0') then
                    axi_araddr_full <= '0';

                elsif (araddr_pipe_ld = '1') then
                    axi_araddr_full <= '1';
                else
                    axi_araddr_full <= axi_araddr_full;
                end if;
            end if;

        end process REG_RDADDR_FULL;


        ---------------------------------------------------------------------------

    end generate GEN_AR_PIPE_DUAL;



    ---------------------------------------------------------------------------

    -- v1.03a
    -- Add early decode of ARSIZE = max size in pipeline based on AXI data
    -- bus width (use constant, C_AXI_SIZE_MAX)

    REG_ARSIZE_PIPE: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                axi_arsize_pipe_max <= '0';

            elsif (araddr_pipe_ld = '1') then

                -- Early decode of ARSIZE in pipeline equal to max # of bytes
                -- based on AXI data bus width
                if (AXI_ARSIZE = C_AXI_SIZE_MAX) then                   
                    axi_arsize_pipe_max <= '1';
                else
                    axi_arsize_pipe_max <= '0';
                end if;                

            else
                axi_arsize_pipe_max <= axi_arsize_pipe_max;
            end if;
        end if;

    end process REG_ARSIZE_PIPE;


   




    ---------------------------------------------------------------------------
    -- Generate:    GE_ARREADY
    -- Purpose:     ARREADY is only created here when in dual port BRAM mode.
    ---------------------------------------------------------------------------
    GEN_ARREADY: if (C_SINGLE_PORT_BRAM = 0) generate
    begin


        ----------------------------------------------------------------------------
        --  AXI_ARREADY Output Register
        --  Description:    Keep AXI_ARREADY output asserted until ARADDR pipeline
        --                  is full.  When a full condition is reached, negate
        --                  ARREADY as another AR address can not be accepted.
        --                  Add condition to keep ARReady asserted if loading current
        ---                 ARADDR pipeline value into the BRAM address counter.
        --                  Indicated by assertion of bram_addr_ld_en & araddr_pipe_sel.
        --
        ----------------------------------------------------------------------------

        REG_ARREADY: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then

                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    axi_arready_int <= '0';

                -- Detect end of S_AXI_AResetn to assert AWREADY and accept 
                -- new AWADDR values
                elsif (axi_aresetn_re_reg = '1') or 

                      -- Add condition for early ARREADY to keep pipeline full
                      (bram_addr_ld_en = '1' and araddr_pipe_sel = '1' and axi_early_arready_int = '0') then            
                    axi_arready_int <= '1';

                -- Add conditional check if ARREADY is asserted (with ARVALID) (one clock cycle later) 
                -- when the address pipeline is full.
                elsif (araddr_pipe_ld = '1') or 
                      (AXI_ARVALID = '1' and axi_arready_int = '1' and axi_araddr_full = '1') then

                    axi_arready_int <= '0';
                else
                    axi_arready_int <= axi_arready_int;
                end if;
            end if;

        end process REG_ARREADY;


        ----------------------------------------------------------------------------


        REG_EARLY_ARREADY: process (S_AXI_AClk)
        begin
            if (S_AXI_AClk'event and S_AXI_AClk = '1') then

                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    axi_early_arready_int <= '0';

                -- Pending ARADDR and ARREADY is not yet asserted to accept
                -- operation (due to ARADDR being full)
                elsif (AXI_ARVALID = '1' and axi_arready_int = '0' and 
                       axi_araddr_full = '1') and
                      (alast_bram_addr = '1') and

                      -- Add check for elgible back-to-back BRAM load
                      (rd_b2b_elgible = '1') then 

                    axi_early_arready_int <= '1';

                else
                    axi_early_arready_int <= '0';
                end if;
            end if;

        end process REG_EARLY_ARREADY;


        ---------------------------------------------------------------------------

        -- Need to detect end of reset cycle to assert ARREADY on AXI bus
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

        ----------------------------------------------------------------------------


    end generate GEN_ARREADY;

   
   

    ---------------------------------------------------------------------------
    -- Generate:    GEN_DUAL_ADDR_CNT
    -- Purpose:     Instantiate BRAM address counter unique for wr_chnl logic
    --              only when controller configured in dual port mode.
    ---------------------------------------------------------------------------
    GEN_DUAL_ADDR_CNT: if (C_SINGLE_PORT_BRAM = 0) generate
    begin

        
        ---------------------------------------------------------------------------
        
        -- Replace I_ADDR_CNT module usage of pf_counter in proc_common library.
        -- Only need to use lower 12-bits of address due to max AXI burst size
        -- Since AXI guarantees bursts do not cross 4KB boundary, the counting part 
        -- of I_ADDR_CNT can be reduced to max 4KB. 
        --
        -- No reset on bram_addr_int.
        -- Increment ONLY.

        REG_ADDR_CNT: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then

                if (bram_addr_ld_en_mod = '1') then
                    bram_addr_int <= bram_addr_ld;

                elsif (bram_addr_inc_mod = '1') then
                    bram_addr_int (C_AXI_ADDR_WIDTH-1 downto 12) <= 
                            bram_addr_int (C_AXI_ADDR_WIDTH-1 downto 12);
                    bram_addr_int (11 downto C_BRAM_ADDR_ADJUST_FACTOR) <= 
                            std_logic_vector (unsigned (bram_addr_int (11 downto C_BRAM_ADDR_ADJUST_FACTOR)) + 1);

                end if;
            end if;

        end process REG_ADDR_CNT;

        ---------------------------------------------------------------------------

        -- Set defaults to shared address counter
        -- Only used in single port configurations
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
    
        Sng_BRAM_Addr_Ld_En <= bram_addr_ld_en_mod;
        Sng_BRAM_Addr_Ld <= bram_addr_ld;
        Sng_BRAM_Addr_Inc <= bram_addr_inc_mod;
        bram_addr_int <= Sng_BRAM_Addr; 

    end generate GEN_SNG_ADDR_CNT;


    ---------------------------------------------------------------------------

    -- BRAM address load mux.
    -- Either load BRAM counter directly from AXI bus or from stored registered value    
    -- Use registered signal to indicate current operation is a WRAP burst
    --
    -- Match bram_addr_ld to what asserts bram_addr_ld_en_mod
    -- Include bram_addr_inc_mod when asserted to use bram_addr_ld_wrap value
    -- (otherwise use pipelined or AXI bus value to load BRAM address counter)

    bram_addr_ld <= bram_addr_ld_wrap when (max_wrap_burst = '1' and 
                                            curr_wrap_burst_reg = '1' and 
                                            bram_addr_inc_wrap_mod = '1') else

                    axi_araddr_pipe (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) 
                        when (araddr_pipe_sel = '1') else 

                    AXI_ARADDR (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR);

    ---------------------------------------------------------------------------


    -- On wrap burst max loads (simultaneous BRAM address increment is asserted).
    -- Ensure that load has higher priority over increment.
    -- Use registered signal to indicate current operation is a WRAP burst

    bram_addr_ld_en_mod <= '1' when (bram_addr_ld_en = '1' or 
                                     (max_wrap_burst = '1' and 
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


    -- Narrow bursting
    --
    -- Handle read burst addressing on narrow burst operations
    -- Intercept BRAM address increment flag, bram_addr_inc and only
    -- increment address when the number of BRAM reads match the width of the
    -- AXI data bus.

    -- For a 32-bit BRAM, byte burst will increment the BRAM address 
    --      after four reads from BRAM.
    -- For a 256-bit BRAM, a byte burst will increment the BRAM address 
    --      after 32 reads from BRAM.


    -- Based on current operation being a narrow burst, hold off BRAM
    -- address increment until narrow burst fits BRAM data width.
    -- For non narrow burst operations, use bram_addr_inc from data SM.
    --
    -- Add in check that burst type is not FIXED, curr_fixed_burst_reg

    -- bram_addr_inc_mod <= (bram_addr_inc and not (curr_fixed_burst_reg)) when (curr_narrow_burst = '0') else
    --                      narrow_bram_addr_inc_re;
    --
    --
    -- Replace w/ below generate statements based on supporting narrow transfers or not.
    -- Create generate statement around the signal assignment for bram_addr_inc_mod.
    


    ---------------------------------------------------------------------------
    -- Generate:    GEN_BRAM_INC_MOD_W_NARROW
    -- Purpose:     Assign signal, bram_addr_inc_mod when narrow transfers
    --              are supported in design instantiation.
    ---------------------------------------------------------------------------

    GEN_BRAM_INC_MOD_W_NARROW: if (C_S_AXI_SUPPORTS_NARROW = 1) generate
    begin

        -- Found issue when narrow FIXED length burst is incorrectly incrementing BRAM address counter
        bram_addr_inc_mod <= (bram_addr_inc and not (curr_fixed_burst_reg)) when (curr_narrow_burst = '0') else
                             (narrow_bram_addr_inc_re and not (curr_fixed_burst_reg));

    end generate GEN_BRAM_INC_MOD_W_NARROW;



    ---------------------------------------------------------------------------
    -- Generate:    GEN_WO_NARROW
    -- Purpose:     Assign signal, bram_addr_inc_mod when narrow transfers
    --              are not supported in the design instantiation.
    --              Drive default values for narrow counter and logic when 
    --              narrow operation support is disabled.
    ---------------------------------------------------------------------------

    GEN_WO_NARROW: if (C_S_AXI_SUPPORTS_NARROW = 0) generate
    begin

        -- Found issue when narrow FIXED length burst is incorrectly incrementing BRAM address counter
        bram_addr_inc_mod <= bram_addr_inc and not (curr_fixed_burst_reg);

        narrow_addr_rst <= '0';
        narrow_burst_cnt_ld_mod <= (others => '0');
        narrow_addr_dec <= '0';
        narrow_addr_ld_en <= '0';    
        narrow_bram_addr_inc <= '0';
        narrow_bram_addr_inc_d1 <= '0';
        narrow_bram_addr_inc_re <= '0';
        narrow_addr_int <= (others => '0');        
        curr_narrow_burst <= '0';


    end generate GEN_WO_NARROW;




    ---------------------------------------------------------------------------
    --
    -- Only instantiate NARROW_CNT and supporting logic when narrow transfers
    -- are supported and utilized by masters in the AXI system.
    -- The design parameter, C_S_AXI_SUPPORTS_NARROW will indicate this.
    --
    ---------------------------------------------------------------------------


    ---------------------------------------------------------------------------
    -- Generate:    GEN_NARROW_CNT
    -- Purpose:     Instantiate narrow counter and logic when narrow
    --              operation support is enabled.
    ---------------------------------------------------------------------------

    GEN_NARROW_CNT: if (C_S_AXI_SUPPORTS_NARROW = 1) generate
    begin


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

        REG_NARROW_CNT: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then

                if (narrow_addr_rst = '1') then
                    narrow_addr_int <= (others => '0');

                -- Load enable
                elsif (narrow_addr_ld_en = '1') then
                    narrow_addr_int <= narrow_burst_cnt_ld_mod;

                -- Decrement ONLY (no increment functionality)
                elsif (narrow_addr_dec = '1') then
                    narrow_addr_int (C_NARROW_BURST_CNT_LEN-1 downto 0) <= 
                            std_logic_vector (unsigned (narrow_addr_int (C_NARROW_BURST_CNT_LEN-1 downto 0)) - 1);

                end if;

            end if;

        end process REG_NARROW_CNT;


        ---------------------------------------------------------------------------


        narrow_addr_rst <= not (S_AXI_AResetn);

        -- Modify narrow burst count load value based on
        -- unalignment of AXI address value

        narrow_burst_cnt_ld_mod <= ua_narrow_load when (curr_ua_narrow_wrap = '1' or curr_ua_narrow_incr = '1') else
                                   narrow_burst_cnt_ld when (bram_addr_ld_en = '1') else
                                   narrow_burst_cnt_ld_reg;

        narrow_addr_dec <= bram_addr_inc when (curr_narrow_burst = '1') else '0';

        narrow_addr_ld_en <= (curr_narrow_burst_cmb and bram_addr_ld_en) or narrow_bram_addr_inc_re;


        narrow_bram_addr_inc <= '1' when (narrow_addr_int = NARROW_CNT_MAX) and 
                                         (curr_narrow_burst = '1') 

                                         -- Ensure that narrow address counter doesn't 
                                         -- flag max or get loaded to
                                         -- reset narrow counter until AXI read data 
                                         -- bus has acknowledged current
                                         -- data on the AXI bus.  Use rd_adv_buf signal 
                                         -- to indicate the non throttle
                                         -- condition on the AXI bus.

                                         and (bram_addr_inc = '1')
                                else '0';

        ----------------------------------------------------------------------------

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




    ----------------------------------------------------------------------------


    -- Specify current ARSIZE signal 
    -- Address pipeline MUX
    curr_arsize <= axi_arsize_pipe when (araddr_pipe_sel = '1') else AXI_ARSIZE;


    REG_ARSIZE: process (S_AXI_AClk)
    begin
    
        if (S_AXI_AClk'event and S_AXI_AClk = '1') then
    
            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                curr_arsize_reg <= (others => '0');
                
            -- Register curr_arsize when bram_addr_ld_en = '1'
            elsif (bram_addr_ld_en = '1') then
                curr_arsize_reg <= curr_arsize;
                
            else
                curr_arsize_reg <= curr_arsize_reg;
            end if;
    
        end if;
    end process REG_ARSIZE;




    ---------------------------------------------------------------------------
    -- Generate:    GEN_NARROW_EN
    -- Purpose:     Only instantiate logic to determine if current burst
    --              is a narrow burst when narrow bursting logic is supported.
    ---------------------------------------------------------------------------

    GEN_NARROW_EN: if (C_S_AXI_SUPPORTS_NARROW = 1) generate
    begin


        -----------------------------------------------------------------------
        -- Determine "narrow" burst transfers
        -- Compare the ARSIZE to the BRAM data width
        -----------------------------------------------------------------------

        -- v1.03a
        -- Detect if current burst operation is of size /= to the full
        -- AXI data bus width.  If not, then the current operation is a 
        -- "narrow" burst.
        
        curr_narrow_burst_cmb <= '1' when (curr_arsize /= C_AXI_SIZE_MAX) else '0';

        ---------------------------------------------------------------------------


        -- Register flag indicating the current operation
        -- is a narrow read burst
        NARROW_BURST_REG: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then

                -- Need to reset this flag at end of narrow burst operation
                -- Ensure if curr_narrow_burst got set during previous transaction, axi_rlast_set
                -- doesn't clear the flag (add check for pend_rd_op negated).

                if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                   (axi_rlast_set = '1' and pend_rd_op = '0' and bram_addr_ld_en = '0') then
                    curr_narrow_burst <= '0';                  

                -- Add check for burst operation using ARLEN value
                -- Ensure that narrow burst flag does not get set during FIXED burst types

                elsif (bram_addr_ld_en = '1') and (curr_arlen /= AXI_ARLEN_ONE) and
                      (curr_fixed_burst = '0') then

                    curr_narrow_burst <= curr_narrow_burst_cmb;
                end if;

            end if;

        end process NARROW_BURST_REG;


    end generate GEN_NARROW_EN;


    ---------------------------------------------------------------------------
    -- Generate:    GEN_NARROW_CNT_LD
    -- Purpose:     Only instantiate logic to determine narrow burst counter
    --              load value when narrow bursts are enabled.
    ---------------------------------------------------------------------------

    GEN_NARROW_CNT_LD: if (C_S_AXI_SUPPORTS_NARROW = 1) generate

    signal curr_arsize_unsigned : unsigned (2 downto 0) := (others => '0');
    signal axi_byte_div_curr_arsize : integer := 1;

    begin


        -- v1.03a
        
        -- Create narrow burst counter load value based on current operation
        -- "narrow" data width (indicated by value of AWSIZE).
        
        curr_arsize_unsigned <= unsigned (curr_arsize);


        -- XST does not support divisors that are not constants and powers of 2.
        -- Create process to create a fixed value for divisor.

        -- Replace this statement:
        --    narrow_burst_cnt_ld <= std_logic_vector (
        --                            to_unsigned (
        --                                   (C_AXI_DATA_WIDTH_BYTES / (2**(to_integer (curr_arsize_unsigned))) ) - 1, 
        --                                    C_NARROW_BURST_CNT_LEN));


        --     -- With this new process and subsequent signal assignment:
        --     DIV_AWSIZE: process (curr_arsize_unsigned)
        --     begin
        --     
        --         case (to_integer (curr_arsize_unsigned)) is
        --             when 0 =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 1;
        --             when 1 =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 2;
        --             when 2 =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 4;
        --             when 3 =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 8;
        --             when 4 =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 16;
        --             when 5 =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 32;
        --             when 6 =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 64;
        --             when 7 =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 128;
        --         --coverage off
        --             when others => axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES;
        --         --coverage on
        --         end case;
        --     
        --     end process DIV_AWSIZE;


        -- w/ CR # 609695


        -- With this new process and subsequent signal assignment:
        DIV_AWSIZE: process (curr_arsize_unsigned)
        begin

            case (curr_arsize_unsigned) is
                when "000" =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 1;
                when "001" =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 2;
                when "010" =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 4;
                when "011" =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 8;
                when "100" =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 16;
                when "101" =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 32;
                when "110" =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 64;
                when "111" =>   axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES / 128;
            --coverage off
                when others => axi_byte_div_curr_arsize <= C_AXI_DATA_WIDTH_BYTES;
            --coverage on
            end case;

        end process DIV_AWSIZE;

        
    
        -- v1.03a
        -- Replace with new signal assignment.
        -- For synthesis to support only divisors that are constant and powers of two.


        -- Updated else clause for simulation warnings w/ CR # 609695

        narrow_burst_cnt_ld <= std_logic_vector (
                                to_unsigned (
                                    (axi_byte_div_curr_arsize) - 1, C_NARROW_BURST_CNT_LEN))
                               when (axi_byte_div_curr_arsize > 0)
                               else std_logic_vector (to_unsigned (0, C_NARROW_BURST_CNT_LEN));



        ---------------------------------------------------------------------------

        -- Register narrow burst count load indicator
        
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
    curr_wrap_burst <= '1' when (curr_arburst = C_AXI_BURST_WRAP) else '0';
    curr_incr_burst <= '1' when (curr_arburst = C_AXI_BURST_INCR) else '0';
    curr_fixed_burst <= '1' when (curr_arburst = C_AXI_BURST_FIXED) else '0';

    ----------------------------------------------------------------------------


    -- Register curr_wrap_burst & curr_fixed_burst signals when BRAM 
    -- address counter is initially loaded

    REG_CURR_BRST: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1') then

            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                curr_wrap_burst_reg <= '0';
                curr_fixed_burst_reg <= '0';

            elsif (bram_addr_ld_en = '1') then 
                curr_wrap_burst_reg <= curr_wrap_burst;
                curr_fixed_burst_reg <= curr_fixed_burst;
            else
                curr_wrap_burst_reg <= curr_wrap_burst_reg;
                curr_fixed_burst_reg <= curr_fixed_burst_reg;
            end if;

        end if;
    end process REG_CURR_BRST;



    ---------------------------------------------------------------------------
    -- Instance: I_WRAP_BRST
    --
    -- Description:
    --
    --      Instantiate WRAP_BRST module
    --      Logic to generate the wrap around value to load into the BRAM address
    --      counter on WRAP burst transactions.
    --      WRAP value is based on current ARLEN, ARSIZE (for narrows) and
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

        S_AXI_AClk                  =>  S_AXI_ACLK                  ,
        S_AXI_AResetn               =>  S_AXI_ARESETN               ,   

        curr_axlen                  =>  curr_arlen                  ,
        curr_axsize                 =>  curr_arsize                 ,
        curr_narrow_burst           =>  curr_narrow_burst           ,
        narrow_bram_addr_inc_re     =>  narrow_bram_addr_inc_re     ,
        bram_addr_ld_en             =>  bram_addr_ld_en             ,
        bram_addr_ld                =>  bram_addr_ld                ,
        bram_addr_int               =>  bram_addr_int               ,
        bram_addr_ld_wrap           =>  bram_addr_ld_wrap           ,
        max_wrap_burst_mod          =>  max_wrap_burst     

    );    
    
    


    ----------------------------------------------------------------------------

    -- Specify current ARBURST signal 
    -- Input address pipeline MUX
    curr_arburst <= axi_arburst_pipe when (araddr_pipe_sel = '1') else AXI_ARBURST;

    ----------------------------------------------------------------------------

    -- Specify current AWBURST signal 
    -- Input address pipeline MUX
    curr_arlen <= axi_arlen_pipe when (araddr_pipe_sel = '1') else AXI_ARLEN;

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
        --
        -- New logic to detect unaligned address on a narrow WRAP burst transaction.
        -- If this condition is met, then the narrow burst counter will be
        -- initially loaded with an offset value corresponding to the unalignment
        -- in the ARADDR value.
        --
        --
        -- Create a sub module for all logic to determine the narrow burst counter
        -- offset value on unaligned WRAP burst operations.
        --
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
        --
        -- Instance: I_UA_NARROW
        --
        -- Description:
        --
        --      Creates a narrow burst count load value when an operation
        --      is an unaligned narrow WRAP or INCR burst type.  Used by
        --      I_NARROW_CNT module.
        --
        --      Logic is customized for each C_AXI_DATA_WIDTH.
        --
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

            curr_axlen                  =>  curr_arlen                  ,       -- in
            curr_axsize                 =>  curr_arsize                 ,       -- in
            curr_axaddr_lsb             =>  curr_araddr_lsb             ,       -- in
            
            curr_ua_narrow_wrap         =>  curr_ua_narrow_wrap         ,       -- out
            curr_ua_narrow_incr         =>  curr_ua_narrow_incr         ,       -- out
            ua_narrow_load              =>  ua_narrow_load                      -- out

        );    
    
    
           

        -- Use in all C_AXI_DATA_WIDTH generate statements

        -- Only probe least significant BRAM address bits
        -- C_BRAM_ADDR_ADJUST_FACTOR offset down to 0.
        curr_araddr_lsb <= axi_araddr_pipe (C_BRAM_ADDR_ADJUST_FACTOR-1 downto 0) 
                            when (araddr_pipe_sel = '1') else 
                        AXI_ARADDR (C_BRAM_ADDR_ADJUST_FACTOR-1 downto 0);





    end generate GEN_UA_NARROW;




    ----------------------------------------------------------------------------
    --
    -- New logic to detect if pending operation in ARADDR pipeline is
    -- elgible for back-to-back no "bubble" performance. And BRAM address
    -- counter can be loaded upon last BRAM address presented for the current
    -- operation.

    -- This condition exists when the ARADDR pipeline is full and the pending
    -- operation is a burst >= length of two data beats.
    -- And not a FIXED burst type (must be INCR or WRAP type).

    -- The DATA SM handles detecting a throttle condition and will void
    -- the capability to be a back-to-back in performance transaction.
    --
    -- Add check if new operation is a narrow burst (to be loaded into BRAM 
    -- counter)
    -- Add check for throttling condition on after last BRAM address is
    -- presented
    --
    ----------------------------------------------------------------------------

    -- v1.03a
    rd_b2b_elgible_no_thr_check <= '1' when (axi_araddr_full = '1') and
                                            (axi_arlen_pipe_1_or_2 /= '1') and
                                            (axi_arburst_pipe_fixed /= '1') and
                                            (disable_b2b_brst = '0') and
                                            (axi_arsize_pipe_max = '1')
                                        else '0';


    rd_b2b_elgible <= '1' when (rd_b2b_elgible_no_thr_check = '1') and
                               (throttle_last_data = '0')
                        else '0';


    -- Check if SM is in LAST_THROTTLE state which also indicates we are throttling at 
    -- the last data beat in the read burst.  Ensures that the bursts are not implemented
    -- as back-to-back bursts and RVALID will negate upon recognition of RLAST and RID
    -- pipeline will be advanced properly.


    -- Fix timing path on araddr_pipe_sel generated in RDADDR SM
    -- SM uses rd_b2b_elgible signal which checks throttle condition on
    -- last data beat to hold off loading new BRAM address counter for next
    -- back-to-back operation.

    -- Attempt to modify logic in generation of throttle_last_data signal.

    throttle_last_data <= '1' when ((brst_zero = '1') and (rd_adv_buf = '0')) or
                                   (rd_data_sm_cs = LAST_THROTTLE)
                            else '0';


    ----------------------------------------------------------------------------

    

    

    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_AR_SNG
    -- Purpose:     If single port BRAM configuration, set all AR flags from
    --              logic generated in sng_port_arb module.
    --
    ---------------------------------------------------------------------------
    
    
    GEN_AR_SNG: if (C_SINGLE_PORT_BRAM = 1) generate
    begin
        
        araddr_pipe_sel <= '0';         -- Unused in single port configuration
        
        ar_active <= Arb2AR_Active;
        bram_addr_ld_en <= ar_active_re;
        brst_cnt_ld_en <= ar_active_re;
        
        AR2Arb_Active_Clr <= axi_rlast_int and AXI_RREADY;
        
        -- Rising edge detect of Arb2AR_Active
        RE_AR_ACT: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                
                -- Clear ar_active_d1 early w/ ar_active
                -- So back to back ar_active assertions see the new transaction
                -- and initiate the read transfer.
                if (S_AXI_AResetn = C_RESET_ACTIVE) or ((axi_rlast_int and AXI_RREADY) = '1') then
                    ar_active_d1 <= '0';
                else
                    ar_active_d1 <= ar_active;
                end if;
            end if;
        end process RE_AR_ACT;
        
        ar_active_re <= '1' when (ar_active = '1' and ar_active_d1 = '0') else '0';


    end generate GEN_AR_SNG;        
    
    
    
    
    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_AW_DUAL
    -- Purpose:     Generate AW control state machine logic only when AXI4
    --              controller is configured for dual port mode.  In dual port
    --              mode, wr_chnl has full access over AW & port A of BRAM.
    --
    ---------------------------------------------------------------------------
    
    GEN_AR_DUAL: if (C_SINGLE_PORT_BRAM = 0) generate
    begin

        AR2Arb_Active_Clr <= '0';   -- Only used in single port case


        ---------------------------------------------------------------------------
        -- RD ADDR State Machine
        --
        -- Description:     Central processing unit for AXI write address
        --                  channel interface handling and handshaking.
        --
        -- Outputs:         araddr_pipe_ld          Not Registered
        --                  araddr_pipe_sel         Not Registered
        --                  bram_addr_ld_en         Not Registered
        --                  brst_cnt_ld_en          Not Registered
        --                  ar_active_set           Not Registered
        --
        -- WR_ADDR_SM_CMB_PROCESS:      Combinational process to determine next state.
        -- WR_ADDR_SM_REG_PROCESS:      Registered process of the state machine.
        --
        ---------------------------------------------------------------------------

        RD_ADDR_SM_CMB_PROCESS: process ( AXI_ARVALID,
                                          axi_araddr_full,
                                          ar_active,
                                          no_ar_ack,
                                          pend_rd_op,
                                          last_bram_addr,           
                                          rd_b2b_elgible,           
                                          rd_addr_sm_cs )

        begin

        -- assign default values for state machine outputs
        rd_addr_sm_ns <= rd_addr_sm_cs;
        araddr_pipe_ld_i <= '0';
        bram_addr_ld_en_i <= '0';
        brst_cnt_ld_en_i <= '0';
        ar_active_set_i <= '0';

        case rd_addr_sm_cs is


                ---------------------------- IDLE State ---------------------------

                when IDLE =>


                    -- Reload BRAM address counter on last BRAM address of current burst
                    -- if a new address is pending in the AR pipeline and is elgible to
                    -- be loaded for subsequent back-to-back performance.

                    if (last_bram_addr = '1' and rd_b2b_elgible = '1') then

                        -- Load BRAM address counter from pipelined value
                        bram_addr_ld_en_i <= '1';
                        brst_cnt_ld_en_i <= '1';

                        ar_active_set_i <= '1';


                        -- If loading BRAM counter for subsequent operation
                        -- AND ARVALID is pending on the bus, go ahead and respond
                        -- and fill ARADDR pipeline with next operation.
                        -- 
                        -- Asserting the signal to load the ARADDR pipeline here
                        -- allows the full bandwidth utilization to BRAM on
                        -- back to back bursts of two data beats.

                        if (AXI_ARVALID = '1') then
                            araddr_pipe_ld_i <= '1';
                            rd_addr_sm_ns <= LD_ARADDR;
                        else
                            rd_addr_sm_ns <= IDLE;
                        end if;


                    elsif (AXI_ARVALID = '1') then

                        -- If address pipeline is full
                        -- ARReady output is negated
                        -- Remain in this state
                        --
                        -- Add check for already pending read operation
                        -- in data SM, but waiting on throttle (even though ar_active is
                        -- already set to '0').

                        if (ar_active = '0') and (no_ar_ack = '0') and (pend_rd_op = '0') then

                            rd_addr_sm_ns <= IDLE;
                            bram_addr_ld_en_i <= '1';
                            brst_cnt_ld_en_i <= '1';
                            ar_active_set_i <= '1';


                        -- Address counter is currently busy
                        else

                            -- Check if ARADDR pipeline is not full and can be loaded
                            if (axi_araddr_full = '0') then

                                rd_addr_sm_ns <= LD_ARADDR;
                                araddr_pipe_ld_i <= '1';

                            end if;

                        end if; -- ar_active


                    -- Pending operation in pipeline that is waiting
                    -- until current operation is complete (ar_active = '0')

                    elsif (axi_araddr_full = '1') and 
                          (ar_active = '0') and 
                          (no_ar_ack = '0') and 
                          (pend_rd_op = '0') then

                        rd_addr_sm_ns <= IDLE;

                        -- Load BRAM address counter from pipelined value
                        bram_addr_ld_en_i <= '1';
                        brst_cnt_ld_en_i <= '1';

                        ar_active_set_i <= '1';

                    end if; -- ARVALID



                ---------------------------- LD_ARADDR State ---------------------------

                when LD_ARADDR =>


                    -- Check here for subsequent BRAM address load when ARADDR pipe is loaded
                    -- in previous clock cycle.
                    -- 
                    -- Reload BRAM address counter on last BRAM address of current burst
                    -- if a new address is pending in the AR pipeline and is elgible to
                    -- be loaded for subsequent back-to-back performance.

                    if (last_bram_addr = '1' and rd_b2b_elgible = '1') then

                        -- Load BRAM address counter from pipelined value
                        bram_addr_ld_en_i <= '1';
                        brst_cnt_ld_en_i <= '1';

                        ar_active_set_i <= '1';

                        -- If loading BRAM counter for subsequent operation
                        -- AND ARVALID is pending on the bus, go ahead and respond
                        -- and fill ARADDR pipeline with next operation.
                        -- 
                        -- Asserting the signal to load the ARADDR pipeline here
                        -- allows the full bandwidth utilization to BRAM on
                        -- back to back bursts of two data beats.

                        if (AXI_ARVALID = '1') then

                            araddr_pipe_ld_i <= '1';
                            rd_addr_sm_ns <= LD_ARADDR;
                            -- Stay in this state another clock cycle

                        else
                            rd_addr_sm_ns <= IDLE;
                        end if;

                    else
                        rd_addr_sm_ns <= IDLE;
                    end if;



        --coverage off
                ------------------------------ Default ----------------------------
                when others =>
                    rd_addr_sm_ns <= IDLE;
        --coverage on

            end case;

        end process RD_ADDR_SM_CMB_PROCESS;


        ---------------------------------------------------------------------------

        -- CR # 582705
        -- Ensure combinatorial SM output signals do not get set before
        -- the end of the reset (and ARREAADY can be set).
        bram_addr_ld_en <= bram_addr_ld_en_i and axi_aresetn_d2;
        brst_cnt_ld_en <= brst_cnt_ld_en_i and axi_aresetn_d2;
        ar_active_set <= ar_active_set_i and axi_aresetn_d2;
        araddr_pipe_ld <= araddr_pipe_ld_i and axi_aresetn_d2;


        RD_ADDR_SM_REG_PROCESS: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                -- if (S_AXI_AResetn = C_RESET_ACTIVE) then
                
                -- CR # 582705
                -- Ensure that ar_active does not get asserted (from SM) before 
                -- the end of reset and the ARREADY flag is set.
                if (axi_aresetn_d2 = C_RESET_ACTIVE) then
                    rd_addr_sm_cs <= IDLE;
                else
                    rd_addr_sm_cs <= rd_addr_sm_ns;
                end if;
            end if;

        end process RD_ADDR_SM_REG_PROCESS;


        ---------------------------------------------------------------------------

        -- Assert araddr_pipe_sel outside of SM logic
        -- The BRAM address counter will get loaded with value in ARADDR pipeline
        -- when data is stored in the ARADDR pipeline.

        araddr_pipe_sel <= '1' when (axi_araddr_full = '1') else '0'; 


        ---------------------------------------------------------------------------


        -- Register for ar_active

        REG_AR_ACT: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                -- if (S_AXI_AResetn = C_RESET_ACTIVE) then
                
                -- CR # 582705
                if (axi_aresetn_d2 = C_RESET_ACTIVE) then
                    ar_active <= '0';

                elsif (ar_active_set = '1') then 
                    ar_active <= '1';

                -- For code coverage closure, ensure priority encoding in if/else clause
                -- to prevent checking ar_active_set in reset clause.
                elsif (ar_active_clr = '1') then
                    ar_active <= '0';

                else 
                    ar_active <= ar_active;
                end if;
            end if;

        end process REG_AR_ACT;


    end generate GEN_AR_DUAL;


   

    ---------------------------------------------------------------------------
    --
    --  REG_BRST_CNT. 
    --  Read Burst Counter.
    --  No need to decrement burst counter.
    --  Able to load with fixed burst length value.
    --  Replace usage of proc_common_v4_0_2 library with direct HDL.
    --
    --  Size of counter = C_BRST_CNT_SIZE
    --                    Max size of burst transfer = 256 data beats
    --
    ---------------------------------------------------------------------------

    REG_BRST_CNT: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1') then

            if (brst_cnt_rst = '1') then
                brst_cnt <= (others => '0');

            -- Load burst counter
            elsif (brst_cnt_ld_en = '1') then
                brst_cnt <= brst_cnt_ld;

            -- Decrement ONLY (no increment functionality)
            elsif (brst_cnt_dec = '1') then
                brst_cnt (C_BRST_CNT_SIZE-1 downto 0) <= 
                        std_logic_vector (unsigned (brst_cnt (C_BRST_CNT_SIZE-1 downto 0)) - 1);

            end if;
        end if;

    end process REG_BRST_CNT;


    ---------------------------------------------------------------------------

    brst_cnt_rst <= not (S_AXI_AResetn);


    -- Determine burst count load value
    -- Either load BRAM counter directly from AXI bus or from stored registered value.
    -- Use mux signal for ARLEN

    BRST_CNT_LD_PROCESS : process (curr_arlen)
    variable brst_cnt_ld_int    : integer := 0;
    begin

        brst_cnt_ld_int := to_integer (unsigned (curr_arlen (7 downto 0)));
        brst_cnt_ld <= std_logic_vector (to_unsigned (brst_cnt_ld_int, 8));

    end process BRST_CNT_LD_PROCESS;



    ----------------------------------------------------------------------------




    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_BRST_MAX_W_NARROW
    -- Purpose:     Generate registered logic for brst_cnt_max when the
    --              design instantiation supports narrow operations.
    --
    ---------------------------------------------------------------------------

    GEN_BRST_MAX_W_NARROW: if (C_S_AXI_SUPPORTS_NARROW = 1) generate
    begin


        REG_BRST_MAX: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) or (brst_cnt_ld_en = '1')
                
                    -- Added with single port (13.1 release)
                    or (end_brst_rd_clr = '1') then
                    brst_cnt_max <= '0';

                -- Replace usage of brst_cnt in this logic.
                -- Replace with registered signal, brst_zero, indicating the 
                -- brst_cnt to be zero when decrement.

                elsif (brst_zero = '1') and (ar_active = '1') and (pend_rd_op = '0') then 


                    -- Hold off assertion of brst_cnt_max on narrow burst transfers
                    -- Must wait until narrow burst count = 0.
                    if (curr_narrow_burst = '1') then

                        if (narrow_bram_addr_inc = '1') then
                            brst_cnt_max <= '1';
                        end if;
                    else
                        brst_cnt_max <= '1';
                    end if;

                else 
                    brst_cnt_max <= brst_cnt_max;
                end if;
            end if;

        end process REG_BRST_MAX;



    end generate GEN_BRST_MAX_W_NARROW;



    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_BRST_MAX_WO_NARROW
    -- Purpose:     Generate registered logic for brst_cnt_max when the
    --              design instantiation does not support narrow operations.
    --
    ---------------------------------------------------------------------------

    GEN_BRST_MAX_WO_NARROW: if (C_S_AXI_SUPPORTS_NARROW = 0) generate
    begin


        REG_BRST_MAX: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) or (brst_cnt_ld_en = '1') then
                    brst_cnt_max <= '0';

                -- Replace usage of brst_cnt in this logic.
                -- Replace with registered signal, brst_zero, indicating the 
                -- brst_cnt to be zero when decrement.

                elsif (brst_zero = '1') and (ar_active = '1') and (pend_rd_op = '0') then 

                    -- When narrow operations are not supported in the core
                    -- configuration, no check for curr_narrow_burst on assertion.
                    brst_cnt_max <= '1';

                else 
                    brst_cnt_max <= brst_cnt_max;
                end if;
            end if;

        end process REG_BRST_MAX;


    end generate GEN_BRST_MAX_WO_NARROW;



    ---------------------------------------------------------------------------


    REG_BRST_MAX_D1: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                brst_cnt_max_d1 <= '0';
            else 
                brst_cnt_max_d1 <= brst_cnt_max;
            end if;
        end if;

    end process REG_BRST_MAX_D1;


    brst_cnt_max_re <= '1' when (brst_cnt_max = '1') and (brst_cnt_max_d1 = '0') else '0';


    -- Set flag that end of burst is reached
    -- Need to capture this condition as the burst
    -- counter may get reloaded for a subsequent read burst

    REG_END_BURST: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            -- SM may assert clear flag early (in case of narrow bursts)
            -- Wait until the end_brst_rd flag is asserted to clear the flag.

            if (S_AXI_AResetn = C_RESET_ACTIVE) or 
               (end_brst_rd_clr = '1' and end_brst_rd = '1') then
                end_brst_rd <= '0';

            elsif (brst_cnt_max_re = '1') then
                end_brst_rd <= '1';
            end if;
        end if;

    end process REG_END_BURST;



    ---------------------------------------------------------------------------

    -- Create flag that indicates burst counter is reaching ZEROs (max of burst
    -- length)

    REG_BURST_ZERO: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

             if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                ((brst_cnt_ld_en = '1') and (brst_cnt_ld /= C_BRST_CNT_ZERO)) then
                 brst_zero <= '0';

             elsif (brst_cnt_dec = '1') and (brst_cnt = C_BRST_CNT_ONE) then
                 brst_zero <= '1';
             else
                 brst_zero <= brst_zero;
             end if;

        end if;

    end process REG_BURST_ZERO;


    ---------------------------------------------------------------------------

    -- Create additional flag that indicates burst counter is reaching ONEs 
    -- (near end of burst length).  Used to disable back-to-back condition in SM.

    REG_BURST_ONE: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

             if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                ((brst_cnt_ld_en = '1') and (brst_cnt_ld /= C_BRST_CNT_ONE)) or
                ((brst_cnt_dec = '1') and (brst_cnt = C_BRST_CNT_ONE)) then
                 brst_one <= '0';

             elsif ((brst_cnt_dec = '1') and (brst_cnt = C_BRST_CNT_TWO)) or
                   ((brst_cnt_ld_en = '1') and (brst_cnt_ld = C_BRST_CNT_ONE)) then
                 brst_one <= '1';
             else
                 brst_one <= brst_one;
             end if;

        end if;

    end process REG_BURST_ONE;


    ---------------------------------------------------------------------------

    -- Register flags for read burst operation
    REG_RD_BURST: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            -- Clear axi_rd_burst flags when burst count gets to zeros (unless the burst
            -- counter is getting subsequently loaded for the new burst operation)
            -- 
            -- Replace usage of brst_cnt in this logic.
            -- Replace with registered signal, brst_zero, indicating the 
            -- brst_cnt to be zero when decrement.

            if (S_AXI_AResetn = C_RESET_ACTIVE) or (brst_zero = '1' and brst_cnt_ld_en = '0') then
                axi_rd_burst <= '0';
                axi_rd_burst_two <= '0';

            elsif (brst_cnt_ld_en = '1') then

                if (curr_arlen /= AXI_ARLEN_ONE and curr_arlen /= AXI_ARLEN_TWO) then
                    axi_rd_burst <= '1';
                else
                    axi_rd_burst <= '0';
                end if;

                if (curr_arlen = AXI_ARLEN_TWO) then
                    axi_rd_burst_two <= '1';
                else
                    axi_rd_burst_two <= '0';
                end if;

            else
                axi_rd_burst <= axi_rd_burst;
                axi_rd_burst_two <= axi_rd_burst_two;

            end if;
        end if;

    end process REG_RD_BURST;



    ---------------------------------------------------------------------------


    -- Seeing issue with axi_rd_burst getting cleared too soon
    -- on subsquent brst_cnt_ld_en early assertion and pend_rd_op is asserted.


    -- Create flag for currently active read burst operation
    -- Gets asserted when burst counter is loaded, but does not
    -- get cleared until the RD_DATA_SM has completed the read
    -- burst operation

    REG_ACT_RD_BURST: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) or (act_rd_burst_clr = '1') then
                act_rd_burst <= '0';
                act_rd_burst_two <= '0';

            elsif (act_rd_burst_set = '1') then

                -- If not loading the burst counter for a B2B operation
                -- Then act_rd_burst follows axi_rd_burst and
                -- act_rd_burst_two follows axi_rd_burst_two.

                -- Get registered value of axi_* signal.
                if (brst_cnt_ld_en = '0') then
                    act_rd_burst <= axi_rd_burst;
                    act_rd_burst_two <= axi_rd_burst_two;

                else

                    -- Otherwise, duplicate logic for axi_* signals if burst counter
                    -- is getting loaded.

                    -- For improved code coverage here
                    -- The act_rd_burst_set signal will never get asserted if the burst
                    -- size is less than two data beats.  So, the conditional check
                    -- for (curr_arlen /= AXI_ARLEN_ONE) is never evaluated.  Removed
                    -- from this if clause.

                    if (curr_arlen /= AXI_ARLEN_TWO) then
                        act_rd_burst <= '1';
                    else
                        act_rd_burst <= '0';
                    end if;


                    if (curr_arlen = AXI_ARLEN_TWO) then
                        act_rd_burst_two <= '1';
                    else
                        act_rd_burst_two <= '0';
                    end if;

                    -- Note: re-code this if/else clause.
                end if;

            else
                act_rd_burst <= act_rd_burst;
                act_rd_burst_two <= act_rd_burst_two;

            end if;
        end if;

    end process REG_ACT_RD_BURST;



    ---------------------------------------------------------------------------



    rd_adv_buf <= axi_rvalid_int and AXI_RREADY;





    ---------------------------------------------------------------------------
    -- RD DATA State Machine
    --
    -- Description:     Central processing unit for AXI write data
    --                  channel interface handling and AXI write data response
    --                  handshaking.
    --
    -- Outputs:         Name                        Type
    --
    --                  bram_en_int                 Registered
    --                  bram_addr_inc               Not Registered
    --                  brst_cnt_dec                Not Registered
    --                  rddata_mux_sel              Registered
    --                  axi_rdata_en                Not Registered
    --                  axi_rvalid_set              Registered
    --
    --
    -- RD_DATA_SM_CMB_PROCESS:      Combinational process to determine next state.
    -- RD_DATA_SM_REG_PROCESS:      Registered process of the state machine.
    --
    ---------------------------------------------------------------------------
    RD_DATA_SM_CMB_PROCESS: process ( bram_addr_ld_en,
                                      rd_adv_buf,
                                      ar_active,
                                      axi_araddr_full,                  
                                      rd_b2b_elgible_no_thr_check,      

                                      disable_b2b_brst,                 

                                      curr_arlen,                       

                                      axi_rd_burst, 
                                      axi_rd_burst_two,
                                      act_rd_burst,
                                      act_rd_burst_two,

                                      end_brst_rd,
                                      brst_zero,                        
                                      brst_one,                         

                                      axi_b2b_brst,                     

                                      bram_en_int,
                                      rddata_mux_sel,
                                      end_brst_rd_clr,
                                      no_ar_ack,
                                      pend_rd_op,
                                      axi_rlast_int,                    

                                      rd_data_sm_cs )

    begin

        -- assign default values for state machine outputs
        rd_data_sm_ns <= rd_data_sm_cs;

        bram_en_cmb <= bram_en_int;
        bram_addr_inc <= '0';
        brst_cnt_dec <= '0';

        rd_skid_buf_ld_cmb <= '0';
        rd_skid_buf_ld_imm <= '0';
        rddata_mux_sel_cmb <= rddata_mux_sel;  

        -- Change axi_rdata_en generated from SM to be a combinatorial signal
        -- Can't afford the latency when throttling on the AXI bus.
        axi_rdata_en <= '0';

        axi_rvalid_set_cmb <= '0';

        end_brst_rd_clr_cmb <= end_brst_rd_clr;

        no_ar_ack_cmb <= no_ar_ack;
        pend_rd_op_cmb <= pend_rd_op;
        act_rd_burst_set <= '0';
        act_rd_burst_clr <= '0';

        set_last_bram_addr <= '0';
        alast_bram_addr <= '0';                     
        axi_b2b_brst_cmb <= axi_b2b_brst;           
        disable_b2b_brst_cmb <= disable_b2b_brst;   

        ar_active_clr <= '0';                       

        case rd_data_sm_cs is


                ---------------------------- IDLE State ---------------------------

                when IDLE =>


                    -- Initiate BRAM read when address is available in controller
                    -- Indicated by load of BRAM address counter

                    -- Remove use of pend_rd_op signal.
                    -- Never asserted as we transition back to IDLE
                    -- Detected in code coverage

                    if (bram_addr_ld_en = '1') then

                        -- At start of new read, clear end burst signal
                        end_brst_rd_clr_cmb <= '0';

                        -- Initiate BRAM read transfer
                        bram_en_cmb <= '1';


                        -- Only count addresses & burst length for read
                        -- burst operations


                        -- If currently loading BRAM address counter
                        -- Must check curr_arlen (mux output from pipe or AXI bus)
                        -- to determine length of next operation.
                        -- If ARLEN = 1 data beat, then set last_bram_addr signal
                        -- Otherwise, increment BRAM address counter.

                        if (curr_arlen /= AXI_ARLEN_ONE) then


                            -- Start of new operation, update act_rd_burst and 
                            -- act_rd_burst_two signals
                            act_rd_burst_set <= '1';


                        else
                            -- Set flag for last_bram_addr on transition
                            -- to SNG_ADDR on single operations.
                            set_last_bram_addr <= '1';

                        end if;

                        -- Go to single active read address state
                        rd_data_sm_ns <= SNG_ADDR;


                    end if;


                ------------------------- SNG_ADDR State --------------------------

                when SNG_ADDR =>



                    -- Clear flag once pending read is recognized
                    -- Duplicate logic here in case combinatorial flag was getting
                    -- set as the SM transitioned into this state.
                    if (pend_rd_op = '1') then
                        pend_rd_op_cmb <= '0';
                    end if;


                    -- At start of new read, clear end burst signal
                    end_brst_rd_clr_cmb <= '0';


                    -- Reach this state on first BRAM address & enable assertion
                    -- For burst operation, create next BRAM address and keep enable
                    -- asserted

                    -- Note:
                    -- No ability to throttle yet as RVALID has not yet been
                    -- asserted on the AXI bus


                    -- Reset data mux select between skid buffer and BRAM
                    -- Ensure read data mux is set for BRAM data
                    rddata_mux_sel_cmb <= C_RDDATA_MUX_BRAM;  


                    -- Assert RVALID on AXI when 1st data beat available
                    -- from BRAM
                    axi_rvalid_set_cmb <= '1';                                


                    -- Reach this state when BRAM address counter is loaded
                    -- Use axi_rd_burst and axi_rd_burst_two to indicate if
                    -- operation is a single data beat burst.

                    if (axi_rd_burst = '0') and (axi_rd_burst_two = '0') then


                        -- Proceed directly to get BRAM read data
                        rd_data_sm_ns <= LAST_ADDR;

                        -- End of active current read address
                        ar_active_clr <= '1';

                        -- Negate BRAM enable
                        bram_en_cmb <= '0';

                        -- Load read data skid buffer for BRAM capture 
                        -- in next clock cycle
                        rd_skid_buf_ld_cmb <= '1';


                        -- Assert new flag to disable back-to-back bursts
                        -- due to throttling
                        disable_b2b_brst_cmb <= '1';

                        
                        -- Set flag for pending operation if bram_addr_ld_en is asserted (BRAM
                        -- address is loaded) and we are waiting for the current read burst to complete.
                        if (bram_addr_ld_en = '1') then
                            pend_rd_op_cmb <= '1';
                        end if;


                    -- Read burst
                    else

                        -- Increment BRAM address counter (2nd data beat)
                        bram_addr_inc <= '1';

                        -- Decrement BRAM burst counter (2nd data beat)
                        brst_cnt_dec <= '1';

                        -- Keep BRAM enable asserted
                        bram_en_cmb <= '1';

                        rd_data_sm_ns <= SEC_ADDR;


                        -- Load read data skid buffer for BRAM capture 
                        -- in next clock cycle
                        rd_skid_buf_ld_cmb <= '1';

                        -- Start of new operation, update act_rd_burst and 
                        -- act_rd_burst_two signals
                        act_rd_burst_set <= '1';


                        -- If new burst is 2 data beats
                        -- Then disable capability on back-to-back bursts
                        if (axi_rd_burst_two = '1') then

                            -- Assert new flag to disable back-to-back bursts
                            -- due to throttling
                            disable_b2b_brst_cmb <= '1';

                        else
                            -- Support back-to-back for all other burst lengths
                            disable_b2b_brst_cmb <= '0';

                        end if;


                    end if;




                ------------------------- SEC_ADDR State --------------------------

                when SEC_ADDR =>

                    -- Reach this state when the 2nd incremented address of the burst
                    -- is presented to the BRAM.

                    -- Only reach this state when axi_rd_burst = '1',
                    -- an active read burst.

                    -- Note:
                    -- No ability to throttle yet as RVALID has not yet been
                    -- asserted on the AXI bus


                    -- Enable AXI read data register
                    axi_rdata_en <= '1';


                    -- Only in dual port mode can the address counter get loaded early
                    if C_SINGLE_PORT_BRAM = 0 then

                        -- If we see the next address get loaded into the BRAM counter
                        -- then set flag for pending operation
                        if (bram_addr_ld_en = '1') then
                            pend_rd_op_cmb <= '1';
                        end if;

                    end if;
                    

                    -- Check here for burst length of two data transfers
                    -- If so, then the SM will NOT hit the condition of a full
                    -- pipeline:
                    -- Operation A) 1st BRAM address data on AXI bus
                    -- Operation B) 2nd BRAm address data read from BRAM
                    -- Operation C) 3rd BRAM address presented to BRAM
                    --
                    -- Full pipeline condition is hit for any read burst
                    -- length greater than 2 data beats.

                    if (axi_rd_burst_two = '1') then


                        -- No increment of BRAM address
                        -- or decrement of burst counter
                        -- Burst counter should be = zero
                        rd_data_sm_ns <= LAST_ADDR;

                        -- End of active current read address
                        ar_active_clr <= '1';

                        -- Ensure read data mux is set for BRAM data
                        rddata_mux_sel_cmb <= C_RDDATA_MUX_BRAM;                    

                        -- Negate BRAM enable
                        bram_en_cmb <= '0';


                        -- Load read data skid buffer for BRAM capture 
                        -- in next clock cycle.
                        -- This signal will negate in the next state
                        -- if the data is not accepted on the AXI bus.
                        -- So that no new data from BRAM is registered into the
                        -- read channel controller.
                        rd_skid_buf_ld_cmb <= '1';



                    else

                        -- Burst length will hit full pipeline condition

                        -- Increment BRAM address counter (3rd data beat)
                        bram_addr_inc <= '1';


                        -- Decrement BRAM burst counter (3rd data beat)
                        brst_cnt_dec <= '1';

                        -- Keep BRAM enable asserted
                        bram_en_cmb <= '1';

                        rd_data_sm_ns <= FULL_PIPE;


                        -- Assert almost last BRAM address flag
                        -- so that ARVALID logic output can remain registered
                        --
                        -- Replace usage of brst_cnt with signal, brst_one.
                        if (brst_one = '1') then
                            alast_bram_addr <= '1';                    
                        end if;

                        -- Load read data skid buffer for BRAM capture 
                        -- in next clock cycle
                        rd_skid_buf_ld_cmb <= '1';


                    end if; -- ARLEN = "0000 0001"





                ------------------------- FULL_PIPE State -------------------------

                when FULL_PIPE =>


                    -- Reach this state when all three data beats in the burst
                    -- are active
                    -- 
                    -- Operation A) 1st BRAM address data on AXI bus
                    -- Operation B) 2nd BRAM address data read from BRAM
                    -- Operation C) 3rd BRAM address presented to BRAM


                    -- Ensure read data mux is set for BRAM data
                    rddata_mux_sel_cmb <= C_RDDATA_MUX_BRAM;                    


                    -- With new pipelining capability BRAM address counter may be 
                    -- loaded in this state.  This only occurs on back-to-back 
                    -- bursts (when enabled).
                    -- No flag set for pending operation.

                    -- Modify the if clause here to check for back-to-back burst operations
                    -- If we load the BRAM address in this state for a subsequent burst, then
                    -- this condition indicates a back-to-back burst and no need to assert
                    -- the pending read operation flag.


                    -- Seeing corner case when pend_rd_op needs to be asserted and cleared
                    -- in this state.  If the BRAM address counter is loaded early, but
                    -- axi_rlast_set is delayed in getting asserted (all while in this state).
                    -- The signal, curr_narrow_burst can not get cleared.


                    -- Only in dual port mode can the address counter get loaded early
                    if C_SINGLE_PORT_BRAM = 0 then


                        -- Set flag for pending operation if bram_addr_ld_en is asserted (BRAM
                        -- address is loaded) and we are waiting for the current read burst to complete.
                        if (bram_addr_ld_en = '1') then
                            pend_rd_op_cmb <= '1';

                        -- Clear flag once pending read is recognized and
                        -- earlier read data phase is complete.
                        elsif (pend_rd_op = '1') and (axi_rlast_int = '1') then
                            pend_rd_op_cmb <= '0';

                        end if;

                    end if;


                    -- Check AXI throttling condition
                    -- If AXI bus advances and accepts read data, SM can
                    -- proceed with next data beat of burst.
                    -- If not, then go to FULL_THROTTLE state to wait for
                    -- AXI_RREADY = '1'.

                    if (rd_adv_buf = '1') then


                        -- Assert AXI read data enable for BRAM capture 
                        axi_rdata_en <= '1';

                        -- Load read data skid buffer for BRAM capture in next clock cycle
                        rd_skid_buf_ld_cmb <= '1';


                        -- Assert almost last BRAM address flag
                        -- so that ARVALID logic output can remain registered
                        --
                        -- Replace usage of brst_cnt with signal, brst_one.
                        if (brst_one = '1') then
                            alast_bram_addr <= '1';                    
                        end if;



                        -- Check burst counter for max
                        -- If max burst count is reached, no new addresses
                        -- presented to BRAM, advance to last capture data states.
                        --
                        -- For timing, replace usage of brst_cnt in this SM.
                        -- Replace with registered signal, brst_zero, indicating the 
                        -- brst_cnt to be zero when decrement.

                        if (brst_zero = '1') or (end_brst_rd = '1' and axi_b2b_brst = '0') then



                            -- Check for elgible pending read operation to support back-to-back performance.
                            -- If so, load BRAM address counter.
                            --                            
                            -- Replace rd_b2b_elgible signal check to remove path from 
                            -- arlen_pipe through rd_b2b_elgible 
                            -- (with data throttle check)
                            
                            if (rd_b2b_elgible_no_thr_check = '1') then


                                rd_data_sm_ns <= FULL_PIPE;

                                -- Set flag to indicate back-to-back read burst
                                -- RVALID will not clear in this case and remain asserted
                                axi_b2b_brst_cmb <= '1';

                                -- Set flag to update active read burst or 
                                -- read burst of two flag
                                act_rd_burst_set <= '1';



                            -- Otherwise, complete current transaction
                            else

                                -- No increment of BRAM address
                                -- or decrement of burst counter
                                -- Burst counter should be = zero
                                bram_addr_inc <= '0';
                                brst_cnt_dec <= '0';

                                rd_data_sm_ns <= LAST_ADDR;

                                -- Negate BRAM enable
                                bram_en_cmb <= '0';

                                -- End of active current read address
                                ar_active_clr <= '1';

                            end if;

                        else

                            -- Remain in this state until burst count reaches zero

                            -- Increment BRAM address counter (Nth data beat)
                            bram_addr_inc <= '1';

                            -- Decrement BRAM burst counter (Nth data beat)
                            brst_cnt_dec <= '1';

                            -- Keep BRAM enable asserted
                            bram_en_cmb <= '1';


                            -- Skid buffer load will remain asserted
                            -- AXI read data register is asserted

                        end if;



                    else

                        -- Throttling condition detected                    
                        rd_data_sm_ns <= FULL_THROTTLE;

                        -- Ensure that AXI read data output register is disabled
                        -- due to throttle condition.
                        axi_rdata_en <= '0';

                        -- Skid buffer gets loaded from BRAM read data in next clock
                        -- cycle ONLY.
                        -- Only on transition to THROTTLE state does skid buffer get loaded.

                        -- Negate load of read data skid buffer for BRAM capture 
                        -- in next clock cycle due to detection of Throttle condition
                        rd_skid_buf_ld_cmb <= '0';


                        -- BRAM address is NOT getting incremented 
                        -- (same for burst counter)
                        bram_addr_inc <= '0';
                        brst_cnt_dec <= '0';


                        -- If transitioning to throttle state
                        -- Then next register enable assertion of the AXI read data
                        -- output register needs to come from the skid buffer
                        -- Set read data mux select here for SKID_BUFFER data
                        rddata_mux_sel_cmb <= C_RDDATA_MUX_SKID_BUF;                    


                        -- Detect if at end of burst read as we transition to FULL_THROTTLE
                        -- If so, negate the BRAM enable even if prior to throttle condition
                        -- on AXI bus.  Read skid buffer will hold last beat of data in burst.
                        --
                        -- For timing purposes, replace usage of brst_cnt in this SM.
                        -- Replace with registered signal, brst_zero, indicating the 
                        -- brst_cnt to be zero when decrement.

                        if (brst_zero = '1') or (end_brst_rd = '1') then


                            -- No back to back "non bubble" support when AXI master 
                            -- is throttling on current burst.
                            -- Seperate signal throttle_last_data will be asserted outside SM.

                            -- End of burst read, negate BRAM enable
                            bram_en_cmb <= '0';


                            -- Assert new flag to disable back-to-back bursts
                            -- due to throttling
                            disable_b2b_brst_cmb <= '1';



                        -- Disable B2B capability if throttling detected when
                        -- burst count is equal to one.
                        --
                        -- For timing purposes, replace usage of brst_cnt in this SM.
                        -- Replace with registered signal, brst_one, indicating the 
                        -- brst_cnt to be one when decrement.

                        elsif (brst_one = '1') then


                            -- Assert new flag to disable back-to-back bursts
                            -- due to throttling
                            disable_b2b_brst_cmb <= '1';


                        -- Throttle, but not end of burst
                        else
                            bram_en_cmb <= '1';

                        end if;


                    end if; -- rd_adv_buf (RREADY throttle)



                ------------------------- FULL_THROTTLE State ---------------------

                when FULL_THROTTLE =>


                    -- Reach this state when the AXI bus throttles on the AXI data
                    -- beat read from BRAM (when the read pipeline is fully active)


                    -- Flag disable_b2b_brst_cmb should be asserted as we transition
                    -- to this state. Flag is asserted near the end of a read burst
                    -- to prevent the back-to-back performance pipelining in the BRAM
                    -- address counter.



                    -- Detect if at end of burst read
                    -- If so, negate the BRAM enable even if prior to throttle condition
                    -- on AXI bus.  Read skid buffer will hold last beat of data in burst.
                    --
                    -- For timing, replace usage of brst_cnt in this SM.
                    -- Replace with registered signal, brst_zero, indicating the 
                    -- brst_cnt to be zero when decrement.
                    
                    if (brst_zero = '1') or (end_brst_rd = '1') then
                        bram_en_cmb <= '0';
                    end if;

                    
                    -- Set new flag for pending operation if bram_addr_ld_en is asserted (BRAM
                    -- address is loaded) and we are waiting for the current read burst to complete.
                    if (bram_addr_ld_en = '1') then
                        pend_rd_op_cmb <= '1';

                    -- Clear flag once pending read is recognized and
                    -- earlier read data phase is complete.

                    elsif (pend_rd_op = '1') and (axi_rlast_int = '1') then
                        pend_rd_op_cmb <= '0';
                    end if;
                    
                    

                    -- Wait for RREADY to be asserted w/ RVALID on AXI bus
                    if (rd_adv_buf = '1') then


                        -- Ensure read data mux is set for skid buffer data
                        rddata_mux_sel_cmb <= C_RDDATA_MUX_SKID_BUF;

                        -- Ensure that AXI read data output register is enabled
                        axi_rdata_en <= '1';


                        -- Must reload skid buffer here from BRAM data
                        -- so if needed can be presented to AXI bus on the following clock cycle
                        rd_skid_buf_ld_imm <= '1';



                        -- When detecting end of throttle condition
                        -- Check first if burst count is complete

                        -- Check burst counter for max
                        -- If max burst count is reached, no new addresses
                        -- presented to BRAM, advance to last capture data states.
                        --
                        -- For timing, replace usage of brst_cnt in this SM.
                        -- Replace with registered signal, brst_zero, indicating the 
                        -- brst_cnt to be zero when decrement.

                        if (brst_zero = '1') or (end_brst_rd = '1') then


                            -- No back-to-back performance when AXI master throttles
                            -- If we reach the end of the burst, proceed to LAST_ADDR state.


                            -- No increment of BRAM address
                            -- or decrement of burst counter
                            -- Burst counter should be = zero
                            bram_addr_inc <= '0';
                            brst_cnt_dec <= '0';

                            rd_data_sm_ns <= LAST_ADDR;

                            -- Negate BRAM enable
                            bram_en_cmb <= '0';

                            -- End of active current read address
                            ar_active_clr <= '1';



                        -- Not end of current burst w/ throttle condition
                        else

                            -- Go back to FULL_PIPE
                            rd_data_sm_ns <= FULL_PIPE;


                            -- Assert almost last BRAM address flag
                            -- so that ARVALID logic output can remain registered
                            --
                            -- For timing purposes, replace usage of brst_cnt in this SM.
                            -- Replace with registered signal, brst_one, indicating the 
                            -- brst_cnt to be one when decrement.
                            if (brst_one = '1') then
                                alast_bram_addr <= '1';                    
                            end if;



                            -- Increment BRAM address counter (Nth data beat)
                            bram_addr_inc <= '1';

                            -- Decrement BRAM burst counter (Nth data beat)
                            brst_cnt_dec <= '1';
                            
                            -- Keep BRAM enable asserted
                            bram_en_cmb <= '1';
                            


                        end if; -- Burst Max                     

                    else

                        -- Stay in this state

                        -- Ensure that AXI read data output register is disabled
                        -- due to throttle condition.
                        axi_rdata_en <= '0';

                        -- Ensure that skid buffer is not getting loaded with
                        -- current read data from BRAM
                        rd_skid_buf_ld_cmb <= '0';

                        -- BRAM address is NOT getting incremented 
                        -- (same for burst counter)
                        bram_addr_inc <= '0';
                        brst_cnt_dec <= '0';


                    end if; -- rd_adv_buf (RREADY throttle)





                ------------------------- LAST_ADDR State -------------------------

                when LAST_ADDR =>


                    -- Reach this state in the clock cycle following the last address 
                    -- presented to the BRAM. Capture the last BRAM data beat in the
                    -- next clock cycle.
                    --
                    -- Data is presented to AXI bus (if no throttling detected) and
                    -- loaded into the skid buffer.


                    -- If we reach this state after back to back burst transfers
                    -- then clear the flag to ensure that RVALID will clear when RLAST
                    -- is recognized
                    if (axi_b2b_brst = '1') then
                        axi_b2b_brst_cmb <= '0';
                    end if;




                    -- Clear flag that indicates end of read burst
                    -- Once we reach this state, we have recognized the burst complete.
                    --
                    -- It is getting asserted too early
                    -- and recognition of the end of the burst is missed when throttling
                    -- on the last two data beats in the read.
                    end_brst_rd_clr_cmb <= '1';


                    -- Set new flag for pending operation if ar_active is asserted (BRAM
                    -- address has already been loaded) and we are waiting for the current
                    -- read burst to complete.  If those two conditions apply, set this flag.

                    -- For dual port, support checking for early writes into BRAM address counter
                    
                    if (C_SINGLE_PORT_BRAM = 0) and ((ar_active = '1' and end_brst_rd = '1') or (bram_addr_ld_en = '1')) then
                    -- Support back-to-backs for single AND dual port modes.
                    
                    -- if ((ar_active = '1' and end_brst_rd = '1') or (bram_addr_ld_en = '1')) then
                    -- if (ar_active = '1' and end_brst_rd = '1') or (bram_addr_ld_en = '1') then
                        pend_rd_op_cmb <= '1';
                    end if;


                    -- Load read data skid buffer for BRAM is asserted on transition
                    -- into this state.  Only gets negated if done with operation
                    -- as detected in below if clause.


                    -- Check flag for no subsequent operations
                    -- Clear that now, with current operation completing
                    if (no_ar_ack = '1') then
                        no_ar_ack_cmb <= '0';
                    end if;


                    -- Check for single AXI read operations
                    -- If so, wait for RREADY to be asserted

                    -- Check for burst and bursts of two as seperate signals.
                    if (act_rd_burst = '0') and (act_rd_burst_two = '0') then


                        -- Create rvalid_set to only be asserted for a single clock
                        -- cycle.
                        -- Will get set as transitioning to LAST_ADDR on single read operations
                        -- Only assert RVALID here on single operations

                        -- Enable AXI read data register
                        axi_rdata_en <= '1';


                        -- Data will not yet be acknowledged on AXI
                        -- in this state.
                       
                        -- Go to wait for last data beat
                        rd_data_sm_ns <= LAST_DATA;

                        -- Set read data mux select for SKID BUF
                        rddata_mux_sel_cmb <= C_RDDATA_MUX_SKID_BUF;



                    else

                        -- Only check throttling on AXI during read data burst operations

                        -- Check AXI throttling condition
                        -- If AXI bus advances and accepts read data, SM can
                        -- proceed with next data beat.
                        -- If not, then go to LAST_THROTTLE state to wait for
                        -- AXI_RREADY = '1'.

                        if (rd_adv_buf = '1') then


                            -- Assert AXI read data enable for BRAM capture 
                            -- in next clock cycle

                            -- Enable AXI read data register
                            axi_rdata_en <= '1';

                            -- Ensure read data mux is set for BRAM data
                            rddata_mux_sel_cmb <= C_RDDATA_MUX_BRAM;



                            -- Burst counter already at zero.  Reached this state due to NO 
                            -- pending ARADDR in the read address pipeline.  However, check
                            -- here for any new read addresses.

                            -- New ARADDR detected and loaded into BRAM address counter

                            -- Add check here for previously loaded BRAM address
                            -- ar_active will be asserted (and qualify that with the
                            -- condition that the read burst is complete, for narrow reads).

                            if (bram_addr_ld_en = '1') then

                                -- Initiate BRAM read transfer
                                bram_en_cmb <= '1';


                                -- Instead of transitioning to SNG_ADDR
                                -- go to wait for last data beat.
                                rd_data_sm_ns <= LAST_DATA_AR_PEND;


                            else

                                -- No pending read address to initiate next read burst
                                -- Go to capture last data beat from BRAM and present on AXI bus.                
                                rd_data_sm_ns <= LAST_DATA;


                            end if; -- bram_addr_ld_en (New read burst)


                        else

                            -- Throttling condition detected                    
                            rd_data_sm_ns <= LAST_THROTTLE;

                            -- Ensure that AXI read data output register is disabled
                            -- due to throttle condition.
                            axi_rdata_en <= '0';                        


                            -- Skid buffer gets loaded from BRAM read data in next clock
                            -- cycle ONLY.
                            -- Only on transition to THROTTLE state does skid buffer get loaded.

                            -- Set read data mux select for SKID BUF
                            rddata_mux_sel_cmb <= C_RDDATA_MUX_SKID_BUF;


                        end if; -- rd_adv_buf (RREADY throttle)

                    end if; -- AXI read burst



                ------------------------- LAST_THROTTLE State ---------------------

                when LAST_THROTTLE =>


                    -- Reach this state when the AXI bus throttles on the last data
                    -- beat read from BRAM
                    -- Data to be sourced from read skid buffer


                    -- Add check in LAST_THROTTLE as well as LAST_ADDR
                    -- as we may miss the setting of this flag for a subsequent operation.
                    
                    -- For dual port, support checking for early writes into BRAM address counter
                    if (C_SINGLE_PORT_BRAM = 0) and ((ar_active = '1' and end_brst_rd = '1') or (bram_addr_ld_en = '1')) then
                    
                    -- Support back-to-back for single AND dual port modes.
                    -- if ((ar_active = '1' and end_brst_rd = '1') or (bram_addr_ld_en = '1')) then
                        pend_rd_op_cmb <= '1';
                    end if;



                    -- Wait for RREADY to be asserted w/ RVALID on AXI bus
                    if (rd_adv_buf = '1') then


                        -- Assert AXI read data enable for BRAM capture 
                        axi_rdata_en <= '1';

                        -- Set read data mux select for SKID BUF
                        rddata_mux_sel_cmb <= C_RDDATA_MUX_SKID_BUF;

                        -- No pending read address to initiate next read burst
                        -- Go to capture last data beat from BRAM and present on AXI bus.                
                        rd_data_sm_ns <= LAST_DATA;

                        -- Load read data skid buffer for BRAM capture in next clock cycle 
                        -- of last data read

                        -- Read Skid buffer already loaded with last data beat from BRAM
                        -- Does not need to be asserted again in this state


                    else

                        -- Stay in this state
                        -- Ensure that AXI read data output register is disabled
                        axi_rdata_en <= '0';

                        -- Ensure that skid buffer is not getting loaded with
                        -- current read data from BRAM
                        rd_skid_buf_ld_cmb <= '0';

                        -- BRAM address is NOT getting incremented 
                        -- (same for burst counter)
                        bram_addr_inc <= '0';
                        brst_cnt_dec <= '0';


                        -- Keep RVALID asserted on AXI
                        -- No need to assert RVALID again


                    end if; -- rd_adv_buf (RREADY throttle)




                ------------------------- LAST_DATA State -------------------------

                when LAST_DATA =>


                    -- Reach this state when last BRAM data beat is
                    -- presented on AXI bus.

                    -- For a read burst, RLAST is not asserted until SM reaches
                    -- this state.


                    -- Ok to accept new operation if throttling detected
                    -- during current operation (and flag was previously set
                    -- to disable the back-to-back performance).
                    disable_b2b_brst_cmb <= '0';



                    -- Stay in this state until RREADY is asserted on AXI bus
                    -- Indicated by assertion of rd_adv_buf
                    if (rd_adv_buf = '1') then


                        -- Last data beat acknowledged on AXI bus                    
                        -- Check for new read burst or proceed back to IDLE
                        -- New ARADDR detected and loaded into BRAM address counter

                        -- Note: this condition may occur when C_SINGLE_PORT_BRAM = 0 or 1

                        if (bram_addr_ld_en = '1') or (pend_rd_op = '1') then

                            -- Clear flag once pending read is recognized
                            if (pend_rd_op = '1') then
                                pend_rd_op_cmb <= '0';
                            end if;

                            -- Initiate BRAM read transfer
                            bram_en_cmb <= '1';

                            -- Only count addresses & burst length for read
                            -- burst operations


                            -- Go to SNG_ADDR state
                            rd_data_sm_ns <= SNG_ADDR;


                            -- If current operation was a burst, clear the active
                            -- burst flag
                            if (act_rd_burst = '1') or (act_rd_burst_two = '1') then
                                act_rd_burst_clr <= '1';
                            end if;


                            -- If we are loading the BRAM, then we have to view the curr_arlen
                            -- signal to determine if the next operation is a single transfer.
                            -- Or if the BRAM address counter is already loaded (and we reach
                            -- this if clause due to pend_rd_op then the axi_* signals will indicate
                            -- if the next operation is a burst or not.
                            -- If the operation is a single transaction, then set the last_bram_addr
                            -- signal when we reach SNG_ADDR.

                            if (bram_addr_ld_en = '1') then

                                if (curr_arlen = AXI_ARLEN_ONE) then

                                    -- Set flag for last_bram_addr on transition
                                    -- to SNG_ADDR on single operations.
                                    set_last_bram_addr <= '1';

                                end if;

                            elsif (pend_rd_op = '1') then

                                if (axi_rd_burst = '0' and axi_rd_burst_two = '0') then                            
                                    set_last_bram_addr <= '1';
                                end if;

                            end if;



                        else

                            -- No pending read address to initiate next read burst.
                            -- Go to IDLE                
                            rd_data_sm_ns <= IDLE;

                            -- If current operation was a burst, clear the active
                            -- burst flag
                            if (act_rd_burst = '1') or (act_rd_burst_two = '1') then
                                act_rd_burst_clr <= '1';
                            end if;

                        end if;

                    else


                        -- Throttling condition detected                    

                        -- Ensure that AXI read data output register is disabled
                        -- due to throttle condition.
                        axi_rdata_en <= '0';



                        -- If new ARADDR detected and loaded into BRAM address counter
                        if (bram_addr_ld_en = '1') then

                            -- Initiate BRAM read transfer
                            bram_en_cmb <= '1';

                            -- Only count addresses & burst length for read
                            -- burst operations


                            -- Instead of transitioning to SNG_ADDR
                            -- to wait for last data beat.
                            rd_data_sm_ns <= LAST_DATA_AR_PEND;


                            -- For singles, block any subsequent loads into BRAM address
                            -- counter from AR SM
                            no_ar_ack_cmb <= '1';


                        end if;


                    end if; -- rd_adv_buf (RREADY throttle)



                ------------------------ LAST_DATA_AR_PEND --------------------

                when LAST_DATA_AR_PEND => 


                    -- Ok to accept new operation if throttling detected
                    -- during current operation (and flag was previously set
                    -- to disable the back-to-back performance).
                    disable_b2b_brst_cmb <= '0';


                    -- Reach this state when new BRAM address is loaded into
                    -- BRAM address counter
                    -- But waiting for last RREADY/RVALID/RLAST to be asserted
                    -- Once this occurs, continue with pending AR operation

                    if (rd_adv_buf = '1') then

                        -- Go to SNG_ADDR state
                        rd_data_sm_ns <= SNG_ADDR;


                        -- If current operation was a burst, clear the active
                        -- burst flag

                        if (act_rd_burst = '1') or (act_rd_burst_two = '1') then
                            act_rd_burst_clr <= '1';
                        end if;


                        -- In this state, the BRAM address counter is already loaded,
                        -- the axi_rd_burst and axi_rd_burst_two signals will indicate
                        -- if the next operation is a burst or not.
                        -- If the operation is a single transaction, then set the last_bram_addr
                        -- signal when we reach SNG_ADDR.

                        if (axi_rd_burst = '0' and axi_rd_burst_two = '0') then                            
                            set_last_bram_addr <= '1';
                        end if;


                        -- Code coverage tests are reporting that reaching this state
                        -- always when axi_rd_burst = '0' and axi_rd_burst_two = '0',
                        -- so no bursting operations.


                    end if;


        --coverage off
                ------------------------------ Default ----------------------------
                when others =>
                    rd_data_sm_ns <= IDLE;
        --coverage on

        end case;

    end process RD_DATA_SM_CMB_PROCESS;
    

    ---------------------------------------------------------------------------

    RD_DATA_SM_REG_PROCESS: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                rd_data_sm_cs <= IDLE;
                bram_en_int <= '0';

                rd_skid_buf_ld_reg <= '0';
                rddata_mux_sel <= C_RDDATA_MUX_BRAM;

                axi_rvalid_set <= '0';
                end_brst_rd_clr <= '0';
                no_ar_ack <= '0';
                pend_rd_op <= '0';

                axi_b2b_brst <= '0';                            
                disable_b2b_brst <= '0';   
                
            else
                rd_data_sm_cs <= rd_data_sm_ns;
                bram_en_int <= bram_en_cmb;

                rd_skid_buf_ld_reg <= rd_skid_buf_ld_cmb;
                rddata_mux_sel <= rddata_mux_sel_cmb;

                axi_rvalid_set <= axi_rvalid_set_cmb;
                end_brst_rd_clr <= end_brst_rd_clr_cmb;
                no_ar_ack <= no_ar_ack_cmb;
                pend_rd_op <= pend_rd_op_cmb;

                axi_b2b_brst <= axi_b2b_brst_cmb;
                disable_b2b_brst <= disable_b2b_brst_cmb;

            end if;
        end if;

    end process RD_DATA_SM_REG_PROCESS;


    ---------------------------------------------------------------------------





    ---------------------------------------------------------------------------


    -- Create seperate registered process for last_bram_addr signal.
    -- Only asserted for a single clock cycle
    -- Gets set when the burst counter is loaded with 0's (for a single data beat operation)
    -- (indicated by set_last_bram_addr from DATA SM)
    -- or when the burst counter is decrement and the current value = 1


    REG_LAST_BRAM_ADDR: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                last_bram_addr <= '0';

            -- The signal, set_last_bram_addr, is asserted when the DATA SM transitions to SNG_ADDR
            -- on a single data beat burst.  Can not use condition of loading burst counter
            -- with the value of 0's (as the burst counter may be loaded during prior single operation
            -- when waiting on last throttle/data beat, ie. rd_adv_buf not yet asserted).

            elsif (set_last_bram_addr = '1') or 

                   -- On burst operations at the last BRAM address presented to BRAM
                  (brst_cnt_dec = '1' and brst_cnt = C_BRST_CNT_ONE) then                  
                last_bram_addr <= '1';
            else
                last_bram_addr <= '0';
            end if;
        end if;

    end process REG_LAST_BRAM_ADDR;


    ---------------------------------------------------------------------------






    ---------------------------------------------------------------------------
    --
    -- *** AXI Read Data Channel Interface ***
    --
    ---------------------------------------------------------------------------

    rd_skid_buf_ld <= rd_skid_buf_ld_reg or rd_skid_buf_ld_imm;


    ---------------------------------------------------------------------------
    -- Generate:        GEN_RDATA_NO_ECC
    -- Purpose:         Generation of AXI_RDATA output register without ECC
    --                  logic (C_ECC = 0 parameterization in design)
    ---------------------------------------------------------------------------
 
    GEN_RDATA_NO_ECC: if C_ECC = 0 generate
    signal axi_rdata_int    : std_logic_vector (C_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    begin

        ---------------------------------------------------------------------------
        -- AXI RdData Skid Buffer/Register
        -- Sized according to size of AXI/BRAM data width
        ---------------------------------------------------------------------------
        
        REG_RD_BUF: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    rd_skid_buf <= (others => '0');

                -- Add immediate load of read skid buffer
                -- Occurs in the case when at full throttle and RREADY/RVALID are asserted
                elsif (rd_skid_buf_ld = '1') then
                    rd_skid_buf <= BRAM_RdData (C_AXI_DATA_WIDTH-1 downto 0);
                else
                    rd_skid_buf <= rd_skid_buf;
                end if;
            end if;

        end process REG_RD_BUF;


        -- Rd Data Mux (selects between skid buffer and BRAM read data)
        -- Select control signal from SM determines register load value
        axi_rdata_mux <= BRAM_RdData (C_AXI_DATA_WIDTH-1 downto 0) when (rddata_mux_sel = C_RDDATA_MUX_BRAM) else
                         rd_skid_buf;


        ---------------------------------------------------------------------------
        -- Generate:        GEN_RDATA
        -- Purpose:         Generate each bit of AXI_RDATA.
        ---------------------------------------------------------------------------
        GEN_RDATA: for i in C_AXI_DATA_WIDTH-1 downto 0 generate
        begin

            REG_RDATA: process (S_AXI_AClk)
            begin

                if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                    -- Clear output after last data beat accepted by requesting AXI master
                    if (S_AXI_AResetn = C_RESET_ACTIVE) or 

                    -- Don't clear RDDATA when a back to back burst is occuring on RLAST & RVALID assertion
                    -- For improved code coverage, can remove the signal, axi_rvalid_int from this if clause.  
                    -- It will always be asserted in this case.
                    
                       (axi_rlast_int = '1' and AXI_RREADY = '1' and axi_b2b_brst = '0') then
                        axi_rdata_int (i) <= '0';

                    elsif (axi_rdata_en = '1') then
                        axi_rdata_int (i) <= axi_rdata_mux (i);

                    else
                        axi_rdata_int (i) <= axi_rdata_int (i);
                    end if;
                end if;

            end process REG_RDATA;


        end generate GEN_RDATA;
        
              
        -- If C_ECC = 0, direct output assignment to AXI_RDATA
        AXI_RDATA <= axi_rdata_int;



    end generate GEN_RDATA_NO_ECC;

    ---------------------------------------------------------------------------




    ---------------------------------------------------------------------------
    -- Generate:        GEN_RDATA_ECC
    -- Purpose:         Generation of AXI_RDATA output register when ECC
    --                  logic is enabled (C_ECC = 1 parameterization in design)
    ---------------------------------------------------------------------------
 
    GEN_RDATA_ECC: if C_ECC = 1 generate
       
    subtype syndrome_bits is std_logic_vector(0 to C_INT_ECC_WIDTH-1);
    -- 0:6 for 32-bit ECC
    -- 0:7 for 64-bit ECC

    type correct_data_table_type is array (natural range 0 to C_AXI_DATA_WIDTH-1) of syndrome_bits;
   
    signal rd_skid_buf_i        : std_logic_vector (C_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal axi_rdata_int        : std_logic_vector (C_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal axi_rdata_int_corr   : std_logic_vector (C_AXI_DATA_WIDTH-1 downto 0) := (others => '0'); 

    begin



        -- Remove GEN_RD_BUF that was doing bit reversal.
        -- Replace with direct register assignments.  Sized according to AXI data width.
        
        REG_RD_BUF: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    rd_skid_buf_i <= (others => '0');

                -- Add immediate load of read skid buffer
                -- Occurs in the case when at full throttle and RREADY/RVALID are asserted
                elsif (rd_skid_buf_ld = '1') then
                    rd_skid_buf_i (C_AXI_DATA_WIDTH-1 downto 0) <= UnCorrectedRdData (0 to C_AXI_DATA_WIDTH-1);
                else
                    rd_skid_buf_i <= rd_skid_buf_i;
                end if;
            end if;

        end process REG_RD_BUF;



        -- Rd Data Mux (selects between skid buffer and BRAM read data)
        -- Select control signal from SM determines register load value
        -- axi_rdata_mux holds data + ECC bits.
        -- Previous mux on input to checkbit_handler logic.
        -- Removed now (mux inserted after checkbit_handler logic before register stage)
        --
        -- axi_rdata_mux <= BRAM_RdData (C_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0) when (rddata_mux_sel = C_RDDATA_MUX_BRAM) else
        --                  rd_skid_buf_i;


        -- Remove GEN_RDATA that was doing bit reversal.

        REG_RDATA: process (S_AXI_AClk)
        begin
            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
                if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                   (axi_rlast_int = '1' and AXI_RREADY = '1' and axi_b2b_brst = '0') then
                    axi_rdata_int <= (others => '0');

                elsif (axi_rdata_en = '1') then
                
                    -- Track uncorrected data vector with AXI RDATA output pipeline                   
                    -- Mimic mux logic here (from previous post checkbit XOR logic register)
                    if (rddata_mux_sel = C_RDDATA_MUX_BRAM) then
                        axi_rdata_int (C_AXI_DATA_WIDTH-1 downto 0) <= UnCorrectedRdData (0 to C_AXI_DATA_WIDTH-1);
                    else
                        axi_rdata_int <= rd_skid_buf_i;
                    end if; 
               
                else
                    axi_rdata_int <= axi_rdata_int;
                end if;
            end if;
        end process REG_RDATA;
                  
        
        -- When C_ECC = 1, correct any single bit errors on output read data.
        -- Post register stage to improve timing on ECC logic data path.
        -- Use registers in AXI Interconnect IP core.
        -- Perform bit swapping on output of correct_one_bit 
        -- module (axi_rdata_int_corr signal).
        -- AXI_RDATA (i) <= axi_rdata_int (i) when (Enable_ECC = '0') 
        --                                 else axi_rdata_int_corr (C_AXI_DATA_WIDTH-1-i);

        
        -- Found in HW debug
        -- axi_rdata_int is reversed to be returned on AXI bus.
        -- AXI_RDATA (i) <= axi_rdata_int (C_AXI_DATA_WIDTH-1-i) when (Enable_ECC = '0') 
        --                                 else axi_rdata_int_corr (C_AXI_DATA_WIDTH-1-i);


        -- Remove bit reversal on AXI_RDATA output.
        AXI_RDATA <= axi_rdata_int when (Enable_ECC = '0' or Sl_UE_i = '1') else axi_rdata_int_corr;




        -- v1.03a
        
        ------------------------------------------------------------------------
        -- Generate:     GEN_HAMMING_ECC_CORR
        --
        -- Purpose:      Determine type of ECC encoding.  Hsiao or Hamming.  
        --               Add parameter/generate level.
        --               Generate statements to correct BRAM read data 
        --               dependent on ECC type.
        ------------------------------------------------------------------------
        GEN_HAMMING_ECC_CORR: if C_ECC_TYPE = 0 generate
        begin


            ------------------------------------------------------------------------
            -- Generate:  CHK_ECC_32
            -- Purpose:   Check ECC data unique for 32-bit BRAM.
            ------------------------------------------------------------------------
            CHK_ECC_32: if C_AXI_DATA_WIDTH = 32 generate

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

            signal syndrome_4_reg : std_logic_vector (0 to 1) := (others => '0');           -- Only used in 32-bit ECC
            signal syndrome_6_reg : std_logic_vector (0 to 5)  := (others => '0');            -- Specific for 32-bit ECC

            begin
                ---------------------------------------------------------------------------

                -- Register ECC syndrome value to correct any single bit errors
                -- post-register on AXI read data.

                REG_SYNDROME: process (S_AXI_AClk)
                begin        
                    if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then  

                        if (S_AXI_AResetn = C_RESET_ACTIVE) then
                            syndrome_reg <= (others => '0');
                            syndrome_4_reg <= (others => '0');
                            syndrome_6_reg <= (others => '0');

                        -- Align register stage of syndrome with AXI read data pipeline
                        elsif (axi_rdata_en = '1') then
                            syndrome_reg <= Syndrome; 
                            syndrome_4_reg <= Syndrome_4;
                            syndrome_6_reg <= Syndrome_6;
                        else
                            syndrome_reg <= syndrome_reg;
                            syndrome_4_reg <= syndrome_4_reg;
                            syndrome_6_reg <= syndrome_6_reg;
                        end if;
                    end if;

                end process REG_SYNDROME;


                ---------------------------------------------------------------------------

                -- Do last XOR on specific syndrome bits after pipeline stage before 
                -- correct_one_bit module.

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

                    -----------------------------------------------------------------------
                    -- Instance:        CORR_ONE_BIT_32
                    -- Description:     Correct output read data based on syndrome vector.
                    --                  A single error can be corrected by decoding the
                    --                  syndrome value.
                    --                  Input signal is declared (N:0).
                    --                  Output signal is (N:0).
                    --                  In order to reuse correct_one_bit module,
                    --                  the single data bit correction is done LSB to MSB
                    --                  in generate statement loop.
                    -----------------------------------------------------------------------

                    CORR_ONE_BIT_32: entity work.correct_one_bit
                    generic map (
                        C_USE_LUT6    => C_USE_LUT6,
						Correct_Value => correct_data_table_32 (i))   
                    port map (
					    DIn           => axi_rdata_int (31-i),   -- This is to match with LMB Controller Hamming Encoder logic (Bit Reversal)
                        Syndrome      => syndrome_reg_i,
                        DCorr         => axi_rdata_int_corr (31-i));  -- This is to match with LMB Controller Hamming Encoder logic (Bit Reversal)

                end generate GEN_CORR_32;


            end generate CHK_ECC_32;


            ------------------------------------------------------------------------
            -- Generate:  CHK_ECC_64
            -- Purpose:   Check ECC data unique for 64-bit BRAM.
            ------------------------------------------------------------------------
            CHK_ECC_64: if C_AXI_DATA_WIDTH = 64 generate

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

            signal syndrome_7_reg       : std_logic_vector (0 to 11) := (others => '0');           -- Specific for 64-bit ECC
            signal syndrome_7_a         : std_logic;
            signal syndrome_7_b         : std_logic;
            begin


                ---------------------------------------------------------------------------

                -- Register ECC syndrome value to correct any single bit errors
                -- post-register on AXI read data.

                REG_SYNDROME: process (S_AXI_AClk)
                begin        
                    if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then  

                        -- Align register stage of syndrome with AXI read data pipeline
                        if (axi_rdata_en = '1') then
                            syndrome_reg <= Syndrome; 
                            syndrome_7_reg <= Syndrome_7;

                        else
                            syndrome_reg <= syndrome_reg;
                            syndrome_7_reg <= syndrome_7_reg;
                        end if;
                    end if;

                end process REG_SYNDROME;


                ---------------------------------------------------------------------------

                -- Do last XOR on select syndrome bits after pipeline stage 
                -- before correct_one_bit_64 module.

                PARITY_CHK7_A: entity work.parity
                generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
                port map (
                  InA   =>  syndrome_7_reg (0 to 5),                 -- [in  std_logic_vector(0 to C_SIZE - 1)]
                  Res   =>  syndrome_7_a );                          -- [out std_logic]

                PARITY_CHK7_B: entity work.parity
                generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
                port map (
                  InA   =>  syndrome_7_reg (6 to 11),                -- [in  std_logic_vector(0 to C_SIZE - 1)]
                  Res   =>  syndrome_7_b );                          -- [out std_logic]


                -- Do last XOR on Syndrome MSB after pipeline stage before correct_one_bit module
                -- PASSES:      syndrome_reg_i (7) <= syndrome_reg (7) xor syndrome_7_b_reg;    
                syndrome_reg_i (7) <= syndrome_7_a xor syndrome_7_b;    
                syndrome_reg_i (0 to 6) <= syndrome_reg (0 to 6);


                ---------------------------------------------------------------------------
                -- Generate: GEN_CORR_64
                -- Purpose:  Generate corrected read data based on syndrome value.
                --           All vectors oriented (0:N)
                ---------------------------------------------------------------------------
                GEN_CORR_64: for i in 0 to C_AXI_DATA_WIDTH-1 generate
                begin

                    -----------------------------------------------------------------------
                    -- Instance:        CORR_ONE_BIT_64
                    -- Description:     Correct output read data based on syndrome vector.
                    --                  A single error can be corrected by decoding the
                    --                  syndrome value.
                    -----------------------------------------------------------------------

                    CORR_ONE_BIT_64: entity work.correct_one_bit_64
                    generic map (
                        C_USE_LUT6    => C_USE_LUT6,
                        Correct_Value => correct_data_table_64 (i))
                    port map (
                        DIn           => axi_rdata_int (i),
                        Syndrome      => syndrome_reg_i,
                        DCorr         => axi_rdata_int_corr (i));

                end generate GEN_CORR_64;

            end generate CHK_ECC_64;


        end generate GEN_HAMMING_ECC_CORR;




        -- v1.03a
        
        ------------------------------------------------------------------------
        -- Generate:     GEN_HSIAO_ECC_CORR
        --
        -- Purpose:      Determine type of ECC encoding.  Hsiao or Hamming.  
        --               Add parameter/generate level.
        --               Derived from MIG v3.7 Hsiao HDL.
        --               Generate statements to correct BRAM read data 
        --               dependent on ECC type.
        ------------------------------------------------------------------------
        GEN_HSIAO_ECC_CORR: if C_ECC_TYPE = 1 generate

        type type_int0 is array (C_AXI_DATA_WIDTH - 1 downto 0) of std_logic_vector (ECC_WIDTH - 1 downto 0);

        signal h_matrix     : type_int0;
        signal flip_bits    : std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0);
        signal ecc_rddata_r : std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0);

        begin


            -- Reconstruct H-matrix
            H_COL: for n in 0 to C_AXI_DATA_WIDTH - 1 generate
            begin
                H_BIT: for p in 0 to  ECC_WIDTH - 1 generate
                begin
                    h_matrix (n)(p) <=  h_rows (p * CODE_WIDTH + n);
                end generate H_BIT;
            end generate H_COL;
 
            
            -- Based on syndrome value, determine bits to flip in BRAM read data.
            GEN_FLIP_BIT: for r in 0 to C_AXI_DATA_WIDTH - 1 generate
            begin
               flip_bits (r) <= BOOLEAN_TO_STD_LOGIC (h_matrix (r) = syndrome_r);
            end generate GEN_FLIP_BIT;

            ecc_rddata_r <= axi_rdata_int;            

            axi_rdata_int_corr (C_AXI_DATA_WIDTH-1 downto 0) <= -- UnCorrectedRdData (0 to C_AXI_DATA_WIDTH-1) xor
                                                                ecc_rddata_r (C_AXI_DATA_WIDTH-1 downto 0) xor
                                                                flip_bits (C_AXI_DATA_WIDTH-1 downto 0);

       
       
        end generate GEN_HSIAO_ECC_CORR;



    end generate GEN_RDATA_ECC;
    
    
    ---------------------------------------------------------------------------
    
    



    ---------------------------------------------------------------------------
    -- Generate:    GEN_RID_SNG
    -- Purpose:     Generate RID output pipeline when the core is configured
    --              in a single port mode.
    ---------------------------------------------------------------------------
    
    GEN_RID_SNG: if (C_SINGLE_PORT_BRAM = 1) generate
    begin
    
        REG_RID_TEMP: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    axi_rid_temp <= (others => '0');

                elsif (bram_addr_ld_en = '1') then            
                    axi_rid_temp <= AXI_ARID;
                else
                    axi_rid_temp <= axi_rid_temp;
                end if;
            end if;
        end process REG_RID_TEMP;


        REG_RID: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                   (axi_rlast_int = '1' and AXI_RREADY = '1') then
                    axi_rid_int <= (others => '0');

                elsif (bram_addr_ld_en = '1') then            
                    axi_rid_int <= AXI_ARID;

                elsif (axi_rvalid_set = '1') or (axi_b2b_rid_adv = '1') then    
                    axi_rid_int <= axi_rid_temp;
                else
                    axi_rid_int <= axi_rid_int;            
                end if;

            end if;
        end process REG_RID;
        
        
        -- Advance RID pipeline values
        axi_b2b_rid_adv <= '1' when (axi_rlast_int = '1' and 
                                     AXI_RREADY = '1' and 
                                     axi_b2b_brst = '1') 
                                else '0'; 


    end generate GEN_RID_SNG;



    ---------------------------------------------------------------------------
    -- Generate:    GEN_RID
    -- Purpose:     Generate RID in dual port mode (with read address pipeline).
    ---------------------------------------------------------------------------
    
    GEN_RID: if (C_SINGLE_PORT_BRAM = 0) generate
    begin
    

        ---------------------------------------------------------------------------
        -- RID Output Register
        --
        -- Output RID value either comes from pipelined value or directly wrapped
        -- ARID value.  Determined by address pipeline usage.
        ---------------------------------------------------------------------------

        -- Create intermediate temporary RID output register
        REG_RID_TEMP: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    axi_rid_temp <= (others => '0');

                -- When BRAM address counter gets loaded
                -- Set output RID value based on address source
                elsif (bram_addr_ld_en = '1') and (axi_rid_temp_full = '0') then            

                    -- If BRAM address counter gets loaded directly from 
                    -- AXI bus, then save ARID value for wrapping to RID
                    if (araddr_pipe_sel = '0') then
                        axi_rid_temp <= AXI_ARID;

                    else
                        -- Use pipelined AWID value
                        axi_rid_temp <= axi_arid_pipe;
                    end if;

                -- Add condition to check for temp utilized (temp_full now = '0'), but a 
                -- pending RID is stored in temp2.  Must advance the pipeline.

                elsif ((axi_rvalid_set = '1' or axi_b2b_rid_adv = '1') and (axi_rid_temp2_full = '1')) or
                      (axi_rid_temp_full_fe = '1' and axi_rid_temp2_full = '1') then

                    axi_rid_temp <= axi_rid_temp2;
                else
                    axi_rid_temp <= axi_rid_temp;
                end if;
            end if;
        end process REG_RID_TEMP;




        -- Create flag that indicates if axi_rid_temp is full
        REG_RID_TEMP_FULL: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
                if (S_AXI_AResetn = C_RESET_ACTIVE) or 

                   (axi_rid_temp_full = '1' and 
                    (axi_rvalid_set = '1' or axi_b2b_rid_adv = '1') and 
                    axi_rid_temp2_full = '0') then

                    axi_rid_temp_full <= '0';

                elsif (bram_addr_ld_en = '1') or 

                      ((axi_rvalid_set = '1' or axi_b2b_rid_adv = '1') and (axi_rid_temp2_full = '1')) or     
                      (axi_rid_temp_full_fe = '1' and axi_rid_temp2_full = '1') then

                    axi_rid_temp_full <= '1';

                else
                    axi_rid_temp_full <= axi_rid_temp_full;

                end if;
            end if;
        end process REG_RID_TEMP_FULL;


        -- Create flag to detect falling edge of axi_rid_temp_full flag
        REG_RID_TEMP_FULL_D1: process (S_AXI_AClk)
        begin
            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    axi_rid_temp_full_d1 <= '0';
                else
                    axi_rid_temp_full_d1 <= axi_rid_temp_full;    
                end if;
            end if;
        end process REG_RID_TEMP_FULL_D1;


        axi_rid_temp_full_fe <= '1' when (axi_rid_temp_full = '0' and 
                                          axi_rid_temp_full_d1 = '1') else '0';


        ---------------------------------------------------------------------------


        -- Create intermediate temporary RID output register
        REG_RID_TEMP2: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    axi_rid_temp2 <= (others => '0');

                -- When BRAM address counter gets loaded
                -- Set output RID value based on address source
                elsif (bram_addr_ld_en = '1') and (axi_rid_temp_full = '1') then            

                    -- If BRAM address counter gets loaded directly from 
                    -- AXI bus, then save ARID value for wrapping to RID
                    if (araddr_pipe_sel = '0') then
                        axi_rid_temp2 <= AXI_ARID;
                    else
                        -- Use pipelined AWID value
                        axi_rid_temp2 <= axi_arid_pipe;
                    end if;
                else
                    axi_rid_temp2 <= axi_rid_temp2;

                end if;
            end if;
        end process REG_RID_TEMP2;


        -- Create flag that indicates if axi_rid_temp2 is full
        REG_RID_TEMP2_FULL: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                   (axi_rid_temp2_full = '1' and (axi_rvalid_set = '1' or axi_b2b_rid_adv = '1')) or 
                   (axi_rid_temp_full_fe = '1' and axi_rid_temp2_full = '1') then

                    axi_rid_temp2_full <= '0';

                elsif (bram_addr_ld_en = '1') and (axi_rid_temp_full = '1') then            
                    axi_rid_temp2_full <= '1';
                else
                    axi_rid_temp2_full <= axi_rid_temp2_full;
                end if;
            end if;
        end process REG_RID_TEMP2_FULL;


        ---------------------------------------------------------------------------


        -- Output RID register is enabeld when RVALID is asserted on the AXI bus
        -- Clear RID when AXI_RLAST is asserted on AXI bus during handshaking sequence
        -- and recognized by AXI requesting master.

        REG_RID: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) or 

                   -- For improved code coverage, can remove the signal, axi_rvalid_int from statement.
                   (axi_rlast_int = '1' and AXI_RREADY = '1' and axi_b2b_brst = '0') then
                    axi_rid_int <= (others => '0');

                -- Add back to back case to advance RID
                elsif (axi_rvalid_set = '1') or (axi_b2b_rid_adv = '1') then  
                    axi_rid_int <= axi_rid_temp;
                else
                    axi_rid_int <= axi_rid_int;            
                end if;

            end if;
        end process REG_RID;

        -- Advance RID pipeline values
        axi_b2b_rid_adv <= '1' when (axi_rlast_int = '1' and 
                                     AXI_RREADY = '1' and 
                                     axi_b2b_brst = '1') 
                                else '0'; 

    end generate GEN_RID;
    


    ---------------------------------------------------------------------------
    -- Generate:    GEN_RRESP
    -- Purpose:     Create register output unique when ECC is disabled.
    --              Only possible output value = OKAY response.
    ---------------------------------------------------------------------------
    GEN_RRESP: if C_ECC = 0 generate
    begin

        -----------------------------------------------------------------------
        -- AXI_RRESP Output Register
        --
        -- Set when RVALID is asserted on AXI bus.
        -- Clear when AXI_RLAST is asserted on AXI bus during handshaking 
        -- sequence and recognized by AXI requesting master.
        -----------------------------------------------------------------------
        REG_RRESP: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) or 

                   -- For improved code coverage, remove signal, axi_rvalid_int, it will always be asserted.
                   (axi_rlast_int = '1' and AXI_RREADY = '1') then
                    axi_rresp_int <= (others => '0');

                elsif (axi_rvalid_set = '1') then
                    -- AXI BRAM only supports OK response for normal operations
                    -- Exclusive operations not yet supported              
                    axi_rresp_int <= RESP_OKAY;
                else
                    axi_rresp_int <= axi_rresp_int;

                end if;

            end if;

        end process REG_RRESP;

    end generate GEN_RRESP;



    ---------------------------------------------------------------------------
    -- Generate:    GEN_RRESP_ECC
    -- Purpose:     Create register output unique when ECC is disabled.
    --              Only possible output value = OKAY response.
    ---------------------------------------------------------------------------
    GEN_RRESP_ECC: if C_ECC = 1 generate
    begin

        -----------------------------------------------------------------------
        -- AXI_RRESP Output Register
        --
        -- Set when RVALID is asserted on AXI bus.
        -- Clear when AXI_RLAST is asserted on AXI bus during handshaking 
        -- sequence and recognized by AXI requesting master.
        -----------------------------------------------------------------------
        REG_RRESP: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) or 

                   -- For improved code coverage, remove signal, axi_rvalid_int, it will always be asserted.
                   (axi_rlast_int = '1' and AXI_RREADY = '1') then
                    axi_rresp_int <= (others => '0');

                elsif (axi_rvalid_set = '1') then
                    -- AXI BRAM only supports OK response for normal operations
                    -- Exclusive operations not yet supported  
                    
                    -- For ECC implementation
                    -- Check that an uncorrectable error has not occured.
                    -- If so, then respond with RESP_SLVERR on AXI.
                    -- Ok to use combinatorial signal here.  The Sl_UE_i
                    -- flag is generated based on the registered syndrome value.
                    -- if (Sl_UE_i = '1') then
                    --     axi_rresp_int <= RESP_SLVERR;
                    -- else
                        axi_rresp_int <= RESP_OKAY;
                    -- end if;
                    
                else
                    axi_rresp_int <= axi_rresp_int;

                end if;

            end if;

        end process REG_RRESP;

    end generate GEN_RRESP_ECC;





    ---------------------------------------------------------------------------
    -- AXI_RVALID Output Register
    --
    -- Set AXI_RVALID when read data SM indicates.
    -- Clear when AXI_RLAST is asserted on AXI bus during handshaking sequence
    -- and recognized by AXI requesting master.
    ---------------------------------------------------------------------------

    REG_RVALID: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) or 


                -- Clear AXI_RVALID at the end of tranfer when able to clear
                -- (axi_rlast_int = '1' and axi_rvalid_int = '1' and AXI_RREADY = '1' and 
                -- For improved code coverage, remove signal axi_rvalid_int.
                (axi_rlast_int = '1' and AXI_RREADY = '1' and 

                -- Added axi_rvalid_clr_ok to check if during a back-to-back burst
                -- and the back-to-back is elgible for streaming performance
                axi_rvalid_clr_ok = '1') then
               
                axi_rvalid_int <= '0';
                
            elsif (axi_rvalid_set = '1') then
                axi_rvalid_int <= '1';
            else
                axi_rvalid_int <= axi_rvalid_int;
            
            end if;

        end if;

    end process REG_RVALID;



    -- Create flag that gets set when we load BRAM address early in a B2B scenario
    -- This will prevent the RVALID from getting cleared at the end of the current burst
    -- Otherwise, the RVALID gets cleared after RLAST/RREADY dual assertion
    

    REG_RVALID_CLR: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                axi_rvalid_clr_ok <= '0';

            -- When the new address loaded into the BRAM counter is for a back-to-back operation
            -- Do not clear the RVALID
            elsif (rd_b2b_elgible = '1' and bram_addr_ld_en = '1') then
                axi_rvalid_clr_ok <= '0';
            
            -- Else when we start a new transaction (that is not back-to-back)
            -- Then enable the RVALID to get cleared upon RLAST/RREADY

            elsif (bram_addr_ld_en = '1') or 

                  (axi_rvalid_clr_ok = '0' and 
                   (disable_b2b_brst = '1' or disable_b2b_brst_cmb = '1') and 
                   last_bram_addr = '1') or

                    -- Add check for current SM state
                    -- If LAST_ADDR state reached, no longer performing back-to-back
                    -- transfers and keeping data streaming on AXI bus.
                  (rd_data_sm_cs = LAST_ADDR) then
            
                axi_rvalid_clr_ok <= '1';
                
            else
                axi_rvalid_clr_ok <= axi_rvalid_clr_ok;            
            end if;
        end if;

    end process REG_RVALID_CLR;


    ---------------------------------------------------------------------------





    ---------------------------------------------------------------------------
    -- AXI_RLAST Output Register
    --
    -- Set AXI_RLAST when read data SM indicates.
    -- Clear when AXI_RLAST is asserted on AXI bus during handshaking sequence
    -- and recognized by AXI requesting master.
    ---------------------------------------------------------------------------

    REG_RLAST: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            -- To improve code coverage, remove
            -- use of axi_rvalid_int (it will always be asserted with RLAST).
            if (S_AXI_AResetn = C_RESET_ACTIVE) or 
               (axi_rlast_int = '1' and AXI_RREADY = '1' and axi_rlast_set = '0') then
                axi_rlast_int <= '0';

            elsif (axi_rlast_set = '1') then
                axi_rlast_int <= '1';
            else
                axi_rlast_int <= axi_rlast_int;

            end if;
        end if;

    end process REG_RLAST;



    
    ---------------------------------------------------------------------------
    
    -- Generate complete flag
    do_cmplt_burst_cmb <= '1' when (last_bram_addr = '1' and 
                                    axi_rd_burst = '1' and 
                                    axi_rd_burst_two = '0') else '0';
    
    -- Register complete flags  

    REG_CMPLT_BURST: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) or (do_cmplt_burst_clr = '1') then
                do_cmplt_burst <= '0';
            elsif (do_cmplt_burst_cmb = '1') then
                do_cmplt_burst <= '1';
            else
                do_cmplt_burst <= do_cmplt_burst;
            end if;

        end if;

    end process REG_CMPLT_BURST;
    

    ---------------------------------------------------------------------------





    ---------------------------------------------------------------------------
    -- RLAST State Machine
    --
    -- Description:     SM to generate axi_rlast_set signal.
    --                  Created based on IR # 555346 to track when RLAST needs 
    --                  to be asserted for back to back transfers
    --                  Uses the indication when last BRAM address is presented 
    --                  and then counts the handshaking cycles on the AXI bus 
    --                  (RVALID and RREADY both asserted).
    --                  Uses rd_adv_buf to perform this operation.
    --
    -- Output:          Name                        Type
    --                  axi_rlast_set               Not Registered
    --                  do_cmplt_burst_clr          Not Registered
    --
    --
    -- RLAST_SM_CMB_PROCESS:      Combinational process to determine next state.
    -- RLAST_SM_REG_PROCESS:      Registered process of the state machine.
    --
    ---------------------------------------------------------------------------
    RLAST_SM_CMB_PROCESS: process ( 
                                    do_cmplt_burst,                                    
                                    last_bram_addr,
                                    rd_adv_buf,                                    
                                    act_rd_burst,                                    
                                    axi_rd_burst,
                                    act_rd_burst_two,                                    
                                    axi_rd_burst_two,                                    
                                    axi_rlast_int,                                    
                                    rlast_sm_cs )

    begin

    -- assign default values for state machine outputs
    rlast_sm_ns <= rlast_sm_cs;
    axi_rlast_set <= '0';
    do_cmplt_burst_clr <= '0';    

    case rlast_sm_cs is
                       

            ---------------------------- IDLE State ---------------------------
            
            when IDLE =>

                -- If last read address is presented to BRAM
                if (last_bram_addr = '1') then
                    
                    -- If the operation is a single read operation
                    if (axi_rd_burst = '0') and (axi_rd_burst_two = '0') then
                        
                        -- Go to wait for last data beat
                        rlast_sm_ns <= W8_LAST_DATA;
                        
                    
                    -- Else the transaction is a burst
                    else
                    
                        -- Throttle condition on 3rd to last data beat
                        if (rd_adv_buf = '0') then
                        
                            -- If AXI read burst = 2 (only two data beats to capture)
                            if (axi_rd_burst_two = '1' or act_rd_burst_two = '1') then                         
                                rlast_sm_ns <= W8_THROTTLE_B2;                              
                                
                            else
                                rlast_sm_ns <= W8_THROTTLE;
                            end if;
                        
                        
                        -- No throttle on 3rd to last data beat
                        else
                                                    
                            -- Only back-to-back support when burst size is greater
                            -- than two data beats.  We will never toggle on a burst > 2
                            -- when last_bram_addr is asserted (as this is no toggle
                            -- condition)
                                                    
                            -- Go to wait for 2nd to last data beat
                            rlast_sm_ns <= W8_2ND_LAST_DATA;
                            
                            do_cmplt_burst_clr <= '1';
                            
                        end if;                        
                    end if;
                end if;



            ------------------------- W8_THROTTLE State -----------------------
            
            when W8_THROTTLE =>

                if (rd_adv_buf = '1') then
                                       
                    -- Go to wait for 2nd to last data beat
                    rlast_sm_ns <= W8_2ND_LAST_DATA;
                    
                    -- If do_cmplt_burst flag is set, then clear it
                    if (do_cmplt_burst = '1') then
                        do_cmplt_burst_clr <= '1';
                    end if;
                    
                            
                    
                end if;


            ---------------------- W8_2ND_LAST_DATA State ---------------------
            
            when W8_2ND_LAST_DATA =>
            
                if (rd_adv_buf = '1') then
                
                    -- Assert RLAST on AXI
                    axi_rlast_set <= '1';
                    rlast_sm_ns <= W8_LAST_DATA;  
                                        
                end if;


            ------------------------- W8_LAST_DATA State ----------------------
            
            when W8_LAST_DATA =>
                
                -- If pending single to complete, keep RLAST asserted

                -- Added to only assert axi_rlast_set for a single clock cycle
                -- when we enter this state and are here waiting for the
                -- throttle on the AXI bus.

                if (axi_rlast_int = '1') then
                    axi_rlast_set <= '0';
                else
                    axi_rlast_set <= '1';
                end if;


                -- Wait for last data beat to transition back to IDLE
                if (rd_adv_buf = '1') then               
                    rlast_sm_ns <= IDLE;          
                end if;
                
                
                
            -------------------------- W8_THROTTLE_B2 ------------------------
            
            when W8_THROTTLE_B2 =>
                
                -- Wait for last data beat to transition back to IDLE
                -- and set RLAST
                if (rd_adv_buf = '1') then                 
                    rlast_sm_ns <= IDLE; 
                    axi_rlast_set <= '1';
                end if;


    --coverage off
            ------------------------------ Default ----------------------------
            when others =>
                rlast_sm_ns <= IDLE;
    --coverage on

        end case;
        
    end process RLAST_SM_CMB_PROCESS;


    ---------------------------------------------------------------------------

    RLAST_SM_REG_PROCESS: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
        
            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                rlast_sm_cs <= IDLE;
            else
                rlast_sm_cs <= rlast_sm_ns;
            end if;
        end if;
        
    end process RLAST_SM_REG_PROCESS;


    ---------------------------------------------------------------------------












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
        
    signal bram_din_a_i     : std_logic_vector(0 to C_AXI_DATA_WIDTH+C_ECC_WIDTH-1) := (others => '0'); -- Set for port data width
    signal CE_Q             : std_logic := '0';
    signal Sl_CE_i          : std_logic := '0';
    signal bram_en_int_d1   : std_logic := '0';
    signal bram_en_int_d2   : std_logic := '0';

    begin
    
        -- Generate signal to advance BRAM read address pipeline to
        -- capture address for ECC error conditions (in lite_ecc_reg module).
        -- BRAM_Addr_En <= bram_addr_inc or narrow_bram_addr_inc_re or 
        --                         ((bram_en_int or bram_en_int_reg) and not (axi_rd_burst) and not (axi_rd_burst_two));


        BRAM_Addr_En <= bram_addr_inc or narrow_bram_addr_inc_re or rd_adv_buf or
                                ((bram_en_int or bram_en_int_d1 or bram_en_int_d2) and not (axi_rd_burst) and not (axi_rd_burst_two));

    
        -- Enable 2nd & 3rd pipeline stage for BRAM address storage with single read transfers.
        BRAM_EN_REG: process(S_AXI_AClk) is
        begin
            if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                bram_en_int_d1 <= bram_en_int;
                bram_en_int_d2 <= bram_en_int_d1;
            end if;
        end process BRAM_EN_REG;
        
    

        -- v1.03a
        
        ------------------------------------------------------------------------
        -- Generate:     GEN_HAMMING_ECC
        -- Purpose:      Determine type of ECC encoding.  Hsiao or Hamming.  
        --               Add parameter/generate level.
        ------------------------------------------------------------------------
        GEN_HAMMING_ECC: if C_ECC_TYPE = 0 generate
        begin


           ------------------------------------------------------------------------
           -- Generate:  GEN_ECC_32
           -- Purpose:   Check ECC data unique for 32-bit BRAM.
           --            Add extra '0' at MSB of ECC vector for data2mem alignment
           --            w/ 32-bit BRAM data widths.
           --            ECC bits are in upper order bits.
           ------------------------------------------------------------------------
           GEN_ECC_32: if C_AXI_DATA_WIDTH = 32 generate
            signal bram_din_a_rev            : std_logic_vector(31 downto 0) := (others => '0'); -- Specific to BRAM data width
            signal bram_din_ecc_a_rev            : std_logic_vector(6 downto 0) := (others => '0'); -- Specific to BRAM data width
           begin
			 

                ---------------------------------------------------------------------------
                -- Instance:        CHK_HANDLER_32
                -- Description:     Generate ECC bits for checking data read from BRAM.
                --                  All vectors oriented (0:N)
                ---------------------------------------------------------------------------
--			    process (bram_din_a_i) begin
--                for k in 0 to 31  loop
--				  bram_din_a_rev(k) <= bram_din_a_i(39-k);
--				end loop; 
--                for k in 0 to 6  loop
--				  bram_din_ecc_a_rev(0) <= bram_din_a_i(6-k);
--				end loop; 
--				end process;

                CHK_HANDLER_32: entity work.checkbit_handler
                  generic map (
                    C_ENCODE   => false,                 -- [boolean]
                    C_USE_LUT6 => C_USE_LUT6)            -- [boolean]
                  port map (

                    -- In 32-bit BRAM use case:     DataIn (8:39)
                    --                              CheckIn (1:7)
                    DataIn          => bram_din_a_i(C_INT_ECC_WIDTH+1 to C_INT_ECC_WIDTH+C_AXI_DATA_WIDTH),         -- [in  std_logic_vector(0 to 31)]
                    CheckIn         => bram_din_a_i(1 to C_INT_ECC_WIDTH),                                          -- [in  std_logic_vector(0 to 6)]
                    --DataIn          => bram_din_a_rev,         -- [in  std_logic_vector(0 to 31)]
                    --CheckIn         => bram_din_ecc_a_rev,                                          -- [in  std_logic_vector(0 to 6)]
                    CheckOut        => open,                                                                        -- [out std_logic_vector(0 to 6)]
                    Syndrome        => Syndrome,                                                                    -- [out std_logic_vector(0 to 6)]
                    Syndrome_4      => Syndrome_4,                                                                  -- [out std_logic_vector(0 to 1)]
                    Syndrome_6      => Syndrome_6,                                                                  -- [out std_logic_vector(0 to 5)]
                    Syndrome_Chk    => syndrome_reg_i,                                                              -- [out std_logic_vector(0 to 6)]
                    Enable_ECC      => Enable_ECC,                                                                  -- [in  std_logic]
                    UE_Q            => UE_Q,                                                                        -- [in  std_logic]
                    CE_Q            => CE_Q,                                                                        -- [in  std_logic]
                    UE              => Sl_UE_i,                                                                     -- [out std_logic]
                    CE              => Sl_CE_i );                                                                   -- [out std_logic]


                    -- GEN_CORR_32 generate & correct_one_bit instantiation moved to generate
                    -- of AXI RDATA output register logic.


            end generate GEN_ECC_32;       
            

           ------------------------------------------------------------------------
           -- Generate:  GEN_ECC_64
           -- Purpose:   Check ECC data unique for 64-bit BRAM.
           --            No extra '0' at MSB of ECC vector for data2mem alignment
           --            w/ 64-bit BRAM data widths.
           --            ECC bits are in upper order bits.
           ------------------------------------------------------------------------
           GEN_ECC_64: if C_AXI_DATA_WIDTH = 64 generate
           begin

                ---------------------------------------------------------------------------
                -- Instance:        CHK_HANDLER_64
                -- Description:     Generate ECC bits for checking data read from BRAM.
                --                  All vectors oriented (0:N)
                ---------------------------------------------------------------------------

                CHK_HANDLER_64: entity work.checkbit_handler_64
                  generic map (
                    C_ENCODE        =>  false,                 -- [boolean]
                    C_REG           =>  false,                 -- [boolean]
                    C_USE_LUT6      =>  C_USE_LUT6)            -- [boolean]
                  port map (
                    Clk             =>  S_AXI_AClk,                                                                  -- [in  std_logic]
                    -- In 64-bit BRAM use case:     DataIn (8:71)
                    --                              CheckIn (0:7)
                    DataIn          =>  bram_din_a_i (C_INT_ECC_WIDTH to C_INT_ECC_WIDTH+C_AXI_DATA_WIDTH-1),        -- [in  std_logic_vector(0 to 63)]
                    CheckIn         =>  bram_din_a_i (0 to C_INT_ECC_WIDTH-1),                                       -- [in  std_logic_vector(0 to 7)]

                    CheckOut        =>  open,                                                                        -- [out std_logic_vector(0 to 7)]
                    Syndrome        =>  Syndrome,                                                                    -- [out std_logic_vector(0 to 7)]
                    Syndrome_7      =>  Syndrome_7,
                    Syndrome_Chk    =>  syndrome_reg_i,                                                              -- [in  std_logic_vector(0 to 7)]
                    Enable_ECC      =>  Enable_ECC,                                                                  -- [in  std_logic]
                    UE_Q            =>  UE_Q,                                                                        -- [in  std_logic]
                    CE_Q            =>  CE_Q,                                                                        -- [in  std_logic]
                    UE              =>  Sl_UE_i,                                                                     -- [out std_logic]
                    CE              =>  Sl_CE_i );                                                                   -- [out std_logic]


                    -- GEN_CORR_64 generate & correct_one_bit instantiation moved to generate
                    -- of AXI RDATA output register logic.


            end generate GEN_ECC_64;
        
        
        end generate GEN_HAMMING_ECC;
        
 
 

        -- v1.03a

        ------------------------------------------------------------------------
        -- Generate:     GEN_HSIAO_ECC
        -- Purpose:      Determine type of ECC encoding.  Hsiao or Hamming.  
        --               Add parameter/generate level.
        --               Derived from MIG v3.7 Hsiao HDL.
        ------------------------------------------------------------------------
        GEN_HSIAO_ECC: if C_ECC_TYPE = 1 generate

        constant ECC_WIDTH  : integer := C_INT_ECC_WIDTH;
        signal syndrome_ns  : std_logic_vector (ECC_WIDTH - 1 downto 0) := (others => '0');

        begin
 
            -- Generate ECC check bits and syndrome values based on 
            -- BRAM read data.
            -- Generate appropriate single or double bit error flags.      
 
            
            -- Instantiate ecc_gen_hsiao module, generated from MIG
            I_ECC_GEN_HSIAO: entity work.ecc_gen
            generic map (
                code_width  => CODE_WIDTH,
                ecc_width   => ECC_WIDTH,
                data_width  => C_AXI_DATA_WIDTH
            )
            port map (
                -- Output
                h_rows  => h_rows (CODE_WIDTH * ECC_WIDTH - 1 downto 0)
            );
            

            GEN_RD_ECC: for m in 0 to ECC_WIDTH - 1 generate
            begin
                syndrome_ns (m) <= REDUCTION_XOR ( -- bram_din_a_i (0 to CODE_WIDTH-1) 
                                                   BRAM_RdData (CODE_WIDTH-1 downto 0)
                                                   and h_rows ((m*CODE_WIDTH)+CODE_WIDTH-1 downto (m*CODE_WIDTH)));
            end generate GEN_RD_ECC;

            -- Insert register stage for syndrome.
            -- Same as Hamming ECC code.  Syndrome value is registered.
            REG_SYNDROME: process (S_AXI_AClk)
            begin        
                if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then            
                    syndrome_r <= syndrome_ns;                    
                end if;
            end process REG_SYNDROME;


            Sl_CE_i <= not (REDUCTION_NOR (syndrome_r (ECC_WIDTH-1 downto 0))) and (REDUCTION_XOR (syndrome_r (ECC_WIDTH-1 downto 0)));
            Sl_UE_i <= not (REDUCTION_NOR (syndrome_r (ECC_WIDTH-1 downto 0))) and not(REDUCTION_XOR (syndrome_r (ECC_WIDTH-1 downto 0)));

 
        end generate GEN_HSIAO_ECC;
 
 
 
         -- Capture correctable/uncorrectable error from BRAM read
         CORR_REG: process(S_AXI_AClk) is
         begin
             if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                 if (Enable_ECC = '1') and 
                    (axi_rvalid_int = '1' and AXI_RREADY = '1') then     -- Capture error flags 
                     CE_Q <= Sl_CE_i;
                     UE_Q <= Sl_UE_i;
                 else              
                     CE_Q <= '0';
                     UE_Q <= '0';
                 end if;          
             end if;
         end process CORR_REG;

 
        -- The signal, axi_rdata_en loads the syndrome_reg.
        -- Use the AXI RVALID/READY signals to capture state of UE and CE.
        -- Since flag generation uses the registered syndrome value.
 
        -- ECC register block gets registered UE or CE conditions to update
        -- ECC registers/interrupt/flag outputs.
        Sl_CE <= CE_Q;
        Sl_UE <= UE_Q;
        
        -- CE_Failing_We <= Sl_CE_i and Enable_ECC and axi_rvalid_set;
        CE_Failing_We <= CE_Q;
                            
                            
        ---------------------------------------------------------------------------
        -- Generate BRAM read data vector assignment to always be from Port A
        -- in a single port BRAM configuration.
        -- Map BRAM_RdData (Port A) (N:0) to bram_din_a_i (0:N)
        -- Including read back ECC bits.
        --
        -- Port A or Port B sourcing done at full_axi module level
        ---------------------------------------------------------------------------
        -- Original design with mux (BRAM vs. Skid Buffer) on input side of checkbit_handler logic.
        -- Move mux to enable on AXI RDATA register.
        bram_din_a_i (0 to C_AXI_DATA_WIDTH+C_ECC_WIDTH-1) <= BRAM_RdData (C_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0);
        

        -- Map data vector from BRAM to use in correct_one_bit module with 
        -- register syndrome (post AXI RDATA register).
        UnCorrectedRdData (0 to C_AXI_DATA_WIDTH-1) <= bram_din_a_i (C_ECC_WIDTH to C_ECC_WIDTH+C_AXI_DATA_WIDTH-1);

                      
     end generate GEN_ECC;



    ---------------------------------------------------------------------------



    ---------------------------------------------------------------------------
    -- Generate:    GEN_NO_ECC
    -- Purpose:     Drive default output signals when ECC is diabled.
    ---------------------------------------------------------------------------

    GEN_NO_ECC: if C_ECC = 0 generate
    begin
    
        BRAM_Addr_En <= '0';
        CE_Failing_We <= '0'; 
        Sl_CE <= '0'; 
        Sl_UE <= '0'; 

    end generate GEN_NO_ECC;










    ---------------------------------------------------------------------------
    --
    -- *** BRAM Interface Signals ***
    --
    ---------------------------------------------------------------------------


    BRAM_En <= bram_en_int;   




    ---------------------------------------------------------------------------
    -- BRAM Address Generate
    ---------------------------------------------------------------------------


    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_L_BRAM_ADDR
    -- Purpose:     Generate zeros on lower order address bits adjustable
    --              based on BRAM data width.
    --
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





end architecture implementation;











