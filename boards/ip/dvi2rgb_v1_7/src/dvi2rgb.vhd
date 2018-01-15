-------------------------------------------------------------------------------
--
-- File: dvi2rgb.vhd
-- Author: Elod Gyorgy
-- Original Project: HDMI input on 7-series Xilinx FPGA
-- Date: 24 July 2015
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
-- This module connects to a top level DVI 1.0 sink interface comprised of three
-- TMDS data channels and one TMDS clock channel. It includes the necessary
-- clock infrastructure, deserialization, phase alignment, channel deskew and
-- decode logic. It outputs 24-bit RGB video data along with pixel clock and
-- synchronization signals. 
--  
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.DVI_Constants.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dvi2rgb is
   Generic (
      kEmulateDDC : boolean := true; --will emulate a DDC EEPROM with basic EDID, if set to yes 
      kRstActiveHigh : boolean := true; --true, if active-high; false, if active-low
      kAddBUFG : boolean := true; --true, if PixelClk should be re-buffered with BUFG 
      kClkRange : natural := 2;  -- MULT_F = kClkRange*5 (choose >=120MHz=1, >=60MHz=2, >=40MHz=3)
      kEdidFileName : string := "900p_edid.data";  -- Select EDID file to use
      -- 7-series specific
      kIDLY_TapValuePs : natural := 78; --delay in ps per tap
      kIDLY_TapWidth : natural := 5); --number of bits for IDELAYE2 tap counter   
   Port (
      -- DVI 1.0 TMDS video interface
      TMDS_Clk_p : in std_logic;
      TMDS_Clk_n : in std_logic;
      TMDS_Data_p : in std_logic_vector(2 downto 0);
      TMDS_Data_n : in std_logic_vector(2 downto 0);
      
      -- Auxiliary signals 
      RefClk : in std_logic; --200 MHz reference clock for IDELAYCTRL, reset, lock monitoring etc.
      aRst : in std_logic; --asynchronous reset; must be reset when RefClk is not within spec
      aRst_n : in std_logic; --asynchronous reset; must be reset when RefClk is not within spec
      
      -- Video out
      vid_pData : out std_logic_vector(23 downto 0);
      vid_pVDE : out std_logic;
      vid_pHSync : out std_logic;
      vid_pVSync : out std_logic;
      
      PixelClk : out std_logic; --pixel-clock recovered from the DVI interface
      
      SerialClk : out std_logic; -- advanced use only; 5x PixelClk
      aPixelClkLckd : out std_logic; -- advanced use only; PixelClk and SerialClk stable
      
      -- Optional DDC port
      DDC_SDA_I : in std_logic;
      DDC_SDA_O : out std_logic;
      DDC_SDA_T : out std_logic;
      DDC_SCL_I : in std_logic;
      DDC_SCL_O : out std_logic; 
      DDC_SCL_T : out std_logic;
      
      pRst : in std_logic; -- synchronous reset; will restart locking procedure
      pRst_n : in std_logic -- synchronous reset; will restart locking procedure
   );
end dvi2rgb;

architecture Behavioral of dvi2rgb is
type dataIn_t is array (2 downto 0) of std_logic_vector(7 downto 0);
type eyeSize_t is array (2 downto 0) of std_logic_vector(kIDLY_TapWidth-1 downto 0);
signal aLocked, SerialClk_int, PixelClk_int, pLockLostRst: std_logic;
signal pRdy, pVld, pDE, pAlignErr, pC0, pC1 : std_logic_vector(2 downto 0);
signal pDataIn : dataIn_t;
signal pEyeSize : eyeSize_t;

signal aRst_int, pRst_int : std_logic;

signal pData : std_logic_vector(23 downto 0);
signal pVDE, pHSync, pVSync : std_logic;
-- set KEEP attribute so that synthesis does not optimize this register
-- in case we want to connect it to an inserted ILA debug core
attribute KEEP : string;
attribute KEEP of pEyeSize: signal is "TRUE";
begin

ResetActiveLow: if not kRstActiveHigh generate
   aRst_int <= not aRst_n;
   pRst_int <= not pRst_n;
end generate ResetActiveLow;

ResetActiveHigh: if kRstActiveHigh generate
   aRst_int <= aRst;
   pRst_int <= pRst;
end generate ResetActiveHigh;

-- Clocking infrastructure to obtain a usable fast serial clock and a slow parallel clock
TMDS_ClockingX: entity work.TMDS_Clocking
   generic map (
      kClkRange => kClkRange)
   port map (
      aRst       => aRst_int, 
      RefClk     => RefClk,
      TMDS_Clk_p => TMDS_Clk_p,      
      TMDS_Clk_n => TMDS_Clk_n,

      aLocked    => aLocked,  
      PixelClk   => PixelClk_int, -- slow parallel clock
      SerialClk  => SerialClk_int -- fast serial clock
   );
   
