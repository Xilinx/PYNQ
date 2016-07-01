----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:20:51 08/06/2012 
-- Design Name: 
-- Module Name:    iis_ser - Behavioral 
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

entity iis_ser is
Port ( CLK_100MHZ : in  STD_LOGIC; --gbuf clock
           SCLK : in  STD_LOGIC; --logic (not used as clk)
           LRCLK : in  STD_LOGIC; --logic (not used as clk)
           SDATA : out  STD_LOGIC;
           EN : in STD_LOGIC;
           LDATA : in  STD_LOGIC_VECTOR (23 downto 0);
           RDATA : in  STD_LOGIC_VECTOR (23 downto 0));
end iis_ser;

architecture Behavioral of iis_ser is

--bit cntr counts to 25 (not 24) so that it can set sdata to zero after
--the 24th bit has been sent to the receiver
constant bit_cntr_max : std_logic_vector(4 downto 0) := "11001";--25

type IIS_STATE_TYPE is (RESET, WAIT_LEFT, WRITE_LEFT, WAIT_RIGHT, WRITE_RIGHT);

signal start_left : std_logic;
signal start_right : std_logic;
signal write_bit : std_logic;

signal sclk_d1 : std_logic := '0';
signal lrclk_d1 : std_logic := '0';

signal bit_cntr : std_logic_vector(4 downto 0) := (others => '0');

signal ldata_reg : std_logic_vector(23 downto 0) := (others => '0');
signal rdata_reg : std_logic_vector(23 downto 0) := (others => '0');
signal sdata_reg : std_logic := '0';

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
--Detect falling edge on SCLK
write_bit <= (sclk_d1 and not(SCLK));

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
        iis_state <= WRITE_LEFT;
      end if;
		when WRITE_LEFT =>
      if (EN = '0') then
				iis_state <= RESET;
			elsif (bit_cntr = bit_cntr_max) then
        iis_state <= WAIT_RIGHT;
      end if;
		when WAIT_RIGHT =>
      if (EN = '0') then
				iis_state <= RESET;
			elsif (start_right = '1') then
        iis_state <= WRITE_RIGHT;
      end if;
		when WRITE_RIGHT =>
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
    if (iis_state = WRITE_RIGHT or iis_state = WRITE_LEFT) then
      if (write_bit = '1') then
        bit_cntr <= bit_cntr + 1;
      end if;
    else 
      bit_cntr <= (others => '0');
    end if;
	end if;
end process;

data_shift_proc : process (CLK_100MHZ)
begin 
  if (rising_edge(CLK_100MHZ)) then
    if (iis_state = RESET) then
      ldata_reg <= (others => '0');
      rdata_reg <= (others => '0');
    elsif ((iis_state = WAIT_LEFT) and (start_left = '1')) then
      ldata_reg <= LDATA;
      rdata_reg <= RDATA;
    else
      if (iis_state = WRITE_LEFT and write_bit = '1') then
        ldata_reg(23 downto 1) <= ldata_reg(22 downto 0);
        ldata_reg(0) <= '0';
      end if;
      if (iis_state = WRITE_RIGHT and write_bit = '1') then
        rdata_reg(23 downto 1) <= rdata_reg(22 downto 0);
        rdata_reg(0) <= '0';
      end if;
    end if;
  end if;
end process data_shift_proc;

sdata_update_proc : process (CLK_100MHZ)
begin 
  if (rising_edge(CLK_100MHZ)) then
    if (iis_state = RESET) then
      sdata_reg <= '0';
    elsif (iis_state = WRITE_LEFT and write_bit = '1') then
      sdata_reg <= ldata_reg(23);
    elsif (iis_state = WRITE_RIGHT and write_bit = '1') then
      sdata_reg <= rdata_reg(23);
    end if;
  end if;
end process sdata_update_proc;

SDATA <= sdata_reg;

end Behavioral;

