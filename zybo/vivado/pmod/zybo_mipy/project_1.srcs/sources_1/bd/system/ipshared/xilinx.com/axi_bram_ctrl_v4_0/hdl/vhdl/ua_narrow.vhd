-------------------------------------------------------------------------------
-- ua_narrow.vhd
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
-- Filename:        ua_narrow.vhd
--
-- Description:     Creates a narrow burst count load value when an operation
--                  is an unaligned narrow WRAP or INCR burst type.  Used by
--                  I_NARROW_CNT module.
--
-- VHDL-Standard:   VHDL'93
--
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
--
-------------------------------------------------------------------------------
--
-- History:
--
-- ^^^^^^
-- JLJ      2/2/2011         v1.03a
-- ~~~~~~
--  Migrate to v1.03a.
--  Plus minor code cleanup.
-- ^^^^^^
-- JLJ      2/4/2011       v1.03a
-- ~~~~~~
--  Edit for scalability and support of 512 and 1024-bit data widths.
-- ^^^^^^
-- JLJ      2/8/2011       v1.03a
-- ~~~~~~
--  Update bit vector usage of address LSB for calculating ua_narrow_load.
--  Add axi_bram_ctrl_funcs package inclusion.
-- ^^^^^^
-- JLJ      3/1/2011        v1.03a
-- ~~~~~~
--  Fix XST handling for DIV functions.  Create seperate process when
--  divisor is not constant and a power of two.
-- ^^^^^^
-- JLJ      3/2/2011        v1.03a
-- ~~~~~~
--  Update range of integer signals.
-- ^^^^^^
-- JLJ      3/4/2011        v1.03a
-- ~~~~~~
--  Remove use of local function, Create_Size_Max.
-- ^^^^^^
-- JLJ      3/11/2011        v1.03a
-- ~~~~~~
--  Remove C_AXI_DATA_WIDTH generate statments.
-- ^^^^^^
-- JLJ      3/14/2011        v1.03a
-- ~~~~~~
--  Update ua_narrow_load signal assignment to pass simulations & XST.
-- ^^^^^^
-- JLJ      3/15/2011        v1.03a
-- ~~~~~~
--  Update multiply function on signal, ua_narrow_wrap_gt_width, 
--  for timing path improvements.  Replace with left shift operation.
-- ^^^^^^
-- JLJ      3/17/2011      v1.03a
-- ~~~~~~
--  Add comments as noted in Spyglass runs. And general code clean-up.
-- ^^^^^^
--
--
-------------------------------------------------------------------------------

-- Library declarations

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.axi_bram_ctrl_funcs.all;


------------------------------------------------------------------------------


entity ua_narrow is
generic (


    C_AXI_DATA_WIDTH : integer := 32;
        -- Width of AXI data bus (in bits)

    C_BRAM_ADDR_ADJUST_FACTOR : integer := 32;
        -- Adjust BRAM address width based on C_AXI_DATA_WIDTH
        
    C_NARROW_BURST_CNT_LEN : integer := 4
        -- Size of narrow burst counter
      
    );
  port (

    curr_wrap_burst             : in    std_logic;
    curr_incr_burst             : in    std_logic;
    bram_addr_ld_en             : in    std_logic;

    curr_axlen                  : in    std_logic_vector (7 downto 0) := (others => '0');
    curr_axsize                 : in    std_logic_vector (2 downto 0) := (others => '0');
    curr_axaddr_lsb             : in    std_logic_vector (C_BRAM_ADDR_ADJUST_FACTOR-1 downto 0) := (others => '0');

    curr_ua_narrow_wrap         : out   std_logic;
    curr_ua_narrow_incr         : out   std_logic;

    ua_narrow_load              : out   std_logic_vector (C_NARROW_BURST_CNT_LEN-1 downto 0)
                                        := (others => '0')  
 

    );



end entity ua_narrow;


-------------------------------------------------------------------------------

architecture implementation of ua_narrow is

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

-- Determine the number of bytes based on the AXI data width.
constant C_AXI_DATA_WIDTH_BYTES          : integer := C_AXI_DATA_WIDTH/8;
constant C_AXI_DATA_WIDTH_BYTES_LOG2     : integer := log2(C_AXI_DATA_WIDTH_BYTES);


-- Use constant to compare when LSB of ADDR is equal to zero.
constant axaddr_lsb_zero          : std_logic_vector (C_BRAM_ADDR_ADJUST_FACTOR-1 downto 0) := (others => '0');

