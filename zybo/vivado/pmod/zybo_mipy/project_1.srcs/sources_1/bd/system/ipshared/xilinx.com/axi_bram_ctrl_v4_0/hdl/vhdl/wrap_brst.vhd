-------------------------------------------------------------------------------
-- wrap_brst.vhd
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
-- Filename:        wrap_brst.vhd
--
-- Description:     Create sub module for logic to generate WRAP burst
--                  address for rd_chnl and wr_chnl.
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
--  Add axi_bram_ctrl_funcs package inclusion.
-- ^^^^^^
-- JLJ      2/7/2011       v1.03a
-- ~~~~~~
--  Remove axi_bram_ctrl_funcs package use.
-- ^^^^^^
-- JLJ      3/15/2011       v1.03a
-- ~~~~~~
--  Update multiply function on signal, wrap_burst_total_cmb, 
--  for timing path improvements.  Replace with left shift operation.
-- ^^^^^^
-- JLJ      3/17/2011      v1.03a
-- ~~~~~~
--  Add comments as noted in Spyglass runs. And general code clean-up.
-- ^^^^^^
-- JLJ      3/24/2011      v1.03a
-- ~~~~~~
--  Add specific generate blocks based on C_AXI_DATA_WIDTH to calculate
--  total WRAP burst size for improved FPGA resource utilization.
-- ^^^^^^
-- JLJ      3/30/2011      v1.03a
-- ~~~~~~
--  Clean up code.
--  Re-code wrap_burst_total_cmb process blocks for each data width
--  to improve and catch all false conditions in code coverage analysis.
-- ^^^^^^
--
--
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

entity wrap_brst is
generic (


    C_AXI_ADDR_WIDTH : integer := 32;
        -- Width of AXI address bus (in bits)

    C_BRAM_ADDR_ADJUST_FACTOR : integer := 32;
        -- Adjust BRAM address width based on C_AXI_DATA_WIDTH

    C_AXI_DATA_WIDTH : integer := 32
        -- Width of AXI data bus (in bits)
      
    );
  port (


    S_AXI_AClk                  : in    std_logic;
    S_AXI_AResetn               : in    std_logic;


    curr_axlen                  : in    std_logic_vector(7 downto 0) := (others => '0');
    curr_axsize                 : in    std_logic_vector(2 downto 0) := (others => '0');

    curr_narrow_burst           : in    std_logic;
    narrow_bram_addr_inc_re     : in    std_logic;
    bram_addr_ld_en             : in    std_logic;
    bram_addr_ld                : in    std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)
                                        := (others => '0');
    bram_addr_int               : in    std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)
                                        := (others => '0');

    bram_addr_ld_wrap           : out   std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)
                                        := (others => '0');
    
    max_wrap_burst_mod          : out   std_logic := '0'   


    );


end entity wrap_brst;


-------------------------------------------------------------------------------

architecture implementation of wrap_brst is

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of implementation : architecture is "yes";

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

-- Reset active level (common through core)
constant C_RESET_ACTIVE     : std_logic := '0';


-- AXI Size Constants
constant C_AXI_SIZE_1BYTE       : std_logic_vector (2 downto 0) := "000";   -- 1 byte
constant C_AXI_SIZE_2BYTE       : std_logic_vector (2 downto 0) := "001";   -- 2 bytes
constant C_AXI_SIZE_4BYTE       : std_logic_vector (2 downto 0) := "010";   -- 4 bytes = max size for 32-bit BRAM
constant C_AXI_SIZE_8BYTE       : std_logic_vector (2 downto 0) := "011";   -- 8 bytes = max size for 64-bit BRAM
constant C_AXI_SIZE_16BYTE      : std_logic_vector (2 downto 0) := "100";   -- 16 bytes = max size for 128-bit BRAM
constant C_AXI_SIZE_32BYTE      : std_logic_vector (2 downto 0) := "101";   -- 32 bytes = max size for 256-bit BRAM
constant C_AXI_SIZE_64BYTE      : std_logic_vector (2 downto 0) := "110";   -- 64 bytes = max size for 512-bit BRAM
constant C_AXI_SIZE_128BYTE     : std_logic_vector (2 downto 0) := "111";   -- 128 bytes = max size for 1024-bit BRAM


