----------------------------------------------------------------------------------
-- Company: Digilent Ro
-- Engineer: Elod Gyorgy
-- 
-- Create Date:    16:14:07 09/20/2013 -- Design Name: 
-- Module Name:    hdmi_rx - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: The desing forwards the HDMI input to the VGA output. The -1 Zynq
-- part supports resolutions of up to 120MHz pixel clock.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - 2013-Sep-20 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity hdmi_rx is
	Port (
		SYSCLK : in STD_LOGIC;
		BTN : in STD_LOGIC;
		
--VGA
		VGA_HS : out std_logic;
		VGA_VS : out std_logic;
		VGA_DE : out std_logic;
		VGA_DATA : out std_logic_vector(23 downto 0);
		
		PXL_CLK : out std_logic;
		PXL_CLK_LOCKED : out std_logic;
		
--HDMI RX
		HDMI_OUT_EN  : out   STD_LOGIC;
		HDMI_HPD     : out   STD_LOGIC;
		HDMI_CLK_P   : in    STD_LOGIC;
		HDMI_CLK_N   : in    STD_LOGIC;
		HDMI_D_P     : in    STD_LOGIC_VECTOR(2 downto 0);
		HDMI_D_N     : in    STD_LOGIC_VECTOR(2 downto 0);
		HDMI_SCL_I   : in    STD_LOGIC;
        HDMI_SCL_O   : out   STD_LOGIC;
        HDMI_SCL_T   : out   STD_LOGIC;
        HDMI_SDA_I   : in    STD_LOGIC;
        HDMI_SDA_O   : out   STD_LOGIC;
        HDMI_SDA_T   : out   STD_LOGIC
	);
end hdmi_rx;

architecture Behavioral of hdmi_rx is

component idelay_clk
   port(
      -- Clock in ports
      CLK_IN           : in     std_logic;
      -- Clock out ports
      CLK_OUT          : out    std_logic;
      -- Status and control signals
      RESET             : in     std_logic;
      LOCKED            : out    std_logic);
end component;

component hdmi_clk
   port(
      -- Clock in ports
      CLK_IN_P         : in     std_logic;
      CLK_IN_N         : in     std_logic;
      -- Clock out ports
      CLK_OUT_1x          : out    std_logic;
      CLK_OUT_5x          : out    std_logic;
      -- Status and control signals
      RESET             : in     std_logic;
      LOCKED            : out    std_logic);
end component;

component decoder
   port(
      pclk_x5_in           : in  std_logic;
      pclk_x1_in           : in  std_logic;
      locked               : in  std_logic;
      din_p                : in  std_logic;
      din_n                : in  std_logic;
      other_ch0_vld        : in  std_logic;
      other_ch1_vld        : in  std_logic;
      other_ch0_rdy        : in  std_logic;
      other_ch1_rdy        : in  std_logic;
      iamvld               : out std_logic;
      iamrdy               : out std_logic;
      psalgnerr            : out std_logic;
      c0                   : out std_logic;
      c1                   : out std_logic;
      vde                  : out std_logic;
	  
      found_vld_openeye    : out std_logic;
      idelay_cnt_out       : out std_logic_vector(4 downto 0);
      vdout                : out std_logic_vector(7 downto 0);
      bitslip_cntr         : out std_logic_vector(3 downto 0);
      rst_fsm              : in  std_logic);
end component;

signal RefClkLckd : std_logic;
signal refclk, lckd, clkLckd, delayLckd, pclk, clk_1x, clk_5x : std_logic;
signal blue_rdy, green_rdy, red_rdy : std_logic;
signal blue_vld, green_vld, red_vld : std_logic;
signal red_int, green_int, blue_int : std_logic_vector(7 downto 0);
signal vsync_int, hsync_int : std_logic;
signal vde_int, blue_vde, green_vde, red_vde : std_logic;
signal err1, err2, err3 : std_logic;
signal PllRst, SysRst, VtcVde, VtcHs, VtcVs, VtcVde_d, VtcHs_d, VtcVs_d: std_logic;
signal PClk_dbg, PClk_x5, int_PClk, int_PClk_x5, int_SysClk : std_logic;

attribute IODELAY_GROUP : string;
attribute IODELAY_GROUP of DelayCtrl : label is "ibuffs_group";

signal pxl_clk_g : std_logic;
signal hsync_bufr : std_logic := '0';
signal vsync_bufr : std_logic := '0';
signal vde_bufr : std_logic := '0';
signal hsync_bufg : std_logic := '0';
signal vsync_bufg : std_logic := '0';
signal vde_bufg : std_logic := '0';

signal red_bufr : std_logic_vector(7 downto 0) := (others=>'0');
signal green_bufr : std_logic_vector(7 downto 0) := (others=>'0');
signal blue_bufr : std_logic_vector(7 downto 0) := (others=>'0');
signal red_bufg : std_logic_vector(7 downto 0) := (others=>'0');
signal green_bufg : std_logic_vector(7 downto 0) := (others=>'0');
signal blue_bufg : std_logic_vector(7 downto 0) := (others=>'0');

signal found_vld_openeye : std_logic;
signal psalgnerr : std_logic;
signal idelay_cnt_out : std_logic_vector(4 downto 0);
signal bitslip_cntr : std_logic_vector(3 downto 0);

begin

PXL_CLK <= pxl_clk_g;
PXL_CLK_LOCKED <= clkLckd;

HDMI_OUT_EN <= '0';
HDMI_HPD <= '1';  --not SysRst;
SysRst <= not DelayLckd;
PllRst <= '0';--BTN;

   RefClk <= SYSCLK;

    HDMI_SCL_O <= '1';
    HDMI_SCL_T <= '1';

   DelayCtrl : IDELAYCTRL
   port map (
      RDY         => DelayLckd,
      REFCLK      => RefClk,
      RST         => PllRst);	

