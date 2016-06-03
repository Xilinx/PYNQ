--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.family_support.all;

package common_types is

-- TYPE DECLARATIONS
type    SLV32_ARRAY_TYPE is array (natural range <>) of std_logic_vector(0 to 31);
subtype SLV64_TYPE is std_logic_vector(0 to 63);
type    SLV64_ARRAY_TYPE is array (natural range <>) of SLV64_TYPE;
type    INTEGER_ARRAY_TYPE is array (natural range <>) of integer;


-- FUNCTION GENERATIONS
function calc_num_ce (ce_num_array : INTEGER_ARRAY_TYPE) return integer;

function calc_start_ce_index (ce_num_array : INTEGER_ARRAY_TYPE;
                              index        : integer) return integer;
										
function clog2(x : positive) return natural;									

end common_types;

package body common_types is

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

 
end common_types;
