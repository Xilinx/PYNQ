----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:13:58 12/21/2011 
-- Design Name: 
-- Module Name:    iis_deser - Behavioral 
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity iis_deser is
    Port ( CLK_100MHZ : in  STD_LOGIC;
           SCLK : in  STD_LOGIC;
           LRCLK : in  STD_LOGIC;
           SDATA : in  STD_LOGIC;
           EN : in STD_LOGIC;
           LDATA : out  STD_LOGIC_VECTOR (23 downto 0);
           RDATA : out  STD_LOGIC_VECTOR (23 downto 0);
           VALID : out  STD_LOGIC);
end iis_deser;

architecture Behavioral of iis_deser is

constant bit_cntr_max : std_logic_vector(4 downto 0) := "11000";

type IIS_STATE_TYPE is (RESET, WAIT_LEFT, SKIP_LEFT, READ_LEFT, WAIT_RIGHT, SKIP_RIGHT, READ_RIGHT);

signal start_left : std_logic;
signal start_right : std_logic;
signal bit_rdy : std_logic;

signal sclk_d1 : std_logic := '0';
signal lrclk_d1 : std_logic := '0';

signal bit_cntr : std_logic_vector(4 downto 0) := (others => '0');

signal ldata_reg : std_logic_vector(23 downto 0) := (others => '0');
signal rdata_reg : std_logic_vector(23 downto 0) := (others => '0');
--signal valid_reg : std_logic := '0';

signal iis_state : IIS_STATE_TYPE := RESET;

begin

process(CLK_100MHZ)
begin
  if (rising_edge(CLK_100MHZ)) then
    sclk_d1 <= SCLK;
    lrclk_d1 <= LRCLK;
  end if;
end process;

--Detect falling edge on LRCLK
start_left <= (lrclk_d1 and not(LRCLK));
--Detect rising edge on LRCLK
start_right <= (not(lrclk_d1) and LRCLK);
--Detect rising edge on SCLK
bit_rdy <= (not(sclk_d1) and SCLK);

--Next state logic
next_iis_state_process : process (CLK_100MHZ)
begin
	if (rising_edge(CLK_100MHZ)) then
		case iis_state is 
		when RESET =>
			if (EN = '1') then
				iis_state <= WAIT_LEFT;
			end if;
		when WAIT_LEFT =>
      if (EN = '0') then
				iis_state <= RESET;
			elsif (start_left = '1') then
        iis_state <= SKIP_LEFT;
      end if;
    when SKIP_LEFT =>
      if (EN = '0') then
				iis_state <= RESET;
			elsif (bit_rdy = '1') then
        iis_state <= READ_LEFT;
      end if;
		when READ_LEFT =>
      if (EN = '0') then
				iis_state <= RESET;
			elsif (bit_cntr = bit_cntr_max) then
        iis_state <= WAIT_RIGHT;
      end if;
		when WAIT_RIGHT =>
      if (EN = '0') then
				iis_state <= RESET;
			elsif (start_right = '1') then
        iis_state <= SKIP_RIGHT;
      end if;
    when SKIP_RIGHT =>
      if (EN = '0') then
				iis_state <= RESET;
			elsif (bit_rdy = '1') then
        iis_state <= READ_RIGHT;
      end if;
		when READ_RIGHT =>
      if (EN = '0') then
				iis_state <= RESET;
			elsif (bit_cntr = bit_cntr_max) then
        iis_state <= WAIT_LEFT;
      end if;
		when others=> --should never be reached
			iis_state <= RESET;
		end case;
	end if;
end process;

process (CLK_100MHZ)
begin
	if (rising_edge(CLK_100MHZ)) then
    if (iis_state = READ_RIGHT or iis_state = READ_LEFT) then
      if (bit_rdy = '1') then
        bit_cntr <= bit_cntr + 1;
      end if;
    else 
      bit_cntr <= (others => '0');
    end if;
	end if;
end process;

process (CLK_100MHZ)
begin
	if (rising_edge(CLK_100MHZ)) then
    if (iis_state = RESET) then
      ldata_reg <= (others => '0');
      rdata_reg <= (others => '0');
    else
      if (iis_state = READ_LEFT and bit_rdy = '1') then
        ldata_reg(23 downto 1) <= ldata_reg(22 downto 0);
        ldata_reg(0) <= SDATA;
      end if;
      if (iis_state = READ_RIGHT and bit_rdy = '1') then
        rdata_reg(23 downto 1) <= rdata_reg(22 downto 0);
        rdata_reg(0) <= SDATA;
      end if;
    end if;
  end if;
end process;

--process (CLK_100MHZ)
--begin
--	if (rising_edge(CLK_100MHZ)) then
--    if (iis_state = READ_RIGHT and bit_cntr = bit_cntr_max) then
--      valid_reg <= '1';
--    else 
--      valid_reg <= '0';
--    end if;
--  end if;
--end process;


--!!!TODO:
--Ensure this triggers PWM correctly, It may be causing the data to latch before the last bit is shifted on the Right Channel
VALID <= '1' when (iis_state = READ_RIGHT and bit_cntr = bit_cntr_max) else
         '0';
LDATA <= ldata_reg;
RDATA <= rdata_reg;

end Behavioral;

