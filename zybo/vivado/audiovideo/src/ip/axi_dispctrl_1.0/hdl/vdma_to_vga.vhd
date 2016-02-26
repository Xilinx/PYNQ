--------------------------------------------------------------------------------
--
--  File:
--      vdma_to_vga.vhd
--
--  Module:
--      AXIS Display Controller
--
--  Author:
--      Sam Bobrowicz
--      Tinghui Wang (Steve)
--
--  Description:
--      AXI Display Controller
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity vdma_to_vga is
	 generic (
           C_RED_WIDTH : integer   := 8;
           C_GREEN_WIDTH : integer  := 8;
           C_BLUE_WIDTH : integer  := 8;
           C_S_AXIS_TDATA_WIDTH	: integer	:= 32 --must be 32
	 );
    Port ( 
           LOCKED_I : in  STD_LOGIC;
           ENABLE_I : in  STD_LOGIC;
           RUNNING_O : out  STD_LOGIC;
           FSYNC_O : out  STD_LOGIC;
			  
           S_AXIS_ACLK : in  STD_LOGIC;
           S_AXIS_ARESETN	  : in std_logic;
           S_AXIS_TDATA : in  STD_LOGIC_VECTOR (31 downto 0);
           S_AXIS_TSTRB	  : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
           S_AXIS_TVALID : in  STD_LOGIC;
           S_AXIS_TLAST	  : in std_logic;
           S_AXIS_TREADY : out  STD_LOGIC;
		   
           DEBUG_O : out STD_LOGIC_VECTOR (31 downto 0);
         
           HSYNC_O : out  STD_LOGIC;
           VSYNC_O : out  STD_LOGIC;
           DE_O : out  STD_LOGIC;
           RED_O : out  STD_LOGIC_VECTOR (C_RED_WIDTH-1 downto 0);
           GREEN_O : out  STD_LOGIC_VECTOR (C_GREEN_WIDTH-1 downto 0);
           BLUE_O : out  STD_LOGIC_VECTOR (C_BLUE_WIDTH-1 downto 0);

           USR_WIDTH_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_HEIGHT_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_HPS_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_HPE_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_HPOL_I : in  STD_LOGIC;
           USR_HMAX_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_VPS_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_VPE_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_VPOL_I : in  STD_LOGIC;
           USR_VMAX_I : in  STD_LOGIC_VECTOR (11 downto 0));
end vdma_to_vga;

architecture Behavioral of vdma_to_vga is


  type VGA_STATE_TYPE is (VGA_RESET, VGA_WAIT_EN, VGA_LATCH, VGA_INIT, VGA_WAIT_VLD, VGA_RUN);

  signal pxl_clk                   : std_logic;
  signal locked                    : std_logic;
  signal vga_running               : std_logic;
  signal frame_edge                : std_logic;
  
  signal running_reg                : std_logic := '0';
  signal vga_en                    : std_logic := '0';

  signal frm_width : std_logic_vector(11 downto 0) := (others =>'0');
  signal frm_height : std_logic_vector(11 downto 0) := (others =>'0');
  signal h_ps : std_logic_vector(11 downto 0) := (others =>'0');
  signal h_pe : std_logic_vector(11 downto 0) := (others =>'0');
  signal h_max : std_logic_vector(11 downto 0) := (others =>'0');
  signal v_ps : std_logic_vector(11 downto 0) := (others =>'0');
  signal v_pe : std_logic_vector(11 downto 0) := (others =>'0');
  signal v_max : std_logic_vector(11 downto 0) := (others =>'0');
  signal h_pol                   : std_logic := '0';
  signal v_pol                   : std_logic := '0';


  signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
  signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');

  signal h_sync_reg : std_logic := '0';
  signal v_sync_reg : std_logic := '0';
  signal h_sync_dly : std_logic := '0';
  signal v_sync_dly : std_logic := '0';

  signal fsync_reg : std_logic := '0';

  signal video_dv                   : std_logic := '0';
  signal video_dv_dly                   : std_logic := '0';

  signal red_reg : std_logic_vector(7 downto 0) := (others =>'0');
  signal green_reg : std_logic_vector(7 downto 0) := (others =>'0');
  signal blue_reg : std_logic_vector(7 downto 0) := (others =>'0');
  
  signal vga_state                 : VGA_STATE_TYPE := VGA_RESET;