--Does HDMI_CLK PLL need feedback?
   PclkGen : hdmi_clk
   port map(
      CLK_IN_P => HDMI_CLK_P,
      CLK_IN_N => HDMI_CLK_N,
      CLK_OUT_1x => int_PClk, -- only for debug (see below)
      CLK_OUT_5x => int_PClk_x5,
      RESET  => SysRst,
      LOCKED => clkLckd);
		
   lckd <= clkLckd and DelayLckd;
	
   BUFIO_inst : BUFIO
   port map (
      O => clk_5x, -- 1-bit output: Clock output (connect to I/O clock loads).
      I => int_PClk_x5  -- 1-bit input: Clock input (connect to an IBUF or BUFMR).
   );
	BUFR_inst : BUFR
	generic map (
      BUFR_DIVIDE => "5",   -- Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
      SIM_DEVICE => "7SERIES"  -- Must be set to "7SERIES" 
   )
   port map (
      O => clk_1x,     -- 1-bit output: Clock output port
      CE => '1',   -- 1-bit input: Active high, clock enable (Divided modes only)
      CLR => '0', -- 1-bit input: Active high, asynchronous clear (Divided modes only)		
      I => int_PClk_x5      -- 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
   );	
   
   BUFG_dbg_inst : BUFG
   port map (
      O => pxl_clk_g, -- 1-bit output: Clock output
      I => clk_1x  -- 1-bit input: Clock input
   );
   
----------------------------------------------------------------------------------
-- DDC EEPROM
----------------------------------------------------------------------------------		
   	Edid: entity work.hdmi_ddc_w
      port map(
         clk_i => RefClk,
         scl_i => HDMI_SCL_I,
         SDA_I      => HDMI_SDA_I,
         SDA_O      => HDMI_SDA_O,
         SDA_T      => HDMI_SDA_T);

----------------------------------------------------------------------------------
-- DVI/HDMI Decoders
----------------------------------------------------------------------------------			
  BlueDecoder: decoder
   port map(
      pclk_x5_in     => clk_5x,
      pclk_x1_in     => clk_1x,
      locked         => lckd,
      din_p          => HDMI_D_P(0),
      din_n          => HDMI_D_N(0),
      other_ch0_vld  => green_vld,
      other_ch1_vld  => red_vld,
      other_ch0_rdy  => green_rdy,
      other_ch1_rdy  => red_rdy,
      iamvld         => blue_vld,
      iamrdy         => blue_rdy,
      psalgnerr      => psalgnerr,
      c0             => hsync_int,
      c1             => vsync_int,
      vde            => blue_vde,
      vdout          => blue_int,
      found_vld_openeye => found_vld_openeye,
      idelay_cnt_out => idelay_cnt_out,
      bitslip_cntr => bitslip_cntr,
      rst_fsm        => SysRst);
   
   GreenDecoder: decoder
   port map(
      pclk_x5_in     => clk_5x,
      pclk_x1_in     => clk_1x,
      locked         => lckd,
      din_p          => HDMI_D_P(1),
      din_n          => HDMI_D_N(1),
      other_ch0_vld  => blue_vld,
      other_ch1_vld  => red_vld,
      other_ch0_rdy  => blue_rdy,
      other_ch1_rdy  => red_rdy,
      iamvld         => green_vld,
      iamrdy         => green_rdy,
      psalgnerr      => open,
      c0             => open,
      c1             => open,
      vde            => green_vde,
      vdout          => green_int,
      found_vld_openeye => open,
      idelay_cnt_out => open,
      bitslip_cntr => open,
      rst_fsm        => SysRst);
   
   RedDecoder: decoder
   port map(
      pclk_x5_in     => clk_5x,
      pclk_x1_in     => clk_1x,
      locked         => lckd,
      din_p          => HDMI_D_P(2),
      din_n          => HDMI_D_N(2),
      other_ch0_vld  => blue_vld,
      other_ch1_vld  => green_vld,
      other_ch0_rdy  => blue_rdy,
      other_ch1_rdy  => green_rdy,
      iamvld         => red_vld,
      iamrdy         => red_rdy,
      psalgnerr      => open,
      c0             => open,
      c1             => open,
      vde            => red_vde,
      vdout          => red_int,
      found_vld_openeye => open,
      idelay_cnt_out => open,
      bitslip_cntr => open,
      rst_fsm        => SysRst);
		
----------------------------------------------------------------------------------
-- VGA Output
----------------------------------------------------------------------------------

 process (clk_1x)
 begin
	if (rising_edge(clk_1x)) then
      hsync_bufr <= hsync_int;
      vsync_bufr <= vsync_int;
      vde_bufr <= blue_vde;
      if (blue_vde = '1') then
         red_bufr <= red_int;
         green_bufr <= green_int;
         blue_bufr <= blue_int;
      else
         red_bufr <= (others=>'0');
         green_bufr <= (others=>'0');
         blue_bufr <= (others=>'0');
      end if;
   end if;
 end process;
      
 process (pxl_clk_g)
 begin
	if (rising_edge(pxl_clk_g)) then
      hsync_bufg <= hsync_bufr;
      vsync_bufg <= vsync_bufr;
      vde_bufg <= vde_bufr;
      red_bufg <= red_bufr;
      green_bufg <= green_bufr;
      blue_bufg <= blue_bufr;
   end if;
 end process;
      
	VGA_HS <= hsync_bufg;
	VGA_VS <= vsync_bufg;
    VGA_DE <= vde_bufg;
    VGA_DATA <= red_bufg & green_bufg & blue_bufg;
           
end Behavioral;

