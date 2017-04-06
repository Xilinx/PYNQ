-------------------------------------------------------------------------------
--
-- File: TMDS_Decoder.vhd
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
-- This module connects to one TMDS data channel and decodes TMDS data
-- according to DVI specifications. It phase aligns the data channel,
-- deserializes the stream, eliminates skew between data channels and decodes
-- data in the end.
-- sDataIn_p/n -> buffer -> de-serialize -> channel de-skew -> decode -> pData
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

entity TMDS_Decoder is
   Generic (
      kCtlTknCount : natural := 128; --how many subsequent control tokens make a valid blank detection
      kTimeoutMs : natural := 50; --what is the maximum time interval for a blank to be detected
      kRefClkFrqMHz : natural := 200; --what is the RefClk frequency
      kIDLY_TapValuePs : natural := 78; --delay in ps per tap
      kIDLY_TapWidth : natural := 5); --number of bits for IDELAYE2 tap counter
   Port (
      PixelClk : in std_logic;   --Recovered TMDS clock x1 (CLKDIV)
      SerialClk : in std_logic;  --Recovered TMDS clock x5 (CLK)
      RefClk : std_logic;        --200 MHz reference clock
      aRst : in std_logic;       --asynchronous reset; must be reset when PixelClk/SerialClk is not within spec
      
      --Encoded serial data
      sDataIn_p : in std_logic;  --TMDS data channel positive
      sDataIn_n : in std_logic;  --TMDS data channel negative
      
      --Decoded parallel data
      pDataIn : out std_logic_vector(7 downto 0);
      pC0 : out std_logic;
      pC1 : out std_logic;
      pVde : out std_logic;
      
      -- Channel bonding (three data channels in total)
      pOtherChVld : in std_logic_vector(1 downto 0);
      pOtherChRdy : in std_logic_vector(1 downto 0);
      pMeVld : out std_logic;
      pMeRdy : out std_logic;
      
      --Status and debug
      pRst : in std_logic; -- Synchronous reset to restart lock procedure
      pAlignErr : out std_logic; 
      pEyeSize : out STD_LOGIC_VECTOR(kIDLY_TapWidth-1 downto 0));
end TMDS_Decoder;

architecture Behavioral of TMDS_Decoder is
constant kBitslipDelay : natural := 3; --three-period delay after bitslip 
signal pAlignRst, pLockLostRst_n : std_logic; 
signal pBitslipCnt : natural range 0 to kBitslipDelay - 1 := kBitslipDelay - 1; 
signal pDataIn8b : std_logic_vector(7 downto 0);
signal pDataInBnd : std_logic_vector(9 downto 0);
signal pDataInRaw : std_logic_vector(9 downto 0);
signal pMeRdy_int, pAligned, pAlignErr_int, pAlignErr_q, pBitslip : std_logic;
signal pIDLY_LD, pIDLY_CE, pIDLY_INC : std_logic;
signal pIDLY_CNT : std_logic_vector(kIDLY_TapWidth-1 downto 0);
-- Timeout Counter End
constant kTimeoutEnd : natural := kTimeoutMs * 1000 * kRefClkFrqMHz;
signal rTimeoutCnt : natural range 0 to kTimeoutEnd-1;
signal pTimeoutRst, pTimeoutOvf, rTimeoutRst, rTimeoutOvf : std_logic;
begin

-- Deserialization block
InputSERDES_X: entity work.InputSERDES
   generic map (
      kIDLY_TapWidth => kIDLY_TapWidth,
      kParallelWidth => 10 -- TMDS uses 1:10 serialization
      )
   port map (
      PixelClk => PixelClk,
      SerialClk => SerialClk,
      sDataIn_p => sDataIn_p,
      sDataIn_n => sDataIn_n,
      
      --Encoded parallel data (raw)
      pDataIn => pDataInRaw,
      
      --Control for phase alignment
      pBitslip => pBitslip,
      pIDLY_LD => pIDLY_LD,
      pIDLY_CE => pIDLY_CE,
      pIDLY_INC => pIDLY_INC,
      pIDLY_CNT => pIDLY_CNT,
      
      aRst => aRst
   );
-- reset min two period (ISERDESE2 requirement)
-- de-assert synchronously with CLKDIV, min two period (ISERDESE2 requirement)

--The timeout counter runs on RefClk, because it's a fixed frequency we can measure timeout
--independently of the TMDS Clk
--The xTimeoutRst and xTimeoutOvf signals need to be synchronized back-and-forth
TimeoutCounter: process(RefClk)
begin
   if Rising_Edge(RefClk) then
      if (rTimeoutRst = '1') then
         rTimeoutCnt <= 0;
      elsif (rTimeoutOvf = '0') then
         rTimeoutCnt <= rTimeoutCnt + 1;
      end if;
   end if;
end process TimeoutCounter;

rTimeoutOvf <= '0' when rTimeoutCnt /= kTimeoutEnd - 1 else
               '1';

