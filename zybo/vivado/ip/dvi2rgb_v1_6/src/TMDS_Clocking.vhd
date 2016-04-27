-------------------------------------------------------------------------------
--
-- File: TMDS_Clocking.vhd
-- Author: Elod Gyorgy
-- Original Project: HDMI input on 7-series Xilinx FPGA
-- Date: 10 October 2014
--
-------------------------------------------------------------------------------
-- (c) 2014 Copyright Digilent Incorporated
-- All Rights Reserved
-- 
-- This program is free software; distributed under the terms of BSD 3-clause 
-- license ("Revised BSD License", "New BSD License", or "Modified BSD License")
--
-- Redistribution and use in source and binary forms, with or without modification,
-- are permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice, this
--    list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright notice,
--    this list of conditions and the following disclaimer in the documentation
--    and/or other materials provided with the distribution.
-- 3. Neither the name(s) of the above-listed copyright holder(s) nor the names
--    of its contributors may be used to endorse or promote products derived
--    from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-------------------------------------------------------------------------------
--
-- Purpose:
-- This module instantiates all the necessary primitives to obtain a fast
-- serial clock from the TMDS Clock pins to be used for deserializing the TMDS
-- Data channels. Connect this module directly to the top-level TMDS Clock pins
-- and a 200/300 MHz reference clock.
--  
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity TMDS_Clocking is
   Generic (
      kClkRange : natural := 1);  -- MULT_F = kClkRange*5 (choose >=120MHz=1, >=60MHz=2, >=40MHz=3, >=30MHz=4, >=25MHz=5
   Port (
      TMDS_Clk_p : in std_logic;
      TMDS_Clk_n : in std_logic;
      RefClk : in std_logic; -- 200MHz reference clock for IDELAY primitives; independent of DVI_Clk!
      aRst : in std_logic; --asynchronous reset; must be reset when RefClk is not within spec
      SerialClk : out std_logic;
      PixelClk : out std_logic;
      aLocked : out std_logic);
end TMDS_Clocking;

architecture Behavioral of TMDS_Clocking is
constant kDlyRstDelay : natural := 32;
signal aDlyLckd, rDlyRst, rBUFR_Rst, rLockLostRst : std_logic;
signal rDlyRstCnt : natural range 0 to kDlyRstDelay - 1 := kDlyRstDelay - 1;

signal clkfbout_hdmi_clk, CLK_IN_hdmi_clk, CLK_OUT_1x_hdmi_clk, CLK_OUT_5x_hdmi_clk : std_logic;
signal clkout1b_unused, clkout2_unused, clkout2b_unused, clkout3_unused, clkout3b_unused, clkout4_unused, clkout5_unused, clkout6_unused,
drdy_unused, psdone_unused, clkfbstopped_unused, clkinstopped_unused, clkfboutb_unused, clkout0b_unused, clkout1_unused : std_logic;
signal do_unused : std_logic_vector(15 downto 0);
signal LOCKED_int, rRdyRst : std_logic;
signal aMMCM_Locked, rMMCM_Locked_ms, rMMCM_Locked, rMMCM_LckdFallingFlag, rMMCM_LckdRisingFlag : std_logic;
signal rMMCM_Reset_q : std_logic_vector(1 downto 0);
signal rMMCM_Locked_q : std_logic_vector(1 downto 0);

begin

-- We need a reset bridge to use the asynchronous aRst signal to reset our circuitry
-- and decrease the chance of metastability. The signal rLockLostRst can be used as
-- asynchronous reset for any flip-flop in the RefClk domain, since it will be de-asserted
-- synchronously.
LockLostReset: entity work.ResetBridge
   generic map (
      kPolarity => '1')
   port map (
      aRst => aRst,
      OutClk => RefClk,
      oRst => rLockLostRst);

--IDELAYCTRL must be reset after configuration or refclk lost for 52ns(K7), 72ns(A7) at least
ResetIDELAYCTRL: process(rLockLostRst, RefClk)
begin
   if Rising_Edge(RefClk) then
      if (rLockLostRst = '1') then
         rDlyRstCnt <= kDlyRstDelay - 1;
         rDlyRst <= '1';
      elsif (rDlyRstCnt /= 0) then
         rDlyRstCnt <= rDlyRstCnt - 1;
      else
         rDlyRst <= '0';
      end if;
   end if;
end process;
    
IDelayCtrlX: IDELAYCTRL
   port map (
      RDY         => aDlyLckd,
      REFCLK      => RefClk,
      RST         => rDlyRst);   

RdyLostReset: entity work.ResetBridge
   generic map (
      kPolarity => '1')
   port map (
      aRst => not aDlyLckd,
      OutClk => RefClk,
      oRst => rRdyRst);
      
InputBuffer: IBUFDS
   generic map (
      DIFF_TERM => FALSE, -- Differential Termination 
      IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD => "TMDS_33")
   port map
 (
      O => CLK_IN_hdmi_clk,
      I => TMDS_Clk_p,
      IB => TMDS_Clk_n);
      
-- The TMDS Clk channel carries a character-rate frequency reference
-- In a single Clk period a whole character (10 bits) is transmitted
-- on each data channel. For deserialization of data channel a faster,
-- serial clock needs to be generated. In 7-series architecture an
-- ISERDESE2 primitive doing a 10:1 deserialization in DDR mode needs
-- a fast 5x clock and a slow 1x clock. These two clocks are generated
-- below with an MMCME2_ADV and BUFR primitive.
-- Caveats:
-- 1. The primitive uses a multiply-by-5 and divide-by-1 to generate
-- a 5x fast clock.
-- While changes in the frequency of the TMDS Clk are tracked by the
-- MMCM, for some TMDS Clk frequencies the datasheet specs for the VCO
-- frequency limits are not met. In other words, there is no single
-- set of MMCM multiply and divide values that can work for the whole
-- range of resolutions and pixel clock frequencies.
-- For example: MMCM_FVCOMIN = 600 MHz
-- MMCM_FVCOMAX = 1200 MHz for Artix-7 -1 speed grade
-- while FVCO = FIN * MULT_F
-- The TMDS Clk for 720p resolution in 74.25 MHz
-- FVCO = 74.25 * 10 = 742.5 MHz, which is between FVCOMIN and FVCOMAX
-- However, the TMDS Clk for 1080p resolution in 148.5 MHz
-- FVCO = 148.5 * 10 = 1480 MHZ, which is above FVCOMAX
-- In the latter case, MULT_F = 5, DIVIDE_F = 5, DIVIDE = 1 would result
-- in a correct VCO frequency, while still generating 5x and 1x clocks
-- 2. The MMCM+BUFIO+BUFR combination results in the highest possible
-- frequencies. PLLE2_ADV could work only with BUFGs, which limits
-- the maximum achievable frequency. The reason is that only the MMCM
-- has dedicated route to BUFIO.
-- If a PLLE2_ADV with BUFGs are used a second CLKOUTx can be used to
-- generate the 1x clock.
DVI_ClkGenerator: MMCME2_ADV
   generic map
      (BANDWIDTH            => "OPTIMIZED",
      CLKOUT4_CASCADE      => FALSE,
      COMPENSATION         => "ZHOLD",
      STARTUP_WAIT         => FALSE,
      DIVCLK_DIVIDE        => 1,
      CLKFBOUT_MULT_F      => real(kClkRange) * 5.0,
      CLKFBOUT_PHASE       => 0.000,
      CLKFBOUT_USE_FINE_PS => FALSE,
      CLKOUT0_DIVIDE_F     => real(kClkRange) * 1.0,
      CLKOUT0_PHASE        => 0.000,
      CLKOUT0_DUTY_CYCLE   => 0.500,
      CLKOUT0_USE_FINE_PS  => FALSE,
      CLKIN1_PERIOD        => real(kClkRange) * 6.0,
      REF_JITTER1          => 0.010)
   port map
   -- Output clocks
   (
      CLKFBOUT            => clkfbout_hdmi_clk,
      CLKFBOUTB           => clkfboutb_unused,
      CLKOUT0             => CLK_OUT_5x_hdmi_clk,
      CLKOUT0B            => clkout0b_unused,
      CLKOUT1             => clkout1_unused,
      CLKOUT1B            => clkout1b_unused,
      CLKOUT2             => clkout2_unused,
      CLKOUT2B            => clkout2b_unused,
      CLKOUT3             => clkout3_unused,
      CLKOUT3B            => clkout3b_unused,
      CLKOUT4             => clkout4_unused,
      CLKOUT5             => clkout5_unused,
      CLKOUT6             => clkout6_unused,
      -- Input clock control
      CLKFBIN             => clkfbout_hdmi_clk,
      CLKIN1              => CLK_IN_hdmi_clk,
      CLKIN2              => '0',
      -- Tied to always select the primary input clock
      CLKINSEL            => '1',
      -- Ports for dynamic reconfiguration
      DADDR               => (others => '0'),
      DCLK                => '0',
      DEN                 => '0',
      DI                  => (others => '0'),
      DO                  => do_unused,
      DRDY                => drdy_unused,
      DWE                 => '0',
      -- Ports for dynamic phase shift
      PSCLK               => '0',
      PSEN                => '0',
      PSINCDEC            => '0',
      PSDONE              => psdone_unused,
      -- Other control and status signals
      LOCKED              => aMMCM_Locked,
      CLKINSTOPPED        => clkinstopped_unused,
      CLKFBSTOPPED        => clkfbstopped_unused,
      PWRDWN              => '0',
      RST                 => rMMCM_Reset_q(0));

-- 5x fast serial clock
SerialClkBuffer: BUFIO
   port map (
      O => SerialClk, -- 1-bit output: Clock output (connect to I/O clock loads).
      I => CLK_OUT_5x_hdmi_clk  -- 1-bit input: Clock input (connect to an IBUF or BUFMR).
   );
-- 1x slow parallel clock
PixelClkBuffer: BUFR
   generic map (
      BUFR_DIVIDE => "5",   -- Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
      SIM_DEVICE => "7SERIES"  -- Must be set to "7SERIES" 
   )
   port map (
      O => PixelClk,     -- 1-bit output: Clock output port
      CE => '1',   -- 1-bit input: Active high, clock enable (Divided modes only)
      CLR => rBUFR_Rst, -- 1-bit input: Active high, asynchronous clear (Divided modes only)        
      I => CLK_OUT_5x_hdmi_clk      -- 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
   );     
rBUFR_Rst <= rMMCM_LckdRisingFlag; --pulse CLR on BUFR one the clock returns

MMCM_Reset: process(rLockLostRst, RefClk)
begin
   if (rLockLostRst = '1') then
      rMMCM_Reset_q <= (others => '1'); -- MMCM_RSTMINPULSE Minimum Reset Pulse Width 5.00ns = two RefClk periods min
   elsif Rising_Edge(RefClk) then
      if (rMMCM_LckdFallingFlag = '1') then
          rMMCM_Reset_q <= (others => '1');
      else
          rMMCM_Reset_q <= '0' & rMMCM_Reset_q(rMMCM_Reset_q'high downto 1);
      end if;
   end if; 
end process MMCM_Reset;

MMCM_LockSync: entity work.SyncAsync
   port map (
      aReset => '0',
      aIn => aMMCM_Locked,
      OutClk => RefClk,
      oOut => rMMCM_Locked);
      
MMCM_LockedDetect: process(RefClk)
begin
   if Rising_Edge(RefClk) then
      rMMCM_Locked_q <= rMMCM_Locked & rMMCM_Locked_q(1);
      rMMCM_LckdFallingFlag <= rMMCM_Locked_q(1) and not rMMCM_Locked;
      rMMCM_LckdRisingFlag <= not rMMCM_Locked_q(1) and rMMCM_Locked;
   end if;
end process MMCM_LockedDetect;

GlitchFreeLocked: process(rRdyRst, RefClk)
begin
   if (rRdyRst = '1') then
      aLocked <= '0';
   elsif Rising_Edge(RefClk) then
      aLocked <= rMMCM_Locked_q(0);
   end if;
end process GlitchFreeLocked;

end Behavioral;
