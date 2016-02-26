--------------------------------------------------------------------------------
--
--  File:
--      axi_dispctrl_v1_0.vhd
--
--  Module:
--      AXIS Display Controller
--
--  Author:
--      Tinghui Wang (Steve)
--		Sam Bobrowicz
--
--  Description:
--      Wrapper for AXI Display Controller
--
--  Additional Notes:
--      TODO - 1) Add Parameter to select whether to use a PLL or MMCM
--             2) Add Parameter to use external pixel clock (no MMCM or PLL)
--             3) Add Hot-plug detect and EDID control, selectable with parameter
--             4) Add feature detect register, for determining enabled parameters from software
--
--  Copyright notice:
--      Copyright (C) 2014 Digilent Inc.
--
--  License:
--      This program is free software; distributed under the terms of 
--      BSD 3-clause license ("Revised BSD License", "New BSD License", or "Modified BSD License")
--
--      Redistribution and use in source and binary forms, with or without modification,
--      are permitted provided that the following conditions are met:
--
--      1.    Redistributions of source code must retain the above copyright notice, this
--             list of conditions and the following disclaimer.
--      2.    Redistributions in binary form must reproduce the above copyright notice,
--             this list of conditions and the following disclaimer in the documentation
--             and/or other materials provided with the distribution.
--      3.    Neither the name(s) of the above-listed copyright holder(s) nor the names
--             of its contributors may be used to endorse or promote products derived
--             from this software without specific prior written permission.
--
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--      ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--      WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--      IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
--      INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
--      BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
--      LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
--      OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
--      OF THE POSSIBILITY OF SUCH DAMAGE.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VComponents.all;

entity axi_dispctrl_v1_0 is
	generic (
		-- Users to add parameters here
		C_USE_BUFR_DIV5	: integer := 0;
        C_RED_WIDTH : integer   := 8;
        C_GREEN_WIDTH : integer  := 8;
        C_BLUE_WIDTH : integer  := 8;
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Parameters of Axi Slave Bus Interface S_AXI
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 6;

		-- Parameters of Axi Slave Bus Interface S_AXIS_MM2S
		C_S_AXIS_MM2S_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here
		-- Clock Signals
		REF_CLK_I                     : in  std_logic;
        PXL_CLK_O                     : out std_logic;
		PXL_CLK_5X_O				  : out std_logic;
		LOCKED_O                      : out std_logic;
		
		IRPT_O					: out std_logic;
        -- Display Signals
        FSYNC_O                       : out std_logic;
		HSYNC_O                       : out std_logic;
		VSYNC_O                       : out std_logic;
		DE_O                          : out std_logic;
		RED_O                         : out std_logic_vector(C_RED_WIDTH-1 downto 0);
		GREEN_O                       : out std_logic_vector(C_GREEN_WIDTH-1 downto 0);
		BLUE_O                        : out std_logic_vector(C_BLUE_WIDTH-1 downto 0);
		-- Debug Signals
		DEBUG_O                       : out std_logic_vector(31 downto 0); 
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Ports of Axi Slave Bus Interface S_AXI
		s_axi_aclk	: in std_logic;
		s_axi_aresetn	: in std_logic;
		s_axi_awaddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		s_axi_awprot	: in std_logic_vector(2 downto 0);
		s_axi_awvalid	: in std_logic;
		s_axi_awready	: out std_logic;
		s_axi_wdata	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		s_axi_wstrb	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		s_axi_wvalid	: in std_logic;
		s_axi_wready	: out std_logic;
		s_axi_bresp	: out std_logic_vector(1 downto 0);
		s_axi_bvalid	: out std_logic;
		s_axi_bready	: in std_logic;
		s_axi_araddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		s_axi_arprot	: in std_logic_vector(2 downto 0);
		s_axi_arvalid	: in std_logic;
		s_axi_arready	: out std_logic;
		s_axi_rdata	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		s_axi_rresp	: out std_logic_vector(1 downto 0);
		s_axi_rvalid	: out std_logic;
		s_axi_rready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S_AXIS_MM2S
		s_axis_mm2s_aclk	: in std_logic;
		s_axis_mm2s_aresetn	: in std_logic;
		s_axis_mm2s_tready	: out std_logic;
		s_axis_mm2s_tdata	: in std_logic_vector(C_S_AXIS_MM2S_TDATA_WIDTH-1 downto 0);
		s_axis_mm2s_tstrb	: in std_logic_vector((C_S_AXIS_MM2S_TDATA_WIDTH/8)-1 downto 0);
		s_axis_mm2s_tlast	: in std_logic;
		s_axis_mm2s_tvalid	: in std_logic
	);
