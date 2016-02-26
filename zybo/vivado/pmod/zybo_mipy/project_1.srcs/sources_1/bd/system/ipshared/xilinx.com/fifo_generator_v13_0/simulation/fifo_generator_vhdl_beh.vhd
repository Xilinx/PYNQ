-------------------------------------------------------------------------------
--
-- FIFO Generator - VHDL Behavioral Model
--
-------------------------------------------------------------------------------
-- (c) Copyright 1995 - 2009 Xilinx, Inc. All rights reserved.
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
-------------------------------------------------------------------------------
--
-- Filename: fifo_generator_vhdl_beh.vhd
--
-- Author     : Xilinx
--
-------------------------------------------------------------------------------
-- Structure:
--
-- fifo_generator_vhdl_beh.vhd
--    |
--    +-fifo_generator_v13_0_0_conv
--       |
--       +-fifo_generator_v13_0_0_bhv_as
--       |
--       +-fifo_generator_v13_0_0_bhv_ss
--       |
--       +-fifo_generator_v13_0_0_bhv_preload0
--
-------------------------------------------------------------------------------
-- Description:
--
-- The VHDL behavioral model for the FIFO Generator.
--
--   The behavioral model has three parts:
--      - The behavioral model for independent clocks FIFOs (_as)
--      - The behavioral model for common clock FIFOs (_ss)
--      - The "preload logic" block which implements First-word Fall-through
--
-------------------------------------------------------------------------------


--#############################################################################
--#############################################################################
--  Independent Clocks FIFO Behavioral Model
--#############################################################################
--#############################################################################

-------------------------------------------------------------------------------
-- Library Declaration
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_arith.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

-------------------------------------------------------------------------------
-- Independent Clocks Entity Declaration - This is NOT the top-level entity
-------------------------------------------------------------------------------
ENTITY fifo_generator_v13_0_0_bhv_as IS

  GENERIC (
    ---------------------------------------------------------------------------
    -- Generic Declarations
    ---------------------------------------------------------------------------
    C_FAMILY                       : string  := "virtex7";
    C_DIN_WIDTH                    : integer := 8;
    C_DOUT_RST_VAL                 : string  := "";
    C_DOUT_WIDTH                   : integer := 8;
    C_FULL_FLAGS_RST_VAL           : integer := 1;
    C_HAS_ALMOST_EMPTY             : integer := 0;
    C_HAS_ALMOST_FULL              : integer := 0;
    C_HAS_OVERFLOW                 : integer := 0;
    C_HAS_RD_DATA_COUNT            : integer := 2;
    C_HAS_RST                      : integer := 1;
    C_HAS_UNDERFLOW                : integer := 0;
    C_HAS_VALID                    : integer := 0;
    C_HAS_WR_ACK                   : integer := 0;
    C_HAS_WR_DATA_COUNT            : integer := 2;
    C_MEMORY_TYPE                  : integer := 1;
    C_OVERFLOW_LOW                 : integer := 0;
    C_PRELOAD_LATENCY              : integer := 1;
    C_PRELOAD_REGS                 : integer := 0;
    C_PROG_EMPTY_THRESH_ASSERT_VAL : integer := 0;
    C_PROG_EMPTY_THRESH_NEGATE_VAL : integer := 0;
    C_PROG_EMPTY_TYPE              : integer := 0;
    C_PROG_FULL_THRESH_ASSERT_VAL  : integer := 0;
    C_PROG_FULL_THRESH_NEGATE_VAL  : integer := 0;
    C_PROG_FULL_TYPE               : integer := 0;
    C_RD_DATA_COUNT_WIDTH          : integer := 0;
    C_RD_DEPTH                     : integer := 256;
    C_RD_PNTR_WIDTH                : integer := 8;
    C_UNDERFLOW_LOW                : integer := 0;
    C_USE_DOUT_RST                 : integer := 0;
    C_USE_ECC                      : integer := 0;
    C_EN_SAFETY_CKT                : integer := 0;
    C_USE_EMBEDDED_REG             : integer := 0;
    C_USE_FWFT_DATA_COUNT          : integer := 0;
    C_VALID_LOW                    : integer := 0;
    C_WR_ACK_LOW                   : integer := 0;
    C_WR_DATA_COUNT_WIDTH          : integer := 0;
    C_WR_DEPTH                     : integer := 256;
    C_WR_PNTR_WIDTH                : integer := 8;
    C_TCQ                          : time    := 100 ps;
    C_ENABLE_RST_SYNC              : integer := 1;
    C_ERROR_INJECTION_TYPE         : integer := 0;
    C_FIFO_TYPE                    : integer := 0;
    C_SYNCHRONIZER_STAGE           : integer := 2
    );
  PORT(
    ---------------------------------------------------------------------------
    -- Input and Output Declarations
    ---------------------------------------------------------------------------
    RST                      : IN std_logic;
    RST_FULL_GEN             : IN std_logic := '0';
    RST_FULL_FF              : IN std_logic := '0';
    WR_RST                   : IN std_logic;
    RD_RST                   : IN std_logic;
    DIN                      : IN std_logic_vector(C_DIN_WIDTH-1 DOWNTO 0);
    RD_CLK                   : IN std_logic;
    RD_EN                    : IN std_logic;
    RD_EN_USER               : IN std_logic;
    WR_CLK                   : IN std_logic;
    WR_EN                    : IN std_logic;
    PROG_EMPTY_THRESH        : IN std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0);
    PROG_EMPTY_THRESH_ASSERT : IN std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0);
    PROG_EMPTY_THRESH_NEGATE : IN std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0);
    PROG_FULL_THRESH         : IN std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0);
    PROG_FULL_THRESH_ASSERT  : IN std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0);
    PROG_FULL_THRESH_NEGATE  : IN std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0);
    INJECTDBITERR            : IN std_logic := '0';
    INJECTSBITERR            : IN std_logic := '0';
    USER_EMPTY_FB            : IN std_logic := '1';
    
    EMPTY                    : OUT std_logic := '1';
    FULL                     : OUT std_logic := '0'; 
    ALMOST_EMPTY             : OUT std_logic := '1';
    ALMOST_FULL              : OUT std_logic := '0'; 
    PROG_EMPTY               : OUT std_logic := '1';
    PROG_FULL                : OUT std_logic := '0'; 
    DOUT                     : OUT std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    VALID                    : OUT std_logic := '0';
    WR_ACK                   : OUT std_logic := '0';
    UNDERFLOW                : OUT std_logic := '0';
    OVERFLOW                 : OUT std_logic := '0';
    RD_DATA_COUNT            : OUT std_logic_vector(C_RD_DATA_COUNT_WIDTH-1 DOWNTO 0)
                             := (OTHERS => '0');
    WR_DATA_COUNT            : OUT std_logic_vector(C_WR_DATA_COUNT_WIDTH-1 DOWNTO 0)
                             := (OTHERS => '0');
    SBITERR                  : OUT std_logic := '0';
    DBITERR                  : OUT std_logic := '0'
    );



END fifo_generator_v13_0_0_bhv_as;



-------------------------------------------------------------------------------
-- Architecture Heading
-------------------------------------------------------------------------------
ARCHITECTURE behavioral OF fifo_generator_v13_0_0_bhv_as IS

  -----------------------------------------------------------------------------
  -- FUNCTION actual_fifo_depth
  -- Returns the actual depth of the FIFO (may differ from what the user 
  -- specified)
  --
  -- The FIFO depth is always represented as 2^n (16,32,64,128,256)
  -- However, the ACTUAL fifo depth may be 2^n+1 or 2^n-1 depending on certain
  -- options. This function returns the actual depth of the fifo, as seen by
  -- the user.
  -------------------------------------------------------------------------------
  FUNCTION actual_fifo_depth(
    C_FIFO_DEPTH : integer; 
    C_PRELOAD_REGS : integer; 
    C_PRELOAD_LATENCY : integer) 
  RETURN integer IS
  BEGIN
    RETURN C_FIFO_DEPTH - 1;
  END actual_fifo_depth;

  -----------------------------------------------------------------------------
  -- FUNCTION div_roundup
  -- Returns data_value / divisor, with the result rounded-up (if fractional)
  -------------------------------------------------------------------------------
  FUNCTION divroundup (
    data_value : integer;
    divisor : integer)
  RETURN integer IS
    VARIABLE div                   : integer;
  BEGIN
    div   := data_value/divisor;
    IF ( (data_value MOD divisor) /= 0) THEN
      div := div+1;
    END IF;
    RETURN div;
  END divroundup;

  -----------------------------------------------------------------------------
  -- FUNCTION int_2_std_logic
  -- Returns a single bit (as std_logic) from an integer 1/0 value.
  -------------------------------------------------------------------------------

  FUNCTION int_2_std_logic(value : integer) RETURN std_logic IS
  BEGIN
    IF (value=1) THEN
      RETURN '1';
    ELSE
      RETURN '0';
    END IF;
  END int_2_std_logic; 

  -----------------------------------------------------------------------------
  -- FUNCTION if_then_else
  -- Returns a true case or flase case based on the condition
  -------------------------------------------------------------------------------

    FUNCTION if_then_else (
      condition : boolean; 
      true_case : integer; 
      false_case : integer) 
    RETURN integer IS
      VARIABLE retval : integer := 0;
    BEGIN
      IF NOT condition THEN
        retval:=false_case;
      ELSE
        retval:=true_case;
      END IF;
      RETURN retval;
    END if_then_else;

    FUNCTION if_then_else (
      condition : boolean; 
      true_case : std_logic;
      false_case : std_logic) 
    RETURN std_logic IS
      VARIABLE retval : std_logic := '0';
    BEGIN
      IF NOT condition THEN
        retval:=false_case;
      ELSE
        retval:=true_case;
      END IF;
      RETURN retval;
    END if_then_else;

  -----------------------------------------------------------------------------
  -- FUNCTION hexstr_to_std_logic_vec
  -- Returns a std_logic_vector for a hexadecimal string
  -------------------------------------------------------------------------------

    FUNCTION hexstr_to_std_logic_vec( 
      arg1 : string; 
      size : integer ) 
    RETURN std_logic_vector IS
      VARIABLE result : std_logic_vector(size-1 DOWNTO 0) := (OTHERS => '0');
      VARIABLE bin    : std_logic_vector(3 DOWNTO 0);
      VARIABLE index  : integer                           := 0;
    BEGIN
      FOR i IN arg1'reverse_range LOOP
        CASE arg1(i) IS
          WHEN '0' => bin := (OTHERS => '0');
          WHEN '1' => bin := (0 => '1', OTHERS => '0');
          WHEN '2' => bin := (1 => '1', OTHERS => '0');
          WHEN '3' => bin := (0 => '1', 1 => '1', OTHERS => '0');
          WHEN '4' => bin := (2 => '1', OTHERS => '0');
          WHEN '5' => bin := (0 => '1', 2 => '1', OTHERS => '0');
          WHEN '6' => bin := (1 => '1', 2 => '1', OTHERS => '0');
          WHEN '7' => bin := (3 => '0', OTHERS => '1');
          WHEN '8' => bin := (3 => '1', OTHERS => '0');
          WHEN '9' => bin := (0 => '1', 3 => '1', OTHERS => '0');
          WHEN 'A' => bin := (0 => '0', 2 => '0', OTHERS => '1');
          WHEN 'a' => bin := (0 => '0', 2 => '0', OTHERS => '1');
          WHEN 'B' => bin := (2 => '0', OTHERS => '1');
          WHEN 'b' => bin := (2 => '0', OTHERS => '1');
          WHEN 'C' => bin := (0 => '0', 1 => '0', OTHERS => '1');
          WHEN 'c' => bin := (0 => '0', 1 => '0', OTHERS => '1');
          WHEN 'D' => bin := (1 => '0', OTHERS => '1');
          WHEN 'd' => bin := (1 => '0', OTHERS => '1');
          WHEN 'E' => bin := (0 => '0', OTHERS => '1');
          WHEN 'e' => bin := (0 => '0', OTHERS => '1');
          WHEN 'F' => bin := (OTHERS => '1');
          WHEN 'f' => bin := (OTHERS => '1');
          WHEN OTHERS =>
            FOR j IN 0 TO 3 LOOP
              bin(j) := 'X';
            END LOOP;
        END CASE;
        FOR j IN 0 TO 3 LOOP
          IF (index*4)+j < size THEN
            result((index*4)+j) := bin(j);
          END IF;
        END LOOP;
        index := index + 1;
      END LOOP;
      RETURN result;
    END hexstr_to_std_logic_vec;

  -----------------------------------------------------------------------------
  -- FUNCTION get_lesser
  -- Returns a minimum value
  -------------------------------------------------------------------------------
  
  FUNCTION get_lesser(a: INTEGER; b: INTEGER) RETURN INTEGER IS
  BEGIN
    IF (a < b) THEN
      RETURN a;
    ELSE
      RETURN b;
    END IF;
  END FUNCTION;


  -----------------------------------------------------------------------------
  -- Derived Constants
  -----------------------------------------------------------------------------
  CONSTANT C_FIFO_WR_DEPTH      : integer 
    := actual_fifo_depth(C_WR_DEPTH, C_PRELOAD_REGS, C_PRELOAD_LATENCY);
  CONSTANT C_FIFO_RD_DEPTH      : integer 
    := actual_fifo_depth(C_RD_DEPTH, C_PRELOAD_REGS, C_PRELOAD_LATENCY);
  CONSTANT C_SMALLER_DATA_WIDTH : integer 
    := get_lesser(C_DIN_WIDTH, C_DOUT_WIDTH);
  CONSTANT C_DEPTH_RATIO_WR     : integer 
    := if_then_else( (C_WR_DEPTH > C_RD_DEPTH), (C_WR_DEPTH/C_RD_DEPTH), 1);
  CONSTANT C_DEPTH_RATIO_RD     : integer 
    := if_then_else( (C_RD_DEPTH > C_WR_DEPTH), (C_RD_DEPTH/C_WR_DEPTH), 1);

  -- "Extra Words" is the number of write words which fit into the two
  -- first-word fall-through output register stages (if using FWFT).
  -- For ratios of 1:4 and 1:8, the fractional result is rounded up to 1.
  -- This value is used to calculate the adjusted PROG_FULL threshold
  -- value for FWFT.
  -- EXTRA_WORDS = 2 * C_DEPTH_RATIO_WR / C_DEPTH_RATIO_RD
  -- WR_DEPTH : RD_DEPTH = 1:2 => EXTRA_WORDS = 1
  -- WR_DEPTH : RD_DEPTH = 1:4 => EXTRA_WORDS = 1 (rounded to ceiling)
  -- WR_DEPTH : RD_DEPTH = 2:1 => EXTRA_WORDS = 4
  -- WR_DEPTH : RD_DEPTH = 4:1 => EXTRA_WORDS = 8
  CONSTANT EXTRA_WORDS          : integer := divroundup(2 * C_DEPTH_RATIO_WR, C_DEPTH_RATIO_RD);

  -- "Extra words dc" is used for calculating the adjusted WR_DATA_COUNT
  -- value for the core when using FWFT.
  -- extra_words_dc = 2 * C_DEPTH_RATIO_WR / C_DEPTH_RATIO_RD
  --  C_DEPTH_RATIO_WR | C_DEPTH_RATIO_RD | C_PNTR_WIDTH    | EXTRA_WORDS_DC
  --  -----------------|------------------|-----------------|---------------
  --  1                | 8                | C_RD_PNTR_WIDTH | 2
  --  1                | 4                | C_RD_PNTR_WIDTH | 2
  --  1                | 2                | C_RD_PNTR_WIDTH | 2
  --  1                | 1                | C_WR_PNTR_WIDTH | 2
  --  2                | 1                | C_WR_PNTR_WIDTH | 4
  --  4                | 1                | C_WR_PNTR_WIDTH | 8
  --  8                | 1                | C_WR_PNTR_WIDTH | 16
  CONSTANT EXTRA_WORDS_DC  : integer
                           := if_then_else ((C_DEPTH_RATIO_WR = 1),2,
                              (2 * C_DEPTH_RATIO_WR/C_DEPTH_RATIO_RD));

  CONSTANT C_PE_THR_ASSERT_ADJUSTED  : integer
    :=if_then_else((C_PRELOAD_REGS=1 and C_PRELOAD_LATENCY=0),
                    C_PROG_EMPTY_THRESH_ASSERT_VAL - 2, --FWFT
                    C_PROG_EMPTY_THRESH_ASSERT_VAL );   --NO FWFT
  CONSTANT C_PE_THR_NEGATE_ADJUSTED  : integer
    :=if_then_else((C_PRELOAD_REGS=1 and C_PRELOAD_LATENCY=0),
                    C_PROG_EMPTY_THRESH_NEGATE_VAL - 2, --FWFT
                    C_PROG_EMPTY_THRESH_NEGATE_VAL);    --NO FWFT
  
  CONSTANT C_PE_THR_ASSERT_VAL_I : integer := C_PE_THR_ASSERT_ADJUSTED;
  CONSTANT C_PE_THR_NEGATE_VAL_I : integer := C_PE_THR_NEGATE_ADJUSTED;

  CONSTANT C_PF_THR_ASSERT_ADJUSTED  : integer
    :=if_then_else((C_PRELOAD_REGS=1 and C_PRELOAD_LATENCY=0),
                    C_PROG_FULL_THRESH_ASSERT_VAL - EXTRA_WORDS_DC, --FWFT
                    C_PROG_FULL_THRESH_ASSERT_VAL );   --NO FWFT
  CONSTANT C_PF_THR_NEGATE_ADJUSTED  : integer
    :=if_then_else((C_PRELOAD_REGS=1 and C_PRELOAD_LATENCY=0),
                    C_PROG_FULL_THRESH_NEGATE_VAL - EXTRA_WORDS_DC, --FWFT
                    C_PROG_FULL_THRESH_NEGATE_VAL);    --NO FWFT

  -- NO_ERR_INJECTION will be 1 if ECC is OFF or ECC is ON but no error
  -- injection is selected.
  CONSTANT NO_ERR_INJECTION      : integer 
           := if_then_else(C_USE_ECC = 0,1,
              if_then_else(C_ERROR_INJECTION_TYPE = 0,1,0));

  -- SBIT_ERR_INJECTION will be 1 if ECC is ON and single bit error injection
  -- is selected.
  CONSTANT SBIT_ERR_INJECTION    : integer 
           := if_then_else((C_USE_ECC > 0 AND C_ERROR_INJECTION_TYPE = 1),1,0);

  -- DBIT_ERR_INJECTION will be 1 if ECC is ON and double bit error injection
  -- is selected.
  CONSTANT DBIT_ERR_INJECTION    : integer 
           := if_then_else((C_USE_ECC > 0 AND C_ERROR_INJECTION_TYPE = 2),1,0);

  -- BOTH_ERR_INJECTION will be 1 if ECC is ON and both single and double bit
  -- error injection are selected.
  CONSTANT BOTH_ERR_INJECTION    : integer 
           := if_then_else((C_USE_ECC > 0 AND C_ERROR_INJECTION_TYPE = 3),1,0);

  CONSTANT C_DATA_WIDTH : integer := if_then_else(NO_ERR_INJECTION = 1, C_DIN_WIDTH, C_DIN_WIDTH+2);
  CONSTANT OF_INIT_VAL : std_logic := if_then_else((C_HAS_OVERFLOW = 1 AND C_OVERFLOW_LOW = 1),'1','0');
  CONSTANT UF_INIT_VAL : std_logic := if_then_else((C_HAS_UNDERFLOW = 1 AND C_UNDERFLOW_LOW = 1),'1','0');

  TYPE wr_sync_array IS ARRAY (C_SYNCHRONIZER_STAGE-1 DOWNTO 0) OF std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0);
  TYPE rd_sync_array IS ARRAY (C_SYNCHRONIZER_STAGE-1 DOWNTO 0) OF std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0);
  SIGNAL wr_pntr_q : wr_sync_array := (OTHERS => (OTHERS => '0'));
  SIGNAL rd_pntr_q : rd_sync_array := (OTHERS => (OTHERS => '0'));

  -------------------------------------------------------------------------------
  -- Signals Declaration
  -------------------------------------------------------------------------------
  SIGNAL wr_point       : integer   := 0;
  SIGNAL rd_point       : integer   := 0;
  SIGNAL wr_point_d1    : integer   := 0;
  SIGNAL rd_point_d1    : integer   := 0;
  SIGNAL num_wr_words   : integer   := 0;
  SIGNAL num_rd_words   : integer   := 0;
  SIGNAL adj_wr_point   : integer   := 0;
  SIGNAL adj_rd_point   : integer   := 0;
  SIGNAL adj_wr_point_d1: integer   := 0;
  SIGNAL adj_rd_point_d1: integer   := 0;

  SIGNAL wr_rst_i        : std_logic := '0';
  SIGNAL rd_rst_i        : std_logic := '0';
  SIGNAL wr_rst_d1       : std_logic := '0';

  SIGNAL wr_ack_i        : std_logic := '0';
  SIGNAL overflow_i      : std_logic := OF_INIT_VAL;
  SIGNAL valid_i         : std_logic := '0';
  SIGNAL valid_d1        : std_logic := '0';
  SIGNAL valid_out       : std_logic := '0';
  SIGNAL underflow_i     : std_logic := UF_INIT_VAL;


  SIGNAL prog_full_reg     : std_logic := '0';
  SIGNAL prog_empty_reg    : std_logic := '1';
  SIGNAL dout_i            : std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0) 
                           := (OTHERS => '0');
  SIGNAL width_gt1         : std_logic := '0'; 
  SIGNAL sbiterr_i         : std_logic := '0'; 
  SIGNAL dbiterr_i         : std_logic := '0'; 

  SIGNAL wr_pntr            : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL wr_pntr_rd1        : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL wr_pntr_rd2        : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL wr_pntr_rd3        : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL wr_pntr_rd         : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL adj_wr_pntr_rd     : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) 
                            := (OTHERS=>'0');
  SIGNAL wr_data_count_int  : std_logic_vector(C_WR_PNTR_WIDTH DOWNTO 0) 
                            := (OTHERS=>'0');
  SIGNAL wdc_fwft_ext_as    : std_logic_vector(C_WR_PNTR_WIDTH DOWNTO 0) 
                            := (OTHERS=>'0');
  SIGNAL rdc_fwft_ext_as    : std_logic_vector (C_RD_PNTR_WIDTH DOWNTO 0)
                            := (OTHERS => '0');
  SIGNAL rd_pntr            : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL rd_pntr_wr_d1      : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL rd_pntr_wr_d2      : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL rd_pntr_wr_d3      : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL rd_pntr_wr_d4      : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL rd_pntr_wr         : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) 
                            := (OTHERS=>'0');
  SIGNAL adj_rd_pntr_wr     : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) 
                            := (OTHERS=>'0');
  SIGNAL rd_data_count_int  : std_logic_vector(C_RD_PNTR_WIDTH DOWNTO 0) 
                            := (OTHERS=>'0');
  SIGNAL empty_int          : boolean   := TRUE;
  SIGNAL empty_comb         : std_logic := '1';
  SIGNAL ram_rd_en          : std_logic := '0';
  SIGNAL ram_rd_en_d1       : std_logic := '0';
  SIGNAL empty_comb_d1      : std_logic := '1';
  SIGNAL almost_empty_int   : boolean   := TRUE;
  SIGNAL full_int           : boolean   := FALSE;
  SIGNAL full_comb          : std_logic := int_2_std_logic(C_FULL_FLAGS_RST_VAL);
  SIGNAL ram_wr_en          : std_logic := '0';
  SIGNAL almost_full_int    : boolean   := FALSE;
  SIGNAL rd_fwft_cnt        : std_logic_vector(3 downto 0)   := (others=>'0');
  SIGNAL stage1_valid       : std_logic := '0';
  SIGNAL stage2_valid       : std_logic := '0';

  SIGNAL diff_pntr_wr       : integer := 0;
  SIGNAL diff_pntr_rd       : integer := 0;
  SIGNAL pf_input_thr_assert_val : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL pf_input_thr_negate_val : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS=>'0');

  -------------------------------------------------------------------------------
  --Linked List types
  -------------------------------------------------------------------------------
  TYPE listtyp;
  TYPE listptr IS ACCESS listtyp;
  TYPE listtyp IS RECORD
      data  : std_logic_vector(C_SMALLER_DATA_WIDTH + 1 DOWNTO 0);
      older : listptr;
      newer : listptr;
    END RECORD;

  -------------------------------------------------------------------------------
  --Processes for linked list implementation. The functions are
  --1. "newlist" - Create a new linked list
  --2. "add"     - Add a data element to a linked list
  --3. "read"    - Read the data from the tail of the linked list
  --4. "remove"  - Remove the tail from the linked list
  --5. "sizeof"  - Calculate the size of the linked list
  -------------------------------------------------------------------------------
  --1. Create a new linked list
  PROCEDURE newlist (
    head   : INOUT listptr; 
    tail   : INOUT listptr;
    cntr   : INOUT integer) IS
  BEGIN
    head   := NULL;
    tail   := NULL;
    cntr   := 0;
  END;  

  --2. Add a data element to a linked list
  PROCEDURE add (
    head    : INOUT listptr; 
    tail    : INOUT listptr; 
    data    : IN std_logic_vector;
    cntr    : INOUT integer;
    inj_err : IN std_logic_vector(2 DOWNTO 0)
    ) IS
    VARIABLE oldhead        : listptr;
    VARIABLE newhead        : listptr;
    VARIABLE corrupted_data : std_logic_vector(1 DOWNTO 0);
  BEGIN
    --------------------------------------------------------------------------
    --a. Create a pointer to the existing head, if applicable
    --b. Create a new node for the list
    --c. Make the new node point to the old head
    --d. Make the old head point back to the new node (for doubly-linked list)
    --e. Put the data into the new head node
    --f. If the new head we just created is the only node in the list, 
    --   make the tail point to it
    --g. Return the new head pointer
    --------------------------------------------------------------------------
    IF (head /= NULL) THEN
      oldhead       := head;
    END IF;
    newhead         := NEW listtyp;
    newhead.older   := oldhead;
    IF (head /= NULL) THEN
      oldhead.newer := newhead;
    END IF;

    CASE inj_err(1 DOWNTO 0) IS
      -- For both error injection, pass only the double bit error injection
      -- as dbit error has priority over single bit error injection
      WHEN "11"   => newhead.data := inj_err(1) & '0' & data;
      WHEN "10"   => newhead.data := inj_err(1) & '0' & data;
      WHEN "01"   => newhead.data := '0' & inj_err(0) & data;
      WHEN OTHERS => newhead.data := '0' & '0' & data;
    END CASE;

    -- Increment the counter when data is added to the list
    cntr := cntr + 1;
    IF (newhead.older = NULL) THEN
      tail          := newhead;
    END IF;
    head            := newhead;
  END;  

  --3. Read the data from the tail of the linked list
  PROCEDURE read (
    tail : INOUT listptr; 
    data : OUT std_logic_vector;
    err_type : OUT std_logic_vector(1 DOWNTO 0)
    ) IS
  VARIABLE data_int     : std_logic_vector(C_SMALLER_DATA_WIDTH + 1 DOWNTO 0) := (OTHERS => '0');
  VARIABLE err_type_int : std_logic_vector(1 DOWNTO 0) := (OTHERS => '0');
  BEGIN
    data_int := tail.data;
    -- MSB two bits carry the error injection type.
    err_type_int := data_int(data_int'high DOWNTO C_SMALLER_DATA_WIDTH);
    IF (err_type_int(1) = '0') THEN
      data     := data_int(C_SMALLER_DATA_WIDTH - 1 DOWNTO 0);
    ELSIF (C_DOUT_WIDTH = 2) THEN
        data     := NOT data_int(C_SMALLER_DATA_WIDTH - 1 DOWNTO 0);
    ELSIF (C_DOUT_WIDTH > 2) THEN
        data     := NOT data_int(data_int'high-2) & NOT data_int(data_int'high-3) &
                    data_int(data_int'high-4 DOWNTO 0);
    ELSE
      data     := data_int(C_SMALLER_DATA_WIDTH - 1 DOWNTO 0);
    END IF;

    err_type := err_type_int;

  END;  

  --4. Remove the tail from the linked list
  PROCEDURE remove (
    head : INOUT listptr; 
    tail : INOUT listptr;
    cntr : INOUT integer) IS
    VARIABLE oldtail     :       listptr;
    VARIABLE newtail     :       listptr;
  BEGIN
    --------------------------------------------------------------------------
    --Make a copy of the old tail pointer
    --a. If there is no newer node, then set the tail pointer to nothing 
    --   (list is empty)
    --   otherwise, make the next newer node the new tail, and make it point 
    --   to nothing older
    --b. Clean up the memory for the old tail node
    --c. If the new tail is nothing, then we have an empty list, and head 
    --   should also be set to nothing
    --d. Return the new tail
    --------------------------------------------------------------------------
    oldtail         := tail;
    IF (oldtail.newer = NULL) THEN
      newtail       := NULL;
    ELSE
      newtail       := oldtail.newer;
      newtail.older := NULL;
    END IF;
    DEALLOCATE(oldtail);
    IF (newtail = NULL) THEN
      head          := NULL;
    END IF;
    tail            := newtail;
    -- Decrement the counter when data is removed from the list
    cntr := cntr - 1;
  END; 


  --5. Calculate the size of the linked list
  PROCEDURE sizeof (head : INOUT listptr; size : OUT integer) IS
    VARIABLE curlink     :       listptr;
    VARIABLE tmpsize     :       integer := 0;
  BEGIN
    --------------------------------------------------------------------------
    --a. If head is null, then there is nothing in the list to traverse
    --   start with the head node (which implies at least one node exists)
    --   Loop through each node until you find the one that points to nothing 
    --   (the tail)
    --b. Return the number of nodes
    --------------------------------------------------------------------------
    IF (head /= NULL) THEN
      curlink                            := head;
      tmpsize                            := 1;
      WHILE (curlink.older /= NULL) LOOP
        tmpsize                          := tmpsize + 1;
        curlink                          := curlink.older;
      END LOOP;
    END IF;
    size                                 := tmpsize;
  END;  


  -----------------------------------------------------------------------------
  -- converts integer to specified length std_logic_vector : dropping least
  -- significant bits if integer is bigger than what can be represented by
  -- the vector
  -----------------------------------------------------------------------------
  FUNCTION count( 
    fifo_count    : IN integer;
    pointer_width : IN integer;
    counter_width : IN integer)
  RETURN std_logic_vector IS
    VARIABLE temp   :    std_logic_vector(pointer_width-1 DOWNTO 0)   
                    := (OTHERS => '0');
    VARIABLE output :    std_logic_vector(counter_width - 1 DOWNTO 0) 
                    := (OTHERS => '0');
  BEGIN
    temp     := CONV_STD_LOGIC_VECTOR(fifo_count, pointer_width);
    IF (counter_width <= pointer_width) THEN
      output := temp(pointer_width - 1 DOWNTO pointer_width - counter_width);
    ELSE
      output := temp(counter_width - 1 DOWNTO 0);
    END IF;
    RETURN output;
  END count;

-------------------------------------------------------------------------------
-- architecture begins here
-------------------------------------------------------------------------------
BEGIN
  -------------------------------------------------------------------------------
  -- Asynchronous FIFO
  -------------------------------------------------------------------------------
  gnll_afifo: IF (C_FIFO_TYPE /= 3) GENERATE
 
    wr_pntr       <= conv_std_logic_vector(wr_point,C_WR_PNTR_WIDTH);
    rd_pntr       <= conv_std_logic_vector(rd_point,C_RD_PNTR_WIDTH);
 
    wr_rst_i <= WR_RST;
    rd_rst_i <= RD_RST;
 
    -------------------------------------------------------------------------------
    -- calculate number of words in wr and rd domain according to the deepest port
    --
    -- These steps circumvent the linked-list data structure and keep track of
    -- wr_point and rd_point pointers much like the core itself does. The behavioral
    -- model uses these to calculate WR_DATA_COUNT and RD_DATA_COUNT. This was done
    -- because the sizeof() function always returns the exact number of words in
    -- the linked list, and can not account for delays when crossing clock domains.
    -------------------------------------------------------------------------------
    adj_wr_point   <= wr_point * C_DEPTH_RATIO_RD;
    adj_rd_point   <= rd_point * C_DEPTH_RATIO_WR;
    adj_wr_point_d1<= wr_point_d1 * C_DEPTH_RATIO_RD;
    adj_rd_point_d1<= rd_point_d1 * C_DEPTH_RATIO_WR;
 
    width_gt1 <= '1' WHEN (C_DIN_WIDTH = 2) ELSE '0'; 
   
    PROCESS (adj_wr_point, adj_wr_point_d1, adj_rd_point, adj_rd_point_d1)
    BEGIN
      IF (adj_wr_point >= adj_rd_point_d1) THEN
        num_wr_words <= adj_wr_point - adj_rd_point_d1;
      ELSE
        num_wr_words <= C_WR_DEPTH*C_DEPTH_RATIO_RD + adj_wr_point - adj_rd_point_d1;
      END IF;
      IF (adj_wr_point_d1 >= adj_rd_point) THEN
        num_rd_words <= adj_wr_point_d1 - adj_rd_point;
      ELSE
        num_rd_words <= C_RD_DEPTH*C_DEPTH_RATIO_WR + adj_wr_point_d1 - adj_rd_point;
      END IF;
    END PROCESS;
    
    -------------------------------------------------------------------------------
    --Calculate WR_ACK based on C_WR_ACK_LOW parameters
    -------------------------------------------------------------------------------
    gwalow : IF (C_WR_ACK_LOW = 0) GENERATE
      WR_ACK <= wr_ack_i;
    END GENERATE gwalow;
    
    gwahgh : IF (C_WR_ACK_LOW = 1) GENERATE
      WR_ACK <= NOT wr_ack_i;
    END GENERATE gwahgh;
    
    -------------------------------------------------------------------------------
    --Calculate OVERFLOW based on C_OVERFLOW_LOW parameters
    -------------------------------------------------------------------------------
    govlow : IF (C_OVERFLOW_LOW = 0) GENERATE
      OVERFLOW <= overflow_i;
    END GENERATE govlow;
    
    govhgh : IF (C_OVERFLOW_LOW = 1) GENERATE
      OVERFLOW <= NOT overflow_i;
    END GENERATE govhgh;
    
    -------------------------------------------------------------------------------
    --Calculate VALID based on C_VALID_LOW
    -------------------------------------------------------------------------------
 
    gnvl : IF (C_VALID_LOW = 0) GENERATE
      VALID <= valid_out;
    END GENERATE gnvl;
    
    gnvh : IF (C_VALID_LOW = 1) GENERATE
      VALID <= NOT valid_out;
    END GENERATE gnvh;
    
    -------------------------------------------------------------------------------
    --Calculate UNDERFLOW based on C_UNDERFLOW_LOW
    -------------------------------------------------------------------------------
    gnul  : IF (C_UNDERFLOW_LOW = 0) GENERATE
      UNDERFLOW <= underflow_i;
    END GENERATE gnul;
    
    gnuh  : IF (C_UNDERFLOW_LOW = 1) GENERATE
      UNDERFLOW <= NOT underflow_i;
    END GENERATE gnuh;
    
    -------------------------------------------------------------------------------
    --Assign PROG_FULL and PROG_EMPTY
    -------------------------------------------------------------------------------
    PROG_FULL <= prog_full_reg;
    PROG_EMPTY <= prog_empty_reg;
    
    -------------------------------------------------------------------------------
    --Assign RD_DATA_COUNT and WR_DATA_COUNT
    -------------------------------------------------------------------------------
    rdc: IF (C_HAS_RD_DATA_COUNT=1) GENERATE
      grdc_fwft_ext: IF (C_USE_FWFT_DATA_COUNT = 1) GENERATE
        RD_DATA_COUNT <= rdc_fwft_ext_as(C_RD_PNTR_WIDTH DOWNTO C_RD_PNTR_WIDTH+1-C_RD_DATA_COUNT_WIDTH);
      END GENERATE grdc_fwft_ext;
    
      gnrdc_fwft_ext: IF (C_USE_FWFT_DATA_COUNT = 0) GENERATE
        RD_DATA_COUNT <= rd_data_count_int(C_RD_PNTR_WIDTH DOWNTO C_RD_PNTR_WIDTH+1-C_RD_DATA_COUNT_WIDTH);
      END GENERATE gnrdc_fwft_ext;
    END GENERATE rdc;
 
    nrdc: IF (C_HAS_RD_DATA_COUNT=0) GENERATE
      RD_DATA_COUNT <= (OTHERS=>'0');
    END GENERATE nrdc;
    
    wdc: IF (C_HAS_WR_DATA_COUNT = 1) GENERATE
      gwdc_fwft_ext: IF (C_USE_FWFT_DATA_COUNT = 1) GENERATE
        WR_DATA_COUNT <= wdc_fwft_ext_as(C_WR_PNTR_WIDTH DOWNTO C_WR_PNTR_WIDTH+1-C_WR_DATA_COUNT_WIDTH);
      END GENERATE gwdc_fwft_ext;
    
      gnwdc_fwft_ext: IF (C_USE_FWFT_DATA_COUNT = 0) GENERATE
        WR_DATA_COUNT <= wr_data_count_int(C_WR_PNTR_WIDTH DOWNTO C_WR_PNTR_WIDTH+1-C_WR_DATA_COUNT_WIDTH);
      END GENERATE gnwdc_fwft_ext;
    END GENERATE wdc;
    nwdc: IF (C_HAS_WR_DATA_COUNT=0) GENERATE
      WR_DATA_COUNT <= (OTHERS=>'0');
    END GENERATE nwdc;


 
 
    -------------------------------------------------------------------------------
    -- Write data count calculation if Use Extra Logic option is used 
    -------------------------------------------------------------------------------
    wdc_fwft_ext: IF (C_HAS_WR_DATA_COUNT = 1 AND C_USE_FWFT_DATA_COUNT = 1) GENERATE 
 
      CONSTANT C_PNTR_WIDTH    : integer           
                               := if_then_else ((C_WR_PNTR_WIDTH>=C_RD_PNTR_WIDTH),
                                  C_WR_PNTR_WIDTH, C_RD_PNTR_WIDTH);
      SIGNAL adjusted_wr_pntr  : std_logic_vector (C_PNTR_WIDTH-1 DOWNTO 0)
                               := (OTHERS => '0');
      SIGNAL adjusted_rd_pntr  : std_logic_vector (C_PNTR_WIDTH-1 DOWNTO 0)
                               := (OTHERS => '0');
      CONSTANT EXTRA_WORDS     : std_logic_vector (C_PNTR_WIDTH DOWNTO 0)
                               := conv_std_logic_vector(
                                  if_then_else ((C_DEPTH_RATIO_WR=1),2
                                  ,(2 * C_DEPTH_RATIO_WR/C_DEPTH_RATIO_RD))
                                  ,C_PNTR_WIDTH+1);
      SIGNAL diff_wr_rd_tmp    : std_logic_vector (C_PNTR_WIDTH-1 DOWNTO 0)
                               := (OTHERS => '0');
      SIGNAL diff_wr_rd        : std_logic_vector (C_PNTR_WIDTH DOWNTO 0)
                               := (OTHERS => '0');
      SIGNAL wr_data_count_i   : std_logic_vector (C_PNTR_WIDTH DOWNTO 0)
                               := (OTHERS => '0');
 
    BEGIN
      -----------------------------------------------------------------------------
      --Adjust write and read pointer to the deepest port width
      -----------------------------------------------------------------------------
      --C_PNTR_WIDTH=C_WR_PNTR_WIDTH
      gpadr: IF (C_WR_PNTR_WIDTH > C_RD_PNTR_WIDTH) GENERATE
        adjusted_wr_pntr <= wr_pntr;
        adjusted_rd_pntr(C_PNTR_WIDTH-1 DOWNTO C_PNTR_WIDTH-C_RD_PNTR_WIDTH) 
          <= rd_pntr_wr;
        adjusted_rd_pntr(C_PNTR_WIDTH-C_RD_PNTR_WIDTH-1 DOWNTO 0)<=(OTHERS=>'0');
      END GENERATE gpadr;
    
      --C_PNTR_WIDTH=C_RD_PNTR_WIDTH
      gpadw: IF (C_WR_PNTR_WIDTH < C_RD_PNTR_WIDTH) GENERATE
        adjusted_wr_pntr(C_PNTR_WIDTH-1 DOWNTO C_PNTR_WIDTH-C_WR_PNTR_WIDTH) 
          <= wr_pntr;
        adjusted_wr_pntr(C_PNTR_WIDTH-C_WR_PNTR_WIDTH-1 DOWNTO 0)<=(OTHERS=>'0');
        adjusted_rd_pntr <= rd_pntr_wr;
      END GENERATE gpadw;
    
      --C_PNTR_WIDTH=C_WR_PNTR_WIDTH=C_RD_PNTR_WIDTH
      ngpad: IF (C_WR_PNTR_WIDTH = C_RD_PNTR_WIDTH) GENERATE
        adjusted_wr_pntr <= wr_pntr;
        adjusted_rd_pntr <= rd_pntr_wr;
      END GENERATE ngpad;
    
      -----------------------------------------------------------------------------
      --Calculate words in write domain
      -----------------------------------------------------------------------------
      --Subtract the pointers to get the number of words in the RAM, *THEN* pad
      --the result
      diff_wr_rd_tmp <= adjusted_wr_pntr - adjusted_rd_pntr;
    
      diff_wr_rd <= '0' & diff_wr_rd_tmp;
    
      pwdc : PROCESS   (WR_CLK, wr_rst_i)
      BEGIN
        IF (wr_rst_i = '1') THEN
          wr_data_count_i <= (OTHERS=>'0');
        ELSIF (WR_CLK'event AND WR_CLK = '1') THEN
          wr_data_count_i <= diff_wr_rd + extra_words;
        END IF;
      END PROCESS pwdc;
    
      gdc0: IF (C_WR_PNTR_WIDTH >= C_RD_PNTR_WIDTH) GENERATE
        wdc_fwft_ext_as
          <= wr_data_count_i(C_PNTR_WIDTH DOWNTO 0);
      END GENERATE gdc0;
    
      gdc1: IF (C_WR_PNTR_WIDTH < C_RD_PNTR_WIDTH) GENERATE
        wdc_fwft_ext_as
          <= wr_data_count_i(C_PNTR_WIDTH DOWNTO C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH);
      END GENERATE gdc1;
    
    END GENERATE wdc_fwft_ext;
   
   
    -------------------------------------------------------------------------------
    -- Read data count calculation if Use Extra Logic option is used 
    -------------------------------------------------------------------------------
    rdc_fwft_ext: IF (C_HAS_RD_DATA_COUNT = 1 AND C_USE_FWFT_DATA_COUNT = 1) GENERATE 
 
      SIGNAL diff_wr_rd_tmp      : std_logic_vector (C_RD_PNTR_WIDTH-1 DOWNTO 0)
        := (OTHERS => '0');
      SIGNAL diff_wr_rd          : std_logic_vector (C_RD_PNTR_WIDTH DOWNTO 0)
        := (OTHERS => '0');
      SIGNAL zero                : std_logic_vector (C_RD_PNTR_WIDTH DOWNTO 0)
        := (OTHERS => '0');
      SIGNAL one                 : std_logic_vector (C_RD_PNTR_WIDTH DOWNTO 0)
        := conv_std_logic_vector(1, C_RD_PNTR_WIDTH+1);
      SIGNAL two                 : std_logic_vector (C_RD_PNTR_WIDTH DOWNTO 0)
        := conv_std_logic_vector(2, C_RD_PNTR_WIDTH+1);
      SIGNAL adjusted_wr_pntr_r : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) 
        := (OTHERS=>'0');
 
    BEGIN
 
      ----------------------------------------------------------------------------
      -- If write depth is smaller than read depth, pad write pointer.
      -- If write depth is bigger than read depth, trim write pointer.
      ----------------------------------------------------------------------------
      gpad : IF (C_RD_PNTR_WIDTH>C_WR_PNTR_WIDTH) GENERATE
        adjusted_wr_pntr_r(C_RD_PNTR_WIDTH-1 DOWNTO C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH)
          <= WR_PNTR_RD;
        adjusted_wr_pntr_r(C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH-1 DOWNTO 0) 
          <= (OTHERS => '0');
      END GENERATE gpad;
    
      gtrim : IF (C_RD_PNTR_WIDTH<=C_WR_PNTR_WIDTH)	GENERATE
        adjusted_wr_pntr_r 
          <= WR_PNTR_RD(C_WR_PNTR_WIDTH-1 DOWNTO C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH);
      END GENERATE gtrim;
    
      -----------------------------------------------------------------------------
      -- This accounts for preload 0 by explicitly handling the preload states
      -- which do not have both output stages filled. As a result, the rd_data_count
      -- produced will always accurately reflect the number of READABLE words at
      -- a given time.
      -----------------------------------------------------------------------------
    
      diff_wr_rd_tmp <= adjusted_wr_pntr_r - RD_PNTR;
      diff_wr_rd <= '0' & diff_wr_rd_tmp;
    
      prdc : PROCESS (RD_CLK, rd_rst_i)
      BEGIN
        IF (rd_rst_i = '1') THEN
          rdc_fwft_ext_as <= zero;
        ELSIF (RD_CLK'event AND RD_CLK = '1') THEN
          IF (stage2_valid = '0') THEN
            rdc_fwft_ext_as <= zero;
          ELSIF (stage2_valid = '1' AND stage1_valid = '0') THEN 
            rdc_fwft_ext_as <= one;
          ELSE
            rdc_fwft_ext_as <= diff_wr_rd + two;
          END IF;
        END IF;
      END PROCESS prdc;
    
    END GENERATE rdc_fwft_ext;
    
    -------------------------------------------------------------------------------
    -- Write pointer adjustment based on pointers width for EMPTY/ALMOST_EMPTY generation
    -------------------------------------------------------------------------------
    gpad : IF (C_RD_PNTR_WIDTH > C_WR_PNTR_WIDTH) GENERATE
      adj_wr_pntr_rd(C_RD_PNTR_WIDTH-1 DOWNTO C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH)
        <= wr_pntr_rd;
      adj_wr_pntr_rd(C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH-1 DOWNTO 0) 
        <= (OTHERS => '0');
    END GENERATE gpad;
 
    gtrim : IF (C_RD_PNTR_WIDTH<=C_WR_PNTR_WIDTH)	GENERATE
      adj_wr_pntr_rd 
        <= wr_pntr_rd(C_WR_PNTR_WIDTH-1 DOWNTO C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH);
    END GENERATE gtrim;
    
    -------------------------------------------------------------------------------
    -- Generate Empty
    -------------------------------------------------------------------------------
    -- ram_rd_en used to determine EMPTY should depend on the EMPTY.
    ram_rd_en <= RD_EN AND (NOT empty_comb);
    empty_int <= ((adj_wr_pntr_rd = rd_pntr) OR (ram_rd_en = '1' AND
                  (adj_wr_pntr_rd = conv_std_logic_vector((conv_integer(rd_pntr)+1),C_RD_PNTR_WIDTH))));
    
    -------------------------------------------------------------------------------
    -- Generate Almost Empty
    -------------------------------------------------------------------------------
    almost_empty_int <= ((adj_wr_pntr_rd = conv_std_logic_vector((conv_integer(rd_pntr)+1),C_RD_PNTR_WIDTH)) OR (ram_rd_en = '1' AND
                  (adj_wr_pntr_rd = conv_std_logic_vector((conv_integer(rd_pntr)+2),C_RD_PNTR_WIDTH))));
 
    -------------------------------------------------------------------------------
    -- Registering Empty & Almost Empty 
    -- Generate read data count if Use Extra Logic is not selected.
    -------------------------------------------------------------------------------
    empty_proc : PROCESS (RD_CLK, rd_rst_i)
    BEGIN
      IF (rd_rst_i = '1') THEN
        empty_comb             <= '1' AFTER C_TCQ;
        empty_comb_d1          <= '1' AFTER C_TCQ;
        ALMOST_EMPTY           <= '1' AFTER C_TCQ;
        rd_data_count_int      <= (OTHERS => '0') AFTER C_TCQ;
      ELSIF (RD_CLK'event AND RD_CLK = '1') THEN
        rd_data_count_int      <= ((adj_wr_pntr_rd(C_RD_PNTR_WIDTH-1 DOWNTO 0) - 
                                   rd_pntr(C_RD_PNTR_WIDTH-1 DOWNTO 0)) & '0') AFTER C_TCQ;
        empty_comb_d1          <= empty_comb AFTER C_TCQ;
        IF (empty_int) THEN
          empty_comb           <= '1' AFTER C_TCQ;
        ELSE
          empty_comb           <= '0' AFTER C_TCQ;
        END IF;
        IF (empty_comb = '0') THEN
          IF (almost_empty_int) THEN
            ALMOST_EMPTY       <= '1' AFTER C_TCQ;
          ELSE
            ALMOST_EMPTY       <= '0' AFTER C_TCQ;
          END IF;
        END IF;
      END IF;
    END PROCESS empty_proc;
 
    -------------------------------------------------------------------------------
    -- Read pointer adjustment based on pointers width for FULL/ALMOST_FULL generation
    -------------------------------------------------------------------------------
    gfpad : IF (C_WR_PNTR_WIDTH > C_RD_PNTR_WIDTH)	GENERATE
      adj_rd_pntr_wr
      (C_WR_PNTR_WIDTH-1 DOWNTO C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH)
        <= rd_pntr_wr;
      adj_rd_pntr_wr(C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH-1 DOWNTO 0)
        <= (OTHERS => '0');
    END GENERATE gfpad;
 
    gftrim : IF (C_WR_PNTR_WIDTH <= C_RD_PNTR_WIDTH) GENERATE 
      adj_rd_pntr_wr 
        <= rd_pntr_wr(C_RD_PNTR_WIDTH-1 DOWNTO C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH);
    END GENERATE gftrim;
 
    -------------------------------------------------------------------------------
    -- Generate Full
    -------------------------------------------------------------------------------
    -- ram_wr_en used to determine FULL should depend on the FULL.
    ram_wr_en <= WR_EN AND (NOT full_comb);
    full_int <= ((adj_rd_pntr_wr = conv_std_logic_vector((conv_integer(wr_pntr)+1),C_WR_PNTR_WIDTH)) OR (ram_wr_en = '1' AND
                  (adj_rd_pntr_wr = conv_std_logic_vector((conv_integer(wr_pntr)+2),C_WR_PNTR_WIDTH))));
    
    -------------------------------------------------------------------------------
    -- Generate Almost Full
    -------------------------------------------------------------------------------
    almost_full_int <= ((adj_rd_pntr_wr = conv_std_logic_vector((conv_integer(wr_pntr)+2),C_WR_PNTR_WIDTH)) OR (ram_wr_en = '1' AND
                  (adj_rd_pntr_wr = conv_std_logic_vector((conv_integer(wr_pntr)+3),C_WR_PNTR_WIDTH))));
 
    -------------------------------------------------------------------------------
    -- Registering Full & Almost Full
    -- Generate write data count if Use Extra Logic is not selected.
    -------------------------------------------------------------------------------
    full_proc : PROCESS (WR_CLK, RST_FULL_FF)
    BEGIN
      IF (RST_FULL_FF = '1') THEN
        full_comb              <= int_2_std_logic(C_FULL_FLAGS_RST_VAL) AFTER C_TCQ;
        ALMOST_FULL            <= int_2_std_logic(C_FULL_FLAGS_RST_VAL) AFTER C_TCQ;
      ELSIF (WR_CLK'event AND WR_CLK = '1') THEN
        IF (full_int) THEN
          full_comb  <= '1' AFTER C_TCQ;
        ELSE
          full_comb  <= '0' AFTER C_TCQ;
        END IF;
        IF (RST_FULL_GEN = '1') THEN
          ALMOST_FULL     <= '0' AFTER C_TCQ;
        ELSIF (full_comb = '0') THEN
          IF (almost_full_int) THEN
            ALMOST_FULL   <= '1' AFTER C_TCQ;
          ELSE
            ALMOST_FULL   <= '0' AFTER C_TCQ;
          END IF;
        END IF;
      END IF;
    END PROCESS full_proc;

    wdci_proc : PROCESS (WR_CLK, wr_rst_i)
    BEGIN
      IF (wr_rst_i = '1') THEN
        wr_data_count_int      <= (OTHERS => '0') AFTER C_TCQ;
      ELSIF (WR_CLK'event AND WR_CLK = '1') THEN
        wr_data_count_int      <= ((wr_pntr(C_WR_PNTR_WIDTH-1 DOWNTO 0) -
                                  adj_rd_pntr_wr(C_WR_PNTR_WIDTH-1 DOWNTO 0)) & '0') AFTER C_TCQ;
      END IF;
    END PROCESS wdci_proc;

    -------------------------------------------------------------------------------
    -- Counter that determines the FWFT read duration.
    -------------------------------------------------------------------------------
    -- C_PRELOAD_LATENCY will be 0 for Non-Built-in FIFO with FWFT.
    grd_fwft: IF (C_PRELOAD_LATENCY = 0) GENERATE
      SIGNAL user_empty_fb_d1 : std_logic := '1';
    BEGIN
      grd_fwft_proc : PROCESS (RD_CLK, rd_rst_i)
      BEGIN
        IF (rd_rst_i = '1') THEN
          rd_fwft_cnt <= (others => '0');
          user_empty_fb_d1 <= '1';
          stage1_valid    <= '0';
          stage2_valid    <= '0';
        ELSIF (RD_CLK'event AND RD_CLK = '1') THEN
          user_empty_fb_d1 <= USER_EMPTY_FB;
          IF (user_empty_fb_d1 = '0' AND USER_EMPTY_FB = '1') THEN
            rd_fwft_cnt <= (others => '0') AFTER C_TCQ;
          ELSIF (empty_comb = '0') THEN
            IF (RD_EN = '1' AND rd_fwft_cnt < X"5") THEN
              rd_fwft_cnt <= rd_fwft_cnt + "1" AFTER C_TCQ;
            END IF;
          END IF;
 
          IF (stage1_valid = '0' AND stage2_valid = '0') THEN
            IF (empty_comb = '0') THEN
              stage1_valid    <= '1' AFTER C_TCQ;
            ELSE
              stage1_valid    <= '0' AFTER C_TCQ;
            END IF;
          ELSIF (stage1_valid = '1' AND stage2_valid = '0') THEN
            IF (empty_comb = '1') THEN
              stage1_valid    <= '0' AFTER C_TCQ;
              stage2_valid    <= '1' AFTER C_TCQ;
            ELSE
              stage1_valid    <= '1' AFTER C_TCQ;
              stage2_valid    <= '1' AFTER C_TCQ;
            END IF;
          ELSIF (stage1_valid = '0' AND stage2_valid = '1') THEN
            IF (empty_comb = '1' AND RD_EN_USER = '1') THEN
              stage1_valid    <= '0' AFTER C_TCQ;
              stage2_valid    <= '0' AFTER C_TCQ;
            ELSIF (empty_comb = '0' AND RD_EN_USER = '1') THEN
              stage1_valid    <= '1' AFTER C_TCQ;
              stage2_valid    <= '0' AFTER C_TCQ;
            ELSIF (empty_comb = '0' AND RD_EN_USER = '0') THEN
              stage1_valid    <= '1' AFTER C_TCQ;
              stage2_valid    <= '1' AFTER C_TCQ;
            ELSE
              stage1_valid    <= '0' AFTER C_TCQ;
              stage2_valid    <= '1' AFTER C_TCQ;
            END IF;
          ELSIF (stage1_valid = '1' AND stage2_valid = '1') THEN
            IF (empty_comb = '1' AND RD_EN_USER = '1') THEN
              stage1_valid    <= '0' AFTER C_TCQ;
              stage2_valid    <= '1' AFTER C_TCQ;
            ELSE
              stage1_valid    <= '1' AFTER C_TCQ;
              stage2_valid    <= '1' AFTER C_TCQ;
            END IF;
          ELSE
            stage1_valid    <= '0' AFTER C_TCQ;
            stage2_valid    <= '0' AFTER C_TCQ;
          END IF;
 
        END IF;
      END PROCESS grd_fwft_proc;
    END GENERATE grd_fwft;
 
    gnrd_fwft: IF (C_PRELOAD_LATENCY > 0) GENERATE 
          rd_fwft_cnt <= X"2";
    END GENERATE gnrd_fwft;
    
    -------------------------------------------------------------------------------
    -- Assign FULL, EMPTY, ALMOST_FULL and ALMOST_EMPTY
    -------------------------------------------------------------------------------
    FULL          <= full_comb;
    EMPTY         <= empty_comb;
 
    -------------------------------------------------------------------------------
    -- Asynchronous FIFO using linked lists
    -------------------------------------------------------------------------------
 
 
    FIFO_PROC : PROCESS (WR_CLK, RD_CLK, rd_rst_i, wr_rst_i)
 
      --Declare the linked-list head/tail pointers and the size value
      VARIABLE head              : listptr;
      VARIABLE tail              : listptr;
      VARIABLE size              : integer := 0;
      VARIABLE cntr              : integer := 0;
      VARIABLE cntr_size_var_int : integer := 0;
 
      --Data is the internal version of the DOUT bus
      VARIABLE data : std_logic_vector(c_dout_width - 1 DOWNTO 0) 
        := hexstr_to_std_logic_vec( C_DOUT_RST_VAL, c_dout_width);
      VARIABLE err_type : std_logic_vector(1 DOWNTO 0) := (OTHERS => '0'); 
 
      --Temporary values for calculating adjusted prog_empty/prog_full thresholds
      VARIABLE prog_empty_actual_assert_thresh : integer := 0;
      VARIABLE prog_empty_actual_negate_thresh : integer := 0;
      VARIABLE prog_full_actual_assert_thresh : integer := 0;
      VARIABLE prog_full_actual_negate_thresh : integer := 0;
      VARIABLE diff_pntr                      : integer := 0;
    
    BEGIN
 
      -- Calculate the current contents of the FIFO (size)
      -- Warning: This value should only be calculated once each time this
      -- process is entered.
      -- It is updated instantaneously for both write and read operations,
      -- so it is not ideal to use for signals which must consider the
      -- latency of crossing clock domains.
 
      -- cntr_size_var_int is updated only once when the process is entered
      -- This variable is used in the conditions instead of cntr which has the
      -- latest value.
      cntr_size_var_int := cntr;
 
 
      -- RESET CONDITIONS
      IF wr_rst_i = '1' THEN
    
        wr_point           <= 0 after C_TCQ;
        wr_point_d1        <= 0 after C_TCQ;
        wr_pntr_rd1        <= (OTHERS => '0') after C_TCQ;
        rd_pntr_wr         <= (OTHERS => '0') after C_TCQ;
        rd_pntr_q          <= (OTHERS => (OTHERS => '0')) after C_TCQ;
    
        --Create new linked list
        newlist(head, tail,cntr);
 
        diff_pntr         := 0;
    
      ---------------------------------------------------------------------------
      -- Write to FIFO
      ---------------------------------------------------------------------------
      ELSIF WR_CLK'event AND WR_CLK = '1' THEN
        rd_pntr_q       <= rd_pntr_q(C_SYNCHRONIZER_STAGE-2 downto 0) & rd_pntr_wr_d1;
        -- Delay the write pointer before passing to RD_CLK domain to accommodate
        -- the binary to gray converion
        wr_pntr_rd1     <= wr_pntr after C_TCQ;
        rd_pntr_wr      <= rd_pntr_q(C_SYNCHRONIZER_STAGE-1) after C_TCQ;
 
        wr_point_d1 <= wr_point after C_TCQ;
    
        --The following IF statement setup default values of full_i and almost_full_i.
        --The values might be overwritten in the next IF statement.
          --If writing, then it is not possible to predict how many
          --words will actually be in the FIFO after the write concludes
          --(because the number of reads which happen in this time can
          -- not be determined).
          --Therefore, treat it pessimistically and always assume that
          -- the write will happen without a read (assume the FIFO is
          -- C_DEPTH_RATIO_RD fuller than it is).
          --Note:
          --1. cntr_size_var_int is the deepest depth between write depth and read depth
          --   cntr_size_var_int/C_DEPTH_RATIO_RD is number of words in the write domain.
          --2. cntr_size_var_int+C_DEPTH_RATIO_RD: number of write words in the next clock cycle
          --   if wr_en=1 (C_DEPTH_RATIO_RD=one write word)
          --3. For asymmetric FIFO, if write width is narrower than read width. Don't
          --   have to consider partial words.
          --4. For asymmetric FIFO, if read width is narrower than write width,
          --   the worse case that FIFO is going to full is depicted in the following 
          --   diagram. Both rd_pntr_a and rd_pntr_b will cause FIFO full. rd_pntr_a
          --   is the worse case. Therefore, in the calculation, actual FIFO depth is
          --   substarcted to one write word and added one read word.
          --              -------
          --              |  |  |
          --    wr_pntr-->|  |---
          --              |  |  |
          --              ---|---
          --              |  |  |
          --              |  |---
          --              |  |  |
          --              ---|---
          --              |  |  |<--rd_pntr_a
          --              |  |---
          --              |  |  |<--rd_pntr_b
          --              ---|---
          
    
        -- Update full_i and almost_full_i if user is writing to the FIFO.
        -- Assign overflow and wr_ack.
        IF WR_EN = '1' THEN
    
          IF full_comb /= '1' THEN
          -- User is writing to a FIFO which is NOT reporting FULL
    
            IF cntr_size_var_int/C_DEPTH_RATIO_RD = C_FIFO_WR_DEPTH THEN
              -- FIFO really is Full
              --Report Overflow and do not acknowledge the write
    
            ELSIF cntr_size_var_int/C_DEPTH_RATIO_RD + 1 = C_FIFO_WR_DEPTH THEN
              -- FIFO is almost full
              -- This write will succeed, and FIFO will go FULL
              FOR h IN C_DEPTH_RATIO_RD DOWNTO 1 LOOP
                add(head, tail, 
                DIN((C_SMALLER_DATA_WIDTH*h)-1 DOWNTO C_SMALLER_DATA_WIDTH*(h-1)),cntr,
                (width_gt1 & INJECTDBITERR & INJECTSBITERR));
              END LOOP;
              wr_point   <= (wr_point + 1) MOD C_WR_DEPTH after C_TCQ;
    
            ELSIF cntr_size_var_int/C_DEPTH_RATIO_RD + 2 = C_FIFO_WR_DEPTH THEN
              -- FIFO is one away from almost full
              -- This write will succeed, and FIFO will go almost_full_i
              FOR h IN C_DEPTH_RATIO_RD DOWNTO 1 LOOP
                add(head, tail, 
                DIN((C_SMALLER_DATA_WIDTH*h)-1 DOWNTO C_SMALLER_DATA_WIDTH*(h-1)),cntr,
                (width_gt1 & INJECTDBITERR & INJECTSBITERR));
              END LOOP;
              wr_point    <= (wr_point + 1) MOD C_WR_DEPTH after C_TCQ;
    
            ELSE
              -- FIFO is no where near FULL
              --Write will succeed, no change in status
              FOR h IN C_DEPTH_RATIO_RD DOWNTO 1 LOOP
                add(head, tail, 
                DIN((C_SMALLER_DATA_WIDTH*h)-1 DOWNTO C_SMALLER_DATA_WIDTH*(h-1)),cntr,
                (width_gt1 & INJECTDBITERR & INJECTSBITERR));
              END LOOP;
              wr_point   <= (wr_point + 1) MOD C_WR_DEPTH after C_TCQ;
            END IF;
    
          ELSE --IF full_i = '1'
            -- User is writing to a FIFO which IS reporting FULL
            --Write will fail
          END IF;  --full_i
    
        ELSE                              --WR_EN/='1'
          --No write attempted, so neither overflow or acknowledge
        END IF;  --WR_EN
    
      END IF;  --WR_CLK
    
      ---------------------------------------------------------------------------
      -- Read from FIFO
      ---------------------------------------------------------------------------
 
      IF rd_rst_i = '1' THEN
        -- Whenever user is attempting to read from
        -- an EMPTY FIFO, the core should report an underflow error, even if
        -- the core is in a RESET condition.
    
        rd_point          <= 0 after C_TCQ;
        rd_point_d1       <= 0 after C_TCQ;
        rd_pntr_wr_d1    <= (OTHERS => '0') after C_TCQ;
        wr_pntr_rd       <= (OTHERS => '0') after C_TCQ;
        wr_pntr_q          <= (OTHERS => (OTHERS => '0')) after C_TCQ;
    
        -- DRAM resets asynchronously
        IF (C_MEMORY_TYPE = 2 AND C_USE_DOUT_RST = 1) THEN
          data := hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH);
        END IF;
    
        -- BRAM resets synchronously
        IF (C_MEMORY_TYPE < 2 AND C_USE_DOUT_RST = 1) THEN
          IF (RD_CLK'event AND RD_CLK = '1') THEN
            data := hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH);
          END IF;
        END IF;
 
        -- Reset only if ECC is not selected as ECC does not support reset.
        IF (C_USE_ECC = 0) THEN
          err_type        := (OTHERS => '0');
        END IF ;
    
      ELSIF RD_CLK'event AND RD_CLK = '1' THEN
        wr_pntr_q       <= wr_pntr_q(C_SYNCHRONIZER_STAGE-2 downto 0) & wr_pntr_rd1;
 
        -- Delay the read pointer before passing to WR_CLK domain to accommodate
        -- the binary to gray converion
        rd_pntr_wr_d1 <= rd_pntr after C_TCQ;
        wr_pntr_rd    <= wr_pntr_q(C_SYNCHRONIZER_STAGE-1) after C_TCQ;
 
        rd_point_d1 <= rd_point after C_TCQ;
        
        
        ---------------------------------------------------------------------------
        -- Read Latency 1
        ---------------------------------------------------------------------------
    
        --The following IF statement setup default values of empty_i and 
        --almost_empty_i. The values might be overwritten in the next IF statement.
        --Note:
        --cntr_size_var_int/C_DEPTH_RATIO_WR : number of words in read domain.
 
        IF (ram_rd_en = '1') THEN
    
          IF empty_comb /= '1' THEN
            IF cntr_size_var_int/C_DEPTH_RATIO_WR = 2 THEN
              --FIFO is going almost empty
              FOR h IN C_DEPTH_RATIO_WR DOWNTO 1 LOOP
                read(tail, 
                data((C_SMALLER_DATA_WIDTH*h)-1 DOWNTO C_SMALLER_DATA_WIDTH*(h-1)),
                err_type);
                remove(head, tail,cntr);
              END LOOP;
              rd_point     <= (rd_point + 1) MOD C_RD_DEPTH after C_TCQ;
            
            ELSIF cntr_size_var_int/C_DEPTH_RATIO_WR = 1 THEN
              --FIFO is going empty
              FOR h IN C_DEPTH_RATIO_WR DOWNTO 1 LOOP
                read(tail, 
                data((C_SMALLER_DATA_WIDTH*h)-1 DOWNTO C_SMALLER_DATA_WIDTH*(h-1)),
                err_type);
                remove(head, tail,cntr);
              END LOOP;
              rd_point     <= (rd_point + 1) MOD C_RD_DEPTH after C_TCQ;
    
            ELSIF cntr_size_var_int/C_DEPTH_RATIO_WR = 0 THEN
            --FIFO is empty
    
            ELSE
            --FIFO is not empty
              FOR h IN C_DEPTH_RATIO_WR DOWNTO 1 LOOP
                read(tail, 
                data((C_SMALLER_DATA_WIDTH*h)-1 DOWNTO C_SMALLER_DATA_WIDTH*(h-1)),
                err_type);
                remove(head, tail,cntr);
              END LOOP;
              rd_point     <= (rd_point + 1) MOD C_RD_DEPTH after C_TCQ;
            END IF;
          ELSE
            --FIFO is empty
          END IF;
    
        END IF;  --RD_EN
    
      END IF;  --RD_CLK
    
      dout_i    <= data after C_TCQ;
      sbiterr_i <= err_type(0) after C_TCQ;
      dbiterr_i <= err_type(1) after C_TCQ;
    
    END PROCESS;
    
    -----------------------------------------------------------------------------
    -- Programmable FULL flags
    -----------------------------------------------------------------------------
    proc_pf_input: PROCESS(PROG_FULL_THRESH, PROG_FULL_THRESH_ASSERT,PROG_FULL_THRESH_NEGATE)
    BEGIN
      IF (C_PRELOAD_REGS = 1 AND C_PRELOAD_LATENCY = 0) THEN -- FWFT
        IF (C_PROG_FULL_TYPE = 3) THEN -- Single threshold input
          pf_input_thr_assert_val <= PROG_FULL_THRESH - conv_integer(EXTRA_WORDS_DC);
        ELSE -- Multiple threshold inputs
          pf_input_thr_assert_val <= PROG_FULL_THRESH_ASSERT - conv_std_logic_vector(EXTRA_WORDS_DC,C_WR_PNTR_WIDTH);
          pf_input_thr_negate_val <= PROG_FULL_THRESH_NEGATE - conv_std_logic_vector(EXTRA_WORDS_DC,C_WR_PNTR_WIDTH);
        END IF;
      ELSE -- STD
        IF (C_PROG_FULL_TYPE = 3) THEN -- Single threshold input
          pf_input_thr_assert_val <= PROG_FULL_THRESH;
        ELSE -- Multiple threshold inputs
          pf_input_thr_assert_val <= PROG_FULL_THRESH_ASSERT;
          pf_input_thr_negate_val <= PROG_FULL_THRESH_NEGATE;
        END IF;
      END IF;
    END PROCESS proc_pf_input;
 
    proc_wdc: PROCESS(WR_CLK, wr_rst_i)
    BEGIN
      IF (wr_rst_i = '1') THEN
        diff_pntr_wr       <= 0;
      ELSIF (WR_CLK'event AND WR_CLK = '1') THEN
 
        IF (ram_wr_en = '0') THEN
          diff_pntr_wr <= conv_integer(wr_pntr - adj_rd_pntr_wr) after C_TCQ;
        ELSIF (ram_wr_en = '1') THEN
          diff_pntr_wr <= conv_integer(wr_pntr - adj_rd_pntr_wr) + 1 after C_TCQ;
        END IF;
      END IF;  -- WR_CLK
    END PROCESS proc_wdc;
 
    proc_pf: PROCESS(WR_CLK, RST_FULL_FF)
    BEGIN
 
      IF (RST_FULL_FF = '1') THEN
        prog_full_reg      <= int_2_std_logic(C_FULL_FLAGS_RST_VAL);
      ELSIF (WR_CLK'event AND WR_CLK = '1') THEN
 
        IF (RST_FULL_GEN = '1') THEN
          prog_full_reg <= '0' after C_TCQ;
        ELSIF (C_PROG_FULL_TYPE = 1) THEN
          IF (full_comb = '0') THEN
            IF (diff_pntr_wr >= C_PF_THR_ASSERT_ADJUSTED) THEN
              prog_full_reg <= '1' after C_TCQ;
            ELSE
              prog_full_reg <= '0' after C_TCQ;
            END IF;
          ELSE
            prog_full_reg   <= prog_full_reg after C_TCQ;
          END IF;  
        ELSIF (C_PROG_FULL_TYPE = 2) THEN
          IF (full_comb = '0') THEN
            IF (diff_pntr_wr >= C_PF_THR_ASSERT_ADJUSTED) THEN
              prog_full_reg <= '1' after C_TCQ;
            ELSIF (diff_pntr_wr < C_PF_THR_NEGATE_ADJUSTED) THEN
              prog_full_reg <= '0' after C_TCQ;
            ELSE
              prog_full_reg <= prog_full_reg after C_TCQ;
            END IF;
          ELSE
            prog_full_reg   <= prog_full_reg after C_TCQ;
          END IF;  
        ELSIF (C_PROG_FULL_TYPE = 3) THEN
          IF (full_comb = '0') THEN
            IF (diff_pntr_wr >= conv_integer(pf_input_thr_assert_val)) THEN
              prog_full_reg <= '1' after C_TCQ;
            ELSE
              prog_full_reg <= '0' after C_TCQ;
            END IF;
          ELSE
            prog_full_reg   <= prog_full_reg after C_TCQ;
          END IF;  
        ELSIF (C_PROG_FULL_TYPE = 4) THEN
          IF (full_comb = '0') THEN
            IF (diff_pntr_wr >= conv_integer(pf_input_thr_assert_val)) THEN
              prog_full_reg <= '1' after C_TCQ;
            ELSIF (diff_pntr_wr < conv_integer(pf_input_thr_negate_val)) THEN
              prog_full_reg <= '0' after C_TCQ;
            ELSE
              prog_full_reg <= prog_full_reg after C_TCQ;
            END IF;
          ELSE
            prog_full_reg   <= prog_full_reg after C_TCQ;
          END IF;  
        END IF;  --C_PROG_FULL_TYPE
      END IF;  -- WR_CLK
    END PROCESS proc_pf;
 
    
    ---------------------------------------------------------------------------
    -- Programmable EMPTY Flags
    ---------------------------------------------------------------------------
 
    proc_pe: PROCESS(RD_CLK, rd_rst_i)
      VARIABLE pe_thr_assert_val  : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      VARIABLE pe_thr_negate_val  : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    BEGIN
      IF (rd_rst_i = '1') THEN
        diff_pntr_rd       <= 0;
        prog_empty_reg     <= '1';
        pe_thr_assert_val  := (OTHERS => '0');
        pe_thr_negate_val  := (OTHERS => '0');
      ELSIF (RD_CLK'event AND RD_CLK = '1') THEN
        IF (ram_rd_en = '0') THEN
          diff_pntr_rd     <= conv_integer(adj_wr_pntr_rd - rd_pntr) after C_TCQ;
        ELSIF (ram_rd_en = '1') THEN
          diff_pntr_rd     <= conv_integer(adj_wr_pntr_rd - rd_pntr) - 1 after C_TCQ;
        ELSE
          diff_pntr_rd     <= diff_pntr_rd after C_TCQ;
        END IF;
 
        IF (C_PROG_EMPTY_TYPE = 1) THEN
          IF (empty_comb = '0') THEN
            IF (diff_pntr_rd <= C_PE_THR_ASSERT_VAL_I) THEN
              prog_empty_reg <= '1' after C_TCQ;
            ELSE
              prog_empty_reg <= '0' after C_TCQ;
            END IF;
          ELSE
            prog_empty_reg   <= prog_empty_reg after C_TCQ;
          END IF;  
        ELSIF (C_PROG_EMPTY_TYPE = 2) THEN
          IF (empty_comb = '0') THEN
            IF (diff_pntr_rd <= C_PE_THR_ASSERT_VAL_I) THEN
              prog_empty_reg <= '1' after C_TCQ;
            ELSIF (diff_pntr_rd > C_PE_THR_NEGATE_VAL_I) THEN
              prog_empty_reg <= '0' after C_TCQ;
            ELSE
              prog_empty_reg <= prog_empty_reg after C_TCQ;
            END IF;
          ELSE
            prog_empty_reg   <= prog_empty_reg after C_TCQ;
          END IF;  
        ELSIF (C_PROG_EMPTY_TYPE = 3) THEN
 
          -- If empty input threshold is selected, then subtract 2 for FWFT to
          -- compensate the FWFT stage, otherwise assign the input value.
          IF (C_PRELOAD_REGS = 1 AND C_PRELOAD_LATENCY = 0) THEN -- FWFT
            pe_thr_assert_val := PROG_EMPTY_THRESH - "10";
          ELSE
            pe_thr_assert_val := PROG_EMPTY_THRESH;
          END IF;  
 
          IF (empty_comb = '0') THEN
            IF (diff_pntr_rd <= pe_thr_assert_val) THEN
              prog_empty_reg <= '1' after C_TCQ;
            ELSE
              prog_empty_reg <= '0' after C_TCQ;
            END IF;
          ELSE
            prog_empty_reg   <= prog_empty_reg after C_TCQ;
          END IF;  
        ELSIF (C_PROG_EMPTY_TYPE = 4) THEN
 
          -- If empty input threshold is selected, then subtract 2 for FWFT to
          -- compensate the FWFT stage, otherwise assign the input value.
          IF (C_PRELOAD_REGS = 1 AND C_PRELOAD_LATENCY = 0) THEN -- FWFT
            pe_thr_assert_val := PROG_EMPTY_THRESH_ASSERT - "10";
            pe_thr_negate_val := PROG_EMPTY_THRESH_NEGATE - "10";
          ELSE
            pe_thr_assert_val := PROG_EMPTY_THRESH_ASSERT;
            pe_thr_negate_val := PROG_EMPTY_THRESH_NEGATE;
          END IF;  
 
          IF (empty_comb = '0') THEN
            IF (diff_pntr_rd <= conv_integer(pe_thr_assert_val)) THEN
              prog_empty_reg <= '1' after C_TCQ;
            ELSIF (diff_pntr_rd > conv_integer(pe_thr_negate_val)) THEN
              prog_empty_reg <= '0' after C_TCQ;
            ELSE
              prog_empty_reg <= prog_empty_reg after C_TCQ;
            END IF;
          ELSE
            prog_empty_reg   <= prog_empty_reg after C_TCQ;
          END IF;  
        END IF;  --C_PROG_EMPTY_TYPE
      END IF;  -- RD_CLK
    END PROCESS proc_pe;
 
    -----------------------------------------------------------------------------
    -- overflow_i generation: Asynchronous FIFO
    -----------------------------------------------------------------------------
    govflw: IF (C_HAS_OVERFLOW = 1) GENERATE
      g7s_ovflw: IF (NOT (C_FAMILY = "virtexu" OR C_FAMILY = "kintexu" OR C_FAMILY = "artixu" OR C_FAMILY = "virtexuplus" OR C_FAMILY = "zynquplus" OR C_FAMILY = "kintexuplus")) GENERATE
        povflw: PROCESS (WR_CLK)
        BEGIN
          IF WR_CLK'event AND WR_CLK = '1' THEN
             overflow_i  <= full_comb AND WR_EN after C_TCQ;
          END IF;
        END PROCESS povflw;
      END GENERATE g7s_ovflw;
      g8s_ovflw: IF ((C_FAMILY = "virtexu" OR C_FAMILY = "kintexu" OR C_FAMILY = "artixu" OR C_FAMILY = "virtexuplus" OR C_FAMILY = "zynquplus" OR C_FAMILY = "kintexuplus")) GENERATE
        povflw: PROCESS (WR_CLK)
        BEGIN
          IF WR_CLK'event AND WR_CLK = '1' THEN
             --overflow_i  <= (wr_rst_i OR full_comb) AND WR_EN after C_TCQ;
             overflow_i  <= (full_comb) AND WR_EN after C_TCQ;
          END IF;
        END PROCESS povflw;
      END GENERATE g8s_ovflw;
    END GENERATE govflw;
 
    -----------------------------------------------------------------------------
    -- underflow_i generation: Asynchronous FIFO
    -----------------------------------------------------------------------------
    gunflw: IF (C_HAS_UNDERFLOW = 1) GENERATE
      g7s_unflw: IF (NOT (C_FAMILY = "virtexu" OR C_FAMILY = "kintexu" OR C_FAMILY = "artixu" OR C_FAMILY = "virtexuplus" OR C_FAMILY = "zynquplus" OR C_FAMILY = "kintexuplus")) GENERATE
        punflw: PROCESS (RD_CLK)
        BEGIN
          IF RD_CLK'event AND RD_CLK = '1' THEN
            underflow_i <= empty_comb and RD_EN after C_TCQ;
          END IF;
        END PROCESS punflw;
      END GENERATE g7s_unflw;
      g8s_unflw: IF ((C_FAMILY = "virtexu" OR C_FAMILY = "kintexu" OR C_FAMILY = "artixu" OR C_FAMILY = "virtexuplus" OR C_FAMILY = "zynquplus" OR C_FAMILY = "kintexuplus")) GENERATE
        punflw: PROCESS (RD_CLK)
        BEGIN
          IF RD_CLK'event AND RD_CLK = '1' THEN
            --underflow_i <= (rd_rst_i OR empty_comb) and RD_EN after C_TCQ;
            underflow_i <= (empty_comb) and RD_EN after C_TCQ;
          END IF;
        END PROCESS punflw;
      END GENERATE g8s_unflw;
    END GENERATE gunflw;
 
    -----------------------------------------------------------------------------
    -- wr_ack_i generation: Asynchronous FIFO
    -----------------------------------------------------------------------------  
    gwack: IF (C_HAS_WR_ACK = 1) GENERATE
      pwack: PROCESS (WR_CLK,wr_rst_i)
      BEGIN
        IF wr_rst_i = '1' THEN
          wr_ack_i           <= '0' after C_TCQ;
        ELSIF WR_CLK'event AND WR_CLK = '1' THEN
          wr_ack_i     <= '0' after C_TCQ;
          IF WR_EN = '1' THEN
            IF full_comb /= '1' THEN
              wr_ack_i <= '1' after C_TCQ;
            END IF;
          END IF;
        END IF;
      END PROCESS pwack;
    END GENERATE gwack;
 
    ----------------------------------------------------------------------------
    -- valid_i generation: Asynchronous FIFO
    ---------------------------------------------------------------------------- 
   gvld_i: IF (C_HAS_VALID = 1) GENERATE
 
      PROCESS (rd_rst_i  , RD_CLK  )
      BEGIN
        IF rd_rst_i = '1' THEN
          valid_i           <= '0' after C_TCQ;
        ELSIF RD_CLK'event AND RD_CLK = '1' THEN
          valid_i     <= '0' after C_TCQ;
          IF RD_EN = '1' THEN
            IF empty_comb /= '1' THEN
              valid_i <= '1' after C_TCQ;
            END IF;
          END IF;
        END IF;
      END PROCESS;
 
      -----------------------------------------------------------------
      -- Delay valid_d1
      --if C_MEMORY_TYPE=0 or 1, C_USE_EMBEDDED_REG=1
      -----------------------------------------------------------------
 
      gv0_as: IF (C_USE_EMBEDDED_REG>0
               AND (C_MEMORY_TYPE=0 OR C_MEMORY_TYPE=1)) GENERATE
        PROCESS (rd_rst_i  , RD_CLK  )
        BEGIN
          IF rd_rst_i = '1' THEN
            valid_d1          <= '0' after C_TCQ;
          ELSIF RD_CLK'event AND RD_CLK = '1' THEN
            valid_d1    <= valid_i after C_TCQ;
          END IF;
        END PROCESS;
      END GENERATE gv0_as;
 
      gv1_as: IF NOT (C_USE_EMBEDDED_REG>0
               AND (C_MEMORY_TYPE=0 OR C_MEMORY_TYPE=1)) GENERATE
        valid_d1 <= valid_i;
      END GENERATE gv1_as;
 
 
  END GENERATE gvld_i;
 
 
 
    -----------------------------------------------------------------------------
    --Use delayed Valid AND DOUT if we have a LATENCY=2 configurations
    --  ( if C_MEMORY_TYPE=0 or 1, C_PRELOAD_REGS=0, C_USE_EMBEDDED_REG=1 )
    --Otherwise, connect the valid and DOUT values up directly, with no
    --additional latency.
    -----------------------------------------------------------------------------
    gv0: IF (C_PRELOAD_LATENCY=2 
             AND (C_MEMORY_TYPE=0 OR C_MEMORY_TYPE=1)AND C_EN_SAFETY_CKT =0) GENERATE
 
      gv1: IF (C_HAS_VALID = 1) GENERATE
        valid_out <= valid_d1;
      END GENERATE gv1;
 
      PROCESS (rd_rst_i  , RD_CLK  )
      BEGIN
        IF (rd_rst_i   = '1') THEN
          -- BRAM resets synchronously
          IF (C_USE_DOUT_RST = 1) THEN
            IF (RD_CLK  'event AND RD_CLK   = '1') THEN
              DOUT     <= hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH) after C_TCQ;
            END IF;
          END IF;
          IF (C_USE_ECC = 0) THEN
            SBITERR  <= '0' after C_TCQ;
            DBITERR  <= '0' after C_TCQ;
          END IF;
          ram_rd_en_d1 <= '0' after C_TCQ;
        ELSIF (RD_CLK  'event AND RD_CLK   = '1') THEN
          ram_rd_en_d1 <= ram_rd_en after C_TCQ;
          IF (ram_rd_en_d1 = '1') THEN
            DOUT     <= dout_i after C_TCQ;
            SBITERR  <= sbiterr_i after C_TCQ;
            DBITERR  <= dbiterr_i after C_TCQ;
          END IF;
        END IF;
      END PROCESS;
    END GENERATE gv0;

      gv0_safety: IF (C_PRELOAD_LATENCY=2 
             AND (C_MEMORY_TYPE=0 OR C_MEMORY_TYPE=1) AND C_EN_SAFETY_CKT =1) GENERATE
     SIGNAL dout_rst_val_d1 : std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
     SIGNAL dout_rst_val_d2 : std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
     SIGNAL rst_delayed_sft1 : std_logic := '1';
     SIGNAL rst_delayed_sft2 : std_logic := '1';
     SIGNAL rst_delayed_sft3 : std_logic := '1';
     SIGNAL rst_delayed_sft4 : std_logic := '1';
     BEGIN
 
      gv1: IF (C_HAS_VALID = 1) GENERATE
        valid_out <= valid_d1;
      END GENERATE gv1;
 
      PROCESS ( RD_CLK  )
      BEGIN
	rst_delayed_sft1 <= rd_rst_i;
	rst_delayed_sft2 <= rst_delayed_sft1;
	rst_delayed_sft3 <= rst_delayed_sft2;
	rst_delayed_sft4 <= rst_delayed_sft3;
      END PROCESS;

      PROCESS (rst_delayed_sft4  ,rd_rst_i, RD_CLK  )
      BEGIN
        IF (rst_delayed_sft4   = '1' OR rd_rst_i = '1') THEN
          ram_rd_en_d1 <= '0' after C_TCQ;
        ELSIF (RD_CLK  'event AND RD_CLK   = '1') THEN
          ram_rd_en_d1 <= ram_rd_en after C_TCQ;
        END IF;
      END PROCESS;

      PROCESS (rst_delayed_sft4  , RD_CLK  )
      BEGIN
        IF (rst_delayed_sft4   = '1' ) THEN
          -- BRAM resets synchronously
          IF (C_USE_DOUT_RST = 1) THEN
            IF (RD_CLK  'event AND RD_CLK   = '1') THEN
              DOUT     <= hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH) after C_TCQ;
            END IF;
          END IF;
          IF (C_USE_ECC = 0) THEN
            SBITERR  <= '0' after C_TCQ;
            DBITERR  <= '0' after C_TCQ;
          END IF;
          --ram_rd_en_d1 <= '0' after C_TCQ;
        ELSIF (RD_CLK  'event AND RD_CLK   = '1') THEN
          --ram_rd_en_d1 <= ram_rd_en after C_TCQ;
          IF (ram_rd_en_d1 = '1') THEN
            DOUT     <= dout_i after C_TCQ;
            SBITERR  <= sbiterr_i after C_TCQ;
            DBITERR  <= dbiterr_i after C_TCQ;
          END IF;
        END IF;
      END PROCESS;
    END GENERATE gv0_safety;

    
 
    gv1_nsafety: IF (NOT (C_PRELOAD_LATENCY=2 
                AND (C_MEMORY_TYPE=0 OR C_MEMORY_TYPE=1)) ) GENERATE
      gv2a: IF (C_HAS_VALID = 1) GENERATE
        valid_out <= valid_i;
      END GENERATE gv2a;
 
      DOUT     <= dout_i;
      SBITERR  <= sbiterr_i after C_TCQ;
      DBITERR  <= dbiterr_i after C_TCQ;
    END GENERATE gv1_nsafety;


  END GENERATE gnll_afifo;

  -------------------------------------------------------------------------------
  -- Low Latency Asynchronous FIFO
  -------------------------------------------------------------------------------
  gll_afifo: IF (C_FIFO_TYPE = 3) GENERATE
    TYPE mem_array IS ARRAY (0 TO C_WR_DEPTH-1) OF STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
    SIGNAL memory                    : mem_array := (OTHERS => (OTHERS => '0'));
    SIGNAL write_allow               : std_logic := '0'; 
    SIGNAL read_allow                : std_logic := '0'; 
    SIGNAL wr_pntr_ll_afifo          : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL rd_pntr_ll_afifo          : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL rd_pntr_ll_afifo_q        : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL ll_afifo_full             : std_logic := '0'; 
    SIGNAL ll_afifo_empty            : std_logic := '1'; 
    SIGNAL wr_pntr_eq_rd_pntr        : std_logic := '0'; 
    SIGNAL wr_pntr_eq_rd_pntr_plus1  : std_logic := '0'; 
    SIGNAL rd_pntr_eq_wr_pntr_plus1  : std_logic := '0'; 
    SIGNAL rd_pntr_eq_wr_pntr_plus2  : std_logic := '0'; 
  BEGIN
    wr_rst_i <= WR_RST;
    rd_rst_i <= RD_RST;

    write_allow <= WR_EN AND (NOT ll_afifo_full);
    read_allow  <= RD_EN AND (NOT ll_afifo_empty);
  
    wrptr_proc : PROCESS (WR_CLK,wr_rst_i)
    BEGIN
      IF (wr_rst_i = '1') THEN
        wr_pntr_ll_afifo   <= (OTHERS => '0');
      ELSIF (WR_CLK'event AND WR_CLK = '1') THEN
        IF (write_allow = '1') THEN
          wr_pntr_ll_afifo <= wr_pntr_ll_afifo + "1" AFTER C_TCQ;
        END IF;
      END IF;
    END PROCESS wrptr_proc;
  
    -------------------------------------------------------------------------------
    -- Fill the Memory
    -------------------------------------------------------------------------------
    wr_mem : PROCESS (WR_CLK)
    BEGIN
      IF (WR_CLK'event AND WR_CLK = '1') THEN
        IF (write_allow = '1') THEN
          memory(conv_integer(wr_pntr_ll_afifo)) <= DIN AFTER C_TCQ;
        END IF;
      END IF;
    END PROCESS wr_mem;
  
    rdptr_proc : PROCESS (RD_CLK, rd_rst_i)
    BEGIN
      IF (rd_rst_i = '1') THEN
        rd_pntr_ll_afifo_q   <= (OTHERS => '0');
      ELSIF (RD_CLK'event AND RD_CLK = '1') THEN
        rd_pntr_ll_afifo_q <= rd_pntr_ll_afifo AFTER C_TCQ;
      END IF;
    END PROCESS rdptr_proc;
    rd_pntr_ll_afifo <= rd_pntr_ll_afifo_q + "1" WHEN (read_allow = '1') ELSE rd_pntr_ll_afifo_q;

    -------------------------------------------------------------------------------
    -- Generate DOUT for DRAM
    -------------------------------------------------------------------------------
    rd_mem : PROCESS (RD_CLK)
    BEGIN
      IF (RD_CLK'event AND RD_CLK = '1') THEN
        DOUT <= memory(conv_integer(rd_pntr_ll_afifo)) AFTER C_TCQ;
      END IF;
    END PROCESS rd_mem;

    -------------------------------------------------------------------------------
    -- Generate EMPTY
    -------------------------------------------------------------------------------
    wr_pntr_eq_rd_pntr       <= '1' WHEN (wr_pntr_ll_afifo = rd_pntr_ll_afifo_q) ELSE '0';
    wr_pntr_eq_rd_pntr_plus1 <= '1' WHEN (wr_pntr_ll_afifo = conv_std_logic_vector(
                                          (conv_integer(rd_pntr_ll_afifo_q)+1),
                                           C_RD_PNTR_WIDTH)) ELSE '0';
    proc_empty : PROCESS (RD_CLK, rd_rst_i)
    BEGIN
      IF (rd_rst_i = '1') THEN
        ll_afifo_empty <= '1';
      ELSIF (RD_CLK'event AND RD_CLK = '1') THEN
        ll_afifo_empty <= wr_pntr_eq_rd_pntr OR (read_allow AND wr_pntr_eq_rd_pntr_plus1) AFTER C_TCQ;
      END IF;
    END PROCESS proc_empty;

    -------------------------------------------------------------------------------
    -- Generate FULL
    -------------------------------------------------------------------------------
    rd_pntr_eq_wr_pntr_plus1 <= '1' WHEN (rd_pntr_ll_afifo_q = conv_std_logic_vector(
                                          (conv_integer(wr_pntr_ll_afifo)+1),
                                           C_WR_PNTR_WIDTH)) ELSE '0';
    rd_pntr_eq_wr_pntr_plus2 <= '1' WHEN (rd_pntr_ll_afifo_q = conv_std_logic_vector(
                                          (conv_integer(wr_pntr_ll_afifo)+2),
                                           C_WR_PNTR_WIDTH)) ELSE '0';
    proc_full : PROCESS (WR_CLK, wr_rst_i)
    BEGIN
      IF (wr_rst_i = '1') THEN
        ll_afifo_full <= '1';
      ELSIF (WR_CLK'event AND WR_CLK = '1') THEN
        ll_afifo_full <= rd_pntr_eq_wr_pntr_plus1 OR (write_allow AND rd_pntr_eq_wr_pntr_plus2) AFTER C_TCQ;
      END IF;
    END PROCESS proc_full;
    EMPTY <= ll_afifo_empty;
    FULL  <= ll_afifo_full;
  END GENERATE gll_afifo;


END behavioral;


--#############################################################################
--#############################################################################
--  Common Clock FIFO Behavioral Model
--#############################################################################
--#############################################################################

-------------------------------------------------------------------------------
-- Library Declaration
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_arith.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.std_logic_misc.ALL;





-------------------------------------------------------------------------------
-- Common-Clock Entity Declaration - This is NOT the top-level entity
-------------------------------------------------------------------------------
ENTITY fifo_generator_v13_0_0_bhv_ss IS

  GENERIC (
    --------------------------------------------------------------------------------
    -- Generic Declarations (alphabetical)
    --------------------------------------------------------------------------------
    C_FAMILY                       : string  := "virtex7";
    C_DATA_COUNT_WIDTH             : integer := 2;  
    C_DIN_WIDTH                    : integer := 8;  
    C_DOUT_RST_VAL                 : string  := ""; 
    C_DOUT_WIDTH                   : integer := 8;  
    C_FULL_FLAGS_RST_VAL           : integer := 1;
    C_HAS_ALMOST_EMPTY             : integer := 0;  
    C_HAS_ALMOST_FULL              : integer := 0;  
    C_HAS_DATA_COUNT               : integer := 0;  
    C_HAS_OVERFLOW                 : integer := 0;  
    C_HAS_RD_DATA_COUNT            : integer := 2;
    C_HAS_RST                      : integer := 0;  
    C_HAS_SRST                     : integer := 0;  
    C_HAS_UNDERFLOW                : integer := 0;
    C_HAS_VALID                    : integer := 0;  
    C_HAS_WR_ACK                   : integer := 0;  
    C_HAS_WR_DATA_COUNT            : integer := 2;
    C_MEMORY_TYPE                  : integer := 1;  
    C_OVERFLOW_LOW                 : integer := 0;  
    C_PRELOAD_LATENCY              : integer := 1;  
    C_PRELOAD_REGS                 : integer := 0;  
    C_PROG_EMPTY_THRESH_ASSERT_VAL : integer := 0;
    C_PROG_EMPTY_THRESH_NEGATE_VAL : integer := 0;
    C_PROG_EMPTY_TYPE              : integer := 0;
    C_PROG_FULL_THRESH_ASSERT_VAL  : integer := 0;
    C_PROG_FULL_THRESH_NEGATE_VAL  : integer := 0;
    C_PROG_FULL_TYPE               : integer := 0;
    C_RD_DATA_COUNT_WIDTH          : integer := 0;
    C_RD_DEPTH                     : integer := 256;
    C_RD_PNTR_WIDTH                : integer := 8;  
    C_UNDERFLOW_LOW                : integer := 0;  
    C_USE_DOUT_RST                 : integer := 0;  
    C_USE_ECC                      : integer := 0;
    C_USE_EMBEDDED_REG             : integer := 0; 
    C_EN_SAFETY_CKT                : integer := 0; 
    C_USE_FWFT_DATA_COUNT          : integer := 0;
    C_VALID_LOW                    : integer := 0;  
    C_WR_ACK_LOW                   : integer := 0;  
    C_WR_DATA_COUNT_WIDTH          : integer := 0;
    C_WR_DEPTH                     : integer := 256;
    C_WR_PNTR_WIDTH                : integer := 8;
    C_TCQ                          : time    := 100 ps;
    C_ENABLE_RST_SYNC              : integer := 1;
    C_ERROR_INJECTION_TYPE         : integer := 0;
    C_FIFO_TYPE                    : integer := 0
    );


  PORT(
    --------------------------------------------------------------------------------
    -- Input and Output Declarations
    --------------------------------------------------------------------------------
    CLK                      : IN std_logic   := '0';
    RST                      : IN std_logic   := '0';
    SRST                     : IN std_logic   := '0';
    RST_FULL_GEN             : IN std_logic := '0';
    RST_FULL_FF              : IN std_logic := '0';
    DIN                      : IN std_logic_vector(C_DIN_WIDTH-1 DOWNTO 0)     
                             := (OTHERS => '0');
    RD_EN                    : IN std_logic   := '0';
    RD_EN_USER               : IN std_logic;
    WR_EN                    : IN std_logic   := '0';
    PROG_EMPTY_THRESH        : IN std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) 
                             := (OTHERS => '0');
    PROG_EMPTY_THRESH_ASSERT : IN std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) 
                             := (OTHERS => '0');
    PROG_EMPTY_THRESH_NEGATE : IN std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) 
                             := (OTHERS => '0');
    PROG_FULL_THRESH         : IN std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) 
                             := (OTHERS => '0');
    PROG_FULL_THRESH_ASSERT  : IN std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) 
                             := (OTHERS => '0');
    PROG_FULL_THRESH_NEGATE  : IN std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) 
                             := (OTHERS => '0');
    WR_RST_BUSY              : IN  std_logic := '0';
    RD_RST_BUSY              : IN  std_logic := '0';
    INJECTDBITERR            : IN  std_logic := '0';
    INJECTSBITERR            : IN  std_logic := '0';
    USER_EMPTY_FB            : IN std_logic := '1';

    DOUT                     : OUT std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0) :=    (OTHERS => '0');
    EMPTY                    : OUT std_logic := '1';
    FULL                     : OUT std_logic := '0'; 
    ALMOST_EMPTY             : OUT std_logic := '1';
    ALMOST_FULL              : OUT std_logic := '0'; 
    PROG_EMPTY               : OUT std_logic := '1';
    PROG_FULL                : OUT std_logic := '0'; 
    OVERFLOW                 : OUT std_logic := '0';
    WR_ACK                   : OUT std_logic := '0';
    VALID                    : OUT std_logic := '0';
    UNDERFLOW                : OUT std_logic := '0';
    DATA_COUNT               : OUT std_logic_vector(C_DATA_COUNT_WIDTH-1 DOWNTO 0) 
                             :=    (OTHERS => '0');
    RD_DATA_COUNT            : OUT std_logic_vector(C_RD_DATA_COUNT_WIDTH-1 DOWNTO 0)
                             := (OTHERS => '0');
    WR_DATA_COUNT            : OUT std_logic_vector(C_WR_DATA_COUNT_WIDTH-1 DOWNTO 0)
                             := (OTHERS => '0');
    SBITERR                  : OUT std_logic := '0';
    DBITERR                  : OUT std_logic := '0'
    );

END fifo_generator_v13_0_0_bhv_ss;


-------------------------------------------------------------------------------
-- Architecture Heading
-------------------------------------------------------------------------------
ARCHITECTURE behavioral OF fifo_generator_v13_0_0_bhv_ss IS


  -----------------------------------------------------------------------------
  -- FUNCTION actual_fifo_depth
  -- Returns the actual depth of the FIFO (may differ from what the user 
  -- specified)
  --
  -- The FIFO depth is always represented as 2^n (16,32,64,128,256)
  -- However, the ACTUAL fifo depth may be 2^n+1 or 2^n-1 depending on certain
  -- options. This function returns the actual depth of the fifo, as seen by
  -- the user.
  -------------------------------------------------------------------------------
  FUNCTION actual_fifo_depth(
    C_FIFO_DEPTH : integer; 
    C_PRELOAD_REGS : integer; 
    C_PRELOAD_LATENCY : integer; 
    C_COMMON_CLOCK : integer) 
  RETURN integer IS
  BEGIN
    RETURN C_FIFO_DEPTH;
  END actual_fifo_depth;

  -----------------------------------------------------------------------------
  -- FUNCTION int_2_std_logic
  -- Returns a single bit (as std_logic) from an integer 1/0 value.
  -------------------------------------------------------------------------------
  FUNCTION int_2_std_logic(value : integer) RETURN std_logic IS
  BEGIN
    IF (value=1) THEN
      RETURN '1';
    ELSE
      RETURN '0';
    END IF;
  END int_2_std_logic; 

  -----------------------------------------------------------------------------
  -- FUNCTION hexstr_to_std_logic_vec
  -- Returns a std_logic_vector for a hexadecimal string
  -------------------------------------------------------------------------------

    FUNCTION hexstr_to_std_logic_vec( 
      arg1 : string; 
      size : integer ) 
    RETURN std_logic_vector IS
      VARIABLE result : std_logic_vector(size-1 DOWNTO 0) := (OTHERS => '0');
      VARIABLE bin    : std_logic_vector(3 DOWNTO 0);
      VARIABLE index  : integer                           := 0;
    BEGIN
      FOR i IN arg1'reverse_range LOOP
        CASE arg1(i) IS
          WHEN '0' => bin := (OTHERS => '0');
          WHEN '1' => bin := (0 => '1', OTHERS => '0');
          WHEN '2' => bin := (1 => '1', OTHERS => '0');
          WHEN '3' => bin := (0 => '1', 1 => '1', OTHERS => '0');
          WHEN '4' => bin := (2 => '1', OTHERS => '0');
          WHEN '5' => bin := (0 => '1', 2 => '1', OTHERS => '0');
          WHEN '6' => bin := (1 => '1', 2 => '1', OTHERS => '0');
          WHEN '7' => bin := (3 => '0', OTHERS => '1');
          WHEN '8' => bin := (3 => '1', OTHERS => '0');
          WHEN '9' => bin := (0 => '1', 3 => '1', OTHERS => '0');
          WHEN 'A' => bin := (0 => '0', 2 => '0', OTHERS => '1');
          WHEN 'a' => bin := (0 => '0', 2 => '0', OTHERS => '1');
          WHEN 'B' => bin := (2 => '0', OTHERS => '1');
          WHEN 'b' => bin := (2 => '0', OTHERS => '1');
          WHEN 'C' => bin := (0 => '0', 1 => '0', OTHERS => '1');
          WHEN 'c' => bin := (0 => '0', 1 => '0', OTHERS => '1');
          WHEN 'D' => bin := (1 => '0', OTHERS => '1');
          WHEN 'd' => bin := (1 => '0', OTHERS => '1');
          WHEN 'E' => bin := (0 => '0', OTHERS => '1');
          WHEN 'e' => bin := (0 => '0', OTHERS => '1');
          WHEN 'F' => bin := (OTHERS => '1');
          WHEN 'f' => bin := (OTHERS => '1');
          WHEN OTHERS =>
            FOR j IN 0 TO 3 LOOP
              bin(j) := 'X';
            END LOOP;
        END CASE;
        FOR j IN 0 TO 3 LOOP
          IF (index*4)+j < size THEN
            result((index*4)+j) := bin(j);
          END IF;
        END LOOP;
        index := index + 1;
      END LOOP;
      RETURN result;
    END hexstr_to_std_logic_vec;

  -----------------------------------------------------------------------------
  -- FUNCTION get_lesser
  -- Returns a minimum value
  -------------------------------------------------------------------------------
  
  FUNCTION get_lesser(a: INTEGER; b: INTEGER) RETURN INTEGER IS
  BEGIN
    IF (a < b) THEN
      RETURN a;
    ELSE
      RETURN b;
    END IF;
  END FUNCTION;

  -----------------------------------------------------------------------------
  -- FUNCTION if_then_else
  -- Returns a true case or flase case based on the condition
  -------------------------------------------------------------------------------

    FUNCTION if_then_else (
      condition : boolean; 
      true_case : integer; 
      false_case : integer) 
    RETURN integer IS
      VARIABLE retval : integer := 0;
    BEGIN
      IF NOT condition THEN
        retval:=false_case;
      ELSE
        retval:=true_case;
      END IF;
      RETURN retval;
    END if_then_else;

    FUNCTION if_then_else (
      condition : boolean; 
      true_case : std_logic;
      false_case : std_logic) 
    RETURN std_logic IS
      VARIABLE retval : std_logic := '0';
    BEGIN
      IF NOT condition THEN
        retval:=false_case;
      ELSE
        retval:=true_case;
      END IF;
      RETURN retval;
    END if_then_else;

    FUNCTION if_then_else (
      condition : boolean; 
      true_case : std_logic_vector;
      false_case : std_logic_vector) 
    RETURN std_logic_vector IS
    BEGIN
      IF NOT condition THEN
        RETURN false_case;
      ELSE
        RETURN true_case;
      END IF;
    END if_then_else;

    FUNCTION int_2_std_logic_vector( 
      value, bitwidth : integer )
    RETURN std_logic_vector IS
      VARIABLE running_value  : integer := value;
      VARIABLE running_result : std_logic_vector(bitwidth-1 DOWNTO 0);
    BEGIN
      running_result := conv_std_logic_vector(value,bitwidth); 
      RETURN running_result;
    END int_2_std_logic_vector;


  --------------------------------------------------------------------------------
  -- Constant Declaration
  --------------------------------------------------------------------------------
  CONSTANT C_FIFO_WR_DEPTH : integer 
    := actual_fifo_depth(C_WR_DEPTH, C_PRELOAD_REGS, C_PRELOAD_LATENCY, 1);
  CONSTANT C_SMALLER_DATA_WIDTH : integer := get_lesser(C_DIN_WIDTH, C_DOUT_WIDTH);
  CONSTANT C_FIFO_DEPTH : integer := C_WR_DEPTH;
  CONSTANT C_DEPTH_RATIO_WR     : integer 
    := if_then_else( (C_WR_DEPTH > C_RD_DEPTH), (C_WR_DEPTH/C_RD_DEPTH), 1);
  CONSTANT C_DEPTH_RATIO_RD     : integer 
    := if_then_else( (C_RD_DEPTH > C_WR_DEPTH), (C_RD_DEPTH/C_WR_DEPTH), 1);



  CONSTANT C_DATA_WIDTH : integer := if_then_else((C_USE_ECC > 0 AND C_ERROR_INJECTION_TYPE /= 0),
                                                   C_DIN_WIDTH+2, C_DIN_WIDTH);
  CONSTANT OF_INIT_VAL : std_logic := if_then_else((C_HAS_OVERFLOW = 1 AND C_OVERFLOW_LOW = 1),'1','0');
  CONSTANT UF_INIT_VAL : std_logic := if_then_else((C_HAS_UNDERFLOW = 1 AND C_UNDERFLOW_LOW = 1),'1','0');
  CONSTANT DO_ALL_ZERO : std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  CONSTANT RST_VAL     : std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0) := hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH);
  CONSTANT RST_VALUE   : std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0) 
                         := if_then_else(C_USE_DOUT_RST = 1, RST_VAL, DO_ALL_ZERO);

  CONSTANT IS_ASYMMETRY      : integer :=if_then_else((C_WR_PNTR_WIDTH /= C_RD_PNTR_WIDTH),1,0);
  CONSTANT C_GRTR_PNTR_WIDTH   : integer :=if_then_else((C_WR_PNTR_WIDTH > C_RD_PNTR_WIDTH),C_WR_PNTR_WIDTH,C_RD_PNTR_WIDTH);
  CONSTANT LESSER_WIDTH  : integer
    :=if_then_else((C_RD_PNTR_WIDTH > C_WR_PNTR_WIDTH),
                    C_WR_PNTR_WIDTH,
                    C_RD_PNTR_WIDTH);  
  CONSTANT DIFF_MAX_RD      : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '1'); 
  CONSTANT DIFF_MAX_WR      : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '1'); 


  TYPE mem_array IS ARRAY (0 TO C_FIFO_DEPTH-1) OF STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
  -------------------------------------------------------------------------------
  -- Internal Signals
  -------------------------------------------------------------------------------
  SIGNAL memory         : mem_array := (OTHERS => (OTHERS => '0'));
  SIGNAL wr_pntr        : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL rd_pntr        : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL write_allow    : std_logic := '0'; 
  SIGNAL read_allow     : std_logic := '0'; 
  SIGNAL read_allow_dc     : std_logic := '0'; 
  SIGNAL empty_i        : std_logic := '1';
  SIGNAL full_i         : std_logic := int_2_std_logic(C_FULL_FLAGS_RST_VAL); 
  SIGNAL almost_empty_i : std_logic := '1';
  SIGNAL almost_full_i  : std_logic := '0';

  SIGNAL rst_asreg      : std_logic := '0';
  SIGNAL rst_asreg_d1   : std_logic := '0';
  SIGNAL rst_asreg_d2   : std_logic := '0';
  SIGNAL rst_comb       : std_logic := '0';
  SIGNAL rst_reg        : std_logic := '0';
  SIGNAL rst_i          : std_logic := '0';
  SIGNAL srst_i         : std_logic := '0';
  SIGNAL srst_wrst_busy : std_logic := '0';
  SIGNAL srst_rrst_busy : std_logic := '0';

  SIGNAL diff_count     : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0)       
                        := (OTHERS => '0');

  SIGNAL wr_ack_i       : std_logic := '0';
  SIGNAL overflow_i     : std_logic := OF_INIT_VAL;

  SIGNAL valid_i        : std_logic := '0';
  SIGNAL valid_d1       : std_logic := '0';
  SIGNAL underflow_i    : std_logic := UF_INIT_VAL;

  --The delayed reset is used to deassert prog_full
  SIGNAL rst_q          : std_logic := '0';

  SIGNAL prog_full_reg   : std_logic := '0'; 
  SIGNAL prog_full_noreg : std_logic := '0'; 
  SIGNAL prog_empty_reg  : std_logic := '1';
  SIGNAL prog_empty_noreg: std_logic := '1';
  SIGNAL dout_i          : std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0) := RST_VALUE;
  SIGNAL sbiterr_i       : std_logic := '0'; 
  SIGNAL dbiterr_i       : std_logic := '0'; 
  SIGNAL ram_rd_en_d1    : std_logic := '0';
  SIGNAL mem_pntr        : integer   := 0; 
  SIGNAL ram_wr_en_i     : std_logic := '0';
  SIGNAL ram_rd_en_i     : std_logic := '0';  

  SIGNAL comp1           : std_logic := '0';
  SIGNAL comp0           : std_logic := '0';
  SIGNAL going_full      : std_logic := '0';
  SIGNAL leaving_full    : std_logic := '0';
  SIGNAL ram_full_comb   : std_logic := '0';
  SIGNAL ecomp1          : std_logic := '0';
  SIGNAL ecomp0          : std_logic := '0';
  SIGNAL going_empty     : std_logic := '0';
  SIGNAL leaving_empty   : std_logic := '0';
  SIGNAL ram_empty_comb  : std_logic := '0';

  SIGNAL wr_point       : integer   := 0;
  SIGNAL rd_point       : integer   := 0;
  SIGNAL wr_point_d1    : integer   := 0;
  SIGNAL wr_point_d2    : integer   := 0;
  SIGNAL rd_point_d1    : integer   := 0;
  SIGNAL num_wr_words   : integer   := 0;
  SIGNAL num_rd_words   : integer   := 0;
  SIGNAL adj_wr_point   : integer   := 0;
  SIGNAL adj_rd_point   : integer   := 0;
  SIGNAL adj_wr_point_d1: integer   := 0;
  SIGNAL adj_rd_point_d1: integer   := 0;

  SIGNAL wr_pntr_temp            : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL wr_pntr_rd1        : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL wr_pntr_rd2        : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL wr_pntr_rd3        : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL wr_pntr_rd         : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL adj_wr_pntr_rd     : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) 
                            := (OTHERS=>'0');
  SIGNAL wr_data_count_int  : std_logic_vector(C_WR_PNTR_WIDTH DOWNTO 0) 
                            := (OTHERS=>'0');
  SIGNAL wdc_fwft_ext_as    : std_logic_vector(C_WR_PNTR_WIDTH DOWNTO 0) 
                            := (OTHERS=>'0');
  SIGNAL rdc_fwft_ext_as    : std_logic_vector (C_RD_PNTR_WIDTH DOWNTO 0)
                            := (OTHERS => '0');
  SIGNAL rd_pntr_wr_d1      : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL rd_pntr_wr_d2      : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL rd_pntr_wr_d3      : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL rd_pntr_wr_d4      : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0)
                            := (OTHERS=>'0');
  SIGNAL rd_pntr_wr         : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) 
                            := (OTHERS=>'0');
  SIGNAL adj_rd_pntr_wr     : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) 
                            := (OTHERS=>'0');
  SIGNAL rd_data_count_int  : std_logic_vector(C_RD_PNTR_WIDTH DOWNTO 0) 
                            := (OTHERS=>'0');
  SIGNAL width_gt1         : std_logic := '0'; 

  -------------------------------------------------------------------------------
  --Used in computing AE and AF
  -------------------------------------------------------------------------------
  SIGNAL fcomp2             : std_logic := '0';
  SIGNAL going_afull        : std_logic := '0';
  SIGNAL leaving_afull      : std_logic := '0';
  SIGNAL ram_afull_comb     : std_logic := '0';
  SIGNAL ecomp2             : std_logic := '0';
  SIGNAL going_aempty       : std_logic := '0';
  SIGNAL leaving_aempty     : std_logic := '0';
  SIGNAL ram_aempty_comb    : std_logic := '1';



  SIGNAL rd_fwft_cnt        : std_logic_vector(3 downto 0)   := (others=>'0');
  SIGNAL stage1_valid       : std_logic := '0';
  SIGNAL stage2_valid       : std_logic := '0';


  -------------------------------------------------------------------------------
  --Used in computing RD_DATA_COUNT WR_DATA_COUNT
  -------------------------------------------------------------------------------

    SIGNAL   count_dc            :  std_logic_vector(C_GRTR_PNTR_WIDTH DOWNTO 0) := int_2_std_logic_vector(0,C_GRTR_PNTR_WIDTH+1);
    SIGNAL   one                 :  std_logic_vector(C_GRTR_PNTR_WIDTH DOWNTO 0);
    SIGNAL   ratio               :  std_logic_vector(C_GRTR_PNTR_WIDTH DOWNTO 0);



  -------------------------------------------------------------------------------
  --Linked List types
  -------------------------------------------------------------------------------
  TYPE listtyp;
  TYPE listptr IS ACCESS listtyp;
  TYPE listtyp IS RECORD
      data  : std_logic_vector(C_SMALLER_DATA_WIDTH + 1 DOWNTO 0);
      older : listptr;
      newer : listptr;
    END RECORD;

  -------------------------------------------------------------------------------
  --Processes for linked list implementation. The functions are
  --1. "newlist" - Create a new linked list
  --2. "add"     - Add a data element to a linked list
  --3. "read"    - Read the data from the tail of the linked list
  --4. "remove"  - Remove the tail from the linked list
  --5. "sizeof"  - Calculate the size of the linked list
  -------------------------------------------------------------------------------
  --1. Create a new linked list
  PROCEDURE newlist (
    head   : INOUT listptr; 
    tail   : INOUT listptr;
    cntr   : INOUT integer) IS
  BEGIN
    head   := NULL;
    tail   := NULL;
    cntr   := 0;
  END;  

  --2. Add a data element to a linked list
  PROCEDURE add (
    head    : INOUT listptr; 
    tail    : INOUT listptr; 
    data    : IN std_logic_vector;
    cntr    : INOUT integer;
    inj_err : IN std_logic_vector(2 DOWNTO 0)
    ) IS
    VARIABLE oldhead        : listptr;
    VARIABLE newhead        : listptr;
    VARIABLE corrupted_data : std_logic_vector(1 DOWNTO 0);
  BEGIN
    --------------------------------------------------------------------------
    --a. Create a pointer to the existing head, if applicable
    --b. Create a new node for the list
    --c. Make the new node point to the old head
    --d. Make the old head point back to the new node (for doubly-linked list)
    --e. Put the data into the new head node
    --f. If the new head we just created is the only node in the list, 
    --   make the tail point to it
    --g. Return the new head pointer
    --------------------------------------------------------------------------
    IF (head /= NULL) THEN
      oldhead       := head;
    END IF;
    newhead         := NEW listtyp;
    newhead.older   := oldhead;
    IF (head /= NULL) THEN
      oldhead.newer := newhead;
    END IF;

    CASE inj_err(1 DOWNTO 0) IS
      -- For both error injection, pass only the double bit error injection
      -- as dbit error has priority over single bit error injection
      WHEN "11"   => newhead.data := inj_err(1) & '0' & data;
      WHEN "10"   => newhead.data := inj_err(1) & '0' & data;
      WHEN "01"   => newhead.data := '0' & inj_err(0) & data;
      WHEN OTHERS => newhead.data := '0' & '0' & data;
    END CASE;

    -- Increment the counter when data is added to the list
    cntr := cntr + 1;
    IF (newhead.older = NULL) THEN
      tail          := newhead;
    END IF;
    head            := newhead;
  END;  

  --3. Read the data from the tail of the linked list
  PROCEDURE read (
    tail : INOUT listptr; 
    data : OUT std_logic_vector;
    err_type : OUT std_logic_vector(1 DOWNTO 0)
    ) IS
  VARIABLE data_int     : std_logic_vector(C_SMALLER_DATA_WIDTH + 1 DOWNTO 0) := (OTHERS => '0');
  VARIABLE err_type_int : std_logic_vector(1 DOWNTO 0) := (OTHERS => '0');
  BEGIN
    data_int := tail.data;
    -- MSB two bits carry the error injection type.
    err_type_int := data_int(data_int'high DOWNTO C_SMALLER_DATA_WIDTH);
    IF (err_type_int(1) = '0') THEN
      data     := data_int(C_SMALLER_DATA_WIDTH - 1 DOWNTO 0);
    ELSIF (C_DOUT_WIDTH = 2) THEN
        data     := NOT data_int(C_SMALLER_DATA_WIDTH - 1 DOWNTO 0);
    ELSIF (C_DOUT_WIDTH > 2) THEN
        data     := NOT data_int(data_int'high-2) & NOT data_int(data_int'high-3) &
                    data_int(data_int'high-4 DOWNTO 0);
    ELSE
      data     := data_int(C_SMALLER_DATA_WIDTH - 1 DOWNTO 0);
    END IF;

    err_type := err_type_int;

  END;  

  --4. Remove the tail from the linked list
  PROCEDURE remove (
    head : INOUT listptr; 
    tail : INOUT listptr;
    cntr : INOUT integer) IS
    VARIABLE oldtail     :       listptr;
    VARIABLE newtail     :       listptr;
  BEGIN
    --------------------------------------------------------------------------
    --Make a copy of the old tail pointer
    --a. If there is no newer node, then set the tail pointer to nothing 
    --   (list is empty)
    --   otherwise, make the next newer node the new tail, and make it point 
    --   to nothing older
    --b. Clean up the memory for the old tail node
    --c. If the new tail is nothing, then we have an empty list, and head 
    --   should also be set to nothing
    --d. Return the new tail
    --------------------------------------------------------------------------
    oldtail         := tail;
    IF (oldtail.newer = NULL) THEN
      newtail       := NULL;
    ELSE
      newtail       := oldtail.newer;
      newtail.older := NULL;
    END IF;
    DEALLOCATE(oldtail);
    IF (newtail = NULL) THEN
      head          := NULL;
    END IF;
    tail            := newtail;
    -- Decrement the counter when data is removed from the list
    cntr := cntr - 1;
  END; 


  --5. Calculate the size of the linked list
  PROCEDURE sizeof (head : INOUT listptr; size : OUT integer) IS
    VARIABLE curlink     :       listptr;
    VARIABLE tmpsize     :       integer := 0;
  BEGIN
    --------------------------------------------------------------------------
    --a. If head is null, then there is nothing in the list to traverse
    --   start with the head node (which implies at least one node exists)
    --   Loop through each node until you find the one that points to nothing 
    --   (the tail)
    --b. Return the number of nodes
    --------------------------------------------------------------------------
    IF (head /= NULL) THEN
      curlink                            := head;
      tmpsize                            := 1;
      WHILE (curlink.older /= NULL) LOOP
        tmpsize                          := tmpsize + 1;
        curlink                          := curlink.older;
      END LOOP;
    END IF;
    size                                 := tmpsize;
  END;  


  -----------------------------------------------------------------------------
  -- converts integer to specified length std_logic_vector : dropping least
  -- significant bits if integer is bigger than what can be represented by
  -- the vector
  -----------------------------------------------------------------------------
  FUNCTION count( 
    fifo_count    : IN integer;
    pointer_width : IN integer;
    counter_width : IN integer)
  RETURN std_logic_vector IS
    VARIABLE temp   :    std_logic_vector(pointer_width-1 DOWNTO 0)   
                    := (OTHERS => '0');
    VARIABLE output :    std_logic_vector(counter_width - 1 DOWNTO 0) 
                    := (OTHERS => '0');
  BEGIN
    temp     := CONV_STD_LOGIC_VECTOR(fifo_count, pointer_width);
    IF (counter_width <= pointer_width) THEN
      output := temp(pointer_width - 1 DOWNTO pointer_width - counter_width);
    ELSE
      output := temp(counter_width - 1 DOWNTO 0);
    END IF;
    RETURN output;
  END count;



-------------------------------------------------------------------------------
-- architecture begins here
-------------------------------------------------------------------------------
BEGIN

  --gnll_fifo: IF (C_FIFO_TYPE /= 2) GENERATE


  rst_i     <= RST;
  
  --SRST
  gsrst  : IF (C_HAS_SRST=1) GENERATE
    srst_i         <= SRST;
    srst_rrst_busy <= SRST OR RD_RST_BUSY;
    srst_wrst_busy <= SRST OR WR_RST_BUSY;
  END GENERATE gsrst;
  
  --No SRST
  nosrst  : IF (C_HAS_SRST=0) GENERATE
    srst_i         <= '0';
    srst_rrst_busy <= '0';
    srst_wrst_busy <= '0';
  END GENERATE nosrst;

  gdc : IF (C_HAS_DATA_COUNT = 1) GENERATE
    SIGNAL diff_count     : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  BEGIN
    diff_count <= wr_pntr - rd_pntr;
    gdcb : IF (C_DATA_COUNT_WIDTH > C_RD_PNTR_WIDTH) GENERATE
       DATA_COUNT(C_RD_PNTR_WIDTH-1 DOWNTO 0)    <= diff_count;
       DATA_COUNT(C_DATA_COUNT_WIDTH-1) <= '0' ; 
     END GENERATE;
 
     gdcs : IF (C_DATA_COUNT_WIDTH <= C_RD_PNTR_WIDTH) GENERATE
       DATA_COUNT <= 
       diff_count(C_RD_PNTR_WIDTH-1 DOWNTO C_RD_PNTR_WIDTH-C_DATA_COUNT_WIDTH);
     END GENERATE;
  END GENERATE gdc;

  gndc    : IF (C_HAS_DATA_COUNT = 0) GENERATE
      DATA_COUNT <= (OTHERS => '0');
  END GENERATE gndc;

  -------------------------------------------------------------------------------
  --Calculate WR_ACK based on C_WR_ACK_LOW parameters
  -------------------------------------------------------------------------------
  gwalow : IF (C_WR_ACK_LOW = 0) GENERATE
    WR_ACK <= wr_ack_i;
  END GENERATE gwalow;

  gwahgh : IF (C_WR_ACK_LOW = 1) GENERATE
    WR_ACK <= NOT wr_ack_i;
  END GENERATE gwahgh;

  -------------------------------------------------------------------------------
  --Calculate OVERFLOW based on C_OVERFLOW_LOW parameters
  -------------------------------------------------------------------------------
  govlow : IF (C_OVERFLOW_LOW = 0) GENERATE
    OVERFLOW <= overflow_i;
  END GENERATE govlow;
  govhgh : IF (C_OVERFLOW_LOW = 1) GENERATE
    OVERFLOW <= NOT overflow_i;
  END GENERATE govhgh;

  -------------------------------------------------------------------------------
  --Calculate VALID based on C_PRELOAD_LATENCY and C_VALID_LOW settings
  -------------------------------------------------------------------------------
  gvlat1 : IF (C_PRELOAD_LATENCY = 1 OR C_PRELOAD_LATENCY=2) GENERATE
    gnvl : IF (C_VALID_LOW = 0) GENERATE
      VALID <= valid_d1;
    END GENERATE gnvl;
    gnvh : IF (C_VALID_LOW = 1) GENERATE
      VALID <= NOT valid_d1;
    END GENERATE gnvh;
  END GENERATE gvlat1;

  -------------------------------------------------------------------------------
  -- Calculate UNDERFLOW based on C_PRELOAD_LATENCY and C_UNDERFLOW_LOW settings
  -------------------------------------------------------------------------------
  guflat1 : IF (C_PRELOAD_LATENCY = 1 OR C_PRELOAD_LATENCY=2) GENERATE
    gnul  : IF (C_UNDERFLOW_LOW = 0) GENERATE
      UNDERFLOW <= underflow_i;
    END GENERATE gnul;
    gnuh  : IF (C_UNDERFLOW_LOW = 1) GENERATE
      UNDERFLOW <= NOT underflow_i;
    END GENERATE gnuh;
  END GENERATE guflat1;

  FULL          <= full_i;
  gaf_ss: IF (C_HAS_ALMOST_FULL = 1 OR C_PROG_FULL_TYPE > 2 OR C_PROG_EMPTY_TYPE > 2) GENERATE
  BEGIN
   ALMOST_FULL   <= almost_full_i;
  END GENERATE gaf_ss;

  gafn_ss: IF (C_HAS_ALMOST_FULL = 0 AND C_PROG_FULL_TYPE <= 2 AND C_PROG_EMPTY_TYPE <= 2) GENERATE
  BEGIN
   ALMOST_FULL   <= '0';
  END GENERATE gafn_ss;

  EMPTY         <= empty_i;

  gae_ss: IF (C_HAS_ALMOST_EMPTY = 1) GENERATE
  BEGIN
   ALMOST_EMPTY  <= almost_empty_i;
  END GENERATE gae_ss;

  gaen_ss: IF (C_HAS_ALMOST_EMPTY = 0) GENERATE
  BEGIN
   ALMOST_EMPTY  <= '0';
  END GENERATE gaen_ss;


    write_allow    <= WR_EN AND (NOT full_i);
    read_allow     <= RD_EN AND (NOT empty_i);

    gen_read_allow_for_dc_fwft: IF(C_PRELOAD_REGS =1 AND C_PRELOAD_LATENCY =0) GENERATE
     read_allow_dc <= RD_EN_USER AND (NOT USER_EMPTY_FB);
    END GENERATE gen_read_allow_for_dc_fwft; 

    gen_read_allow_for_dc_std: IF(NOT(C_PRELOAD_REGS =1 AND C_PRELOAD_LATENCY =0)) GENERATE
     read_allow_dc <= read_allow;
    END GENERATE gen_read_allow_for_dc_std; 

    wrptr_proc : PROCESS (CLK, rst_i)
    BEGIN
      IF (rst_i = '1') THEN
        wr_pntr   <= (OTHERS => '0');
      ELSIF (CLK'event AND CLK = '1') THEN
        IF (srst_wrst_busy = '1') THEN 
          wr_pntr <= (OTHERS => '0') AFTER C_TCQ;
        ELSIF (write_allow = '1') THEN
          wr_pntr <= wr_pntr + "1" AFTER C_TCQ;
        END IF;
      END IF;
    END PROCESS wrptr_proc;

    gecc_mem: IF (C_USE_ECC > 0 AND C_ERROR_INJECTION_TYPE /= 0) GENERATE
      wr_mem : PROCESS (CLK)
      BEGIN
        IF (CLK'event AND CLK = '1') THEN
          IF (write_allow = '1') THEN
            memory(conv_integer(wr_pntr)) <= INJECTDBITERR & INJECTSBITERR & DIN AFTER C_TCQ;
          END IF;
        END IF;
      END PROCESS wr_mem;
    END GENERATE gecc_mem;

    gnecc_mem: IF NOT (C_USE_ECC > 0 AND C_ERROR_INJECTION_TYPE /= 0) GENERATE
      wr_mem : PROCESS (CLK)
      BEGIN
        IF (CLK'event AND CLK = '1') THEN
          IF (write_allow = '1') THEN
            memory(conv_integer(wr_pntr)) <= DIN AFTER C_TCQ;
          END IF;
        END IF;
      END PROCESS wr_mem;
    END GENERATE gnecc_mem;

    rdptr_proc : PROCESS (CLK, rst_i)
    BEGIN
      IF (rst_i = '1') THEN
        rd_pntr   <= (OTHERS => '0');
      ELSIF (CLK'event AND CLK = '1') THEN
        IF (srst_rrst_busy = '1') THEN 
          rd_pntr <= (OTHERS => '0') AFTER C_TCQ;
        ELSIF (read_allow = '1') THEN
          rd_pntr <= rd_pntr + "1" AFTER C_TCQ;
        END IF;
      END IF;
    END PROCESS rdptr_proc;
   
 -------------------------------------------------------------------------------
    --Assign RD_DATA_COUNT and WR_DATA_COUNT
    -------------------------------------------------------------------------------
    rdc: IF (C_HAS_RD_DATA_COUNT=1 AND C_USE_FWFT_DATA_COUNT = 1) GENERATE
        RD_DATA_COUNT <= rd_data_count_int(C_RD_PNTR_WIDTH DOWNTO C_RD_PNTR_WIDTH+1-C_RD_DATA_COUNT_WIDTH);
    END GENERATE rdc;
 
    nrdc: IF (C_HAS_RD_DATA_COUNT=0) GENERATE
      RD_DATA_COUNT <= (OTHERS=>'0');
    END GENERATE nrdc;
    
    wdc: IF (C_HAS_WR_DATA_COUNT = 1 AND C_USE_FWFT_DATA_COUNT = 1) GENERATE
        WR_DATA_COUNT <=  wr_data_count_int(C_WR_PNTR_WIDTH DOWNTO C_WR_PNTR_WIDTH+1-C_WR_DATA_COUNT_WIDTH);
    END GENERATE wdc;
    nwdc: IF (C_HAS_WR_DATA_COUNT=0) GENERATE
      WR_DATA_COUNT <= (OTHERS=>'0');
    END GENERATE nwdc;
 
    -------------------------------------------------------------------------------
    -- Counter that determines the FWFT read duration.
    -------------------------------------------------------------------------------
    -- C_PRELOAD_LATENCY will be 0 for Non-Built-in FIFO with FWFT.
    grd_fwft: IF (C_PRELOAD_LATENCY = 0) GENERATE
      SIGNAL user_empty_fb_d1 : std_logic := '1';
    BEGIN
      grd_fwft_proc : PROCESS (CLK, rst_i)
      BEGIN
        IF (rst_i = '1') THEN
          rd_fwft_cnt <= (others => '0');
          user_empty_fb_d1 <= '1';
          stage1_valid    <= '0';
          stage2_valid    <= '0';
        ELSIF (CLK'event AND CLK = '1') THEN
         -- user_empty_fb_d1 <= USER_EMPTY_FB;
          user_empty_fb_d1 <= empty_i;
          IF (user_empty_fb_d1 = '0' AND empty_i = '1') THEN
            rd_fwft_cnt <= (others => '0') AFTER C_TCQ;
          ELSIF (empty_i = '0') THEN
            IF (RD_EN = '1' AND rd_fwft_cnt < X"5") THEN
              rd_fwft_cnt <= rd_fwft_cnt + "1" AFTER C_TCQ;
            END IF;
          END IF;
 
          IF (stage1_valid = '0' AND stage2_valid = '0') THEN
            IF (empty_i = '0') THEN
              stage1_valid    <= '1' AFTER C_TCQ;
            ELSE
              stage1_valid    <= '0' AFTER C_TCQ;
            END IF;
          ELSIF (stage1_valid = '1' AND stage2_valid = '0') THEN
            IF (empty_i = '1') THEN
              stage1_valid    <= '0' AFTER C_TCQ;
              stage2_valid    <= '1' AFTER C_TCQ;
            ELSE
              stage1_valid    <= '1' AFTER C_TCQ;
              stage2_valid    <= '1' AFTER C_TCQ;
            END IF;
          ELSIF (stage1_valid = '0' AND stage2_valid = '1') THEN
            IF (empty_i = '1' AND RD_EN_USER = '1') THEN
              stage1_valid    <= '0' AFTER C_TCQ;
              stage2_valid    <= '0' AFTER C_TCQ;
            ELSIF (empty_i = '0' AND RD_EN_USER = '1') THEN
              stage1_valid    <= '1' AFTER C_TCQ;
              stage2_valid    <= '0' AFTER C_TCQ;
            ELSIF (empty_i = '0' AND RD_EN_USER = '0') THEN
              stage1_valid    <= '1' AFTER C_TCQ;
              stage2_valid    <= '1' AFTER C_TCQ;
            ELSE
              stage1_valid    <= '0' AFTER C_TCQ;
              stage2_valid    <= '1' AFTER C_TCQ;
            END IF;
          ELSIF (stage1_valid = '1' AND stage2_valid = '1') THEN
            IF (empty_i = '1' AND RD_EN_USER = '1') THEN
              stage1_valid    <= '0' AFTER C_TCQ;
              stage2_valid    <= '1' AFTER C_TCQ;
            ELSE
              stage1_valid    <= '1' AFTER C_TCQ;
              stage2_valid    <= '1' AFTER C_TCQ;
            END IF;
          ELSE
            stage1_valid    <= '0' AFTER C_TCQ;
            stage2_valid    <= '0' AFTER C_TCQ;
          END IF;
 
        END IF;
      END PROCESS grd_fwft_proc;
    END GENERATE grd_fwft;



    -------------------------------------------------------------------------------
    -- Generate DOUT for common clock low latency FIFO
    -------------------------------------------------------------------------------
    gll_dout: IF(C_FIFO_TYPE = 2) GENERATE
      SIGNAL dout_q : STD_LOGIC_VECTOR(C_DOUT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    BEGIN
      dout_i <= memory(conv_integer(rd_pntr)) when (read_allow = '1') else dout_q;
      dout_reg : PROCESS (CLK)
      BEGIN
        IF (CLK'event AND CLK = '1') THEN
          dout_q <= dout_i AFTER C_TCQ;
        END IF;
      END PROCESS dout_reg;
    END GENERATE gll_dout;


    -------------------------------------------------------------------------------
    -- Generate FULL flag
    -------------------------------------------------------------------------------
  gpad : IF (C_WR_PNTR_WIDTH > C_RD_PNTR_WIDTH)	GENERATE
    adj_rd_pntr_wr (C_WR_PNTR_WIDTH-1 DOWNTO C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH) <= rd_pntr;
    adj_rd_pntr_wr(C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH-1 DOWNTO 0) <= (OTHERS => '0');
  END GENERATE gpad;

  gtrim : IF (C_WR_PNTR_WIDTH <= C_RD_PNTR_WIDTH) GENERATE 
    adj_rd_pntr_wr <= rd_pntr(C_RD_PNTR_WIDTH-1 DOWNTO C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH);
  END GENERATE gtrim;


    comp1         <= '1' WHEN (adj_rd_pntr_wr = (wr_pntr + "1")) ELSE '0';
    comp0         <= '1' WHEN (adj_rd_pntr_wr = wr_pntr) ELSE '0';

    gf_wp_eq_rp: IF (C_WR_PNTR_WIDTH = C_RD_PNTR_WIDTH) GENERATE
      going_full    <= (comp1 AND write_allow AND NOT read_allow);
      leaving_full  <= (comp0 AND read_allow) OR RST_FULL_GEN;
    END GENERATE gf_wp_eq_rp;

    -- Write data width is bigger than read data width
    -- Write depth is smaller than read depth
    -- One write could be equal to 2 or 4 or 8 reads
    gf_asym: IF (C_WR_PNTR_WIDTH < C_RD_PNTR_WIDTH) GENERATE
      going_full    <= comp1 AND write_allow AND (NOT (read_allow AND AND_REDUCE(rd_pntr(C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH-1 DOWNTO 0))));
      leaving_full  <= (comp0 AND read_allow AND AND_REDUCE(rd_pntr(C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH-1 DOWNTO 0))) OR RST_FULL_GEN;
    END GENERATE gf_asym;

    gf_wp_gt_rp: IF (C_WR_PNTR_WIDTH > C_RD_PNTR_WIDTH) GENERATE
      going_full    <= (comp1 AND write_allow AND NOT read_allow);
      leaving_full  <= (comp0 AND read_allow) OR RST_FULL_GEN;
    END GENERATE gf_wp_gt_rp;

    ram_full_comb <= going_full OR (NOT leaving_full AND full_i);

    full_proc : PROCESS (CLK, RST_FULL_FF)
    BEGIN
      IF (RST_FULL_FF = '1') THEN
        full_i   <= int_2_std_logic(C_FULL_FLAGS_RST_VAL);
      ELSIF (CLK'event AND CLK = '1') THEN
        IF (srst_wrst_busy = '1') THEN 
          full_i <= int_2_std_logic(C_FULL_FLAGS_RST_VAL) AFTER C_TCQ;
        ELSE
          full_i <= ram_full_comb AFTER C_TCQ;
        END IF;
      END IF;
    END PROCESS full_proc;

    -------------------------------------------------------------------------------
    -- Generate ALMOST_FULL flag
    -------------------------------------------------------------------------------

      fcomp2          <= '1' WHEN (adj_rd_pntr_wr = (wr_pntr + "10")) ELSE '0';

    gaf_wp_eq_rp: IF (C_WR_PNTR_WIDTH = C_RD_PNTR_WIDTH) GENERATE
      going_afull   <= (fcomp2 AND write_allow AND NOT read_allow);
      leaving_afull <= (comp1 AND read_allow AND NOT write_allow) OR RST_FULL_GEN;
    END GENERATE gaf_wp_eq_rp;
    gaf_wp_lt_rp: IF (C_WR_PNTR_WIDTH < C_RD_PNTR_WIDTH) GENERATE
      going_afull   <= fcomp2 AND write_allow AND (NOT (read_allow AND AND_REDUCE(rd_pntr(C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH-1 DOWNTO 0))));
      leaving_afull <= (comp1 AND (NOT write_allow) AND read_allow AND AND_REDUCE(rd_pntr(C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH-1 DOWNTO 0))) OR RST_FULL_GEN;
    END GENERATE gaf_wp_lt_rp;
    gaf_wp_gt_rp: IF (C_WR_PNTR_WIDTH > C_RD_PNTR_WIDTH) GENERATE
      going_afull   <= (fcomp2 AND write_allow AND NOT read_allow);
      leaving_afull <= ((comp0 OR comp1 OR fcomp2) AND read_allow) OR RST_FULL_GEN;
    END GENERATE gaf_wp_gt_rp;

      ram_afull_comb  <= going_afull OR (NOT leaving_afull AND almost_full_i);

      af_proc : PROCESS (CLK, RST_FULL_FF)
      BEGIN
        IF (RST_FULL_FF = '1') THEN
          almost_full_i          <= int_2_std_logic(C_FULL_FLAGS_RST_VAL);
        ELSIF (CLK'event AND CLK = '1') THEN
          IF (srst_wrst_busy = '1') THEN 
            almost_full_i          <= int_2_std_logic(C_FULL_FLAGS_RST_VAL) AFTER C_TCQ;
          ELSE
            almost_full_i          <= ram_afull_comb AFTER C_TCQ;
          END IF;
        END IF;
      END PROCESS af_proc;

    -------------------------------------------------------------------------------
    -- Generate EMPTY flag
    -------------------------------------------------------------------------------
  pad : IF (C_RD_PNTR_WIDTH>C_WR_PNTR_WIDTH) GENERATE
    adj_wr_pntr_rd(C_RD_PNTR_WIDTH-1 DOWNTO C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH)
   <= wr_pntr;
    adj_wr_pntr_rd(C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH-1 DOWNTO 0) 
   <= (OTHERS => '0');
  END GENERATE pad;

  trim : IF (C_RD_PNTR_WIDTH<=C_WR_PNTR_WIDTH)	GENERATE
    adj_wr_pntr_rd 
      <= wr_pntr(C_WR_PNTR_WIDTH-1 DOWNTO C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH);
  END GENERATE trim;

    ecomp1         <= '1' WHEN (adj_wr_pntr_rd = (rd_pntr + "1")) ELSE '0';
    ecomp0         <= '1' WHEN (adj_wr_pntr_rd = rd_pntr) ELSE '0';

  ge_wp_eq_rp: IF (C_WR_PNTR_WIDTH = C_RD_PNTR_WIDTH) GENERATE
    going_empty   <= (ecomp1 AND (NOT write_allow) AND read_allow);
    leaving_empty <= (ecomp0 AND write_allow);
  END GENERATE ge_wp_eq_rp;
  ge_wp_lt_rp: IF (C_WR_PNTR_WIDTH < C_RD_PNTR_WIDTH) GENERATE
    going_empty   <= (ecomp1 AND (NOT write_allow) AND read_allow);
    leaving_empty <= (ecomp0 AND write_allow);
  END GENERATE ge_wp_lt_rp;
  ge_wp_gt_rp: IF (C_WR_PNTR_WIDTH > C_RD_PNTR_WIDTH) GENERATE
    going_empty   <= ecomp1 AND read_allow AND (NOT(write_allow AND AND_REDUCE(wr_pntr(C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH-1 DOWNTO 0))));
    leaving_empty <= ecomp0 AND write_allow AND AND_REDUCE(wr_pntr(C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH-1 DOWNTO 0));
  END GENERATE ge_wp_gt_rp;


    ram_empty_comb <= going_empty OR (NOT leaving_empty AND empty_i);

    empty_proc : PROCESS (CLK, rst_i)
    BEGIN
      IF (rst_i = '1') THEN
        empty_i   <= '1';
      ELSIF (CLK'event AND CLK = '1') THEN
        IF (srst_rrst_busy = '1') THEN 
          empty_i <= '1' AFTER C_TCQ;
        ELSE
          empty_i <= ram_empty_comb AFTER C_TCQ;
        END IF;
      END IF;
    END PROCESS empty_proc;


    -------------------------------------------------------------------------------
    -- Generate data_count_int flags for RD_DATA_COUNT and WR_DATA_COUNT
    -------------------------------------------------------------------------------
   rd_depth_gt_wr: IF (C_WR_PNTR_WIDTH < C_RD_PNTR_WIDTH) GENERATE
     SIGNAL decr_by_one    :  std_logic := '0';
     SIGNAL incr_by_ratio  :  std_logic := '0';
     BEGIN
      ratio <= int_2_std_logic_vector(if_then_else(C_DEPTH_RATIO_RD > C_DEPTH_RATIO_WR, C_DEPTH_RATIO_RD, C_DEPTH_RATIO_WR), C_GRTR_PNTR_WIDTH+1);
      one <= int_2_std_logic_vector(1, C_GRTR_PNTR_WIDTH+1);
      decr_by_one   <= read_allow_dc;
      incr_by_ratio <= write_allow;

  cntr: PROCESS (CLK, rst_i)
  BEGIN  
    IF (rst_i = '1') THEN                   
      count_dc <= int_2_std_logic_vector(0,C_GRTR_PNTR_WIDTH+1);
    ELSIF CLK'event AND CLK = '1' THEN  
      IF (srst_wrst_busy = '1') THEN
        count_dc <= int_2_std_logic_vector(0,C_GRTR_PNTR_WIDTH+1)
          AFTER C_TCQ;
      ELSE
        IF decr_by_one = '1' THEN
          IF incr_by_ratio = '0' THEN
            count_dc <= count_dc - one AFTER C_TCQ;
          ELSE
	    count_dc <= count_dc - one  + ratio AFTER C_TCQ;
          END IF;      
	ELSE
          IF incr_by_ratio = '0' THEN
            count_dc <= count_dc AFTER C_TCQ;
          ELSE
	    count_dc <= count_dc + ratio AFTER C_TCQ;
          END IF;      
        END IF;	
      END IF;
    END IF;
  END PROCESS cntr;

  rd_data_count_int <= count_dc;
  wr_data_count_int <= count_dc(C_RD_PNTR_WIDTH DOWNTO C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH);

    END GENERATE rd_depth_gt_wr;


    wr_depth_gt_rd: IF (C_WR_PNTR_WIDTH > C_RD_PNTR_WIDTH) GENERATE
     SIGNAL incr_by_one    :  std_logic := '0';
     SIGNAL decr_by_ratio  :  std_logic := '0';
     BEGIN
      ratio <= int_2_std_logic_vector(if_then_else(C_DEPTH_RATIO_RD > C_DEPTH_RATIO_WR, C_DEPTH_RATIO_RD, C_DEPTH_RATIO_WR), C_GRTR_PNTR_WIDTH+1);
      one <= int_2_std_logic_vector(1, C_GRTR_PNTR_WIDTH+1);
      incr_by_one   <= write_allow;
      decr_by_ratio <= read_allow_dc;

  cntr: PROCESS (CLK, RST)
  BEGIN  
    IF (rst_i = '1' ) THEN                   
      count_dc <= int_2_std_logic_vector(0,C_GRTR_PNTR_WIDTH+1);
    ELSIF CLK'event AND CLK = '1' THEN  
      IF (srst_wrst_busy='1') THEN
        count_dc <= int_2_std_logic_vector(0,C_GRTR_PNTR_WIDTH+1)
          AFTER C_TCQ;
      ELSE
        IF incr_by_one = '1' THEN
          IF decr_by_ratio = '0' THEN
            count_dc <= count_dc + one AFTER C_TCQ;
          ELSE
	    count_dc <= count_dc + one  - ratio AFTER C_TCQ;
          END IF;      
	ELSE
          IF decr_by_ratio = '0' THEN
            count_dc <= count_dc AFTER C_TCQ;
          ELSE
	    count_dc <= count_dc - ratio AFTER C_TCQ;
          END IF;      
        END IF;	
      END IF;
    END IF;
  END PROCESS cntr;

  wr_data_count_int <= count_dc;
  rd_data_count_int <= count_dc(C_WR_PNTR_WIDTH DOWNTO C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH);

    END GENERATE wr_depth_gt_rd;


    -------------------------------------------------------------------------------
    -- Generate ALMOST_EMPTY flag
    -------------------------------------------------------------------------------

      ecomp2         <= '1' WHEN (adj_wr_pntr_rd = (rd_pntr + "10")) ELSE '0';

   gae_wp_eq_rp: IF (C_WR_PNTR_WIDTH = C_RD_PNTR_WIDTH) GENERATE
      going_aempty   <= (ecomp2 AND (NOT write_allow) AND read_allow);
      leaving_aempty <= (ecomp1 AND write_allow AND (NOT read_allow));
    END GENERATE gae_wp_eq_rp;
    gae_wp_lt_rp: IF (C_WR_PNTR_WIDTH < C_RD_PNTR_WIDTH) GENERATE
      going_aempty   <= (ecomp2 AND (NOT write_allow) AND read_allow);
      leaving_aempty <= ((ecomp0 OR ecomp1 OR ecomp2) AND write_allow);
    END GENERATE gae_wp_lt_rp;
    gae_wp_gt_rp: IF (C_WR_PNTR_WIDTH > C_RD_PNTR_WIDTH) GENERATE
      going_aempty   <= ecomp2 AND read_allow AND (NOT(write_allow AND AND_REDUCE(wr_pntr(C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH-1 DOWNTO 0))));
      leaving_aempty <= ecomp1 AND (NOT read_allow) AND write_allow AND AND_REDUCE(wr_pntr(C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH-1 DOWNTO 0));
    END GENERATE gae_wp_gt_rp;

      ram_aempty_comb <= going_aempty OR (NOT leaving_aempty AND almost_empty_i);

      ae_proc : PROCESS (CLK, rst_i)
      BEGIN
        IF (rst_i = '1') THEN
          almost_empty_i   <= '1';
        ELSIF (CLK'event AND CLK = '1') THEN
          IF (srst_rrst_busy = '1') THEN 
            almost_empty_i <= '1' AFTER C_TCQ;
          ELSE
            almost_empty_i <= ram_aempty_comb AFTER C_TCQ;
          END IF;
        END IF;
      END PROCESS ae_proc;
    -------------------------------------------------------------------------------
    -- synchronous FIFO using linked lists
    -------------------------------------------------------------------------------
 
    gnll_cc_fifo: IF (C_FIFO_TYPE /= 2) GENERATE
 
    FIFO_PROC : PROCESS (CLK, rst_i, wr_pntr)
 
      --Declare the linked-list head/tail pointers and the size value
      VARIABLE head              : listptr;
      VARIABLE tail              : listptr;
      VARIABLE size              : integer := 0;
      VARIABLE cntr              : integer := 0;
      VARIABLE cntr_size_var_int : integer := 0;
 
      --Data is the internal version of the DOUT bus
      VARIABLE data : std_logic_vector(c_dout_width - 1 DOWNTO 0) 
        := hexstr_to_std_logic_vec( C_DOUT_RST_VAL, c_dout_width);
      VARIABLE err_type : std_logic_vector(1 DOWNTO 0) := (OTHERS => '0'); 
 
      --Temporary values for calculating adjusted prog_empty/prog_full thresholds
      VARIABLE prog_empty_actual_assert_thresh : integer := 0;
      VARIABLE prog_empty_actual_negate_thresh : integer := 0;
      VARIABLE prog_full_actual_assert_thresh : integer := 0;
      VARIABLE prog_full_actual_negate_thresh : integer := 0;
      VARIABLE diff_pntr                      : integer := 0;
    
    BEGIN
 
      -- Calculate the current contents of the FIFO (size)
      -- Warning: This value should only be calculated once each time this
      -- process is entered.
      -- It is updated instantaneously for both write and read operations,
      -- so it is not ideal to use for signals which must consider the
      -- latency of crossing clock domains.
 
      -- cntr_size_var_int is updated only once when the process is entered
      -- This variable is used in the conditions instead of cntr which has the
      -- latest value.
      cntr_size_var_int := cntr;
 
 
      -- RESET CONDITIONS
      IF rst_i = '1' THEN
    
        wr_point           <= 0 after C_TCQ;
        wr_point_d1        <= 0 after C_TCQ;
        wr_point_d2        <= 0 after C_TCQ;
        wr_pntr_rd1        <= (OTHERS => '0') after C_TCQ;
        rd_pntr_wr         <= (OTHERS => '0') after C_TCQ;
    
        --Create new linked list
        newlist(head, tail,cntr);
 
        diff_pntr         := 0;
    
      ---------------------------------------------------------------------------
      -- Write to FIFO
      ---------------------------------------------------------------------------
      ELSIF CLK'event AND CLK = '1' THEN
      IF srst_wrst_busy = '1' THEN
    
        wr_point           <= 0 after C_TCQ;
        wr_point_d1        <= 0 after C_TCQ;
        wr_point_d2        <= 0 after C_TCQ;
        wr_pntr_rd1        <= (OTHERS => '0') after C_TCQ;
        rd_pntr_wr         <= (OTHERS => '0') after C_TCQ;
    
        --Create new linked list
        newlist(head, tail,cntr);
 
        diff_pntr         := 0;
       ELSE
        -- the binary to gray converion
        wr_pntr_rd1     <= wr_pntr after C_TCQ;
        rd_pntr_wr      <= rd_pntr_wr_d1 after C_TCQ;
 
        wr_point_d1 <= wr_point after C_TCQ;
        wr_point_d2 <= wr_point_d1 after C_TCQ;
    
        --The following IF statement setup default values of full_i and almost_full_i.
        --The values might be overwritten in the next IF statement.
          --If writing, then it is not possible to predict how many
          --words will actually be in the FIFO after the write concludes
          --(because the number of reads which happen in this time can
          -- not be determined).
          --Therefore, treat it pessimistically and always assume that
          -- the write will happen without a read (assume the FIFO is
          -- C_DEPTH_RATIO_RD fuller than it is).
          --Note:
          --1. cntr_size_var_int is the deepest depth between write depth and read depth
          --   cntr_size_var_int/C_DEPTH_RATIO_RD is number of words in the write domain.
          --2. cntr_size_var_int+C_DEPTH_RATIO_RD: number of write words in the next clock cycle
          --   if wr_en=1 (C_DEPTH_RATIO_RD=one write word)
          --3. For asymmetric FIFO, if write width is narrower than read width. Don't
          --   have to consider partial words.
          --4. For asymmetric FIFO, if read width is narrower than write width,
          --   the worse case that FIFO is going to full is depicted in the following 
          --   diagram. Both rd_pntr_a and rd_pntr_b will cause FIFO full. rd_pntr_a
          --   is the worse case. Therefore, in the calculation, actual FIFO depth is
          --   substarcted to one write word and added one read word.
          --              -------
          --              |  |  |
          --    wr_pntr-->|  |---
          --              |  |  |
          --              ---|---
          --              |  |  |
          --              |  |---
          --              |  |  |
          --              ---|---
          --              |  |  |<--rd_pntr_a
          --              |  |---
          --              |  |  |<--rd_pntr_b
          --              ---|---
          
    
        -- Update full_i and almost_full_i if user is writing to the FIFO.
        -- Assign overflow and wr_ack.

        IF WR_EN = '1' THEN
    
          IF full_i /= '1' THEN
          -- User is writing to a FIFO which is NOT reporting FULL
    
            IF cntr_size_var_int/C_DEPTH_RATIO_RD = C_FIFO_WR_DEPTH THEN
              -- FIFO really is Full
              --Report Overflow and do not acknowledge the write
    
            ELSIF cntr_size_var_int/C_DEPTH_RATIO_RD + 1 = C_FIFO_WR_DEPTH THEN
              -- FIFO is almost full
              -- This write will succeed, and FIFO will go FULL
              FOR h IN C_DEPTH_RATIO_RD DOWNTO 1 LOOP
                add(head, tail, 
                DIN((C_SMALLER_DATA_WIDTH*h)-1 DOWNTO C_SMALLER_DATA_WIDTH*(h-1)),cntr,
                (width_gt1 & INJECTDBITERR & INJECTSBITERR));
              END LOOP;
              wr_point   <= (wr_point + 1) MOD C_WR_DEPTH after C_TCQ;
    
            ELSIF cntr_size_var_int/C_DEPTH_RATIO_RD + 2 = C_FIFO_WR_DEPTH THEN
              -- FIFO is one away from almost full
              -- This write will succeed, and FIFO will go almost_full_i
              FOR h IN C_DEPTH_RATIO_RD DOWNTO 1 LOOP
                add(head, tail, 
                DIN((C_SMALLER_DATA_WIDTH*h)-1 DOWNTO C_SMALLER_DATA_WIDTH*(h-1)),cntr,
                (width_gt1 & INJECTDBITERR & INJECTSBITERR));
              END LOOP;
              wr_point    <= (wr_point + 1) MOD C_WR_DEPTH after C_TCQ;
    
            ELSE
              -- FIFO is no where near FULL
              --Write will succeed, no change in status
              FOR h IN C_DEPTH_RATIO_RD DOWNTO 1 LOOP
                add(head, tail, 
                DIN((C_SMALLER_DATA_WIDTH*h)-1 DOWNTO C_SMALLER_DATA_WIDTH*(h-1)),cntr,
                (width_gt1 & INJECTDBITERR & INJECTSBITERR));
              END LOOP;
              wr_point   <= (wr_point + 1) MOD C_WR_DEPTH after C_TCQ;
            END IF;
    
          ELSE --IF full_i = '1'
            -- User is writing to a FIFO which IS reporting FULL
            --Write will fail
          END IF;  --full_i
    
        ELSE                              --WR_EN/='1'
          --No write attempted, so neither overflow or acknowledge
        END IF;  --WR_EN
    
      END IF;  --srst
      END IF;  --CLK
    
      ---------------------------------------------------------------------------
      -- Read from FIFO
      ---------------------------------------------------------------------------
 
        IF (C_FIFO_TYPE < 2 AND C_MEMORY_TYPE < 2 AND C_USE_DOUT_RST = 1) THEN
          IF (CLK'event AND CLK = '1') THEN
           IF (rst_i = '1' OR srst_rrst_busy = '1') THEN 
           data := hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH);
          END IF;
          END IF;
        END IF;

      IF rst_i = '1' THEN
        -- Whenever user is attempting to read from
        -- an EMPTY FIFO, the core should report an underflow error, even if
        -- the core is in a RESET condition.
    
        rd_point          <= 0 after C_TCQ;
        rd_point_d1       <= 0 after C_TCQ;
        rd_pntr_wr_d1    <= (OTHERS => '0') after C_TCQ;
        wr_pntr_rd       <= (OTHERS => '0') after C_TCQ;
    
        -- DRAM resets asynchronously
        IF (C_FIFO_TYPE < 2 AND (C_MEMORY_TYPE = 2 OR C_MEMORY_TYPE = 3 )AND C_USE_DOUT_RST = 1) THEN
          data := hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH);
        END IF;
    
        -- Reset only if ECC is not selected as ECC does not support reset.
        IF (C_USE_ECC = 0) THEN
          err_type        := (OTHERS => '0');
        END IF ;
    
      ELSIF CLK'event AND CLK = '1' THEN
      --  ELSE
      IF (srst_rrst_busy= '1') THEN
       IF (C_FIFO_TYPE < 2 AND (C_MEMORY_TYPE = 2 OR C_MEMORY_TYPE = 3 ) AND C_USE_DOUT_RST = 1) THEN
            data := hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH);
          END IF;
      END IF;

      IF srst_rrst_busy = '1' THEN
        -- Whenever user is attempting to read from
        -- an EMPTY FIFO, the core should report an underflow error, even if
        -- the core is in a RESET condition.
    
        rd_point          <= 0 after C_TCQ;
        rd_point_d1       <= 0 after C_TCQ;
        rd_pntr_wr_d1    <= (OTHERS => '0') after C_TCQ;
        wr_pntr_rd       <= (OTHERS => '0') after C_TCQ;
    
        -- DRAM resets asynchronously
        IF (C_FIFO_TYPE < 2 AND C_MEMORY_TYPE = 2 AND C_USE_DOUT_RST = 1) THEN
          data := hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH);
        END IF;
    
        -- Reset only if ECC is not selected as ECC does not support reset.
        IF (C_USE_ECC = 0) THEN
          err_type        := (OTHERS => '0');
        END IF ;
    
       ELSE
 
        -- Delay the read pointer before passing to CLK domain to accommodate
        -- the binary to gray converion
        rd_pntr_wr_d1 <= rd_pntr after C_TCQ;
        wr_pntr_rd    <= wr_pntr_rd1 after C_TCQ;
 
        rd_point_d1 <= rd_point after C_TCQ;
        
        
        ---------------------------------------------------------------------------
        -- Read Latency 1
        ---------------------------------------------------------------------------
    
        --The following IF statement setup default values of empty_i and 
        --almost_empty_i. The values might be overwritten in the next IF statement.
        --Note:
        --cntr_size_var_int/C_DEPTH_RATIO_WR : number of words in read domain.
 
        IF (RD_EN = '1') THEN
    
          IF empty_i /= '1' THEN
            IF cntr_size_var_int/C_DEPTH_RATIO_WR = 2 THEN
              --FIFO is going almost empty
              FOR h IN C_DEPTH_RATIO_WR DOWNTO 1 LOOP
                read(tail, 
                data((C_SMALLER_DATA_WIDTH*h)-1 DOWNTO C_SMALLER_DATA_WIDTH*(h-1)),
                err_type);
                remove(head, tail,cntr);
              END LOOP;
              rd_point     <= (rd_point + 1) MOD C_RD_DEPTH after C_TCQ;
            
            ELSIF cntr_size_var_int/C_DEPTH_RATIO_WR = 1 THEN
              --FIFO is going empty
              FOR h IN C_DEPTH_RATIO_WR DOWNTO 1 LOOP
                read(tail, 
                data((C_SMALLER_DATA_WIDTH*h)-1 DOWNTO C_SMALLER_DATA_WIDTH*(h-1)),
                err_type);
                remove(head, tail,cntr);
              END LOOP;
              rd_point     <= (rd_point + 1) MOD C_RD_DEPTH after C_TCQ;
    
            ELSIF cntr_size_var_int/C_DEPTH_RATIO_WR = 0 THEN
            --FIFO is empty
    
            ELSE
            --FIFO is not empty
              FOR h IN C_DEPTH_RATIO_WR DOWNTO 1 LOOP
                read(tail, 
                data((C_SMALLER_DATA_WIDTH*h)-1 DOWNTO C_SMALLER_DATA_WIDTH*(h-1)),
                err_type);
                remove(head, tail,cntr);
              END LOOP;
              rd_point     <= (rd_point + 1) MOD C_RD_DEPTH after C_TCQ;
            END IF;
          ELSE
            --FIFO is empty
          END IF;
    
        END IF;  --RD_EN
    
      END IF;  --srst
      END IF;  --CLK
    
      dout_i    <= data after C_TCQ;
      sbiterr_i <= err_type(0) after C_TCQ;
      dbiterr_i <= err_type(1) after C_TCQ;
    
    END PROCESS;
   END GENERATE gnll_cc_fifo;
    


    -------------------------------------------------------------------------------
    -- Generate PROG_FULL and PROG_EMPTY flags
    -------------------------------------------------------------------------------
    gpf_pe: IF (C_PROG_FULL_TYPE /= 0 OR C_PROG_EMPTY_TYPE /= 0) GENERATE
      SIGNAL diff_pntr      : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL diff_pntr_max      : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL diff_pntr_pe   : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL diff_pntr_pe_asym   : std_logic_vector(C_RD_PNTR_WIDTH DOWNTO 0) := (OTHERS => '0');
      SIGNAL adj_wr_pntr_rd_asym   : std_logic_vector(C_RD_PNTR_WIDTH DOWNTO 0) := (OTHERS => '0');
      SIGNAL rd_pntr_asym   : std_logic_vector(C_RD_PNTR_WIDTH DOWNTO 0) := (OTHERS => '0');
      SIGNAL diff_pntr_pe_max   : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL diff_pntr_reg1      : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL diff_pntr_pe_reg1   : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL diff_pntr_reg2      : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL diff_pntr_pe_reg2   : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL write_allow_q  : std_logic := '0';
      SIGNAL read_allow_q   : std_logic := '0';
      SIGNAL write_only     : std_logic := '0';
      SIGNAL write_only_q   : std_logic := '0';
      SIGNAL read_only      : std_logic := '0';
      SIGNAL read_only_q    : std_logic := '0';
      SIGNAL prog_full_i    : std_logic := int_2_std_logic(C_FULL_FLAGS_RST_VAL);
      SIGNAL prog_empty_i   : std_logic := '1';
      SIGNAL full_reg       : std_logic := '0';
      SIGNAL rst_full_ff_reg1       : std_logic := '0';
      SIGNAL rst_full_ff_reg2       : std_logic := '0';
      SIGNAL carry          : std_logic := '0';


  CONSTANT WR_RD_RATIO_I_PF         : integer := if_then_else((C_WR_PNTR_WIDTH > C_RD_PNTR_WIDTH), (C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH), 0);
  CONSTANT WR_RD_RATIO_PF           : integer := 2**WR_RD_RATIO_I_PF;
 -- CONSTANT WR_RD_RATIO_I_PE         : integer := if_then_else((C_WR_PNTR_WIDTH < C_RD_PNTR_WIDTH), (C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH), 0);
 -- CONSTANT WR_RD_RATIO_PE           : integer := 2**WR_RD_RATIO_I_PE;
  -- EXTRA_WORDS = 2 * C_DEPTH_RATIO_WR / C_DEPTH_RATIO_RD
  -- WR_DEPTH : RD_DEPTH = 1:2 => EXTRA_WORDS = 1
  -- WR_DEPTH : RD_DEPTH = 1:4 => EXTRA_WORDS = 1 (rounded to ceiling)
  -- WR_DEPTH : RD_DEPTH = 2:1 => EXTRA_WORDS = 4
  -- WR_DEPTH : RD_DEPTH = 4:1 => EXTRA_WORDS = 8
  --CONSTANT EXTRA_WORDS       : integer := if_then_else ((C_DEPTH_RATIO_WR = 1),2,
  --                                        (2 * C_DEPTH_RATIO_WR/C_DEPTH_RATIO_RD));

  CONSTANT EXTRA_WORDS_PF       : integer := 2*WR_RD_RATIO_PF; 
  --CONSTANT EXTRA_WORDS_PE       : integer := 2*WR_RD_RATIO_PE; 


      CONSTANT C_PF_ASSERT_VAL : integer := if_then_else(C_PRELOAD_LATENCY = 0, 
                                            C_PROG_FULL_THRESH_ASSERT_VAL - EXTRA_WORDS_PF, -- FWFT 
                                            C_PROG_FULL_THRESH_ASSERT_VAL); -- STD
      CONSTANT C_PF_NEGATE_VAL : integer := if_then_else(C_PRELOAD_LATENCY = 0, 
                                            C_PROG_FULL_THRESH_NEGATE_VAL - EXTRA_WORDS_PF, -- FWFT
                                            C_PROG_FULL_THRESH_NEGATE_VAL); -- STD

      CONSTANT C_PE_ASSERT_VAL : integer := if_then_else(C_PRELOAD_LATENCY = 0,
                                            C_PROG_EMPTY_THRESH_ASSERT_VAL - 2,
                                            C_PROG_EMPTY_THRESH_ASSERT_VAL);
      CONSTANT C_PE_NEGATE_VAL : integer := if_then_else(C_PRELOAD_LATENCY = 0,
                                            C_PROG_EMPTY_THRESH_NEGATE_VAL - 2,
                                            C_PROG_EMPTY_THRESH_NEGATE_VAL);
    BEGIN
    diff_pntr_pe_max <= DIFF_MAX_RD; 

   dif_pntr_sym: IF (IS_ASYMMETRY = 0) GENERATE
    write_only <= write_allow AND NOT read_allow;
    read_only    <= read_allow    AND NOT write_allow;
   END GENERATE dif_pntr_sym; 

   dif_pntr_asym: IF (IS_ASYMMETRY = 1) GENERATE
    gpf_wp_lt_rp: IF (C_WR_PNTR_WIDTH < C_RD_PNTR_WIDTH) GENERATE
      read_only <= read_allow AND AND_REDUCE(rd_pntr(C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH-1 DOWNTO 0)) AND NOT(write_allow);
      write_only <= write_allow AND NOT (read_allow AND AND_REDUCE(rd_pntr(C_RD_PNTR_WIDTH-C_WR_PNTR_WIDTH-1 DOWNTO 0)));
    END GENERATE gpf_wp_lt_rp;
    gpf_wp_gt_rp: IF (C_WR_PNTR_WIDTH > C_RD_PNTR_WIDTH) GENERATE
      read_only <= read_allow AND NOT(write_allow AND AND_REDUCE(wr_pntr(C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH-1 DOWNTO 0)));
      write_only<= write_allow AND AND_REDUCE(wr_pntr(C_WR_PNTR_WIDTH-C_RD_PNTR_WIDTH-1 DOWNTO 0)) AND NOT(read_allow);
    END GENERATE gpf_wp_gt_rp;
   END GENERATE dif_pntr_asym; 




   dif_cal_pntr_sym: IF (IS_ASYMMETRY = 0) GENERATE
      wr_rd_q_proc : PROCESS (CLK)
      BEGIN
        IF (rst_i = '1') THEN
          write_only_q   <= '0';
          read_only_q    <= '0';
          diff_pntr_reg1       <= (OTHERS => '0');
          diff_pntr_pe_reg1    <= (OTHERS => '0');
          diff_pntr_reg2       <= (OTHERS => '0');
          diff_pntr_pe_reg2    <= (OTHERS => '0');
        ELSIF (CLK'event AND CLK = '1') THEN
          IF (srst_i = '1' OR srst_rrst_busy = '1' OR srst_wrst_busy = '1' ) THEN 
           IF (srst_rrst_busy = '1') THEN 
            read_only_q  <= '0' AFTER C_TCQ;
            diff_pntr_pe_reg1  <= (OTHERS => '0') AFTER C_TCQ;
            diff_pntr_pe_reg2    <= (OTHERS => '0');
           END IF;
           IF (srst_wrst_busy = '1') THEN 
            write_only_q <= '0' AFTER C_TCQ;
            diff_pntr_reg1     <= (OTHERS => '0') AFTER C_TCQ;
            diff_pntr_reg2       <= (OTHERS => '0');
           END IF;
          ELSE
            write_only_q <= write_only AFTER C_TCQ;
            read_only_q  <= read_only AFTER C_TCQ;
            diff_pntr_reg2 <= diff_pntr_reg1 AFTER C_TCQ;
            diff_pntr_pe_reg2 <= diff_pntr_pe_reg1 AFTER C_TCQ;

            -- Add 1 to the difference pointer value when only write happens.
            IF (write_only = '1') THEN
              diff_pntr_reg1     <= wr_pntr - adj_rd_pntr_wr + "1" AFTER C_TCQ;
            ELSE
              diff_pntr_reg1     <= wr_pntr - adj_rd_pntr_wr AFTER C_TCQ;
            END IF;

            -- Add 1 to the difference pointer value when write or both write & read or no write & read happen.
            IF (read_only = '1') THEN
              diff_pntr_pe_reg1  <= adj_wr_pntr_rd - rd_pntr - "1" AFTER C_TCQ;
            ELSE
              diff_pntr_pe_reg1  <= adj_wr_pntr_rd - rd_pntr AFTER C_TCQ;
            END IF;
          END IF;
        END IF;
      END PROCESS wr_rd_q_proc;

    diff_pntr     <=  diff_pntr_reg1(C_WR_PNTR_WIDTH-1 downto 0);
    diff_pntr_pe  <=  diff_pntr_pe_reg1(C_RD_PNTR_WIDTH-1 downto 0);

   END GENERATE dif_cal_pntr_sym; 

   dif_cal_pntr_asym: IF (IS_ASYMMETRY = 1) GENERATE
      adj_wr_pntr_rd_asym(C_RD_PNTR_WIDTH downto 1) <= adj_wr_pntr_rd; 
      adj_wr_pntr_rd_asym(0)                        <= '1'; 
      rd_pntr_asym(C_RD_PNTR_WIDTH downto 1)        <= not(rd_pntr); 
      rd_pntr_asym(0)                               <= '1'; 
      wr_rd_q_proc : PROCESS (CLK)
      BEGIN
        IF (rst_i = '1') THEN
          diff_pntr_pe_asym    <= (OTHERS => '0');
          full_reg             <= '0';
          rst_full_ff_reg1     <= '1';
          rst_full_ff_reg2     <= '1';
          diff_pntr       <= (OTHERS => '0');
        ELSIF (CLK'event AND CLK = '1') THEN
          IF (srst_i = '1' OR srst_rrst_busy = '1' OR srst_wrst_busy = '1' ) THEN 
           IF (srst_rrst_busy = '1') THEN 
            rst_full_ff_reg1     <= '1' AFTER C_TCQ;
            rst_full_ff_reg2     <= '1' AFTER C_TCQ;
            full_reg             <= '0' AFTER C_TCQ;
            diff_pntr_pe_asym  <= (OTHERS => '0') AFTER C_TCQ;
           END IF;
           IF (srst_wrst_busy = '1') THEN 
            diff_pntr     <= (OTHERS => '0') AFTER C_TCQ;
           END IF;
          ELSE
            write_only_q <= write_only AFTER C_TCQ;
            read_only_q  <= read_only AFTER C_TCQ;
            diff_pntr_reg2 <= diff_pntr_reg1 AFTER C_TCQ;
            diff_pntr_pe_reg2 <= diff_pntr_pe_reg1 AFTER C_TCQ;
            rst_full_ff_reg1 <= RST_FULL_FF AFTER C_TCQ;
            rst_full_ff_reg2 <= rst_full_ff_reg1 AFTER C_TCQ;
            full_reg         <= full_i AFTER C_TCQ;

              diff_pntr_pe_asym  <= adj_wr_pntr_rd_asym + rd_pntr_asym AFTER C_TCQ;
            IF (full_i = '0') THEN
              diff_pntr  <= wr_pntr - adj_rd_pntr_wr AFTER C_TCQ;
            END IF;
          END IF;
        END IF;
      END PROCESS wr_rd_q_proc;
  carry     <= (NOT(OR_REDUCE(diff_pntr_pe_asym (C_RD_PNTR_WIDTH downto 1))));
 diff_pntr_pe <= diff_pntr_pe_max when (full_reg = '1' AND rst_full_ff_reg2 = '0' AND carry = '1' ) else diff_pntr_pe_asym (C_RD_PNTR_WIDTH downto 1);
   END GENERATE dif_cal_pntr_asym; 

 


      -------------------------------------------------------------------------------
      -- Generate PROG_FULL flag
      -------------------------------------------------------------------------------
      gpf: IF (C_PROG_FULL_TYPE /= 0) GENERATE
        -------------------------------------------------------------------------------
        -- Generate PROG_FULL for single programmable threshold constant
        -------------------------------------------------------------------------------
        gpf1: IF (C_PROG_FULL_TYPE = 1) GENERATE
          pf1_proc : PROCESS (CLK, RST_FULL_FF)
          BEGIN
            IF (RST_FULL_FF = '1') THEN
              prog_full_i   <= int_2_std_logic(C_FULL_FLAGS_RST_VAL);
            ELSIF (CLK'event AND CLK = '1') THEN
              IF (srst_wrst_busy = '1') THEN 
                prog_full_i <= int_2_std_logic(C_FULL_FLAGS_RST_VAL) AFTER C_TCQ;
             ELSIF (IS_ASYMMETRY = 0) THEN
              IF (RST_FULL_GEN = '1') THEN 
                prog_full_i <= '0' AFTER C_TCQ;
              ELSIF ((conv_integer(diff_pntr) = C_PF_ASSERT_VAL) AND write_only_q = '1') THEN 
                prog_full_i <= '1' AFTER C_TCQ;
              ELSIF ((conv_integer(diff_pntr) = C_PF_ASSERT_VAL) AND read_only_q = '1') THEN 
                prog_full_i <= '0' AFTER C_TCQ;
              ELSE
                prog_full_i <= prog_full_i AFTER C_TCQ;
              END IF;
             ELSE
              IF (RST_FULL_GEN = '1') THEN
               prog_full_i  <= '0' AFTER C_TCQ;
              ELSIF (RST_FULL_GEN = '0') THEN 
               IF ((diff_pntr) >= C_PF_ASSERT_VAL ) THEN
                prog_full_i  <= '1' AFTER C_TCQ;
               ELSIF ((diff_pntr) < C_PF_ASSERT_VAL ) THEN
                 prog_full_i  <= '0' AFTER C_TCQ;
              ELSE
                prog_full_i  <= '0' AFTER C_TCQ;
               END IF;
              ELSE
                prog_full_i <= prog_full_i AFTER C_TCQ;
               END IF;
              END IF;
            END IF;
          END PROCESS pf1_proc;
        END GENERATE gpf1;
  
        -------------------------------------------------------------------------------
        -- Generate PROG_FULL for multiple programmable threshold constants
        -------------------------------------------------------------------------------
        gpf2: IF (C_PROG_FULL_TYPE = 2) GENERATE
          pf2_proc : PROCESS (CLK, RST_FULL_FF)
          BEGIN
            IF (RST_FULL_FF = '1' AND C_HAS_RST = 1) THEN
              prog_full_i   <= int_2_std_logic(C_FULL_FLAGS_RST_VAL);
            ELSIF (CLK'event AND CLK = '1') THEN
              IF (srst_wrst_busy = '1') THEN 
                prog_full_i <= int_2_std_logic(C_FULL_FLAGS_RST_VAL) AFTER C_TCQ;
              ELSIF (IS_ASYMMETRY = 0) THEN 
              IF (RST_FULL_GEN = '1') THEN 
                prog_full_i <= '0' AFTER C_TCQ;
              ELSIF ((conv_integer(diff_pntr) = C_PF_ASSERT_VAL) AND write_only_q = '1') THEN 
                prog_full_i <= '1' AFTER C_TCQ;
              ELSIF ((conv_integer(diff_pntr) = C_PF_NEGATE_VAL) AND read_only_q = '1') THEN 
                prog_full_i <= '0' AFTER C_TCQ;
              ELSE
                prog_full_i <= prog_full_i AFTER C_TCQ;
              END IF;
             ELSE
              IF (RST_FULL_GEN = '1') THEN
               prog_full_i <= '0' AFTER C_TCQ;
              ELSIF (RST_FULL_GEN='0') THEN
              IF (conv_integer(diff_pntr) >= C_PF_ASSERT_VAL ) THEN
               prog_full_i  <= '1' AFTER C_TCQ;
              ELSIF (conv_integer(diff_pntr) < C_PF_NEGATE_VAL) THEN
               prog_full_i  <= '0' AFTER C_TCQ;
              ELSE
               prog_full_i <= prog_full_i AFTER C_TCQ;
              END IF;
              ELSE
               prog_full_i <= prog_full_i AFTER C_TCQ;
              END IF;
             END IF;
            END IF;
          END PROCESS pf2_proc;
        END GENERATE gpf2;

        -------------------------------------------------------------------------------
        -- Generate PROG_FULL for single programmable threshold input port
        -------------------------------------------------------------------------------
        gpf3: IF (C_PROG_FULL_TYPE = 3) GENERATE
          SIGNAL pf_assert_val : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        BEGIN
          pf_assert_val <= PROG_FULL_THRESH -int_2_std_logic_vector(EXTRA_WORDS_PF,C_WR_PNTR_WIDTH)WHEN (C_PRELOAD_LATENCY = 0) ELSE PROG_FULL_THRESH;

          pf3_proc : PROCESS (CLK, RST_FULL_FF)
          BEGIN
            IF (RST_FULL_FF = '1') THEN
              prog_full_i   <= int_2_std_logic(C_FULL_FLAGS_RST_VAL);
            ELSIF (CLK'event AND CLK = '1') THEN
              IF (srst_wrst_busy = '1') THEN 
                prog_full_i <= int_2_std_logic(C_FULL_FLAGS_RST_VAL) AFTER C_TCQ;
             ELSIF (IS_ASYMMETRY = 0) THEN
              IF (RST_FULL_GEN = '1') THEN 
                prog_full_i <= '0' AFTER C_TCQ;
              ELSIF (almost_full_i = '0') THEN 
                IF (conv_integer(diff_pntr) > pf_assert_val) THEN 
                  prog_full_i <= '1' AFTER C_TCQ;
                ELSIF (conv_integer(diff_pntr) = pf_assert_val) THEN
                  IF (read_only_q = '1') THEN 
                    prog_full_i <= '0' AFTER C_TCQ;
                  ELSE
                    prog_full_i <= '1' AFTER C_TCQ;
                  END IF;
                ELSE
                  prog_full_i <= '0' AFTER C_TCQ;
                END IF;
              ELSE
                prog_full_i <= prog_full_i AFTER C_TCQ;
              END IF;
              ELSE
              IF (RST_FULL_GEN = '1') THEN
               prog_full_i  <= '0' AFTER C_TCQ;
              ELSIF (full_i='0') THEN
               IF (conv_integer(diff_pntr) >= pf_assert_val) THEN
                prog_full_i  <= '1' AFTER C_TCQ;
               ELSIF (conv_integer(diff_pntr) < pf_assert_val) THEN
                prog_full_i  <= '0' AFTER C_TCQ;
               END IF;
              ELSE
               prog_full_i <= prog_full_i AFTER C_TCQ;
             END IF;
             END IF;
            END IF;
          END PROCESS pf3_proc;
        END GENERATE gpf3;
  
        -------------------------------------------------------------------------------
        -- Generate PROG_FULL for multiple programmable threshold input ports
        -------------------------------------------------------------------------------
        gpf4: IF (C_PROG_FULL_TYPE = 4) GENERATE
          SIGNAL pf_assert_val : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
          SIGNAL pf_negate_val : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        BEGIN
          pf_assert_val <= PROG_FULL_THRESH_ASSERT -int_2_std_logic_vector(EXTRA_WORDS_PF,C_WR_PNTR_WIDTH) WHEN (C_PRELOAD_LATENCY = 0) ELSE PROG_FULL_THRESH_ASSERT;
          pf_negate_val <= PROG_FULL_THRESH_NEGATE -int_2_std_logic_vector(EXTRA_WORDS_PF,C_WR_PNTR_WIDTH) WHEN (C_PRELOAD_LATENCY = 0) ELSE PROG_FULL_THRESH_NEGATE;
  
          pf4_proc : PROCESS (CLK, RST_FULL_FF)
          BEGIN
            IF (RST_FULL_FF = '1') THEN
              prog_full_i   <= int_2_std_logic(C_FULL_FLAGS_RST_VAL);
            ELSIF (CLK'event AND CLK = '1') THEN
              IF (srst_wrst_busy = '1') THEN 
                prog_full_i <= int_2_std_logic(C_FULL_FLAGS_RST_VAL) AFTER C_TCQ;
             ELSIF (IS_ASYMMETRY = 0) THEN
              IF (RST_FULL_GEN = '1') THEN 
                prog_full_i <= '0' AFTER C_TCQ;
              ELSIF (almost_full_i = '0') THEN 
                IF (conv_integer(diff_pntr) >= pf_assert_val) THEN 
                  prog_full_i <= '1' AFTER C_TCQ;
                ELSIF (((conv_integer(diff_pntr) = pf_negate_val) AND read_only_q = '1') OR
                       (conv_integer(diff_pntr) < pf_negate_val)) THEN 
                  prog_full_i <= '0' AFTER C_TCQ;
                ELSE
                  prog_full_i <= prog_full_i AFTER C_TCQ;
                END IF;
                ELSE
                  prog_full_i <= prog_full_i AFTER C_TCQ;
                END IF;
                ELSE
                 IF (RST_FULL_GEN = '1') THEN
                  prog_full_i  <= '0' AFTER C_TCQ;
                 ELSIF (full_i='0') THEN
                 IF (conv_integer(diff_pntr) >= pf_assert_val) THEN 
                  prog_full_i  <= '1' AFTER C_TCQ;
                  ELSIF(conv_integer(diff_pntr) < pf_negate_val) THEN
                   prog_full_i  <= '0' AFTER C_TCQ;
                  ELSE
                   prog_full_i  <= prog_full_i AFTER C_TCQ;
                  END IF;
                 ELSE
                  prog_full_i <= prog_full_i AFTER C_TCQ;
                 END IF;
              END IF;
            END IF;
          END PROCESS pf4_proc;
        END GENERATE gpf4;
        PROG_FULL <= prog_full_i; 
      END GENERATE gpf;

      -------------------------------------------------------------------------------
      -- Generate PROG_EMPTY flag
      -------------------------------------------------------------------------------
      gpe: IF (C_PROG_EMPTY_TYPE /= 0) GENERATE
        -------------------------------------------------------------------------------
        -- Generate PROG_EMPTY for single programmable threshold constant
        -------------------------------------------------------------------------------
        gpe1: IF (C_PROG_EMPTY_TYPE = 1) GENERATE
          pe1_proc : PROCESS (CLK, rst_i)
          BEGIN
            IF (rst_i = '1') THEN
              prog_empty_i   <= '1';
            ELSIF (CLK'event AND CLK = '1') THEN
              IF (srst_rrst_busy = '1') THEN 
                prog_empty_i <= '1' AFTER C_TCQ;
              ELSE
               IF (IS_ASYMMETRY = 0) THEN
                IF ((conv_integer(diff_pntr_pe) = C_PE_ASSERT_VAL) AND read_only_q = '1') THEN 
                prog_empty_i <= '1' AFTER C_TCQ;
              ELSIF ((conv_integer(diff_pntr_pe) = C_PE_ASSERT_VAL) AND write_only_q = '1') THEN 
                prog_empty_i <= '0' AFTER C_TCQ;
              ELSE
                prog_empty_i <= prog_empty_i AFTER C_TCQ;
              END IF;
              ELSE
               IF (rst_i = '0') THEN
                IF (diff_pntr_pe <= (C_PE_ASSERT_VAL)) THEN
                  prog_empty_i  <= '1' AFTER C_TCQ;
                ELSIF (diff_pntr_pe > (C_PE_ASSERT_VAL)) THEN
                 prog_empty_i  <= '0' AFTER C_TCQ;
                END IF;
                ELSE
                 prog_empty_i  <= prog_empty_i AFTER C_TCQ;
                END IF;
               END IF; 
             END IF;
            END IF;
          END PROCESS pe1_proc;
        END GENERATE gpe1;

        -------------------------------------------------------------------------------
        -- Generate PROG_EMPTY for multiple programmable threshold constants
        -------------------------------------------------------------------------------
        gpe2: IF (C_PROG_EMPTY_TYPE = 2) GENERATE
          pe2_proc : PROCESS (CLK, rst_i)
          BEGIN
            IF (rst_i = '1') THEN
              prog_empty_i   <= '1';
            ELSIF (CLK'event AND CLK = '1') THEN
              IF (srst_rrst_busy = '1') THEN 
                prog_empty_i <= '1' AFTER C_TCQ;
            ELSE
              IF (IS_ASYMMETRY = 0) THEN
              IF ((conv_integer(diff_pntr_pe) = C_PE_ASSERT_VAL) AND read_only_q = '1') THEN 
                prog_empty_i <= '1' AFTER C_TCQ;
              ELSIF ((conv_integer(diff_pntr_pe) = C_PE_NEGATE_VAL) AND write_only_q = '1') THEN 
                prog_empty_i <= '0' AFTER C_TCQ;
              ELSE
                prog_empty_i <= prog_empty_i AFTER C_TCQ;
              END IF;
            ELSE
             IF (rst_i = '0') THEN
               IF (conv_integer(diff_pntr_pe) <= (C_PE_ASSERT_VAL)) THEN
                 prog_empty_i  <= '1' AFTER C_TCQ;
               ELSIF (conv_integer(diff_pntr_pe) > (C_PE_NEGATE_VAL) ) THEN
                 prog_empty_i  <= '0' AFTER C_TCQ;
               ELSE
                 prog_empty_i  <= prog_empty_i AFTER C_TCQ;
               END IF;
             ELSE
               prog_empty_i  <= prog_empty_i AFTER C_TCQ;
             END IF;
           END IF;
         END IF;

            END IF;
          END PROCESS pe2_proc;
        END GENERATE gpe2;

        -------------------------------------------------------------------------------
        -- Generate PROG_EMPTY for single programmable threshold input port
        -------------------------------------------------------------------------------
        gpe3: IF (C_PROG_EMPTY_TYPE = 3) GENERATE
          SIGNAL pe_assert_val : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        BEGIN
          pe_assert_val <= PROG_EMPTY_THRESH - "10" WHEN (C_PRELOAD_LATENCY = 0) ELSE PROG_EMPTY_THRESH;
  
          pe3_proc : PROCESS (CLK, rst_i)
          BEGIN
            IF (rst_i = '1') THEN
              prog_empty_i   <= '1';
            ELSIF (CLK'event AND CLK = '1') THEN
              IF (srst_rrst_busy = '1') THEN 
                prog_empty_i <= '1' AFTER C_TCQ;
               ELSIF (IS_ASYMMETRY = 0) THEN
              IF (almost_full_i = '0') THEN 
                IF (conv_integer(diff_pntr_pe) < pe_assert_val) THEN 
                  prog_empty_i <= '1' AFTER C_TCQ;
                ELSIF (conv_integer(diff_pntr_pe) = pe_assert_val) THEN
                  IF (write_only_q = '1') THEN 
                    prog_empty_i <= '0' AFTER C_TCQ;
                  ELSE
                    prog_empty_i <= '1' AFTER C_TCQ;
                  END IF;
                ELSE
                  prog_empty_i <= '0' AFTER C_TCQ;
                END IF;
              ELSE
                prog_empty_i <= prog_empty_i AFTER C_TCQ;
              END IF;
            ELSE
               IF (conv_integer(diff_pntr_pe) <= pe_assert_val) THEN
                prog_empty_i  <= '1' AFTER C_TCQ;
                ELSIF (conv_integer(diff_pntr_pe) > pe_assert_val) THEN
                 prog_empty_i  <= '0' AFTER C_TCQ;
               ELSE
                prog_empty_i      <= prog_empty_i AFTER C_TCQ;
                END IF;
            END IF;
            END IF;
          END PROCESS pe3_proc;
        END GENERATE gpe3;

        -------------------------------------------------------------------------------
        -- Generate PROG_EMPTY for multiple programmable threshold input ports
        -------------------------------------------------------------------------------
        gpe4: IF (C_PROG_EMPTY_TYPE = 4) GENERATE
          SIGNAL pe_assert_val : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
          SIGNAL pe_negate_val : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        BEGIN
          pe_assert_val <= PROG_EMPTY_THRESH_ASSERT - "10" WHEN (C_PRELOAD_LATENCY = 0) ELSE PROG_EMPTY_THRESH_ASSERT;
          pe_negate_val <= PROG_EMPTY_THRESH_NEGATE - "10" WHEN (C_PRELOAD_LATENCY = 0) ELSE PROG_EMPTY_THRESH_NEGATE;
  
          pe4_proc : PROCESS (CLK, rst_i)
          BEGIN
            IF (rst_i = '1') THEN
              prog_empty_i   <= '1';
            ELSIF (CLK'event AND CLK = '1') THEN
              IF (srst_rrst_busy = '1') THEN 
                prog_empty_i <= '1' AFTER C_TCQ;
             ELSIF (IS_ASYMMETRY = 0) THEN
              IF (almost_full_i = '0') THEN 
                IF (conv_integer(diff_pntr_pe) <= pe_assert_val) THEN 
                  prog_empty_i <= '1' AFTER C_TCQ;
                ELSIF (((conv_integer(diff_pntr_pe) = pe_negate_val) AND write_only_q = '1') OR
                       (conv_integer(diff_pntr_pe) > pe_negate_val)) THEN 
                  prog_empty_i <= '0' AFTER C_TCQ;
                ELSE
                  prog_empty_i <= prog_empty_i AFTER C_TCQ;
                END IF;
              ELSE
                prog_empty_i <= prog_empty_i AFTER C_TCQ;
              END IF;
            ELSE
              IF (conv_integer(diff_pntr_pe) <= (pe_assert_val)) THEN
               prog_empty_i  <= '1' AFTER C_TCQ;
              ELSIF (conv_integer(diff_pntr_pe) > pe_negate_val) THEN
                prog_empty_i  <= '0' AFTER C_TCQ;
              ELSE
               prog_empty_i  <= prog_empty_i AFTER C_TCQ;
             END IF;
         END IF;
            END IF;
          END PROCESS pe4_proc;
        END GENERATE gpe4;
        PROG_EMPTY <= prog_empty_i; 
      END GENERATE gpe;
    END GENERATE gpf_pe;

-------------------------------------------------------------------------------
  -- overflow_i generation: Synchronous FIFO
-------------------------------------------------------------------------------
  govflw: IF (C_HAS_OVERFLOW = 1) GENERATE
    g7s_ovflw: IF (NOT (C_FAMILY = "virtexu" OR C_FAMILY = "kintexu" OR C_FAMILY = "artixu" OR C_FAMILY = "virtexuplus" OR C_FAMILY = "zynquplus" OR C_FAMILY = "kintexuplus")) GENERATE
      povflw: PROCESS (CLK)
      BEGIN
        IF CLK'event AND CLK = '1' THEN
          overflow_i  <= full_i AND WR_EN after C_TCQ;
        END IF;
      END PROCESS povflw;
    END GENERATE g7s_ovflw;
    g8s_ovflw: IF ((C_FAMILY = "virtexu" OR C_FAMILY = "kintexu" OR C_FAMILY = "artixu" OR C_FAMILY = "virtexuplus" OR C_FAMILY = "zynquplus" OR C_FAMILY = "kintexuplus")) GENERATE
      povflw: PROCESS (CLK)
      BEGIN
        IF CLK'event AND CLK = '1' THEN
          overflow_i  <= (WR_RST_BUSY OR full_i) AND WR_EN after C_TCQ;
        END IF;
      END PROCESS povflw;
    END GENERATE g8s_ovflw;
  END GENERATE govflw;

-------------------------------------------------------------------------------
  -- underflow_i generation: Synchronous FIFO
-------------------------------------------------------------------------------
  gunflw: IF (C_HAS_UNDERFLOW = 1) GENERATE
    g7s_unflw: IF (NOT (C_FAMILY = "virtexu" OR C_FAMILY = "kintexu" OR C_FAMILY = "artixu" OR C_FAMILY = "virtexuplus" OR C_FAMILY = "zynquplus" OR C_FAMILY = "kintexuplus")) GENERATE
      punflw: PROCESS (CLK)
      BEGIN
        IF CLK'event AND CLK = '1' THEN
          underflow_i <= empty_i and RD_EN after C_TCQ;
        END IF;
      END PROCESS punflw;
    END GENERATE g7s_unflw;
    g8s_unflw: IF ((C_FAMILY = "virtexu" OR C_FAMILY = "kintexu" OR C_FAMILY = "artixu" OR C_FAMILY = "virtexuplus" OR C_FAMILY = "zynquplus" OR C_FAMILY = "kintexuplus")) GENERATE
      punflw: PROCESS (CLK)
      BEGIN
        IF CLK'event AND CLK = '1' THEN
          underflow_i <= (RD_RST_BUSY OR empty_i) and RD_EN after C_TCQ;
        END IF;
      END PROCESS punflw;
    END GENERATE g8s_unflw;
  END GENERATE gunflw;

-------------------------------------------------------------------------------
  -- wr_ack_i generation: Synchronous FIFO
-------------------------------------------------------------------------------
  gwack: IF (C_HAS_WR_ACK = 1) GENERATE
    pwack: PROCESS (CLK,rst_i)
    BEGIN
      IF rst_i = '1' THEN
        wr_ack_i           <= '0' after C_TCQ;
      ELSIF CLK'event AND CLK = '1' THEN
        wr_ack_i     <= '0' after C_TCQ;
        IF srst_wrst_busy = '1' THEN
           wr_ack_i     <= '0' after C_TCQ;
        ELSIF WR_EN = '1' THEN
            IF full_i /= '1' THEN
              wr_ack_i <= '1' after C_TCQ;
            END IF;
        END IF;
      END IF;
    END PROCESS pwack;
  END GENERATE gwack;

 -----------------------------------------------------------------------------
  -- valid_i generation: Synchronous FIFO
  -----------------------------------------------------------------------------
gvld_i: IF (C_HAS_VALID = 1) GENERATE

    PROCESS (rst_i  , CLK  )
    BEGIN
      IF rst_i = '1' THEN
        valid_i           <= '0' after C_TCQ;
      ELSIF CLK'event AND CLK = '1' THEN
        IF srst_rrst_busy = '1' THEN
           valid_i     <= '0' after C_TCQ;
        ELSE --srst_i=0
           -- Setup default value for underflow and valid
           valid_i     <= '0' after C_TCQ;
           IF RD_EN = '1' THEN
             IF empty_i /= '1' THEN
               valid_i <= '1' after C_TCQ;
             END IF;
           END IF;
        END IF;
      END IF;
    END PROCESS;
 END GENERATE gvld_i;

  -----------------------------------------------------------------------------
  --Delay Valid AND DOUT 
  --if C_MEMORY_TYPE=0 or 1, C_USE_EMBEDDED_REG=1, STD
  -----------------------------------------------------------------------------
  gnll_fifo1: IF (C_FIFO_TYPE < 2) GENERATE
    gv0: IF (C_USE_EMBEDDED_REG>0 AND (NOT (C_PRELOAD_REGS = 1 AND C_PRELOAD_LATENCY = 0))
             AND (C_MEMORY_TYPE=0 OR C_MEMORY_TYPE=1) AND C_EN_SAFETY_CKT = 0) GENERATE
      PROCESS (rst_i  , CLK  )
      BEGIN
        IF (rst_i   = '1') THEN
          IF (C_USE_DOUT_RST = 1) THEN
            IF (CLK'event AND CLK = '1') THEN
              DOUT     <= hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH) after C_TCQ;
            END IF;
          END IF;
          IF (C_USE_ECC = 0) THEN
            SBITERR  <= '0' after C_TCQ;
            DBITERR  <= '0' after C_TCQ;
          END IF;
          ram_rd_en_d1 <= '0' after C_TCQ;
          valid_d1 <= '0' after C_TCQ;
        ELSIF (CLK  'event AND CLK   = '1') THEN
          ram_rd_en_d1 <= RD_EN AND (NOT empty_i) after C_TCQ;
          valid_d1 <= valid_i after C_TCQ;
          IF (srst_rrst_busy = '1') THEN
            IF (C_USE_DOUT_RST = 1) THEN
              DOUT     <= hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH) after C_TCQ;
            END IF;
            ram_rd_en_d1 <= '0' after C_TCQ;
            valid_d1     <= '0' after C_TCQ;
          ELSIF (ram_rd_en_d1 = '1') THEN
            DOUT     <= dout_i after C_TCQ;
            SBITERR  <= sbiterr_i after C_TCQ;
            DBITERR  <= dbiterr_i after C_TCQ;
          END IF;
        END IF;
      END PROCESS;
    END GENERATE gv0;
   gv1: IF (C_USE_EMBEDDED_REG>0 AND (NOT (C_PRELOAD_REGS = 1 AND C_PRELOAD_LATENCY = 0))
             AND (C_MEMORY_TYPE=0 OR C_MEMORY_TYPE=1) AND C_EN_SAFETY_CKT = 1) GENERATE
     SIGNAL dout_rst_val_d2 : std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
     SIGNAL dout_rst_val_d1 : std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
     SIGNAL rst_delayed_sft1 : std_logic := '1';
     SIGNAL rst_delayed_sft2 : std_logic := '1';
     SIGNAL rst_delayed_sft3 : std_logic := '1';
     SIGNAL rst_delayed_sft4 : std_logic := '1';
     BEGIN

     PROCESS ( CLK  )
      BEGIN
	rst_delayed_sft1 <= rst_i;
	rst_delayed_sft2 <= rst_delayed_sft1;
	rst_delayed_sft3 <= rst_delayed_sft2;
	rst_delayed_sft4 <= rst_delayed_sft3;
      END PROCESS;

     PROCESS (rst_delayed_sft4  ,rst_i, CLK  )
      BEGIN
        IF (rst_delayed_sft4   = '1' OR rst_i = '1') THEN
          valid_d1 <= '0' after C_TCQ;
          ram_rd_en_d1 <= '0' after C_TCQ;
        ELSIF (CLK  'event AND CLK   = '1') THEN
          valid_d1 <= valid_i after C_TCQ;
          ram_rd_en_d1 <= RD_EN AND (NOT empty_i) after C_TCQ;
        END IF;
      END PROCESS;


      PROCESS (rst_delayed_sft4  ,  CLK  )
      BEGIN
        IF (rst_delayed_sft4   = '1') THEN
          IF (C_USE_DOUT_RST = 1) THEN
            IF (CLK'event AND CLK = '1') THEN
              DOUT     <= hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH) after C_TCQ;
            END IF;
          END IF;
          IF (C_USE_ECC = 0) THEN
            SBITERR  <= '0' after C_TCQ;
            DBITERR  <= '0' after C_TCQ;
          END IF;
          --ram_rd_en_d1 <= '0' after C_TCQ;
          --valid_d1 <= '0' after C_TCQ;
        ELSIF (CLK  'event AND CLK   = '1') THEN
          --ram_rd_en_d1 <= RD_EN AND (NOT empty_i) after C_TCQ;
          --valid_d1 <= valid_i after C_TCQ;
          IF (srst_rrst_busy = '1') THEN
            IF (C_USE_DOUT_RST = 1) THEN
              DOUT     <= hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH) after C_TCQ;
            END IF;
            --ram_rd_en_d1 <= '0' after C_TCQ;
            --valid_d1     <= '0' after C_TCQ;
          ELSIF (ram_rd_en_d1 = '1') THEN
            DOUT     <= dout_i after C_TCQ;
            SBITERR  <= sbiterr_i after C_TCQ;
            DBITERR  <= dbiterr_i after C_TCQ;
          END IF;
        END IF;
      END PROCESS;
    END GENERATE gv1;

  END GENERATE gnll_fifo1;

  gv1: IF (C_FIFO_TYPE = 2 OR (NOT(C_USE_EMBEDDED_REG>0 AND (NOT (C_PRELOAD_REGS = 1 AND C_PRELOAD_LATENCY = 0))
              AND (C_MEMORY_TYPE=0 OR C_MEMORY_TYPE=1)))) GENERATE
    valid_d1 <= valid_i;
    DOUT     <= dout_i;
    SBITERR  <= sbiterr_i;
    DBITERR  <= dbiterr_i;
  END GENERATE gv1;
  --END GENERATE gnll_fifo;



END behavioral;


--#############################################################################
--#############################################################################
--  Preload Latency 0 (First-Word Fall-Through) Module
--#############################################################################
--#############################################################################
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_arith.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY fifo_generator_v13_0_0_bhv_preload0 IS

  GENERIC (
    C_DOUT_RST_VAL           : string  := "";
    C_DOUT_WIDTH             : integer := 8;
    C_HAS_RST                : integer := 0;
    C_HAS_SRST               : integer := 0;
    C_USE_DOUT_RST           : integer := 0;
    C_USE_ECC                : integer := 0;
    C_USERVALID_LOW          : integer := 0;
    C_USERUNDERFLOW_LOW      : integer := 0;
    C_EN_SAFETY_CKT          : integer := 0;
    C_TCQ                    : time    := 100 ps;
    C_ENABLE_RST_SYNC        : integer := 1;
    C_ERROR_INJECTION_TYPE   : integer := 0;
    C_MEMORY_TYPE            : integer := 0;
    C_FIFO_TYPE              : integer := 0
   );
  PORT (
    RD_CLK          : IN  std_logic;
    RD_RST          : IN  std_logic;
    SRST            : IN  std_logic;
    WR_RST_BUSY     : IN  std_logic;
    RD_RST_BUSY     : IN  std_logic;
    RD_EN           : IN  std_logic;
    FIFOEMPTY       : IN  std_logic;
    FIFODATA        : IN  std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
    FIFOSBITERR     : IN  std_logic;
    FIFODBITERR     : IN  std_logic;
    USERDATA        : OUT std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
    USERVALID       : OUT std_logic;
    USERUNDERFLOW   : OUT std_logic;
    USEREMPTY       : OUT std_logic;
    USERALMOSTEMPTY : OUT std_logic;
    RAMVALID        : OUT std_logic;
    FIFORDEN        : OUT std_logic;
    USERSBITERR     : OUT std_logic := '0';
    USERDBITERR     : OUT std_logic := '0';
    STAGE2_REG_EN   : OUT std_logic;
    VALID_STAGES    : OUT std_logic_vector(1 DOWNTO 0) := (OTHERS => '0')
    );

END fifo_generator_v13_0_0_bhv_preload0;

ARCHITECTURE behavioral OF fifo_generator_v13_0_0_bhv_preload0 IS

  -----------------------------------------------------------------------------
  -- FUNCTION hexstr_to_std_logic_vec
  -- Returns a std_logic_vector for a hexadecimal string
  -------------------------------------------------------------------------------

    FUNCTION hexstr_to_std_logic_vec( 
      arg1 : string; 
      size : integer ) 
    RETURN std_logic_vector IS
      VARIABLE result : std_logic_vector(size-1 DOWNTO 0) := (OTHERS => '0');
      VARIABLE bin    : std_logic_vector(3 DOWNTO 0);
      VARIABLE index  : integer                           := 0;
    BEGIN
      FOR i IN arg1'reverse_range LOOP
        CASE arg1(i) IS
          WHEN '0' => bin := (OTHERS => '0');
          WHEN '1' => bin := (0 => '1', OTHERS => '0');
          WHEN '2' => bin := (1 => '1', OTHERS => '0');
          WHEN '3' => bin := (0 => '1', 1 => '1', OTHERS => '0');
          WHEN '4' => bin := (2 => '1', OTHERS => '0');
          WHEN '5' => bin := (0 => '1', 2 => '1', OTHERS => '0');
          WHEN '6' => bin := (1 => '1', 2 => '1', OTHERS => '0');
          WHEN '7' => bin := (3 => '0', OTHERS => '1');
          WHEN '8' => bin := (3 => '1', OTHERS => '0');
          WHEN '9' => bin := (0 => '1', 3 => '1', OTHERS => '0');
          WHEN 'A' => bin := (0 => '0', 2 => '0', OTHERS => '1');
          WHEN 'a' => bin := (0 => '0', 2 => '0', OTHERS => '1');
          WHEN 'B' => bin := (2 => '0', OTHERS => '1');
          WHEN 'b' => bin := (2 => '0', OTHERS => '1');
          WHEN 'C' => bin := (0 => '0', 1 => '0', OTHERS => '1');
          WHEN 'c' => bin := (0 => '0', 1 => '0', OTHERS => '1');
          WHEN 'D' => bin := (1 => '0', OTHERS => '1');
          WHEN 'd' => bin := (1 => '0', OTHERS => '1');
          WHEN 'E' => bin := (0 => '0', OTHERS => '1');
          WHEN 'e' => bin := (0 => '0', OTHERS => '1');
          WHEN 'F' => bin := (OTHERS => '1');
          WHEN 'f' => bin := (OTHERS => '1');
          WHEN OTHERS =>
            FOR j IN 0 TO 3 LOOP
              bin(j) := 'X';
            END LOOP;
        END CASE;
        FOR j IN 0 TO 3 LOOP
          IF (index*4)+j < size THEN
            result((index*4)+j) := bin(j);
          END IF;
        END LOOP;
        index := index + 1;
      END LOOP;
      RETURN result;
    END hexstr_to_std_logic_vec;


  SIGNAL USERDATA_int : std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0) := hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH);
  SIGNAL preloadstage1     : std_logic := '0';
  SIGNAL preloadstage2     : std_logic := '0';
  SIGNAL ram_valid_i       : std_logic := '0';
  SIGNAL read_data_valid_i : std_logic := '0';
  SIGNAL ram_regout_en     : std_logic := '0';
  SIGNAL ram_rd_en         : std_logic := '0';
  SIGNAL empty_i           : std_logic := '1';
  SIGNAL empty_q           : std_logic := '1';
  SIGNAL rd_en_q           : std_logic := '0';
  SIGNAL almost_empty_i    : std_logic := '1';
  SIGNAL almost_empty_q    : std_logic := '1';
  SIGNAL rd_rst_i          : std_logic := '0';
  SIGNAL srst_i            : std_logic := '0';


BEGIN  -- behavioral

  grst: IF (C_HAS_RST = 1 OR C_ENABLE_RST_SYNC = 0) GENERATE
    rd_rst_i <= RD_RST;
  end generate grst;
  
  ngrst: IF (C_HAS_RST = 0 AND C_ENABLE_RST_SYNC = 1) GENERATE
    rd_rst_i <= '0';
  END GENERATE ngrst;
  
   
  --SRST
  gsrst  : IF (C_HAS_SRST=1) GENERATE
    srst_i <= SRST OR WR_RST_BUSY OR RD_RST_BUSY;
  END GENERATE gsrst;
   
  --SRST
  ngsrst  : IF (C_HAS_SRST=0) GENERATE
    srst_i <= '0';
  END GENERATE ngsrst;
  

  gnll_fifo: IF (C_FIFO_TYPE /= 2) GENERATE
    CONSTANT INVALID             : std_logic_vector (1 downto 0) := "00";
    CONSTANT STAGE1_VALID        : std_logic_vector (1 downto 0) := "10";
    CONSTANT STAGE2_VALID        : std_logic_vector (1 downto 0) := "01";
    CONSTANT BOTH_STAGES_VALID   : std_logic_vector (1 downto 0) := "11";

    SIGNAL curr_fwft_state       : std_logic_vector (1 DOWNTO 0) := INVALID; 
    SIGNAL next_fwft_state       : std_logic_vector (1 DOWNTO 0) := INVALID;
  BEGIN

    proc_fwft_fsm : PROCESS ( curr_fwft_state, RD_EN, FIFOEMPTY)
    BEGIN
      
     CASE curr_fwft_state IS
     
       WHEN INVALID =>
         IF (FIFOEMPTY = '0') THEN
           next_fwft_state     <= STAGE1_VALID;
         ELSE --FIFOEMPTY = '1' 
           next_fwft_state     <= INVALID;
         END IF;
  
       WHEN STAGE1_VALID =>
         IF (FIFOEMPTY = '1') THEN
           next_fwft_state     <= STAGE2_VALID;
         ELSE -- FIFOEMPTY = '0'
             next_fwft_state     <= BOTH_STAGES_VALID;
         END IF;
       
       WHEN STAGE2_VALID =>
         IF (FIFOEMPTY = '1' AND RD_EN = '1') THEN
           next_fwft_state     <= INVALID;
         ELSIF (FIFOEMPTY = '0' AND RD_EN = '1') THEN
           next_fwft_state     <= STAGE1_VALID;
         ELSIF (FIFOEMPTY = '0' AND RD_EN = '0') THEN
           next_fwft_state     <= BOTH_STAGES_VALID;
         ELSE -- FIFOEMPTY = '1' AND RD_EN = '0' 
           next_fwft_state     <= STAGE2_VALID;
         END IF;
  
       WHEN BOTH_STAGES_VALID =>
         IF (FIFOEMPTY = '1' AND RD_EN = '1') THEN
           next_fwft_state     <= STAGE2_VALID;
         ELSIF (FIFOEMPTY = '0' AND RD_EN = '1') THEN
           next_fwft_state     <= BOTH_STAGES_VALID;
         ELSE -- RD_EN = '0' 
           next_fwft_state     <= BOTH_STAGES_VALID;
         END IF;
  
       WHEN OTHERS =>
        next_fwft_state     <= INVALID;
        
      END CASE;
    END PROCESS proc_fwft_fsm;

    proc_fsm_reg: PROCESS (rd_rst_i, RD_CLK)
    BEGIN
      IF (rd_rst_i = '1') THEN
        curr_fwft_state  <= INVALID;
      ELSIF (RD_CLK'event AND RD_CLK='1') THEN
          IF (srst_i = '1') THEN
            curr_fwft_state  <= INVALID AFTER C_TCQ;
          ELSE
            curr_fwft_state  <= next_fwft_state AFTER C_TCQ;
          END IF; 
      END IF; 
    END PROCESS proc_fsm_reg;

    proc_regen: PROCESS (curr_fwft_state, FIFOEMPTY, RD_EN)
    BEGIN
      CASE curr_fwft_state IS
      
        WHEN INVALID =>
          STAGE2_REG_EN <= '0';
        WHEN STAGE1_VALID =>
          STAGE2_REG_EN <= '1';
        WHEN STAGE2_VALID =>
          STAGE2_REG_EN <= '0';
        WHEN BOTH_STAGES_VALID =>
          IF (RD_EN = '1') THEN
           STAGE2_REG_EN <= '1';
          ELSE
            STAGE2_REG_EN <= '0';
          END IF;
        WHEN OTHERS =>
          STAGE2_REG_EN <= '0';
      END CASE;
    END PROCESS proc_regen;

    VALID_STAGES <= curr_fwft_state;
    --------------------------------------------------------------------------------
    --  preloadstage2 indicates that stage2 needs to be updated. This is true
    --  whenever read_data_valid is false, and RAM_valid is true.
    --------------------------------------------------------------------------------
    preloadstage2 <= ram_valid_i AND (NOT read_data_valid_i OR RD_EN);
    
    --------------------------------------------------------------------------------
    --  preloadstage1 indicates that stage1 needs to be updated. This is true
    --  whenever the RAM has data (RAM_EMPTY is false), and either RAM_Valid is
    --  false (indicating that Stage1 needs updating), or preloadstage2 is active
    --  (indicating that Stage2 is going to update, so Stage1, therefore, must
    --  also be updated to keep it valid.
    --------------------------------------------------------------------------------
      preloadstage1 <= (((NOT ram_valid_i) OR preloadstage2) AND (NOT FIFOEMPTY));
  
    --------------------------------------------------------------------------------
    -- Calculate RAM_REGOUT_EN
    --  The output registers are controlled by the ram_regout_en signal.
    --  These registers should be updated either when the output in Stage2 is
    --  invalid (preloadstage2), OR when the user is reading, in which case the
    --  Stage2 value will go invalid unless it is replenished.
    --------------------------------------------------------------------------------
    ram_regout_en <= preloadstage2;

    --------------------------------------------------------------------------------
    -- Calculate RAM_RD_EN
    --   RAM_RD_EN will be asserted whenever the RAM needs to be read in order to
    --  update the value in Stage1.
    --   One case when this happens is when preloadstage1=true, which indicates
    --  that the data in Stage1 or Stage2 is invalid, and needs to automatically
    --  be updated.
    --   The other case is when the user is reading from the FIFO, which guarantees
    --  that Stage1 or Stage2 will be invalid on the next clock cycle, unless it is
    --  replinished by data from the memory. So, as long as the RAM has data in it,
    --  a read of the RAM should occur.
    --------------------------------------------------------------------------------
    ram_rd_en     <= (RD_EN AND NOT FIFOEMPTY) OR preloadstage1;

    
  END GENERATE gnll_fifo;

  gll_fifo: IF (C_FIFO_TYPE = 2) GENERATE
    SIGNAL empty_d1                : STD_LOGIC := '1';
    SIGNAL fe_of_empty             : STD_LOGIC := '0';
    SIGNAL curr_state              : STD_LOGIC := '0';
    SIGNAL next_state              : STD_LOGIC := '0';
    SIGNAL leaving_empty_fwft      : STD_LOGIC := '0';
    SIGNAL going_empty_fwft        : STD_LOGIC := '0';
  BEGIN
    fsm_proc: PROCESS (curr_state, FIFOEMPTY, RD_EN)
    BEGIN
      CASE curr_state IS
        WHEN '0' =>
          IF (FIFOEMPTY = '0') THEN
            next_state <= '1';
          ELSE
            next_state <= '0';
          END IF; 
        WHEN '1' =>
          IF (FIFOEMPTY = '1' AND RD_EN = '1') THEN
            next_state <= '0';
          ELSE
            next_state <= '1';
          END IF; 
        WHEN OTHERS =>
          next_state <= '0';
      END CASE;
    END PROCESS fsm_proc;

    empty_reg: PROCESS (RD_CLK, rd_rst_i)
    BEGIN
      IF (rd_rst_i = '1') THEN
        empty_d1      <= '1';
        empty_i       <= '1';
        ram_valid_i   <= '0';
        curr_state    <= '0';
      ELSIF (RD_CLK'event AND RD_CLK='1') THEN
        IF (srst_i = '1') THEN
          empty_d1    <= '1' AFTER C_TCQ;
          empty_i     <= '1' AFTER C_TCQ;
          ram_valid_i <= '0' AFTER C_TCQ;
          curr_state  <= '0' AFTER C_TCQ;
        ELSE
          empty_d1    <= FIFOEMPTY AFTER C_TCQ;
          curr_state  <= next_state AFTER C_TCQ;
          empty_i     <= going_empty_fwft OR (NOT leaving_empty_fwft AND empty_i) AFTER C_TCQ; 
          ram_valid_i <= next_state AFTER C_TCQ;
        END IF; 
      END IF; 
    END PROCESS empty_reg;
    fe_of_empty <= empty_d1 AND (NOT FIFOEMPTY);

    prege: PROCESS (curr_state, FIFOEMPTY, RD_EN)
    BEGIN
      CASE curr_state IS
        WHEN '0' =>
          IF (FIFOEMPTY = '0') THEN
            ram_regout_en      <= '1';
            ram_rd_en          <= '1';
          ELSE
            ram_regout_en      <= '0';
            ram_rd_en          <= '0';
          END IF; 
        WHEN '1' =>
          IF (FIFOEMPTY = '0' AND RD_EN = '1') THEN
            ram_regout_en <= '1';
            ram_rd_en     <= '1';
          ELSE
            ram_regout_en <= '0';
            ram_rd_en     <= '0';
          END IF; 
        WHEN OTHERS =>
          ram_regout_en      <= '0';
          ram_rd_en          <= '0';
      END CASE;
    END PROCESS prege;

    ple: PROCESS (curr_state, fe_of_empty) -- Leaving Empty
    BEGIN
      CASE curr_state IS
        WHEN '0' =>
          leaving_empty_fwft   <= fe_of_empty;
        WHEN '1' =>
          leaving_empty_fwft <= '1';
        WHEN OTHERS =>
          leaving_empty_fwft <= '0';
      END CASE;
    END PROCESS ple;

    pge: PROCESS (curr_state, FIFOEMPTY, RD_EN) -- Going Empty
    BEGIN
      CASE curr_state IS
        WHEN '1' =>
          IF (FIFOEMPTY = '1' AND RD_EN = '1') THEN
            going_empty_fwft <= '1';
          ELSE
            going_empty_fwft <= '0';
          END IF;
        WHEN OTHERS =>
          going_empty_fwft   <= '0';
      END CASE;
    END PROCESS pge;
  END GENERATE gll_fifo;
  
  --------------------------------------------------------------------------------
  -- Calculate ram_valid
  --   ram_valid indicates that the data in Stage1 is valid.
  --
  --   If the RAM is being read from on this clock cycle (ram_rd_en=1), then
  --   ram_valid is certainly going to be true.
  --   If the RAM is not being read from, but the output registers are being
  --   updated to fill Stage2 (ram_regout_en=1), then Stage1 will be emptying,
  --   therefore causing ram_valid to be false.
  --   Otherwise, ram_valid will remain unchanged.
  --------------------------------------------------------------------------------
  gvalid: IF (C_FIFO_TYPE < 2) GENERATE
    regout_valid: PROCESS (RD_CLK, rd_rst_i)
    BEGIN  -- PROCESS regout_valid
      IF rd_rst_i = '1' THEN                -- asynchronous reset (active high)
        ram_valid_i <= '0' after C_TCQ;
      ELSIF RD_CLK'event AND RD_CLK = '1' THEN  -- rising clock edge
        IF srst_i = '1' THEN                -- synchronous reset (active high)
          ram_valid_i <= '0' after C_TCQ;
        ELSE
          IF ram_rd_en = '1' THEN
            ram_valid_i <= '1' after C_TCQ;
          ELSE
            IF ram_regout_en = '1' THEN
              ram_valid_i <= '0' after C_TCQ;
            ELSE
              ram_valid_i <= ram_valid_i after C_TCQ;
            END IF;
          END IF;
        END IF;
      END IF;
    END PROCESS regout_valid;
  END GENERATE gvalid;
  
  --------------------------------------------------------------------------------
  -- Calculate READ_DATA_VALID
  --  READ_DATA_VALID indicates whether the value in Stage2 is valid or not.
  --  Stage2 has valid data whenever Stage1 had valid data and ram_regout_en_i=1,
  --  such that the data in Stage1 is propogated into Stage2.
  --------------------------------------------------------------------------------
  regout_dvalid : PROCESS (RD_CLK, rd_rst_i)
  BEGIN
    IF (rd_rst_i='1') THEN
      read_data_valid_i <= '0' after C_TCQ;
    ELSIF (RD_CLK'event AND RD_CLK='1') THEN
      IF (srst_i='1') THEN
        read_data_valid_i <= '0' after C_TCQ;
      ELSE
        read_data_valid_i <= ram_valid_i OR (read_data_valid_i AND NOT RD_EN) after C_TCQ;
      END IF;
    END IF; --RD_CLK
  END PROCESS regout_dvalid;
  
  -------------------------------------------------------------------------------
  -- Calculate EMPTY
  --  Defined as the inverse of READ_DATA_VALID
  --
  -- Description:
  --
  --  If read_data_valid_i indicates that the output is not valid,
  -- and there is no valid data on the output of the ram to preload it
  -- with, then we will report empty.
  --
  --  If there is no valid data on the output of the ram and we are
  -- reading, then the FIFO will go empty.
  --
  
  -------------------------------------------------------------------------------
  gempty: IF (C_FIFO_TYPE < 2) GENERATE
    regout_empty :  PROCESS (RD_CLK, rd_rst_i)       --This is equivalent to (NOT read_data_valid_i)
    BEGIN
      IF (rd_rst_i='1') THEN
        empty_i <= '1' after C_TCQ;
      ELSIF (RD_CLK'event AND RD_CLK='1') THEN
        IF (srst_i='1') THEN
          empty_i <= '1' after C_TCQ;
        ELSE
          empty_i  <= (NOT ram_valid_i AND NOT read_data_valid_i) OR (NOT ram_valid_i AND RD_EN) after C_TCQ;
        END IF;
      END IF; --RD_CLK
    END PROCESS regout_empty;
  END GENERATE gempty;
  


  regout_empty_q: PROCESS (RD_CLK)
  BEGIN  -- PROCESS regout_rd_en
    IF RD_CLK'event AND RD_CLK = '1' THEN  --
        empty_q  <= empty_i after C_TCQ;
    END IF;
  END PROCESS regout_empty_q;

  regout_rd_en: PROCESS (RD_CLK)                                                                   
  BEGIN  -- PROCESS regout_rd_en                                                                             
    IF RD_CLK'event AND RD_CLK = '1' THEN  -- rising clock edge                                           
        rd_en_q <= RD_EN after C_TCQ;
    END IF;                                                                                                  
  END PROCESS regout_rd_en;
  -------------------------------------------------------------------------------
  -- Calculate user_almost_empty
  --  user_almost_empty is defined such that, unless more words are written
  --  to the FIFO, the next read will cause the FIFO to go EMPTY.
  --
  --  In most cases, whenever the output registers are updated (due to a user
  -- read or a preload condition), then user_almost_empty will update to
  -- whatever RAM_EMPTY is.
  --
  --  The exception is when the output is valid, the user is not reading, and
  -- Stage1 is not empty. In this condition, Stage1 will be preloaded from the
  -- memory, so we need to make sure user_almost_empty deasserts properly under
  -- this condition.
  -------------------------------------------------------------------------------
  regout_aempty: PROCESS (RD_CLK, rd_rst_i)
  BEGIN  -- PROCESS regout_empty
    IF rd_rst_i = '1' THEN                -- asynchronous reset (active high)
      almost_empty_i <= '1' after C_TCQ;
      almost_empty_q <= '1' after C_TCQ;
    ELSIF RD_CLK'event AND RD_CLK = '1' THEN  -- rising clock edge
      IF srst_i = '1' THEN                -- synchronous reset (active high)
        almost_empty_i <= '1' after C_TCQ;
        almost_empty_q <= '1' after C_TCQ;
      ELSE
        IF ((ram_regout_en = '1') OR (FIFOEMPTY = '0' AND read_data_valid_i = '1' AND  RD_EN='0')) THEN
          almost_empty_i <= FIFOEMPTY after C_TCQ;
        END IF;
        almost_empty_q   <= almost_empty_i after C_TCQ;
      END IF;
    END IF;
  END PROCESS regout_aempty;
  
  USEREMPTY <= empty_i;
  USERALMOSTEMPTY <= almost_empty_i;
  FIFORDEN  <= ram_rd_en;
  RAMVALID  <= ram_valid_i;
  
  guvh: IF C_USERVALID_LOW=0 GENERATE
    USERVALID <= read_data_valid_i;
  END GENERATE guvh;
  guvl: if C_USERVALID_LOW=1 GENERATE
    USERVALID <= NOT read_data_valid_i;
  END GENERATE guvl;
  
  gufh: IF C_USERUNDERFLOW_LOW=0 GENERATE
    USERUNDERFLOW <= empty_q AND rd_en_q;
  END GENERATE gufh;
  gufl: if C_USERUNDERFLOW_LOW=1 GENERATE
    USERUNDERFLOW <= NOT (empty_q AND rd_en_q);
  END GENERATE gufl;

  glat0_nsafety: if C_EN_SAFETY_CKT=0 GENERATE
  regout_lat0: PROCESS (RD_CLK, rd_rst_i)
  BEGIN  -- PROCESS regout_lat0
    IF (rd_rst_i = '1') THEN              -- asynchronous reset (active high)
      IF (C_USE_ECC = 0) THEN  -- Reset S/DBITERR only if ECC is OFF
        USERSBITERR  <= '0' after C_TCQ;
        USERDBITERR  <= '0' after C_TCQ;
      END IF;

      -- DRAM resets asynchronously
      IF (C_USE_DOUT_RST = 1 AND C_MEMORY_TYPE = 2) THEN 
        USERDATA_int <= hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH) after C_TCQ;
      END IF;

      -- BRAM resets synchronously
      IF (C_USE_DOUT_RST = 1 AND C_MEMORY_TYPE < 2) THEN 
        IF (RD_CLK'event AND RD_CLK = '1') THEN
          USERDATA_int <= hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH) after C_TCQ;
        END IF;
      END IF;

    ELSIF RD_CLK'event AND RD_CLK = '1' THEN  -- rising clock edge
      IF (srst_i = '1') THEN              -- synchronous reset (active high)
        IF (C_USE_ECC = 0) THEN  -- Reset S/DBITERR only if ECC is OFF
          USERSBITERR  <= '0' after C_TCQ;
          USERDBITERR  <= '0' after C_TCQ;
        END IF;
        IF (C_USE_DOUT_RST = 1) THEN              -- synchronous reset (active high)
          USERDATA_int <= hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH) after C_TCQ;
        END IF;
      ELSE
        IF (ram_regout_en = '1') THEN
          USERDATA_int <= FIFODATA after C_TCQ;
          USERSBITERR  <= FIFOSBITERR after C_TCQ;
          USERDBITERR  <= FIFODBITERR after C_TCQ;
        END IF;
      END IF;
    END IF;
  END PROCESS regout_lat0;

  USERDATA <= USERDATA_int ; -- rle, fixed bug R62
  END GENERATE glat0_nsafety;


  glat0_safety: if C_EN_SAFETY_CKT=1 GENERATE
     SIGNAL rst_delayed_sft1 : std_logic := '1';
     SIGNAL rst_delayed_sft2 : std_logic := '1';
     SIGNAL rst_delayed_sft3 : std_logic := '1';
     SIGNAL rst_delayed_sft4 : std_logic := '1';
  BEGIN  -- PROCESS regout_lat0
     PROCESS ( RD_CLK  )
      BEGIN
	rst_delayed_sft1 <= rd_rst_i;
	rst_delayed_sft2 <= rst_delayed_sft1;
	rst_delayed_sft3 <= rst_delayed_sft2;
	rst_delayed_sft4 <= rst_delayed_sft3;
      END PROCESS;
  regout_lat0: PROCESS (RD_CLK, rd_rst_i)
  BEGIN  -- PROCESS regout_lat0


    IF (rd_rst_i = '1') THEN              -- asynchronous reset (active high)
      IF (C_USE_ECC = 0) THEN  -- Reset S/DBITERR only if ECC is OFF
        USERSBITERR  <= '0' after C_TCQ;
        USERDBITERR  <= '0' after C_TCQ;
      END IF;

      -- DRAM resets asynchronously
      IF (C_USE_DOUT_RST = 1 AND C_MEMORY_TYPE = 2 ) THEN 
        USERDATA_int <= hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH) after C_TCQ;
      END IF;

      -- BRAM resets synchronously
      IF (C_USE_DOUT_RST = 1 AND C_MEMORY_TYPE < 2 AND rst_delayed_sft4 = '1') THEN 
        IF (RD_CLK'event AND RD_CLK = '1') THEN
        USERDATA_int <= hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH) after C_TCQ;
        END IF;
      END IF;

    ELSIF RD_CLK'event AND RD_CLK = '1' THEN  -- rising clock edge
      IF (srst_i = '1') THEN              -- synchronous reset (active high)
        IF (C_USE_ECC = 0) THEN  -- Reset S/DBITERR only if ECC is OFF
          USERSBITERR  <= '0' after C_TCQ;
          USERDBITERR  <= '0' after C_TCQ;
        END IF;
        IF (C_USE_DOUT_RST = 1) THEN              -- synchronous reset (active high)
          USERDATA_int <= hexstr_to_std_logic_vec(C_DOUT_RST_VAL, C_DOUT_WIDTH) after C_TCQ;
        END IF;
      ELSE
        IF (ram_regout_en = '1' and rd_rst_i = '0') THEN
          USERDATA_int <= FIFODATA after C_TCQ;
          USERSBITERR  <= FIFOSBITERR after C_TCQ;
          USERDBITERR  <= FIFODBITERR after C_TCQ;
        END IF;
      END IF;
    END IF;
  END PROCESS regout_lat0;

  USERDATA <= USERDATA_int ; -- rle, fixed bug R62
  END GENERATE glat0_safety;

  

END behavioral;



-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--  Top-level Behavioral Model for Conventional FIFO
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_arith.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY fifo_generator_v13_0_0;
USE fifo_generator_v13_0_0.fifo_generator_v13_0_0_bhv_as;
USE fifo_generator_v13_0_0.fifo_generator_v13_0_0_bhv_ss;


-------------------------------------------------------------------------------
-- Top-level Entity Declaration - This is the top-level of the conventional 
-- FIFO Bhv Model
-------------------------------------------------------------------------------
ENTITY fifo_generator_v13_0_0_conv IS
  GENERIC (
    ---------------------------------------------------------------------------
    -- Generic Declarations
    ---------------------------------------------------------------------------
    C_COMMON_CLOCK                : integer := 0;
    C_COUNT_TYPE                  : integer := 0;  --not used
    C_DATA_COUNT_WIDTH            : integer := 2;
    C_DEFAULT_VALUE               : string  := "";  --not used
    C_DIN_WIDTH                   : integer := 8;
    C_DOUT_RST_VAL                : string  := "";
    C_DOUT_WIDTH                  : integer := 8;
    C_ENABLE_RLOCS                : integer := 0;  --not used
    C_FAMILY                      : string  := "";  --not used in bhv model
    C_FULL_FLAGS_RST_VAL          : integer := 0;
    C_HAS_ALMOST_EMPTY            : integer := 0;
    C_HAS_ALMOST_FULL             : integer := 0;
    C_HAS_BACKUP                  : integer := 0;  --not used
    C_HAS_DATA_COUNT              : integer := 0;
    C_HAS_INT_CLK                 : integer := 0;  --not used in bhv model
    C_HAS_MEMINIT_FILE            : integer := 0;  --not used
    C_HAS_OVERFLOW                : integer := 0;
    C_HAS_RD_DATA_COUNT           : integer := 0;
    C_HAS_RD_RST                  : integer := 0;  --not used
    C_HAS_RST                     : integer := 1;
    C_HAS_SRST                    : integer := 0;
    C_HAS_UNDERFLOW               : integer := 0;
    C_HAS_VALID                   : integer := 0;
    C_HAS_WR_ACK                  : integer := 0;
    C_HAS_WR_DATA_COUNT           : integer := 0;
    C_HAS_WR_RST                  : integer := 0;  --not used
    C_IMPLEMENTATION_TYPE         : integer := 0;
    C_INIT_WR_PNTR_VAL            : integer := 0;  --not used
    C_MEMORY_TYPE                 : integer := 1;
    C_MIF_FILE_NAME               : string  := "";  --not used
    C_OPTIMIZATION_MODE           : integer := 0;  --not used
    C_OVERFLOW_LOW                : integer := 0;
    C_PRELOAD_LATENCY             : integer := 1;
    C_PRELOAD_REGS                : integer := 0;
    C_PRIM_FIFO_TYPE              : string  := "4kx4";  --not used in bhv model
    C_PROG_EMPTY_THRESH_ASSERT_VAL: integer := 0;
    C_PROG_EMPTY_THRESH_NEGATE_VAL: integer := 0;
    C_PROG_EMPTY_TYPE             : integer := 0;
    C_PROG_FULL_THRESH_ASSERT_VAL : integer := 0;
    C_PROG_FULL_THRESH_NEGATE_VAL : integer := 0;
    C_PROG_FULL_TYPE              : integer := 0;
    C_RD_DATA_COUNT_WIDTH         : integer := 2;
    C_RD_DEPTH                    : integer := 256;
    C_RD_FREQ                     : integer := 1;  --not used in bhv model
    C_RD_PNTR_WIDTH               : integer := 8;
    C_UNDERFLOW_LOW               : integer := 0;
    C_USE_DOUT_RST                : integer := 0;
    C_USE_ECC                     : integer := 0;
    C_USE_EMBEDDED_REG            : integer := 0;
    C_USE_FIFO16_FLAGS            : integer := 0;  --not used in bhv model
    C_USE_FWFT_DATA_COUNT         : integer := 0;
    C_VALID_LOW                   : integer := 0;
    C_WR_ACK_LOW                  : integer := 0;
    C_WR_DATA_COUNT_WIDTH         : integer := 2;
    C_WR_DEPTH                    : integer := 256;
    C_WR_FREQ                     : integer := 1;  --not used in bhv model
    C_WR_PNTR_WIDTH               : integer := 8;
    C_WR_RESPONSE_LATENCY         : integer := 1;  --not used
    C_MSGON_VAL                   : integer := 1;  --not used in bhv model 
    C_ENABLE_RST_SYNC             : integer := 1;
    C_EN_SAFETY_CKT               : integer := 0;
    C_ERROR_INJECTION_TYPE        : integer := 0;
    C_FIFO_TYPE                   : integer := 0;
    C_SYNCHRONIZER_STAGE          : integer := 2;
    C_AXI_TYPE                    : integer := 0
    );
  PORT(
--------------------------------------------------------------------------------
-- Input and Output Declarations
--------------------------------------------------------------------------------
    BACKUP                    : IN  std_logic := '0';
    BACKUP_MARKER             : IN  std_logic := '0';
    CLK                       : IN  std_logic := '0';
    RST                       : IN  std_logic := '0';
    SRST                      : IN  std_logic := '0';
    WR_CLK                    : IN  std_logic := '0';
    WR_RST                    : IN  std_logic := '0';
    RD_CLK                    : IN  std_logic := '0';
    RD_RST                    : IN  std_logic := '0';
    DIN                       : IN  std_logic_vector(C_DIN_WIDTH-1 DOWNTO 0); --
    WR_EN                     : IN  std_logic;  --Mandatory input
    RD_EN                     : IN  std_logic;  --Mandatory input
    --Mandatory input
    PROG_EMPTY_THRESH         : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_EMPTY_THRESH_ASSERT  : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_EMPTY_THRESH_NEGATE  : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_FULL_THRESH          : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_FULL_THRESH_ASSERT   : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_FULL_THRESH_NEGATE   : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    INT_CLK                   : IN  std_logic := '0';
    INJECTDBITERR             : IN  std_logic := '0';
    INJECTSBITERR             : IN  std_logic := '0';

    DOUT                      : OUT std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
    FULL                      : OUT std_logic;
    ALMOST_FULL               : OUT std_logic;
    WR_ACK                    : OUT std_logic;
    OVERFLOW                  : OUT std_logic;
    EMPTY                     : OUT std_logic;
    ALMOST_EMPTY              : OUT std_logic;
    VALID                     : OUT std_logic;
    UNDERFLOW                 : OUT std_logic;
    DATA_COUNT                : OUT std_logic_vector(C_DATA_COUNT_WIDTH-1 DOWNTO 0);
    RD_DATA_COUNT             : OUT std_logic_vector(C_RD_DATA_COUNT_WIDTH-1 DOWNTO 0);
    WR_DATA_COUNT             : OUT std_logic_vector(C_WR_DATA_COUNT_WIDTH-1 DOWNTO 0);
    PROG_FULL                 : OUT std_logic;
    PROG_EMPTY                : OUT std_logic;
    SBITERR                   : OUT std_logic := '0';
    DBITERR                   : OUT std_logic := '0';
    WR_RST_BUSY               : OUT std_logic := '0';
    RD_RST_BUSY               : OUT std_logic := '0';
    WR_RST_I_OUT              : OUT std_logic := '0';
    RD_RST_I_OUT              : OUT std_logic := '0'
    );

END fifo_generator_v13_0_0_conv;

-------------------------------------------------------------------------------
-- Definition of Parameters
-------------------------------------------------------------------------------
--     C_COMMON_CLOCK                : Common Clock (1), Independent Clocks (0)
--     C_COUNT_TYPE                  :   --not used
--     C_DATA_COUNT_WIDTH            : Width of DATA_COUNT bus
--     C_DEFAULT_VALUE               :   --not used
--     C_DIN_WIDTH                   : Width of DIN bus
--     C_DOUT_RST_VAL                : Reset value of DOUT
--     C_DOUT_WIDTH                  : Width of DOUT bus
--     C_ENABLE_RLOCS                :   --not used
--     C_FAMILY                      : not used in bhv model
--     C_FULL_FLAGS_RST_VAL          : Full flags rst val (0 or 1)
--     C_HAS_ALMOST_EMPTY            : 1=Core has ALMOST_EMPTY flag
--     C_HAS_ALMOST_FULL             : 1=Core has ALMOST_FULL flag
--     C_HAS_BACKUP                  :   --not used
--     C_HAS_DATA_COUNT              : 1=Core has DATA_COUNT bus
--     C_HAS_INT_CLK                 : not used in bhv model
--     C_HAS_MEMINIT_FILE            :   --not used
--     C_HAS_OVERFLOW                : 1=Core has OVERFLOW flag
--     C_HAS_RD_DATA_COUNT           : 1=Core has RD_DATA_COUNT bus
--     C_HAS_RD_RST                  :   --not used
--     C_HAS_RST                     : 1=Core has Async Rst
--     C_HAS_SRST                    : 1=Core has Sync Rst
--     C_HAS_UNDERFLOW               : 1=Core has UNDERFLOW flag
--     C_HAS_VALID                   : 1=Core has VALID flag
--     C_HAS_WR_ACK                  : 1=Core has WR_ACK flag
--     C_HAS_WR_DATA_COUNT           : 1=Core has WR_DATA_COUNT bus
--     C_HAS_WR_RST                  :   --not used
--     C_IMPLEMENTATION_TYPE         : 0=Common-Clock Bram/Dram
--                                     1=Common-Clock ShiftRam
--                                     2=Indep. Clocks Bram/Dram
--                                     3=Virtex-4 Built-in
--                                     4=Virtex-5 Built-in
--     C_INIT_WR_PNTR_VAL            :  --not used
--     C_MEMORY_TYPE                 : 1=Block RAM
--                                     2=Distributed RAM
--                                     3=Shift RAM
--                                     4=Built-in FIFO
--     C_MIF_FILE_NAME               :  --not used
--     C_OPTIMIZATION_MODE           :  --not used
--     C_OVERFLOW_LOW                : 1=OVERFLOW active low
--     C_PRELOAD_LATENCY             : Latency of read: 0, 1, 2
--     C_PRELOAD_REGS                : 1=Use output registers
--     C_PRIM_FIFO_TYPE              : not used in bhv model
--     C_PROG_EMPTY_THRESH_ASSERT_VAL: PROG_EMPTY assert threshold
--     C_PROG_EMPTY_THRESH_NEGATE_VAL: PROG_EMPTY negate threshold
--     C_PROG_EMPTY_TYPE             : 0=No programmable empty
--                                     1=Single prog empty thresh constant
--                                     2=Multiple prog empty thresh constants
--                                     3=Single prog empty thresh input
--                                     4=Multiple prog empty thresh inputs
--     C_PROG_FULL_THRESH_ASSERT_VAL : PROG_FULL assert threshold
--     C_PROG_FULL_THRESH_NEGATE_VAL : PROG_FULL negate threshold
--     C_PROG_FULL_TYPE              : 0=No prog full
--                                     1=Single prog full thresh constant
--                                     2=Multiple prog full thresh constants
--                                     3=Single prog full thresh input
--                                     4=Multiple prog full thresh inputs
--     C_RD_DATA_COUNT_WIDTH         : Width of RD_DATA_COUNT bus
--     C_RD_DEPTH                    : Depth of read interface (2^N)
--     C_RD_FREQ                     : not used in bhv model
--     C_RD_PNTR_WIDTH               : always log2(C_RD_DEPTH)
--     C_UNDERFLOW_LOW               : 1=UNDERFLOW active low
--     C_USE_DOUT_RST                : 1=Resets DOUT on RST
--     C_USE_ECC                     : not used in bhv model
--     C_USE_EMBEDDED_REG            : 1=Use BRAM embedded output register
--     C_USE_FIFO16_FLAGS            : not used in bhv model
--     C_USE_FWFT_DATA_COUNT         : 1=Use extra logic for FWFT data count
--     C_VALID_LOW                   : 1=VALID active low
--     C_WR_ACK_LOW                  : 1=WR_ACK active low
--     C_WR_DATA_COUNT_WIDTH         : Width of WR_DATA_COUNT bus
--     C_WR_DEPTH                    : Depth of write interface (2^N)
--     C_WR_FREQ                     : not used in bhv model
--     C_WR_PNTR_WIDTH               : always log2(C_WR_DEPTH)
--     C_WR_RESPONSE_LATENCY         :   --not used
-------------------------------------------------------------------------------
-- Definition of Ports
-------------------------------------------------------------------------------
--   BACKUP       : Not used
--   BACKUP_MARKER: Not used
--   CLK          : Clock
--   DIN          : Input data bus
--   PROG_EMPTY_THRESH       : Threshold for Programmable Empty Flag
--   PROG_EMPTY_THRESH_ASSERT: Threshold for Programmable Empty Flag
--   PROG_EMPTY_THRESH_NEGATE: Threshold for Programmable Empty Flag
--   PROG_FULL_THRESH        : Threshold for Programmable Full Flag
--   PROG_FULL_THRESH_ASSERT : Threshold for Programmable Full Flag
--   PROG_FULL_THRESH_NEGATE : Threshold for Programmable Full Flag
--   RD_CLK       : Read Domain Clock
--   RD_EN        : Read enable
--   RD_RST       : Not used
--   RST          : Asynchronous Reset
--   SRST         : Synchronous Reset
--   WR_CLK       : Write Domain Clock
--   WR_EN        : Write enable
--   WR_RST       : Not used
--   INT_CLK      : Internal Clock
--   ALMOST_EMPTY : One word remaining in FIFO
--   ALMOST_FULL  : One empty space remaining in FIFO
--   DATA_COUNT   : Number of data words in fifo( synchronous to CLK)
--   DOUT         : Output data bus
--   EMPTY        : Empty flag
--   FULL         : Full flag
--   OVERFLOW     : Last write rejected
--   PROG_EMPTY   : Programmable Empty Flag
--   PROG_FULL    : Programmable Full Flag
--   RD_DATA_COUNT: Number of data words in fifo (synchronous to RD_CLK)
--   UNDERFLOW    : Last read rejected
--   VALID        : Last read acknowledged, DOUT bus VALID
--   WR_ACK       : Last write acknowledged
--   WR_DATA_COUNT: Number of data words in fifo (synchronous to WR_CLK)
--   SBITERR      : Single Bit ECC Error Detected
--   DBITERR      : Double Bit ECC Error Detected
-------------------------------------------------------------------------------


ARCHITECTURE behavioral OF fifo_generator_v13_0_0_conv IS

  -----------------------------------------------------------------------------
  -- FUNCTION two_comp
  -- Returns a 2's complement value
  -------------------------------------------------------------------------------
  	
    FUNCTION two_comp(
      vect : std_logic_vector)
    RETURN std_logic_vector IS
      VARIABLE local_vect : std_logic_vector(vect'high DOWNTO 0);
      VARIABLE toggle     : integer := 0;
    BEGIN
      FOR i IN 0 TO vect'high LOOP
        IF (toggle = 1) THEN
          IF (vect(i) = '0') THEN
            local_vect(i) := '1';
          ELSE
            local_vect(i) := '0';
          END IF;
        ELSE
          local_vect(i)   := vect(i);
          IF (vect(i) = '1') THEN
            toggle        := 1;
          END IF;
        END IF;
      END LOOP;
      RETURN local_vect;
    END two_comp;

  -----------------------------------------------------------------------------
  -- FUNCTION int_2_std_logic_vector
  -- Returns a std_logic_vector for an integer value for a given width.
  -------------------------------------------------------------------------------
  
    FUNCTION int_2_std_logic_vector( 
      value, bitwidth : integer )
    RETURN std_logic_vector IS
      VARIABLE running_value  : integer := value;
      VARIABLE running_result : std_logic_vector(bitwidth-1 DOWNTO 0);
    BEGIN
      IF (value < 0) THEN
        running_value := -1 * value;
      END IF;
  
      FOR i IN 0 TO bitwidth-1 LOOP
        IF running_value MOD 2 = 0 THEN
          running_result(i) := '0';
        ELSE
          running_result(i) := '1';
        END IF;
        running_value       := running_value/2;
      END LOOP;
      
      IF (value < 0) THEN                 -- find the 2s complement
        RETURN two_comp(running_result);
      ELSE
        RETURN running_result;
      END IF;
    
    END int_2_std_logic_vector;

  COMPONENT fifo_generator_v13_0_0_bhv_as

    GENERIC (
      --------------------------------------------------------------------------------
      -- Generic Declarations
      --------------------------------------------------------------------------------
      C_FAMILY                       : string  := "virtex7";
      C_DIN_WIDTH                    :    integer := 8;
      C_DOUT_RST_VAL                 :    string  := "";
      C_DOUT_WIDTH                   :    integer := 8;
      C_FULL_FLAGS_RST_VAL           :    integer := 1;
      C_HAS_ALMOST_EMPTY             :    integer := 0;
      C_HAS_ALMOST_FULL              :    integer := 0;
      C_HAS_OVERFLOW                 :    integer := 0;
      C_HAS_RD_DATA_COUNT            :    integer := 2;
      C_HAS_RST                      :    integer := 1;
      C_HAS_UNDERFLOW                :    integer := 0;
      C_HAS_VALID                    :    integer := 0;
      C_HAS_WR_ACK                   :    integer := 0;
      C_HAS_WR_DATA_COUNT            :    integer := 2;
      C_MEMORY_TYPE                  :    integer := 1;
      C_OVERFLOW_LOW                 :    integer := 0;
      C_PRELOAD_LATENCY              :    integer := 1;
      C_PRELOAD_REGS                 :    integer := 0;
      C_PROG_EMPTY_THRESH_ASSERT_VAL :    integer := 0;
      C_PROG_EMPTY_THRESH_NEGATE_VAL :    integer := 0;
      C_PROG_EMPTY_TYPE              :    integer := 0;
      C_PROG_FULL_THRESH_ASSERT_VAL  :    integer := 0;
      C_PROG_FULL_THRESH_NEGATE_VAL  :    integer := 0;
      C_PROG_FULL_TYPE               :    integer := 0;
      C_RD_DATA_COUNT_WIDTH          :    integer := 0;
      C_RD_DEPTH                     :    integer := 256;
      C_RD_PNTR_WIDTH                :    integer := 8;
      C_UNDERFLOW_LOW                :    integer := 0;
      C_USE_DOUT_RST                 :    integer := 0;
      C_USE_ECC                      :    integer := 0;
      C_EN_SAFETY_CKT                :    integer := 0;
      C_USE_EMBEDDED_REG             :    integer := 0;
      C_USE_FWFT_DATA_COUNT          :    integer := 0;
      C_VALID_LOW                    :    integer := 0;
      C_WR_ACK_LOW                   :    integer := 0;
      C_WR_DATA_COUNT_WIDTH          :    integer := 0;
      C_WR_DEPTH                     :    integer := 256;
      C_WR_PNTR_WIDTH                :    integer := 8;
      C_TCQ                          :    time    := 100 ps;
      C_ENABLE_RST_SYNC              :    integer := 1;
      C_ERROR_INJECTION_TYPE         :    integer := 0;
      C_SYNCHRONIZER_STAGE           :    integer := 2;
      C_FIFO_TYPE                    :    integer := 0
      );
    PORT(
--------------------------------------------------------------------------------
-- Input and Output Declarations
--------------------------------------------------------------------------------
      DIN                            : IN std_logic_vector(C_DIN_WIDTH-1 DOWNTO 0);
      PROG_EMPTY_THRESH              : IN std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0);
      PROG_EMPTY_THRESH_ASSERT       : IN std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0);
      PROG_EMPTY_THRESH_NEGATE       : IN std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0);
      PROG_FULL_THRESH               : IN std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0);
      PROG_FULL_THRESH_ASSERT        : IN std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0);
      PROG_FULL_THRESH_NEGATE        : IN std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0);
      RD_CLK                         : IN std_logic;
      RD_EN                          : IN std_logic;
      RD_EN_USER                     : IN std_logic;
      RST                            : IN std_logic;
      RST_FULL_GEN                   : IN std_logic := '0';
      RST_FULL_FF                    : IN std_logic := '0';
      WR_RST                         : IN std_logic;
      RD_RST                         : IN std_logic;
      WR_CLK                         : IN std_logic;
      WR_EN                          : IN std_logic;
      INJECTDBITERR                  : IN std_logic := '0';
      INJECTSBITERR                  : IN std_logic := '0';
      USER_EMPTY_FB                  : IN std_logic := '1';

      ALMOST_EMPTY                   : OUT std_logic;
      ALMOST_FULL                    : OUT std_logic;
      DOUT                           : OUT std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
      EMPTY                          : OUT std_logic;
      FULL                           : OUT std_logic;
      OVERFLOW                       : OUT std_logic;
      PROG_EMPTY                     : OUT std_logic;
      PROG_FULL                      : OUT std_logic;
      VALID                          : OUT std_logic;
      RD_DATA_COUNT                  : OUT std_logic_vector(C_RD_DATA_COUNT_WIDTH-1 DOWNTO 0);
      UNDERFLOW                      : OUT std_logic;
      WR_ACK                         : OUT std_logic;
      WR_DATA_COUNT                  : OUT std_logic_vector(C_WR_DATA_COUNT_WIDTH-1 DOWNTO 0);
      DBITERR                        : OUT std_logic := '0';
      SBITERR                        : OUT std_logic := '0'
      );

  END COMPONENT;



  COMPONENT fifo_generator_v13_0_0_bhv_ss

    GENERIC (
    --------------------------------------------------------------------------------
    -- Generic Declarations (alphabetical)
    --------------------------------------------------------------------------------
    C_FAMILY                       : string  := "virtex7";
    C_DATA_COUNT_WIDTH             : integer := 2;
    C_DIN_WIDTH                    : integer := 8;
    C_DOUT_RST_VAL                 : string  := "";
    C_DOUT_WIDTH                   : integer := 8;
    C_FULL_FLAGS_RST_VAL           : integer := 1;
    C_HAS_ALMOST_EMPTY             : integer := 0;
    C_HAS_ALMOST_FULL              : integer := 0;
    C_HAS_DATA_COUNT               : integer := 0;
    C_HAS_OVERFLOW                 : integer := 0;
    C_HAS_RD_DATA_COUNT            : integer := 2;
    C_HAS_RST                      : integer := 0;
    C_HAS_SRST                     : integer := 0;
    C_HAS_UNDERFLOW                : integer := 0;
    C_HAS_VALID                    : integer := 0;
    C_HAS_WR_ACK                   : integer := 0;
    C_HAS_WR_DATA_COUNT            : integer := 2;
    C_MEMORY_TYPE                  : integer := 1;
    C_OVERFLOW_LOW                 : integer := 0;
    C_PRELOAD_LATENCY              : integer := 1;
    C_PRELOAD_REGS                 : integer := 0;
    C_PROG_EMPTY_THRESH_ASSERT_VAL : integer := 0;
    C_PROG_EMPTY_THRESH_NEGATE_VAL : integer := 0;
    C_PROG_EMPTY_TYPE              : integer := 0;
    C_PROG_FULL_THRESH_ASSERT_VAL  : integer := 0;
    C_PROG_FULL_THRESH_NEGATE_VAL  : integer := 0;
    C_PROG_FULL_TYPE               : integer := 0;
    C_RD_DATA_COUNT_WIDTH          : integer := 0;
    C_RD_DEPTH                     : integer := 256;
    C_RD_PNTR_WIDTH                : integer := 8;
    C_UNDERFLOW_LOW                : integer := 0;
    C_USE_ECC                      : integer := 0;
    C_EN_SAFETY_CKT                : integer := 0;
    C_USE_DOUT_RST                 : integer := 0;
    C_USE_EMBEDDED_REG             : integer := 0;
    C_USE_FWFT_DATA_COUNT          : integer := 0;
    C_VALID_LOW                    : integer := 0;
    C_WR_ACK_LOW                   : integer := 0;
    C_WR_DATA_COUNT_WIDTH          : integer := 0;
    C_WR_DEPTH                     : integer := 256;
    C_WR_PNTR_WIDTH                : integer := 8;
    C_TCQ                          : time    := 100 ps;
    C_ENABLE_RST_SYNC              : integer := 1;
    C_ERROR_INJECTION_TYPE         : integer := 0;
    C_FIFO_TYPE                    : integer := 0
    );


  PORT(
--------------------------------------------------------------------------------
-- Input and Output Declarations
--------------------------------------------------------------------------------
    CLK                      : IN std_logic                                    := '0';
    DIN                      : IN std_logic_vector(C_DIN_WIDTH-1 DOWNTO 0)     := (OTHERS => '0');
    PROG_EMPTY_THRESH        : IN std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_EMPTY_THRESH_ASSERT : IN std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_EMPTY_THRESH_NEGATE : IN std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_FULL_THRESH         : IN std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_FULL_THRESH_ASSERT  : IN std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_FULL_THRESH_NEGATE  : IN std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    RD_EN                    : IN std_logic                                    := '0';
    RD_EN_USER               : IN std_logic;
    RST                      : IN std_logic                                    := '0';
    RST_FULL_GEN             : IN std_logic := '0';
    RST_FULL_FF              : IN std_logic := '0';
    SRST                     : IN std_logic                                    := '0';
    WR_EN                    : IN std_logic                                    := '0';
    WR_RST_BUSY              : IN std_logic := '0';
    RD_RST_BUSY              : IN std_logic := '0';
    INJECTDBITERR            : IN std_logic := '0';
    INJECTSBITERR            : IN std_logic := '0';
    USER_EMPTY_FB            : IN std_logic := '1';

    ALMOST_EMPTY             : OUT std_logic;
    ALMOST_FULL              : OUT std_logic;
    DATA_COUNT               : OUT std_logic_vector(C_DATA_COUNT_WIDTH-1 DOWNTO 0);
    DOUT                     : OUT std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
    EMPTY                    : OUT std_logic;
    FULL                     : OUT std_logic;
    OVERFLOW                 : OUT std_logic;
    PROG_EMPTY               : OUT std_logic;
    PROG_FULL                : OUT std_logic;
    VALID                    : OUT std_logic;
    UNDERFLOW                : OUT std_logic;
    RD_DATA_COUNT            : OUT std_logic_vector(C_RD_DATA_COUNT_WIDTH-1 DOWNTO 0)
                             := (OTHERS => '0');
    WR_DATA_COUNT            : OUT std_logic_vector(C_WR_DATA_COUNT_WIDTH-1 DOWNTO 0)
                             := (OTHERS => '0');
    WR_ACK                   : OUT std_logic;
    DBITERR                  : OUT std_logic := '0';
    SBITERR                  : OUT std_logic := '0'
    );

  END COMPONENT;

  COMPONENT fifo_generator_v13_0_0_bhv_preload0
    GENERIC (
      C_DOUT_RST_VAL         : string;
      C_DOUT_WIDTH           : integer;
      C_HAS_RST              : integer;
      C_HAS_SRST             : integer;
      C_USE_DOUT_RST         : integer := 0;
      C_USE_ECC              : integer := 0;
      C_USERVALID_LOW        : integer := 0;
      C_EN_SAFETY_CKT        : integer := 0;
      C_USERUNDERFLOW_LOW    : integer := 0;
      C_TCQ                  : time    := 100 ps; 
      C_ENABLE_RST_SYNC      : integer := 1;
      C_ERROR_INJECTION_TYPE : integer := 0;
      C_MEMORY_TYPE          : integer := 0;
      C_FIFO_TYPE            : integer := 0
   );
    PORT (
      RD_CLK                 : IN  std_logic;
      RD_RST                 : IN  std_logic;
      SRST                   : IN  std_logic;
      WR_RST_BUSY            : IN  std_logic;
      RD_RST_BUSY            : IN  std_logic;
      RD_EN                  : IN  std_logic;
      FIFOEMPTY              : IN  std_logic;
      FIFODATA               : IN  std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
      FIFOSBITERR            : IN  std_logic;
      FIFODBITERR            : IN  std_logic;
      USERDATA               : OUT std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
      USERVALID              : OUT std_logic;
      USERUNDERFLOW          : OUT std_logic;
      USEREMPTY              : OUT std_logic;
      USERALMOSTEMPTY        : OUT std_logic;
      RAMVALID               : OUT std_logic;
      FIFORDEN               : OUT std_logic;
      USERSBITERR            : OUT std_logic;
      USERDBITERR            : OUT std_logic;
      STAGE2_REG_EN          : OUT std_logic;
      VALID_STAGES           : OUT std_logic_vector(1 DOWNTO 0)
      );
  END COMPONENT;

  -- Constant to have clock to register delay
  CONSTANT C_TCQ : time := 100 ps;

  SIGNAL zero : std_logic := '0';
  SIGNAL CLK_INT : std_logic := '0';

  -----------------------------------------------------------------------------
  -- Internal Signals for delayed input signals
  -- All the input signals except Clock are delayed by 100 ps and then given to
  -- the models.
  -----------------------------------------------------------------------------

  SIGNAL rst_delayed                       : std_logic := '0';
  SIGNAL srst_delayed                      : std_logic := '0';
  SIGNAL wr_rst_delayed                    : std_logic := '0';
  SIGNAL rd_rst_delayed                    : std_logic := '0';
  SIGNAL din_delayed                       : std_logic_vector(C_DIN_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL wr_en_delayed                     : std_logic := '0';
  SIGNAL rd_en_delayed                     : std_logic := '0';
  SIGNAL prog_empty_thresh_delayed         : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL prog_empty_thresh_assert_delayed  : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL prog_empty_thresh_negate_delayed  : std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL prog_full_thresh_delayed          : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL prog_full_thresh_assert_delayed   : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL prog_full_thresh_negate_delayed   : std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL injectdbiterr_delayed             : std_logic := '0';
  SIGNAL injectsbiterr_delayed             : std_logic := '0';
  SIGNAL wr_rst_busy_i             : std_logic := '0';
  SIGNAL rd_rst_busy_i             : std_logic := '0';


  -----------------------------------------------------------------------------
  -- Internal Signals
  --  In the normal case, these signals tie directly to the FIFO's inputs and
  --  outputs.
  --  In the case of Preload Latency 0 or 1, these are the intermediate
  --  signals between the internal FIFO and the preload logic.
  -----------------------------------------------------------------------------
    SIGNAL rd_en_fifo_in          : std_logic;
    SIGNAL dout_fifo_out          : std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
    SIGNAL empty_fifo_out         : std_logic;
    SIGNAL almost_empty_fifo_out  : std_logic;
    SIGNAL valid_fifo_out         : std_logic;
    SIGNAL underflow_fifo_out     : std_logic;
    SIGNAL rd_data_count_fifo_out : std_logic_vector(C_RD_DATA_COUNT_WIDTH-1 DOWNTO 0);
    SIGNAL wr_data_count_fifo_out : std_logic_vector(C_WR_DATA_COUNT_WIDTH-1 DOWNTO 0);
    SIGNAL data_count_fifo_out    : std_logic_vector(C_DATA_COUNT_WIDTH-1 DOWNTO 0);
    SIGNAL DATA_COUNT_FWFT        : std_logic_vector(C_RD_PNTR_WIDTH DOWNTO 0) := (OTHERS => '0');
    SIGNAL SS_FWFT_RD             : std_logic := '0' ;
    SIGNAL SS_FWFT_WR             : std_logic := '0' ;
    SIGNAL FULL_int               : std_logic ;
    SIGNAL almost_full_i          : std_logic ;
    SIGNAL prog_full_i            : std_logic ;

    SIGNAL dout_p0_out            : std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
    signal valid_p0_out           : std_logic;
    signal empty_p0_out           : std_logic;
    signal underflow_p0_out       : std_logic;
    signal almost_empty_p0_out    : std_logic;

    signal empty_p0_out_q         : std_logic;
    signal almost_empty_p0_out_q  : std_logic;

    SIGNAL ram_valid              : std_logic;  --Internal signal used to monitor the
                                                --ram_valid state
    signal rst_fwft               : std_logic;
    signal sbiterr_fifo_out       : std_logic;
    signal dbiterr_fifo_out       : std_logic;

    signal wr_rst_i               : std_logic := '0';
    signal rd_rst_i               : std_logic := '0';
    signal rst_i                  : std_logic := '0';
    signal rst_full_gen_i         : std_logic := '0';
    signal rst_full_ff_i          : std_logic := '0';
    signal rst_2_sync             : std_logic := '0';
    signal rst_2_sync_safety             : std_logic := '0';
    signal clk_2_sync             : std_logic := '0';
    signal clk_2_sync_safety             : std_logic := '0';

  -----------------------------------------------------------------------------
  -- FUNCTION if_then_else
  -- Returns a true case or flase case based on the condition
  -------------------------------------------------------------------------------

    FUNCTION if_then_else (
      condition : boolean; 
      true_case : integer; 
      false_case : integer) 
    RETURN integer IS
      VARIABLE retval : integer := 0;
    BEGIN
      IF NOT condition THEN
        retval:=false_case;
      ELSE
        retval:=true_case;
      END IF;
      RETURN retval;
    END if_then_else;

  -----------------------------------------------------------------------------
  -- FUNCTION log2roundup
  -- Returns a log2 of the input value
  -----------------------------------------------------------------------------

    FUNCTION log2roundup (
        data_value : integer)
    	RETURN integer IS
    	
    	VARIABLE width       : integer := 0;
    	VARIABLE cnt         : integer := 1;
    	
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


    CONSTANT FULL_FLAGS_RST_VAL        : integer := if_then_else((C_HAS_SRST = 1),0,C_FULL_FLAGS_RST_VAL);
    CONSTANT IS_WR_PNTR_WIDTH_CORRECT  : integer := if_then_else((C_WR_PNTR_WIDTH = log2roundup(C_WR_DEPTH)),1,0);
    CONSTANT IS_RD_PNTR_WIDTH_CORRECT  : integer := if_then_else((C_RD_PNTR_WIDTH = log2roundup(C_RD_DEPTH)),1,0);
BEGIN

  rst_delayed                       <= RST                      AFTER C_TCQ;
  srst_delayed                      <= SRST                     AFTER C_TCQ; 
  wr_rst_delayed                    <= WR_RST                   AFTER C_TCQ; 
  rd_rst_delayed                    <= RD_RST                   AFTER C_TCQ; 
  din_delayed                       <= DIN                      AFTER C_TCQ; 
  wr_en_delayed                     <= WR_EN                    AFTER C_TCQ; 
  rd_en_delayed                     <= RD_EN                    AFTER C_TCQ; 
  prog_empty_thresh_delayed         <= PROG_EMPTY_THRESH        AFTER C_TCQ; 
  prog_empty_thresh_assert_delayed  <= PROG_EMPTY_THRESH_ASSERT AFTER C_TCQ; 
  prog_empty_thresh_negate_delayed  <= PROG_EMPTY_THRESH_NEGATE AFTER C_TCQ; 
  prog_full_thresh_delayed          <= PROG_FULL_THRESH         AFTER C_TCQ; 
  prog_full_thresh_assert_delayed   <= PROG_FULL_THRESH_ASSERT  AFTER C_TCQ; 
  prog_full_thresh_negate_delayed   <= PROG_FULL_THRESH_NEGATE  AFTER C_TCQ; 
  injectdbiterr_delayed             <= INJECTDBITERR            AFTER C_TCQ; 
  injectsbiterr_delayed             <= INJECTSBITERR            AFTER C_TCQ; 

  --Assign Ground Signal
  zero <= '0';
  
  ASSERT (C_MEMORY_TYPE /= 4) REPORT "FAILURE : Behavioral models do not support built-in FIFO configurations. Please use post-synthesis or post-implement simulation in Vivado." SEVERITY FAILURE;
--  
  ASSERT (C_IMPLEMENTATION_TYPE /= 2) REPORT "WARNING: Behavioral models for independent clock FIFO configurations do not model synchronization delays. The behavioral models are functionally correct, and will represent the behavior of the configured FIFO. See the FIFO Generator User Guide for more information." SEVERITY NOTE;

  ASSERT (IS_WR_PNTR_WIDTH_CORRECT /= 0) REPORT "FAILURE : C_WR_PNTR_WIDTH is not log2 of C_WR_DEPTH." SEVERITY FAILURE;

  ASSERT (IS_RD_PNTR_WIDTH_CORRECT /= 0) REPORT "FAILURE : C_RD_PNTR_WIDTH is not log2 of C_RD_DEPTH." SEVERITY FAILURE;

  gen_ss : IF ((C_IMPLEMENTATION_TYPE = 0) OR (C_IMPLEMENTATION_TYPE = 1) OR (C_MEMORY_TYPE = 4)) GENERATE
    fgss : fifo_generator_v13_0_0_bhv_ss
      GENERIC MAP (
        C_FAMILY                       => C_FAMILY,
        C_DATA_COUNT_WIDTH             => C_DATA_COUNT_WIDTH,
        C_DIN_WIDTH                    => C_DIN_WIDTH,
        C_DOUT_RST_VAL                 => C_DOUT_RST_VAL,
        C_DOUT_WIDTH                   => C_DOUT_WIDTH,
        C_FULL_FLAGS_RST_VAL           => FULL_FLAGS_RST_VAL,
        C_HAS_ALMOST_EMPTY             => C_HAS_ALMOST_EMPTY,
        C_HAS_ALMOST_FULL              => if_then_else((C_AXI_TYPE = 0 AND C_FIFO_TYPE = 1), 1, C_HAS_ALMOST_FULL),
        C_HAS_DATA_COUNT               => C_HAS_DATA_COUNT,
        C_HAS_OVERFLOW                 => C_HAS_OVERFLOW,
        C_HAS_RD_DATA_COUNT            => C_HAS_RD_DATA_COUNT,
        C_HAS_RST                      => C_HAS_RST,
        C_HAS_SRST                     => C_HAS_SRST,
        C_HAS_UNDERFLOW                => C_HAS_UNDERFLOW,
        C_HAS_VALID                    => C_HAS_VALID,
        C_HAS_WR_ACK                   => C_HAS_WR_ACK,
        C_HAS_WR_DATA_COUNT            => C_HAS_WR_DATA_COUNT,
        C_MEMORY_TYPE                  => if_then_else(C_MEMORY_TYPE = 4, 1, C_MEMORY_TYPE),
        C_OVERFLOW_LOW                 => C_OVERFLOW_LOW,
        C_PRELOAD_LATENCY              => C_PRELOAD_LATENCY,
        C_PRELOAD_REGS                 => C_PRELOAD_REGS,
        C_PROG_EMPTY_THRESH_ASSERT_VAL => C_PROG_EMPTY_THRESH_ASSERT_VAL,
        C_PROG_EMPTY_THRESH_NEGATE_VAL => C_PROG_EMPTY_THRESH_NEGATE_VAL,
        C_PROG_EMPTY_TYPE              => C_PROG_EMPTY_TYPE,
        C_PROG_FULL_THRESH_ASSERT_VAL  => C_PROG_FULL_THRESH_ASSERT_VAL,
        C_PROG_FULL_THRESH_NEGATE_VAL  => C_PROG_FULL_THRESH_NEGATE_VAL,
        C_PROG_FULL_TYPE               => C_PROG_FULL_TYPE,
        C_RD_DATA_COUNT_WIDTH          => C_RD_DATA_COUNT_WIDTH,
        C_RD_DEPTH                     => C_RD_DEPTH,
        C_RD_PNTR_WIDTH                => C_RD_PNTR_WIDTH,
        C_UNDERFLOW_LOW                => C_UNDERFLOW_LOW,
        C_USE_ECC                      => C_USE_ECC,
        C_EN_SAFETY_CKT                => C_EN_SAFETY_CKT,
        C_USE_DOUT_RST                 => C_USE_DOUT_RST,
        C_USE_EMBEDDED_REG             => C_USE_EMBEDDED_REG,
        C_USE_FWFT_DATA_COUNT          => C_USE_FWFT_DATA_COUNT,
        C_VALID_LOW                    => C_VALID_LOW,
        C_WR_ACK_LOW                   => C_WR_ACK_LOW,
        C_WR_DATA_COUNT_WIDTH          => C_WR_DATA_COUNT_WIDTH,
        C_WR_DEPTH                     => C_WR_DEPTH,
        C_WR_PNTR_WIDTH                => C_WR_PNTR_WIDTH,
        C_TCQ                          => C_TCQ,
        C_ENABLE_RST_SYNC              => C_ENABLE_RST_SYNC,
        C_ERROR_INJECTION_TYPE         => C_ERROR_INJECTION_TYPE,
        C_FIFO_TYPE                    => C_FIFO_TYPE
        )
      PORT MAP(
        --Inputs
        CLK                            => CLK,
        DIN                            => din_delayed,
        PROG_EMPTY_THRESH              => prog_empty_thresh_delayed,
        PROG_EMPTY_THRESH_ASSERT       => prog_empty_thresh_assert_delayed,
        PROG_EMPTY_THRESH_NEGATE       => prog_empty_thresh_negate_delayed,
        PROG_FULL_THRESH               => prog_full_thresh_delayed,
        PROG_FULL_THRESH_ASSERT        => prog_full_thresh_assert_delayed,
        PROG_FULL_THRESH_NEGATE        => prog_full_thresh_negate_delayed,
        RD_EN                          => rd_en_fifo_in,
        RD_EN_USER                     => rd_en_delayed,
        RST                            => rst_i,
        SRST                           => srst_delayed,
        RST_FULL_GEN                   => rst_full_gen_i,
        RST_FULL_FF                    => rst_full_ff_i,
        WR_EN                          => wr_en_delayed,
        WR_RST_BUSY                    => wr_rst_busy_i,
        RD_RST_BUSY                    => rd_rst_busy_i,
        INJECTDBITERR                  => injectdbiterr_delayed,
        INJECTSBITERR                  => injectsbiterr_delayed,
        USER_EMPTY_FB                  => empty_p0_out,

        --Outputs
        ALMOST_EMPTY                   => almost_empty_fifo_out,
        ALMOST_FULL                    => almost_full_i,
        DATA_COUNT                     => data_count_fifo_out,
        DOUT                           => dout_fifo_out,
        EMPTY                          => empty_fifo_out,
        FULL                           => FULL_int,
        OVERFLOW                       => OVERFLOW,
        PROG_EMPTY                     => PROG_EMPTY,
        PROG_FULL                      => prog_full_i,
        UNDERFLOW                      => underflow_fifo_out,
        RD_DATA_COUNT                  => rd_data_count_fifo_out,
        WR_DATA_COUNT                  => wr_data_count_fifo_out,
        VALID                          => valid_fifo_out,
        WR_ACK                         => WR_ACK,
        DBITERR                        => dbiterr_fifo_out,
        SBITERR                        => sbiterr_fifo_out
        );
  END GENERATE gen_ss;



  gen_as : IF (C_IMPLEMENTATION_TYPE = 2 OR C_FIFO_TYPE = 3) GENERATE

    fgas : fifo_generator_v13_0_0_bhv_as
      GENERIC MAP (
        C_FAMILY                       => C_FAMILY,
        C_DIN_WIDTH                    => C_DIN_WIDTH,
        C_DOUT_RST_VAL                 => C_DOUT_RST_VAL,
        C_DOUT_WIDTH                   => C_DOUT_WIDTH,
        C_FULL_FLAGS_RST_VAL           => C_FULL_FLAGS_RST_VAL,
        C_HAS_ALMOST_EMPTY             => C_HAS_ALMOST_EMPTY,
        C_HAS_ALMOST_FULL              => if_then_else((C_AXI_TYPE = 0 AND C_FIFO_TYPE = 1), 1, C_HAS_ALMOST_FULL),
        C_HAS_OVERFLOW                 => C_HAS_OVERFLOW,
        C_HAS_RD_DATA_COUNT            => C_HAS_RD_DATA_COUNT,
        C_HAS_RST                      => C_HAS_RST,
        C_HAS_UNDERFLOW                => C_HAS_UNDERFLOW,
        C_HAS_VALID                    => C_HAS_VALID,
        C_HAS_WR_ACK                   => C_HAS_WR_ACK,
        C_HAS_WR_DATA_COUNT            => C_HAS_WR_DATA_COUNT,
        C_MEMORY_TYPE                  => C_MEMORY_TYPE,
        C_OVERFLOW_LOW                 => C_OVERFLOW_LOW,
        C_PRELOAD_LATENCY              => C_PRELOAD_LATENCY,
        C_PRELOAD_REGS                 => C_PRELOAD_REGS,
        C_PROG_EMPTY_THRESH_ASSERT_VAL => C_PROG_EMPTY_THRESH_ASSERT_VAL,
        C_PROG_EMPTY_THRESH_NEGATE_VAL => C_PROG_EMPTY_THRESH_NEGATE_VAL,
        C_PROG_EMPTY_TYPE              => C_PROG_EMPTY_TYPE,
        C_PROG_FULL_THRESH_ASSERT_VAL  => C_PROG_FULL_THRESH_ASSERT_VAL,
        C_PROG_FULL_THRESH_NEGATE_VAL  => C_PROG_FULL_THRESH_NEGATE_VAL,
        C_PROG_FULL_TYPE               => C_PROG_FULL_TYPE,
        C_RD_DATA_COUNT_WIDTH          => C_RD_DATA_COUNT_WIDTH,
        C_RD_DEPTH                     => C_RD_DEPTH,
        C_RD_PNTR_WIDTH                => C_RD_PNTR_WIDTH,
        C_UNDERFLOW_LOW                => C_UNDERFLOW_LOW,
        C_USE_ECC                      => C_USE_ECC,
        C_EN_SAFETY_CKT                => C_EN_SAFETY_CKT,
        C_USE_DOUT_RST                 => C_USE_DOUT_RST,
        C_USE_EMBEDDED_REG             => C_USE_EMBEDDED_REG,
        C_USE_FWFT_DATA_COUNT          => C_USE_FWFT_DATA_COUNT,
        C_VALID_LOW                    => C_VALID_LOW,
        C_WR_ACK_LOW                   => C_WR_ACK_LOW,
        C_WR_DATA_COUNT_WIDTH          => C_WR_DATA_COUNT_WIDTH,
        C_WR_DEPTH                     => C_WR_DEPTH,
        C_WR_PNTR_WIDTH                => C_WR_PNTR_WIDTH,
        C_TCQ                          => C_TCQ,
        C_ENABLE_RST_SYNC              => C_ENABLE_RST_SYNC,
        C_ERROR_INJECTION_TYPE         => C_ERROR_INJECTION_TYPE,
        C_SYNCHRONIZER_STAGE           => C_SYNCHRONIZER_STAGE,
        C_FIFO_TYPE                    => C_FIFO_TYPE

        )
      PORT MAP(
        --Inputs
        WR_CLK                         => WR_CLK,
        RD_CLK                         => RD_CLK,
        RST                            => rst_i,
        RST_FULL_GEN                   => rst_full_gen_i,
        RST_FULL_FF                    => rst_full_ff_i,
        WR_RST                         => wr_rst_i,
        RD_RST                         => rd_rst_i,
        DIN                            => din_delayed,
        RD_EN                          => rd_en_fifo_in,
        WR_EN                          => wr_en_delayed,
        RD_EN_USER                     => rd_en_delayed,
        PROG_FULL_THRESH               => prog_full_thresh_delayed,
        PROG_EMPTY_THRESH_ASSERT       => prog_empty_thresh_assert_delayed,
        PROG_EMPTY_THRESH_NEGATE       => prog_empty_thresh_negate_delayed,
        PROG_EMPTY_THRESH              => prog_empty_thresh_delayed,
        PROG_FULL_THRESH_ASSERT        => prog_full_thresh_assert_delayed,
        PROG_FULL_THRESH_NEGATE        => prog_full_thresh_negate_delayed,
        INJECTDBITERR                  => injectdbiterr_delayed,
        INJECTSBITERR                  => injectsbiterr_delayed,
        USER_EMPTY_FB                  => empty_p0_out,

        --Outputs
        DOUT                           => dout_fifo_out,
        FULL                           => FULL_int,
        ALMOST_FULL                    => almost_full_i,
        WR_ACK                         => WR_ACK,
        OVERFLOW                       => OVERFLOW,
        EMPTY                          => empty_fifo_out,
        ALMOST_EMPTY                   => almost_empty_fifo_out,
        VALID                          => valid_fifo_out,
        UNDERFLOW                      => underflow_fifo_out,
        RD_DATA_COUNT                  => rd_data_count_fifo_out,
        WR_DATA_COUNT                  => wr_data_count_fifo_out,
        PROG_FULL                      => prog_full_i,
        PROG_EMPTY                     => PROG_EMPTY,
        DBITERR                        => dbiterr_fifo_out,
        SBITERR                        => sbiterr_fifo_out
        );

  END GENERATE gen_as;
  ALMOST_FULL <= almost_full_i;
  PROG_FULL   <= prog_full_i;
  WR_RST_I_OUT   <= wr_rst_i;
  RD_RST_I_OUT   <= rd_rst_i;
-------------------------------------------------------------------------
-- Connect internal clock used for FWFT logic based on C_COMMON_CLOCK ---
-------------------------------------------------------------------------


  clock_fwft_common: IF (C_COMMON_CLOCK=1 ) GENERATE
     CLK_INT <= CLK;
  END GENERATE clock_fwft_common;

  clock_fwft: IF (C_COMMON_CLOCK= 0 ) GENERATE 
     CLK_INT <= RD_CLK; 
  END GENERATE clock_fwft; 


  -----------------------------------------------------------------------------
  -- Connect Internal Signals
  --  In the normal case, these signals tie directly to the FIFO's inputs and
  --  outputs.
  --  In the case of Preload Latency 0 or 1, these are the intermediate
  --  signals between the internal FIFO and the preload logic.
  -----------------------------------------------------------------------------
  latnrm: IF (C_PRELOAD_LATENCY=1 OR C_PRELOAD_LATENCY=2 OR C_FIFO_TYPE = 3) GENERATE
     rd_en_fifo_in <= rd_en_delayed;
     DOUT          <= dout_fifo_out;
     VALID         <= valid_fifo_out;
     EMPTY         <= empty_fifo_out;
     ALMOST_EMPTY  <= almost_empty_fifo_out;
     UNDERFLOW     <= underflow_fifo_out;
     RD_DATA_COUNT <= rd_data_count_fifo_out;
     WR_DATA_COUNT <= wr_data_count_fifo_out;
     SBITERR       <= sbiterr_fifo_out;
     DBITERR       <= dbiterr_fifo_out;
  END GENERATE latnrm;


  lat0: IF ((C_PRELOAD_REGS = 1) AND (C_PRELOAD_LATENCY = 0) AND C_FIFO_TYPE /= 3) GENERATE
    SIGNAL sbiterr_fwft           : STD_LOGIC := '0';
    SIGNAL dbiterr_fwft           : STD_LOGIC := '0';
    SIGNAL rd_en_to_fwft_fifo     : STD_LOGIC := '0';
    SIGNAL dout_fwft              : std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
    SIGNAL empty_fwft             : STD_LOGIC := '0';
    SIGNAL valid_stages_i         : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL stage2_reg_en_i        : STD_LOGIC := '0';
  BEGIN
    rst_fwft <= rd_rst_i WHEN (C_COMMON_CLOCK = 0) ELSE rst_i WHEN (C_HAS_RST = 1) ELSE '0';

    lat0logic : fifo_generator_v13_0_0_bhv_preload0
      GENERIC MAP (
        C_DOUT_RST_VAL         => C_DOUT_RST_VAL,
        C_DOUT_WIDTH           => C_DOUT_WIDTH,
        C_HAS_RST              => C_HAS_RST,
        C_HAS_SRST             => C_HAS_SRST,
        C_USE_DOUT_RST         => C_USE_DOUT_RST,
        C_USE_ECC              => C_USE_ECC,
        C_USERVALID_LOW        => C_VALID_LOW,
        C_EN_SAFETY_CKT        => C_EN_SAFETY_CKT,
        C_USERUNDERFLOW_LOW    => C_UNDERFLOW_LOW,
        C_ENABLE_RST_SYNC      => C_ENABLE_RST_SYNC,
        C_ERROR_INJECTION_TYPE => C_ERROR_INJECTION_TYPE,
        C_MEMORY_TYPE          => C_MEMORY_TYPE,
        C_FIFO_TYPE            => C_FIFO_TYPE
        )
      PORT MAP (
        RD_CLK                 => CLK_INT,
        RD_RST                 => rst_fwft,
        SRST                   => srst_delayed,
        WR_RST_BUSY            => wr_rst_busy_i,
        RD_RST_BUSY            => rd_rst_busy_i,
        RD_EN                  => rd_en_to_fwft_fifo,
        FIFOEMPTY              => empty_fifo_out,
        FIFODATA               => dout_fifo_out,
        FIFOSBITERR            => sbiterr_fifo_out,
        FIFODBITERR            => dbiterr_fifo_out,
        USERDATA               => dout_fwft,
        USERVALID              => valid_p0_out,
        USEREMPTY              => empty_fwft,
        USERALMOSTEMPTY        => almost_empty_p0_out,
        USERUNDERFLOW          => underflow_p0_out,
        RAMVALID               => ram_valid, --Used for observing the state of the ram_valid
        FIFORDEN               => rd_en_fifo_in,
        USERSBITERR            => sbiterr_fwft,
        USERDBITERR            => dbiterr_fwft,
        STAGE2_REG_EN          => stage2_reg_en_i,
        VALID_STAGES           => valid_stages_i
        );

    gberr_non_pkt_fifo: IF (C_FIFO_TYPE /= 1) GENERATE
      VALID              <= valid_p0_out;
      ALMOST_EMPTY       <= almost_empty_p0_out;
      UNDERFLOW          <= underflow_p0_out;
      SBITERR            <= sbiterr_fwft;
      DBITERR            <= dbiterr_fwft;
      dout_p0_out        <= dout_fwft;
      rd_en_to_fwft_fifo <= rd_en_delayed;
      empty_p0_out       <= empty_fwft;
    END GENERATE gberr_non_pkt_fifo;

    rdcg: IF (C_USE_FWFT_DATA_COUNT=1 AND (C_RD_DATA_COUNT_WIDTH > C_RD_PNTR_WIDTH) AND C_COMMON_CLOCK = 0) GENERATE
      eclk: PROCESS (CLK_INT,rst_fwft)
      BEGIN  -- process eclk
        IF (rst_fwft='1') THEN
          empty_p0_out_q        <= '1' after C_TCQ;
          almost_empty_p0_out_q <= '1' after C_TCQ;
        ELSIF CLK_INT'event AND CLK_INT = '1' THEN  -- rising clock edge
          empty_p0_out_q        <= empty_p0_out after C_TCQ;
          almost_empty_p0_out_q <= almost_empty_p0_out after C_TCQ;
        END IF;
      END PROCESS eclk;

      rcsproc: PROCESS (rd_data_count_fifo_out, empty_p0_out_q, 
                        almost_empty_p0_out_q,rst_fwft)
      BEGIN  -- process rcsproc
        IF (empty_p0_out_q='1' OR rst_fwft='1') THEN
          RD_DATA_COUNT <= int_2_std_logic_vector(0, C_RD_DATA_COUNT_WIDTH);
        ELSIF (almost_empty_p0_out_q='1') THEN
          RD_DATA_COUNT <= int_2_std_logic_vector(1, C_RD_DATA_COUNT_WIDTH);
        ELSE
          RD_DATA_COUNT <= rd_data_count_fifo_out ;
        END IF;
      END PROCESS rcsproc;

    END GENERATE rdcg;

    rdcg1: IF (C_USE_FWFT_DATA_COUNT=1 AND (C_RD_DATA_COUNT_WIDTH <= C_RD_PNTR_WIDTH) AND C_COMMON_CLOCK = 0) GENERATE
      eclk1: PROCESS (CLK_INT,rst_fwft)
      BEGIN  -- process eclk
        IF (rst_fwft='1') THEN
          empty_p0_out_q        <= '1' after C_TCQ;
          almost_empty_p0_out_q <= '1' after C_TCQ;
        ELSIF CLK_INT'event AND CLK_INT = '1' THEN  -- rising clock edge
          empty_p0_out_q        <= empty_p0_out after C_TCQ;
          almost_empty_p0_out_q <= almost_empty_p0_out after C_TCQ;
        END IF;
      END PROCESS eclk1;
 
      rcsproc1: PROCESS (rd_data_count_fifo_out, empty_p0_out_q,
                        almost_empty_p0_out_q,rst_fwft)
      BEGIN  -- process rcsproc
        IF (empty_p0_out_q='1' OR rst_fwft='1') THEN
          RD_DATA_COUNT <= int_2_std_logic_vector(0, C_RD_DATA_COUNT_WIDTH);
        ELSIF (almost_empty_p0_out_q='1') THEN
          RD_DATA_COUNT <= int_2_std_logic_vector(0, C_RD_DATA_COUNT_WIDTH);
        ELSE
          RD_DATA_COUNT <= rd_data_count_fifo_out ;
        END IF;
      END PROCESS rcsproc1;
    END GENERATE rdcg1;

    nrdcg: IF (C_USE_FWFT_DATA_COUNT=0) GENERATE
      RD_DATA_COUNT <= rd_data_count_fifo_out;
    END GENERATE nrdcg;


    WR_DATA_COUNT <= wr_data_count_fifo_out;
    RD_DATA_COUNT <= rd_data_count_fifo_out;

    ---------------------------------------------------
    -- logics for common-clock data count with fwft
    --  For common-clock FIFOs with FWFT, data count
    -- is calculated as an up-down counter to maintain
    -- accuracy.
    ---------------------------------------------------

   grd_en_npkt: IF (C_FIFO_TYPE /= 1) GENERATE
     gfwft_rd: IF (C_VALID_LOW = 0) GENERATE
       SS_FWFT_RD <= rd_en_delayed AND valid_p0_out ;
     END GENERATE gfwft_rd;
     
     ngfwft_rd: IF (C_VALID_LOW = 1) GENERATE
       SS_FWFT_RD <= rd_en_delayed AND NOT valid_p0_out ;
     END GENERATE ngfwft_rd;
   END GENERATE grd_en_npkt;

   grd_en_pkt: IF (C_FIFO_TYPE = 1) GENERATE
     gfwft_rd: IF (C_VALID_LOW = 0) GENERATE
       SS_FWFT_RD <= (NOT empty_p0_out) AND rd_en_delayed AND valid_p0_out ;
     END GENERATE gfwft_rd;
     
     ngfwft_rd: IF (C_VALID_LOW = 1) GENERATE
       SS_FWFT_RD <= (NOT empty_p0_out) AND rd_en_delayed AND (NOT valid_p0_out);
     END GENERATE ngfwft_rd;
   END GENERATE grd_en_pkt;
    
    SS_FWFT_WR <= wr_en_delayed AND (NOT FULL_int) ;  

  cc_data_cnt:  IF (C_HAS_DATA_COUNT = 1 AND C_USE_FWFT_DATA_COUNT = 1) GENERATE
     count_fwft: PROCESS (CLK, rst_fwft)
      BEGIN
        IF (rst_fwft = '1' AND C_HAS_RST=1) THEN
           DATA_COUNT_FWFT <= (OTHERS=>'0') after C_TCQ;
        ELSIF CLK'event AND CLK = '1' THEN
          IF ((srst_delayed='1' OR wr_rst_busy_i='1' OR rd_rst_busy_i='1') AND C_HAS_SRST=1) THEN
            DATA_COUNT_FWFT <= (OTHERS=>'0') after C_TCQ;
          ELSE
            IF (SS_FWFT_WR = '0' and SS_FWFT_RD ='0')  THEN
               DATA_COUNT_FWFT <= DATA_COUNT_FWFT after C_TCQ;
            ELSIF (SS_FWFT_WR = '0' and SS_FWFT_RD ='1')  THEN
               DATA_COUNT_FWFT <= DATA_COUNT_FWFT - 1 after C_TCQ;
            ELSIF (SS_FWFT_WR = '1' and SS_FWFT_RD ='0')  THEN
                DATA_COUNT_FWFT <= DATA_COUNT_FWFT + 1 after C_TCQ;
            ELSE
               DATA_COUNT_FWFT <= DATA_COUNT_FWFT after C_TCQ;
            END IF ;
          END IF;
        END IF;
      END PROCESS count_fwft;
  END GENERATE cc_data_cnt;

----------------------------------------------

    DOUT          <= dout_p0_out;
    EMPTY         <= empty_p0_out;

    gpkt_fifo_fwft: IF (C_FIFO_TYPE = 1) GENERATE
      SIGNAL wr_pkt_count           : STD_LOGIC_VECTOR(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL rd_pkt_count           : STD_LOGIC_VECTOR(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL rd_pkt_count_plus1     : STD_LOGIC_VECTOR(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL rd_pkt_count_reg       : STD_LOGIC_VECTOR(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL eop_at_stage2          : STD_LOGIC := '0';
      SIGNAL ram_pkt_empty          : STD_LOGIC := '0';
      SIGNAL ram_pkt_empty_d1       : STD_LOGIC := '0';
      SIGNAL pkt_ready_to_read      : STD_LOGIC := '0';
      SIGNAL fwft_stage1_valid      : STD_LOGIC := '0';
      SIGNAL fwft_stage2_valid      : STD_LOGIC := '0';
      SIGNAL rd_en_2_stage2         : STD_LOGIC := '0';
      SIGNAL ram_wr_en_pkt_fifo     : STD_LOGIC := '0';
      SIGNAL wr_eop                 : STD_LOGIC := '0';
      SIGNAL dummy_wr_eop           : STD_LOGIC := '0';
      SIGNAL ram_rd_en_compare      : STD_LOGIC := '0';
      SIGNAL partial_packet         : STD_LOGIC := '0';
      SIGNAL wr_rst_fwft_pkt_fifo   : STD_LOGIC := '0';
      SIGNAL stage1_eop             : STD_LOGIC := '0';
      SIGNAL stage1_eop_d1          : STD_LOGIC := '0';
      SIGNAL rd_en_fifo_in_d1       : STD_LOGIC := '0';
    BEGIN
      wr_rst_fwft_pkt_fifo <= wr_rst_i WHEN (C_COMMON_CLOCK = 0) ELSE rst_i WHEN (C_HAS_RST = 1) ELSE '0';

      -- Generate Dummy WR_EOP for partial packet (Only for AXI Streaming)
      -- When Packet EMPTY is high, and FIFO is full, then generate the dummy WR_EOP
      -- When dummy WR_EOP is high, mask the actual EOP to avoid double increment of
      -- write packet count
      gdummy_wr_eop: IF (C_AXI_TYPE = 0) GENERATE
        SIGNAL packet_empty_wr : std_logic := '1';
      BEGIN
        proc_dummy_wr_eop: PROCESS (wr_rst_fwft_pkt_fifo, WR_CLK)       
        BEGIN
          IF (wr_rst_fwft_pkt_fifo = '1') THEN
            partial_packet   <= '0';
          ELSIF (WR_CLK'event AND WR_CLK = '1') THEN
            IF (srst_delayed = '1' OR wr_rst_busy_i='1' OR rd_rst_busy_i='1') THEN
              partial_packet   <= '0' AFTER C_TCQ;
            ELSE
              IF (almost_full_i = '1' AND ram_wr_en_pkt_fifo = '1' AND packet_empty_wr = '1' AND din_delayed(0) = '0') THEN
                partial_packet <= '1' AFTER C_TCQ;
              ELSE
                IF (partial_packet = '1' AND din_delayed(0) = '1' AND ram_wr_en_pkt_fifo = '1') THEN
                  partial_packet <= '0' AFTER C_TCQ;
                END IF; 
              END IF; 
            END IF; 
          END IF; 
        END PROCESS proc_dummy_wr_eop;
        dummy_wr_eop <= almost_full_i AND ram_wr_en_pkt_fifo AND packet_empty_wr AND (NOT din_delayed(0)) AND (NOT partial_packet);
  
        -- Synchronize the packet EMPTY in WR clock domain to generate the dummy WR_EOP
        gpkt_empty_sync: IF (C_COMMON_CLOCK = 0) GENERATE
          TYPE pkt_empty_array IS ARRAY (0 TO C_SYNCHRONIZER_STAGE-1) OF STD_LOGIC;
          SIGNAL pkt_empty_sync : pkt_empty_array := (OTHERS => '1');
        BEGIN
          proc_empty_sync: PROCESS (wr_rst_fwft_pkt_fifo, WR_CLK)       
          BEGIN
            IF (wr_rst_fwft_pkt_fifo = '1') THEN
              pkt_empty_sync   <= (OTHERS => '1');
            ELSIF (WR_CLK'event AND WR_CLK = '1') THEN
              pkt_empty_sync   <= pkt_empty_sync(1 to C_SYNCHRONIZER_STAGE-1) & empty_p0_out AFTER C_TCQ;
            END IF; 
          END PROCESS proc_empty_sync;
          packet_empty_wr <= pkt_empty_sync(0);
        END GENERATE gpkt_empty_sync;
  
        gnpkt_empty_sync: IF (C_COMMON_CLOCK = 1) GENERATE
          packet_empty_wr <= empty_p0_out;
        END GENERATE gnpkt_empty_sync;
      END GENERATE gdummy_wr_eop;

      proc_stage1_eop: PROCESS (rst_fwft, CLK_INT)       
      BEGIN
        IF (rst_fwft = '1') THEN
          stage1_eop_d1    <= '0';
          rd_en_fifo_in_d1 <= '0';
        ELSIF (CLK_INT'event AND CLK_INT = '1') THEN
          IF (srst_delayed = '1' OR wr_rst_busy_i='1' OR rd_rst_busy_i='1') THEN
            stage1_eop_d1    <= '0' AFTER C_TCQ;
            rd_en_fifo_in_d1 <= '0' AFTER C_TCQ;
          ELSE
            stage1_eop_d1    <= stage1_eop AFTER C_TCQ;
            rd_en_fifo_in_d1 <= rd_en_fifo_in AFTER C_TCQ;
          END IF; 
        END IF; 
      END PROCESS proc_stage1_eop;
      stage1_eop <= dout_fifo_out(0) WHEN (rd_en_fifo_in_d1 = '1') ELSE stage1_eop_d1;

      ram_wr_en_pkt_fifo <= wr_en_delayed AND (NOT FULL_int);
      wr_eop <= ram_wr_en_pkt_fifo AND ((din_delayed(0) AND (NOT partial_packet)) OR dummy_wr_eop);
      ram_rd_en_compare <= stage2_reg_en_i AND stage1_eop;

      pkt_fifo_fwft : fifo_generator_v13_0_0_bhv_preload0
        GENERIC MAP (
          C_DOUT_RST_VAL         => C_DOUT_RST_VAL,
          C_DOUT_WIDTH           => C_DOUT_WIDTH,
          C_HAS_RST              => C_HAS_RST,
          C_HAS_SRST             => C_HAS_SRST,
          C_USE_DOUT_RST         => C_USE_DOUT_RST,
          C_USE_ECC              => C_USE_ECC,
          C_USERVALID_LOW        => C_VALID_LOW,
          C_USERUNDERFLOW_LOW    => C_UNDERFLOW_LOW,
          C_ENABLE_RST_SYNC      => C_ENABLE_RST_SYNC,
          C_ERROR_INJECTION_TYPE => C_ERROR_INJECTION_TYPE,
          C_MEMORY_TYPE          => C_MEMORY_TYPE,
          C_FIFO_TYPE            => 2 -- Enable low latency fwft logic
          )
        PORT MAP (
          RD_CLK                 => CLK_INT,
          RD_RST                 => rst_fwft,
          SRST                   => srst_delayed,
          WR_RST_BUSY            => wr_rst_busy_i,
          RD_RST_BUSY            => rd_rst_busy_i,
          RD_EN                  => rd_en_delayed,
          FIFOEMPTY              => pkt_ready_to_read,
          FIFODATA               => dout_fwft,
          FIFOSBITERR            => sbiterr_fwft,
          FIFODBITERR            => dbiterr_fwft,
          USERDATA               => dout_p0_out,
          USERVALID              => OPEN,
          USEREMPTY              => empty_p0_out,
          USERALMOSTEMPTY        => OPEN,
          USERUNDERFLOW          => OPEN,
          RAMVALID               => OPEN, --Used for observing the state of the ram_valid
          FIFORDEN               => rd_en_2_stage2,
          USERSBITERR            => SBITERR,
          USERDBITERR            => DBITERR,
          STAGE2_REG_EN          => OPEN,
          VALID_STAGES           => OPEN
          );

      pkt_ready_to_read <= NOT ((ram_pkt_empty NOR empty_fwft) AND ((valid_stages_i(0) AND valid_stages_i(1)) OR eop_at_stage2));
      rd_en_to_fwft_fifo <= NOT empty_fwft AND rd_en_2_stage2;

      pregsm : PROCESS (CLK_INT, rst_fwft)
      BEGIN
        IF (rst_fwft = '1') THEN
          eop_at_stage2        <= '0';
        ELSIF (CLK_INT'event AND CLK_INT = '1') THEN
          IF (stage2_reg_en_i = '1') THEN
            eop_at_stage2      <= stage1_eop AFTER C_TCQ;
          END IF; 
        END IF; 
      END PROCESS pregsm;

      -----------------------------------------------------------------------------
      -- Write and Read Packet Count
      -----------------------------------------------------------------------------
      proc_wr_pkt_cnt: PROCESS (WR_CLK, wr_rst_fwft_pkt_fifo)
      BEGIN  
        IF (wr_rst_fwft_pkt_fifo = '1') THEN
          wr_pkt_count       <= (OTHERS => '0');
        ELSIF (WR_CLK'event AND WR_CLK = '1') THEN  
          IF (srst_delayed='1' OR wr_rst_busy_i='1' OR rd_rst_busy_i='1') THEN
            wr_pkt_count       <= (OTHERS => '0') AFTER C_TCQ;
          ELSIF (wr_eop = '1') THEN
            wr_pkt_count       <= wr_pkt_count + int_2_std_logic_vector(1,C_WR_PNTR_WIDTH) AFTER C_TCQ;
          END IF;
        END IF;
      END PROCESS proc_wr_pkt_cnt;

      grss_pkt_cnt : IF C_COMMON_CLOCK = 1 GENERATE
        proc_rd_pkt_cnt: PROCESS (CLK_INT, rst_fwft)
        BEGIN  
          IF (rst_fwft = '1') THEN
            rd_pkt_count       <= (OTHERS => '0');
            rd_pkt_count_plus1 <= int_2_std_logic_vector(1,C_RD_PNTR_WIDTH);
          ELSIF (CLK_INT'event AND CLK_INT = '1') THEN
            IF (srst_delayed='1' OR wr_rst_busy_i='1' OR rd_rst_busy_i='1') THEN
              rd_pkt_count       <= (OTHERS => '0') AFTER C_TCQ;
              rd_pkt_count_plus1 <= int_2_std_logic_vector(1,C_RD_PNTR_WIDTH) AFTER C_TCQ;
            ELSIF (stage2_reg_en_i = '1' AND stage1_eop = '1') THEN
              rd_pkt_count       <= rd_pkt_count + int_2_std_logic_vector(1,C_RD_PNTR_WIDTH) AFTER C_TCQ;
              rd_pkt_count_plus1 <= rd_pkt_count_plus1 + int_2_std_logic_vector(1,C_RD_PNTR_WIDTH) AFTER C_TCQ;
            END IF;
          END IF;
        END PROCESS proc_rd_pkt_cnt;

        proc_pkt_empty : PROCESS (CLK_INT, rst_fwft)
        BEGIN
          IF (rst_fwft = '1') THEN
            ram_pkt_empty    <= '1';
            ram_pkt_empty_d1 <= '1';
          ELSIF (CLK_INT'event AND CLK_INT = '1') THEN
              IF (SRST='1' OR wr_rst_busy_i='1' OR rd_rst_busy_i='1') THEN
                ram_pkt_empty    <= '1' AFTER C_TCQ;
                ram_pkt_empty_d1 <= '1' AFTER C_TCQ;
              ELSE
                IF ((rd_pkt_count = wr_pkt_count) AND wr_eop = '1') THEN
                  ram_pkt_empty    <= '0' AFTER C_TCQ;
                  ram_pkt_empty_d1 <= '0' AFTER C_TCQ;
                ELSIF (ram_pkt_empty_d1 = '1' AND rd_en_to_fwft_fifo = '1') THEN
                  ram_pkt_empty    <= '1' AFTER C_TCQ;
                ELSIF ((rd_pkt_count_plus1 = wr_pkt_count) AND wr_eop = '0' AND almost_full_i = '0' AND ram_rd_en_compare = '1') THEN
                  ram_pkt_empty_d1 <= '1' AFTER C_TCQ;
                END IF;
              END IF; 
          END IF; 
        END PROCESS proc_pkt_empty;
      END GENERATE grss_pkt_cnt;
    
      gras_pkt_cnt : IF C_COMMON_CLOCK = 0 GENERATE

        TYPE wr_pkt_cnt_sync_array IS ARRAY (C_SYNCHRONIZER_STAGE-1 DOWNTO 0) OF std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0);
        SIGNAL wr_pkt_count_q         : wr_pkt_cnt_sync_array := (OTHERS => (OTHERS => '0'));
        SIGNAL wr_pkt_count_b2g       : STD_LOGIC_VECTOR(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        SIGNAL wr_pkt_count_rd        : STD_LOGIC_VECTOR(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      BEGIN
        -- Delay the write packet count in write clock domain to accomodate the binary to gray conversion delay
        proc_wr_pkt_cnt_b2g: PROCESS (WR_CLK, wr_rst_fwft_pkt_fifo)
        BEGIN  
          IF (wr_rst_fwft_pkt_fifo = '1') THEN
            wr_pkt_count_b2g   <= (OTHERS => '0');
          ELSIF (WR_CLK'event AND WR_CLK = '1') THEN  
            wr_pkt_count_b2g   <= wr_pkt_count AFTER C_TCQ;
          END IF;
        END PROCESS proc_wr_pkt_cnt_b2g;

        -- Synchronize the delayed write packet count in read domain, and also compensate the gray to binay conversion delay
        proc_wr_pkt_cnt_rd: PROCESS (CLK_INT, rst_fwft)
        BEGIN  
          IF (wr_rst_fwft_pkt_fifo = '1') THEN
            wr_pkt_count_q     <= (OTHERS => (OTHERS => '0'));
            wr_pkt_count_rd    <= (OTHERS => '0');
          ELSIF (CLK_INT'event AND CLK_INT = '1') THEN  
            wr_pkt_count_q     <= wr_pkt_count_q(C_SYNCHRONIZER_STAGE-2 DOWNTO 0) & wr_pkt_count_b2g AFTER C_TCQ;
            wr_pkt_count_rd    <= wr_pkt_count_q(C_SYNCHRONIZER_STAGE-1) AFTER C_TCQ;
          END IF;
        END PROCESS proc_wr_pkt_cnt_rd;

        rd_pkt_count       <= rd_pkt_count_reg + int_2_std_logic_vector(1,C_RD_PNTR_WIDTH)
                              WHEN (stage1_eop = '1') ELSE rd_pkt_count_reg;

        proc_rd_pkt_cnt: PROCESS (CLK_INT, rst_fwft)
        BEGIN  
          IF (rst_fwft = '1') THEN
            rd_pkt_count_reg      <= (OTHERS => '0');
          ELSIF (RD_CLK'event AND RD_CLK = '1') THEN
            IF (rd_en_fifo_in = '1') THEN
              rd_pkt_count_reg  <= rd_pkt_count AFTER C_TCQ;     
            END IF;
          END IF;
        END PROCESS proc_rd_pkt_cnt;

        proc_pkt_empty_as : PROCESS (CLK_INT, rst_fwft)
        BEGIN
          IF (rst_fwft = '1') THEN
            ram_pkt_empty    <= '1';
            ram_pkt_empty_d1 <= '1';
          ELSIF (CLK_INT'event AND CLK_INT = '1') THEN
            IF (rd_pkt_count /= wr_pkt_count_rd) THEN
              ram_pkt_empty    <= '0' AFTER C_TCQ;
              ram_pkt_empty_d1 <= '0' AFTER C_TCQ;
            ELSIF (ram_pkt_empty_d1 = '1' AND rd_en_to_fwft_fifo = '1') THEN
              ram_pkt_empty    <= '1' AFTER C_TCQ;
            ELSIF ((rd_pkt_count = wr_pkt_count_rd) AND stage2_reg_en_i = '1') THEN
              ram_pkt_empty_d1 <= '1' AFTER C_TCQ;
            END IF;
          END IF; 
        END PROCESS proc_pkt_empty_as;

      END GENERATE gras_pkt_cnt;

    END GENERATE gpkt_fifo_fwft;


  END GENERATE lat0;


  gdc_fwft: IF (C_HAS_DATA_COUNT = 1) GENERATE
  begin 
    ss_count:  IF ((NOT ((C_PRELOAD_REGS = 1) AND (C_PRELOAD_LATENCY = 0)) ) OR
                   (C_USE_FWFT_DATA_COUNT = 0) )GENERATE
    begin  
      DATA_COUNT   <= data_count_fifo_out ;
    end generate ss_count ;
  
    ss_count_fwft1:  IF ((C_PRELOAD_REGS = 1) AND (C_PRELOAD_LATENCY = 0) AND
                         (C_DATA_COUNT_WIDTH > C_RD_PNTR_WIDTH) AND
                         (C_USE_FWFT_DATA_COUNT = 1) ) GENERATE 
    begin 
      DATA_COUNT   <= DATA_COUNT_FWFT(C_RD_PNTR_WIDTH DOWNTO 0) ;
    end generate ss_count_fwft1 ;
  
    ss_count_fwft2:  IF ((C_PRELOAD_REGS = 1) AND (C_PRELOAD_LATENCY = 0) AND
                         (C_DATA_COUNT_WIDTH <= C_RD_PNTR_WIDTH)  AND
                         (C_USE_FWFT_DATA_COUNT = 1)) GENERATE
    begin  
      DATA_COUNT   <= DATA_COUNT_FWFT(C_RD_PNTR_WIDTH  DOWNTO C_RD_PNTR_WIDTH-C_DATA_COUNT_WIDTH+1) ;
    end generate ss_count_fwft2 ;
  end generate gdc_fwft;

  FULL <= FULL_int;


  -------------------------------------------------------------------------------
  -- If there is a reset input, generate internal reset signals
  -- The latency of reset will match the core behavior
  -------------------------------------------------------------------------------
  --Single RST
  grst_sync : IF (C_ENABLE_RST_SYNC = 1 OR C_FIFO_TYPE = 3) GENERATE
    grst : IF (C_HAS_RST = 1) GENERATE
      gic_rst : IF (C_COMMON_CLOCK = 0 OR C_FIFO_TYPE = 3) GENERATE
        SIGNAL rd_rst_asreg    : std_logic:= '0';
        SIGNAL rd_rst_asreg_d1 : std_logic:= '0';
        SIGNAL rd_rst_asreg_d2 : std_logic:= '0';
        SIGNAL rd_rst_comb     : std_logic:= '0';
        SIGNAL rd_rst_reg      : std_logic:= '0';
        SIGNAL wr_rst_asreg    : std_logic:= '0';
        SIGNAL wr_rst_asreg_d1 : std_logic:= '0';
        SIGNAL wr_rst_asreg_d2 : std_logic:= '0';
        SIGNAL wr_rst_comb     : std_logic:= '0';
        SIGNAL wr_rst_reg      : std_logic:= '0';
        SIGNAL rst_active      : STD_LOGIC := '0';
        SIGNAL rst_active_i    : STD_LOGIC := '1';
        SIGNAL rst_delayed_d1  : STD_LOGIC := '1';
        SIGNAL rst_delayed_d2  : STD_LOGIC := '1';
      BEGIN
          PROCESS (WR_CLK, rst_delayed)
          BEGIN
            IF (rst_delayed = '1') THEN
              wr_rst_asreg <=   '1' after C_TCQ;
            ELSIF (WR_CLK'event and WR_CLK = '1') THEN
              IF (wr_rst_asreg_d1 = '1') THEN
                wr_rst_asreg <= '0' after C_TCQ;
              END IF;
            END IF;
        
            IF (WR_CLK'event and WR_CLK = '1') THEN
              wr_rst_asreg_d1 <= wr_rst_asreg after C_TCQ;
              wr_rst_asreg_d2 <= wr_rst_asreg_d1 after C_TCQ;
            END IF;
          END PROCESS;
          
          PROCESS (wr_rst_asreg, wr_rst_asreg_d2)
          BEGIN
            wr_rst_comb <= NOT wr_rst_asreg_d2 AND wr_rst_asreg;
          END PROCESS;

          PROCESS (WR_CLK, wr_rst_comb)
          BEGIN
            IF (wr_rst_comb = '1') THEN
              wr_rst_reg <= '1' after C_TCQ;
            ELSIF (WR_CLK'event and WR_CLK = '1') THEN
              wr_rst_reg <= '0' after C_TCQ;
            END IF;
          END PROCESS;
          PROCESS (WR_CLK)
          BEGIN
            IF (WR_CLK'event and WR_CLK = '1') THEN
              rst_delayed_d1 <= rst_delayed after C_TCQ;
              rst_delayed_d2 <= rst_delayed_d1 after C_TCQ;
              IF (wr_rst_reg = '1' OR rst_delayed_d2 = '1') THEN
                rst_active_i <= '1' after C_TCQ;
              ELSE
                rst_active_i <= rst_active after C_TCQ;
              END IF;
            END IF;
          END PROCESS;

          
          PROCESS (RD_CLK, rst_delayed)
          BEGIN
            IF (rst_delayed = '1') THEN
              rd_rst_asreg <=   '1' after C_TCQ;
            ELSIF (RD_CLK'event and RD_CLK = '1') THEN
              IF (rd_rst_asreg_d1 = '1') THEN
                rd_rst_asreg <= '0' after C_TCQ;
              END IF;
            END IF;
        
            IF (RD_CLK'event and RD_CLK = '1') THEN
              rd_rst_asreg_d1 <= rd_rst_asreg after C_TCQ;
              rd_rst_asreg_d2 <= rd_rst_asreg_d1 after C_TCQ;
            END IF;
          END PROCESS;
          
          PROCESS (rd_rst_asreg, rd_rst_asreg_d2)
          BEGIN
            rd_rst_comb <= NOT rd_rst_asreg_d2 AND rd_rst_asreg;
          END PROCESS;
        
          PROCESS (RD_CLK, rd_rst_comb)
          BEGIN
            IF (rd_rst_comb = '1') THEN
              rd_rst_reg <= '1' after C_TCQ;
            ELSIF (RD_CLK'event and RD_CLK = '1') THEN
              rd_rst_reg <= '0' after C_TCQ;
            END IF;
          END PROCESS;
  
          wr_rst_i <= wr_rst_reg;
          rd_rst_i <= rd_rst_reg;
          wr_rst_busy <= '0';
          wr_rst_busy_i <= '0';
          rd_rst_busy <= '0';
          rd_rst_busy_i <= '0';

      END GENERATE gic_rst;

      gcc_rst : IF (C_COMMON_CLOCK = 1) GENERATE
        SIGNAL rst_asreg      : std_logic := '0';
        SIGNAL rst_active_i   : STD_LOGIC := '1';
        SIGNAL rst_delayed_d1 : STD_LOGIC := '1';
        SIGNAL rst_delayed_d2 : STD_LOGIC := '1';
        SIGNAL rst_asreg_d1   : std_logic := '0';
        SIGNAL rst_asreg_d2   : std_logic := '0';
        SIGNAL rst_comb       : std_logic := '0';
        SIGNAL rst_reg        : std_logic := '0';
      BEGIN
          PROCESS (CLK, rst_delayed)
          BEGIN
            IF (rst_delayed = '1') THEN
              rst_asreg <=   '1' after C_TCQ;
            ELSIF (CLK'event and CLK = '1') THEN
              IF (rst_asreg_d1 = '1') THEN
                rst_asreg <= '0' after C_TCQ;
              ELSE
                rst_asreg <= rst_asreg after C_TCQ;
              END IF;
            END IF;
        
            IF (CLK'event and CLK = '1') THEN
              rst_asreg_d1 <= rst_asreg after C_TCQ;
              rst_asreg_d2 <= rst_asreg_d1 after C_TCQ;
            END IF;
          END PROCESS;
          
          PROCESS (rst_asreg, rst_asreg_d2)
          BEGIN
            rst_comb <= NOT rst_asreg_d2 AND rst_asreg;
          END PROCESS;
        
          PROCESS (CLK, rst_comb)
          BEGIN
            IF (rst_comb = '1') THEN
              rst_reg <= '1' after C_TCQ;
            ELSIF (CLK'event and CLK = '1') THEN
              rst_reg <= '0' after C_TCQ;
            END IF;
          END PROCESS;

         rst_i <= rst_reg;
         wr_rst_busy <= '0';
         wr_rst_busy_i <= '0';
         rd_rst_busy <= '0';
         rd_rst_busy_i <= '0';

          PROCESS (CLK)
          BEGIN
            IF (CLK'event and CLK = '1') THEN
              rst_delayed_d1 <= rst_delayed after C_TCQ;
              rst_delayed_d2 <= rst_delayed_d1 after C_TCQ;
              IF (rst_reg = '1' OR rst_delayed_d2 = '1') THEN
                rst_active_i <= '1' after C_TCQ;
              ELSE
                rst_active_i <= rst_reg after C_TCQ;
              END IF;
            END IF;
          END PROCESS;
      END GENERATE gcc_rst;
    END GENERATE grst;

    gnrst : IF (C_HAS_RST = 0) GENERATE
      wr_rst_i <= '0';
      rd_rst_i <= '0';
      rst_i    <= '0';
    END GENERATE gnrst;

    gsrst : IF (C_HAS_SRST = 1) GENERATE
      gcc_srst : IF (C_COMMON_CLOCK = 1) GENERATE
        SIGNAL rst_asreg      : std_logic := '0';
        SIGNAL rst_asreg_d1   : std_logic := '0';
        SIGNAL rst_asreg_d2   : std_logic := '0';
        SIGNAL rst_comb       : std_logic := '0';
        SIGNAL rst_reg        : std_logic := '0';
      BEGIN
        g8s_cc_srst: IF (C_FAMILY = "virtexu" OR C_FAMILY = "kintexu" OR C_FAMILY = "artixu" OR C_FAMILY = "virtexuplus" OR C_FAMILY = "zynquplus" OR C_FAMILY = "kintexuplus") GENERATE
          SIGNAL wr_rst_reg : STD_LOGIC := '0';
          SIGNAL rst_active_i   : STD_LOGIC := '1';
          SIGNAL rst_delayed_d1 : STD_LOGIC := '1';
          SIGNAL rst_delayed_d2 : STD_LOGIC := '1';
        BEGIN
          prst: PROCESS (CLK)
          BEGIN
            IF (CLK'event AND CLK = '1') THEN
              IF (wr_rst_reg = '0' AND srst_delayed = '1') THEN
                 wr_rst_reg <= '1';
              ELSE
                 IF (wr_rst_reg = '1') THEN
                    wr_rst_reg <= '0';
                 ELSE
                    wr_rst_reg <= wr_rst_reg;
                 END IF;
              END IF;
            END IF;
          END PROCESS;
          rst_i <= wr_rst_reg;
          rd_rst_busy <= wr_rst_reg;
          rd_rst_busy_i <= wr_rst_reg;
          wr_rst_busy <= wr_rst_reg WHEN (C_MEMORY_TYPE /= 4) ELSE rst_active_i;
          wr_rst_busy_i <= wr_rst_reg WHEN (C_MEMORY_TYPE /= 4) ELSE rst_active_i;
          rst_full_ff_i  <= wr_rst_reg;
          rst_full_gen_i <= rst_active_i WHEN (C_FULL_FLAGS_RST_VAL = 1) ELSE '0';


          PROCESS (CLK)
          BEGIN
            IF (CLK'event and CLK = '1') THEN
              rst_delayed_d1 <= srst_delayed after C_TCQ;
              rst_delayed_d2 <= rst_delayed_d1 after C_TCQ;
              IF (wr_rst_reg = '1' OR rst_delayed_d2 = '1') THEN
                rst_active_i <= '1' after C_TCQ;
              ELSE
                rst_active_i <= wr_rst_reg after C_TCQ;
              END IF;
            END IF;
          END PROCESS;
        END GENERATE g8s_cc_srst;


     END GENERATE gcc_srst;
    END GENERATE gsrst;
  END GENERATE grst_sync;

  gnrst_sync : IF (C_ENABLE_RST_SYNC = 0) GENERATE
      wr_rst_i <= wr_rst_delayed;
      rd_rst_i <= rd_rst_delayed;
      rst_i    <= '0';
  END GENERATE gnrst_sync;
 
  rst_2_sync <= rst_delayed WHEN (C_ENABLE_RST_SYNC = 1) ELSE wr_rst_delayed;
  rst_2_sync_safety <= RST WHEN (C_ENABLE_RST_SYNC = 1) ELSE RD_RST;
  clk_2_sync <= CLK WHEN (C_COMMON_CLOCK = 1) ELSE WR_CLK;
  clk_2_sync_safety <= CLK WHEN (C_COMMON_CLOCK = 1) ELSE RD_CLK;

   grst_safety_ckt: IF (C_EN_SAFETY_CKT = 1) GENERATE
      SIGNAL rst_d1_safety : STD_LOGIC := '1';
      SIGNAL rst_d2_safety : STD_LOGIC := '1';
      SIGNAL rst_d3_safety : STD_LOGIC := '1';
      SIGNAL rst_d4_safety : STD_LOGIC := '1';
      SIGNAL rst_d5_safety : STD_LOGIC := '1';
      SIGNAL rst_d6_safety : STD_LOGIC := '1';
      SIGNAL rst_d7_safety : STD_LOGIC := '1';
    BEGIN

        prst: PROCESS (rst_2_sync_safety, clk_2_sync_safety)
        BEGIN
          IF (rst_2_sync_safety = '1') THEN
            rst_d1_safety         <= '1';
            rst_d2_safety         <= '1';
            rst_d3_safety         <= '1';
            rst_d4_safety         <= '1';
            rst_d5_safety         <= '1';
            rst_d6_safety         <= '1';
            rst_d7_safety         <= '1';
          ELSIF (clk_2_sync'event AND clk_2_sync = '1') THEN
            rst_d1_safety         <= '0' AFTER C_TCQ;
            rst_d2_safety         <= rst_d1_safety AFTER C_TCQ;
            rst_d3_safety         <= rst_d2_safety AFTER C_TCQ;
            rst_d4_safety         <= rst_d3_safety AFTER C_TCQ;
            rst_d5_safety         <= rst_d4_safety AFTER C_TCQ;
            rst_d6_safety         <= rst_d5_safety AFTER C_TCQ;
            rst_d7_safety         <= rst_d6_safety AFTER C_TCQ;
          END IF;
        END PROCESS prst;

   assert_safety: PROCESS (rst_d7_safety, wr_en)
   BEGIN
    IF(rst_d7_safety = '1' AND wr_en = '1') THEN
      assert false
      report "A wriite attempt has been made within the 7 clock sycles of reset de-assertion. This can lead to data discrepancy when safety circuit is enabled"
       severity warning;
    END IF;
   END PROCESS assert_safety;

    END GENERATE grst_safety_ckt;

 
  grstd1 : IF ((C_HAS_RST = 1 OR C_HAS_SRST = 1 OR C_ENABLE_RST_SYNC = 0)) GENERATE

  -- RST_FULL_GEN replaces the reset falling edge detection used to de-assert
  -- FULL, ALMOST_FULL & PROG_FULL flags if C_FULL_FLAGS_RST_VAL = 1.

  -- RST_FULL_FF goes to the reset pin of the final flop of FULL, ALMOST_FULL &
  -- PROG_FULL

    grst_full: IF (C_FULL_FLAGS_RST_VAL = 1) GENERATE
      SIGNAL rst_d1 : STD_LOGIC := '1';
      SIGNAL rst_d2 : STD_LOGIC := '1';
      SIGNAL rst_d3 : STD_LOGIC := '1';
      SIGNAL rst_d4 : STD_LOGIC := '1';
      SIGNAL rst_d5 : STD_LOGIC := '1';
    BEGIN

      grst_f: IF (C_HAS_SRST = 0) GENERATE
        prst: PROCESS (rst_2_sync, clk_2_sync)
        BEGIN
          IF (rst_2_sync = '1') THEN
            rst_d1         <= '1';
            rst_d2         <= '1';
            rst_d3         <= '1';
            rst_d4         <= '1';
            rst_d5         <= '1';
          ELSIF (clk_2_sync'event AND clk_2_sync = '1') THEN
            rst_d1         <= '0' AFTER C_TCQ;
            rst_d2         <= rst_d1 AFTER C_TCQ;
            rst_d3         <= rst_d2 AFTER C_TCQ;
            rst_d4         <= rst_d3 AFTER C_TCQ;
            rst_d5         <= rst_d4 AFTER C_TCQ;
          END IF;
        END PROCESS prst;

      g_nsafety_ckt: IF ((C_EN_SAFETY_CKT = 0)  ) GENERATE
            rst_full_gen_i <= rst_d3;
      END GENERATE g_nsafety_ckt;

      g_safety_ckt: IF (C_EN_SAFETY_CKT = 1 ) GENERATE
            rst_full_gen_i  <= rst_d5; 
      END GENERATE g_safety_ckt;


        rst_full_ff_i <= rst_d2;
      END GENERATE grst_f;

      ngrst_f: IF (C_HAS_SRST = 1) GENERATE
        prst: PROCESS (clk_2_sync)
        BEGIN
          IF (clk_2_sync'event AND clk_2_sync = '1') THEN
            IF (srst_delayed = '1') THEN
              rst_d1         <= '1' AFTER C_TCQ;
              rst_d2         <= '1' AFTER C_TCQ;
              rst_d3         <= '1' AFTER C_TCQ;
              rst_full_gen_i <= '0' AFTER C_TCQ;
            ELSE
              rst_d1         <= '0' AFTER C_TCQ;
              rst_d2         <= rst_d1 AFTER C_TCQ;
              rst_d3         <= rst_d2 AFTER C_TCQ;
              rst_full_gen_i <= rst_d3 AFTER C_TCQ;
            END IF;
          END IF;
        END PROCESS prst;

        rst_full_ff_i <= '0';
      END GENERATE ngrst_f;

    END GENERATE grst_full;

    gnrst_full: IF (C_FULL_FLAGS_RST_VAL = 0) GENERATE
      rst_full_gen_i <= '0';
      rst_full_ff_i  <= wr_rst_i WHEN (C_COMMON_CLOCK = 0) ELSE rst_i;
    END GENERATE gnrst_full;
 
  END GENERATE grstd1;

END behavioral;


-------------------------------------------------------------------------------
--
-- Register Slice
--   Register one AXI channel on forward and/or reverse signal path
--
----------------------------------------------------------------------------
--
-- Structure:
--   reg_slice
--
----------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY fifo_generator_v13_0_0_axic_reg_slice IS
  GENERIC (
    C_FAMILY         : string  := "";
    C_DATA_WIDTH     : integer := 32;
    C_REG_CONFIG     : integer := 0
   );
  PORT (
   -- System Signals
   ACLK              : IN  STD_LOGIC;
   ARESET            : IN  STD_LOGIC;

   -- Slave side
   S_PAYLOAD_DATA    : IN  STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
   S_VALID           : IN  STD_LOGIC;
   S_READY           : OUT STD_LOGIC := '0';

   -- Master side
   M_PAYLOAD_DATA    : OUT STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
   M_VALID           : OUT STD_LOGIC := '0';
   M_READY           : IN  STD_LOGIC
   );

END fifo_generator_v13_0_0_axic_reg_slice;

ARCHITECTURE xilinx OF fifo_generator_v13_0_0_axic_reg_slice IS
  SIGNAL storage_data1  : STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL s_ready_i      : STD_LOGIC := '0'; -- local signal of output
  SIGNAL m_valid_i      : STD_LOGIC := '0'; -- local signal of output
  SIGNAL areset_d1      : STD_LOGIC := '0'; -- Reset delay register
  SIGNAL rst_asreg      : std_logic := '0';
  SIGNAL rst_asreg_d1   : std_logic := '0';
  SIGNAL rst_asreg_d2   : std_logic := '0';
  SIGNAL rst_comb       : std_logic := '0';
  -- Constant to have clock to register delay
  CONSTANT TFF   : time := 100 ps;
BEGIN
  --------------------------------------------------------------------
  --
  -- Both FWD and REV mode
  --
  --------------------------------------------------------------------
  gfwd_rev: IF (C_REG_CONFIG = 0) GENERATE
    CONSTANT ZERO             : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";
    CONSTANT ONE              : STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";
    CONSTANT TWO              : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
    SIGNAL   state            : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL   storage_data2    : STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL   load_s1          : STD_LOGIC;
    SIGNAL   load_s2          : STD_LOGIC;
    SIGNAL   load_s1_from_s2  : BOOLEAN;
  BEGIN

    -- assign local signal to its output signal
    S_READY <= s_ready_i;
    M_VALID <= m_valid_i;

    -- Reset delay register
    PROCESS(ACLK) 
    BEGIN
      IF (ACLK'event AND ACLK = '1') THEN
        areset_d1 <= ARESET AFTER TFF;
      END IF;
    END PROCESS;

    -- Load storage1 with either slave side data or from storage2
    PROCESS(ACLK) 
    BEGIN
      IF (ACLK'event AND ACLK = '1') THEN
        IF (load_s1 = '1') THEN
          IF (load_s1_from_s2) THEN
            storage_data1 <= storage_data2 AFTER TFF;
          ELSE
            storage_data1 <= S_PAYLOAD_DATA AFTER TFF;
          END IF;
        END IF;
      END IF;
    END PROCESS;

    -- Load storage2 with slave side data
    PROCESS(ACLK) 
    BEGIN
      IF (ACLK'event AND ACLK = '1') THEN
        IF (load_s2 = '1') THEN
          storage_data2 <= S_PAYLOAD_DATA AFTER TFF;
        END IF;
      END IF;
    END PROCESS;

    M_PAYLOAD_DATA <= storage_data1;

    -- Always load s2 on a valid transaction even if it's unnecessary
    load_s2 <= S_VALID AND s_ready_i;

    -- Loading s1
    PROCESS(state,S_VALID,M_READY) 
    BEGIN
      IF ((state = ZERO AND S_VALID = '1') OR -- Load when empty on slave transaction
          -- Load when ONE if we both have read and write at the same time
          (state = ONE AND S_VALID = '1' AND M_READY = '1') OR
           -- Load when TWO and we have a transaction on Master side
          (state = TWO AND M_READY = '1')) THEN
        load_s1 <= '1';
      ELSE
        load_s1 <= '0';
      END IF;
    END PROCESS;

    load_s1_from_s2 <= (state = TWO);
                     
    -- State Machine for handling output signals
    PROCESS(ACLK) 
    BEGIN
      IF (ACLK'event AND ACLK = '1') THEN
        IF (ARESET = '1') THEN
          s_ready_i <= '0' AFTER TFF;
          state     <= ZERO AFTER TFF;
        ELSIF (areset_d1 = '1') THEN
          s_ready_i <= '1' AFTER TFF;
        ELSE
          CASE state IS
            WHEN ZERO => -- No transaction stored locally
              IF (S_VALID = '1') THEN -- Got one so move to ONE
                state <= ONE AFTER TFF;
              END IF;
            WHEN ONE  => -- One transaction stored locally
              IF (M_READY = '1' AND S_VALID = '0') THEN -- Read out one so move to ZERO
                state <= ZERO AFTER TFF;
              END IF;
              IF (M_READY = '0' AND S_VALID = '1') THEN -- Got another one so move to TWO
                state     <= TWO AFTER TFF;
                s_ready_i <= '0' AFTER TFF;
              END IF;
            WHEN TWO  => -- TWO transaction stored locally
              IF (M_READY = '1') THEN -- Read out one so move to ONE
                state     <= ONE AFTER TFF;
                s_ready_i <= '1' AFTER TFF;
              END IF;
            WHEN OTHERS  =>
              state <= state AFTER TFF;
          END CASE;
        END IF;
      END IF;
    END PROCESS;
    
    m_valid_i <= state(0);

  END GENERATE gfwd_rev;
  --------------------------------------------------------------------
  --
  -- C_REG_CONFIG = 1
  -- Light-weight mode.
  -- 1-stage pipeline register with bubble cycle, both FWD and REV pipelining
  -- Operates same as 1-deep FIFO
  --
  --------------------------------------------------------------------
  gfwd_rev_pipeline1: IF (C_REG_CONFIG = 1) GENERATE

      -- assign local signal to its output signal
      S_READY        <= s_ready_i;
      M_VALID        <= m_valid_i;

    -- Reset delay register
    PROCESS(ACLK) 
    BEGIN
      IF (ACLK'event AND ACLK = '1') THEN
        areset_d1 <= ARESET AFTER TFF;
      END IF;
    END PROCESS;

      -- Load storage1 with slave side data
    PROCESS(ACLK) 
    BEGIN
      IF (ACLK'event AND ACLK = '1') THEN
        IF (ARESET = '1') THEN
          s_ready_i <= '0' AFTER TFF;
          m_valid_i <= '0' AFTER TFF;
        ELSIF (areset_d1 = '1') THEN
          s_ready_i <= '1' AFTER TFF;
        ELSIF (m_valid_i = '1' AND M_READY = '1') THEN
          s_ready_i <= '1' AFTER TFF;
          m_valid_i <= '0' AFTER TFF;
        ELSIF (S_VALID = '1' AND s_ready_i = '1') THEN
          s_ready_i <= '0' AFTER TFF;
          m_valid_i <= '1' AFTER TFF;
        END IF;

        IF (m_valid_i = '0') THEN
          storage_data1 <= S_PAYLOAD_DATA AFTER TFF;        
        END IF;
      END IF;
    END PROCESS;
    M_PAYLOAD_DATA <= storage_data1;

  END GENERATE gfwd_rev_pipeline1;

end xilinx;-- reg_slice

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--  Top-level Behavioral Model for AXI
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_misc.ALL;
USE IEEE.std_logic_arith.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY fifo_generator_v13_0_0;
USE fifo_generator_v13_0_0.fifo_generator_v13_0_0_conv;


-------------------------------------------------------------------------------
-- Top-level Entity Declaration - This is the top-level of the AXI FIFO Bhv Model
-------------------------------------------------------------------------------
ENTITY fifo_generator_vhdl_beh IS
  GENERIC (
    -------------------------------------------------------------------------
    -- Generic Declarations
    -------------------------------------------------------------------------
    C_COMMON_CLOCK                          : integer := 0;
    C_COUNT_TYPE                            : integer := 0;
    C_DATA_COUNT_WIDTH                      : integer := 2;
    C_DEFAULT_VALUE                         : string  := "";
    C_DIN_WIDTH                             : integer := 8;
    C_DOUT_RST_VAL                          : string  := "";
    C_DOUT_WIDTH                            : integer := 8;
    C_ENABLE_RLOCS                          : integer := 0;
    C_FAMILY                                : string  := "virtex7";
    C_FULL_FLAGS_RST_VAL                    : integer := 1;
    C_HAS_ALMOST_EMPTY                      : integer := 0;
    C_HAS_ALMOST_FULL                       : integer := 0;
    C_HAS_BACKUP                            : integer := 0;
    C_HAS_DATA_COUNT                        : integer := 0;
    C_HAS_INT_CLK                           : integer := 0;
    C_HAS_MEMINIT_FILE                      : integer := 0;
    C_HAS_OVERFLOW                          : integer := 0;
    C_HAS_RD_DATA_COUNT                     : integer := 0;
    C_HAS_RD_RST                            : integer := 0;
    C_HAS_RST                               : integer := 1;
    C_HAS_SRST                              : integer := 0;
    C_HAS_UNDERFLOW                         : integer := 0;
    C_HAS_VALID                             : integer := 0;
    C_HAS_WR_ACK                            : integer := 0;
    C_HAS_WR_DATA_COUNT                     : integer := 0;
    C_HAS_WR_RST                            : integer := 0;
    C_IMPLEMENTATION_TYPE                   : integer := 0;
    C_INIT_WR_PNTR_VAL                      : integer := 0;
    C_MEMORY_TYPE                           : integer := 1;
    C_MIF_FILE_NAME                         : string  := "";
    C_OPTIMIZATION_MODE                     : integer := 0;
    C_OVERFLOW_LOW                          : integer := 0;
    C_PRELOAD_LATENCY                       : integer := 1;
    C_PRELOAD_REGS                          : integer := 0;
    C_PRIM_FIFO_TYPE                        : string  := "4kx4";
    C_PROG_EMPTY_THRESH_ASSERT_VAL          : integer := 0;
    C_PROG_EMPTY_THRESH_NEGATE_VAL          : integer := 0;
    C_PROG_EMPTY_TYPE                       : integer := 0;
    C_PROG_FULL_THRESH_ASSERT_VAL           : integer := 0;
    C_PROG_FULL_THRESH_NEGATE_VAL           : integer := 0;
    C_PROG_FULL_TYPE                        : integer := 0;
    C_RD_DATA_COUNT_WIDTH                   : integer := 2;
    C_RD_DEPTH                              : integer := 256;
    C_RD_FREQ                               : integer := 1;
    C_RD_PNTR_WIDTH                         : integer := 8;
    C_UNDERFLOW_LOW                         : integer := 0;
    C_USE_DOUT_RST                          : integer := 0;
    C_USE_ECC                               : integer := 0;
    C_USE_EMBEDDED_REG                      : integer := 0;
    C_USE_PIPELINE_REG                      : integer := 0;
    C_POWER_SAVING_MODE                     : integer := 0;
    C_USE_FIFO16_FLAGS                      : integer := 0;
    C_USE_FWFT_DATA_COUNT                   : integer := 0;
    C_VALID_LOW                             : integer := 0;
    C_WR_ACK_LOW                            : integer := 0;
    C_WR_DATA_COUNT_WIDTH                   : integer := 2;
    C_WR_DEPTH                              : integer := 256;
    C_WR_FREQ                               : integer := 1;
    C_WR_PNTR_WIDTH                         : integer := 8;
    C_WR_RESPONSE_LATENCY                   : integer := 1;
    C_MSGON_VAL                             : integer := 1;
    C_ENABLE_RST_SYNC                       : integer := 1;
    C_EN_SAFETY_CKT                         : integer := 0;
    C_ERROR_INJECTION_TYPE                  : integer := 0;
    C_SYNCHRONIZER_STAGE                    : integer := 2;

    -- AXI Interface related parameters start here
    C_INTERFACE_TYPE                        : integer := 0; -- 0: Native Interface; 1: AXI Interface
    C_AXI_TYPE                              : integer := 0; -- 0: AXI Stream; 1: AXI Full; 2: AXI Lite
    C_HAS_AXI_WR_CHANNEL                    : integer := 0;
    C_HAS_AXI_RD_CHANNEL                    : integer := 0;
    C_HAS_SLAVE_CE                          : integer := 0;
    C_HAS_MASTER_CE                         : integer := 0;
    C_ADD_NGC_CONSTRAINT                    : integer := 0;
    C_USE_COMMON_OVERFLOW                   : integer := 0;
    C_USE_COMMON_UNDERFLOW                  : integer := 0;
    C_USE_DEFAULT_SETTINGS                  : integer := 0;

    -- AXI Full/Lite
    C_AXI_ID_WIDTH                          : integer := 4;
    C_AXI_ADDR_WIDTH                        : integer := 32;
    C_AXI_DATA_WIDTH                        : integer := 64;
    C_AXI_LEN_WIDTH                         : integer := 8;
    C_AXI_LOCK_WIDTH                        : integer := 2;
    C_HAS_AXI_ID                            : integer := 0;
    C_HAS_AXI_AWUSER                        : integer := 0;
    C_HAS_AXI_WUSER                         : integer := 0;
    C_HAS_AXI_BUSER                         : integer := 0;
    C_HAS_AXI_ARUSER                        : integer := 0;
    C_HAS_AXI_RUSER                         : integer := 0;
    C_AXI_ARUSER_WIDTH                      : integer := 1;
    C_AXI_AWUSER_WIDTH                      : integer := 1;
    C_AXI_WUSER_WIDTH                       : integer := 1;
    C_AXI_BUSER_WIDTH                       : integer := 1;
    C_AXI_RUSER_WIDTH                       : integer := 1;
                                       
    -- AXI Streaming
    C_HAS_AXIS_TDATA                        : integer := 0;
    C_HAS_AXIS_TID                          : integer := 0;
    C_HAS_AXIS_TDEST                        : integer := 0;
    C_HAS_AXIS_TUSER                        : integer := 0;
    C_HAS_AXIS_TREADY                       : integer := 1;
    C_HAS_AXIS_TLAST                        : integer := 0;
    C_HAS_AXIS_TSTRB                        : integer := 0;
    C_HAS_AXIS_TKEEP                        : integer := 0;
    C_AXIS_TDATA_WIDTH                      : integer := 64;
    C_AXIS_TID_WIDTH                        : integer := 8;
    C_AXIS_TDEST_WIDTH                      : integer := 4;
    C_AXIS_TUSER_WIDTH                      : integer := 4;
    C_AXIS_TSTRB_WIDTH                      : integer := 4;
    C_AXIS_TKEEP_WIDTH                      : integer := 4;

    -- AXI Channel Type
    -- WACH --> Write Address Channel
    -- WDCH --> Write Data Channel
    -- WRCH --> Write Response Channel
    -- RACH --> Read Address Channel
    -- RDCH --> Read Data Channel
    -- AXIS --> AXI Streaming
    C_WACH_TYPE                             : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logic
    C_WDCH_TYPE                             : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie
    C_WRCH_TYPE                             : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie
    C_RACH_TYPE                             : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie
    C_RDCH_TYPE                             : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie
    C_AXIS_TYPE                             : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie

    -- AXI Implementation Type
    -- 1 = Common Clock Block RAM FIFO
    -- 2 = Common Clock Distributed RAM FIFO
    -- 5 = Common Clock Built-in FIFO
    -- 11 = Independent Clock Block RAM FIFO
    -- 12 = Independent Clock Distributed RAM FIFO
    C_IMPLEMENTATION_TYPE_WACH              : integer := 1;
    C_IMPLEMENTATION_TYPE_WDCH              : integer := 1;
    C_IMPLEMENTATION_TYPE_WRCH              : integer := 1;
    C_IMPLEMENTATION_TYPE_RACH              : integer := 1;
    C_IMPLEMENTATION_TYPE_RDCH              : integer := 1;
    C_IMPLEMENTATION_TYPE_AXIS              : integer := 1;

    -- AXI FIFO Type
    -- 0 = Data FIFO
    -- 1 = Packet FIFO
    -- 2 = Low Latency Sync FIFO
    -- 3 = Low Latency Async FIFO
    C_APPLICATION_TYPE_WACH                 : integer := 0;
    C_APPLICATION_TYPE_WDCH                 : integer := 0;
    C_APPLICATION_TYPE_WRCH                 : integer := 0;
    C_APPLICATION_TYPE_RACH                 : integer := 0;
    C_APPLICATION_TYPE_RDCH                 : integer := 0;
    C_APPLICATION_TYPE_AXIS                 : integer := 0;

    -- AXI Built-in FIFO Primitive Type
    -- 512x36, 1kx18, 2kx9, 4kx4, etc
    C_PRIM_FIFO_TYPE_WACH                   : string  := "512x36";
    C_PRIM_FIFO_TYPE_WDCH                   : string  := "512x36";
    C_PRIM_FIFO_TYPE_WRCH                   : string  := "512x36";
    C_PRIM_FIFO_TYPE_RACH                   : string  := "512x36";
    C_PRIM_FIFO_TYPE_RDCH                   : string  := "512x36";
    C_PRIM_FIFO_TYPE_AXIS                   : string  := "512x36";

    -- Enable ECC
    -- 0 = ECC disabled
    -- 1 = ECC enabled
    C_USE_ECC_WACH                          : integer := 0;
    C_USE_ECC_WDCH                          : integer := 0;
    C_USE_ECC_WRCH                          : integer := 0;
    C_USE_ECC_RACH                          : integer := 0;
    C_USE_ECC_RDCH                          : integer := 0;
    C_USE_ECC_AXIS                          : integer := 0;

    -- ECC Error Injection Type
    -- 0 = No Error Injection
    -- 1 = Single Bit Error Injection
    -- 2 = Double Bit Error Injection
    -- 3 = Single Bit and Double Bit Error Injection
    C_ERROR_INJECTION_TYPE_WACH             : integer := 0;
    C_ERROR_INJECTION_TYPE_WDCH             : integer := 0;
    C_ERROR_INJECTION_TYPE_WRCH             : integer := 0;
    C_ERROR_INJECTION_TYPE_RACH             : integer := 0;
    C_ERROR_INJECTION_TYPE_RDCH             : integer := 0;
    C_ERROR_INJECTION_TYPE_AXIS             : integer := 0;

    -- Input Data Width
    -- Accumulation of all AXI input signal's width
    C_DIN_WIDTH_WACH                        : integer := 32;
    C_DIN_WIDTH_WDCH                        : integer := 64;
    C_DIN_WIDTH_WRCH                        : integer := 2;
    C_DIN_WIDTH_RACH                        : integer := 32;
    C_DIN_WIDTH_RDCH                        : integer := 64;
    C_DIN_WIDTH_AXIS                        : integer := 1;

    C_WR_DEPTH_WACH                         : integer := 16;
    C_WR_DEPTH_WDCH                         : integer := 1024;
    C_WR_DEPTH_WRCH                         : integer := 16;
    C_WR_DEPTH_RACH                         : integer := 16;
    C_WR_DEPTH_RDCH                         : integer := 1024;
    C_WR_DEPTH_AXIS                         : integer := 1024;

    C_WR_PNTR_WIDTH_WACH                    : integer := 4;
    C_WR_PNTR_WIDTH_WDCH                    : integer := 10;
    C_WR_PNTR_WIDTH_WRCH                    : integer := 4;
    C_WR_PNTR_WIDTH_RACH                    : integer := 4;
    C_WR_PNTR_WIDTH_RDCH                    : integer := 10;
    C_WR_PNTR_WIDTH_AXIS                    : integer := 10;

    C_HAS_DATA_COUNTS_WACH                  : integer := 0;
    C_HAS_DATA_COUNTS_WDCH                  : integer := 0;
    C_HAS_DATA_COUNTS_WRCH                  : integer := 0;
    C_HAS_DATA_COUNTS_RACH                  : integer := 0;
    C_HAS_DATA_COUNTS_RDCH                  : integer := 0;
    C_HAS_DATA_COUNTS_AXIS                  : integer := 0;

    C_HAS_PROG_FLAGS_WACH                   : integer := 0;
    C_HAS_PROG_FLAGS_WDCH                   : integer := 0;
    C_HAS_PROG_FLAGS_WRCH                   : integer := 0;
    C_HAS_PROG_FLAGS_RACH                   : integer := 0;
    C_HAS_PROG_FLAGS_RDCH                   : integer := 0;
    C_HAS_PROG_FLAGS_AXIS                   : integer := 0;

    -- 0: No Programmable FULL
    -- 1: Single Programmable FULL Threshold Constant
    -- 3: Single Programmable FULL Threshold Input Port
    C_PROG_FULL_TYPE_WACH                   : integer := 5;
    C_PROG_FULL_TYPE_WDCH                   : integer := 5;
    C_PROG_FULL_TYPE_WRCH                   : integer := 5;
    C_PROG_FULL_TYPE_RACH                   : integer := 5;
    C_PROG_FULL_TYPE_RDCH                   : integer := 5;
    C_PROG_FULL_TYPE_AXIS                   : integer := 5;

    -- Single Programmable FULL Threshold Constant Assert Value
    C_PROG_FULL_THRESH_ASSERT_VAL_WACH      : integer := 1023;
    C_PROG_FULL_THRESH_ASSERT_VAL_WDCH      : integer := 1023;
    C_PROG_FULL_THRESH_ASSERT_VAL_WRCH      : integer := 1023;
    C_PROG_FULL_THRESH_ASSERT_VAL_RACH      : integer := 1023;
    C_PROG_FULL_THRESH_ASSERT_VAL_RDCH      : integer := 1023;
    C_PROG_FULL_THRESH_ASSERT_VAL_AXIS      : integer := 1023;

    -- 0: No Programmable EMPTY
    -- 1: Single Programmable EMPTY Threshold Constant
    -- 3: Single Programmable EMPTY Threshold Input Port
    C_PROG_EMPTY_TYPE_WACH                  : integer := 5;
    C_PROG_EMPTY_TYPE_WDCH                  : integer := 5;
    C_PROG_EMPTY_TYPE_WRCH                  : integer := 5;
    C_PROG_EMPTY_TYPE_RACH                  : integer := 5;
    C_PROG_EMPTY_TYPE_RDCH                  : integer := 5;
    C_PROG_EMPTY_TYPE_AXIS                  : integer := 5;

    -- Single Programmable EMPTY Threshold Constant Assert Value
    C_PROG_EMPTY_THRESH_ASSERT_VAL_WACH     : integer := 1022;
    C_PROG_EMPTY_THRESH_ASSERT_VAL_WDCH     : integer := 1022;
    C_PROG_EMPTY_THRESH_ASSERT_VAL_WRCH     : integer := 1022;
    C_PROG_EMPTY_THRESH_ASSERT_VAL_RACH     : integer := 1022;
    C_PROG_EMPTY_THRESH_ASSERT_VAL_RDCH     : integer := 1022;
    C_PROG_EMPTY_THRESH_ASSERT_VAL_AXIS     : integer := 1022;

    C_REG_SLICE_MODE_WACH                   : integer := 0;
    C_REG_SLICE_MODE_WDCH                   : integer := 0;
    C_REG_SLICE_MODE_WRCH                   : integer := 0;
    C_REG_SLICE_MODE_RACH                   : integer := 0;
    C_REG_SLICE_MODE_RDCH                   : integer := 0;
    C_REG_SLICE_MODE_AXIS                   : integer := 0
    );


  PORT(
    ------------------------------------------------------------------------------
    -- Input and Output Declarations
    ------------------------------------------------------------------------------

    -- Conventional FIFO Interface Signals
    BACKUP                         : IN  std_logic := '0';
    BACKUP_MARKER                  : IN  std_logic := '0';
    CLK                            : IN  std_logic := '0';
    RST                            : IN  std_logic := '0';
    SRST                           : IN  std_logic := '0';
    WR_CLK                         : IN  std_logic := '0';
    WR_RST                         : IN  std_logic := '0';
    RD_CLK                         : IN  std_logic := '0';
    RD_RST                         : IN  std_logic := '0';
    DIN                            : IN  std_logic_vector(C_DIN_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    WR_EN                          : IN  std_logic := '0';
    RD_EN                          : IN  std_logic := '0';

    -- Optional inputs
    PROG_EMPTY_THRESH              : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_EMPTY_THRESH_ASSERT       : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_EMPTY_THRESH_NEGATE       : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_FULL_THRESH               : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_FULL_THRESH_ASSERT        : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_FULL_THRESH_NEGATE        : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    INT_CLK                        : IN  std_logic := '0';
    INJECTDBITERR                  : IN  std_logic := '0';
    INJECTSBITERR                  : IN  std_logic := '0';
    SLEEP                          : IN  std_logic := '0';

    DOUT                           : OUT std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    FULL                           : OUT std_logic := '0';
    ALMOST_FULL                    : OUT std_logic := '0';
    WR_ACK                         : OUT std_logic := '0';
    OVERFLOW                       : OUT std_logic := '0';
    EMPTY                          : OUT std_logic := '1';
    ALMOST_EMPTY                   : OUT std_logic := '1';
    VALID                          : OUT std_logic := '0';
    UNDERFLOW                      : OUT std_logic := '0';
    DATA_COUNT                     : OUT std_logic_vector(C_DATA_COUNT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    RD_DATA_COUNT                  : OUT std_logic_vector(C_RD_DATA_COUNT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    WR_DATA_COUNT                  : OUT std_logic_vector(C_WR_DATA_COUNT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    PROG_FULL                      : OUT std_logic := '0';
    PROG_EMPTY                     : OUT std_logic := '1';
    SBITERR                        : OUT std_logic := '0';
    DBITERR                        : OUT std_logic := '0';
    WR_RST_BUSY                    : OUT std_logic := '0';
    RD_RST_BUSY                    : OUT std_logic := '0';

    -- AXI Global Signal
    M_ACLK                         : IN  std_logic := '0';
    S_ACLK                         : IN  std_logic := '0';
    S_ARESETN                      : IN  std_logic := '1'; -- Active low reset, default value set to 1
    M_ACLK_EN                      : IN  std_logic := '0';
    S_ACLK_EN                      : IN  std_logic := '0';

    -- AXI Full/Lite Slave Write Channel (write side)
    S_AXI_AWID                     : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWADDR                   : IN  std_logic_vector(C_AXI_ADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWLEN                    : IN  std_logic_vector(C_AXI_LEN_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWSIZE                   : IN  std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWBURST                  : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWLOCK                   : IN  std_logic_vector(C_AXI_LOCK_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWCACHE                  : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWPROT                   : IN  std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWQOS                    : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWREGION                 : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWUSER                   : IN  std_logic_vector(C_AXI_AWUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWVALID                  : IN  std_logic := '0';
    S_AXI_AWREADY                  : OUT std_logic := '0';
    S_AXI_WID                      : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0)     := (OTHERS => '0');
    S_AXI_WDATA                    : IN  std_logic_vector(C_AXI_DATA_WIDTH-1 DOWNTO 0)   := (OTHERS => '0');
    S_AXI_WSTRB                    : IN  std_logic_vector(C_AXI_DATA_WIDTH/8-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_WLAST                    : IN  std_logic := '0';
    S_AXI_WUSER                    : IN  std_logic_vector(C_AXI_WUSER_WIDTH-1 DOWNTO 0)  := (OTHERS => '0');
    S_AXI_WVALID                   : IN  std_logic := '0';
    S_AXI_WREADY                   : OUT std_logic := '0';
    S_AXI_BID                      : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0)     := (OTHERS => '0');
    S_AXI_BRESP                    : OUT std_logic_vector(2-1 DOWNTO 0)                  := (OTHERS => '0');
    S_AXI_BUSER                    : OUT std_logic_vector(C_AXI_BUSER_WIDTH-1 DOWNTO 0)  := (OTHERS => '0');
    S_AXI_BVALID                   : OUT std_logic := '0';
    S_AXI_BREADY                   : IN  std_logic := '0';

    -- AXI Full/Lite Master Write Channel (Read side)
    M_AXI_AWID                     : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0)   := (OTHERS => '0');
    M_AXI_AWADDR                   : OUT std_logic_vector(C_AXI_ADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_AWLEN                    : OUT std_logic_vector(C_AXI_LEN_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_AWSIZE                   : OUT std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_AWBURST                  : OUT std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_AWLOCK                   : OUT std_logic_vector(C_AXI_LOCK_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_AWCACHE                  : OUT std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_AWPROT                   : OUT std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_AWQOS                    : OUT std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_AWREGION                 : OUT std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_AWUSER                   : OUT std_logic_vector(C_AXI_AWUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_AWVALID                  : OUT std_logic := '0';
    M_AXI_AWREADY                  : IN  std_logic := '0';
    M_AXI_WID                      : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0)     := (OTHERS => '0');
    M_AXI_WDATA                    : OUT std_logic_vector(C_AXI_DATA_WIDTH-1 DOWNTO 0)   := (OTHERS => '0');
    M_AXI_WSTRB                    : OUT std_logic_vector(C_AXI_DATA_WIDTH/8-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_WLAST                    : OUT std_logic := '0';
    M_AXI_WUSER                    : OUT std_logic_vector(C_AXI_WUSER_WIDTH-1 DOWNTO 0)  := (OTHERS => '0');
    M_AXI_WVALID                   : OUT std_logic := '0';
    M_AXI_WREADY                   : IN  std_logic := '0';
    M_AXI_BID                      : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0)    := (OTHERS => '0');
    M_AXI_BRESP                    : IN  std_logic_vector(2-1 DOWNTO 0)                 := (OTHERS => '0');
    M_AXI_BUSER                    : IN  std_logic_vector(C_AXI_BUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_BVALID                   : IN  std_logic := '0';
    M_AXI_BREADY                   : OUT std_logic := '0';

    -- AXI Full/Lite Slave Read Channel (Write side)
    S_AXI_ARID                     : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0)   := (OTHERS => '0');
    S_AXI_ARADDR                   : IN  std_logic_vector(C_AXI_ADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0'); 
    S_AXI_ARLEN                    : IN  std_logic_vector(C_AXI_LEN_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_ARSIZE                   : IN  std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_ARBURST                  : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_ARLOCK                   : IN  std_logic_vector(C_AXI_LOCK_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_ARCACHE                  : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_ARPROT                   : IN  std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_ARQOS                    : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_ARREGION                 : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_ARUSER                   : IN  std_logic_vector(C_AXI_ARUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_ARVALID                  : IN  std_logic := '0';
    S_AXI_ARREADY                  : OUT std_logic := '0';
    S_AXI_RID                      : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0)   := (OTHERS => '0');       
    S_AXI_RDATA                    : OUT std_logic_vector(C_AXI_DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0'); 
    S_AXI_RRESP                    : OUT std_logic_vector(2-1 DOWNTO 0)                := (OTHERS => '0');
    S_AXI_RLAST                    : OUT std_logic := '0';
    S_AXI_RUSER                    : OUT std_logic_vector(C_AXI_RUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_RVALID                   : OUT std_logic := '0';
    S_AXI_RREADY                   : IN  std_logic := '0';

    -- AXI Full/Lite Master Read Channel (Read side)
    M_AXI_ARID                     : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0)   := (OTHERS => '0');        
    M_AXI_ARADDR                   : OUT std_logic_vector(C_AXI_ADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');  
    M_AXI_ARLEN                    : OUT std_logic_vector(C_AXI_LEN_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_ARSIZE                   : OUT std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_ARBURST                  : OUT std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_ARLOCK                   : OUT std_logic_vector(C_AXI_LOCK_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_ARCACHE                  : OUT std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_ARPROT                   : OUT std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_ARQOS                    : OUT std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_ARREGION                 : OUT std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_ARUSER                   : OUT std_logic_vector(C_AXI_ARUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_ARVALID                  : OUT std_logic := '0';
    M_AXI_ARREADY                  : IN  std_logic := '0';
    M_AXI_RID                      : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');        
    M_AXI_RDATA                    : IN  std_logic_vector(C_AXI_DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');  
    M_AXI_RRESP                    : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_RLAST                    : IN  std_logic := '0';
    M_AXI_RUSER                    : IN  std_logic_vector(C_AXI_RUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXI_RVALID                   : IN  std_logic := '0';
    M_AXI_RREADY                   : OUT std_logic := '0';

    -- AXI Streaming Slave Signals (Write side)
    S_AXIS_TVALID                  : IN  std_logic := '0';
    S_AXIS_TREADY                  : OUT std_logic := '0';
    S_AXIS_TDATA                   : IN  std_logic_vector(C_AXIS_TDATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXIS_TSTRB                   : IN  std_logic_vector(C_AXIS_TSTRB_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXIS_TKEEP                   : IN  std_logic_vector(C_AXIS_TKEEP_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXIS_TLAST                   : IN  std_logic := '0';
    S_AXIS_TID                     : IN  std_logic_vector(C_AXIS_TID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXIS_TDEST                   : IN  std_logic_vector(C_AXIS_TDEST_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    S_AXIS_TUSER                   : IN  std_logic_vector(C_AXIS_TUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

    -- AXI Streaming Master Signals (Read side)
    M_AXIS_TVALID                  : OUT std_logic := '0';
    M_AXIS_TREADY                  : IN  std_logic := '0';
    M_AXIS_TDATA                   : OUT std_logic_vector(C_AXIS_TDATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXIS_TSTRB                   : OUT std_logic_vector(C_AXIS_TSTRB_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXIS_TKEEP                   : OUT std_logic_vector(C_AXIS_TKEEP_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXIS_TLAST                   : OUT std_logic := '0';
    M_AXIS_TID                     : OUT std_logic_vector(C_AXIS_TID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXIS_TDEST                   : OUT std_logic_vector(C_AXIS_TDEST_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    M_AXIS_TUSER                   : OUT std_logic_vector(C_AXIS_TUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

    -- AXI Full/Lite Write Address Channel Signals
    AXI_AW_INJECTSBITERR           : IN  std_logic := '0';
    AXI_AW_INJECTDBITERR           : IN  std_logic := '0';
    AXI_AW_PROG_FULL_THRESH        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WACH-1 DOWNTO 0) := (OTHERS => '0');
    AXI_AW_PROG_EMPTY_THRESH       : IN  std_logic_vector(C_WR_PNTR_WIDTH_WACH-1 DOWNTO 0) := (OTHERS => '0');
    AXI_AW_DATA_COUNT              : OUT std_logic_vector(C_WR_PNTR_WIDTH_WACH DOWNTO 0) := (OTHERS => '0');
    AXI_AW_WR_DATA_COUNT           : OUT std_logic_vector(C_WR_PNTR_WIDTH_WACH DOWNTO 0) := (OTHERS => '0');
    AXI_AW_RD_DATA_COUNT           : OUT std_logic_vector(C_WR_PNTR_WIDTH_WACH DOWNTO 0) := (OTHERS => '0');
    AXI_AW_SBITERR                 : OUT std_logic := '0';
    AXI_AW_DBITERR                 : OUT std_logic := '0';
    AXI_AW_OVERFLOW                : OUT std_logic := '0';
    AXI_AW_UNDERFLOW               : OUT std_logic := '0';
    AXI_AW_PROG_FULL               : OUT STD_LOGIC := '0';
    AXI_AW_PROG_EMPTY              : OUT STD_LOGIC := '1';

    -- AXI Full/Lite Write Data Channel Signals
    AXI_W_INJECTSBITERR            : IN  std_logic := '0';
    AXI_W_INJECTDBITERR            : IN  std_logic := '0';
    AXI_W_PROG_FULL_THRESH         : IN  std_logic_vector(C_WR_PNTR_WIDTH_WDCH-1 DOWNTO 0) := (OTHERS => '0');
    AXI_W_PROG_EMPTY_THRESH        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WDCH-1 DOWNTO 0) := (OTHERS => '0');
    AXI_W_DATA_COUNT               : OUT std_logic_vector(C_WR_PNTR_WIDTH_WDCH DOWNTO 0) := (OTHERS => '0');
    AXI_W_WR_DATA_COUNT            : OUT std_logic_vector(C_WR_PNTR_WIDTH_WDCH DOWNTO 0) := (OTHERS => '0');
    AXI_W_RD_DATA_COUNT            : OUT std_logic_vector(C_WR_PNTR_WIDTH_WDCH DOWNTO 0) := (OTHERS => '0');
    AXI_W_SBITERR                  : OUT std_logic := '0';
    AXI_W_DBITERR                  : OUT std_logic := '0';
    AXI_W_OVERFLOW                 : OUT std_logic := '0';
    AXI_W_UNDERFLOW                : OUT std_logic := '0';
    AXI_W_PROG_FULL                : OUT STD_LOGIC := '0';
    AXI_W_PROG_EMPTY               : OUT STD_LOGIC := '1';

    -- AXI Full/Lite Write Response Channel Signals
    AXI_B_INJECTSBITERR            : IN  std_logic := '0';
    AXI_B_INJECTDBITERR            : IN  std_logic := '0';
    AXI_B_PROG_FULL_THRESH         : IN  std_logic_vector(C_WR_PNTR_WIDTH_WRCH-1 DOWNTO 0) := (OTHERS => '0');
    AXI_B_PROG_EMPTY_THRESH        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WRCH-1 DOWNTO 0) := (OTHERS => '0');
    AXI_B_DATA_COUNT               : OUT std_logic_vector(C_WR_PNTR_WIDTH_WRCH DOWNTO 0) := (OTHERS => '0');
    AXI_B_WR_DATA_COUNT            : OUT std_logic_vector(C_WR_PNTR_WIDTH_WRCH DOWNTO 0) := (OTHERS => '0');
    AXI_B_RD_DATA_COUNT            : OUT std_logic_vector(C_WR_PNTR_WIDTH_WRCH DOWNTO 0) := (OTHERS => '0');
    AXI_B_SBITERR                  : OUT std_logic := '0';
    AXI_B_DBITERR                  : OUT std_logic := '0';
    AXI_B_OVERFLOW                 : OUT std_logic := '0';
    AXI_B_UNDERFLOW                : OUT std_logic := '0';
    AXI_B_PROG_FULL                : OUT STD_LOGIC := '0';
    AXI_B_PROG_EMPTY               : OUT STD_LOGIC := '1';

    -- AXI Full/Lite Read Address Channel Signals
    AXI_AR_INJECTSBITERR           : IN  std_logic := '0';
    AXI_AR_INJECTDBITERR           : IN  std_logic := '0';
    AXI_AR_PROG_FULL_THRESH        : IN  std_logic_vector(C_WR_PNTR_WIDTH_RACH-1 DOWNTO 0) := (OTHERS => '0');
    AXI_AR_PROG_EMPTY_THRESH       : IN  std_logic_vector(C_WR_PNTR_WIDTH_RACH-1 DOWNTO 0) := (OTHERS => '0');
    AXI_AR_DATA_COUNT              : OUT std_logic_vector(C_WR_PNTR_WIDTH_RACH DOWNTO 0) := (OTHERS => '0');
    AXI_AR_WR_DATA_COUNT           : OUT std_logic_vector(C_WR_PNTR_WIDTH_RACH DOWNTO 0) := (OTHERS => '0');
    AXI_AR_RD_DATA_COUNT           : OUT std_logic_vector(C_WR_PNTR_WIDTH_RACH DOWNTO 0) := (OTHERS => '0');
    AXI_AR_SBITERR                 : OUT std_logic := '0';
    AXI_AR_DBITERR                 : OUT std_logic := '0';
    AXI_AR_OVERFLOW                : OUT std_logic := '0';
    AXI_AR_UNDERFLOW               : OUT std_logic := '0';
    AXI_AR_PROG_FULL               : OUT STD_LOGIC := '0';
    AXI_AR_PROG_EMPTY              : OUT STD_LOGIC := '1';

    -- AXI Full/Lite Read Data Channel Signals
    AXI_R_INJECTSBITERR            : IN  std_logic := '0';
    AXI_R_INJECTDBITERR            : IN  std_logic := '0';
    AXI_R_PROG_FULL_THRESH         : IN  std_logic_vector(C_WR_PNTR_WIDTH_RDCH-1 DOWNTO 0) := (OTHERS => '0');
    AXI_R_PROG_EMPTY_THRESH        : IN  std_logic_vector(C_WR_PNTR_WIDTH_RDCH-1 DOWNTO 0) := (OTHERS => '0');
    AXI_R_DATA_COUNT               : OUT std_logic_vector(C_WR_PNTR_WIDTH_RDCH DOWNTO 0) := (OTHERS => '0');
    AXI_R_WR_DATA_COUNT            : OUT std_logic_vector(C_WR_PNTR_WIDTH_RDCH DOWNTO 0) := (OTHERS => '0');
    AXI_R_RD_DATA_COUNT            : OUT std_logic_vector(C_WR_PNTR_WIDTH_RDCH DOWNTO 0) := (OTHERS => '0');
    AXI_R_SBITERR                  : OUT std_logic := '0';
    AXI_R_DBITERR                  : OUT std_logic := '0';
    AXI_R_OVERFLOW                 : OUT std_logic := '0';
    AXI_R_UNDERFLOW                : OUT std_logic := '0';
    AXI_R_PROG_FULL                : OUT STD_LOGIC := '0';
    AXI_R_PROG_EMPTY               : OUT STD_LOGIC := '1';

    -- AXI Streaming FIFO Related Signals
    AXIS_INJECTSBITERR             : IN  std_logic := '0';
    AXIS_INJECTDBITERR             : IN  std_logic := '0';
    AXIS_PROG_FULL_THRESH          : IN  std_logic_vector(C_WR_PNTR_WIDTH_AXIS-1 DOWNTO 0) := (OTHERS => '0');
    AXIS_PROG_EMPTY_THRESH         : IN  std_logic_vector(C_WR_PNTR_WIDTH_AXIS-1 DOWNTO 0) := (OTHERS => '0');
    AXIS_DATA_COUNT                : OUT std_logic_vector(C_WR_PNTR_WIDTH_AXIS DOWNTO 0) := (OTHERS => '0');
    AXIS_WR_DATA_COUNT             : OUT std_logic_vector(C_WR_PNTR_WIDTH_AXIS DOWNTO 0) := (OTHERS => '0');
    AXIS_RD_DATA_COUNT             : OUT std_logic_vector(C_WR_PNTR_WIDTH_AXIS DOWNTO 0) := (OTHERS => '0');
    AXIS_SBITERR                   : OUT std_logic := '0';
    AXIS_DBITERR                   : OUT std_logic := '0';
    AXIS_OVERFLOW                  : OUT std_logic := '0';
    AXIS_UNDERFLOW                 : OUT std_logic := '0';
    AXIS_PROG_FULL                 : OUT STD_LOGIC := '0';
    AXIS_PROG_EMPTY                : OUT STD_LOGIC := '1'

    );
END fifo_generator_vhdl_beh;


ARCHITECTURE behavioral OF fifo_generator_vhdl_beh IS

   COMPONENT fifo_generator_v13_0_0_conv IS
     GENERIC (
       ---------------------------------------------------------------------------
       -- Generic Declarations
       ---------------------------------------------------------------------------
       C_COMMON_CLOCK                : integer := 0;
       C_COUNT_TYPE                  : integer := 0;  --not used
       C_DATA_COUNT_WIDTH            : integer := 2;
       C_DEFAULT_VALUE               : string  := "";  --not used
       C_DIN_WIDTH                   : integer := 8;
       C_DOUT_RST_VAL                : string  := "";
       C_DOUT_WIDTH                  : integer := 8;
       C_ENABLE_RLOCS                : integer := 0;  --not used
       C_FAMILY                      : string  := "";  --not used in bhv model
       C_FULL_FLAGS_RST_VAL          : integer := 0;
       C_HAS_ALMOST_EMPTY            : integer := 0;
       C_HAS_ALMOST_FULL             : integer := 0;
       C_HAS_BACKUP                  : integer := 0;  --not used
       C_HAS_DATA_COUNT              : integer := 0;
       C_HAS_INT_CLK                 : integer := 0;  --not used in bhv model
       C_HAS_MEMINIT_FILE            : integer := 0;  --not used
       C_HAS_OVERFLOW                : integer := 0;
       C_HAS_RD_DATA_COUNT           : integer := 0;
       C_HAS_RD_RST                  : integer := 0;  --not used
       C_HAS_RST                     : integer := 1;
       C_HAS_SRST                    : integer := 0;
       C_HAS_UNDERFLOW               : integer := 0;
       C_HAS_VALID                   : integer := 0;
       C_HAS_WR_ACK                  : integer := 0;
       C_HAS_WR_DATA_COUNT           : integer := 0;
       C_HAS_WR_RST                  : integer := 0;  --not used
       C_IMPLEMENTATION_TYPE         : integer := 0;
       C_INIT_WR_PNTR_VAL            : integer := 0;  --not used
       C_MEMORY_TYPE                 : integer := 1;
       C_MIF_FILE_NAME               : string  := "";  --not used
       C_OPTIMIZATION_MODE           : integer := 0;  --not used
       C_OVERFLOW_LOW                : integer := 0;
       C_PRELOAD_LATENCY             : integer := 1;
       C_PRELOAD_REGS                : integer := 0;
       C_PRIM_FIFO_TYPE              : string  := "4kx4";  --not used in bhv model
       C_PROG_EMPTY_THRESH_ASSERT_VAL: integer := 0;
       C_PROG_EMPTY_THRESH_NEGATE_VAL: integer := 0;
       C_PROG_EMPTY_TYPE             : integer := 0;
       C_PROG_FULL_THRESH_ASSERT_VAL : integer := 0;
       C_PROG_FULL_THRESH_NEGATE_VAL : integer := 0;
       C_PROG_FULL_TYPE              : integer := 0;
       C_RD_DATA_COUNT_WIDTH         : integer := 2;
       C_RD_DEPTH                    : integer := 256;
       C_RD_FREQ                     : integer := 1;  --not used in bhv model
       C_RD_PNTR_WIDTH               : integer := 8;
       C_UNDERFLOW_LOW               : integer := 0;
       C_USE_DOUT_RST                : integer := 0;
       C_USE_ECC                     : integer := 0;
       C_USE_EMBEDDED_REG            : integer := 0;
       C_USE_FIFO16_FLAGS            : integer := 0;  --not used in bhv model
       C_USE_FWFT_DATA_COUNT         : integer := 0;
       C_VALID_LOW                   : integer := 0;
       C_WR_ACK_LOW                  : integer := 0;
       C_WR_DATA_COUNT_WIDTH         : integer := 2;
       C_WR_DEPTH                    : integer := 256;
       C_WR_FREQ                     : integer := 1;  --not used in bhv model
       C_WR_PNTR_WIDTH               : integer := 8;
       C_WR_RESPONSE_LATENCY         : integer := 1;  --not used
       C_MSGON_VAL                   : integer := 1;  --not used in bhv model 
       C_ENABLE_RST_SYNC             : integer := 1;
       C_EN_SAFETY_CKT               : integer := 0;
       C_ERROR_INJECTION_TYPE        : integer := 0;
       C_FIFO_TYPE                   : integer := 0;
       C_SYNCHRONIZER_STAGE          : integer := 2;
       C_AXI_TYPE                    : integer := 0
       );
     PORT(
   --------------------------------------------------------------------------------
   -- Input and Output Declarations
   --------------------------------------------------------------------------------
       BACKUP                    : IN  std_logic := '0';
       BACKUP_MARKER             : IN  std_logic := '0';
       CLK                       : IN  std_logic := '0';
       RST                       : IN  std_logic := '0';
       SRST                      : IN  std_logic := '0';
       WR_CLK                    : IN  std_logic := '0';
       WR_RST                    : IN  std_logic := '0';
       RD_CLK                    : IN  std_logic := '0';
       RD_RST                    : IN  std_logic := '0';
       DIN                       : IN  std_logic_vector(C_DIN_WIDTH-1 DOWNTO 0); --
       WR_EN                     : IN  std_logic;  --Mandatory input
       RD_EN                     : IN  std_logic;  --Mandatory input
       --Mandatory input
       PROG_EMPTY_THRESH         : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
       PROG_EMPTY_THRESH_ASSERT  : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
       PROG_EMPTY_THRESH_NEGATE  : IN  std_logic_vector(C_RD_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
       PROG_FULL_THRESH          : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
       PROG_FULL_THRESH_ASSERT   : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
       PROG_FULL_THRESH_NEGATE   : IN  std_logic_vector(C_WR_PNTR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
       INT_CLK                   : IN  std_logic := '0';
       INJECTDBITERR             : IN  std_logic := '0';
       INJECTSBITERR             : IN  std_logic := '0';
   
       DOUT                      : OUT std_logic_vector(C_DOUT_WIDTH-1 DOWNTO 0);
       FULL                      : OUT std_logic;
       ALMOST_FULL               : OUT std_logic;
       WR_ACK                    : OUT std_logic;
       OVERFLOW                  : OUT std_logic;
       EMPTY                     : OUT std_logic;
       ALMOST_EMPTY              : OUT std_logic;
       VALID                     : OUT std_logic;
       UNDERFLOW                 : OUT std_logic;
       DATA_COUNT                : OUT std_logic_vector(C_DATA_COUNT_WIDTH-1 DOWNTO 0);
       RD_DATA_COUNT             : OUT std_logic_vector(C_RD_DATA_COUNT_WIDTH-1 DOWNTO 0);
       WR_DATA_COUNT             : OUT std_logic_vector(C_WR_DATA_COUNT_WIDTH-1 DOWNTO 0);
       PROG_FULL                 : OUT std_logic;
       PROG_EMPTY                : OUT std_logic;
       SBITERR                   : OUT std_logic := '0';
       DBITERR                   : OUT std_logic := '0';
       WR_RST_BUSY               : OUT std_logic := '0';
       RD_RST_BUSY               : OUT std_logic := '0';
       WR_RST_I_OUT                  : OUT std_logic := '0';
       RD_RST_I_OUT                  : OUT std_logic := '0'

       );

   END COMPONENT;

   COMPONENT fifo_generator_v13_0_0_axic_reg_slice IS
     GENERIC (
       C_FAMILY         : string  := "";
       C_DATA_WIDTH     : integer := 32;
       C_REG_CONFIG     : integer := 0
      );
     PORT (
      -- System Signals
      ACLK              : IN  STD_LOGIC;
      ARESET            : IN  STD_LOGIC;

      -- Slave side
      S_PAYLOAD_DATA    : IN  STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
      S_VALID           : IN  STD_LOGIC;
      S_READY           : OUT STD_LOGIC := '0';

      -- Master side
      M_PAYLOAD_DATA    : OUT STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
      M_VALID           : OUT STD_LOGIC := '0';
      M_READY           : IN  STD_LOGIC
      );

   END COMPONENT;

--  CONSTANT C_AXI_LEN_WIDTH    : integer := 8;
  CONSTANT C_AXI_SIZE_WIDTH   : integer := 3;
  CONSTANT C_AXI_BURST_WIDTH  : integer := 2;
--  CONSTANT C_AXI_LOCK_WIDTH   : integer := 2;
  CONSTANT C_AXI_CACHE_WIDTH  : integer := 4;
  CONSTANT C_AXI_PROT_WIDTH   : integer := 3;
  CONSTANT C_AXI_QOS_WIDTH    : integer := 4;
  CONSTANT C_AXI_REGION_WIDTH : integer := 4;
  CONSTANT C_AXI_BRESP_WIDTH  : integer := 2;
  CONSTANT C_AXI_RRESP_WIDTH  : integer := 2;
  CONSTANT TFF   : time := 100 ps;

  -----------------------------------------------------------------------------
  -- FUNCTION if_then_else
  -- Returns a true case or flase case based on the condition
  -------------------------------------------------------------------------------

  FUNCTION if_then_else (
    condition : boolean; 
    true_case : integer; 
    false_case : integer) 
  RETURN integer IS
    VARIABLE retval : integer := 0;
  BEGIN
    IF NOT condition THEN
      retval:=false_case;
    ELSE
      retval:=true_case;
    END IF;
    RETURN retval;
  END if_then_else;


   ------------------------------------------------------------------------------
    -- This function is used to implement an IF..THEN when such a statement is not
    --  allowed and returns string. 
    ------------------------------------------------------------------------------
    FUNCTION if_then_else (
      condition : boolean; 
      true_case : string;
      false_case : string) 
    RETURN string IS
    BEGIN
      IF NOT condition THEN
        RETURN false_case;
      ELSE
        RETURN true_case;
      END IF;
    END if_then_else;

        ---------------------------------------------------------------------------
    -- FUNCTION : log2roundup
    ---------------------------------------------------------------------------
    FUNCTION log2roundup (
        data_value : integer)
    	RETURN integer IS
    	
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

    -----------------------------------------------------------------------------
    -- FUNCTION : bin2gray
    -----------------------------------------------------------------------------
    -- This function receives a binary value, and returns the associated 
    -- graycoded value. 
  
    FUNCTION bin2gray (
      indata : std_logic_vector; 
      length : integer)
    RETURN std_logic_vector IS
      VARIABLE tmp_value : std_logic_vector(length-1 DOWNTO 0);
    BEGIN
      tmp_value(length-1) := indata(length-1);
  
      gray_loop : FOR I IN length-2 DOWNTO 0 LOOP
        tmp_value(I) := indata(I) XOR indata(I+1);
      END LOOP;
  
      RETURN tmp_value;
    END bin2gray;
  
    -----------------------------------------------------------------------------
    -- FUNCTION : gray2bin
    -----------------------------------------------------------------------------
    -- This function receives a gray-coded value, and returns the associated 
    -- binary value.
  
    FUNCTION gray2bin (
      indata : std_logic_vector; 
      length : integer)
    RETURN std_logic_vector IS
      VARIABLE tmp_value : std_logic_vector(length-1 DOWNTO 0);
    BEGIN
      tmp_value(length-1) := indata(length-1);
  
      gray_loop : FOR I IN length-2 DOWNTO 0 LOOP
        tmp_value(I) := XOR_REDUCE(indata(length-1 DOWNTO I));
      END LOOP;
  
      RETURN tmp_value;
    END gray2bin;



  --------------------------------------------------------
  -- FUNCION : map_ready_valid
  -- Returns the READY signal that is mapped out of FULL or ALMOST_FULL or PROG_FULL
  -- Returns the VALID signal that is mapped out of EMPTY or ALMOST_EMPTY or PROG_EMPTY
  --------------------------------------------------------

  FUNCTION map_ready_valid(
    pf_pe_type : integer; 
    full_empty : std_logic; 
    af_ae      : std_logic; 
    pf_pe      : std_logic) 
    RETURN std_logic IS
  BEGIN
    IF (pf_pe_type = 5) THEN
      RETURN NOT full_empty;
    ELSIF (pf_pe_type = 6) THEN
      RETURN NOT af_ae;
    ELSE
      RETURN NOT pf_pe;
    END IF;
  END map_ready_valid;
  SIGNAL inverted_reset : std_logic := '0';
  SIGNAL axi_rs_rst     : std_logic := '0';
  CONSTANT IS_V8    : INTEGER := if_then_else((C_FAMILY = "virtexu"),1,0);
  CONSTANT IS_K8    : INTEGER := if_then_else((C_FAMILY = "kintexu"),1,0);
  CONSTANT IS_A8    : INTEGER := if_then_else((C_FAMILY = "artixu"),1,0);
  CONSTANT IS_VM    : INTEGER := if_then_else((C_FAMILY = "virtexuplus"),1,0);
  CONSTANT IS_KM    : INTEGER := if_then_else((C_FAMILY = "kintexuplus"),1,0);
  CONSTANT IS_ZNQU  : INTEGER := if_then_else((C_FAMILY = "zynquplus"),1,0);
  CONSTANT IS_8SERIES  : INTEGER := if_then_else((IS_V8 = 1 OR IS_K8 = 1 OR IS_A8 = 1 OR IS_VM = 1 OR IS_ZNQU = 1 OR IS_KM = 1),1,0);

BEGIN

  inverted_reset <= NOT S_ARESETN;  

  gaxi_rs_rst: IF (C_INTERFACE_TYPE > 0 AND (C_AXIS_TYPE = 1 OR C_WACH_TYPE = 1 OR
                   C_WDCH_TYPE = 1 OR C_WRCH_TYPE = 1 OR C_RACH_TYPE = 1 OR C_RDCH_TYPE = 1)) GENERATE

      SIGNAL rst_d1 : STD_LOGIC := '1';
      SIGNAL rst_d2 : STD_LOGIC := '1';
    BEGIN
      prst: PROCESS (inverted_reset, S_ACLK)
      BEGIN
        IF (inverted_reset = '1') THEN
          rst_d1         <= '1';
          rst_d2         <= '1';
        ELSIF (S_ACLK'event AND S_ACLK = '1') THEN
          rst_d1         <= '0' AFTER TFF;
          rst_d2         <= rst_d1 AFTER TFF;
        END IF;
      END PROCESS prst;
  
      axi_rs_rst <= rst_d2;

  END GENERATE gaxi_rs_rst;

  ---------------------------------------------------------------------------
  -- Top level instance for Conventional FIFO.
  ---------------------------------------------------------------------------
  gconvfifo: IF (C_INTERFACE_TYPE = 0) GENERATE
   SIGNAL wr_data_count_in   : std_logic_vector (C_WR_DATA_COUNT_WIDTH-1 DOWNTO 0)
                            := (OTHERS => '0');
   signal full_i : std_logic := '0';		       
   signal empty_i : std_logic := '0';		       
   signal WR_RST_INT : std_logic := '0';		       
   signal RD_RST_INT : std_logic := '0';		       
  begin


    inst_conv_fifo: fifo_generator_v13_0_0_conv
      GENERIC map(
        C_COMMON_CLOCK                 => C_COMMON_CLOCK,
        C_COUNT_TYPE                   => C_COUNT_TYPE,
        C_DATA_COUNT_WIDTH             => C_DATA_COUNT_WIDTH,
        C_DEFAULT_VALUE                => C_DEFAULT_VALUE,
        C_DIN_WIDTH                    => C_DIN_WIDTH,
        C_DOUT_RST_VAL                 => if_then_else(C_USE_DOUT_RST = 1, C_DOUT_RST_VAL, "0"),
        C_DOUT_WIDTH                   => C_DOUT_WIDTH,
        C_ENABLE_RLOCS                 => C_ENABLE_RLOCS,
        C_FAMILY                       => C_FAMILY,
        C_FULL_FLAGS_RST_VAL           => C_FULL_FLAGS_RST_VAL,
        C_HAS_ALMOST_EMPTY             => C_HAS_ALMOST_EMPTY,
        C_HAS_ALMOST_FULL              => C_HAS_ALMOST_FULL,
        C_HAS_BACKUP                   => C_HAS_BACKUP,
        C_HAS_DATA_COUNT               => C_HAS_DATA_COUNT,
        C_HAS_INT_CLK                  => C_HAS_INT_CLK,
        C_HAS_MEMINIT_FILE             => C_HAS_MEMINIT_FILE,
        C_HAS_OVERFLOW                 => C_HAS_OVERFLOW,
        C_HAS_RD_DATA_COUNT            => C_HAS_RD_DATA_COUNT,
        C_HAS_RD_RST                   => C_HAS_RD_RST,
        C_HAS_RST                      => C_HAS_RST,
        C_HAS_SRST                     => C_HAS_SRST,
        C_HAS_UNDERFLOW                => C_HAS_UNDERFLOW,
        C_HAS_VALID                    => C_HAS_VALID,
        C_HAS_WR_ACK                   => C_HAS_WR_ACK,
        C_HAS_WR_DATA_COUNT            => C_HAS_WR_DATA_COUNT,
        C_HAS_WR_RST                   => C_HAS_WR_RST,
        C_IMPLEMENTATION_TYPE          => C_IMPLEMENTATION_TYPE,
        C_INIT_WR_PNTR_VAL             => C_INIT_WR_PNTR_VAL,
        C_MEMORY_TYPE                  => C_MEMORY_TYPE,
        C_MIF_FILE_NAME                => C_MIF_FILE_NAME,
        C_OPTIMIZATION_MODE            => C_OPTIMIZATION_MODE,
        C_OVERFLOW_LOW                 => C_OVERFLOW_LOW,
        C_PRELOAD_LATENCY              => C_PRELOAD_LATENCY,
        C_PRELOAD_REGS                 => C_PRELOAD_REGS,
        C_PRIM_FIFO_TYPE               => C_PRIM_FIFO_TYPE,
        C_PROG_EMPTY_THRESH_ASSERT_VAL => C_PROG_EMPTY_THRESH_ASSERT_VAL,
        C_PROG_EMPTY_THRESH_NEGATE_VAL => C_PROG_EMPTY_THRESH_NEGATE_VAL,
        C_PROG_EMPTY_TYPE              => C_PROG_EMPTY_TYPE,
        C_PROG_FULL_THRESH_ASSERT_VAL  => C_PROG_FULL_THRESH_ASSERT_VAL,
        C_PROG_FULL_THRESH_NEGATE_VAL  => C_PROG_FULL_THRESH_NEGATE_VAL,
        C_PROG_FULL_TYPE               => C_PROG_FULL_TYPE,
        C_RD_DATA_COUNT_WIDTH          => C_RD_DATA_COUNT_WIDTH,
        C_RD_DEPTH                     => C_RD_DEPTH,
        C_RD_FREQ                      => C_RD_FREQ,
        C_RD_PNTR_WIDTH                => C_RD_PNTR_WIDTH,
        C_UNDERFLOW_LOW                => C_UNDERFLOW_LOW,
        C_USE_DOUT_RST                 => C_USE_DOUT_RST,
        C_USE_ECC                      => C_USE_ECC,
        C_USE_EMBEDDED_REG             => C_USE_EMBEDDED_REG,
        C_USE_FIFO16_FLAGS             => C_USE_FIFO16_FLAGS,
        C_USE_FWFT_DATA_COUNT          => C_USE_FWFT_DATA_COUNT,
        C_VALID_LOW                    => C_VALID_LOW,
        C_WR_ACK_LOW                   => C_WR_ACK_LOW,
        C_WR_DATA_COUNT_WIDTH          => C_WR_DATA_COUNT_WIDTH,
        C_WR_DEPTH                     => C_WR_DEPTH,
        C_WR_FREQ                      => C_WR_FREQ,
        C_WR_PNTR_WIDTH                => C_WR_PNTR_WIDTH,
        C_WR_RESPONSE_LATENCY          => C_WR_RESPONSE_LATENCY,
        C_MSGON_VAL                    => C_MSGON_VAL,
        C_ENABLE_RST_SYNC              => C_ENABLE_RST_SYNC,
        C_EN_SAFETY_CKT                => C_EN_SAFETY_CKT,
        C_ERROR_INJECTION_TYPE         => C_ERROR_INJECTION_TYPE,
        C_AXI_TYPE                     => C_AXI_TYPE,
        C_SYNCHRONIZER_STAGE           => C_SYNCHRONIZER_STAGE
        )
      PORT MAP(
        --Inputs
        BACKUP                    => BACKUP,
        BACKUP_MARKER             => BACKUP_MARKER,
        CLK                       => CLK,
        RST                       => RST,
        SRST                      => SRST,
        WR_CLK                    => WR_CLK,
        WR_RST                    => WR_RST,
        RD_CLK                    => RD_CLK,
        RD_RST                    => RD_RST,
        DIN                       => DIN,
        WR_EN                     => WR_EN,
        RD_EN                     => RD_EN,
        PROG_EMPTY_THRESH         => PROG_EMPTY_THRESH,
        PROG_EMPTY_THRESH_ASSERT  => PROG_EMPTY_THRESH_ASSERT,
        PROG_EMPTY_THRESH_NEGATE  => PROG_EMPTY_THRESH_NEGATE,
        PROG_FULL_THRESH          => PROG_FULL_THRESH,
        PROG_FULL_THRESH_ASSERT   => PROG_FULL_THRESH_ASSERT,
        PROG_FULL_THRESH_NEGATE   => PROG_FULL_THRESH_NEGATE,
        INT_CLK                   => INT_CLK,
        INJECTDBITERR             => INJECTDBITERR,
        INJECTSBITERR             => INJECTSBITERR,
  
        --Outputs
        DOUT                  => DOUT,
        FULL                  => full_i,
        ALMOST_FULL           => ALMOST_FULL,
        WR_ACK                => WR_ACK,
        OVERFLOW              => OVERFLOW,
        EMPTY                 => empty_i,
        ALMOST_EMPTY          => ALMOST_EMPTY,
        VALID                 => VALID,
        UNDERFLOW             => UNDERFLOW,
        DATA_COUNT            => DATA_COUNT,
        RD_DATA_COUNT         => RD_DATA_COUNT,
        WR_DATA_COUNT         => wr_data_count_in,
        PROG_FULL             => PROG_FULL,
        PROG_EMPTY            => PROG_EMPTY,
        SBITERR               => SBITERR,
        DBITERR               => DBITERR,
        WR_RST_BUSY           => WR_RST_BUSY,
        RD_RST_BUSY           => RD_RST_BUSY, 
        WR_RST_I_OUT          => WR_RST_INT, 
        RD_RST_I_OUT          => RD_RST_INT 
        );

            FULL <= full_i;
      EMPTY <= empty_i;


      fifo_ic_adapter: IF (C_HAS_DATA_COUNTS_AXIS = 3) GENERATE
        SIGNAL wr_eop      : STD_LOGIC := '0';
        SIGNAL rd_eop      : STD_LOGIC := '0';
        SIGNAL data_read    : STD_LOGIC := '0';
        SIGNAL w_cnt    : STD_LOGIC_VECTOR(log2roundup(C_WR_DEPTH)-1 DOWNTO 0) := (OTHERS => '0');
        SIGNAL r_cnt    : STD_LOGIC_VECTOR(log2roundup(C_WR_DEPTH)-1 DOWNTO 0) := (OTHERS => '0');
        SIGNAL w_cnt_gc : STD_LOGIC_VECTOR(log2roundup(C_WR_DEPTH)-1 DOWNTO 0) := (OTHERS => '0');
        SIGNAL w_cnt_gc_asreg_last : STD_LOGIC_VECTOR(log2roundup(C_WR_DEPTH)-1 DOWNTO 0) := (OTHERS => '0');
        SIGNAL w_cnt_rd : STD_LOGIC_VECTOR(log2roundup(C_WR_DEPTH)-1 DOWNTO 0) := (OTHERS => '0');
        --SIGNAL axis_wr_rst      : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
        --SIGNAL axis_rd_rst      : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
  
        SIGNAL d_cnt             : std_logic_vector(log2roundup(C_WR_DEPTH)-1 DOWNTO 0) := (OTHERS => '0');
        SIGNAL d_cnt_pad         : std_logic_vector(log2roundup(C_WR_DEPTH) DOWNTO 0) := (OTHERS => '0');
        SIGNAL adj_w_cnt_rd_pad : std_logic_vector(log2roundup(C_WR_DEPTH) DOWNTO 0) := (others => '0');
        SIGNAL r_inv_pad             : std_logic_vector(log2roundup(C_WR_DEPTH) DOWNTO 0) := (others => '0');
        -- Defined to connect data output of one FIFO to data input of another 
        TYPE w_sync_array IS ARRAY (0 TO C_SYNCHRONIZER_STAGE) OF std_logic_vector(log2roundup(C_WR_DEPTH)-1 DOWNTO 0);
        SIGNAL w_q : w_sync_array := (OTHERS => (OTHERS => '0'));
        TYPE axis_af_array IS ARRAY (0 TO C_SYNCHRONIZER_STAGE) OF std_logic_vector(0 DOWNTO 0);
      BEGIN
        wr_eop <= WR_EN AND not(full_i);
        rd_eop <= RD_EN AND not(empty_i);

        -- Write Packet count logic
        proc_w_cnt: PROCESS (WR_CLK, WR_RST_INT)
        BEGIN
          IF (WR_RST_INT = '1') THEN
            w_cnt <= (OTHERS => '0');
          ELSIF (WR_CLK = '1' AND WR_CLK'EVENT) THEN
            IF (wr_eop = '1') THEN
              w_cnt <= w_cnt + "1"  AFTER TFF;
            END IF;
          END IF;
        END PROCESS proc_w_cnt;

        -- Convert Write Packet count to Grey
        pw_gc : PROCESS (WR_CLK, WR_RST_INT)
        BEGIN
          if (WR_RST_INT = '1') then
            w_cnt_gc <= (OTHERS => '0');
          ELSIF (WR_CLK'event AND WR_CLK='1') THEN
            w_cnt_gc <= bin2gray(w_cnt, log2roundup(C_WR_DEPTH)) AFTER TFF;
          END IF;
        END PROCESS pw_gc;

        -- Synchronize the Write Packet count in read domain
        -- Synchronize the axis_almost_full in read domain
        gpkt_cnt_sync_stage: FOR I IN 1 TO C_SYNCHRONIZER_STAGE GENERATE
        BEGIN
         --   pkt_rd_stg_inst: ENTITY fifo_generator_v13_0_0.synchronizer_ff
         --       GENERIC MAP (
         --         C_HAS_RST => C_HAS_RST,
         --         C_WIDTH   => log2roundup(C_WR_DEPTH_AXIS)
         --         )
         --       PORT MAP ( 
         --         RST       => axis_rd_rst(0),
         --         CLK       => M_ACLK,   
         --         D         => wpkt_q(i-1),
         --         Q         => wpkt_q(i)
         --         );

            PROCESS (RD_CLK, RD_RST_INT)
            BEGIN  
              IF (RD_RST_INT = '1' AND C_HAS_RST = 1) THEN
                w_q(i) <= (OTHERS => '0');
              ELSIF RD_CLK'EVENT AND RD_CLK = '1' THEN  
                w_q(i) <= w_q(i-1) AFTER TFF;
              END IF;
            END PROCESS;



        END GENERATE gpkt_cnt_sync_stage;

        w_q(0)                    <= w_cnt_gc;
        w_cnt_gc_asreg_last  <= w_q(C_SYNCHRONIZER_STAGE);

           -- Convert synchronized Write Packet count grey value to binay
        pw_rd_bin : PROCESS (RD_CLK, RD_RST_INT)
        BEGIN
          if (RD_RST_INT = '1') then
            w_cnt_rd <= (OTHERS => '0'); 
          ELSIF (RD_CLK'event AND RD_CLK = '1') THEN
            w_cnt_rd <= gray2bin(w_cnt_gc_asreg_last, log2roundup(C_WR_DEPTH)) AFTER TFF;
          END IF;
        END PROCESS pw_rd_bin;

        -- Read Packet count logic
        proc_r_cnt: PROCESS (RD_CLK, RD_RST_INT)
        BEGIN
          IF (RD_RST_INT = '1') THEN
            r_cnt <= (OTHERS => '0');
          ELSIF (RD_CLK = '1' AND RD_CLK'EVENT) THEN
            IF (rd_eop = '1') THEN
              r_cnt <= r_cnt + "1"  AFTER TFF;
            END IF;
          END IF;
        END PROCESS proc_r_cnt;

        -- Take the difference of write and read packet count
        -- Logic is similar to rd_pe_as
        adj_w_cnt_rd_pad(log2roundup(C_WR_DEPTH) DOWNTO 1) <= w_cnt_rd;
        r_inv_pad(log2roundup(C_WR_DEPTH) DOWNTO 1)             <= not r_cnt;

        p_cry: PROCESS (rd_eop)
        BEGIN
          IF (rd_eop = '0') THEN
            adj_w_cnt_rd_pad(0) <= '1';
            r_inv_pad(0)             <= '1';
          ELSE 
            adj_w_cnt_rd_pad(0) <= '0';
            r_inv_pad(0)             <= '0';
          END IF;
        END PROCESS p_cry;

        p_sub: PROCESS (RD_CLK, RD_RST_INT)
        BEGIN
          IF (RD_RST_INT = '1') THEN  
            d_cnt_pad <= (OTHERS=>'0');
          ELSIF RD_CLK'event AND RD_CLK = '1' THEN  
            d_cnt_pad <= adj_w_cnt_rd_pad + r_inv_pad AFTER TFF;
          END IF;
        END PROCESS p_sub;

        d_cnt <= d_cnt_pad(log2roundup(C_WR_DEPTH) DOWNTO 1);

          WR_DATA_COUNT <= d_cnt;
  END GENERATE fifo_ic_adapter; 

  fifo_icn_adapter: IF (C_HAS_DATA_COUNTS_AXIS /= 3) GENERATE
          WR_DATA_COUNT <= wr_data_count_in;
  END GENERATE fifo_icn_adapter; 

  END GENERATE gconvfifo; -- End of conventional FIFO


  
  ---------------------------------------------------------------------------
  ---------------------------------------------------------------------------
  ---------------------------------------------------------------------------
  -- Top level instance for ramfifo in AXI Streaming FIFO core. It implements:
  -- * BRAM based FIFO
  -- * Dist RAM based FIFO
  ---------------------------------------------------------------------------
  ---------------------------------------------------------------------------
  ---------------------------------------------------------------------------

  gaxis_fifo: IF ((C_INTERFACE_TYPE = 1) AND (C_AXIS_TYPE < 2)) GENERATE
    SIGNAL axis_din            : std_logic_vector(C_DIN_WIDTH_AXIS-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL axis_dout           : std_logic_vector(C_DIN_WIDTH_AXIS-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL axis_full           : std_logic := '0';
    SIGNAL axis_almost_full    : std_logic := '0';
    SIGNAL axis_empty          : std_logic := '0';
    SIGNAL axis_s_axis_tready  : std_logic := '0';
    SIGNAL axis_m_axis_tvalid  : std_logic := '0';
    SIGNAL axis_wr_en          : std_logic := '0';
    SIGNAL axis_rd_en          : std_logic := '0';
    SIGNAL axis_dc             : STD_LOGIC_VECTOR(C_WR_PNTR_WIDTH_AXIS DOWNTO 0) := (OTHERS => '0');
    SIGNAL wr_rst_busy_axis    : STD_LOGIC := '0';
    SIGNAL rd_rst_busy_axis    : STD_LOGIC := '0';

    CONSTANT TDATA_OFFSET      : integer := if_then_else(C_HAS_AXIS_TDATA = 1,C_DIN_WIDTH_AXIS-C_AXIS_TDATA_WIDTH,C_DIN_WIDTH_AXIS);
    CONSTANT TSTRB_OFFSET      : integer := if_then_else(C_HAS_AXIS_TSTRB = 1,TDATA_OFFSET-C_AXIS_TSTRB_WIDTH,TDATA_OFFSET);
    CONSTANT TKEEP_OFFSET      : integer := if_then_else(C_HAS_AXIS_TKEEP = 1,TSTRB_OFFSET-C_AXIS_TKEEP_WIDTH,TSTRB_OFFSET);
    CONSTANT TID_OFFSET        : integer := if_then_else(C_HAS_AXIS_TID = 1,TKEEP_OFFSET-C_AXIS_TID_WIDTH,TKEEP_OFFSET);
    CONSTANT TDEST_OFFSET      : integer := if_then_else(C_HAS_AXIS_TDEST = 1,TID_OFFSET-C_AXIS_TDEST_WIDTH,TID_OFFSET);
    CONSTANT TUSER_OFFSET      : integer := if_then_else(C_HAS_AXIS_TUSER = 1,TDEST_OFFSET-C_AXIS_TUSER_WIDTH,TDEST_OFFSET);
  BEGIN

    -- Generate the DIN to FIFO by concatinating the AXIS optional ports
    gdin1: IF (C_HAS_AXIS_TDATA = 1) GENERATE
      axis_din(C_DIN_WIDTH_AXIS-1 DOWNTO TDATA_OFFSET) <= S_AXIS_TDATA;
      M_AXIS_TDATA   <= axis_dout(C_DIN_WIDTH_AXIS-1 DOWNTO TDATA_OFFSET);
    END GENERATE gdin1;

    gdin2: IF (C_HAS_AXIS_TSTRB = 1) GENERATE
      axis_din(TDATA_OFFSET-1 DOWNTO TSTRB_OFFSET) <= S_AXIS_TSTRB;
      M_AXIS_TSTRB   <= axis_dout(TDATA_OFFSET-1 DOWNTO TSTRB_OFFSET);
    END GENERATE gdin2;

    gdin3: IF (C_HAS_AXIS_TKEEP = 1) GENERATE
      axis_din(TSTRB_OFFSET-1 DOWNTO TKEEP_OFFSET) <= S_AXIS_TKEEP;
      M_AXIS_TKEEP   <= axis_dout(TSTRB_OFFSET-1 DOWNTO TKEEP_OFFSET);
    END GENERATE gdin3;

    gdin4: IF (C_HAS_AXIS_TID = 1) GENERATE
      axis_din(TKEEP_OFFSET-1 DOWNTO TID_OFFSET) <= S_AXIS_TID;
      M_AXIS_TID     <= axis_dout(TKEEP_OFFSET-1 DOWNTO TID_OFFSET);
    END GENERATE gdin4;

    gdin5: IF (C_HAS_AXIS_TDEST = 1) GENERATE
      axis_din(TID_OFFSET-1 DOWNTO TDEST_OFFSET) <= S_AXIS_TDEST;
      M_AXIS_TDEST   <= axis_dout(TID_OFFSET-1 DOWNTO TDEST_OFFSET);
    END GENERATE gdin5;

    gdin6: IF (C_HAS_AXIS_TUSER = 1) GENERATE
      axis_din(TDEST_OFFSET-1 DOWNTO TUSER_OFFSET) <= S_AXIS_TUSER;
      M_AXIS_TUSER   <= axis_dout(TDEST_OFFSET-1 DOWNTO TUSER_OFFSET);
    END GENERATE gdin6;

    gdin7: IF (C_HAS_AXIS_TLAST = 1) GENERATE
      axis_din(0) <= S_AXIS_TLAST;
      M_AXIS_TLAST   <= axis_dout(0);
    END GENERATE gdin7;

    -- Write protection
    --   When FULL is high, pass VALID as a WR_EN to the FIFO to get OVERFLOW interrupt
    gaxis_wr_en1: IF (C_PROG_FULL_TYPE_AXIS = 0) GENERATE
      gwe_pkt: IF (C_APPLICATION_TYPE_AXIS = 1) GENERATE
        axis_wr_en <= S_AXIS_TVALID AND axis_s_axis_tready;
      END GENERATE gwe_pkt;
      gwe: IF (C_APPLICATION_TYPE_AXIS /= 1) GENERATE
        axis_wr_en <= S_AXIS_TVALID;
      END GENERATE gwe;
    END GENERATE gaxis_wr_en1;
    --   When ALMOST_FULL or PROG_FULL is high, then shield the FIFO from becoming FULL
    gaxis_wr_en2: IF (C_PROG_FULL_TYPE_AXIS /= 0) GENERATE
      axis_wr_en <= axis_s_axis_tready AND S_AXIS_TVALID;
    END GENERATE gaxis_wr_en2;

    -- Read protection
    --   When EMPTY is low, pass READY as a RD_EN to the FIFO to get UNDERFLOW interrupt
    gaxis_rd_en1: IF (C_PROG_EMPTY_TYPE_AXIS = 0) GENERATE
      gre_pkt: IF (C_APPLICATION_TYPE_AXIS = 1) GENERATE
        axis_rd_en <= M_AXIS_TREADY AND axis_m_axis_tvalid;
      END GENERATE gre_pkt;
      gre_npkt: IF (C_APPLICATION_TYPE_AXIS /= 1) GENERATE
        axis_rd_en <= M_AXIS_TREADY;
      END GENERATE gre_npkt;
    END GENERATE gaxis_rd_en1;
    --   When ALMOST_EMPTY or PROG_EMPTY is low, then shield the FIFO from becoming EMPTY
    gaxis_rd_en2: IF (C_PROG_EMPTY_TYPE_AXIS /= 0) GENERATE
      axis_rd_en <= axis_m_axis_tvalid AND M_AXIS_TREADY;
    END GENERATE gaxis_rd_en2;

    gaxisf: IF (C_AXIS_TYPE = 0) GENERATE
      SIGNAL axis_we : STD_LOGIC := '0';
      SIGNAL axis_re : STD_LOGIC := '0';
      SIGNAL axis_wr_rst      : STD_LOGIC :=  '0';
      SIGNAL axis_rd_rst      : STD_LOGIC :=  '0';
    BEGIN
      axis_we <= axis_wr_en WHEN (C_HAS_SLAVE_CE = 0) ELSE axis_wr_en AND S_ACLK_EN;
      axis_re <= axis_rd_en WHEN (C_HAS_MASTER_CE = 0) ELSE axis_rd_en AND M_ACLK_EN;

      axisf : fifo_generator_v13_0_0_conv
      GENERIC MAP (
          C_FAMILY                          => C_FAMILY,
          C_COMMON_CLOCK                    => C_COMMON_CLOCK,
          C_MEMORY_TYPE                     => if_then_else((C_IMPLEMENTATION_TYPE_AXIS = 1 OR C_IMPLEMENTATION_TYPE_AXIS = 11),1,
                                               if_then_else((C_IMPLEMENTATION_TYPE_AXIS = 2 OR C_IMPLEMENTATION_TYPE_AXIS = 12),2,4)),
          C_IMPLEMENTATION_TYPE             => if_then_else((C_IMPLEMENTATION_TYPE_AXIS = 1 OR C_IMPLEMENTATION_TYPE_AXIS = 2),0,
                                               if_then_else((C_IMPLEMENTATION_TYPE_AXIS = 11 OR C_IMPLEMENTATION_TYPE_AXIS = 12),2,6)),
          C_PRELOAD_REGS                    => 1, -- Always FWFT for AXI
          C_PRELOAD_LATENCY                 => 0, -- Always FWFT for AXI
          C_DIN_WIDTH                       => C_DIN_WIDTH_AXIS,
          C_WR_DEPTH                        => C_WR_DEPTH_AXIS,
          C_WR_PNTR_WIDTH                   => C_WR_PNTR_WIDTH_AXIS,
          C_DOUT_WIDTH                      => C_DIN_WIDTH_AXIS,
          C_RD_DEPTH                        => C_WR_DEPTH_AXIS,
          C_RD_PNTR_WIDTH                   => C_WR_PNTR_WIDTH_AXIS,
          C_PROG_FULL_TYPE                  => C_PROG_FULL_TYPE_AXIS,
          C_PROG_FULL_THRESH_ASSERT_VAL     => C_PROG_FULL_THRESH_ASSERT_VAL_AXIS,
          C_PROG_EMPTY_TYPE                 => C_PROG_EMPTY_TYPE_AXIS,
          C_PROG_EMPTY_THRESH_ASSERT_VAL    => C_PROG_EMPTY_THRESH_ASSERT_VAL_AXIS,
          C_USE_ECC                         => C_USE_ECC_AXIS,
          C_ERROR_INJECTION_TYPE            => C_ERROR_INJECTION_TYPE_AXIS,
          C_HAS_ALMOST_EMPTY                => 0,
          C_HAS_ALMOST_FULL                 => if_then_else(C_APPLICATION_TYPE_AXIS = 1,1,0),
          -- Enable Low Latency Sync FIFO for Common Clock Built-in FIFO
          C_FIFO_TYPE                       => if_then_else(C_APPLICATION_TYPE_AXIS = 1,0,C_APPLICATION_TYPE_AXIS),
          C_SYNCHRONIZER_STAGE              => C_SYNCHRONIZER_STAGE,
          C_AXI_TYPE                        => if_then_else(C_INTERFACE_TYPE = 1, 0, C_AXI_TYPE),

          C_HAS_WR_RST                      => 0,
          C_HAS_RD_RST                      => 0,
          C_HAS_RST                         => 1,
          C_HAS_SRST                        => 0,
          C_DOUT_RST_VAL                    => "0",
  
          C_HAS_VALID                       => 0,
          C_VALID_LOW                       => C_VALID_LOW,
          C_HAS_UNDERFLOW                   => C_HAS_UNDERFLOW,
          C_UNDERFLOW_LOW                   => C_UNDERFLOW_LOW,
          C_HAS_WR_ACK                      => 0,
          C_WR_ACK_LOW                      => C_WR_ACK_LOW,
          C_HAS_OVERFLOW                    => C_HAS_OVERFLOW,
          C_OVERFLOW_LOW                    => C_OVERFLOW_LOW,
  
          C_HAS_DATA_COUNT                  => if_then_else((C_COMMON_CLOCK = 1 AND C_HAS_DATA_COUNTS_AXIS = 1), 1, 0),
          C_DATA_COUNT_WIDTH                => C_WR_PNTR_WIDTH_AXIS+1,      
          C_HAS_RD_DATA_COUNT               => if_then_else((C_COMMON_CLOCK = 0 AND C_HAS_DATA_COUNTS_AXIS = 1), 1, 0),
          C_RD_DATA_COUNT_WIDTH             => C_WR_PNTR_WIDTH_AXIS+1,
          C_USE_FWFT_DATA_COUNT             => 1, -- use extra logic is always true
          C_HAS_WR_DATA_COUNT               => if_then_else((C_COMMON_CLOCK = 0 AND C_HAS_DATA_COUNTS_AXIS = 1), 1, 0),
          C_WR_DATA_COUNT_WIDTH             => C_WR_PNTR_WIDTH_AXIS+1,
          C_FULL_FLAGS_RST_VAL              => 1,
          C_USE_EMBEDDED_REG                => C_USE_EMBEDDED_REG,
          C_USE_DOUT_RST                    => 0,
          C_MSGON_VAL                       => C_MSGON_VAL,
          C_ENABLE_RST_SYNC                 => 1,
          C_EN_SAFETY_CKT                   => 1,
  
          C_COUNT_TYPE                      => C_COUNT_TYPE,
          C_DEFAULT_VALUE                   => C_DEFAULT_VALUE,
          C_ENABLE_RLOCS                    => C_ENABLE_RLOCS,
          C_HAS_BACKUP                      => C_HAS_BACKUP,
          C_HAS_INT_CLK                     => C_HAS_INT_CLK,
          C_HAS_MEMINIT_FILE                => C_HAS_MEMINIT_FILE,
          C_INIT_WR_PNTR_VAL                => C_INIT_WR_PNTR_VAL,
          C_MIF_FILE_NAME                   => C_MIF_FILE_NAME,
          C_OPTIMIZATION_MODE               => C_OPTIMIZATION_MODE,
          C_RD_FREQ                         => C_RD_FREQ,
          C_USE_FIFO16_FLAGS                => C_USE_FIFO16_FLAGS,
          C_WR_FREQ                         => C_WR_FREQ,
          C_WR_RESPONSE_LATENCY             => C_WR_RESPONSE_LATENCY
  
          )
      PORT MAP(
        --Inputs
        BACKUP                    => BACKUP,
        BACKUP_MARKER             => BACKUP_MARKER,
        INT_CLK                   => INT_CLK,
    
        CLK                       => S_ACLK,
        WR_CLK                    => S_ACLK,
        RD_CLK                    => M_ACLK,
        RST                       => inverted_reset,
        SRST                      => '0',
        WR_RST                    => inverted_reset,
        RD_RST                    => inverted_reset,
  
        WR_EN                     => axis_we,
        RD_EN                     => axis_re,
        PROG_FULL_THRESH          => AXIS_PROG_FULL_THRESH,
        PROG_FULL_THRESH_ASSERT   => (OTHERS => '0'),
        PROG_FULL_THRESH_NEGATE   => (OTHERS => '0'),
        PROG_EMPTY_THRESH         => AXIS_PROG_EMPTY_THRESH,
        PROG_EMPTY_THRESH_ASSERT  => (OTHERS => '0'),
        PROG_EMPTY_THRESH_NEGATE  => (OTHERS => '0'),
        INJECTDBITERR             => AXIS_INJECTDBITERR,
        INJECTSBITERR             => AXIS_INJECTSBITERR,
 
        DIN                       => axis_din,
        DOUT                      => axis_dout,
        FULL                      => axis_full,
        EMPTY                     => axis_empty,
        ALMOST_FULL               => axis_almost_full,
        PROG_FULL                 => AXIS_PROG_FULL,
        ALMOST_EMPTY              => OPEN,
        PROG_EMPTY                => AXIS_PROG_EMPTY,
    
        WR_ACK                    => OPEN,
        OVERFLOW                  => AXIS_OVERFLOW,
        VALID                     => OPEN,
        UNDERFLOW                 => AXIS_UNDERFLOW,
        DATA_COUNT                => axis_dc,
        RD_DATA_COUNT             => AXIS_RD_DATA_COUNT,
        WR_DATA_COUNT             => AXIS_WR_DATA_COUNT,
        SBITERR                   => AXIS_SBITERR,
        DBITERR                   => AXIS_DBITERR,
        WR_RST_BUSY               => wr_rst_busy_axis,
        RD_RST_BUSY               => rd_rst_busy_axis, 
        WR_RST_I_OUT                  => axis_wr_rst, 
        RD_RST_I_OUT                  => axis_rd_rst 
        );

      g8s_axis_rdy: IF (IS_8SERIES = 1) GENERATE
        g8s_bi_axis_rdy: IF (C_IMPLEMENTATION_TYPE_AXIS = 5 OR C_IMPLEMENTATION_TYPE_AXIS = 13) GENERATE
          axis_s_axis_tready    <= NOT (axis_full OR wr_rst_busy_axis);
        END GENERATE g8s_bi_axis_rdy;
        g8s_nbi_axis_rdy: IF (NOT (C_IMPLEMENTATION_TYPE_AXIS = 5 OR C_IMPLEMENTATION_TYPE_AXIS = 13)) GENERATE
          axis_s_axis_tready    <= NOT (axis_full);
        END GENERATE g8s_nbi_axis_rdy;
      END GENERATE g8s_axis_rdy;
      g7s_axis_rdy: IF (IS_8SERIES = 0) GENERATE
        axis_s_axis_tready    <= NOT (axis_full);
      END GENERATE g7s_axis_rdy;

      --axis_m_axis_tvalid    <= NOT axis_empty WHEN (C_APPLICATION_TYPE_AXIS /= 1) ELSE NOT axis_empty AND axis_pkt_read;
     gnaxis_pkt_fifo: IF (C_APPLICATION_TYPE_AXIS /= 1) GENERATE
        axis_m_axis_tvalid    <= NOT axis_empty;
      END GENERATE gnaxis_pkt_fifo;

      S_AXIS_TREADY         <= axis_s_axis_tready;
      M_AXIS_TVALID         <= axis_m_axis_tvalid;

      gaxis_pkt_fifo_cc: IF (C_APPLICATION_TYPE_AXIS = 1 AND C_COMMON_CLOCK = 1) GENERATE
        SIGNAL axis_wr_eop      : STD_LOGIC := '0';
        SIGNAL axis_wr_eop_d1   : STD_LOGIC := '0';
        SIGNAL axis_rd_eop      : STD_LOGIC := '0';
        SIGNAL axis_pkt_cnt     : INTEGER   := 0;
        SIGNAL axis_pkt_read       : STD_LOGIC := '0';
      BEGIN
        axis_m_axis_tvalid    <=  NOT axis_empty AND axis_pkt_read;
        axis_wr_eop <= axis_we AND S_AXIS_TLAST;
        axis_rd_eop <= axis_re AND axis_dout(0);

        -- Packet Read Generation logic
        PROCESS (S_ACLK, inverted_reset)
        BEGIN
          IF (inverted_reset = '1') THEN
            axis_pkt_read    <= '0';
            axis_wr_eop_d1   <= '0';
          ELSIF (S_ACLK = '1' AND S_ACLK'EVENT) THEN
            axis_wr_eop_d1   <= axis_wr_eop;
            IF (axis_rd_eop = '1' AND (axis_pkt_cnt = 1) AND axis_wr_eop_d1 = '0') THEN
              axis_pkt_read <= '0'  AFTER TFF;
            ELSIF ((axis_pkt_cnt > 0) OR (axis_almost_full = '1' AND axis_empty = '0')) THEN
              axis_pkt_read <= '1'  AFTER TFF;
            END IF;
          END IF;
        END PROCESS;

        -- Packet count logic
        PROCESS (S_ACLK, inverted_reset)
        BEGIN
          IF (inverted_reset = '1') THEN
            axis_pkt_cnt <= 0;
          ELSIF (S_ACLK = '1' AND S_ACLK'EVENT) THEN
            IF (axis_wr_eop_d1 = '1' AND axis_rd_eop = '0') THEN
              axis_pkt_cnt <= axis_pkt_cnt + 1  AFTER TFF;
            ELSIF (axis_rd_eop = '1' AND axis_wr_eop_d1 = '0') THEN
              axis_pkt_cnt <= axis_pkt_cnt - 1  AFTER TFF;
            END IF;
          END IF;
        END PROCESS;
      END GENERATE gaxis_pkt_fifo_cc;

      gaxis_pkt_fifo_ic: IF (C_APPLICATION_TYPE_AXIS = 1 AND C_COMMON_CLOCK = 0) GENERATE
        SIGNAL axis_wr_eop      : STD_LOGIC := '0';
        SIGNAL axis_rd_eop      : STD_LOGIC := '0';
        SIGNAL axis_pkt_read    : STD_LOGIC := '0';
        SIGNAL axis_wpkt_cnt    : STD_LOGIC_VECTOR(log2roundup(C_WR_DEPTH_AXIS)-1 DOWNTO 0) := (OTHERS => '0');
        SIGNAL axis_rpkt_cnt    : STD_LOGIC_VECTOR(log2roundup(C_WR_DEPTH_AXIS)-1 DOWNTO 0) := (OTHERS => '0');
        SIGNAL axis_wpkt_cnt_gc : STD_LOGIC_VECTOR(log2roundup(C_WR_DEPTH_AXIS)-1 DOWNTO 0) := (OTHERS => '0');
        SIGNAL axis_wpkt_cnt_gc_asreg_last : STD_LOGIC_VECTOR(log2roundup(C_WR_DEPTH_AXIS)-1 DOWNTO 0) := (OTHERS => '0');
        SIGNAL axis_wpkt_cnt_rd : STD_LOGIC_VECTOR(log2roundup(C_WR_DEPTH_AXIS)-1 DOWNTO 0) := (OTHERS => '0');
        SIGNAL diff_pkt_cnt             : std_logic_vector(log2roundup(C_WR_DEPTH_AXIS)-1 DOWNTO 0) := (OTHERS => '0');
        SIGNAL diff_pkt_cnt_pad         : std_logic_vector(log2roundup(C_WR_DEPTH_AXIS) DOWNTO 0) := (OTHERS => '0');
        SIGNAL adj_axis_wpkt_cnt_rd_pad : std_logic_vector(log2roundup(C_WR_DEPTH_AXIS) DOWNTO 0) := (others => '0');
        SIGNAL rpkt_inv_pad             : std_logic_vector(log2roundup(C_WR_DEPTH_AXIS) DOWNTO 0) := (others => '0');
        -- Defined to connect data output of one FIFO to data input of another 
        TYPE wpkt_sync_array IS ARRAY (0 TO C_SYNCHRONIZER_STAGE) OF std_logic_vector(log2roundup(C_WR_DEPTH_AXIS)-1 DOWNTO 0);
        SIGNAL wpkt_q : wpkt_sync_array := (OTHERS => (OTHERS => '0'));
        TYPE axis_af_array IS ARRAY (0 TO C_SYNCHRONIZER_STAGE) OF std_logic_vector(0 DOWNTO 0);
        SIGNAL axis_af_q  : axis_af_array := (OTHERS => (OTHERS => '0'));
        SIGNAL axis_af_rd : std_logic_vector(0 DOWNTO 0) := (others => '0');
      BEGIN
        axis_wr_eop <= axis_we AND S_AXIS_TLAST;
        axis_rd_eop <= axis_re AND axis_dout(0);

        -- Packet Read Generation logic
        PROCESS (M_ACLK, axis_rd_rst)
        BEGIN
          IF (axis_rd_rst = '1') THEN
            axis_pkt_read    <= '0';
          ELSIF (M_ACLK = '1' AND M_ACLK'EVENT) THEN
            IF (axis_rd_eop = '1' AND (conv_integer(diff_pkt_cnt) = 1)) THEN
              axis_pkt_read <= '0'  AFTER TFF;
            -- Asserting packet read at the same time when the packet is written is not considered because it causes
            -- packet FIFO handshake violation when the packet size is just 2 data beat and each write is separated
            -- by more than 2 clocks. This causes the first data to come out at the FWFT stage making the actual FIFO
            -- empty and leaving the first stage FWFT stage with no data, and when the last data is written, it 
            -- actually makes the valid to be high for a clock and de-asserts immediately as the written data will
            -- take two clocks to appear at the FWFT output. This situation is a violation of packet FIFO, where 
            -- TVALID should not get de-asserted in between the packet transfer.
            ELSIF ((conv_integer(diff_pkt_cnt) > 0) OR (axis_af_rd(0) = '1' AND axis_empty = '0')) THEN
              axis_pkt_read <= '1'  AFTER TFF;
            END IF;
          END IF;
        END PROCESS;
        axis_m_axis_tvalid    <= (NOT axis_empty) AND axis_pkt_read;

        -- Write Packet count logic
        proc_wpkt_cnt: PROCESS (S_ACLK, axis_wr_rst)
        BEGIN
          IF (axis_wr_rst = '1') THEN
            axis_wpkt_cnt <= (OTHERS => '0');
          ELSIF (S_ACLK = '1' AND S_ACLK'EVENT) THEN
            IF (axis_wr_eop = '1') THEN
              axis_wpkt_cnt <= axis_wpkt_cnt + "1"  AFTER TFF;
            END IF;
          END IF;
        END PROCESS proc_wpkt_cnt;

        -- Convert Write Packet count to Grey
        pwpkt_gc : PROCESS (S_ACLK, axis_wr_rst)
        BEGIN
          if (axis_wr_rst = '1') then
            axis_wpkt_cnt_gc <= (OTHERS => '0');
          ELSIF (S_ACLK'event AND S_ACLK='1') THEN
            axis_wpkt_cnt_gc <= bin2gray(axis_wpkt_cnt, log2roundup(C_WR_DEPTH_AXIS)) AFTER TFF;
          END IF;
        END PROCESS pwpkt_gc;

        -- Synchronize the Write Packet count in read domain
        -- Synchronize the axis_almost_full in read domain
        gpkt_cnt_sync_stage: FOR I IN 1 TO C_SYNCHRONIZER_STAGE GENERATE
        BEGIN
         --   pkt_rd_stg_inst: ENTITY fifo_generator_v13_0_0.synchronizer_ff
         --       GENERIC MAP (
         --         C_HAS_RST => C_HAS_RST,
         --         C_WIDTH   => log2roundup(C_WR_DEPTH_AXIS)
         --         )
         --       PORT MAP ( 
         --         RST       => axis_rd_rst(0),
         --         CLK       => M_ACLK,   
         --         D         => wpkt_q(i-1),
         --         Q         => wpkt_q(i)
         --         );

            PROCESS (M_ACLK, axis_rd_rst)
            BEGIN  
              IF (axis_rd_rst = '1' AND C_HAS_RST = 1) THEN
                wpkt_q(i) <= (OTHERS => '0');
              ELSIF M_ACLK'EVENT AND M_ACLK = '1' THEN  
                wpkt_q(i) <= wpkt_q(i-1) AFTER TFF;
              END IF;
            END PROCESS;


          --  af_rd_stg_inst: ENTITY fifo_generator_v13_0_0.synchronizer_ff
          --      GENERIC MAP (
          --        C_HAS_RST => C_HAS_RST,
          --        C_WIDTH   => 1
          --        )
          --      PORT MAP ( 
          --        RST       => axis_rd_rst(0),
          --        CLK       => M_ACLK,   
          --        D         => axis_af_q(i-1),
          --        Q         => axis_af_q(i)
          --        );    

            PROCESS (M_ACLK, axis_rd_rst)
            BEGIN  
              IF (axis_rd_rst = '1' AND C_HAS_RST = 1) THEN
                axis_af_q(i) <=  (OTHERS => '0');
              ELSIF M_ACLK'EVENT AND M_ACLK = '1' THEN  
                axis_af_q(i) <= axis_af_q(i-1) AFTER TFF;
              END IF;
            END PROCESS;

        END GENERATE gpkt_cnt_sync_stage;

        wpkt_q(0)                    <= axis_wpkt_cnt_gc;
        axis_wpkt_cnt_gc_asreg_last  <= wpkt_q(C_SYNCHRONIZER_STAGE);
        axis_af_q(0)(0)              <= axis_almost_full;
        axis_af_rd                   <= axis_af_q(C_SYNCHRONIZER_STAGE);

        -- Convert synchronized Write Packet count grey value to binay
        pwpkt_rd_bin : PROCESS (M_ACLK, axis_rd_rst)
        BEGIN
          if (axis_rd_rst = '1') then
            axis_wpkt_cnt_rd <= (OTHERS => '0'); 
          ELSIF (M_ACLK'event AND M_ACLK = '1') THEN
            axis_wpkt_cnt_rd <= gray2bin(axis_wpkt_cnt_gc_asreg_last, log2roundup(C_WR_DEPTH_AXIS)) AFTER TFF;
          END IF;
        END PROCESS pwpkt_rd_bin;

        -- Read Packet count logic
        proc_rpkt_cnt: PROCESS (M_ACLK, axis_rd_rst)
        BEGIN
          IF (axis_rd_rst = '1') THEN
            axis_rpkt_cnt <= (OTHERS => '0');
          ELSIF (M_ACLK = '1' AND M_ACLK'EVENT) THEN
            IF (axis_rd_eop = '1') THEN
              axis_rpkt_cnt <= axis_rpkt_cnt + "1"  AFTER TFF;
            END IF;
          END IF;
        END PROCESS proc_rpkt_cnt;

        -- Take the difference of write and read packet count
        -- Logic is similar to rd_pe_as
        adj_axis_wpkt_cnt_rd_pad(log2roundup(C_WR_DEPTH_AXIS) DOWNTO 1) <= axis_wpkt_cnt_rd;
        rpkt_inv_pad(log2roundup(C_WR_DEPTH_AXIS) DOWNTO 1)             <= not axis_rpkt_cnt;

        pkt_cry: PROCESS (axis_rd_eop)
        BEGIN
          IF (axis_rd_eop = '0') THEN
            adj_axis_wpkt_cnt_rd_pad(0) <= '1';
            rpkt_inv_pad(0)             <= '1';
          ELSE 
            adj_axis_wpkt_cnt_rd_pad(0) <= '0';
            rpkt_inv_pad(0)             <= '0';
          END IF;
        END PROCESS pkt_cry;

        pkt_sub: PROCESS (M_ACLK, axis_rd_rst)
        BEGIN
          IF (axis_rd_rst = '1') THEN  
            diff_pkt_cnt_pad <= (OTHERS=>'0');
          ELSIF M_ACLK'event AND M_ACLK = '1' THEN  
            diff_pkt_cnt_pad <= adj_axis_wpkt_cnt_rd_pad + rpkt_inv_pad AFTER TFF;
          END IF;
        END PROCESS pkt_sub;

        diff_pkt_cnt <= diff_pkt_cnt_pad(log2roundup(C_WR_DEPTH_AXIS) DOWNTO 1);

      END GENERATE gaxis_pkt_fifo_ic;


      gdc_pkt: IF (C_HAS_DATA_COUNTS_AXIS = 1 AND C_APPLICATION_TYPE_AXIS = 1) GENERATE
        SIGNAL axis_dc_pkt_fifo : STD_LOGIC_VECTOR(C_WR_PNTR_WIDTH_AXIS DOWNTO 0) := (OTHERS => '0');
      BEGIN
        PROCESS (S_ACLK, inverted_reset)
        BEGIN
          IF (inverted_reset = '1') THEN
            axis_dc_pkt_fifo <= (OTHERS => '0');
          ELSIF (S_ACLK = '1' AND S_ACLK'EVENT) THEN
            IF (axis_we = '1' AND axis_re = '0') THEN
              axis_dc_pkt_fifo <= axis_dc_pkt_fifo + "1"  AFTER TFF;
            ELSIF (axis_we = '0' AND axis_re = '1') THEN
              axis_dc_pkt_fifo <= axis_dc_pkt_fifo - "1"  AFTER TFF;
            END IF;
          END IF;
        END PROCESS;
        AXIS_DATA_COUNT <= axis_dc_pkt_fifo;
      END GENERATE gdc_pkt;

      gndc_pkt: IF (C_HAS_DATA_COUNTS_AXIS = 0 AND C_APPLICATION_TYPE_AXIS = 1) GENERATE
        AXIS_DATA_COUNT <= (OTHERS => '0');
      END GENERATE gndc_pkt;

      gdc: IF (C_APPLICATION_TYPE_AXIS /= 1) GENERATE
        AXIS_DATA_COUNT <= axis_dc;
      END GENERATE gdc;
    END GENERATE gaxisf;

    -- Register Slice for AXI Streaming  
    gaxis_reg_slice: IF (C_AXIS_TYPE = 1) GENERATE
      SIGNAL axis_we : STD_LOGIC := '0';
      SIGNAL axis_re : STD_LOGIC := '0';
    BEGIN
      axis_we <= S_AXIS_TVALID WHEN (C_HAS_SLAVE_CE = 0) ELSE S_AXIS_TVALID AND S_ACLK_EN;
      axis_re <= M_AXIS_TREADY WHEN (C_HAS_MASTER_CE = 0) ELSE M_AXIS_TREADY AND M_ACLK_EN;

      axis_reg_slice: fifo_generator_v13_0_0_axic_reg_slice
        GENERIC MAP (
          C_FAMILY                          => C_FAMILY,
          C_DATA_WIDTH                      => C_DIN_WIDTH_AXIS,
          C_REG_CONFIG                      => C_REG_SLICE_MODE_AXIS
          )
      PORT MAP(
        -- System Signals
        ACLK                      => S_ACLK,
        ARESET                    => axi_rs_rst,

        -- Slave side
        S_PAYLOAD_DATA            => axis_din,
        S_VALID                   => axis_we,
        S_READY                   => S_AXIS_TREADY,

        -- Master side
        M_PAYLOAD_DATA            => axis_dout,
        M_VALID                   => M_AXIS_TVALID,
        M_READY                   => axis_re
        );
    END GENERATE gaxis_reg_slice;

  END GENERATE gaxis_fifo;



  gaxifull: IF (C_INTERFACE_TYPE = 2) GENERATE
    SIGNAL axi_rd_underflow_i  : std_logic := '0';
    SIGNAL axi_rd_overflow_i   : std_logic := '0';
    SIGNAL axi_wr_underflow_i  : std_logic := '0';
    SIGNAL axi_wr_overflow_i   : std_logic := '0';
  BEGIN
    gwrch: IF (C_HAS_AXI_WR_CHANNEL = 1) GENERATE
      SIGNAL wach_din            : std_logic_vector(C_DIN_WIDTH_WACH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL wach_dout           : std_logic_vector(C_DIN_WIDTH_WACH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL wach_dout_pkt       : std_logic_vector(C_DIN_WIDTH_WACH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL wach_full           : std_logic := '0';
      SIGNAL wach_almost_full    : std_logic := '0';
      SIGNAL wach_prog_full      : std_logic := '0';
      SIGNAL wach_empty          : std_logic := '0';
      SIGNAL wach_almost_empty   : std_logic := '0';
      SIGNAL wach_prog_empty     : std_logic := '0';
      SIGNAL wdch_din            : std_logic_vector(C_DIN_WIDTH_WDCH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL wdch_dout           : std_logic_vector(C_DIN_WIDTH_WDCH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL wdch_full           : std_logic := '0';
      SIGNAL wdch_almost_full    : std_logic := '0';
      SIGNAL wdch_prog_full      : std_logic := '0';
      SIGNAL wdch_empty          : std_logic := '0';
      SIGNAL wdch_almost_empty   : std_logic := '0';
      SIGNAL wdch_prog_empty     : std_logic := '0';
      SIGNAL wrch_din            : std_logic_vector(C_DIN_WIDTH_WRCH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL wrch_dout           : std_logic_vector(C_DIN_WIDTH_WRCH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL wrch_full           : std_logic := '0';
      SIGNAL wrch_almost_full    : std_logic := '0';
      SIGNAL wrch_prog_full      : std_logic := '0';
      SIGNAL wrch_empty          : std_logic := '0';
      SIGNAL wrch_almost_empty   : std_logic := '0';
      SIGNAL wrch_prog_empty     : std_logic := '0';
      SIGNAL axi_aw_underflow_i  : std_logic := '0';
      SIGNAL axi_w_underflow_i   : std_logic := '0';
      SIGNAL axi_b_underflow_i   : std_logic := '0';
      SIGNAL axi_aw_overflow_i   : std_logic := '0';
      SIGNAL axi_w_overflow_i    : std_logic := '0';
      SIGNAL axi_b_overflow_i    : std_logic := '0';
      SIGNAL wach_s_axi_awready  : std_logic := '0';
      SIGNAL wach_m_axi_awvalid  : std_logic := '0';
      SIGNAL wach_wr_en          : std_logic := '0';
      SIGNAL wach_rd_en          : std_logic := '0';
      SIGNAL wdch_s_axi_wready   : std_logic := '0';
      SIGNAL wdch_m_axi_wvalid   : std_logic := '0';
      SIGNAL wdch_wr_en          : std_logic := '0';
      SIGNAL wdch_rd_en          : std_logic := '0';
      SIGNAL wrch_s_axi_bvalid   : std_logic := '0';
      SIGNAL wrch_m_axi_bready   : std_logic := '0';
      SIGNAL wrch_wr_en          : std_logic := '0';
      SIGNAL wrch_rd_en          : std_logic := '0';
      SIGNAL awvalid_en          : std_logic := '0';
      SIGNAL awready_pkt         : std_logic := '0';
      SIGNAL wdch_we             : STD_LOGIC := '0';
      SIGNAL wr_rst_busy_wach    : std_logic := '0';
      SIGNAL wr_rst_busy_wdch    : std_logic := '0';
      SIGNAL wr_rst_busy_wrch    : std_logic := '0';
      SIGNAL rd_rst_busy_wach    : std_logic := '0';
      SIGNAL rd_rst_busy_wdch    : std_logic := '0';
      SIGNAL rd_rst_busy_wrch    : std_logic := '0';

      CONSTANT AWID_OFFSET       : integer := if_then_else(C_AXI_TYPE /= 2 AND C_HAS_AXI_ID = 1,C_DIN_WIDTH_WACH - C_AXI_ID_WIDTH,C_DIN_WIDTH_WACH);
      CONSTANT AWADDR_OFFSET     : integer := AWID_OFFSET - C_AXI_ADDR_WIDTH;
      CONSTANT AWLEN_OFFSET      : integer := if_then_else(C_AXI_TYPE /= 2,AWADDR_OFFSET - C_AXI_LEN_WIDTH,AWADDR_OFFSET);
      CONSTANT AWSIZE_OFFSET     : integer := if_then_else(C_AXI_TYPE /= 2,AWLEN_OFFSET - C_AXI_SIZE_WIDTH,AWLEN_OFFSET);
      CONSTANT AWBURST_OFFSET    : integer := if_then_else(C_AXI_TYPE /= 2,AWSIZE_OFFSET - C_AXI_BURST_WIDTH,AWSIZE_OFFSET);
      CONSTANT AWLOCK_OFFSET     : integer := if_then_else(C_AXI_TYPE /= 2,AWBURST_OFFSET - C_AXI_LOCK_WIDTH,AWBURST_OFFSET);
      CONSTANT AWCACHE_OFFSET    : integer := if_then_else(C_AXI_TYPE /= 2,AWLOCK_OFFSET - C_AXI_CACHE_WIDTH,AWLOCK_OFFSET);
      CONSTANT AWPROT_OFFSET     : integer := AWCACHE_OFFSET - C_AXI_PROT_WIDTH;
      CONSTANT AWQOS_OFFSET      : integer := AWPROT_OFFSET - C_AXI_QOS_WIDTH;
      CONSTANT AWREGION_OFFSET   : integer := if_then_else(C_AXI_TYPE = 1,AWQOS_OFFSET - C_AXI_REGION_WIDTH, AWQOS_OFFSET);
      CONSTANT AWUSER_OFFSET     : integer := if_then_else(C_HAS_AXI_AWUSER = 1,AWREGION_OFFSET-C_AXI_AWUSER_WIDTH,AWREGION_OFFSET);

      CONSTANT WID_OFFSET        : integer := if_then_else(C_AXI_TYPE = 3 AND C_HAS_AXI_ID = 1,C_DIN_WIDTH_WDCH - C_AXI_ID_WIDTH,C_DIN_WIDTH_WDCH);
      CONSTANT WDATA_OFFSET      : integer := WID_OFFSET - C_AXI_DATA_WIDTH;
      CONSTANT WSTRB_OFFSET      : integer := WDATA_OFFSET - C_AXI_DATA_WIDTH/8;
      CONSTANT WUSER_OFFSET      : integer := if_then_else(C_HAS_AXI_WUSER = 1,WSTRB_OFFSET-C_AXI_WUSER_WIDTH,WSTRB_OFFSET);

      CONSTANT BID_OFFSET        : integer := if_then_else(C_AXI_TYPE /= 2 AND C_HAS_AXI_ID = 1,C_DIN_WIDTH_WRCH - C_AXI_ID_WIDTH,C_DIN_WIDTH_WRCH);
      CONSTANT BRESP_OFFSET      : integer := BID_OFFSET - C_AXI_BRESP_WIDTH;
      CONSTANT BUSER_OFFSET      : integer := if_then_else(C_HAS_AXI_BUSER = 1,BRESP_OFFSET-C_AXI_BUSER_WIDTH,BRESP_OFFSET);

    BEGIN

    -- Form the DIN to FIFO by concatinating the AXI Full Write Address Channel optional ports
      axi_full_din_wr_ch: IF (C_AXI_TYPE /= 2) GENERATE
        gwach1: IF (C_WACH_TYPE < 2) GENERATE
          gwach_din1: IF (C_HAS_AXI_AWUSER = 1) GENERATE
            wach_din(AWREGION_OFFSET-1 DOWNTO AWUSER_OFFSET) <= S_AXI_AWUSER;
            M_AXI_AWUSER <= wach_dout(AWREGION_OFFSET-1 DOWNTO AWUSER_OFFSET);
          END GENERATE gwach_din1;
      
          gwach_din2: IF (C_HAS_AXI_AWUSER = 0) GENERATE
            M_AXI_AWUSER <= (OTHERS => '0');
          END GENERATE gwach_din2;

          gwach_din3: IF (C_HAS_AXI_ID = 1) GENERATE
            wach_din(C_DIN_WIDTH_WACH-1 DOWNTO AWID_OFFSET)  <= S_AXI_AWID;
            M_AXI_AWID      <= wach_dout(C_DIN_WIDTH_WACH-1 DOWNTO AWID_OFFSET);    
          END GENERATE gwach_din3;

          gwach_din4: IF (C_HAS_AXI_ID = 0) GENERATE
            M_AXI_AWID      <= (OTHERS => '0');
          END GENERATE gwach_din4;

          gwach_din5: IF (C_AXI_TYPE = 1) GENERATE
            wach_din(AWQOS_OFFSET-1 DOWNTO AWREGION_OFFSET)  <= S_AXI_AWREGION;
            M_AXI_AWREGION      <= wach_dout(AWQOS_OFFSET-1 DOWNTO AWREGION_OFFSET);    
          END GENERATE gwach_din5;

          gwach_din6: IF (C_AXI_TYPE = 0) GENERATE
            M_AXI_AWREGION      <= (OTHERS => '0');
          END GENERATE gwach_din6;

          wach_din(AWID_OFFSET-1 DOWNTO AWADDR_OFFSET)     <= S_AXI_AWADDR;
          wach_din(AWADDR_OFFSET-1 DOWNTO AWLEN_OFFSET)    <= S_AXI_AWLEN;
          wach_din(AWLEN_OFFSET-1 DOWNTO AWSIZE_OFFSET)    <= S_AXI_AWSIZE;
          wach_din(AWSIZE_OFFSET-1 DOWNTO AWBURST_OFFSET)  <= S_AXI_AWBURST;
          wach_din(AWBURST_OFFSET-1 DOWNTO AWLOCK_OFFSET)  <= S_AXI_AWLOCK;
          wach_din(AWLOCK_OFFSET-1 DOWNTO AWCACHE_OFFSET)  <= S_AXI_AWCACHE;
          wach_din(AWCACHE_OFFSET-1 DOWNTO AWPROT_OFFSET)  <= S_AXI_AWPROT;
          wach_din(AWPROT_OFFSET-1 DOWNTO AWQOS_OFFSET)    <= S_AXI_AWQOS;

          M_AXI_AWADDR    <= wach_dout(AWID_OFFSET-1 DOWNTO AWADDR_OFFSET);    
          M_AXI_AWLEN     <= wach_dout(AWADDR_OFFSET-1 DOWNTO AWLEN_OFFSET);    
          M_AXI_AWSIZE    <= wach_dout(AWLEN_OFFSET-1 DOWNTO AWSIZE_OFFSET);    
          M_AXI_AWBURST   <= wach_dout(AWSIZE_OFFSET-1 DOWNTO AWBURST_OFFSET);    
          M_AXI_AWLOCK    <= wach_dout(AWBURST_OFFSET-1 DOWNTO AWLOCK_OFFSET);    
          M_AXI_AWCACHE   <= wach_dout(AWLOCK_OFFSET-1 DOWNTO AWCACHE_OFFSET);    
          M_AXI_AWPROT    <= wach_dout(AWCACHE_OFFSET-1 DOWNTO AWPROT_OFFSET);    
          M_AXI_AWQOS     <= wach_dout(AWPROT_OFFSET-1 DOWNTO AWQOS_OFFSET);    
        END GENERATE gwach1;
  
        -- Generate the DIN to FIFO by concatinating the AXI Full Write Data Channel optional ports
        gwdch1: IF (C_WDCH_TYPE < 2) GENERATE
          gwdch_din1: IF (C_HAS_AXI_WUSER = 1) GENERATE
            wdch_din(WSTRB_OFFSET-1 DOWNTO WUSER_OFFSET)     <= S_AXI_WUSER;
            M_AXI_WUSER  <= wdch_dout(WSTRB_OFFSET-1 DOWNTO WUSER_OFFSET);
          END GENERATE gwdch_din1;
      
          gwdch_din2: IF (C_HAS_AXI_WUSER = 0) GENERATE
            M_AXI_WUSER <= (OTHERS => '0');
          END GENERATE gwdch_din2;

          gwdch_din3: IF (C_HAS_AXI_ID = 1 AND C_AXI_TYPE = 3) GENERATE
            wdch_din(C_DIN_WIDTH_WDCH-1 DOWNTO WID_OFFSET)  <= S_AXI_WID;
            M_AXI_WID      <= wdch_dout(C_DIN_WIDTH_WDCH-1 DOWNTO WID_OFFSET);    
          END GENERATE gwdch_din3;

          gwdch_din4: IF NOT (C_HAS_AXI_ID = 1 AND C_AXI_TYPE = 3) GENERATE
            M_AXI_WID      <= (OTHERS => '0');
          END GENERATE gwdch_din4;

          wdch_din(WID_OFFSET-1 DOWNTO WDATA_OFFSET)    <= S_AXI_WDATA;
          wdch_din(WDATA_OFFSET-1 DOWNTO WSTRB_OFFSET)    <= S_AXI_WSTRB;
          wdch_din(0)    <= S_AXI_WLAST;
    
          M_AXI_WDATA  <= wdch_dout(WID_OFFSET-1 DOWNTO WDATA_OFFSET);
          M_AXI_WSTRB  <= wdch_dout(WDATA_OFFSET-1 DOWNTO WSTRB_OFFSET);
          M_AXI_WLAST  <= wdch_dout(0);
        END GENERATE gwdch1;
  
        -- Generate the DIN to FIFO by concatinating the AXI Full Write Response Channel optional ports
        gwrch1: IF (C_WRCH_TYPE < 2) GENERATE
          gwrch_din1: IF (C_HAS_AXI_BUSER = 1) GENERATE
            wrch_din(BRESP_OFFSET-1 DOWNTO BUSER_OFFSET)    <= M_AXI_BUSER;
            S_AXI_BUSER <= wrch_dout(BRESP_OFFSET-1 DOWNTO BUSER_OFFSET); 
          END GENERATE gwrch_din1;

          gwrch_din2: IF (C_HAS_AXI_BUSER = 0) GENERATE
            S_AXI_BUSER <= (OTHERS => '0');
          END GENERATE gwrch_din2;

          gwrch_din3: IF (C_HAS_AXI_ID = 1) GENERATE
            wrch_din(C_DIN_WIDTH_WRCH-1 DOWNTO BID_OFFSET)    <= M_AXI_BID;
            S_AXI_BID <= wrch_dout(C_DIN_WIDTH_WRCH-1 DOWNTO BID_OFFSET); 
          END GENERATE gwrch_din3;

          gwrch_din4: IF (C_HAS_AXI_ID = 0) GENERATE
            S_AXI_BID <= (OTHERS => '0');
          END GENERATE gwrch_din4;

          wrch_din(BID_OFFSET-1 DOWNTO BRESP_OFFSET)    <= M_AXI_BRESP;

          S_AXI_BRESP <= wrch_dout(BID_OFFSET-1 DOWNTO BRESP_OFFSET); 
        END GENERATE gwrch1;
  
      END GENERATE axi_full_din_wr_ch;

    -- Form the DIN to FIFO by concatinating the AXI Lite Write Address Channel optional ports
    axi_lite_din_wr_ch: IF (C_AXI_TYPE = 2) GENERATE
      gwach1: IF (C_WACH_TYPE < 2) GENERATE
        wach_din <= S_AXI_AWADDR & S_AXI_AWPROT;
        M_AXI_AWADDR  <= wach_dout(C_DIN_WIDTH_WACH-1 DOWNTO AWADDR_OFFSET);
        M_AXI_AWPROT  <= wach_dout(AWADDR_OFFSET-1 DOWNTO AWPROT_OFFSET);
      END GENERATE gwach1;
      gwdch1: IF (C_WDCH_TYPE < 2) GENERATE
        wdch_din <= S_AXI_WDATA & S_AXI_WSTRB;
        M_AXI_WDATA   <= wdch_dout(C_DIN_WIDTH_WDCH-1 DOWNTO WDATA_OFFSET);
        M_AXI_WSTRB   <= wdch_dout(WDATA_OFFSET-1 DOWNTO WSTRB_OFFSET);
      END GENERATE gwdch1;
      gwrch1: IF (C_WRCH_TYPE < 2) GENERATE
        wrch_din <= M_AXI_BRESP;
        S_AXI_BRESP   <= wrch_dout(C_DIN_WIDTH_WRCH-1 DOWNTO BRESP_OFFSET);
      END GENERATE gwrch1;
    END GENERATE axi_lite_din_wr_ch;

      -- Write protection for Write Address Channel
      -- When FULL is high, pass VALID as a WR_EN to the FIFO to get OVERFLOW interrupt
      gwach_wr_en1: IF (C_PROG_FULL_TYPE_WACH = 0) GENERATE
        wach_wr_en <= S_AXI_AWVALID;
      END GENERATE gwach_wr_en1;
      -- When ALMOST_FULL or PROG_FULL is high, then shield the FIFO from becoming FULL
      gwach_wr_en2: IF (C_PROG_FULL_TYPE_WACH /= 0) GENERATE
        wach_wr_en <= wach_s_axi_awready AND S_AXI_AWVALID;
      END GENERATE gwach_wr_en2;

      -- Write protection for Write Data Channel
      -- When FULL is high, pass VALID as a WR_EN to the FIFO to get OVERFLOW interrupt
      gwdch_wr_en1: IF (C_PROG_FULL_TYPE_WDCH = 0) GENERATE
        wdch_wr_en <= S_AXI_WVALID;
      END GENERATE gwdch_wr_en1;
      --   When ALMOST_FULL or PROG_FULL is high, then shield the FIFO from becoming FULL
      gwdch_wr_en2: IF (C_PROG_FULL_TYPE_WDCH /= 0) GENERATE
        wdch_wr_en <= wdch_s_axi_wready AND S_AXI_WVALID;
      END GENERATE gwdch_wr_en2;

      -- Write protection for Write Response Channel
      -- When FULL is high, pass VALID as a WR_EN to the FIFO to get OVERFLOW interrupt
      gwrch_wr_en1: IF (C_PROG_FULL_TYPE_WRCH = 0) GENERATE
        wrch_wr_en <= M_AXI_BVALID;
      END GENERATE gwrch_wr_en1;
      --   When ALMOST_FULL or PROG_FULL is high, then shield the FIFO from becoming FULL
      gwrch_wr_en2: IF (C_PROG_FULL_TYPE_WRCH /= 0) GENERATE
        wrch_wr_en <= wrch_m_axi_bready AND M_AXI_BVALID;
      END GENERATE gwrch_wr_en2;
  
      -- Read protection for Write Address Channel
      -- When EMPTY is low, pass READY as a RD_EN to the FIFO to get UNDERFLOW interrupt
      gwach_rd_en1: IF (C_PROG_EMPTY_TYPE_WACH = 0) GENERATE
	gpkt_mm_wach_rd_en1: IF (C_APPLICATION_TYPE_WACH = 1) GENERATE
          wach_rd_en <= awready_pkt AND awvalid_en;
  	END GENERATE;
	gnpkt_mm_wach_rd_en1: IF (C_APPLICATION_TYPE_WACH /= 1) GENERATE
          wach_rd_en <= M_AXI_AWREADY;
  	END GENERATE;
      END GENERATE gwach_rd_en1;

      -- When ALMOST_EMPTY or PROG_EMPTY is low, then shield the FIFO from becoming EMPTY
      gwach_rd_en2: IF (C_PROG_EMPTY_TYPE_WACH /= 0) GENERATE
        gaxi_mm_wach_rd_en2: IF (C_APPLICATION_TYPE_WACH = 1) GENERATE
          wach_rd_en <= wach_m_axi_awvalid AND awready_pkt AND awvalid_en;
        END GENERATE gaxi_mm_wach_rd_en2;
        gnaxi_mm_wach_rd_en2: IF (C_APPLICATION_TYPE_WACH /= 1) GENERATE
          wach_rd_en <= wach_m_axi_awvalid AND M_AXI_AWREADY;
        END GENERATE gnaxi_mm_wach_rd_en2;
      END GENERATE gwach_rd_en2;

      -- Read protection for Write Data Channel
      -- When EMPTY is low, pass READY as a RD_EN to the FIFO to get UNDERFLOW interrupt
      gwdch_rd_en1: IF (C_PROG_EMPTY_TYPE_WDCH = 0) GENERATE
        wdch_rd_en <= M_AXI_WREADY;
      END GENERATE gwdch_rd_en1;
      -- When ALMOST_EMPTY or PROG_EMPTY is low, then shield the FIFO from becoming EMPTY
      gwdch_rd_en2: IF (C_PROG_EMPTY_TYPE_WDCH /= 0) GENERATE
        wdch_rd_en <= wdch_m_axi_wvalid AND M_AXI_WREADY;
      END GENERATE gwdch_rd_en2;

      -- Read protection for Write Response Channel
      -- When EMPTY is low, pass READY as a RD_EN to the FIFO to get UNDERFLOW interrupt
      gwrch_rd_en1: IF (C_PROG_EMPTY_TYPE_WRCH = 0) GENERATE
        wrch_rd_en <= S_AXI_BREADY;
      END GENERATE gwrch_rd_en1;
      -- When ALMOST_EMPTY or PROG_EMPTY is low, then shield the FIFO from becoming EMPTY
      gwrch_rd_en2: IF (C_PROG_EMPTY_TYPE_WRCH /= 0) GENERATE
        wrch_rd_en <= wrch_s_axi_bvalid AND S_AXI_BREADY;
      END GENERATE gwrch_rd_en2;
    gwach2: IF (C_WACH_TYPE = 0) GENERATE
      SIGNAL wach_we : STD_LOGIC := '0';
      SIGNAL wach_re : STD_LOGIC := '0';
    BEGIN
      wach_we <= wach_wr_en WHEN (C_HAS_SLAVE_CE = 0) ELSE wach_wr_en AND S_ACLK_EN;
      wach_re <= wach_rd_en WHEN (C_HAS_MASTER_CE = 0) ELSE wach_rd_en AND M_ACLK_EN;

      axi_wach : fifo_generator_v13_0_0_conv
      GENERIC MAP (
          C_FAMILY                          => C_FAMILY,
          C_COMMON_CLOCK                    => C_COMMON_CLOCK,
          C_MEMORY_TYPE                     => if_then_else((C_IMPLEMENTATION_TYPE_WACH = 1  OR C_IMPLEMENTATION_TYPE_WACH = 11),1,
                                               if_then_else((C_IMPLEMENTATION_TYPE_WACH = 2  OR C_IMPLEMENTATION_TYPE_WACH = 12),2,4)),
          C_IMPLEMENTATION_TYPE             => if_then_else((C_IMPLEMENTATION_TYPE_WACH = 1  OR C_IMPLEMENTATION_TYPE_WACH = 2),0,
                                               if_then_else((C_IMPLEMENTATION_TYPE_WACH = 11 OR C_IMPLEMENTATION_TYPE_WACH = 12),2,6)),
          C_PRELOAD_REGS                    => 1, -- Always FWFT for AXI
          C_PRELOAD_LATENCY                 => 0, -- Always FWFT for AXI
          C_DIN_WIDTH                       => C_DIN_WIDTH_WACH,
          C_WR_DEPTH                        => C_WR_DEPTH_WACH,
          C_WR_PNTR_WIDTH                   => C_WR_PNTR_WIDTH_WACH,
          C_DOUT_WIDTH                      => C_DIN_WIDTH_WACH,
          C_RD_DEPTH                        => C_WR_DEPTH_WACH,
          C_RD_PNTR_WIDTH                   => C_WR_PNTR_WIDTH_WACH,
          C_PROG_FULL_TYPE                  => C_PROG_FULL_TYPE_WACH,
          C_PROG_FULL_THRESH_ASSERT_VAL     => C_PROG_FULL_THRESH_ASSERT_VAL_WACH,
          C_PROG_EMPTY_TYPE                 => C_PROG_EMPTY_TYPE_WACH,
          C_PROG_EMPTY_THRESH_ASSERT_VAL    => C_PROG_EMPTY_THRESH_ASSERT_VAL_WACH,
          C_USE_ECC                         => C_USE_ECC_WACH,
          C_ERROR_INJECTION_TYPE            => C_ERROR_INJECTION_TYPE_WACH,
          C_HAS_ALMOST_EMPTY                => 0,
          C_HAS_ALMOST_FULL                 => 0,
          -- Enable Low Latency Sync FIFO for Common Clock Built-in FIFO
          C_FIFO_TYPE                       => if_then_else((C_APPLICATION_TYPE_WACH = 1),0,C_APPLICATION_TYPE_WACH),
          C_SYNCHRONIZER_STAGE              => C_SYNCHRONIZER_STAGE,
          C_AXI_TYPE                        => if_then_else(C_INTERFACE_TYPE = 1, 0, C_AXI_TYPE),
      
          C_HAS_WR_RST                      => 0,
          C_HAS_RD_RST                      => 0,
          C_HAS_RST                         => 1,
          C_HAS_SRST                        => 0,
          C_DOUT_RST_VAL                    => "0",
      
          C_HAS_VALID                       => C_HAS_VALID,
          C_VALID_LOW                       => C_VALID_LOW,
          C_HAS_UNDERFLOW                   => C_HAS_UNDERFLOW,
          C_UNDERFLOW_LOW                   => C_UNDERFLOW_LOW,
          C_HAS_WR_ACK                      => C_HAS_WR_ACK,
          C_WR_ACK_LOW                      => C_WR_ACK_LOW,
          C_HAS_OVERFLOW                    => C_HAS_OVERFLOW,
          C_OVERFLOW_LOW                    => C_OVERFLOW_LOW,
      
          C_HAS_DATA_COUNT                  => if_then_else((C_COMMON_CLOCK = 1 AND C_HAS_DATA_COUNTS_WACH = 1), 1, 0),
          C_DATA_COUNT_WIDTH                => C_WR_PNTR_WIDTH_WACH+1,      
          C_HAS_RD_DATA_COUNT               => if_then_else((C_COMMON_CLOCK = 0 AND C_HAS_DATA_COUNTS_WACH = 1), 1, 0),
          C_RD_DATA_COUNT_WIDTH             => C_WR_PNTR_WIDTH_WACH+1,
          C_USE_FWFT_DATA_COUNT             => 1, -- use extra logic is always true
          C_HAS_WR_DATA_COUNT               => if_then_else((C_COMMON_CLOCK = 0 AND C_HAS_DATA_COUNTS_WACH = 1), 1, 0),
          C_WR_DATA_COUNT_WIDTH             => C_WR_PNTR_WIDTH_WACH+1,
          C_FULL_FLAGS_RST_VAL              => 1,
          C_USE_EMBEDDED_REG                => 0,
          C_USE_DOUT_RST                    => 0,
          C_MSGON_VAL                       => C_MSGON_VAL,
          C_ENABLE_RST_SYNC                 => 1,
          C_EN_SAFETY_CKT                   => 1,
      
          C_COUNT_TYPE                      => C_COUNT_TYPE,
          C_DEFAULT_VALUE                   => C_DEFAULT_VALUE,
          C_ENABLE_RLOCS                    => C_ENABLE_RLOCS,
          C_HAS_BACKUP                      => C_HAS_BACKUP,
          C_HAS_INT_CLK                     => C_HAS_INT_CLK,
          C_HAS_MEMINIT_FILE                => C_HAS_MEMINIT_FILE,
          C_INIT_WR_PNTR_VAL                => C_INIT_WR_PNTR_VAL,
          C_MIF_FILE_NAME                   => C_MIF_FILE_NAME,
          C_OPTIMIZATION_MODE               => C_OPTIMIZATION_MODE,
          C_RD_FREQ                         => C_RD_FREQ,
          C_USE_FIFO16_FLAGS                => C_USE_FIFO16_FLAGS,
          C_WR_FREQ                         => C_WR_FREQ,
          C_WR_RESPONSE_LATENCY             => C_WR_RESPONSE_LATENCY
      
          )
      PORT MAP(
        --Inputs
        BACKUP                    => BACKUP,
        BACKUP_MARKER             => BACKUP_MARKER,
        INT_CLK                   => INT_CLK,
      
        CLK                       => S_ACLK,
        WR_CLK                    => S_ACLK,
        RD_CLK                    => M_ACLK,
        RST                       => inverted_reset,
        SRST                      => '0',
        WR_RST                    => inverted_reset,
        RD_RST                    => inverted_reset,
      
        WR_EN                     => wach_we,
        RD_EN                     => wach_re,
        PROG_FULL_THRESH          => AXI_AW_PROG_FULL_THRESH,
        PROG_FULL_THRESH_ASSERT   => (OTHERS => '0'),
        PROG_FULL_THRESH_NEGATE   => (OTHERS => '0'),
        PROG_EMPTY_THRESH         => AXI_AW_PROG_EMPTY_THRESH,
        PROG_EMPTY_THRESH_ASSERT  => (OTHERS => '0'),
        PROG_EMPTY_THRESH_NEGATE  => (OTHERS => '0'),
        INJECTDBITERR             => AXI_AW_INJECTDBITERR,
        INJECTSBITERR             => AXI_AW_INJECTSBITERR,
      
        DIN                       => wach_din,
        DOUT                      => wach_dout_pkt,
        FULL                      => wach_full,
        EMPTY                     => wach_empty,
        ALMOST_FULL               => OPEN,
        PROG_FULL                 => AXI_AW_PROG_FULL,
        ALMOST_EMPTY              => OPEN,
        PROG_EMPTY                => AXI_AW_PROG_EMPTY,

        WR_ACK                    => OPEN,
        OVERFLOW                  => axi_aw_overflow_i,
        VALID                     => OPEN,
        UNDERFLOW                 => axi_aw_underflow_i,
        DATA_COUNT                => AXI_AW_DATA_COUNT,
        RD_DATA_COUNT             => AXI_AW_RD_DATA_COUNT,
        WR_DATA_COUNT             => AXI_AW_WR_DATA_COUNT,
        SBITERR                   => AXI_AW_SBITERR,
        DBITERR                   => AXI_AW_DBITERR,
        WR_RST_BUSY               => wr_rst_busy_wach,
        RD_RST_BUSY               => rd_rst_busy_wach, 
        WR_RST_I_OUT                  => OPEN,
        RD_RST_I_OUT                  => OPEN
        );

        g8s_wach_rdy: IF (IS_8SERIES = 1) GENERATE
          g8s_bi_wach_rdy: IF (C_IMPLEMENTATION_TYPE_WACH = 5 OR C_IMPLEMENTATION_TYPE_WACH = 13) GENERATE
            wach_s_axi_awready   <= NOT (wach_full OR wr_rst_busy_wach);
          END GENERATE g8s_bi_wach_rdy;
          g8s_nbi_wach_rdy: IF (NOT (C_IMPLEMENTATION_TYPE_WACH = 5 OR C_IMPLEMENTATION_TYPE_WACH = 13)) GENERATE
            wach_s_axi_awready   <= NOT (wach_full);
          END GENERATE g8s_nbi_wach_rdy;
        END GENERATE g8s_wach_rdy;
        g7s_wach_rdy: IF (IS_8SERIES = 0) GENERATE
          wach_s_axi_awready   <= NOT (wach_full);
        END GENERATE g7s_wach_rdy;

      wach_m_axi_awvalid   <= NOT wach_empty;
      S_AXI_AWREADY        <= wach_s_axi_awready;
      
      gawvld_pkt_fifo: IF (C_APPLICATION_TYPE_WACH = 1) GENERATE
          SIGNAL awvalid_pkt     : STD_LOGIC := '0';
        BEGIN
          awvalid_pkt <= wach_m_axi_awvalid AND awvalid_en;

          wach_pkt_reg_slice: fifo_generator_v13_0_0_axic_reg_slice
            GENERIC MAP (
              C_FAMILY                          => C_FAMILY,
              C_DATA_WIDTH                      => C_DIN_WIDTH_WACH,
              C_REG_CONFIG                      => 1
              )
            PORT MAP(
              -- System Signals
              ACLK                      => S_ACLK,
              ARESET                    => inverted_reset,

              -- Slave side
              S_PAYLOAD_DATA            => wach_dout_pkt,
              S_VALID                   => awvalid_pkt,
              S_READY                   => awready_pkt,

              -- Master side
              M_PAYLOAD_DATA            => wach_dout,
              M_VALID                   => M_AXI_AWVALID,
              M_READY                   => M_AXI_AWREADY
              );
        END GENERATE gawvld_pkt_fifo;

      gnawvld_pkt_fifo: IF (C_APPLICATION_TYPE_WACH /= 1) GENERATE
    	M_AXI_AWVALID        <= wach_m_axi_awvalid;
	wach_dout            <= wach_dout_pkt;
      END GENERATE gnawvld_pkt_fifo;

      gaxi_wr_ch_uf1: IF (C_USE_COMMON_UNDERFLOW = 0) GENERATE
        AXI_AW_UNDERFLOW <= axi_aw_underflow_i; 
      END GENERATE gaxi_wr_ch_uf1;

      gaxi_wr_ch_of1: IF (C_USE_COMMON_OVERFLOW = 0) GENERATE
        AXI_AW_OVERFLOW <= axi_aw_overflow_i; 
      END GENERATE gaxi_wr_ch_of1;
    END GENERATE gwach2;

      -- Register Slice for Write Address Channel
      gwach_reg_slice: IF (C_WACH_TYPE = 1) GENERATE
        wach_reg_slice: fifo_generator_v13_0_0_axic_reg_slice
          GENERIC MAP (
            C_FAMILY                          => C_FAMILY,
            C_DATA_WIDTH                      => C_DIN_WIDTH_WACH,
            C_REG_CONFIG                      => C_REG_SLICE_MODE_WACH
            )
        PORT MAP(
          -- System Signals
          ACLK                      => S_ACLK,
          ARESET                    => axi_rs_rst,
  
          -- Slave side
          S_PAYLOAD_DATA            => wach_din,
          S_VALID                   => S_AXI_AWVALID,
          S_READY                   => S_AXI_AWREADY,
  
          -- Master side
          M_PAYLOAD_DATA            => wach_dout,
          M_VALID                   => M_AXI_AWVALID,
          M_READY                   => M_AXI_AWREADY
          );
      END GENERATE gwach_reg_slice;

    gwdch2: IF (C_WDCH_TYPE = 0) GENERATE
      SIGNAL wdch_re : STD_LOGIC := '0';
    BEGIN
      wdch_we <= wdch_wr_en WHEN (C_HAS_SLAVE_CE = 0) ELSE wdch_wr_en AND S_ACLK_EN;
      wdch_re <= wdch_rd_en WHEN (C_HAS_MASTER_CE = 0) ELSE wdch_rd_en AND M_ACLK_EN;


      axi_wdch : fifo_generator_v13_0_0_conv
      GENERIC MAP (
          C_FAMILY                          => C_FAMILY,
          C_COMMON_CLOCK                    => C_COMMON_CLOCK,
          C_MEMORY_TYPE                     => if_then_else((C_IMPLEMENTATION_TYPE_WDCH = 1  OR C_IMPLEMENTATION_TYPE_WDCH = 11),1,
                                               if_then_else((C_IMPLEMENTATION_TYPE_WDCH = 2  OR C_IMPLEMENTATION_TYPE_WDCH = 12),2,4)),
          C_IMPLEMENTATION_TYPE             => if_then_else((C_IMPLEMENTATION_TYPE_WDCH = 1  OR C_IMPLEMENTATION_TYPE_WDCH = 2),0,
                                               if_then_else((C_IMPLEMENTATION_TYPE_WDCH = 11 OR C_IMPLEMENTATION_TYPE_WDCH = 12),2,6)),
          C_PRELOAD_REGS                    => 1, -- Always FWFT for AXI
          C_PRELOAD_LATENCY                 => 0, -- Always FWFT for AXI
          C_DIN_WIDTH                       => C_DIN_WIDTH_WDCH,
          C_WR_DEPTH                        => C_WR_DEPTH_WDCH,
          C_WR_PNTR_WIDTH                   => C_WR_PNTR_WIDTH_WDCH,
          C_DOUT_WIDTH                      => C_DIN_WIDTH_WDCH,
          C_RD_DEPTH                        => C_WR_DEPTH_WDCH,
          C_RD_PNTR_WIDTH                   => C_WR_PNTR_WIDTH_WDCH,
          C_PROG_FULL_TYPE                  => C_PROG_FULL_TYPE_WDCH,
          C_PROG_FULL_THRESH_ASSERT_VAL     => C_PROG_FULL_THRESH_ASSERT_VAL_WDCH,
          C_PROG_EMPTY_TYPE                 => C_PROG_EMPTY_TYPE_WDCH,
          C_PROG_EMPTY_THRESH_ASSERT_VAL    => C_PROG_EMPTY_THRESH_ASSERT_VAL_WDCH,
          C_USE_ECC                         => C_USE_ECC_WDCH,
          C_ERROR_INJECTION_TYPE            => C_ERROR_INJECTION_TYPE_WDCH,
          C_HAS_ALMOST_EMPTY                => 0,
          C_HAS_ALMOST_FULL                 => 0,
          -- Enable Low Latency Sync FIFO for Common Clock Built-in FIFO
          C_FIFO_TYPE                       => C_APPLICATION_TYPE_WDCH,
          C_SYNCHRONIZER_STAGE              => C_SYNCHRONIZER_STAGE,
          C_AXI_TYPE                        => if_then_else(C_INTERFACE_TYPE = 1, 0, C_AXI_TYPE),
      
          C_HAS_WR_RST                      => 0,
          C_HAS_RD_RST                      => 0,
          C_HAS_RST                         => 1,
          C_HAS_SRST                        => 0,
          C_DOUT_RST_VAL                    => "0",
      
          C_HAS_VALID                       => C_HAS_VALID,
          C_VALID_LOW                       => C_VALID_LOW,
          C_HAS_UNDERFLOW                   => C_HAS_UNDERFLOW,
          C_UNDERFLOW_LOW                   => C_UNDERFLOW_LOW,
          C_HAS_WR_ACK                      => C_HAS_WR_ACK,
          C_WR_ACK_LOW                      => C_WR_ACK_LOW,
          C_HAS_OVERFLOW                    => C_HAS_OVERFLOW,
          C_OVERFLOW_LOW                    => C_OVERFLOW_LOW,
      
          C_HAS_DATA_COUNT                  => if_then_else((C_COMMON_CLOCK = 1 AND C_HAS_DATA_COUNTS_WDCH = 1), 1, 0),
          C_DATA_COUNT_WIDTH                => C_WR_PNTR_WIDTH_WDCH+1,      
          C_HAS_RD_DATA_COUNT               => if_then_else((C_COMMON_CLOCK = 0 AND C_HAS_DATA_COUNTS_WDCH = 1), 1, 0),
          C_RD_DATA_COUNT_WIDTH             => C_WR_PNTR_WIDTH_WDCH+1,
          C_USE_FWFT_DATA_COUNT             => 1, -- use extra logic is always true
          C_HAS_WR_DATA_COUNT               => if_then_else((C_COMMON_CLOCK = 0 AND C_HAS_DATA_COUNTS_WDCH = 1), 1, 0),
          C_WR_DATA_COUNT_WIDTH             => C_WR_PNTR_WIDTH_WDCH+1,
          C_FULL_FLAGS_RST_VAL              => 1,
          C_USE_EMBEDDED_REG                => 0,
          C_USE_DOUT_RST                    => 0,
          C_MSGON_VAL                       => C_MSGON_VAL,
          C_ENABLE_RST_SYNC                 => 1,
          C_EN_SAFETY_CKT                   => 1,
      
          C_COUNT_TYPE                      => C_COUNT_TYPE,
          C_DEFAULT_VALUE                   => C_DEFAULT_VALUE,
          C_ENABLE_RLOCS                    => C_ENABLE_RLOCS,
          C_HAS_BACKUP                      => C_HAS_BACKUP,
          C_HAS_INT_CLK                     => C_HAS_INT_CLK,
          C_HAS_MEMINIT_FILE                => C_HAS_MEMINIT_FILE,
          C_INIT_WR_PNTR_VAL                => C_INIT_WR_PNTR_VAL,
          C_MIF_FILE_NAME                   => C_MIF_FILE_NAME,
          C_OPTIMIZATION_MODE               => C_OPTIMIZATION_MODE,
          C_RD_FREQ                         => C_RD_FREQ,
          C_USE_FIFO16_FLAGS                => C_USE_FIFO16_FLAGS,
          C_WR_FREQ                         => C_WR_FREQ,
          C_WR_RESPONSE_LATENCY             => C_WR_RESPONSE_LATENCY
      
          )
      PORT MAP(
        --Inputs
        BACKUP                    => BACKUP,
        BACKUP_MARKER             => BACKUP_MARKER,
        INT_CLK                   => INT_CLK,
      
        CLK                       => S_ACLK,
        WR_CLK                    => S_ACLK,
        RD_CLK                    => M_ACLK,
        RST                       => inverted_reset,
        SRST                      => '0',
        WR_RST                    => inverted_reset,
        RD_RST                    => inverted_reset,
      
        WR_EN                     => wdch_we,
        RD_EN                     => wdch_re,
        PROG_FULL_THRESH          => AXI_W_PROG_FULL_THRESH,
        PROG_FULL_THRESH_ASSERT   => (OTHERS => '0'),
        PROG_FULL_THRESH_NEGATE   => (OTHERS => '0'),
        PROG_EMPTY_THRESH         => AXI_W_PROG_EMPTY_THRESH,
        PROG_EMPTY_THRESH_ASSERT  => (OTHERS => '0'),
        PROG_EMPTY_THRESH_NEGATE  => (OTHERS => '0'),
        INJECTDBITERR             => AXI_W_INJECTDBITERR,
        INJECTSBITERR             => AXI_W_INJECTSBITERR,
      
        DIN                       => wdch_din,
        DOUT                      => wdch_dout,
        FULL                      => wdch_full,
        EMPTY                     => wdch_empty,
        ALMOST_FULL               => OPEN,
        PROG_FULL                 => AXI_W_PROG_FULL,
        ALMOST_EMPTY              => OPEN,
        PROG_EMPTY                => AXI_W_PROG_EMPTY,
      
        WR_ACK                    => OPEN,
        OVERFLOW                  => axi_w_overflow_i,
        VALID                     => OPEN,
        UNDERFLOW                 => axi_w_underflow_i,
        DATA_COUNT                => AXI_W_DATA_COUNT,
        RD_DATA_COUNT             => AXI_W_RD_DATA_COUNT,
        WR_DATA_COUNT             => AXI_W_WR_DATA_COUNT,
        SBITERR                   => AXI_W_SBITERR,
        DBITERR                   => AXI_W_DBITERR,
        WR_RST_BUSY               => wr_rst_busy_wdch,
        RD_RST_BUSY               => rd_rst_busy_wdch, 
        WR_RST_I_OUT                  => OPEN,
        RD_RST_I_OUT                  => OPEN
        );

        g8s_wdch_rdy: IF (IS_8SERIES = 1) GENERATE
          g8s_bi_wdch_rdy: IF (C_IMPLEMENTATION_TYPE_WDCH = 5 OR C_IMPLEMENTATION_TYPE_WDCH = 13) GENERATE
            wdch_s_axi_wready    <= NOT (wdch_full OR wr_rst_busy_wdch);
          END GENERATE g8s_bi_wdch_rdy;
          g8s_nbi_wdch_rdy: IF (NOT (C_IMPLEMENTATION_TYPE_WDCH = 5 OR C_IMPLEMENTATION_TYPE_WDCH = 13)) GENERATE
            wdch_s_axi_wready    <= NOT (wdch_full);
          END GENERATE g8s_nbi_wdch_rdy;
        END GENERATE g8s_wdch_rdy;
        g7s_wdch_rdy: IF (IS_8SERIES = 0) GENERATE
          wdch_s_axi_wready    <= NOT (wdch_full);
        END GENERATE g7s_wdch_rdy;

      wdch_m_axi_wvalid    <= NOT wdch_empty;
      S_AXI_WREADY         <= wdch_s_axi_wready;
      M_AXI_WVALID         <= wdch_m_axi_wvalid;

      gaxi_wr_ch_uf2: IF (C_USE_COMMON_UNDERFLOW = 0) GENERATE
        AXI_W_UNDERFLOW  <= axi_w_underflow_i; 
      END GENERATE gaxi_wr_ch_uf2;

      gaxi_wr_ch_of2: IF (C_USE_COMMON_OVERFLOW = 0) GENERATE
        AXI_W_OVERFLOW  <= axi_w_overflow_i; 
      END GENERATE gaxi_wr_ch_of2;
    END GENERATE gwdch2;
  
      -- Register Slice for Write Data Channel
      gwdch_reg_slice: IF (C_WDCH_TYPE = 1) GENERATE
        wdch_reg_slice: fifo_generator_v13_0_0_axic_reg_slice
          GENERIC MAP (
            C_FAMILY                          => C_FAMILY,
            C_DATA_WIDTH                      => C_DIN_WIDTH_WDCH,
            C_REG_CONFIG                      => C_REG_SLICE_MODE_WDCH
            )
        PORT MAP(
          -- System Signals
          ACLK                      => S_ACLK,
          ARESET                    => axi_rs_rst,
  
          -- Slave side
          S_PAYLOAD_DATA            => wdch_din,
          S_VALID                   => S_AXI_WVALID,
          S_READY                   => S_AXI_WREADY,
  
          -- Master side
          M_PAYLOAD_DATA            => wdch_dout,
          M_VALID                   => M_AXI_WVALID,
          M_READY                   => M_AXI_WREADY
          );
      END GENERATE gwdch_reg_slice;
  

    gwrch2: IF (C_WRCH_TYPE = 0) GENERATE
      SIGNAL wrch_we : STD_LOGIC := '0';
      SIGNAL wrch_re : STD_LOGIC := '0';
    BEGIN
      wrch_we <= wrch_wr_en WHEN (C_HAS_MASTER_CE = 0) ELSE wrch_wr_en AND M_ACLK_EN;
      wrch_re <= wrch_rd_en WHEN (C_HAS_SLAVE_CE = 0) ELSE wrch_rd_en AND S_ACLK_EN;


      axi_wrch : fifo_generator_v13_0_0_conv -- Write Response Channel
      GENERIC MAP (
          C_FAMILY                          => C_FAMILY,
          C_COMMON_CLOCK                    => C_COMMON_CLOCK,
          C_MEMORY_TYPE                     => if_then_else((C_IMPLEMENTATION_TYPE_WRCH = 1  OR C_IMPLEMENTATION_TYPE_WRCH = 11),1,
                                               if_then_else((C_IMPLEMENTATION_TYPE_WRCH = 2  OR C_IMPLEMENTATION_TYPE_WRCH = 12),2,4)),
          C_IMPLEMENTATION_TYPE             => if_then_else((C_IMPLEMENTATION_TYPE_WRCH = 1  OR C_IMPLEMENTATION_TYPE_WRCH = 2),0,
                                               if_then_else((C_IMPLEMENTATION_TYPE_WRCH = 11 OR C_IMPLEMENTATION_TYPE_WRCH = 12),2,6)),
          C_PRELOAD_REGS                    => 1, -- Always FWFT for AXI
          C_PRELOAD_LATENCY                 => 0, -- Always FWFT for AXI
          C_DIN_WIDTH                       => C_DIN_WIDTH_WRCH,
          C_WR_DEPTH                        => C_WR_DEPTH_WRCH,
          C_WR_PNTR_WIDTH                   => C_WR_PNTR_WIDTH_WRCH,
          C_DOUT_WIDTH                      => C_DIN_WIDTH_WRCH,
          C_RD_DEPTH                        => C_WR_DEPTH_WRCH,
          C_RD_PNTR_WIDTH                   => C_WR_PNTR_WIDTH_WRCH,
          C_PROG_FULL_TYPE                  => C_PROG_FULL_TYPE_WRCH,
          C_PROG_FULL_THRESH_ASSERT_VAL     => C_PROG_FULL_THRESH_ASSERT_VAL_WRCH,
          C_PROG_EMPTY_TYPE                 => C_PROG_EMPTY_TYPE_WRCH,
          C_PROG_EMPTY_THRESH_ASSERT_VAL    => C_PROG_EMPTY_THRESH_ASSERT_VAL_WRCH,
          C_USE_ECC                         => C_USE_ECC_WRCH,
          C_ERROR_INJECTION_TYPE            => C_ERROR_INJECTION_TYPE_WRCH,
          C_HAS_ALMOST_EMPTY                => 0,
          C_HAS_ALMOST_FULL                 => 0,
          -- Enable Low Latency Sync FIFO for Common Clock Built-in FIFO
          C_FIFO_TYPE                       => C_APPLICATION_TYPE_WRCH,
          C_SYNCHRONIZER_STAGE              => C_SYNCHRONIZER_STAGE,
          C_AXI_TYPE                        => if_then_else(C_INTERFACE_TYPE = 1, 0, C_AXI_TYPE),
      
          C_HAS_WR_RST                      => 0,
          C_HAS_RD_RST                      => 0,
          C_HAS_RST                         => 1,
          C_HAS_SRST                        => 0,
          C_DOUT_RST_VAL                    => "0",
      
          C_HAS_VALID                       => C_HAS_VALID,
          C_VALID_LOW                       => C_VALID_LOW,
          C_HAS_UNDERFLOW                   => C_HAS_UNDERFLOW,
          C_UNDERFLOW_LOW                   => C_UNDERFLOW_LOW,
          C_HAS_WR_ACK                      => C_HAS_WR_ACK,
          C_WR_ACK_LOW                      => C_WR_ACK_LOW,
          C_HAS_OVERFLOW                    => C_HAS_OVERFLOW,
          C_OVERFLOW_LOW                    => C_OVERFLOW_LOW,
      
          C_HAS_DATA_COUNT                  => if_then_else((C_COMMON_CLOCK = 1 AND C_HAS_DATA_COUNTS_WRCH = 1), 1, 0),
          C_DATA_COUNT_WIDTH                => C_WR_PNTR_WIDTH_WRCH+1,      
          C_HAS_RD_DATA_COUNT               => if_then_else((C_COMMON_CLOCK = 0 AND C_HAS_DATA_COUNTS_WRCH = 1), 1, 0),
          C_RD_DATA_COUNT_WIDTH             => C_WR_PNTR_WIDTH_WRCH+1,
          C_USE_FWFT_DATA_COUNT             => 1, -- use extra logic is always true
          C_HAS_WR_DATA_COUNT               => if_then_else((C_COMMON_CLOCK = 0 AND C_HAS_DATA_COUNTS_WRCH = 1), 1, 0),
          C_WR_DATA_COUNT_WIDTH             => C_WR_PNTR_WIDTH_WRCH+1,
          C_FULL_FLAGS_RST_VAL              => 1,
          C_USE_EMBEDDED_REG                => 0,
          C_USE_DOUT_RST                    => 0,
          C_MSGON_VAL                       => C_MSGON_VAL,
          C_ENABLE_RST_SYNC                 => 1,
          C_EN_SAFETY_CKT                   => 1,
      
          C_COUNT_TYPE                      => C_COUNT_TYPE,
          C_DEFAULT_VALUE                   => C_DEFAULT_VALUE,
          C_ENABLE_RLOCS                    => C_ENABLE_RLOCS,
          C_HAS_BACKUP                      => C_HAS_BACKUP,
          C_HAS_INT_CLK                     => C_HAS_INT_CLK,
          C_HAS_MEMINIT_FILE                => C_HAS_MEMINIT_FILE,
          C_INIT_WR_PNTR_VAL                => C_INIT_WR_PNTR_VAL,
          C_MIF_FILE_NAME                   => C_MIF_FILE_NAME,
          C_OPTIMIZATION_MODE               => C_OPTIMIZATION_MODE,
          C_RD_FREQ                         => C_RD_FREQ,
          C_USE_FIFO16_FLAGS                => C_USE_FIFO16_FLAGS,
          C_WR_FREQ                         => C_WR_FREQ,
          C_WR_RESPONSE_LATENCY             => C_WR_RESPONSE_LATENCY
      
          )
      PORT MAP(
        --Inputs
        BACKUP                    => BACKUP,
        BACKUP_MARKER             => BACKUP_MARKER,
        INT_CLK                   => INT_CLK,
      
        CLK                       => S_ACLK,
        WR_CLK                    => M_ACLK,
        RD_CLK                    => S_ACLK,
        RST                       => inverted_reset,
        SRST                      => '0',
        WR_RST                    => inverted_reset,
        RD_RST                    => inverted_reset,
      
        WR_EN                     => wrch_we,
        RD_EN                     => wrch_re,
        PROG_FULL_THRESH          => AXI_B_PROG_FULL_THRESH,
        PROG_FULL_THRESH_ASSERT   => (OTHERS => '0'),
        PROG_FULL_THRESH_NEGATE   => (OTHERS => '0'),
        PROG_EMPTY_THRESH         => AXI_B_PROG_EMPTY_THRESH,
        PROG_EMPTY_THRESH_ASSERT  => (OTHERS => '0'),
        PROG_EMPTY_THRESH_NEGATE  => (OTHERS => '0'),
        INJECTDBITERR             => AXI_B_INJECTDBITERR,
        INJECTSBITERR             => AXI_B_INJECTSBITERR,
      
        DIN                       => wrch_din,
        DOUT                      => wrch_dout,
        FULL                      => wrch_full,
        EMPTY                     => wrch_empty,
        ALMOST_FULL               => OPEN,
        PROG_FULL                 => AXI_B_PROG_FULL,
        ALMOST_EMPTY              => OPEN,
        PROG_EMPTY                => AXI_B_PROG_EMPTY,
      
        WR_ACK                    => OPEN,
        OVERFLOW                  => axi_b_overflow_i,
        VALID                     => OPEN,
        UNDERFLOW                 => axi_b_underflow_i,
        DATA_COUNT                => AXI_B_DATA_COUNT,
        RD_DATA_COUNT             => AXI_B_RD_DATA_COUNT,
        WR_DATA_COUNT             => AXI_B_WR_DATA_COUNT,
        SBITERR                   => AXI_B_SBITERR,
        DBITERR                   => AXI_B_DBITERR,
        WR_RST_BUSY               => wr_rst_busy_wrch,
        RD_RST_BUSY               => rd_rst_busy_wrch, 
        WR_RST_I_OUT                  => OPEN,
        RD_RST_I_OUT                  => OPEN
        );

      wrch_s_axi_bvalid    <= NOT wrch_empty;
        g8s_wrch_rdy: IF (IS_8SERIES = 1) GENERATE
          g8s_bi_wrch_rdy: IF (C_IMPLEMENTATION_TYPE_WRCH = 5 OR C_IMPLEMENTATION_TYPE_WRCH = 13) GENERATE
            wrch_m_axi_bready    <= NOT (wrch_full OR wr_rst_busy_wrch);
          END GENERATE g8s_bi_wrch_rdy;
          g8s_nbi_wrch_rdy: IF (NOT (C_IMPLEMENTATION_TYPE_WRCH = 5 OR C_IMPLEMENTATION_TYPE_WRCH = 13)) GENERATE
            wrch_m_axi_bready    <= NOT (wrch_full);
          END GENERATE g8s_nbi_wrch_rdy;
        END GENERATE g8s_wrch_rdy;
        g7s_wrch_rdy: IF (IS_8SERIES = 0) GENERATE
          wrch_m_axi_bready    <= NOT (wrch_full);
        END GENERATE g7s_wrch_rdy;

      S_AXI_BVALID         <= wrch_s_axi_bvalid;
      M_AXI_BREADY         <= wrch_m_axi_bready;

      gaxi_wr_ch_uf3: IF (C_USE_COMMON_UNDERFLOW = 0) GENERATE
        AXI_B_UNDERFLOW  <= axi_b_underflow_i; 
      END GENERATE gaxi_wr_ch_uf3;

      gaxi_wr_ch_of3: IF (C_USE_COMMON_OVERFLOW = 0) GENERATE
        AXI_B_OVERFLOW  <= axi_b_overflow_i; 
      END GENERATE gaxi_wr_ch_of3;

    END GENERATE gwrch2;
  
      -- Register Slice for Write Response Channel
      gwrch_reg_slice: IF (C_WRCH_TYPE = 1) GENERATE
        wrch_reg_slice: fifo_generator_v13_0_0_axic_reg_slice
          GENERIC MAP (
            C_FAMILY                          => C_FAMILY,
            C_DATA_WIDTH                      => C_DIN_WIDTH_WRCH,
            C_REG_CONFIG                      => C_REG_SLICE_MODE_WRCH
            )
        PORT MAP(
          -- System Signals
          ACLK                      => S_ACLK,
          ARESET                    => axi_rs_rst,
  
          -- Slave side
          S_PAYLOAD_DATA            => wrch_din,
          S_VALID                   => M_AXI_BVALID,
          S_READY                   => M_AXI_BREADY,
  
          -- Master side
          M_PAYLOAD_DATA            => wrch_dout,
          M_VALID                   => S_AXI_BVALID,
          M_READY                   => S_AXI_BREADY
          );
      END GENERATE gwrch_reg_slice;

      gaxi_wr_ch_uf4: IF (C_USE_COMMON_UNDERFLOW = 1) GENERATE
        axi_wr_underflow_i <= axi_aw_underflow_i OR axi_w_underflow_i OR axi_b_underflow_i; 
      END GENERATE gaxi_wr_ch_uf4;

      gaxi_wr_ch_of4: IF (C_USE_COMMON_OVERFLOW = 1) GENERATE
        axi_wr_overflow_i <= axi_aw_overflow_i OR axi_w_overflow_i OR axi_b_overflow_i; 
      END GENERATE gaxi_wr_ch_of4;

      gaxi_pkt_fifo_wr: IF (C_APPLICATION_TYPE_WACH = 1) GENERATE
        SIGNAL wr_pkt_count      : STD_LOGIC_VECTOR(C_WR_PNTR_WIDTH_WDCH DOWNTO 0) := (OTHERS => '0');
        SIGNAL txn_count_en_up   : STD_LOGIC := '0';
        SIGNAL txn_count_en_down : STD_LOGIC := '0';
      BEGIN
        txn_count_en_up   <= wdch_s_axi_wready AND wdch_we AND wdch_din(0);
        txn_count_en_down <= wach_m_axi_awvalid AND awready_pkt AND awvalid_en;

        gaxi_mm_cc_pkt_wr: IF (C_COMMON_CLOCK = 1) GENERATE
          proc_wr_txn_cnt: PROCESS (S_ACLK, inverted_reset)
          BEGIN
            IF (inverted_reset = '1') THEN
              wr_pkt_count   <= (OTHERS => '0');
            ELSIF (S_ACLK'EVENT AND S_ACLK = '1') THEN
              IF (txn_count_en_up = '1' AND txn_count_en_down = '0') THEN
                wr_pkt_count <= wr_pkt_count + conv_std_logic_vector(1,C_WR_PNTR_WIDTH_WDCH+1);
              ELSIF (txn_count_en_down = '1' AND txn_count_en_up = '0') THEN
                wr_pkt_count <= wr_pkt_count - conv_std_logic_vector(1,C_WR_PNTR_WIDTH_WDCH+1);
              END IF;
            END IF;
          END PROCESS proc_wr_txn_cnt;
          awvalid_en <= '1' WHEN (wr_pkt_count > conv_std_logic_vector(0,C_WR_PNTR_WIDTH_WDCH)) ELSE '0';
        END GENERATE gaxi_mm_cc_pkt_wr;
      END GENERATE gaxi_pkt_fifo_wr;


    END GENERATE gwrch;



    grdch: IF (C_HAS_AXI_RD_CHANNEL = 1) GENERATE
      SIGNAL rach_din            : std_logic_vector(C_DIN_WIDTH_RACH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL rach_dout           : std_logic_vector(C_DIN_WIDTH_RACH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL rach_dout_pkt       : std_logic_vector(C_DIN_WIDTH_RACH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL rach_full           : std_logic := '0';
      SIGNAL rach_almost_full    : std_logic := '0';
      SIGNAL rach_prog_full      : std_logic := '0';
      SIGNAL rach_empty          : std_logic := '0';
      SIGNAL rach_almost_empty   : std_logic := '0';
      SIGNAL rach_prog_empty     : std_logic := '0';
      SIGNAL rdch_din            : std_logic_vector(C_DIN_WIDTH_RDCH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL rdch_dout           : std_logic_vector(C_DIN_WIDTH_RDCH-1 DOWNTO 0) := (OTHERS => '0');
      SIGNAL rdch_full           : std_logic := '0';
      SIGNAL rdch_almost_full    : std_logic := '0';
      SIGNAL rdch_prog_full      : std_logic := '0';
      SIGNAL rdch_empty          : std_logic := '0';
      SIGNAL rdch_almost_empty   : std_logic := '0';
      SIGNAL rdch_prog_empty     : std_logic := '0';
      SIGNAL axi_ar_underflow_i  : std_logic := '0';
      SIGNAL axi_ar_overflow_i   : std_logic := '0';
      SIGNAL axi_r_underflow_i   : std_logic := '0';
      SIGNAL axi_r_overflow_i    : std_logic := '0';
      SIGNAL rach_s_axi_arready  : std_logic := '0';
      SIGNAL rach_m_axi_arvalid  : std_logic := '0';
      SIGNAL rach_wr_en          : std_logic := '0';
      SIGNAL rach_rd_en          : std_logic := '0';
      SIGNAL rdch_m_axi_rready   : std_logic := '0';
      SIGNAL rdch_s_axi_rvalid   : std_logic := '0';
      SIGNAL rdch_wr_en          : std_logic := '0';
      SIGNAL rdch_rd_en          : std_logic := '0';
      SIGNAL arvalid_en          : std_logic := '0';
      SIGNAL arready_pkt         : std_logic := '0';
      SIGNAL rdch_re             : STD_LOGIC := '0';
      SIGNAL wr_rst_busy_rach    : STD_LOGIC := '0';
      SIGNAL wr_rst_busy_rdch    : STD_LOGIC := '0';
      SIGNAL rd_rst_busy_rach    : STD_LOGIC := '0';
      SIGNAL rd_rst_busy_rdch    : STD_LOGIC := '0';

      CONSTANT ARID_OFFSET       : integer := if_then_else(C_AXI_TYPE /= 2 AND C_HAS_AXI_ID = 1,C_DIN_WIDTH_RACH - C_AXI_ID_WIDTH,C_DIN_WIDTH_RACH);
      CONSTANT ARADDR_OFFSET     : integer := ARID_OFFSET - C_AXI_ADDR_WIDTH;
      CONSTANT ARLEN_OFFSET      : integer := if_then_else(C_AXI_TYPE /= 2,ARADDR_OFFSET - C_AXI_LEN_WIDTH,ARADDR_OFFSET);
      CONSTANT ARSIZE_OFFSET     : integer := if_then_else(C_AXI_TYPE /= 2,ARLEN_OFFSET - C_AXI_SIZE_WIDTH,ARLEN_OFFSET);
      CONSTANT ARBURST_OFFSET    : integer := if_then_else(C_AXI_TYPE /= 2,ARSIZE_OFFSET - C_AXI_BURST_WIDTH,ARSIZE_OFFSET);
      CONSTANT ARLOCK_OFFSET     : integer := if_then_else(C_AXI_TYPE /= 2,ARBURST_OFFSET - C_AXI_LOCK_WIDTH,ARBURST_OFFSET);
      CONSTANT ARCACHE_OFFSET    : integer := if_then_else(C_AXI_TYPE /= 2,ARLOCK_OFFSET - C_AXI_CACHE_WIDTH,ARLOCK_OFFSET);
      CONSTANT ARPROT_OFFSET     : integer := ARCACHE_OFFSET - C_AXI_PROT_WIDTH;
      CONSTANT ARQOS_OFFSET      : integer := ARPROT_OFFSET - C_AXI_QOS_WIDTH;
      CONSTANT ARREGION_OFFSET   : integer := if_then_else(C_AXI_TYPE = 1,ARQOS_OFFSET - C_AXI_REGION_WIDTH,ARQOS_OFFSET);
      CONSTANT ARUSER_OFFSET     : integer := if_then_else(C_HAS_AXI_ARUSER = 1,ARREGION_OFFSET-C_AXI_ARUSER_WIDTH,ARREGION_OFFSET);

      CONSTANT RID_OFFSET        : integer := if_then_else(C_AXI_TYPE /= 2 AND C_HAS_AXI_ID = 1,C_DIN_WIDTH_RDCH - C_AXI_ID_WIDTH,C_DIN_WIDTH_RDCH);
      CONSTANT RDATA_OFFSET      : integer := RID_OFFSET - C_AXI_DATA_WIDTH;
      CONSTANT RRESP_OFFSET      : integer := RDATA_OFFSET - C_AXI_RRESP_WIDTH;
      CONSTANT RUSER_OFFSET      : integer := if_then_else(C_HAS_AXI_RUSER = 1,RRESP_OFFSET-C_AXI_RUSER_WIDTH,RRESP_OFFSET);

    BEGIN

      -- Form the DIN to FIFO by concatinating the AXI Full Write Address Channel optional ports
      axi_full_din_rd_ch: IF (C_AXI_TYPE /= 2) GENERATE
        grach1: IF (C_RACH_TYPE < 2) GENERATE
          grach_din1: IF (C_HAS_AXI_ARUSER = 1) GENERATE
            rach_din(ARREGION_OFFSET-1 DOWNTO ARUSER_OFFSET) <= S_AXI_ARUSER;
            M_AXI_ARUSER <= rach_dout(ARREGION_OFFSET-1 DOWNTO ARUSER_OFFSET);
          END GENERATE grach_din1;
      
          grach_din2: IF (C_HAS_AXI_ARUSER = 0) GENERATE
            M_AXI_ARUSER <= (OTHERS => '0');
          END GENERATE grach_din2;

          grach_din3: IF (C_HAS_AXI_ID = 1) GENERATE
            rach_din(C_DIN_WIDTH_RACH-1 DOWNTO ARID_OFFSET) <= S_AXI_ARID;
            M_AXI_ARID <= rach_dout(C_DIN_WIDTH_RACH-1 DOWNTO ARID_OFFSET);
          END GENERATE grach_din3;
      
          grach_din4: IF (C_HAS_AXI_ID = 0) GENERATE
            M_AXI_ARID <= (OTHERS => '0');
          END GENERATE grach_din4;

          grach_din5: IF (C_AXI_TYPE = 1) GENERATE
            rach_din(ARQOS_OFFSET-1 DOWNTO ARREGION_OFFSET) <=  S_AXI_ARREGION;
            M_AXI_ARREGION <= rach_dout(ARQOS_OFFSET-1 DOWNTO ARREGION_OFFSET);
          END GENERATE grach_din5;
      
          grach_din6: IF (C_AXI_TYPE = 0) GENERATE
            M_AXI_ARREGION <= (OTHERS => '0');
          END GENERATE grach_din6;

          rach_din(ARID_OFFSET-1 DOWNTO ARADDR_OFFSET)     <= S_AXI_ARADDR;
          rach_din(ARADDR_OFFSET-1 DOWNTO ARLEN_OFFSET)    <= S_AXI_ARLEN;
          rach_din(ARLEN_OFFSET-1 DOWNTO ARSIZE_OFFSET)    <= S_AXI_ARSIZE;
          rach_din(ARSIZE_OFFSET-1 DOWNTO ARBURST_OFFSET)  <= S_AXI_ARBURST;
          rach_din(ARBURST_OFFSET-1 DOWNTO ARLOCK_OFFSET)  <= S_AXI_ARLOCK;
          rach_din(ARLOCK_OFFSET-1 DOWNTO ARCACHE_OFFSET)  <= S_AXI_ARCACHE;
          rach_din(ARCACHE_OFFSET-1 DOWNTO ARPROT_OFFSET)  <= S_AXI_ARPROT;
          rach_din(ARPROT_OFFSET-1 DOWNTO ARQOS_OFFSET)    <= S_AXI_ARQOS;

          M_AXI_ARADDR    <= rach_dout(ARID_OFFSET-1 DOWNTO ARADDR_OFFSET);    
          M_AXI_ARLEN     <= rach_dout(ARADDR_OFFSET-1 DOWNTO ARLEN_OFFSET);    
          M_AXI_ARSIZE    <= rach_dout(ARLEN_OFFSET-1 DOWNTO ARSIZE_OFFSET);    
          M_AXI_ARBURST   <= rach_dout(ARSIZE_OFFSET-1 DOWNTO ARBURST_OFFSET);    
          M_AXI_ARLOCK    <= rach_dout(ARBURST_OFFSET-1 DOWNTO ARLOCK_OFFSET);    
          M_AXI_ARCACHE   <= rach_dout(ARLOCK_OFFSET-1 DOWNTO ARCACHE_OFFSET);    
          M_AXI_ARPROT    <= rach_dout(ARCACHE_OFFSET-1 DOWNTO ARPROT_OFFSET);    
          M_AXI_ARQOS     <= rach_dout(ARPROT_OFFSET-1 DOWNTO ARQOS_OFFSET);    
        END GENERATE grach1;
    
          -- Generate the DIN to FIFO by concatinating the AXI Full Write Data Channel optional ports
        grdch1: IF (C_RDCH_TYPE < 2) GENERATE
          grdch_din1: IF (C_HAS_AXI_RUSER = 1) GENERATE
            rdch_din(RRESP_OFFSET-1 DOWNTO RUSER_OFFSET)     <= M_AXI_RUSER;
            S_AXI_RUSER  <= rdch_dout(RRESP_OFFSET-1 DOWNTO RUSER_OFFSET);
          END GENERATE grdch_din1;
      
          grdch_din2: IF (C_HAS_AXI_RUSER = 0) GENERATE
            S_AXI_RUSER <= (OTHERS => '0');
          END GENERATE grdch_din2;

          grdch_din3: IF (C_HAS_AXI_ID = 1) GENERATE
            rdch_din(C_DIN_WIDTH_RDCH-1 DOWNTO RID_OFFSET) <= M_AXI_RID;
            S_AXI_RID  <= rdch_dout(C_DIN_WIDTH_RDCH-1 DOWNTO RID_OFFSET);
          END GENERATE grdch_din3;
      
          grdch_din4: IF (C_HAS_AXI_ID = 0) GENERATE
            S_AXI_RID <= (OTHERS => '0');
          END GENERATE grdch_din4;

          rdch_din(RID_OFFSET-1 DOWNTO RDATA_OFFSET)   <= M_AXI_RDATA;
          rdch_din(RDATA_OFFSET-1 DOWNTO RRESP_OFFSET) <= M_AXI_RRESP;
          rdch_din(0)    <= M_AXI_RLAST;
    
          S_AXI_RDATA  <= rdch_dout(RID_OFFSET-1 DOWNTO RDATA_OFFSET);
          S_AXI_RRESP  <= rdch_dout(RDATA_OFFSET-1 DOWNTO RRESP_OFFSET);
          S_AXI_RLAST  <= rdch_dout(0);
        END GENERATE grdch1;
  
      END GENERATE axi_full_din_rd_ch;

      -- Form the DIN to FIFO by concatinating the AXI Lite Read Address Channel optional ports
      axi_lite_din_rd_ch: IF (C_AXI_TYPE = 2) GENERATE
        grach1: IF (C_RACH_TYPE < 2) GENERATE
          rach_din <= S_AXI_ARADDR & S_AXI_ARPROT;
          M_AXI_ARADDR  <= rach_dout(C_DIN_WIDTH_RACH-1 DOWNTO ARADDR_OFFSET);
          M_AXI_ARPROT  <= rach_dout(ARADDR_OFFSET-1 DOWNTO ARPROT_OFFSET);
        END GENERATE grach1;

        grdch1: IF (C_RDCH_TYPE < 2) GENERATE
          rdch_din <= M_AXI_RDATA & M_AXI_RRESP;
          S_AXI_RDATA   <= rdch_dout(C_DIN_WIDTH_RDCH-1 DOWNTO RDATA_OFFSET);
          S_AXI_RRESP   <= rdch_dout(RDATA_OFFSET-1 DOWNTO RRESP_OFFSET);
        END GENERATE grdch1;
      END GENERATE axi_lite_din_rd_ch;

      -- Write protection for Read Address Channel
      -- When FULL is high, pass VALID as a WR_EN to the FIFO to get OVERFLOW interrupt
      grach_wr_en1: IF (C_PROG_FULL_TYPE_RACH = 0) GENERATE
        rach_wr_en <= S_AXI_ARVALID;
      END GENERATE grach_wr_en1;
      -- When ALMOST_FULL or PROG_FULL is high, then shield the FIFO from becoming FULL
      grach_wr_en2: IF (C_PROG_FULL_TYPE_RACH /= 0) GENERATE
        rach_wr_en <= rach_s_axi_arready AND S_AXI_ARVALID;
      END GENERATE grach_wr_en2;

      -- Write protection for Read Data Channel
      -- When FULL is high, pass VALID as a WR_EN to the FIFO to get OVERFLOW interrupt
      grdch_wr_en1: IF (C_PROG_FULL_TYPE_RDCH = 0) GENERATE
        rdch_wr_en <= M_AXI_RVALID;
      END GENERATE grdch_wr_en1;
      --   When ALMOST_FULL or PROG_FULL is high, then shield the FIFO from becoming FULL
      grdch_wr_en2: IF (C_PROG_FULL_TYPE_RDCH /= 0) GENERATE
        rdch_wr_en <= rdch_m_axi_rready AND M_AXI_RVALID;
      END GENERATE grdch_wr_en2;

      -- Read protection for Read Address Channel
      -- When EMPTY is low, pass READY as a RD_EN to the FIFO to get UNDERFLOW interrupt
      grach_rd_en1: IF (C_PROG_EMPTY_TYPE_RACH = 0) GENERATE
	gpkt_mm_rach_rd_en1: IF (C_APPLICATION_TYPE_RACH = 1) GENERATE
          rach_rd_en <= arready_pkt AND arvalid_en;
	END GENERATE;
	gnpkt_mm_rach_rd_en1: IF (C_APPLICATION_TYPE_RACH /= 1) GENERATE
  	  rach_rd_en <= M_AXI_ARREADY;
	END GENERATE;
      END GENERATE grach_rd_en1;

      -- When ALMOST_EMPTY or PROG_EMPTY is low, then shield the FIFO from becoming EMPTY
      grach_rd_en2: IF (C_PROG_EMPTY_TYPE_RACH /= 0) GENERATE
        gaxi_mm_rach_rd_en2: IF (C_APPLICATION_TYPE_RACH = 1) GENERATE
          rach_rd_en <= rach_m_axi_arvalid AND arready_pkt AND arvalid_en;
        END GENERATE gaxi_mm_rach_rd_en2;
        gnaxi_mm_rach_rd_en2: IF (C_APPLICATION_TYPE_RACH /= 1) GENERATE
          rach_rd_en <= rach_m_axi_arvalid AND M_AXI_ARREADY;
        END GENERATE gnaxi_mm_rach_rd_en2;
      END GENERATE grach_rd_en2;

      -- Read protection for Read Data Channel
      -- When EMPTY is low, pass READY as a RD_EN to the FIFO to get UNDERFLOW interrupt
      grdch_rd_en1: IF (C_PROG_EMPTY_TYPE_RDCH = 0) GENERATE
        rdch_rd_en <= S_AXI_RREADY;
      END GENERATE grdch_rd_en1;
      -- When ALMOST_EMPTY or PROG_EMPTY is low, then shield the FIFO from becoming EMPTY
      grdch_rd_en2: IF (C_PROG_EMPTY_TYPE_RDCH /= 0) GENERATE
        rdch_rd_en <= rdch_s_axi_rvalid AND S_AXI_RREADY;
      END GENERATE grdch_rd_en2;

      grach2: IF (C_RACH_TYPE = 0) GENERATE
        SIGNAL rach_we : STD_LOGIC := '0';
        SIGNAL rach_re : STD_LOGIC := '0';
      BEGIN
        rach_we <= rach_wr_en WHEN (C_HAS_SLAVE_CE = 0) ELSE rach_wr_en AND S_ACLK_EN;
        rach_re <= rach_rd_en WHEN (C_HAS_MASTER_CE = 0) ELSE rach_rd_en AND M_ACLK_EN;

        axi_rach : fifo_generator_v13_0_0_conv
        GENERIC MAP (
            C_FAMILY                          => C_FAMILY,
            C_COMMON_CLOCK                    => C_COMMON_CLOCK,
            C_MEMORY_TYPE                     => if_then_else((C_IMPLEMENTATION_TYPE_RACH = 1  OR C_IMPLEMENTATION_TYPE_RACH = 11),1,
                                                 if_then_else((C_IMPLEMENTATION_TYPE_RACH = 2  OR C_IMPLEMENTATION_TYPE_RACH = 12),2,4)),
            C_IMPLEMENTATION_TYPE             => if_then_else((C_IMPLEMENTATION_TYPE_RACH = 1  OR C_IMPLEMENTATION_TYPE_RACH = 2),0,
                                                 if_then_else((C_IMPLEMENTATION_TYPE_RACH = 11 OR C_IMPLEMENTATION_TYPE_RACH = 12),2,6)),
            C_PRELOAD_REGS                    => 1, -- Always FWFT for AXI
            C_PRELOAD_LATENCY                 => 0, -- Always FWFT for AXI
            C_DIN_WIDTH                       => C_DIN_WIDTH_RACH,
            C_WR_DEPTH                        => C_WR_DEPTH_RACH,
            C_WR_PNTR_WIDTH                   => C_WR_PNTR_WIDTH_RACH,
            C_DOUT_WIDTH                      => C_DIN_WIDTH_RACH,
            C_RD_DEPTH                        => C_WR_DEPTH_RACH,
            C_RD_PNTR_WIDTH                   => C_WR_PNTR_WIDTH_RACH,
            C_PROG_FULL_TYPE                  => C_PROG_FULL_TYPE_RACH,
            C_PROG_FULL_THRESH_ASSERT_VAL     => C_PROG_FULL_THRESH_ASSERT_VAL_RACH,
            C_PROG_EMPTY_TYPE                 => C_PROG_EMPTY_TYPE_RACH,
            C_PROG_EMPTY_THRESH_ASSERT_VAL    => C_PROG_EMPTY_THRESH_ASSERT_VAL_RACH,
            C_USE_ECC                         => C_USE_ECC_RACH,
            C_ERROR_INJECTION_TYPE            => C_ERROR_INJECTION_TYPE_RACH,
            C_HAS_ALMOST_EMPTY                => 0,
            C_HAS_ALMOST_FULL                 => 0,
            -- Enable Low Latency Sync FIFO for Common Clock Built-in FIFO
	    C_FIFO_TYPE                       => if_then_else((C_APPLICATION_TYPE_RACH = 1),0,C_APPLICATION_TYPE_RACH),
            C_SYNCHRONIZER_STAGE              => C_SYNCHRONIZER_STAGE,
            C_AXI_TYPE                        => if_then_else(C_INTERFACE_TYPE = 1, 0, C_AXI_TYPE),

            C_HAS_WR_RST                      => 0,
            C_HAS_RD_RST                      => 0,
            C_HAS_RST                         => 1,
            C_HAS_SRST                        => 0,
            C_DOUT_RST_VAL                    => "0",

            C_HAS_VALID                       => C_HAS_VALID,
            C_VALID_LOW                       => C_VALID_LOW,
            C_HAS_UNDERFLOW                   => C_HAS_UNDERFLOW,
            C_UNDERFLOW_LOW                   => C_UNDERFLOW_LOW,
            C_HAS_WR_ACK                      => C_HAS_WR_ACK,
            C_WR_ACK_LOW                      => C_WR_ACK_LOW,
            C_HAS_OVERFLOW                    => C_HAS_OVERFLOW,
            C_OVERFLOW_LOW                    => C_OVERFLOW_LOW,

            C_HAS_DATA_COUNT                  => if_then_else((C_COMMON_CLOCK = 1 AND C_HAS_DATA_COUNTS_RACH = 1), 1, 0),
            C_DATA_COUNT_WIDTH                => C_WR_PNTR_WIDTH_RACH+1,      
            C_HAS_RD_DATA_COUNT               => if_then_else((C_COMMON_CLOCK = 0 AND C_HAS_DATA_COUNTS_RACH = 1), 1, 0),
            C_RD_DATA_COUNT_WIDTH             => C_WR_PNTR_WIDTH_RACH+1,
            C_USE_FWFT_DATA_COUNT             => 1, -- use extra logic is always true
            C_HAS_WR_DATA_COUNT               => if_then_else((C_COMMON_CLOCK = 0 AND C_HAS_DATA_COUNTS_RACH = 1), 1, 0),
            C_WR_DATA_COUNT_WIDTH             => C_WR_PNTR_WIDTH_RACH+1,
            C_FULL_FLAGS_RST_VAL              => 1,
            C_USE_EMBEDDED_REG                => 0,
            C_USE_DOUT_RST                    => 0,
            C_MSGON_VAL                       => C_MSGON_VAL,
            C_ENABLE_RST_SYNC                 => 1,
            C_EN_SAFETY_CKT                   => 1,

            C_COUNT_TYPE                      => C_COUNT_TYPE,
            C_DEFAULT_VALUE                   => C_DEFAULT_VALUE,
            C_ENABLE_RLOCS                    => C_ENABLE_RLOCS,
            C_HAS_BACKUP                      => C_HAS_BACKUP,
            C_HAS_INT_CLK                     => C_HAS_INT_CLK,
            C_HAS_MEMINIT_FILE                => C_HAS_MEMINIT_FILE,
            C_INIT_WR_PNTR_VAL                => C_INIT_WR_PNTR_VAL,
            C_MIF_FILE_NAME                   => C_MIF_FILE_NAME,
            C_OPTIMIZATION_MODE               => C_OPTIMIZATION_MODE,
            C_WR_FREQ                         => C_WR_FREQ,
            C_USE_FIFO16_FLAGS                => C_USE_FIFO16_FLAGS,
            C_RD_FREQ                         => C_RD_FREQ,
            C_WR_RESPONSE_LATENCY             => C_WR_RESPONSE_LATENCY

            )
        PORT MAP(
          --Inputs
          BACKUP                    => BACKUP,
          BACKUP_MARKER             => BACKUP_MARKER,
          INT_CLK                   => INT_CLK,

          CLK                       => S_ACLK,
          WR_CLK                    => S_ACLK,
          RD_CLK                    => M_ACLK,
          RST                       => inverted_reset,
          SRST                      => '0',
          WR_RST                    => inverted_reset,
          RD_RST                    => inverted_reset,

          WR_EN                     => rach_we,
          RD_EN                     => rach_re,
          PROG_FULL_THRESH          => AXI_AR_PROG_FULL_THRESH,
          PROG_FULL_THRESH_ASSERT   => (OTHERS => '0'),
          PROG_FULL_THRESH_NEGATE   => (OTHERS => '0'),
          PROG_EMPTY_THRESH         => AXI_AR_PROG_EMPTY_THRESH,
          PROG_EMPTY_THRESH_ASSERT  => (OTHERS => '0'),
          PROG_EMPTY_THRESH_NEGATE  => (OTHERS => '0'),
          INJECTDBITERR             => AXI_AR_INJECTDBITERR,
          INJECTSBITERR             => AXI_AR_INJECTSBITERR,

          DIN                       => rach_din,
          DOUT                      => rach_dout_pkt,
          FULL                      => rach_full,
          EMPTY                     => rach_empty,
          ALMOST_FULL               => OPEN,
          PROG_FULL                 => AXI_AR_PROG_FULL,
          ALMOST_EMPTY              => OPEN,
          PROG_EMPTY                => AXI_AR_PROG_EMPTY,

          WR_ACK                    => OPEN,
          OVERFLOW                  => axi_ar_overflow_i,
          VALID                     => OPEN,
          UNDERFLOW                 => axi_ar_underflow_i,
          DATA_COUNT                => AXI_AR_DATA_COUNT,
          RD_DATA_COUNT             => AXI_AR_RD_DATA_COUNT,
          WR_DATA_COUNT             => AXI_AR_WR_DATA_COUNT,
          SBITERR                   => AXI_AR_SBITERR,
          DBITERR                   => AXI_AR_DBITERR,
          WR_RST_BUSY               => wr_rst_busy_rach,
          RD_RST_BUSY               => rd_rst_busy_rach, 
          WR_RST_I_OUT                  => OPEN,
          RD_RST_I_OUT                  => OPEN
          );

        g8s_rach_rdy: IF (IS_8SERIES = 1) GENERATE
          g8s_bi_rach_rdy: IF (C_IMPLEMENTATION_TYPE_RACH = 5 OR C_IMPLEMENTATION_TYPE_RACH = 13) GENERATE
            rach_s_axi_arready   <= NOT (rach_full OR wr_rst_busy_rach);
          END GENERATE g8s_bi_rach_rdy;
          g8s_nbi_rach_rdy: IF (NOT (C_IMPLEMENTATION_TYPE_RACH = 5 OR C_IMPLEMENTATION_TYPE_RACH = 13)) GENERATE
            rach_s_axi_arready   <= NOT (rach_full);
          END GENERATE g8s_nbi_rach_rdy;
        END GENERATE g8s_rach_rdy;
        g7s_rach_rdy: IF (IS_8SERIES = 0) GENERATE
          rach_s_axi_arready   <= NOT (rach_full);
        END GENERATE g7s_rach_rdy;

        rach_m_axi_arvalid   <= NOT rach_empty;
        S_AXI_ARREADY        <= rach_s_axi_arready;
        
	gaxi_arvld: IF (C_APPLICATION_TYPE_RACH = 1) GENERATE
          SIGNAL arvalid_pkt     : STD_LOGIC := '0';
        BEGIN
          arvalid_pkt <= rach_m_axi_arvalid AND arvalid_en;

          rach_pkt_reg_slice: fifo_generator_v13_0_0_axic_reg_slice
            GENERIC MAP (
              C_FAMILY                          => C_FAMILY,
              C_DATA_WIDTH                      => C_DIN_WIDTH_RACH,
              C_REG_CONFIG                      => 1
              )
            PORT MAP(
              -- System Signals
              ACLK                      => S_ACLK,
              ARESET                    => inverted_reset,

              -- Slave side
              S_PAYLOAD_DATA            => rach_dout_pkt,
              S_VALID                   => arvalid_pkt,
              S_READY                   => arready_pkt,

              -- Master side
              M_PAYLOAD_DATA            => rach_dout,
              M_VALID                   => M_AXI_ARVALID,
              M_READY                   => M_AXI_ARREADY
              );

        END GENERATE gaxi_arvld;

        gnaxi_arvld: IF (C_APPLICATION_TYPE_RACH /= 1) GENERATE
          M_AXI_ARVALID <= rach_m_axi_arvalid;
	  rach_dout     <= rach_dout_pkt;
        END GENERATE gnaxi_arvld;

        gaxi_rd_ch_uf1: IF (C_USE_COMMON_UNDERFLOW = 0) GENERATE
          AXI_AR_UNDERFLOW <= axi_ar_underflow_i; 
        END GENERATE gaxi_rd_ch_uf1;

        gaxi_rd_ch_of1: IF (C_USE_COMMON_OVERFLOW = 0) GENERATE
          AXI_AR_OVERFLOW <= axi_ar_overflow_i; 
        END GENERATE gaxi_rd_ch_of1;
      END GENERATE grach2;

        -- Register Slice for Read Address Channel
      grach_reg_slice: IF (C_RACH_TYPE = 1) GENERATE
        rach_reg_slice: fifo_generator_v13_0_0_axic_reg_slice
          GENERIC MAP (
            C_FAMILY                          => C_FAMILY,
            C_DATA_WIDTH                      => C_DIN_WIDTH_RACH,
            C_REG_CONFIG                      => C_REG_SLICE_MODE_RACH
            )
        PORT MAP(
          -- System Signals
          ACLK                      => S_ACLK,
          ARESET                    => axi_rs_rst,

          -- Slave side
          S_PAYLOAD_DATA            => rach_din,
          S_VALID                   => S_AXI_ARVALID,
          S_READY                   => S_AXI_ARREADY,

          -- Master side
          M_PAYLOAD_DATA            => rach_dout,
          M_VALID                   => M_AXI_ARVALID,
          M_READY                   => M_AXI_ARREADY
          );
      END GENERATE grach_reg_slice;


      grdch2: IF (C_RDCH_TYPE = 0) GENERATE
        SIGNAL rdch_we : STD_LOGIC := '0';
      BEGIN
        rdch_we <= rdch_wr_en WHEN (C_HAS_MASTER_CE = 0) ELSE rdch_wr_en AND M_ACLK_EN;
        rdch_re <= rdch_rd_en WHEN (C_HAS_SLAVE_CE = 0) ELSE rdch_rd_en AND S_ACLK_EN;

        axi_rdch : fifo_generator_v13_0_0_conv
        GENERIC MAP (
            C_FAMILY                          => C_FAMILY,
            C_COMMON_CLOCK                    => C_COMMON_CLOCK,
            C_MEMORY_TYPE                     => if_then_else((C_IMPLEMENTATION_TYPE_RDCH = 1  OR C_IMPLEMENTATION_TYPE_RDCH = 11),1,
                                                 if_then_else((C_IMPLEMENTATION_TYPE_RDCH = 2  OR C_IMPLEMENTATION_TYPE_RDCH = 12),2,4)),
            C_IMPLEMENTATION_TYPE             => if_then_else((C_IMPLEMENTATION_TYPE_RDCH = 1  OR C_IMPLEMENTATION_TYPE_RDCH = 2),0,
                                                 if_then_else((C_IMPLEMENTATION_TYPE_RDCH = 11 OR C_IMPLEMENTATION_TYPE_RDCH = 12),2,6)),
            C_PRELOAD_REGS                    => 1, -- Always FWFT for AXI
            C_PRELOAD_LATENCY                 => 0, -- Always FWFT for AXI
            C_DIN_WIDTH                       => C_DIN_WIDTH_RDCH,
            C_WR_DEPTH                        => C_WR_DEPTH_RDCH,
            C_WR_PNTR_WIDTH                   => C_WR_PNTR_WIDTH_RDCH,
            C_DOUT_WIDTH                      => C_DIN_WIDTH_RDCH,
            C_RD_DEPTH                        => C_WR_DEPTH_RDCH,
            C_RD_PNTR_WIDTH                   => C_WR_PNTR_WIDTH_RDCH,
            C_PROG_FULL_TYPE                  => C_PROG_FULL_TYPE_RDCH,
            C_PROG_FULL_THRESH_ASSERT_VAL     => C_PROG_FULL_THRESH_ASSERT_VAL_RDCH,
            C_PROG_EMPTY_TYPE                 => C_PROG_EMPTY_TYPE_RDCH,
            C_PROG_EMPTY_THRESH_ASSERT_VAL    => C_PROG_EMPTY_THRESH_ASSERT_VAL_RDCH,
            C_USE_ECC                         => C_USE_ECC_RDCH,
            C_ERROR_INJECTION_TYPE            => C_ERROR_INJECTION_TYPE_RDCH,
            C_HAS_ALMOST_EMPTY                => 0,
            C_HAS_ALMOST_FULL                 => 0,
            -- Enable Low Latency Sync FIFO for Common Clock Built-in FIFO
	    C_FIFO_TYPE                       => C_APPLICATION_TYPE_RDCH,
            C_SYNCHRONIZER_STAGE              => C_SYNCHRONIZER_STAGE,
            C_AXI_TYPE                        => if_then_else(C_INTERFACE_TYPE = 1, 0, C_AXI_TYPE),

            C_HAS_WR_RST                      => 0,
            C_HAS_RD_RST                      => 0,
            C_HAS_RST                         => 1,
            C_HAS_SRST                        => 0,
            C_DOUT_RST_VAL                    => "0",

            C_HAS_VALID                       => C_HAS_VALID,
            C_VALID_LOW                       => C_VALID_LOW,
            C_HAS_UNDERFLOW                   => C_HAS_UNDERFLOW,
            C_UNDERFLOW_LOW                   => C_UNDERFLOW_LOW,
            C_HAS_WR_ACK                      => C_HAS_WR_ACK,
            C_WR_ACK_LOW                      => C_WR_ACK_LOW,
            C_HAS_OVERFLOW                    => C_HAS_OVERFLOW,
            C_OVERFLOW_LOW                    => C_OVERFLOW_LOW,

            C_HAS_DATA_COUNT                  => if_then_else((C_COMMON_CLOCK = 1 AND C_HAS_DATA_COUNTS_RDCH = 1), 1, 0),
            C_DATA_COUNT_WIDTH                => C_WR_PNTR_WIDTH_RDCH+1,      
            C_HAS_RD_DATA_COUNT               => if_then_else((C_COMMON_CLOCK = 0 AND C_HAS_DATA_COUNTS_RDCH = 1), 1, 0),
            C_RD_DATA_COUNT_WIDTH             => C_WR_PNTR_WIDTH_RDCH+1,
            C_USE_FWFT_DATA_COUNT             => 1, -- use extra logic is always true
            C_HAS_WR_DATA_COUNT               => if_then_else((C_COMMON_CLOCK = 0 AND C_HAS_DATA_COUNTS_RDCH = 1), 1, 0),
            C_WR_DATA_COUNT_WIDTH             => C_WR_PNTR_WIDTH_RDCH+1,
            C_FULL_FLAGS_RST_VAL              => 1,
            C_USE_EMBEDDED_REG                => 0,
            C_USE_DOUT_RST                    => 0,
            C_MSGON_VAL                       => C_MSGON_VAL,
            C_ENABLE_RST_SYNC                 => 1,
            C_EN_SAFETY_CKT                   => 1,

            C_COUNT_TYPE                      => C_COUNT_TYPE,
            C_DEFAULT_VALUE                   => C_DEFAULT_VALUE,
            C_ENABLE_RLOCS                    => C_ENABLE_RLOCS,
            C_HAS_BACKUP                      => C_HAS_BACKUP,
            C_HAS_INT_CLK                     => C_HAS_INT_CLK,
            C_HAS_MEMINIT_FILE                => C_HAS_MEMINIT_FILE,
            C_INIT_WR_PNTR_VAL                => C_INIT_WR_PNTR_VAL,
            C_MIF_FILE_NAME                   => C_MIF_FILE_NAME,
            C_OPTIMIZATION_MODE               => C_OPTIMIZATION_MODE,
            C_WR_FREQ                         => C_WR_FREQ,
            C_USE_FIFO16_FLAGS                => C_USE_FIFO16_FLAGS,
            C_RD_FREQ                         => C_RD_FREQ,
            C_WR_RESPONSE_LATENCY             => C_WR_RESPONSE_LATENCY

            )
        PORT MAP(
          --Inputs
          BACKUP                    => BACKUP,
          BACKUP_MARKER             => BACKUP_MARKER,
          INT_CLK                   => INT_CLK,

          CLK                       => S_ACLK,
          WR_CLK                    => M_ACLK,
          RD_CLK                    => S_ACLK,
          RST                       => inverted_reset,
          SRST                      => '0',
          WR_RST                    => inverted_reset,
          RD_RST                    => inverted_reset,

          WR_EN                     => rdch_we,
          RD_EN                     => rdch_re,
          PROG_FULL_THRESH          => AXI_R_PROG_FULL_THRESH,
          PROG_FULL_THRESH_ASSERT   => (OTHERS => '0'),
          PROG_FULL_THRESH_NEGATE   => (OTHERS => '0'),
          PROG_EMPTY_THRESH         => AXI_R_PROG_EMPTY_THRESH,
          PROG_EMPTY_THRESH_ASSERT  => (OTHERS => '0'),
          PROG_EMPTY_THRESH_NEGATE  => (OTHERS => '0'),
          INJECTDBITERR             => AXI_R_INJECTDBITERR,
          INJECTSBITERR             => AXI_R_INJECTSBITERR,

          DIN                       => rdch_din,
          DOUT                      => rdch_dout,
          FULL                      => rdch_full,
          EMPTY                     => rdch_empty,
          ALMOST_FULL               => OPEN,
          PROG_FULL                 => AXI_R_PROG_FULL,
          ALMOST_EMPTY              => OPEN,
          PROG_EMPTY                => AXI_R_PROG_EMPTY,

          WR_ACK                    => OPEN,
          OVERFLOW                  => axi_r_overflow_i,
          VALID                     => OPEN,
          UNDERFLOW                 => axi_r_underflow_i,
          DATA_COUNT                => AXI_R_DATA_COUNT,
          RD_DATA_COUNT             => AXI_R_RD_DATA_COUNT,
          WR_DATA_COUNT             => AXI_R_WR_DATA_COUNT,
          SBITERR                   => AXI_R_SBITERR,
          DBITERR                   => AXI_R_DBITERR,
          WR_RST_BUSY               => wr_rst_busy_rdch,
          RD_RST_BUSY               => rd_rst_busy_rdch, 
          WR_RST_I_OUT                  => OPEN,
          RD_RST_I_OUT                  => OPEN
          );
  
        rdch_s_axi_rvalid    <= NOT rdch_empty;

        g8s_rdch_rdy: IF (IS_8SERIES = 1) GENERATE
          g8s_bi_rdch_rdy: IF (C_IMPLEMENTATION_TYPE_RDCH = 5 OR C_IMPLEMENTATION_TYPE_RDCH = 13) GENERATE
            rdch_m_axi_rready    <= NOT (rdch_full OR wr_rst_busy_rdch);
          END GENERATE g8s_bi_rdch_rdy;
          g8s_nbi_rdch_rdy: IF (NOT (C_IMPLEMENTATION_TYPE_RDCH = 5 OR C_IMPLEMENTATION_TYPE_RDCH = 13)) GENERATE
            rdch_m_axi_rready    <= NOT (rdch_full);
          END GENERATE g8s_nbi_rdch_rdy;
        END GENERATE g8s_rdch_rdy;
        g7s_rdch_rdy: IF (IS_8SERIES = 0) GENERATE
          rdch_m_axi_rready    <= NOT (rdch_full);
        END GENERATE g7s_rdch_rdy;
        S_AXI_RVALID         <= rdch_s_axi_rvalid;
        M_AXI_RREADY         <= rdch_m_axi_rready;

        gaxi_rd_ch_uf2: IF (C_USE_COMMON_UNDERFLOW = 0) GENERATE
          AXI_R_UNDERFLOW  <= axi_r_underflow_i; 
        END GENERATE gaxi_rd_ch_uf2;

        gaxi_rd_ch_of2: IF (C_USE_COMMON_OVERFLOW = 0) GENERATE
          AXI_R_OVERFLOW  <= axi_r_overflow_i; 
        END GENERATE gaxi_rd_ch_of2;

      END GENERATE grdch2;

      -- Register Slice for Read Data Channel
      grdch_reg_slice: IF (C_RDCH_TYPE = 1) GENERATE
        rdch_reg_slice: fifo_generator_v13_0_0_axic_reg_slice
          GENERIC MAP (
            C_FAMILY                          => C_FAMILY,
            C_DATA_WIDTH                      => C_DIN_WIDTH_RDCH,
            C_REG_CONFIG                      => C_REG_SLICE_MODE_RDCH
            )
        PORT MAP(
          -- System Signals
          ACLK                      => S_ACLK,
          ARESET                    => axi_rs_rst,

          -- Slave side
          S_PAYLOAD_DATA            => rdch_din,
          S_VALID                   => M_AXI_RVALID,
          S_READY                   => M_AXI_RREADY,

          -- Master side
          M_PAYLOAD_DATA            => rdch_dout,
          M_VALID                   => S_AXI_RVALID,
          M_READY                   => S_AXI_RREADY
          );
      END GENERATE grdch_reg_slice;

      gaxi_rd_ch_uf3: IF (C_USE_COMMON_UNDERFLOW = 1) GENERATE
        axi_rd_underflow_i <= axi_ar_underflow_i OR axi_r_underflow_i; 
      END GENERATE gaxi_rd_ch_uf3;

      gaxi_rd_ch_of3: IF (C_USE_COMMON_OVERFLOW = 1) GENERATE
        axi_rd_overflow_i <= axi_ar_overflow_i OR axi_r_overflow_i; 
      END GENERATE gaxi_rd_ch_of3;

      gaxi_pkt_fifo_rd: IF (C_APPLICATION_TYPE_RACH = 1) GENERATE
        SIGNAL rd_burst_length           : STD_LOGIC_VECTOR(8 DOWNTO 0) := (OTHERS => '0');
        SIGNAL rd_fifo_free_space        : STD_LOGIC_VECTOR(C_WR_PNTR_WIDTH_RDCH DOWNTO 0) := (OTHERS => '0');
        SIGNAL rd_fifo_committed_space   : STD_LOGIC_VECTOR(C_WR_PNTR_WIDTH_RDCH DOWNTO 0) := (OTHERS => '0');
        SIGNAL txn_count_en_up           : STD_LOGIC := '0';
        SIGNAL txn_count_en_down         : STD_LOGIC := '0';
        SIGNAL rdch_rd_ok                : STD_LOGIC := '0';
        SIGNAL accept_next_pkt           : STD_LOGIC := '0';
        SIGNAL decrement_val             : INTEGER   := 0;
      BEGIN
        rd_burst_length   <= ('0' & rach_dout_pkt(ARADDR_OFFSET-1 DOWNTO ARLEN_OFFSET)) + conv_std_logic_vector(1,9);
        accept_next_pkt   <= rach_m_axi_arvalid AND arready_pkt AND arvalid_en;
        rdch_rd_ok        <= rdch_re AND rdch_s_axi_rvalid;
        arvalid_en        <= '1' WHEN (rd_fifo_free_space >= rd_burst_length) ELSE '0';

        gaxi_mm_cc_pkt_rd: IF (C_COMMON_CLOCK = 1) GENERATE
          rd_fifo_free_space <= conv_std_logic_vector(C_WR_DEPTH_RDCH-conv_integer(rd_fifo_committed_space),C_WR_PNTR_WIDTH_RDCH+1);
	  decrement_val      <= 1 WHEN (rdch_rd_ok = '1') ELSE 0;
	  proc_rd_txn_cnt: PROCESS (S_ACLK, inverted_reset)
          BEGIN
            IF (inverted_reset = '1') THEN
              rd_fifo_committed_space   <= (OTHERS => '0');
            ELSIF (S_ACLK'EVENT AND S_ACLK = '1') THEN
              IF (accept_next_pkt = '1') THEN
                -- Subtract 1 if read happens on read data FIFO while adding ARLEN
                rd_fifo_committed_space <= rd_fifo_committed_space + conv_std_logic_vector((conv_integer(rd_burst_length) - decrement_val), C_WR_PNTR_WIDTH_RDCH+1);
              ELSIF (rdch_rd_ok = '1') THEN
                -- Subtract 1 whenever read happens on read data FIFO
                rd_fifo_committed_space <= rd_fifo_committed_space - conv_std_logic_vector(1,C_WR_PNTR_WIDTH_RDCH+1);
              END IF;
            END IF;
          END PROCESS proc_rd_txn_cnt;
        END GENERATE gaxi_mm_cc_pkt_rd;

      END GENERATE gaxi_pkt_fifo_rd;

    END GENERATE grdch;

    gaxi_comm_uf: IF (C_USE_COMMON_UNDERFLOW = 1) GENERATE
      grdwr_uf1: IF (C_HAS_AXI_WR_CHANNEL = 1 AND C_HAS_AXI_RD_CHANNEL = 1) GENERATE
        UNDERFLOW <= axi_wr_underflow_i OR axi_rd_underflow_i;
      END GENERATE grdwr_uf1;

      grdwr_uf2: IF (C_HAS_AXI_WR_CHANNEL = 1 AND C_HAS_AXI_RD_CHANNEL = 0) GENERATE
        UNDERFLOW <= axi_wr_underflow_i;
      END GENERATE grdwr_uf2;

      grdwr_uf3: IF (C_HAS_AXI_WR_CHANNEL = 0 AND C_HAS_AXI_RD_CHANNEL = 1) GENERATE
        UNDERFLOW <= axi_rd_underflow_i;
      END GENERATE grdwr_uf3;
    END GENERATE gaxi_comm_uf;

    gaxi_comm_of: IF (C_USE_COMMON_OVERFLOW = 1) GENERATE
      grdwr_of1: IF (C_HAS_AXI_WR_CHANNEL = 1 AND C_HAS_AXI_RD_CHANNEL = 1) GENERATE
        OVERFLOW <= axi_wr_overflow_i OR axi_rd_overflow_i;
      END GENERATE grdwr_of1;

      grdwr_of2: IF (C_HAS_AXI_WR_CHANNEL = 1 AND C_HAS_AXI_RD_CHANNEL = 0) GENERATE
        OVERFLOW <= axi_wr_overflow_i;
      END GENERATE grdwr_of2;

      grdwr_of3: IF (C_HAS_AXI_WR_CHANNEL = 0 AND C_HAS_AXI_RD_CHANNEL = 1) GENERATE
        OVERFLOW <= axi_rd_overflow_i;
      END GENERATE grdwr_of3;
    END GENERATE gaxi_comm_of;

  END GENERATE gaxifull;

  ---------------------------------------------------------------------------
  ---------------------------------------------------------------------------
  ---------------------------------------------------------------------------
  -- Pass Through Logic or Wiring Logic
  ---------------------------------------------------------------------------
  ---------------------------------------------------------------------------
  ---------------------------------------------------------------------------
  gaxi_pass_through: IF (C_WACH_TYPE = 2 OR C_WDCH_TYPE = 2 OR C_WRCH_TYPE = 2 OR
                         C_RACH_TYPE = 2 OR C_RDCH_TYPE = 2 OR C_AXIS_TYPE = 2) GENERATE
    gwach_pass_through: IF (C_WACH_TYPE = 2) GENERATE -- Wiring logic for Write Address Channel
      M_AXI_AWID      <= S_AXI_AWID;
      M_AXI_AWADDR    <= S_AXI_AWADDR;
      M_AXI_AWLEN     <= S_AXI_AWLEN;
      M_AXI_AWSIZE    <= S_AXI_AWSIZE;
      M_AXI_AWBURST   <= S_AXI_AWBURST;
      M_AXI_AWLOCK    <= S_AXI_AWLOCK;
      M_AXI_AWCACHE   <= S_AXI_AWCACHE;
      M_AXI_AWPROT    <= S_AXI_AWPROT;
      M_AXI_AWQOS     <= S_AXI_AWQOS;
      M_AXI_AWREGION  <= S_AXI_AWREGION;
      M_AXI_AWUSER    <= S_AXI_AWUSER;
      S_AXI_AWREADY   <= M_AXI_AWREADY;
      M_AXI_AWVALID   <= S_AXI_AWVALID;
    END GENERATE gwach_pass_through;
  
    -- Wiring logic for Write Data Channel
    gwdch_pass_through: IF (C_WDCH_TYPE = 2) GENERATE
      M_AXI_WID       <= S_AXI_WID;
      M_AXI_WDATA     <= S_AXI_WDATA;
      M_AXI_WSTRB     <= S_AXI_WSTRB;
      M_AXI_WLAST     <= S_AXI_WLAST;
      M_AXI_WUSER     <= S_AXI_WUSER;
      S_AXI_WREADY    <= M_AXI_WREADY;
      M_AXI_WVALID    <= S_AXI_WVALID;
    END GENERATE gwdch_pass_through;
  
    -- Wiring logic for Write Response Channel
    gwrch_pass_through: IF (C_WRCH_TYPE = 2) GENERATE
      S_AXI_BID       <= M_AXI_BID;
      S_AXI_BRESP     <= M_AXI_BRESP;
      S_AXI_BUSER     <= M_AXI_BUSER;
      M_AXI_BREADY    <= S_AXI_BREADY;
      S_AXI_BVALID    <= M_AXI_BVALID;
    END GENERATE gwrch_pass_through;
  
    -- Pass Through Logic for Read Channel
    grach_pass_through: IF (C_RACH_TYPE = 2) GENERATE -- Wiring logic for Read Address Channel
      M_AXI_ARID      <= S_AXI_ARID;
      M_AXI_ARADDR    <= S_AXI_ARADDR;
      M_AXI_ARLEN     <= S_AXI_ARLEN;
      M_AXI_ARSIZE    <= S_AXI_ARSIZE;
      M_AXI_ARBURST   <= S_AXI_ARBURST;
      M_AXI_ARLOCK    <= S_AXI_ARLOCK;
      M_AXI_ARCACHE   <= S_AXI_ARCACHE;
      M_AXI_ARPROT    <= S_AXI_ARPROT;
      M_AXI_ARQOS     <= S_AXI_ARQOS;
      M_AXI_ARREGION  <= S_AXI_ARREGION;
      M_AXI_ARUSER    <= S_AXI_ARUSER;
      S_AXI_ARREADY   <= M_AXI_ARREADY;
      M_AXI_ARVALID   <= S_AXI_ARVALID;
    END GENERATE grach_pass_through;
  
    grdch_pass_through: IF (C_RDCH_TYPE = 2) GENERATE -- Wiring logic for Read Data Channel
      S_AXI_RID      <= M_AXI_RID;
      S_AXI_RLAST    <= M_AXI_RLAST;
      S_AXI_RUSER    <= M_AXI_RUSER;
      S_AXI_RDATA    <= M_AXI_RDATA;
      S_AXI_RRESP    <= M_AXI_RRESP;
      S_AXI_RVALID   <= M_AXI_RVALID;
      M_AXI_RREADY   <= S_AXI_RREADY;
    END GENERATE grdch_pass_through;
  
    gaxis_pass_through: IF (C_AXIS_TYPE = 2) GENERATE -- Wiring logic for AXI Streaming
      M_AXIS_TDATA   <= S_AXIS_TDATA;
      M_AXIS_TSTRB   <= S_AXIS_TSTRB;
      M_AXIS_TKEEP   <= S_AXIS_TKEEP;
      M_AXIS_TID     <= S_AXIS_TID;
      M_AXIS_TDEST   <= S_AXIS_TDEST;
      M_AXIS_TUSER   <= S_AXIS_TUSER;
      M_AXIS_TLAST   <= S_AXIS_TLAST;
      S_AXIS_TREADY  <= M_AXIS_TREADY;
      M_AXIS_TVALID  <= S_AXIS_TVALID;
    END GENERATE gaxis_pass_through;
  END GENERATE gaxi_pass_through;

END behavioral;

