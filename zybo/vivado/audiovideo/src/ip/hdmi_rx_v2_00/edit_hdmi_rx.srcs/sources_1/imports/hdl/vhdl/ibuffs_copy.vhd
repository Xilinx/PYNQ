----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:53:01 12/10/2012 
-- Design Name: 
-- Module Name:    ibuffs_copy - Behavioral 
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ibuffs_copy is
generic
 (-- width of the data for the system
  sys_w       : integer := 1;
  -- width of the data for the device
  dev_w       : integer := 10);
port
 (
  RESET : in std_logic;
  
  -- From the system into the device
  DATA_IN_FROM_PINS_P     : in    std_logic_vector(sys_w-1 downto 0);
  DATA_IN_FROM_PINS_N     : in    std_logic_vector(sys_w-1 downto 0);
  DATA_IN_TO_DEVICE       : out   std_logic_vector(dev_w-1 downto 0);

-- Input, Output delay control signals
  IN_DELAY_RESET          : in    std_logic;                    -- Active high synchronous reset for input delay
  IN_DELAY_DATA_CE        : in    std_logic_vector(sys_w -1 downto 0);                    -- Enable signal for delay 
  IN_DELAY_DATA_INC       : in    std_logic_vector(sys_w -1 downto 0);                    -- Delay increment (high), decrement (low) signal
  CNTVALUE_O              : out   std_logic_vector(4 downto 0);
  BITSLIP                 : in    std_logic;                    -- Bitslip module is enabled in NETWORKING mode
 
-- Clock and reset signals
  PCLK_X5_IN             : in    std_logic;                    -- Differential fast clock from IOB
  PCLK_X1_IN                : in    std_logic);
--  CLK_DIV_OUT             : out   std_logic);                    -- Slow clock output
end ibuffs_copy;

architecture Behavioral of ibuffs_copy is

  constant clock_enable            : std_logic := '1';
  signal unused : std_logic;
  --signal clk_in_int                : std_logic;
  signal clk_div                   : std_logic;
  signal clk_div_int               : std_logic;
  signal clk_in_int_buf            : std_logic;
  signal clk_in_int_1x : std_logic;
  
  signal CLKFB_NET : std_logic;
  signal clk_div_fb : std_logic;
  signal FBCLK_IN : std_logic;
  signal LOCKED : std_logic;
  signal IO_RESET : std_logic;
  signal IN_DELAY_RESET_INT : std_logic;
  signal DELAY_LOCKED : std_logic;

  -- After the buffer
  signal data_in_from_pins_int     : std_logic;
  -- Between the delay and serdes
  signal data_in_from_pins_delay   : std_logic;
  signal delay_data_busy           : std_logic_vector(sys_w-1 downto 0);
  signal in_delay_ce              : std_logic;
  signal in_delay_inc_dec         : std_logic;
  signal ce_out_uc              : std_logic;
  signal inc_out_uc             : std_logic;
  signal regrst_out_uc          : std_logic;
  constant num_serial_bits         : integer := dev_w/sys_w;
  type serdarr is array (0 to 13) of std_logic_vector(sys_w-1 downto 0);
  -- Array to use intermediately from the serdes to the internal
  --  devices. bus "0" is the leftmost bus
  -- * fills in starting with 0
  signal iserdes_q                 : serdarr := (( others => (others => '0')));
  signal serdesstrobe             : std_logic;
  signal icascade1                : std_logic_vector(sys_w-1 downto 0);
  signal icascade2                : std_logic_vector(sys_w-1 downto 0);
  signal clk_in_int_inv           : std_logic;
  
  signal cntvalue : std_logic_vector(4 downto 0);

  attribute IODELAY_GROUP : string;
  attribute IODELAY_GROUP of idelaye2_bus : label is "ibuffs_group";
  
  attribute KEEP : string;
--  attribute KEEP of data_in_from_pins_delay: signal is "TRUE";
  attribute KEEP of in_delay_ce: signal is "TRUE";
  attribute KEEP of clk_div: signal is "TRUE";
  attribute KEEP of in_delay_inc_dec: signal is "TRUE";
--  attribute KEEP of data_in_from_pins_int: signal is "TRUE";
  attribute KEEP of in_delay_reset_int: signal is "TRUE";
  attribute KEEP of io_reset: signal is "TRUE";
  attribute KEEP of cntvalue: signal is "TRUE";