begin

locked <= LOCKED_I;
pxl_clk <= S_AXIS_ACLK;

DEBUG_O(11 downto 0) <= h_cntr_reg;
DEBUG_O(23 downto 12) <= v_cntr_reg;
DEBUG_O(24) <= vga_running;
DEBUG_O(25) <= frame_edge;
DEBUG_O(26) <= fsync_reg;
DEBUG_O(27) <= h_sync_dly;
DEBUG_O(28) <= v_sync_dly;
DEBUG_O(29) <= video_dv_dly; --Data valid
DEBUG_O(30) <= video_dv; --TREADY
DEBUG_O(31) <= S_AXIS_TVALID;

------------------------------------------------------------------
------                 CONTROL STATE MACHINE               -------
------------------------------------------------------------------
  
--Synchronize ENABLE_I signal from axi_lite domain to pixel clock
--domain
  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      vga_en <= '0';
    elsif (rising_edge(pxl_clk)) then
      vga_en <= ENABLE_I;
    end if;
  end process;

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      vga_state <= VGA_RESET;
    elsif (rising_edge(pxl_clk)) then
      case vga_state is 
      when VGA_RESET =>
        vga_state <= VGA_WAIT_EN;
      when VGA_WAIT_EN =>
        if (vga_en = '1') then
          vga_state <= VGA_LATCH;
        end if;
      when VGA_LATCH =>
        --vga_state <= VGA_INIT;
		vga_state <= VGA_WAIT_VLD;
      when VGA_INIT =>
        vga_state <= VGA_WAIT_VLD;
		when VGA_WAIT_VLD =>
		--It seems the first frame requires a bit of time for the linebuffer to fill. This
		--State ensures we do not begin requesting data before the VDMA reports it is valid
		  --if (S_AXIS_TVALID = '1') then
		    vga_state <= VGA_RUN;
		  --end if;
      when VGA_RUN =>
        if (vga_en = '0' and frame_edge = '1') then
          vga_state <= VGA_WAIT_EN;
        end if;
      when others => --Never reached
        vga_state <= VGA_RESET;
      end case;
    end if;
  end process;

  --This component treats the first pixel of the first non-visible line as the beginning
  --of the frame.
  frame_edge <= '1' when ((v_cntr_reg = frm_height) and (h_cntr_reg = 0)) else
                '0';

  vga_running <= '1' when vga_state = VGA_RUN else
                 '0'; 

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      running_reg <= '0';
    elsif (rising_edge(pxl_clk)) then
      running_reg <= vga_running;
    end if;
  end process;

  RUNNING_O <= running_reg;

------------------------------------------------------------------
------                  USER REGISTER LATCH                -------
------------------------------------------------------------------
--Note that the USR_ inputs are crossing from the axi_lite clock domain
--to the pixel clock domain


  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      frm_width <= (others => '0');
      frm_height <= (others => '0');
      h_ps <= (others => '0');
      h_pe <= (others => '0');
      h_pol <= '0';
      h_max <= (others => '0');
      v_ps <= (others => '0');
      v_pe <= (others => '0');
      v_pol <= '0';
      v_max <= (others => '0');
    elsif (rising_edge(pxl_clk)) then
      if (vga_state = VGA_LATCH) then
        frm_width <= USR_WIDTH_I;
        frm_height <= USR_HEIGHT_I;
        h_ps <= USR_HPS_I;
        h_pe <= USR_HPE_I;
        h_pol <= USR_HPOL_I;
        h_max <= USR_HMAX_I;
        v_ps <= USR_VPS_I;
        v_pe <= USR_VPE_I;
        v_pol <= USR_VPOL_I;
        v_max <= USR_VMAX_I;
      end if;
    end if;
  end process;


