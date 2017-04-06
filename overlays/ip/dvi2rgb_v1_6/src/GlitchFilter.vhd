-------------------------------------------------------------------------------
--
-- File: GlitchFilter.vhd
-- Author: Elod Gyorgy
-- Original Project: HDMI input on 7-series Xilinx FPGA
-- Date: 22 October 2014
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
--    This module filters any pulses on sIn lasting less than the number of
--    periods specified in kNoOfPeriodsToFilter. The output sOut will be
--    delayed by kNoOfPeriodsToFilter cycles, but glitch-free.
--  
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GlitchFilter is
   Generic (
      kNoOfPeriodsToFilter : natural);
   Port (
      SampleClk : in STD_LOGIC;
      sIn : in STD_LOGIC;
      sOut : out STD_LOGIC;
      sRst : in STD_LOGIC);
end GlitchFilter;

architecture Behavioral of GlitchFilter is
signal cntPeriods : natural range 0 to kNoOfPeriodsToFilter - 1 := kNoOfPeriodsToFilter - 1;
signal sIn_q : std_logic;
begin

Bypass: if kNoOfPeriodsToFilter = 0 generate
   sOut <= sIn; 
end generate Bypass;

Filter: if kNoOfPeriodsToFilter > 0 generate
   process (SampleClk)
   begin
      if Rising_Edge(SampleClk) then
         sIn_q <= sIn;
         if (cntPeriods = 0) then
            sOut <= sIn_q;
         end if;
      end if;
   end process;
   
   PeriodCounter: process (SampleClk)
   begin
      if Rising_Edge(SampleClk) then
         if (sIn_q /= sIn or sRst = '1') then --edge detected
            cntPeriods <= kNoOfPeriodsToFilter - 1; --reset counter
         elsif (cntPeriods /= 0) then
            cntPeriods <= cntPeriods - 1; --count down
         end if;
      end if;
   end process PeriodCounter;
end generate Filter;

end Behavioral;
