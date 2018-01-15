-------------------------------------------------------------------------------
--
-- File: TWI_SlaveCtl.vhd
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
--    This module is a two-wire (I2C compatible) slave controller responding
--    to the address defined in SLAVE_ADDRESS. It samples the bus and
--    deserializes data. The module needs to be controlled in turn by a
--    high-level controller.
--    Status signals:
--       DONE_O   active-high pulsed when the slave is addressed by a master,
--                or when a data byte is either sent or received
--       END_O    active-high pulsed when the master ended the transfer
--       RD_WRN_O high when transfer is read, low when write
--    Control signals:
--       STB_I    needs to be held high when the current byte needs to be
--                acknowledged; this is the case for the device address, as
--                well as every byte written to-slave
--       D_I      data needs to be provided on this bus when read transaction
--                occurs; needs to be held until DONE_O
--       D_O      data will appear on D_O when a write transaction occurs;
--                valid on DONE_O 
--  
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity TWI_SlaveCtl is
   generic (
      SLAVE_ADDRESS : std_logic_vector(7 downto 0) := x"A0"; -- TWI Slave address
      kSampleClkFreqInMHz : natural := 100
      );
    Port ( D_I : in  STD_LOGIC_VECTOR (7 downto 0);
           D_O : out  STD_LOGIC_VECTOR (7 downto 0);
           RD_WRN_O : out  STD_LOGIC;
			  END_O : out STD_LOGIC;
           DONE_O : out  STD_LOGIC;
           STB_I : in  STD_LOGIC;
           SampleClk : in  STD_LOGIC;
           SRST : in  STD_LOGIC;
           --two-wire bus
           SDA_I : in  STD_LOGIC;
           SDA_O : out  STD_LOGIC;
           SDA_T : out  STD_LOGIC;
           SCL_I : in  STD_LOGIC;
           SCL_O : out  STD_LOGIC;
           SCL_T : out  STD_LOGIC
           );
end TWI_SlaveCtl;

architecture Behavioral of TWI_SlaveCtl is
   constant kGlitchDurationInNs : natural := 50; --tSP in I2C specs
   constant kNoOfPeriodsToFilter : natural := natural(ceil(real(kGlitchDurationInNs * kSampleClkFreqInMHz) / 1000.0));
	attribute fsm_encoding: string;
   type state_type is (stIdle, stAddress, stRead, stWrite, stSAck, stMAck, stTurnAround); 
   signal state, nstate : state_type;
	attribute fsm_encoding of state: signal is "gray";	
	
	signal dSda, ddSda, dScl, ddScl : std_logic;
	signal fStart, fStop, fSCLFalling, fSCLRising : std_logic;
	signal dataByte : std_logic_vector(7 downto 0); --shift register and parallel load
	signal iEnd, iDone, latchData, dataBitOut, shiftBitIn, shiftBitOut : std_logic;
	signal rd_wrn, drive : std_logic;
	signal bitCount : natural range 0 to 7 := 7;
	signal sSda, sScl, sSdaFtr, sSclFtr : std_logic;
begin

-- Synchronize SDA and SCL inputs
SyncSDA: entity work.SyncAsync
   generic map (
      kResetTo => '1',
      kStages => 2)
   port map (
      aReset => '0',
      aIn => SDA_I,
      OutClk => SampleClk,
      oOut => sSda);
SyncSCL: entity work.SyncAsync
   generic map (
      kResetTo => '1',
      kStages => 2)
   port map (
      aReset => '0',
      aIn => SCL_I,
      OutClk => SampleClk,
      oOut => sScl);
         
-- Glitch filter as required by I2C Fast-mode specs
GlitchF_SDA: entity work.GlitchFilter
   Generic map (kNoOfPeriodsToFilter)
   Port map (
      SampleClk => SampleClk,
      sIn => sSda,
      sOut => sSdaFtr,
      sRst => SRST);
GlitchF_SCL: entity work.GlitchFilter
      Generic map (kNoOfPeriodsToFilter)
      Port map (
         SampleClk => SampleClk,
         sIn => sScl,
         sOut => sSclFtr,
         sRst => SRST);
         
----------------------------------------------------------------------------------                  
--Bus State detection
----------------------------------------------------------------------------------
EdgeDetect: process(SampleClk)
   begin
      if Rising_Edge(SampleClk) then
			dSda <= sSdaFtr;
			ddSda <= dSda;
			dScl <= sSclFtr;
			ddScl <= dScl;
      end if;
   end process;
	
	fStart <= dSCL and not dSda and ddSda; --if SCL high while SDA falling, start condition
	fStop <= dSCL and dSda and not ddSda; --if SCL high while SDA rising, stop condition
	
	fSCLFalling <= ddSCL and not dScl; -- SCL falling
	fSCLRising <= not ddSCL and dScl; -- SCL rising
	
----------------------------------------------------------------------------------
-- Open-drain outputs for bi-directional SDA and SCL
---------------------------------------------------------------------------------- 
   SDA_T <= '1' when dataBitOut = '1' or drive = '0' else -- high-Z
            '0'; --drive
   SDA_O <= '0';
   
   SCL_T <= '1'; -- input 4eva
   SCL_O <= '0';

