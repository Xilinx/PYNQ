----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:27:09 04/26/2013 
-- Design Name: 
-- Module Name:    TWISlaveCtl - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity TWISlaveCtl is
	 generic (SLAVE_ADDRESS : std_logic_vector(7 downto 0) := x"A0"); -- TWI Slave address
    Port ( D_I : in  STD_LOGIC_VECTOR (7 downto 0);
           D_O : out  STD_LOGIC_VECTOR (7 downto 0);
           RD_WRN_O : out  STD_LOGIC;
			  END_O : out STD_LOGIC;
           DONE_O : out  STD_LOGIC;
           STB_I : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
           SRST : in  STD_LOGIC;
		     SDA_I : in std_logic;
		     SDA_O : out std_logic;
		     SDA_T : out std_logic;
           SCL_I : in  STD_LOGIC);
end TWISlaveCtl;

architecture Behavioral of TWISlaveCtl is
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
begin
----------------------------------------------------------------------------------                  
--Bus State detection
----------------------------------------------------------------------------------
SYNC_FFS: process(CLK)
   begin
      if Rising_Edge(CLK) then
			dSda <= SDA_I;
			ddSda <= dSda;
			dScl <= SCL_I;
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
	SDA_T <= dataBitOut or not(drive);
	SDA_O <= '0';
	
--   SDA <= 'Z' when dataBitOut = '1' or drive = '0' else
--          '0';
   --SCL <= 'Z' when rSCL = '1' else
   --       '0';

----------------------------------------------------------------------------------
-- Title: Data byte shift register
-- Description: Stores the byte to be written or the byte read depending on the
-- transfer direction.
----------------------------------------------------------------------------------	
DATABYTE_SHREG: process (CLK) 
	begin
		if Rising_Edge(CLK) then
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
	
RDWRN_BIT_REG: process (CLK) 
	begin
		if Rising_Edge(CLK) then
			if (state = stAddress and bitCount = 0 and fSCLRising = '1') then
				rd_wrn <= dSDA;
			end if;
		end if;
	end process;
	
SYNC_PROC: process (CLK)
   begin
      if Rising_Edge(CLK) then
         state <= nstate;
			END_O <= iEnd;
			DONE_O <= iDone;
      end if;
   end process;
	
OUTPUT_DECODE: process (nstate, state, fSCLRising, fSCLFalling, ddSDA, bitCount)
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
	
NEXT_STATE_DECODE: process (state, fStart, STB_I, fSCLRising, fSCLFalling, bitCount, ddSDA)
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