-- 8d = size of AxLEN vector
constant C_MAX_LSHIFT_SIZE  : integer := C_AXI_DATA_WIDTH_BYTES_LOG2 + 8;


-- Convert # of data bytes for AXI data bus into an unsigned vector (C_MAX_LSHIFT_SIZE:0).
constant C_AXI_DATA_WIDTH_BYTES_UNSIGNED : unsigned (C_MAX_LSHIFT_SIZE downto 0) := 
                                           to_unsigned (C_AXI_DATA_WIDTH_BYTES, C_MAX_LSHIFT_SIZE+1);


-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------

signal ua_narrow_wrap_gt_width      : std_logic := '0';
signal curr_axsize_unsigned         : unsigned (2 downto 0) := (others => '0');
signal curr_axsize_int          : integer := 0;

signal curr_axlen_unsigned          : unsigned (7 downto 0) := (others => '0');
signal curr_axlen_unsigned_lshift   : unsigned (C_MAX_LSHIFT_SIZE downto 0) := (others => '0');    -- Max = 32768d

signal bytes_per_addr           : integer := 1;     --    range 1 to 128 := 1;
signal size_plus_lsb            : integer range 1 to 256 := 1;
signal narrow_addr_offset       : integer := 1;



-------------------------------------------------------------------------------
-- Architecture Body
-------------------------------------------------------------------------------