begin

  in_delay_ce <= IN_DELAY_DATA_CE(0);
  in_delay_inc_dec <= IN_DELAY_DATA_INC(0);

  -- Create the clock logic
--     ibufds_clk_inst : IBUFGDS
--       generic map (
--         IOSTANDARD => "TMDS_33")
--       port map (
--         I          => CLK_IN_P,
--         IB         => CLK_IN_N,
--         O          => clk_in_int);

-- High Speed BUFIO clock buffer
--     bufio_inst : BUFIO
--       port map (
--         O => clk_in_int_buf,
--         I => PCLK_X5_IN);

--     clk_in_int_buf <= PCLK_X5_IN;
         
-- BUFR generates the slow clock
--     clkout_buf_inst : BUFR
--       generic map (
--          SIM_DEVICE => "7SERIES",
--          BUFR_DIVIDE => "1")
--       port map (
--          O           => clk_div,
--          CE          => '1',
--          CLR         => '0',
--          I           => PCLK_X1_IN);
   
--   clk_div <= PCLK_X1_IN;
   
   IO_RESET <= RESET;--'0' when LOCKED = '1' else '1';
   IN_DELAY_RESET_INT <= RESET or IN_DELAY_RESET;--'0' when LOCKED = '1' or IN_DELAY_RESET = '1' else '1';

