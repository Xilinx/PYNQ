-------------------------------------------------------------------------------
-- checkbit_handler_64.vhd
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
-- Filename:        checkbit_handler_64.vhd
--
-- Description:     Generates the ECC checkbits for the input vector of 
--                  64-bit data widths.
--                  
-- VHDL-Standard:   VHDL'93/02
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
--                      |
--                      |-- axi_lite.vhd
--                      |   -- lite_ecc_reg.vhd
--                      |       -- axi_lite_if.vhd
--                      |   -- checkbit_handler.vhd
--                      |       -- xor18.vhd
--                      |       -- parity.vhd
--                      |   -- checkbit_handler_64.vhd
--                      |       -- (same helper components as checkbit_handler)
--                      |   -- correct_one_bit.vhd
--                      |   -- correct_one_bit_64.vhd
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
--
--
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

library IEEE;
use IEEE.std_logic_1164.all;

entity checkbit_handler_64 is
  generic (
    C_ENCODE   : boolean := true;
    C_REG      : boolean := false;
    C_USE_LUT6 : boolean := true);
  port (

    Clk             : in    std_logic;

    DataIn          : in  std_logic_vector (63 downto 0);
    CheckIn         : in  std_logic_vector (7 downto 0);
    CheckOut        : out std_logic_vector (7 downto 0);
    Syndrome        : out std_logic_vector (7 downto 0);
    Syndrome_7      : out std_logic_vector (11 downto 0);
    Syndrome_Chk    : in  std_logic_vector (0 to 7);    

    Enable_ECC : in  std_logic;
    UE_Q       : in  std_logic;
    CE_Q       : in  std_logic;
    UE         : out std_logic;
    CE         : out std_logic
    );
    
end entity checkbit_handler_64;

library unisim;
use unisim.vcomponents.all;

-- library axi_bram_ctrl_v1_02_a;
-- use axi_bram_ctrl_v1_02_a.all;

architecture IMP of checkbit_handler_64 is

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of IMP : architecture is "yes";

  component XOR18 is
    generic (
      C_USE_LUT6 : boolean);
    port (
      InA : in  std_logic_vector(0 to 17);
      res : out std_logic);
  end component XOR18;
  
  component Parity is
    generic (
      C_USE_LUT6 : boolean;
      C_SIZE     : integer);
    port (
      InA : in  std_logic_vector(0 to C_SIZE - 1);
      Res : out std_logic);
  end component Parity;

 --    component ParityEnable
 --      generic (
 --        C_USE_LUT6 : boolean;
 --        C_SIZE     : integer);
 --      port (
 --        InA    : in  std_logic_vector(0 to C_SIZE - 1);
 --        Enable : in  std_logic;
 --        Res    : out std_logic);
 --    end component ParityEnable;
  
  
  signal data_chk0          : std_logic_vector(0 to 34);
  signal data_chk1          : std_logic_vector(0 to 34);
  signal data_chk2          : std_logic_vector(0 to 34);
  signal data_chk3          : std_logic_vector(0 to 30);
  signal data_chk4          : std_logic_vector(0 to 30);
  signal data_chk5          : std_logic_vector(0 to 30);
  
  signal data_chk6          : std_logic_vector(0 to 6);
  signal data_chk6_xor      : std_logic;
  
  -- signal data_chk7_a        : std_logic_vector(0 to 17);
  -- signal data_chk7_b        : std_logic_vector(0 to 17);
  -- signal data_chk7_i        : std_logic;
  -- signal data_chk7_xor      : std_logic;
  -- signal data_chk7_i_xor    : std_logic;
  -- signal data_chk7_a_xor      : std_logic;
  -- signal data_chk7_b_xor    : std_logic;
 
  