begin 



    -- v1.03a
    
    -- Added for narrow INCR bursts with UA addresses
    -- Check if burst is a) INCR type,
    --                   b) a narrow burst (SIZE = full width of bus)
    --                   c) LSB of address is non zero
    curr_ua_narrow_incr <= '1' when (curr_incr_burst = '1') and
                                    (curr_axsize (2 downto 0) /= C_AXI_SIZE_MAX) and
                                    (curr_axaddr_lsb /= axaddr_lsb_zero) and 
                                    (bram_addr_ld_en = '1')
                                    else '0';

    -- v1.03a
    
    -- Detect narrow WRAP bursts
    -- Detect if the operation is a) WRAP type,
    --                            b) a narrow burst (SIZE = full width of bus)
    --                            c) LSB of address is non zero
    --                            d) complete size of WRAP is larger than width of BRAM
    
    curr_ua_narrow_wrap <= '1' when (curr_wrap_burst = '1') and
                                    (curr_axsize (2 downto 0) /= C_AXI_SIZE_MAX) and
                                    (curr_axaddr_lsb /= axaddr_lsb_zero) and 
                                    (bram_addr_ld_en = '1') and
                                    (ua_narrow_wrap_gt_width = '1')
                                    else '0';
    


    ---------------------------------------------------------------------------


    -- v1.03a

    -- Check condition if narrow burst wraps within the size of the BRAM width.
    -- Check if size * length > BRAM width in bytes.
    --
    -- When asserted = '1', means that narrow burst counter is not preloaded early,
    -- the BRAM burst will be contained within the BRAM data width.

    curr_axsize_unsigned <= unsigned (curr_axsize);
    curr_axsize_int <= to_integer (curr_axsize_unsigned);

    curr_axlen_unsigned <= unsigned (curr_axlen);


    -- Original logic with multiply function.
    --
    -- ua_narrow_wrap_gt_width <= '0' when (((2**(to_integer (curr_axsize_unsigned))) * 
    --                                       unsigned (curr_axlen (7 downto 0))) 
    --                                      < C_AXI_DATA_WIDTH_BYTES) 
    --                                else '1';


    -- Replace with left shift operation of AxLEN.
    -- Replace multiply of AxLEN * AxSIZE with a left shift function.
    LEN_LSHIFT: process (curr_axlen_unsigned, curr_axsize_int)
    begin
    
        for i in C_MAX_LSHIFT_SIZE downto 0 loop
        
            if (i >= curr_axsize_int + 8) then
                curr_axlen_unsigned_lshift (i) <= '0';
            elsif (i >= curr_axsize_int) then
                curr_axlen_unsigned_lshift (i) <= curr_axlen_unsigned (i - curr_axsize_int);
            else
                curr_axlen_unsigned_lshift (i) <= '0';
            end if;
        
        end loop;        
    
    end process LEN_LSHIFT;
        
        
    -- Final result.
    ua_narrow_wrap_gt_width <= '0' when (curr_axlen_unsigned_lshift < C_AXI_DATA_WIDTH_BYTES_UNSIGNED) 
                                   else '1';
                                   

    ---------------------------------------------------------------------------


    
    -- v1.03a
    
    -- For narrow burst transfer, provides the number of bytes per address
    
    -- XST does not support divisors that are not constants AND powers of two.
    -- Create process to create a fixed value for divisor.

    -- Replace this statement:
    --     bytes_per_addr <= C_AXI_DATA_WIDTH_BYTES / (2**(to_integer (curr_axsize_unsigned)));

    
    -- With this new process:
    -- Replace case statement with unsigned signal comparator.

    DIV_AXSIZE: process (curr_axsize)
    begin
    
        case (curr_axsize) is
            when "000" =>   bytes_per_addr <= C_AXI_DATA_WIDTH_BYTES / 1;
            when "001" =>   bytes_per_addr <= C_AXI_DATA_WIDTH_BYTES / 2;
            when "010" =>   bytes_per_addr <= C_AXI_DATA_WIDTH_BYTES / 4;
            when "011" =>   bytes_per_addr <= C_AXI_DATA_WIDTH_BYTES / 8;
            when "100" =>   bytes_per_addr <= C_AXI_DATA_WIDTH_BYTES / 16;
            when "101" =>   bytes_per_addr <= C_AXI_DATA_WIDTH_BYTES / 32;
            when "110" =>   bytes_per_addr <= C_AXI_DATA_WIDTH_BYTES / 64;
            when "111" =>   bytes_per_addr <= C_AXI_DATA_WIDTH_BYTES / 128;     -- Max SIZE for 1024-bit AXI bus
            when others => bytes_per_addr <= C_AXI_DATA_WIDTH_BYTES;
        end case;
    
    end process DIV_AXSIZE;

    
    
    -- Original statement.
    -- XST does not support divisors that are not constants AND powers of two.
    -- Insert process to perform (size_plus_lsb / size_bytes_int) function in generation of ua_narrow_load.
    --
    --      size_bytes_int <= (2**(to_integer (curr_axsize_unsigned)));
    --
    --      ua_narrow_load <= std_logic_vector (to_unsigned (bytes_per_addr - 
    --                                                       (size_plus_lsb / size_bytes_int), C_NARROW_BURST_CNT_LEN));


    
    -- AxSIZE + LSB of address
    -- Use all LSB address bit lanes for the narrow transfer based on C_S_AXI_DATA_WIDTH
    size_plus_lsb <= (2**(to_integer (curr_axsize_unsigned))) + 
                     to_integer (unsigned (curr_axaddr_lsb (C_AXI_DATA_WIDTH_BYTES_LOG2-1 downto 0)));
    

    -- Process to keep synthesis with divide by constants that are a power of 2.    
    DIV_SIZE_BYTES: process (size_plus_lsb, 
                             curr_axsize)
    begin
               
        -- Use unsigned w/ curr_axsize signal
        case (curr_axsize) is
        
            when "000" =>   narrow_addr_offset <= size_plus_lsb / 1;
            when "001" =>   narrow_addr_offset <= size_plus_lsb / 2;
            when "010" =>   narrow_addr_offset <= size_plus_lsb / 4;
            when "011" =>   narrow_addr_offset <= size_plus_lsb / 8;           
            when "100" =>   narrow_addr_offset <= size_plus_lsb / 16;
            when "101" =>   narrow_addr_offset <= size_plus_lsb / 32;
            when "110" =>   narrow_addr_offset <= size_plus_lsb / 64;
            when "111" =>   narrow_addr_offset <= size_plus_lsb / 128;     -- Max SIZE for 1024-bit AXI bus
            when others =>  narrow_addr_offset <= size_plus_lsb;
        end case;
    
    end process DIV_SIZE_BYTES;
    
    
    -- Final new statement.    
    -- Passing in simulation and XST.
    ua_narrow_load <= std_logic_vector (to_unsigned (bytes_per_addr - 
                                                     narrow_addr_offset, C_NARROW_BURST_CNT_LEN)) 
                      when (bytes_per_addr >= narrow_addr_offset) 
                      else std_logic_vector (to_unsigned (0, C_NARROW_BURST_CNT_LEN));
                      

   

    ---------------------------------------------------------------------------



end architecture implementation;