--   CLK_DIV_OUT <= clk_div; --This is regional clock;
  
  -- We have multiple bits- step over every bit, instantiating the required elements
  --pins: for pin_count in 0 to sys_w-1 generate 
     --attribute IODELAY_GROUP of idelaye2_bus: label is iodelay_group_name;--"ibuffs_group";
  --begin
    -- Instantiate the buffers
    ----------------------------------
    -- Instantiate a buffer for every bit of the data bus
     ibufds_inst : IBUFDS
       generic map (
         DIFF_TERM  => FALSE,             -- Differential termination
         IOSTANDARD => "TMDS_33")
       port map (
         I          => DATA_IN_FROM_PINS_P(0),--  (pin_count),
         IB         => DATA_IN_FROM_PINS_N(0),--  (pin_count),
         O          => data_in_from_pins_int);

    -- Instantiate the delay primitive
    -----------------------------------

     idelaye2_bus : IDELAYE2
       generic map (
         CINVCTRL_SEL           => "FALSE",            -- TRUE, FALSE
         DELAY_SRC              => "IDATAIN",        -- IDATAIN, DATAIN
         HIGH_PERFORMANCE_MODE  => "TRUE",             -- TRUE, FALSE
         IDELAY_TYPE            => "VARIABLE",          -- FIXED, VARIABLE, or VAR_LOADABLE
         IDELAY_VALUE           => 0,                -- 0 to 31
         REFCLK_FREQUENCY       => 200.0,
         PIPE_SEL               => "FALSE",
         SIGNAL_PATTERN         => "DATA"           -- CLOCK, DATA
         )
         port map (
         DATAOUT                => data_in_from_pins_delay,
         DATAIN                 => '0', -- Data from FPGA logic
         C                      => PCLK_X1_IN,
         CE                     => in_delay_ce, --IN_DELAY_DATA_CE,
         INC                    => in_delay_inc_dec, --IN_DELAY_DATA_INC,
         IDATAIN                => data_in_from_pins_int, -- Driven by IOB
         LD                     => IN_DELAY_RESET_INT,
         REGRST                 => IO_RESET,
         LDPIPEEN               => '0',
         CNTVALUEIN             => "00000",
         CNTVALUEOUT            => cntvalue,
         CINVCTRL               => '0'
         );
         
         cntvalue_o <= cntvalue;

     -- Instantiate the serdes primitive
     ----------------------------------

     clk_in_int_inv <= not (PCLK_X5_IN);

     -- declare the iserdes
     iserdese2_master : ISERDESE2
       generic map (
         DATA_RATE         => "DDR",
         DATA_WIDTH        => 10,
         INTERFACE_TYPE    => "NETWORKING", 
         DYN_CLKDIV_INV_EN => "FALSE",
         DYN_CLK_INV_EN    => "FALSE",
         NUM_CE            => 2,
         OFB_USED          => "FALSE",
         IOBDELAY          => "IFD",                              -- Use input at DDLY to output the data on Q1-Q6
         SERDES_MODE       => "MASTER")
       port map (
         Q1                => iserdes_q(0)(0),--(pin_count),
         Q2                => iserdes_q(1)(0),--(pin_count),
         Q3                => iserdes_q(2)(0),--(pin_count),
         Q4                => iserdes_q(3)(0),--(pin_count),
         Q5                => iserdes_q(4)(0),--(pin_count),
         Q6                => iserdes_q(5)(0),--(pin_count),
         Q7                => iserdes_q(6)(0),--(pin_count),
         Q8                => iserdes_q(7)(0),--(pin_count),
         SHIFTOUT1         => icascade1(0),--(pin_count),               -- Cascade connection to Slave ISERDES
         SHIFTOUT2         => icascade2(0),--(pin_count),               -- Cascade connection to Slave ISERDES
         BITSLIP           => BITSLIP,                            -- 1-bit Invoke Bitslip. This can be used with any 
                                                                  -- DATA_WIDTH, cascaded or not.
         CE1               => clock_enable,                       -- 1-bit Clock enable input
         CE2               => clock_enable,                       -- 1-bit Clock enable input
         CLK               => PCLK_X5_IN,                     -- Fast Source Synchronous SERDES clock from BUFIO
         CLKB              => clk_in_int_inv,                     -- Locally inverted clock
         CLKDIV            => PCLK_X1_IN,                            -- Slow clock driven by BUFR
         CLKDIVP           => '0',
         D                 => '0',                                
         DDLY              => data_in_from_pins_delay, -- 1-bit Input signal from IODELAYE1.
         RST               => IO_RESET,                           -- 1-bit Asynchronous reset only.
         SHIFTIN1          => '0',
         SHIFTIN2          => '0',
        -- unused connections
         DYNCLKDIVSEL      => '0',
         DYNCLKSEL         => '0',
         OFB               => '0',
         OCLK              => '0',
         OCLKB             => '0',
         O                 => open);                              -- unregistered output of ISERDESE1

     iserdese2_slave : ISERDESE2
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
         Q1                => open,
         Q2                => open,
         Q3                => iserdes_q(8)(0),--(pin_count),
         Q4                => iserdes_q(9)(0),--(pin_count),
         Q5                => iserdes_q(10)(0),--(pin_count),
         Q6                => iserdes_q(11)(0),--(pin_count),
         Q7                => iserdes_q(12)(0),--(pin_count),
         Q8                => iserdes_q(13)(0),--(pin_count),
         SHIFTOUT1         => open,
         SHIFTOUT2         => open,
         SHIFTIN1          => icascade1(0),--(pin_count),               -- Cascade connections from Master ISERDES
         SHIFTIN2          => icascade2(0),--(pin_count),               -- Cascade connections from Master ISERDES
         BITSLIP           => BITSLIP,                            -- 1-bit Invoke Bitslip. This can be used with any 
                                                                  -- DATA_WIDTH, cascaded or not.
         CE1               => clock_enable,                       -- 1-bit Clock enable input
         CE2               => clock_enable,                       -- 1-bit Clock enable input
         CLK               => PCLK_X5_IN,                     -- Fast source synchronous serdes clock
         CLKB              => clk_in_int_inv,                     -- locally inverted clock
         CLKDIV            => PCLK_X1_IN,                            -- Slow clock sriven by BUFR.
         CLKDIVP           => '0',
         D                 => '0',                                -- Slave ISERDES module. No need to connect D, DDLY
         DDLY              => '0',
         RST               => IO_RESET,                           -- 1-bit Asynchronous reset only.
        -- unused connections
         DYNCLKDIVSEL      => '0',
         DYNCLKSEL         => '0',
         OFB               => '0',
          OCLK             => '0',
          OCLKB            => '0',
          O                => open);                              -- unregistered output of ISERDESE1

     -- Concatenate the serdes outputs together. Keep the timesliced
     --   bits together, and placing the earliest bits on the right
     --   ie, if data comes in 0, 1, 2, 3, 4, 5, 6, 7, ...
     --       the output will be 3210, 7654, ...
     -------------------------------------------------------------

     in_slices: for slice_count in 0 to num_serial_bits-1 generate begin
        -- This places the first data in time on the right
        DATA_IN_TO_DEVICE(slice_count) <=
          iserdes_q(num_serial_bits-slice_count-1)(0);
        -- To place the first data in time on the left, use the
        --   following code, instead
        -- DATA_IN_TO_DEVICE(slice_count) <=
        --   iserdes_q(slice_count);
     end generate in_slices;


  --end generate pins;


     
end Behavioral;
