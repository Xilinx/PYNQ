-- IPIF Common Library Package  
-------------------------------------------------------------------------------
--
-- *************************************************************************
-- **                                                                     **
-- ** DISCLAIMER OF LIABILITY                                             **
-- **                                                                     **
-- ** This text/file contains proprietary, confidential                   **
-- ** information of Xilinx, Inc., is distributed under                   **
-- ** license from Xilinx, Inc., and may be used, copied                  **
-- ** and/or disclosed only pursuant to the terms of a valid              **
-- ** license agreement with Xilinx, Inc. Xilinx hereby                   **
-- ** grants you a license to use this text/file solely for               **
-- ** design, simulation, implementation and creation of                  **
-- ** design files limited to Xilinx devices or technologies.             **
-- ** Use with non-Xilinx devices or technologies is expressly            **
-- ** prohibited and immediately terminates your license unless           **
-- ** covered by a separate agreement.                                    **
-- **                                                                     **
-- ** Xilinx is providing this design, code, or information               **
-- ** "as-is" solely for use in developing programs and                   **
-- ** solutions for Xilinx devices, with no obligation on the             **
-- ** part of Xilinx to provide support. By providing this design,        **
-- ** code, or information as one possible implementation of              **
-- ** this feature, application or standard, Xilinx is making no          **
-- ** representation that this implementation is free from any            **
-- ** claims of infringement. You are responsible for obtaining           **
-- ** any rights you may require for your implementation.                 **
-- ** Xilinx expressly disclaims any warranty whatsoever with             **
-- ** respect to the adequacy of the implementation, including            **
-- ** but not limited to any warranties or representations that this      **
-- ** implementation is free from claims of infringement, implied         **
-- ** warranties of merchantability or fitness for a particular           **
-- ** purpose.                                                            **
-- **                                                                     **
-- ** Xilinx products are not intended for use in life support            **
-- ** appliances, devices, or systems. Use in such applications is        **
-- ** expressly prohibited.                                               **
-- **                                                                     **
-- ** Any modifications that are made to the Source Code are              **
-- ** done at the user’s sole risk and will be unsupported.               **
-- ** The Xilinx Support Hotline does not have access to source           **
-- ** code and therefore cannot answer specific questions related         **
-- ** to source HDL. The Xilinx Hotline support of original source        **
-- ** code IP shall only address issues and questions related             **
-- ** to the standard Netlist version of the core (and thus               **
-- ** indirectly, the original core source).                              **
-- **                                                                     **
-- ** Copyright (c) 2002-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--

-------------------------------------------------------------------------------
-- Filename:        ipif_pkg.vhd
-- Version:         Intital
-- Description:     This file contains the constants and functions used in the 
--                  ipif common library components.
--
-------------------------------------------------------------------------------
-- Structure:       
--
-------------------------------------------------------------------------------
-- Author:      DET
-- History:
--  DET         02/21/02      -- Created from proc_common_pkg.vhd
--
--  DET         03/13/02      -- PLB IPIF development updates
-- ^^^^^^
--              - Commented out string types and string functions due to an XST
--                problem with string arrays and functions. THe string array
--                processing functions were replaced with comperable functions
--                operating on integer arrays.
-- ~~~~~~
--
--
--     DET     4/30/2002     Initial
-- ~~~~~~
--     - Added three functions: rebuild_slv32_array, rebuild_slv64_array, and
--       rebuild_int_array to support removal of unused elements from the 
--       ARD arrays.
-- ^^^^^^ --
--
--     FLO     8/12/2002
-- ~~~~~~
--     - Added three functions: bits_needed_for_vac, bits_needed_for_occ,
--       and get_id_index_iboe.
--       (Removed provisional functions bits_needed_for_vacancy,
--        bits needed_for_occupancy, and bits_needed_for.)
-- ^^^^^^
--
--     FLO     3/24/2003
-- ~~~~~~
--     - Added dependent property paramters for channelized DMA.
--     - Added common property parameter array type.
--     - Definded the KEYHOLD_BURST common-property parameter.
-- ^^^^^^
--
--     FLO     10/22/2003
-- ~~~~~~
--     - Some adjustment to CHDMA parameterization.
--     - Cleanup of obsolete code and comments. (The former "XST workaround"
--       has become the officially deployed method.)
-- ^^^^^^
--
--     LSS     03/24/2004
-- ~~~~~~
--     - Added 5 functions
-- ^^^^^^
--
--      ALS     09/03/04
-- ^^^^^^
--      -- Added constants to describe the channel protocols used in MCH_OPB_IPIF
-- ~~~~~~
--
--     DET     1/17/2008     v4_0
-- ~~~~~~
--     - Changed proc_common library version to v4_0
--     - Incorporated new disclaimer header
-- ^^^^^^
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
--      combinatorial signals:                  "*_com" 
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
-- need conversion function to convert reals/integers to std logic vectors
use ieee.std_logic_arith.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


package ipif_pkg is


-------------------------------------------------------------------------------
-- Type Declarations
-------------------------------------------------------------------------------
type    SLV32_ARRAY_TYPE is array (natural range <>) of std_logic_vector(0 to 31);
subtype SLV64_TYPE is std_logic_vector(0 to 63);
type    SLV64_ARRAY_TYPE is array (natural range <>) of SLV64_TYPE;
type    INTEGER_ARRAY_TYPE is array (natural range <>) of integer;

-------------------------------------------------------------------------------
-- Function and Procedure Declarations
-------------------------------------------------------------------------------
function "=" (s1: in string; s2: in string) return boolean;

function equaluseCase( str1, str2 : STRING ) RETURN BOOLEAN;

function calc_num_ce (ce_num_array : INTEGER_ARRAY_TYPE) return integer;

function calc_start_ce_index (ce_num_array : INTEGER_ARRAY_TYPE;
                              index        : integer) return integer;
                              
function get_min_dwidth (dwidth_array: INTEGER_ARRAY_TYPE) return integer;