-- Determine the number of bytes based on the AXI data width.
constant C_AXI_DATA_WIDTH_BYTES     : integer := C_AXI_DATA_WIDTH/8;
constant C_AXI_DATA_WIDTH_BYTES_LOG2     : integer := log2(C_AXI_DATA_WIDTH_BYTES);

-- 8d = size of AxLEN vector
constant C_MAX_LSHIFT_SIZE  : integer := C_AXI_DATA_WIDTH_BYTES_LOG2 + 8;

-- Constants for WRAP size decoding to simplify integer represenation.
constant C_WRAP_SIZE_2      : std_logic_vector (2 downto 0) := "001";
constant C_WRAP_SIZE_4      : std_logic_vector (2 downto 0) := "010";
constant C_WRAP_SIZE_8      : std_logic_vector (2 downto 0) := "011";
constant C_WRAP_SIZE_16     : std_logic_vector (2 downto 0) := "100";



-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------

signal max_wrap_burst           : std_logic := '0';

signal save_init_bram_addr_ld       : std_logic_vector (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR+1)
                                        := (others => '0');

-- signal curr_axsize_unsigned     : unsigned (2 downto 0) := (others => '0');
-- signal curr_axsize_int          : integer := 0;
-- signal curr_axlen_unsigned      : unsigned (7 downto 0) := (others => '0');

-- Holds burst length/size total (based on width of BRAM width)
-- Max size = max length of burst (256 beats)
-- signal wrap_burst_total_cmb     : integer range 0 to 256 := 1;      -- Max 256 (= 32768d / 128 bytes)
-- signal wrap_burst_total         : integer range 0 to 256 := 1;

signal wrap_burst_total_cmb     : std_logic_vector (2 downto 0) := (others => '0');
signal wrap_burst_total         : std_logic_vector (2 downto 0) := (others => '0');

-- signal curr_axlen_unsigned_plus1          : unsigned (7 downto 0) := (others => '0');
-- signal curr_axlen_unsigned_plus1_lshift   : unsigned (C_MAX_LSHIFT_SIZE downto 0) := (others => '0');  -- Max = 32768d


-------------------------------------------------------------------------------
-- Architecture Body
-------------------------------------------------------------------------------


