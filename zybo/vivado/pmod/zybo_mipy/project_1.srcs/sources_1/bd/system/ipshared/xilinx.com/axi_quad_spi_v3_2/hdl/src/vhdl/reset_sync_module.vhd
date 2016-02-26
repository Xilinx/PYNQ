-------------------------------------------------------------------------------
-- reset_sync_module.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- *******************************************************************
-- ** (c) Copyright [2010] - [2012] Xilinx, Inc. All rights reserved.*
-- **                                                                *
-- ** This file contains confidential and proprietary information    *
-- ** of Xilinx, Inc. and is protected under U.S. and                *
-- ** international copyright and other intellectual property        *
-- ** laws.                                                          *
-- **                                                                *
-- ** DISCLAIMER                                                     *
-- ** This disclaimer is not a license and does not grant any        *
-- ** rights to the materials distributed herewith. Except as        *
-- ** otherwise provided in a valid license issued to you by         *
-- ** Xilinx, and to the maximum extent permitted by applicable      *
-- ** law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND        *
-- ** WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES    *
-- ** AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING      *
-- ** BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-         *
-- ** INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and       *
-- ** (2) Xilinx shall not be liable (whether in contract or tort,   *
-- ** including negligence, or under any other theory of             *
-- ** liability) for any loss or damage of any kind or nature        *
-- ** related to, arising under or in connection with these          *
-- ** materials, including for any direct, or any indirect,          *
-- ** special, incidental, or consequential loss or damage           *
-- ** (including loss of data, profits, goodwill, or any type of     *
-- ** loss or damage suffered as a result of any action brought      *
-- ** by a third party) even if such damage or loss was              *
-- ** reasonably foreseeable or Xilinx had been advised of the       *
-- ** possibility of the same.                                       *
-- **                                                                *
-- ** CRITICAL APPLICATIONS                                          *
-- ** Xilinx products are not designed or intended to be fail-       *
-- ** safe, or for use in any application requiring fail-safe        *
-- ** performance, such as life-support or safety devices or         *
-- ** systems, Class III medical devices, nuclear facilities,        *
-- ** applications related to the deployment of airbags, or any      *
-- ** other applications that could lead to death, personal          *
-- ** injury, or severe property or environmental damage             *
-- ** (individually and collectively, "Critical                      *
-- ** Applications"). Customer assumes the sole risk and             *
-- ** liability of any use of Xilinx products in Critical            *
-- ** Applications, subject only to applicable laws and              *
-- ** regulations governing limitations on product liability.        *
-- **                                                                *
-- ** THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS       *
-- ** PART OF THIS FILE AT ALL TIMES.                                *
-- *******************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        reset_sync_module.vhd
-- Version:         v3.0
-- Description:     This is the reset sync module.
--
-- VHDL-Standard:   VHDL'93
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
-------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_arith.conv_std_logic_vector;
    use ieee.std_logic_arith.all;
    use ieee.std_logic_signed.all;
    use ieee.std_logic_misc.all;
-- library unsigned is used for overloading of "=" which allows integer to
-- be compared to std_logic_vector
    use ieee.std_logic_unsigned.all;


library axi_lite_ipif_v3_0_3;
    use axi_lite_ipif_v3_0_3.axi_lite_ipif;
    use axi_lite_ipif_v3_0_3.ipif_pkg.all;

library axi_quad_spi_v3_2_5;
    use axi_quad_spi_v3_2_5.all;
library unisim;
    use unisim.vcomponents.FDR;
-------------------------------------------------------------------------------
entity reset_sync_module is
--generic();
port(EXT_SPI_CLK       : in std_logic;
     Soft_Reset_frm_axi: in std_logic;
     Rst_to_spi        : out std_logic
);
end entity reset_sync_module;

architecture imp of reset_sync_module is

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

-- signal declaration
signal Soft_Reset_frm_axi_d1 : std_logic;
signal Soft_Reset_frm_axi_d2 : std_logic;
signal Soft_Reset_frm_axi_d3 : std_logic;
attribute ASYNC_REG : string;
attribute ASYNC_REG of RESET_SYNC_AX2S_1     : label is "TRUE";
-----
begin
-----
--RESET_SYNC_FROM_AXI_TO_SPI: process(EXT_SPI_CLK)is
-------
--begin
-------
--     if(EXT_SPI_CLK'event and EXT_SPI_CLK = '1') then
--         Soft_Reset_frm_axi_d1 <= Soft_Reset_frm_axi;
--         Soft_Reset_frm_axi_d2 <= Soft_Reset_frm_axi_d1;
--         Soft_Reset_frm_axi_d3 <= Soft_Reset_frm_axi_d2;
--     end if;
--end process RESET_SYNC_FROM_AXI_TO_SPI;
-----------------------------------------
     RESET_SYNC_AX2S_1: component FDR
                   generic map(INIT => '0' 
                   )port map (
                              Q  => Soft_Reset_frm_axi_d1,
                              C  => EXT_SPI_CLK,
                              D  => Soft_Reset_frm_axi,
                              R  => '0'
                            );
     RESET_SYNC_AX2S_2: component FDR
                   generic map(INIT => '0'
                   )port map (
                              Q  => Soft_Reset_frm_axi_d2,
                              C  => EXT_SPI_CLK,
                              D  => Soft_Reset_frm_axi_d1,
                              R  => '0'
                            );
Rst_to_spi <= Soft_Reset_frm_axi_d2;
---------------------------------------

end architecture imp;
-------------------------------------------------------------------------------
