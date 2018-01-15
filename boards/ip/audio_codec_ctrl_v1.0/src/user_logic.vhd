------------------------------------------------------------------------------
-- user_logic.vhd - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          user_logic.vhd
-- Version:           1.00.a
-- Description:       User logic.
-- Date:              Wed Aug 15 18:20:40 2012 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

-- DO NOT EDIT BELOW THIS LINE --------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- DO NOT EDIT ABOVE THIS LINE --------------------

--USER libraries added here

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_NUM_REG                    -- Number of software accessible registers
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Resetn                -- Bus to IP reset
--   Bus2IP_Data                  -- Bus to IP data bus
--   Bus2IP_BE                    -- Bus to IP byte enables
--   Bus2IP_RdCE                  -- Bus to IP read chip enable
--   Bus2IP_WrCE                  -- Bus to IP write chip enable
--   IP2Bus_Data                  -- IP to Bus data bus
--   IP2Bus_RdAck                 -- IP to Bus read transfer acknowledgement
--   IP2Bus_WrAck                 -- IP to Bus write transfer acknowledgement
--   IP2Bus_Error                 -- IP to Bus error response
------------------------------------------------------------------------------

entity user_logic is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    --USER generics added here
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_NUM_REG                      : integer              := 5;
    C_SLV_DWIDTH                   : integer              := 32
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    BCLK    :  out  STD_LOGIC;
    LRCLK   :  out  STD_LOGIC;
    SDATA_I :  in   STD_LOGIC;
    SDATA_O :  out  STD_LOGIC;
    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk                     : in  std_logic;
    Bus2IP_Resetn                  : in  std_logic;
    Bus2IP_Data                    : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    Bus2IP_BE                      : in  std_logic_vector(C_SLV_DWIDTH/8-1 downto 0);
    Bus2IP_RdCE                    : in  std_logic_vector(C_NUM_REG-1 downto 0);
    Bus2IP_WrCE                    : in  std_logic_vector(C_NUM_REG-1 downto 0);
    IP2Bus_Data                    : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    IP2Bus_RdAck                   : out std_logic;
    IP2Bus_WrAck                   : out std_logic;
    IP2Bus_Error                   : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;

  attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
  attribute SIGIS of Bus2IP_Resetn : signal is "RST";

end entity user_logic;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of user_logic is


  COMPONENT iis_deser
	PORT(
		CLK_100MHZ : IN std_logic;
		SCLK : IN std_logic;
		LRCLK : IN std_logic;
		SDATA : IN std_logic;
		EN : IN std_logic;          
		LDATA : OUT std_logic_vector(23 downto 0);
		RDATA : OUT std_logic_vector(23 downto 0);
		VALID : OUT std_logic
		);
	END COMPONENT;

	COMPONENT iis_ser
	PORT(
		CLK_100MHZ : IN std_logic;
		SCLK : IN std_logic;
		LRCLK : IN std_logic;
		EN : IN std_logic;
		LDATA : IN std_logic_vector(23 downto 0);
		RDATA : IN std_logic_vector(23 downto 0);          
		SDATA : OUT std_logic
		);
	END COMPONENT;
  
  signal clk_cntr : std_logic_vector(10 downto 0) := (others => '0');
  
  --internal logic "clock" signals
  signal sclk_int : std_logic;
  signal lrclk_int : std_logic;
  
  signal en : std_logic;
   
  signal ldata_in : std_logic_vector(23 downto 0);
  signal rdata_in : std_logic_vector(23 downto 0);
  
  signal data_rdy : std_logic;
  
  signal data_rdy_bit : std_logic := '0';

  ------------------------------------------
  -- Signals for user logic slave model s/w accessible register example
  ------------------------------------------
  signal DataRx_L                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal DataRx_R                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal DataTx_L                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal DataTx_R                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal slv_reg4                       : std_logic;
  signal slv_reg_write_sel              : std_logic_vector(4 downto 0);
  signal slv_reg_read_sel               : std_logic_vector(4 downto 0);
  signal slv_ip2bus_data                : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal slv_read_ack                   : std_logic;
  signal slv_write_ack                  : std_logic;
  
  