-- We need a reset bridge to use the asynchronous aLocked signal to reset our circuitry
-- and decrease the chance of metastability. The signal pLockLostRst can be used as
-- asynchronous reset for any flip-flop in the PixelClk domain, since it will be de-asserted
-- synchronously.
LockLostReset: entity work.ResetBridge
   generic map (
      kPolarity => '1')
   port map (
      aRst => not aLocked,
      OutClk => PixelClk_int,
      oRst => pLockLostRst);
         
-- Three data channel decoders
DataDecoders: for iCh in 2 downto 0 generate
   DecoderX: entity work.TMDS_Decoder
      generic map (
         kCtlTknCount => kMinTknCntForBlank, --how many subsequent control tokens make a valid blank detection (DVI spec)
         kTimeoutMs => kBlankTimeoutMs, --what is the maximum time interval for a blank to be detected (DVI spec)
         kRefClkFrqMHz => 200, --what is the RefClk frequency
         kIDLY_TapValuePs => kIDLY_TapValuePs, --delay in ps per tap
         kIDLY_TapWidth => kIDLY_TapWidth) --number of bits for IDELAYE2 tap counter   
      port map (
         aRst                    => pLockLostRst,               
         PixelClk                => PixelClk_int,
         SerialClk               => SerialClk_int,   
         RefClk                  => RefClk,          
         pRst                    => pRst_int,
         sDataIn_p               => TMDS_Data_p(iCh),                           
         sDataIn_n               => TMDS_Data_n(iCh),                                       
         pOtherChRdy(1 downto 0) => pRdy((iCh+1) mod 3) & pRdy((iCh+2) mod 3), -- tie channels together for channel de-skew
         pOtherChVld(1 downto 0) => pVld((iCh+1) mod 3) & pVld((iCh+2) mod 3), -- tie channels together for channel de-skew
   
         pAlignErr               => pAlignErr(iCh),             
         pC0                     => pC0(iCh),
         pC1                     => pC1(iCh),                    
         pMeRdy                  => pRdy(iCh),                
         pMeVld                  => pVld(iCh),                
         pVde                    => pDE(iCh),                  
         pDataIn(7 downto 0)     => pDataIn(iCh),   
         pEyeSize                => pEyeSize(iCh)
      );
end generate DataDecoders;

-- RGB Output conform DVI 1.0
-- except that it sends blank pixel during blanking
-- for some reason video_data uses RBG packing
pData(23 downto 16) <= pDataIn(2); -- red is channel 2
pData(7 downto 0) <= pDataIn(1); -- green is channel 1
pData(15 downto 8) <= pDataIn(0); -- blue is channel 0
pHSync <= pC0(0); -- channel 0 carries control signals too
pVSync <= pC1(0); -- channel 0 carries control signals too
pVDE <= pDE(0); -- since channels are aligned, all of them are either active or blanking at once

-- Clock outputs
SerialClk <= SerialClk_int; -- fast 5x pixel clock for advanced use only
aPixelClkLckd <= aLocked;
----------------------------------------------------------------------------------
-- Re-buffer PixelClk with a BUFG so that it can reach the whole device, unlike
-- through a BUFR. Since BUFG introduces a delay on the clock path, pixel data is
-- re-registered here.
----------------------------------------------------------------------------------
GenerateBUFG: if kAddBUFG generate
   ResyncToBUFG_X: entity work.ResyncToBUFG
      port map (
         -- Video in
         piData => pData,
         piVDE => pVDE,
         piHSync => pHSync,
         piVSync => pVSync,
         PixelClkIn => PixelClk_int,
         -- Video out
         poData => vid_pData,
         poVDE => vid_pVDE,
         poHSync => vid_pHSync,
         poVSync => vid_pVSync,
         PixelClkOut => PixelClk
      );
end generate GenerateBUFG;

DontGenerateBUFG: if not kAddBUFG generate
   vid_pData <= pData;
   vid_pVDE <= pVDE;
   vid_pHSync <= pHSync;
   vid_pVSync <= pVSync;
   PixelClk <= PixelClk_int;
end generate DontGenerateBUFG;
                 
----------------------------------------------------------------------------------
-- Optional DDC EEPROM Display Data Channel - Bi-directional (DDC2B)
-- The EDID will be loaded from the file specified below in kInitFileName.
----------------------------------------------------------------------------------
GenerateDDC: if kEmulateDDC generate	
   DDC_EEPROM: entity work.EEPROM_8b
      generic map (
         kSampleClkFreqInMHz => 200,
         kSlaveAddress => "1010000",
         kAddrBits => 7, -- 128 byte EDID 1.x data
         kWritable => false,
         kInitFileName => kEdidFileName) -- name of file containing init values
      port map(
         SampleClk => RefClk,
         sRst => '0',
         aSDA_I => DDC_SDA_I,
         aSDA_O => DDC_SDA_O,
         aSDA_T => DDC_SDA_T,
         aSCL_I => DDC_SCL_I,
         aSCL_O => DDC_SCL_O,
         aSCL_T => DDC_SCL_T);
end generate GenerateDDC;
   
end Behavioral;
