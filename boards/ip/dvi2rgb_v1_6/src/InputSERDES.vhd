-------------------------------------------------------------------------------
--
-- File: InputSERDES.vhd
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
-- This module instantiates the Xilinx 7-series primitives necessary for
-- de-serializing the TMDS data stream. 
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

entity InputSERDES is
   Generic (
      kIDLY_TapWidth : natural := 5;   -- number of bits for IDELAYE2 tap counter
      kParallelWidth : natural := 10); -- number of parallel bits
   Port (
      PixelClk : in std_logic;   --Recovered TMDS clock x1 (CLKDIV)
      SerialClk : in std_logic;  --Recovered TMDS clock x5 (CLK)
      
      --Encoded serial data
      sDataIn_p : in std_logic;  --TMDS data channel positive
      sDataIn_n : in std_logic;  --TMDS data channel negative
      
      --Encoded parallel data (raw)
      pDataIn : out STD_LOGIC_VECTOR (kParallelWidth-1 downto 0);
      
      --Control for phase alignment
      pBitslip : in STD_LOGIC;   --Bitslip for ISERDESE2
      pIDLY_LD : in STD_LOGIC;   --IDELAYE2 Load
      pIDLY_CE : in STD_LOGIC;   --IDELAYE2 CE
      pIDLY_INC : in STD_LOGIC;  --IDELAYE2 Tap Increment
      pIDLY_CNT : out std_logic_vector(kIDLY_TapWidth-1 downto 0);  --IDELAYE2 Current Tap Count
      
      aRst : in STD_LOGIC
   );
end InputSERDES;

architecture Behavioral of InputSERDES is

signal sDataIn, sDataInDly, icascade1, icascade2, SerialClkInv : std_logic;
signal pDataIn_q : std_logic_vector(13 downto 0); --ISERDESE2 can do 1:14 at most
begin

-- Differential input buffer for TMDS I/O standard 
InputBuffer: IBUFDS
   generic map (
      DIFF_TERM  => FALSE,
      IOSTANDARD => "TMDS_33")
   port map (
      I          => sDataIn_p,
      IB         => sDataIn_n,
      O          => sDataIn);

-- Delay element for phase alignment of serial data
InputDelay: IDELAYE2
   generic map (
      CINVCTRL_SEL           => "FALSE",     -- TRUE, FALSE
      DELAY_SRC              => "IDATAIN",   -- IDATAIN, DATAIN
      HIGH_PERFORMANCE_MODE  => "TRUE",      -- TRUE, FALSE
      IDELAY_TYPE            => "VARIABLE",  -- FIXED, VARIABLE, or VAR_LOADABLE
      IDELAY_VALUE           => 0,           -- 0 to 31
      REFCLK_FREQUENCY       => 200.0,
      PIPE_SEL               => "FALSE",
      SIGNAL_PATTERN         => "DATA")      -- CLOCK, DATA
   port map (
      DATAOUT                => sDataInDly, -- Delayed signal
      DATAIN                 => '0', -- Not used; IDATAIN instead
      C                      => PixelClk, -- Clock for control signals (CE,INC...)
      CE                     => pIDLY_CE,
      INC                    => pIDLY_INC,
      IDATAIN                => sDataIn, -- Driven by IOB
      LD                     => pIDLY_LD,
      REGRST                 => '0', --not used in VARIABLE mode
      LDPIPEEN               => '0',
      CNTVALUEIN             => "00000", --not used in VARIABLE mode
      CNTVALUEOUT            => pIDLY_CNT, -- current tap value
      CINVCTRL               => '0');

--Invert locally for ISERDESE2
SerialClkInv <= not SerialClk;

