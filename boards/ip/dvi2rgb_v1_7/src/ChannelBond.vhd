-------------------------------------------------------------------------------
--
-- File: ChannelBond.vhd
-- Author: Elod Gyorgy
-- Original Project: HDMI input on 7-series Xilinx FPGA
-- Date: 8 October 2014
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
--    This module de-skews data channels relative to each other. TMDS specs
--    allow 0.2 Tcharacter + 1.78ns skew between channels. To re-align the
--    channels all are buffered in FIFOs until a special marker (the beginning
--    of a blanking period) is found on all the channels.
--  
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.DVI_Constants.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ChannelBond is
   Port (
      PixelClk : in std_logic;
      pDataInRaw : in std_logic_vector(9 downto 0);
      pMeVld : in std_logic;
      pOtherChVld : in std_logic_vector(1 downto 0);
      pOtherChRdy : in std_logic_vector(1 downto 0);
      
      pDataInBnd : out std_logic_vector(9 downto 0);
      pMeRdy : out std_logic
      );
end ChannelBond;

architecture Behavioral of ChannelBond is
constant kFIFO_Depth : natural := 32;
type FIFO_t is array (0 to kFIFO_Depth-1) of std_logic_vector(9 downto 0);
signal pFIFO : FIFO_t;
signal pDataFIFO : std_logic_vector(9 downto 0);
signal pRdA, pWrA : natural range 0 to kFIFO_Depth-1;
signal pRdEn : std_logic;
signal pAllVld, pAllVld_q, pMeRdy_int: std_logic;
signal pBlnkBgnFlag, pTokenFlag, pTokenFlag_q, pAllVldBgnFlag : std_logic;
begin

pAllVld <= pMeVld and pOtherChVld(0) and pOtherChVld(1);
pDataInBnd <= pDataFIFO; -- raw data with skew removed
pMeRdy <= pMeRdy_int; -- data is de-skewed and valid

-- The process below should result in a dual-port distributed RAM with registered output
FIFO: process (PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (pAllVld = '1') then -- begin writing in FIFO as soon as all the channels have valid data
         pFIFO(pWrA) <= pDataInRaw;
      end if;
      pDataFIFO <= pFIFO(pRdA); -- register FIFO output
   end if;
end process FIFO;

-- FIFO address counters
FIFO_WrA: process (PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (pAllVld = '1') then
         pWrA <= pWrA + 1;
      else -- when invalid data, go back to the beginning
         pWrA <= 0;
      end if;
   end if;
end process FIFO_WrA;

FIFO_RdA: process (PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (pAllVld = '0') then
         pRdA <= 0;
      elsif (pRdEn = '1') then
         pRdA <= pRdA + 1;
      end if;   
   end if;
end process FIFO_RdA;

DataValidFlag: process(PixelClk)
begin
   if Rising_Edge(PixelClk) then
      pAllVld_q <= pAllVld;
      pAllVldBgnFlag <= not pAllVld_q and pAllVld; -- this flag used below delays enabling read, thus making sure data is written first before being read
   end if;
end process DataValidFlag;

-------------------------------------------------------------------------------
-- Channel bonding is done here:
-- 1 When all the channels have valid data (ie. alignment lock), FIFO is flow-through
-- 2 When marker is found on this channel, FIFO read is paused, thus holding data
-- 3 When all channels report the marker, FIFO read begins again, thus syncing markers  
-------------------------------------------------------------------------------
FIFO_RdEn: process(PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (pAllVld = '0') then
         pRdEn <= '0';
      elsif (pAllVldBgnFlag = '1' or (pMeRdy_int = '1' and pOtherChRdy = "11")) then
         pRdEn <= '1';
      elsif (pBlnkBgnFlag = '1' and not (pMeRdy_int = '1' and pOtherChRdy = "11")) then
         pRdEn <= '0';
      end if; 
   end if;
end process FIFO_RdEn;

-- Detect blanking period begin
TokenDetect: process(PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (pRdEn = '0' or pDataFIFO = kCtlTkn0 or pDataFIFO = kCtlTkn1 or pDataFIFO = kCtlTkn2 or pDataFIFO = kCtlTkn3) then
         pTokenFlag <= '1'; --token flag activates on invalid data, which avoids a BlnkBgn pulse if the valid signal goes up in the middle of a blanking period
      else
         pTokenFlag <= '0';
      end if;
      pTokenFlag_q <= pTokenFlag;
      pBlnkBgnFlag <= not pTokenFlag_q and pTokenFlag;
   end if;
end process TokenDetect;

-- Ready signal when marker is received
IAmReady: process(PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (pAllVld = '0') then -- if not all channels are valid, we are not ready either
         pMeRdy_int <= '0';
      elsif (pBlnkBgnFlag = '1') then
         pMeRdy_int <= '1';
      end if; 
   end if;
end process IAmReady;

end Behavioral;
