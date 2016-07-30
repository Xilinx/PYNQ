----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:24:14 01/31/2014 
-- Design Name: 
-- Module Name:    pdm_des - Behavioral 
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pdm_des is
   generic(
      C_NR_OF_BITS : integer := 16;
      C_SYS_CLK_FREQ_MHZ : integer := 100;
      C_PDM_FREQ_MHZ : integer range 1 to 3 := 3
   );
   port(
      clk_i : in std_logic;
      rst_i : in std_logic;
      en_i : in std_logic;
      
      done_o : out std_logic;
      data_o : out std_logic_vector(15 downto 0);
      
      -- PDM
      pdm_m_clk_o : out std_logic;
      pdm_m_data_i : in std_logic;
      pdm_lrsel_o : out std_logic
   );
end pdm_des;

architecture Behavioral of pdm_des is

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------
signal cnt_clk : integer range 0 to 127 := 0;
signal clk_int, clk_intt : std_logic := '0';
signal pdm_clk_rising, pdm_clk_falling : std_logic;
signal pdm_tmp : std_logic_vector((C_NR_OF_BITS-1) downto 0);
signal cnt_bits : integer range 0 to 31 := 0;

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------
begin

   -- with L/R Sel tied to GND => output = DATA1 (rising edge)
   pdm_lrsel_o <= '0';

------------------------------------------------------------------------
-- Deserializer
------------------------------------------------------------------------
   -- sample input serial data process
   SHFT_IN: process(clk_i) 
   begin 
      if rising_edge(clk_i) then
         if pdm_clk_rising = '1' then 
            pdm_tmp <= pdm_tmp(C_NR_OF_BITS-2 downto 0) & pdm_m_data_i;
         end if; 
      end if;
   end process SHFT_IN;
   
   -- counter for the number of sampled bits
   CNT: process(clk_i) begin
      if rising_edge(clk_i) then
         if pdm_clk_rising = '1' then
            if cnt_bits = (C_NR_OF_BITS-1) then
               cnt_bits <= 0;
            else
               cnt_bits <= cnt_bits + 1;
            end if;
         end if;
      end if;
   end process CNT;
   
   -- done gen
   process(clk_i) 
   begin
      if rising_edge(clk_i) then
         if pdm_clk_rising = '1' then
            if cnt_bits = (C_NR_OF_BITS-1) then
               done_o <= '1';
               data_o <= pdm_tmp;
            end if;
         else
            done_o <= '0';
         end if;
      end if;
   end process;

------------------------------------------------------------------------
-- slave clock generator
------------------------------------------------------------------------
   CLK_CNT: process(clk_i)
   begin
      if rising_edge(clk_i) then
         if rst_i = '1' or cnt_clk = ((C_SYS_CLK_FREQ_MHZ/(C_PDM_FREQ_MHZ*2))-1) then
            cnt_clk <= 0;
            clk_int <= not clk_int;
         else
            cnt_clk <= cnt_clk + 1;
         end if;
         clk_intt <= clk_int;
      end if;
   end process CLK_CNT;
   
   pdm_m_clk_o <= clk_int;
   pdm_clk_rising <= '1' when clk_int = '1' and clk_intt = '0' and en_i = '1' else '0';
   --pdm_clk_falling <= '1' when cnt_clk = ((clk_div/2)-1) else '0';


end Behavioral;


