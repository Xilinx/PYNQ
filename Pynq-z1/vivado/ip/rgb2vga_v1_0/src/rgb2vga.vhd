-------------------------------------------------------------------------------
--
-- File: rgb2vga.vhd
-- Author: Elod Gyorgy
-- Original Project: Genesys 2 demo project
-- Date: 20 March 2015
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
-- To provide a properly blanked vga signal from an rgb interface
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

entity rgb2vga is
   Generic (
      VID_IN_DATA_WIDTH : natural := 24;
      kRedDepth : natural := 5;
      kGreenDepth : natural := 6;
      kBlueDepth : natural := 5
   );
   Port (
      rgb_pData : in std_logic_vector(VID_IN_DATA_WIDTH-1 downto 0);
      rgb_pVDE : in std_logic;
      rgb_pHSync : in std_logic;
      rgb_pVSync : in std_logic;
      
      PixelClk : in std_logic; --pixel clock
      
      vga_pRed : out std_logic_vector(kRedDepth-1 downto 0);
      vga_pGreen : out std_logic_vector(kGreenDepth-1 downto 0);
      vga_pBlue : out std_logic_vector(kBlueDepth-1 downto 0);
      vga_pHSync : out std_logic;
      vga_pVSync : out std_logic
   );
end rgb2vga;

architecture Behavioral of rgb2vga is
signal int_pData : std_logic_vector(VID_IN_DATA_WIDTH-1 downto 0);

begin

Blanking: process(PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (rgb_pVDE = '1') then
         int_pData <= rgb_pData;
      else
         int_pData <= (others => '0');
      end if;
      
      vga_pHSync <= rgb_pHSync;
      vga_pVSync <= rgb_pVSync;
   end if;
end process Blanking;

vga_pRed <= int_pData(VID_IN_DATA_WIDTH-1 downto VID_IN_DATA_WIDTH - kRedDepth);
vga_pBlue <= int_pData(VID_IN_DATA_WIDTH/3*2-1 downto VID_IN_DATA_WIDTH/3*2 - kBlueDepth);
vga_pGreen <= int_pData(VID_IN_DATA_WIDTH/3-1 downto VID_IN_DATA_WIDTH/3 - kGreenDepth); 


end Behavioral;