begin

  en <= '1';

  process(Bus2IP_Clk)
  begin
    if (rising_edge(Bus2IP_Clk)) then
      clk_cntr <= clk_cntr + 1;
    end if;
  end process;

  --sclk = 100MHz / 32 = 3.125 MHz
  sclk_int <= clk_cntr(4);
  --lrclk = 100MHz / 2048 = 48.828125 KHz
  lrclk_int <= clk_cntr(10);
  
  	Inst_iis_deser: iis_deser PORT MAP(
		CLK_100MHZ => Bus2IP_Clk,
		SCLK => sclk_int,
		LRCLK => lrclk_int,
		SDATA => SDATA_I,
		EN => en,
		LDATA => ldata_in,
		RDATA => rdata_in,
		VALID => data_rdy
	);
  
  process(Bus2IP_Clk)
  begin
    if (rising_edge(Bus2IP_Clk)) then
      if (data_rdy = '1') then
        DataRx_L <= x"00" & ldata_in;
        DataRx_R <= x"00" & rdata_in;
      end if;
    end if;
  end process;
  
  	Inst_iis_ser: iis_ser PORT MAP(
		CLK_100MHZ => Bus2IP_Clk,
		SCLK => sclk_int,
		LRCLK => lrclk_int,
		SDATA => SDATA_O,
		EN => en,
		LDATA => DataTx_L(23 downto 0),
		RDATA => DataTx_R(23 downto 0)
	);
  
  LRCLK <= lrclk_int;
  BCLK <= sclk_int;

  ------------------------------------------
  -- Example code to read/write user logic slave model s/w accessible registers
  -- 
  -- Note:
  -- The example code presented here is to show you one way of reading/writing
  -- software accessible registers implemented in the user logic slave model.
  -- Each bit of the Bus2IP_WrCE/Bus2IP_RdCE signals is configured to correspond
  -- to one software accessible register by the top level template. For example,
  -- if you have four 32 bit software accessible registers in the user logic,
  -- you are basically operating on the following memory mapped registers:
  -- 
  --    Bus2IP_WrCE/Bus2IP_RdCE   Memory Mapped Register
  --                     "1000"   C_BASEADDR + 0x0
  --                     "0100"   C_BASEADDR + 0x4
  --                     "0010"   C_BASEADDR + 0x8
  --                     "0001"   C_BASEADDR + 0xC
  -- 
  ------------------------------------------
  slv_reg_write_sel <= Bus2IP_WrCE(4 downto 0);
  slv_reg_read_sel  <= Bus2IP_RdCE(4 downto 0);
  slv_write_ack     <= Bus2IP_WrCE(0) or Bus2IP_WrCE(1) or Bus2IP_WrCE(2) or Bus2IP_WrCE(3) or Bus2IP_WrCE(4);
  slv_read_ack      <= Bus2IP_RdCE(0) or Bus2IP_RdCE(1) or Bus2IP_RdCE(2) or Bus2IP_RdCE(3) or Bus2IP_RdCE(4);

  -- implement slave model software accessible register(s)
  SLAVE_REG_WRITE_PROC : process( Bus2IP_Clk ) is
  begin

    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Resetn = '0' then
        DataTx_L <= (others => '0');
        DataTx_R <= (others => '0');
        data_rdy_bit <= '0';
      else
        case slv_reg_write_sel is
          when "00100" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                DataTx_L(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00010" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                DataTx_R(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00001" =>
             data_rdy_bit <= '0';
          when others =>
             if (data_rdy = '1') then
               data_rdy_bit <= '1';
             end if;  
        end case;
      end if;
    end if;

  end process SLAVE_REG_WRITE_PROC;

  -- implement slave model software accessible register(s) read mux
  SLAVE_REG_READ_PROC : process( slv_reg_read_sel, DataRx_L, DataRx_R, DataTx_L, DataTx_R, data_rdy_bit ) is
  begin

    case slv_reg_read_sel is
      when "10000" => slv_ip2bus_data <= DataRx_L;
      when "01000" => slv_ip2bus_data <= DataRx_R;
      when "00100" => slv_ip2bus_data <= DataTx_L;
      when "00010" => slv_ip2bus_data <= DataTx_R;
      when "00001" => slv_ip2bus_data <= "0000000000000000000000000000000" & data_rdy_bit;
      when others => slv_ip2bus_data <= (others => '0');
    end case;

  end process SLAVE_REG_READ_PROC;

  ------------------------------------------
  -- Example code to drive IP to Bus signals
  ------------------------------------------
  IP2Bus_Data  <= slv_ip2bus_data when slv_read_ack = '1' else
                  (others => '0');

  IP2Bus_WrAck <= slv_write_ack;
  IP2Bus_RdAck <= slv_read_ack;
  IP2Bus_Error <= '0';

end IMP;
