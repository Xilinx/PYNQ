-------------------------------------------------------------------
-- (c) Copyright 1984 - 2012 Xilinx, Inc. All rights reserved.	 --
--								 --
-- This file contains confidential and proprietary information	 --
-- of Xilinx, Inc. and is protected under U.S. and		 --
-- international copyright and other intellectual property	 --
-- laws.							 --
--								 --
-- DISCLAIMER							 --
-- This disclaimer is not a license and does not grant any	 --
-- rights to the materials distributed herewith. Except as	 --
-- otherwise provided in a valid license issued to you by	 --
-- Xilinx, and to the maximum extent permitted by applicable	 --
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND	 --
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES	 --
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING	 --
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-	 --
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and	 --
-- (2) Xilinx shall not be liable (whether in contract or tort,	 --
-- including negligence, or under any other theory of		 --
-- liability) for any loss or damage of any kind or nature	 --
-- related to, arising under or in connection with these	 --
-- materials, including for any direct, or any indirect,	 --
-- special, incidental, or consequential loss or damage		 --
-- (including loss of data, profits, goodwill, or any type of	 --
-- loss or damage suffered as a result of any action brought	 --
-- by a third party) even if such damage or loss was		 --
-- reasonably foreseeable or Xilinx had been advised of the	 --
-- possibility of the same.					 --
--								 --
-- CRITICAL APPLICATIONS					 --
-- Xilinx products are not designed or intended to be fail-	 --
-- safe, or for use in any application requiring fail-safe	 --
-- performance, such as life-support or safety devices or	 --
-- systems, Class III medical devices, nuclear facilities,	 --
-- applications related to the deployment of airbags, or any	 --
-- other applications that could lead to death, personal	 --
-- injury, or severe property or environmental damage		 --
-- (individually and collectively, "Critical			 --
-- Applications"). Customer assumes the sole risk and		 --
-- liability of any use of Xilinx products in Critical		 --
-- Applications, subject only to applicable laws and		 --
-- regulations governing limitations on product liability.	 --
--								 --
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS	 --
-- PART OF THIS FILE AT ALL TIMES. 				 --
-------------------------------------------------------------------
-- ************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        address_decoder.vhd
-- Version:         v1.01.a
-- Description:     Address decoder utilizing unconstrained arrays for Base
--                  Address specification and ce number.
-------------------------------------------------------------------------------
-- Structure:   This section shows the hierarchical structure of axi_lite_ipif.
--
--              --axi_lite_ipif.vhd
--                    --slave_attachment.vhd
--                       --address_decoder.vhd
-------------------------------------------------------------------------------
-- Author:      BSB
--
-- History:
--
--  BSB      05/20/10      -- First version
-- ~~~~~~
--  - Created the first version v1.00.a
-- ^^^^^^
-- ~~~~~~
--  SK       08/09/2010    --
--  - updated the core with optimziation. Closed CR 574507
--  - combined the CE generation logic to further optimize the code.
-- ^^^^^^
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

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_types.all;

-------------------------------------------------------------------------------
--                     Definition of Generics
-------------------------------------------------------------------------------
-- C_BUS_AWIDTH          -- Address bus width
-- C_S_AXI_MIN_SIZE      -- Minimum address range of the IP
-- C_ARD_ADDR_RANGE_ARRAY-- Base /High Address Pair for each Address Range
-- C_ARD_NUM_CE_ARRAY    -- Desired number of chip enables for an address range
-- C_FAMILY              -- Target FPGA family
-------------------------------------------------------------------------------
--                  Definition of Ports
-------------------------------------------------------------------------------
-- Bus_clk               -- Clock
-- Bus_rst               -- Reset
-- Address_In_Erly       -- Adddress in
-- Address_Valid_Erly    -- Address is valid
-- Bus_RNW               -- Read or write registered
-- Bus_RNW_Erly          -- Read or Write
-- CS_CE_ld_enable       -- chip select and chip enable registered
-- Clear_CS_CE_Reg       -- Clear_CS_CE_Reg clear
-- RW_CE_ld_enable       -- Read or Write Chip Enable
-- CS_for_gaps           -- CS generation for the gaps between address ranges
-- CS_Out                -- Chip select
-- RdCE_Out              -- Read Chip enable
-- WrCE_Out              -- Write chip enable
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Entity Declaration
-------------------------------------------------------------------------------

entity address_decoder is
    generic (
        C_BUS_AWIDTH          : integer := 32;
        C_S_AXI_MIN_SIZE      : std_logic_vector(0 to 31) := X"000001FF";
        C_ARD_ADDR_RANGE_ARRAY: SLV64_ARRAY_TYPE :=
            (
             X"0000_0000_1000_0000", --  IP user0 base address
             X"0000_0000_1000_01FF", --  IP user0 high address
             X"0000_0000_1000_0200", --  IP user1 base address
             X"0000_0000_1000_02FF"  --  IP user1 high address
            );
        C_ARD_NUM_CE_ARRAY  : INTEGER_ARRAY_TYPE :=
            (
             8,     -- User0 CE Number
             1      -- User1 CE Number
            );
        C_FAMILY            : string  := "virtex6"
    );
  port (
        Bus_clk             : in  std_logic;
        Bus_rst             : in  std_logic;

        -- PLB Interface signals
        Address_In_Erly     : in  std_logic_vector(0 to C_BUS_AWIDTH-1);
        Address_Valid_Erly  : in  std_logic;
        Bus_RNW             : in  std_logic;
        Bus_RNW_Erly        : in  std_logic;

        -- Registering control signals
        CS_CE_ld_enable     : in  std_logic;
        Clear_CS_CE_Reg     : in  std_logic;
        RW_CE_ld_enable     : in  std_logic;
        CS_for_gaps         : out std_logic;
        -- Decode output signals
        CS_Out              : out std_logic_vector
                                (0 to ((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1);
        RdCE_Out            : out std_logic_vector
                                (0 to calc_num_ce(C_ARD_NUM_CE_ARRAY)-1);
        WrCE_Out            : out std_logic_vector
                                (0 to calc_num_ce(C_ARD_NUM_CE_ARRAY)-1)
    );
end entity address_decoder;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture IMP of address_decoder is

-- local type declarations ----------------------------------------------------
type decode_bit_array_type is Array(natural range 0 to (
                           (C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1) of
                           integer;

type short_addr_array_type is Array(natural range 0 to
                           C_ARD_ADDR_RANGE_ARRAY'LENGTH-1) of
                           std_logic_vector(0 to C_BUS_AWIDTH-1);
-------------------------------------------------------------------------------
-- Function Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- This function converts a 64 bit address range array to a AWIDTH bit
-- address range array.
-------------------------------------------------------------------------------
function slv64_2_slv_awidth(slv64_addr_array   : SLV64_ARRAY_TYPE;
                            awidth             : integer)
                        return short_addr_array_type is

    variable temp_addr   : std_logic_vector(0 to 63);
    variable slv_array   : short_addr_array_type;
    begin
        for array_index in 0 to slv64_addr_array'length-1 loop
            temp_addr := slv64_addr_array(array_index);
            slv_array(array_index) := temp_addr((64-awidth) to 63);
        end loop;
        return(slv_array);
    end function slv64_2_slv_awidth;

-------------------------------------------------------------------------------
--Function Addr_bits
--function to convert an address range (base address and an upper address)
--into the number of upper address bits needed for decoding a device
--select signal.  will handle slices and big or little endian
-------------------------------------------------------------------------------
function Addr_Bits (x,y : std_logic_vector(0 to C_BUS_AWIDTH-1))
                    return integer is
    variable addr_nor : std_logic_vector(0 to C_BUS_AWIDTH-1);
    begin
        addr_nor := x xor y;
        for i in 0 to C_BUS_AWIDTH-1 loop
            if addr_nor(i)='1' then
                return i;
            end if;
        end loop;
--coverage off
        return(C_BUS_AWIDTH);
--coverage on
    end function Addr_Bits;


-------------------------------------------------------------------------------
--Function Get_Addr_Bits
--function calculates the array which has the decode bits for the each address
--range.
-------------------------------------------------------------------------------
function Get_Addr_Bits (baseaddrs : short_addr_array_type)
                        return decode_bit_array_type is

    variable num_bits : decode_bit_array_type;
    begin
        for i in 0 to ((baseaddrs'length)/2)-1 loop

            num_bits(i) :=  Addr_Bits (baseaddrs(i*2),
                                       baseaddrs(i*2+1));
        end loop;
        return(num_bits);
    end function Get_Addr_Bits;


-------------------------------------------------------------------------------
-- NEEDED_ADDR_BITS
--
-- Function Description:
--  This function calculates the number of address bits required
-- to support the CE generation logic. This is determined by
-- multiplying the number of CEs for an address space by the
-- data width of the address space (in bytes). Each address
-- space entry is processed and the biggest of the spaces is
-- used to set the number of address bits required to be latched
-- and used for CE decoding. A minimum value of 1 is returned by
-- this function.
--
-------------------------------------------------------------------------------
function needed_addr_bits (ce_array   : INTEGER_ARRAY_TYPE)
                            return integer is

    constant NUM_CE_ENTRIES     : integer := CE_ARRAY'length;
    variable biggest            : integer := 2;
    variable req_ce_addr_size   : integer := 0;
    variable num_addr_bits      : integer := 0;
    begin

        for i in 0 to NUM_CE_ENTRIES-1 loop
            req_ce_addr_size := ce_array(i) * 4;
            if (req_ce_addr_size > biggest) Then
                biggest := req_ce_addr_size;
            end if;
        end loop;
        num_addr_bits := clog2(biggest);
        return(num_addr_bits);
    end function NEEDED_ADDR_BITS;

-----------------------------------------------------------------------------
-- Function calc_high_address
--
-- This function is used to calculate the high address of the each address
-- range
-----------------------------------------------------------------------------
 function calc_high_address (high_address : short_addr_array_type;
                index      : integer) return std_logic_vector is

    variable calc_high_addr : std_logic_vector(0 to C_BUS_AWIDTH-1);

 begin
   If (index = (C_ARD_ADDR_RANGE_ARRAY'length/2-1)) Then
     calc_high_addr := C_S_AXI_MIN_SIZE(32-C_BUS_AWIDTH to 31);
   else
     calc_high_addr := high_address(index*2+2);
   end if;
   return(calc_high_addr);
 end function calc_high_address;

----------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
constant ARD_ADDR_RANGE_ARRAY   : short_addr_array_type :=
                                    slv64_2_slv_awidth(C_ARD_ADDR_RANGE_ARRAY,
                                                       C_BUS_AWIDTH);

constant NUM_BASE_ADDRS         : integer := (C_ARD_ADDR_RANGE_ARRAY'length)/2;

constant DECODE_BITS            : decode_bit_array_type :=
                                    Get_Addr_Bits(ARD_ADDR_RANGE_ARRAY);

constant NUM_CE_SIGNALS         : integer :=
                                    calc_num_ce(C_ARD_NUM_CE_ARRAY);

constant NUM_S_H_ADDR_BITS      : integer :=
                                    needed_addr_bits(C_ARD_NUM_CE_ARRAY);
-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal pselect_hit_i    : std_logic_vector
                            (0 to ((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1);
signal cs_out_i         : std_logic_vector
                            (0 to ((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1);
signal ce_expnd_i       : std_logic_vector(0 to NUM_CE_SIGNALS-1);
signal rdce_out_i       : std_logic_vector(0 to NUM_CE_SIGNALS-1);
signal wrce_out_i       : std_logic_vector(0 to NUM_CE_SIGNALS-1);

signal ce_out_i	        : std_logic_vector(0 to NUM_CE_SIGNALS-1); --

signal cs_ce_clr        : std_logic;
signal addr_out_s_h     : std_logic_vector(0 to NUM_S_H_ADDR_BITS-1);

signal Bus_RNW_reg      : std_logic;
-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------
begin -- architecture IMP


-- Register clears
cs_ce_clr       <= not Bus_rst or Clear_CS_CE_Reg;

addr_out_s_h    <= Address_In_Erly(C_BUS_AWIDTH-NUM_S_H_ADDR_BITS
                                   to C_BUS_AWIDTH-1);
-------------------------------------------------------------------------------
-- MEM_DECODE_GEN: Universal Address Decode Block
-------------------------------------------------------------------------------
MEM_DECODE_GEN: for bar_index in 0 to NUM_BASE_ADDRS-1 generate
---------------
constant CE_INDEX_START : integer
                        := calc_start_ce_index(C_ARD_NUM_CE_ARRAY,bar_index);
constant CE_ADDR_SIZE   : Integer range 0 to 15
                        := clog2(C_ARD_NUM_CE_ARRAY(bar_index));
constant OFFSET         : integer := 2;

constant BASE_ADDR_x    : std_logic_vector(0 to C_BUS_AWIDTH-1)
                        := ARD_ADDR_RANGE_ARRAY(bar_index*2+1);

constant HIGH_ADDR_X    : std_logic_vector(0 to C_BUS_AWIDTH-1)
                        := calc_high_address(ARD_ADDR_RANGE_ARRAY,bar_index);
--constant DECODE_BITS_0  : integer:= DECODE_BITS(0);
---------
begin
---------

    -- GEN_FOR_MULTI_CS: Below logic generates the CS for decoded address
    -- -----------------
    GEN_FOR_MULTI_CS : if C_ARD_ADDR_RANGE_ARRAY'length > 2 generate
            -- Instantiate the basic Base Address Decoders
            MEM_SELECT_I: entity work.pselect_f
                generic map
                (
                    C_AB     => DECODE_BITS(bar_index),
                    C_AW     => C_BUS_AWIDTH,
                    C_BAR    => ARD_ADDR_RANGE_ARRAY(bar_index*2),
                    C_FAMILY => C_FAMILY
                )
                port map
                (
                    A        => Address_In_Erly,            -- [in]
                    AValid   => Address_Valid_Erly,         -- [in]
                    CS       => pselect_hit_i(bar_index)    -- [out]
                );
    end generate GEN_FOR_MULTI_CS;

    -- GEN_FOR_ONE_CS: below logic decodes the CS for single address range
    -- ---------------
    GEN_FOR_ONE_CS : if C_ARD_ADDR_RANGE_ARRAY'length = 2 generate
            pselect_hit_i(bar_index) <= Address_Valid_Erly;
    end generate GEN_FOR_ONE_CS;


    -- Instantate backend registers for the Chip Selects
    BKEND_CS_REG : process(Bus_Clk)
            begin
                if(Bus_Clk'EVENT and Bus_Clk = '1')then
                  if(Bus_Rst='0' or Clear_CS_CE_Reg = '1')then
                    cs_out_i(bar_index) <= '0';
                  elsif(CS_CE_ld_enable='1')then
                    cs_out_i(bar_index) <= pselect_hit_i(bar_index);
                  end if;
                end if;
    end process BKEND_CS_REG;

    -------------------------------------------------------------------------
    -- PER_CE_GEN: Now expand the individual CEs for each base address.
    -------------------------------------------------------------------------
    PER_CE_GEN: for j in 0 to C_ARD_NUM_CE_ARRAY(bar_index) - 1 generate
    -----------
    begin
    -----------
        ----------------------------------------------------------------------
        -- CE decoders for multiple CE's
        ----------------------------------------------------------------------
        MULTIPLE_CES_THIS_CS_GEN : if CE_ADDR_SIZE > 0 generate
        constant BAR    : std_logic_vector(0 to CE_ADDR_SIZE-1) :=
                            std_logic_vector(to_unsigned(j,CE_ADDR_SIZE));
        begin
            CE_I : entity work.pselect_f
                generic map (
                    C_AB        => CE_ADDR_SIZE                             ,
                    C_AW        => CE_ADDR_SIZE                             ,
                    C_BAR       => BAR                                      ,
                    C_FAMILY    => C_FAMILY
                )
                port map (
                    A           => addr_out_s_h
                                    (NUM_S_H_ADDR_BITS-OFFSET-CE_ADDR_SIZE
                                    to NUM_S_H_ADDR_BITS - OFFSET - 1)      ,
                    AValid      => pselect_hit_i(bar_index)                 ,
                    CS          => ce_expnd_i(CE_INDEX_START+j)
                );
            end generate MULTIPLE_CES_THIS_CS_GEN;
	    --------------------------------------
        ----------------------------------------------------------------------
        -- SINGLE_CE_THIS_CS_GEN: CE decoders for single CE
        ----------------------------------------------------------------------
        SINGLE_CE_THIS_CS_GEN : if CE_ADDR_SIZE = 0 generate
            ce_expnd_i(CE_INDEX_START+j) <= pselect_hit_i(bar_index);
        end generate;
	-------------
    end generate PER_CE_GEN;
    ------------------------
end generate MEM_DECODE_GEN;

    -- RNW_REG_P: Register the incoming RNW signal at the time of registering the
    --            address. This is  need to generate the CE's separately.

    RNW_REG_P:process(Bus_Clk)
    begin
    if(Bus_Clk'EVENT and Bus_Clk = '1')then
       if(RW_CE_ld_enable='1')then
	Bus_RNW_reg <= Bus_RNW_Erly;
       end if;
    end if;
    end process RNW_REG_P;

    ---------------------------------------------------------------------------
    -- GEN_BKEND_CE_REGISTERS
    -- This ForGen implements the backend registering for
    -- the CE, RdCE, and WrCE output buses.
    ---------------------------------------------------------------------------
GEN_BKEND_CE_REGISTERS : for ce_index in 0 to NUM_CE_SIGNALS-1 generate
signal rdce_expnd_i : std_logic_vector(0 to NUM_CE_SIGNALS-1);
signal wrce_expnd_i : std_logic_vector(0 to NUM_CE_SIGNALS-1);
------
begin
------


    BKEND_RDCE_REG : process(Bus_Clk)
        begin
            if(Bus_Clk'EVENT and Bus_Clk = '1')then
              if(cs_ce_clr='1')then
                ce_out_i(ce_index) <= '0';
              elsif(RW_CE_ld_enable='1')then
                ce_out_i(ce_index) <= ce_expnd_i(ce_index);
              end if;
            end if;
    end process BKEND_RDCE_REG;
    rdce_out_i(ce_index)   <= ce_out_i(ce_index) and Bus_RNW_reg;
    wrce_out_i(ce_index)   <= ce_out_i(ce_index) and not Bus_RNW_reg;

-------------------------------
end generate GEN_BKEND_CE_REGISTERS;
-------------------------------------------------------------------------------

CS_for_gaps <= '0'; -- Removed the GAP adecoder logic
---------------------------------
CS_Out       <= cs_out_i   ;
RdCE_Out     <= rdce_out_i ;
WrCE_Out     <= wrce_out_i ;

end architecture IMP;