function get_max_dwidth (dwidth_array: INTEGER_ARRAY_TYPE) return integer;

function S32 (in_string : string) return string;


--------------------------------------------------------------------------------
-- ARD support functions.
-- These function can be useful when operating with the ARD parameterization.
--------------------------------------------------------------------------------

function get_id_index (id_array :INTEGER_ARRAY_TYPE; 
                       id       : integer)
                       return integer;

function get_id_index_iboe (id_array :INTEGER_ARRAY_TYPE; 
                       id       : integer)
                       return integer;


function find_ard_id (id_array : INTEGER_ARRAY_TYPE;
                      id       : integer) return boolean;


function find_id_dwidth (id_array    : INTEGER_ARRAY_TYPE; 
                         dwidth_array: INTEGER_ARRAY_TYPE;
                         id          : integer;
                         default     : integer) 
                         return integer;


function cnt_ipif_id_blks (id_array : INTEGER_ARRAY_TYPE) return integer;

function get_ipif_id_dbus_index (id_array : INTEGER_ARRAY_TYPE;
                                 id          : integer)
                                 return integer ;


function rebuild_slv32_array (slv32_array     : SLV32_ARRAY_TYPE;
                              num_valid_pairs : integer)
                              return SLV32_ARRAY_TYPE;

function rebuild_slv64_array (slv64_array     : SLV64_ARRAY_TYPE;
                              num_valid_pairs : integer)
                              return SLV64_ARRAY_TYPE;


function rebuild_int_array (int_array       : INTEGER_ARRAY_TYPE;
                            num_valid_entry : integer)
                            return INTEGER_ARRAY_TYPE;

-- 5 Functions Added 3/24/04

function populate_intr_mode_array (num_user_intr        : integer;
                                   intr_capture_mode    : integer)
                                  return INTEGER_ARRAY_TYPE ;

function add_intr_ard_id_array(include_intr    : boolean;
                              ard_id_array     : INTEGER_ARRAY_TYPE)
                              return INTEGER_ARRAY_TYPE; 

function add_intr_ard_addr_range_array(include_intr    : boolean;
                              ZERO_ADDR_PAD        : std_logic_vector;
                              intr_baseaddr            : std_logic_vector;
                              intr_highaddr            : std_logic_vector;
                              ard_id_array             : INTEGER_ARRAY_TYPE;
                              ard_addr_range_array     : SLV64_ARRAY_TYPE)
                              return SLV64_ARRAY_TYPE; 

function add_intr_ard_num_ce_array(include_intr     : boolean;
                              ard_id_array          : INTEGER_ARRAY_TYPE;
                              ard_num_ce_array      : INTEGER_ARRAY_TYPE)
                              return INTEGER_ARRAY_TYPE; 

function add_intr_ard_dwidth_array(include_intr    : boolean;
                              intr_dwidth           : integer;
                              ard_id_array          : INTEGER_ARRAY_TYPE;
                              ard_dwidth_array      : INTEGER_ARRAY_TYPE)
                              return INTEGER_ARRAY_TYPE; 

function log2(x : natural) return integer;
function clog2(x : positive) return natural;


-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Channel Protocols
--  The constant declarations below give symbolic-name aliases for values that 
--  can be used in the C_MCH_PROTOCOL_ARRAY generic of the MCH_OPB_IPIF.
-------------------------------------------------------------------------------
constant XCL                    : integer := 0;
constant DAG                    : integer := 1;

--------------------------------------------------------------------------------
-- Address range types.
-- The constant declarations, below, give symbolic-name aliases for values
-- that can be used in the C_ARD_ID_ARRAY generic of IPIFs. The first set
-- gives aliases that are used to include IPIF services.
--------------------------------------------------------------------------------
-- IPIF module aliases
Constant IPIF_INTR              : integer := 1;
Constant IPIF_RST               : integer := 2;
Constant IPIF_SESR_SEAR         : integer := 3;
Constant IPIF_DMA_SG            : integer := 4;
Constant IPIF_WRFIFO_REG        : integer := 5;
Constant IPIF_WRFIFO_DATA       : integer := 6;
Constant IPIF_RDFIFO_REG        : integer := 7;
Constant IPIF_RDFIFO_DATA       : integer := 8;
Constant IPIF_CHDMA_CHANNELS    : integer := 9;
Constant IPIF_CHDMA_GLOBAL_REGS : integer := 10;
Constant CHDMA_STATUS_FIFO      : integer := 90;

-- Some predefined user module aliases
Constant USER_00                : integer := 100;
Constant USER_01                : integer := 101;
Constant USER_02                : integer := 102;
Constant USER_03                : integer := 103;
Constant USER_04                : integer := 104;
Constant USER_05                : integer := 105;
Constant USER_06                : integer := 106;
Constant USER_07                : integer := 107;
Constant USER_08                : integer := 108;
Constant USER_09                : integer := 109;
Constant USER_10                : integer := 110;
Constant USER_11                : integer := 111;
Constant USER_12                : integer := 112;
Constant USER_13                : integer := 113;
Constant USER_14                : integer := 114;
Constant USER_15                : integer := 115;
Constant USER_16                : integer := 116;
        
                                          
                                          
