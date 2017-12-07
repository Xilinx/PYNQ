-------------------------------------------------------------------------------
--
-- File: PhaseAlign.vhd
-- Author: Elod Gyorgy
-- Original Project: HDMI input on 7-series Xilinx FPGA
-- Date: 7 October 2014
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
--  This module receives a DVI-encoded stream of 10-bit deserialized words
--  and tries to change the phase of the serial data to shift the sampling
--  event to the middle of the "eye", ie. the part of the bit period where
--  data is stable. Alignment is achieved by incrementing the tap count of
--  the IDELAYE2 primitives, delaying data by kIDLY_TapValuePs in each step.
--  In Artix-7 architecture each tap (step) accounts to 78 ps.
--  Data is considered valid when control tokens are recognized in the
--  stream. Alignment lock is achieved when the middle of the valid eye is
--  found. When this happens, pAligned will go high. If the whole range of 
--  delay values had been exhausted and alignment lock could still not be 
--  achieved, pError will go high. Resetting the module with pRst will
--  restart the alignment process.
--  The port pEyeSize provides an approximation of the width of the
--  eye in units of tap count. The larger the number, the better the signal
--  quality of the DVI stream.
--  Since the IDELAYE2 primitive only allows a fine alignment, the bitslip
--  feature of the ISERDES primitives complements the PhaseAlign module acting
--  as coarse alignment to find the 10-bit word boundary in the data stream.
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.DVI_Constants.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PhaseAlign is
   Generic (
      kUseFastAlgorithm : boolean := false;
      kCtlTknCount : natural := 128; --how many subsequent control tokens make a valid blank detection
      kIDLY_TapValuePs : natural := 78; --delay in ps per tap
      kIDLY_TapWidth : natural := 5); --number of bits for IDELAYE2 tap counter
   Port (
      pRst : in STD_LOGIC;
      pTimeoutOvf : in std_logic;   --50ms timeout expired
      pTimeoutRst : out std_logic;  --reset timeout
      PixelClk : in STD_LOGIC;
      pData : in STD_LOGIC_VECTOR (9 downto 0);
      pIDLY_CE : out STD_LOGIC;
      pIDLY_INC : out STD_LOGIC;
      pIDLY_CNT : in STD_LOGIC_VECTOR (kIDLY_TapWidth-1 downto 0);
      pIDLY_LD : out STD_LOGIC; --load default tap value 
      pAligned : out STD_LOGIC;
      pError : out STD_LOGIC;
      pEyeSize : out STD_LOGIC_VECTOR(kIDLY_TapWidth-1 downto 0));
end PhaseAlign;

architecture Behavioral of PhaseAlign is
-- Control Token Counter
signal pCtlTknCnt : natural range 0 to kCtlTknCount-1;
signal pCtlTknRst, pCtlTknOvf : std_logic;

-- Control Token Detection Pipeline
signal pTkn0Flag, pTkn1Flag, pTkn2Flag, pTkn3Flag : std_logic;
signal pTkn0FlagQ, pTkn1FlagQ, pTkn2FlagQ, pTkn3FlagQ : std_logic;
signal pTknFlag, pTknFlagQ, pBlankBegin : std_logic;
signal pDataQ : std_logic_vector(pData'high downto pData'low);