end axi_dispctrl_v1_0;

architecture arch_imp of axi_dispctrl_v1_0 is

	-- component declaration
	component axi_dispctrl_v1_0_S_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 6
		);
		port (
		CTRL_REG     :out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        STAT_REG     :in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        FRAME_REG    :out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        HPARAM1_REG  :out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        HPARAM2_REG  :out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        VPARAM1_REG  :out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        VPARAM2_REG  :out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
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
	end component axi_dispctrl_v1_0_S_AXI;

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
   
    component vdma_to_vga
      generic (
        C_RED_WIDTH : integer   := 8;
        C_GREEN_WIDTH : integer  := 8;
        C_BLUE_WIDTH : integer  := 8;
   		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
      );
	  port(
		LOCKED_I          : in std_logic;
		ENABLE_I          : in std_logic;
		S_AXIS_ACLK	      : in std_logic;
		S_AXIS_ARESETN	  : in std_logic;
		S_AXIS_TREADY	  : out std_logic;
		S_AXIS_TDATA	  : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TSTRB	  : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TLAST	  : in std_logic;
		S_AXIS_TVALID	  : in std_logic;
		DEBUG_O           : out std_logic_vector(31 downto 0);
		USR_WIDTH_I       : in std_logic_vector(11 downto 0);
		USR_HEIGHT_I      : in std_logic_vector(11 downto 0);
		USR_HPS_I         : in std_logic_vector(11 downto 0);
		USR_HPE_I         : in std_logic_vector(11 downto 0);
		USR_HPOL_I        : in std_logic;
		USR_HMAX_I        : in std_logic_vector(11 downto 0);
		USR_VPS_I         : in std_logic_vector(11 downto 0);
		USR_VPE_I         : in std_logic_vector(11 downto 0);
		USR_VPOL_I        : in std_logic;
		USR_VMAX_I        : in std_logic_vector(11 downto 0);          
		RUNNING_O         : out std_logic;
		FSYNC_O           : out std_logic;
		HSYNC_O           : out std_logic;
		VSYNC_O           : out std_logic;
		DE_O              : out std_logic;
		RED_O             : out std_logic_vector(C_RED_WIDTH-1 downto 0);
		GREEN_O           : out std_logic_vector(C_GREEN_WIDTH-1 downto 0);
		BLUE_O            : out std_logic_vector(C_BLUE_WIDTH-1 downto 0)
	  );
	end component;

    signal CTRL_REG                       : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal STAT_REG                       : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal FRAME_REG                      : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal HPARAM1_REG                    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal HPARAM2_REG                    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal VPARAM1_REG                    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal VPARAM2_REG                    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal CLK_O_REG                      : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal CLK_FB_REG                     : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal CLK_FRAC_REG                   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal CLK_DIV_REG                    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal CLK_LOCK_REG                   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal CLK_FLTR_REG                   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

	type CLK_STATE_TYPE is (RESET, WAIT_LOCKED, WAIT_EN, WAIT_SRDY, WAIT_RUN, ENABLED, WAIT_FRAME_DONE);
	signal clk_state                 : CLK_STATE_TYPE := RESET;
	signal srdy                      : std_logic;
	signal enable_reg                : std_logic := '0';
	signal sen_reg                   : std_logic := '0';
	signal pxl_clk                   : std_logic;
	signal locked                    : std_logic;
	signal locked_n                  : std_logic;
 
	signal mmcm_fbclk_in             : std_logic;
	signal mmcm_fbclk_out            : std_logic;
	signal mmcm_clk					 : std_logic;

	signal vga_running               : std_logic;
	signal irpt_trig               : std_logic;
	signal vsync_int               : std_logic;

	

begin

-- Instantiation of Axi Bus Interface S_AXI
axi_dispctrl_v1_0_S_AXI_inst : axi_dispctrl_v1_0_S_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_ADDR_WIDTH
	)
	port map (
		CTRL_REG     => CTRL_REG,    
		STAT_REG     => STAT_REG,    
        FRAME_REG    => FRAME_REG,
        HPARAM1_REG  => HPARAM1_REG,  
        HPARAM2_REG  => HPARAM2_REG, 
        VPARAM1_REG  => VPARAM1_REG,  
        VPARAM2_REG  => VPARAM2_REG,  
        CLK_O_REG    => CLK_O_REG,    
        CLK_FB_REG   => CLK_FB_REG,
        CLK_FRAC_REG => CLK_FRAC_REG, 
        CLK_DIV_REG  => CLK_DIV_REG,  
        CLK_LOCK_REG => CLK_LOCK_REG,
        CLK_FLTR_REG => CLK_FLTR_REG,
       
		S_AXI_ACLK	=> s_axi_aclk,
		S_AXI_ARESETN	=> s_axi_aresetn,
		S_AXI_AWADDR	=> s_axi_awaddr,
		S_AXI_AWPROT	=> s_axi_awprot,
		S_AXI_AWVALID	=> s_axi_awvalid,
		S_AXI_AWREADY	=> s_axi_awready,
		S_AXI_WDATA	=> s_axi_wdata,
		S_AXI_WSTRB	=> s_axi_wstrb,
		S_AXI_WVALID	=> s_axi_wvalid,
		S_AXI_WREADY	=> s_axi_wready,
		S_AXI_BRESP	=> s_axi_bresp,
		S_AXI_BVALID	=> s_axi_bvalid,
		S_AXI_BREADY	=> s_axi_bready,
		S_AXI_ARADDR	=> s_axi_araddr,
		S_AXI_ARPROT	=> s_axi_arprot,
		S_AXI_ARVALID	=> s_axi_arvalid,
		S_AXI_ARREADY	=> s_axi_arready,
		S_AXI_RDATA	=> s_axi_rdata,
		S_AXI_RRESP	=> s_axi_rresp,
		S_AXI_RVALID	=> s_axi_rvalid,
		S_AXI_RREADY	=> s_axi_rready
	);