---( Start  of Dependent Properties declarations
--------------------------------------------------------------------------------
-- Declarations for Dependent Properties (properties that depend on the type of
-- the address range, or in other words, address-range-specific parameters).
-- There is one property, i.e. one parameter, encoded as an integer at
-- each index of the properties array. There is one properties array for
-- each address range.
-- 
-- The C_ARD_DEPENDENT_PROPS_ARRAY generic parameter in (most) IPIFs is such
-- a properties array and it is usually giving its (static) value using a
-- VHDL aggregate construct.  (--ToDo, give an example of this.)
--
-- The the "assigned" default value of a dependent property is zero. This value
-- is usually specified the aggregate by leaving its (index) name out so that
-- it is covered by an "others => 0" choice in the aggregate. Some parameters,
-- as noted in the definitions, below, have an "effective" default value that is
-- different from the assigned default value of zero. In such cases, the
-- function, eff_dp, given below, can be used to get the effective value of
-- the dependent property.
--------------------------------------------------------------------------------

constant DEPENDENT_PROPS_SIZE : integer := 32;

subtype DEPENDENT_PROPS_TYPE
         is INTEGER_ARRAY_TYPE(0 to DEPENDENT_PROPS_SIZE-1);

type DEPENDENT_PROPS_ARRAY_TYPE
         is array (natural range <>) of DEPENDENT_PROPS_TYPE;


--------------------------------------------------------------------------------
-- Below are the indices of dependent properties for the different types of
-- address ranges.
--
-- Example: Let C_ARD_DEPENDENT_PROPS_ARRAY hold the dependent properites
-- for a set of address ranges. Then, e.g.,
--
--   C_ARD_DEPENDENT_PROPS_ARRAY(i)(FIFO_CAPACITY_BITS)
--
-- gives the fifo capacity in bits, provided that the i'th address range
-- is of type IPIF_WRFIFO_DATA or IPIF_RDFIFO_DATA.
--
-- These indices should be referenced only by the names below and never
-- by numerical literals. (The right to change numerical index assignments
-- is reserved; applications using the names will not be affected by such
-- reassignments.)
--------------------------------------------------------------------------------
--
--ToDo, if the interrupt controller parameterization is ever moved to
--      C_ARD_DEPENDENT_PROPS_ARRAY, then the following declarations
--      could be uncommented and used.
---- IPIF_INTR                                                               IDX
---------------------------------------------------------------------------- ---
constant EXCLUDE_DEV_ISC                                       : integer := 0;
      -- 1 specifies that only the global interrupt
      -- enable is present in the device interrupt source
      -- controller and that the only source of interrupts
      -- in the device is the IP interrupt source controller.
      -- 0 specifies that the full device interrupt
      -- source controller structure will be included.
constant INCLUDE_DEV_PENCODER                                  : integer := 1;
      -- 1 will include the Device IID in the device interrupt
      -- source controller, 0 will exclude it.


--
-- IPIF_WRFIFO_DATA or IPIF_RDFIFO_DATA                                      IDX
---------------------------------------------------------------------------- ---
constant FIFO_CAPACITY_BITS                                      : integer := 0;
constant WR_WIDTH_BITS                                           : integer := 1;
constant RD_WIDTH_BITS                                           : integer := 2;
constant EXCLUDE_PACKET_MODE                                     : integer := 3;
      -- 1  Don't include packet mode features
      -- 0  Include packet mode features
constant EXCLUDE_VACANCY                                         : integer := 4;
      -- 1  Don't include vacancy calculation
      -- 0  Include vacancy calculation
      --    See also the functions
      --    bits_needed_for_vac  and
      --    bits_needed_for_occ  that are declared below.
constant INCLUDE_DRE                                             : integer := 5;
constant INCLUDE_AUTOPUSH_POP                                    : integer := 6;
constant AUTOPUSH_POP_CE                                         : integer := 7;
constant INCLUDE_CSUM                                            : integer := 8;
--------------------------------------------------------------------------------

--
-- DMA_SG                                                                    IDX
---------------------------------------------------------------------------- ---
--------------------------------------------------------------------------------

-- IPIF_CHDMA_CHANNELS                                                       IDX
---------------------------------------------------------------------------- ---
constant NUM_SUBS_FOR_PHYS_0                                     : integer :=0;
constant NUM_SUBS_FOR_PHYS_1                                     : integer :=1;
constant NUM_SUBS_FOR_PHYS_2                                     : integer :=2;
constant NUM_SUBS_FOR_PHYS_3                                     : integer :=3;
constant NUM_SUBS_FOR_PHYS_4                                     : integer :=4;
constant NUM_SUBS_FOR_PHYS_5                                     : integer :=5;
constant NUM_SUBS_FOR_PHYS_6                                     : integer :=6;
constant NUM_SUBS_FOR_PHYS_7                                     : integer :=7;
constant NUM_SUBS_FOR_PHYS_8                                     : integer :=8;
constant NUM_SUBS_FOR_PHYS_9                                     : integer :=9;
constant NUM_SUBS_FOR_PHYS_10                                    : integer :=10;
constant NUM_SUBS_FOR_PHYS_11                                    : integer :=11;
constant NUM_SUBS_FOR_PHYS_12                                    : integer :=12;
constant NUM_SUBS_FOR_PHYS_13                                    : integer :=13;
constant NUM_SUBS_FOR_PHYS_14                                    : integer :=14;
constant NUM_SUBS_FOR_PHYS_15                                    : integer :=15;
      -- Gives the number of sub-channels for physical channel i.
      --
      -- These constants, which will be MAX_NUM_PHYS_CHANNELS in number (see
      -- below), have consecutive values starting with 0 for
      -- NUM_SUBS_FOR_PHYS_0. (The constants serve the purpose of giving symbolic
      -- names for use in the dependent-properties aggregates that parameterize
      -- an IPIF_CHDMA_CHANNELS address range.)
      --  
      -- [Users can ignore this note for developers
      --   If the number of physical channels changes, both the
      --   IPIF_CHDMA_CHANNELS constants and MAX_NUM_PHYS_CHANNELS,
      --   below, must be adjusted.
      --   (Use of an array constant or a function of the form
      --    NUM_SUBS_FOR_PHYS(i) to define the indices
      --    runs afoul of LRM restrictions on non-locally static aggregate
      --    choices. (Further, the LRM imposes perhaps unnecessarily
      --    strict limits on what qualifies as a locally static primary.)
      --    Note: This information is supplied for the benefit of anyone seeking
      --    to improve the way that these NUM_SUBS_FOR_PHYS parameter
      --    indices are defined.)
      -- End of note for developers ]
      --
      -- The value associated with any index NUM_SUBS_FOR_PHYS_i in the
      -- dependent-properties array must be even since TX and RX channels
      -- come in pairs with the TX followed immediately by
      -- the corresponding RX.
      --
constant NUM_SIMPLE_DMA_CHANS                                  : integer :=16;
      -- The number of simple DMA channels.
constant NUM_SIMPLE_SG_CHANS                                   : integer :=17;
      -- The number of simple SG channels.
constant INTR_COALESCE                                         : integer :=18;
      -- 0 Interrupt coalescing is disabled
      -- 1 Interrupt coalescing is enabled
constant CLK_PERIOD_PS                                         : integer :=19;
      -- The period of the OPB Bus clock in ps.
      -- The default value of 0 is a special value that
      -- is synonymous with 10000 ps (10 ns).
      -- The value for CLK_PERIOD_PS is relevant only if (INTR_COALESCE = 1).
constant PACKET_WAIT_UNIT_NS                                   : integer :=20;  
      -- Gives the unit for used for timing of pack-wait bounds.
      -- The default value of 0 is a special value that
      -- is synonymous with 1,000,000 ns (1 ms) and a non-default
      -- value is typically only used for testing.
      -- Relevant only if (INTR_COALESCE = 1).
constant BURST_SIZE                                            : integer :=21;
      -- 1, 2, 4, 8 or 16 
      -- The default value of 0 is a special value that
      -- is synonymous with a burst size of 16.
      -- Setting the BURST_SIZE to 1 effectively disables
      -- bursts.
constant REMAINDER_AS_SINGLES                                  : integer :=22;
      -- 0 Remainder handled as a short burst
      -- 1 Remainder handled as a series of singles

      --------------------------------------------------------------------------------
      -- The constant below is not the index of a dependent-properties
      -- parameter (and, as such, would never appear as a choice in a
      -- dependent-properties aggregate). Rather, it is fixed to the maximum
      -- number of physical channels that an Address Range of type
      -- IPIF_CHDMA_CHANNELS supports. It must be maintained in conjuction with
      -- the constants named, e.g., NUM_SUBS_FOR_PHYS_15, above.
      --------------------------------------------------------------------------------
      constant MAX_NUM_PHYS_CHANNELS : natural := 16;


      --------------------------------------------------------------------------
      -- EXAMPLE: Here is an example dependent-properties aggregate for an 
      -- address range of type IPIF_CHDMA_CHANNELS. 
      -- To have a compact list of all of the CHDMA parameters, all are
      -- shown, however three are commented out and the unneeded
      -- MUM_SUBS_FOR_PHYS_x are excluded. The "OTHERS => 0" association
      -- gives these parameters their default values, such that, for the example
      --
      --     - All physical channels above 2 have zero subchannels (effectively,
      --       these physical channels are not used)
      --     - There are no simple SG channels
      --     - The packet-wait time unit is 1 ms
      --     - Burst size is 16
      --------------------------------------------------------------------------
      --    (
      --     NUM_SUBS_FOR_PHYS_0                        =>     8,
      --     NUM_SUBS_FOR_PHYS_1                        =>     4,
      --     NUM_SUBS_FOR_PHYS_2                        =>    14,
      --     NUM_SIMPLE_DMA_CHANS                       =>     1,
      --   --NUM_SIMPLE_SG_CHANS                        =>     5,
      --     INTR_COALESCE                              =>     1,
      --     CLK_PERIOD_PS                              => 20000,
      --   --PACKET_WAIT_UNIT_NS                        => 50000,
      --   --BURST_SIZE                                 =>     1,
      --     REMAINDER_AS_SINGLES                       =>     1,
      --     OTHERS                                     =>     0
      --    )
      --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Calculates the number of bits needed to convey the vacancy (emptiness) of
-- the fifo described by dependent_props, if fifo_present. If not fifo_present,
-- returns 0 (or the smallest value allowed by tool limitations on null arrays)
-- without making reference to dependent_props.
--------------------------------------------------------------------------------
function  bits_needed_for_vac(
              fifo_present: boolean;
              dependent_props : DEPENDENT_PROPS_TYPE
          ) return integer;

--------------------------------------------------------------------------------
-- Calculates the number of bits needed to convey the occupancy (fullness) of
-- the fifo described by dependent_props, if fifo_present. If not fifo_present,
-- returns 0 (or the smallest value allowed by tool limitations on null arrays)
-- without making reference to dependent_props.
--------------------------------------------------------------------------------
function  bits_needed_for_occ(
              fifo_present: boolean;
              dependent_props : DEPENDENT_PROPS_TYPE
          ) return integer;

--------------------------------------------------------------------------------
-- Function eff_dp.
--
-- For some of the dependent properties, the default value of zero is meant
-- to imply an effective default value of other than zero (see e.g.
-- PKT_WAIT_UNIT_NS for the IPIF_CHDMA_CHANNELS address-range type). The
-- following function is used to get the (possibly default-adjusted)
-- value for a dependent property.
--
-- Example call:
--
--    eff_value_of_param :=
--        eff_dp(
--            C_IPIF_CHDMA_CHANNELS,
--            PACKET_WAIT_UNIT_NS,
--            C_ARD_DEPENDENT_PROPS_ARRAY(i)(PACKET_WAIT_UNIT_NS)
--        );
--
--    where C_ARD_DEPENDENT_PROPS_ARRAY(i) is an object of type
--    DEPENDENT_PROPS_ARRAY_TYPE, that was parameterized for an address range of
--    type C_IPIF_CHDMA_CHANNELS.
--------------------------------------------------------------------------------
function eff_dp(id       : integer;  -- The type of address range.
                dep_prop : integer;  -- The index of the dependent prop.
                value    : integer   -- The value at that index.
               ) return    integer;  -- The effective value, possibly adjusted
                                     -- if value has the default value of 0.

---) End  of Dependent Properties declarations