----------------------------------------------------------------------------------
-- Title: Data byte shift register
-- Description: Stores the byte to be written or the byte read depending on the
-- transfer direction.
----------------------------------------------------------------------------------	
DATABYTE_SHREG: process (SampleClk) 
	begin
		if Rising_Edge(SampleClk) then
			if ((latchData = '1' and fSCLFalling = '1') or state = stIdle or fStart = '1') then
				dataByte <= D_I; --latch data
				bitCount <= 7;
			elsif (shiftBitOut = '1' and fSCLFalling = '1') then
				dataByte <= dataByte(dataByte'high-1 downto 0) & dSDA;
				bitCount <= bitCount - 1;
			elsif (shiftBitIn = '1' and fSCLRising = '1') then
				dataByte <= dataByte(dataByte'high-1 downto 0) & dSDA;
				bitCount <= bitCount - 1;
			end if;
		end if;
	end process;

	dataBitOut <= 	'0' when state = stSAck else
						dataByte(dataByte'high);
	D_O <= dataByte;
	RD_WRN_O <= rd_wrn;
	
RDWRN_BIT_REG: process (SampleClk) 
	begin
		if Rising_Edge(SampleClk) then
			if (state = stAddress and bitCount = 0 and fSCLRising = '1') then
				rd_wrn <= dSDA;
			end if;
		end if;
	end process;
	
SYNC_PROC: process (SampleClk)
   begin
      if Rising_Edge(SampleClk) then
         state <= nstate;
			END_O <= iEnd;
			DONE_O <= iDone;
      end if;
   end process;
	
OUTPUT_DECODE: process (nstate, state, fSCLRising, fSCLFalling, ddSDA, bitCount, rd_wrn, dataByte, fStop, fStart)
   begin
		iDone <= '0';
		iEnd <= '0';
		shiftBitIn <= '0';
		shiftBitOut <= '0';
		latchData <= '0';
		drive <= '0';
		
		if (state = stRead or state = stSAck) then
			drive <= '1';
		end if;
		
		if (state = stAddress or state = stWrite) then
			shiftBitIn <= '1';
		end if;
		
		if (state = stRead) then
			shiftBitOut <= '1';
		end if;
			
		if ((state = stSAck and rd_wrn = '1') or
			(state = stMAck and ddSda = '0')) then --get the data byte for the next read
			latchData <= '1';
		end if;
		
		if ((state = stAddress and bitCount = 0 and fSCLRising = '1' and dataByte(6 downto 0) = SLAVE_ADDRESS(7 downto 1)) or
			(state = stWrite and bitCount = 0 and fSCLRising = '1') or
			(state = stRead and bitCount = 0 and fSCLFalling = '1')) then
			iDone <= '1';
		end if;
		
		if (fStop = '1' or fStart = '1' or
			(state = stMAck and fSCLRising = '1' and ddSDA = '1')) then
			iEnd <= '1';
		end if;
		
	end process;
	
NEXT_STATE_DECODE: process (state, fStart, STB_I, fSCLRising, fSCLFalling, bitCount, ddSDA, rd_wrn, dataByte, fStop)
   begin
      
      nstate <= state;  --default is to stay in current state
   
      case (state) is
         when stIdle =>
            if (fStart = '1') then -- start condition received
               nstate <= stAddress;
            end if;
				
         when stAddress =>
            if (fStop = '1') then
					nstate <= stIdle;
				elsif (bitCount = 0 and fSCLRising = '1') then
					if (dataByte(6 downto 0) = SLAVE_ADDRESS(7 downto 1)) then
						nstate <= stTurnAround;
					else
						nstate <= stIdle;
					end if;
				end if;
				
			when stTurnAround =>
				if (fStop = '1') then
					nstate <= stIdle;
				elsif (fStart = '1') then
					nstate <= stAddress;
				elsif (fSCLFalling = '1') then
					if (STB_I = '1') then
						nstate <= stSAck; --we acknowledge and continue
					else
						nstate <= stIdle; --don't ack and stop
					end if;
				end if;
			
			when stSAck =>
				if (fStop = '1') then
					nstate <= stIdle;
				elsif (fStart = '1') then
					nstate <= stAddress;
				elsif fSCLFalling = '1' then
					if (rd_wrn = '1') then
						nstate <= stRead;
					else
						nstate <= stWrite;
					end if;
				end if;
				
			when stWrite =>
				if (fStop = '1') then
					nstate <= stIdle;
				elsif (fStart = '1') then
					nstate <= stAddress;					
				elsif (bitCount = 0 and fSCLRising = '1') then
					nstate <= stTurnAround;
				end if;
							
         when stMAck =>
				if (fStop = '1') then
					nstate <= stIdle;
				elsif (fStart = '1') then
					nstate <= stAddress;					
				elsif (fSCLFalling = '1') then
					if (ddSDA = '1') then
						nstate <= stIdle;
					else
						nstate <= stRead;
					end if;
				end if;
			
			when stRead =>
				if (fStop = '1') then
					nstate <= stIdle;
				elsif (fStart = '1') then
					nstate <= stAddress;					
				elsif (bitCount = 0 and fSCLFalling = '1') then
					nstate <= stMAck;
				end if;
							
         when others =>
            nstate <= stIdle;
      end case;      
   end process;

end Behavioral;