USE_BUFR_DIV5 : if C_USE_BUFR_DIV5 = 1 generate
	
	BUFIO_inst : BUFIO
	port map (
		O => PXL_CLK_5X_O, -- 1-bit output: Clock output (connect to I/O clock loads).
		I => mmcm_clk  -- 1-bit input: Clock input (connect to an IBUF or BUFMR).
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
		I => mmcm_clk      -- 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
	);
   
	locked_n <= not(locked);
  
  Inst_mmcme2_drp: mmcme2_drp 
  GENERIC MAP(
  DIV_F => 2
  )  
  PORT MAP(
		SEN => sen_reg,
		SCLK => s_axi_aclk,
		RST => not(s_axi_aresetn),
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
end generate;
DONT_USE_BUFR_DIV5 : if C_USE_BUFR_DIV5 /= 1 generate
	
	PXL_CLK_5X_O <= '0';
	
	BUFG_inst : BUFG
	port map (
	O => pxl_clk, -- 1-bit output: Clock output
	I => mmcm_clk -- 1-bit input: Clock input
	);
	
    
  Inst_mmcme2_drp: mmcme2_drp 
  GENERIC MAP(
  DIV_F => 10
  )  
  PORT MAP(
		SEN => sen_reg,
		SCLK => s_axi_aclk,
		RST => not(s_axi_aresetn),
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
  
end generate;

	mmcm_fbclk_in <= mmcm_fbclk_out; --Don't bother compensating for any delay, because we don't need a phase relationship between
									--REF_CLK and PXL_CLK
	
	PXL_CLK_O <= pxl_clk;
	LOCKED_O <= locked;
   

	process (s_axi_aclk)
	begin
    	if (rising_edge(s_axi_aclk)) then
    		if (s_axi_aresetn = '0') then
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
    					clk_state <= WAIT_RUN;
    				end if;
    			when WAIT_RUN =>
    				if (STAT_REG(0) = '1') then
    					clk_state <= ENABLED;
    				end if;
    			when ENABLED =>
    				if (CTRL_REG(0) = '0') then
    					clk_state <= WAIT_FRAME_DONE;
    				end if;
    			when WAIT_FRAME_DONE =>
    				if (STAT_REG(0) = '0') then
    					clk_state <= WAIT_EN;
    				end if;
    			when others => --Never reached
    				clk_state <= RESET;
    			end case;
    		end if;
    	end if;
	end process;

	process (s_axi_aclk)
	begin
    	if (rising_edge(s_axi_aclk)) then
    		if (s_axi_aresetn = '0') then
    			enable_reg <= '0';
    			sen_reg <= '0';
    		else
    			if (clk_state = WAIT_EN and CTRL_REG(0) = '1') then
    				sen_reg <= '1';
    			else
    				sen_reg <= '0';
    			end if;
    			if (clk_state = WAIT_RUN or clk_state = ENABLED) then
    				enable_reg <= '1';
    			else
    				enable_reg <= '0';
    			end if;
    		end if;
    	end if;
	end process;
 
Inst_vdma_to_vga: vdma_to_vga
	generic map (
        C_RED_WIDTH   => C_RED_WIDTH,
        C_GREEN_WIDTH => C_GREEN_WIDTH,
        C_BLUE_WIDTH  => C_BLUE_WIDTH,
		C_S_AXIS_TDATA_WIDTH	=> C_S_AXIS_MM2S_TDATA_WIDTH
	)
	PORT MAP(
		LOCKED_I => locked,
		ENABLE_I => enable_reg,
		RUNNING_O => vga_running,
		S_AXIS_ACLK	=> s_axis_mm2s_aclk,
		S_AXIS_ARESETN	=> s_axis_mm2s_aresetn,
		S_AXIS_TREADY	=> s_axis_mm2s_tready,
		S_AXIS_TDATA	=> s_axis_mm2s_tdata,
		S_AXIS_TSTRB	=> s_axis_mm2s_tstrb,
		S_AXIS_TLAST	=> s_axis_mm2s_tlast,
		S_AXIS_TVALID	=> s_axis_mm2s_tvalid,
		FSYNC_O => FSYNC_O,
		HSYNC_O => HSYNC_O,
		VSYNC_O => vsync_int,
		DEBUG_O => DEBUG_O,
		DE_O => DE_O,
		RED_O => RED_O,
		GREEN_O => GREEN_O,
		BLUE_O => BLUE_O,
		USR_WIDTH_I => FRAME_REG(27 downto 16),
		USR_HEIGHT_I => FRAME_REG(11 downto 0),
		USR_HPS_I => HPARAM1_REG(27 downto 16),
		USR_HPE_I => HPARAM1_REG(11 downto 0),
		USR_HPOL_I => HPARAM2_REG(16),
		USR_HMAX_I => HPARAM2_REG(11 downto 0),
		USR_VPS_I => VPARAM1_REG(27 downto 16),
		USR_VPE_I => VPARAM1_REG(11 downto 0),
		USR_VPOL_I => VPARAM2_REG(16),
		USR_VMAX_I => VPARAM2_REG(11 downto 0)
	);

	STAT_REG(C_S_AXI_DATA_WIDTH-1 downto 1) <= (others => '0');

	process (s_axi_aclk)
	begin
    	if (rising_edge(s_axi_aclk)) then
    		if (s_axi_aresetn = '0') then
    			STAT_REG(0) <= '0';
    		else
    			STAT_REG(0) <= vga_running;
    		end if;
    	end if;
	end process;
	
	
	irpt_trig <= '1' when ((vsync_int = VPARAM2_REG(16)) and (CTRL_REG(2) = '1')) else
	             '0';
				 
	IRPT_O <= irpt_trig;
	VSYNC_O <= vsync_int;
	
  
	-- User logic ends

end arch_imp;