--------------------------------------------------------------------------------
-- Declarations for Common Properties (properties that apply regardless of the
-- type of the address range). Structurally, these work the same as
-- the dependent properties.
--------------------------------------------------------------------------------

constant COMMON_PROPS_SIZE : integer := 2;

subtype COMMON_PROPS_TYPE
         is INTEGER_ARRAY_TYPE(0 to COMMON_PROPS_SIZE-1);

type COMMON_PROPS_ARRAY_TYPE
         is array (natural range <>) of COMMON_PROPS_TYPE;

--------------------------------------------------------------------------------
-- Below are the indices of the common properties.
--
-- These indices should be referenced only by the names below and never
-- by numerical literals.
--                                                                           IDX
---------------------------------------------------------------------------- ---
constant KEYHOLE_BURST                                           : integer := 0;
      -- 1 All addresses of a burst are forced to the initial
      --   address of the burst.
      -- 0 Burst addresses follow the bus protocol.




-- IP interrupt mode array constants
Constant INTR_PASS_THRU         : integer := 1;
Constant INTR_PASS_THRU_INV     : integer := 2;
Constant INTR_REG_EVENT         : integer := 3;
Constant INTR_REG_EVENT_INV     : integer := 4;
Constant INTR_POS_EDGE_DETECT   : integer := 5;
Constant INTR_NEG_EDGE_DETECT   : integer := 6;




 
end ipif_pkg;




