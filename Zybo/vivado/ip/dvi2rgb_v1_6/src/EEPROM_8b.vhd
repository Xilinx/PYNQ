-------------------------------------------------------------------------------
--
-- File: EEPROM_8b.vhd
-- Author: Elod Gyorgy
-- Original Project: HDMI input on 7-series Xilinx FPGA
-- Date: 15 October 2014
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
--    This module emulates a generic I2C EEPROM. It is byte-addressable, with
--    a customizable address width (and thus capacity). It can be made writable
--    from I2C or not, in which case all writes are ignored.
--    Providing a file name accessible by the synthesizer will initialize the
--    EEPROM with the default values from the file.
--    An example use case for this module would be a DDC EEPROM, storing EDID
--    (Extended display identification data). The I2C bus bus is compatible
--    with both standard and fast mode.
--  
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity EEPROM_8b is
   Generic (
      kSampleClkFreqInMHz : natural := 100;
      kSlaveAddress : std_logic_vector(7 downto 1) := "1010000";
      kAddrBits : natural range 1 to 8 := 8; -- 2**kAddrBits byte EEPROM capacity
      kWritable : boolean := true; -- is it writable from I2C?
      kInitFileName : string := ""); -- name of file containing init values, leave empty to init with zero
   Port (
      SampleClk : in STD_LOGIC; --at least fSCL*10
      sRst : in std_logic;
      -- two-wire interface
      aSDA_I : in  STD_LOGIC;
      aSDA_O : out  STD_LOGIC;
      aSDA_T : out  STD_LOGIC;
      aSCL_I : in  STD_LOGIC;
      aSCL_O : out  STD_LOGIC;
      aSCL_T : out  STD_LOGIC);
end EEPROM_8b;

architecture Behavioral of EEPROM_8b is
constant kRAM_Width : integer := 8;
type eeprom_t is array (0 to 2**kAddrBits - 1) of std_logic_vector(kRAM_Width-1 downto 0);

impure function InitRamFromFile (ramfilename : in string) return eeprom_t is
file ramfile : text is in ramfilename;
variable ramfileline : line;
variable ram_name	: eeprom_t;
variable bitvec : bit_vector(kRAM_Width-1 downto 0);
variable good : boolean;
begin
   assert good report "Reading EDID data from file " & ramfilename & "." severity NOTE;
   for i in eeprom_t'range loop
      readline (ramfile, ramfileline);
      read (ramfileline, bitvec, good);
      assert good report "Failed to parse EEPROM_8b init file " & ramfilename & "at line " & integer'image(i+1) & "." severity FAILURE;
      ram_name(i) := to_stdlogicvector(bitvec);
   end loop;
   return ram_name;
end function;

impure function init_from_file_or_zeroes(ramfile : string) return eeprom_t is 
begin 
    if ramfile = "" then 
       return (others => (others => '0')); 
    else 
       return InitRamFromFile(ramfile);  
    end if; 
end;

signal eeprom : eeprom_t := init_from_file_or_zeroes(kInitFileName); 
signal aEeprom_out : std_logic_vector(kRAM_Width-1 downto 0);
signal sAddr : natural range 0 to 2**kAddrBits - 1;

type state_type is (stIdle, stRead, stWrite, stRegAddress); 
signal sState, sNstate : state_type;

signal sI2C_DataIn, sI2C_DataOut : std_logic_vector(7 downto 0);
signal sI2C_Stb, sI2C_Done, sI2C_End, sI2C_RdWrn, sWe : std_logic;
begin

-- Instantiate the I2C Slave Transmitter
I2C_SlaveController: entity work.TWI_SlaveCtl
   generic map (
      SLAVE_ADDRESS => kSlaveAddress & '0',
      kSampleClkFreqInMHz => kSampleClkFreqInMHz)
   port map (
      D_I         => sI2C_DataOut,
      D_O         => sI2C_DataIn,
      RD_WRN_O    => sI2C_RdWrn,
      END_O       => sI2C_End,
      DONE_O      => sI2C_Done,
      STB_I       => sI2C_Stb,
      SampleClk   => SampleClk,
      SRST        => sRst,
      --two-wire interface
      SDA_I       => aSDA_I,
      SDA_O       => aSDA_O,
      SDA_T       => aSDA_T,
      SCL_I       => aSCL_I,
      SCL_O       => aSCL_O,
      SCL_T       => aSCL_T);

-- RAM
Writable: if kWritable generate
   EEPROM_RAM: process (SampleClk)
   begin
      if Rising_Edge(SampleClk) then
         if (sWe = '1') then
            eeprom(sAddr) <= sI2C_DataIn;
         end if;
      end if;
   end process EEPROM_RAM;
end generate Writable;

-- ROM/RAM sync output
RegisteredOutput: process (SampleClk)
begin
   if Rising_Edge(SampleClk) then
      sI2C_DataOut <= eeprom(sAddr);
   end if;
end process RegisteredOutput;

RegisterAddress: process (SampleClk)
begin
   if Rising_Edge(SampleClk) then
      if (sI2C_Done = '1') then
         if (sState = stRegAddress) then
            sAddr <= to_integer(resize(unsigned(sI2C_DataIn), kAddrBits));
         elsif (sState = stRead) then
            sAddr <= sAddr + 1;
         end if;
      end if;
   end if;
end process RegisterAddress;
				
--Insert the following in the architecture after the begin keyword
SyncProc: process (SampleClk)
begin
   if Rising_Edge(SampleClk) then
      if (sRst = '1') then
         sState <= stIdle;
      else
         sState <= sNstate;
      end if;   
   end if;
end process SyncProc;
 
--MOORE State-Machine - Outputs based on state only
sI2C_Stb <= '1' when (sState = stRegAddress or sState = stRead or sState = stWrite) else '0';
sWe <= '1' when (sState = stWrite) else '0';

NextStateDecode: process (sState, sI2C_Done, sI2C_End, sI2C_RdWrn)
begin
   --declare default state for next_state to avoid latches
   sNstate <= sState;
   case (sState) is
      when stIdle =>
         if (sI2C_Done = '1') then
            if (sI2C_RdWrn = '1') then
               sNstate <= stRead;
            else
               sNstate <= stRegAddress;
            end if;
         end if;
         
      when stRegAddress =>
         if (sI2C_End = '1') then
            sNstate <= stIdle;
         elsif (sI2C_Done = '1') then
            sNstate <= stWrite;
         end if;
         
      when stWrite =>
         if (sI2C_End = '1') then
            sNstate <= stIdle;
         elsif (sI2C_Done = '1') then
            sNstate <= stWrite;
         end if;
         
      when stRead =>
         if (sI2C_End = '1') then
            sNstate <= stIdle;
         elsif (sI2C_Done = '1') then
            sNstate <= stRead;
         end if;
         
      when others =>
         sNstate <= stIdle;
   end case;      
end process NextStateDecode;

end Behavioral;
