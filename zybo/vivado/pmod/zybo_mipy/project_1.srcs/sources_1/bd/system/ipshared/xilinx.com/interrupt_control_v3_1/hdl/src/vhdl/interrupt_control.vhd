-------------------------------------------------------------------
-- (c) Copyright 1984 - 2012 Xilinx, Inc. All rights reserved.
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
-------------------------------------------------------------------
-- Filename:        interrupt_control.vhd
--
-- Description:     This VHDL design file is the parameterized interrupt control
--                  module for the ipif which permits parameterizing 1 or 2 levels
--                  of interrupt registers. This module has been optimized
--                  for the 64 bit wide PLB bus.
--
--
--
-------------------------------------------------------------------------------
-- Structure:   
--
--              interrupt_control.vhd
--                  
--
-------------------------------------------------------------------------------
-- BEGIN_CHANGELOG EDK_I_SP2
--
-- Initial Release
--
-- END_CHANGELOG
-------------------------------------------------------------------------------
-- @BEGIN_CHANGELOG EDK_K_SP3
--
-- Updated to use proc_common_v4_0_2 library
--
-- @END_CHANGELOG
-------------------------------------------------------------------------------
-- Author:      Doug Thorpe
--
-- History:
--  Doug Thorpe  Aug 16, 2001      -- V1.00a (initial release)
--  Mike Lovejoy  Oct 9, 2001      -- V1.01a
--               Added parameter C_INCLUDE_DEV_ISC to remove Device ISC.
--               When one source of interrupts Device ISC is redundant and
--               can be eliminated to reduce LUT count. When 7 interrupts
--               are included, the LUT count is reduced from 49 to 17.
--               Also removed the "wrapper" which required redefining
--               ports and generics herein.
--                                           
-- det      Feb-19-02   
--              - Added additional selections of input processing on the IP
--                interrupt inputs. This was done by replacing the 
--                C_IP_IRPT_NUM Generic with an unconstrained input array  
--                of integers selecting the type of input processing for each
--                bit.
--
-- det      Mar-22-02
--              - Corrected a reset problem with pos edge detect interrupt
--                input processing (a high on the input when recovering from
--                reset caused an eroneous interrupt to be latched in the IP_
--                ISR reg.
--
-- blt      Nov-18-02               -- V1.01b
--              - Updated library and use statements to use ipif_common_v1_00_b
--
--     DET     11/5/2003     v1_00_e
-- ~~~~~~
--     - Revamped register topology to take advantage of 64 bit wide data bus
--       interface. This required adding the Bus2IP_BE_sa input port to 
--       provide byte lane qualifiers for write operations.
-- ^^^^^^
--
--
--     DET     3/25/2004     ipif to v1_00_f
-- ~~~~~~
--     - Changed proc_common library reference to v2_00_a
--     - Removed ipif_common library reference
-- ^^^^^^
--     GAB     06/29/2005     v2_00_a
-- ~~~~~~
--     - Modified plb_interrupt_control of plb_ipif_v1_00_f to make 
--       a common version that supports 32,64, and 128-Bit Data Bus Widths.
--     - Changed to use ieee.numeric_std library and removed 
--       ieee.std_logic_arith.all
-- ^^^^^^
--     GAB     09/01/2006     v2_00_a
-- ~~~~~~
--     - Modified wrack and strobe for toggling set interrupt bits to reduce LUTs
--     - Removed strobe from interrupt enable registers where it was not needed
-- ^^^^^^
--     GAB     07/02/2008     v3_1
-- ~~~~~~
--     - Modified to used proc_common_v4_0_2 library
-- ^^^^^^
-- ~~~~~~
--  SK       12/16/12      -- v3.0
--  1. up reved to major version for 2013.1 Vivado release. No logic updates.
--  2. Updated the version of Interrupt Control to v3.0 in X.Y format
--  3. updated the proc common version to proc_common_v4_0_2
--  4. No Logic Updates
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
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
--
--
-------------------------------------------------------------------------------
-- Special information
--
--  The input Generic C_IP_INTR_MODE_ARRAY is an unconstrained array
--  of integers. The number of entries specifies how many IP interrupts
--  are to be processed. Each entry in the array specifies the type of input 
--  processing for each IP interrupt input. The following table
--  lists the defined values for entries in the array:
--
--          1   =   Level Pass through  (non-inverted input)
--          2   =   Level Pass through  (invert input)
--          3   =   Registered Level    (non-inverted input)
--          4   =   Registered Level    (inverted input)
--          5   =   Rising Edge Detect  (non-inverted input)
--          6   =   Falling Edge Detect (non-inverted input)
--
-------------------------------------------------------------------------------
-- Library definitions

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library axi_lite_ipif_v3_0_3;
use axi_lite_ipif_v3_0_3.ipif_pkg.all;

----------------------------------------------------------------------

entity interrupt_control is
    Generic(
        C_NUM_CE                : integer range 4 to 16 := 4;
            -- Number of register chip enables required
            -- For C_IPIF_DWIDTH=32  Set C_NUM_CE = 16
            -- For C_IPIF_DWIDTH=64  Set C_NUM_CE = 8
            -- For C_IPIF_DWIDTH=128 Set C_NUM_CE = 4
                       
        C_NUM_IPIF_IRPT_SRC     : integer range 1 to 29 := 4;
      
        C_IP_INTR_MODE_ARRAY    : INTEGER_ARRAY_TYPE :=
                                (
                                    1,  -- pass through (non-inverting)
                                    2   -- pass through (inverting)
                                );
            -- Interrupt Modes
            --1,  -- pass through (non-inverting)
            --2,  -- pass through (inverting)
            --3,  -- registered level (non-inverting)
            --4,  -- registered level (inverting)
            --5,  -- positive edge detect
            --6   -- negative edge detect
      
        C_INCLUDE_DEV_PENCODER  : boolean := false;
            -- Specifies device Priority Encoder function
      
        C_INCLUDE_DEV_ISC       : boolean := false; 
            -- Specifies device ISC hierarchy
            -- Exclusion of Device ISC requires 
            -- exclusion of Priority encoder
        
        C_IPIF_DWIDTH           : integer range 32 to 128 := 128
    ); 
    port(
  
        -- Inputs From the IPIF Bus 
        bus2ip_clk              : In  std_logic;
        bus2ip_reset            : In  std_logic;
        bus2ip_data             : In  std_logic_vector(0 to C_IPIF_DWIDTH-1);
        bus2ip_be               : In  std_logic_vector(0 to (C_IPIF_DWIDTH/8)-1);
        interrupt_rdce          : In  std_logic_vector(0 to C_NUM_CE-1);
        interrupt_wrce          : In  std_logic_vector(0 to C_NUM_CE-1);

        -- Interrupt inputs from the IPIF sources that will 
        -- get registered in this design
        ipif_reg_interrupts     : In  std_logic_vector(0 to 1);
        
        -- Level Interrupt inputs from the IPIF sources
        ipif_lvl_interrupts     : In  std_logic_vector
                                    (0 to C_NUM_IPIF_IRPT_SRC-1);

        -- Inputs from the IP Interface  
        ip2bus_intrevent        : In  std_logic_vector
                                    (0 to C_IP_INTR_MODE_ARRAY'length-1);
                          
        -- Final Device Interrupt Output
        intr2bus_devintr        : Out std_logic;

        -- Status Reply Outputs to the Bus 
        intr2bus_dbus           : Out std_logic_vector(0 to C_IPIF_DWIDTH-1);
        intr2bus_wrack          : Out std_logic;
        intr2bus_rdack          : Out std_logic;
        intr2bus_error          : Out std_logic;
        intr2bus_retry          : Out std_logic;
        intr2bus_toutsup        : Out std_logic
    );
    end interrupt_control;

-------------------------------------------------------------------------------

architecture implementation of interrupt_control is

-------------------------------------------------------------------------------
-- Function max2
--
-- This function returns the greater of two numbers.
-------------------------------------------------------------------------------
function max2 (num1, num2 : integer) return integer is
begin
    if num1 >= num2 then
        return num1;
    else
        return num2;
    end if;
end function max2;

-------------------------------------------------------------------------------
-- Function declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------
-- Function
--
-- Function Name: get_max_allowed_irpt_width
--
-- Function Description:
--   This function determines the maximum number of interrupts that
-- can be processed from the User IP based on the IPIF data bus width
-- and the number of interrupt entries desired.
--
-------------------------------------------------------------------
function get_max_allowed_irpt_width(data_bus_width      : integer;
                                   num_intrpts_entered  : integer)
                                   return integer is
    Variable temp_max : Integer;
    begin
        If (data_bus_width >= num_intrpts_entered) Then
            temp_max :=  num_intrpts_entered;
        else
            temp_max :=  data_bus_width;
        End if;
    return(temp_max);

end function get_max_allowed_irpt_width;
       
-------------------------------------------------------------------------------
-- Function data_port_map
-- This function will return an index within a 'reg_width' divided port
-- having a width of 'port_width' based on an address 'offset'.
-- For instance if the port_width is 128-bits and the register width
-- reg_width = 32 bits and the register address offset=16 (0x10), this
-- function will return a index of 0. 
-- 
-- Address Offset   Returned Index  Return Index    Returned Index
--                  (128 Bit Bus)   (64 Bit Bus)     (32 Bit Bus)
-- 0x00                 0               0                 0
-- 0x04                 1               1                 0
-- 0x08                 2               0                 0
-- 0x0C                 3               1                 0
-- 0x10                 0               0                 0
-- 0x14                 1               1                 0
-- 0x18                 2               0                 0
-- 0x1C                 3               1                 0
-------------------------------------------------------------------------------
function data_port_map(offset       : integer;
                       reg_width    : integer;
                       port_width   : integer)
                       return integer is
    variable upper_index    : integer;
    variable vector_range   : integer;
    variable reg_offset     : std_logic_vector(0 to 7);
    variable word_offset_i  : integer;
    begin
        
        -- Calculate index position to start decoding the address offset
        upper_index     := log2(port_width/8);
        
        -- Calculate the number of bits to look at in decoding 
        -- the address offset
        vector_range    := max2(1,log2(port_width/reg_width));
        
        -- Convert address offset into a std_logic_vector in order to
        -- strip out a set of bits for decoding
        reg_offset      := std_logic_vector(to_unsigned(offset,8));
        
        -- Calculate an index representing the word position of
        -- a register with respect to the port width.
        word_offset_i   :=  to_integer(unsigned(reg_offset(reg_offset'length 
                                - upper_index to (reg_offset'length 
                                - upper_index) + vector_range - 1)));
        return word_offset_i;
    end data_port_map;


-------------------------------------------------------------------------------
-- Type declarations
-------------------------------------------------------------------------------
      
   -- no Types  
     
-------------------------------------------------------------------------------
-- Constant declarations
-------------------------------------------------------------------------------
    
   -- general use constants 
    Constant LOGIC_LOW      : std_logic := '0';
    Constant LOGIC_HIGH     : std_logic := '1';
    
    
  -- figure out if 32 bits wide or 64 bits wide
    Constant LSB_BYTLE_LANE_COL_OFFSET : integer  := (C_IPIF_DWIDTH/32)-1;
    Constant CHIP_SEL_SCALE_FACTOR     : integer  := (C_IPIF_DWIDTH/32);
    
    constant BITS_PER_REG           : integer := 32;
    constant BYTES_PER_REG          : integer := BITS_PER_REG/8;

    -- Register Index
    Constant DEVICE_ISR_INDEX   : integer  := 0;
    Constant DEVICE_IPR_INDEX   : integer  := 1;
    Constant DEVICE_IER_INDEX   : integer  := 2;
    Constant DEVICE_IAR_INDEX   : integer  := 3;  --NOT USED RSVD
    Constant DEVICE_SIE_INDEX   : integer  := 4;  --NOT USED RSVD
    Constant DEVICE_CIE_INDEX   : integer  := 5;  --NOT USED RSVD
    Constant DEVICE_IIR_INDEX   : integer  := 6;
    Constant DEVICE_GIE_INDEX   : integer  := 7;
    Constant IP_ISR_INDEX       : integer  := 8;
    Constant IP_IPR_INDEX       : integer  := 9;  --NOT USED RSVD
    Constant IP_IER_INDEX       : integer  := 10;
    Constant IP_IAR_INDEX       : integer  := 11; --NOT USED RSVD
    Constant IP_SIE_INDEX       : integer  := 12; --NOT USED RSVD
    Constant IP_CIE_INDEX       : integer  := 13; --NOT USED RSVD
    Constant IP_IIR_INDEX       : integer  := 14; --NOT USED RSVD
    Constant IP_GIE_INDEX       : integer  := 15; --NOT USED RSVD
  
    -- Chip Enable Selection mapping (applies to RdCE and WrCE inputs)
    Constant DEVICE_ISR     : integer := DEVICE_ISR_INDEX/CHIP_SEL_SCALE_FACTOR; --   0 if 64-bit dwidth;
    Constant DEVICE_IPR     : integer := DEVICE_IPR_INDEX/CHIP_SEL_SCALE_FACTOR; --   0 if 64-bit dwidth;
    Constant DEVICE_IER     : integer := DEVICE_IER_INDEX/CHIP_SEL_SCALE_FACTOR; --   1 if 64-bit dwidth;
    Constant DEVICE_IAR     : integer := DEVICE_IAR_INDEX/CHIP_SEL_SCALE_FACTOR; --   1 if 64-bit dwidth;
    Constant DEVICE_SIE     : integer := DEVICE_SIE_INDEX/CHIP_SEL_SCALE_FACTOR; --   2 if 64-bit dwidth;
    Constant DEVICE_CIE     : integer := DEVICE_CIE_INDEX/CHIP_SEL_SCALE_FACTOR; --   2 if 64-bit dwidth;
    Constant DEVICE_IIR     : integer := DEVICE_IIR_INDEX/CHIP_SEL_SCALE_FACTOR; --   3 if 64-bit dwidth;
    Constant DEVICE_GIE     : integer := DEVICE_GIE_INDEX/CHIP_SEL_SCALE_FACTOR; --   3 if 64-bit dwidth;
    Constant IP_ISR         : integer := IP_ISR_INDEX/CHIP_SEL_SCALE_FACTOR;     --   4 if 64-bit dwidth;
    Constant IP_IPR         : integer := IP_IPR_INDEX/CHIP_SEL_SCALE_FACTOR;     --   4 if 64-bit dwidth;
    Constant IP_IER         : integer := IP_IER_INDEX/CHIP_SEL_SCALE_FACTOR;     --   5 if 64-bit dwidth;
    Constant IP_IAR         : integer := IP_IAR_INDEX/CHIP_SEL_SCALE_FACTOR;     --   5 if 64-bit dwidth;
    Constant IP_SIE         : integer := IP_SIE_INDEX/CHIP_SEL_SCALE_FACTOR;     --   6 if 64-bit dwidth;
    Constant IP_CIE         : integer := IP_CIE_INDEX/CHIP_SEL_SCALE_FACTOR;     --   6 if 64-bit dwidth;
    Constant IP_IIR         : integer := IP_IIR_INDEX/CHIP_SEL_SCALE_FACTOR;     --   7 if 64-bit dwidth;
    Constant IP_GIE         : integer := IP_GIE_INDEX/CHIP_SEL_SCALE_FACTOR;     --   7 if 64-bit dwidth;
  
  
    -- Register Address Offset
    Constant DEVICE_ISR_OFFSET   : integer  := DEVICE_ISR_INDEX * BYTES_PER_REG;
    Constant DEVICE_IPR_OFFSET   : integer  := DEVICE_IPR_INDEX * BYTES_PER_REG;
    Constant DEVICE_IER_OFFSET   : integer  := DEVICE_IER_INDEX * BYTES_PER_REG;
    Constant DEVICE_IAR_OFFSET   : integer  := DEVICE_IAR_INDEX * BYTES_PER_REG;
    Constant DEVICE_SIE_OFFSET   : integer  := DEVICE_SIE_INDEX * BYTES_PER_REG;
    Constant DEVICE_CIE_OFFSET   : integer  := DEVICE_CIE_INDEX * BYTES_PER_REG;
    Constant DEVICE_IIR_OFFSET   : integer  := DEVICE_IIR_INDEX * BYTES_PER_REG;
    Constant DEVICE_GIE_OFFSET   : integer  := DEVICE_GIE_INDEX * BYTES_PER_REG;
    Constant IP_ISR_OFFSET       : integer  := IP_ISR_INDEX     * BYTES_PER_REG;
    Constant IP_IPR_OFFSET       : integer  := IP_IPR_INDEX     * BYTES_PER_REG;
    Constant IP_IER_OFFSET       : integer  := IP_IER_INDEX     * BYTES_PER_REG;
    Constant IP_IAR_OFFSET       : integer  := IP_IAR_INDEX     * BYTES_PER_REG;
    Constant IP_SIE_OFFSET       : integer  := IP_SIE_INDEX     * BYTES_PER_REG;
    Constant IP_CIE_OFFSET       : integer  := IP_CIE_INDEX     * BYTES_PER_REG;
    Constant IP_IIR_OFFSET       : integer  := IP_IIR_INDEX     * BYTES_PER_REG;
    Constant IP_GIE_OFFSET       : integer  := IP_GIE_INDEX     * BYTES_PER_REG;

  
    -- Column Selection mapping (applies to RdCE and WrCE inputs)
    Constant DEVICE_ISR_COL      : integer  := data_port_map(DEVICE_ISR_OFFSET,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant DEVICE_IPR_COL      : integer  := data_port_map(DEVICE_IPR_OFFSET,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant DEVICE_IER_COL      : integer  := data_port_map(DEVICE_IER_OFFSET,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant DEVICE_IAR_COL      : integer  := data_port_map(DEVICE_IAR_OFFSET,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant DEVICE_SIE_COL      : integer  := data_port_map(DEVICE_SIE_OFFSET,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant DEVICE_CIE_COL      : integer  := data_port_map(DEVICE_CIE_OFFSET,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant DEVICE_IIR_COL      : integer  := data_port_map(DEVICE_IIR_OFFSET,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant DEVICE_GIE_COL      : integer  := data_port_map(DEVICE_GIE_OFFSET,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant IP_ISR_COL          : integer  := data_port_map(IP_ISR_OFFSET    ,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant IP_IPR_COL          : integer  := data_port_map(IP_IPR_OFFSET    ,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant IP_IER_COL          : integer  := data_port_map(IP_IER_OFFSET    ,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant IP_IAR_COL          : integer  := data_port_map(IP_IAR_OFFSET    ,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant IP_SIE_COL          : integer  := data_port_map(IP_SIE_OFFSET    ,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant IP_CIE_COL          : integer  := data_port_map(IP_CIE_OFFSET    ,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant IP_IIR_COL          : integer  := data_port_map(IP_IIR_OFFSET    ,BITS_PER_REG,C_IPIF_DWIDTH);
    Constant IP_GIE_COL          : integer  := data_port_map(IP_GIE_OFFSET    ,BITS_PER_REG,C_IPIF_DWIDTH);
                                                            
   -- Generic to constant mapping
    Constant DBUS_WIDTH_MINUS1          : Integer := C_IPIF_DWIDTH - 1;
    Constant NUM_USER_DESIRED_IRPTS    : Integer :=  C_IP_INTR_MODE_ARRAY'length;
    
    
    -- Constant IP_IRPT_HIGH_INDEX         : Integer := C_IP_INTR_MODE_ARRAY'length - 1;
    
    Constant IP_IRPT_HIGH_INDEX : Integer := 
                         get_max_allowed_irpt_width(C_IPIF_DWIDTH,
                                                    NUM_USER_DESIRED_IRPTS)
                                                    -1;
    
    
    
    Constant IPIF_IRPT_HIGH_INDEX       : Integer := C_NUM_IPIF_IRPT_SRC + 2;
                          -- (2 level + 1 IP + Number of latched inputs) - 1
    Constant IPIF_LVL_IRPT_HIGH_INDEX   : Integer := C_NUM_IPIF_IRPT_SRC - 1; 
    
   -- Priority encoder support constants
    Constant PRIORITY_ENC_WIDTH    : Integer := 8; -- bits
    Constant NO_INTR_VALUE         : Integer := 128;
                                    -- no interrupt pending code = "10000000"
   
-------------------------------------------------------------------------------
-- Signal declarations
-------------------------------------------------------------------------------
    Signal trans_reg_irpts              : std_logic_vector(1 downto 0);
    Signal trans_lvl_irpts              : std_logic_vector
                                            (IPIF_LVL_IRPT_HIGH_INDEX downto 0);

    Signal trans_ip_irpts               : std_logic_vector
                                            (IP_IRPT_HIGH_INDEX downto 0);

    Signal edgedtct_ip_irpts            : std_logic_vector
                                            (0 to IP_IRPT_HIGH_INDEX);

    signal irpt_read_data               : std_logic_vector
                                            (DBUS_WIDTH_MINUS1 downto 0);
    Signal irpt_rdack                   : std_logic;
    Signal irpt_wrack                   : std_logic;

    signal ip_irpt_status_reg           : std_logic_vector
                                            (IP_IRPT_HIGH_INDEX downto 0);

    signal ip_irpt_enable_reg           : std_logic_vector  
                                            (IP_IRPT_HIGH_INDEX downto 0);

    signal ip_irpt_pending_value        : std_logic_vector
                                            (IP_IRPT_HIGH_INDEX downto 0);

    Signal ip_interrupt_or              : std_logic;
    signal ipif_irpt_status_reg         : std_logic_vector(1 downto 0);

    signal ipif_irpt_status_value       : std_logic_vector
                                            (IPIF_IRPT_HIGH_INDEX downto 0);

    signal ipif_irpt_enable_reg         : std_logic_vector
                                            (IPIF_IRPT_HIGH_INDEX downto 0);

    signal ipif_irpt_pending_value      : std_logic_vector
                                            (IPIF_IRPT_HIGH_INDEX downto 0);

    Signal ipif_glbl_irpt_enable_reg    : std_logic;
    Signal ipif_interrupt               : std_logic;
    Signal ipif_interrupt_or            : std_logic;
    Signal ipif_pri_encode_present      : std_logic;
    Signal ipif_priority_encode_value   : std_logic_vector
                                            (PRIORITY_ENC_WIDTH-1 downto 0);

    Signal column_sel                   : std_logic_vector
                                            (0 to LSB_BYTLE_LANE_COL_OFFSET);

    signal interrupt_wrce_strb          : std_logic;
    signal irpt_wrack_d1                : std_logic;    
    signal irpt_rdack_d1                : std_logic;    
-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
  
begin
       
 
 -- Misc I/O and Signal assignments 
 
    Intr2Bus_DevIntr <= ipif_interrupt;
    Intr2Bus_Error   <= LOGIC_LOW;
    Intr2Bus_Retry   <= LOGIC_LOW;
    Intr2Bus_ToutSup <= LOGIC_LOW;

    REG_WRACK_PROCESS : process(Bus2IP_Clk)                                     
        begin
            if(Bus2IP_Clk'EVENT and Bus2IP_Clk = '1')then
                if(Bus2IP_Reset = '1')then
                    irpt_wrack_d1   <= '0';
                    Intr2Bus_WrAck  <= '0';
                else
                    irpt_wrack_d1   <= irpt_wrack;
                    Intr2Bus_WrAck  <= interrupt_wrce_strb;
                end if;
            end if;
        end process REG_WRACK_PROCESS;

    interrupt_wrce_strb <= irpt_wrack and not irpt_wrack_d1;

              
    REG_RDACK_PROCESS : process(Bus2IP_Clk)                                     
        begin
            if(Bus2IP_Clk'EVENT and Bus2IP_Clk = '1')then
                if(Bus2IP_Reset = '1')then
                    irpt_rdack_d1   <= '0';
                    Intr2Bus_RdAck  <= '0';
                else
                    irpt_rdack_d1   <= irpt_rdack;
                    Intr2Bus_RdAck  <= irpt_rdack and not irpt_rdack_d1;
                end if;
            end if;
        end process REG_RDACK_PROCESS;
                    
                    
    -------------------------------------------------------------
    -- Combinational Process
    --
    -- Label: ASSIGN_COL
    --
    -- Process Description:
    --
    --
    -------------------------------------------------------------
    ASSIGN_COL : process (Bus2IP_BE)
       begin
    
         -- Assign the 32-bit column selects from BE inputs
         for i in 0 to LSB_BYTLE_LANE_COL_OFFSET loop
           column_sel(i)    <= Bus2IP_BE(i*4);
         end loop;
        
       end process ASSIGN_COL; 
    
       
----------------------------------------------------------------------------------------------------------------
---  IP Interrupt processing start  
  

  ------------------------------------------------------------------------------------------
  -- Convert Little endian register to big endian data bus
  ------------------------------------------------------------------------------------------
  LITTLE_TO_BIG : process (irpt_read_data)
   Begin
     
      for k in 0 to DBUS_WIDTH_MINUS1 loop
        Intr2Bus_DBus(DBUS_WIDTH_MINUS1-k) <= irpt_read_data(k); -- Convert to Big-Endian Data Bus
      End loop; 
       
   End process; -- LITTLE_TO_BIG



 ------------------------------------------------------------------------------------------
 -- Convert big endian interrupt inputs to Little endian registers
 ------------------------------------------------------------------------------------------
 BIG_TO_LITTLE : process (IPIF_Reg_Interrupts, IPIF_Lvl_Interrupts, edgedtct_ip_irpts)
   Begin                  
    
      for i in 0 to 1 loop
        trans_reg_irpts(i) <= IPIF_Reg_Interrupts(i); -- Convert to Little-Endian format
      End loop; 
       
      for j in 0 to IPIF_LVL_IRPT_HIGH_INDEX loop
        trans_lvl_irpts(j) <= IPIF_Lvl_Interrupts(j); -- Convert to Little-Endian format
      End loop; 
       
      for k in 0 to IP_IRPT_HIGH_INDEX loop
        trans_ip_irpts(k) <= edgedtct_ip_irpts(k);     -- Convert to Little-Endian format
      End loop;                                                                           
  
   End process; -- BIG_TO_LITTLE

  
        
        
  ------------------------------------------------------------------------------------------
  -- Implement the IP Interrupt Input Processing 
  ------------------------------------------------------------------------------------------
  DO_IRPT_INPUT: for irpt_index in 0 to IP_IRPT_HIGH_INDEX generate
    
     
     
     GEN_NON_INVERT_PASS_THROUGH : if (C_IP_INTR_MODE_ARRAY(irpt_index) = 1 or
                                       C_IP_INTR_MODE_ARRAY(irpt_index) = 3) generate
  
        edgedtct_ip_irpts(irpt_index) <= IP2Bus_IntrEvent(irpt_index);
  
     end generate GEN_NON_INVERT_PASS_THROUGH;  
  
      
     
     GEN_INVERT_PASS_THROUGH : if (C_IP_INTR_MODE_ARRAY(irpt_index) = 2 or
                                   C_IP_INTR_MODE_ARRAY(irpt_index) = 4) generate
     
        edgedtct_ip_irpts(irpt_index) <= not(IP2Bus_IntrEvent(irpt_index));
     
     end generate GEN_INVERT_PASS_THROUGH;  
      
     
     
     
     GEN_POS_EDGE_DETECT : if (C_IP_INTR_MODE_ARRAY(irpt_index) = 5) generate
          
          Signal irpt_dly1 : std_logic;
          Signal irpt_dly2 : std_logic;
          
        
     begin   
        
        REG_THE_IRPTS : process (Bus2IP_Clk)
          begin   
             
             If (Bus2IP_Clk'EVENT and Bus2IP_Clk = '1') Then
     
                If (Bus2IP_Reset = '1') Then 

                   irpt_dly1     <= '1'; -- setting to '1' protects reset transition
                   irpt_dly2     <= '1'; -- where interrupt inputs are preset high
                   
                Else

                   irpt_dly1     <= IP2Bus_IntrEvent(irpt_index);
                   irpt_dly2     <= irpt_dly1;
                    
                End if;
               
             else
                 null;
             End if;
     
          End process; -- REG_THE_IRPTS
        
        -- now detect rising edge 
        edgedtct_ip_irpts(irpt_index) <= irpt_dly1 and not(irpt_dly2);
                  
     end generate GEN_POS_EDGE_DETECT;  
       
                                    
                                    
                                    
                                    
     GEN_NEG_EDGE_DETECT : if (C_IP_INTR_MODE_ARRAY(irpt_index) = 6) generate
          
          Signal irpt_dly1 : std_logic;
          Signal irpt_dly2 : std_logic;
        
     begin   
        
        REG_THE_IRPTS : process (Bus2IP_Clk)
          begin   
             
             If (Bus2IP_Clk'EVENT and Bus2IP_Clk = '1') Then
     
                If (Bus2IP_Reset = '1') Then  
              
                   irpt_dly1     <= '0';
                   irpt_dly2     <= '0';
                   
                Else 
     
                   irpt_dly1     <= IP2Bus_IntrEvent(irpt_index);
                   irpt_dly2     <= irpt_dly1;
                    
                End if;
               
             else
                 null;
             End if;
     
          End process; -- REG_THE_IRPTS
        
        edgedtct_ip_irpts(irpt_index) <= not(irpt_dly1) and irpt_dly2;
     
     end generate GEN_NEG_EDGE_DETECT;  
  
       
     
     GEN_INVALID_TYPE : if (C_IP_INTR_MODE_ARRAY(irpt_index) > 6 ) generate
     
        edgedtct_ip_irpts(irpt_index) <= '0'; -- Don't use input
        
     end generate GEN_INVALID_TYPE;  
  
     
  End generate DO_IRPT_INPUT; 
 
 
  
  
 -- Generate the IP Interrupt Status register                  
 GEN_IP_IRPT_STATUS_REG : for irpt_index in 0 to IP_IRPT_HIGH_INDEX generate
   
 
      GEN_REG_STATUS : if (C_IP_INTR_MODE_ARRAY(irpt_index) > 2) generate
      
         DO_STATUS_BIT : process (Bus2IP_Clk)
          Begin
      
            if (Bus2IP_Clk'event and Bus2IP_Clk = '1') Then
            
               If (Bus2IP_Reset = '1') Then
          
                  ip_irpt_status_reg(irpt_index) <= '0'; 
          
               elsif (Interrupt_WrCE(IP_ISR) = '1' and
                      column_sel(IP_ISR_COL) = '1' and
                      interrupt_wrce_strb = '1') Then -- toggle selected ISR bits from the DBus inputs
          
-- (GAB)                
                    ip_irpt_status_reg(irpt_index) <= 
                     (Bus2IP_Data((BITS_PER_REG * IP_ISR_COL) 
                                    +(BITS_PER_REG - 1)
                                    - irpt_index) xor         -- toggle bits on write of '1'
                     ip_irpt_status_reg(irpt_index)) or       -- but don't miss interrupts coming
                     trans_ip_irpts(irpt_index);              -- in on non-cleared interrupt bits





               else
                  ip_irpt_status_reg(irpt_index) <= 
                           ip_irpt_status_reg(irpt_index) or 
                           trans_ip_irpts(irpt_index); -- latch and hold input interrupt bits
                    
               End if;
               
            Else
               null;
            End if;
        
         End process; -- DO_STATUS_BIT
      
      End generate GEN_REG_STATUS;
 
 
 
 
      GEN_PASS_THROUGH_STATUS : if (C_IP_INTR_MODE_ARRAY(irpt_index) = 1 or
                                    C_IP_INTR_MODE_ARRAY(irpt_index) = 2) generate
 
         ip_irpt_status_reg(irpt_index) <= trans_ip_irpts(irpt_index);
 
      End generate GEN_PASS_THROUGH_STATUS;
 
 
 End generate GEN_IP_IRPT_STATUS_REG;
                   
                   
                   
    
  ------------------------------------------------------------------------------------------
  -- Implement the IP Interrupt Enable Register Write and Clear Functions
  ------------------------------------------------------------------------------------------
  DO_IP_IRPT_ENABLE_REG : process (Bus2IP_Clk)
    Begin
    

       if (Bus2IP_Clk'event and Bus2IP_Clk = '1') Then

         If (Bus2IP_Reset = '1') Then

            ip_irpt_enable_reg <= (others => '0'); 
           
         elsif (Interrupt_WrCE(IP_IER) = '1' and
                column_sel(IP_IER_COL) = '1') then 
--                      interrupt_wrce_strb = '1') Then
                  
-- (GAB)                
            ip_irpt_enable_reg  <= Bus2IP_Data
                                    ( (BITS_PER_REG * IP_IER_COL) 
                                     +(BITS_PER_REG - 1)
                                     - IP_IRPT_HIGH_INDEX to

                                      (BITS_PER_REG * IP_IER_COL) 
                                     +(BITS_PER_REG - 1)
                                    );
         else
            null; -- no change
         End if;
          
       Else
          null;
       End if;
      
    End process; -- DO_IP_IRPT_ENABLE_REG
    
  

  ------------------------------------------------------------------------------------------
  -- Implement the IP Interrupt Enable/Masking function
  ------------------------------------------------------------------------------------------
  DO_IP_INTR_ENABLE : process (ip_irpt_status_reg, ip_irpt_enable_reg)
    Begin

      for i in 0 to IP_IRPT_HIGH_INDEX loop
        ip_irpt_pending_value(i) <= ip_irpt_status_reg(i) and 
                                    ip_irpt_enable_reg(i); -- enable/mask interrupt bits
      End loop;
            
    End process; -- DO_IP_INTR_ENABLE
    
    
  ------------------------------------------------------------------------------------------
  -- Implement the IP Interrupt 'OR' Functions
  ------------------------------------------------------------------------------------------
  DO_IP_INTR_OR : process (ip_irpt_pending_value)
  
    Variable ip_loop_or : std_logic;
  
    Begin

      ip_loop_or := '0';
        
      for i in 0 to IP_IRPT_HIGH_INDEX loop
          ip_loop_or := ip_loop_or or ip_irpt_pending_value(i);
      End loop;
     
      ip_interrupt_or <= ip_loop_or;
     
            
    End process; -- DO_IP_INTR_OR
  

--------------------------------------------------------------------------------------------
---  IP Interrupt processing end  
--------------------------------------------------------------------------------------------
 
 
--==========================================================================================



Include_Device_ISC_generate: if(C_INCLUDE_DEV_ISC) generate
begin
--------------------------------------------------------------------------------------------
---  IPIF Interrupt processing Start  
--------------------------------------------------------------------------------------------
 
 
  ------------------------------------------------------------------------------------------
  -- Implement the IPIF Interrupt Status Register Write and Clear Functions
  -- This is only 2 bits wide (the only inputs latched at this level...the others just flow
  -- through)
  ------------------------------------------------------------------------------------------
  DO_IPIF_IRPT_STATUS_REG : process (Bus2IP_Clk)
    Begin
    

       if (Bus2IP_Clk'event and Bus2IP_Clk = '1') Then

         If (Bus2IP_Reset = '1') Then

            ipif_irpt_status_reg <= (others => '0'); 
           
         elsif (Interrupt_WrCE(DEVICE_ISR) = '1' and
                column_sel(DEVICE_ISR_COL) = '1' and
                      interrupt_wrce_strb = '1') Then

            for i in 0 to 1 loop                                                            
-- (GAB)                
                ipif_irpt_status_reg(i) <= (Bus2IP_Data
                                            ( (BITS_PER_REG * DEVICE_ISR_COL) 
                                             +(BITS_PER_REG - 1)
                                             - i) xor                       -- toggle bits on write of '1'
                                            ipif_irpt_status_reg(i)) or     -- but don't miss interrupts coming
                                            trans_reg_irpts(i);             -- in on non-cleared interrupt bits
            End loop;                                                                       
                                                                                          
         else

            for i in 0 to 1 loop
              ipif_irpt_status_reg(i) <= ipif_irpt_status_reg(i) or trans_reg_irpts(i);
                                                              -- latch and hold asserted interrupts        
            End loop;                                                                         
                                                                                              
         End if;
          
       Else
          null;
       End if;
      
    End process; -- DO_IPIF_IRPT_STATUS_REG
    

  
  DO_IPIF_IRPT_STATUS_VALUE : process (ipif_irpt_status_reg, trans_lvl_irpts, ip_interrupt_or)
    Begin

       ipif_irpt_status_value(1 downto 0) <=  ipif_irpt_status_reg;
       ipif_irpt_status_value(2)          <=  ip_interrupt_or;
       
       for i in 3 to IPIF_IRPT_HIGH_INDEX loop
         ipif_irpt_status_value(i) <= trans_lvl_irpts(i-3); 
       End loop;                                                
                                                                
    
    End process; -- DO_IPIF_IRPT_STATUS_VALUE
  
  

    
    
  ------------------------------------------------------------------------------------------
  -- Implement the IPIF Interrupt Enable Register Write and Clear Functions
  ------------------------------------------------------------------------------------------
  DO_IPIF_IRPT_ENABLE_REG : process (Bus2IP_Clk)
    Begin
    
       if (Bus2IP_Clk'event and Bus2IP_Clk = '1') Then

          If (Bus2IP_Reset = '1') Then

             ipif_irpt_enable_reg <= (others => '0'); 

          elsif (Interrupt_WrCE(DEVICE_IER) = '1' and
                 column_sel(DEVICE_IER_COL) = '1') then
--                      interrupt_wrce_strb = '1') Then
          
-- (GAB)                
             ipif_irpt_enable_reg <= Bus2IP_Data
                                        (
                                            (BITS_PER_REG * DEVICE_IER_COL) 
                                           +(BITS_PER_REG - 1)
                                           - IPIF_IRPT_HIGH_INDEX to
                                        
                                            (BITS_PER_REG * DEVICE_IER_COL) 
                                           +(BITS_PER_REG - 1)
                                        );
         else
            null; -- no change
         End if;
          
       Else
          null;
       End if;
      
    End process; -- DO_IPIF_IRPT_ENABLE_REG
    
    

  ------------------------------------------------------------------------------------------
  -- Implement the IPIF Interrupt Enable/Masking function
  ------------------------------------------------------------------------------------------
  DO_IPIF_INTR_ENABLE : process (ipif_irpt_status_value, ipif_irpt_enable_reg)
    Begin

      for i in 0 to IPIF_IRPT_HIGH_INDEX loop
        ipif_irpt_pending_value(i) <= ipif_irpt_status_value(i) and ipif_irpt_enable_reg(i); -- enable/mask interrupt bits
      End loop;
            
    End process; -- DO_IPIF_INTR_ENABLE
    
    
    
end generate Include_Device_ISC_generate;
 
Initialize_when_not_include_Device_ISC_generate: if(not(C_INCLUDE_DEV_ISC)) generate
begin
   ipif_irpt_status_reg <= (others => '0'); 
   ipif_irpt_status_value <= (others => '0'); 
   ipif_irpt_enable_reg <= (others => '0'); 
   ipif_irpt_pending_value <= (others => '0');
end generate Initialize_when_not_include_Device_ISC_generate;
  

 ------------------------------------------------------------------------------------------
 -- Implement the IPIF Interrupt Master Enable Register Write and Clear Functions
 ------------------------------------------------------------------------------------------
 DO_IPIF_IRPT_MASTER_ENABLE : process (Bus2IP_Clk)
   Begin
   
      if (Bus2IP_Clk'event and Bus2IP_Clk = '1') Then

        If (Bus2IP_Reset = '1') Then
   
           ipif_glbl_irpt_enable_reg <= '0'; 
   
        elsif (Interrupt_WrCE(DEVICE_GIE) = '1' and
               column_sel(DEVICE_GIE_COL) = '1' )then
               --interrupt_wrce_strb = '1') Then -- load input data from the DBus inputs
 
-- (GAB)
           ipif_glbl_irpt_enable_reg <= Bus2IP_Data(BITS_PER_REG * DEVICE_GIE_COL);
           
        else
           null; -- no change
        End if;
         
      Else
         null;
      End if;
     
   End process; -- DO_IPIF_IRPT_MASTER_ENABLE
   
   

 
   
  INCLUDE_DEV_PRIORITY_ENCODER : if (C_INCLUDE_DEV_PENCODER = True) generate
    ------------------------------------------------------------------------------------------
    -- Implement the IPIF Interrupt Priority Encoder Function on the Interrupt Pending Value
    -- Loop from Interrupt LSB to MSB, retaining the position of the last interrupt detected. 
    -- This method implies a positional priority of MSB to LSB.
    ------------------------------------------------------------------------------------------
    
    
     ipif_pri_encode_present <= '1';
    
    
    
  DO_PRIORITY_ENCODER : process (ipif_irpt_pending_value)
  
    Variable irpt_position : Integer;
    Variable irpt_detected : Boolean;
    Variable loop_count    : integer;
    
    Begin
      
        loop_count    := IPIF_IRPT_HIGH_INDEX + 1;
        irpt_position := 0;
        irpt_detected := FALSE;
      
       -- Search through the pending interrupt values starting with the MSB 
        while (loop_count > 0) loop
           
           If (ipif_irpt_pending_value(loop_count-1) = '1') Then
              irpt_detected := TRUE;
              irpt_position := loop_count-1;
           else
              null; -- do nothing
           End if;
          
           loop_count := loop_count - 1;
  
        End loop;
        
       -- now assign the encoder output value to the bit position of the last interrupt encountered 
        If (irpt_detected) Then
           ipif_priority_encode_value <= std_logic_vector(to_unsigned(irpt_position, PRIORITY_ENC_WIDTH));
           ipif_interrupt_or          <= '1';  -- piggy-back off of this function for the "OR" function
        else
           ipif_priority_encode_value <= std_logic_vector(to_unsigned(NO_INTR_VALUE, PRIORITY_ENC_WIDTH)); 
           ipif_interrupt_or          <= '0';
        End if;
      
         
      
    End process; -- DO_PRIORITY_ENCODER
   

end generate INCLUDE_DEV_PRIORITY_ENCODER; 



 
 
   
DELETE_DEV_PRIORITY_ENCODER : if (C_INCLUDE_DEV_PENCODER = False) generate
      
    
    
    ipif_pri_encode_present <= '0';
    
    
        
    ipif_priority_encode_value <= (others => '0'); 
        
        
    ------------------------------------------------------------------------------------------
    -- Implement the IPIF Interrupt 'OR' Functions (used if priority encoder removed)
    ------------------------------------------------------------------------------------------
    DO_IPIF_INTR_OR : process (ipif_irpt_pending_value)
    
      Variable ipif_loop_or : std_logic;
      
      Begin
    
        ipif_loop_or := '0';  
    
        for i in 0 to IPIF_IRPT_HIGH_INDEX loop
            ipif_loop_or := ipif_loop_or or ipif_irpt_pending_value(i);
        End loop;
              
        ipif_interrupt_or <= ipif_loop_or;         
                  
      End process; -- DO_IPIF_INTR_OR
        

end generate DELETE_DEV_PRIORITY_ENCODER;  
                                        
   
 -------------------------------------------------------------------------------------------
 -- Perform the final Master enable function on the 'ORed' interrupts
OR_operation_with_Dev_ISC_generate: if(C_INCLUDE_DEV_ISC) generate
   begin
      ipif_interrupt_PROCESS: process(ipif_interrupt_or, ipif_glbl_irpt_enable_reg)
         begin
            ipif_interrupt  <=  ipif_interrupt_or and ipif_glbl_irpt_enable_reg;
      end process ipif_interrupt_PROCESS;
end generate OR_operation_with_Dev_ISC_generate;



OR_operation_withOUT_Dev_ISC_generate: if(not(C_INCLUDE_DEV_ISC)) generate
   begin
      ipif_interrupt_PROCESS: process(ip_interrupt_or, ipif_glbl_irpt_enable_reg)
         begin
            ipif_interrupt  <=  ip_interrupt_or and ipif_glbl_irpt_enable_reg;
      end process ipif_interrupt_PROCESS;
end generate OR_operation_withOUT_Dev_ISC_generate;
 
-----------------------------------------------------------------------------------------------------------
---  IPIF Interrupt processing end  
----------------------------------------------------------------------------------------------------------------
Include_Dev_ISC_WrAck_OR_generate: if(C_INCLUDE_DEV_ISC) generate
begin
  GEN_WRITE_ACKNOWLEGDGE : process (Interrupt_WrCE,
                                    column_sel
                                   )
    Begin
      
       irpt_wrack <= (
                      Interrupt_WrCE(DEVICE_ISR) and 
                      column_sel(DEVICE_ISR_COL)
                     )
                 or
                     (
                      Interrupt_WrCE(DEVICE_IER) and 
                      column_sel(DEVICE_IER_COL)
                     )
                 or
                     (
                      Interrupt_WrCE(DEVICE_GIE) and
                      column_sel(DEVICE_GIE_COL)
                     )
                 or
                     (
                      Interrupt_WrCE(IP_ISR) and
                      column_sel(IP_ISR_COL)
                     )    
                 or
                     (
                      Interrupt_WrCE(IP_IER) and
                      column_sel(IP_IER_COL)
                     );
      
      
    End process; -- GEN_WRITE_ACKNOWLEGDGE
end generate Include_Dev_ISC_WrAck_OR_generate;



Exclude_Dev_ISC_WrAck_OR_generate: if(not(C_INCLUDE_DEV_ISC)) generate
begin
  GEN_WRITE_ACKNOWLEGDGE : process (Interrupt_WrCE,
                                    column_sel
                                   )
    Begin
      
       irpt_wrack <= 
                     (
                      Interrupt_WrCE(DEVICE_GIE) and
                      column_sel(DEVICE_GIE_COL)
                     )
                 or
                     (
                      Interrupt_WrCE(IP_ISR) and
                      column_sel(IP_ISR_COL)
                     )    
                 or
                     (
                      Interrupt_WrCE(IP_IER) and
                      column_sel(IP_IER_COL)
                     );
      
      
    End process; -- GEN_WRITE_ACKNOWLEGDGE
end generate Exclude_Dev_ISC_WrAck_OR_generate;
  
 
   -----------------------------------------------------------------------------------------------------------
   ---  IPIF Bus Data Read Mux and Read Acknowledge generation 
   ----------------------------------------------------------------------------------------------------------------
Include_Dev_ISC_RdAck_OR_generate: if(C_INCLUDE_DEV_ISC) generate
begin
    GET_READ_DATA : process (Interrupt_RdCE, column_sel,
                             ip_irpt_status_reg,
                             ip_irpt_enable_reg,
                             ipif_irpt_pending_value,
                             ipif_irpt_enable_reg,
                             ipif_pri_encode_present,
                             ipif_priority_encode_value, 
                             ipif_irpt_status_value,
                             ipif_glbl_irpt_enable_reg)
      Begin

         irpt_read_data <= (others => '0'); -- default to driving zeroes   
          
          
       
         If (Interrupt_RdCE(IP_ISR) = '1'
         and column_sel(IP_ISR_COL) = '1') Then
   
            for i in 0 to IP_IRPT_HIGH_INDEX loop
--              irpt_read_data(i+32) <= ip_irpt_status_reg(i); -- output IP interrupt status register values
 
                irpt_read_data
                    (i+(C_IPIF_DWIDTH
                     - (BITS_PER_REG*IP_ISR_COL)
                     - BITS_PER_REG)) <= ip_irpt_status_reg(i); -- output IP interrupt status register values
 
            End loop;
           
            irpt_rdack <= '1';   -- set the acknowledge handshake
            
         Elsif (Interrupt_RdCE(IP_IER) = '1'
         and column_sel(IP_IER_COL) = '1') Then
   
            for i in 0 to IP_IRPT_HIGH_INDEX loop
--              irpt_read_data(i+32) <= ip_irpt_enable_reg(i); -- output IP interrupt enable register values
                irpt_read_data
                    (i+(C_IPIF_DWIDTH
                     - (BITS_PER_REG*IP_IER_COL)
                     - BITS_PER_REG)) <= ip_irpt_enable_reg(i); -- output IP interrupt enable register values

            End loop;
           
            irpt_rdack <= '1';   -- set the acknowledge handshake
         
            
         Elsif (Interrupt_RdCE(DEVICE_ISR) = '1'
         and column_sel(DEVICE_ISR_COL) = '1')then  
            for i in 0 to IPIF_IRPT_HIGH_INDEX loop
--              irpt_read_data(i+32) <= ipif_irpt_status_value(i); -- output IPIF status interrupt values
                irpt_read_data
                    (i+(C_IPIF_DWIDTH
                     - (BITS_PER_REG*DEVICE_ISR_COL)
                     - BITS_PER_REG)) <= ipif_irpt_status_value(i); -- output IPIF status interrupt values
            End loop;
            irpt_rdack <= '1';   -- set the acknowledge handshake
           
         Elsif (Interrupt_RdCE(DEVICE_IPR) = '1'
         and column_sel(DEVICE_IPR_COL) = '1')then  
          
             for i in 0 to IPIF_IRPT_HIGH_INDEX loop
--               irpt_read_data(i+32) <= ipif_irpt_pending_value(i+32); -- output IPIF pending interrupt values

                irpt_read_data
                    (i+(C_IPIF_DWIDTH
                     - (BITS_PER_REG*DEVICE_IPR_COL)
                     - BITS_PER_REG)) <= ipif_irpt_pending_value(i); -- output IPIF pending interrupt values

             End loop;
            
             irpt_rdack <= '1';   -- set the acknowledge handshake
            
         Elsif (Interrupt_RdCE(DEVICE_IER) = '1'
         and column_sel(DEVICE_IER_COL) = '1') Then
   
            for i in 0 to IPIF_IRPT_HIGH_INDEX loop
--              irpt_read_data(i+32) <= ipif_irpt_enable_reg(i); -- output IPIF pending interrupt values
                irpt_read_data
                    (i+(C_IPIF_DWIDTH
                     - (BITS_PER_REG*DEVICE_IER_COL)
                     - BITS_PER_REG)) <= ipif_irpt_enable_reg(i); -- output IPIF pending interrupt values
            End loop;
           
            irpt_rdack <= '1';   -- set the acknowledge handshake
            
         Elsif (Interrupt_RdCE(DEVICE_IIR) = '1'
         and column_sel(DEVICE_IIR_COL) = '1') Then
         
--            irpt_read_data(32+PRIORITY_ENC_WIDTH-1 downto 32) <= ipif_priority_encode_value; -- output IPIF pending interrupt values
            
           irpt_read_data( (C_IPIF_DWIDTH
                         - (BITS_PER_REG*DEVICE_IIR_COL)
                         - BITS_PER_REG) + PRIORITY_ENC_WIDTH-1 
                    downto (C_IPIF_DWIDTH
                         - (BITS_PER_REG*DEVICE_IIR_COL)
                         - BITS_PER_REG))  <= ipif_priority_encode_value;
           
            irpt_rdack <= '1';   -- set the acknowledge handshake 
            
          Elsif (Interrupt_RdCE(DEVICE_GIE) = '1'
          and column_sel(DEVICE_GIE_COL) = '1') Then
              
--             irpt_read_data(DBUS_WIDTH_MINUS1) <= ipif_glbl_irpt_enable_reg; -- output Global Enable Register value  
             irpt_read_data(C_IPIF_DWIDTH 
             - (BITS_PER_REG * DEVICE_GIE_COL) - 1) <= ipif_glbl_irpt_enable_reg;
            
             irpt_rdack <= '1';   -- set the acknowledge handshake                                    
          
         else
   
            irpt_rdack      <= '0';             -- don't set the acknowledge handshake
            
         End if;
      
      
      End process; -- GET_READ_DATA
end generate Include_Dev_ISC_RdAck_OR_generate;


Exclude_Dev_ISC_RdAck_OR_generate: if(not(C_INCLUDE_DEV_ISC)) generate
begin
    GET_READ_DATA : process (Interrupt_RdCE, ip_irpt_status_reg, ip_irpt_enable_reg,
                             ipif_glbl_irpt_enable_reg,column_sel)
      Begin

         irpt_read_data <= (others => '0'); -- default to driving zeroes   
          
          
       
         If (Interrupt_RdCE(IP_ISR) = '1'
         and column_sel(IP_ISR_COL) = '1') Then
   
            for i in 0 to IP_IRPT_HIGH_INDEX loop
--              irpt_read_data(i+32) <= ip_irpt_status_reg(i); -- output IP interrupt status register values
                irpt_read_data
                    (i+(C_IPIF_DWIDTH
                     - (BITS_PER_REG*IP_ISR_COL)
                     - BITS_PER_REG)) <= ip_irpt_status_reg(i); -- output IP interrupt status register values


            End loop;
           
            irpt_rdack <= '1';   -- set the acknowledge handshake
            
         Elsif (Interrupt_RdCE(IP_IER) = '1'
         and column_sel(IP_IER_COL) = '1') Then
   
            for i in 0 to IP_IRPT_HIGH_INDEX loop
--              irpt_read_data(i+32) <= ip_irpt_enable_reg(i); -- output IP interrupt enable register values
                irpt_read_data
                    (i+(C_IPIF_DWIDTH
                     - (BITS_PER_REG*IP_IER_COL)
                     - BITS_PER_REG)) <= ip_irpt_enable_reg(i); -- output IP interrupt enable register values

            End loop;
           
            irpt_rdack <= '1';   -- set the acknowledge handshake
         
         Elsif (Interrupt_RdCE(DEVICE_GIE) = '1'
         and column_sel(DEVICE_GIE_COL) = '1') Then
             
--            irpt_read_data(31) <= ipif_glbl_irpt_enable_reg; -- output Global Enable Register value  
             irpt_read_data(C_IPIF_DWIDTH 
             - (BITS_PER_REG * DEVICE_GIE_COL) - 1) <= ipif_glbl_irpt_enable_reg;
                                                                                                         
            irpt_rdack <= '1';   -- set the acknowledge handshake                                    
          
         else
   
            irpt_rdack <= '0';             -- don't set the acknowledge handshake
            
         End if;
      
      
      End process; -- GET_READ_DATA

end generate Exclude_Dev_ISC_RdAck_OR_generate;



end implementation;


 