constant kTapCntEnd : std_logic_vector(pIDLY_CNT'range) := (others => '0');
constant kFastTapCntEnd : std_logic_vector(pIDLY_CNT'range) := std_logic_vector(to_unsigned(20, pIDLY_CNT'length)); -- fast search limit; if token not found in 20 taps, fail earlier and bitslip
signal pIDLY_CNT_Q : std_logic_vector(pIDLY_CNT'range);
signal pDelayOvf, pDelayFastOvf, pDelayCenter : std_logic;

-- IDELAY increment/decrement wait counter
-- CE, INC registered outputs + CNTVALUEOUT registered input + CNTVALUEOUT registered comparison
constant kDelayWaitEnd : natural := 3;
signal pDelayWaitCnt : natural range 0 to kDelayWaitEnd - 1;
signal pDelayWaitRst, pDelayWaitOvf : std_logic;

constant kEyeOpenCntMin : natural := 3;
constant kEyeOpenCntEnough : natural := 16;
signal pEyeOpenCnt : unsigned(kIDLY_TapWidth-1 downto 0);
signal pCenterTap : unsigned(kIDLY_TapWidth downto 0); -- 1 extra bit to increment with 1/2 for every open eye tap
signal pEyeOpenRst, pEyeOpenEn : std_logic;

--Flags
signal pFoundJtrFlag, pFoundEyeFlag : std_logic;
--FSM
--type state_t is (ResetSt, IdleSt, TokenSt, EyeOpenSt, JtrZoneSt, DlyIncSt, DlyTstOvfSt, DlyDecSt, DlyTstCenterSt, AlignedSt, AlignErrorSt);
subtype state_t is std_logic_vector(10 downto 0);
signal pState, pStateNxt : state_t;
-- Ugh, manual state encoding, since Vivado won't tell me the result of automatic encoding; we need this for debugging.
constant ResetSt : state_t :=       "00000000001";
constant IdleSt : state_t :=        "00000000010";
constant TokenSt : state_t :=       "00000000100";
constant EyeOpenSt : state_t :=     "00000001000";
constant JtrZoneSt : state_t :=     "00000010000";
constant DlyIncSt : state_t :=      "00000100000";
constant DlyTstOvfSt : state_t :=   "00001000000";
constant DlyDecSt : state_t :=      "00010000000";
constant DlyTstCenterSt : state_t :="00100000000";
constant AlignedSt : state_t :=     "01000000000";
constant AlignErrorSt : state_t :=  "10000000000";

begin

ControlTokenCounter: process(PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (pCtlTknRst = '1') then
         pCtlTknCnt <= 0;
      else
         pCtlTknCnt <= pCtlTknCnt + 1;
         -- Overflow
         if (pCtlTknCnt = kCtlTknCount - 1) then
            pCtlTknOvf <= '1';
         else
            pCtlTknOvf <= '0';
         end if;         
      end if;
   end if;
end process ControlTokenCounter;

-- Control Token Detection
pTkn0Flag <= '1' when pDataQ = kCtlTkn0 else '0';
pTkn1Flag <= '1' when pDataQ = kCtlTkn1 else '0';
pTkn2Flag <= '1' when pDataQ = kCtlTkn2 else '0';
pTkn3Flag <= '1' when pDataQ = kCtlTkn3 else '0';

-- Register pipeline
ControlTokenDetect: process(PixelClk)
begin
   if Rising_Edge(PixelClk) then
      pDataQ <= pData; -- level 1      
      pTkn0FlagQ <= pTkn0Flag;
      pTkn1FlagQ <= pTkn1Flag;
      pTkn2FlagQ <= pTkn2Flag;
      pTkn3FlagQ <= pTkn3Flag; -- level 2      
      pTknFlag <= pTkn0Flag or pTkn1Flag or pTkn2Flag or pTkn3Flag; -- level 3
      pTknFlagQ <= pTknFlag;
      pBlankBegin <= not pTknFlagQ and pTknFlag; -- level 4
   end if;
end process ControlTokenDetect;

-- Open Eye Width Counter
EyeOpenCnt: process (PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (pEyeOpenRst = '1') then
         pEyeOpenCnt <= (others => '0');
         pCenterTap <= unsigned(pIDLY_CNT_Q) & '1'; -- 1 extra bit for 1/2 increments; start with 1/2
      elsif (pEyeOpenEn = '1') then
         pEyeOpenCnt <= pEyeOpenCnt + 1;
         pCenterTap <= pCenterTap + 1;
      end if;
   end if;
end process EyeOpenCnt;

pEyeSize <= std_logic_vector(pEyeOpenCnt);

-- Tap Delay Overflow
TapDelayCnt: process (PixelClk)
begin
   if Rising_Edge(PixelClk) then
      pIDLY_CNT_Q <= pIDLY_CNT;
      if (pIDLY_CNT_Q = kTapCntEnd) then
         pDelayOvf <= '1';
      else
         pDelayOvf <= '0';
      end if;
      if (pIDLY_CNT_Q = kFastTapCntEnd) then
         pDelayFastOvf <= '1';
      else
         pDelayFastOvf <= '0';
      end if;
   end if;
end process TapDelayCnt;

-- Tap Delay Center
TapDelayCenter: process (PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (unsigned(pIDLY_CNT_Q) = SHIFT_RIGHT(pCenterTap, 1)) then
         pDelayCenter <= '1';
      else
         pDelayCenter <= '0';
      end if;
   end if;
end process TapDelayCenter;

DelayIncWaitCounter: process (PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (pDelayWaitRst = '1') then
         pDelayWaitCnt <= 0;
      else
         pDelayWaitCnt <= pDelayWaitCnt + 1;
         if (pDelayWaitCnt = kDelayWaitEnd - 1) then
            pDelayWaitOvf <= '1';
         else
            pDelayWaitOvf <= '0';
         end if;
      end if;
   end if;
end process DelayIncWaitCounter;

-- FSM
FSM_Sync: process (PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (pRst = '1') then
         pState <= ResetSt;
      else
         pState <= pStateNxt;

      end if;        
   end if;
end process FSM_Sync;

--FSM Outputs
pTimeoutRst <= '0'   when pState = IdleSt or pState = TokenSt else '1';
pCtlTknRst <= '0'    when pState = TokenSt else '1';
pDelayWaitRst <= '0' when pState = DlyTstOvfSt or pState = DlyTstCenterSt else '1';
pEyeOpenRst <= '1'   when pState = ResetSt or (pState = JtrZoneSt and pFoundEyeFlag = '0') else '0';
pEyeOpenEn <= '1'    when pState = EyeOpenSt else '0';

--FSM Registered Outputs
FSM_RegOut: process (PixelClk)
begin
   if Rising_Edge(PixelClk) then
      if (pState = ResetSt) then
         pIDLY_LD <= '1';
      else
         pIDLY_LD <= '0';
      end if;
      
      if (pState = DlyIncSt) then
         pIDLY_INC <= '1';
         pIDLY_CE <= '1';
      elsif (pState = DlyDecSt) then
         pIDLY_INC <= '0';
         pIDLY_CE <= '1';
      else
         pIDLY_CE <= '0';
      end if;
      
      if (pState = AlignedSt) then
         pAligned <= '1';
      else
         pAligned <= '0';
      end if;
      
      if (pState = AlignErrorSt) then
         pError <= '1';
      else
         pError <= '0';
      end if;
   end if;
end process FSM_RegOut;

FSM_Flags: process (PixelClk)
begin
   if Rising_Edge(PixelClk) then
      case (pState) is
         when ResetSt =>
            pFoundEyeFlag <= '0';
            pFoundJtrFlag <= '0';
         when JtrZoneSt =>
            pFoundJtrFlag <= '1';
         when EyeOpenSt =>
         -- We consider the eye found, if we had found jitter before and the eye is at least kEyeOpenCntMin wide OR
         -- We have not seen jitter yet (because tap 0 was already in the eye) and the eye is at least kEyeOpenCntEnough wide
            if ((pFoundJtrFlag = '1' and pEyeOpenCnt = kEyeOpenCntMin) or (pEyeOpenCnt = kEyeOpenCntEnough)) then
               pFoundEyeFlag <= '1';
            end if;
         when others =>
      end case;
   end if;
end process FSM_Flags;

FSM_NextState: process (pState, pBlankBegin, pTimeoutOvf, pCtlTknOvf, pDelayOvf, pDelayFastOvf, pDelayWaitOvf,
pEyeOpenCnt, pDelayCenter, pFoundEyeFlag, pTknFlagQ)
begin

   pStateNxt <= pState;  --default is to stay in current state

   case (pState) is
      when ResetSt =>
         pStateNxt <= IdleSt;
      
      when IdleSt => -- waiting for a token with timeout
         if (pBlankBegin = '1') then
            pStateNxt <= TokenSt;
         elsif (pTimeoutOvf = '1') then
            pStateNxt <= JtrZoneSt; -- we didn't find a proper blank, must be in jitter zone
         end if;
         
      when TokenSt => -- waiting for kCtlTknCount tokens with timeout
         if (pTknFlagQ = '0') then
            pStateNxt <= IdleSt;
         elsif (pCtlTknOvf = '1') then
            pStateNxt <= EyeOpenSt;
         end if;
      
      when JtrZoneSt =>
         if (pFoundEyeFlag = '1') then
            pStateNxt <= DlyDecSt; -- this jitter zone ends an open eye, go back to the middle of the eye
         elsif (kUseFastAlgorithm and pDelayFastOvf = '1' and pFoundEyeFlag = '0') then
            pStateNxt <= AlignErrorSt; 
         else
            pStateNxt <= DlyIncSt;
         end if;
               
      when EyeOpenSt =>
         -- If our eye is already kEyeOpenCntEnough wide, consider the search finished and consider the current tap value
         -- the end of our eye = jitter zone
         if (pEyeOpenCnt = kEyeOpenCntEnough) then
            pStateNxt <= JtrZoneSt;
         else
            pStateNxt <= DlyIncSt;
         end if;
      
      when DlyIncSt =>
         pStateNxt <= DlyTstOvfSt;
     
      when DlyTstOvfSt =>
         if (pDelayWaitOvf = '1') then
            if (pDelayOvf = '1') then
               pStateNxt <= AlignErrorSt; -- we went through all the delay taps
            else
               pStateNxt <= IdleSt;
            end if;
         end if;
      
      when DlyDecSt =>
         pStateNxt <= DlyTstCenterSt;
      
      when DlyTstCenterSt =>
         if (pDelayWaitOvf = '1') then
            if (pDelayCenter = '1') then
               pStateNxt <= AlignedSt; -- we went back to the center of the eye, done
            else
               pStateNxt <= DlyDecSt;
            end if;
         end if;
      
      when AlignedSt =>
         null; --stay here
         
      when AlignErrorSt =>
         null; --stay here
                
      when others =>
         pStateNxt <= ResetSt;
   end case;      
end process FSM_NextState;

end Behavioral;
