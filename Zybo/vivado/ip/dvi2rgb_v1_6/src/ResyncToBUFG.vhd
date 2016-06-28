-------------------------------------------------------------------------------
--
-- File: ResyncToBUFG.vhd
-- Author: Elod Gyorgy
-- Original Project: HDMI input on 7-series Xilinx FPGA
-- Date: 7 July 2015
--
-------------------------------------------------------------------------------
-- (c) 2015 Copyright Digilent Incorporated
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
-- This module inserts a BUFG on the PixelClk path so that the pixel bus can be
-- routed globally on the device. It also synchronizes data to the new BUFG
-- clock. 
--  
-------------------------------------------------------------------------------



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity ResyncToBUFG is
   Port (
      -- Video in
      piData : in std_logic_vector(23 downto 0);
      piVDE : in std_logic;
      piHSync : in std_logic;
      piVSync : in std_logic;
      PixelClkIn : in std_logic;
      -- Video out
      poData : out std_logic_vector(23 downto 0);
      poVDE : out std_logic;
      poHSync : out std_logic;
      poVSync : out std_logic;
      PixelClkOut : out std_logic
   );
end ResyncToBUFG;

architecture Behavioral of ResyncToBUFG is

signal PixelClkInt : std_logic;

begin
-- Insert BUFG on clock path
InstBUFG: BUFG
   port map (
      O => PixelClkInt, -- 1-bit output: Clock output
      I => PixelClkIn  -- 1-bit input: Clock input
   );
PixelClkOut <= PixelClkInt;

-- Try simple registering
RegisterData: process(PixelClkInt)
begin
   if Rising_Edge(PixelClkInt) then
      poData <= piData;
      poVDE <= piVDE;
      poHSync <= piHSync;
      poVSync <= piVSync; 
   end if;
end process RegisterData;

end Behavioral;
