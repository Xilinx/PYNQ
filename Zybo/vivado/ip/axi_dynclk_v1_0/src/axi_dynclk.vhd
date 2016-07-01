library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VComponents.all;


entity axi_dynclk is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line
        ADD_BUFMR : boolean := false; --true, if BUFMR should be added between MMCM and BUFIO  

		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 5
	);
	port (
		-- Users to add ports here
		REF_CLK_I                     : in  std_logic;
        PXL_CLK_O                     : out std_logic;
		PXL_CLK_5X_O				  : out std_logic;
		LOCKED_O                      : out std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end axi_dynclk;

architecture arch_imp of axi_dynclk is

	-- component declaration
	component axi_dynclk_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 5
		);
		port (
		CTRL_REG     :out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        STAT_REG     :in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        CLK_O_REG    :out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        CLK_FB_REG   :out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        CLK_FRAC_REG :out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        CLK_DIV_REG  :out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        CLK_LOCK_REG :out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        CLK_FLTR_REG :out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component axi_dynclk_S00_AXI;
	
	
	component mmcme2_drp
	generic (
        DIV_F : integer
		);
	port(
		SEN               : in std_logic;
		SCLK              : in std_logic;
		RST               : in std_logic;
		S1_CLKOUT0        : in std_logic_vector(35 downto 0);
		S1_CLKFBOUT       : in std_logic_vector(35 downto 0);
		S1_DIVCLK         : in std_logic_vector(13 downto 0);
		S1_LOCK           : in std_logic_vector(39 downto 0);
		S1_DIGITAL_FILT   : in std_logic_vector(9 downto 0);
		REF_CLK           : in std_logic;
		CLKFBOUT_I		  : in std_logic;
		CLKFBOUT_O        : out std_logic;
		SRDY              : out std_logic;
		PXL_CLK           : out std_logic;
		LOCKED_O          : out std_logic
		);
	end component;
	
	
    signal CTRL_REG                       : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal STAT_REG                       : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal CLK_O_REG                      : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal CLK_FB_REG                     : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal CLK_FRAC_REG                   : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal CLK_DIV_REG                    : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal CLK_LOCK_REG                   : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal CLK_FLTR_REG                   : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);

	type CLK_STATE_TYPE is (RESET, WAIT_LOCKED, WAIT_EN, WAIT_SRDY, ENABLED);
	signal clk_state                 : CLK_STATE_TYPE := RESET;
	signal srdy                      : std_logic;
	signal pxl_clk                   : std_logic;
	signal locked                    : std_logic;
	signal locked_n                  : std_logic;
	signal sen_reg                   : std_logic := '0';
 
	signal mmcm_fbclk_in             : std_logic;
	signal mmcm_fbclk_out            : std_logic;
	signal mmcm_clk					 : std_logic;
	
	signal bufio_in                 : std_logic;
begin

-- Instantiation of Axi Bus Interface S00_AXI
axi_dynclk_S00_AXI_inst : axi_dynclk_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
		CTRL_REG     => CTRL_REG,    
		STAT_REG     => STAT_REG,   
        CLK_O_REG    => CLK_O_REG,    
        CLK_FB_REG   => CLK_FB_REG,
        CLK_FRAC_REG => CLK_FRAC_REG, 
        CLK_DIV_REG  => CLK_DIV_REG,  
        CLK_LOCK_REG => CLK_LOCK_REG,
        CLK_FLTR_REG => CLK_FLTR_REG,
		
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

GenerateBUFMR: if ADD_BUFMR generate
BUFMR_inst : BUFMR
   port map (
      O => bufio_in, -- 1-bit output: Clock output (connect to BUFIOs/BUFRs)
      I => mmcm_clk  -- 1-bit input: Clock input (Connect to IBUF)
   );
end generate GenerateBUFMR;

DontGenerateBUFMR: if not ADD_BUFMR generate
    bufio_in <= mmcm_clk;
end generate DontGenerateBUFMR;

	-- Add user logic here
	BUFIO_inst : BUFIO
	port map (
		O => PXL_CLK_5X_O, -- 1-bit output: Clock output (connect to I/O clock loads).
		I => bufio_in  -- 1-bit input: Clock input (connect to an IBUF or BUFMR).
	);

	BUFR_inst : BUFR
	generic map (
		BUFR_DIVIDE => "5",   -- Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
		SIM_DEVICE => "7SERIES"  -- Must be set to "7SERIES" 
	)
	port map (
		O => pxl_clk,     -- 1-bit output: Clock output port
		CE => '1',   -- 1-bit input: Active high, clock enable (Divided modes only)
		CLR => locked_n, -- 1-bit input: Active high, asynchronous clear (Divided modes only)		
		I => bufio_in      -- 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
	);
   
	locked_n <= not(locked);
  
  Inst_mmcme2_drp: mmcme2_drp 
  GENERIC MAP(
  DIV_F => 2
  )  
  PORT MAP(
		SEN => sen_reg,
		SCLK => s00_axi_aclk,
		RST => not(s00_axi_aresetn),
		SRDY => srdy,
		S1_CLKOUT0 => CLK_FRAC_REG(3 downto 0) & CLK_O_REG,
		S1_CLKFBOUT => CLK_FRAC_REG(19 downto 16) & CLK_FB_REG,
		S1_DIVCLK => CLK_DIV_REG(13 downto 0),
		S1_LOCK => CLK_FLTR_REG(7 downto 0) & CLK_LOCK_REG,
		S1_DIGITAL_FILT => CLK_FLTR_REG(25 downto 16),
		REF_CLK => REF_CLK_I,
		PXL_CLK => mmcm_clk,
		CLKFBOUT_O => mmcm_fbclk_out,
		CLKFBOUT_I => mmcm_fbclk_in,
		LOCKED_O => locked
	);
	
	mmcm_fbclk_in <= mmcm_fbclk_out; --Don't bother compensating for any delay, because we don't need a phase relationship between
									--REF_CLK and PXL_CLK
	
	PXL_CLK_O <= pxl_clk;
	LOCKED_O <= locked;
   
   	process (s00_axi_aclk)
	begin
    	if (rising_edge(s00_axi_aclk)) then
    		if (s00_axi_aresetn = '0') then
    			clk_state <= RESET;
    		else	
    			case clk_state is 
    			when RESET =>
    				clk_state <= WAIT_LOCKED;
    			when WAIT_LOCKED =>  
					-- This state ensures that the initial SRDY pulse 
					-- doesnt interfere with the WAIT_SRDY state
    				if (locked = '1') then
    					clk_state <= WAIT_EN;
    				end if;
    			when WAIT_EN =>
    				if (CTRL_REG(0) = '1') then
    					clk_state <= WAIT_SRDY;
    				end if;
    			when WAIT_SRDY =>
    				if (srdy = '1') then 
    					clk_state <= ENABLED;
    				end if;
    			when ENABLED =>
    				if (CTRL_REG(0) = '0') then
    					clk_state <= WAIT_EN;
    				end if;
    			when others => --Never reached
    				clk_state <= RESET;
    			end case;
    		end if;
    	end if;
	end process;
	
	STAT_REG(0) <= '1' when clk_state = ENABLED else
					'0';
					
process (s00_axi_aclk)
begin
	if (rising_edge(s00_axi_aclk)) then
		if (s00_axi_aresetn = '0') then
			sen_reg <= '0';
		else
			if (clk_state = WAIT_EN and CTRL_REG(0) = '1') then
				sen_reg <= '1';
			else
				sen_reg <= '0';
			end if;
		end if;
	end if;
end process;
   
	-- User logic ends

end arch_imp;