package body ipif_pkg is

-------------------------------------------------------------------------------
-- Function log2 -- returns number of bits needed to encode x choices
--   x = 0  returns 0
--   x = 1  returns 0
--   x = 2  returns 1
--   x = 4  returns 2, etc.
-------------------------------------------------------------------------------
--
function log2(x : natural) return integer is
  variable i  : integer := 0;
  variable val: integer := 1;
begin
  if x = 0 then return 0;
  else
    for j in 0 to 29 loop -- for loop for XST 
      if val >= x then null;
      else
        i := i+1;
        val := val*2;
      end if;
    end loop;
  -- Fix per CR520627  XST was ignoring this anyway and printing a  
  -- Warning in SRP file. This will get rid of the warning and not
  -- impact simulation.  
  -- synthesis translate_off
    assert val >= x
      report "Function log2 received argument larger" &
             " than its capability of 2^30. "
      severity failure;
  -- synthesis translate_on
    return i;
  end if;
end function log2;



--------------------------------------------------------------------------------
-- Function clog2 - returns the integer ceiling of the base 2 logarithm of x,
--                  i.e., the least integer greater than or equal to log2(x).
--------------------------------------------------------------------------------
function clog2(x : positive) return natural is
  variable r  : natural := 0;
  variable rp : natural := 1; -- rp tracks the value 2**r
begin
  while rp < x loop -- Termination condition T: x <= 2**r
    -- Loop invariant L: 2**(r-1) < x
    r := r + 1;
    if rp > integer'high - rp then exit; end if;  -- If doubling rp overflows
      -- the integer range, the doubled value would exceed x, so safe to exit.
    rp := rp + rp;
  end loop;
  -- L and T  <->  2**(r-1) < x <= 2**r  <->  (r-1) < log2(x) <= r
  return r; --
end clog2;