------------------------------------------------------------------
------              PIXEL ADDRESS COUNTERS                 -------
------------------------------------------------------------------


  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      h_cntr_reg <= (others => '0');
    elsif (rising_edge(pxl_clk)) then
      if (vga_state = VGA_WAIT_VLD) then
        h_cntr_reg <= (others =>'0'); --Note that the first frame starts on the second non-visible line, right after when FSYNC would pulse
      elsif (vga_running = '1') then
        if (h_cntr_reg = h_max) then
          h_cntr_reg <= (others => '0');
        else
          h_cntr_reg <= h_cntr_reg + 1;
        end if;
      else
        h_cntr_reg <= (others =>'0');
      end if;
    end if;
  end process;

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      v_cntr_reg <= (others => '0');
    elsif (rising_edge(pxl_clk)) then
      if (vga_state = VGA_WAIT_VLD) then 
        --v_cntr_reg <= frm_height + 1; --Note that the first frame starts on the second non-visible line, right after when FSYNC would pulse
		v_cntr_reg <= frm_height;
      elsif (vga_running = '1') then
        if ((h_cntr_reg = h_max) and (v_cntr_reg = v_max))then
          v_cntr_reg <= (others => '0');
        elsif (h_cntr_reg = h_max) then
          v_cntr_reg <= v_cntr_reg + 1;
        end if;
      else
        v_cntr_reg <= (others =>'0');
      end if;
    end if;
  end process;

------------------------------------------------------------------
------               SYNC GENERATION                       -------
------------------------------------------------------------------


  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      h_sync_reg <= '0';
    elsif (rising_edge(pxl_clk)) then
      if (vga_running = '1') then
        if ((h_cntr_reg >= h_ps) and (h_cntr_reg < h_pe)) then
          h_sync_reg <= h_pol;
        else
          h_sync_reg <= not(h_pol);
        end if;
      else
        h_sync_reg <= '0';
      end if;
    end if;
  end process;

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      v_sync_reg <= '0';
    elsif (rising_edge(pxl_clk)) then
      if (vga_running = '1') then
        if ((v_cntr_reg >= v_ps) and (v_cntr_reg < v_pe)) then
          v_sync_reg <= v_pol;
        else
          v_sync_reg <= not(v_pol);
        end if;
      else
        v_sync_reg <= '0';
      end if;
    end if;
  end process;

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      v_sync_dly <= '0';
      h_sync_dly <= '0';
    elsif (rising_edge(pxl_clk)) then
      v_sync_dly <= v_sync_reg;
      h_sync_dly <= h_sync_reg;
    end if;
  end process;

  HSYNC_O <= h_sync_dly;
  VSYNC_O <= v_sync_dly;


--Signal a new frame to the VDMA at the end of the first non-visible line. This
--should allow plenty of time for the line buffer to fill between frames, before 
--data is required. The first fsync pulse is signaled during the VGA_INIT state.
  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      fsync_reg <= '0';
    elsif (rising_edge(pxl_clk)) then
      if ((((v_cntr_reg = frm_height) and (h_cntr_reg = h_max)) and (vga_running = '1')) or (vga_state = VGA_INIT)) then
        fsync_reg <= '1';
      else
        fsync_reg <= '0';
      end if;
    end if;
  end process;

  FSYNC_O <= fsync_reg; 

------------------------------------------------------------------
------                  DATA CAPTURE                       -------
------------------------------------------------------------------

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      video_dv <= '0';
		video_dv_dly <= '0';
    elsif (rising_edge(pxl_clk)) then
		video_dv_dly <= video_dv;
      if ((vga_running = '1') and (v_cntr_reg < frm_height) and (h_cntr_reg < frm_width)) then
        video_dv <= '1';
      else
        video_dv <= '0';
      end if;
    end if;
  end process;

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      red_reg <= (others => '0');
      green_reg <= (others => '0');
      blue_reg <= (others => '0');
    elsif (rising_edge(pxl_clk)) then
      if (video_dv = '1') then
        red_reg <= S_AXIS_TDATA(23 downto 16);
        green_reg <= S_AXIS_TDATA(15 downto 8);
        blue_reg <= S_AXIS_TDATA(7 downto 0);
      else
        red_reg <= (others => '0');
        green_reg <= (others => '0');
        blue_reg <= (others => '0');
      end if;
    end if;
  end process;

  S_AXIS_TREADY <= video_dv;
  DE_O <= video_dv_dly;

  RED_O <= red_reg(7 downto 8-C_RED_WIDTH);
  GREEN_O <= green_reg(7 downto 8-C_GREEN_WIDTH);
  BLUE_O <= blue_reg(7 downto 8-C_BLUE_WIDTH);

end Behavioral;