begin  -- architecture IMP


    -- Add bits for 64-bit ECC
    
    -- 0 <= 0 1 3 4 6 8 10 11 13 17 19 21 23 25 26 28 30 
    --      32 34 36 38 40 42 44 46 48 50 52 54 56 57 59 61 63 

  data_chk0 <= DataIn(0) & DataIn(1) & DataIn(3) & DataIn(4) & DataIn(6) & DataIn(8) & DataIn(10) &
               DataIn(11) & DataIn(13) & DataIn(15) & DataIn(17) & DataIn(19) & DataIn(21) &
               DataIn(23) & DataIn(25) & DataIn(26) & DataIn(28) & DataIn(30) &
               
               DataIn(32) & DataIn(34) & DataIn(36) & DataIn(38) & DataIn(40) & 
               DataIn(42) & DataIn(44) & DataIn(46) & DataIn(48) & DataIn(50) & 
               DataIn(52) & DataIn(54) & DataIn(56) & DataIn(57) & DataIn(59) & 
               DataIn(61) & DataIn(63) ;

    -- 18 + 17 = 35

    ---------------------------------------------------------------------------


    -- 1 <= 0 2 3 5 6 9 10 12 13 16 17 20 21 24 25 27 28 31
    --      32 35 36 39 40 43 44 47 48 51 52 55 56 58 59 62 63


  data_chk1 <= DataIn(0) & DataIn(2) & DataIn(3) & DataIn(5) & DataIn(6) & DataIn(9) & DataIn(10) &
               DataIn(12) & DataIn(13) & DataIn(16) & DataIn(17) & DataIn(20) & DataIn(21) &
               DataIn(24) & DataIn(25) & DataIn(27) & DataIn(28) & DataIn(31) &
               
                 DataIn(32) & DataIn(35) & DataIn(36) & DataIn(39) & DataIn(40) &
                 DataIn(43) & DataIn(44) & DataIn(47) & DataIn(48) & DataIn(51) &
                 DataIn(52) & DataIn(55) & DataIn(56) & DataIn(58) & DataIn(59) &
                 DataIn(62) & DataIn(63) ;

    -- 18 + 17 = 35

    ---------------------------------------------------------------------------
               
               
    -- 2 <=   1 2 3 7 8 9 10 14 15 16 17 22 23 24 25 29 30 31
    --        32 37 38 39 40 45 46 47 48 53 54 55 56 60 61 62 63 
               
  data_chk2 <= DataIn(1) & DataIn(2) & DataIn(3) & DataIn(7) & DataIn(8) & DataIn(9) & DataIn(10) &
               DataIn(14) & DataIn(15) & DataIn(16) & DataIn(17) & DataIn(22) & DataIn(23) & DataIn(24) &
               DataIn(25) & DataIn(29) & DataIn(30) & DataIn(31) &
               
               DataIn(32) & DataIn(37) & DataIn(38) & DataIn(39) & DataIn(40) & DataIn(45) &
               DataIn(46) & DataIn(47) & DataIn(48) & DataIn(53) & DataIn(54) & DataIn(55) &
               DataIn(56) & DataIn(60) & DataIn(61) & DataIn(62) & DataIn(63) ;

    -- 18 + 17 = 35

    ---------------------------------------------------------------------------


    -- 3 <= 4 5 6 7 8 9 10 18 19 20 21 22 23 24 25
    --      33 34 35 36 37 38 39 40 49 50 51 52 53 54 55 56

  data_chk3 <= DataIn(4) & DataIn(5) & DataIn(6) & DataIn(7) & DataIn(8) & DataIn(9) & DataIn(10) &
               DataIn(18) & DataIn(19) & DataIn(20) & DataIn(21) & DataIn(22) & DataIn(23) & DataIn(24) &
               DataIn(25) &
               
               DataIn(33) & DataIn(34) & DataIn(35) & DataIn(36) & DataIn(37) & DataIn(38) & DataIn(39) &
               DataIn(40) & DataIn(49) & DataIn(50) & DataIn(51) & DataIn(52) & DataIn(53) & DataIn(54) &
               DataIn(55) & DataIn(56) ;

    -- 15 + 16 = 31

    ---------------------------------------------------------------------------


    -- 4 <= 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
    --      41-56

  data_chk4 <= DataIn(11) & DataIn(12) & DataIn(13) & DataIn(14) & DataIn(15) & DataIn(16) & DataIn(17) &
               DataIn(18) & DataIn(19) & DataIn(20) & DataIn(21) & DataIn(22) & DataIn(23) & DataIn(24) &
               DataIn(25) &
               
               DataIn(41) & DataIn(42) & DataIn(43) & DataIn(44) & DataIn(45) & DataIn(46) & DataIn(47) &
               DataIn(48) & DataIn(49) & DataIn(50) & DataIn(51) & DataIn(52) & DataIn(53) & DataIn(54) &
               DataIn(55) & DataIn(56) ;

    -- 15 + 16 = 31

    ---------------------------------------------------------------------------


    -- 5 <= 26 - 31
    --      32 - 56

  data_chk5   <= DataIn(26) & DataIn(27) & DataIn(28) & DataIn(29) & DataIn(30) & DataIn(31) &  
                 DataIn(32) & DataIn(33) & DataIn(34) & DataIn(35) & DataIn(36) & DataIn(37) & 
                 DataIn(38) & DataIn(39) & DataIn(40) & DataIn(41) & DataIn(42) & DataIn(43) &
               
                 DataIn(44) & DataIn(45) & DataIn(46) & DataIn(47) & DataIn(48) & DataIn(49) & 
                 DataIn(50) & DataIn(51) & DataIn(52) & DataIn(53) & DataIn(54) & DataIn(55) & 
                 DataIn(56) ;


    -- 18 + 13 = 31

    ---------------------------------------------------------------------------


    -- New additional checkbit for 64-bit data
    -- 6 <= 57 - 63

  data_chk6   <= DataIn(57) & DataIn(58) & DataIn(59) & DataIn(60) & DataIn(61) & DataIn(62) &
               DataIn(63) ;




  -- Encode bits for writing data
  Encode_Bits : if (C_ENCODE) generate

  -- signal data_chk0_i        : std_logic_vector(0 to 17);
  -- signal data_chk0_xor      : std_logic;
  -- signal data_chk0_i_xor    : std_logic;

  -- signal data_chk1_i        : std_logic_vector(0 to 17);
  -- signal data_chk1_xor      : std_logic;
  -- signal data_chk1_i_xor    : std_logic;

  -- signal data_chk2_i        : std_logic_vector(0 to 17);
  -- signal data_chk2_xor      : std_logic;
  -- signal data_chk2_i_xor    : std_logic;

  -- signal data_chk3_i        : std_logic_vector(0 to 17);
  -- signal data_chk3_xor      : std_logic;
  -- signal data_chk3_i_xor    : std_logic;

  -- signal data_chk4_i        : std_logic_vector(0 to 17);
  -- signal data_chk4_xor      : std_logic;
  -- signal data_chk4_i_xor    : std_logic;

  -- signal data_chk5_i        : std_logic_vector(0 to 17);
  -- signal data_chk5_xor      : std_logic;
  -- signal data_chk5_i_xor    : std_logic;
  
  -- signal data_chk6_i        : std_logic;


  -- signal data_chk0_xor_reg    : std_logic;          
  -- signal data_chk0_i_xor_reg  : std_logic;          
  -- signal data_chk1_xor_reg    : std_logic;          
  -- signal data_chk1_i_xor_reg  : std_logic;          
  -- signal data_chk2_xor_reg    : std_logic;          
  -- signal data_chk2_i_xor_reg  : std_logic;          
  -- signal data_chk3_xor_reg    : std_logic;          
  -- signal data_chk3_i_xor_reg  : std_logic;          
  -- signal data_chk4_xor_reg    : std_logic;          
  -- signal data_chk4_i_xor_reg  : std_logic;          
  -- signal data_chk5_xor_reg    : std_logic;          
  -- signal data_chk5_i_xor_reg  : std_logic;          
  -- signal data_chk6_i_reg      : std_logic;          
  -- signal data_chk7_a_xor_reg  : std_logic;          
  -- signal data_chk7_b_xor_reg  : std_logic;          


  -- Checkbit (0)
  signal data_chk0_a           : std_logic_vector (0 to 5);  
  signal data_chk0_b           : std_logic_vector (0 to 5);  
  signal data_chk0_c           : std_logic_vector (0 to 5);  
  signal data_chk0_d           : std_logic_vector (0 to 5);  
  signal data_chk0_e           : std_logic_vector (0 to 5);  
  signal data_chk0_f           : std_logic_vector (0 to 4);  
  
  signal data_chk0_a_xor       : std_logic;  
  signal data_chk0_b_xor       : std_logic;  
  signal data_chk0_c_xor       : std_logic;  
  signal data_chk0_d_xor       : std_logic;  
  signal data_chk0_e_xor       : std_logic;  
  signal data_chk0_f_xor       : std_logic;  

  signal data_chk0_a_xor_reg   : std_logic;  
  signal data_chk0_b_xor_reg   : std_logic;  
  signal data_chk0_c_xor_reg   : std_logic;  
  signal data_chk0_d_xor_reg   : std_logic;  
  signal data_chk0_e_xor_reg   : std_logic;  
  signal data_chk0_f_xor_reg   : std_logic;  
  
  
  -- Checkbit (1)
  signal data_chk1_a           : std_logic_vector (0 to 5);  
  signal data_chk1_b           : std_logic_vector (0 to 5);  
  signal data_chk1_c           : std_logic_vector (0 to 5);  
  signal data_chk1_d           : std_logic_vector (0 to 5);  
  signal data_chk1_e           : std_logic_vector (0 to 5);  
  signal data_chk1_f           : std_logic_vector (0 to 4);  
  
  signal data_chk1_a_xor       : std_logic;  
  signal data_chk1_b_xor       : std_logic;  
  signal data_chk1_c_xor       : std_logic;  
  signal data_chk1_d_xor       : std_logic;  
  signal data_chk1_e_xor       : std_logic;  
  signal data_chk1_f_xor       : std_logic;  

  signal data_chk1_a_xor_reg   : std_logic;  
  signal data_chk1_b_xor_reg   : std_logic;  
  signal data_chk1_c_xor_reg   : std_logic;  
  signal data_chk1_d_xor_reg   : std_logic;  
  signal data_chk1_e_xor_reg   : std_logic;  
  signal data_chk1_f_xor_reg   : std_logic;  


  -- Checkbit (2)
  signal data_chk2_a           : std_logic_vector (0 to 5);  
  signal data_chk2_b           : std_logic_vector (0 to 5);  
  signal data_chk2_c           : std_logic_vector (0 to 5);  
  signal data_chk2_d           : std_logic_vector (0 to 5);  
  signal data_chk2_e           : std_logic_vector (0 to 5);  
  signal data_chk2_f           : std_logic_vector (0 to 4);  
  
  signal data_chk2_a_xor       : std_logic;  
  signal data_chk2_b_xor       : std_logic;  
  signal data_chk2_c_xor       : std_logic;  
  signal data_chk2_d_xor       : std_logic;  
  signal data_chk2_e_xor       : std_logic;  
  signal data_chk2_f_xor       : std_logic;  

  signal data_chk2_a_xor_reg   : std_logic;  
  signal data_chk2_b_xor_reg   : std_logic;  
  signal data_chk2_c_xor_reg   : std_logic;  
  signal data_chk2_d_xor_reg   : std_logic;  
  signal data_chk2_e_xor_reg   : std_logic;  
  signal data_chk2_f_xor_reg   : std_logic;  


  -- Checkbit (3)
  signal data_chk3_a           : std_logic_vector (0 to 5);  
  signal data_chk3_b           : std_logic_vector (0 to 5);  
  signal data_chk3_c           : std_logic_vector (0 to 5);  
  signal data_chk3_d           : std_logic_vector (0 to 5);  
  signal data_chk3_e           : std_logic_vector (0 to 5);  
  
  signal data_chk3_a_xor       : std_logic;  
  signal data_chk3_b_xor       : std_logic;  
  signal data_chk3_c_xor       : std_logic;  
  signal data_chk3_d_xor       : std_logic;  
  signal data_chk3_e_xor       : std_logic;  
  signal data_chk3_f_xor       : std_logic;  
  
  signal data_chk3_a_xor_reg   : std_logic;  
  signal data_chk3_b_xor_reg   : std_logic;  
  signal data_chk3_c_xor_reg   : std_logic;  
  signal data_chk3_d_xor_reg   : std_logic;  
  signal data_chk3_e_xor_reg   : std_logic;  
  signal data_chk3_f_xor_reg   : std_logic;  


  -- Checkbit (4)
  signal data_chk4_a           : std_logic_vector (0 to 5);  
  signal data_chk4_b           : std_logic_vector (0 to 5);  
  signal data_chk4_c           : std_logic_vector (0 to 5);  
  signal data_chk4_d           : std_logic_vector (0 to 5);  
  signal data_chk4_e           : std_logic_vector (0 to 5);  
  
  signal data_chk4_a_xor       : std_logic;  
  signal data_chk4_b_xor       : std_logic;  
  signal data_chk4_c_xor       : std_logic;  
  signal data_chk4_d_xor       : std_logic;  
  signal data_chk4_e_xor       : std_logic;  
  signal data_chk4_f_xor       : std_logic;  
  
  signal data_chk4_a_xor_reg   : std_logic;  
  signal data_chk4_b_xor_reg   : std_logic;  
  signal data_chk4_c_xor_reg   : std_logic;  
  signal data_chk4_d_xor_reg   : std_logic;  
  signal data_chk4_e_xor_reg   : std_logic;  
  signal data_chk4_f_xor_reg   : std_logic;  

  
  -- Checkbit (5)
  signal data_chk5_a           : std_logic_vector (0 to 5);  
  signal data_chk5_b           : std_logic_vector (0 to 5);  
  signal data_chk5_c           : std_logic_vector (0 to 5);  
  signal data_chk5_d           : std_logic_vector (0 to 5);  
  signal data_chk5_e           : std_logic_vector (0 to 5);  
  
  signal data_chk5_a_xor       : std_logic;  
  signal data_chk5_b_xor       : std_logic;  
  signal data_chk5_c_xor       : std_logic;  
  signal data_chk5_d_xor       : std_logic;  
  signal data_chk5_e_xor       : std_logic;  
  signal data_chk5_f_xor       : std_logic;  
  
  signal data_chk5_a_xor_reg   : std_logic;  
  signal data_chk5_b_xor_reg   : std_logic;  
  signal data_chk5_c_xor_reg   : std_logic;  
  signal data_chk5_d_xor_reg   : std_logic;  
  signal data_chk5_e_xor_reg   : std_logic;  
  signal data_chk5_f_xor_reg   : std_logic;  
  

  -- Checkbit (6)
  signal data_chk6_a            : std_logic; 
  signal data_chk6_b            : std_logic; 

  signal data_chk6_a_reg        : std_logic; 
  signal data_chk6_b_reg        : std_logic; 


  -- Checkbit (7)
  signal data_chk7_a            : std_logic_vector (0 to 5);     
  signal data_chk7_b            : std_logic_vector (0 to 5);     
  signal data_chk7_c            : std_logic_vector (0 to 5);     
  signal data_chk7_d            : std_logic_vector (0 to 5);     
  signal data_chk7_e            : std_logic_vector (0 to 5);     
  signal data_chk7_f            : std_logic_vector (0 to 4);     

  signal data_chk7_a_xor        : std_logic;     
  signal data_chk7_b_xor        : std_logic;     
  signal data_chk7_c_xor        : std_logic;     
  signal data_chk7_d_xor        : std_logic;     
  signal data_chk7_e_xor        : std_logic;     
  signal data_chk7_f_xor        : std_logic;     

  signal data_chk7_a_xor_reg   : std_logic;  
  signal data_chk7_b_xor_reg   : std_logic;  
  signal data_chk7_c_xor_reg   : std_logic;  
  signal data_chk7_d_xor_reg   : std_logic;  
  signal data_chk7_e_xor_reg   : std_logic;  
  signal data_chk7_f_xor_reg   : std_logic;  



  begin
  
      -----------------------------------------------------------------------------
      -- For timing improvements, if check bit XOR logic
      -- needs to be pipelined.  Add register level here
      -- after 1st LUT level.
  
      REG_BITS : if (C_REG) generate
      begin
          REG_CHK: process (Clk)
          begin    
              if (Clk'event and Clk = '1' ) then
                -- Checkbit (0)
                -- data_chk0_xor_reg   <= data_chk0_xor;
                -- data_chk0_i_xor_reg <= data_chk0_i_xor;
                
                data_chk0_a_xor_reg <= data_chk0_a_xor;
                data_chk0_b_xor_reg <= data_chk0_b_xor;
                data_chk0_c_xor_reg <= data_chk0_c_xor;
                data_chk0_d_xor_reg <= data_chk0_d_xor;
                data_chk0_e_xor_reg <= data_chk0_e_xor;
                data_chk0_f_xor_reg <= data_chk0_f_xor;
                
                
                
                -- Checkbit (1)
                -- data_chk1_xor_reg   <= data_chk1_xor;
                -- data_chk1_i_xor_reg <= data_chk1_i_xor;

                data_chk1_a_xor_reg <= data_chk1_a_xor;
                data_chk1_b_xor_reg <= data_chk1_b_xor;
                data_chk1_c_xor_reg <= data_chk1_c_xor;
                data_chk1_d_xor_reg <= data_chk1_d_xor;
                data_chk1_e_xor_reg <= data_chk1_e_xor;
                data_chk1_f_xor_reg <= data_chk1_f_xor;


                -- Checkbit (2)
                -- data_chk2_xor_reg   <= data_chk2_xor;
                -- data_chk2_i_xor_reg <= data_chk2_i_xor;
                
                data_chk2_a_xor_reg <= data_chk2_a_xor;
                data_chk2_b_xor_reg <= data_chk2_b_xor;
                data_chk2_c_xor_reg <= data_chk2_c_xor;
                data_chk2_d_xor_reg <= data_chk2_d_xor;
                data_chk2_e_xor_reg <= data_chk2_e_xor;
                data_chk2_f_xor_reg <= data_chk2_f_xor;

                
                
                
                -- Checkbit (3)
                -- data_chk3_xor_reg   <= data_chk3_xor;
                -- data_chk3_i_xor_reg <= data_chk3_i_xor;
                
                data_chk3_a_xor_reg <= data_chk3_a_xor;
                data_chk3_b_xor_reg <= data_chk3_b_xor;
                data_chk3_c_xor_reg <= data_chk3_c_xor;
                data_chk3_d_xor_reg <= data_chk3_d_xor;
                data_chk3_e_xor_reg <= data_chk3_e_xor;
                data_chk3_f_xor_reg <= data_chk3_f_xor;
                
                
                
                
                -- Checkbit (4)
                -- data_chk4_xor_reg   <= data_chk4_xor;
                -- data_chk4_i_xor_reg <= data_chk4_i_xor;
                
                data_chk4_a_xor_reg <= data_chk4_a_xor;
                data_chk4_b_xor_reg <= data_chk4_b_xor;
                data_chk4_c_xor_reg <= data_chk4_c_xor;
                data_chk4_d_xor_reg <= data_chk4_d_xor;
                data_chk4_e_xor_reg <= data_chk4_e_xor;
                data_chk4_f_xor_reg <= data_chk4_f_xor;
                
                
                -- Checkbit (5)
                -- data_chk5_xor_reg   <= data_chk5_xor;
                -- data_chk5_i_xor_reg <= data_chk5_i_xor;
 
                 data_chk5_a_xor_reg <= data_chk5_a_xor;
                 data_chk5_b_xor_reg <= data_chk5_b_xor;
                 data_chk5_c_xor_reg <= data_chk5_c_xor;
                 data_chk5_d_xor_reg <= data_chk5_d_xor;
                 data_chk5_e_xor_reg <= data_chk5_e_xor;
                 data_chk5_f_xor_reg <= data_chk5_f_xor;

                
                -- Checkbit (6)
                -- data_chk6_i_reg     <= data_chk6_i;
                data_chk6_a_reg <= data_chk6_a;
                data_chk6_b_reg <= data_chk6_b;
                

                -- Checkbit (7)
                -- data_chk7_a_xor_reg <= data_chk7_a_xor;
                -- data_chk7_b_xor_reg <= data_chk7_b_xor;

                data_chk7_a_xor_reg <= data_chk7_a_xor;
                data_chk7_b_xor_reg <= data_chk7_b_xor;
                data_chk7_c_xor_reg <= data_chk7_c_xor;
                data_chk7_d_xor_reg <= data_chk7_d_xor;
                data_chk7_e_xor_reg <= data_chk7_e_xor;
                data_chk7_f_xor_reg <= data_chk7_f_xor;
                
              end if;
              
          end process REG_CHK;


          -- Perform the last XOR after the register stage
          -- CheckOut(0) <= data_chk0_xor_reg xor data_chk0_i_xor_reg;
          
          CheckOut(0) <= data_chk0_a_xor_reg xor 
                         data_chk0_b_xor_reg xor
                         data_chk0_c_xor_reg xor 
                         data_chk0_d_xor_reg xor 
                         data_chk0_e_xor_reg xor 
                         data_chk0_f_xor_reg;
          
          
          -- CheckOut(1) <= data_chk1_xor_reg xor data_chk1_i_xor_reg;
          
          CheckOut(1) <= data_chk1_a_xor_reg xor 
                         data_chk1_b_xor_reg xor
                         data_chk1_c_xor_reg xor 
                         data_chk1_d_xor_reg xor 
                         data_chk1_e_xor_reg xor 
                         data_chk1_f_xor_reg;
          
          
          
          
          -- CheckOut(2) <= data_chk2_xor_reg xor data_chk2_i_xor_reg;

          CheckOut(2) <= data_chk2_a_xor_reg xor 
                         data_chk2_b_xor_reg xor
                         data_chk2_c_xor_reg xor 
                         data_chk2_d_xor_reg xor 
                         data_chk2_e_xor_reg xor 
                         data_chk2_f_xor_reg;
          
          
          -- CheckOut(3) <= data_chk3_xor_reg xor data_chk3_i_xor_reg;
          
          CheckOut(3) <= data_chk3_a_xor_reg xor 
                         data_chk3_b_xor_reg xor
                         data_chk3_c_xor_reg xor 
                         data_chk3_d_xor_reg xor 
                         data_chk3_e_xor_reg xor 
                         data_chk3_f_xor_reg;
          
          
          -- CheckOut(4) <= data_chk4_xor_reg xor data_chk4_i_xor_reg;

          CheckOut(4) <= data_chk4_a_xor_reg xor 
                         data_chk4_b_xor_reg xor
                         data_chk4_c_xor_reg xor 
                         data_chk4_d_xor_reg xor 
                         data_chk4_e_xor_reg xor 
                         data_chk4_f_xor_reg;

          -- CheckOut(5) <= data_chk5_xor_reg xor data_chk5_i_xor_reg;

          CheckOut(5) <= data_chk5_a_xor_reg xor 
                         data_chk5_b_xor_reg xor
                         data_chk5_c_xor_reg xor 
                         data_chk5_d_xor_reg xor 
                         data_chk5_e_xor_reg xor 
                         data_chk5_f_xor_reg;
          
          
          -- CheckOut(6) <= data_chk6_i_reg;
          CheckOut(6) <= data_chk6_a_reg xor data_chk6_b_reg;
          
          -- CheckOut(7) <= data_chk7_a_xor_reg xor data_chk7_b_xor_reg;
          CheckOut(7) <= data_chk7_a_xor_reg xor 
                         data_chk7_b_xor_reg xor
                         data_chk7_c_xor_reg xor 
                         data_chk7_d_xor_reg xor 
                         data_chk7_e_xor_reg xor 
                         data_chk7_f_xor_reg;

      
      end generate REG_BITS;
  
      NO_REG_BITS: if (not C_REG) generate
      begin
          -- CheckOut(0) <= data_chk0_xor xor data_chk0_i_xor;
          
          CheckOut(0) <= data_chk0_a_xor xor 
                         data_chk0_b_xor xor
                         data_chk0_c_xor xor 
                         data_chk0_d_xor xor 
                         data_chk0_e_xor xor 
                         data_chk0_f_xor;         
          
          -- CheckOut(1) <= data_chk1_xor xor data_chk1_i_xor;

          CheckOut(1) <= data_chk1_a_xor xor 
                         data_chk1_b_xor xor
                         data_chk1_c_xor xor 
                         data_chk1_d_xor xor 
                         data_chk1_e_xor xor 
                         data_chk1_f_xor;         


          -- CheckOut(2) <= data_chk2_xor xor data_chk2_i_xor;

          CheckOut(2) <= data_chk2_a_xor xor 
                         data_chk2_b_xor xor
                         data_chk2_c_xor xor 
                         data_chk2_d_xor xor 
                         data_chk2_e_xor xor 
                         data_chk2_f_xor;         

          -- CheckOut(3) <= data_chk3_xor xor data_chk3_i_xor;

          CheckOut(3) <= data_chk3_a_xor xor 
                         data_chk3_b_xor xor
                         data_chk3_c_xor xor 
                         data_chk3_d_xor xor 
                         data_chk3_e_xor xor 
                         data_chk3_f_xor;         


          -- CheckOut(4) <= data_chk4_xor xor data_chk4_i_xor;

          CheckOut(4) <= data_chk4_a_xor xor 
                         data_chk4_b_xor xor
                         data_chk4_c_xor xor 
                         data_chk4_d_xor xor 
                         data_chk4_e_xor xor 
                         data_chk4_f_xor;         

          -- CheckOut(5) <= data_chk5_xor xor data_chk5_i_xor;
          
          CheckOut(5) <= data_chk5_a_xor xor 
                         data_chk5_b_xor xor
                         data_chk5_c_xor xor 
                         data_chk5_d_xor xor 
                         data_chk5_e_xor xor 
                         data_chk5_f_xor;         
          
          
          
          -- CheckOut(6) <= data_chk6_i;
          CheckOut(6) <= data_chk6_a xor data_chk6_b;
          
          -- CheckOut(7) <= data_chk7_a_xor xor data_chk7_b_xor;
          CheckOut(7) <= data_chk7_a_xor xor 
                         data_chk7_b_xor xor
                         data_chk7_c_xor xor 
                         data_chk7_d_xor xor 
                         data_chk7_e_xor xor 
                         data_chk7_f_xor;


      end generate NO_REG_BITS;
  
      -----------------------------------------------------------------------------

  
  
    -------------------------------------------------------------------------------
    -- Checkbit 0 built up using 2x XOR18
    -------------------------------------------------------------------------------

    --     XOR18_I0_A : XOR18
    --       generic map (
    --         C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --       port map (
    --         InA => data_chk0 (0 to 17),         -- [in  std_logic_vector(0 to 17)]
    --         res => data_chk0_xor);              -- [out std_logic]
    --     
    --     data_chk0_i <= data_chk0 (18 to 34) & '0';
    --     
    --     XOR18_I0_B : XOR18
    --       generic map (
    --         C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --       port map (
    --         InA => data_chk0_i,                 -- [in  std_logic_vector(0 to 17)]
    --         res => data_chk0_i_xor);            -- [out std_logic]
    --     
    --     -- CheckOut(0) <= data_chk0_xor xor data_chk0_i_xor;
    
    -- Push register stage to earlier in ECC XOR logic stages (when enabled, C_REG)
    
    data_chk0_a <= data_chk0 (0 to 5);
    data_chk0_b <= data_chk0 (6 to 11);
    data_chk0_c <= data_chk0 (12 to 17);
    data_chk0_d <= data_chk0 (18 to 23);
    data_chk0_e <= data_chk0 (24 to 29);
    data_chk0_f <= data_chk0 (30 to 34);
    
    PARITY_CHK0_A : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk0_a (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk0_a_xor );           -- [out std_logic]
    
    PARITY_CHK0_B : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk0_b (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk0_b_xor );           -- [out std_logic]
    
    PARITY_CHK0_C : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk0_c (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk0_c_xor );           -- [out std_logic]
    
    PARITY_CHK0_D : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk0_d (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk0_d_xor );           -- [out std_logic]
    
    PARITY_CHK0_E : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk0_e (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk0_e_xor );           -- [out std_logic]
    
    PARITY_CHK0_F : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 5)
    port map (
        InA => data_chk0_f (0 to 4),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk0_f_xor );           -- [out std_logic]
    
    


    -------------------------------------------------------------------------------
    -- Checkbit 1 built up using 2x XOR18
    -------------------------------------------------------------------------------
    
    --     XOR18_I1_A : XOR18
    --      generic map (
    --        C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --      port map (
    --        InA => data_chk1 (0 to 17),         -- [in  std_logic_vector(0 to 17)]
    --        res => data_chk1_xor);              -- [out std_logic]
    --     
    --     data_chk1_i <= data_chk1 (18 to 34) & '0';
    --     
    --     XOR18_I1_B : XOR18
    --      generic map (
    --        C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --      port map (
    --        InA => data_chk1_i,                 -- [in  std_logic_vector(0 to 17)]
    --        res => data_chk1_i_xor);            -- [out std_logic]
    --     
    --     -- CheckOut(1) <= data_chk1_xor xor data_chk1_i_xor;


    -- Push register stage to earlier in ECC XOR logic stages (when enabled, C_REG)
    
    data_chk1_a <= data_chk1 (0 to 5);
    data_chk1_b <= data_chk1 (6 to 11);
    data_chk1_c <= data_chk1 (12 to 17);
    data_chk1_d <= data_chk1 (18 to 23);
    data_chk1_e <= data_chk1 (24 to 29);
    data_chk1_f <= data_chk1 (30 to 34);
    
    PARITY_chk1_A : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk1_a (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk1_a_xor );           -- [out std_logic]
    
    PARITY_chk1_B : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk1_b (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk1_b_xor );           -- [out std_logic]
    
    PARITY_chk1_C : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk1_c (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk1_c_xor );           -- [out std_logic]
    
    PARITY_chk1_D : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk1_d (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk1_d_xor );           -- [out std_logic]
    
    PARITY_chk1_E : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk1_e (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk1_e_xor );           -- [out std_logic]
    
    PARITY_chk1_F : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 5)
    port map (
        InA => data_chk1_f (0 to 4),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk1_f_xor );           -- [out std_logic]
    
    




    ------------------------------------------------------------------------------------------------
    -- Checkbit 2 built up using 2x XOR18
    ------------------------------------------------------------------------------------------------
    
    --     XOR18_I2_A : XOR18
    --       generic map (
    --         C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --       port map (
    --         InA => data_chk2 (0 to 17),         -- [in  std_logic_vector(0 to 17)]
    --         res => data_chk2_xor);              -- [out std_logic]
    --     
    --     data_chk2_i <= data_chk2 (18 to 34) & '0';
    --     
    --     XOR18_I2_B : XOR18
    --       generic map (
    --         C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --       port map (
    --         InA => data_chk2_i,                   -- [in  std_logic_vector(0 to 17)]
    --         res => data_chk2_i_xor);            -- [out std_logic]
    --     
    --     -- CheckOut(2) <= data_chk2_xor xor data_chk2_i_xor;



    -- Push register stage to earlier in ECC XOR logic stages (when enabled, C_REG)
    
    data_chk2_a <= data_chk2 (0 to 5);
    data_chk2_b <= data_chk2 (6 to 11);
    data_chk2_c <= data_chk2 (12 to 17);
    data_chk2_d <= data_chk2 (18 to 23);
    data_chk2_e <= data_chk2 (24 to 29);
    data_chk2_f <= data_chk2 (30 to 34);
    
    PARITY_chk2_A : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk2_a (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk2_a_xor );           -- [out std_logic]
    
    PARITY_chk2_B : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk2_b (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk2_b_xor );           -- [out std_logic]
    
    PARITY_chk2_C : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk2_c (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk2_c_xor );           -- [out std_logic]
    
    PARITY_chk2_D : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk2_d (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk2_d_xor );           -- [out std_logic]
    
    PARITY_chk2_E : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk2_e (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk2_e_xor );           -- [out std_logic]
    
    PARITY_chk2_F : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 5)
    port map (
        InA => data_chk2_f (0 to 4),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk2_f_xor );           -- [out std_logic]
    
    



    ------------------------------------------------------------------------------------------------
    -- Checkbit 3 built up using 2x XOR18
    ------------------------------------------------------------------------------------------------   

    --     XOR18_I3_A : XOR18
    --       generic map (
    --         C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --       port map (
    --         InA => data_chk3 (0 to 17),         -- [in  std_logic_vector(0 to 17)]
    --         res => data_chk3_xor);              -- [out std_logic]
    --     
    --     data_chk3_i <= data_chk3 (18 to 30) & "00000";
    --     
    --     XOR18_I3_B : XOR18
    --       generic map (
    --         C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --       port map (
    --         InA => data_chk3_i,                 -- [in  std_logic_vector(0 to 17)]
    --         res => data_chk3_i_xor);            -- [out std_logic]
    --     
    --     -- CheckOut(3) <= data_chk3_xor xor data_chk3_i_xor;


    -- Push register stage to earlier in ECC XOR logic stages (when enabled, C_REG)
    
    data_chk3_a <= data_chk3 (0 to 5);
    data_chk3_b <= data_chk3 (6 to 11);
    data_chk3_c <= data_chk3 (12 to 17);
    data_chk3_d <= data_chk3 (18 to 23);
    data_chk3_e <= data_chk3 (24 to 29);
    
    data_chk3_f_xor <= data_chk3 (30);
    
    PARITY_chk3_A : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk3_a (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk3_a_xor );           -- [out std_logic]
    
    PARITY_chk3_B : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk3_b (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk3_b_xor );           -- [out std_logic]
    
    PARITY_chk3_C : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk3_c (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk3_c_xor );           -- [out std_logic]
    
    PARITY_chk3_D : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk3_d (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk3_d_xor );           -- [out std_logic]
    
    PARITY_chk3_E : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk3_e (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk3_e_xor );           -- [out std_logic]
        
    


    ------------------------------------------------------------------------------------------------
    -- Checkbit 4 built up using 2x XOR18
    ------------------------------------------------------------------------------------------------
    
    --     XOR18_I4_A : XOR18
    --       generic map (
    --         C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --       port map (
    --         InA => data_chk4 (0 to 17),         -- [in  std_logic_vector(0 to 17)]
    --         res => data_chk4_xor);              -- [out std_logic]
    --     
    --     data_chk4_i <= data_chk4 (18 to 30) & "00000";
    --     
    --     XOR18_I4_B : XOR18
    --       generic map (
    --         C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --       port map (
    --         InA => data_chk4_i,                 -- [in  std_logic_vector(0 to 17)]
    --         res => data_chk4_i_xor);            -- [out std_logic]
    --     
    --     -- CheckOut(4) <= data_chk4_xor xor data_chk4_i_xor;



    -- Push register stage to earlier in ECC XOR logic stages (when enabled, C_REG)
    
    data_chk4_a <= data_chk4 (0 to 5);
    data_chk4_b <= data_chk4 (6 to 11);
    data_chk4_c <= data_chk4 (12 to 17);
    data_chk4_d <= data_chk4 (18 to 23);
    data_chk4_e <= data_chk4 (24 to 29);
    
    data_chk4_f_xor <= data_chk4 (30);
    
    PARITY_chk4_A : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk4_a (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk4_a_xor );           -- [out std_logic]
    
    PARITY_chk4_B : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk4_b (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk4_b_xor );           -- [out std_logic]
    
    PARITY_chk4_C : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk4_c (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk4_c_xor );           -- [out std_logic]
    
    PARITY_chk4_D : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk4_d (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk4_d_xor );           -- [out std_logic]
    
    PARITY_chk4_E : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk4_e (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk4_e_xor );           -- [out std_logic]
        
    



    ------------------------------------------------------------------------------------------------
    -- Checkbit 5 built up using 2x XOR18
    ------------------------------------------------------------------------------------------------   

    --     XOR18_I5_A : XOR18
    --       generic map (
    --         C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --       port map (
    --         InA => data_chk5 (0 to 17),         -- [in  std_logic_vector(0 to 17)]
    --         res => data_chk5_xor);              -- [out std_logic]
    --     
    --     data_chk5_i <= data_chk5 (18 to 30) & "00000";
    --     
    --     XOR18_I5_B : XOR18
    --       generic map (
    --         C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --       port map (
    --         InA => data_chk5_i,                 -- [in  std_logic_vector(0 to 17)]
    --         res => data_chk5_i_xor);            -- [out std_logic]
    --     
    --     -- CheckOut(5) <= data_chk5_xor xor data_chk5_i_xor;


    -- Push register stage to earlier in ECC XOR logic stages (when enabled, C_REG)
    
    data_chk5_a <= data_chk5 (0 to 5);
    data_chk5_b <= data_chk5 (6 to 11);
    data_chk5_c <= data_chk5 (12 to 17);
    data_chk5_d <= data_chk5 (18 to 23);
    data_chk5_e <= data_chk5 (24 to 29);
    
    data_chk5_f_xor <= data_chk5 (30);
    
    PARITY_chk5_A : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk5_a (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk5_a_xor );           -- [out std_logic]
    
    PARITY_chk5_B : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk5_b (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk5_b_xor );           -- [out std_logic]
    
    PARITY_chk5_C : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk5_c (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk5_c_xor );           -- [out std_logic]
    
    PARITY_chk5_D : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk5_d (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk5_d_xor );           -- [out std_logic]
    
    PARITY_chk5_E : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk5_e (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk5_e_xor );           -- [out std_logic]
        
    





    ------------------------------------------------------------------------------------------------
    -- Checkbit 6 built up from 1 LUT6 + 1 XOR
    ------------------------------------------------------------------------------------------------
    Parity_chk6_I : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk6 (0 to 5),              -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk6_xor);                  -- [out std_logic]
    
    -- data_chk6_i <= data_chk6_xor xor data_chk6(6);
    -- Push register stage to 1st ECC XOR logic stage (when enabled, C_REG)
    data_chk6_a <= data_chk6_xor;
    data_chk6_b <= data_chk6(6);


    -- CheckOut(6) <= data_chk6_xor xor data_chk6(6);
    -- CheckOut(6) <= data_chk6_i;
    
    
    
    
    
    
    -- Overall checkbit 
    -- New checkbit (7) for 64-bit ECC
    
    -- 7 <= 0 1 2 4 5 7 10 11 12 14 17 18 21 23 24 26 27 29
    --      32 33 36 38 39 41 44 46 47 50 51 53 56 57 58 60 63
                 
    
    
    
    ------------------------------------------------------------------------------------------------
    -- Checkbit 6 built up from 2x XOR18
    ------------------------------------------------------------------------------------------------
    
    --     data_chk7_a <= DataIn(0) & DataIn(1) & DataIn(2) & DataIn(4) & DataIn(5) & DataIn(7) & DataIn(10) &
    --                    DataIn(11) & DataIn(12) & DataIn(14) & DataIn(17) & DataIn(18) & DataIn(21) &
    --                    DataIn(23) & DataIn(24) & DataIn(26) & DataIn(27) & DataIn(29) ;
    --                  
    --     data_chk7_b <= DataIn(32) & DataIn(33) & DataIn(36) & DataIn(38) & DataIn(39) &
    --                    DataIn(41) & DataIn(44) & DataIn(46) & DataIn(47) & DataIn(50) &
    --                    DataIn(51) & DataIn(53) & DataIn(56) & DataIn(57) & DataIn(58) &
    --                    DataIn(60) & DataIn(63) & '0';
    --                  
    --     XOR18_I7_A : XOR18
    --       generic map (
    --         C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --       port map (
    --         InA => data_chk7_a,                   -- [in  std_logic_vector(0 to 17)]
    --         res => data_chk7_a_xor);              -- [out std_logic]
    --     
    --     
    --     XOR18_I7_B : XOR18
    --       generic map (
    --         C_USE_LUT6 => C_USE_LUT6)           -- [boolean]
    --       port map (
    --         InA => data_chk7_b,                 -- [in  std_logic_vector(0 to 17)]
    --         res => data_chk7_b_xor);            -- [out std_logic]


    -- Move register stage to earlier in LUT XOR logic when enabled (for C_ENCODE only)    
    -- Break up data_chk7_a & data_chk7_b into the following 6-input LUT XOR combinations.
    
    data_chk7_a <= DataIn(0) & DataIn(1) & DataIn(2) & DataIn(4) & DataIn(5) & DataIn(7);
    data_chk7_b <= DataIn(10) & DataIn(11) & DataIn(12) & DataIn(14) & DataIn(17) & DataIn(18);
    data_chk7_c <= DataIn(21) & DataIn(23) & DataIn(24) & DataIn(26) & DataIn(27) & DataIn(29);
    data_chk7_d <= DataIn(32) & DataIn(33) & DataIn(36) & DataIn(38) & DataIn(39) & DataIn(41);
    data_chk7_e <= DataIn(44) & DataIn(46) & DataIn(47) & DataIn(50) & DataIn(51) & DataIn(53);
    data_chk7_f <= DataIn(56) & DataIn(57) & DataIn(58) & DataIn(60) & DataIn(63);


    PARITY_CHK7_A : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk7_a (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk7_a_xor );           -- [out std_logic]
    
    PARITY_CHK7_B : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk7_b (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk7_b_xor );           -- [out std_logic]
    
    PARITY_CHK7_C : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk7_c (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk7_c_xor );           -- [out std_logic]
    
    PARITY_CHK7_D : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk7_d (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk7_d_xor );           -- [out std_logic]
    
    PARITY_CHK7_E : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    port map (
        InA => data_chk7_e (0 to 5),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk7_e_xor );           -- [out std_logic]
    
    PARITY_CHK7_F : Parity
    generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 5)
    port map (
        InA => data_chk7_f (0 to 4),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => data_chk7_f_xor );           -- [out std_logic]
    

    
    -- Merge all data bits
    -- CheckOut(7) <= data_chk7_xor xor data_chk7_i_xor;
    
    -- data_chk7_i <= data_chk7_a_xor xor data_chk7_b_xor;

    -- CheckOut(7) <= data_chk7_i;    
    
    
  end generate Encode_Bits;








  --------------------------------------------------------------------------------------------------
  -- Decode bits to get syndrome and UE/CE signals
  --------------------------------------------------------------------------------------------------
  Decode_Bits : if (not C_ENCODE) generate
    signal syndrome_i  : std_logic_vector(0 to 7) := (others => '0');
    -- Unused   signal syndrome_int_7   : std_logic;
    signal chk0_1 : std_logic_vector(0 to 6);    
    signal chk1_1 : std_logic_vector(0 to 6);
    signal chk2_1 : std_logic_vector(0 to 6);
    signal data_chk3_i : std_logic_vector(0 to 31);    
    signal chk3_1 : std_logic_vector(0 to 3);    
    signal data_chk4_i : std_logic_vector(0 to 31);
    signal chk4_1 : std_logic_vector(0 to 3);
    signal data_chk5_i : std_logic_vector(0 to 31);
    signal chk5_1 : std_logic_vector(0 to 3);
    
    signal data_chk6_i : std_logic_vector(0 to 7);
    
    signal data_chk7   : std_logic_vector(0 to 71);
    signal chk7_1 : std_logic_vector(0 to 11);
    -- signal syndrome7_a : std_logic;
    -- signal syndrome7_b : std_logic;

    signal syndrome_0_to_2       : std_logic_vector(0 to 2);
    signal syndrome_3_to_6       : std_logic_vector(3 to 6);
    signal syndrome_3_to_6_multi : std_logic;
    signal syndrome_3_to_6_zero  : std_logic;
    signal ue_i_0 : std_logic;
    signal ue_i_1 : std_logic;

  begin
  
    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 0 built up from 5 LUT6, 1 LUT5 and 1 7-bit XOR
    ------------------------------------------------------------------------------------------------
--    chk0_1(3) <= CheckIn(0);
    chk0_1(6) <= CheckIn(0);    -- 64-bit ECC
    
    Parity_chk0_1 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA                   => data_chk0(0 to 5),         -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res                   => chk0_1(0));                -- [out std_logic]
        
    Parity_chk0_2 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA                   => data_chk0(6 to 11),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res                   => chk0_1(1));                -- [out std_logic]
        
    Parity_chk0_3 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA                   => data_chk0(12 to 17),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res                   => chk0_1(2));                -- [out std_logic]
        
    -- Checkbit 0
    -- 18-bit for 32-bit data
    -- 35-bit for 64-bit data
    
    Parity_chk0_4 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA                   => data_chk0(18 to 23),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res                   => chk0_1(3));                -- [out std_logic]
    
    Parity_chk0_5 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA                   => data_chk0(24 to 29),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res                   => chk0_1(4));                -- [out std_logic]

    Parity_chk0_6 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 5)
      port map (
        InA                   => data_chk0(30 to 34),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res                   => chk0_1(5));                -- [out std_logic]
        
    --    Parity_chk0_7 : ParityEnable
    --      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 7)
    --      port map (
    --        InA                   => chk0_1,            -- [in  std_logic_vector(0 to C_SIZE - 1)]
    --        Enable                => Enable_ECC,        -- [in  std_logic]
    --        Res                   => syndrome_i(0));    -- [out std_logic]

    Parity_chk0_7 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 7)
      port map (
        InA                   => chk0_1,            -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res                   => syndrome_i(0));    -- [out std_logic]




    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 1 built up from 5 LUT6, 1 LUT5 and 1 7-bit XOR
    ------------------------------------------------------------------------------------------------
--    chk1_1(3) <= CheckIn(1);
    chk1_1(6) <= CheckIn(1);    -- 64-bit ECC
    
    Parity_chk1_1 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk1(0 to 5),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk1_1(0));              -- [out std_logic]
    
    Parity_chk1_2 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk1(6 to 11),      -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk1_1(1));              -- [out std_logic]
    
    Parity_chk1_3 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk1(12 to 17),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk1_1(2));              -- [out std_logic]

        
    -- Checkbit 1
    -- 18-bit for 32-bit data
    -- 35-bit for 64-bit data

    Parity_chk1_4 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk1(18 to 23),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk1_1(3));              -- [out std_logic]

    Parity_chk1_5 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk1(24 to 29),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk1_1(4));              -- [out std_logic]

    Parity_chk1_6 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 5)
      port map (
        InA => data_chk1(30 to 34),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk1_1(5));              -- [out std_logic]

    --    Parity_chk1_7 : ParityEnable      
    --      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 7)
    --      port map (
    --        InA => chk1_1,                  -- [in  std_logic_vector(0 to C_SIZE - 1)]
    --        Enable => Enable_ECC,           -- [in  std_logic]
    --        Res => syndrome_i(1));          -- [out std_logic]

    Parity_chk1_7 : Parity      
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 7)
      port map (
        InA => chk1_1,                  -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => syndrome_i(1));          -- [out std_logic]










    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 2 built up from 5 LUT6, 1 LUT5 and 1 7-bit XOR
    ------------------------------------------------------------------------------------------------