-------------------------------------------------------------------------------
-- Function Definitions
-------------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Function "="
--
-- This function can be used to overload the "=" operator when comparing
-- strings.
-----------------------------------------------------------------------------
  function "=" (s1: in string; s2: in string) return boolean is
      constant tc: character := ' ';  -- string termination character
      variable i: integer := 1;
      variable v1 : string(1 to s1'length) := s1;
      variable v2 : string(1 to s2'length) := s2;
  begin
      while (i <= v1'length) and (v1(i) /= tc) and
            (i <= v2'length) and (v2(i) /= tc) and
            (v1(i) = v2(i))
      loop
          i := i+1;
      end loop;
      return ((i > v1'length) or (v1(i) = tc)) and
             ((i > v2'length) or (v2(i) = tc));
  end;




----------------------------------------------------------------------------
-- Function equaluseCase
--
-- This function returns true if case sensitive string comparison determines
-- that str1 and str2 are the same.
-----------------------------------------------------------------------------
   FUNCTION equaluseCase( str1, str2 : STRING ) RETURN BOOLEAN IS
     CONSTANT len1 : INTEGER := str1'length;
     CONSTANT len2 : INTEGER := str2'length;
     VARIABLE equal : BOOLEAN := TRUE;
   BEGIN
      IF NOT (len1=len2) THEN
        equal := FALSE;
      ELSE
        FOR i IN str1'range LOOP
          IF NOT (str1(i) = str2(i)) THEN
            equal := FALSE;
          END IF;
        END LOOP;
      END IF;

      RETURN equal;
   END equaluseCase;
 

-----------------------------------------------------------------------------
-- Function calc_num_ce
--
-- This function is used to process the array specifying the number of Chip
-- Enables required for a Base Address specification. The array is input to
-- the function and an integer is returned reflecting the total number of 
-- Chip Enables required for the CE, RdCE, and WrCE Buses
-----------------------------------------------------------------------------
  function calc_num_ce (ce_num_array : INTEGER_ARRAY_TYPE) return integer is

     Variable ce_num_sum : integer := 0;

  begin
    
    for i in 0 to (ce_num_array'length)-1 loop
        ce_num_sum := ce_num_sum + ce_num_array(i);
    End loop;
     
    return(ce_num_sum);
       
  end function calc_num_ce;


-----------------------------------------------------------------------------
-- Function calc_start_ce_index
--
-- This function is used to process the array specifying the number of Chip
-- Enables required for a Base Address specification. The CE Size array is 
-- input to the function and an integer index representing the index of the 
-- target module in the ce_num_array. An integer is returned reflecting the 
-- starting index of the assigned Chip Enables within the CE, RdCE, and 
-- WrCE Buses.
-----------------------------------------------------------------------------
 function calc_start_ce_index (ce_num_array : INTEGER_ARRAY_TYPE;
                               index        : integer) return integer is

    Variable ce_num_sum : integer := 0;

 begin
   If (index = 0) Then
     ce_num_sum := 0;
   else
      for i in 0 to index-1 loop
          ce_num_sum := ce_num_sum + ce_num_array(i);
      End loop;
   End if;
    
   return(ce_num_sum);
      
 end function calc_start_ce_index;
 
 
-----------------------------------------------------------------------------
-- Function get_min_dwidth
--
-- This function is used to process the array specifying the data bus width
-- for each of the target modules. The dwidth_array is input to the function
-- and an integer is returned that is the smallest value found of all the 
-- entries in the array.
-----------------------------------------------------------------------------
 function get_min_dwidth (dwidth_array: INTEGER_ARRAY_TYPE) return integer is

    Variable temp_min : Integer := 1024;
    
 begin

    for i in 0 to dwidth_array'length-1 loop
        
       If (dwidth_array(i) < temp_min) Then
          temp_min := dwidth_array(i);
       else
           null;
       End if;
        
    End loop;
    
    return(temp_min);
                  
 end function get_min_dwidth;

 
 
-----------------------------------------------------------------------------
-- Function get_max_dwidth
--
-- This function is used to process the array specifying the data bus width
-- for each of the target modules. The dwidth_array is input to the function
-- and an integer is returned that is the largest value found of all the 
-- entries in the array.
-----------------------------------------------------------------------------
 function get_max_dwidth (dwidth_array: INTEGER_ARRAY_TYPE) return integer is

    Variable temp_max : Integer := 0;
    
 begin

    for i in 0 to dwidth_array'length-1 loop
        
       If (dwidth_array(i) > temp_max) Then
          temp_max := dwidth_array(i);
       else
           null;
       End if;
        
    End loop;
    
    return(temp_max);
                  
 end function get_max_dwidth;

 

-----------------------------------------------------------------------------
-- Function S32
--
-- This function is used to expand an input string to 32 characters by
-- padding with spaces. If the input string is larger than 32 characters,
-- it will truncate to 32 characters.
-----------------------------------------------------------------------------
 function S32 (in_string : string) return string is

   constant OUTPUT_STRING_LENGTH : integer := 32;
   Constant space : character := ' ';
   
   variable new_string    : string(1 to 32);
   Variable start_index   : Integer :=  in_string'length+1;
   
 begin

   If (in_string'length < OUTPUT_STRING_LENGTH) Then
    
      for i in 1 to in_string'length loop
          new_string(i) :=  in_string(i);
      End loop; 
   
      for j in start_index to OUTPUT_STRING_LENGTH loop
          new_string(j) :=  space;
      End loop; 
   
   
   else  -- use first 32 chars of in_string (truncate the rest)

      for k in 1 to OUTPUT_STRING_LENGTH loop
          new_string(k) :=  in_string(k);
      End loop; 
   
   End if;
  
   return(new_string);
  
 end function S32;
 

-----------------------------------------------------------------------------
-- Function get_id_index
--
-- This function is used to process the array specifying the target function
-- assigned to a Base Address pair address range. The id_array and a 
-- id number is input to the function. A integer is returned reflecting the
-- array index of the id matching the id input number. This function
-- should only be called if the id number is known to exist in the 
-- name_array input. This can be detirmined by using the  find_ard_id
-- function.
-----------------------------------------------------------------------------
 function get_id_index (id_array :INTEGER_ARRAY_TYPE;      
                        id       : integer) return integer is
 
    Variable match       : Boolean := false;
    Variable match_index : Integer := 10000; -- a really big number!
    
    
 begin
 
    for array_index in 0 to id_array'length-1 loop
        
               
        If (match = true) Then  -- match already found so do nothing
            
            null; 
            
        else  -- compare the numbers one by one
          
           match       := (id_array(array_index) = id);
           
           If (match) Then
              match_index := array_index;
           else
               null;
           End if;
          
        End if;
        
    End loop;
   
    return(match_index);
    
 end function get_id_index;
 

--------------------------------------------------------------------------------
-- get_id_index but return a value in bounds on error (iboe).
--
-- This function is the same as get_id_index, except that when id does
-- not exist in id_array, the value returned is any index that is
-- within the index range of id_array.
--
-- This function would normally only be used where function find_ard_id
-- is used to establish the existence of id but, even when non-existent,
-- an element of one of the ARD arrays will be computed from the
-- returned get_id_index_iboe value. See, e.g., function bits_needed_for_vac
-- and the example call, below
--
--      bits_needed_for_vac(
--        find_ard_id(C_ARD_ID_ARRAY, IPIF_RDFIFO_DATA),
--        C_ARD_DEPENDENT_PROPS_ARRAY(get_id_index_iboe(C_ARD_ID_ARRAY,
--                                                      IPIF_RDFIFO_DATA))
--      )
--------------------------------------------------------------------------------
 function get_id_index_iboe (id_array :INTEGER_ARRAY_TYPE;      
                             id       : integer) return integer is
 
    Variable match       : Boolean := false;
    Variable match_index : Integer := id_array'left; -- any valid array index
    
 begin
    for array_index in 0 to id_array'length-1 loop
        If (match = true) Then  -- match already found so do nothing
            null; 
        else  -- compare the numbers one by one
           match       := (id_array(array_index) = id);
           If (match) Then match_index := array_index;
           else null;
           End if;
        End if;
    End loop;
    return(match_index);
 end function get_id_index_iboe;
 

-----------------------------------------------------------------------------
-- Function find_ard_id
--
-- This function is used to process the array specifying the target function
-- assigned to a Base Address pair address range. The id_array and a 
-- integer id is input to the function. A boolean is returned reflecting the
-- presence (or not) of a number in the array matching the id input number.
-----------------------------------------------------------------------------
function find_ard_id (id_array : INTEGER_ARRAY_TYPE;
                      id       : integer) return boolean is
 
    Variable match       : Boolean := false;
    
 begin
 
    for array_index in 0 to id_array'length-1 loop
        
        
        If (match = true) Then  -- match already found so do nothing
            
            null; 
            
        else  -- compare the numbers one by one

           match       := (id_array(array_index) = id);
          
        End if;
        
    End loop;
   
    return(match);
    
 end function find_ard_id;
 
 
-----------------------------------------------------------------------------
-- Function find_id_dwidth
--
-- This function is used to find the data width of a target module. If the
-- target module exists, the data width is extracted from the input dwidth 
-- array. If the module is not in the ID array, the default input is 
-- returned. This function is needed to assign data port size constraints on
-- unconstrained port widths.
-----------------------------------------------------------------------------
function find_id_dwidth (id_array    : INTEGER_ARRAY_TYPE; 
                        dwidth_array: INTEGER_ARRAY_TYPE;
                        id          : integer;
                        default     : integer) return integer is


     Variable id_present   : Boolean := false;
     Variable array_index  : Integer := 0;
     Variable dwidth       : Integer := default;

 begin

    id_present := find_ard_id(id_array, id);
   
    If (id_present) Then
      array_index :=  get_id_index (id_array, id);
      dwidth      :=  dwidth_array(array_index);
    else
       null; -- use default input 
    End if;
   
   
   Return (dwidth);
   
 end function find_id_dwidth;

 
 
 

-----------------------------------------------------------------------------
-- Function cnt_ipif_id_blks
--
-- This function is used to detirmine the number of IPIF components specified
-- in the ARD ID Array. An integer is returned representing the number
-- of elements counted. User IDs are ignored in the counting process.
-----------------------------------------------------------------------------
function cnt_ipif_id_blks (id_array : INTEGER_ARRAY_TYPE) 
                           return integer is

    Variable blk_count   : integer := 0;
    Variable temp_id     : integer;
    
 begin
 
    for array_index in 0 to id_array'length-1 loop
        
        temp_id :=  id_array(array_index);
        
        If (temp_id = IPIF_WRFIFO_DATA or
            temp_id = IPIF_RDFIFO_DATA or
            temp_id = IPIF_RST or
            temp_id = IPIF_INTR or
            temp_id = IPIF_DMA_SG or
            temp_id = IPIF_SESR_SEAR
           ) Then  -- IPIF block found
            
            blk_count := blk_count+1; 
            
        else  -- go to next loop iteration
          
            null;
          
        End if;
        
    End loop;
   
    return(blk_count);
    
end function cnt_ipif_id_blks;



-----------------------------------------------------------------------------
-- Function get_ipif_id_dbus_index
--
-- This function is used to detirmine the IPIF relative index of a given
-- ID value. User IDs are ignored in the index detirmination.
-----------------------------------------------------------------------------
function get_ipif_id_dbus_index (id_array : INTEGER_ARRAY_TYPE;
                                 id       : integer)
                                 return integer is
    
    Variable blk_index   : integer := 0;
    Variable temp_id     : integer;
    Variable id_found    : Boolean := false;
    
begin

    for array_index in 0 to id_array'length-1 loop
        
        temp_id :=  id_array(array_index);
        
        If (id_found) then

           null;
            
        elsif (temp_id = id) then
        
          id_found := true;
        
        elsif (temp_id = IPIF_WRFIFO_DATA or 
               temp_id = IPIF_RDFIFO_DATA or 
               temp_id = IPIF_RST or         
               temp_id = IPIF_INTR or        
               temp_id = IPIF_DMA_SG or      
               temp_id = IPIF_SESR_SEAR      
              ) Then  -- IPIF block found
            
            blk_index := blk_index+1; 
            
        else  -- user block so do nothing
          
            null;
          
        End if;
        
    End loop;
   
    return(blk_index);
    
   
end function get_ipif_id_dbus_index;



 ------------------------------------------------------------------------------ 
 -- Function: rebuild_slv32_array
 --
 -- Description:
 -- This function takes an input slv32 array and rebuilds an output slv32
 -- array composed of the first "num_valid_entry" elements from the input 
 -- array.
 ------------------------------------------------------------------------------ 
 function rebuild_slv32_array (slv32_array  : SLV32_ARRAY_TYPE;
                               num_valid_pairs : integer)
                               return SLV32_ARRAY_TYPE is
 
      --Constants
      constant num_elements          : Integer := num_valid_pairs * 2;
      
      -- Variables
      variable temp_baseaddr32_array :  SLV32_ARRAY_TYPE( 0 to num_elements-1);
 
 begin
 
     for array_index in 0 to num_elements-1 loop
     
        temp_baseaddr32_array(array_index) := slv32_array(array_index);
     
     end loop;
   
   
     return(temp_baseaddr32_array);
   
 end function rebuild_slv32_array;
 


  
 ------------------------------------------------------------------------------ 
 -- Function: rebuild_slv64_array
 --
 -- Description:
 -- This function takes an input slv64 array and rebuilds an output slv64
 -- array composed of the first "num_valid_entry" elements from the input 
 -- array.
 ------------------------------------------------------------------------------ 
 function rebuild_slv64_array (slv64_array  : SLV64_ARRAY_TYPE;
                               num_valid_pairs : integer)
                               return SLV64_ARRAY_TYPE is
 
      --Constants
      constant num_elements          : Integer := num_valid_pairs * 2;
      
      -- Variables
      variable temp_baseaddr64_array :  SLV64_ARRAY_TYPE( 0 to num_elements-1);
 
 begin
 
     for array_index in 0 to num_elements-1 loop
     
        temp_baseaddr64_array(array_index) := slv64_array(array_index);
     
     end loop;
   
   
     return(temp_baseaddr64_array);
   
 end function rebuild_slv64_array;
 


 ------------------------------------------------------------------------------ 
 -- Function: rebuild_int_array
 --
 -- Description:
 -- This function takes an input integer array and rebuilds an output integer
 -- array composed of the first "num_valid_entry" elements from the input 
 -- array.
 ------------------------------------------------------------------------------ 
 function rebuild_int_array (int_array       : INTEGER_ARRAY_TYPE;
                             num_valid_entry : integer)
                             return INTEGER_ARRAY_TYPE is
 
      -- Variables
      variable temp_int_array   : INTEGER_ARRAY_TYPE( 0 to num_valid_entry-1);
 
 begin
 
     for array_index in 0 to num_valid_entry-1 loop
     
        temp_int_array(array_index) := int_array(array_index);
     
     end loop;
   
   
     return(temp_int_array);
   
 end function rebuild_int_array;
 

 
    function  bits_needed_for_vac(
                  fifo_present: boolean;
                  dependent_props : DEPENDENT_PROPS_TYPE
              ) return integer is
    begin
        if not fifo_present then
            return 1; -- Zero would be better but leads to "0 to -1" null
                      -- ranges that are not handled by XST Flint or earlier
                      -- because of the negative index.
        else
            return
            log2(1 + dependent_props(FIFO_CAPACITY_BITS) /
                     dependent_props(RD_WIDTH_BITS)
            );
        end if;
    end function bits_needed_for_vac;


    function  bits_needed_for_occ(
                  fifo_present: boolean;
                  dependent_props : DEPENDENT_PROPS_TYPE
              ) return integer is
    begin
        if not fifo_present then
            return 1; -- Zero would be better but leads to "0 to -1" null
                      -- ranges that are not handled by XST Flint or earlier
                      -- because of the negative index.
        else
            return
            log2(1 + dependent_props(FIFO_CAPACITY_BITS) /
                     dependent_props(WR_WIDTH_BITS)
            );
        end if;
    end function bits_needed_for_occ;


    function eff_dp(id       : integer;
                    dep_prop : integer;
                    value    : integer) return integer is
        variable dp : integer := dep_prop;
        type     bo2na_type is array (boolean) of natural;
        constant bo2na : bo2na_type := (0, 1);
    begin
        if value /= 0 then return value; end if; -- Not default
        case id is
            when IPIF_CHDMA_CHANNELS =>
                 -------------------
                 return(   bo2na(dp =  CLK_PERIOD_PS          ) * 10000
                         + bo2na(dp =  PACKET_WAIT_UNIT_NS    ) * 1000000
                         + bo2na(dp =  BURST_SIZE             ) * 16
                       );
            when others => return 0;
        end case;
    end eff_dp;


function populate_intr_mode_array (num_user_intr        : integer;
                                   intr_capture_mode    : integer)
                                   return INTEGER_ARRAY_TYPE is
    variable intr_mode_array    : INTEGER_ARRAY_TYPE(0 to num_user_intr-1);
begin
    for i in 0 to num_user_intr-1 loop
        intr_mode_array(i) := intr_capture_mode;
    end loop;
    
    return intr_mode_array;
end function populate_intr_mode_array;


function add_intr_ard_id_array(include_intr    : boolean;
                              ard_id_array     : INTEGER_ARRAY_TYPE)
                              return INTEGER_ARRAY_TYPE is
    variable intr_ard_id_array   : INTEGER_ARRAY_TYPE(0 to ard_id_array'length);
begin
    intr_ard_id_array(0 to ard_id_array'length-1) := ard_id_array;
    if include_intr then
       intr_ard_id_array(ard_id_array'length) := IPIF_INTR;
       return intr_ard_id_array;
    else
        return ard_id_array;
    end if;
end function add_intr_ard_id_array;


function add_intr_ard_addr_range_array(include_intr    : boolean;
                              ZERO_ADDR_PAD        : std_logic_vector;
                              intr_baseaddr            : std_logic_vector;
                              intr_highaddr            : std_logic_vector;
                              ard_id_array             : INTEGER_ARRAY_TYPE;
                              ard_addr_range_array     : SLV64_ARRAY_TYPE)
                              return SLV64_ARRAY_TYPE is
    variable intr_ard_addr_range_array   : SLV64_ARRAY_TYPE(0 to ard_addr_range_array'length+1);
begin
    intr_ard_addr_range_array(0 to ard_addr_range_array'length-1) := ard_addr_range_array;
    if include_intr  then
       intr_ard_addr_range_array(2*get_id_index(ard_id_array,IPIF_INTR)) 
                        := ZERO_ADDR_PAD & intr_baseaddr;
       intr_ard_addr_range_array(2*get_id_index(ard_id_array,IPIF_INTR)+1) 
                        := ZERO_ADDR_PAD & intr_highaddr;
       return intr_ard_addr_range_array;
    else
        return ard_addr_range_array;
    end if;
end function add_intr_ard_addr_range_array;

function add_intr_ard_dwidth_array(include_intr    : boolean;
                              intr_dwidth           : integer;
                              ard_id_array          : INTEGER_ARRAY_TYPE;
                              ard_dwidth_array      : INTEGER_ARRAY_TYPE)
                              return INTEGER_ARRAY_TYPE is
    variable intr_ard_dwidth_array   : INTEGER_ARRAY_TYPE(0 to ard_dwidth_array'length);
begin
    intr_ard_dwidth_array(0 to ard_dwidth_array'length-1) := ard_dwidth_array;
    if include_intr  then
       intr_ard_dwidth_array(get_id_index(ard_id_array, IPIF_INTR)) := intr_dwidth;
       return intr_ard_dwidth_array;
    else
        return ard_dwidth_array;
    end if;
end function add_intr_ard_dwidth_array;

function add_intr_ard_num_ce_array(include_intr     : boolean;
                              ard_id_array          : INTEGER_ARRAY_TYPE;
                              ard_num_ce_array      : INTEGER_ARRAY_TYPE)
                              return INTEGER_ARRAY_TYPE is
    variable intr_ard_num_ce_array   : INTEGER_ARRAY_TYPE(0 to ard_num_ce_array'length);
begin
    intr_ard_num_ce_array(0 to ard_num_ce_array'length-1) := ard_num_ce_array;
    if include_intr  then
       intr_ard_num_ce_array(get_id_index(ard_id_array, IPIF_INTR)) := 16;
       return intr_ard_num_ce_array;
    else
        return ard_num_ce_array;
    end if;
end function add_intr_ard_num_ce_array;


end package body ipif_pkg;