SyncBaseOvf: entity work.SyncBase
   generic map (
      kResetTo => '0',
      kStages => 2) --use double FF synchronizer
   port map (
      aReset => aRst,
      InClk => RefClk,
      iIn => rTimeoutOvf,
      OutClk => PixelClk,
      oOut => pTimeoutOvf);
      
SyncBaseRst: entity work.SyncBase
   generic map (
      kResetTo => '1',
      kStages => 2) --use double FF synchronizer
   port map (
      aReset => aRst,
      InClk => PixelClk,
      iIn => pTimeoutRst,
      OutClk => RefClk,
      oOut => rTimeoutRst);
        
-- Phase alignment controller to lock onto data stream
PhaseAlignX: entity work.PhaseAlign 
   generic map (
      kUseFastAlgorithm => false,   
      kCtlTknCount => kCtlTknCount,
      kIDLY_TapValuePs => kIDLY_TapValuePs,
      kIDLY_TapWidth => kIDLY_TapWidth
   )
   port map (
      pRst => pAlignRst,
      PixelClk => PixelClk,
      pTimeoutOvf => pTimeoutOvf,
      pTimeoutRst => pTimeoutRst,
      pData => pDataInRaw,
      pIDLY_CE => pIDLY_CE,
      pIDLY_INC => pIDLY_INC,
      pIDLY_CNT => pIDLY_CNT,
      pIDLY_LD => pIDLY_LD,
      pAligned => pAligned,
      pError => pAlignErr_int,
      pEyeSize => pEyeSize);

pAlignErr <= pAlignErr_int;
pMeVld <= pAligned;

-- Bitslip when phase alignment exhausted the whole tap range and still no lock
Bitslip: process(PixelClk)
begin
   if Rising_Edge(PixelClk) then
      pAlignErr_q <= pAlignErr_int;
      pBitslip <= not pAlignErr_q and pAlignErr_int; -- single pulse bitslip on failed alignment attempt
   end if;
end process Bitslip;

ResetAlignment: process(PixelClk, aRst)
begin
   if (aRst = '1') then
      pAlignRst <= '1';
   elsif Rising_Edge(PixelClk) then
      if (pRst = '1' or pBitslip = '1') then
         pAlignRst <= '1';
      elsif (pBitslipCnt = 0) then
         pAlignRst <= '0';
      end if;
   end if;
end process ResetAlignment;

-- Reset phase aligment module after bitslip + 3 CLKDIV cycles (ISERDESE2 requirement)
BitslipDelay: process(PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (pBitslip = '1') then
         pBitslipCnt <= kBitslipDelay - 1;
      elsif (pBitslipCnt /= 0) then
         pBitslipCnt <= pBitslipCnt - 1;
      end if;
   end if;
end process BitslipDelay;
   
-- Channel de-skew (bonding)
ChannelBondX: entity work.ChannelBond
   port map (
      PixelClk => PixelClk,
      pDataInRaw => pDataInRaw,
      pMeVld => pAligned,
      pOtherChVld => pOtherChVld,
      pOtherChRdy => pOtherChRdy,      
      pDataInBnd => pDataInBnd,
      pMeRdy => pMeRdy_int);

pMeRdy <= pMeRdy_int;

-- Below performs the 10B-8B decoding function
-- DVI Specification: Section 3.3.3, Figure 3-6, page 31. 
pDataIn8b <=   pDataInBnd(7 downto 0) when pDataInBnd(9) = '0' else
               not pDataInBnd(7 downto 0);
               
TMDS_Decode: process (PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (pMeRdy_int = '1' and pOtherChRdy = "11") then
         pDataIn <= x"00"; --added for VGA-compatibility (blank pixel needed during blanking)
         
         case (pDataInBnd) is
            --Control tokens decode straight to C0, C1 values
            when kCtlTkn0 =>
               pC0 <= '0';
               pC1 <= '0';
               pVde <= '0';
            when kCtlTkn1 =>
               pC0 <= '1';
               pC1 <= '0';
               pVde <= '0';               
            when kCtlTkn2 =>
               pC0 <= '0';
               pC1 <= '1';
               pVde <= '0';
            when kCtlTkn3 =>
               pC0 <= '1';
               pC1 <= '1';
               pVde <= '0';
            --If not control token, it's encoded data
            when others =>
               pVde <= '1'; 
               pDataIn(0) <= pDataIn8b(0);
               for iBit in 1 to 7 loop
                  if (pDataInBnd(8) = '1') then
                     pDataIn(iBit) <= pDataIn8b(iBit) xor pDataIn8b(iBit-1);
                  else
                     pDataIn(iBit) <= pDataIn8b(iBit) xnor pDataIn8b(iBit-1);
                  end if;
               end loop;                           
         end case;
      else --if we are not aligned on all channels, gate outputs
         pC0 <= '0';
         pC1 <= '0';
         pVde <= '0';
         pDataIn <= x"00";
      end if;
   end if;
end process;

end Behavioral;