--    chk2_1(3) <= CheckIn(2);
    chk2_1(6) <= CheckIn(2);        -- 64-bit ECC
    
    Parity_chk2_1 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk2(0 to 5),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk2_1(0));              -- [out std_logic]
    
    Parity_chk2_2 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk2(6 to 11),      -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk2_1(1));              -- [out std_logic]
    
    Parity_chk2_3 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk2(12 to 17),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk2_1(2));              -- [out std_logic]

    -- Checkbit 2
    -- 18-bit for 32-bit data
    -- 35-bit for 64-bit data
    

    Parity_chk2_4 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk2(18 to 23),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk2_1(3));              -- [out std_logic]

    Parity_chk2_5 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk2(24 to 29),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk2_1(4));              -- [out std_logic]

    Parity_chk2_6 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 5)
      port map (
        InA => data_chk2(30 to 34),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk2_1(5));              -- [out std_logic]
    
    --    Parity_chk2_7 : ParityEnable
    --      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 7)
    --      port map (
    --        InA => chk2_1,             -- [in  std_logic_vector(0 to C_SIZE - 1)]
    --        Enable => Enable_ECC,  -- [in  std_logic]
    --        Res => syndrome_i(2));          -- [out std_logic]

    Parity_chk2_7 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 7)
      port map (
        InA => chk2_1,             -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => syndrome_i(2));          -- [out std_logic]








    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 3 built up from 4 LUT8 and 1 LUT4
    ------------------------------------------------------------------------------------------------
    data_chk3_i <= data_chk3 & CheckIn(3);
    
    Parity_chk3_1 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 8)
      port map (
        InA => data_chk3_i(0 to 7),         -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk3_1(0));                  -- [out std_logic]
    
    Parity_chk3_2 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 8)
      port map (
        InA => data_chk3_i(8 to 15),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk3_1(1));                  -- [out std_logic]
    
    -- 15-bit for 32-bit ECC
    -- 31-bit for 64-bit ECC

    Parity_chk3_3 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 8)
      port map (
        InA => data_chk3_i(16 to 23),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk3_1(2));                  -- [out std_logic]
    
    Parity_chk3_4 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 8)
      port map (
        InA => data_chk3_i(24 to 31),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk3_1(3));                  -- [out std_logic]
    
    --    Parity_chk3_5 : ParityEnable
    --      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 4)
    --      port map (
    --        InA => chk3_1,                      -- [in  std_logic_vector(0 to C_SIZE - 1)]
    --        Enable => Enable_ECC,               -- [in  std_logic]
    --        Res => syndrome_i(3));              -- [out std_logic]

    Parity_chk3_5 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 4)
      port map (
        InA => chk3_1,                      -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => syndrome_i(3));              -- [out std_logic]



    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 4 built up from 4 LUT8 and 1 LUT4
    ------------------------------------------------------------------------------------------------
    data_chk4_i <= data_chk4 & CheckIn(4);
    
    -- 15-bit for 32-bit ECC
    -- 31-bit for 64-bit ECC
    
    Parity_chk4_1 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 8)
      port map (
        InA => data_chk4_i(0 to 7),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk4_1(0));              -- [out std_logic]

    Parity_chk4_2 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 8)
      port map (
        InA => data_chk4_i(8 to 15),      -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk4_1(1));              -- [out std_logic]

    Parity_chk4_3 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 8)
      port map (
        InA => data_chk4_i(16 to 23),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk4_1(2));              -- [out std_logic]

    Parity_chk4_4 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 8)
      port map (
        InA => data_chk4_i(24 to 31),      -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk4_1(3));              -- [out std_logic]


    Parity_chk4_5 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 4)
      port map (
        InA => chk4_1,                  -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => syndrome_i(4));              -- [out std_logic]




    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 5 built up from 4 LUT8 and 1 LUT4
    ------------------------------------------------------------------------------------------------
    data_chk5_i <= data_chk5 & CheckIn(5);
    
    -- 15-bit for 32-bit ECC
    -- 31-bit for 64-bit ECC
    
    Parity_chk5_1 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 8)
      port map (
        InA => data_chk5_i(0 to 7),         -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk5_1(0));                  -- [out std_logic]

    Parity_chk5_2 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 8)
      port map (
        InA => data_chk5_i(8 to 15),        -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk5_1(1));                  -- [out std_logic]

    Parity_chk5_3 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 8)
      port map (
        InA => data_chk5_i(16 to 23),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk5_1(2));                  -- [out std_logic]

    Parity_chk5_4 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 8)
      port map (
        InA => data_chk5_i(24 to 31),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk5_1(3));                  -- [out std_logic]


    Parity_chk5_5 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 4)
      port map (
        InA => chk5_1,                  -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => syndrome_i(5));              -- [out std_logic]





    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 6 built up from 1 LUT8
    ------------------------------------------------------------------------------------------------
    data_chk6_i <= data_chk6 & CheckIn(6);
    
    Parity_chk6_1 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 8)
      port map (
        InA => data_chk6_i,             -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => syndrome_i(6));          -- [out std_logic]
    
    
    
    
    ------------------------------------------------------------------------------------------------
    -- Syndrome bit 7 built up from 3 LUT7 and 8 LUT6 and 1 LUT3 (12 total) + 2 LUT6 + 1 2-bit XOR
    ------------------------------------------------------------------------------------------------
    -- 32-bit ECC uses DataIn(0:31) and Checkin (0 to 6)
    -- 64-bit ECC will use DataIn(0:63) and Checkin (0 to 7)
    
    data_chk7 <= DataIn(0) & DataIn(1) & DataIn(2) & DataIn(3) & DataIn(4) & DataIn(5) & DataIn(6) & DataIn(7) &
                 DataIn(8) & DataIn(9) & DataIn(10) & DataIn(11) & DataIn(12) & DataIn(13) & DataIn(14) &
                 DataIn(15) & DataIn(16) & DataIn(17) & DataIn(18) & DataIn(19) & DataIn(20) & DataIn(21) &
                 DataIn(22) & DataIn(23) & DataIn(24) & DataIn(25) & DataIn(26) & DataIn(27) & DataIn(28) &
                 DataIn(29) & DataIn(30) & DataIn(31) & 
                 
                 DataIn(32) & DataIn(33) & DataIn(34) & DataIn(35) & DataIn(36) & DataIn(37) & 
                 DataIn(38) & DataIn(39) & DataIn(40) & DataIn(41) & DataIn(42) & DataIn(43) &                 
                 DataIn(44) & DataIn(45) & DataIn(46) & DataIn(47) & DataIn(48) & DataIn(49) & 
                 DataIn(50) & DataIn(51) & DataIn(52) & DataIn(53) & DataIn(54) & DataIn(55) & 
                 DataIn(56) & DataIn(57) & DataIn(58) & DataIn(59) & DataIn(60) & DataIn(61) & 
                 DataIn(62) & DataIn(63) &                  
                 
                 CheckIn(6) & CheckIn(5) & CheckIn(4) & CheckIn(3) & CheckIn(2) &
                 CheckIn(1) & CheckIn(0) & CheckIn(7);
                 
                 
    Parity_chk7_1 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk7(0 to 5),       -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk7_1(0));              -- [out std_logic]
    
    Parity_chk7_2 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk7(6 to 11),      -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk7_1(1));              -- [out std_logic]
    
    Parity_chk7_3 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk7(12 to 17),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk7_1(2));              -- [out std_logic]
    
    Parity_chk7_4 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 7)
      port map (
        InA => data_chk7(18 to 24),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk7_1(3));              -- [out std_logic]
    
    Parity_chk7_5 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 7)
      port map (
        InA => data_chk7(25 to 31),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk7_1(4));              -- [out std_logic]
    
    Parity_chk7_6 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 7)
      port map (
        InA => data_chk7(32 to 38),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk7_1(5));              -- [out std_logic]
        
    Parity_chk7_7 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk7(39 to 44),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk7_1(6));              -- [out std_logic]

    Parity_chk7_8 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk7(45 to 50),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk7_1(7));              -- [out std_logic]

    Parity_chk7_9 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk7(51 to 56),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk7_1(8));              -- [out std_logic]

    Parity_chk7_10 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk7(57 to 62),     -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk7_1(9));              -- [out std_logic]

    Parity_chk7_11 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
      port map (
        InA => data_chk7(63 to 68),         -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk7_1(10));                 -- [out std_logic]

    Parity_chk7_12 : Parity
      generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 3)
      port map (
        InA => data_chk7(69 to 71),         -- [in  std_logic_vector(0 to C_SIZE - 1)]
        Res => chk7_1(11));                 -- [out std_logic]
        
        
    -- Unused    
    --     Parity_chk7_13 : Parity
    --       generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    --       port map (
    --         InA => chk7_1 (0 to 5),             -- [in  std_logic_vector(0 to C_SIZE - 1)]
    --         Res => syndrome7_a);                -- [out std_logic]
    --     
    --     
    --     Parity_chk7_14 : Parity
    --       generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
    --       port map (
    --         InA => chk7_1 (6 to 11),             -- [in  std_logic_vector(0 to C_SIZE - 1)]
    --         Res => syndrome7_b);                 -- [out std_logic]

    -- Unused   syndrome_i(7) <= syndrome7_a xor syndrome7_b;
    -- Unused   syndrome_i (7) <= syndrome7_a;

    -- syndrome_i (7) is not used here.  Final XOR stage is done outside this module with Syndrome_7 vector output.
    -- Clean up this statement.
    syndrome_i (7) <= '0';

    -- Unused   syndrome_int_7 <= syndrome7_a xor syndrome7_b;
    -- Unused   Syndrome_7_b <= syndrome7_b;


    Syndrome <= syndrome_i;
    
    -- Bring out seperate output to do final XOR stage on Syndrome (7) after
    -- the pipeline stage.
    Syndrome_7 <= chk7_1 (0 to 11);
    
    
    
    ---------------------------------------------------------------------------
    
    -- With final syndrome registered outside this module for pipeline balancing
    -- Use registered syndrome to generate any error flags.
    -- Use input signal, Syndrome_Chk which is the registered Syndrome used to
    -- correct any single bit errors.
        
    syndrome_0_to_2 <= Syndrome_Chk(0) & Syndrome_Chk(1) & Syndrome_Chk(2);
       
    -- syndrome_3_to_6 <= syndrome_i(3) & syndrome_i(4) & syndrome_i(5) & syndrome_i(6);
    syndrome_3_to_6 <= Syndrome_Chk(3) & Syndrome_Chk(4) & Syndrome_Chk(5) & Syndrome_Chk(6);
    
    syndrome_3_to_6_zero <= '1' when syndrome_3_to_6 = "0000" else '0';
    
    -- Syndrome bits (3:6) can indicate a double bit error if
    -- Syndrome (6) = '1' AND any bits of Syndrome(3:5) are equal to a '1'.
    syndrome_3_to_6_multi <= '1' when (syndrome_3_to_6 = "1111" or      -- 15
                                       syndrome_3_to_6 = "1101" or      -- 13
                                       syndrome_3_to_6 = "1011" or      -- 11
                                       syndrome_3_to_6 = "1001" or      -- 9
                                       syndrome_3_to_6 = "0111" or      -- 7
                                       syndrome_3_to_6 = "0101" or      -- 5
                                       syndrome_3_to_6 = "0011")        -- 3
                             else '0';

    -- A single bit error is detectable if
    -- Syndrome (7) = '1' and a double bit error is not detectable in Syndrome (3:6)
    -- CE <= Enable_ECC and (syndrome_i(7) or CE_Q) when (syndrome_3_to_6_multi = '0')
    -- CE <= Enable_ECC and (syndrome_int_7 or CE_Q) when (syndrome_3_to_6_multi = '0')
    -- CE <= Enable_ECC and (Syndrome_Chk(7) or CE_Q) when (syndrome_3_to_6_multi = '0')
    --       else CE_Q and Enable_ECC;


    -- Ensure that CE flag is only asserted for a single clock cycle (and does not keep
    -- registered output value)
    CE <= (Enable_ECC and Syndrome_Chk(7)) when (syndrome_3_to_6_multi = '0') else '0';




    -- Uncorrectable error if Syndrome(7) = '0' and any other bits are = '1'.
    -- ue_i_0 <= Enable_ECC when (syndrome_3_to_6_zero = '0') or (syndrome_i(0 to 2) /= "000")
    --           else UE_Q and Enable_ECC;

    --      ue_i_0 <= Enable_ECC when (syndrome_3_to_6_zero = '0') or (syndrome_0_to_2 /= "000")
    --                else UE_Q and Enable_ECC;
    --                
    --      ue_i_1 <= Enable_ECC and (syndrome_3_to_6_multi or UE_Q);


    -- Similar edit from CE flag.  Ensure that UE flags are only asserted for a single
    -- clock cycle.  The flags are registered outside this module for detection in
    -- register module.

    ue_i_0 <= Enable_ECC when (syndrome_3_to_6_zero = '0') or (syndrome_0_to_2 /= "000") else '0';
    ue_i_1 <= Enable_ECC and (syndrome_3_to_6_multi);




    Use_LUT6: if (C_USE_LUT6) generate
      UE_MUXF7 : MUXF7
        port map (
          I0 => ue_i_0,
          I1 => ue_i_1,
--          S  => syndrome_i(7),
--          S  => syndrome_int_7,
          S  => Syndrome_Chk(7),
          O  => UE );      
          
    end generate Use_LUT6;

    Use_RTL: if (not C_USE_LUT6) generate
    -- bit 6 in 32-bit ECC
    -- bit 7 in 64-bit ECC
--      UE <= ue_i_1 when syndrome_i(7) = '1' else ue_i_0;
--      UE <= ue_i_1 when syndrome_int_7 = '1' else ue_i_0;
      UE <= ue_i_1 when Syndrome_Chk(7) = '1' else ue_i_0;
    end generate Use_RTL;
    
    
  end generate Decode_Bits;

end architecture IMP;