begin 


        ---------------------------------------------------------------------------


        -- Modify counter size based on size of current write burst operation
        -- For WRAP burst types, the counter value will roll over when the burst
        -- boundary is reached.

        -- Based on AxSIZE and AxLEN
        -- To minimize muxing on initial load of counter value
        -- Detect on WRAP burst types, when the max address is reached.
        -- When the max address is reached, re-load counter with lower
        -- address value.

        -- Save initial load address value.

        REG_INIT_BRAM_ADDR: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then

                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    save_init_bram_addr_ld <= (others => '0');
                    
                elsif (bram_addr_ld_en = '1') then 
                    save_init_bram_addr_ld <= bram_addr_ld(C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR+1);
                else
                    save_init_bram_addr_ld <= save_init_bram_addr_ld;
                end if;

            end if;
        end process REG_INIT_BRAM_ADDR;


        ---------------------------------------------------------------------------



        -- v1.03a
        
        -- Calculate AXI size (integer)
        --  curr_axsize_unsigned <= unsigned (curr_axsize);
        --  curr_axsize_int <= to_integer (curr_axsize_unsigned);

        -- Calculate AXI length (integer)
        --  curr_axlen_unsigned <= unsigned (curr_axlen);
        --  curr_axlen_unsigned_plus1 <= curr_axlen_unsigned + "00000001";
        

        -- WRAP = size * length (based on BRAM data width in bytes)
        --
        -- Original multiply function:
        -- wrap_burst_total_cmb <= (size_bytes_int * len_int) / C_AXI_DATA_WIDTH_BYTES;


        -- For XST, modify integer multiply function to improve timing.  
        -- Replace multiply of AxLEN * AxSIZE with a left shift function.
        --  LEN_LSHIFT: process (curr_axlen_unsigned_plus1, curr_axsize_int)
        --  begin
        --  
        --      for i in C_MAX_LSHIFT_SIZE downto 0 loop
        --      
        --          if (i >= curr_axsize_int + 8) then
        --              curr_axlen_unsigned_plus1_lshift (i) <= '0';
        --          elsif (i >= curr_axsize_int) then
        --              curr_axlen_unsigned_plus1_lshift (i) <= curr_axlen_unsigned_plus1 (i - curr_axsize_int);
        --          else
        --              curr_axlen_unsigned_plus1_lshift (i) <= '0';
        --          end if;
        --      
        --      end loop;        
        --  
        --  end process LEN_LSHIFT;


        -- Final signal assignment for XST & timing improvements.
        --  wrap_burst_total_cmb <= to_integer (curr_axlen_unsigned_plus1_lshift) / C_AXI_DATA_WIDTH_BYTES;



        ---------------------------------------------------------------------------



        -- v1.03a
        
        -- For best FPGA resource implementation, hard code the generation of
        -- WRAP burst size based on each C_AXI_DATA_WIDTH possibility.

                
        ---------------------------------------------------------------------------
        -- Generate:    GEN_32_WRAP_SIZE
        -- Purpose:     These wrap size values only apply to 32-bit BRAM.
        ---------------------------------------------------------------------------

        GEN_32_WRAP_SIZE: if C_AXI_DATA_WIDTH = 32 generate
        begin
        
            WRAP_SIZE_CMB: process (curr_axlen, curr_axsize)
            begin
            
            
                -- v1.03a
                -- Attempt to re code this to improve conditional coverage checks.
                -- Use case statment to replace if/else with no priority enabled.
                
                -- Current size of transaction
                case (curr_axsize (2 downto 0)) is
                    
                    -- 4 bytes (full AXI size)
                    when C_AXI_SIZE_4BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0001" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "0011" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_16;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                
                    -- 2 bytes (1/2 AXI size)
                    when C_AXI_SIZE_2BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0011" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;

                    -- 1 byte (1/4 AXI size)
                    when C_AXI_SIZE_1BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                
                    when others =>  wrap_burst_total_cmb <= (others => '0');
            
                end case;
                
                
                
                -- v1.03 Original HDL
                --     
                --     
                --     if ((curr_axlen (3 downto 0) = "0001") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_4BYTE)) or
                --        ((curr_axlen (3 downto 0) = "0011") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_2BYTE)) or
                --        ((curr_axlen (3 downto 0) = "0111") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_1BYTE)) then   
                --     
                --         wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                --      
                --     elsif ((curr_axlen (3 downto 0) = "0011") and 
                --            (curr_axsize (2 downto 0) = C_AXI_SIZE_4BYTE)) or
                --           ((curr_axlen (3 downto 0) = "0111") and 
                --            (curr_axsize (2 downto 0) = C_AXI_SIZE_2BYTE)) or
                --           ((curr_axlen (3 downto 0) = "1111") and 
                --            (curr_axsize (2 downto 0) = C_AXI_SIZE_1BYTE)) then
                --            
                --         wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                --     
                --     elsif ((curr_axlen (3 downto 0) = "0111") and 
                --            (curr_axsize (2 downto 0) = C_AXI_SIZE_4BYTE)) or
                --           ((curr_axlen (3 downto 0) = "1111") and 
                --            (curr_axsize (2 downto 0) = C_AXI_SIZE_2BYTE)) then
                --     
                --         wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                --     
                --     elsif ((curr_axlen (3 downto 0) = "1111") and 
                --            (curr_axsize (2 downto 0) = C_AXI_SIZE_4BYTE)) then
                --                 
                --         wrap_burst_total_cmb <= C_WRAP_SIZE_16;
                --     
                --     else                
                --         wrap_burst_total_cmb <= (others => '0');
                --     end if;                    
                            
                            
            end process WRAP_SIZE_CMB;
                
        end generate GEN_32_WRAP_SIZE;
        


                
        ---------------------------------------------------------------------------
        -- Generate:    GEN_64_WRAP_SIZE
        -- Purpose:     These wrap size values only apply to 64-bit BRAM.
        ---------------------------------------------------------------------------

        GEN_64_WRAP_SIZE: if C_AXI_DATA_WIDTH = 64 generate
        begin
        
            WRAP_SIZE_CMB: process (curr_axlen, curr_axsize)
            begin
            

                -- v1.03a
                -- Attempt to re code this to improve conditional coverage checks.
                -- Use case statment to replace if/else with no priority enabled.
                
                -- Current size of transaction
                case (curr_axsize (2 downto 0)) is

                    -- 8 bytes (full AXI size)
                    when C_AXI_SIZE_8BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0001" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "0011" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_16;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                    
                    -- 4 bytes (1/2 AXI size)
                    when C_AXI_SIZE_4BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0011" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                
                    -- 2 bytes (1/4 AXI size)
                    when C_AXI_SIZE_2BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;

                    -- 1 byte (1/8 AXI size)
                    when C_AXI_SIZE_1BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                
                    when others =>  wrap_burst_total_cmb <= (others => '0');
            
                end case;
                


                -- v1.03 Original HDL
                --    
                --    
                --    if ((curr_axlen (3 downto 0) = "0001") and 
                --        (curr_axsize (2 downto 0) = C_AXI_SIZE_8BYTE)) or
                --       ((curr_axlen (3 downto 0) = "0011") and 
                --        (curr_axsize (2 downto 0) = C_AXI_SIZE_4BYTE)) or
                --       ((curr_axlen (3 downto 0) = "0111") and 
                --        (curr_axsize (2 downto 0) = C_AXI_SIZE_2BYTE)) or
                --       ((curr_axlen (3 downto 0) = "1111") and 
                --        (curr_axsize (2 downto 0) = C_AXI_SIZE_1BYTE)) then
                --    
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                --     
                --    elsif ((curr_axlen (3 downto 0) = "0011") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_8BYTE)) or
                --          ((curr_axlen (3 downto 0) = "0111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_4BYTE)) or
                --          ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_2BYTE)) then
                --          
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                --    
                --    elsif ((curr_axlen (3 downto 0) = "0111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_8BYTE)) or
                --          ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_4BYTE)) then
                --    
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                --    
                --    elsif ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_8BYTE)) then
                --                
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_16;
                --    
                --    else                
                --        wrap_burst_total_cmb <= (others => '0');
                --    end if;                    
                
                
                            
            end process WRAP_SIZE_CMB;
                
        end generate GEN_64_WRAP_SIZE;
        


                
        ---------------------------------------------------------------------------
        -- Generate:    GEN_128_WRAP_SIZE
        -- Purpose:     These wrap size values only apply to 128-bit BRAM.
        ---------------------------------------------------------------------------

        GEN_128_WRAP_SIZE: if C_AXI_DATA_WIDTH = 128 generate
        begin
        
            WRAP_SIZE_CMB: process (curr_axlen, curr_axsize)
            begin
            

                -- v1.03a
                -- Attempt to re code this to improve conditional coverage checks.
                -- Use case statment to replace if/else with no priority enabled.
                
                -- Current size of transaction
                case (curr_axsize (2 downto 0)) is

                    -- 16 bytes (full AXI size)
                    when C_AXI_SIZE_16BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0001" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "0011" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_16;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                    
                    -- 8 bytes (1/2 AXI size)
                    when C_AXI_SIZE_8BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0011" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                
                    -- 4 bytes (1/4 AXI size)
                    when C_AXI_SIZE_4BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;

                    -- 2 bytes (1/8 AXI size)
                    when C_AXI_SIZE_2BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                
                    when others =>  wrap_burst_total_cmb <= (others => '0');
            
                end case;
                


                -- v1.03 Original HDL
                --    
                --     if ((curr_axlen (3 downto 0) = "0001") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_16BYTE)) or
                --        ((curr_axlen (3 downto 0) = "0011") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_8BYTE)) or
                --        ((curr_axlen (3 downto 0) = "0111") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_4BYTE)) or
                --        ((curr_axlen (3 downto 0) = "1111") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_2BYTE)) then 
                --    
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                --     
                --    elsif ((curr_axlen (3 downto 0) = "0011") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_16BYTE)) or
                --          ((curr_axlen (3 downto 0) = "0111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_8BYTE)) or
                --          ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_4BYTE)) then
                --          
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                --    
                --    elsif ((curr_axlen (3 downto 0) = "0111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_16BYTE)) or
                --          ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_8BYTE)) then
                --    
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                --    
                --    elsif ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_16BYTE)) then
                --                
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_16;
                --    
                --    else                
                --        wrap_burst_total_cmb <= (others => '0');
                --    end if;                    
                            
                            
                            
            end process WRAP_SIZE_CMB;
                
        end generate GEN_128_WRAP_SIZE;
        


                
        ---------------------------------------------------------------------------
        -- Generate:    GEN_256_WRAP_SIZE
        -- Purpose:     These wrap size values only apply to 256-bit BRAM.
        ---------------------------------------------------------------------------

        GEN_256_WRAP_SIZE: if C_AXI_DATA_WIDTH = 256 generate
        begin
        
            WRAP_SIZE_CMB: process (curr_axlen, curr_axsize)
            begin
            

                -- v1.03a
                -- Attempt to re code this to improve conditional coverage checks.
                -- Use case statment to replace if/else with no priority enabled.
                
                -- Current size of transaction
                case (curr_axsize (2 downto 0)) is

                    -- 32 bytes (full AXI size)
                    when C_AXI_SIZE_32BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0001" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "0011" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_16;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                    
                    -- 16 bytes (1/2 AXI size)
                    when C_AXI_SIZE_16BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0011" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                
                    -- 8 bytes (1/4 AXI size)
                    when C_AXI_SIZE_8BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;

                    -- 4 bytes (1/8 AXI size)
                    when C_AXI_SIZE_4BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                
                    when others =>  wrap_burst_total_cmb <= (others => '0');
            
                end case;
                


                -- v1.03 Original HDL
                --    
                --     if ((curr_axlen (3 downto 0) = "0001") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_32BYTE)) or
                --        ((curr_axlen (3 downto 0) = "0011") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_16BYTE)) or
                --        ((curr_axlen (3 downto 0) = "0111") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_8BYTE)) or
                --        ((curr_axlen (3 downto 0) = "1111") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_4BYTE)) then   
                --    
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                --     
                --    elsif ((curr_axlen (3 downto 0) = "0011") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_32BYTE)) or
                --          ((curr_axlen (3 downto 0) = "0111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_16BYTE)) or
                --          ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_8BYTE)) then
                --           
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                --    
                --    elsif ((curr_axlen (3 downto 0) = "0111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_32BYTE)) or
                --          ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_16BYTE)) then
                --    
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                --    
                --    elsif ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_32BYTE)) then
                --                
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_16;
                --    
                --    else                
                --        wrap_burst_total_cmb <= (others => '0');
                --    end if;   
                
                
                            
            end process WRAP_SIZE_CMB;
                
        end generate GEN_256_WRAP_SIZE;
        


                
        ---------------------------------------------------------------------------
        -- Generate:    GEN_512_WRAP_SIZE
        -- Purpose:     These wrap size values only apply to 512-bit BRAM.
        ---------------------------------------------------------------------------

        GEN_512_WRAP_SIZE: if C_AXI_DATA_WIDTH = 512 generate
        begin
        
            WRAP_SIZE_CMB: process (curr_axlen, curr_axsize)
            begin
            

                -- v1.03a
                -- Attempt to re code this to improve conditional coverage checks.
                -- Use case statment to replace if/else with no priority enabled.
                
                -- Current size of transaction
                case (curr_axsize (2 downto 0)) is

                    -- 64 bytes (full AXI size)
                    when C_AXI_SIZE_64BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0001" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "0011" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_16;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                    
                    -- 32 bytes (1/2 AXI size)
                    when C_AXI_SIZE_32BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0011" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                
                    -- 16 bytes (1/4 AXI size)
                    when C_AXI_SIZE_16BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;

                    -- 8 bytes (1/8 AXI size)
                    when C_AXI_SIZE_8BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                
                    when others =>  wrap_burst_total_cmb <= (others => '0');
            
                end case;
                


                -- v1.03 Original HDL
                --    
                --    
                --     if ((curr_axlen (3 downto 0) = "0001") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_64BYTE)) or
                --        ((curr_axlen (3 downto 0) = "0011") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_32BYTE)) or
                --        ((curr_axlen (3 downto 0) = "0111") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_16BYTE)) or
                --        ((curr_axlen (3 downto 0) = "1111") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_8BYTE)) then   
                --    
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                --     
                --    elsif ((curr_axlen (3 downto 0) = "0011") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_64BYTE)) or
                --          ((curr_axlen (3 downto 0) = "0111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_32BYTE)) or
                --          ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_16BYTE)) then
                --           
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                --    
                --    elsif ((curr_axlen (3 downto 0) = "0111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_64BYTE)) or
                --          ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_32BYTE)) then
                --    
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                --    
                --    elsif ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_64BYTE)) then
                --                
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_16;
                --    
                --    else                
                --        wrap_burst_total_cmb <= (others => '0');
                --    end if;                    
                
                            
            end process WRAP_SIZE_CMB;
                
        end generate GEN_512_WRAP_SIZE;
        


                
        ---------------------------------------------------------------------------
        -- Generate:    GEN_1024_WRAP_SIZE
        -- Purpose:     These wrap size values only apply to 1024-bit BRAM.
        ---------------------------------------------------------------------------

        GEN_1024_WRAP_SIZE: if C_AXI_DATA_WIDTH = 1024 generate
        begin
        
            WRAP_SIZE_CMB: process (curr_axlen, curr_axsize)
            begin
            

                -- v1.03a
                -- Attempt to re code this to improve conditional coverage checks.
                -- Use case statment to replace if/else with no priority enabled.
                
                -- Current size of transaction
                case (curr_axsize (2 downto 0)) is

                    -- 128 bytes (full AXI size)
                    when C_AXI_SIZE_128BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0001" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "0011" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_16;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                    
                    -- 64 bytes (1/2 AXI size)
                    when C_AXI_SIZE_64BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0011" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                
                    -- 32 bytes (1/4 AXI size)
                    when C_AXI_SIZE_32BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "0111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;

                    -- 16 bytes (1/8 AXI size)
                    when C_AXI_SIZE_16BYTE =>
            
                        case (curr_axlen (3 downto 0)) is 
                            when "1111" =>  wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                            when others =>  wrap_burst_total_cmb <= (others => '0');
                        end case;
                
                    when others =>  wrap_burst_total_cmb <= (others => '0');
            
                end case;
                


                -- v1.03 Original HDL
                --    
                --    
                --     if ((curr_axlen (3 downto 0) = "0001") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_128BYTE)) or
                --        ((curr_axlen (3 downto 0) = "0011") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_64BYTE)) or
                --        ((curr_axlen (3 downto 0) = "0111") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_32BYTE)) or
                --        ((curr_axlen (3 downto 0) = "1111") and 
                --         (curr_axsize (2 downto 0) = C_AXI_SIZE_16BYTE)) then   
                --    
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_2;
                --     
                --    elsif ((curr_axlen (3 downto 0) = "0011") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_128BYTE)) or
                --          ((curr_axlen (3 downto 0) = "0111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_64BYTE)) or
                --          ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_32BYTE)) then
                --           
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_4;
                --    
                --    elsif ((curr_axlen (3 downto 0) = "0111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_128BYTE)) or
                --          ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_64BYTE)) then
                --    
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_8;
                --    
                --    elsif ((curr_axlen (3 downto 0) = "1111") and 
                --           (curr_axsize (2 downto 0) = C_AXI_SIZE_128BYTE)) then
                --                
                --        wrap_burst_total_cmb <= C_WRAP_SIZE_16;
                --    
                --    else                
                --        wrap_burst_total_cmb <= (others => '0');
                --    end if;                    
                            
                            
            end process WRAP_SIZE_CMB;
                
        end generate GEN_1024_WRAP_SIZE;
        
        
        

        ---------------------------------------------------------------------------



        -- Early decode to determine size of WRAP transfer
        -- Goal to break up long timing path to generate max_wrap_burst signal.
        
        REG_WRAP_TOTAL: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    wrap_burst_total <= (others => '0');

                elsif (bram_addr_ld_en = '1') then
                    wrap_burst_total <= wrap_burst_total_cmb;
                else
                    wrap_burst_total <= wrap_burst_total;
                end if;
            end if;

        end process REG_WRAP_TOTAL;


        ---------------------------------------------------------------------------


        CHECK_WRAP_MAX : process ( wrap_burst_total,                                   
                                   bram_addr_int,
                                   save_init_bram_addr_ld )
        begin

           
            -- Check BRAM address value if max value is reached.
            -- Max value is based on burst size/length for operation.
            -- Address bits to check vary based on C_S_AXI_DATA_WIDTH and burst size/length.
            -- (use signal, wrap_burst_total, based on current WRAP burst size/length/data width).

            case wrap_burst_total is
            
            when C_WRAP_SIZE_2 => 
                if (bram_addr_int (C_BRAM_ADDR_ADJUST_FACTOR) = '1') then
                    max_wrap_burst <= '1';
                else
                    max_wrap_burst <= '0';
                end if;

                -- Use saved BRAM load value
                bram_addr_ld_wrap (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR+1) <= 
                    save_init_bram_addr_ld (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR+1);
                
                -- Reset lower order address bits to zero (to wrap address)
                bram_addr_ld_wrap (C_BRAM_ADDR_ADJUST_FACTOR) <= '0';
                
            when C_WRAP_SIZE_4 =>     
                if (bram_addr_int (C_BRAM_ADDR_ADJUST_FACTOR + 1 downto C_BRAM_ADDR_ADJUST_FACTOR) = "11") then
                    max_wrap_burst <= '1';
                else
                    max_wrap_burst <= '0';
                end if;

                -- Use saved BRAM load value
                bram_addr_ld_wrap (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR+2) <= 
                    save_init_bram_addr_ld (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR+2);
                
                -- Reset lower order address bits to zero (to wrap address)
                bram_addr_ld_wrap (C_BRAM_ADDR_ADJUST_FACTOR + 1 downto C_BRAM_ADDR_ADJUST_FACTOR ) <= "00";

                
            when C_WRAP_SIZE_8 =>     
                if (bram_addr_int (C_BRAM_ADDR_ADJUST_FACTOR + 2 downto C_BRAM_ADDR_ADJUST_FACTOR) = "111") then
                    max_wrap_burst <= '1';
                else
                    max_wrap_burst <= '0';
                end if;

                -- Use saved BRAM load value
                bram_addr_ld_wrap (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR+3) <= 
                    save_init_bram_addr_ld (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR+3);
                    
                -- Reset lower order address bits to zero (to wrap address)
                bram_addr_ld_wrap (C_BRAM_ADDR_ADJUST_FACTOR + 2 downto C_BRAM_ADDR_ADJUST_FACTOR ) <= "000";
                
            when C_WRAP_SIZE_16 =>     
                if (bram_addr_int (C_BRAM_ADDR_ADJUST_FACTOR + 3 downto C_BRAM_ADDR_ADJUST_FACTOR) = "1111") then
                    max_wrap_burst <= '1';
                else
                    max_wrap_burst <= '0';
                end if;

                -- Use saved BRAM load value
                bram_addr_ld_wrap (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR+4) <= 
                    save_init_bram_addr_ld (C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR+4);
                    
                -- Reset lower order address bits to zero (to wrap address)
                bram_addr_ld_wrap (C_BRAM_ADDR_ADJUST_FACTOR + 3 downto C_BRAM_ADDR_ADJUST_FACTOR ) <= "0000";

            when others => 
                max_wrap_burst <= '0';
                bram_addr_ld_wrap(C_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR+1) <= save_init_bram_addr_ld;
                -- Reset lower order address bits to zero (to wrap address)
                bram_addr_ld_wrap (C_BRAM_ADDR_ADJUST_FACTOR) <= '0';             
            end case;

            

        end process CHECK_WRAP_MAX;


        ---------------------------------------------------------------------------


        -- Move outside of CHECK_WRAP_MAX process.
        -- Account for narrow burst operations.
        --
        -- Currently max_wrap_burst is getting asserted at the first address beat to BRAM
        -- that indicates the maximum WRAP burst boundary.  Must wait for the completion of the
        -- narrow wrap burst counter to assert max_wrap_burst.
        --
        -- Indicates when narrow burst address counter hits max (all zeros value)          
        -- narrow_bram_addr_inc_re
        
        max_wrap_burst_mod <= max_wrap_burst when (curr_narrow_burst = '0') else
                              (max_wrap_burst and narrow_bram_addr_inc_re);


        ---------------------------------------------------------------------------



end architecture implementation;