-- De-serializer, 1:10 (1:5 DDR), master-slave cascaded
DeserializerMaster: ISERDESE2
   generic map (
      DATA_RATE         => "DDR",
      DATA_WIDTH        => kParallelWidth,
      INTERFACE_TYPE    => "NETWORKING", 
      DYN_CLKDIV_INV_EN => "FALSE",
      DYN_CLK_INV_EN    => "FALSE",
      NUM_CE            => 2,
      OFB_USED          => "FALSE",
      IOBDELAY          => "IFD",         -- Use input at DDLY to output the data on Q1-Q6
      SERDES_MODE       => "MASTER")
   port map (
      Q1                => pDataIn_q(0),
      Q2                => pDataIn_q(1),
      Q3                => pDataIn_q(2),
      Q4                => pDataIn_q(3),
      Q5                => pDataIn_q(4),
      Q6                => pDataIn_q(5),
      Q7                => pDataIn_q(6),
      Q8                => pDataIn_q(7),
      SHIFTOUT1         => icascade1, -- Cascade connection to Slave ISERDES
      SHIFTOUT2         => icascade2, -- Cascade connection to Slave ISERDES
      BITSLIP           => pBitslip, -- 1-bit Invoke Bitslip. This can be used with any 
      CE1               => '1', -- 1-bit Clock enable input
      CE2               => '1', -- 1-bit Clock enable input
      CLK               => SerialClk, -- Fast Source Synchronous SERDES clock from BUFIO
      CLKB              => SerialClkInv, -- Locally inverted clock
      CLKDIV            => PixelClk, -- Slow clock driven by BUFR
      CLKDIVP           => '0', --Not used here
      D                 => '0',                                
      DDLY              => sDataInDly, -- 1-bit Input signal from IODELAYE1.
      RST               => aRst, -- 1-bit Asynchronous reset only.
      SHIFTIN1          => '0',
      SHIFTIN2          => '0',
      -- unused connections
      DYNCLKDIVSEL      => '0',
      DYNCLKSEL         => '0',
      OFB               => '0',
      OCLK              => '0',
      OCLKB             => '0',
      O                 => open); -- unregistered output of ISERDESE1

DeserializerSlave: ISERDESE2
   generic map (
      DATA_RATE         => "DDR",
      DATA_WIDTH        => 10,
      INTERFACE_TYPE    => "NETWORKING",
      DYN_CLKDIV_INV_EN => "FALSE",
      DYN_CLK_INV_EN    => "FALSE",
      NUM_CE            => 2,
      OFB_USED          => "FALSE",
      IOBDELAY          => "IFD",                              -- Use input at DDLY to output the data on Q1-Q6
      SERDES_MODE       => "SLAVE")
   port map (
      Q1                => open, --not used in cascaded mode
      Q2                => open, --not used in cascaded mode
      Q3                => pDataIn_q(8),
      Q4                => pDataIn_q(9),
      Q5                => pDataIn_q(10),
      Q6                => pDataIn_q(11),
      Q7                => pDataIn_q(12),
      Q8                => pDataIn_q(13),
      SHIFTOUT1         => open,
      SHIFTOUT2         => open,
      SHIFTIN1          => icascade1, -- Cascade connections from Master ISERDES
      SHIFTIN2          => icascade2,-- Cascade connections from Master ISERDES
      BITSLIP           => pBitslip, -- 1-bit Invoke Bitslip. This can be used with any 
      CE1               => '1', -- 1-bit Clock enable input
      CE2               => '1', -- 1-bit Clock enable input
      CLK               => SerialClk, -- Fast Source Synchronous SERDES clock from BUFIO
      CLKB              => SerialClkInv, -- Locally inverted clock
      CLKDIV            => PixelClk, -- Slow clock driven by BUFR
      CLKDIVP           => '0', --Not used here
      D                 => '0',                                
      DDLY              => '0', -- not used in cascaded Slave mode
      RST               => aRst, -- 1-bit Asynchronous reset only.
      -- unused connections
      DYNCLKDIVSEL      => '0',
      DYNCLKSEL         => '0',
      OFB               => '0',
      OCLK             => '0',
      OCLKB            => '0',
      O                => open); -- unregistered output of ISERDESE1

------------------------------------------------------------- 
-- Concatenate the serdes outputs together. Keep the timesliced
-- bits together, and placing the earliest bits on the right
-- ie, if data comes in 0, 1, 2, 3, 4, 5, 6, 7, ...
-- the output will be 3210, 7654, ...
------------------------------------------------------------- 
SliceISERDES_q: for slice_count in 0 to kParallelWidth-1 generate begin
    --DVI sends least significant bit first 
   -- This places the first data in time on the right
   pDataIn(slice_count) <= pDataIn_q(kParallelWidth-slice_count-1);
end generate SliceISERDES_q;

end Behavioral;
